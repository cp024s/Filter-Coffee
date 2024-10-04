package Ethernet_IP_TX;

import  Clocks::*;
import  BRAMCore::*;
import  FIFO::*;
import  FIFOF::*;
import  Ethernet_IP_Phy::*;

// `define FrameSize 1560
typedef 16 BRAM_addr_size;
typedef 8 BRAM_data_size;
typedef `FrameSize BRAM_memory_size;


interface MacTXIfc;
    method Bool m_ready_to_recv_next_frame;
    method Action m_write_tx_frame (Bit#(8) data, Bool is_last_byte);
endinterface

interface TXIfc;
    (* prefix="" *)
    interface PhyTXIfc phy;
    interface MacTXIfc mac_tx;
endinterface

// `define DEBUG 1

(*synthesize*)
module mkEthIPTX#(Clock eth_mii_tx_clk, Reset eth_mii_rstn) (TXIfc);

    let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;
    EthIPTXPhyIfc phy_tx <- mkEthIPTXPhy(clocked_by eth_mii_tx_clk, reset_by eth_mii_rstn, core_clock, core_reset); 

    BRAM_DUAL_PORT#(Bit#(BRAM_addr_size), Bit#(BRAM_data_size)) frame <- mkBRAMCore2(valueOf(BRAM_memory_size), False);

    Reg#(Bool) initialize_bram <- mkReg(True);
    Reg#(Bit#(4)) initialize_bram_count <- mkReg(0);

// 7 bytes preamble
    rule r_initialize_bram if (initialize_bram); // 1st 6 bytes 1010... 
        if (initialize_bram_count < 6) begin 
            frame.b.put(True, zeroExtend(initialize_bram_count), 8'h55);
        end
        else if (initialize_bram_count == 6) begin // Start frame delimiter
            frame.b.put(True, zeroExtend(initialize_bram_count), 8'hD5);
            initialize_bram <= False;
            `ifdef DEBUG $display("%t mkEthIPTX: r_initialize_bram. Initialized setup", $time); `endif
        end
        initialize_bram_count <= initialize_bram_count + 1;        
    endrule

// Initialization of registers
    Reg#(Bit#(16)) bytes_sent_to_phy_addr <- mkReg(0);
    Reg#(Bit#(16)) bytes_sent_to_phy_data <- mkReg(0);
    Reg#(Bit#(16)) bytes_written <- mkReg(0);

    Reg#(Bool) is_frame_fully_written <- mkReg(False);
    Reg#(Bool) buffer_in_use <- mkReg(False);

    Reg#(Bool) is_msb_nibble <- mkReg(False);
    Reg#(Bit#(4)) msb_nibble <- mkReg(0);      

    Reg#(Bit#(6)) interframe_counter <- mkReg(0);
    
//  send byte addr rule
    rule r_phy_send_byte_addr if ((!initialize_bram) && (bytes_written > bytes_sent_to_phy_addr) && (bytes_sent_to_phy_addr == bytes_sent_to_phy_data) && (buffer_in_use));

        frame.a.put(False, bytes_sent_to_phy_addr, ?); //   read next data byte
        bytes_sent_to_phy_addr <= bytes_sent_to_phy_addr + 1; //    byte sent to phy layer ++
    endrule

//  send lower nibble
    rule r_phy_send_lsb_nibble if ((!initialize_bram) && (bytes_written > bytes_sent_to_phy_data) && (bytes_sent_to_phy_addr > bytes_sent_to_phy_data) && (buffer_in_use) && (!is_msb_nibble));

        Bit#(8) bram_data_out = frame.a.read(); // read data byte from BRAM
        ValidNibble phy_tx_data = ValidNibble { 
            valid: True,
            data_nibble: bram_data_out[3:0] //  store lower 4 bits
        };        
        phy_tx.send_data(phy_tx_data);
        msb_nibble <= bram_data_out[7:4]; // store upper 4 bits
        is_msb_nibble <= True; //   set MSB nibble to TRUE

        bytes_sent_to_phy_data <= bytes_sent_to_phy_data + 1;   // byte sent to phy ++
    endrule

//  send upper nibble
    rule r_phy_send_msb_nibble if ((!initialize_bram) && (buffer_in_use) && (is_msb_nibble)); // if upper nibble needs to be sent 

        ValidNibble phy_tx_data = ValidNibble {
            valid: True,
            data_nibble: msb_nibble // send MSB nibble
        };        
        phy_tx.send_data(phy_tx_data);
        is_msb_nibble <= False; // set MSB nibble to FLASE
    endrule

//  send interframe gap
    rule r_interframe_gap ((!initialize_bram) && (buffer_in_use) && (!is_msb_nibble) && (bytes_written == bytes_sent_to_phy_addr) && (bytes_sent_to_phy_addr == bytes_sent_to_phy_data) && (interframe_counter < 6'h1A));
        if (interframe_counter < 6'h1A) begin // if interframe couter value is less than 26
            interframe_counter <= interframe_counter + 1; // interframe counter ++
            ValidNibble phy_tx_data = ValidNibble {
                valid: False,   // No valild nibble
                data_nibble: 4'h0 // send an empty nibble
            };        
            phy_tx.send_data(phy_tx_data);
        end
    endrule

//  send reset setup
    rule r_reset_setup if ((!initialize_bram) && (is_frame_fully_written) && (buffer_in_use) && (bytes_sent_to_phy_data == bytes_written) && (bytes_sent_to_phy_addr == bytes_written) && (!is_msb_nibble) && (interframe_counter >= 6'h1A));
        // reset all the variables
        buffer_in_use <= False;
        is_frame_fully_written <= False;
        bytes_written <= 0;
        bytes_sent_to_phy_addr <= 0;
        bytes_sent_to_phy_data <= 0;
        interframe_counter <= 0;
        `ifdef DEBUG $display("%t mkEthIPTX: r_reset_setup. Frame fully sent", $time); `endif
    endrule


    interface MacTXIfc mac_tx;

        method Bool m_ready_to_recv_next_frame;
            return (!buffer_in_use); // send buffer use information for new frame to be sent
        endmethod

        method Action m_write_tx_frame (Bit#(8) data, Bool is_last_byte) if (((!buffer_in_use) || (buffer_in_use && !is_frame_fully_written)) && !initialize_bram); // if butter is free and not fully written

            if (!buffer_in_use) begin // and if buffer is not used by anyone
                buffer_in_use <= True; // make the buffer use true
                bytes_written <= zeroExtend(initialize_bram_count)+1; // increment bytes written
                frame.b.put(True, zeroExtend(initialize_bram_count), data); // write data byte to BRAM
            end
            else begin
                frame.b.put(True, bytes_written, data);
                bytes_written <= bytes_written + 1;
            end

            if (is_last_byte) begin // if this is the last byte, mark frame as fully written
                is_frame_fully_written <= True;
            end

        endmethod
        
    endinterface: mac_tx

    interface phy = phy_tx.phy;

endmodule

endpackage


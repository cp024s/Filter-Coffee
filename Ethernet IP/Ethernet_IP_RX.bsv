package Ethernet_IP_RX;

import  Clocks::*;
import  BRAMCore::*;
import  FIFO::*;
import  FIFOF::*;
import  Ethernet_IP_Phy::*;

// `define FrameSize 1520
typedef 16 BRAM_addr_size;
typedef 8 BRAM_data_size;
typedef `FrameSize BRAM_memory_size;



interface MacRXIfc;

    method Bool m_is_new_frame_available;
    method Bool m_is_last_data_rcvd;

    method Action m_start_reading_rx_frame;
    method ActionValue#(Bit#(8)) m_read_rx_frame;
    method Action m_finished_reading_rx_frame;
    method Action m_stop_receiving_current_frame;

    method Bit#(16) m_get_bytes_sent;    
    
endinterface

interface RXIfc;
    (* prefix="" *)
    interface PhyRXIfc phy;
    interface MacRXIfc mac_rx; 
endinterface

typedef enum {STATE_IDLE, STATE_PAYLOAD} PhyRXState
deriving (Bits, Eq, FShow);

// `define DEBUG 1

(*synthesize*)
module mkEthIPRX#(Clock eth_mii_rx_clk, Reset eth_mii_rstn) (RXIfc);


    let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;

    EthIPRXPhyIfc phy_rx <- mkEthIPRXPhy(clocked_by eth_mii_rx_clk, reset_by eth_mii_rstn, core_clock); 

    Reg#(Bool) is_msb_nibble <- mkReg(False);
    Reg#(Bit#(4)) prev_nibble <- mkReg(?);  
    Reg#(PhyRXState) phy_rx_state <- mkReg(STATE_IDLE);

    FIFOF#(ValidByte) data_fifo <- mkFIFOF;

    rule r_phy_get_byte;

        ValidNibble phy_rx_data <- phy_rx.get_data;
        prev_nibble <= phy_rx_data.data_nibble;

        if (!phy_rx_data.valid) begin
            phy_rx_state <= STATE_IDLE;
        end
        else if ((phy_rx_data.valid) && (phy_rx_data.data_nibble == 4'hD) && (prev_nibble == 4'h5) && (phy_rx_state == STATE_IDLE)) begin
            phy_rx_state <= STATE_PAYLOAD;
        end

        if (phy_rx_state == STATE_IDLE) begin
            is_msb_nibble <= False;
        end
        else if (phy_rx_state == STATE_PAYLOAD) begin
            is_msb_nibble <= !is_msb_nibble;
        end

        if ((phy_rx_state == STATE_PAYLOAD) && (is_msb_nibble)) begin
            ValidByte data = ValidByte {
                valid : True,
                data_byte: {phy_rx_data.data_nibble, prev_nibble}
            };
            data_fifo.enq(data);
        end
        else if (phy_rx_state == STATE_IDLE) begin
            ValidByte data = ValidByte {
                valid : False,
                data_byte: {phy_rx_data.data_nibble, prev_nibble}
            };
            data_fifo.enq(data);
        end

    endrule



    Reg#(Bool) buffer_in_use <- mkReg(False);
    Reg#(Bool) is_current_frame_getting_stored <- mkReg(False);
    Reg#(Bool) is_frame_fully_rcvd <- mkReg(False);

    BRAM_DUAL_PORT#(Bit#(BRAM_addr_size), Bit#(BRAM_data_size)) frame <- mkBRAMCore2(valueOf(BRAM_memory_size), False);
    Reg#(Bit#(16)) bytes_rcvd_from_phy <- mkReg(0);
    Reg#(Bit#(16)) bytes_sent_req_rcvd <- mkReg(0);
    Reg#(Bit#(16)) bytes_sent_data_sent <- mkReg(0);

    Reg#(Bool) prev_valid <- mkReg(False);

    Reg#(Bool) stop_rx <- mkReg(False);

    rule r_stop_recv_frame if (stop_rx && is_frame_fully_rcvd);
        stop_rx <= False;
        is_frame_fully_rcvd <= False;
        buffer_in_use <= False;
        bytes_rcvd_from_phy <= 0;
        bytes_sent_req_rcvd <= 0;
        bytes_sent_data_sent <= 0;
        `ifdef DEBUG $display("%t mkEthIPRX: r_stop_recv_frame executed", $time); `endif
    endrule

    rule r_store_byte if (!is_frame_fully_rcvd); 

        ValidByte phy_rx_data = data_fifo.first;
        data_fifo.deq;

        Bool curr_valid = phy_rx_data.valid;
        prev_valid <= phy_rx_data.valid;
        Bit#(8) curr_data  = phy_rx_data.data_byte;

        if (curr_valid && !prev_valid) begin
            if (buffer_in_use) begin
                is_current_frame_getting_stored <= False;
                `ifdef DEBUG $display("%t mkEthIPRX: r_phy_get_byte. skipping frame since previous frame is not fully received", $time); `endif
            end
            else begin
                buffer_in_use <= True;
                is_current_frame_getting_stored <= True;
                frame.a.put(True, 0, curr_data);
                bytes_rcvd_from_phy <= 1;
                `ifdef DEBUG $display("%t mkEthIPRX: r_phy_get_byte. started receiving new frame addr %d data %h", $time, bytes_rcvd_from_phy, curr_data); `endif
            end
        end
        else if (curr_valid && is_current_frame_getting_stored) begin
            if (bytes_rcvd_from_phy < `FrameSize) begin
                bytes_rcvd_from_phy <= bytes_rcvd_from_phy + 1;
                frame.a.put(True, bytes_rcvd_from_phy, curr_data);
                `ifdef DEBUG $display("%t mkEthIPRX: r_phy_get_byte: receiving addr %d data %h", $time, bytes_rcvd_from_phy, curr_data); `endif
            end
        end
        else if (!curr_valid && prev_valid && is_current_frame_getting_stored) begin
            is_current_frame_getting_stored <= False;
            is_frame_fully_rcvd <= True;
            `ifdef DEBUG $display("%t mkEthIPRX: r_phy_get_byte. frame fully received", $time); `endif
        end
    endrule

    PulseWire read_rx_frame_conflict <- mkPulseWire;





    interface MacRXIfc mac_rx;

        method Bool m_is_new_frame_available;
            return ((bytes_rcvd_from_phy >= 1) && (bytes_sent_req_rcvd == 0) && (buffer_in_use));
        endmethod

        method Bool m_is_last_data_rcvd;
            return is_frame_fully_rcvd && (bytes_sent_data_sent == bytes_rcvd_from_phy) && buffer_in_use;
        endmethod

        method Bit#(16) m_get_bytes_sent;
                return bytes_sent_data_sent;
        endmethod

        method Action m_stop_receiving_current_frame if (!stop_rx);
            if (buffer_in_use) begin
                stop_rx <= True;
            end
        endmethod

        method Action m_finished_reading_rx_frame if (is_frame_fully_rcvd && !stop_rx);
            if (buffer_in_use) begin
                buffer_in_use <= False;
                bytes_rcvd_from_phy <= 0;
                bytes_sent_req_rcvd <= 0;
                bytes_sent_data_sent <= 0;
                is_frame_fully_rcvd <= False;
                read_rx_frame_conflict.send();
            end
        endmethod

        method Action m_start_reading_rx_frame if (
            (buffer_in_use) &&
            (bytes_sent_req_rcvd == 0) &&
            (bytes_rcvd_from_phy >= 1) &&
            (!stop_rx) &&
            (!read_rx_frame_conflict)
        );
            bytes_sent_req_rcvd <= bytes_sent_req_rcvd + 1;            
            frame.b.put(False, bytes_sent_req_rcvd, ?);
        endmethod

        method ActionValue#(Bit#(8)) m_read_rx_frame if (
            (buffer_in_use) &&
            (bytes_sent_req_rcvd >= 1) &&
            (((bytes_sent_data_sent < bytes_sent_req_rcvd) && (bytes_sent_req_rcvd < bytes_rcvd_from_phy)) ||
             ((bytes_sent_data_sent < bytes_sent_req_rcvd) && (bytes_sent_req_rcvd == bytes_rcvd_from_phy) && (is_frame_fully_rcvd))) &&
            (!stop_rx) &&
            (!read_rx_frame_conflict)
        );
            if (bytes_sent_req_rcvd < bytes_rcvd_from_phy) begin
                bytes_sent_req_rcvd <= bytes_sent_req_rcvd + 1;
                frame.b.put(False, bytes_sent_req_rcvd, ?);
            end
            bytes_sent_data_sent <= bytes_sent_data_sent + 1;
            Bit#(8) data = frame.b.read();
            return data;
        endmethod

    endinterface: mac_rx


    interface phy = phy_rx.phy;

endmodule

endpackage


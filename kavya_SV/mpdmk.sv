`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/29/2024 09:15:09 AM
// Design Name: 
// Module Name: mpdmk
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
typedef struct {
	bit id;
	Index tag;
	bit res;
} Tagged_index;


interface EthIPPhyIfc;
	mii_phy_rx mii_phy_rx = ethernet.mii_phy_rx;
	 mii_phy_tx mii_phy_tx = ethernet.mii_phy_tx;
endinterface

interface MPDIfc;
    EthIPPhyIfc eth_phy;
    PrtIfc prt_table;
    extern task get_header;
    extern task send_result (input bit ethid ,input  Tagged_index tag,input  bit result); //check tag
endinterface 



typedef union tagged { 
    void Invalid;
    int Valid ;
}Vtag;

typedef struct {
	bit id;
	Index tag;
	Header header;
} Fifo_struct;

typedef struct {
	Bit#(8) protocol;
	Bit#(32) srcip;
	Bit#(32) dstip;
	Bit#(16) srcport;
	Bit#(16) dstport;
} Header;

typedef enum logic { FALSE, TRUE } BOOL;

typedef enum logic { CHECK_PRT_IF_SLOT_AVAILABLE, GET_FRAME_DATA } ReceiveFrameState ;
ReceiveFrameState receive_frame_state;

typedef enum logic {HEADER_AVAILABLE, HEADER_NOT_AVAILABLE} HeaderAvailability;
HeaderAvailability header_availability;

typedef enum logic {START_TX, SEND_FRAME_DATA} SendFrameState;
SendFrameState send_frame_state;

module mpdmk( input logic eth_mii_rx_clk, input logic eth_mii_tx_clk, input logic eth_mii_rx_rstn, input logic eth_mii_tx_rstn, MPDIfc mkmpd);
       //declarations 
        Vtag rx_slot;
        int slot ;
        BOOL currently_recv_packet_is_unsafe ;
        logic [7:0]            data ;
        logic [7:0] addr; // the addr bit need to check
        //registers 
        logic [7:0] rx_header_protocol;
	    logic [31:0] rx_header_srcip ;
        logic [31:0] rx_header_dstip ;
	    logic [15:0] rx_header_srcport;
	    logic [15:0] rx_header_dstport;
        logic [31:0] protocol;
        logic current_recv_packet_slot;  //Index size ??
        //fifo 
	   FIFOF#(Fifo_struct) fifo_to_firewall <- mkFIFOF;								// Header is pushed into this FIFO. Firewall will read from this FIFO
	   FIFOF#(Tagged_index) to_invalidate_fifo <- mkFIFOF;								// unsafe packets classified by firewall which needs to be invalidated 
	   FIFOF#(Tagged_index) to_send_fifo <- mkFIFOF;									// safe packers classified by firewall which needs to be sent out

        
        initial begin 
            receive_frame_state = CHECK_PRT_IF_SLOT_AVAILABLE;
            header_availability = HEADER_NOT_AVAILABLE;	
            rx_slot = tagged Invalid;
            currently_recv_packet_is_unsafe = FALSE;	
        end 
        
        always_ff @ (posedge eth_mii_rx_clk) begin 
            if (receive_frame_state == CHECK_PRT_IF_SLOT_AVAILABLE) begin 
                if (prt_table.is_prt_slot_free && ethernet.mac_rx.m_is_new_frame_available)begin  
                    ethernet.mac_rx.m_start_reading_rx_frame;
                    slot <= prt_table.start_writing_prt_entry;
                    rx_slot <= tagged Valid(slot);
                    receive_frame_state<= GET_FRAME_DATA;
                end  
            end 
        end 
        always_ff @ (posedge eth_mii_rx_clk) begin
                data <= ethernet.mac_rx.m_read_rx_frame;
                prt_table.write_prt_entry(data);
                addr <= ethernet.mac_rx.m_get_bytes_sent;
		        if (addr == 23) begin
			         protocol <= data;
			         rx_header_protocol <= protocol;
		        end
		        else if (addr == 26) begin
			         rx_header_srcip <= {data, 8'b0, 8'b0, 8'b0};
		        end
		        else if (addr == 27) begin
			         rx_header_srcip <= rx_header_srcip | {8'b0, data, 8'b0, 8'b0};
		        end
		        else if (addr == 28) begin
			         rx_header_srcip <= rx_header_srcip | {8'b0, 8'b0, data, 8'b0};
		        end
		        else if (addr == 29) begin
			         rx_header_srcip <= rx_header_srcip | {8'b0, 8'b0, 8'b0, data};
	           	end
	           	else if (addr == 30) begin
		            rx_header_dstip <= {data, 8'b0, 8'b0, 8'b0};
        		end
	           	else if (addr == 31) begin
			         rx_header_dstip <= rx_header_dstip | {8'b0, data, 8'b0, 8'b0};
	           	end
	            else if (addr == 32) begin
		              	rx_header_dstip <= rx_header_dstip | {8'b0, 8'b0, data, 8'b0};
		        end
		        else if (addr == 33) begin
			            rx_header_dstip <= rx_header_dstip | {8'b0, 8'b0, 8'b0, data};
		          end
		        else if (addr == 34) begin
		              	rx_header_srcport <= {data, 8'b0};
	           	end
	           	else if (addr == 35) begin
		              	rx_header_srcport <= rx_header_srcport | {8'b0, data};
		          end
		      else if (addr == 36) begin
			             rx_header_dstport <= {data, 8'b0};
		       end
		      else if (addr == 37) begin
		              	rx_header_dstport <= rx_header_dstport | {8'b0, data};
		              	header_availability <= HEADER_AVAILABLE;
		      end  
       end
       
       // push header to fifo
       always_ff @( posedge eth_mii_rx_clk) begin 
          Header rx_header;
		  rx_header.protocol = rx_header_protocol;
		  rx_header.srcip = rx_header_srcip;
		  rx_header.dstip = rx_header_dstip;
		  rx_header.srcport = rx_header_srcport;
		  rx_header.dstport = rx_header_dstport;
	
		  Fifo_struct fifo_entry;
		  fifo_entry.tag = rx_slot.Valid;
		  fifo_entry.id = 0;
		  fifo_entry.header = rx_header;
		  fifo_to_firewall.enq(fifo_entry);
		  header_availability <= HEADER_NOT_AVAILABLE;
       end 
       
       //rx_finish_geting_frame_data 
       always_ff@(posedge eth_mii_rx_clk) begin
            receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		    rx_slot <= tagged Invalid;
	       	prt_table.finish_writing_prt_entry;
	       	ethernet.mac_rx.m_finished_reading_rx_frame; 
       end  
       
       //invalidate_unsafe_prt_entries ==check!!
       always_ff @(posedge eth_mii_rx_clk or posedge  eth_mii_tx_clk) begin 
              let firewall_output = to_invalidate_fifo.first; 
		      to_invalidate_fifo.deq;
		      if ((firewall_output.tag == rx_slot.Valid) && (isValid(rx_slot))) begin
			         currently_recv_packet_is_unsafe <= TRUE;
			         current_recv_packet_slot <= rx_slot.Valid;
		      end	
		      else begin
			         prt_table.invalidate_prt_entry(firewall_output.tag);
		      end
       end 
       //invalidate_currently_receiving_frame
       always_ff @(posedge eth_mii_rx_clk or posedge  eth_mii_tx_clk) begin 
              ethernet.mac_rx.m_stop_receiving_current_frame;
		      receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		      rx_slot <= tagged Invalid;
		      prt_table.invalidate_prt_entry(current_recv_packet_slot);
		      conflict_invalidating_two_entries_same_time.send();
		      currently_recv_packet_is_unsafe <= False;
       end 
       //tx_start_transmission
       always_ff @(posedge eth_mii_tx_clk) begin 
             let firewall_output = to_send_fifo.first;
	         to_send_fifo.deq;
		     prt_table.start_reading_prt_entry(firewall_output.tag);
           	 send_frame_state <= SEND_FRAME_DATA; 
       end 
       //tx_send_frame_data
       always_ff @(posedge eth_mii_tx_clk) begin 
             temp <- prt_table.read_prt_entry;
		      if (temp.is_last_byte) begin
			     send_frame_state <= START_TX;
			     ethernet.mac_tx.m_write_tx_frame(temp.data_byte, True);
		      end
		      else begin
			     ethernet.mac_tx.m_write_tx_frame(temp.data_byte, False);
		      end 
       end 
       //methods in bsv put in the interface 
       task mkmpd.get_header;
            let header = fifo_to_firewall.first;
		    fifo_to_firewall.deq;
		    return header;   
       endtask
           
       task mkmpd.send_result (input bit ethid ,input  Tagged_index tag,input  bit result);
              Tagged_index firewall_output;
		      firewall_output.id = ethid;
		      firewall_output.tag = tag;
		      firewall_output.res = result;
		      if (result == 1) to_send_fifo.enq(firewall_output);
		      else to_invalidate_fifo.enq(firewall_output);
       endtask
endmodule

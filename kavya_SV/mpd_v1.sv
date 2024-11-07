/////////


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2024 09:01:22 AM
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

 

typedef enum logic { FALSE, TRUE } BOOL;

typedef enum { CHECK_PRT_IF_SLOT_AVAILABLE, GET_FRAME_DATA} ReceiveFrameState;
ReceiveFrameState receive_frame_state;

typedef enum { HEADER_AVAILABLE, HEADER_NOT_AVAILABLE} HeaderAvailability;
HeaderAvailability header_availability;

typedef enum { START_TX, SEND_FRAME_DATA} SendFrameState;
SendFrameState send_frame_state;

module mpdmk(input logic clk,rst);
        //the struct    
        
        typedef bit Tag;  //refer the size of tag 
        typedef bit  Index; //changes to in tag
        
        typedef union tagged {
            int Valid ;
            void Invalid ;
        } Vtag ;

        typedef struct {
	       bit id;
	       Index tag;
	       bit res;
        } Tagged_index;

        typedef struct {
	       logic [7:0]  protocol;
	       logic [31:0] srcip;
	       logic [31:0] dstip;
	       logic [15:0] srcport;
	       logic [15:0] dstport;
        } Header;

        typedef struct {
	       bit id;
	       Index tag;
	       Header header;
        } Fifo_struct;

        
        BOOL is_prt_slot_free;
        
        prt prtdut(.clk(clk) , .reset(rst), .is_prt_slot_free(is_prt_slot_free));        
        
        //queue 
        Fifo_struct fifo_to_firewall[$];  // Header is pushed into this FIFO. Firewall will read from this FIFO
	    Tagged_index to_invalidate_fifo[$];// unsafe packets classified by firewall which needs to be invalidated 
	    Tagged_index to_send_fifo[$];	
        //delare 
        Vtag rx_slot = tagged Invalid;
        int slot ;
        BOOL currently_recv_packet_is_unsafe ;
        logic [7:0]            data ;
        logic [7:0] addr; // the addr bit need to check
        Fifo_struct fifo_entry;

        //registers 
        logic [7:0] rx_header_protocol;
	    logic [31:0] rx_header_srcip ;
        logic [31:0] rx_header_dstip ;
	    logic [15:0] rx_header_srcport;
	    logic [15:0] rx_header_dstport;
        logic [31:0] protocol;
        logic current_recv_packet_slot; 
        
       always @ (posedge clk) begin 
            if (rst) begin 
                receive_frame_state = CHECK_PRT_IF_SLOT_AVAILABLE;
                header_availability = HEADER_NOT_AVAILABLE;	
                rx_slot = tagged Invalid;
                currently_recv_packet_is_unsafe = FALSE;	
            end
        end 
  

        always @(posedge clk) begin 
            if (is_prt_slot_free && ethernet.mac_rx.m_is_new_frame_available && receive_frame_state ==  CHECK_PRT_IF_SLOT_AVAILABLE) begin
                int slot;
			    ethernet.mac_rx.m_start_reading_rx_frame;
			    slot <= prtdut.start_writing_prt_entry;
			    rx_slot <= tagged Valid(slot);
			    receive_frame_state <= GET_FRAME_DATA;
		end
       end 
        always @ (posedge clk) begin
        
            if ((receive_frame_state == GET_FRAME_DATA) && (!currently_recv_packet_is_unsafe) && (header_availability == HEADER_NOT_AVAILABLE) && !ethernet.mac_rx.m_is_last_data_rcvd) begin
            
                data <= ethernet.mac_rx.m_read_rx_frame;
                prtdut.write_prt_entry(data);
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
		 end 
      
       
       // push header to fifo
       always @( posedge clk) begin 
        if (header_availability == HEADER_AVAILABLE) begin 
          Header rx_header;
		  rx_header.protocol <= rx_header_protocol;
		  rx_header.srcip <= rx_header_srcip;
		  rx_header.dstip <= rx_header_dstip;
		  rx_header.srcport <= rx_header_srcport;
		  rx_header.dstport <= rx_header_dstport;
		  fifo_entry.tag <= rx_slot.Valid;
		  fifo_entry.id <= 0;
		  fifo_entry.header <= rx_header;
		  fifo_to_firewall.push_back(fifo_entry);
		  header_availability <= HEADER_NOT_AVAILABLE;
		end
       end 
       
       //rx_finish_geting_frame_data 
       always_ff@(posedge clk) begin
          if ((receive_frame_state == GET_FRAME_DATA) && (!currently_recv_packet_is_unsafe) && (header_availability == HEADER_NOT_AVAILABLE) && ethernet.mac_rx.m_is_last_data_rcvd) begin 
            receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		    rx_slot <= tagged Invalid;
	       	prtdut.finish_writing_prt_entry;
	       	ethernet.mac_rx.m_finished_reading_rx_frame;
	      end  
       end  
       
       //invalidate_unsafe_prt_entries 
       always_ff @(posedge clk) begin 
           if (!rst) begin //(to_invalidate_fifo.notEmpty) 
              Tagged_index firewall_output; 
              firewall_output = to_invalidate_fifo.pop_front; 
		      to_invalidate_fifo.pop_front;
		      if ((firewall_output.tag == rx_slot.Valid) && (isValid(rx_slot))) begin
			     currently_recv_packet_is_unsafe <= TRUE;
			     current_recv_packet_slot <= rx_slot.Valid;
		      end	
		      else begin
			     prtdut.invalidate_prt_entry(firewall_output.tag);
		      end
		    end
       end 
       
       //invalidate_currently_receiving_frame
       always_ff @(posedge clk) begin 
            if(currently_recv_packet_is_unsafe) begin
              ethernet.mac_rx.m_stop_receiving_current_frame;
		      receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		      rx_slot <= tagged Invalid;
		      prtdut.invalidate_prt_entry(current_recv_packet_slot);
		      currently_recv_packet_is_unsafe <= FALSE;
		    end 
       end 
       //tx_start_transmission
       always_ff @(posedge clk) begin 
          if ((send_frame_state == START_TX)  && (ethernet.mac_tx.m_ready_to_recv_next_frame)) begin //&& (to_send_fifo.notEmpty)
             Tagged_index firewall_output;
             firewall_output <= to_send_fifo.pop_front;
	         to_send_fifo.pop_front;
		     prtdut.start_reading_prt_entry(firewall_output.tag);
           	 send_frame_state <= SEND_FRAME_DATA; 
           end 
       end 
       //tx_send_frame_data
       always_ff @(posedge clk) begin 
          if (send_frame_state == SEND_FRAME_DATA) begin 
             logic temp;
             temp <= prtdut.read_prt_entry;
		      if (temp.is_last_byte) begin
			     send_frame_state <= START_TX;
			     ethernet.mac_tx.m_write_tx_frame(temp.data_byte, TRUE);
		      end
		      else begin
			     ethernet.mac_tx.m_write_tx_frame(temp.data_byte, FALSE);
		      end 
		   end 
       end 
       //methods in bsv put in the interface 
       function  Fifo_struct get_header;
            Fifo_struct header ;
            header = fifo_to_firewall.pop_front;
		    fifo_to_firewall.pop_front;
		    return header;   
       endfunction
           
       function void  send_result (input bit ethid ,input  Index tag ,input  bit result);
              Tagged_index firewall_output;
		      firewall_output.id = ethid;
		      firewall_output.tag = tag;
		      firewall_output.res = result;
		      if (result == 1) to_send_fifo.push_back(firewall_output);
		      else to_invalidate_fifo.push_back(firewall_output);
       endfunction
        
endmodule


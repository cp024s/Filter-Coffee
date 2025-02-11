                                     
interface MPDIfc;
	// AXI Interface to be connected to Ethernet IP
	interface EthIPPhyIfc eth_phy;
	
	// Methods to interact with MPD. To & Fro 
	method ActionValue#(Fifo_struct) get_header;							// Firewall uses this method to get header from MPD
	method Action send_result(bit ethid_in, Index tag_in, bit result);		// Firewall uses this method to send result to MPD
endinterface


typedef enum { CHECK_PRT_IF_SLOT_AVAILABLE, GET_FRAME_DATA} ReceiveFrameState
deriving (Bits, Eq, FShow);

typedef enum { HEADER_AVAILABLE, HEADER_NOT_AVAILABLE} HeaderAvailability
deriving (Bits, Eq, FShow);

typedef enum { START_TX, SEND_FRAME_DATA} SendFrameState
deriving (Bits, Eq, FShow);

`define MPD_DEBUG 1

(*synthesize*)
module mkMPD#(Clock eth_mii_rx_clk, Clock eth_mii_tx_clk, Reset eth_mii_rx_rstn, Reset eth_mii_tx_rstn) (MPDIfc);

	let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;
	EthIPIfc ethernet <- mkEthIP(clocked_by core_clock, reset_by core_reset, eth_mii_rx_clk, eth_mii_tx_clk, eth_mii_rx_rstn, eth_mii_tx_rstn); 
	
	PRTIfc prt_table <- mkPRT;							// PRT Table

	//PktIfc packet_detector <- mkpktd;

	Reg#(ReceiveFrameState) receive_frame_state <- mkReg(CHECK_PRT_IF_SLOT_AVAILABLE); 	// State of receiving the frame
	Reg#(Maybe#(Bit#(`Index_Size))) rx_slot <- mkReg(Invalid);							// Slot of PRT in which the currently receiving frame is stored

	// This rule starts the receiving process if
	//		1) prt_table.is_prt_slot_free: Free PRT Slot is available
	//		2) ethernet.mac_rx.m_is_new_frame_available: If Ethernet is available to start receiving a new frame
	//		3) ethernet.mac_rx.m_start_reading_rx_frame: If Ethernet is available to start receiving a new frame
	//		4) (receive_frame_state ==  CHECK_PRT_IF_SLOT_AVAILABLE): If MPD is not currently receiving any frame.
	//		5) prt_table.start_writing_prt_entry: 
	// This rule sends the signal to transactor telling it to start checking the IP if any packet is available to be received. The PRT will return the slot where the
	// frame that is going to be received will be stored. This slot is stored in rx_slot register.
	rule rx_check_prt_if_slot_available if (receive_frame_state ==  CHECK_PRT_IF_SLOT_AVAILABLE); 
		if (prt_table.is_prt_slot_free && ethernet.mac_rx.m_is_new_frame_available) begin
			ethernet.mac_rx.m_start_reading_rx_frame;
			let slot <- prt_table.start_writing_prt_entry;
			rx_slot <= tagged Valid(slot);
			receive_frame_state <= GET_FRAME_DATA;
			`ifdef MPD_DEBUG $display("%t: MPD: Rule: rx_check_prt_if_slot_available. PRT Slot available. Requesting Transactor 0 to start receiving", $time); `endif
		end
	endrule

	// As frame is being received, header is stored in these registers
	Reg#(Bit#(8)) rx_header_protocol <- mkReg(?);
	Reg#(Bit#(32)) rx_header_srcip <- mkReg(?);
	Reg#(Bit#(32)) rx_header_dstip <- mkReg(?);
	Reg#(Bit#(16)) rx_header_srcport <- mkReg(?);
	Reg#(Bit#(16)) rx_header_dstport <- mkReg(?);

	Reg#(HeaderAvailability) header_availability <- mkReg(HEADER_NOT_AVAILABLE);	// Have we received the header of the frame that is being currently received
	FIFOF#(Fifo_struct) fifo_to_firewall <- mkFIFOF;								// Header is pushed into this FIFO. Firewall will read from this FIFO
	FIFOF#(Tagged_index) to_invalidate_fifo <- mkFIFOF;								// unsafe packets classified by firewall which needs to be invalidated 
	FIFOF#(Tagged_index) to_send_fifo <- mkFIFOF;									// safe packers classified by firewall which needs to be sent out

	Reg#(Bool) currently_recv_packet_is_unsafe <- mkReg(False);			// If the firewall classifies that the currently receiving frame is unsafe, this register is set

	// This rule obtains the frame word-after-word and pushes it into the PRT entry. At the same time if sufficient frame is received such that header is available, it 
	// also stores the header information.
	// Conditions:
	//		1) (receive_frame_state == GET_FRAME_DATA): rx_get_frame_len rule must have been executed before
	//		2) (!currently_recv_packet_is_unsafe): If the firewall determines that the currently receiving frame is unsafe
	//		3) (header_availability == HEADER_NOT_AVAILABLE): Only when header of previous frame is pushed into FIFO.
	//		4) (!ethernet.mac_rx.m_is_last_data_rcvd): Read until the last byte is received
	// Receive until the last byte is received. 
	rule rx_get_frame_data if ((receive_frame_state == GET_FRAME_DATA) && (!currently_recv_packet_is_unsafe) && (header_availability == HEADER_NOT_AVAILABLE) && !ethernet.mac_rx.m_is_last_data_rcvd);

		let data <- ethernet.mac_rx.m_read_rx_frame;  
		prt_table.write_prt_entry(data);


		/* 
		data_frm_pkt = data; 
		//ethernet.mac_rx.m_get_bytes_sent; //gots only bytes 
		










		header_availability <= HEADER_AVAILABLE;

		*/
		let addr = ethernet.mac_rx.m_get_bytes_sent;
		if (addr == 23) begin
			let protocol = data;
			rx_header_protocol <= protocol;
			`ifdef MPD_DEBUG $display("%t: MPD: Rule: rx_get_frame_data. Protocol: %h", $time, protocol); `endif
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

	endrule

	// Once the header of the frame is received, this rule pushes it into the to_firewall FIFO
	// Conditions:
	//		1) (header_availability == HEADER_AVAILABLE): Header must be available
	//		2) If the to_firewall FIFO has space in it to push the header information.
	rule push_header_into_firewall_fifo if (header_availability == HEADER_AVAILABLE); 
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

		`ifdef MPD_DEBUG $display("\n"); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Pushing header of frame in slot %d into firewall FIFO", $time, rx_slot.Valid); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Protocol: %h", $time, rx_header.protocol); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Src IP: %h", $time, rx_header.srcip); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Dst IP: %h", $time, rx_header.dstip); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Src Port: %h", $time, rx_header.srcport); `endif
		`ifdef MPD_DEBUG $display("%t: MPD: Dst Port: %h", $time, rx_header.dstport); `endif
		`ifdef MPD_DEBUG $display("\n"); `endif	

	endrule

	// Once the entire frame is received, finish the reception
	// Conditions:
	//		1) (receive_frame_state == GET_FRAME_DATA): rx_get_frame_len rule must have been executed before
	//		2) (!currently_recv_packet_is_unsafe): If the firewall determines that the currently receiving frame is unsafe
	//		3) (header_availability == HEADER_NOT_AVAILABLE): Only when header of previous frame is pushed into FIFO.
	//		4) (ethernet.mac_rx.m_is_last_data_rcvd): Is last byte is received
	// Finish reading 
	rule rx_finish_geting_frame_data if ((receive_frame_state == GET_FRAME_DATA) && (!currently_recv_packet_is_unsafe) && (header_availability == HEADER_NOT_AVAILABLE) && ethernet.mac_rx.m_is_last_data_rcvd);
		receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		rx_slot <= tagged Invalid;
		prt_table.finish_writing_prt_entry;
		ethernet.mac_rx.m_finished_reading_rx_frame;
	endrule






	// When two rules are trying to invalidate multiple PRT entries at the same time, it causes conflict. So to prevent this
	PulseWire conflict_invalidating_two_entries_same_time <- mkPulseWire;
	// The slot where the frame is being currently received. If firewall determines that this currently receiving packet is unsafe, it will invalidate this PRT slot			
	Reg#(Bit#(`Index_Size)) current_recv_packet_slot <- mkReg(0);


	// (* conflict_free = "invalidate_unsafe_prt_entries, rx_get_frame_data" *)
	// These rules are conflict free because this rule does not directly invalidate the prt entry where the currently receiving frame is getting stored 
	(* conflict_free = "invalidate_unsafe_prt_entries, rx_get_frame_data" *)
	// (* conflict_free = "invalidate_unsafe_prt_entries, rx_finish_geting_frame_data" *)
	// These rules are conflict free because this rule does not directly invalidate the prt entry where the currently receiving frame is getting stored 
	(* conflict_free = "invalidate_unsafe_prt_entries, rx_finish_geting_frame_data" *)

	(* preempts = "invalidate_unsafe_prt_entries, rx_check_prt_if_slot_available"*)
	// This rule will get information from the to_invalidate FIFO containing the slots that are to be invalidated. 
	// However, If the firewall determines that the currently receiving frame is unsafe, this rule will not directly invalidate the PRT entry where the currently 
	// receiving frame is getting stored. Instead it will pass it on to the `invalidate_currently_receiving_frame` rule which will stop receiving the frame and invalidate the PRT slot.
	// Conditions:
	//		1) (to_invalidate_fifo.notEmpty): If there is any entry in to_invalidate FIFO
	// 		2) (!conflict_invalidating_two_entries_same_time): If `invalidate_currently_receiving_frame` is also invalidating a PRT entry at the same time
	rule invalidate_unsafe_prt_entries if ((to_invalidate_fifo.notEmpty) && (!conflict_invalidating_two_entries_same_time));
		let firewall_output = to_invalidate_fifo.first; 
		to_invalidate_fifo.deq;
		`ifdef MPD_DEBUG $display("%t: MPD: Rule: invalidate_unsafe_prt_entries. Slot %d is UNSAFE. Sending invalidate signal to PRT", $time, firewall_output.tag); `endif
		if ((firewall_output.tag == rx_slot.Valid) && (isValid(rx_slot))) begin
			currently_recv_packet_is_unsafe <= True;
			current_recv_packet_slot <= rx_slot.Valid;
		end	
		else begin
			prt_table.invalidate_prt_entry(firewall_output.tag);
		end
	endrule


	(* preempts = "invalidate_currently_receiving_frame, rx_check_prt_if_slot_available"*)
	// This rule will invalidate the PRT entry where the currently receiving frame is stored. It will also stop the transactor from receiving the frame anymore & will start the RX process again
	// Conditions:
	//		1) (currently_recv_packet_is_unsafe): If `invalidate_unsafe_prt_entries` executed previously and determined that the current frame is unsafe
	rule invalidate_currently_receiving_frame if (currently_recv_packet_is_unsafe);
		ethernet.mac_rx.m_stop_receiving_current_frame;
		receive_frame_state <= CHECK_PRT_IF_SLOT_AVAILABLE;
		rx_slot <= tagged Invalid;
		prt_table.invalidate_prt_entry(current_recv_packet_slot);
		conflict_invalidating_two_entries_same_time.send();
		currently_recv_packet_is_unsafe <= False;
		`ifdef MPD_DEBUG $display("%t: MPD: Rule: invalidate_unsafe_prt_entries. Currently receiving frame at slot %d is invalidated", $time, rx_slot.Valid); `endif
	endrule





	Reg#(SendFrameState) send_frame_state <- mkReg(START_TX);		// State of transmitting a frame

	// This rule will get information from the to_send FIFO containing the slots of frames that are to be sent.
	// Conditions:
	//		1) (to_send_fifo.notEmpty): if there is an entry in the to_send FIFO
	//		2) (send_frame_state == START_TX): Ensures that we are already not sending any frame
	//		3) If the transactor is available for transmission.
	// This rule will give a request to PRT entertaining that the TX of the frame stored in the said slot will start. It also informs the transactor that a frame of tx_frame_len length
	// needs to be transmitted.
	rule tx_start_transmission if ((send_frame_state == START_TX) && (to_send_fifo.notEmpty) && (ethernet.mac_tx.m_ready_to_recv_next_frame));
		let firewall_output = to_send_fifo.first;
		to_send_fifo.deq;
		prt_table.start_reading_prt_entry(firewall_output.tag);
		send_frame_state <= SEND_FRAME_DATA;
	
		`ifdef MPD_DEBUG $display("%t: MPD: Rule: tx_start_transmission. Start transmission of frame from slot %d", $time, firewall_output.tag); `endif
	endrule


	// (* conflict_free = "invalidate_unsafe_prt_entries, tx_send_frame_data" *)
	// These rules are conflict free because you will not be invalidating the PRT entry which the firewall has determined as safe and transmission is happening already
	(* conflict_free = "invalidate_unsafe_prt_entries, tx_send_frame_data" *)

	// (* conflict_free = "invalidate_currently_receiving_frame, tx_send_frame_data" *)
	// These rules are conflict free because you will not be invalidating the PRT entry which the firewall has determined as safe and transmission is happening already
	(* conflict_free = "invalidate_currently_receiving_frame, tx_send_frame_data" *)

	// (* conflict_free = "rx_check_prt_if_slot_available, tx_send_frame_data" *)
	// These rules are conflict free because the underlying actions prt_table.start_writing_prt_entry and prt_table.read_prt_entry cannot happen for the same slot at the same time
	(* conflict_free = "rx_check_prt_if_slot_available, tx_send_frame_data" *)

	// This rule will obtain the data word-after-word from PRT table and sends it to the transactor so that it can be transmitted until the entire frame is transmitted.
	// Conditions:
	//		1) (send_frame_state == SEND_FRAME_DATA): rule `tx_start_transmission` must have been executed before to initialize transmission.
	rule tx_send_frame_data if (send_frame_state == SEND_FRAME_DATA);
		let temp <- prt_table.read_prt_entry;
		if (temp.is_last_byte) begin
			send_frame_state <= START_TX;
			//`ifdef MPD_DEBUG $display("%t: MPD: Rule: tx_send_frame_data. Entire frame transmitted to Ethernet Transactor", $time); `endif
			ethernet.mac_tx.m_write_tx_frame(temp.data_byte, True);
		end
		else begin
			// `ifdef MPD_DEBUG $display("%t: MPD: Rule: tx_send_frame_data. TX. DATA: %h", $time, data); `endif
			ethernet.mac_tx.m_write_tx_frame(temp.data_byte, False);
		end
	endrule



	

	// This method sends the header to the firewall. Call this method to obtain the header
	method ActionValue#(Fifo_struct) get_header;
		let header = fifo_to_firewall.first;
		fifo_to_firewall.deq;
		`ifdef MPD_DEBUG $display("%t: MPD: Method: get_header. Firewall receives header from MPD", $time); `endif
		return header;
	endmethod

	// This method receives the result from the firewall and stores it into `to_invalidate` or `to_send` FIFO depending on whether it is unsafe or safe. 
	method Action send_result(bit ethid, Index tag, bit result);
		Tagged_index firewall_output;
		firewall_output.id = ethid;
		firewall_output.tag = tag;
		firewall_output.res = result;
		if (result == 1) to_send_fifo.enq(firewall_output);
		else to_invalidate_fifo.enq(firewall_output);
		`ifdef MPD_DEBUG if (result == 1) $display("%t: MPD: Method: send_result. Firewall sends header response to MPD. Indicates frame at slot %d is SAFE", $time, tag);
		else $display("%t: MPD: Method: send_result. Firewall sends header response to MPD. Indicates frame at slot %d is UNSAFE", $time, tag); `endif
	endmethod

	interface EthIPPhyIfc eth_phy;
		interface mii_phy_rx = ethernet.mii_phy_rx;
		interface mii_phy_tx = ethernet.mii_phy_tx;
	endinterface

endmodule

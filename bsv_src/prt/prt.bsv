import Vector::*;
import ConfigReg::*;
import FIFO::*;
import FIFOF::*;
import Ref_Dtypes::*;
import BRAMCore :: *;

import Ethernet_IP::*;
import Ethernet_IP_TX::*;
import Ethernet_IP_RX::*;
import Ethernet_IP_Phy::*;

// PARAMS
// `define Index_Size 2
// `define Table_Size 4
// `define FrameSize 1520			// Header:: 14 MTU: 1500 FCS: 4
typedef 16 BRAM_addr_size;
typedef 8 BRAM_data_size;
typedef `FrameSize BRAM_memory_size;

// `define PRT_DEBUG 1

typedef struct {
	Reg#(Bool) valid;														// Validity of PRT entry
	BRAM_DUAL_PORT#(Bit#(BRAM_addr_size), Bit#(BRAM_data_size)) frame;		// Frame stored in BRAM
	Reg#(Bit#(16)) bytes_sent_req;											// Number of bytes transmitted from BRAM: BRAM requests
	Reg#(Bit#(16)) bytes_sent_res;											// Number of bytes transmitted from BRAM: BRAM responses
	Reg#(Bit#(16)) bytes_rcvd;												// Number of bytes of frame received and stored
	Reg#(Bool)	   is_frame_fully_rcvd;										// Is Frame fully received or not
} PRTEntry;	

typedef struct {
	Bit#(8) data_byte;
	Bool	is_last_byte;
} PRTReadOutput deriving (Bits, FShow, Eq);


interface PRTIfc;
	// Used for writing frames into the PRT
	method ActionValue#(Bit#(`Index_Size)) start_writing_prt_entry;
	method Action write_prt_entry (Bit#(8) data);
	method Action finish_writing_prt_entry;

	// Used for invalidating PRT entry. To be used when the firewall says it is unsafe
	method Action invalidate_prt_entry (Bit#(`Index_Size) slot);

	// Used for reading frames from the PRT
	method Action start_reading_prt_entry (Bit#(`Index_Size) slot) ;
	method ActionValue#(PRTReadOutput) read_prt_entry;
		
	// Check whether if any prt slot is available so that we can read frames.
	method Bool is_prt_slot_free ;
endinterface


(*synthesize*)
module mkPRT (PRTIfc);
	
	// Creating PRT Table
	Vector#(`Table_Size, PRTEntry) prt_table;
	for (Integer i=0; i<`Table_Size;i=i+1) begin
		prt_table[i].valid <- mkReg(False);
		prt_table[i].frame <- mkBRAMCore2(valueOf(BRAM_memory_size), False);
		prt_table[i].bytes_sent_req <- mkReg(0);
		prt_table[i].bytes_sent_res <- mkReg(0);
		prt_table[i].bytes_rcvd <- mkReg(0);
		prt_table[i].is_frame_fully_rcvd <- mkReg(False);
	end

	Reg#(Maybe#(Bit#(`Index_Size))) write_slot <- mkReg(tagged Valid(0)); 		// At which PRT entry is the incoming packet will be stored 
	Reg#(Bool) using_write_slot <- mkReg(False);								// Is the packet currently incoming?

	Reg#(Maybe#(Bit#(`Index_Size))) read_slot <- mkReg(Invalid);				// Which PRT entry is being transmitted.

	// During invalidating PRT entry, rule to find the write slot shall not be called to avoid deadlocks. 
	// This pulsewire is excited whenever an entry is invalidated.
	PulseWire conflict_update_write_slot <- mkPulseWire;

	// This rule finds the write_slot where a new incoming packet can be stored
	// This rule is fired only when 
	//      1) (!using_write_slot): There is no packet that is currently incoming and getting stored
	// 		2) (!isvalid(write_slot)): If the write_slot is not found
	//      3) (!conflict_update_write_slot): When there is no rule/method that is invalidating any of the PRT entries
	rule update_write_slot if (
		(!using_write_slot) && 
		(!isValid(write_slot)) && 
		!conflict_update_write_slot
	);
		Bool is_write_slot_available = False;
		Bit#(`Index_Size) temp_write_slot = 0;
		for (Integer i=0; i<`Table_Size;i=i+1) begin
			if (!prt_table[i].valid) begin
				is_write_slot_available = True;
				temp_write_slot = fromInteger(i);
			end
		end
		// `ifdef PRT_DEBUG $display("%t: PRT: Rule: update_write_slot. Updating write slot", $time); `endif
		if (is_write_slot_available) begin 
			write_slot <= tagged Valid(temp_write_slot);
			// `ifdef PRT_DEBUG $display("%t: PRT: Rule: update_write_slot. Empty write slot found at %d", $time, temp_write_slot); `endif
		end
		else begin
			write_slot <= tagged Invalid;
			// `ifdef PRT_DEBUG $display("%t: PRT: Rule: update_write_slot. Empty write not found", $time); `endif
		end
	endrule


	


	// Call this method to start storing the incoming packet. Pass the to be length of the frame in bytes.
	// This can be executed only when 
	//		1) isValid(write_slot):   A valid write_slot is available
	//		2) (!using_write_slot):   There is no other packet that is incoming. At a time, one one packet can be incoming.
	//		3) (!prt_table[write_slot.Valid].valid):  This checks whether if the slot at which the incoming packet is to be stored does not have a valid packet
	method ActionValue#(Bit#(`Index_Size)) start_writing_prt_entry if (
		isValid(write_slot) && 
		(!using_write_slot) && 
		(!prt_table[write_slot.Valid].valid)
	);
		Bit#(`Index_Size) slot = write_slot.Valid;
		prt_table[slot].valid <= True;
		prt_table[slot].bytes_rcvd <= 0;
		// prt_table[slot].bytes_sent_req <= 0;
		prt_table[slot].bytes_sent_req <= 1;
		prt_table[slot].bytes_sent_res <= 0;
		prt_table[slot].is_frame_fully_rcvd <= False;
		using_write_slot <= True; 
		`ifdef PRT_DEBUG $display("%t: PRT: Method: start_writing_prt_entry. Start storing packet at slot %d", $time, slot); `endif
		return slot;
	endmethod

	// Call this method to store the incoming frame word-after-word. Note: The frame has to be passed in a successive manner and is stored successively. So ordering is important
	// This can be execued only when
	//		1) isValid(write_slot):   A valid write_slot is available
	//		2) using_write_slot:      Ensures writing is possible only after the method 'start_writing_prt_entry' is called.
	//		3) !prt_table[write_slot.Valid].is_frame_fully_rcvd: The frame should not be fully received before i.e., you cannot call finish_writing_prt_entry before this rule
	// It receives word after word. 
	method Action write_prt_entry (Bit#(8) data) if (
		isValid(write_slot) && 
		(using_write_slot) && 
		(!prt_table[write_slot.Valid].is_frame_fully_rcvd)
	);
		Bit#(`Index_Size) slot = write_slot.Valid;
		prt_table[slot].frame.a.put(True, prt_table[slot].bytes_rcvd, data);
		prt_table[slot].bytes_rcvd <= prt_table[slot].bytes_rcvd + 1;
		// `ifdef PRT_DEBUG $display("%t: PRT: Method: write_prt_entry. Storing packet. ADDR: %h DATA: %h at slot %d", $time, prt_table[slot].bytes_rcvd, data, slot); `endif
	endmethod

	// Call this method to finish storing the incoming
	// This can be execued only when
	//		1) isValid(write_slot):   A valid write_slot is available
	//		2) using_write_slot:      Ensures writing is possible only after the method 'start_writing_prt_entry' is called.
	//		3) !prt_table[write_slot.Valid].is_frame_fully_rcvd: The frame should not be fully received before i.e., you cannot call this rule twice
	// It releases the write_slot and using_write_slot and sets frame_fully_received to true
	method Action finish_writing_prt_entry if (
		isValid(write_slot) && 
		(using_write_slot) && 
		(!prt_table[write_slot.Valid].is_frame_fully_rcvd) 
	);
		Bit#(`Index_Size) slot = write_slot.Valid;
		using_write_slot <= False;
		write_slot <= tagged Invalid;
		prt_table[slot].is_frame_fully_rcvd <= True;
		`ifdef PRT_DEBUG $display("%t: PRT: Method: finish_writing_prt_entry. Finished Storing packet at slot %d", $time, slot); `endif
	endmethod





	// Call this method to invalidate a PRT entry. Use this when the firewall says the packet is UNSAFE.
	// When invalidating a PRT entry, update_write_slot rule is not executed to prevent deadlock.
	// When you are invalidating a PRT entry, and the PRT entry is being currently written, then skip the writing process. Free the write_slot and using_write_slot, as well.
	// NOTE: It is user's responsibility to ensure that if a PRT entry is getting invalidated, it must also not call 'write_prt_entry' to write more frame data of the same slot
	//       at the same time. Otherwise, it might result in a lock.
	method Action invalidate_prt_entry (Bit#(`Index_Size) slot);
		`ifdef PRT_DEBUG $display("%t: PRT: Method: invalidate_prt_entry. Invalidating packet at slot %d", $time, slot); `endif
		conflict_update_write_slot.send();
		// When you invalidate, if the frame is already in the writing process, then skip the writing process completely
		if (isValid(write_slot) && (write_slot.Valid == slot) && (using_write_slot)) begin
			using_write_slot <= False;
			write_slot <= tagged Invalid;
			`ifdef PRT_DEBUG $display("%t: PRT: Method: invalidate_prt_entry. Packet that is being written is invalidated at slot %d. Write slots are released", $time, slot); `endif
		end
		if (prt_table[slot].valid) prt_table[slot].valid <= False;
	endmethod






	// Call this method to start transmitting a PRT entry. This method returns the frame length of the frame to be transmitted, if it is valid.
	// This method can be executed only when
	//		1) !isValid(read_slot): There is no other packet that is being currently transmitted.
	method Action start_reading_prt_entry (Bit#(`Index_Size) slot) if (!isValid(read_slot));
		if (!prt_table[slot].valid) begin 
			`ifdef PRT_DEBUG $display("%t: PRT: Method: start_reading_prt_entry. Invalid slot %d", $time, slot); `endif
		end
		else begin 
			read_slot <= tagged Valid(slot);
			// prt_table[slot].bytes_sent_req <= 1;
			// prt_table[slot].bytes_sent_res <= 0;
			prt_table[slot].frame.b.put(False, 0, ?);
			`ifdef PRT_DEBUG $display("%t: PRT: Method: start_reading_prt_entry. Start transmitting packet from slot %d", $time, slot); `endif
		end
	endmethod

	// Call this method to get the PRT entry frame word-after-word. Note: This is a successive process i.e., read the word one after other in the correct order. 
	// This method can be executed only when
	// 		1) isValid(read_slot):  Ensures that this rule can be executed after 'start_reading_prt_entry'
	//		2) prt_table[read_slot.Valid].valid:   Ensures that the slot we are trying to read is a valid slot. Now this would mean that if the slot is invalidated when reading then the user is locked in this process
	// 		3)	(((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req < prt_table[read_slot.Valid].bytes_rcvd)) ||
	// 			((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req == prt_table[read_slot.Valid].bytes_rcvd) && (prt_table[read_slot.Valid].is_frame_fully_rcvd)))
	// Once the frame is completely transmitted, then invalidate the PRT entry and release the read_slot. 
	method ActionValue#(PRTReadOutput) read_prt_entry if (
		(isValid(read_slot)) && 
		(prt_table[read_slot.Valid].valid) && 
		(((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req < prt_table[read_slot.Valid].bytes_rcvd)) ||
		 ((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req == prt_table[read_slot.Valid].bytes_rcvd) && (prt_table[read_slot.Valid].is_frame_fully_rcvd)))
	);
		Bit#(`Index_Size) slot = read_slot.Valid;
		let data = prt_table[slot].frame.b.read();
		prt_table[slot].bytes_sent_res <= prt_table[slot].bytes_sent_res + 1;

        if (prt_table[slot].bytes_sent_req < prt_table[slot].bytes_rcvd) begin
			prt_table[slot].frame.b.put(False, prt_table[slot].bytes_sent_req, ?);
            prt_table[slot].bytes_sent_req <= prt_table[slot].bytes_sent_req + 1;
        end
		
		if ((prt_table[slot].bytes_sent_res + 1 == prt_table[slot].bytes_rcvd) && (prt_table[slot].is_frame_fully_rcvd)) begin
			read_slot <= tagged Invalid;
			// Invalidate once the entire entry is pushed outside. 
			conflict_update_write_slot.send();
			prt_table[slot].valid <= False;
			`ifdef PRT_DEBUG $display("%t: PRT: Method: read_prt_entry. Transmitting packet complete. Invalidating PRT entry. Read slots are released", $time); `endif
			return PRTReadOutput { data_byte: data, is_last_byte: True };
		end
		else begin
			return PRTReadOutput { data_byte: data, is_last_byte: False };
		end
	endmethod


	// Call this method to find if there are any free slots where the incoming packet can be written. If false, then PRT table is full.
	method Bool is_prt_slot_free ;
		return (isValid(write_slot) && (!using_write_slot));
	endmethod

endmodule

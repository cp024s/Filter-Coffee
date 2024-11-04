
parameter int Index_Size = 1;
parameter int Table_Size = 8;
parameter int DATA_SIZE = 8;
parameter int DATA_ADDR_SIZE = 16;
parameter int FrameSize = 1518;

typedef enum {FALSE , TRUE} BOOL ;

typedef struct { 
        logic valid;														   
	    logic [0 : Table_Size]frame ;	//big endian?	                                     
	    logic [15:0] bytes_sent_req;											
	    logic [15:0] bytes_sent_res;											
	    logic [15:0] bytes_rcvd;												
	    logic       is_frame_fully_rcvd;
}PRTEntry;

typedef struct packed {
	    logic [7:0] data_byte;
    	logic 	is_last_byte;
} PRTReadOutput ;

typedef union tagged {
    void Invalid;
    int Valid;
} VInt;

module prt ( input clk, 
             input rst, 
             input [7:0] data,
             output is_prt_slot_free);
    //table 
    PRTEntry prt_table[0 : Table_Size];
   
    //initialize table 
    initial begin 
        for (int i = 0; i <Table_Size; i = i +1) begin 
            prt_table[i].valid <= 0; 
            prt_table[i].frame <= 0;
            prt_table[i].bytes_sent_req <= 0;
            prt_table[i].bytes_sent_res <= 0;
            prt_table[i].bytes_rcvd <=0; 
            prt_table[i].is_frame_fully_rcvd <= 0;
        end
    end  
   //slots :indicators of which slot is available to write or read
   VInt writeslot=tagged Valid(0);
   VInt readslot= tagged Invalid;
   
   //internal reg 
   logic using_write_slot;
   
   //update writeslot
   always_ff @(posedge clk)begin 
        if (!using_write_slot && (!isValid(writeslot))) begin 
            automatic BOOL is_write_slot_available = FALSE;
            automatic int temp_write_slot = 0;
            for ( int j = 0; j < Table_Size ; j = j+1) begin
                if (!prt_table[j].valid) begin
                    is_write_slot_available <= TRUE;
                    temp_write_slot <= j ;
                end
             end 
             if(is_write_slot_available) begin 
                writeslot <= tagged Valid(temp_write_slot);
             end 
             else begin
                writeslot <= tagged Invalid ;
             end     
        end 
   end 
   
   //1
   function bit start_writing_prt_entry ;  // [Index_Size:0]
    if ( isValid((writeslot)) &&    
		(!using_write_slot) && 
		(!prt_table[write_slot.Valid].valid)) begin  
		    automatic logic [Index_Size:0] slot = write_slot.Valid;
		    prt_table[slot].valid = TRUE;
		    prt_table[slot].bytes_rcvd = 0;
		    prt_table[slot].bytes_sent_req = 1;
		    prt_table[slot].bytes_sent_res = 0;
		    prt_table[slot].is_frame_fully_rcvd = FALSE;
		    using_write_slot = TRUE; 
		    return slot;
        end 
    endfunction
    
    //2
    function void write_prt_entry(input bit [8:0] data) ;
        if (isValid(writeslot) && 
		(using_write_slot) && 
		(!prt_table[write_slot.Valid].is_frame_fully_rcvd)) begin 
		automatic int slot = write_slot.Valid;
		//prt_table[slot].frame.a.put(True, prt_table[slot].bytes_rcvd, data); //need to check this expression 
		prt_table[slot].bytes_rcvd = prt_table[slot].bytes_rcvd + 1;
		end 
    endfunction
    //3
    function void finish_writing_prt_entry;
    if (
		isValid(writeslot)&&    // isValid function i guess need to write 
		(using_write_slot) && 
		(!prt_table[write_slot.Valid].is_frame_fully_rcvd) 
    ) begin 
		automatic int slot = write_slot.Valid;
		using_write_slot = FALSE;
		writeslot = tagged Invalid;
		prt_table[slot].is_frame_fully_rcvd = TRUE;
    end 
    endfunction

     //4
	function void invalidate_prt_entry(input int slot);
		//conflict_update_write_slot.send();  -> check 
		if (isValid(writeslot) && (writeslot.Valid == slot) && (using_write_slot)) begin
			using_write_slot = FALSE;
			writeslot = tagged Invalid;
		end
		if (prt_table[slot].valid) begin  prt_table[slot].valid = FALSE; end
	endfunction
    //5

	function  start_reading_prt_entry (input logic slot); //need to put function type ??
        if (isValid(readslot)) begin  //[Index_Size:0] 
		    if (!prt_table[slot].valid) begin 
                $display("this is start_reading_prt_entry ");
		    end
		    else begin 
			    readslot <= tagged Valid(slot);
			    // prt_table[slot].bytes_sent_req <= 1;
			    // prt_table[slot].bytes_sent_res <= 0;
			    //prt_table[slot].frame.b.put(False, 0, ?);  //check 
		    end
        end 
    endfunction
    //6
	function read_prt_entry ; //need to put some function type???
        if (
		    (isValid(readslot)) && 
		    (prt_table[read_slot.Valid].valid) && 
		    (((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req < prt_table[read_slot.Valid].bytes_rcvd)) ||
		     ((prt_table[read_slot.Valid].bytes_sent_res < prt_table[read_slot.Valid].bytes_sent_req) && (prt_table[read_slot.Valid].bytes_sent_req == prt_table[read_slot.Valid].bytes_rcvd) && (prt_table[read_slot.Valid].is_frame_fully_rcvd)))
       ) begin
            automatic PRTReadOutput out_prt;
		    automatic int slot = read_slot.Valid;
		    //data = prt_table[slot].frame.b.read();  //CHECK !!
		    prt_table[slot].bytes_sent_res = prt_table[slot].bytes_sent_res + 1;

            if (prt_table[slot].bytes_sent_req < prt_table[slot].bytes_rcvd) begin
		    //prt_table[slot].frame.b.put(False, prt_table[slot].bytes_sent_req, ?); //CHECK !!
                prt_table[slot].bytes_sent_req = prt_table[slot].bytes_sent_req + 1;
            end
		
		    if ((prt_table[slot].bytes_sent_res + 1 == prt_table[slot].bytes_rcvd) && (prt_table[slot].is_frame_fully_rcvd)) begin
			    readslot = tagged Invalid;
			    // check conflict_update_write_slot.send(); // =>PULSE WIRE
			    prt_table[slot].valid = FALSE;
			    out_prt.data_byte = data;
			    out_prt.is_last_byte = TRUE; 
			    return out_prt;
	      	end
	    	else begin
	    	    out_prt.data_byte = data;
			    out_prt.is_last_byte = FALSE; 
		    	return out_prt ;
		    end
      end
	endfunction

   //7
	assign  is_prt_slot_free = ((isValid(writeslot)) && (!using_write_slot));  //is valid
	
    ///internal function
    function isValid( input VInt write_slot) ;
        if ( write_slot.Valid) begin 
            return 1;
        end else begin 
            return 0;
        end 
    endfunction 

endmodule

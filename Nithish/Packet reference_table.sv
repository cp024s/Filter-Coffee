// Parameters
 parameter int Index_Size = 2; 
 parameter int Table_Size = 4; 
 parameter int BRAM_memory_size = 1520; // Header: 14, MTU: 1500, FCS: 4
 parameter int BRAM_addr_size = 16; 
 parameter int BRAM_data_size = 8;
 //parameter int BRAM_memory_size = FrameSize;

// In mkPRT.sv file
module mkPRT (
    input logic clk,
    input logic reset
    //input  PRTIfc PRTIfc_instance    // Interface instance
);

// Define the PRTReadOutput structure
typedef struct packed {
    logic [7:0] data_byte;
    logic       is_last_byte;
} PRTReadOutput;

// Define the PRTEntry structure with a packed frame
typedef struct packed {
    logic                   valid;                     // Validity of PRT entry
    logic [15:0]            bytes_sent_req;            // Bytes transmitted (requests)
    logic [15:0]            bytes_sent_res;            // Bytes transmitted (responses)
    logic [15:0]            bytes_rcvd;                // Bytes received and stored
    logic                   is_frame_fully_rcvd;       // Frame fully received status
    //logic [7:0]             frame [0:BRAM_memory_size-1]; // Frame data (packed)
} PRTEntry;

logic [7:0]             frame [0:BRAM_memory_size-1]; // Frame data

typedef enum logic [1:0] {
    Invalid = 2'b00,  // State for invalid write slot
    Valid   = 2'b01   // State for valid write slot
} VInt;

// Define the PRT table
PRTEntry prt_table [0:Table_Size-1];

// Initialize PRT table entries
initial begin
    for (int i = 0; i < Table_Size; i = i + 1) begin
        prt_table[i].valid = 1'b0;
        prt_table[i].bytes_sent_req = 16'd0;
        prt_table[i].bytes_sent_res = 16'd0;
        prt_table[i].bytes_rcvd = 16'd0;
        prt_table[i].is_frame_fully_rcvd = 1'b0;

        // Initialize frame memory to zero (optional)
        for (int j = 0; j < BRAM_memory_size; j = j + 1) begin
            prt_table[i].frame[j] = 8'd0;
        end
    end
end


// Declare the registers and flags
logic [Index_Size-1:0] write_slot;     // Register for write slot
logic using_write_slot;                // Flag for tracking if packet is being written
logic [Index_Size-1:0] read_slot;     // Register for read slot
logic read_slot_valid;

 logic [Index_Size-1:0] isValid = {Index_Size{1'bx}};  // 'x' value for invalid slot

// Initial block for initialization
initial begin
    write_slot = {Index_Size{1'b0}};   // Initialize write_slot to 0 (Invalid state)
    using_write_slot = 1'b0;            // Initialize using_write_slot to False
    read_slot = {Index_Size{1'b0}};    // Initialize read_slot to 0 (Invalid state)
    read_slot_valid = 1'b0;
end


// During invalidating PRT entry, the rule to find the write slot shall not be called to avoid deadlocks.
// Declare the invalidation signal
logic invalidate_entry; // This is the signal that triggers invalidation of a PRT entry

// PulseWire to track invalidation updates
logic conflict_update_write_slot;

// Logic that determines when a PRT entry is invalidated
always_ff @(posedge clk or negedge reset) begin
    if (!reset)
        invalidate_entry <= 1'b0; // Reset signal on reset
    else
        invalidate_entry <= 1'b0; // Condition when an entry is invalidated
end

// Set conflict_update_write_slot based on the invalidation signal
always_ff @(posedge clk or negedge reset) begin
    if (!reset) 
        conflict_update_write_slot <= 1'b0; // Reset the conflict signal
    else if (invalidate_entry) 
        conflict_update_write_slot <= 1'b1; // Set conflict flag when invalidation happens
    else 
        conflict_update_write_slot <= 1'b0; // Clear conflict flag otherwise
end



// This rule finds the write_slot where a new incoming packet can be stored.
// This rule is fired only when 
//      1) (!using_write_slot): There is no packet that is currently incoming and getting stored
//      2) (!isvalid(write_slot)): If the write_slot is not valid
//      3) (!conflict_update_write_slot): When there is no rule/method that is invalidating any of the PRT entries
always_ff @(posedge clk or negedge reset) begin
    if (!reset) begin
        // Reset logic here
        write_slot <= 'x; // or appropriate reset value
    end
    else if ((!using_write_slot) && (!isValid(write_slot)) && !conflict_update_write_slot) begin
        automatic logic is_write_slot_available = 1'b0;
        automatic logic [Index_Size-1:0] temp_write_slot = '0;
        
        for (int i = 0; i < Table_Size; i = i + 1) begin
            if (~prt_table[i].valid) begin
                is_write_slot_available = 1'b1;
                temp_write_slot = i; // Convert the index to the correct format if necessary
            end
        end

        // Display debug messages if needed
        // `ifdef PRT_DEBUG
        //     $display("%t: PRT: Rule: update_write_slot. Updating write slot", $time);
        // `endif

        if (is_write_slot_available) begin 
            write_slot <= Valid;
            // `ifdef PRT_DEBUG
            //     $display("%t: PRT: Rule: update_write_slot. Empty write slot found at %d", $time, temp_write_slot);
            // `endif
        end
        else begin
            write_slot <= Invalid;
            // `ifdef PRT_DEBUG
            //     $display("%t: PRT: Rule: update_write_slot. Empty write not found", $time);
            // `endif
        end
    end
end


// SystemVerilog conversion of the BSV `start_writing_prt_entry` method
function automatic logic [Index_Size-1:0] start_writing_prt_entry(); // Return the slot index

    // Ensure that the method is only executed if the conditions are met
    if (isValid(write_slot) && !using_write_slot && !prt_table[write_slot.Valid].valid) begin
        logic [Index_Size-1:0] slot; // Local variable to store the slot index
        slot = write_slot.Valid; // Assign the valid slot to a local variable

        // Mark the slot as valid and initialize the packet's parameters
        prt_table[slot].valid <= 1'b1; // Set the slot as valid
        prt_table[slot].bytes_rcvd <= 0; // Initialize bytes received to 0
        prt_table[slot].bytes_sent_req <= 1; // Set the bytes sent request to 1
        prt_table[slot].bytes_sent_res <= 0; // Initialize bytes sent response to 0
        prt_table[slot].is_frame_fully_rcvd <= 1'b0; // Mark the frame as not fully received

        // Mark that a write slot is in use
        using_write_slot <= 1'b1; 

        // Debug message for tracking the method execution
        `ifdef PRT_DEBUG
            $display("%t: PRT: Method: start_writing_prt_entry. Start storing packet at slot %d", $time, slot);
        `endif

        // Return the slot where the packet is being stored
        return slot;
    end

    // If conditions are not met, return an invalid slot (optional, based on the use case)
    return '0; // Return a value indicating failure or invalid slot
endfunction


// SystemVerilog conversion of the BSV `write_prt_entry` method
task write_prt_entry(input logic [7:0] data); // 8-bit data input for the frame

    // Ensure that the method is only executed if the conditions are met
    if (isValid(write_slot) && using_write_slot && !prt_table[write_slot.Valid].is_frame_fully_rcvd) begin
       automatic logic [Index_Size-1:0] slot = write_slot.Valid; // Assign the valid slot to a local variable

        // Store the incoming data word-by-word in the frame
        prt_table[slot].frame.a.put(1'b1, prt_table[slot].bytes_rcvd, data); // Store the byte of data at the correct address

        // Increment the bytes received counter
        prt_table[slot].bytes_rcvd <= prt_table[slot].bytes_rcvd + 1;

        // Optionally, enable debug messages for tracing
         `ifdef PRT_DEBUG
             $display("%t: PRT: Method: write_prt_entry. Storing packet. ADDR: %h DATA: %h at slot %d", $time, prt_table[slot].bytes_rcvd, data, slot);
         `endif
    end
endtask


// SystemVerilog conversion of the BSV `finish_writing_prt_entry` method
task finish_writing_prt_entry();

    // Check if the write_slot is valid, using_write_slot is true, and the frame is not fully received
    if (isValid(write_slot) && using_write_slot && !prt_table[write_slot.Valid].is_frame_fully_rcvd) begin
        automatic logic [Index_Size-1:0] slot = write_slot.Valid; // Assign the valid slot to a local variable

        // Release the write_slot and using_write_slot
        using_write_slot <= 1'b0; // Mark the write slot as no longer in use
        write_slot <= Invalid; // Mark the write_slot as invalid

        // Mark the frame as fully received
        prt_table[slot].is_frame_fully_rcvd <= 1'b1;

        // Debug message indicating that the packet has been fully stored
        `ifdef PRT_DEBUG
            $display("%t: PRT: Method: finish_writing_prt_entry. Finished Storing packet at slot %d", $time, slot);
        `endif
    end
endtask


// SystemVerilog conversion of the BSV `invalidate_prt_entry` method
task invalidate_prt_entry(input logic [Index_Size-1:0] slot);

    // Display debug message about invalidation
    `ifdef PRT_DEBUG
        $display("%t: PRT: Method: invalidate_prt_entry. Invalidating packet at slot %d", $time, slot);
    `endif

    // Send conflict update to free write slot
    conflict_update_write_slot.send();

    // If there is a valid write slot and the current write slot matches the invalidating slot, skip writing process
    if (isValid(write_slot) && (write_slot.Valid == slot) && using_write_slot) begin
        using_write_slot <= 1'b0; // Release the write slot
        write_slot <= Invalid; // Mark the write slot as invalid
        `ifdef PRT_DEBUG
            $display("%t: PRT: Method: invalidate_prt_entry. Packet that is being written is invalidated at slot %d. Write slots are released", $time, slot);
        `endif
    end

    // Invalidate the entry in the PRT table for the given slot
    if (prt_table[slot].valid) begin
        prt_table[slot].valid <= 1'b0; // Set the PRT entry as invalid
    end

endtask


// SystemVerilog conversion of the BSV `start_reading_prt_entry` method
task start_reading_prt_entry(input logic [Index_Size-1:0] slot);

    // Check if there is no valid read slot
    if (!isValid(read_slot)) begin
        // Check if the slot is valid for transmission
        if (!prt_table[slot].valid) begin
            // If the slot is invalid, display a debug message
            `ifdef PRT_DEBUG
                $display("%t: PRT: Method: start_reading_prt_entry. Invalid slot %d", $time, slot);
            `endif
        end else begin
            // Start reading the entry from the valid slot
            read_slot <= Valid; // Assign the tagged value to read_slot
            // Optionally initialize bytes_sent_req and bytes_sent_res (commented out in original code)
            // prt_table[slot].bytes_sent_req <= 1;
            // prt_table[slot].bytes_sent_res <= 0;

            // Put the frame's first byte (could be False as in the original BSV code)
            prt_table[slot].frame.b.put(1'b0, 0, 'x); // `1'b0` is False, `0` is the starting byte position

            // Debug message indicating the start of transmission
            `ifdef PRT_DEBUG
                $display("%t: PRT: Method: start_reading_prt_entry. Start transmitting packet from slot %d", $time, slot);
            `endif
        end
    end
    else begin
        // If there is a read slot already in use, no action is taken
        `ifdef PRT_DEBUG
            $display("%t: PRT: Method: start_reading_prt_entry. Read slot already in use, cannot start new transmission", $time);
        `endif
    end
endtask


// SystemVerilog conversion of the BSV `read_prt_entry` method
function PRTReadOutput read_prt_entry(input logic [Index_Size-1:0] read_slot);
    PRTReadOutput output_data;

    // Check conditions for a valid read
    if (isValid(read_slot) &&
        prt_table[read_slot].valid &&
        ((prt_table[read_slot].bytes_sent_res < prt_table[read_slot].bytes_sent_req && 
          prt_table[read_slot].bytes_sent_req < prt_table[read_slot].bytes_rcvd) ||
         (prt_table[read_slot].bytes_sent_res < prt_table[read_slot].bytes_sent_req && 
          prt_table[read_slot].bytes_sent_req == prt_table[read_slot].bytes_rcvd && 
          prt_table[read_slot].is_frame_fully_rcvd))) 
    begin

        // Retrieve data from the frame
        output_data.data_byte = prt_table[read_slot].frame.b.read();
        
        // Increment bytes_sent_res
        prt_table[read_slot].bytes_sent_res += 1;

        // Update bytes_sent_req if conditions allow
        if (prt_table[read_slot].bytes_sent_req < prt_table[read_slot].bytes_rcvd) begin
            prt_table[read_slot].frame.b.put(1'b0, prt_table[read_slot].bytes_sent_req, 'x);
            prt_table[read_slot].bytes_sent_req += 1;
        end

        // Check for completion of data transmission
        if ((prt_table[read_slot].bytes_sent_res == prt_table[read_slot].bytes_rcvd) &&
             prt_table[read_slot].is_frame_fully_rcvd) 
        begin
            // Invalidate the read slot and entry
            read_slot_valid <= 0;
            prt_table[read_slot].valid <= 0;

            // Trigger conflict update and set the last byte flag
            conflict_update_write_slot.send();
            output_data.is_last_byte = 1;

            // Debug message if PRT_DEBUG is enabled
            `ifdef PRT_DEBUG
                $display("%t: PRT: Method: read_prt_entry. Transmitting packet complete. Invalidating PRT entry. Read slots are released", $time);
            `endif
        end
        else begin
            output_data.is_last_byte = 0;
        end
    end
    else begin
        // In case conditions are not met, output data is invalid
        output_data = '0;
    end

    return output_data;
endfunction


// Define function to check if there is a free slot
function logic is_prt_slot_free();
    // Checks if write_slot is valid and not currently in use
    return (isValid(write_slot) && (!using_write_slot));
endfunction

endmodule


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


module PRT_TB;

  // Parameters from mkPRT module
  parameter int Index_Size = 2;
  parameter int Table_Size = 4;
  parameter int FrameSize = 1520;
  parameter int BRAM_addr_size = 16;
  parameter int BRAM_data_size = 8;
  parameter int BRAM_memory_size = FrameSize;

  // Signals
  logic clk;
  logic reset;
  logic [7:0] data;
  logic [Index_Size-1:0] slot_id;  // Slot ID for testing
  
  typedef struct packed {
    logic [7:0] data_byte;
    logic       is_last_byte;
} PRTReadOutput; 


  PRTReadOutput read_data;    // Correct way to declare PRTReadOutput

  // Instantiate the mkPRT (Design Under Test)
  mkPRT dut (
    .clk(clk),       // Connect clk signal
    .reset(reset)    // Connect reset signal
  );

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns clock period
  end

  // Reset logic
  initial begin
    reset = 1;
    #15 reset = 0;
    #10 reset = 1; // De-assert reset after some time
  end

  // Testbench sequence
  initial begin
    // Wait for reset to de-assert
    @(negedge reset);
    @(posedge clk);

    // Test case 1: Start writing to a PRT entry
    slot_id = dut.start_writing_prt_entry();
    if (slot_id != '0) begin
      $display("%t: Started writing to PRT entry at slot %0d", $time, slot_id);
    end else begin
      $display("%t: No available slot for writing", $time);
    end

    // Test case 2: Write data into the slot
    data = 8'hA5; // Example data to write
    for (int i = 0; i < 10; i++) begin // Write 10 bytes as an example
      dut.write_prt_entry(data);
      data = data + 1; // Increment data for the next byte
      @(posedge clk);
    end
    $display("%t: Data writing complete for slot %0d", $time, slot_id);

    // Test case 3: Finish writing to the entry
    dut.finish_writing_prt_entry();
    $display("%t: Finished writing to PRT entry at slot %0d", $time, slot_id);

    // Test case 4: Start reading from the PRT entry
    dut.start_reading_prt_entry(slot_id);

    // Test case 5: Read data until end of frame
    do begin
      read_data = dut.read_prt_entry(slot_id);
      $display("%t: Read data: %0h, Last byte: %0b", $time, read_data.data_byte, read_data.is_last_byte);
      @(posedge clk);
    end while (!read_data.is_last_byte);

    // Test case 6: Invalidate the PRT entry
    dut.invalidate_prt_entry(slot_id);
    $display("%t: Invalidated PRT entry at slot %0d", $time, slot_id);

    // End of simulation
    #100;
    $finish;
  end

endmodule

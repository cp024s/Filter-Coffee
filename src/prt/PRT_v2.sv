module mkPRT (
    input logic clk,
    input logic reset
);

    // Parameters
    parameter int Index_Size = 2; 
    parameter int Table_Size = 4; 
    parameter int BRAM_memory_size = 1520; // Header: 14, MTU: 1500, FCS: 4
    parameter int BRAM_addr_size = 16; 
    parameter int BRAM_data_size = 8;

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
        logic [7:0]             frame [0:BRAM_memory_size-1]; // Frame data
    } PRTEntry;

    // Define the PRT table
    PRTEntry prt_table [0:Table_Size-1];

    // Register for write slot
    logic [Index_Size-1:0] write_slot;     // Register for write slot
    logic using_write_slot;                // Flag for tracking if packet is being written
    logic [Index_Size-1:0] read_slot;     // Register for read slot
    logic read_slot_valid;

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

    // During invalidating PRT entry, the rule to find the write slot shall not be called to avoid deadlocks.
    logic invalidate_entry; // Signal that triggers invalidation of a PRT entry
    logic conflict_update_write_slot; // PulseWire to track invalidation updates

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            invalidate_entry <= 1'b0; // Reset signal on reset
        end else begin
            invalidate_entry <= 1'b0; // Condition when an entry is invalidated
        end
    end

    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            conflict_update_write_slot <= 1'b0; // Reset the conflict signal
        end else if (invalidate_entry) begin
            conflict_update_write_slot <= 1'b1; // Set conflict flag when invalidation happens
        end else begin
            conflict_update_write_slot <= 1'b0; // Clear conflict flag otherwise
        end
    end

    // Check if the write slot is valid
    function logic isValid(input logic [Index_Size-1:0] slot);
        return (slot < Table_Size); // Check if the slot index is valid
    endfunction

    // Slot finder logic for PRT table
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            write_slot <= {Index_Size{1'bx}}; // Invalid state on reset
        end else if (!using_write_slot && !isValid(write_slot) && !conflict_update_write_slot) begin
            automatic logic is_write_slot_available = 1'b0;
            automatic logic [Index_Size-1:0] temp_write_slot = {Index_Size{1'bx}};
            
            for (int i = 0; i < Table_Size; i = i + 1) begin
                if (~prt_table[i].valid) begin
                    is_write_slot_available = 1'b1;
                    temp_write_slot = i; // Found an available slot
                end
            end

            if (is_write_slot_available) begin
                write_slot <= temp_write_slot; // Assign the found slot
            end else begin
                write_slot <= {Index_Size{1'bx}}; // No available slot
            end
        end
    end

    // SystemVerilog conversion of the BSV `start_writing_prt_entry` method
    function automatic logic [Index_Size-1:0] start_writing_prt_entry(); 
        if (isValid(write_slot) && !using_write_slot && !prt_table[write_slot].valid) begin
            logic [Index_Size-1:0] slot = write_slot;
            prt_table[slot].valid <= 1'b1;
            prt_table[slot].bytes_rcvd <= 16'd0;
            prt_table[slot].bytes_sent_req <= 16'd1;
            prt_table[slot].bytes_sent_res <= 16'd0;
            prt_table[slot].is_frame_fully_rcvd <= 1'b0;

            using_write_slot <= 1'b1;
            return slot;
        end

        return {Index_Size{1'bx}}; // No slot available
    endfunction

    // SystemVerilog conversion of the BSV `write_prt_entry` method
    task write_prt_entry(input logic [7:0] data);
        if (isValid(write_slot) && using_write_slot && !prt_table[write_slot].is_frame_fully_rcvd) begin
            prt_table[write_slot].frame[prt_table[write_slot].bytes_rcvd] = data; // Store data at current byte index
            prt_table[write_slot].bytes_rcvd <= prt_table[write_slot].bytes_rcvd + 1;
        end
    endtask

    // SystemVerilog conversion of the BSV `finish_writing_prt_entry` method
    task finish_writing_prt_entry();
        if (isValid(write_slot) && using_write_slot && !prt_table[write_slot].is_frame_fully_rcvd) begin
            prt_table[write_slot].is_frame_fully_rcvd <= 1'b1;
            using_write_slot <= 1'b0;
            write_slot <= {Index_Size{1'bx}}; // Mark write_slot as invalid
        end
    endtask

    // SystemVerilog conversion of the BSV `invalidate_prt_entry` method
    task invalidate_prt_entry(input logic [Index_Size-1:0] slot);
        conflict_update_write_slot <= 1'b1; // Set conflict flag
        
        if (prt_table[slot].valid) begin
            prt_table[slot].valid <= 1'b0; // Invalidate the PRT entry
        end
    endtask

    // SystemVerilog conversion of the BSV `start_reading_prt_entry` method
    task start_reading_prt_entry(input logic [Index_Size-1:0] slot);
        if (!isValid(read_slot)) begin
            if (prt_table[slot].valid) begin
                read_slot <= slot;
                prt_table[slot].frame[0] = 'x; // Start reading from first byte
            end
        end
    endtask

    // SystemVerilog conversion of the BSV `read_prt_entry` method
    function PRTReadOutput read_prt_entry(input logic [Index_Size-1:0] slot);
        PRTReadOutput output_data;
        if (isValid(slot) && prt_table[slot].valid) begin
            output_data.data_byte = prt_table[slot].frame[prt_table[slot].bytes_sent_res];
            prt_table[slot].bytes_sent_res <= prt_table[slot].bytes_sent_res + 1;

            output_data.is_last_byte = (prt_table[slot].bytes_sent_res == prt_table[slot].bytes_rcvd);
            if (output_data.is_last_byte) begin
                prt_table[slot].valid <= 1'b0; // Invalidate after reading last byte
            end
            return output_data;
        end

        output_data.data_byte = 8'b0; // Invalid data byte
        output_data.is_last_byte = 1'b0;
        return output_data;
    endfunction

endmodule

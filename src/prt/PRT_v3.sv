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

    // Define PRTEntry structure
    typedef struct packed {
        logic valid;  // Validity of PRT entry
        logic [15:0] bytes_sent_req;
        logic [15:0] bytes_sent_res;
        logic [15:0] bytes_rcvd;
        logic is_frame_fully_rcvd;
        logic [7:0] frame [0:BRAM_memory_size-1]; // Frame data
    } PRTEntry;

    // Define PRT table
    PRTEntry prt_table [0:Table_Size-1];

    // FSM states
    typedef enum logic [2:0] {
        IDLE = 3'b000,
        WRITING = 3'b001,
        FINISH_WRITE = 3'b010,
        READING = 3'b011,
        FINISH_READ = 3'b100,
        INVALIDATING = 3'b101
    } state_t;

    state_t state, next_state;
    logic [Index_Size-1:0] write_slot;
    logic [Index_Size-1:0] read_slot;
    logic using_write_slot;  // Flag indicating if write slot is in use

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

    // State transition block (combinational)
    always_ff @(state or using_write_slot or write_slot or prt_table[write_slot].valid or prt_table[write_slot].is_frame_fully_rcvd) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (!using_write_slot && !prt_table[write_slot].valid) begin
                    next_state = WRITING;
                end
            end

            WRITING: begin
                if (prt_table[write_slot].is_frame_fully_rcvd) begin
                    next_state = FINISH_WRITE;
                end
            end

            FINISH_WRITE: begin
                next_state = IDLE;  // After finishing write, go back to IDLE
            end

            READING: begin
                if (prt_table[read_slot].bytes_sent_res == prt_table[read_slot].bytes_rcvd) begin
                    next_state = FINISH_READ;
                end
            end

            FINISH_READ: begin
                next_state = IDLE;  // After finishing read, go back to IDLE
            end

            INVALIDATING: begin
                next_state = IDLE;  // After invalidation, go back to IDLE
            end
        endcase
    end

    // State update (synchronous)
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            state <= IDLE;
            using_write_slot <= 1'b0;
            write_slot <= {Index_Size{1'bx}};
            read_slot <= {Index_Size{1'bx}};
        end else begin
            state <= next_state;

            // Handle state-specific operations
            case (state)
                WRITING: begin
                    if (!using_write_slot && !prt_table[write_slot].valid) begin
                        // Initialize PRT entry for writing
                        prt_table[write_slot].valid <= 1'b1;
                        prt_table[write_slot].bytes_rcvd <= 16'd0;
                        prt_table[write_slot].bytes_sent_req <= 16'd1;
                        prt_table[write_slot].bytes_sent_res <= 16'd0;
                        prt_table[write_slot].is_frame_fully_rcvd <= 1'b0;
                        using_write_slot <= 1'b1;
                    end
                end

                WRITING: begin
                    // Handle data write logic
                    if (using_write_slot) begin
                        prt_table[write_slot].frame[prt_table[write_slot].bytes_rcvd] <= 8'b10101010; // Example data
                        prt_table[write_slot].bytes_rcvd <= prt_table[write_slot].bytes_rcvd + 1;
                    end
                end

                FINISH_WRITE: begin
                    // Finish writing to the slot and mark the slot as fully received
                    prt_table[write_slot].is_frame_fully_rcvd <= 1'b1;
                    using_write_slot <= 1'b0;
                end

                READING: begin
                    if (prt_table[read_slot].valid) begin
                        // Read the data from the slot
                        logic [7:0] data_byte = prt_table[read_slot].frame[prt_table[read_slot].bytes_sent_res];
                        prt_table[read_slot].bytes_sent_res <= prt_table[read_slot].bytes_sent_res + 1;
                    end
                end

                FINISH_READ: begin
                    // Mark the slot as invalid after finishing reading
                    prt_table[read_slot].valid <= 1'b0;
                end

                INVALIDATING: begin
                    if (prt_table[write_slot].valid) begin
                        prt_table[write_slot].valid <= 1'b0;
                    end
                end
            endcase
        end
    end

    // Task to invalidate a PRT entry
    task invalidate_prt_entry(input logic [Index_Size-1:0] slot);
        prt_table[slot].valid <= 1'b0;
        next_state <= INVALIDATING;
    endtask

    // Task to start reading from a PRT entry
    task start_reading_prt_entry(input logic [Index_Size-1:0] slot);
        if (!prt_table[slot].valid) begin
            read_slot <= slot;
            next_state <= READING;
        end
    endtask

    // Task to write a PRT entry
    task write_prt_entry(input logic [Index_Size-1:0] slot, input logic [7:0] data);
        if (!prt_table[slot].valid) begin
            write_slot <= slot;
            prt_table[slot].frame[prt_table[slot].bytes_rcvd] <= data;
            prt_table[slot].bytes_rcvd <= prt_table[slot].bytes_rcvd + 1;
            next_state <= WRITING;
        end
    endtask

endmodule

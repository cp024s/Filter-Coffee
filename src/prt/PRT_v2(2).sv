module PRT #(
    parameter DATA_WIDTH = 8,      // Data width in bits
    parameter ADDR_WIDTH = 11,     // Address width, depending on memory size
    parameter NUM_ENTRIES = 10,  // Number of entries in PRT
    parameter FRAME_SIZE = 1518    // Max frame size in bytes
)(
    input logic                     clk,
    input logic                     rst,
    input logic                     frame_in_valid,
    input logic [DATA_WIDTH-1:0]    frame_data_in,
    output logic                    frame_out_valid,
    output logic [DATA_WIDTH-1:0]   frame_data_out,
    output logic                    slot_available, // Indicates free slot availability
    input logic                     start_receive,  // Start receiving a new frame
    input logic                     stop_receive,   // Force stop receiving frame
    input logic                     start_transmit  // Start sending frame data
);

    // PRT Entry Structure with Packed Multidimensional Array
    typedef struct packed {
        logic                        valid;
        logic [DATA_WIDTH-1:0][FRAME_SIZE-1:0] data; // Packed array for frame data
        logic [ADDR_WIDTH-1:0]       bytes_rcvd;
        logic [ADDR_WIDTH-1:0]       bytes_sent;
        logic                        frame_fully_rcvd;
    } prt_entry_t;

    // Packet Reference Table
    prt_entry_t prt [NUM_ENTRIES];

    // State Encoding
    typedef enum logic [2:0] {
        IDLE,
        RECEIVE_FRAME,
        STORE_DATA,
        WAIT_FOR_TRANSMIT,
        TRANSMIT_FRAME,
        RESET_ENTRY
    } state_t;

    state_t current_state, next_state;

    // FSM Variables
    logic [ADDR_WIDTH-1:0] byte_count;   // Counter for bytes received/transmitted
    logic [ADDR_WIDTH-1:0] write_addr, read_addr;
    logic                  frame_fully_rcvd;
    
    // FSM Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // State Transitions
    always_comb begin
        // Default next state
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (start_receive) begin
                    next_state = RECEIVE_FRAME;
                end
            end

            RECEIVE_FRAME: begin
                if (frame_in_valid && slot_available) begin
                    next_state = STORE_DATA;
                end else if (stop_receive) begin
                    next_state = RESET_ENTRY;
                end
            end

            STORE_DATA: begin
                if (byte_count == FRAME_SIZE - 1) begin
                    next_state = WAIT_FOR_TRANSMIT;
                end
            end

            WAIT_FOR_TRANSMIT: begin
                if (start_transmit) begin
                    next_state = TRANSMIT_FRAME;
                end
            end

            TRANSMIT_FRAME: begin
                if (prt[read_addr].bytes_sent == prt[read_addr].bytes_rcvd) begin
                    next_state = RESET_ENTRY;
                end
            end

            RESET_ENTRY: begin
                next_state = IDLE;
            end

            default: next_state = IDLE;
        endcase
    end

    // Data and State Operations
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all entries in PRT
            for (int i = 0; i < NUM_ENTRIES; i++) begin
                prt[i].valid <= 0;
                prt[i].bytes_rcvd <= 0;
                prt[i].bytes_sent <= 0;
                prt[i].frame_fully_rcvd <= 0;
            end
            byte_count <= 0;
            write_addr <= 0;
            read_addr <= 0;
            frame_fully_rcvd <= 0;
        end else begin
            case (current_state)
                RECEIVE_FRAME: begin
                    if (frame_in_valid && slot_available) begin
                        // Start receiving frame into a new slot
                        prt[write_addr].valid <= 1;
                        prt[write_addr].data[prt[write_addr].bytes_rcvd] <= frame_data_in;
                        prt[write_addr].bytes_rcvd <= prt[write_addr].bytes_rcvd + 1;
                        byte_count <= prt[write_addr].bytes_rcvd;
                    end
                end

                STORE_DATA: begin
                    if (frame_in_valid) begin
                        prt[write_addr].data[prt[write_addr].bytes_rcvd] <= frame_data_in;
                        prt[write_addr].bytes_rcvd <= prt[write_addr].bytes_rcvd + 1;
                        if (prt[write_addr].bytes_rcvd == FRAME_SIZE - 1) begin
                            prt[write_addr].frame_fully_rcvd <= 1;
                        end
                    end
                end

                WAIT_FOR_TRANSMIT: begin
                    frame_fully_rcvd <= prt[write_addr].frame_fully_rcvd;
                end

                TRANSMIT_FRAME: begin
                    if (frame_fully_rcvd) begin
                        frame_out_valid <= 1;
                        frame_data_out <= prt[read_addr].data[prt[read_addr].bytes_sent];
                        prt[read_addr].bytes_sent <= prt[read_addr].bytes_sent + 1;
                        if (prt[read_addr].bytes_sent == prt[read_addr].bytes_rcvd) begin
                            frame_out_valid <= 0;
                            prt[read_addr].valid <= 0;
                        end
                    end
                end

                RESET_ENTRY: begin
                    prt[read_addr].valid <= 0;
                    prt[read_addr].bytes_rcvd <= 0;
                    prt[read_addr].bytes_sent <= 0;
                    prt[read_addr].frame_fully_rcvd <= 0;
                    byte_count <= 0;
                    write_addr <= write_addr + 1; // Move to the next available slot
                    read_addr <= read_addr + 1;   // Move to the next available slot for read
                end

                default: ;
            endcase
        end
    end

    // Output Logic
    assign slot_available = !prt[write_addr].valid; // Check if current slot is free

endmodule

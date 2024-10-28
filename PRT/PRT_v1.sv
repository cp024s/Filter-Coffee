

module MPD_FSM (
    input logic                clk,
    input logic                reset_n,
    input logic                new_frame_available_from_rx,
    input logic [5:0]          rx_slot_tag,
    input logic [5:0]          tx_slot_tag,
    input logic                firewall_safe,            // Output from firewall indicating packet safety
    input logic                firewall_check_required,  // Signal that packet requires firewall check

    output logic               start_rx,                 // Start receiving frame
    output logic               start_tx,                 // Start transmitting frame
    output logic               force_stop_rx,            // Stop receiving unsafe packet
    output logic [5:0]         prt_rx_slot_tag,          // Slot tag for writing to PRTnn
    output logic               invalidate_prt_entry      // Invalidate unsafe packet in PRT
);

    // FSM states
    typedef enum logic [2:0] { IDLE, RECEIVE_FRAME, CHECK_FIREWALL, SEND_FRAME, INVALIDATE_PACKET } fsm_state_t;

    fsm_state_t state, next_state;

    // State register
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // FSM next state logic and output logic
    always_comb begin
        // Default outputs
        start_rx            = 0;
        start_tx            = 0;
        force_stop_rx       = 0;
        prt_rx_slot_tag     = 6'd0;
        invalidate_prt_entry = 0;
        next_state          = state;

        case (state)
            // IDLE: Wait for a new frame to be available for processing
            IDLE: begin
                if (new_frame_available_from_rx) begin
                    start_rx = 1;
                    prt_rx_slot_tag = rx_slot_tag;
                    next_state = RECEIVE_FRAME;
                end
            end

            // RECEIVE_FRAME: Handle frame reception and transfer header to firewall for checking
            RECEIVE_FRAME: begin
                if (firewall_check_required) begin
                    next_state = CHECK_FIREWALL;
                end else begin
                    next_state = SEND_FRAME; // No firewall check needed, proceed to send
                end
            end

            // CHECK_FIREWALL: Query firewall to determine if the packet is safe or unsafe
            CHECK_FIREWALL: begin
                if (firewall_safe) begin
                    next_state = SEND_FRAME; // If safe, move to transmission
                end else begin
                    force_stop_rx = 1;        // Unsafe packet, stop receiving and invalidate entry
                    next_state = INVALIDATE_PACKET;
                end
            end

            // SEND_FRAME: Transmit the safe packet from the PRT
            SEND_FRAME: begin
                start_tx = 1;
                next_state = IDLE;            // After transmission, return to idle
            end

            // INVALIDATE_PACKET: Discard unsafe packet from PRT
            INVALIDATE_PACKET: begin
                invalidate_prt_entry = 1;
                next_state = IDLE;            // Return to idle state after invalidation
            end

            default: next_state = IDLE;
        endcase
    end
endmodule




module PacketReferenceTable #(
    parameter DATA_WIDTH = 8,          // Data width per byte
    parameter PACKET_SIZE = 1400,      // Maximum packet size in bytes
    parameter PRT_SIZE = 32            // Number of PRT entries
)(
    input logic                    clk,
    input logic                    reset_n,
    input logic [DATA_WIDTH-1:0]   in_data,          // Data to write into PRT
    input logic                    in_data_valid,    // Signal to indicate valid input data
    input logic [5:0]              in_slot_tag,      // Slot tag for each packet entry
    input logic                    in_frame_complete,// Signal to indicate end of frame for a packet
    output logic [DATA_WIDTH-1:0]  out_data,         // Data read from PRT for TX
    output logic                   out_data_valid,   // Signal to indicate valid output data
    output logic                   out_frame_complete,// Signal to indicate end of frame for a packet
    input logic                    out_enable,       // Enable signal to start sending data
    input logic [5:0]              out_slot_tag      // Slot tag for reading data from PRT
);

    // PRT entry structure
    typedef struct packed {
        logic                    valid_bit;
        logic [15:0]             bytes_received;      // Number of bytes received in this entry
        logic [15:0]             bytes_sent;          // Number of bytes transmitted from this entry
        logic                    is_frame_complete;   // Flag to indicate frame reception completion
        logic [DATA_WIDTH-1:0]   frame_data [0:PACKET_SIZE-1]; // Buffer to store packet data
    } prt_entry_t;

    // Memory array for PRT entries
    prt_entry_t prt_table [0:PRT_SIZE-1];

    // Write Process
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // Initialize all entries to invalid on reset
            foreach (prt_table[i]) begin
                prt_table[i].valid_bit        <= 0;
                prt_table[i].bytes_received   <= 0;
                prt_table[i].bytes_sent       <= 0;
                prt_table[i].is_frame_complete <= 0;
            end
        end else if (in_data_valid && prt_table[in_slot_tag].bytes_received < PACKET_SIZE) begin
            // Write incoming data to specified slot in PRT table
            prt_table[in_slot_tag].frame_data[prt_table[in_slot_tag].bytes_received] <= in_data;
            prt_table[in_slot_tag].bytes_received <= prt_table[in_slot_tag].bytes_received + 1;

            // Mark the frame as complete if indicated
            if (in_frame_complete) begin
                prt_table[in_slot_tag].is_frame_complete <= 1;
                prt_table[in_slot_tag].valid_bit <= 1;
            end
        end
    end

    // Read Process
    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            out_data_valid        <= 0;
            out_frame_complete    <= 0;
        end else if (out_enable && prt_table[out_slot_tag].valid_bit) begin
            // Check if there’s data left to read in the selected entry
            if (prt_table[out_slot_tag].bytes_sent < prt_table[out_slot_tag].bytes_received) begin
                out_data <= prt_table[out_slot_tag].frame_data[prt_table[out_slot_tag].bytes_sent];
                out_data_valid <= 1;
                prt_table[out_slot_tag].bytes_sent <= prt_table[out_slot_tag].bytes_sent + 1;
            end else begin
                out_data_valid <= 0;
            end

            // Mark frame as complete once all bytes are sent
            if (prt_table[out_slot_tag].bytes_sent == prt_table[out_slot_tag].bytes_received) begin
                out_frame_complete <= prt_table[out_slot_tag].is_frame_complete;
                prt_table[out_slot_tag].valid_bit <= 0;  // Invalidate entry after transmission
            end else begin
                out_frame_complete <= 0;
            end
        end else begin
            out_data_valid <= 0;
        end
    end

endmodule

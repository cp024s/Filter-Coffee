module MasterPacketDealer #(
    parameter DATA_WIDTH = 8,       // Width of each data word
    parameter ADDR_WIDTH = 10,      // Address width for Packet Reference Table
    parameter TAG_WIDTH  = 8        // Tag width for tracking packet slots
)(
    input logic clk,                // Clock signal
    input logic reset,              // Synchronous reset
    input logic [DATA_WIDTH-1:0] rx_data,  // Received data from Ethernet IP
    input logic rx_valid,           // Data valid signal for received data
    input logic force_stop_rx,      // Signal to stop receiving in case of unsafe packet
    output logic [DATA_WIDTH-1:0] tx_data,  // Transmitted data to Ethernet IP
    output logic tx_valid,          // Data valid signal for transmitted data
    output logic tx_done,           // Signal to indicate end of transmission
    output logic new_frame_avail,   // Indicates a new frame is ready for processing
    input logic [TAG_WIDTH-1:0] bloom_result, // Result from Bloom Filter (safe or unsafe)
    input logic [TAG_WIDTH-1:0] shakti_result // Result from Shakti processor check
);

    // Internal Signals
    logic [ADDR_WIDTH-1:0] prt_write_addr, prt_read_addr; // Addresses for Packet Reference Table
    logic prt_write_en, prt_read_en;                      // Write and Read enables for PRT
    logic [DATA_WIDTH-1:0] prt_data_in, prt_data_out;     // Data signals for PRT
    logic [TAG_WIDTH-1:0] slot_tag;                       // Tag for packet identification
    logic [TAG_WIDTH-1:0] packet_fifo_out;                // Output of packet header FIFO
    logic fifo_empty, fifo_full;                          // FIFO status signals

    // FIFO for incoming packets (headers)
    PacketFIFO #(
        .DATA_WIDTH(TAG_WIDTH)
    ) packet_fifo (
        .clk(clk),
        .reset(reset),
        .data_in(slot_tag),
        .write_en(new_frame_avail),
        .data_out(packet_fifo_out),
        .read_en(bloom_result),
        .empty(fifo_empty),
        .full(fifo_full)
    );

    // Packet Reference Table (PRT)
    PRT #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) prt (
        .clk(clk),
        .reset(reset),
        .write_addr(prt_write_addr),
        .read_addr(prt_read_addr),
        .write_en(prt_write_en),
        .read_en(prt_read_en),
        .data_in(prt_data_in),
        .data_out(prt_data_out)
    );

    // State machine for managing packet processing
    typedef enum logic [2:0] {
        IDLE,
        RX_PACKET,
        BLOOM_FILTER_CHECK,
        SHAKTI_CHECK,
        TX_PACKET,
        INVALIDATE_PACKET
    } state_t;

    state_t state, next_state;

    // State Machine Sequential Logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            state <= IDLE;
        else
            state <= next_state;
    end

    // State Machine Combinational Logic
    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin
                if (rx_valid)
                    next_state = RX_PACKET;
            end
            RX_PACKET: begin
                if (!fifo_full && rx_valid)
                    next_state = BLOOM_FILTER_CHECK;
            end
            BLOOM_FILTER_CHECK: begin
                if (bloom_result == '1)
                    next_state = SHAKTI_CHECK;
                else
                    next_state = TX_PACKET;
            end
            SHAKTI_CHECK: begin
                if (shakti_result == '0)
                    next_state = TX_PACKET;
                else
                    next_state = INVALIDATE_PACKET;
            end
            TX_PACKET: begin
                if (tx_done)
                    next_state = IDLE;
            end
            INVALIDATE_PACKET: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Data Handling Logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            prt_write_en <= 1'b0;
            prt_read_en <= 1'b0;
            tx_valid <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    tx_valid <= 1'b0;
                    if (rx_valid) begin
                        prt_write_en <= 1'b1;
                        prt_data_in <= rx_data;
                    end
                end
                RX_PACKET: begin
                    prt_write_en <= 1'b1;
                    prt_data_in <= rx_data;
                    slot_tag <= prt_write_addr;
                    new_frame_avail <= 1'b1;
                end
                BLOOM_FILTER_CHECK: begin
                    prt_read_en <= 1'b1;
                    prt_read_addr <= packet_fifo_out;
                end
                SHAKTI_CHECK: begin
                    prt_read_en <= 1'b1;
                    prt_read_addr <= packet_fifo_out;
                end
                TX_PACKET: begin
                    tx_valid <= 1'b1;
                    tx_data <= prt_data_out;
                end
                INVALIDATE_PACKET: begin
                    prt_write_en <= 1'b0;
                    prt_read_en <= 1'b0;
                end
            endcase
        end
    end

endmodule

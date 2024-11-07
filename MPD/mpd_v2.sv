module MasterPacketDealer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 11,
    parameter NUM_ENTRIES = 2048
)(
    input  logic                clk,
    input  logic                rst,
    input  logic                new_frame_available_rx,
    input  logic [DATA_WIDTH-1:0] rx_data,
    input  logic                is_frame_fully_read,
    output logic                is_last_byte_rx,
    output logic                rx_frame_pushed,
    output logic                tx_frame_ready,
    output logic                tx_slot_available,
    output logic [DATA_WIDTH-1:0] tx_data,
    output logic                tx_frame_sent,
    output logic                prt_slot_available, 
    output logic                force_stop_rx,
    output logic                invalidate_prt_slot
);

    // State encoding for FSM
    typedef enum logic [3:0] {
        IDLE,
        WAIT_FOR_NEW_FRAME,
        RECEIVE_FRAME,
        STORE_HEADER_TAG,
        PUSH_TO_FIREWALL_FIFO,
        WAIT_FOR_FIREWALL_DECISION,
        TX_FRAME,
        RESET_SLOT
    } state_t;

    state_t current_state, next_state;

    // Instantiate Packet Reference Table (PRT) - External code is provided by user
    PacketReferenceTable #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_ENTRIES(NUM_ENTRIES)
    ) prt_inst (
        .clk(clk),
        .rst(rst),
        .frame_in_valid(new_frame_available_rx),
        .frame_data_in(rx_data),
        .frame_out_valid(tx_frame_ready),
        .frame_data_out(tx_data),
        .slot_available(prt_slot_available),
        .start_receive(current_state == RECEIVE_FRAME),
        .stop_receive(force_stop_rx),
        .start_transmit(current_state == TX_FRAME)
    );

    // FIFO instances for communication with Firewall
    fifo #(.WIDTH(DATA_WIDTH), .DEPTH(128)) to_firewall_fifo (
        .clk(clk),
        .rst(rst),
        .write_en(current_state == PUSH_TO_FIREWALL_FIFO),
        .read_en(current_state == WAIT_FOR_FIREWALL_DECISION),
        .data_in({header, slot_tag}),
        .data_out(firewall_data),
        .full(fifo_full),
        .empty(fifo_empty)
    );

    fifo #(.WIDTH(DATA_WIDTH), .DEPTH(128)) to_invalidate_fifo (
        .clk(clk),
        .rst(rst),
        .write_en(current_state == RESET_SLOT && !is_packet_safe),
        .read_en(invalidate_prt_slot),
        .data_in(slot_tag),
        .data_out(invalid_slot),
        .full(invalidate_fifo_full),
        .empty(invalidate_fifo_empty)
    );

    // FSM for Master Packet Dealer
    always_ff @(posedge clk or posedge rst) begin
        if (rst) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    always_comb begin
        // Default transitions
        next_state = current_state;

        case (current_state)
            IDLE: begin
                if (prt_slot_available)
                    next_state = WAIT_FOR_NEW_FRAME;
            end
            
            WAIT_FOR_NEW_FRAME: begin
                if (new_frame_available_rx)
                    next_state = RECEIVE_FRAME;
            end

            RECEIVE_FRAME: begin
                if (is_last_byte_rx)
                    next_state = STORE_HEADER_TAG;
            end

            STORE_HEADER_TAG: begin
                next_state = PUSH_TO_FIREWALL_FIFO;
            end

            PUSH_TO_FIREWALL_FIFO: begin
                if (!fifo_full)
                    next_state = WAIT_FOR_FIREWALL_DECISION;
            end

            WAIT_FOR_FIREWALL_DECISION: begin
                if (firewall_response_received)
                    next_state = firewall_safe ? TX_FRAME : RESET_SLOT;
            end

            TX_FRAME: begin
                if (is_frame_fully_sent)
                    next_state = WAIT_FOR_NEW_FRAME;
            end

            RESET_SLOT: begin
                next_state = WAIT_FOR_NEW_FRAME;
            end

            default: next_state = IDLE;
        endcase
    end

    // Process received data
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            header <= 0;
            slot_tag <= 0;
        end
        else begin
            case (current_state)
                RECEIVE_FRAME: begin
                    if (new_frame_available_rx) begin
                        header <= rx_data;
                        slot_tag <= prt_slot;
                    end
                end

                TX_FRAME: begin
                    tx_data <= prt_inst.frame_data_out;
                end

                RESET_SLOT: begin
                    prt_inst.reset_slot(slot_tag);
                end
            endcase
        end
    end
endmodule

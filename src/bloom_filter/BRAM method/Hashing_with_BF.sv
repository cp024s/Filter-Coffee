`timescale 1ns/1ps

module bloom_filter (
    input  logic clka,                  // Clock signal
    input  logic rst_n,                 // Active low reset
    input  logic [71:0] data_in,        // 72-bit input data
    input  logic start,                 // Start signal to process input data
    output logic done                   // Done signal indicating completion
);

    // BRAM interface signals
    logic ena;                          // Enable signal for BRAM
    logic wea;                          // Write enable for BRAM
    logic [10:0] addra;                 // 11-bit address for BRAM
    logic [2047:0] dina;                  // 32-bit data input for BRAM
    logic [2047:0] douta;                 // 32-bit data output from BRAM

    // State machine states
    typedef enum logic [3:0] {
        IDLE, 
        CALCULATE_HASHES, 
        WRITE_HASH_0, 
        WRITE_HASH_1, 
        WRITE_HASH_2, 
        WRITE_HASH_3, 
        WRITE_HASH_4, 
        WRITE_HASH_5, 
        WRITE_HASH_6, 
        DONE
    } state_t;

    state_t current_state, next_state;

    // Hash outputs (7 hash addresses)
    logic [10:0] hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6;

    // BRAM instantiation (do not change)
    BRAM BRAM_inst (
        .clka(clka),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta)
    );

    // Hash module instantiation (do not change)
    bloom_filter_hashes_11bit hash_inst (
        .data_in(data_in),
        .hash_0(hash_0),
        .hash_1(hash_1),
        .hash_2(hash_2),
        .hash_3(hash_3),
        .hash_4(hash_4),
        .hash_5(hash_5),
        .hash_6(hash_6)
    );

    // =========================
    // State Machine Logic
    // =========================
    always_ff @(posedge clka or negedge rst_n) begin
        if (!rst_n) 
            current_state <= IDLE;
        else 
            current_state <= next_state;
    end

    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: 
                if (start) 
                    next_state = CALCULATE_HASHES;

            CALCULATE_HASHES: 
                next_state = WRITE_HASH_0;

            WRITE_HASH_0: 
                next_state = WRITE_HASH_1;

            WRITE_HASH_1: 
                next_state = WRITE_HASH_2;

            WRITE_HASH_2: 
                next_state = WRITE_HASH_3;

            WRITE_HASH_3: 
                next_state = WRITE_HASH_4;

            WRITE_HASH_4: 
                next_state = WRITE_HASH_5;

            WRITE_HASH_5: 
                next_state = WRITE_HASH_6;

            WRITE_HASH_6: 
                next_state = DONE;

            DONE: 
                next_state = IDLE;

            default: 
                next_state = IDLE;
        endcase
    end

    // =========================
    // Control Logic for BRAM Writes
    // =========================
    always_ff @(posedge clka or negedge rst_n) begin
        if (!rst_n) begin
            ena  <= 0;
            wea  <= 0;
            addra <= 11'd0;
            dina <= 32'd0;
            done <= 0;
        end 
        else begin
            ena  <= 0;
            wea  <= 0;
            addra <= 11'd0;
            dina <= 32'd0;
            done <= 0;

            case (current_state)
                IDLE: begin
                    ena  <= 0;
                    wea  <= 0;
                    done <= 0;
                end

                CALCULATE_HASHES: begin
                    // This state computes the 7 hash addresses for the input data.
                end

                WRITE_HASH_0: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_0;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_1: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_1;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_2: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_2;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_3: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_3;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_4: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_4;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_5: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_5;
                    dina  <= {2048{1'b1}};
                end

                WRITE_HASH_6: begin
                    ena  <= 1;
                    wea  <= 1;
                    addra <= hash_6;
                    dina  <= {2048{1'b1}};
                end

                DONE: begin
                    done <= 1;
                end

            endcase
        end
    end

endmodule

module Firewall (
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input logic [71:0] ip_protocol,  // 72-bit IP protocol info (src_ip, dst_ip, protocol)
    input logic [15:0] src_port,     // Source port
    input logic [15:0] dst_port,     // Destination port
    output logic result_out,         // Result of the Bloom filter check (pass/fail)
    output logic ready_recv,         // Ready signal to receive data
    output logic ready_res           // Ready signal to provide result
);

    // FSM States
    typedef enum logic [1:0] {READY, WAIT, GET_RESULT} state_t;
    state_t state;

    // BRAM Interface Signals (for Bloom filter)
    logic [2:0] bram_addr;          // Address for BRAM
    logic bram_write_en;            // Write enable for BRAM
    logic bram_din;                 // Data input for BRAM
    logic bram_dout;                // Data output from BRAM

    // Hash Output Signals
    logic [31:0] hash_result_1, hash_result_2, hash_result_3; // Three hash results
    logic valid_hash;             // Hash valid signal

    // Instantiate BRAM
    BRAM2Port #(.ADDR_WIDTH(3), .DATA_WIDTH(1)) bram_inst (
        .clk(clk),
        .addr(bram_addr),
        .din(bram_din),
        .dout(bram_dout),
        .we(bram_write_en)
    );

    // Instantiate Hashing Module
    HashModule hash_inst (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ip_protocol(ip_protocol),
        .src_port(src_port),
        .dst_port(dst_port),
        .hash_out_1(hash_result_1),
        .hash_out_2(hash_result_2),
        .hash_out_3(hash_result_3),
        .valid_hash(valid_hash)
    );

    // FSM Logic for handling Bloom Filter
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= READY;
            result_out <= 0;
        end else begin
            case (state)
                READY: begin
                    if (valid_in) begin
                        state <= WAIT;
                    end
                end
                WAIT: begin
                    if (valid_hash) begin
                        // Compute BRAM address from the hash results
                        bram_addr <= hash_result_1[2:0];   // Use one of the hashes for address
                        bram_write_en <= 1;                 // Enable write to BRAM
                        bram_din <= 1;                      // Set data to 1 (indicating presence)
                        state <= GET_RESULT;
                    end
                end
                GET_RESULT: begin
                    result_out <= bram_dout;  // Output the value read from BRAM (check result)
                    state <= READY;           // Go back to READY state
                    bram_write_en <= 0;       // Disable write after result is fetched
                end
            endcase
        end
    end

    // Assigning ready signals
    assign ready_recv = (state == READY);
    assign ready_res = (state == GET_RESULT);

endmodule

// Hash Module with Multiple Hash Functions
module HashModule (
    input logic clk,
    input logic rst_n,
    input logic valid_in,
    input logic [71:0] ip_protocol,
    input logic [15:0] src_port,
    input logic [15:0] dst_port,
    output logic [31:0] hash_out_1,  // First hash output
    output logic [31:0] hash_out_2,  // Second hash output
    output logic [31:0] hash_out_3,  // Third hash output
    output logic valid_hash          // Hash valid signal
);

    // Hash Calculation State Machine
    logic [31:0] a, b, c;
    typedef enum logic [2:0] {IDLE, STEP1, STEP2, DONE} hash_state_t;
    hash_state_t hstate;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hstate <= IDLE;
            valid_hash <= 0;
        end else begin
            case (hstate)
                IDLE: if (valid_in) begin
                    // Initialize hash variables with input data
                    a <= 32'hdeadbef8 + ip_protocol[71:40];
                    b <= 32'hdeadbef1 + src_port;
                    c <= 32'hdeadbef8 + dst_port;
                    hstate <= STEP1;
                end
                STEP1: begin
                    a <= (a ^ c) - {c[27:0], c[31:28]};
                    hstate <= STEP2;
                end
                STEP2: begin
                    b <= (b ^ a) - {a[6:0], a[31:7]};
                    hash_out_1 <= (b ^ a) - {a[17:0], a[31:18]};   // First hash result
                    hash_out_2 <= (b ^ a) - {a[9:0], a[31:10]};    // Second hash result
                    hash_out_3 <= (b ^ a) - {a[15:0], a[31:16]};   // Third hash result
                    valid_hash <= 1;  // Set valid_hash signal to indicate hash is done
                    hstate <= DONE;
                end
                DONE: hstate <= IDLE;  // Return to IDLE state after completion
            endcase
        end
    end
endmodule

// 1D BRAM Module for Bloom Filter
module BRAM2Port #(parameter ADDR_WIDTH = 3, DATA_WIDTH = 1) (
    input logic clk,
    input logic [ADDR_WIDTH-1:0] addr,  // Address for BRAM
    input logic din,                     // Data input to BRAM
    output logic dout,                   // Data output from BRAM
    input logic we                       // Write enable signal
);
    logic [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];  // Memory array

    always_ff @(posedge clk) begin
        if (we)
            mem[addr] <= din;  // Write data into BRAM
        dout <= mem[addr];    // Read data from BRAM
    end
endmodule

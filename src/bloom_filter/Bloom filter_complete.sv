module mkFirewall (
    input logic clk,                // Clock signal.
    input logic reset,              // Reset signal.
    
    input logic [71:0] ip_protocol, // Input for the IP protocol.
    input logic [15:0] src_port,    // Input for the source port.
    input logic [15:0] dst_port,    // Input for the destination port.
    
    output logic readyRecv,         // Signal to indicate ready to receive inputs.
    output logic readyRes,          // Signal to indicate ready to send result.
    output logic result             // Output result from firewall (1 = allowed, 0 = denied).
);

    // FSM state definitions
    typedef enum logic [1:0] {READY, WAIT, GET_RESULT} FirewallState;
    FirewallState state;

    // Internal registers and bloom filter
    logic [31:0] hash;                      // Hash value from the hash module.
    logic [1023:0] bloom_filter;             // 1K-bit Bloom filter array.
    logic valid_hash;                        // Signal indicating hash is valid.
    logic [71:0] ip_protocol_reg;            // Register for storing IP protocol.
    logic [15:0] src_port_reg, dst_port_reg; // Registers for storing ports.

    // Instantiate the hash computation module
    mkHash hash_mod (
        .clk(clk),
        .reset(reset),
        .k0(ip_protocol_reg[31:0]),
        .k1(src_port_reg),
        .k2(dst_port_reg),
        .hashKey(hash),
        .valid_hash(valid_hash)
    );

    // Initial values and reset behavior
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= READY;
            bloom_filter <= 1024'b0; // Initialize bloom filter to all zeros
            result <= 1'b0;
        end
        else begin
            case(state)
                READY: begin
                    if (readyRecv) begin
                    
                    
                        pass_inps(ip_protocol, src_port, dst_port); // Pass inputs to hash module.
                        state <= WAIT;
                    end
                end
                
                WAIT: begin
                    if (valid_hash) begin
                        state <= GET_RESULT;
                    end
                end
                
                GET_RESULT: begin
                    // Check the Bloom filter with the computed hash value
                    if (bloom_filter[hash[9:0]] == 1'b1) begin
                        result <= 1'b1;  // Packet is allowed (hash found in the Bloom filter).
                    end
                    else begin
                        result <= 1'b0;  // Packet is denied (hash not found in the Bloom filter).
                    end
                    state <= READY; // Return to READY state.
                end

                default: state <= READY;
            endcase
        end
    end

    // Task to pass inputs to the hash computation
    task pass_inps(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
        if (state == READY) begin
            ip_protocol_reg <= ip_protocol;
            src_port_reg <= src_port;
            dst_port_reg <= dst_port;
        end
    endtask: pass_inps

    // Ready to receive inputs signal
    assign readyRecv = (state == READY);

    // Ready to return result signal
    assign readyRes = (state == GET_RESULT);

endmodule


module mkHash (
    input logic clk,            // Clock signal.
    input logic reset,          // Reset signal.
    input logic [31:0] k0,      // First input key (IP protocol lower 32 bits).
    input logic [15:0] k1,      // Second input key (Source port).
    input logic [15:0] k2,      // Third input key (Destination port).
    output logic [31:0] hashKey, // Output hash value.
    output logic valid_hash     // Output signal to indicate valid hash.
);

    // FSM States for the hash computation
    typedef enum logic [2:0] {READY, C1, C2, C3, C4, C5, C6, GET_HASH} HashState;
    HashState hstate;

    // Internal registers for hash computation
    logic [31:0] a0, b0, c0, a1, b1, a2, b2, c1;

    // Initial values and reset behavior
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            hstate <= READY;
            valid_hash <= 1'b0;
        end
        else begin
            case(hstate)
                READY: begin
                    valid_hash <= 1'b0;
                    a0 <= 32'hdeadbef8 + k0;
                    b0 <= 32'hdeadbef1 + k1;
                    c0 <= 32'hdeadbef8 + {24'b0, k2 & 8'hff};
                    
                    hstate <= C1;
                end

                C1: begin
                    c1  <= (c0 ^ b0) - {b0[17:0], b0[31:18]};
                    hstate <= C2;
                end

                C2: begin
                    a1 <= (a0 ^ c1) - {c1[20:0], c1[31:21]};
                    hstate <= C3;
                end

                C3: begin
                    b1 <= (b0 ^ a1) - {a1[6:0], a1[31:7]};
                    hstate <= C4;
                end

                C4: begin
                    a2 <= (a1 ^ c1) - {c1[27:0], c1[31:28]};
                    hstate <= C5;
                end

                C5: begin
                    b2 <= (b1 ^ a2) - {a2[17:0], a2[31:18]};
                    hstate <= C6;
                end

                C6: begin
                    hashKey <= (c1 ^ b2) - {b2[7:0], b2[31:8]};
                    valid_hash <= 1'b1;
                    hstate <= GET_HASH;
                end

                GET_HASH: begin
                    hstate <= READY;
                end
            endcase
        end
    end

    // Function to load input values
    
    task putInputs(input logic [31:0] k0, input logic [15:0] k1, input logic [15:0] k2);
        a0 <= 32'hdeadbef8 + k0;
        b0 <= 32'hdeadbef1 + k1;
        c0 <= 32'hdeadbef8 + {24'b0, k2 & 8'hff};
    endtask

endmodule

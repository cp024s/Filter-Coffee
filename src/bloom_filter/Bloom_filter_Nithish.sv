
//Bloom_Filter.sv


module Firewall_IFC (
    input logic [71:0] ip_protocol,
    input logic [15:0] src_port,
    input logic [15:0] dst_port,
    input logic clk,
    input logic reset,
    output logic result_ready,
    output logic result,
    output logic readyRecv,  // Ready to receive inputs
    output logic readyRes    // Ready with results/response
);

    typedef enum logic [1:0] {READY, WAIT, GET_RESULT} BSVWrapperState;
    BSVWrapperState state;

    logic [71:0] ip_protocol_reg;
    logic [15:0] src_port_reg;
    logic [15:0] dst_port_reg;
    logic [31:0] hash;
    logic res;

    // Instantiate BRAM2Port
    logic [2:0] dut0_addr;
    logic dut0_write;
    logic [0:0] dut0_datain;
    logic [0:0] dut0_response;

    // Instantiate hashComputer
    logic [31:0] getHash;
    logic validHash;

    // Ready signals
    logic is_ready_to_recv;
    logic is_ready_with_result;

    // BRAM request function
    function automatic BRAMRequest makeRequest(input logic write, input logic [2:0] addr, input logic data);
        BRAMRequest req;
        req.write = write;
        req.responseOnWrite = 1'b0;
        req.address = addr;
        req.datain = data;
        return req;
    endfunction

    // Hash module instantiation
    Hash_IFC hashComputer (
        .k0(ip_protocol_reg[71:40]),
        .k1(ip_protocol_reg[39:8]),
        .k2(ip_protocol_reg[7:0]),
        .clk(clk),
        .reset(reset),
        .validHash(validHash),
        .getHash(getHash)
    );

    // State machine logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= READY;
            res <= 1'b0;
        end else begin
            case(state)
                READY: begin
                    if (is_ready_to_recv) begin
                        hashComputer.putInputs(ip_protocol[71:40], ip_protocol[39:8], ip_protocol[7:0]);
                        state <= WAIT;
                    end
                end
                WAIT: begin
                    if (validHash) begin
                        dut0_addr = getHash[2:0];
                        state <= GET_RESULT;
                    end else begin
                        state <= WAIT;
                    end
                end
                GET_RESULT: begin
                    res <= (dut0_response == 1'b1);
                    state <= READY;
                end
            endcase
        end
    end

    // pass_inps task
    task automatic pass_inps(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
        if (state == READY) begin
            ip_protocol_reg = ip_protocol;
            src_port_reg = src_port;
            dst_port_reg = dst_port;
            state <= WAIT;
        end
    endtask

    // getResult function
    function automatic logic getResult();
        if (state == GET_RESULT) begin
            state <= READY;
            return res;
        end
    endfunction

    // Logic for ready signals instead of function returns
    always_comb begin
        is_ready_to_recv = (state == READY);
        is_ready_with_result = (state == GET_RESULT);
    end

    // Assign the output signals
    assign readyRecv = is_ready_to_recv;
    assign readyRes = is_ready_with_result;

endmodule


module Hash_IFC (
    input logic [31:0] k0,
    input logic [31:0] k1,
    input logic [7:0] k2,
    input logic clk,
    input logic reset,
    output logic validHash,
    output logic [31:0] getHash
);

    typedef enum logic [2:0] {C1, C2, C3, C4, C5, C6, READY} HashComputeState;
    HashComputeState hstate;

    logic [31:0] a0, b0, c0, a1, b1, a2, b2, c1, hashKey;
    logic valid_hash;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            hstate <= C1;
            valid_hash <= 1'b0;
        end else begin
            case (hstate)
                C1: begin
                    c1 <= (c0 ^ b0) - {b0[17:0], b0[31:18]};
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
                    hstate <= READY;
                end
                READY: begin
                    valid_hash <= 1'b0;
                end
            endcase
        end
    end

    // putInputs method
    task automatic putInputs(input logic [31:0] k0, input logic [31:0] k1, input logic [7:0] k2);
        a0 = 32'hdeadbef8 + k0;
        b0 = 32'hdeadbef1 + k1;
        c0 = 32'hdeadbef8 + {24'b0, k2};
        hstate <= C1;
        valid_hash <= 1'b0;
    endtask

    assign validHash = valid_hash;
    assign getHash = hashKey;

endmodule



-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

//Bloom_Filter_TB.sv


module mkTb;

    // Declare internal registers for inputs and the result
    logic [71:0] ip_pro_1, ip_pro_2;
    logic [15:0] port1_1, port2_1, port1_2, port2_2;
    logic clk, reset;
    logic readyRecv, readyRes;
    logic result;
    logic result_ready;

    // Counter for controlling testbench behavior
    logic [5:0] cntr;  // Declaring the counter

    // Instantiate the Firewall module
    Firewall_IFC dut (
        .ip_protocol(ip_pro_1),  // Inputs will be updated in the test logic
        .src_port(port1_1),
        .dst_port(port2_1),
        .clk(clk),
        .reset(reset),
        .result_ready(result_ready),
        .result(result),
        .readyRecv(readyRecv),
        .readyRes(readyRes)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 time units clock period
    end

    // Reset logic
    initial begin
        reset = 1;
        #15 reset = 0;  // Release reset after 15 time units
    end

    // Initialize IP's & ports
    initial begin
        // First IP, port configuration
        ip_pro_1 = {8'd192, 8'd169, 8'd1, 8'd30, 8'd192, 8'd168, 8'd1, 8'd30, 8'd30};  // src_ip, dst_ip, protocol
        port1_1 = 16'd16538;  // Source port
        port2_1 = 16'd37281;  // Destination port

        // Second IP, port configuration (unused in this version, but prepared)
        ip_pro_2 = {8'd192, 8'd169, 8'd1, 8'd40, 8'd192, 8'd168, 8'd1, 8'd40, 8'd40};  // src_ip, dst_ip, protocol
        port1_2 = 16'd29386;  // Source port
        port2_2 = 16'd38849;  // Destination port
    end

 
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cntr <= 0;  // Initialize counter when reset is high
        end else begin
            case (cntr)
                0: begin
                    if (readyRecv) begin
                        // Send the first set of IP and port inputs
                        $display($time, "Sent IP and port: %h %d %d", ip_pro_1, port1_1, port2_1);
                        cntr <= cntr + 1;  // Increment counter
                    end
                end

                1: begin
                    if (readyRes) begin
                        // Get the result
                        $display($time, "Received result: %b", result);
                        $finish;  // End the simulation after receiving the result
                    end
                end

                default: begin
                    $finish;  // End the simulation if cntr is out of bounds
                end
            endcase
        end
    end

endmodule


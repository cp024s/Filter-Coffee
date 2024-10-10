module Firewall_new;  // Start of the module definition.

    // Interface declaration
    interface Firewall_IFC;
        logic [71:0] ip_protocol;    // Input for the IP protocol.
        logic [15:0] src_port;       // Input for the source port.
        logic [15:0] dst_port;       // Input for the destination port.
        logic readyRecv;             // Signal to indicate ready to receive inputs.
        logic readyRes;              // Signal to indicate ready to send result.
        logic result;                // Output result from firewall.
    endinterface

    // Internal state representation
    typedef enum logic [1:0] {
        READY = 2'b00,
        WAIT = 2'b01,
        GET_RESULT = 2'b10
    } FirewallState;

    // Registers
    reg FirewallState state = READY;      // State machine for firewall.
    reg [71:0] ip_protocol_reg;           // Register for the IP protocol.
    reg [15:0] src_port_reg, dst_port_reg; // Registers for source and destination ports.
    reg [31:0] hash;                      // Register for the hash value.
    reg res = 1'b0;                       // Result register.

    // Instantiate BRAM and hash modules (assumed external)
    // Assuming BRAMRequest and Hash modules are separately defined.

    // Generate a BRAM request
    function automatic [32:0] makeRequest(input logic write, input logic [2:0] addr, input logic [0:0] data);
        makeRequest = {write, addr, data};
    endfunction

    // Main FSM
    always_ff @(posedge clk) begin
        case(state)
            READY: begin
                if (/* some condition */) begin
                    state <= WAIT;
                end
            end

            WAIT: begin
                if (/* hash is valid */) begin
                    // Perform BRAM read or write
                    hash <= /* hash computation */;
                    state <= GET_RESULT;
                end
                else begin
                    state <= WAIT; // Keep waiting
                end
            end

            GET_RESULT: begin
                res <= /* check BRAM result */;
                state <= READY; // Transition back to ready state.
            end

            default: state <= READY;
        endcase
    end

    // Method to pass inputs into the firewall
    task pass_inps(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
        if (state == READY) begin
            ip_protocol_reg <= ip_protocol;
            src_port_reg <= src_port;
            dst_port_reg <= dst_port;
            state <= WAIT;
        end
    endtask

    // Method to get the result of the firewall operation
    function logic getResult();
        if (state == GET_RESULT) begin
            getResult = res;
        end
    endfunction

    // Ready to receive inputs signal
    function logic readyRecv();
        readyRecv = (state == READY);
    endfunction

    // Ready to return result signal
    function logic readyRes();
        readyRes = (state == GET_RESULT);
    endfunction

endmodule


// Hash computation module
module HashModule(input logic [31:0] k0, input logic [31:0] k1, input logic [7:0] k2,
                  output logic [31:0] hash_out, output logic valid);

    // Internal registers
    reg [31:0] a0, b0, c0, a1, b1, a2, b2, c1;
    reg valid_hash = 1'b0;

    always_ff @(posedge clk) begin
        case(state)
            // Various hash computation steps here
            // Update a0, b0, c0, etc.
            // Set valid_hash when done
        endcase
    end

    assign hash_out = c1 ^ b2; // Example hash combination
    assign valid = valid_hash;
    
endmodule


// Testbench
module tb_Firewall;

    // Instantiate the firewall module
    Firewall_new firewall_dut();

    initial begin
        // Test scenarios

        // Pass input to the firewall
        firewall_dut.pass_inps(72'hc0a80130c0a80130, 16'd16538, 16'd37281);
        
        // Wait for result
        #10;
        if (firewall_dut.readyRes()) begin
            $display("Result: %b", firewall_dut.getResult());
        end

        // Finish simulation
        #20;
        $finish;
    end
endmodule

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  BLOOM FILTER OVERALL  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
typedef enum logic [1:0] { READY = 2'b00, WAIT = 2'b01, GET_RESULT = 2'b10 } FirewallState;
typedef enum {READY, C1, C2, C3, C4, C5, C6, GET_HASH} HashComputeState // Define states for hash computation.

// Registers
reg FirewallState state = READY;       // State machine for firewall.
reg [71:0] ip_protocol_reg;            // Register for the IP protocol.
reg [15:0] src_port_reg, dst_port_reg; // Registers for source and destination ports.
reg [31:0] hash;                       // Register for the hash value.
reg res = 1'b0;                        // Result register.

// FIREWALL INTERFACE
interface Firewall_IFC;

    logic [71:0] ip_protocol;    // Input for the IP protocol.
    logic [15:0] src_port;       // Input for the source port.
    logic [15:0] dst_port;       // Input for the destination port.
    logic readyRecv;             // Signal to indicate ready to receive inputs.
    logic readyRes;              // Signal to indicate ready to send result.
    logic result;                // Output result from firewall.

    // method action        - task
    // method action value  - function
    
    // method Action pass_inps(Bit#(72) ip_protocol, Bit#(16) src_port, Bit#(16) dst_port); // Method to pass input data.
    task pass_inps(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
    if (state == READY) begin
        ip_protocol_reg <= ip_protocol;
        src_port_reg <= src_port;
        dst_port_reg <= dst_port;
        state <= WAIT;
    end
    endtask

    // method Bool readyRecv; // Method to check if the firewall is ready to receive inputs.
    // Ready to receive inputs signal
    task logic readyRecv();
        readyRecv = (state == READY);
    endtask: readyRecv

    // method Bool readyRes; // Method to check if the firewall is ready to provide results.
    // Ready to return result signal
    function logic readyRes();
        readyRes = (state == GET_RESULT);
    endfunction

    // method ActionValue#(Bool) getResult; // Method to get the result of the firewall's processing.
    // Method to get the result of the firewall operation
    function logic getResult();
        if (state == GET_RESULT) begin
            getResult = res;
        end
    endfunction

endinterface

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// 1st FSM STATE
module 
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
endmodule

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// 2nd FSM STATE
module HashModule(input logic [31:0] k0, input logic [31:0] k1, input logic [7:0] k2, output logic [31:0] hash_out, output logic valid);

    // Internal registers
    reg [31:0] a0, b0, c0, a1, b1, a2, b2, c1;
    reg valid_hash = 1'b0;

    always_ff @(posedge clk) begin
        case(state)


        endcase
    end

    assign hash_out = c1 ^ b2; // Example hash combination
    assign valid = valid_hash;
    
endmodule

// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

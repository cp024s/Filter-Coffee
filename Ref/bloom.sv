 // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
    typedef enum logic [1:0] { READY = 2'b00, WAIT = 2'b01, GET_RESULT = 2'b10 } FirewallState;

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
module HashModule(input logic [31:0] k0, input logic [31:0] k1, input logic [7:0] k2, output logic [31:0] hash_out, output logic valid);

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

 // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
module Firewall_new;
    // State enumeration for the firewall operation
    typedef enum logic [1:0] {READY, WAIT, GET_RESULT} BSVWrapperState;
    BSVWrapperState state; // Register to hold the current state of the firewall

    // Structure for BRAM request
    typedef struct packed {
        logic write;            // Write flag for the BRAM operation
        logic responseOnWrite;  // Disable response on write operations
        logic [2:0] address;    // Address to access in the BRAM (3 bits)
        logic [0:0] datain;     // Data to be written to BRAM (1 bit)
    } BRAMRequest;

    // Function to create a BRAM request
    function BRAMRequest makeRequest(input logic write, input logic [2:0] addr, input logic [0:0] data);
        BRAMRequest request;
        request.write = write;               // Set the write flag
        request.responseOnWrite = 0;         // Disable response on write operations
        request.address = addr;              // Set the BRAM address
        request.datain = data;               // Set the data to be written
        return request;                      // Return the constructed BRAMRequest
    endfunction

    // Registers to hold input and processing data
    logic [71:0] ip_protocol_reg; // Register for IP protocol
    logic [15:0] src_port_reg;    // Register for source port
    logic [15:0] dst_port_reg;    // Register for destination port
    logic [31:0] hash;            // Register for the hash value
    logic res;                    // Register to hold the result

    // Instantiate the BRAM memory
    logic [0:0] bram_data_out; // Data output from BRAM
    BRAMRequest bram_req; // BRAM request instance

    // Control signals for the firewall
    logic readyRecv; // Signal to indicate the firewall is ready to receive inputs
    logic readyRes;  // Signal to indicate the firewall is ready to provide results

    // Method to check if the firewall is ready to receive inputs
    always_comb begin
        readyRecv = (state == READY);
    end

    // Method to check if the firewall is ready to provide results
    always_comb begin
        readyRes = (state == GET_RESULT);
    end

    // Method to input values for hash computation (equivalent to putInputs)
    task putInputs(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
        if (state == READY) begin
            // Store inputs into registers
            ip_protocol_reg = ip_protocol;
            src_port_reg = src_port;
            dst_port_reg = dst_port;
            
            // Trigger the hash computation by passing inputs to the hash unit (mock-up)
            // Here, assume some hash computation logic occurs, resulting in the 'hash' value
            hash = (ip_protocol[71:40] ^ ip_protocol[39:8]) + {16'd0, src_port} + {16'd0, dst_port};
            
            // Move to the WAIT state to process the hash
            state <= WAIT;
        end
    endtask

    // Rule to transition states and run operations
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= READY;
            res <= 0;
        end
        else begin
            case (state)
                WAIT: begin
                    // Run hash computation or any intermediate processing
                    if (/* hash is valid */) begin
                        // Make a BRAM read request using the hash value
                        bram_req = makeRequest(0, hash[2:0], 1'b0);
                        state <= GET_RESULT; // Move to the GET_RESULT state
                    end
                end
                GET_RESULT: begin
                    // Retrieve the result from BRAM
                    if (/* BRAM data is ready */) begin
                        bram_data_out = /* BRAM data read */;
                        res <= (bram_data_out == 1); // Check if result is a match
                        state <= READY; // Return to READY state for the next operation
                    end
                end
            endcase
        end
    end

    // Logic to retrieve the result of firewall processing
    function logic getResult;
        if (state == GET_RESULT) begin
            getResult = res;
        end
        else begin
            getResult = 0;
        end
    endfunction

endmodule

 // ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

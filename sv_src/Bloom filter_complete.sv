// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  BLOOM FILTER COMPLETE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  GLOBAL VARIABLES  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

typedef enum logic [1:0] { READY = 2'b00, WAIT = 2'b01, GET_RESULT = 2'b10 } FirewallState;
typedef enum {READY, C1, C2, C3, C4, C5, C6, GET_HASH} HashComputeState // Define states for hash computation.

// Registers
reg FirewallState state = READY;       // State machine for firewall.
reg [71:0] ip_protocol_reg;            // Register for the IP protocol.
reg [15:0] src_port_reg, dst_port_reg; // Registers for source and destination ports.

reg [31:0] hash;                       // Register for the hash value.
reg res = 1'b0;                        // Result register.

reg [31:0] hashkey;
logic valid;

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  FIREWALL INTERFACE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

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
    function pass_inps(input logic [71:0] ip_protocol, input logic [15:0] src_port, input logic [15:0] dst_port);
    if (state == READY) begin
        ip_protocol_reg <= ip_protocol;
        src_port_reg <= src_port;
        dst_port_reg <= dst_port;
        state <= WAIT;
    end
    endfunction: pass_inps

    // method Bool readyRecv; // Method to check if the firewall is ready to receive inputs.
    // Ready to receive inputs signal
    function logic readyRecv();
        readyRecv = (state == READY);
    endfunction: readyRecv

    // method Bool readyRes; // Method to check if the firewall is ready to provide results.
    // Ready to return result signal
    function logic readyRes();
        readyRes = (state == GET_RESULT);
    endfunction: readyRes

    // method ActionValue#(Bool) getResult; // Method to get the result of the firewall's processing.
    // Method to get the result of the firewall operation
    function logic getResult();
        if (state == GET_RESULT) begin
            getResult = res;
        end
    endfunction: getResult

endinterface: Firewall_IFC


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  1st FSM STATE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module mkFirewall (Firewall_IFC IFC)

        always_ff @(posedge clk) begin
        case(state)
            READY: begin
                if () begin
                    state <= WAIT;
                end
            end

            WAIT: begin
                if () begin
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


// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  2nd  FSM HASH MODULE  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

module HashModule(input logic [31:0] k0, input logic [31:0] k1, input logic [7:0] k2, output logic [31:0] hash_out, output logic valid);

    // Internal registers
    reg [31:0] a0, b0, c0, a1, b1, a2, b2, c1;
    reg valid_hash = 1'b0;

    wire wr_validInputs

    always_ff @(posedge clk) begin

         case(hstate)
		 // STATE - C1
            C1: 
                $display(" State =  C1");
	            c1  <= (c0 ^ b0) - {b0[17:0], b0[31:18]};
                hstate = C2;
                valid_hash = 0;
                
		 // STATE - C2
            C2:
                $display(" State = C2");
                a1 <= (a0 ^ c1) - {c1[20:0], c1[31:21]};
                hstate = C3;
        
		 // STATE - C3
            C3:
                $display(" State = C3");
                b1 <= (b0 ^ a1) - {a1[6:0], a1[31:7]};
                hstate = C4;
                
		 // STATE - C4
            C4:
                $display(" State = C4");
                a2 <= (a1 ^ c1) - {c1[27:0], c1[31:28]};
                hstate = C5;

		 // STATE - C5
            C5:
                $display(" State = C5");
                b2 <= (b1 ^ a2) - {a2[17:0], a2[31:18]};
                hstate = C6;

		 // STATE - C6 Final stage
            C6:
                $display(" State = C6");
                hashKey <= (c1 ^ b2) - {b2[7:0], b2[31:8]};
                Valid_hash = 1;
                
		 // Default case
            Default:
                $display(" Default state");
                hstate = C1;
                
         endcase
    end

    function putInputs (k0, k1, k2);
        a0 <= 32'h deadbef8 + k0;
        b0 <= 32'h deadbef1 + k1;
        c0 <= 32'h deadbef8 + {24'b0, k2 & 8'hff};

        wr_validInputs = 1;
        $display(" Inside put inputs")
    endfunction

    assign hashkey = hashKey
    assign getHash = valid_hash;
    
endmodule

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  END  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~




// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~  USE THIS SPACE BELOW FOR ROUGH WORK  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

BRAM_test test_inst (
  .clka(clka),    // input wire clka
  .ena(ena),      // input wire ena
  .wea(wea),      // input wire [0 : 0] wea
  .addra(addra),  // input wire [3 : 0] addra
  .dina(dina),    // input wire [15 : 0] dina
  .douta(douta)  // output wire [15 : 0] douta
);

// You must compile the wrapper file BRAM_test.v when simulating
// the core, BRAM_test. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.


// BRAM REQUEST
always_ff @(posedge clk or posedge reset) begin

    if (reset) begin
        state <= WAIT;
    end 
    
    else if (state == WAIT) begin

        if (hashComputer.validHash()) begin
            logic [2:0] z = hashComputer.getHash()[2:0]; // Extracting the 3 least significant bits
            dut0.portA.request.put(makeRequest(false, z, ?)); // Replace ? with actual value
            state <= GET_RESULT;
            $display($time, " done");

        end 
        
        else begin
            state <= WAIT;
            $display($time, " waiting");
        end

    end

end

function BRAMRequest makeRequest(logic write, logic [2:0] addr, logic [0:0] data);
    BRAMRequest req; // Declare a variable of type BRAMRequest
    req.write = write;
    req.responseOnWrite = 1'b0; // Equivalent to False
    req.address = addr;
    req.datain = data;
    
    return req; // Return the request struct
endfunction


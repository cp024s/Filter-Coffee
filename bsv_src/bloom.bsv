package Firewall_new;  // Start of the package definition named Firewall_new.
import BRAM::*;         // Import all definitions from the BRAM module.
import StmtFSM::*;     // Import all definitions from the State Machine module.

interface Firewall_IFC; // Define the interface for the firewall.
    method Action pass_inps(Bit#(72) ip_protocol, Bit#(16) src_port, Bit#(16) dst_port); // Method to pass input data.
    method ActionValue#(Bool) getResult; // Method to get the result of the firewall's processing.
    method Bool readyRecv; // Method to check if the firewall is ready to receive inputs.
    method Bool readyRes; // Method to check if the firewall is ready to provide results.
endinterface // End of the Firewall_IFC interface.

function BRAMRequest#(Bit#(3), Bit#(1)) makeRequest(Bool write, Bit#(3) addr, Bit#(1) data); // Function to create a BRAM request. paramertized
    return BRAMRequest{ // Return a new BRAMRequest.
        write: write, // Boolean - Set write flag.
        responseOnWrite: False, // Disable response on write operations.
        address: addr, // 3 bits - Set the address for the request.
        datain: data // 1 bit - Set the data to be written.
    };
endfunction // End of the makeRequest function.

typedef enum {READY, WAIT, GET_RESULT} BSVWrapperState // Define the states for the firewall operation.
deriving (Bits, Eq, FShow); // Enable automatic bit representation, equality comparison, and formatted display.

(*synthesize*) // Directive for synthesis tools.
module mkFirewall (Firewall_IFC); // Define the firewall module implementing the Firewall_IFC interface.

    BRAM_Configure cfg = defaultstatesValue; // Create a configuration for BRAM with default values.    
    cfg.allowWriteResponseBypass = False; // Disable bypass for write response.
    cfg.loadFormat = tagged Hex "bloomfilter.mem"; // Load a memory file for the BRAM.
    BRAM2Port#(Bit#(3), Bit#(1)) dut0 <- mkBRAM2Server(cfg); // Instantiate a BRAM server.

    Hash_IFC hashComputer <- mkHash; // Instantiate the hash computation module.

    Reg#(BSVWrapperState) state <- mkReg(READY); // Register to hold the current state of the firewall.

    // Registers to hold input and processing data.
    Reg#(Bit#(72)) ip_protocol_reg <- mkReg(?); // Register for IP protocol.
    Reg#(Bit#(16)) src_port_reg <- mkReg(?); // Register for source port.
    Reg#(Bit#(16)) dst_port_reg <- mkReg(?); // Register for destination port.
    Reg#(Bit#(32)) hash <- mkReg(?); // Register for the hash value.
    Reg#(Bool) res <- mkReg(False); // Register for the result.

    // Rule to run the timer and handle state transitions.
    rule run_timer if (state == WAIT);
        (* split *) // Split the processing into separate branches.
        if(hashComputer.validHash()) // Check if the hash is valid.
        begin
            // let z <- hashComputer.getHash(); // Retrieve the hash (currently commented out).
            // $display($time, " Hash %b", z); // Display the hash value (currently commented out).
            dut0.portA.request.put(makeRequest(False, hashComputer.getHash()[2:0], ?)); // Make a request to BRAM using the hash.
            state <= GET_RESULT; // Transition to the GET_RESULT state.
            $display($time, " done"); // Log that processing is done.
        end
        else
        begin
            state <= WAIT; // Stay in the WAIT state if no valid hash.
            $display($time, " waiting"); // Log waiting status.
        end          
    endrule // End of the run_timer rule.

    // Method to receive inputs.
    method Action pass_inps(Bit#(72) ip_protocol, Bit#(16) src_port, Bit#(16) dst_port) if (state == READY);
        hashComputer.putInputs(ip_protocol[71:40], ip_protocol[39:8], ip_protocol[7:0]); // Pass IP protocol components to the hash computer.
        state <= WAIT; // Transition to the WAIT state.
    endmethod // End of pass_inps method.

    // Method to get results.
    method ActionValue#(Bool) getResult if (state == GET_RESULT);
        $display($time, "Inside getResult"); // Log entry into getResult.
        let y <- dut0.portA.response.get; // Retrieve the response from BRAM.
        $display("dut0read[0] = %b", y); // Log the retrieved response.
        state <= READY; // Transition back to the READY state.
        return y == 1; // Return true if the response indicates success.
    endmethod // End of getResult method.

    // Method to check if the firewall is ready to receive inputs.
    method Bool readyRecv;
        if (state == READY)
            return True; // Return true if in READY state.
        else
            return False; // Return false otherwise.
    endmethod // End of readyRecv method.

    // Method to check if the firewall is ready to provide results.
    method Bool readyRes;
        if (state == GET_RESULT)
            return True; // Return true if in GET_RESULT state.
        else
            return False; // Return false otherwise.
    endmethod // End of readyRes method.

endmodule // End of mkFirewall module.

interface Hash_IFC; // Define the interface for the hash computation.
    method Action putInputs(Bit#(32) k0, Bit#(32) k1, Bit#(8) k2); // Method to input data for hash computation.
    method Bit#(32) getHash; // Method to retrieve the computed hash.
    method Bool validHash(); // Method to check if a valid hash is avaistateslable.
endinterface // End of Hash_IFC interface.

typedef enum {READY, C1, C2, C3, C4, C5, C6, GET_HASH} HashComputeState // Define states for hash computation.
deriving (Bits, Eq, FShow); // Enable automatic bit representation, equality comparison, and formatted display.

module mkHash(Hash_IFC); // Define the hash computation module implementing Hash_IFC.
    Reg#(HashComputeState) hstate <- mkReg(C1); // Register to hold the current state of the hash computation.
    // Registers to hold intermediate hash values.
    Reg#(Bit#(32)) a0 <- mkReg(?);
    Reg#(Bit#(32)) b0 <- mkReg(?);
    Reg#(Bit#(32)) c0 <- mkReg(?);
    Reg#(Bit#(32)) a1 <- mkReg(?);
    Reg#(Bit#(32)) b1 <- mkReg(?);
    Reg#(Bit#(32)) a2 <- mkReg(?);
    Reg#(Bit#(32)) b2 <- mkReg(?);	
    Reg#(Bit#(32)) c1 <- mkReg(?);
    Reg#(Bit#(32)) hashKey <- mkReg(?); // Register to hold the final hash key.
    Wire#(Bool) wr_validInputs <- mkDWire(False); // Wire to indicate if valid inputs have been written.
    Reg#(Bool) valid_hash <- mkReg(False); // Register to indicate if a valid hash is available.

    // State transitions for hash computation.
    rule rc1 if(hstate == C1);
        $display("C1 state"); // Log current state.
        c1 <= (c0 ^ b0) - {b0[17:0], b0[31:18]}; // Compute part of the hash.
        hstate <= C2; // Transition to the next state.
        valid_hash <= False; // Reset valid hash flag.
    endrule // End of rc1 rule.

    rule c2 if(hstate == C2);
        //$display("C2 state"); // Log current state.
        a1 <= (a0 ^ c1) - {c1[20:0], c1[31:21]}; // Compute part of the hash.
        hstate <= C3; // Transition to the next state.
    endrule // End of c2 rule.

    rule c3 if(hstate == C3);
        $display("C3 state"); // Log current state.
        b1 <= (b0 ^ a1) - {a1[6:0], a1[31:7]}; // Compute part of the hash.
        hstate <= C4; // Transition to the next state.
    endrule // End of c3 rule.

    rule c4 if(hstate == C4);
        $display("C4 state"); // Log current state.
        a2 <= (a1 ^ c1) - {c1[27:0], c1[31:28]}; // Compute part of the hash.
        hstate <= C5; // Transition to the next state.
    endrule // End of c4 rule.

    rule c5 if(hstate == C5);
        $display("C5 state"); // Log current state.
        b2 <= (b1 ^ a2) - {a2[17:0], a2[31:18]}; // Compute part of the hash.
        hstate <= C6; // Transition to the next state.
    endrule // End of c5 rule.

    rule c6 if(hstate == C6);
        $display("C6 state"); // Log current state.
        hashKey <= (c1 ^ b2) - {b2[7:0], b2[31:8]}; // Compute the final hash value.
        valid_hash <= True; // Set valid hash flag.
        // hstate <= C1; // (Commented out) Reset state to C1.
    endrule // End of c6 rule.

    // Method to input values for hash computation.
    method Action putInputs(Bit#(32) k0, Bit#(32) k1, Bit#(8) k2);states
        a0 <= 32'hdeadbef8 + k0; // Initialize a0 with a constant and k0.
        b0 <= 32'hdeadbef1 + k1; // Initialize b0 with a constant and k1.
        c0 <= 32'hdeadbef8 + {24'b0, k2 & 8'hff}; // Initialize c0 with a constant and k2 (masked).
        wr_validInputs <= True; // Set flag indicating valid inputs.
        $display("Inside put inputs"); // Log entry into putInputs.
    endmethod // End of putInputs method.

    method Bool validHash = valid_hash; // Method to check if a valid hash is available.
    method Bit#(32) getHash = hashKey; // Method to retrieve the computed hash value.
endmodule // End of mkHash module.

(*synthesize*) // Directive for synthesis tools.
module mkTb (Empty); // Define the testbench module mkTb.
    Firewall_IFC dut <- mkFirewall; // Instantiate the firewall module.

    Reg#(Bit#(6)) cntr <- mkReg(0); // Register to count simulation cycles.

    // Define input values for testing.
    Bit#(72) ip_pro_1 = {8'd192, 8'd169, 8'd1, 8'd30, 8'd192, 8'd168, 8'd1, 8'd30, 8'd30}; // First input IP protocol.
    Bit#(16) port1_1 = 16'd16538; // First input source port.
    Bit#(16) port2_1 = 16'd37281; // First input destination port.
    Bit#(72) ip_pro_2 = {8'd192, 8'd169, 8'd1, 8'd40, 8'd192, 8'd168, 8'd1, 8'd40, 8'd40}; // Second input IP protocol.
    Bit#(16) port1_2 = 16'd29386; // Second input source port.
    Bit#(16) port2_2 = 16'd38849; // Second input destination port.

    // Rule to initialize and send the first input.
    rule init (cntr == 0);
        $dumpvars(); // Prepare for dumping simulation variables.
        dut.pass_inps(ip_pro_1, port1_1, port2_1); // Send the first input to the firewall.
        $display($time, "Sent ip and port"); // Log that inputs have been sent.
        cntr <= cntr + 1; // Increment the counter.
    endrule // End of init rule.

    // Rule to receive the result from the firewall.
    rule r1(dut.readyRes());
        let z <- dut.getResult(); // Get the result from the firewall.
        $display($time, " Received %b", z); // Log the received result.
        $finish; // End the simulation.
    endrule // End of r1 rule.

    // Commented out rules for future implementation (if needed).
    // rule r2 
    //     cntr <= cntr + 1; 
    // endrule 

    // rule end_sim if (cntr == 32);
    // endrule

endmodule // End of mkTb module.
endpackage : Firewall_new // End of the Firewall_new package.

// Ethernet_IP_MDIO_TB.sv


module Ethernet_IP_MDIO_tb;

    // Signals
    logic clk;
    logic reset;

    // Interface instantiation
    PhyMDIOIfc phy_mdio_ifc();

    // DUT (Device Under Test) instantiation
    Ethernet_IP_MDIO dut (
        .clk(clk),
        .reset(reset),
        .phy_mdio_ifc(phy_mdio_ifc)
    );

    // Clock generation (10-time unit period)
    always #5 clk = ~clk;

    // Testbench procedure
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Reset sequence
        #10 reset = 0; // Assert reset
        #10 reset = 1; // Deassert reset

        // Run the simulation for a specified amount of time
        #1000;
        $finish;
    end

    // Monitor output signals and state transitions
    initial begin
        // Header for output monitoring
        $display("Time\tMDIO_O\tMDIO_T\tState\tGap_Counter\tBit_Counter");
        
        // Monitor the signals and FSM state
        forever begin
            @(posedge clk); // Wait for clock edge
            log_signals();
        end
    end

    // Task to log the signals
    task log_signals();
        $display("%0t\t%b\t%b\t%s\t%d\t%d",
                 $time, 
                 phy_mdio_ifc.mdio_o, 
                 phy_mdio_ifc.mdio_t, 
                 state_name(dut.fsm_state), 
                 dut.gap_counter, 
                 dut.bit_counter);
    endtask

    // Function to return the state name as a string
    function string state_name(input logic [2:0] state); // Change is here
        case (state)
            3'b000: return "GAP1";       // Represent GAP1 state
            3'b001: return "COMMAND1";   // Represent COMMAND1 state
            3'b010: return "GAP2";       // Represent GAP2 state
            3'b011: return "COMMAND2";   // Represent COMMAND2 state
            3'b100: return "GAP3";       // Represent GAP3 state
            3'b101: return "COMMAND3";   // Represent COMMAND3 state
            3'b110: return "DONE";       // Represent DONE state
            default: return "UNKNOWN";
        endcase
    endfunction

endmodule


// Ethernet_IP_MDIO.sv


// Define the interface
interface PhyMDIOIfc();
    logic mdio_o;  // MDIO output
    logic mdio_t;  // MDIO tri-state control

    // Function to return the value of mdio_o
    function logic m_phy_mdio_o();
        return mdio_o;
    endfunction

    // Function to return the value of mdio_t
    function logic m_phy_mdio_t();
        return mdio_t;
    endfunction
endinterface


// Ethernet_IP_MDIO Module Implementation
module Ethernet_IP_MDIO (
    // Clock and reset signals
    input logic clk,               // Clock signal
    input logic reset,             // Reset signal (active high)
    
    PhyMDIOIfc phy_mdio_ifc       // Interface instance
);

    typedef enum logic [2:0] {
        GAP1, COMMAND1, GAP2, COMMAND2, GAP3, COMMAND3, DONE
    } CommandFSMState;

    // Register declarations
    CommandFSMState fsm_state;
    logic [6:0] gap_counter;
    logic [6:0] bit_counter;

    logic [31:0] command1 = 32'b00000000100011000100000100001010;  // Command 1
    logic [31:0] command2 = 32'b00000000000000000110010100001010;  // Command 2
    logic [31:0] command3 = 32'b00000000110011000100000100001010;  // Command 3

    // Initial conditions or reset conditions
    always_ff @(posedge clk or negedge reset) begin
        if (!reset) begin
            fsm_state <= GAP1;
            gap_counter <= 0;
            bit_counter <= 0;
            phy_mdio_ifc.mdio_o <= 0;  // Initialize mdio_o
            phy_mdio_ifc.mdio_t <= 1;  // Initialize mdio_t
        end else begin
            case (fsm_state)

                GAP1: begin
                    phy_mdio_ifc.mdio_o <= 1'b0;
                    phy_mdio_ifc.mdio_t <= 1'b1;
                    if (gap_counter < 64) begin
                        gap_counter <= gap_counter + 1;
                    end else begin
                        gap_counter <= 0;
                        fsm_state <= COMMAND1;
                        bit_counter <= 0;
                    end
                end

                COMMAND1: begin
                    if (bit_counter < 32) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= 1'b1;
                        bit_counter <= bit_counter + 1;
                    end else if (bit_counter < 64) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= command1[bit_counter - 32];
                        bit_counter <= bit_counter + 1;
                    end else begin
                        phy_mdio_ifc.mdio_t <= 1'b1;
                        phy_mdio_ifc.mdio_o <= 1'b0;
                        bit_counter <= 0;
                        fsm_state <= GAP2; 
                    end
                end

                GAP2: begin
                    phy_mdio_ifc.mdio_o <= 1'b0;
                    phy_mdio_ifc.mdio_t <= 1'b1;
                    if (gap_counter < 64) begin
                        gap_counter <= gap_counter + 1;
                    end else begin
                        gap_counter <= 0;
                        fsm_state <= COMMAND2;
                        bit_counter <= 0;
                    end
                end

                COMMAND2: begin
                    if (bit_counter < 32) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= 1'b1;
                        bit_counter <= bit_counter + 1;
                    end else if (bit_counter < 64) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= command2[bit_counter - 32];
                        bit_counter <= bit_counter + 1;
                    end else begin
                        phy_mdio_ifc.mdio_t <= 1'b1;
                        phy_mdio_ifc.mdio_o <= 1'b0;
                        bit_counter <= 0;
                        fsm_state <= GAP3; 
                    end
                end

                GAP3: begin
                    phy_mdio_ifc.mdio_o <= 1'b0;
                    phy_mdio_ifc.mdio_t <= 1'b1;
                    if (gap_counter < 64) begin
                        gap_counter <= gap_counter + 1;
                    end else begin
                        gap_counter <= 0;
                        fsm_state <= COMMAND3;
                        bit_counter <= 0;
                    end
                end

                COMMAND3: begin
                    if (bit_counter < 32) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= 1'b1;
                        bit_counter <= bit_counter + 1;
                    end else if (bit_counter < 64) begin
                        phy_mdio_ifc.mdio_t <= 1'b0;
                        phy_mdio_ifc.mdio_o <= command3[bit_counter - 32];
                        bit_counter <= bit_counter + 1;
                    end else begin
                        phy_mdio_ifc.mdio_t <= 1'b1;
                        phy_mdio_ifc.mdio_o <= 1'b0;
                        bit_counter <= 0;
                        fsm_state <= DONE; 
                    end
                end

                DONE: begin
                    phy_mdio_ifc.mdio_t <= 1'b1;
                    phy_mdio_ifc.mdio_o <= 1'b0;
                end

            endcase
        end
    end

endmodule

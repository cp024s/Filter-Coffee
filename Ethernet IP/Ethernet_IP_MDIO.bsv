package Ethernet_IP_MDIO;

import  Clocks::*;

interface PhyMDIOIfc;
    (* always_ready, result="eth_mdio_o" *) 
    method Bit#(1) m_phy_mdio_o;
    (* always_ready, result="eth_mdio_t" *) 
    method Bit#(1) m_phy_mdio_t;
endinterface

typedef enum { GAP1, COMMAND1, GAP2, COMMAND2, GAP3, COMMAND3, DONE} CommandFSMState
deriving (Bits, Eq, FShow);


(*synthesize*)
module mkEthIPMDIO(PhyMDIOIfc);

    Reg#(CommandFSMState) fsm_state <- mkReg(GAP1);
    Reg#(Bit#(7)) gap_counter <- mkReg(0);
    Reg#(Bit#(7)) bit_counter <- mkReg(0);

    // TODO
    Reg#(Bit#(32)) command1 <- mkReg(32'b00000000100011000100000100001010);  // Value must be sent in this order:    01-01-00001-00000-10-00110001-00000000
    Reg#(Bit#(32)) command2 <- mkReg(32'b00000000000000000110010100001010);  // Value must be sent in this order:    01-01-00001-01001-10-00000000-00000000
    Reg#(Bit#(32)) command3 <- mkReg(32'b00000000110011000100000100001010);  // Value must be sent in this order:    01-01-00001-00000-10-00110011-00000000

    Reg#(Bit#(1)) mdio_o <- mkReg(0);
    Reg#(Bit#(1)) mdio_t <- mkReg(1);

    rule r_gap1 if (fsm_state == GAP1);
        mdio_o <= 1'b0;
        mdio_t <= 1'b1;
        if (gap_counter + 1 <= 64) begin
            gap_counter <= gap_counter + 1;
        end
        else begin
            gap_counter <= 0;
            fsm_state <= COMMAND1;
            bit_counter <= 0;
        end
    endrule

    rule r_command1 if (fsm_state == COMMAND1);
        if (bit_counter + 1 <= 32) begin
            mdio_t <= 1'b0;
            mdio_o <= 1'b1;
            bit_counter <= bit_counter + 1;
        end
        else if (bit_counter + 1 <= 64) begin
            mdio_t <= 1'b0;
            mdio_o <= command1[bit_counter - 32];
            bit_counter <= bit_counter + 1;
        end
        else begin
            mdio_t <= 1'b1;
            mdio_o <= 1'b0;
            bit_counter <= 0;
            fsm_state <= GAP2; 
        end
    endrule

    rule r_gap2 if (fsm_state == GAP2);
        mdio_o <= 1'b0;
        mdio_t <= 1'b1;
        if (gap_counter + 1 <= 64) begin
            gap_counter <= gap_counter + 1;
        end
        else begin
            gap_counter <= 0;
            fsm_state <= COMMAND2;
            bit_counter <= 0;
        end
    endrule

    rule r_command2 if (fsm_state == COMMAND2);
        if (bit_counter + 1 <= 32) begin
            mdio_t <= 1'b0;
            mdio_o <= 1'b1;
            bit_counter <= bit_counter + 1;
        end
        else if (bit_counter + 1 <= 64) begin
            mdio_t <= 1'b0;
            mdio_o <= command2[bit_counter - 32];
            bit_counter <= bit_counter + 1;
        end
        else begin
            mdio_t <= 1'b1;
            mdio_o <= 1'b0;
            bit_counter <= 0;
            fsm_state <= GAP3; 
        end
    endrule

    rule r_gap3 if (fsm_state == GAP3);
        mdio_o <= 1'b0;
        mdio_t <= 1'b1;
        if (gap_counter + 1 <= 64) begin
            gap_counter <= gap_counter + 1;
        end
        else begin
            gap_counter <= 0;
            fsm_state <= COMMAND3;
            bit_counter <= 0;
        end
    endrule

    rule r_command3 if (fsm_state == COMMAND3);
        if (bit_counter + 1 <= 32) begin
            mdio_t <= 1'b0;
            mdio_o <= 1'b1;
            bit_counter <= bit_counter + 1;
        end
        else if (bit_counter + 1 <= 64) begin
            mdio_t <= 1'b0;
            mdio_o <= command3[bit_counter - 32];
            bit_counter <= bit_counter + 1;
        end
        else begin
            mdio_t <= 1'b1;
            mdio_o <= 1'b0;
            bit_counter <= 0;
            fsm_state <= DONE; 
        end
    endrule

    method Bit#(1) m_phy_mdio_o;
        return mdio_o;
    endmethod
    method Bit#(1) m_phy_mdio_t;
        return mdio_t;
    endmethod

endmodule


endpackage: Ethernet_IP_MDIO

// Ethernet_IP_TOP.sv


// Interface EthIPIfc
interface EthIPIfc;
    PhyRXIfc mii_phy_rx;
    MacRXIfc mac_rx;
    PhyTXIfc mii_phy_tx;
    MacTXIfc mac_tx;
endinterface

// Interface EthIPPhyIfc
interface EthIPPhyIfc;
    PhyRXIfc mii_phy_rx;
    PhyTXIfc mii_phy_tx;
endinterface

// RX Interface Module (assuming RXIfc exists as a module)
module RXIfc (
    input logic clk,
    input logic rst_n,
    input logic eth_mii_rx_clk,
    input logic eth_mii_rx_rstn,
    output PhyRXIfc phy,
    output MacRXIfc mac_rx
);
    // RX logic here
endmodule

// TX Interface Module (assuming TXIfc exists as a module)
module TXIfc (
    input logic clk,
    input logic rst_n,
    input logic eth_mii_tx_clk,
    input logic eth_mii_tx_rstn,
    output PhyTXIfc phy,
    output MacTXIfc mac_tx
);
    // TX logic here
endmodule

// Main Ethernet IP Module
module mkEthIP(
    input logic eth_mii_rx_clk,
    input logic eth_mii_tx_clk,
    input logic eth_mii_rx_rstn,
    input logic eth_mii_tx_rstn,
    EthIPIfc eth_ip_ifc
);

    // Core clock and reset
    logic core_clock;
    logic core_reset;

    assign core_clock = eth_mii_rx_clk;
    assign core_reset = ~eth_mii_rx_rstn;     // Active-low reset

    // Instantiating RX and TX blocks
    RXIfc rx_inst (
        .clk(core_clock),
        .rst_n(core_reset),
        .eth_mii_rx_clk(eth_mii_rx_clk),
        .eth_mii_rx_rstn(eth_mii_rx_rstn),
        .phy(eth_ip_ifc.mii_phy_rx),
        .mac_rx(eth_ip_ifc.mac_rx)
    );

    TXIfc tx_inst (
        .clk(core_clock),
        .rst_n(core_reset),
        .eth_mii_tx_clk(eth_mii_tx_clk),
        .eth_mii_tx_rstn(eth_mii_tx_rstn),
        .phy(eth_ip_ifc.mii_phy_tx),
        .mac_tx(eth_ip_ifc.mac_tx)
    );

endmodule



package Ethernet_IP;

import Ethernet_IP_TX::*;
import Ethernet_IP_RX::*;
import Ethernet_IP_Phy::*;

interface EthIPIfc;
    (* prefix="" *)
    interface PhyRXIfc mii_phy_rx;
    interface MacRXIfc mac_rx;
    (* prefix="" *) 
    interface PhyTXIfc mii_phy_tx;
    interface MacTXIfc mac_tx;
endinterface

interface EthIPPhyIfc;
    (* prefix="" *)
    interface PhyRXIfc mii_phy_rx;
    (* prefix="" *)
    interface PhyTXIfc mii_phy_tx;
endinterface

(*synthesize*)
module mkEthIP#(Clock eth_mii_rx_clk, Clock eth_mii_tx_clk, Reset eth_mii_rx_rstn, Reset eth_mii_tx_rstn) (EthIPIfc);

    let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;

    RXIfc rx <- mkEthIPRX(clocked_by core_clock, reset_by core_reset, eth_mii_rx_clk, eth_mii_rx_rstn);
    TXIfc tx <- mkEthIPTX(clocked_by core_clock, reset_by core_reset, eth_mii_tx_clk, eth_mii_tx_rstn);

    interface mii_phy_rx = rx.phy;
    interface mac_rx = rx.mac_rx;
    interface mii_phy_tx = tx.phy;
    interface mac_tx = tx.mac_tx;

endmodule


endpackage
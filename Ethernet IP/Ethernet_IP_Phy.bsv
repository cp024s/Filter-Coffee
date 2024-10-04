package Ethernet_IP_Phy;

import  Clocks::*;
import  FIFO::*;
import  FIFOF::*;

typedef struct {
    Bool valid;
    Bit#(4) data_nibble;
} ValidNibble deriving (Bits, FShow, Eq);

typedef struct {
    Bool valid;
    Bit#(8) data_byte;
} ValidByte deriving (Bits, FShow, Eq);






interface PhyRXIfc;
    (* always_ready, always_enabled, prefix="" *) 
    method Action m_phy_rx ((* port="eth_mii_rxd" *) Bit#(4) nibble,
                            (* port="eth_mii_rx_dv" *) Bool valid);
endinterface

interface EthIPRXPhyIfc;
    (* prefix="" *)
    interface PhyRXIfc phy;
    method ActionValue#(ValidNibble) get_data;
endinterface

// (*synthesize*)
module mkEthIPRXPhy#(Clock eth_mac_clock) (EthIPRXPhyIfc);

    let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;

    SyncFIFOIfc#(ValidNibble) data_fifo <- mkSyncFIFO(8, core_clock, core_reset, eth_mac_clock);    

    Wire#(ValidNibble) data <- mkWire;

    rule r_phy_rx;
        data_fifo.enq(data);
    endrule

    interface PhyRXIfc phy;
        method Action m_phy_rx (Bit#(4) nibble, Bool valid);
            ValidNibble temp = ValidNibble {
                data_nibble: nibble,
                valid: valid
            };
            data <= temp;
        endmethod
    endinterface
    
    method ActionValue#(ValidNibble) get_data;
        ValidNibble temp = data_fifo.first;    
        data_fifo.deq;
        return temp;
    endmethod
endmodule







interface PhyTXIfc;
    (* always_ready, result="eth_mii_txd" *) 
    method Bit#(4) m_phy_txd;

    (* always_ready, result="eth_mii_tx_en" *) 
    method Bool m_phy_tx_en;
endinterface

interface EthIPTXPhyIfc;
    (* prefix="" *)
    interface PhyTXIfc phy;
    method Action send_data (ValidNibble data);
endinterface

// (*synthesize*)
module mkEthIPTXPhy#(Clock eth_mac_clock, Reset eth_mac_rstn) (EthIPTXPhyIfc);

    let core_clock <- exposeCurrentClock;
    let core_reset <- exposeCurrentReset;

    SyncFIFOIfc#(ValidNibble) data_fifo <- mkSyncFIFO(8, eth_mac_clock, eth_mac_rstn, core_clock);    

    Wire#(Bit#(4)) nibble <- mkDWire(0);
    Wire#(Bool) valid <- mkDWire(False);

    rule r_phy_tx;
        nibble <= data_fifo.first.data_nibble;
        valid <= data_fifo.first.valid;
        data_fifo.deq;
    endrule

    interface PhyTXIfc phy;
        method Bit#(4) m_phy_txd;
            return nibble;
        endmethod
        method Bool m_phy_tx_en;
            return valid;
        endmethod
    endinterface
    
    method Action send_data (ValidNibble data);
        data_fifo.enq(data);        
    endmethod
endmodule


endpackage: Ethernet_IP_Phy
Chapter 9 of the AXI 1G/2.5G Ethernet Subsystem v7.2 Product Guide, titled **"Upgrading,"** provides guidance on migrating and upgrading the AXI Ethernet Subsystem design within AMD’s Vivado Design Suite. This chapter outlines changes in interface ports and functionality across versions, offering support for both migration from ISE and upgrades within Vivado.

---

### **1. Migrating to the Vivado Design Suite**

- This section is relevant for users moving from AMD’s ISE Design Suite to the Vivado Design Suite.
- Referencing the **ISE to Vivado Design Suite Migration Guide (UG911)**, it details migration steps, interface adjustments, and IP support changes between the design tools.

### **2. Upgrading in the Vivado Design Suite**

When upgrading to a newer version of the AXI Ethernet Subsystem in Vivado, there are often changes to ports, parameters, or required connections. The guide summarizes such updates, specifying any actions needed to maintain compatibility with existing user logic. 

#### **Changes from Version 7.1 to 7.2**
- **Added Support for AMD Versal Devices**: Versal devices are supported in the latest version, enhancing flexibility and performance options.
- **Dynamic Switching Support**: Added dynamic switching capability between **1000BASE-X** and **SGMII** modes, enabling seamless transitions without reconfiguration.

#### **Changes from Version 7.0 to 7.1**
- **gt_powergood Port Addition**: This new port indicates when the **gtrefclk** (transceiver reference clock) is stable and ready. It’s especially useful in designs where gtrefclk is used for multiple applications. The **gtwizard** user guide provides more details on this feature.

#### **Changes from Version 5.0 to 6.0**
- **Port Renaming for AXI4-Stream Interfaces**: Several key ports were renamed to align with Vivado’s AXI4-Stream conventions:
  - `axi_str_txc` renamed to `s_axis_txc` (Transmit Control).
  - `axi_str_txd` renamed to `s_axis_txd` (Transmit Data).
  - `axi_str_rxd` renamed to `m_axis_rxd` (Receive Data).
  - `axi_str_rxs` renamed to `m_axis_rxs` (Receive Status).
- **AVB-Specific Ports**: The following ports were updated to support Audio Video Bridging (AVB) mode:
  - `axi_str_avb_tx` renamed to `s_axis_tx_av` for AVB transmit.
  - `axi_str_avb_rx` renamed to `m_axis_rx_av` for AVB receive.

#### **Changes from Version 4.0 to 5.0**
- **sgmii and sfp Interface Adjustments**: In SGMII mode, the serial interface ports (`txp`, `txn`, `rxp`, `rxn`) were standardized as `sgmii`. In 1000BASE-X mode, these ports connect to an SFP cage labeled `sfp`, facilitating a clean external interface configuration.
- **Clock Input Adjustments**: For improved clarity and compatibility, the `refclk` input was renamed to `ref_clk` to match Vivado clocking terminology and updated usage guidelines for RGMII, 1000BASE-X, and SGMII modes.

---

### **3. Summary of Actions for Upgrades**

For each version change, the guide emphasizes:
- **Port Mapping and Renaming**: Ensure updated connections between user logic and renamed ports.
- **Parameter Adjustments**: Review parameter changes as these are often handled automatically in Vivado but may impact functionality.
- **Device-Specific Adaptations**: When upgrading to newer hardware families like Versal, re-evaluate clock, transceiver, and I/O configurations to utilize additional device features effectively.

---

This chapter provides a structured approach to migrating and upgrading the AXI Ethernet Subsystem, ensuring compatibility and optimizing performance with the latest versions in Vivado

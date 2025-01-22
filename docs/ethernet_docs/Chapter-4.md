Chapter 4 of the AXI 1G/2.5G Ethernet Subsystem v7.2 Product Guide, titled **"Designing with the Subsystem,"** provides guidance on using the subsystem effectively within FPGA designs. Here is a detailed summary:

---

### **1. Design Guidelines**

#### **Customization and Generation**
- The AXI Ethernet Subsystem can be customized in Vivado's IP integrator by adjusting various parameters. Parameters that aren’t valid or allowed in specific configurations are grayed out to prevent modifications. This includes setting up options like **checksum offloading**, **VLAN processing**, **PHY type selection**, and **buffer settings**.

#### **Hierarchical Block Analysis**
- The subsystem's HDL includes automatically generated logic. Users should verify the HDL, particularly the instantiation of MDIO IOBUF (for PHY management), address space allocation, and the clocks required for the specific mode of operation.
- It’s recommended to review the IP integrator's Address editor to ensure the required 256K address range is reserved.

#### **Clocking and Reset Considerations**
- Proper clocking is crucial. The guide details the required clock configurations for each PHY type. For GMII designs, for example, the **BUFGMUX** switches between MII_TX_CLK and GTX_CLK, allowing the design to operate at both 10/100 Mbps and 1 Gbps. For 1000BASE-X or SGMII, reference clocks of 125 MHz, 156.25 MHz, or 250 MHz are required.
- Ensure that reset signals are managed appropriately to avoid build errors and maintain data integrity.

### **2. Important Design Practices**

#### **Signal Registration**
- To simplify timing and improve system performance, it’s recommended to keep inputs and outputs registered at the boundaries between the user application and the subsystem. Registering signals can make timing analysis and routing easier for the Vivado tools.

#### **Identifying Critical Timing Paths**
- The documentation includes timing constraints for critical paths, particularly those that involve high-speed data transfers or specific infrastructure cores.

#### **Modification Restrictions**
- Modifications outside of Vivado’s allowed parameters can disrupt system timing or protocol compliance, especially for built-in cores and critical paths. Users should use only the customization options provided by Vivado to avoid unsupported modifications.

### **3. AXI4-Stream Interface**

#### **Transmit and Receive Interfaces**
- The AXI4-Stream interface transfers Ethernet frames between the subsystem and external logic. Both the **transmit** and **receive** interfaces provide control and data paths, with the subsystem controlling ready/valid handshakes and flagging errors where necessary.
- The interface is compatible with external cores like AXI_DMA, which can manage buffer descriptors and facilitate data transfers at high speeds.

#### **Throttling and Dual Channel Support**
- The subsystem supports throttling on the AXI4-Stream Status and Data buses, particularly useful in applications where the external system might experience delays or require controlled data flows. Dual-channel support enables separate streams for **data** and **status** in configurations like AVB (Audio Video Bridging) applications.

#### **Ethernet AVB Support**
- For AVB applications, the subsystem’s AVB AXI4-Stream interface includes transmit and receive buses. It is a limited interface without throttling support and requires continuous readiness from the external logic during transfers. The AVB mode enforces frame prioritization and time-slotting based on AVB standardsuffer Mapping and Checksum Offloading**

#### **DMA Buffer Descriptor Integration**
- The AXI DMA core’s buffer descriptors in external memory are mapped to AXI4-Stream fields for packet data management. These descriptors include fields for **control**, **status**, **buffer addresses**, and **application-specific words** (e.g., checksum control/status), allowing efficient integration with the AXI Ethernet Subsystem.
  
#### **Checksum Offloading**
- TCP/IP checksum offloading support enables the subsystem to handle partial and full checksum calculations in hardware, offloading processing tasks from the CPU. The specific control/status words for checksum offloading are detailed, supporting integration with AXI_DMA IP for streamlined packet handling.

---

This chapter provides in-depth information on configuring, managing, and utilizing the AXI Ethernet Subsystem for high-performance Ethernet applications in FPGAs, especially those requiring careful clocking, signal management, and adherence to timing constraints   .

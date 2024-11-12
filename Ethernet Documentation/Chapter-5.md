## <p align = center> Chapter 5 </p>

### **1. Customizing and Generating the Subsystem**

This section covers steps for customizing the AXI Ethernet Subsystem in Vivado IP Integrator:

#### **Adding the Subsystem to a Vivado Design**
- In Vivado’s IP Integrator, create a new block design and add the AXI Ethernet Subsystem from the IP catalog.
- Customization happens through a graphical interface in Vivado, where each configuration tab provides options for fine-tuning the subsystem.

#### **Configuration Tabs Overview**

1. **Board Tab**:
   - For supported boards, enables board-specific constraints like pin assignments for Ethernet interfaces.
   - This setting may be unavailable for certain devices (e.g., Versal), where manual constraint management is required.

2. **Physical Interface Tab**:
   - Selects **Ethernet speed** (1G or 2.5G).
   - Configures the **PHY interface type** (MII, GMII, RGMII, SGMII, or 1000BASE-X).
   - Sets the **GT reference clock frequency**, typically required for high-speed interfaces like SGMII and 1000BASE-X. Ensure that the clock frequency aligns with the requirements of the selected PHY interface.

3. **MAC Features Tab**:
   - Enables or disables **checksum offloading** for TCP and UDP, which can enhance data transfer speeds by offloading the checksum computation from the CPU to the subsystem.
   - **VLAN Options**: Configure VLAN support to allow for VLAN-tagged frames, with options for stripping and tagging.
   - **Flow Control**: Configures pause frame support, allowing the subsystem to manage data flow and prevent buffer overflows during heavy network traffic.
   - **Processor Mode**: Selects the data handling mode, where disabling this mode connects the ports directly to the TEMAC and PCS/PMA cores without an intermediary buffer.

4. **Network Timing Tab**:
   - **IEEE 1588 Precision Time Protocol (PTP)**: Configure options for timestamping using 1-step or 2-step synchronization methods, required for applications needing precise network time synchronization.
   - **AVB (Audio Video Bridging) Mode**: Enables features to prioritize multimedia traffic, important in low-latency and high-reliability applications like audio and video streaming.

5. **Shared Logic Tab**:
   - Defines whether **shared logic resources** (e.g., MDIO, clocking logic) are part of the subsystem or should be instantiated separately. Choosing "Include Shared Logic" can simplify integration, but some applications may benefit from a standalone instantiation, especially when multiple instances of the subsystem are present.

6. **OOC (Out-of-Context) Settings Tab**:
   - Allows setting specific **clock frequencies** and configurations for scenarios when the subsystem is synthesized out-of-context. This approach is useful in modular designs where individual subsystems are synthesized independently before full integration.

---

### **2. Constraining the Subsystem**

Setting up constraints is essential for ensuring proper timing, signal integrity, and compatibility with different PHY interfaces. Here’s a detailed look:

#### **Clocking Constraints**
- **PHY-Specific Clocking**: Each PHY interface type (MII, GMII, RGMII, SGMII, and 1000BASE-X) requires specific clocking settings.
   - For example, **GMII** requires a 125 MHz clock for gigabit speeds, while **MII** can use a lower frequency of 25 MHz or 2.5 MHz for 100 Mbps and 10 Mbps, respectively.
   - **RGMII** requires double data rate clocking, allowing both 1 Gbps and lower speeds, typically achieved with a BUFGMUX for clock switching.
   - **SGMII and 1000BASE-X** interfaces require stable, high-speed reference clocks, typically 125 MHz, but can vary based on device.

#### **Reset Constraints**
- Ensure all **reset signals** are synchronized to the appropriate clock domains. Reset signals are critical to initializing the subsystem correctly and preventing timing violations.
- Proper synchronization of resets prevents incorrect subsystem operation, especially in designs using multiple clock domains.

#### **Shared Resources in Multi-Instance Designs**
- When using multiple Ethernet subsystem instances, shared resources like the IDELAYCTRL block (for RGMII) can reduce resource utilization by enabling multiple instances to share the same clock and reset circuitry.
- For configurations involving GT-based PHY interfaces (SGMII or 1000BASE-X), multiple instances can share a **GT Quad Base** resource, provided they operate on compatible configurations.

### **3. Simulation**

This section guides the simulation requirements and resources for testing the AXI Ethernet Subsystem design.

#### **Simulation Models**
- **Supported Libraries**: The subsystem supports the **UNISIM library** for simulation, required for Zynq and 7-series devices. However, **UNIFAST libraries** are not compatible with these devices.
- **Example Design Simulation**: The product guide includes an example design with a basic test bench, useful for verifying subsystem functionality. However, additional setup may be required for specific configurations, such as IEEE 1588 timestamping or AVB support.

#### **Simulation Workflow**
- Simulation begins by initializing the design with proper clock and reset signals, then verifying basic functionality (e.g., packet transmission and reception).
- For designs with AVB or IEEE 1588 configurations, the simulation must account for specific timing requirements, including accurate timestamp generation and AVB priority management.

---

### **4. Synthesis and Implementation**

This section provides best practices for synthesizing and implementing the AXI Ethernet Subsystem in the Vivado environment.

#### **Synthesis**
- **Standard Synthesis Flow**: Use Vivado’s synthesis tools to translate RTL to gate-level implementation. The subsystem automatically applies required constraints for sub-cores, ensuring compliance with Ethernet timing and protocol standards.
- **Resource Optimization**: During synthesis, choose optimizations that balance performance with resource usage. For instance, when checksum offloading is enabled, additional FPGA resources may be required, but system performance is enhanced.

#### **Implementation**
- **Timing Closure**: Implementation includes placing and routing the design to meet timing constraints, especially critical for high-speed PHYs like SGMII and 1000BASE-X. Review timing reports and apply floorplanning as needed.
- **Device-Specific Constraints**: For certain configurations, device-specific constraints may be necessary to ensure stable operation. For example, Zynq devices may require additional routing constraints to maintain performance in high-speed applications.
- **Verification of Generated Bitstream**: Once implementation is complete, generate the bitstream and verify functionality on hardware, particularly focusing on correct data transmission, reset functionality, and proper handling of the selected Ethernet protocols.

### **Additional Design Flow Steps**

#### **Debugging with Integrated Logic Analyzer (ILA)**
- The Integrated Logic Analyzer (ILA) core in Vivado allows users to monitor real-time Ethernet traffic, capturing data from key points within the AXI Ethernet Subsystem. This is especially useful for debugging and ensuring correct packet transmission and reception.

#### **Using Constraints Files**
- Constraint files generated or specified within Vivado ensure that all interface standards, clocking, and resets meet the Ethernet protocol requirements.
- For multiple Ethernet instances, additional constraints may be needed to avoid resource conflicts and ensure that shared logic is optimally allocated.

---

This chapter serves as a comprehensive guide to setting up, verifying, and implementing the AXI Ethernet Subsystem, covering essential aspects from customization to synthesis and debugging. Each step is designed to ensure smooth integration of high-speed Ethernet functionality into FPGA designs while optimizing performance and resource usage. Let me know if you need any further details on a specific section!

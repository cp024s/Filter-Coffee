## <p align = center> Chapter 6 - Example Design </p>

### in the AXI 1G/2.5G Ethernet Subsystem v7.2 Product Guide provides information on a pre-built design example. This chapter details the design’s components, operational setup, and how it is tailored for specific FPGA boards, such as the KC705 and KCU105 evaluation kits.

---

### **1. Overview of the Example Design**

- **Purpose**: This example demonstrates basic functionality by initializing the Ethernet subsystem, enabling frame transfers, and using a state machine to control the Ethernet PHY and MAC.
- **Target Boards**: Primarily designed for the AMD Kintex 7 FPGA KC705 Evaluation Kit. A variant exists for the Kintex UltraScale KCU105, with unique configurations for each board’s interface and clock requirements.

---

### **2. Components of the Example Design**

The example design includes various elements configured to enable Ethernet frame transmission and reception:

1. **AXI Ethernet Subsystem Instance**: This serves as the core IP for the example.
2. **Clock Management**: Includes MMCM (Mixed-Mode Clock Manager) and Global Clock Buffers for clock generation, essential for supporting multiple Ethernet modes.
3. **Ethernet PHY Interface Logic**: Configurations for different PHY types, such as MII, GMII, RGMII, SGMII, or 1000BASE-X, include appropriate Input/Output Buffers (IOBs) and DDR registers.
4. **Transmit and Receive FIFOs**: The TX and RX FIFOs operate on AXI4-Stream interfaces, facilitating data transfer between user logic and the subsystem.
5. **Pattern Generator and Checker**: Implements a basic pattern generator for data transmission and a checker for verifying received data. Optional **loopback functionality** allows RX-to-TX or PHY-based loopback.
6. **AVB Pattern Generator and Checker**: Supports the Audio Video Bridging (AVB) endpoint if enabled.
7. **Control State Machine**: A simple state machine that uses the AXI4-Lite interface for bringing up the PHY and Ethernet MAC.

---

### **3. Key Functional Modules**

#### **Pattern Generator and Checker**
- **Pattern Generator**: Generates Ethernet frames with configurable source/destination addresses, minimum/maximum frame sizes, and incremental frame size progression.
- **Pattern Checker**: Verifies that received frames match the expected format and data. If errors occur, it triggers an LED signal for troubleshooting.

#### **FIFO Components**
- **TX Client FIFO**: Provides a dual-port RAM buffer of 4,096 bytes for data transmission, with mechanisms to prevent overflow and ensure data is read at an appropriate rate.
- **RX Client FIFO**: Similar in structure, with overflow management to handle high-speed data and prevent frame loss.

#### **Address Swap Module**
- In loopback mode, this module swaps source and destination MAC addresses to ensure that frames return to the transmitting device. The module is primarily used in scenarios with Ethernet testers.

---

### **4. Board-Specific Details**

The design is tailored to work seamlessly on specific evaluation boards, with unique configurations for each:

1. **KC705 Board**
   - **LED Indicators**: LEDs show activity and errors during frame transmission and reception.
   - **Push Buttons and DIP Switches**: Enable bit rate adjustments, system reset, and loopback mode changes.
2. **KCU105 Board**
   - Uses **SGMII over LVDS** mode, relying on a 625 MHz MGT clock from the on-board PHY.
   - Unique reset configurations are required to prevent potential deadlocks in the PHY reset state.

---

### **5. Bring-Up Sequence**

To ensure proper functionality on the target boards, specific bring-up steps are recommended:
- Verify board jumper settings and clock source configurations.
- For SGMII or 1000BASE-X modes, connect an SFP with PHY or loopback as needed.

### **6. Using the Example Design**

The example design serves as a foundation for implementing and testing Ethernet functionality in FPGA projects. By providing a configurable, ready-to-run environment, this design enables rapid prototyping and validation of Ethernet-based applications on FPGA platforms

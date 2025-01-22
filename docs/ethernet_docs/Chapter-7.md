Chapter 7 of the AXI 1G/2.5G Ethernet Subsystem v7.2 Product Guide, titled **"Test Bench,"** describes the provided test bench, its operation modes, and customization options. Here is an in-depth breakdown:

---

### **1. Overview of Test Bench Functionality**

The test bench, implemented in `demo_tb.v`, is a Verilog-based simulation environment designed to validate the functionality of the AXI Ethernet Subsystem and its example design. It operates in two main modes:
- **DEMO Mode**: Emulates data transmission through the Ethernet subsystem, testing various frame types and verifying correct behavior.
- **Built-in Self-Test (BIST) Mode**: Provides a loopback environment to perform extensive self-checking, including throughput and error reporting.

BIST mode is set as the default for testing.

### **2. Components of the Test Bench**

The test bench includes multiple component blocks, each designed to exercise or monitor specific parts of the Ethernet subsystem:

1. **Clock Generators**: Provides input clock signals required for subsystem operation.
2. **DEMO (Stimulus Block)**: This block feeds the PHY-side receiver interface with data frames, supporting MII, GMII, RGMII, SGMII, and SFP/1000BASE-X interfaces.
3. **DEMO (Monitor Block)**: Verifies data returning through the PHY-side transmitter interface, checking for frame integrity.
4. **Frame Filter**: Filters frames by checking the destination (DA) and source (SA) address fields in each frame.
5. **Loopback for BIST**: In BIST mode, the loopback feature enables frames transmitted from the PHY-side interface to loop back to the receiver.
6. **AVB Data Bandwidth Monitor** (optional for AVB-enabled subsystems): Monitors the bandwidth of two data streams in BIST mode.
7. **Speed Selection Control Block**: Manages Ethernet MAC bit rate settings.
8. **MDIO Monitor/Stimulus**: Simulates MDIO accesses, emulating a PHY-less environment by responding with all 1s during reads.

---

### **3. DEMO Mode Operation**

DEMO mode performs a series of test steps designed to emulate various operational scenarios:

1. **Clock and Reset Initialization**: Generates the necessary clocks and initializes reset signals.
2. **Speed Selection**: Configures the Ethernet MAC to operate at the highest supported bit rate.
3. **MDIO Response**: Responds to MDIO reads with all 1s, simulating the absence of a connected PHY.
4. **Frame Transmission**: Four distinct frames are sent to the PHY-side receiver interface:
   - **Minimum-Length Frame**: Tests basic transmission.
   - **Type Frame**: Sends a frame with a specified Ethernet type.
   - **Errored Frame**: Simulates an erroneous frame to validate error detection.
   - **Padded Frame**: Tests handling of padded Ethernet frames.

5. **Frame Verification**: The monitor block checks that received frames match the transmitted frames, considering DA/SA fields and Frame Check Sequence (FCS) modifications from the address swap module.
6. **Speed Update**: The design is updated to the next supported bit rate, and the MDIO response is repeated.
7. **Repetition of Steps**: The above steps are repeated for all supported bit rates, validating performance across different configurations.

#### **Frame Filtering in DEMO Mode**
- A fifth frame is transmitted with a mismatched DA/SA field to test the address filtering capability.
- If a mismatch occurs between the DA/SA of the incoming frame and the predefined filter settings in the AXI4-Lite state machine, the frame is dropped. By default, only this fifth frame is dropped due to this mismatch.

---

### **4. BIST Mode Operation**

BIST mode performs continuous data validation using loopback and extensive error reporting:

1. **Clock and Reset Setup**: Initializes the necessary clocks and resets.
2. **Speed Configuration**: Sets the Ethernet MAC to the selected bit rate.
3. **MDIO Response**: Similar to DEMO mode, the MDIO monitor responds with all 1s.
4. **Pattern Generator and Checker Activation**: Enables pattern generation and verification blocks to test frame integrity.
5. **Extended Run**: The simulation runs for a fixed period, allowing numerous frames to pass through the loopback path.
6. **Error Detection and Reporting**: Any observed errors or lack of RX activity is flagged, providing a self-checking environment.
7. **Bandwidth Monitoring for AVB**: If AVB is enabled, the system reports the data bandwidth for two data streams, ensuring compliance with AVB standards.

### **5. Customizing the Test Bench**

The test bench offers configuration flexibility:

- **Mode Selection**: The test bench mode (DEMO or BIST) can be changed by setting the `TB_MODE` parameter in the `demo_tb.v` file. This allows users to quickly switch between the two testing modes.
- **Modifying Frame Data**: Frame data for the TEMAC receiver can be modified by updating the `DATA` fields within the test bench. The test bench recalculates the FCS automatically.
- **Error Insertion**: Errors can be introduced by setting the error field to `1` for any frame. This disables monitoring for that frame, allowing custom error scenarios. The error flag for the default errored frame (third frame) can be cleared by resetting all error fields for that frame.

### **6. BIST Mode Frame Generation Controls**

In BIST mode, the pattern generator offers control over generated frames using parameters such as:
- **DEST_ADDR and SRC_ADDR**: Sets destination and source MAC addresses for generated frames.
- **MAX_SIZE and MIN_SIZE**: Controls the maximum and minimum frame size.
- **VLAN_ID and VLAN_PRIORITY**: Sets VLAN parameters for tagged frames.

This configuration provides a high degree of control over generated frames, allowing tailored testing for diverse network scenarios.

---

Chapter 7 provides an extensive testing framework, including loopback and error checking, making it a valuable tool for verifying the AXI Ethernet Subsystem's functionality before implementation

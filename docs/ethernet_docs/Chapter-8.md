Chapter 8 of the AXI 1G/2.5G Ethernet Subsystem v7.2 Product Guide, titled **"IEEE 1588 Timestamping,"** provides an overview of the subsystem’s support for IEEE 1588 Precision Time Protocol (PTP), which enables highly accurate timestamping for Ethernet frames. This is critical in applications that require precise time synchronization across networked systems, such as industrial automation and telecommunications. Here’s a detailed breakdown:

---

### **1. Configuring the Subsystem for IEEE 1588 Support**

To enable IEEE 1588 hardware timestamping, configure the subsystem within the Vivado IDE:
1. **Select the Physical Interface**: In the Physical Interface tab, choose either **1000BASE-X** or **SGMII**.
2. **Enable 1588 Option**: Within the Network Timing tab, check the **Enable 1588** option.
3. **Timestamping Options**: Choose between **1-step** and **2-step** support:
   - **1-step** involves capturing and inserting the timestamp directly into the frame.
   - **2-step** provides a separate timestamp for client-side processing.
4. **Timer Format Selection**: Decide on the timestamp format:
   - **Time-of-Day (ToD)** format includes 48-bit seconds and 32-bit nanoseconds.
   - **Correction Field Format** is used specifically for PTP with an embedded correction field.
5. **Set System Timer Period**: Enter the clock period (in picoseconds) for the **1588 System Timer** to ensure synchronization accuracy.

### **2. Supported Features and Interfaces**

#### **Supported Frame Types**
The subsystem supports the following frame types for IEEE 1588 timestamping:
- **Transmit 1-step**: Raw Ethernet, UDP IPv4, and UDP IPv6 frames.
- **Transmit 2-step and Receive**: All PTP frame formats are supported.

#### **Timestamp Accuracy**
The timestamping accuracy is better than ±10 nanoseconds across supported devices and operating conditions, enabling precise synchronization.

#### **Devices and PHY Compatibility**
IEEE 1588 is supported on specific devices, including:
- AMD 7 series (GTX and GTH), UltraScale, UltraScale+ (GTH, GTY), and Versal transceivers (GTY, GTYP).
- PHY compatibility includes **1000BASE-X** and **SGMII** configurations, ensuring broad compatibility with industry-standard Ethernet speeds.

### **3. Architecture Overview**

#### **Transmitter Path**

For outgoing frames, the transmitter architecture integrates timestamping capabilities directly within the Ethernet MAC and PHY layers:
- **Command Field**: A client-specified command field is used to define timestamp actions per frame, such as no operation, 1-step or 2-step.
- **Timestamp Insertion**:
  - **1-Step Mode**: The timestamp is embedded in the frame based on an offset defined in the command field, recalculating the Ethernet Frame Check Sequence (FCS) and UDP checksum as needed.
  - **2-Step Mode**: The frame remains unchanged, and the timestamp is passed separately to the client for further handling.

**Latency Adjustments**: The system includes built-in latency adjustments to account for fixed transmission delays through the MAC, PCS, and GTX transceiver, ensuring accurate timestamps at the frame’s Start-of-Frame Delimiter (SFD).

#### **Receiver Path**

For incoming frames, the receiver captures timestamps with precise alignment to the frame’s arrival:
- **80-bit ToD Timestamp**: An 80-bit timestamp (48-bit seconds, 32-bit nanoseconds) is provided out-of-band for all received frames, along with an optional 64-bit in-line timestamp.
- **Latency Adjustment**: Adjustments are made to account for fixed latencies in the receiver path, aligning timestamps with the physical arrival time of the frame.

### **4. Frame-by-Frame Timestamp Operation**

The IEEE 1588 timestamping operates on a frame-by-frame basis:
- **Command Field Definition**: Specifies the timestamping mode (no operation, 1-step, or 2-step), as well as parameters like the **Timestamp Offset** and **Checksum Offset**.
- **UDP Checksum Update**: For 1-step UDP frames, the subsystem recalculates the UDP checksum in line with the inserted timestamp, ensuring compatibility with RFC 1624.
- **Correction Field Handling**: For the Correction Field format, a 64-bit correction value is added to existing timestamps, adjusting for network delays within the PTP frame format.

### **5. Interface Ports for IEEE 1588**

The IEEE 1588 mode introduces several key ports:
- **Transmit Timestamp Ports**: Provides out-of-band timestamp data for transmitted frames, with a 128-bit data field covering timestamp and tag information.
- **Receive Timestamp Ports**: Allows access to the 80-bit ToD timestamp or 64-bit correction field timestamp out-of-band.
- **System Timer Ports**: Includes `systemtimer_s_field` for seconds and `systemtimer_ns_field` for nanoseconds, supporting a high-precision clock.

### **6. Latency Values**

Simulation and theoretical latency values are provided for both the transmit and receive paths to help in latency compensation:
- **Transmit Path Latency**: Accounts for MAC, PCS, and GTX components, yielding a latency of approximately 189–196 ns.
- **Receive Path Latency**: Accounts for MAC and PCS delays along with GTX transceiver latency, typically around 209–177 ns.

---

This chapter provides essential information on configuring IEEE 1588 timestamping for precise synchronization in Ethernet-based systems, covering the detailed setup, interface specifications, and operational latency adjustments needed for implementing the AXI Ethernet Subsystem with IEEE 1588 functionality

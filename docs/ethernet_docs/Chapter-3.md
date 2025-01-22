## <p align = center> Chapter 3 </p>
### **1. Functional Description**

#### **High-Level Architecture**
- The AXI Ethernet Subsystem comprises several key components:
  - **Tri-Mode Ethernet MAC (TEMAC)**: Supports 10/100/1000 Mbps speeds.
  - **Gigabit PCS/PMA**: Used for physical layer encoding and decoding, necessary for SGMII and 1000BASE-X interfaces.
  - **AXI Ethernet Buffer**: Manages packet buffering and includes optional features like TCP/UDP checksum offloading, VLAN tagging/stripping, and multicast filtering.
  - **AVB Core**: Optional component for Ethernet Audio Video Bridging, which prioritizes traffic based on IEEE 802.1 standards.
  - **Timer Sync Core**: Provides IEEE 1588 timestamping capabilities, required for Precision Time Protocol applications.
  
#### **PHY Interfaces Supported**
- **GMII/MII/RGMII**: Standard media-independent interfaces allowing connection with Ethernet PHY devices at various speeds (10/100/1000 Mbps).
- **SGMII/1000BASE-X**: Enables high-speed (1G/2.5G) serial connections directly to an external SFP module or Ethernet PHY.

#### **AXI Interfaces**
- **AXI4-Lite Interface**: A 32-bit control interface that allows register access for configuration and management.
- **AXI4-Stream Interface**: Handles Ethernet data transmission and reception, compatible with AXI DMA and MCDMA cores for efficient data movement in systems requiring high throughput.

### **2. Standards**

The subsystem complies with various Ethernet and IEEE standards:
- **IEEE 802.3**: General compliance for Ethernet MAC/PHY functions.
- **IEEE 1588**: Supports hardware timestamping for precise clock synchronization in networked devices.
- **IEEE 802.1Q**: VLAN tagging to segregate network traffic.
- **IEEE 802.1AS/802.1Qav**: AVB standards for clock synchronization and traffic shaping, respectively.

### **3. Performance**

#### **Frame Processing and Throughput**
- The subsystem can handle frames at speeds up to 2.5G in compliant devices, making it suitable for high-performance applications.
- Frame processing is further optimized through optional hardware offloading for TCP/UDP checksum calculations, which can significantly reduce CPU overhead for large data transfers.

### **4. Resource Utilization**

The guide provides specific FPGA utilization figures for the AXI Ethernet Subsystem. Resources considered include:
- **Logic and DSP Blocks**: Amount of FPGA logic and DSP slices used based on configuration.
- **Memory Utilization**: The subsystem’s buffer memory requirements for transmitting and receiving Ethernet frames.
- **Clocking**: Describes how the design relies on certain clock domains, which vary based on the configured PHY interface and the need for timing synchronization (e.g., IEEE 1588).

### **5. Port Descriptions**

Each subsystem port serves a specific function. Key ports include:
- **s_axi (AXI4-Lite control interface)**: Manages register reads/writes.
- **s_axis_txc and s_axis_txd (Transmit data/control interface)**: Sends data to the subsystem for transmission.
- **m_axis_rxd and m_axis_rxs (Receive data/status interface)**: Receives data and status signals from the subsystem.
- **gt_clk and mgt_clk**: Required for SGMII/1000BASE-X clocking.
- **Ethernet Interface Ports**: Specific for each PHY interface (e.g., GMII, SGMII), these ports handle the low-level transmission and reception of Ethernet frames.

### **6. Register Space**

#### **Control and Configuration Registers**
- **TEMAC Control Registers**: Allow configuration of TEMAC-specific options like flow control, duplex mode, and pause frame settings.
- **Checksum Offload Control Registers**: Configures partial and full checksum offload for both transmit and receive paths.
- **VLAN Registers**: Enable VLAN support and configure VLAN tags for filtering or forwarding.
- **Address Filtering Registers**: Used to define and enable specific MAC addresses (unicast, multicast, and broadcast) for filtering incoming frames.
- **Interrupt Status and Control Registers**: Manage interrupts for various events, like frame reception or transmission completion, error conditions, etc.
  
#### **Addressing and Mapping**
- **Checksum and Offload Parameters**: Configurable checksum parameters, such as start and end offsets, are managed through dedicated registers for hardware offloading.

### **Detailed Functionalities**

#### **Partial and Full TCP/UDP Checksum Offload**
- For high-speed applications, the subsystem supports offloading checksum calculations for TCP and UDP packets.
  - **Partial Checksum Offload**: Allows certain parts of the checksum computation to be handled by hardware, reducing CPU load.
  - **Full Checksum Offload**: Hardware calculates the entire checksum, further reducing CPU load and enhancing data throughput.

#### **VLAN and Jumbo Frame Support**
- **VLAN Processing**: Supports VLAN tagging and stripping, configurable through the control registers.
- **Jumbo Frames**: Enables transmission and reception of frames up to 16 KB, beyond the standard Ethernet frame size.

#### **Frame Transmission and Reception Control**
- **Frame Padding and FCS Control**: Configurable frame padding to meet minimum frame size requirements, with options to insert or pass through the Frame Check Sequence (FCS).
- **Error Handling**: Frames with errors (e.g., incorrect FCS) are dropped, and the status is reported through interrupts.

#### **Address Filtering**
- The subsystem includes programmable address filtering:
  - **Unicast and Multicast Address Matching**: Matches frames against predefined unicast or multicast addresses.
  - **Promiscuous Mode**: Allows the subsystem to pass all frames to higher layers, useful for monitoring or debugging.

#### **Flow Control**
- Implements IEEE 802.3 pause frames, which control the data flow in situations where the receiver cannot handle incoming data rates.
  - **Pause Frame Transmission**: The subsystem can generate pause frames to signal the sender to temporarily stop transmission.
  - **Pause Frame Reception**: Configurable to honor incoming pause frames and halt transmissions accordingly.

### **Usage Considerations**

The AXI Ethernet Subsystem’s functionality can be customized to fit a variety of applications, from low-latency streaming to AVB-compliant systems. This chapter gives essential information for balancing performance, resource usage, and compatibility with specific Ethernet protocols and interfaces.

--- 

This comprehensive summary should cover the essential details found in Chapter 3 of the product guide. If you need further explanations on any section or additional details, let me know!

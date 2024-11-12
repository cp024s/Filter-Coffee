# <p align = center> AXI 1G/2.5G Ethernet Subsystem v7.2 Documentation </p>

## Chapter 1: [Introduction](https://github.com/ChandraPrakash024/Filter-Coffee/blob/cp024s-patch-2/Ethernet%20Documentation/Chapter-1)

The **AXI 1G/2.5G Ethernet Subsystem** is a flexible Ethernet solution supporting both 1G and 2.5G Ethernet configurations. Designed for AMD FPGAs and SoCs, this subsystem can implement multiple Ethernet protocols and PHY interfaces.

### Key Features
- **Tri-Mode Ethernet MAC**: Operates at speeds of 10 Mb/s, 100 Mb/s, and 1 Gb/s, with support for MII, GMII, RGMII, SGMII, and 1000BASE-X interfaces.
- **Checksum Offloading**: Supports TCP/UDP full or partial checksum offloading in hardware, which reduces processor workload.
- **VLAN and AVB Support**: Includes options for VLAN tagging, stripping, and translating, along with support for Ethernet Audio Video Bridging (AVB).
- **Precision Timing**: Supports IEEE 1588 PTP with hardware timestamping for accurate synchronization.

![](https://github.com/ChandraPrakash024/Filter-Coffee/blob/cp024s-patch-2/Ethernet%20Documentation/Assets/IPv4.png)

### Licensing
- Provided with the Vivado Design Suite, although certain features like AVB require additional licenses. The Tri-Mode Ethernet MAC (TEMAC) IP core also has specific licensing details available in PG051.

---

## Chapter 2: [Overview](https://github.com/ChandraPrakash024/Filter-Coffee/blob/cp024s-patch-2/Ethernet%20Documentation/Chapter-2)

### Integration in Vivado
The AXI Ethernet Subsystem is designed to be used within the Vivado IP Integrator for streamlined integration into an FPGA design. Users can add the subsystem directly from the IP catalog, allowing for parameter customization and connection to other system components.

### Features Summary
- **Design Flexibility**: The subsystem includes various features like full-duplex support, IEEE 1588 timestamping, jumbo frames up to 16 KB, and flow control.
- **Interface Options**: Configurable to use various PHY interfaces, allowing compatibility with a range of networking configurations.
- **Design Process Assistance**: AMD provides a design process flow to guide users through hardware, IP, and platform development, with specific sections covering port descriptions, register space, and customization steps.

### Recommended Use
Users are advised to configure the subsystem according to the intended Ethernet speed and PHY requirements to ensure compatibility and efficient performance.

---

## Chapter 3: [Product Specification](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-3.md)

This chapter provides the functional breakdown, port definitions, and configuration parameters.

### Functional Description
The AXI Ethernet Subsystem includes several core components:
- **Tri-Mode Ethernet MAC (TEMAC)**: Manages Ethernet frame transmission and reception, supporting functions like flow control, checksum offloading, and VLAN handling.
- **PCS/PMA or SGMII Core**: Converts between Ethernet MAC frames and the physical-layer signals for various speeds and standards.
- **AXI Ethernet Buffer**: Handles buffer management for transmit and receive paths, with features like checksum offloading and multicast filtering.
  
### Port Descriptions
- **AXI4-Lite Interface**: Provides processor access to the subsystem’s registers, supporting single-beat read and write operations.
- **AXI4-Stream Interfaces**: Separate AXI4-Stream buses handle transmit (`s_axis_txd`) and receive (`m_axis_rxd`) data, designed to connect with an AXI DMA or other custom logic.
- **PHY Interface**: Configurable for MII, GMII, RGMII, SGMII, or 1000BASE-X interfaces, connecting the MAC to an external PHY or to an on-chip interface.

### Flow Control
IEEE 802.3 flow control can prevent data loss by sending or receiving pause frames. When a link is congested, the subsystem can issue a pause frame to its link partner, requesting it to temporarily stop sending data.

### Additional Features
- **Jumbo Frame Support**: Frames up to 16 KB are supported in hardware.
- **Multicast Address Filtering**: The subsystem allows configurable filtering for up to four multicast addresses, with extended multicast filtering available if configured.

---

## Chapter 4: [Designing with the Subsystem](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-4.md)

This chapter covers detailed design guidelines for proper configuration and signal management.

### Design Guidelines
- **Clocking**: The subsystem requires a primary clock (`gt_clk`) and optional clocks for specific configurations (e.g., timestamping).
- **Resets**: Proper reset configuration is critical for initializing the subsystem and for recovery from errors.
- **Parameter Configuration**: Configuration parameters must be set according to design needs, especially when enabling advanced features like timestamping or checksum offloading.

### Allowable Parameter Combinations
Describes how parameter selections impact functionality. For example, enabling checksum offloading increases resource utilization but boosts performance by offloading CPU tasks.

### Example Configurations
Various configurations are provided for different use cases, ensuring flexibility for multiple designs (e.g., standard Ethernet operation vs. timestamped Ethernet for industrial automation).

---

## Chapter 5: [Design Flow Steps](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-5.md)

This chapter guides the user through key steps in configuring, simulating, and implementing the subsystem within Vivado.

### Customization and Generation
- **Subsystem Configuration**: Details how to use Vivado to customize the AXI Ethernet Subsystem, including setting IP parameters, enabling/disabling features, and setting up interfaces.
- **Output Product Generation**: Instructions on generating the necessary output files for the customized subsystem, including constraints and simulation models.

### Constraining the Subsystem
- **Timing Constraints**: Specific guidance on timing constraints, especially for high-speed Ethernet connections.
- **I/O Constraints**: Configuration of I/O standards and pin assignments for the subsystem’s physical Ethernet interfaces.

### Simulation and Synthesis
Instructions for simulating the subsystem using Vivado-supported simulators, with notes on synthesis and implementation. Specific examples are provided for handling constraints during synthesis.

---

## Chapter 6: [Example Design](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-6.md)

An example design is provided to illustrate how to integrate and test the subsystem in a practical setup.

### Example Components
- **Pattern Generator**: Generates Ethernet frames for transmission, allowing testing of the transmission path.
- **Pattern Checker**: Receives Ethernet frames and verifies correctness, used for validating receive path integrity.
- **FIFO Buffers**: Used for buffering Ethernet frames at 10/100/1000 Mb/s, demonstrating handling of data flow between MAC and user logic.

### Implementation on FPGA Boards
Detailed steps are provided for targeting an FPGA board, including configuring the example design and setting up the physical Ethernet connection.

---

## Chapter 7: [Test Bench](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-7.md)

### Test Bench Functionality
Describes the default test bench provided with the subsystem. It simulates typical Ethernet data flow scenarios, verifying functionality for both transmission and reception paths.

### Customization
Users can modify the test bench to test specific features or handle custom data patterns, such as varying frame sizes or different Ethernet protocols.

---

## Chapter 8: [IEEE 1588 Timestamping](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-8.md)

The subsystem offers IEEE 1588 Precision Time Protocol (PTP) for synchronized timestamps on Ethernet packets, often used in industrial or automation contexts.

### Configuring IEEE 1588
Instructions on enabling IEEE 1588 support, configuring timestamp formats, and adjusting clock synchronization for precision timing.

### Device and Interface Requirements
The IEEE 1588 functionality requires specific transceivers and PHY interfaces compatible with timestamping. Only certain AMD devices support this feature fully.

---

## Chapter 9: [Upgrading](https://github.com/ChandraPrakash024/Filter-Coffee/blob/Master/Ethernet%20Documentation/Chapter-9.md)

Guidelines for users upgrading to the latest subsystem version.

### Vivado Compatibility
Provides information on using Vivado’s IP upgrade features to bring older designs up to date. This includes handling changes in core versions and any new requirements for constraints or interfaces.

### Summary of Changes
A change log summarizes significant updates between previous versions and version 7.2, allowing users to understand potential impacts on their designs.

---

## Chapter 10: Debugging

This chapter outlines available debugging tools and techniques for troubleshooting.

### Debugging Tools
Descriptions of tools in the Vivado Suite for debugging, such as hardware debug cores and Integrated Logic Analyzer (ILA) support.

### Interface Debugging
Provides techniques for debugging data flow on AXI4-Stream and AXI4-Lite interfaces, with a focus on ensuring proper data transfer to and from the Ethernet subsystem.

---

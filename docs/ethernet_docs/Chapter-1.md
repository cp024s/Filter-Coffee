# Chapter 1: Introduction

The **AXI 1G/2.5G Ethernet Subsystem** is a versatile and high-performance Ethernet solution, optimized for use in AMD FPGA platforms including the AMD 7 Series, UltraScale™, UltraScale+™, and Versal™ Adaptive SoCs. This subsystem provides capabilities for various Ethernet modes, PHY interface standards, and optional advanced features such as IEEE 1588 timestamping, TCP/UDP checksum offloading, and Ethernet Audio Video Bridging (AVB) support.

## Overview of the Subsystem

The AXI Ethernet Subsystem is an intellectual property (IP) core developed by AMD for integration within custom hardware designs. It enables Ethernet communication at standard speeds (10/100/1000 Mb/s) and can also support 2.5 Gb/s Ethernet operation on specific devices. The subsystem facilitates a streamlined process for designing Ethernet-enabled systems by managing the MAC (Media Access Control) layer, interfacing with a PHY (Physical Layer) device, and handling advanced networking functions.

### Core Components of the Subsystem
The subsystem includes several critical components:
1. **Tri-Mode Ethernet MAC (TEMAC)**:
   - The TEMAC provides Ethernet frame formatting and control, supporting 10, 100, and 1000 Mb/s (1G) operation. It manages MAC layer functions and complies with IEEE 802.3 standards.
   - The TEMAC can operate in various modes, such as MII (Media Independent Interface) and GMII (Gigabit Media Independent Interface), allowing connectivity to a range of PHY devices.
   
2. **1G/2.5G PCS/PMA or SGMII Core**:
   - This core provides the physical coding sublayer (PCS) and physical media attachment (PMA) for Ethernet physical interfaces.
   - It supports 1000BASE-X and SGMII (Serial GMII), which are especially suited for high-speed serial links, such as fiber-optic communication.

3. **AXI Ethernet Buffer**:
   - This module manages data buffering for Ethernet transmit and receive paths. It facilitates the handling of Ethernet frames in the FPGA fabric.
   - It supports VLAN tagging and stripping, checksum offloading, and multicast filtering.

### Supported Ethernet Standards and Features

The subsystem is compatible with several Ethernet standards and offers flexible PHY interfacing options to meet diverse application requirements:

- **10/100/1000 Mb/s Support**: The AXI Ethernet Subsystem is a tri-mode Ethernet MAC, supporting three standard Ethernet speeds (10 Mb/s, 100 Mb/s, and 1 Gb/s).
- **2.5 Gb/s Operation**: Available on compatible devices, such as AMD Kintex, Virtex, and UltraScale+ FPGAs. This feature is supported with GTH and GTY transceivers and provides increased bandwidth over the traditional 1 Gb/s Ethernet.
- **IEEE 802.3 Compliance**: Complies with IEEE standards for Ethernet, ensuring compatibility and interoperability with other IEEE-compliant network devices.
  
### PHY Interface Options
The AXI Ethernet Subsystem supports several PHY interface standards, each suited to specific network requirements:
1. **MII (Media Independent Interface)**: Suitable for 10 and 100 Mb/s operation, offering a straightforward connection for low-speed Ethernet.
2. **GMII (Gigabit Media Independent Interface)**: Supports 1 Gb/s operation and provides flexibility for connecting to a wide range of PHY devices.
3. **RGMII (Reduced Gigabit Media Independent Interface)**: A reduced-pin version of GMII, used for 1 Gb/s Ethernet with fewer signals, which reduces PCB routing complexity.
4. **SGMII (Serial Gigabit Media Independent Interface)**: A serial interface designed for 1 Gb/s links, often used with fiber optics or in backplane applications.
5. **1000BASE-X**: Standard for gigabit Ethernet over fiber, providing high-speed data transfer rates.

### Optional Advanced Features
1. **VLAN Support**:
   - The subsystem can handle VLAN (Virtual LAN) tagging, stripping, and translation, enabling support for VLAN-based network segmentation and traffic management.
   - VLAN functionality complies with IEEE 802.1Q standards, supporting 16-bit VLAN tags.

2. **TCP/UDP Checksum Offload**:
   - Hardware-based checksum offloading allows the AXI Ethernet Subsystem to compute and verify TCP/UDP checksums, offloading this responsibility from the host CPU.
   - This feature can be enabled for both transmit and receive paths, enhancing performance for high-throughput applications by reducing CPU processing load.

3. **IEEE 1588 Precision Time Protocol (PTP)**:
   - The IEEE 1588 PTP support provides hardware timestamping for Ethernet frames, allowing precise time synchronization across networked devices.
   - IEEE 1588 is widely used in industrial and automation applications where accurate time coordination between devices is critical.

4. **Ethernet Audio Video Bridging (AVB)**:
   - AVB enables real-time streaming of audio and video over Ethernet networks, providing low-latency, time-synchronized data streams.
   - AVB support in the AXI Ethernet Subsystem includes features for IEEE 802.1AS clock synchronization and IEEE 802.1Qav bandwidth reservation, essential for audio-visual applications.

### Licensing Information
The AXI 1G/2.5G Ethernet Subsystem is available under the AMD Vivado Design Suite and comes with various licensing options based on the feature set.

- **Included Features**: Basic Ethernet MAC functionality, including MII, GMII, and RGMII modes, is generally available as part of the Vivado Design Suite.
- **Licensing Requirements**:
  - Advanced features such as AVB may require a separate license.
  - The TEMAC core, which provides MAC functionality, has licensing conditions outlined in the Tri-Mode Ethernet MAC LogiCORE IP Product Guide (PG051).
  
Licensing requirements are indicated in the Vivado IP catalog, which specifies whether a feature is included or requires an additional purchase.

---

### Summary of Key Benefits
The AXI Ethernet Subsystem v7.2 provides a range of advantages for networking applications:
- **Flexible PHY Interface Support**: Compatibility with various PHY interfaces (MII, GMII, RGMII, SGMII, 1000BASE-X) offers design flexibility, enabling integration into a broad range of Ethernet applications.
- **Performance Optimization**: With features like checksum offloading, VLAN tagging, and timestamping, the subsystem offloads significant networking tasks from the CPU, improving overall system performance.
- **Advanced Timing and Synchronization**: Support for IEEE 1588 PTP makes the subsystem ideal for applications requiring precise synchronization, such as telecommunications and industrial automation.
- **Real-Time Audio and Video Support**: AVB support allows for real-time audio and video transmission over Ethernet, making the subsystem suitable for multimedia applications.

---

### Typical Use Cases
The AXI 1G/2.5G Ethernet Subsystem is designed to support a variety of applications, including but not limited to:
1. **Industrial Automation**: Using IEEE 1588 PTP for time-critical applications requiring precise device synchronization.
2. **Telecommunications**: Leveraging high-speed 2.5 Gb/s Ethernet and advanced flow control to handle large volumes of data efficiently.
3. **Automotive Applications**: Enabling real-time AVB Ethernet streams for in-vehicle multimedia and infotainment systems.
4. **Audio and Video Broadcasting**: Using AVB and VLAN capabilities to manage multimedia streams and network traffic.

---

This comprehensive introduction provides an overview of the subsystem’s functionality, supported interfaces, and feature options, setting the stage for deeper technical exploration in the following chapters. Let me know if you'd like further details on any specific feature or component.

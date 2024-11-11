### Overview of the AXI Ethernet Subsystem

The AXI 1G/2.5G Ethernet Subsystem can be easily integrated into a design using the **Vivado IP Integrator** or by instantiating it as an IP core in the **Vivado Integrated Design Environment (IDE)**. This setup allows you to configure, simulate, and implement the subsystem, followed by generating the bitstream for the target device. 

The subsystem includes multiple infrastructure cores that are instantiated and connected to each other during system design. The **primary components** include:
1. **Tri-Mode Ethernet MAC (TEMAC)**: Provides the core Media Access Control (MAC) functionality.
2. **1G/2.5G Ethernet PCS/PMA or SGMII**: Manages physical layer signaling.
3. **AXI Ethernet Buffer Core**: Adds buffering capabilities for the data stream, enhancing performance and customization potential.

Each infrastructure core can also be instantiated independently, allowing users flexibility depending on design needs.

### Key Design Process

Documentation for the AXI Ethernet Subsystem aligns with specific **design processes** to facilitate smooth development. Each process includes links to design resources and relevant chapters within the document:
- **Hardware, IP, and Platform Development**: Guidance for creating IP blocks, designing functional simulations, and evaluating constraints related to timing, power, and resource usage.
- **Subsystem Customization**: Step-by-step instructions for adjusting subsystem parameters to meet design specifications.

### How to Use This Document

The document is structured to highlight common features across different operational modes, with specific instructions in cases where differences exist. Mode-specific details (e.g., for PHY interfaces like MII, GMII, and SGMII) are clearly marked to avoid confusion. Users are advised to follow mode-related notes for precise configuration.

### Feature Summary

The AXI Ethernet Subsystem offers a rich feature set:
- **Full-Duplex Operation**: Provides high-speed bidirectional communication; half-duplex is not supported.
- **IEEE 1588 Timestamping**: Available for 1G and 2.5G modes, particularly on the 1000BASE-X and SGMII PHY configurations. Timestamping can be done in **one-step** or **two-step** modes. The timestamp format can be customized during subsystem generation, either in **Time-of-Day (ToD)** or **Correction Field** format. 
  - **Supported Devices**: IEEE 1588 support is compatible with certain AMD Versal Adaptive SoCs, UltraScale, UltraScale+ devices, and 7 series FPGAs, depending on the transceivers available (GTY, GTX, or GTH).
- **Jumbo Frame Support**: Jumbo frames up to 16 KB in size are supported, allowing for efficient handling of large data packets.
- **Checksum Offloading**: Both partial and full TCP/UDP checksum offload are available for IPv4 transmission and reception, reducing CPU processing load.
- **VLAN Support**: VLAN tagging, stripping, and translation are supported, facilitating integration into segmented network environments.
- **Multicast Filtering**: Extended filtering capabilities for multicast frames help improve performance by limiting the frames processed.
- **Frame Padding and Frame Check Sequence (FCS)**: The subsystem offers automatic padding and FCS handling. FCS can be inserted or stripped, depending on transmit or receive configuration.
- **AVB (Audio Video Bridging)**: Supports Ethernet AVB at 100 Mbps or 1 Gbps, which is essential for applications requiring synchronized audio/video streaming. (Additional license required for AVB).
- **Optional Shared Logic Exclusion**: Shared logic resources may be included or excluded from the design based on the specific hardware setup and user needs, allowing optimized use of FPGA resources.

### Licensing and Ordering

The AXI Ethernet Subsystem is included with the Vivado Design Suite, but specific features, such as AVB, require additional licenses. This licensing structure ensures flexibility for users who only need core functionality while allowing access to advanced features as needed.

For complete details on supported device families, refer to the IP catalog in Vivado or consult the **Tri-Mode Ethernet MAC (TEMAC) Product Guide (PG051)** for licensing details on the TEMAC core itself.

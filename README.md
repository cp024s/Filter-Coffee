# Shakti - Packet Filter Firewall

## Introduction
The Shakti - Packet Filter Firewall project aims to provide a robust, hardware-accelerated firewall solution for high-speed networks. With the exponential growth in data transfer rates, traditional software-based firewalls face significant challenges in meeting the performance requirements. By leveraging FPGA-based hardware and a hybrid packet filtering approach, this project addresses the limitations of software solutions and achieves high-throughput packet filtering.

## Motivation
The increasing prevalence of cyber-attacks necessitates effective network security measures, particularly for high-speed data transmission. The conventional software-based firewalls are becoming inadequate due to the ever-increasing network speeds and the processing requirements to handle gigabits of data per second. This project explores hardware-based alternatives to overcome these limitations and provides a scalable and customizable solution.

## Project Objectives
The main objectives of the project are:
1. **High-Performance Packet Filtering:** Achieve packet processing rates required for modern high-speed networks (100 Gbps and beyond).
2. **Low Latency:** Minimize the processing delay to avoid becoming a bottleneck in the network.
3. **Efficient Resource Utilization:** Optimize the FPGA's hardware resources, including Slice LUTs, Slice Registers, and BRAM slices.
4. **Scalability:** Support dynamic updates to firewall rules and adapt to different network configurations.
5. **Security:** Provide robust packet filtering to detect and block potentially harmful network traffic.

## Overall Architecture
The system architecture integrates hardware-based packet filtering with FPGA technology and software-driven analysis for enhanced security and performance.

### Packet Filtering Mechanism
The firewall works by inspecting the incoming network packets against a set of predefined rules:
- **Rule Matching:** The incoming packet headers are compared against firewall rules that specify authorized or unauthorized traffic based on IP addresses, ports, and protocols.
- **Action Execution:** Depending on the match, the system executes an action (allow or block) on the incoming packet. If no match is found, a default action is applied.

### System Components
1. **Ethernet Transactor:** Interfaces with the Ethernet IP core to receive and transmit packets over the network.
2. **Master Packet Dealer (MPD):** Manages packet classification and coordination between different components.
3. **Packet Reference Table (PRT):** Stores the payload data of incoming packets and associates metadata for processing.
4. **Hardware Bloom Filter:** Performs initial packet classification using a probabilistic data structure.
5. **Shakti CPU:** Handles secondary processing for packets flagged by the Bloom filter.

## Implementation Details

### Bloom Filter-Based Packet Classification
The Bloom filter is used to classify packets based on a probabilistic data structure that allows fast membership checks:
- **Programming the Filter:** Firewall rules are hashed and stored in the Bloom filter, setting specific bits in a bit array.
- **Packet Query:** Incoming packets are hashed and checked against the Bloom filter to determine if they match any programmed rules.
- **False Positives Handling:** Any packets flagged as potential matches are further analyzed using a secondary software-based linear search.

### Hardware Architecture
The project evolved through three iterations to optimize latency, resource utilization, and throughput:

#### V1 Architecture
- **Description:** The initial architecture implemented a basic packet filtering mechanism using the Bloom filter.
- **Challenges:** High latency due to storage in registers and inefficient pipeline design. The architecture did not make full use of the available hardware resources.

#### V2 Architecture
- **Improvements:** Added a fully pipelined approach where the packet was processed as it was received, enabling simultaneous transmission and reception.
- **Outcomes:** Reduced resource utilization by using BRAM slices instead of registers. The architecture could achieve up to 100 Mbps throughput.

#### V3 Architecture
- **Enhancements:** Replaced the third-party Ethernet IP core with a custom solution, tightly integrating the Ethernet transactor and IP. The system achieved a drastic reduction in latency (213 clock cycles) and a significant reduction in Slice LUTs, Slice Registers, and BRAM slices.
- **Design Changes:** Employed custom synchronization FIFOs for clock-domain crossing, allowing data transfer between components running at different clock frequencies.

## Testing and Results
- **Latency:** The V3 architecture reduced the latency to 213 clock cycles for a 1400-byte Ethernet frame, a drastic improvement from the 10,642 cycles in V1.
- **Resource Utilization:** The design saw a significant decrease in Slice LUTs, Slice Registers, and BRAM slices from V1 to V3.
- **Testing Setup:** The system was tested using loopback mechanisms on Artix-7 FPGAs. Dual-port testing was conducted using Alinx AX7203B Artix-7 200T, which provided gigabit Ethernet support.

## Supported FPGA Boards
The project has been tested on the following FPGA boards:
- **Arty A7 - Artix-7 100T FPGA:** Used for initial testing and development with loopback configurations.
- **Alinx AX7203 - Artix-7 200T FPGA:** Employed for dual-port testing and gigabit Ethernet support.

## Future Work
The following enhancements are planned:
- **Development of Ethernet IP for 1000 Mbps Support:** Enable auto-negotiation and higher data rates.
- **Dynamic Hardware Reconfiguration:** Allow real-time updates to firewall rules through hardware reconfiguration.
- **Multi-Clock Domain Support:** Improve processing capabilities by running the firewall at higher clock speeds than the Shakti CPU.
- **Integration with Zedboards or ARM-Based SoCs:** Explore alternative processors for performance comparison.
- **Research on Advanced Bloom Filter Algorithms:** Investigate approaches to reduce false positives using learned algorithms or Boolean expressions.

# Ethernet frame format
### 1. **Preamble (7 Bytes)**
   - **Purpose**: The preamble consists of alternating 1s and 0s and is used to synchronize the communication between the sender and receiver. It allows the receiver to establish clock synchronization before the actual data is transmitted.
   - **Structure**: `10101010` pattern repeated 7 times.

### 2. **Start Frame Delimiter (SFD) (1 Byte)**
   - **Purpose**: The SFD marks the start of the actual Ethernet frame and indicates the end of the preamble. It’s a specific byte pattern that signals to the receiving device that the frame is about to begin.
   - **Structure**: `10101011`.

### 3. **Destination MAC Address (6 Bytes)**
   - **Purpose**: This field contains the MAC (Media Access Control) address of the destination device, identifying where the frame is to be delivered.
   - **Structure**: 48-bit (6-byte) hardware address, unique to each network device.

### 4. **Source MAC Address (6 Bytes)**
   - **Purpose**: This field holds the MAC address of the source device, identifying where the frame originated from.
   - **Structure**: 48-bit (6-byte) hardware address.

### 5. **EtherType / Length (2 Bytes)**
   - **Purpose**: This field can serve two purposes depending on the context:
     - If the value is **greater than 1500** (0x0600), it represents the **EtherType** and indicates which protocol is encapsulated in the payload (e.g., IPv4, IPv6, ARP).
     - If the value is **less than or equal to 1500**, it represents the **length** of the payload in bytes.
   - **Examples**:
     - `0x0800`: IPv4 packet.
     - `0x86DD`: IPv6 packet.
     - `0x0806`: ARP (Address Resolution Protocol).

### 6. **Data / Payload (46–1500 Bytes)**
   - **Purpose**: This field contains the actual data being transmitted, such as an IP packet or other network-layer information.
   - **Structure**: The minimum payload size is 46 bytes, and the maximum is 1500 bytes. If the payload is less than 46 bytes, padding is added to reach the minimum size.
   - **Details**: Encapsulates the higher-layer protocol data (e.g., IP, ARP, etc.).

### 7. **Frame Check Sequence (FCS) (4 Bytes)**
   - **Purpose**: The FCS is a 32-bit cyclic redundancy check (CRC) used to detect errors in the frame during transmission. The sender calculates a CRC value based on the frame contents, and the receiver verifies this CRC to ensure data integrity.
   - **Structure**: 32-bit CRC value.

---

### Complete Ethernet Frame Breakdown (Standard Ethernet Frame)

| **Field Name**               | **Size**          | **Description**                                                |
|------------------------------|-------------------|----------------------------------------------------------------|
| **Preamble**                  | 7 bytes           | Synchronizes sender and receiver clocks.                       |
| **Start Frame Delimiter (SFD)**| 1 byte            | Indicates the start of the frame.                              |
| **Destination MAC Address**   | 6 bytes           | Hardware address of the destination device.                    |
| **Source MAC Address**        | 6 bytes           | Hardware address of the source device.                         |
| **EtherType / Length**        | 2 bytes           | Identifies the protocol (e.g., IPv4) or specifies payload length.|
| **Data / Payload**            | 46–1500 bytes     | Encapsulated data from higher-layer protocols.                 |
| **Frame Check Sequence (FCS)**| 4 bytes           | Error-detection field using CRC-32.                            |

### Minimum Ethernet Frame Size: 64 bytes
   - **Why Minimum Size**: If the payload is less than 46 bytes, padding is added to ensure the minimum frame size of 64 bytes, including headers and FCS, is met. This helps detect collisions in the network.

### Maximum Ethernet Frame Size: 1518 bytes
   - **Standard Ethernet Frame**: The maximum frame size without any form of encapsulation is 1518 bytes, which includes 1500 bytes of payload and 18 bytes of overhead (headers and FCS).
   - **Jumbo Frames** (Optional): Some Ethernet implementations support larger frames (up to 9000 bytes) called **Jumbo Frames**, used in high-performance networks to reduce overhead.

---

### Ethernet Frame Example (IPv4 Packet Encapsulation)
Let’s break down a typical Ethernet frame that carries an IPv4 packet:

| **Field**               | **Value (Hexadecimal)**                | **Description**                                 |
|-------------------------|----------------------------------------|-------------------------------------------------|
| **Preamble**            | `55 55 55 55 55 55 55`                | Synchronization.                               |
| **SFD**                 | `D5`                                   | Marks the start of the frame.                  |
| **Destination MAC**     | `FF FF FF FF FF FF`                    | Broadcast address (FF:FF:FF:FF:FF:FF).         |
| **Source MAC**          | `00 0C 29 9C 8E 4A`                    | Source device MAC address.                     |
| **EtherType**           | `08 00`                                | Indicates IPv4 (0x0800).                       |
| **Data (Payload)**      | (Variable)                             | Contains the IP header and data.               |
| **FCS**                 | (Calculated CRC)                       | Used for error detection.                      |

This example frame encapsulates an IPv4 packet. The actual data inside the payload would contain the IPv4 header and the encapsulated higher-layer protocols (e.g., TCP, UDP).

### Summary:
- The Ethernet frame consists of fields for synchronization, addressing, error-checking, and actual data encapsulation.
- Ethernet relies on both MAC addresses for local delivery and upper-layer protocols like IP for global communication, encapsulated inside the frame's payload.

The **IP addresses** (both Source and Destination IP) are found **within the Ethernet frame's payload**, specifically in the **IP header** of an IP packet.

Here’s a detailed breakdown of where the IP addresses appear within the Ethernet frame:

1. **Ethernet Frame**: The Ethernet frame does not directly contain IP addresses. It contains MAC addresses in its header. The **EtherType** field will indicate if the payload is an IP packet (usually by having a value of `0x0800` for IPv4).
   
2. **Ethernet Payload**: If the EtherType indicates IPv4 (`0x0800`), the payload starts with an IP packet. The IP addresses are located inside the **IP header**, which is part of this payload.

### IP Header (Encapsulated in Ethernet Payload)
The IP header contains the following relevant fields:

- **Source IP Address**: Located at byte 12–15 of the IP header.
- **Destination IP Address**: Located at byte 16–19 of the IP header.

### Example Ethernet Frame Breakdown with IP Packet

| **Ethernet Field**           | **Size (Bytes)**  | **Details**                                                                 |
|------------------------------|-------------------|-----------------------------------------------------------------------------|
| **Preamble**                 | 7 bytes           | Synchronization bytes (not relevant for IP addressing).                     |
| **SFD**                      | 1 byte            | Marks the start of the frame.                                               |
| **Destination MAC Address**   | 6 bytes           | MAC address of the destination device (Layer 2 address).                    |
| **Source MAC Address**        | 6 bytes           | MAC address of the source device (Layer 2 address).                         |
| **EtherType**                 | 2 bytes           | `0x0800` indicating that the payload is an IPv4 packet.                     |
| **Ethernet Payload**          | 20+ bytes         | Contains the IP packet, starting with the IP header.                        |
| -- **IP Header**              | 20 bytes (min)    | Inside Ethernet Payload, contains IP addresses, version, TTL, etc.          |
| ---- **Source IP Address**    | 4 bytes (byte 12-15)| The IP address of the sending device (Layer 3 address).                     |
| ---- **Destination IP Address**| 4 bytes (byte 16-19)| The IP address of the receiving device (Layer 3 address).                   |
| **Frame Check Sequence (FCS)**| 4 bytes           | CRC value used for error detection.                                         |

---

### Locating the IP Address
- The **Ethernet frame** wraps the **IP packet**.
- Inside the **IP packet** (which is the payload of the Ethernet frame), the **Source IP Address** and **Destination IP Address** are located in the IP header.
  
- **Source IP Address**: At byte 12–15 in the IP header.
- **Destination IP Address**: At byte 16–19 in the IP header.

Thus, the IP addresses are located **within the Ethernet frame's payload**, specifically in the **IP header** of the encapsulated IP packet.

The **payload** in an Ethernet frame is where the actual data from higher-layer protocols is encapsulated. It typically contains the **IP packet** if the EtherType field indicates that the payload is carrying an IPv4 or IPv6 packet. The IP packet itself contains its own header (including the source and destination IP addresses) and the encapsulated data, such as a TCP/UDP segment, HTTP request, or other protocol data.

Let's dive deeply into the payload, particularly focusing on the most common case: an **IPv4 packet** encapsulated within an Ethernet frame.

---

### Ethernet Payload Structure (with IPv4 Encapsulation)

If the EtherType field is `0x0800` (for IPv4), the payload is an **IPv4 packet**. The payload starts with the **IPv4 header**, followed by the **IP data** (such as a TCP, UDP, ICMP, or other higher-layer protocol data).

The payload consists of:
1. **IPv4 Header**
2. **IP Data (TCP/UDP/ICMP/etc.)**

---

### 1. **IPv4 Header** (Minimum 20 bytes)

The **IPv4 header** is a fixed part of the Ethernet payload and contains key information needed to route and deliver the packet across networks. The IP header is usually 20 bytes long, but it can be longer if **optional fields** are present.

| **Field**               | **Size (Bits)** | **Description**                                                         |
|-------------------------|-----------------|-------------------------------------------------------------------------|
| **Version**             | 4 bits          | IP version (IPv4 = 4).                                                  |
| **IHL (Header Length)**  | 4 bits          | The length of the IP header (usually 5 for 20 bytes).                    |
| **Type of Service**      | 8 bits          | Differentiated services or priority (QoS).                               |
| **Total Length**         | 16 bits         | The total length of the entire IP packet (header + data).                |
| **Identification**       | 16 bits         | Unique identifier for fragmentation.                                     |
| **Flags + Fragment Offset** | 3 bits + 13 bits | Used for fragmentation of large packets.                                 |
| **Time to Live (TTL)**   | 8 bits          | Hop limit for the packet (prevents infinite looping).                    |
| **Protocol**             | 8 bits          | Indicates the higher-level protocol (e.g., `0x06` for TCP, `0x11` for UDP). |
| **Header Checksum**      | 16 bits         | Error-checking code for the IP header.                                   |
| **Source IP Address**    | 32 bits (4 bytes) | The IPv4 address of the source device.                                    |
| **Destination IP Address**| 32 bits (4 bytes) | The IPv4 address of the destination device.                               |
| **Options (if present)** | Variable (0 to 40 bytes) | Optional fields, used for special routing purposes.                 |

#### **Source and Destination IP Addresses**
   - **Source IP Address** (4 bytes): This is located at byte 12–15 in the IP header. It represents the address of the sender of the packet.
   - **Destination IP Address** (4 bytes): This is located at byte 16–19 in the IP header. It represents the address of the intended recipient of the packet.

#### **Example of IPv4 Header Breakdown**
Consider a typical IPv4 header (20 bytes) in hexadecimal:

```
45 00 00 3C 1C 46 40 00 40 06 B1 E6 C0 A8 00 68 C0 A8 00 01
```

| **Hexadecimal** | **Explanation**                              |
|-----------------|----------------------------------------------|
| `45`            | Version (4) + IHL (5 = 20 bytes header).     |
| `00`            | Type of Service.                             |
| `00 3C`         | Total Length (60 bytes).                     |
| `1C 46`         | Identification.                             |
| `40 00`         | Flags and Fragment Offset (Don't Fragment).  |
| `40`            | TTL (64).                                    |
| `06`            | Protocol (TCP).                              |
| `B1 E6`         | Header Checksum.                             |
| `C0 A8 00 68`   | Source IP (192.168.0.104).                   |
| `C0 A8 00 01`   | Destination IP (192.168.0.1).                |

---

### 2. **IP Data (Payload)**

After the IP header, the actual **IP data** (which is the payload of the IP packet) follows. The content of this part depends on the **Protocol** field in the IP header. This data could be from various Layer 4 protocols, such as **TCP**, **UDP**, or **ICMP**.

#### **Examples of Encapsulated IP Data**:

1. **TCP Segment**:
   If the Protocol field in the IP header indicates TCP (`0x06`), the payload will contain a TCP segment.

   - **TCP Header** (20–60 bytes): The TCP header contains the source and destination port numbers, sequence numbers, and flags.
   - **TCP Data**: The actual data being sent via TCP (e.g., HTTP request, file data, etc.).

2. **UDP Datagram**:
   If the Protocol field indicates UDP (`0x11`), the payload will contain a UDP datagram.

   - **UDP Header** (8 bytes): Contains source and destination ports, length, and checksum.
   - **UDP Data**: The actual data being sent via UDP (e.g., DNS query, streaming media, etc.).

3. **ICMP Packet**:
   If the Protocol field indicates ICMP (`0x01`), the payload will contain an ICMP packet, often used for network diagnostics (e.g., ping requests).

---

### Payload Size and Fragmentation

1. **Minimum Payload Size**:
   - The minimum payload size for Ethernet is 46 bytes. If the IP data (including the IP header) is less than 46 bytes, padding is added to meet this requirement.

2. **Maximum Payload Size (MTU)**:
   - The maximum payload size for a standard Ethernet frame is 1500 bytes. This is the **Maximum Transmission Unit (MTU)** for Ethernet.
   - If the IP packet exceeds the MTU size, the packet must be **fragmented** into smaller pieces, which are reassembled at the destination.

---

### Fragmentation in IP

When an IP packet is too large to fit within the MTU of the Ethernet frame (1500 bytes), the packet is broken into smaller fragments. These fragments are reassembled by the destination device based on the information in the IP header.

- The **Total Length** field in the IP header gives the size of each fragment.
- The **Fragment Offset** and **More Fragments** flag in the IP header indicate where the fragment belongs in the original packet and whether more fragments follow.

---

### Example of a Full Ethernet Frame Carrying an IPv4 Packet

Here’s an example breakdown of an Ethernet frame that encapsulates an IPv4 packet containing TCP data:

| **Ethernet Frame**                      | **Field**                      | **Size (Bytes)** | **Description**                                           |
|-----------------------------------------|---------------------------------|------------------|-----------------------------------------------------------|
| **Ethernet Header**                     | Destination MAC Address         | 6 bytes          | Destination MAC (Layer 2).                                |
|                                         | Source MAC Address              | 6 bytes          | Source MAC (Layer 2).                                     |
|                                         | EtherType                       | 2 bytes          | `0x0800` (indicates IPv4).                                |
| **Ethernet Payload (IP Packet)**        | **IPv4 Header**                 | 20 bytes         | Contains source and destination IP addresses.             |
|                                         | Source IP Address               | 4 bytes          | IPv4 source (e.g., 192.168.1.1).                          |
|                                         | Destination IP Address          | 4 bytes          | IPv4 destination (e.g., 192.168.1.2).                     |
| **IP Data (TCP Segment)**               | **TCP Header**                  | 20 bytes         | Contains source and destination ports (e.g., HTTP port).   |
|                                         | TCP Data                        | Variable         | Application layer data (e.g., part of an HTTP request).    |
| **Frame Check Sequence (FCS)**          | Frame Check Sequence            | 4 bytes          | Error detection using CRC-32.                             |

---

### Summary of the Ethernet Payload:
- The Ethernet payload carries the actual data from upper-layer protocols, which could be an IP packet, an ARP request, or other data.
- For **IP packets**, the payload contains the IP header (with source and destination IP addresses) and the encapsulated IP data (such as TCP, UDP, ICMP, etc.).
- The size of the payload can vary from 46 to 1500 bytes, with padding added if needed to meet the minimum payload size.

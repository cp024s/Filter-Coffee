
---

# Frame and Packet Formats in the ISO/OSI Model

## **1. Ethernet Frame Format**
Ethernet frames operate at the **Data Link Layer (Layer 2)**. Below is the structure:

| Field              | Size         | Description                                    |
|--------------------|--------------|------------------------------------------------|
| **Preamble**       | 7 Bytes      | Synchronization pattern for receiver.          |
| **Start Frame Delimiter (SFD)** | 1 Byte  | Indicates the start of the frame.            |
| **Destination MAC**| 6 Bytes      | MAC address of the destination device.         |
| **Source MAC**     | 6 Bytes      | MAC address of the source device.              |
| **EtherType/Length**| 2 Bytes     | Indicates protocol type (e.g., IPv4/IPv6) or length. |
| **Payload/Data**   | 46–1500 Bytes| Actual data being transported.                 |
| **Frame Check Sequence (FCS)** | 4 Bytes | CRC checksum for error checking.             |

---

## **2. IPv4 Packet Format**
IPv4 packets operate at the **Network Layer (Layer 3)**. Below is the structure:

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Version**          | 4 Bits       | IPv4 version (always 4).                      |
| **Header Length**    | 4 Bits       | Length of the header in 32-bit words.         |
| **Type of Service**  | 1 Byte       | Quality of Service (QoS) settings.            |
| **Total Length**     | 2 Bytes      | Total size of the packet (header + data).     |
| **Identification**   | 2 Bytes      | Packet ID for reassembly.                     |
| **Flags**            | 3 Bits       | Control flags (e.g., fragmentation).          |
| **Fragment Offset**  | 13 Bits      | Position of fragment in original packet.      |
| **Time to Live (TTL)**| 1 Byte      | Maximum number of hops.                       |
| **Protocol**         | 1 Byte       | Protocol used in the payload (e.g., TCP = 6). |
| **Header Checksum**  | 2 Bytes      | Error-checking value for the header.          |
| **Source IP Address**| 4 Bytes      | Sender's IPv4 address.                        |
| **Destination IP Address** | 4 Bytes | Receiver's IPv4 address.                     |
| **Options**          | Variable     | Additional options, if any.                  |
| **Payload/Data**     | Variable     | Encapsulated higher-layer data.              |

---

## **3. IPv6 Packet Format**
IPv6 packets also operate at the **Network Layer (Layer 3)** but have a simplified structure compared to IPv4:

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Version**          | 4 Bits       | IPv6 version (always 6).                      |
| **Traffic Class**    | 1 Byte       | QoS parameters.                               |
| **Flow Label**       | 20 Bits      | Used for prioritization of packet flows.      |
| **Payload Length**   | 2 Bytes      | Length of the data payload.                   |
| **Next Header**      | 1 Byte       | Type of the next header (e.g., TCP/UDP).      |
| **Hop Limit**        | 1 Byte       | Number of hops before the packet is dropped.  |
| **Source IP Address**| 16 Bytes     | Sender's IPv6 address.                        |
| **Destination IP Address** | 16 Bytes | Receiver's IPv6 address.                     |
| **Payload/Data**     | Variable     | Encapsulated higher-layer data.              |

---

## **4. Other Key Protocol Formats in the ISO Layers**

### **4.1 TCP Segment Format (Transport Layer - Layer 4)**

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Source Port**      | 2 Bytes      | Sender's port number.                         |
| **Destination Port** | 2 Bytes      | Receiver's port number.                       |
| **Sequence Number**  | 4 Bytes      | Order of the data in the stream.              |
| **Acknowledgment Number** | 4 Bytes | Next expected sequence number.               |
| **Header Length**    | 4 Bits       | Size of the header in 32-bit words.           |
| **Flags**            | 6 Bits       | Control bits (e.g., SYN, ACK, FIN).           |
| **Window Size**      | 2 Bytes      | Size of the receiver's buffer window.         |
| **Checksum**         | 2 Bytes      | Error-checking value.                         |
| **Urgent Pointer**   | 2 Bytes      | Pointer to urgent data.                       |
| **Options**          | Variable     | Additional options, if any.                  |
| **Data**             | Variable     | Encapsulated higher-layer data.              |

---

### **4.2 UDP Segment Format (Transport Layer - Layer 4)**

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Source Port**      | 2 Bytes      | Sender's port number.                         |
| **Destination Port** | 2 Bytes      | Receiver's port number.                       |
| **Length**           | 2 Bytes      | Total length of the segment.                  |
| **Checksum**         | 2 Bytes      | Error-checking value.                         |
| **Data**             | Variable     | Encapsulated higher-layer data.              |

---

### **4.3 ARP Frame Format (Network Layer - Layer 3)**

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Hardware Type**    | 2 Bytes      | Type of hardware (e.g., Ethernet = 1).        |
| **Protocol Type**    | 2 Bytes      | Type of protocol (e.g., IPv4 = 0x0800).       |
| **Hardware Size**    | 1 Byte       | Size of MAC address (6 for Ethernet).         |
| **Protocol Size**    | 1 Byte       | Size of IP address (4 for IPv4).              |
| **Opcode**           | 2 Bytes      | ARP operation (Request = 1, Reply = 2).       |
| **Sender MAC Address** | 6 Bytes    | MAC address of sender.                        |
| **Sender IP Address**| 4 Bytes      | IP address of sender.                         |
| **Target MAC Address** | 6 Bytes    | MAC address of receiver.                      |
| **Target IP Address**| 4 Bytes      | IP address of receiver.                       |

---

### **4.4 ICMP Packet Format (Network Layer - Layer 3)**

| Field                | Size         | Description                                    |
|----------------------|--------------|------------------------------------------------|
| **Type**            | 1 Byte       | Type of message (e.g., Echo Request = 8).     |
| **Code**            | 1 Byte       | Subtype of the message.                       |
| **Checksum**        | 2 Bytes      | Error-checking value.                         |
| **Rest of Header**  | Variable     | Depends on the ICMP type.                     |
| **Data**            | Variable     | Payload data.                                 |

---

## **5. ISO/OSI Model Layers and Common Protocols**
| Layer Number | Layer Name          | Example Protocols                              |
|--------------|---------------------|-----------------------------------------------|
| **7**        | Application Layer   | HTTP, FTP, SMTP, DNS                          |
| **6**        | Presentation Layer  | SSL/TLS, JPEG, PNG                            |
| **5**        | Session Layer       | NetBIOS, PPTP                                 |
| **4**        | Transport Layer     | TCP, UDP                                      |
| **3**        | Network Layer       | IP, ICMP, ARP                                 |
| **2**        | Data Link Layer     | Ethernet, PPP, Frame Relay                   |
| **1**        | Physical Layer      | Ethernet PHY, DSL, 802.11 (Wi-Fi)            |

---

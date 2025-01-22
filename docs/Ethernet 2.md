
---

## **Layer 7: Application Layer**
- **Message Name**: **Message or Data**
- **Function**:  
  The raw user-generated data (e.g., HTTP requests, file transfers, emails) originates at this layer.  
- **Frame Format**:  
  No specific frame format, as this layer deals with raw application data.

---

## **Layer 6: Presentation Layer**
- **Message Name**: **Formatted Data**
- **Function**:  
  Ensures data is in a readable and transmittable format (e.g., encryption, compression).  
- **Frame Format**:  
  No standard frame format. Examples include data encryption (TLS) or encoding (e.g., JSON, XML).

---

## **Layer 5: Session Layer**
- **Message Name**: **Session Data**  
- **Function**:  
  Establishes, manages, and terminates communication sessions. Provides synchronization and dialog control.  
- **Frame Format**:  
  No standard frame format. This layer uses protocols like NetBIOS or PPTP.

---

## **Layer 4: Transport Layer**
- **Message Name**: **Segment (TCP) or Datagram (UDP)**  
- **Function**:  
  Adds port numbers and ensures data delivery reliability (TCP) or fast, connectionless communication (UDP).  
- **Frame Format**:  

### **TCP Segment Format**
| Field               | Size       | Description                                       |
|---------------------|------------|---------------------------------------------------|
| **Source Port**     | 16 bits    | Port of the sender process.                      |
| **Destination Port**| 16 bits    | Port of the receiver process.                    |
| **Sequence Number** | 32 bits    | Order of bytes in the segment.                   |
| **Acknowledgment**  | 32 bits    | Next expected byte from the sender.              |
| **Data Offset**     | 4 bits     | Length of the TCP header.                        |
| **Flags**           | 6 bits     | Control bits (e.g., SYN, ACK, FIN).              |
| **Window Size**     | 16 bits    | Buffer size for flow control.                    |
| **Checksum**        | 16 bits    | Error detection.                                 |
| **Urgent Pointer**  | 16 bits    | Marks urgent data.                               |
| **Options**         | Variable   | TCP header options.                              |
| **Data**            | Variable   | Application data.                                |

### **UDP Datagram Format**
| Field               | Size       | Description                                       |
|---------------------|------------|---------------------------------------------------|
| **Source Port**     | 16 bits    | Port of the sender process.                      |
| **Destination Port**| 16 bits    | Port of the receiver process.                    |
| **Length**          | 16 bits    | Length of header and data.                       |
| **Checksum**        | 16 bits    | Error detection.                                 |
| **Data**            | Variable   | Application data.                                |

---

## **Layer 3: Network Layer**
- **Message Name**: **Packet**  
- **Function**:  
  Adds logical addressing (IP addresses) and routing information.  
- **Frame Format**:  

### **IPv4 Packet Format**
| Field                  | Size       | Description                                       |
|------------------------|------------|---------------------------------------------------|
| **Version**            | 4 bits     | IPv4 version identifier (value = 4).             |
| **Header Length (IHL)**| 4 bits     | Length of the header.                            |
| **Type of Service**    | 8 bits     | Priority and QoS bits.                           |
| **Total Length**       | 16 bits    | Total packet size.                               |
| **Identification**     | 16 bits    | Unique ID for fragment reassembly.               |
| **Flags**              | 3 bits     | Control bits (e.g., "More Fragments").           |
| **Fragment Offset**    | 13 bits    | Position of this fragment in the original data.  |
| **Time to Live (TTL)** | 8 bits     | Maximum hops the packet can take.                |
| **Protocol**           | 8 bits     | Higher-layer protocol (e.g., 6 for TCP).         |
| **Checksum**           | 16 bits    | Error detection for the header.                  |
| **Source IP**          | 32 bits    | Sender's IP address.                             |
| **Destination IP**     | 32 bits    | Receiver's IP address.                           |
| **Options**            | Variable   | Additional IP options.                           |
| **Data**               | Variable   | Encapsulated segment/datagram.                   |

---

## **Layer 2: Data Link Layer**
- **Message Name**: **Frame**  
- **Function**:  
  Adds physical addressing (MAC addresses) and error detection.  
- **Frame Format**:  

### **Ethernet Frame Format**
| Field                  | Size       | Description                                       |
|------------------------|------------|---------------------------------------------------|
| **Preamble**           | 7 bytes    | Synchronization for the receiver.                |
| **SFD (Start Frame)**  | 1 byte     | Indicates the start of the frame.                |
| **Destination MAC**    | 6 bytes    | Receiver's hardware address.                     |
| **Source MAC**         | 6 bytes    | Sender's hardware address.                       |
| **EtherType/Length**   | 2 bytes    | Indicates the encapsulated protocol (e.g., IPv4).|
| **Payload**            | 46–1500 bytes| Encapsulated packet.                            |
| **FCS (CRC)**          | 4 bytes    | Error detection.                                 |

---

## **Layer 1: Physical Layer**
- **Message Name**: **Bits**  
- **Function**:  
  Converts the frame into electrical signals, light pulses, or radio waves for transmission.  
- **Frame Format**:  
  No standard format, as data is now a continuous stream of **bits** (`0` and `1`).

---

### **Summary of Data at Each Layer**
| Layer           | Data Name       | Encapsulation Process                |
|------------------|-----------------|---------------------------------------|
| **Application** | Message         | Raw user data.                       |
| **Presentation**| Formatted Data  | Encodes/encrypts the message.         |
| **Session**     | Session Data    | Adds session control.                |
| **Transport**   | Segment/Datagram| Adds port numbers and reliability.   |
| **Network**     | Packet          | Adds IP addresses and routing info.  |
| **Data Link**   | Frame           | Adds MAC addresses and error checking.|
| **Physical**    | Bits            | Converts to physical signals.        |

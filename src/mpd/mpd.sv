// ------------------------------------------------------  MASTER PACKET DEALER  ----------------------------------------------

module mkMPD(

// -------------------------------------------------------  PORTS DECLARATION  ------------------------------------------------

  // Main system clock: Synchronizes the internal operations of the module
  input  logic CLK,
  // Active-low reset: Resets the internal states and logic of the module
  input  logic RST_N,
  // Ethernet RX clock: Synchronizes operations related to receiving data from the Ethernet PHY
  input  logic CLK_eth_mii_rx_clk,
  // Ethernet TX clock: Synchronizes operations related to transmitting data to the Ethernet PHY
  input  logic CLK_eth_mii_tx_clk,
  // Ethernet RX reset: Resets logic associated with the RX data path
  input  logic RST_N_eth_mii_rx_rstn,
  // Ethernet TX reset: Resets logic associated with the TX data path
  input  logic RST_N_eth_mii_tx_rstn,
  
  // Input RX data from Ethernet PHY (4 bits at a time): Captures incoming Ethernet data
  input  logic [3 : 0] eth_phy_eth_mii_rxd,
  // Input RX data valid signal: Indicates whether the incoming RX data is valid
  input  logic eth_phy_eth_mii_rx_dv,

  // Output TX data to Ethernet PHY (4 bits at a time): Sends processed Ethernet data
  output logic [3 : 0] eth_phy_eth_mii_txd,
  // Output TX enable signal: Indicates whether the transmitted data is valid and ready
  output logic eth_phy_eth_mii_tx_en,

  // Enables fetching of a header: When asserted, initiates the action to retrieve a header
  input  logic EN_get_header,
  // Outputs the fetched header (106 bits): Provides the retrieved header to external logic
  output logic [105 : 0] get_header,
  // Indicates readiness of the header: Signals that the header data is valid and available
  output logic RDY_get_header,

  // Accepts input for sending a result:
  // - `send_result_ethid_in`: Identifier of the Ethernet packet being processed
  // - `send_result_tag_in`: Metadata or tag associated with the result
  // - `send_result_result`: Status or result of the processing (e.g., pass, fail, etc.)
  input  logic send_result_ethid_in,
  input  logic send_result_tag_in,
  input  logic send_result_result,
  // Enables sending of a result: When asserted, initiates the process of sending the result
  input  logic EN_send_result,
  // Indicates readiness to send the result: Signals that the module is ready for the next result
  output logic RDY_send_result
);

//_____________________________________________________________________________________________________________________________

// -----------------------------  Inline wires for managing various enable and write signals  ---------------------------------

logic _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget;         // Wire for enabling unsafe PRT entries invalidation
logic _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget;  // Wire for enabling unsafe packet marking

// Register declarations for various control and data signals

// Slot currently being used to receive a packet
logic current_recv_packet_slot;
logic current_recv_packet_slot$D_IN; // Input data for the register
logic current_recv_packet_slot$EN;  // Enable signal for the register

// Flag indicating if the currently received packet is unsafe
logic currently_recv_packet_is_unsafe;
logic currently_recv_packet_is_unsafe$D_IN; // Input data for the flag
logic currently_recv_packet_is_unsafe$EN;  // Enable signal for the flag

// Availability of the header data
logic header_availability;
logic header_availability$D_IN; // Input data for the register
logic header_availability$EN;  // Enable signal for the register

// Current state of the frame reception
logic receive_frame_state;
logic receive_frame_state$D_IN; // Input data for the state register
logic receive_frame_state$EN;  // Enable signal for the state register

// Registers for storing header information
logic [31:0] rx_header_dstip;        // Destination IP address
logic [31:0] rx_header_dstip$D_IN;  // Input data for destination IP
logic rx_header_dstip$EN;           // Enable signal for destination IP

logic [15:0] rx_header_dstport;      // Destination port
logic [15:0] rx_header_dstport$D_IN; // Input data for destination port
logic rx_header_dstport$EN;          // Enable signal for destination port

logic [7:0] rx_header_protocol;      // Protocol information
logic [7:0] rx_header_protocol$D_IN; // Input data for protocol
logic rx_header_protocol$EN;         // Enable signal for protocol

logic [31:0] rx_header_srcip;        // Source IP address
logic [31:0] rx_header_srcip$D_IN;  // Input data for source IP
logic rx_header_srcip$EN;           // Enable signal for source IP

logic [15:0] rx_header_srcport;      // Source port
logic [15:0] rx_header_srcport$D_IN; // Input data for source port
logic rx_header_srcport$EN;          // Enable signal for source port

// Slot information for the current packet
logic [1:0] rx_slot;
logic [1:0] rx_slot$D_IN; // Input data for the slot
logic rx_slot$EN;         // Enable signal for the slot

// State for frame transmission
logic send_frame_state;
logic send_frame_state$D_IN; // Input data for the state
logic send_frame_state$EN;  // Enable signal for the state


// -------------------------------------------------------  PORTS FOR ETHERNET SUB MODULE  ------------------------------------------------

// Number of bytes sent for the current frame
logic [15:0] ethernet$mac_rx_m_get_bytes_sent; 

// Signals for managing read/write of frames
logic [7:0] ethernet$mac_rx_m_read_rx_frame, ethernet$mac_tx_m_write_tx_frame_data;
logic [3:0] ethernet$eth_mii_rxd, ethernet$eth_mii_txd;

// Enable, ready, and status signals for Ethernet operations
logic ethernet$EN_mac_rx_m_finished_reading_rx_frame;
logic ethernet$EN_mac_rx_m_read_rx_frame;
logic ethernet$EN_mac_rx_m_start_reading_rx_frame;
logic ethernet$EN_mac_rx_m_stop_receiving_current_frame;
logic ethernet$EN_mac_tx_m_write_tx_frame;
logic ethernet$RDY_mac_rx_m_finished_reading_rx_frame;
logic ethernet$RDY_mac_rx_m_read_rx_frame;
logic ethernet$RDY_mac_rx_m_start_reading_rx_frame;
logic ethernet$RDY_mac_rx_m_stop_receiving_current_frame;
logic ethernet$RDY_mac_tx_m_write_tx_frame;
logic ethernet$eth_mii_rx_dv; // MII RX data valid signal
logic ethernet$eth_mii_tx_en; // MII TX enable signal
logic ethernet$mac_rx_m_is_last_data_rcvd; // Flag for last data received
logic ethernet$mac_rx_m_is_new_frame_available; // Flag for new frame available
logic ethernet$mac_tx_m_ready_to_recv_next_frame; // Ready for next frame transmission
logic ethernet$mac_tx_m_write_tx_frame_is_last_byte; // Last byte flag for TX frame

  // ports of submodule fifo_to_firewall
  logic [105 : 0] fifo_to_firewall$D_IN, fifo_to_firewall$D_OUT; // The input and output data ports (each 106 bits wide) for the FIFO module connected to the firewall, used to transfer data.
  logic fifo_to_firewall$CLR,                               // Clear signal for the FIFO, used to reset or initialize the FIFO.
        fifo_to_firewall$DEQ,                               // Dequeue signal for the FIFO, used to remove data from the FIFO.
        fifo_to_firewall$EMPTY_N,                           // Empty signal for the FIFO (active low), indicates if the FIFO is empty.
        fifo_to_firewall$ENQ,                               // Enqueue signal for the FIFO, used to insert data into the FIFO.
        fifo_to_firewall$FULL_N;                            // Full signal for the FIFO (active low), indicates if the FIFO is full.

  // ports of submodule prt_table
  logic [8 : 0] prt_table$read_prt_entry;                   // Read pointer for the PRT (Packet Reference Table), used to read from a specific entry.
  logic [7 : 0] prt_table$write_prt_entry_data;             // Data to be written to the PRT entry (8 bits wide).
  logic prt_table$EN_finish_writing_prt_entry,              // Enable signal to finish writing a PRT entry.
        prt_table$EN_invalidate_prt_entry,                  // Enable signal to invalidate a PRT entry.
        prt_table$EN_read_prt_entry,                        // Enable signal to read a PRT entry.
        prt_table$EN_start_reading_prt_entry,                // Enable signal to start reading a PRT entry.
        prt_table$EN_start_writing_prt_entry,                // Enable signal to start writing a PRT entry.
        prt_table$EN_write_prt_entry,                        // Enable signal to write to a PRT entry.
        prt_table$RDY_finish_writing_prt_entry,              // Ready signal indicating the completion of writing a PRT entry.
        prt_table$RDY_read_prt_entry,                        // Ready signal indicating the availability of data for reading a PRT entry.
        prt_table$RDY_start_reading_prt_entry,                // Ready signal to start reading from the PRT entry.
        prt_table$RDY_start_writing_prt_entry,                // Ready signal to start writing to the PRT entry.
        prt_table$RDY_write_prt_entry,                        // Ready signal to confirm that a write operation to the PRT entry is complete.
        prt_table$invalidate_prt_entry_slot,                  // Signal used to invalidate a specific entry slot in the PRT.
        prt_table$is_prt_slot_free,                           // Indicates whether a particular PRT entry slot is free for use.
        prt_table$start_reading_prt_entry_slot,               // Signal to start reading from a specific slot in the PRT.
        prt_table$start_writing_prt_entry;                    // Signal to start writing to a specific slot in the PRT.

  // ports of submodule to_invalidate_fifo
  logic [2 : 0] to_invalidate_fifo$D_IN, to_invalidate_fifo$D_OUT; // Data input and output ports (3 bits wide) for the FIFO that handles invalidation operations.
  logic to_invalidate_fifo$CLR,                               // Clear signal for the invalidate FIFO.
        to_invalidate_fifo$DEQ,                               // Dequeue signal for removing data from the invalidate FIFO.
        to_invalidate_fifo$EMPTY_N,                           // Empty signal (active low) for the invalidate FIFO, indicates no data to process.
        to_invalidate_fifo$ENQ,                               // Enqueue signal to add data into the invalidate FIFO.
        to_invalidate_fifo$FULL_N;                            // Full signal (active low) for the invalidate FIFO, indicates the FIFO is at capacity.

  // ports of submodule to_send_fifo
  logic [2 : 0] to_send_fifo$D_IN, to_send_fifo$D_OUT;         // Data input and output ports (3 bits wide) for the send FIFO module used to queue data to be sent.
  logic to_send_fifo$CLR,                                      // Clear signal for the send FIFO.
        to_send_fifo$DEQ,                                      // Dequeue signal for removing data from the send FIFO.
        to_send_fifo$EMPTY_N,                                  // Empty signal (active low) for the send FIFO, indicates no data to send.
        to_send_fifo$ENQ,                                      // Enqueue signal to add data into the send FIFO.
        to_send_fifo$FULL_N;                                   // Full signal (active low) for the send FIFO, indicates the FIFO is at capacity.

  // rule scheduling signals
  logic CAN_FIRE_RL_invalidate_unsafe_prt_entries,              // Rule signal to invalidate unsafe PRT entries, indicating that the rule can fire.
        WILL_FIRE_RL_invalidate_currently_receiving_frame,      // Rule signal indicating the system will fire to invalidate the currently receiving frame.
        WILL_FIRE_RL_invalidate_unsafe_prt_entries,             // Rule signal indicating that the system will fire to invalidate unsafe PRT entries.
        WILL_FIRE_RL_push_header_into_firewall_fifo,            // Rule signal to push header data into the firewall FIFO.
        WILL_FIRE_RL_rx_check_prt_if_slot_available,            // Rule signal to check if a PRT entry slot is available for receiving data.
        WILL_FIRE_RL_rx_finish_geting_frame_data,               // Rule signal to finish gathering frame data.
        WILL_FIRE_RL_rx_get_frame_data,                         // Rule signal to retrieve frame data.
        WILL_FIRE_RL_tx_send_frame_data,                        // Rule signal to send frame data.
        WILL_FIRE_RL_tx_start_transmission;                     // Rule signal to initiate transmission of frame data.

  // inputs to muxes for submodule ports
  logic [1 : 0] MUX_rx_slot$write_1__VAL_1;                     // MUX input to write a value (2 bits) into the RX slot.
  logic MUX_currently_recv_packet_is_unsafe$write_1__SEL_1,      // MUX selector for selecting the currently received packet (unsafe).
        MUX_header_availability$write_1__SEL_1,                 // MUX selector to control header availability.
        MUX_prt_table$invalidate_prt_entry_1__SEL_1,             // MUX selector for invalidating a PRT entry.
        MUX_receive_frame_state$write_1__SEL_1,                  // MUX selector for the state of receiving the frame.
        MUX_send_frame_state$write_1__SEL_1;                     // MUX selector for the state of sending the frame.

  // declarations used by system tasks
  logic [63 : 0] v__h2933, v__h1642, v__h1701, v__h1750, v__h1799, v__h1848, v__h1897, v__h2685, v__h2495, v__h2184, v__h3134, v__h3148, v__h2797, v__h468, v__h1351; 
  // A set of 64-bit internal signals used by system tasks for processing or calculation purposes, potentially related to memory addresses or data values.

  // remaining internal signals
  logic [31 : 0] x__h1136, x__h1143, x__h1150, x__h1157, x__h1171, x__h1178, x__h1185, y__h1381, y__h1385, y__h1389; 
  // 32-bit internal signals for intermediate data manipulations or operations, likely used for specific processing within the design.
  
  logic [15 : 0] x__h1192, x__h1199, x__h1297, y__h1327;         // 16-bit internal signals for finer control or intermediate processing, used in operations or state transitions.
  
  logic to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144; // A specialized internal signal related to the first invalidation process in the FIFO, potentially used to handle specific conditions in the FSM (Finite State Machine).

  // value method eth_phy_mii_phy_tx_m_phy_txd
  assign eth_phy_eth_mii_txd = ethernet$eth_mii_txd ;

  // value method eth_phy_mii_phy_tx_m_phy_tx_en
  assign eth_phy_eth_mii_tx_en = ethernet$eth_mii_tx_en ;

  // actionvalue method get_header
  assign get_header = fifo_to_firewall$D_OUT ;
  assign RDY_get_header = fifo_to_firewall$EMPTY_N ;

  // action method send_result
  assign RDY_send_result = to_send_fifo$FULL_N && to_invalidate_fifo$FULL_N ;
  
//_____________________________________________________________________________________________________________________________

// ---------------------------------------------------  SUB MODULES INSTANCIATION  --------------------------------------------
 
 
// ------------------------------------------------------  ETHERNET SUB MODULE  -----------------------------------------------
 
// Submodule: Ethernet
// This instantiates the Ethernet module with necessary signal connections for MII (Media Independent Interface)
// and handling the transmission and reception of Ethernet frames.
mkEthIP ethernet(
  .CLK_eth_mii_rx_clk(CLK_eth_mii_rx_clk), // MII receive clock
  .CLK_eth_mii_tx_clk(CLK_eth_mii_tx_clk), // MII transmit clock
  .RST_N_eth_mii_rx_rstn(RST_N_eth_mii_rx_rstn), // Reset signal for MII receive interface (active low)
  .RST_N_eth_mii_tx_rstn(RST_N_eth_mii_tx_rstn), // Reset signal for MII transmit interface (active low)
  .CLK(CLK), // Main clock
  .RST_N(RST_N), // Main reset signal (active low)
  .eth_mii_rx_dv(ethernet$eth_mii_rx_dv), // Ethernet MII receive data valid signal
  .eth_mii_rxd(ethernet$eth_mii_rxd), // Ethernet MII received data
  .mac_tx_m_write_tx_frame_data(ethernet$mac_tx_m_write_tx_frame_data), // Data to be written for transmission
  .mac_tx_m_write_tx_frame_is_last_byte(ethernet$mac_tx_m_write_tx_frame_is_last_byte), // Flag for the last byte in frame
  .EN_mac_rx_m_start_reading_rx_frame(ethernet$EN_mac_rx_m_start_reading_rx_frame), // Enable to start reading receive frame
  .EN_mac_rx_m_read_rx_frame(ethernet$EN_mac_rx_m_read_rx_frame), // Enable to read the received frame
  .EN_mac_rx_m_finished_reading_rx_frame(ethernet$EN_mac_rx_m_finished_reading_rx_frame), // Enable when finished reading
  .EN_mac_rx_m_stop_receiving_current_frame(ethernet$EN_mac_rx_m_stop_receiving_current_frame), // Stop receiving current frame
  .EN_mac_tx_m_write_tx_frame(ethernet$EN_mac_tx_m_write_tx_frame), // Enable to write transmit frame
  .mac_rx_m_is_new_frame_available(ethernet$mac_rx_m_is_new_frame_available), // Flag indicating new frame available
  .RDY_mac_rx_m_is_new_frame_available(), // Ready signal for new frame availability
  .mac_rx_m_is_last_data_rcvd(ethernet$mac_rx_m_is_last_data_rcvd), // Flag indicating last data is received
  .RDY_mac_rx_m_is_last_data_rcvd(), // Ready signal for last data received
  .RDY_mac_rx_m_start_reading_rx_frame(ethernet$RDY_mac_rx_m_start_reading_rx_frame), // Ready signal to start reading frame
  .mac_rx_m_read_rx_frame(ethernet$mac_rx_m_read_rx_frame), // Read received frame signal
  .RDY_mac_rx_m_read_rx_frame(ethernet$RDY_mac_rx_m_read_rx_frame), // Ready signal for reading received frame
  .RDY_mac_rx_m_finished_reading_rx_frame(ethernet$RDY_mac_rx_m_finished_reading_rx_frame), // Ready signal when reading is finished
  .RDY_mac_rx_m_stop_receiving_current_frame(ethernet$RDY_mac_rx_m_stop_receiving_current_frame), // Ready signal to stop receiving frame
  .mac_rx_m_get_bytes_sent(ethernet$mac_rx_m_get_bytes_sent), // Get number of bytes sent signal
  .RDY_mac_rx_m_get_bytes_sent(), // Ready signal for bytes sent
  .eth_mii_txd(ethernet$eth_mii_txd), // Ethernet MII transmit data
  .eth_mii_tx_en(ethernet$eth_mii_tx_en), // Ethernet MII transmit enable
  .mac_tx_m_ready_to_recv_next_frame(ethernet$mac_tx_m_ready_to_recv_next_frame), // Ready to receive next frame
  .RDY_mac_tx_m_ready_to_recv_next_frame(), // Ready signal for next frame reception
  .RDY_mac_tx_m_write_tx_frame(ethernet$RDY_mac_tx_m_write_tx_frame) // Ready signal for transmitting next frame
); 

// -----------------------------------------------  FIFO TO FIREWALL SUB MODULE  ------------------------------------------
// This FIFO module connects to the firewall, with a width of 106 bits, for queuing data and handling the FIFO logic.
FIFO2 #(.width(32'd106), .guarded(1'd1)) fifo_to_firewall(
  .RST(RST_N), // Reset signal (active low)
  .CLK(CLK), // Main clock
  .D_IN(fifo_to_firewall$D_IN), // Data input to FIFO
  .ENQ(fifo_to_firewall$ENQ), // Enable to enqueue data
  .DEQ(fifo_to_firewall$DEQ), // Enable to dequeue data
  .CLR(fifo_to_firewall$CLR), // Clear FIFO signal
  .D_OUT(fifo_to_firewall$D_OUT), // Data output from FIFO
  .FULL_N(fifo_to_firewall$FULL_N), // Flag for FIFO full (active low)
  .EMPTY_N(fifo_to_firewall$EMPTY_N) // Flag for FIFO empty (active low)
);

// ------------------------------------------------------  PRT SUB MODULE  ------------------------------------------------
// This module is responsible for managing the Packet Reference Table (PRT) entries, with functionalities such as
// reading, writing, invalidating, and starting/stopping entry operations.
mkPRT prt_table(
  .CLK(CLK), // Main clock
  .RST_N(RST_N), // Main reset signal (active low)
  .invalidate_prt_entry_slot(prt_table$invalidate_prt_entry_slot), // Signal to invalidate PRT entry
  .start_reading_prt_entry_slot(prt_table$start_reading_prt_entry_slot), // Start reading PRT entry
  .write_prt_entry_data(prt_table$write_prt_entry_data), // Data to write into PRT entry
  .EN_start_writing_prt_entry(prt_table$EN_start_writing_prt_entry), // Enable to start writing PRT entry
  .EN_write_prt_entry(prt_table$EN_write_prt_entry), // Enable to write PRT entry
  .EN_finish_writing_prt_entry(prt_table$EN_finish_writing_prt_entry), // Enable to finish writing PRT entry
  .EN_invalidate_prt_entry(prt_table$EN_invalidate_prt_entry), // Enable to invalidate PRT entry
  .EN_start_reading_prt_entry(prt_table$EN_start_reading_prt_entry), // Enable to start reading PRT entry
  .EN_read_prt_entry(prt_table$EN_read_prt_entry), // Enable to read PRT entry
  .start_writing_prt_entry(prt_table$start_writing_prt_entry), // Start writing PRT entry
  .RDY_start_writing_prt_entry(prt_table$RDY_start_writing_prt_entry), // Ready signal for writing PRT entry
  .RDY_write_prt_entry(prt_table$RDY_write_prt_entry), // Ready signal for write PRT entry
  .RDY_finish_writing_prt_entry(prt_table$RDY_finish_writing_prt_entry), // Ready signal for finishing writing
  .RDY_invalidate_prt_entry(), // Ready signal for invalidating PRT entry
  .RDY_start_reading_prt_entry(prt_table$RDY_start_reading_prt_entry), // Ready signal for reading PRT entry
  .read_prt_entry(prt_table$read_prt_entry), // Signal to read a PRT entry
  .RDY_read_prt_entry(prt_table$RDY_read_prt_entry), // Ready signal for reading PRT entry
  .is_prt_slot_free(prt_table$is_prt_slot_free), // Flag indicating if a PRT slot is free
  .RDY_is_prt_slot_free() // Ready signal for checking if PRT slot is free
);

// ------------------------------------------------------  TO INVALIDATE FIFO  ----------------------------------------------
// A FIFO module to handle invalidation requests for entries. It has a width of 3 bits and includes enabling and
// clearing signals.
FIFO2 #(.width(32'd3), .guarded(1'd1)) to_invalidate_fifo(
  .RST(RST_N), // Reset signal (active low)
  .CLK(CLK), // Main clock
  .D_IN(to_invalidate_fifo$D_IN), // Data input to FIFO
  .ENQ(to_invalidate_fifo$ENQ), // Enable to enqueue data
  .DEQ(to_invalidate_fifo$DEQ), // Enable to dequeue data
  .CLR(to_invalidate_fifo$CLR), // Clear FIFO signal
  .D_OUT(to_invalidate_fifo$D_OUT), // Data output from FIFO
  .FULL_N(to_invalidate_fifo$FULL_N), // Flag for FIFO full (active low)
  .EMPTY_N(to_invalidate_fifo$EMPTY_N) // Flag for FIFO empty (active low)
);

// ---------------------------------------------------------  TO SEND FIFO  -------------------------------------------------
// A FIFO module to handle sending operations. It has a width of 3 bits and includes enabling and clearing signals.
FIFO2 #(.width(32'd3), .guarded(1'd1)) to_send_fifo(
  .RST(RST_N), // Reset signal (active low)
  .CLK(CLK), // Main clock
  .D_IN(to_send_fifo$D_IN), // Data input to FIFO
  .ENQ(to_send_fifo$ENQ), // Enable to enqueue data
  .DEQ(to_send_fifo$DEQ), // Enable to dequeue data
  .CLR(to_send_fifo$CLR), // Clear FIFO signal
  .D_OUT(to_send_fifo$D_OUT), // Data output from FIFO
  .FULL_N(to_send_fifo$FULL_N), // Flag for FIFO full (active low)
  .EMPTY_N(to_send_fifo$EMPTY_N) // Flag for FIFO empty (active low)
);

//_____________________________________________________________________________________________________________________________

  // rule RL_push_header_into_firewall_fifo
  assign WILL_FIRE_RL_push_header_into_firewall_fifo = fifo_to_firewall$FULL_N && !header_availability ;

  // rule RL_tx_start_transmission
  assign WILL_FIRE_RL_tx_start_transmission = prt_table$RDY_start_reading_prt_entry && to_send_fifo$EMPTY_N && !send_frame_state && ethernet$mac_tx_m_ready_to_recv_next_frame ;

  // rule RL_invalidate_currently_receiving_frame
  assign WILL_FIRE_RL_invalidate_currently_receiving_frame = ethernet$RDY_mac_rx_m_stop_receiving_current_frame && currently_recv_packet_is_unsafe ;

  // rule RL_invalidate_unsafe_prt_entries
  assign CAN_FIRE_RL_invalidate_unsafe_prt_entries = to_invalidate_fifo$EMPTY_N && !WILL_FIRE_RL_invalidate_currently_receiving_frame ;
  assign WILL_FIRE_RL_invalidate_unsafe_prt_entries = CAN_FIRE_RL_invalidate_unsafe_prt_entries && !WILL_FIRE_RL_invalidate_currently_receiving_frame ;

  // rule RL_tx_send_frame_data
  assign WILL_FIRE_RL_tx_send_frame_data = ethernet$RDY_mac_tx_m_write_tx_frame && prt_table$RDY_read_prt_entry && send_frame_state ;

  // rule RL_rx_finish_geting_frame_data
  assign WILL_FIRE_RL_rx_finish_geting_frame_data = ethernet$RDY_mac_rx_m_finished_reading_rx_frame && prt_table$RDY_finish_writing_prt_entry && receive_frame_state && !currently_recv_packet_is_unsafe && header_availability && ethernet$mac_rx_m_is_last_data_rcvd ;

  // rule RL_rx_check_prt_if_slot_available
  assign WILL_FIRE_RL_rx_check_prt_if_slot_available = ethernet$RDY_mac_rx_m_start_reading_rx_frame && prt_table$RDY_start_writing_prt_entry && !receive_frame_state && !WILL_FIRE_RL_invalidate_unsafe_prt_entries && !WILL_FIRE_RL_invalidate_currently_receiving_frame ;

  // rule RL_rx_get_frame_data
  assign WILL_FIRE_RL_rx_get_frame_data = ethernet$RDY_mac_rx_m_read_rx_frame && prt_table$RDY_write_prt_entry && receive_frame_state && !currently_recv_packet_is_unsafe && header_availability && !ethernet$mac_rx_m_is_last_data_rcvd ;

  // inputs to muxes for submodule ports
  assign MUX_currently_recv_packet_is_unsafe$write_1__SEL_1 = WILL_FIRE_RL_invalidate_unsafe_prt_entries && to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1] ;
  assign MUX_header_availability$write_1__SEL_1 = WILL_FIRE_RL_rx_get_frame_data && ethernet$mac_rx_m_get_bytes_sent == 16'd37 ;
  assign MUX_prt_table$invalidate_prt_entry_1__SEL_1 = WILL_FIRE_RL_invalidate_unsafe_prt_entries && (!to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1]) ;
  assign MUX_receive_frame_state$write_1__SEL_1 = WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && ethernet$mac_rx_m_is_new_frame_available ;
  assign MUX_send_frame_state$write_1__SEL_1 = WILL_FIRE_RL_tx_send_frame_data && prt_table$read_prt_entry[0] ;
  assign MUX_rx_slot$write_1__VAL_1 = { 1'd1, prt_table$start_writing_prt_entry } ;

  // inlined wires
  assign _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget = !to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1] ;
  assign _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget = to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1] ;

  // register current_recv_packet_slot
  assign current_recv_packet_slot$D_IN = rx_slot[0] ;
  assign current_recv_packet_slot$EN = MUX_currently_recv_packet_is_unsafe$write_1__SEL_1 ;

  // register currently_recv_packet_is_unsafe
  assign currently_recv_packet_is_unsafe$D_IN = MUX_currently_recv_packet_is_unsafe$write_1__SEL_1 ;
  assign currently_recv_packet_is_unsafe$EN = WILL_FIRE_RL_invalidate_unsafe_prt_entries && to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1] || WILL_FIRE_RL_invalidate_currently_receiving_frame ;

  // register header_availability
  assign header_availability$D_IN = !MUX_header_availability$write_1__SEL_1 ;
  assign header_availability$EN = WILL_FIRE_RL_rx_get_frame_data && ethernet$mac_rx_m_get_bytes_sent == 16'd37 || WILL_FIRE_RL_push_header_into_firewall_fifo ;

  // register receive_frame_state
  assign receive_frame_state$D_IN = MUX_receive_frame_state$write_1__SEL_1 ;
  assign receive_frame_state$EN = WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && ethernet$mac_rx_m_is_new_frame_available || WILL_FIRE_RL_invalidate_currently_receiving_frame || WILL_FIRE_RL_rx_finish_geting_frame_data ;

  // register rx_header_dstip
  always@(ethernet$mac_rx_m_get_bytes_sent or x__h1185 or x__h1136 or x__h1171 or x__h1178)
  begin
    case (ethernet$mac_rx_m_get_bytes_sent)
      16'd30: rx_header_dstip$D_IN = x__h1136;
      16'd31: rx_header_dstip$D_IN = x__h1171;
      16'd32: rx_header_dstip$D_IN = x__h1178;
      default: rx_header_dstip$D_IN = x__h1185;
    endcase
  end
  assign rx_header_dstip$EN = WILL_FIRE_RL_rx_get_frame_data && (ethernet$mac_rx_m_get_bytes_sent == 16'd30 || ethernet$mac_rx_m_get_bytes_sent == 16'd31 || ethernet$mac_rx_m_get_bytes_sent == 16'd32 || ethernet$mac_rx_m_get_bytes_sent == 16'd33) ;

  // register rx_header_dstport
  assign rx_header_dstport$D_IN = (ethernet$mac_rx_m_get_bytes_sent == 16'd36) ? x__h1192 : x__h1297 ;
  assign rx_header_dstport$EN = WILL_FIRE_RL_rx_get_frame_data && (ethernet$mac_rx_m_get_bytes_sent == 16'd36 || ethernet$mac_rx_m_get_bytes_sent == 16'd37) ;

  // register rx_header_protocol
  assign rx_header_protocol$D_IN = ethernet$mac_rx_m_read_rx_frame ;
  assign rx_header_protocol$EN = WILL_FIRE_RL_rx_get_frame_data && ethernet$mac_rx_m_get_bytes_sent == 16'd23 ;

  // register rx_header_srcip
  always@(ethernet$mac_rx_m_get_bytes_sent or x__h1157 or x__h1136 or x__h1143 or x__h1150)
  begin
    case (ethernet$mac_rx_m_get_bytes_sent)
      16'd26: rx_header_srcip$D_IN = x__h1136;
      16'd27: rx_header_srcip$D_IN = x__h1143;
      16'd28: rx_header_srcip$D_IN = x__h1150;
      default: rx_header_srcip$D_IN = x__h1157;
    endcase
  end
  assign rx_header_srcip$EN = WILL_FIRE_RL_rx_get_frame_data && (ethernet$mac_rx_m_get_bytes_sent == 16'd26 || ethernet$mac_rx_m_get_bytes_sent == 16'd27 || ethernet$mac_rx_m_get_bytes_sent == 16'd28 || ethernet$mac_rx_m_get_bytes_sent == 16'd29) ;

  // register rx_header_srcport
  assign rx_header_srcport$D_IN = (ethernet$mac_rx_m_get_bytes_sent == 16'd34) ? x__h1192 : x__h1199 ;
  assign rx_header_srcport$EN = WILL_FIRE_RL_rx_get_frame_data && (ethernet$mac_rx_m_get_bytes_sent == 16'd34 || ethernet$mac_rx_m_get_bytes_sent == 16'd35) ;

  // register rx_slot
  assign rx_slot$D_IN = MUX_receive_frame_state$write_1__SEL_1 ? MUX_rx_slot$write_1__VAL_1 : 2'd0 ;
  assign rx_slot$EN = WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && ethernet$mac_rx_m_is_new_frame_available || WILL_FIRE_RL_invalidate_currently_receiving_frame || WILL_FIRE_RL_rx_finish_geting_frame_data ;

  // register send_frame_state
  assign send_frame_state$D_IN = !MUX_send_frame_state$write_1__SEL_1 ;
  assign send_frame_state$EN = WILL_FIRE_RL_tx_send_frame_data && prt_table$read_prt_entry[0] || WILL_FIRE_RL_tx_start_transmission ;

  // submodule ethernet
  assign ethernet$eth_mii_rx_dv = eth_phy_eth_mii_rx_dv ;
  assign ethernet$eth_mii_rxd = eth_phy_eth_mii_rxd ;
  assign ethernet$mac_tx_m_write_tx_frame_data = prt_table$read_prt_entry[8:1] ;
  assign ethernet$mac_tx_m_write_tx_frame_is_last_byte = prt_table$read_prt_entry[0] ;
  assign ethernet$EN_mac_rx_m_start_reading_rx_frame = MUX_receive_frame_state$write_1__SEL_1 ;
  assign ethernet$EN_mac_rx_m_read_rx_frame = WILL_FIRE_RL_rx_get_frame_data ;
  assign ethernet$EN_mac_rx_m_finished_reading_rx_frame = WILL_FIRE_RL_rx_finish_geting_frame_data ;
  assign ethernet$EN_mac_rx_m_stop_receiving_current_frame = WILL_FIRE_RL_invalidate_currently_receiving_frame ;
  assign ethernet$EN_mac_tx_m_write_tx_frame = WILL_FIRE_RL_tx_send_frame_data ;

  // submodule fifo_to_firewall
  assign fifo_to_firewall$D_IN = { 1'd0, rx_slot[0], rx_header_protocol, rx_header_srcip, rx_header_dstip, rx_header_srcport, rx_header_dstport } ;
  assign fifo_to_firewall$ENQ = WILL_FIRE_RL_push_header_into_firewall_fifo ;
  assign fifo_to_firewall$DEQ = EN_get_header ;
  assign fifo_to_firewall$CLR = 1'b0 ;

  // submodule prt_table
  assign prt_table$invalidate_prt_entry_slot = MUX_prt_table$invalidate_prt_entry_1__SEL_1 ? to_invalidate_fifo$D_OUT[1] : current_recv_packet_slot ;
  assign prt_table$start_reading_prt_entry_slot = to_send_fifo$D_OUT[1] ;
  assign prt_table$write_prt_entry_data = ethernet$mac_rx_m_read_rx_frame ;
  assign prt_table$EN_start_writing_prt_entry = MUX_receive_frame_state$write_1__SEL_1 ;
  assign prt_table$EN_write_prt_entry = WILL_FIRE_RL_rx_get_frame_data ;
  assign prt_table$EN_finish_writing_prt_entry = WILL_FIRE_RL_rx_finish_geting_frame_data ;
  assign prt_table$EN_invalidate_prt_entry = WILL_FIRE_RL_invalidate_unsafe_prt_entries && (!to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1]) || WILL_FIRE_RL_invalidate_currently_receiving_frame ;
  assign prt_table$EN_start_reading_prt_entry = WILL_FIRE_RL_tx_start_transmission ;
  assign prt_table$EN_read_prt_entry = WILL_FIRE_RL_tx_send_frame_data ;

  // submodule to_invalidate_fifo
  assign to_invalidate_fifo$D_IN = { send_result_ethid_in, send_result_tag_in, send_result_result } ;
  assign to_invalidate_fifo$ENQ = EN_send_result && !send_result_result ;
  assign to_invalidate_fifo$DEQ = WILL_FIRE_RL_invalidate_unsafe_prt_entries ;
  assign to_invalidate_fifo$CLR = 1'b0 ;

  // submodule to_send_fifo
  assign to_send_fifo$D_IN = { send_result_ethid_in, send_result_tag_in, send_result_result } ;
  assign to_send_fifo$ENQ = EN_send_result && send_result_result ;
  assign to_send_fifo$DEQ = WILL_FIRE_RL_tx_start_transmission ;
  assign to_send_fifo$CLR = 1'b0 ;

  // remaining internal signals
  assign to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 = to_invalidate_fifo$D_OUT[1] == rx_slot[0] ;
  assign x__h1136 = { ethernet$mac_rx_m_read_rx_frame, 24'd0 } ;
  assign x__h1143 = rx_header_srcip | y__h1381 ;
  assign x__h1150 = rx_header_srcip | y__h1385 ;
  assign x__h1157 = rx_header_srcip | y__h1389 ;
  assign x__h1171 = rx_header_dstip | y__h1381 ;
  assign x__h1178 = rx_header_dstip | y__h1385 ;
  assign x__h1185 = rx_header_dstip | y__h1389 ;
  assign x__h1192 = { ethernet$mac_rx_m_read_rx_frame, 8'b0 } ;
  assign x__h1199 = rx_header_srcport | y__h1327 ;
  assign x__h1297 = rx_header_dstport | y__h1327 ;
  assign y__h1327 = { 8'b0, ethernet$mac_rx_m_read_rx_frame } ;
  assign y__h1381 = { 8'b0, ethernet$mac_rx_m_read_rx_frame, 16'd0 } ;
  assign y__h1385 = { 16'd0, x__h1192 } ;
  assign y__h1389 = { 24'd0, ethernet$mac_rx_m_read_rx_frame } ;

  // handling of inlined registers

  always @(posedge CLK) begin
  if (!RST_N) begin
    current_recv_packet_slot <= '0;
    currently_recv_packet_is_unsafe <= '0;
    header_availability <= 1'b1; // Note: This is '1' in the reset
    receive_frame_state <= '0;
    rx_header_dstip <= 32'hAAAAAAAA;
    rx_header_dstport <= 16'hAAAA;
    rx_header_protocol <= 8'hAA;
    rx_header_srcip <= 32'hAAAAAAAA;
    rx_header_srcport <= 16'hAAAA;
    rx_slot <= '0;
    send_frame_state <= '0;
  end else begin
    if (current_recv_packet_slot$EN) current_recv_packet_slot <= current_recv_packet_slot$D_IN;
    if (currently_recv_packet_is_unsafe$EN) currently_recv_packet_is_unsafe <= currently_recv_packet_is_unsafe$D_IN;
    if (header_availability$EN) header_availability <= header_availability$D_IN;
    if (receive_frame_state$EN) receive_frame_state <= receive_frame_state$D_IN;
    if (rx_header_dstip$EN) rx_header_dstip <= rx_header_dstip$D_IN;
    if (rx_header_dstport$EN) rx_header_dstport <= rx_header_dstport$D_IN;
    if (rx_header_protocol$EN) rx_header_protocol <= rx_header_protocol$D_IN;
    if (rx_header_srcip$EN) rx_header_srcip <= rx_header_srcip$D_IN;
    if (rx_header_srcport$EN) rx_header_srcport <= rx_header_srcport$D_IN;
    if (rx_slot$EN) rx_slot <= rx_slot$D_IN;
    if (send_frame_state$EN) send_frame_state <= send_frame_state$D_IN;
  end
end

initial begin
  current_recv_packet_slot <= '0; // Use non-blocking assignments in initial block
  currently_recv_packet_is_unsafe <= '0;
  header_availability <= 1'b1; // Consistent with reset value
  receive_frame_state <= '0;
  rx_header_dstip <= 32'hAAAAAAAA;
  rx_header_dstport <= 16'hAAAA;
  rx_header_protocol <= 8'hAA;
  rx_header_srcip <= 32'hAAAAAAAA;
  rx_header_srcport <= 16'hAAAA;
  rx_slot <= '0;
  send_frame_state <= '0;
end

  // handling of system tasks

always_ff @(negedge CLK) begin : debug_block // Named the block for clarity
  if (!RST_N) begin
    if (EN_get_header) begin
      v__h2933 = $time; // Declare and assign in one step
      $display("%0t: MPD: Method: get_header. Firewall receives header from MPD", v__h2933);
    end

    if (WILL_FIRE_RL_push_header_into_firewall_fifo) begin
      $display("\n"); // Just a newline

      v__h1642 = $time;
      $display("%0t: MPD: Pushing header of frame in slot %d into firewall FIFO", v__h1642, rx_slot[0]);

      v__h1701 = $time;
      $display("%0t: MPD: Protocol: %h", v__h1701, rx_header_protocol);

      v__h1750 = $time;
      $display("%0t: MPD: Src IP: %h", v__h1750, rx_header_srcip);

      v__h1799 = $time;
      $display("%0t: MPD: Dst IP: %h", v__h1799, rx_header_dstip);

      v__h1848 = $time;
      $display("%0t: MPD: Src Port: %h", v__h1848, rx_header_srcport);

      v__h1897 = $time;
      $display("%0t: MPD: Dst Port: %h", v__h1897, rx_header_dstport);
      $display("\n");
    end

    if (WILL_FIRE_RL_tx_start_transmission) begin
      v__h2685 = $time;
      $display("%0t: MPD: Rule: tx_start_transmission. Start transmission of frame from slot %d", v__h2685, to_send_fifo$D_OUT[1]);
    end

    if (WILL_FIRE_RL_invalidate_currently_receiving_frame) begin
      v__h2495 = $time;
      $display("%0t: MPD: Rule: invalidate_unsafe_prt_entries. Currently receiving frame at slot %d is invalidated", v__h2495, rx_slot[0]);
    end

    if (WILL_FIRE_RL_invalidate_unsafe_prt_entries) begin
      v__h2184 = $time;
      $display("%0t: MPD: Rule: invalidate_unsafe_prt_entries. Slot %d is UNSAFE. Sending invalidate signal to PRT", v__h2184, to_invalidate_fifo$D_OUT[1]);
    end

    if (EN_send_result && send_result_result) begin
      v__h3134 = $time;
      $display("%0t: MPD: Method: send_result. Firewall sends header response to MPD. Indicates frame at slot %d is SAFE", v__h3134, send_result_tag_in);
    end

    if (EN_send_result && !send_result_result) begin
      v__h3148 = $time;
      $display("%0t: MPD: Method: send_result. Firewall sends header response to MPD. Indicates frame at slot %d is UNSAFE", v__h3148, send_result_tag_in);
    end

    if (WILL_FIRE_RL_tx_send_frame_data && prt_table$read_prt_entry[0]) begin
      v__h2797 = $time;
      $display("%0t: MPD: Rule: tx_send_frame_data. Entire frame transmitted to Ethernet Transactor", v__h2797);
    end


    // Error displays
    if (WILL_FIRE_RL_tx_send_frame_data && WILL_FIRE_RL_invalidate_currently_receiving_frame)
      $display("Error: ... (R0002) Conflict-free rules RL_tx_send_frame_data and RL_invalidate_currently_receiving_frame called conflicting methods read_prt_entry and invalidate_prt_entry of module instance prt_table.");

    if (WILL_FIRE_RL_tx_send_frame_data && WILL_FIRE_RL_invalidate_unsafe_prt_entries && _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods read_prt_entry and invalidate_prt_entry of module instance prt_table.");

    if (WILL_FIRE_RL_rx_finish_geting_frame_data && WILL_FIRE_RL_invalidate_unsafe_prt_entries && _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods finish_writing_prt_entry and invalidate_prt_entry of module instance prt_table.");

    if (WILL_FIRE_RL_rx_finish_geting_frame_data && WILL_FIRE_RL_invalidate_unsafe_prt_entries && prt_table$RDY_finish_writing_prt_entry && ethernet$RDY_mac_rx_m_finished_reading_rx_frame && ethernet$mac_rx_m_is_last_data_rcvd && receive_frame_state && header_availability && _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods read and write of module instance currently_recv_packet_is_unsafe.");

    if (WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && ethernet$mac_rx_m_is_new_frame_available) begin
      v__h468 = $time;
      $display("%0t: MPD: Rule: rx_check_prt_if_slot_available. PRT Slot available. Requesting Transactor 0 to start receiving", v__h468);
    end

    if (WILL_FIRE_RL_rx_check_prt_if_slot_available && WILL_FIRE_RL_tx_send_frame_data && prt_table$is_prt_slot_free && ethernet$mac_rx_m_is_new_frame_available)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods start_writing_prt_entry and read_prt_entry of module instance prt_table.");

    if (WILL_FIRE_RL_rx_get_frame_data && ethernet$mac_rx_m_get_bytes_sent == 16'd23) begin
      v__h1351 = $time;
      $display("%0t: MPD: Rule: rx_get_frame_data. Protocol: %h", v__h1351, ethernet$mac_rx_m_read_rx_frame);
    end

    if (WILL_FIRE_RL_rx_get_frame_data && WILL_FIRE_RL_invalidate_unsafe_prt_entries && _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods write_prt_entry and invalidate_prt_entry of module instance prt_table.");

    if (WILL_FIRE_RL_rx_get_frame_data && WILL_FIRE_RL_invalidate_unsafe_prt_entries && !ethernet$mac_rx_m_is_last_data_rcvd && prt_table$RDY_write_prt_entry && ethernet$RDY_mac_rx_m_read_rx_frame && receive_frame_state && header_availability && _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget)
      $display("Error: ... (R0002) Conflict-free rules ... called conflicting methods read and write of module instance currently_recv_packet_is_unsafe.\n");
  end
 end
  
endmodule  // mkMPD

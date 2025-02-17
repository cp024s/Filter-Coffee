  `timescale 1ns / 1ps
// ==========================================================================
//                         MASTER PACKET DEALER
// ==========================================================================
module mkMPD(
  // Global Clock and Reset
  input  logic CLK,
  input  logic RST_N,
  
  //------------------------------------------------------------------------
  // Ethernet AXI-Stream Receive Interface (replacing MII Rx signals)
  //------------------------------------------------------------------------
  input  logic [7:0] rx_axis_tdata,   // Incoming data byte from Ethernet
  input  logic       rx_axis_tvalid,  // Data valid
  output logic       rx_axis_tready,  // Ready to accept data
  input  logic       rx_axis_tlast,   // End-of-frame indicator
  input  logic       rx_axis_tuser,   // Error flag, if any

  //------------------------------------------------------------------------
  // Ethernet AXI-Stream Transmit Interface (replacing MII Tx signals)
  //------------------------------------------------------------------------
  output logic [7:0] tx_axis_tdata,   // Outgoing data byte to Ethernet
  output logic       tx_axis_tvalid,  // Data valid
  input  logic       tx_axis_tready,  // Downstream ready signal
  output logic       tx_axis_tlast,   // End-of-frame indicator
  output logic       tx_axis_tuser,   // User flag (if needed)

  //------------------------------------------------------------------------
  // Firewall Header Interface (AXI-Stream Master)
  //  This port replaces the original "get_header" action-value method.
  //------------------------------------------------------------------------
  output logic [105:0] m_axis_header_tdata,
  output logic         m_axis_header_tvalid,
  input  logic         m_axis_header_tready,
  
  //------------------------------------------------------------------------
  // Firewall Result Interface (AXI-Stream Slave)
  //  This port replaces the original "send_result" action method.
  //  The 3-bit word is assumed to pack {send_result_ethid, send_result_tag, send_result_result}
  //------------------------------------------------------------------------
  input  logic [2:0]   s_axis_result_tdata,
  input  logic         s_axis_result_tvalid,
  output logic         s_axis_result_tready
);

  //=======================================================================
  // INTERNAL SIGNAL DECLARATIONS
  //=======================================================================
  
  // Inlined wires from original design (unchanged names)
  logic _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget;
  logic _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget;

  // Registers for tracking packet/slot states (as in the original code)
  logic current_recv_packet_slot;
  logic current_recv_packet_slot$D_IN;
  logic current_recv_packet_slot$EN;

  logic currently_recv_packet_is_unsafe;
  logic currently_recv_packet_is_unsafe$D_IN;
  logic currently_recv_packet_is_unsafe$EN;

  logic header_availability;
  logic header_availability$D_IN;
  logic header_availability$EN;

  logic receive_frame_state;
  logic receive_frame_state$D_IN;
  logic receive_frame_state$EN;

  logic [31:0] rx_header_dstip;
  logic [31:0] rx_header_dstip$D_IN;
  logic rx_header_dstip$EN;

  logic [15:0] rx_header_dstport;
  logic [15:0] rx_header_dstport$D_IN;
  logic rx_header_dstport$EN;

  logic [7:0] rx_header_protocol;
  logic [7:0] rx_header_protocol$D_IN;
  logic rx_header_protocol$EN;

  logic [31:0] rx_header_srcip;
  logic [31:0] rx_header_srcip$D_IN;
  logic rx_header_srcip$EN;

  logic [15:0] rx_header_srcport;
  logic [15:0] rx_header_srcport$D_IN;
  logic rx_header_srcport$EN;

  logic [1:0] rx_slot;
  logic [1:0] rx_slot$D_IN;
  logic rx_slot$EN;

  logic send_frame_state;
  logic send_frame_state$D_IN;
  logic send_frame_state$EN;
  
  //-------------------------------------------------------
  // AXI-Stream Ethernet Interface Support
  //-------------------------------------------------------
  // A byte counter to track the number of bytes received on the AXI-Stream RX.
  // This replaces the old ethernet$mac_rx_m_get_bytes_sent signal.
  logic [15:0] rx_byte_count;
  
  // TX internal registers for driving the AXI-Stream TX interface
  logic [7:0]  tx_byte_reg;
  logic        tx_valid_reg;
  logic        tx_last_reg;

  //-------------------------------------------------------
  // FIFO Interfaces (unchanged widths)
  //-------------------------------------------------------
  // FIFO for header information to be sent to the firewall.
  logic [105:0] fifo_to_firewall$D_IN, fifo_to_firewall$D_OUT;
  logic         fifo_to_firewall$ENQ, fifo_to_firewall$DEQ;
  logic         fifo_to_firewall$FULL_N, fifo_to_firewall$EMPTY_N;
  logic         fifo_to_firewall$CLR;
  
  // Instantiate FIFO for invalidation results.
  wire [2:0] to_invalidate_fifo$D_IN, to_invalidate_fifo$D_OUT;
  wire       to_invalidate_fifo$ENQ, to_invalidate_fifo$DEQ;
  wire       to_invalidate_fifo$FULL_N, to_invalidate_fifo$EMPTY_N;
  wire       to_invalidate_fifo$CLR;
  
  // Instantiate FIFO for to send results.
  wire [2:0] to_send_fifo$D_IN, to_send_fifo$D_OUT;
  wire       to_send_fifo$ENQ, to_send_fifo$DEQ;
  wire       to_send_fifo$FULL_N, to_send_fifo$EMPTY_N;
  wire       to_send_fifo$CLR;
  
  //-------------------------------------------------------
  // PRT Table Interface (signals as in original design)
  //-------------------------------------------------------
  logic [8:0] prt_table$read_prt_entry;
  logic [7:0] prt_table$write_prt_entry_data;
  logic       prt_table$EN_finish_writing_prt_entry;
  logic       prt_table$EN_invalidate_prt_entry;
  logic       prt_table$EN_read_prt_entry;
  logic       prt_table$EN_start_reading_prt_entry;
  logic       prt_table$EN_start_writing_prt_entry;
  logic       prt_table$EN_write_prt_entry;
  logic       prt_table$RDY_finish_writing_prt_entry;
  logic       prt_table$RDY_read_prt_entry;
  logic       prt_table$RDY_start_reading_prt_entry;
  logic       prt_table$RDY_start_writing_prt_entry;
  logic       prt_table$RDY_write_prt_entry;
  logic       prt_table$invalidate_prt_entry_slot;
  logic       prt_table$is_prt_slot_free;
  logic       prt_table$start_reading_prt_entry_slot;
  logic       prt_table$start_writing_prt_entry;
  
  //-------------------------------------------------------
  // Rule Scheduling Signals (unchanged names)
  //-------------------------------------------------------
  logic CAN_FIRE_RL_invalidate_unsafe_prt_entries;
  logic WILL_FIRE_RL_invalidate_currently_receiving_frame;
  logic WILL_FIRE_RL_invalidate_unsafe_prt_entries;
  logic WILL_FIRE_RL_push_header_into_firewall_fifo;
  logic WILL_FIRE_RL_rx_check_prt_if_slot_available;
  logic WILL_FIRE_RL_rx_finish_geting_frame_data;
  logic WILL_FIRE_RL_rx_get_frame_data;
  logic WILL_FIRE_RL_tx_send_frame_data;
  logic WILL_FIRE_RL_tx_start_transmission;
  
  //-------------------------------------------------------
  // Mux Inputs (as in original design)
  //-------------------------------------------------------
  logic [1:0] MUX_rx_slot$write_1__VAL_1;
  logic       MUX_currently_recv_packet_is_unsafe$write_1__SEL_1;
  logic       MUX_header_availability$write_1__SEL_1;
  logic       MUX_prt_table$invalidate_prt_entry_1__SEL_1;
  logic       MUX_receive_frame_state$write_1__SEL_1;
  logic       MUX_send_frame_state$write_1__SEL_1;
  
  //-------------------------------------------------------
  // Inlined Wires for Computation (unchanged names)
  //-------------------------------------------------------
  // ... (omitted for brevity; see original code)
  logic [31:0] x__h1136, x__h1143, x__h1150, x__h1157, x__h1171, x__h1178, x__h1185;
  logic [15:0] x__h1192, x__h1199, x__h1297;
  logic [7:0]  y__h1381, y__h1385, y__h1389;
  logic [15:0] y__h1327;
  logic        to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144;

  //===============================================================
  // BLOOM FILTER INTEGRATION SIGNALS
  //===============================================================
  logic bf_need;
  logic bf_res;
  logic bf_res_sent;
  logic packet_safe;
  
  // For this design, assume that a BF result of 1 indicates a "hit" (i.e. safe)
  assign packet_safe = bf_res;
  
  // Assert the Bloom filter request when header extraction is complete.
  // (In this example, we trigger BF when rx_byte_count reaches 37 and the RX data is being processed.)
  assign bf_need = (rx_byte_count == 16'd37) && WILL_FIRE_RL_rx_get_frame_data;
  
  //=======================================================================
  // ASSIGNMENTS FOR AXI-STREAM INTERFACES
  //=======================================================================
  
  //----- Transmit (TX) AXI-Stream Output ---------------------------------
  // TX signals are driven from an internal state machine (see below)
  assign tx_axis_tdata = tx_byte_reg;
  assign tx_axis_tvalid = tx_valid_reg;
  assign tx_axis_tlast  = tx_last_reg;
  assign tx_axis_tuser  = 1'b0;
  
  //----- Receive (RX) AXI-Stream Ready ------------------------------------
  // For this example, we assume the receiver is always ready.
  assign rx_axis_tready = 1'b1;
  
  //----- Firewall Header Interface ----------------------------------------
  // Assemble the header data from the extracted header fields.
  // Order and widths are chosen to total 106 bits.
  wire [105:0] header_data;
  assign header_data = { 
    rx_header_dstip,       // 32 bits
    rx_header_dstport,     // 16 bits
    rx_header_protocol,    // 8 bits
    rx_header_srcip,       // 32 bits
    rx_header_srcport,     // 16 bits
    current_recv_packet_slot // 6 bits (example; adjust if needed)
  };
  
  // Connect the assembled header to the FIFO data input.
  assign fifo_to_firewall$D_IN = header_data;
  
  // ENQ Logic: Enqueue the header data when the header is completely extracted.
  // This signal should be asserted by the header extraction state machine (or rule).
  assign fifo_to_firewall$ENQ = WILL_FIRE_RL_push_header_into_firewall_fifo;
  
  // FIFO Dequeue: When the firewall is ready and the FIFO is non-empty.
  assign m_axis_header_tdata  = fifo_to_firewall$D_OUT;
  assign m_axis_header_tvalid = fifo_to_firewall$EMPTY_N; // Valid when FIFO is non-empty.
  assign fifo_to_firewall$DEQ  = m_axis_header_tvalid && m_axis_header_tready;
  
  // No asynchronous clear for the FIFO.
  assign fifo_to_firewall$CLR  = 1'b0;
  
  //----- Firewall Result Interface ----------------------------------------
  // Dispatch the 3-bit result into two FIFOs based on bit0.
  assign s_axis_result_tready = to_send_fifo$FULL_N && to_invalidate_fifo$FULL_N;
  assign to_send_fifo$D_IN       = s_axis_result_tdata;
  assign to_invalidate_fifo$D_IN = s_axis_result_tdata;
  assign to_send_fifo$ENQ       = s_axis_result_tvalid && s_axis_result_tready && (s_axis_result_tdata[0] == 1'b1);
  assign to_invalidate_fifo$ENQ = s_axis_result_tvalid && s_axis_result_tready && (s_axis_result_tdata[0] == 1'b0);
  assign to_send_fifo$CLR       = 1'b0;
  assign to_invalidate_fifo$CLR = 1'b0;
  
  //=======================================================================
  // SUBMODULE INSTANTIATIONS
  //=======================================================================
  // Instantiate FIFO for header information.
  FIFO2 #(.width(106), .guarded(1)) fifo_to_firewall (
    .RST(RST_N),
    .CLK(CLK),
    .D_IN(fifo_to_firewall$D_IN),
    .ENQ(fifo_to_firewall$ENQ),
    .DEQ(fifo_to_firewall$DEQ),
    .CLR(fifo_to_firewall$CLR),
    .D_OUT(fifo_to_firewall$D_OUT),
    .FULL_N(fifo_to_firewall$FULL_N),
    .EMPTY_N(fifo_to_firewall$EMPTY_N)
  );
  
  // Instantiate FIFO for invalidation results.
  FIFO2 #(.width(3), .guarded(1)) to_invalidate_fifo (
    .RST(RST_N),
    .CLK(CLK),
    .D_IN(to_invalidate_fifo$D_IN),
    .ENQ(to_invalidate_fifo$ENQ),
    .DEQ(to_invalidate_fifo$DEQ),
    .CLR(to_invalidate_fifo$CLR),
    .D_OUT(to_invalidate_fifo$D_OUT),
    .FULL_N(to_invalidate_fifo$FULL_N),
    .EMPTY_N(to_invalidate_fifo$EMPTY_N)
  );
  
  // Instantiate FIFO for to send results.
  FIFO2 #(.width(3), .guarded(1)) to_send_fifo (
    .RST(RST_N),
    .CLK(CLK),
    .D_IN(to_send_fifo$D_IN),
    .ENQ(to_send_fifo$ENQ),
    .DEQ(to_send_fifo$DEQ),
    .CLR(to_send_fifo$CLR),
    .D_OUT(to_send_fifo$D_OUT),
    .FULL_N(to_send_fifo$FULL_N),
    .EMPTY_N(to_send_fifo$EMPTY_N)
  );
  
  // Instantiate the PRT table module.
  mkPRT prt_table(
    .CLK(CLK),
    .RST_N(RST_N),
    .invalidate_prt_entry_slot(prt_table$invalidate_prt_entry_slot),
    .start_reading_prt_entry_slot(prt_table$start_reading_prt_entry_slot),
    .write_prt_entry_data(prt_table$write_prt_entry_data),
    .EN_start_writing_prt_entry(prt_table$EN_start_writing_prt_entry),
    .EN_write_prt_entry(prt_table$EN_write_prt_entry),
    .EN_finish_writing_prt_entry(prt_table$EN_finish_writing_prt_entry),
    .EN_invalidate_prt_entry(prt_table$EN_invalidate_prt_entry),
    .EN_start_reading_prt_entry(prt_table$EN_start_reading_prt_entry),
    .EN_read_prt_entry(prt_table$EN_read_prt_entry),
    .start_writing_prt_entry(prt_table$start_writing_prt_entry),
    .RDY_start_writing_prt_entry(prt_table$RDY_start_writing_prt_entry),
    .RDY_write_prt_entry(prt_table$RDY_write_prt_entry),
    .RDY_finish_writing_prt_entry(prt_table$RDY_finish_writing_prt_entry),
    .RDY_invalidate_prt_entry(),
    .RDY_start_reading_prt_entry(prt_table$RDY_start_reading_prt_entry),
    .read_prt_entry(prt_table$read_prt_entry),
    .RDY_read_prt_entry(prt_table$RDY_read_prt_entry),
    .is_prt_slot_free(prt_table$is_prt_slot_free),
    .RDY_is_prt_slot_free()
  );
  
  //-------------------------------------------------------------------------
  // Instantiate Bloom Filter module
  // Note: The mkbloomfilter module expects an active-high reset so we invert RST_N.
  mkbloomfilter #(.M_SIZE(16'd65535)) bloom_filter_inst (
    .clk(CLK),
    .rst(!RST_N),
    .need_bf(bf_need),
    .src_ip(rx_header_srcip),
    .dst_ip(rx_header_dstip),
    .protocol(rx_header_protocol),
    .src_port(rx_header_srcport),
    .dst_port(rx_header_dstport),
    .res(bf_res),
    .res_sent(bf_res_sent)
  );
  
  //=======================================================================
  // RECEIVE BYTE COUNTER (AXI-Stream RX)
  //=======================================================================
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N)
      rx_byte_count <= 16'd0;
    else if (rx_axis_tvalid && rx_axis_tready) begin
      rx_byte_count <= rx_byte_count + 16'd1;
      if (rx_axis_tlast)
        rx_byte_count <= 16'd0;
    end
  end
  
  //=======================================================================
  // HEADER EXTRACTION
  //=======================================================================
  // Header extraction assignments for protocol, srcip, dstip, srcport, dstport.
  assign rx_header_protocol$D_IN = rx_axis_tdata;
  assign rx_header_protocol$EN = WILL_FIRE_RL_rx_get_frame_data && (rx_byte_count == 16'd23);
  
  // For rx_header_srcip:
  always @(*) begin
    case (rx_byte_count)
      16'd26: rx_header_srcip$D_IN = x__h1136;
      16'd27: rx_header_srcip$D_IN = x__h1143;
      16'd28: rx_header_srcip$D_IN = x__h1150;
      default: rx_header_srcip$D_IN = x__h1157;
    endcase
  end
  assign rx_header_srcip$EN = WILL_FIRE_RL_rx_get_frame_data &&
                              ((rx_byte_count == 16'd26) ||
                               (rx_byte_count == 16'd27) ||
                               (rx_byte_count == 16'd28) ||
                               (rx_byte_count == 16'd29));
  
  // For rx_header_dstip:
  always @(*) begin
    case (rx_byte_count)
      16'd30: rx_header_dstip$D_IN = x__h1136;
      16'd31: rx_header_dstip$D_IN = x__h1171;
      16'd32: rx_header_dstip$D_IN = x__h1178;
      default: rx_header_dstip$D_IN = x__h1185;
    endcase
  end
  assign rx_header_dstip$EN = WILL_FIRE_RL_rx_get_frame_data &&
                               ((rx_byte_count == 16'd30) ||
                                (rx_byte_count == 16'd31) ||
                                (rx_byte_count == 16'd32) ||
                                (rx_byte_count == 16'd33));
  
  // For rx_header_srcport:
  assign rx_header_srcport$D_IN = (rx_byte_count == 16'd34) ? x__h1192 : x__h1199;
  assign rx_header_srcport$EN = WILL_FIRE_RL_rx_get_frame_data &&
                               ((rx_byte_count == 16'd34) || (rx_byte_count == 16'd35));
  
  // For rx_header_dstport:
  assign rx_header_dstport$D_IN = (rx_byte_count == 16'd36) ? x__h1192 : x__h1297;
  assign rx_header_dstport$EN = WILL_FIRE_RL_rx_get_frame_data &&
                               ((rx_byte_count == 16'd36) || (rx_byte_count == 16'd37));
  
  //=======================================================================
// ETHERNET TRANSMIT (AXI-Stream TX) LOGIC
//=======================================================================

typedef enum logic [1:0] {
  TX_IDLE,   // No transmission is taking place.
  TX_FETCH,  // Fetch a new byte from the PRT table.
  TX_SEND    // Drive the byte onto the AXI-Stream TX interface.
} tx_state_t;

tx_state_t tx_state, tx_state_next;

// Combinational block to determine the next state.
always_comb begin
  // Default: remain in current state.
  tx_state_next = tx_state;
  case (tx_state)
    TX_IDLE: begin
      // When send_frame_state becomes true, start transmission.
      if (send_frame_state)
        tx_state_next = TX_FETCH;
    end
    TX_FETCH: begin
      // After fetching data, go to send state.
      tx_state_next = TX_SEND;
    end
    TX_SEND: begin
      // In send state, if the downstream is ready and we are outputting valid data:
      if (tx_axis_tready && tx_valid_reg) begin
        // If this is the last byte, return to idle.
        if (tx_last_reg)
          tx_state_next = TX_IDLE;
        else
          // Otherwise, fetch the next byte.
          tx_state_next = TX_FETCH;
      end
    end
    default: tx_state_next = TX_IDLE;
  endcase
end

// Sequential block updating the state machine and TX output registers.
always_ff @(posedge CLK or negedge RST_N) begin
  if (!RST_N) begin
    tx_state     <= TX_IDLE;
    tx_valid_reg <= 1'b0;
    tx_byte_reg  <= 8'd0;
    tx_last_reg  <= 1'b0;
  end else begin
    tx_state <= tx_state_next;
    case (tx_state)
      TX_IDLE: begin
        // In IDLE, ensure no valid data is output.
        tx_valid_reg <= 1'b0;
        // (Optionally, you can add a debug print here)
        // $display("[%0t] TX_STATE: IDLE", $time);
      end
      TX_FETCH: begin
        // Fetch a byte from the PRT table.
        tx_byte_reg  <= prt_table$read_prt_entry[8:1];
        tx_last_reg  <= prt_table$read_prt_entry[0];
        tx_valid_reg <= 1'b1;
        // Debug print (optional):
        // $display("[%0t] TX_STATE: FETCH, read data = %h, last=%b", $time, prt_table$read_prt_entry[8:1], prt_table$read_prt_entry[0]);
      end
      TX_SEND: begin
        // In SEND state, drive the valid data.
        tx_valid_reg <= 1'b1;
        // If the downstream is ready and the current byte is sent,
        // then if it was the last byte, clear the valid flag.
        if (tx_axis_tready) begin
          if (tx_last_reg) begin
            tx_valid_reg <= 1'b0;
            // $display("[%0t] TX_STATE: SEND, last byte transmitted", $time);
          end else begin
            // $display("[%0t] TX_STATE: SEND, more bytes to fetch", $time);
          end
        end
      end
      default: begin
        tx_valid_reg <= 1'b0;
      end
    endcase
  end
end

  //=========================================================================
  // RULE ASSIGNMENTS (Mapping new Ethernet signals to AXI-Stream)
  //=========================================================================
  assign WILL_FIRE_RL_tx_start_transmission = prt_table$RDY_start_reading_prt_entry &&
                                               to_send_fifo$EMPTY_N &&
                                               !send_frame_state &&
                                               tx_axis_tready;
  
  assign WILL_FIRE_RL_invalidate_currently_receiving_frame = rx_axis_tlast && currently_recv_packet_is_unsafe;
  
  assign CAN_FIRE_RL_invalidate_unsafe_prt_entries = to_invalidate_fifo$EMPTY_N && !WILL_FIRE_RL_invalidate_currently_receiving_frame;
  assign WILL_FIRE_RL_invalidate_unsafe_prt_entries = CAN_FIRE_RL_invalidate_unsafe_prt_entries && !WILL_FIRE_RL_invalidate_currently_receiving_frame;
  
  assign WILL_FIRE_RL_tx_send_frame_data = tx_axis_tready && prt_table$RDY_read_prt_entry && send_frame_state;
  
  assign WILL_FIRE_RL_rx_finish_geting_frame_data = rx_axis_tlast &&
                                                    prt_table$RDY_finish_writing_prt_entry &&
                                                    receive_frame_state &&
                                                    !currently_recv_packet_is_unsafe &&
                                                    header_availability &&
                                                    rx_axis_tlast;
  
  assign WILL_FIRE_RL_rx_check_prt_if_slot_available = 1'b1 && prt_table$RDY_start_writing_prt_entry &&
                                                       !receive_frame_state &&
                                                       !WILL_FIRE_RL_invalidate_unsafe_prt_entries &&
                                                       !WILL_FIRE_RL_invalidate_currently_receiving_frame;
  
  assign WILL_FIRE_RL_rx_get_frame_data = rx_axis_tvalid && prt_table$RDY_write_prt_entry &&
                                          receive_frame_state &&
                                          !currently_recv_packet_is_unsafe &&
                                          header_availability &&
                                          !rx_axis_tlast;
  
  //=======================================================================
  // MUX AND INLINE SIGNAL ASSIGNMENTS
  //=======================================================================
  assign MUX_currently_recv_packet_is_unsafe$write_1__SEL_1 = 
         (WILL_FIRE_RL_invalidate_unsafe_prt_entries && 
          to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1]);
          
  assign MUX_header_availability$write_1__SEL_1 = 
         (WILL_FIRE_RL_rx_get_frame_data && (rx_byte_count == 16'd37));
         
  assign MUX_prt_table$invalidate_prt_entry_1__SEL_1 = 
         (WILL_FIRE_RL_invalidate_unsafe_prt_entries && 
         (!to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1]));
         
  assign MUX_receive_frame_state$write_1__SEL_1 = 
         (WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && rx_axis_tvalid);
         
  assign MUX_send_frame_state$write_1__SEL_1 = 
         (WILL_FIRE_RL_tx_send_frame_data && prt_table$read_prt_entry[0]);
         
  assign MUX_rx_slot$write_1__VAL_1 = { 1'd1, prt_table$start_writing_prt_entry };
  
  assign _invalidate_prt_entry_RL_invalidate_unsafe_prt_entries$EN_prt_table$wget =
         (!to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1]);
  assign _write_RL_invalidate_unsafe_prt_entries$EN_currently_recv_packet_is_unsafe$wget =
         (to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1]);
  
  assign current_recv_packet_slot$D_IN = rx_slot[0];
  assign current_recv_packet_slot$EN = MUX_currently_recv_packet_is_unsafe$write_1__SEL_1;
  
  assign currently_recv_packet_is_unsafe$D_IN = MUX_currently_recv_packet_is_unsafe$write_1__SEL_1;
  assign currently_recv_packet_is_unsafe$EN = (WILL_FIRE_RL_invalidate_unsafe_prt_entries && 
                                                to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 && rx_slot[1]) ||
                                               WILL_FIRE_RL_invalidate_currently_receiving_frame;
  
  assign header_availability$D_IN = !MUX_header_availability$write_1__SEL_1;
  assign header_availability$EN = (WILL_FIRE_RL_rx_get_frame_data && (rx_byte_count == 16'd37)) ||
                                  WILL_FIRE_RL_push_header_into_firewall_fifo;
  
  assign receive_frame_state$D_IN = MUX_receive_frame_state$write_1__SEL_1;
  assign receive_frame_state$EN = (WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && rx_axis_tvalid) ||
                                  WILL_FIRE_RL_invalidate_currently_receiving_frame ||
                                  WILL_FIRE_RL_rx_finish_geting_frame_data;
                                 
  assign rx_slot$D_IN = (MUX_receive_frame_state$write_1__SEL_1) ? MUX_rx_slot$write_1__VAL_1 : 2'd0;
  assign rx_slot$EN = (WILL_FIRE_RL_rx_check_prt_if_slot_available && prt_table$is_prt_slot_free && rx_axis_tvalid) ||
                     WILL_FIRE_RL_invalidate_currently_receiving_frame ||
                     WILL_FIRE_RL_rx_finish_geting_frame_data;
  
  assign send_frame_state$D_IN = !MUX_send_frame_state$write_1__SEL_1;
  assign send_frame_state$EN = (WILL_FIRE_RL_tx_send_frame_data && prt_table$read_prt_entry[0]) ||
                               WILL_FIRE_RL_tx_start_transmission;
                               
   //=========================================================================
  // SUBMODULE ASSIGNMENTS (FIFOs & PRT Table)
  //=========================================================================
  
  assign prt_table$invalidate_prt_entry_slot = MUX_prt_table$invalidate_prt_entry_1__SEL_1 ?
                                               to_invalidate_fifo$D_OUT[1] : current_recv_packet_slot;
  assign prt_table$start_reading_prt_entry_slot = to_send_fifo$D_OUT[1];
  assign prt_table$write_prt_entry_data = rx_axis_tdata;
  assign prt_table$EN_start_writing_prt_entry = MUX_receive_frame_state$write_1__SEL_1;
  assign prt_table$EN_write_prt_entry = WILL_FIRE_RL_rx_get_frame_data;
  assign prt_table$EN_finish_writing_prt_entry = WILL_FIRE_RL_rx_finish_geting_frame_data;
  assign prt_table$EN_invalidate_prt_entry = WILL_FIRE_RL_invalidate_unsafe_prt_entries &&
                                             (!to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 || !rx_slot[1]) ||
                                             WILL_FIRE_RL_invalidate_currently_receiving_frame;
  assign prt_table$EN_start_reading_prt_entry = WILL_FIRE_RL_tx_start_transmission;
  assign prt_table$EN_read_prt_entry = WILL_FIRE_RL_tx_send_frame_data;
  
  assign to_invalidate_fifo$D_IN = s_axis_result_tdata;
  assign to_invalidate_fifo$ENQ = s_axis_result_tvalid && s_axis_result_tready && (s_axis_result_tdata[0] == 1'b0);
  assign to_invalidate_fifo$DEQ = WILL_FIRE_RL_invalidate_unsafe_prt_entries;
  assign to_invalidate_fifo$CLR = 1'b0;
  
  assign to_send_fifo$D_IN = s_axis_result_tdata;
  assign to_send_fifo$ENQ = s_axis_result_tvalid && s_axis_result_tready && (s_axis_result_tdata[0] == 1'b1);
  assign to_send_fifo$DEQ = WILL_FIRE_RL_tx_start_transmission; 
  assign to_send_fifo$CLR = 1'b0;                           
  
  // Inline computations for header extraction
  assign x__h1136 = { rx_axis_tdata, 24'd0 };
  assign x__h1143 = rx_header_srcip | y__h1381;
  assign x__h1150 = rx_header_srcip | y__h1385;
  assign x__h1157 = rx_header_srcip | y__h1389;
  assign x__h1171 = rx_header_dstip | y__h1381;
  assign x__h1178 = rx_header_dstip | y__h1385;
  assign x__h1185 = rx_header_dstip | y__h1389;
  assign x__h1192 = { rx_axis_tdata, 8'b0 };
  assign x__h1199 = rx_header_srcport | y__h1327;
  assign x__h1297 = rx_header_dstport | y__h1327;
  assign y__h1327 = { 8'b0, rx_axis_tdata };
  assign y__h1381 = { 8'b0, rx_axis_tdata, 16'd0 };
  assign y__h1385 = { 16'd0, x__h1192 };
  assign y__h1389 = { 24'd0, rx_axis_tdata };
  
  assign to_invalidate_fifo_first__42_BIT_1_43_EQ_IF_rx_ETC___d144 = (to_invalidate_fifo$D_OUT[1] == rx_slot[0]);
  
  //=======================================================================
  // INTERNAL STATE UPDATES (Registers, PRT, etc.)
  //=======================================================================
  // Updates to internal registers and state. The Bloom filter result is used here
  // to update the "currently_recv_packet_is_unsafe" flag.
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N) begin
      current_recv_packet_slot        <= 1'b1;
      currently_recv_packet_is_unsafe <= '0;
      header_availability             <= 1'b1;  // Reset value as in original design
      receive_frame_state             <= '0;
      rx_slot                         <= '0;
      send_frame_state                <= 1'b1;
    end else begin
      if (current_recv_packet_slot$EN)
        current_recv_packet_slot <= current_recv_packet_slot$D_IN;
      if (currently_recv_packet_is_unsafe$EN)
        currently_recv_packet_is_unsafe <= currently_recv_packet_is_unsafe$D_IN;
      if (header_availability$EN)
        header_availability <= header_availability$D_IN;
      if (receive_frame_state$EN)
        receive_frame_state <= receive_frame_state$D_IN;
      if (rx_header_dstip$EN)
        rx_header_dstip <= rx_header_dstip$D_IN;
      if (rx_header_dstport$EN)
        rx_header_dstport <= rx_header_dstport$D_IN;
      if (rx_header_protocol$EN)
        rx_header_protocol <= rx_header_protocol$D_IN;
      if (rx_header_srcip$EN)
        rx_header_srcip <= rx_header_srcip$D_IN;
      if (rx_header_srcport$EN)
        rx_header_srcport <= rx_header_srcport$D_IN;
      if (rx_slot$EN)
        rx_slot <= rx_slot$D_IN;
      if (send_frame_state$EN)
        send_frame_state <= send_frame_state$D_IN;
        
      // Bloom filter integration:
      // When the BF result is ready, update the unsafe flag.
      if (bf_res_sent)
        currently_recv_packet_is_unsafe <= ~packet_safe;
    end
  end
  
  // Initial assignments (as in your original code)
  initial begin
    current_recv_packet_slot        <= '0;
    currently_recv_packet_is_unsafe <= '0;
    header_availability             <= 1'b1;
    receive_frame_state             <= '0;
    rx_header_dstip                 <= 32'hAAAAAAAA;
    rx_header_dstport               <= 16'hAAAA;
    rx_header_protocol              <= 8'hAA;
    rx_header_srcip                 <= 32'hAAAAAAAA;
    rx_header_srcport               <= 16'hAAAA;
    rx_slot                         <= '0;
    send_frame_state                <= '0;
  end
  
endmodule

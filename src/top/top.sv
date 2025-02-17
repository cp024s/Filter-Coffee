`timescale 1ns / 1ps

/* ==========================================================================
                          -----  ERRORS & BUGS  -----
                               
- needs to attach top file
- bloom filter needs to be completed
- bloom filter la ithana states edhuku ?
- BRAM attachment for bloom filter
- port mismatch between different modules

=============================================================================
===========================================================================*/


// ==========================================================================
//                              TOP MODULE
// ==========================================================================

module mkMVP_2to1 (
  input  logic CLK,
  input  logic RST_N,
  
  //------------------------------------------------------------------------
  // Ethernet AXI-Stream Receive Interface (replacing MII Rx signals)
  //------------------------------------------------------------------------
  input  logic [7:0] rx_axis_tdata,   // Incoming data byte from Ethernet
  input  logic       rx_axis_tvalid,  // Data valid
  output logic       rx_axis_tready,  // Ready to accept data
  input  logic       rx_axis_tlast,   // End-of-frame indicator
  input  logic       rx_axis_tuser,   // Error flag
  
  //------------------------------------------------------------------------
  // Ethernet AXI-Stream Transmit Interface (replacing MII Tx signals)
  //------------------------------------------------------------------------
  output logic [7:0] tx_axis_tdata,   // Outgoing data byte to Ethernet
  output logic       tx_axis_tvalid,  // Data valid
  input  logic       tx_axis_tready,  // Downstream ready signal
  output logic       tx_axis_tlast,   // End-of-frame indicator
  output logic       tx_axis_tuser,   // User flag
  
  // (For simplicity, no additional debug ports are added here.)
  
  // (All other internal functionality is encapsulated in mkMPD and the firewall.)
  
  // Optional: a debug output to monitor the header used in firewall interfacing.
  output logic [105:0] debug_header
);

  //-------------------------------------------------------------------------
  // Internal Signals Connecting Submodules
  //-------------------------------------------------------------------------
  // These signals come from the mkMPD instance.
  wire [105:0] m_axis_header_tdata;
  wire         m_axis_header_tvalid;
  wire         m_axis_header_tready;
  
  // Firewall result (3-bit) coming from the firewall.
  wire [2:0] firewall_result;
  
  // We also need a BF request signal for the firewall.
  wire need_bf;
  
  //-------------------------------------------------------------------------
  // Inlined Register for header_in and Associated Rule Signals
  //-------------------------------------------------------------------------
  // header_in is 107 bits wide. Bit 106 (MSB) is used as a flag.
  logic [106:0] header_in;
  logic [106:0] header_in$D_IN;
  logic         header_in$EN;
  
  // Rule Definitions
  // RL_read_headers fires when the header interface is ready, a BF request is needed,
  // and header_in[106] is 0.
  wire WILL_FIRE_RL_read_headers;
  assign WILL_FIRE_RL_read_headers = m_axis_header_tready && need_bf && !header_in[106];
  
  // RL_write_tag_bf fires when the BF submodule has sent its result,
  // the firewall result interface is ready, and header_in[106] is 1.
  wire WILL_FIRE_RL_write_tag_bf;
  assign WILL_FIRE_RL_write_tag_bf = /* Assuming BF submodule drives res_sent */ 
                                      /* res_sent should be 1 when the result is ready */
                                      res_sent && s_axis_result_tready && header_in[106];
  
  // Mux assignment for header_in input.
  // Here we concatenate a 1-bit flag with the header output from mkMPD.
  // (You can modify the constant as needed.)
  wire [106:0] MUX_header_in$write_1__VAL_2;
  assign MUX_header_in$write_1__VAL_2 = { 1'd1, m_axis_header_tdata };
  
  // Inlined register update for header_in:
  assign header_in$D_IN = (WILL_FIRE_RL_write_tag_bf) ? 107'h2AAAAAAAAAAAAAAAAAAAAAAAAAA : MUX_header_in$write_1__VAL_2;
  assign header_in$EN   =  WILL_FIRE_RL_write_tag_bf || WILL_FIRE_RL_read_headers;
  
  //-------------------------------------------------------------------------
  // Submodule Signal Connections for Firewall
  //-------------------------------------------------------------------------
  // Extract fields from m_axis_header_tdata.
  // (Adjust bit-slice ranges as needed for your header format.)
  wire [31:0] scr_ip, dst_ip;
  wire [7:0]  protocol;
  wire [15:0] scr_port, dst_port;
  
  assign scr_ip    = m_axis_header_tdata[15:0];         // Example slice; adjust as needed.
  assign dst_ip    = m_axis_header_tdata[31:16];
  assign protocol  = m_axis_header_tdata[63:32];
  assign scr_port  = m_axis_header_tdata[95:64];
  assign dst_port  = m_axis_header_tdata[103:96];
  
  // For mpd connections, assign the firewall result signals.
  // Here we pack the result bit into a 3-bit word.
  assign s_axis_result_tdata = firewall_result; // Firewall drives a 3-bit result.
  // For this example, drive m_axis_header_tvalid to be the same as our rule.
  assign m_axis_header_tvalid = WILL_FIRE_RL_read_headers;
  // And the result valid is asserted when writing tag and result is not a threat.
  assign s_axis_result_tvalid = WILL_FIRE_RL_write_tag_bf && !firewall_result[0];
  
  //-------------------------------------------------------------------------
  // Inlined Register: header_in
  // Using active-low asynchronous reset.
  //-------------------------------------------------------------------------
  always @(posedge CLK or negedge RST_N) begin
    if (!RST_N)
      header_in <= 107'h2AAAAAAAAAAAAAAAAAAAAAAAAAA;
    else if (header_in$EN)
      header_in <= header_in$D_IN;
  end
  
  //-------------------------------------------------------------------------
  // Instantiate mkMPD
  //-------------------------------------------------------------------------
  // We assume mkMPD internally implements the full datapath (including TX,
  // header extraction, PRT table, and so on).
  // For this example, we connect the AXI-Stream ports directly.
  mkMPD dut (
    .CLK                   (CLK),
    .RST_N                 (RST_N),
    // Ethernet RX
    .rx_axis_tdata         (rx_axis_tdata),
    .rx_axis_tvalid        (rx_axis_tvalid),
    .rx_axis_tready        (rx_axis_tready),
    .rx_axis_tlast         (rx_axis_tlast),
    .rx_axis_tuser         (rx_axis_tuser),
    // Ethernet TX
    .tx_axis_tdata         (tx_axis_tdata),
    .tx_axis_tvalid        (tx_axis_tvalid),
    .tx_axis_tready        (tx_axis_tready),
    .tx_axis_tlast         (tx_axis_tlast),
    .tx_axis_tuser         (tx_axis_tuser),
    // Firewall Header Interface
    .m_axis_header_tdata   (m_axis_header_tdata),
    .m_axis_header_tvalid  (),   // We'll drive this via our rule definitions
    .m_axis_header_tready  (m_axis_header_tready),
    // Firewall Result Interface
    .s_axis_result_tdata   (s_axis_result_tdata),
    .s_axis_result_tvalid  (s_axis_result_tvalid),
    .s_axis_result_tready  (s_axis_result_tready)
  );
  
  //-------------------------------------------------------------------------
  // Instantiate mkFirewall2to1 (Firewall Module)
  //-------------------------------------------------------------------------
  // Note: If mkFirewall2to1 expects an active-high reset, we invert RST_N.
  mkbloomfilter uut (
    .clk        (CLK),
    .rst        (!RST_N),
    .need_bf    (need_bf),
    .src_ip     (scr_ip),
    .dst_ip     (dst_ip),
    .protocol   (protocol),
    .src_port   (scr_port),
    .dst_port   (dst_port),
    .res        (firewall_result[0]), // Use bit0 as the result indicator
    .res_sent   (res_sent)
  );
  
  //-------------------------------------------------------------------------
  // Tie header interface ready high.
  //-------------------------------------------------------------------------
  assign m_axis_header_tready = 1'b1;
  
  //-------------------------------------------------------------------------
  // Drive need_bf signal (for example, when header is valid)
  //-------------------------------------------------------------------------
  assign need_bf = m_axis_header_tvalid; // Or some other condition as required.
  
  //-------------------------------------------------------------------------
  // Drive debug output.
  //-------------------------------------------------------------------------
  assign debug_header = m_axis_header_tdata;
  
  //-------------------------------------------------------------------------
  // (Optional) Simulation Debug Displays
  //-------------------------------------------------------------------------
  // These always blocks print diagnostic information on each negative edge.
  // synthesis translate_off
  always @(negedge CLK) begin
    if (RST_N) begin
      if (WILL_FIRE_RL_read_headers) begin
        v__h385 = $time;
        $display("%0t mkMVP2to1: Header Read - src_ip: %h, dst_ip: %h, protocol: %h, src_port: %h, dst_port: %h",
                 v__h385,
                 m_axis_header_tdata[95:64],
                 m_axis_header_tdata[63:32],
                 m_axis_header_tdata[103:96],
                 m_axis_header_tdata[31:16],
                 m_axis_header_tdata[15:0]);
      end
      if (WILL_FIRE_RL_read_headers) begin
        v__h498 = $time;
        $display("%0t mkMVP2to1: Sent header to firewall", v__h498);
      end
      if (WILL_FIRE_RL_write_tag_bf && firewall_result[0]) begin
        v__h856 = $time;
        $display("%0t mkMVP2to1: Possibly Safe packet. False-positive can exist", v__h856);
      end
      if (WILL_FIRE_RL_write_tag_bf && !firewall_result[0]) begin
        v__h605 = $time;
        $display("%0t mkMVP2to1: Detected as threat", v__h605);
      end
    end
  end
  // synthesis translate_on

endmodule

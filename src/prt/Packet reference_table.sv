`timescale 1ns / 1ps

// ==========================================================================
//                           PACKET REFERENCE TABLE
// ==========================================================================
module mkPRT(
  input  logic CLK,           // System clock
  input  logic RST_N,         // Active-low reset
  
  // --------------------------------------------------------------------------
  // Actionvalue method: start_writing_prt_entry
  // --------------------------------------------------------------------------
  input  logic EN_start_writing_prt_entry, // Enable starting a write operation
  output logic start_writing_prt_entry,      // Signal to indicate start of writing
  output logic RDY_start_writing_prt_entry,  // Ready signal for starting writing

  // --------------------------------------------------------------------------
  // Action method: write_prt_entry
  // --------------------------------------------------------------------------
  input  logic [7:0] write_prt_entry_data,   // Data to be written into the PRT entry
  input  logic EN_write_prt_entry,           // Enable signal for writing a PRT entry
  output logic RDY_write_prt_entry,          // Ready signal for writing operation
  
  // --------------------------------------------------------------------------
  // Action method: finish_writing_prt_entry
  // --------------------------------------------------------------------------
  input  logic EN_finish_writing_prt_entry,  // Enable finishing the write operation
  output logic RDY_finish_writing_prt_entry, // Ready signal for finish writing

  // --------------------------------------------------------------------------
  // Action method: invalidate_prt_entry
  // --------------------------------------------------------------------------
  input  logic invalidate_prt_entry_slot,    // Slot identifier for invalidation
  input  logic EN_invalidate_prt_entry,        // Enable invalidation of a PRT entry
  output logic RDY_invalidate_prt_entry,       // Ready signal for invalidation

  // --------------------------------------------------------------------------
  // Action method: start_reading_prt_entry
  // --------------------------------------------------------------------------
  input  logic start_reading_prt_entry_slot,   // Slot identifier for reading start
  input  logic EN_start_reading_prt_entry,       // Enable starting the read operation
  output logic RDY_start_reading_prt_entry,      // Ready signal for starting read

  // --------------------------------------------------------------------------
  // Actionvalue method: read_prt_entry
  // --------------------------------------------------------------------------
  input  logic EN_read_prt_entry,            // Enable signal for reading a PRT entry
  output logic [8 : 0] read_prt_entry,         // Data output from the PRT entry read
  output logic RDY_read_prt_entry,           // Ready signal for the read operation

  // --------------------------------------------------------------------------
  // Value method: is_prt_slot_free
  // --------------------------------------------------------------------------
  output logic is_prt_slot_free,             // Indicates if a PRT slot is free
  output logic RDY_is_prt_slot_free          // Ready signal for checking slot status
  );

  // ==========================================================================
  // Internal Signal Declarations
  // ==========================================================================

  // Inlined wire for conflict detection in write slot updates
  logic conflict_update_write_slot$whas;

  // --------------------------------------------------------------------------
  // Registers for PRT Table 0
  // --------------------------------------------------------------------------
  // prt_table_0_bytes_rcvd: Number of bytes received in table 0 entry.
  logic [15 : 0] prt_table_0_bytes_rcvd;
  logic [15 : 0] prt_table_0_bytes_rcvd$D_IN;
  logic prt_table_0_bytes_rcvd$EN;

  // prt_table_0_bytes_sent_req: Number of bytes requested to be sent in table 0.
  logic [15 : 0] prt_table_0_bytes_sent_req;
  logic [15 : 0] prt_table_0_bytes_sent_req$D_IN;
  logic prt_table_0_bytes_sent_req$EN;

  // prt_table_0_bytes_sent_res: Number of bytes actually sent in table 0.
  logic [15 : 0] prt_table_0_bytes_sent_res;
  logic [15 : 0] prt_table_0_bytes_sent_res$D_IN;
  logic prt_table_0_bytes_sent_res$EN;

  // prt_table_0_is_frame_fully_rcvd: Flag indicating if the complete frame has been
  // received for table 0.
  logic prt_table_0_is_frame_fully_rcvd;
  logic prt_table_0_is_frame_fully_rcvd$D_IN;
  logic prt_table_0_is_frame_fully_rcvd$EN;

  // prt_table_0_valid: Valid flag for the table 0 entry.
  logic prt_table_0_valid;
  logic prt_table_0_valid$D_IN;
  logic prt_table_0_valid$EN;

  // --------------------------------------------------------------------------
  // Registers for PRT Table 1 (Alternate slot)
  // --------------------------------------------------------------------------
  // prt_table_1_bytes_rcvd: Number of bytes received in table 1 entry.
  logic [15 : 0] prt_table_1_bytes_rcvd;
  logic [15 : 0] prt_table_1_bytes_rcvd$D_IN;
  logic prt_table_1_bytes_rcvd$EN;

  // prt_table_1_bytes_sent_req: Number of bytes requested to be sent in table 1.
  logic [15 : 0] prt_table_1_bytes_sent_req;
  logic [15 : 0] prt_table_1_bytes_sent_req$D_IN;
  logic prt_table_1_bytes_sent_req$EN;

  // prt_table_1_bytes_sent_res: Number of bytes actually sent in table 1.
  logic [15 : 0] prt_table_1_bytes_sent_res;
  logic [15 : 0] prt_table_1_bytes_sent_res$D_IN;
  logic prt_table_1_bytes_sent_res$EN;

  // prt_table_1_is_frame_fully_rcvd: Flag indicating if the complete frame has been
  // received for table 1.
  logic prt_table_1_is_frame_fully_rcvd;
  logic prt_table_1_is_frame_fully_rcvd$D_IN;
  logic prt_table_1_is_frame_fully_rcvd$EN;

  // prt_table_1_valid: Valid flag for the table 1 entry.
  logic prt_table_1_valid;
  logic prt_table_1_valid$D_IN; 
  logic prt_table_1_valid$EN;

  // --------------------------------------------------------------------------
  // Registers for Reading and Writing Slot Control
  // --------------------------------------------------------------------------
  // read_slot: Indicates which table (0 or 1) is used for read operations.
  logic [1 : 0] read_slot;
  logic [1 : 0] read_slot$D_IN;
  logic read_slot$EN;

  // using_write_slot: Flag indicating if the write slot is currently in use.
  logic using_write_slot;
  logic using_write_slot$D_IN; 
  logic using_write_slot$EN;

  // write_slot: Indicates which table (0 or 1) is used for write operations and
  // contains additional status bits.
  logic [1 : 0] write_slot;
  logic [1 : 0] write_slot$D_IN;
  logic write_slot$EN;

  // --------------------------------------------------------------------------
  // Ports for Submodule: prt_table_0_frame (BRAM for Table 0)
  // --------------------------------------------------------------------------
  logic [15 : 0] prt_table_0_frame$ADDRA, prt_table_0_frame$ADDRB;
  logic [7 : 0] prt_table_0_frame$DIA,
	       prt_table_0_frame$DIB,
	       prt_table_0_frame$DOB;
  logic prt_table_0_frame$ENA,
       prt_table_0_frame$ENB,
       prt_table_0_frame$WEA,
       prt_table_0_frame$WEB;

  // --------------------------------------------------------------------------
  // Ports for Submodule: prt_table_1_frame (BRAM for Table 1)
  // --------------------------------------------------------------------------
  logic [15 : 0] prt_table_1_frame$ADDRA, prt_table_1_frame$ADDRB;
  logic [7 : 0] prt_table_1_frame$DIA,
	       prt_table_1_frame$DIB,
	       prt_table_1_frame$DOB;
  logic prt_table_1_frame$ENA,
       prt_table_1_frame$ENB,
       prt_table_1_frame$WEA,
       prt_table_1_frame$WEB;

  // --------------------------------------------------------------------------
  // Rule Scheduling Signals
  // --------------------------------------------------------------------------
  // Signal to determine whether the update rule for the write slot should fire.
  logic WILL_FIRE_RL_update_write_slot;

  // --------------------------------------------------------------------------
  // Inputs to Multiplexers for Submodule Ports
  // --------------------------------------------------------------------------
  logic [15 : 0] MUX_prt_table_0_bytes_rcvd$write_1__VAL_1,		MUX_prt_table_0_bytes_sent_req$write_1__VAL_2;
  logic [1 : 0] MUX_read_slot$write_1__VAL_2, MUX_write_slot$write_1__VAL_3;
  logic MUX_prt_table_0_bytes_rcvd$write_1__SEL_1,
       MUX_prt_table_0_bytes_rcvd$write_1__SEL_2,
       MUX_prt_table_0_bytes_sent_res$write_1__SEL_1,
       MUX_prt_table_0_frame$b_put_1__SEL_1,
       MUX_prt_table_0_valid$write_1__SEL_2,
       MUX_prt_table_0_valid$write_1__SEL_3,
       MUX_prt_table_1_bytes_rcvd$write_1__SEL_1,
       MUX_prt_table_1_bytes_rcvd$write_1__SEL_2,
       MUX_prt_table_1_bytes_sent_res$write_1__SEL_1,
       MUX_prt_table_1_frame$b_put_1__SEL_1,
       MUX_prt_table_1_valid$write_1__SEL_2,
       MUX_prt_table_1_valid$write_1__SEL_3,
       MUX_read_slot$write_1__SEL_1,
       MUX_using_write_slot$write_1__SEL_1;

  // --------------------------------------------------------------------------
  // Additional Internal Signals for Computation and Decision Making
  // --------------------------------------------------------------------------
  logic [15 : 0] x2__h2068, x__h2728, y__h2729, y__h2770;
  logic [7 : 0] x__h2676;
  logic CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3,
      CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4,
      CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1,
      CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2,
      SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75,
      SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42;
  logic [15 : 0] x__h2937;
  logic IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77,
       IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78,
       NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47,
       SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69,
       SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85,
       write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39;

  // ==========================================================================
  // Action and Value Method Signal Assignments
  // ==========================================================================

  // --------------------------------------------------------------------------
  // Actionvalue Method: start_writing_prt_entry
  // Assigns the start signal and its ready signal based on the current write slot
  // and the status of the write operation.
  // --------------------------------------------------------------------------
  assign start_writing_prt_entry = write_slot[0] ;
  assign RDY_start_writing_prt_entry = write_slot[1] && !using_write_slot &&
        CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 ;

  // --------------------------------------------------------------------------
  // Action Method: write_prt_entry
  // Ready signal for writing is based on write_slot, whether the write slot is in
  // use, and whether the full frame has not been received.
  // --------------------------------------------------------------------------
  assign RDY_write_prt_entry = write_slot[1] && using_write_slot &&
        CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 ;

  // --------------------------------------------------------------------------
  // Action Method: finish_writing_prt_entry
  // Ready signal for finishing the write operation; same conditions as for writing.
  // --------------------------------------------------------------------------
  assign RDY_finish_writing_prt_entry = write_slot[1] && using_write_slot &&
        CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 ;

  // --------------------------------------------------------------------------
  // Action Method: invalidate_prt_entry
  // Invalidation is always ready.
  // --------------------------------------------------------------------------
  assign RDY_invalidate_prt_entry = 1'd1 ;

  // --------------------------------------------------------------------------
  // Action Method: start_reading_prt_entry
  // Ready signal for starting a read operation is asserted when the second bit
  // of read_slot is low.
  // --------------------------------------------------------------------------
  assign RDY_start_reading_prt_entry = !read_slot[1] ;

  // --------------------------------------------------------------------------
  // Actionvalue Method: read_prt_entry
  // Concatenates the frame data (from the appropriate table) and a flag
  // indicating if the frame is fully received.
  // --------------------------------------------------------------------------
  assign read_prt_entry = { x__h2676, x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 } ;
  assign RDY_read_prt_entry = read_slot[1] && CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 &&
        ((SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 &&
          SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69) ||
         (SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 &&
          y__h2729 == y__h2770 &&
          SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75)) ;

  // --------------------------------------------------------------------------
  // Value Method: is_prt_slot_free
  // Indicates if the write slot is free.
  // --------------------------------------------------------------------------
  assign is_prt_slot_free = write_slot[1] && !using_write_slot ;
  assign RDY_is_prt_slot_free = 1'd1 ;

  // --------------------------------------------------------------------------
  // Submodule: prt_table_0_frame
  // Dual-port BRAM instantiation for table 0 frame data.
  // --------------------------------------------------------------------------
  BRAM2 #(.PIPELINED(1'd0),
	  .ADDR_WIDTH(32'd16),
	  .DATA_WIDTH(32'd8),
	  .MEMSIZE(17'd2000)
	  ) prt_table_0_frame(
	    .CLKA(CLK),
		.CLKB(CLK),
		.ADDRA(prt_table_0_frame$ADDRA),
		.ADDRB(prt_table_0_frame$ADDRB),
		.DIA(prt_table_0_frame$DIA),
		.DIB(prt_table_0_frame$DIB),
		.WEA(prt_table_0_frame$WEA),
		.WEB(prt_table_0_frame$WEB),
		.ENA(prt_table_0_frame$ENA),
		.ENB(prt_table_0_frame$ENB),
		.DOA(),
		.DOB(prt_table_0_frame$DOB));

  // --------------------------------------------------------------------------
  // Submodule: prt_table_1_frame
  // Dual-port BRAM instantiation for table 1 frame data.
  // --------------------------------------------------------------------------
  BRAM2 #(.PIPELINED(1'd0),
	  .ADDR_WIDTH(32'd16),
	  .DATA_WIDTH(32'd8),
	  .MEMSIZE(17'd2000)
	  ) prt_table_1_frame(
	    .CLKA(CLK),
		.CLKB(CLK),
		.ADDRA(prt_table_1_frame$ADDRA),
		.ADDRB(prt_table_1_frame$ADDRB),
		.DIA(prt_table_1_frame$DIA),
		.DIB(prt_table_1_frame$DIB),
		.WEA(prt_table_1_frame$WEA),
		.WEB(prt_table_1_frame$WEB),
		.ENA(prt_table_1_frame$ENA),
		.ENB(prt_table_1_frame$ENB),
		.DOA(),
		.DOB(prt_table_1_frame$DOB));           

  // ==========================================================================
  // Rule: RL_update_write_slot
  // ==========================================================================
  // The rule fires when the write slot is not in use, no conflict is detected,
  // and neither a read nor an invalidate operation is in progress.
  assign WILL_FIRE_RL_update_write_slot = !using_write_slot && !write_slot[1] &&
       !conflict_update_write_slot$whas && !EN_read_prt_entry && !EN_invalidate_prt_entry ;

  // ==========================================================================
  // Multiplexer Inputs for Submodule Port Signals
  // ==========================================================================
  assign MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 = EN_write_prt_entry && write_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 = EN_start_writing_prt_entry && write_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_bytes_sent_res$write_1__SEL_1 = EN_read_prt_entry && read_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_frame$b_put_1__SEL_1 = EN_start_reading_prt_entry &&
         start_reading_prt_entry_slot == 1'd0 &&
         NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 ;
  assign MUX_prt_table_0_valid$write_1__SEL_2 = EN_invalidate_prt_entry &&
         invalidate_prt_entry_slot == 1'd0 &&
         SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 ;
  assign MUX_prt_table_0_valid$write_1__SEL_3 = EN_read_prt_entry &&
         IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77 ;
  assign MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 = EN_write_prt_entry && write_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 = EN_start_writing_prt_entry && write_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_bytes_sent_res$write_1__SEL_1 = EN_read_prt_entry && read_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_frame$b_put_1__SEL_1 = EN_start_reading_prt_entry &&
         start_reading_prt_entry_slot == 1'd1 &&
         NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 ;
  assign MUX_prt_table_1_valid$write_1__SEL_2 = EN_invalidate_prt_entry &&
         invalidate_prt_entry_slot == 1'd1 &&
         SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 ;
  assign MUX_prt_table_1_valid$write_1__SEL_3 = EN_read_prt_entry &&
         IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78 ;
  assign MUX_read_slot$write_1__SEL_1 = EN_read_prt_entry && x__h2937 == y__h2770 &&
         SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign MUX_using_write_slot$write_1__SEL_1 = EN_invalidate_prt_entry &&
         write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 ;
  assign MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 = x2__h2068 + 16'd1 ;
  assign MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 = y__h2729 + 16'd1 ;
  assign MUX_read_slot$write_1__VAL_2 = { 1'd1, start_reading_prt_entry_slot } ;
  assign MUX_write_slot$write_1__VAL_3 = { !prt_table_1_valid || !prt_table_0_valid, !prt_table_1_valid } ;

  // ==========================================================================
  // Inlined Wire Assignment for Conflict Detection
  // ==========================================================================
  assign conflict_update_write_slot$whas =
         (EN_read_prt_entry && x__h2937 == y__h2770 &&
          SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75) ||
         EN_invalidate_prt_entry ;

  // ==========================================================================
  // Register Update Assignments for PRT Table 0 and Table 1
  // ==========================================================================

  // --------------------------------------------------------------------------
  // Register: prt_table_0_bytes_rcvd
  // Updates the count of bytes received for table 0 based on the mux selection.
  // --------------------------------------------------------------------------
  assign prt_table_0_bytes_rcvd$D_IN = MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 ?
         MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 : 16'd0 ;
  assign prt_table_0_bytes_rcvd$EN = (EN_write_prt_entry && write_slot[0] == 1'd0) ||
         (EN_start_writing_prt_entry && write_slot[0] == 1'd0) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_0_bytes_sent_req
  // Sets the requested bytes count for table 0, initializing to 1 if starting.
  // --------------------------------------------------------------------------
  assign prt_table_0_bytes_sent_req$D_IN = MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 ?
         16'd1 : MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 ;
  assign prt_table_0_bytes_sent_req$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd0) ||
         (EN_read_prt_entry && read_slot[0] == 1'd0 &&
          SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_0_bytes_sent_res
  // Stores the actual number of bytes sent for table 0.
  // --------------------------------------------------------------------------
  assign prt_table_0_bytes_sent_res$D_IN = MUX_prt_table_0_bytes_sent_res$write_1__SEL_1 ?
         x__h2937 : 16'd0 ;
  assign prt_table_0_bytes_sent_res$EN = (EN_read_prt_entry && read_slot[0] == 1'd0) ||
         (EN_start_writing_prt_entry && write_slot[0] == 1'd0) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_0_is_frame_fully_rcvd
  // Indicates whether the full frame has been received in table 0.
  // --------------------------------------------------------------------------
  assign prt_table_0_is_frame_fully_rcvd$D_IN = !MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 ;
  assign prt_table_0_is_frame_fully_rcvd$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd0) ||
         (EN_finish_writing_prt_entry && write_slot[0] == 1'd0) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_0_valid
  // Updates the valid flag for table 0 based on write and invalidate operations.
  // --------------------------------------------------------------------------
  assign prt_table_0_valid$D_IN = !MUX_prt_table_0_valid$write_1__SEL_2 &&
         !MUX_prt_table_0_valid$write_1__SEL_3 ;
  assign prt_table_0_valid$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd0) ||
         (EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd0 &&
          SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42) ||
         (EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_1_bytes_rcvd
  // Updates the count of bytes received for table 1.
  // --------------------------------------------------------------------------
  assign prt_table_1_bytes_rcvd$D_IN = MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 ?
         MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 : 16'd0 ;
  assign prt_table_1_bytes_rcvd$EN = (EN_write_prt_entry && write_slot[0] == 1'd1) ||
         (EN_start_writing_prt_entry && write_slot[0] == 1'd1) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_1_bytes_sent_req
  // Sets the requested bytes count for table 1.
  // --------------------------------------------------------------------------
  assign prt_table_1_bytes_sent_req$D_IN = MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 ?
         16'd1 : MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 ;
  assign prt_table_1_bytes_sent_req$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd1) ||
         (EN_read_prt_entry && read_slot[0] == 1'd1 &&
          SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_1_bytes_sent_res
  // Stores the actual number of bytes sent for table 1.
  // --------------------------------------------------------------------------
  assign prt_table_1_bytes_sent_res$D_IN = MUX_prt_table_1_bytes_sent_res$write_1__SEL_1 ?
         x__h2937 : 16'd0 ;
  assign prt_table_1_bytes_sent_res$EN = (EN_read_prt_entry && read_slot[0] == 1'd1) ||
         (EN_start_writing_prt_entry && write_slot[0] == 1'd1) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_1_is_frame_fully_rcvd
  // Indicates whether the full frame has been received in table 1.
  // --------------------------------------------------------------------------
  assign prt_table_1_is_frame_fully_rcvd$D_IN = !MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 ;
  assign prt_table_1_is_frame_fully_rcvd$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd1) ||
         (EN_finish_writing_prt_entry && write_slot[0] == 1'd1) ;

  // --------------------------------------------------------------------------
  // Register: prt_table_1_valid
  // Updates the valid flag for table 1 based on write, read, and invalidate events.
  // --------------------------------------------------------------------------
  assign prt_table_1_valid$D_IN = !MUX_prt_table_1_valid$write_1__SEL_2 &&
         !MUX_prt_table_1_valid$write_1__SEL_3 ;
  assign prt_table_1_valid$EN = (EN_start_writing_prt_entry && write_slot[0] == 1'd1) ||
         (EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd1 &&
          SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42) ||
         (EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78) ;

  // --------------------------------------------------------------------------
  // Register: read_slot
  // Chooses which table to use for read operations.
  // --------------------------------------------------------------------------
  assign read_slot$D_IN = MUX_read_slot$write_1__SEL_1 ? 2'd0 : MUX_read_slot$write_1__VAL_2 ;
  assign read_slot$EN = (EN_read_prt_entry && x__h2937 == y__h2770 &&
         SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75) ||
         (EN_start_reading_prt_entry && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47) ;

  // --------------------------------------------------------------------------
  // Register: using_write_slot
  // Indicates whether the write slot is currently in use.
  // --------------------------------------------------------------------------
  assign using_write_slot$D_IN = !MUX_using_write_slot$write_1__SEL_1 &&
         !EN_finish_writing_prt_entry ;
  assign using_write_slot$EN = (EN_invalidate_prt_entry &&
         write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39) ||
         EN_finish_writing_prt_entry || EN_start_writing_prt_entry ;

  // --------------------------------------------------------------------------
  // Register: write_slot
  // Determines which table is used for writing and updates when the rule fires.
  // --------------------------------------------------------------------------
  assign write_slot$D_IN = WILL_FIRE_RL_update_write_slot ? MUX_write_slot$write_1__VAL_3 : 2'd0 ;
  assign write_slot$EN = (EN_invalidate_prt_entry &&
         write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39) ||
         EN_finish_writing_prt_entry || WILL_FIRE_RL_update_write_slot ;

  // ==========================================================================
  // Submodule Port Assignments for BRAM Interfaces
  // ==========================================================================

  // --------------------------------------------------------------------------
  // Submodule prt_table_0_frame Port Assignments
  // Sets the addresses, data, and control signals for table 0 BRAM.
  // --------------------------------------------------------------------------
  assign prt_table_0_frame$ADDRA = x2__h2068 ;
  assign prt_table_0_frame$ADDRB = MUX_prt_table_0_frame$b_put_1__SEL_1 ? 16'd0 : y__h2729 ;
  assign prt_table_0_frame$DIA = write_prt_entry_data ;
  assign prt_table_0_frame$DIB = MUX_prt_table_0_frame$b_put_1__SEL_1 ? 8'b10101010 : 8'b10101010 ;
  assign prt_table_0_frame$WEA = 1'd1 ;
  assign prt_table_0_frame$WEB = 1'd0 ;
  assign prt_table_0_frame$ENA = MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 ;
  assign prt_table_0_frame$ENB = (EN_start_reading_prt_entry &&
         start_reading_prt_entry_slot == 1'd0 &&
         NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47) ||
         (EN_read_prt_entry && read_slot[0] == 1'd0 &&
         SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69) ;

  // --------------------------------------------------------------------------
  // Submodule prt_table_1_frame Port Assignments
  // Sets the addresses, data, and control signals for table 1 BRAM.
  // --------------------------------------------------------------------------
  assign prt_table_1_frame$ADDRA = x2__h2068 ;
  assign prt_table_1_frame$ADDRB = MUX_prt_table_1_frame$b_put_1__SEL_1 ? 16'd0 : y__h2729 ;
  assign prt_table_1_frame$DIA = write_prt_entry_data ;
  assign prt_table_1_frame$DIB = MUX_prt_table_1_frame$b_put_1__SEL_1 ? 8'b10101010 : 8'b10101010 ;
  assign prt_table_1_frame$WEA = 1'd1 ;
  assign prt_table_1_frame$WEB = 1'd0 ;
  assign prt_table_1_frame$ENA = MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 ;
  assign prt_table_1_frame$ENB = (EN_start_reading_prt_entry &&
         start_reading_prt_entry_slot == 1'd1 &&
         NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47) ||
         (EN_read_prt_entry && read_slot[0] == 1'd1 &&
         SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69) ;

  // ==========================================================================
  // Remaining Internal Signal Assignments
  // ==========================================================================

  assign IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77 =
         (read_slot[0] == 1'd0) && (x__h2937 == y__h2770) &&
         SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78 =
         (read_slot[0] == 1'd1) && (x__h2937 == y__h2770) &&
         SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 = !CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 ;
  assign SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 = (y__h2729 < y__h2770) ;
  assign SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 = (x__h2728 < y__h2729) ;
  assign write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 = write_slot[1] &&
         (write_slot[0] == invalidate_prt_entry_slot) && using_write_slot ;
  assign x__h2937 = x__h2728 + 16'd1 ;
  
  // ==========================================================================
  // Combinational Logic Blocks (always_comb)
  // ==========================================================================

  // --------------------------------------------------------------------------
  // is_frame_fully_rcvd_logic: Determines if the frame is fully received based
  // on the current write slot.
  // --------------------------------------------------------------------------
  always_comb begin : is_frame_fully_rcvd_logic
    case (write_slot[0])
      1'd0: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = !prt_table_0_is_frame_fully_rcvd;
      1'd1: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = !prt_table_1_is_frame_fully_rcvd;
      default: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = 1'bx; // Default (optional)
    endcase
  end

  // --------------------------------------------------------------------------
  // bytes_sent_res_logic: Selects the bytes sent result from the appropriate table.
  // --------------------------------------------------------------------------
  always_comb begin : bytes_sent_res_logic
    case (read_slot[0])
      1'd0: x__h2728 = prt_table_0_bytes_sent_res;
      1'd1: x__h2728 = prt_table_1_bytes_sent_res;
      default: x__h2728 = 'x; // Default case
    endcase
  end

  // --------------------------------------------------------------------------
  // valid_write_logic: Checks the validity of the write operation based on the
  // current write slot.
  // --------------------------------------------------------------------------
  always_comb begin : valid_write_logic
    case (write_slot[0])
      1'd0: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = !prt_table_0_valid;
      1'd1: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = !prt_table_1_valid;
      default: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = 1'bx;
    endcase
  end

  // --------------------------------------------------------------------------
  // bytes_sent_req_logic: Selects the bytes requested count from the appropriate table.
  // --------------------------------------------------------------------------
  always_comb begin : bytes_sent_req_logic
    case (read_slot[0])
      1'd0: y__h2729 = prt_table_0_bytes_sent_req;
      1'd1: y__h2729 = prt_table_1_bytes_sent_req;
      default: y__h2729 = 'x;
    endcase
  end

  // --------------------------------------------------------------------------
  // bytes_rcvd_write_logic: Determines the bytes received value for the write slot.
  // --------------------------------------------------------------------------
  always_comb begin : bytes_rcvd_write_logic
    case (write_slot[0])
      1'd0: x2__h2068 = prt_table_0_bytes_rcvd;
      1'd1: x2__h2068 = prt_table_1_bytes_rcvd;
      default: x2__h2068 = 'x;
    endcase
  end

  // --------------------------------------------------------------------------
  // bytes_rcvd_read_logic: Selects the bytes received value from the appropriate table.
  // --------------------------------------------------------------------------
  always_comb begin : bytes_rcvd_read_logic
    case (read_slot[0])
      1'd0: y__h2770 = prt_table_0_bytes_rcvd;
      1'd1: y__h2770 = prt_table_1_bytes_rcvd;
      default: y__h2770 = 'x;
    endcase
  end

  // --------------------------------------------------------------------------
  // frame_dob_logic: Selects the data output byte from the BRAM based on read slot.
  // --------------------------------------------------------------------------
  always_comb begin : frame_dob_logic
    case (read_slot[0])
      1'd0: x__h2676 = prt_table_0_frame$DOB;
      1'd1: x__h2676 = prt_table_1_frame$DOB;
      default: x__h2676 = 'x;
    endcase
  end

  // --------------------------------------------------------------------------
  // is_frame_fully_rcvd_read_logic: Determines the fully received flag for the
  // current read slot.
  // --------------------------------------------------------------------------
  always_comb begin : is_frame_fully_rcvd_read_logic
    case (read_slot[0])
      1'd0: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = prt_table_0_is_frame_fully_rcvd;
      1'd1: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = prt_table_1_is_frame_fully_rcvd;
      default: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = 1'bx;
    endcase
  end

  // --------------------------------------------------------------------------
  // valid_read_logic: Checks whether the data in the read slot is valid.
  // --------------------------------------------------------------------------
  always_comb begin : valid_read_logic
    case (read_slot[0])
      1'd0: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = prt_table_0_valid;
      1'd1: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = prt_table_1_valid;
      default: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = 1'bx;
    endcase
  end

  // --------------------------------------------------------------------------
  // valid_invalidate_logic: Selects the valid flag for invalidation based on the
  // invalidate slot.
  // --------------------------------------------------------------------------
  always_comb begin : valid_invalidate_logic
    case (invalidate_prt_entry_slot)
      1'd0: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = prt_table_0_valid;
      1'd1: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = prt_table_1_valid;
      default: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = 1'bx;
    endcase
  end

  // --------------------------------------------------------------------------
  // valid_start_read_logic: Determines the condition to start reading based on the slot.
  // --------------------------------------------------------------------------
  always_comb begin : valid_start_read_logic
    case (start_reading_prt_entry_slot)
      1'd0: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = !prt_table_0_valid;
      1'd1: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = !prt_table_1_valid;
      default: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = 1'bx;
    endcase
  end

  // ==========================================================================
  // Sequential Logic: Register Updates on Clock Edge
  // ==========================================================================
  // Updates all registers on the rising edge of CLK or resets them when RST_N is low.
  always @(posedge CLK) begin
    if (!RST_N) begin
      // Reset all registers to their initial values
      prt_table_0_bytes_rcvd       <= '0;
      prt_table_0_bytes_sent_req   <= '0;
      prt_table_0_bytes_sent_res   <= '0;
      prt_table_0_is_frame_fully_rcvd <= '0;
      prt_table_0_valid            <= '0;
      prt_table_1_bytes_rcvd       <= '0;
      prt_table_1_bytes_sent_req   <= '0;
      prt_table_1_bytes_sent_res   <= '0;
      prt_table_1_is_frame_fully_rcvd <= '0;
      prt_table_1_valid            <= '0;
      read_slot                    <= 2'd2;
      using_write_slot             <= '0;
      write_slot                   <= 2'd2; 
    end else begin
      // Update registers if their enable signals are asserted
      if (prt_table_0_bytes_rcvd$EN)       prt_table_0_bytes_rcvd       <= prt_table_0_bytes_rcvd$D_IN;
      if (prt_table_0_bytes_sent_req$EN)   prt_table_0_bytes_sent_req   <= prt_table_0_bytes_sent_req$D_IN;
      if (prt_table_0_bytes_sent_res$EN)   prt_table_0_bytes_sent_res   <= prt_table_0_bytes_sent_res$D_IN;
      if (prt_table_0_is_frame_fully_rcvd$EN) prt_table_0_is_frame_fully_rcvd <= prt_table_0_is_frame_fully_rcvd$D_IN;
      if (prt_table_0_valid$EN)            prt_table_0_valid            <= prt_table_0_valid$D_IN;
      if (prt_table_1_bytes_rcvd$EN)       prt_table_1_bytes_rcvd       <= prt_table_1_bytes_rcvd$D_IN;
      if (prt_table_1_bytes_sent_req$EN)   prt_table_1_bytes_sent_req   <= prt_table_1_bytes_sent_req$D_IN;
      if (prt_table_1_bytes_sent_res$EN)   prt_table_1_bytes_sent_res   <= prt_table_1_bytes_sent_res$D_IN;
      if (prt_table_1_is_frame_fully_rcvd$EN) prt_table_1_is_frame_fully_rcvd <= prt_table_1_is_frame_fully_rcvd$D_IN;
      if (prt_table_1_valid$EN)            prt_table_1_valid            <= prt_table_1_valid$D_IN;
      if (read_slot$EN)                    read_slot                    <= read_slot$D_IN;
      if (using_write_slot$EN)             using_write_slot             <= using_write_slot$D_IN;
      if (write_slot$EN)                   write_slot                   <= write_slot$D_IN;
    end
  end

  // ==========================================================================
  // Initial Block: Register Initialization
  // ==========================================================================
  // Sets initial values for all registers during simulation startup.
  initial begin
    prt_table_0_bytes_rcvd       = '0;
    prt_table_0_bytes_sent_req   = '0;
    prt_table_0_bytes_sent_res   = '0;
    prt_table_0_is_frame_fully_rcvd = '0;
    prt_table_0_valid            = '0;
    prt_table_1_bytes_rcvd       = '0;
    prt_table_1_bytes_sent_req   = '0;
    prt_table_1_bytes_sent_res   = '0;
    prt_table_1_is_frame_fully_rcvd = '0;
    prt_table_1_valid            = '0;
    read_slot                    = '0;
    using_write_slot             = '0;
    write_slot                   = '0; 
  end

endmodule


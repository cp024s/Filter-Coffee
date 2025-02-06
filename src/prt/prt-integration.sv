`timescale 1ns/1ps

module mkPRT(

// ------------------------------------------------------- INPUT AND OUTPUT PORTS -------------------------------------------------------

  input  logic CLK,                    // Clock signal for synchronization of the design.
  input  logic RST_N,                  // Active-low reset signal for resetting the design to its initial state.

  // actionvalue method start_writing_prt_entry
  input  logic EN_start_writing_prt_entry, // Enable signal for starting the writing of PRT (Packet Reference Table) entry.
  output logic start_writing_prt_entry,    // Output signal indicating that the process of writing a PRT entry has started.
  output logic RDY_start_writing_prt_entry, // Ready signal indicating that the module is ready to start writing a PRT entry.

  // action method write_prt_entry
  input  logic [7:0] write_prt_entry_data, // 8-bit input data for writing to the PRT entry.
  input  logic EN_write_prt_entry,         // Enable signal for writing a PRT entry.
  output logic RDY_write_prt_entry,        // Ready signal indicating the module is ready for writing the PRT entry.

  // action method finish_writing_prt_entry
  input  logic EN_finish_writing_prt_entry, // Enable signal for finishing the writing of a PRT entry.
  output logic RDY_finish_writing_prt_entry, // Ready signal indicating the module is ready to finish writing the PRT entry.

  // action method invalidate_prt_entry
  input  logic invalidate_prt_entry_slot,  // Input signal to specify which PRT entry slot to invalidate.
  input  logic EN_invalidate_prt_entry,    // Enable signal for invalidating the specified PRT entry slot.
  output logic RDY_invalidate_prt_entry,   // Ready signal indicating the module is ready to invalidate the PRT entry slot.

  // action method start_reading_prt_entry
  input  logic start_reading_prt_entry_slot, // Input signal specifying the slot from which to start reading the PRT entry.
  input  logic EN_start_reading_prt_entry,  // Enable signal for starting the reading of a PRT entry.
  output logic RDY_start_reading_prt_entry, // Ready signal indicating the module is ready to start reading the PRT entry.

  // actionvalue method read_prt_entry
  input  logic EN_read_prt_entry,            // Enable signal for reading a PRT entry.
  output logic [8 : 0] read_prt_entry,       // 9-bit output data representing the read PRT entry.
  output logic RDY_read_prt_entry,           // Ready signal indicating the module is ready to output the PRT entry data.

  // value method is_prt_slot_free
  output logic is_prt_slot_free,             // Output signal indicating whether the PRT entry slot is free or not.
  output logic RDY_is_prt_slot_free          // Ready signal indicating the module is ready to provide the status of the PRT slot.
  
  );
  
// ----------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------- INLINE WIRES -------------------------------------------------------

  // inlined wires
  logic conflict_update_write_slot$whas;      // Wire used for tracking a conflict during the update of the write slot.

  // register prt_table_0_bytes_rcvd
  logic [15 : 0] prt_table_0_bytes_rcvd;      // 16-bit register storing the number of bytes received for the PRT entry 0.
  logic [15 : 0] prt_table_0_bytes_rcvd$D_IN; // 16-bit register for input data (D_IN) related to prt_table_0_bytes_rcvd.
  logic prt_table_0_bytes_rcvd$EN;            // Enable signal for updating prt_table_0_bytes_rcvd.

  // register prt_table_0_bytes_sent_req
  logic [15 : 0] prt_table_0_bytes_sent_req;      // 16-bit register storing the requested bytes sent for PRT entry 0.
  logic [15 : 0] prt_table_0_bytes_sent_req$D_IN; // 16-bit register for input data (D_IN) related to prt_table_0_bytes_sent_req.
  logic prt_table_0_bytes_sent_req$EN;            // Enable signal for updating prt_table_0_bytes_sent_req.

  // register prt_table_0_bytes_sent_res
  logic [15 : 0] prt_table_0_bytes_sent_res;      // 16-bit register storing the actual bytes sent for PRT entry 0.
  logic [15 : 0] prt_table_0_bytes_sent_res$D_IN; // 16-bit register for input data (D_IN) related to prt_table_0_bytes_sent_res.
  logic prt_table_0_bytes_sent_res$EN;            // Enable signal for updating prt_table_0_bytes_sent_res.

  // register prt_table_0_is_frame_fully_rcvd
  logic prt_table_0_is_frame_fully_rcvd;      // Register indicating whether the frame for PRT entry 0 is fully received.
  logic prt_table_0_is_frame_fully_rcvd$D_IN; // Data input (D_IN) for prt_table_0_is_frame_fully_rcvd.
  logic prt_table_0_is_frame_fully_rcvd$EN;   // Enable signal for updating prt_table_0_is_frame_fully_rcvd.

  // register prt_table_0_valid
  logic prt_table_0_valid;                    // Register indicating whether PRT entry 0 is valid.
  logic prt_table_0_valid$D_IN;               // Data input (D_IN) for prt_table_0_valid.
  logic prt_table_0_valid$EN;                 // Enable signal for updating prt_table_0_valid.

  // register prt_table_1_bytes_rcvd
  logic [15 : 0] prt_table_1_bytes_rcvd;      // 16-bit register storing the number of bytes received for the PRT entry 1.
  logic [15 : 0] prt_table_1_bytes_rcvd$D_IN; // 16-bit register for input data (D_IN) related to prt_table_1_bytes_rcvd.
  logic prt_table_1_bytes_rcvd$EN;            // Enable signal for updating prt_table_1_bytes_rcvd.

  // register prt_table_1_bytes_sent_req
  logic [15 : 0] prt_table_1_bytes_sent_req;      // 16-bit register storing the requested bytes sent for PRT entry 1.
  logic [15 : 0] prt_table_1_bytes_sent_req$D_IN; // 16-bit register for input data (D_IN) related to prt_table_1_bytes_sent_req.
  logic prt_table_1_bytes_sent_req$EN;            // Enable signal for updating prt_table_1_bytes_sent_req.

  // register prt_table_1_bytes_sent_res
  logic [15 : 0] prt_table_1_bytes_sent_res;      // 16-bit register storing the actual bytes sent for PRT entry 1.
  logic [15 : 0] prt_table_1_bytes_sent_res$D_IN; // 16-bit register for input data (D_IN) related to prt_table_1_bytes_sent_res.
  logic prt_table_1_bytes_sent_res$EN;            // Enable signal for updating prt_table_1_bytes_sent_res.

  // register prt_table_1_is_frame_fully_rcvd
  logic prt_table_1_is_frame_fully_rcvd;      // Register indicating whether the frame for PRT entry 1 is fully received.
  logic prt_table_1_is_frame_fully_rcvd$D_IN; // Data input (D_IN) for prt_table_1_is_frame_fully_rcvd.
  logic prt_table_1_is_frame_fully_rcvd$EN;   // Enable signal for updating prt_table_1_is_frame_fully_rcvd.

  // register prt_table_1_valid
  logic prt_table_1_valid;                    // Register indicating whether PRT entry 1 is valid.
  logic prt_table_1_valid$D_IN;               // Data input (D_IN) for prt_table_1_valid.
  logic prt_table_1_valid$EN;                 // Enable signal for updating prt_table_1_valid.

  // register read_slot
  logic [1 : 0] read_slot;                    // 2-bit register specifying the slot to read from the PRT.
  logic [1 : 0] read_slot$D_IN;               // Data input (D_IN) for read_slot.
  logic read_slot$EN;                         // Enable signal for updating read_slot.

  // register using_write_slot
  logic using_write_slot;                    // Register indicating whether the write slot is currently in use.
  logic using_write_slot$D_IN;               // Data input (D_IN) for using_write_slot.
  logic using_write_slot$EN;                 // Enable signal for updating using_write_slot.

  // register write_slot
  logic [1 : 0] write_slot;                  // 2-bit register specifying the write slot for the PRT.
  logic [1 : 0] write_slot$D_IN;             // Data input (D_IN) for write_slot.
  logic write_slot$EN;                       // Enable signal for updating write_slot.


// Ports for prt_table_0_frame submodule
logic [15:0] prt_table_0_frame$ADDRA, prt_table_0_frame$ADDRB;                    // Address lines for read and write operations on prt_table_0
logic [7:0] prt_table_0_frame$DIA, prt_table_0_frame$DIB, prt_table_0_frame$DOB;  // Data input and output signals for prt_table_0 (DIA for A, DIB for B, DOB for data output)
logic prt_table_0_frame$ENA, prt_table_0_frame$ENB;                               // Enable signals for prt_table_0 frame (ENA for A, ENB for B)
logic prt_table_0_frame$WEA, prt_table_0_frame$WEB;                               // Write Enable signals for prt_table_0 (WEA for A, WEB for B)

// Ports for prt_table_1_frame submodule (same functionality as prt_table_0)
logic [15:0] prt_table_1_frame$ADDRA, prt_table_1_frame$ADDRB;                    // Address lines for prt_table_1
logic [7:0] prt_table_1_frame$DIA, prt_table_1_frame$DIB, prt_table_1_frame$DOB;  // Data input and output signals for prt_table_1
logic prt_table_1_frame$ENA, prt_table_1_frame$ENB;                               // Enable signals for prt_table_1 (ENA for A, ENB for B)
logic prt_table_1_frame$WEA, prt_table_1_frame$WEB;                               // Write Enable signals for prt_table_1 (WEA for A, WEB for B)

// Rule scheduling signals (indicates whether the write slot rule will fire)
logic WILL_FIRE_RL_update_write_slot;

// Inputs to multiplexers for submodule ports
logic [15:0] MUX_prt_table_0_bytes_rcvd$write_1__VAL_1, MUX_prt_table_0_bytes_sent_req$write_1__VAL_2;  // Values to be multiplexed for prt_table_0 byte received and byte sent request
logic [1:0] MUX_read_slot$write_1__VAL_2, MUX_write_slot$write_1__VAL_3;                                // Values for read and write slot selection
logic MUX_prt_table_0_bytes_rcvd$write_1__SEL_1, MUX_prt_table_0_bytes_rcvd$write_1__SEL_2;             // Select signals for prt_table_0 byte received multiplexer
logic MUX_prt_table_0_bytes_sent_res$write_1__SEL_1, MUX_prt_table_0_frame$b_put_1__SEL_1;              // Select signals for prt_table_0 byte sent result and frame put multiplexer
logic MUX_prt_table_0_valid$write_1__SEL_2, MUX_prt_table_0_valid$write_1__SEL_3;                       // Select signals for prt_table_0 valid signal multiplexers
logic MUX_prt_table_1_bytes_rcvd$write_1__SEL_1, MUX_prt_table_1_bytes_rcvd$write_1__SEL_2;             // Select signals for prt_table_1 byte received multiplexer
logic MUX_prt_table_1_bytes_sent_res$write_1__SEL_1, MUX_prt_table_1_frame$b_put_1__SEL_1;              // Select signals for prt_table_1 byte sent result and frame put multiplexer
logic MUX_prt_table_1_valid$write_1__SEL_2, MUX_prt_table_1_valid$write_1__SEL_3;                       // Select signals for prt_table_1 valid signal multiplexers
logic MUX_read_slot$write_1__SEL_1, MUX_using_write_slot$write_1__SEL_1;                                // Select signals for read slot and write slot multiplexers

// Internal signal definitions
logic [15:0] x2__h2068, x__h2728, y__h2729, y__h2770;  // Internal signal values for processing
logic [7:0] x__h2676;  // 8-bit internal signal for processing
logic CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3, CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4;      // Case statements for various conditions in the process flow
logic CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1, CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2;      // Case conditions for write slot and table validity
logic SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75, SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42;  // Signals for selection and validation of frame reception and validity
logic [15:0] x__h2937;  // 16-bit internal signal for further processing
logic IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77, IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78;  // Conditional processing for read slot status
logic NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47, SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69;  // Signals for byte sent requests and negations in selection array
logic SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85, write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39;  // Signals for byte sent results and conditional logic for write slot

// ----------------------------------------------------------------------------------------------------------------------------

// -------------------------------------------------------  -------------------------------------------------------

// Actionvalue method start_writing_prt_entry
// 'start_writing_prt_entry' is assigned to the value of the first bit of 'write_slot',
// indicating the start of the write operation for the PRT (Packet Reference Table) entry.
assign start_writing_prt_entry = write_slot[0]; 

// 'RDY_start_writing_prt_entry' is assigned to true when:
// 1. The second bit of 'write_slot' is set (indicating readiness to write).
// 2. 'using_write_slot' is false (ensuring no other write slot is being used).
// 3. 'CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2' is true (indicating the PRT entry is valid).
assign RDY_start_writing_prt_entry = write_slot[1] && !using_write_slot && CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2;

// Action method write_prt_entry
// 'RDY_write_prt_entry' is activated when:
// 1. The second bit of 'write_slot' is set (indicating readiness to write).
// 2. 'using_write_slot' is true (indicating that a write slot is in use).
// 3. 'CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1' is true (indicating it's not flagged as a frame).
assign RDY_write_prt_entry = write_slot[1] && using_write_slot && CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1;

// Action method finish_writing_prt_entry
// 'RDY_finish_writing_prt_entry' is activated under the same conditions as 'RDY_write_prt_entry',
// indicating that the system is ready to finish writing a PRT entry.
assign RDY_finish_writing_prt_entry = write_slot[1] && using_write_slot && CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1;

// Action method invalidate_prt_entry
// This is always active (constant value '1'd1'), allowing the invalidate action to proceed without conditions.
assign RDY_invalidate_prt_entry = 1'd1;

// Action method start_reading_prt_entry
// 'RDY_start_reading_prt_entry' is activated when the second bit of 'read_slot' is not set,
// meaning the system is ready to start reading from the PRT entry.
assign RDY_start_reading_prt_entry = !read_slot[1];

// Actionvalue method read_prt_entry
// 'read_prt_entry' is a combination of signals:
// 1. The signal 'x__h2937' is compared with 'y__h2770'.
// 2. If true, 'SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75' ensures the frame is fully received.
// The result triggers the reading of the PRT entry.
assign read_prt_entry = { x__h2676, x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 };

// Readiness signal for 'read_prt_entry' is activated when:
// 1. The second bit of 'read_slot' is set (indicating readiness to read).
// 2. 'CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3' ensures the read data is valid.
// 3. The byte sent conditions are satisfied, or the frame is fully received and valid.
assign RDY_read_prt_entry = read_slot[1] && CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 &&
                            (SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 && SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 || 
                             SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 && y__h2729 == y__h2770 && 
                             SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75);

// Value method is_prt_slot_free
// 'is_prt_slot_free' is true when:
// 1. The second bit of 'write_slot' is set (indicating availability).
// 2. 'using_write_slot' is false (ensuring no write slot is being used).
assign is_prt_slot_free = write_slot[1] && !using_write_slot;

// Readiness signal for 'is_prt_slot_free' is always active (constant value '1'd1'),
// meaning the system can always check if a PRT slot is free.
assign RDY_is_prt_slot_free = 1'd1;

// ----------------------------------------------------------------------------------------------------------------------------

// ------------------------------------------------------- BRAM MODULE INSTANCES -------------------------------------------------------

// BRAM2 instance for prt_table_0_frame
// This module instantiates a Block RAM (BRAM) to store the PRT table 0 frame data
// with the specified parameters like address width, data width, and memory size.

BRAM2 #(.PIPELINED(1'd0),                         // PIPELINED is set to 0, meaning no pipelining in the BRAM access.
        .ADDR_WIDTH(32'd16),                      // Address width is set to 16 bits (addressable space of 2^16).
        .DATA_WIDTH(32'd8),                       // Data width is set to 8 bits (1 byte per data entry).
        .MEMSIZE(17'd2000)                        // Memory size is 2000 entries (addressable with 17 bits).
       ) prt_table_0_frame(                       // Instance name 'prt_table_0_frame'
            .CLKA(CLK),                           // Clock for port A (input side)
            .CLKB(CLK),                           // Clock for port B (output side), both using the same clock signal (CLK).
            .ADDRA(prt_table_0_frame$ADDRA),      // Address input for port A (used for writing to the BRAM).
            .ADDRB(prt_table_0_frame$ADDRB),      // Address input for port B (used for reading from the BRAM).
            .DIA(prt_table_0_frame$DIA),          // Data input for port A (data to be written to the BRAM).
            .DIB(prt_table_0_frame$DIB),          // Data input for port B (data read from the BRAM).
            .WEA(prt_table_0_frame$WEA),          // Write enable signal for port A (controls writing data to the BRAM).
            .WEB(prt_table_0_frame$WEB),          // Write enable signal for port B (controls writing data to the BRAM).
            .ENA(prt_table_0_frame$ENA),          // Enable signal for port A (activates the BRAM for reading/writing).
            .ENB(prt_table_0_frame$ENB),          // Enable signal for port B (activates the BRAM for reading).
            .DOA(),                               // Data output for port A (unused in this case).
            .DOB(prt_table_0_frame$DOB)           // Data output for port B (used for reading data from the BRAM).
        );

// BRAM2 instance for prt_table_1_frame
// This module instantiates another Block RAM (BRAM) to store the PRT table 1 frame data
// with similar parameters as the first BRAM instance, but this one is separate for prt_table_1.

BRAM2 #(.PIPELINED(1'd0),                        // PIPELINED is set to 0, meaning no pipelining in the BRAM access.
        .ADDR_WIDTH(32'd16),                     // Address width is set to 16 bits (addressable space of 2^16).
        .DATA_WIDTH(32'd8),                      // Data width is set to 8 bits (1 byte per data entry).
        .MEMSIZE(17'd2000)                       // Memory size is 2000 entries (addressable with 17 bits).
       ) prt_table_1_frame(                      // Instance name 'prt_table_1_frame'
            .CLKA(CLK),                          // Clock for port A (input side).
            .CLKB(CLK),                          // Clock for port B (output side), both using the same clock signal (CLK).
            .ADDRA(prt_table_1_frame$ADDRA),      // Address input for port A (used for writing to the BRAM).
            .ADDRB(prt_table_1_frame$ADDRB),      // Address input for port B (used for reading from the BRAM).
            .DIA(prt_table_1_frame$DIA),          // Data input for port A (data to be written to the BRAM).
            .DIB(prt_table_1_frame$DIB),          // Data input for port B (data read from the BRAM).
            .WEA(prt_table_1_frame$WEA),          // Write enable signal for port A (controls writing data to the BRAM).
            .WEB(prt_table_1_frame$WEB),          // Write enable signal for port B (controls writing data to the BRAM).
            .ENA(prt_table_1_frame$ENA),          // Enable signal for port A (activates the BRAM for reading/writing).
            .ENB(prt_table_1_frame$ENB),          // Enable signal for port B (activates the BRAM for reading).
            .DOA(),                               // Data output for port A (unused in this case).
            .DOB(prt_table_1_frame$DOB)           // Data output for port B (used for reading data from the BRAM).
        );


  // rule RL_update_write_slot
  assign WILL_FIRE_RL_update_write_slot = !using_write_slot && !write_slot[1] && !conflict_update_write_slot$whas && !EN_read_prt_entry && !EN_invalidate_prt_entry ;

  // inputs to muxes for submodule ports
  assign MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 = EN_write_prt_entry && write_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 = EN_start_writing_prt_entry && write_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_bytes_sent_res$write_1__SEL_1 = EN_read_prt_entry && read_slot[0] == 1'd0 ;
  assign MUX_prt_table_0_frame$b_put_1__SEL_1 = EN_start_reading_prt_entry && start_reading_prt_entry_slot == 1'd0 && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 ;
  assign MUX_prt_table_0_valid$write_1__SEL_2 = EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd0 && SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 ;
  assign MUX_prt_table_0_valid$write_1__SEL_3 = EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77 ;
  assign MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 = EN_write_prt_entry && write_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 = EN_start_writing_prt_entry && write_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_bytes_sent_res$write_1__SEL_1 = EN_read_prt_entry && read_slot[0] == 1'd1 ;
  assign MUX_prt_table_1_frame$b_put_1__SEL_1 = EN_start_reading_prt_entry && start_reading_prt_entry_slot == 1'd1 && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 ;
  assign MUX_prt_table_1_valid$write_1__SEL_2 = EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd1 && SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 ;
  assign MUX_prt_table_1_valid$write_1__SEL_3 = EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78 ;
  assign MUX_read_slot$write_1__SEL_1 = EN_read_prt_entry && x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign MUX_using_write_slot$write_1__SEL_1 = EN_invalidate_prt_entry && write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 ;
  assign MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 = x2__h2068 + 16'd1 ;
  assign MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 = y__h2729 + 16'd1 ;
  assign MUX_read_slot$write_1__VAL_2 = { 1'd1, start_reading_prt_entry_slot } ;
  assign MUX_write_slot$write_1__VAL_3 = { !prt_table_1_valid || !prt_table_0_valid, !prt_table_1_valid } ;

  // inlined wires
  assign conflict_update_write_slot$whas = EN_read_prt_entry && x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 || EN_invalidate_prt_entry ;

  // register prt_table_0_bytes_rcvd
  assign prt_table_0_bytes_rcvd$D_IN = MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 ? MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 : 16'd0 ;
  assign prt_table_0_bytes_rcvd$EN = EN_write_prt_entry && write_slot[0] == 1'd0 || EN_start_writing_prt_entry && write_slot[0] == 1'd0 ;

  // register prt_table_0_bytes_sent_req
  assign prt_table_0_bytes_sent_req$D_IN = MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 ? 16'd1 : MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 ;
  assign prt_table_0_bytes_sent_req$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd0 || EN_read_prt_entry && read_slot[0] == 1'd0 && SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 ;

  // register prt_table_0_bytes_sent_res
  assign prt_table_0_bytes_sent_res$D_IN = MUX_prt_table_0_bytes_sent_res$write_1__SEL_1 ? x__h2937 : 16'd0 ;
  assign prt_table_0_bytes_sent_res$EN = EN_read_prt_entry && read_slot[0] == 1'd0 || EN_start_writing_prt_entry && write_slot[0] == 1'd0 ;

  // register prt_table_0_is_frame_fully_rcvd
  assign prt_table_0_is_frame_fully_rcvd$D_IN = !MUX_prt_table_0_bytes_rcvd$write_1__SEL_2 ;
  assign prt_table_0_is_frame_fully_rcvd$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd0 || EN_finish_writing_prt_entry && write_slot[0] == 1'd0 ;

  // register prt_table_0_valid
  assign prt_table_0_valid$D_IN = !MUX_prt_table_0_valid$write_1__SEL_2 && !MUX_prt_table_0_valid$write_1__SEL_3 ;
  assign prt_table_0_valid$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd0 || EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd0 && SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 || EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77 ;

  // register prt_table_1_bytes_rcvd
  assign prt_table_1_bytes_rcvd$D_IN = MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 ? MUX_prt_table_0_bytes_rcvd$write_1__VAL_1 : 16'd0 ;
  assign prt_table_1_bytes_rcvd$EN = EN_write_prt_entry && write_slot[0] == 1'd1 || EN_start_writing_prt_entry && write_slot[0] == 1'd1 ;

  // register prt_table_1_bytes_sent_req
  assign prt_table_1_bytes_sent_req$D_IN = MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 ? 16'd1 : MUX_prt_table_0_bytes_sent_req$write_1__VAL_2 ;
  assign prt_table_1_bytes_sent_req$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd1 || EN_read_prt_entry && read_slot[0] == 1'd1 && SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 ;

  // register prt_table_1_bytes_sent_res
  assign prt_table_1_bytes_sent_res$D_IN = MUX_prt_table_1_bytes_sent_res$write_1__SEL_1 ? x__h2937 : 16'd0 ;
  assign prt_table_1_bytes_sent_res$EN = EN_read_prt_entry && read_slot[0] == 1'd1 || EN_start_writing_prt_entry && write_slot[0] == 1'd1 ;

  // register prt_table_1_is_frame_fully_rcvd
  assign prt_table_1_is_frame_fully_rcvd$D_IN = !MUX_prt_table_1_bytes_rcvd$write_1__SEL_2 ;
  assign prt_table_1_is_frame_fully_rcvd$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd1 || EN_finish_writing_prt_entry && write_slot[0] == 1'd1 ;

  // register prt_table_1_valid
  assign prt_table_1_valid$D_IN = !MUX_prt_table_1_valid$write_1__SEL_2 && !MUX_prt_table_1_valid$write_1__SEL_3 ;
  assign prt_table_1_valid$EN = EN_start_writing_prt_entry && write_slot[0] == 1'd1 || EN_invalidate_prt_entry && invalidate_prt_entry_slot == 1'd1 && SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 || EN_read_prt_entry && IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78 ;

  // register read_slot
  assign read_slot$D_IN = MUX_read_slot$write_1__SEL_1 ? 2'd0 : MUX_read_slot$write_1__VAL_2 ;
  assign read_slot$EN = EN_read_prt_entry && x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 || EN_start_reading_prt_entry && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 ;

  // register using_write_slot
  assign using_write_slot$D_IN = !MUX_using_write_slot$write_1__SEL_1 && !EN_finish_writing_prt_entry ;
  assign using_write_slot$EN = EN_invalidate_prt_entry && write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 || EN_finish_writing_prt_entry || EN_start_writing_prt_entry ;

  // register write_slot
  assign write_slot$D_IN = WILL_FIRE_RL_update_write_slot ? MUX_write_slot$write_1__VAL_3 : 2'd0 ;
  assign write_slot$EN = EN_invalidate_prt_entry && write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 || EN_finish_writing_prt_entry || WILL_FIRE_RL_update_write_slot ;

  // submodule prt_table_0_frame
  assign prt_table_0_frame$ADDRA = x2__h2068 ;
  assign prt_table_0_frame$ADDRB = MUX_prt_table_0_frame$b_put_1__SEL_1 ? 16'd0 : y__h2729 ;
  assign prt_table_0_frame$DIA = write_prt_entry_data ;
  assign prt_table_0_frame$DIB = MUX_prt_table_0_frame$b_put_1__SEL_1 ? 8'b10101010 : 8'b10101010 ;
  assign prt_table_0_frame$WEA = 1'd1 ;
  assign prt_table_0_frame$WEB = 1'd0 ;
  assign prt_table_0_frame$ENA = MUX_prt_table_0_bytes_rcvd$write_1__SEL_1 ;
  assign prt_table_0_frame$ENB = EN_start_reading_prt_entry && start_reading_prt_entry_slot == 1'd0 && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 || EN_read_prt_entry && read_slot[0] == 1'd0 && SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 ;

  // submodule prt_table_1_frame
  assign prt_table_1_frame$ADDRA = x2__h2068 ;
  assign prt_table_1_frame$ADDRB = MUX_prt_table_1_frame$b_put_1__SEL_1 ? 16'd0 : y__h2729 ;
  assign prt_table_1_frame$DIA = write_prt_entry_data ;
  assign prt_table_1_frame$DIB = MUX_prt_table_1_frame$b_put_1__SEL_1 ? 8'b10101010  : 8'b10101010 ;
  assign prt_table_1_frame$WEA = 1'd1 ;
  assign prt_table_1_frame$WEB = 1'd0 ;
  assign prt_table_1_frame$ENA = MUX_prt_table_1_bytes_rcvd$write_1__SEL_1 ;
  assign prt_table_1_frame$ENB = EN_start_reading_prt_entry && start_reading_prt_entry_slot == 1'd1 && NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 || EN_read_prt_entry && read_slot[0] == 1'd1 && SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 ;

  // remaining internal signals
  assign IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d77 = read_slot[0] == 1'd0 && x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign IF_read_slot_3_BIT_1_4_THEN_read_slot_3_BIT_0__ETC___d78 = read_slot[0] == 1'd1 && x__h2937 == y__h2770 && SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 ;
  assign NOT_SEL_ARR_NOT_prt_table_0_valid_2_3_NOT_prt__ETC___d47 = !CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 ;
  assign SEL_ARR_prt_table_0_bytes_sent_req_4_prt_table_ETC___d69 = y__h2729 < y__h2770 ;
  assign SEL_ARR_prt_table_0_bytes_sent_res_8_prt_table_ETC___d85 = x__h2728 < y__h2729 ;
  assign write_slot_BIT_1_AND_IF_write_slot_BIT_1_THEN__ETC___d39 = write_slot[1] && write_slot[0] == invalidate_prt_entry_slot && using_write_slot ;
  assign x__h2937 = x__h2728 + 16'd1 ;
  
  always_comb begin : is_frame_fully_rcvd_logic
  case (write_slot[0])
    1'd0: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = !prt_table_0_is_frame_fully_rcvd;
    1'd1: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = !prt_table_1_is_frame_fully_rcvd;
    default: CASE_write_slot_BIT_0_0_NOT_prt_table_0_is_fra_ETC__q1 = 1'bx; // Handle default case (optional but good practice)
  endcase
end

always_comb begin : bytes_sent_res_logic
  case (read_slot[0])
    1'd0: x__h2728 = prt_table_0_bytes_sent_res;
    1'd1: x__h2728 = prt_table_1_bytes_sent_res;
    default: x__h2728 = 'x; // Default case
  endcase
end

always_comb begin : valid_write_logic
  case (write_slot[0])
    1'd0: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = !prt_table_0_valid;
    1'd1: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = !prt_table_1_valid;
    default: CASE_write_slot_BIT_0_0_NOT_prt_table_0_valid__ETC__q2 = 1'bx;
  endcase
end

always_comb begin : bytes_sent_req_logic
  case (read_slot[0])
    1'd0: y__h2729 = prt_table_0_bytes_sent_req;
    1'd1: y__h2729 = prt_table_1_bytes_sent_req;
    default: y__h2729 = 'x;
  endcase
end

always_comb begin : bytes_rcvd_write_logic
  case (write_slot[0])
    1'd0: x2__h2068 = prt_table_0_bytes_rcvd;
    1'd1: x2__h2068 = prt_table_1_bytes_rcvd;
    default: x2__h2068 = 'x;
  endcase
end

always_comb begin : bytes_rcvd_read_logic
  case (read_slot[0])
    1'd0: y__h2770 = prt_table_0_bytes_rcvd;
    1'd1: y__h2770 = prt_table_1_bytes_rcvd;
    default: y__h2770 = 'x;
  endcase
end

always_comb begin : frame_dob_logic
  case (read_slot[0])
    1'd0: x__h2676 = prt_table_0_frame$DOB;
    1'd1: x__h2676 = prt_table_1_frame$DOB;
    default: x__h2676 = 'x;
  endcase
end

always_comb begin : is_frame_fully_rcvd_read_logic
  case (read_slot[0])
    1'd0: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = prt_table_0_is_frame_fully_rcvd;
    1'd1: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = prt_table_1_is_frame_fully_rcvd;
    default: SEL_ARR_prt_table_0_is_frame_fully_rcvd_9_prt__ETC___d75 = 1'bx;
  endcase
end

always_comb begin : valid_read_logic
  case (read_slot[0])
    1'd0: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = prt_table_0_valid;
    1'd1: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = prt_table_1_valid;
    default: CASE_read_slot_BIT_0_0_prt_table_0_valid_1_prt_ETC__q3 = 1'bx;
  endcase
end

always_comb begin : valid_invalidate_logic
  case (invalidate_prt_entry_slot)
    1'd0: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = prt_table_0_valid;
    1'd1: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = prt_table_1_valid;
    default: SEL_ARR_prt_table_0_valid_2_prt_table_1_valid__ETC___d42 = 1'bx;
  endcase
end

always_comb begin : valid_start_read_logic
  case (start_reading_prt_entry_slot)
    1'd0: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = !prt_table_0_valid;
    1'd1: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = !prt_table_1_valid;
    default: CASE_start_reading_prt_entry_slot_0_NOT_prt_ta_ETC__q4 = 1'bx;
  endcase
end

  // handling of inlined registers

  always @(posedge CLK) begin
  if (!RST_N) begin
    prt_table_0_bytes_rcvd <= '0;
    prt_table_0_bytes_sent_req <= '0;
    prt_table_0_bytes_sent_res <= '0;
    prt_table_0_is_frame_fully_rcvd <= '0;
    prt_table_0_valid <= '0;
    prt_table_1_bytes_rcvd <= '0;
    prt_table_1_bytes_sent_req <= '0;
    prt_table_1_bytes_sent_res <= '0;
    prt_table_1_is_frame_fully_rcvd <= '0;
    prt_table_1_valid <= '0;
    read_slot <= '0;
    using_write_slot <= '0;
    write_slot <= 2'd2; 
  end else begin
    if (prt_table_0_bytes_rcvd$EN) prt_table_0_bytes_rcvd <= prt_table_0_bytes_rcvd$D_IN;
    if (prt_table_0_bytes_sent_req$EN) prt_table_0_bytes_sent_req <= prt_table_0_bytes_sent_req$D_IN;
    if (prt_table_0_bytes_sent_res$EN) prt_table_0_bytes_sent_res <= prt_table_0_bytes_sent_res$D_IN;
    if (prt_table_0_is_frame_fully_rcvd$EN) prt_table_0_is_frame_fully_rcvd <= prt_table_0_is_frame_fully_rcvd$D_IN;
    if (prt_table_0_valid$EN) prt_table_0_valid <= prt_table_0_valid$D_IN;
    if (prt_table_1_bytes_rcvd$EN) prt_table_1_bytes_rcvd <= prt_table_1_bytes_rcvd$D_IN;
    if (prt_table_1_bytes_sent_req$EN) prt_table_1_bytes_sent_req <= prt_table_1_bytes_sent_req$D_IN;
    if (prt_table_1_bytes_sent_res$EN) prt_table_1_bytes_sent_res <= prt_table_1_bytes_sent_res$D_IN;
    if (prt_table_1_is_frame_fully_rcvd$EN) prt_table_1_is_frame_fully_rcvd <= prt_table_1_is_frame_fully_rcvd$D_IN;
    if (prt_table_1_valid$EN) prt_table_1_valid <= prt_table_1_valid$D_IN;
    if (read_slot$EN) read_slot <= read_slot$D_IN;
    if (using_write_slot$EN) using_write_slot <= using_write_slot$D_IN;
    if (write_slot$EN) write_slot <= write_slot$D_IN;
  end
end

//initialize register signals

initial begin
  prt_table_0_bytes_rcvd = '0;
  prt_table_0_bytes_sent_req = '0;
  prt_table_0_bytes_sent_res = '0;
  prt_table_0_is_frame_fully_rcvd = '0;
  prt_table_0_valid = '0;
  prt_table_1_bytes_rcvd = '0;
  prt_table_1_bytes_sent_req = '0;
  prt_table_1_bytes_sent_res = '0;
  prt_table_1_is_frame_fully_rcvd = '0;
  prt_table_1_valid = '0;
  read_slot = '0;
  using_write_slot = '0;
  write_slot = 2'd2; 
end

endmodule

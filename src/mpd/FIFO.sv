// ------------------------------------------------------  FIFO BUFFER  ----------------------------------------------

module FIFO #(
  parameter int width = 8,              // Data width of each FIFO entry (default: 8 bits)
  parameter int depth = 16              // Depth of the FIFO (default: 16 entries)
)(
  input  logic                CLK,      // Clock input
  input  logic                RST,      // Active-high reset signal
  input  logic [width-1:0]    D_IN,     // Input data to be enqueued [7:0]
  input  logic                ENQ,      // Enqueue signal (asserted to enqueue data)
  input  logic                DEQ,      // Dequeue signal (asserted to dequeue data)
  input  logic                CLR,      // Clear signal (asserted to reset FIFO)
  output logic                FULL_N,   // Asserted when FIFO is not full
  output logic                EMPTY_N,  // Asserted when FIFO is not empty
  output logic [width-1:0]    D_OUT     // Output data (valid when FIFO is not empty) [7:0]
);
//____________________________________________________________________________________________________________________

  // Local parameter for pointer width: required to address FIFO locations.
  localparam int PTR_WIDTH = $clog2(depth);   // The width of the read/write pointer (log2 of depth)

  // FIFO storage array, write and read pointers, and the count of current elements in FIFO
  logic [width-1:0]             data [0:depth-1];         // FIFO data array of size 'depth', each entry is 'width' bits
  logic [PTR_WIDTH-1:0]         write_ptr, read_ptr;     // Pointers for write and read operations
  logic [$clog2(depth+1)-1:0]   count;              // Counter for tracking the number of items in FIFO

//____________________________________________________________________________________________________________________

  // Reset and initialization block
  always_ff @(posedge CLK or posedge RST) begin
    if (RST || CLR) begin
      // Reset the FIFO state when RST or CLR is asserted
      write_ptr <= 0;           // Reset write pointer
      read_ptr  <= 0;           // Reset read pointer
      count     <= 0;           // Reset item count
    end else begin
      // Handle operations when RST or CLR is not asserted
      if (ENQ && !DEQ && (count < depth)) begin
        // Enqueue operation: 
        // Only happens if FIFO is not full (count < depth) and DEQ is not asserted
        data[write_ptr] <= D_IN;                          // Write input data to the FIFO
        write_ptr <= (write_ptr == depth-1) ? 0 : write_ptr + 1; // Circular increment of write pointer
        count <= count + 1;                                 // Increment item count
      end else if (!ENQ && DEQ && (count > 0)) begin
        // Dequeue operation: 
        // Only happens if FIFO is not empty (count > 0) and ENQ is not asserted
        read_ptr <= (read_ptr == depth-1) ? 0 : read_ptr + 1; // Circular increment of read pointer
        count <= count - 1;                                 // Decrement item count
      end else if (ENQ && DEQ && (count > 0)) begin
        // Simultaneous ENQ and DEQ:
        // When both ENQ and DEQ are asserted at the same time (count > 0)
        // Update both pointers but keep count unchanged.
        data[write_ptr] <= D_IN;                          // Write input data to the FIFO
        write_ptr <= (write_ptr == depth-1) ? 0 : write_ptr + 1; // Circular increment of write pointer
        read_ptr <= (read_ptr == depth-1) ? 0 : read_ptr + 1;   // Circular increment of read pointer
      end
    end
  end

//____________________________________________________________________________________________________________________

  // ----- FIFO STATUS SIGNALS  -----
  assign FULL_N  = (count < depth);       // FIFO is not full if count is less than depth
  assign EMPTY_N = (count > 0);           // FIFO is not empty if count is greater than zero

//____________________________________________________________________________________________________________________

  // -----  OUTPUT DATA LOGIC  -----

  // Valid data is provided only when FIFO is not empty (EMPTY_N is asserted).
  // If FIFO is empty, output zeroes (or it could be x/z depending on design needs).
  assign D_OUT   = (EMPTY_N) ? data[read_ptr] : {width{1'b0}}; // Provide data at read_ptr if not empty, else zero

endmodule

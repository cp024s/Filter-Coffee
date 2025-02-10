module tb_FIFO;

  // Testbench parameters
  parameter int width = 8;   // Data width (8 bits)
  parameter int depth = 16;  // FIFO depth (16 entries)

  // Testbench signals
  logic CLK;                // Clock signal
  logic RST;                // Reset signal
  logic [width-1:0] D_IN;   // Data input for enqueue
  logic ENQ;                // Enqueue signal
  logic DEQ;                // Dequeue signal
  logic CLR;                // Clear signal
  logic FULL_N;             // FIFO full status (active-low)
  logic EMPTY_N;            // FIFO empty status (active-low)
  logic [width-1:0] D_OUT;  // Data output for dequeue

  // Instantiate the FIFO module
  FIFO #(.width(width), .depth(depth)) fifo_inst (.CLK(CLK), .RST(RST), .D_IN(D_IN), .ENQ(ENQ), .DEQ(DEQ), .CLR(CLR), .FULL_N(FULL_N), .EMPTY_N(EMPTY_N), .D_OUT(D_OUT));

  // Clock generation
  always begin
    #5 CLK = ~CLK;  // Toggle clock every 5 time units (100 MHz clock)
  end

  // Test sequence
  initial begin
    // Initialize signals
    CLK = 0;
    RST = 0;
    D_IN = 8'b00000000;  // Initialize input data to 0
    ENQ = 0;
    DEQ = 0;
    CLR = 0;

    // Apply reset to initialize FIFO
    $display("Applying reset...");
    RST = 1;
    #10; // Wait for 10 time units
    RST = 0;
    #10; // Wait for 10 time units

    // Test: Enqueue operation (ENQ = 1)
    $display("Enqueue operation...");
    ENQ = 1;
    D_IN = 8'b10101010; // Data to be enqueued
    #10; // Wait for 10 time units

    // Test: Dequeue operation (DEQ = 1)
    $display("Dequeue operation...");
    ENQ = 0;
    DEQ = 1;
    #10; // Wait for 10 time units

    // Test: Check FIFO empty status
    $display("Checking FIFO empty status...");
    if (EMPTY_N) begin
      $display("FIFO is not empty.");
    end else begin
      $display("FIFO is empty.");
    end

    // Test: Full FIFO condition (Enqueue until full)
    $display("Filling FIFO...");
    for (int i = 0; i < depth; i = i + 1) begin
      ENQ = 1;
      D_IN = i[width-1:0]; // Enqueue increasing data
      #10; // Wait for 10 time units
    end

    // Test: Full condition check
    if (!FULL_N) begin
      $display("FIFO is full.");
    end else begin
      $display("FIFO is not full.");
    end

    // Test: Dequeue from full FIFO
    $display("Dequeuing from full FIFO...");
    for (int i = 0; i < depth; i = i + 1) begin
      ENQ = 0;
      DEQ = 1;
      #10; // Wait for 10 time units
    end

    // Test: FIFO empty check after dequeueing all data
    $display("Checking FIFO empty status after all dequeues...");
    if (EMPTY_N) begin
      $display("FIFO is not empty.");
    end else begin
      $display("FIFO is empty.");
    end

    // Test: Simultaneous Enqueue and Dequeue (ENQ = 1, DEQ = 1)
    $display("Testing simultaneous ENQ and DEQ...");
    ENQ = 1;
    DEQ = 1;
    D_IN = 8'b11110000; // Data for ENQ
    #10; // Wait for 10 time units

    // Test: Clear FIFO (CLR = 1)
    $display("Clearing FIFO...");
    CLR = 1;
    #10; // Wait for 10 time units
    CLR = 0;

    // End of simulation
    $display("Test complete. Ending simulation.");
    $finish;
  end

endmodule

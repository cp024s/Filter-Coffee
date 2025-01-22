`timescale 1ns/1ps

module tb_bloom_filter();

    // Testbench signals
    logic clka;
    logic rst_n;
    logic [71:0] data_in;
    logic start;
    logic done;

    // Instantiate the bloom_filter module
    bloom_filter uut (
        .clka(clka),
        .rst_n(rst_n),
        .data_in(data_in),
        .start(start),
        .done(done)
    );

    // Clock generation
    always begin
        #5 clka = ~clka; // 100 MHz clock
    end

    // Stimulus process
    initial begin
        // Initialize signals
        clka = 0;
        rst_n = 0;
        data_in = 72'b0;
        start = 0;

        // Apply reset
        $display("Applying reset...");
        #10 rst_n = 1;
        #10 rst_n = 0;
        #10 rst_n = 1;

        // Test Case 1: Normal input data (all zeroes)
        $display("Test Case 1: Input data = 72'b0");
        data_in = 72'b0;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 2: Normal input data (all ones)
        $display("Test Case 2: Input data = 72'b1");
        data_in = 72'b1;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 3: Random 72-bit input data
        $display("Test Case 3: Random 72-bit input data");
        data_in = 72'b101010101010101010101010101010101010101010101010101010101010101010101010101010;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 4: Another random 72-bit input data
        $display("Test Case 4: Another random 72-bit input data");
        data_in = 72'b110011001100110011001100110011001100110011001100110011001100110011001100110011;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 5: Sequential 72-bit input data
        $display("Test Case 5: Sequential 72-bit input data");
        data_in = 72'b000000000000000000000000000000000000000000000000000000000000000000000000000000;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 6: Another sequential 72-bit input data
        $display("Test Case 6: Another sequential 72-bit input data");
        data_in = 72'b111111111111111111111111111111111111111111111111111111111111111111111111111111;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 7: All even bits set to 1
        $display("Test Case 7: All even bits set to 1");
        data_in = 72'b101010101010101010101010101010101010101010101010101010101010101010101010101010;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 8: Random input with different bit patterns
        $display("Test Case 8: Random input with different bit patterns");
        data_in = 72'b010101110011101000101101100101011100011110010001101010011010010111000100011110;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 9: Random input, all high order bits set
        $display("Test Case 9: Random input, all high order bits set");
        data_in = 72'b111111111111111111111111111111111111111111111111111111111111111111111111111111;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // Test Case 10: Lower order bits set
        $display("Test Case 10: Lower order bits set");
        data_in = 72'b000000000000000000000000000000000000000000000000111111111111111111111111111111;
        start = 1;
        #10 start = 0;
        wait(done);
        $display("Done signal: %b", done);

        // End simulation after all test cases
        $display("All test cases completed.");
        $finish;
    end

endmodule

module tb_bloom_filter_hashes_11bit;

    // Inputs to the design
    logic [71:0] data_in;  // 72-bit input data

    // Outputs from the design
    logic [10:0] hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6;

    // Instantiate the bloom_filter_hashes_11bit module
    bloom_filter_hashes_11bit uut (
        .data_in(data_in),
        .hash_0(hash_0),
        .hash_1(hash_1),
        .hash_2(hash_2),
        .hash_3(hash_3),
        .hash_4(hash_4),
        .hash_5(hash_5),
        .hash_6(hash_6)
    );

    // Task to print results for each test case
    task print_hashes;
        input [71:0] input_data;
        input [10:0] h0, h1, h2, h3, h4, h5, h6;
        begin
            $display("--------------------------------------------------");
            $display("Input Data: %h", input_data);
            $display("Hash 0: %h | Hash 1: %h | Hash 2: %h", h0, h1, h2);
            $display("Hash 3: %h | Hash 4: %h | Hash 5: %h", h3, h4, h5);
            $display("Hash 6: %h", h6);
            $display("--------------------------------------------------");
        end
    endtask

    // Initial block for test execution
    initial begin
        $display("\nStarting Testbench for 7x 11-bit Bloom Filter Hashes\n");

        // Test case 1: Random pattern
        data_in = 72'h123456789ABCDEF;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 2: Maximum value (all 1s)
        data_in = 72'hFFFFFFFFFFFFFFFF;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 3: Minimum value (all 0s)
        data_in = 72'h000000000000000;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 4: Alternating bits (0xAAAA...)
        data_in = 72'hAAAAAAAAAAAAAAA;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 5: Alternating bits (0x5555...)
        data_in = 72'h555555555555555;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 6: Random hexadecimal value
        data_in = 72'hCAFEBABEDEAD123;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 7: Pattern resembling a "bad" hexadecimal
        data_in = 72'h0BADBEEF0000123;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 8: Pattern resembling "dead" in hex
        data_in = 72'hDEADDEADDEAD123;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 9: Fully random value
        data_in = 72'hBAADF00DBAADF00;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        // Test case 10: Another fully random value
        data_in = 72'hFEEDFACECAFEBEEF;
        #10;
        print_hashes(data_in, hash_0, hash_1, hash_2, hash_3, hash_4, hash_5, hash_6);

        $display("\nTestbench complete.\n");
        $finish;
    end

endmodule

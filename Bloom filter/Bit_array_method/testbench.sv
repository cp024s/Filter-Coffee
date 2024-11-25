`timescale 1ns / 1ps

module tb_Firewall();

    // Testbench Signals
    logic clk;
    logic rst_n;
    logic valid_in;
    logic [71:0] ip_protocol;  // 72-bit IP protocol info (src_ip, dst_ip, protocol)
    logic [15:0] src_port;     // Source port
    logic [15:0] dst_port;     // Destination port
    logic result_out;          // Result of Bloom filter check (pass/fail)
    logic ready_recv;          // Ready signal to receive data
    logic ready_res;           // Ready signal to provide result

    // Instantiate the Firewall Module
    Firewall uut (
        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),
        .ip_protocol(ip_protocol),
        .src_port(src_port),
        .dst_port(dst_port),
        .result_out(result_out),
        .ready_recv(ready_recv),
        .ready_res(ready_res)
    );

    // Clock Generation
    always begin
        #5 clk = ~clk; // Generate a clock with 10 time units period
    end

    // Stimulus Generation
    initial begin
        // Initialize Signals
        clk = 0;
        rst_n = 0;
        valid_in = 0;
        ip_protocol = 72'hC0A8000100010800; // Example IP, source IP, destination IP, and protocol
        src_port = 16'h1234;  // Example source port
        dst_port = 16'h5678;  // Example destination port

        // Reset the design
        #10 rst_n = 1;  // Release reset
        #10 rst_n = 0;  // Apply reset again to stabilize the design
        #10 rst_n = 1;  // Release reset

        // Apply stimulus and test Bloom filter behavior
        run_test_case(72'hC0A8000100010800, 16'h1234, 16'h5678, 1); // Test Case 1
        run_test_case(72'hA0A0000100010800, 16'h4321, 16'h8765, 0); // Test Case 2
        run_test_case(72'hC0A8000200010800, 16'h1ABC, 16'h2DEF, 1); // Test Case 3
        run_test_case(72'hC0A8000100010801, 16'h1000, 16'h1001, 0); // Test Case 4
        run_test_case(72'hC0A8000200020800, 16'h4321, 16'h8765, 1); // Test Case 5
        run_test_case(72'hC0A8000300030800, 16'h4321, 16'h8765, 0); // Test Case 6
        run_test_case(72'hC0A8000400040800, 16'h1234, 16'h5678, 1); // Test Case 7
        run_test_case(72'hF0F0000100010800, 16'h9999, 16'h8888, 0); // Test Case 8
        run_test_case(72'hC0A8000500050800, 16'h4321, 16'h8765, 1); // Test Case 9
        run_test_case(72'hE0E0000100010800, 16'hAAAA, 16'hBBBB, 0); // Test Case 10
        run_test_case(72'hC0A8000100000800, 16'h5678, 16'h8765, 1); // Test Case 11
        run_test_case(72'hF0F0000200020800, 16'hABCD, 16'hDCBA, 0); // Test Case 12
        run_test_case(72'hD0D0000100010800, 16'h1C1C, 16'h2B2B, 1); // Test Case 13
        run_test_case(72'hA0A0000200010800, 16'h4D5E, 16'h3F6E, 0); // Test Case 14
        run_test_case(72'hB0B0000100010800, 16'h1111, 16'h2222, 1); // Test Case 15
        run_test_case(72'hD0D0000200020800, 16'h7777, 16'h8888, 0); // Test Case 16
        run_test_case(72'hC0A8000600060800, 16'h6666, 16'h7777, 1); // Test Case 17
        run_test_case(72'hB0B0000200020800, 16'h9999, 16'hAABB, 0); // Test Case 18
        run_test_case(72'hA0A0000300030800, 16'hCCDD, 16'hEEFF, 1); // Test Case 19
        run_test_case(72'hF0F0000300030800, 16'h4C4C, 16'h5D5D, 0); // Test Case 20

        // End simulation
        #50 $finish;
    end

    // Helper task to run each test case
    task run_test_case(input logic [71:0] ip, input logic [15:0] src, input logic [15:0] dst, input logic expected);
        begin
            ip_protocol = ip;
            src_port = src;
            dst_port = dst;
            
            // Apply stimulus for the test case
            #10 valid_in = 1; // Set valid input
            #10 valid_in = 0; // Reset valid input
            #20; // Wait for processing

            // Check result after processing
            #10 if (result_out == expected)
                    $display("Test Passed: ip_protocol=%h, src_port=%h, dst_port=%h, result_out=%b", ip_protocol, src_port, dst_port, result_out);
                else
                    $display("Test Failed: ip_protocol=%h, src_port=%h, dst_port=%h, result_out=%b", ip_protocol, src_port, dst_port, result_out);
        end
    endtask

    // Displaying simulation results to console
    initial begin
        $monitor("At time %0t, valid_in=%b, ip_protocol=%h, src_port=%h, dst_port=%h, result_out=%b, ready_recv=%b, ready_res=%b",
                 $time, valid_in, ip_protocol, src_port, dst_port, result_out, ready_recv, ready_res);
    end

endmodule

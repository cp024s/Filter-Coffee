`timescale 1ns/1ps

module tb_mkFirewall;

    // Signals for mkFirewall
    logic [71:0] ip_protocol_tb;
    logic [15:0] src_port_tb, dst_port_tb;
    logic readyRecv_tb, readyRes_tb, result_tb;
    logic clk_tb, reset_tb;

    // Instantiate mkFirewall module
    mkFirewall uut (
        .ip_protocol(ip_protocol_tb),
        .src_port(src_port_tb),
        .dst_port(dst_port_tb),
        .readyRecv(readyRecv_tb),
        .readyRes(readyRes_tb),
        .result(result_tb),
        .clk(clk_tb),
        .reset(reset_tb)  // Ensure reset is connected
    );

    // Clock generation
    initial begin
        clk_tb = 1'b0;
        forever #5 clk_tb = ~clk_tb;  // 100 MHz clock
    end

    // Reset logic
    initial begin
        reset_tb = 1'b1;
        #10 reset_tb = 1'b0;  // Release reset after 10ns
    end

    // Test sequence
    initial begin
        // Wait for reset to deassert
        wait (!reset_tb);

        // Test case 1: Provide input data to the firewall
        @(posedge clk_tb);
        ip_protocol_tb = 72'h123456789ABC;
        src_port_tb = 16'h1234;
        dst_port_tb = 16'h5678;

        // Wait for the firewall to process and produce results
        @(posedge clk_tb);
        while (!readyRecv_tb) @(posedge clk_tb);
        
        // Trigger processing
        @(posedge clk_tb);
        while (!readyRes_tb) @(posedge clk_tb);

        // Check result
        if (result_tb) $display("Test Case 1 Passed: Packet allowed");
        else $display("Test Case 1 Failed: Packet blocked");

        // Test case 2: Provide different inputs
        @(posedge clk_tb);
        ip_protocol_tb = 72'hABCDEF012345;
        src_port_tb = 16'h4321;
        dst_port_tb = 16'h8765;

        // Wait for the firewall to process and produce results
        @(posedge clk_tb);
        while (!readyRecv_tb) @(posedge clk_tb);
        
        // Trigger processing
        @(posedge clk_tb);
        while (!readyRes_tb) @(posedge clk_tb);

        // Check result
        if (result_tb) $display("Test Case 2 Passed: Packet allowed");
        else $display("Test Case 2 Failed: Packet blocked");

        // End the simulation
        $finish;
    end

    // Monitor signals for debugging
    initial begin
        $monitor("Time = %0t | ip_protocol = %h | src_port = %h | dst_port = %h | readyRecv = %b | readyRes = %b | result = %b",
                 $time, ip_protocol_tb, src_port_tb, dst_port_tb, readyRecv_tb, readyRes_tb, result_tb);
    end

    // Additional monitoring for the hash computation
    initial begin
        // Monitor the hash module state
        $monitor("Time = %0t | HashState = %b | HashValue = %h",
                 $time, uut.hash_mod.hstate, uut.hash_mod.hashKey);
    end

endmodule

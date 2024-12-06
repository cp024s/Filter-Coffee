`timescale 1ns / 1ps
module murmurhash3_tb;
    reg [31:0] ip_int;
    reg [31:0] seed;
    wire [31:0] hash;

    murmurhash3 uut (
        .ip_int(ip_int),
        .seed(seed),
        .hash(hash)
    );

    initial begin
        // Test cases
        seed = 32'h12345678;

        // Test with IP 192.168.1.1
        ip_int = 32'hC0A80101;  // Equivalent to 192.168.1.1
        #1;
        $display("Hash for 192.168.1.1: %b", hash);  // Display binary hash

        // Test with IP 10.0.0.1
        ip_int = 32'h0A000001;  // Equivalent to 10.0.0.1
        #1;
        $display("Hash for 10.0.0.1: %b", hash);  // Display binary hash

        // Test with IP 172.16.0.1
        ip_int = 32'hAC100001;  // Equivalent to 172.16.0.1
        #1;
        $display("Hash for 172.16.0.1: %b", hash);  // Display binary hash

        // Test with IP 127.0.0.1
        ip_int = 32'h7F000001;  // Equivalent to 127.0.0.1
        #1;
        $display("Hash for 127.0.0.1: %b", hash);  // Display binary hash

        $stop;
    end
endmodule

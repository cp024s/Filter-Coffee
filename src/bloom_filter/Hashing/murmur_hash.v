`timescale 1ns / 1ps
module murmurhash3 (
    input wire [31:0] ip_int,  // 32-bit integer representation of the IP address
    input wire [31:0] seed,    // Seed value
    output reg [31:0] hash     // Output hash value
);
    // MurmurHash3 constants
    parameter C1 = 32'hcc9e2d51;
    parameter C2 = 32'h1b873593;

    reg [31:0] k;
    reg [31:0] h;
    reg [31:0] temp;

    // Function for left rotate
    function [31:0] rotl32(input [31:0] x, input [4:0] r);
        rotl32 = (x << r) | (x >> (32 - r));
    endfunction

    always @(*) begin
        // Key manipulation
        k = ip_int * C1;
        k = rotl32(k, 15);
        k = k * C2;

        // Initialize hash with seed
        h = seed ^ k;

        // Mixing
        h = rotl32(h, 13);
        h = h * 5 + 32'hb1e6c9e8;

        // Finalization
        h = h ^ 4;  // Length of the input, 4 bytes
        temp = h ^ (h >> 16);
        temp = temp * 32'h85ebca6b;
        temp = temp ^ (temp >> 13);
        temp = temp * 32'hc2b2ae35;
        hash = temp ^ (temp >> 16);
    end
endmodule

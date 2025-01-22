module BloomFilter (
    input wire clka,
    input wire ena,
    input wire wea,               // Write enable for BRAM
    input wire [3:0] hash1,       // Hash function 1 output
    input wire [3:0] hash2,       // Hash function 2 output
    input wire [15:0] dina,       // Data to write (single bit in appropriate position)
    output reg [15:0] douta       // Output data
);
    // Parameters
    parameter NUM_HASHES = 2;     // Number of hash functions
    parameter NUM_BRAM_BLOCKS = 16;  // Number of BRAM blocks (adjustable)

    // Internal signals
    wire [15:0] bram_data_out;    // Data output from BRAM
    reg [15:0] data_to_write;     // Data to write back to BRAM
    reg [3:0] current_address;    // Address for current hash
    integer i;

    // Instantiate BRAM blocks
    genvar idx;
    generate
        for (idx = 0; idx < NUM_BRAM_BLOCKS; idx = idx + 1) begin : BRAM_BLOCKS
            BRAM BRAM_inst (
                .clka(clka),
                .ena(ena),
                .wea(wea),
                .addra(current_address),  // Connect to the current address
                .dina(data_to_write),     // Connect to the write data
                .douta(bram_data_out)     // Connect to the BRAM data out
            );
        end
    endgenerate

    // Bloom filter write logic
    always @(posedge clka) begin
        if (wea) begin
            // For each hash, compute the corresponding BRAM address
            for (i = 0; i < NUM_HASHES; i = i + 1) begin
                case (i)
                    0: current_address <= hash1;  // First hash maps to BRAM address
                    1: current_address <= hash2;  // Second hash maps to BRAM address
                endcase

                // Read the current BRAM data
                douta <= bram_data_out;

                // Set the bit corresponding to the hash index
                data_to_write = bram_data_out | dina;  // OR operation to set bit

                // Write back the updated data to BRAM
                wea <= 1;  // Enable write
            end
        end
    end

    // Bloom filter query logic
    assign douta = bram_data_out;  // Output the BRAM data directly
endmodule

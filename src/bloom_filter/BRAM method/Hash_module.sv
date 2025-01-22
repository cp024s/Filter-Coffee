module bloom_filter_hashes_11bit (
    input  logic [71:0] data_in,   // 72-bit input to be hashed
    output logic [10:0] hash_0,    // First 11-bit hash output
    output logic [10:0] hash_1,    // Second 11-bit hash output
    output logic [10:0] hash_2,    // Third 11-bit hash output
    output logic [10:0] hash_3,    // Fourth 11-bit hash output
    output logic [10:0] hash_4,    // Fifth 11-bit hash output
    output logic [10:0] hash_5,    // Sixth 11-bit hash output
    output logic [10:0] hash_6     // Seventh 11-bit hash output
);

    // Jenkins hash function (16-bit output)
    function automatic logic [15:0] jenkins_hash (
        input logic [71:0] data_in,
        input logic [31:0] seed  // Seed allows for unique hash functions
    );
        logic [31:0] hash;
        int i;
        logic [7:0] byte_;

        hash = seed; // Initialize the hash with the seed

        // Process 72-bit input, treating each 8-bit chunk as a byte
        for (i = 0; i < 9; i++) begin
            byte_ = data_in >> (i * 8); // Extract each byte from 72-bit input
            hash = hash + byte_;
            hash = hash + (hash << 10);
            hash = hash ^ (hash >> 6);
        end

        // Final mixing steps for better diffusion
        hash = hash + (hash << 3);
        hash = hash ^ (hash >> 11);
        hash = hash + (hash << 15);

        return hash[15:0]; // Return 16-bit hash
    endfunction

    // Generate 11-bit hashes using the 16-bit Jenkins hash and mask to 11 bits
    assign hash_0 = jenkins_hash(data_in, 32'hdeadbeef) & 11'b111_1111_1111; // Seed 1
    assign hash_1 = jenkins_hash(data_in, 32'hcafebabe) & 11'b111_1111_1111; // Seed 2
    assign hash_2 = jenkins_hash(data_in, 32'h12345678) & 11'b111_1111_1111; // Seed 3
    assign hash_3 = jenkins_hash(data_in, 32'habcdef01) & 11'b111_1111_1111; // Seed 4
    assign hash_4 = jenkins_hash(data_in, 32'h0badc0de) & 11'b111_1111_1111; // Seed 5
    assign hash_5 = jenkins_hash(data_in, 32'hfeedface) & 11'b111_1111_1111; // Seed 6
    assign hash_6 = jenkins_hash(data_in, 32'hba5eba11) & 11'b111_1111_1111; // Seed 7

endmodule

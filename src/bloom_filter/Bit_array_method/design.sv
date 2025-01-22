module bloom_filter #(parameter FILTER_SIZE = 1024, parameter HASH_SIZE = 10) (
    input logic clk, 
    input logic rstn, 
    input logic insert_valid, 
    input logic [31:0] insert_data, 
    input logic query_valid, 
    input logic [31:0] query_data, 
    output logic query_result
);
    // Bloom filter array (bit array)
    logic [FILTER_SIZE-1:0] bloom_filter;

    // Simple hash function (e.g., modulus operation)
    function logic [HASH_SIZE-1:0] hash_function(input logic [31:0] data);
        return data[HASH_SIZE-1:0]; // Taking lower HASH_SIZE bits for simplicity
    endfunction

    // Insert data into the Bloom filter
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bloom_filter <= '0;  // Clear the Bloom filter on reset
        end
        else if (insert_valid) begin
            logic [HASH_SIZE-1:0] hash_value = hash_function(insert_data);
            bloom_filter[hash_value] <= 1;  // Set the corresponding bit to 1 (non-blocking assignment)
        end
    end

    // Query the Bloom filter
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            query_result <= 0;  // Reset query result
        end
        else if (query_valid) begin
            logic [HASH_SIZE-1:0] query_hash = hash_function(query_data);
            query_result <= bloom_filter[query_hash];  // Return 1 if the bit is set (hit), 0 if not (miss)
        end
    end
endmodule

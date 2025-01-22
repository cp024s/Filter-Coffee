module tb_bloom_filter;

    // Test signals
    logic clk;
    logic rstn;
    logic insert_valid;
    logic [31:0] insert_data;
    logic query_valid;
    logic [31:0] query_data;
    logic query_result;

    // Instantiate the Bloom filter module
    bloom_filter dut (
        .clk(clk), 
        .rstn(rstn), 
        .insert_valid(insert_valid), 
        .insert_data(insert_data), 
        .query_valid(query_valid), 
        .query_data(query_data), 
        .query_result(query_result)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;  // 10ns period clock (100 MHz)
    end

    // Stimulus process
    initial begin
        // Initialize signals
        clk = 0;
        rstn = 0;
        insert_valid = 0;
        query_valid = 0;
        insert_data = 0;
        query_data = 0;
        #10 rstn = 1;  // Release reset

        // Test Case 1: Insert first data
        #10;
        insert_valid = 1;
        insert_data = 32'hc0a9011e;  // Example IP address part
        #10;
        insert_valid = 0;

        // Test Case 2: Query the inserted data (Should be a hit)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9011e;  // Same IP address part as inserted
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 2: Query: %h, Result: %b", query_data, query_result); // Expected Result: 1 (Hit)

        // Test Case 3: Query for non-inserted data (Should be a miss)
        #10;
        query_valid = 1;
        query_data = 32'hc0a90128;  // Different IP address part
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 3: Query: %h, Result: %b", query_data, query_result); // Expected Result: 0 (Miss)

        // Test Case 4: Insert a second data
        #10;
        insert_valid = 1;
        insert_data = 32'hc0a8011e;  // Another IP address
        #10;
        insert_valid = 0;

        // Test Case 5: Query for the second inserted data (Should be a hit)
        #10;
        query_valid = 1;
        query_data = 32'hc0a8011e;  // Same IP address part as inserted
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 5: Query: %h, Result: %b", query_data, query_result); // Expected Result: 1 (Hit)

        // Test Case 6: Query for data that was not inserted (Should be a miss)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9021e;  // Another different IP address
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 6: Query: %h, Result: %b", query_data, query_result); // Expected Result: 0 (Miss)

        // Test Case 7: Insert a third data
        #10;
        insert_valid = 1;
        insert_data = 32'hc0a9031e;  // Another IP address
        #10;
        insert_valid = 0;

        // Test Case 8: Query for the third inserted data (Should be a hit)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9031e;  // Same IP address part as inserted
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 8: Query: %h, Result: %b", query_data, query_result); // Expected Result: 1 (Hit)

        // Test Case 9: Query for data that is not inserted, different address (Should be a miss)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9041e;  // Different IP address
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 9: Query: %h, Result: %b", query_data, query_result); // Expected Result: 0 (Miss)

        // Test Case 10: Insert data that overlaps with earlier data (Same hash value, but might be a miss due to Bloom filter nature)
        #10;
        insert_valid = 1;
        insert_data = 32'hc0a9051e;  // Similar IP address to test hash collision
        #10;
        insert_valid = 0;

        // Test Case 11: Query for a possibly collided value (Should be a miss or hit depending on Bloom filter)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9051e;  // Same IP address part, may match due to hash collision
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 11: Query: %h, Result: %b", query_data, query_result); // Expected Result: 1 or 0 depending on hash collision

        // Test Case 12: Query the first inserted data again (Should be a hit)
        #10;
        query_valid = 1;
        query_data = 32'hc0a9011e;  // Same as first inserted
        #10;
        query_valid = 0;
        #10;
        $display("Test Case 12: Query: %h, Result: %b", query_data, query_result); // Expected Result: 1 (Hit)

        $finish;
    end
endmodule

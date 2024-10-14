module bloom_filter #(
    parameter int m = 1024,  // Size of the bit array
    parameter int k = 3      // Number of hash functions
)(
    input  logic         clk,
    input  logic         rst,
    input  logic         insert,     // Signal to insert a new element
    input  logic         query,      // Signal to query an element
    input  logic [31:0]  data_in,    // Input data for insertion/query
    output logic         match,      // Output: 1 if the data might be in the set, 0 otherwise
    output logic         busy        // Output: 1 if the module is busy processing
);

    // Internal states
    typedef enum logic [1:0] {
        IDLE,
        INSERT,
        QUERY,
        CHECK
    } state_t;

    state_t current_state, next_state;

    // Bit array for the Bloom filter
    logic [m-1:0] bit_array;
    
    // Hash function results
    logic [9:0] hash_indices[k-1:0]; // Using 10-bit indices (log2(m) = 10 for m=1024)
    
    // Hash function busy signals
    logic hash_busy;
    logic hash_done;
    
    // Loop index for setting/checking multiple hash positions
    int i;

    // Sequential logic to manage state transitions
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Combinational logic to determine next state
    always_comb begin
        next_state = current_state;
        case (current_state)
            IDLE: begin
                if (insert) begin
                    next_state = INSERT;
                end else if (query) begin
                    next_state = QUERY;
                end
            end
            INSERT: begin
                if (hash_done) begin
                    next_state = IDLE;
                end
            end
            QUERY: begin
                if (hash_done) begin
                    next_state = CHECK;
                end
            end
            CHECK: begin
                next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // Busy signal
    assign busy = (current_state != IDLE);

    // Hash function: parallel hashing using a simple modulo approach for demonstration
    generate
        genvar j;
        for (j = 0; j < k; j++) begin : HASH_FUNCTIONS
            assign hash_indices[j] = (data_in + j*32'h5bd1e995) % m; // Simple hash function for demonstration
        end
    endgenerate

    // Bit array management
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_array <= '0;
            match <= 0;
        end else begin
            case (current_state)
                INSERT: begin
                    if (hash_done) begin
                        // Set bits in the array corresponding to hash indices
                        for (i = 0; i < k; i++) begin
                            bit_array[hash_indices[i]] <= 1'b1;
                        end
                    end
                end
                QUERY: begin
                    if (hash_done) begin
                        match <= 1'b1;
                        // Check if all positions are set to 1
                        for (i = 0; i < k; i++) begin
                            if (bit_array[hash_indices[i]] == 0) begin
                                match <= 1'b0;
                            end
                        end
                    end
                end
                default: match <= 1'b0;
            endcase
        end
    end

    // Hashing control logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_busy <= 0;
            hash_done <= 0;
        end else begin
            case (current_state)
                INSERT, QUERY: begin
                    hash_busy <= 1;
                    hash_done <= 1;
                end
                default: begin
                    hash_busy <= 0;
                    hash_done <= 0;
                end
            endcase
        end
    end

endmodule

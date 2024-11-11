// THIS CODE IS COMPLETELY WRITTEN USING THE ARCHITECTURE DIAGRAM and NO BAV REFERENCE

module BloomFilter (
    input  logic               clk,           // Clock signal
    input  logic               rst,           // Reset signal
    input  logic [71:0]        ip_protocol,   // Concatenated IP and protocol fields for hashing
    input  logic               add_entry,     // Signal to add new entry
    input  logic               check_entry,   // Signal to check if entry exists
    output logic               result         // Output result (1 if entry likely exists, 0 otherwise)
);

    // Bloom Filter Parameters
    localparam int HASH_COUNT = 3;          // Number of hash functions (can be increased)
    localparam int ADDR_WIDTH = 8;          // Address width for BRAM (updated to 8 bits)
    localparam int DATA_WIDTH = 16;         // Data width for BRAM

    // BRAM Interface Signals
    logic                ena, wea;
    logic [ADDR_WIDTH-1:0] addra;           // Updated to match BRAM port width
    logic [DATA_WIDTH-1:0] dina, douta;

    // Internal Signals
    logic [31:0] hash_values [HASH_COUNT];   // Array to store hash outputs
    logic        hash_ready;                 // Indicates hash values are ready
    logic [HASH_COUNT-1:0] check_bits;       // Results for each hash check
    logic [HASH_COUNT-1:0] bram_data_read;   // Data read from BRAM for each hash address

    // Hashing State Machine
    typedef enum logic [1:0] {HASH_IDLE, HASH_COMPUTE, HASH_READY} hash_state_t;
    hash_state_t hash_state, next_hash_state;

    // Bloom Filter State Machine
    typedef enum logic [1:0] {BF_IDLE, BF_READ, BF_WRITE, BF_DONE} bf_state_t;
    bf_state_t bf_state, next_bf_state;

    // Instantiate BRAM
    BRAM_inst BRAM (
        .clka(clk),
        .ena(ena),
        .wea(wea),
        .addra(addra),
        .dina(dina),
        .douta(douta)
    );

    // Jenkins Hash Function
    function automatic logic [31:0] jenkins_hash(input logic [71:0] key, input logic [7:0] seed);
        logic [31:0] hash;
        hash = {seed, key[71:48]} + key[47:24];
        hash = hash + (hash << 10);
        hash ^= (hash >> 6);
        hash = hash + (key[23:0] ^ (hash << 3));
        hash ^= (hash >> 11);
        hash = hash + (hash << 15);
        return hash;
    endfunction

    // Generate multiple hash addresses using Jenkins Hash with different seeds
    always_comb begin
        hash_values[0] = jenkins_hash(ip_protocol, 8'hA5);
        hash_values[1] = jenkins_hash(ip_protocol, 8'h5A);
        hash_values[2] = jenkins_hash(ip_protocol, 8'h6F);
    end

    // Hash FSM Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            hash_state <= HASH_IDLE;
            hash_ready <= 0;
        end else begin
            hash_state <= next_hash_state;
            if (next_hash_state == HASH_READY) begin
                hash_ready <= 1;
            end else begin
                hash_ready <= 0;
            end
        end
    end

    always_comb begin
        next_hash_state = hash_state;
        case (hash_state)
            HASH_IDLE: begin
                if (add_entry || check_entry) begin
                    next_hash_state = HASH_COMPUTE;
                end
            end
            HASH_COMPUTE: begin
                next_hash_state = HASH_READY;
            end
            HASH_READY: begin
                next_hash_state = HASH_IDLE;
            end
        endcase
    end

    // Bloom Filter FSM Logic
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            bf_state <= BF_IDLE;
            result <= 0;
        end else begin
            bf_state <= next_bf_state;
            if (next_bf_state == BF_READ) begin
                result <= &check_bits; // Entry exists if all bits are 1
            end
        end
    end

    always_comb begin
        next_bf_state = bf_state;
        ena = 1'b0;
        wea = 1'b0;
        addra = 0;
        dina = 0;

        case (bf_state)
            BF_IDLE: begin
                if (hash_ready) begin
                    next_bf_state = add_entry ? BF_WRITE : BF_READ;
                end
            end
            BF_READ: begin
                // Check bits from Bloom filter for existence
                for (int i = 0; i < HASH_COUNT; i++) begin
                    addra = hash_values[i][ADDR_WIDTH-1:0];
                    ena = 1'b1;
                    check_bits[i] = douta[0];  // Assume first bit is indicator
                end
                next_bf_state = BF_DONE;
            end
            BF_WRITE: begin
                // Set bits in the Bloom filter to add entry
                for (int i = 0; i < HASH_COUNT; i++) begin
                    addra = hash_values[i][ADDR_WIDTH-1:0];
                    ena = 1'b1;
                    dina = 16'hFFFF;  // Set bits to indicate presence
                    wea = 1'b1;
                end
                next_bf_state = BF_DONE;
            end
            BF_DONE: begin
                next_bf_state = BF_IDLE;
            end
        endcase
    end
endmodule

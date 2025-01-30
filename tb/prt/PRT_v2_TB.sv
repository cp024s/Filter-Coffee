module tb_PacketReferenceTable;

    // Testbench parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 11;
    parameter NUM_ENTRIES = 10;
    parameter FRAME_SIZE = 1518;


// these are the inputs and outputs for the PacketReferenceTable module

    // Inputs
    logic clk;
    logic rst;
    logic frame_in_valid;
    logic [DATA_WIDTH-1:0] frame_data_in;
    logic start_receive;
    logic stop_receive;
    logic start_transmit;

    // Outputs
    logic frame_out_valid;
    logic [DATA_WIDTH-1:0] frame_data_out;
    logic slot_available;

    // Instantiate the PacketReferenceTable module
    PacketReferenceTable #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .NUM_ENTRIES(NUM_ENTRIES),
        .FRAME_SIZE(FRAME_SIZE)
    ) uut (
        .clk(clk),
        .rst(rst),
        .frame_in_valid(frame_in_valid),
        .frame_data_in(frame_data_in),
        .frame_out_valid(frame_out_valid),
        .frame_data_out(frame_data_out),
        .slot_available(slot_available),
        .start_receive(start_receive),
        .stop_receive(stop_receive),
        .start_transmit(start_transmit)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Initialize signals
    initial begin
        // Initialize all signals
        clk = 0;
        rst = 0;
        frame_in_valid = 0;
        frame_data_in = 0;
        start_receive = 0;
        stop_receive = 0;
        start_transmit = 0;

        // Apply reset
        rst = 1;
        #10 rst = 0;
        
        // Test 1: Start receiving a frame
        $display("Test 1: Start receiving a frame");
        start_receive = 1;
        #10 start_receive = 0;

        // Simulate receiving data for the first frame
        frame_in_valid = 1;
        frame_data_in = 8'hAA;
        #10 frame_data_in = 8'hBB;
        #10 frame_data_in = 8'hCC;
        #10 frame_data_in = 8'hDD;
        #10 frame_data_in = 8'hEE;

        // Stop receiving frame
        stop_receive = 1;
        #10 stop_receive = 0;

        // Test 2: Check if slot is available
        $display("Test 2: Check if slot is available");
        if (slot_available == 0) begin
            $display("Slot not available after receiving the frame");
        end else begin
            $display("Slot available after frame reception");
        end

        // Test 3: Start transmitting a frame
        $display("Test 3: Start transmitting the frame");
        start_transmit = 1;
        #10 start_transmit = 0;

        // Check transmitted data
        if (frame_out_valid) begin
            $display("Transmitted data: %h", frame_data_out);
        end

        // Wait for transmission completion
        #20;
        
        // Test 4: Reset entries
        $display("Test 4: Reset entries");
        rst = 1;
        #10 rst = 0;

        // Simulate second frame reception and transmission
        $display("Test 5: Receive and transmit second frame");
        start_receive = 1;
        #10 start_receive = 0;
        
        frame_in_valid = 1;
        frame_data_in = 8'hFF;
        #10 frame_data_in = 8'h11;
        #10 frame_data_in = 8'h22;
        #10 frame_data_in = 8'h33;
        #10 frame_data_in = 8'h44;

        stop_receive = 1;
        #10 stop_receive = 0;

        // Test transmitting second frame
        start_transmit = 1;
        #10 start_transmit = 0;

        if (frame_out_valid) begin
            $display("Transmitted second frame data: %h", frame_data_out);
        end

        // End simulation after all tests
        $stop;
    end

endmodule

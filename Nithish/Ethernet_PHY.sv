
// Ethernet_IP_PHY.sv


// Define the PHY RX interface
interface PhyRXIfc;
    // Define the signals within the interface scope
    logic [3:0] eth_mii_rxd;  // 4-bit RX data nibble
    logic eth_mii_rx_dv;      // RX valid signal

    // RX modport to receive nibbles and valid signal
    modport phy_rx_modport(input eth_mii_rxd, input eth_mii_rx_dv);
endinterface

// Define the PHY TX interface
interface PhyTXIfc;
    // Define the signals within the interface scope
    logic [3:0] eth_mii_txd;  // 4-bit TX data nibble
    logic eth_mii_tx_en;      // TX enable signal

    // TX modport to transmit nibbles and valid signal
    modport phy_tx_modport(output eth_mii_txd, output eth_mii_tx_en);
endinterface

    // Struct for valid nibbles
    typedef struct {
        logic valid;
        logic [3:0] data_nibble;  // 4-bit data nibble
    } ValidNibble;

    // Struct for valid bytes (future use)
    typedef struct {
        logic valid;
        logic [7:0] data_byte;    // 8-bit data byte
    } ValidByte;

// Define the EthIPRXPhyIfc Interface
interface EthIPRXPhyIfc;
    PhyRXIfc phy;  // Instance of PhyRXIfc

    // FIFO for holding ValidNibble data
    logic [3:0] data_fifo [10]; // Example FIFO for data
    int fifo_ptr_in = 0;        // Pointer for enqueuing data
    int fifo_ptr_out = 0;       // Pointer for dequeuing data

    // Function to dequeue data from FIFO and return a valid nibble
    function ValidNibble get_data();
        ValidNibble temp; // Temporary storage for the ValidNibble

        // Check if FIFO is not empty before reading
        if (fifo_ptr_out < fifo_ptr_in) begin
            // Retrieve the first element from the FIFO
            temp.data_nibble = data_fifo[fifo_ptr_out]; // Assuming data_fifo is the FIFO array
            temp.valid = 1'b1; // Mark as valid
            fifo_ptr_out++;    // Dequeue: increment read pointer
        end else begin
            // Handle empty FIFO case (returning invalid data)
            temp.data_nibble = 4'b0000; // Invalid nibble
            temp.valid = 1'b0;           // Mark as invalid
        end

        return temp; // Return the ValidNibble
    endfunction
endinterface

// Define the EthIPTXPhyIfc Interface
interface EthIPTXPhyIfc;
    PhyTXIfc phy;  // Instance of PhyTXIfc

    // Declare a FIFO for holding ValidNibble data
    ValidNibble data_fifo [0:9]; // FIFO to hold 10 ValidNibble entries
    int fifo_ptr_in = 0;         // Pointer for enqueuing data
    int fifo_ptr_out = 0;        // Pointer for dequeuing data

    // Task to enqueue data
    task send_data(ValidNibble data); // Specify the input argument type
        // Check if FIFO is not full before writing
        if (fifo_ptr_in < 10) begin // Check if FIFO has space
            data_fifo[fifo_ptr_in] = data; // Enqueue the data into the FIFO
            fifo_ptr_in <= fifo_ptr_in + 1; // Increment write pointer
        end else begin
            $display("FIFO is full, cannot enqueue data!"); // Handle overflow
        end
    endtask
endinterface

// Ethernet_IP_PHY Module Implementation
module Ethernet_IP_Phy (
    input  logic             eth_mac_clock,   // Clock input
    input  logic             eth_mac_rstn,    // Reset input

    // Receiver side inputs
    input  logic [3:0]       eth_mii_rxd,     // 4-bit RX data nibble
    input  logic             eth_mii_rx_dv,   // RX valid signal

    // Transmitter side outputs
    output logic [3:0]       eth_mii_txd,     // 4-bit TX data nibble
    output logic             eth_mii_tx_en     // TX enable signal
);

    // Parameters
    localparam int FIFO_DEPTH = 8;     // FIFO Depth

    // RX FIFO
    ValidNibble rx_data_fifo [FIFO_DEPTH]; // RX FIFO buffer
    logic [2:0] rx_fifo_write_ptr = 0;     // RX FIFO write pointer
    logic [2:0] rx_fifo_read_ptr = 0;      // RX FIFO read pointer

    // TX FIFO
    ValidNibble tx_data_fifo [FIFO_DEPTH]; // TX FIFO buffer
    logic [2:0] tx_fifo_write_ptr = 0;     // TX FIFO write pointer
    logic [2:0] tx_fifo_read_ptr = 0;      // TX FIFO read pointer

    // FIFO full/empty conditions
    logic rx_fifo_full, rx_fifo_empty, tx_fifo_full, tx_fifo_empty;

    assign rx_fifo_full  = (rx_fifo_write_ptr + 1) % FIFO_DEPTH == rx_fifo_read_ptr;
    assign rx_fifo_empty = (rx_fifo_read_ptr == rx_fifo_write_ptr);

    assign tx_fifo_full  = (tx_fifo_write_ptr + 1) % FIFO_DEPTH == tx_fifo_read_ptr;
    assign tx_fifo_empty = (tx_fifo_read_ptr == tx_fifo_write_ptr);

    // RX Side Logic
    // FIFO write logic for RX (stores incoming nibbles and valid signals)
    always_ff @(posedge eth_mac_clock or negedge eth_mac_rstn) begin
        if (!eth_mac_rstn) begin
            rx_fifo_write_ptr <= 0;  // Reset write pointer on reset
        end else if (eth_mii_rx_dv && !rx_fifo_full) begin
            rx_data_fifo[rx_fifo_write_ptr].data_nibble <= eth_mii_rxd; // Store nibble
            rx_data_fifo[rx_fifo_write_ptr].valid <= eth_mii_rx_dv;     // Store valid signal
            rx_fifo_write_ptr <= rx_fifo_write_ptr + 1;                 // Increment write pointer
        end
    end

    // 'get_data' function logic (reads data from RX FIFO)
    function ValidNibble get_data();
        ValidNibble temp;  // Temporary storage for the valid nibble

        if (rx_fifo_read_ptr != rx_fifo_write_ptr) begin
            // Read both the data nibble and the valid flag from the RX FIFO
            temp = rx_data_fifo[rx_fifo_read_ptr];  // Retrieve both data and valid signal from FIFO
            rx_fifo_read_ptr <= rx_fifo_read_ptr + 1;  // Increment read pointer
        end else begin
            // If FIFO is empty, return invalid data
            temp.data_nibble = 4'b0000;
            temp.valid = 1'b0;
        end

        return temp;  // Return the ValidNibble containing the data and valid signal
    endfunction

    // TX Side Logic
    // FIFO write logic for TX (stores outgoing nibbles and valid signals)
    function void send_data(ValidNibble data);
        if (!tx_fifo_full) begin
            tx_data_fifo[tx_fifo_write_ptr] = data; // Store TX nibble and valid flag
            tx_fifo_write_ptr <= tx_fifo_write_ptr + 1; // Increment write pointer
        end
    endfunction

    // FIFO read logic for TX (transmits stored nibbles and valid signals)
    always_ff @(posedge eth_mac_clock or negedge eth_mac_rstn) begin
        if (!eth_mac_rstn) begin
            eth_mii_txd <= 4'b0;     // Reset TX data nibble
            eth_mii_tx_en <= 1'b0;   // Reset TX enable
            tx_fifo_read_ptr <= 0;   // Reset read pointer
        end else if (!tx_fifo_empty) begin
            eth_mii_txd <= tx_data_fifo[tx_fifo_read_ptr].data_nibble;  // Output TX nibble
            eth_mii_tx_en <= tx_data_fifo[tx_fifo_read_ptr].valid;      // Output TX valid signal
            tx_fifo_read_ptr <= tx_fifo_read_ptr + 1;                   // Increment read pointer
        end
    end

    // FIFO initialization
    initial begin
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            rx_data_fifo[i].data_nibble = 4'b0000;
            rx_data_fifo[i].valid = 1'b0;
            tx_data_fifo[i].data_nibble = 4'b0000;
            tx_data_fifo[i].valid = 1'b0;
        end
    end

endmodule

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// Ethernet_IP_PHY_TB.sv


module tb_Ethernet_IP_Phy;

    // Parameters
    localparam int FIFO_DEPTH = 8;

    // Clock and Reset signals
    logic eth_mac_clock;    // Clock signal
    logic eth_mac_rstn;     // Active low reset signal

    // Receiver side signals
    logic [3:0] eth_mii_rxd; // 4-bit RX data nibble
    logic eth_mii_rx_dv;     // RX valid signal

    // Transmitter side signals
    logic [3:0] eth_mii_txd; // 4-bit TX data nibble
    logic eth_mii_tx_en;     // TX enable signal

    // Instantiate the Ethernet_IP_Phy module
    Ethernet_IP_Phy uut (
        .eth_mac_clock(eth_mac_clock),
        .eth_mac_rstn(eth_mac_rstn),
        .eth_mii_rxd(eth_mii_rxd),
        .eth_mii_rx_dv(eth_mii_rx_dv),
        .eth_mii_txd(eth_mii_txd),
        .eth_mii_tx_en(eth_mii_tx_en)
    );

    // Clock generation
    initial begin
        eth_mac_clock = 0;
        forever #5 eth_mac_clock = ~eth_mac_clock; // 10ns clock period
    end

    // Initial block for reset and stimulus generation
    initial begin
        eth_mac_rstn = 0;   // Assert reset
        eth_mii_rxd = 4'b0; // Initialize RX data
        eth_mii_rx_dv = 1'b0; // Initialize RX valid signal

        // Release reset after 20 ns
        #20 eth_mac_rstn = 1; 

        // Stimulus for RX
        // Send some data to the RX FIFO
        send_data(4'b1010, 1'b1); // Send valid nibble
        send_data(4'b1100, 1'b1); // Send valid nibble
        send_data(4'b1111, 1'b1); // Send valid nibble
        send_data(4'b0001, 1'b0); // Send invalid nibble (not valid)

        // Allow time for data to be processed
        #50;

        // Check TX data
        check_tx_data(4'b1010, 1'b1);
        check_tx_data(4'b1100, 1'b1);
        check_tx_data(4'b1111, 1'b1);
        check_tx_data(4'b0000, 1'b0); // Expected invalid nibble
       
        // End simulation after some time
        #100 $finish;
    end

    // Task to send data
    task send_data(input logic [3:0] data, input logic valid);
        begin
            eth_mii_rxd = data;     // Assign the data
            eth_mii_rx_dv = valid;  // Assign the valid signal
            #10;                    // Wait for a clock cycle
            eth_mii_rx_dv = 1'b0;   // Deassert valid signal
            #10;                    // Wait for next clock edge
        end
    endtask

    // Task to check TX data
    task check_tx_data(input logic [3:0] expected_data, input logic expected_valid);
        begin
            #10; // Wait for a clock cycle to capture output
            if (eth_mii_txd !== expected_data) begin
                $error("TX Data mismatch! Expected: %b, Got: %b", expected_data, eth_mii_txd);
            end
            if (eth_mii_tx_en !== expected_valid) begin
                $error("TX Valid mismatch! Expected: %b, Got: %b", expected_valid, eth_mii_tx_en);
            end
        end
    endtask

endmodule





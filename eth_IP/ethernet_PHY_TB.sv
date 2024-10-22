
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

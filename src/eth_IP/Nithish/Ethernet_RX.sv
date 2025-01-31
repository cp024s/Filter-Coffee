
// Ethernet_IP_RX.sv


module Ethernet_IP_RX;

    // Define FrameSize if not defined elsewhere
    //`ifndef FrameSize
    `define FrameSize 1520
   // `endif

    typedef logic [15:0] BRAM_addr_size;
    typedef logic [7:0] BRAM_data_size;
    localparam Integer BRAM_memory_size = `FrameSize;

    // Define the MacRXIfc interface
    // Define the MacRXIfc interface
    interface MacRXIfc;

        logic new_frame_available;
        logic last_data_received;
        logic [7:0] read_data_frame;
        logic [15:0] bytes_sent;

        // Method equivalents as tasks/functions
        function automatic logic m_is_new_frame_available();
            return new_frame_available;
        endfunction

        function automatic logic m_is_last_data_rcvd();
            return last_data_received;
        endfunction

        task m_start_reading_rx_frame();
            // The logic will be implemented within the module
        endtask

        function automatic logic [7:0] m_read_rx_frame();
            return read_data_frame;
        endfunction

        task m_finished_reading_rx_frame();
            // The logic will be implemented within the module
        endtask

        task m_stop_receiving_current_frame();
            // The logic will be implemented within the module
        endtask

        function automatic logic [15:0] m_get_bytes_sent();
            return bytes_sent;
        endfunction

    endinterface

    // Define the RXIfc interface
    interface RXIfc;
        // Instantiate PhyRXIfc and MacRXIfc inside
        PhyRXIfc phy();
        MacRXIfc mac_rx();
    endinterface

    // Define PhyRXState enumeration
    typedef enum logic [0:0] {
        STATE_IDLE,
        STATE_PAYLOAD
    } PhyRXState;

    // Define DEBUG if needed
    // `define DEBUG 1

    // Define the main module
    module mkEthIPRX (
        input  logic eth_mii_rx_clk,
        input  logic eth_mii_rstn,
        RXIfc rx_ifc // Assuming RXIfc is connected externally
    );
        // Clock and Reset signals
        // In SV, use always_ff with posedge or negedge as required

        // Instantiate the PHY RX Interface Module
        EthIPRXPhyIfc phy_rx (
            .clk(eth_mii_rx_clk),
            .rstn(eth_mii_rstn),
            .core_clk(), // Connect appropriately
            .phy(rx_ifc.phy)
        );

        // Internal Registers
        logic is_msb_nibble;
        logic [3:0] prev_nibble;
        PhyRXState phy_rx_state;

        // Initialize registers
        initial begin
            is_msb_nibble = 0;
            prev_nibble = 4'bx;
            phy_rx_state = STATE_IDLE;
        end

        // Instantiate FIFO
        FIFOF #(.WIDTH(ValidByte_WIDTH)) data_fifo (
            .clk(eth_mii_rx_clk),
            .rstn(eth_mii_rstn),
            .enq(data_fifo_enq),
            .deq(data_fifo_deq),
            .full(),
            .empty()
        );

        // Instantiate BRAM
        BRAM_DUAL_PORT #(
            .ADDR_WIDTH(16), // Adjust based on BRAM_addr_size
            .DATA_WIDTH(8)   // Adjust based on BRAM_data_size
        ) frame (
            .clk_a(eth_mii_rx_clk),
            .clk_b(eth_mii_rx_clk),
            .rstn(eth_mii_rstn),
            .we_a(frame_a_we),
            .addr_a(frame_a_addr),
            .data_in_a(frame_a_data_in),
            .we_b(frame_b_we),
            .addr_b(frame_b_addr),
            .data_out_b(frame_b_data_out)
        );

        // Other Registers
        logic buffer_in_use;
        logic is_current_frame_getting_stored;
        logic is_frame_fully_rcvd;
        logic [15:0] bytes_rcvd_from_phy;
        logic [15:0] bytes_sent_req_rcvd;
        logic [15:0] bytes_sent_data_sent;
        logic prev_valid;
        logic stop_rx;

        // Initialize other registers
        initial begin
            buffer_in_use = 0;
            is_current_frame_getting_stored = 0;
            is_frame_fully_rcvd = 0;
            bytes_rcvd_from_phy = 16'd0;
            bytes_sent_req_rcvd = 16'd0;
            bytes_sent_data_sent = 16'd0;
            prev_valid = 0;
            stop_rx = 0;
        end

        // Rule r_phy_get_byte translated to always_ff block
        always_ff @(posedge eth_mii_rx_clk or negedge eth_mii_rstn) begin
            if (!eth_mii_rstn) begin
                // Reset logic
                phy_rx_state <= STATE_IDLE;
                is_msb_nibble <= 0;
                prev_nibble <= 4'bx;
            end else begin
                // Get data from PHY
                ValidNibble phy_rx_data = phy_rx.get_data();
                prev_nibble <= phy_rx_data.data_nibble;

                if (!phy_rx_data.valid) begin
                    phy_rx_state <= STATE_IDLE;
                end else if (phy_rx_data.valid && (phy_rx_data.data_nibble == 4'hD) &&
                         (prev_nibble == 4'h5) && (phy_rx_state == STATE_IDLE)) begin
                    phy_rx_state <= STATE_PAYLOAD;
                end

                if (phy_rx_state == STATE_IDLE) begin
                    is_msb_nibble <= 0;
                end else if (phy_rx_state == STATE_PAYLOAD) begin
                    is_msb_nibble <= ~is_msb_nibble;
                end

                // Enqueue data to FIFO
                if (phy_rx_state == STATE_PAYLOAD && is_msb_nibble) begin
                    ValidByte data;
                    data.valid = 1;
                    data.data_byte = {phy_rx_data.data_nibble, prev_nibble};
                    data_fifo_enq = data;
                end else if (phy_rx_state == STATE_IDLE) begin
                    ValidByte data;
                    data.valid = 0;
                    data.data_byte = {phy_rx_data.data_nibble, prev_nibble};
                    data_fifo_enq = data;
                end else begin
                    data_fifo_enq = '0; // No operation
                end
            end
        end

        // Rule r_stop_recv_frame
        always_ff @(posedge eth_mii_rx_clk or negedge eth_mii_rstn) begin
            if (!eth_mii_rstn) begin
                stop_rx <= 0;
                is_frame_fully_rcvd <= 0;
                buffer_in_use <= 0;
                bytes_rcvd_from_phy <= 16'd0;
                bytes_sent_req_rcvd <= 16'd0;
                bytes_sent_data_sent <= 16'd0;
            end else begin
                if (stop_rx && is_frame_fully_rcvd) begin
                    stop_rx <= 0;
                    is_frame_fully_rcvd <= 0;
                    buffer_in_use <= 0;
                    bytes_rcvd_from_phy <= 16'd0;
                    bytes_sent_req_rcvd <= 16'd0;
                    bytes_sent_data_sent <= 16'd0;
                    `ifdef DEBUG
                        $display("%t mkEthIPRX: r_stop_recv_frame executed", $time);
                    `endif
                end
            end
        end

        // Rule r_store_byte
        always_ff @(posedge eth_mii_rx_clk or negedge eth_mii_rstn) begin
            if (!eth_mii_rstn) begin
                // Reset logic for store byte rule
                // Initialize or reset variables if necessary
            end else begin
                if (!is_frame_fully_rcvd) begin
                    ValidByte phy_rx_data = data_fifo_deq;
                    logic curr_valid = phy_rx_data.valid;
                    prev_valid <= phy_rx_data.valid;
                    logic [7:0] curr_data = phy_rx_data.data_byte;

                    if (curr_valid && !prev_valid) begin
                        if (buffer_in_use) begin
                            is_current_frame_getting_stored <= 0;
                            `ifdef DEBUG
                                $display("%t mkEthIPRX: r_phy_get_byte. skipping frame since previous frame is not fully received", $time);
                            `endif
                        end else begin
                            buffer_in_use <= 1;
                            is_current_frame_getting_stored <= 1;
                            frame.a_we <= 1;
                            frame.a_addr <= 16'd0;
                            frame.a_data_in <= curr_data;
                            bytes_rcvd_from_phy <= 16'd1;
                            `ifdef DEBUG
                                $display("%t mkEthIPRX: r_phy_get_byte. started receiving new frame addr %d data %h", 
                                    $time, bytes_rcvd_from_phy, curr_data);
                            `endif
                        end
                    end else if (curr_valid && is_current_frame_getting_stored) begin
                        if (bytes_rcvd_from_phy < `FrameSize) begin
                            bytes_rcvd_from_phy <= bytes_rcvd_from_phy + 16'd1;
                            frame.a_we <= 1;
                            frame.a_addr <= bytes_rcvd_from_phy;
                            frame.a_data_in <= curr_data;
                            `ifdef DEBUG
                                $display("%t mkEthIPRX: r_phy_get_byte: receiving addr %d data %h", 
                                    $time, bytes_rcvd_from_phy, curr_data);
                            `endif
                        end
                    end else if (!curr_valid && prev_valid && is_current_frame_getting_stored) begin
                        is_current_frame_getting_stored <= 0;
                        is_frame_fully_rcvd <= 1;
                        `ifdef DEBUG
                            $display("%t mkEthIPRX: r_phy_get_byte. frame fully received", $time);
                        `endif
                    end else begin
                        // No operation
                        frame.a_we <= 0;
                    end
                end
            end
        end

        // PulseWire equivalent can be implemented using a single-cycle pulse
        logic read_rx_frame_conflict;
        assign read_rx_frame_conflict = 0; // Initialize as 0
        
        // Implement read_rx_frame_conflict_send logic
        logic read_rx_frame_conflict_send_trigger;
        // Logic to set read_rx_frame_conflict_send_trigger when needed
        // This requires more context on how it's used


        // Implement read_rx_frame_conflict as a single-cycle pulse
        always_ff @(posedge eth_mii_rx_clk or negedge eth_mii_rstn) begin
            if (!eth_mii_rstn) begin
                read_rx_frame_conflict <= 0;
            end else begin
                if (read_rx_frame_conflict_send_trigger) begin
                    read_rx_frame_conflict <= 1;
                end else begin
                    read_rx_frame_conflict <= 0;
                end
            end
        end

        // Instantiate MacRXIfc methods
        // Using modports or connecting tasks/functions appropriately
        // Here, using procedural assignments for simplicity

        // MacRXIfc Methods Implementation
        // Implemented as separate always_comb or functions/tasks

        // Example implementation for m_is_new_frame_available
        function logic MacRXIfc_m_is_new_frame_available;
            MacRXIfc_m_is_new_frame_available = (bytes_rcvd_from_phy >= 1) && 
                                                (bytes_sent_req_rcvd == 0) && 
                                                buffer_in_use;
        endfunction

        // Example implementation for m_is_last_data_rcvd
        function logic MacRXIfc_m_is_last_data_rcvd;
            MacRXIfc_m_is_last_data_rcvd = is_frame_fully_rcvd && 
                                           (bytes_sent_data_sent == bytes_rcvd_from_phy) && 
                                           buffer_in_use;
        endfunction

        // Example implementation for m_get_bytes_sent
        function logic [15:0] MacRXIfc_m_get_bytes_sent;
            MacRXIfc_m_get_bytes_sent = bytes_sent_data_sent;
        endfunction

        // Example implementation for m_stop_receiving_current_frame
        task MacRXIfc_m_stop_receiving_current_frame;
            if (!stop_rx) begin
                if (buffer_in_use) begin
                    stop_rx <= 1;
                end
            end
        endtask

        // Example implementation for m_finished_reading_rx_frame
        task MacRXIfc_m_finished_reading_rx_frame;
            if (is_frame_fully_rcvd && !stop_rx) begin
                if (buffer_in_use) begin
                    buffer_in_use <= 0;
                    bytes_rcvd_from_phy <= 16'd0;
                    bytes_sent_req_rcvd <= 16'd0;
                    bytes_sent_data_sent <= 16'd0;
                    is_frame_fully_rcvd <= 0;
                    read_rx_frame_conflict_send_trigger <= 1; // Trigger the pulse
                end
            end
        endtask

        // Example implementation for m_start_reading_rx_frame
        task MacRXIfc_m_start_reading_rx_frame;
            if (buffer_in_use && (bytes_sent_req_rcvd == 0) && 
                (bytes_rcvd_from_phy >= 1) && !stop_rx && !read_rx_frame_conflict) begin
                bytes_sent_req_rcvd <= bytes_sent_req_rcvd + 16'd1;
                frame.b_we <= 0; // Assuming 'put' with False for write enable
                frame.b_addr <= bytes_sent_req_rcvd;
                frame.b_data_in <= 8'bz; // Assuming '?' represents high impedance or no data
            end
        endtask

        // Example implementation for m_read_rx_frame
        function logic [7:0] MacRXIfc_m_read_rx_frame;
            if (buffer_in_use && 
                (bytes_sent_req_rcvd >= 1) && 
                (((bytes_sent_data_sent < bytes_sent_req_rcvd) && 
                  (bytes_sent_req_rcvd < bytes_rcvd_from_phy)) ||
                 ((bytes_sent_data_sent < bytes_sent_req_rcvd) && 
                  (bytes_sent_req_rcvd == bytes_rcvd_from_phy) && 
                  is_frame_fully_rcvd)) &&
                !stop_rx && 
                !read_rx_frame_conflict) begin
                
                if (bytes_sent_req_rcvd < bytes_rcvd_from_phy) begin
                    bytes_sent_req_rcvd <= bytes_sent_req_rcvd + 16'd1;
                    frame.b_we <= 0;
                    frame.b_addr <= bytes_sent_req_rcvd;
                    frame.b_data_in <= 8'bz;
                end
                bytes_sent_data_sent <= bytes_sent_data_sent + 16'd1;
                MacRXIfc_m_read_rx_frame = frame.b_data_out;
            end else begin
                MacRXIfc_m_read_rx_frame = 8'b0; // Default or error value
            end
        endfunction

        // Connect MacRXIfc interface methods
        // This requires additional structure to map these functions/tasks to the interface
        // For simplicity, assuming external connection or using a generate block

        // Example:
        assign rx_ifc.mac_rx.m_is_new_frame_available = MacRXIfc_m_is_new_frame_available;
        assign rx_ifc.mac_rx.m_is_last_data_rcvd = MacRXIfc_m_is_last_data_rcvd;
        assign rx_ifc.mac_rx.m_get_bytes_sent = MacRXIfc_m_get_bytes_sent;

        // Tasks need to be called explicitly; consider using procedural blocks or interface bindings

    endmodule

endmodule



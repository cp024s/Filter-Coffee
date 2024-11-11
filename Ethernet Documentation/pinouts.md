The **AXI 1G/2.5G Ethernet Subsystem v7.2** document outlines the pinouts and interfaces available for configuration and control of Ethernet functions. Here’s an in-depth look at key pinouts based on the document:

### 1. AXI4-Lite Interface (`s_axi`)
This interface is used for the configuration of the Ethernet subsystem:
- **s_axi_awaddr**: Write address
- **s_axi_wdata**: Write data
- **s_axi_bresp**: Write response
- **s_axi_araddr**: Read address
- **s_axi_rdata**: Read data
This interface supports only single-beat read and write transfers, enabling access to subsystem registers for configuration purposes.

### 2. AXI4-Stream Interfaces
The AXI Ethernet subsystem uses multiple AXI4-Stream ports for data transmission and reception:
- **s_axis_txc**: AXI4-Stream Transmit Control, primarily for passing control data.
- **s_axis_txd**: AXI4-Stream Transmit Data, used for actual Ethernet frame data during transmission.
- **m_axis_rxd**: AXI4-Stream Receive Data, provides Ethernet frame data received from the network.
- **m_axis_rxs**: AXI4-Stream Receive Status, provides status information related to received data.
In AVB (Audio Video Bridging) mode, additional ports `s_axis_tx_av` and `m_axis_rx_av` are enabled for transmit and receive data, respectively.

### 3. MDIO (Management Data Input/Output)
The **MDIO interface** is provided for accessing the management registers of an external PHY device. This interface is essential for configurations that require interaction with a physical layer device and is available in MII, GMII, RGMII, and SGMII modes.

### 4. Ethernet PHY Interfaces
The subsystem supports various physical interfaces depending on the selected PHY mode:
- **MII (Media Independent Interface)**: Available in 10/100 Mbps modes.
- **GMII (Gigabit Media Independent Interface)**: Supports 1 Gbps operations.
- **RGMII (Reduced Gigabit Media Independent Interface)**: Also supports 1 Gbps but with fewer pins for reduced routing complexity.
- **SGMII (Serial Gigabit Media Independent Interface)**: Used in configurations that require serialized data transmission.
- **1000BASE-X**: Used for 1 Gbps transmission over fiber or copper through the SFP (Small Form-factor Pluggable) interface.

### 5. Clock Inputs
Different clock inputs are required based on the selected interface mode:
- **gtx_clk**: 125 MHz clock, used for GMII, RGMII, and SGMII modes.
- **mgt_clk_p / mgt_clk_n**: Differential clock inputs for high-speed serial transceivers in SGMII and 1000BASE-X modes.
- **ref_clk**: A stable global clock required for RGMII and GMII modes, with a frequency of 200 MHz on 7 series devices.

### 6. Reset Signals
The subsystem includes multiple reset signals to control various functional domains:
- **s_axi_aresetn**: Resets the AXI4-Lite interface.
- **axi_str_txd_aresetn**: Resets the AXI transmit data stream.
- **axi_str_rxd_aresetn**: Resets the AXI receive data stream.

### 7. Additional Pins
For specific configurations and debugging, the following additional signals are included:
- **phy_rst_n**: Active-low reset signal for the PHY, used to ensure that the PHY is held in reset for initialization.
- **signal_detect**: A signal used with optical modules to detect the presence of a network cable.
- **clk_en**: A clock enable signal used in GMII mode for selective clock gating, primarily when the Include_IO option is disabled.

These pinouts and their associated configurations allow for flexible integration of the AXI Ethernet Subsystem within a range of FPGA designs, supporting various Ethernet standards and PHY interfaces.

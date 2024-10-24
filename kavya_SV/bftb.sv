`timescale 1ns/1ps

module bftb;

logic clk;
logic reset;
logic [71:0] ip_pro ;
logic [15:0] src_port;
logic [15:0] dest_port;
logic readyRestb, readyRecvtb;
logic get_Resulttb ;

bloomfilter dut ( .clk(clk), .reset(reset) , .ip_pro(ip_pro) , .src_port(src_port) , .dest_port(dest_port), .readyRecv(readyRecvtb), .readyRes(readyRestb), .get_Result(get_Resulttb));

initial begin 
        forever begin
		  #5 clk = ~clk;
	end 
end 

initial begin
	$display("SIMULATION FOR BLOOM FILTER STARTS"); 
    clk = 0;
    reset = 0;
    ip_pro = 72'b110000001010100100000001000111101100000010101000000000010001111000011110 ;   //  {8'd192,8'd169,8'd1,8'd30, 8'd192,8'd168,8'd1,8'd30,8'd30} ; //72'b11000000101010010000000100011110;  //192.169.1.30
	src_port = 16'd16538 ;
	dest_port = 16'd37281;
    #5 reset = 1;
    #20 reset = 0;

	if (readyRestb) begin
		$display("hash output bit = %b", get_Resulttb);
	end 

	$display("ip = %d", ip_pro);
	$monitor("time = %t, ipprotocol = %h, recv = %b, res = %b, getresult = %b ", $time, ip_pro, readyRecvtb, readyRestb, get_Resulttb);
	
end 


endmodule 


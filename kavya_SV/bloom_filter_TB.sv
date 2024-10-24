`timescale 1ns/1ps

module bftb;

logic clk;
logic reset;
logic [71:0] ipprotocol ;
logic [15:0] src_porttb;
logic [15:0] dest_porttb;
logic readyRestb, readyRecvtb;
logic get_Resulttb ;

bloomfilter dut ( .clk(clk), .reset(reset) , .ip_pro(ipprotocol) , .src_port(src_porttb) , .dest_port(dest_porttb), .readyRecv(readyRecvtb), .readyRes(readyRestb), .get_Result(get_Resulttb));

initial begin 
    clk = 0;
    reset = 1;
    #15 reset = 0;
    forever begin
		#5 clk = ~clk;
	end 
	
	ipprotocol = {8'd192,8'd169,8'd1,8'd30, 8'd192,8'd168,8'd1,8'd30,8'd30} ; //72'b11000000101010010000000100011110;  //192.169.1.30
	src_porttb = 16'd16538 ;
	dest_porttb = 16'd37281;
	$display("ip = %d", ipprotocol);
end 

initial begin 
	$display("SIMULATION FOR BLOOM FILTER STARTS");
	$monitor("time = %t, ipprotocol = %h, recv = %b, res = %b, getresult = %b ", $time, ipprotocol, readyRecvtb, readyRestb, get_Resulttb);
	
	if(readyRecvtb) begin 
	   ipprotocol = {8'd192,8'd169,8'd1,8'd30, 8'd192,8'd168,8'd1,8'd30,8'd30} ; //72'b11000000101010010000000100011110;  //192.169.1.30
	   src_porttb = 16'd16538 ;
	   dest_porttb = 16'd37281;
	end 
	if (readyRestb) begin
		$display("hash output bit = %b", get_Resulttb);
	end 
end 
endmodule 


`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/05/2024 09:02:43 AM
// Design Name: 
// Module Name: noncpulb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
  typedef bit Tag;  //refer the size of tag 
  typedef bit  Index; //changes to in tag
        


   typedef struct {
	       bit id;
	       Index tag;
	       bit res;
        } Tagged_index;

   typedef struct {
	       logic [7:0]  protocol;
	       logic [31:0] srcip;
	       logic [31:0] dstip;
	       logic [15:0] srcport;
	       logic [15:0] dstport;
        } Header;

    typedef struct {
	       bit id;
	       Index tag;
	       Header header;
        } Fifo_struct;

typedef union tagged { 
        Fifo_struct Valid;
        void Invalid ;
} Vtagg;


module noncpulb(input clk, input reset );
    //one clk is used here and nothing 
    //add ethernet instant 
    //clock problem ??
	logic [71:0] ip_pro;
	logic [15:0] src_port;
	logic [15:0] dest_port;
	logic readyRes;
	logic readyRecv;
	logic get_Result ;
	
    bloomfilter bf (.clk(clk),.reset(reset),.ip_pro(ip_pro),.src_port(src_port),.dest_port(dest_port),.readyRes(readyRes),.readyRecv(readyRecv),.get_Result(get_Result) );
    mpdmk mpd(.clk(clk) , .rst(reset) );
    //read the headers that mpd send and write it to the bf
    Vtagg header_in = tagged Invalid ;
    //take the result from bf and put it in mpd 
    
    //read headers
    always @( posedge clk) begin
        Fifo_struct z;
        if (!isValid(header_in)) begin 
            z <= mpd.get_header;
            ip_pro <= {z.header.srcip, z.header.dstip, z.header.protocol};
            src_port <=  z.header.srcport;
            dest_port <= z.header.dstport;
            header_in <= tagged Valid(z);	
        end 
    end  
    //write tag
    always @( posedge clk) begin
        bit z ; 
        if (isValid(header_in)) begin 
            z <= get_Result;
            if (z == 1) begin 
                $display( "true: fp: send to cpu ");
            end else begin 
                $display("false : surely unsafe discard");
            end  
            mpd.send_result(header_in.Valid.id, header_in.Valid.tag, z);
		    header_in <= tagged Invalid;
        end 
    end 
    //not sure on this function 
    function bit isValid( input Vtagg header_in) ;          
          if ( header_in.Valid.id && header_in.Valid.tag && header_in.Valid.header.protocol  ) begin 
                         return 1;  
          end else begin 
                         return 0;
          end 
    endfunction 
endmodule

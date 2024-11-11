`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/07/2024 02:15:30 PM
// Design Name: 
// Module Name: firewall_wrapper
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
// DONE
//////////////////////////////////////////////////////////////////////////////////
 typedef struct {
        int slot;
        logic res;
    }resultslot;
  /* 
 typedef struct {
        int slot ;
        logic [103 :0] header;
     }FIFO_struct;
*/
module firewall_wrapper(
    input clk,
    input reset, 
    input FIFO_struct headerandtag,
    output resultslot resultout
    );
    //declare
    logic read_en_fw_fifo;
    FIFO_struct read_data_fw_fifo;
    FIFO_struct header_out;
    logic empty_fw;
    logic [71:0] ip_pro;
	logic [15:0] src_port;
	logic [15:0] dest_port;
	logic readyRes;
	logic readyRecv;
	logic get_Result ;
	logic z;
	int slot_store;
    //bloom filter instantiated 
    bloomfilter bf(.clk(clk),.reset(reset),.ip_pro(ip_pro),.readyRes(readyRes),.readyRecv(readyRecv),.get_Result(get_Result));
    //instantiate fifo 
    FIFO fifo_to_fw(.r_en(read_en_fw_fifo),.data_out(read_data_fw_fifo),.empty(empty_fw)); //read by fw
    typedef enum logic [1:0]  {READ, WAITA, WRITE}state_fw;
    state_fw statef;
    //read data 
        always @(posedge clk) begin 
            if(reset)begin 
                resultout.slot <=0;
                resultout.header <= 0;
                statef <= READ;
            end 
            else begin 
                case(statef) 
                    READ: begin
                        read_en_fw_fifo <= 1'b1;
                        if (!empty_fw && readyRecv) begin 
                                header_out <= read_data_fw_fifo;
                                //put into bloomfilter
                                ip_pro <= header_out.header ; //ip pro has different bit length 
                                slot_store <= header_out.slot;
                                statef <= WAITA;
                        end
                    end 
                    WAITA: begin 
                        if (!readyRes) begin 
                            statef <= WAITA;
                        end 
                        else begin 
                            statef <=WRITE;
                        end 
                    end 
                    WRITE: begin 
                        z <= get_Result ;
                        if (z == 1) begin 
                            $display( "true: fp: send to cpu ");
                           //if cpu present use these else connect with axi
                           resultout.slot  <= slot_store;
                           resultout.res  <= z;
                        end 
                        if(z==0) begin 
                            $display("false : surely unsafe discard");
                            resultout.slot  <= slot_store;
                            resultout.res  <= z;
                        end  
                        statef <= READ;
                    end 
                  endcase
            end
        end
        //write for cpu
endmodule

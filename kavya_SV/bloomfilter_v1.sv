
module bloomfilter(
	input logic clk,
	input logic reset,
	input logic [71:0] ip_pro,
	input logic [15:0] src_port,
	input logic [15:0] dest_port,
	output logic readyRes,
	output logic readyRecv,
	output logic get_Result 
	);
	logic [71:0] ip;
	//logic [15:0] src;
	//logic [15:0] dest;
	logic [31:0] ipro1;
	logic [31:0] ipro2;
	logic [7:0] ipro3;
	logic givetohash;
	logic hashisready;
	logic [31:0] myhash;
	logic [2:0] val;
	logic bram_index_val;
	//bram 
	logic bram [0:7]; //1 bit wide size 8 array // count from left to right 
	
	typedef enum logic [1:0] { READY , WAITA, COMPARE_SEND_RESULT} bfstate ;
	bfstate bstate;
	
	hashfilter hasher (.clk(clk), .reset(reset), .pro1(ipro1), .pro2(ipro2), .pro3(ipro3), .readyhashRecv(givetohash), .readyhashRes(hashisready), .hashout(myhash));
	integer i;
	//bram
	initial begin  
	   $readmemb("bloomfilter.mem", bram);
	end 
	//display bram contents 
	initial begin 
		$display("bram data");
		for (i=0; i<8; i=i+1) begin 
			$display("%d:%b", i, bram[i]);
		end 
	end 
			
	always_ff @ (posedge clk) begin 
		if ( reset) begin 
			readyRecv <= 1'b1;
			readyRes <= 1'b0;
			ip <= ip_pro ;
			val<= 3'b0;
			bstate <= READY;
		end 
		else begin 
			case (bstate)
				READY: begin
					if (givetohash) begin 
						ipro1 <= ip[71:40];
						ipro2 <= ip[39:8];
						ipro3 <= ip[7:0]; 
						readyRecv <= 1'b1;
						readyRes <= 1'b0;
						bstate <= WAITA;
					end 
					end		
				WAITA: begin	
					if (hashisready) begin 
						readyRecv <= 1'b0;
						bstate <= COMPARE_SEND_RESULT;
					end 
					else begin
						readyRecv <= 1'b0; 
						bstate <= WAITA;
					end 
					end 	
				COMPARE_SEND_RESULT: begin 
					val <= myhash % 1001000 ; //72 depends on the input size 
					$readmemb("bloomfilter.mem",bram); //how to access bram which now has the contents of the mem file 
					bram_index_val <= bram[val];
					//assume : mem file is already configured, hash value is the index
					if (bram_index_val) begin 
						readyRes <= 1'b1;
						get_Result <= 1'b1; // sends true -> it is present in bf SAFE - FP exist
						bstate <= READY;
					end 
					else begin 
						readyRes <= 1'b1;
						get_Result <= 1'b0; // sends False -> not present in bf UNSAFE - sure unsafe 
						bstate <= READY;
					end 								
		          end
		          endcase
	       end 
	       end
endmodule 

module hashfilter( clk, reset, pro1, pro2, pro3, readyhashRecv, readyhashRes, hashout);
	input logic clk;
	input logic reset;
	input logic [31:0] pro1;
	input logic [31:0] pro2;
	input logic [7:0] pro3;
	output logic readyhashRecv;
	output logic  readyhashRes;
	output logic [31:0] hashout;
	logic [31:0] a0;
	logic [31:0] b0;
	logic [31:0] c0;
	logic [31:0] a1;
	logic [31:0] b1;
	logic [31:0] c1;
	logic [31:0] a2;
	logic [31:0] b2;
	logic [31:0] hashKey;
	
	typedef enum logic [2:0] { READY, C1, C2, C3, C4, C5, C6, HASH_RESULT} hashstate;
	hashstate state ; 
	
	always_ff @ (posedge clk) begin 
		if (reset) begin 
			readyhashRecv <= 1'b1;
			readyhashRes <= 1'b0;
			state <= READY ;
		end
		else begin 
			case (state) 
				READY: begin 
					readyhashRecv <= 1'b1 ;
					readyhashRes <= 1'b0;
					a0 <= 32'hdeadbef8 + pro1;
       	        	b0 <= 32'hdeadbef1 + pro2;
       	       		c0 <= 32'hdeadbef8 + {24'b0, pro3 & 8'hff};
					state <= C1;
					end
				C1:	begin 
					c1  <= (c0 ^ b0) - {b0[17:0], b0[31:18]};
					readyhashRecv <= 1'b0;
					state <= C2;	
					end	
				C2: begin 
					a1 <= (a0 ^ c1) - {c1[20:0], c1[31:21]};
                	state <= C3;
                	end	
				C3: begin 
					b1 <= (b0 ^ a1) - {a1[6:0], a1[31:7]};
                	state <= C4;	
                	end
				C4: begin
					a2 <= (a1 ^ c1) - {c1[27:0], c1[31:28]};
                	state <= C5;
                	end 
				C5: begin 
					b2 <= (b1 ^ a2) - {a2[17:0], a2[31:18]};
                	state <= C6;	
                	end 
				C6: begin
					hashKey <= (c1 ^ b2) - {b2[7:0], b2[31:8]};
					readyhashRes <= 1'b1;
					state <= HASH_RESULT ;
					end 	
				HASH_RESULT:begin 
					hashout <= hashKey ;
					state <= READY; 
					end	
				endcase						
		      end 
	   end 
endmodule 
	 

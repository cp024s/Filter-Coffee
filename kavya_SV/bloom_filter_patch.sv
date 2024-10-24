
module bloomfilter(
    input logic clk, reset,
    input logic [71:0] ip_pro,
    input logic [15:0] src_port,
    input logic [15:0] dest_port,
    output logic readyRes, readyRecv,
    output logic get_Result 
);
    logic [71:0] ip;
    logic [15:0] src;
    logic [15:0] dest;
    logic [31:0] ipro1, ipro2, ipro3;
    logic givetohash, hashisready;
    logic [31:0] myhash;
    logic [2:0] val;
    logic bram_index_val;

    //bram 
    logic bram [7:0]; //1 bit wide size 8 array
    
    typedef enum { READY , WAIT, COMPARE_SEND_RESULT } bfstate ;
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
        for (i = 0; i < 8; i = i + 1) begin 
            $display("%d:%b", i, bram[i]);
        end 
    end 
            
    always @ (posedge clk) begin 
        if (reset) begin 
            readyRecv <= 1'b1;
            readyRes <= 1'b0;
            ip <= ip_pro;
            bstate <= READY;
            givetohash <= 1'b0; // Initialize `givetohash`
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
                        bstate <= WAIT;
                    end 
                end		
                WAIT: begin	
                    if (hashisready) begin 
                        readyRecv <= 1'b0;
                        bstate <= COMPARE_SEND_RESULT;
                    end 
                    else begin
                        readyRecv <= 1'b0; 
                        bstate <= WAIT;
                    end 
                end 	
                COMPARE_SEND_RESULT: begin 
                    val <= myhash % 8; // Use modulus with bram size
                    bram_index_val <= bram[val]; // Access `bram` directly
                    if (bram_index_val) begin 
                        readyRes <= 1'b1;
                        get_Result <= 1'b1; // SAFE (FP exist)
                        bstate <= READY;
                    end 
                    else begin 
                        readyRes <= 1'b1;
                        get_Result <= 1'b0; // UNSAFE
                        bstate <= READY;
                    end 								
                end
            endcase
        end 
    end
endmodule 

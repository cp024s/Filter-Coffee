package Firewall_new;
import BRAM::*;
import StmtFSM::*;

interface Firewall_IFC;
	method Action pass_inps(Bit#(72) ip_protocol, Bit#(16) src_port, Bit#(16) dst_port);
	method ActionValue#(Bool) getResult;
	method Bool readyRecv;
	method Bool readyRes;
endinterface

function BRAMRequest#(Bit#(3), Bit#(1)) makeRequest(Bool write, Bit#(3) addr, Bit#(1) data);
	return BRAMRequest{
	write: write,
	responseOnWrite:False,
	address: addr,
	datain: data
};

endfunction

typedef enum {READY, WAIT, GET_RESULT} BSVWrapperState
deriving (Bits, Eq, FShow);

(*synthesize*)
module mkFirewall (Firewall_IFC);

	BRAM_Configure cfg = defaultValue;
        cfg.allowWriteResponseBypass = False;
        cfg.loadFormat = tagged Hex "bloomfilter.mem";
        BRAM2Port#(Bit#(3), Bit#(1)) dut0 <- mkBRAM2Server(cfg);
        
        
        Hash_IFC hashComputer <- mkHash;
      
	Reg#(BSVWrapperState) state <- mkReg(READY);
	
	Reg#(Bit#(72)) ip_protocol_reg <- mkReg(?);
	Reg#(Bit#(16)) src_port_reg <- mkReg(?);
	Reg#(Bit#(16)) dst_port_reg <- mkReg(?);
	Reg#(Bit#(32)) hash <- mkReg(?);
	Reg#(Bool) res <- mkReg(False);	
        
	rule run_timer if (state == WAIT);
                       (* split *)
                       if(hashComputer.validHash())
                       begin
                         // let z <- hashComputer.getHash();
                         // $display($time, " Hash %b", z);
                          dut0.portA.request.put(makeRequest(False, hashComputer.getHash()[2:0], ?));
                          state <= GET_RESULT;
                          $display($time, " done");
                       end
                       else
                       begin
                           state <= WAIT;
                           
                           $display($time, " waiting");
                       end          
            
	endrule

	method Action pass_inps(Bit#(72) ip_protocol, Bit#(16) src_port, Bit#(16) dst_port) if (state == READY);
		
	        hashComputer.putInputs(ip_protocol[71:40],ip_protocol[39:8],ip_protocol[7:0]);
		state <= WAIT;
	endmethod	


	method ActionValue#(Bool) getResult if (state == GET_RESULT);
	        $display($time, "Inside getResult");
	        let y <- dut0.portA.response.get;
	        $display("dut0read[0] = %b", y);
		state <= READY;
		return y==1;
	endmethod
	
	method Bool readyRecv ;
	if (state == READY)
        	return True;
        else
                return False;
        endmethod

        method Bool readyRes ;
        if (state == GET_RESULT)
                return True;
        else
                return False;
        endmethod
        
endmodule


interface Hash_IFC;
	method Action putInputs(Bit#(32) k0, Bit#(32) k1, Bit#(8) k2);
	method Bit#(32) getHash;
	method Bool validHash();	
endinterface

typedef enum {READY, C1, C2, C3, C4, C5, C6, GET_HASH} HashComputeState
deriving (Bits, Eq, FShow);

module mkHash(Hash_IFC);
        Reg#(HashComputeState) hstate <- mkReg(C1);
        Reg#(Bit#(32)) a0 <- mkReg(?);
        Reg#(Bit#(32)) b0 <- mkReg(?);
        Reg#(Bit#(32)) c0 <- mkReg(?);
        Reg#(Bit#(32)) a1 <- mkReg(?);
        Reg#(Bit#(32)) b1 <- mkReg(?);
        Reg#(Bit#(32)) a2 <- mkReg(?);
        Reg#(Bit#(32)) b2 <- mkReg(?);
        Reg#(Bit#(32)) c1 <- mkReg(?);
        Reg#(Bit#(32)) hashKey <- mkReg(?);
        Wire#(Bool) wr_validInputs <- mkDWire(False);
        Reg#(Bool) valid_hash <- mkReg(False);
        	
	rule rc1 if(hstate == C1);
	$display("C1 state");
	          c1  <= (c0 ^ b0) - {b0[17:0], b0[31:18]};
	          
                  hstate <= C2;	
                  valid_hash <= False;
        
	endrule 
	
	rule c2 if(hstate == C2);
	  $display("C2 state");
  		a1 <= (a0 ^ c1) - {c1[20:0], c1[31:21]};
                hstate <= C3;	
	endrule 	

	rule c3 if(hstate == C3);
	  $display("C3 state");
		b1 <= (b0 ^ a1) - {a1[6:0], a1[31:7]};
                hstate <= C4;	
	endrule 
	
	rule c4 if(hstate == C4);
	  $display("C4 state");
		a2 <= (a1 ^ c1) - {c1[27:0], c1[31:28]};
                hstate <= C5;	
	endrule 

       
	rule c5 if(hstate == C5);
	  $display("C5 state");
		b2 <= (b1 ^ a2) - {a2[17:0], a2[31:18]};
                hstate <= C6;	
	endrule 
	

        
	rule c6 if(hstate == C6);
	  $display("C6 state");
  		hashKey <= (c1 ^ b2) - {b2[7:0], b2[31:8]};	
                valid_hash <= True;
                //hstate <= C1;
	endrule 

       	method Action putInputs(Bit#(32) k0, Bit#(32) k1, Bit#(8) k2);
       	        a0 <= 32'hdeadbef8 + k0;
       	        b0 <= 32'hdeadbef1 + k1;
       	        c0 <= 32'hdeadbef8 + {24'b0, k2 & 8'hff};
                wr_validInputs <= True;
                $display("Inside put inputs");
	endmethod	
	
        method Bool validHash = valid_hash;
        method Bit#(32) getHash = hashKey;
        
endmodule


// (*synthesize*)
module mkTb (Empty);
	
	
	Firewall_IFC dut <- mkFirewall;
	
	Reg#(Bit#(6)) cntr <- mkReg(0);

	// CORRECT RULES: OUTPUT MUST BE 1 FOR THIS. ELSE IDEALLY 0
	// Bit#(72) ip_pro_1 = {8'd192,8'd169,8'd1,8'd30, 8'd192,8'd168,8'd1,8'd30,8'd30}; // ip_pro is src_ip, dst_ip, protocol
	// Bit#(16) port1_1 = 16'd16558;
	// Bit#(16) port2_1 = 16'd37281;
	// Bit#(72) ip_pro_2 = {8'd192,8'd169,8'd1,8'd40, 8'd192,8'd168,8'd1,8'd40,8'd40}; // ip_pro is src_ip, dst_ip, protocol
	// Bit#(16) port1_2 = 16'd29386;
	// Bit#(16) port2_2 = 16'd38849;

	Bit#(72) ip_pro_1 = {8'd192,8'd169,8'd1,8'd30, 8'd192,8'd168,8'd1,8'd30,8'd30}; // ip_pro is src_ip, dst_ip, protocol
	Bit#(16) port1_1 = 16'd16538;
	Bit#(16) port2_1 = 16'd37281;
	Bit#(72) ip_pro_2 = {8'd192,8'd169,8'd1,8'd40, 8'd192,8'd168,8'd1,8'd40,8'd40}; // ip_pro is src_ip, dst_ip, protocol
	Bit#(16) port1_2 = 16'd29386;
	Bit#(16) port2_2 = 16'd38849;

        rule init (cntr == 0);    $dumpvars();  dut.pass_inps(ip_pro_1, port1_1, port2_1);  $display($time, " 1: Sent ip and port");  cntr <= cntr + 1;   endrule

	rule r1(dut.readyRes());
		    let z <- dut.getResult();
		    $display($time, " 1: Received %b", z);
		    $finish;
	endrule

	//rule r2 ;
	//	cntr <= cntr + 1;
	//endrule 

	//rule end_sim if (cntr == 32);
		
	//endrule
	
	
	

endmodule
endpackage : Firewall_new

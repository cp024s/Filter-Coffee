module mpdmk#(parameter FRAME_SIZE = 1500 ,
              parameter DATA_WIDTH = 8,
              parameter HEADER_BIT = 104) (
    input logic clk, 
    input logic reset,
    
    //signals for rx
    input bit free_slot_avail,
    input bit new_frame_avail_eth,
    input logic [DATA_WIDTH:0] rcvd_frame,  //push to prt
    input bit is_frame_fully_read_eth,
    output bit is_it_last_byte_to_prt,
    output logic header_plus_tag, //format
    
    //signals for tx
    input logic result_plus_tag, //format 
    output logic to_send_fifo_slot,
    output logic to_invalidate_fifo_slot,
    input logic get_from_fifo_slot,
    output logic send_inv_slot_to_prt,
    input bit new_frame_rdy_to_send,
    output logic [DATA_WIDTH:0] tx_frame,
    input logic [DATA_WIDTH:0] get_tx_data_prt,
    input bit is_it_last_byte_prt,
    output bit is_frame_fully_sent
);
    //declare dtype
    typedef enum logic [3:0] { READY, WAIT_FOR_NEW_FRAME, GET_NEW_FRAME,GET_HEADER_TAG,  STORE_FW_FIFO} state_rx;
    typedef enum logic [1:0] { GET_SEND_TO_FIFO, WAIT_TO_SEND_NEW_FRAME,TX_DATA_OUT } state_tx;
    typedef enum logic [1:0]{ GET_FROM_INV_FIFO,GET_INV_FIFO, INV_PRT  } state_inv;
    typedef enum logic { GET_FROM_FW, GOTO_NXT_STATE  } state_mpd;
                    
    typedef struct {
        int slot ;
        logic [HEADER_BIT -1 :0] header;
     }FIFO_struct;
     FIFO_struct headerplustag;

    typedef struct {
        int slot;
        logic res;
    }resultslot;
    resultslot resultplustag;
    
    //declaration 
    state_mpd state_inside;
    state_rx rx_st;
    state_tx tx_st;
    state_inv inv_st;
    //prt
    logic [DATA_WIDTH:0] data_rx;
    logic                     frame_in_valid;
    logic [DATA_WIDTH-1:0]    frame_data_in;
    logic                    frame_out_valid;
    logic [DATA_WIDTH-1:0]   frame_data_out;
    logic                    slot_available; 
    logic                     start_receive;  
    logic                     stop_receive;  
    logic                     start_transmit  ;
    int                        slot;   //add this in the prt 
    int slot_tag;
    
    //header contents
    logic [7:0] protocol_v1;
    logic [31:0] srcip_v1;
    logic [31:0] dstip_v1;
    logic [15:0] srcpt_v1;
    logic [15:0] dstpt_v1;
    //fifo
    FIFO_struct write_data_fw_fifo;
    int write_data_send_fifo;
    int write_data_inv_fifo;
    logic write_en_fw_fifo;
    logic write_en_send_fifo;
    logic write_en_inv_fifo;
    logic read_en_fw_fifo;
    logic read_en_send_fifo;
    logic read_en_inv_fifo;
    logic full_fw;
    logic full_send;
    logic full_inv;
    FIFO_struct read_data_fw_fifo;
    int read_data_send_fifo;
    int read_data_inv_fifo;
    logic empty_fw;
    logic empty_send;
    logic empty_inv;
    
    logic is_current_frame_unsafe ; //output of the prt
    
    //instantiations
    prt prt_table(.clk(clk), .rst(reset),.frame_in_valid(frame_in_valid),
                   .frame_data_in(frame_data_in),.frame_out_valid(frame_out_valid), 
                   .frame_data_out(frame_data_out),.slot_available(slot_available),.start_receive(start_receive), .stop_receive(stop_receive),
                    .start_transmit(start_transmit), .slot(slot), .current_frame_unsafe(is_current_frame_unsafe));
            
    FIFO fifo_to_fw(.clk(clock) ,.rst(reset) ,.w_en(write_en_fw_fifo),.data_in(write_data_fw_fifo),.r_en(read_en_fw_fifo),.data_out(read_data_fw_fifo),.full(full_fw),.empty(empty_fw)); //read by fw
    FIFO1 to_send(.clk(clock) ,.rst(reset) ,.w_en(write_en_send_fifo),.data_in(write_data_send_fifo),.r_en(read_en_send_fifo),.data_out(read_data_send_fifo),.full(full_send),.empty(empty_send));
    FIFO1 to_invalidate(.clk(clock) ,.rst(reset) ,.w_en(write_en_inv_fifo),.data_in(write_data_inv_fifo),.r_en(read_en_inv_fifo),.data_out(read_data_inv_fifo),.full(full_inv),.empty(empty_inv)); //read by prt
    
    firewall_wrapper fwtop(.clk(clk) , .reset(reset), .headerandtag (headerplustag), .resultout(resultplustag));
    //design rx
    always@(posedge clk) begin 
            if( reset) begin 
                    is_it_last_byte_to_prt <= 0;
                    is_frame_fully_sent <= 0;
            end else begin 
                    case (rx_st)
                    //receiver cases
                            READY: begin 
                                    if ( free_slot_avail ) begin 
                                            rx_st <= WAIT_FOR_NEW_FRAME;
                                    end 
                            end 
                            WAIT_FOR_NEW_FRAME: begin
                                    if( new_frame_avail_eth) begin 
                                            rx_st <=  GET_NEW_FRAME ;
                                    end else begin 
                                            rx_st <= WAIT_FOR_NEW_FRAME;
                                    end 
                            end 
                            GET_NEW_FRAME :  begin //check logic
                                    if (!is_frame_fully_read_eth) begin
                                        int byte_i; 
                                        for ( int byte_i = 0; byte_i< FRAME_SIZE; byte_i +=1 ) begin  
                                            data_rx <= rcvd_frame;
                                            frame_data_in <= data_rx;  //push data to prt
                                            //HEADER RETRIVEL 
                                            if(byte_i == 23) begin
                                                protocol_v1 <= data_rx;
                                            end
                                            else if (byte_i == 26) begin 
                                                srcip_v1 <= {data_rx, 8'b0, 8'b0, 8'b0}; 
                                            end 
                                            else if (byte_i == 27) begin 
                                                srcip_v1 <= {8'b0, data_rx, 8'b0, 8'b0};
                                            end 
                                            else if (byte_i == 28) begin 
                                                srcip_v1 <= {8'b0, 8'b0,data_rx, 8'b0};
                                            end 
                                            else if (byte_i == 29) begin 
                                                srcip_v1 <= {8'b0, 8'b0, 8'b0, data_rx};
                                            end 
                                            else if (byte_i == 30) begin 
                                                dstip_v1 <= {data_rx, 8'b0, 8'b0, 8'b0};
                                            end 
                                            else if (byte_i == 31) begin 
                                                dstip_v1 <= {8'b0, data_rx, 8'b0, 8'b0};
                                            end
                                            else if (byte_i == 32) begin 
                                                srcip_v1 <= {8'b0, 8'b0,data_rx, 8'b0};
                                            end 
                                            else if (byte_i == 33) begin 
                                                srcip_v1 <= {8'b0, 8'b0,8'b0, data_rx};
                                            end 
                                            else if (byte_i == 34) begin 
                                                srcpt_v1 <= {data_rx, 8'b0};
                                            end 
                                            else if (byte_i == 35) begin 
                                                srcpt_v1 <= {8'b0,data_rx};
                                            end 
                                            else if (byte_i == 36) begin 
                                                dstpt_v1 <= {data_rx, 8'b0};
                                            end 
                                            else if (byte_i == 37) begin 
                                                srcip_v1 <= {8'b0,data_rx};
                                            end 
                                            //HEADER RETRIVEL 
                                            if( byte_i + 1 == FRAME_SIZE) begin //check counter
                                                is_it_last_byte_to_prt <= 1;  //add this to prt code
                                            end                   
                                        end 
                                        rx_st <= GET_HEADER_TAG; //conflict
                                    end
                                    else begin
                                        rx_st <= READY ;
                                    end 
                             end 
                             GET_HEADER_TAG: begin
                                    //prt -> slot tag
                                    if (slot_available) begin 
                                            slot_tag <= slot;
                                            //fifo structure 
                                            headerplustag.slot <= slot_tag ;
                                            headerplustag.header <= {dstpt_v1,srcpt_v1,dstip_v1,srcip_v1,protocol_v1};
                                            //state trans
                                            rx_st <= STORE_FW_FIFO;
                                    end else begin 
                                            rx_st <= GET_HEADER_TAG;
                                    end
                             end
                             STORE_FW_FIFO: begin 
                                    //pass the value into fifo_to_fw
                                    write_en_fw_fifo  <= 1'b1;
                                    if ( !full_fw) begin 
                                        write_data_fw_fifo <= headerplustag;
                                    end   
                                    rx_st <= READY;  
                             end
                           endcase
                      end 
                 end 
           
           //design tx       
           always@ (posedge clk)  begin 
                         // result calculation cases : yet to do 
                         if(reset) begin
                         
                         end else begin
                           case(tx_st)
                            GET_SEND_TO_FIFO: begin 
                                //get the slot from fifo  
                                //go to WAIT FOR SEND NEW FRAME 
                            end 
                            WAIT_TO_SEND_NEW_FRAME:begin 
                                //if new frame is read or tx 
                                //then go to tx data out state 
                                //else stay here
                            end 
                            TX_DATA_OUT: begin
                                //get the byte from the prt to the 
                                //send byte by byte 
                                //if(last byte) => fully-sent == 1
                                //and state wait_to_send_new_frame 
                                //else state = tx_data_out 
                                
                            end                          
                    endcase 
             end
       end
       //design inv
       always @(posedge clk) begin 
            if(reset) begin 
            end 
            else begin 
                case (inv_st) 
                    GET_FROM_INV_FIFO: begin 
                               //get from inv fifo and invalidate the prt entry 
                                if(is_current_frame_unsafe) begin
                                //force stop rx 
                                //go to GET_NEW_FRAME
                                end else begin 
                                    //invalidate prt by slot
                                end 
                    end 
                    GET_INV_FIFO:begin 
                    end 
                    INV_PRT:begin 
                    end
                endcase
            end
      end 
      //design inside mpd
      always @(posedge clk) begin 
            if(reset) begin 
            end
            else begin 
                case (state_inside) 
                      GET_FROM_FW:begin

                            write_en_fw_fifo <= 1'b0;
                                    //result + tag from the fw
                            if (resultplustag.res == 1) begin //true unsafe  
                                       //put in invalidate fifo
                            write_en_inv_fifo <= 1'b1;
                            if (!full_inv) begin
                                write_data_inv_fifo <= resultplustag.slot;   
                            end                                          
                        end 
                        else if (resultplustag.res == 0) begin //safe
                                            // then safe,  send tag/slot to to_send fifo
                                               //then get from the to_send fifo                                                
                        end    
                      end
                      GOTO_NXT_STATE: begin
                      end
                endcase
           end  
       end 

endmodule

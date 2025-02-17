`timescale 1ns / 1ps

// ==========================================================================
//                                 BRAM
// ==========================================================================
module BRAM2 #(
  parameter int PIPELINED = 0,
  parameter int ADDR_WIDTH = 1,
  parameter int DATA_WIDTH = 1,
  parameter int MEMSIZE = 1
)(
  input logic CLKA,
  input logic ENA,
  input logic WEA,
  input logic [ADDR_WIDTH-1:0] ADDRA,
  input logic [DATA_WIDTH-1:0] DIA,
  output logic [DATA_WIDTH-1:0] DOA,

  input logic CLKB,
  input logic ENB,
  input logic WEB,
  input logic [ADDR_WIDTH-1:0] ADDRB,
  input logic [DATA_WIDTH-1:0] DIB,
  output logic [DATA_WIDTH-1:0] DOB
);

  logic [DATA_WIDTH-1:0] RAM [0:MEMSIZE-1]; // Array of logic for memory
  logic [DATA_WIDTH-1:0] DOA_R;
  logic [DATA_WIDTH-1:0] DOB_R;
  logic [DATA_WIDTH-1:0] DOA_R2;
  logic [DATA_WIDTH-1:0] DOB_R2;

  initial begin : init_block
    for (int i = 0; i < MEMSIZE; i = i + 1) begin
      RAM[i] = { ((DATA_WIDTH + 1)/2) {2'b10} }; // Initialize RAM (more common and portable)
    end
    DOA_R = { ((DATA_WIDTH + 1)/2) {2'b10} };
    DOB_R = { ((DATA_WIDTH + 1)/2) {2'b10} };
    DOA_R2 = { ((DATA_WIDTH + 1)/2) {2'b10} };
    DOB_R2 = { ((DATA_WIDTH + 1)/2) {2'b10} };
  end

  always @(posedge CLKA) begin
    if (ENA) begin
      if (WEA) begin
        RAM[ADDRA] <= DIA; // No need for the BSV delay
        DOA_R <= DIA;
      end else begin
        DOA_R <= RAM[ADDRA];
      end
    end
    DOA_R2 <= DOA_R;
  end

  always @(posedge CLKB) begin
    if (ENB) begin
      if (WEB) begin
        RAM[ADDRB] <= DIB;
        DOB_R <= DIB;
      end else begin
        DOB_R <= RAM[ADDRB];
      end
    end
    DOB_R2 <= DOB_R;
  end

  assign DOA = (PIPELINED) ? DOA_R2 : DOA_R;
  assign DOB = (PIPELINED) ? DOB_R2 : DOB_R;

endmodule //BRAM

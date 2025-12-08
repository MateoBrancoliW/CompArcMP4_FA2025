`timescale 1ns/1ps
`define alu_add = 3'b000,
`define alu_sub = 3'b001,
`define alu_and = 3'b010,
`define alu_or = 3'b011,
`define alu_xor = 3'b100,
`define alu_sll = 3'b101,
`define alu_srl = 3'b110,
`define alu_sra = 3'b111
module alu(
  input wire [2:0] alu_operation,
  input int [31:0] alu_a,
  input int [31:0] alu_b,
  output int [31:0] alu_c,
  output int zero,
  output int less_than
  output int signed_less_than
);
  always @(*) begin
    case (alu_operation):
    `alu_add: alu_c = alu_a + alu_b;
    `alu_sub: alu_c = alu_a - alu_b;
    `alu_and: alu_c = alu_a & alu_b;
    `alu_or: alu_c = alu_a | alu_b;
    `alu_xor: alu_c = alu_a ^ alu_b;
    `alu_sll: alu_c = alu_a << alu_b;
    `alu_srl: alu_c = alu_a >> alu_b;
    `alu_sra: alu_c = alu_a >>> alu_b;
    endcase
  end

  assign zero = (alu_c == 32'b0);
  assign signed_less_than = ($signed(alu_a) < $signed(alu_b));
  assign less_than = (alu_a < alu_b);
endmodule: alu
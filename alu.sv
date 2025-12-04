`timescale 1ns/1ps

module alu
  import alu_pkg::*;
(
  input  logic [31:0] a,       // operand A
  input  logic [31:0] b,       // operand B
  input  alu_op_t     alu_op,  // ALU control
  output logic [31:0] y,       // result
  output logic zero,    // y == 0
  output logic lt,      // a < b (signed)
  output logic ltu,     // a < b (unsigned)
  output logic overflow
);

  logic [4:0] shamt;
  assign shamt = b[4:0];
  logic signed [31:0] a_s, b_s;
  assign a_s = a;
  assign b_s = b;
  logic [31:0] sum, diff;
  logic signed [31:0] sum_s, diff_s;

  assign sum    = a + b;
  assign diff   = a - b;
  assign sum_s  = a_s + b_s;
  assign diff_s = a_s - b_s;

  // Comparison flags
  assign lt  = (a_s < b_s);
  assign ltu = (a   < b  );

  // Main ALU
  always_comb begin
    y        = 32'h0000_0000;
    overflow = 1'b0;

    unique case (alu_op)
      ALU_ADD: begin
        y        = sum;
        overflow = (a_s[31] == b_s[31]) && (sum_s[31] != a_s[31]);
      end

      ALU_SUB: begin
        y        = diff;
        overflow = (a_s[31] != b_s[31]) && (diff_s[31] != a_s[31]);
      end

      ALU_AND:   y = a & b;
      ALU_OR:    y = a | b;
      ALU_XOR:   y = a ^ b;

      // Set-less-than
      ALU_SLT:   y = {{31{1'b0}}, lt};   // signed
      ALU_SLTU:  y = {{31{1'b0}}, ltu};  // unsigned

      // Shifts
      ALU_SLL:   y = a << shamt;
      ALU_SRL:   y = a >> shamt;        // logical
      ALU_SRA:   y = a_s >>> shamt;     // arithmetic

      // Pass-throughs
      ALU_COPY_A: y = a;
      ALU_COPY_B: y = b;
    endcase
  end
  
  assign zero = (y == 32'b0);

endmodule : alu

// common/alu_pkg.sv
`timescale 1ns/1ps

package alu_pkg;
  typedef enum logic [3:0] {
    ALU_ADD    = 4'b0000,  // add, addi
    ALU_SUB    = 4'b0001,  // sub
    ALU_AND    = 4'b0010,  // and, andi
    ALU_OR     = 4'b0011,  // or, ori
    ALU_XOR    = 4'b0100,  // xor, xori
    ALU_SLT    = 4'b0101,  // slt, slti (signed)
    ALU_SLTU   = 4'b0110,  // sltu, sltiu (unsigned)
    ALU_SLL    = 4'b0111,  // sll, slli
    ALU_SRL    = 4'b1000,  // srl, srli (logical)
    ALU_SRA    = 4'b1001,  // sra, srai (arithmetic)
    ALU_COPY_A = 4'b1010,  // pass-through A
  } alu_op_t;

endpackage : alu_pkg

`timescale 1ns/1ps

// ALU operation encodings
`define ALU_ADD 4'b0000
`define ALU_SUB 4'b0001
`define ALU_AND 4'b0010
`define ALU_OR  4'b0011
`define ALU_XOR 4'b0100
`define ALU_SLL 4'b1000
`define ALU_SRL 4'b0110
`define ALU_SRA 4'b0111
`define ALU_SLT 4'b0101
`define ALU_SLTU 4'b1001
module alu(
    input  logic [3:0]  alu_operation,
    input  logic [31:0] alu_a,
    input  logic [31:0] alu_b,
    output logic [31:0] alu_c,
    output logic zero,
    output logic less_than,
    output logic signed_less_than
);

    always_comb begin
        alu_c = 32'b0;
        zero = 0;
        case (alu_operation)
            `ALU_ADD: alu_c = alu_a + alu_b;
            `ALU_SUB: alu_c = alu_a - alu_b;
            `ALU_AND: alu_c = alu_a & alu_b;
            `ALU_OR:  alu_c = alu_a | alu_b;
            `ALU_XOR: alu_c = alu_a ^ alu_b;
            `ALU_SLL: alu_c = alu_a <<  alu_b[4:0];
            `ALU_SRL: alu_c = alu_a >>  alu_b[4:0];
            `ALU_SRA: alu_c = alu_a >>> alu_b[4:0];
            `ALU_SLT: begin
                signed_less_than = $signed(alu_a) < $signed(alu_b);
                zero = alu_c[0];
            end
            `ALU_SLTU: begin
                alu_c = $unsigned(alu_a) < $unsigned(alu_b);
                Zero = alu_c[0];
            end
            default: begin
            end
        endcase
    end
endmodule: alu
`timescale 1ns/1ps

// ALU operation encodings
`define ALU_ADD 3'b000
`define ALU_SUB 3'b001
`define ALU_AND 3'b010
`define ALU_OR  3'b011
`define ALU_XOR 3'b100
`define ALU_SLL 3'b101
`define ALU_SRL 3'b110
`define ALU_SRA 3'b111

module alu(
    input  logic [2:0]  alu_operation,
    input  logic [31:0] alu_a,
    input  logic [31:0] alu_b,
    output logic [31:0] alu_c,
    output logic zero,
    output logic less_than,
    output logic signed_less_than
);

    always_comb begin
        alu_c = 32'b0;

        case (alu_operation)
            `ALU_ADD: alu_c = alu_a + alu_b;
            `ALU_SUB: alu_c = alu_a - alu_b;
            `ALU_AND: alu_c = alu_a & alu_b;
            `ALU_OR:  alu_c = alu_a | alu_b;
            `ALU_XOR: alu_c = alu_a ^ alu_b;
            `ALU_SLL: alu_c = alu_a <<  alu_b[4:0];
            `ALU_SRL: alu_c = alu_a >>  alu_b[4:0];
            `ALU_SRA: alu_c = alu_a >>> alu_b[4:0];
            default:  alu_c = 32'b0;
        endcase
    end

    assign zero = (alu_c == 32'b0);
    assign signed_less_than = ($signed(alu_a) < $signed(alu_b));
    assign less_than = (alu_a < alu_b);

endmodule: alu

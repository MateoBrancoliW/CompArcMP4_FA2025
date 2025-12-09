`timescale 1ns/1ps


module alu(
    input  logic [3:0]  alu_operation,
    input  logic [31:0] alu_a,
    input  logic [31:0] alu_b,
    output logic [31:0] alu_c,
    output logic zero
);
localparam ALU_ADD =4'b0000;
localparam ALU_SUB =4'b0001;
localparam ALU_AND =4'b0010;
localparam ALU_OR  =4'b0011;
localparam ALU_XOR =4'b0100;
localparam ALU_SLL =4'b1000;
localparam ALU_SRL =4'b0110;
localparam ALU_SRA =4'b0111;
localparam ALU_SLT =4'b0101;
localparam ALU_SLTU =4'b1001;


always_comb begin // From what I understand if R type works, immediate type works too
    alu_c = 32'b0;
    zero = 0;
    case (alu_operation)
        ALU_ADD: begin
            alu_c = alu_a + alu_b;
            zero = 0;
        end
        ALU_SUB: begin
            alu_c = alu_a - alu_b;
            if (alu_a == alu_b) begin
                zero = 1;
            end
            else begin
                zero = 0;
            end
        end
        ALU_AND: alu_c = alu_a & alu_b;
        ALU_OR:  alu_c = alu_a | alu_b;
        ALU_SLT: begin
            alu_c = $signed(alu_a) < $signed(alu_b);
            zero = alu_c[0];
        end
        ALU_XOR: alu_c = alu_a ^ alu_b  ;
        ALU_SRL: alu_c = alu_a >> alu_b[4:0];
        ALU_SRA: alu_c = $signed(alu_a) >>> alu_b[4:0];
        ALU_SLL: alu_c = alu_a << alu_b[4:0];
        ALU_SLTU: begin
            alu_c = $unsigned(alu_a) < $unsigned(alu_b);
            zero = alu_c[0];
        end
        default: begin
        end
    endcase
end


endmodule

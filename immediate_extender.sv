// Immediate Extension Unit
module immediate_extension(
    input  logic [31:0] instr,
    input  logic [2:0] imm_src,
    output logic [31:0] imm_ext
);

    always_comb begin
        case (imm_src)

            // I-type: imm[31:20]
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};

            // S-type: imm[31:25 | 11:7]
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            // B-type: imm[31 | 7 | 30:25 | 11:8 | 0]
            3'b010: imm_ext = {{19{instr[31]}},
                               instr[31], instr[7],
                               instr[30:25], instr[11:8], 1'b0};

            // J-type: imm[31 | 19:12 | 20 | 30:21 | 0]
            3'b011: imm_ext = {{11{instr[31]}},
                               instr[31], instr[19:12],
                               instr[20], instr[30:21], 1'b0};

            // U-type: imm[31:12] << 12
            3'b100: imm_ext = {instr[31:12], 12'b0};

            default: imm_ext = 32'd0;
        endcase
    end

endmodule

// Control Unit for a simple multi-cycle RISC-V core
module control_unit(
    input  logic zero,
    input  logic clk,
    input  logic reset,
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,
    output logic pc_write,
    output logic pc_update,
    output logic reg_write,
    output logic mem_write,
    output logic ir_write,
    output logic [1:0] result_src,
    output logic [1:0] alu_src_b,
    output logic [1:0] alu_src_a,
    output logic adr_src,
    output logic [2:0] alu_control,
    output logic [2:0] imm_src
);

    // FSM states
    localparam FETCH      = 5'd0;
    localparam DECODE     = 5'd1;
    localparam MEM_ADR    = 5'd2;
    localparam MEM_READ   = 5'd3;
    localparam MEM_WB     = 5'd4;
    localparam MEM_WRITE  = 5'd5;
    localparam EXECUTE_R  = 5'd6;
    localparam ALU_WB     = 5'd7;
    localparam EXECUTE_I  = 5'd8;
    localparam JAL = 5'd9;
    localparam BEQ = 5'd10;
    localparam LUI = 5'd11;
    localparam AUI = 5'd12;
    localparam JALR = 5'd13;
    localparam BNE = 5'd14;
    localparam BLT = 5'd15;
    localparam BGE = 5'd16;
    localparam BLTU = 5'd17;
    localparam BGEU = 5'd18;
    localparam AUIPC = 5'd19;

    // State + control internals
    logic [3:0] state = FETCH;
    logic[3:0] next_state;
    logic [1:0] alu_op;
    logic branch;

    // ----------------------
    // State register
    // ----------------------
    always_ff @(posedge clk ) begin
        state <= next_state;
    end

    // ----------------------
    // Instruction decoder: imm_src
    // ----------------------
    always_comb begin
        // default
        imm_src = 3'b00;

        unique case (opcode)
        7'b0000011: imm_src = 3'b000; // Load (I-type)
        7'b0100011: imm_src = 3'b001; // Store (S-type)
        7'b0110011: imm_src = 3'b000; // R-type (no imm used)
        7'b1100011: imm_src = 3'b010; // Branch (B-type)
        7'b0010011: imm_src = 3'b000; // I-type ALU
        7'b1101111: imm_src = 3'b011; // JAL (J-type)
        7'b1100111: imm_src = 3'b000; // JALR (I-type)
        7'b0110111: imm_src = 3'b100; // LUI (U-type)
        7'b0010111: imm_src = 3'b100; // AUIPC (U-type)
        default:    imm_src = 3'b000;
        endcase
    end

    // ----------------------
    // ALU decoder: alu_control from alu_op / funct3 / funct7
    // encoding example:
    // 000 = ADD
    // 001 = SUB
    // 010 = AND
    // 011 = OR
    // 100 = XOR
    // ----------------------
    always_comb begin
        alu_control = 3'b000; // default ADD

        unique case (alu_op)
            2'b00: begin
                // simple add (e.g., PC+4, address calc)
                alu_control = 3'b000;
            end

            2'b01: begin
                // branch compare (e.g., SUB)
                alu_control = 3'b001;
            end

            2'b10: begin
                // R-type / I-type ALU operations
                unique case (funct3)
                    3'b000: begin
                        // ADD / SUB depends on funct7[5]
                        if (funct7[5]) begin
                            alu_control = 3'b001; // SUB
                        end else begin
                            alu_control = 3'b000; // ADD
                        end
                    end
                    3'b111: alu_control = 3'b010; // AND
                    3'b110: alu_control = 3'b011; // OR
                    3'b100: alu_control = 3'b100; // XOR
                    default: alu_control = 3'b000;
                endcase
            end

            default: begin
                alu_control = 3'b000;
            end
        endcase
    end

    // ----------------------
    // Main FSM: generates control signals + next_state
    // ----------------------
    always_comb begin
        // --- safe defaults (avoids latches) ---
        adr_src    = 1'b0;
        ir_write   = 1'b0;
        pc_update  = 1'b0;
        alu_src_a  = 2'b00;
        alu_src_b  = 2'b00;
        alu_op     = 2'b00;
        result_src = 2'b00;
        branch     = 1'b0;
        mem_write  = 1'b0;
        reg_write  = 1'b0;

        unique case (state)
            FETCH: begin
                adr_src    = 1'b0;      // PC as address
                ir_write   = 1'b1;      // load instruction
                pc_update  = 1'b1;      // PC = PC + 4
                alu_src_a  = 2'b01;     // use PC
                alu_src_b  = 2'b10;     // constant 4
                alu_op     = 2'b00;     // ADD
                result_src = 2'b10;     // ALU result -> PC
                branch     = 1'b0;
                mem_write  = 1'b0;
                reg_write  = 1'b0;
                next_state = DECODE;
            end

            // ---------------
            // DECODE
            // ---------------
            DECODE: begin
                alu_src_a = 2'b01;  // PC
                alu_src_b = 2'b01;  // imm (for branch target precompute)
                alu_op    = 2'b00;  // ADD

                branch     = 1'b0;
                pc_update  = 1'b0;
                ir_write   = 1'b0;
                reg_write  = 1'b0;
                mem_write  = 1'b0;

                unique case (opcode)
                    7'b0000011: next_state = MEM_ADR;    // Load
                    7'b0100011: next_state = MEM_ADR;    // Store
                    7'b0110011: next_state = EXECUTE_R;  // R-type
                    7'b0010011: next_state = EXECUTE_I;  // I-type
                    7'b1101111: next_state = JAL;        // JAL
                    7'b1100011: next_state = BEQ;        // Branch (e.g., BEQ)
                    7'b0110111: next_state = LUI;        // LUI
                    7'b0010111: next_state = AUI;        // AUIPC
                    7'b1100111: next_state = JALR;       // JALR
                    default:    next_state = FETCH;
                endcase
            end

            // ---------------
            // MEM_ADR: compute address for load/store
            // ---------------
            MEM_ADR: begin
                alu_src_a = 2'b10; // register base
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b00; // ADD

                unique case (opcode)
                    7'b0000011: next_state = MEM_READ;  // Load
                    7'b0100011: next_state = MEM_WRITE; // Store
                    default:    next_state = FETCH;
                endcase
            end

            // ---------------
            // MEM_READ: memory read
            // ---------------
            MEM_READ: begin
                adr_src    = 1'b1;  // use ALU result as address
                result_src = 2'b00; // data from memory
                next_state = MEM_WB;
            end

            // ---------------
            // MEM_WB: write back load result
            // ---------------
            MEM_WB: begin
                result_src = 2'b01; // mem_data
                reg_write  = 1'b1;
                next_state = FETCH;
            end

            // ---------------
            // MEM_WRITE: store
            // ---------------
            MEM_WRITE: begin
                adr_src    = 1'b1;  // ALU result as address
                mem_write  = 1'b1;
                result_src = 2'b00;
                next_state = FETCH;
            end

            // ---------------
            // EXECUTE_R: R-type ALU
            // ---------------
            EXECUTE_R: begin
                alu_src_a = 2'b10; // rs1
                alu_src_b = 2'b00; // rs2
                alu_op    = 2'b10; // use funct3/funct7
                next_state = ALU_WB;
            end

            // ---------------
            // EXECUTE_I: I-type ALU
            // ---------------
            EXECUTE_I: begin
                alu_src_a = 2'b10; // rs1
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b10; // use funct3/funct7
                next_state = ALU_WB;
            end

            // ---------------
            // ALU_WB: write back ALU result
            // ---------------
            ALU_WB: begin
                result_src = 2'b00; // ALU result
                reg_write  = 1'b1;
                next_state = FETCH;
            end

            // ---------------
            // LUI: load upper imm into rd
            // ---------------
            LUI: begin
                alu_src_a = 2'b11;
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b00; // ADD (0 + imm)
                next_state = ALU_WB;
            end

            // ---------------
            // AUI (AUIPC): PC + imm
            // ---------------
            AUI: begin
                alu_src_a = 2'b01; // PC
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b00; // ADD
                result_src = 2'b00;
                reg_write  = 1'b1;
                next_state = FETCH;
            end

            // ---------------
            // JAL: PC-relative jump, write rd = PC+4
            // ---------------
            JAL: begin
                // PC+4 already computed in FETCH and stored somewhere;
                // here we might compute target PC = PC + imm
                alu_src_a = 2'b01; // PC
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b00; // ADD
                pc_update = 1'b1;  // update PC from ALU result
                result_src = 2'b10; // (assume some path for PC+4 to rd)
                reg_write  = 1'b1;
                next_state = FETCH;
            end

            // ---------------
            // JALR: jump to rs1 + imm, write rd = PC+4
            // ---------------
            JALR: begin
                alu_src_a = 2'b10; // rs1
                alu_src_b = 2'b01; // imm
                alu_op    = 2'b00; // ADD
                pc_update = 1'b1;
                result_src = 2'b10; // PC+4 to rd
                reg_write  = 1'b1;
                next_state = FETCH;
            end

            // ---------------
            // BEQ: branch if zero
            // ---------------
            BEQ: begin
                alu_src_a = 2'b10; // rs1
                alu_src_b = 2'b00; // rs2
                alu_op    = 2'b01; // SUB (for comparison)
                branch    = 1'b1;
                result_src = 2'b00;

                if (zero) begin
                    pc_update = 1'b1; // branch taken
                end else begin
                    pc_update = 1'b0; // no update from branch path
                end

                next_state = FETCH;
            end

            default: begin
                next_state = FETCH;
            end
        endcase
    end

    // pc_write: actual write-enable for PC
    assign pc_write = pc_update | (branch & zero);

endmodule

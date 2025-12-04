// Control Unit
module control_unit(
    input logic zero,
    input logic clk,
    input logic reset,
    input logic [6:0] opcode,
    input logc [2:0] funct3,
    input logic funct7,

    output logic pc_write,
    output logic pc_update,
    output logic reg_write,
    output logic mem_write,
    output logic ir_write,
    output logic [1:0] result_src,
    output logic [1:0] alu_src_b,
    output logic [1:0] alu_src_a,
    output logic adr_src,
    output logic [2:0]alu_control,
    output logic [1:0] imm_src,
);
localparam FETCH = 4'd0;
localparam DECODE = 4'd1;
localparam MEM_ADR = 4'd2;
localparam MEM_READ = 4'd3;
localparam MEM_WB = 4'd4;
localparam MEM_WRITE = 4'd5;
localparam EXECUTE_R = 4'd6;
localparam ALU_WB = 4'd7;
localparam EXECUTE_I = 4'd8;
localparam JAL = 4'd9;
localparam BEQ = 4'd10;

logic [3:0] state = FETCH;
logic [3:0] next_state;
logic [1:0] alu_op;
logic branch;
logic pc_update;

// Instruction Decoder
always_comb begin
    case (opcode)
        7'b0000011: begin // Load
            imm_src = 2'b00;
        end
        7'b0100011: begin // Store
            imm_src = 2'b01;
        end
        7'b0110011: begin // R-type
            imm_src = 2'bxx;
        end
        7'b1100011: begin // Branch
            imm_src = 2'b10;
        end
        7'b0010011: begin // I-type
            imm_src = 2'b00;    
        end
        7'b1101111: begin // JAL
            imm_src = 2'b11;
        end
    endcase
end

// ALU Decoder
always_comb begin
    case (alu_op)
        2'b00: begin
           alu_control = 3'b000
        end
        2'b01: begin 
          alu_control = 3'b001; 
        end
        2'b10 begin 
            case (funct3)
                3'b000: begin
                    if ({op[5],funct7} == 2'b11) begin
                        alu_control = 3'b001; // ADD
                    end else begin
                        alu_control = 3'b000; // SUB
                    end
                end
                3'b010: alu_control = 3'b101; // AND
                3'b110: alu_control = 3'b011; // OR
                3'b111: alu_control = 3'b010; // XOR
            endcase
        end
    endcase
end
    
    //Main FSM
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= FETCH;
    end 
    else begin
        state <= next_state;
    end
end

always_comb begin 
    case (state) 
        FETCH begin
            adr_src = 1'b0;
            ir_write = 1'b1;
            pc_update = 1'b1;
            alu_src_a = 2'b00;
            alu_src_b = 2'b10;
            alu_op = 2'b00;
            result_src = 2'b10;
            branch = 1'b0;
            mem_write = 1'b0;
            reg_write = 1'b0;
            next_state = DECODE;
        end
        DECODE begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b01;
            alu_op = 2'b00;

            branch = 1'b0;
            pc_update = 1'b0;
            ir_write = 1'b0;
            reg_write = 1'b0;
            mem_write = 1'b0;

            case (opcode)
                7'b0000011: next_state = MEM_ADR; // Load
                7'b0100011: next_state = MEM_ADR; // Store
                7'b0110011: next_state = EXECUTE_R; // R-type
                7'b0010011: next_state = EXECUTE_I; // I-type
                7'b1101111: next_state = JAL; // JAL
                7'b1100011: next_state = BEQ; // Branch
            endcase
        end
        MEM_ADR begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b01;
            alu_op = 2'b00;

            case (opcode)
                7'b0000011: next_state = MEM_READ; // Load
                7'b0100011: next_state = MEM_WRITE; // Store
            endcase
        end
        MEM_READ begin
            result_src = 2'b00;
            adr_src = 1'b1;
            next_state = MEM_WB;
        end
        MEM_WB begin
            result_src = 2'b01;
            reg_write = 1'b1;
            next_state = FETCH;
        end
        MEM_WRITE begin
            result_src = 2'b00;
            mem_write = 1'b1;
            adr_src = 1'b1;
            next_state = FETCH;
        end
        EXECUTE_R begin
            alu_src_a = 2'b01;
            alu_src_b = 2'b01;
            alu_op = 2'b10;
            next_state = ALU_WB;
        end
        ALU_WB begin
            result_src = 2'b00;
            reg_write = 1'b1;
            next_state = FETCH;
        end
        EXECUTE_I begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b01;
            alu_op = 2'b10;
            next_state = ALU_WB;
        end
        JAL begin
            pc_update = 1'b1;
            alu_src_a = 2'b01;
            alu_src_b = 2'b10;
            alu_op = 2'b00;
            result_src = 2'b00;
            next_state = ALU_WB;
        end
        BEQ begin
            alu_src_a = 2'b10;
            alu_src_b = 2'b00;
            alu_op = 2'b01;
            branch = 1'b1;
            result_src = 2'b00;
            if (zero) begin
                pc_update = 1'b1;
            end else begin
                pc_update = 1'b0;
            end
            next_state = FETCH;
        end
    endcase
end
pc_write = pc_update | (branch & zero);
endmodule

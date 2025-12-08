`include "memory.sv"
`include "control_unit.sv"
`include "alu.sv"
`include "register_file.sv"
`include "immediate_extender.sv"
`include "program_counter.sv"
`include "2_to_1_mux.sv"
`include "3_to_1_mux.sv"

module top (
    input logic clk, 
    input logic reset,
    output logic LED, 
    output logic RGB_R, 
    output logic RGB_G, 
    output logic RGB_B
);

    localparam [3:0] INIT       = 4'd0;
    localparam [3:0] RED        = 4'd1;
    localparam [3:0] YELLOW     = 4'd2;
    localparam [3:0] GREEN      = 4'd3;
    localparam [3:0] CYAN       = 4'd4;
    localparam [3:0] BLUE       = 4'd5;
    localparam [3:0] MAGENTA    = 4'd6;

    localparam [21:0] STATE_DWELL_CYCLES = 22'd3000000;

    logic [2:0] funct3 = 3'b010;
    logic dmem_wren = 1'b0;
    logic [31:0] dmem_address = 31'd0;
    logic [31:0] imem_address;
    logic [31:0] dmem_data_in = 31'd0;
    logic [31:0] dmem_data_out;
    logic [31:0] imem_data_out;

    logic led;
    logic red;
    logic green;
    logic blue;

    logic zero, pc_write, pc_update, reg_write, mem_write, ir_write;
    logic adr_src, less_than , signed_less_than;
    logic [1:0] result_src, alu_src_a, alu_src_b;
    logic [2:0] alu_control, imm_src;
    logic [6:0]  funct7;
    logic[31:0] A, Data, instr, imm_ext, alu_a, alu_b, alu_c, write_data, read_data1, read_data2, next_pc, old_pc, rd_2_out, alu_out, res, adr;

    logic [3:0] state = INIT;
    logic [21:0] count = 22'd0;

    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (instr[14:12]), 
        .dmem_wren      (mem_write), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (write_data), 
        .imem_address   (adr), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (), 
        .led            (led), 
        .red            (red), 
        .green          (green), 
        .blue           (blue)
    );
    program_counter u2 (
        .clk            (clk),
        .reset          (reset),
        .pc_write       (pc_write),
        .next_pc          (res),
        .pc         (imem_address)
    );

    immediate_extension u3 (
        .instr    (instr),
        .imm_src      (imm_src),
        .imm_ext      (imm_ext)
    );

    register_file u4 (
        .clk            (clk),
        .reset          (reset),
        .rs1            (instr[19:15]),
        .rs2            (instr[24:20]),
        .rd             (instr[11:7]),
        .write_data     (write_data),
        .reg_write      (reg_write),
        .read_data1     (read_data1),
        .read_data2     (read_data2)
    );
    control_unit u5 (
        .clk            (clk),
        .reset          (reset),
        .zero          (zero),
        .opcode         (instr[6:0]),
        .funct3         (instr[14:12]),
        .funct7         (instr[31:25]),
        .pc_write         (pc_write),
        .pc_update      (pc_update),
        .reg_write      (reg_write),
        .mem_write      (mem_write),
        .ir_write       (ir_write),
        .result_src    (result_src),
        .alu_src_a      (alu_src_a),
        .alu_src_b      (alu_src_b),
        .adr_src       (adr_src),
        .alu_control   (alu_control),
        .imm_src       (imm_src)
    );
    alu u6 (
        .alu_operation  (alu_control),
        .alu_a          (alu_a),
        .alu_b          (alu_b),
        .alu_c          (alu_c),
        .zero          (zero),
        .less_than      (less_than),
        .signed_less_than (signed_less_than)
    );
    mux2_1  adr_mux(
        .in0 (imem_address),
        .in1 (res),
        .sel (adr_src),
        .out (adr)
    );

    mux3_1 alu_src_a_mux(
        .in0 (imem_address),
        .in1 (old_pc),
        .in2 (A),
        .sel (alu_src_a),
        .out (alu_a)
    );

    mux3_1 alu_src_b_mux(
        .in0 (rd_2_out),
        .in1 (imm_ext),
        .in2 (4),
        .sel (alu_src_b),
        .out (alu_b)
    );
    
    mux3_1 result_src_mux(
        .in0 (alu_out),
        .in1 (Data),
        .in2 (alu_c),
        .sel (result_src),
        .out (res)
    );

    always_ff @(posedge clk) begin
        if (ir_write) begin
            instr <= imem_data_out;
            old_pc <= imem_address;
        end
    end

    always_ff @(posedge clk)begin 
        A <= read_data1;
        write_data <= read_data2;
        rd_2_out <= read_data2;
    end
    always_ff @(posedge clk) begin
            alu_out <= alu_c;
    end


    assign Data = dmem_data_out;

    assign LED = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;



endmodule

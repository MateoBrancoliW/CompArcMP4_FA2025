`include "memory.sv"

module top (
    input logic clk, 
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
    logic [31:0] dmem_data_in = 31'd0;
    logic [31:0] dmem_data_out;
    logic [31:0] imem_address = 31'h1000;
    logic [31:0] imem_data_out;

    logic reset;
    logic led;
    logic red;
    logic green;
    logic blue;

    logic [3:0] state = INIT;
    logic [21:0] count = 22'd0;

    always_ff @(negedge clk) begin
        imem_address <= imem_address + 1;
    end

    always_ff @(negedge clk) begin
        case (state)
            INIT: begin
                dmem_address <= 32'hFFFFFFFC;
                dmem_data_in <= 32'hFFFF0000;
                dmem_wren <= 1'b1;
                count <= STATE_DWELL_CYCLES;
                state <= RED;
            end
            RED: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFFFFFF00;
                    count <= STATE_DWELL_CYCLES;
                    state <= YELLOW;
                end
            end
            YELLOW: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFF00FF00;
                    count <= STATE_DWELL_CYCLES;
                    state <= GREEN;
                end
            end
            GREEN: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h0000FFFF;
                    count <= STATE_DWELL_CYCLES;
                    state <= CYAN;
                end
            end
            CYAN: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h000000FF;
                    count <= STATE_DWELL_CYCLES;
                    state <= BLUE;
                end
            end
            BLUE: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'h00FF00FF;
                    count <= STATE_DWELL_CYCLES;
                    state <= MAGENTA;
                end
            end
            MAGENTA: begin
                if (count > 22'd0) begin
                    count <= count - 1;
                end
                else begin
                    dmem_data_in <= 32'hFFFF0000;
                    count <= STATE_DWELL_CYCLES;
                    state <= RED;
                end
            end
        endcase
    end

    memory #(
        .IMEM_INIT_FILE_PREFIX  ("rv32i_test")
    ) u1 (
        .clk            (clk), 
        .funct3         (funct3), 
        .dmem_wren      (dmem_wren), 
        .dmem_address   (dmem_address), 
        .dmem_data_in   (dmem_data_in), 
        .imem_address   (imem_address), 
        .imem_data_out  (imem_data_out), 
        .dmem_data_out  (dmem_data_out), 
        .reset          (reset), 
        .led            (led), 
        .red            (red), 
        .green          (green), 
        .blue           (blue)
    );

    assign LED = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;

endmodule

// Program Counter
module program_counter(
    input logic clk,
    input logic reset,
    input logic [31:0] next_pc,
    output logic [31:0] pc,
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'd0;
        end else begin
            pc <= next_pc;
        end
    end
endmodule

// Register File
module register_file(
    input logic clk,
    input logic reset
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic [4:0] rd,
    input logic [31:0] write_data,
    input logic reg_write,
    output logic [31:0] read_data1,
    output logic [31:0] read_data2
);  
logic [31:0] registers [0:31];

    // Read ports
    assign read_data1 = registers[rs1];
    assign read_data2 = registers[rs2];

    // Write port
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            integer i;
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (reg_write && (rd != 5'd0)) begin
            registers[rd] <= write_data;
        end
    end
endmodule

//Immediate Extension
module immediate_extension(
    input logic [31:7] instr,
    input logic [1:0] imm_src,
    output logic [31:0] imm_ext
);

    always_comb begin
        case (imm_src)
            2'b00: imm_ext = {{20{instr[31]}}, instr[31:20]};  // I-type
            2'b01: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};  // S-type
            2'b10: imm_ext = {{20{instr[31]}},instr[7],instr[30:25], instr[11:8], 1'd0};  // B-type
            2'b11: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'd0};  // J-type
            default: imm_ext = 32'd0;
        endcase
    end
endmodule

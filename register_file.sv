// Register File
module register_file(
    input logic clk,
    input logic reset,
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

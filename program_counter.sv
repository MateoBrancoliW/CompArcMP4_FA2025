// Program Counter
module program_counter(
    input  logic        clk,
    input  logic        reset,
    input  logic        pc_write,
    input  logic [31:0] next_pc,
    output logic [31:0] pc
);
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h1000;
        end 
        else if(pc_write) begin
            pc <= next_pc;
        end
    end
endmodule

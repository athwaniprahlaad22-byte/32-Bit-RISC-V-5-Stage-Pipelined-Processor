`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// regfile - 32 x 32-bit register file, 2 read ports / 1 write port
//
// x0 is hardwired to zero. Reads are combinational and write-through: if WB
// writes the register that ID is reading in the same cycle, the new value is
// returned. This covers the WB -> ID case that the EX forwarding unit cannot.
// ---------------------------------------------------------------------------
module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] regs [0:31];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (we && rd != 5'd0) begin
            regs[rd] <= wd;
        end
    end

    assign rd1 = (rs1 == 5'd0)                ? 32'b0 :
                 (we && rd == rs1)            ? wd    : regs[rs1];
    assign rd2 = (rs2 == 5'd0)                ? 32'b0 :
                 (we && rd == rs2)            ? wd    : regs[rs2];

endmodule

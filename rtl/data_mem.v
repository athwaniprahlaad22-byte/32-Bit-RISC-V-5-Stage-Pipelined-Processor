`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// data_mem - word-addressed data memory (Harvard: separate from instructions)
//
// Synchronous write, combinational read. Having separate instruction and data
// memories lets IF and MEM access memory in the same cycle, so there is no
// structural hazard.
// ---------------------------------------------------------------------------
module data_mem #(
    parameter DEPTH = 1024
) (
    input  wire        clk,
    input  wire        mem_write,
    input  wire        mem_read,
    input  wire [31:0] addr,
    input  wire [31:0] write_data,
    output wire [31:0] read_data
);

    localparam AW = $clog2(DEPTH);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'b0;
    end

    always @(posedge clk) begin
        if (mem_write)
            mem[addr[AW+1:2]] <= write_data;
    end

    assign read_data = mem_read ? mem[addr[AW+1:2]] : 32'b0;

endmodule

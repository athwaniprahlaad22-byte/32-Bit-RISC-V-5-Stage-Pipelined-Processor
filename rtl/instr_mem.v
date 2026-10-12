`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// instr_mem - read-only instruction memory (Harvard: separate from data)
//
// Word-addressed, combinational read. Unused words hold NOPs. An optional
// hex file can be loaded at elaboration with the INIT_FILE parameter.
// ---------------------------------------------------------------------------
module instr_mem #(
    parameter DEPTH     = 1024,
    parameter INIT_FILE = ""
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);

    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = `NOP;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[$clog2(DEPTH)+1:2]];

endmodule

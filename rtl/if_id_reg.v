`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// if_id_reg - IF/ID pipeline register
//   stall: hold current contents (load-use)
//   flush: replace with NOP (taken branch / jump)
// ---------------------------------------------------------------------------
module if_id_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        stall,
    input  wire        flush,
    input  wire [31:0] pc_in,
    input  wire [31:0] instr_in,
    output reg  [31:0] pc,
    output reg  [31:0] instr,
    output reg         valid
);

    always @(posedge clk) begin
        if (reset || flush) begin
            pc    <= 32'b0;
            instr <= `NOP;
            valid <= 1'b0;
        end else if (!stall) begin
            pc    <= pc_in;
            instr <= instr_in;
            valid <= 1'b1;
        end
    end

endmodule

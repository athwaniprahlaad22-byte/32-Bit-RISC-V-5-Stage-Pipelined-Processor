`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// forwarding_unit - resolves RAW data hazards by bypassing results into EX
//
// For each EX source operand:
//   1. EX/MEM match -> forward ALU result of the previous instruction
//   2. MEM/WB match -> forward the value being written back
//   3. otherwise    -> use the value read from the register file
// EX/MEM is checked first so the most recent write wins when both stages
// target the same register. x0 is never forwarded.
// ---------------------------------------------------------------------------
module forwarding_unit (
    input  wire [4:0] id_ex_rs1,
    input  wire [4:0] id_ex_rs2,
    input  wire [4:0] ex_mem_rd,
    input  wire       ex_mem_reg_write,
    input  wire [4:0] mem_wb_rd,
    input  wire       mem_wb_reg_write,
    output reg  [1:0] forward_a,
    output reg  [1:0] forward_b
);

    wire ex_mem_valid = ex_mem_reg_write && (ex_mem_rd != 5'd0);
    wire mem_wb_valid = mem_wb_reg_write && (mem_wb_rd != 5'd0);

    always @(*) begin
        if (ex_mem_valid && ex_mem_rd == id_ex_rs1)
            forward_a = `FWD_EXMEM;
        else if (mem_wb_valid && mem_wb_rd == id_ex_rs1)
            forward_a = `FWD_MEMWB;
        else
            forward_a = `FWD_NONE;

        if (ex_mem_valid && ex_mem_rd == id_ex_rs2)
            forward_b = `FWD_EXMEM;
        else if (mem_wb_valid && mem_wb_rd == id_ex_rs2)
            forward_b = `FWD_MEMWB;
        else
            forward_b = `FWD_NONE;
    end

endmodule

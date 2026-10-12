`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// control_unit - main decoder (ID stage)
//
// Supported: R-type ALU, I-type ALU, LW, SW, BEQ, BNE, JAL.
// Any other opcode decodes to a NOP (all write enables low).
// use_rs1 / use_rs2 tell the hazard unit which source fields are real
// register operands, so immediate bits are never mistaken for rs2.
// ---------------------------------------------------------------------------
module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        mem_to_reg,
    output reg        alu_src,     // 0: rs2, 1: immediate
    output reg  [1:0] alu_op,
    output reg  [1:0] imm_sel,
    output reg        branch,
    output reg        jump,
    output reg        use_rs1,
    output reg        use_rs2
);

    always @(*) begin
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        mem_to_reg = 1'b0;
        alu_src    = 1'b0;
        alu_op     = `ALUOP_ADD;
        imm_sel    = `IMM_I;
        branch     = 1'b0;
        jump       = 1'b0;
        use_rs1    = 1'b0;
        use_rs2    = 1'b0;

        case (opcode)
            `OP_RTYPE: begin
                reg_write = 1'b1;
                alu_op    = `ALUOP_RTYPE;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
            end
            `OP_ITYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_op    = `ALUOP_ITYPE;
                use_rs1   = 1'b1;
            end
            `OP_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                mem_to_reg = 1'b1;
                alu_src    = 1'b1;
                use_rs1    = 1'b1;
            end
            `OP_STORE: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                imm_sel   = `IMM_S;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
            end
            `OP_BRANCH: begin
                branch  = 1'b1;
                alu_op  = `ALUOP_BRANCH;
                imm_sel = `IMM_B;
                use_rs1 = 1'b1;
                use_rs2 = 1'b1;
            end
            `OP_JAL: begin
                reg_write = 1'b1;
                jump      = 1'b1;
                imm_sel   = `IMM_J;
            end
            default: ;
        endcase
    end

endmodule

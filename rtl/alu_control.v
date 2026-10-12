`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// alu_control - maps (alu_op, funct3, funct7[5]) to a 4-bit ALU operation
// ---------------------------------------------------------------------------
module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,
    output reg  [3:0] alu_ctrl
);

    always @(*) begin
        case (alu_op)
            `ALUOP_ADD:    alu_ctrl = `ALU_ADD;
            `ALUOP_BRANCH: alu_ctrl = `ALU_SUB;
            `ALUOP_RTYPE, `ALUOP_ITYPE: begin
                case (funct3)
                    // SUB only exists for R-type; ADDI never subtracts
                    3'b000: alu_ctrl = (alu_op == `ALUOP_RTYPE && funct7_5) ? `ALU_SUB : `ALU_ADD;
                    3'b001: alu_ctrl = `ALU_SLL;
                    3'b010: alu_ctrl = `ALU_SLT;
                    3'b011: alu_ctrl = `ALU_SLTU;
                    3'b100: alu_ctrl = `ALU_XOR;
                    3'b101: alu_ctrl = funct7_5 ? `ALU_SRA : `ALU_SRL;
                    3'b110: alu_ctrl = `ALU_OR;
                    3'b111: alu_ctrl = `ALU_AND;
                    default: alu_ctrl = `ALU_ADD;
                endcase
            end
            default: alu_ctrl = `ALU_ADD;
        endcase
    end

endmodule

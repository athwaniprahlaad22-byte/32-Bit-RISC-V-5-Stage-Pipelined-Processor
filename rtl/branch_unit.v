`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// branch_unit - resolves BEQ / BNE / JAL in the EX stage
//
// Operands come from the forwarding muxes, so branches see up-to-date
// register values without extra stalls (except after a load).
// ---------------------------------------------------------------------------
module branch_unit (
    input  wire        branch,
    input  wire        jump,
    input  wire [2:0]  funct3,
    input  wire [31:0] op_a,
    input  wire [31:0] op_b,
    input  wire [31:0] pc,
    input  wire [31:0] imm,
    output wire        taken,
    output wire [31:0] target
);

    wire equal = (op_a == op_b);

    reg cond;
    always @(*) begin
        case (funct3)
            3'b000:  cond = equal;    // BEQ
            3'b001:  cond = ~equal;   // BNE
            default: cond = 1'b0;     // other branch types not supported
        endcase
    end

    assign taken  = jump | (branch & cond);
    assign target = pc + imm;

endmodule

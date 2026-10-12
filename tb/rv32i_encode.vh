// ---------------------------------------------------------------------------
// rv32i_encode.vh - instruction encoders for writing test programs in Verilog
//
// Include inside a module. Lets testbenches build programs like
//     prog(ADDI(1, 0, 5));      // addi x1, x0, 5
//     prog(BEQ (1, 2, 12));     // beq  x1, x2, +12
// so no external assembler or toolchain is needed.
// Register arguments are register numbers; branch/jump offsets are in bytes
// relative to the branch instruction itself.
// ---------------------------------------------------------------------------

// ---- raw formats ----------------------------------------------------------
function [31:0] enc_r;
    input [6:0] f7; input [4:0] rs2, rs1; input [2:0] f3; input [4:0] rd;
    enc_r = {f7, rs2, rs1, f3, rd, 7'b0110011};
endfunction

function [31:0] enc_i;
    input [31:0] imm; input [4:0] rs1; input [2:0] f3; input [4:0] rd; input [6:0] op;
    enc_i = {imm[11:0], rs1, f3, rd, op};
endfunction

function [31:0] enc_s;
    input [31:0] imm; input [4:0] rs2, rs1; input [2:0] f3;
    enc_s = {imm[11:5], rs2, rs1, f3, imm[4:0], 7'b0100011};
endfunction

function [31:0] enc_b;
    input [31:0] imm; input [4:0] rs2, rs1; input [2:0] f3;
    enc_b = {imm[12], imm[10:5], rs2, rs1, f3, imm[4:1], imm[11], 7'b1100011};
endfunction

function [31:0] enc_j;
    input [31:0] imm; input [4:0] rd;
    enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'b1101111};
endfunction

// ---- R-type ---------------------------------------------------------------
function [31:0] ADD;  input [4:0] rd, rs1, rs2; ADD  = enc_r(7'b0000000, rs2, rs1, 3'b000, rd); endfunction
function [31:0] SUB;  input [4:0] rd, rs1, rs2; SUB  = enc_r(7'b0100000, rs2, rs1, 3'b000, rd); endfunction
function [31:0] SLL;  input [4:0] rd, rs1, rs2; SLL  = enc_r(7'b0000000, rs2, rs1, 3'b001, rd); endfunction
function [31:0] SLT;  input [4:0] rd, rs1, rs2; SLT  = enc_r(7'b0000000, rs2, rs1, 3'b010, rd); endfunction
function [31:0] SLTU; input [4:0] rd, rs1, rs2; SLTU = enc_r(7'b0000000, rs2, rs1, 3'b011, rd); endfunction
function [31:0] XOR;  input [4:0] rd, rs1, rs2; XOR  = enc_r(7'b0000000, rs2, rs1, 3'b100, rd); endfunction
function [31:0] SRL;  input [4:0] rd, rs1, rs2; SRL  = enc_r(7'b0000000, rs2, rs1, 3'b101, rd); endfunction
function [31:0] SRA;  input [4:0] rd, rs1, rs2; SRA  = enc_r(7'b0100000, rs2, rs1, 3'b101, rd); endfunction
function [31:0] OR;   input [4:0] rd, rs1, rs2; OR   = enc_r(7'b0000000, rs2, rs1, 3'b110, rd); endfunction
function [31:0] AND;  input [4:0] rd, rs1, rs2; AND  = enc_r(7'b0000000, rs2, rs1, 3'b111, rd); endfunction

// ---- I-type ALU -----------------------------------------------------------
function [31:0] ADDI;  input [4:0] rd, rs1; input [31:0] imm; ADDI  = enc_i(imm, rs1, 3'b000, rd, 7'b0010011); endfunction
function [31:0] SLTI;  input [4:0] rd, rs1; input [31:0] imm; SLTI  = enc_i(imm, rs1, 3'b010, rd, 7'b0010011); endfunction
function [31:0] SLTIU; input [4:0] rd, rs1; input [31:0] imm; SLTIU = enc_i(imm, rs1, 3'b011, rd, 7'b0010011); endfunction
function [31:0] XORI;  input [4:0] rd, rs1; input [31:0] imm; XORI  = enc_i(imm, rs1, 3'b100, rd, 7'b0010011); endfunction
function [31:0] ORI;   input [4:0] rd, rs1; input [31:0] imm; ORI   = enc_i(imm, rs1, 3'b110, rd, 7'b0010011); endfunction
function [31:0] ANDI;  input [4:0] rd, rs1; input [31:0] imm; ANDI  = enc_i(imm, rs1, 3'b111, rd, 7'b0010011); endfunction
function [31:0] SLLI;  input [4:0] rd, rs1, sh; SLLI = enc_i({7'b0000000, sh}, rs1, 3'b001, rd, 7'b0010011); endfunction
function [31:0] SRLI;  input [4:0] rd, rs1, sh; SRLI = enc_i({7'b0000000, sh}, rs1, 3'b101, rd, 7'b0010011); endfunction
function [31:0] SRAI;  input [4:0] rd, rs1, sh; SRAI = enc_i({7'b0100000, sh}, rs1, 3'b101, rd, 7'b0010011); endfunction

// ---- memory ---------------------------------------------------------------
function [31:0] LW; input [4:0] rd, rs1;  input [31:0] imm; LW = enc_i(imm, rs1, 3'b010, rd, 7'b0000011); endfunction
function [31:0] SW; input [4:0] rs2, rs1; input [31:0] imm; SW = enc_s(imm, rs2, rs1, 3'b010); endfunction

// ---- control flow ---------------------------------------------------------
function [31:0] BEQ; input [4:0] rs1, rs2; input [31:0] off; BEQ = enc_b(off, rs2, rs1, 3'b000); endfunction
function [31:0] BNE; input [4:0] rs1, rs2; input [31:0] off; BNE = enc_b(off, rs2, rs1, 3'b001); endfunction
function [31:0] JAL; input [4:0] rd; input [31:0] off; JAL = enc_j(off, rd); endfunction

// ---- pseudo-instructions --------------------------------------------------
function [31:0] NOP;  input dummy; NOP  = ADDI(0, 0, 0); endfunction
function [31:0] HALT; input dummy; HALT = JAL(0, 0); endfunction   // j . (self-loop)

// ---------------------------------------------------------------------------
// defines.vh - shared constants for the 5-stage pipelined RV32I core
// ---------------------------------------------------------------------------
`ifndef RV_DEFINES_VH
`define RV_DEFINES_VH

// Major opcodes (instruction[6:0])
`define OP_RTYPE   7'b0110011
`define OP_ITYPE   7'b0010011
`define OP_LOAD    7'b0000011
`define OP_STORE   7'b0100011
`define OP_BRANCH  7'b1100011
`define OP_JAL     7'b1101111

// Canonical NOP: addi x0, x0, 0 (inserted on flush / bubble)
`define NOP        32'h00000013

// ALU operation select (control unit -> ALU control)
`define ALUOP_ADD    2'b00   // loads, stores, jal (address/add)
`define ALUOP_BRANCH 2'b01   // branch compare (subtract)
`define ALUOP_RTYPE  2'b10   // decode funct3/funct7
`define ALUOP_ITYPE  2'b11   // decode funct3 (+funct7[5] for SRAI)

// ALU control codes (ALU control -> ALU)
`define ALU_ADD   4'b0000
`define ALU_SUB   4'b0001
`define ALU_AND   4'b0010
`define ALU_OR    4'b0011
`define ALU_XOR   4'b0100
`define ALU_SLL   4'b0101
`define ALU_SRL   4'b0110
`define ALU_SRA   4'b0111
`define ALU_SLT   4'b1000
`define ALU_SLTU  4'b1001

// Immediate formats
`define IMM_I  2'b00
`define IMM_S  2'b01
`define IMM_B  2'b10
`define IMM_J  2'b11

// Forwarding mux select
`define FWD_NONE   2'b00   // value read from register file in ID
`define FWD_MEMWB  2'b01   // value being written back (MEM/WB)
`define FWD_EXMEM  2'b10   // ALU result of previous instruction (EX/MEM)

`endif

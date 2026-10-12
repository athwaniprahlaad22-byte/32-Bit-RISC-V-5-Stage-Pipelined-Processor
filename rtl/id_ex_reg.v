`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// id_ex_reg - ID/EX pipeline register
//   bubble: clear all control signals so the slot behaves as a NOP
//           (used for both load-use stalls and branch flushes)
// ---------------------------------------------------------------------------
module id_ex_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        bubble,
    // control in
    input  wire        reg_write_in,
    input  wire        mem_read_in,
    input  wire        mem_write_in,
    input  wire        mem_to_reg_in,
    input  wire        alu_src_in,
    input  wire [1:0]  alu_op_in,
    input  wire        branch_in,
    input  wire        jump_in,
    input  wire        valid_in,
    // data in
    input  wire [31:0] pc_in,
    input  wire [31:0] rd1_in,
    input  wire [31:0] rd2_in,
    input  wire [31:0] imm_in,
    input  wire [4:0]  rs1_in,
    input  wire [4:0]  rs2_in,
    input  wire [4:0]  rd_in,
    input  wire [2:0]  funct3_in,
    input  wire        funct7_5_in,
    // control out
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg         mem_to_reg,
    output reg         alu_src,
    output reg  [1:0]  alu_op,
    output reg         branch,
    output reg         jump,
    output reg         valid,
    // data out
    output reg  [31:0] pc,
    output reg  [31:0] rd1,
    output reg  [31:0] rd2,
    output reg  [31:0] imm,
    output reg  [4:0]  rs1,
    output reg  [4:0]  rs2,
    output reg  [4:0]  rd,
    output reg  [2:0]  funct3,
    output reg         funct7_5
);

    always @(posedge clk) begin
        if (reset || bubble) begin
            reg_write  <= 1'b0;
            mem_read   <= 1'b0;
            mem_write  <= 1'b0;
            mem_to_reg <= 1'b0;
            alu_src    <= 1'b0;
            alu_op     <= 2'b00;
            branch     <= 1'b0;
            jump       <= 1'b0;
            valid      <= 1'b0;
            pc         <= 32'b0;
            rd1        <= 32'b0;
            rd2        <= 32'b0;
            imm        <= 32'b0;
            rs1        <= 5'd0;
            rs2        <= 5'd0;
            rd         <= 5'd0;
            funct3     <= 3'b0;
            funct7_5   <= 1'b0;
        end else begin
            reg_write  <= reg_write_in;
            mem_read   <= mem_read_in;
            mem_write  <= mem_write_in;
            mem_to_reg <= mem_to_reg_in;
            alu_src    <= alu_src_in;
            alu_op     <= alu_op_in;
            branch     <= branch_in;
            jump       <= jump_in;
            valid      <= valid_in;
            pc         <= pc_in;
            rd1        <= rd1_in;
            rd2        <= rd2_in;
            imm        <= imm_in;
            rs1        <= rs1_in;
            rs2        <= rs2_in;
            rd         <= rd_in;
            funct3     <= funct3_in;
            funct7_5   <= funct7_5_in;
        end
    end

endmodule

`timescale 1ns/1ps
`include "defines.vh"

// ---------------------------------------------------------------------------
// riscv_pipeline - 5-stage pipelined RV32I core (IF / ID / EX / MEM / WB)
//
//   * Harvard memories: instruction and data memory are separate, so IF and
//     MEM never compete for a port (no structural hazards).
//   * Data hazards: EX/MEM and MEM/WB forwarding into EX, plus a write-through
//     register file for the WB -> ID case.
//   * Load-use: 1-cycle stall from the hazard unit.
//   * Control hazards: predict-not-taken, resolved in EX, 2-stage flush.
//   * Performance counters for cycles, retired instructions, stalls and
//     flushes.
// ---------------------------------------------------------------------------
module riscv_pipeline #(
    parameter IMEM_DEPTH = 1024,
    parameter DMEM_DEPTH = 1024,
    parameter IMEM_INIT  = ""
) (
    input  wire        clk,
    input  wire        reset,
    output reg  [31:0] cycle_count,
    output reg  [31:0] instret_count,
    output reg  [31:0] stall_count,
    output reg  [31:0] flush_count
);

    // ======================================================================
    // Hazard / control wires
    // ======================================================================
    wire        stall;           // load-use: hold PC and IF/ID
    wire        bubble;          // insert NOP into ID/EX
    wire        flush;           // taken branch: squash IF/ID and ID/EX
    wire        branch_taken;
    wire [31:0] branch_target;

    // ======================================================================
    // IF stage
    // ======================================================================
    reg  [31:0] pc;
    wire [31:0] pc_plus4 = pc + 32'd4;
    wire [31:0] if_instr;

    always @(posedge clk) begin
        if (reset)
            pc <= 32'b0;
        else if (branch_taken)
            pc <= branch_target;
        else if (!stall)
            pc <= pc_plus4;
    end

    instr_mem #(.DEPTH(IMEM_DEPTH), .INIT_FILE(IMEM_INIT)) u_imem (
        .addr  (pc),
        .instr (if_instr)
    );

    // ---------------------------- IF/ID ----------------------------------
    wire [31:0] if_id_pc;
    wire [31:0] if_id_instr;
    wire        if_id_valid;

    if_id_reg u_if_id (
        .clk      (clk),
        .reset    (reset),
        .stall    (stall),
        .flush    (flush),
        .pc_in    (pc),
        .instr_in (if_instr),
        .pc       (if_id_pc),
        .instr    (if_id_instr),
        .valid    (if_id_valid)
    );

    // ======================================================================
    // ID stage
    // ======================================================================
    wire [6:0] id_opcode   = if_id_instr[6:0];
    wire [4:0] id_rd       = if_id_instr[11:7];
    wire [2:0] id_funct3   = if_id_instr[14:12];
    wire [4:0] id_rs1      = if_id_instr[19:15];
    wire [4:0] id_rs2      = if_id_instr[24:20];
    wire       id_funct7_5 = if_id_instr[30];

    wire       id_reg_write, id_mem_read, id_mem_write, id_mem_to_reg;
    wire       id_alu_src, id_branch, id_jump, id_use_rs1, id_use_rs2;
    wire [1:0] id_alu_op, id_imm_sel;

    control_unit u_ctrl (
        .opcode     (id_opcode),
        .reg_write  (id_reg_write),
        .mem_read   (id_mem_read),
        .mem_write  (id_mem_write),
        .mem_to_reg (id_mem_to_reg),
        .alu_src    (id_alu_src),
        .alu_op     (id_alu_op),
        .imm_sel    (id_imm_sel),
        .branch     (id_branch),
        .jump       (id_jump),
        .use_rs1    (id_use_rs1),
        .use_rs2    (id_use_rs2)
    );

    wire [31:0] id_imm;
    imm_gen u_imm (
        .instr   (if_id_instr),
        .imm_sel (id_imm_sel),
        .imm     (id_imm)
    );

    // Write-back signals (driven in WB stage below)
    wire        wb_reg_write;
    wire [4:0]  wb_rd;
    wire [31:0] wb_data;

    wire [31:0] id_rd1, id_rd2;
    regfile u_regfile (
        .clk   (clk),
        .reset (reset),
        .we    (wb_reg_write),
        .rs1   (id_rs1),
        .rs2   (id_rs2),
        .rd    (wb_rd),
        .wd    (wb_data),
        .rd1   (id_rd1),
        .rd2   (id_rd2)
    );

    // ---------------------------- ID/EX ----------------------------------
    wire        ex_reg_write, ex_mem_read, ex_mem_write, ex_mem_to_reg;
    wire        ex_alu_src, ex_branch, ex_jump, ex_valid, ex_funct7_5;
    wire [1:0]  ex_alu_op;
    wire [31:0] ex_pc, ex_rd1, ex_rd2, ex_imm;
    wire [4:0]  ex_rs1, ex_rs2, ex_rd;
    wire [2:0]  ex_funct3;

    id_ex_reg u_id_ex (
        .clk           (clk),
        .reset         (reset),
        .bubble        (bubble),
        .reg_write_in  (id_reg_write),
        .mem_read_in   (id_mem_read),
        .mem_write_in  (id_mem_write),
        .mem_to_reg_in (id_mem_to_reg),
        .alu_src_in    (id_alu_src),
        .alu_op_in     (id_alu_op),
        .branch_in     (id_branch),
        .jump_in       (id_jump),
        .valid_in      (if_id_valid),
        .pc_in         (if_id_pc),
        .rd1_in        (id_rd1),
        .rd2_in        (id_rd2),
        .imm_in        (id_imm),
        .rs1_in        (id_use_rs1 ? id_rs1 : 5'd0),
        .rs2_in        (id_use_rs2 ? id_rs2 : 5'd0),
        .rd_in         (id_rd),
        .funct3_in     (id_funct3),
        .funct7_5_in   (id_funct7_5),
        .reg_write     (ex_reg_write),
        .mem_read      (ex_mem_read),
        .mem_write     (ex_mem_write),
        .mem_to_reg    (ex_mem_to_reg),
        .alu_src       (ex_alu_src),
        .alu_op        (ex_alu_op),
        .branch        (ex_branch),
        .jump          (ex_jump),
        .valid         (ex_valid),
        .pc            (ex_pc),
        .rd1           (ex_rd1),
        .rd2           (ex_rd2),
        .imm           (ex_imm),
        .rs1           (ex_rs1),
        .rs2           (ex_rs2),
        .rd            (ex_rd),
        .funct3        (ex_funct3),
        .funct7_5      (ex_funct7_5)
    );

    // ======================================================================
    // Hazard detection (looks at ID and EX)
    // ======================================================================
    hazard_unit u_hazard (
        .if_id_rs1      (id_rs1),
        .if_id_rs2      (id_rs2),
        .if_id_use_rs1  (id_use_rs1),
        .if_id_use_rs2  (id_use_rs2),
        .id_ex_rd       (ex_rd),
        .id_ex_mem_read (ex_mem_read),
        .branch_taken   (branch_taken),
        .stall          (stall),
        .bubble         (bubble),
        .flush          (flush)
    );

    // ======================================================================
    // EX stage
    // ======================================================================
    wire        mem_reg_write, mem_mem_read, mem_mem_write, mem_mem_to_reg, mem_valid;
    wire [31:0] mem_result, mem_write_data;
    wire [4:0]  mem_rd;

    wire [1:0] forward_a, forward_b;
    forwarding_unit u_fwd (
        .id_ex_rs1        (ex_rs1),
        .id_ex_rs2        (ex_rs2),
        .ex_mem_rd        (mem_rd),
        .ex_mem_reg_write (mem_reg_write),
        .mem_wb_rd        (wb_rd),
        .mem_wb_reg_write (wb_reg_write),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    reg [31:0] ex_op_a, ex_op_b;   // forwarded rs1 / rs2 values
    always @(*) begin
        case (forward_a)
            `FWD_EXMEM: ex_op_a = mem_result;
            `FWD_MEMWB: ex_op_a = wb_data;
            default:    ex_op_a = ex_rd1;
        endcase
        case (forward_b)
            `FWD_EXMEM: ex_op_b = mem_result;
            `FWD_MEMWB: ex_op_b = wb_data;
            default:    ex_op_b = ex_rd2;
        endcase
    end

    wire [31:0] ex_alu_b = ex_alu_src ? ex_imm : ex_op_b;

    wire [3:0]  ex_alu_ctrl;
    alu_control u_alu_ctrl (
        .alu_op   (ex_alu_op),
        .funct3   (ex_funct3),
        .funct7_5 (ex_funct7_5),
        .alu_ctrl (ex_alu_ctrl)
    );

    wire [31:0] ex_alu_result;
    alu u_alu (
        .a        (ex_op_a),
        .b        (ex_alu_b),
        .alu_ctrl (ex_alu_ctrl),
        .result   (ex_alu_result),
        .zero     ()
    );

    branch_unit u_branch (
        .branch (ex_branch),
        .jump   (ex_jump),
        .funct3 (ex_funct3),
        .op_a   (ex_op_a),
        .op_b   (ex_op_b),
        .pc     (ex_pc),
        .imm    (ex_imm),
        .taken  (branch_taken),
        .target (branch_target)
    );

    // JAL writes the return address (pc + 4) instead of the ALU result
    wire [31:0] ex_result = ex_jump ? (ex_pc + 32'd4) : ex_alu_result;

    // ---------------------------- EX/MEM ---------------------------------
    ex_mem_reg u_ex_mem (
        .clk           (clk),
        .reset         (reset),
        .reg_write_in  (ex_reg_write),
        .mem_read_in   (ex_mem_read),
        .mem_write_in  (ex_mem_write),
        .mem_to_reg_in (ex_mem_to_reg),
        .valid_in      (ex_valid),
        .result_in     (ex_result),
        .write_data_in (ex_op_b),
        .rd_in         (ex_rd),
        .reg_write     (mem_reg_write),
        .mem_read      (mem_mem_read),
        .mem_write     (mem_mem_write),
        .mem_to_reg    (mem_mem_to_reg),
        .valid         (mem_valid),
        .result        (mem_result),
        .write_data    (mem_write_data),
        .rd            (mem_rd)
    );

    // ======================================================================
    // MEM stage
    // ======================================================================
    wire [31:0] mem_read_data;
    data_mem #(.DEPTH(DMEM_DEPTH)) u_dmem (
        .clk        (clk),
        .mem_write  (mem_mem_write),
        .mem_read   (mem_mem_read),
        .addr       (mem_result),
        .write_data (mem_write_data),
        .read_data  (mem_read_data)
    );

    // ---------------------------- MEM/WB ---------------------------------
    wire        wb_mem_to_reg, wb_valid;
    wire [31:0] wb_result, wb_mem_data;

    mem_wb_reg u_mem_wb (
        .clk           (clk),
        .reset         (reset),
        .reg_write_in  (mem_reg_write),
        .mem_to_reg_in (mem_mem_to_reg),
        .valid_in      (mem_valid),
        .result_in     (mem_result),
        .mem_data_in   (mem_read_data),
        .rd_in         (mem_rd),
        .reg_write     (wb_reg_write),
        .mem_to_reg    (wb_mem_to_reg),
        .valid         (wb_valid),
        .result        (wb_result),
        .mem_data      (wb_mem_data),
        .rd            (wb_rd)
    );

    // ======================================================================
    // WB stage
    // ======================================================================
    assign wb_data = wb_mem_to_reg ? wb_mem_data : wb_result;

    // ======================================================================
    // Performance counters
    // ======================================================================
    always @(posedge clk) begin
        if (reset) begin
            cycle_count   <= 32'b0;
            instret_count <= 32'b0;
            stall_count   <= 32'b0;
            flush_count   <= 32'b0;
        end else begin
            cycle_count <= cycle_count + 32'd1;
            if (wb_valid) instret_count <= instret_count + 32'd1;
            if (stall)    stall_count   <= stall_count + 32'd1;
            if (flush)    flush_count   <= flush_count + 32'd1;
        end
    end

endmodule

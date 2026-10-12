`timescale 1ns/1ps
`include "defines.vh"

// Self-checking unit test for the ALU: every operation plus signed/unsigned
// and shift edge cases.
module tb_alu;

    reg  [31:0] a, b;
    reg  [3:0]  ctrl;
    wire [31:0] result;
    wire        zero;

    alu dut (.a(a), .b(b), .alu_ctrl(ctrl), .result(result), .zero(zero));

    integer errors = 0, checks = 0;

    task t;
        input [3:0]  op;
        input [31:0] x, y, expected;
        input [8*24-1:0] name;
        begin
            ctrl = op; a = x; b = y; #1;
            checks = checks + 1;
            if (result !== expected) begin
                errors = errors + 1;
                $display("  [FAIL] %0s: a=0x%08h b=0x%08h -> 0x%08h, expected 0x%08h",
                         name, x, y, result, expected);
            end
        end
    endtask

    initial begin
        $display("tb_alu");
        t(`ALU_ADD,  32'd7,        32'd5,        32'd12,       "add");
        t(`ALU_ADD,  32'hFFFFFFFF, 32'd1,        32'd0,        "add wrap");
        t(`ALU_ADD,  32'h7FFFFFFF, 32'd1,        32'h80000000, "add signed overflow");
        t(`ALU_SUB,  32'd5,        32'd7,        32'hFFFFFFFE, "sub negative");
        t(`ALU_SUB,  32'd42,       32'd42,       32'd0,        "sub equal");
        t(`ALU_AND,  32'hF0F0F0F0, 32'hFF00FF00, 32'hF000F000, "and");
        t(`ALU_OR,   32'hF0F0F0F0, 32'h0F0F0000, 32'hFFFFF0F0, "or");
        t(`ALU_XOR,  32'hAAAA5555, 32'hFFFF0000, 32'h55555555, "xor");
        t(`ALU_SLL,  32'd1,        32'd31,       32'h80000000, "sll 31");
        t(`ALU_SLL,  32'd3,        32'd0,        32'd3,        "sll 0");
        t(`ALU_SLL,  32'd1,        32'd33,       32'd2,        "sll uses b[4:0]");
        t(`ALU_SRL,  32'h80000000, 32'd31,       32'd1,        "srl 31");
        t(`ALU_SRL,  32'hF0000000, 32'd4,        32'h0F000000, "srl zero-fill");
        t(`ALU_SRA,  32'hF0000000, 32'd4,        32'hFF000000, "sra sign-fill");
        t(`ALU_SRA,  32'h70000000, 32'd4,        32'h07000000, "sra positive");
        t(`ALU_SLT,  32'hFFFFFFFF, 32'd1,        32'd1,        "slt -1 < 1");
        t(`ALU_SLT,  32'd1,        32'hFFFFFFFF, 32'd0,        "slt 1 < -1");
        t(`ALU_SLT,  32'd5,        32'd5,        32'd0,        "slt equal");
        t(`ALU_SLTU, 32'hFFFFFFFF, 32'd1,        32'd0,        "sltu big < 1");
        t(`ALU_SLTU, 32'd1,        32'hFFFFFFFF, 32'd1,        "sltu 1 < big");

        // zero flag
        ctrl = `ALU_SUB; a = 32'd9; b = 32'd9; #1;
        checks = checks + 1;
        if (zero !== 1'b1) begin errors = errors + 1; $display("  [FAIL] zero flag"); end

        if (errors == 0) $display("TEST PASSED: alu (%0d checks)", checks);
        else             $display("TEST FAILED: alu (%0d of %0d checks failed)", errors, checks);
        $finish;
    end

endmodule

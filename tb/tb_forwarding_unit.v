`timescale 1ns/1ps
`include "defines.vh"

// Self-checking unit test for the forwarding unit, including recent-write
// priority (EX/MEM over MEM/WB) and the x0 / RegWrite=0 exclusions.
module tb_forwarding_unit;

    reg  [4:0] rs1, rs2, ex_mem_rd, mem_wb_rd;
    reg        ex_mem_we, mem_wb_we;
    wire [1:0] fa, fb;

    forwarding_unit dut (
        .id_ex_rs1(rs1), .id_ex_rs2(rs2),
        .ex_mem_rd(ex_mem_rd), .ex_mem_reg_write(ex_mem_we),
        .mem_wb_rd(mem_wb_rd), .mem_wb_reg_write(mem_wb_we),
        .forward_a(fa), .forward_b(fb)
    );

    integer errors = 0, checks = 0;

    task t;
        input [4:0] s1, s2, exr; input exw; input [4:0] wbr; input wbw;
        input [1:0] ea, eb;
        input [8*40-1:0] name;
        begin
            rs1 = s1; rs2 = s2; ex_mem_rd = exr; ex_mem_we = exw;
            mem_wb_rd = wbr; mem_wb_we = wbw; #1;
            checks = checks + 1;
            if (fa !== ea || fb !== eb) begin
                errors = errors + 1;
                $display("  [FAIL] %0s: fa=%b fb=%b, expected fa=%b fb=%b", name, fa, fb, ea, eb);
            end
        end
    endtask

    initial begin
        $display("tb_forwarding_unit");
        //  rs1 rs2 exRd exW wbRd wbW   expA        expB
        t(1, 2,  3, 1,  4, 1, `FWD_NONE,  `FWD_NONE,  "no dependency");
        t(1, 2,  1, 1,  4, 1, `FWD_EXMEM, `FWD_NONE,  "rs1 from EX/MEM");
        t(1, 2,  3, 1,  2, 1, `FWD_NONE,  `FWD_MEMWB, "rs2 from MEM/WB");
        t(1, 2,  2, 1,  1, 1, `FWD_MEMWB, `FWD_EXMEM, "rs1 MEM/WB, rs2 EX/MEM");
        t(5, 5,  5, 1,  5, 1, `FWD_EXMEM, `FWD_EXMEM, "both stages: EX/MEM wins");
        t(5, 6,  5, 0,  5, 1, `FWD_MEMWB, `FWD_NONE,  "EX/MEM not writing");
        t(5, 6,  5, 0,  5, 0, `FWD_NONE,  `FWD_NONE,  "neither writing");
        t(0, 0,  0, 1,  0, 1, `FWD_NONE,  `FWD_NONE,  "x0 never forwarded");
        t(0, 3,  0, 1,  3, 1, `FWD_NONE,  `FWD_MEMWB, "x0 rs1, rs2 MEM/WB");

        if (errors == 0) $display("TEST PASSED: forwarding_unit (%0d checks)", checks);
        else             $display("TEST FAILED: forwarding_unit (%0d of %0d checks failed)", errors, checks);
        $finish;
    end

endmodule

`timescale 1ns/1ps

// Self-checking unit test for the hazard unit: load-use detection on rs1/rs2,
// no false stalls, and flush on a taken branch.
module tb_hazard_unit;

    reg  [4:0] rs1, rs2, ex_rd;
    reg        use1, use2, ex_load, taken;
    wire       stall, bubble, flush;

    hazard_unit dut (
        .if_id_rs1(rs1), .if_id_rs2(rs2),
        .if_id_use_rs1(use1), .if_id_use_rs2(use2),
        .id_ex_rd(ex_rd), .id_ex_mem_read(ex_load),
        .branch_taken(taken),
        .stall(stall), .bubble(bubble), .flush(flush)
    );

    integer errors = 0, checks = 0;

    task t;
        input [4:0] s1, s2; input u1, u2; input [4:0] r; input ld, tk;
        input es, eb, ef;
        input [8*40-1:0] name;
        begin
            rs1 = s1; rs2 = s2; use1 = u1; use2 = u2; ex_rd = r; ex_load = ld; taken = tk; #1;
            checks = checks + 1;
            if (stall !== es || bubble !== eb || flush !== ef) begin
                errors = errors + 1;
                $display("  [FAIL] %0s: stall=%b bubble=%b flush=%b, expected %b %b %b",
                         name, stall, bubble, flush, es, eb, ef);
            end
        end
    endtask

    initial begin
        $display("tb_hazard_unit");
        //  rs1 rs2 u1 u2 exRd load taken  stall bubble flush
        t(3, 4,  1, 1,  3,  1,   0,     1, 1, 0, "load-use on rs1");
        t(3, 4,  1, 1,  4,  1,   0,     1, 1, 0, "load-use on rs2");
        t(3, 4,  1, 1,  5,  1,   0,     0, 0, 0, "load, no dependency");
        t(3, 4,  1, 1,  3,  0,   0,     0, 0, 0, "ALU producer: forward, no stall");
        t(3, 4,  1, 0,  4,  1,   0,     0, 0, 0, "rs2 field is immediate");
        t(0, 0,  1, 1,  0,  1,   0,     0, 0, 0, "load to x0");
        t(3, 4,  1, 1,  9,  0,   1,     0, 1, 1, "taken branch flush");

        if (errors == 0) $display("TEST PASSED: hazard_unit (%0d checks)", checks);
        else             $display("TEST FAILED: hazard_unit (%0d of %0d checks failed)", errors, checks);
        $finish;
    end

endmodule

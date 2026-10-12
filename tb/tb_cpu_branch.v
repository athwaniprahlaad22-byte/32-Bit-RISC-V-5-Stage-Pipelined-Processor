`timescale 1ns/1ps

// Full-CPU test: control hazards. Predict-not-taken means not-taken branches
// are free; every taken branch/jump flushes the 2 wrong-path instructions,
// which must have no architectural effect (no register or memory writes).
module tb_cpu_branch;

    `include "cpu_tb_common.vh"

    initial begin
        $display("tb_cpu_branch");
        #1;
        prog(ADDI(1, 0, 5));        //  0: x1 = 5
        prog(ADDI(2, 0, 5));        //  1: x2 = 5
        prog(BEQ (1, 2, 12));       //  2: TAKEN -> 5 (operands forwarded)
        prog(ADDI(3, 0, 1));        //  3: flushed
        prog(ADDI(3, 0, 2));        //  4: flushed
        prog(ADDI(4, 0, 7));        //  5: x4 = 7
        prog(BNE (1, 2, 8));        //  6: not taken
        prog(ADDI(5, 0, 9));        //  7: x5 = 9
        prog(BEQ (1, 0, 8));        //  8: not taken
        prog(ADDI(6, 0, 3));        //  9: x6 = 3
        prog(JAL (7, 12));          // 10: TAKEN -> 13, x7 = 44 (return address)
        prog(ADDI(8, 0, 1));        // 11: flushed
        prog(SW  (1, 0, 128));      // 12: flushed - must NOT write mem[128]
        prog(ADDI(9, 0, 4));        // 13: x9 = 4
        prog(ADDI(10, 0, 3));       // 14: x10 = 3 (loop counter)
        prog(ADDI(11, 0, 0));       // 15: x11 = 0
        prog(ADDI(11, 11, 2));      // 16: loop: x11 += 2
        prog(ADDI(10, 10, -1));     // 17:       x10 -= 1
        prog(BNE (10, 0, -8));      // 18:       TAKEN twice, falls through once
        prog(ADDI(13, 0, 64));      // 19: x13 = 64
        prog(SW  (9, 13, 0));       // 20: mem[64] = 4
        prog(LW  (12, 13, 0));      // 21: x12 = 4
        prog(BEQ (12, 9, 8));       // 22: STALL (load-use), then TAKEN -> 24
        prog(ADDI(14, 0, 1));       // 23: flushed
        prog(ADDI(15, 0, 6));       // 24: x15 = 6
        prog(HALT(0));              // 25

        run_program(300);

        check_reg(3, 0);
        check_reg(4, 7);
        check_reg(5, 9);
        check_reg(6, 3);
        check_reg(7, 44);
        check_reg(8, 0);
        check_mem(128, 0);
        check_reg(9, 4);
        check_reg(10, 0);
        check_reg(11, 6);
        check_reg(12, 4);
        check_reg(14, 0);
        check_reg(15, 6);
        // taken: beq@2, jal@10, bne@18 x2, beq@22  -> 5 flushes
        check_val("flushes", flushes, 5);
        check_val("stalls", stalls, 1);
        finish_test("cpu_branch");
    end

endmodule

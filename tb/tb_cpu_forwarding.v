`timescale 1ns/1ps

// Full-CPU test: back-to-back RAW dependencies resolved purely by forwarding.
// Expect zero stalls and zero flushes.
module tb_cpu_forwarding;

    `include "cpu_tb_common.vh"

    initial begin
        $display("tb_cpu_forwarding");
        #1;
        prog(ADDI(1, 0, 5));        //  0: x1 = 5
        prog(ADDI(2, 0, 10));       //  1: x2 = 10
        prog(ADD (3, 1, 2));        //  2: x3 = x1(MEM/WB) + x2(EX/MEM)   = 15
        prog(SUB (4, 3, 1));        //  3: x4 = x3(EX/MEM) - x1(regfile)  = 10
        prog(ADD (5, 3, 4));        //  4: x5 = x3(MEM/WB) + x4(EX/MEM)   = 25
        prog(ADDI(6, 0, 1));        //  5: x6 = 1
        prog(ADDI(6, 0, 2));        //  6: x6 = 2  (newer write)
        prog(ADD (7, 6, 6));        //  7: x7 = 2 + 2 = 4  (EX/MEM must beat MEM/WB)
        prog(ADDI(8, 0, 7));        //  8: x8 = 7
        prog(NOP(0));               //  9
        prog(NOP(0));               // 10
        prog(ADD (9, 8, 8));        // 11: x9 = 14  (WB -> ID register-file bypass)
        prog(ADDI(10, 0, 64));      // 12: x10 = 64
        prog(ADDI(11, 0, 99));      // 13: x11 = 99
        prog(SW  (11, 10, 0));      // 14: mem[64] = 99 (store data from EX/MEM)
        prog(LW  (12, 10, 0));      // 15: x12 = 99
        prog(ADDI(0, 0, 5));        // 16: write to x0 is ignored
        prog(ADD (13, 0, 0));       // 17: x13 = 0  (x0 never forwarded)
        prog(SLLI(14, 5, 2));       // 18: x14 = 25 << 2 = 100
        prog(XOR (15, 14, 7));      // 19: x15 = 100 ^ 4 = 96
        prog(SUB (16, 4, 5));       // 20: x16 = 10 - 25 = -15
        prog(SRAI(17, 16, 1));      // 21: x17 = -15 >>> 1 = -8
        prog(SLTU(18, 16, 5));      // 22: x18 = (0xFFFFFFF1 <u 25) = 0
        prog(SLT (19, 16, 5));      // 23: x19 = (-15 < 25) = 1
        prog(HALT(0));              // 24

        run_program(200);

        check_reg(3, 15);
        check_reg(4, 10);
        check_reg(5, 25);
        check_reg(7, 4);
        check_reg(9, 14);
        check_reg(12, 99);
        check_mem(64, 99);
        check_reg(0, 0);
        check_reg(13, 0);
        check_reg(14, 100);
        check_reg(15, 96);
        check_reg(16, -15);
        check_reg(17, -8);
        check_reg(18, 0);
        check_reg(19, 1);
        check_val("stalls", stalls, 0);
        check_val("flushes", flushes, 0);
        finish_test("cpu_forwarding");
    end

endmodule

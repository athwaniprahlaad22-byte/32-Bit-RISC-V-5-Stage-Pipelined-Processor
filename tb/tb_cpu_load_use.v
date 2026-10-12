`timescale 1ns/1ps

// Full-CPU test: load-use hazards. Each true load-use dependency must cost
// exactly one stall cycle; independent or distance-2 uses must not stall.
module tb_cpu_load_use;

    `include "cpu_tb_common.vh"

    initial begin
        $display("tb_cpu_load_use");
        #1;
        prog(ADDI(1, 0, 64));       //  0: x1 = 64 (base address)
        prog(ADDI(2, 0, 11));       //  1
        prog(SW  (2, 1, 0));        //  2: mem[64] = 11
        prog(ADDI(2, 0, 22));       //  3
        prog(SW  (2, 1, 4));        //  4: mem[68] = 22
        prog(LW  (3, 1, 0));        //  5: x3 = 11
        prog(ADD (4, 3, 3));        //  6: STALL (rs1 and rs2)      x4 = 22
        prog(LW  (5, 1, 4));        //  7: x5 = 22
        prog(ADDI(6, 5, 1));        //  8: STALL (rs1)              x6 = 23
        prog(LW  (7, 1, 0));        //  9: x7 = 11
        prog(SUB (8, 2, 7));        // 10: STALL (rs2)              x8 = 22 - 11 = 11
        prog(LW  (9, 1, 4));        // 11: x9 = 22
        prog(NOP(0));               // 12
        prog(ADD (10, 9, 9));       // 13: distance 2, no stall     x10 = 44
        prog(LW  (11, 1, 0));       // 14: x11 = 11
        prog(SW  (11, 1, 8));       // 15: STALL (store data rs2)   mem[72] = 11
        prog(LW  (12, 1, 0));       // 16: x12 = 11
        prog(ADDI(13, 0, 12));      // 17: imm bits == 12 look like rs2=x12, but
                                    //     I-type has no rs2 -> no stall. x13 = 12
        prog(LW  (0, 1, 0));        // 18: load to x0
        prog(ADD (14, 0, 0));       // 19: no stall for x0          x14 = 0
        prog(HALT(0));              // 20

        run_program(200);

        check_mem(64, 11);
        check_mem(68, 22);
        check_reg(3, 11);
        check_reg(4, 22);
        check_reg(6, 23);
        check_reg(8, 11);
        check_reg(10, 44);
        check_mem(72, 11);
        check_reg(13, 12);
        check_reg(14, 0);
        check_reg(0, 0);
        check_val("stalls", stalls, 4);
        check_val("flushes", flushes, 0);
        finish_test("cpu_load_use");
    end

endmodule

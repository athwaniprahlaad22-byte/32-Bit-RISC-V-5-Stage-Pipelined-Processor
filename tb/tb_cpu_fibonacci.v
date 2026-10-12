`timescale 1ns/1ps

// Full-CPU integration test: build the first 12 Fibonacci numbers in data
// memory with a load/add/store loop, then sum them in a second loop.
// Exercises forwarding, load-use stalls and loop branches together.
module tb_cpu_fibonacci;

    `include "cpu_tb_common.vh"

    integer k;
    reg [31:0] fib [0:11];

    initial begin
        $display("tb_cpu_fibonacci");
        #1;
        // --- fib[0..11] -> mem[0..44] -----------------------------------
        prog(ADDI(1, 0, 0));        //  0: x1 = &fib[0]
        prog(SW  (0, 1, 0));        //  1: fib[0] = 0
        prog(ADDI(2, 0, 1));        //  2
        prog(SW  (2, 1, 4));        //  3: fib[1] = 1
        prog(ADDI(3, 0, 10));       //  4: x3 = 10 iterations
        prog(LW  (4, 1, 0));        //  5: loop1: x4 = fib[i]
        prog(LW  (5, 1, 4));        //  6:        x5 = fib[i+1]
        prog(ADD (6, 4, 5));        //  7:        STALL (x5)
        prog(SW  (6, 1, 8));        //  8:        fib[i+2] = x6
        prog(ADDI(1, 1, 4));        //  9:        i++
        prog(ADDI(3, 3, -1));       // 10
        prog(BNE (3, 0, -24));      // 11:        -> 5
        // --- sum fib[0..11] -> mem[64] ----------------------------------
        prog(ADDI(1, 0, 0));        // 12
        prog(ADDI(3, 0, 12));       // 13
        prog(ADDI(7, 0, 0));        // 14: x7 = sum
        prog(LW  (4, 1, 0));        // 15: loop2
        prog(ADD (7, 7, 4));        // 16:        STALL (x4)
        prog(ADDI(1, 1, 4));        // 17
        prog(ADDI(3, 3, -1));       // 18
        prog(BNE (3, 0, -16));      // 19:        -> 15
        prog(SW  (7, 0, 64));       // 20: mem[64] = sum
        prog(HALT(0));              // 21

        run_program(1000);

        fib[0] = 0; fib[1] = 1;
        for (k = 2; k < 12; k = k + 1) fib[k] = fib[k-1] + fib[k-2];
        for (k = 0; k < 12; k = k + 1) check_mem(4 * k, fib[k]);
        check_mem(64, 232);
        check_reg(7, 232);
        // one load-use stall per iteration: 10 + 12
        check_val("stalls", stalls, 22);
        // taken back-edges: 9 + 11
        check_val("flushes", flushes, 20);
        finish_test("cpu_fibonacci");
    end

endmodule

// ---------------------------------------------------------------------------
// cpu_tb_common.vh - shared harness for full-CPU testbenches
//
// Include at the top of a testbench module. Provides:
//   * clock, reset and the DUT (riscv_pipeline)
//   * prog(instr)          append an instruction to instruction memory
//   * run_program(max)     reset, run until HALT (jal x0, 0) reaches EX
//   * check_reg / check_mem / check_val   self-checking comparisons
//   * finish_test          print PASS/FAIL summary and end simulation
//
// After run_program:
//   stalls / flushes  hazard events up to (not including) the HALT jump
//   instrs / cycles   instructions retired before HALT and cycles taken
// ---------------------------------------------------------------------------

`include "rv32i_encode.vh"

reg clk   = 1'b0;
reg reset = 1'b1;
always #5 clk = ~clk;

wire [31:0] cycle_count, instret_count, stall_count, flush_count;

riscv_pipeline dut (
    .clk           (clk),
    .reset         (reset),
    .cycle_count   (cycle_count),
    .instret_count (instret_count),
    .stall_count   (stall_count),
    .flush_count   (flush_count)
);

integer errors   = 0;
integer checks   = 0;
integer prog_idx = 0;
integer stalls, flushes, instrs, cycles;
reg [8*256-1:0] vcd_file;

initial begin
    if ($value$plusargs("vcd=%s", vcd_file)) begin
        $dumpfile(vcd_file);
        $dumpvars(0, dut);
    end
end

task prog;
    input [31:0] instr;
    begin
        dut.u_imem.mem[prog_idx] = instr;
        prog_idx = prog_idx + 1;
    end
endtask

// HALT detected when a taken jump in EX targets its own PC
wire halted = dut.branch_taken && (dut.branch_target == dut.ex_pc);

task run_program;
    input integer max_cycles;
    integer n;
    begin
        reset = 1'b1;
        repeat (2) @(negedge clk);
        reset = 1'b0;
        n = 0;
        @(negedge clk);
        while (!halted && n < max_cycles) begin
            @(negedge clk);
            n = n + 1;
        end
        if (!halted) begin
            $display("  [FAIL] program did not reach HALT within %0d cycles", max_cycles);
            errors = errors + 1;
        end
        // Counters at this point cover every event before the HALT jump.
        stalls  = stall_count;
        flushes = flush_count;
        // Instructions still in MEM and WB retire in the next two cycles.
        instrs  = instret_count + dut.mem_valid + dut.wb_valid;
        cycles  = cycle_count + 2;
        // Drain the pipeline so all register / memory writes land.
        repeat (3) @(negedge clk);
        $display("  cycles=%0d  instrs=%0d  CPI=%0.2f  stalls=%0d  flushes=%0d",
                 cycles, instrs, cycles * 1.0 / instrs, stalls, flushes);
    end
endtask

task check_val;
    input [8*32-1:0] name;
    input [31:0]     actual;
    input [31:0]     expected;
    begin
        checks = checks + 1;
        if (actual !== expected) begin
            errors = errors + 1;
            $display("  [FAIL] %0s = %0d (0x%08h), expected %0d (0x%08h)",
                     name, $signed(actual), actual, $signed(expected), expected);
        end else begin
            $display("  [ OK ] %0s = %0d", name, $signed(actual));
        end
    end
endtask

task check_reg;
    input [4:0]  r;
    input [31:0] expected;
    reg [8*32-1:0] name;
    begin
        $sformat(name, "x%0d", r);
        check_val(name, dut.u_regfile.regs[r], expected);
    end
endtask

task check_mem;
    input [31:0] byte_addr;
    input [31:0] expected;
    reg [8*32-1:0] name;
    begin
        $sformat(name, "mem[0x%0h]", byte_addr);
        check_val(name, dut.u_dmem.mem[byte_addr >> 2], expected);
    end
endtask

task finish_test;
    input [8*48-1:0] test_name;
    begin
        if (errors == 0)
            $display("TEST PASSED: %0s (%0d checks)", test_name, checks);
        else
            $display("TEST FAILED: %0s (%0d of %0d checks failed)", test_name, errors, checks);
        $finish;
    end
endtask

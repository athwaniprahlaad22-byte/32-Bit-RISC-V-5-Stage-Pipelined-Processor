# Pipeline Design Notes

These notes cover how the control signals behave cycle by cycle, for anyone reading the RTL or looking at waveforms.

## Pipeline registers

| Register | Fields | Stall | Flush / bubble |
|----------|--------|-------|----------------|
| IF/ID  | `pc`, `instr`, `valid` | holds contents | `instr <= NOP`, `valid <= 0` |
| ID/EX  | control (`reg_write`, `mem_read`, `mem_write`, `mem_to_reg`, `alu_src`, `alu_op`, `branch`, `jump`), `pc`, `rd1`, `rd2`, `imm`, `rs1`, `rs2`, `rd`, `funct3`, `funct7[5]`, `valid` | n/a (receives a bubble instead) | all control cleared, `valid <= 0` |
| EX/MEM | `reg_write`, `mem_read`, `mem_write`, `mem_to_reg`, `result`, `write_data`, `rd`, `valid` | never stalls | never flushed |
| MEM/WB | `reg_write`, `mem_to_reg`, `result`, `mem_data`, `rd`, `valid` | never stalls | never flushed |

`valid` follows each instruction down the pipeline. When it reaches WB it increments the retired-instruction counter, so bubbles and flushed slots are not counted.

When an instruction doesn't read a register (`use_rs1` / `use_rs2` = 0), ID/EX gets `rs1` / `rs2` = x0 instead of the raw instruction bits. That stops the forwarding unit from matching immediate bits by accident.

## Hazard unit outputs

| Signal | Meaning | Effect |
|--------|---------|--------|
| `stall`  | load-use hazard detected | PC holds, IF/ID holds |
| `bubble` | `stall \|\| flush` | ID/EX control cleared |
| `flush`  | branch/jump taken in EX | IF/ID cleared to NOP, PC <- target |

A taken branch in EX means ID/EX holds a branch, not a load, so `stall` and `flush` can't happen in the same cycle. `flush` is still given priority in the PC logic so the PC always follows the branch.

## PC update priority

```
if (reset)              pc <= 0
else if (branch_taken)  pc <= branch_target     // pc_EX + imm
else if (!stall)        pc <= pc + 4
// else hold
```

## Write-back and JAL

`ex_result = jump ? pc_EX + 4 : alu_result`. The JAL link address travels down the pipeline in the same field as an ALU result, so it can be forwarded like any other value with no special cases.

`wb_data = mem_to_reg ? mem_data : result`

## Worked example: load-use stall followed by a taken branch

From `tb_cpu_branch` (instructions 21–24):

```
                       c1   c2   c3   c4   c5   c6   c7   c8
21 lw   x12, 0(x13)    IF   ID   EX   MEM  WB
22 beq  x12, x9, +8         IF   ID   ID   EX   MEM  WB
23 addi x14, x0, 1               IF   IF   ID   --              wrong path, flushed
24 addi x15, x0, 6                         IF   --              wrong path, flushed
24 addi x15, x0, 6  (branch target)             IF   ID   EX ...
```

- c3: lw is in EX and beq is in ID. The hazard unit sees `ID/EX.mem_read` with `rd = x12` matching beq's `rs1`, so the PC and IF/ID hold and ID/EX gets a bubble. beq repeats ID in c4.
- c5: beq is in EX and lw is in WB. `forward_a = MEM/WB` supplies the loaded x12. The branch is taken, so `flush` clears IF/ID and ID/EX and the PC moves to the target (instruction 24, fetched again in c6).
- Total cost: 1 stall cycle + 2 flushed slots. The testbench checks exactly this (`stalls = 1` for that test).

## Performance counters

| Counter | Increments when |
|---------|-----------------|
| `cycle_count`   | every cycle after reset |
| `instret_count` | a valid instruction reaches WB |
| `stall_count`   | `stall` is high |
| `flush_count`   | `flush` is high (one per taken branch/jump) |

CPI = `cycle_count / instret_count`. With only forwarding hazards the CPI is close to 1 (the start-up fill cost spread over the program). Each load-use dependency adds 1 cycle and each taken branch adds 2.

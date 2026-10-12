`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// hazard_unit - load-use detection and control-hazard flush
//
// Load-use: a load in EX produces its data at the end of MEM, too late to
// forward to the instruction now in ID. Freeze PC and IF/ID for one cycle
// and turn ID/EX into a bubble; MEM/WB forwarding then supplies the data.
//
// Control: branches/jumps resolve in EX with predict-not-taken. When one is
// taken, the two younger instructions in IF/ID and ID/EX are wrong-path and
// get flushed (2-cycle penalty).
// ---------------------------------------------------------------------------
module hazard_unit (
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    input  wire       if_id_use_rs1,
    input  wire       if_id_use_rs2,
    input  wire [4:0] id_ex_rd,
    input  wire       id_ex_mem_read,
    input  wire       branch_taken,
    output wire       stall,       // hold PC and IF/ID
    output wire       bubble,      // zero ID/EX control signals
    output wire       flush        // squash IF/ID and ID/EX
);

    wire load_use = id_ex_mem_read && (id_ex_rd != 5'd0) &&
                    ((if_id_use_rs1 && id_ex_rd == if_id_rs1) ||
                     (if_id_use_rs2 && id_ex_rd == if_id_rs2));

    // A taken branch in EX means ID/EX is not a load, so the two cases never
    // overlap; flush still takes priority so the PC always follows the branch.
    assign flush  = branch_taken;
    assign stall  = load_use && !branch_taken;
    assign bubble = stall || flush;

endmodule

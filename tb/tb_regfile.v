`timescale 1ns/1ps

// Self-checking unit test for the register file: x0 hardwiring, basic
// write/read, and same-cycle write-through (WB -> ID bypass).
module tb_regfile;

    reg         clk = 0, reset = 1, we = 0;
    reg  [4:0]  rs1 = 0, rs2 = 0, rd = 0;
    reg  [31:0] wd = 0;
    wire [31:0] rd1, rd2;

    regfile dut (.clk(clk), .reset(reset), .we(we), .rs1(rs1), .rs2(rs2),
                 .rd(rd), .wd(wd), .rd1(rd1), .rd2(rd2));

    always #5 clk = ~clk;

    integer errors = 0, checks = 0;

    task check;
        input [31:0] actual, expected;
        input [8*40-1:0] name;
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("  [FAIL] %0s: got 0x%08h, expected 0x%08h", name, actual, expected);
            end
        end
    endtask

    task write;
        input [4:0] r; input [31:0] v;
        begin
            @(negedge clk); we = 1; rd = r; wd = v;
            @(negedge clk); we = 0;
        end
    endtask

    initial begin
        $display("tb_regfile");
        @(negedge clk); @(negedge clk); reset = 0;

        write(5'd1, 32'hDEADBEEF);
        write(5'd31, 32'h12345678);
        rs1 = 1; rs2 = 31; #1;
        check(rd1, 32'hDEADBEEF, "read x1");
        check(rd2, 32'h12345678, "read x31");

        write(5'd0, 32'hFFFFFFFF);
        rs1 = 0; #1;
        check(rd1, 32'd0, "x0 stays zero");

        // write-through: read the register being written in the same cycle
        @(negedge clk); we = 1; rd = 5'd7; wd = 32'hCAFEF00D; rs1 = 7; rs2 = 7; #1;
        check(rd1, 32'hCAFEF00D, "bypass port 1");
        check(rd2, 32'hCAFEF00D, "bypass port 2");
        @(negedge clk); we = 0; #1;
        check(rd1, 32'hCAFEF00D, "x7 committed");
        // bypass must not apply to x0
        @(negedge clk); we = 1; rd = 5'd0; wd = 32'h55555555; rs1 = 0; #1;
        check(rd1, 32'd0, "no bypass for x0");
        @(negedge clk); we = 0;

        if (errors == 0) $display("TEST PASSED: regfile (%0d checks)", checks);
        else             $display("TEST FAILED: regfile (%0d of %0d checks failed)", errors, checks);
        $finish;
    end

endmodule

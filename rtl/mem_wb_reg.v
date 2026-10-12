`timescale 1ns/1ps

// ---------------------------------------------------------------------------
// mem_wb_reg - MEM/WB pipeline register
// ---------------------------------------------------------------------------
module mem_wb_reg (
    input  wire        clk,
    input  wire        reset,
    input  wire        reg_write_in,
    input  wire        mem_to_reg_in,
    input  wire        valid_in,
    input  wire [31:0] result_in,
    input  wire [31:0] mem_data_in,
    input  wire [4:0]  rd_in,
    output reg         reg_write,
    output reg         mem_to_reg,
    output reg         valid,
    output reg  [31:0] result,
    output reg  [31:0] mem_data,
    output reg  [4:0]  rd
);

    always @(posedge clk) begin
        if (reset) begin
            reg_write  <= 1'b0;
            mem_to_reg <= 1'b0;
            valid      <= 1'b0;
            result     <= 32'b0;
            mem_data   <= 32'b0;
            rd         <= 5'd0;
        end else begin
            reg_write  <= reg_write_in;
            mem_to_reg <= mem_to_reg_in;
            valid      <= valid_in;
            result     <= result_in;
            mem_data   <= mem_data_in;
            rd         <= rd_in;
        end
    end

endmodule

`timescale 1ns/1ps
module Register_File #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input  logic                      i_clk,
    input  logic                      i_rstn,
    input  logic                      i_datain,
    input  logic [$clog2(DEPTH)-1:0]  i_rs1_addr,
    input  logic [$clog2(DEPTH)-1:0]  i_rs2_addr,
    input  logic [$clog2(DEPTH)-1:0]  i_rd_addr,
    input  logic                      i_wr_en,
    input  logic [$clog2(WIDTH):0]    i_counter,
    input  logic                      i_bittst,
    output logic                      o_rd1,
    output logic                      o_rd2,
    input  logic [2:0]                i_shift_amount,
    input  logic                      i_sra
);
    localparam int BITS = DEPTH*WIDTH;          // 128
    localparam int AW   = $clog2(BITS);         // 7
    localparam int BITW = $clog2(WIDTH);        // 4

    // 1-bit-wide, 128-deep RAM - THIS is the form Vivado maps to LUTRAM cleanly
    (* ram_style = "distributed" *)
    logic rf_mem [0:BITS-1];

    logic [BITW-1:0] r1_bit, r2_bit;
    logic [BITW:0]   shifted_idx;
    assign shifted_idx = i_counter + i_shift_amount;

    always_comb begin
        if (i_sra)
            r1_bit = (shifted_idx >= WIDTH) ? (WIDTH-1) : shifted_idx[BITW-1:0];
        else
            r1_bit = i_counter[BITW-1:0];
        r2_bit = i_bittst ? (WIDTH-1) : i_counter[BITW-1:0];
    end

    logic [AW-1:0] waddr, r1addr, r2addr;
    assign waddr  = {i_rd_addr,  i_counter[BITW-1:0]};
    assign r1addr = {i_rs1_addr, r1_bit};
    assign r2addr = {i_rs2_addr, r2_bit};

    always_ff @(posedge i_clk) begin
        if (i_wr_en && (i_rd_addr != 0))
            rf_mem[waddr] <= i_datain;
    end

    assign o_rd1 = rf_mem[r1addr];
    assign o_rd2 = rf_mem[r2addr];

    initial begin
        for (int i = 0; i < BITS; i++) rf_mem[i] = 1'b0;
    end
endmodule
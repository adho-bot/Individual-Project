`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

module Control_Unit_tb;

    // ───────────────────────────────────────────────
    // DUT signals
    // ───────────────────────────────────────────────
    logic        clk;
    logic        rstn;
    logic [31:0] instruction;

    // Control outputs
    logic [4:0]  rd1_addr, rd2_addr, wr_addr;
    logic        wr_en, rs2_sel, wb_sel, data_valid, dataout_en;
    logic [1:0]  news_sel;
    logic [9:0]  opcode;
    logic [4:0]  counter;
    logic        data_wr, data_rd;
    logic        o_Control_ready;

    // ───────────────────────────────────────────────
    // Instantiate DUT
    // ───────────────────────────────────────────────
Control_Unit dut (
    .i_clk(clk),
    .i_rstn(rstn),
    .i_instruction(instruction),

    .o_rd1_addr(rd1_addr),
    .o_rd2_addr(rd2_addr),
    .o_wr_addr(wr_addr),
    .o_wr_reg_en(wr_reg_en),
    .o_rs2_sel(rs2_sel),
    .o_news_sel(news_sel),
    .o_wb_sel(wb_sel),
    .o_opcode(opcode),
    .o_data_valid(data_valid),
    .o_counter(counter),
    .o_dataout_en(dataout_en),
    .o_data_wr(data_wr),
    .o_data_rd(data_rd),
    .o_Control_ready(o_Control_ready),

    // PISO / SIPO control
    .o_piso_load(piso_load),
    .o_piso_shift(piso_shift),
    .o_sipo_shift(sipo_shift)
);
    // ───────────────────────────────────────────────
    // Clock generation
    // ───────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ───────────────────────────────────────────────
    // Stimulus
    // ───────────────────────────────────────────────
initial begin
    rstn = 0;
    instruction = 32'b0;
    #100;
    rstn = 1;
    #10;

    // VECTOR_R_TYPE
    wait(o_Control_ready);
    instruction = {7'b0000001, 5'd2, 5'd1, 3'b000, 5'd3, `OP_R_TYPE};
    $display("\n[TB] Applying VECTOR_R_TYPE instruction: %b", instruction);
    @(negedge o_Control_ready);

    // LOAD
    wait(o_Control_ready);
    instruction = {20'd0, 5'd4, `OP_LOAD};
    $display("\n[TB] Applying LOAD instruction: %b", instruction);
    @(negedge o_Control_ready);

    // STORE
    wait(o_Control_ready);
    instruction = {25'd0, `OP_STORE};
    $display("\n[TB] Applying STORE instruction: %b", instruction);
    @(negedge o_Control_ready);

    // NEWS_TYPE
    wait(o_Control_ready);
    instruction = {7'b0000000, 2'b01, 5'd1, 3'b001, 5'd6, `OP_NEWS_TYPE};
    $display("\n[TB] Applying NEWS_TYPE instruction: %b", instruction);
    @(negedge o_Control_ready);

    #400;
    instruction = 0;
    $display("\nSimulation complete at time %t", $time);
    $stop;
end

endmodule

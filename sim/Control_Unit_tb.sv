`timescale 1ns/1ps
`include "Definitions.sv"
`include "Control_Unit.sv"

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
        .o_wr_en(wr_en),
        .o_rs2_sel(rs2_sel),
        .o_news_sel(news_sel),
        .o_wb_sel(wb_sel),
        .o_opcode(opcode),
        .o_data_valid(data_valid),
        .o_counter(counter),
        .o_dataout_en(dataout_en),
        .o_data_wr(data_wr),
        .o_data_rd(data_rd)
    );

    // ───────────────────────────────────────────────
    // Clock generation
    // ───────────────────────────────────────────────
    initial clk = 0;
    always #5 clk = ~clk;

    // ───────────────────────────────────────────────
    // Reset
    // ───────────────────────────────────────────────
    initial begin
        rstn = 0;
        instruction = 32'b0;
        #20;
        rstn = 1;
    end

    // ───────────────────────────────────────────────
    // Main stimulus
    // ───────────────────────────────────────────────
    initial begin
        @(posedge rstn);
        #10;

        // Run through all custom instruction types
        send_instr(VECTOR_R_TYPE_inst(), "VECTOR_R_TYPE");
        send_instr(LOAD_inst(),           "LOAD");
        send_instr(MV_TYPE_inst(),        "MV_TYPE");
        send_instr(STORE_inst(),          "STORE");
        send_instr(NEWS_TYPE_inst(),      "NEWS_TYPE");

        #50;
        $display("\nSimulation complete.");
        $stop;
    end

    // ───────────────────────────────────────────────
    // Helper instruction functions
    // ───────────────────────────────────────────────
    function [31:0] VECTOR_R_TYPE_inst();
        VECTOR_R_TYPE_inst = {7'b0000001, 5'd2, 5'd1, 3'b000, 5'd3, `OP_R_TYPE};
    endfunction

    function [31:0] LOAD_inst();
        LOAD_inst = {7'b0000010, 5'd0, 5'd0, 3'b000, 5'd4, `OP_LOAD};
    endfunction

    function [31:0] MV_TYPE_inst();
        MV_TYPE_inst = {1'b0, 6'b000000, 5'd1, 5'd2, 3'b000, 5'd5, `OP_MV_TYPE};
    endfunction

    function [31:0] STORE_inst();
        STORE_inst = {7'b0000011, 5'd3, 5'd2, 3'b000, 5'd0, `OP_STORE};
    endfunction

    function [31:0] NEWS_TYPE_inst();
        NEWS_TYPE_inst = {7'b0101010, 2'b01, 5'd1, 3'b001, 5'd6, `OP_NEWS_TYPE};
    endfunction

    // ───────────────────────────────────────────────
    // Task to send instructions
    // ───────────────────────────────────────────────
    task send_instr(input [31:0] instr, input string name);
        begin
            instruction = instr;
            $display("\n[TB] Applying %s instruction: %b", name, instr);
            repeat(40) @(posedge clk);
            instruction = 32'b0;
            repeat(5) @(posedge clk);
        end
    endtask
endmodule


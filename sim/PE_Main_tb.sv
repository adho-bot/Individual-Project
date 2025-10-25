`timescale 1ns/1ps

module PE_Main_tb;

    // Parameters
    localparam WIDTH = 32;
    localparam DEPTH = 16;
    localparam CLK_PERIOD = 10;

    // DUT signals
    logic i_clk, i_rstn;
    logic [$clog2(WIDTH)-1:0] i_counter;
    logic i_data, o_data;
    logic i_north, i_east, i_south, i_west;
    logic o_news;
    logic [$clog2(DEPTH)-1:0] i_rd1_addr, i_rd2_addr, i_wr_addr;
    logic i_wr_en, i_rs2_sel, i_wb_sel, i_data_valid, i_dataout_en;
    logic [1:0] i_news_sel;
    logic [9:0] i_opcode;

    // Instantiate DUT
    PE_Main #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_counter(i_counter),
        .i_data(i_data),
        .o_data(o_data),
        .i_north(i_north),
        .i_east(i_east),
        .i_south(i_south),
        .i_west(i_west),
        .o_news(o_news),
        .i_rd1_addr(i_rd1_addr),
        .i_rd2_addr(i_rd2_addr),
        .i_wr_addr(i_wr_addr),
        .i_wr_en(i_wr_en),
        .i_rs2_sel(i_rs2_sel),
        .i_news_sel(i_news_sel),
        .i_wb_sel(i_wb_sel),
        .i_opcode(i_opcode),
        .i_data_valid(i_data_valid),
        .i_dataout_en(i_dataout_en)
    );

    // Clock generation
    always #(CLK_PERIOD/2) i_clk = ~i_clk;

    // Reset and initialization
    initial begin
        i_clk = 0;
        i_rstn = 0;
        #50;
        i_rstn = 1;
    end

    // Shift-register approach for writing pattern
    logic [WIDTH-1:0] shift_reg;
    logic [$clog2(WIDTH):0] bit_cnt;
    logic busy;

    initial begin
        // Initialize signals
        i_data = 0; i_wr_en = 0; i_wb_sel = 1;
        i_rd1_addr = 0; i_rd2_addr = 1; i_wr_addr = 1;
        i_north = 0; i_east = 0; i_south = 0; i_west = 0;
        i_news_sel = 2'b00; i_rs2_sel = 0; i_opcode = 0;
        i_data_valid = 0; i_dataout_en = 0;

        // Load the pattern to shift in
        shift_reg = 32'b11010101010101010101010101010101;
        bit_cnt = 0;
        busy = 1;
        i_wr_en = 1;

        $display("---- TEST 1: Writing 110101010101... pattern ----");
    end

    // Always_ff style bit-serial driver
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            shift_reg <= 0;
            bit_cnt   <= 0;
            busy      <= 0;
            i_data    <= 0;
            i_wr_en   <= 0;
        end else if (busy) begin
            // Drive current LSB combinationally
            i_data <= shift_reg[0];

            // Shift after posedge
            shift_reg <= {1'b0, shift_reg[WIDTH-1:1]};
            bit_cnt <= bit_cnt + 1;

            if (bit_cnt == WIDTH-1) begin
                busy <= 0;
                i_wr_en <= 0;
            end
        end
    end
endmodule

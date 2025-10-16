module Array_Main#(
parameter ROWS = 1,
parameter COLS = 1
)(
    input logic i_clk,
    input logic i_rstn
    

);






    // PE instantiation template
    PE_Main #(
        .WIDTH(32),
        .DEPTH(4)
    ) pe_inst (
        // Global signals
        .i_clk        (i_clk),
        .i_rstn       (i_rstn),
        .i_counter    (i_counter),
        
        // Data input
        .i_data       (i_data),
        
        // Neighbour inputs
        .i_north      (i_north),
        .i_east       (i_east),
        .i_south      (i_south),
        .i_west       (i_west),
        
        // Neighbour output
        .o_news       (o_news),
        
        // Control signals
        .i_rd1_addr   (rd1_addr),
        .i_rd2_addr   (rd2_addr),
        .i_wr_addr    (wr_addr),
        .i_wr_en      (wr_en),
        .i_rs2_sel    (rs2_sel),
        .i_news_sel   (news_sel),
        .i_wb_sel     (wb_sel),
        .i_opcode     (opcode),
        .i_data_valid (data_valid)
    );



endmodule

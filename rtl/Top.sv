module Top (
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_instruction,
    
    // Data Memory Signals
    logic [31:0] address,
    logic [31:0] dataIn,
    logic [31:0] dataOut,
    logic        data_wr,
    logic        data_rd,
    
    // Array Memory Signals
    logic [31:0] array_address,
    logic        array_access
);

    
    // Control signals from Control_Unit to Array_Main
    logic [4:0]  rd1_addr;
    logic [4:0]  rd2_addr;
    logic [4:0]  wr_addr;
    logic        wr_en;
    logic        rs2_sel;
    logic [1:0]  news_sel;      // Assuming 2-bit select for NEWS
    logic [1:0]  wb_sel;        // Assuming 2-bit select for writeback
    logic [6:0]  opcode;        // Standard RISC-V opcode width
    logic        data_valid;
    logic [4:0]  counter;       // Assuming 32-bit counter
    logic        dataout_en;
    
    
    Array_Main #(
        .ROWS(1),         // example: 4x4 array
        .COLS(1),
        .DATA_WIDTH(32)
    ) array_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),

        // Control signals
        .i_rd1_addr(rd1_addr),
        .i_rd2_addr(rd2_addr),
        .i_wr_addr(wr_addr),
        .i_wr_en(wr_en),
        .i_rs2_sel(rs2_sel),
        .i_news_sel(news_sel),
        .i_wb_sel(wb_sel),
        .i_opcode(opcode),
        .i_data_valid(data_valid),
        .i_counter(counter),
        .i_dataout_en(dataout_en),

        // Global data bus
        .i_data_bus(dataOut),
        .o_data_bus(dataIn),

        // Memory access
        .i_array_access(array_access),
        .i_array_address(array_address)
    );
    
    Control_Unit ctrl_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),

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
        .o_data_rd(data_rdd)
    );
    

endmodule

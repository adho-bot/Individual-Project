module Top (
    input  logic i_clk,
    input  logic i_rstn
);

    //Data Memory Signals
    logic [31:0] address;
    logic [31:0] dataIn;
    logic [31:0] dataOut;
    logic        data_wr;
    logic        data_rd;

    //Array Memory Signals
    logic [31:0] array_address;
    logic        array_access;

    //Data Memory Instance
    Data_Memory #(
        .MEM_DEPTH(32'h0001_0000) // Example: parameter value written properly
    ) data_mem_inst (
        .i_clk           (i_clk),          // clock
        .i_address       (address),        // memory address
        .i_data          (dataIn),         // data input (to memory)
        .i_data_wr       (data_wr),        // write enable
        .i_data_rd       (data_rd),        // read enable
        .o_data          (dataOut),        // data output (from memory)
        .o_array_access  (array_access),   // array memory-mapped access flag
        .o_array_address (array_address)   // memory-mapped array address
    );
    
    
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
        .i_data_bus(data_bus_in),
        .o_data_bus(data_bus_out),

        // Memory access
        .i_array_access(array_access),
        .i_array_address(array_address)
    );
    
    Control_Unit ctrl_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(instruction),

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
        .i_dataout_en(dataout_en)
    );
    

endmodule

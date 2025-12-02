//Ignore for now. needs bus arbritration and system level stuff 

module System_Top(
    input logic         i_clk,
    input logic         i_rstn

    //input logic [31:0]  i_instruction
);
    logic [31:0]  i_instruction;

    logic        wr_en;
    logic        rd_en;

    //Data bus between Top and Data memory
    logic [31:0] array_data_in;
    logic [31:0] array_data_out;
    
    //Address out
    logic [31:0] address;

    // Instantiate Array + Array control top module
    Top top_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),

        //Data input/output
        .i_array_data(array_data_in),
        .o_array_data(array_data_out),

        // Data Memory interface
        .o_array_address(address),
        .o_wr_en(wr_en),//from array read enable
        .o_rd_en(rd_en) //from array write enable

    );

    // Instantiate Data_Memory module
    Data_Memory data_mem (
        .i_clk(i_clk),
        .i_address(address),
        .i_data(array_data_out),                   
        .i_wr_en(wr_en),
        .i_rd_en(rd_en),      
        .o_data(array_data_in)
    );

endmodule

`include "Definitions"

module Control_Unit(
	input logic 				   i_clk,
    input logic					   i_rstn,
	
	//instruction output
	input logic 	[31:0]	       i_instruction,
	

	//Control logic
    output  logic [4:0]  	i_rd1_addr,
    output  logic [4:0]  	i_rd2_addr,
    output  logic [4:0]  	i_wr_addr,
    output  logic        	i_wr_en,
    output  logic        	i_rs2_sel,
    output  logic [1:0]     i_news_sel,
    output  logic        	i_wb_sel,
    output  logic [9:0]  	i_opcode,
    output  logic        	i_data_valid,
    output  logic [4:0]     i_counter,
    output  logic           i_dataout_en


);

    //state logic
    logic [2:0] state;
    
    Control_FSM control_inst(
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),  // instruction word (opcode + operands)
        .i_counter(i_counter),
        .o_state(state)
    );


    Control_Decode decode_inst (
        .i_state(state),
        .i_instruction(i_instruction),
        .o_rd1_addr(i_rd1_addr),
        .o_rd2_addr(i_rd2_addr),
        .o_wr_addr(i_wr_addr),
        .o_wr_en(i_wr_en),
        .o_rs2_sel(i_rs2_sel),
        .o_news_sel(i_news_sel),
        .o_wb_sel(i_wb_sel),
        .o_opcode(i_opcode),
        .o_data_valid(i_data_valid),
        .o_dataout_en(i_dataout_en)
    );

endmodule

`include "Definitions.sv"

module Control_Unit(
	input logic 				   i_clk,
    input logic					   i_rstn,
	
	//instruction output
	input logic 	[31:0]	       i_instruction,
	

	//Control logic
    output  logic [4:0]  	o_rd1_addr,
    output  logic [4:0]  	o_rd2_addr,
    output  logic [4:0]  	o_wr_addr,
    output  logic        	o_wr_en,
    output  logic        	o_rs2_sel,
    output  logic [1:0]     o_news_sel,
    output  logic        	o_wb_sel,
    output  logic [9:0]  	o_opcode,
    output  logic        	o_data_valid,
    output  logic [4:0]     o_counter,
    output  logic           o_dataout_en,

    output logic            o_data_wr,
    output logic            o_data_rd

);

    //state logic
    logic [2:0] state;
    
    logic [4:0] o_counter;
    
    Control_FSM control_inst(
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),  // instruction word (opcode + operands)
        .o_counter(o_counter),
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
        .o_dataout_en(i_dataout_en),
        
        .o_data_wr(o_data_wr),
        .o_data_rd(o_data_rd)
    );

endmodule

Control_Unit(
	input logic 					i_clk,
	input logic					i_rstn,
	
	//instruction output
	input logic 	[31:0]				i_instruction,
	

	//Control logic
	output  logic [3:0]  				i_rd1_addr,
	output  logic [3:0]  				i_rd2_addr,
    	output  logic [3:0]  				i_wr_addr,
   	output  logic        				i_wr_en,
    	output  logic        				i_rs2_sel,
    	output  logic        				i_news_sel,
    	output  logic        				i_wb_sel,
    	output  logic [2:0]  				i_opcode,
    	output  logic        				i_data_valid,
    	output  logic [4:0]  	i_counter,
    	output  logic        				i_dataout_en


);



endmodule

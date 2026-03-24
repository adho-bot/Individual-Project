`include "Definitions.sv"
`timescale 1ns/1ps

module Control_Unit#(
    parameter int DATA_WIDTH,
    parameter int REG_DEPTH
    )(
	input logic 				   i_clk,
    input logic					   i_rstn,
	
	//instruction output
	input logic 	[19:0]	       i_instruction,
	
	//Instruction handshaking
	input logic                    i_instr_valid,

	//Control logic
    output  logic [$clog2(REG_DEPTH) - 1:0]  	o_rs1_addr,
    output  logic [$clog2(REG_DEPTH) - 1:0]  	o_rs2_addr,
    output  logic [$clog2(REG_DEPTH) - 1:0]  	o_rd_addr,
    output  logic        	o_wr_reg_en,
    output  logic        	o_rs2_sel,
    output  logic [1:0]     o_news_sel,
    output  logic        	o_wb_sel,
    output  logic [2:0]  	o_opcode,
    output  logic [$clog2(DATA_WIDTH):0]     o_counter,
    output  logic           o_dataout_en,

    output logic            o_data_wr,
    output logic            o_data_rd,
    
    output logic            o_Control_ready, //next instruction can be sent (for sync purposes)
    
    //PISO SIPO control
    output logic o_piso_load, 
    output logic o_piso_shift,
    output logic o_sipo_shift,
    
    //Address generation
    output logic [9:0]     o_array_address, 
    
    //PE gating
    output logic            o_PE_enable,
    
    //MSB bit
    output logic            o_bittst,
    
    //Shift logic
    output logic [2:0] o_shift_amount,
    output logic       o_sra    
);

    //state logic
    logic [3:0] state;

    Control_FSM #(
        .DATA_WIDTH(DATA_WIDTH)
    )   control_inst(
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),  // instruction word (opcode + operands)
        .i_instr_valid(i_instr_valid), //instruction handshaking signal
        .o_counter(o_counter),
        .o_state(state),
        .o_FSM_ready(o_Control_ready)
    );

    Control_Decode #(
        .REG_DEPTH(REG_DEPTH)
    )   decode_inst(
        .i_state(state),
        .i_instruction(i_instruction),
        .o_rs1_addr(o_rs1_addr),
        .o_rs2_addr(o_rs2_addr),
        .o_rd_addr(o_rd_addr),
        .o_wr_reg_en(o_wr_reg_en),
        .o_rs2_sel(o_rs2_sel),
        .o_news_sel(o_news_sel),
        .o_wb_sel(o_wb_sel),
        .o_opcode(o_opcode),
        .o_dataout_en(o_dataout_en),
        
        .o_data_wr(o_data_wr),
        .o_data_rd(o_data_rd),
        
        //PISO SIPO control signals
        .o_piso_load(o_piso_load), 
        .o_piso_shift(o_piso_shift),
        .o_sipo_shift(o_sipo_shift), 
        
        //Address generation
        .o_array_address(o_array_address),
        
        .o_bittst(o_bittst),
        
        //PE gating
        .o_PE_enable(o_PE_enable),
        
        .o_shift_amount(o_shift_amount),
        .o_sra(o_sra)    
    );

endmodule

`include "Definitions.sv"

module Control_Decode(
    // FSM / instruction inputs
    input  logic [3:0]  i_state,
    input  logic [31:0] i_instruction,

    // Control outputs
    output logic [4:0]  o_rd1_addr,
    output logic [4:0]  o_rd2_addr,
    output logic [4:0]  o_wr_addr,
    output logic        o_wr_reg_en,
    output logic        o_rs2_sel,
    output logic [1:0]  o_news_sel,
    output logic        o_wb_sel,
    output logic [9:0]  o_opcode,
    output logic        o_dataout_en,
    
    //Memory control
    output logic        o_data_wr,
    output logic        o_data_rd,
  
    //PISO SIPO control
    output logic        o_piso_load, 
    output logic        o_piso_shift,
    output logic        o_sipo_shift,  
    
    //address generation
    output logic [31:0] o_array_address,
    
    //PE gating
    output logic        o_PE_enable,
    
    //MSB latching
    output logic        o_bit0,
    
    //MSB bit
    output logic        o_bittst
);

always_comb begin
    if ((i_state == `STORE_DATA) || (i_state == `DATA_TO_MEM))
        o_array_address = {12'd0, i_instruction[31:20], i_instruction[14:7]};
    else
        o_array_address = {12'd0, i_instruction[31:12]};
end

always_comb begin
    o_rd1_addr  = i_instruction[19:15];
    o_rd2_addr  = i_instruction[24:20];
    o_wr_addr   = i_instruction[11:7];
    o_wr_reg_en = 1'b0;
    o_rs2_sel   = 1'b0;
    o_news_sel  = 2'b00;
    o_wb_sel    = 1'b0;
    o_opcode    = 10'd0;
    o_PE_enable = 1'b0;
    o_bit0      = 1'b0;
    o_bittst    = 1'b0;

    case (i_state)
        `R_EXECUTE: begin
            o_opcode    = {i_instruction[31:25], i_instruction[14:12]};
            o_wb_sel    = 1'b0;
            o_wr_reg_en = 1'b1;
            o_PE_enable = 1'b1;
        end

        `NEWS_EXECUTE: begin
            o_opcode    = {i_instruction[31:25], i_instruction[14:12]};
            o_rs2_sel   = 1'b1;
            o_news_sel  = i_instruction[24:23];
            o_wb_sel    = 1'b0;
            o_wr_reg_en = 1'b1;
            o_PE_enable = 1'b1;
            o_rd2_addr  = {2'b00, i_instruction[22:20]};
        end

        `DATA_LOAD: begin
            o_wr_reg_en = 1'b1;
            o_wb_sel    = 1'b1;
        end

        `ABS_A_MSB: begin
            o_bit0      = 1'b1;
            o_opcode    = {i_instruction[31:25], i_instruction[14:12]};
            o_PE_enable = 1'b1;
            o_bittst    = 1'b1;
            o_rd2_addr  = i_instruction[19:15]; // rs2 forced to rs1
        end

        `ABS_A1: begin
            o_bit0      = 1'b1;
            o_opcode    = {i_instruction[31:25], i_instruction[14:12]};
            o_wr_reg_en = 1'b1;
            o_PE_enable = 1'b1;
            o_bittst    = 1'b1;
            o_rd2_addr  = i_instruction[19:15];
        end

        `ABS_A: begin
            o_opcode    = {i_instruction[31:25], i_instruction[14:12]};
            o_wr_reg_en = 1'b1;
            o_PE_enable = 1'b1;
            o_bittst    = 1'b1;
            o_rd2_addr  = i_instruction[19:15];
        end

        default: ;
    endcase
end

always_comb begin
    o_dataout_en = 1'b0;
    o_data_wr    = 1'b0;
    o_data_rd    = 1'b0;
    o_piso_load  = 1'b0;
    o_piso_shift = 1'b0;
    o_sipo_shift = 1'b0;

    case (i_state)
        `DATA_FETCH:  o_data_rd    = 1'b1;
        `MEM_TO_DATA: o_piso_load  = 1'b1;
        `DATA_LOAD:   o_piso_shift = 1'b1;
        `STORE_DATA: begin
            o_dataout_en = 1'b1;
            o_sipo_shift = 1'b1;
        end
        `DATA_TO_MEM: o_data_wr    = 1'b1;
        default: ;
    endcase
end

endmodule
`include "Definitions.sv"
//need to add control signals for piso sipo
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
    output logic        o_data_valid,
    output logic        o_dataout_en,
    
    //Memory control
    output logic        o_data_wr,
    output logic        o_data_rd,
  
    //PISO SIPO control
    output logic o_piso_load, 
    output logic o_piso_shift,
    output logic o_sipo_shift,  
    
    //addrss generation
    output logic [31:0] o_array_address,
    
    //PE gating
    output logic        o_PE_enable 
);



always_comb begin

            o_rd1_addr   = i_instruction[19:15];
            o_rd2_addr   = i_instruction[24:20];
            o_wr_addr    = i_instruction[11:7];
            o_wr_reg_en  = 1'b0;
            o_rs2_sel    = 1'b0;
            o_news_sel   = 2'bXX;
            o_wb_sel     = 1'bX;
            o_opcode     = 10'd0;
            o_data_valid = 1'b0;
            o_dataout_en = 1'b0; 
            o_data_wr    = 1'b0;
            o_data_rd    = 1'b0;
            
            o_piso_load  = 1'b0;            //keeping it in for now. Will see if this signal is necessary in future
            o_piso_shift = 1'b0;
            o_sipo_shift = 1'b0;

            o_array_address = 32'd0;
            
            o_PE_enable = 1'b0;
    case(i_state)
        
        `DATA_FETCH: begin
            o_data_rd = 1'b1;
            o_array_address = {12'd0,i_instruction[31:12]};
        end
        
        
        `MEM_TO_DATA: begin
            o_piso_load  = 1'b1;
            o_array_address = {12'd0,i_instruction[31:12]};
        end
        
        `DATA_LOAD: begin
            o_wr_reg_en = 1'b1;
            o_wb_sel = 1'b1;
            o_wr_addr = i_instruction[11:7];
            o_piso_shift = 1'b1;
            o_array_address = {12'd0,i_instruction[31:12]};
        end
        
        `R_EXECUTE: begin
            o_opcode = {i_instruction[31:25],i_instruction[14:12]};
            o_rs2_sel = 1'b0;
            
            //Register writeback
            o_wb_sel = 1'b0; //write back to reg file
            o_wr_addr = i_instruction[11:7];
            o_wr_reg_en = 1'b1;
            
            //enable all PEs
            o_PE_enable = 1'b1;
        end
        
        `NEWS_EXECUTE: begin        //this is operation between rs1 and NEWS
            o_opcode = {i_instruction[31:25],i_instruction[14:12]};
            o_rs2_sel = 1'b1;
            o_news_sel = i_instruction[21:20]; //<-------NEED TO CHANGE VALUES BASED ON INSTRUCTIONS THAT I MAKE
            
            //Register writeback
            o_wb_sel = 1'b0; //write back to reg file
            o_wr_addr = i_instruction[11:7];
            o_wr_reg_en = 1'b1;
            
            //enable all PEs
            o_PE_enable = 1'b1;
            
        end
        
        `MV_EXECUTE: begin //
            o_opcode = {7'd0, 3'd0};        //add rs1 with 0
            o_rs2_sel = 1'b0;
            
            //Register writeback
            o_data_valid = 1'b1;     
            
            //enable all PEs
            o_PE_enable = 1'b1;  
        end
        
        `STORE_DATA: begin
            o_dataout_en = 1'b1;
            o_sipo_shift = 1'b1;
        end
        
        `DATA_TO_MEM: begin
            o_data_wr = 1'b1;
            o_array_address = {12'd0,i_instruction[31:20],i_instruction[14:7]};
        end
    endcase
end


endmodule

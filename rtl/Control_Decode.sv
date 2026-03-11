`include "Definitions.sv"
//need to add control signals for piso sipo
module Control_Decode#(
    parameter int REG_DEPTH
)(
    // FSM / instruction inputs
    input  logic [3:0]  i_state,
    input  logic [19:0] i_instruction,

    // Control outputs
    output logic [$clog2(REG_DEPTH) - 1:0]  o_rs1_addr,
    output logic [$clog2(REG_DEPTH) - 1:0]  o_rs2_addr,
    output logic [$clog2(REG_DEPTH) - 1:0]  o_rd_addr,
    output logic        o_wr_reg_en,
    output logic        o_rs2_sel,
    output logic [1:0]  o_news_sel,
    output logic        o_wb_sel,
    output logic [2:0]  o_opcode,
    output logic        o_dataout_en,
    
    //Memory control
    output logic        o_data_wr,
    output logic        o_data_rd,
  
    //PISO SIPO control
    output logic        o_piso_load, 
    output logic        o_piso_shift,
    output logic        o_sipo_shift,  
    
    //addrss generation
    output logic [9:0] o_array_address,
    
    output logic        o_bittst,
    
    //PE gating
    output logic        o_PE_enable,
    
    //Shift logic
    output logic [2:0] o_shift_amount,
    output logic       o_sra      
     
);

always_comb begin

            o_rs1_addr   = i_instruction[7:5];
            o_rs2_addr   = i_instruction[14:12];
            o_rd_addr    = i_instruction[4:2];
            o_wr_reg_en  = 1'b0;
            o_rs2_sel    = 1'b0;
            o_news_sel   = 2'b00;
            o_wb_sel     = 1'b0;
            o_opcode     = 3'd0;
            o_dataout_en = 1'b0; 
            o_data_wr    = 1'b0;
            o_data_rd    = 1'b0;
            
            o_piso_load  = 1'b0;            //keeping it in for now. Will see if this signal is necessary in future
            o_piso_shift = 1'b0;
            o_sipo_shift = 1'b0;

            o_array_address = i_instruction[17:8];
            
            o_bittst = 1'b0;
            
            o_PE_enable = 1'b0;
            
            o_sra = 1'b0;
            o_shift_amount = 3'd0;
    case(i_state)
        
        `DATA_FETCH: begin
            o_data_rd = 1'b1;
            o_array_address = i_instruction[17:8];
        end
        
        
        `MEM_TO_DATA: begin
            o_piso_load  = 1'b1;
            o_array_address = i_instruction[17:8];
        end
        
        `DATA_LOAD: begin
            o_wr_reg_en = 1'b1;
            o_wb_sel = 1'b1;
            o_rs1_addr = i_instruction[4:2];  //rs1 = rd             
            o_piso_shift = 1'b1;
            o_array_address = i_instruction[17:8];
        end
        
        `R_EXECUTE: begin
            o_bittst = (i_instruction[17:15] == `MSBTST);
            o_opcode = i_instruction[17:15];
            o_rs2_sel = 1'b0;
            
            //Register writeback
            o_wb_sel = 1'b0; //write back to reg file
            o_wr_reg_en = 1'b1;
            
            //enable all PEs
            o_PE_enable = 1'b1;
            
            // SRA: extract shift amount from rs2 field
            o_sra = (i_instruction[17:15] == `SRA);
            o_shift_amount = i_instruction[14:12];
        end
        
        `NEWS_EXECUTE: begin        //this is operation between rs1 and NEWS
            o_opcode = i_instruction[17:15];
            o_rs2_sel = 1'b1;
            o_news_sel = i_instruction[11:10];
            
            //Register writeback
            o_wb_sel = 1'b0; //write back to reg file from ALU
            o_wr_reg_en = 1'b1;
            
            //enable all PEs
            o_PE_enable = 1'b1;
            
            
        end
        
        `STORE_DATA: begin
            o_dataout_en = 1'b1;
            o_sipo_shift = 1'b1;
            o_array_address = i_instruction[17:8];
        end
        
        `DATA_TO_MEM: begin
            o_data_wr = 1'b1;
            o_array_address = i_instruction[17:8];
        end
        
    endcase
end


endmodule

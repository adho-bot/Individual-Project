`include "Definitions"

module Control_Decode(
    // FSM / instruction inputs
    input  logic [2:0]  i_state,
    input  logic [31:0] i_instruction,

    // Control outputs
    output logic [5:0]  o_rd1_addr,
    output logic [5:0]  o_rd2_addr,
    output logic [5:0]  o_wr_addr,
    output logic        o_wr_en,
    output logic        o_rs2_sel,
    output logic        o_news_sel,
    output logic        o_wb_sel,
    output logic [2:0]  o_opcode,
    output logic        o_data_valid,
    output logic [4:0]  o_counter,
    output logic        o_dataout_en
);



always_comb begin
    case(i_state)
    
    
    endcase
end


endmodule

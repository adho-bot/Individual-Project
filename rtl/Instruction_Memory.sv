module Instruction_Memory#(
    parameter MEM_SIZE = 1024
)(
    input  logic        i_clk,
    input  logic [31:0] i_address,
    input  logic        i_Control_Ready,

    output logic [31:0] o_instr
);

    logic [7:0] instr_memory [0:MEM_SIZE-1];
    
//Add .hex initial here
    

    // Normal memory read (only when not array-mapped)
    always_ff @(posedge i_clk) begin
        if (i_Control_Ready) begin
            o_instr <= {instr_memory[i_address[9:0]+3],
                       instr_memory[i_address[9:0]+2],
                       instr_memory[i_address[9:0]+1],
                       instr_memory[i_address[9:0]]};
        end
    end

    
endmodule
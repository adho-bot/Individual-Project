`include "Definitions.sv"


//magnitude = (x ^ x[WIDTH - 1]) + x[WIDTH - 1]

module ALU_bitserial(
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_operandA,
    input  logic i_operandB,
    input  logic [2:0] i_opcode,   // Only 5 ops for now
    output logic o_result

);

    logic r_carry, l_carry;
    
    //Internal
    logic y;

    // ALU Operations Multiplexer
    always_comb begin
        l_carry = 1'b0;
        o_result = 1'b0;
        y = 1'b0;
        case (i_opcode)
            `ADD: begin 
                o_result = i_operandA ^ i_operandB ^ r_carry;
                l_carry = (i_operandA & i_operandB) | (r_carry & (i_operandA ^ i_operandB));
            end
            `XORR: o_result = i_operandA ^ i_operandB;
            `ANDD: o_result = i_operandA & i_operandB;
            `ORR:  o_result = i_operandA | i_operandB;
            `SUB: begin
                o_result = i_operandA ^ i_operandB ^ r_carry;       
                l_carry  = (~i_operandA & i_operandB) | (r_carry & (~i_operandA ^ i_operandB)); 
            end 
            
            `MSBTST: begin
                o_result = i_operandA ^ i_operandB;
            end      
            `SRA: begin
                o_result = i_operandA;  // shift is handled in register file
            end       
            
            
            default: begin 
                o_result = 0;
                y = 0;
            end
        endcase
    end
    
    // Carry update
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            r_carry <= 1'b0;
        end else begin
                r_carry <= l_carry;
            end
    end

    //assign o_carry_out = r_carry;
endmodule


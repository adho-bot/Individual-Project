`include "Definitions.sv"

module ALU_bitserial(
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_operandA,
    input  logic i_operandB,
    input  logic [9:0] i_opcode,   // Only 5 ops for now
    output logic o_result
    //output logic o_carry_out
);

    logic r_carry, l_carry;

    // ALU Operations Multiplexer
    always_comb begin
        l_carry = 1'b0;
        o_result = 1'b0;
        case (i_opcode)
            `ADD: begin 
                o_result = i_operandA ^ i_operandB ^ r_carry;
                l_carry = (i_operandA & i_operandB) | (r_carry & (i_operandA ^ i_operandB));
            end
            `XORR: o_result = i_operandA ^ i_operandB;
            `ANDD: o_result = i_operandA & i_operandB;
            `ORR:  o_result = i_operandA | i_operandB;
            `SUB:  o_result = i_operandA + ~(i_operandB) + 1;
            default: o_result = 0;
        endcase
    end
    
    // Carry update
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn)
            r_carry <= 1'b0;
        else 
            r_carry <= l_carry;     //only consider carry when ADD
    end

    //assign o_carry_out = r_carry;
endmodule


module ALU_bitserial(
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_operandA,
    input  logic i_operandB,
    input  logic [1:0] i_opcode,   // Only 4 ops now
    output logic o_result
    //output logic o_carry_out
);
    // Opcode definitions
    localparam ADD = 2'b00,
               XOR = 2'b01,
               AND = 2'b10,
               OR  = 2'b11;

    logic r_carry, l_carry;

    // ALU Operations Multiplexer
    always_comb begin
        l_carry = 1'b0;
        o_result = 1'b0;
        case (i_opcode)
            ADD: begin 
                o_result = i_operandA ^ i_operandB ^ r_carry;
                l_carry = (i_operandA & i_operandB) | (r_carry & (i_operandA ^ i_operandB));
            end
            XOR: o_result = i_operandA ^ i_operandB;
            AND: o_result = i_operandA & i_operandB;
            OR:  o_result = i_operandA | i_operandB;
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


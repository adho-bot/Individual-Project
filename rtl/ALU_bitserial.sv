`include "Definitions.sv"


//magnitude = (x ^ x[31]) + x[31]

module ALU_bitserial(
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_operandA,
    input  logic i_operandB,
    input  logic [9:0] i_opcode,   // Only 5 ops for now
    output logic o_result,

    //input  logic i_sign,   // sign of operandA (latched MSB)
    input  logic i_bit0    // asserted on first bit time of the word (LSB)

);

    logic r_carry, l_carry;
    
    //Internal
    logic y;

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
            `SUB: begin
                o_result = i_operandA ^ i_operandB ^ r_carry;       
                l_carry  = (~i_operandA & i_operandB) | (r_carry & (~i_operandA ^ i_operandB)); 
            end 
            
            `ABS: begin
                // y = x XOR sssss...  (bitwise mask is just signed each cycle)
                y        = i_operandA ^ i_operandB;

                // out = y + s (bit-serial add using carry only)
                o_result = y ^ r_carry;

                // carry ripple when adding only carry-in:
                // c_next = y & c
                l_carry  = y & r_carry;
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
            // initialise carry at start of word for ops that use it
            if (i_bit0) begin
                if (i_opcode == `ABS)
                    r_carry <= i_operandB;   // inject +s at LSB time
                else
                    r_carry <= 1'b0;     // clear carry for ADD/SUB etc (recommended)
            end else begin
                // normal ripple
                r_carry <= l_carry;
            end
        end
    end

    //assign o_carry_out = r_carry;
endmodule


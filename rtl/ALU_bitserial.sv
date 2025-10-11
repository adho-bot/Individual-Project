module ALU_bitserial_minimal (
    input  logic clk,
    input  logic rst_n,
    input  logic i_en,           // Enable for processing
    input  logic i_init,         // Initialize new operation
    input  logic i_cnt_last,     // Signal for last bit (bit 31)
    
    // Bit-serial inputs (LSB first)
    input  logic i_operandA,
    input  logic i_operandB,
    
    // Control
    input  logic [2:0] i_opcode, // Operation select
    
    // Outputs
    output logic o_result,       // Bit-serial result
    output logic o_less_than,    // Comparison flag (valid at last bit)
    output logic o_carry_out     // Carry/Borrow out
);
    //===========================================
    // OPERATION ENCODING
    //===========================================
    localparam OP_ADD  = 3'b000;
    localparam OP_SUB  = 3'b001;
    localparam OP_XOR  = 3'b010;
    localparam OP_AND  = 3'b011;
    localparam OP_OR   = 3'b100;
    localparam OP_SLL  = 3'b101;  // Shift left logical
    localparam OP_SRL  = 3'b110;  // Shift right logical

    //===========================================
    // INTERNAL STATE
    //===========================================
    logic r_carry;       // Reused for carry & shift buffer
    logic r_less_than;

    //===========================================
    // COMMON INPUTS
    //===========================================
    logic is_sub = (i_opcode == OP_SUB);
    logic op0 = i_opcode[0];
    logic op1 = i_opcode[1];
    logic op2 = i_opcode[2];

    // OperandB inversion for SUB
    logic b_eff = i_operandB ^ is_sub;

    // Full adder (used only in arithmetic ops)
    logic w_sum   = i_operandA ^ b_eff ^ r_carry;
    logic w_carry = (i_operandA & b_eff) | (r_carry & (i_operandA ^ b_eff));

    //===========================================
    // SINGLE MUX TREE FOR ALL OPS
    //===========================================
    // Instead of separate logic paths (AND/XOR/OR/SHIFT),
    // we merge everything into a compact combinational function.
    always_comb begin
        case (i_opcode)
            OP_ADD, OP_SUB: o_result = w_sum;                       // Add/Sub
            OP_XOR:         o_result = i_operandA ^ i_operandB;     // XOR
            OP_AND:         o_result = i_operandA & i_operandB;     // AND
            OP_OR:          o_result = i_operandA | i_operandB;     // OR
            OP_SLL:         o_result = r_carry;                     // SLL → use previous bit (stored in r_carry)
            OP_SRL:         o_result = i_operandA;                  // SRL → current bit
            default:        o_result = 1'b0;
        endcase
    end

    //===========================================
    // STATE REGISTERS
    //===========================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            r_carry     <= 1'b0;
            r_less_than <= 1'b0;
        end
        else if (i_en) begin
            if (i_init) begin
                // Initialize carry: SUB starts with carry=1 (2’s complement)
                r_carry     <= is_sub;
                r_less_than <= 1'b0;
            end
            else begin
                case (i_opcode)
                    OP_ADD, OP_SUB: r_carry <= w_carry;        // Carry chain
                    OP_SLL:         r_carry <= i_operandA;     // Shift buffer reuse
                    default:        r_carry <= 1'b0;           // Reset when not used
                endcase

                // Capture less-than flag at final bit
                if (i_cnt_last && (i_opcode == OP_SUB))
                    r_less_than <= ~w_carry; // Borrow means A < B
            end
        end
    end

    //===========================================
    // OUTPUTS
    //===========================================
    assign o_carry_out = r_carry;
    assign o_less_than = r_less_than;

endmodule


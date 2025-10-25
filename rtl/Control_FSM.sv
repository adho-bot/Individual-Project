`include "Definitions"

module Control_FSM(
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic [31:0] i_instruction,  // instruction word (opcode + operands)

    output logic [2:0]  o_state
    
    
);

    // ───────────────────────────────────────────────
    // State encoding
    // ───────────────────────────────────────────────
    logic [2:0] next_state;

    // ───────────────────────────────────────────────
    // Sequential block - state register
    // ───────────────────────────────────────────────
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn)
            o_state <= `IDLE;
        else
            o_state <= next_state;
    end

    // ───────────────────────────────────────────────
    // Combinational block - next state logic
    // ───────────────────────────────────────────────
    always_comb begin

        case (o_state)

            `IDLE: begin
                next_state = `DECODE;
            end

            `DECODE: begin
                case(i_instruction[6:0])
                    `OP_LOAD:   next_state = `DATA_LOAD;
                    `OP_R_TYPE:  next_state = `R_EXECUTE;
                    `OP_MV_TYPE: next_state = `MV_EXECUTE;
                    `OP_STORE: next_state = `STORE_DATA;
                    default:   next_state = `IDLE;
                endcase
            end

            `DATA_LOAD: begin
             next_state = `IDLE; // fallback
            end

            `R_EXECUTE: begin
                next_state = `IDLE;
            end

            `MV_EXECUTE: begin
                next_state = `IDLE;
            end

            `STORE_DATA: begin
                next_state = `IDLE;
            end
            default: begin
                next_state = `IDLE;
            end

        endcase
    end

endmodule

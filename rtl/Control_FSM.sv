`include "Definitions.sv"

module Control_FSM(
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic [31:0] i_instruction,  // instruction word (opcode + operands)
    output  logic [5:0] o_counter,      //sync counter

    output logic [2:0]  o_state,
    
    output logic        o_FSM_ready     //ready signal for next instruction to be sent
    
    
);

    // ───────────────────────────────────────────────
    // State encoding
    // ───────────────────────────────────────────────
    logic [2:0] next_state;


    // ───────────────────────────────────────────────
    // Counter Logic
    // ───────────────────────────────────────────────
    logic [5:0] counter;
    assign o_counter = counter;    

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
                    `OP_NEWS_TYPE: next_state = `NEWS_EXECUTE;
                    default:   next_state = `IDLE;
                endcase
            end

            `DATA_LOAD: begin
                if(counter < 6'd31) begin
                    next_state = `DATA_LOAD; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `R_EXECUTE: begin
                if(counter < 6'd31) begin
                    next_state = `R_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end
            
            `NEWS_EXECUTE: begin    //
                if(counter < 5'd31) begin
                    next_state = `NEWS_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `MV_EXECUTE: begin
                if(counter < 6'd31) begin
                    next_state = `MV_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `STORE_DATA: begin
                if(counter < 6'd31) begin
                    next_state = `STORE_DATA; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end
            default: begin
                next_state = `IDLE;
            end

        endcase
    end

always_ff@(posedge i_clk or negedge i_rstn) begin
	if(!i_rstn) begin
		counter <= 6'b0;
	end else if(o_state == `DATA_LOAD ||o_state == `R_EXECUTE ||
	            o_state == `NEWS_EXECUTE ||o_state == `MV_EXECUTE ||o_state == `STORE_DATA) begin
	               counter <= counter + 1;
	end else begin
	   counter <= 6'b0;
	end
end

assign o_FSM_ready = (o_state == `IDLE) ? 1 : 0;

endmodule

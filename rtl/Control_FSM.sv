`include "Definitions.sv"

module Control_FSM(
    input   logic           i_clk,
    input   logic           i_rstn,
    input   logic [31:0]    i_instruction,  // instruction word (opcode + operands)
    output  logic [5:0]     o_counter,      //sync counter

    output  logic [3:0]     o_state,
    
    output  logic           o_FSM_ready     //ready signal for next instruction to be sent
    
    
);

    // ───────────────────────────────────────────────
    // State encoding
    // ───────────────────────────────────────────────
    logic   [3:0]           next_state;


    // ───────────────────────────────────────────────
    // Counter Logic
    // ───────────────────────────────────────────────
    logic   [5:0]           counter;
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
                case(i_instruction[6:0])
                    `OP_LOAD:   next_state = `DATA_FETCH;
                    `OP_R_TYPE:  next_state = `R_EXECUTE;
                    `OP_STORE: next_state = `STORE_DATA;
                    `OP_NEWS_TYPE: next_state = `NEWS_EXECUTE;
                    `OP_ABS: next_state = `ABS_A_MSB;
                    default:   next_state = `IDLE;
                endcase
            end
            
            `DATA_FETCH: begin
                next_state = `MEM_TO_DATA;
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
                if(counter < 6'd31) begin
                    next_state = `NEWS_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `STORE_DATA: begin
                if(counter < 6'd31) begin
                    next_state = `STORE_DATA; 
                end else begin
                    next_state = `DATA_TO_MEM;
                end
            end
            
            `DATA_TO_MEM: begin         //sends accumulated 32bit data from SIPO to memory
                next_state = `IDLE;
            end
            
            `MEM_TO_DATA: begin
                next_state = `DATA_LOAD;
            end
            
            
            `ABS_A_MSB: begin
                next_state = `ABS_A1;
            end
            
            `ABS_A1:begin
                next_state = `ABS_A;
            end
            
            `ABS_A: begin
                if(counter < 6'd31) begin
                    next_state = `ABS_A; 
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
	            o_state == `NEWS_EXECUTE ||o_state == `STORE_DATA ||o_state == `ABS_A || o_state == `ABS_A1) begin
	               counter <= counter + 1;
	end else begin
	   counter <= 6'b0;
	end
end

assign o_FSM_ready = (o_state == `IDLE) ? 1 : 0;

endmodule

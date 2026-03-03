`include "Definitions.sv"

module Control_FSM#(
    parameter int DATA_WIDTH
    )(
    input   logic           i_clk,
    input   logic           i_rstn,
    input   logic [6:0]     i_opcode,  // instruction word (opcode + operands)
    
    //Instruction Handshaking
    input logic             i_instr_valid,
    
    output  logic [$clog2(DATA_WIDTH):0]     o_counter,      //sync counter

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
    logic   [$clog2(DATA_WIDTH):0]           counter;
    assign o_counter = counter;    


//Handshaking Latch
// In Control_FSM, add an internal latch
    logic instr_valid_latched;
    
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn)
            instr_valid_latched <= 0;
        else if (i_instr_valid && o_state == `IDLE)
            instr_valid_latched <= 1;  // latch on first detection
        else
            instr_valid_latched <= 0;  // clear immediately after
    end



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
                if(instr_valid_latched) begin
                    case(i_opcode)
                        `OP_LOAD:   next_state = `DATA_FETCH;
                        `OP_R_TYPE:  next_state = `R_EXECUTE;
                        `OP_STORE: next_state = `STORE_DATA;
                        `OP_NEWS_TYPE: next_state = `NEWS_EXECUTE;
                        `OP_ABS: next_state = `ABS_A_MSB;
                        default:   next_state = `IDLE;
                    endcase
                end else begin
                    next_state = `IDLE;
                end
            end
            
            `DATA_FETCH: begin
                next_state = `MEM_TO_DATA;
            end

            `DATA_LOAD: begin
                if(counter < DATA_WIDTH - 1) begin
                    next_state = `DATA_LOAD; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `R_EXECUTE: begin
                if(counter < DATA_WIDTH - 1) begin
                    next_state = `R_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end
            
            `NEWS_EXECUTE: begin    //
                if(counter < DATA_WIDTH - 1) begin
                    next_state = `NEWS_EXECUTE; // fallback
                end else begin
                    next_state = `IDLE;
                end
            end

            `STORE_DATA: begin
                if(counter < DATA_WIDTH - 1) begin
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
                if(counter < DATA_WIDTH - 1) begin
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
		counter <= '0;
	end else if(o_state == `DATA_LOAD ||o_state == `R_EXECUTE ||
	            o_state == `NEWS_EXECUTE ||o_state == `STORE_DATA ||o_state == `ABS_A || o_state == `ABS_A1) begin
	               counter <= counter + 1;
	end else begin
	   counter <= '0;
	end
end

assign o_FSM_ready = (o_state == `IDLE) & (next_state == `IDLE);

endmodule

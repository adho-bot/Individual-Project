module Control_FSM(
    input  logic        i_clk,
    input  logic        i_rstn,
    input  logic [31:0] i_instruction,  // instruction word (opcode + operands)

    // decoded instruction type flags (from decoder module ideally)
    input  logic is_mem,      // LOAD / STORE
    input  logic is_alu,      // ADD / SUB / CMP
    input  logic is_comm,     // MOVE_N / MOVE_S / MOVE_E / MOVE_W
    input  logic is_ctrl,     // BRANCH, HALT
    input  logic is_halt,     // HALT instruction detected

    // status flags
    input  logic all_pe_done, // from PE array, indicates all PEs completed execution

    output logic [3:0] state  // current FSM state for observation / debug
);

    // ───────────────────────────────────────────────
    // State encoding
    // ───────────────────────────────────────────────
    typedef enum logic [3:0] {
        RESET       = 4'b0000,
        FETCH       = 4'b0001,
        DECODE      = 4'b0010,
        MEM_ACCESS  = 4'b0011,
        BROADCAST   = 4'b0100,
        EXECUTE     = 4'b0101,
        COMM_EXEC   = 4'b0110,
        CTRL_FLOW   = 4'b0111,
        SYNC        = 4'b1000,
        NEXT        = 4'b1001,
        HALT        = 4'b1010
    } state_t;

    state_t current_state, next_state;

    // ───────────────────────────────────────────────
    // Sequential block - state register
    // ───────────────────────────────────────────────
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end

    // ───────────────────────────────────────────────
    // Combinational block - next state logic
    // ───────────────────────────────────────────────
    always_comb begin
        // Default
        next_state = current_state;

        case (current_state)

            RESET: begin
                next_state = FETCH;
            end

            FETCH: begin
                next_state = DECODE;
            end

            DECODE: begin
                if (is_mem)       next_state = MEM_ACCESS;
                else if (is_alu)  next_state = BROADCAST;
                else if (is_comm) next_state = COMM_EXEC;
                else if (is_ctrl) next_state = CTRL_FLOW;
                else if (is_halt) next_state = HALT;
                else              next_state = FETCH; // fallback
            end

            MEM_ACCESS: begin
                next_state = BROADCAST;
            end

            BROADCAST: begin
                next_state = EXECUTE;
            end

            EXECUTE: begin
                next_state = SYNC;
            end

            COMM_EXEC: begin
                next_state = SYNC;
            end

            CTRL_FLOW: begin
                next_state = NEXT;
            end

            SYNC: begin
                if (all_pe_done)
                    next_state = NEXT;
                else
                    next_state = SYNC;
            end

            NEXT: begin
                if (is_halt)
                    next_state = HALT;
                else
                    next_state = FETCH;
            end

            HALT: begin
                next_state = HALT;
            end

            default: begin
                next_state = RESET;
            end

        endcase
    end

    // ───────────────────────────────────────────────
    // Output assignment
    // ───────────────────────────────────────────────
    assign state = current_state;

endmodule

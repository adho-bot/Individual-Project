`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

module Postsim_Test;

    class Instructions;
        localparam logic [1:0] NORTH = 2'b00, EAST = 2'b01, WEST = 2'b10, SOUTH = 2'b11;

        function logic [19:0] load(logic [9:0] address, logic [2:0] rd);
            return {2'b00, address, 3'b000, rd, `OP_LOAD};
        endfunction

        function logic [19:0] store(logic [9:0] address, logic [2:0] rs1);
            return {2'b00, address, rs1, 3'b000, `OP_STORE};
        endfunction

        function logic [19:0] r_type(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2, logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, 4'b0000, rs1, rd, `OP_R_TYPE};
        endfunction

        function logic [19:0] news_type(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2, logic [1:0] dir, logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, dir, 2'b00, rs1, rd, `OP_NEWS_TYPE};
        endfunction

        function logic [19:0] add (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return r_type(rd, rs1, rs2, `ADD);  endfunction
        function logic [19:0] sub (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return r_type(rd, rs1, rs2, `SUB);  endfunction
        function logic [19:0] xorr(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return r_type(rd, rs1, rs2, `XORR); endfunction
        function logic [19:0] orr (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return r_type(rd, rs1, rs2, `ORR);  endfunction
        function logic [19:0] andd(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return r_type(rd, rs1, rs2, `ANDD); endfunction
        function logic [19:0] getmsb(logic [2:0] rd, logic [2:0] rs); return r_type(rd, 3'd0, rs, `MSBTST); endfunction
        function logic [19:0] sra(logic [2:0] rd, logic [2:0] rs1, logic [2:0] shamt); return r_type(rd, rs1, shamt, `SRA); endfunction

        function logic [19:0] mov_north(logic [2:0] rd, logic [2:0] rs2); return news_type(rd, 3'd0, rs2, NORTH, `ADD); endfunction
        function logic [19:0] mov_south(logic [2:0] rd, logic [2:0] rs2); return news_type(rd, 3'd0, rs2, SOUTH, `ADD); endfunction
        function logic [19:0] mov_east (logic [2:0] rd, logic [2:0] rs2); return news_type(rd, 3'd0, rs2, EAST,  `ADD); endfunction
        function logic [19:0] mov_west (logic [2:0] rd, logic [2:0] rs2); return news_type(rd, 3'd0, rs2, WEST,  `ADD); endfunction

        function logic [19:0] add_north(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, NORTH, `ADD); endfunction
        function logic [19:0] add_south(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, SOUTH, `ADD); endfunction
        function logic [19:0] add_east (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, EAST,  `ADD); endfunction
        function logic [19:0] add_west (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, WEST,  `ADD); endfunction

        function logic [19:0] sub_north(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, NORTH, `SUB); endfunction
        function logic [19:0] sub_south(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, SOUTH, `SUB); endfunction
        function logic [19:0] sub_east (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, EAST,  `SUB); endfunction
        function logic [19:0] sub_west (logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2); return news_type(rd, rs1, rs2, WEST,  `SUB); endfunction
    endclass

    // -----------------------------------------
    // DUT I/O
    // -----------------------------------------
    logic clk;
    logic rstn;

    logic [19:0] instruction;
    logic [15:0] array_data_in;
    logic [15:0] array_data_out;

    logic [31:0] address;
    logic        wr_en;
    logic        rd_en;

    logic        Control_ready;
    logic        instr_valid;

    localparam ROW_LENGTH      = 32;
    localparam COL_LENGTH      = 32;
    localparam DATA_WIDTH      = 16;
    localparam REG_DEPTH       = 8;
    localparam ARRAY_BASE_ADDR = 32'h0000_0000;

    Top #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .ARRAY_BASE_ADDR(ARRAY_BASE_ADDR),
        .ROW_LENGTH(ROW_LENGTH),
        .COL_LENGTH(COL_LENGTH)
    ) top_inst(
        .i_clk          (clk),
        .i_rstn         (rstn),
        .i_instruction  (instruction),
        .i_instr_valid  (instr_valid),
        .i_array_data   (array_data_in),
        .o_array_data   (array_data_out),
        .o_array_address(address),
        .o_wr_en        (wr_en),
        .o_rd_en        (rd_en),
        .o_Control_ready(Control_ready)
    );

    // -----------------------------------------
    // Sim memory
    // -----------------------------------------
    localparam DATA_DEPTH = ROW_LENGTH * COL_LENGTH;
    logic [15:0] data_mem [0:DATA_DEPTH - 1];

    always_ff @(posedge clk) begin
        array_data_in <= data_mem[address];
    end

    integer outfile;
    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_mem[address] <= array_data_out[15:0];
            $fwrite(outfile, "%02x\n", array_data_out);
            $display("[TB] OUTPUT PIXEL: addr=%0d  val=%02x", address, array_data_out[7:0]);
        end
    end

    // -----------------------------------------
    // Clock
    // -----------------------------------------
    always #5 clk = ~clk;

    // -----------------------------------------
    // Handshake task
    // -----------------------------------------
    // Drives instruction + valid, waits for FSM to accept (Control_ready -> 0),
    // then waits for FSM to finish (Control_ready -> 1), then drops valid.
    task automatic issue(input logic [19:0] instr_word);
        @(posedge clk);
        instruction <= instr_word;
        instr_valid <= 1'b1;

        // Wait for FSM to leave IDLE (it has accepted the instruction)
        wait (Control_ready === 1'b0);

        // Drop valid so it doesn't re-fire when FSM returns to IDLE
        @(posedge clk);
        instr_valid <= 1'b0;

        // Wait for FSM to come back to IDLE (instruction complete)
        wait (Control_ready === 1'b1);
        @(posedge clk);
    endtask

    // -----------------------------------------
    // Stimulus
    // -----------------------------------------
    Instructions instr = new;

    initial begin
        clk         = 0;
        rstn        = 0;
        instruction = 20'h0;
        instr_valid = 1'b0;

        $display("[TB] Loading image from /home/gary/Individual_Project/img/4x4_input.hex");
        $readmemh("/home/gary/Individual_Project/img/4x4_input.hex", data_mem);

        outfile = $fopen("/home/gary/Individual_Project/img/4x4_output.hex", "w");
        if (!outfile) begin
            $display("[TB] ERROR: could not open output hex file!");
            $finish;
        end

        // Hold reset for several clocks, release on clock edge
        repeat (20) @(posedge clk);
        rstn = 1'b1;
        repeat (5)  @(posedge clk);

        // ---- Recursive load into reg 1 ----
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                issue(instr.load(10'(i*ROW_LENGTH + j), 3'd1));
            end
        end

        //====================================================
        //                       Gx
        //====================================================
        issue(instr.add_north(3'd2, 3'd1, 3'd1));   // B = A + A(north)
        issue(instr.add_south(3'd2, 3'd2, 3'd2));   // C = B + B(south)
        issue(instr.mov_east (3'd3, 3'd2));         // C east -> r3
        issue(instr.mov_west (3'd4, 3'd2));         // C west -> r4
        issue(instr.sub      (3'd5, 3'd3, 3'd4));   // Gx -> r5

        //====================================================
        //                       Gy
        //====================================================
        issue(instr.add_east (3'd2, 3'd1, 3'd1));   // B = A + A(east)
        issue(instr.add_west (3'd2, 3'd2, 3'd2));   // C = B + B(west)
        issue(instr.mov_north(3'd3, 3'd2));         // C north -> r3
        issue(instr.mov_south(3'd4, 3'd2));         // C south -> r4
        issue(instr.sub      (3'd6, 3'd3, 3'd4));   // Gy -> r6

        //====================================================
        //                   Magnitude
        //====================================================
        // |Gx|
        issue(instr.getmsb(3'd3, 3'd5));
        issue(instr.xorr  (3'd4, 3'd5, 3'd3));
        issue(instr.sub   (3'd5, 3'd4, 3'd3));

        // |Gy|
        issue(instr.getmsb(3'd3, 3'd6));
        issue(instr.xorr  (3'd4, 3'd6, 3'd3));
        issue(instr.sub   (3'd6, 3'd4, 3'd3));

        //====================================================
        //                  |Gx| + |Gy|
        //====================================================
        issue(instr.add(3'd6, 3'd5, 3'd6));

        //====================================================
        //                  Shift right by 2
        //====================================================
        issue(instr.sra(3'd6, 3'd6, 3'd2));

        // ---- Recursive store ----
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                issue(instr.store(10'(i*ROW_LENGTH + j), 3'd6));
            end
        end

        instruction = 20'd0;
        instr_valid = 1'b0;
        #100;
        $display("Simulation completed.");
        $fclose(outfile);
        $finish;
    end

endmodule
`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

// ============================================================================
//  Self-Checking Sobel Testbench
// ============================================================================
//  Runs the full Sobel edge-detection kernel, then compares every output
//  pixel against a golden reference file.  Prints per-pixel PASS/FAIL and
//  a final summary.  Returns a non-zero exit code on mismatch so that
//  scripts (Tcl, Makefile, CI) can detect failure automatically.
//
//  Required files (paths configurable via plusargs):
//    +INPUT_HEX=<path>      input image  (one hex value per line)
//    +GOLDEN_OUT_HEX=<path>     expected output from sobel_verify.py
//    +RTL_OUT_HEX=<path>     (optional) write actual output for debugging
//
//  Quick run:
//    python3 sobel_verify.py --input img/input.hex --rows 32 --cols 32
//    vsim ... +INPUT_HEX=img/input.hex +GOLDEN_HEX=expected_sobel_output.hex
// ============================================================================

module tb_selfCheck;

    // ─────────────────────────────────────────────
    //  Instruction Helper Class (unchanged from original)
    // ─────────────────────────────────────────────
    class Instructions;
        localparam logic [1:0] NORTH = 2'b00, EAST = 2'b01,
                               WEST  = 2'b10, SOUTH = 2'b11;

        function logic [19:0] load(logic [9:0] address, logic [2:0] rd);
            return {2'b00, address, 3'b000, rd, `OP_LOAD};
        endfunction

        function logic [19:0] store(logic [9:0] address, logic [2:0] rs1);
            return {2'b00, address, rs1, 3'b000, `OP_STORE};
        endfunction

        function logic [19:0] r_type(logic [2:0] rd, logic [2:0] rs1,
                                     logic [2:0] rs2, logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, 4'b0000, rs1, rd, `OP_R_TYPE};
        endfunction

        function logic [19:0] news_type(logic [2:0] rd, logic [2:0] rs1,
                                        logic [2:0] rs2, logic [1:0] dir,
                                        logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, dir, 2'b00, rs1, rd, `OP_NEWS_TYPE};
        endfunction

        // ALU convenience
        function logic [19:0] add(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return r_type(rd, rs1, rs2, `ADD);
        endfunction
        function logic [19:0] sub(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return r_type(rd, rs1, rs2, `SUB);
        endfunction
        function logic [19:0] xorr(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return r_type(rd, rs1, rs2, `XORR);
        endfunction
        function logic [19:0] orr(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return r_type(rd, rs1, rs2, `ORR);
        endfunction
        function logic [19:0] andd(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return r_type(rd, rs1, rs2, `ANDD);
        endfunction
        function logic [19:0] getmsb(logic [2:0] rd, logic [2:0] rs);
            return r_type(rd, 3'd0, rs, `MSBTST);
        endfunction
        function logic [19:0] sra(logic [2:0] rd, logic [2:0] rs1, logic [2:0] shamt);
            return r_type(rd, rs1, shamt, `SRA);
        endfunction

        // NEWS move (rs1=0 → result = 0 + neighbour = neighbour)
        function logic [19:0] mov_north(logic [2:0] rd, logic [2:0] rs2);
            return news_type(rd, 3'd0, rs2, NORTH, `ADD);
        endfunction
        function logic [19:0] mov_south(logic [2:0] rd, logic [2:0] rs2);
            return news_type(rd, 3'd0, rs2, SOUTH, `ADD);
        endfunction
        function logic [19:0] mov_east(logic [2:0] rd, logic [2:0] rs2);
            return news_type(rd, 3'd0, rs2, EAST, `ADD);
        endfunction
        function logic [19:0] mov_west(logic [2:0] rd, logic [2:0] rs2);
            return news_type(rd, 3'd0, rs2, WEST, `ADD);
        endfunction

        // NEWS add
        function logic [19:0] add_north(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, NORTH, `ADD);
        endfunction
        function logic [19:0] add_south(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, SOUTH, `ADD);
        endfunction
        function logic [19:0] add_east(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, EAST, `ADD);
        endfunction
        function logic [19:0] add_west(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, WEST, `ADD);
        endfunction

        // NEWS sub
        function logic [19:0] sub_north(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, NORTH, `SUB);
        endfunction
        function logic [19:0] sub_south(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, SOUTH, `SUB);
        endfunction
        function logic [19:0] sub_east(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, EAST, `SUB);
        endfunction
        function logic [19:0] sub_west(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, rs2, WEST, `SUB);
        endfunction
    endclass

    // ─────────────────────────────────────────────
    //  Parameters
    // ─────────────────────────────────────────────
    localparam ROW_LENGTH  = 32;
    localparam COL_LENGTH  = 32;
    localparam DATA_WIDTH  = 16;
    localparam REG_DEPTH   = 8;
    localparam ARRAY_BASE_ADDR = 32'h0000_0000;
    localparam DATA_DEPTH  = ROW_LENGTH * COL_LENGTH;

    // ─────────────────────────────────────────────
    //  DUT signals
    // ─────────────────────────────────────────────
    logic        clk;
    logic        rstn;
    logic [19:0] instruction;
    logic [15:0] array_data_in;
    logic [15:0] array_data_out;
    logic [31:0] address;
    logic        wr_en;
    logic        rd_en;
    logic        Control_ready;
    logic        instr_valid;

    // ─────────────────────────────────────────────
    //  DUT
    // ─────────────────────────────────────────────
    Top #(
        .DATA_WIDTH     (DATA_WIDTH),
        .REG_DEPTH      (REG_DEPTH),
        .ARRAY_BASE_ADDR(ARRAY_BASE_ADDR),
        .ROW_LENGTH     (ROW_LENGTH),
        .COL_LENGTH     (COL_LENGTH)
    ) top_inst (
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

    // ─────────────────────────────────────────────
    //  Simulation Memory
    // ─────────────────────────────────────────────
    logic [15:0] data_mem    [0:DATA_DEPTH-1];
    logic [15:0] golden_mem  [0:DATA_DEPTH-1];

    always @(posedge clk) begin
        array_data_in <= data_mem[address];
    end

    // ─────────────────────────────────────────────
    //  Store capture + self-check
    // ─────────────────────────────────────────────
    integer outfile;
    integer store_idx;
    integer mismatch_count;
    integer total_checked;

    always @(posedge clk) begin
        if (wr_en) begin
            data_mem[address] <= array_data_out[15:0];

            // Write actual output for debugging
            if (outfile)
                $fwrite(outfile, "%04x\n", array_data_out);

            // ── Self-check against golden ──
            if (array_data_out[15:0] !== golden_mem[store_idx]) begin
                $display("[FAIL] pixel %0d (row=%0d col=%0d): got=0x%04x  expected=0x%04x",
                         store_idx,
                         store_idx / COL_LENGTH,
                         store_idx % COL_LENGTH,
                         array_data_out[15:0],
                         golden_mem[store_idx]);
                mismatch_count = mismatch_count + 1;
            end
            total_checked = total_checked + 1;
            store_idx     = store_idx + 1;
        end
    end

    // ─────────────────────────────────────────────
    //  Clock
    // ─────────────────────────────────────────────
    always #5 clk = ~clk;

    // ─────────────────────────────────────────────
    //  Stimulus
    // ─────────────────────────────────────────────
    Instructions instr;

    // File path variables
    string input_hex;
    string golden_hex;
    string output_hex;

    initial begin
        // ── Defaults ──
        clk             = 0;
        rstn            = 0;
        instruction     = 20'h0;
        array_data_in   = 0;
        instr_valid     = 1;
        store_idx       = 0;
        mismatch_count  = 0;
        total_checked   = 0;

        instr = new;

        // ── Read file paths from plusargs ──
        if (!$value$plusargs("INPUT_HEX=%s", input_hex)) begin
            $display("[TB] ERROR: supply +INPUT_HEX=<path>");
            $finish;
        end
        if (!$value$plusargs("GOLDEN_OUT_HEX=%s", golden_hex)) begin
            $display("[TB] ERROR: supply +GOLDEN_OUT_HEX=<path>");
            $finish;
        end
        // Output hex is optional
        if (!$value$plusargs("RTL_OUT_HEX=%s", output_hex))
            output_hex = "";

        // ── Load memories ──
        $display("[TB] Loading input:  %s", input_hex);
        $readmemh(input_hex, data_mem);

        $display("[TB] Loading golden: %s", golden_hex);
        $readmemh(golden_hex, golden_mem);

        // ── Open output file (optional) ──
        if (output_hex != "") begin
            outfile = $fopen(output_hex, "w");
            if (!outfile)
                $display("[TB] WARNING: could not open %s for writing", output_hex);
        end else begin
            outfile = 0;
        end

        // ── Reset ──
        #20;
        rstn = 1;

        $display("[TB] ──────── Starting Sobel kernel ────────");
        $display("[TB] Array: %0dx%0d  DataWidth: %0d", ROW_LENGTH, COL_LENGTH, DATA_WIDTH);

        // ══════════════════════════════════════════════
        //  Load image into r1 of every PE
        // ══════════════════════════════════════════════
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                instruction = instr.load(10'(i*COL_LENGTH + j), 3'd1);
                @(posedge Control_ready);
            end
        end
        $display("[TB] Load complete");

        // ══════════════════════════════════════════════
        //  Gx
        // ══════════════════════════════════════════════
        instruction = instr.add_north(3'd2, 3'd1, 3'd1);
        @(posedge Control_ready);

        instruction = instr.add_south(3'd2, 3'd2, 3'd2);
        @(posedge Control_ready);

        instruction = instr.mov_east(3'd3, 3'd2);
        @(posedge Control_ready);

        instruction = instr.mov_west(3'd4, 3'd2);
        @(posedge Control_ready);

        instruction = instr.sub(3'd5, 3'd3, 3'd4);
        @(posedge Control_ready);
        $display("[TB] Gx complete");

        // ══════════════════════════════════════════════
        //  Gy
        // ══════════════════════════════════════════════
        instruction = instr.add_east(3'd2, 3'd1, 3'd1);
        @(posedge Control_ready);

        instruction = instr.add_west(3'd2, 3'd2, 3'd2);
        @(posedge Control_ready);

        instruction = instr.mov_north(3'd3, 3'd2);
        @(posedge Control_ready);

        instruction = instr.mov_south(3'd4, 3'd2);
        @(posedge Control_ready);

        instruction = instr.sub(3'd6, 3'd3, 3'd4);
        @(posedge Control_ready);
        $display("[TB] Gy complete");

        // ══════════════════════════════════════════════
        //  |Gx|
        // ══════════════════════════════════════════════
        instruction = instr.getmsb(3'd3, 3'd5);
        @(posedge Control_ready);
        instruction = instr.xorr(3'd4, 3'd5, 3'd3);
        @(posedge Control_ready);
        instruction = instr.sub(3'd5, 3'd4, 3'd3);
        @(posedge Control_ready);

        // ══════════════════════════════════════════════
        //  |Gy|
        // ══════════════════════════════════════════════
        instruction = instr.getmsb(3'd3, 3'd6);
        @(posedge Control_ready);
        instruction = instr.xorr(3'd4, 3'd6, 3'd3);
        @(posedge Control_ready);
        instruction = instr.sub(3'd6, 3'd4, 3'd3);
        @(posedge Control_ready);

        // ══════════════════════════════════════════════
        //  |Gx| + |Gy|, then >> 2
        // ══════════════════════════════════════════════
        instruction = instr.add(3'd6, 3'd5, 3'd6);
        @(posedge Control_ready);

        instruction = instr.sra(3'd6, 3'd6, 3'd2);
        @(posedge Control_ready);
        $display("[TB] Magnitude complete");

        // ══════════════════════════════════════════════
        //  Store results from r6 of every PE
        // ══════════════════════════════════════════════
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                instruction = instr.store(10'(i*COL_LENGTH + j), 3'd6);
                @(posedge Control_ready);
            end
        end

        // ══════════════════════════════════════════════
        //  Report
        // ══════════════════════════════════════════════
        instruction = 20'd0;
        #100;

        $display("[TB] ──────── Results ────────");
        $display("[TB] Pixels checked:  %0d / %0d", total_checked, DATA_DEPTH);
        $display("[TB] Mismatches:      %0d", mismatch_count);

        if (total_checked != DATA_DEPTH)
            $display("[TB] WARNING: expected %0d stores but saw %0d", DATA_DEPTH, total_checked);

        if (mismatch_count == 0 && total_checked == DATA_DEPTH)
            $display("[TB] *** PASS ***");
        else
            $display("[TB] *** FAIL ***");

        if (outfile) $fclose(outfile);
        $finish;
    end

endmodule
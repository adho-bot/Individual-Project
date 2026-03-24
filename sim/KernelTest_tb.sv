`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"
//A B C are the matrix images

//Gx
//B = A + A(north) <- A shifted by 1

//C = B + B(south) 

//D =  C(east) - C(west)


//Gy 
//B = A + A(east) 

//C = B + B(west) 

//D =  C(north) - C(south)


//Compute threshold T (trick to do it without magnitude computation)
//  Add all values together
//divide by 


//D > T or D < -T (then set as 255)
// Else set as 0

//If larger than threshold 

module KernelTest_tb;

    class Instructions;
        localparam logic [1:0] NORTH = 2'b00, EAST = 2'b01, WEST = 2'b10, SOUTH = 2'b11;

        // =====================================================
        //  20-bit aligned encoding
        //  [1:0]   = op
        //  [4:2]   = rd
        //  [7:5]   = rs1
        //  [17:8]  = addr (LOAD/STORE) or {alu_op[17:15], rs2[14:12], ...}
        //  [19:18] = reserved
        // =====================================================

        // --- LOAD: addr[17:8], rs1[7:5]=x, rd[4:2], op=00 ---
        function logic [19:0] load(logic [9:0] address, logic [2:0] rd);
            return {2'b00, address, 3'b000, rd, `OP_LOAD};
        endfunction

        // --- STORE: addr[17:8], rs1[7:5], rd[4:2]=x, op=10 ---
        function logic [19:0] store(logic [9:0] address, logic [2:0] rs1);
            return {2'b00, address, rs1, 3'b000, `OP_STORE};
        endfunction

        // --- R-TYPE: alu_op[17:15], rs2[14:12], rsvd[11:8], rs1[7:5], rd[4:2], op=01 ---
        function logic [19:0] r_type(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2, logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, 4'b0000, rs1, rd, `OP_R_TYPE};
        endfunction

        // --- NEWS: alu_op[17:15], rs2[14:12], dir[11:10], rsvd[9:8], rs1[7:5], rd[4:2], op=11 ---
        function logic [19:0] news_type(logic [2:0] rd, logic [2:0] rs1, logic [2:0] rs2, logic [1:0] dir, logic [2:0] alu_op);
            return {2'b00, alu_op, rs2, dir, 2'b00, rs1, rd, `OP_NEWS_TYPE};
        endfunction

        // --- ALU convenience ---
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

        // --- NEWS move (rs1=0, so result = 0 + neighbour = neighbour) ---
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

        // --- NEWS add ---
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

        // --- NEWS sub ---
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

    // -----------------------------------------
    // DUT I/O declarations
    // -----------------------------------------
    logic clk;
    logic rstn;

    logic [19:0] instruction;
    logic [15:0] array_data_in;
    logic [15:0] array_data_out;

    logic [31:0] address;
    logic        wr_en;
    logic        rd_en;

    logic       Control_ready;
    logic       instr_valid;

    // PROCESSOR CONTROL PARAMETERS
    localparam ROW_LENGTH = 2;
    localparam COL_LENGTH = 2;

    localparam DATA_WIDTH = 16;
    localparam REG_DEPTH = 8;
    localparam ARRAY_BASE_ADDR = 32'h0000_0000;

    // -----------------------------------------
    // Instantiate DUT
    // -----------------------------------------
    Top #(
        .DATA_WIDTH(DATA_WIDTH),
        .REG_DEPTH(REG_DEPTH),
        .ARRAY_BASE_ADDR(ARRAY_BASE_ADDR),
        .ROW_LENGTH(ROW_LENGTH),
        .COL_LENGTH(COL_LENGTH)
    ) top_inst(
        .i_clk        (clk),
        .i_rstn       (rstn),
        .i_instruction(instruction),
        .i_instr_valid(instr_valid),

        .i_array_data (array_data_in),
        .o_array_data (array_data_out),

        .o_array_address(address),
        .o_wr_en      (wr_en),
        .o_rd_en      (rd_en),
        .o_Control_ready(Control_ready)
    );

    // -----------------------------------------
    // Simulation Data Memory
    // -----------------------------------------
    localparam DATA_DEPTH = ROW_LENGTH * COL_LENGTH;

    logic [15:0] data_mem [0:DATA_DEPTH - 1];

    // Memory read
    always_ff @(posedge clk) begin
        array_data_in <= data_mem[address];
    end

    // Memory write + record to file
    integer outfile;
    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_mem[address] <= array_data_out[15:0];
            $fwrite(outfile, "%02x\n", array_data_out);
            $display("[TB] OUTPUT PIXEL: addr=%0d  val=%02x", address, array_data_out[7:0]);
        end
    end

    // -----------------------------------------
    // Clock generation
    // -----------------------------------------
    always #5 clk = ~clk;

    // -----------------------------------------
    // Test Stimulus
    // -----------------------------------------
    Instructions instr = new;

    initial begin
        clk = 0;
        rstn = 0;
        instruction = 20'h0;
        instr_valid = 1;

        $display("[TB] Loading image from /home/gary/Individual_Project/img/4x4_input.hex");
        $readmemh("/home/gary/Individual_Project/img/4x4_input.hex", data_mem);

        outfile = $fopen("/home/gary/Individual_Project/img/4x4_output.hex", "w");
        if (!outfile) begin
            $display("[TB] ERROR: could not open output hex file!");
            $finish;
        end

        #20;
        rstn = 1;

        // Recursive load into reg 1
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                instruction = instr.load(10'(i*ROW_LENGTH + j), 3'd1);
                @(posedge Control_ready);
            end
        end

        //====================================================
        //                           Gx
        //====================================================
        // B = A + A(north)
        instruction = instr.add_north(3'd2, 3'd1, 3'd1);
        @(posedge Control_ready);

        // C = B + B(south)
        instruction = instr.add_south(3'd2, 3'd2, 3'd2);
        @(posedge Control_ready);

        // C east -> r3
        instruction = instr.mov_east(3'd3, 3'd2);
        @(posedge Control_ready);

        // C west -> r4
        instruction = instr.mov_west(3'd4, 3'd2);
        @(posedge Control_ready);

        // Gx = C_east - C_west -> r5
        instruction = instr.sub(3'd5, 3'd3, 3'd4);
        @(posedge Control_ready);

        //====================================================
        //                           Gy
        //====================================================
        // B = A + A(east)
        instruction = instr.add_east(3'd2, 3'd1, 3'd1);
        @(posedge Control_ready);

        // C = B + B(west)
        instruction = instr.add_west(3'd2, 3'd2, 3'd2);
        @(posedge Control_ready);

        // C north -> r3
        instruction = instr.mov_north(3'd3, 3'd2);
        @(posedge Control_ready);

        // C south -> r4
        instruction = instr.mov_south(3'd4, 3'd2);
        @(posedge Control_ready);

        // Gy = C_north - C_south -> r6
        instruction = instr.sub(3'd6, 3'd3, 3'd4);
        @(posedge Control_ready);

        //====================================================
        //                      Magnitude
        //====================================================
        // --- |Gx| ---
        instruction = instr.getmsb(3'd3, 3'd5);
        @(posedge Control_ready);
        instruction = instr.xorr(3'd4, 3'd5, 3'd3);
        @(posedge Control_ready);
        instruction = instr.sub(3'd5, 3'd4, 3'd3);
        @(posedge Control_ready);

        // --- |Gy| ---
        instruction = instr.getmsb(3'd3, 3'd6);
        @(posedge Control_ready);
        instruction = instr.xorr(3'd4, 3'd6, 3'd3);
        @(posedge Control_ready);
        instruction = instr.sub(3'd6, 3'd4, 3'd3);
        @(posedge Control_ready);

        //====================================================
        //                     |Gx| + |Gy|
        //====================================================
        instruction = instr.add(3'd6, 3'd5, 3'd6);
        @(posedge Control_ready);

        //====================================================
        //                     Shift 2 right
        //====================================================
        instruction = instr.sra(3'd6, 3'd6, 3'd2);  // r6 = r6 >> 2
        @(posedge Control_ready);

        // Recursive store
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                instruction = instr.store(10'(i*ROW_LENGTH + j), 3'd6);
                @(posedge Control_ready);
            end
        end

        // -------------------------------------
        // Finish
        // -------------------------------------
        instruction = 20'd0;
        #100;
        $display("Simulation completed.");
        $finish;
    end

endmodule

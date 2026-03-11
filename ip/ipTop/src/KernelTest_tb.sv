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

        // --- Base encoding ---
        function logic [31:0] store(logic [19:0] address, logic [4:0] rs1);
            return {address[19:8], rs1, address[7:0], `OP_STORE};
        endfunction

        function logic [31:0] load(logic [19:0] address, logic [4:0] rd);
            return {address, rd, `OP_LOAD};
        endfunction

        function logic [31:0] vector_R_type(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, logic [6:0] funct7, logic [2:0] funct3);
            return {funct7, rs2, rs1, funct3, rd, `OP_R_TYPE};
        endfunction

        function logic [31:0] news_type(logic [4:0] rd, logic [4:0] rs1, logic [1:0] news_sel, logic [6:0] funct7, logic [2:0] funct3, logic [2:0] rs2);
            return {funct7, news_sel, rs2, rs1, funct3, rd, `OP_NEWS_TYPE};
        endfunction

        // --- ALU ---
        function logic [31:0] add(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return vector_R_type(rd, rs1, rs2, 7'b0000000, 3'b000);
        endfunction

        function logic [31:0] sub(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return vector_R_type(rd, rs1, rs2, 7'b0100000, 3'b000);
        endfunction

        function logic [31:0] xorr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return vector_R_type(rd, rs1, rs2, 7'b0000000, 3'b100);
        endfunction

        function logic [31:0] orr(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return vector_R_type(rd, rs1, rs2, 7'b0000000, 3'b110);
        endfunction

        function logic [31:0] andd(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2);
            return vector_R_type(rd, rs1, rs2, 7'b0000000, 3'b111);
        endfunction

        function logic [31:0] getmsb(logic [4:0] rd, logic [4:0] rs);
            return vector_R_type(rd, 5'd0, rs, 7'b1000000, 3'b000);
        endfunction

        function logic [31:0] sra(logic [4:0] rd, logic [4:0] rs1, logic [4:0] shamt);
            return vector_R_type(rd, rs1, shamt, 7'b0100000, 3'b101);
        endfunction

        // --- NEWS move ---
        function logic [31:0] mov_north(logic [4:0] rd, logic [2:0] rs2);
            return news_type(rd, 5'd0, NORTH, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] mov_south(logic [4:0] rd, logic [2:0] rs2);
            return news_type(rd, 5'd0, SOUTH, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] mov_east(logic [4:0] rd, logic [2:0] rs2);
            return news_type(rd, 5'd0, EAST, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] mov_west(logic [4:0] rd, logic [2:0] rs2);
            return news_type(rd, 5'd0, WEST, 7'b0000000, 3'b000, rs2);
        endfunction

        // --- NEWS add ---
        function logic [31:0] add_north(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, NORTH, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] add_south(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, SOUTH, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] add_east(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, EAST, 7'b0000000, 3'b000, rs2);
        endfunction

        function logic [31:0] add_west(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, WEST, 7'b0000000, 3'b000, rs2);
        endfunction

        // --- NEWS sub ---
        function logic [31:0] sub_north(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, NORTH, 7'b0100000, 3'b000, rs2);
        endfunction

        function logic [31:0] sub_south(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, SOUTH, 7'b0100000, 3'b000, rs2);
        endfunction

        function logic [31:0] sub_east(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, EAST, 7'b0100000, 3'b000, rs2);
        endfunction

        function logic [31:0] sub_west(logic [4:0] rd, logic [4:0] rs1, logic [2:0] rs2);
            return news_type(rd, rs1, WEST, 7'b0100000, 3'b000, rs2);
        endfunction

    endclass

    // -----------------------------------------
    // DUT I/O declarations
    // -----------------------------------------
    logic clk;
    logic rstn;

    logic [31:0] instruction;    
    logic [15:0] array_data_in;
    logic [15:0] array_data_out;

    logic [31:0] address;
    logic        wr_en;
    logic        rd_en;

    logic       Control_ready;
    
    logic       instr_valid;


//PROCESSOR CONTROL PARAMETERS
    localparam ROW_LENGTH = 32;
    localparam COL_LENGTH = 32;
    
    localparam DATA_WIDTH = 16;
    localparam REG_DEPTH = 4;
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
        .i_instr_valid(instr_valid),  //always valid for now (just testing)

        .i_array_data (array_data_in),
        .o_array_data (array_data_out),

        .o_array_address(address),
        .o_wr_en      (wr_en),
        .o_rd_en      (rd_en),
        .o_Control_ready(Control_ready)
    );

    // -----------------------------------------
    // Simulation Data Memory (WORD ADDRESSING TO MIMICK BRAM)
    // -----------------------------------------
    localparam DATA_DEPTH = ROW_LENGTH * COL_LENGTH;
    
    logic [15:0] data_mem [0:DATA_DEPTH - 1];
    //logic [7:0] pix[0:3];
    
    // Memory read
    always_ff @(posedge clk) begin
//        if (rd_en)
            array_data_in <= data_mem[address];
    end

    // Memory write + record to file
    integer outfile;
    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_mem[address]   <= array_data_out[15:0];

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
        instruction = 32'h0;
        array_data_in = 0;
        instr_valid = 1;

        // -------------------------------------
        // Load IMAGE DATA from hex file
        // -------------------------------------


        $display("[TB] Loading image from /home/gary/Individual_Project/img/4x4_input.hex");
        $readmemh("/home/gary/Individual_Project/img/4x4_input.hex", data_mem);
/*
        data_mem[0]  = {24'h0, pix[0]}; // (0,0)
        data_mem[4]  = {24'h0, pix[1]}; // (0,1)
        data_mem[8]  = {24'h0, pix[2]}; // (1,0)
        data_mem[12] = {24'h0, pix[3]}; // (1,1)
*/
        // -------------------------------------
        // Open OUTPUT HEX FILE
        // -------------------------------------
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
                    instruction = instr.load((i*ROW_LENGTH + j), 5'd1);           
                    @(posedge Control_ready);
                end
            end
        
        //====================================================
        //                           Gx        
        //====================================================
                // B = A + A(north)
                instruction = instr.add_north(5'd2, 5'd1, 3'd1);
                @(posedge Control_ready);        
        
                // C = B + B(south)
                instruction = instr.add_south(5'd2, 5'd2, 3'd2);
                @(posedge Control_ready);     
        
                // C east → r3
                instruction = instr.mov_east(5'd3, 3'd2);
                @(posedge Control_ready);         
        
                // C west → r4
                instruction = instr.mov_west(5'd4, 3'd2);
                @(posedge Control_ready);         
        
                // Gx = C_east - C_west → r5
                instruction = instr.sub(5'd5, 5'd3, 5'd4);
                @(posedge Control_ready);  
                                 
        //====================================================
        //                           Gy        
        //====================================================
                // B = A + A(east)
                instruction = instr.add_east(5'd2, 5'd1, 3'd1);
                @(posedge Control_ready);        
        
                // C = B + B(west)
                instruction = instr.add_west(5'd2, 5'd2, 3'd2);
                @(posedge Control_ready);  
        
                // C north → r3
                instruction = instr.mov_north(5'd3, 3'd2);
                @(posedge Control_ready);         
        
                // C south → r4
                instruction = instr.mov_south(5'd4, 3'd2);
                @(posedge Control_ready);         
        
                // Gy = C_north - C_south → r6
                instruction = instr.sub(5'd6, 5'd3, 5'd4);
                @(posedge Control_ready);
        
        //====================================================
        //                      Magnitude        
        //====================================================
                // --- |Gx| ---
                instruction = instr.getmsb(5'd3, 5'd5);
                @(posedge Control_ready);    
                instruction = instr.xorr(5'd4, 5'd5, 5'd3);
                @(posedge Control_ready);           
                instruction = instr.sub(5'd5, 5'd4, 5'd3);
                @(posedge Control_ready);           
        
                // --- |Gy| ---
                instruction = instr.getmsb(5'd3, 5'd6);
                @(posedge Control_ready);    
                instruction = instr.xorr(5'd4, 5'd6, 5'd3);
                @(posedge Control_ready);           
                instruction = instr.sub(5'd6, 5'd4, 5'd3);
                @(posedge Control_ready);    
                
        //====================================================
        //                     |Gx| + |Gy|        
        //====================================================
                instruction = instr.add(5'd6, 5'd5, 5'd6);
                @(posedge Control_ready);
        
                
        //====================================================
        //                     Shift 2 right        
        //====================================================
        instruction = instr.sra(5'd6, 5'd6, 5'd2);  // r6 = r6 >> 2 (divide by 4)
        @(posedge Control_ready);        
        
        
        //Recursive store  
                for (int i = 0; i < ROW_LENGTH; i++) begin
                    for (int j = 0; j < COL_LENGTH; j++) begin
                        instruction = instr.store((i*ROW_LENGTH + j), 5'd6);
                        @(posedge Control_ready);
                    end
                end 
       // -------------------------------------
        // Finish
        // -------------------------------------
        instruction = 32'd0;
        #100;
        $display("Simulation completed."); 
        $finish;
    end

endmodule


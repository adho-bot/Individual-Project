`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

module KernelTest_tb;

    // =========================
    // DUT Signals
    // =========================
    logic        i_clk;
    logic        i_rstn;
    logic [31:0] i_instruction;
    logic        o_Control_ready;

    //PROCESSOR CONTROL PARAMETERS
    localparam INSTR_WIDTH = 32;
    localparam ROW_LENGTH = 2;
    localparam COL_LENGTH = 2;
    
    localparam DATA_WIDTH = 16;
    localparam REG_DEPTH = 8;
    localparam ARRAY_BASE_ADDR = 32'h0000_0000;
    localparam ADDR_BYTES_PER_ELEMENT = DATA_WIDTH / 16;

    //Instruction class
    class Instructions;    
        function logic [INSTR_WIDTH-1:0] store(logic [19:0] address, logic [4:0] rs1);
            return {address[19:8], rs1, address[7:0], `OP_STORE};
        endfunction
    
        function logic [INSTR_WIDTH-1:0] load(logic [19:0] address,logic [4:0] rd);
            return {address, rd, `OP_LOAD};
        endfunction
    
        function logic [INSTR_WIDTH-1:0] vector_R_type(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, logic [6:0] funct7, logic [2:0] funct3);
            return {funct7, rs2, rs1, funct3, rd, `OP_R_TYPE};
        endfunction
    
        function logic [INSTR_WIDTH-1:0] news_type(logic [4:0] rd, logic [4:0] rs1, logic [1:0] news_sel, logic [6:0] funct7, logic [2:0] funct3, logic [2:0] rs2);
            return {funct7, news_sel, rs2, rs1, funct3, rd, `OP_NEWS_TYPE};
        endfunction 

        function logic [INSTR_WIDTH-1:0] abs(logic [4:0] rd, logic [4:0] rs1, logic [6:0] funct7, logic [2:0] funct3);
            return {funct7, 5'b00000, rs1, funct3, rd, `OP_ABS};
        endfunction        
    endclass

    // =========================
    // Instantiate DUT
    // =========================
    BRAM_Top dut (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),
        .o_Control_ready(o_Control_ready)
    );

    // =========================
    // Clock Generation
    // =========================
    always #5 i_clk = ~i_clk; 

    // =========================
    // Test Stimulus
    // =========================
    Instructions instr = new;
   
    initial begin
        i_clk = 0;
        i_rstn = 0;
        i_instruction = 32'h0;

        #100;
        i_rstn = 1;

        // Wait for BRAM init FSM
        #200;
        
//BRAM test
        
        

// Recursive load into reg 1
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                $display("LOAD (%0d,%0d) | Reg 1", i, j);
                i_instruction = instr.load(ADDR_BYTES_PER_ELEMENT * (i*ROW_LENGTH + j), 5'(1));
                @(posedge o_Control_ready);
            end
        end

//================ Gx =================
        i_instruction = instr.news_type(5'd2, 5'd1, 2'b00, 7'd0, 3'd0, 3'd1);
        @(posedge o_Control_ready);        

        i_instruction = instr.news_type(5'd2, 5'd2, 2'b11, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);     

        i_instruction = instr.news_type(5'd3, 5'd0, 2'b01, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);         

        i_instruction = instr.news_type(5'd4, 5'd0, 2'b10, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);         

        i_instruction = instr.vector_R_type(5'd5, 5'd3, 5'd4, 7'b0100000, 3'd0);
        @(posedge o_Control_ready);  

//================ Gy =================
        i_instruction = instr.news_type(5'd2, 5'd1, 2'b01, 7'd0, 3'd0, 3'd1);
        @(posedge o_Control_ready);        

        i_instruction = instr.news_type(5'd2, 5'd2, 2'b10, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);  

        i_instruction = instr.news_type(5'd3, 5'd0, 2'b00, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);         

        i_instruction = instr.news_type(5'd4, 5'd0, 2'b11, 7'd0, 3'd0, 3'd2);
        @(posedge o_Control_ready);         

        i_instruction = instr.vector_R_type(5'd6, 5'd3, 5'd4, 7'b0100000, 3'd0);
        @(posedge o_Control_ready);

//================ Magnitude =================
        i_instruction = instr.abs(5'd5, 5'd5, 7'b0100000, 3'b001);
        @(posedge o_Control_ready); 
        
        i_instruction = instr.abs(5'd6, 5'd6, 7'b0100000, 3'b001);
        @(posedge o_Control_ready);         

//================ Add =================
        i_instruction = instr.vector_R_type(5'd6, 5'd5, 5'd6, 7'b0000000, 3'd0);
        @(posedge o_Control_ready);

// Recursive store  
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                $display("STORE (%0d,%0d) | Reg 6", i, j);
                i_instruction = instr.store(ADDR_BYTES_PER_ELEMENT * (i*ROW_LENGTH + j), 5'd6);
                @(posedge o_Control_ready);
            end
        end        

        i_instruction = 32'd0;
        #100;
        $display("Simulation completed."); 
        $finish;
    end

endmodule
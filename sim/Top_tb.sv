`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

module Top_tb;

    // -----------------------------------------
    // DUT I/O declarations
    // -----------------------------------------
    logic clk;
    logic rstn;

    logic [31:0] instruction;     // Assuming 32-bit instruction width
    logic [31:0] array_data_in;   // Data going INTO Top
    logic [31:0] array_data_out;  // Data coming OUT of Top

    logic [31:0] address;         // Memory address from Top
    logic        wr_en;           // Write enable from Top
    logic        rd_en;           // Read enable from Top

    localparam INSTR_WIDTH = 32;

    //Instruction class
    class Instructions;    
        //Store
        function logic [INSTR_WIDTH-1:0] store(logic [19:0] address, logic [4:0] rs1);
            store = {address[19:8], rs1, address[7:0], `OP_STORE}; // Example RISC-V store encoding
        endfunction
    
        //Load
        function logic [INSTR_WIDTH-1:0] load(logic [19:0] address,logic [4:0] rd);
            load = {address, rd, `OP_LOAD}; // Example RISC-V load encoding
        endfunction
    
        //Vector R-type
        function logic [INSTR_WIDTH-1:0] vector_R_type(logic [4:0] rd, logic [4:0] rs1, logic [4:0] rs2, logic [6:0] funct7, logic [2:0] funct3);
            vector_R_type = {funct7, rs2, rs1, funct3, rd, `OP_R_TYPE}; // Example vector opcode
        endfunction
    
        //NEWS Type
        function logic [INSTR_WIDTH-1:0] my_type(logic [4:0] rd, logic [4:0] rs1, logic [1:0] news_sel, logic [9:0] funct10, logic [2:0] funct3);
            my_type = {funct10, news_sel, rs1, funct3, rd, `OP_NEWS_TYPE}; // placeholder encoding
        endfunction 
    endclass

    // -----------------------------------------
    // Instantiate DUT
    // -----------------------------------------
    Top top_inst (
        .i_clk        (clk),
        .i_rstn       (rstn),
        .i_instruction(instruction),

        .i_array_data (array_data_in),
        .o_array_data (array_data_out),

        .o_array_address    (address),
        .o_wr_en      (wr_en),
        .o_rd_en      (rd_en)
    );

    // -----------------------------------------
    // Simulation Data Memory
    // -----------------------------------------
    logic [31:0] data_mem [0:255];     // 256-word memory

    // Memory read
    always_ff @(posedge clk) begin
        if (rd_en) begin
            array_data_in <= data_mem[address];
        end
    end

    // Memory write
    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_mem[address] <= array_data_out;
        end
    end

    // -----------------------------------------
    // Clock generation
    // -----------------------------------------
    always #5 clk = ~clk;

    // -----------------------------------------
    // Test Stimulus
    // -----------------------------------------
   
    //Object init
    Instructions instr = new;
   
    initial begin
        clk = 0;
        rstn = 0;
        instruction = 32'h0;
        array_data_in = 0;

        // Initialize memory with some values
        data_mem[0] = 32'hAAAA0001;
        data_mem[4] = 32'hBBBB0002;
        data_mem[8] = 32'hCCCC0003;
        data_mem[12] = 32'hDDDD004;
        #20;
        rstn = 1;

        // -------------------------------------
        // Example Instruction 1
        // -------------------------------------
        $display("TEST: Read data from memory address 1");
        instruction = instr.load(20'd4,5'd1);    // REMEMBER MEM OP HAVE TO BE MUTIPLE OF 
        #100;

        

        // -------------------------------------
        // Finish
        // -------------------------------------
        #100;
        $display("Simulation completed.");
        $finish;
    end

endmodule

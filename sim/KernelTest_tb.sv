`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

//A B C are the matrix images
//divide by 2 in each stage

//B = A + A(north) <- A shifted by 1

//C = B + B(south) 


//D =  C(east) - C(west)


//Compute threshold T (trick to do it without magnitude computation)
//  Add all values together
//divide by 


//D > T or D < -T (then set as 255)
// Else set as 0

//If larger than threshold 

module KernelTest_tb;

    // -----------------------------------------
    // DUT I/O declarations
    // -----------------------------------------
    logic clk;
    logic rstn;

    logic [31:0] instruction;    
    logic [31:0] array_data_in;
    logic [31:0] array_data_out;

    logic [31:0] address;
    logic        wr_en;
    logic        rd_en;

    logic       Control_ready;

    localparam INSTR_WIDTH = 32;
    localparam ROW_LENGTH = 16;
    localparam COL_LENGTH = 16;

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
    endclass

    // -----------------------------------------
    // Instantiate DUT
    // -----------------------------------------
    Top #(
        .THRESH(0.2)
    ) top_inst(
        .i_clk        (clk),
        .i_rstn       (rstn),
        .i_instruction(instruction),

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
    localparam DATA_DEPTH = ROW_LENGTH * COL_LENGTH * 8;
    
    logic [7:0] data_mem [0:DATA_DEPTH - 1];
    //logic [7:0] pix[0:3];
    
    // Memory read
    always_ff @(posedge clk) begin
        if (rd_en)
            array_data_in <= {data_mem[address+3],
                              data_mem[address+2],
                              data_mem[address+1],
                              data_mem[address]};
    end

    // Memory write + record to file
    integer outfile;
    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_mem[address[9:0]]   <= array_data_out[7:0];
            data_mem[address[9:0]+1] <= array_data_out[15:8];
            data_mem[address[9:0]+2] <= array_data_out[23:16];
            data_mem[address[9:0]+3] <= array_data_out[31:24];


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

// news_type rd, 

//Recursive load into reg 1
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                    $display("LOAD (%0d,%0d) | Reg %0d", i, j, 1);
                    instruction = instr.load(20'd4 * (i*ROW_LENGTH + j), 5'(1));
                    @(posedge Control_ready);
            end
        end
                         
        $display("====================================");
        $display("            B = A + A North         ");
        $display("====================================");
       
        $display("Vector NEWS | Move image up and add with A| Store B into 2");
        instruction = instr.news_type(5'd2, 5'd1, 2'b00, 7'd0, 3'd0, 3'd1);
        @(posedge Control_ready);        
    
        $display("====================================");
        $display("            C = B + B South         ");
        $display("====================================");
        
        $display("Vector NEWS | Move img down and add with B | Store C into 3");
        instruction = instr.news_type(5'd3, 5'd1, 2'b11, 7'd0, 3'd0, 3'd1);
        @(posedge Control_ready);     
        
        $display("====================================");
        $display("                C east              ");
        $display("====================================");
        
        $display("Vector NEWS | Move reg 3 to the east | Store C into 4");
        instruction = instr.news_type(5'd4, 5'd0, 2'b01, 7'd0, 3'd0, 3'd3);
        @(posedge Control_ready);         

        $display("====================================");
        $display("                C west              ");
        $display("====================================");
        
        $display("Vector NEWS | Move reg 3 to the west | Store C into 5");
        instruction = instr.news_type(5'd5, 5'd0, 2'b10, 7'd0, 3'd0, 3'd3);
        @(posedge Control_ready);         
 
        $display("====================================");
        $display("           C west - C east          ");
        $display("====================================");

        $display("Vector Sub | Add rs6 <- rs4 - rs5");
        instruction = instr.vector_R_type(5'd6, 5'd4, 5'd5, 7'b0100000, 3'd0);
        @(posedge Control_ready);  


//Recursive store  
        for (int i = 0; i < ROW_LENGTH; i++) begin
            for (int j = 0; j < COL_LENGTH; j++) begin
                $display("STORE (%0d,%0d) | Reg 3", i, j);
                instruction = instr.store(20'd4 * (i*ROW_LENGTH + j), 5'd6);
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


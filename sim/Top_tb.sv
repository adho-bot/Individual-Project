`timescale 1ns/1ps
`include "/home/gary/Individual_Project/rtl/Definitions.sv"

//A B C are the matrix images


//B = A + A(north) <- A shifted by 1
//C = B + B(south) 


//D =  C(east) - C(west)



module Top_tb;

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

    //Instruction class
    class Instructions;    
        function logic [INSTR_WIDTH-1:0] store(logic [19:0] address, logic [4:0] rs1);
            store = {address[19:8], rs1, address[7:0], `OP_STORE};
        endfunction
    
        function logic [INSTR_WIDTH-1:0] load(logic [19:0] address,logic [4:0] rd);
            load = {address, rd, `OP_LOAD};
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
    Top top_inst (
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
    logic [7:0] data_mem [0:255];
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
            data_mem[address] <= array_data_out;

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

        $display("====================================");
        $display("              LOAD TYPES            ");
        $display("====================================");
/*        
        $display("LOAD (0,0) | Reg 1");
        instruction = instr.load(20'd0,5'd1);
        @(posedge Control_ready);

        $display("LOAD (0,0) | Reg 2");
        instruction = instr.load(20'd0,5'd2);
        @(posedge Control_ready);

        $display("LOAD (0,1) | Reg 1");
        instruction = instr.load(20'd4,5'd1);
        @(posedge Control_ready);

        $display("LOAD (0,1) | Reg 2");
        instruction = instr.load(20'd4,5'd2);
        @(posedge Control_ready);
        
        $display("LOAD (1,0)");
        instruction = instr.load(20'd8,5'd1);
        @(posedge Control_ready);

        $display("LOAD (1,0)");
        instruction = instr.load(20'd8,5'd2);
        @(posedge Control_ready);
        
        $display("LOAD (1,1)");
        instruction = instr.load(20'd12,5'd1);
        @(posedge Control_ready);     
        
        $display("LOAD (1,1)");
        instruction = instr.load(20'd12,5'd2);
        @(posedge Control_ready);
*/

//Recursive load loop
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                for (int reg_num = 1; reg_num <= 2; reg_num++) begin
                    $display("LOAD (%0d,%0d) | Reg %0d", i, j, reg_num);
                    instruction = instr.load(20'd4 * (i*4 + j), 5'(reg_num));
                    @(posedge Control_ready);
                end
            end
        end
                          
        $display("====================================");
        $display("              R TYPES               ");
        $display("====================================");
        
        $display("Vector ADD | Add rs3 <- rs1 + rs2");
        instruction = instr.vector_R_type(5'd3, 5'd1, 5'd2, 7'd0, 3'd0);
        @(posedge Control_ready);       
        /*
        $display("====================================");
        $display("              NEWS TYPES            ");
        $display("====================================");
        
        $display("Vector NEWS | Move rs2 data east. Add with rs1 of east PE and store in rs3");
        instruction = instr.news_type(5'd3, 5'd1, 2'b01, 7'd0, 3'd0, 3'd2);
        @(posedge Control_ready);         
        */
        $display("====================================");
        $display("              STORE TYPES           ");
        $display("====================================");
/*        
        $display("STORE (0,0) | Reg 3");
        instruction = instr.store(20'd0, 2'd3);
        @(posedge Control_ready);

        $display("STORE (0,1) | Reg 3");
        instruction = instr.store(20'd4, 2'd3);
        @(posedge Control_ready);
        
        $display("STORE (1,0) | Reg 3");
        instruction = instr.store(20'd8, 2'd3);
        @(posedge Control_ready);
        
        $display("STORE (1,1) | Reg 3");
        instruction = instr.store(20'd12, 2'd3);
        @(posedge Control_ready);  
*/       
  
//Recursive store  
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                $display("STORE (%0d,%0d) | Reg 3", i, j);
                instruction = instr.store(20'd4 * (i*4 + j), 2'd3);
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

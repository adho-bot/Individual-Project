module System_Top(
    input logic         i_clk,
    input logic         i_rstn,
    input logic [31:0]  i_cpu_address,  //address from cpu
    input logic [31:0]  i_cpu_rd_en,    //read enable from cpu
    input logic [31:0]  i_cpu_wr_en,    //write enable from cpu
    input logic [31:0]  i_cpu_wdata,    //data from cpu
    output logic [31:0] i_cpu_rdata,    //data from mem to cpu
    input logic [31:0]  i_instruction
);

    logic        wr_en;
    logic        rd_en;


    // Instantiate Array + Array control top module
    Top top_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),

        // Data Memory interface
        .i_address(i_cpu_address),
        
        
        
        .o_wr_en(wr_en),//from array read enable
        .o_rd_en(rd_en) //from array write enable

    );

    // Instantiate Data_Memory module
    Data_Memory data_mem (
        .i_clk(i_clk),
        .i_address(i_cpu_address),
        .i_data(i_cpu_wdata),                   
        .i_wr_en(wr_en),
        .i_rd_en(rd_en),
        .i_cpu_wr_en(i_cpu_wr_en),
        .i_cpu_rd_en(i_cpu_rd_en),        
        .o_data(i_cpu_rdata)
    );

endmodule

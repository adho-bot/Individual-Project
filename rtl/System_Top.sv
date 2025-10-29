module System_Top(
    input logic i_clk,
    input logic i_rstn
);

    // CPU / Top module signals
    logic i_instruction;

    logic [31:0] cpu_address;
    logic [31:0] cpu_wdata;
    logic [31:0] cpu_rdata;
    logic        cpu_wr;
    logic        cpu_rd;

    // Array signals
    logic [31:0] array_addr;
    logic        array_access;
    logic [31:0] array_wdata;
    logic [31:0] array_rdata;
    logic        array_wr;
    logic        array_rd;

    // Instantiate Top module
    Top top_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),

        // Data Memory interface
        .address(cpu_address),
        .dataIn(cpu_rdata),
        .dataOut(cpu_wdata),
        .data_wr(cpu_wr),
        .data_rd(cpu_rd),

        // Array Memory interface
        .array_address(array_addr),
        .array_access(array_access)
    );

    // Instantiate Data_Memory module
    Data_Memory data_mem (
        .i_clk(i_clk),
        .i_address(cpu_address),
        .i_data(cpu_wdata),
        .i_data_wr(cpu_wr),
        .i_data_rd(cpu_rd),
        .o_data(cpu_rdata),
        
        .o_array_access(array_access),
        .o_array_address(array_addr),
        .o_array_wdata(array_wdata),
        .o_array_wr(array_wr),
        .o_array_rd(array_rd),
        .i_array_rdata(array_rdata)
    );

endmodule

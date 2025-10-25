module Top (
    input  logic i_clk,
    input  logic i_rstn
);

    //Data Memory Signals
    logic [31:0] address;
    logic [31:0] dataIn;
    logic [31:0] dataOut;
    logic        data_wr;
    logic        data_rd;

    //Array Memory Signals
    logic [31:0] array_address;
    logic        array_access;

    //Data Memory Instance
    Data_Memory #(
        .MEM_DEPTH(32'h0001_0000) // Example: parameter value written properly
    ) data_mem_inst (
        .i_clk           (i_clk),          // clock
        .i_address       (address),        // memory address
        .i_data          (dataIn),         // data input (to memory)
        .i_data_wr       (data_wr),        // write enable
        .i_data_rd       (data_rd),        // read enable
        .o_data          (dataOut),        // data output (from memory)
        .o_array_access  (array_access),   // array memory-mapped access flag
        .o_array_address (array_address)   // memory-mapped array address
    );

endmodule

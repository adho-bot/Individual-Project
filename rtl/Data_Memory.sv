module Data_Memory #(
    parameter MEM_SIZE = 1024
)(
    input  logic        i_clk,
    input  logic [31:0] i_address,
    input  logic [31:0] i_data,
    input  logic        i_wr_en,
    input  logic        i_rd_en,

    output logic [31:0] o_data
);

    logic [7:0] data_memory [0:MEM_SIZE-1];



    // Normal memory read (only when not array-mapped)
    always_ff @(negedge i_clk) begin
        if (i_rd_en) begin
            o_data <= {data_memory[i_address[9:0]+3],
                       data_memory[i_address[9:0]+2],
                       data_memory[i_address[9:0]+1],
                       data_memory[i_address[9:0]]};
        end
    end

    // Normal memory write (only when not array-mapped)
    always_ff @(negedge i_clk) begin
        if (i_wr_en) begin
            data_memory[i_address[9:0]]   <= i_data[7:0];
            data_memory[i_address[9:0]+1] <= i_data[15:8];
            data_memory[i_address[9:0]+2] <= i_data[23:16];
            data_memory[i_address[9:0]+3] <= i_data[31:24];
        end
    end

endmodule

module Data_Memory #(
    parameter ARRAY_BASE_ADDR = 32'h0001_0000,
    parameter MEM_SIZE = 1024
)(
    input  logic        i_clk,
    input  logic [31:0] i_address,
    input  logic [31:0] i_data,
    input  logic        i_data_wr,
    input  logic        i_data_rd,

    output logic [31:0] o_data,
    
    // Array memory-mapped I/O interface
    output logic        o_array_access,
    output logic [31:0] o_array_address,
    output logic [31:0] o_array_wdata,
    output logic        o_array_wr,
    output logic        o_array_rd,
    input  logic [31:0] i_array_rdata
);

    logic [7:0] data_memory [0:MEM_SIZE-1];

    // Detect if access is to array-mapped address space
    always_comb begin
        o_array_access  = (i_address >= ARRAY_BASE_ADDR);
        o_array_address = i_address;
        o_array_wdata   = i_data;
        o_array_wr      = i_data_wr && o_array_access;
        o_array_rd      = i_data_rd && o_array_access;
    end

    // Normal memory read (only when not array-mapped)
    always_ff @(negedge i_clk) begin
        if (i_data_rd && !o_array_access) begin
            o_data <= {data_memory[i_address[9:0]+3],
                       data_memory[i_address[9:0]+2],
                       data_memory[i_address[9:0]+1],
                       data_memory[i_address[9:0]]};
        end else if (o_array_rd) begin
            o_data <= i_array_rdata; // read data from PE array
        end
    end

    // Normal memory write (only when not array-mapped)
    always_ff @(negedge i_clk) begin
        if (i_data_wr && !o_array_access) begin
            data_memory[i_address[9:0]]   <= i_data[7:0];
            data_memory[i_address[9:0]+1] <= i_data[15:8];
            data_memory[i_address[9:0]+2] <= i_data[23:16];
            data_memory[i_address[9:0]+3] <= i_data[31:24];
        end
    end

endmodule

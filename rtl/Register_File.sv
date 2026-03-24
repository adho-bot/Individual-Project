//Note:
//Pointers are used for reading a full word based on a base register address
// E.g. for 8 registers in a rf, the bit serial RF will have a depth 8*32.
//Words are accessed by having the user choose a base 0,1,2,3,4,5,6,7
//base is multiplied by 32 and added with pointer values(pointer will increement untill a word is extracted(lsb first))
//How do i extract individual bits?

`timescale 1ns/1ps
module Register_File#(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input  logic        i_clk,
    input  logic        i_rstn,

    // serial data input
    input  logic        i_datain,

    // addresses
    input  logic [$clog2(DEPTH)-1:0] i_rs1_addr,
    input  logic [$clog2(DEPTH)-1:0] i_rs2_addr,
    input  logic [$clog2(DEPTH)-1:0] i_rd_addr,

    // control
    input  logic        i_wr_en,
    input  logic [$clog2(WIDTH):0] i_counter,

    // MSB
    input  logic        i_bittst,

    // serial data outputs
    output logic        o_rd1,
    output logic        o_rd2,

    // Shift logic
    input  logic [2:0]  i_shift_amount,
    input  logic        i_sra
);

    // Infer this as distributed RAM
    logic [WIDTH-1:0] rf_mem [0:DEPTH-1];

    // Shift amount
    logic [$clog2(WIDTH):0] shifted_idx;
    assign shifted_idx = i_counter + i_shift_amount;

    // Read words fetched from RAM by register address
    logic [WIDTH-1:0] rd1_word, rd2_word;
    assign rd1_word = rf_mem[i_rs1_addr];
    assign rd2_word = rf_mem[i_rs2_addr];

    // Bit-serial read: select one bit per cycle using counter
    assign o_rd1 = (i_sra) ? rd1_word[(shifted_idx >= WIDTH) ? (WIDTH-1) : shifted_idx[$clog2(WIDTH)-1:0]]
                            : rd1_word[i_counter[$clog2(WIDTH)-1:0]];

    assign o_rd2 = (i_bittst) ? rd2_word[WIDTH-1]
                               : rd2_word[i_counter[$clog2(WIDTH)-1:0]];

    // Write: synchronous, no async reset
    always_ff @(posedge i_clk) begin
        if (i_wr_en && (i_rd_addr != 0)) begin
            rf_mem[i_rd_addr][i_counter[$clog2(WIDTH)-1:0]] <= i_datain;
        end
    end

    // Register 0 is hardwired to zero - initialize once at elaboration
    initial begin
        for (int i = 0; i < DEPTH; i++)
            rf_mem[i] = '0;
    end

endmodule
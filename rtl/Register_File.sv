//Note:
//Pointers are used for reading a full word based on a base register address
// E.g. for 8 registers in a rf, the bit serial RF will have a depth 8*32.
//Words are accessed by having the user choose a base 0,1,2,3,4,5,6,7
//base is multiplied by 32 and added with pointer values(pointer will increement untill a word is extracted(lsb first))
//How do i extract individual bits?


module Register_File#(
    parameter DEPTH,
    parameter WIDTH
)(
    input  logic        i_clk,
    input  logic        i_rstn,

    // serial data input
    input  logic        i_datain,

    // addresses
    input  logic [$clog2(DEPTH)-1:0] i_rd1_addr,
    input  logic [$clog2(DEPTH)-1:0] i_rd2_addr,
    input  logic [$clog2(DEPTH)-1:0] i_wr_addr,

    // control
    input  logic        i_wr_en,
    input  logic        [$clog2(WIDTH):0] i_counter, //global counter shared by all PEs

    //MSB
    input logic         i_bittst,

    // serial data outputs
    output logic        o_rd1,
    output logic        o_rd2
);

    // Register memory
    logic [0:WIDTH * DEPTH-1] rf_mem;

    // Precomputed base addresses - shift instead of multiply (zero LUTs)
    localparam LOG2_WIDTH = $clog2(WIDTH);
    logic [LOG2_WIDTH + $clog2(DEPTH) - 1:0] rd1_base, rd2_base, wr_base;

    always_comb begin
        rd1_base = i_rd1_addr << LOG2_WIDTH;
        rd2_base = i_rd2_addr << LOG2_WIDTH;
        wr_base  = i_wr_addr  << LOG2_WIDTH;
    end

//Write - use global i_counter directly, wr_ptr removed
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            for (int i = 0; i < DEPTH * WIDTH; i++)
                rf_mem[i] <= '0;
        end else if (i_wr_en && (i_wr_addr != 0)) begin
            rf_mem[wr_base + i_counter] <= i_datain;
        end
    end

//Read         
    assign o_rd1 = rf_mem[rd1_base + i_counter]; 
    assign o_rd2 = (i_bittst) ? rf_mem[rd2_base + (WIDTH - 1)] : rf_mem[rd2_base + i_counter];   //change this in the ALU
            
endmodule
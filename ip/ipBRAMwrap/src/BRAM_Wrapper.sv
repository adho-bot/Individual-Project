// ============================================================================
// BRAM_PortB_Wrapper
//
// Sits between Top_0 and blk_mem_gen_0 Port B.
// Handles all signal conversion so Top_0 and the BRAM don't need to know
// about each other's interface details.
//
//  Top_0 Side                  BRAM Port B Side
//  ─────────────────────────   ──────────────────────────
//  o_array_address [31:0]  ──► addrb [31:0]  (word → byte: addr << 2)
//  o_wr_en                 ──► web   [3:0]   (1-bit → 4-bit byte enables)
//  o_rd_en                 ──► (combinational read, no explicit enable on BRAM)
//  o_array_data    [31:0]  ──► dinb  [31:0]  (passthrough)
//  i_array_data    [31:0]  ◄── doutb [31:0]  (passthrough)
// ============================================================================

module BRAM_Wrapper(
    input logic i_clk,
    output logic clkb,

    // --------------------------------
    // Top_0 side
    // --------------------------------
    input  logic [31:0] i_top_addr,       // Word address from Top_0 (o_array_address)
    input  logic        i_top_wr_en,      // Write enable from Top_0  (o_wr_en)
    input  logic        i_top_rd_en,      // Read  enable from Top_0  (o_rd_en)
    input  logic [15:0] i_top_wdata,      // Write data from Top_0    (o_array_data)
    output logic [15:0] o_top_rdata,      // Read data to Top_0       (i_array_data)

    // --------------------------------
    // BRAM Port B side
    // --------------------------------
    output logic [31:0] o_bram_addrb,     // Byte address to BRAM
    output logic [3:0]  o_bram_web,       // Byte-wide write enables
    output logic [31:0] o_bram_dinb,      // Write data to BRAM
    output logic        enb,
    output logic        rstb,
    input  logic [31:0] i_bram_doutb      // Read data from BRAM
);

    // ----------------------------------------------------------------
    // 1. Word → Byte address conversion
    //    Top_0 works in 32-bit word addresses.
    //    blk_mem_gen_0 Port B expects byte addresses.
    //    Each word = 4 bytes, so shift left by 2.
    // ----------------------------------------------------------------
    assign o_bram_addrb = i_top_addr << 2;

    // ----------------------------------------------------------------
    // 2. Write enable expansion
    //    Top_0 asserts a single wr_en bit.
    //    BRAM Port B has a 4-bit byte-enable (web).
    //    Drive all 4 byte lanes when writing a full 32-bit word.
    // ----------------------------------------------------------------
    assign o_bram_web = i_top_wr_en ? 4'b1111 : 4'b0000;

    // ----------------------------------------------------------------
    // 3. Write data passthrough
    //    No conversion needed - both sides are 32-bit.
    // ----------------------------------------------------------------
    assign o_bram_dinb = {16'd0, i_top_wdata};

    // ----------------------------------------------------------------
    // 4. Read data passthrough
    //    BRAM output is registered internally (1-cycle latency).
    //    Pass doutb straight back to Top_0 - Top_0 must account
    //    for the 1-cycle read latency of the BRAM.
    // ----------------------------------------------------------------
    assign o_top_rdata = i_bram_doutb[15:0];
    
    
    assign enb = 1'b1;
    
    assign rstb =1'b0;
    
    assign clkb = i_clk;

endmodule
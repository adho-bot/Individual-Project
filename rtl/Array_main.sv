// Array_Main.sv

`timescale 1ns/1ps
module Array_Main #(
    parameter int ROWS = 2,
    parameter int COLS = 2,
    parameter int DATA_WIDTH = 16,
    parameter int REG_DEPTH = 8,
    parameter logic [31:0] ARRAY_BASE_ADDR = 32'h0000_0000
)(
    input  logic                        i_clk,
    input  logic                        i_rstn,

    // control
    input  logic [$clog2(REG_DEPTH) - 1:0]                  i_rs1_addr,
    input  logic [$clog2(REG_DEPTH) - 1:0]                  i_rs2_addr,
    input  logic [$clog2(REG_DEPTH) - 1:0]                  i_rd_addr,
    input  logic                        i_wr_en,
    input  logic                        i_rs2_sel,
    input  logic [1:0]                  i_news_sel,
    input  logic                        i_wb_sel,
    input  logic [2:0]                  i_opcode,
    input  logic [$clog2(DATA_WIDTH):0] i_counter,
    input  logic                        i_dataout_en,

    // memory mapped signals
    input  logic [9:0]                 i_array_address,

    // data in/out (word-wide interface)
    output logic [DATA_WIDTH-1:0]       o_array_data,
    input  logic [DATA_WIDTH-1:0]       i_array_data,

    // PISO / SIPO control
    input  logic                        i_piso_load,
    input  logic                        i_piso_shift,
    input  logic                        i_sipo_shift, 
    
    //MSB test
    input  logic                        i_bittst,
    
    //PE gating signal
    input  logic                        i_PE_enable,
    
    //Shift logic
    input logic [2:0] i_shift_amount,
    input logic       i_sra
);

    // --- Derived widths ---
    localparam int ROW_W                    = (ROWS > 1) ? $clog2(ROWS) : 1;
    localparam int COL_W                    = (COLS > 1) ? $clog2(COLS) : 1;
    localparam int NUM_ELEMENTS             = ROWS * COLS;

    // --- Internal registers ---
    logic [DATA_WIDTH-1:0]  piso_reg;
    logic                   arrayIn;
    logic [DATA_WIDTH-1:0]  parallel_out;
    logic                   arrayOut;

    // Neighbor wires
    logic north             [0:ROWS-1][0:COLS-1];
    logic south             [0:ROWS-1][0:COLS-1];
    logic east              [0:ROWS-1][0:COLS-1];
    logic west              [0:ROWS-1][0:COLS-1];
    logic news              [0:ROWS-1][0:COLS-1];

    // 1-bit data out per PE (bit-serial) - OR-reduced together
    logic array_dataOut     [0:ROWS-1][0:COLS-1];
    
    // Per-PE dataout enable (scalar per PE)
    logic dataout_en        [0:ROWS-1][0:COLS-1];
    
    // PE gating
    logic PE_enable         [0:ROWS-1][0:COLS-1];

    // Decoded indices and valid flags
    logic [ROW_W-1:0]       row_sel;
    logic [COL_W-1:0]       col_sel;
    logic                   wr_addr_valid;

    localparam COLS_W = $clog2(COLS);

/*===============================================*/
/*              PE Array                         */
/*===============================================*/
    genvar r, c;
    generate
        for (r = 0; r < ROWS; r++) begin : gen_row
            for (c = 0; c < COLS; c++) begin : gen_col
                assign north[r][c] = (r == ROWS-1)  ? '0 : news[r+1][c];
                assign south[r][c] = (r == 0)       ? '0 : news[r-1][c];
                assign west[r][c]  = (c == COLS-1)  ? '0 : news[r][c+1];
                assign east[r][c]  = (c == 0)       ? '0 : news[r][c-1];

                // PE gating
                assign PE_enable[r][c] = (i_PE_enable) ? 1'b1 : 
                                         (wr_addr_valid && i_piso_shift && (row_sel == r && col_sel == c));

                // Per-PE dataout enable: only the addressed PE gets enabled
                assign dataout_en[r][c] = (wr_addr_valid && row_sel == r && col_sel == c) ? i_dataout_en : 1'b0;

                PE_Main #(
                    .DATA_WIDTH(DATA_WIDTH), 
                    .REG_DEPTH(REG_DEPTH)
                )   pe_i (
                    .i_clk        (i_clk),
                    .i_rstn       (i_rstn),
                    .i_counter    (i_counter),
                    .i_data       (arrayIn),
                    .o_data       (array_dataOut[r][c]),
                    .i_north      (north[r][c]),
                    .i_east       (east[r][c]),
                    .i_south      (south[r][c]),
                    .i_west       (west[r][c]),
                    .o_news       (news[r][c]),
                    .i_rs1_addr   (i_rs1_addr),
                    .i_rs2_addr   (i_rs2_addr),
                    .i_rd_addr    (i_rd_addr),
                    .i_wr_en      (i_wr_en),
                    .i_rs2_sel    (i_rs2_sel),
                    .i_news_sel   (i_news_sel),
                    .i_wb_sel     (i_wb_sel),
                    .i_opcode     (i_opcode),
                    .i_dataout_en (dataout_en[r][c]),
                    .i_bittst     (i_bittst),
                    
                    .i_PE_enable (PE_enable[r][c]),
                    
                    .i_shift_amount(i_shift_amount),
                    .i_sra(i_sra)
                );
            end
        end
    endgenerate

/*===============================================*/
/*              Address Decoder                  */
/*===============================================*/
    
    always_comb begin
        row_sel = i_array_address[COLS_W +: ROW_W];
        col_sel = i_array_address[COLS_W-1:0];
        wr_addr_valid = (i_array_address < NUM_ELEMENTS);
    end

/*===============================================*/
/*              Output OR-Reduction              */
/*===============================================*/
    // Each PE outputs 0 when its dataout_en is low (gated in PE_Main).
    // OR-reduce all PE outputs - only the selected PE contributes a 1.
    always_comb begin
        arrayOut = 1'b0;
        for (int rr = 0; rr < ROWS; rr++) begin
            for (int cc = 0; cc < COLS; cc++) begin
                arrayOut = arrayOut | array_dataOut[rr][cc];
            end
        end
    end

/*===============================================*/
/*              Data Shift Registers             */
/*===============================================*/
    // Serial out (from PISO) is current LSB
    assign arrayIn = piso_reg[0];

    // PISO: load full word, shift right on strobe
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) piso_reg <= '0;
        else if (i_piso_load) piso_reg <= i_array_data;
        else if (i_piso_shift) piso_reg <= {1'b0, piso_reg[DATA_WIDTH-1:1]};
    end

    // SIPO parallel collector: shift in new bit (LSB-first)
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) parallel_out <= '0;
        else if (i_sipo_shift) parallel_out <= {arrayOut, parallel_out[DATA_WIDTH-1:1]};
    end

    assign o_array_data = parallel_out;

endmodule
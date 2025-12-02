// Array_Main.sv
`timescale 1ns/1ps
module Array_Main #(
    parameter int ROWS = 4,
    parameter int COLS = 4,
    parameter int DATA_WIDTH = 32,
    parameter logic [31:0] ARRAY_BASE_ADDR = 32'h0000_0000  // base for array element mapping (SIM MODE RN)
)(
    input  logic                      i_clk,
    input  logic                      i_rstn,

    // control (kept for compatibility; unused in stub PE)
    input  logic [4:0]                i_rd1_addr,
    input  logic [4:0]                i_rd2_addr,
    input  logic [4:0]                i_wr_addr,
    input  logic                      i_wr_en,
    input  logic                      i_rs2_sel,
    input  logic [1:0]                i_news_sel,
    input  logic                      i_wb_sel,
    input  logic [9:0]                i_opcode,
    input  logic [$clog2(DATA_WIDTH):0] i_counter,
    input  logic                      i_dataout_en,

    // memory mapped signals
    input  logic [31:0]               i_array_address,

    // data in/out (word-wide interface)
    output logic [DATA_WIDTH-1:0]     o_array_data,   // changed to DATA_WIDTH to match register
    input  logic [DATA_WIDTH-1:0]     i_array_data,

    // PISO / SIPO control
    input  logic                      i_piso_load,
    input  logic                      i_piso_shift,
    input  logic                      i_sipo_shift, 
    
    //PE gating signal
    input  logic                      i_PE_enable
);

    // --- Derived widths ---
    localparam int ROW_W = (ROWS > 1) ? $clog2(ROWS) : 1;
    localparam int COL_W = (COLS > 1) ? $clog2(COLS) : 1;
    localparam int NUM_ELEMENTS = ROWS * COLS;
    localparam int ADDR_BYTES_PER_ELEMENT = 4; // mapping granularity

    // --- Internal registers ---
    logic [DATA_WIDTH-1:0] piso_reg;
    logic arrayIn; // serial bit out of PISO
    logic [DATA_WIDTH-1:0] parallel_out;
    logic arrayOut; // serial bit from selected PE into SIPO

    // Neighbor wires (kept sized to DATA_WIDTH for compatibility)
    logic north [0:ROWS-1][0:COLS-1];
    logic south [0:ROWS-1][0:COLS-1];
    logic east  [0:ROWS-1][0:COLS-1];
    logic west  [0:ROWS-1][0:COLS-1];
    logic news  [0:ROWS-1][0:COLS-1];

    // 1-bit data in/out per PE (bit-serial)
    logic array_dataOut [0:ROWS-1][0:COLS-1];
    logic array_dataIn  [0:ROWS-1][0:COLS-1];

    //PE gating
    logic PE_enable     [0:ROWS-1][0:COLS-1];

    // Decoded indices and valid flags
    logic [ROW_W-1:0] wr_row_sel;
    logic [COL_W-1:0] wr_col_sel;
    logic             wr_addr_valid;

    logic [ROW_W-1:0] rd_row_sel;
    logic [COL_W-1:0] rd_col_sel;
    logic             rd_addr_valid;

/*===============================================*/
/*              PE Array                         */
/*===============================================*/
    genvar r, c;
    generate
        for (r = 0; r < ROWS; r++) begin : gen_row
            for (c = 0; c < COLS; c++) begin : gen_col
                assign north[r][c] = (r == ROWS-1)        ? '0 : news[r+1][c];
                assign south[r][c] = (r == 0)   ? '0 : news[r-1][c];
                assign west[r][c]  = (c == COLS-1)        ? '0 : news[r][c+1];
                assign east[r][c]  = (c == 0)   ? '0 : news[r][c-1];

                PE_Main #(.WIDTH(DATA_WIDTH), .DEPTH(16)) pe_i (
                    .i_clk        (i_clk),
                    .i_rstn       (i_rstn),
                    .i_counter    (i_counter),
                    .i_data       (array_dataIn[r][c]),
                    .o_data       (array_dataOut[r][c]),
                    .i_north      (north[r][c]),
                    .i_east       (east[r][c]),
                    .i_south      (south[r][c]),
                    .i_west       (west[r][c]),
                    .o_news       (news[r][c]),
                    .i_rd1_addr   (i_rd1_addr),
                    .i_rd2_addr   (i_rd2_addr),
                    .i_wr_addr    (i_wr_addr),
                    .i_wr_en      (i_wr_en),
                    .i_rs2_sel    (i_rs2_sel),
                    .i_news_sel   (i_news_sel),
                    .i_wb_sel     (i_wb_sel),
                    .i_opcode     (i_opcode),
                    .i_dataout_en (i_dataout_en),
                    
                    .i_PE_enable (PE_enable[r][c])
                );
            end
        end
    endgenerate

/*===============================================*/
/*              Address Decoder                  */
/*===============================================*/
    always_comb begin
        // default
        wr_row_sel = '0;
        wr_col_sel = '0;
        wr_addr_valid = 1'b0;

        rd_row_sel = '0;
        rd_col_sel = '0;
        rd_addr_valid = 1'b0;

        //Write Decode
        if (i_array_address >= ARRAY_BASE_ADDR) begin
            logic [31:0] byte_offset;
            byte_offset = i_array_address - ARRAY_BASE_ADDR;
            if (byte_offset < NUM_ELEMENTS * ADDR_BYTES_PER_ELEMENT) begin
                logic [31:0] elem_index;    //word address
                elem_index = byte_offset >> 2; // convert from byte to word (/4)
                wr_row_sel = elem_index / COLS;
                wr_col_sel = elem_index % COLS;
                wr_addr_valid = 1'b1;
            end
        end

        //Read Decode
        if (i_array_address >= ARRAY_BASE_ADDR) begin
            logic [31:0] byte_offset_r;
            byte_offset_r = i_array_address - ARRAY_BASE_ADDR;
            if (byte_offset_r < NUM_ELEMENTS * ADDR_BYTES_PER_ELEMENT) begin
                logic [31:0] elem_index_r;
                elem_index_r = byte_offset_r >> 2;
                rd_row_sel = elem_index_r / COLS;
                rd_col_sel = elem_index_r % COLS;
                rd_addr_valid = 1'b1;
            end
        end
    end

/*===============================================*/
/*              Input Decoder                    */
/*===============================================*/
    always_comb begin
        integer rr, cc;
        // default 0 to avoid latches
        for (rr = 0; rr < ROWS; rr = rr + 1) begin
            for (cc = 0; cc < COLS; cc = cc + 1) begin
                array_dataIn[rr][cc] = 1'b0;
            end
        end

        // route serial bit to selected PE when write is valid and PISO is shifting (strobe)
        if (wr_addr_valid && i_piso_shift) begin
            if (wr_row_sel < ROWS && wr_col_sel < COLS) begin
                array_dataIn[wr_row_sel][wr_col_sel] = arrayIn;
            end
        end
    end

/*===============================================*/
/*              Output Mux                       */
/*===============================================*/
    always_comb begin
        if (rd_addr_valid && rd_row_sel < ROWS && rd_col_sel < COLS) begin
            arrayOut = array_dataOut[rd_row_sel][rd_col_sel];
        end else begin
            arrayOut = 1'b0;
        end
    end

/*===============================================*/
/*               PE gate                         */
/*===============================================*/

    always_comb begin
        integer rr, cc;

        if(!i_PE_enable) begin      //i_PE_enable selects between memory instr(0) and other instructions
            for (rr = 0; rr < ROWS; rr = rr + 1) begin
                for (cc = 0; cc < COLS; cc = cc + 1) begin
                    PE_enable[rr][cc] = 1'b0;
                end
            end
    
            // route serial bit to selected PE when write is valid and PISO is shifting (strobe)
            if (wr_addr_valid && i_piso_shift) begin
                if (wr_row_sel < ROWS && wr_col_sel < COLS) begin
                    PE_enable[wr_row_sel][wr_col_sel] = 1;  //PE enable signal
                end
            end
        end else begin
            for (rr = 0; rr < ROWS; rr = rr + 1) begin
                for (cc = 0; cc < COLS; cc = cc + 1) begin
                    PE_enable[rr][cc] = 1'b1;
                end
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
        if (!i_rstn) begin
            piso_reg <= '0;
        end else begin
            if (i_piso_load) begin
                piso_reg <= i_array_data;
            end else if (i_piso_shift) begin
                // shift right: drop LSB, insert zero at MSB (serial LSB-first)
                piso_reg <= {1'b0, piso_reg[DATA_WIDTH-1:1]};
            end
        end
    end

    // SIPO parallel collector: shift left in new bit at LSB side (LSB-first)
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            parallel_out <= '0;
        end else begin
            if (i_sipo_shift) begin
                // shift left so LSB is newest bit (this is consistent with arrayOut being serial LSB-first)
                parallel_out <= {arrayOut, parallel_out[DATA_WIDTH-1:1]};   //Array data out is LSB first
            end
        end
    end

    assign o_array_data = parallel_out;

endmodule
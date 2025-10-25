module Array_Main #(
    parameter ROWS = 1,
    parameter COLS = 1,
    parameter DATA_WIDTH = 32
)(
    input  logic i_clk,
    input  logic i_rstn,

    // Control signals
    input  logic [3:0]  i_rd1_addr,
    input  logic [3:0]  i_rd2_addr,
    input  logic [3:0]  i_wr_addr,
    input  logic        i_wr_en,
    input  logic        i_rs2_sel,
    input  logic        i_news_sel,
    input  logic        i_wb_sel,
    input  logic [9:0]  i_opcode,
    input  logic        i_data_valid,
    input  logic [$clog2(DATA_WIDTH) - 1:0]  i_counter,
    input  logic        i_dataout_en,

    // Global data bus
    input  logic [DATA_WIDTH-1:0] i_data_bus,
    output logic [DATA_WIDTH-1:0] o_data_bus,
    
    //Memory Access signals
    input logic i_array_access,
    input logic [31:0] i_array_address
);

    // Internal wiring for inter-PE connections
    
    //Directions
    logic [DATA_WIDTH-1:0] north [0:ROWS-1][0:COLS-1];
    logic [DATA_WIDTH-1:0] south [0:ROWS-1][0:COLS-1];
    logic [DATA_WIDTH-1:0] east  [0:ROWS-1][0:COLS-1];
    logic [DATA_WIDTH-1:0] west  [0:ROWS-1][0:COLS-1];
    logic [DATA_WIDTH-1:0] news  [0:ROWS-1][0:COLS-1];
    
    //Data
    logic array_dataOut [0:ROWS-1][0:COLS-1];
    logic array_dataIn [0:ROWS-1][0:COLS-1];

    logic [31:0] dataTemp;  //Temporary Data storage
    
    // Generate PE array
    generate
        genvar row, col;
        for (row = 0; row < ROWS; row++) begin : row_gen
            for (col = 0; col < COLS; col++) begin : col_gen

                // Handle boundary connections
                assign north[row][col] = (row == 0) ? '0 : news[row-1][col];
                assign south[row][col] = (row == ROWS-1) ? '0 : news[row+1][col];
                assign west[row][col]  = (col == 0) ? '0 : news[row][col-1];
                assign east[row][col]  = (col == COLS-1) ? '0 : news[row][col+1];

                PE_Main #(
                    .WIDTH (DATA_WIDTH),
                    .DEPTH (16)
                ) pe_inst (
                    .i_clk        (i_clk),
                    .i_rstn       (i_rstn),
                    .i_counter    (i_counter),

                    // Data bus interface
                    .i_data       (array_dataIn[row][col]),
                    .o_data       (array_dataOut[row][col]),

                    // Neighbour connections
                    .i_north      (north[row][col]),
                    .i_east       (east[row][col]),
                    .i_south      (south[row][col]),
                    .i_west       (west[row][col]),
                    .o_news       (news[row][col]),

                    // Control signals
                    .i_rd1_addr   (i_rd1_addr),
                    .i_rd2_addr   (i_rd2_addr),
                    .i_wr_addr    (i_wr_addr),
                    .i_wr_en      (i_wr_en),
                    .i_rs2_sel    (i_rs2_sel),
                    .i_news_sel   (i_news_sel),
                    .i_wb_sel     (i_wb_sel),
                    .i_opcode     (i_opcode),
                    .i_data_valid (i_data_valid),
                    .i_dataout_en (i_dataout_en)
                );
            end
        end
    endgenerate
    
    
    //Memory interfacing
    
    //Address -> row/col converter
    logic [15:0] Row, Col;
    always_comb begin
        Row = i_array_address >> $clog2(ROWS);    
        Col = i_array_address % ROWS;
    end
    
    
    //Memory Read   SIPO
    always_ff@(posedge i_clk) begin
        if(i_rstn) begin
            dataTemp <= 32'd0;
        end else begin
            dataTemp <= {dataTemp[31:1],array_dataOut[Row][Col]};
        end
    end
    
    assign o_data_bus = (i_array_access) ? dataTemp : 0;
    
    //Memory Write  PISO prolly need a data write singal
    always_ff@(posedge i_clk) begin
        if(i_rstn) begin
            array_dataIn[Row][Col] <= 1'b0;
        end else begin
            array_dataIn[Row][Col] <= i_data_bus[i_counter]; //lsb first
        end
    end
endmodule

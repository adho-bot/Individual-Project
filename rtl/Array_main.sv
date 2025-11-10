module Array_Main #(
    parameter ROWS = 2,
    parameter COLS = 2,
    parameter DATA_WIDTH = 32,
    parameter ARRAY_BASE_ADDR = 32'h0001_0000       //32'h rowSel_colSel
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
    input  logic [$clog2(DATA_WIDTH):0]  i_counter, //From Control unit
    input  logic        i_dataout_en,
    
    //Memory mapped signals
    input  logic [31:0]  i_address,   //address from cpu
    
    //data into and out of array
    output logic [31:0]  o_array_data, 
    input  logic [31:0]  i_array_data
    

);


    //PISO
    logic [DATA_WIDTH-1:0] piso_reg;
    logic piso_load, piso_shift;
    logic arrayIn; //intermediate data between PISO and array
        
    //SIPO
    logic [DATA_WIDTH-1:0] parallel_out;
    logic sipo_load, sipo_shift;
    logic arrayOut;             //intermediate data between array and SIPO


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
                    .i_data       (array_dataIn[row][col]),     //1 bit
                    .o_data       (array_dataOut[row][col]),    //1 bit

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
    
    
/*===================================================================*/    
/*                          Array Decode Unit                        */
/*===================================================================*/ 
    logic [ROWS - 1: 0 ]            array_input_sel;
    logic [ROWS - 1: 0 ]            array_output_sel;
    
    logic [DATA_WIDTH / 2 - 1: 0]   rd_row_inter;           //row intermediate signal
    logic [DATA_WIDTH / 2 - 1: 0]   rd_col_inter;           //col intermediate signal
    logic [DATA_WIDTH / 2 - 1: 0]   wr_row_inter;           //row intermediate signal
    logic [DATA_WIDTH / 2 - 1: 0]   wr_col_inter;           //col intermediate signal
        
    //Writing to array
    always_comb begin
        if(i_address < 32'h1000_0000) begin
            array_input_sel = 32'd0;
        end else begin
            wr_row_inter = (i_address[31:16] - 8)/4;
            wr_col_inter = i_address [15:0] / 4;
            array_input_sel = {wr_row_inter, wr_col_inter}; 
        end
    end
    
    //Reading from array
    always_comb begin
        if(i_address < 32'h1000_1000) begin
            array_output_sel = 32'd0;
        end else begin
            rd_row_inter = (i_address[31:16] - 8) / 4;
            rd_col_inter = (i_address [15:0] - 8) / 4;
            array_output_sel = {rd_row_inter, rd_col_inter}; 
        end
    end    
    
/*===================================================================*/    
/*                          MUX to/from array                        */
/*===================================================================*/ 
    //PISO MUX
    always_comb begin
        case(array_input_sel)
            00: array_dataIn[0][0] = arrayIn;           //2x2 for now. need to ask piotr how to expand this
            01: array_dataIn[0][1] = arrayIn;
            10: array_dataIn[1][0] = arrayIn;
            11: array_dataIn[1][1] = arrayIn;
        endcase 
    end
    
    //SIPO MUX
    always_comb begin
        case(array_output_sel)
            00: arrayOut = array_dataOut[0][0];
            01: arrayOut = array_dataOut[0][1];
            10: arrayOut = array_dataOut[1][0];
            11: arrayOut = array_dataOut[1][1];
        endcase
    end    
    
/*===================================================================*/ 
/*                          Shift Registers                          */ 
/*===================================================================*/    

        
        
    // serial out is always current LSB
    assign arrayIn = piso_reg[0];

    always_ff @(posedge i_clk) begin                //LSB in first
        if (!i_rstn) begin
            piso_reg <= {DATA_WIDTH{1'b0}};
        end else if (piso_load) begin
            piso_reg <= i_array_data;
        end else if (piso_shift) begin
            piso_reg <= {1'b0, piso_reg[DATA_WIDTH-1:1]};
        end
    end
    
    
    always_ff @(posedge i_clk) begin            //LSB out first
        if (!i_rstn) begin
            parallel_out <= {DATA_WIDTH{1'b0}};
        end else if (sipo_load) begin
            o_array_data <= parallel_out;
        end else if (sipo_shift) begin
            parallel_out <= {parallel_out[DATA_WIDTH-2:0], arrayOut};
        end
    end
  
    
    
endmodule


/*
Addressing method: (written here incase i forget it)

1. Address sent in from CPU
2. Address is fed into data memory and PE array
3. If (address > threshold) 
        data selected from Array 
   else 
        data selected from memory
4. Data from array selected from i_address
5. Two multiplexers for input sel and Two multiplexers for output sel
6. PISO and SIPO into the PEs happens in the array_main layer.
   - All data inside PE is bit serial
7. Data load and store states are initiated by a read/write to the data memory <-- IMPORTANT
    - ARRAY LOADS AND STORES ARE NOT DONE BY A MICROINSTRUCTION. DONE BY INTERFACING WITH MEMORY
    - NEED TO BRING THE STATUS FLAG OUT FOR CPU TO SEE when instruction done writing( the o_Control_ready flag) 


*/




module Top #(
    parameter int THRESH = 0.2
 )(
    input  logic    i_clk,
    input  logic    i_rstn,
    input  logic    [31:0] i_instruction,
    
    //Data input/output
    input logic     [31:0] i_array_data,
    output logic    [31:0] o_array_data,
    
    // Data Memory Signals
    output logic [31:0] o_array_address,
    output logic        o_wr_en,
    output logic        o_rd_en,
    
    output logic        o_Control_ready //signals when the array has finished processing
);
    //Threshold for 8 bit data
    localparam signed THRESHOLD = THRESH * 1020;


    // Control signals from Control_Unit to Array_Main
    logic [4:0]  rd1_addr;
    logic [4:0]  rd2_addr;
    logic [4:0]  wr_addr;
    logic        wr_reg_en;
    logic        rs2_sel;
    logic [1:0]  news_sel;      // Assuming 2-bit select for NEWS
    logic [1:0]  wb_sel;        // Assuming 2-bit select for writeback
    logic [9:0]  opcode;        // Standard RISC-V opcode width
    logic [5:0]  counter;       // Assuming 32-bit counter
    logic        dataout_en;
    
    //Memory map write and read
    logic [31:0] array_address;
    
    //PISO SIPO control
    logic sipo_shift;
    logic piso_shift, piso_load;
    
    //PE gating
    logic PE_enable;
    
    //Clipping signal
    logic signed [31:0] array_data;
    
    //Magnitude signal
    logic [31:0] signed_array_data;
    
    //MSB latching 
    logic bit0;
    
    //MSB Bit
    logic [4:0] bittst;
    
    
    Array_Main #(
        .ROWS(2),         // example: 4x4 array
        .COLS(2),
        .DATA_WIDTH(32),
        .ARRAY_BASE_ADDR(32'h0000_0000)
    ) array_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),

        // Control signals
        .i_rd1_addr(rd1_addr),
        .i_rd2_addr(rd2_addr),
        .i_wr_addr(wr_addr),
        .i_wr_en(wr_reg_en),
        .i_rs2_sel(rs2_sel),
        .i_news_sel(news_sel),
        .i_wb_sel(wb_sel),
        .i_opcode(opcode),
        .i_counter(counter),
        .i_dataout_en(dataout_en),
        
        .i_array_address(array_address),
        
        //data into and out of array
        .o_array_data(array_data),                 //32 bits
        .i_array_data(i_array_data),               //32bits        still need to connect
        
        //PISO SIPO control
        .i_piso_load(piso_load), 
        .i_piso_shift(piso_shift),
        .i_sipo_shift(sipo_shift), 
        
        //PE gating
        .i_PE_enable(PE_enable),   

        //MSB latching        
        .i_bit0(bit0),
    
        //MSB bit
        .i_bittst(bittst)         
             
    );
    
    Control_Unit ctrl_inst (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),

        .o_rd1_addr(rd1_addr),
        .o_rd2_addr(rd2_addr),
        .o_wr_addr(wr_addr),
        .o_wr_reg_en(wr_reg_en),            //register write enable signal
        .o_rs2_sel(rs2_sel),                // ALU's rs2 input select   
        .o_news_sel(news_sel),              // Select between N,E,W,S
        .o_wb_sel(wb_sel),                  // Selects between writing back to reg file from alu or external
        .o_opcode(opcode),                  //
        .o_counter(counter),                //Control sync counter
        .o_dataout_en(dataout_en),          //Data out enable           --need to look into whether this is needed
        
        .o_data_wr(o_wr_en),                //data memory write enable
        .o_data_rd(o_rd_en),                //data memory read enable
        
        .o_Control_ready(o_Control_ready),   //High during IDLE, low otherwise
        
        //PISO SIPO control signals
        .o_piso_load(piso_load), 
        .o_piso_shift(piso_shift),
        .o_sipo_shift(sipo_shift),   
        
        //Address generation
        .o_array_address(array_address), 
        
        //PE gating
        .o_PE_enable(PE_enable), 

        //MSB latching        
        .o_bit0(bit0),
    
        //MSB bit
        .o_bittst(bittst)          
        
    );
    
    assign o_array_address = array_address;
    
    //Thresholding (|array data| > T ? 255 : 0)
    //assign o_array_data = ((array_data > THRESHOLD) || (array_data < -THRESHOLD)) ? 8'd255 : 8'd0;  


//Magnitude and Thresholding step
   //Magnitude |array data|
//   assign signed_array_data =  (array_data > 0) ? array_data : ~array_data + 1;
   
    //Scaling
//    assign o_array_data = signed_array_data >> 2;
    
    assign o_array_data = array_data;
endmodule

module PE_Main#(
    parameter WIDTH = 32,
    parameter DEPTH = 9
)(
    // Global signals
    input  logic                        i_clk,
    input  logic                        i_rstn,
    input  logic [$clog2(WIDTH):0]      i_counter,
    
    // Data input
    input  logic                        i_data,
    output logic                        o_data,
    
    // Neighbour inputs
    input  logic                        i_north,
    input  logic                        i_east,
    input  logic                        i_south,
    input  logic                        i_west,
    
    // Neighbour outputs
    output logic                        o_news,
    
    // Control signals
    input  logic [$clog2(DEPTH)-1:0]    i_rd1_addr,
    input  logic [$clog2(DEPTH)-1:0]    i_rd2_addr,
    input  logic [$clog2(DEPTH)-1:0]    i_wr_addr,
    input  logic                        i_wr_en,
    input  logic                        i_rs2_sel,
    input  logic [1:0]                  i_news_sel,
    input  logic                        i_wb_sel,
    input  logic [9:0]                  i_opcode,
    input  logic                        i_dataout_en,
    
    //PE gate
    input  logic                        i_PE_enable,
    
    //MSB latching        
    input logic                         i_bit0,
    
    //MSB bit
    input logic [4:0]                    i_bittst  
);
    // Parameters
    localparam [1:0] NORTH = 2'b00, EAST = 2'b01, WEST = 2'b10, SOUTH = 2'b11;
    
    // Internal connecting signals
    // Register file signals
    logic datain;
    logic rd1;
    logic rd2;
    
    logic news;
    
    // ALU signals
    logic operandA;
    logic operandB;
    logic result;
    
    //PE gating signals
    logic wr_en;
    
    //PE Gating
    assign wr_en = i_wr_en & i_PE_enable;
    
    // Register File instantiation
    Register_File #(
        .DEPTH(DEPTH)
    ) register_file_inst (
        .i_clk      (i_clk),
        .i_rstn     (i_rstn),
        .i_datain   (datain),
        .i_rd1_addr (i_rd1_addr),
        .i_rd2_addr (i_rd2_addr),
        .i_wr_addr  (i_wr_addr),
        .i_wr_en    (wr_en),
        .i_counter  (i_counter),
        .i_bittst   (i_bittst),
        
        .o_rd1      (rd1),
        .o_rd2      (rd2)
    );
    
    // ALU instantiation
    ALU_bitserial alu_inst (
        .i_clk       (i_clk),
        .i_rstn      (i_rstn),
        .i_operandA  (operandA),
        .i_operandB  (operandB),
        .i_opcode    (i_opcode),
//        .i_sign()
        .i_bit0(i_bit0),
        
        .o_result    (result)       
    );
    
    // Register to ALU connections
    assign operandA = rd1;
    assign operandB = (i_rs2_sel) ? news : rd2;
    
    //Rs2 to NEWS
    assign o_news = rd2;
    
    // NEWS input mux
    always_comb begin
        case(i_news_sel)
            NORTH:   news = i_north;
            EAST:    news = i_east;
            WEST:    news = i_west;
            SOUTH:   news = i_south;
            default: news = 1'b0;
        endcase
    end
    
    // ALU result writeback mux
    assign datain = (i_wb_sel) ? i_data : result;
    
    //Data output to data bus
    assign o_data = (i_dataout_en) ? rd1 : 0; 
endmodule
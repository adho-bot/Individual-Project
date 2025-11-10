module Top (
    input  logic i_clk,
    input  logic i_rstn,
    input  logic i_instruction,
    
    // Data Memory Signals
    input  logic [31:0] i_address,
    output logic        o_wr_en,
    output logic        o_rd_en
    

);

    
    // Control signals from Control_Unit to Array_Main
    logic [4:0]  rd1_addr;
    logic [4:0]  rd2_addr;
    logic [4:0]  wr_addr;
    logic        wr_reg_en;
    logic        rs2_sel;
    logic [1:0]  news_sel;      // Assuming 2-bit select for NEWS
    logic [1:0]  wb_sel;        // Assuming 2-bit select for writeback
    logic [6:0]  opcode;        // Standard RISC-V opcode width
    logic        data_valid;
    logic [5:0]  counter;       // Assuming 32-bit counter
    logic        dataout_en;
    logic       o_Control_ready;
    
    //Memory map write and read
    
    Array_Main #(
        .ROWS(1),         // example: 4x4 array
        .COLS(1),
        .DATA_WIDTH(32),
        .ARRAY_BASE_ADDR(32'h0001_0000)
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
        .i_data_valid(data_valid),
        .i_counter(counter),
        .i_dataout_en(dataout_en),
        
        .i_address(i_address)

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
        .o_data_valid(data_valid),          //News enable register
        .o_counter(counter),                //Control sync counter
        .o_dataout_en(dataout_en),          //Data out enable           --need to look into whether this is needed
        
        .o_data_wr(o_wr_en),                //data memory write enable
        .o_data_rd(o_rd_en),                //data memory read enable
        
        .o_Control_ready(o_Control_ready)   //High during IDLE, low otherwise
    );
    

endmodule

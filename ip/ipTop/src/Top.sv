module Top#(
    parameter int DATA_WIDTH = 16,
    parameter int REG_DEPTH = 4,
    parameter int ARRAY_BASE_ADDR = 32'h0000_0000,
    parameter int ROW_LENGTH = 2,
    parameter int COL_LENGTH = 2
 )(
    input   logic           i_clk,
    input   logic           i_rstn,
    input   logic   [31:0]  i_instruction,
    input   logic           i_instr_valid,  //instruction handshaking
    
    //Data input/output
    input logic     [DATA_WIDTH - 1:0] i_array_data,
    output logic    [DATA_WIDTH - 1:0] o_array_data,
    
    // Data Memory Signals
    output logic [31:0] o_array_address,
    output logic        o_wr_en,
    output logic        o_rd_en,
    
    output logic        o_Control_ready //signals when the array has finished processing
);

    // Control signals from Control_Unit to Array_Main
    logic [4:0]  rd1_addr;
    logic [4:0]  rd2_addr;
    logic [4:0]  wr_addr;
    logic        wr_reg_en;
    logic        rs2_sel;
    logic [1:0]  news_sel;      // Assuming 2-bit select for NEWS
    logic [1:0]  wb_sel;        // Assuming 2-bit select for writeback
    logic [9:0]  opcode;        // Standard RISC-V opcode width
    logic [4:0]  counter;       // Assuming 32-bit counter
    logic        dataout_en;
    
    logic        bittst;
    
    //Memory map write and read
    logic [31:0] array_address;
    
    //PISO SIPO control
    logic sipo_shift;
    logic piso_shift, piso_load;
    
    //PE gating
    logic PE_enable;
    
    //Clipping signal
    logic signed [DATA_WIDTH - 1:0] array_data;
 
    //Shifting signals
    logic [4:0] shift_amount;
    logic       sra;
    
    Array_Main #(
        .ROWS(ROW_LENGTH),         // Note: Array size must be of powers of 2
        .COLS(COL_LENGTH),
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_BASE_ADDR(ARRAY_BASE_ADDR),
        .REG_DEPTH(REG_DEPTH)
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
        .o_array_data(array_data),                
        .i_array_data(i_array_data),             
        
        //PISO SIPO control
        .i_piso_load(piso_load), 
        .i_piso_shift(piso_shift),
        .i_sipo_shift(sipo_shift), 
        
        .i_bittst(bittst),
        
        //PE gating
        .i_PE_enable(PE_enable),
        
        .i_shift_amount(shift_amount),
        .i_sra(sra) 
    );
    
    Control_Unit #(
        .DATA_WIDTH(DATA_WIDTH)
    )   ctrl_inst(
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_instruction(i_instruction),
        .i_instr_valid(i_instr_valid), //instruction handshaking

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
        
        .o_bittst(bittst),
        
        //PE gating
        .o_PE_enable(PE_enable),
        
        .o_shift_amount(shift_amount),
        .o_sra(sra)        
    );
    
    assign o_array_address = array_address;


    assign o_array_data = array_data;
endmodule
module FPGA_Top(
input logic i_clk
);


logic clk, rstn, locked;
logic control_ready;
logic [31:0] pc;
logic [31:0] instruction;

logic [31:0] read_data, write_data;
logic [31:0] array_address;
logic wr_en, rd_en;


Top #(
    .THRESH(32'd0)   //Unused for now
) u_top (
    .i_clk            (clk),
    .i_rstn           (rstn),
    .i_instruction    (instruction),

    .i_array_data     (read_data),
    .o_array_data     (write_data),

    .o_array_address  (array_address),
    .o_wr_en          (wr_en),
    .o_rd_en          (rd_en),

    .o_Control_ready  (control_ready)
);


Data_Memory #(
    .MEM_SIZE(1024)
) data_memory_inst (
    .i_clk      (clk),
    .i_address  (array_address),
    .i_data     (write_data),
    .i_wr_en    (wr_en),
    .i_rd_en    (rd_en),
    .o_data     (read_data)
);

Instruction_Memory #(
    .MEM_SIZE(1024)
) instruction_memory_inst (
    .i_clk            (clk),
    .i_address        (pc),
    .i_Control_Ready  (control_ready), 
    .o_instr          (instruction)
);

clk_wiz_0 clk_inst
(
 // Clock out ports
    .clk_out1(clk),     // output clk_out1
    // Status and control signals
    .locked(locked),       // output locked
   // Clock in ports
    .clk_in1(i_clk)      // input clk_in1
);

assign rstn = !locked;

TempPC PC_inst(
    .i_clk(clk),
    .i_rstn(rstn),
    .i_Control_Ready(control_ready),
    .o_pc(pc)
);


endmodule





/*=============================================*/
/*                 TEMP PC MODULE              */
/*=============================================*/

module TempPC(
input logic i_clk,
input logic i_rstn,
input logic i_Control_Ready,
output logic [31:0] o_pc
);

always_ff @(posedge i_clk) begin
    if(!i_rstn)
        o_pc <= 32'd0; 
    else if(i_Control_Ready)
        o_pc <= o_pc + 4;
end


endmodule


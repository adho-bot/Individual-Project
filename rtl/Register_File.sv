module Register_File#(
    parameter WIDTH = 32,
    parameter DEPTH = 4
)(
    input  logic        i_clk,
    input  logic        i_rstn,

    // serial data input
    input  logic        i_datain,

    // addresses
    input  logic [$clog2(DEPTH)-1:0] i_rd1_addr,
    input  logic [$clog2(DEPTH)-1:0] i_rd2_addr,
    input  logic [$clog2(DEPTH)-1:0] i_wr_addr,

    // control
    input  logic        i_wr_en,

    // serial data outputs
    output logic        o_rd1,
    output logic        o_rd2
);

    // Register memory 
   logic [WIDTH-1:0] rf_mem [0:DEPTH-1];

/*================================================================*/
/*				WRITE				  */
/*================================================================*/

    // Write: shift in one bit per clock to rf_mem[i_wr_addr]
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            integer i;
            for (i = 0; i < DEPTH; i=i+1)
                rf_mem[i] <= '0;
        end else if (i_wr_en) begin
            // shift left by 1 and insert new bit at LSB
            rf_mem[i_wr_addr] <= {i_datain, rf_mem[i_wr_addr][WIDTH-1:1]};
        end
    end

/*================================================================*/
/*				READ				  */
/*================================================================*/
    
// Serial read: output LSB of selected registers each cycle
    assign o_rd1 = rf_mem[i_rd1_addr][0];  // LSB
    assign o_rd2 = rf_mem[i_rd2_addr][0];  // LSB

    // Shift registers right after outputting LSB
    always_ff @(posedge i_clk) begin
        rf_mem[i_rd1_addr] <= {1'b0, rf_mem[i_rd1_addr][WIDTH-1:1]};
        rf_mem[i_rd2_addr] <= {1'b0, rf_mem[i_rd2_addr][WIDTH-1:1]};
    end

endmodule

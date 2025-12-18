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
    input  logic        [5:0] i_counter, //global counter shared by all PEs

    // serial data outputs
    output logic        o_rd1,
    output logic        o_rd2
);

    // Register memory 
   logic [WIDTH-1:0] rf_mem [0:DEPTH-1];
   
   //Temp shifting variable
    logic [WIDTH:0] tempShift1, tempShift2;
    
    assign tempShift1  = (rf_mem[i_rd1_addr] > 255) ? 255 : (rf_mem[i_rd1_addr] < 0) ? 0 : rf_mem[i_rd1_addr];
    assign tempShift2  = (rf_mem[i_rd2_addr] > 255) ? 255 : (rf_mem[i_rd2_addr] < 0) ? 0 : rf_mem[i_rd2_addr];
    
/*================================================================*/
/*				WRITE				  */
/*================================================================*/

    // Write: shift in one bit per clock to rf_mem[i_wr_addr]
    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            integer i;
            for (i = 0; i < DEPTH; i=i+1)
                rf_mem[i] <= '0;
        end else if (i_wr_en && (i_wr_addr != 0)) begin
            rf_mem[i_wr_addr] <= {i_datain, rf_mem[i_wr_addr][WIDTH-1:1]};
        end
    end

/*================================================================*/
/*				             READ				                  */
/*================================================================*/
    logic [4:0] safe_index;
    assign safe_index = (i_counter >= WIDTH) ? WIDTH-1 : i_counter;
    
// Serial read: output LSB of selected registers each cycle
    assign o_rd1 = tempShift1[i_counter];   //this counter goes from 0 to 32 and produces X value for the 0 to 31 bit temp variable
    assign o_rd2 = tempShift2[i_counter];

endmodule

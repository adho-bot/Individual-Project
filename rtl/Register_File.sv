//Note:
//Pointers are used for reading a full word based on a base register address
// E.g. for 8 registers in a rf, the bit serial RF will have a depth 8*32.
//Words are accessed by having the user choose a base 0,1,2,3,4,5,6,7
//base is multiplied by 32 and added with pointer values(pointer will increement untill a word is extracted(lsb first))
//How do i extract individual bits?

module Register_File#(
    parameter DEPTH,
    parameter WIDTH
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
    input  logic        [$clog2(WIDTH):0] i_counter, //global counter shared by all PEs

    //MSB
    input logic         i_bittst,

    // serial data outputs
    output logic        o_rd1,
    output logic        o_rd2
);

    // Register memory 
   logic rf_mem [0:WIDTH * DEPTH-1];
   
    //Write Pointer
    logic [$clog2(WIDTH) :0] wr_ptr;
    

/*================================================================*/
/*				              WRITE		                 		  */
/*================================================================*/       

    always_ff @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            integer i;
            wr_ptr <= 5'd0;
            for (i = 0; i < DEPTH * WIDTH; i=i+1)
                rf_mem[i] <= '0;
        end else if (i_wr_en && (i_wr_addr != 0)) begin
            if (wr_ptr == WIDTH - 1)
                wr_ptr <= 5'd0;
            else
                wr_ptr <= wr_ptr + 1;
                
                rf_mem[i_wr_addr * WIDTH + wr_ptr] <= i_datain;
            end
    end

/*================================================================*/
/*				             READ				                  */
/*================================================================*/           
    assign o_rd1 = rf_mem[i_rd1_addr * WIDTH + i_counter]; 
    assign o_rd2 = (i_bittst) ? rf_mem[i_rd2_addr * WIDTH + i_bittst * (WIDTH - 1)]: rf_mem[i_rd2_addr * WIDTH + i_counter];  
            


endmodule

module Data_Memory#(
    parameter ARRAY_BASE_ADDR = 32'h00001_0000
)(
    input logic i_clk,
    input logic [31:0] i_address,  
    input logic [31:0] i_data,     
    input logic i_data_wr,           
    input logic i_data_rd,         
    
    output logic [31:0] o_data,  
    
    //Array access flag
    output logic o_array_access,
    
    //Array access address (scaled to fit array)
    output logic [31:0] o_array_address
);


logic [7:0] data_memory [0:1023];  

//Array memory map flag
always_comb begin
    if(i_address >= ARRAY_BASE_ADDR && i_data_wr) begin
        o_array_access = 1'b1;
        o_array_address = (i_address - ARRAY_BASE_ADDR) >> 2; //outputs 0,1, 2, 3 ... (normalise and divide by 4)
    end else begin
        o_array_access = 1'b0;
        o_array_address = 32'd0;
    end
end

always_ff @(negedge i_clk) begin
    if (i_data_rd) begin   
        o_data <= {data_memory[i_address[11:0]+3], 
                   data_memory[i_address[11:0]+2], 
                   data_memory[i_address[11:0]+1], 
                   data_memory[i_address[11:0]]};
    end                
end


always_ff @(negedge i_clk) begin
    if (i_data_wr && !o_array_access) begin
        data_memory[i_address[11:0]]   <= i_data[7:0];   
        data_memory[i_address[11:0]+1] <= i_data[15:8];
        data_memory[i_address[11:0]+2] <= i_data[23:16];
        data_memory[i_address[11:0]+3] <= i_data[31:24]; 
    end
end

endmodule

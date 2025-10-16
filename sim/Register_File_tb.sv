`timescale 1ns/1ps
module tb_Register_File;
    // Parameters
    parameter WIDTH = 32;
    parameter DEPTH = 4;
    parameter CLK_PERIOD = 10;

    // DUT signals
    logic        clk;
    logic        rstn;
    logic        datain;
    logic [1:0]  rd1_addr;
    logic [1:0]  rd2_addr;
    logic [1:0]  wr_addr;
    logic        wr_en;
    logic        rd1;
    logic        rd2;
    logic [$clog2(WIDTH)- 1: 0] counter;
    logic [WIDTH-1:0] read_data, read_data1, read_data2;

    // Instantiate DUT
    Register_File #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .i_clk(clk),
        .i_rstn(rstn),
        .i_datain(datain),
        .i_rd1_addr(rd1_addr),
        .i_rd2_addr(rd2_addr),
        .i_wr_addr(wr_addr),
        .i_wr_en(wr_en),
        .i_counter(counter)
        .o_rd1(rd1),
        .o_rd2(rd2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Task to write serial data to a register
    task write_register(input [1:0] addr, input [WIDTH-1:0] data);
        integer i;
        begin
            wr_addr = addr;
            wr_en = 1;
            // Shift in data LSB first
            for (i = 0; i < WIDTH; i = i + 1) begin
                datain = data[i];
                @(posedge clk);
            end
            wr_en = 0;
            datain = 0;
        end
    endtask

    // Task to read serial data from a register
    task read_register(input [1:0] addr, output [WIDTH-1:0] data);
        integer i;
        begin
            rd1_addr = addr;
            data = 0;
            // Read out data LSB first
            for (i = 0; i < WIDTH; i = i + 1) begin
                @(posedge clk);
                data[i] = rd1;
            end
        end
    endtask

    // Test procedure
    initial begin
        // Initialize signals
        rstn = 0;
        datain = 0;
        rd1_addr = 0;
        rd2_addr = 0;
        wr_addr = 0;
        wr_en = 0;

        // Reset
        repeat(2) @(posedge clk);
        rstn = 1;
        repeat(2) @(posedge clk);

        $display("=== Starting Register File Test ===");

        // Test 1: Write to register 0
        $display("\nTest 1: Writing 0xDEADBEEF to Register 0");
        write_register(2'h0, 32'hDEADBEEF);

        // Test 2: Write to register 1
        $display("Test 2: Writing 0x12345678 to Register 1");
        write_register(2'h1, 32'h12345678);

        // Test 3: Write to register 2
        $display("Test 3: Writing 0xAAAAAAAA to Register 2");
        write_register(2'h2, 32'hAAAAAAAA);

        // Test 4: Read back register 0
        $display("\nTest 4: Reading back Register 0");
        read_register(2'h0, read_data);
        $display("Read data = 0x%h", read_data);

        // Test 5: Simultaneous read from two registers
        $display("\nTest 5: Simultaneous read from Register 1 and 2");
        rd1_addr = 2'h1;
        rd2_addr = 2'h2;
        for (int i = 0; i < WIDTH; i++) begin
            @(posedge clk);
            read_data1[i] = rd1;
            read_data2[i] = rd2;
        end
        $display("Register 1 = 0x%h", read_data1);
        $display("Register 2 = 0x%h", read_data2);

        // Finish simulation
        repeat(5) @(posedge clk);
        $display("\n=== Test Complete ===");
        $finish;
    end

endmodule
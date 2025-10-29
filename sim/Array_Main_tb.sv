`timescale 1ns/1ps

module Array_Main_tb;

    // Parameters
    parameter ROWS = 2;
    parameter COLS = 2;
    parameter DATA_WIDTH = 32;
    parameter ARRAY_BASE_ADDR = 32'h0001_0000;
    parameter CLK_PERIOD = 10;
    
    // DUT signals
    logic i_clk;
    logic i_rstn;
    logic [3:0]  i_rd1_addr;
    logic [3:0]  i_rd2_addr;
    logic [3:0]  i_wr_addr;
    logic        i_wr_en;
    logic        i_rs2_sel;
    logic        i_news_sel;
    logic        i_wb_sel;
    logic [9:0]  i_opcode;
    logic        i_data_valid;
    logic [$clog2(DATA_WIDTH)-1:0] i_counter;
    logic        i_dataout_en;
    logic [31:0] i_address;
    
    // Test control
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;
    
    // Clock generation
    initial begin
        i_clk = 0;
        forever #(CLK_PERIOD/2) i_clk = ~i_clk;
    end
    
    // DUT instantiation
    Array_Main #(
        .ROWS(ROWS),
        .COLS(COLS),
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_BASE_ADDR(ARRAY_BASE_ADDR)
    ) dut (
        .i_clk(i_clk),
        .i_rstn(i_rstn),
        .i_rd1_addr(i_rd1_addr),
        .i_rd2_addr(i_rd2_addr),
        .i_wr_addr(i_wr_addr),
        .i_wr_en(i_wr_en),
        .i_rs2_sel(i_rs2_sel),
        .i_news_sel(i_news_sel),
        .i_wb_sel(i_wb_sel),
        .i_opcode(i_opcode),
        .i_data_valid(i_data_valid),
        .i_counter(i_counter),
        .i_dataout_en(i_dataout_en),
        .i_address(i_address)
    );
    
    // Task: Initialize all inputs
    task init_inputs();
        i_rstn = 1'b0;
        i_rd1_addr = 4'h0;
        i_rd2_addr = 4'h0;
        i_wr_addr = 4'h0;
        i_wr_en = 1'b0;
        i_rs2_sel = 1'b0;
        i_news_sel = 1'b0;
        i_wb_sel = 1'b0;
        i_opcode = 10'h0;
        i_data_valid = 1'b0;
        i_counter = '0;
        i_dataout_en = 1'b0;
        i_address = 32'h0;
    endtask
    
    // Task: Reset sequence
    task reset_dut();
        $display("[%0t] Applying reset...", $time);
        i_rstn = 1'b0;
        repeat(5) @(posedge i_clk);
        i_rstn = 1'b1;
        repeat(2) @(posedge i_clk);
        $display("[%0t] Reset released", $time);
    endtask
    
    // Task: Write to register file
    task write_register(input [3:0] addr, input logic data_valid);
        @(posedge i_clk);
        i_wr_addr = addr;
        i_wr_en = 1'b1;
        i_data_valid = data_valid;
        @(posedge i_clk);
        i_wr_en = 1'b0;
        i_data_valid = 1'b0;
    endtask
    
    // Task: Read from register file
    task read_register(input [3:0] rd1, input [3:0] rd2);
        @(posedge i_clk);
        i_rd1_addr = rd1;
        i_rd2_addr = rd2;
        @(posedge i_clk);
    endtask
    
    // Task: Execute operation
    task execute_op(input [9:0] opcode, input rs2_sel, input news_sel, input wb_sel);
        @(posedge i_clk);
        i_opcode = opcode;
        i_rs2_sel = rs2_sel;
        i_news_sel = news_sel;
        i_wb_sel = wb_sel;
        repeat(2) @(posedge i_clk);
        i_opcode = 10'h0;
    endtask
    
    // Task: Test counter increment
    task test_counter_sequence();
        $display("\n[%0t] === Test: Counter Sequence ===", $time);
        test_count++;
        
        for(int i = 0; i < DATA_WIDTH; i++) begin
            @(posedge i_clk);
            i_counter = i;
        end
        
        @(posedge i_clk);
        i_counter = '0;
        pass_count++;
        $display("[%0t] Counter sequence test PASSED", $time);
    endtask
    
    // Task: Test write enable
    task test_write_enable();
        $display("\n[%0t] === Test: Write Enable ===", $time);
        test_count++;
        
        // Write to different addresses
        for(int addr = 0; addr < 4; addr++) begin
            write_register(addr, 1'b1);
            $display("[%0t] Written to address %0d", $time, addr);
        end
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Write enable test PASSED", $time);
    endtask
    
    // Task: Test read operations
    task test_read_operations();
        $display("\n[%0t] === Test: Read Operations ===", $time);
        test_count++;
        
        // Test different read address combinations
        read_register(4'h0, 4'h1);
        $display("[%0t] Read from rd1=0, rd2=1", $time);
        
        read_register(4'h2, 4'h3);
        $display("[%0t] Read from rd1=2, rd2=3", $time);
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Read operations test PASSED", $time);
    endtask
    
    // Task: Test selector signals
    task test_selectors();
        $display("\n[%0t] === Test: Selector Signals ===", $time);
        test_count++;
        
        // Test rs2_sel
        @(posedge i_clk);
        i_rs2_sel = 1'b1;
        @(posedge i_clk);
        i_rs2_sel = 1'b0;
        
        // Test news_sel
        @(posedge i_clk);
        i_news_sel = 1'b1;
        @(posedge i_clk);
        i_news_sel = 1'b0;
        
        // Test wb_sel
        @(posedge i_clk);
        i_wb_sel = 1'b1;
        @(posedge i_clk);
        i_wb_sel = 1'b0;
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Selector signals test PASSED", $time);
    endtask
    
    // Task: Test operation execution
    task test_operations();
        $display("\n[%0t] === Test: Operation Execution ===", $time);
        test_count++;
        
        // Test different opcodes
        execute_op(10'h001, 1'b0, 1'b0, 1'b0);
        $display("[%0t] Executed opcode 0x001", $time);
        
        execute_op(10'h002, 1'b1, 1'b0, 1'b0);
        $display("[%0t] Executed opcode 0x002 with rs2_sel", $time);
        
        execute_op(10'h003, 1'b0, 1'b1, 1'b0);
        $display("[%0t] Executed opcode 0x003 with news_sel", $time);
        
        execute_op(10'h004, 1'b0, 1'b0, 1'b1);
        $display("[%0t] Executed opcode 0x004 with wb_sel", $time);
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Operation execution test PASSED", $time);
    endtask
    
    // Task: Test data output enable
    task test_dataout_enable();
        $display("\n[%0t] === Test: Data Output Enable ===", $time);
        test_count++;
        
        @(posedge i_clk);
        i_dataout_en = 1'b1;
        repeat(5) @(posedge i_clk);
        i_dataout_en = 1'b0;
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Data output enable test PASSED", $time);
    endtask
    
    // Task: Test memory mapped addressing
    task test_memory_addressing();
        $display("\n[%0t] === Test: Memory Mapped Addressing ===", $time);
        test_count++;
        
        // Test base address
        @(posedge i_clk);
        i_address = ARRAY_BASE_ADDR;
        $display("[%0t] Address = 0x%08h (BASE)", $time, i_address);
        
        // Test offset addresses
        @(posedge i_clk);
        i_address = ARRAY_BASE_ADDR + 32'h4;
        $display("[%0t] Address = 0x%08h (BASE+4)", $time, i_address);
        
        @(posedge i_clk);
        i_address = ARRAY_BASE_ADDR + 32'h100;
        $display("[%0t] Address = 0x%08h (BASE+256)", $time, i_address);
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Memory addressing test PASSED", $time);
    endtask
    
    // Task: Test combined operations
    task test_combined_operations();
        $display("\n[%0t] === Test: Combined Operations ===", $time);
        test_count++;
        
        // Write, read, and execute sequence
        write_register(4'h5, 1'b1);
        read_register(4'h5, 4'h6);
        execute_op(10'h010, 1'b1, 1'b1, 1'b0);
        
        @(posedge i_clk);
        i_dataout_en = 1'b1;
        repeat(3) @(posedge i_clk);
        i_dataout_en = 1'b0;
        
        repeat(2) @(posedge i_clk);
        pass_count++;
        $display("[%0t] Combined operations test PASSED", $time);
    endtask
    
    // Main test sequence
    initial begin
        $display("\n========================================");
        $display("Starting Array_Main Testbench");
        $display("ROWS=%0d, COLS=%0d, DATA_WIDTH=%0d", ROWS, COLS, DATA_WIDTH);
        $display("========================================\n");
        
        // Initialize
        init_inputs();
        
        // Reset
        reset_dut();
        
        // Run tests
        test_write_enable();
        test_read_operations();
        test_selectors();
        test_counter_sequence();
        test_operations();
        test_dataout_enable();
        test_memory_addressing();
        test_combined_operations();
        
        // Summary
        repeat(10) @(posedge i_clk);
        
        $display("\n========================================");
        $display("Testbench Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_count);
        $display("Passed:      %0d", pass_count);
        $display("Failed:      %0d", fail_count);
        
        if (fail_count == 0) begin
            $display("\n*** ALL TESTS PASSED ***\n");
        end else begin
            $display("\n*** SOME TESTS FAILED ***\n");
        end
        
        $display("========================================\n");
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #100000;
        $display("\n[ERROR] Testbench timeout!");
        $finish;
    end
    
    // Optional: Waveform dumping
    initial begin
        $dumpfile("array_main_tb.vcd");
        $dumpvars(0, tb_Array_Main);
    end

endmodule

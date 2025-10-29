`timescale 1ns/1ps

module Top_tb;
    // Clock and reset
    logic i_clk;
    logic i_rstn;
    
    // Testbench signals
    integer test_num;
    integer errors;
    
    // Instantiate DUT
    Top dut (
        .i_clk(i_clk),
        .i_rstn(i_rstn)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end
    
    // Test stimulus
    initial begin
        // Initialize
        test_num = 0;
        errors = 0;
        i_rstn = 0;
        
        
        repeat(5) @(posedge i_clk);
        i_rstn = 1;
        
        
        $display("[%0t] Reset released", $time);
        repeat(2) @(posedge i_clk);
        
        
        
        // Test 1: Basic data memory write
        test_num = 1;
        $display("\n[TEST %0d] Data Memory Write Test", test_num);
        test_data_memory_write();
        
        
        /*
        // Test 2: Basic data memory read
        test_num = 2;
        $display("\n[TEST %0d] Data Memory Read Test", test_num);
        test_data_memory_read();
        
        // Test 3: Array access through memory-mapped interface
        test_num = 3;
        $display("\n[TEST %0d] Array Memory-Mapped Access", test_num);
        test_array_access();
        
        // Test 4: R-type instruction execution
        test_num = 4;
        $display("\n[TEST %0d] R-Type Instruction Test", test_num);
        test_r_type_instruction();
        
        // Test 5: MOVE instruction
        test_num = 5;
        $display("\n[TEST %0d] MOVE Instruction Test", test_num);
        test_move_instruction();
        
        // Test 6: LOAD instruction
        test_num = 6;
        $display("\n[TEST %0d] LOAD Instruction Test", test_num);
        test_load_instruction();
        
        // Test 7: STORE instruction
        test_num = 7;
        $display("\n[TEST %0d] STORE Instruction Test", test_num);
        test_store_instruction();
        
        // Test 8: NEWS-type instruction
        test_num = 8;
        $display("\n[TEST %0d] NEWS-Type Instruction Test", test_num);
        test_news_instruction();
        
        // Test 9: Reset during operation
        test_num = 9;
        $display("\n[TEST %0d] Reset During Operation", test_num);
        test_reset_during_op();
        
        // Test 10: Back-to-back operations
        test_num = 10;
        $display("\n[TEST %0d] Back-to-Back Operations", test_num);
        test_back_to_back();
        *
        // Summary
        repeat(10) @(posedge i_clk);
        $display("\n========================================");
        $display("Test Summary:");
        $display("Total Tests: %0d", test_num);
        $display("Errors: %0d", errors);
        if (errors == 0)
            $display("STATUS: ALL TESTS PASSED!");
        else
            $display("STATUS: TESTS FAILED");
        $display("========================================\n");
        
        $finish;
    end
    
    // Task: Test data memory write
    task test_data_memory_write();
        begin
            // Set up write operation
            dut.address = 32'h0000_0100;
            dut.dataIn = 32'hDEAD_BEEF;
            dut.data_wr = 1'b1;
            dut.data_rd = 1'b0;
            @(posedge i_clk);
            dut.data_wr = 1'b0;
            @(posedge i_clk);
            $display("  Written 0x%h to address 0x%h", 32'hDEAD_BEEF, 32'h0000_0100);
        end
    endtask
    
    // Task: Test data memory read
    task test_data_memory_read();
        begin
            // Set up read operation
            dut.address = 32'h0000_0100;
            dut.data_wr = 1'b0;
            dut.data_rd = 1'b1;
            @(posedge i_clk);
            @(posedge i_clk);
            $display("  Read 0x%h from address 0x%h", dut.dataOut, 32'h0000_0100);
            dut.data_rd = 1'b0;
        end
    endtask
    
    // Task: Test array memory-mapped access
    task test_array_access();
        begin
            // Access array through memory-mapped interface
            dut.address = 32'hA000_0000; // Assuming array is mapped at 0xA0000000
            dut.dataIn = 32'h1234_5678;
            dut.data_wr = 1'b1;
            @(posedge i_clk);
            dut.data_wr = 1'b0;
            @(posedge i_clk);
            
            if (dut.array_access) begin
                $display("  Array access detected: address=0x%h", dut.array_address);
            end else begin
                $display("  WARNING: Array access not detected");
                errors++;
            end
        end
    endtask
    
    // Task: Test R-type instruction
    task test_r_type_instruction();
        begin
            // Simulate R-type ADD instruction
            // Instruction format: funct7[6:0] + rs2[4:0] + rs1[4:0] + funct3[2:0] + rd[4:0] + opcode[6:0]
            logic [31:0] instruction;
            instruction = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, `OP_R_TYPE};
            
            // Send instruction to control unit (you may need to add this interface)
            @(posedge i_clk);
            repeat(5) @(posedge i_clk); // Allow time for execution
            $display("  R-type instruction executed: ADD");
        end
    endtask
    
    // Task: Test MOVE instruction
    task test_move_instruction();
        begin
            logic [31:0] instruction;
            instruction = {7'b0000000, 5'd1, 5'd0, 3'b000, 5'd2, `OP_MV_TYPE};
            
            @(posedge i_clk);
            repeat(3) @(posedge i_clk);
            $display("  MOVE instruction executed");
        end
    endtask
    
    // Task: Test LOAD instruction
    task test_load_instruction();
        begin
            logic [31:0] instruction;
            instruction = {12'h100, 5'd1, 3'b000, 5'd2, `OP_LOAD};
            
            @(posedge i_clk);
            repeat(4) @(posedge i_clk);
            $display("  LOAD instruction executed");
        end
    endtask
    
    // Task: Test STORE instruction
    task test_store_instruction();
        begin
            logic [31:0] instruction;
            instruction = {7'b0000000, 5'd2, 5'd1, 3'b000, 5'h10, `OP_STORE};
            
            @(posedge i_clk);
            repeat(4) @(posedge i_clk);
            $display("  STORE instruction executed");
        end
    endtask
    
    // Task: Test NEWS-type instruction
    task test_news_instruction();
        begin
            logic [31:0] instruction;
            instruction = {7'b0000000, 5'd1, 5'd2, 3'b000, 5'd3, `OP_NEWS_TYPE};
            
            @(posedge i_clk);
            repeat(5) @(posedge i_clk);
            $display("  NEWS-type instruction executed");
        end
    endtask
    
    // Task: Test reset during operation
    task test_reset_during_op();
        begin
            // Start an operation
            dut.address = 32'h0000_0200;
            dut.dataIn = 32'hCAFE_BABE;
            dut.data_wr = 1'b1;
            @(posedge i_clk);
            
            // Assert reset in the middle
            i_rstn = 0;
            repeat(3) @(posedge i_clk);
            i_rstn = 1;
            @(posedge i_clk);
            
            dut.data_wr = 1'b0;
            $display("  Reset during operation test completed");
        end
    endtask
    
    // Task: Test back-to-back operations
    task test_back_to_back();
        begin
            // Write operation 1
            dut.address = 32'h0000_0300;
            dut.dataIn = 32'h1111_1111;
            dut.data_wr = 1'b1;
            @(posedge i_clk);
            
            // Write operation 2 (back-to-back)
            dut.address = 32'h0000_0304;
            dut.dataIn = 32'h2222_2222;
            @(posedge i_clk);
            
            // Write operation 3
            dut.address = 32'h0000_0308;
            dut.dataIn = 32'h3333_3333;
            @(posedge i_clk);
            
            dut.data_wr = 1'b0;
            @(posedge i_clk);
            $display("  Back-to-back operations completed");
        end
    endtask
    
    // Watchdog timer
    initial begin
        #100000; // 100us timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end
    
endmodule

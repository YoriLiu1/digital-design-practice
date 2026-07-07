//==============================================================================
// tb_sync_fifo.v — Testbench for sync_fifo (synchronous FIFO)
//==============================================================================
// Tests:
//  1. Write 8 values (0..7), read back 8, check data integrity
//  2. Write until full (DEPTH=16), verify full asserts
//  3. Read until empty, verify empty asserts
//  4. Simultaneous write+read: pre-fill 4, then alternately write one and
//     read one for 4 cycles
//
// All stimulus driven on negedge clk to avoid races with the DUT.
//==============================================================================

`timescale 1ns / 1ps

module tb_sync_fifo;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    parameter WIDTH = 8;
    parameter DEPTH = 16;
    parameter CLK_PERIOD = 10;          // 100 MHz

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg             clk;
    reg             rst_n;
    reg             wr_en;
    reg  [WIDTH-1:0] wr_data;
    wire            full;
    reg             rd_en;
    wire [WIDTH-1:0] rd_data;
    wire            empty;

    //--------------------------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------------------------
    sync_fifo #(
        .WIDTH (WIDTH),
        .DEPTH (DEPTH)
    ) u_dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .wr_en  (wr_en),
        .wr_data(wr_data),
        .full   (full),
        .rd_en  (rd_en),
        .rd_data(rd_data),
        .empty  (empty)
    );

    //--------------------------------------------------------------------------
    // Clock Generation
    //--------------------------------------------------------------------------
    initial clk = 0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    //--------------------------------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_sync_fifo);
    end

    //--------------------------------------------------------------------------
    // Test Variables
    //--------------------------------------------------------------------------
    integer            i;
    reg  [WIDTH-1:0]   expected;
    reg                test_pass;
    integer            total_pass;
    integer            total_fail;

    //--------------------------------------------------------------------------
    // Task: Wait N clock cycles (posedge)
    //--------------------------------------------------------------------------
    task wait_clk;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge clk);
        end
    endtask

    //--------------------------------------------------------------------------
    // Task: Write a single value (stimulus on negedge)
    //       1 full cycle of wr_en=1
    //--------------------------------------------------------------------------
    task write_fifo;
        input [WIDTH-1:0] data;
        begin
            @(negedge clk);
            wr_en   = 1;
            wr_data = data;
            @(negedge clk);
            wr_en   = 0;
        end
    endtask

    //--------------------------------------------------------------------------
    // Task: Read a single value (stimulus on negedge)
    //       Assert rd_en, capture rd_data on next negedge, then deassert
    //--------------------------------------------------------------------------
    task read_fifo;
        output [WIDTH-1:0] data;
        begin
            @(negedge clk);
            rd_en = 1;
            @(negedge clk);
            data  = rd_data;
            rd_en = 0;
        end
    endtask

    //--------------------------------------------------------------------------
    // Task: Record test result
    //--------------------------------------------------------------------------
    task check;
        input [255*8:1] test_name;
        input            condition;
        begin
            if (condition) begin
                $display("[PASS] %0s", test_name);
                total_pass = total_pass + 1;
            end else begin
                $display("[FAIL] %0s", test_name);
                total_fail = total_fail + 1;
            end
        end
    endtask

    //--------------------------------------------------------------------------
    // Main Test Sequence
    //--------------------------------------------------------------------------
    initial begin
        // Initialization
        wr_en   = 0;
        wr_data = 0;
        rd_en   = 0;
        total_pass = 0;
        total_fail = 0;

        // Reset
        $display("============================================================");
        $display("  sync_fifo Testbench Starting...");
        $display("============================================================");
        rst_n = 0;
        wait_clk(5);
        rst_n = 1;
        wait_clk(2);

        //======================================================================
        // TEST 1: Write 8 values, then read them back
        //======================================================================
        $display("");
        $display("--- Test 1: Write 8 values (0..7), then read back ---");

        for (i = 0; i < 8; i = i + 1)
            write_fifo(i[WIDTH-1:0]);

        test_pass = 1;
        for (i = 0; i < 8; i = i + 1) begin
            read_fifo(expected);
            if (expected !== i[WIDTH-1:0]) begin
                $display("  Mismatch at idx %0d: expected %0d, got %0d", i, i, expected);
                test_pass = 0;
            end
        end
        check("Test 1: Write-then-read data integrity", test_pass);
        check("Test 1: FIFO empty after reading all", empty === 1'b1);

        //======================================================================
        // TEST 2: Write until full
        //======================================================================
        $display("");
        $display("--- Test 2: Write until full (DEPTH=%0d) ---", DEPTH);

        for (i = 0; i < DEPTH; i = i + 1)
            write_fifo(i[WIDTH-1:0]);

        check("Test 2: full asserted after DEPTH writes", full === 1'b1);

        // Attempt one more write — full should stay asserted
        @(negedge clk);
        wr_en   = 1;
        wr_data = 8'hFF;
        @(negedge clk);
        wr_en   = 0;
        check("Test 2: full remains high on overflow write", full === 1'b1);

        //======================================================================
        // TEST 3: Read until empty
        //======================================================================
        $display("");
        $display("--- Test 3: Read until empty ---");

        test_pass = 1;
        for (i = 0; i < DEPTH; i = i + 1) begin
            read_fifo(expected);
            if (expected !== i[WIDTH-1:0]) begin
                $display("  Mismatch at idx %0d: expected %0d, got %0d", i, i, expected);
                test_pass = 0;
            end
        end
        check("Test 3: Data integrity after reading all", test_pass);
        check("Test 3: empty asserted after reading all entries", empty === 1'b1);

        // Attempt one more read — empty should stay asserted
        @(negedge clk);
        rd_en = 1;
        @(negedge clk);
        rd_en = 0;
        check("Test 3: empty remains high on underflow read", empty === 1'b1);

        //======================================================================
        // TEST 4: Simultaneous write+read
        //======================================================================
        $display("");
        $display("--- Test 4: Simultaneous write+read ---");

        // Pre-fill 4 values so we can do simultaneous r/w
        for (i = 0; i < 4; i = i + 1)
            write_fifo(i[WIDTH-1:0]);

        // Alternately write one and read one for 4 cycles
        test_pass = 1;
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk);
            wr_en   = 1;
            wr_data = i + 4;
            rd_en   = 1;
            @(negedge clk);
            wr_en   = 0;
            rd_en   = 0;
            // Check the value we read
            if (rd_data !== i[WIDTH-1:0]) begin
                $display("  Simul r/w mismatch: expected %0d, got %0d", i, rd_data);
                test_pass = 0;
            end
        end
        check("Test 4: Simultaneous write+read data integrity", test_pass);

        //======================================================================
        // Summary
        //======================================================================
        $display("");
        $display("============================================================");
        $display("  Testbench Complete: %0d PASS, %0d FAIL", total_pass, total_fail);
        $display("============================================================");
        if (total_fail > 0)
            $display("  *** SOME TESTS FAILED ***");
        else
            $display("  *** ALL TESTS PASSED ***");

        #100;
        $finish;
    end

endmodule

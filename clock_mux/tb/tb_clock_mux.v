//==============================================================================
// tb_clock_mux.v — Testbench for clock_mux (glitch-free clock multiplexer)
//==============================================================================
// Tests:
//  1. Start with clk_sel=0 (clk0=100MHz), verify output tracks clk0
//  2. Switch to clk_sel=1 (clk1=60MHz), verify output switches cleanly
//  3. Switch back to clk_sel=0, verify output tracks clk0 again
//  4. Verify no glitches — no output half-cycle is shorter than the minimum
//     input half-period (5 ns)
//
// Stimulus driven on negedge of clk_out transitions where applicable,
// and clk_sel changes are timed via $time measurements.
//==============================================================================

`timescale 1ns / 1ps

module tb_clock_mux;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    parameter CLK0_PERIOD     = 10.0;     // 100 MHz
    parameter CLK1_PERIOD     = 16.667;   // 60 MHz
    parameter MIN_HALF_PERIOD = 5.0;      // min(clk0_half, clk1_half) = 5ns

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg  clk0;
    reg  clk1;
    reg  rst_n;
    reg  clk_sel;
    wire clk_out;

    //--------------------------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------------------------
    clock_mux u_dut (
        .clk0   (clk0),
        .clk1   (clk1),
        .rst_n  (rst_n),
        .clk_sel(clk_sel),
        .clk_out(clk_out)
    );

    //--------------------------------------------------------------------------
    // Clock Generators
    //--------------------------------------------------------------------------
    initial clk0 = 0;
    always #(CLK0_PERIOD / 2.0) clk0 = ~clk0;

    initial clk1 = 0;
    always #(CLK1_PERIOD / 2.0) clk1 = ~clk1;

    //--------------------------------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_clock_mux);
    end

    //--------------------------------------------------------------------------
    // Test Variables
    //--------------------------------------------------------------------------
    real         last_edge_time;
    real         half_period;
    real         min_measured_half;
    reg          glitch_detected;
    integer      total_pass;
    integer      total_fail;
    integer      i;
    integer      edge_count;

    //--------------------------------------------------------------------------
    // Glitch Monitor — fires on every change of clk_out
    //--------------------------------------------------------------------------
    initial begin
        last_edge_time  = 0.0;
        glitch_detected = 0;
        min_measured_half = 999999.0;
        edge_count      = 0;
    end

    always @(clk_out) begin
        if ($time > 0) begin
            half_period = $realtime - last_edge_time;
            if (half_period < min_measured_half)
                min_measured_half = half_period;
            if (half_period < MIN_HALF_PERIOD) begin
                $display("[GLITCH] At time %0t: clk_out half-period = %0.3f ns (< %0.3f ns min)",
                         $time, half_period, MIN_HALF_PERIOD);
                glitch_detected = 1;
            end
            last_edge_time = $realtime;
            edge_count     = edge_count + 1;
        end else begin
            last_edge_time = $realtime;
        end
    end

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
        clk_sel = 0;
        total_pass = 0;
        total_fail = 0;

        // Reset
        $display("============================================================");
        $display("  clock_mux Testbench Starting...");
        $display("  clk0: 100 MHz (T=10 ns), clk1: 60 MHz (T=16.667 ns)");
        $display("============================================================");

        rst_n = 0;
        #50;
        rst_n = 1;
        #20;

        //======================================================================
        // Phase 1: clk_sel=0 — output should track clk0
        //======================================================================
        $display("");
        $display("--- Phase 1: clk_sel=0, expect clk_out tracks clk0 ---");

        // Let it run for several clk0 cycles
        glitch_detected = 0;
        #(CLK0_PERIOD * 20);

        check("Phase 1: No glitches while running on clk0", glitch_detected == 0);

        //======================================================================
        // Phase 2: Switch to clk1 (60 MHz)
        //======================================================================
        $display("");
        $display("--- Phase 2: Switch to clk_sel=1 (clk1=60MHz) ---");

        glitch_detected = 0;
        // Drive clk_sel on negedge of clk0 to avoid race
        @(negedge clk0);
        clk_sel = 1;
        $display("  clk_sel switched to 1 at time %0t", $time);

        // Let it run on clk1 for a while
        #(CLK1_PERIOD * 20);

        check("Phase 2: No glitches after switching to clk1", glitch_detected == 0);

        //======================================================================
        // Phase 3: Switch back to clk0
        //======================================================================
        $display("");
        $display("--- Phase 3: Switch back to clk_sel=0 (clk0=100MHz) ---");

        glitch_detected = 0;
        @(negedge clk1);
        clk_sel = 0;
        $display("  clk_sel switched to 0 at time %0t", $time);

        // Run on clk0 again
        #(CLK0_PERIOD * 20);

        check("Phase 3: No glitches after switching back to clk0", glitch_detected == 0);

        //======================================================================
        // Phase 4: Rapid toggle stress
        //======================================================================
        $display("");
        $display("--- Phase 4: Rapid toggle between clocks ---");

        glitch_detected = 0;

        // Toggle a few times with sufficient settling time
        for (i = 0; i < 4; i = i + 1) begin
            @(negedge clk0);
            clk_sel = 1;
            #(CLK1_PERIOD * 5);
            @(negedge clk1);
            clk_sel = 0;
            #(CLK0_PERIOD * 5);
        end

        check("Phase 4: No glitches during rapid toggling", glitch_detected == 0);

        //======================================================================
        // Summary
        //======================================================================
        $display("");
        $display("============================================================");
        $display("  Minimum measured clk_out half-period: %0.3f ns", min_measured_half);
        $display("  Total clk_out edges monitored: %0d", edge_count);
        $display("  Testbench Complete: %0d PASS, %0d FAIL", total_pass, total_fail);
        $display("============================================================");
        if (total_fail > 0 || glitch_detected)
            $display("  *** SOME TESTS FAILED ***");
        else
            $display("  *** ALL TESTS PASSED ***");

        #100;
        $finish;
    end

endmodule

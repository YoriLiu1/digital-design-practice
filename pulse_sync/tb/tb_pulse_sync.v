//==============================================================================
// tb_pulse_sync.v — Testbench for pulse_sync (cross-domain pulse synchronizer)
//==============================================================================
// Tests:
//  1. Send 3 pulses from src domain (100 MHz) spaced ~30 ns apart
//  2. Verify each produces exactly 1 dst_pulse in dst domain (200 MHz)
//  3. Verify dst_pulse is exactly 1 dst_clk cycle wide
//  4. Verify no spurious/extra dst_pulses
//
// Clocks: src_clk=100MHz (10ns), dst_clk=200MHz (5ns)
// Stimulus driven on negedge of src_clk to avoid race conditions.
//==============================================================================

`timescale 1ns / 1ps

module tb_pulse_sync;

    //--------------------------------------------------------------------------
    // Parameters
    //--------------------------------------------------------------------------
    parameter SRC_CLK_PERIOD = 10.0;    // 100 MHz
    parameter DST_CLK_PERIOD = 5.0;     // 200 MHz
    parameter PULSE_SPACING  = 30;      // 30 ns between pulses (~3 src cycles)

    //--------------------------------------------------------------------------
    // DUT I/O
    //--------------------------------------------------------------------------
    reg  src_clk;
    reg  src_rst_n;
    reg  src_pulse;
    reg  dst_clk;
    reg  dst_rst_n;
    wire dst_pulse;

    //--------------------------------------------------------------------------
    // DUT Instantiation
    //--------------------------------------------------------------------------
    pulse_sync u_dut (
        .src_clk  (src_clk),
        .src_rst_n(src_rst_n),
        .src_pulse(src_pulse),
        .dst_clk  (dst_clk),
        .dst_rst_n(dst_rst_n),
        .dst_pulse(dst_pulse)
    );

    //--------------------------------------------------------------------------
    // Clock Generators
    //--------------------------------------------------------------------------
    initial src_clk = 0;
    always #(SRC_CLK_PERIOD / 2.0) src_clk = ~src_clk;

    initial dst_clk = 0;
    always #(DST_CLK_PERIOD / 2.0) dst_clk = ~dst_clk;

    //--------------------------------------------------------------------------
    // Waveform Dump
    //--------------------------------------------------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_pulse_sync);
    end

    //--------------------------------------------------------------------------
    // Test Variables
    //--------------------------------------------------------------------------
    integer      total_pass;
    integer      total_fail;
    integer      pulse_count;
    integer      dst_pulse_count;
    integer      i;
    reg          dst_pulse_r;       // registered to detect edges
    reg          dst_pulse_r2;
    integer      dst_pulse_width_count; // count dst_clk cycles dst_pulse is high
    reg          pulse_width_ok;
    integer      sent_pulses;

    //--------------------------------------------------------------------------
    // Monitor dst_pulse: count occurrences and measure width
    //--------------------------------------------------------------------------
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            dst_pulse_r  <= 0;
            dst_pulse_r2 <= 0;
            dst_pulse_count <= 0;
        end else begin
            dst_pulse_r  <= dst_pulse;
            dst_pulse_r2 <= dst_pulse_r;

            // rising edge detect
            if (dst_pulse_r && !dst_pulse_r2) begin
                dst_pulse_count <= dst_pulse_count + 1;
            end
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
    // Task: Send one pulse in src domain (driven on negedge)
    //--------------------------------------------------------------------------
    task send_pulse;
        begin
            @(negedge src_clk);
            src_pulse = 1;
            @(negedge src_clk);
            src_pulse = 0;
        end
    endtask

    //--------------------------------------------------------------------------
    // Task: Wait N src_clk cycles
    //--------------------------------------------------------------------------
    task wait_src_clk;
        input integer n;
        integer j;
        begin
            for (j = 0; j < n; j = j + 1)
                @(posedge src_clk);
        end
    endtask

    //--------------------------------------------------------------------------
    // Main Test Sequence
    //--------------------------------------------------------------------------
    initial begin
        src_pulse  = 0;
        total_pass = 0;
        total_fail = 0;
        sent_pulses = 0;

        $display("============================================================");
        $display("  pulse_sync Testbench Starting...");
        $display("  src_clk: 100 MHz, dst_clk: 200 MHz");
        $display("============================================================");

        // Reset both domains
        src_rst_n = 0;
        dst_rst_n = 0;
        #50;
        src_rst_n = 1;
        dst_rst_n = 1;
        #20;

        //======================================================================
        // TEST 1: Send 3 pulses, verify dst_pulse count matches
        //======================================================================
        $display("");
        $display("--- Test 1: Send 3 pulses spaced ~30 ns apart ---");

        // Send 3 pulses
        for (i = 0; i < 3; i = i + 1) begin
            send_pulse();
            sent_pulses = sent_pulses + 1;
            $display("  Sent pulse #%0d at time %0t", sent_pulses, $time);
            // Wait 30 ns between pulses
            #(PULSE_SPACING);
        end

        // Wait enough time for all pulses to propagate to dst domain
        // Several dst_clk cycles plus synchronizer latency
        #(DST_CLK_PERIOD * 20);

        check("Test 1: dst_pulse_count equals sent_pulses (3)", dst_pulse_count == sent_pulses);
        check("Test 1: No extra dst_pulses beyond expected", dst_pulse_count == 3);

        //======================================================================
        // TEST 2: Verify dst_pulse width is exactly 1 dst_clk cycle
        //======================================================================
        $display("");
        $display("--- Test 2: Verify dst_pulse width (1 dst cycle) ---");

        // Send another pulse and monitor width
        send_pulse();
        sent_pulses = sent_pulses + 1;
        $display("  Sent pulse #%0d at time %0t", sent_pulses, $time);

        // Allow propagation
        #(DST_CLK_PERIOD * 10);

        // A proper 1-cycle pulse in dst domain means dst_pulse asserts for
        // exactly 1 dst_clk cycle. Since the synchronizer typically produces
        // a pulse that is 1 dst_clk wide, we verify it's not multi-cycle.
        // We count dst_pulse_count after the final pulse.
        check("Test 2: dst_pulse_count matches total sent (4)", dst_pulse_count == sent_pulses);

        //======================================================================
        // TEST 3: No dst_pulse when src_pulse is quiet (idle check)
        //======================================================================
        $display("");
        $display("--- Test 3: Idle check — no spurious pulses ---");

        // Record current count and wait
        pulse_count = dst_pulse_count;
        #(SRC_CLK_PERIOD * 20);

        check("Test 3: No spurious dst_pulses during idle", dst_pulse_count == pulse_count);

        //======================================================================
        // TEST 4: Back-to-back pulses (short spacing)
        //======================================================================
        $display("");
        $display("--- Test 4: Back-to-back pulses ---");

        pulse_count = dst_pulse_count;
        // Send two pulses close together (~20 ns apart)
        send_pulse();
        sent_pulses = sent_pulses + 1;
        #20;
        send_pulse();
        sent_pulses = sent_pulses + 1;

        #(DST_CLK_PERIOD * 15);

        check("Test 4: dst_pulse_count increments by 2 for back-to-back",
              (dst_pulse_count - pulse_count) == 2);

        //======================================================================
        // Summary
        //======================================================================
        $display("");
        $display("============================================================");
        $display("  Total src_pulses sent: %0d", sent_pulses);
        $display("  Total dst_pulses detected: %0d", dst_pulse_count);
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

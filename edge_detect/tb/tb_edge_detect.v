// ============================================================================
// edge_detect (边缘检测) 测试平台
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 测试项目:
//   1. 信号 0→1 上升沿检测 → pos_edge=1
//   2. 信号 1→0 下降沿检测 → neg_edge=1
//   3. 双边沿检测 → both_edge=1 (pos_edge | neg_edge)
//   4. 信号保持期间无脉冲
//
// 信号序列: 0 → 1 → 1 → 0 → 0 → 1 → 1 → 1 → 0
//            | pos |     | neg |     | pos |...  | neg
// ============================================================================

`timescale 1ns / 1ps

module tb_edge_detect;

    reg  clk;
    reg  rst_n;
    reg  signal;
    wire pos_edge;
    wire neg_edge;
    wire both_edge;

    // ---- 实例化 DUT ----
    edge_detect u_dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .signal   (signal),
        .pos_edge (pos_edge),
        .neg_edge (neg_edge),
        .both_edge(both_edge)
    );

    // ---- 时钟: 100MHz (周期 10ns) ----
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_edge_detect);
    end

    // ---- 监控 (下降沿采样, 避免竞争) ----
    always @(negedge clk) begin
        if (rst_n)
            $display("time=%0t | signal=%b | pos=%b neg=%b both=%b",
                     $time, signal, pos_edge, neg_edge, both_edge);
    end

    // ========================================================================
    // 检查任务: 在下降沿检查边沿输出
    // ========================================================================
    task check_edges;
        input exp_pos;
        input exp_neg;
        input exp_both;
        begin
            @(negedge clk);
            if (pos_edge  !== exp_pos) begin
                $display("  [FAIL] pos_edge=%b, expected %b (time=%0t)", pos_edge, exp_pos, $time);
            end else if (neg_edge !== exp_neg) begin
                $display("  [FAIL] neg_edge=%b, expected %b (time=%0t)", neg_edge, exp_neg, $time);
            end else if (both_edge !== exp_both) begin
                $display("  [FAIL] both_edge=%b, expected %b (time=%0t)", both_edge, exp_both, $time);
            end else begin
                $display("  [PASS] pos=%b neg=%b both=%b", pos_edge, neg_edge, both_edge);
            end
        end
    endtask

    // ========================================================================
    // 测试
    // ========================================================================
    reg [7:0] pass_cnt, fail_cnt;
    integer    i;

    initial begin
        pass_cnt = 0;
        fail_cnt = 0;

        signal = 1'b0;
        rst_n  = 1'b0;

        // 复位
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("============================================");
        $display(" edge_detect (边缘检测) 测试开始");
        $display(" 时钟: 100MHz (周期 10ns)");
        $display("============================================\n");

        // --------------------------------------------------
        // 信号序列: 0 → 1 → 1 → 0 → 0 → 1 → 1 → 1 → 0
        // 每个值保持至少 2 拍, 确保边沿脉冲可见
        // --------------------------------------------------

        // --- Step 0: 初始 0, 无变化 ---
        $display("--- 初始状态: signal=0 (保持) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // --- Step 1: 0 → 1 (上升沿) ---
        $display("\n--- 上升沿: signal 0→1 ---");
        @(negedge clk);
        signal = 1'b1;
        check_edges(1'b1, 1'b0, 1'b1);

        // --- Step 2: 1 保持 ---
        $display("\n--- 保持 1: signal=1 (应无脉冲) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // --- Step 3: 1 → 0 (下降沿) ---
        $display("\n--- 下降沿: signal 1→0 ---");
        @(negedge clk);
        signal = 1'b0;
        check_edges(1'b0, 1'b1, 1'b1);

        // --- Step 4: 0 保持 ---
        $display("\n--- 保持 0: signal=0 (应无脉冲) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // --- Step 5: 0 → 1 (上升沿) ---
        $display("\n--- 上升沿: signal 0→1 ---");
        @(negedge clk);
        signal = 1'b1;
        check_edges(1'b1, 1'b0, 1'b1);

        // --- Step 6: 1 保持 ---
        $display("\n--- 保持 1: signal=1 (应无脉冲) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // --- Step 7: 1 保持 ---
        $display("\n--- 保持 1: signal=1 (应无脉冲) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // --- Step 8: 1 → 0 (下降沿) ---
        $display("\n--- 下降沿: signal 1→0 ---");
        @(negedge clk);
        signal = 1'b0;
        check_edges(1'b0, 1'b1, 1'b1);

        // --- Step 9: 0 保持 ---
        $display("\n--- 保持 0: signal=0 (应无脉冲) ---");
        check_edges(1'b0, 1'b0, 1'b0);

        // ============================================================
        $display("\n============================================");
        $display(" edge_detect 测试全部完成");
        $display("============================================");

        repeat (4) @(posedge clk);
        $finish;
    end

endmodule

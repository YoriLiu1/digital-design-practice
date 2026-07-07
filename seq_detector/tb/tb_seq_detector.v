// ============================================================================
// seq_detector (序列检测器 "1101") 测试平台
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 待检测序列: "1101" (支持重叠匹配)
//
// 测试 bitstream: 1 1 0 1 1 0 1
// 期望 match: 在 bit4 和 bit7 各产生 1 拍脉冲 (重叠)
//   第一个 "1101": bit 1-4 → match@bit4
//   重叠: bit4 的 1 作为下一个 "1101" 的首位
//   第二个 "1101": bit 4-7 → match@bit7
//
// match 为 Mealy 型输出 (state==S110 && din==1 时 match=1).
// din 在下降沿驱动; match 在下一个下降沿采样,
// 因为 match 在下降沿到上升沿之间有效 (组合逻辑基于旧 state + 新 din).
// 使用 #1 延迟确保组合逻辑稳定后再采样.
// ============================================================================

`timescale 1ns / 1ps

module tb_seq_detector;

    reg  clk;
    reg  rst_n;
    reg  din;
    wire match;

    // ---- 实例化 DUT ----
    seq_detector u_dut (
        .clk  (clk),
        .rst_n(rst_n),
        .din  (din),
        .match(match)
    );

    // ---- 时钟: 100MHz (周期 10ns) ----
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_seq_detector);
    end

    // ---- 监控 (下降沿采样, 加 #1 看组合逻辑稳定后的值) ----
    always @(negedge clk) begin
        #1;
        if (rst_n)
            $display("time=%0t | din=%b match=%b state=%0d",
                     $time, din, match, u_dut.state);
    end

    // ========================================================================
    // 测试
    // ========================================================================
    // bitstream:  1  1  0  1  1  0  1
    // expected:   0  0  0  1  0  0  1
    // index [6:0] — MSB first (bit6 先发)
    // ========================================================================
    integer   i;
    integer   pass_cnt, fail_cnt;
    reg [6:0] bitstream;
    reg [6:0] exp_match;
    reg [6:0] got_match;

    initial begin
        din  = 1'b0;
        rst_n = 1'b0;

        // 复位
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("============================================");
        $display(" seq_detector (序列检测器) 测试开始");
        $display(" 待检测序列: 1101 (重叠匹配)");
        $display(" 时钟: 100MHz (周期 10ns)");
        $display("============================================\n");

        bitstream = 7'b1101101;       // bit[6] 先发 (MSB first)
        exp_match = 7'b0001001;       // 期望 match: bit4=1, bit7=1

        got_match = 7'd0;
        pass_cnt  = 0;
        fail_cnt  = 0;

        $display("--- 发送 bitstream: 1 1 0 1 1 0 1 ---\n");

        for (i = 6; i >= 0; i = i - 1) begin
            // 在下降沿驱动 din (避免竞争)
            @(negedge clk);
            din = bitstream[i];

            // 等待组合逻辑稳定 (Mealy 输出: state=S110 + din 更新)
            // match 在下降沿后的半个周期内有效
            #1;

            got_match[i] = match;

            if (match === exp_match[i]) begin
                $display("  bit%0d: din=%b match=%b (exp %b) [PASS]",
                         7-i, din, match, exp_match[i]);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("  bit%0d: din=%b match=%b (exp %b) [FAIL]",
                         7-i, din, match, exp_match[i]);
                fail_cnt = fail_cnt + 1;
            end
        end

        // ---- 总结 ----
        $display("\n--- 结果汇总 ---");
        $display("  期望:  %b", exp_match);
        $display("  实际:  %b", got_match);
        if (got_match === exp_match) begin
            $display("  [PASS] 序列检测正确!");
        end else begin
            $display("  [FAIL] 序列检测有误!");
            fail_cnt = fail_cnt + 1;
        end
        $display("  位比对 PASS: %0d / FAIL: %0d", pass_cnt, fail_cnt);

        // ---- 附加: 空闲时 match 应为 0 ----
        $display("\n--- 空闲检查: din=0 保持, match 应为 0 ---");
        @(negedge clk);
        din = 1'b0;
        repeat (3) begin
            @(negedge clk);
            #1;
            if (match !== 1'b0) begin
                $display("  [FAIL] 空闲时 match=%b (time=%0t)", match, $time);
                fail_cnt = fail_cnt + 1;
            end
        end
        $display("  空闲检查完成");

        // ============================================================
        $display("\n============================================");
        $display(" seq_detector 测试全部完成");
        if (fail_cnt == 0)
            $display("  所有测试通过!");
        else
            $display("  共 %0d 项失败!", fail_cnt);
        $display("============================================");

        repeat (4) @(posedge clk);
        $finish;
    end

endmodule

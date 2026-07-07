// ============================================================================
// Glitch-Free 时钟切换 - Glitch-Free Clock Mux
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 两个时钟源之间无毛刺切换, 输出时钟不会出现窄脉冲
//
// 原理:
//   1. sel 变化 → 目标时钟的"关闭当前→开启目标"流程
//   2. 先在当前时钟域把当前 enable 拉低 (sync negedge)
//   3. 等待两个 cycle 确保关闭
//   4. 再在目标时钟域把目标 enable 拉高 (sync negedge)
//
// 关键: 所有 enable 信号都在各自时钟域的下降沿切换, 避免毛刺
//
// 参数:
//   CLK_SEL: 0 = clk0, 1 = clk1
// ============================================================================

module clock_mux (
    input  clk0,
    input  clk1,
    input  rst_n,
    input  clk_sel,          // 0: clk0, 1: clk1
    output clk_out
);

    reg en0, en1;             // 各自时钟域的使能
    reg en0_sync, en1_sync;   // 跨时钟域同步

    // ---- clk0 域: en0 控制 ----
    always @(negedge clk0 or negedge rst_n) begin
        if (!rst_n)
            en0 <= 1'b1;                     // 复位默认选 clk0
        else
            en0 <= !clk_sel && !en1_sync;    // 选 clk0 且 clk1 已关闭
    end

    // ---- clk1 域: en1 控制 ----
    always @(negedge clk1 or negedge rst_n) begin
        if (!rst_n)
            en1 <= 1'b0;
        else
            en1 <= clk_sel && !en0_sync;     // 选 clk1 且 clk0 已关闭
    end

    // ---- 跨域同步: en1 → clk0 ----
    reg en1_d1;
    always @(posedge clk0 or negedge rst_n) begin
        if (!rst_n) begin
            en1_d1   <= 1'b0;
            en1_sync <= 1'b0;
        end else begin
            en1_d1   <= en1;
            en1_sync <= en1_d1;
        end
    end

    // ---- 跨域同步: en0 → clk1 ----
    reg en0_d1;
    always @(posedge clk1 or negedge rst_n) begin
        if (!rst_n) begin
            en0_d1   <= 1'b0;
            en0_sync <= 1'b0;
        end else begin
            en0_d1   <= en0;
            en0_sync <= en0_d1;
        end
    end

    // ---- 时钟门控输出 ----
    assign clk_out = (en0 && clk0) || (en1 && clk1);

endmodule

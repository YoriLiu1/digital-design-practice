// ============================================================================
// 脉冲同步器 - Pulse Synchronizer (CDC)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 将源时钟域的单周期脉冲同步到目标时钟域
//
// 要求: 目标时钟频率 ≥ 1.5× 源时钟频率 (保证不丢脉冲)
//       两个脉冲间隔 ≥ 2× 目标时钟周期
//
// 原理:
//   1. 源时钟域: 每收到 pulse, 翻转 toggle 信号
//   2. 目标时钟域: 用两级同步器采样 toggle
//   3. 目标时钟域: 边缘检测 toggle 的变化, 恢复为单周期脉冲
// ============================================================================

module pulse_sync (
    input  src_clk,       // 源时钟
    input  src_rst_n,
    input  src_pulse,     // 源时钟域脉冲 (1 拍)
    input  dst_clk,       // 目标时钟
    input  dst_rst_n,
    output dst_pulse      // 目标时钟域脉冲 (1 拍)
);

    // ---- 源时钟域: 脉冲 → toggle 翻转 ----
    reg toggle;
    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n)
            toggle <= 1'b0;
        else if (src_pulse)
            toggle <= ~toggle;
    end

    // ---- 目标时钟域: 两级同步器 ----
    reg toggle_d1, toggle_d2, toggle_d3;
    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            toggle_d1 <= 1'b0;
            toggle_d2 <= 1'b0;
            toggle_d3 <= 1'b0;
        end else begin
            toggle_d1 <= toggle;
            toggle_d2 <= toggle_d1;
            toggle_d3 <= toggle_d2;
        end
    end

    // ---- 目标时钟域: 边缘检测恢复脉冲 ----
    assign dst_pulse = toggle_d2 ^ toggle_d3;

endmodule

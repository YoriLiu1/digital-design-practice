// ============================================================================
// 边缘检测 - Edge Detector
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 检测输入信号的上升沿 / 下降沿, 输出 1 拍脉冲
//
// 原理: 打两拍寄存器 + 组合逻辑
//   pos_edge = 前一拍为 0 且当前为 1
//   neg_edge = 前一拍为 1 且当前为 0
//
// 时序:
//   signal:  0 0 1 1 1 0 0
//   pos:     0 0 1 0 0 0 0
//   neg:     0 0 0 0 0 1 0
// ============================================================================

module edge_detect (
    input  clk,
    input  rst_n,
    input  signal,
    output pos_edge,
    output neg_edge,
    output both_edge
);

    reg signal_d1;    // 打一拍
    reg signal_d2;    // 打两拍

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_d1 <= 1'b0;
            signal_d2 <= 1'b0;
        end else begin
            signal_d1 <= signal;
            signal_d2 <= signal_d1;
        end
    end

    assign pos_edge  = signal_d1 && !signal_d2;    // 上升沿: d1=1, d2=0
    assign neg_edge  = !signal_d1 && signal_d2;    // 下降沿: d1=0, d2=1
    assign both_edge = signal_d1 ^  signal_d2;     // 双边沿: d1 XOR d2

endmodule

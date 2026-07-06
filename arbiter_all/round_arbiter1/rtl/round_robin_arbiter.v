// ============================================================================
// 轮询仲裁器 - Round-Robin Arbiter (减法取反法)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 在多个请求源之间公平轮询授权, 每次授权后优先级自动移到下一个通道
// 算法: fix_base_arbiter (减法取反) + grant 左移旋转
//
// 工作原理:
//   1. 用 fix_base_arbiter 从 base 位置找到第一个有效 req
//   2. 将本次 grant 左移一位作为下次的 base (环形旋转)
//   3. 复位时 base 指向 LSB, 保证首次从通道 0 开始
//
// 参数:
//   CHANNEL — 通道数 (默认 4)
//
// 示例 (CHANNEL=4, req=1111 持续):
//   周期 1: base=0001 → grant=0001 (通道0)
//   周期 2: base=0010 → grant=0010 (通道1)
//   周期 3: base=0100 → grant=0100 (通道2)
//   周期 4: base=1000 → grant=1000 (通道3)
//   周期 5: base=0001 → grant=0001 (回到通道0) ...
// ============================================================================

module round_robin_arbiter #(
    parameter CHANNEL = 4               // 通道数
)(
    input           clk,                // 时钟
    input           rst_n,              // 复位 (低有效)
    input   [CHANNEL-1:0] req,          // 请求
    output  [CHANNEL-1:0] grant         // 授权 (one-hot)
);

    reg  [CHANNEL-1:0] base;            // 优先级起点 (one-hot)
    wire [CHANNEL-1:0] grant_comb;      // 组合逻辑输出的 grant

    // ---- 核心: 复用 fix_base_arbiter 做优先级查找 ----
    fix_base_arbiter #(
        .CHANNEL(CHANNEL)
    ) u_arb (
        .req   (req),
        .base  (base),
        .grant (grant_comb)
    );

    // ---- 维护轮询指针: 本次 grant → 下次从下一位开始 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            base <= {{CHANNEL-1{1'b0}}, 1'b1};              // 复位: 从 LSB 开始
        else if (|req) begin                                 // 有请求才推进
            // 环形左移一位: grant[bit2→bit3, bit1→bit2, bit0→bit1, bit3→bit0]
            base <= {grant_comb[CHANNEL-2:0],
                      grant_comb[CHANNEL-1]};
        end
    end

    assign grant = grant_comb;

endmodule

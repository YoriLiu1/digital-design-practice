// ============================================================================
// 占空比 50% 三分频电路 - Divide-by-3 (50% Duty Cycle)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 输入时钟 3 分频, 输出 50% 占空比
//
// 原理:
//   分频比 = 3 → 输出周期 = 3 个输入周期 → 高电平需要 1.5 个输入周期
//   仅用 posedge 只能做到 1/3 或 2/3 占空比, 必须配合 negedge 拉长半拍
//
//   cnt      : 模 3 计数器 (0, 1, 2, 0, ...)
//   clk_pos  : 上升沿触发, cnt=0 拉高, cnt=1 拉低 (1 拍宽)
//   clk_neg  : 下降沿触发, cnt=0 拉高, cnt=1 拉低 (落后半拍, 1 拍宽)
//   o_clk    : clk_pos | clk_neg → 高 1.5 拍, 低 1.5 拍 → 50%
//
// 时序:
//   i_clk:  _/‾\_/‾\_/‾\_/‾\_/‾\_/‾\_
//   cnt:     0   1   2   0   1   2
//   clk_pos: 1   0   0   1   0   0
//   clk_neg:   1   0   0   1   0   0
//   o_clk:  _/‾‾\___/‾‾\___/‾‾\___
// ============================================================================

module div3 (
    input  i_clk,       // 输入时钟
    input  i_rst_n,     // 复位 (低有效)
    output o_clk        // 3 分频输出, 50% 占空比
);

    reg [1:0] cnt;
    reg       clk_pos;
    reg       clk_neg;

    // ---- 模 3 计数器 (上升沿) ----
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            cnt <= 2'd0;
        else if (cnt == 2'd2)
            cnt <= 2'd0;
        else
            cnt <= cnt + 2'd1;
    end

    // ---- 上升沿触发: cnt=0 拉高, cnt=1 拉低 (脉宽 1 拍) ----
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            clk_pos <= 1'b0;
        else if (cnt == 2'd0)
            clk_pos <= 1'b1;
        else 
            clk_pos <= 1'b0;
    end

    // ---- 下降沿触发: 同样逻辑, 延迟 0.5 拍 ----
    always @(negedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            clk_neg <= 1'b0;
        else if (cnt == 2'd0)
            clk_neg <= 1'b1;
        else 
            clk_neg <= 1'b0;
    end

    // ---- OR 组合输出, 获得 50% 占空比 ----
    assign o_clk = clk_pos | clk_neg;

endmodule

// ============================================================================
// 序列检测器 - Sequence Detector (FSM)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 检测输入序列 "1101", 支持重叠匹配, 输出 1 拍脉冲
//
// 重叠匹配示例:
//   输入: 1 1 0 1 1 0 1
//   输出: 0 0 0 1 0 1 1
//           ^^^^   ^^^^ (第一个 1101 的末位 1 同时作为第二个 1101 的首位 1)
//                      ^^^^
//
// FSM 状态 (Moore 型):
//   IDLE (0)     — 初始, match=0
//   S1   (1'b1)  — 收到 1,          match=0
//   S11  (2'b11) — 收到 11,         match=0
//   S110 (3'b110)— 收到 110,        match=0
//                       收到 1101 → 输出 pulse + 回到 S11 (支持重叠)
// ============================================================================

module seq_detector (
    input  clk,
    input  rst_n,
    input  din,
    output reg match
);

    localparam IDLE = 3'd0;
    localparam S1   = 3'd1;
    localparam S11  = 3'd2;
    localparam S110 = 3'd3;

    reg [2:0] state, next_state;

    // ---- 状态寄存器 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    // ---- 下一状态 + 输出 ----
    always @(*) begin
        next_state = state;
        match = 1'b0;

        case (state)
            IDLE: begin
                if (din) next_state = S1;
                else     next_state = IDLE;
            end
            S1: begin
                if (din) next_state = S11;
                else     next_state = IDLE;
            end
            S11: begin
                if (!din) next_state = S110;
                else      next_state = S11;     // 保持 S11 (连续 1)
            end
            S110: begin
                if (din) begin
                    next_state = S11;            // 重叠! 回到 S11 (1)
                    match      = 1'b1;          // 检测到 1101
                end else
                    next_state = IDLE;           // 1100 → 重新开始
            end
            default: next_state = IDLE;
        endcase
    end

endmodule

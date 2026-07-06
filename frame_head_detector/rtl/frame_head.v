// ============================================================================
// 帧头检测器 - Frame Header Detector
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 连续 3 次检测到 8'h23 时, 输出一个脉冲 head_vld
// 输入: clk, rstn, frame[7:0], frame_vld
// 输出: head_vld (1 cycle pulse)
// ============================================================================

module frame_head(
    input           clk,
    input           rstn,
    input   [7:0]   frame,
    input           frame_vld,
    output          head_vld
);

    // 帧头模式
    localparam HEADER = 8'h23;
    localparam N_MATCH = 2'd3;   // 连续命中次数阈值

    // 连续命中计数器 (0~3, 计到3归零)
    reg [1:0] match_cnt, next_match_cnt;

    // ========================================================================
    // 时序
    // ========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            match_cnt <= 2'd0;
        else
            match_cnt <= next_match_cnt;
    end

    // ========================================================================
    // 组合: 计数逻辑
    // ========================================================================
    always @(*) begin
        next_match_cnt = match_cnt;

        if (frame_vld) begin
            if (frame == HEADER) begin
                if (match_cnt == N_MATCH - 1)
                    next_match_cnt = 2'd0;   // 连续3次命中, 归零重新开始
                else
                    next_match_cnt = match_cnt + 1'd1;
            end else begin
                next_match_cnt = 2'd0;        // 断了, 重新计数
            end
        end
    end

    // ========================================================================
    // 输出: 第3次命中时 pulse 一拍
    // ========================================================================
    assign head_vld = frame_vld && (frame == HEADER) && (match_cnt == N_MATCH - 1);

endmodule

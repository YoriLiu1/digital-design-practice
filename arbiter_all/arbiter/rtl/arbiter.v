// ============================================================================
// 加权仲裁器 - Weighted Round-Robin Arbiter (A:B)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 在两个请求源 reqA / reqB 之间按权重比分配 grant
//
// 仲裁规则:
//   - 仅 A 请求 → grantA = 1
//   - 仅 B 请求 → grantB = 1
//   - A/B 同时请求 → 按 A_ratio : B_ratio 循环仲裁
//     (先给 A 连续 A_ratio 拍, 再给 B 连续 B_ratio 拍, 重复)
//   - 无请求 → 都不 grant
//
// 参数:
//   A_ratio / B_ratio — 权重比, 默认 3:1 (A 占 3/4 带宽, B 占 1/4)
//
// 示例 (A_ratio=3, B_ratio=1):
//   cnt:  0  1  2  3  0  1  2  3 ...
//   grant: A  A  A  B  A  A  A  B ...
// ============================================================================

module arbiter#(
    parameter [7:0] A_ratio = 3,       // A 通道权重 (连续 grant 拍数)
    parameter [7:0] B_ratio = 1        // B 通道权重 (连续 grant 拍数)
)(
    input           clk,                // 时钟
    input           rst_n,              // 复位 (低有效)
    input           reqA,               // 请求 A
    input           reqB,               // 请求 B
    output reg      grantA,             // 授权 A
    output reg      grantB              // 授权 B
);

    // ---- 循环计数器, 范围 0 ~ A_ratio+B_ratio-1 ----
    reg [7:0] cnt;

    // ========================================================================
    // Grant 输出 (同步复位, 上升沿触发)
    // ========================================================================
    always @(posedge clk) begin
        if (!rst_n) begin
            grantA <= 1'b0;
            grantB <= 1'b0;
        end
        else begin
            // 只有一侧请求: 直接授权
            if (reqA && !reqB) begin
                grantA <= 1'b1;
                grantB <= 1'b0;
            end
            else if (!reqA && reqB) begin
                grantA <= 1'b0;
                grantB <= 1'b1;
            end
            // 两侧同时请求: 按权重轮流
            else if (reqA && reqB) begin
                if (cnt <= A_ratio - 1) begin         // cnt 在 A 区间
                    grantA <= 1'b1;
                    grantB <= 1'b0;
                end
                else begin                             // cnt 在 B 区间
                    grantA <= 1'b0;
                    grantB <= 1'b1;
                end
            end
            // 无请求: 都不授权
            else begin
                grantA <= 1'b0;
                grantB <= 1'b0;
            end
        end
    end

    // ========================================================================
    // 循环计数器 (异步复位)
    // 仅在两路同时请求时推进, 计满归零
    // ========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 8'b0;
        end
        else if (reqA && reqB) begin
            cnt <= cnt + 1'b1;
            if (cnt == A_ratio + B_ratio - 1) begin   // 一个循环结束
                cnt <= 8'b0;
            end
        end
        else begin
            cnt <= cnt;                                 // 无竞争时保持
        end
    end

endmodule

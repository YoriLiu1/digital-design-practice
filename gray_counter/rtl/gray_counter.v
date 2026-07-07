// ============================================================================
// Gray 码计数器 - Gray Code Counter
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 可配置位宽 Gray 码计数器, 同时输出 Gray 码和 binary
//
// Gray 码特点: 相邻值仅 1 bit 变化, 常用于跨时钟域 FIFO 指针
//
// 转换:
//   Binary → Gray:  gray = bin ^ (bin >> 1)
//   Gray → Binary:  bin[i] = bin[i+1] ^ gray[i] (MSB→LSB 递推)
// ============================================================================

module gray_counter #(
    parameter WIDTH = 4
)(
    input                   clk,
    input                   rst_n,
    input                   inc,           // 递增使能
    output [WIDTH-1:0]      gray,
    output [WIDTH-1:0]      binary
);

    reg [WIDTH-1:0] bin_cnt;

    // ---- Binary 计数器 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            bin_cnt <= {WIDTH{1'b0}};
        else if (inc)
            bin_cnt <= bin_cnt + 1'b1;
    end

    // ---- Binary → Gray (组合逻辑) ----
    assign binary = bin_cnt;
    assign gray   = bin_cnt ^ (bin_cnt >> 1);

endmodule

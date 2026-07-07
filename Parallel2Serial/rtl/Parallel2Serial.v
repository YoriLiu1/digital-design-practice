// ============================================================================
// 并串转换 - Parallel-to-Serial Converter (6-bit)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 1 拍 6-bit 并行输入 → 6 拍串行输出 (LSB first), 带握手
// ============================================================================

module Parallel2Serial (
    input           i_clk,
    input           i_rst_n,
    input           i_din_valid,
    input   [5:0]   i_din,
    output          o_din_ready,
    input           i_dout_ready,
    output          o_dout_valid,
    output          o_dout
);

    reg [2:0] shift_cnt;      // 已输出的 bit 数: 0(刚load)→1→2→3→4→5→done
    reg [5:0] r_data;
    reg       r_dout_valid;

    assign o_din_ready  = !r_dout_valid;      // 空闲才能收新数据
    assign o_dout       = r_data[0];          // LSB first
    assign o_dout_valid = r_dout_valid;

    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_data       <= 6'd0;
            shift_cnt    <= 3'd0;
            r_dout_valid <= 1'b0;
        end
        // 接收新数据 → 开始发送
        else if (i_din_valid && o_din_ready) begin
            r_data       <= i_din;
            shift_cnt    <= 3'd0;
            r_dout_valid <= 1'b1;
        end
        // 发送中, 下游 ready
        else if (r_dout_valid && i_dout_ready) begin
            if (shift_cnt < 3'd5) begin          // 还有 bit 要发 (bit1~bit5)
                r_data    <= {1'b0, r_data[5:1]};
                shift_cnt <= shift_cnt + 1'b1;
            end else begin                        // 最后一个 bit(5) 已发完
                r_dout_valid <= 1'b0;
            end
        end
    end

endmodule

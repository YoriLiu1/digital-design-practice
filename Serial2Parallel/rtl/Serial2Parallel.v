// ============================================================================
// 串并转换 - Serial-to-Parallel Converter (6-bit)
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 串行输入 6 拍 → 并行输出 1 拍 6-bit, 带上下游握手
//
// 握手协议:
//   i_din_valid / o_din_ready — 上游握手 (valid-ready)
//   o_dout_valid / i_dout_ready — 下游握手 (valid-ready)
//
// 数据顺序: 先收到的 bit 放低位 (LSB first)
//   串行输入: b0, b1, b2, b3, b4, b5
//   并行输出: {b5, b4, b3, b2, b1, b0}
// ============================================================================

module Serial_Parallel (
    input           i_clk,
    input           i_rst_n,
    // ---- 上游接口 (串行输入) ----
    input           i_din_valid,
    input           i_din,
    output          o_din_ready,
    // ---- 下游接口 (并行输出) ----
    input           i_dout_ready,
    output          o_dout_valid,
    output  [5:0]   o_dout
);

    reg [2:0] cnt;              // 已收集 bit 数 (0~5)
    reg [5:0] r_data_out;       // 并行输出寄存器
    reg [5:0] r_data_temp;      // 移位缓存
    reg       r_dout_valid;     // 输出有效
    reg       r_din_ready;      // 可接收新数据

    assign o_din_ready  = r_din_ready;
    assign o_dout_valid = r_dout_valid;
    assign o_dout       = r_data_out;

    // ========================================================================
    // 计数器: 记录已收集 bit 数
    // ========================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            cnt <= 3'd0;
        else if (i_din_valid && o_din_ready) begin
            if (cnt == 3'd5)
                cnt <= 3'd0;
            else
                cnt <= cnt + 1'b1;
        end
    end

    // ========================================================================
    // 上游 ready: 下游没准备好时不收新数据 (backpressure)
    // ========================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            r_din_ready <= 1'b0;
        // 当下游 ready 时允许接收; 已经组装好但下游还没取走时拒绝
        else
            r_din_ready <= i_dout_ready || !r_dout_valid;
    end

    // ========================================================================
    // 移位缓存: LSB first, 新 bit 压入高位
    // ========================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)
            r_data_temp <= 6'd0;
        else if (i_din_valid && o_din_ready)
            r_data_temp <= {i_din, r_data_temp[5:1]};   // 右移,新 bit 放 MSB
    end

    // ========================================================================
    // 并行输出 + valid
    // ========================================================================
    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n) begin
            r_data_out  <= 6'd0;
            r_dout_valid <= 1'b0;
        end
        // 第 6 拍数据到达 → 输出有效
        else if ((cnt == 3'd5) && i_din_valid && o_din_ready) begin
            r_data_out  <= {i_din, r_data_temp[5:1]};
            r_dout_valid <= 1'b1;
        end
        // 下游取走数据 → 清除 valid
        else if (r_dout_valid && i_dout_ready) begin
            r_dout_valid <= 1'b0;
        end
    end

endmodule

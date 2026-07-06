// ============================================================================
// 数据包检测器 - Data Packet Detector
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 数据包格式: 起始码(0xFF00) + 数据段(n bytes, n<256) + 结束码(0xFF01)
// 约束: 数据段中不会出现起始码(0xFF00)和结束码(0xFF01)
//
// FSM 状态说明:
//   IDLE       - 等待起始码第一个字节 0xFF
//   WAIT_START - 已收到 0xFF, 等待 0x00 确认起始码
//   IN_DATA    - 起始码已确认, 收集数据字节并计数
//   WAIT_END   - 在数据段中收到 0xFF, 判断是数据还是结束码
//
// 输入:  clk, rstn, din[7:0], din_vld
// 输出:  data_cnt[7:0] (有效数据字节数), data_cnt_vld (有效脉冲)
//        pkt_err       (异常脉冲: 1=无效包被丢弃)
// ============================================================================

module data(
    input           clk,
    input           rstn,
    input   [7:0]   din,
    input           din_vld,
    output  [7:0]   data_cnt,
    output          data_cnt_vld,
    output          pkt_err
);

    localparam CODE_FF = 8'hFF;
    localparam CODE_00 = 8'h00;
    localparam CODE_01 = 8'h01;

    localparam IDLE       = 2'd0;
    localparam WAIT_START = 2'd1;
    localparam IN_DATA    = 2'd2;
    localparam WAIT_END   = 2'd3;

    reg [1:0] state,      next_state;
    reg [7:0] byte_cnt,   next_byte_cnt;
    reg       pkt_err_r,  next_pkt_err;

    // ========================================================================
    // 时序逻辑
    // ========================================================================
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            state     <= IDLE;
            byte_cnt  <= 8'd0;
            pkt_err_r <= 1'b0;
        end else begin
            state     <= next_state;
            byte_cnt  <= next_byte_cnt;
            pkt_err_r <= next_pkt_err;
        end
    end

    // ========================================================================
    // 组合逻辑: 下一状态、下一计数、异常标志
    // ========================================================================
    always @(*) begin
        next_state    = state;
        next_byte_cnt = byte_cnt;
        next_pkt_err  = 1'b0;   // 默认无异常

        case (state)

            // ----------------------------------------------------------------
            // IDLE: 等待起始码 0xFF
            // ----------------------------------------------------------------
            IDLE: begin
                if (din_vld && din == CODE_FF)
                    next_state = WAIT_START;
            end

            // ----------------------------------------------------------------
            // WAIT_START: 已收到 0xFF, 等 0x00
            // ----------------------------------------------------------------
            WAIT_START: begin
                if (din_vld) begin
                    if (din == CODE_00) begin
                        next_state    = IN_DATA;
                        next_byte_cnt = 8'd0;
                    end else if (din == CODE_FF) begin
                        next_state = WAIT_START;
                    end else begin
                        next_state   = IDLE;
                        next_pkt_err = 1'b1;   // 无效起始码
                    end
                end
            end

            // ----------------------------------------------------------------
            // IN_DATA: 收集数据字节
            // ----------------------------------------------------------------
            IN_DATA: begin
                if (din_vld) begin
                    if (din == CODE_FF) begin
                        next_state = WAIT_END;
                    end else begin
                        if (byte_cnt == 8'd255) begin
                            next_state   = IDLE;
                            next_pkt_err = 1'b1;   // 数据超长
                        end else begin
                            next_byte_cnt = byte_cnt + 1'd1;
                        end
                    end
                end
            end

            // ----------------------------------------------------------------
            // WAIT_END: 数据段中收到 0xFF, 判断后续
            // ----------------------------------------------------------------
            WAIT_END: begin
                if (din_vld) begin
                    case (din)
                        CODE_01: begin
                            // 有效结束码 0xFF01
                            next_state = IDLE;
                        end

                        CODE_00: begin
                            // 0xFF00 嵌入数据
                            next_state    = IN_DATA;
                            next_byte_cnt = 8'd0;
                            next_pkt_err  = 1'b1;
                        end

                        CODE_FF: begin
                            // 前一个 0xFF 是数据, 当前 0xFF 待定
                            if (byte_cnt == 8'd255) begin
                                next_state   = IDLE;
                                next_pkt_err = 1'b1;   // 溢出
                            end else begin
                                next_byte_cnt = byte_cnt + 1'd1;
                                next_state    = WAIT_END;
                            end
                        end

                        default: begin
                            // 前一个 0xFF 是数据, 当前字节也是数据 (+2)
                            if (byte_cnt >= 8'd254) begin
                                next_state   = IDLE;
                                next_pkt_err = 1'b1;   // 溢出
                            end else begin
                                next_byte_cnt = byte_cnt + 2'd2;
                                next_state    = IN_DATA;
                            end
                        end
                    endcase
                end
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    // ========================================================================
    // 输出
    // ========================================================================
    assign data_cnt_vld = (state == WAIT_END) && din_vld && (din == CODE_01);
    assign data_cnt     = byte_cnt;
    assign pkt_err      = pkt_err_r;

endmodule

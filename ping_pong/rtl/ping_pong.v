// ============================================================================
// 乒乓 Buffer - Ping-Pong Buffer
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 双缓冲无缝切换, 写操作与读操作可同时在不同 bank 进行
//
// 设计:
//   两个 bank (A/B), 各 BUF_SIZE 深度
//   full_banks 计数: 0=都空, 1=一块就绪, 2=都满(反压写端)
//   wr_full  = (full_banks == 2)
//   rd_empty = (full_banks == 0)
// ============================================================================

module ping_pong #(
    parameter DATA_WIDTH = 8,
    parameter BUF_SIZE   = 4
)(
    input                           clk,
    input                           rst_n,
    input                           wr_en,
    input  [DATA_WIDTH-1:0]         wr_data,
    output                          wr_full,
    input                           rd_en,
    output [DATA_WIDTH-1:0]         rd_data,
    output                          rd_empty
);

    localparam ADDR_W = $clog2(BUF_SIZE);

    reg [DATA_WIDTH-1:0] buf0 [0:BUF_SIZE-1];
    reg [DATA_WIDTH-1:0] buf1 [0:BUF_SIZE-1];

    reg [ADDR_W:0]  wr_cnt;          // 当前 bank 内写指针
    reg [ADDR_W:0]  rd_cnt;          // 当前 bank 内读指针
    reg             wr_bank;         // 0=A, 1=B
    reg             rd_bank;         // 读取的 bank
    reg  [1:0]      full_banks;      // 已就绪的 bank 数 (0/1/2)

    wire            wr_bank_full = (wr_cnt == BUF_SIZE - 1);   // 写最后一个位置时触发切换

    // ---- 写 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_cnt     <= 0;
            wr_bank    <= 1'b0;
            full_banks <= 2'd0;
        end else if (wr_en && !wr_full) begin
            if (!wr_bank)
                buf0[wr_cnt[ADDR_W-1:0]] <= wr_data;
            else
                buf1[wr_cnt[ADDR_W-1:0]] <= wr_data;

            if (wr_bank_full) begin
                wr_cnt     <= 0;
                wr_bank    <= ~wr_bank;
                full_banks <= full_banks + 1'b1;   // 一块就绪
            end else begin
                wr_cnt <= wr_cnt + 1'b1;
            end
        end
    end

    // ---- 读 (寄存器输出, 避免读指针递增后读到错误地址) ----
    reg [DATA_WIDTH-1:0] rd_data_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_cnt       <= 0;
            rd_bank      <= 1'b0;
            rd_data_reg  <= 0;
        end else if (rd_en && !rd_empty) begin
            // 先捕获当前地址的数据, 再递增指针
            rd_data_reg <= rd_bank ? buf1[rd_cnt[ADDR_W-1:0]] : buf0[rd_cnt[ADDR_W-1:0]];
            if (rd_cnt == BUF_SIZE - 1) begin
                rd_cnt     <= 0;
                rd_bank    <= ~rd_bank;
                full_banks <= full_banks - 1'b1;
            end else begin
                rd_cnt <= rd_cnt + 1'b1;
            end
        end
    end

    // ---- 输出 ----
    assign rd_data  = rd_data_reg;
    assign wr_full  = (full_banks == 2'd2);
    assign rd_empty = (full_banks == 2'd0);

endmodule

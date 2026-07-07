// ============================================================================
// 同步 FIFO - Synchronous FIFO
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 功能: 单时钟域同步 FIFO, 读写共用同一时钟
//
// 设计: rd_data 为寄存器输出 (rd_en 后一拍有效)
//       空满用 MSB 扩展法区分
// ============================================================================

module sync_fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 16
)(
    input                   clk,
    input                   rst_n,
    input                   wr_en,
    input  [WIDTH-1:0]      wr_data,
    output                  full,
    input                   rd_en,
    output [WIDTH-1:0]      rd_data,
    output                  empty
);

    localparam ADDR_W = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_W:0]  wr_ptr;         // 多 1 bit 区分空满
    reg [ADDR_W:0]  rd_ptr;
    reg [WIDTH-1:0] rd_data_reg;

    // ---- 空满 ----
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[ADDR_W] != rd_ptr[ADDR_W]) &&
                   (wr_ptr[ADDR_W-1:0] == rd_ptr[ADDR_W-1:0]);

    // ---- 写 ----
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wr_ptr <= 0;
        else if (wr_en && !full) begin
            mem[wr_ptr[ADDR_W-1:0]] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end

    // ---- 读 (寄存器输出) ----
    assign rd_data = rd_data_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr      <= 0;
            rd_data_reg <= 0;
        end else begin
            if (rd_en && !empty) begin
                rd_data_reg <= mem[rd_ptr[ADDR_W-1:0]];
                rd_ptr      <= rd_ptr + 1'b1;
            end
        end
    end

endmodule

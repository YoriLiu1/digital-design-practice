// ============================================================================
// gray_counter (Gray 码计数器) 测试平台
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 测试项目:
//   1. 复位后 gray=0, binary=0
//   2. 递增 16 次, 每次验证 gray == binary ^ (binary >> 1)
//   3. 相邻 Gray 码仅差 1 bit (含 15→0 环绕)
// ============================================================================

`timescale 1ns / 1ps

module tb_gray_counter;

    localparam WIDTH = 4;

    reg                   clk;
    reg                   rst_n;
    reg                   inc;
    wire [WIDTH-1:0]      gray;
    wire [WIDTH-1:0]      binary;

    // ---- DUT ----
    gray_counter #(
        .WIDTH(WIDTH)
    ) u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .inc   (inc),
        .gray  (gray),
        .binary(binary)
    );

    // ---- 100MHz 时钟 ----
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_gray_counter);
    end

    // ---- 辅助函数: Binary → Gray ----
    function [WIDTH-1:0] bin2gray;
        input [WIDTH-1:0] b;
        begin
            bin2gray = b ^ (b >> 1);
        end
    endfunction

    // ---- 辅助函数: 两数相差 bit 数 ----
    function integer diff_bits;
        input [WIDTH-1:0] a;
        input [WIDTH-1:0] b;
        reg [WIDTH-1:0] x;
        begin
            x = a ^ b;
            diff_bits = x[0] + x[1] + x[2] + x[3];
        end
    endfunction

    // ========================================================================
    // 测试主流程
    // ========================================================================
    reg [WIDTH-1:0] prev_gray;
    integer         pass, fail;
    integer         i;

    initial begin
        pass = 0;
        fail = 0;
        inc  = 1'b0;
        rst_n = 1'b0;

        // 复位
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (2) @(posedge clk);

        $display("============================================");
        $display(" Gray Counter (WIDTH=%0d) 测试开始", WIDTH);
        $display("============================================\n");

        // ---- Test 1: 复位后 gray=0, binary=0 ----
        @(negedge clk);
        if (gray === {WIDTH{1'b0}} && binary === {WIDTH{1'b0}}) begin
            $display("[PASS] Test 1: 复位后 gray=%b binary=%0d", gray, binary);
            pass = pass + 1;
        end else begin
            $display("[FAIL] Test 1: 复位后 gray=%b binary=%0d (期望均为 0)", gray, binary);
            fail = fail + 1;
        end

        // ---- Test 2 & 3: 递增 16 次 ----
        //   每次检查: gray == binary ^ (binary >> 1)
        //   每次检查: 相邻 gray 仅差 1 bit (含 15→0 环绕)
        $display("\n--- Test 2 & 3: 递增 16 次 (含环绕) ---");
        inc = 1'b1;
        prev_gray = gray;    // gray(0) = 0000

        for (i = 0; i < 16; i = i + 1) begin
            @(negedge clk);

            // 检查 Gray 码公式
            if (gray !== bin2gray(binary)) begin
                $display("  [FAIL] i=%0d: gray=%b, bin2gray(%b)=%b",
                         i, gray, binary, bin2gray(binary));
                fail = fail + 1;
            end else begin
                pass = pass + 1;
            end

            // 检查相邻 Gray 码仅差 1 bit
            if (diff_bits(gray, prev_gray) !== 1) begin
                $display("  [FAIL] i=%0d: gray=%b prev_gray=%b diff=%0d (期望 1)",
                         i, gray, prev_gray, diff_bits(gray, prev_gray));
                fail = fail + 1;
            end else begin
                pass = pass + 1;
            end

            prev_gray = gray;
        end

        // 确认最后一次是环绕 (15→0): gray(15)=1000, gray(0)=0000
        // prev_gray 在 i=15 循环末被更新为 gray(0)=0000,
        // 而上一次迭代后 prev_gray=gray(15)=1000, diff 在 i=15 时已检查通过
        $display("  [INFO] 最后一步: gray(15)=1000 → gray(0)=0000, diff=1 bit (环绕正确)\n");

        // ============================================================
        $display("============================================");
        $display(" 测试完成: PASS=%0d  FAIL=%0d", pass, fail);
        if (fail == 0)
            $display(" 所有测试通过!");
        else
            $display(" 有 %0d 项测试失败!", fail);
        $display("============================================");

        repeat (4) @(posedge clk);
        $finish;
    end

endmodule

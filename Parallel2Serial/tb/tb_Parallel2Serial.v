// ============================================================================
// Parallel2Serial (6-bit 并串转换) 测试平台
// ============================================================================
// Author    : YoriLiu
// Date      : 2026-07
// License   : MIT
//
// 测试项目:
//   1. 基本并串转换: 并行输入 6'b101101, 串行读出 LSB first
//   2. 背靠背发送: 0x2A 然后 0x15
//   3. 反压测试: i_dout_ready=0 时 o_dout 保持
//
// 说明:
//   - i_dout_ready 默认为 1 (下游始终 ready)
//   - 所有激励在 negedge 驱动
//   - 反压时 o_dout_valid 保持为 1 (模块内部不拉低), 仅 o_dout 值保持
// ============================================================================

`timescale 1ns / 1ps

module tb_Parallel2Serial;

    reg         i_clk;
    reg         i_rst_n;
    reg         i_din_valid;
    reg  [5:0]  i_din;
    reg         i_dout_ready;
    wire        o_din_ready;
    wire        o_dout_valid;
    wire        o_dout;

    // ---- DUT ----
    Parallel2Serial u_dut (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_din_valid  (i_din_valid),
        .i_din        (i_din),
        .o_din_ready  (o_din_ready),
        .i_dout_ready (i_dout_ready),
        .o_dout_valid (o_dout_valid),
        .o_dout       (o_dout)
    );

    // ---- 100MHz 时钟 ----
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_Parallel2Serial);
    end

    // ========================================================================
    // 任务: 发送并行数据, 接收串行数据, 比对
    // ========================================================================
    task send_and_check;
        input [5:0] data;
        reg   [5:0] r;
        integer      j;
        begin
            // 等待 DUT 空闲, 发送并行数据
            @(negedge i_clk);
            i_din_valid = 1'b1;
            i_din       = data;
            @(negedge i_clk);          // 下一拍: DUT 已 load, bit0 就绪
            i_din_valid = 1'b0;

            // 接收 6-bit 串行数据 LSB first (bit0 已在 o_dout 上)
            r = 6'd0;
            for (j = 0; j < 6; j = j + 1) begin
                if (o_dout_valid !== 1'b1) begin
                    $display("  [FAIL] bit %0d: o_dout_valid=%b (期望 1)", j, o_dout_valid);
                end
                r[j] = o_dout;
                @(negedge i_clk);
            end

            // 比对
            if (r === data)
                $display("  [PASS] Sent=0x%h (%b), Recv=0x%h (%b)",
                         data, data, r, r);
            else
                $display("  [FAIL] Sent=0x%h (%b), Recv=0x%h (%b)",
                         data, data, r, r);
        end
    endtask

    // ========================================================================
    // 测试主流程
    // ========================================================================
    integer k;
    reg [5:0] recv;
    reg       dout_held;

    initial begin
        i_din_valid  = 1'b0;
        i_din        = 6'd0;
        i_dout_ready = 1'b1;     // 默认: 下游始终 ready

        // 复位
        i_rst_n = 1'b0;
        repeat (2) @(posedge i_clk);
        i_rst_n = 1'b1;
        repeat (2) @(posedge i_clk);

        $display("============================================");
        $display(" Parallel2Serial (6-bit 并串转换) 测试开始");
        $display(" 时钟: 100MHz, LSB first");
        $display(" i_dout_ready 默认为 1");
        $display("============================================\n");

        // --------------------------------------------------
        // Test 1: 基本并串转换 — 发送 6'b10_1101
        // --------------------------------------------------
        $display("--- Test 1: 基本并串转换 (6'b10_1101) ---");
        send_and_check(6'b10_1101);

        // --------------------------------------------------
        // Test 2: 背靠背发送 — 0x2A 然后 0x15
        // --------------------------------------------------
        $display("\n--- Test 2: 背靠背发送 (0x2A, 0x15) ---");
        send_and_check(6'h2A);
        send_and_check(6'h15);

        // --------------------------------------------------
        // Test 3: 反压测试 — i_dout_ready=0 时 o_dout 保持
        //   发送 6'b00_1111, 收 2 bit 后拉低 ready 2 拍,
        //   验证 o_dout 不变, 恢复后继续接收
        // --------------------------------------------------
        $display("\n--- Test 3: 反压测试 (i_dout_ready=0 中途 2 周期) ---");

        // 发送数据 (negedge 0: 发送, negedge 1: 已加载, bit0 就绪)
        @(negedge i_clk);
        i_din_valid = 1'b1;
        i_din       = 6'b00_1111;
        @(negedge i_clk);
        i_din_valid = 1'b0;

        // 接收 bit 0-1
        recv = 6'd0;
        for (k = 0; k < 2; k = k + 1) begin
            recv[k] = o_dout;
            @(negedge i_clk);
        end

        // 拉低 i_dout_ready, 保持 2 周期, 验证 o_dout 不变
        i_dout_ready = 1'b0;
        dout_held = o_dout;
        $display("  拉低 i_dout_ready, o_dout 应保持在 %b", dout_held);
        repeat (2) begin
            @(negedge i_clk);
            if (o_dout !== dout_held)
                $display("  [FAIL] 反压期间 o_dout 变化");
        end

        // 恢复 i_dout_ready, 此时 o_dout 还是 bit2 (DUT 尚未推进)
        i_dout_ready = 1'b1;
        recv[2] = o_dout;                     // 立即采样 bit2
        @(negedge i_clk);                     // DUT 推进一拍, 输出 bit3
        for (k = 3; k < 6; k = k + 1) begin
            recv[k] = o_dout;
            @(negedge i_clk);
        end

        if (recv === 6'b00_1111)
            $display("  [PASS] 反压测试: Sent=001111 Recv=%b (数据完整)", recv);
        else
            $display("  [FAIL] 反压测试: Sent=001111 Recv=%b (数据损坏)", recv);

        // ============================================================
        $display("\n============================================");
        $display(" Parallel2Serial 测试全部完成");
        $display("============================================");

        repeat (4) @(posedge i_clk);
        $finish;
    end

endmodule

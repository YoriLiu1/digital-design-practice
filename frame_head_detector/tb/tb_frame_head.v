// ============================================================================
// 帧头检测器 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_frame_head;

    reg         clk;
    reg         rstn;
    reg  [7:0]  frame;
    reg         frame_vld;
    wire        head_vld;

    frame_head u_frame_head (
        .clk       (clk),
        .rstn      (rstn),
        .frame     (frame),
        .frame_vld (frame_vld),
        .head_vld  (head_vld)
    );

    always #5 clk = ~clk;

    integer i;

    task send_byte(input [7:0] b);
        begin
            frame     = b;
            frame_vld = 1'b1;
            @(posedge clk);
        end
    endtask

    task idle_cycle(input integer n);
        begin
            frame_vld = 1'b0;
            frame     = 8'h00;
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // 测试间清理: 发一个非0x23的字节打断计数器
    task test_break;
        begin
            send_byte(8'h00);
            idle_cycle(2);
        end
    endtask

    initial begin
        clk      = 0;
        rstn     = 0;
        frame    = 8'h00;
        frame_vld = 1'b0;

        repeat(5) @(posedge clk);
        rstn = 1;
        repeat(2) @(posedge clk);

        $display("============================================================");
        $display(" 帧头检测器 测试开始");
        $display("============================================================");

        // ================================================================
        // Test 1: 基础 - 连续 3 个 0x23
        // ================================================================
        $display("\n--- Test 1: 连续 3 个 0x23 ---");
        send_byte(8'h23);
        send_byte(8'h23);
        send_byte(8'h23);   // 第3次, 应输出 pulse
        idle_cycle(3);

        // ================================================================
        test_break;

        // ================================================================
        // Test 2: 连续 4 个 0x23 (第 3 个输出 pulse)
        // ================================================================
        $display("\n--- Test 2: 连续 4 个 0x23 ---");
        send_byte(8'h23);
        send_byte(8'h23);
        send_byte(8'h23);   // pulse (第3次)
        send_byte(8'h23);   // 新一组: 第1次
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 3: 连续 6 个 0x23 (第 3, 6 个输出)
        // ================================================================
        $display("\n--- Test 3: 连续 6 个 0x23 ---");
        send_byte(8'h23);   // 新一组: 第2次 (接上一个)
        send_byte(8'h23);   // 第3次 (接上上个) → pulse
        send_byte(8'h23);   // 新一组: 第1次
        send_byte(8'h23);   // 第2次
        send_byte(8'h23);   // 第3次 → pulse
        send_byte(8'h23);   // 新一组: 第1次
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 4: 中间打断 (2个+杂+3个)
        // ================================================================
        $display("\n--- Test 4: 中间打断 ---");
        send_byte(8'h23);   // 第1次
        send_byte(8'h23);   // 第2次
        send_byte(8'hAB);   // 打断! cnt归0
        send_byte(8'h23);   // 第1次
        send_byte(8'h23);   // 第2次
        send_byte(8'h23);   // 第3次 → pulse
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 5: 带空闲周期的连续 0x23
        // ================================================================
        $display("\n--- Test 5: 带空闲周期 (frame_vld=0 时不计) ---");
        send_byte(8'h23);   // 第1次
        send_byte(8'h23);   // 第2次
        idle_cycle(2);      // 空闲: frame_vld=0, 计数不变
        send_byte(8'h23);   // 第3次 → pulse
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 6: 满 3 次后立即再发 (背靠背)
        // ================================================================
        $display("\n--- Test 6: 背靠背两组 ---");
        // 第一组
        send_byte(8'h23);
        send_byte(8'h23);
        send_byte(8'h23);   // pulse
        // 第二组, 无间隔
        send_byte(8'h23);
        send_byte(8'h23);
        send_byte(8'h23);   // pulse
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 7: 1+1+1 不连续, 无输出
        // ================================================================
        $display("\n--- Test 7: 不连续的 0x23 (应无 pulse) ---");
        send_byte(8'h23);
        send_byte(8'hAA);
        send_byte(8'h23);
        send_byte(8'hBB);
        send_byte(8'h23);
        send_byte(8'hCC);
        idle_cycle(3);

        test_break;

        // ================================================================
        // Test 8: 与其他字节混合
        // ================================================================
        $display("\n--- Test 8: 与其他字节混合 ---");
        send_byte(8'hAA);
        send_byte(8'h23);
        send_byte(8'h23);
        send_byte(8'h23);   // pulse
        send_byte(8'hBB);
        idle_cycle(3);

        // ================================================================
        // 结束
        // ================================================================
        $display("\n============================================================");
        $display(" All tests done.");
        $display("============================================================");
        repeat(5) @(posedge clk);
        $finish;
    end

    // ========================================================================
    // 实时监测
    // ========================================================================
    always @(posedge clk) begin
        if (rstn && head_vld)
            $display("[%0t] *** HEAD_VLD pulse ***", $time);
    end

    // 打印每个有效字节 (方便调试)
    always @(posedge clk) begin
        if (rstn && frame_vld)
            $display("[%0t] frame=0x%02h", $time, frame);
    end

    initial begin
        $dumpfile("tb_frame_head.vcd");
        $dumpvars(0, tb_frame_head);
    end

endmodule

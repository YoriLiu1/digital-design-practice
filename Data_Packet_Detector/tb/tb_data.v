// ============================================================================
// 数据包检测器 测试平台 (纯 Verilog-2001)
// ============================================================================

`timescale 1ns / 1ps

module tb_data;

    reg         clk;
    reg         rstn;
    reg  [7:0]  din;
    reg         din_vld;
    wire [7:0]  data_cnt;
    wire        data_cnt_vld;
    wire        pkt_err;

    data u_data (
        .clk          (clk),
        .rstn         (rstn),
        .din          (din),
        .din_vld      (din_vld),
        .data_cnt     (data_cnt),
        .data_cnt_vld (data_cnt_vld),
        .pkt_err      (pkt_err)
    );

    // 时钟
    always #5 clk = ~clk;

    // 测试用变量
    integer i;
    reg [7:0] test_data [0:255];

    // ========================================================================
    // 任务
    // ========================================================================
    task send_byte;
        input [7:0] b;
        begin
            din     = b;
            din_vld = 1'b1;
            @(posedge clk);
        end
    endtask

    task idle_cycle;
        input integer n;
        begin
            din_vld = 1'b0;
            din     = 8'h00;
            for (i = 0; i < n; i = i + 1)
                @(posedge clk);
        end
    endtask

    // 发送起始码
    task send_start;
        begin
            send_byte(8'hFF);
            send_byte(8'h00);
        end
    endtask

    // 发送结束码
    task send_end;
        begin
            send_byte(8'hFF);
            send_byte(8'h01);
        end
    endtask

    // ========================================================================
    // 主测试
    // ========================================================================
    initial begin
        clk     = 0;
        rstn    = 0;
        din     = 8'h00;
        din_vld = 1'b0;

        repeat(5) @(posedge clk);
        rstn = 1;
        repeat(2) @(posedge clk);

        $display("============================================================");
        $display(" 数据包检测器 测试开始");
        $display("============================================================");

        // ================================================================
        // Test 1: 基本有效包 n=5
        // ================================================================
        $display("\n--- Test 1: 基本有效包 n=5 ---");
        send_start;
        send_byte(8'hAA); send_byte(8'hBB); send_byte(8'hCC);
        send_byte(8'hDD); send_byte(8'hEE);
        send_end;
        idle_cycle(3);

        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 2: 空数据包 n=0
        // ================================================================
        $display("\n--- Test 2: 空数据包 n=0 ---");
        send_start;
        // 数据段为空，直接发结束码
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 3: 数据段含单个 0xFF (n=3)
        // ================================================================
        $display("\n--- Test 3: 数据段含0xFF (n=3) ---");
        send_start;
        send_byte(8'hAA);
        send_byte(8'hFF);
        send_byte(8'hBB);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 4: 数据段含连续 0xFF 0xFF (n=4)
        // ================================================================
        $display("\n--- Test 4: 连续两个0xFF (n=4) ---");
        send_start;
        send_byte(8'hAA);
        send_byte(8'hFF);
        send_byte(8'hFF);
        send_byte(8'hBB);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 5: 数据段全是 0xFF (n=5)
        // ================================================================
        $display("\n--- Test 5: 全是0xFF (n=5) ---");
        send_start;
        send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF);
        send_byte(8'hFF); send_byte(8'hFF);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 6: 独立 0x00/0x01 (n=3, 合法)
        // ================================================================
        $display("\n--- Test 6: 独立0x00/0x01 (n=3, 合法) ---");
        send_start;
        send_byte(8'h00);
        send_byte(8'hAA);
        send_byte(8'h01);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 7: 异常 - 数据段中 0xFF00
        // ================================================================
        $display("\n--- Test 7: 数据段中0xFF00 (pkt_err应=1) ---");
        send_start;
        send_byte(8'hAA);   // data[0]
        send_byte(8'hFF);   // -> WAIT_END
        send_byte(8'h00);   // 0xFF00! pkt_err=1, 同时重同步进 IN_DATA
        send_byte(8'hBB);   // 新包 data[0]
        send_end;            // 新包结束
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 8: 异常 - 无效起始码
        // ================================================================
        $display("\n--- Test 8: 无效起始码 (pkt_err应=1) ---");
        send_byte(8'hFF);
        send_byte(8'hAB);   // 非0x00 -> pkt_err, IDLE
        idle_cycle(2);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);
        // 验证恢复: 发一个正常包
        send_start;
        send_byte(8'h55);
        send_end;
        idle_cycle(3);
        $display("  -> 恢复后: data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 9: 起始码前有连续 0xFF
        // ================================================================
        $display("\n--- Test 9: 连续0xFF后起始码 ---");
        send_byte(8'hFF);
        send_byte(8'hFF);
        send_byte(8'hFF);
        send_byte(8'h00);   // 起始码确认
        send_byte(8'h12);
        send_byte(8'h34);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 10: 背靠背两个包
        // ================================================================
        $display("\n--- Test 10: 背靠背两个包 ---");
        send_start;
        send_byte(8'hA1); send_byte(8'hA2);
        send_end;
        // 无空闲，紧接着第二个包
        send_start;
        send_byte(8'hB1); send_byte(8'hB2); send_byte(8'hB3);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 11: 最大长度包 n=255
        // ================================================================
        $display("\n--- Test 11: 最大长度包 n=255 ---");
        send_start;
        for (i = 0; i < 255; i = i + 1)
            send_byte(8'hAA);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 12: 带气泡的数据流 (n=2)
        // ================================================================
        $display("\n--- Test 12: 带气泡的数据流 (n=2) ---");
        send_byte(8'hFF);
        idle_cycle(2);
        send_byte(8'h00);
        idle_cycle(1);
        send_byte(8'h11);
        idle_cycle(3);
        send_byte(8'h22);
        idle_cycle(1);
        send_byte(8'hFF);
        idle_cycle(2);
        send_byte(8'h01);
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // Test 13: 超长包 n=256 (异常)
        // ================================================================
        $display("\n--- Test 13: 超长包 n=256 (pkt_err应=1) ---");
        send_start;
        for (i = 0; i < 256; i = i + 1)
            send_byte(8'hAA);
        send_end;
        idle_cycle(3);
        $display("  -> data_cnt_vld=%b, data_cnt=%0d, pkt_err=%b",
                 data_cnt_vld, data_cnt, pkt_err);

        // ================================================================
        // 测试结束
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
        if (rstn && data_cnt_vld)
            $display("[%0t] *** VALID: data_cnt=%0d ***", $time, data_cnt);
        if (rstn && pkt_err)
            $display("[%0t] *** ERROR ***", $time);
    end

    // ========================================================================
    // 波形
    // ========================================================================
    initial begin
        $dumpfile("tb_data.vcd");
        $dumpvars(0, tb_data);
    end

endmodule

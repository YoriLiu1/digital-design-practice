// ============================================================================
// Serial2Parallel (6-bit 串并转换) 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_Serial2Parallel;

    reg         i_clk;
    reg         i_rst_n;
    reg         i_din_valid;
    reg         i_din;
    reg         i_dout_ready;
    wire        o_din_ready;
    wire        o_dout_valid;
    wire [5:0]  o_dout;

    // ---- 实例化 DUT ----
    Serial_Parallel u_dut (
        .i_clk        (i_clk),
        .i_rst_n      (i_rst_n),
        .i_din_valid  (i_din_valid),
        .i_din        (i_din),
        .i_dout_ready (i_dout_ready),
        .o_din_ready  (o_din_ready),
        .o_dout_valid (o_dout_valid),
        .o_dout       (o_dout)
    );

    // ---- 时钟 ----
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_Serial2Parallel);
    end

    // ---- 监控 ----
    always @(negedge i_clk) begin
        if (i_rst_n)
            $display("time=%0t | din_vld=%b din=%b din_rdy=%b | dout_vld=%b dout=%b dout_rdy=%b",
                     $time, i_din_valid, i_din, o_din_ready,
                     o_dout_valid, o_dout, i_dout_ready);
    end

    // ---- 发送一个 6-bit 数据的任务 ----
    task send_bits;
        input [5:0] data;
        integer i;
        begin
            for (i = 0; i < 6; i = i + 1) begin
                @(negedge i_clk);
                i_din_valid = 1'b1;
                i_din       = data[i];          // LSB first
                @(negedge i_clk);               // 等一拍确认握手
            end
            @(negedge i_clk);
            i_din_valid = 1'b0;
        end
    endtask

    // ---- 等待并行输出 ----
    task wait_output;
        input [5:0] expected;
        begin
            // 等待 o_dout_valid
            while (!o_dout_valid) @(negedge i_clk);
            if (o_dout == expected)
                $display("  [PASS] o_dout = %b (expected)", o_dout);
            else
                $display("  [FAIL] o_dout = %b, expected %b", o_dout, expected);
            // 取走数据
            @(negedge i_clk);
            i_dout_ready = 1'b1;
            @(negedge i_clk);
            i_dout_ready = 1'b0;
        end
    endtask

    // ========================================================================
    // 测试
    // ========================================================================
    initial begin
        i_din_valid  = 1'b0;
        i_din        = 1'b0;
        i_dout_ready = 1'b0;

        // 复位
        i_rst_n = 1'b0;
        repeat (2) @(posedge i_clk);
        i_rst_n = 1'b1;
        repeat (2) @(posedge i_clk);

        $display("============================================");
        $display(" Serial2Parallel (6-bit) 测试开始");
        $display("============================================\n");

        // --- Test 1: 基本串并转换 ---
        $display("--- Test 1: 发送 6'b10_1101 (MSB..LSB) ---");
        send_bits(6'b10_1101);
        wait_output(6'b10_1101);

        // --- Test 2: 全 1 ---
        $display("\n--- Test 2: 发送 6'b11_1111 ---");
        send_bits(6'b11_1111);
        wait_output(6'b11_1111);

        // --- Test 3: 全 0 ---
        $display("\n--- Test 3: 发送 6'b00_0000 ---");
        send_bits(6'b00_0000);
        wait_output(6'b00_0000);

        // --- Test 4: 背靠背连续发送 ---
        $display("\n--- Test 4: 背靠背发送 0x2A, 0x15 ---");
        send_bits(6'b10_1010);
        wait_output(6'b10_1010);
        send_bits(6'b01_0101);
        wait_output(6'b01_0101);

        // --- Test 5: 下游忙, 测试反压 ---
        $display("\n--- Test 5: 下游不 ready, 反压测试 ---");
        i_dout_ready = 1'b0;
        send_bits(6'b00_1111);
        // 此时 o_dout_valid=1, 但 i_dout_ready=0, 上游应被阻塞
        $display("  输出数据等待中... (o_din_ready=%b)", o_din_ready);
        repeat (3) @(negedge i_clk);               // 等 3 拍
        $display("  等待 3 拍后, o_din_ready=%b (应为 0)", o_din_ready);
        // 下游准备好, 取走数据
        @(negedge i_clk);
        i_dout_ready = 1'b1;
        @(negedge i_clk);
        i_dout_ready = 1'b0;
        $display("  下游取走数据: o_dout=%b", o_dout);

        // ============================================================
        $display("\n============================================");
        $display(" 测试全部完成");
        $display("============================================");
        repeat (4) @(posedge i_clk);
        $finish;
    end

endmodule

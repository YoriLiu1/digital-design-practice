// ============================================================================
// round_robin_arbiter (mask 法) 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_round_arbiter;

    parameter DEEP_NUM = 8;

    reg                         clk;
    reg                         rst_n;
    reg  [DEEP_NUM - 1 : 0]     queue_i;
    reg                         sche_en;
    wire [$clog2(DEEP_NUM)-1:0] pointer_o;

    // ---- 实例化 DUT ----
    round_robin_arbiter #(
        .DEEP_NUM(DEEP_NUM)
    ) u_dut (
        .clk       (clk),
        .rst_n     (rst_n),
        .queue_i   (queue_i),
        .sche_en   (sche_en),
        .pointer_o (pointer_o)
    );

    // ---- 时钟 ----
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_round_arbiter);
    end

    // ---- 每周期打印 ----
    always @(negedge clk) begin
        if (rst_n)
            $display("time=%0t | queue=%b sche_en=%b pointer=%0d",
                     $time, queue_i, sche_en, pointer_o);
    end

    // ========================================================================
    // 辅助: 激励在 negedge 更新
    // ========================================================================
    task set_queue;
        input [DEEP_NUM-1:0] val;
        begin
            @(negedge clk);
            queue_i = val;
        end
    endtask

    task set_sche;
        input val;
        begin
            @(negedge clk);
            sche_en = val;
        end
    endtask

    task do_reset;
        begin
            queue_i = 0;
            sche_en = 0;
            rst_n   = 1'b0;
            repeat (2) @(posedge clk);
            rst_n   = 1'b1;
            @(posedge clk);
            sche_en = 1'b1;              // 使能调度
            @(negedge clk);
        end
    endtask

    // ========================================================================
    // 测试
    // ========================================================================
    initial begin
        do_reset();

        $display("============================================");
        $display(" round_robin_arbiter (mask 法) 测试开始");
        $display(" DEEP_NUM = %0d", DEEP_NUM);
        $display("============================================\n");

        // --- Test 1: 单请求队列 ---
        $display("--- Test 1: 单请求 queue=0000_0100 ---");
        $display("  期望: 每拍 pointer=2");
        set_queue(8'b0000_0100);
        repeat (4) @(posedge clk);

        // --- Test 2: 全请求 → 轮流调度 ---
        $display("\n--- Test 2: 全请求 queue=1111_1111, 检查轮询顺序 ---");
        $display("  期望: 0→1→2→3→4→5→6→7→0→...");
        set_queue(8'b1111_1111);
        repeat (12) @(posedge clk);

        // --- Test 3: 部分请求 ---
        $display("\n--- Test 3: 部分请求 queue=1010_1010 (偶数通道) ---");
        $display("  期望: 1→3→5→7→1→3→...");
        set_queue(8'b1010_1010);
        repeat (8) @(posedge clk);

        // --- Test 4: sche_en 暂停 ---
        $display("\n--- Test 4: sche_en 暂停, pointer 应保持不变 ---");
        set_queue(8'b1111_1111);
        repeat (3) @(posedge clk);              // 推进 3 拍
        set_sche(1'b0);
        $display("  sche_en -> 0 (暂停)");
        repeat (3) @(posedge clk);              // 停 3 拍, pointer 不变
        set_sche(1'b1);
        $display("  sche_en -> 1 (继续)");
        repeat (3) @(posedge clk);              // 继续轮询

        // --- Test 5: 动态请求变化 ---
        $display("\n--- Test 5: 动态请求变化 ---");
        set_sche(1'b1);
        set_queue(8'b0000_0000);  repeat (2) @(posedge clk);
        set_queue(8'b1111_0000);  repeat (4) @(posedge clk);
        set_queue(8'b0000_1111);  repeat (4) @(posedge clk);
        set_queue(8'b0000_0001);  repeat (2) @(posedge clk);

        // --- Test 6: DEEP_NUM=4 小位宽 ---
        // 由于 DUT 参数化是 8, 这里只用低 4 位模拟

        // ============================================================
        $display("\n============================================");
        $display(" 测试全部完成");
        $display("============================================");
        repeat (2) @(posedge clk);
        $finish;
    end

    // ========================================================================
    // 自动检查: 不应该给相同通道连续授权 (多请求时)
    // ========================================================================
    reg [$clog2(DEEP_NUM)-1:0] prev_pointer;
    wire                      prev_valid;
    always @(posedge clk) begin
        if (!rst_n)
            prev_pointer <= '0;
        else if (sche_en)
            prev_pointer <= pointer_o;
    end

    assign prev_valid = (|queue_i);

    always @(posedge clk) begin
        if (rst_n && sche_en && prev_valid && (|queue_i)) begin
            // 多于 1 个请求时检查
            if ((queue_i & (queue_i - 1)) != '0) begin
                if (pointer_o == prev_pointer) begin
                    $display("[WARN] time=%0t: 连续两次授权同一通道 pointer=%0d",
                             $time, pointer_o);
                end
            end
        end
    end

endmodule

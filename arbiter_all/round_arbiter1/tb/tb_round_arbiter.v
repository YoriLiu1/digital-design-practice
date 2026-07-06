// ============================================================================
// round_robin_arbiter 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_round_arbiter;

    parameter CHANNEL = 4;

    reg                 clk;
    reg                 rst_n;
    reg  [CHANNEL-1:0]  req;
    wire [CHANNEL-1:0]  grant;

    // ---- 实例化 DUT ----
    round_robin_arbiter #(
        .CHANNEL(CHANNEL)
    ) u_dut (
        .clk   (clk),
        .rst_n (rst_n),
        .req   (req),
        .grant (grant)
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

    // 每周期在 negedge 打印 (此时信号已稳定)
    always @(negedge clk) begin
        if (rst_n)
            $display("time=%0t | req=%b grant=%b", $time, req, grant);
    end

    // ========================================================================
    // 辅助: 激励在 negedge 更新, 避免 posedge 竞态
    // ========================================================================
    task set_req;
        input [CHANNEL-1:0] val;
        begin
            @(negedge clk);
            req = val;
        end
    endtask

    task do_reset;
        begin
            req   = 4'b0000;
            rst_n = 1'b0;
            repeat (2) @(posedge clk);
            rst_n = 1'b1;
            @(posedge clk);             // 等一拍让 rst_n 稳定
        end
    endtask

    // ========================================================================
    // 测试
    // ========================================================================
    initial begin
        do_reset();

        $display("============================================");
        $display(" round_robin_arbiter 测试开始 (CHANNEL=%0d)", CHANNEL);
        $display("============================================\n");

        // --- Test 1: 单请求 → 持续授权同一通道 ---
        $display("--- Test 1: 单请求 req=0010 (应持续 grant=0010) ---");
        set_req(4'b0010);
        repeat (4) @(posedge clk);

        // --- Test 2: 全请求 → 轮流授权 ---
        $display("\n--- Test 2: 全请求 req=1111, 检查轮询顺序 ---");
        $display("  期望: 0001 → 0010 → 0100 → 1000 → ...");
        set_req(4'b1111);
        repeat (8) @(posedge clk);

        // --- Test 3: 部分请求 → 跳过无请求通道 ---
        $display("\n--- Test 3: 部分请求 req=1010 ---");
        $display("  期望: grant 只在 0010 和 1000 之间交替");
        set_req(4'b1010);
        repeat (6) @(posedge clk);

        // --- Test 4: 动态请求变化 ---
        $display("\n--- Test 4: 动态请求变化 ---");
        set_req(4'b0000);  repeat (2) @(posedge clk);
        set_req(4'b1111);  repeat (4) @(posedge clk);
        set_req(4'b0101);  repeat (4) @(posedge clk);
        set_req(4'b1111);  repeat (4) @(posedge clk);

        // --- Test 5: 单通道切换 ---
        $display("\n--- Test 5: 单通道来回切换 ---");
        set_req(4'b0001);  repeat (2) @(posedge clk);
        set_req(4'b1000);  repeat (2) @(posedge clk);
        set_req(4'b0010);  repeat (2) @(posedge clk);
        set_req(4'b0000);  repeat (2) @(posedge clk);

        // ============================================================
        $display("\n============================================");
        $display(" 测试全部完成");
        $display("============================================");
        repeat (2) @(posedge clk);
        $finish;
    end

    // ========================================================================
    // 自动检查: 多请求时不应连续两次授权同一通道
    // ========================================================================
    reg [CHANNEL-1:0] prev_grant;
    always @(posedge clk) begin
        if (!rst_n)
            prev_grant <= '0;
        else
            prev_grant <= grant;
    end

    always @(posedge clk) begin
        if (rst_n && (grant != '0) && (prev_grant != '0)) begin
            if ( (req & (req - 1)) != '0 ) begin
                if (grant == prev_grant) begin
                    $display("[WARN] time=%0t: 多请求时连续两次授权同一通道 grant=%b", $time, grant);
                end
            end
        end
    end

endmodule

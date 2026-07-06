// ============================================================================
// fix_base_arbiter 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_fix_arbiter;

    parameter CHANNEL = 4;

    reg  [CHANNEL-1 : 0] req;
    reg  [CHANNEL-1 : 0] base;
    wire [CHANNEL-1 : 0] grant;

    // ---- 实例化 DUT ----
    fix_base_arbiter #(
        .CHANNEL(CHANNEL)
    ) u_dut (
        .req   (req),
        .base  (base),
        .grant (grant)
    );

    // ---- 波形 + 监控 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_fix_arbiter);
        $monitor("time=%0t | req=%b base=%b grant=%b", $time, req, base, grant);
    end

    // ---- 辅助任务: 测试一组 req+base 并检查 grant ----
    reg [CHANNEL-1 : 0] expected;

    task check;
        input [CHANNEL-1 : 0] r;       // req
        input [CHANNEL-1 : 0] b;       // base
        input [CHANNEL-1 : 0] exp;      // expected grant
        begin
            req  = r;
            base = b;
            #10;
            if (grant !== exp) begin
                $display("[FAIL] req=%b base=%b | grant=%b expected=%b",
                         req, base, grant, exp);
            end else begin
                $display("[PASS] req=%b base=%b | grant=%b",
                         req, base, grant);
            end
        end
    endtask

    // ========================================================================
    // 测试
    // ========================================================================
    initial begin
        $display("============================================");
        $display(" fix_base_arbiter 测试开始 (CHANNEL=%0d)", CHANNEL);
        $display("============================================\n");

        // --- Test 1: 无请求 ---
        $display("--- Test 1: 无请求 ---");
        check(4'b0000, 4'b0001, 4'b0000);
        check(4'b0000, 4'b1000, 4'b0000);

        // --- Test 2: 单个请求, 各种 base ---
        $display("\n--- Test 2: 单请求 (req[2]=1) ---");
        check(4'b0100, 4'b0001, 4'b0100);  // base=1→从0开始, 找到2
        check(4'b0100, 4'b0010, 4'b0100);  // base=2→从1开始, 找到2
        check(4'b0100, 4'b0100, 4'b0100);  // base=4→从2开始, 找到2 (自身)
        check(4'b0100, 4'b1000, 4'b0100);  // base=8→从3开始, wrap 到2

        // --- Test 3: 多请求, base=0001 (默认优先级从0开始) ---
        $display("\n--- Test 3: 多请求, base=0001 ---");
        check(4'b1010, 4'b0001, 4'b0010);  // req[1],[3]=1 → grant[1]
        check(4'b1110, 4'b0001, 4'b0010);  // req[1],[2],[3]=1 → grant[1]
        check(4'b1001, 4'b0001, 4'b0001);  // req[0],[3]=1 → grant[0]

        // --- Test 4: 多请求, base 不在 0001 ---
        $display("\n--- Test 4: 多请求, base=0100 (从 req[2] 开始) ---");
        // 优先级: req[2] > req[1] > req[0] > req[3]
        check(4'b1010, 4'b0100, 4'b1000);  // req[1],[3]=1 → 找[2],[1],[0],[3], 第一个是[3]
        check(4'b1110, 4'b0100, 4'b0100);  // req[1],[2],[3]=1 → [2]命中自己
        check(4'b0111, 4'b0100, 4'b0100);  // req[0],[1],[2]=1 → [2]命中

        $display("\n--- Test 5: 多请求, base=1000 (从 req[3] 开始) ---");
        // 优先级: req[3] > req[2] > req[1] > req[0]
        check(4'b1010, 4'b1000, 4'b1000);  // req[1],[3]=1 → [3]命中
        check(4'b0111, 4'b1000, 4'b0001);  // req[0],[1],[2]=1 → wrap, [0]命中
        check(4'b1111, 4'b1000, 4'b1000);  // 全请求 → base 就是 [3]

        $display("\n--- Test 6: 多请求, base=0010 (从 req[1] 开始) ---");
        // 优先级: req[1] > req[0] > req[3] > req[2]
        check(4'b1111, 4'b0010, 4'b0010);  // [1]命中
        check(4'b1001, 4'b0010, 4'b1000);  // req[0],[3]=1 → [1],[0],[3]找到[3]
        check(4'b0001, 4'b0010, 4'b0001);  // req[0]=1 → [1],[0],[3],[2]找到[0]

        // --- Test 7: 全请求, 遍历所有 base ---
        $display("\n--- Test 7: req=1111, 遍历 base ---");
        check(4'b1111, 4'b0001, 4'b0001);  // 从0开始 → grant[0]
        check(4'b1111, 4'b0010, 4'b0010);  // 从1开始 → grant[1]
        check(4'b1111, 4'b0100, 4'b0100);  // 从2开始 → grant[2]
        check(4'b1111, 4'b1000, 4'b1000);  // 从3开始 → grant[3]

        // --- Test 8: 连续单 bit 请求, base=0001 ---
        $display("\n--- Test 8: 连续单 bit 请求 ---");
        check(4'b0001, 4'b0001, 4'b0001);
        check(4'b0010, 4'b0001, 4'b0010);
        check(4'b0100, 4'b0001, 4'b0100);
        check(4'b1000, 4'b0001, 4'b1000);

        // ============================================================
        $display("\n============================================");
        $display(" 测试全部完成");
        $display("============================================");
        #20;
        $finish;
    end

endmodule

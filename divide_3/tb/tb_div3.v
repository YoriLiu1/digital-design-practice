// ============================================================================
// div3 (50% 占空比 3 分频) 测试平台
// ============================================================================

`timescale 1ns / 1ps

module tb_div3;

    reg  i_clk;
    reg  i_rst_n;
    wire o_clk;

    // ---- 实例化 DUT ----
    div3 u_dut (
        .i_clk   (i_clk),
        .i_rst_n (i_rst_n),
        .o_clk   (o_clk)
    );

    // ---- 时钟: 100MHz (周期 10ns) ----
    initial begin
        i_clk = 0;
        forever #5 i_clk = ~i_clk;
    end

    // ---- 波形 ----
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_div3);
    end

    // ---- 每周期打印 (下降沿) ----
    always @(negedge i_clk) begin
        if (i_rst_n)
            $display("time=%0t | cnt=%0d clk_pos=%b clk_neg=%b o_clk=%b",
                     $time, u_dut.cnt, u_dut.clk_pos, u_dut.clk_neg, o_clk);
    end

    // ========================================================================
    // 占空比自动测量
    // ========================================================================
    realtime rise_time, fall_time;
    realtime high_width, period;

    always @(posedge o_clk) begin
        if (i_rst_n) begin
            rise_time = $realtime;
            if (fall_time > 0) begin
                period     = rise_time - fall_time + high_width;  // fall→rise + rise→fall
                $display("\n[MEASURE] 上升沿@%0t 下降沿@%0t", rise_time, fall_time);
            end
        end
    end

    always @(negedge o_clk) begin
        if (i_rst_n) begin
            fall_time  = $realtime;
            high_width = fall_time - rise_time;
            $display("[MEASURE] 高电平宽度 = %.1fns, 周期 ≈ %.1fns (3 × 10ns = 30ns), 占空比 ≈ %.0f%%",
                     high_width,
                     high_width / 0.5,
                     high_width / 0.3);
        end
    end

    // ========================================================================
    // 测试
    // ========================================================================
    initial begin
        i_rst_n = 1'b0;
        #20;
        i_rst_n = 1'b1;

        $display("============================================");
        $display(" div3 (50%% 占空比 3 分频) 测试开始");
        $display(" 输入时钟周期: 10ns (100MHz)");
        $display(" 期望: 输出周期 30ns, 高电平 15ns (50%%)");
        $display("============================================\n");

        #300;

        $display("\n============================================");
        $display(" 测试完成");
        $display("============================================");
        #20;
        $finish;
    end

endmodule

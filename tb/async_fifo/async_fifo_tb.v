`timescale 1ns/1ps

module async_fifo_tb;

    // ========== 参数定义（匹配RTL）==========
    parameter FIFO_WIDTH = 8;        // 数据位宽 8bit
    parameter FIFO_DEPTH = 16;       // FIFO深度 16
    parameter ALMOST_FULL = 12;      // 几乎满阈值
    parameter ALMOST_EMPTY = 4;      // 几乎空阈值
    
    // ========== 信号定义 ==========
    reg  rst_n;                       // 复位（低有效）
    
    // 写时钟域
    reg  wclk;
    reg  wr_en;
    reg  [FIFO_WIDTH-1:0] data_in;
    wire wfull;
    wire almost_full;
    
    // 读时钟域
    reg  rclk;
    reg  rd_en;
    wire [FIFO_WIDTH-1:0] data_out;
    wire rempty;
    wire almost_empty;
    
    // ========== 时钟生成 ==========
    // 写时钟: 100MHz (周期10ns)
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;
    end
    
    // 读时钟: 50MHz (周期20ns)
    initial begin
        rclk = 0;
        forever #10 rclk = ~rclk;
    end
    
    // ========== 实例化异步FIFO（匹配RTL模块名和参数）==========
    async_fifo #(
        .FIFO_WIDTH(FIFO_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH),
        .ALMOST_FULL(ALMOST_FULL),
        .ALMOST_EMPTY(ALMOST_EMPTY)
    ) u_asyn_fifo (
        .rst_n        (rst_n),
        .wclk         (wclk),
        .rclk         (rclk),
        .wr_en        (wr_en),
        .rd_en        (rd_en),
        .data_in      (data_in),
        .data_out     (data_out),
        .wfull        (wfull),
        .rempty       (rempty),
        .almost_full  (almost_full),
        .almost_empty (almost_empty)
    );
    
    // ========== 测试流程 ==========
    initial begin
        // 1. 初始化
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        
        #20;  // 等待时钟稳定
        
        // 2. 释放复位
        rst_n = 1;
        $display("========================================");
        $display("Testbench Started");
        $display("FIFO_WIDTH = %d, FIFO_DEPTH = %d", FIFO_WIDTH, FIFO_DEPTH);
        $display("ALMOST_FULL = %d, ALMOST_EMPTY = %d", ALMOST_FULL, ALMOST_EMPTY);
        $display("========================================");
        
        // 3. 测试1: 写入一个数据，然后读出
        #30;
        $display("\n[Test 1] Write then read");
        
        @(posedge wclk);
        wr_en = 1;
        data_in = 8'hA5;
        @(posedge wclk);
        wr_en = 0;
        $display("  Wrote data: 0x%h at time %t", data_in, $time);
        
        #40;
        @(posedge rclk);
        rd_en = 1;
        @(posedge rclk);
        rd_en = 0;
        $display("  Read data: 0x%h at time %t", data_out, $time);
        
        // 检查
        if (data_out == 8'hA5) begin
            $display("  [PASS] Read data matches");
        end else begin
            $display("  [FAIL] Expected 0xA5, got 0x%h", data_out);
        end
        
        // 4. 测试2: 连续写直到满
        #50;
        $display("\n[Test 2] Write until full");
        
        while (!wfull) begin
            @(posedge wclk);
            wr_en = 1;
            data_in = data_in + 1;
        end
        @(posedge wclk);
        wr_en = 0;
        $display("  FIFO full after writing %d data", data_in);
        $display("  wfull = %b, almost_full = %b", wfull, almost_full);
        
        // 5. 测试3: 连续读直到空
        #50;
        $display("\n[Test 3] Read until empty");
        
        while (!rempty) begin
            @(posedge rclk);
            rd_en = 1;
            $display("  Read data: 0x%h", data_out);
        end
        @(posedge rclk);
        rd_en = 0;
        $display("  FIFO empty after reading all data");
        $display("  rempty = %b, almost_empty = %b", rempty, almost_empty);
        
        // 6. 测试4: 测试几乎满/空标志
        #50;
        $display("\n[Test 4] Test almost_full and almost_empty flags");
        
        // 写数据直到 almost_full 有效
        $display("  Writing data until almost_full...");
        while (!almost_full && !wfull) begin
            @(posedge wclk);
            wr_en = 1;
            data_in = data_in + 1;
        end
        @(posedge wclk);
        wr_en = 0;
        $display("  almost_full = %b when data count >= %d", almost_full, ALMOST_FULL);
        
        // 读数据直到 almost_empty 有效
        #50;
        $display("  Reading data until almost_empty...");
        while (!almost_empty && !rempty) begin
            @(posedge rclk);
            rd_en = 1;
        end
        @(posedge rclk);
        rd_en = 0;
        $display("  almost_empty = %b when data count <= %d", almost_empty, ALMOST_EMPTY);
        
        // 7. 测试5: 随机读写
        #50;
        $display("\n[Test 5] Random write and read");
        
        repeat(50) begin
            // 随机写
            if ($random % 2 && !wfull) begin
                @(posedge wclk);
                wr_en = 1;
                data_in = $random % 256;
            end else begin
                @(posedge wclk);
                wr_en = 0;
            end
            
            // 随机读
            if ($random % 2 && !rempty) begin
                @(posedge rclk);
                rd_en = 1;
            end else begin
                @(posedge rclk);
                rd_en = 0;
            end
        end
        
        // 8. 结束仿真
        #100;
        $display("\n========================================");
        $display("All tests completed!");
        $display("========================================");
        $finish;
    end
    
    // ========== 波形输出 ==========
    initial begin
        $fsdbDumpfile("async_fifo.fsdb");
        $fsdbDumpvars(0, async_fifo_tb);
    end
    
    // ========== 监控信号（警告检查）==========
    always @(posedge wclk) begin
        if (wr_en && wfull) begin
            $display("WARNING: Write to full FIFO at time %t", $time);
        end
    end
    
    always @(posedge rclk) begin
        if (rd_en && rempty) begin
            $display("WARNING: Read from empty FIFO at time %t", $time);
        end
    end
    
    // 打印状态变化（可选）
    always @(posedge wclk) begin
        $display("[%t] wclk: wr_en=%b, wfull=%b, almost_full=%b", 
                 $time, wr_en, wfull, almost_full);
    end
    
    always @(posedge rclk) begin
        $display("[%t] rclk: rd_en=%b, rempty=%b, almost_empty=%b, data_out=0x%h", 
                 $time, rd_en, rempty, almost_empty, data_out);
    end

endmodule

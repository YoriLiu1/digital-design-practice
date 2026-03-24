`timescale 1ns/1ps

module async_fifo_tb;

    // ========== Parameter definition ==========
    parameter FIFO_WIDTH = 8;        
    parameter FIFO_DEPTH = 16;       
    parameter ALMOST_FULL = 12; 
    parameter ALMOST_EMPTY = 4;      
    
    // ========== Signal Definition =============
    reg  rst_n;                       // Reset (active low)
    
    // Write clock domain
    reg  wclk;
    reg  wr_en;
    reg  [FIFO_WIDTH-1:0] data_in;
    wire wfull;
    wire almost_full;
    
    // Read clock domain
    reg  rclk;
    reg  rd_en;
    wire [FIFO_WIDTH-1:0] data_out;
    wire rempty;
    wire almost_empty;
    
    // ========== Clock generation ==========
    // Write clock: 100MHz (period 10ns)
    initial begin
        wclk = 0;
        forever #5 wclk = ~wclk;
    end
    
    // Read clock: 50MHz (period 20ns)
    initial begin
        rclk = 0;
        forever #10 rclk = ~rclk;
    end
    
    // ========== Instantiate async fifo ==========
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
    
    // ========== Test procedure ==========
    initial begin
        
        rst_n = 0;
        wr_en = 0;
        rd_en = 0;
        data_in = 0;
        
        #20;  // Wait for clocks to stabilize
        
        // 2. Release reset
        rst_n = 1;
        $display("========================================");
        $display("Testbench start");
        $display("FIFO_WIDTH = %d, FIFO_DEPTH = %d", FIFO_WIDTH, FIFO_DEPTH);
        $display("ALMOST_FULL = %d, ALMOST_EMPTY = %d", ALMOST_FULL, ALMOST_EMPTY);
        $display("========================================");
        
        // 3. Test 1: Write one data, then read
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
        
        // Check result
        if (data_out == 8'hA5) begin
            $display("  [PASS] Read data matches");
        end else begin
            $display("  [FAIL] Expected 0xA5, got 0x%h", data_out);
        end
        
        // 4. Test 2: Write until full
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
        
        // 5. Test 3: Read until empty
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
        
        // 6. Test 4: Test almost_full and almost_empty flags
        #50;
        $display("\n[Test 4] Test almost_full and almost_empty flags");
        
        // Write data until almost_full becomes active
        $display("  Writing data until almost_full...");
        while (!almost_full && !wfull) begin
            @(posedge wclk);
            wr_en = 1;
            data_in = data_in + 1;
        end
        @(posedge wclk);
        wr_en = 0;
        $display("  almost_full = %b when data count >= %d", almost_full, ALMOST_FULL);
        
        // Read data until almost_empty becomes active
        #50;
        $display("  Reading data until almost_empty...");
        while (!almost_empty && !rempty) begin
            @(posedge rclk);
            rd_en = 1;
        end
        @(posedge rclk);
        rd_en = 0;
        $display("  almost_empty = %b when data count <= %d", almost_empty, ALMOST_EMPTY);
        
        // 7. Test 5: Random read and write
        #50;
        $display("\n[Test 5] Random write and read");
        
        repeat(50) begin
            // Random write
            if ($random % 2 && !wfull) begin
                @(posedge wclk);
                wr_en = 1;
                data_in = $random % 256;
            end else begin
                @(posedge wclk);
                wr_en = 0;
            end
            
            // Random read
            if ($random % 2 && !rempty) begin
                @(posedge rclk);
                rd_en = 1;
            end else begin
                @(posedge rclk);
                rd_en = 0;
            end
        end
        
        // 8. End simulation
        #100;
        $display("\n========================================");
        $display("All tests completed!");
        $display("========================================");
        $finish;
    end
    
    // ========== Waveform Dump ==========
    initial begin
        $fsdbDumpfile("async_fifo.fsdb");
        $fsdbDumpvars(0, async_fifo_tb);
    end
    
    // ========== Monitor (Warning Checks) ==========
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
    
    // Optional: Print status changes
    always @(posedge wclk) begin
        $display("[%t] wclk: wr_en=%b, wfull=%b, almost_full=%b", 
                 $time, wr_en, wfull, almost_full);
    end
    
    always @(posedge rclk) begin
        $display("[%t] rclk: rd_en=%b, rempty=%b, almost_empty=%b, data_out=0x%h", 
                 $time, rd_en, rempty, almost_empty, data_out);
    end

endmodule

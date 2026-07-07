// ============================================================================
// ping_pong 测试平台
// ============================================================================
`timescale 1ns/1ps
module tb_ping_pong;
    parameter DW=8, BS=4;
    reg clk, rst_n, wr_en, rd_en;
    reg [DW-1:0] wr_data;
    wire wr_full, rd_empty;
    wire [DW-1:0] rd_data;

    ping_pong #(.DATA_WIDTH(DW), .BUF_SIZE(BS)) u(
        .clk,.rst_n,.wr_en,.wr_data,.wr_full,.rd_en,.rd_data,.rd_empty);

    initial clk=0; always #5 clk=~clk;
    initial begin $dumpfile("wave.vcd"); $dumpvars(0,tb_ping_pong); end

    integer i, p, f;
    reg [DW-1:0] g;
    task W; input [DW-1:0] v; begin @(negedge clk); wr_en=1; wr_data=v; @(negedge clk); wr_en=0; end endtask
    task R; output [DW-1:0] v; begin @(negedge clk); rd_en=1; @(negedge clk); v=rd_data; rd_en=0; end endtask
    task T; input [255*8:1] n; input c; begin if(c) begin $display("[PASS] %s",n); p=p+1; end else begin $display("[FAIL] %s",n); f=f+1; end end endtask

    initial begin
        wr_en=0; rd_en=0; p=0; f=0;
        rst_n=0; repeat(2)@(posedge clk); rst_n=1; @(posedge clk);
        $display("=== ping_pong test ===");

        // Test 1: fill bank A (4 writes) → full_banks=1, wr_full=0
        for(i=0;i<BS;i=i+1) W(i);
        T("Test1: wr_full=0 after fill bank A", wr_full==0);

        // Test 2: fill bank B (4 more writes) → full_banks=2, wr_full=1
        for(i=0;i<BS;i=i+1) W(i+BS);
        T("Test2: wr_full=1 after fill bank B", wr_full==1);

        // Test 3: read bank A (4 reads) → data match, full_banks=1
        for(i=0;i<BS;i=i+1) begin R(g); if(g!==i) $display("  exp %0d got %0d",i,g); end
        T("Test3: rd_empty=0 after read bank A", rd_empty==0);

        // Test 4: read bank B (4 reads) → data match, full_banks=0
        for(i=0;i<BS;i=i+1) begin R(g); if(g !== i+BS) $display("  exp %0d got %0d",i+BS,g); end
        T("Test4: rd_empty=1 after read bank B", rd_empty==1);

        $display("PASS=%0d FAIL=%0d",p,f);
        if(f>0) $display("*** SOME TESTS FAILED ***");
        else $display("*** ALL TESTS PASSED ***");
        #20; $finish;
    end
endmodule

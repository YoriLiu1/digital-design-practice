`timescale 1ns/1ps
module tb_arbiter;

reg clk;
reg rst_n;
reg reqA;
reg reqB;
wire grantA;
wire grantB;

arbiter #(
    .A_ratio(3),
    .B_ratio(1)
) U1 (
    .clk(clk),
    .rst_n(rst_n),
    .reqA(reqA),
    .reqB(reqB),
    .grantA(grantA),
    .grantB(grantB)
);

initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
end
initial begin
    rst_n = 1'b0;
    reqA = 1'b0;
    reqB = 1'b0;
    #10 rst_n = 1'b1;
    #10 reqA = 1'b1;
    #10 reqB = 1'b1;
    #100 reqA = 1'b0;
    #10 reqB = 1'b0;
end
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_arbiter);
    #300 $finish;
end

endmodule
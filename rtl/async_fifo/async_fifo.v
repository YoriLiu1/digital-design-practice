`timescale 1ns / 1ps

module asyn_fifo#(
    parameter FIFO_WIDTH='d8,
    parameter FIFO_DEPTH='d16,
    parameter ALMOST_FULL='d12,
    parameter ALMOST_EMPTY='d4
    )(
    input rst_n,
    input [FIFO_WIDTH-1:0] data_in,
    input wr_en,
    input rd_en,
    input wclk,
    input rclk,
    
    output reg [FIFO_WIDTH-1:0] data_out,
    output wfull,
    output rempty,
    output wire almost_full,
    output wire almost_empty
    
);

    reg [FIFO_WIDTH-1:0] fifo_buffer [0:FIFO_DEPTH-1];
    reg [$clog2(FIFO_DEPTH):0] wptr;
    reg [$clog2(FIFO_DEPTH):0] rptr;
    reg [$clog2(FIFO_DEPTH):0] wptr_gray_nxt;
    reg [$clog2(FIFO_DEPTH):0] rptr_gray_nxt;
    reg [$clog2(FIFO_DEPTH):0] rptr_gray_syn;
    reg [$clog2(FIFO_DEPTH):0] wptr_gray_syn;
    reg [$clog2(FIFO_DEPTH)-1:0] almost_full_value;
    reg [$clog2(FIFO_DEPTH)-1:0] almost_empty_value;
    
    wire [$clog2(FIFO_DEPTH):0] wptr_gray;
    wire [$clog2(FIFO_DEPTH):0] rptr_gray;
    wire [$clog2(FIFO_DEPTH):0] rptr_bin_syn;
    wire [$clog2(FIFO_DEPTH):0] wptr_bin_syn;
    
   //写指针 
    always@(posedge wclk or negedge rst_n)begin
        if(!rst_n)
            wptr<='d0;
        else if(~wfull&&wr_en)begin
            wptr<=wptr+1'b1;
            fifo_buffer[wptr]<=data_in;
        end    
        else
            wptr<=wptr;
    end
    always@(posedge rclk or negedge rst_n)begin
        if(!rst_n)
            rptr<='d0;
        else if(~rempty&&rd_en)begin
            rptr<=rptr+1'b1;
            data_out<=fifo_buffer[rptr];

        end
        else
            rptr<=rptr;
    end
    //空满
    //地址二进制转格雷码(原因：打两拍同步指针时只适用于每次变化1bit 当多bit时打怕方式会是的跨时钟域同步的结果出错
    assign wptr_gray=wptr^(wptr>>1);
    assign rptr_gray=rptr^(rptr>>1);
    //跨时钟域--将写指针同步到读时钟域
    always@(posedge rclk or negedge rst_n)begin
        if(!rst_n)begin
              wptr_gray_nxt<='d0;
              wptr_gray_syn<='d0;
        end 
        else begin
              wptr_gray_nxt<=wptr_gray;
              wptr_gray_syn<=wptr_gray_nxt;        
        end  
    end
    //跨时钟域--将读指针同步到写时钟域
    always@(posedge wclk or negedge rst_n)begin
        if(!rst_n)begin
              rptr_gray_nxt<='d0;
              rptr_gray_syn<='d0;
        end 
        else begin
              rptr_gray_nxt<=rptr_gray;
              rptr_gray_syn<=rptr_gray_nxt;        
        end  
    end 
    assign wfull=({~wptr_gray[$clog2(FIFO_DEPTH):$clog2(FIFO_DEPTH)-1],wptr_gray[$clog2(FIFO_DEPTH)-2:0]}==rptr_gray_syn)?1'b1:1'b0;
    assign rempty=(wptr_gray_syn==rptr_gray)?1'b1:1'b0; 
    
    //almost_full与almost_empty
    //先将指针格雷码形式转换为二进制
    assign rptr_bin_syn[$clog2(FIFO_DEPTH)]=rptr_gray_syn[$clog2(FIFO_DEPTH)];
    assign wptr_bin_syn[$clog2(FIFO_DEPTH)]=wptr_gray_syn[$clog2(FIFO_DEPTH)];
    

    generate 
    genvar i;
    for (i=$clog2(FIFO_DEPTH)-1;i>=0;i=i-1)begin
        assign rptr_bin_syn[i]=rptr_gray_syn[i+1]^rptr_gray_syn[i];
        assign wptr_bin_syn[i]=wptr_gray_syn[i+1]^wptr_gray_syn[i]; 
    end
    endgenerate
    
    //almost_empty
    always@(*)begin
        if(wptr_bin_syn[$clog2(FIFO_DEPTH)]==rptr[$clog2(FIFO_DEPTH)])
            almost_empty_value=wptr_bin_syn[$clog2(FIFO_DEPTH)-1:0]-rptr[$clog2(FIFO_DEPTH)-1:0]; 
        else   
            almost_empty_value=FIFO_DEPTH-(rptr[$clog2(FIFO_DEPTH)-1:0]-wptr_bin_syn[$clog2(FIFO_DEPTH)-1:0]);
    end
    //almost_full
    always@(*)begin
        if(rptr_bin_syn[$clog2(FIFO_DEPTH)]==wptr[$clog2(FIFO_DEPTH)])
            almost_full_value=wptr[$clog2(FIFO_DEPTH)-1:0]-rptr_bin_syn[$clog2(FIFO_DEPTH)-1:0]; 
        else   
            almost_full_value=FIFO_DEPTH-(rptr_bin_syn[$clog2(FIFO_DEPTH)-1:0]-wptr[$clog2(FIFO_DEPTH)-1:0]);
    end
    assign almost_empty=(almost_empty_value<ALMOST_EMPTY); 
    assign almost_full=(almost_full_value>ALMOST_FULL); 
        
endmodule


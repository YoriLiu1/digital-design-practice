`timescale 1ns / 1ps

module async_fifo_tb(

    );
endmodule
`timescale 1ns/1ps

module tb_Sync_FIFO;

parameter FIFO_WIDTH='d8;
parameter FIFO_DEPTH='d16;
parameter ALMOST_FULL='d12;
parameter ALMOST_EMPTY='d4;

reg          w_clk_i, r_clk_i;
reg          rst_n_i;

reg          wr_en_i  ;
reg  [FIFO_WIDTH-1:0]   wr_data_i;

reg          rd_en_i  ;
wire  [FIFO_WIDTH-1:0]  rd_data_o;

wire          full_o   ;
wire          empty_o  ;

parameter  w_clk_period = 1000;   //1GHz时钟： T = 1000ns
parameter  r_clk_period = 500;    //2GHz时钟： T = 500ns

// 生成写端clk：
initial
begin
  w_clk_i = 1'b1;
  forever
  begin
    #(w_clk_period/2)  w_clk_i = ~w_clk_i;
    
  end
end

//生成读端clk
initial
begin
  r_clk_i = 1'b1;
  forever
  begin
    #(r_clk_period/2)  r_clk_i = ~r_clk_i;
    
  end
end

//生成写复位、写使能、写数据
initial 
begin
  rst_n_i   = 1  ;
  

  wr_en_i   = 0  ;
  wr_data_i = 4'b0;

  #(w_clk_period)     rst_n_i = 0;
  #(w_clk_period*2)   rst_n_i = 1;

  @(posedge w_clk_i)
  begin
    wr_en_i = 1;

  end

  @(posedge w_clk_i)
  begin
    wr_en_i = 0;

  end

  @(posedge w_clk_i)
  begin
    wr_en_i = 1;

  end

  @(posedge w_clk_i)
  begin
    wr_en_i = 0;

  end

  #(w_clk_period)
  repeat(50)
  begin
      @(posedge w_clk_i)
      begin
        wr_en_i     = {$random}%2;
        wr_data_i   = {$random}%5'h10;
      end
  end

  #(w_clk_period)

  @(posedge w_clk_i)
  begin
    wr_en_i = 0;

  end

end

//生成读复位、读使能
initial 
begin
  rst_n_i   = 1  ;
  
  rd_en_i   = 0  ;

  #(r_clk_period)     rst_n_i = 0;
  #(r_clk_period*2)   rst_n_i = 1;

  @(posedge r_clk_i)
  begin
    rd_en_i = 0;
  end

  #(r_clk_period*30)
  repeat(60)
  begin
      @(posedge r_clk_i)
      begin
        rd_en_i = {$random}%2;
      end
  end
  
  #(r_clk_period*30)

  @(posedge r_clk_i)
  begin
    rd_en_i = 1;
  end

end

initial 
begin
  #(w_clk_period*125)
  $stop;
end


asyn_fifo#(
    .FIFO_WIDTH(FIFO_WIDTH),
    .FIFO_DEPTH(FIFO_DEPTH),
    .ALMOST_FULL(ALMOST_FULL),
    .ALMOST_EMPTY(ALMOST_EMPTY)
    )
    A0(
    .rst_n(rst_n_i),
    .data_in(wr_data_i),
    .wr_en(wr_en_i),
    .rd_en(rd_en_i),
    .wclk(w_clk_i),
    .rclk(r_clk_i),
   
    .data_out(rd_data_o),
    .wfull(full_o),
    .rempty(empty_o),
    .almost_full(),
    .almost_empty()   
);

endmodule

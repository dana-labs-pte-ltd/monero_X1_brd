`timescale 1 ns / 100 ps // timescale for following modules
module cn_top_tb ();
  
  parameter ADDRESS_WIDTH = 15;
  
  wire      clk;
  wire      reset_n;
  
  // Buffer interface
  // input          reg_cs;
  reg  [9:0]    reg_address;
  reg           reg_write;
  reg  [31:0]   reg_wrdata;
  wire [31:0]   reg_rddata;
  
  reg  [ADDRESS_WIDTH+1:0]    mem_address;
  reg           mem_write;
  reg  [127:0]  mem_wrdata;
  wire [127:0]  mem_rddata;
  wire          sts_ml_finished;
  
  reg [63:0] h0 [0:13];
  reg [63:0] code0 [0:69];
  
  parameter REF_CLK_HALF_CYCLE = 2000;//ps
  parameter RESET_WIDTH        = 20000;
  parameter h0_base            = 10'h100;
  parameter code0_base         = 10'h000;
  parameter cntl_base          = 10'h200;
  integer i;
  
  //------------------------------------------------------------------------------//
  // Generate system clock
  //------------------------------------------------------------------------------//
  sys_clk_gen # (
  .halfcycle(REF_CLK_HALF_CYCLE),
  .offset(0)
  )
  CLK_GEN_RP (
  .sys_clk(clk)
  );
  
  //------------------------------------------------------------------------------//
  // Generate reset
  //------------------------------------------------------------------------------//
  reset_gen # (
  .halfcycle(RESET_WIDTH),
  .offset(0)
  )
  RESET_GEN_RP (
  .reset_n(reset_n)
  );
  
  
  task tsk_mem_write;
    input [511:0] mem_data;
    input [ADDRESS_WIDTH+1:0]   mem_addr;
    begin
      mem_address = mem_addr;
      mem_wrdata  = mem_data;
      @(posedge clk);
      mem_write = 1'b1;
      @(posedge clk);
      mem_write = 1'b0;
    end
  endtask
  
  task delay;
    input [8:0]   delay_cnt;
    begin
      repeat(delay_cnt)begin
        @(posedge clk);
      end
    end
  endtask
  
  task tsk_reg_write;
    input [31:0] reg_data;
    input [9:0]   reg_addr;
    begin
      reg_address = reg_addr;
      reg_wrdata  = reg_data;
      @(posedge clk);
      reg_write = 1'b1;
      @(posedge clk);
      reg_write = 1'b0;
    end
  endtask
  
  task h0_init;
    reg [4:0] i;
    begin
      h0[0]  = 64'h8862253561833732;
      h0[1]  = 64'h3744837167518724;
      h0[2]  = 64'h6764440355350450;
      h0[3]  = 64'hb158fbf4b3c32cd8;
      h0[4]  = 64'ha3def0f41d45e2aa;
      h0[5]  = 64'h8332e42d8f9352fb;
      h0[6]  = 64'h27f3842d7c78f07d;
      h0[7]  = 64'hf9bb0af7423804d4;
      h0[8]  = 64'h46d9b3fadb38b700;
      h0[9]  = 64'haf267bb9648b6f8b;
      h0[10] = 64'h4f60c4f20af60d7c;
      h0[11] = 64'h090a233ba8929add;
      h0[12] = 64'h4f60c4f20af60d7c;
      h0[13] = 64'h27f3842d7c78f07d;
      i      = 0;
      repeat(28)begin
        if (i[0])begin
          tsk_reg_write(h0[(i[4:1])][63:32], h0_base+i);
          end else begin
          tsk_reg_write(h0[(i[4:1])][31:0], h0_base+i);
        end
        i = i+1;
      end
    end
  endtask
  
  task random_math_init;
    integer i;
    //reg [63:0] code0 [0:69];
    begin
      i = 0;
      repeat(140)begin
        if (i%2 == 1)begin
          tsk_reg_write(code0[i/2][63:32],code0_base+i);
          end else begin
          tsk_reg_write(code0[i/2][31:0],code0_base+i);
        end
        i = i+1;
      end
    end
  endtask
  
  task mem_init;
    reg [127:0] mem_data;
    reg [63:0] j;
    reg [63:0] k;
    begin
      j = 0;
      k = 0;
      repeat(32768*4) begin
        repeat(2) begin
          mem_data = {j,mem_data[127:64]};
          j        = j+1;
        end
        tsk_mem_write(mem_data,k);
        k = k + 1;
      end
    end
  endtask
  
  initial begin
    reg_address = 0;
    reg_wrdata  = 0;
    reg_write   = 0;
    mem_wrdata  = 0;
    mem_write   = 0;
    mem_address = 0;
    $readmemh("random_code.txt",code0);
    i = 0;
    @(posedge reset_n);
    delay(20);
    //start h0 init
    h0_init;
    //start memory init
    mem_init;
    random_math_init;
    delay(20);
    i = 0;
    delay(20);
    //    repeat(1<<9) begin
    //      tsk_mem_write({32{$random}},i);
    //      i = i + 1;
    //    end
    i = 0;
    delay(20);
    //    repeat(12) begin
    //      tsk_reg_write($random,i);
    //      i = i + 1;
    //    end
    delay(20);
    tsk_reg_write(1,cntl_base);
    @(posedge UUT.cn_ml_inst.sts_running);
    $stop;
    @(posedge UUT.cn_ml_inst.finished);
    $stop;
    delay(20);
    $finish;
  end
  
  integer ax0_file;
  integer bx0_file;
  integer bx1_file;
  
  
  initial begin
    delay(20);
    ax0_file = $fopen("ax0.txt");
    $fmonitor(ax0_file,"%h",UUT.cn_ml_inst.ax0);
    @(posedge UUT.cn_ml_inst.finished);
    $fclose(ax0_file);
  end
  
  initial begin
    delay(20);
    bx0_file = $fopen("bx0.txt");
    $fmonitor(bx0_file,"%h",UUT.cn_ml_inst.bx0);
    @(posedge UUT.cn_ml_inst.finished);
    $fclose(bx0_file);
  end
  
  initial begin
    delay(20);
    bx1_file = $fopen("bx1.txt");
    $fmonitor(bx1_file,"%h",UUT.cn_ml_inst.bx1);
    @(posedge UUT.cn_ml_inst.finished);
    $fclose(bx1_file);
  end
  
  
  cn_top UUT(
  .clk(clk),
  .reset_n(reset_n),
  
  //avalon mem slave interface
  .mem_address(mem_address),
  .mem_write(mem_write),
  .mem_wrdata(mem_wrdata),
  .mem_rddata(mem_rddata),
  .sts_ml_finished(sts_ml_finished),
  
  //avalon reg slave interface
  .reg_address(reg_address),
  .reg_write(reg_write),
  .reg_wrdata(reg_wrdata),
  .reg_rddata(reg_rddata)
  );
  
endmodule

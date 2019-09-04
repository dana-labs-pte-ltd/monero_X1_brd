`timescale 1 ns / 1 ns // timescale for following modules

module cn_ml (clk,
              reset_n,
              ctrl_start,
              sts_running,
              sts_finished,
              ram_rden,
              ram_wren,
              ram_wrdata,
              ram_addr,
              ram_rddata,
              cipher_StateIn,
              cipher_Roundkey,
              cipher_StateOut,
              h0_0,
              h0_1,
              h0_2,
              h0_3,
              h0_4,
              h0_5,
              h0_6,
              h0_7,
              h0_8,
              h0_9,
              h0_10,
              h0_11,
              h0_12,
              h0_13,
              random_addr,
              random_rdata,
              mode_speedup,
              out_ax0,
              out_bx0,
              out_bx1);
  
  `include "cn.vh"
  
  parameter ADDR_WIDTH = 15;//memory size 2Mbyte 16byte allign
  
  //  ctrl interface
  input               clk	          ;
  input               reset_n       ;
  input               ctrl_start		;
  
  //  sts interface
  output              sts_running		;
  output              sts_finished	;
  
  // Table RAM
  output  					  ram_rden      ;
  output  					  ram_wren      ;
  output  [511:0]     ram_wrdata    ;
  output  [ADDR_WIDTH-1:0] 	ram_addr  ;
  input   [511:0]     ram_rddata    ;
  
  // AES cipher round
  output 	[127:0]     cipher_StateIn	;
  output 	[127:0]     cipher_Roundkey	;
  input  	[127:0]     cipher_StateOut	;
  
  // memory map interface from last stage
  output   [127:0]     out_ax0	        ;
  output   [127:0]     out_bx0         ;
  output   [127:0]     out_bx1         ;
  
  input   [63:0]      h0_0;
  input   [63:0]      h0_1;
  input   [63:0]      h0_2;
  input   [63:0]      h0_3;
  input   [63:0]      h0_4;
  input   [63:0]      h0_5;
  input   [63:0]      h0_6;
  input   [63:0]      h0_7;
  input   [63:0]      h0_8;
  input   [63:0]      h0_9;
  input   [63:0]      h0_10;
  input   [63:0]      h0_11;
  input   [63:0]      h0_12;
  input   [63:0]      h0_13;
  
  input   [55:0]      random_rdata;
  output  [6:0]       random_addr;
  
  input               mode_speedup;
  
                                                    //  specify the multiplier delay in clock cycles
  localparam integer    MULTIPLIER_DELAY       = 1; // 1 or 2
  localparam integer    ELIMINATE_WAIT_STATE 	 = 1; // 0 or 1
  initial $display("MULTIPLIER_DELAY           = %0d", MULTIPLIER_DELAY);
  initial $display("ELIMINATE_WAIT_STATE       = %0d", ELIMINATE_WAIT_STATE);
  
  //  RAM size definition
  localparam integer BYTE_ADDRESS_BITS = ADDR_WIDTH + 4;
  
  wire [63:0]  h0 [0:13];
  assign h0[0]  = h0_0;
  assign h0[1]  = h0_1;
  assign h0[2]  = h0_2;
  assign h0[3]  = h0_3;
  assign h0[4]  = h0_4;
  assign h0[5]  = h0_5;
  assign h0[6]  = h0_6;
  assign h0[7]  = h0_7;
  assign h0[8]  = h0_8;
  assign h0[9]  = h0_9;
  assign h0[10] = h0_10;
  assign h0[11] = h0_11;
  assign h0[12] = h0_12;
  assign h0[13] = h0_13;
  
  reg   [127:0]     in_ax0            ;
  reg   [127:0]     in_bx0            ;
  reg   [127:0]     in_bx1            ;
  reg   [31:0]      in_r0 [0:3]       ;
  reg   [31:0]      r0 [0:8]          ;
  wire  [31:0]      out_r0 [0:8]      ;
  //  signals declaration
  //  input signals
  wire    [63:0]          idx0_stage1 ;
  reg     [63:0]          al0  ;
  reg     [63:0]          ah0  ;
  
  reg     [127:0]         ax0  ;
  reg     [127:0]         bx0  ;
  reg     [127:0]         bx1  ;
  
  
  reg     [63:0]        cl;
  wire    [63:0]        ch          ;
  reg     [127:0]       cx          ;
  wire    [63:0]        hi,lo       ;
  
  wire    [63:0]        idx0_stage2 ;
  
  reg     [127:0]       chk1        ;
  reg     [127:0]       chk2        ;
  reg     [127:0]       chk3        ;
  
  //data from ram
  reg     [127:0]       cx_before_aes ;
  wire     [127:0]       cx_after_aes  ;
  
  reg     [127:0]       chk1_add_bx0_stage1;
  reg     [127:0]       chk2_add_ax0_stage1;
  reg     [127:0]       chk3_add_bx1_stage1;
  reg     [127:0]       chk123_xor_cx_stage1;//update cx
  
  reg     [127:0]       chk1_add_bx0_stage2;
  reg     [127:0]       chk2_add_ax0_stage2;
  reg     [127:0]       chk3_add_bx1_stage2;
  reg     [127:0]       chk123_xor_cx_stage2;
  
  
  //define the state parameter
  parameter     phase_idle                 = 8'h1;
  parameter     phase_0_read_stage_1       = 8'h2;
  parameter     phase_1_aes_stage_1        = 8'h4;
  parameter     phase_2_write_stage_1      = 8'h8;
  parameter     phase_3_read_stage_2       = 8'h10;
  parameter     phase_4_randommath_stage_2 = 8'h20;
  parameter     phase_5_mul_stage_2        = 8'h40;
  parameter     phase_6_write_stage_2      = 8'h80;
  
  (*mark_debug = "true"*)reg     [7:0]     cs_state          ;
  (*mark_debug = "true"*)reg     [7:0]     ns_state          ;
  
  
  //  internal signals for ack
  reg     					phase_0_read_ack	;
  reg     					phase_3_read_ack	;
  reg     					phase_2_write_ack	;
  reg     					phase_6_write_ack	;
  wire              phase_4_randommath_ack;
  reg               phase_5_mul_ack   ;
  
  reg     					phase_0_read_r0	;
  reg     					phase_3_read_r0	;
  reg [17:0]        phase_5_mul_r0   ;
  
  /*
   reg     					phase_0_read_r1	;
   reg     					phase_3_read_r1	;
   reg     					phase_2_write_r1	;
   reg     					phase_6_write_r1	;
   reg                         phase_5_mul_r1   ;
   
   reg     					phase_0_read_r2	;
   reg     					phase_3_read_r2	;
   reg     					phase_2_write_r2	;
   reg     					phase_6_write_r2	;
   reg                         phase_5_mul_r2   ;
   
   reg     					phase_0_read_r3	;
   reg     					phase_3_read_r3	;
   reg     					phase_2_write_r3	;
   reg     					phase_6_write_r3	;
   reg                         phase_5_mul_r3   ;
   
   reg     					phase_0_read_r4	;
   reg     					phase_3_read_r4	;
   reg     					phase_2_write_r4	;
   reg     					phase_6_write_r4	;
   reg                         phase_5_mul_r4   ;
   
   
   wire    [127:0] 			aes_async_v	;
   reg     [127:0] 			aes				  ;//aes output
   wire    [127:0] 			product			;
   reg     [127:0] 			ram_2nd_wr_data	;
   reg     [127:0] 			ram_1st_wr_data	;
   reg     [ADDR_WIDTH - 1:0] 	ram_1st_wr_addr	;//1st write address
   reg     [ADDR_WIDTH - 1:0] 	ram_2nd_wr_addr	;//2nd write address
   reg     [ADDR_WIDTH - 1:0] 	ram_1st_rd_addr	;//1st read address
   reg     [ADDR_WIDTH - 1:0] 	ram_2nd_rd_addr	;//2nd read address
   */
                                         //  on chip RAM signals
  reg     [ADDR_WIDTH - 1:0] 	ram_addr		;//address bus to the internal ram
  reg     [1:0]               ram_addr_lowbit ;
  
  //  word addressing
  reg      [511:0] 			ram_wrdata      ;
  reg                   ram_wren        ;
  
  //  iteration counter 524288 loop
  reg     [19:0] 				iteration		    ;
  
  //  control signals
  reg    						    finished      ;
  reg    						    sts_finished  ;
  reg    						    sts_running	  ;
  reg    						    random_start  ;
  reg                   			last_loop     ;
  
  assign out_ax0 = ax0;
  assign out_bx0 = bx0;
  assign out_bx1 = bx1;
  
  localparam  speedup_mask = (1 << (ADDR_WIDTH-CFG_SPEEDUP_IL_LOG2)) - 1;//地址mask
  
  //byte address exchange,�?17bit地址
  function [ADDR_WIDTH-1:0] to_addr;
    input   [127:0] data;
    begin
      to_addr = data >> 6;
      //  if (mode_speedup)
      //    to_addr = to_addr & speedup_mask;
    end
  endfunction
  
  //byte address exchange,取低位地�?
  function [1:0] to_addr_lowbit;
    input   [127:0] data;
    begin
      to_addr_lowbit = data >> 4;
      //  if (mode_speedup)
      //    to_addr = to_addr & speedup_mask;
    end
  endfunction
  
  //字节变换
  function [127:0] byteswap;
    input [127:0] indata;
    reg [127:0] data;
    begin
      byteswap = 0; // eliminate warnings
      data     = indata;
      repeat (16) begin
        byteswap = {byteswap, data[7:0]};
        data     = data >> 8;
      end
    end
  endfunction
  
  //get the input in_ax0 in_bx0 in_bx1
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      in_ax0 <= 128'h0;
      in_bx0 <= 128'h0;
      in_bx1 <= 128'h0;
      end else begin
      in_ax0   <= {h0[1] ^ h0[5],h0[0] ^ h0[4]};
      in_bx0   <= {h0[3] ^ h0[7],h0[2] ^ h0[6]};
      in_bx1   <= {h0[9] ^ h0[11],h0[8] ^ h0[10]};
      in_r0[0] <= h0[12][31:0];
      in_r0[1] <= h0[12] >> 32;
      in_r0[2] <= h0[13][31:0];
      in_r0[3] <= h0[13] >> 32;
    end
  
  
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  //Main state machine
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      cs_state <= phase_idle;
    end
    else begin
      cs_state <= ns_state;
    end
  
  //state transfer
  always @ (*)
  begin
    ns_state = cs_state;
    case(cs_state)
      phase_idle:begin
        if (ctrl_start)begin
          ns_state = phase_0_read_stage_1;
        end
      end
      
      phase_0_read_stage_1:begin
        if (phase_0_read_ack)begin
          ns_state = phase_1_aes_stage_1;
        end
      end
      
      phase_1_aes_stage_1:begin
        ns_state = phase_2_write_stage_1;
      end
      
      phase_2_write_stage_1:begin
        if (phase_2_write_ack) begin
          ns_state = phase_3_read_stage_2;
        end
      end
      
      phase_3_read_stage_2:begin
        if (phase_3_read_ack)begin
          ns_state = phase_4_randommath_stage_2;
        end
      end
      
      phase_4_randommath_stage_2:begin
        if (phase_4_randommath_ack)begin
          ns_state = phase_5_mul_stage_2;
        end
      end
      
      phase_5_mul_stage_2:begin
        if (phase_5_mul_ack)begin
          ns_state = phase_6_write_stage_2;
        end
      end
      
      phase_6_write_stage_2:begin
        if (phase_6_write_ack)begin
          if (last_loop)begin
            ns_state = phase_idle;
            end else begin
              ns_state = phase_0_read_stage_1;
            end
          end
        end
        
    endcase
  end
  
  //status
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      sts_finished <= 1'b0;
      sts_running  <= 1'b0;
    end
    else begin
      sts_finished <= finished;
      if (cs_state == phase_idle && ns_state == phase_idle)begin
        sts_running <= 1'b0;
      end
      else begin
        sts_running <= 1'b1;
      end
    end
  
  
  //ack
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      phase_0_read_ack <= 1'b0;
      phase_0_read_r0  <= 1'b0;
    end
    else begin
      phase_0_read_ack <= phase_0_read_r0;
      if (cs_state != phase_0_read_stage_1 && ns_state == phase_0_read_stage_1)begin
        phase_0_read_r0 <= 1'b1;
      end
      else begin
        phase_0_read_r0 <= 1'b0;
      end
    end
  
  //ack
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      phase_3_read_ack <= 1'b0;
      phase_3_read_r0  <= 1'b0;
    end
    else begin
      phase_3_read_ack <= phase_3_read_r0;
      if (cs_state != phase_3_read_stage_2 && ns_state == phase_3_read_stage_2)begin
        phase_3_read_r0 <= 1'b1;
      end
      else begin
        phase_3_read_r0 <= 1'b0;
      end
    end
  
  //ack
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      phase_2_write_ack <= 1'b0;
    end
    else begin
      //phase_2_write_ack <= phase_2_write_r0;
      if (cs_state != phase_2_write_stage_1 && ns_state == phase_2_write_stage_1)begin
        phase_2_write_ack <= 1'b1;
      end
      else begin
        phase_2_write_ack <= 1'b0;
      end
    end
  
  //ack
  //  always @(posedge clk or negedge reset_n)
  //  if (!reset_n) begin
  //    phase_4_randommath_ack <= 1'b0;
  //    phase_4_randommath_r0  <= 1'b0;
  //    phase_4_randommath_r1  <= 1'b0;
  //    phase_4_randommath_r2  <= 1'b0;
  //  end else begin
  //    phase_4_randommath_r1  <= phase_4_randommath_r0;
  //    phase_4_randommath_r2  <= phase_4_randommath_r1;
  //    phase_4_randommath_ack <= phase_4_randommath_r2;
  //    if (cs_state ! = phase_4_randommath_stage_2 && ns_state == phase_4_randommath_stage_2)begin
  //      phase_4_randommath_r0 <= 1'b1;
  //    end else begin
  //      phase_4_randommath_r0 <= 1'b0;
  //    end
  //  end
  
  //ack
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      phase_5_mul_ack <= 1'b0;
      phase_5_mul_r0  <= 18'h0;
    end
    else begin
      phase_5_mul_ack <= phase_5_mul_r0[3];
      phase_5_mul_r0  <= (phase_5_mul_r0 << 1);
      if (cs_state != phase_5_mul_stage_2 && ns_state == phase_5_mul_stage_2)begin
        phase_5_mul_r0[0] <= 1'b1;
      end
      else begin
        phase_5_mul_r0[0] <= 1'b0;
      end
    end
  
  //ack
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      phase_6_write_ack   <= 1'b0;
      // phase_6_write_r0 <= 1'b0;
    end
    else begin
      // phase_6_write_ack <= phase_6_write_r0;
      if (cs_state != phase_6_write_stage_2 && ns_state == phase_6_write_stage_2)begin
        phase_6_write_ack <= 1'b1;
      end
      else begin
        phase_6_write_ack <= 1'b0;
      end
    end
  
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  //  Table RAM -- 128K words
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  //write enable
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      ram_wren <= 1'b0;
    end
    else begin
      if (cs_state == phase_1_aes_stage_1 && ns_state == phase_2_write_stage_1)begin
        ram_wren <= 1'b1;
      end
      else if (cs_state == phase_5_mul_stage_2 && ns_state == phase_6_write_stage_2) begin
        ram_wren <= 1'b1;
      end
      else begin
        ram_wren <= 1'b0;
      end
    end
  
  //ram address
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      ram_addr        <= 0;
      ram_addr_lowbit <= 0;
    end
    else begin
      if (cs_state == phase_idle && ns_state == phase_0_read_stage_1)begin//start iteration
        ram_addr        <= to_addr(in_ax0[63:0]);
        ram_addr_lowbit <= to_addr_lowbit(in_ax0[63:0]);
      end
      else if (cs_state == phase_6_write_stage_2 && ns_state == phase_0_read_stage_1)begin
        ram_addr        <= to_addr(al0 ^ cl);
        ram_addr_lowbit <= to_addr_lowbit(al0 ^ cl);
      end
        else if (ns_state == phase_3_read_stage_2) begin
        ram_addr        <= to_addr(cx[63:0]);
        ram_addr_lowbit <= to_addr_lowbit(cx[63:0]);
        end
      else begin
        ram_addr_lowbit <= ram_addr_lowbit;
        ram_addr        <= ram_addr;
      end
    end
  
  
  // ram address
  // always @(posedge clk or negedge reset_n)
  // if (!reset_n) begin
  // ram_addr <= 0;
  // end else begin
  // if (ns_state == phase_0_read_stage_1)begin
  // ram_addr <= to_addr(idx0_stage1);
  // end else if (ns_state == phase_3_read_stage_2) begin
  // ram_addr <= to_addr(idx0_stage2);
  // end
  // end
  
  //---------------------------------------------------------------------------
  //    chk12xorcx chk3xorb1 chk1xorb0 chk2xora0
  //addr   0x00       0x01     0x10       0x11
  //0x00   0x00       0x01     0x10       0x11
  //0x01   0x01       0x00     0x11       0x10
  //0x10   0x10       0x11     0x00       0x01
  //0x11   0x11       0x10     0x01       0x00
  //---------------------------------------------------------------------------
  //write data
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      ram_wrdata <= 0;
      end else begin
      if (ns_state == phase_2_write_stage_1) begin
        case(ram_addr_lowbit[1:0])
          2'b00:begin
            ram_wrdata <= {chk2_add_ax0_stage1,chk1_add_bx0_stage1,chk3_add_bx1_stage1,chk123_xor_cx_stage1};
          end
          
          2'b01:begin
            ram_wrdata <= {chk1_add_bx0_stage1,chk2_add_ax0_stage1,chk123_xor_cx_stage1,chk3_add_bx1_stage1};
          end
          
          2'b10:begin
            ram_wrdata <= {chk3_add_bx1_stage1,chk123_xor_cx_stage1,chk2_add_ax0_stage1,chk1_add_bx0_stage1};
          end
          
          2'b11:begin
            ram_wrdata <= {chk123_xor_cx_stage1,chk3_add_bx1_stage1,chk1_add_bx0_stage1,chk2_add_ax0_stage1};
          end
        endcase
        end else begin
        case(ram_addr_lowbit[1:0])
          2'b00:begin
            ram_wrdata <= {chk2_add_ax0_stage2,chk1_add_bx0_stage2,chk3_add_bx1_stage2,chk123_xor_cx_stage2};
          end
          
          2'b01:begin
            ram_wrdata <= {chk1_add_bx0_stage2,chk2_add_ax0_stage2,chk123_xor_cx_stage2,chk3_add_bx1_stage2};
          end
          
          2'b10:begin
            ram_wrdata <= {chk3_add_bx1_stage2,chk123_xor_cx_stage2,chk2_add_ax0_stage2,chk1_add_bx0_stage2};
          end
          
          2'b11:begin
            ram_wrdata <= {chk123_xor_cx_stage2,chk3_add_bx1_stage2,chk1_add_bx0_stage2,chk2_add_ax0_stage2};
          end
        endcase
      end
    end
  
  
  //write back data
  always@(*)
  begin
    chk123_xor_cx_stage1 = cx_after_aes ^ chk1 ^ chk2 ^ chk3 ^ bx0;//cx xor chk1 xor ch2 xor ch3 xor bx0
    chk1_add_bx0_stage1  = {chk1[127:64] + bx0[127:64],chk1[63:0] + bx0[63:0]};
    chk2_add_ax0_stage1  = {chk2[127:64] + ax0[127:64],chk2[63:0] + ax0[63:0]};
    chk3_add_bx1_stage1  = {chk3[127:64] + bx1[127:64],chk3[63:0] + bx1[63:0]};
    chk123_xor_cx_stage2 = {ah0+lo,al0+hi};
    chk1_add_bx0_stage2  = chk1_add_bx0_stage1;
    chk2_add_ax0_stage2  = chk2_add_ax0_stage1;
    chk3_add_bx1_stage2  = chk3_add_bx1_stage1;
    //    cx             = cx_after_aes ^ chk1 ^ chk2 ^ chk3;
  end
  
  //---------------------------------------------------------------------------
  //   0x1 0x2 0x3
  //00 01  10  11
  //01 00  11  10
  //10 11  00  01
  //11 10  01  00
  //---------------------------------------------------------------------------
  //update the ram output
  //chk1 chk2 chk3 cx and cl ch
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      chk1          <= 0;
      chk2          <= 0;
      chk3          <= 0;
      cx_before_aes <= 0;
      end else begin
      if (phase_0_read_ack | phase_3_read_ack)begin
        case(ram_addr_lowbit[1:0])
          2'b00:begin
            cx_before_aes <= ram_rddata[127:0];
            chk1          <= ram_rddata[255:128];
            chk2          <= ram_rddata[128*2+127:128*2];
            chk3          <= ram_rddata[128*3+127:128*3];
          end
          
          2'b01:begin
            chk1          <= ram_rddata[127:0];
            cx_before_aes <= ram_rddata[128+127:128];
            chk3          <= ram_rddata[128*2+127:128*2];
            chk2          <= ram_rddata[128*3+127:128*3];
          end
          
          2'b10:begin
            chk2          <= ram_rddata[127:0];
            chk3          <= ram_rddata[128+127:128];
            cx_before_aes <= ram_rddata[128*2+127:128*2];
            chk1          <= ram_rddata[128*3+127:128*3];
          end
          
          2'b11:begin
            chk3          <= ram_rddata[127:0];
            chk2          <= ram_rddata[128+127:128];
            chk1          <= ram_rddata[128*2+127:128*2];
            cx_before_aes <= ram_rddata[128*3+127:128*3];
          end
          
        endcase
      end
    end
  
  //al0,ah0,ax0,bx0,bx1,bx1 update
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      al0 <= 0;
      ah0 <= 0;
      ax0 <= 0;
      bx0 <= 0;
      bx1 <= 0;
    end
    else begin
      if (cs_state == phase_idle && ns_state == phase_0_read_stage_1)begin//start iteration
        al0 <= in_ax0[63:0];
        ah0 <= in_ax0[127:64];
        ax0 <= in_ax0;
        bx0 <= in_bx0;
        bx1 <= in_bx1;
      end
      else if (phase_4_randommath_ack) begin
        al0 <= al0 ^ (out_r0[2] | (out_r0[3] << 32));
        ah0 <= ah0 ^ (out_r0[0] | (out_r0[1] << 32));
      end
        else if (phase_5_mul_ack) begin
        al0 <= al0 + hi;
        ah0 <= ah0 + lo;
        end
        else if (cs_state == phase_6_write_stage_2 && ns_state == phase_0_read_stage_1) begin
        al0 <= al0 ^ cl;
        ah0 <= ah0 ^ ch;
        ax0 <= {ah0 ^ ch,al0 ^ cl};
        bx0 <= cx ^ chk1 ^ chk2 ^ chk3;
        bx1 <= bx0;
        end
      else begin
      end
    end
  
  //r0 update
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      r0[0]        <= 32'h0;
      r0[1]        <= 32'h0;
      r0[2]        <= 32'h0;
      r0[3]        <= 32'h0;
      r0[4]        <= 32'h0;
      r0[5]        <= 32'h0;
      r0[6]        <= 32'h0;
      r0[7]        <= 32'h0;
      r0[8]        <= 32'h0;
      random_start <= 1'b0;
    end
    else begin
      random_start <= 1'b0;
      if (cs_state == phase_idle && ns_state == phase_0_read_stage_1)begin//start iteration
        r0[0] <= in_r0[0];
        r0[1] <= in_r0[1];
        r0[2] <= in_r0[2];
        r0[3] <= in_r0[3];
      end
      else if (phase_4_randommath_ack) begin
        r0[0] <= out_r0[0];
        r0[1] <= out_r0[1];
        r0[2] <= out_r0[2];
        r0[3] <= out_r0[3];
      end
        else if (ns_state == phase_4_randommath_stage_2 && cs_state == phase_3_read_stage_2) begin
        r0[4]        <= al0[31:0];
        r0[5]        <= ah0[31:0];
        r0[6]        <= bx0[31:0];
        r0[7]        <= bx1[31:0];
        r0[8]        <= bx1[95:64];
        random_start <= 1'b1;
        end
      else begin
        
      end
    end
  
  wire [31:0] tmp_r00r01 = r0[0] + r0[1];
  //this place can optmize in future
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      cl <= 0;
      end else begin
      if (phase_4_randommath_ack) begin
        cl <= cx_before_aes[63:0] ^ (tmp_r00r01 | ((r0[2] + r0[3]) << 32));
      end
    end
  
  // idx generation
  // assign idx0_stage1 = al0;
  // assign idx0_stage2 = cx[63:0];
  //idx update
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      cx <= 0;
      end else begin
      if (cs_state == phase_1_aes_stage_1) begin
        cx <= cx_after_aes ^ chk1 ^ chk2 ^ chk3 ;
      end
    end
  
  assign cipher_StateIn  = cx_before_aes;
  assign cipher_Roundkey = byteswap(ax0);
  assign cx_after_aes    = cipher_StateOut;
  
  
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  //  random math
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  random_math random_math_inst(
  .clk(clk),
  .reset_n(reset_n),
  .start(random_start),//start
  
  .in_r0_0(r0[0]),
  .in_r0_1(r0[1]),
  .in_r0_2(r0[2]),
  .in_r0_3(r0[3]),
  .in_r0_4(r0[4]),
  .in_r0_5(r0[5]),
  .in_r0_6(r0[6]),
  .in_r0_7(r0[7]),
  .in_r0_8(r0[8]),
  
  .random_ram_addr(random_addr),
  .random_ram_rdata(random_rdata),
  
  .random_ack(phase_4_randommath_ack),
  .out_r0_0(out_r0[0]),
  .out_r0_1(out_r0[1]),
  .out_r0_2(out_r0[2]),
  .out_r0_3(out_r0[3])
  );
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  //  multiplier
  // ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  ==  == 
  // assign {hi,lo} = idx0_stage2[63:0] * cl;
  
  mult_64wx64w_unsigned mult_64wx64w_inst(
  .CLK(clk),
  //.SCLR(phase_0_read_r0),
  .A(cl),
  .B(cx[63:0]),
  .P({hi,lo})
  );
  
  //  wire [127:0] a1 = cx[63:0];
  //  wire [127:0] b1 = cl;
  //  assign {hi,lo}  = a1 * b1;
  
  assign ch = cx_before_aes[127:64];
  
  //  Iteration counter�?524288计数�?
  always @(negedge reset_n or posedge clk)
    if (!reset_n)begin
      iteration <= 0;
    end
    else if (ns_state == phase_1_aes_stage_1 && cs_state == phase_0_read_stage_1) begin
      iteration <= iteration + 1;
    end
      else if (cs_state == phase_idle)begin
      iteration <= 0;
      end
    else begin
    end
  
                                                                               // Run/finish
  parameter last_iteration_full    = (20'b1 << 19) - 1;                        //524288 loop only for simulation
  parameter last_iteration_speedup = (20'b1 << (19 - CFG_SPEEDUP_ML_LOG2)) - 1;//speed loop only for simulation
  
  wire [19:0] last_iteration = mode_speedup ? last_iteration_speedup : last_iteration_full;
  
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      last_loop <= 0;
    end
    else begin
      if (iteration >= last_iteration+1) begin
        last_loop <= 1'b1;
      end
      else begin
        last_loop <= 1'b0;
      end
    end
  
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      finished <= 0;
    end
    else begin
      if (last_loop && cs_state == phase_6_write_stage_2) begin
        finished <= 1'b1;
      end
      else begin
        finished <= 1'b0;
      end
    end
  
endmodule // module cn_ml

`timescale 1 ns / 1 ps // timescale for following modules
  
  
module multi_core_top (clk,
               reset_n,
//                sts_ml_finished,
               mem_address,
               mem_write,
               mem_wrdata,
               mem_rddata,
               reg_address,
               reg_write,
               reg_wrdata,
               reg_rddata);

  `include "cn.vh"

  parameter ADDR_WIDTH = 19;
  parameter UNROLL     = 2;
  parameter CORE_NUM   = 1;

  initial $display("ADDR_WIDTH = %0d", ADDR_WIDTH);
  initial $display("UNROLL     = %0d", UNROLL);

  input      clk;
  input      reset_n;

  // Buffer interface
  // input          reg_cs;
  input  [9+4:0]      reg_address;
  input               reg_write;
  input  [31:0]       reg_wrdata;
  (*mark_debug = "true"*)output reg [31:0]       reg_rddata;

  input  [ADDR_WIDTH+1:0]   mem_address;
  input               mem_write;
  input  [127:0]      mem_wrdata;
  (*mark_debug = "true"*)output reg [127:0]      mem_rddata;

  (*mark_debug = "true"*)reg     [9:0]       reg_address_core ;
  (*mark_debug = "true"*)reg                 reg_write_core   [0:CORE_NUM-1];
  (*mark_debug = "true"*)reg     [31:0]      reg_wrdata_core  ;
  wire    [31:0]      reg_rddata_core  [0:CORE_NUM-1];


  (*mark_debug = "true"*)reg     [16:0]      mem_address_core ;
  (*mark_debug = "true"*)reg                 mem_write_core   [0:CORE_NUM-1];
  (*mark_debug = "true"*)reg     [127:0]     mem_wrdata_core  ;
  wire    [127:0]     mem_rddata_core  [0:CORE_NUM-1];
  reg     [7:0]       i;
  reg     [3:0]       mem_addr_lat      [1:0];
  reg     [3:0]       reg_addr_lat      [1:0];

//reg write
always@(posedge clk or negedge reset_n)
if(!reset_n)begin
    for(i=0;i<CORE_NUM;i=i+1)begin
       reg_write_core[i] <= 1'b0; 
    end
end else begin
    for(i=0;i<CORE_NUM;i=i+1)begin
       reg_write_core[i] <= 1'b0; 
    end
    reg_write_core[reg_address[13:10]] <= reg_write;
end

//mem write
always@(posedge clk or negedge reset_n)
if(!reset_n)begin
    mem_addr_lat[0] <= 0;
    mem_addr_lat[1] <= 0;
    reg_addr_lat[0] <= 0;
    reg_addr_lat[1] <= 0;
end else begin
    mem_addr_lat[0] <= mem_address[20:17];
    mem_addr_lat[1] <= mem_addr_lat[0];
    reg_addr_lat[0] <= reg_address[13:10];
    reg_addr_lat[1] <= reg_addr_lat[0];
end

//mem write
always@(posedge clk or negedge reset_n)
if(!reset_n)begin
    for(i=0;i<CORE_NUM;i=i+1)begin
       mem_write_core[i] <= 1'b0; 
    end
end else begin
    for(i=0;i<CORE_NUM;i=i+1)begin
       mem_write_core[i] <= 1'b0; 
    end
    mem_write_core[mem_address[ADDR_WIDTH+1:ADDR_WIDTH-2]] <= mem_write;
end

always@(posedge clk or negedge reset_n)
if(!reset_n)begin
    reg_wrdata_core <= 32'h0;
    mem_wrdata_core <= 128'h0;
    reg_address_core <= 0;
    mem_address_core <= 0;
end else begin
    reg_wrdata_core <= reg_wrdata;
    mem_wrdata_core <= mem_wrdata;
    reg_address_core <= reg_address[9:0];
    mem_address_core <= mem_address[16:0];
end


always@(posedge clk or negedge reset_n)
if(!reset_n)begin
    mem_rddata <= 128'h0;
    reg_rddata <= 32'h0;
end else begin
    mem_rddata = mem_rddata_core[mem_addr_lat[1]];
    reg_rddata = reg_rddata_core[reg_addr_lat[1]];
end


genvar gi;
//generate
  for (gi=0; gi<CORE_NUM; gi=gi+1) begin 
         cn_top cn_top_inst(
                .clk        (clk),
                .reset_n    (reset_n),
                
                .sts_ml_finished(),
                //avalon mem slave interface
                .mem_address(mem_address_core),
                .mem_write  (mem_write_core[gi]),
                .mem_wrdata (mem_wrdata_core),
                .mem_rddata (mem_rddata_core[gi]),
                
                //avalon reg slave interface
                .reg_address(reg_address_core),
                .reg_write  (reg_write_core[gi]),
                .reg_wrdata (reg_wrdata_core),
                .reg_rddata (reg_rddata_core[gi])
   );
  end
//end generate

endmodule

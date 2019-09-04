`timescale 1 ns / 1 ps // timescale for following modules


module cn_top (clk,
               reset_n,
               sts_ml_finished,
               mem_address,
               mem_write,
               mem_wrdata,
               mem_rddata,
               reg_address,
               reg_write,
               reg_wrdata,
               reg_rddata);
  
  `include "cn.vh"
  
  parameter ADDR_WIDTH = 15;
  parameter UNROLL     = 2;
  
  initial $display("ADDR_WIDTH = %0d", ADDR_WIDTH);
  initial $display("UNROLL     = %0d", UNROLL);
  
  input      clk;
  input      reset_n;
  
  // Buffer interface
  // input          reg_cs;
  input  [9:0]    reg_address;
  input           reg_write;
  input  [31:0]   reg_wrdata;
  output [31:0]   reg_rddata;
  
  input  [ADDR_WIDTH+1:0]   mem_address;
  input           mem_write;
  input  [127:0]  mem_wrdata;
  output [127:0]  mem_rddata;
  output          sts_ml_finished;
  
  wire mode_speedup = 1'b0;
  
  //reg   [127:0]   initial_ax0;
  //reg   [127:0]   initial_bx0;
  //reg   [127:0]   initial_bx1;
  
  reg  [63:0]     h0  [0:13];
  
  wire [127:0]    ml_cipher_StateIn ;
  wire [127:0]    ml_cipher_Roundkey;
  wire [127:0]    ml_cipher_StateOut;
  
  wire [511:0]    ml_ram_wrdata;
  wire [511:0]    ml_ram_rddata;
  wire [ADDR_WIDTH-1:0]    ml_ram_addr;
  wire            ml_ram_we;
  wire            ml_ram_re;
  reg             sm_ml_start;
  wire [511:0]    ram_rddata;
  wire            sts_ml_running;
  
  reg  [127:0]  mem_rddata;
  
  reg  [63:0]   random_rdata;
  wire [6:0]    random_addr;
  
  reg [63:0]    code0 [0:70];//save the op code
  reg [31:0]    reg_rddata;
  reg [31:0]    sts_reg;//bit0:finish bit1:busy
  
  parameter version = 32'h19070416;
  
  //register output
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      reg_rddata <= 0;
    end
    else begin
      if (reg_address[9:8] == 2'b00 && reg_address[0] == 1'b0) begin
		reg_rddata <= code0[reg_address[7:1]][31:0];
	  end else if (reg_address[9:8] == 2'b00 && reg_address[0] == 1'b1) begin
		reg_rddata <= code0[reg_address[7:1]][31+32:32];
	  end else if (reg_address[9:8] == 2'b01 && reg_address[0] == 1'b0) begin
		reg_rddata <= h0[reg_address[4:1]][31:0];
	  end else if (reg_address[9:8] == 2'b01 && reg_address[0] == 1'b1) begin
		reg_rddata <= h0[reg_address[4:1]][31+32:32];
	  end else if(reg_address[9:8] == 2'b10 && reg_address[3:0] == 4'h0) begin
		reg_rddata <= sts_reg;
	  end else if(reg_address[9:8] == 2'b10 && reg_address[3:0] == 4'h1) begin
	    reg_rddata <= version;
      end else begin
        reg_rddata <= 32'h12345678;
      end
    end
  
  //pc configuration
  always @(posedge clk or negedge reset_n)
    if (!reset_n) begin
      sm_ml_start <= 0;
      h0[0] <= 64'h0;
      h0[1] <= 64'h0;
      h0[2] <= 64'h0;
      h0[3] <= 64'h0;
      h0[4] <= 64'h0;
      h0[5] <= 64'h0;
      h0[6] <= 64'h0;
      h0[7] <= 64'h0;
      h0[8] <= 64'h0;
      h0[9] <= 64'h0;
      h0[10] <= 64'h0;
      h0[11] <= 64'h0;
      h0[12] <= 64'h0;
      h0[13] <= 64'h0;
    end
    else begin
      if (reg_write && reg_address[9:8] == 2'b01 && reg_address[0] == 1'b0)
        h0[reg_address[4:1]][31:0] <= reg_wrdata;
      else if (reg_write && reg_address[9:8] == 2'b01 && reg_address[0] == 1'b1)
        h0[reg_address[4:1]][63:32] <= reg_wrdata;
      else begin
      end
      //start the crypto core
      if (reg_write && reg_address[9:8] == 2'b10 && reg_address[3:0] == 4'h0)
        sm_ml_start <= reg_wrdata[0];
      else begin
        sm_ml_start <= 1'b0;
      end
    end
  
  //code save for test
    reg [7:0] i;
	always @(posedge clk or negedge reset_n )
	if(!reset_n)begin
        for(i=0;i<71;i=i+1)begin
            code0[i] <= 64'h1324576813245897; 
        end
	end	else if (reg_write && reg_address[9:8] == 2'b00 && reg_address[0] == 1'b0) begin
        code0[reg_address[7:1]][31:0] <= reg_wrdata;
	end else if (reg_write && reg_address[9:8] == 2'b00 && reg_address[0] == 1'b1) begin
        code0[reg_address[7:1]][63:32] <= reg_wrdata;
	end
  
   //sts reg
  always @(posedge clk or negedge reset_n)
  if (!reset_n)begin
	sts_reg <= 32'h0;
  end else begin
	if(sts_ml_finished) begin
		sts_reg[0] <= 1;
	end else if (reg_write && reg_address[9:8] == 2'b10 && reg_address[3:0] == 4'h1) begin
		sts_reg[0] <= reg_wrdata[0];
	end 
	sts_reg[1] <= sts_ml_running;
  end

   //soft reset
  reg    soft_reset_n;
  always @(posedge clk or negedge reset_n)
  if (!reset_n)begin
	soft_reset_n <= 1'b0;
  end else begin
	if (reg_write && reg_address[9:8] == 2'b10 && reg_address[3:0] == 4'h2) begin
		soft_reset_n <= 1'b0;
	end else begin
                soft_reset_n <= 1'b1;
        end
  end
  

  
  //read the random reg
	always @(posedge clk or negedge reset_n)
	if (!reset_n) begin
		random_rdata <= 64'h0;
	end else begin
		random_rdata <= code0[random_addr];
	end
	
  
  assign ml_ram_rddata = ram_rddata;
  //memory loop
  cn_ml #(.ADDR_WIDTH(ADDR_WIDTH)) cn_ml_inst (
  .clk(clk),
  .reset_n(soft_reset_n),
  // ctrl interface
  .ctrl_start(sm_ml_start),
  // sts interface
  .sts_running(sts_ml_running),
  .sts_finished(sts_ml_finished),
  // Table RAM
  .ram_rden(ml_ram_re),
  .ram_wren(ml_ram_we),
  .ram_wrdata(ml_ram_wrdata),
  .ram_addr(ml_ram_addr),
  .ram_rddata(ml_ram_rddata),
  // AES cipher round
  .cipher_StateIn(ml_cipher_StateIn),
  .cipher_Roundkey(ml_cipher_Roundkey),
  .cipher_StateOut(ml_cipher_StateOut),
  // input signals
  
  .h0_0(h0[0]),
  .h0_1(h0[1]),
  .h0_2(h0[2]),
  .h0_3(h0[3]),
  .h0_4(h0[4]),
  .h0_5(h0[5]),
  .h0_6(h0[6]),
  .h0_7(h0[7]),
  .h0_8(h0[8]),
  .h0_9(h0[9]),
  .h0_10(h0[10]),
  .h0_11(h0[11]),
  .h0_12(h0[12]),
  .h0_13(h0[13]),
  
  .random_addr(random_addr),
  .random_rdata(random_rdata),
  .out_ax0(out_ax0),
  .out_bx0(out_bx0),
  .out_bx1(out_bx1),
  // Test modes
  .mode_speedup(mode_speedup)
  );
  
  // -----------------------------------------------------------------------------------
  // AES combinatorial
  // -----------------------------------------------------------------------------------
  cipherRound_mod aes_inst_ml (
  .last_cipher_iteration(1'b0),
  .StateIn(ml_cipher_StateIn),
  .Roundkey(ml_cipher_Roundkey),
  .StateOut(ml_cipher_StateOut));
  
  // -----------------------------------------------------------------------------------
  // Table RAM dualport
  // -----------------------------------------------------------------------------------
  wire        mem_write_0;
  wire        mem_write_1;
  wire        mem_write_2;
  wire        mem_write_3;
  assign      mem_write_0 = (mem_address[1:0] == 2'b00)?mem_write:1'b0;
  assign      mem_write_1 = (mem_address[1:0] == 2'b01)?mem_write:1'b0;
  assign      mem_write_2 = (mem_address[1:0] == 2'b10)?mem_write:1'b0;
  assign      mem_write_3 = (mem_address[1:0] == 2'b11)?mem_write:1'b0;
  
  reg [1:0]   mem_address_r;
  always @(posedge clk or negedge reset_n)
	if (!reset_n) begin
		mem_address_r <= 2'h0;
	end else begin
		mem_address_r <= mem_address;
	end

  always@(*)
  begin
    case(mem_address_r[1:0])
      2'b00:begin
        mem_rddata = ram_rddata[127:0];
      end
      
      2'b01:begin
        mem_rddata = ram_rddata[128+127:128];
      end
      
      2'b10:begin
        mem_rddata = ram_rddata[128*2+127:128*2];
      end
      
      2'b11:begin
        mem_rddata = ram_rddata[128*3+127:128*3];
      end
      
      default:mem_rddata = ram_rddata[127:0];
    endcase
  end
  
  uram_32768D128W cryptonightR_ram_inst_0(
  .clka(clk),
  .ena(1'b1),
  .wea(sts_ml_running ? ml_ram_we : mem_write_0),
  .addra(sts_ml_running ? ml_ram_addr : mem_address[16:2]),
  .dina(sts_ml_running ? ml_ram_wrdata[127:0] : mem_wrdata),
  .douta(ram_rddata[127:0])
  );
  
  uram_32768D128W cryptonightR_ram_inst_1(
  .clka(clk),
  .ena(1'b1),
  .wea(sts_ml_running ? ml_ram_we : mem_write_1),
  .addra(sts_ml_running ? ml_ram_addr : mem_address[16:2]),
  .dina(sts_ml_running ? ml_ram_wrdata[128+127:128] : mem_wrdata),
  .douta(ram_rddata[128+127:128])
  );
  
  uram_32768D128W cryptonightR_ram_inst_2(
  .clka(clk),
  .ena(1'b1),
  .wea(sts_ml_running ? ml_ram_we : mem_write_2),
  .addra(sts_ml_running ? ml_ram_addr : mem_address[16:2]),
  .dina(sts_ml_running ? ml_ram_wrdata[128*2+127:128*2] : mem_wrdata),
  .douta(ram_rddata[128*2+127:128*2])
  );
  
  uram_32768D128W cryptonightR_ram_inst_3(
  .clka(clk),
  .ena(1'b1),
  .wea(sts_ml_running ? ml_ram_we : mem_write_3),
  .addra(sts_ml_running ? ml_ram_addr : mem_address[16:2]),
  .dina(sts_ml_running ? ml_ram_wrdata[128*3+127:128*3] : mem_wrdata),
  .douta(ram_rddata[128*3+127:128*3])
  );
  
endmodule // module cn_top

//-----------------------------------------------------------------------------
//
// (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : xdma_app.v
// Version    : 4.1
//-----------------------------------------------------------------------------

`timescale 1ps / 1ps
module xdma_app #(
  parameter TCQ                         = 1,
  parameter C_M_AXI_ID_WIDTH            = 4,
  parameter PL_LINK_CAP_MAX_LINK_WIDTH  = 2,
  parameter C_DATA_WIDTH                = 128,
  parameter C_M_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXI_DATA_WIDTH          = C_DATA_WIDTH,
  parameter C_S_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_DATA_WIDTH         = C_DATA_WIDTH,
  parameter C_M_AXIS_RQ_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 137 : 62),
  parameter C_S_AXIS_CQP_USER_WIDTH     = ((C_DATA_WIDTH == 512) ? 183 : 88),
  parameter C_M_AXIS_RC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ? 161 : 75),
  parameter C_S_AXIS_CC_USER_WIDTH      = ((C_DATA_WIDTH == 512) ?  81 : 33),
  parameter C_S_KEEP_WIDTH              = C_S_AXI_DATA_WIDTH / 32,
  parameter C_M_KEEP_WIDTH              = (C_M_AXI_DATA_WIDTH / 32),
  parameter C_XDMA_NUM_CHNL             = 1
)
(

  // AXI Lite Master Interface connections
  input  wire  [31:0] s_axil_awaddr,
  input  wire         s_axil_awvalid,
  output wire         s_axil_awready,
  input  wire  [31:0] s_axil_wdata,
  input  wire   [3:0] s_axil_wstrb,
  input  wire         s_axil_wvalid,
  output wire         s_axil_wready,
  output wire   [1:0] s_axil_bresp,
  output wire         s_axil_bvalid,
  input  wire         s_axil_bready,
  input  wire  [31:0] s_axil_araddr,
  input  wire         s_axil_arvalid,
  output wire         s_axil_arready,
  output wire  [31:0] s_axil_rdata,
  output wire   [1:0] s_axil_rresp,
  output wire         s_axil_rvalid,
  input  wire         s_axil_rready,


//VU9P_TUL_EX_String= FALSE

  // AXI Memory Mapped interface
  input  wire  [C_M_AXI_ID_WIDTH-1:0] s_axi_awid,
  input  wire  [64-1:0] s_axi_awaddr,
  input  wire   [7:0] s_axi_awlen,
  input  wire   [2:0] s_axi_awsize,
  input  wire   [1:0] s_axi_awburst,
  input  wire         s_axi_awvalid,
  output wire         s_axi_awready,
  input  wire [C_M_AXI_DATA_WIDTH-1:0]        s_axi_wdata,
  input  wire [(C_M_AXI_DATA_WIDTH/8)-1:0]    s_axi_wstrb,
  input  wire         s_axi_wlast,
  input  wire         s_axi_wvalid,
  output wire         s_axi_wready,
  output wire [C_M_AXI_ID_WIDTH-1:0]          s_axi_bid,
  output wire   [1:0] s_axi_bresp,
  output wire         s_axi_bvalid,
  input  wire         s_axi_bready,
  input  wire [C_M_AXI_ID_WIDTH-1:0]          s_axi_arid,
  input  wire  [64-1:0] s_axi_araddr,
  input  wire   [7:0] s_axi_arlen,
  input  wire   [2:0] s_axi_arsize,
  input  wire   [1:0] s_axi_arburst,
  input  wire         s_axi_arvalid,
  output wire         s_axi_arready,
  output wire   [C_M_AXI_ID_WIDTH-1:0]        s_axi_rid,
  output wire   [C_M_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
  output wire   [1:0] s_axi_rresp,
  output wire         s_axi_rlast,
  output wire         s_axi_rvalid,
  input  wire         s_axi_rready,

  // AXI stream interface for the CQ forwarding
  input  wire  [C_M_AXI_ID_WIDTH-1:0]  s_axib_awid,
  input  wire  [18:0] s_axib_awaddr,
  input  wire   [7:0] s_axib_awlen,
  input  wire   [2:0] s_axib_awsize,
  input  wire   [1:0] s_axib_awburst,
  input  wire         s_axib_awvalid,
  output wire         s_axib_awready,
  input  wire  [C_M_AXI_DATA_WIDTH-1:0]        s_axib_wdata,
  input  wire  [(C_M_AXI_DATA_WIDTH/8)-1:0]    s_axib_wstrb,
  input  wire         s_axib_wlast,
  input  wire         s_axib_wvalid,
  output wire         s_axib_wready,
  output wire  [C_M_AXI_ID_WIDTH-1:0]          s_axib_bid,
  output wire   [1:0] s_axib_bresp,
  output wire         s_axib_bvalid,
  input  wire         s_axib_bready,
  input  wire [C_M_AXI_ID_WIDTH-1:0]           s_axib_arid,
  input  wire  [18:0] s_axib_araddr,
  input  wire   [7:0] s_axib_arlen,
  input  wire   [2:0] s_axib_arsize,
  input  wire   [1:0] s_axib_arburst,
  input  wire         s_axib_arvalid,
  output wire         s_axib_arready,
  output wire [C_M_AXI_ID_WIDTH-1:0]           s_axib_rid,
  output wire [C_M_AXI_DATA_WIDTH-1:0]         s_axib_rdata,
  output wire   [1:0] s_axib_rresp,
  output wire         s_axib_rlast,
  output wire         s_axib_rvalid,
  input  wire         s_axib_rready,

  //local register read and write 
  output wire [32-1:0]   local_reg_wdata,
  output wire            local_reg_wren,
  output wire [32-1:0]   local_reg_addr,
  input  wire [32-1:0]   local_reg_rdata,
  input                 local_reg_clk,

  //local dma read and write 
  output wire [128-1:0]   local_dma_wdata,
  output wire            local_dma_wren,
  output wire [32-1:0]   local_dma_addr,
  input  wire [128-1:0]   local_dma_rdata,
  input                 local_dma_clk,

  // System IO signals
  input  wire         user_resetn,
  input  wire         sys_rst_n,
 
  input  wire         user_clk,
  input  wire         user_lnk_up,
  output wire   [3:0] leds

);
  // wire/reg declarations
  wire            sys_reset;
  reg  [25:0]     user_clk_heartbeat;


    wire [32-1:0]   local_mem_wdata_0;
    wire            local_mem_wren_0;
    wire [32-1:0]   local_mem_addr_0;
    wire [32-1:0]   local_mem_rdata_0;
    wire            local_mem_clk_0;

    wire [128-1:0]  local_mem_wdata_1;
    wire            local_mem_wren_1;
    wire [32-1:0]   local_mem_addr_1;
    wire [128-1:0]  local_mem_rdata_1;
    wire            local_mem_clk_1;

    wire [128-1:0]  local_mem_wdata_2;
    wire            local_mem_wren_2;
    wire [32-1:0]   local_mem_addr_2;
    wire [128-1:0]  local_mem_rdata_2;
    wire            local_mem_clk_2;
    
    wire            avm_read_0;
    wire [(32)/8 -1 : 0] avm_byteenable_0;
    wire [32 -1 : 0] avm_writedata_0;
    wire [32 -1 : 0] avm_readdata_0;
    wire [1 : 0]    avm_resp_0;
    wire            avm_readdatavalid_0;
    wire [9 -1 : 0] avm_burstcount_0;
    wire            avm_beginbursttransfer_0;
    wire            avm_writeresponsevalid_0;
    wire            avm_waitrequest_0;
    wire [32-1:0]   avm_address_0;
    
    wire            avm_read_1;
    wire [(C_DATA_WIDTH)/8 -1 : 0] avm_byteenable_1;
    wire [C_DATA_WIDTH -1 : 0] avm_writedata_1;
    wire [C_DATA_WIDTH -1 : 0] avm_readdata_1;
    wire [1 : 0]    avm_resp_1;
    wire            avm_readdatavalid_1;
    wire [9 -1 : 0] avm_burstcount_1;
    wire            avm_beginbursttransfer_1;
    wire            avm_writeresponsevalid_1;
    wire            avm_waitrequest_1;
    wire [32-1:0]   avm_address_1;

    wire            avm_read_2;
    wire [(C_DATA_WIDTH)/8 -1 : 0] avm_byteenable_2;
    wire [C_DATA_WIDTH -1 : 0] avm_writedata_2;
    wire [C_DATA_WIDTH -1 : 0] avm_readdata_2;
    wire [1 : 0]    avm_resp_2;
    wire            avm_readdatavalid_2;
    wire [9 -1 : 0] avm_burstcount_2;
    wire            avm_beginbursttransfer_2;
    wire            avm_writeresponsevalid_2;
    wire            avm_waitrequest_2;
    wire [32-1:0]   avm_address_2;

    //clock conver for dma interface
    wire  [C_M_AXI_ID_WIDTH-1:0]    local_dma_axi_awid;
    wire  [64-1:0]                  local_dma_axi_awaddr;
    wire  [7:0]                     local_dma_axi_awlen;
    wire  [2:0]                     local_dma_axi_awsize;
    wire  [1:0]                     local_dma_axi_awburst;
    wire                            local_dma_axi_awvalid;
    wire                            local_dma_axi_awready;
    wire [C_M_AXI_DATA_WIDTH-1:0]       local_dma_axi_wdata;
    wire [(C_M_AXI_DATA_WIDTH/8)-1:0]    local_dma_axi_wstrb;
    wire                            local_dma_axi_wlast;
    wire                            local_dma_axi_wvalid;
    wire                            local_dma_axi_wready;
    wire [C_M_AXI_ID_WIDTH-1:0]     local_dma_axi_bid;
    wire   [1:0]                    local_dma_axi_bresp;
    wire                            local_dma_axi_bvalid;
    wire                            local_dma_axi_bready;
    wire [C_M_AXI_ID_WIDTH-1:0]     local_dma_axi_arid;
    wire  [64-1:0]                  local_dma_axi_araddr;
    wire   [7:0]                    local_dma_axi_arlen;
    wire   [2:0]                    local_dma_axi_arsize;
    wire   [1:0]                    local_dma_axi_arburst;
    wire                            local_dma_axi_arvalid;
    wire                            local_dma_axi_arready;
    wire   [C_M_AXI_ID_WIDTH-1:0]   local_dma_axi_rid;
    wire   [C_M_AXI_DATA_WIDTH-1:0] local_dma_axi_rdata;
    wire   [1:0]                    local_dma_axi_rresp;
    wire                            local_dma_axi_rlast;
    wire                            local_dma_axi_rvalid;
    wire                            local_dma_axi_rready;
  //clock conver for reg write interface  
    wire  [31:0]                    local_reg_axil_awaddr;
    wire                            local_reg_axil_awvalid;
    wire                            local_reg_axil_awready;
    wire  [31:0]                    local_reg_axil_wdata;
    wire   [3:0]                    local_reg_axil_wstrb;
    wire                            local_reg_axil_wvalid;
    wire                            local_reg_axil_wready;
    wire   [1:0]                    local_reg_axil_bresp;
    wire                            local_reg_axil_bvalid;
    wire                            local_reg_axil_bready;
    wire  [31:0]                    local_reg_axil_araddr;
    wire                            local_reg_axil_arvalid;
    wire                            local_reg_axil_arready;
    wire  [31:0]                    local_reg_axil_rdata;
    wire   [1:0]                    local_reg_axil_rresp;
    wire                            local_reg_axil_rvalid;
    wire                            local_reg_axil_rready;
      // output signal
  assign local_reg_wdata = local_mem_wdata_0;
  assign local_reg_wren = local_mem_wren_0;
  assign local_reg_addr = local_mem_addr_0;
  assign local_mem_rdata_0 = local_reg_rdata;
//  assign local_reg_clk = local_mem_clk_0;

  assign local_dma_wdata = local_mem_wdata_1;
  assign local_dma_wren = local_mem_wren_1;
  assign local_dma_addr = local_mem_addr_1;
  assign local_mem_rdata_1 = local_dma_rdata;
//  assign local_dma_clk = local_mem_clk_1;
  wire local_reg_resetn = user_resetn;
  wire local_dma_resetn = user_resetn;
  

  // The sys_rst_n input is active low based on the core configuration
  assign sys_resetn = sys_rst_n;

  // Create a Clock Heartbeat
  always @(posedge user_clk or negedge sys_resetn) begin
    if(!sys_resetn) begin
      user_clk_heartbeat <= #TCQ 26'd0;
    end else begin
      user_clk_heartbeat <= #TCQ user_clk_heartbeat + 1'b1;
    end
  end

  // LEDs for observation
  assign leds[0] = sys_resetn;
  assign leds[1] = user_resetn;
  assign leds[2] = user_lnk_up;
  assign leds[3] = user_clk_heartbeat[25];

axilite_clock_converter_32d32aw axilite_clock_converter_32d32aw_inst (
      .s_axi_aclk(user_clk),                          // input wire s_axi_aclk
      .s_axi_aresetn(user_resetn),                    // input wire s_axi_aresetn
      .s_axi_awaddr(s_axil_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
      .s_axi_awvalid(s_axil_awvalid),                    // input wire s_axi_awvalid
      .s_axi_awready(s_axil_awready),                    // output wire s_axi_awready
      .s_axi_wdata(s_axil_wdata),                        // input wire [31 : 0] s_axi_wdata
      .s_axi_wstrb(s_axil_wstrb),                        // input wire [3 : 0] s_axi_wstrb
      .s_axi_wvalid(s_axil_wvalid),                      // input wire s_axi_wvalid
      .s_axi_wready(s_axil_wready),                      // output wire s_axi_wready
      .s_axi_bresp(s_axil_bresp),                        // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid(s_axil_bvalid),                      // output wire s_axi_bvalid
      .s_axi_bready(s_axil_bready),                      // input wire s_axi_bready
      .s_axi_araddr(s_axil_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
      .s_axi_arvalid(s_axil_arvalid),                    // input wire s_axi_arvalid
      .s_axi_arready(s_axil_arready),                    // output wire s_axi_arready
      .s_axi_rdata(s_axil_rdata),                        // output wire [31 : 0] s_axi_rdata
      .s_axi_rresp(s_axil_rresp),                        // output wire [1 : 0] s_axi_rresp
      .s_axi_rvalid(s_axil_rvalid),                      // output wire s_axi_rvalid
      .s_axi_rready(s_axil_rready),                      // input wire s_axi_rready
      //the master interface
      .m_axi_aclk(local_reg_clk),                         // input wire s_axi_aclk
      .m_axi_aresetn(local_reg_resetn),                    // input wire s_axi_aresetn
      .m_axi_awaddr(local_reg_axil_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
      .m_axi_awvalid(local_reg_axil_awvalid),                    // input wire s_axi_awvalid
      .m_axi_awready(local_reg_axil_awready),                    // output wire s_axi_awready
      .m_axi_wdata(local_reg_axil_wdata),                        // input wire [31 : 0] s_axi_wdata
      .m_axi_wstrb(local_reg_axil_wstrb),                        // input wire [3 : 0] s_axi_wstrb
      .m_axi_wvalid(local_reg_axil_wvalid),                      // input wire s_axi_wvalid
      .m_axi_wready(local_reg_axil_wready),                      // output wire s_axi_wready
      .m_axi_bresp(local_reg_axil_bresp),                        // output wire [1 : 0] s_axi_bresp
      .m_axi_bvalid(local_reg_axil_bvalid),                      // output wire s_axi_bvalid
      .m_axi_bready(local_reg_axil_bready),                      // input wire s_axi_bready
      .m_axi_araddr(local_reg_axil_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
      .m_axi_arvalid(local_reg_axil_arvalid),                    // input wire s_axi_arvalid
      .m_axi_arready(local_reg_axil_arready),                    // output wire s_axi_arready
      .m_axi_rdata(local_reg_axil_rdata),                        // output wire [31 : 0] s_axi_rdata
      .m_axi_rresp(local_reg_axil_rresp),                        // output wire [1 : 0] s_axi_rresp
      .m_axi_rvalid(local_reg_axil_rvalid),                      // output wire s_axi_rvalid
      .m_axi_rready(local_reg_axil_rready)                      // input wire s_axi_rready
);

axi4_lite_amm_bridge axi4_lite_amm_bridge_inst (
      .s_axi_aclk(local_reg_clk),                          // input wire s_axi_aclk
      .s_axi_aresetn(local_reg_resetn),                    // input wire s_axi_aresetn
      .s_axi_awaddr(local_reg_axil_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
      .s_axi_awvalid(local_reg_axil_awvalid),                    // input wire s_axi_awvalid
      .s_axi_awready(local_reg_axil_awready),                    // output wire s_axi_awready
      .s_axi_wdata(local_reg_axil_wdata),                        // input wire [31 : 0] s_axi_wdata
      .s_axi_wstrb(local_reg_axil_wstrb),                        // input wire [3 : 0] s_axi_wstrb
      .s_axi_wvalid(local_reg_axil_wvalid),                      // input wire s_axi_wvalid
      .s_axi_wready(local_reg_axil_wready),                      // output wire s_axi_wready
      .s_axi_bresp(local_reg_axil_bresp),                        // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid(local_reg_axil_bvalid),                      // output wire s_axi_bvalid
      .s_axi_bready(local_reg_axil_bready),                      // input wire s_axi_bready
      .s_axi_araddr(local_reg_axil_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
      .s_axi_arvalid(local_reg_axil_arvalid),                    // input wire s_axi_arvalid
      .s_axi_arready(local_reg_axil_arready),                    // output wire s_axi_arready
      .s_axi_rdata(local_reg_axil_rdata),                        // output wire [31 : 0] s_axi_rdata
      .s_axi_rresp(local_reg_axil_rresp),                        // output wire [1 : 0] s_axi_rresp
      .s_axi_rvalid(local_reg_axil_rvalid),                      // output wire s_axi_rvalid
      .s_axi_rready(local_reg_axil_rready),                      // input wire s_axi_rready
      .avm_write(avm_write_0),                            // output wire avm_write
      .avm_read(avm_read_0),                              // output wire avm_read
      .avm_writedata(avm_writedata_0),                    // output wire [31 : 0] avm_writedata
      .avm_readdata(avm_readdata_0),                      // input wire [31 : 0] avm_readdata
      .avm_readdatavalid(avm_readdatavalid_0),            // input wire avm_readdatavalid
      .avm_waitrequest(avm_waitrequest_0),                // input wire avm_waitrequest
      .avm_address(avm_address_0)                        // output wire [31 : 0] avm_address
);

axi4_lite_amm_slave #(
      //.C_S_AXI_ADDR_WIDTH(32),
      .C_S_AXI_ADDR_WIDTH(32),
      .C_S_AXI_DATA_WIDTH(32), 
      .C_USE_WSTRB(0), 
      .C_HAS_FIXED_WAIT(0),
      .C_HAS_RESPONSE(0),
      .C_FIXED_WRITE_WAIT(1),
      .C_FIXED_READ_WAIT(1),
      .C_HAS_FIXED_READ_LATENCY(0),
      .C_AVM_BURST_WIDTH(1),
      .C_READ_LATENCY(1)
      ) axi4_lite_amm_slave_inst (
        .avm_clk(local_reg_clk),
        .avm_resetn(local_reg_resetn),
        .avm_write(avm_write_0),                            // output wire avm_write
        .avm_read(avm_read_0),                              // output wire avm_read
        .avm_byteenable(avm_byteenable_0),                  // output wire [3 : 0] avm_byteenable
        .avm_writedata(avm_writedata_0),                    // output wire [31 : 0] avm_writedata
        .avm_readdata(avm_readdata_0),                      // input wire [31 : 0] avm_readdata
        .avm_readdatavalid(avm_readdatavalid_0),            // input wire avm_readdatavalid
        .avm_burstcount(avm_burstcount_0),                  // output wire [0 : 0] avm_burstcount
        .avm_beginbursttransfer(avm_beginbursttransfer_0),  // output wire avm_beginbursttransfer
        .avm_resp(avm_resp_0),                              // input wire [1 : 0] avm_resp
        .avm_writeresponsevalid(avm_writeresponsevalid_0),  // input wire avm_writeresponsevalid
        .avm_waitrequest(avm_waitrequest_0),                // input wire avm_waitrequest
        .avm_address({2'b0,avm_address_0[31:2]}),

        //output RAM interface single port
        .local_mem_wdata(local_mem_wdata_0),
        .local_mem_wren(local_mem_wren_0),
        .local_mem_addr(local_mem_addr_0),
        .local_mem_rdata(local_mem_rdata_0),
        .local_mem_clk(local_mem_clk_0)
);

/*
blk_mem_1024D32W blk_mem_1024D32W_lite_isnt(
            .clka(local_mem_clk_0),
            .ena(1'b1),
            .wea(local_mem_wren_0), 
            .addra(local_mem_addr_0[9:0]), 
            .dina(local_mem_wdata_0), 
            .douta(local_mem_rdata_0)
            );
*/









//axi_local_inf axi_local_inf_bypassdma_ins
//--------------------------------------------------------------------
//AXI4 Memory Driver Instance
//--------------------------------------------------------------------
axi_clock_converter_128D32AW axi_clock_converter_128D32AW_inst(//clock converter
        //slave interface
        .s_axi_aclk(user_clk),                          // input wire s_axi_aclk
        .s_axi_aresetn(user_resetn),                    // input wire s_axi_aresetn
        .s_axi_awid(s_axi_awid),                          // input wire [3 : 0] s_axi_awid
        .s_axi_awlen(s_axi_awlen),                        // input wire [4 : 0] s_axi_awlen
        .s_axi_awsize(s_axi_awsize),                      // input wire [2 : 0] s_axi_awsize
        .s_axi_awburst(s_axi_awburst),                    // input wire [1 : 0] s_axi_awburst
        .s_axi_arid(s_axi_arid),                          // input wire [3 : 0] s_axi_arid
        .s_axi_arlen(s_axi_arlen),                        // input wire [4 : 0] s_axi_arlen
        .s_axi_arsize(s_axi_arsize),                      // input wire [2 : 0] s_axi_arsize
        .s_axi_arburst(s_axi_arburst),                    // input wire [1 : 0] s_axi_arburst
        .s_axi_rid(s_axi_rid),                            // output wire [3 : 0] s_axi_rid
        .s_axi_rlast(s_axi_rlast),                        // output wire s_axi_rlast
        .s_axi_wlast(s_axi_wlast),                        // input wire s_axi_wlast
        .s_axi_bid(s_axi_bid),                            // output wire [3 : 0] s_axi_bid
        .s_axi_awaddr(s_axi_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
        .s_axi_awvalid(s_axi_awvalid),                    // input wire s_axi_awvalid
        .s_axi_awready(s_axi_awready),                    // output wire s_axi_awready
        .s_axi_wdata(s_axi_wdata),                        // input wire [31 : 0] s_axi_wdata
        .s_axi_wstrb(s_axi_wstrb),                        // input wire [3 : 0] s_axi_wstrb
        .s_axi_wvalid(s_axi_wvalid),                      // input wire s_axi_wvalid
        .s_axi_wready(s_axi_wready),                      // output wire s_axi_wready
        .s_axi_bresp(s_axi_bresp),                        // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(s_axi_bvalid),                      // output wire s_axi_bvalid
        .s_axi_bready(s_axi_bready),                      // input wire s_axi_bready
        .s_axi_araddr(s_axi_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
        .s_axi_arvalid(s_axi_arvalid),                    // input wire s_axi_arvalid
        .s_axi_arready(s_axi_arready),                    // output wire s_axi_arready
        .s_axi_rdata(s_axi_rdata),                        // output wire [31 : 0] s_axi_rdata
        .s_axi_rresp(s_axi_rresp),                        // output wire [1 : 0] s_axi_rresp
        .s_axi_rvalid(s_axi_rvalid),                      // output wire s_axi_rvalid
        .s_axi_rready(s_axi_rready),                      // input wire s_axi_rready 
        
        //master interface
        .m_axi_aclk(local_dma_clk),                          // input wire s_axi_aclk
        .m_axi_aresetn(local_dma_resetn),                    // input wire s_axi_aresetn
        .m_axi_awid(local_dma_axi_awid),                          // input wire [3 : 0] s_axi_awid
        .m_axi_awlen(local_dma_axi_awlen),                        // input wire [4 : 0] s_axi_awlen
        .m_axi_awsize(local_dma_axi_awsize),                      // input wire [2 : 0] s_axi_awsize
        .m_axi_awburst(local_dma_axi_awburst),                    // input wire [1 : 0] s_axi_awburst
        .m_axi_arid(local_dma_axi_arid),                          // input wire [3 : 0] s_axi_arid
        .m_axi_arlen(local_dma_axi_arlen),                        // input wire [4 : 0] s_axi_arlen
        .m_axi_arsize(local_dma_axi_arsize),                      // input wire [2 : 0] s_axi_arsize
        .m_axi_arburst(local_dma_axi_arburst),                    // input wire [1 : 0] s_axi_arburst
        .m_axi_rid(local_dma_axi_rid),                            // output wire [3 : 0] s_axi_rid
        .m_axi_rlast(local_dma_axi_rlast),                        // output wire s_axi_rlast
        .m_axi_wlast(local_dma_axi_wlast),                        // input wire s_axi_wlast
        .m_axi_bid(local_dma_axi_bid),                            // output wire [3 : 0] s_axi_bid
        .m_axi_awaddr(local_dma_axi_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
        .m_axi_awvalid(local_dma_axi_awvalid),                    // input wire s_axi_awvalid
        .m_axi_awready(local_dma_axi_awready),                    // output wire s_axi_awready
        .m_axi_wdata(local_dma_axi_wdata),                        // input wire [31 : 0] s_axi_wdata
        .m_axi_wstrb(local_dma_axi_wstrb),                        // input wire [3 : 0] s_axi_wstrb
        .m_axi_wvalid(local_dma_axi_wvalid),                      // input wire s_axi_wvalid
        .m_axi_wready(local_dma_axi_wready),                      // output wire s_axi_wready
        .m_axi_bresp(local_dma_axi_bresp),                        // output wire [1 : 0] s_axi_bresp
        .m_axi_bvalid(local_dma_axi_bvalid),                      // output wire s_axi_bvalid
        .m_axi_bready(local_dma_axi_bready),                      // input wire s_axi_bready
        .m_axi_araddr(local_dma_axi_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
        .m_axi_arvalid(local_dma_axi_arvalid),                    // input wire s_axi_arvalid
        .m_axi_arready(local_dma_axi_arready),                    // output wire s_axi_arready
        .m_axi_rdata(local_dma_axi_rdata),                        // output wire [31 : 0] s_axi_rdata
        .m_axi_rresp(local_dma_axi_rresp),                        // output wire [1 : 0] s_axi_rresp
        .m_axi_rvalid(local_dma_axi_rvalid),                      // output wire s_axi_rvalid
        .m_axi_rready(local_dma_axi_rready)                       // input wire s_axi_rready
        );


axi4_amm_bridge axi4_amm_bridge_dma_inst (
        .s_axi_aclk(local_dma_clk),                          // input wire s_axi_aclk
        .s_axi_aresetn(local_dma_resetn),                    // input wire s_axi_aresetn
        .s_axi_awid(local_dma_axi_awid),                          // input wire [3 : 0] s_axi_awid
        .s_axi_awlen(local_dma_axi_awlen),                        // input wire [4 : 0] s_axi_awlen
        .s_axi_awsize(local_dma_axi_awsize),                      // input wire [2 : 0] s_axi_awsize
        .s_axi_awburst(local_dma_axi_awburst),                    // input wire [1 : 0] s_axi_awburst
        .s_axi_arid(local_dma_axi_arid),                          // input wire [3 : 0] s_axi_arid
        .s_axi_arlen(local_dma_axi_arlen),                        // input wire [4 : 0] s_axi_arlen
        .s_axi_arsize(local_dma_axi_arsize),                      // input wire [2 : 0] s_axi_arsize
        .s_axi_arburst(local_dma_axi_arburst),                    // input wire [1 : 0] s_axi_arburst
        .s_axi_rid(local_dma_axi_rid),                            // output wire [3 : 0] s_axi_rid
        .s_axi_rlast(local_dma_axi_rlast),                        // output wire s_axi_rlast
        .s_axi_wlast(local_dma_axi_wlast),                        // input wire s_axi_wlast
        .s_axi_bid(local_dma_axi_bid),                            // output wire [3 : 0] s_axi_bid
        .s_axi_awaddr(local_dma_axi_awaddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_awaddr
        .s_axi_awvalid(local_dma_axi_awvalid),                    // input wire s_axi_awvalid
        .s_axi_awready(local_dma_axi_awready),                    // output wire s_axi_awready
        .s_axi_wdata(local_dma_axi_wdata),                        // input wire [31 : 0] s_axi_wdata
        .s_axi_wstrb(local_dma_axi_wstrb),                        // input wire [3 : 0] s_axi_wstrb
        .s_axi_wvalid(local_dma_axi_wvalid),                      // input wire s_axi_wvalid
        .s_axi_wready(local_dma_axi_wready),                      // output wire s_axi_wready
        .s_axi_bresp(local_dma_axi_bresp),                        // output wire [1 : 0] s_axi_bresp
        .s_axi_bvalid(local_dma_axi_bvalid),                      // output wire s_axi_bvalid
        .s_axi_bready(local_dma_axi_bready),                      // input wire s_axi_bready
        .s_axi_araddr(local_dma_axi_araddr[32 -1 : 0]),                      // input wire [31 : 0] s_axi_araddr
        .s_axi_arvalid(local_dma_axi_arvalid),                    // input wire s_axi_arvalid
        .s_axi_arready(local_dma_axi_arready),                    // output wire s_axi_arready
        .s_axi_rdata(local_dma_axi_rdata),                        // output wire [31 : 0] s_axi_rdata
        .s_axi_rresp(local_dma_axi_rresp),                        // output wire [1 : 0] s_axi_rresp
        .s_axi_rvalid(local_dma_axi_rvalid),                      // output wire s_axi_rvalid
        .s_axi_rready(local_dma_axi_rready),                      // input wire s_axi_rready

        .avm_write(avm_write_1),                            // output wire avm_write
        .avm_read(avm_read_1),                              // output wire avm_read
        .avm_writedata(avm_writedata_1),                    // output wire [31 : 0] avm_writedata
        .avm_readdata(avm_readdata_1),                      // input wire [31 : 0] avm_readdata
        .avm_readdatavalid(avm_readdatavalid_1),            // input wire avm_readdatavalid
        .avm_beginbursttransfer(avm_beginbursttransfer_1),
        .avm_burstcount(avm_burstcount_1),                  // output wire [0 : 0] avm_burstcount
        .avm_waitrequest(avm_waitrequest_1),                // input wire avm_waitrequest
        .avm_address(avm_address_1)                        // output wire [31 : 0] avm_address
);

axi4_amm_slave #(
        //.C_S_AXI_ADDR_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(32),
        .C_S_AXI_DATA_WIDTH(128), 
        .C_USE_WSTRB(1), 
        .C_HAS_FIXED_WAIT(0),
        .C_HAS_RESPONSE(0),
        .C_FIXED_WRITE_WAIT(1),
        .C_FIXED_READ_WAIT(1),
        .C_HAS_FIXED_READ_LATENCY(0),
        .C_AVM_BURST_WIDTH(9),
        .C_READ_LATENCY(1)
        ) axi4_amm_slave_dma_isnt (
          .avm_clk(local_dma_clk),
          .avm_resetn(local_dma_resetn),
          .avm_write(avm_write_1),                            // output wire avm_write
          .avm_read(avm_read_1),                              // output wire avm_read
          //.avm_byteenable(avm_byteenable_1),                  // output wire [3 : 0] avm_byteenable
          .avm_writedata(avm_writedata_1),                    // output wire [31 : 0] avm_writedata
          .avm_readdata(avm_readdata_1),                      // input wire [31 : 0] avm_readdata
          .avm_readdatavalid(avm_readdatavalid_1),            // input wire avm_readdatavalid
          .avm_burstcount(avm_burstcount_1),                  // output wire [0 : 0] avm_burstcount
          .avm_beginbursttransfer(avm_beginbursttransfer_1),  // output wire avm_beginbursttransfer
          //.avm_resp(avm_resp_1),                              // input wire [1 : 0] avm_resp
          //.avm_writeresponsevalid(avm_writeresponsevalid_1),  // input wire avm_writeresponsevalid
          .avm_waitrequest(avm_waitrequest_1),                // input wire avm_waitrequest
          .avm_address({4'b0,avm_address_1[31:4]}),
          
          //output RAM interface single port
          .local_mem_wdata(local_mem_wdata_1),
          .local_mem_wren(local_mem_wren_1),
          .local_mem_addr(local_mem_addr_1),
          .local_mem_rdata(local_mem_rdata_1),
          .local_mem_clk(local_mem_clk_1)
);

/*
blk_mem_131072D128W blk_mem_131072D128W_xdma_isnt(
            .clka(local_mem_clk_1), 
            .wea(local_mem_wren_1), 
            .addra(local_mem_addr_1[16:0]), 
            .dina(local_mem_wdata_1), 
            .douta(local_mem_rdata_1)
            );
*/
/*
axi4_amm_bridge axi4_amm_bridge_bypassdma_inst (
        .s_axi_aclk(user_clk),                          // input wire s_axi_aclk
        .s_axi_aresetn(user_resetn),                    // input wire s_axi_aresetn

        .s_axi_awid(s_axib_awid), 
        .s_axi_awaddr({13'd0, s_axib_awaddr[18:0]}),
        .s_axi_awlen(s_axib_awlen),
        .s_axi_awsize(s_axib_awsize),
        .s_axi_awburst(s_axib_awburst),
        // .s_axi_awlock(s_axib_awlock),--
        // .s_axi_awcache(s_axib_awcache),--
        // .s_axi_awprot(s_axib_awprot),--
        .s_axi_awvalid(s_axib_awvalid),
        .s_axi_awready(s_axib_awready),
        .s_axi_wdata(s_axib_wdata),
        .s_axi_wstrb(s_axib_wstrb),
        .s_axi_wlast(s_axib_wlast),
        .s_axi_wvalid(s_axib_wvalid),
        .s_axi_wready(s_axib_wready),
        .s_axi_bid(s_axib_bid),
        .s_axi_bresp(s_axib_bresp),
        .s_axi_bvalid(s_axib_bvalid),
        .s_axi_bready(s_axib_bready),
        .s_axi_arid(s_axib_arid),
        .s_axi_araddr({13'd0, s_axib_araddr[18:0]}),
        .s_axi_arlen(s_axib_arlen),
        .s_axi_arsize(s_axib_arsize),
        .s_axi_arburst(s_axib_arburst),
        // .s_axi_arlock(s_axib_arlock),
        // .s_axi_arcache(s_axib_arcache),
        // .s_axi_arprot(s_axib_arprot),
        .s_axi_arvalid(s_axib_arvalid),
        .s_axi_arready(s_axib_arready),
        .s_axi_rid(s_axib_rid),
        .s_axi_rdata(s_axib_rdata),
        .s_axi_rresp(s_axib_rresp),
        .s_axi_rlast(s_axib_rlast),
        .s_axi_rvalid(s_axib_rvalid),
        .s_axi_rready(s_axib_rready),
        
        .avm_write(avm_write_2),                            // output wire avm_write
        .avm_read(avm_read_2),                              // output wire avm_read
        .avm_writedata(avm_writedata_2),                    // output wire [31 : 0] avm_writedata
        .avm_readdata(avm_readdata_2),                      // input wire [31 : 0] avm_readdata
        .avm_readdatavalid(avm_readdatavalid_2),            // input wire avm_readdatavalid
        .avm_burstcount(avm_burstcount_2),                  // output wire [0 : 0] avm_burstcount
        .avm_waitrequest(avm_waitrequest_2),                // input wire avm_waitrequest
        .avm_address(avm_address_2)                        // output wire [31 : 0] avm_address
);

axi4_amm_slave #(
        //.C_S_AXI_ADDR_WIDTH(32),
        .C_S_AXI_ADDR_WIDTH(32),
        .C_S_AXI_DATA_WIDTH(128), 
        .C_USE_WSTRB(1), 
        .C_HAS_FIXED_WAIT(0),
        .C_HAS_RESPONSE(0),
        .C_FIXED_WRITE_WAIT(1),
        .C_FIXED_READ_WAIT(1),
        .C_HAS_FIXED_READ_LATENCY(0),
        .C_AVM_BURST_WIDTH(9),
        .C_READ_LATENCY(1)
        ) axi4_amm_slave_bypassdma_isnt (
          .avm_clk(user_clk),
          .avm_resetn(user_resetn),
          .avm_write(avm_write_2),                            // output wire avm_write
          .avm_read(avm_read_2),                              // output wire avm_read
          .avm_byteenable(avm_byteenable_2),                  // output wire [3 : 0] avm_byteenable
          .avm_writedata(avm_writedata_2),                    // output wire [31 : 0] avm_writedata
          .avm_readdata(avm_readdata_2),                      // input wire [31 : 0] avm_readdata
          .avm_readdatavalid(avm_readdatavalid_2),            // input wire avm_readdatavalid
          .avm_burstcount(avm_burstcount_2),                  // output wire [0 : 0] avm_burstcount
          .avm_beginbursttransfer(avm_beginbursttransfer_2),  // output wire avm_beginbursttransfer
          .avm_resp(avm_resp_2),                              // input wire [1 : 0] avm_resp
          .avm_writeresponsevalid(avm_writeresponsevalid_2),  // input wire avm_writeresponsevalid
          .avm_waitrequest(avm_waitrequest_2),                // input wire avm_waitrequest
          .avm_address({4'b0,avm_address_2[31:4]}),
          
          //output RAM interface single port
          .local_mem_wdata(local_mem_wdata_2),
          .local_mem_wren(local_mem_wren_2),
          .local_mem_addr(local_mem_addr_2),
          .local_mem_rdata(local_mem_rdata_2),
          .local_mem_clk(local_mem_clk_2)
);

blk_mem_1024D128W blk_mem_1024D128W_bypassdma_isnt(
            .clka(local_mem_clk_2), 
            .wea(local_mem_wren_2), 
            .addra(local_mem_addr_2[9:0]), 
            .dina(local_mem_wdata_2), 
            .douta(local_mem_rdata_2)
            );
*/
endmodule

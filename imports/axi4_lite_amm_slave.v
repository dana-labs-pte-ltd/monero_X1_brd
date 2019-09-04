

//////////////////////////////////////////////////////////////////-
// (c) Copyright 1984 - 2016 Xilinx, Inc. All rights reserved.
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
//////////////////////////////////////////////////////////////////-
// ************************************************************************
//
//////////////////////////////////////////////////////////////////////////////-
// Filename:        amm_slave_0.v
// Version:         v1.0
// Description:     This is the amm slave example model.
//////////////////////////////////////////////////////////////////////////////-
// Author:      Karthee
//
// History:
//
//  Karthee      07/10/16      // First version
// ~~~~~~
`timescale 1ns/1ps
(* DowngradeIPIdentifiedWarnings="yes" *)

module axi4_lite_amm_slave #(
parameter                              C_HAS_FIXED_WAIT = 0,//1,
parameter                              C_HAS_RESPONSE = 1,//1,
parameter                              C_FIXED_WRITE_WAIT = 5,
parameter                              C_FIXED_READ_WAIT = 1,
parameter                              C_HAS_FIXED_READ_LATENCY = 0,//1,
parameter                              C_READ_LATENCY = 3,
parameter                              C_S_AXI_DATA_WIDTH   = 32,
parameter                              C_S_AXI_ADDR_WIDTH   = 10,
parameter                              C_USE_WSTRB          = 0,
parameter                              C_AVM_BURST_WIDTH    = 1,
parameter                              C_PROTOCOL           = 0,
parameter                              C_FAMILY            = "virtex7"
)
(
    input                                   avm_clk,
    input                                   avm_resetn,
    input [C_S_AXI_ADDR_WIDTH-1:0]          avm_address,  
    input                                   avm_write, 
    input                                   avm_read, 
    input [((C_S_AXI_DATA_WIDTH / 8)-1):0]  avm_byteenable, 
    input [(C_S_AXI_DATA_WIDTH - 1):0]      avm_writedata,    
    (*mark_debug = "true"*)output reg [(C_S_AXI_DATA_WIDTH - 1):0] avm_readdata, 
    output reg [1:0]                        avm_resp,
    (*mark_debug = "true"*)output reg                              avm_readdatavalid,
    input                                   avm_beginbursttransfer,
    input [C_AVM_BURST_WIDTH-1:0]           avm_burstcount,
    output reg                              avm_writeresponsevalid,
    output reg                              avm_waitrequest,
    
    //mem read and write
    //output RAM interface single port
    output reg [C_S_AXI_DATA_WIDTH-1:0]     local_mem_wdata,
    output reg 						                  local_mem_wren,
    output reg  [C_S_AXI_ADDR_WIDTH-1:0]    local_mem_addr,
    input  wire [C_S_AXI_DATA_WIDTH-1:0]	  local_mem_rdata,
    output wire						                  local_mem_clk
);

    reg [C_AVM_BURST_WIDTH-1:0]   arlen_i,awlen_i;
    //reg [(C_S_AXI_DATA_WIDTH - 1):0] avm_mem [31:0];
    (*mark_debug = "true"*)reg                           avm_write_i;
    (*mark_debug = "true"*)reg                           avm_read_i;
    reg                           avm_read_i0;
    reg                           avm_read_i1;
    reg                           avm_read_i2;
    reg                           avm_read_i3;
    reg                           wr_done;
    reg                           wait_done;
    reg                           start;
    reg                           rd_lat_done;
    reg                           avm_write_i1;

    reg [9:0]                     rd_lat_cnt;
    reg [7:0]                     rd_wait_cnt;
    reg [7:0]                     wr_wait_cnt;
    (*mark_debug = "true"*)reg [C_S_AXI_ADDR_WIDTH-1:0]  avm_address_i;
    (*mark_debug = "true"*)reg [(C_S_AXI_DATA_WIDTH - 1):0] avm_writedata_i;
    
    assign local_mem_clk = avm_clk;
   
   localparam IDLE            = 2'h0;
   localparam WRITE_AD_DATA   = 2'h1;
   localparam READ_ADDRESS    = 2'h2;
   localparam READ_DATA       = 2'h3;
   
   localparam C_FIXED_READ_WAIT_1    = (C_HAS_FIXED_WAIT) ? C_FIXED_READ_WAIT: 0;
   
   reg [1:0]  current_state   = IDLE;
   reg [1:0]  next_state      = IDLE;

//memory control signals
//read delay
  always @(posedge avm_clk) begin
     if(avm_resetn == 1'b0) begin
        avm_read_i0 <= 1'b0;
        avm_read_i1 <= 1'b0;
        avm_read_i2 <= 1'b0;
        avm_read_i3 <= 1'b0;
     end else begin
        avm_read_i0 <= avm_read_i1;
        avm_read_i1 <= avm_read_i2;
        avm_read_i2 <= avm_read_i3;
        avm_read_i3 <= avm_read_i;
     end
   end

//for data read and write
  always @(posedge avm_clk) begin
     if(avm_resetn == 1'b0) begin
          avm_waitrequest <= 1'b1;
          avm_readdata <= 0;
          avm_readdatavalid <= 1'b0;       
     end else begin
         avm_waitrequest <= 1'b0;
         avm_readdata <= local_mem_rdata;
         if(avm_read_i0) begin           
           avm_readdatavalid <= 1'b1;       
         end
         else begin
           avm_readdatavalid <= 1'b0;       
         end
     end
   end
   
  //generata the ram write signal
  //for data read and write
  always @(posedge avm_clk) begin
     if(avm_resetn == 1'b0) begin
        local_mem_wdata <= 0;
        local_mem_wren <= 1'b0;  
        local_mem_addr <= 0;
     end else begin
        local_mem_wdata <= avm_writedata_i;
        local_mem_wren <= avm_write_i;
        local_mem_addr <= avm_address_i;
     end
   end


  always @(posedge avm_clk) begin
    if(avm_resetn == 1'b0) begin
      rd_lat_done = 1'b0;              
    end else begin
      if(avm_write_i) begin 
        rd_lat_done = 1'b0;              
      end
      else if(avm_read_i) begin
        rd_lat_done = 1'b1;     
      end
      else begin
        rd_lat_done = 1'b0;              
      end
     end   
   end

  always @(posedge avm_clk) begin
    if(avm_resetn == 1'b0) begin
      avm_resp <= 2'b10;
      avm_writeresponsevalid <= 1'b0;
      avm_write_i1 <= 1'b0;
    end else begin
      avm_resp <= 2'b00;
      avm_write_i1 <= avm_write_i;
      avm_writeresponsevalid <= avm_write_i1;      
    end
  end

  always @(posedge avm_clk) begin
    avm_read_i <=    avm_read;
  end

   always @(posedge avm_clk) begin
       avm_write_i <= avm_write;
       avm_writedata_i <= avm_writedata;
       avm_address_i <= avm_address;
       wait_done <= 1'b1;
   end

  always @(*) begin
    // Setup the default values
    case (current_state)
      // If RST is asserted reset the machine
      IDLE: begin
        start <= 1'b0;
        if(avm_read == 1'b1) begin
          next_state <= READ_ADDRESS;                       
        end else if(avm_write == 1'b1) begin
          next_state <= WRITE_AD_DATA;                       
        end else begin
          next_state <= IDLE;
        end
      end
      WRITE_AD_DATA: begin
        if(wait_done == 1'b1)     
          next_state <= IDLE;
        else
          next_state <= WRITE_AD_DATA;                      
      end
      READ_ADDRESS: begin
        if(wait_done == 1'b1)     
          next_state <= READ_DATA;
        else
          next_state <= READ_ADDRESS; 
      end
      READ_DATA: begin
        if(rd_lat_done == 1'b1)     
          next_state <= IDLE;
        else
          next_state <= READ_DATA; 
     end
    default: begin
      next_state <= IDLE;           
    end
  endcase
 end

 // This block assigns the next state, reset is synchronous.
  always @(posedge avm_clk) begin
    if(avm_resetn == 1'b0) begin
      current_state <= IDLE;
    end else begin
      current_state <= next_state;
    end
  end

endmodule


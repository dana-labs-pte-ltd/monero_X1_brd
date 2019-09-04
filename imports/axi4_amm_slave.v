

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

module axi4_amm_slave #(
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
//    input [((C_S_AXI_DATA_WIDTH / 8)-1):0]  avm_byteenable, 
    input [(C_S_AXI_DATA_WIDTH - 1):0]      avm_writedata,    
    output reg [(C_S_AXI_DATA_WIDTH - 1):0] avm_readdata, 
//    output reg [1:0]                        avm_resp,
    output reg                              avm_readdatavalid,
    input                                   avm_beginbursttransfer,
    input [C_AVM_BURST_WIDTH-1:0]           avm_burstcount,
//    output reg                              avm_writeresponsevalid,
    output reg                              avm_waitrequest,
    
    //mem read and write
    	//output RAM interface single port
    (*mark_debug = "true"*)output reg [C_S_AXI_DATA_WIDTH-1:0]    local_mem_wdata,
    (*mark_debug = "true"*)output reg                             local_mem_wren,
    (*mark_debug = "true"*)output reg  [C_S_AXI_ADDR_WIDTH-1:0]   local_mem_addr,
    (*mark_debug = "true"*)input  wire [C_S_AXI_DATA_WIDTH-1:0]	  local_mem_rdata,
    output wire	                                                  local_mem_clk
);

    (*mark_debug = "true"*)reg [C_AVM_BURST_WIDTH-1:0]     arlen_i;
    //reg [(C_S_AXI_DATA_WIDTH - 1):0]            avm_mem [31:0];
    (*mark_debug = "true"*)reg                             avm_write_i;
    (*mark_debug = "true"*)reg                             avm_read_i;
    (*mark_debug = "true"*)reg                             avm_read_i0;
    (*mark_debug = "true"*)reg                             avm_read_i1;
    (*mark_debug = "true"*)reg                             avm_read_i2;
    (*mark_debug = "true"*)reg                             avm_read_i3;

    (*mark_debug = "true"*)reg [C_S_AXI_ADDR_WIDTH-1:0]    avm_address_i;
    reg [(C_S_AXI_DATA_WIDTH - 1):0] avm_writedata_i;
    
    assign local_mem_clk = avm_clk;

    //address
    always @(posedge avm_clk) begin
        if(avm_resetn == 1'b0) begin
               avm_address_i <= avm_address;    
        end else begin
            if(avm_beginbursttransfer) begin
               avm_address_i <= avm_address;
            end else if(avm_write_i) begin 
               avm_address_i <= avm_address_i + 1'b1;
            end else if(avm_read_i) begin 
               avm_address_i <= avm_address_i + 1'b1;
            end
        end
    end

   always @(posedge avm_clk) begin
     if(avm_resetn == 1'b0) begin
        arlen_i <= 0;
        avm_read_i <= 0;
      end else begin
        if(avm_beginbursttransfer && avm_read) begin 
          avm_read_i <= 1'b1;
          arlen_i <= avm_burstcount;
        end else if(arlen_i > 1 && avm_read_i) begin 
          avm_read_i <= 1'b1;
          arlen_i <= arlen_i - 1;
        end else if(arlen_i == 1) begin
          avm_read_i <= 0;
        end
     end
   end

//read delay
    always @(posedge avm_clk)
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

    //for data read and write
    always @(posedge avm_clk or negedge avm_resetn)
    if(avm_resetn == 1'b0) begin
        avm_waitrequest <= 1'b1;
        avm_readdata <= 0;
        avm_readdatavalid <= 1'b0;       
    end else begin
        avm_waitrequest <= 1'b0;
        avm_readdata <= local_mem_rdata;
        if(avm_read_i0) begin
           avm_readdatavalid <= 1'b1;
        end else begin
           avm_readdatavalid <= 1'b0;       
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
    avm_write_i <= avm_write;
    avm_writedata_i <= avm_writedata;
  end

endmodule


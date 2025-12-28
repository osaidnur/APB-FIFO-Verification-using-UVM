//------------------------------------------------------------------------------
// APB FIFO Top Testbench
//------------------------------------------------------------------------------
`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

// Include interface first
`include "components/apb_fifo_interface.sv"

// // Include design
// `include "design/fifo.sv"

// Include UVM package
`include "components/apb_fifo_pkg.sv"
import apb_fifo_pkg::*;

module top_tb;
  
  //--------------------------------------------------------------------------
  // Clock and Reset
  //--------------------------------------------------------------------------
  logic PCLK;
  logic PRESETn;
  
  //--------------------------------------------------------------------------
  // Clock Generation - 100MHz
  //--------------------------------------------------------------------------
  initial begin
    PCLK = 0;
    forever #5 PCLK = ~PCLK;  // 10ns period = 100MHz
  end
  
  //--------------------------------------------------------------------------
  // Reset Generation
  //--------------------------------------------------------------------------
  initial begin
    PRESETn = 0;
    repeat(5) @(posedge PCLK);
    PRESETn = 1;
    `uvm_info("TOP", "Reset released", UVM_LOW)
  end
  
  //--------------------------------------------------------------------------
  // Interface Instance
  //--------------------------------------------------------------------------
  apb_fifo_if apb_if(PCLK, PRESETn);
  
  //--------------------------------------------------------------------------
  // DUT Instance
  //--------------------------------------------------------------------------
  apb_sync_fifo #(
    .WIDTH(FIFO_WIDTH),
    .DEPTH(FIFO_DEPTH)
  ) dut (
    .PCLK    (PCLK),
    .PRESETn (PRESETn),
    .PSEL    (apb_if.PSEL),
    .PENABLE (apb_if.PENABLE),
    .PWRITE  (apb_if.PWRITE),
    .PADDR   (apb_if.PADDR),
    .PWDATA  (apb_if.PWDATA),
    .PRDATA  (apb_if.PRDATA),
    .PREADY  (apb_if.PREADY),
    .PSLVERR (apb_if.PSLVERR)
  );
  
  //--------------------------------------------------------------------------
  // Interface Configuration
  //--------------------------------------------------------------------------
  initial begin
    // Set virtual interface in config_db
    uvm_config_db#(virtual apb_fifo_if)::set(null, "*.env.agent.driver", "vif", apb_if);
    uvm_config_db#(virtual apb_fifo_if)::set(null, "*.env.agent.monitor", "vif", apb_if);
    
    // Set verbosity
    //uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
  end
  
  //--------------------------------------------------------------------------
  // Start Test
  //--------------------------------------------------------------------------
  initial begin
    run_test();
  end
  
  //--------------------------------------------------------------------------
  // Simulation Timeout
  //--------------------------------------------------------------------------
  initial begin
    #1000000;  // 1ms timeout
    `uvm_fatal("TOP", "Simulation timeout!")
  end
  
  //--------------------------------------------------------------------------
  // Waveform Dump (VCS)
  //--------------------------------------------------------------------------
  `ifdef VCS
  initial begin
    $fsdbDumpfile("apb_fifo.fsdb");
    $fsdbDumpvars(0, top_tb);
  end
  `endif
  
  //--------------------------------------------------------------------------
  // Waveform Dump (Questa/ModelSim)
  //--------------------------------------------------------------------------
  `ifdef QUESTA
  initial begin
    $wlfdumpvars(0, top_tb);
  end
  `endif
  
  //--------------------------------------------------------------------------
  // Waveform Dump (Generic VCD)
  //--------------------------------------------------------------------------
  `ifdef DUMP_VCD
  initial begin
    $dumpfile("apb_fifo.vcd");
    $dumpvars(0, top_tb);
  end
  `endif

endmodule : top_tb

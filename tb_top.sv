import uvm_pkg::*;
`include "uvm_macros.svh"

// Include UVM package
`include "apb_fifo_pkg.sv"
import apb_fifo_pkg::*;

module top_tb;
  
    // Clock
    logic PCLK;
    
    // Clock Generation - 100MHz
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end
    
    // Interface Instance
    apb_fifo_if apb_if(PCLK);

    // DUT Instance
    apb_sync_fifo #(
        .WIDTH(FIFO_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) dut (
        .PCLK (PCLK),
        .PRESETn (apb_if.PRESETn),
        .PSEL (apb_if.PSEL),
        .PENABLE (apb_if.PENABLE),
        .PWRITE (apb_if.PWRITE),
        .PADDR (apb_if.PADDR),
        .PWDATA (apb_if.PWDATA),
        .PRDATA (apb_if.PRDATA),
        .PREADY (apb_if.PREADY),
        .PSLVERR (apb_if.PSLVERR)
    );
    
    // Interface Configuration
    initial begin
        // Set virtual interface in config_db
        uvm_config_db#(virtual apb_fifo_if)::set(null, "*.env.agent.driver", "vif", apb_if);
        uvm_config_db#(virtual apb_fifo_if)::set(null, "*.env.agent.monitor", "vif", apb_if);
    end
    
    //--------------------------------------------------------------------------
    // Tests Map:
    // - reset_test
    // - basic_operation_test
    // - fifo_clear_test
    // - fifo_enable_test
    // - overflow_test
    // - underflow_test
    // - threshold_test
    // - random_test
    // - stress_test
    //--------------------------------------------------------------------------
    initial begin
        run_test("basic_operation_test");
    end
    
    // Simulation Timeout
    initial begin
        #1000000;  // 1ms timeout
        `uvm_fatal("TOP", "Simulation timeout!")
    end
    
    // Waveform Dump
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, top_tb);
    end

endmodule : top_tb
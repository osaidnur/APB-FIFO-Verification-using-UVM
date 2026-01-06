//===============================================================================
// Interface Definition
//===============================================================================
interface apb_fifo_if(input logic PCLK);

    // Reset signal
    input logic PRESETn;

    // input to the DUT
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [7:0] PADDR;
    logic [31:0] PWDATA;

    // output from the DUT
    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    // Driver clocking block
    clocking drv_cb @(posedge PCLK);
        default input #1ns output #1ns;
        output PRESETn;
        output PSEL;
        output PENABLE;
        output PWRITE;
        output PADDR;
        output PWDATA;
        input PRDATA;
        input PREADY;
        input PSLVERR;
    endclocking

    // Monitor clocking block
    clocking mon_cb @(posedge PCLK);
        default input #1ns output #1ns;
        input PRESETn;
        input PSEL;
        input PENABLE;
        input PWRITE;
        input PADDR;
        input PWDATA;
        input PRDATA;
        input PREADY;
        input PSLVERR;
    endclocking

    // Modports
    modport DRV (clocking drv_cb, input PCLK, input PRESETn);
    modport MON (clocking mon_cb, input PCLK, input PRESETn);

endinterface : apb_fifo_if

// #########################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #########################################################################################

//===============================================================================
// Package Definition
//===============================================================================
package apb_fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // FIFO Parameters
    parameter int FIFO_WIDTH = 8;
    parameter int FIFO_DEPTH = 16;

    // APB Operation Types
    parameter bit APB_READ = 1'b0;
    parameter bit APB_WRITE = 1'b1;

    // Register Offsets
    parameter bit [7:0] CTRL_OFFSET = 8'h00; // RW
    parameter bit [7:0] THRESH_OFFSET = 8'h04; // RW
    parameter bit [7:0] STATUS_OFFSET = 8'h08; // R
    parameter bit [7:0] DATA_OFFSET = 8'h0C; // RW

    // Include UVM Components
    `include "apb_components.sv"
    `include "apb_sequences.sv"
    `include "apb_tests.sv"

endpackage : apb_fifo_pkg


// #########################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #########################################################################################

//===============================================================================
// Top Module
//===============================================================================
module top_tb;
  
    import uvm_pkg::*;
    import apb_fifo_pkg::*;
    `include "uvm_macros.svh"
    
    // Clock and Reset
    logic PCLK;
    // logic PRESETn;
    
    // Clock Generation - 100MHz
    initial begin
        PCLK = 0;
        forever #5 PCLK = ~PCLK;
    end
    
    // // Reset Generation
    // initial begin
    //     PRESETn = 0;
    //     `uvm_info("TOP", "***** Asserting reset *****", UVM_LOW)
    //     repeat(5) @(posedge PCLK);
    //     PRESETn = 1;
    //     `uvm_info("TOP", "***** Reset released *****", UVM_LOW)
    // end
    
    
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
    // - overflow_test
    // - underflow_test
    // - threshold_test
    // - register_test
    // - random_test
    // - full_coverage_test
    // - stress_test
    // - back_to_back_test
    // - clear_test
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

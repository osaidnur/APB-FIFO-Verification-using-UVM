package apb_fifo_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    //--------------------------------------------------------------------------
    // FIFO Parameters
    //--------------------------------------------------------------------------
    parameter int FIFO_WIDTH = 8;
    parameter int FIFO_DEPTH = 16;

    //--------------------------------------------------------------------------
    // APB Operation Types
    //--------------------------------------------------------------------------
    parameter bit APB_READ = 1'b0;
    parameter bit APB_WRITE = 1'b1;

    //--------------------------------------------------------------------------
    // Register Offsets
    //--------------------------------------------------------------------------
    parameter bit [7:0] CTRL_OFFSET = 8'h00; // RW
    parameter bit [7:0] THRESH_OFFSET = 8'h04; // RW
    parameter bit [7:0] STATUS_OFFSET = 8'h08; // R
    parameter bit [7:0] DATA_OFFSET = 8'h0C; // RW

    //--------------------------------------------------------------------------
    // Include UVM Components
    //--------------------------------------------------------------------------
    `include "apb_fifo_ref_model.sv"
    `include "apb_sequence_item.sv"
    `include "apb_sequencer.sv"
    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"
    `include "apb_fifo_scoreboard.sv"
    `include "apb_fifo_coverage.sv"
    `include "apb_fifo_env.sv"

    //--------------------------------------------------------------------------
    // Include Sequences
    //--------------------------------------------------------------------------
    `include "../sequences/apb_base_sequence.sv"
    `include "../sequences/reset_sequence.sv"
    `include "../sequences/fifo_enable_sequence.sv"
    `include "../sequences/basic_push_pop_sequence.sv"
    `include "../sequences/fill_fifo_sequence.sv"
    `include "../sequences/overflow_sequence.sv"
    `include "../sequences/underflow_sequence.sv"
    `include "../sequences/threshold_sequence.sv"
    `include "../sequences/clear_sequence.sv"
    `include "../sequences/random_sequence.sv"
    `include "../sequences/reg_access_sequence.sv"
    `include "../sequences/full_coverage_sequence.sv"
    `include "../sequences/back_to_back_sequence.sv"

    //--------------------------------------------------------------------------
    // Include Tests
    //--------------------------------------------------------------------------
    `include "../tests/apb_fifo_base_test.sv"
    `include "../tests/reset_test.sv"
    `include "../tests/basic_operation_test.sv"
    `include "../tests/overflow_test.sv"
    `include "../tests/underflow_test.sv"
    `include "../tests/threshold_test.sv"
    `include "../tests/register_test.sv"
    `include "../tests/random_test.sv"
    `include "../tests/full_coverage_test.sv"
    `include "../tests/stress_test.sv"
    `include "../tests/back_to_back_test.sv"
endpackage : apb_fifo_pkg

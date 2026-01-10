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
    `include "apb_fifo_ref_model.sv"
    `include "apb_sequence_item.sv"
    `include "apb_sequencer.sv"
    `include "apb_driver.sv"
    `include "apb_monitor.sv"
    `include "apb_agent.sv"
    `include "apb_fifo_scoreboard.sv"
    `include "apb_subscriber.sv"
    `include "apb_fifo_env.sv"

    // Include Sequences
    `include "apb_base_sequence.sv"
    `include "basic_push_pop_sequence.sv"
    `include "fifo_clear_sequence.sv"
    `include "fifo_enable_sequence.sv"
    `include "fifo_reset_sequence.sv"
    `include "overflow_sequence.sv"
    `include "random_sequence.sv"
    `include "threshold_sequence.sv"
    `include "underflow_sequence.sv"

    // Include Tests
    `include "apb_fifo_base_test.sv"
    `include "basic_operation_test.sv"
    `include "fifo_clear_test.sv"
    `include "fifo_enable_test.sv"
    `include "overflow_test.sv"
    `include "random_test.sv"
    `include "reset_test.sv"
    `include "stress_test.sv"
    `include "threshold_test.sv"
    `include "underflow_test.sv"
endpackage : apb_fifo_pkg

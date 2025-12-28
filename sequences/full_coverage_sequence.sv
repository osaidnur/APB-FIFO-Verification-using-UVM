//------------------------------------------------------------------------------
// Full Coverage Sequence - Runs all directed sequences
//------------------------------------------------------------------------------
class full_coverage_sequence extends apb_base_sequence;
  
  `uvm_object_utils(full_coverage_sequence)
  
  function new(string name = "full_coverage_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    reset_sequence          reset_seq;
    fifo_enable_sequence    enable_seq;
    basic_push_pop_sequence push_pop_seq;
    fill_fifo_sequence      fill_seq;
    overflow_sequence       overflow_seq;
    underflow_sequence      underflow_seq;
    threshold_sequence      thresh_seq;
    clear_sequence          clear_seq;
    reg_access_sequence     reg_seq;
    random_sequence         rand_seq;
    
    `uvm_info("SEQ", "Starting Full Coverage Sequence", UVM_MEDIUM)
    
    // Run all directed sequences
    `uvm_do(reset_seq)
    `uvm_do(enable_seq)
    `uvm_do(reg_seq)
    `uvm_do(push_pop_seq)
    `uvm_do(clear_seq)
    `uvm_do(fill_seq)
    `uvm_do(clear_seq)
    `uvm_do(overflow_seq)
    `uvm_do(clear_seq)
    `uvm_do(underflow_seq)
    `uvm_do(clear_seq)
    `uvm_do(thresh_seq)
    `uvm_do(clear_seq)
    `uvm_do_with(rand_seq, {num_transactions == 100;})
    
    `uvm_info("SEQ", "Full Coverage Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : full_coverage_sequence

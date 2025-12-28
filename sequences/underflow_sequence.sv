//------------------------------------------------------------------------------
// Underflow Sequence - Tests underflow condition
//------------------------------------------------------------------------------
class underflow_sequence extends apb_base_sequence;
  
  `uvm_object_utils(underflow_sequence)
  
  function new(string name = "underflow_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [7:0] data;
    bit empty, full, overflow, underflow;
    bit [7:0] count;
    
    `uvm_info("SEQ", "Starting Underflow Sequence", UVM_MEDIUM)
    
    // Enable FIFO
    enable_fifo();
    
    // Clear to ensure empty
    clear_fifo();
    enable_fifo();
    
    // Verify empty
    read_status(empty, full, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("FIFO should be empty: empty=%0d", empty), UVM_MEDIUM)
    
    // Try to pop from empty - should cause underflow
    pop_data(data);
    
    // Check underflow flag
    read_status(empty, full, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("After underflow attempt: underflow=%0d", underflow), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Underflow Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : underflow_sequence

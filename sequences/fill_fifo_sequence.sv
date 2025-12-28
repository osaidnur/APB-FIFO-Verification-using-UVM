//------------------------------------------------------------------------------
// Fill FIFO Sequence - Fills FIFO to capacity
//------------------------------------------------------------------------------
class fill_fifo_sequence extends apb_base_sequence;
  
  `uvm_object_utils(fill_fifo_sequence)
  
  function new(string name = "fill_fifo_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit empty, full, overflow, underflow;
    bit [7:0] count;
    
    `uvm_info("SEQ", "Starting Fill FIFO Sequence", UVM_MEDIUM)
    
    // Enable FIFO
    enable_fifo();
    
    // Fill FIFO completely
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      push_data(i[7:0]);
      read_status(empty, full, overflow, underflow, count);
      `uvm_info("SEQ", $sformatf("Pushed %0d, count=%0d, full=%0d", i, count, full), UVM_HIGH)
    end
    
    // Verify full
    read_status(empty, full, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("FIFO should be full: count=%0d, full=%0d", count, full), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Fill FIFO Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : fill_fifo_sequence

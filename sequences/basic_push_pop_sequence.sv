//------------------------------------------------------------------------------
// Basic Push/Pop Sequence - Simple FIFO operations
//------------------------------------------------------------------------------
class basic_push_pop_sequence extends apb_base_sequence;
  
  `uvm_object_utils(basic_push_pop_sequence)
  
  rand int num_items;
  
  constraint num_items_c {
    num_items inside {[1:FIFO_DEPTH]};
  }
  
  function new(string name = "basic_push_pop_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [7:0] push_data_array[$];
    bit [7:0] pop_data_val;
    bit empty, full, overflow, underflow;
    bit [7:0] count;
    
    `uvm_info("SEQ", $sformatf("Starting Basic Push/Pop Sequence with %0d items", num_items), UVM_MEDIUM)
    
    // Enable FIFO
    enable_fifo();
    
    // Push data
    for (int i = 0; i < num_items; i++) begin
      bit [7:0] data = $urandom_range(0, 255);
      push_data_array.push_back(data);
      push_data(data);
      `uvm_info("SEQ", $sformatf("Pushed: 0x%02h", data), UVM_HIGH)
    end
    
    // Read status
    read_status(empty, full, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("After push: count=%0d, empty=%0d, full=%0d", count, empty, full), UVM_MEDIUM)
    
    // Pop all data
    for (int i = 0; i < num_items; i++) begin
      pop_data(pop_data_val);
      `uvm_info("SEQ", $sformatf("Popped: 0x%02h, Expected: 0x%02h", pop_data_val, push_data_array[i]), UVM_HIGH)
    end
    
    // Verify empty
    read_status(empty, full, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("After pop: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Basic Push/Pop Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : basic_push_pop_sequence

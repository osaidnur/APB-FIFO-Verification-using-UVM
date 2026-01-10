class basic_push_pop_sequence extends apb_base_sequence;
  
  `uvm_object_utils(basic_push_pop_sequence)
    
  function new(string name = "basic_push_pop_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [7:0] pop_data_val;
    bit empty, full, overflow, underflow, almost_full, almost_empty;
    bit [7:0] count;
    int num_items;
    
    `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
    `uvm_info(get_type_name(), "Starting Basic Push/Pop Sequence", UVM_MEDIUM)
    
    // Clear FIFO to start fresh
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

    // Enable FIFO first
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
    
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    
    // Test 1: Push some elements, then pop all - track status after each operation
    `uvm_info(get_type_name(), "--- Test 1: Push Some Elements, then Pop All ---", UVM_MEDIUM)
    
    num_items = $urandom_range(2, FIFO_DEPTH-1); // there is already 2 items 

    // Push random data
    for (int i = 0; i < num_items; i++) begin
      bit [7:0] data = $urandom_range(1, 254);
      push_data(data);
      `uvm_info(get_type_name(), $sformatf("The Element 0x%02h was pushed", data), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), $sformatf("Pushed %0d items total, starting pop", num_items), UVM_MEDIUM)
    
    // Pop all data
    for (int i = 0; i < num_items; i++) begin
      pop_data(pop_data_val);
      `uvm_info(get_type_name(), $sformatf("Popped 0x%02h", pop_data_val), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end

    `uvm_info(get_type_name(), "Test 1 complete ---------------------------------", UVM_MEDIUM)
    
    // Test 2: Interleaved push/pop (push one, pop one immediately)
    `uvm_info(get_type_name(), "--- Test 2: Interleaved Push/Pop ---", UVM_MEDIUM)
    
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)

    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    // Interleaved operations with boundary values
    for (int i = 0; i < 6; i++) begin
      bit [7:0] corners[6] = {8'h00, 8'hFF, 8'h55, 8'hAA, 8'h01, 8'hFE};
      push_data(corners[i]);
      `uvm_info(get_type_name(), $sformatf("Pushed corner data 0x%02h", corners[i]), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
      
      pop_data(pop_data_val);
      `uvm_info(get_type_name(), $sformatf("Popped corner data 0x%02h", pop_data_val), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), "Test 2 complete ---------------------------------", UVM_MEDIUM)
    
    // Test 3: Fill FIFO element by element - track empty, full, count flags
    `uvm_info(get_type_name(), "--- Test 3: Fill FIFO element by element to full ---", UVM_MEDIUM)
    
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
    
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)


    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    // Fill FIFO completely, checking flags at each step
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      bit [7:0] data = $urandom_range(1, 254);
      
      push_data(data);
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), $sformatf("FIFO filled to fifo depth: %d", FIFO_DEPTH), UVM_MEDIUM)
    
    // Test clear resets full flag
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
    
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
    
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    `uvm_info(get_type_name(), "Test 3 complete ---------------------------------------", UVM_MEDIUM)
    
    `uvm_info(get_type_name(), "Basic Push/Pop Sequence Complete", UVM_MEDIUM)
    `uvm_info(get_type_name(), "============================================================", UVM_MEDIUM)
  endtask : body
  
endclass : basic_push_pop_sequence
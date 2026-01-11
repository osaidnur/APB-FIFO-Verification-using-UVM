class random_sequence extends apb_base_sequence;
  
  `uvm_object_utils(random_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[50:200]};
  }
  
  function new(string name = "=================== random_sequence ===================");
    super.new(name);
  endfunction : new
  
  task body();
    apb_sequence_item item;
    
    `uvm_info(get_type_name(), $sformatf("Starting Random Sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    // Enable FIFO first
    enable_fifo();
    
    for (int i = 0; i < num_transactions; i++) begin
      item = apb_sequence_item::type_id::create("item");
      start_item(item);
      
      if (!item.randomize()) begin
        `uvm_error(get_type_name(), "Randomization failed")
      end
      
      finish_item(item);
      get_response(item);
      
      
      // `uvm_info(get_type_name(), $sformatf("Transaction %0d: %s", i, item.convert2string()), UVM_HIGH)
    end
    
    `uvm_info(get_type_name(), "================= Random Sequence Complete ===================", UVM_MEDIUM)
  endtask : body
  
endclass : random_sequence
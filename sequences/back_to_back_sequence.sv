//------------------------------------------------------------------------------
// Back-to-Back Sequence - Tests rapid transactions
//------------------------------------------------------------------------------
class back_to_back_sequence extends apb_base_sequence;
  
  `uvm_object_utils(back_to_back_sequence)
  
  function new(string name = "back_to_back_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    `uvm_info("SEQ", "Starting Back-to-Back Sequence", UVM_MEDIUM)
    
    enable_fifo();
    
    // Rapid push operations
    for (int i = 0; i < 10; i++) begin
      push_data(i[7:0]);
    end
    
    // Rapid pop operations
    for (int i = 0; i < 10; i++) begin
      bit [7:0] data;
      pop_data(data);
    end
    
    // Interleaved push/pop
    for (int i = 0; i < 10; i++) begin
      bit [7:0] data;
      push_data(i[7:0]);
      pop_data(data);
    end
    
    `uvm_info("SEQ", "Back-to-Back Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : back_to_back_sequence

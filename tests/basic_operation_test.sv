//------------------------------------------------------------------------------
// Basic Operation Test - Tests basic push/pop
//------------------------------------------------------------------------------
class basic_operation_test extends apb_fifo_base_test;
  
  `uvm_component_utils(basic_operation_test)
  
  function new(string name = "basic_operation_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    basic_push_pop_sequence seq;
    
    phase.raise_objection(this);
    
    seq = basic_push_pop_sequence::type_id::create("seq");
    seq.randomize() with {num_items == 10;};
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : basic_operation_test

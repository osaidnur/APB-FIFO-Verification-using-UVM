//------------------------------------------------------------------------------
// Back to Back Test - Rapid transaction test
//------------------------------------------------------------------------------
class back_to_back_test extends apb_fifo_base_test;
  
  `uvm_component_utils(back_to_back_test)
  
  function new(string name = "back_to_back_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    back_to_back_sequence seq;
    
    phase.raise_objection(this);
    
    seq = back_to_back_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : back_to_back_test

//------------------------------------------------------------------------------
// Register Test - Tests register access
//------------------------------------------------------------------------------
class register_test extends apb_fifo_base_test;
  
  `uvm_component_utils(register_test)
  
  function new(string name = "register_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    reg_access_sequence seq;
    
    phase.raise_objection(this);
    
    seq = reg_access_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : register_test

//------------------------------------------------------------------------------
// Full Coverage Test - Comprehensive test
//------------------------------------------------------------------------------
class full_coverage_test extends apb_fifo_base_test;
  
  `uvm_component_utils(full_coverage_test)
  
  function new(string name = "full_coverage_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    full_coverage_sequence seq;
    
    phase.raise_objection(this);
    
    seq = full_coverage_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : full_coverage_test

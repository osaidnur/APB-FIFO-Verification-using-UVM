//------------------------------------------------------------------------------
// Clear Test - Tests FIFO clear functionality
//------------------------------------------------------------------------------
class clear_test extends apb_fifo_base_test;
  
  `uvm_component_utils(clear_test)
  
  function new(string name = "clear_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_clear_sequence seq;
    
    phase.raise_objection(this);
    
    seq = fifo_clear_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : clear_test

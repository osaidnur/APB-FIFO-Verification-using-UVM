class basic_operation_test extends apb_fifo_base_test;
  
  `uvm_component_utils(basic_operation_test)
  
  function new(string name = "basic_operation_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_reset_sequence reset_seq;
    basic_push_pop_sequence seq;
    
    phase.raise_objection(this);
    
    reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    seq = basic_push_pop_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : basic_operation_test
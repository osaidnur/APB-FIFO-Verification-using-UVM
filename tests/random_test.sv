class random_test extends apb_fifo_base_test;
  
  `uvm_component_utils(random_test)
  
  function new(string name = "random_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_reset_sequence reset_seq;
    random_sequence seq;
    
    phase.raise_objection(this);
    
    reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    seq = random_sequence::type_id::create("seq");
    seq.randomize() with {num_transactions == 100;};
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : random_test
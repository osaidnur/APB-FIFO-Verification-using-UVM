class stress_test extends apb_fifo_base_test;
  
  `uvm_component_utils(stress_test)
  
  function new(string name = "stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    random_sequence seq;
    fifo_clear_sequence  clear_seq;
    
    phase.raise_objection(this);
    
    // Run multiple iterations of random sequence
    for (int i = 0; i < 5; i++) begin
      seq = random_sequence::type_id::create($sformatf("seq_%0d", i));
      seq.randomize() with {num_transactions == 200;};
      seq.start(env.agent.sequencer);
      
      // Clear FIFO between iterations
      clear_seq = fifo_clear_sequence::type_id::create("clear_seq");
      clear_seq.start(env.agent.sequencer);
    end
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : stress_test
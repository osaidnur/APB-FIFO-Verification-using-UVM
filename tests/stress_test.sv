class stress_test extends apb_fifo_base_test;
  
  `uvm_component_utils(stress_test)
  
  function new(string name = "stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_reset_sequence reset_seq;
    basic_push_pop_sequence push_pop_seq;
    fifo_clear_sequence  clear_seq;
    fifo_enable_sequence enable_seq;
    overflow_sequence overflow_seq;
    underflow_sequence underflow_seq;
    random_sequence random_seq;
    threshold_sequence threshold_seq;


    phase.raise_objection(this);
    
    `uvm_info(get_type_name(), "====================== Starting Stress Test ======================", UVM_MEDIUM)

    reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);

    push_pop_seq = basic_push_pop_sequence::type_id::create("push_pop_seq");
    push_pop_seq.start(env.agent.sequencer);
    
    enable_seq = fifo_enable_sequence::type_id::create("enable_seq");
    enable_seq.start(env.agent.sequencer);

    clear_seq = fifo_clear_sequence::type_id::create("clear_seq");
    clear_seq.start(env.agent.sequencer);

    overflow_seq = overflow_sequence::type_id::create("overflow_seq");
    overflow_seq.start(env.agent.sequencer);

    underflow_seq = underflow_sequence::type_id::create("underflow_seq");
    underflow_seq.start(env.agent.sequencer);

    threshold_seq = threshold_sequence::type_id::create("threshold_seq");
    threshold_seq.start(env.agent.sequencer);

    random_seq = random_sequence::type_id::create("random_seq");
    random_seq.start(env.agent.sequencer);

    `uvm_info(get_type_name(), "====================== Stress Test Completed ======================", UVM_MEDIUM)


    phase.drop_objection(this);
  endtask : run_phase
  
endclass : stress_test
class overflow_test extends apb_fifo_base_test;
  
    `uvm_component_utils(overflow_test)
    
    function new(string name = "overflow_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    task run_phase(uvm_phase phase);
        fifo_reset_sequence reset_seq;
        overflow_sequence seq;
        
        phase.raise_objection(this);
        
        reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
        reset_seq.start(env.agent.sequencer);
        
        seq = overflow_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask : run_phase
  
endclass : overflow_test
class fifo_enable_test extends apb_fifo_base_test;
  
    `uvm_component_utils(fifo_enable_test)
    
    function new(string name = "fifo_enable_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    task run_phase(uvm_phase phase);
        fifo_enable_sequence seq;
        fifo_reset_sequence reset_seq;
        
        phase.raise_objection(this);
        
        seq = fifo_enable_sequence::type_id::create("seq");
        reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
        
        reset_seq.start(env.agent.sequencer);
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask : run_phase

endclass : fifo_enable_test
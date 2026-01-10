// ==============================================================================
// Base Test - Base class for all tests
// ==============================================================================
class apb_fifo_base_test extends uvm_test;

    `uvm_component_utils(apb_fifo_base_test)

    apb_fifo_env env;

    // Constructor
    function new(string name = "apb_fifo_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = apb_fifo_env::type_id::create("env", this);
    endfunction : build_phase

    // End of Elaboration Phase
    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        // uvm_top.print_topology();
    endfunction : end_of_elaboration_phase

    // Report Phase
    function void report_phase(uvm_phase phase);
        uvm_report_server svr;
        super.report_phase(phase);
        
        svr = uvm_report_server::get_server();
        
        `uvm_info("BASE TEST", "", UVM_NONE)
        if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
            `uvm_info("BASE TEST", "╔═══════════════════════════════════════════╗", UVM_NONE)
            `uvm_info("BASE TEST", "║              ✘ TEST FAILED ✘             ║", UVM_NONE)
            `uvm_info("BASE TEST", $sformatf("║        Errors: %3d    Fatals: %3d         ║", 
                    svr.get_severity_count(UVM_ERROR), svr.get_severity_count(UVM_FATAL)), UVM_NONE)
            `uvm_info("BASE TEST", "╚═══════════════════════════════════════════╝", UVM_NONE)
        end else begin
            `uvm_info("BASE TEST", "╔═══════════════════════════════════════════╗", UVM_NONE)
            `uvm_info("BASE TEST", "║              ✓ TEST PASSED ✓             ║", UVM_NONE)
            `uvm_info("BASE TEST", "╚═══════════════════════════════════════════╝", UVM_NONE)
        end
    endfunction : report_phase

endclass : apb_fifo_base_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Reset Test - Tests reset behavior
// ==============================================================================
class reset_test extends apb_fifo_base_test;
  
  `uvm_component_utils(reset_test)
  
  function new(string name = "reset_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_reset_sequence seq;
    
    phase.raise_objection(this);
    
    seq = fifo_reset_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : reset_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// =============================================================================
// FIFO Enable Test 
// =============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// FIFO Clear Test 
// ==============================================================================
class fifo_clear_test extends apb_fifo_base_test;
  
    `uvm_component_utils(fifo_clear_test)
    
    function new(string name = "fifo_clear_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    task run_phase(uvm_phase phase);
        fifo_reset_sequence reset_seq;
        fifo_clear_sequence seq;
        
        phase.raise_objection(this);
        
        seq = fifo_clear_sequence::type_id::create("seq");
        reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
        reset_seq.start(env.agent.sequencer);
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask : run_phase
endclass : fifo_clear_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Basic Operation Test - Tests basic push/pop
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Overflow Test - Tests overflow conditions
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// =============================================================================
// Underflow Test - Tests underflow conditions
// =============================================================================
class underflow_test extends apb_fifo_base_test;
    
    `uvm_component_utils(underflow_test)
    
    function new(string name = "underflow_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    task run_phase(uvm_phase phase);
        fifo_reset_sequence reset_seq;
        underflow_sequence seq;
        
        phase.raise_objection(this);
        
        reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
        reset_seq.start(env.agent.sequencer);
        
        seq = underflow_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask : run_phase
  
endclass : underflow_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Threshold Test - Tests threshold detection
// ==============================================================================
class threshold_test extends apb_fifo_base_test;
  
    `uvm_component_utils(threshold_test)
    
    function new(string name = "threshold_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    task run_phase(uvm_phase phase);
        fifo_reset_sequence reset_seq;
        threshold_sequence seq;
        
        phase.raise_objection(this);
        
        reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
        reset_seq.start(env.agent.sequencer);
        
        seq = threshold_sequence::type_id::create("seq");
        seq.start(env.agent.sequencer);
        
        phase.drop_objection(this);
    endtask : run_phase
  
endclass : threshold_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Register Test - Tests register access
// ==============================================================================
class register_test extends apb_fifo_base_test;
  
  `uvm_component_utils(register_test)
  
  function new(string name = "register_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new
  
  task run_phase(uvm_phase phase);
    fifo_reset_sequence reset_seq;
    reg_access_sequence seq;
    
    phase.raise_objection(this);
    
    reset_seq = fifo_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    seq = reg_access_sequence::type_id::create("seq");
    seq.start(env.agent.sequencer);
    
    phase.drop_objection(this);
  endtask : run_phase
  
endclass : register_test

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Random Test - Random operations
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Full Coverage Test - Comprehensive test
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Stress Test - High volume random test
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################
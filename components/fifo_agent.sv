class alu_agent extends uvm_agent;
    //1. Component
    `uvm_component_utils(alu_agent)

    //2.Initializations of agent components
    alu_driver driver;
    alu_monitor monitor;
    alu_sequencer sequencer;

    //3. Constuctor
    function new(string name = "alu_agent", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //4. Build Phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver = alu_driver::type_id::create("driver", this);
        monitor = alu_monitor::type_id::create("monitor", this);
        sequencer = alu_sequencer::type_id::create("sequencer", this);
    endfunction : build_phase

    //5. Connect Phase
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction : connect_phase

    //6. Run Phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase

endclass: alu_agent
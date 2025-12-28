class apb_agent extends uvm_agent;

    `uvm_component_utils(apb_agent)

    apb_sequencer sequencer;
    apb_driver driver;
    apb_monitor monitor;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create driver and sequencer only if active
        if (get_is_active() == UVM_ACTIVE) begin
            driver = apb_driver::type_id::create("driver", this);
            sequencer = apb_sequencer::type_id::create("sequencer", this);
        end

        // Always create monitor
        monitor = apb_monitor::type_id::create("monitor", this);
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Connect Phase
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect driver to sequencer if active
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction : connect_phase

endclass : apb_agent
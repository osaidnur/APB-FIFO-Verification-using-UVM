class apb_fifo_env extends uvm_env;

    `uvm_component_utils(apb_fifo_env)

    apb_agent agent;
    apb_fifo_scoreboard scoreboard;
    apb_subscriber subscriber;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_fifo_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // Create agent
        agent = apb_agent::type_id::create("agent", this);

        // Create scoreboard
        scoreboard = apb_fifo_scoreboard::type_id::create("scoreboard", this);

        // Create coverage collector
        subscriber = apb_subscriber::type_id::create("subscriber", this);
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Connect Phase
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor to scoreboard
        agent.monitor.ap.connect(scoreboard.analysis_export);

        // Connect monitor to coverage
        agent.monitor.ap.connect(subscriber.analysis_export);
    endfunction : connect_phase

endclass : apb_fifo_env

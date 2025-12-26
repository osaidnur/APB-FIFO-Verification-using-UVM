class alu_env extends uvm_env;
    //1. Component 
    `uvm_component_utils(alu_env)

    //2. Initialize
    alu_agent agent;
    alu_scoreboard scb;

    //3. Constructor
    function new(string name = "alu_env", uvm_component parent);
        super.new(name, parent);
    endfunction : new

    //4. Build
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = alu_agent::type_id::create("agent", this);
        scb  = alu_scoreboard::type_id::create("scb", this);
    endfunction : build_phase

    //5. Connect
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.monitor_port.connect(scb.scoreboard_port);
    endfunction : connect_phase

    //6. Run
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
    endtask : run_phase


endclass: alu_env
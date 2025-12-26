class BaseTest extends uvm_test;
    //1. Component
    `uvm_component_utils(BaseTest)

    //2. Initialize
    Adder_env env;
    //3. Constructor
    function new(string name = "BaseTest", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //4. Build
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = Adder_env::type_id::create("env",this);
    endfunction : build_phase

    //5. End of Elaboration
    function void end_of_elaboration();
        print();
    endfunction

    //6. Connect
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction : connect_phase

    function void report_phase(uvm_phase phase);
    uvm_report_server svr;
    super.report_phase(phase);

    svr = uvm_report_server::get_server();
    if (svr.get_severity_count(UVM_FATAL) + svr.get_severity_count(UVM_ERROR) > 0) begin
      `uvm_info(get_type_name(), "┌───────────────────────────────────────────┐", UVM_NONE)
      `uvm_info(get_type_name(), "│              ✘ TEST FAILED ✘             │", UVM_NONE)
      `uvm_info(get_type_name(), "│   Fatal or Error messages were detected   │", UVM_NONE)
      `uvm_info(get_type_name(), "└───────────────────────────────────────────┘", UVM_NONE)
    end else begin
      `uvm_info(get_type_name(), "┌───────────────────────────────────────────┐", UVM_NONE)
      `uvm_info(get_type_name(), "│              ✓ TEST PASSED ✓✓            |", UVM_NONE)
      `uvm_info(get_type_name(), "│     No fatal or error messages reported   │", UVM_NONE)
      `uvm_info(get_type_name(), "└───────────────────────────────────────────┘", UVM_NONE)
    end

  endfunction



endclass
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
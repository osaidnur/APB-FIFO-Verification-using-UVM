class apb_fifo_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_fifo_scoreboard)

    // Analysis Port
    uvm_analysis_imp #(apb_sequence_item, apb_fifo_scoreboard) analysis_export;

    // Reference Model Instance
    apb_fifo_ref_model ref_model;

    // Some Statistics
    int pass_count;
    int fail_count;
    int total_transactions;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_fifo_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
        ref_model = new();
        `uvm_info("SCB", "Reference model created", UVM_MEDIUM)
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Write Implementation - No Run Phase Needed
    //--------------------------------------------------------------------------
    function void write(apb_sequence_item item);
        bit [31:0] expected;
        bit [7:0] expected_data;
        bit success;
        
        total_transactions++;
        
        `uvm_info("SCB", $sformatf("Processing: %s to Addr=0x%02h", item.pwrite ? "WRITE" : "READ", item.paddr), UVM_HIGH)
        
        // WRITE transactions :
        if (item.pwrite == APB_WRITE) begin
            case (item.paddr)
                CTRL_OFFSET: ref_model.write_ctrl(item.pwdata);
                THRESH_OFFSET: ref_model.write_thresh(item.pwdata);
                STATUS_OFFSET: `uvm_warning("SCB", "STATUS register is read-only, write ignored")
                DATA_OFFSET: void'(ref_model.push(item.pwdata));
                default: `uvm_warning("SCB", $sformatf("Unknown register address: 0x%02h", item.paddr))
            endcase
        end 
        
        // READ transactions :
        else begin
            case (item.paddr)
                CTRL_OFFSET: begin
                    expected = ref_model.read_ctrl();
                    compare("CTRL", expected, item.prdata);
                end
                THRESH_OFFSET: begin
                    expected = ref_model.read_thresh();
                    compare("THRESH", expected, item.prdata);
                end
                STATUS_OFFSET: begin
                    expected = ref_model.read_status();
                    compare("STATUS", expected, item.prdata);
                end
                DATA_OFFSET: begin
                    expected_data = ref_model.pop(success);
                    compare("DATA", expected_data, item.prdata);
                end
                default: `uvm_warning("SCB", $sformatf("Unknown register address: 0x%02h", item.paddr))
            endcase
        end
        
        `uvm_info("SCB", ref_model.print_status(), UVM_HIGH)
    endfunction : write

    //--------------------------------------------------------------------------
    // Compare Expected vs Actual
    //--------------------------------------------------------------------------
    function void compare(string reg_name, bit [31:0] expected, bit [31:0] actual);
        if (actual !== expected) begin
            fail_count++;
            `uvm_error("SCB", $sformatf("%s Mismatch: Expected=0x%08h, Actual=0x%08h",
                    reg_name, expected, actual))
        end else begin
            pass_count++;
            `uvm_info("SCB", $sformatf("%s Match: 0x%08h", reg_name, actual), UVM_HIGH)
        end
    endfunction : compare

    //--------------------------------------------------------------------------
    // Report Phase
    //--------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("SCB", "╔══════════════════════════════════════════╗", UVM_NONE)
        `uvm_info("SCB", "║      SCOREBOARD SUMMARY REPORT           ║", UVM_NONE)
        `uvm_info("SCB", "╠══════════════════════════════════════════╣", UVM_NONE)
        `uvm_info("SCB", $sformatf("║  Total Transactions: %5d              ║", total_transactions), UVM_NONE)
        `uvm_info("SCB", $sformatf("║  Passed Checks:      %5d              ║", pass_count), UVM_NONE)
        `uvm_info("SCB", $sformatf("║  Failed Checks:      %5d              ║", fail_count), UVM_NONE)
        `uvm_info("SCB", $sformatf("║  Final FIFO Count:   %5d              ║", ref_model.get_count()), UVM_NONE)
        `uvm_info("SCB", "╚══════════════════════════════════════════╝", UVM_NONE)
        
        if (fail_count > 0) begin
            `uvm_info("SCB", "┌─────────────────────────────────────────┐", UVM_NONE)
            `uvm_info("SCB", "│           ✘ TEST FAILED ✘               │", UVM_NONE)
            `uvm_info("SCB", "└─────────────────────────────────────────┘", UVM_NONE)
        end else begin
            `uvm_info("SCB", "┌─────────────────────────────────────────┐", UVM_NONE)
            `uvm_info("SCB", "│           ✓ TEST PASSED ✓               │", UVM_NONE)
            `uvm_info("SCB", "└─────────────────────────────────────────┘", UVM_NONE)
        end
    endfunction : report_phase

endclass : apb_fifo_scoreboard

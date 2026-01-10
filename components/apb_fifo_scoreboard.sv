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
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Write function 
    //--------------------------------------------------------------------------
    function void write(apb_sequence_item item);
        bit [31:0] expected;
        bit [7:0] expected_data;
        bit success;
        
        // Handle reset - reset reference model when PRESETn is low
        if (item.presetn == 1'b0) begin
            `uvm_info("Scoreboard", "(!!!!!) Reset detected - resetting reference model (!!!!!)", UVM_MEDIUM)
            ref_model.reset();
            return;  // Don't process transaction during reset
        end
        
        total_transactions++;
        
        `uvm_info("Scoreboard", $sformatf("Processing: %s to Addr=0x%02h, pwrite=%0b", item.pwrite ? "WRITE" : "READ", item.paddr, item.pwrite), UVM_HIGH)
        
        // WRITE transactions :
        if (item.pwrite == APB_WRITE) begin
            case (item.paddr)
                CTRL_OFFSET: begin
                    ref_model.write_ctrl(item.pwdata);
                end
                THRESH_OFFSET: begin
                    ref_model.write_thresh(item.pwdata);
                end
                STATUS_OFFSET: begin
                    `uvm_warning("Scoreboard", "(!!!) STATUS register is read-only, write ignored")
                end
                DATA_OFFSET: begin
                    bit push_success;
                    push_success = ref_model.push(item.pwdata[7:0]);
                    compare_error(!push_success, item.pslverr);
                end
                default: `uvm_warning("Scoreboard", $sformatf("(!!!) Unknown register address: 0x%02h", item.paddr))
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

                    compare("DATA", expected_data, item.prdata[7:0]);
                end
                default: `uvm_warning("SCB", $sformatf("Unknown register address: 0x%02h", item.paddr))
            endcase
        end
        
    endfunction : write

    //--------------------------------------------------------------------------
    // Compare Error Signal (PSLVERR)
    //--------------------------------------------------------------------------
    function void compare_error(bit expected_error, bit actual_error);
        if (actual_error !== expected_error) begin
            fail_count++;
            `uvm_error("Scoreboard", "============================================================")
            `uvm_error("Scoreboard", $sformatf("PSLVERR Mismatch: Expected=%0b, Actual=%0b", expected_error, actual_error))
            `uvm_error("Scoreboard", "============================================================")
        end else begin
            pass_count++;
            if (expected_error) begin
                `uvm_info("Scoreboard", $sformatf("PSLVERR correctly asserted (error expected and occurred)"), UVM_MEDIUM)
            end else begin
                `uvm_info("Scoreboard", $sformatf("PSLVERR correctly deasserted (no error)"), UVM_HIGH)
            end
        end
    endfunction : compare_error

    //--------------------------------------------------------------------------
    // Compare Expected vs Actual
    //--------------------------------------------------------------------------
    function void compare(string reg_name, bit [31:0] expected, bit [31:0] actual);
        if (actual !== expected) begin
            fail_count++;
            `uvm_error("Scoreboard", $sformatf("============================================================"))
            `uvm_error("Scoreboard", $sformatf("%s Mismatch: Expected=0x%08h, Actual=0x%08h", reg_name, expected, actual))
            
            // Detailed breakdown for different register types
            if (reg_name == "STATUS") begin
                `uvm_error("Scoreboard", $sformatf("  STATUS Details:"))
                `uvm_error("Scoreboard", $sformatf("    Empty:       Exp=%0b Act=%0b %s", expected[0], actual[0], (expected[0]!=actual[0])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    Full:        Exp=%0b Act=%0b %s", expected[1], actual[1], (expected[1]!=actual[1])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    AlmostFull:  Exp=%0b Act=%0b %s", expected[2], actual[2], (expected[2]!=actual[2])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    AlmostEmpty: Exp=%0b Act=%0b %s", expected[3], actual[3], (expected[3]!=actual[3])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    Overflow:    Exp=%0b Act=%0b %s", expected[4], actual[4], (expected[4]!=actual[4])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    Underflow:   Exp=%0b Act=%0b %s", expected[5], actual[5], (expected[5]!=actual[5])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    Count:       Exp=%0d Act=%0d %s", expected[13:6], actual[13:6], (expected[13:6]!=actual[13:6])?"MISMATCH":""))
            end else if (reg_name == "CTRL") begin
                `uvm_error("Scoreboard", $sformatf("  CTRL Details:"))
                `uvm_error("Scoreboard", $sformatf("    Enable:      Exp=%0b Act=%0b %s", expected[0], actual[0], (expected[0]!=actual[0])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    Clear:       Exp=%0b Act=%0b %s", expected[1], actual[1], (expected[1]!=actual[1])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    DropOnFull:  Exp=%0b Act=%0b %s", expected[2], actual[2], (expected[2]!=actual[2])?"MISMATCH":""))
            end else if (reg_name == "THRESH") begin
                `uvm_error("Scoreboard", $sformatf("  THRESH Details:"))
                `uvm_error("Scoreboard", $sformatf("    AlmostFullTh:  Exp=%0d Act=%0d %s", expected[7:0], actual[7:0], (expected[7:0]!=actual[7:0])?"MISMATCH":""))
                `uvm_error("Scoreboard", $sformatf("    AlmostEmptyTh: Exp=%0d Act=%0d %s", expected[15:8], actual[15:8], (expected[15:8]!=actual[15:8])?"MISMATCH":""))
            end
            `uvm_error("Scoreboard", $sformatf("============================================================"))
        end else begin
            pass_count++;
            `uvm_info("Scoreboard", $sformatf("┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"), UVM_MEDIUM)
            `uvm_info("Scoreboard", $sformatf("┃%6s Match: 0x%08h                                                      ┃", reg_name, actual), UVM_MEDIUM)
            `uvm_info("Scoreboard", ref_model.print_status(), UVM_MEDIUM)
            `uvm_info("Scoreboard", $sformatf("┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"), UVM_MEDIUM)
        end
    endfunction : compare

    //--------------------------------------------------------------------------
    // Report Phase
    //--------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("Scoreboard", "╔══════════════════════════════════════════╗", UVM_NONE)
        `uvm_info("Scoreboard", "║      SCOREBOARD SUMMARY REPORT           ║", UVM_NONE)
        `uvm_info("Scoreboard", "╠══════════════════════════════════════════╣", UVM_NONE)
        `uvm_info("Scoreboard", $sformatf("║  Total Transactions: %5d               ║", total_transactions), UVM_NONE)
        `uvm_info("Scoreboard", $sformatf("║  Passed Checks:      %5d               ║", pass_count), UVM_NONE)
        `uvm_info("Scoreboard", $sformatf("║  Failed Checks:      %5d               ║", fail_count), UVM_NONE)
        `uvm_info("Scoreboard", $sformatf("║  Final FIFO Count:   %5d               ║", ref_model.get_count()), UVM_NONE)
        `uvm_info("Scoreboard", "╚══════════════════════════════════════════╝", UVM_NONE)
        
        if (fail_count > 0) begin
            `uvm_info("Scoreboard", "┌─────────────────────────────────────────┐", UVM_NONE)
            `uvm_info("Scoreboard", "│           ✘ TEST FAILED ✘              │", UVM_NONE)
            `uvm_info("Scoreboard", "└─────────────────────────────────────────┘", UVM_NONE)
        end else begin
            `uvm_info("Scoreboard", "┌─────────────────────────────────────────┐", UVM_NONE)
            `uvm_info("Scoreboard", "│           ✓ TEST PASSED ✓              │", UVM_NONE)
            `uvm_info("Scoreboard", "└─────────────────────────────────────────┘", UVM_NONE)
        end
    endfunction : report_phase

endclass : apb_fifo_scoreboard
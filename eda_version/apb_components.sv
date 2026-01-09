// ==============================================================================
// Sequence Item - APB Transaction
// ==============================================================================
class apb_sequence_item extends uvm_sequence_item;
    
    // Reset signal
    rand bit presetn;

    // inputs to DUT
    rand bit pwrite;
    rand bit [7:0] paddr;
    rand bit [31:0] pwdata;

    // outputs from DUT
    bit [31:0] prdata;
    bit pslverr;

    // Valid address constraint
    constraint valid_addr_c {
        paddr inside {CTRL_OFFSET, THRESH_OFFSET, STATUS_OFFSET, DATA_OFFSET};
    }

    // CTRL register constraint
    constraint ctrl_reg_c {
        // [0]: EN
        // [1]: CLR
        // [2]: DROP_ON_FULL
        (paddr == CTRL_OFFSET) -> pwdata[31:3] == 29'h0;
    }

    // THRESH register constraint
    constraint thresh_reg_c {
        // [15:8] almost_empty_th
        // [7:0]  almost_full_th  
        (paddr == THRESH_OFFSET) -> pwdata[31:16] == 16'h0;
    }

    // Write data constraint for DATA register (8-bit)
    constraint data_reg_c {
        // data needs just [7:0] valid, upper bits zero
        (paddr == DATA_OFFSET) -> pwdata[31:8] == 24'h0;
    }

    // Reset is always high during normal operations
    constraint reset_default_c {
        presetn == 1'b1;
    }

    // macros
    `uvm_object_utils_begin(apb_sequence_item)
    `uvm_field_int(presetn, UVM_ALL_ON)
    `uvm_field_int(pwrite, UVM_ALL_ON)
    `uvm_field_int(paddr, UVM_ALL_ON)
    `uvm_field_int(pwdata, UVM_ALL_ON)
    `uvm_field_int(prdata, UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "apb_sequence_item");
        super.new(name);
    endfunction : new

endclass : apb_sequence_item

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Sequencer
// ==============================================================================
class apb_sequencer extends uvm_sequencer #(apb_sequence_item);

    `uvm_component_utils(apb_sequencer)

    function new(string name = "apb_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

endclass : apb_sequencer

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ===============================================================================
// Driver
// ===============================================================================
class apb_driver extends uvm_driver #(apb_sequence_item);

    `uvm_component_utils(apb_driver)

    virtual apb_fifo_if vif;
    
    // --------------------------------------------------------------------------
    // Constructor
    // --------------------------------------------------------------------------
    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // --------------------------------------------------------------------------
    // Build Phase
    // --------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Failed to get virtual interface from config DB")
        end
    endfunction : build_phase

    // --------------------------------------------------------------------------
    // Reset Signals
    // --------------------------------------------------------------------------
    task drive_idle();
        vif.PRESETn <= 1'b1;
        vif.PSEL <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PWRITE <= 1'b0;
        vif.PADDR <= 8'h0;
        vif.PWDATA <= 32'h0;
    endtask : drive_idle

    // --------------------------------------------------------------------------
    // Run Phase
    // --------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_sequence_item item;

        // Initialize APB signals
        drive_idle();

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("Driver", $sformatf("Driving %s transaction: addr=0x%02h, pwdata=0x%0h",
                        item.pwrite ? "WRITE" : "READ", item.paddr, item.pwdata), UVM_HIGH)
            drive(item);
            seq_item_port.item_done(item);
        end
    endtask : run_phase

    // --------------------------------------------------------------------------
    // Drive APB Transaction
    // --------------------------------------------------------------------------
    task drive(apb_sequence_item tr);
        
        // If reset is asserted, just drive reset and idle signals
        if (tr.presetn == 1'b0) begin
            @(posedge vif.PCLK);
            vif.PRESETn <= 1'b0;
            vif.PSEL <= 1'b0;
            vif.PENABLE <= 1'b0;
            vif.PWRITE <= 1'b0;
            vif.PADDR <= 8'h0;
            vif.PWDATA <= 32'h0;
            return;
        end

        // Normal operation-no reset

        // SETUP cycle
        @(posedge vif.PCLK);
        vif.PRESETn <= 1'b1;
        vif.PSEL <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE <= tr.pwrite;
        vif.PADDR <= tr.paddr;
        vif.PWDATA <= tr.pwdata;

        // ACCESS cycle
        @(posedge vif.PCLK);
        vif.PENABLE <= 1'b1;

        // keep signals stable until PREADY=1
        while (vif.PREADY !== 1'b1) begin
            @(posedge vif.PCLK);
        end

        // The transfer is completed here, so take the outputs
        tr.pslverr = vif.PSLVERR;
        if (!tr.pwrite) begin
            tr.prdata = vif.PRDATA;
        end

        // Return to IDLE
        @(posedge vif.PCLK);
        drive_idle();
    endtask

endclass : apb_driver


// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Monitor
// ==============================================================================
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_fifo_if vif;
    uvm_analysis_port #(apb_sequence_item) ap ;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual apb_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("APB_MON", "Failed to get virtual interface from config DB")
        end
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Run Phase
    //--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_sequence_item item;

        forever begin
            @(posedge vif.PCLK);
            #0; // Wait for NBA region to settle (driver's non-blocking assignments)
            
            // for debugging
            // `uvm_info("Monitor", $sformatf("@ %0t: PRESETn=%b PSEL=%b PENABLE=%b PREADY=%b PWRITE=%b PADDR=0x%02h", 
            //           $time, vif.PRESETn, vif.PSEL, vif.PENABLE, vif.PREADY, 
            //           vif.PWRITE, vif.PADDR), UVM_HIGH)            
            
            // APB transfer completes when PSEL=1, PENABLE=1, PREADY=1
            if ((vif.PSEL && vif.PENABLE && vif.PREADY) || vif.PRESETn === 1'b0) begin
                item = apb_sequence_item::type_id::create("item", this);
                item.presetn = vif.PRESETn;
                item.paddr   = vif.PADDR;
                item.pwrite  = vif.PWRITE;
                item.pwdata  = vif.PWDATA;
                item.prdata  = vif.PRDATA;
                item.pslverr = vif.PSLVERR;
                `uvm_info("Monitor", $sformatf("Monitoring %s transaction: addr=0x%02h, pwdata=0x%08h, prdata=0x%08h", 
                          item.pwrite ? "WRITE" : "READ", item.paddr, item.pwdata, item.prdata), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask : run_phase
endclass : apb_monitor

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Agent
// ==============================================================================
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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Reference Model
// ==============================================================================
class apb_fifo_ref_model;

    // local parameters
    localparam int DEPTH = FIFO_DEPTH;
    localparam int WIDTH = FIFO_WIDTH;

    // Virtual FIFO memory
    protected bit [WIDTH-1:0] fifo_mem[$];

    // Control Registers
    protected bit en; // fifo enable
    protected bit clr; // clear
    protected bit drop_on_full; // drop new data when full
    protected bit [7:0] almost_full_th;  // almost full threshold
    protected bit [7:0] almost_empty_th; // almost empty threshold

    // Status Flags
    protected bit empty_flag;
    protected bit full_flag;
    protected bit almost_full_flag;
    protected bit almost_empty_flag;
    protected bit overflow_flag; // sticky flag
    protected bit underflow_flag; // sticky flag
    protected int count;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new();
        reset();
    endfunction : new

    //------------------------------------------------------
    // Reset
    //------------------------------------------------------
    function void reset();
        fifo_mem.delete();
        count = 0;
        
        // Control register
        en = 1'b0;
        clr = 1'b0;
        drop_on_full = 1'b0;

        // Thresholds
        almost_full_th = DEPTH - 1; // default = 15 when DEPTH=16
        almost_empty_th = 8'd1; // default = 1
        
        // Status flags
        empty_flag = 1'b1;
        full_flag = 1'b0;
        almost_full_flag = 1'b0;
        almost_empty_flag= 1'b1;
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;
    endfunction : reset

    //------------------------------------------------------
    // Clear FIFO - when clr flag is set 
    //------------------------------------------------------
    function void clear_fifo();
        fifo_mem.delete();
        count = 0;
        overflow_flag = 1'b0; // only cleared here
        underflow_flag = 1'b0; // only cleared here
        update_flags();
    endfunction : clear_fifo

    //------------------------------------------------------
    // Update Flags
    //------------------------------------------------------
    protected function void update_flags();
        count = fifo_mem.size();
        empty_flag = (count == 0);
        full_flag = (count >= DEPTH);
        almost_full_flag = (count >= almost_full_th);
        almost_empty_flag = (count <= almost_empty_th);
    endfunction : update_flags

    //------------------------------------------------------
    // Push Operation - 1:success, 0:failed 
    //------------------------------------------------------
    function bit push(bit [WIDTH-1:0] data);
        if (!en) begin
            return 0; // FIFO is disabled
        end
        
        if (full_flag) begin
            overflow_flag = 1'b1;
            if (drop_on_full) begin
                return 1; // overflow without error
            end
            return 0; // overflow + error
        end
        
        fifo_mem.push_back(data);
        update_flags();
        return 1;
    endfunction : push

    //------------------------------------------------------
    // Pop Operation - return data + success=1 when the pop
    // is successful, success=0 otherwise(underflow or disabled)
    //------------------------------------------------------
    function bit [WIDTH-1:0] pop(output bit success);
        bit [WIDTH-1:0] data;
        
        if (!en) begin
            success = 0;
            return 0; // FIFO is disabled
        end
        
        if (empty_flag) begin
            underflow_flag = 1'b1;
            success = 0;
            return 0; // Underflow condition
        end
        
        data = fifo_mem.pop_front();
        update_flags();
        success = 1;
        return data;
    endfunction : pop

    //------------------------------------------------------
    // Write CTRL register
    //------------------------------------------------------
    function void write_ctrl(bit [31:0] data);
        en = data[0];
        clr = data[1];
        drop_on_full = data[2];
        
        if (clr) begin
            clear_fifo();
            clr = 1'b0; // return to 0 after clearing
        end
    endfunction : write_ctrl

    //------------------------------------------------------
    // Read CTRL register
    //------------------------------------------------------
    function bit [31:0] read_ctrl();
        return {29'h0, drop_on_full, clr, en};
    endfunction : read_ctrl

    //------------------------------------------------------
    // Write THRESH register
    //------------------------------------------------------
    function void write_thresh(bit [31:0] data);
        almost_full_th  = data[7:0];
        almost_empty_th = data[15:8];
        update_flags();
    endfunction : write_thresh

    //------------------------------------------------------
    // Read THRESH register
    //------------------------------------------------------
    function bit [31:0] read_thresh();
        return {16'h0, almost_empty_th, almost_full_th};
    endfunction : read_thresh

    //------------------------------------------------------
    // Read STATUS register
    //------------------------------------------------------
    function bit [31:0] read_status();
        update_flags();
        return {18'h0, count[7:0], underflow_flag, overflow_flag, almost_empty_flag, almost_full_flag, full_flag, empty_flag};
    endfunction : read_status

    function bit is_empty();
        return empty_flag;
    endfunction : is_empty

    function bit is_full();
        return full_flag;
    endfunction : is_full

    function bit is_almost_full();
        return almost_full_flag;
    endfunction : is_almost_full

    function bit is_almost_empty();
        return almost_empty_flag;
    endfunction : is_almost_empty

    function bit has_overflow();
        return overflow_flag;
    endfunction : has_overflow

    function bit has_underflow();
        return underflow_flag;
    endfunction : has_underflow

    function int get_count();
        return count;
    endfunction : get_count

    function bit is_enabled();
        return en;
    endfunction : is_enabled

    function bit get_drop_on_full();
        return drop_on_full;
    endfunction : get_drop_on_full

    function bit [7:0] get_almost_full_th();
        return almost_full_th;
    endfunction : get_almost_full_th

    function bit [7:0] get_almost_empty_th();
        return almost_empty_th;
    endfunction : get_almost_empty_th

    //--------------------------------------------------------------------------
    // Debug: Get FIFO contents as string
    //--------------------------------------------------------------------------
    function string print_status();
        string s;
        s = $sformatf("┃RefModel State: EN=%0d, Count=%0d/%0d, Empty=%0d, Full=%0d, AF=%0d, AE=%0d, OVF=%0d, UNF=%0d   ┃",
                        en, count, DEPTH, empty_flag, full_flag, almost_full_flag, almost_empty_flag, overflow_flag,
                        underflow_flag);
        return s;
    endfunction : print_status

endclass : apb_fifo_ref_model

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Scoreboard
// ==============================================================================
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
                CTRL_OFFSET: ref_model.write_ctrl(item.pwdata);
                THRESH_OFFSET: ref_model.write_thresh(item.pwdata);
                STATUS_OFFSET: `uvm_warning("Scoreboard", "(!!!) STATUS register is read-only, write ignored")
                DATA_OFFSET: void'(ref_model.push(item.pwdata));
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
                    compare("DATA", expected_data, item.prdata);
                end
                default: `uvm_warning("SCB", $sformatf("Unknown register address: 0x%02h", item.paddr))
            endcase
        end
        
    endfunction : write

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

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Coverage Subscriber
// ==============================================================================
class apb_subscriber extends uvm_subscriber #(apb_sequence_item);
    
    `uvm_component_utils(apb_subscriber)
    
    apb_sequence_item item;
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_fifo_coverage", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new
    
    //--------------------------------------------------------------------------
    // Write Implementation - Called when monitor broadcasts a transaction
    //--------------------------------------------------------------------------
    function void write(apb_sequence_item t);
        item = t;
        // Coverage sampling would go here
        `uvm_info("COV", $sformatf("Coverage transaction: %s to 0x%02h", 
                  t.pwrite ? "WRITE" : "READ", t.paddr), UVM_HIGH)
    endfunction : write

endclass : apb_subscriber

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Environment
// ==============================================================================
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

        // Create subscriber (coverage collector)
        subscriber = apb_subscriber::type_id::create("subscriber", this);
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Connect Phase
    //--------------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Connect monitor to scoreboard
        agent.monitor.ap.connect(scoreboard.analysis_export);

        // Connect monitor to subscriber (coverage collector)
        agent.monitor.ap.connect(subscriber.analysis_export);
    endfunction : connect_phase

endclass : apb_fifo_env

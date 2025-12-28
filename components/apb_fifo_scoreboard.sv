//------------------------------------------------------------------------------
// APB FIFO Scoreboard - Uses Reference Model for checking
//------------------------------------------------------------------------------
class apb_fifo_scoreboard extends uvm_scoreboard;
  
  `uvm_component_utils(apb_fifo_scoreboard)
  
  //--------------------------------------------------------------------------
  // Analysis Port
  //--------------------------------------------------------------------------
  uvm_analysis_imp #(apb_sequence_item, apb_fifo_scoreboard) analysis_export;
  
  //--------------------------------------------------------------------------
  // Reference Model Instance
  //--------------------------------------------------------------------------
  apb_fifo_ref_model ref_model;
  
  //--------------------------------------------------------------------------
  // Statistics
  //--------------------------------------------------------------------------
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
  // Reset Reference Model (can be called from test on reset)
  //--------------------------------------------------------------------------
  function void reset_ref_model();
    ref_model.reset();
    pass_count = 0;
    fail_count = 0;
    total_transactions = 0;
    `uvm_info("SCB", "Reference model reset", UVM_MEDIUM)
  endfunction : reset_ref_model
  
  //--------------------------------------------------------------------------
  // Write Implementation - Called when monitor broadcasts a transaction
  //--------------------------------------------------------------------------
  function void write(apb_sequence_item item);
    total_transactions++;
    
    `uvm_info("SCB", $sformatf("Processing: %s to Addr=0x%02h", 
              item.pwrite ? "WRITE" : "READ", item.paddr), UVM_HIGH)
    
    case (item.paddr)
      CTRL_OFFSET:   process_ctrl_access(item);
      THRESH_OFFSET: process_thresh_access(item);
      STATUS_OFFSET: process_status_access(item);
      DATA_OFFSET:   process_data_access(item);
      default: begin
        `uvm_warning("SCB", $sformatf("Unknown register address: 0x%02h", item.paddr))
      end
    endcase
    
    `uvm_info("SCB", ref_model.get_debug_string(), UVM_HIGH)
  endfunction : write
  
  //--------------------------------------------------------------------------
  // Process CTRL Register Access
  //--------------------------------------------------------------------------
  function void process_ctrl_access(apb_sequence_item item);
    if (item.pwrite == APB_WRITE) begin
      ref_model.write_ctrl(item.pwdata);
      
      `uvm_info("SCB", $sformatf("CTRL Write: EN=%0d, CLR=%0d, DROP_ON_FULL=%0d", 
                item.pwdata[0], item.pwdata[1], item.pwdata[2]), UVM_MEDIUM)
    end else begin
      // Read - check expected value
      bit [31:0] expected = ref_model.read_ctrl();
      check_read_data("CTRL", expected, item.prdata);
    end
  endfunction : process_ctrl_access
  
  //--------------------------------------------------------------------------
  // Process THRESH Register Access
  //--------------------------------------------------------------------------
  function void process_thresh_access(apb_sequence_item item);
    if (item.pwrite == APB_WRITE) begin
      ref_model.write_thresh(item.pwdata);
      
      `uvm_info("SCB", $sformatf("THRESH Write: ALMOST_FULL_TH=%0d, ALMOST_EMPTY_TH=%0d", 
                item.pwdata[7:0], item.pwdata[15:8]), UVM_MEDIUM)
    end else begin
      // Read - check expected value
      bit [31:0] expected = ref_model.read_thresh();
      check_read_data("THRESH", expected, item.prdata);
    end
  endfunction : process_thresh_access
  
  //--------------------------------------------------------------------------
  // Process STATUS Register Access
  //--------------------------------------------------------------------------
  function void process_status_access(apb_sequence_item item);
    if (item.pwrite == APB_READ) begin
      bit [31:0] expected = ref_model.read_status();
      check_read_data("STATUS", expected, item.prdata);
      
      // Note: The buggy DUT clears overflow/underflow on any read
      // Uncomment below if DUT behavior needs to be matched:
      // ref_model.clear_sticky_flags();
    end else begin
      `uvm_warning("SCB", "STATUS register is read-only, write ignored")
    end
  endfunction : process_status_access
  
  //--------------------------------------------------------------------------
  // Process DATA Register Access
  //--------------------------------------------------------------------------
  function void process_data_access(apb_sequence_item item);
    if (item.pwrite == APB_WRITE) begin
      // PUSH operation
      if (!ref_model.is_enabled()) begin
        `uvm_info("SCB", "FIFO disabled - push ignored", UVM_MEDIUM)
        return;
      end
      
      if (ref_model.push(item.pwdata[7:0])) begin
        `uvm_info("SCB", $sformatf("PUSH: Data=0x%02h, Count=%0d", 
                  item.pwdata[7:0], ref_model.get_count()), UVM_MEDIUM)
      end else begin
        if (ref_model.is_full()) begin
          `uvm_info("SCB", $sformatf("FIFO full - overflow, drop_on_full=%0d", 
                    ref_model.get_drop_on_full()), UVM_MEDIUM)
        end
      end
    end else begin
      // POP operation (READ from DATA register)
      bit success;
      bit [7:0] expected_data;
      
      if (!ref_model.is_enabled()) begin
        `uvm_info("SCB", "FIFO disabled - pop returns stale data", UVM_MEDIUM)
        return;
      end
      
      if (ref_model.is_empty()) begin
        // Will cause underflow in ref model
        expected_data = ref_model.pop(success);
        `uvm_info("SCB", "FIFO empty - underflow", UVM_MEDIUM)
      end else begin
        expected_data = ref_model.pop(success);
        
        `uvm_info("SCB", $sformatf("POP: Expected=0x%02h, Actual=0x%02h, Count=%0d", 
                  expected_data, item.prdata[7:0], ref_model.get_count()), UVM_MEDIUM)
        
        if (item.prdata[7:0] !== expected_data) begin
          fail_count++;
          `uvm_error("SCB", $sformatf("DATA Mismatch: Expected=0x%02h, Actual=0x%02h",
                    expected_data, item.prdata[7:0]))
        end else begin
          pass_count++;
        end
      end
    end
  endfunction : process_data_access
  
  //--------------------------------------------------------------------------
  // Check Read Data Helper
  //--------------------------------------------------------------------------
  function void check_read_data(string reg_name, bit [31:0] expected, bit [31:0] actual);
    if (actual !== expected) begin
      fail_count++;
      `uvm_error("SCB", $sformatf("%s Read Mismatch: Expected=0x%08h, Actual=0x%08h",
                reg_name, expected, actual))
    end else begin
      pass_count++;
      `uvm_info("SCB", $sformatf("%s Read Match: 0x%08h", reg_name, actual), UVM_HIGH)
    end
  endfunction : check_read_data
  
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

// ==============================================================================
// Base Sequence
// ==============================================================================
class apb_base_sequence extends uvm_sequence #(apb_sequence_item);

    `uvm_object_utils(apb_base_sequence)

    function new(string name = "apb_base_sequence");
        super.new(name);
    endfunction : new

    // Write to a register
    task write_reg(bit [7:0] addr, bit [31:0] data);
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.pwrite = APB_WRITE;
        item.paddr = addr;
        item.pwdata = data;
        finish_item(item);
    endtask : write_reg

    // Read from a register
    task read_reg(bit [7:0] addr, output bit [31:0] data);
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.pwrite = APB_READ;
        item.paddr = addr;
        finish_item(item);
        data = item.prdata;
    endtask : read_reg

    // Push data to FIFO
    task push_data(bit [7:0] data);
        write_reg(DATA_OFFSET, {24'h0, data});
    endtask : push_data

    // Pop data from FIFO
    task pop_data(output bit [7:0] data);
        bit [31:0] rdata;
        read_reg(DATA_OFFSET, rdata);
        data = rdata;
    endtask : pop_data

    // Enable FIFO
    task enable_fifo();
        write_reg(CTRL_OFFSET, 32'h1); // EN=1
    endtask : enable_fifo

    // Disable FIFO
    task disable_fifo();
        write_reg(CTRL_OFFSET, 32'h0); // EN=0
    endtask : disable_fifo

    // Clear FIFO
    task clear_fifo();
        bit [31:0] ctrl_val;
        read_reg(CTRL_OFFSET, ctrl_val);
        write_reg(CTRL_OFFSET, ctrl_val | 32'h2); // Set CLR bit
    endtask : clear_fifo

    task set_drop_on_full(bit enable);
        bit [31:0] ctrl_val;
        read_reg(CTRL_OFFSET, ctrl_val);
        if (enable)
            write_reg(CTRL_OFFSET, ctrl_val | 32'h4); // Set DOF bit
        else
            write_reg(CTRL_OFFSET, ctrl_val & ~32'h4); // Clear DOF bit
    endtask : set_drop_on_full

    // Read STATUS register
    task read_status(output bit empty, output bit full,output bit almost_full, output bit almost_empty, output bit overflow, output bit underflow, output bit [7:0] count);
        bit [31:0] status;
        read_reg(STATUS_OFFSET, status);
        empty = status[0];
        full = status[1];
        almost_full = status[2];
        almost_empty = status[3];
        overflow = status[4];
        underflow = status[5];
        count = status[13:6];
        `uvm_info("SEQ", $sformatf("The FIFO status flags: empty=%0d, full=%0d, almost_full=%0d, almost_empty=%0d, overflow=%0d, underflow=%0d, count=%0d",
         empty, full, almost_full, almost_empty, overflow, underflow, count), UVM_HIGH)
    endtask : read_status
  
endclass : apb_base_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// =============================================================================
// Reset Sequence
// ============================================================================
class reset_sequence extends apb_base_sequence;

    `uvm_object_utils(reset_sequence)

    function new(string name = "reset_sequence");
        super.new(name);
    endfunction : new

    task body();
        apb_sequence_item reset_item;
        bit empty, full, almost_full, almost_empty, overflow, underflow;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Reset Sequence - Testing Reset Behavior", UVM_MEDIUM)

        // First, enable FIFO and push some data
        enable_fifo();
        `uvm_info("SEQ", "FIFO enabled", UVM_MEDIUM)
        
        for (int i = 0; i < 5; i++) begin
            push_data(8'h10 + i);
        end
        `uvm_info("SEQ", "Pushed 5 data items to FIFO", UVM_MEDIUM)

        // Read status before reset
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("Before reset: count=%0d, empty=%0d, full=%0d", count, empty, full), UVM_MEDIUM)

        // Apply hardware reset by driving PRESETn low
        `uvm_info("SEQ", "Asserting hardware reset (PRESETn=0)", UVM_MEDIUM)
        reset_item = apb_sequence_item::type_id::create("reset_item");
        start_item(reset_item);
        reset_item.presetn = 1'b0;  // Assert reset
        finish_item(reset_item);
        
        // Hold reset for a few cycles
        repeat(5) begin
            reset_item = apb_sequence_item::type_id::create("reset_item");
            start_item(reset_item);
            reset_item.presetn = 1'b0;
            finish_item(reset_item);
        end
        `uvm_info("SEQ", "Reset held for 5 cycles", UVM_MEDIUM)

        // Deassert reset
        `uvm_info("SEQ", "Deasserting reset (PRESETn=1)", UVM_MEDIUM)
        reset_item = apb_sequence_item::type_id::create("reset_item");
        start_item(reset_item);
        reset_item.presetn = 1'b1;  // Deassert reset
        finish_item(reset_item);

        // Wait a few cycles for reset to take effect
        repeat(2) begin
            reset_item = apb_sequence_item::type_id::create("reset_item");
            start_item(reset_item);
            reset_item.presetn = 1'b1;
            finish_item(reset_item);
        end

        // Re-enable FIFO after reset
        enable_fifo();
        `uvm_info("SEQ", "FIFO re-enabled after reset", UVM_MEDIUM)

        // Read status after reset - should be empty and count should be 0
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After reset: count=%0d, empty=%0d, full=%0d", count, empty, full), UVM_MEDIUM)

        // Verify reset behavior
        if (count == 0 && empty == 1) begin
            `uvm_info("SEQ", "Reset verification PASSED - FIFO cleared as expected", UVM_MEDIUM)
        end else begin
            `uvm_error("SEQ", $sformatf("Reset verification FAILED - Expected count=0, empty=1, Got count=%0d, empty=%0d", count, empty))
        end

        // Test normal operation after reset
        `uvm_info("SEQ", "Testing normal operation after reset", UVM_MEDIUM)
        push_data(8'hAA);
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After push: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        `uvm_info("SEQ", "Reset Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : reset_sequence


// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// FIFO Enable Sequence
// ==============================================================================
class fifo_enable_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_enable_sequence)

    function new(string name = "fifo_enable_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [7:0] rdata;

        `uvm_info("SEQ", "Starting FIFO Enable Sequence", UVM_MEDIUM)

        // Try to push data when disabled
        disable_fifo();
        push_data(8'hAA);

        // Enable FIFO
        enable_fifo();

        // Push data when enabled
        push_data(8'h55);

        // Pop and verify
        pop_data(rdata);

        `uvm_info("SEQ", "FIFO Enable Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_enable_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// =============================================================================
// Basic Push/Pop Sequence - Simple FIFO operations
// =============================================================================
class basic_push_pop_sequence extends apb_base_sequence;
  
  `uvm_object_utils(basic_push_pop_sequence)
  
  rand int num_items;
  
  constraint num_items_c {
    num_items inside {[1:FIFO_DEPTH]};
  }
  
  function new(string name = "basic_push_pop_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [7:0] push_data_array[$];
    bit [7:0] pop_data_val;
    bit empty, full, overflow, underflow, almost_full, almost_empty;
    bit [7:0] count;
    
    `uvm_info("SEQ", $sformatf("Starting Basic Push/Pop Sequence with %0d items", num_items), UVM_MEDIUM)
    
    // Enable FIFO
    enable_fifo();
    
    // Push data
    for (int i = 0; i < num_items; i++) begin
      bit [7:0] data = $urandom_range(0, 255);
      push_data_array.push_back(data);
      push_data(data);
      `uvm_info("SEQ", $sformatf("Pushed: 0x%02h", data), UVM_HIGH)
    end
    
    // Read status
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("After push: count=%0d, empty=%0d, full=%0d", count, empty, full), UVM_MEDIUM)
    
    // Pop all data
    for (int i = 0; i < num_items; i++) begin
      pop_data(pop_data_val);
      `uvm_info("SEQ", $sformatf("Popped: 0x%02h, Expected: 0x%02h", pop_data_val, push_data_array[i]), UVM_HIGH)
    end
    
    // Verify empty
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("After pop: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Basic Push/Pop Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : basic_push_pop_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Fill FIFO Sequence - Fills FIFO to capacity
// ==============================================================================
class fill_fifo_sequence extends apb_base_sequence;
  
  `uvm_object_utils(fill_fifo_sequence)
  
  function new(string name = "fill_fifo_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit empty, full, overflow, underflow, almost_full, almost_empty;
    bit [7:0] count;
    
    `uvm_info("SEQ", "Starting Fill FIFO Sequence", UVM_MEDIUM)
    
    // Enable FIFO
    enable_fifo();
    
    // Fill FIFO completely
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      push_data(i[7:0]);
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
      `uvm_info("SEQ", $sformatf("Pushed %0d, count=%0d, full=%0d", i, count, full), UVM_HIGH)
    end
    
    // Verify full
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    `uvm_info("SEQ", $sformatf("FIFO should be full: count=%0d, full=%0d", count, full), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Fill FIFO Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : fill_fifo_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Overflow Sequence
// ==============================================================================
class overflow_sequence extends apb_base_sequence;

    `uvm_object_utils(overflow_sequence)

    function new(string name = "overflow_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit empty, full, overflow, underflow, almost_full, almost_empty;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Overflow Sequence", UVM_MEDIUM)

        // ==============================================================================
        // Test with drop_on_full = 0
        // ==============================================================================
        write_reg(CTRL_OFFSET, 32'h1);  // EN=1, DROP_ON_FULL=0

        // Fill FIFO completely
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push_data(i);
        end

        // Try to push one more - should cause overflow
        push_data(8'hFF);

        // Check overflow flag
        read_status(empty,full,almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After overflow attempt: overflow=%0d", overflow), UVM_MEDIUM)

        // Clear FIFO
        clear_fifo();

        // ==============================================================================
        // Test with drop_on_full = 1
        // ==============================================================================
        write_reg(CTRL_OFFSET, 32'h5);  // EN=1, DROP_ON_FULL=1

        // Fill again
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push_data(i);
        end

        // Push extra - should drop silently but set overflow
        push_data(8'hEE);

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After drop: overflow=%0d", overflow), UVM_MEDIUM)

        `uvm_info("SEQ", "Overflow Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : overflow_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Underflow Sequence
// ==============================================================================
class underflow_sequence extends apb_base_sequence;

    `uvm_object_utils(underflow_sequence)

    function new(string name = "underflow_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [7:0] data;
        bit empty, full, overflow, underflow,almost_full, almost_empty;
        bit [7:0] count;
        
        `uvm_info("SEQ", "Starting Underflow Sequence", UVM_MEDIUM)
        
        // Enable FIFO
        enable_fifo();
        
        // Clear to ensure empty
        clear_fifo();
        enable_fifo();
        
        // Verify empty
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("FIFO should be empty: empty=%0d", empty), UVM_MEDIUM)
        
        // Try to pop from empty - should cause underflow
        pop_data(data);
        
        // Check underflow flag
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After underflow attempt: underflow=%0d", underflow), UVM_MEDIUM)
        
        `uvm_info("SEQ", "Underflow Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : underflow_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Threshold Sequence
// ==============================================================================

class threshold_sequence extends apb_base_sequence;

    `uvm_object_utils(threshold_sequence)

    function new(string name = "threshold_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [31:0] status;
        bit almost_full, almost_empty;
        bit overflow, underflow;
        bit full, empty;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Threshold Sequence", UVM_MEDIUM)

        // Enable FIFO
        enable_fifo();

        // Set thresholds: almost_full_th = 10, almost_empty_th = 3
        write_reg(THRESH_OFFSET, {16'h0, 8'd3, 8'd10});

        // Push data and check almost_empty transitions
        for (int i = 0; i < 5; i++) begin
            push_data(i[7:0]);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info("SEQ", $sformatf("Count=%0d, almost_empty=%0d", i+1, almost_empty), UVM_LOW)
        end

        // Continue pushing to check almost_full
        for (int i = 5; i < FIFO_DEPTH; i++) begin
            push_data(i[7:0]);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info("SEQ", $sformatf("Count=%0d, almost_full=%0d", i+1, almost_full), UVM_LOW)
        end

        `uvm_info("SEQ", "Threshold Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : threshold_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// FIFO Clear Sequence
// ==============================================================================
class fifo_clear_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_clear_sequence)

    function new(string name = "fifo_clear_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit empty, full, almost_full, almost_empty, overflow, underflow;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Clear Sequence", UVM_MEDIUM)

        // Enable FIFO
        enable_fifo();

        // Push some data
        for (int i = 0; i < 8; i++) begin
            push_data(i);
        end

        // Verify not empty
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        `uvm_info("SEQ", $sformatf("Before clear: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        // Clear FIFO
        clear_fifo();
        enable_fifo();

        // Verify empty after clear
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After clear: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        `uvm_info("SEQ", "Clear Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_clear_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Random Sequence - Random FIFO operations
// ==============================================================================
class random_sequence extends apb_base_sequence;
  
  `uvm_object_utils(random_sequence)
  
  rand int num_transactions;
  
  constraint num_trans_c {
    num_transactions inside {[50:200]};
  }
  
  function new(string name = "random_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    apb_sequence_item item;
    
    `uvm_info("SEQ", $sformatf("Starting Random Sequence with %0d transactions", num_transactions), UVM_MEDIUM)
    
    // Enable FIFO first
    enable_fifo();
    
    for (int i = 0; i < num_transactions; i++) begin
      item = apb_sequence_item::type_id::create("item");
      start_item(item);
      
      if (!item.randomize()) begin
        `uvm_error("SEQ", "Randomization failed")
      end
      
      finish_item(item);
      
      `uvm_info("SEQ", $sformatf("Transaction %0d: %s", i, item.convert2string()), UVM_HIGH)
    end
    
    `uvm_info("SEQ", "Random Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : random_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Register Access Sequence - Tests all register read/write
// ==============================================================================
class reg_access_sequence extends apb_base_sequence;
  
  `uvm_object_utils(reg_access_sequence)
  
  function new(string name = "reg_access_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [31:0] wdata, rdata;
    
    `uvm_info("SEQ", "Starting Register Access Sequence", UVM_MEDIUM)
    
    // Test CTRL register
    wdata = 32'h5;  // EN=1, DROP_ON_FULL=1
    write_reg(CTRL_OFFSET, wdata);
    read_reg(CTRL_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("CTRL: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    // Test THRESH register
    wdata = {16'h0, 8'd5, 8'd12};  // almost_empty=5, almost_full=12
    write_reg(THRESH_OFFSET, wdata);
    read_reg(THRESH_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("THRESH: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    // Test STATUS register (read-only)
    read_reg(STATUS_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("STATUS: read=0x%08h", rdata), UVM_MEDIUM)
    
    // Test DATA register (push/pop)
    wdata = 32'hAB;
    write_reg(DATA_OFFSET, wdata);
    read_reg(DATA_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("DATA: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Register Access Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : reg_access_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Full Coverage Sequence - Runs all directed sequences
// ==============================================================================
class full_coverage_sequence extends apb_base_sequence;
  
  `uvm_object_utils(full_coverage_sequence)
  
  function new(string name = "full_coverage_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    reset_sequence          reset_seq;
    fifo_enable_sequence    enable_seq;
    basic_push_pop_sequence push_pop_seq;
    fill_fifo_sequence      fill_seq;
    overflow_sequence       overflow_seq;
    underflow_sequence      underflow_seq;
    threshold_sequence      thresh_seq;
    fifo_clear_sequence     clear_seq;
    reg_access_sequence     reg_seq;
    random_sequence         rand_seq;
    
    `uvm_info("SEQ", "Starting Full Coverage Sequence", UVM_MEDIUM)
    
    // Run all directed sequences
    `uvm_do(reset_seq)
    `uvm_do(enable_seq)
    `uvm_do(reg_seq)
    `uvm_do(push_pop_seq)
    `uvm_do(clear_seq)
    `uvm_do(fill_seq)
    `uvm_do(clear_seq)
    `uvm_do(overflow_seq)
    `uvm_do(clear_seq)
    `uvm_do(underflow_seq)
    `uvm_do(clear_seq)
    `uvm_do(thresh_seq)
    `uvm_do(clear_seq)
    `uvm_do_with(rand_seq, {num_transactions == 100;})
    
    `uvm_info("SEQ", "Full Coverage Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : full_coverage_sequence

// ==============================================================================
// Back-to-Back Sequence - Tests rapid transactions
// ==============================================================================
class back_to_back_sequence extends apb_base_sequence;
  
  `uvm_object_utils(back_to_back_sequence)
  
  function new(string name = "back_to_back_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    `uvm_info("SEQ", "Starting Back-to-Back Sequence", UVM_MEDIUM)
    
    enable_fifo();
    
    // Rapid push operations
    for (int i = 0; i < 10; i++) begin
      push_data(i[7:0]);
    end
    
    // Rapid pop operations
    for (int i = 0; i < 10; i++) begin
      bit [7:0] data;
      pop_data(data);
    end
    
    // Interleaved push/pop
    for (int i = 0; i < 10; i++) begin
      bit [7:0] data;
      push_data(i[7:0]);
      pop_data(data);
    end
    
    `uvm_info("SEQ", "Back-to-Back Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : back_to_back_sequence

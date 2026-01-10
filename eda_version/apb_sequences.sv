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
        item.presetn = 1'b1;
        item.pwrite = APB_WRITE;
        item.paddr = addr;
        item.pwdata = data;
        finish_item(item);
        get_response(item);
    endtask : write_reg

    // Read from a register
    task read_reg(bit [7:0] addr, output bit [31:0] data);
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.presetn = 1'b1;
        item.pwrite = APB_READ;
        item.paddr = addr;
        finish_item(item);
        get_response(item);
        data = item.prdata;
    endtask : read_reg


    task reset_fifo();
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.presetn = 1'b0; // Assert reset
        finish_item(item);
        get_response(item);
    endtask : reset_fifo

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

    task read_thresholds(output bit [7:0] almost_empty_th, output bit [7:0] almost_full_th);
        bit [31:0] thresh;
        read_reg(THRESH_OFFSET, thresh);
        almost_empty_th = thresh[7:0];
        almost_full_th = thresh[15:8];
    endtask : read_thresholds

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
class fifo_reset_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_reset_sequence)

    function new(string name = "fifo_reset_sequence");
        super.new(name);
    endfunction : new

    task body();
        apb_sequence_item reset_item;
        bit empty, full, almost_full, almost_empty, overflow, underflow;
        bit [7:0] count;
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Starting Reset Sequence - Testing Reset Behavior", UVM_MEDIUM)

        // Assert reset and hold for 3 cycles (PRESETn=0)
        `uvm_info(get_type_name(), "Asserting hardware reset (PRESETn=0)", UVM_MEDIUM)
        // repeat(3) begin
            reset_fifo();
        // end
        `uvm_info(get_type_name(), "Reset held for 3 cycles", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        // `uvm_info(get_type_name(), $sformatf("After first reset: count=%0d, empty=%0d, full=%0d, overflow=%0d, underflow=%0d", 
        //           count, empty, full, overflow, underflow), UVM_MEDIUM)

        //  push some data to the fifo
        `uvm_info(get_type_name(), "--- Pushing data to FIFO ---", UVM_MEDIUM)
        
        // Enable FIFO first
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        // Push 3 data items
        push_data(8'h10);
        push_data(8'h11);
        push_data(8'h12);

        `uvm_info(get_type_name(), "Pushed 3 data items to FIFO", UVM_MEDIUM)
        
        // Check status after pushing
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        // `uvm_info(get_type_name(), $sformatf("After pushing: count=%0d, empty=%0d, full=%0d", 
        //           count, empty, full), UVM_MEDIUM)

        // Assert reset and hold for 3 cycles (PRESETn=0)
        `uvm_info(get_type_name(), "Asserting hardware reset again (PRESETn=0)", UVM_MEDIUM)
        // repeat(3) begin
            reset_fifo();
        // end
        `uvm_info(get_type_name(), "Reset held for 3 cycles", UVM_MEDIUM)

        // Verify status after second reset - should be same as first reset
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        // `uvm_info(get_type_name(), $sformatf("After second reset: count=%0d, empty=%0d, full=%0d, overflow=%0d, underflow=%0d", 
        //           count, empty, full, overflow, underflow), UVM_MEDIUM)

        // ###############################################################################
        // Test with flipped reset polarity (PRESETn=1 when it should reset)
        `uvm_info(get_type_name(), "--- Testing Flipped Reset Polarity ---", UVM_MEDIUM)
        
        `uvm_info(get_type_name(), "Asserting hardware reset (PRESETn=1)", UVM_MEDIUM)
        // repeat(3) begin
            reset_item = apb_sequence_item::type_id::create("reset_item");
            start_item(reset_item);
            reset_item.presetn = 1'b1;  // flipped
            finish_item(reset_item);
        // end

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After flipped polarity reset attempt: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)


        // Push data to FIFO first
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        reset_item = apb_sequence_item::type_id::create("reset_item");
        start_item(reset_item);
        reset_item.presetn = 1'b0;
        reset_item.pwrite = APB_WRITE;
        reset_item.paddr = DATA_OFFSET;
        reset_item.pwdata = 32'h010;
        finish_item(reset_item);

        reset_item = apb_sequence_item::type_id::create("reset_item");

        start_item(reset_item);
        reset_item.presetn = 1'b0;
        reset_item.pwrite = APB_WRITE;
        reset_item.paddr = DATA_OFFSET;
        reset_item.pwdata = 32'h20;
        finish_item(reset_item);

        reset_item = apb_sequence_item::type_id::create("reset_item");

        start_item(reset_item);
        reset_item.presetn = 1'b0;
        reset_item.pwrite = APB_WRITE;
        reset_item.paddr = DATA_OFFSET;
        reset_item.pwdata = 32'h30;
        finish_item(reset_item);

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        // `uvm_info(get_type_name(), $sformatf("Before flipped polarity test: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)
        
        // Try to "reset" with PRESETn=1 (incorrect - should NOT reset)
        `uvm_info(get_type_name(), "Attempting reset with PRESETn=1 (should have NO effect)", UVM_MEDIUM)
        // repeat(3) begin
            reset_item = apb_sequence_item::type_id::create("reset_item");
            start_item(reset_item);
            reset_item.presetn = 1'b1;  // flipped
            finish_item(reset_item);
        // end
        
        // Verify FIFO was NOT reset (data should still be there)
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After PRESETn=1: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)
        
        `uvm_info(get_type_name(), "Reset Sequence Complete (with polarity test)", UVM_MEDIUM)
        `uvm_info(get_type_name(), "============================================================", UVM_MEDIUM)
    endtask : body

endclass : fifo_reset_sequence


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
        bit empty, full, almost_full, almost_empty, overflow, underflow;

        `uvm_info(get_type_name(), "Starting FIFO Enable Sequence", UVM_MEDIUM)

        // read status flags
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, rdata);

        // Try to push data when disabled
        disable_fifo();
        `uvm_info(get_type_name(), "FIFO disabled", UVM_MEDIUM)

        push_data(8'hAA);
        `uvm_info(get_type_name(), "Attempted to push data while FIFO disabled", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, rdata);

        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)

        // Push data when enabled
        push_data(8'h55);
        `uvm_info(get_type_name(), "Pushed data while FIFO enabled", UVM_MEDIUM)
        // read status 
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, rdata);

        // Pop and verify
        pop_data(rdata);
        `uvm_info(get_type_name(), $sformatf("Popped data while FIFO enabled: 0x%0h", rdata), UVM_MEDIUM)
        `uvm_info(get_type_name(), "FIFO Enable Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_enable_sequence


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

        `uvm_info(get_type_name(), "Starting Clear Sequence", UVM_MEDIUM)

        // Enable FIFO
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)

        // Push some data
        for (int i = 0; i < 8; i++) begin
            push_data(i);
        end
        `uvm_info(get_type_name(), "Pushed 8 data items to FIFO", UVM_MEDIUM)

        // Verify not empty
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Clear FIFO
        clear_fifo();
        `uvm_info(get_type_name(), "Cleared FIFO", UVM_MEDIUM)

        // Verify empty after clear
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);



        // Corner Case: Clear when already empty
        clear_fifo();
        `uvm_info(get_type_name(), "Cleared FIFO when already empty", UVM_MEDIUM)
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        // Corner Case: Clear when full
        // Fill FIFO
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push_data(i);
        end
        `uvm_info(get_type_name(), "Filled FIFO to capacity", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        clear_fifo();
        `uvm_info(get_type_name(), "Cleared FIFO when full", UVM_MEDIUM)
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);


        `uvm_info(get_type_name(), "Clear Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_clear_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// =============================================================================
// Basic Push/Pop Sequence - Comprehensive FIFO operations testing
// =============================================================================
class basic_push_pop_sequence extends apb_base_sequence;
  
  `uvm_object_utils(basic_push_pop_sequence)
    
  function new(string name = "basic_push_pop_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [7:0] pop_data_val;
    bit empty, full, overflow, underflow, almost_full, almost_empty;
    bit [7:0] count;
    int num_items;
    
    `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
    `uvm_info(get_type_name(), "Starting Basic Push/Pop Sequence", UVM_MEDIUM)
    
    // Clear FIFO to start fresh
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

    // Enable FIFO first
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
    
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    
    // Test 1: Push some elements, then pop all - track status after each operation
    `uvm_info(get_type_name(), "--- Test 1: Push Some Elements, then Pop All ---", UVM_MEDIUM)
    
    num_items = $urandom_range(2, FIFO_DEPTH-1); // there is already 2 items 

    // Push random data
    for (int i = 0; i < num_items; i++) begin
      bit [7:0] data = $urandom_range(1, 254);
      push_data(data);
      `uvm_info(get_type_name(), $sformatf("The Element 0x%02h was pushed", data), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), $sformatf("Pushed %0d items total, starting pop", num_items), UVM_MEDIUM)
    
    // Pop all data
    for (int i = 0; i < num_items; i++) begin
      pop_data(pop_data_val);
      `uvm_info(get_type_name(), $sformatf("Popped 0x%02h", pop_data_val), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end

    `uvm_info(get_type_name(), "Test 1 complete ---------------------------------", UVM_MEDIUM)
    
    // Test 2: Interleaved push/pop (push one, pop one immediately)
    `uvm_info(get_type_name(), "--- Test 2: Interleaved Push/Pop ---", UVM_MEDIUM)
    
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)

    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    // Interleaved operations with boundary values
    for (int i = 0; i < 6; i++) begin
      bit [7:0] corners[6] = {8'h00, 8'hFF, 8'h55, 8'hAA, 8'h01, 8'hFE};
      push_data(corners[i]);
      `uvm_info(get_type_name(), $sformatf("Pushed corner data 0x%02h", corners[i]), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
      
      pop_data(pop_data_val);
      `uvm_info(get_type_name(), $sformatf("Popped corner data 0x%02h", pop_data_val), UVM_MEDIUM)
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), "Test 2 complete ---------------------------------", UVM_MEDIUM)
    
    // Test 3: Fill FIFO element by element - track empty, full, count flags
    `uvm_info(get_type_name(), "--- Test 3: Fill FIFO element by element to full ---", UVM_MEDIUM)
    
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
    
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)


    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    // Fill FIFO completely, checking flags at each step
    for (int i = 0; i < FIFO_DEPTH; i++) begin
      bit [7:0] data = $urandom_range(1, 254);
      
      push_data(data);
      read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    end
    
    `uvm_info(get_type_name(), $sformatf("FIFO filled to fifo depth: %d", FIFO_DEPTH), UVM_MEDIUM)
    
    // Test clear resets full flag
    clear_fifo();
    `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
    
    enable_fifo();
    `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
    
    read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
    
    `uvm_info(get_type_name(), "Test 3 complete ---------------------------------------", UVM_MEDIUM)
    
    `uvm_info(get_type_name(), "Basic Push/Pop Sequence Complete", UVM_MEDIUM)
    `uvm_info(get_type_name(), "============================================================", UVM_MEDIUM)
  endtask : body
  
endclass : basic_push_pop_sequence

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

        `uvm_info(get_type_name(), "============================================================", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Starting Overflow Sequence", UVM_MEDIUM)

        // Test 1: Overflow with DROP_ON_FULL = 0 (disabled)
        `uvm_info(get_type_name(), "--- Test 1: Overflow with DROP_ON_FULL Disabled ---", UVM_MEDIUM)
        
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
        
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled with DROP_ON_FULL=0", UVM_MEDIUM)

        // Fill FIFO to full capacity
        `uvm_info(get_type_name(), $sformatf("Filling FIFO to capacity (%0d elements)", FIFO_DEPTH), UVM_MEDIUM)
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push_data(i[7:0]);
        end
        `uvm_info(get_type_name(), "FIFO filled to capacity", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        // Try to push one more element - should cause overflow
        `uvm_info(get_type_name(), "Attempting to push to full FIFO (should overflow)", UVM_MEDIUM)
        push_data(8'hFF);
        `uvm_info(get_type_name(), "Pushed extra element to full FIFO", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);


        // =========================================================================
        // Test sticky flag property - overflow should remain set
        // =========================================================================
        `uvm_info(get_type_name(), "--- Testing Sticky Flag Property ---", UVM_MEDIUM)
        
        // Pop some elements - overflow should still be set
        for (int i = 0; i < 3; i++) begin
            bit [7:0] data;
            pop_data(data);
        end
        `uvm_info(get_type_name(), "Popped 3 elements - overflow flag should remain set", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Push elements - overflow should still be set
        push_data(8'hAA);
        push_data(8'hBB);
        push_data(8'hCC);
        push_data(8'hDD);
        push_data(8'hEE);
        `uvm_info(get_type_name(), "Pushed 5 elements - overflow flag should remain set", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Only clear should reset overflow flag
        `uvm_info(get_type_name(), "Clearing FIFO - should reset overflow flag", UVM_MEDIUM)
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        // Test 2: Overflow with DROP_ON_FULL = 1 (enabled)
        `uvm_info(get_type_name(), "--- Test 2: Overflow with DROP_ON_FULL Enabled ---", UVM_MEDIUM)
        
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

        // enable_fifo();
        // set_drop_on_full(1'b1);
        
        write_reg(CTRL_OFFSET, 32'h5);  // EN=1, DROP_ON_FULL=1
        `uvm_info(get_type_name(), "FIFO enabled with DROP_ON_FULL=1", UVM_MEDIUM)

        // Fill FIFO to full capacity
        `uvm_info(get_type_name(), $sformatf("Filling FIFO to capacity (%0d elements)", FIFO_DEPTH), UVM_MEDIUM)
        for (int i = 0; i < FIFO_DEPTH; i++) begin
            push_data(i[7:0]);
        end
        `uvm_info(get_type_name(), "FIFO filled to capacity", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        // Push extra - should drop silently but set overflow flag
        push_data(8'hEE);
        `uvm_info(get_type_name(), "Attempted to push extra element to full FIFO (should drop error)", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Test sticky flag with DROP_ON_FULL=1
        `uvm_info(get_type_name(), "Testing sticky flag with DROP_ON_FULL=1", UVM_MEDIUM)
        push_data(8'hDD); // Another dropped write
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After another drop: overflow=%0d (should still be 1)", overflow), UVM_MEDIUM)
        
        // Clear to reset overflow
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO re-enabled", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);

        `uvm_info(get_type_name(), "Overflow Sequence Complete", UVM_MEDIUM)
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
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
        bit empty, full, overflow, underflow, almost_full, almost_empty;
        bit [7:0] count;
        
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Starting Underflow Sequence", UVM_MEDIUM)
        
        // Test 1: Underflow from empty FIFO
        `uvm_info(get_type_name(), "--- Test 1: Pop from Empty FIFO ---", UVM_MEDIUM)
        
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
        
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        // Verify FIFO is empty
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Try to pop from empty FIFO - should cause underflow
        `uvm_info(get_type_name(), "Attempting to pop from empty FIFO (should underflow)", UVM_MEDIUM)
        pop_data(data);
        `uvm_info(get_type_name(), $sformatf("Popped data from empty FIFO: 0x%02h", data), UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Test sticky flag property - underflow should remain set
        `uvm_info(get_type_name(), "--- Testing Sticky Flag Property (underflow remains set) ---", UVM_MEDIUM)
        
        // Push some elements - underflow should still be set
        `uvm_info(get_type_name(), "Pushing 3 elements - underflow flag should remain set", UVM_MEDIUM)
        push_data(8'h10);
        push_data(8'h20);
        push_data(8'h30);
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Pop elements - underflow should still be set
        `uvm_info(get_type_name(), "Popping 2 elements - underflow flag should remain set", UVM_MEDIUM)
        pop_data(data);
        pop_data(data);
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Only clear should reset underflow flag
        `uvm_info(get_type_name(), "Clearing FIFO - should reset underflow flag", UVM_MEDIUM)
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)

        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After clear: count=%0d, underflow=%0d (should be 0)", count, underflow), UVM_MEDIUM)
        
        // Test 2: Push elements, pop all + extra to cause underflow
        `uvm_info(get_type_name(), "--- Test 2: Push Some, Pop All + Extra ---", UVM_MEDIUM)
        
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
        
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        // Push 5 elements
        `uvm_info(get_type_name(), "Pushing 5 elements", UVM_MEDIUM)
        for (int i = 0; i < 5; i++) begin
            push_data(8'h40 + i[7:0]);
        end
        `uvm_info(get_type_name(), "5 elements pushed", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Pop all 5 elements
        `uvm_info(get_type_name(), "Popping all 5 elements", UVM_MEDIUM)
        for (int i = 0; i < 5; i++) begin
            pop_data(data);
            `uvm_info(get_type_name(), $sformatf("Popped element %0d: 0x%02h", i+1, data), UVM_MEDIUM)
        end
        `uvm_info(get_type_name(), "All 5 elements popped", UVM_MEDIUM)

        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Pop one more - should cause underflow
        `uvm_info(get_type_name(), "Popping one more element (should underflow)", UVM_MEDIUM)
        pop_data(data);
        `uvm_info(get_type_name(), $sformatf("Popped data from empty FIFO: 0x%02h", data), UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Verify sticky flag persists
        `uvm_info(get_type_name(), "Attempting another pop - underflow should remain set", UVM_MEDIUM)
        pop_data(data);
        `uvm_info(get_type_name(), $sformatf("Popped data from empty FIFO: 0x%02h", data), UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        // Clear to reset
        clear_fifo();
        `uvm_info(get_type_name(), "FIFO cleared", UVM_MEDIUM)
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        `uvm_info(get_type_name(), "Underflow Sequence Complete", UVM_MEDIUM)
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
    endtask : body

endclass : underflow_sequence

// #############################################################################################
// $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$
// #############################################################################################

// ==============================================================================
// Threshold Sequence - Comprehensive threshold testing
// ==============================================================================

class threshold_sequence extends apb_base_sequence;

    `uvm_object_utils(threshold_sequence)

    function new(string name = "threshold_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [31:0] status, thresh_read;
        bit almost_full, almost_empty;
        bit overflow, underflow;
        bit full, empty;
        bit [7:0] count;

        `uvm_info(get_type_name(), "Starting Threshold Sequence", UVM_MEDIUM)

        // Test 1: Set thresholds at start, fill FIFO and track flag transitions
        `uvm_info(get_type_name(), "TEST 1: Initial threshold setting and flag tracking", UVM_MEDIUM)
        
        enable_fifo();
        `uvm_info(get_type_name(), "FIFO enabled", UVM_MEDIUM)
        
        // Set thresholds: almost_full_th = 12, almost_empty_th = 4
        `uvm_info(get_type_name(), "Setting THRESH: almost_full=12, almost_empty=4", UVM_MEDIUM)
        write_reg(THRESH_OFFSET, {16'h0, 8'd4, 8'd12});
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH readback: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
        // Fill FIFO element by element and track almost_empty flag
        `uvm_info(get_type_name(), "Filling FIFO and tracking almost_empty flag (should clear at count > 4)", UVM_MEDIUM)
        for (int i = 0; i < 8; i++) begin
            push_data(8'hA0 + i);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("After push %0d: count=%0d, almost_empty=%0b, almost_full=%0b", 
                      i+1, count, almost_empty, almost_full), UVM_MEDIUM)
        end
        
        // Continue filling and track almost_full flag
        `uvm_info(get_type_name(), "Continuing fill and tracking almost_full flag (should set at count >= 12)", UVM_MEDIUM)
        for (int i = 8; i < FIFO_DEPTH; i++) begin
            push_data(8'hA0 + i);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("After push %0d: count=%0d, almost_empty=%0b, almost_full=%0b, full=%0b", 
                      i+1, count, almost_empty, almost_full, full), UVM_MEDIUM)
        end
        
        // Now pop and track flag transitions
        `uvm_info(get_type_name(), "Popping data and tracking almost_full flag (should clear at count < 12)", UVM_MEDIUM)
        for (int i = 0; i < 6; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_empty=%0b, almost_full=%0b", 
                      i+1, count, almost_empty, almost_full), UVM_MEDIUM)
        end
        
        // Continue popping and track almost_empty flag
        `uvm_info(get_type_name(), "Continuing pop and tracking almost_empty flag (should set at count <= 4)", UVM_MEDIUM)
        for (int i = 6; i < 14; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_empty=%0b, almost_full=%0b, empty=%0b", 
                      i+1, count, almost_empty, almost_full, empty), UVM_MEDIUM)
        end

        //===========================================================================
        // Test 2: Clear FIFO and verify thresholds remain unchanged
        //===========================================================================
        `uvm_info(get_type_name(), "TEST 2: Clear FIFO and verify thresholds persistence", UVM_MEDIUM)
        
        // Push a few elements
        for (int i = 0; i < 5; i++) begin
            push_data(8'hB0 + i);
        end
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("Before clear: count=%0d", count), UVM_MEDIUM)
        
        // Clear FIFO
        clear_fifo();
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After clear: count=%0d, empty=%0b", count, empty), UVM_MEDIUM)
        
        // Read thresholds - should be unchanged
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH after clear: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
        if (thresh_read[15:8] == 8'd4 && thresh_read[7:0] == 8'd12) begin
            `uvm_info(get_type_name(), "✓ Thresholds correctly preserved after clear", UVM_MEDIUM)
        end else begin
            `uvm_info(get_type_name(), "✗ Thresholds changed after clear (unexpected!)", UVM_MEDIUM)
        end

        //===========================================================================
        // Test 3: Update thresholds while FIFO contains elements
        //===========================================================================
        `uvm_info(get_type_name(), "TEST 3: Update thresholds with FIFO partially filled", UVM_MEDIUM)
        
        // Fill FIFO to 8 elements
        for (int i = 0; i < 8; i++) begin
            push_data(8'hC0 + i);
        end
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("FIFO has %0d elements, almost_full=%0b, almost_empty=%0b", 
                  count, almost_full, almost_empty), UVM_MEDIUM)
        
        // Change thresholds: almost_full_th = 6, almost_empty_th = 10
        `uvm_info(get_type_name(), "Updating THRESH to: almost_full=6, almost_empty=10", UVM_MEDIUM)
        write_reg(THRESH_OFFSET, {16'h0, 8'd10, 8'd6});
        read_reg(THRESH_OFFSET, thresh_read);
        `uvm_info(get_type_name(), $sformatf("THRESH updated: 0x%08h (almost_empty=%0d, almost_full=%0d)", 
                  thresh_read, thresh_read[15:8], thresh_read[7:0]), UVM_MEDIUM)
        
        // **BUG CHECK**: Read status immediately - flags should reflect new thresholds instantly
        // Expected: count=8, almost_full should be 1 (8 >= 6), almost_empty should be 1 (8 <= 10)
        `uvm_info(get_type_name(), "═══════════════════════════════════════════════════════", UVM_MEDIUM)
        `uvm_info(get_type_name(), "BUG CHECK: Reading status immediately after threshold change", UVM_MEDIUM)
        `uvm_info(get_type_name(), "═══════════════════════════════════════════════════════", UVM_MEDIUM)
        
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("Immediate read: count=%0d, almost_full=%0b, almost_empty=%0b", 
                  count, almost_full, almost_empty), UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Expected:       count=8,  almost_full=1,  almost_empty=1"), UVM_MEDIUM)
        
        if (almost_full && almost_empty) begin
            `uvm_info(get_type_name(), "✓ PASS: Thresholds updated immediately (count=8: >= 6 for almost_full, <= 10 for almost_empty)", UVM_MEDIUM)
        end else begin
            `uvm_info(get_type_name(), "✗ FAIL: Threshold flags NOT immediately effective!", UVM_MEDIUM)
            `uvm_info(get_type_name(), "        This reveals a TIMING BUG in threshold update logic", UVM_MEDIUM)
            
            // Wait one more clock and read again to see if flags catch up
            `uvm_info(get_type_name(), "        Reading again after 1 clock cycle delay...", UVM_MEDIUM)
            #10; // Wait one clock
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("Delayed read:   count=%0d, almost_full=%0b, almost_empty=%0b", 
                      count, almost_full, almost_empty), UVM_MEDIUM)
            if (almost_full && almost_empty) begin
                `uvm_info(get_type_name(), "        Flags updated after delay - confirms SYNCHRONIZATION BUG", UVM_MEDIUM)
            end
        end
        `uvm_info(get_type_name(), "═══════════════════════════════════════════════════════", UVM_MEDIUM)
        
        // Push 2 more to exceed almost_empty threshold
        `uvm_info(get_type_name(), "Pushing 2 more elements (count should exceed almost_empty threshold)", UVM_MEDIUM)
        for (int i = 0; i < 2; i++) begin
            push_data(8'hD0 + i);
        end
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info(get_type_name(), $sformatf("After 2 more pushes: count=%0d, almost_full=%0b, almost_empty=%0b (expect 0)", 
                  count, almost_full, almost_empty), UVM_MEDIUM)
        
        // Pop to test threshold behavior
        `uvm_info(get_type_name(), "Popping elements to test threshold crossings", UVM_MEDIUM)
        for (int i = 0; i < 6; i++) begin
            pop_data(status);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info(get_type_name(), $sformatf("After pop %0d: count=%0d, almost_full=%0b, almost_empty=%0b", 
                      i+1, count, almost_full, almost_empty), UVM_MEDIUM)
        end

        // Clean up
        clear_fifo();
        
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Threshold Sequence Complete", UVM_MEDIUM)
        `uvm_info("SEQ", "============================================================", UVM_MEDIUM)
    endtask : body

endclass : threshold_sequence

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
    fifo_reset_sequence          reset_seq;
    fifo_enable_sequence    enable_seq;
    basic_push_pop_sequence push_pop_seq;
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

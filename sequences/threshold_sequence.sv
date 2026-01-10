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
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
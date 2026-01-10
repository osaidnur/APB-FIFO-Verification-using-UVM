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
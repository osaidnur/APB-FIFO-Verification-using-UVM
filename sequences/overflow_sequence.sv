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

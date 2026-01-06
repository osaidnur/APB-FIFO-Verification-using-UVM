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

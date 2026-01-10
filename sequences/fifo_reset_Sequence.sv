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
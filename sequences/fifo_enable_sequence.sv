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
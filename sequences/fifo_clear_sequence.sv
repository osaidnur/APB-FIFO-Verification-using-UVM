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
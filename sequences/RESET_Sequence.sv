class reset_sequence extends apb_base_sequence;

    `uvm_object_utils(reset_sequence)

    function new(string name = "reset_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit empty, full, almost_full, almost_empty, overflow, underflow;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Reset Sequence", UVM_MEDIUM)

        // Enable FIFO and push some data
        enable_fifo();
        
        for (int i = 0; i < 5; i++) begin
            push_data(i);
        end

        // Read status before reset
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("Before reset: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        // Clear FIFO (acts as reset)
        clear_fifo();

        // Re-enable after clear
        enable_fifo();

        // Read status after reset
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After reset: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        `uvm_info("SEQ", "Reset Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : reset_sequence

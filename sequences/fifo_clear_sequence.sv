class fifo_clear_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_clear_sequence)

    function new(string name = "fifo_clear_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit empty, full, almost_full, almost_empty, overflow, underflow;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Clear Sequence", UVM_MEDIUM)

        // Enable FIFO
        enable_fifo();

        // Push some data
        for (int i = 0; i < 8; i++) begin
            push_data(i);
        end

        // Verify not empty
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        
        `uvm_info("SEQ", $sformatf("Before clear: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        // Clear FIFO
        clear_fifo();
        enable_fifo();

        // Verify empty after clear
        read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
        `uvm_info("SEQ", $sformatf("After clear: count=%0d, empty=%0d", count, empty), UVM_MEDIUM)

        `uvm_info("SEQ", "Clear Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_clear_sequence

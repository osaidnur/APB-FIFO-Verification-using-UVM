class fifo_enable_sequence extends apb_base_sequence;

    `uvm_object_utils(fifo_enable_sequence)

    function new(string name = "fifo_enable_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [7:0] rdata;

        `uvm_info("SEQ", "Starting FIFO Enable Sequence", UVM_MEDIUM)

        // Try to push data when disabled
        disable_fifo();
        push_data(8'hAA);

        // Enable FIFO
        enable_fifo();

        // Push data when enabled
        push_data(8'h55);

        // Pop and verify
        pop_data(rdata);

        `uvm_info("SEQ", "FIFO Enable Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : fifo_enable_sequence

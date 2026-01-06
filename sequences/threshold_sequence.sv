class threshold_sequence extends apb_base_sequence;

    `uvm_object_utils(threshold_sequence)

    function new(string name = "threshold_sequence");
        super.new(name);
    endfunction : new

    task body();
        bit [31:0] status;
        bit almost_full, almost_empty;
        bit overflow, underflow;
        bit full, empty;
        bit [7:0] count;

        `uvm_info("SEQ", "Starting Threshold Sequence", UVM_MEDIUM)

        // Enable FIFO
        enable_fifo();

        // Set thresholds: almost_full_th = 10, almost_empty_th = 3
        write_reg(THRESH_OFFSET, {16'h0, 8'd3, 8'd10});

        // Push data and check almost_empty transitions
        for (int i = 0; i < 5; i++) begin
            push_data(i[7:0]);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info("SEQ", $sformatf("Count=%0d, almost_empty=%0d", i+1, almost_empty), UVM_LOW)
        end

        // Continue pushing to check almost_full
        for (int i = 5; i < FIFO_DEPTH; i++) begin
            push_data(i[7:0]);
            read_status(empty, full, almost_full, almost_empty, overflow, underflow, count);
            `uvm_info("SEQ", $sformatf("Count=%0d, almost_full=%0d", i+1, almost_full), UVM_LOW)
        end

        `uvm_info("SEQ", "Threshold Sequence Complete", UVM_MEDIUM)
    endtask : body

endclass : threshold_sequence

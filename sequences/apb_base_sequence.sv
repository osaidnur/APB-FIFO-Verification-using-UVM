class apb_base_sequence extends uvm_sequence #(apb_sequence_item);

    `uvm_object_utils(apb_base_sequence)

    function new(string name = "apb_base_sequence");
        super.new(name);
    endfunction : new

    // Write to a register
    task write_reg(bit [7:0] addr, bit [31:0] data);
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.pwrite = APB_WRITE;
        item.paddr = addr;
        item.pwdata = data;
        finish_item(item);
    endtask : write_reg

    // Read from a register
    task read_reg(bit [7:0] addr, output bit [31:0] data);
        apb_sequence_item item = apb_sequence_item::type_id::create("item");
        start_item(item);
        item.pwrite = APB_READ;
        item.paddr = addr;
        finish_item(item);
        data = item.prdata;
    endtask : read_reg

    // Push data to FIFO
    task push_data(bit [7:0] data);
        write_reg(DATA_OFFSET, {24'h0, data});
    endtask : push_data

    // Pop data from FIFO
    task pop_data(output bit [7:0] data);
        bit [31:0] rdata;
        read_reg(DATA_OFFSET, rdata);
        data = rdata;
    endtask : pop_data

    // Enable FIFO
    task enable_fifo();
        write_reg(CTRL_OFFSET, 32'h1); // EN=1
    endtask : enable_fifo

    // Disable FIFO
    task disable_fifo();
        write_reg(CTRL_OFFSET, 32'h0); // EN=0
    endtask : disable_fifo

    // Clear FIFO
    task clear_fifo();
        bit [31:0] ctrl_val;
        read_reg(CTRL_OFFSET, ctrl_val);
        write_reg(CTRL_OFFSET, ctrl_val | 32'h2); // Set CLR bit
    endtask : clear_fifo

    task set_drop_on_full(bit enable);
        bit [31:0] ctrl_val;
        read_reg(CTRL_OFFSET, ctrl_val);
        if (enable)
            write_reg(CTRL_OFFSET, ctrl_val | 32'h4); // Set DOF bit
        else
            write_reg(CTRL_OFFSET, ctrl_val & ~32'h4); // Clear DOF bit
    endtask : set_drop_on_full

    // Read STATUS register
    task read_status(output bit empty, output bit full,output bit almost_full, output bit almost_empty, output bit overflow, output bit underflow, output bit [7:0] count);
        bit [31:0] status;
        read_reg(STATUS_OFFSET, status);
        empty = status[0];
        full = status[1];
        almost_full = status[2];
        almost_empty = status[3];
        overflow = status[4];
        underflow = status[5];
        count = status[13:6];
        `uvm_info("SEQ", $sformatf("The FIFO status flags: empty=%0d, full=%0d, almost_full=%0d, almost_empty=%0d, overflow=%0d, underflow=%0d, count=%0d",
         empty, full, almost_full, almost_empty, overflow, underflow, count), UVM_HIGH)
    endtask : read_status
  
endclass : apb_base_sequence

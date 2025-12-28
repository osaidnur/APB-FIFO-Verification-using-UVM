//------------------------------------------------------------------------------
// Base Sequence - Foundation for all sequences
//------------------------------------------------------------------------------
class apb_base_sequence extends uvm_sequence #(apb_sequence_item);
  
  `uvm_object_utils(apb_base_sequence)
  
  function new(string name = "apb_base_sequence");
    super.new(name);
  endfunction : new
  
  // Helper task: Write to a register
  task write_reg(bit [7:0] addr, bit [31:0] data);
    apb_sequence_item item = apb_sequence_item::type_id::create("item");
    start_item(item);
    item.pwrite = APB_WRITE;
    item.paddr = addr;
    item.pwdata = data;
    finish_item(item);
  endtask : write_reg
  
  // Helper task: Read from a register
  task read_reg(bit [7:0] addr, output bit [31:0] data);
    apb_sequence_item item = apb_sequence_item::type_id::create("item");
    start_item(item);
    item.pwrite = APB_READ;
    item.paddr = addr;
    finish_item(item);
    data = item.prdata;
  endtask : read_reg
  
  // Helper task: Push data to FIFO
  task push_data(bit [7:0] data);
    write_reg(DATA_OFFSET, {24'h0, data});
  endtask : push_data
  
  // Helper task: Pop data from FIFO
  task pop_data(output bit [7:0] data);
    bit [31:0] rdata;
    read_reg(DATA_OFFSET, rdata);
    data = rdata[7:0];
  endtask : pop_data
  
  // Helper task: Enable FIFO
  task enable_fifo();
    write_reg(CTRL_OFFSET, 32'h1);  // EN=1
  endtask : enable_fifo
  
  // Helper task: Disable FIFO
  task disable_fifo();
    write_reg(CTRL_OFFSET, 32'h0);  // EN=0
  endtask : disable_fifo
  
  // Helper task: Clear FIFO
  task clear_fifo();
    bit [31:0] ctrl_val;
    read_reg(CTRL_OFFSET, ctrl_val);
    write_reg(CTRL_OFFSET, ctrl_val | 32'h2);  // Set CLR bit
  endtask : clear_fifo
  
  // Helper task: Read STATUS register
  task read_status(output bit empty, output bit full, output bit overflow, output bit underflow, output bit [7:0] count);
    bit [31:0] status;
    read_reg(STATUS_OFFSET, status);
    empty     = status[0];
    full      = status[1];
    overflow  = status[4];
    underflow = status[5];
    count     = status[13:6];
  endtask : read_status
  
endclass : apb_base_sequence

//------------------------------------------------------------------------------
// Register Access Sequence - Tests all register read/write
//------------------------------------------------------------------------------
class reg_access_sequence extends apb_base_sequence;
  
  `uvm_object_utils(reg_access_sequence)
  
  function new(string name = "reg_access_sequence");
    super.new(name);
  endfunction : new
  
  task body();
    bit [31:0] wdata, rdata;
    
    `uvm_info("SEQ", "Starting Register Access Sequence", UVM_MEDIUM)
    
    // Test CTRL register
    wdata = 32'h5;  // EN=1, DROP_ON_FULL=1
    write_reg(CTRL_OFFSET, wdata);
    read_reg(CTRL_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("CTRL: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    // Test THRESH register
    wdata = {16'h0, 8'd5, 8'd12};  // almost_empty=5, almost_full=12
    write_reg(THRESH_OFFSET, wdata);
    read_reg(THRESH_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("THRESH: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    // Test STATUS register (read-only)
    read_reg(STATUS_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("STATUS: read=0x%08h", rdata), UVM_MEDIUM)
    
    // Test DATA register (push/pop)
    wdata = 32'hAB;
    write_reg(DATA_OFFSET, wdata);
    read_reg(DATA_OFFSET, rdata);
    `uvm_info("SEQ", $sformatf("DATA: wrote=0x%08h, read=0x%08h", wdata, rdata), UVM_MEDIUM)
    
    `uvm_info("SEQ", "Register Access Sequence Complete", UVM_MEDIUM)
  endtask : body
  
endclass : reg_access_sequence

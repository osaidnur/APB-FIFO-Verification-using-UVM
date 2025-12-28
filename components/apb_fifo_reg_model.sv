//------------------------------------------------------------------------------
// APB FIFO Register Model (UVM_REG)
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
// CTRL Register (0x00)
// Bit[0]: EN - FIFO Enable
// Bit[1]: CLR - Clear FIFO (self-clearing)
// Bit[2]: DROP_ON_FULL - Drop data on full (vs error)
//------------------------------------------------------------------------------
class ctrl_reg extends uvm_reg;
  
  `uvm_object_utils(ctrl_reg)
  
  rand uvm_reg_field en;
  rand uvm_reg_field clr;
  rand uvm_reg_field drop_on_full;
  rand uvm_reg_field reserved;
  
  function new(string name = "ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction : new
  
  virtual function void build();
    en = uvm_reg_field::type_id::create("en");
    en.configure(this, 1, 0, "RW", 0, 1'b0, 1, 1, 0);
    
    clr = uvm_reg_field::type_id::create("clr");
    clr.configure(this, 1, 1, "RW", 0, 1'b0, 1, 1, 0);
    
    drop_on_full = uvm_reg_field::type_id::create("drop_on_full");
    drop_on_full.configure(this, 1, 2, "RW", 0, 1'b0, 1, 1, 0);
    
    reserved = uvm_reg_field::type_id::create("reserved");
    reserved.configure(this, 29, 3, "RO", 0, 29'h0, 1, 0, 0);
  endfunction : build
  
endclass : ctrl_reg

//------------------------------------------------------------------------------
// THRESH Register (0x04)
// Bit[7:0]:  ALMOST_FULL_TH
// Bit[15:8]: ALMOST_EMPTY_TH
//------------------------------------------------------------------------------
class thresh_reg extends uvm_reg;
  
  `uvm_object_utils(thresh_reg)
  
  rand uvm_reg_field almost_full_th;
  rand uvm_reg_field almost_empty_th;
  rand uvm_reg_field reserved;
  
  function new(string name = "thresh_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction : new
  
  virtual function void build();
    almost_full_th = uvm_reg_field::type_id::create("almost_full_th");
    almost_full_th.configure(this, 8, 0, "RW", 0, 8'd15, 1, 1, 0);
    
    almost_empty_th = uvm_reg_field::type_id::create("almost_empty_th");
    almost_empty_th.configure(this, 8, 8, "RW", 0, 8'd1, 1, 1, 0);
    
    reserved = uvm_reg_field::type_id::create("reserved");
    reserved.configure(this, 16, 16, "RO", 0, 16'h0, 1, 0, 0);
  endfunction : build
  
endclass : thresh_reg

//------------------------------------------------------------------------------
// STATUS Register (0x08) - Read Only / Read Clear
// Bit[0]: EMPTY
// Bit[1]: FULL
// Bit[2]: ALMOST_FULL
// Bit[3]: ALMOST_EMPTY
// Bit[4]: OVERFLOW (sticky, RC)
// Bit[5]: UNDERFLOW (sticky, RC)
// Bit[13:6]: COUNT
//------------------------------------------------------------------------------
class status_reg extends uvm_reg;
  
  `uvm_object_utils(status_reg)
  
  rand uvm_reg_field empty;
  rand uvm_reg_field full;
  rand uvm_reg_field almost_full;
  rand uvm_reg_field almost_empty;
  rand uvm_reg_field overflow;
  rand uvm_reg_field underflow;
  rand uvm_reg_field count;
  rand uvm_reg_field reserved;
  
  function new(string name = "status_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction : new
  
  virtual function void build();
    empty = uvm_reg_field::type_id::create("empty");
    empty.configure(this, 1, 0, "RO", 1, 1'b1, 1, 0, 0);
    
    full = uvm_reg_field::type_id::create("full");
    full.configure(this, 1, 1, "RO", 1, 1'b0, 1, 0, 0);
    
    almost_full = uvm_reg_field::type_id::create("almost_full");
    almost_full.configure(this, 1, 2, "RO", 1, 1'b0, 1, 0, 0);
    
    almost_empty = uvm_reg_field::type_id::create("almost_empty");
    almost_empty.configure(this, 1, 3, "RO", 1, 1'b1, 1, 0, 0);
    
    overflow = uvm_reg_field::type_id::create("overflow");
    overflow.configure(this, 1, 4, "W1C", 1, 1'b0, 1, 1, 0);
    
    underflow = uvm_reg_field::type_id::create("underflow");
    underflow.configure(this, 1, 5, "W1C", 1, 1'b0, 1, 1, 0);
    
    count = uvm_reg_field::type_id::create("count");
    count.configure(this, 8, 6, "RO", 1, 8'h0, 1, 0, 0);
    
    reserved = uvm_reg_field::type_id::create("reserved");
    reserved.configure(this, 18, 14, "RO", 0, 18'h0, 1, 0, 0);
  endfunction : build
  
endclass : status_reg

//------------------------------------------------------------------------------
// DATA Register (0x0C)
// Write: Push data to FIFO
// Read: Pop data from FIFO
//------------------------------------------------------------------------------
class data_reg extends uvm_reg;
  
  `uvm_object_utils(data_reg)
  
  rand uvm_reg_field data;
  rand uvm_reg_field reserved;
  
  function new(string name = "data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction : new
  
  virtual function void build();
    data = uvm_reg_field::type_id::create("data");
    data.configure(this, 8, 0, "RW", 1, 8'h0, 1, 1, 0);
    
    reserved = uvm_reg_field::type_id::create("reserved");
    reserved.configure(this, 24, 8, "RO", 0, 24'h0, 1, 0, 0);
  endfunction : build
  
endclass : data_reg

//------------------------------------------------------------------------------
// APB FIFO Register Block
//------------------------------------------------------------------------------
class apb_fifo_reg_block extends uvm_reg_block;
  
  `uvm_object_utils(apb_fifo_reg_block)
  
  rand ctrl_reg   CTRL;
  rand thresh_reg THRESH;
  rand status_reg STATUS;
  rand data_reg   DATA;
  
  uvm_reg_map reg_map;
  
  function new(string name = "apb_fifo_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction : new
  
  virtual function void build();
    // Create registers
    CTRL = ctrl_reg::type_id::create("CTRL");
    CTRL.configure(this, null, "");
    CTRL.build();
    
    THRESH = thresh_reg::type_id::create("THRESH");
    THRESH.configure(this, null, "");
    THRESH.build();
    
    STATUS = status_reg::type_id::create("STATUS");
    STATUS.configure(this, null, "");
    STATUS.build();
    
    DATA = data_reg::type_id::create("DATA");
    DATA.configure(this, null, "");
    DATA.build();
    
    // Create address map
    reg_map = create_map("reg_map", 'h0, 4, UVM_LITTLE_ENDIAN, 1);
    
    // Add registers to map
    reg_map.add_reg(CTRL,   'h00, "RW");
    reg_map.add_reg(THRESH, 'h04, "RW");
    reg_map.add_reg(STATUS, 'h08, "RO");
    reg_map.add_reg(DATA,   'h0C, "RW");
    
    lock_model();
  endfunction : build
  
endclass : apb_fifo_reg_block

//------------------------------------------------------------------------------
// APB Register Adapter - Converts between register model and APB transactions
//------------------------------------------------------------------------------
class apb_reg_adapter extends uvm_reg_adapter;
  
  `uvm_object_utils(apb_reg_adapter)
  
  function new(string name = "apb_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 1;
  endfunction : new
  
  // Convert register transaction to APB transaction
  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_sequence_item apb_item = apb_sequence_item::type_id::create("apb_item");
    
    apb_item.addr = rw.addr[7:0];
    apb_item.operation = (rw.kind == UVM_WRITE) ? APB_WRITE : APB_READ;
    apb_item.wdata = rw.data;
    
    return apb_item;
  endfunction : reg2bus
  
  // Convert APB transaction to register transaction
  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_sequence_item apb_item;
    
    if (!$cast(apb_item, bus_item)) begin
      `uvm_fatal("APB_ADAPTER", "Failed to cast bus_item to apb_sequence_item")
    end
    
    rw.addr   = apb_item.addr;
    rw.kind   = (apb_item.operation == APB_WRITE) ? UVM_WRITE : UVM_READ;
    rw.data   = (apb_item.operation == APB_READ) ? apb_item.rdata : apb_item.wdata;
    rw.status = apb_item.slverr ? UVM_NOT_OK : UVM_IS_OK;
  endfunction : bus2reg
  
endclass : apb_reg_adapter

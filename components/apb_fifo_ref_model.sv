//------------------------------------------------------------------------------
// APB FIFO Reference Model - High-level behavioral model
//------------------------------------------------------------------------------
// This reference model implements a clean, high-level view of the FIFO behavior
// without coupling to UVM infrastructure. It can be used by the scoreboard
// for comparison against DUT behavior.
//------------------------------------------------------------------------------

class apb_fifo_ref_model;
  
  //--------------------------------------------------------------------------
  // Parameters (mirroring DUT configuration)
  //--------------------------------------------------------------------------
  localparam int DEPTH = FIFO_DEPTH;  // From package
  localparam int WIDTH = FIFO_WIDTH;  // From package
  
  //--------------------------------------------------------------------------
  // FIFO Storage
  //--------------------------------------------------------------------------
  protected bit [WIDTH-1:0] fifo_mem[$];
  
  //--------------------------------------------------------------------------
  // Control Registers
  //--------------------------------------------------------------------------
  protected bit        en;              // FIFO enable
  protected bit        clr;             // Clear (self-clearing)
  protected bit        drop_on_full;    // Drop new data when full
  protected bit [7:0]  almost_full_th;  // Almost full threshold
  protected bit [7:0]  almost_empty_th; // Almost empty threshold
  
  //--------------------------------------------------------------------------
  // Status Flags
  //--------------------------------------------------------------------------
  protected bit        empty_flag;
  protected bit        full_flag;
  protected bit        almost_full_flag;
  protected bit        almost_empty_flag;
  protected bit        overflow_flag;   // Sticky
  protected bit        underflow_flag;  // Sticky
  
  //--------------------------------------------------------------------------
  // Internal State
  //--------------------------------------------------------------------------
  protected int        count;
  
  //--------------------------------------------------------------------------
  // Constructor
  //--------------------------------------------------------------------------
  function new();
    reset();
  endfunction : new
  
  //--------------------------------------------------------------------------
  // Reset - Initialize to power-on state
  //--------------------------------------------------------------------------
  function void reset();
    fifo_mem.delete();
    count = 0;
    
    // Control registers default values
    en              = 1'b0;
    clr             = 1'b0;
    drop_on_full    = 1'b0;
    almost_full_th  = DEPTH - 1;  // Default: 15 for depth=16
    almost_empty_th = 8'd1;       // Default: 1
    
    // Status flags
    empty_flag       = 1'b1;
    full_flag        = 1'b0;
    almost_full_flag = 1'b0;
    almost_empty_flag= 1'b1;
    overflow_flag    = 1'b0;
    underflow_flag   = 1'b0;
  endfunction : reset
  
  //--------------------------------------------------------------------------
  // Clear FIFO - Called when CLR bit is set
  //--------------------------------------------------------------------------
  function void clear();
    fifo_mem.delete();
    count = 0;
    overflow_flag  = 1'b0;
    underflow_flag = 1'b0;
    update_flags();
  endfunction : clear
  
  //--------------------------------------------------------------------------
  // Update Status Flags
  //--------------------------------------------------------------------------
  protected function void update_flags();
    count = fifo_mem.size();
    empty_flag        = (count == 0);
    full_flag         = (count >= DEPTH);
    almost_full_flag  = (count > almost_full_th);
    almost_empty_flag = (count <= almost_empty_th);
  endfunction : update_flags
  
  //--------------------------------------------------------------------------
  // PUSH Operation - Write data to FIFO
  //--------------------------------------------------------------------------
  // Returns: 1 = success, 0 = failed (disabled/overflow)
  //--------------------------------------------------------------------------
  function bit push(bit [WIDTH-1:0] data);
    if (!en) begin
      return 0;  // FIFO disabled
    end
    
    if (full_flag) begin
      overflow_flag = 1'b1;
      return 0;  // Overflow condition
    end
    
    fifo_mem.push_back(data);
    update_flags();
    return 1;
  endfunction : push
  
  //--------------------------------------------------------------------------
  // POP Operation - Read data from FIFO
  //--------------------------------------------------------------------------
  // Returns: popped data (or 0 if underflow/disabled)
  //--------------------------------------------------------------------------
  function bit [WIDTH-1:0] pop(output bit success);
    bit [WIDTH-1:0] data;
    
    if (!en) begin
      success = 0;
      return 0;  // FIFO disabled
    end
    
    if (empty_flag) begin
      underflow_flag = 1'b1;
      success = 0;
      return 0;  // Underflow condition
    end
    
    data = fifo_mem.pop_front();
    update_flags();
    success = 1;
    return data;
  endfunction : pop
  
  //--------------------------------------------------------------------------
  // Peek - Read front data without removing
  //--------------------------------------------------------------------------
  function bit [WIDTH-1:0] peek();
    if (fifo_mem.size() > 0)
      return fifo_mem[0];
    else
      return 0;
  endfunction : peek
  
  //--------------------------------------------------------------------------
  // Register Write Operations
  //--------------------------------------------------------------------------
  
  // Write CTRL register
  function void write_ctrl(bit [31:0] data);
    en           = data[0];
    clr          = data[1];
    drop_on_full = data[2];
    
    if (clr) begin
      clear();
      clr = 1'b0;  // Self-clearing
    end
  endfunction : write_ctrl
  
  // Write THRESH register
  function void write_thresh(bit [31:0] data);
    almost_full_th  = data[7:0];
    almost_empty_th = data[15:8];
    update_flags();
  endfunction : write_thresh
  
  //--------------------------------------------------------------------------
  // Register Read Operations
  //--------------------------------------------------------------------------
  
  // Read CTRL register
  function bit [31:0] read_ctrl();
    return {29'h0, drop_on_full, 1'b0, en};  // CLR always reads 0
  endfunction : read_ctrl
  
  // Read THRESH register
  function bit [31:0] read_thresh();
    return {16'h0, almost_empty_th, almost_full_th};
  endfunction : read_thresh
  
  // Read STATUS register
  function bit [31:0] read_status();
    update_flags();
    return {18'h0, count[7:0], underflow_flag, overflow_flag, 
            almost_empty_flag, almost_full_flag, full_flag, empty_flag};
  endfunction : read_status
  
  // Read DATA register (peek, doesn't pop)
  function bit [31:0] read_data_reg();
    return {24'h0, peek()};
  endfunction : read_data_reg
  
  //--------------------------------------------------------------------------
  // Status Accessors (for scoreboard comparison)
  //--------------------------------------------------------------------------
  function bit is_empty();
    return empty_flag;
  endfunction : is_empty
  
  function bit is_full();
    return full_flag;
  endfunction : is_full
  
  function bit is_almost_full();
    return almost_full_flag;
  endfunction : is_almost_full
  
  function bit is_almost_empty();
    return almost_empty_flag;
  endfunction : is_almost_empty
  
  function bit has_overflow();
    return overflow_flag;
  endfunction : has_overflow
  
  function bit has_underflow();
    return underflow_flag;
  endfunction : has_underflow
  
  function int get_count();
    return count;
  endfunction : get_count
  
  function bit is_enabled();
    return en;
  endfunction : is_enabled
  
  function bit get_drop_on_full();
    return drop_on_full;
  endfunction : get_drop_on_full
  
  function bit [7:0] get_almost_full_th();
    return almost_full_th;
  endfunction : get_almost_full_th
  
  function bit [7:0] get_almost_empty_th();
    return almost_empty_th;
  endfunction : get_almost_empty_th
  
  //--------------------------------------------------------------------------
  // Clear sticky flags (DUT clears on STATUS read - this is a bug in DUT)
  //--------------------------------------------------------------------------
  function void clear_sticky_flags();
    overflow_flag  = 1'b0;
    underflow_flag = 1'b0;
  endfunction : clear_sticky_flags
  
  //--------------------------------------------------------------------------
  // Debug: Get FIFO contents as string
  //--------------------------------------------------------------------------
  function string get_debug_string();
    string s;
    s = $sformatf("RefModel State: EN=%0d, Count=%0d/%0d, Empty=%0d, Full=%0d, AF=%0d, AE=%0d, OVF=%0d, UNF=%0d",
                  en, count, DEPTH, empty_flag, full_flag, 
                  almost_full_flag, almost_empty_flag, overflow_flag, underflow_flag);
    return s;
  endfunction : get_debug_string

endclass : apb_fifo_ref_model

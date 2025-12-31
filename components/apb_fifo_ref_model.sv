class apb_fifo_ref_model;

    // local parameters
    localparam int DEPTH = FIFO_DEPTH;
    localparam int WIDTH = FIFO_WIDTH;

    // Virtual FIFO memory
    protected bit [WIDTH-1:0] fifo_mem[$];

    // Control Registers
    protected bit en; // fifo enable
    protected bit clr; // clear
    protected bit drop_on_full; // drop new data when full
    protected bit [7:0] almost_full_th;  // almost full threshold
    protected bit [7:0] almost_empty_th; // almost empty threshold

    // Status Flags
    protected bit empty_flag;
    protected bit full_flag;
    protected bit almost_full_flag;
    protected bit almost_empty_flag;
    protected bit overflow_flag; // sticky flag
    protected bit underflow_flag; // sticky flag
    protected int count;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new();
        reset();
    endfunction : new


    // ################################################################################
    // Basic Operations
    // ################################################################################

    //------------------------------------------------------
    // Reset
    //------------------------------------------------------
    function void reset();
        fifo_mem.delete();
        count = 0;
        
        // Control register
        en = 1'b0;
        clr = 1'b0;
        drop_on_full = 1'b0;

        // Thresholds
        almost_full_th = DEPTH - 1; // default = 15 when DEPTH=16
        almost_empty_th = 8'd1; // default = 1
        
        // Status flags
        empty_flag = 1'b1;
        full_flag = 1'b0;
        almost_full_flag = 1'b0;
        almost_empty_flag= 1'b1;
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;
    endfunction : reset

    //------------------------------------------------------
    // Clear FIFO - when clr flag is set 
    //------------------------------------------------------
    function void clear_fifo();
        fifo_mem.delete();
        count = 0;
        overflow_flag = 1'b0; // only cleared here
        underflow_flag = 1'b0; // only cleared here
        update_flags();
    endfunction : clear_fifo

    //------------------------------------------------------
    // Update Flags
    //------------------------------------------------------
    protected function void update_flags();
        count = fifo_mem.size();
        empty_flag = (count == 0);
        full_flag = (count >= DEPTH);
        almost_full_flag = (count >= almost_full_th);
        almost_empty_flag = (count <= almost_empty_th);
    endfunction : update_flags


    // #################################################################################
    // FIFO Operations
    // #################################################################################

    //------------------------------------------------------
    // Push Operation - 1:success, 0:failed 
    //------------------------------------------------------
    function bit push(bit [WIDTH-1:0] data);
        if (!en) begin
            return 0; // FIFO is disabled
        end
        
        if (full_flag) begin
            overflow_flag = 1'b1;
            if (drop_on_full) begin
                return 1; // overflow without error
            end
            return 0; // overflow + error
        end
        
        fifo_mem.push_back(data);
        update_flags();
        return 1;
    endfunction : push

    //------------------------------------------------------
    // Pop Operation - return data + success=1 when the pop
    // is successful, success=0 otherwise(underflow or disabled)
    //------------------------------------------------------
    function bit [WIDTH-1:0] pop(output bit success);
        // note: the success here handles the edge case when the popped data is zero
        bit [WIDTH-1:0] data;
        
        if (!en) begin
            success = 0;
            return 0; // FIFO is disabled
        end
        
        if (empty_flag) begin
            underflow_flag = 1'b1;
            success = 0;
            return 0; // Underflow condition
        end
        
        data = fifo_mem.pop_front();
        update_flags();
        success = 1;
        return data;
    endfunction : pop


    // #################################################################################
    // Register Write Operations
    // #################################################################################

    //------------------------------------------------------
    // Write CTRL register
    //------------------------------------------------------
    function void write_ctrl(bit [31:0] data);
        en = data[0];
        clr = data[1];
        drop_on_full = data[2];
        
        if (clr) begin
            clear_fifo();
            clr = 1'b0; // return to 0 after clearing
        end
    endfunction : write_ctrl

    //------------------------------------------------------
    // Write THRESH register
    //------------------------------------------------------
    function void write_thresh(bit [31:0] data);
        almost_full_th  = data[7:0];
        almost_empty_th = data[15:8];
        update_flags();
    endfunction : write_thresh


    // #################################################################################
    // Register Read Operations
    // #################################################################################

    //------------------------------------------------------
    // Read CTRL register
    //------------------------------------------------------
    function bit [31:0] read_ctrl();
        return {29'h0, drop_on_full, clr, en};
    endfunction : read_ctrl

    //------------------------------------------------------
    // Read THRESH register
    //------------------------------------------------------
    function bit [31:0] read_thresh();
        return {16'h0, almost_empty_th, almost_full_th};
    endfunction : read_thresh

    //------------------------------------------------------
    // Read STATUS register
    //------------------------------------------------------
    function bit [31:0] read_status();
        update_flags();
        return {18'h0, count[7:0], underflow_flag, overflow_flag, almost_empty_flag, almost_full_flag, full_flag, empty_flag};
    endfunction : read_status


    // #################################################################################
    // Getters Functions
    // #################################################################################

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
    // Debug: Get FIFO contents as string
    //--------------------------------------------------------------------------
    function string print_status();
    string s;
    s = $sformatf("RefModel State: EN=%0d, Count=%0d/%0d, Empty=%0d, Full=%0d, AF=%0d, AE=%0d, OVF=%0d, UNF=%0d",
                    en, count, DEPTH, empty_flag, full_flag, 
                    almost_full_flag, almost_empty_flag, overflow_flag, underflow_flag);
    return s;
    endfunction : print_status

endclass : apb_fifo_ref_model

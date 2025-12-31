class apb_sequence_item extends uvm_sequence_item;

    // inputs to DUT
    rand bit pwrite;
    rand bit [7:0] paddr;
    rand bit [31:0] pwdata;

    // outputs from DUT
    bit [31:0] prdata;
    bit pslverr;

    // Valid address constraint - only valid register addresses
    constraint valid_addr_c {
        paddr inside {CTRL_OFFSET, THRESH_OFFSET, STATUS_OFFSET, DATA_OFFSET};
    }

    
    // CTRL register constraint
    constraint ctrl_reg_c {
        // [0]: EN
        // [1]: CLR
        // [2]: DROP_ON_FULL
        (paddr == CTRL_OFFSET) -> pwdata[31:3] == 29'h0;
    }

    // THRESH register constraint
    constraint thresh_reg_c {
        // [15:8] almost_empty_th
        // [7:0]  almost_full_th  
        (paddr == THRESH_OFFSET) -> pwdata[31:16] == 16'h0;
    }

    // ToDo Write data constraint for DATA register (8-bit) ---------> todo need to check that (the least or most significant 8 bit )
    constraint data_reg_c {
        // data needs just [7:0] valid, upper bits zero
        (paddr == DATA_OFFSET) -> pwdata[31:8] == 24'h0;
    }

    // status register is read-only - no constraint needed

   
    // // Operation distribution
    // constraint op_dist_c {
    // pwrite dist {APB_WRITE := 60, APB_READ := 40};
    // }

    // macros
    `uvm_object_utils_begin(apb_sequence_item)
    `uvm_field_int(pwrite, UVM_ALL_ON)
    `uvm_field_int(paddr, UVM_ALL_ON)
    `uvm_field_int(pwdata, UVM_ALL_ON)
    `uvm_field_int(prdata, UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "apb_sequence_item");
        super.new(name);
    endfunction : new

    //--------------------------------------------------------------------------
    // Convert to String (for debug)
    //--------------------------------------------------------------------------
    function string convert2string();
        string s;
        s = $sformatf("\n========== APB Transaction ==========");
        s = {s, $sformatf("\n  Operation : %s", pwrite.name())};
        s = {s, $sformatf("\n  Address   : 0x%02h", paddr)};
        if (pwrite == APB_WRITE)
            s = {s, $sformatf("\n  Write Data: 0x%08h", pwdata)};
        else if (pwrite == APB_READ)
            s = {s, $sformatf("\n  Read Data : 0x%08h", prdata)};
        s = {s, $sformatf("\n  Slave Err : %0d", pslverr)};
        s = {s, "\n======================================\n"};
        return s;
    endfunction : convert2string

endclass : apb_sequence_item

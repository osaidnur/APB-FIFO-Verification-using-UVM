class apb_sequence_item extends uvm_sequence_item;
    
    // Reset signal
    rand bit presetn;

    // inputs to DUT
    rand bit pwrite;
    randc bit [7:0] paddr;
    rand bit [31:0] pwdata;

    // outputs from DUT
    bit [31:0] prdata;
    bit pslverr;

    // Valid address constraint
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

    // Write data constraint for DATA register (8-bit)
    constraint data_reg_c {
        // data needs just [7:0] valid, upper bits zero
        (paddr == DATA_OFFSET) -> pwdata[31:8] == 24'h0;
    }

    // Reset is always high during normal operations
    constraint reset_default_c {
        presetn == 1'b1;
    }

    // macros
    `uvm_object_utils_begin(apb_sequence_item)
    `uvm_field_int(presetn, UVM_ALL_ON)
    `uvm_field_int(pwrite, UVM_ALL_ON)
    `uvm_field_int(paddr, UVM_ALL_ON)
    `uvm_field_int(pwdata, UVM_ALL_ON)
    `uvm_field_int(prdata, UVM_ALL_ON)
    `uvm_field_int(pslverr, UVM_ALL_ON)
    `uvm_object_utils_end

    // Constructor
    function new(string name = "apb_sequence_item");
        super.new(name);
    endfunction : new

endclass : apb_sequence_item
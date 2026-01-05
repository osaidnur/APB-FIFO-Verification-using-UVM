class apb_subscriber extends uvm_subscriber #(apb_sequence_item);
    
    `uvm_component_utils(apb_subscriber)
    
    apb_sequence_item item;
    
    // Tracked state for coverage
    bit [7:0]  last_status;
    bit [4:0]  fifo_count;
    bit        fifo_en;
    bit        drop_on_full;
    
    //--------------------------------------------------------------------------
    // Covergroups
    //--------------------------------------------------------------------------
    
    // APB Transaction Coverage
    covergroup apb_transaction_cg;
        option.per_instance = 1;
        
        // Operation type coverage
        operation_cp: coverpoint item.pwrite {
            bins read  = {APB_READ};
            bins write = {APB_WRITE};
        }
        
        // Address coverage
        address_cp: coverpoint item.paddr {
            bins ctrl_reg   = {8'h00};
            bins thresh_reg = {8'h04};
            bins status_reg = {8'h08};
            bins data_reg   = {8'h0C};
            bins invalid    = default;
        }
        
        // Cross coverage: operation x address
        op_addr_cross: cross operation_cp, address_cp {
            // STATUS is read-only
            ignore_bins status_write = binsof(operation_cp.write) && binsof(address_cp.status_reg);
        }
        
    endgroup : apb_transaction_cg
    
    // FIFO Data Coverage
    covergroup fifo_data_cg;
        option.per_instance = 1;
        
        // Write data coverage for DATA register
        wdata_cp: coverpoint item.pwdata[7:0] {
            bins zero      = {8'h00};
            bins low       = {[8'h01:8'h3F]};
            bins mid       = {[8'h40:8'hBF]};
            bins high      = {[8'hC0:8'hFE]};
            bins max       = {8'hFF};
        }
        
        // Read data coverage for DATA register
        rdata_cp: coverpoint item.prdata[7:0] {
            bins zero      = {8'h00};
            bins low       = {[8'h01:8'h3F]};
            bins mid       = {[8'h40:8'hBF]};
            bins high      = {[8'hC0:8'hFE]};
            bins max       = {8'hFF};
        }
        
    endgroup : fifo_data_cg
    
    // FIFO Status Coverage
    covergroup fifo_status_cg;
        option.per_instance = 1;
        
        // FIFO count coverage
        count_cp: coverpoint fifo_count {
            bins empty     = {0};
            bins one       = {1};
            bins low       = {[2:5]};
            bins mid       = {[6:10]};
            bins high      = {[11:14]};
            bins almost_full = {15};
            bins full      = {16};
        }
        
        // Empty flag
        empty_cp: coverpoint last_status[0] {
            bins not_empty = {0};
            bins empty     = {1};
        }
        
        // Full flag
        full_cp: coverpoint last_status[1] {
            bins not_full = {0};
            bins full     = {1};
        }
        
        // Almost full flag
        almost_full_cp: coverpoint last_status[2] {
            bins not_almost_full = {0};
            bins almost_full     = {1};
        }
        
        // Almost empty flag
        almost_empty_cp: coverpoint last_status[3] {
            bins not_almost_empty = {0};
            bins almost_empty     = {1};
        }
        
        // Overflow flag
        overflow_cp: coverpoint last_status[4] {
            bins no_overflow = {0};
            bins overflow    = {1};
        }
        
        // Underflow flag
        underflow_cp: coverpoint last_status[5] {
            bins no_underflow = {0};
            bins underflow    = {1};
        }
        
        // Cross coverage: Empty and operations
        empty_full_cross: cross empty_cp, full_cp {
            // Can't be both empty and full
            illegal_bins impossible = binsof(empty_cp.empty) && binsof(full_cp.full);
        }
        
    endgroup : fifo_status_cg
    
    // Control Register Coverage
    covergroup ctrl_reg_cg;
        option.per_instance = 1;
        
        // Enable bit
        en_cp: coverpoint fifo_en {
            bins disabled = {0};
            bins enabled  = {1};
        }
        
        // Drop on full mode
        drop_mode_cp: coverpoint drop_on_full {
            bins error_on_full = {0};
            bins drop_on_full  = {1};
        }
        
        // Cross coverage
        mode_cross: cross en_cp, drop_mode_cp;
        
    endgroup : ctrl_reg_cg
    
    // Threshold Coverage
    covergroup threshold_cg;
        option.per_instance = 1;
        
        // Almost full threshold
        almost_full_th_cp: coverpoint item.pwdata[7:0] iff (item.paddr == THRESH_OFFSET && item.pwrite == APB_WRITE) {
            bins low_th  = {[0:5]};
            bins mid_th  = {[6:10]};
            bins high_th = {[11:15]};
        }
        
        // Almost empty threshold
        almost_empty_th_cp: coverpoint item.pwdata[15:8] iff (item.paddr == THRESH_OFFSET && item.pwrite == APB_WRITE) {
            bins low_th  = {[0:5]};
            bins mid_th  = {[6:10]};
            bins high_th = {[11:15]};
        }
        
    endgroup : threshold_cg
    
    // Error Conditions Coverage
    covergroup error_conditions_cg;
        option.per_instance = 1;
        
        // Write to full FIFO
        write_when_full_cp: coverpoint (item.paddr == DATA_OFFSET && item.pwrite == APB_WRITE && last_status[1]) {
            bins no_write_full = {0};
            bins write_full    = {1};
        }
        
        // Read from empty FIFO
        read_when_empty_cp: coverpoint (item.paddr == DATA_OFFSET && item.pwrite == APB_READ && last_status[0]) {
            bins no_read_empty = {0};
            bins read_empty    = {1};
        }
        
        // Operations when disabled
        op_when_disabled_cp: coverpoint (item.paddr == DATA_OFFSET && !fifo_en) {
            bins enabled_ops  = {0};
            bins disabled_ops = {1};
        }
        
    endgroup : error_conditions_cg
    
    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_fifo_coverage", uvm_component parent = null);
        super.new(name, parent);
        
        apb_transaction_cg  = new();
        fifo_data_cg = new();
        fifo_status_cg = new();
        ctrl_reg_cg = new();
        threshold_cg = new();
        error_conditions_cg = new();
    endfunction : new
    
    //--------------------------------------------------------------------------
    // Write Implementation - Called when monitor broadcasts a transaction
    //--------------------------------------------------------------------------
    function void write(apb_sequence_item t);
        item = t;
        
        // Sample APB transaction coverage
        apb_transaction_cg.sample();
        
        // Sample based on register type
        case (item.paddr)
            CTRL_OFFSET: begin
                if (item.pwrite == APB_WRITE) begin
                    fifo_en = item.pwdata[0];
                    drop_on_full = item.pwdata[2];
                end
                ctrl_reg_cg.sample();
            end
            
            THRESH_OFFSET: begin
                threshold_cg.sample();
            end
            
            STATUS_OFFSET: begin
                if (item.pwrite == APB_READ) begin
                    last_status = item.prdata[7:0];
                    fifo_count = item.prdata[13:6];
                end
                fifo_status_cg.sample();
            end
            
            DATA_OFFSET: begin
                fifo_data_cg.sample();
                error_conditions_cg.sample();
            end
        endcase
    endfunction : write
    
    //--------------------------------------------------------------------------
    // Report Phase
    //--------------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        
        `uvm_info("COV", "╔══════════════════════════════════════════╗", UVM_NONE)
        `uvm_info("COV", "║      COVERAGE SUMMARY REPORT             ║", UVM_NONE)
        `uvm_info("COV", "╠══════════════════════════════════════════╣", UVM_NONE)
        `uvm_info("COV", $sformatf("║  APB Transaction:    %5.2f%%             ║", apb_transaction_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("║  FIFO Data:          %5.2f%%             ║", fifo_data_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("║  FIFO Status:        %5.2f%%             ║", fifo_status_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("║  Control Register:   %5.2f%%             ║", ctrl_reg_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("║  Thresholds:         %5.2f%%             ║", threshold_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", $sformatf("║  Error Conditions:   %5.2f%%             ║", error_conditions_cg.get_coverage()), UVM_NONE)
        `uvm_info("COV", "╚══════════════════════════════════════════╝", UVM_NONE)
    endfunction : report_phase

endclass : apb_subscriber

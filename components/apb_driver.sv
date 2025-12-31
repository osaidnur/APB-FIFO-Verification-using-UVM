class apb_driver extends uvm_driver #(apb_sequence_item);

    `uvm_component_utils(apb_driver)

    virtual apb_fifo_if vif;
    
    // --------------------------------------------------------------------------
    // Constructor
    // --------------------------------------------------------------------------
    function new(string name = "apb_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    // --------------------------------------------------------------------------
    // Build Phase
    // --------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual apb_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal(get_type_name(), "Failed to get virtual interface from config DB")
        end
    endfunction : build_phase


    // --------------------------------------------------------------------------
    // Reset Signals
    // --------------------------------------------------------------------------
    task drive_idle();
        vif.drv_cb.PSEL <= 1'b0;
        vif.drv_cb.PENABLE <= 1'b0;
        vif.drv_cb.PWRITE <= 1'b0;
        vif.drv_cb.PADDR <= 8'h0;
        vif.drv_cb.PWDATA <= 32'h0;
    endtask : drive_idle



    // --------------------------------------------------------------------------
    // Run Phase
    // --------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_sequence_item item;

        // Initialize APB signals
        drive_idle();

        // Wait for reset to complete
        // @(posedge vif.PRESETn);
        // @(posedge vif.PCLK);

        forever begin
            seq_item_port.get_next_item(item);
            drive(item);
            
            // case (item.pwrite)
            // APB_WRITE: drive_write(item);
            // APB_READ:  drive_read(item);
            // APB_IDLE:  drive_idle();
            // endcase
            
            seq_item_port.item_done();
        end
    endtask : run_phase


    

    // // --------------------------------------------------------------------------
    // // Drive Write Transaction (APB3 Protocol)
    // // --------------------------------------------------------------------------
    // task drive_write(apb_sequence_item item);
    //     `uvm_info("APB_DRV", $sformatf("Driving WRITE: Addr=0x%02h, Data=0x%08h", 
    //                 item.paddr, item.pwdata), UVM_HIGH)

    //     // Setup Phase
    //     @(vif.drv_cb);
    //     vif.drv_cb.PSEL    <= 1'b1;
    //     vif.drv_cb.PENABLE <= 1'b0;
    //     vif.drv_cb.PWRITE  <= 1'b1;
    //     vif.drv_cb.PADDR   <= item.paddr;
    //     vif.drv_cb.PWDATA  <= item.pwdata;

    //     // Access Phase
    //     @(vif.drv_cb);
    //     vif.drv_cb.PENABLE <= 1'b1;

    //     // Wait for PREADY
    //     do begin
    //         @(vif.drv_cb);
    //     end while (!vif.drv_cb.PREADY);

    //     // Capture response
    //     item.pslverr = vif.drv_cb.PSLVERR;

    //     // End transaction
    //     vif.drv_cb.PSEL    <= 1'b0;
    //     vif.drv_cb.PENABLE <= 1'b0;

    //     `uvm_info("APB_DRV", $sformatf("WRITE Complete: Addr=0x%02h, SlvErr=%0d", 
    //                 item.paddr, item.pslverr), UVM_HIGH)
    // endtask : drive_write

    // //--------------------------------------------------------------------------
    // // Drive Read Transaction (APB3 Protocol)
    // //--------------------------------------------------------------------------
    // task drive_read(apb_sequence_item item);
    //     `uvm_info("APB_DRV", $sformatf("Driving READ: Addr=0x%02h", item.paddr), UVM_HIGH)

    //     // Setup Phase
    //     @(vif.drv_cb);
    //     vif.drv_cb.PSEL <= 1'b1;
    //     vif.drv_cb.PENABLE <= 1'b0;
    //     vif.drv_cb.PWRITE <= 1'b0;
    //     vif.drv_cb.PADDR <= item.paddr;
    //     vif.drv_cb.PWDATA <= 32'h0;

    //     // Access Phase
    //     @(vif.drv_cb);
    //     vif.drv_cb.PENABLE <= 1'b1;

    //     // Wait for PREADY
    //     do begin
    //         @(vif.drv_cb);
    //     end while (!vif.drv_cb.PREADY);

    //     // Capture response
    //     item.prdata  = vif.drv_cb.PRDATA;
    //     item.pslverr = vif.drv_cb.PSLVERR;

    //     // End transaction
    //     vif.drv_cb.PSEL    <= 1'b0;
    //     vif.drv_cb.PENABLE <= 1'b0;

    //     `uvm_info("APB_DRV", $sformatf("READ Complete: Addr=0x%02h, Data=0x%08h, SlvErr=%0d", 
    //                 item.paddr, item.prdata, item.pslverr), UVM_HIGH)
    // endtask : drive_read

    task drive(apb_sequence_item tr);
        
        // Wait until reset is deasserted
        while (vif.PRESETn !== 1'b1) begin
            drive_idle();
            @(posedge vif.PCLK);
        end

        // -------------------------
        // SETUP cycle
        // -------------------------
        @(posedge vif.PCLK);
        vif.PSEL <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE <= tr.pwrite;
        vif.PADDR <= tr.paddr;
        vif.PWDATA <= tr.pwdata;

        // -------------------------
        // ACCESS cycle(s)
        // -------------------------
        @(posedge vif.PCLK);
        vif.PENABLE <= 1'b1;

        // Wait states support: keep signals stable until PREADY=1
        while (vif.PREADY !== 1'b1) begin
            @(posedge vif.PCLK);
        end

        // Transfer completes on the cycle with PREADY=1 while PSEL&PENABLE=1
        tr.pslverr = vif.PSLVERR;
        if (!tr.pwrite) begin
            tr.prdata = vif.PRDATA;
        end

        // -------------------------
        // Return to IDLE
        // -------------------------
        @(posedge vif.PCLK);
        drive_idle();
    endtask


endclass : apb_driver

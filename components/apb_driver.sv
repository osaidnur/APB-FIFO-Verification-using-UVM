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
        vif.PRESETn <= 1'b1;
        vif.PSEL <= 1'b0;
        vif.PENABLE <= 1'b0;
        vif.PWRITE <= 1'b0;
        vif.PADDR <= 8'h0;
        vif.PWDATA <= 32'h0;
    endtask : drive_idle

    // --------------------------------------------------------------------------
    // Run Phase
    // --------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_sequence_item item;

        // Initialize APB signals
        drive_idle();

        forever begin
            seq_item_port.get_next_item(item);
            `uvm_info("Driver", $sformatf("Driving %s transaction: addr=0x%02h, pwdata=0x%0h",
                        item.pwrite ? "WRITE" : "READ", item.paddr, item.pwdata), UVM_HIGH)
            drive(item);
            seq_item_port.item_done(item);
        end
    endtask : run_phase

    // --------------------------------------------------------------------------
    // Drive APB Transaction
    // --------------------------------------------------------------------------
    task drive(apb_sequence_item tr);
        
        // If reset is asserted, just drive reset and idle signals
        if (tr.presetn == 1'b0) begin
            @(posedge vif.PCLK);
            vif.PRESETn <= 1'b0;
            vif.PSEL <= 1'b0;
            vif.PENABLE <= 1'b0;
            vif.PWRITE <= 1'b0;
            vif.PADDR <= 8'h0;
            vif.PWDATA <= 32'h0;
            return;
        end

        // Normal operation-no reset

        // SETUP cycle
        @(posedge vif.PCLK);
        vif.PRESETn <= 1'b1;
        vif.PSEL <= 1'b1;
        vif.PENABLE <= 1'b0;
        vif.PWRITE <= tr.pwrite;
        vif.PADDR <= tr.paddr;
        vif.PWDATA <= tr.pwdata;

        // ACCESS cycle
        @(posedge vif.PCLK);
        vif.PENABLE <= 1'b1;

        // keep signals stable until PREADY=1
        while (vif.PREADY !== 1'b1) begin
            @(posedge vif.PCLK);
        end

        // The transfer is completed here, so take the outputs
        tr.pslverr = vif.PSLVERR;
        if (!tr.pwrite) begin
            tr.prdata = vif.PRDATA;
        end

        // Return to IDLE
        @(posedge vif.PCLK);
        drive_idle();
    endtask

endclass : apb_driver
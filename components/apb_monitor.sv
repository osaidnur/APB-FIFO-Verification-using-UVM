class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual apb_fifo_if vif;
    uvm_analysis_port #(apb_sequence_item) ap ;

    //--------------------------------------------------------------------------
    // Constructor
    //--------------------------------------------------------------------------
    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction : new

    //--------------------------------------------------------------------------
    // Build Phase
    //--------------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db#(virtual apb_fifo_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("APB_MON", "Failed to get virtual interface from config DB")
        end
    endfunction : build_phase

    //--------------------------------------------------------------------------
    // Run Phase
    //--------------------------------------------------------------------------
    task run_phase(uvm_phase phase);
        apb_sequence_item item;

        // Wait for reset to complete
        @(posedge vif.PRESETn);

        forever begin
            @(posedge vif.PCLK);
            // APB transfer completes when PSEL=1, PENABLE=1, PREADY=1
            if (vif.PSEL && vif.PENABLE && vif.PREADY) begin
                item = apb_sequence_item::type_id::create("item", this);

                item.paddr   = vif.PADDR;
                item.pwrite  = vif.PWRITE;
                item.pwdata  = vif.PWDATA;
                item.prdata  = vif.PRDATA;
                item.pslverr = vif.PSLVERR;
                ap.write(item);
            end
        end
    endtask : run_phase
endclass : apb_monitor

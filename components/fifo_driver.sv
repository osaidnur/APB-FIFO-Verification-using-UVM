class alu_driver extends uvm_driver #(alu_sequence_item);

//1.UVM component
`uvm_component_utils(alu_driver)

//2. Initialization (vif & seq_item)
virtual alu_interface vif;
alu_sequence_item item; 
//3. Constructor
  function new(string name = "alu_driver", uvm_component parent);
    super.new(name, parent);
  endfunction : new

//4. Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!(uvm_config_db#(virtual alu_interface)::get(this, "*", "vif", vif))) 
            begin
            `uvm_error("FA_driver", "Failed to get VIF from config DB!")
            end
  endfunction : build_phase


//5. Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

//6. Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
        item = alu_sequence_item::type_id::create("item");
        seq_item_port.get_next_item(item);
        drive(item);
        seq_item_port.item_done();
    end
  endtask : run_phase

//7. Drive
  task drive(alu_sequence_item item);
  
    `uvm_info(get_type_name(), $sformatf("Driver: Sending data to DUT\n %s", item.sprint()),UVM_NONE)
    vif.A <= item.A;
    vif.B <= item.B;
    vif.selection <= item.selection;
    @(posedge vif.clk);

  endtask : drive

endclass : Adder_driver
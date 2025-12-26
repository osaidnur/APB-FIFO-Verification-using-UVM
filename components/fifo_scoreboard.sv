class alu_scoreboard extends uvm_scoreboard;
  //1. Component
  `uvm_component_utils(alu_scoreboard)

  //2. Port
  uvm_analysis_imp #(alu_sequence_item, alu_scoreboard) scoreboard_port;

  //3. Transactions
  alu_sequence_item transactions[$];

  //4. Constructor
  function new(string name = "alu_scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction : new

  //5. Build Phase
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard_port = new("scoreboard_port", this);
  endfunction : build_phase

  //6. Connect Phase
  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction : connect_phase

  //7. Write 
  function void write(Adder_sequence_item item);
    transactions.push_back(item);
    `uvm_info(get_type_name(), ("Scoreboard: Accept transaction item!"), UVM_MEDIUM)
    item.print();
  endfunction : write

  //8. Run Phase
  task run_phase(uvm_phase phase);
    super.run_phase(phase);
    forever begin
      Adder_sequence_item trans;
      wait ((transactions.size() != 0));
      trans = transactions.pop_front();
      compare(trans);
    end
  endtask : run_phase

  //9. Compare Function
  task compare(Adder_sequence_item trans);
    logic [4:0] actual_response;
    logic [4:0] predicted_response;
    actual_response = trans.c;
    if(trans.reset) begin
      predicted_response = 0;
    end else if (trans.valid) begin
      predicted_response = trans.a + trans.b;
    end
  
if (actual_response != predicted_response) begin
  `uvm_error(get_type_name(), "✘ TEST FAILED ✘")
  `uvm_info("Scoreboard", 
            $sformatf("Actual Output    = %h\nPredicted Output = %h", 
                      actual_response, predicted_response), 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "┌─────────────────────────────────────────────┐", 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "│           ✘ Mismatch Detected ✘            │", 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "└─────────────────────────────────────────────┘", 
            UVM_NONE)

end else begin
  `uvm_info(get_type_name(), "✓ TEST PASSED ✓", UVM_NONE)
  `uvm_info("Scoreboard", 
            $sformatf("Actual Output    = %h\nPredicted Output = %h", 
                      actual_response, predicted_response), 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "┌─────────────────────────────────────────────┐", 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "│           ✓ Outputs Match ✓                │", 
            UVM_NONE)
  `uvm_info(get_type_name(), 
            "└─────────────────────────────────────────────┘", 
            UVM_NONE)
end

  endtask : compare

endclass : Adder_scoreboard




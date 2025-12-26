class alu_sequence_item extends uvm_sequence_item;
  rand bit [7:0] A, B;
  rand bit [3:0] selection;
  bit [7:0] result;
  bit carry_out;
  
  `uvm_object_utils_begin(alu_sequence_item)
    `uvm_field_int(A, UVM_ALL_ON)
    `uvm_field_int(B, UVM_ALL_ON)
    `uvm_field_int(selection, UVM_ALL_ON)
    `uvm_field_int(result, UVM_ALL_ON)
    `uvm_field_int(carry_out, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "alu_sequence_item");
    super.new(name);
  endfunction
endclass
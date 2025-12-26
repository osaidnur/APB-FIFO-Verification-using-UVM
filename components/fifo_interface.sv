interface alu_interface(input logic clk);
  logic reset;
  logic [7:0] A, B;
  logic [3:0] selection;
  logic [7:0] result;
  logic carry_out;
endinterface
interface apb_fifo_if(input logic PCLK, input logic PRESETn);
  
  // input to the DUT
  logic        PSEL;
  logic        PENABLE;
  logic        PWRITE;
  logic [7:0]  PADDR;
  logic [31:0] PWDATA;

  // output from the DUT
  logic [31:0] PRDATA;
  logic        PREADY;
  logic        PSLVERR;
  
  // Driver clocking block
  clocking drv_cb @(posedge PCLK);
    default input #1ns output #1ns;
    output PSEL;
    output PENABLE;
    output PWRITE;
    output PADDR;
    output PWDATA;
    input  PRDATA;
    input  PREADY;
    input  PSLVERR;
  endclocking
  
  // Monitor clocking block
  clocking mon_cb @(posedge PCLK);
    default input #1ns output #1ns;
    input PSEL;
    input PENABLE;
    input PWRITE;
    input PADDR;
    input PWDATA;
    input PRDATA;
    input PREADY;
    input PSLVERR;
  endclocking
  
  // Modports
  modport DRV (clocking drv_cb, input PCLK, input PRESETn);
  modport MON (clocking mon_cb, input PCLK, input PRESETn);

endinterface : apb_fifo_if

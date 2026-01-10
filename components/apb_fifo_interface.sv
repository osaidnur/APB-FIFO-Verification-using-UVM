interface apb_fifo_if(input logic PCLK);

    // Reset signal
    logic PRESETn;

    // input to the DUT
    logic PSEL;
    logic PENABLE;
    logic PWRITE;
    logic [7:0] PADDR;
    logic [31:0] PWDATA;

    // output from the DUT
    logic [31:0] PRDATA;
    logic PREADY;
    logic PSLVERR;

    // // Driver clocking block
    // clocking drv_cb @(posedge PCLK);
    //     default input #1ns output #1ns;
    //     output PRESETn;
    //     output PSEL;
    //     output PENABLE;
    //     output PWRITE;
    //     output PADDR;
    //     output PWDATA;
    //     input PRDATA;
    //     input PREADY;
    //     input PSLVERR;
    // endclocking

    // Monitor clocking block
    // clocking mon_cb @(posedge PCLK);
    //     default input #1ns output #1ns;
    //     input PRESETn;
    //     input PSEL;
    //     input PENABLE;
    //     input PWRITE;
    //     input PADDR;
    //     input PWDATA;
    //     input PRDATA;
    //     input PREADY;
    //     input PSLVERR;
    // endclocking

    // Modports
    modport DRV (input PCLK, output PRESETn,
                  output PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                  input PRDATA, PREADY, PSLVERR
                );
    modport MON (input PCLK, PRESETn,
                  input PSEL, PENABLE, PWRITE, PADDR, PWDATA,
                  output PRDATA, PREADY, PSLVERR
                );

endinterface : apb_fifo_if
//------------------------------------------------------------------------------
// APB3-accessible synchronous FIFO (WIDTH=8, DEPTH=16) — intentionally buggy
//------------------------------------------------------------------------------
module apb_sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 16,
  localparam int AW    = $clog2(DEPTH)
)(
  input  logic        PCLK,
  input  logic        PRESETn,     
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [7:0]  PADDR,
  input  logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  output logic        PSLVERR
);

  // ---- APB constants ----
  localparam CTRL_O   = 8'h00;
  localparam THRESH_O = 8'h04;
  localparam STATUS_O = 8'h08;
  localparam DATA_O   = 8'h0C;

  // ---- registers ----
  logic        en, clr, drop_on_full;
  logic [7:0]  almost_full_th, almost_empty_th;
  logic        empty, full, almost_full, almost_empty;
  logic        overflow, underflow; // sticky
  logic [AW:0] count;               // allows DEPTH value

  // FIFO storage
  logic [WIDTH-1:0] mem [0:DEPTH-1];
  logic [AW-1:0] wptr, rptr;

  // APB default
  assign PREADY  = 1'b1;     // zero-wait state
  assign PSLVERR = 1'b0;     

  // Async reset 
  always @(negedge PRESETn or posedge PCLK) begin
    if (!PRESETn) begin
      en <= 1'b0;
      clr <= 1'b0;
      drop_on_full <= 1'b0;
      almost_full_th <= DEPTH-1; 
      almost_empty_th <= 8'd1;   
      
    end else begin
      if (PSEL && !PENABLE && PWRITE) begin // setup phase latching
        unique case (PADDR)
          CTRL_O: begin
            en           <= PWDATA[0];
            clr          <= PWDATA[1];   // self-clear handled below
            drop_on_full <= PWDATA[2];
          end
          THRESH_O: begin
            almost_full_th  <= PWDATA[7:0];
            almost_empty_th <= PWDATA[15:8];
          end
          default: ;
        endcase
      end

      // self-clear of CLR
      if (clr) clr <= 1'b0;

      
      if (PSEL && PENABLE && !PWRITE) begin
        overflow <= 1'b0;
        underflow <= 1'b0;
      end
    end
  end

  // STATUS read mux
  always_comb begin
    PRDATA = 32'd0;
    unique case (PADDR)
      STATUS_O: PRDATA = {18'd0, count[7:0], underflow, overflow, almost_empty, almost_full, full, empty};
      DATA_O:   PRDATA = {24'd0, mem[rptr]};
      CTRL_O:   PRDATA = {29'd0, drop_on_full, clr, en};
      THRESH_O: PRDATA = {16'd0, almost_empty_th, almost_full_th};
      default:  PRDATA = 32'd0;
    endcase
  end

  // FIFO control
  logic push, pop;
  assign push = (PSEL && PENABLE && PWRITE && (PADDR==DATA_O));
  assign pop  = (PSEL && PENABLE && !PWRITE && (PADDR==DATA_O));

  // Count/flags
  always @(posedge PCLK or posedge PRESETn) begin 
    if (PRESETn) begin
      count <= '0;
      wptr  <= '0;
      rptr  <= '0;
      empty <= 1'b1;
      full  <= 1'b0;
    end else begin
      if (clr) begin
        count <= '0;
        wptr  <= '0;
        rptr  <= '0;
        empty <= 1'b1;
        full  <= 1'b0;
      end else if (en) begin
        // Push
        if (push) begin
          if (!full) begin
            mem[wptr] <= PWDATA[7:0];
            wptr <= wptr + 1'b1;
            count <= count + 1'b1;
          end else begin
            
            if (drop_on_full) begin
              // drop silently but set flag
              overflow <= 1'b1;
            end else begin
                  overflow <= 1'b1;
            end
          end
        end

        // Pop
        if (pop) begin
          if (!empty) begin
            rptr <= rptr + 1'b1;
            count <= count - 1'b1;
          end else begin
            underflow <= 1'b1; 
          end
        end

        

        // Update empty/full
        empty <= (count == 0);
        full  <= (count == DEPTH-1);
      end
    end
  end

  
  always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      almost_full  <= 1'b0;
      almost_empty <= 1'b1;
    end else begin
      almost_full  <= (count > almost_full_th);
      almost_empty <= (count <= almost_empty_th);
    end
  end

endmodule

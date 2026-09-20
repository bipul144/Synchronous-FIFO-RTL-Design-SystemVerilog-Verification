// =====================================================================
// File   : fifo_if.sv
// Desc   : SystemVerilog interface bundling all DUT I/O signals,
//          used to connect the testbench classes to the DUT via a
//          virtual interface handle.
// =====================================================================

interface fifo_if;

  logic       clock, rd, wr;   // Clock, read, and write control signals
  logic       full, empty;     // Flags indicating FIFO status
  logic [7:0] data_in;         // Data input
  logic [7:0] data_out;        // Data output
  logic       rst;             // Reset signal

endinterface

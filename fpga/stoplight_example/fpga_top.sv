`default_nettype none
// Empty top module (do not modify the ports)

module fpga_top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // UART ports
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);
  // Your code goes here...
  logic rd, yellow, grn;

  top #() top_inst(.clk(hz100), .button(pb[0]), .nrst(!reset), .green(grn), .yellow(yellow), .red(rd));

  assign red = rd | yellow;
  assign green = yellow | grn;

endmodule
module top(
    input logic clk, nrst, //clock and negative-edge reset
    input logic [7:0] in_data,

    output logic out,
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

    // input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,

    // output logic [COUNT_W-1:0] nonzero_count,
    // output logic [COUNT_W-1:0] zero_count,

    // output logic [COST_W-1:0] raw_cost,
    // output logic [COST_W-1:0] bitmap_cost,
    // output logic [COST_W-1:0] rle_cost,

    // output logic [1:0]         format_select,
    // output logic [COST_W-1:0] selected_cost

adaptive_selector u1_select (
    // .tile_in()
)

endmodule
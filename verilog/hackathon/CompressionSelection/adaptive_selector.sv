`timescale 1ns / 1ps

// Complete Hardware block.
// Input:  one uncompressed tile
// Output: tile statistics, predicted costs, and the chosen compression format
module adaptive_selector #(
    parameter int DATA_W     = 8,
    parameter int TILE_ELEMS = 16,
    parameter int COUNT_W    = $clog2(TILE_ELEMS + 1),
    parameter int COST_W     = 8
)(
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,

    output logic [COUNT_W-1:0] nonzero_count,
    output logic [COUNT_W-1:0] zero_count,

    output logic [COST_W-1:0] raw_cost,
    output logic [COST_W-1:0] bitmap_cost,
    output logic [COST_W-1:0] rle_cost,

    output logic [1:0]         format_select,
    output logic [COST_W-1:0] selected_cost
);

    tile_analyzer #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .COUNT_W(COUNT_W)
    ) u_analyzer (
        .tile_in(tile_in),
        .nonzero_count(nonzero_count),
        .zero_count(zero_count)
    );

    cost_calculator #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .COUNT_W(COUNT_W),
        .COST_W(COST_W)
    ) u_cost (
        .nonzero_count(nonzero_count),
        .raw_cost(raw_cost),
        .bitmap_cost(bitmap_cost),
        .rle_cost(rle_cost)
    );

    format_selector #(
        .COST_W(COST_W)
    ) u_selector (
        .raw_cost(raw_cost),
        .bitmap_cost(bitmap_cost),
        .rle_cost(rle_cost),
        .format_select(format_select),
        .selected_cost(selected_cost)
    );

endmodule

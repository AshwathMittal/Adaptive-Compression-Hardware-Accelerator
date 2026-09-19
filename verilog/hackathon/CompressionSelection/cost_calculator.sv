`timescale 1ns / 1ps

// Predicts the exact encoded bit lengths produced by the current Member 1 encoders.
//
// RAW:    2-bit tag + every input value
// Bitmap: 2-bit tag + one bitmap bit per element + each non-zero value
// RLE:    2-bit tag + 4-bit token-count header + one 12-bit token per non-zero
//         (4-bit zero-run + 8-bit value for the current default parameters)
module cost_calculator #(
    parameter int DATA_W         = 8,
    parameter int TILE_ELEMS     = 16,
    parameter int COUNT_W        = $clog2(TILE_ELEMS + 1),
    parameter int COST_W         = 8,
    parameter int TAG_W          = 2,
    parameter int RLE_HEADER_W   = 4,
    parameter int RLE_RUN_W      = 4
)(
    input  logic [COUNT_W-1:0] nonzero_count,
    output logic [COST_W-1:0]  raw_cost,
    output logic [COST_W-1:0]  bitmap_cost,
    output logic [COST_W-1:0]  rle_cost
);

    always_comb begin
        // These formulas intentionally include the format tags because
        // Member 1's len_out signals also include them.
        raw_cost    = TAG_W + (TILE_ELEMS * DATA_W);
        bitmap_cost = TAG_W + TILE_ELEMS + (nonzero_count * DATA_W);
        rle_cost    = TAG_W + RLE_HEADER_W
                    + (nonzero_count * (RLE_RUN_W + DATA_W));
    end

endmodule

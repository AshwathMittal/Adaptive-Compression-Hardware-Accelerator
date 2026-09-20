`timescale 1ns / 1ps

// Examines one matrix tile and counts how many elements are zero/non-zero.
// For the current encoders, nonzero_count is the only statistic needed
// to predict RAW, Bitmap, and RLE encoded lengths exactly.
module tile_analyzer #(
    parameter int DATA_W     = 8,
    parameter int TILE_ELEMS = 16,
    parameter int COUNT_W    = $clog2(TILE_ELEMS + 1)
)(
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,
    output logic [COUNT_W-1:0]                 nonzero_count,
    output logic [COUNT_W-1:0]                 zero_count
);

    always_comb begin
        nonzero_count = '0;

        for (integer i = 0; i < TILE_ELEMS; i++) begin
            if (tile_in[i] != '0)
                nonzero_count = nonzero_count + 1'b1;
        end

        zero_count = TILE_ELEMS - nonzero_count;
    end

endmodule

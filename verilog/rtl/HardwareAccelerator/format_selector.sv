`timescale 1ns / 1ps

// Chooses the format with the smallest predicted encoded length.
// Tie-break rule:
//   1) RAW wins a tie involving RAW (simplest representation)
//   2) Bitmap wins a Bitmap/RLE tie
// This makes the decision deterministic and avoids unnecessary encoding work.
module format_selector #(
    parameter int COST_W = 8
)(
    input  logic [COST_W-1:0] raw_cost,
    input  logic [COST_W-1:0] bitmap_cost,
    input  logic [COST_W-1:0] rle_cost,

    output logic [1:0]        format_select,
    output logic [COST_W-1:0] selected_cost
);

    localparam logic [1:0] FORMAT_RAW    = 2'b00;
    localparam logic [1:0] FORMAT_BITMAP = 2'b01;
    localparam logic [1:0] FORMAT_RLE    = 2'b10;

    always_comb begin
        if ((raw_cost <= bitmap_cost) && (raw_cost <= rle_cost)) begin
            format_select = FORMAT_RAW;
            selected_cost = raw_cost;
        end
        else if (bitmap_cost <= rle_cost) begin
            format_select = FORMAT_BITMAP;
            selected_cost = bitmap_cost;
        end
        else begin
            format_select = FORMAT_RLE;
            selected_cost = rle_cost;
        end
    end

endmodule

//this wrapper instantiates all three encoders concurrently and 
//registers the outputs to deliver deterministic, pipeline-ready timing

`timescale 1ns / 1ps

module compression_top #(
    parameter DATA_W       = 8,
    parameter TILE_ELEMS   = 16,
    parameter MAX_OUT_BITS = 200
)(
    input  logic                              clk,
    input  logic                              rst_n,
    input  logic                              in_valid,
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,

    // RAW Encoder outputs
    output logic [MAX_OUT_BITS-1:0]           raw_data_out,
    output logic [7:0]                        raw_len_out,

    // Bitmap Encoder outputs
    output logic [MAX_OUT_BITS-1:0]           bitmap_data_out,
    output logic [7:0]                        bitmap_len_out,

    // RLE Encoder outputs
    output logic [MAX_OUT_BITS-1:0]           rle_data_out,
    output logic [7:0]                        rle_len_out,

    output logic                              out_valid
);

    // Combinational nets from sub-encoders
    logic [MAX_OUT_BITS-1:0] raw_data_w,   bitmap_data_w,   rle_data_w;
    logic [7:0]              raw_len_w,    bitmap_len_w,    rle_len_w;

    raw_encoder #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_raw (
        .tile_in(tile_in),
        .data_out(raw_data_w),
        .len_out(raw_len_w)
    );

    bitmap_encoder #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_bitmap (
        .tile_in(tile_in),
        .data_out(bitmap_data_w),
        .len_out(bitmap_len_w)
    );

    rle_encoder #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_rle (
        .tile_in(tile_in),
        .data_out(rle_data_w),
        .len_out(rle_len_w)
    );

    // Single-cycle output pipeline register stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            raw_data_out    <= '0;
            raw_len_out     <= '0;
            bitmap_data_out <= '0;
            bitmap_len_out  <= '0;
            rle_data_out    <= '0;
            rle_len_out     <= '0;
            out_valid       <= 1'b0;
        end else begin
            out_valid       <= in_valid;
            if (in_valid) begin
                raw_data_out    <= raw_data_w;
                raw_len_out     <= raw_len_w;
                bitmap_data_out <= bitmap_data_w;
                bitmap_len_out  <= bitmap_len_w;
                rle_data_out    <= rle_data_w;
                rle_len_out     <= rle_len_w;
            end
        end
    end

endmodule
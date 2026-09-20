`timescale 1ns / 1ps

module decompressor_tb;
    localparam int DATA_W = 8;
    localparam int TILE_ELEMS = 16;
    localparam int MAX_OUT_BITS = 200;

    logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in;
    logic [MAX_OUT_BITS-1:0] raw_data, bitmap_data, rle_data;
    logic [7:0] raw_len, bitmap_len, rle_len;
    logic [TILE_ELEMS-1:0][DATA_W-1:0] raw_tile, bitmap_tile, rle_tile;
    logic raw_valid, bitmap_valid, rle_valid;

    raw_encoder u_raw (.tile_in(tile_in), .data_out(raw_data), .len_out(raw_len));
    bitmap_encoder u_bitmap (.tile_in(tile_in), .data_out(bitmap_data), .len_out(bitmap_len));
    rle_encoder u_rle (.tile_in(tile_in), .data_out(rle_data), .len_out(rle_len));

    decompressor u_raw_dec (.data_in(raw_data), .len_in(raw_len), .tile_out(raw_tile), .valid(raw_valid));
    decompressor u_bitmap_dec (.data_in(bitmap_data), .len_in(bitmap_len), .tile_out(bitmap_tile), .valid(bitmap_valid));
    decompressor u_rle_dec (.data_in(rle_data), .len_in(rle_len), .tile_out(rle_tile), .valid(rle_valid));

    initial begin
        tile_in = '0;
        tile_in[3] = 8'h05;
        tile_in[7] = 8'hA7;
        tile_in[15] = 8'h02;
        #1;

        assert (raw_valid && bitmap_valid && rle_valid)
            else $fatal(1, "decoder rejected a valid encoded stream");
        assert (raw_tile == tile_in)
            else $fatal(1, "raw round trip failed");
        assert (bitmap_tile == tile_in)
            else $fatal(1, "bitmap round trip failed");
        assert (rle_tile == tile_in)
            else $fatal(1, "RLE round trip failed");

        $display("PASS: decompressor round trips raw, bitmap, and RLE streams");
        $finish;
    end
endmodule

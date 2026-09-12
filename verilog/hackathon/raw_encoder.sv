//this module appends the 2'b00 tag to the uncompressed 128-bit tile
`timescale 1ns / 1ps

module raw_encoder #(
    parameter DATA_W          = 8,
    parameter TILE_ELEMS      = 16,
    parameter RAW_BITS        = DATA_W * TILE_ELEMS, // 128 bits
    parameter MAX_OUT_BITS    = 200
)(
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,
    output logic [MAX_OUT_BITS-1:0]           data_out,
    output logic [7:0]                        len_out
);

    localparam [1:0] TAG_RAW = 2'b00;

    always_comb begin
        data_out = '0;
        // Pack: [Tag (2 bits)][Original Tile Data (128 bits)]
        data_out[1:0]                     = TAG_RAW;
        data_out[RAW_BITS + 1 : 2]        = tile_in;
        len_out                           = 8'd130; // 2 + 128
    end

endmodule
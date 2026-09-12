//verifies encoding

`timescale 1ns / 1ps

module tb_compression;

    localparam DATA_W       = 8;
    localparam TILE_ELEMS   = 16;
    localparam MAX_OUT_BITS = 200;

    logic clk;
    logic rst_n;
    logic in_valid;
    logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in;

    logic [MAX_OUT_BITS-1:0] raw_data_out, bitmap_data_out, rle_data_out;
    logic [7:0] raw_len_out, bitmap_len_out, rle_len_out;
    logic out_valid;

    compression_top #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .MAX_OUT_BITS(MAX_OUT_BITS)
    ) dut (.*);

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    initial begin
        clk      = 0;
        rst_n    = 0;
        in_valid = 0;
        tile_in  = '0;

        #20;
        rst_n = 1;
        #10;

        // Test 1: Sparse tile (5, 0, 0, 0, 0, 0, 0, 2, rest 0)
        @(negedge clk);  // Drive inputs on negedge to prevent race conditions
        in_valid   = 1;
        tile_in    = '0;
        tile_in[0] = 8'd5;
        tile_in[7] = 8'd2;

        @(negedge clk);
        in_valid = 0;

        @(posedge clk);
        #1; // Wait a tiny delay to ensure outputs propagate to the $display statement
        $display("--- Sparse Tile Test ---");
        $display("RAW    Len: %0d bits", raw_len_out);
        $display("Bitmap Len: %0d bits (Expected: 34 bits)", bitmap_len_out);
        $display("RLE    Len: %0d bits (Expected: 30 bits)", rle_len_out);

        // Verify tags
        assert(raw_data_out[1:0] == 2'b00) else $error("RAW tag mismatch!");
        assert(bitmap_data_out[1:0] == 2'b01) else $error("Bitmap tag mismatch!");
        assert(rle_data_out[1:0] == 2'b10) else $error("RLE tag mismatch!");

        #30;
        $display("All basic checks completed successfully.");
        $finish;
    end

endmodule
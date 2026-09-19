`timescale 1ns / 1ps

module tb_adaptive_selector;

    localparam int DATA_W       = 8;
    localparam int TILE_ELEMS   = 16;
    localparam int MAX_OUT_BITS = 200;
    localparam int COUNT_W      = $clog2(TILE_ELEMS + 1);
    localparam int COST_W       = 8;

    localparam logic [1:0] FORMAT_RAW    = 2'b00;
    localparam logic [1:0] FORMAT_BITMAP = 2'b01;
    localparam logic [1:0] FORMAT_RLE    = 2'b10;

    logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in;

    logic [COUNT_W-1:0] nonzero_count;
    logic [COUNT_W-1:0] zero_count;
    logic [COST_W-1:0] raw_cost, bitmap_cost, rle_cost;
    logic [1:0] format_select;
    logic [COST_W-1:0] selected_cost;

    // Instantiate Member 2's complete decision block.
    adaptive_selector #(
        .DATA_W(DATA_W),
        .TILE_ELEMS(TILE_ELEMS),
        .COUNT_W(COUNT_W),
        .COST_W(COST_W)
    ) dut (
        .*
    );

    // Also instantiate Member 1's encoders directly so this testbench can
    // prove that our predicted costs match their actual len_out values.
    logic [MAX_OUT_BITS-1:0] raw_data_unused;
    logic [MAX_OUT_BITS-1:0] bitmap_data_unused;
    logic [MAX_OUT_BITS-1:0] rle_data_unused;
    logic [7:0] raw_len_actual, bitmap_len_actual, rle_len_actual;

    raw_encoder #(
        .DATA_W(DATA_W), .TILE_ELEMS(TILE_ELEMS), .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_raw (
        .tile_in(tile_in), .data_out(raw_data_unused), .len_out(raw_len_actual)
    );

    bitmap_encoder #(
        .DATA_W(DATA_W), .TILE_ELEMS(TILE_ELEMS), .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_bitmap (
        .tile_in(tile_in), .data_out(bitmap_data_unused), .len_out(bitmap_len_actual)
    );

    rle_encoder #(
        .DATA_W(DATA_W), .TILE_ELEMS(TILE_ELEMS), .MAX_OUT_BITS(MAX_OUT_BITS)
    ) u_rle (
        .tile_in(tile_in), .data_out(rle_data_unused), .len_out(rle_len_actual)
    );

    task automatic load_first_n_nonzero(input int n);
        begin
            tile_in = '0;
            for (int i = 0; i < TILE_ELEMS; i++) begin
                if (i < n)
                    tile_in[i] = i + 1;
            end
            #1;
        end
    endtask

    task automatic check_case(
        input string case_name,
        input int expected_nz,
        input int expected_raw,
        input int expected_bitmap,
        input int expected_rle,
        input logic [1:0] expected_format
    );
        begin
            $display("\n--- %s ---", case_name);
            $display("NZ=%0d  RAW=%0d  Bitmap=%0d  RLE=%0d  Selected=%b (%0d bits)",
                     nonzero_count, raw_cost, bitmap_cost, rle_cost,
                     format_select, selected_cost);

            assert(nonzero_count == expected_nz)
                else $fatal(1, "nonzero_count mismatch");
            assert(zero_count == TILE_ELEMS - expected_nz)
                else $fatal(1, "zero_count mismatch");

            assert(raw_cost == expected_raw)
                else $fatal(1, "RAW predicted cost mismatch");
            assert(bitmap_cost == expected_bitmap)
                else $fatal(1, "Bitmap predicted cost mismatch");
            assert(rle_cost == expected_rle)
                else $fatal(1, "RLE predicted cost mismatch");

            // Check against Member 1's real encoder lengths.
            assert(raw_cost == raw_len_actual)
                else $fatal(1, "RAW cost does not match raw_encoder len_out");
            assert(bitmap_cost == bitmap_len_actual)
                else $fatal(1, "Bitmap cost does not match bitmap_encoder len_out");
            assert(rle_cost == rle_len_actual)
                else $fatal(1, "RLE cost does not match rle_encoder len_out");

            assert(format_select == expected_format)
                else $fatal(1, "Wrong format selected");
        end
    endtask

    initial begin
        tile_in = '0;
        #1;

        // K=0: RLE = 6 bits, best.
        load_first_n_nonzero(0);
        check_case("All zero", 0, 130, 18, 6, FORMAT_RLE);

        // K=1: RLE = 18 bits, best.
        load_first_n_nonzero(1);
        check_case("One non-zero", 1, 130, 26, 18, FORMAT_RLE);

        // K=2: RLE = 30 bits, best.
        load_first_n_nonzero(2);
        check_case("Two non-zero", 2, 130, 34, 30, FORMAT_RLE);

        // K=3: Bitmap and RLE both 42 bits; tie-break chooses Bitmap.
        load_first_n_nonzero(3);
        check_case("Three non-zero / Bitmap-RLE tie", 3, 130, 42, 42, FORMAT_BITMAP);

        // Middle-sparsity case: Bitmap wins.
        load_first_n_nonzero(10);
        check_case("Ten non-zero", 10, 130, 98, 126, FORMAT_BITMAP);

        // K=14: RAW and Bitmap both 130; tie-break chooses RAW.
        load_first_n_nonzero(14);
        check_case("Fourteen non-zero / RAW-Bitmap tie", 14, 130, 130, 174, FORMAT_RAW);

        // Dense cases: RAW wins.
        load_first_n_nonzero(15);
        check_case("Fifteen non-zero", 15, 130, 138, 186, FORMAT_RAW);

        load_first_n_nonzero(16);
        check_case("Fully dense", 16, 130, 146, 198, FORMAT_RAW);

        $display("\nPASS: All adaptive-selector tests completed successfully.");
        $finish;
    end

endmodule

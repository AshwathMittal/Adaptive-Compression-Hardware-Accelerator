`timescale 1ns / 1ps

// Human-readable demonstration bench for the adaptive 4x4 tile compressor.
// Run with: make demo
module tb_compression_demo;
    localparam integer DATA_W = 8;
    localparam integer TILE_ELEMS = 16;
    localparam integer MAX_OUT_BITS = 200;

    logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in;
    logic [4:0] nonzero_count, zero_count;
    logic [7:0] raw_cost, bitmap_cost, rle_cost, selected_cost;
    logic [1:0] format_select;
    logic [MAX_OUT_BITS-1:0] raw_data, bitmap_data, rle_data;
    logic [7:0] raw_len, bitmap_len, rle_len;
    logic [MAX_OUT_BITS-1:0] selected_data;
    logic [7:0] selected_len;
    logic [TILE_ELEMS-1:0][DATA_W-1:0] decoded_tile;
    logic decoded_valid;

    adaptive_selector u_selector (
        .tile_in(tile_in), .nonzero_count(nonzero_count), .zero_count(zero_count),
        .raw_cost(raw_cost), .bitmap_cost(bitmap_cost), .rle_cost(rle_cost),
        .format_select(format_select), .selected_cost(selected_cost)
    );

    raw_encoder u_raw (
        .tile_in(tile_in), .data_out(raw_data), .len_out(raw_len)
    );
    bitmap_encoder u_bitmap (
        .tile_in(tile_in), .data_out(bitmap_data), .len_out(bitmap_len)
    );
    rle_encoder u_rle (
        .tile_in(tile_in), .data_out(rle_data), .len_out(rle_len)
    );

    always_comb begin
        case (format_select)
            2'b00: begin selected_data = raw_data; selected_len = raw_len; end
            2'b01: begin selected_data = bitmap_data; selected_len = bitmap_len; end
            default: begin selected_data = rle_data; selected_len = rle_len; end
        endcase
    end

    decompressor u_decoder (
        .data_in(selected_data), .len_in(selected_len),
        .tile_out(decoded_tile), .valid(decoded_valid)
    );

    function automatic [8*8-1:0] format_name(input logic [1:0] format);
        case (format)
            2'b00: format_name = "RAW     ";
            2'b01: format_name = "BITMAP  ";
            default: format_name = "RLE     ";
        endcase
    endfunction

    task automatic print_matrix(input string label,
                                input logic [TILE_ELEMS-1:0][DATA_W-1:0] matrix);
        integer row;
        integer col;
        begin
            $display("%s", label);
            for (row = 0; row < 4; row = row + 1) begin
                $write("      [");
                for (col = 0; col < 4; col = col + 1) begin
                    $write("%02h%s", matrix[TILE_ELEMS - 1 - (row * 4 + col)],
                           col == 3 ? "]\n" : " ");
                end
            end
        end
    endtask

    task automatic print_case(input string case_name,
                              input logic [TILE_ELEMS-1:0][DATA_W-1:0] matrix);
        integer savings;
        begin
            tile_in = matrix;
            #1;
            savings = raw_cost - selected_cost;

            $display("\n============================================================");
            $display("CASE: %s", case_name);
            print_matrix("  INPUT 4x4 TILE:", tile_in);
            $display("  ANALYSIS: %0d non-zero, %0d zero", nonzero_count, zero_count);
            $display("  COST COMPARISON (bits):");
            $display("    RAW    = %0d bits  payload=%0d'h%0h", raw_cost, raw_len, raw_data);
            $display("    BITMAP = %0d bits  payload=%0d'h%0h", bitmap_cost, bitmap_len, bitmap_data);
            $display("    RLE    = %0d bits  payload=%0d'h%0h", rle_cost, rle_len, rle_data);
            $display("  DECISION: %s (%0d bits, saved %0d bits / %0d%%)",
                     format_name(format_select), selected_cost, savings,
                     (savings * 100) / raw_cost);
            $display("  FINAL COMPRESSED STREAM: %0d'h%0h", selected_len, selected_data);
            print_matrix("  DECOMPRESSED OUTPUT:", decoded_tile);
            if (!decoded_valid || decoded_tile != tile_in)
                $fatal(1, "Round-trip failed for %s", case_name);
            $display("  ROUND-TRIP: PASS");
        end
    endtask

    initial begin
        print_case("DENSE SENSOR TILE -> RAW", {
            8'h12, 8'ha4, 8'h37, 8'hf0,
            8'h55, 8'h81, 8'hc2, 8'h19,
            8'h6e, 8'h2b, 8'hd8, 8'h43,
            8'h9a, 8'h70, 8'h0d, 8'hbe
        });

        print_case("SPARSE MASK TILE -> BITMAP", {
            8'h00, 8'h00, 8'h2a, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h91,
            8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h44, 8'h00, 8'h00
        });

        print_case("CLUSTERED EVENTS TILE -> RLE", {
            8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'h00, 8'h5c,
            8'h00, 8'h00, 8'h00, 8'h00,
            8'h00, 8'h00, 8'ha7, 8'h00
        });

        $display("\nDEMO COMPLETE: every selected compressed tile decompressed losslessly.");
        $finish;
    end
endmodule
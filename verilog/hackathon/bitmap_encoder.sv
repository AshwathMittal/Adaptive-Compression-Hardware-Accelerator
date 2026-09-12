//this module generates a 16-bit occupancy mask via parallel zero-comparators, 
//then uses a parallel compaction crossbar to pack only the non-zero bytes without bubbles or latency

`timescale 1ns / 1ps

module bitmap_encoder #(
    parameter DATA_W       = 8,
    parameter TILE_ELEMS   = 16,
    parameter MAX_OUT_BITS = 200
)(
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,
    output logic [MAX_OUT_BITS-1:0]           data_out,
    output logic [7:0]                        len_out
);

    localparam [1:0] TAG_BITMAP = 2'b01;

    logic [TILE_ELEMS-1:0] is_nonzero;
    logic [3:0]            prefix_nz_count [TILE_ELEMS];
    logic [4:0]            total_nz;
    logic [DATA_W-1:0]     compacted_vals  [TILE_ELEMS];

    always_comb begin
        logic [3:0] cnt;
        logic [3:0] slot_idx;

        // Step 1: Detect non-zeros and calculate prefix sums inline
        total_nz = 5'd0;
        for (integer i = 0; i < TILE_ELEMS; i++) begin
            is_nonzero[i] = (tile_in[i] != 0);
            
            // Inline prefix sum to avoid iverilog function scope bugs
            cnt = 0;
            for (integer j = 0; j < TILE_ELEMS; j++) begin
                if (j < i) begin
                    if (tile_in[j] != 0) cnt = cnt + 1;
                end
            end
            prefix_nz_count[i] = cnt;
            
            if (is_nonzero[i]) total_nz = total_nz + 1;
        end

        // Step 2: Parallel Compaction
        for (integer slot = 0; slot < TILE_ELEMS; slot++) begin
            slot_idx = slot; 
            compacted_vals[slot] = '0;
            for (integer elem = 0; elem < TILE_ELEMS; elem++) begin
                if (is_nonzero[elem] && (prefix_nz_count[elem] == slot_idx)) begin
                    compacted_vals[slot] = tile_in[elem];
                end
            end
        end

        // Step 3: Stream Packing
        data_out        = '0;
        data_out[1:0]   = TAG_BITMAP;
        data_out[17:2]  = is_nonzero;

        for (integer slot = 0; slot < TILE_ELEMS; slot++) begin
            if (slot < total_nz) begin
                data_out[(18 + (slot * 8)) +: 8] = compacted_vals[slot];
            end
        end

        // Use multiplication instead of concatenation to prevent 'x' states
        len_out = 8'd18 + (total_nz * 8'd8);
    end

endmodule
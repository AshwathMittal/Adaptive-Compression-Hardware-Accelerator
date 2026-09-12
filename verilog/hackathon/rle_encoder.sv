//this engine calculates preceding zero-runs for every non-zero element in parallel 
//each token is encoded as a 12-bit pair (4-bit run length + 8-bit value), 
//preceded by a 4-bit header specifying the number of tokens. Any remaining trailing zeros are omitted, saving space

`timescale 1ns / 1ps

module rle_encoder #(
    parameter DATA_W       = 8,
    parameter TILE_ELEMS   = 16,
    parameter MAX_OUT_BITS = 200
)(
    input  logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_in,
    output logic [MAX_OUT_BITS-1:0]           data_out,
    output logic [7:0]                        len_out
);

    localparam [1:0] TAG_RLE = 2'b10;

    logic [TILE_ELEMS-1:0] is_nonzero;
    logic [3:0]            token_idx [TILE_ELEMS];
    logic [3:0]            zero_run  [TILE_ELEMS];
    logic [4:0]            total_tokens;
    logic [11:0]           packed_tokens [TILE_ELEMS];

    always_comb begin
        integer prev_nz_idx;
        logic [3:0] num_zeros;
        logic [3:0] count;
        logic [3:0] slot_idx;
        logic [3:0] total_tokens_trunc;

        // Step 1: Detect non-zero elements
        for (integer i = 0; i < TILE_ELEMS; i++) begin
            is_nonzero[i] = (tile_in[i] != 0); // Explicit check
        end

        // Step 2: Calculate zero runs and token target index
        for (integer i = 0; i < TILE_ELEMS; i++) begin
            prev_nz_idx = -1;
            
            // Fixed loop boundary for iverilog
            for (integer j = 0; j < TILE_ELEMS; j++) begin
                if (j < i) begin
                    if (is_nonzero[j]) prev_nz_idx = j;
                end
            end

            if (prev_nz_idx == -1) begin
                num_zeros = i; 
            end else begin
                num_zeros = i - prev_nz_idx - 1;
            end
            zero_run[i] = num_zeros;

            // Target token index
            count = 0;
            for (integer k = 0; k < TILE_ELEMS; k++) begin
                if (k < i) begin
                    if (is_nonzero[k]) count = count + 1;
                end
            end
            token_idx[i] = count;
        end

        total_tokens = 5'd0;
        for (integer i = 0; i < TILE_ELEMS; i++) begin
            if (is_nonzero[i]) total_tokens++;
        end

        // Step 3: Align tokens into sequential output positions
        for (integer slot = 0; slot < TILE_ELEMS; slot++) begin
            slot_idx = slot;
            packed_tokens[slot] = '0;
            for (integer elem = 0; elem < TILE_ELEMS; elem++) begin
                if (is_nonzero[elem] && (token_idx[elem] == slot_idx)) begin
                    packed_tokens[slot] = {zero_run[elem], tile_in[elem]};
                end
            end
        end

        // Step 4: Stream Packing
        total_tokens_trunc = total_tokens;
        
        data_out       = '0;
        data_out[1:0]  = TAG_RLE;
        data_out[5:2]  = total_tokens_trunc;

        for (integer slot = 0; slot < TILE_ELEMS; slot++) begin
            if (slot < total_tokens) begin
                data_out[(6 + (slot * 12)) +: 12] = packed_tokens[slot];
            end
        end

        len_out = 8'd6 + (total_tokens * 8'd12);
    end

endmodule
// $Id: $
// File name:   decoder_for_out.sv
// Created:     9/17/2024
// Author:      Miguel Isrrael Teran
// Description: Decoder for outputs

module decoder_for_out #(
    parameter IN_SIZE = 3,
    parameter OUT_SIZE = 8
)
(
    input logic [IN_SIZE-1:0] in,
    output logic [OUT_SIZE-1:0] out
);
    // Decoder Logic
    always_comb begin
        out = '0;
        if (in > '0 && in < OUT_SIZE + 1)
            out[in - 1] = 1'b1;
    end
endmodule
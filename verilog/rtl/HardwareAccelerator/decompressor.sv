`timescale 1ns / 1ps

module decompressor #(
	parameter int DATA_W       = 8,
	parameter int TILE_ELEMS   = 16,
	parameter int MAX_OUT_BITS = 200
)(
	input  logic [MAX_OUT_BITS-1:0]           data_in,
	input  logic [7:0]                        len_in,
	output logic [TILE_ELEMS-1:0][DATA_W-1:0] tile_out,
	output logic                              valid
);

	localparam logic [1:0] FORMAT_RAW    = 2'b00;
	localparam logic [1:0] FORMAT_BITMAP = 2'b01;
	localparam logic [1:0] FORMAT_RLE    = 2'b10;
	localparam int RAW_BITS = DATA_W * TILE_ELEMS;

	integer i;
	integer position;
	integer run_length;
	integer token_count;
	integer required_bits;
	logic [TILE_ELEMS-1:0] occupancy;
	logic [DATA_W-1:0] value;

	always_comb begin
		tile_out  = '0;
		valid     = 1'b0;
		occupancy = '0;
		position  = 0;
		run_length = 0;
		token_count = 0;
		required_bits = 0;
		value = '0;

		case (data_in[1:0])
			FORMAT_RAW: begin
				required_bits = RAW_BITS + 2;
				if ((len_in >= required_bits) && (required_bits <= MAX_OUT_BITS)) begin
					tile_out = data_in[RAW_BITS + 1:2];
					valid = 1'b1;
				end
			end

			FORMAT_BITMAP: begin
				occupancy = data_in[17:2];
				token_count = 0;
				for (i = 0; i < TILE_ELEMS; i = i + 1) begin
					if (occupancy[i])
						token_count = token_count + 1;
				end

				required_bits = 18 + (token_count * DATA_W);
				if ((len_in >= required_bits) && (required_bits <= MAX_OUT_BITS)) begin
					position = 0;
					for (i = 0; i < TILE_ELEMS; i = i + 1) begin
						if (occupancy[i]) begin
							tile_out[i] = data_in[18 + (position * DATA_W) +: DATA_W];
							position = position + 1;
						end
					end
					valid = 1'b1;
				end
			end

			FORMAT_RLE: begin
				token_count = data_in[5:2];
				required_bits = 6 + (token_count * (DATA_W + 4));
				if ((token_count <= TILE_ELEMS) &&
					(len_in >= required_bits) &&
					(required_bits <= MAX_OUT_BITS)) begin
					position = 0;
					valid = 1'b1;
					for (i = 0; i < TILE_ELEMS; i = i + 1) begin
						if (i < token_count) begin
							value = data_in[6 + (i * (DATA_W + 4)) +: DATA_W];
							run_length = data_in[6 + (i * (DATA_W + 4)) + DATA_W +: 4];
							position = position + run_length;
							if (position >= TILE_ELEMS) begin
								valid = 1'b0;
							end else begin
								tile_out[position] = value;
								position = position + 1;
							end
						end
					end
				end
			end

			default: begin
				valid = 1'b0;
			end
		endcase
	end

endmodule
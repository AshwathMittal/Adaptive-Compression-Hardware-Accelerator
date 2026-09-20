# Software verification and benchmarking

The Python files in the repository root form an independent software oracle
for the 4x4, unsigned 8-bit hardware compressor. The model matches the current
RTL bit-for-bit, including its two-bit tags and deterministic tie-breaking
order: RAW, then Bitmap, then RLE.

## 1. Run the software tests

From the repository root:

```bash
python3 test_compression_model.py -v
```

The suite verifies known cases, selector boundaries, bit packing, malformed
streams, and 1,000 randomized lossless round trips through every format.

## 2. Generate RTL oracle vectors

From the repository root:

```bash
python3 generate_vectors.py --count 256
```

This writes five deterministic memory files to:

```text
verilog/rtl/HardwareAccelerator/generated_vectors/
```

The files contain the input tiles, expected costs and selected formats, and
the exact expected RAW, Bitmap, and RLE payloads.

## 3. Verify the RTL

Install Icarus Verilog, then run:

```bash
cd verilog/rtl/HardwareAccelerator

iverilog -g2012 -s tb_software_vectors -o sim_vectors \
  raw_encoder.sv bitmap_encoder.sv rle_encoder.sv \
  tile_analyzer.sv cost_calculator.sv format_selector.sv \
  adaptive_selector.sv decompressor.sv tb_software_vectors.sv

vvp sim_vectors +VECTOR_DIR=generated_vectors
```

When every test passes, the final line is:

```text
PASS: 256 Python-oracle vectors matched the RTL and decompressed correctly.
```

For a different vector count, generate the same count and compile with:

```bash
-Ptb_software_vectors.NUM_VECTORS=<count>
```

The testbench checks:

- exact RAW, Bitmap, and RLE payloads;
- all three encoded lengths;
- predicted costs and the selected format;
- RAW, Bitmap, and RLE hardware decompression; and
- equality between every reconstructed tile and its original input.

## 4. Run the benchmark

From the repository root:

```bash
python3 benchmark.py --samples-per-density 100 --output-dir benchmark_results
```

This creates per-tile and summary CSV files plus two PNG plots. Matplotlib is
required for plot generation. All bit counts include the tags emitted by the
current RTL.

## 5. Record the RTL compression demo

From the repository root:

```bash
make demo
```

The demo prints three 4x4 tiles chosen to exercise RAW, Bitmap, and RLE. For
each tile it shows the input matrix, non-zero/zero counts, all three exact
candidate costs, the selected format, the final packed bitstream, and the
decompressed matrix. It ends each case with a lossless round-trip check. This
output is intended to be captured directly in a terminal recording alongside
the RTL architecture explanation.

For all 256 generated oracle vectors, run:

```bash
make demo-python
```

This uses the same `tiles.mem` and `expected.mem` files as the RTL testbench,
checks every cost and format decision against the software model, prints every
matrix and compressed stream, and ends with a format-selection and savings
summary. Use `python3 demo_vectors.py --limit 3` for a short rehearsal.

The synthetic pattern families intentionally have identical nonzero counts
but different placement. Their size curves overlap with the current formats
because encoded cost depends only on the number of nonzero elements, not their
positions.

## Known RLE edge case

The RLE token-count field is four bits, so a tile containing 16 nonzero values
stores a header value of zero. The software decoder distinguishes this case
from an all-zero tile using the encoded length: 198 bits versus 6 bits.

The current hardware decompressor reads only the four-bit count and will fail
the fully-dense fixed-RLE round-trip test. The decoder must either infer 16
tokens when `len_in == 198` and the header is zero, or the format must use a
wider token-count field. Adaptive mode selects RAW for a fully-dense tile, but
the fixed-RLE benchmark still requires this edge case to be defined.

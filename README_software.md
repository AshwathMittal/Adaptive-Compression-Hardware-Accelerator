# Software verification and benchmarking

This directory is the independent software oracle for the 4x4, unsigned
8-bit hardware compressor. It matches the current RTL bit-for-bit, including
the two-bit tags and deterministic tie-breaking (`RAW`, then `Bitmap`, then
`RLE`).

## Run the software tests

From `software/`:

```bash
python3 -m unittest discover -s tests -v
```

The tests verify known cases, selector boundaries, bit packing, malformed
streams, and 1,000 randomized lossless round trips through every format.

## Generate RTL oracle vectors

```bash
python3 generate_vectors.py --count 256
```

Then, from `verilog/hackathon/`:

```bash
iverilog -g2012 -s tb_software_vectors -o sim_vectors \
  raw_encoder.sv bitmap_encoder.sv rle_encoder.sv \
  CompressionSelection/tile_analyzer.sv \
  CompressionSelection/cost_calculator.sv \
  CompressionSelection/format_selector.sv \
  CompressionSelection/adaptive_selector.sv \
  tb_software_vectors.sv
vvp sim_vectors +VECTOR_DIR=generated_vectors
```

For a different vector count, compile with
`-Ptb_software_vectors.NUM_VECTORS=<count>`.

## Run the benchmark

```bash
python3 benchmark.py --samples-per-density 100 --output-dir benchmark_results
```

This creates per-tile and summary CSV files plus two PNG plots. All reported
bit counts include the tags emitted by the current RTL. The three synthetic
patterns intentionally have the same nonzero counts but different placement;
with the current encodings their size curves overlap because cost depends only
on nonzero count, not zero placement.

## Current RLE edge case

The RLE token-count field is four bits, so a tile containing 16 nonzero values
stores a header value of zero. The software decoder resolves this using the
reported encoded length (198 bits). The adaptive selector chooses RAW for this
case, but a future hardware decoder or fixed-RLE experiment must adopt the same
rule or widen the count field.

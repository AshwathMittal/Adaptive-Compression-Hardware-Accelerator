- build the core data-path logic: three parallel encoding circuits that take a raw 4x4 matrix tile (128 bits) and independently compress it
- modules will output these compressed payloads to the selector, which decides which one actually gets saved

- encoder - encoders append the 2-bit tag so the decoder knows which algorithm was used

- bitmap encoding - a type of data compression, 16-way zero comparison + Shift register/FIFO packing, drops 128 bits down to 16 bits PLUS the actual non-zero values
- run length encoding- a type of data compression, compresses data by finding sequences (runs) of identical values and replacing them with a single value and a count

-use (iverilog -g2012 -o sim_out raw_encoder.sv bitmap_encoder.sv rle_encoder.sv compression_top.sv tb_compression.sv) to run the test bench
-use vvp sim_out to see results
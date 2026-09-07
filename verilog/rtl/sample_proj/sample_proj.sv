// $Id: $
// File name:   sample_proj.sv
// Created:     9/17/2024
// Author:      Miguel Isrrael Teran
// Description: Sample Project

/*
* This sample project consists of a design that cycles through each of the
* 34 available output pins, setting the pin output on and off, one at
* a time, in sequence.
*
* This output cycling is active when "enable" is high, and stops when
* "stop" is high (stop has priority over enable).
*
* The "prescaler" value controls the cycling period (i.e., how long the
* output of each GPIO pin stays high). A prescaler value of 1 means that each pin
* is set high for 1 ms. Similarly, a prescaler value of 1000 means that
* each pin is set high for 1 s.
* 
* "Done" goes high after the last pin output turns off. Each pin
* should have gone high for the same amount of time
* (one after the other) before this happens.
*/

module sample_proj (
`ifdef USE_POWER_PINS
    inout VPWR,
    inout VGND,
`endif
    input logic clk,  // clock is 10 MHz
    input logic nrst,
    input logic enable,
    input logic stop,
    input logic [13:0] prescaler,
    output logic done,
    output logic [33:0] out
);

    // Internal signals
    logic clk_pulse;
    logic [5:0] count;
    logic [33:0] gpio;

    // Clock divider
    flex_counter #(.NUM_CNT_BITS(28)) clk_divider (
        .clk(clk),
        .nrst(nrst),
        .count_enable(enable),
        .clear(stop),
        .rollover_val({14'd0, prescaler} * 28'd10000),  // there are 10^4 clock cycles in 1 ms
        .rollover_flag(clk_pulse),
        .count_out()
    );

    // Counter
    flex_counter #(.NUM_CNT_BITS(6)) counter_to_35 (
        .clk(clk),
        .nrst(nrst),
        .count_enable(clk_pulse),
        .clear(stop),
        .rollover_val(6'd35),  // interrupt is raised when count is 35
        .count_out(count),
        .rollover_flag(done)
    );

    // Decoder instantiation
    decoder_for_out #(
        .IN_SIZE(6),
        .OUT_SIZE(34)
    ) decoder (
        .in(count),
        .out(out)
    );

endmodule

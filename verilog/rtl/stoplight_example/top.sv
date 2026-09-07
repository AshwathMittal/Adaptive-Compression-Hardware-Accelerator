module top (
    input logic clk, nrst, //clock and negative-edge reset
    //other signals here
    input logic button,
    output logic red, yellow, green
);
    //internal signals
    logic count_en, count_clr, count_max;

    //all submodule instantiations here
    counter src1 (
        .clk(clk), .nrst(nrst), //clock and negative-edge reset
        //other signals here
        .clear(count_clr), .enable(count_en),
        .max_count(count_max)
    );

    fsm src2 (
        .clk(clk), .nrst(nrst), //clock and negative-edge reset
        //other signals here
        .button(button), .count_max(count_max),
        .red(red), .yellow(yellow), .green(green),
        .count_clr(count_clr), .count_en(count_en)
    );
    
endmodule
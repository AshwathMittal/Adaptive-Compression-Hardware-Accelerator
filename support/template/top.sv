module top #(
    //parameters here
)(
    input logic clk, nrst, //clock and negative-edge reset
    //other signals here
    output logic out
);
    //internal signals
    logic a;
    assign out = a;

    //all submodule instantiations here
    src1 #() src1_inst (.clk(clk), .nrst(nrst), .a(a));
    
endmodule
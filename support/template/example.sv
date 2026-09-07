module src1 #(
    //parameters here
)(
    input logic clk, nrst, //clock and negative-edge reset
    //other signals here
    output logic a
);
    //module code here
    assign a = clk && nrst;
    
endmodule

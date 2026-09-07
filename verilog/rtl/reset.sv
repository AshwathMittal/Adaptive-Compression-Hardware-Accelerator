//TODO: PLEASE REMOVE FROM TEMPLATE REPO
`default_nettype none
logic clk;
logic syncrst;
logic D, Q;
 
module reset (
  input logic clk,
  input logic rst_button,
  output rst
);
 
always_ff @(posedge clk) begin
  if (rst) begin
    Q <= 0;
  end else begin
    Q <= D;
  end
end

module counter (
    input logic clk, nrst, //clock and negative-edge reset
    //other signals here
    input logic clear, enable,
    output logic max_count
);
    //module code here
    logic [7:0] count_d, count_q;

    always_ff @(posedge clk, negedge nrst) begin: count_register
        if (!nrst) begin
            count_q <= '0;
        end else begin
            count_q <= count_d;
        end
    end

    always_comb begin: next_count_logic
        count_d = count_q;
        if (clear || max_count) begin
            count_d = '0;
        end else if (enable) begin
            count_d = count_q + 1;
        end
    end

    always_comb begin: output_logic
        max_count = 0;
        if (count_q == 8'd10) begin
            max_count = 1;
        end
    end
    
endmodule

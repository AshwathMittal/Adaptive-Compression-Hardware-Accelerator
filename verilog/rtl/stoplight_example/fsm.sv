module fsm (
    input logic clk, nrst, //clock and negative-edge reset
    //other signals here
    input logic button, count_max,
    output logic red, yellow, green,
    output logic count_clr, count_en
);
    //module code here
    typedef enum logic [1:0] {
        RED,
        YELLOW,
        GREEN
    } state_t;

    state_t state_d, state_q;

    always_ff @(posedge clk, negedge nrst) begin: count_register
        if (!nrst) begin
            state_q <= RED;
        end else begin
            state_q <= state_d;
        end
    end

    always_comb begin: next_state_logic
        state_d = state_q;
        {red, yellow, green} = 0;
        count_en = 0;
        count_clr = 0;

        case (state_q)
            RED: begin
                red = 1;
                count_en = 1;
                if (count_max) begin
                    state_d = GREEN;
                end
            end
            YELLOW: begin
                yellow = 1;
                count_en = 1;
                if (count_max) begin
                    state_d = RED;
                end
            end
            GREEN: begin
                green = 1;
                count_clr = 1;
                if (button) begin
                    state_d = YELLOW;
                end
            end
            default: state_d = RED;
        endcase
    end
    
endmodule

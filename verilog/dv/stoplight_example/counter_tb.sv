// $Id: $
// File name:   src1_tb.sv
// Created:     01/19/2026
// Author:      Alex Weyer
// Description: Template test bench

`timescale 1ns / 10ps

module counter_tb();

    // Define local parameters used by the test bench
    localparam  CLK_PERIOD = 10;
    
    // Declare DUT portmap signals
    logic clk;
    logic nrst;
    // etc...
    logic clear, enable, max_count;
    
    // Declare test bench signals
    integer tb_test_num;
    integer tb_passed;
    string tb_test_case;
    
    // Task for standard DUT reset procedure
    task reset_dut;
    begin
        // Activate the reset
        nrst = 1'b0;
        @(posedge clk);
        @(posedge clk);
        @(negedge clk);
        // deactivate reset
        nrst = 1'b1;
        @(negedge clk);
        @(negedge clk);
    end
    endtask

    // Add more tasks as needed


    // Clock generation block
    always
    begin
        #(CLK_PERIOD/2.0); clk ++;
    end

    // Signal dump
    initial begin
        $dumpfile ("support/waves/stoplight_example/counter.vcd");
        $dumpvars;
    end
    
    // DUT Port map
    counter DUT(.*); // .* is a shortcut to automatically connect all ports if names match
    
    // Test bench main process
    initial
    begin
        // Initialize all of the test inputs here
        clk = 0;
        nrst = 1;
        // etc...
        enable = 1;
        clear = 0;

        // ************************************************************************
        // Test Case 1: Power-on Reset of the DUT
        // ************************************************************************
        tb_test_case = "Power on Reset";

        reset_dut();

        // ************************************************************************
        // Test Case 2: Continuous counting
        // ************************************************************************    
        tb_test_case = "Continuous counting";
        repeat (5) @(negedge clk);
        clear = 1;
        tb_test_case = "clear";
        repeat (3) @(negedge clk);
        clear = 0;
        tb_test_case = "Continuous counting";
        repeat (5) @(negedge clk);
        enable = 0;
        tb_test_case = "disabled";
        repeat (3) @(negedge clk);
        enable = 1;
        tb_test_case = "wrap around";
        repeat(10) @(negedge clk);

        $display("\nTest cases passed: %1d/%1d\n", tb_passed, tb_test_num);
        $finish;

    end

endmodule
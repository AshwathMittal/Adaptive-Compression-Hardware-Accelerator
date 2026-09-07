// $Id: $
// File name:   top1_tb.sv
// Created:     01/19/2026
// Author:      Alex Weyer
// Description: Template test bench

`timescale 1ns / 10ps

module top_tb();

    // Define local parameters used by the test bench
    localparam  CLK_PERIOD = 10;
    
    // Declare DUT portmap signals
    logic clk;
    logic nrst;
    // etc...
    logic button;
    logic red, yellow, green;

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
        $dumpfile ("support/waves/stoplight_example/top.vcd");
        $dumpvars;
    end
    
    // DUT Port map
    top DUT(.*);
    
    // Test bench main process
    initial
    begin
        // Initialize all of the test inputs here
        clk = 0;
        nrst = 1;
        // etc...
        button = 0;

        // ************************************************************************
        // Test Case 1: Power-on Reset of the DUT
        // ************************************************************************
        tb_test_case = "Power on Reset";

        reset_dut();

        // ************************************************************************
        // Test Case 2: 
        // ************************************************************************    
        tb_test_case = "Your Next Test Case";
        //red
        repeat(30) @(negedge clk);
        button = 1;
        @(negedge clk);
        button = 0;
        repeat(30) @(negedge clk);

        $display("\nTest cases passed: %1d/%1d\n", tb_passed, tb_test_num);
        $finish;

    end

endmodule
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
    logic tb_clk;
    logic tb_nrst;
    // etc...
    
    // Declare test bench signals
    integer tb_test_num;
    integer tb_passed;
    string tb_test_case;
    
    // Task for standard DUT reset procedure
    task reset_dut;
    begin
        // Activate the reset
        tb_nrst = 1'b0;
        @(posedge tb_clk);
        @(posedge tb_clk);
        @(negedge tb_clk);
        // deactivate reset
        tb_nrst = 1'b1;
        @(negedge tb_clk);
        @(negedge tb_clk);
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
        $dumpfile ("support/waves/<project>/top.vcd");
        $dumpvars;
    end
    
    // DUT Port map
    top DUT(.clk(tb_clk), .nrst(tb_nrst), /*add other ports*/);
    
    // Test bench main process
    initial
    begin
        // Initialize all of the test inputs here
        clk = 0;
        nrst = 1;
        // etc...

        // ************************************************************************
        // Test Case 1: Power-on Reset of the DUT
        // ************************************************************************
        tb_test_case = "Power on Reset";

        reset_dut();

        // ************************************************************************
        // Test Case 2: Continuous counting
        // ************************************************************************    
        tb_test_case = "Your Next Test Case";

        $display("\nTest cases passed: %1d/%1d\n", tb_passed, tb_test_num);
        $finish;

    end

endmodule
//TODO: PLEASE REMOVE FROM TEMPLATE BRANCH
// Code your design here
`default_nettype none

// ============================================================================
// TOP MODULE
// ============================================================================
module top (
  // Physical I/O ports
  input  wire logic clk_66mhz, 
  input  wire logic reset,     
  input  wire logic [20:0] pb,
  
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,
  output logic [7:0] txdata,
  input  wire logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  wire logic txready, rxready
);

  // --- Internal System Signals ---
  logic sys_rst;   // The clean reset from your sync module
  
  logic [3:0]  rnd_4bit;
  logic [15:0] ship_pos_wire;
  
  logic [15:0] p1_ships_reg;
  logic [15:0] p2_ships_reg;

  // Pulses from your edge detectors
  logic load_p1_pulse;
  logic load_p2_pulse;

  // Ship Counters (3 bits can count from 0 to 7)
  logic [2:0] p1_ship_count;
  logic [2:0] p2_ship_count;

  // --- Module Instantiations ---

  // 1. The Reset Synchronizer
  reset_sync rst_manager (
    .clk(clk_66mhz),
    .rst_button(reset),
    .rst(sys_rst)
  );

  // 2. The Random Number Generator 
  lfsr_4bit generator (
    .clk(clk_66mhz),
    .reset(sys_rst),
    .rnd_4bit(rnd_4bit)
  );

  // 3. The Decoder
  decoder_4to16 decoder_inst (
    .rnd_in(rnd_4bit),
    .ship_pos(ship_pos_wire)
  );

  // 4. Edge Detectors for the Push Buttons
  edge_detector p1_edge (
    .clk(clk_66mhz),
    .rst(sys_rst),
    .sig_in(pb[0]),
    .pulse_out(load_p1_pulse)
  );

  edge_detector p2_edge (
    .clk(clk_66mhz),
    .rst(sys_rst),
    .sig_in(pb[1]),
    .pulse_out(load_p2_pulse)
  );

  // --- Ship Placement & Counter Logic ---
  always_ff @(posedge clk_66mhz) begin
    if (sys_rst) begin
      p1_ships_reg  <= 16'h0000;
      p2_ships_reg  <= 16'h0000;
      p1_ship_count <= 3'b000;
      p2_ship_count <= 3'b000;
    end else begin
      
      // PLAYER 1 LOGIC 
      if (load_p1_pulse && p1_ship_count < 3'd6) begin
        // Check for collision (spot must be empty)
        if ((p1_ships_reg & ship_pos_wire) == 16'h0000) begin
          p1_ships_reg  <= p1_ships_reg | ship_pos_wire; 
          p1_ship_count <= p1_ship_count + 1'b1; 
        end
      end

      // PLAYER 2 LOGIC 
      if (load_p2_pulse && p2_ship_count < 3'd6) begin
        // Check for collision (spot must be empty)
        if ((p2_ships_reg & ship_pos_wire) == 16'h0000) begin
          p2_ships_reg  <= p2_ships_reg | ship_pos_wire; 
          p2_ship_count <= p2_ship_count + 1'b1; 
        end
      end

    end
  end

  // --- Output Mapping ---
  // Show P1 ships on the LEDs
  assign left  = p1_ships_reg[15:8];
  assign right = p1_ships_reg[7:0];

  // Turn off unused outputs
  assign {ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0} = '0;
  assign {red, green, blue} = 3'b000;
  assign txdata = 8'h00;
  assign {txclk, rxclk} = 2'b00;

endmodule

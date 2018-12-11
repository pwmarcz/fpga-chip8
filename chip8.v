`default_nettype none
`include "cpu.v"


module top(input wire CLK,
           output wire LED4);
  reg [18:0] counter;
  wire tick_60hz = counter == 0;

  parameter clk_freq = 12_000_000;
  parameter clk_divider = clk_freq / 60;

  cpu cpu0(CLK, tick_60hz, LED4);

  always @(posedge CLK) begin
    if (counter == clk_divider) begin
      counter <= 0;
    end else
      counter <= counter + 1;
  end
endmodule

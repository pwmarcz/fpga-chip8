`default_nettype none
`include "cpu.v"


module top(input wire CLK,
           output wire LED4);
  reg [17:0] counter;
  reg clk_60hz = 1;

  parameter clk_freq = 12_000_000;

  cpu cpu0(CLK, clk_60hz, LED4);

  always @(posedge CLK) begin
    if (counter == clk_freq / 120) begin
      clk_60hz <= ~clk_60hz;
      counter <= 0;
    end else
      counter <= counter + 1;
  end
endmodule

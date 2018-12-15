`default_nettype none

// https://en.wikipedia.org/wiki/Xorshift

module rng(input wire clk,
           output wire [31:0] out,
           input wire user_input);
  reg [31:0] state = 42;
  reg [31:0] next;
  assign out = state;

  always @(*) begin
    next = state;
    next = next ^ (next << 13);
    next = next ^ (next >> 17);
    next = next ^ (next << 5);

    if (user_input) begin
      next = next ^ (next << 13);
      next = next ^ (next >> 17);
      next = next ^ (next << 5);
    end
  end

  always @(posedge clk) begin
    state <= next;
  end
endmodule

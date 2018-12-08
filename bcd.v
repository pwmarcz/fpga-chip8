`default_nettype none

module bcd(input wire [7:0] abc,
           output wire [1:0] a,
           output reg [3:0] b,
           output reg [3:0] c);
  assign a = abc >= 200 ? 2 : abc >= 100 ? 1 : 0;
  wire [6:0] bc = abc - 100 * a;

  // See Hacker's Delight, Integer division by constants:
  // https://www.hackersdelight.org/divcMore.pdf
  reg [6:0] q;
  reg [3:0] r;
  always @(*) begin
    q = (bc >> 1) + (bc >> 2);
    q = q + (q >> 4);
    q = q >> 3;
    r = bc - q * 10;
    if (r < 10) begin
      b = q;
      c = r;
    end else begin
      b = q + 1;
      c = r - 10;
    end
  end
endmodule

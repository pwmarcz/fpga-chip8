`include "bcd.v"
`include "utils.v"

module top;
  reg [7:0] abc = 0;
  wire [1:0] a;
  wire [3:0] b, c;

  bcd bcd0(abc, a, b, c);

  initial begin
    $monitor($time, " %d -> %d %d %d", abc, a, b, c);
    $dumpfile(`VCD_FILE);
    $dumpvars;

    repeat (256) begin
      #1;
      utils.assert_equal(abc, a * 100 + b * 10 + c);
      utils.assert_true(a < 10 && b < 10 && c < 10);

      abc += 1;
    end
    #1 $finish;
  end
endmodule

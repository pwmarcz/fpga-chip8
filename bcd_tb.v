`include "bcd.v"

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
      if (!(a < 10 && b < 10 && c < 10))
        $fatal(1, "bad result");
      if (!(abc == a * 100 + b * 10 + c))
        $fatal(2, "bad result");

      abc += 1;
    end
    #1 $finish;
  end
endmodule

module utils;
  task assert_true;
    input x;
    begin
      if (!x) begin
        $error($time, " Assertion failed");
        $finish_and_return(1);
      end
    end
  endtask

  task assert_equal;
    input [31:0] x;
    input [31:0] y;
    begin
      if (x != y) begin
        $error($time, " %x != %x", x, y);
        $finish_and_return(1);
      end
    end
  endtask

  task timeout;
    input [31:0] n;
    begin
      #n;
      $error($time, " Timed out after %d ticks", n);
      $finish_and_return(1);
    end
  endtask
endmodule

`include "cpu.v"

module top;
  reg clk = 1;
  wire [11:0] pc;

  cpu cpu0(clk, pc);

  initial
    forever #1 clk = ~clk;

  task assert_equal;
    input [7:0] x;
    input [7:0] y;
    begin
      if (x != y)
        $fatal(1, "%x != %x", x, y);
    end
  endtask

  task reset;
    integer i;
    begin
      for (i = 0; i < 'h1000; i++)
        cpu0._mem[i] = 0;

      cpu0.addr = 0;
      cpu0.pc = 'h200;

      cpu0.state = cpu0.STATE_FETCH_HI;
    end
  endtask

  integer i;

`define run(name) \
  $display("Running %s", name); \
  reset; \
  $readmemh(name, cpu0._mem, 'h200, 'hFFF); \
  wait (cpu0.state == cpu0.STATE_IDLE);

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;

    `run("test_jump.hex");
    assert_equal(cpu0._mem['h020], 'h42);

    `run("test_call.hex");
    assert_equal(cpu0._mem['h020], 'h42);

    `run("test_add.hex");
    assert_equal(cpu0._mem['h020], 'h42);

    `run("test_mem.hex");
    assert_equal(cpu0._mem['h020], 'h42);

    `run("test_jump_v0.hex");
    assert_equal(cpu0._mem['h020], 'h42);

    `run("test_screen.hex");
    for (i = 'h100; i < 'h200; i++)
      assert_equal(cpu0._mem[i], 0);

    $finish;
  end
endmodule // Top

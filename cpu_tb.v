`include "cpu.v"
`include "utils.v"

module top;
  reg clk = 1;
  wire [11:0] pc;

  cpu cpu0(clk, pc);

  initial
    forever #1 clk = ~clk;

  initial utils.timeout(10000);

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

    `run("build/test_jump.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    `run("build/test_call.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    `run("build/test_add.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    `run("build/test_mem.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    `run("build/test_jump_v0.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    `run("build/test_screen.hex");
    for (i = 'h100; i < 'h200; i++)
      utils.assert_equal(cpu0._mem[i], 0);

    `run("build/test_bcd.hex");
    utils.assert_equal(cpu0._mem['h020], 'h42);

    $finish;
  end
endmodule // Top

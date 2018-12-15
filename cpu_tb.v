`include "cpu.v"
`include "utils.v"

module top;
  reg clk = 1;
  reg tick_60hz = 0;
  reg [15:0] keys = 0;
  wire out;

  cpu cpu0(.clk(clk),
           .tick_60hz(tick_60hz),
           .tick_next(1'b1),
           .keys(keys),
           .out(out),
           .scr_busy(1'b0),
           .scr_read(1'b0));

  initial
    forever #1 clk = ~clk;

  initial
    forever begin
      #98 tick_60hz = 1;
      #2 tick_60hz = 0;
    end

  initial utils.timeout(10000);

  task reset;
    integer i;
    begin
      for (i = 0; i < 'h1000; i++)
        cpu0.mem0.data[i] = 0;
      $readmemh("font.hex", cpu0.mem0.data, 'h030, 'h07f);

      cpu0.addr = 0;
      cpu0.pc = 'h200;
      cpu0.dt = 0;
      cpu0.st = 0;

      cpu0.state = cpu0.STATE_NEXT;
    end
  endtask

  integer i;

`define run(name) \
  $display("Running %s", name); \
  reset; \
  $readmemh(name, cpu0.mem0.data, 'h200, 'hFFF); \
  wait (cpu0.state == cpu0.STATE_STOP);

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;

    `run("build/test_jump.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    `run("build/test_call.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    `run("build/test_add.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    `run("build/test_mem.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    `run("build/test_jump_v0.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    keys <= 'b10101010;
    `run("build/test_keys.hex");
    keys <= 'b00000000;
    utils.assert_equal(cpu0.mem0.data['h020], 'b10101010);

    `run("build/test_screen.hex");
    for (i = 'h100; i < 'h200; i++)
      utils.assert_equal(cpu0.mem0.data[i], 0);

    `run("build/test_drw.hex");

    utils.assert_equal(cpu0.mem0.data['h138], 'b00100000);
    utils.assert_equal(cpu0.mem0.data['h140], 'b01100000);
    utils.assert_equal(cpu0.mem0.data['h148], 'b00100000);
    utils.assert_equal(cpu0.mem0.data['h150], 'b00100000);
    utils.assert_equal(cpu0.mem0.data['h158], 'b01110000);

    utils.assert_equal({cpu0.mem0.data['h110], cpu0.mem0.data['h111]}, 'b00110000_00110000);
    utils.assert_equal({cpu0.mem0.data['h118], cpu0.mem0.data['h119]}, 'b00111100_11110000);
    utils.assert_equal({cpu0.mem0.data['h120], cpu0.mem0.data['h121]}, 'b00111100_11110000);
    utils.assert_equal({cpu0.mem0.data['h128], cpu0.mem0.data['h129]}, 'b00111100_11110000);
    utils.assert_equal({cpu0.mem0.data['h130], cpu0.mem0.data['h131]}, 'b00110000_00110000);

    // collision
    utils.assert_equal(cpu0.mem0.data['h02f], 1);

    `run("build/test_bcd.hex");
    utils.assert_equal(cpu0.mem0.data['h020], 'h42);

    // This program should wait 5 ticks
    i = $time;
    `run("build/test_timers.hex");
    utils.assert_equal(($time - i) / 100, 5);
    utils.assert_equal(out, 1);

    $finish;
  end
endmodule // Top

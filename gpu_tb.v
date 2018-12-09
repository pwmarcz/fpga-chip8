`include "gpu.v"
`include "mem.v"
`include "utils.v"

module top;
  reg clk = 1;

  reg draw = 0;
  reg [11:0] addr;
  reg [3:0] lines;
  reg [7:0] x, y;

  wire busy, collision;

  wire mem_read;
  wire [11:0] mem_read_idx;
  wire [7:0] mem_read_byte;
  wire mem_read_ack;
  wire mem_write;
  wire [11:0] mem_write_idx;
  wire [7:0] mem_write_byte;

  mem #(.debug(1))
  mem0(clk,
       mem_read,
       mem_read_idx,
       mem_read_byte,
       mem_read_ack,
       mem_write,
       mem_write_idx,
       mem_write_byte);

  gpu gpu0(clk,
           draw, addr, lines, x, y,
           busy, collision,
           mem_read, mem_read_idx, mem_read_byte, mem_read_ack,
           mem_write, mem_write_idx, mem_write_byte);

  initial
    forever #1 clk = ~clk;

  initial utils.timeout(10000);

  integer i;
  initial begin
    for (i = 100; i < 'h300; i++)
      mem0.data[i] = 0;
    mem0.data['h42] = 'b11111111;
    mem0.data['h43] = 'b11000011;
    mem0.data['h44] = 'b11000011;
    mem0.data['h45] = 'b11000011;
    mem0.data['h46] = 'b11111111;
  end

  task run;
    input [11:0] _addr;
    input [3:0] _lines;
    input [7:0] _x, _y;
    begin
      draw <= 1;
      addr <= _addr;
      lines <= _lines;
      x <= _x;
      y <= _y;
      #2 draw <= 0;
      #2 wait (!busy);
    end
  endtask

  initial begin
    $dumpfile(`VCD_FILE);
    $dumpvars;

    #2;
    run('h42, 5, 0, 0);
    utils.assert_equal(collision, 0);
    utils.assert_equal(mem0.data['h100], 'b11111111);
    utils.assert_equal(mem0.data['h108], 'b11000011);
    utils.assert_equal(mem0.data['h110], 'b11000011);
    utils.assert_equal(mem0.data['h118], 'b11000011);
    utils.assert_equal(mem0.data['h120], 'b11111111);

    // erase
    run('h42, 5, 0, 0);
    utils.assert_equal(collision, 1);
    utils.assert_equal(mem0.data['h100], 0);
    utils.assert_equal(mem0.data['h108], 0);
    utils.assert_equal(mem0.data['h110], 0);
    utils.assert_equal(mem0.data['h118], 0);
    utils.assert_equal(mem0.data['h120], 0);

    // test clipping
    run('h42, 5, 0, 28);
    utils.assert_equal(collision, 0);
    utils.assert_equal(mem0.data['h1e0], 'b11111111);
    utils.assert_equal(mem0.data['h1e8], 'b11000011);
    utils.assert_equal(mem0.data['h1f0], 'b11000011);
    utils.assert_equal(mem0.data['h1f8], 'b11000011);
    utils.assert_equal(mem0.data['h200], 'b00000000);
    $finish;
  end
endmodule

`include "cpu.v"

module top;
  reg clk = 1;
  wire [11:0] pc;

  cpu cpu0(clk, pc);

  initial
    forever #1 clk = ~clk;

  task put_instr;
    input [11:0] addr;
    input [15:0] instr;
    begin
      cpu0._mem[addr] = instr[15:8];
      cpu0._mem[addr+1] = instr[7:0];
    end
  endtask

  initial begin
    put_instr('h100, 'h1104); // JP 104
    put_instr('h102, 'h0000); // NOP
    put_instr('h104, 'h2108); // CALL 108
    put_instr('h106, 'h00FD); // EXIT

    put_instr('h108, 'h6642); // LD V6, 42
    put_instr('h10a, 'h8760); // LD V7, V6
    put_instr('h10c, 'h3742); // SE V7, 42
    put_instr('h10e, 'h00FD); // EXIT
    put_instr('h110, 'h00EE); // RET
  end

  initial
    begin
      $dumpfile(`VCD_FILE);
      $dumpvars;
      #200 $finish;
    end
endmodule // Top

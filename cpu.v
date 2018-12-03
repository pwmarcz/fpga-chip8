module cpu(input wire clk, output wire [15:0] debug_pc);
  assign debug_pc = pc;

  reg [7:0] mem[0:'hFFF];

  reg [15:0] pc = 'h100;
  reg [7:0] v[0:15];
  reg [15:0] stack[0:15];
  reg [7:0] sp = 0;

  reg [15:0] instr;
  wire [3:0] a = instr[15:12];
  wire [3:0] x = instr[11:8];
  wire [7:0] yz = instr[7:0];
  wire [11:0] xyz = instr[11:0];

  wire [7:0] vx = v[x];

  reg [2:0] load_cycle = 1;
  reg [7:0] loaded;
  reg run_instr = 0;

  task skip;
    begin
      $display($time, " skip");
      pc <= pc + 2;
    end
  endtask

  always @(posedge clk) begin
    case (load_cycle)
      1: begin
        loaded <= mem[pc];
        pc <= pc + 1;
        load_cycle <= 2;
      end
      2: begin
        instr[15:8] <= loaded;
        loaded <= mem[pc];
        pc <= pc + 1;
        load_cycle <= 3;
      end
      3: begin
        instr[7:0] <= loaded;
        load_cycle <= 0;
        run_instr <= 1;
      end
    endcase

    if (run_instr) begin
      $display($time, " run [%x] %x", pc - 16'sd2, instr);

      run_instr <= 0;
      load_cycle <= 1;
      case (a)
        4'h0: begin
          if (xyz == 'h0EE) begin
            $display($time, " instr: RET");
            pc <= stack[sp - 1];
          end else if (xyz == 'h0FD) begin
            $display($time, " instr: EXIT");
            load_cycle <= 0;
          end else begin
            $display($time, " instr: NOP");
          end
        end
        4'h1: begin
          $display($time, " instr: JP %x", xyz);
          pc <= xyz;
        end
        4'h2: begin
          $display($time, " instr: CALL %x", xyz);
          pc <= xyz;
          stack[sp] <= pc;
          sp <= sp + 1;
        end
        4'h3: begin
          $display($time, " instr: SE V%x, %x", x, yz);
          if (vx == yz)
            skip;
        end
        4'h4: begin
          $display($time, " instr: SNE V%x, %x", x, yz);
          if (vx != yz)
            skip;
        end
        4'h6: begin
          $display($time, " instr: LD V%x, %x", x, yz);
          v[x] <= yz;
        end
      endcase
    end
  end
endmodule

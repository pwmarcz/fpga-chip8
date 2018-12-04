module cpu(input wire clk, output wire [11:0] debug_pc);
  assign debug_pc = pc;

  // Memory
  reg [7:0] _mem[0:'hFFF];
  reg mem_read = 0;
  reg mem_read_ack = 0;
  reg [11:0] mem_read_idx;
  reg [7:0] mem_read_byte;
  reg mem_write = 0;
  reg [11:0] mem_write_idx;
  reg [7:0] mem_write_byte;
  always @(posedge clk) begin
    mem_read_ack <= 0;
    if (mem_read) begin
      $display($time, " load [%x] = %x", mem_read_idx, _mem[mem_read_idx]);
      mem_read_byte <= _mem[mem_read_idx];
      mem_read_ack <= 1;
    end
    if (mem_write) begin
      $display($time, " store [%x] = %x", mem_write_idx, mem_write_byte);
      _mem[mem_write_idx] <= mem_write_byte;
    end
  end

  localparam
    STATE_IDLE = 0,
    STATE_FETCH_HI = 1,
    STATE_FETCH_LO = 2,
    STATE_POP_HI = 3,
    STATE_POP_LO = 4,
    STATE_PUSH_HI = 5,
    STATE_PUSH_LO = 6,
    STATE_DECODE = 7;

  reg[3:0] state = STATE_FETCH_HI;

  // Memory loads and stores
  always @(*) begin
    mem_read = 0;
    mem_write = 0;
    mem_read_idx = 0;

    case (state)
      STATE_FETCH_HI: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = pc[11:0];
      end
      STATE_FETCH_LO: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = pc[11:0] + 1;
      end
      STATE_POP_HI: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = 2 * sp;
      end
      STATE_POP_LO: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = 2 * sp + 1;
      end
      STATE_PUSH_HI: begin
        mem_write = 1;
        mem_write_idx = 2 * sp - 2;
        mem_write_byte = {4'b0, ret_pc[11:8]};
      end
      STATE_PUSH_LO: begin
        mem_write = 1;
        mem_write_idx = 2 * sp - 1;
        mem_write_byte = ret_pc[7:0];
      end
    endcase
  end

  // Registers
  reg [11:0] pc = 'h100;
  reg [11:0] ret_pc;
  reg [7:0] v[0:15];
  reg [3:0] sp = 0;

  // Instruction
  reg [15:0] instr;
  wire [3:0] a = instr[15:12];
  wire [3:0] x = instr[11:8];
  wire [7:0] yz = instr[7:0];
  wire [11:0] xyz = instr[11:0];

  wire [7:0] vx, vy;

  always @(posedge clk)
    case (state)
      STATE_FETCH_HI:
        if (mem_read_ack) begin
          instr[15:8] <= mem_read_byte;
          state <= STATE_FETCH_LO;
        end
      STATE_FETCH_LO:
        if (mem_read_ack) begin
          instr[7:0] <= mem_read_byte;
          state <= STATE_DECODE;
          // Fetch vx, vy already
          vx <= v[instr[11:8]];
          vy <= v[mem_read_byte[7:4]];
        end
      STATE_POP_HI:
        if (mem_read_ack) begin
          pc[11:8] <= mem_read_byte[3:0];
          state <= STATE_POP_LO;
        end
      STATE_POP_LO:
        if (mem_read_ack) begin
          pc[7:0] <= mem_read_byte;
          state <= STATE_FETCH_HI;
        end
      STATE_PUSH_HI:
        state <= STATE_PUSH_LO;
      STATE_PUSH_LO:
        state <= STATE_FETCH_HI;
      STATE_DECODE: begin
        pc <= pc + 2;
        state <= STATE_FETCH_HI;

        case (a)
          4'h0: begin
            if (xyz == 'h0EE) begin
              $display($time, " instr: RET");
              sp <= sp - 1;
              state <= STATE_POP_HI;
            end else if (xyz == 'h0FD) begin
              $display($time, " instr: EXIT");
              state <= STATE_IDLE;
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
            sp <= sp + 1;
            state <= STATE_PUSH_HI;
            ret_pc <= pc + 2;
            pc <= xyz;
          end
          4'h3: begin
            $display($time, " instr: SE V%x, %x", x, yz);
            if (vx == yz)
              pc <= pc + 4;
          end
          4'h4: begin
            $display($time, " instr: SNE V%x, %x", x, yz);
            if (vx != yz)
              pc <= pc + 4;
          end
          4'h6: begin
            $display($time, " instr: LD V%x, %x", x, yz);
            v[x] <= yz;
          end
          default: // TODO
            ;
        endcase
      end
    endcase

endmodule

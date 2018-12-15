`default_nettype none

`include "bcd.v"
`include "mem.v"
`include "gpu.v"
`include "rng.v"

module cpu(input wire clk,
           input wire tick_60hz,
           input wire tick_next,
           input wire [15:0] keys,
           output wire out,
           input wire scr_busy,
           input wire scr_read,
           input wire [7:0] scr_read_idx,
           output reg [7:0] scr_read_byte,
           output reg scr_read_ack);
  assign out = st != 0;

  // Press 0 + F to activate debug mode
  wire debug_mode = (keys == 16'b1000_0000_0000_0010);

  // Memory map:
  // 000..01F: stack (16 x 2 bytes)
  // 020..02F: registers (16 x 1 byte)
  // 030..07F: font (16 x 5 bytes)
  // 100..1FF: screen (32 lines x 8 bytes)

  // Memory

  reg mem_read = 0;
  reg [11:0] mem_read_idx;
  wire [7:0] mem_read_byte;
  wire mem_read_ack;

  reg mem_write = 0;
  reg [11:0] mem_write_idx;
  reg [7:0] mem_write_byte;

  mem mem0(clk,
           mem_read, mem_read_idx, mem_read_byte, mem_read_ack,
           mem_write, mem_write_idx, mem_write_byte);

  localparam
    STATE_NEXT = 0,
    STATE_FETCH_HI = 1,
    STATE_FETCH_LO = 2,
    STATE_POP_HI = 3,
    STATE_POP_LO = 4,
    STATE_PUSH_HI = 5,
    STATE_PUSH_LO = 6,
    STATE_DECODE = 7,
    STATE_TRANSFER_LOAD = 8,
    STATE_TRANSFER_STORE = 9,
    STATE_CLEAR = 10,
    STATE_LOAD_VX = 11,
    STATE_LOAD_VY = 12,
    STATE_LOAD_V0 = 13,
    STATE_STORE_VX = 14,
    STATE_STORE_CARRY = 15,
    STATE_BCD_1 = 16,
    STATE_BCD_2 = 17,
    STATE_BCD_3 = 18,
    STATE_GPU = 19,
    // ...
    STATE_STOP = 31;

  reg[4:0] state = STATE_NEXT;

  // BCD
  wire [1:0] bcd_1;
  wire [3:0] bcd_2, bcd_3;
  bcd bcd0(vx, bcd_1, bcd_2, bcd_3);

  // GPU
  reg gpu_draw = 0;
  reg [11:0] gpu_addr;
  reg [3:0] gpu_lines;
  reg [5:0] gpu_x;
  reg [4:0] gpu_y;
  wire gpu_busy;
  wire gpu_collision;
  wire gpu_read;
  wire [11:0] gpu_read_idx;
  wire gpu_write;
  wire [11:0] gpu_write_idx;
  wire [7:0] gpu_write_byte;

  gpu gpu0(.clk(clk),
           .draw(gpu_draw),
           .addr(gpu_addr),
           .lines(gpu_lines),
           .x(gpu_x),
           .y(gpu_y),
           .busy(gpu_busy),
           .collision(gpu_collision),
           .mem_read(gpu_read),
           .mem_read_idx(gpu_read_idx),
           .mem_read_byte(mem_read_byte), // pass-through
           .mem_read_ack(mem_read_ack), // pass-through
           .mem_write(gpu_write),
           .mem_write_idx(gpu_write_idx),
           .mem_write_byte(gpu_write_byte));

  // Memory loads and stores
  always @(*) begin
    mem_read = 0;
    mem_write = 0;
    mem_read_idx = 0;

    case (state)
      STATE_NEXT, STATE_STOP: begin
        mem_read = scr_read;
        mem_read_idx = {4'h1, scr_read_idx};
        if (debug_mode) begin
          if (scr_read_idx < 'h30)
            // Show stack and registers
            mem_read_idx = {4'h0, scr_read_idx};
          else
            // Show beginning of program memory
            mem_read_idx = {4'h2, scr_read_idx - 8'h30};
        end
      end
      STATE_FETCH_HI: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = pc[11:0];
      end
      STATE_FETCH_LO: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = pc[11:0] + 1;
      end
      STATE_LOAD_VX: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = 'h20 + {8'b0, x};
      end
      STATE_LOAD_VY: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = 'h20 + {8'b0, y};
      end
      STATE_LOAD_V0: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = 'h20;
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
      STATE_TRANSFER_LOAD: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = transfer_src_addr + {4'b0, transfer_counter};
      end
      STATE_TRANSFER_STORE: begin
        mem_write = 1;
        mem_write_idx = transfer_dest_addr + {4'b0, transfer_counter};
        mem_write_byte = mem_read_byte;
      end
      STATE_CLEAR: begin
        mem_write = 1;
        mem_write_idx = transfer_dest_addr + {4'b0, transfer_counter};
        mem_write_byte = 0;
      end
      STATE_STORE_VX: begin
        mem_write = 1;
        mem_write_idx = 'h20 + {8'b0, x};
        mem_write_byte = new_vx;
      end
      STATE_STORE_CARRY: begin
        mem_write = 1;
        mem_write_idx = 'h2F;
        mem_write_byte = {7'b0, carry};
      end
      STATE_BCD_1: begin
        mem_write = 1;
        mem_write_idx = addr;
        mem_write_byte = {6'b0, bcd_1};
      end
      STATE_BCD_2: begin
        mem_write = 1;
        mem_write_idx = addr + 1;
        mem_write_byte = {4'b0, bcd_2};
      end
      STATE_BCD_3: begin
        mem_write = 1;
        mem_write_idx = addr + 2;
        mem_write_byte = {4'b0, bcd_3};
      end
      STATE_GPU: begin
        mem_read = gpu_read;
        mem_read_idx = gpu_read_idx;
        mem_write = gpu_write;
        mem_write_idx = gpu_write_idx;
        mem_write_byte = gpu_write_byte;
      end
    endcase
  end

  // Registers
  reg [11:0] pc = 'h200;
  reg [11:0] ret_pc;
  reg [11:0] addr = 0;
  reg [11:0] transfer_src_addr, transfer_dest_addr;
  reg [7:0] transfer_counter;
  reg [3:0] sp = 0;
  reg [7:0] dt = 0;
  reg [7:0] st = 0;

  // Instruction
  reg [15:0] instr;
  wire [3:0] a = instr[15:12];
  wire [3:0] x = instr[11:8];
  wire [3:0] y = instr[7:4];
  wire [3:0] z = instr[3:0];
  wire [7:0] yz = instr[7:0];
  wire [11:0] xyz = instr[11:0];

  reg [7:0] vx, vy, new_vx;
  reg carry;
  wire needs_carry = a == 'h8 && (z == 'h4 || z == 'h5 || z == 'h6 || z == 'h7 || z == 'hE);

  // Can go to the next instruction (for rate limiting by tick_next)
  reg next = 1;

  wire [31:0] rng_state;
  rng rng(.clk(clk), .out(rng_state), .user_input(&keys));

  integer i;

  always @(posedge clk) begin
    if (tick_60hz) begin
      $display($time, " tick, dt = %x st = %x", dt, st);
      if (dt != 0)
        dt <= dt - 1;
      if (st != 0)
        st <= st - 1;
    end

    if (tick_next)
      next <= 1;

    scr_read_ack <= 0;

    case (state)
      STATE_NEXT, STATE_STOP: begin
        if (scr_read && mem_read_ack) begin
          scr_read_ack <= 1;
          scr_read_byte <= mem_read_byte;
        end
        if (state == STATE_NEXT && !scr_busy && next) begin
          next <= 0;
          state <= STATE_FETCH_HI;
        end
      end
      STATE_FETCH_HI:
        if (mem_read_ack) begin
          instr[15:8] <= mem_read_byte;
          state <= STATE_FETCH_LO;
        end
      STATE_FETCH_LO:
        if (mem_read_ack) begin
          instr[7:0] <= mem_read_byte;
          if (a == 'hB)
            // JP V0, xyz
            state <= STATE_LOAD_V0;
          else
            // TODO check if necessary?
            state <= STATE_LOAD_VX;
        end
      STATE_LOAD_VX:
        if (mem_read_ack) begin
          vx <= mem_read_byte;
          // TODO check if necessary?
          state <= STATE_LOAD_VY;
        end
      STATE_LOAD_VY:
        if (mem_read_ack) begin
          vy <= mem_read_byte;
          state <= STATE_DECODE;
        end
      STATE_LOAD_V0:
        if (mem_read_ack) begin
          vx <= mem_read_byte;
          state <= STATE_DECODE;
        end
      STATE_STORE_VX:
        state <= needs_carry ? STATE_STORE_CARRY : STATE_NEXT;
      STATE_STORE_CARRY:
        state <= STATE_NEXT;
      STATE_POP_HI:
        if (mem_read_ack) begin
          pc[11:8] <= mem_read_byte[3:0];
          state <= STATE_POP_LO;
        end
      STATE_POP_LO:
        if (mem_read_ack) begin
          pc[7:0] <= mem_read_byte;
          state <= STATE_NEXT;
        end
      STATE_PUSH_HI:
        state <= STATE_PUSH_LO;
      STATE_PUSH_LO:
        state <= STATE_NEXT;
      STATE_TRANSFER_LOAD:
        if (mem_read_ack)
          state <= STATE_TRANSFER_STORE;
      STATE_TRANSFER_STORE:
        if (transfer_counter == 0)
          state <= STATE_NEXT;
        else begin
          transfer_counter <= transfer_counter - 1;
          state <= STATE_TRANSFER_LOAD;
        end
      STATE_CLEAR:
        if (transfer_counter == 0)
          state <= STATE_NEXT;
        else begin
          transfer_counter <= transfer_counter - 1;
        end
      STATE_BCD_1:
        state <= STATE_BCD_2;
      STATE_BCD_2:
        state <= STATE_BCD_3;
      STATE_BCD_3:
        state <= STATE_NEXT;
      STATE_GPU:
        begin
          gpu_draw <= 0;
          if (!gpu_draw && !gpu_busy) begin
            carry <= gpu_collision;
            state <= STATE_STORE_CARRY;
          end
        end
      STATE_DECODE: begin
        $display($time, " run [%x] %x", pc, instr);
        pc <= pc + 2;
        state <= STATE_NEXT;

        case (a)
          4'h0:
            case (xyz)
              'h0E0: begin
                $display($time, " instr: CLS");
                transfer_dest_addr <= 'h100;
                transfer_counter <= 'hFF;
                state <= STATE_CLEAR;
              end
              'h0EE: begin
                $display($time, " instr: RET");
                sp <= sp - 1;
                state <= STATE_POP_HI;
              end
              'h0FD: begin
                $display($time, " instr: EXIT");
                state <= STATE_STOP;
              end
              default: begin
                $display($time, " instr: NOP");
              end
            endcase
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
          4'h5: begin
            $display($time, " instr: SE V%x, V%x", x, y);
            if (vx == vy)
              pc <= pc + 4;
          end
          4'h9: begin
            $display($time, " instr: SNE V%x, V%x", x, y);
            if (vx != vy)
              pc <= pc + 4;
          end
          4'h6: begin
            $display($time, " instr: LD V%x, %x", x, yz);
            new_vx <= yz;
            state <= STATE_STORE_VX;
          end
          4'h7: begin
            $display($time, " instr: ADD V%x, %x", x, yz);
            new_vx <= vx + yz;
            state <= STATE_STORE_VX;
          end
          4'h8: begin
            case (z)
              4'h0: begin
                $display($time, " instr: LD V%x, V%x", x, y);
                new_vx <= vy;
                state <= STATE_STORE_VX;
              end
              4'h1: begin
                $display($time, " instr: OR V%x, V%x", x, y);
                new_vx <= vx | vy;
                state <= STATE_STORE_VX;
              end
              4'h2: begin
                $display($time, " instr: AND V%x, V%x", x, y);
                new_vx <= vx & vy;
                state <= STATE_STORE_VX;
              end
              4'h3: begin
                $display($time, " instr: XOR V%x, V%x", x, y);
                new_vx <= vx ^ vy;
                state <= STATE_STORE_VX;
              end
              4'h4: begin
                $display($time, " instr: ADD V%x, V%x", x, y);
                new_vx <= vx + vy;
                carry <= ((vx + vy) >= 'h100) ? 1 : 0;
                state <= STATE_STORE_VX;
              end
              4'h5: begin
                $display($time, " instr: SUB V%x, V%x", x, y);
                new_vx <= vx - vy;
                carry <= (vx > vy) ? 1 : 0;
                state <= STATE_STORE_VX;
              end
              4'h6: begin
                $display($time, " instr: SHR V%x", x);
                new_vx <= vx >> 1;
                carry <= vx[0];
                state <= STATE_STORE_VX;
              end
              4'h7: begin
                $display($time, " instr: SUBN V%x, V%x", x, y);
                new_vx <= vy - vx;
                carry <= (vy > vx) ? 1 : 0;
                state <= STATE_STORE_VX;
              end
              4'hE: begin
                $display($time, " instr: SHL V%x", x);
                new_vx <= vx << 1;
                carry <= vx[7];
                state <= STATE_STORE_VX;
              end
              default: ;
            endcase
          end
          4'hA: begin
            $display($time, " instr: LD I, %x", xyz);
            addr <= xyz;
          end
          4'hB: begin
            $display($time, " instr: JP V0, %x", xyz);
            // STATE_LOAD_V0 loaded V0 into vx
            pc <= xyz + {4'b0, vx};
          end
          4'hC: begin
            $display($time, " instr: RND V%x, %x", x, yz);
            new_vx <= rng_state[15:8] & yz;
            state <= STATE_STORE_VX;
          end
          4'hD: begin
            $display($time, " instr: DRW V%x, V%x, %x", x, y, z);
            gpu_draw <= 1;
            gpu_addr <= addr;
            gpu_lines <= z;
            gpu_x <= vx[5:0];
            gpu_y <= vy[4:0];
            state <= STATE_GPU;
          end
          4'hE: begin
            case (yz)
              8'h9E: begin
                $display($time, " instr: SKP V%x", x);
                // In debug mode, assume no keys are pressed.
                if (!debug_mode && keys[vx[3:0]])
                  pc <= pc + 4;
              end
              8'hA1: begin
                $display($time, " instr: SKNP V%x", x);
                // In debug mode, assume no keys are pressed.
                if (debug_mode || !keys[vx[3:0]])
                  pc <= pc + 4;
              end
              default: ;
            endcase
          end
          4'hF: begin
            case (yz)
              8'h07: begin
                $display($time, " instr: LD V%x, DT", x);
                new_vx <= dt;
                state <= STATE_STORE_VX;
              end
              8'h0A: begin
                $display($time, " instr: LD V%x, K", x);
                if (keys == 0)
                  pc <= pc;
                else begin
                  for (i = 15; i >= 0; i--)
                    if (keys[i])
                      vx <= i[7:0];
                end
              end
              8'h15: begin
                $display($time, " instr: LD DT, V%x", x);
                dt <= vx;
              end
              8'h18: begin
                $display($time, " instr: LD ST, V%x", x);
                st <= vx;
              end
              8'h1E: begin
                $display($time, " instr: ADD I, V%x", x);
                addr <= addr + {4'b0, vx};
              end
              8'h29: begin
                $display($time, " instr: LD F, V%x", x);
                addr <= 'h30 + vx * 5;
              end
              8'h33: begin
                $display($time, " instr: LD B, V%x", x);
                state <= STATE_BCD_1;
              end
              8'h55: begin
                $display($time, " instr: LD [I], V%x", x);
                transfer_src_addr <= 'h020;
                transfer_dest_addr <= addr;
                transfer_counter <= {4'b0, x};
                state <= STATE_TRANSFER_LOAD;
              end
              8'h65: begin
                $display($time, " instr: LD V%x, [I]", x);
                transfer_src_addr <= addr;
                transfer_dest_addr <= 'h020;
                transfer_counter <= {4'b0, x};
                state <= STATE_TRANSFER_LOAD;
              end
              default: ;
            endcase
          end
        endcase
      end
    endcase
  end
endmodule

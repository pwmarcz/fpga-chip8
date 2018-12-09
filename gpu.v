`default_nettype none

module gpu(input wire clk,
           input wire draw,
           input wire [11:0] addr,
           input wire [3:0] lines,
           input wire [7:0] x,
           input wire [7:0] y,

           output wire busy,
           output wire collision,

           output reg mem_read,
           output reg [11:0] mem_read_idx,
           input wire [7:0] mem_read_byte,
           input wire mem_read_ack,
           output reg mem_write,
           output reg [11:0] mem_write_idx,
           output reg [7:0] mem_write_byte);

  localparam WIDTH = 8;
  localparam HEIGHT = 32;

  localparam
    STATE_IDLE = 0,
    STATE_LOAD_SPRITE = 1,
    STATE_LOAD_MEM = 2,
    STATE_STORE_MEM = 3;

  reg [3:0] lines_left;
  reg [11:0] sprite_addr;
  reg [11:0] screen_addr;
  reg [7:0] sprite_byte, screen_byte;

  reg [3:0] state = STATE_IDLE;
  assign busy = state != STATE_IDLE;

  // Memory access
  always @(*) begin
    mem_read = 0;
    mem_read_idx = 0;
    mem_write = 0;
    mem_write_idx = 0;
    mem_write_byte = 0;

    case (state)
      STATE_LOAD_SPRITE: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = sprite_addr;
      end
      STATE_LOAD_MEM: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = screen_addr;
      end
      STATE_STORE_MEM: begin
        mem_write = 1;
        mem_write_idx = screen_addr;
        mem_write_byte = screen_byte;
      end
    endcase
  end

  always @(posedge clk)
    case (state)
      STATE_IDLE:
        if (draw) begin
          if (y + lines <= HEIGHT)
            lines_left <= lines - 1;
          else
            lines_left <= HEIGHT - y - 1;
          sprite_addr <= addr;
          screen_addr <= 12'h100 + y * WIDTH;
          state <= STATE_LOAD_SPRITE;
        end
      STATE_LOAD_SPRITE:
        if (mem_read_ack) begin
          sprite_byte <= mem_read_byte;
          state <= STATE_LOAD_MEM;
        end
      STATE_LOAD_MEM:
        if (mem_read_ack) begin
          screen_byte <= mem_read_byte ^ sprite_byte;
          state <= STATE_STORE_MEM;
        end
      STATE_STORE_MEM:
        if (lines_left == 0)
          state <= STATE_IDLE;
        else begin
          sprite_addr <= sprite_addr + 1;
          screen_addr <= screen_addr + WIDTH;
          lines_left <= lines_left - 1;
          state <= STATE_LOAD_SPRITE;
        end
    endcase
endmodule

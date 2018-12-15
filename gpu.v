`default_nettype none

module gpu(input wire clk,
           input wire draw,
           input wire [11:0] addr,
           input wire [3:0] lines,
           input wire [5:0] x,
           input wire [4:0] y,

           output wire busy,
           output reg collision,

           output reg mem_read,
           output reg [11:0] mem_read_idx,
           input wire [7:0] mem_read_byte,
           input wire mem_read_ack,
           output reg mem_write,
           output reg [11:0] mem_write_idx,
           output reg [7:0] mem_write_byte);

  localparam WIDTH = 8;

  localparam
    STATE_IDLE = 0,
    STATE_LOAD_SPRITE = 1,
    STATE_LOAD_MEM_LEFT = 2,
    STATE_STORE_MEM_LEFT = 3,
    STATE_LOAD_MEM_RIGHT = 4,
    STATE_STORE_MEM_RIGHT = 5;

  reg [3:0] lines_left;
  reg [3:0] shift;
  reg use_right;
  reg [11:0] sprite_addr;
  reg [7:0] screen_addr;
  reg [15:0] sprite_word;
  reg [7:0] screen_byte;

  wire [11:0] mem_idx_left = {4'h1, screen_addr};
  // Wrap the last 3 bits to wrap a line correctly (a line is 8 bytes)
  wire [11:0] mem_idx_right = {4'h1, screen_addr[7:3], screen_addr[2:0] + 1'b1};

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
      STATE_LOAD_MEM_LEFT: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = mem_idx_left;
      end
      STATE_LOAD_MEM_RIGHT: if (!mem_read_ack) begin
        mem_read = 1;
        mem_read_idx = mem_idx_right;
      end
      STATE_STORE_MEM_LEFT: begin
        mem_write = 1;
        mem_write_idx = mem_idx_left;
        mem_write_byte = screen_byte;
        $display($time, " gpu: [%x] = %b", mem_idx_left, screen_byte);
      end
      STATE_STORE_MEM_RIGHT:
        if (use_right) begin
          mem_write = 1;
          mem_write_idx = mem_idx_right;
          mem_write_byte = screen_byte;
          $display($time, " gpu: [%x] = %b", mem_idx_right, screen_byte);
        end
    endcase
  end

  always @(posedge clk)
    case (state)
      STATE_IDLE:
        if (draw) begin
          $display($time, " gpu: draw %x (%x lines) at (%x, %x)",
                   addr, lines, x, y);
          lines_left <= lines - 1;
          sprite_addr <= addr;
          screen_addr <= y * WIDTH + x / 8;
          shift <= x % 8;
          use_right <= (x % 8 != 0);
          collision <= 0;
          state <= STATE_LOAD_SPRITE;
        end
      STATE_LOAD_SPRITE:
        if (mem_read_ack) begin
          sprite_word <= {mem_read_byte, 8'b0} >> shift;
          state <= STATE_LOAD_MEM_LEFT;
        end
      STATE_LOAD_MEM_LEFT:
        if (mem_read_ack) begin
          screen_byte <= mem_read_byte ^ sprite_word[15:8];
          collision <= collision | |(mem_read_byte & sprite_word[15:8]);
          state <= STATE_STORE_MEM_LEFT;
        end
      STATE_STORE_MEM_LEFT:
        state <= STATE_LOAD_MEM_RIGHT;
      STATE_LOAD_MEM_RIGHT:
        if (mem_read_ack) begin
          if (use_right) begin
            screen_byte <= mem_read_byte ^ sprite_word[7:0];
            collision <= collision | |(mem_read_byte & sprite_word[7:0]);
          end
          state <= STATE_STORE_MEM_RIGHT;
        end
      STATE_STORE_MEM_RIGHT:
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

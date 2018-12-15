`default_nettype none

module screen_bridge(input wire clk,
                     input wire tick_60hz,
                     input wire read,
                     input wire [5:0] row_idx,
                     input wire [6:0] column_idx,
                     output reg [7:0] data,
                     output reg ack,

                     output wire scr_busy,
                     output wire scr_read,
                     output wire [7:0] scr_read_idx,
                     input wire [7:0] scr_read_byte,
                     input wire scr_read_ack);

  reg [7:0] buffer [0:1023];
  wire [9:0] buffer_read_idx = {row_idx[2:0], column_idx};

  // 8 x 4 rectangle (scanned in horizontal stripes, output in vertical ones)
  reg [7:0] rect [0:3];
  // Num of rectangle on screen
  reg [5:0] rect_num = 0;
  // Index of byte (horizontal stripe) in rectangle
  reg [1:0] rect_scan_idx = 0;

  // Index of vertical stripe in rectangle (16 double-pixel stripes)
  reg [3:0] rect_write_idx = 0;

  assign scr_read = state == STATE_READ_RECT && !scr_read_ack;
  assign scr_read_idx = {rect_num[5:3], rect_scan_idx, rect_num[2:0]};
  wire [9:0] buffer_write_idx = {rect_num, rect_write_idx};

  wire [7:0] buffer_write_byte = {rect[3][7], rect[3][7],
                                  rect[2][7], rect[2][7],
                                  rect[1][7], rect[1][7],
                                  rect[0][7], rect[0][7]};

  localparam
    STATE_READ_RECT = 0,
    STATE_WRITE_RECT = 1,
    STATE_WAIT = 2;

  assign scr_busy = state != STATE_WAIT;

  reg [1:0] state = STATE_READ_RECT;

  reg draw_next = 0;

  always @(posedge clk) begin
    if (tick_60hz)
      draw_next <= 1;

    ack <= 0;
    if (read) begin
      ack <= 1;
      data <= buffer[buffer_read_idx];
    end

    case (state)
      STATE_READ_RECT: begin
        if (scr_read_ack) begin
          rect[rect_scan_idx] <= scr_read_byte;
          rect_scan_idx <= rect_scan_idx + 1;
          if (rect_scan_idx == 'b11) begin
            state <= STATE_WRITE_RECT;
          end
        end
      end
      STATE_WRITE_RECT: begin
        buffer[buffer_write_idx] <= buffer_write_byte;
        rect_write_idx <= rect_write_idx + 1;
        if (rect_write_idx[0]) begin
          rect[0] <= rect[0] << 1;
          rect[1] <= rect[1] << 1;
          rect[2] <= rect[2] << 1;
          rect[3] <= rect[3] << 1;
        end
        if (rect_write_idx == 'b1111) begin
          rect_num <= rect_num + 1;
          if (rect_num == 'b111111)
            state <= STATE_WAIT;
          else
            state <= STATE_READ_RECT;
        end
      end
      STATE_WAIT:
        if (draw_next) begin
          draw_next <= 0;
          state <= STATE_READ_RECT;
        end
    endcase
  end
endmodule

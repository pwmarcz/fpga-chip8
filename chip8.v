`default_nettype none
`include "cpu.v"
`include "screen_bridge.v"
`include "fpga-tools/components/oled.v"

module top(input wire CLK,
           output wire LED,
           output wire PIN_12,
           output wire PIN_11,
           output wire PIN_10,
           output wire PIN_9,
           output wire PIN_8,
           output wire PIN_7,
           output wire PIN_6,
           output wire PIN_5);

  assign PIN_12 = 1; // oled: VCC
  assign PIN_11 = 0; // oled: GND
  assign PIN_10 = 0; // oled: NC

  reg [18:0] counter;
  wire tick_60hz = counter == 0;

  parameter clk_freq = 16_000_000;
  parameter clk_divider = clk_freq / 60;

  always @(posedge CLK) begin
    if (counter == clk_divider) begin
      counter <= 0;
    end else
      counter <= counter + 1;
  end

  wire       oled_read;
  wire [5:0] oled_row_idx;
  wire [6:0] oled_column_idx;
  wire [7:0] oled_data;
  wire       oled_ack;

  wire scr_read;
  wire [7:0] scr_read_idx;
  wire [7:0] scr_read_byte;
  wire scr_read_ack;

  cpu cpu0(.clk(CLK),
           .tick_60hz(tick_60hz),
           .out(LED),
           .scr_read(scr_read),
           .scr_read_idx(scr_read_idx),
           .scr_read_byte(scr_read_byte),
           .scr_read_ack(scr_read_ack));

  oled o(.clk(CLK),
         .pin_din(PIN_9),
         .pin_clk(PIN_8),
         .pin_cs(PIN_7),
         .pin_dc(PIN_6),
         .pin_res(PIN_5),
         .read(oled_read),
         .row_idx(oled_row_idx),
         .column_idx(oled_column_idx),
         .data(oled_data),
         .ack(oled_ack));

  screen_bridge sb(.clk(CLK),
                   .tick_60hz(tick_60hz),
                   .read(oled_read),
                   .row_idx(oled_row_idx),
                   .column_idx(oled_column_idx),
                   .data(oled_data),
                   .ack(oled_ack),

                   .scr_read(scr_read),
                   .scr_read_idx(scr_read_idx),
                   .scr_read_byte(scr_read_byte),
                   .scr_read_ack(scr_read_ack));
endmodule

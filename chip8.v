`default_nettype none
`include "cpu.v"
`include "fpga-tools/components/oled.v"

module pattern(input wire clk,
               input wire tick_60hz,
               input wire read,
               input wire [5:0] row_idx,
               input wire [6:0] column_idx,
               output reg [7:0] data,
               output reg ack);

  reg [5:0] counter;
  wire [4:0] offset = counter[5:2];
  wire page_odd = row_idx & 1;
  wire column_field_odd = (((column_idx + offset) >> 3) & 1);
  wire field_black = page_odd ^ column_field_odd;
  wire column_odd = (column_idx + offset) & 1;

  always @(posedge clk) begin
    if (tick_60hz)
      counter <= counter + 1;
    ack <= 0;
    if (read) begin
      ack <= 1;
      if (field_black)
        data <= 8'b00000000;
      else if (column_odd)
        data <= 8'b10101010;
      else
        data <= 8'b01010101;
    end
  end
endmodule

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

  cpu cpu0(CLK, tick_60hz, LED);

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

  pattern p(.clk(CLK),
            .tick_60hz(tick_60hz),
            .read(oled_read),
            .row_idx(oled_row_idx),
            .column_idx(oled_column_idx),
            .data(oled_data),
            .ack(oled_ack));
endmodule

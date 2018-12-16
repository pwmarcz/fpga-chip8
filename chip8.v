`default_nettype none
`include "cpu.v"
`include "screen_bridge.v"
`include "fpga-tools/components/oled.v"
`include "fpga-tools/components/keypad.v"

module pullup(output wire pin, output wire d_in);
  SB_IO #(.PIN_TYPE(6'b1), .PULLUP(1'b1)) io(.PACKAGE_PIN(pin), .D_IN_0(d_in));
endmodule

module top(input wire CLK,
           output wire LED,
           // Turbo mode
           input wire PIN_1,
           // Keypad:
           output wire PIN_22,
           output wire PIN_21,
           output wire PIN_20,
           output wire PIN_19,
           input wire PIN_18,
           input wire PIN_17,
           input wire PIN_16,
           input wire PIN_15,
           // OLED:
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

  // Turbo mode: connect pin to ground to bypass instruction rate limit.
  wire turbo_mode;
  pullup pu_turbo_mode(PIN_1, turbo_mode);

  reg [18:0] counter_60hz, counter_next;
  wire tick_60hz = counter_60hz == 0;
  wire tick_next = (counter_next == 0 || turbo_mode == 0);

  parameter clk_freq = 16_000_000;
  parameter clk_divider_60hz = clk_freq / 60;

  parameter instr_freq = 500;
  parameter clk_divider_next = clk_freq / instr_freq;

  always @(posedge CLK) begin
    counter_60hz <= counter_60hz + 1;
    if (counter_60hz == clk_divider_60hz)
      counter_60hz <= 0;

    counter_next <= counter_next + 1;
    if (counter_next == clk_divider_next)
      counter_next <= 0;
  end

  wire       oled_read;
  wire [5:0] oled_row_idx;
  wire [6:0] oled_column_idx;
  wire [7:0] oled_data;
  wire       oled_ack;

  wire scr_busy;
  wire scr_read;
  wire [7:0] scr_read_idx;
  wire [7:0] scr_read_byte;
  wire scr_read_ack;

  cpu cpu0(.clk(CLK),
           .tick_60hz(tick_60hz),
           .tick_next(tick_next),
           .keys(cpu_keys),
           .out(LED),
           .scr_busy(scr_busy),
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

                   .scr_busy(scr_busy),
                   .scr_read(scr_read),
                   .scr_read_idx(scr_read_idx),
                   .scr_read_byte(scr_read_byte),
                   .scr_read_ack(scr_read_ack));


  wire [3:0] row_pins;
  wire [3:0] column_pins;
  wire [15:0] keys;
  wire [15:0] cpu_keys;

  assign cpu_keys = {keys[15],  // F
                     keys[11],  // E
                     keys[7],   // D
                     keys[3],   // C
                     keys[14],  // B
                     keys[12],  // A
                     keys[10],  // 9
                     keys[9],   // 8
                     keys[8],   // 7
                     keys[6],   // 6
                     keys[5],   // 5
                     keys[4],   // 4
                     keys[2],   // 3
                     keys[1],   // 2
                     keys[0],   // 1
                     keys[13]}; // 0

  assign column_pins = {PIN_19, PIN_20, PIN_21, PIN_22};
  pullup io1(PIN_18, row_pins[0]);
  pullup io2(PIN_17, row_pins[1]);
  pullup io3(PIN_16, row_pins[2]);
  pullup io4(PIN_15, row_pins[3]);

  keypad k(CLK, column_pins, row_pins, keys);
endmodule

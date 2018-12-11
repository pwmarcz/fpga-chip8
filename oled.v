`include "ssd1306.v"
`include "ssd1331.v"

module oled(input wire        clk,
            input wire        pin_din,
            input wire        pin_clk,
            input wire        pin_cs,
            input wire        pin_dc,
            input wire        pin_res,

            output wire       read,
            output wire [5:0] row_idx,
            output wire [6:0] column_idx,
            // mono: 8-pixel vertical strip
            input wire [7:0]  data,
            // color: 5+6+5 bit RGB value
            input wire [15:0] data_rgb,
            input wire        ack);

  parameter color = 0;

  wire       transmit;
  wire       is_data;
  wire [7:0] tx_byte;
  wire       ready;

  oled_spi spi(.clk(clk),
               .transmit(transmit),
               .is_data(is_data),
               .tx_byte(tx_byte),
               .ready(ready),
               .pin_din(pin_din),
               .pin_clk(pin_clk),
               .pin_cs(pin_cs),
               .pin_dc(pin_dc));

  oled_controller #(.color(color))
  controller(.clk(clk),
             .pin_res(pin_res),
             .spi_transmit(transmit),
             .spi_is_data(is_data),
             .spi_tx_byte(tx_byte),
             .spi_ready(ready),
             .read(read),
             .row_idx(row_idx),
             .column_idx(column_idx),
             .data(data),
             .data_rgb(data_rgb),
             .ack(ack));

endmodule

module oled_spi(input wire       clk,
                input wire       transmit,
                input wire       is_data,
                input wire [7:0] tx_byte,
                output wire      ready,

                output wire      pin_din,
                output wire      pin_clk,
                output wire      pin_cs,
                output reg       pin_dc);
  assign pin_clk = clk;

  reg [7:0] data;
  reg [3:0] data_counter = 0;
  wire      transmitting = data_counter > 0;
  assign pin_din = data[7];
  assign pin_cs = !transmitting;

  assign ready = !transmit && !transmitting;

  always @(posedge clk) begin
    if (transmit && !transmitting) begin
      data <= tx_byte;
      pin_dc <= is_data;
      data_counter <= 8;
    end

    if (transmitting) begin
      data <= data << 1;
      data_counter <= data_counter - 1;
    end
  end
endmodule

module oled_controller(input wire       clk,
                       output reg        pin_res,

                       output reg        spi_transmit,
                       output reg        spi_is_data,
                       output reg [7:0]  spi_tx_byte,
                       input wire        spi_ready,

                       output reg        read,
                       output reg [5:0]  row_idx,
                       output reg [6:0]  column_idx,
                       input wire [7:0]  data,
                       input wire [15:0] data_rgb,
                       input wire        ack);

  parameter color = 0;

  localparam N_INIT_COMMANDS = color ? 38 : 25;
  localparam N_REFRESH_COMMANDS = 6;
  localparam WIDTH = color ? 96 : 128;
  localparam HEIGHT = color ? 64 : 8;

  localparam
    STATE_RESET = 0,
    STATE_INIT = 1,
    STATE_IDLE = 2,
    STATE_REFRESH_BEGIN = 3,
    STATE_REFRESH_DATA = 4,
    STATE_TRANSMIT_LOWER_BYTE = 5,
    STATE_ADVANCE = 6;

  reg [7:0] commands[0:N_INIT_COMMANDS+N_REFRESH_COMMANDS-1];
  reg [8:0] command_idx = 0;
  reg [7:0] command;
  reg       send_command = 0;

  reg [7:0] data_rgb_lower_byte;

  reg [3:0] state = STATE_RESET;
  reg [9:0] reset_counter = 0;

  integer i;

  initial begin
    i = -1;

    if (color) begin
      // Init commands
      i++; commands[i] <= `SSD1331_DISPLAY_OFF;
      i++; commands[i] <= `SSD1331_SET_CONTRAST_A;
      i++; commands[i] <= 'hFF;
      i++; commands[i] <= `SSD1331_SET_CONTRAST_B;
      i++; commands[i] <= 'hFF;
      i++; commands[i] <= `SSD1331_SET_CONTRAST_C;
      i++; commands[i] <= 'hFF;
      i++; commands[i] <= `SSD1331_MASTER_CURRENT_CONTROL;
      i++; commands[i] <= 'h06;
      i++; commands[i] <= `SSD1331_SET_PRECHARGE_SPEED_A;
      i++; commands[i] <= 'h64;
      i++; commands[i] <= `SSD1331_SET_PRECHARGE_SPEED_B;
      i++; commands[i] <= 'h78;
      i++; commands[i] <= `SSD1331_SET_PRECHARGE_SPEED_C;
      i++; commands[i] <= 'h64;
      i++; commands[i] <= `SSD1331_SET_REMAP;
      i++; commands[i] <= 'h72;
      i++; commands[i] <= `SSD1331_SET_DISPLAY_START_LINE;
      i++; commands[i] <= 'h00;
      i++; commands[i] <= `SSD1331_SET_DISPLAY_OFFSET;
      i++; commands[i] <= 'h00;
      i++; commands[i] <= `SSD1331_NORMAL_DISPLAY;
      i++; commands[i] <= `SSD1331_SET_MULTIPLEX_RATIO;
      i++; commands[i] <= 'h3F;
      i++; commands[i] <= `SSD1331_SET_MASTER_CONFIGURE;
      i++; commands[i] <= 'h8E;
      i++; commands[i] <= `SSD1331_POWER_SAVE_MODE;
      i++; commands[i] <= 'h00;
      i++; commands[i] <= `SSD1331_PHASE_PERIOD_ADJUSTMENT;
      i++; commands[i] <= 'h31;
      i++; commands[i] <= `SSD1331_DISPLAY_CLOCK_DIV;
      i++; commands[i] <= 'hF0;
      i++; commands[i] <= `SSD1331_SET_PRECHARGE_VOLTAGE;
      i++; commands[i] <= 'h3A;
      i++; commands[i] <= `SSD1331_SET_V_VOLTAGE;
      i++; commands[i] <= 'h3E;
      i++; commands[i] <= `SSD1331_DEACTIVE_SCROLLING;
      i++; commands[i] <= `SSD1331_NORMAL_BRIGHTNESS_DISPLAY_ON;

      // Refresh commands
      i++; commands[i] <= `SSD1331_SET_COLUMN_ADDRESS;
      i++; commands[i] <= 0;
      i++; commands[i] <= WIDTH - 1;
      i++; commands[i] <= `SSD1331_SET_ROW_ADDRESS;
      i++; commands[i] <= 0;
      i++; commands[i] <= HEIGHT - 1;
    end else begin
      // Init commands
      i++; commands[i] <= `SSD1306_DISPLAYOFF;
      i++; commands[i] <= `SSD1306_SETDISPLAYCLOCKDIV;
      i++; commands[i] <= 'h80;
      i++; commands[i] <= `SSD1306_SETMULTIPLEX;
      i++; commands[i] <= 'h3F;
      i++; commands[i] <= `SSD1306_SETDISPLAYOFFSET;
      i++; commands[i] <= 'h00;
      i++; commands[i] <= `SSD1306_SETSTARTLINE | 'h00;
      i++; commands[i] <= `SSD1306_CHARGEPUMP;
      i++; commands[i] <= 'h14;
      i++; commands[i] <= `SSD1306_MEMORYMODE;
      i++; commands[i] <= 'h00;
      i++; commands[i] <= `SSD1306_SEGREMAP | 'h01;
      i++; commands[i] <= `SSD1306_COMSCANDEC;
      i++; commands[i] <= `SSD1306_SETCOMPINS;
      i++; commands[i] <= 'h12;
      i++; commands[i] <= `SSD1306_SETCONTRAST;
      i++; commands[i] <= 'h70;
      i++; commands[i] <= `SSD1306_SETPRECHARGE;
      i++; commands[i] <= 'hF1;
      i++; commands[i] <= `SSD1306_SETVCOMDETECT;
      i++; commands[i] <= 'h40;
      i++; commands[i] <= `SSD1306_DISPLAYALLON_RESUME;
      i++; commands[i] <= `SSD1306_NORMALDISPLAY;
      i++; commands[i] <= `SSD1306_DISPLAYON;

      // Refresh commands
      i++; commands[i] <= `SSD1306_COLUMNADDR;
      i++; commands[i] <= 0;
      i++; commands[i] <= WIDTH - 1;
      i++; commands[i] <= `SSD1306_PAGEADDR;
      i++; commands[i] <= 0;
      i++; commands[i] <= HEIGHT - 1;
    end
  end

  always @(posedge clk) begin
    command <= commands[command_idx];
    if (send_command) begin
      send_command <= 0;
      spi_transmit <= 1;
      spi_is_data <= 0;
      spi_tx_byte <= command;
    end else begin
      spi_transmit <= 0;
      pin_res <= 1;
      case (state)
        STATE_RESET: begin
          pin_res <= 0;
          reset_counter <= reset_counter + 1;
          if (&reset_counter)
            if (spi_ready) begin
              pin_res <= 0;
              state <= STATE_INIT;
              command_idx <= 0;
            end
        end
        STATE_INIT: begin
          if (spi_ready) begin
            send_command <= 1;

            command_idx <= command_idx + 1;
            if (command_idx+1 == N_INIT_COMMANDS) begin
              state <= STATE_REFRESH_BEGIN;
            end
          end
        end
        STATE_REFRESH_BEGIN: begin
          if (spi_ready) begin
            if (command_idx < N_INIT_COMMANDS + N_REFRESH_COMMANDS) begin
              send_command <= 1;
              command_idx <= command_idx + 1;
            end else begin
              state <= STATE_REFRESH_DATA;
              row_idx <= 0;
              column_idx <= 0;
              read <= 1;
            end
          end
        end
        STATE_REFRESH_DATA: begin
          read <= 0;
          if (ack) begin
            spi_transmit <= 1;
            spi_is_data <= 1;
            if (color) begin
              spi_tx_byte <= data_rgb[15:8];
              data_rgb_lower_byte <= data_rgb[7:0];
              state <= STATE_TRANSMIT_LOWER_BYTE;
            end else begin
              spi_tx_byte <= data;
              state <= STATE_ADVANCE;
            end
          end
        end
        STATE_TRANSMIT_LOWER_BYTE: begin
          if (color) begin
            if (spi_ready) begin
              spi_transmit <= 1;
              spi_is_data <= 1;
              spi_tx_byte <= data_rgb_lower_byte;
              state <= STATE_ADVANCE;
            end
          end
        end
        STATE_ADVANCE: begin
          if (spi_ready) begin
            if (column_idx == WIDTH - 1 && row_idx == HEIGHT - 1) begin
              state <= STATE_REFRESH_BEGIN;
              command_idx <= N_INIT_COMMANDS;
            end else begin
              read <= 1;
              state <= STATE_REFRESH_DATA;
              column_idx <= column_idx + 1;
              if (column_idx == WIDTH - 1) begin
                column_idx <= 0;
                if (color)
                  row_idx <= row_idx + 1;
                else
                  row_idx <= row_idx + 1;
              end
            end
          end
        end
      endcase
    end
  end
endmodule

// Copied from Waveshare's official documentation.

`define SSD1331_DRAW_LINE                       8'h21
`define SSD1331_DRAW_RECTANGLE                  8'h22
`define SSD1331_COPY_WINDOW                     8'h23
`define SSD1331_DIM_WINDOW                      8'h24
`define SSD1331_CLEAR_WINDOW                    8'h25
`define SSD1331_FILL_WINDOW                     8'h26
`define SSD1331_DISABLE_FILL                    8'h00
`define SSD1331_ENABLE_FILL                     8'h01
`define SSD1331_CONTINUOUS_SCROLLING_SETUP      8'h27
`define SSD1331_DEACTIVE_SCROLLING              8'h2E
`define SSD1331_ACTIVE_SCROLLING                8'h2F

`define SSD1331_SET_COLUMN_ADDRESS              8'h15
`define SSD1331_SET_ROW_ADDRESS                 8'h75
`define SSD1331_SET_CONTRAST_A                  8'h81
`define SSD1331_SET_CONTRAST_B                  8'h82
`define SSD1331_SET_CONTRAST_C                  8'h83
`define SSD1331_MASTER_CURRENT_CONTROL          8'h87
`define SSD1331_SET_PRECHARGE_SPEED_A           8'h8A
`define SSD1331_SET_PRECHARGE_SPEED_B           8'h8B
`define SSD1331_SET_PRECHARGE_SPEED_C           8'h8C
`define SSD1331_SET_REMAP                       8'hA0
`define SSD1331_SET_DISPLAY_START_LINE          8'hA1
`define SSD1331_SET_DISPLAY_OFFSET              8'hA2
`define SSD1331_NORMAL_DISPLAY                  8'hA4
`define SSD1331_ENTIRE_DISPLAY_ON               8'hA5
`define SSD1331_ENTIRE_DISPLAY_OFF              8'hA6
`define SSD1331_INVERSE_DISPLAY                 8'hA7
`define SSD1331_SET_MULTIPLEX_RATIO             8'hA8
`define SSD1331_DIM_MODE_SETTING                8'hAB
`define SSD1331_SET_MASTER_CONFIGURE            8'hAD
`define SSD1331_DIM_MODE_DISPLAY_ON             8'hAC
`define SSD1331_DISPLAY_OFF                     8'hAE
`define SSD1331_NORMAL_BRIGHTNESS_DISPLAY_ON    8'hAF
`define SSD1331_POWER_SAVE_MODE                 8'hB0
`define SSD1331_PHASE_PERIOD_ADJUSTMENT         8'hB1
`define SSD1331_DISPLAY_CLOCK_DIV               8'hB3
`define SSD1331_SET_GRAY_SCALE_TABLE            8'hB8
`define SSD1331_ENABLE_LINEAR_GRAY_SCALE_TABLE  8'hB9
`define SSD1331_SET_PRECHARGE_VOLTAGE           8'hBB

`define SSD1331_SET_V_VOLTAGE                   8'hBE

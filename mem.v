`default_nettype none

module mem(input wire clk,
           input wire read,
           input wire [11:0] read_idx,
           output reg [7:0] read_byte,
           output reg read_ack = 0,
           input wire write,
           input wire [11:0] write_idx,
           input wire [7:0] write_byte);

  parameter debug = 0;

  reg [7:0] data[0:'hFFF];

  initial $readmemh("font.hex", data, 'h030, 'h07f);
  // for icebram to replace
  initial $readmemh("random.hex", data, 'h200, 'hfff);

  always @(posedge clk) begin
    read_ack <= 0;
    if (read) begin
      if (debug)
        $display($time, " load [%x] = %x", read_idx, data[read_idx]);
      read_byte <= data[read_idx];
      read_ack <= 1;
    end
    if (write) begin
      if (debug)
        $display($time, " store [%x] = %x", write_idx, write_byte);
      data[write_idx] <= write_byte;
    end
  end
endmodule

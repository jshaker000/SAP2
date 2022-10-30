`default_nettype none

// This register allows for loading - the bottom WIDTH/2 bits from the bottom in bits and the top WIDTH/2 bits from either the top or bottom WIDTH/2 bits

module HalfLoadableRegister #(
  parameter WIDTH = 8
)(
  input wire             clk,
  input wire             clk_en,
  input wire       [1:0] i_load_enable,
  input wire             i_load_upper_from_lower,
  input wire [WIDTH-1:0] i_load_data,

  output reg [WIDTH-1:0] o_data
);

  initial begin
    o_data = {WIDTH{1'b0}};
  end

  wire [1:0] load = {2{clk_en}} & i_load_enable;

  always @(posedge clk) o_data[WIDTH-1:WIDTH/2] <= load[1] ? (i_load_upper_from_lower ? i_load_data[WIDTH/2-1:0] : i_load_data[WIDTH-1:WIDTH/2]) : o_data[WIDTH-1:WIDTH/2];
  always @(posedge clk) o_data[WIDTH/2-1:0]     <= load[0] ? i_load_data[WIDTH/2-1:0] : o_data[WIDTH/2-1:0];

endmodule

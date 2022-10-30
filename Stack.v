`default_nettype none

// This stack does not support simultaneous pushing and popping

module Stack #(
  parameter STACK_WIDTH = 16,
  parameter STACK_DEPTH = 16
) (
  input wire clk,
  input wire clk_en,
  input wire i_push,
  input wire i_pop,
  input wire  [STACK_WIDTH-1:0] i_load_data,
  output wire [STACK_WIDTH-1:0] o_data
);

  localparam SP_W = $clog2(STACK_DEPTH);
  reg [STACK_WIDTH-1:0] stack [0:STACK_DEPTH-1];

  reg [SP_W-1:0] sp;
  initial begin
    sp = {SP_W{1'b0}};
  end

  always @(posedge clk) sp        <= clk_en & i_push ? sp + 1 : clk_en & i_pop ? sp - 1 : sp;
  always @(posedge clk) stack[sp] <= clk_en & i_push ? i_load_data : stack[sp];

  assign o_data = stack[sp-1];
endmodule

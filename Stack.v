`default_nettype none

// This stack does not support simultaneous pushing and popping
// That's fine though, we check against this in our opcode generator and with sim assertions

module Stack #(
  parameter STACK_WIDTH = 16,
  parameter STACK_DEPTH = 16
) (
  input wire clk,
  input wire clk_en,
  input wire i_push,
  input wire i_pop,
  input wire  [STACK_WIDTH-1:0] i_load_data,
  output wire  [STACK_WIDTH-1:0] o_data
);

  localparam SP_W = $clog2(STACK_DEPTH);
  reg [STACK_WIDTH-1:0] stack [0:STACK_DEPTH-1];

  reg [SP_W-1:0] sp; // stores where we want to write to next
  initial begin
    sp = {SP_W{1'b0}};
  end

  wire i_push_use = i_push  & ~i_pop;
  wire i_pop_use  = ~i_push & i_pop;

  always @(posedge clk) sp <= clk_en ?
                                i_push_use ? sp + 1 :
                                i_pop_use  ? sp - 1  :
                                sp :
                              sp;

  always @(posedge clk) stack[sp] <= clk_en & i_push_use ? i_load_data : stack[sp];

  // We want the stack to be able to use a synchronous read port for the RAM
  // To handle this, we need to have a seperate synchronoyus read and a 'fallthough path'
  // and mux between the results
  reg [STACK_WIDTH-1:0] ram_rd_data;
  always @(posedge clk) ram_rd_data <= clk_en & i_pop_use ? stack[sp - 2] : ram_rd_data;

  reg [STACK_WIDTH-1:0] last_pushed_data;
  always @(posedge clk) last_pushed_data <= clk_en & i_push_use ? i_load_data : last_pushed_data;

  reg last_op_was_a_pop_not_a_push;
  always @(posedge clk) last_op_was_a_pop_not_a_push <= clk_en ?
                                                          i_pop_use  ? 1'b1 :
                                                          i_push_use ? 1'b0 :
                                                          last_op_was_a_pop_not_a_push :
                                                        last_op_was_a_pop_not_a_push;

  assign o_data = last_op_was_a_pop_not_a_push ? ram_rd_data : last_pushed_data;

  `ifndef SYNTHESIS
    always @(posedge clk) if (clk_en & i_push & i_pop) $fatal(1, "Stack cannot simultaneously push and pop!");
  `endif
endmodule

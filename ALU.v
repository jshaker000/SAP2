// Simple ALU that can add or subtrack.
// Can optionally latch its flags, which can be used as inputs to the
// Instruction decoding for JIZ instructions and the like,

`default_nettype none

module ALU (
  clk,
  clk_en,
  i_latch_flags,
  i_op,
  i_a,
  i_t,

  o_zero,
  o_carry,
  o_odd,
  o_data
);

  parameter WIDTH = 8;
  `include "control_words.vi"

  input  wire                    clk;
  input  wire                    clk_en;
  input  wire                    i_latch_flags;
  input  wire [ALU_OP_WIDTH-1:0] i_op;
  input  wire        [WIDTH-1:0] i_a;
  input  wire        [WIDTH-1:0] i_t;

  output reg              o_zero;
  output reg              o_carry;
  output reg              o_odd;
  output wire [WIDTH-1:0] o_data;


  initial begin
    o_zero  = 1'b0;
    o_carry = 1'b0;
    o_odd   = 1'b0;
  end

  wire           latch  = clk_en & i_latch_flags;

  wire [WIDTH:0] alu_add_or_sub = i_op == ALU_ADD ? i_a + i_t : i_a - i_t;
  wire [WIDTH:0] alu_and        = {1'b0,    i_a & i_t};
  wire [WIDTH:0] alu_or         = {1'b0,    i_a | i_t};
  wire [WIDTH:0] alu_xor        = {1'b0,    i_a ^ i_t};
  wire [WIDTH:0] alu_sl         = {1'b0,    i_a[WIDTH-2:0], 1'b0};
  wire [WIDTH:0] alu_sr         = {1'b0,    1'b0,           i_a[WIDTH-1:1]};
  wire [WIDTH:0] alu_asr        = {1'b0,    i_a[WIDTH-1],   i_a[WIDTH-1:1]};
  wire [WIDTH:0] alu_rol        = {1'b0,    i_a[WIDTH-2:0], i_a[WIDTH-1]};
  wire [WIDTH:0] alu_ror        = {1'b0,    i_a[0],         i_a[WIDTH-1:1]};
  wire [WIDTH:0] alu_rolc       = {i_a,     o_carry};
  wire [WIDTH:0] alu_rorc       = {o_carry, i_a};
  wire [WIDTH:0] alu_inv        = {1'b0,    ~i_a};
  wire [WIDTH:0] alu_chk        = {1'b0,    i_a};

  wire [WIDTH:0] result         = i_op == ALU_ADD || i_op == ALU_SUB ? alu_add_or_sub :
                                  i_op == ALU_AND                    ? alu_and  :
                                  i_op == ALU_OR                     ? alu_or   :
                                  i_op == ALU_XOR                    ? alu_xor  :
                                  i_op == ALU_SL                     ? alu_sl   :
                                  i_op == ALU_SR                     ? alu_sr   :
                                  i_op == ALU_ASR                    ? alu_asr  :
                                  i_op == ALU_ROL                    ? alu_rol  :
                                  i_op == ALU_ROR                    ? alu_ror  :
                                  i_op == ALU_ROLC                   ? alu_rolc :
                                  i_op == ALU_RORC                   ? alu_rorc :
                                  i_op == ALU_INV                    ? alu_inv  :
                                                                       alu_chk;

  assign o_data         = result[WIDTH-1:0];

  always @(posedge clk) o_zero  <= latch ? o_data == {WIDTH{1'b0}} : o_zero;
  always @(posedge clk) o_carry <= latch ? result[WIDTH]           : o_carry;
  always @(posedge clk) o_odd   <= latch ? o_data[0]               : o_odd;

endmodule

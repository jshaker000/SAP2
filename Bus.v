// My verilog simulator does not do tristate logic
// Instead, we will send all data to the bus and AND it with a MASK of its valid
// The bus will then OR reduce and output. At any given time, only one valid
// should be high anyway so this works will

`default_nettype none

module Bus #(
  parameter BUS_WIDTH                 = 16,
  parameter A_REG_OUT_WIDTH           = 8,
  parameter T_REG_OUT_WIDTH           = 8,
  parameter B_REG_OUT_WIDTH           = 8,
  parameter C_REG_OUT_WIDTH           = 8,
  parameter RAM_OUT_WIDTH             = 8,
  parameter STACK_OUT_WIDTH           = 16,
  parameter MEMORY_ADDR_REG_OUT_WIDTH = 16,
  parameter ALU_OUT_WIDTH             = 8,
  parameter PROGRAM_COUNTER_OUT_WIDTH = 16
)(
  input wire i_a_reg_out,
  input wire i_t_reg_out,
  input wire i_b_reg_out,
  input wire i_c_reg_out,
  input wire i_ram_out,
  input wire i_stack_out,
  input wire i_memory_addr_reg_out,
  input wire i_alu_out,
  input wire i_program_counter_out,

  input wire           [A_REG_OUT_WIDTH-1:0] i_a_reg_data,
  input wire           [T_REG_OUT_WIDTH-1:0] i_t_reg_data,
  input wire           [B_REG_OUT_WIDTH-1:0] i_b_reg_data,
  input wire           [C_REG_OUT_WIDTH-1:0] i_c_reg_data,
  input wire           [STACK_OUT_WIDTH-1:0] i_stack_data,
  input wire             [RAM_OUT_WIDTH-1:0] i_ram_data,
  input wire [MEMORY_ADDR_REG_OUT_WIDTH-1:0] i_memory_addr_reg_data,
  input wire             [ALU_OUT_WIDTH-1:0] i_alu_data,
  input wire [PROGRAM_COUNTER_OUT_WIDTH-1:0] i_program_counter_data,

  output wire                [BUS_WIDTH-1:0] o_bus_out
);

  //left fill with 0's if need be, and mask with data with valids
  wire [BUS_WIDTH-1:0] a_reg_masked           =  {{BUS_WIDTH-A_REG_OUT_WIDTH{1'b0}},          i_a_reg_data}
                                                & {BUS_WIDTH{i_a_reg_out}};
  wire [BUS_WIDTH-1:0] t_reg_masked           =  {{BUS_WIDTH-B_REG_OUT_WIDTH{1'b0}},          i_t_reg_data}
                                                & {BUS_WIDTH{i_t_reg_out}};
  wire [BUS_WIDTH-1:0] b_reg_masked           =  {{BUS_WIDTH-B_REG_OUT_WIDTH{1'b0}},          i_b_reg_data}
                                                & {BUS_WIDTH{i_b_reg_out}};
  wire [BUS_WIDTH-1:0] c_reg_masked           =  {{BUS_WIDTH-C_REG_OUT_WIDTH{1'b0}},          i_c_reg_data}
                                                & {BUS_WIDTH{i_c_reg_out}};
  wire [BUS_WIDTH-1:0] stack_masked           =  {{BUS_WIDTH-STACK_OUT_WIDTH{1'b0}},          i_stack_data}
                                                & {BUS_WIDTH{i_stack_out}};
  wire [BUS_WIDTH-1:0] ram_masked             =  {{BUS_WIDTH-RAM_OUT_WIDTH{1'b0}},            i_ram_data}
                                                & {BUS_WIDTH{i_ram_out}};
  wire [BUS_WIDTH-1:0] memory_addr_reg_masked =  {{BUS_WIDTH-MEMORY_ADDR_REG_OUT_WIDTH{1'b0}},i_memory_addr_reg_data}
                                                & {BUS_WIDTH{i_memory_addr_reg_out}};
  wire [BUS_WIDTH-1:0] alu_masked             =  {{BUS_WIDTH-ALU_OUT_WIDTH{1'b0}},            i_alu_data}
                                                & {BUS_WIDTH{i_alu_out}};
  wire [BUS_WIDTH-1:0] program_counter_masked =  {{BUS_WIDTH-PROGRAM_COUNTER_OUT_WIDTH{1'b0}},i_program_counter_data}
                                                & {BUS_WIDTH{i_program_counter_out}};

  assign o_bus_out = a_reg_masked           | t_reg_masked |
                     b_reg_masked           | c_reg_masked |
                     stack_masked           | ram_masked   |
                     memory_addr_reg_masked | alu_masked   | program_counter_masked;

endmodule

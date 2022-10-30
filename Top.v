`default_nettype none

module Top #(
  parameter BUS_WIDTH   = 16,
  parameter A_REG_WIDTH = 16,
  parameter T_REG_WIDTH = 16,
  parameter B_REG_WIDTH = 16,
  parameter C_REG_WIDTH = 16,
  parameter ALU_WIDTH   = 16,
  parameter OUT_WIDTH   = 16,

  parameter STACK_WIDTH           = 16,
  parameter STACK_DEPTH           = 512,

  parameter PROGRAM_COUNTER_WIDTH = 16,

  parameter RAM_DEPTH         = 2**PROGRAM_COUNTER_WIDTH,
  parameter RAM_WIDTH         = 16,

  parameter INSTRUCTION_WIDTH  = 16,
  parameter INSTRUCTION_STEPS  = 32,

  parameter FILE               = "ram.hex",

  localparam ADDRESS_WIDTH             = $clog2(RAM_DEPTH),
  localparam INSTRUCTION_COUNTER_WIDTH = $clog2(INSTRUCTION_STEPS)
)(
  input wire clk,
  output wire [OUT_WIDTH-1:0] out_data
);

  `include "instructions.vi"


/*------------------BEGIN INTERCONNECTS----------------------------------*/
  // clock enable
  wire  clk_en;

  // Instruction Decoder
  wire [CONTROL_WORD_WIDTH-1:0] control_word;

  // bus
  wire                         [BUS_WIDTH-1:0] bus_out;

  // program counter
  wire             [PROGRAM_COUNTER_WIDTH-1:0] program_counter;

  // instruction counter
  wire         [INSTRUCTION_COUNTER_WIDTH-1:0] instruction_counter;

  // instruction register
  wire                  [INSTRUCTION_WIDTH-1:0] instruction;

  // memory address
  wire                     [ADDRESS_WIDTH-1:0] memory_address;

  // ram data
  wire                         [RAM_WIDTH-1:0] ram_data;

  // registers
  wire                       [A_REG_WIDTH-1:0] a_reg;
  wire                       [T_REG_WIDTH-1:0] t_reg;
  wire                       [B_REG_WIDTH-1:0] b_reg;
  wire                       [C_REG_WIDTH-1:0] c_reg;

  wire                       [STACK_WIDTH-1:0] stack;

  // alu out
  wire                         [ALU_WIDTH-1:0] alu_data;
  wire                                         zero;
  wire                                         carry;
  wire                                         odd;

/*-------------------END INTERCONNECTS-----------------------------------*/

  Clock_Enable inst_Clock_Enable(
    .clk   (clk),
    .clk_en(clk_en)
  );

  Instruction_Decoder #(
    .INSTRUCTION_WIDTH(INSTRUCTION_WIDTH),
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS)
  ) inst_Instruction_Decoder(
      .i_instruction (instruction),
      .i_step        (instruction_counter),
      .i_zero        (zero),
      .i_carry       (carry),
      .i_odd         (odd),
      .o_control_word(control_word)
  );

  Bus #(
    .BUS_WIDTH                (BUS_WIDTH),
    .A_REG_OUT_WIDTH          (A_REG_WIDTH),
    .T_REG_OUT_WIDTH          (T_REG_WIDTH),
    .B_REG_OUT_WIDTH          (B_REG_WIDTH),
    .C_REG_OUT_WIDTH          (C_REG_WIDTH),
    .MEMORY_ADDR_REG_OUT_WIDTH(ADDRESS_WIDTH),
    .ALU_OUT_WIDTH            (ALU_WIDTH),
    .STACK_OUT_WIDTH          (STACK_WIDTH),
    .RAM_OUT_WIDTH            (RAM_WIDTH),
    .PROGRAM_COUNTER_OUT_WIDTH(PROGRAM_COUNTER_WIDTH)
  ) inst_Bus (
    .i_a_reg_out           (control_word[ARO_POS]),
    .i_a_reg_data          (a_reg),
    .i_t_reg_out           (control_word[TRO_POS]),
    .i_t_reg_data          (t_reg),
    .i_b_reg_out           (control_word[BRO_POS]),
    .i_b_reg_data          (b_reg),
    .i_c_reg_out           (control_word[CRO_POS]),
    .i_c_reg_data          (c_reg),
    .i_alu_out             (control_word[EO_POS]),
    .i_alu_data            (alu_data),
    .i_stack_out           (control_word[SO_POS]),
    .i_stack_data          (stack),
    .i_ram_out             (control_word[RO_POS]),
    .i_ram_data            (ram_data),
    .i_memory_addr_reg_out (control_word[MO_POS]),
    .i_memory_addr_reg_data(memory_address),
    .i_program_counter_out (control_word[CO_POS]),
    .i_program_counter_data(program_counter),
    .o_bus_out             (bus_out)
  );

  Program_Counter #(
    .WIDTH(PROGRAM_COUNTER_WIDTH)
  ) inst_Program_Counter (
    .clk            (clk),
    .clk_en         (clk_en),
    .i_counter_enable(control_word[CE_POS]),
    .i_halt          (control_word[HLT_POS]),
    .i_load_enable   (control_word[J_POS]),
    .i_load_data     (bus_out[PROGRAM_COUNTER_WIDTH-1:0]),
    .o_data          (program_counter)
  );

  Instruction_Counter #(
    .INSTRUCTION_STEPS(INSTRUCTION_STEPS)
  ) inst_Instruction_Counter (
    .clk    (clk),
    .clk_en (clk_en),
    .i_halt (control_word[HLT_POS]),
    .i_adv  (control_word[ADV_POS]),
    .o_data (instruction_counter)
  );

  Register #(
    .WIDTH(INSTRUCTION_WIDTH)
  ) inst_Register_Instruction (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[II_POS]),
    .i_load_data  (bus_out[INSTRUCTION_WIDTH-1:0]),
    .o_data       (instruction)
  );

  Register #(
    .WIDTH(ADDRESS_WIDTH)
  ) inst_Register_Memory_Address (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[MI_POS]),
    .i_load_data  (bus_out[ADDRESS_WIDTH-1:0]),
    .o_data       (memory_address)
  );

  Ram #(
    .RAM_DEPTH(RAM_DEPTH),
    .WIDTH    (RAM_WIDTH),
    .FILE     (FILE)
  ) inst_Ram (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_address    (memory_address),
    .i_load_enable(control_word[RI_POS]),
    .i_load_data  (bus_out[RAM_WIDTH-1:0]),
    .o_data       (ram_data)
  );

  Register #(
    .WIDTH(A_REG_WIDTH)
  ) inst_Register_A (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[ARI_POS]),
    .i_load_data  (bus_out[A_REG_WIDTH-1:0]),
    .o_data       (a_reg)
  );

  Register #(
    .WIDTH(T_REG_WIDTH)
  ) inst_Register_T (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[TRI_POS]),
    .i_load_data  (bus_out[T_REG_WIDTH-1:0]),
    .o_data       (t_reg)
  );

  Register #(
    .WIDTH(B_REG_WIDTH)
  ) inst_Register_B (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[BRI_POS]),
    .i_load_data  (bus_out[B_REG_WIDTH-1:0]),
    .o_data       (b_reg)
  );

  Register #(
    .WIDTH(C_REG_WIDTH)
  ) inst_Register_C (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[CRI_POS]),
    .i_load_data  (bus_out[C_REG_WIDTH-1:0]),
    .o_data       (c_reg)
  );

  Stack #(
    .STACK_WIDTH(STACK_WIDTH),
    .STACK_DEPTH(STACK_DEPTH)
  ) inst_Stack (
    .clk        (clk),
    .clk_en     (clk_en),
    .i_push     (control_word[SPU_POS]),
    .i_pop      (control_word[SPO_POS]),
    .i_load_data(bus_out[STACK_WIDTH-1:0]),
    .o_data     (stack)
  );

  ALU #(
    .WIDTH(ALU_WIDTH)
  ) inst_ALU (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_latch_flags(control_word[EL_POS]),
    .i_sub        (control_word[SU_POS]),
    .i_a          (a_reg),
    .i_b          (t_reg),
    .o_zero       (zero),
    .o_carry      (carry),
    .o_odd        (odd),
    .o_data       (alu_data)
  );

  Out #(
    .WIDTH(OUT_WIDTH)
  ) inst_Out (
    .clk          (clk),
    .clk_en       (clk_en),
    .i_load_enable(control_word[OI_POS]),
    .i_load_data  (bus_out[OUT_WIDTH-1:0]),
    .o_data       (out_data)
  );

  `ifdef verilator
    function [OUT_WIDTH-1:0] get_out_data;
    // verilator public
      get_out_data = out_data;
    endfunction

    function [1-1:0] get_out_in;
    // verilator public
      get_out_in = control_word[OI_POS];
    endfunction

    function [1-1:0] get_halt;
    // verilator public
      get_halt = control_word[HLT_POS];
    endfunction
  `endif
endmodule

// Combinational module that takes program counter and instruction and ALU
// flags and produces control logic

`default_nettype none

module Instruction_Decoder (
  i_instruction,
  i_step,
  i_zero,
  i_carry,
  i_odd,
  o_control_word
);
  parameter  INSTRUCTION_WIDTH  = 16;
  parameter  INSTRUCTION_STEPS  = 32;

  `include "control_words.vi"

  localparam STEP_WIDTH = $clog2(INSTRUCTION_STEPS);

  localparam                    [0:0] X_NOT_ZERO_FOR_SHOULD_NEVER_REACH = 1'b0;
  localparam [CONTROL_WORD_WIDTH-1:0] SHOULD_NEVER_REACH                = {CONTROL_WORD_WIDTH{X_NOT_ZERO_FOR_SHOULD_NEVER_REACH ? 1'bx : 1'b0}};

  input wire     [INSTRUCTION_WIDTH-1:0] i_instruction;
  input wire            [STEP_WIDTH-1:0] i_step;
  input wire                             i_zero;
  input wire                             i_odd;
  input wire                             i_carry;
  output wire   [CONTROL_WORD_WIDTH-1:0] o_control_word;

  assign o_control_word =
                 // Fetch, put prgm cntr in mem addr, fetch instruction, advance PC. All instructions start like this
                 // Also note, all instructions must end in a c_ADV to advance to the next instruction
                 i_step == 'h0 ? c_MI | c_CO :
                 i_step == 'h1 ? c_RO | c_II | c_CE :
                   // i_instruction == 16'h0000 ? // unimplemented - defaults at bottom to NOP
                   // LD,A - put data in RAM[addr] in A. addr is the next word in ram
                   i_instruction == 16'h0001 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // LD,B - put data in RAM[addr] in B. addr is next word in ram
                   i_instruction == 16'h0002 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // LD,C - put data in RAM[addr] in C. addr is next word in ram
                   i_instruction == 16'h0003 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ST,A - put A in RAM[addr]. addr is next word in ram
                   i_instruction == 16'h0004 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ST,T - put T in RAM[addr]. addr is next word in ram
                   i_instruction == 16'h0005 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_TRO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ST,B - put B in RAM[addr]. addr is next word in ram
                   i_instruction == 16'h0006 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // STC - put C in RAM[addr]. addr is next word in RAM
                   i_instruction == 16'h0007 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDT,A - put data in RAM[T] in A.
                   i_instruction == 16'h0008 ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // LDT,B - put data in RAM[T] in B.
                   i_instruction == 16'h0009 ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // LDT,C - put data in RAM[T] in C.
                   i_instruction == 16'h000a ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH:
                   // STT,A - put data in A in RAM[T].
                   i_instruction == 16'h000b ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // STT,B - put data in B in RAM[T].
                   i_instruction == 16'h000c ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // STT,C - put data in C in RAM[T].
                   i_instruction == 16'h000d ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH:
                   // MOVA,T - put A in T.
                   i_instruction == 16'h000e ?
                     i_step == 'h2 ? c_ARO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVA,B - put A in B.
                   i_instruction == 16'h000f ?
                     i_step == 'h2 ? c_ARO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVA,C - put A in C.
                   i_instruction == 16'h0010 ?
                     i_step == 'h2 ? c_ARO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,A - put T in A.
                   i_instruction == 16'h0011 ?
                     i_step == 'h2 ? c_TRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,B - put T in B.
                   i_instruction == 16'h0012 ?
                     i_step == 'h2 ? c_TRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,C - put T in C.
                   i_instruction == 16'h0013 ?
                     i_step == 'h2 ? c_TRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,A - put B in A.
                   i_instruction == 16'h0014 ?
                     i_step == 'h2 ? c_BRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,T - put B in T .
                   i_instruction == 16'h0015 ?
                     i_step == 'h2 ? c_BRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,C - put B in C.
                   i_instruction == 16'h0016 ?
                     i_step == 'h2 ? c_BRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,A - put C in A.
                   i_instruction == 16'h0017 ?
                     i_step == 'h2 ? c_CRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,T - put C in T.
                   i_instruction == 16'h0018 ?
                     i_step == 'h2 ? c_CRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,B - put C in B.
                   i_instruction == 16'h0019 ?
                     i_step == 'h2 ? c_CRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,A
                   i_instruction == 16'h001a ?
                     i_step == 'h2 ? c_SPU | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,A
                   i_instruction == 16'h001b ?
                     i_step == 'h2 ? c_SPO | c_SO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,T
                   i_instruction == 16'h001c ?
                     i_step == 'h2 ? c_SPU | c_TRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,T
                   i_instruction == 16'h001d ?
                     i_step == 'h2 ? c_SPO | c_SO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,B
                   i_instruction == 16'h001e ?
                     i_step == 'h2 ? c_SPU | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,B
                   i_instruction == 16'h001f ?
                     i_step == 'h2 ? c_SPO | c_SO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,C
                   i_instruction == 16'h0020 ?
                     i_step == 'h2 ? c_SPU | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,C
                   i_instruction == 16'h0021 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,PC - note that when we pop we increment the counter 2 times so this should almost always be immediately followed by a jump. then a pop would bring us to the following expression
                   i_instruction == 16'h0022 ?
                     i_step == 'h2 ? c_SPU | c_CO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,PC - note we increment the counter 2 times to get past the jump instruction we presumably did just after pushing
                   i_instruction == 16'h0023 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_J :
                     i_step == 'h3 ? c_CE :
                     i_step == 'h4 ? c_CE | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH,MA
                   i_instruction == 16'h0024 ?
                     i_step == 'h2 ? c_SPU | c_MO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP,MA
                   i_instruction == 16'h0025 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_MI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUT,A
                   i_instruction == 16'h0026 ?
                     i_step == 'h2      ? c_ARO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUT,T
                   i_instruction == 16'h0027 ?
                     i_step == 'h2      ? c_TRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUT,B
                   i_instruction == 16'h0028 ?
                     i_step == 'h2      ? c_BRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUT,C
                   i_instruction == 16'h0029 ?
                     i_step == 'h2      ? c_CRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,A - data to A. data is the next word of ram
                   i_instruction == 16'h002a ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,B - data to B. data is the next word of ram
                   i_instruction == 16'h002b ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,C - data to C. data is the next word of ram
                   i_instruction == 16'h002c ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JMP - jump to RAM[addr]. addr is the next word of RAM
                   i_instruction == 16'h002d ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_J | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIZ - jump to RAM[addr] if zero flag is set. addr is the next word of RAM
                   i_instruction == 16'h002e ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_zero ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J  | c_RO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // JIC - jump to RAM[addr] if zero flag is set. addr is the next word of RAM
                   i_instruction == 16'h002f ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_carry ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J  | c_RO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // JIO - jump to RAM[addr] if odd flag is set. addr is the next word of RAM
                   i_instruction == 16'h0030 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_odd ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J  | c_RO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // ADDI - add A to data, store into TMP. data is next word of ram
                   i_instruction == 16'h0031 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBI - subtract A by data, store into TMP. data is next word of ram
                   i_instruction == 16'h0032 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ANDI - and A with data, store in TMP, data is next word of RAM
                   i_instruction == 16'h0033 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ORI - ori A with data, store in TMP, data is next word of RAM
                   i_instruction == 16'h0034 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // XORI - xor A with data, store in TMP, data is next word of RAM
                   i_instruction == 16'h0035 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADD,B - add A to B, storing into TMP.
                   i_instruction == 16'h0036 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUB,B - subtract A by B, storing in TMP
                   i_instruction == 16'h0037 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // AND,B - and A with B, storing in TMP
                   i_instruction == 16'h0038 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_AND | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // OR,B - or A with B, storing in TMP
                   i_instruction == 16'h0039 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // XOR,B - xor A with B, storing in TMP
                   i_instruction == 16'h003a ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADD,C - add A to C, storing into TMP.
                   i_instruction == 16'h003b ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUB,C - subtract A by C, storing in TMP
                   i_instruction == 16'h003c ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // AND,C - and A with C, storing in TMP
                   i_instruction == 16'h003d ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_AND | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // OR,C - or A with C, storing in TMP
                   i_instruction == 16'h003e ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // XOR,C - xor A with C, storing in TMP
                   i_instruction == 16'h003f ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SL shift A left 1 bit, storing in T. MSB is discarded
                   i_instruction == 16'h0040 ?
                     i_step == 'h2 ? c_EO | c_SL | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SR shift A right 1 bit, storing in T. MSB is discarded
                   i_instruction == 16'h0041 ?
                     i_step == 'h2 ? c_EO | c_SR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ROL rotate A left 1 bit, moving carry into the LSB and the MSB into Carry, storing in T.
                   i_instruction == 16'h0042 ?
                     i_step == 'h2 ? c_EO | c_ROL | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // HALT PROGRAM
                   i_instruction == 16'hffff ?
                     i_step == 'h2 ? c_HLT :
                     SHOULD_NEVER_REACH :
                   // NOP - do nothing and just advance counter
                   i_step == 'h2 ? c_ADV : SHOULD_NEVER_REACH;
endmodule

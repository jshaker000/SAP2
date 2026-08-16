// AUTO-GENERATED FILE. DO NOT EDIT BY HAND.
// Generated from opcodes.rb by gen_decoder.rb -- edit opcodes.rb and
// Instruction_Decoder.v.erb instead, then re-run `make Instruction_Decoder.v`.
//
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
                   // LDA - load A from RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0001 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDB - load B from RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0002 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDC - load C from RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0003 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STA - store A into RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0004 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STT - store T into RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0005 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_TRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STB - store B into RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0006 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STC - store C into RAM[addr]. addr is the next word in ram
                   i_instruction == 16'h0007 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RI | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDTA - load A from RAM[T] (indirect through T)
                   i_instruction == 16'h0008 ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDTB - load B from RAM[T] (indirect through T)
                   i_instruction == 16'h0009 ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDTC - load C from RAM[T] (indirect through T)
                   i_instruction == 16'h000a ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STTA - store A into RAM[T] (indirect through T)
                   i_instruction == 16'h000b ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STTB - store B into RAM[T] (indirect through T)
                   i_instruction == 16'h000c ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // STTC - store C into RAM[T] (indirect through T)
                   i_instruction == 16'h000d ?
                     i_step == 'h2 ? c_MI | c_TRO :
                     i_step == 'h3 ? c_RI | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVAT - put A in T
                   i_instruction == 16'h000e ?
                     i_step == 'h2 ? c_ARO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVAB - put A in B
                   i_instruction == 16'h000f ?
                     i_step == 'h2 ? c_ARO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVAC - put A in C
                   i_instruction == 16'h0010 ?
                     i_step == 'h2 ? c_ARO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVTA - put T in A
                   i_instruction == 16'h0011 ?
                     i_step == 'h2 ? c_TRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVTB - put T in B
                   i_instruction == 16'h0012 ?
                     i_step == 'h2 ? c_TRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVTC - put T in C
                   i_instruction == 16'h0013 ?
                     i_step == 'h2 ? c_TRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVBA - put B in A
                   i_instruction == 16'h0014 ?
                     i_step == 'h2 ? c_BRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVBT - put B in T
                   i_instruction == 16'h0015 ?
                     i_step == 'h2 ? c_BRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVBC - put B in C
                   i_instruction == 16'h0016 ?
                     i_step == 'h2 ? c_BRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVCA - put C in A
                   i_instruction == 16'h0017 ?
                     i_step == 'h2 ? c_CRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVCT - put C in T
                   i_instruction == 16'h0018 ?
                     i_step == 'h2 ? c_CRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVCB - put C in B
                   i_instruction == 16'h0019 ?
                     i_step == 'h2 ? c_CRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHA - push A onto the stack
                   i_instruction == 16'h001a ?
                     i_step == 'h2 ? c_SPU | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPA - pop the stack into A
                   i_instruction == 16'h001b ?
                     i_step == 'h2 ? c_SPO | c_SO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHT - push T onto the stack
                   i_instruction == 16'h001c ?
                     i_step == 'h2 ? c_SPU | c_TRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPT - pop the stack into T
                   i_instruction == 16'h001d ?
                     i_step == 'h2 ? c_SPO | c_SO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHB - push B onto the stack
                   i_instruction == 16'h001e ?
                     i_step == 'h2 ? c_SPU | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPB - pop the stack into B
                   i_instruction == 16'h001f ?
                     i_step == 'h2 ? c_SPO | c_SO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHC - push C onto the stack
                   i_instruction == 16'h0020 ?
                     i_step == 'h2 ? c_SPU | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPC - pop the stack into C
                   i_instruction == 16'h0021 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHPC - push PC onto the stack
                   i_instruction == 16'h0022 ?
                     i_step == 'h2 ? c_SPU | c_CO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPPC - pop the stack into PC. we increment the counter 2 times to get past the JMP instruction we presumably did just after PUSHPC
                   i_instruction == 16'h0023 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_J :
                     i_step == 'h3 ? c_CE :
                     i_step == 'h4 ? c_CE | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSHMA - push MA onto the stack
                   i_instruction == 16'h0024 ?
                     i_step == 'h2 ? c_SPU | c_MO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POPMA - pop the stack into MA
                   i_instruction == 16'h0025 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_MI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTA - output A
                   i_instruction == 16'h0026 ?
                     i_step == 'h2 ? c_ARO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTT - output T
                   i_instruction == 16'h0027 ?
                     i_step == 'h2 ? c_TRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTB - output B
                   i_instruction == 16'h0028 ?
                     i_step == 'h2 ? c_BRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTC - output C
                   i_instruction == 16'h0029 ?
                     i_step == 'h2 ? c_CRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDIA - load literal/resolved-address operand directly into A
                   i_instruction == 16'h002a ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDIB - load literal/resolved-address operand directly into B
                   i_instruction == 16'h002b ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDIC - load literal/resolved-address operand directly into C
                   i_instruction == 16'h002c ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JMP - jump to RAM[addr]. addr is the next word of RAM
                   i_instruction == 16'h002d ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_J | c_RO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIZ - jump to RAM[addr] if zero flag is set. addr is the next word of RAM
                   i_instruction == 16'h002e ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_zero ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J | c_RO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIC - jump to RAM[addr] if carry flag is set. addr is the next word of RAM
                   i_instruction == 16'h002f ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_carry ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J | c_RO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JIO - jump to RAM[addr] if odd flag is set. addr is the next word of RAM
                   i_instruction == 16'h0030 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE | (i_odd ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h3 ? c_J | c_RO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ADDI - add A to data, store into TMP. data is next word of ram
                   i_instruction == 16'h0031 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // SUBI - subtract A by data, store into TMP. data is next word of ram
                   i_instruction == 16'h0032 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ANDI - and A with data, store into TMP. data is next word of ram
                   i_instruction == 16'h0033 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_AND | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ORI - or A with data, store into TMP. data is next word of ram
                   i_instruction == 16'h0034 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // XORI - xor A with data, store into TMP. data is next word of ram
                   i_instruction == 16'h0035 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ADDB - add A to B, storing into TMP
                   i_instruction == 16'h0036 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // SUBB - subtract A by B, storing into TMP
                   i_instruction == 16'h0037 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ANDB - and A with B, storing into TMP
                   i_instruction == 16'h0038 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_AND | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ORB - or A with B, storing into TMP
                   i_instruction == 16'h0039 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // XORB - xor A with B, storing into TMP
                   i_instruction == 16'h003a ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ADDC - add A to C, storing into TMP
                   i_instruction == 16'h003b ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_ADD | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // SUBC - subtract A by C, storing into TMP
                   i_instruction == 16'h003c ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SUB | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ANDC - and A with C, storing into TMP
                   i_instruction == 16'h003d ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_AND | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ORC - or A with C, storing into TMP
                   i_instruction == 16'h003e ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_OR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // XORC - xor A with C, storing into TMP
                   i_instruction == 16'h003f ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_XOR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // SL - shift A left 1 bit, storing in T. MSB is discarded
                   i_instruction == 16'h0040 ?
                     i_step == 'h2 ? c_EO | c_SL | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // SR - shift A right 1 bit, storing in T. LSB is discarded
                   i_instruction == 16'h0041 ?
                     i_step == 'h2 ? c_EO | c_SR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ASR - arithmetic shift A right 1 bit (preserves sign), storing in T
                   i_instruction == 16'h0042 ?
                     i_step == 'h2 ? c_EO | c_ASR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ROL - rotate A left 1 bit, storing in T
                   i_instruction == 16'h0043 ?
                     i_step == 'h2 ? c_EO | c_ROL | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ROR - rotate A right 1 bit, storing in T
                   i_instruction == 16'h0044 ?
                     i_step == 'h2 ? c_EO | c_ROR | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ROLC - rotate A left through carry 1 bit, storing in T
                   i_instruction == 16'h0045 ?
                     i_step == 'h2 ? c_EO | c_ROLC | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // RORC - rotate A right through carry 1 bit, storing in T
                   i_instruction == 16'h0046 ?
                     i_step == 'h2 ? c_EO | c_RORC | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // INV - invert A (flip all bits), storing in T
                   i_instruction == 16'h0047 ?
                     i_step == 'h2 ? c_EO | c_INV | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // NEG - negate A (two's complement), storing in T
                   i_instruction == 16'h0048 ?
                     i_step == 'h2 ? c_EO | c_NEG | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // ABS - store |A| in T, updating flags
                   i_instruction == 16'h0049 ?
                     i_step == 'h2 ? c_EO | c_ABS | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // CHK - store A in T, updating flags (good to check for 0)
                   i_instruction == 16'h004a ?
                     i_step == 'h2 ? c_EO | c_CHK | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH :
                   // HALT - halt the program
                   i_instruction == 16'h004b ?
                     i_step == 'h2 ? c_HLT :
                     SHOULD_NEVER_REACH :
                   // NOP - do nothing and just advance counter
                   i_step == 'h2 ? c_ADV : SHOULD_NEVER_REACH;
endmodule

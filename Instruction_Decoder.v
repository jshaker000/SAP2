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
  parameter  INSTRUCTION_WIDTH  = 4;
  parameter  INSTRUCTION_STEPS  = 8;

  `include "instructions.vi"

  localparam STEP_WIDTH = $clog2(INSTRUCTION_STEPS);

  localparam                    [0:0] X_NOT_ZERO_FOR_SHOULD_NEVER_REACH = 1'b0;
  localparam [CONTROL_WORD_WIDTH-1:0] SHOULD_NEVER_REACH                = {CONTROL_WORD_WIDTH{X_NOT_ZERO_FOR_SHOULD_NEVER_REACH ? 1'bx : 1'b0}};

  input wire     [INSTRUCTION_WIDTH-1:0] i_instruction;
  input wire            [STEP_WIDTH-1:0] i_step;
  input wire                             i_zero;
  input wire                             i_odd;
  input wire                             i_carry;
  output wire   [CONTROL_WORD_WIDTH-1:0] o_control_word;

  // NOTE when reading addresses from RAM, they are contaned in little ENDIAN in the next 2 words
  assign o_control_word =
                 // Fetch, put prgm cntr in mem addr, fetch instruction, advance PC. All instructions start like this
                 // Also note, all instructions must end in a c_ADV to advance to the next instruction
                 i_step == 'h0 ? c_MI | c_CO :
                 i_step == 'h1 ? c_RO | c_II | c_CE :
                   // i_instruction == 8'h00 ? // unimplemented - defaults at bottom to NOP
                   // LDA - put data in RAM[addr] in A. addr is the next 2 bytes in ram
                   i_instruction == 8'h01 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RO | c_ARI | c_ADV:
                     SHOULD_NEVER_REACH:
                   // LDB - put data in RAM[addr] in B. addr is next 2 bytes in ram
                   i_instruction == 8'h02 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RO | c_BRI | c_ADV:
                     SHOULD_NEVER_REACH:
                   // LDC - put data in RAM[addr] in C. addr is next 2 bytes in ram
                   i_instruction == 8'h03 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RO | c_CRI | c_ADV:
                     SHOULD_NEVER_REACH:
                   // STA - put A in RAM[addr]. addr is next 2 bytes in ram
                   i_instruction == 8'h04 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RI | c_ARO | c_ADV:
                     SHOULD_NEVER_REACH:
                   // STT - put T in RAM[addr]. addr is next 2 bytes in ram
                   i_instruction == 8'h05 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RI | c_TRO | c_ADV:
                     SHOULD_NEVER_REACH:
                   // STB - put B in RAM[addr]. addr is next 2 bytes in ram
                   i_instruction == 8'h06 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RI | c_BRO | c_ADV:
                     SHOULD_NEVER_REACH:
                   // STC - put C in RAM[addr]. addr is next 2 bytes in ram
                   i_instruction == 8'h07 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RI | c_CRO | c_ADV:
                     SHOULD_NEVER_REACH:
                   // MOVA,T - put A in T.
                   i_instruction == 8'h08 ?
                     i_step == 'h2 ? c_ARO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVA,B - put A in B.
                   i_instruction == 8'h09 ?
                     i_step == 'h2 ? c_ARO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVA,C - put A in C.
                   i_instruction == 8'h0a ?
                     i_step == 'h2 ? c_ARO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,A - put T in A.
                   i_instruction == 8'h0b ?
                     i_step == 'h2 ? c_TRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,B - put T in B.
                   i_instruction == 8'h0c ?
                     i_step == 'h2 ? c_TRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVT,C - put T in C.
                   i_instruction == 8'h0d ?
                     i_step == 'h2 ? c_TRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,A - put B in A.
                   i_instruction == 8'h0e ?
                     i_step == 'h2 ? c_BRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,T - put B in T .
                   i_instruction == 8'h0f ?
                     i_step == 'h2 ? c_BRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVB,C - put B in C.
                   i_instruction == 8'h10 ?
                     i_step == 'h2 ? c_BRO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,A - put C in A.
                   i_instruction == 8'h11 ?
                     i_step == 'h2 ? c_CRO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,T - put C in T.
                   i_instruction == 8'h12 ?
                     i_step == 'h2 ? c_CRO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // MOVC,B - put C in B.
                   i_instruction == 8'h13 ?
                     i_step == 'h2 ? c_CRO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH A
                   i_instruction == 8'h14 ?
                     i_step == 'h2 ? c_SPU | c_ARO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP A
                   i_instruction == 8'h15 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH T
                   i_instruction == 8'h16 ?
                     i_step == 'h2 ? c_SPU | c_TRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP T
                   i_instruction == 8'h17 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_TRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH B
                   i_instruction == 8'h18 ?
                     i_step == 'h2 ? c_SPU | c_BRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP B
                   i_instruction == 8'h19 ?
                     i_step == 'h2 ? c_SPO | c_SO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH C
                   i_instruction == 8'h1a ?
                     i_step == 'h2 ? c_SPU | c_CRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP C
                   i_instruction == 8'h1b ?
                     i_step == 'h2 ? c_SPO | c_SO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH Program Counter - note that when we pop we increment the counter 3 times so this should almost always be immediately followed by a jump. then a pop would bring us to the following expression
                   i_instruction == 8'h1c ?
                     i_step == 'h2 ? c_SPU | c_CO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP Program Counter - note we increment the counter three times to get past the jump instruction we presumably did just after pushing
                   i_instruction == 8'h1d ?
                     i_step == 'h2 ? c_SPO | c_SO | c_J :
                     i_step == 'h3 ? c_CE :
                     i_step == 'h4 ? c_CE :
                     i_step == 'h5 ? c_CE | c_ADV :
                     SHOULD_NEVER_REACH :
                   // PUSH Memory Data Register
                   i_instruction == 8'h1e ?
                     i_step == 'h2 ? c_SPU | c_MDRO | c_ADV :
                     SHOULD_NEVER_REACH :
                   // POP Memory Data Register
                   i_instruction == 8'h1f ?
                     i_step == 'h2 ? c_SPO | c_SO | c_MDRLL | c_MDRLU | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTA
                   i_instruction == 8'h20 ?
                     i_step == 'h2      ? c_ARO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTT
                   i_instruction == 8'h21 ?
                     i_step == 'h2      ? c_TRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTB
                   i_instruction == 8'h22 ?
                     i_step == 'h2      ? c_BRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // OUTC
                   i_instruction == 8'h23 ?
                     i_step == 'h2      ? c_CRO | c_OI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,A - data to A. data is the next 1 byte of ram
                   i_instruction == 8'h24 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_ARI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,B - data to B. data is the next 1 byte of ram
                   i_instruction == 8'h25 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_BRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // LDI,C - data to C. data is the next 1 byte of ram
                   i_instruction == 8'h26 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_CRI | c_ADV :
                     SHOULD_NEVER_REACH :
                   // JUMP - jump to RAM[addr]. addr is the next 2 bytes of RAM
                   i_instruction == 8'h27 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_J  | c_MDRO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // JIZ - jump to RAM[addr] if zero flag is set. addr is the next 2 bytes of RAM
                   i_instruction == 8'h28 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE | (i_zero ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_J  | c_MDRO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // JIC - jump to RAM[addr] if zero flag is set. addr is the next 2 bytes of RAM
                   i_instruction == 8'h29 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE | (i_carry ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_J  | c_MDRO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // JIO - jump to RAM[addr] if odd flag is set. addr is the next 2 bytes of RAM
                   i_instruction == 8'h2a ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE | (i_odd ? {CONTROL_WORD_WIDTH{1'b0}} : c_ADV) :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_J  | c_MDRO | c_ADV:
                     SHOULD_NEVER_REACH :
                   // ADDI - add A to data, store into TMP. data is next 1 byte of ram
                   i_instruction == 8'h30 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBI - subtract A by data, store into TMP. data is next 1 byte of ram
                   i_instruction == 8'h31 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_TRI :
                     i_step == 'h4 ? c_EO | c_SU | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADD - add A to RAM[addr], storing into TMP. addr is next 2 bytes in ram
                   i_instruction == 8'h32 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RO | c_TRI :
                     i_step == 'h8 ? c_EO | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUB - add A to RAM[addr], storing into TMP. addr is next 2 bytes in ram
                   i_instruction == 8'h33 ?
                     i_step == 'h2 ? c_MI | c_CO | c_CE :
                     i_step == 'h3 ? c_RO | c_MDRLL :
                     i_step == 'h4 ? c_MI | c_CO | c_CE :
                     i_step == 'h5 ? c_RO | c_MDRLU | c_MDRMLTU :
                     i_step == 'h6 ? c_MI | c_MDRO :
                     i_step == 'h7 ? c_RO | c_TRI :
                     i_step == 'h8 ? c_EO | c_SU | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADDB - add A to B, storing into TMP.
                   i_instruction == 8'h34 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBB - subtract A by B, storing in TMP
                   i_instruction == 8'h35 ?
                     i_step == 'h2 ? c_BRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SU | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // ADDC - add A to C, storing into TMP.
                   i_instruction == 8'h36 ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // SUBC - subtract A by C, storing in TMP
                   i_instruction == 8'h37 ?
                     i_step == 'h2 ? c_CRO | c_TRI :
                     i_step == 'h3 ? c_EO | c_SU | c_TRI | c_EL | c_ADV :
                     SHOULD_NEVER_REACH:
                   // HALT PROGRAM
                   i_instruction == 8'hff ?
                     i_step == 'h2 ? c_HLT :
                     SHOULD_NEVER_REACH :
                   // NOP - do nothing and just advance counter
                   i_step == 'h2 ? c_ADV : SHOULD_NEVER_REACH;
endmodule

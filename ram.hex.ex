// Demonstrate a multiplication subroutine
27    // addr:0x0 | JMP,RUN | 1/3
1c    // addr:0x1 | JMP,RUN | 2/3
00    // addr:0x2 | JMP,RUN | 3/3
// MULT_START: (multiply A, B, storing result in T, then pop back to caller)
14    // addr:0x3 | PSH,A    | 1/1
18    // addr:0x4 | PSH,B    | 1/1
1a    // addr:0x5 | PSH,C    | 1/1
26    // addr:0x6 | LDI,C 00 | 1/2
00    // addr:0x7 | LDI,C 00 | 2/2
//   MULT_LOOP:
30   // addr:0x8  | ADDI 00        | 1/2
00   // addr:0x9  | ADDI 00        | 2/2
28   // addr:0xa  | JIZ MULT_END   | 1/3
17   // addr:0xb  | JIZ MULT_END   | 2/3
00   // addr:0xc  | JIZ MULT_END   | 3/3
31   // addr:0xd  | SUBI 01        | 1/2
01   // addr:0xe  | SUBI 01        | 2/2
16   // addr:0xf  | PSH,T          | 1/1
11   // addr:0x10 | MOVC,A         | 1/1
34   // addr:0x11 | ADD,B          | 1/1
15   // addr:0x12 | POP,A          | 1/1
0d   // addr:0x13 | MOVT,C         | 1/1
27   // addr:0x14 | JUMP,MULT_LOOP | 1/3
08   // addr:0x15 | JUMP,MULT_LOOP | 2/3
00   // addr:0x16 | JUMP,MULT_LOOP | 3/3
//   MULT_END:
12    // addr:0x17 | MOVC,T   | 1/1
1b    // addr:0x18 | POP,C    | 1/1
19    // addr:0x19 | POP,B    | 1/1
15    // addr:0x1a | POP,A    | 1/1
1d    // addr:0x1b | POP,PRGCN| 1/1
// DONE MULT
// RUN:
// 3 * 4 =
24    // addr:0x1c| LDI,A 03       | 1/2
03    // addr:0x1d| LDI,A 03       | 2/2
20    // addr:0x1e| OUT,A          | 1/1
25    // addr:0x1f| LDI,B 04       | 1/2
04    // addr:0x20| LDI,B 04       | 2/2
22    // addr:0x21| OUT,B          | 1/1
1c    // addr:0x22| PSH,PRGCN      | 1/2
27    // addr:0x23| JMP MULT_START | 1/3
03    // addr:0x24| JMP MULT_START | 1/3
00    // addr:0x25| JMP MULT_START | 1/3
21    // addr:0x26| OUT,T          | 1/1
// 8 * 9 =
24    // addr:0x27| LDI,A 09       | 1/2
09    // addr:0x28| LDI,A 09       | 2/2
20    // addr:0x29| OUT,A          | 1/1
25    // addr:0x2a| LDI,B 08       | 1/2
08    // addr:0x2b| LDI,B 08       | 2/2
22    // addr:0x2c| OUT,B          | 1/1
1c    // addr:0x2d| PSH,PRGCN      | 1/2
27    // addr:0x2e| JMP MULT_START | 1/3
03    // addr:0x2f| JMP MULT_START | 1/3
00    // addr:0x30| JMP MULT_START | 1/3
21    // addr:0x31| OUT,T          | 1/1
// 5 times tables
24    // addr:0x32| LDI,A 01       | 1/2
01    // addr:0x33| LDI,A 01       | 2/2
25    // addr:0x34| LDI,B 05       | 1/2
05    // addr:0x35| LDI,B 05       | 2/2
// LOOP_5_TIMES_TABLES
30    // addr:0x36| ADDI 205 (dec) | 1/2
cd    // addr:0x37| ADDI 205 (dec) | 2/2
29    // addr:0x38| JIC  HALT      | 1/3
46    // addr:0x39| JIC  HALT      | 2/3
00    // addr:0x3a| JIC  HALT      | 3/3
1c    // addr:0x3b| PSH,PRGCN      | 1/2
27    // addr:0x3c| JMP MULT_START | 1/3
03    // addr:0x3d| JMP MULT_START | 1/3
00    // addr:0x3e| JMP MULT_START | 1/3
21    // addr:0x3f| OUT,T          | 1/1
30    // addr:0x40| ADDI 1 (dec)   | 1/2
01    // addr:0x41| ADDI 1 (dec)   | 2/2
0b    // addr:0x42| MOVT,A         | 1/1
27    // addr:0x43| JMP LOOP_5_TIMES_TABLES | 1/3
36    // addr:0x44| JMP LOOP_5_TIMES_TABLES | 2/3
00    // addr:0x45| JMP LOOP_5_TIMES_TABLES | 3/3
// HALT
ff    // addr:0x46| HALT | 1/1

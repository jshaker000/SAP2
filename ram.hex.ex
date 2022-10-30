// Demonstrate a multiplication subroutine
002d  // addr:0x0000 | JMP,RUN | 1/2
001f  // addr:0x0001 | JMP,RUN | 2/2
// MULT_START: (multiply A, B, storing result in T, then pop back to caller)
001a  // addr:0x0002 | PSH,A      | 1/1
001e  // addr:0x0003 | PSH,B      | 1/1
0020  // addr:0x0004 | PSH,C      | 1/1
002c  // addr:0x0005 | LDI,C 0000 | 1/2
0000  // addr:0x0006 | LDI,C 0000 | 2/2
0034  // addr:0x0007 | SUB,B      | 1/1
002f  // addr:0x0008 | JIC MULT_LOOP | 1/2
000d  // addr:0x0009 | JIC MULT_LOOP | 2/2
// MULT_SWAP: If A > B swap A and B for speed
0015  // addr:0x000a | MOVB,T     | 1/1
000f  // addr:0x000b | MOVA,B     | 1/1
0011  // addr:0x000c | MOVT,A     | 1/1
//   MULT_LOOP:
0031 // addr:0x000d | ADDI 0000     | 1/2
0000 // addr:0x000e | ADDI 0000     | 2/2
002e // addr:0x000f | JIZ MULT_END  | 1/2
001a // addr:0x0010 | JIZ MULT_END  | 2/2
0032 // addr:0x0011 | SUBI 0001     | 1/2
0001 // addr:0x0012 | SUBI 0001     | 2/2
001c // addr:0x0013 | PSH,T         | 1/1
0017 // addr:0x0014 | MOVC,A         | 1/1
0033 // addr:0x0015 | ADD,B          | 1/1
001b // addr:0x0016 | POP,A          | 1/1
0013 // addr:0x0017 | MOVT,C         | 1/1
002d // addr:0x0018 | JUMP,MULT_LOOP | 1/2
000d // addr:0x0019 | JUMP,MULT_LOOP | 2/2
//   MULT_END:
0018  // addr:0x001a | MOVC,T   | 1/1
0021  // addr:0x001b | POP,C    | 1/1
001f  // addr:0x001c | POP,B    | 1/1
001b  // addr:0x001d | POP,A    | 1/1
0023  // addr:0x001e | POP,PRGCN| 1/1
// DONE MULT
// RUN:
// 3 * 4 =
002a  // addr:0x001f| LDI,A 0003     | 1/2
0003  // addr:0x0020| LDI,A 0003     | 2/2
0026  // addr:0x0021| OUT,A          | 1/1
002b  // addr:0x0022| LDI,B 0004     | 1/2
0004  // addr:0x0023| LDI,B 0004     | 2/2
0028  // addr:0x0024| OUT,B          | 1/1
0022  // addr:0x0025| PSH,PRGCN      | 1/2
002d  // addr:0x0026| JMP MULT_START | 1/2
0002  // addr:0x0026| JMP MULT_START | 2/2
0027  // addr:0x0028| OUT,T          | 1/1
// 8 * 9 =
002a  // addr:0x0029| LDI,A 0009     | 1/2
0009  // addr:0x002a| LDI,A 0009     | 2/2
0026  // addr:0x002b| OUT,A          | 1/1
002b  // addr:0x002c| LDI,B 0008     | 1/2
0008  // addr:0x002d| LDI,B 0008     | 2/2
0028  // addr:0x002e| OUT,B          | 1/1
0022  // addr:0x002f| PSH,PRGCN      | 1/2
002d  // addr:0x0030| JMP MULT_START | 1/2
0002  // addr:0x0031| JMP MULT_START | 2/2
0027  // addr:0x0032| OUT,T          | 1/1
// 5 times tables (done inefficiently by multiplying each time, but demoing a loop and subroutine call)
002a  // addr:0x0033| LDI,A 0001     | 1/2
0001  // addr:0x0034| LDI,A 0001     | 2/2
002b  // addr:0x0035| LDI,B 0005     | 1/2
0005  // addr:0x0036| LDI,B 0005     | 2/2
// LOOP_5_TIMES_TABLES
0031  // addr:0x0037| ADDI 2**16(1 - 1/5) (dec) | 1/2
cccd  // addr:0x0038| ADDI 2**16(1 - 1/5) (dec) | 2/2
002f  // addr:0x0039| JIC  HALT      | 1/2
0044  // addr:0x003a| JIC  HALT      | 2/2
0022  // addr:0x003b| PSH,PRGCN      | 1/2
002d  // addr:0x003c| JMP MULT_START | 1/2
0002  // addr:0x003d| JMP MULT_START | 1/2
0027  // addr:0x003e| OUT,T          | 1/1
0031  // addr:0x003f| ADDI 1 (dec)   | 1/2
0001  // addr:0x0040| ADDI 1 (dec)   | 2/2
0011  // addr:0x0041| MOVT,A         | 1/1
002d  // addr:0x0042| JMP LOOP_5_TIMES_TABLES | 1/2
0037  // addr:0x0043| JMP LOOP_5_TIMES_TABLES | 2/2
// HALT
ffff  // addr:0x0044| HALT | 1/1

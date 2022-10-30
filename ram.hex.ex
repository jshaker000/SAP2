// Implement Fibbonacci:
// INIT:
24    // addr:0x0 | LDA,I 00 | 1/2
00    // addr:0x1 | LDA,I 00 | 2/2
09    // addr:0x2 | MOVA,V   | 1/1
// LOOP:
34    // addr:0x3 | ADDB     | 1/2
29    // addr:0x4 | JIC,DONE | 1/3
00    // addr:0x5 | JIC,DONE | 2/3
0b    // addr:0x6 | JIC,DONE | 3/3
21    // addr:0x7 | OUT,T    | 1/1
0e    // addr:0x8 | MOVB,A   | 1/1
0c    // addr:0x9 | MOVT,B   | 1/1
27    // addr:0xa | JUMP,LOOP| 1/3
00    // addr:0xa | JUMP,LOOP| 1/3
03    // addr:0xa | JUMP,LOOP| 1/3
// DONE:
ff    // addr:0xb | HALT | 1/1

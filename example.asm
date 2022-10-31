  JMP RUN
; Multiply A * B and put into T
; assume the caller pushed their PC to the stack so we can pop back when done
MULT_START:
  PUSHA
  PUSHB
  PUSHC
  LDIC 0
  SUBB
  JIC MULT_LOOP
  MOVBT
  MOVAB
  MOVTA
MULT_LOOP:
  ADDI 0
  JIZ MULT_END
  SUBI 1
  PUSHT
  MOVCA
  ADDB
  POPA
  MOVTC
  JMP MULT_LOOP
MULT_END:
  MOVCT
  POPC
  POPB
  POPA
  POPPC
RUN:
  ; 3 * 4
  LDIA 3
  OUTA
  LDIB 4
  OUTB
  PUSHPC
  JMP MULT_START
  OUTT
  ; 9 * 8
  LDIA 9
  OUTA
  LDIB 8
  OUTB
  PUSHPC
  JMP MULT_START
  OUTT
  ; loop to compute the 5 times tables with repeated multiplication
  ; yes, this is less efficient than just adding 5 but it shows calling a subroutine in a loop
  LDIA 1
  LDIB 5
LOOP_5_TIMES_TABLES:
  ; ADD 2**16 (1 - 1/5). If this carries, we know we are done
  ADDI 52428
  JIC HLT
  PUSHPC
  JMP MULT_START
  OUTT
  ADDI 1
  MOVTA
  JMP LOOP_5_TIMES_TABLES
HLT:
  HALT

  JMP RUN
; Multiply A * B and put into T
; assume the caller pushed their PC to the stack so we can pop back when done
MULT_START:
  PUSHA
  PUSHB
  PUSHC
  MOVAC
  ; if B > A, swap so we can always know B is the smaller of the two for loop optimization
  SUBB
  JIC  MULT_SWAP
  LDIA 0
  JMP  MULT_LOOP
MULT_SWAP:
  MOVBC
  MOVAB
  LDIA 0
MULT_LOOP:
  ; check if we are done
  PUSHA
  MOVBA
  CHK
  POPA
  JIZ MULT_END
  ; check if B is even or odd
  JIO MULT_ADD
  JMP MULT_SHIFT
MULT_ADD:
  ADDC
  MOVTA
MULT_SHIFT:
  PUSHA
  MOVBA
  SR
  MOVTB
  MOVCA
  SL
  MOVTC
  POPA
  JMP MULT_LOOP
MULT_END:
  MOVAT
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
  ; 127 * 307
  LDIA 127
  OUTA
  LDIB 307
  OUTB
  PUSHPC
  JMP MULT_START
  OUTT
  ; loop to compute the 13 times tables with repeated multiplication
  ; yes, this is less efficient than just adding 13 but it shows calling a subroutine in a loop
  LDIA 1
  LDIB 13
LOOP_13_TIMES_TABLES:
  ; ADD 2**16 (1 - 1/13). If this carries, we know we are done
  ADDI 60495
  JIC HLT
  PUSHPC
  JMP MULT_START
  OUTT
  ADDI 1
  MOVTA
  JMP LOOP_13_TIMES_TABLES
HLT:
  HALT

; Find primes up to SIEVE_LENGTH by sieving
; In the SIEVE method, we store 0 in a variable if it is prime, 1 if it is not prime
; When we find a prime number, print it then set all of its multiples to be not prime
CONSTANT SIEVE_LENGTH 32768
RESERVE  sieve[SIEVE_LENGTH]
; Generally B holds out current index, or our 'current prime'
START:
  LDIB 2
LOOP:
  ; check if we are done
  MOVBA
  SUBI SIEVE_LENGTH
  JIZ HLT
  ; retrieve sieve[B] and check if it is prime or not
  ADDI sieve
  LDTA
  MOVTC
  ADDI 0
  JIZ SIEVE_START
SIEVE_RET:
  ; increment the current prime by 1
  MOVBA
  ADDI 1
  MOVTB
  JMP LOOP
; print the current prime, then loop through and store 1 in all its multiples
SIEVE_START:
  OUTB
SIEVE_LOOP:
  MOVCA
  ADDB
  MOVTC
  MOVTA
  SUBI sieve
  MOVTA
  SUBI SIEVE_LENGTH
  JIC SIEVE_LOOP_CONTINUE
  JMP SIEVE_RET
SIEVE_LOOP_CONTINUE:
  MOVCT
  LDIA 1
  STTA
  JMP SIEVE_LOOP
HLT:
  HALT

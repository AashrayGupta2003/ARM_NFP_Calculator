.section .data
myNumbers: .word 0x12345678, 0x87654321                   @ our non-floating point numbers    
@ myNumbers: .word 0x00040000, 0x000A0000                 @ our non-floating point numbers
@ myNumbers: .word 0x0028E000, 0x00010000                 @ our non-floating point numbers
@ myNumbers: .word 0x001C0000, 0x00240000                 @ our non-floating point numbers
@ myNumbers: .word 0x001C0000, 0x00240000                 @ our non-floating point numbers
@ myNumbers: .word 0x01f70000, 0x01d2a000                 @ out non-floating point numbers
@ myNumbers: .word 0x81f70000, 0x01d2a000                 @ out non-floating point numbers
@ myNumbers: .word 0x81d2a000, 0x81f70000                 @ out non-floating point numbers



@                     n1          n2
sign: .word 0b10000000000000000000000000000000          @ number for extracing the `Sign` bit
exp: .word 0b01111111111110000000000000000000           @ number for extracing the `Exponent` bits
mantissa: .word 0b00000000000001111111111111111111      @ number for extracing the `Mantissa` bits

.section .text
.global _start

@****************************************************************************************************
loadNumbers:                            @ function to load numbers in register
stmfd sp!, {lr}
ldr r5, =sign                           @ loading r5 with extraction bits for sign
ldr r5, [r5]
ldr r6, =exp                            @ loading r6 with extraction bits for exponent
ldr r6, [r6]
ldr r7, =mantissa                       @ loading r7 with extraction bits for mantissa
ldr r7, [r7]
ldr r0, [r1], #4                        @ r0 = n1 (in hexadecimal form)
and r2, r0, r5                          @ r2 = sign bit of n1
and r3, r0, r6                          @ r3 = exponent bits of n1
and r4, r0, r7                          @ r4 = mantissa bits of n1
ldr r0, [r1], #4                        @ r0 = n2 (in hexadecimal form)
and r5, r0, r5                          @ r5 = sign bit of n2
and r6, r0, r6                          @ r6 = exponent bits of n2
and r7, r0, r7                          @ r7 = mantissa bits of n2
@                     S   E   M
@ now n1 is stored in r2, r3, r4 
@ now n2 is stored in r5, r6, r7 
@ Ans to be stored in r0, r8, r9
ldmfd sp!, {pc}

@****************************************************************************************************
storeAnswer:
stmfd sp!, {lr}
str r0, [r1]
ldmfd sp!, {pc}

@****************************************************************************************************
nfpAdd:
stmfd sp!, {r0, r2-r9, lr}              @ creating activation block for the function
bl loadNumbers
add r4, r4, #0b00000000000010000000000000000000 @ converting mantissa to significand
add r7, r7, #0b00000000000010000000000000000000 @ converting mantissa to significand
tst r2, #0x80000000                     @ checking whether to take 2's complement of significand or not
beq branch1                             @ branch if not to take 2's complement of significand
mov r10, #-1
mul r4, r4, r10                         @ taking 2's complement of mantisssa
branch1:                                
tst r5, #0x80000000                     @ checking whether to take 2's complement of mantissa or not
beq branch2                             @ branch if not to take 2's complement of mantissa
mul r7, r7, r10                         @ taking 2's complement of mantissa
branch2:
@
lsl r3, #1                              @ because msb of exponent is empty
lsl r6, #1
asr r3, #20                             @ so that carry bit and sign bit remain preserved
asr r6, #20
cmp r3, r6
moveq r8, r3                            @ exponent of result
movgt r8, r3
movlt r8, r6
lsl r8, #19                             @ final exponent in `r8`
and r8, #0x7fffffff                     @ clearing the 32 bit position
@
mov r9, r3                              @ storing the number of bits to shift the significand in r9 (temp)
beq noNeed                              @ branching if there is no need to adjust the significand positions
subgt r9, r3, r6
asrgt r7, r9
sublt r9, r6, r3
asrlt r4, r9                            
noNeed:                                 @ now we have got the mantissa in proper place (exponent is same)
add r9, r4, r7                          @ now we got addition result
@                                       @ but sign determination, 2's comp to signed magnitude, normalisation has to be done
ands r0, r9, #0x80000000                @ determine signed bit of answer
beq alreadyInSignedMagnitude            @ converting 2's complement ans (if negative) to signed magnitude
mul r9, r9, r10
alreadyInSignedMagnitude:
@                                       @ `Normalisation of result`
mov r10, #0b0000000000100000000000000000000 @ `1` at 21st position
tst r9, r10                             @ 1 at 21st bit position, then only single step normalisation is required
lsr r10, #1                             @ r10 will always check 20th bit position (used in while loop)
beq while                               @ 0 at 21st bit position, then go to normalisation1
lsr r9, #1                              @ actual normalisation (shifting one bit right)
add r8, r8, #0b00000000000010000000000000000000 @ adding 1 to exponent
b normalisationDone
@
while:
tst r9, r10                         
bne normalisationDone                   @ if 1 is there at 20th position, then normalisation is done
lsl r9, r9, #1                          @ shifting the significand one bit towards left
sub r8, r8, #0b00000000000010000000000000000000 @ reducing the exponent by 1
b while
@
normalisationDone:
ldr r10, =mantissa
ldr r10, [r10]
and r9, r9, r10                         @ filtering out only mantissa bits

add r0, r0, r8                          @ putting together all three pieces of number together
add r0, r0, r9                          @ answer is in `r0`
bl storeAnswer
ldmfd sp!, {r0, r2-r9, pc}
@                     S   E   M
@ now n1 is stored in r2, r3, r4 
@ now n2 is stored in r5, r6, r7 
@ Ans to be stored in r0, r8, r9

@****************************************************************************************************
nfpMultiply:
stmfd sp!, {r0, r2-r9, lr}              @ creating the activation block for function
bl loadNumbers                          @ this function loads the numbers into registers
@ getting sign bit of answer
eor r0, r2, r5
@ getting exponent of answer
add r8, r3, r6
@ getting mantissa of answer
mov r10, #0b00000000000010000000000000000000
orr r4, r4, r10                          @ adding the significand extra bit `1.___`
orr r7, r7, r10
lsr r4, #4                               @ right shift by four bits (so that multiplication result comes in 32 bit)
lsr r7, #4
mul r9, r4, r7
@                                        @ using r5, r7 as they are not required again
mov r5, #0b01111111111111111111111111111111 @ storing extraction bit for `MSB`
bics r7, r9, r5                          @ checking whether MSB is 0 or 1
and r9, r9, r5                           @ removing the MSB of result (significand to mantissa)
add r8, r8, #0b10000000000000000000      @ adding one to exponent
mov r7, #12                              @ loading r7 with number of bits for `logical shift right`
bne notRenormalisation                   @ if renormalisation was not required
lsr r5, #1                               @ storing extraction bit for `Second MSB`
and r9, r9, r5                           @ removing actual MSB of result (significand to mantissa)
sub r8, r8, #0b10000000000000000000      @ subtracting the extra `1` added before for renormalisation
sub r7, r7, #1                           @ because we have only 31 bits as of now
notRenormalisation:
lsr r9, r7                               @ putting mantissa in its proper place (last 19 bits)
@
add r0, r0, r8                           @ putting together all three pieces of number together
add r0, r0, r9                           @ answer is in `r0` 
bl storeAnswer
ldmfd sp!, {r0, r2-r9, pc}

@****************************************************************************************************
_start:

ldr r1, =myNumbers                       @ r1 contains the address of memory location which contains the acutal nfp numbers

@ bl nfpAdd
bl nfpMultiply
@ =============================================================================
@ asm_func.S
@
@ add_3, add_10, arr_copy, multiply: example functions from the course template.
@
@ mul_add_row, mul_add_shift, mul_add_col: the inner loops of montMulOpt
@ (montgomery.c), rewritten in assembly. How we optimised them:
@
@ 1. Find where the time goes. montMul has three inner loops that each run
@    ~size^2/2 times (~500-1000x for size = 32). Everything else (the small
@    carry tails, sub_cond, the final copy) runs only ~size times, so the
@    inner loops are the only parts worth writing in assembly.
@
@ 2. Use umaal for "multiply and add with carry".
@    The first two loops compute  sum = t[j] + x[j]*y + C,  C = sum >> 32.
@    umaal RdLo, RdHi, Rn, Rm  does  {RdHi, RdLo} = Rn*Rm + RdLo + RdHi,
@    i.e. this whole step (32x32 multiply + two 32-bit adds + carry) in ONE
@    instruction, and it can never overflow 64 bits:
@    (2^32-1)^2 + 2*(2^32-1) = 2^64-1. GCC almost never generates umaal.
@    The carry C stays in RdHi from one iteration to the next for free.
@
@ 3. Keep everything in registers inside the loop.
@    Pointers walk through the arrays with post-increment addressing
@    ([rX], #4) instead of computing t[i+j] each time, the carry and the
@    3-word accumulator (mul_add_col) live in registers and are only
@    written back to memory at the end, and loops count down to 0 with
@    subs so no separate cmp is needed.
@
@ 4. No malloc and no aliasing problems.
@    montMulOpt works in a local stack array t and only writes res at the
@    end, so res may be the same array as a or b (e.g. x = x*x in modexp).
@
@ Calling convention (AAPCS): arguments in r0-r3, return value in r0,
@ r0-r3 and r12 may be overwritten, r4-r11 must be saved (push/pop).
@ Push an even number of registers to keep the stack 8-byte aligned.
@
@ For the PC build (make host) asm_func_host.c contains C versions of these
@ functions, they must stay identical in behaviour.
@ =============================================================================

.text

.global add_3
.func add_3, add_3
.type add_3, %function

add_3:
add r0, r0, r1
add r0, r0, r2
bx lr
.endfunc

.text

.global add_10
.func add_10, add_10
.type add_10, %function

add_10:
cmp r1, #0
beq end_add
mov r2, #0
add_loop:
	ldr r3, [r0], #4
	add r2, r2, r3
	subs r1, r1, #1
	bne  add_loop
mov r0, r2
end_add:
bx lr
.endfunc

.text

.global arr_copy
.func arr_copy, arr_copy
.type arr_copy, %function

arr_copy:
cmp r2, #0
beq end_add
copy_loop:
	ldr r3, [r0], #4
	str r3, [r1], #4
	subs r2, r2, #1
	bne  copy_loop
end_copy:
bx lr
.endfunc

.text

.global multiply
.func multiply, multiply
.type multiply, %function

multiply:
	push {r4-r9}
	// If more registers are used in the function make sure to do push them on the stack to preserve them
	ldr r4, [sp, #24]		@m pointer is stored in R4
	ldr r5, [sp, #28]		@n pointer is stored in R5
	add r1, r1, r0, lsl #2
	ldr r6, [r4]
	ldr r7, [r5]
	umull r8, r9, r6, r7
	ldr r6, [r2]
	ldr r7, [r3]
	umull r4, r5, r6, r7
	adds r8, r8, r4
	adc r9, r9, r5
	stmia r1, {r8, r9}
	pop {r4-r9}
	bx lr
.endfunc

.text

.global mul_add_row
.func mul_add_row, mul_add_row
.type mul_add_row, %function

@ r0 = t, r1 = a, r2 = bi, r3 = len
@ for j in 0..len-1: {C, t[j]} = t[j] + a[j]*bi + C
@ returns the final carry C in r0
mul_add_row:
	push {r4, r5}
	mov r4, #0					@ C = 0
	cmp r3, #0
	beq mul_add_row_end
mul_add_row_loop:
	ldr r5, [r0]				@ r5 = t[j]
	ldr r12, [r1], #4			@ r12 = a[j], a++
	umaal r5, r4, r12, r2		@ {r4, r5} = a[j]*bi + t[j] + C
	str r5, [r0], #4			@ t[j] = low word, t++
	subs r3, r3, #1
	bne mul_add_row_loop
mul_add_row_end:
	mov r0, r4					@ return C
	pop {r4, r5}
	bx lr
.endfunc

.text

.global mul_add_shift
.func mul_add_shift, mul_add_shift
.type mul_add_shift, %function

@ r0 = t, r1 = n, r2 = m, r3 = size (must be >= 1)
@ j = 0:           {C, -}      = t[0] + n[0]*m        (low word is 0 by choice of m, dropped)
@ j = 1..size-1:   {C, t[j-1]} = t[j] + n[j]*m + C    (result shifted down one word)
@ returns the final carry C in r0
mul_add_shift:
	push {r4, r5}
	mov r4, #0					@ C = 0
	ldr r5, [r0], #4			@ r5 = t[0], t -> t[1]
	ldr r12, [r1], #4			@ r12 = n[0], n -> n[1]
	umaal r5, r4, r12, r2		@ {r4, r5} = n[0]*m + t[0] + 0, r5 is 0: only keep C
	subs r3, r3, #1				@ size - 1 words left
	beq mul_add_shift_end
mul_add_shift_loop:
	ldr r5, [r0], #4			@ r5 = t[j], t -> t[j+1]
	ldr r12, [r1], #4			@ r12 = n[j], n -> n[j+1]
	umaal r5, r4, r12, r2		@ {r4, r5} = n[j]*m + t[j] + C
	str r5, [r0, #-8]			@ t[j-1] = low word (r0 is at t[j+1], so t[j-1] is 8 bytes back)
	subs r3, r3, #1
	bne mul_add_shift_loop
mul_add_shift_end:
	mov r0, r4					@ return C
	pop {r4, r5}
	bx lr
.endfunc

.text

.global mul_add_col
.func mul_add_col, mul_add_col
.type mul_add_col, %function

@ r0 = t (= &t[size-1]), r1 = b (= &b[i+1]), r2 = a (= &a[size-1]), r3 = len
@ for len steps: {t[2], t[1], t[0]} += b[j] * a[k],  j going up, k going down
@ Used for the products b[j]*a[k] with j + k = size + i that the first loop
@ skipped (the top half of a*b), added into the 3-word accumulator at the top of t.
@ The C version did two separate 64-bit adds per step, here the accumulator
@ stays in r4-r6 for the whole loop: adds/adcs/adc = 96-bit add in 3 instructions.
mul_add_col:
	cmp r3, #0
	bxeq lr						@ nothing to do (last iteration, i = size-1)
	push {r4-r9}
	ldmia r0, {r4, r5, r6}		@ r4 = t[size-1], r5 = t[size], r6 = t[size+1]
mul_add_col_loop:
	ldr r7, [r1], #4			@ r7 = b[j], b++
	ldr r8, [r2], #-4			@ r8 = a[k], a-- (walks backwards)
	umull r9, r12, r7, r8		@ {r12, r9} = b[j] * a[k]
	adds r4, r4, r9				@ accumulator += 64-bit product,
	adcs r5, r5, r12			@ carry rippling up through
	adc r6, r6, #0				@ all three words
	subs r3, r3, #1
	bne mul_add_col_loop
	stmia r0, {r4, r5, r6}		@ write the accumulator back to t[size-1..size+1]
	pop {r4-r9}
	bx lr
.endfunc


@USEFUL FUNCTIONS

@ add Rx, Ry, Rz	//Rx = Ry + Rz  second operand can be constant
@ sub Rx, Ry, Rz	//Rx = Ry - Rz second operand can be constant
@ addc Rx, Ry, Rz	//Rx = Ry + Rz + CARRY   one operand can be constant
@ cmp Rx, Ry		//compares Rx and Ry and if they are equal sets Z flag, otherwise resets Z flag (works by subtracting two values and checks if result is zero)
@ b{cond} <label>		//Jumps to given label in the code if given condition is satisfied
@ umull Rn, Rm, Rx, Ry 	//{Rm, Rn} = Rx * Ry Multiplies unsigned 32bit values in Rx and Ry. Stores the higher 32 bits in Rm, and lower in Rn
@ ldr Rx, [Ry]		//Loads from memory pointed by Ry to register Rx, see addressing modes for post increment, pre decrement
@ str Rx, [Ry]		//Stores to memory pointed by Ry value in register Rx, see addressing modes for post increment, pre decrement
@ pop {}			//Pops values from stack to specified registers in order they are specified
@ push {}			//Push registers to stack in orded they are specified
@ ldmia rx, {set of registers} //Loads to specified set of registers memory values, starting from rx. Increasing addresses
@ stmia rx, {set of registers} //Stores specified set of registers in memory, starting from address pointed by rx. Increasing addresses

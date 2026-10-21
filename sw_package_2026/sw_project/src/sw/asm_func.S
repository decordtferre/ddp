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
	add r1, r1, r0, lsl #2 		// r1 = r1 + r0 * 4 calculate destination address
	ldr r6, [r4] 				// Load value from memory pointed by r4 into r6
	ldr r7, [r5] 				// Load value from memory pointed by r5 into r7
	umull r8, r9, r6, r7 		// Multiply r6 and r7, store lower 32 bits in r8 and higher 32 bits in r9
	ldr r6, [r2] 				// Load value from memory pointed by r2 into r6
	ldr r7, [r3] 				// Load value from memory pointed by r3 into r7
	umull r4, r5, r6, r7 		// Multiply r6 and r7, store lower 32 bits in r4 and higher 32 bits in r5
	adds r8, r8, r4 			// Add lower 32 bits of second multiplication to r8 with carry
	adc r9, r9, r5 				// Add higher 32 bits of second multiplication to r9 with carry
	stmia r1, {r8, r9} 			// Store the result of the multiplication to memory starting at address in r1
	pop {r4-r9} 				// Restore the values of r4 to r9 from the stack
	bx lr
.endfunc

.global mont_inner_loop1
.func mont_inner_loop1, mont_inner_loop1
.type mont_inner_loop1, %function

mont_inner_loop1:
    // Read the 5th argument (size) off the stack into r12
    LDR     r12, [sp, #0]

    // If size <= 1, there are 0 iterations; return C directly in r0
    CMP     r12, #1
    BLE     .Learly_exit

    // Save callee-saved registers we will use
    PUSH    {r4-r6, lr}

    // Set loop counter: count = size - 1
    SUBS    r12, r12, #1

    // Setup pointers:
    // r0 = write pointer (&t[0])
    // r4 = read pointer  (&t[1])
    // r1 = read pointer  (&n[1])
    ADD     r4, r0, #4
    ADD     r1, r1, #4

.Lloop:
    LDR     r5, [r1], #4        // r5 = n[j], advance n read pointer
    LDR     r6, [r4], #4        // r6 = t[j], advance t read pointer

    // {r3, r6} = r3 (C) + r6 (t[j]) + (r2 (m) * r5 (n[j]))
    // r6 gets the low 32 bits (new t[j-1])
    // r3 gets the high 32 bits (new C)
    UMAAL   r6, r3, r2, r5

    STR     r6, [r0], #4        // t[j-1] = r6, advance t write pointer

    SUBS    r12, r12, #1        // decrement loop counter
    BNE     .Lloop

    // Put the final carry (r3) into r0 for the return value
    MOV     r0, r3

    // Restore saved registers and return
    POP     {r4-r6, pc}

.Learly_exit:
    MOV     r0, r3              // return initial carry
    BX      lr

    .size mont_inner_loop1, .-mont_inner_loop1
.endfunc

.global mont_row_mac
.func mont_row_mac, mont_row_mac
.type mont_row_mac, %function

mont_row_mac:
    // r0 = &t[i], r1 = a, r2 = b[i], r3 = count; returns carry out in r0
    // t[j] = low(t[j] + a[j]*b[i] + C), C = high(...)
    CMP     r3, #0
    MOVEQ   r0, #0
    BXEQ    lr

    PUSH    {r4-r5}
    MOV     r12, #0             // carry

.Lrowloop:
    LDR     r4, [r1], #4        // a[j]
    LDR     r5, [r0]            // t[i+j]
    UMAAL   r5, r12, r4, r2     // {r12, r5} = a[j]*b[i] + r5 + r12
    STR     r5, [r0], #4
    SUBS    r3, r3, #1
    BNE     .Lrowloop

    MOV     r0, r12
    POP     {r4-r5}
    BX      lr

    .size mont_row_mac, .-mont_row_mac
.endfunc

.global mont_inner_loop2
.func mont_inner_loop2, mont_inner_loop2
.type mont_inner_loop2, %function

mont_inner_loop2:
    // r0 = &t[size-1], r1 = &b[i+1] (ascending), r2 = &a[size-1] (descending), r3 = count
    // Accumulates sum(b[j]*a[..]) into the 96-bit value {t[size+1], t[size], t[size-1]}
    CMP     r3, #0
    BXLE    lr

    PUSH    {r4-r9}
    LDR     r4, [r0]            // acc0 = t[size-1]
    LDR     r5, [r0, #4]        // acc1 = t[size]
    LDR     r6, [r0, #8]        // acc2 = t[size+1]

.L2loop:
    LDR     r12, [r1], #4       // b[j]
    LDR     r9, [r2], #-4       // a[size-j+i]
    UMULL   r7, r8, r9, r12
    ADDS    r4, r4, r7
    ADCS    r5, r5, r8
    ADC     r6, r6, #0
    SUBS    r3, r3, #1
    BNE     .L2loop

    STR     r4, [r0]
    STR     r5, [r0, #4]
    STR     r6, [r0, #8]
    POP     {r4-r9}
    BX      lr

    .size mont_inner_loop2, .-mont_inner_loop2
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

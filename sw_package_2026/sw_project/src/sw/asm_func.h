/*
 * asm_func.h
 *
 *  Created on: May 13, 2016
 *      Author: dbozilov
 */

#ifndef ASM_FUNC_H_
#define ASM_FUNC_H_

#include <stdint.h>

// a will be in register R0, b in R1, c in R2
// Result is stored in register r0
uint32_t add_3(uint32_t a, uint32_t b, uint32_t c);

//Adds all elements of array
uint32_t add_10(uint32_t *a, uint32_t n);

//Copies array a to array b
uint32_t arr_copy(uint32_t *a, uint32_t *b, uint32_t n);

// Function that calculates {t[i+1], t[i]} = a[0]*b[0] + m[0]*n[0]
// i is in R0, pointer to t array in R1, a array in R2, b array in R3
// pointer to m array is stored in [SP]
// pointer to n array is stored in [SP, #4] (one position above m)
void multiply(uint32_t i, uint32_t *t, uint32_t *a, uint32_t *b, uint32_t *m, uint32_t *n);

extern uint32_t mont_inner_loop1(uint32_t *t, const uint32_t *n, uint32_t m, uint32_t C, int size);

// t[i+j] += a[j]*bi (with carry) for j < count (= size-i), then adds the carry into t[size], t[size+1]. t points to &t[i].
extern void mont_row_mac(uint32_t *t, const uint32_t *a, uint32_t bi, uint32_t count);

// m = t[0]*n_prime0; t = (t + m*n) >> 32 limb, including the t[size], t[size+1] fix-up
extern void mont_reduce_step(uint32_t *t, const uint32_t *n, uint32_t n_prime0, uint32_t size);

// res = (t >= n) ? t - n : t; t and res have size+1 words, n has size words
extern void mont_sub_cond(const uint32_t *t, const uint32_t *n, uint32_t *res, uint32_t size);

// Zeroes count words
extern void mont_zero(uint32_t *p, uint32_t count);

// t points to &t[size-1], b to &b[i+1], a to &a[size-1]; count = size-i-1
extern void mont_inner_loop2(uint32_t *t, const uint32_t *b, const uint32_t *a, uint32_t count);


#endif /* ASM_FUNC_H_ */

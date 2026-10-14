/*
 * asm_func_host.c
 *
 * C versions of the functions in asm_func.S, ONLY for the PC build (make host),
 * since ARM assembly cannot run on a PC. Empty when building for the board.
 * They must compute exactly the same thing as the asm versions.
 */

#ifdef HOST

#include "asm_func.h"

uint32_t mul_add_row(uint32_t *t, uint32_t *a, uint32_t bi, uint32_t len)
{
	uint32_t C = 0;
	for (uint32_t j = 0; j < len; j++) {
		uint64_t sum = (uint64_t)t[j] + (uint64_t)a[j]*bi + C;
		C = (sum >> 32);
		t[j] = (uint32_t)sum;
	}
	return C;
}

uint32_t mul_add_shift(uint32_t *t, uint32_t *n, uint32_t m, uint32_t size)
{
	uint64_t sum = (uint64_t)t[0] + (uint64_t)n[0]*m;
	uint32_t C = (sum >> 32);
	for (uint32_t j = 1; j < size; j++) {
		sum = (uint64_t)t[j] + (uint64_t)n[j]*m + C;
		C = (sum >> 32);
		t[j - 1] = (uint32_t)sum;
	}
	return C;
}

void mul_add_col(uint32_t *t, uint32_t *b, uint32_t *a, uint32_t len)
{
	for (uint32_t j = 0; j < len; j++) {
		uint64_t sum = (uint64_t)t[0] + (uint64_t)b[j] * a[-(int32_t)j];
		uint32_t C = (sum >> 32);
		t[0] = (uint32_t)sum;
		sum = (uint64_t)t[1] + C;
		C = (sum >> 32);
		t[1] = (uint32_t)sum;
		t[2] = t[2] + C;
	}
}

#endif

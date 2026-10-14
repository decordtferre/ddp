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

#endif

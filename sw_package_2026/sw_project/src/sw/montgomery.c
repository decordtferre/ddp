/*
 * montgomery.c
 *
 */

#include <stdlib.h>
#include "montgomery.h"
#include "asm_func.h"

/*
 * procedure SUB COND(u, n, SIZE) . Subtract n array from u if u is
   larger than n. u has SIZE+1 elements, n has SIZE+1 elements, n[SIZE] =
   0
 */
void sub_cond(uint32_t *u, uint32_t *n, uint32_t size)
{
	uint32_t B = 0;
	uint32_t t[size + 1];

	for (uint8_t i = 0; i < size; i++) {
		uint64_t diff = (uint64_t)u[i]-n[i]-B;
		t[i] = (uint32_t)diff;
		B = (diff >> 63) & 1ULL;
	}

	uint64_t diff = (uint64_t)u[size] - B;
	t[size] = (uint32_t)diff;
	B = (diff >> 63) & 1ULL;

	if (B == 0) {
		for (uint32_t i = 0; i <= size; i++) {
			u[i] = t[i];
		}
	}
}

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
void montMul(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{
	uint32_t *t = calloc(size + 2, sizeof(uint32_t));
	uint32_t nprime_0 = n_prime[0];
	uint32_t C;
	uint64_t sum;
	uint8_t i;
	uint8_t j;

	for (i = 0; i < size; i++) {
		C = 0;
		for (j = 0; j < size - i; j++) {
			sum = (uint64_t)t[i + j] + (uint64_t)a[j]*b[i] + C;
			C = (sum >> 32);
			t[i+j] = (uint32_t)sum;
		}

		sum = (uint64_t)t[size] + (uint64_t)C;
		C = (sum >> 32);
		t[size] = (uint32_t)sum;
		t[size + 1] = t[size + 1] + C;
	}

	for (i = 0; i < size; i++) {

		uint32_t m = t[0] * nprime_0; // onderste 32 bit selecteren adhv 32 bit type
		sum = (uint64_t)t[0] + (uint64_t)m*(uint64_t)n[0];
		C = (sum >> 32);

		for (j = 1; j < size; j++) {
			sum = (uint64_t)t[j] + (uint64_t)m * (uint64_t)n[j] + (uint64_t)C;
			C = (sum >> 32);
			t[j - 1] = (uint32_t)sum;
		}

		sum = (uint64_t)t[size] + (uint64_t)C;
		C = (sum >> 32);
		t[size - 1] = (uint32_t)sum;
		t[size] = t[size + 1] + C;
		t[size + 1] = 0;

		for (j = i+1; j < size; j++) {
			sum = (uint64_t)t[size - 1] + (uint64_t)b[j] * (uint64_t)a[size - j + i];
			C = (sum >> 32);
			t[size - 1] = (uint32_t)sum;
			sum = (uint64_t)t[size] + (uint64_t)C;
			C = (sum >> 32);
			t[size] = (uint32_t)sum;
			t[size + 1] = t[size + 1] + C;
		}

	}

	sub_cond(t, n, size);
	for (uint32_t k = 0; k <= size; k++) {
		res[k] = t[k];
	}

	free(t);
}


// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// Optimised ASM version
void montMulOpt(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{
	uint32_t t[size + 2];
	uint32_t nprime_0 = n_prime[0];
	uint32_t C;
	uint64_t sum;
	uint8_t i;
	uint8_t j;

	for (i = 0; i < size + 2; i++) {
		t[i] = 0;
	}

	for (i = 0; i < size; i++) {
		C = mul_add_row(&t[i], a, b[i], size - i);

		sum = (uint64_t)t[size] + (uint64_t)C;
		C = (sum >> 32);
		t[size] = (uint32_t)sum;
		t[size + 1] = t[size + 1] + C;
	}

	for (i = 0; i < size; i++) {

		uint32_t m = t[0] * nprime_0; // onderste 32 bit selecteren adhv 32 bit type
		sum = (uint64_t)t[0] + (uint64_t)m*(uint64_t)n[0];
		C = (sum >> 32);

		for (j = 1; j < size; j++) {
			sum = (uint64_t)t[j] + (uint64_t)m * (uint64_t)n[j] + (uint64_t)C;
			C = (sum >> 32);
			t[j - 1] = (uint32_t)sum;
		}

		sum = (uint64_t)t[size] + (uint64_t)C;
		C = (sum >> 32);
		t[size - 1] = (uint32_t)sum;
		t[size] = t[size + 1] + C;
		t[size + 1] = 0;

		for (j = i+1; j < size; j++) {
			sum = (uint64_t)t[size - 1] + (uint64_t)b[j] * (uint64_t)a[size - j + i];
			C = (sum >> 32);
			t[size - 1] = (uint32_t)sum;
			sum = (uint64_t)t[size] + (uint64_t)C;
			C = (sum >> 32);
			t[size] = (uint32_t)sum;
			t[size + 1] = t[size + 1] + C;
		}

	}

	sub_cond(t, n, size);
	for (uint32_t k = 0; k <= size; k++) {
		res[k] = t[k];
	}
}

/*
 * mp_arith.c
 *
 */

#include <stdint.h>


// returns 1 if a >= b, 0 otherwise (both have size words)
int mp_geq(uint32_t *a, uint32_t *b, uint32_t size)
{
    for (int i = (int)size - 1; i >= 0; i--) {     // start at the most significant word
        if (a[i] > b[i])
            return 1;
        if (a[i] < b[i])
            return 0;
    }
    return 1;                                       // all words equal
}


// Calculates res = a + b.
// a and b represent large integers stored in uint32_t arrays
// a and b are arrays of size elements, res has size+1 elements
void mp_add(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
    uint32_t c = 0;                              // carry

    for (uint32_t i = 0; i < size; i++) {
        uint64_t sum = (uint64_t)a[i] + b[i] + c;
        res[i] = (uint32_t)sum;                  // sum mod 2^32
        c = (uint32_t)(sum >> 32);               // 0 or 1
    }

    res[size] = c;                               // final carry
}
// Calculates res = a - b.
// a and b represent large integers stored in uint32_t arrays
// a, b and res are arrays of size elements
void mp_sub(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
    int64_t c = 0;                                   // carry (borrow): 0 or -1

    for (uint32_t i = 0; i < size; i++) {
        int64_t diff = (int64_t)a[i] -  (int64_t)b[i] + c;     // can be negative
        res[i] = (uint32_t)diff;                     // diff mod 2^32

        if (diff >= 0)
            c = 0;
        else
            c = -1;
    }

}

// Calculates res = (a + b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_add(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{
	  uint32_t c = 0;
	    for (uint32_t i = 0; i < size; i++) {
	        uint64_t sum = (uint64_t)a[i] + b[i] + c;
	        res[i] = (uint32_t)sum;
	        c = (uint32_t)(sum >> 32);
	    }

	    // step (4): if t >= n, subtract n
	    if (c == 1 || mp_geq(res, N, size))
	        mp_sub(res, N, res, size);

}

// Calculates res = (a - b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_sub(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{
		if (mp_geq(a,b, size)) {
			mp_sub(a,b, res, size);
		} else {
			mp_sub(b, a, res, size);
			mp_sub(N, res, res, size);

		}
}


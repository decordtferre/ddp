#ifndef _EC_H_
#define _EC_H_

#include <stdint.h>
#include "hw_accel.h"

// Point on the twisted Edwards curve in extended coordinates (X, Y, Z, T),
// with x = X/Z, y = Y/Z and T = X*Y/Z.
typedef struct {
  uint32_t x[OPERAND_WORDS];
  uint32_t y[OPERAND_WORDS];
  uint32_t z[OPERAND_WORDS];
  uint32_t t[OPERAND_WORDS];
} ec_point;

// Has to be called once before ec_add.
//   q    : modulus
//   r2_q : R^2 mod q, with R = 2^377
// Loads q into the FPGA and precomputes k*R mod q.
void ec_init(const uint32_t* q, const uint32_t* r2_q);

// res = p1 + p2. res may be the same point as p1 or p2.
// Same computation as EC_addition in testvectors/HW.py.
void ec_add(const ec_point* p1, const ec_point* p2, ec_point* res);

// res = (a + b) mod q and res = (a - b) mod q, for a and b smaller than q.
// res may be the same array as a or b.
void mod_add(const uint32_t* a, const uint32_t* b, uint32_t* res);
void mod_sub(const uint32_t* a, const uint32_t* b, uint32_t* res);

#endif

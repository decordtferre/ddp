#include <string.h>

#include "ec.h"

// Curve constant k (curves.py), used in C = k * T1 * T2
static const uint32_t curve_k[OPERAND_WORDS] = {
  0x84d6e016, 0xe02c1256, 0x70e3d3e4, 0x735d9478, 0xe0b32139, 0x7f165b2f,
  0xc1a32d21, 0x37786998, 0xae65fc74, 0xca0b7670, 0x3169a4f2, 0x0196bab0 };

static uint32_t mod_q[OPERAND_WORDS];   // modulus
static uint32_t k_r  [OPERAND_WORDS];   // k * R mod q

void ec_init(const uint32_t* q, const uint32_t* r2_q) {
  memcpy(mod_q, q, sizeof(mod_q));
  hw_load_modulus(q);
  // MontMul(k, R^2) = k * R^2 * R^-1 = k * R
  hw_montmul(curve_k, r2_q, k_r);
}

// res = a + b, returns the carry out
static uint32_t mp_add(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  uint64_t carry = 0;
  for (int i = 0; i < OPERAND_WORDS; i++) {
    uint64_t sum = (uint64_t)a[i] + b[i] + carry;
    res[i] = (uint32_t)sum;
    carry  = sum >> 32;
  }
  return (uint32_t)carry;
}

// res = a - b, returns 1 if a < b (borrow out)
static uint32_t mp_sub(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  uint64_t borrow = 0;
  for (int i = 0; i < OPERAND_WORDS; i++) {
    uint64_t diff = (uint64_t)a[i] - b[i] - borrow;
    res[i] = (uint32_t)diff;
    borrow = (diff >> 32) & 1;
  }
  return (uint32_t)borrow;
}

void mod_add(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  uint32_t sum[OPERAND_WORDS], reduced[OPERAND_WORDS];
  // a + b < 2q < 2^378 fits in 12 words, so there is no carry out
  mp_add(a, b, sum);
  // keep sum - q, unless that is negative
  if (mp_sub(sum, mod_q, reduced)) memcpy(res, sum,     sizeof(sum));
  else                             memcpy(res, reduced, sizeof(reduced));
}

void mod_sub(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  uint32_t diff[OPERAND_WORDS];
  // if a - b is negative, add q
  if (mp_sub(a, b, diff)) mp_add(diff, mod_q, res);
  else                    memcpy(res, diff, sizeof(diff));
}

void ec_add(const ec_point* p1, const ec_point* p2, ec_point* res) {
  uint32_t a[OPERAND_WORDS], b[OPERAND_WORDS], c[OPERAND_WORDS], d[OPERAND_WORDS];
  uint32_t e[OPERAND_WORDS], f[OPERAND_WORDS], g[OPERAND_WORDS], h[OPERAND_WORDS];
  uint32_t t1[OPERAND_WORDS], t2[OPERAND_WORDS];

  // A = (Y1 - X1) * (Y2 - X2)
  mod_sub(p1->y, p1->x, t1);
  mod_sub(p2->y, p2->x, t2);
  hw_montmul(t1, t2, a);

  // B = (Y1 + X1) * (Y2 + X2)
  mod_add(p1->y, p1->x, t1);
  mod_add(p2->y, p2->x, t2);
  hw_montmul(t1, t2, b);

  // C = k * T1 * T2
  hw_montmul(p1->t, p2->t, c);
  hw_montmul(c, k_r, c);

  // D = 2 * Z1 * Z2, the doubling is an addition instead of a multiplication
  hw_montmul(p1->z, p2->z, d);
  mod_add(d, d, d);

  mod_sub(b, a, e);   // E = B - A
  mod_sub(d, c, f);   // F = D - C
  mod_add(d, c, g);   // G = D + C
  mod_add(b, a, h);   // H = B + A

  // All inputs are used by now, so res may overlap with p1 or p2
  hw_montmul(e, f, res->x);   // X3 = E * F
  hw_montmul(g, h, res->y);   // Y3 = G * H
  hw_montmul(f, g, res->z);   // Z3 = F * G
  hw_montmul(e, h, res->t);   // T3 = E * H
}

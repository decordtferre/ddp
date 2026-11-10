#ifndef _HW_ACCEL_H_
#define _HW_ACCEL_H_

#include <stdint.h>

// A 377-bit number takes 12 words, least significant word first.
#define OPERAND_WORDS 12

// Load the modulus into the FPGA. It stays there until the next call.
void hw_load_modulus(const uint32_t* m);

// res = a * b * R^-1 mod m, with R = 2^377 and m the loaded modulus.
// res may be the same array as a or b.
void hw_montmul(const uint32_t* a, const uint32_t* b, uint32_t* res);

// Status register of the FPGA, see the register map at the top of ecdsa.v
uint32_t hw_status(void);

// Number of FPGA clock cycles the last multiplication took
uint32_t hw_mul_cycles(void);

#define STATUS_DONE  (1 << 0)
#define STATUS_IDLE  (1 << 1)
#define STATUS_ERROR (1 << 2)

#endif

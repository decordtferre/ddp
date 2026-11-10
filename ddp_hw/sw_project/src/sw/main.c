#include "common.h"
#include <string.h>

#include "hw_accel.h"
#include "ec.h"

// These variables are defined in the testvector.c
// that is created by the testvector generator python script
extern uint32_t modulus[32],
                Public_X[32], Public_Y[32], Public_Z[32], Public_T[32],
                G_X[32],      G_Y[32],      G_Z[32],      G_T[32],
                R2_N[32];

// Expected results for the testvector with seed = 2026, calculated with
// EC_addition from testvectors/HW.py. Regenerate them when testvector.c
// is regenerated with another seed, because the public key changes.
static const ec_point expected_G_plus_P = {
  .x = { 0x6540d446, 0x3a90abb6, 0xc531a32d, 0x3f187f0d, 0x22ace6d1, 0x94cb3aa6,
         0x2801d948, 0x8edf2bef, 0xfd3b4ce3, 0xf7e1d151, 0x684c51d4, 0x0072d37d },
  .y = { 0x3129ae7c, 0x2df8b840, 0x5365f4f6, 0xa7eef99b, 0xcdce5e8c, 0x2360b5fd,
         0x1b2a36f1, 0x04f16d30, 0x491f03da, 0xd1a328cf, 0x7b84e758, 0x017592e1 },
  .z = { 0xab8912e5, 0x2d6d451b, 0xd470e2e3, 0x24127e6b, 0xe42782d4, 0x3445312a,
         0x4e4c959e, 0xb2b9d34a, 0x9767ba48, 0xaf086907, 0xbde4964f, 0x01a95d2a },
  .t = { 0xe9538041, 0x009c8433, 0x4c85a76c, 0x36613479, 0x3e155e79, 0x8ed73bbd,
         0xbf3d8888, 0x27af7202, 0xdf7d7964, 0xf32b68c4, 0x02a50ac4, 0x00327353 },
};

static const ec_point expected_G_plus_G = {
  .x = { 0xb6de8390, 0x95bc1183, 0x18a4a297, 0x9356e66f, 0x45f22d77, 0x37076e62,
         0x28276595, 0x8de5bac7, 0xde07cc63, 0xff60ae67, 0xc84936c1, 0x017b7761 },
  .y = { 0xca8d626a, 0x2d467d85, 0x72e9de5d, 0x0107491d, 0xb7d58a41, 0x62941925,
         0x718adff3, 0xdec31cca, 0x5747a213, 0x78e8e273, 0x17df2bfa, 0x00376622 },
  .z = { 0x9f2793f6, 0xf9bfd9a3, 0x0a09c049, 0x491b0033, 0xf3e3f19d, 0xffc36d6a,
         0x1ed8ee47, 0xc56d6b65, 0xe12c59c7, 0x44b9143d, 0xccc2b1aa, 0x01262ed8 },
  .t = { 0x25b2319a, 0xd482fe43, 0xaf7c34e9, 0x6f3494a4, 0x152578d0, 0x57352cba,
         0x05dc1ff7, 0xdcd51975, 0xce928564, 0xcaaa8cd8, 0x24dbc400, 0x00e37d05 },
};

static void load_point(ec_point* p, const uint32_t* x, const uint32_t* y,
                       const uint32_t* z, const uint32_t* t) {
  memcpy(p->x, x, sizeof(p->x));
  memcpy(p->y, y, sizeof(p->y));
  memcpy(p->z, z, sizeof(p->z));
  memcpy(p->t, t, sizeof(p->t));
}

static void print_operand(const char* name, const uint32_t* src) {
  xil_printf("%s = 0x", name);
  for (int i = OPERAND_WORDS - 1; i >= 0; i--)
    xil_printf("%08x", src[i]);
  xil_printf("\n\r");
}

static void check_point(const char* name, const ec_point* result, const ec_point* expected) {
  if (memcmp(result, expected, sizeof(ec_point)) == 0) {
    xil_printf("%s: PASS\n\r", name);
  } else {
    xil_printf("%s: FAIL\n\r", name);
    print_operand("  X result  ", result->x);
    print_operand("  X expected", expected->x);
    print_operand("  Y result  ", result->y);
    print_operand("  Y expected", expected->y);
    print_operand("  Z result  ", result->z);
    print_operand("  Z expected", expected->z);
    print_operand("  T result  ", result->t);
    print_operand("  T expected", expected->t);
  }
}

int main() {

  init_platform();
  init_performance_counters(0);

  xil_printf("Begin\n\r");

  ec_point G, P, result;
  load_point(&G, G_X, G_Y, G_Z, G_T);
  load_point(&P, Public_X, Public_Y, Public_Z, Public_T);

  ec_init(modulus, R2_N);

  // Addition of two different points
START_TIMING
  ec_add(&G, &P, &result);
STOP_TIMING
  check_point("G + P", &result, &expected_G_plus_P);

  // Doubling, with the result written over one of the inputs
  memcpy(&result, &G, sizeof(ec_point));
  ec_add(&result, &G, &result);
  check_point("G + G", &result, &expected_G_plus_G);

  uint32_t status = hw_status();
  xil_printf("STATUS %08x | Done %d | Idle %d | Error %d\n\r", (unsigned int)status,
    (status & STATUS_DONE) != 0, (status & STATUS_IDLE) != 0, (status & STATUS_ERROR) != 0);
  xil_printf("Multiplier took %u FPGA clock cycles\n\r", (unsigned int)hw_mul_cycles());

  cleanup_platform();

  return 0;
}

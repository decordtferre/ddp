#include "common.h"
#include <stdalign.h>
#include <string.h>

// Register file shared with FPGA
static volatile uint32_t* const HWreg = (volatile uint32_t*)0x40400000;

// Input registers (SW to HW)
#define COMMAND 0
#define RXADDR  1
#define TXADDR  2

// Output registers (HW to SW)
#define STATUS     0
#define MUL_CYCLES 3

// Commands, see the register map at the top of ecdsa.v
#define CMD_IDLE    0
#define CMD_LOAD_M  1
#define CMD_MONTMUL 2

// Status bits
#define STATUS_DONE  (1 << 0)
#define STATUS_IDLE  (1 << 1)
#define STATUS_ERROR (1 << 2)

// A 377-bit operand takes 12 words. Every DMA transfer is 32 words (1024 bit).
#define OPERAND_WORDS 12
#define DMA_WORDS     32

// Buffers shared with the FPGA. They have to be 128-byte aligned.
static alignas(128) uint32_t dma_in [DMA_WORDS];
static alignas(128) uint32_t dma_out[DMA_WORDS];

// Same testvector as tb_montgomery.v and tb_ecdsa_wrapper.v
static const uint32_t tv_a[OPERAND_WORDS] = {
  0x85e8916a, 0x0a056006, 0x2d6c3abb, 0x20060be1, 0xde94d88c, 0x12c00772,
  0xa8b4f1e2, 0xd96fe122, 0x63d7e16c, 0x9a380d96, 0xb0f9f0ec, 0x001b8a55 };
static const uint32_t tv_b[OPERAND_WORDS] = {
  0x9bbd7275, 0x99f8364b, 0x8837de3d, 0x8142eb8c, 0x5f5fb704, 0x6a6ab12f,
  0x702915d6, 0x72c5f3f5, 0x8bfb7aa1, 0xe00b13b9, 0xc5b8695e, 0x00d07020 };
static const uint32_t tv_m[OPERAND_WORDS] = {
  0x7a6e75f5, 0x7a65f040, 0x0b537e7c, 0xae2ab026, 0x1df61006, 0x6eec116e,
  0xdb4ffcbb, 0x61606436, 0x4aed030c, 0xe66c6e84, 0x01b93e63, 0x0108fdf5 };
static const uint32_t tv_expected[OPERAND_WORDS] = {
  0x20168b8a, 0x6ee79cf7, 0x72b0e9c6, 0xf04b770b, 0x2c101d25, 0xfb625deb,
  0x3d3ec09c, 0xf68c9e43, 0x686f246e, 0x267903ab, 0x7d8d92ab, 0x00575225 };

// Write a command, wait until the FPGA is done, and release the command
static void hw_run(uint32_t command) {
  HWreg[COMMAND] = command;
  while ((HWreg[STATUS] & STATUS_DONE) == 0);
  HWreg[COMMAND] = CMD_IDLE;
}

// Load the modulus into the FPGA. It stays there until the next call.
void hw_load_modulus(const uint32_t* m) {
  memset(dma_in, 0, sizeof(dma_in));
  memcpy(dma_in, m, OPERAND_WORDS * sizeof(uint32_t));
  HWreg[RXADDR] = (uint32_t)dma_in;
  hw_run(CMD_LOAD_M);
}

// res = a * b * R^-1 mod m, with R = 2^377 and m the loaded modulus
void hw_montmul(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  memset(dma_in, 0, sizeof(dma_in));
  memcpy(dma_in,      a, OPERAND_WORDS * sizeof(uint32_t));  // bits [376:0]
  memcpy(dma_in + 16, b, OPERAND_WORDS * sizeof(uint32_t));  // bits [888:512]
  HWreg[RXADDR] = (uint32_t)dma_in;
  HWreg[TXADDR] = (uint32_t)dma_out;
  hw_run(CMD_MONTMUL);
  memcpy(res, dma_out, OPERAND_WORDS * sizeof(uint32_t));
}

static void print_operand(const char* name, const uint32_t* src) {
  xil_printf("%s = 0x", name);
  for (int i = OPERAND_WORDS - 1; i >= 0; i--)
    xil_printf("%08x", src[i]);
  xil_printf("\n\r");
}

int main() {

  init_platform();
  init_performance_counters(0);

  xil_printf("Begin\n\r");

  uint32_t result[OPERAND_WORDS];

  hw_load_modulus(tv_m);

START_TIMING
  hw_montmul(tv_a, tv_b, result);
STOP_TIMING

  uint32_t status = HWreg[STATUS];
  xil_printf("STATUS %08x | Done %d | Idle %d | Error %d\n\r", (unsigned int)status,
    (status & STATUS_DONE) != 0, (status & STATUS_IDLE) != 0, (status & STATUS_ERROR) != 0);
  xil_printf("Multiplier took %u FPGA clock cycles\n\r", (unsigned int)HWreg[MUL_CYCLES]);

  print_operand("result  ", result);
  print_operand("expected", tv_expected);

  if (memcmp(result, tv_expected, sizeof(result)) == 0)
    xil_printf("PASS\n\r");
  else
    xil_printf("FAIL\n\r");

  cleanup_platform();

  return 0;
}

#include <stdalign.h>
#include <string.h>

#include "hw_accel.h"

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

// Every DMA transfer is 32 words (1024 bit)
#define DMA_WORDS 32

// Buffers shared with the FPGA. They have to be 128-byte aligned.
static alignas(128) uint32_t dma_in [DMA_WORDS];
static alignas(128) uint32_t dma_out[DMA_WORDS];

// Write a command, wait until the FPGA is done, and release the command
static void hw_run(uint32_t command) {
  HWreg[COMMAND] = command;
  while ((HWreg[STATUS] & STATUS_DONE) == 0);
  HWreg[COMMAND] = CMD_IDLE;
}

void hw_load_modulus(const uint32_t* m) {
  memset(dma_in, 0, sizeof(dma_in));
  memcpy(dma_in, m, OPERAND_WORDS * sizeof(uint32_t));
  HWreg[RXADDR] = (uint32_t)dma_in;   // where FPGA reads the data
  hw_run(CMD_LOAD_M);
}

void hw_montmul(const uint32_t* a, const uint32_t* b, uint32_t* res) {
  memset(dma_in, 0, sizeof(dma_in));
  memcpy(dma_in,      a, OPERAND_WORDS * sizeof(uint32_t));  // bits [376:0]
  memcpy(dma_in + 16, b, OPERAND_WORDS * sizeof(uint32_t));  // bits [888:512]
  HWreg[RXADDR] = (uint32_t)dma_in;   // where FPGA reads the data
  HWreg[TXADDR] = (uint32_t)dma_out;  // where FPGA writes the data
  hw_run(CMD_MONTMUL);
  memcpy(res, dma_out, OPERAND_WORDS * sizeof(uint32_t));
}

uint32_t hw_status(void) {
  return HWreg[STATUS];
}

uint32_t hw_mul_cycles(void) {
  return HWreg[MUL_CYCLES];
}

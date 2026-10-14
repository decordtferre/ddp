#ifndef _COMMON_H_
#define _COMMON_H_

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

#ifdef HOST
// PC build (make host): no board, no Xilinx BSP.
// Timing uses the x86 timestamp counter: only useful to compare versions
// against each other on the PC, NOT comparable to the board's cycle counts.
#include <x86intrin.h>
#define xil_printf printf
#define init_platform()
#define cleanup_platform()
#define init_performance_counters(x)
static uint64_t time_start;
#define START_TIMING time_start = __rdtsc();
#define STOP_TIMING  xil_printf(">>> TIMING: %llu PC ticks \n\r", (unsigned long long)(__rdtsc() - time_start));
#else

#include "platform/platform.h"

#include "platform/performance.h"

#include "xil_printf.h"
#include "xil_cache.h"

#endif

#endif

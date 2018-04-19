#ifndef __PERIPH_H__
#define __PERIPH_H__

#define PERF_EXIT (*((uint32_t)*0xa0000000) = 0)
#define PERF_PUTCHAR(c) (*((uint32_t *)0xa0000001) = (c))

#endif
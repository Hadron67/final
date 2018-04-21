#ifndef __IO_H__
#define __IO_H__

#include <stdarg.h>
typedef struct __IO_FILE FILE;
struct __IO_FILE_vt {
    char (*fputc)(FILE *f, char c);
};
struct __IO_FILE {
    const struct __IO_FILE_vt *_vt;
};
int vafprintf(FILE *f, const char *fmt, va_list args);
int fprintf(FILE *f, const char *fmt, ...);

FILE *fcmdopen(unsigned int addr);
#endif
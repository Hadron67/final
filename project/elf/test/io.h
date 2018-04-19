#ifndef __IO_H__
#define __IO_H__
#include <stdarg.h>
typedef struct __IO_FILE FILE;

struct _IO_FILE_VT {
    int (*fputc)(FILE *f, char c);
};
struct __IO_FILE {
    const struct _IO_FILE_VT *vt;
};

int vafprintf(FILE *f, const char *fmt, va_list arg);
int fprintf(FILE *f, const char *fmt, ...);

#endif
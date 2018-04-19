#include "io.h"

static int printString(FILE *f, const char *s){
    while(*s){
        f->vt->fputc(f, *s++);
    }
}


int vafprintf(FILE *f, const char *fmt, va_list arg){
    while(*fmt){
        if(*fmt == '%'){
            fmt++;
            if(*fmt == '%'){
                fmt++;
                f->vt->fputc(f, '%');
            }
            else if(*fmt == 'c'){
                fmt++;
                f->vt->fputc(f, va_arg(arg, int));
            }
            else if(*fmt == 's'){
                fmt++;
                printString(f, va_arg(arg, const char *));
            }
            else {
                f->vt->fputc(f, '%');
                f->vt->fputc(f, *fmt++);
            }
        }
        else {
            f->vt->fputc(f, *fmt++);
        }
    }
}

int fprintf(FILE *f, const char *fmt, ...){
    int ret;
    va_list arg_ptr;
    va_start(arg_ptr, fmt);
    ret = vafprintf(f, fmt, arg_ptr);
    va_end(arg_ptr);
    return ret;
}
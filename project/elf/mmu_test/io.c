#include "io.h"
static int printString(FILE *f, const char *s){
    while(*s){
        f->_vt->fputc(f, *s++);
    }
}

int vafprintf(FILE *f, const char *fmt, va_list args){
    while(*fmt){
        if(*fmt == '%'){
            fmt++;
            if(*fmt == '%'){
                fmt++;
                f->_vt->fputc(f, '%');
            }
            else if(*fmt == 'c'){
                fmt++;
                f->_vt->fputc(f, va_arg(args, int));
            }
            else if(*fmt == 's'){
                fmt++;
                printString(f, va_arg(args, const char *));
            }
            else {
                f->_vt->fputc(f, '%');
                f->_vt->fputc(f, *fmt++);
            }
        }
        else {
            f->_vt->fputc(f, *fmt++);
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

struct cmdfile_t {
    struct __IO_FILE file;
    unsigned int addr;
};
static char fcmdputc(FILE *f, char c){

}
static struct __IO_FILE_vt cmdfile_vt = {
    fcmdputc
};
static struct __IO_FILE cmdfile = {
    &cmdfile_vt
};
FILE *fcmdopen(unsigned int addr){

}
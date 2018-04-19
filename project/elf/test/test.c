#include <inttypes.h>
#include "periph.h"
#include "io.h"

static int _fputc(FILE *f, char c){
    PERF_PUTCHAR(c);
}
static const struct _IO_FILE_VT _vt = {
    _fputc
};
static FILE __f = {&_vt};
FILE *stdout = &__f;

int main(){
    int a1 = 0, a2 = 0;
    int i;
    for(i = 0; i < 10; i++){
        fprintf(stdout, "hkm: <%s>\n", "soor");
    }
    return 0;
}
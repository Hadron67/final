#include <inttypes.h>

int exit(){
    // write any content to address 0xbfffffff to stop simulation.
    *((uint32_t *)0xbfffffff) = 0;
}

int test(){
    
}
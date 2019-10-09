#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t level;
    int message[1024];
}
#ifndef _MSC_VER
__attribute__((packed))
#endif
localmessage_t;

#ifdef __cplusplus
}
#endif

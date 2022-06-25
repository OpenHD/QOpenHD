#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t level;
    int data[1024];
}
#ifndef _MSC_VER
__attribute__((packed))
#endif
logger_t;

#ifdef __cplusplus
}
#endif

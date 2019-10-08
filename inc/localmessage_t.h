#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    uint8_t level;
    int message[1024];
} __attribute__((packed)) localmessage_t;

#ifdef __cplusplus
}
#endif

#include "wifibroadcast.h"

#include <unistd.h>
#include <sys/mman.h>
#include <sys/stat.h>        /* For mode constants */
#include <fcntl.h>           /* For O_* constants */
#include <stdio.h>
#include <stdlib.h>

#if defined(__rasp_pi__)
/*
 * These are copied verbatim from Open.HD/telemetry.c to ensure the shared memory stuff works
 * exactly the same as the original OSD code
 *
 */
wifibroadcast_rx_status_t *telemetry_wbc_status_memory_open(void) {
    int fd = 0;
    int sharedmem = 0;
    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_0", O_RDONLY, S_IRUSR | S_IWUSR);
        if(fd < 0) {
            fprintf(stderr, "QOpenHD: Could not open /wifibroadcast_rx_status_0 - will try again ...\n");
        } else {
            sharedmem = 1;
        }
        usleep(100000);
    }
    void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t), PROT_READ, MAP_SHARED, fd, 0);
    if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
    return (wifibroadcast_rx_status_t*)retval;
}


wifibroadcast_rx_status_t_osd *telemetry_wbc_status_memory_open_osd(void) {
    int fd = 0;
    int sharedmem = 0;
    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_1", O_RDONLY, S_IRUSR | S_IWUSR);
        if(fd < 0) {
            fprintf(stderr, "QOpenHD: Could not open /wifibroadcast_rx_status_1 - will try again ...\n");
        } else {
            sharedmem = 1;
        }
        usleep(100000);
    }
    void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_osd), PROT_READ, MAP_SHARED, fd, 0);
    if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
    return (wifibroadcast_rx_status_t_osd*)retval;
}


wifibroadcast_rx_status_t_rc *telemetry_wbc_status_memory_open_rc(void) {
    int fd = 0;
    int sharedmem = 0;
    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_rc", O_RDONLY, S_IRUSR | S_IWUSR);
        if(fd < 0) {
            fprintf(stderr, "QOpenHD: Could not open wifibroadcast_rx_status_rc - will try again ...\n");
        } else {
            sharedmem = 1;
        }
        usleep(100000);
    }
    void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_rc), PROT_READ, MAP_SHARED, fd, 0);
    if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
    return (wifibroadcast_rx_status_t_rc*)retval;
}

wifibroadcast_rx_status_t_uplink *telemetry_wbc_status_memory_open_uplink(void) {
    int fd = 0;
    int sharedmem = 0;
    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_uplink", O_RDONLY, S_IRUSR | S_IWUSR);
        if(fd < 0) {
            fprintf(stderr, "QOpenHD: Could not open wifibroadcast_rx_status_uplink - will try again ...\n");
        } else {
            sharedmem = 1;
        }
        usleep(100000);
    }
    void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_uplink), PROT_READ, MAP_SHARED, fd, 0);
    if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
    return (wifibroadcast_rx_status_t_uplink*)retval;
}


wifibroadcast_rx_status_t_sysair *telemetry_wbc_status_memory_open_sysair(void) {
    int fd = 0;
    int sharedmem = 0;
    while(sharedmem == 0) {
        fd = shm_open("/wifibroadcast_rx_status_sysair", O_RDONLY, S_IRUSR | S_IWUSR);
        if(fd < 0) {
            fprintf(stderr, "QOpenHD: Could not open wifibroadcast_rx_status_sysair - will try again ...\n");
        } else {
            sharedmem = 1;
        }
        usleep(100000);
    }
    void *retval = mmap(NULL, sizeof(wifibroadcast_rx_status_t_sysair), PROT_READ, MAP_SHARED, fd, 0);
    if (retval == MAP_FAILED) { perror("mmap"); exit(1); }
    return (wifibroadcast_rx_status_t_sysair*)retval;
}
#endif //__rasp_pi__

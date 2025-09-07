//
// Created by consti10 on 31.03.24.
//

#ifndef FPVUE_TIME_UTIL_H
#define FPVUE_TIME_UTIL_H

#include <time.h>
#include <stdlib.h>
#include <stdint.h>

/**
 * @return milliseconds
 */
uint64_t get_time_ms() {
    struct timespec spec;
    if (clock_gettime(1, &spec) == -1) { /* 1 is CLOCK_MONOTONIC */
        abort();
    }
    return spec.tv_sec * 1000 + spec.tv_nsec / 1e6;
}

void print_time_ms(const char* tag,uint64_t ms){
    printf("%s %dms\n",tag,(int)ms);
}


struct TSAccumulator{
    // In milliseconds
    uint64_t min_ms;
    uint64_t max_ms;
    uint64_t accumulated_ms;
    int count;
    uint64_t last_print_ms;
};


void accumulate_and_print(const char *tag,uint64_t ms,struct TSAccumulator* tsAccumulator){
    if(ms>tsAccumulator->max_ms){
        tsAccumulator->max_ms=ms;
    }
    if(ms<tsAccumulator->min_ms){
        tsAccumulator->min_ms=ms;
    }
    tsAccumulator->accumulated_ms+=ms;
    tsAccumulator->count++;
    uint64_t elapsed_since_last_print_ms=get_time_ms()- tsAccumulator->last_print_ms;
    if(elapsed_since_last_print_ms>1000){
        uint64_t average=tsAccumulator->accumulated_ms/tsAccumulator->count;
        printf("%s min:%ld max:%ld avg:%ld (ms)\n",tag,tsAccumulator->min_ms,tsAccumulator->max_ms,average);
        tsAccumulator->min_ms=UINT64_MAX;
        tsAccumulator->max_ms=0;
        tsAccumulator->count=0;
        tsAccumulator->accumulated_ms=0;
        tsAccumulator->last_print_ms=get_time_ms();
    }
}


#endif //FPVUE_TIME_UTIL_H

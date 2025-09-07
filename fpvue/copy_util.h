//
// Created by consti10 on 02.04.24.
//

#ifndef FPVUE_COPY_UTIL_H
#define FPVUE_COPY_UTIL_H


#include <pthread.h>
#include <assert.h>
#include <string.h>

//#define __ARM__
/*#include <arm_neon.h>

void memcpy_neon_8bytes(uint8_t* region2, const uint8_t* region1, size_t length){
    assert(length % 8 == 0);
    uint8x8_t in;
    for (const uint8_t *end = region1 + length; region1 < end; region1 += 8, region2 += 8) {
        in = vld1_u8(region1);
        vst1_u8(region2, in);
    }
}
void memcpy_neon_16bytes(uint8_t* region2, const uint8_t* region1, size_t length){
    assert(length % 16 == 0);
    uint8x8x2_t in;
    for (const uint8_t *end = region1 + length; region1 < end; region1 += 16, region2 += 16) {
        in = vld2_u8(region1);
        vst2_u8(region2, in);
    }
}
void memcpy_neon_32bytes(uint8_t* region2, const uint8_t* region1, size_t length){
    assert(length % 32 == 0);
    uint8x8x4_t in;
    for (const uint8_t *end = region1 + length; region1 < end; region1 += 32, region2 += 32) {
        in = vld4_u8(region1);
        vst4_u8(region2, in);
    }
}

void memcpy_neon_aligned(void* dst, const void * src, size_t length){
    int len_fast=length-(length % 16);
    memcpy_neon_16bytes((uint8_t*)dst,(const uint8_t*)src,len_fast);
    int len_slow=length-len_fast;
    if(len_slow>0){
        memcpy(dst+len_fast,src+len_fast,len_slow);
    }
}*/

// From https://stackoverflow.com/questions/34888683/arm-neon-memcpy-optimized-for-uncached-memory
// and https://stackoverflow.com/questions/61210517/memcpy-for-arm-uncached-memory-for-arm64
#ifdef __ARM__
void my_copy(volatile void *dst, volatile const void *src, int sz){
    if (sz & 63) {
        sz = (sz & -64) + 64;
    }
    asm volatile ("NEONCopyPLD: \n"
                  "sub %[dst], %[dst], #64 \n"
                  "1: \n"
                  "ldnp q0, q1, [%[src]] \n"
                  "ldnp q2, q3, [%[src], #32] \n"
                  "add %[dst], %[dst], #64 \n"
                  "subs %[sz], %[sz], #64 \n"
                  "add %[src], %[src], #64 \n"
                  "stnp q0, q1, [%[dst]] \n"
                  "stnp q2, q3, [%[dst], #32] \n"
                  "b.gt 1b \n"
            : [dst]"+r"(dst), [src]"+r"(src), [sz]"+r"(sz) : : "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "cc", "memory");
}
// https://wx.comake.online/doc/doc/SigmaStarDocs-SSC9341_Ispahan-ULS00V040-20210913/customer/faq/i6b0/system/i6b0/neon.html
// https://community.nxp.com/t5/i-MX-Processors/iMX6-EIM-transfer-speed-with-using-NEON-vld-vst-instructions/m-p/312256
/*void __attribute__ ((noinline)) memcpy_neon_pld(void *dest, const void *src, size_t n)
{
    asm(
            "NEONCopyPLD:\n"
            "   pld [r1, #0xC0]\n" //预取数据
            "   vldm r1!,{d0-d7}\n" //从参数一r0（src）加载8*8=64个单通道8位数据
            "   vstm r0!,{d0-d7}\n" //存储在目的地址r1（dst）中，同样是64个8位单通道8位数据
            "   subs r2,r2,#0x40\n" //循环跳转参数，每次减64，总共循环次数=row*col*4/64
            "   bgt NEONCopyPLD\n"  //以前这里是bge，有问题。现在改成bgt。
            );
}*/
#endif


#ifdef __ARM__
extern "C"{
// The memcpymove-v7l.S impl
void *mempcpy(void * __restrict s1, const void * __restrict s2, size_t n);
// memcpy from arm repo
//void *__memcpy_aarch64(void * __restrict s1, const void * __restrict s2, size_t n);
//void *__memcpy_aarch64_simd(void * __restrict s1, const void * __restrict s2, size_t n);
//void *__memcpy_aarch64_sve(void * __restrict s1, const void * __restrict s2, size_t n);
//void *__memcpy_aarch64_sve (void *__restrict, const void *__restrict, size_t);
};
#endif

void simple_memcpy (char *dst, const char *src, size_t n)
{
    char *ret = dst;
    while (n--)
        *dst++ = *src++;
}

struct memcpy_args_t {
    void* src;
    void* dst;
    int len;
};
void* memcpy_data_function(void* args_uncast){
    struct memcpy_args_t* args=(struct memcpy_args_t*)args_uncast;
#ifdef __ARM__
    //mempcpy(args->dst,args->src,args->len);
    my_copy(args->dst,args->src,args->len);
    //memcpy_neon_pld(args->dst,args->src,args->len);
#else
    memcpy(args->dst,args->src,args->len);
#endif
    //mempcpy(args->dst,args->src,args->len);
    //__memcpy_aarch64(args->dst,args->src,args->len);
    //__memcpy_aarch64_sve(args->dst,args->src,args->len);
    //mempcpy(args->dst,args->src,args->len);
    //memcpy_neon_aligned(args->dst,args->src,args->len);
    //memmove(args->dst,args->src,args->len);
    //simple_memcpy(args->dst,args->src,args->len);
    return NULL;
}

void memcpy_threaded(void* dest,void* src, int len,int n_threads){
    pthread_t threads[100];
    struct memcpy_args_t memcpyArgs[100];
    int consumed=0;
    int chunck=len/(n_threads);
    for(int i=0;i<n_threads;i++){
        memcpyArgs[i].src=src+consumed;
        memcpyArgs[i].dst=dest+consumed;
        int this_thread_len;
        if(i==n_threads-1){
            // might not be even
            this_thread_len=len-consumed;
        }else{
            this_thread_len=chunck;
        }
        memcpyArgs[i].len=this_thread_len;
        int iret1 = pthread_create( &threads[i], NULL, &memcpy_data_function, (void*) &memcpyArgs[i]);
        assert(iret1==0);
        consumed+=this_thread_len;
    }
    assert(consumed==len);
    for(int i=0;i<n_threads;i++){
        pthread_join(threads[i], NULL);
    }
    /*pthread_t thread1;
    struct memcpy_args_t memcpyArgs;
    int len_first=len / 2;
    int len_second=len-len_first;
    memcpyArgs.src=src;
    memcpyArgs.dst=dest;
    memcpyArgs.len=len_first;
    int iret1 = pthread_create( &thread1, NULL, &memcpy_data_function, (void*) &memcpyArgs);
    assert(iret1==0);
    memcpy(dest+len_first,src+len_first,len_second);
    pthread_join(thread1, NULL);*/
}

#endif //FPVUE_COPY_UTIL_H

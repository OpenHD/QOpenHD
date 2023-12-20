
#ifndef PACKED_STRUCT_COMPILER_H
#define PACKED_STRUCT_COMPILER_H

// Packed for windows and non windows

#ifdef __windows__
#  define PACKED_STRUCT(name) \
__pragma(pack(push, 1)) name __pragma(pack(pop))
#else
#  define PACKED_STRUCT(name)  __attribute__((packed)) name
#endif

#endif // PACKED_STRUCT_COMPILER_H

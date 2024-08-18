
#include "include/runtime.h"
#include <stdbool.h>

// MARK: - Bump Allocator

#define WASM_PAGE 65536

extern unsigned char heap;
void *memory_end = &heap;

//size_t memory_size() {
//    return __builtin_wasm_memory_size(0);
//}
//
//void memory_grow(size_t page_count) {
//    __builtin_wasm_memory_grow(0, page_count);
//}

//extern int impl_posix_memalign(void **memptr, size_t alignment, size_t size);
//int posix_memalign(void **memptr, size_t alignment, size_t size) {
//    return impl_posix_memalign(memptr, alignment, size);
//}
//
//extern void impl_free(void *_Nullable ptr);
//void free(void *_Nullable ptr) { impl_free(ptr); }

extern unsigned int impl_arc4random(void);
unsigned int arc4random() { return impl_arc4random(); }

extern void impl_arc4random_buf(void *buf, size_t count);
void arc4random_buf(void *buf, size_t count) { impl_arc4random_buf(buf, count); }

void *memcpy(void *dst, const void *src, size_t n) {
    const char *p = src;
    char *q = dst;
    
    while (n--) { *q++ = *p++; }
    
    return dst;
}

int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *c1 = s1, *c2 = s2;
    int d = 0;
    
    while (n--) {
        d = (int)*c1++ - (int)*c2++;
        if (d) break;
    }
    
    return d;
}

void *memmove(void *dst, const void *src, size_t n) {
    const char *p = src;
    char *q = dst;
    
    if (q < p) {
        while (n--) {
            *q++ = *p++;
        }
    } else {
        p += n;
        q += n;
        while (n--) {
            *--q = *--p;
        }
    }
    
    return dst;
}

void *memset(void *str, int c, size_t n) {
    for (int i = 0; i < n; i++) *(unsigned char *)(str + i) = (unsigned char) c;
    return str;
}

unsigned long __stack_chk_guard = 0x1;
void __stack_chk_guard_setup(void) {}
void __stack_chk_fail(void) {}

//void initialize() {
//    memory_end += memory_size() * WASM_PAGE;
//}

int posix_memalign(void **memptr, size_t alignment, size_t size) {
    *memptr = malloc(size);
    return 0;
}

//int impl_posix_memalign(void **memptr, size_t alignment, size_t size) {
//    if (first_alloc) {
//        memory_end += memory_size() * WASM_PAGE;
//        first_alloc = false;
//    }
//
//    if ((size_t)memory_end + size > memory_size() * WASM_PAGE) {
//        memory_grow(1 + size / WASM_PAGE);
//    }
//
//    *memptr = memory_end;
//    memory_end += size;
//
//    return 0;
//}

//void free(void *_Nullable ptr) {
//    // :)
//}

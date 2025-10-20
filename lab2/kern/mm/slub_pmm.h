#ifndef __KERN_MM_SLUB_PMM_H__
#define __KERN_MM_SLUB_PMM_H__

#include <pmm.h>
#include <list.h>

#define SLAB_CACHE_NUM 3
#define SLAB_CACHE_SIZES {32, 64, 128}

typedef struct slab {
    list_entry_t list_link;
    void *objects;
    unsigned char *bitmap;
    size_t free_objects;
    size_t total_objects;
    struct cache *cache;
} slab_t;

typedef struct cache {
    list_entry_t slabs_full;
    list_entry_t slabs_partial; 
    list_entry_t slabs_free;
    size_t object_size;
    size_t objects_per_slab;
    const char *name;
} cache_t;

#define le2slab(le, member) to_struct((le), slab_t, member)

// SLUB 分配器接口
void slub_init(void);
void *slub_alloc(size_t size);
void slub_free(void *obj);
void *slub_alloc_pages(size_t n);
void slub_free_pages(void *addr, size_t n);
void slub_check(void);

// 测试函数声明
void slub_basic_test(void);
void slub_stress_test(void);
void slub_corner_case_test(void);
void slub_performance_test(void);
void slub_leak_check(void);

#endif /* !__KERN_MM_SLUB_PMM_H__ */

#include <pmm.h> // 物理内存管理头文件
#include <list.h>
#include <string.h>
#include <stdio.h>
#include <slub_pmm.h> // SLUB 分配器自定义头文件
#include <memlayout.h> // 内存布局定义头文件

// 调试控制 : 设为0减少输出
#define SLUB_DEBUG 0

#if SLUB_DEBUG
#define slub_debug(fmt, ...) cprintf("[SLUB] " fmt, ##__VA_ARGS__)
#else
#define slub_debug(fmt, ...) // 空宏，不产生任何输出
#endif

// SLUB 缓存数组 :存储三种不同大小的缓存
static cache_t slub_caches[SLAB_CACHE_NUM];
static int slub_initialized = 0; // SLUB 初始化标志 - 0表示未初始化，1表示已初始化

// 调试统计 :用于内存泄漏检测
static size_t total_allocated = 0;
static size_t total_freed = 0;

// 计算每个 slab 能容纳的对象数量
static size_t calculate_objects_per_slab(size_t object_size) {
    size_t slab_struct_size = sizeof(slab_t); // slab结构体本身大小
    size_t available_size = PGSIZE - slab_struct_size; // 可用空间 = 页大小 - 结构体大小
    
    // 计算位图大小并调整可用空间
    size_t bitmap_bits = (available_size * 8) / (object_size * 8 + 1);
    size_t bitmap_size = (bitmap_bits + 7) / 8;
    
    available_size -= bitmap_size;
    size_t objects = available_size / object_size; // 计算能容纳的对象数量
    
    // 确保至少有一个对象
    return objects > 0 ? objects : 1;
}

// 初始化单个缓存
static void cache_init(cache_t *cache, size_t object_size, const char *name) {
    cache->object_size = object_size; //设置对象大小
    cache->objects_per_slab = calculate_objects_per_slab(object_size); // 计算每slab对象数
    cache->name = name;
    
    // 初始化三个slab链表
    list_init(&cache->slabs_full); // 全满
    list_init(&cache->slabs_partial); // 部分分配
    list_init(&cache->slabs_free); // 完全空闲
    
    cprintf("SLUB: cache '%s' initialized, object_size=%lu, objects_per_slab=%lu\n",
           name, object_size, cache->objects_per_slab);
}

// 初始化所有 SLUB 缓存,初始化整个SLUB系统
void slub_init(void) {
    if (slub_initialized) return; // 如果已初始化则直接返回
    
    size_t sizes[SLAB_CACHE_NUM] = SLAB_CACHE_SIZES; // 对象大小数组
    const char *names[SLAB_CACHE_NUM] = {"size-32", "size-64", "size-128"};
    
    for (int i = 0; i < SLAB_CACHE_NUM; i++) {
        cache_init(&slub_caches[i], sizes[i], names[i]); // 初始化每个缓存
    }
    
    slub_initialized = 1; // 设置初始化标志
    cprintf("SLUB: all caches initialized\n");
}

// 创建新的 slab
static slab_t *slab_create(cache_t *cache) {
    slub_debug("Creating new slab for cache %s\n", cache->name);
    
    // 分配一页物理内存
    struct Page *page = alloc_page();
    if (page == NULL) {
        cprintf("SLUB: failed to allocate page for slab\n");
        return NULL;
    }
    
    // 将物理页转换为内核虚拟地址
    void *page_va = page2kva(page);
    slab_t *slab = (slab_t *)page_va; // slab结构体位于页的开始位置
    
    // 初始化 slab
    slab->objects = page_va + sizeof(slab_t); // 对象数组紧随slab头之后
    slab->free_objects = cache->objects_per_slab; // 初始空闲对象数
    slab->total_objects = cache->objects_per_slab; // 总对象数
    slab->cache = cache; // 设置所属缓存
    
    // 计算位图位置和大小
    size_t bitmap_size = (cache->objects_per_slab + 7) / 8; // 计算位图所需字节数
    slab->bitmap = (unsigned char *)((char *)slab->objects + cache->objects_per_slab * cache->object_size); // 位图位于对象数组之后
    memset(slab->bitmap, 0, bitmap_size); // 初始化位图（全部置0，表示所有对象都空闲）
    // 将新slab添加到缓存的空闲列表
    list_add(&cache->slabs_free, &(slab->list_link));
    
    slub_debug("New slab created with %lu objects\n", cache->objects_per_slab);
    return slab;
}

// 从缓存中分配对象
void *slub_alloc(size_t size) {
    cprintf("SLUB_alloc: called with size=%lu, slub_initialized=%d\n", size, slub_initialized);
    // 延迟初始化：第一次调用时初始化SLUB系统
    if (!slub_initialized) {
        cprintf("SLUB_alloc: initializing SLUB\n");
        slub_init();
    }
    
    // 处理零大小请求
    if (size == 0) {
        cprintf("SLUB_alloc: zero size request, returning NULL\n");
        return NULL;
    }
    
    // 查找合适的缓存：找到第一个对象大小 >= 请求大小的缓存
    cache_t *target_cache = NULL;
    for (int i = 0; i < SLAB_CACHE_NUM; i++) {
        if (slub_caches[i].object_size >= size) {
            target_cache = &slub_caches[i];
            cprintf("SLUB_alloc: found cache %s for size %lu\n", target_cache->name, size);
            break;
        }
    }
    
    // 如果没有合适的缓存（请求太大），回退到页分配器
    if (target_cache == NULL) {
        // 没有合适的缓存，使用页分配器
        cprintf("SLUB_alloc: no suitable cache, using page allocator\n");
        size_t pages_needed = (size + PGSIZE - 1) / PGSIZE;// 计算所需页数
        struct Page *page = alloc_pages(pages_needed); // 分配物理页
        cprintf("SLUB_alloc: page allocator returned %p\n", page);
        return page ? page2kva(page) : NULL; // 返回虚拟地址
    }
    // 查找可用的slab（按优先级顺序）
    slab_t *slab = NULL;
    list_entry_t *found_le = NULL;
    
    cprintf("SLUB_alloc: checking slabs_partial (empty=%d)\n", list_empty(&target_cache->slabs_partial));
    cprintf("SLUB_alloc: checking slabs_free (empty=%d)\n", list_empty(&target_cache->slabs_free));
    
    // 策略1：首先尝试部分分配的slab（最高效）
    if (!list_empty(&target_cache->slabs_partial)) {
        cprintf("SLUB_alloc: trying partial slab\n");
        found_le = list_next(&target_cache->slabs_partial);
        slab = le2slab(found_le, list_link);
        cprintf("SLUB_alloc: found partial slab with %lu free objects\n", slab->free_objects);
    }
     
    // 策略2：然后尝试完全空闲的slab
    else if (!list_empty(&target_cache->slabs_free)) {
        cprintf("SLUB_alloc: trying free slab\n");
        found_le = list_next(&target_cache->slabs_free);
        slab = le2slab(found_le, list_link);
        cprintf("SLUB_alloc: found free slab with %lu free objects\n", slab->free_objects);
        // 将slab从空闲列表移动到部分分配列表
        list_del(found_le);
        list_add(&target_cache->slabs_partial, found_le);
    }
    // 策略3：最后创建新的slab
    else {
        cprintf("SLUB_alloc: creating new slab\n");
        slab = slab_create(target_cache);
        if (slab) {
            cprintf("SLUB_alloc: new slab created successfully\n");
            // 将新slab从空闲列表移动到部分分配列表
            list_del(&slab->list_link);
            list_add(&target_cache->slabs_partial, &slab->list_link);
        } else {
            cprintf("SLUB_alloc: failed to create new slab\n");
        }
    }
    
    if (slab == NULL) {
        cprintf("SLUB_alloc: no slab available\n");
        return NULL;
    }
    
    // 在找到的slab中查找空闲对象
    cprintf("SLUB_alloc: searching for free object in slab\n");
    // 在 slab 中查找空闲对象
    for (size_t i = 0; i < slab->total_objects; i++) {
        size_t byte_index = i / 8; // 计算位图字节索引
        size_t bit_index = i % 8; // 计算位图位索引
        // 检查该对象是否空闲（位图为0）
        if (!(slab->bitmap[byte_index] & (1 << bit_index))) {
            // 找到空闲对象，进行分配
            cprintf("SLUB_alloc: found free object at index %lu\n", i);
            slab->bitmap[byte_index] |= (1 << bit_index); // 设置位图标记为已分配
            slab->free_objects--; // 减少空闲对象计数
            // 计算对象地址：对象数组起始地址 + 索引 * 对象大小
            void *obj = (char *)slab->objects + i * target_cache->object_size;
            memset(obj, 0, target_cache->object_size); // 清空对象内存
            
            // 如果 slab 已满，移动到满列表
            if (slab->free_objects == 0) {
                cprintf("SLUB_alloc: slab is now full, moving to full list\n");
                list_del(&slab->list_link);
                list_add(&target_cache->slabs_full, &slab->list_link);
            }
            
            total_allocated++; // 更新分配统计
            cprintf("SLUB_alloc: successfully allocated object %p\n", obj);
            return obj;
        }
    }
    
    cprintf("SLUB_alloc: no free objects found in slab\n");
    return NULL;
}

// 释放对象
void slub_free(void *obj) {
    if (obj == NULL) return;
    cprintf("SLUB_free: freeing object %p\n", obj);
    
    // 通过对象地址找到对应的物理页和slab
    struct Page *page = pa2page(PADDR(obj)); // 物理地址→物理页
    slab_t *slab = (slab_t *)page2kva(page); // 物理页→虚拟地址（slab头）
    
    // 检查是否是SLUB分配的对象（通过检查slab->cache）
    if (slab->cache == NULL) {
        // 可能是页分配器分配的内存，使用页释放
        cprintf("SLUB_free: freeing page-allocated memory %p\n", obj);
        slub_free_pages(obj, 1);
        return;
    }
    
    cache_t *cache = slab->cache;
    
    // 计算对象在 slab 中的索引
    uintptr_t obj_addr = (uintptr_t)obj;
    uintptr_t objects_start = (uintptr_t)slab->objects;
    long offset = obj_addr - objects_start; // 计算偏移量
    size_t object_index = offset / cache->object_size; // 计算对象索引
    
    // 索引有效性检查
    if (object_index >= slab->total_objects) {
        panic("slub_free: invalid object pointer %p", obj);
    }
    
    // 更新位图：标记对象为空闲
    size_t byte_index = object_index / 8;
    size_t bit_index = object_index % 8;
    // 双重释放检查
    if (!(slab->bitmap[byte_index] & (1 << bit_index))) {
        panic("slub_free: double free detected for object %p", obj);
    }
    
    slab->bitmap[byte_index] &= ~(1 << bit_index); // 清除位图位
    slab->free_objects++; // 增加空闲对象计数
    
    // 更新slab在链表中的位置
    list_del(&slab->list_link); // 先从当前列表中移除
    
    // 根据空闲对象数量决定移动到哪个列表
    if (slab->free_objects == slab->total_objects) {
        // 完全空闲，移动到空闲列表
        list_add(&cache->slabs_free, &slab->list_link);
        cprintf("SLUB_free: slab moved to free list\n");
    } else if (slab->free_objects == 1) {
        // 从全满变为部分分配
        list_add(&cache->slabs_partial, &slab->list_link);
    } else {
        // 保持在部分分配列表
        list_add(&cache->slabs_partial, &slab->list_link);
    }
    
    total_freed++; // 更新释放统计
    cprintf("SLUB_free: freed object %p from cache %s\n", obj, cache->name);
}

// 大内存直接使用页分配器
void *slub_alloc_pages(size_t n) {
    struct Page *page = alloc_pages(n); // 分配物理页
    void *result = page ? page2kva(page) : NULL; // 转换为虚拟地址
    cprintf("SLUB: allocated %lu pages at %p\n", n, result);
    return result;
}

void slub_free_pages(void *addr, size_t n) {
    if (addr == NULL) return;
    struct Page *page = pa2page(PADDR(addr)); // 虚拟地址→物理页
    cprintf("SLUB: freeing %lu pages at %p\n", n, addr);
    free_pages(page, n); // 释放物理页
}

// 精简测试函数
void slub_basic_test(void) {
    
    // 测试1: 基本功能 : 分配和释放
    cprintf("Test 1: Basic alloc/free\n");
    void *ptr1 = slub_alloc(32);
    void *ptr2 = slub_alloc(64); 
    void *ptr3 = slub_alloc(128);
    
    cprintf("  Allocated: 32B%p, 64B%p, 128B%p\n", ptr1, ptr2, ptr3);
    assert(ptr1 != NULL && ptr2 != NULL && ptr3 != NULL);
    
    slub_free(ptr1);
    slub_free(ptr2);
    slub_free(ptr3);
    cprintf("  Basic alloc/free: PASS\n");
    
    // 测试2: 缓存重用 : 再次分配应该重用之前的slab
    cprintf("Test 2: Cache reuse\n");
    void *ptr4 = slub_alloc(32);
    cprintf("  Re-allocated 32B: %p\n", ptr4);
    assert(ptr4 != NULL);
    slub_free(ptr4);
    cprintf("  Cache reuse: PASS\n");
    
    // 测试3: 大对象回退到页分配器
    cprintf("Test 3: Large object fallback\n");
    void *large_ptr = slub_alloc(2048); // 大于128B，应该使用页分配器
    cprintf("  Large allocation (2048B): %p\n", large_ptr);
    assert(large_ptr != NULL);
    slub_free_pages(large_ptr, 1);
    cprintf("  Large object fallback: PASS\n");
    
    // 测试4: 多个对象分配（验证slab管理）
    cprintf("Test 4: Multiple objects in slab\n");
    void *objs[5];
    for (int i = 0; i < 5; i++) {
        objs[i] = slub_alloc(32);
        assert(objs[i] != NULL);
        // 写入可识别的数据
        memset(objs[i], 0xA0 + i, 32);
    }
    
    // 验证数据完整性
    for (int i = 0; i < 5; i++) {
        assert(*(char*)objs[i] == (char)(0xA0 + i));
    }
    
    // 释放所有对象
    for (int i = 0; i < 5; i++) {
        slub_free(objs[i]);
    }
    cprintf("  Multiple objects: PASS\n");
}

void slub_check(void) {
    cprintf("\n SLUB Consistency Check :\n");
    
    for (int i = 0; i < SLAB_CACHE_NUM; i++) {
        cache_t *cache = &slub_caches[i];
        size_t total_slabs = 0;
        size_t total_objects = 0;
        size_t free_objects = 0;
        
        // 统计全满列表中的slab
        list_entry_t *le;
        le = list_next(&cache->slabs_full);
        while (le != &cache->slabs_full) {
            slab_t *slab = le2slab(le, list_link);
            total_slabs++;
            total_objects += slab->total_objects; // 全满slab没有空闲对象
            le = list_next(le);
        }
        // 统计部分分配列表中的slab
        le = list_next(&cache->slabs_partial);
        while (le != &cache->slabs_partial) {
            slab_t *slab = le2slab(le, list_link);
            total_slabs++;
            total_objects += slab->total_objects;
            free_objects += slab->free_objects; // 累加空闲对象数
            le = list_next(le);
        }
        // 统计空闲列表中的slab
        le = list_next(&cache->slabs_free);
        while (le != &cache->slabs_free) {
            slab_t *slab = le2slab(le, list_link);
            total_slabs++;
            total_objects += slab->total_objects;
            free_objects += slab->free_objects; // 累加空闲对象数
            le = list_next(le);
        }
        
        cprintf("Cache %s: slabs=%lu, objects=%lu, free=%lu\n",
               cache->name, total_slabs, total_objects, free_objects);
    }
    
    // 内存泄漏检查
    cprintf("Memory leak check: allocated=%lu, freed=%lu, potential_leaks=%lu\n",
           total_allocated, total_freed, total_allocated - total_freed);
    
    cprintf(" SLUB Check Complete !\n");
}

#include <pmm.h>
#include <list.h>
#include <string.h>
#include <buddy_pmm.h>
#include <stdio.h>

// 定义最大支持的块大小的阶数（2^MAX_ORDER 页）
#define MAX_ORDER 20

// 空闲区域数组，每个元素对应一个阶数的空闲链表
typedef struct {
    list_entry_t free_list;     // 该阶数的空闲块链表
    unsigned int nr_free;       // 该阶数中空闲块的数量
} free_buddy_t;

// 全局变量：管理不同大小的空闲块
static free_buddy_t free_buddy[MAX_ORDER];

// 获取页面的阶数
static unsigned int page_order(struct Page *p) {
    return p->property;
}

// 设置页面的阶数
static void set_page_order(struct Page *p, unsigned int order) {
    p->property = order;
}

// 判断地址是否对齐到 2^order 个页面
static bool is_page_buddy_aligned(struct Page *page, unsigned int order) {
    unsigned long addr = page2pa(page);
    return (addr >> PGSHIFT) % (1U << order) == 0;
}

// 获取伙伴块的 Page 结构
static struct Page *get_buddy_page(struct Page *page, unsigned int order) {
    unsigned long buddy_ppn = page2ppn(page) ^ (1UL << order);
    if (buddy_ppn >= npage) return NULL;  // 超出物理内存范围
    return &pages[buddy_ppn];
}

static void buddy_init(void) {
    // 初始化每个阶数的空闲链表
    for (int i = 0; i < MAX_ORDER; i++) {
        list_init(&(free_buddy[i].free_list));
        free_buddy[i].nr_free = 0;
    }
    cprintf("memory management: buddy_system_pmm_manager\n");
}

static void buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    
    // 初始化所有页面
    struct Page *p = base;
    for (; p != base + n; p++) {
        p->flags = p->property = 0;
        set_page_ref(p, 0);
    }
    
    // 找到最大的 2 的幂次，这将是我们的起始块大小
    unsigned int order = 0;
    size_t size = n;
    while (size > 1) {
        size >>= 1;
        order++;
    }
    if (n != (1UL << order)) {
        order--;  // 如果不是 2 的整数幂，取小一级的幂
    }
    
    // 将起始块加入对应阶数的空闲链表
    base->property = order;
    SetPageProperty(base);
    list_add(&(free_buddy[order].free_list), &(base->page_link));
    free_buddy[order].nr_free++;
    
    // 如果还有剩余页面，递归处理
    size_t remaining = n - (1UL << order);
    if (remaining > 0) {
        buddy_init_memmap(base + (1UL << order), remaining);
    }
}

static struct Page *buddy_alloc_pages(size_t n) {
    assert(n > 0);
    
    // 计算需要的块大小的阶数
    unsigned int order = 0;
    size_t size = n;
    while ((1UL << order) < size) {
        order++;
    }
    
    // 在相应或更大的阶数中查找空闲块
    unsigned int current_order = order;
    struct Page *page = NULL;
    
    while (current_order < MAX_ORDER) {
        if (!list_empty(&(free_buddy[current_order].free_list))) {
            page = le2page(list_next(&(free_buddy[current_order].free_list)), page_link);
            list_del(&(page->page_link));
            free_buddy[current_order].nr_free--;
            
            // 分割大块直到得到合适大小
            while (current_order > order) {
                current_order--;
                struct Page *buddy = page + (1UL << current_order);
                set_page_order(buddy, current_order);
                SetPageProperty(buddy);
                list_add(&(free_buddy[current_order].free_list), &(buddy->page_link));
                free_buddy[current_order].nr_free++;
            }
            
            ClearPageProperty(page);
            return page;
        }
        current_order++;
    }
    
    return NULL;
}

static void buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    
    // 计算块的阶数
    unsigned int order = 0;
    size_t size = n;
    while ((1UL << order) < size) {
        order++;
    }
    
    // 设置页面属性
    base->property = order;
    SetPageProperty(base);
    
    // 尝试合并伙伴块
    while (order < MAX_ORDER - 1) {
        struct Page *buddy = get_buddy_page(base, order);
        
        // 检查伙伴块是否存在且空闲
        if (buddy != NULL && PageProperty(buddy) && page_order(buddy) == order) {
            // 从空闲链表中移除伙伴块
            list_del(&(buddy->page_link));
            free_buddy[order].nr_free--;
            ClearPageProperty(buddy);
            
            // 确保 base 指向较低地址的块
            if (buddy < base) {
                base = buddy;
            }
            
            // 增加阶数，继续尝试合并
            order++;
            base->property = order;
        } else {
            break;
        }
    }
    
    // 将最终的块添加到对应阶数的空闲链表中
    list_add(&(free_buddy[order].free_list), &(base->page_link));
    free_buddy[order].nr_free++;
}

static size_t buddy_nr_free_pages(void) {
    size_t total = 0;
    for (int i = 0; i < MAX_ORDER; i++) {
        total += free_buddy[i].nr_free * (1UL << i);
    }
    return total;
}

static void buddy_check(void) {
    cprintf("buddy_check() BEGIN\n");
    
    // 基本分配/释放测试
    struct Page *p0, *p1, *p2;
    p0 = p1 = p2 = NULL;
    
    // 分配单个页面
    assert((p0 = alloc_pages(1)) != NULL);
    assert((p1 = alloc_pages(2)) != NULL);
    assert((p2 = alloc_pages(4)) != NULL);
    
    // 验证页面引用计数和地址
    assert(p0 != p1 && p0 != p2 && p1 != p2);
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
    
    // 释放并验证合并
    free_pages(p0, 1);
    free_pages(p1, 2);
    free_pages(p2, 4);
    
    // 验证大块分配
    p0 = alloc_pages(8);
    assert(p0 != NULL);
    free_pages(p0, 8);
    
    // 验证碎片整理
    p0 = alloc_pages(2);
    p1 = alloc_pages(1);
    p2 = alloc_pages(1);
    
    free_pages(p1, 1);
    free_pages(p2, 1);
    free_pages(p0, 2);
    
    cprintf("buddy_check() END\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
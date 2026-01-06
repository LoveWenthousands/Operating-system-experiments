#ifndef __KERN_SCHEDULE_SCHED_H__
#define __KERN_SCHEDULE_SCHED_H__

#include <defs.h>
#include <list.h>
#include <skew_heap.h>

#define MAX_TIME_SLICE 5

struct proc_struct;

struct run_queue;

// The introduction of scheduling classes is borrrowed from Linux, and makes the
// core scheduler quite extensible. These classes (the scheduler modules) encapsulate
// the scheduling policies.
struct sched_class
{
    // the name of sched_class
    const char *name;// 调度类名称
    // Init the run queue
    void (*init)(struct run_queue *rq); // 初始化运行队列
    // put the proc into runqueue, and this function must be called with rq_lock
    void (*enqueue)(struct run_queue *rq, struct proc_struct *proc);// 进程入队
    // get the proc out runqueue, and this function must be called with rq_lock
    void (*dequeue)(struct run_queue *rq, struct proc_struct *proc);// 进程出队
    // choose the next runnable task
    struct proc_struct *(*pick_next)(struct run_queue *rq);// 选择下一个运行进程
    // dealer of the time-tick
    void (*proc_tick)(struct run_queue *rq, struct proc_struct *proc);// 时钟 tick 处理
    /* for SMP support in the future
     *  load_balance
     *     void (*load_balance)(struct rq* rq);
     *  get some proc from this rq, used in load_balance,
     *  return value is the num of gotten proc
     *  int (*get_proc)(struct rq* rq, struct proc* procs_moved[]);
     */
};

struct run_queue
{
    list_entry_t run_list;// 链表（用于RR等简单调度算法）
    unsigned int proc_num;// 队列中进程数量
    int max_time_slice;// 最大时间片（RR算法用）
    // For LAB6 ONLY
    skew_heap_entry_t *lab6_run_pool;// 斜堆（用于stride等优先级调度算法）
};

void sched_init(void);
void wakeup_proc(struct proc_struct *proc);
void schedule(void);
void sched_class_proc_tick(struct proc_struct *proc);
#endif /* !__KERN_SCHEDULE_SCHED_H__ */

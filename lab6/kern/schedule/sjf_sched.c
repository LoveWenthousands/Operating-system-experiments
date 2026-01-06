#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

#ifndef UINT32_MAX
#define UINT32_MAX ((uint32_t)-1)
#endif

/* SJF (non-preemptive) scheduler: choose process with smallest sjf_expected */

static void sjf_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->proc_num = 0;
}

static void sjf_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    list_entry_t *le;

    assert(list_empty(&proc->run_link));
    /* default: unknown (0) => treat as very large to avoid priority */
    uint32_t mylen = (proc->sjf_expected == 0) ? UINT32_MAX : proc->sjf_expected;

    /* find first element with greater expected length */
    le = list_next(&rq->run_list);
    while (le != &rq->run_list) {
        struct proc_struct *p = le2proc(le, run_link);
        uint32_t plen = (p->sjf_expected == 0) ? UINT32_MAX : p->sjf_expected;
        if (mylen < plen) {
            /* insert before le */
            list_add_before(le, &proc->run_link);
            proc->rq = rq;
            rq->proc_num++;
            return;
        }
        le = list_next(le);
    }
    /* no larger found => insert at tail */
    list_add_before(&rq->run_list, &proc->run_link);
    proc->rq = rq;
    rq->proc_num++;
}

static void sjf_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(!list_empty(&proc->run_link) && proc->rq == rq);
    list_del_init(&proc->run_link);
    rq->proc_num--;
}

static struct proc_struct *sjf_pick_next(struct run_queue *rq)
{
    list_entry_t *le = list_next(&rq->run_list);
    if (le != &rq->run_list)
        return le2proc(le, run_link);
    return NULL;
}

/* non-preemptive: tick does not force resched */
static void sjf_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    /* do nothing; SJF non-preemptive */
}

struct sched_class sjf_sched_class = {
    .name = "SJF_scheduler",
    .init = sjf_init,
    .enqueue = sjf_enqueue,
    .dequeue = sjf_dequeue,
    .pick_next = sjf_pick_next,
    .proc_tick = sjf_proc_tick,
};
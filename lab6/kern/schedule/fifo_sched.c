#include <defs.h>
#include <list.h>
#include <proc.h>
#include <assert.h>
#include <default_sched.h>

/* FIFO scheduler: non-preemptive simple queue */

static void fifo_init(struct run_queue *rq)
{
    list_init(&rq->run_list);
    rq->proc_num = 0;
}

static void fifo_enqueue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(list_empty(&proc->run_link));
    /* place at tail (before head sentinel) */
    list_add_before(&rq->run_list, &proc->run_link);
    proc->rq = rq;
    rq->proc_num++;
    /* FIFO non-preemptive: time_slice not used */
}

static void fifo_dequeue(struct run_queue *rq, struct proc_struct *proc)
{
    assert(!list_empty(&proc->run_link) && proc->rq == rq);
    list_del_init(&proc->run_link);
    rq->proc_num--;
}

static struct proc_struct *fifo_pick_next(struct run_queue *rq)
{
    list_entry_t *le = list_next(&rq->run_list);
    if (le != &rq->run_list)
        return le2proc(le, run_link);
    return NULL;
}

/* no preemption on tick */
static void fifo_proc_tick(struct run_queue *rq, struct proc_struct *proc)
{
    /* intentionally empty - FIFO is non-preemptive */
}

struct sched_class fifo_sched_class = {
    .name = "FIFO_scheduler",
    .init = fifo_init,
    .enqueue = fifo_enqueue,
    .dequeue = fifo_dequeue,
    .pick_next = fifo_pick_next,
    .proc_tick = fifo_proc_tick,
};
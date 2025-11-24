### 练习1：分配并初始化一个进程控制块（需要编码）

alloc_proc函数（位于kern/process/proc.c中）负责分配并返回一个新的struct proc_struct结构，用于存储新建立的内核线程的管理信息。ucore需要对这个结构进行最基本的初始化，你需要完成这个初始化过程。

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明proc_struct中`struct context context`和`struct trapframe *tf`成员变量含义和在本实验中的作用是啥？（提示通过看代码和编程调试可以判断出来）

#### 初始化设计实现

根据题意，我们需要对proc_struct这个结构体进行初始化，我们首先去定位该结构体（proc.h）并查看相应结构信息：

```c
struct proc_struct
{
    enum proc_state state;        // Process state
    int pid;                      // Process ID
    int runs;                     // the running times of Proces
    uintptr_t kstack;             // Process kernel stack
    volatile bool need_resched;   // bool value: need to be rescheduled to release CPU?
    struct proc_struct *parent;   // the parent process
    struct mm_struct *mm;         // Process's memory management field
    struct context context;       // Switch here to run process
    struct trapframe *tf;         // Trap frame for current interrupt
    uintptr_t pgdir;              // the base addr of Page Directroy Table(PDT)
    uint32_t flags;               // Process flag
    char name[PROC_NAME_LEN + 1]; // Process name
    list_entry_t list_link;       // Process link list
    list_entry_t hash_link;       // Process hash list
};
```

我们根据指导书中“创建第0个内核线程idleproc”的内容可知，我们在初始化的时候，通过proc->state = PROC_UNINIT 来设置进程为“初始”态；通过 proc->pid = -1 来设置进程pid的未初始化值；通过 proc->pgdir = boot_pgdir 来使用内核页目录表的基址。因此我们的初始化内容如下所示（proc.c）：

```c
static struct proc_struct *
alloc_proc(void)
{
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL)
    {
        // LAB4:EXERCISE1 YOUR CODE
        proc->state=PROC_UNINIT;
        proc->pid=-1;
        proc->runs=0;
        proc->pgdir = boot_pgdir;
        proc->kstack=0;
        proc->need_resched=0;
        proc->parent = NULL;
        proc->mm = NULL;
        proc->tf=NULL;
        proc->flags = 0;
        memset(&proc->name, 0, PROC_NAME_LEN);
        memset(&proc->context,0,sizeof(struct context));
    }
    return proc;
}
```

###### 初始化说明：

- state = PROC_UNINIT ：因为新分配的进程控制块还未完全初始化，不能投入运行，因此我们标识进程为“未初始化”状态，后续设置完成后会改为就绪状态

- pid = -1 ：未初始化的进程号我们需要设置为-1

- runs = 0 ：runs用来统计进程被调度的次数，由于是刚刚初始化的进程，因此我们将其设置为0

- pgdir = boot_pgdir ：由于内核线程共享内核的页表，因此我们使用内核页目录表的基址boot_pgdir

- kstack = 0：内核栈地址,该进程分配的地址为0，因为还没有执行，也没有被重定位，因为默认地址都是从0开始的

- need_resched = 0 ：是一个用于判断当前进程是否需要被调度的bool类型变量，为1则需要进行调度。初始化的过程中我们不需要对其进行调度，因此设置为0

- parent = NULL ：在alloc_proc时我们还不知道父进程，因此设置为NULL

- mm = NULL：虚拟内存为空，设置为NULL

- tf = NULL：中断帧指针为空，设置为NULL

- flags = 0 ：标志位flags设置为0

- memset(&proc->name, 0, PROC_NAME_LEN)：将进程名name初始化为0

- memset(&proc->context,0,sizeof(struct context))：初始化上下文，将上下文结构体context初始化为0

#### 问题回答：

##### struct context context 成员变量含义和在本实验中的作用

**含义**：保存进程执行时的上下文，保存进程运行时寄存器的状态。

**作用**：实现进程切换时的执行上下文保存与恢复，为核心态线程调度提供轻量级的寄存器切换机制。context只保存进程调度所需的关键寄存器（如栈指针、返回地址等），在进程主动让出CPU时通过软件方式进行上下文切换，避免了陷入内核态的完整状态保存开销，为操作系统内核提供了高效的线程调度能力。

**详细分析**：

我们来看proc.h里context结构的定义：

```c
struct context
{
    uintptr_t ra;
    uintptr_t sp;
    uintptr_t s0;
    uintptr_t s1;
    uintptr_t s2;
    uintptr_t s3;
    uintptr_t s4;
    uintptr_t s5;
    uintptr_t s6;
    uintptr_t s7;
    uintptr_t s8;
    uintptr_t s9;
    uintptr_t s10;
    uintptr_t s11;
};
```

其中，ra是返回地址寄存器，用于保存函数调用后的返回地址；sp是栈指针寄存器，指向当前线程的栈顶；s0 到 s11都是保存寄存器（scratch registers），用于保存临时数据，它们在函数调用时不需要被保存和恢复，这是因为它们不会被调用者所保留。

##### struct trapframe *tf 成员变量含义和在本实验中的作用

**含义**：这是陷阱帧，保存了进程的中断帧（32个通用寄存器、异常相关的寄存器）。

**作用**：保存了进程的中断帧（32个通用寄存器、异常相关的寄存器），实现执行状态的完全保存与精确恢复，从而为多个进程透明地共享CPU提供技术基础。通过完整保存32个通用寄存器和异常相关寄存器，操作系统能够在中断或进程切换时捕获进程的完整执行状态，使得每个进程都觉得自己在独占CPU连续运行，而不知道被频繁中断和调度的事实，这样就实现了多任务并发的透明性和进程间的完全隔离。

**详细分析**：

我们来看 tf 指针指向的 trapframe 结构的具体定义：

```c
struct pushregs
{
    uintptr_t zero; // Hard-wired zero
    uintptr_t ra;   // Return address
    uintptr_t sp;   // Stack pointer
    uintptr_t gp;   // Global pointer
    uintptr_t tp;   // Thread pointer
    uintptr_t t0;   // Temporary
    uintptr_t t1;   // Temporary
    uintptr_t t2;   // Temporary
    uintptr_t s0;   // Saved register/frame pointer
    uintptr_t s1;   // Saved register
    uintptr_t a0;   // Function argument/return value
    uintptr_t a1;   // Function argument/return value
    uintptr_t a2;   // Function argument
    uintptr_t a3;   // Function argument
    uintptr_t a4;   // Function argument
    uintptr_t a5;   // Function argument
    uintptr_t a6;   // Function argument
    uintptr_t a7;   // Function argument
    uintptr_t s2;   // Saved register
    uintptr_t s3;   // Saved register
    uintptr_t s4;   // Saved register
    uintptr_t s5;   // Saved register
    uintptr_t s6;   // Saved register
    uintptr_t s7;   // Saved register
    uintptr_t s8;   // Saved register
    uintptr_t s9;   // Saved register
    uintptr_t s10;  // Saved register
    uintptr_t s11;  // Saved register
    uintptr_t t3;   // Temporary
    uintptr_t t4;   // Temporary
    uintptr_t t5;   // Temporary
    uintptr_t t6;   // Temporary
};

struct trapframe
{
    struct pushregs gpr;  // 所有通用寄存器
    uintptr_t status;     // 状态寄存器 (sstatus)
    uintptr_t epc;        // 异常程序计数器
    uintptr_t badvaddr;   // 错误虚拟地址
    uintptr_t cause;      // 异常原因 (scause)
};
```

这验证了我们上述所说的作用，即该成员变量保存了进程的中断帧（32个通用寄存器、异常相关的寄存器）。

### 练习2：为新创建的内核线程分配资源（需要编码）

创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_kernel函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要"fork"的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：

- 调用alloc_proc，首先获得一块用户信息块
- 为进程分配一个内核栈
- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
- 复制原进程上下文到新进程
- 将新进程添加到进程列表
- 唤醒新进程
- 返回新进程号

请在实验报告中简要说明你的设计实现过程。请回答如下问题：

- 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。

#### 设计实现过程说明

我们找到 kern/process/proc.c 中的 do_fork 函数中的处理过程，然后按照相应的步骤进行程序设计：

- 调用alloc_proc，首先获得一块用户信息块
  
  ```c
  if ((proc = alloc_proc()) == NULL) {
      goto fork_out;
  }
  //我们调用alloc_proc函数，获取一个新的用户信息块，如果为空的话就跳转到fork_out做失败返回处理
  ```

- 为进程分配一个内核栈
  
  ```c
  if(setup_kstack(proc)!=0){
      goto bad_fork_cleanup_proc;
  }
  //我们调用setup_kstack函数，分配一个内核栈，如果没有的话就进行失败处理
  ```

- 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
  
  ```c
  if(copy_mm(clone_flags,proc)!=0){
      goto bad_fork_cleanup_kstack;
  }
  //copy_mm()函数内容如下所示
  static int
  copy_mm(uint32_t clone_flags, struct proc_struct *proc)
  {
      assert(current->mm == NULL);
      /* do nothing in this project */
      return 0;
  }
  ```

- 复制原进程上下文到新进程
  
  ```c
  copy_thread(proc,stack,tf);
  
  //调用copy_thread()函数复制父进程的中断帧和上下文信息
  
  static void
  copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)
  {
      proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
      *(proc->tf) = *tf;
  
      // Set a0 to 0 so a child process knows it's just forked
      proc->tf->gpr.a0 = 0;
      proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
  
      proc->context.ra = (uintptr_t)forkret;
      proc->context.sp = (uintptr_t)(proc->tf);
  }
  ```

- 将新进程添加到进程列表
  
  ```c
  proc->pid=get_pid();
  hash_proc(proc);
  list_add(&proc_list,&(proc->list_link));
  //我们首先获取当前进程PID；然后调用hash_proc函数把新进程的PCB插入到哈希进程控制链表中，然后通过list_add函数把PCB插入到进程控制链表中
  ```

- 唤醒新进程
  
  ```c
  wakeup_proc(proc);
  ```

- 返回新进程号
  
  ```c
  ret=proc->pid;
  ```

#### 问题回答：

我们首先定位到proc.c文件中与分配ID相关的函数get_pid()：

```c
static int
get_pid(void)
{
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct *proc;
    list_entry_t *list = &proc_list, *le;
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    if (++last_pid >= MAX_PID)
    {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe)
    {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        while ((le = list_next(le)) != list)
        {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid)
            {
                if (++last_pid >= next_safe)
                {
                    if (last_pid >= MAX_PID)
                    {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            else if (proc->pid > last_pid && next_safe > proc->pid)
            {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}
```

我们通过分析`get_pid()`函数可以看出，**ucore确实能够为每个新fork的线程分配唯一的id**。该函数采用静态变量`last_pid`记录最后分配的PID，当需要分配新PID时，首先简单递增`last_pid`，但如果检测到可能冲突（达到`next_safe`边界），就会完整遍历进程链表进行冲突检查。一旦发现PID已被使用，就继续递增并重新扫描，直到找到未被使用的PID为止。这种设计结合了效率与可靠性，既在无冲突时快速分配，又在可能冲突时通过完全遍历确保唯一性，从而保证了每个新线程都能获得独一无二的进程ID。

此外，该函数还考虑了PID耗尽的情况，当`last_pid`达到`MAX_PID`时会回绕到1重新开始，并在回绕时强制进行全链表扫描，防止与已有进程ID冲突。这种完备的冲突解决机制，加上对进程链表的完整遍历验证，确保了在任何情况下都不会分配重复的PID，从而实现了为每个新fork线程提供唯一id的保证。

### 练习3：编写proc_run 函数（需要编码）

proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：

- 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
- 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
- 切换当前进程为要运行的进程。
- 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lsatp(unsigned int pgdir)`函数，可实现修改SATP寄存器值的功能。
- 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
- 允许中断。

请回答如下问题：

- 在本实验的执行过程中，创建且运行了几个内核线程？

完成代码编写后，编译并运行代码：make qemu

#### 设计实现过程说明

```c
void proc_run(struct proc_struct *proc) {
    if (proc != current) {
        bool intr_flag;
        struct proc_struct *prev = current, *next = proc;

        local_intr_save(intr_flag);
        {
             current = proc;
             lsatp(next->pgdir);
             // 上下文切换
             switch_to(&(prev->context), &(next->context));
        }
        local_intr_restore(intr_flag);
    }
}
```

上述是我们设计的完整的进程切换机制代码，其核心功能是在关中断保护下安全地将CPU控制权从一个进程转移到另一个进程。代码首先通过`local_intr_save`禁用中断，防止切换过程被中断打断造成状态不一致，然后将当前运行进程指针`current`更新为目标进程，接着使用`lsatp(next->pgdir)`切换页表以更新地址空间映射，最后通过`switch_to`函数执行上下文切换，保存原进程的寄存器状态并恢复新进程的执行上下文，完成后再通过`local_intr_restore`恢复中断使能。

我们的整个设计确保了进程切换的原子性和状态完整性，页表切换保证了新进程拥有独立的地址空间，上下文切换维护了进程执行的连续性，而中断保护则防止了竞争条件的发生，这些机制共同为ucore的多进程并发执行提供了可靠的基础支撑。

#### 问题回答：

在本实验的执行过程中，我们创建且运行了2个内核线程：

- idleproc：第一个内核进程，完成内核中各个子系统的初始化，之后立即调度，执行其他进程。

- initproc：用于完成实验的功能而调度的内核进程。

### 扩展练习 Challenge1：

#### 说明语句`local_intr_save(intr_flag);....local_intr_restore(intr_flag);`是如何实现开关中断的？

我们首先定位到这两个语句的相关定义部分，也就是sync.h文件：

```c
#ifndef __KERN_SYNC_SYNC_H__
#define __KERN_SYNC_SYNC_H__

#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
        intr_disable();
        return 1;
    }
    return 0;
}
static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
    }
}

#define local_intr_save(x) \
    do {                   \
        x = __intr_save(); \
    } while (0)
#define local_intr_restore(x) __intr_restore(x);
#endif /* !__KERN_SYNC_SYNC_H__ */
```

结合代码我们可以看到，`local_intr_save(intr_flag)` 通过 `__intr_save()` 函数检查 `sstatus` 寄存器的 `SSTATUS_SIE` 位来判断当前中断是否开启。如果中断原本是开启的，就调用 `intr_disable()` 关闭中断，并返回 1 记录原状态；否则直接返回 0。这样既关闭了中断保护关键代码，又通过 `intr_flag` 准确记录了中断的原始状态。

执行完关键代码后，`local_intr_restore(intr_flag)` 根据传入的 `intr_flag` 值调用 `__intr_restore()` 函数。如果 `intr_flag` 为 1，说明中断原本是开启的，就调用 `intr_enable()` 重新开启中断；如果为 0，则保持中断关闭状态不变。这种设计确保了中断状态的精确保存和恢复，支持代码嵌套而不会破坏系统的中断管理。

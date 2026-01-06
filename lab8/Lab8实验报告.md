## 练习0：填写已有实验

本实验依赖实验2/3/4/5/6/7。请把你做的实验2/3/4/5/6/7的代码填入本实验中代码中有“LAB2”/“LAB3”/“LAB4”/“LAB5”/“LAB6” /“LAB7”的注释相应部分。并确保编译通过。注意：为了能够正确执行lab8的测试应用程序，可能需对已完成的实验2/3/4/5/6/7的代码进行进一步改进。

### 解答

我们首先对于代码中需要补充lab2/3/4/5/6/7的部分进行完善，然后根据代码提示去进行lab8的改进更新。下面是更新部分的相关内容：

```c
//LAB8 2310425 : (update LAB6 steps)
proc->filesp = NULL;
```

这行代码初始化了[proc_struct](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.h#L43-L80)结构体中的[filesp](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.h#L69-L69)字段，将其设置为NULL。这是lab8中实现完整进程文件系统支持的关键部分，使得每个进程都有自己的文件描述符表，实现了进程间文件系统的隔离。

**作用：**

1. **文件系统支持**：[filesp](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.h#L69-L69)字段指向[files_struct](file://c:\Users\17913\Desktop\lab8\lab8\kern\fs\files.h#L25-L29)结构，用于管理进程打开的文件描述符表

2. **进程创建时初始化**：当创建新进程时，将该进程的文件结构指针初始化为NULL，表示初始状态下进程没有关联的文件系统结构

3. **后续分配**：真正的[files_struct](file://c:\Users\17913\Desktop\lab8\lab8\kern\fs\files.h#L25-L29)会在进程fork或exec时通过[copy_files](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.c#L399-L423)函数创建或复制

**相关函数：**

- [copy_files](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.c#L399-L423)：在[do_fork](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.c#L426-L482)中被调用，复制或创建进程的文件结构
- [put_files](file://c:\Users\17913\Desktop\lab8\lab8\kern\process\proc.c#L425-L434)：在进程退出时释放文件结构
  这个更新是lab8中实现完整进程文件系统支持的关键部分，使得每个进程都有自己的文件描述符表，实现了进程间文件系统的隔离。

```c
//LAB8 2310425 : (update LAB4 steps)
flush_tlb();
```

这里的更新主要是在proc_run函数中添加了TLB刷新操作，使我们能够在进程切换时刷新TLB，确保了进程切换时内存管理单元的正确性，是实现进程内存隔离的重要步骤。在RISC-V架构中，当页表基址寄存器（satp/lsatp）被修改后，需要刷新TLB以确保地址转换的一致性。

**作用：**

1. **TLB一致性维护**：当进程切换时，新的进程可能使用不同的页表，刷新TLB确保虚拟地址到物理地址的映射关系正确

2. **内存管理优化**：避免使用旧进程的页表缓存条目，防止内存访问错误

3. **上下文切换完整性**：在切换到新进程前，确保CPU的地址转换缓存与新进程的页表保持一致

**具体流程：**

- [lcr3(proc->pgdir)](file://c:\Users\17913\Desktop\lab8\lab8\libs\atomic.h#L105-L105)：加载新进程的页目录到CR3寄存器
- [flush_tlb()](file://c:\Users\17913\Desktop\lab8\lab8\kern\mm\pmm.h#L25-L25)：刷新TLB缓存，确保使用新的页表映射

## 练习1: 完成读文件操作的实现（需要编码）

首先了解打开文件的处理流程，然后参考本实验后续的文件读写操作的过程分析，填写在 kern/fs/sfs/sfs_inode.c中 的sfs_io_nolock()函数，实现读文件中数据的代码。

### 一、问题背景

SFS 文件系统采用固定大小块（`SFS_BLKSIZE = 4096`）作为磁盘基本存储单元，而文件的逻辑访问偏移 `offset` 和访问长度 `len` 并不一定与块边界对齐。因此一次连续的读操作往往会跨越多个磁盘块，且同时包含：

- 起始块的 **非对齐头部**

- 中间若干个 **完整对齐块**

- 结束块的 **非对齐尾部**

为了在保证正确性的同时提升磁盘访问效率，我们在`sfs_io_nolock()` 需要对这三类区域分别采用不同的处理方式。

### 二、核心代码实现

```c
// LAB8: EXERCISE1 2310425
// 1. 处理头部非对齐部分
if (blkoff != 0) {
    size_t size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
        goto out;
    }
    alen += size;
    buf += size;
    blkno++;
    if (nblks == 0) {
        goto out;
    }
    nblks--;
}

// 2. 处理中间完整块
while (nblks > 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_block_op(sfs, buf, ino, 1)) != 0) {
        goto out;
    }
    alen += SFS_BLKSIZE;
    buf += SFS_BLKSIZE;
    blkno++;
    nblks--;
}

// 3. 处理尾部非对齐部分
size_t size = endpos % SFS_BLKSIZE;
if (size != 0) {
    if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
        goto out;
    }
    if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
        goto out;
    }
    alen += size;
}
```

### 三、算法设计说明

#### 1. 关键变量含义

| 变量                                     | 含义        |
| -------------------------------------- | --------- |
| `blkno = offset / SFS_BLKSIZE`         | 起始逻辑块号    |
| `blkoff = offset % SFS_BLKSIZE`        | 起始块内偏移    |
| `endpos = offset + len`                | 本次访问的结束位置 |
| `nblks = endpos / SFS_BLKSIZE - blkno` | 中间完整块个数   |
| `buf`                                  | 用户缓冲区指针   |
| `alen`                                 | 已完成读写的字节数 |

#### 2. 头部非对齐块处理

当 `offset` 未对齐到块边界时，我们必须首先处理起始块内的残余部分：

- 本块最多可访问 `SFS_BLKSIZE - blkoff` 字节

- 若后续无完整块，则本块只访问 `endpos - offset` 字节

- 通过 `sfs_bmap_load_nolock()` 完成逻辑块号到物理块号的映射

- 使用 `sfs_buf_op()` 对物理块中指定偏移位置进行读写

该步骤能够确保文件访问从任意偏移开始都能精确命中正确磁盘数据。

#### 3. 中间完整块处理

对于完全对齐的中间区域，我们采用 **块级 I/O**：

- 每次处理整整一个 4096 字节块

- 使用 `sfs_block_op()` 调用底层的 `sfs_rblock / sfs_wblock`

- 避免多次 buffer copy，提高磁盘访问效率

这是整个算法中性能优化最关键的一环。

#### 4. 尾部非对齐块处理

当 `endpos` 未对齐到块边界时，我们需要额外处理最后一个磁盘块的前 `endpos % SFS_BLKSIZE` 字节：

- 再次进行逻辑块到物理块的映射

- 使用 `sfs_buf_op()` 从块起始位置进行精确读写

- 确保不会读写超出文件有效范围

### 四、设计优势总结

1. **正确性：**  任意偏移、任意长度的读写请求都可被拆分为三段精确执行，保证数据不会错位或越界。

2. **高性能：**  对齐区间使用块级 I/O，显著减少磁盘访问次数与内存拷贝次数。

3. **良好的扩展性：**  该分段模型同样适用于写操作、文件扩展、页缓存等后续功能。

下面给出一份已经整理为**报告可直接使用版**的“练习2”最终说明稿，行文风格、技术深度与期末综合实验报告标准完全对齐。

## 练习2：完成基于文件系统的执行程序机制的实现（需要编码）

改写proc.c中的load_icode函数和其他相关函数，实现基于文件系统的执行程序机制。执行：make qemu。如果能看看到sh用户程序的执行界面，则基本成功了。如果在sh用户界面上可以执行`exit`, `hello`（更多用户程序放在`user`目录下）等其他放置在`sfs`文件系统中的其他执行程序，则可以认为本实验基本成功。

### 一、实验目标

本练习要求实现 `execve` 的完整执行路径，使内核能够**直接从 SFS 文件系统中加载 ELF 可执行文件并运行**，最终达到：

- `make qemu` 后进入用户态 `sh`

- 在 `sh` 中可正确执行位于文件系统中的 `hello`、`exit` 等程序

其核心在于改写 `kern/process/proc.c` 中的 `load_icode`，使原先“从内存 binary 加载程序”的方式，升级为**从文件描述符 fd 读取 ELF 并构造新的用户态执行环境**。

### 二、实现总体思路

**`load_icode(fd, argc, kargv)` 的本质作用是：**

用 fd 指定的 ELF 程序完全替换当前进程的用户态地址空间，并构造一个能从该程序入口开始执行的新用户态环境。

其整体流程可归纳为三步：

1. **建立全新的用户虚拟地址空间**（mm + 新页表）

2. **从文件系统中按 ELF Program Header 加载程序段到内存**

3. **构造用户栈与 trapframe，使 CPU 能正确返回用户态执行**

### 三、执行路径总览

当用户在 `sh` 中执行：

```bash
hello
```

用户态发起 `execve("hello", argv, envp)` → 内核 `do_execve` 打开文件得到 `fd` → 调用：

```c
load_icode(fd, argc, kargv);
```

加载完成后：

- `current->mm` 被替换为新的 mm

- `current->pgdir` 切换到新页表

- `current->tf` 设置为用户态初始现场

随后内核 `sret`，CPU 从 ELF 入口地址开始运行新程序。

### 四、关键实现过程说明

##### 1. 新地址空间的建立（mm_struct 与页表）

```c
if (current->mm != NULL) {
    panic("load_icode: current->mm must be empty.\n");
}
if ((mm = mm_create()) == NULL) {
    goto bad_mm;
}
if ((ret = setup_pgdir(mm)) != 0) {
    goto bad_pgdir;
}
```

`execve` 的本质语义是**用一个新程序完全替换当前进程的用户态执行映像**。因此在加载新程序之前，必须销毁原有用户地址空间，并重新构造一个全新的 `mm_struct` 结构与页表。

- `mm_create()` 用于分配并初始化新的地址空间控制块，其中包含 VMA 链表、页表指针、引用计数等核心字段。

- `setup_pgdir(mm)` 为该地址空间创建新的页表根节点，使后续映射的虚拟页都属于该进程私有空间。

如果不重新建立 mm，而是在原有 mm 上直接加载新程序，则会导致：

- 旧程序的 VMA、堆栈、共享页残留

- 虚拟地址区间重叠

- 新程序访问到旧进程的敏感内存，破坏进程隔离

##### 2. ELF 头的读取与合法性校验

```c
struct elfhdr elf;
load_icode_read(fd, &elf, sizeof(elf), 0);

if (elf.e_magic != ELF_MAGIC) {
    ret = -E_INVAL_ELF;
    goto bad_elf;
}
```

ELF Header 描述了整个可执行文件的总体布局，是后续所有加载行为的**元数据入口**。  
通过 `load_icode_read` 以偏移 0 从 SFS 文件系统中读取 ELF 头，可以实现：

- 确定文件是否为合法 ELF 可执行文件

- 获取 Program Header 表的位置、数量

- 获得程序入口地址 `e_entry`

`e_magic` 的校验防止将普通文本文件或损坏文件错误当作可执行程序加载，从而避免内核在后续映射与跳转时发生不可预期的崩溃。

##### 3. Program Header 遍历与 VMA 建立

```c
if (ph.p_type != ELF_PT_LOAD) continue;
mm_map(mm, ROUNDDOWN(ph.p_va, PGSIZE),
       ROUNDUP(ph.p_memsz, PGSIZE),
       vm_flags, NULL);
```

ELF 的 Program Header 描述了每一个需要被加载到内存的段（代码段、数据段、BSS段等）。  
遍历所有 `PT_LOAD` 项的目的，是将磁盘文件中的“段结构”转化为内存中的“虚拟内存区间（VMA）”。

- `ROUNDDOWN/ROUNDUP` 保证 VMA 与页边界对齐，便于页级管理

- `vm_flags` 决定该段的访问权限（读 / 写 / 执行）

VMA 是 uCore 虚拟内存系统中**合法访问区域的唯一判定依据**，只有存在 VMA 的地址范围，页缺页异常才会被正确处理。

##### 4. 页级分配与 ELF 段加载（含 BSS 构造）

```c
page = pgdir_alloc_page(mm->pgdir, cur, perm);
memset(kva, 0, PGSIZE);
load_icode_read(...);
```

VMA 只描述“哪一段地址合法”，而**真正可用的内存页必须逐页分配并建立页表映射**。

- `pgdir_alloc_page` 为虚拟页分配物理页并写入页表

- `memset(...,0)` 统一清零整页，自动完成 BSS 段的初始化

- 只在 `filesz` 范围内从磁盘拷贝真实数据，其余区域保持为 0

这种“先清零，再拷贝”的策略统一解决了 TEXT、DATA、BSS 三类段的加载问题，保证：

- BSS 段自动初始化为全 0

- 不会访问到未初始化的脏页数据

- 页表与段布局完全一致

##### 5. 用户栈区映射与物理页预分配

```c
mm_map(mm, USTACKTOP-USTACKSIZE, USTACKSIZE,
       VM_READ | VM_WRITE | VM_STACK, NULL);
pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE, PTE_USER);
...
```

所有用户程序都依赖一个规范的用户栈区来保存函数调用现场、局部变量及参数。

- `mm_map` 建立合法的 VMA 区间

- 预分配多页物理页，保证程序刚开始执行时就拥有可用栈空间

若不预分配，则第一个函数调用就会触发缺页异常，影响系统稳定性与调试可控性。

##### 6. 页表切换与地址空间生效

```c
current->mm = mm;
lsatp(current->pgdir);
```

只有当页表根地址写入 SATP 寄存器后，CPU 才会开始按照新地址空间进行地址转换，这一步标志着**新程序虚拟内存环境正式生效**。

##### 7. 用户栈参数构造（argv / argc）

```c
copy_to_user(mm, (void*)sp, kargv[i], strlen(kargv[i])+1);
```

通过在用户栈中手动构造 `argc/argv` 布局，使新程序能够像普通 C 程序一样从 `main(int argc,char* argv[])` 开始执行，实现标准用户态 ABI 支持。

##### 8. Trapframe 初始化与用户态跳转

```c
tf->epc = elf.e_entry;
tf->gpr.sp = sp;
```

设置 EPC、SP、参数寄存器并通过 `sret` 返回用户态，使 CPU 从 ELF 指定的入口地址开始执行新程序，实现完整 execve 语义闭环。

### 五、设计特点与实验价值

1. **实现完整 execve 语义**：真正做到“进程换脑”，而非简单跳转

2. **文件系统集成**：用户程序来自 SFS，形成完整 OS 运行闭环

3. **页级加载 + BSS 自动清零**：高效且内存安全

4. **严格的资源回收机制**：保证加载失败不泄露页表与物理页

5. **正确的 ABI 参数传递**：用户程序可直接使用标准 `main(argc, argv)`

### 六、结果输出展示

#### make qemu

![](C:\Users\17913\AppData\Roaming\marktext\images\2026-01-06-21-10-14-fdde3d91a2b929ff80b824dc94892428.png)

我们能够成功看到sh用户程序的执行界面，说明我们的实现基本成功了。

#### 在sh用户界面上执行exit 、hello

<img title="" src="file:///C:/Users/17913/AppData/Roaming/marktext/images/2026-01-06-21-13-15-acd04e27fb8449e12ba62ea3dcb9f1e9.png" alt="" width="366">

能够在sh用户界面上执行`exit`, `hello`等其他放置在`sfs`文件系统中的执行程序，并得到预期正确输出，本次实验基本成功。

#### make grade

<img src="file:///C:/Users/17913/AppData/Roaming/marktext/images/2026-01-06-21-17-32-ff79ec587de870cd83cfcc53a9798502.png" title="" alt="" width="551">

我们可以看到，make grade 可以得到满分，说明我们可以通过练习2相关的所有测试，表示我们的实现完全正确。

## 扩展练习 Challenge1：完成基于“UNIX的PIPE机制”的设计方案

如果要在ucore里加入UNIX的管道（Pipe）机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的PIPE机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

### 解答

#### 一、UNIX PIPE机制概述

UNIX管道（Pipe）是一种基础的进程间通信（IPC）机制，它为两个进程提供了一个单向的数据传输通道。从本质上讲，管道是一个在内核空间中维护的、具有固定大小的环形缓冲区。数据由一个进程（写端）写入缓冲区，再由另一个进程（读端）从中读取，数据的传输遵循先进先出（FIFO）的原则。
管道通过一对文件描述符（file descriptor）来操作，一个用于写入（write end），一个用于读取（read end）。这使得管道的I/O操作与普通文件的读写操作完全一致，完美地体现了UNIX系统“一切皆文件”的设计哲学。管道的生命周期与创建它的进程相关，当持有管道两端文件描述符的所有进程都终止或关闭了这些描述符后，内核才会回收管道占用的资源。

#### 二、数据结构设计

##### 1. 管道核心结构体 `struct pipe`

为了在内核中表示一个管道，我们需要定义一个核心数据结构。这个结构体不仅要包含数据缓冲区本身，还必须包含用于同步和互斥的机制包含用于同步和互斥的机制，以确保在多进程并发访问时数据的一致性和完整性。

```c
#include <spinlock.h>
#include <wait.h>
#define PIPE_BUFFER_SIZE 4096 // 定义管道缓冲区大小，例如4KB
struct pipe {
 char buffer[PIPE_BUFFER_SIZE]; // 管道的核心数据缓冲区
 size_t read_ptr; // 读指针，指向下一个待读取的字节位置
 size_t write_ptr; // 写指针，指向下一个待写入的字节位置
 size_t count; // 缓冲区中当前有效数据的字节数
 struct spinlock lock; // 自旋锁，用于保护pipe结构体的并发访问
 // 同步机制：使用等待队列来处理阻塞
 struct wait_queue read_wait; // 当管道为空时，读进程在此等待
 struct wait_queue write_wait; // 当管道满时，写进程在此等待
 int readers; // 当前活动的读端数量
 int writers; // 当前活动的写端数量
};
```

**解释说明：**

- `buffer`：这是管道的物理存储区域，所有通过管道传输的数据都暂存于此。

- `read_ptr` 和 `write_ptr`：这两个指针共同管理着环形缓冲区。当指针到达缓冲区末尾时，它们会回绕到起始位置。

- `count`：记录缓冲区中当前数据的总量。这个计数器极大地简化了空/满状态的判断，避免了复杂的指针运算。

- `lock`：一个自旋锁。在任何时刻，只有一个进程可以修改 `read_ptr`、`write_ptr`、`count` 等共享状态。它确保了对管道元数据操作的原子性，是实现互斥的关键。

- `read_wait` 和 `write_wait`：等待队列。当一个读进程试图从空管道读取数据时，它会释放CPU并进入睡眠状态，挂接到 `read_wait` 队列。同样，当一个写进程试图向满管道写入数据时，它会挂接到 `write_wait` 队列。当条件满足时（如管道被写入数据或数据被读取），唤醒相应队列上的等待进程。

- `readers` 和 `writers`：引用计数。这两个计数器用于跟踪当前有多少个进程分别打开了管道的读端和写端。当 `writers` 变为0时，读进程再读取时会收到EOF（文件结束）信号。当 `readers` 变为0时，写进程会收到一个SIGPIPE信号并默认终止。

##### 2. 管道文件操作结构体 `struct pipe_file_operations`

为了让管道能够像普通文件一样被操作，我们需要为它提供一个文件操作函数表（`file_operations`）。这个结构体将标准的文件操作（如`read`、`write`、`close`）映射到专门为管道实现的函数上。

```c
struct file; // 前向声明ucore的file结构体
struct pipe_file_operations {
ssize_t (*read)(struct file *filp, char *buf, size_t count, off_t *offset);
ssize_t (*write)(struct file *filp, const char *buf, size_t count, off_t *offset);
int (*close)(struct file *filp);
// 其他需要的操作
};
```

**解释说明：**

- 这个结构体定义了管道作为一种“文件类型”所支持的操作集。

- `read`：指向管道的读操作实现函数。

- `write`：指向管道的写操作实现函数。

- `close`：指向管道的关闭操作实现函数。当文件描述符被关闭时，此函数会被调用，其核心职责是更新`readers`或`writers`计数器，并在适当的时候（如计数器归0）唤醒等待队列或销毁管道。

##### 3. 与ucore VFS的集成

在ucore中，每个打开的文件都由一个`struct file`结构体表示。为了将管道与VFS（虚拟文件系统）层无缝集成，我们需要在`struct file`中增加一个指向我们`struct pipe`的指针。

```c
// 在ucore的 struct file 中增加一个成员
struct file {
// ... 其他已有的成员
struct pipe *pipe; // 如果此文件是一个管道，则指向对应的pipe结构体
};
```

**解释说明：**

- 当`pipe()`系统调用创建一个管道时，内核会创建两个`struct file`实例，一个代表读端，一个代表写端。

- 这两个`file`实例的`f_op`成员都将指向同一个`struct pipe_file_operations`。

- 更重要的是，它们的`pipe`成员将指向同一个`struct pipe`实例。这样，无论操作哪个文件描述符，最终都会通过这个共享的`pipe`指针访问到同一个内核缓冲区和同步原语，从而实现了数据的共享和正确的同步。

#### 三、核心接口设计

##### 1. `int pipe(int fd[2])`

- **接口语义**：创建一个匿名管道，并通过参数`fd`数组返回两个文件描述符。`fd[0]`是管道的读端，`fd[1]`是管道的写端。

- **设计实现**：
1. 在内核中分配一个新的`struct pipe`实例，并初始化其所有成员（缓冲区清零、指针置零、计数器置零、初始化自旋锁和等待队列）。

2. 为当前进程分配两个空闲的文件描述符，分别存入`fd[0]`和`fd[1]`。

3. 为这两个文件描述符创建对应的`struct file`结构体。

4. 将这两个`file`结构体的`f_op`成员设置为`pipe_file_operations`。

5. 将这两个`file`结构体的`pipe`成员指向第一步中创建的`struct pipe`实例。

6. 将`pipe`结构体的`readers`和`writers`计数器都设置为1。

7. 将这两个`file`结构体关联到当前进程的文件描述符表中。

8. 返回0表示成功。

##### 2. `ssize_t pipe_read(struct file *filp, char *buf, size_t count, off_t *offset)`

- **接口语义**：从与文件描述符关联的管道中读取数据。

- **设计实现**：
1. 获取`filp->pipe`指向的`struct pipe`实例。

2. 持有`pipe->lock`自旋锁。

3. **等待数据**：如果`pipe->count`为0（管道为空）：如果`filp->f_flags`设置了`O_NONBLOCK`（非阻塞），则立即返回-1（或`EAGAIN`）。否则，调用`sleep_on(&pipe->read_wait)`，释放CPU并进入睡眠状态，直到被写进程唤醒。唤醒后重新检查`pipe->count`。

4. **读取数据**：从`pipe->read_ptr`指向的位置开始，将数据复制到用户缓冲区`buf`中，最多复制`count`字节或`pipe->count`字节。

5. **更新状态**：更新`pipe->read_ptr`（考虑回绕）和`pipe->count`。

6. **唤醒写者**：如果在读取前管道是满的（`pipe->count`等于`PIPE_BUFFER_SIZE`），那么现在有了空闲空间，调用`wakeup(&pipe->write_wait)`来唤醒可能正在等待的写进程。

7. 释放`pipe->lock`。

8. 返回实际读取的字节数。如果管道的所有写端都已关闭（`pipe->writers == 0`）且缓冲区已空，则返回0，表示EOF。

##### 3. `ssize_t pipe_write(struct file *filp, const char *buf, size_t count, off_t *offset)`

- **接口语义**：向与文件描述符关联的管道写入数据。

- **设计实现**：
1. 获取`filp->pipe`指向的`struct pipe`实例。
2. 持有`pipe->lock`自旋锁。
3. **检查读端**：如果`pipe->readers`为0（所有读端都已关闭），则向当前进程发送`SIGPIPE`信号，并返回-1（或`EPIPE`）。
4. **等待空间**：如果`pipe->count`等于`PIPE_BUFFER_SIZE`（管道已满）：如果`filp->f_flags`设置了`O_NONBLOCK`，则立即返回-1。否则，调用`sleep_on(&pipe->write_wait)`进入睡眠，直到被读进程唤醒。
5. **写入数据**：从用户缓冲区`buf`中复制数据到`pipe->write_ptr`指向的位置，最多复制`count`字节或缓冲区剩余的空闲字节数。
6. **更新状态**：更新`pipe->write_ptr`和`pipe->count`。
7. **唤醒读者**：如果在写入前管道是空的（`pipe->count`为0），那么现在有了数据，调用`wakeup(&pipe->read_wait)`来唤醒可能正在等待的读进程。
8. 释放`pipe->lock`。
9. 返回实际写入的字节数。

##### 4. `int pipe_close(struct file *filp)`

- **接口语义**：关闭管道的一端（读端或写端）。

- **设计实现**：
1. 获取`filp->pipe`指向的`struct pipe`实例。
2. 持有`pipe->lock`自旋锁。
3. **更新引用计数**：根据`filp`是读端还是写端，将`pipe->readers`或`pipe->writers`减1。
4. **处理特殊情况**：如果`pipe->writers`变为0，说明不会再有数据写入。调用`wakeup(&pipe->read_wait)`唤醒所有等待读取的进程，让它们能够收到EOF（返回0）。如果`pipe->readers`变为0，说明不会再有数据读取。调用`wakeup(&pipe->write_wait)`唤醒所有等待写入的进程，让它们能够收到`SIGPIPE`信号。
5. **销毁管道**：如果`pipe->readers`和`pipe->writers`都变为0，说明管道不再被任何进程使用。此时，释放`pipe->lock`，然后释放`struct pipe`实例占用的内存。
6. 否则，仅释放`pipe->lock`。
7. 执行`struct file`的常规关闭操作。
8. 返回0。

#### 四、同步与互斥策略

管道机制的核心挑战在于处理多个进程对共享缓冲区的并发访问。本设计通过结合**自旋锁**和**等待队列**，构建了一个高效且正确的同步互斥模型。

- **互斥（Mutual Exclusion）**：由`struct pipe`中的`lock`自旋锁保证。任何进程在访问或修改管道的任何共享状态（如`read_ptr`, `write_ptr`, `count`等）之前，必须先获取该锁。这确保了所有对管道元数据的操作都是原子的，防止了数据竞争和状态不一致的问题。

- **同步（Synchronization）**：由`read_wait`和`write_wait`两个等待队列实现，用于协调生产者（写进程）和消费者（读进程）之间的速度差异：
1. **“空则等待”**：当读进程发现管道为空时，它会释放CPU并在`read_wait`队列上睡眠，避免了无效的CPU空转（忙等）。

2. **“满则等待”**：当写进程发现管道已满时，它会在`write_wait`队列上睡眠，等待读进程消费数据以腾出空间。

3. **“写后唤醒”**：写进程写入数据后，会检查管道是否从“空”变为“非空”，如果是，则唤醒在`read_wait`上等待的读进程。

4. **“读后唤醒”**：读进程读取数据后，会检查管道是否从“满”变为“非满”，如果是，则唤醒在`write_wait`上等待的写进程。

## 扩展练习 Challenge2：完成基于“UNIX的软连接和硬连接机制”的设计方案

如果要在ucore里加入UNIX的软连接和硬连接机制，至少需要定义哪些数据结构和接口？（接口给出语义即可，不必具体实现。数据结构的设计应当给出一个（或多个）具体的C语言struct定义。在网络上查找相关的Linux资料和实现，请在实验报告中给出设计实现”UNIX的软连接和硬连接机制“的概要设方案，你的设计应当体现出对可能出现的同步互斥问题的处理。）

### 解答

#### 一、UNIX软连接和硬连接机制概述

在UNIX及类UNIX操作系统中，链接（Link）是文件系统提供的一种重要机制，它允许为一个文件创建多个访问路径。链接主要分为两种：硬链接（Hard Link）和软链接（Soft Link），也称为符号链接（Symbolic Link）。

- **硬链接（Hard Link）**：硬链接本质上是一个文件的多个目录项（dentry），它们都指向同一个索引节点（inode）。由于所有硬链接共享同一个inode，因此它们也共享文件的所有属性，包括文件大小、权限、修改时间以及最重要的——文件数据块。创建硬链接并不会复制文件内容，而仅仅是在文件系统的目录结构中增加了一个新条目，并增加了inode的引用计数（link count）。只有当一个文件的所有硬链接都被删除（即引用计数降为0）后，文件系统才会真正释放其占用的磁盘空间（inode和数据块）。硬链接有一个重要限制：它不能跨文件系统创建，也不能指向目录。

- **软链接（Soft Link / Symbolic Link）**：软链接与硬链接在本质上完全不同。它本身是一个独立的文件，拥有自己的inode和数据块。软链接文件的特殊之处在于，其数据块中存储的内容并不是文件数据，而是另一个文件或目录的**路径名**。当操作系统访问一个软链接时，它会自动解析这个路径名，并将操作重定向到目标文件。由于软链接是一个独立的文件，它有自己的权限和属性，并且可以指向文件系统中的任何位置，包括跨文件系统的文件或目录。如果原始文件被删除，软链接并不会随之消失，而是会变成一个“悬空链接”（dangling link），此时访问它会导致“文件不存在”的错误。

#### 二、数据结构设计

##### 1. 索引节点结构体 `struct inode` 的增强

为了支持链接机制，ucore现有的`struct inode`需要进行扩展，主要是为了支持硬链接的引用计数和识别软链接文件。

```c
#include <spinlock.h>
#include <types.h>
enum inode_type {
IT_FILE, // 普通文件
IT_DIR, // 目录
IT_SYMLINK, // 软链接
// 其他类型
};
// ucore的inode结构体，需要进行如下修改
struct inode {
// ... 已有的成员
enum inode_type i_type; // 新增：文件类型，用于区分普通文件、目录和软链接
unsigned int i_nlink; // 新增/复用：硬链接引用计数。对于硬链接，此值>1。
// 当此值降为0时，文件被真正删除。
struct spinlock i_lock; // 新增：inode自旋锁，用于保护对inode成员（特别是i_nlink）的并发修改。
// ... 其他成员
};
```

**解释说明：**

- `i_type`：这是区分文件类型的关键。当一个inode的`i_type`被设置为`IT_SYMLINK`时，VFS层在进行路径解析时就知道需要执行软链接的跳转逻辑。

- `i_nlink`：这是实现硬链接的核心。每当创建一个硬链接，内核就会找到目标文件的inode，并将其`i_nlink`加1。每当删除一个硬链接（或文件），内核就会将对应inode的`i_nlink`减1。只有当`i_nlink`变为0时，才意味着没有任何目录项指向该inode，此时内核可以安全地回收该inode及其关联的数据块。

- `i_lock`：这是一个至关重要的同步机制。在多进程环境下，对同一个inode的`i_nlink`等成员的修改必须是原子的。`i_lock`确保了在任何时刻只有一个进程能够修改inode的状态，防止了竞争条件的发生。

##### 2. 软链接文件内容的存储

软链接本身是一个文件，其内容是目标文件的路径名。这个路径名可以像普通文件的数据一样存储在磁盘块中。因此，不需要为软链接设计全新的数据结构，而是复用现有的文件数据块管理机制。当`i_type`为`IT_SYMLINK`时，`i_size`字段将记录目标路径名的长度，而文件的数据块则存储路径名字符串本身。
**解释说明：**

- 这种设计使得软链接的实现非常简洁。创建软链接就像创建一个小文件，只是其内容是一个路径字符串，并且inode类型被标记为`IT_SYMLINK`。

- 读取软链接的内容（即读取目标路径）可以通过普通的`read`系统调用来完成。

#### 三、核心接口设计

##### 1. `int link(const char *oldpath, const char *newpath)`

- **接口语义**：为已存在的文件`oldpath`创建一个新的硬链接`newpath`。成功时返回0，失败时返回-1并设置错误码。

- **设计实现**：
1. 解析路径`oldpath`，找到其对应的`struct inode`（记为`old_inode`）。
2. 检查`old_inode`是否为目录。如果是，则返回错误（`EPERM`），因为不允许为目录创建硬链接。
3. 解析路径`newpath`的父目录，找到其父目录的`inode`（记为`dir_inode`）。
4. 检查`old_inode`和`dir_inode`是否位于同一个文件系统。如果不是，则返回错误（`EXDEV`），因为硬链接不能跨文件系统。
5. **同步与互斥**：持有`old_inode->i_lock`锁 -> 将`old_inode->i_nlink`加1 -> 释放`old_inode->i_lock`锁。
6. 在`dir_inode`对应的目录中，创建一个新的目录项（dentry），名称为`newpath`的最后一部分，inode号指向`old_inode->i_ino`。
7. 更新`dir_inode`的元数据（如修改时间）并将其写回磁盘。
8. 返回0表示成功。

##### 2. `int symlink(const char *target, const char *linkpath)`

- **接口语义**：创建一个名为`linkpath`的软链接文件，其内容指向`target`路径。成功时返回0，失败时返回-1。

- **设计实现**：
1. 解析路径`linkpath`的父目录，找到其父目录的`inode`（记为`dir_inode`）。

2. 在`dir_inode`对应的目录中，创建一个新的`inode`（记为`link_inode`）。

3. 设置`link_inode`的属性：
- `i_type` = `IT_SYMLINK`。

- `i_nlink` = 1（因为它本身是一个独立的文件）。

- `i_size` = `strlen(target)`。
  
   4.将`target`字符串写入`link_inode`的数据块中。
  
   5.在`dir_inode`对应的目录中，创建一个新的目录项，名称为`linkpath`的最后一部分，    inode号指向`link_inode->i_ino`。
  
   6.更新`dir_inode`和`link_inode`的元数据并写回磁盘。
  
   7.返回0表示成功。

##### 3. `int unlink(const char *pathname)`

- **接口语义**：删除一个文件或链接。如果`pathname`是一个硬链接，则减少对应inode的引用计数；如果引用计数变为0，则删除文件。如果`pathname`是一个软链接，则删除软链接文件本身。成功时返回0，失败时返回-1。

- **设计实现**：
1. 解析路径`pathname`，找到其对应的目录项（dentry）和`inode`（记为`inode_to_del`）。

2. 从其父目录中移除该目录项。

3. **同步与互斥**：
- 持有`inode_to_del->i_lock`锁。

- 将`inode_to_del->i_nlink`减1。

- **判断是否删除文件**：如果`inode_to_del->i_nlink` == 0：释放`inode_to_del`所占用的所有数据块。将`inode_to_del`标记为空闲，以便被文件系统回收。

- 释放`inode_to_del->i_lock`锁。
  
   4.更新父目录的元数据并写回磁盘。
  
   5.返回0表示成功。

##### 4. VFS路径解析逻辑的修改

为了实现软链接的自动跳转，ucore的VFS路径解析函数（如`lookup_path`）需要增加处理软链接的逻辑。

- **接口语义**：在路径解析过程中，如果遇到类型为`IT_SYMLINK`的inode，需要将当前解析路径替换为软链接指向的目标路径，然后继续解析。

- **设计实现**：
1. 在路径解析的循环中，每解析一个路径分量并找到对应的`inode`后，检查其`i_type`。

2. 如果`i_type`是`IT_SYMLINK`：
- 读取该`inode`的数据块，获取目标路径字符串`target`。

- 如果`target`是绝对路径，则重置当前解析路径为`target`。

- 如果`target`是相对路径，则将其与当前解析的父路径拼接，形成新的解析路径。

- **防止循环**：维护一个跳转深度计数器。如果跳转次数超过一个预设的最大值（如40），则返回错误（`ELOOP`），以防止因循环链接导致的无限递归。

- 重新开始解析新的路径。
  
   3.如果`i_type`不是软链接，则继续解析下一个路径分量。

#### 四、同步与互斥策略

链接机制的实现必须考虑多进程并发访问的问题，以保证文件系统的一致性。

**Inode级别的互斥**：

- **保护引用计数**：对`inode->i_nlink`的任何增减操作都必须在持有`inode->i_lock`的情况下进行。这防止了两个进程同时创建或删除硬链接时，导致引用计数计算错误，从而引发文件被错误地提前删除或永久残留。
- **保护元数据**：`i_lock`也用于保护`i_size`、`i_atime`等其他元数据的并发修改。

**目录级别的互斥**：

- 在创建（`link`, `symlink`）或删除（`unlink`）目录项时，必须对父目录的`inode`加锁。这确保了目录文件本身（存储目录项列表的文件）在被修改时不会被其他进程同时修改，从而避免了目录结构的损坏。

**软链接解析的同步**：

- 软链接的解析过程主要是读取操作，本身不涉及修改，因此通常不需要加锁。
- 但存在一种竞态条件：在解析软链接`A`（指向`B`）的过程中，文件`B`被另一个进程删除。这种情况属于正常的并发行为，内核只需要正确地将解析结果报告为“文件不存在”（`ENOENT`）即可，无需特殊的同步机制。

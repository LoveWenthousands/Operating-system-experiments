
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200024:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200028:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002c:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200030:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200034:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200038:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc020003c:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200040:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200044:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200048:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc020004c:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004e:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200052:	05828293          	addi	t0,t0,88 # ffffffffc0200058 <kern_init>
    jr t0
ffffffffc0200056:	8282                	jr	t0

ffffffffc0200058 <kern_init>:
void grade_backtrace(void);

int kern_init(void) {
    extern char edata[], end[];
    // 先清零 BSS，再读取并保存 DTB 的内存信息，避免被清零覆盖（为了解释变化 正式上传时我觉得应该删去这句话）
    memset(edata, 0, end - edata);
ffffffffc0200058:	00006517          	auipc	a0,0x6
ffffffffc020005c:	fd050513          	addi	a0,a0,-48 # ffffffffc0206028 <edata>
ffffffffc0200060:	00006617          	auipc	a2,0x6
ffffffffc0200064:	44060613          	addi	a2,a2,1088 # ffffffffc02064a0 <end>
int kern_init(void) {
ffffffffc0200068:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc020006a:	8e09                	sub	a2,a2,a0
ffffffffc020006c:	4581                	li	a1,0
int kern_init(void) {
ffffffffc020006e:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200070:	711010ef          	jal	ra,ffffffffc0201f80 <memset>
    dtb_init();
ffffffffc0200074:	470000ef          	jal	ra,ffffffffc02004e4 <dtb_init>
    cons_init();  // init the console
ffffffffc0200078:	3f8000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc020007c:	00002517          	auipc	a0,0x2
ffffffffc0200080:	f1c50513          	addi	a0,a0,-228 # ffffffffc0201f98 <etext+0x6>
ffffffffc0200084:	08e000ef          	jal	ra,ffffffffc0200112 <cputs>

    print_kerninfo();
ffffffffc0200088:	0da000ef          	jal	ra,ffffffffc0200162 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc020008c:	762000ef          	jal	ra,ffffffffc02007ee <idt_init>

    pmm_init();  // init physical memory management
ffffffffc0200090:	718010ef          	jal	ra,ffffffffc02017a8 <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200094:	75a000ef          	jal	ra,ffffffffc02007ee <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200098:	396000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc020009c:	746000ef          	jal	ra,ffffffffc02007e2 <intr_enable>

    /* do nothing */
    while (1)
        ;
ffffffffc02000a0:	a001                	j	ffffffffc02000a0 <kern_init+0x48>

ffffffffc02000a2 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000a2:	1141                	addi	sp,sp,-16
ffffffffc02000a4:	e022                	sd	s0,0(sp)
ffffffffc02000a6:	e406                	sd	ra,8(sp)
ffffffffc02000a8:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000aa:	3c8000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc02000ae:	401c                	lw	a5,0(s0)
}
ffffffffc02000b0:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000b2:	2785                	addiw	a5,a5,1
ffffffffc02000b4:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b6:	6402                	ld	s0,0(sp)
ffffffffc02000b8:	0141                	addi	sp,sp,16
ffffffffc02000ba:	8082                	ret

ffffffffc02000bc <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000bc:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	86ae                	mv	a3,a1
ffffffffc02000c0:	862a                	mv	a2,a0
ffffffffc02000c2:	006c                	addi	a1,sp,12
ffffffffc02000c4:	00000517          	auipc	a0,0x0
ffffffffc02000c8:	fde50513          	addi	a0,a0,-34 # ffffffffc02000a2 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000cc:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ce:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000d0:	139010ef          	jal	ra,ffffffffc0201a08 <vprintfmt>
    return cnt;
}
ffffffffc02000d4:	60e2                	ld	ra,24(sp)
ffffffffc02000d6:	4532                	lw	a0,12(sp)
ffffffffc02000d8:	6105                	addi	sp,sp,32
ffffffffc02000da:	8082                	ret

ffffffffc02000dc <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000dc:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000de:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000e2:	f42e                	sd	a1,40(sp)
ffffffffc02000e4:	f832                	sd	a2,48(sp)
ffffffffc02000e6:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e8:	862a                	mv	a2,a0
ffffffffc02000ea:	004c                	addi	a1,sp,4
ffffffffc02000ec:	00000517          	auipc	a0,0x0
ffffffffc02000f0:	fb650513          	addi	a0,a0,-74 # ffffffffc02000a2 <cputch>
ffffffffc02000f4:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02000f6:	ec06                	sd	ra,24(sp)
ffffffffc02000f8:	e0ba                	sd	a4,64(sp)
ffffffffc02000fa:	e4be                	sd	a5,72(sp)
ffffffffc02000fc:	e8c2                	sd	a6,80(sp)
ffffffffc02000fe:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200100:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200102:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200104:	105010ef          	jal	ra,ffffffffc0201a08 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200108:	60e2                	ld	ra,24(sp)
ffffffffc020010a:	4512                	lw	a0,4(sp)
ffffffffc020010c:	6125                	addi	sp,sp,96
ffffffffc020010e:	8082                	ret

ffffffffc0200110 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc0200110:	a68d                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200112 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200112:	1101                	addi	sp,sp,-32
ffffffffc0200114:	e822                	sd	s0,16(sp)
ffffffffc0200116:	ec06                	sd	ra,24(sp)
ffffffffc0200118:	e426                	sd	s1,8(sp)
ffffffffc020011a:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011c:	00054503          	lbu	a0,0(a0)
ffffffffc0200120:	c51d                	beqz	a0,ffffffffc020014e <cputs+0x3c>
ffffffffc0200122:	0405                	addi	s0,s0,1
ffffffffc0200124:	4485                	li	s1,1
ffffffffc0200126:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200128:	34a000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc020012c:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc0200130:	0405                	addi	s0,s0,1
ffffffffc0200132:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200136:	f96d                	bnez	a0,ffffffffc0200128 <cputs+0x16>
ffffffffc0200138:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013c:	4529                	li	a0,10
ffffffffc020013e:	334000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	60e2                	ld	ra,24(sp)
ffffffffc0200146:	6442                	ld	s0,16(sp)
ffffffffc0200148:	64a2                	ld	s1,8(sp)
ffffffffc020014a:	6105                	addi	sp,sp,32
ffffffffc020014c:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014e:	4405                	li	s0,1
ffffffffc0200150:	b7f5                	j	ffffffffc020013c <cputs+0x2a>

ffffffffc0200152 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200152:	1141                	addi	sp,sp,-16
ffffffffc0200154:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200156:	324000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc020015a:	dd75                	beqz	a0,ffffffffc0200156 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015c:	60a2                	ld	ra,8(sp)
ffffffffc020015e:	0141                	addi	sp,sp,16
ffffffffc0200160:	8082                	ret

ffffffffc0200162 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200162:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200164:	00002517          	auipc	a0,0x2
ffffffffc0200168:	e8450513          	addi	a0,a0,-380 # ffffffffc0201fe8 <etext+0x56>
void print_kerninfo(void) {
ffffffffc020016c:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016e:	f6fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200172:	00000597          	auipc	a1,0x0
ffffffffc0200176:	ee658593          	addi	a1,a1,-282 # ffffffffc0200058 <kern_init>
ffffffffc020017a:	00002517          	auipc	a0,0x2
ffffffffc020017e:	e8e50513          	addi	a0,a0,-370 # ffffffffc0202008 <etext+0x76>
ffffffffc0200182:	f5bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200186:	00002597          	auipc	a1,0x2
ffffffffc020018a:	e0c58593          	addi	a1,a1,-500 # ffffffffc0201f92 <etext>
ffffffffc020018e:	00002517          	auipc	a0,0x2
ffffffffc0200192:	e9a50513          	addi	a0,a0,-358 # ffffffffc0202028 <etext+0x96>
ffffffffc0200196:	f47ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc020019a:	00006597          	auipc	a1,0x6
ffffffffc020019e:	e8e58593          	addi	a1,a1,-370 # ffffffffc0206028 <edata>
ffffffffc02001a2:	00002517          	auipc	a0,0x2
ffffffffc02001a6:	ea650513          	addi	a0,a0,-346 # ffffffffc0202048 <etext+0xb6>
ffffffffc02001aa:	f33ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ae:	00006597          	auipc	a1,0x6
ffffffffc02001b2:	2f258593          	addi	a1,a1,754 # ffffffffc02064a0 <end>
ffffffffc02001b6:	00002517          	auipc	a0,0x2
ffffffffc02001ba:	eb250513          	addi	a0,a0,-334 # ffffffffc0202068 <etext+0xd6>
ffffffffc02001be:	f1fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c2:	00006597          	auipc	a1,0x6
ffffffffc02001c6:	6dd58593          	addi	a1,a1,1757 # ffffffffc020689f <end+0x3ff>
ffffffffc02001ca:	00000797          	auipc	a5,0x0
ffffffffc02001ce:	e8e78793          	addi	a5,a5,-370 # ffffffffc0200058 <kern_init>
ffffffffc02001d2:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d6:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001da:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001dc:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001e0:	95be                	add	a1,a1,a5
ffffffffc02001e2:	85a9                	srai	a1,a1,0xa
ffffffffc02001e4:	00002517          	auipc	a0,0x2
ffffffffc02001e8:	ea450513          	addi	a0,a0,-348 # ffffffffc0202088 <etext+0xf6>
}
ffffffffc02001ec:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ee:	b5fd                	j	ffffffffc02000dc <cprintf>

ffffffffc02001f0 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001f0:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02001f2:	00002617          	auipc	a2,0x2
ffffffffc02001f6:	dc660613          	addi	a2,a2,-570 # ffffffffc0201fb8 <etext+0x26>
ffffffffc02001fa:	04d00593          	li	a1,77
ffffffffc02001fe:	00002517          	auipc	a0,0x2
ffffffffc0200202:	dd250513          	addi	a0,a0,-558 # ffffffffc0201fd0 <etext+0x3e>
void print_stackframe(void) {
ffffffffc0200206:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200208:	1c6000ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc020020c <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020c:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020e:	00002617          	auipc	a2,0x2
ffffffffc0200212:	f8a60613          	addi	a2,a2,-118 # ffffffffc0202198 <commands+0xe0>
ffffffffc0200216:	00002597          	auipc	a1,0x2
ffffffffc020021a:	fa258593          	addi	a1,a1,-94 # ffffffffc02021b8 <commands+0x100>
ffffffffc020021e:	00002517          	auipc	a0,0x2
ffffffffc0200222:	fa250513          	addi	a0,a0,-94 # ffffffffc02021c0 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200226:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200228:	eb5ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc020022c:	00002617          	auipc	a2,0x2
ffffffffc0200230:	fa460613          	addi	a2,a2,-92 # ffffffffc02021d0 <commands+0x118>
ffffffffc0200234:	00002597          	auipc	a1,0x2
ffffffffc0200238:	fc458593          	addi	a1,a1,-60 # ffffffffc02021f8 <commands+0x140>
ffffffffc020023c:	00002517          	auipc	a0,0x2
ffffffffc0200240:	f8450513          	addi	a0,a0,-124 # ffffffffc02021c0 <commands+0x108>
ffffffffc0200244:	e99ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc0200248:	00002617          	auipc	a2,0x2
ffffffffc020024c:	fc060613          	addi	a2,a2,-64 # ffffffffc0202208 <commands+0x150>
ffffffffc0200250:	00002597          	auipc	a1,0x2
ffffffffc0200254:	fd858593          	addi	a1,a1,-40 # ffffffffc0202228 <commands+0x170>
ffffffffc0200258:	00002517          	auipc	a0,0x2
ffffffffc020025c:	f6850513          	addi	a0,a0,-152 # ffffffffc02021c0 <commands+0x108>
ffffffffc0200260:	e7dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    }
    return 0;
}
ffffffffc0200264:	60a2                	ld	ra,8(sp)
ffffffffc0200266:	4501                	li	a0,0
ffffffffc0200268:	0141                	addi	sp,sp,16
ffffffffc020026a:	8082                	ret

ffffffffc020026c <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026c:	1141                	addi	sp,sp,-16
ffffffffc020026e:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200270:	ef3ff0ef          	jal	ra,ffffffffc0200162 <print_kerninfo>
    return 0;
}
ffffffffc0200274:	60a2                	ld	ra,8(sp)
ffffffffc0200276:	4501                	li	a0,0
ffffffffc0200278:	0141                	addi	sp,sp,16
ffffffffc020027a:	8082                	ret

ffffffffc020027c <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027c:	1141                	addi	sp,sp,-16
ffffffffc020027e:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200280:	f71ff0ef          	jal	ra,ffffffffc02001f0 <print_stackframe>
    return 0;
}
ffffffffc0200284:	60a2                	ld	ra,8(sp)
ffffffffc0200286:	4501                	li	a0,0
ffffffffc0200288:	0141                	addi	sp,sp,16
ffffffffc020028a:	8082                	ret

ffffffffc020028c <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028c:	7115                	addi	sp,sp,-224
ffffffffc020028e:	e962                	sd	s8,144(sp)
ffffffffc0200290:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200292:	00002517          	auipc	a0,0x2
ffffffffc0200296:	e6e50513          	addi	a0,a0,-402 # ffffffffc0202100 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc020029a:	ed86                	sd	ra,216(sp)
ffffffffc020029c:	e9a2                	sd	s0,208(sp)
ffffffffc020029e:	e5a6                	sd	s1,200(sp)
ffffffffc02002a0:	e1ca                	sd	s2,192(sp)
ffffffffc02002a2:	fd4e                	sd	s3,184(sp)
ffffffffc02002a4:	f952                	sd	s4,176(sp)
ffffffffc02002a6:	f556                	sd	s5,168(sp)
ffffffffc02002a8:	f15a                	sd	s6,160(sp)
ffffffffc02002aa:	ed5e                	sd	s7,152(sp)
ffffffffc02002ac:	e566                	sd	s9,136(sp)
ffffffffc02002ae:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002b0:	e2dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b4:	00002517          	auipc	a0,0x2
ffffffffc02002b8:	e7450513          	addi	a0,a0,-396 # ffffffffc0202128 <commands+0x70>
ffffffffc02002bc:	e21ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    if (tf != NULL) {
ffffffffc02002c0:	000c0563          	beqz	s8,ffffffffc02002ca <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c4:	8562                	mv	a0,s8
ffffffffc02002c6:	708000ef          	jal	ra,ffffffffc02009ce <print_trapframe>
ffffffffc02002ca:	00002c97          	auipc	s9,0x2
ffffffffc02002ce:	deec8c93          	addi	s9,s9,-530 # ffffffffc02020b8 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d2:	00002997          	auipc	s3,0x2
ffffffffc02002d6:	e7e98993          	addi	s3,s3,-386 # ffffffffc0202150 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002da:	00002917          	auipc	s2,0x2
ffffffffc02002de:	e7e90913          	addi	s2,s2,-386 # ffffffffc0202158 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc02002e2:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e4:	00002b17          	auipc	s6,0x2
ffffffffc02002e8:	e7cb0b13          	addi	s6,s6,-388 # ffffffffc0202160 <commands+0xa8>
    if (argc == 0) {
ffffffffc02002ec:	00002a97          	auipc	s5,0x2
ffffffffc02002f0:	ecca8a93          	addi	s5,s5,-308 # ffffffffc02021b8 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f4:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f6:	854e                	mv	a0,s3
ffffffffc02002f8:	291010ef          	jal	ra,ffffffffc0201d88 <readline>
ffffffffc02002fc:	842a                	mv	s0,a0
ffffffffc02002fe:	dd65                	beqz	a0,ffffffffc02002f6 <kmonitor+0x6a>
ffffffffc0200300:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200304:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200306:	c999                	beqz	a1,ffffffffc020031c <kmonitor+0x90>
ffffffffc0200308:	854a                	mv	a0,s2
ffffffffc020030a:	459010ef          	jal	ra,ffffffffc0201f62 <strchr>
ffffffffc020030e:	c925                	beqz	a0,ffffffffc020037e <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc0200310:	00144583          	lbu	a1,1(s0)
ffffffffc0200314:	00040023          	sb	zero,0(s0)
ffffffffc0200318:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020031a:	f5fd                	bnez	a1,ffffffffc0200308 <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc020031c:	dce9                	beqz	s1,ffffffffc02002f6 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031e:	6582                	ld	a1,0(sp)
ffffffffc0200320:	00002d17          	auipc	s10,0x2
ffffffffc0200324:	d98d0d13          	addi	s10,s10,-616 # ffffffffc02020b8 <commands>
    if (argc == 0) {
ffffffffc0200328:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032a:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
ffffffffc020032e:	3cf010ef          	jal	ra,ffffffffc0201efc <strcmp>
ffffffffc0200332:	c919                	beqz	a0,ffffffffc0200348 <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200334:	2405                	addiw	s0,s0,1
ffffffffc0200336:	09740463          	beq	s0,s7,ffffffffc02003be <kmonitor+0x132>
ffffffffc020033a:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020033e:	6582                	ld	a1,0(sp)
ffffffffc0200340:	0d61                	addi	s10,s10,24
ffffffffc0200342:	3bb010ef          	jal	ra,ffffffffc0201efc <strcmp>
ffffffffc0200346:	f57d                	bnez	a0,ffffffffc0200334 <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200348:	00141793          	slli	a5,s0,0x1
ffffffffc020034c:	97a2                	add	a5,a5,s0
ffffffffc020034e:	078e                	slli	a5,a5,0x3
ffffffffc0200350:	97e6                	add	a5,a5,s9
ffffffffc0200352:	6b9c                	ld	a5,16(a5)
ffffffffc0200354:	8662                	mv	a2,s8
ffffffffc0200356:	002c                	addi	a1,sp,8
ffffffffc0200358:	fff4851b          	addiw	a0,s1,-1
ffffffffc020035c:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020035e:	f8055ce3          	bgez	a0,ffffffffc02002f6 <kmonitor+0x6a>
}
ffffffffc0200362:	60ee                	ld	ra,216(sp)
ffffffffc0200364:	644e                	ld	s0,208(sp)
ffffffffc0200366:	64ae                	ld	s1,200(sp)
ffffffffc0200368:	690e                	ld	s2,192(sp)
ffffffffc020036a:	79ea                	ld	s3,184(sp)
ffffffffc020036c:	7a4a                	ld	s4,176(sp)
ffffffffc020036e:	7aaa                	ld	s5,168(sp)
ffffffffc0200370:	7b0a                	ld	s6,160(sp)
ffffffffc0200372:	6bea                	ld	s7,152(sp)
ffffffffc0200374:	6c4a                	ld	s8,144(sp)
ffffffffc0200376:	6caa                	ld	s9,136(sp)
ffffffffc0200378:	6d0a                	ld	s10,128(sp)
ffffffffc020037a:	612d                	addi	sp,sp,224
ffffffffc020037c:	8082                	ret
        if (*buf == '\0') {
ffffffffc020037e:	00044783          	lbu	a5,0(s0)
ffffffffc0200382:	dfc9                	beqz	a5,ffffffffc020031c <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc0200384:	03448863          	beq	s1,s4,ffffffffc02003b4 <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc0200388:	00349793          	slli	a5,s1,0x3
ffffffffc020038c:	0118                	addi	a4,sp,128
ffffffffc020038e:	97ba                	add	a5,a5,a4
ffffffffc0200390:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200394:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc0200398:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039a:	e591                	bnez	a1,ffffffffc02003a6 <kmonitor+0x11a>
ffffffffc020039c:	b749                	j	ffffffffc020031e <kmonitor+0x92>
            buf ++;
ffffffffc020039e:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a0:	00044583          	lbu	a1,0(s0)
ffffffffc02003a4:	ddad                	beqz	a1,ffffffffc020031e <kmonitor+0x92>
ffffffffc02003a6:	854a                	mv	a0,s2
ffffffffc02003a8:	3bb010ef          	jal	ra,ffffffffc0201f62 <strchr>
ffffffffc02003ac:	d96d                	beqz	a0,ffffffffc020039e <kmonitor+0x112>
ffffffffc02003ae:	00044583          	lbu	a1,0(s0)
ffffffffc02003b2:	bf91                	j	ffffffffc0200306 <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b4:	45c1                	li	a1,16
ffffffffc02003b6:	855a                	mv	a0,s6
ffffffffc02003b8:	d25ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
ffffffffc02003bc:	b7f1                	j	ffffffffc0200388 <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003be:	6582                	ld	a1,0(sp)
ffffffffc02003c0:	00002517          	auipc	a0,0x2
ffffffffc02003c4:	dc050513          	addi	a0,a0,-576 # ffffffffc0202180 <commands+0xc8>
ffffffffc02003c8:	d15ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    return 0;
ffffffffc02003cc:	b72d                	j	ffffffffc02002f6 <kmonitor+0x6a>

ffffffffc02003ce <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003ce:	00006317          	auipc	t1,0x6
ffffffffc02003d2:	07230313          	addi	t1,t1,114 # ffffffffc0206440 <is_panic>
ffffffffc02003d6:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003da:	715d                	addi	sp,sp,-80
ffffffffc02003dc:	ec06                	sd	ra,24(sp)
ffffffffc02003de:	e822                	sd	s0,16(sp)
ffffffffc02003e0:	f436                	sd	a3,40(sp)
ffffffffc02003e2:	f83a                	sd	a4,48(sp)
ffffffffc02003e4:	fc3e                	sd	a5,56(sp)
ffffffffc02003e6:	e0c2                	sd	a6,64(sp)
ffffffffc02003e8:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ea:	02031c63          	bnez	t1,ffffffffc0200422 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003ee:	4785                	li	a5,1
ffffffffc02003f0:	8432                	mv	s0,a2
ffffffffc02003f2:	00006717          	auipc	a4,0x6
ffffffffc02003f6:	04f72723          	sw	a5,78(a4) # ffffffffc0206440 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fa:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02003fc:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	e3850513          	addi	a0,a0,-456 # ffffffffc0202238 <commands+0x180>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	cd3ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	cabff0ef          	jal	ra,ffffffffc02000bc <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00002517          	auipc	a0,0x2
ffffffffc020041a:	c9a50513          	addi	a0,a0,-870 # ffffffffc02020b0 <etext+0x11e>
ffffffffc020041e:	cbfff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	3c6000ef          	jal	ra,ffffffffc02007e8 <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e65ff0ef          	jal	ra,ffffffffc020028c <kmonitor>
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x58>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	21d010ef          	jal	ra,ffffffffc0201e62 <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	0207b623          	sd	zero,44(a5) # ffffffffc0206478 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	e0450513          	addi	a0,a0,-508 # ffffffffc0202258 <commands+0x1a0>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9bd                	j	ffffffffc02000dc <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <BASE_ADDRESS-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	1f70106f          	j	ffffffffc0201e62 <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	andi	a0,a0,255
ffffffffc0200476:	1d10106f          	j	ffffffffc0201e46 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	2050106f          	j	ffffffffc0201e7e <sbi_console_getchar>

ffffffffc020047e <fdt64_to_cpu>:
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
}

static uint64_t fdt64_to_cpu(uint64_t x) {
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020047e:	0005069b          	sext.w	a3,a0
           fdt32_to_cpu(x >> 32);
ffffffffc0200482:	9501                	srai	a0,a0,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200484:	0085579b          	srliw	a5,a0,0x8
ffffffffc0200488:	00ff08b7          	lui	a7,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048c:	0185531b          	srliw	t1,a0,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200490:	0086d71b          	srliw	a4,a3,0x8
ffffffffc0200494:	0185159b          	slliw	a1,a0,0x18
ffffffffc0200498:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049c:	0105551b          	srliw	a0,a0,0x10
ffffffffc02004a0:	6641                	lui	a2,0x10
ffffffffc02004a2:	0186de1b          	srliw	t3,a3,0x18
ffffffffc02004a6:	167d                	addi	a2,a2,-1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004a8:	0186981b          	slliw	a6,a3,0x18
ffffffffc02004ac:	0117f7b3          	and	a5,a5,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b0:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004b4:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004b8:	0106d69b          	srliw	a3,a3,0x10
ffffffffc02004bc:	0085151b          	slliw	a0,a0,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004c0:	01177733          	and	a4,a4,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004c4:	01c86833          	or	a6,a6,t3
ffffffffc02004c8:	8fcd                	or	a5,a5,a1
ffffffffc02004ca:	8d71                	and	a0,a0,a2
ffffffffc02004cc:	0086969b          	slliw	a3,a3,0x8
ffffffffc02004d0:	01076733          	or	a4,a4,a6
ffffffffc02004d4:	8ef1                	and	a3,a3,a2
ffffffffc02004d6:	8d5d                	or	a0,a0,a5
ffffffffc02004d8:	8f55                	or	a4,a4,a3
           fdt32_to_cpu(x >> 32);
ffffffffc02004da:	1502                	slli	a0,a0,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc02004dc:	1702                	slli	a4,a4,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc02004de:	9101                	srli	a0,a0,0x20
}
ffffffffc02004e0:	8d59                	or	a0,a0,a4
ffffffffc02004e2:	8082                	ret

ffffffffc02004e4 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02004e4:	7159                	addi	sp,sp,-112
    cprintf("DTB Init\n");
ffffffffc02004e6:	00002517          	auipc	a0,0x2
ffffffffc02004ea:	d9250513          	addi	a0,a0,-622 # ffffffffc0202278 <commands+0x1c0>
void dtb_init(void) {
ffffffffc02004ee:	f486                	sd	ra,104(sp)
ffffffffc02004f0:	f0a2                	sd	s0,96(sp)
ffffffffc02004f2:	e4ce                	sd	s3,72(sp)
ffffffffc02004f4:	eca6                	sd	s1,88(sp)
ffffffffc02004f6:	e8ca                	sd	s2,80(sp)
ffffffffc02004f8:	e0d2                	sd	s4,64(sp)
ffffffffc02004fa:	fc56                	sd	s5,56(sp)
ffffffffc02004fc:	f85a                	sd	s6,48(sp)
ffffffffc02004fe:	f45e                	sd	s7,40(sp)
ffffffffc0200500:	f062                	sd	s8,32(sp)
ffffffffc0200502:	ec66                	sd	s9,24(sp)
ffffffffc0200504:	e86a                	sd	s10,16(sp)
ffffffffc0200506:	e46e                	sd	s11,8(sp)
    cprintf("DTB Init\n");
ffffffffc0200508:	bd5ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020050c:	00006797          	auipc	a5,0x6
ffffffffc0200510:	af478793          	addi	a5,a5,-1292 # ffffffffc0206000 <boot_hartid>
ffffffffc0200514:	638c                	ld	a1,0(a5)
ffffffffc0200516:	00002517          	auipc	a0,0x2
ffffffffc020051a:	d7250513          	addi	a0,a0,-654 # ffffffffc0202288 <commands+0x1d0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020051e:	00006417          	auipc	s0,0x6
ffffffffc0200522:	aea40413          	addi	s0,s0,-1302 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc0200526:	bb7ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc020052a:	600c                	ld	a1,0(s0)
ffffffffc020052c:	00002517          	auipc	a0,0x2
ffffffffc0200530:	d6c50513          	addi	a0,a0,-660 # ffffffffc0202298 <commands+0x1e0>
ffffffffc0200534:	ba9ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc0200538:	00043983          	ld	s3,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc020053c:	00002517          	auipc	a0,0x2
ffffffffc0200540:	d7450513          	addi	a0,a0,-652 # ffffffffc02022b0 <commands+0x1f8>
    if (boot_dtb == 0) {
ffffffffc0200544:	10098d63          	beqz	s3,ffffffffc020065e <dtb_init+0x17a>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200548:	57f5                	li	a5,-3
ffffffffc020054a:	07fa                	slli	a5,a5,0x1e
ffffffffc020054c:	00f98733          	add	a4,s3,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200550:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200552:	00ff0537          	lui	a0,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200556:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020055a:	0087d69b          	srliw	a3,a5,0x8
ffffffffc020055e:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200562:	8dd1                	or	a1,a1,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200564:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200568:	0107d79b          	srliw	a5,a5,0x10
ffffffffc020056c:	6641                	lui	a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020056e:	8ee9                	and	a3,a3,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200570:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200574:	167d                	addi	a2,a2,-1
ffffffffc0200576:	8dd5                	or	a1,a1,a3
ffffffffc0200578:	8ff1                	and	a5,a5,a2
ffffffffc020057a:	8fcd                	or	a5,a5,a1
ffffffffc020057c:	0007859b          	sext.w	a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200580:	d00e07b7          	lui	a5,0xd00e0
ffffffffc0200584:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9a4d>
ffffffffc0200588:	0ef59a63          	bne	a1,a5,ffffffffc020067c <dtb_init+0x198>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020058c:	471c                	lw	a5,8(a4)
ffffffffc020058e:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200590:	4b81                	li	s7,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200592:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200596:	0086d81b          	srliw	a6,a3,0x8
ffffffffc020059a:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020059e:	0186d31b          	srliw	t1,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005a2:	0187999b          	slliw	s3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005a6:	0187d89b          	srliw	a7,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005aa:	0108181b          	slliw	a6,a6,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005ae:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005b2:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005b6:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ba:	00a87833          	and	a6,a6,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005be:	00646433          	or	s0,s0,t1
ffffffffc02005c2:	0086969b          	slliw	a3,a3,0x8
ffffffffc02005c6:	0119e9b3          	or	s3,s3,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005ca:	8d6d                	and	a0,a0,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005cc:	0087979b          	slliw	a5,a5,0x8
ffffffffc02005d0:	01046433          	or	s0,s0,a6
ffffffffc02005d4:	8ef1                	and	a3,a3,a2
ffffffffc02005d6:	00a9e9b3          	or	s3,s3,a0
ffffffffc02005da:	8ff1                	and	a5,a5,a2
ffffffffc02005dc:	8c55                	or	s0,s0,a3
ffffffffc02005de:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005e2:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005e4:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005e6:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005e8:	0209d993          	srli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc02005ec:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc02005ee:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02005f0:	00ff0cb7          	lui	s9,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02005f4:	8b32                	mv	s6,a2
        switch (token) {
ffffffffc02005f6:	4c09                	li	s8,2
ffffffffc02005f8:	490d                	li	s2,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02005fa:	00002497          	auipc	s1,0x2
ffffffffc02005fe:	d0648493          	addi	s1,s1,-762 # ffffffffc0202300 <commands+0x248>
        switch (token) {
ffffffffc0200602:	4d91                	li	s11,4
ffffffffc0200604:	4d05                	li	s10,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200606:	0009a703          	lw	a4,0(s3)
ffffffffc020060a:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020060e:	0087579b          	srliw	a5,a4,0x8
ffffffffc0200612:	0187161b          	slliw	a2,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200616:	0187559b          	srliw	a1,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061a:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200622:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200626:	8e4d                	or	a2,a2,a1
ffffffffc0200628:	0087171b          	slliw	a4,a4,0x8
ffffffffc020062c:	8fd1                	or	a5,a5,a2
ffffffffc020062e:	01677733          	and	a4,a4,s6
ffffffffc0200632:	8fd9                	or	a5,a5,a4
ffffffffc0200634:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc0200636:	09878d63          	beq	a5,s8,ffffffffc02006d0 <dtb_init+0x1ec>
ffffffffc020063a:	06fc7463          	bgeu	s8,a5,ffffffffc02006a2 <dtb_init+0x1be>
ffffffffc020063e:	09278c63          	beq	a5,s2,ffffffffc02006d6 <dtb_init+0x1f2>
ffffffffc0200642:	01b79463          	bne	a5,s11,ffffffffc020064a <dtb_init+0x166>
                in_memory_node = 0;
ffffffffc0200646:	89d2                	mv	s3,s4
ffffffffc0200648:	bf7d                	j	ffffffffc0200606 <dtb_init+0x122>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc020064a:	00002517          	auipc	a0,0x2
ffffffffc020064e:	d2e50513          	addi	a0,a0,-722 # ffffffffc0202378 <commands+0x2c0>
ffffffffc0200652:	a8bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc0200656:	00002517          	auipc	a0,0x2
ffffffffc020065a:	d5a50513          	addi	a0,a0,-678 # ffffffffc02023b0 <commands+0x2f8>
}
ffffffffc020065e:	7406                	ld	s0,96(sp)
ffffffffc0200660:	70a6                	ld	ra,104(sp)
ffffffffc0200662:	64e6                	ld	s1,88(sp)
ffffffffc0200664:	6946                	ld	s2,80(sp)
ffffffffc0200666:	69a6                	ld	s3,72(sp)
ffffffffc0200668:	6a06                	ld	s4,64(sp)
ffffffffc020066a:	7ae2                	ld	s5,56(sp)
ffffffffc020066c:	7b42                	ld	s6,48(sp)
ffffffffc020066e:	7ba2                	ld	s7,40(sp)
ffffffffc0200670:	7c02                	ld	s8,32(sp)
ffffffffc0200672:	6ce2                	ld	s9,24(sp)
ffffffffc0200674:	6d42                	ld	s10,16(sp)
ffffffffc0200676:	6da2                	ld	s11,8(sp)
ffffffffc0200678:	6165                	addi	sp,sp,112
    cprintf("DTB init completed\n");
ffffffffc020067a:	b48d                	j	ffffffffc02000dc <cprintf>
}
ffffffffc020067c:	7406                	ld	s0,96(sp)
ffffffffc020067e:	70a6                	ld	ra,104(sp)
ffffffffc0200680:	64e6                	ld	s1,88(sp)
ffffffffc0200682:	6946                	ld	s2,80(sp)
ffffffffc0200684:	69a6                	ld	s3,72(sp)
ffffffffc0200686:	6a06                	ld	s4,64(sp)
ffffffffc0200688:	7ae2                	ld	s5,56(sp)
ffffffffc020068a:	7b42                	ld	s6,48(sp)
ffffffffc020068c:	7ba2                	ld	s7,40(sp)
ffffffffc020068e:	7c02                	ld	s8,32(sp)
ffffffffc0200690:	6ce2                	ld	s9,24(sp)
ffffffffc0200692:	6d42                	ld	s10,16(sp)
ffffffffc0200694:	6da2                	ld	s11,8(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	c3a50513          	addi	a0,a0,-966 # ffffffffc02022d0 <commands+0x218>
}
ffffffffc020069e:	6165                	addi	sp,sp,112
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc02006a0:	bc35                	j	ffffffffc02000dc <cprintf>
        switch (token) {
ffffffffc02006a2:	fba794e3          	bne	a5,s10,ffffffffc020064a <dtb_init+0x166>
                int name_len = strlen(name);
ffffffffc02006a6:	8552                	mv	a0,s4
ffffffffc02006a8:	011010ef          	jal	ra,ffffffffc0201eb8 <strlen>
ffffffffc02006ac:	0005099b          	sext.w	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc02006b0:	4619                	li	a2,6
ffffffffc02006b2:	00002597          	auipc	a1,0x2
ffffffffc02006b6:	c4658593          	addi	a1,a1,-954 # ffffffffc02022f8 <commands+0x240>
ffffffffc02006ba:	8552                	mv	a0,s4
ffffffffc02006bc:	06b010ef          	jal	ra,ffffffffc0201f26 <strncmp>
ffffffffc02006c0:	e111                	bnez	a0,ffffffffc02006c4 <dtb_init+0x1e0>
                    in_memory_node = 1;
ffffffffc02006c2:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc02006c4:	0a11                	addi	s4,s4,4
ffffffffc02006c6:	9a4e                	add	s4,s4,s3
ffffffffc02006c8:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc02006cc:	89d2                	mv	s3,s4
ffffffffc02006ce:	bf25                	j	ffffffffc0200606 <dtb_init+0x122>
ffffffffc02006d0:	4b81                	li	s7,0
ffffffffc02006d2:	89d2                	mv	s3,s4
ffffffffc02006d4:	bf0d                	j	ffffffffc0200606 <dtb_init+0x122>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006d6:	0049a783          	lw	a5,4(s3)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006da:	00c98a13          	addi	s4,s3,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006de:	0087da9b          	srliw	s5,a5,0x8
ffffffffc02006e2:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006e6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ea:	010a9a9b          	slliw	s5,s5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ee:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006f2:	019afab3          	and	s5,s5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006f6:	8f51                	or	a4,a4,a2
ffffffffc02006f8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02006fc:	00eaeab3          	or	s5,s5,a4
ffffffffc0200700:	0167f7b3          	and	a5,a5,s6
ffffffffc0200704:	00faeab3          	or	s5,s5,a5
ffffffffc0200708:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020070a:	000b9b63          	bnez	s7,ffffffffc0200720 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc020070e:	1a82                	slli	s5,s5,0x20
ffffffffc0200710:	0a0d                	addi	s4,s4,3
ffffffffc0200712:	020ada93          	srli	s5,s5,0x20
ffffffffc0200716:	9a56                	add	s4,s4,s5
ffffffffc0200718:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc020071c:	89d2                	mv	s3,s4
ffffffffc020071e:	b5e5                	j	ffffffffc0200606 <dtb_init+0x122>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200720:	0089a783          	lw	a5,8(s3)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200724:	85a6                	mv	a1,s1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0087d51b          	srliw	a0,a5,0x8
ffffffffc020072a:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200732:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200736:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020073a:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020073e:	8f51                	or	a4,a4,a2
ffffffffc0200740:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200744:	8d59                	or	a0,a0,a4
ffffffffc0200746:	0167f7b3          	and	a5,a5,s6
ffffffffc020074a:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc020074c:	1502                	slli	a0,a0,0x20
ffffffffc020074e:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200750:	9522                	add	a0,a0,s0
ffffffffc0200752:	7aa010ef          	jal	ra,ffffffffc0201efc <strcmp>
ffffffffc0200756:	fd45                	bnez	a0,ffffffffc020070e <dtb_init+0x22a>
ffffffffc0200758:	47bd                	li	a5,15
ffffffffc020075a:	fb57fae3          	bgeu	a5,s5,ffffffffc020070e <dtb_init+0x22a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc020075e:	00c9b503          	ld	a0,12(s3)
ffffffffc0200762:	d1dff0ef          	jal	ra,ffffffffc020047e <fdt64_to_cpu>
ffffffffc0200766:	84aa                	mv	s1,a0
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200768:	0149b503          	ld	a0,20(s3)
ffffffffc020076c:	d13ff0ef          	jal	ra,ffffffffc020047e <fdt64_to_cpu>
ffffffffc0200770:	842a                	mv	s0,a0
        cprintf("Physical Memory from DTB:\n");
ffffffffc0200772:	00002517          	auipc	a0,0x2
ffffffffc0200776:	b9650513          	addi	a0,a0,-1130 # ffffffffc0202308 <commands+0x250>
ffffffffc020077a:	963ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc020077e:	85a6                	mv	a1,s1
ffffffffc0200780:	00002517          	auipc	a0,0x2
ffffffffc0200784:	ba850513          	addi	a0,a0,-1112 # ffffffffc0202328 <commands+0x270>
ffffffffc0200788:	955ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc020078c:	01445613          	srli	a2,s0,0x14
ffffffffc0200790:	85a2                	mv	a1,s0
ffffffffc0200792:	00002517          	auipc	a0,0x2
ffffffffc0200796:	bae50513          	addi	a0,a0,-1106 # ffffffffc0202340 <commands+0x288>
ffffffffc020079a:	943ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc020079e:	008485b3          	add	a1,s1,s0
ffffffffc02007a2:	15fd                	addi	a1,a1,-1
ffffffffc02007a4:	00002517          	auipc	a0,0x2
ffffffffc02007a8:	bbc50513          	addi	a0,a0,-1092 # ffffffffc0202360 <commands+0x2a8>
ffffffffc02007ac:	931ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("DTB init completed\n");
ffffffffc02007b0:	00002517          	auipc	a0,0x2
ffffffffc02007b4:	c0050513          	addi	a0,a0,-1024 # ffffffffc02023b0 <commands+0x2f8>
        memory_base = mem_base;
ffffffffc02007b8:	00006797          	auipc	a5,0x6
ffffffffc02007bc:	c897b823          	sd	s1,-880(a5) # ffffffffc0206448 <memory_base>
        memory_size = mem_size;
ffffffffc02007c0:	00006797          	auipc	a5,0x6
ffffffffc02007c4:	c887b823          	sd	s0,-880(a5) # ffffffffc0206450 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc02007c8:	bd59                	j	ffffffffc020065e <dtb_init+0x17a>

ffffffffc02007ca <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
ffffffffc02007ca:	00006797          	auipc	a5,0x6
ffffffffc02007ce:	c7e78793          	addi	a5,a5,-898 # ffffffffc0206448 <memory_base>
}
ffffffffc02007d2:	6388                	ld	a0,0(a5)
ffffffffc02007d4:	8082                	ret

ffffffffc02007d6 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc02007d6:	00006797          	auipc	a5,0x6
ffffffffc02007da:	c7a78793          	addi	a5,a5,-902 # ffffffffc0206450 <memory_size>
}
ffffffffc02007de:	6388                	ld	a0,0(a5)
ffffffffc02007e0:	8082                	ret

ffffffffc02007e2 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007e2:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02007e6:	8082                	ret

ffffffffc02007e8 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02007e8:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02007ec:	8082                	ret

ffffffffc02007ee <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02007ee:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02007f2:	00000797          	auipc	a5,0x0
ffffffffc02007f6:	38a78793          	addi	a5,a5,906 # ffffffffc0200b7c <__alltraps>
ffffffffc02007fa:	10579073          	csrw	stvec,a5
}
ffffffffc02007fe:	8082                	ret

ffffffffc0200800 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200800:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc0200802:	1141                	addi	sp,sp,-16
ffffffffc0200804:	e022                	sd	s0,0(sp)
ffffffffc0200806:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200808:	00002517          	auipc	a0,0x2
ffffffffc020080c:	cf850513          	addi	a0,a0,-776 # ffffffffc0202500 <commands+0x448>
void print_regs(struct pushregs *gpr) {
ffffffffc0200810:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200812:	8cbff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200816:	640c                	ld	a1,8(s0)
ffffffffc0200818:	00002517          	auipc	a0,0x2
ffffffffc020081c:	d0050513          	addi	a0,a0,-768 # ffffffffc0202518 <commands+0x460>
ffffffffc0200820:	8bdff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc0200824:	680c                	ld	a1,16(s0)
ffffffffc0200826:	00002517          	auipc	a0,0x2
ffffffffc020082a:	d0a50513          	addi	a0,a0,-758 # ffffffffc0202530 <commands+0x478>
ffffffffc020082e:	8afff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200832:	6c0c                	ld	a1,24(s0)
ffffffffc0200834:	00002517          	auipc	a0,0x2
ffffffffc0200838:	d1450513          	addi	a0,a0,-748 # ffffffffc0202548 <commands+0x490>
ffffffffc020083c:	8a1ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200840:	700c                	ld	a1,32(s0)
ffffffffc0200842:	00002517          	auipc	a0,0x2
ffffffffc0200846:	d1e50513          	addi	a0,a0,-738 # ffffffffc0202560 <commands+0x4a8>
ffffffffc020084a:	893ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc020084e:	740c                	ld	a1,40(s0)
ffffffffc0200850:	00002517          	auipc	a0,0x2
ffffffffc0200854:	d2850513          	addi	a0,a0,-728 # ffffffffc0202578 <commands+0x4c0>
ffffffffc0200858:	885ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc020085c:	780c                	ld	a1,48(s0)
ffffffffc020085e:	00002517          	auipc	a0,0x2
ffffffffc0200862:	d3250513          	addi	a0,a0,-718 # ffffffffc0202590 <commands+0x4d8>
ffffffffc0200866:	877ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc020086a:	7c0c                	ld	a1,56(s0)
ffffffffc020086c:	00002517          	auipc	a0,0x2
ffffffffc0200870:	d3c50513          	addi	a0,a0,-708 # ffffffffc02025a8 <commands+0x4f0>
ffffffffc0200874:	869ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc0200878:	602c                	ld	a1,64(s0)
ffffffffc020087a:	00002517          	auipc	a0,0x2
ffffffffc020087e:	d4650513          	addi	a0,a0,-698 # ffffffffc02025c0 <commands+0x508>
ffffffffc0200882:	85bff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200886:	642c                	ld	a1,72(s0)
ffffffffc0200888:	00002517          	auipc	a0,0x2
ffffffffc020088c:	d5050513          	addi	a0,a0,-688 # ffffffffc02025d8 <commands+0x520>
ffffffffc0200890:	84dff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200894:	682c                	ld	a1,80(s0)
ffffffffc0200896:	00002517          	auipc	a0,0x2
ffffffffc020089a:	d5a50513          	addi	a0,a0,-678 # ffffffffc02025f0 <commands+0x538>
ffffffffc020089e:	83fff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02008a2:	6c2c                	ld	a1,88(s0)
ffffffffc02008a4:	00002517          	auipc	a0,0x2
ffffffffc02008a8:	d6450513          	addi	a0,a0,-668 # ffffffffc0202608 <commands+0x550>
ffffffffc02008ac:	831ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02008b0:	702c                	ld	a1,96(s0)
ffffffffc02008b2:	00002517          	auipc	a0,0x2
ffffffffc02008b6:	d6e50513          	addi	a0,a0,-658 # ffffffffc0202620 <commands+0x568>
ffffffffc02008ba:	823ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02008be:	742c                	ld	a1,104(s0)
ffffffffc02008c0:	00002517          	auipc	a0,0x2
ffffffffc02008c4:	d7850513          	addi	a0,a0,-648 # ffffffffc0202638 <commands+0x580>
ffffffffc02008c8:	815ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02008cc:	782c                	ld	a1,112(s0)
ffffffffc02008ce:	00002517          	auipc	a0,0x2
ffffffffc02008d2:	d8250513          	addi	a0,a0,-638 # ffffffffc0202650 <commands+0x598>
ffffffffc02008d6:	807ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02008da:	7c2c                	ld	a1,120(s0)
ffffffffc02008dc:	00002517          	auipc	a0,0x2
ffffffffc02008e0:	d8c50513          	addi	a0,a0,-628 # ffffffffc0202668 <commands+0x5b0>
ffffffffc02008e4:	ff8ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02008e8:	604c                	ld	a1,128(s0)
ffffffffc02008ea:	00002517          	auipc	a0,0x2
ffffffffc02008ee:	d9650513          	addi	a0,a0,-618 # ffffffffc0202680 <commands+0x5c8>
ffffffffc02008f2:	feaff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc02008f6:	644c                	ld	a1,136(s0)
ffffffffc02008f8:	00002517          	auipc	a0,0x2
ffffffffc02008fc:	da050513          	addi	a0,a0,-608 # ffffffffc0202698 <commands+0x5e0>
ffffffffc0200900:	fdcff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200904:	684c                	ld	a1,144(s0)
ffffffffc0200906:	00002517          	auipc	a0,0x2
ffffffffc020090a:	daa50513          	addi	a0,a0,-598 # ffffffffc02026b0 <commands+0x5f8>
ffffffffc020090e:	fceff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200912:	6c4c                	ld	a1,152(s0)
ffffffffc0200914:	00002517          	auipc	a0,0x2
ffffffffc0200918:	db450513          	addi	a0,a0,-588 # ffffffffc02026c8 <commands+0x610>
ffffffffc020091c:	fc0ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200920:	704c                	ld	a1,160(s0)
ffffffffc0200922:	00002517          	auipc	a0,0x2
ffffffffc0200926:	dbe50513          	addi	a0,a0,-578 # ffffffffc02026e0 <commands+0x628>
ffffffffc020092a:	fb2ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc020092e:	744c                	ld	a1,168(s0)
ffffffffc0200930:	00002517          	auipc	a0,0x2
ffffffffc0200934:	dc850513          	addi	a0,a0,-568 # ffffffffc02026f8 <commands+0x640>
ffffffffc0200938:	fa4ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc020093c:	784c                	ld	a1,176(s0)
ffffffffc020093e:	00002517          	auipc	a0,0x2
ffffffffc0200942:	dd250513          	addi	a0,a0,-558 # ffffffffc0202710 <commands+0x658>
ffffffffc0200946:	f96ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc020094a:	7c4c                	ld	a1,184(s0)
ffffffffc020094c:	00002517          	auipc	a0,0x2
ffffffffc0200950:	ddc50513          	addi	a0,a0,-548 # ffffffffc0202728 <commands+0x670>
ffffffffc0200954:	f88ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200958:	606c                	ld	a1,192(s0)
ffffffffc020095a:	00002517          	auipc	a0,0x2
ffffffffc020095e:	de650513          	addi	a0,a0,-538 # ffffffffc0202740 <commands+0x688>
ffffffffc0200962:	f7aff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200966:	646c                	ld	a1,200(s0)
ffffffffc0200968:	00002517          	auipc	a0,0x2
ffffffffc020096c:	df050513          	addi	a0,a0,-528 # ffffffffc0202758 <commands+0x6a0>
ffffffffc0200970:	f6cff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200974:	686c                	ld	a1,208(s0)
ffffffffc0200976:	00002517          	auipc	a0,0x2
ffffffffc020097a:	dfa50513          	addi	a0,a0,-518 # ffffffffc0202770 <commands+0x6b8>
ffffffffc020097e:	f5eff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200982:	6c6c                	ld	a1,216(s0)
ffffffffc0200984:	00002517          	auipc	a0,0x2
ffffffffc0200988:	e0450513          	addi	a0,a0,-508 # ffffffffc0202788 <commands+0x6d0>
ffffffffc020098c:	f50ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200990:	706c                	ld	a1,224(s0)
ffffffffc0200992:	00002517          	auipc	a0,0x2
ffffffffc0200996:	e0e50513          	addi	a0,a0,-498 # ffffffffc02027a0 <commands+0x6e8>
ffffffffc020099a:	f42ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020099e:	746c                	ld	a1,232(s0)
ffffffffc02009a0:	00002517          	auipc	a0,0x2
ffffffffc02009a4:	e1850513          	addi	a0,a0,-488 # ffffffffc02027b8 <commands+0x700>
ffffffffc02009a8:	f34ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc02009ac:	786c                	ld	a1,240(s0)
ffffffffc02009ae:	00002517          	auipc	a0,0x2
ffffffffc02009b2:	e2250513          	addi	a0,a0,-478 # ffffffffc02027d0 <commands+0x718>
ffffffffc02009b6:	f26ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ba:	7c6c                	ld	a1,248(s0)
}
ffffffffc02009bc:	6402                	ld	s0,0(sp)
ffffffffc02009be:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009c0:	00002517          	auipc	a0,0x2
ffffffffc02009c4:	e2850513          	addi	a0,a0,-472 # ffffffffc02027e8 <commands+0x730>
}
ffffffffc02009c8:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02009ca:	f12ff06f          	j	ffffffffc02000dc <cprintf>

ffffffffc02009ce <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02009ce:	1141                	addi	sp,sp,-16
ffffffffc02009d0:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009d2:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02009d4:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02009d6:	00002517          	auipc	a0,0x2
ffffffffc02009da:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202800 <commands+0x748>
void print_trapframe(struct trapframe *tf) {
ffffffffc02009de:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02009e0:	efcff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    print_regs(&tf->gpr);
ffffffffc02009e4:	8522                	mv	a0,s0
ffffffffc02009e6:	e1bff0ef          	jal	ra,ffffffffc0200800 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02009ea:	10043583          	ld	a1,256(s0)
ffffffffc02009ee:	00002517          	auipc	a0,0x2
ffffffffc02009f2:	e2a50513          	addi	a0,a0,-470 # ffffffffc0202818 <commands+0x760>
ffffffffc02009f6:	ee6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc02009fa:	10843583          	ld	a1,264(s0)
ffffffffc02009fe:	00002517          	auipc	a0,0x2
ffffffffc0200a02:	e3250513          	addi	a0,a0,-462 # ffffffffc0202830 <commands+0x778>
ffffffffc0200a06:	ed6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc0200a0a:	11043583          	ld	a1,272(s0)
ffffffffc0200a0e:	00002517          	auipc	a0,0x2
ffffffffc0200a12:	e3a50513          	addi	a0,a0,-454 # ffffffffc0202848 <commands+0x790>
ffffffffc0200a16:	ec6ff0ef          	jal	ra,ffffffffc02000dc <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a1a:	11843583          	ld	a1,280(s0)
}
ffffffffc0200a1e:	6402                	ld	s0,0(sp)
ffffffffc0200a20:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a22:	00002517          	auipc	a0,0x2
ffffffffc0200a26:	e3e50513          	addi	a0,a0,-450 # ffffffffc0202860 <commands+0x7a8>
}
ffffffffc0200a2a:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200a2c:	eb0ff06f          	j	ffffffffc02000dc <cprintf>

ffffffffc0200a30 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a30:	11853783          	ld	a5,280(a0)
    static int ticks = 0;
    static int print_count = 0;
    switch (cause) {
ffffffffc0200a34:	472d                	li	a4,11
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200a36:	0786                	slli	a5,a5,0x1
ffffffffc0200a38:	8385                	srli	a5,a5,0x1
    switch (cause) {
ffffffffc0200a3a:	08f76563          	bltu	a4,a5,ffffffffc0200ac4 <interrupt_handler+0x94>
ffffffffc0200a3e:	00002717          	auipc	a4,0x2
ffffffffc0200a42:	98670713          	addi	a4,a4,-1658 # ffffffffc02023c4 <commands+0x30c>
ffffffffc0200a46:	078a                	slli	a5,a5,0x2
ffffffffc0200a48:	97ba                	add	a5,a5,a4
ffffffffc0200a4a:	439c                	lw	a5,0(a5)
ffffffffc0200a4c:	97ba                	add	a5,a5,a4
ffffffffc0200a4e:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200a50:	00002517          	auipc	a0,0x2
ffffffffc0200a54:	a4850513          	addi	a0,a0,-1464 # ffffffffc0202498 <commands+0x3e0>
ffffffffc0200a58:	e84ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc0200a5c:	00002517          	auipc	a0,0x2
ffffffffc0200a60:	a1c50513          	addi	a0,a0,-1508 # ffffffffc0202478 <commands+0x3c0>
ffffffffc0200a64:	e78ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a68:	00002517          	auipc	a0,0x2
ffffffffc0200a6c:	9d050513          	addi	a0,a0,-1584 # ffffffffc0202438 <commands+0x380>
ffffffffc0200a70:	e6cff06f          	j	ffffffffc02000dc <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200a74:	00002517          	auipc	a0,0x2
ffffffffc0200a78:	a4450513          	addi	a0,a0,-1468 # ffffffffc02024b8 <commands+0x400>
ffffffffc0200a7c:	e60ff06f          	j	ffffffffc02000dc <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a80:	1141                	addi	sp,sp,-16
ffffffffc0200a82:	e406                	sd	ra,8(sp)
            /*(1)设置下次时钟中断- clock_set_next_event()
             *(2)计数器（ticks）加一
             *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
            * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
            */
            clock_set_next_event();
ffffffffc0200a84:	9ddff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            // 计数器加一
            ticks++;
ffffffffc0200a88:	00006797          	auipc	a5,0x6
ffffffffc0200a8c:	9d478793          	addi	a5,a5,-1580 # ffffffffc020645c <ticks.1323>
ffffffffc0200a90:	439c                	lw	a5,0(a5)
            // 当计数器达到100时打印并重置
            if (ticks >= TICK_NUM) {
ffffffffc0200a92:	06300713          	li	a4,99
            ticks++;
ffffffffc0200a96:	0017869b          	addiw	a3,a5,1
ffffffffc0200a9a:	00006617          	auipc	a2,0x6
ffffffffc0200a9e:	9cd62123          	sw	a3,-1598(a2) # ffffffffc020645c <ticks.1323>
            if (ticks >= TICK_NUM) {
ffffffffc0200aa2:	02d74263          	blt	a4,a3,ffffffffc0200ac6 <interrupt_handler+0x96>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa6:	60a2                	ld	ra,8(sp)
ffffffffc0200aa8:	0141                	addi	sp,sp,16
ffffffffc0200aaa:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200aac:	00002517          	auipc	a0,0x2
ffffffffc0200ab0:	a3450513          	addi	a0,a0,-1484 # ffffffffc02024e0 <commands+0x428>
ffffffffc0200ab4:	e28ff06f          	j	ffffffffc02000dc <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200ab8:	00002517          	auipc	a0,0x2
ffffffffc0200abc:	9a050513          	addi	a0,a0,-1632 # ffffffffc0202458 <commands+0x3a0>
ffffffffc0200ac0:	e1cff06f          	j	ffffffffc02000dc <cprintf>
            print_trapframe(tf);
ffffffffc0200ac4:	b729                	j	ffffffffc02009ce <print_trapframe>
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc0200ac6:	06400593          	li	a1,100
ffffffffc0200aca:	00002517          	auipc	a0,0x2
ffffffffc0200ace:	a0650513          	addi	a0,a0,-1530 # ffffffffc02024d0 <commands+0x418>
ffffffffc0200ad2:	e0aff0ef          	jal	ra,ffffffffc02000dc <cprintf>
                print_count++;
ffffffffc0200ad6:	00006797          	auipc	a5,0x6
ffffffffc0200ada:	98278793          	addi	a5,a5,-1662 # ffffffffc0206458 <print_count.1324>
ffffffffc0200ade:	439c                	lw	a5,0(a5)
                ticks = 0;
ffffffffc0200ae0:	00006717          	auipc	a4,0x6
ffffffffc0200ae4:	96072e23          	sw	zero,-1668(a4) # ffffffffc020645c <ticks.1323>
                if (print_count >= 10) {
ffffffffc0200ae8:	4725                	li	a4,9
                print_count++;
ffffffffc0200aea:	0017869b          	addiw	a3,a5,1
ffffffffc0200aee:	00006617          	auipc	a2,0x6
ffffffffc0200af2:	96d62523          	sw	a3,-1686(a2) # ffffffffc0206458 <print_count.1324>
                if (print_count >= 10) {
ffffffffc0200af6:	fad758e3          	bge	a4,a3,ffffffffc0200aa6 <interrupt_handler+0x76>
}
ffffffffc0200afa:	60a2                	ld	ra,8(sp)
ffffffffc0200afc:	0141                	addi	sp,sp,16
                    sbi_shutdown();
ffffffffc0200afe:	39e0106f          	j	ffffffffc0201e9c <sbi_shutdown>

ffffffffc0200b02 <exception_handler>:

void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
ffffffffc0200b02:	11853783          	ld	a5,280(a0)
ffffffffc0200b06:	472d                	li	a4,11
ffffffffc0200b08:	02f76763          	bltu	a4,a5,ffffffffc0200b36 <exception_handler+0x34>
ffffffffc0200b0c:	4705                	li	a4,1
ffffffffc0200b0e:	00f71733          	sll	a4,a4,a5
ffffffffc0200b12:	6785                	lui	a5,0x1
ffffffffc0200b14:	17cd                	addi	a5,a5,-13
ffffffffc0200b16:	8ff9                	and	a5,a5,a4
ffffffffc0200b18:	ef91                	bnez	a5,ffffffffc0200b34 <exception_handler+0x32>
void exception_handler(struct trapframe *tf) {
ffffffffc0200b1a:	1141                	addi	sp,sp,-16
ffffffffc0200b1c:	e022                	sd	s0,0(sp)
ffffffffc0200b1e:	e406                	sd	ra,8(sp)
ffffffffc0200b20:	00877793          	andi	a5,a4,8
ffffffffc0200b24:	842a                	mv	s0,a0
ffffffffc0200b26:	e3a1                	bnez	a5,ffffffffc0200b66 <exception_handler+0x64>
ffffffffc0200b28:	8b11                	andi	a4,a4,4
ffffffffc0200b2a:	e719                	bnez	a4,ffffffffc0200b38 <exception_handler+0x36>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200b2c:	6402                	ld	s0,0(sp)
ffffffffc0200b2e:	60a2                	ld	ra,8(sp)
ffffffffc0200b30:	0141                	addi	sp,sp,16
            print_trapframe(tf);
ffffffffc0200b32:	bd71                	j	ffffffffc02009ce <print_trapframe>
ffffffffc0200b34:	8082                	ret
ffffffffc0200b36:	bd61                	j	ffffffffc02009ce <print_trapframe>
            cprintf("Illegal instruction\n");
ffffffffc0200b38:	00002517          	auipc	a0,0x2
ffffffffc0200b3c:	8c050513          	addi	a0,a0,-1856 # ffffffffc02023f8 <commands+0x340>
            cprintf("breakpoint\n");
ffffffffc0200b40:	d9cff0ef          	jal	ra,ffffffffc02000dc <cprintf>
            cprintf("Exception at 0x%08x\n", tf->epc);
ffffffffc0200b44:	10843583          	ld	a1,264(s0)
ffffffffc0200b48:	00002517          	auipc	a0,0x2
ffffffffc0200b4c:	8c850513          	addi	a0,a0,-1848 # ffffffffc0202410 <commands+0x358>
ffffffffc0200b50:	d8cff0ef          	jal	ra,ffffffffc02000dc <cprintf>
            tf->epc += 4;  // 跳过断点指令（ebreak）
ffffffffc0200b54:	10843783          	ld	a5,264(s0)
}
ffffffffc0200b58:	60a2                	ld	ra,8(sp)
            tf->epc += 4;  // 跳过断点指令（ebreak）
ffffffffc0200b5a:	0791                	addi	a5,a5,4
ffffffffc0200b5c:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200b60:	6402                	ld	s0,0(sp)
ffffffffc0200b62:	0141                	addi	sp,sp,16
ffffffffc0200b64:	8082                	ret
            cprintf("breakpoint\n");
ffffffffc0200b66:	00002517          	auipc	a0,0x2
ffffffffc0200b6a:	8c250513          	addi	a0,a0,-1854 # ffffffffc0202428 <commands+0x370>
ffffffffc0200b6e:	bfc9                	j	ffffffffc0200b40 <exception_handler+0x3e>

ffffffffc0200b70 <trap>:

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200b70:	11853783          	ld	a5,280(a0)
ffffffffc0200b74:	0007c363          	bltz	a5,ffffffffc0200b7a <trap+0xa>
        // interrupts
        interrupt_handler(tf);
    } else {
        // exceptions
        exception_handler(tf);
ffffffffc0200b78:	b769                	j	ffffffffc0200b02 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200b7a:	bd5d                	j	ffffffffc0200a30 <interrupt_handler>

ffffffffc0200b7c <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc0200b7c:	14011073          	csrw	sscratch,sp
ffffffffc0200b80:	712d                	addi	sp,sp,-288
ffffffffc0200b82:	e002                	sd	zero,0(sp)
ffffffffc0200b84:	e406                	sd	ra,8(sp)
ffffffffc0200b86:	ec0e                	sd	gp,24(sp)
ffffffffc0200b88:	f012                	sd	tp,32(sp)
ffffffffc0200b8a:	f416                	sd	t0,40(sp)
ffffffffc0200b8c:	f81a                	sd	t1,48(sp)
ffffffffc0200b8e:	fc1e                	sd	t2,56(sp)
ffffffffc0200b90:	e0a2                	sd	s0,64(sp)
ffffffffc0200b92:	e4a6                	sd	s1,72(sp)
ffffffffc0200b94:	e8aa                	sd	a0,80(sp)
ffffffffc0200b96:	ecae                	sd	a1,88(sp)
ffffffffc0200b98:	f0b2                	sd	a2,96(sp)
ffffffffc0200b9a:	f4b6                	sd	a3,104(sp)
ffffffffc0200b9c:	f8ba                	sd	a4,112(sp)
ffffffffc0200b9e:	fcbe                	sd	a5,120(sp)
ffffffffc0200ba0:	e142                	sd	a6,128(sp)
ffffffffc0200ba2:	e546                	sd	a7,136(sp)
ffffffffc0200ba4:	e94a                	sd	s2,144(sp)
ffffffffc0200ba6:	ed4e                	sd	s3,152(sp)
ffffffffc0200ba8:	f152                	sd	s4,160(sp)
ffffffffc0200baa:	f556                	sd	s5,168(sp)
ffffffffc0200bac:	f95a                	sd	s6,176(sp)
ffffffffc0200bae:	fd5e                	sd	s7,184(sp)
ffffffffc0200bb0:	e1e2                	sd	s8,192(sp)
ffffffffc0200bb2:	e5e6                	sd	s9,200(sp)
ffffffffc0200bb4:	e9ea                	sd	s10,208(sp)
ffffffffc0200bb6:	edee                	sd	s11,216(sp)
ffffffffc0200bb8:	f1f2                	sd	t3,224(sp)
ffffffffc0200bba:	f5f6                	sd	t4,232(sp)
ffffffffc0200bbc:	f9fa                	sd	t5,240(sp)
ffffffffc0200bbe:	fdfe                	sd	t6,248(sp)
ffffffffc0200bc0:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200bc4:	100024f3          	csrr	s1,sstatus
ffffffffc0200bc8:	14102973          	csrr	s2,sepc
ffffffffc0200bcc:	143029f3          	csrr	s3,stval
ffffffffc0200bd0:	14202a73          	csrr	s4,scause
ffffffffc0200bd4:	e822                	sd	s0,16(sp)
ffffffffc0200bd6:	e226                	sd	s1,256(sp)
ffffffffc0200bd8:	e64a                	sd	s2,264(sp)
ffffffffc0200bda:	ea4e                	sd	s3,272(sp)
ffffffffc0200bdc:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200bde:	850a                	mv	a0,sp
    jal trap
ffffffffc0200be0:	f91ff0ef          	jal	ra,ffffffffc0200b70 <trap>

ffffffffc0200be4 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200be4:	6492                	ld	s1,256(sp)
ffffffffc0200be6:	6932                	ld	s2,264(sp)
ffffffffc0200be8:	10049073          	csrw	sstatus,s1
ffffffffc0200bec:	14191073          	csrw	sepc,s2
ffffffffc0200bf0:	60a2                	ld	ra,8(sp)
ffffffffc0200bf2:	61e2                	ld	gp,24(sp)
ffffffffc0200bf4:	7202                	ld	tp,32(sp)
ffffffffc0200bf6:	72a2                	ld	t0,40(sp)
ffffffffc0200bf8:	7342                	ld	t1,48(sp)
ffffffffc0200bfa:	73e2                	ld	t2,56(sp)
ffffffffc0200bfc:	6406                	ld	s0,64(sp)
ffffffffc0200bfe:	64a6                	ld	s1,72(sp)
ffffffffc0200c00:	6546                	ld	a0,80(sp)
ffffffffc0200c02:	65e6                	ld	a1,88(sp)
ffffffffc0200c04:	7606                	ld	a2,96(sp)
ffffffffc0200c06:	76a6                	ld	a3,104(sp)
ffffffffc0200c08:	7746                	ld	a4,112(sp)
ffffffffc0200c0a:	77e6                	ld	a5,120(sp)
ffffffffc0200c0c:	680a                	ld	a6,128(sp)
ffffffffc0200c0e:	68aa                	ld	a7,136(sp)
ffffffffc0200c10:	694a                	ld	s2,144(sp)
ffffffffc0200c12:	69ea                	ld	s3,152(sp)
ffffffffc0200c14:	7a0a                	ld	s4,160(sp)
ffffffffc0200c16:	7aaa                	ld	s5,168(sp)
ffffffffc0200c18:	7b4a                	ld	s6,176(sp)
ffffffffc0200c1a:	7bea                	ld	s7,184(sp)
ffffffffc0200c1c:	6c0e                	ld	s8,192(sp)
ffffffffc0200c1e:	6cae                	ld	s9,200(sp)
ffffffffc0200c20:	6d4e                	ld	s10,208(sp)
ffffffffc0200c22:	6dee                	ld	s11,216(sp)
ffffffffc0200c24:	7e0e                	ld	t3,224(sp)
ffffffffc0200c26:	7eae                	ld	t4,232(sp)
ffffffffc0200c28:	7f4e                	ld	t5,240(sp)
ffffffffc0200c2a:	7fee                	ld	t6,248(sp)
ffffffffc0200c2c:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200c2e:	10200073          	sret

ffffffffc0200c32 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200c32:	00005797          	auipc	a5,0x5
ffffffffc0200c36:	3f678793          	addi	a5,a5,1014 # ffffffffc0206028 <edata>
ffffffffc0200c3a:	e79c                	sd	a5,8(a5)
ffffffffc0200c3c:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200c3e:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200c42:	8082                	ret

ffffffffc0200c44 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200c44:	00005517          	auipc	a0,0x5
ffffffffc0200c48:	3f456503          	lwu	a0,1012(a0) # ffffffffc0206038 <edata+0x10>
ffffffffc0200c4c:	8082                	ret

ffffffffc0200c4e <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200c4e:	c55d                	beqz	a0,ffffffffc0200cfc <best_fit_alloc_pages+0xae>
    if (n > nr_free) {
ffffffffc0200c50:	00005697          	auipc	a3,0x5
ffffffffc0200c54:	3d868693          	addi	a3,a3,984 # ffffffffc0206028 <edata>
ffffffffc0200c58:	0106a803          	lw	a6,16(a3)
ffffffffc0200c5c:	862a                	mv	a2,a0
ffffffffc0200c5e:	02081793          	slli	a5,a6,0x20
ffffffffc0200c62:	9381                	srli	a5,a5,0x20
ffffffffc0200c64:	08a7ea63          	bltu	a5,a0,ffffffffc0200cf8 <best_fit_alloc_pages+0xaa>
    size_t min_size = nr_free + 1;
ffffffffc0200c68:	0018059b          	addiw	a1,a6,1
ffffffffc0200c6c:	1582                	slli	a1,a1,0x20
ffffffffc0200c6e:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc0200c70:	87b6                	mv	a5,a3
    struct Page *page = NULL;
ffffffffc0200c72:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200c74:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c76:	02d78263          	beq	a5,a3,ffffffffc0200c9a <best_fit_alloc_pages+0x4c>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200c7a:	ff07b703          	ld	a4,-16(a5)
        if (PageProperty(p) && p->property >= n) {// 若当前块大小 >= 需求（满足分配条件）
ffffffffc0200c7e:	8b09                	andi	a4,a4,2
ffffffffc0200c80:	db75                	beqz	a4,ffffffffc0200c74 <best_fit_alloc_pages+0x26>
ffffffffc0200c82:	ff87e703          	lwu	a4,-8(a5)
ffffffffc0200c86:	fec767e3          	bltu	a4,a2,ffffffffc0200c74 <best_fit_alloc_pages+0x26>
            if (p->property < min_size) {// 若当前块是更小的满足条件的块（Best-Fit核心）
ffffffffc0200c8a:	feb775e3          	bgeu	a4,a1,ffffffffc0200c74 <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc0200c8e:	fe878513          	addi	a0,a5,-24
ffffffffc0200c92:	679c                	ld	a5,8(a5)
ffffffffc0200c94:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200c96:	fed792e3          	bne	a5,a3,ffffffffc0200c7a <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc0200c9a:	c125                	beqz	a0,ffffffffc0200cfa <best_fit_alloc_pages+0xac>
    __list_del(listelm->prev, listelm->next);
ffffffffc0200c9c:	7118                	ld	a4,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200c9e:	6d14                	ld	a3,24(a0)
        if (page->property > n) {
ffffffffc0200ca0:	490c                	lw	a1,16(a0)
ffffffffc0200ca2:	0006089b          	sext.w	a7,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200ca6:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0200ca8:	e314                	sd	a3,0(a4)
ffffffffc0200caa:	02059713          	slli	a4,a1,0x20
ffffffffc0200cae:	9301                	srli	a4,a4,0x20
ffffffffc0200cb0:	02e67863          	bgeu	a2,a4,ffffffffc0200ce0 <best_fit_alloc_pages+0x92>
            struct Page *p = page + n;
ffffffffc0200cb4:	00261713          	slli	a4,a2,0x2
ffffffffc0200cb8:	9732                	add	a4,a4,a2
ffffffffc0200cba:	070e                	slli	a4,a4,0x3
ffffffffc0200cbc:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc0200cbe:	411585bb          	subw	a1,a1,a7
ffffffffc0200cc2:	cb0c                	sw	a1,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0200cc4:	4609                	li	a2,2
ffffffffc0200cc6:	00870593          	addi	a1,a4,8
ffffffffc0200cca:	40c5b02f          	amoor.d	zero,a2,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0200cce:	6690                	ld	a2,8(a3)
            list_add(prev, &(p->page_link));
ffffffffc0200cd0:	01870593          	addi	a1,a4,24
    prev->next = next->prev = elm;
ffffffffc0200cd4:	0107a803          	lw	a6,16(a5)
ffffffffc0200cd8:	e20c                	sd	a1,0(a2)
ffffffffc0200cda:	e68c                	sd	a1,8(a3)
    elm->next = next;
ffffffffc0200cdc:	f310                	sd	a2,32(a4)
    elm->prev = prev;
ffffffffc0200cde:	ef14                	sd	a3,24(a4)
        nr_free -= n;
ffffffffc0200ce0:	4118083b          	subw	a6,a6,a7
ffffffffc0200ce4:	00005797          	auipc	a5,0x5
ffffffffc0200ce8:	3507aa23          	sw	a6,852(a5) # ffffffffc0206038 <edata+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200cec:	57f5                	li	a5,-3
ffffffffc0200cee:	00850713          	addi	a4,a0,8
ffffffffc0200cf2:	60f7302f          	amoand.d	zero,a5,(a4)
ffffffffc0200cf6:	8082                	ret
        return NULL;
ffffffffc0200cf8:	4501                	li	a0,0
}
ffffffffc0200cfa:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200cfc:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200cfe:	00002697          	auipc	a3,0x2
ffffffffc0200d02:	b7a68693          	addi	a3,a3,-1158 # ffffffffc0202878 <commands+0x7c0>
ffffffffc0200d06:	00002617          	auipc	a2,0x2
ffffffffc0200d0a:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0200d0e:	06b00593          	li	a1,107
ffffffffc0200d12:	00002517          	auipc	a0,0x2
ffffffffc0200d16:	b8650513          	addi	a0,a0,-1146 # ffffffffc0202898 <commands+0x7e0>
best_fit_alloc_pages(size_t n) {
ffffffffc0200d1a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d1c:	eb2ff0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc0200d20 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200d20:	715d                	addi	sp,sp,-80
ffffffffc0200d22:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200d24:	00005917          	auipc	s2,0x5
ffffffffc0200d28:	30490913          	addi	s2,s2,772 # ffffffffc0206028 <edata>
ffffffffc0200d2c:	00893783          	ld	a5,8(s2)
ffffffffc0200d30:	e486                	sd	ra,72(sp)
ffffffffc0200d32:	e0a2                	sd	s0,64(sp)
ffffffffc0200d34:	fc26                	sd	s1,56(sp)
ffffffffc0200d36:	f44e                	sd	s3,40(sp)
ffffffffc0200d38:	f052                	sd	s4,32(sp)
ffffffffc0200d3a:	ec56                	sd	s5,24(sp)
ffffffffc0200d3c:	e85a                	sd	s6,16(sp)
ffffffffc0200d3e:	e45e                	sd	s7,8(sp)
ffffffffc0200d40:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d42:	2d278363          	beq	a5,s2,ffffffffc0201008 <best_fit_check+0x2e8>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200d46:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200d4a:	8305                	srli	a4,a4,0x1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200d4c:	8b05                	andi	a4,a4,1
ffffffffc0200d4e:	2c070163          	beqz	a4,ffffffffc0201010 <best_fit_check+0x2f0>
    int count = 0, total = 0;
ffffffffc0200d52:	4401                	li	s0,0
ffffffffc0200d54:	4481                	li	s1,0
ffffffffc0200d56:	a031                	j	ffffffffc0200d62 <best_fit_check+0x42>
ffffffffc0200d58:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200d5c:	8b09                	andi	a4,a4,2
ffffffffc0200d5e:	2a070963          	beqz	a4,ffffffffc0201010 <best_fit_check+0x2f0>
        count ++, total += p->property;
ffffffffc0200d62:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200d66:	679c                	ld	a5,8(a5)
ffffffffc0200d68:	2485                	addiw	s1,s1,1
ffffffffc0200d6a:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200d6c:	ff2796e3          	bne	a5,s2,ffffffffc0200d58 <best_fit_check+0x38>
ffffffffc0200d70:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200d72:	1f7000ef          	jal	ra,ffffffffc0201768 <nr_free_pages>
ffffffffc0200d76:	37351d63          	bne	a0,s3,ffffffffc02010f0 <best_fit_check+0x3d0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d7a:	4505                	li	a0,1
ffffffffc0200d7c:	163000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200d80:	8a2a                	mv	s4,a0
ffffffffc0200d82:	3a050763          	beqz	a0,ffffffffc0201130 <best_fit_check+0x410>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d86:	4505                	li	a0,1
ffffffffc0200d88:	157000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200d8c:	89aa                	mv	s3,a0
ffffffffc0200d8e:	38050163          	beqz	a0,ffffffffc0201110 <best_fit_check+0x3f0>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d92:	4505                	li	a0,1
ffffffffc0200d94:	14b000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200d98:	8aaa                	mv	s5,a0
ffffffffc0200d9a:	30050b63          	beqz	a0,ffffffffc02010b0 <best_fit_check+0x390>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200d9e:	293a0963          	beq	s4,s3,ffffffffc0201030 <best_fit_check+0x310>
ffffffffc0200da2:	28aa0763          	beq	s4,a0,ffffffffc0201030 <best_fit_check+0x310>
ffffffffc0200da6:	28a98563          	beq	s3,a0,ffffffffc0201030 <best_fit_check+0x310>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200daa:	000a2783          	lw	a5,0(s4)
ffffffffc0200dae:	2a079163          	bnez	a5,ffffffffc0201050 <best_fit_check+0x330>
ffffffffc0200db2:	0009a783          	lw	a5,0(s3)
ffffffffc0200db6:	28079d63          	bnez	a5,ffffffffc0201050 <best_fit_check+0x330>
ffffffffc0200dba:	411c                	lw	a5,0(a0)
ffffffffc0200dbc:	28079a63          	bnez	a5,ffffffffc0201050 <best_fit_check+0x330>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dc0:	00005797          	auipc	a5,0x5
ffffffffc0200dc4:	6d878793          	addi	a5,a5,1752 # ffffffffc0206498 <pages>
ffffffffc0200dc8:	639c                	ld	a5,0(a5)
ffffffffc0200dca:	00002717          	auipc	a4,0x2
ffffffffc0200dce:	ae670713          	addi	a4,a4,-1306 # ffffffffc02028b0 <commands+0x7f8>
ffffffffc0200dd2:	630c                	ld	a1,0(a4)
ffffffffc0200dd4:	40fa0733          	sub	a4,s4,a5
ffffffffc0200dd8:	870d                	srai	a4,a4,0x3
ffffffffc0200dda:	02b70733          	mul	a4,a4,a1
ffffffffc0200dde:	00002697          	auipc	a3,0x2
ffffffffc0200de2:	1b268693          	addi	a3,a3,434 # ffffffffc0202f90 <nbase>
ffffffffc0200de6:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200de8:	00005697          	auipc	a3,0x5
ffffffffc0200dec:	67868693          	addi	a3,a3,1656 # ffffffffc0206460 <npage>
ffffffffc0200df0:	6294                	ld	a3,0(a3)
ffffffffc0200df2:	06b2                	slli	a3,a3,0xc
ffffffffc0200df4:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200df6:	0732                	slli	a4,a4,0xc
ffffffffc0200df8:	26d77c63          	bgeu	a4,a3,ffffffffc0201070 <best_fit_check+0x350>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200dfc:	40f98733          	sub	a4,s3,a5
ffffffffc0200e00:	870d                	srai	a4,a4,0x3
ffffffffc0200e02:	02b70733          	mul	a4,a4,a1
ffffffffc0200e06:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e08:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e0a:	42d77363          	bgeu	a4,a3,ffffffffc0201230 <best_fit_check+0x510>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200e0e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200e12:	878d                	srai	a5,a5,0x3
ffffffffc0200e14:	02b787b3          	mul	a5,a5,a1
ffffffffc0200e18:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200e1a:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200e1c:	3ed7fa63          	bgeu	a5,a3,ffffffffc0201210 <best_fit_check+0x4f0>
    assert(alloc_page() == NULL);
ffffffffc0200e20:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200e22:	00093c03          	ld	s8,0(s2)
ffffffffc0200e26:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200e2a:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200e2e:	00005797          	auipc	a5,0x5
ffffffffc0200e32:	2127b123          	sd	s2,514(a5) # ffffffffc0206030 <edata+0x8>
ffffffffc0200e36:	00005797          	auipc	a5,0x5
ffffffffc0200e3a:	1f27b923          	sd	s2,498(a5) # ffffffffc0206028 <edata>
    nr_free = 0;
ffffffffc0200e3e:	00005797          	auipc	a5,0x5
ffffffffc0200e42:	1e07ad23          	sw	zero,506(a5) # ffffffffc0206038 <edata+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200e46:	099000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200e4a:	3a051363          	bnez	a0,ffffffffc02011f0 <best_fit_check+0x4d0>
    free_page(p0);
ffffffffc0200e4e:	4585                	li	a1,1
ffffffffc0200e50:	8552                	mv	a0,s4
ffffffffc0200e52:	0d1000ef          	jal	ra,ffffffffc0201722 <free_pages>
    free_page(p1);
ffffffffc0200e56:	4585                	li	a1,1
ffffffffc0200e58:	854e                	mv	a0,s3
ffffffffc0200e5a:	0c9000ef          	jal	ra,ffffffffc0201722 <free_pages>
    free_page(p2);
ffffffffc0200e5e:	4585                	li	a1,1
ffffffffc0200e60:	8556                	mv	a0,s5
ffffffffc0200e62:	0c1000ef          	jal	ra,ffffffffc0201722 <free_pages>
    assert(nr_free == 3);
ffffffffc0200e66:	01092703          	lw	a4,16(s2)
ffffffffc0200e6a:	478d                	li	a5,3
ffffffffc0200e6c:	36f71263          	bne	a4,a5,ffffffffc02011d0 <best_fit_check+0x4b0>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200e70:	4505                	li	a0,1
ffffffffc0200e72:	06d000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200e76:	89aa                	mv	s3,a0
ffffffffc0200e78:	32050c63          	beqz	a0,ffffffffc02011b0 <best_fit_check+0x490>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200e7c:	4505                	li	a0,1
ffffffffc0200e7e:	061000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200e82:	8aaa                	mv	s5,a0
ffffffffc0200e84:	30050663          	beqz	a0,ffffffffc0201190 <best_fit_check+0x470>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200e88:	4505                	li	a0,1
ffffffffc0200e8a:	055000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200e8e:	8a2a                	mv	s4,a0
ffffffffc0200e90:	2e050063          	beqz	a0,ffffffffc0201170 <best_fit_check+0x450>
    assert(alloc_page() == NULL);
ffffffffc0200e94:	4505                	li	a0,1
ffffffffc0200e96:	049000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200e9a:	2a051b63          	bnez	a0,ffffffffc0201150 <best_fit_check+0x430>
    free_page(p0);
ffffffffc0200e9e:	4585                	li	a1,1
ffffffffc0200ea0:	854e                	mv	a0,s3
ffffffffc0200ea2:	081000ef          	jal	ra,ffffffffc0201722 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200ea6:	00893783          	ld	a5,8(s2)
ffffffffc0200eaa:	1f278363          	beq	a5,s2,ffffffffc0201090 <best_fit_check+0x370>
    assert((p = alloc_page()) == p0);
ffffffffc0200eae:	4505                	li	a0,1
ffffffffc0200eb0:	02f000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200eb4:	54a99e63          	bne	s3,a0,ffffffffc0201410 <best_fit_check+0x6f0>
    assert(alloc_page() == NULL);
ffffffffc0200eb8:	4505                	li	a0,1
ffffffffc0200eba:	025000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200ebe:	52051963          	bnez	a0,ffffffffc02013f0 <best_fit_check+0x6d0>
    assert(nr_free == 0);
ffffffffc0200ec2:	01092783          	lw	a5,16(s2)
ffffffffc0200ec6:	50079563          	bnez	a5,ffffffffc02013d0 <best_fit_check+0x6b0>
    free_page(p);
ffffffffc0200eca:	854e                	mv	a0,s3
ffffffffc0200ecc:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ece:	00005797          	auipc	a5,0x5
ffffffffc0200ed2:	1587bd23          	sd	s8,346(a5) # ffffffffc0206028 <edata>
ffffffffc0200ed6:	00005797          	auipc	a5,0x5
ffffffffc0200eda:	1577bd23          	sd	s7,346(a5) # ffffffffc0206030 <edata+0x8>
    nr_free = nr_free_store;
ffffffffc0200ede:	00005797          	auipc	a5,0x5
ffffffffc0200ee2:	1567ad23          	sw	s6,346(a5) # ffffffffc0206038 <edata+0x10>
    free_page(p);
ffffffffc0200ee6:	03d000ef          	jal	ra,ffffffffc0201722 <free_pages>
    free_page(p1);
ffffffffc0200eea:	4585                	li	a1,1
ffffffffc0200eec:	8556                	mv	a0,s5
ffffffffc0200eee:	035000ef          	jal	ra,ffffffffc0201722 <free_pages>
    free_page(p2);
ffffffffc0200ef2:	4585                	li	a1,1
ffffffffc0200ef4:	8552                	mv	a0,s4
ffffffffc0200ef6:	02d000ef          	jal	ra,ffffffffc0201722 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200efa:	4515                	li	a0,5
ffffffffc0200efc:	7e2000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f00:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200f02:	4a050763          	beqz	a0,ffffffffc02013b0 <best_fit_check+0x690>
ffffffffc0200f06:	651c                	ld	a5,8(a0)
ffffffffc0200f08:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200f0a:	8b85                	andi	a5,a5,1
ffffffffc0200f0c:	48079263          	bnez	a5,ffffffffc0201390 <best_fit_check+0x670>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200f10:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f12:	00093b03          	ld	s6,0(s2)
ffffffffc0200f16:	00893a83          	ld	s5,8(s2)
ffffffffc0200f1a:	00005797          	auipc	a5,0x5
ffffffffc0200f1e:	1127b723          	sd	s2,270(a5) # ffffffffc0206028 <edata>
ffffffffc0200f22:	00005797          	auipc	a5,0x5
ffffffffc0200f26:	1127b723          	sd	s2,270(a5) # ffffffffc0206030 <edata+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200f2a:	7b4000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f2e:	44051163          	bnez	a0,ffffffffc0201370 <best_fit_check+0x650>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200f32:	4589                	li	a1,2
ffffffffc0200f34:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200f38:	01092b83          	lw	s7,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200f3c:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200f40:	00005797          	auipc	a5,0x5
ffffffffc0200f44:	0e07ac23          	sw	zero,248(a5) # ffffffffc0206038 <edata+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200f48:	7da000ef          	jal	ra,ffffffffc0201722 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200f4c:	8562                	mv	a0,s8
ffffffffc0200f4e:	4585                	li	a1,1
ffffffffc0200f50:	7d2000ef          	jal	ra,ffffffffc0201722 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f54:	4511                	li	a0,4
ffffffffc0200f56:	788000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f5a:	3e051b63          	bnez	a0,ffffffffc0201350 <best_fit_check+0x630>
ffffffffc0200f5e:	0309b783          	ld	a5,48(s3)
ffffffffc0200f62:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f64:	8b85                	andi	a5,a5,1
ffffffffc0200f66:	3c078563          	beqz	a5,ffffffffc0201330 <best_fit_check+0x610>
ffffffffc0200f6a:	0389a703          	lw	a4,56(s3)
ffffffffc0200f6e:	4789                	li	a5,2
ffffffffc0200f70:	3cf71063          	bne	a4,a5,ffffffffc0201330 <best_fit_check+0x610>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200f74:	4505                	li	a0,1
ffffffffc0200f76:	768000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f7a:	8a2a                	mv	s4,a0
ffffffffc0200f7c:	38050a63          	beqz	a0,ffffffffc0201310 <best_fit_check+0x5f0>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200f80:	4509                	li	a0,2
ffffffffc0200f82:	75c000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f86:	36050563          	beqz	a0,ffffffffc02012f0 <best_fit_check+0x5d0>
    assert(p0 + 4 == p1);
ffffffffc0200f8a:	354c1363          	bne	s8,s4,ffffffffc02012d0 <best_fit_check+0x5b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200f8e:	854e                	mv	a0,s3
ffffffffc0200f90:	4595                	li	a1,5
ffffffffc0200f92:	790000ef          	jal	ra,ffffffffc0201722 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200f96:	4515                	li	a0,5
ffffffffc0200f98:	746000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200f9c:	89aa                	mv	s3,a0
ffffffffc0200f9e:	30050963          	beqz	a0,ffffffffc02012b0 <best_fit_check+0x590>
    assert(alloc_page() == NULL);
ffffffffc0200fa2:	4505                	li	a0,1
ffffffffc0200fa4:	73a000ef          	jal	ra,ffffffffc02016de <alloc_pages>
ffffffffc0200fa8:	2e051463          	bnez	a0,ffffffffc0201290 <best_fit_check+0x570>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200fac:	01092783          	lw	a5,16(s2)
ffffffffc0200fb0:	2c079063          	bnez	a5,ffffffffc0201270 <best_fit_check+0x550>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200fb4:	4595                	li	a1,5
ffffffffc0200fb6:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200fb8:	00005797          	auipc	a5,0x5
ffffffffc0200fbc:	0977a023          	sw	s7,128(a5) # ffffffffc0206038 <edata+0x10>
    free_list = free_list_store;
ffffffffc0200fc0:	00005797          	auipc	a5,0x5
ffffffffc0200fc4:	0767b423          	sd	s6,104(a5) # ffffffffc0206028 <edata>
ffffffffc0200fc8:	00005797          	auipc	a5,0x5
ffffffffc0200fcc:	0757b423          	sd	s5,104(a5) # ffffffffc0206030 <edata+0x8>
    free_pages(p0, 5);
ffffffffc0200fd0:	752000ef          	jal	ra,ffffffffc0201722 <free_pages>
    return listelm->next;
ffffffffc0200fd4:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fd8:	01278963          	beq	a5,s2,ffffffffc0200fea <best_fit_check+0x2ca>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200fdc:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fe0:	679c                	ld	a5,8(a5)
ffffffffc0200fe2:	34fd                	addiw	s1,s1,-1
ffffffffc0200fe4:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200fe6:	ff279be3          	bne	a5,s2,ffffffffc0200fdc <best_fit_check+0x2bc>
    }
    assert(count == 0);
ffffffffc0200fea:	26049363          	bnez	s1,ffffffffc0201250 <best_fit_check+0x530>
    assert(total == 0);
ffffffffc0200fee:	e06d                	bnez	s0,ffffffffc02010d0 <best_fit_check+0x3b0>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200ff0:	60a6                	ld	ra,72(sp)
ffffffffc0200ff2:	6406                	ld	s0,64(sp)
ffffffffc0200ff4:	74e2                	ld	s1,56(sp)
ffffffffc0200ff6:	7942                	ld	s2,48(sp)
ffffffffc0200ff8:	79a2                	ld	s3,40(sp)
ffffffffc0200ffa:	7a02                	ld	s4,32(sp)
ffffffffc0200ffc:	6ae2                	ld	s5,24(sp)
ffffffffc0200ffe:	6b42                	ld	s6,16(sp)
ffffffffc0201000:	6ba2                	ld	s7,8(sp)
ffffffffc0201002:	6c02                	ld	s8,0(sp)
ffffffffc0201004:	6161                	addi	sp,sp,80
ffffffffc0201006:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201008:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020100a:	4401                	li	s0,0
ffffffffc020100c:	4481                	li	s1,0
ffffffffc020100e:	b395                	j	ffffffffc0200d72 <best_fit_check+0x52>
        assert(PageProperty(p));
ffffffffc0201010:	00002697          	auipc	a3,0x2
ffffffffc0201014:	8a868693          	addi	a3,a3,-1880 # ffffffffc02028b8 <commands+0x800>
ffffffffc0201018:	00002617          	auipc	a2,0x2
ffffffffc020101c:	86860613          	addi	a2,a2,-1944 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201020:	10b00593          	li	a1,267
ffffffffc0201024:	00002517          	auipc	a0,0x2
ffffffffc0201028:	87450513          	addi	a0,a0,-1932 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020102c:	ba2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0201030:	00002697          	auipc	a3,0x2
ffffffffc0201034:	91868693          	addi	a3,a3,-1768 # ffffffffc0202948 <commands+0x890>
ffffffffc0201038:	00002617          	auipc	a2,0x2
ffffffffc020103c:	84860613          	addi	a2,a2,-1976 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201040:	0d700593          	li	a1,215
ffffffffc0201044:	00002517          	auipc	a0,0x2
ffffffffc0201048:	85450513          	addi	a0,a0,-1964 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020104c:	b82ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201050:	00002697          	auipc	a3,0x2
ffffffffc0201054:	92068693          	addi	a3,a3,-1760 # ffffffffc0202970 <commands+0x8b8>
ffffffffc0201058:	00002617          	auipc	a2,0x2
ffffffffc020105c:	82860613          	addi	a2,a2,-2008 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201060:	0d800593          	li	a1,216
ffffffffc0201064:	00002517          	auipc	a0,0x2
ffffffffc0201068:	83450513          	addi	a0,a0,-1996 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020106c:	b62ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201070:	00002697          	auipc	a3,0x2
ffffffffc0201074:	94068693          	addi	a3,a3,-1728 # ffffffffc02029b0 <commands+0x8f8>
ffffffffc0201078:	00002617          	auipc	a2,0x2
ffffffffc020107c:	80860613          	addi	a2,a2,-2040 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201080:	0da00593          	li	a1,218
ffffffffc0201084:	00002517          	auipc	a0,0x2
ffffffffc0201088:	81450513          	addi	a0,a0,-2028 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020108c:	b42ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201090:	00002697          	auipc	a3,0x2
ffffffffc0201094:	9a868693          	addi	a3,a3,-1624 # ffffffffc0202a38 <commands+0x980>
ffffffffc0201098:	00001617          	auipc	a2,0x1
ffffffffc020109c:	7e860613          	addi	a2,a2,2024 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02010a0:	0f300593          	li	a1,243
ffffffffc02010a4:	00001517          	auipc	a0,0x1
ffffffffc02010a8:	7f450513          	addi	a0,a0,2036 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02010ac:	b22ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010b0:	00002697          	auipc	a3,0x2
ffffffffc02010b4:	87868693          	addi	a3,a3,-1928 # ffffffffc0202928 <commands+0x870>
ffffffffc02010b8:	00001617          	auipc	a2,0x1
ffffffffc02010bc:	7c860613          	addi	a2,a2,1992 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02010c0:	0d500593          	li	a1,213
ffffffffc02010c4:	00001517          	auipc	a0,0x1
ffffffffc02010c8:	7d450513          	addi	a0,a0,2004 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02010cc:	b02ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(total == 0);
ffffffffc02010d0:	00002697          	auipc	a3,0x2
ffffffffc02010d4:	a9868693          	addi	a3,a3,-1384 # ffffffffc0202b68 <commands+0xab0>
ffffffffc02010d8:	00001617          	auipc	a2,0x1
ffffffffc02010dc:	7a860613          	addi	a2,a2,1960 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02010e0:	14d00593          	li	a1,333
ffffffffc02010e4:	00001517          	auipc	a0,0x1
ffffffffc02010e8:	7b450513          	addi	a0,a0,1972 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02010ec:	ae2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(total == nr_free_pages());
ffffffffc02010f0:	00001697          	auipc	a3,0x1
ffffffffc02010f4:	7d868693          	addi	a3,a3,2008 # ffffffffc02028c8 <commands+0x810>
ffffffffc02010f8:	00001617          	auipc	a2,0x1
ffffffffc02010fc:	78860613          	addi	a2,a2,1928 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201100:	10e00593          	li	a1,270
ffffffffc0201104:	00001517          	auipc	a0,0x1
ffffffffc0201108:	79450513          	addi	a0,a0,1940 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020110c:	ac2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201110:	00001697          	auipc	a3,0x1
ffffffffc0201114:	7f868693          	addi	a3,a3,2040 # ffffffffc0202908 <commands+0x850>
ffffffffc0201118:	00001617          	auipc	a2,0x1
ffffffffc020111c:	76860613          	addi	a2,a2,1896 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201120:	0d400593          	li	a1,212
ffffffffc0201124:	00001517          	auipc	a0,0x1
ffffffffc0201128:	77450513          	addi	a0,a0,1908 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020112c:	aa2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201130:	00001697          	auipc	a3,0x1
ffffffffc0201134:	7b868693          	addi	a3,a3,1976 # ffffffffc02028e8 <commands+0x830>
ffffffffc0201138:	00001617          	auipc	a2,0x1
ffffffffc020113c:	74860613          	addi	a2,a2,1864 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201140:	0d300593          	li	a1,211
ffffffffc0201144:	00001517          	auipc	a0,0x1
ffffffffc0201148:	75450513          	addi	a0,a0,1876 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020114c:	a82ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201150:	00002697          	auipc	a3,0x2
ffffffffc0201154:	8c068693          	addi	a3,a3,-1856 # ffffffffc0202a10 <commands+0x958>
ffffffffc0201158:	00001617          	auipc	a2,0x1
ffffffffc020115c:	72860613          	addi	a2,a2,1832 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201160:	0f000593          	li	a1,240
ffffffffc0201164:	00001517          	auipc	a0,0x1
ffffffffc0201168:	73450513          	addi	a0,a0,1844 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020116c:	a62ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201170:	00001697          	auipc	a3,0x1
ffffffffc0201174:	7b868693          	addi	a3,a3,1976 # ffffffffc0202928 <commands+0x870>
ffffffffc0201178:	00001617          	auipc	a2,0x1
ffffffffc020117c:	70860613          	addi	a2,a2,1800 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201180:	0ee00593          	li	a1,238
ffffffffc0201184:	00001517          	auipc	a0,0x1
ffffffffc0201188:	71450513          	addi	a0,a0,1812 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020118c:	a42ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201190:	00001697          	auipc	a3,0x1
ffffffffc0201194:	77868693          	addi	a3,a3,1912 # ffffffffc0202908 <commands+0x850>
ffffffffc0201198:	00001617          	auipc	a2,0x1
ffffffffc020119c:	6e860613          	addi	a2,a2,1768 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02011a0:	0ed00593          	li	a1,237
ffffffffc02011a4:	00001517          	auipc	a0,0x1
ffffffffc02011a8:	6f450513          	addi	a0,a0,1780 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02011ac:	a22ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02011b0:	00001697          	auipc	a3,0x1
ffffffffc02011b4:	73868693          	addi	a3,a3,1848 # ffffffffc02028e8 <commands+0x830>
ffffffffc02011b8:	00001617          	auipc	a2,0x1
ffffffffc02011bc:	6c860613          	addi	a2,a2,1736 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02011c0:	0ec00593          	li	a1,236
ffffffffc02011c4:	00001517          	auipc	a0,0x1
ffffffffc02011c8:	6d450513          	addi	a0,a0,1748 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02011cc:	a02ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 3);
ffffffffc02011d0:	00002697          	auipc	a3,0x2
ffffffffc02011d4:	85868693          	addi	a3,a3,-1960 # ffffffffc0202a28 <commands+0x970>
ffffffffc02011d8:	00001617          	auipc	a2,0x1
ffffffffc02011dc:	6a860613          	addi	a2,a2,1704 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02011e0:	0ea00593          	li	a1,234
ffffffffc02011e4:	00001517          	auipc	a0,0x1
ffffffffc02011e8:	6b450513          	addi	a0,a0,1716 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02011ec:	9e2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc02011f0:	00002697          	auipc	a3,0x2
ffffffffc02011f4:	82068693          	addi	a3,a3,-2016 # ffffffffc0202a10 <commands+0x958>
ffffffffc02011f8:	00001617          	auipc	a2,0x1
ffffffffc02011fc:	68860613          	addi	a2,a2,1672 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201200:	0e500593          	li	a1,229
ffffffffc0201204:	00001517          	auipc	a0,0x1
ffffffffc0201208:	69450513          	addi	a0,a0,1684 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020120c:	9c2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201210:	00001697          	auipc	a3,0x1
ffffffffc0201214:	7e068693          	addi	a3,a3,2016 # ffffffffc02029f0 <commands+0x938>
ffffffffc0201218:	00001617          	auipc	a2,0x1
ffffffffc020121c:	66860613          	addi	a2,a2,1640 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201220:	0dc00593          	li	a1,220
ffffffffc0201224:	00001517          	auipc	a0,0x1
ffffffffc0201228:	67450513          	addi	a0,a0,1652 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020122c:	9a2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201230:	00001697          	auipc	a3,0x1
ffffffffc0201234:	7a068693          	addi	a3,a3,1952 # ffffffffc02029d0 <commands+0x918>
ffffffffc0201238:	00001617          	auipc	a2,0x1
ffffffffc020123c:	64860613          	addi	a2,a2,1608 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201240:	0db00593          	li	a1,219
ffffffffc0201244:	00001517          	auipc	a0,0x1
ffffffffc0201248:	65450513          	addi	a0,a0,1620 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020124c:	982ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(count == 0);
ffffffffc0201250:	00002697          	auipc	a3,0x2
ffffffffc0201254:	90868693          	addi	a3,a3,-1784 # ffffffffc0202b58 <commands+0xaa0>
ffffffffc0201258:	00001617          	auipc	a2,0x1
ffffffffc020125c:	62860613          	addi	a2,a2,1576 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201260:	14c00593          	li	a1,332
ffffffffc0201264:	00001517          	auipc	a0,0x1
ffffffffc0201268:	63450513          	addi	a0,a0,1588 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020126c:	962ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 0);
ffffffffc0201270:	00002697          	auipc	a3,0x2
ffffffffc0201274:	80068693          	addi	a3,a3,-2048 # ffffffffc0202a70 <commands+0x9b8>
ffffffffc0201278:	00001617          	auipc	a2,0x1
ffffffffc020127c:	60860613          	addi	a2,a2,1544 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201280:	14100593          	li	a1,321
ffffffffc0201284:	00001517          	auipc	a0,0x1
ffffffffc0201288:	61450513          	addi	a0,a0,1556 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020128c:	942ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201290:	00001697          	auipc	a3,0x1
ffffffffc0201294:	78068693          	addi	a3,a3,1920 # ffffffffc0202a10 <commands+0x958>
ffffffffc0201298:	00001617          	auipc	a2,0x1
ffffffffc020129c:	5e860613          	addi	a2,a2,1512 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02012a0:	13b00593          	li	a1,315
ffffffffc02012a4:	00001517          	auipc	a0,0x1
ffffffffc02012a8:	5f450513          	addi	a0,a0,1524 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02012ac:	922ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02012b0:	00002697          	auipc	a3,0x2
ffffffffc02012b4:	88868693          	addi	a3,a3,-1912 # ffffffffc0202b38 <commands+0xa80>
ffffffffc02012b8:	00001617          	auipc	a2,0x1
ffffffffc02012bc:	5c860613          	addi	a2,a2,1480 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02012c0:	13a00593          	li	a1,314
ffffffffc02012c4:	00001517          	auipc	a0,0x1
ffffffffc02012c8:	5d450513          	addi	a0,a0,1492 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02012cc:	902ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 + 4 == p1);
ffffffffc02012d0:	00002697          	auipc	a3,0x2
ffffffffc02012d4:	85868693          	addi	a3,a3,-1960 # ffffffffc0202b28 <commands+0xa70>
ffffffffc02012d8:	00001617          	auipc	a2,0x1
ffffffffc02012dc:	5a860613          	addi	a2,a2,1448 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02012e0:	13200593          	li	a1,306
ffffffffc02012e4:	00001517          	auipc	a0,0x1
ffffffffc02012e8:	5b450513          	addi	a0,a0,1460 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02012ec:	8e2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02012f0:	00002697          	auipc	a3,0x2
ffffffffc02012f4:	82068693          	addi	a3,a3,-2016 # ffffffffc0202b10 <commands+0xa58>
ffffffffc02012f8:	00001617          	auipc	a2,0x1
ffffffffc02012fc:	58860613          	addi	a2,a2,1416 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201300:	13100593          	li	a1,305
ffffffffc0201304:	00001517          	auipc	a0,0x1
ffffffffc0201308:	59450513          	addi	a0,a0,1428 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020130c:	8c2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0201310:	00001697          	auipc	a3,0x1
ffffffffc0201314:	7e068693          	addi	a3,a3,2016 # ffffffffc0202af0 <commands+0xa38>
ffffffffc0201318:	00001617          	auipc	a2,0x1
ffffffffc020131c:	56860613          	addi	a2,a2,1384 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201320:	13000593          	li	a1,304
ffffffffc0201324:	00001517          	auipc	a0,0x1
ffffffffc0201328:	57450513          	addi	a0,a0,1396 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020132c:	8a2ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0201330:	00001697          	auipc	a3,0x1
ffffffffc0201334:	79068693          	addi	a3,a3,1936 # ffffffffc0202ac0 <commands+0xa08>
ffffffffc0201338:	00001617          	auipc	a2,0x1
ffffffffc020133c:	54860613          	addi	a2,a2,1352 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201340:	12e00593          	li	a1,302
ffffffffc0201344:	00001517          	auipc	a0,0x1
ffffffffc0201348:	55450513          	addi	a0,a0,1364 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020134c:	882ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201350:	00001697          	auipc	a3,0x1
ffffffffc0201354:	75868693          	addi	a3,a3,1880 # ffffffffc0202aa8 <commands+0x9f0>
ffffffffc0201358:	00001617          	auipc	a2,0x1
ffffffffc020135c:	52860613          	addi	a2,a2,1320 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201360:	12d00593          	li	a1,301
ffffffffc0201364:	00001517          	auipc	a0,0x1
ffffffffc0201368:	53450513          	addi	a0,a0,1332 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020136c:	862ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201370:	00001697          	auipc	a3,0x1
ffffffffc0201374:	6a068693          	addi	a3,a3,1696 # ffffffffc0202a10 <commands+0x958>
ffffffffc0201378:	00001617          	auipc	a2,0x1
ffffffffc020137c:	50860613          	addi	a2,a2,1288 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201380:	12100593          	li	a1,289
ffffffffc0201384:	00001517          	auipc	a0,0x1
ffffffffc0201388:	51450513          	addi	a0,a0,1300 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020138c:	842ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(!PageProperty(p0));
ffffffffc0201390:	00001697          	auipc	a3,0x1
ffffffffc0201394:	70068693          	addi	a3,a3,1792 # ffffffffc0202a90 <commands+0x9d8>
ffffffffc0201398:	00001617          	auipc	a2,0x1
ffffffffc020139c:	4e860613          	addi	a2,a2,1256 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02013a0:	11800593          	li	a1,280
ffffffffc02013a4:	00001517          	auipc	a0,0x1
ffffffffc02013a8:	4f450513          	addi	a0,a0,1268 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02013ac:	822ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(p0 != NULL);
ffffffffc02013b0:	00001697          	auipc	a3,0x1
ffffffffc02013b4:	6d068693          	addi	a3,a3,1744 # ffffffffc0202a80 <commands+0x9c8>
ffffffffc02013b8:	00001617          	auipc	a2,0x1
ffffffffc02013bc:	4c860613          	addi	a2,a2,1224 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02013c0:	11700593          	li	a1,279
ffffffffc02013c4:	00001517          	auipc	a0,0x1
ffffffffc02013c8:	4d450513          	addi	a0,a0,1236 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02013cc:	802ff0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(nr_free == 0);
ffffffffc02013d0:	00001697          	auipc	a3,0x1
ffffffffc02013d4:	6a068693          	addi	a3,a3,1696 # ffffffffc0202a70 <commands+0x9b8>
ffffffffc02013d8:	00001617          	auipc	a2,0x1
ffffffffc02013dc:	4a860613          	addi	a2,a2,1192 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02013e0:	0f900593          	li	a1,249
ffffffffc02013e4:	00001517          	auipc	a0,0x1
ffffffffc02013e8:	4b450513          	addi	a0,a0,1204 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02013ec:	fe3fe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013f0:	00001697          	auipc	a3,0x1
ffffffffc02013f4:	62068693          	addi	a3,a3,1568 # ffffffffc0202a10 <commands+0x958>
ffffffffc02013f8:	00001617          	auipc	a2,0x1
ffffffffc02013fc:	48860613          	addi	a2,a2,1160 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201400:	0f700593          	li	a1,247
ffffffffc0201404:	00001517          	auipc	a0,0x1
ffffffffc0201408:	49450513          	addi	a0,a0,1172 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020140c:	fc3fe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201410:	00001697          	auipc	a3,0x1
ffffffffc0201414:	64068693          	addi	a3,a3,1600 # ffffffffc0202a50 <commands+0x998>
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	46860613          	addi	a2,a2,1128 # ffffffffc0202880 <commands+0x7c8>
ffffffffc0201420:	0f600593          	li	a1,246
ffffffffc0201424:	00001517          	auipc	a0,0x1
ffffffffc0201428:	47450513          	addi	a0,a0,1140 # ffffffffc0202898 <commands+0x7e0>
ffffffffc020142c:	fa3fe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc0201430 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0201430:	1141                	addi	sp,sp,-16
ffffffffc0201432:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201434:	18058063          	beqz	a1,ffffffffc02015b4 <best_fit_free_pages+0x184>
    for (; p != base + n; p ++) {
ffffffffc0201438:	00259693          	slli	a3,a1,0x2
ffffffffc020143c:	96ae                	add	a3,a3,a1
ffffffffc020143e:	068e                	slli	a3,a3,0x3
ffffffffc0201440:	96aa                	add	a3,a3,a0
ffffffffc0201442:	02d50d63          	beq	a0,a3,ffffffffc020147c <best_fit_free_pages+0x4c>
ffffffffc0201446:	651c                	ld	a5,8(a0)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201448:	8b85                	andi	a5,a5,1
ffffffffc020144a:	14079563          	bnez	a5,ffffffffc0201594 <best_fit_free_pages+0x164>
ffffffffc020144e:	651c                	ld	a5,8(a0)
ffffffffc0201450:	8385                	srli	a5,a5,0x1
ffffffffc0201452:	8b85                	andi	a5,a5,1
ffffffffc0201454:	14079063          	bnez	a5,ffffffffc0201594 <best_fit_free_pages+0x164>
ffffffffc0201458:	87aa                	mv	a5,a0
ffffffffc020145a:	a809                	j	ffffffffc020146c <best_fit_free_pages+0x3c>
ffffffffc020145c:	6798                	ld	a4,8(a5)
ffffffffc020145e:	8b05                	andi	a4,a4,1
ffffffffc0201460:	12071a63          	bnez	a4,ffffffffc0201594 <best_fit_free_pages+0x164>
ffffffffc0201464:	6798                	ld	a4,8(a5)
ffffffffc0201466:	8b09                	andi	a4,a4,2
ffffffffc0201468:	12071663          	bnez	a4,ffffffffc0201594 <best_fit_free_pages+0x164>
        p->flags = 0;
ffffffffc020146c:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201470:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201474:	02878793          	addi	a5,a5,40
ffffffffc0201478:	fed792e3          	bne	a5,a3,ffffffffc020145c <best_fit_free_pages+0x2c>
    base->property = n;
ffffffffc020147c:	2581                	sext.w	a1,a1
ffffffffc020147e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201480:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201484:	4789                	li	a5,2
ffffffffc0201486:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020148a:	00005697          	auipc	a3,0x5
ffffffffc020148e:	b9e68693          	addi	a3,a3,-1122 # ffffffffc0206028 <edata>
ffffffffc0201492:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201494:	669c                	ld	a5,8(a3)
ffffffffc0201496:	9db9                	addw	a1,a1,a4
ffffffffc0201498:	00005717          	auipc	a4,0x5
ffffffffc020149c:	bab72023          	sw	a1,-1120(a4) # ffffffffc0206038 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc02014a0:	08d78f63          	beq	a5,a3,ffffffffc020153e <best_fit_free_pages+0x10e>
            struct Page* page = le2page(le, page_link);
ffffffffc02014a4:	fe878713          	addi	a4,a5,-24
ffffffffc02014a8:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02014aa:	4801                	li	a6,0
ffffffffc02014ac:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02014b0:	00e56a63          	bltu	a0,a4,ffffffffc02014c4 <best_fit_free_pages+0x94>
    return listelm->next;
ffffffffc02014b4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02014b6:	02d70563          	beq	a4,a3,ffffffffc02014e0 <best_fit_free_pages+0xb0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014ba:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02014bc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02014c0:	fee57ae3          	bgeu	a0,a4,ffffffffc02014b4 <best_fit_free_pages+0x84>
ffffffffc02014c4:	00080663          	beqz	a6,ffffffffc02014d0 <best_fit_free_pages+0xa0>
ffffffffc02014c8:	00005817          	auipc	a6,0x5
ffffffffc02014cc:	b6b83023          	sd	a1,-1184(a6) # ffffffffc0206028 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02014d0:	638c                	ld	a1,0(a5)
    prev->next = next->prev = elm;
ffffffffc02014d2:	e390                	sd	a2,0(a5)
ffffffffc02014d4:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02014d6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02014d8:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc02014da:	02d59163          	bne	a1,a3,ffffffffc02014fc <best_fit_free_pages+0xcc>
ffffffffc02014de:	a091                	j	ffffffffc0201522 <best_fit_free_pages+0xf2>
    prev->next = next->prev = elm;
ffffffffc02014e0:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02014e2:	f114                	sd	a3,32(a0)
ffffffffc02014e4:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02014e6:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02014e8:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc02014ea:	00d70563          	beq	a4,a3,ffffffffc02014f4 <best_fit_free_pages+0xc4>
ffffffffc02014ee:	4805                	li	a6,1
ffffffffc02014f0:	87ba                	mv	a5,a4
ffffffffc02014f2:	b7e9                	j	ffffffffc02014bc <best_fit_free_pages+0x8c>
ffffffffc02014f4:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc02014f6:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc02014f8:	02d78163          	beq	a5,a3,ffffffffc020151a <best_fit_free_pages+0xea>
        if (p + p->property == base) {
ffffffffc02014fc:	ff85a803          	lw	a6,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201500:	fe858613          	addi	a2,a1,-24
        if (p + p->property == base) {
ffffffffc0201504:	02081713          	slli	a4,a6,0x20
ffffffffc0201508:	9301                	srli	a4,a4,0x20
ffffffffc020150a:	00271793          	slli	a5,a4,0x2
ffffffffc020150e:	97ba                	add	a5,a5,a4
ffffffffc0201510:	078e                	slli	a5,a5,0x3
ffffffffc0201512:	97b2                	add	a5,a5,a2
ffffffffc0201514:	02f50e63          	beq	a0,a5,ffffffffc0201550 <best_fit_free_pages+0x120>
ffffffffc0201518:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc020151a:	fe878713          	addi	a4,a5,-24
ffffffffc020151e:	00d78d63          	beq	a5,a3,ffffffffc0201538 <best_fit_free_pages+0x108>
        if (base + base->property == p) {
ffffffffc0201522:	490c                	lw	a1,16(a0)
ffffffffc0201524:	02059613          	slli	a2,a1,0x20
ffffffffc0201528:	9201                	srli	a2,a2,0x20
ffffffffc020152a:	00261693          	slli	a3,a2,0x2
ffffffffc020152e:	96b2                	add	a3,a3,a2
ffffffffc0201530:	068e                	slli	a3,a3,0x3
ffffffffc0201532:	96aa                	add	a3,a3,a0
ffffffffc0201534:	04d70063          	beq	a4,a3,ffffffffc0201574 <best_fit_free_pages+0x144>
}
ffffffffc0201538:	60a2                	ld	ra,8(sp)
ffffffffc020153a:	0141                	addi	sp,sp,16
ffffffffc020153c:	8082                	ret
ffffffffc020153e:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201540:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201544:	e398                	sd	a4,0(a5)
ffffffffc0201546:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201548:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020154a:	ed1c                	sd	a5,24(a0)
}
ffffffffc020154c:	0141                	addi	sp,sp,16
ffffffffc020154e:	8082                	ret
            p->property += base->property;
ffffffffc0201550:	491c                	lw	a5,16(a0)
ffffffffc0201552:	0107883b          	addw	a6,a5,a6
ffffffffc0201556:	ff05ac23          	sw	a6,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020155a:	57f5                	li	a5,-3
ffffffffc020155c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201560:	01853803          	ld	a6,24(a0)
ffffffffc0201564:	7118                	ld	a4,32(a0)
            base = p;  // 更新base指针，以便继续检查后面的块
ffffffffc0201566:	8532                	mv	a0,a2
    prev->next = next;
ffffffffc0201568:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc020156c:	659c                	ld	a5,8(a1)
ffffffffc020156e:	01073023          	sd	a6,0(a4)
ffffffffc0201572:	b765                	j	ffffffffc020151a <best_fit_free_pages+0xea>
            base->property += p->property;
ffffffffc0201574:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201578:	ff078693          	addi	a3,a5,-16
ffffffffc020157c:	9db9                	addw	a1,a1,a4
ffffffffc020157e:	c90c                	sw	a1,16(a0)
ffffffffc0201580:	5775                	li	a4,-3
ffffffffc0201582:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201586:	6398                	ld	a4,0(a5)
ffffffffc0201588:	679c                	ld	a5,8(a5)
}
ffffffffc020158a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020158c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020158e:	e398                	sd	a4,0(a5)
ffffffffc0201590:	0141                	addi	sp,sp,16
ffffffffc0201592:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201594:	00001697          	auipc	a3,0x1
ffffffffc0201598:	5e468693          	addi	a3,a3,1508 # ffffffffc0202b78 <commands+0xac0>
ffffffffc020159c:	00001617          	auipc	a2,0x1
ffffffffc02015a0:	2e460613          	addi	a2,a2,740 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02015a4:	09a00593          	li	a1,154
ffffffffc02015a8:	00001517          	auipc	a0,0x1
ffffffffc02015ac:	2f050513          	addi	a0,a0,752 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02015b0:	e1ffe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(n > 0);
ffffffffc02015b4:	00001697          	auipc	a3,0x1
ffffffffc02015b8:	2c468693          	addi	a3,a3,708 # ffffffffc0202878 <commands+0x7c0>
ffffffffc02015bc:	00001617          	auipc	a2,0x1
ffffffffc02015c0:	2c460613          	addi	a2,a2,708 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02015c4:	09700593          	li	a1,151
ffffffffc02015c8:	00001517          	auipc	a0,0x1
ffffffffc02015cc:	2d050513          	addi	a0,a0,720 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02015d0:	dfffe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc02015d4 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc02015d4:	1141                	addi	sp,sp,-16
ffffffffc02015d6:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02015d8:	c1fd                	beqz	a1,ffffffffc02016be <best_fit_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc02015da:	00259693          	slli	a3,a1,0x2
ffffffffc02015de:	96ae                	add	a3,a3,a1
ffffffffc02015e0:	068e                	slli	a3,a3,0x3
ffffffffc02015e2:	96aa                	add	a3,a3,a0
ffffffffc02015e4:	02d50463          	beq	a0,a3,ffffffffc020160c <best_fit_init_memmap+0x38>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02015e8:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02015ea:	87aa                	mv	a5,a0
ffffffffc02015ec:	8b05                	andi	a4,a4,1
ffffffffc02015ee:	e709                	bnez	a4,ffffffffc02015f8 <best_fit_init_memmap+0x24>
ffffffffc02015f0:	a07d                	j	ffffffffc020169e <best_fit_init_memmap+0xca>
ffffffffc02015f2:	6798                	ld	a4,8(a5)
ffffffffc02015f4:	8b05                	andi	a4,a4,1
ffffffffc02015f6:	c745                	beqz	a4,ffffffffc020169e <best_fit_init_memmap+0xca>
        p->flags = 0;
ffffffffc02015f8:	0007b423          	sd	zero,8(a5)
ffffffffc02015fc:	0007a023          	sw	zero,0(a5)
        p->property = 0;//非空闲块起始页的块大小设为0
ffffffffc0201600:	0007a823          	sw	zero,16(a5)
    for (; p != base + n; p ++) {
ffffffffc0201604:	02878793          	addi	a5,a5,40
ffffffffc0201608:	fed795e3          	bne	a5,a3,ffffffffc02015f2 <best_fit_init_memmap+0x1e>
    base->property = n;
ffffffffc020160c:	2581                	sext.w	a1,a1
ffffffffc020160e:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201610:	4789                	li	a5,2
ffffffffc0201612:	00850713          	addi	a4,a0,8
ffffffffc0201616:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc020161a:	00005697          	auipc	a3,0x5
ffffffffc020161e:	a0e68693          	addi	a3,a3,-1522 # ffffffffc0206028 <edata>
ffffffffc0201622:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc0201624:	669c                	ld	a5,8(a3)
ffffffffc0201626:	9db9                	addw	a1,a1,a4
ffffffffc0201628:	00005717          	auipc	a4,0x5
ffffffffc020162c:	a0b72823          	sw	a1,-1520(a4) # ffffffffc0206038 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc0201630:	04d78a63          	beq	a5,a3,ffffffffc0201684 <best_fit_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0201634:	fe878713          	addi	a4,a5,-24
ffffffffc0201638:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc020163a:	4801                	li	a6,0
ffffffffc020163c:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201640:	00e56a63          	bltu	a0,a4,ffffffffc0201654 <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc0201644:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0201646:	02d70563          	beq	a4,a3,ffffffffc0201670 <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc020164a:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020164c:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201650:	fee57ae3          	bgeu	a0,a4,ffffffffc0201644 <best_fit_init_memmap+0x70>
ffffffffc0201654:	00080663          	beqz	a6,ffffffffc0201660 <best_fit_init_memmap+0x8c>
ffffffffc0201658:	00005717          	auipc	a4,0x5
ffffffffc020165c:	9cb73823          	sd	a1,-1584(a4) # ffffffffc0206028 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201660:	6398                	ld	a4,0(a5)
}
ffffffffc0201662:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201664:	e390                	sd	a2,0(a5)
ffffffffc0201666:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201668:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020166a:	ed18                	sd	a4,24(a0)
ffffffffc020166c:	0141                	addi	sp,sp,16
ffffffffc020166e:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201670:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201672:	f114                	sd	a3,32(a0)
ffffffffc0201674:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201676:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0201678:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020167a:	00d70e63          	beq	a4,a3,ffffffffc0201696 <best_fit_init_memmap+0xc2>
ffffffffc020167e:	4805                	li	a6,1
ffffffffc0201680:	87ba                	mv	a5,a4
ffffffffc0201682:	b7e9                	j	ffffffffc020164c <best_fit_init_memmap+0x78>
}
ffffffffc0201684:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201686:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc020168a:	e398                	sd	a4,0(a5)
ffffffffc020168c:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020168e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201690:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201692:	0141                	addi	sp,sp,16
ffffffffc0201694:	8082                	ret
ffffffffc0201696:	60a2                	ld	ra,8(sp)
ffffffffc0201698:	e290                	sd	a2,0(a3)
ffffffffc020169a:	0141                	addi	sp,sp,16
ffffffffc020169c:	8082                	ret
        assert(PageReserved(p));
ffffffffc020169e:	00001697          	auipc	a3,0x1
ffffffffc02016a2:	50268693          	addi	a3,a3,1282 # ffffffffc0202ba0 <commands+0xae8>
ffffffffc02016a6:	00001617          	auipc	a2,0x1
ffffffffc02016aa:	1da60613          	addi	a2,a2,474 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02016ae:	04a00593          	li	a1,74
ffffffffc02016b2:	00001517          	auipc	a0,0x1
ffffffffc02016b6:	1e650513          	addi	a0,a0,486 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02016ba:	d15fe0ef          	jal	ra,ffffffffc02003ce <__panic>
    assert(n > 0);
ffffffffc02016be:	00001697          	auipc	a3,0x1
ffffffffc02016c2:	1ba68693          	addi	a3,a3,442 # ffffffffc0202878 <commands+0x7c0>
ffffffffc02016c6:	00001617          	auipc	a2,0x1
ffffffffc02016ca:	1ba60613          	addi	a2,a2,442 # ffffffffc0202880 <commands+0x7c8>
ffffffffc02016ce:	04700593          	li	a1,71
ffffffffc02016d2:	00001517          	auipc	a0,0x1
ffffffffc02016d6:	1c650513          	addi	a0,a0,454 # ffffffffc0202898 <commands+0x7e0>
ffffffffc02016da:	cf5fe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc02016de <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02016de:	100027f3          	csrr	a5,sstatus
ffffffffc02016e2:	8b89                	andi	a5,a5,2
ffffffffc02016e4:	eb89                	bnez	a5,ffffffffc02016f6 <alloc_pages+0x18>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc02016e6:	00005797          	auipc	a5,0x5
ffffffffc02016ea:	da278793          	addi	a5,a5,-606 # ffffffffc0206488 <pmm_manager>
ffffffffc02016ee:	639c                	ld	a5,0(a5)
ffffffffc02016f0:	0187b303          	ld	t1,24(a5)
ffffffffc02016f4:	8302                	jr	t1
struct Page *alloc_pages(size_t n) {
ffffffffc02016f6:	1141                	addi	sp,sp,-16
ffffffffc02016f8:	e406                	sd	ra,8(sp)
ffffffffc02016fa:	e022                	sd	s0,0(sp)
ffffffffc02016fc:	842a                	mv	s0,a0
        intr_disable();
ffffffffc02016fe:	8eaff0ef          	jal	ra,ffffffffc02007e8 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201702:	00005797          	auipc	a5,0x5
ffffffffc0201706:	d8678793          	addi	a5,a5,-634 # ffffffffc0206488 <pmm_manager>
ffffffffc020170a:	639c                	ld	a5,0(a5)
ffffffffc020170c:	8522                	mv	a0,s0
ffffffffc020170e:	6f9c                	ld	a5,24(a5)
ffffffffc0201710:	9782                	jalr	a5
ffffffffc0201712:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc0201714:	8ceff0ef          	jal	ra,ffffffffc02007e2 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201718:	8522                	mv	a0,s0
ffffffffc020171a:	60a2                	ld	ra,8(sp)
ffffffffc020171c:	6402                	ld	s0,0(sp)
ffffffffc020171e:	0141                	addi	sp,sp,16
ffffffffc0201720:	8082                	ret

ffffffffc0201722 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201722:	100027f3          	csrr	a5,sstatus
ffffffffc0201726:	8b89                	andi	a5,a5,2
ffffffffc0201728:	eb89                	bnez	a5,ffffffffc020173a <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc020172a:	00005797          	auipc	a5,0x5
ffffffffc020172e:	d5e78793          	addi	a5,a5,-674 # ffffffffc0206488 <pmm_manager>
ffffffffc0201732:	639c                	ld	a5,0(a5)
ffffffffc0201734:	0207b303          	ld	t1,32(a5)
ffffffffc0201738:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc020173a:	1101                	addi	sp,sp,-32
ffffffffc020173c:	ec06                	sd	ra,24(sp)
ffffffffc020173e:	e822                	sd	s0,16(sp)
ffffffffc0201740:	e426                	sd	s1,8(sp)
ffffffffc0201742:	842a                	mv	s0,a0
ffffffffc0201744:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201746:	8a2ff0ef          	jal	ra,ffffffffc02007e8 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020174a:	00005797          	auipc	a5,0x5
ffffffffc020174e:	d3e78793          	addi	a5,a5,-706 # ffffffffc0206488 <pmm_manager>
ffffffffc0201752:	639c                	ld	a5,0(a5)
ffffffffc0201754:	85a6                	mv	a1,s1
ffffffffc0201756:	8522                	mv	a0,s0
ffffffffc0201758:	739c                	ld	a5,32(a5)
ffffffffc020175a:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc020175c:	6442                	ld	s0,16(sp)
ffffffffc020175e:	60e2                	ld	ra,24(sp)
ffffffffc0201760:	64a2                	ld	s1,8(sp)
ffffffffc0201762:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201764:	87eff06f          	j	ffffffffc02007e2 <intr_enable>

ffffffffc0201768 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201768:	100027f3          	csrr	a5,sstatus
ffffffffc020176c:	8b89                	andi	a5,a5,2
ffffffffc020176e:	eb89                	bnez	a5,ffffffffc0201780 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201770:	00005797          	auipc	a5,0x5
ffffffffc0201774:	d1878793          	addi	a5,a5,-744 # ffffffffc0206488 <pmm_manager>
ffffffffc0201778:	639c                	ld	a5,0(a5)
ffffffffc020177a:	0287b303          	ld	t1,40(a5)
ffffffffc020177e:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201780:	1141                	addi	sp,sp,-16
ffffffffc0201782:	e406                	sd	ra,8(sp)
ffffffffc0201784:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201786:	862ff0ef          	jal	ra,ffffffffc02007e8 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc020178a:	00005797          	auipc	a5,0x5
ffffffffc020178e:	cfe78793          	addi	a5,a5,-770 # ffffffffc0206488 <pmm_manager>
ffffffffc0201792:	639c                	ld	a5,0(a5)
ffffffffc0201794:	779c                	ld	a5,40(a5)
ffffffffc0201796:	9782                	jalr	a5
ffffffffc0201798:	842a                	mv	s0,a0
        intr_enable();
ffffffffc020179a:	848ff0ef          	jal	ra,ffffffffc02007e2 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc020179e:	8522                	mv	a0,s0
ffffffffc02017a0:	60a2                	ld	ra,8(sp)
ffffffffc02017a2:	6402                	ld	s0,0(sp)
ffffffffc02017a4:	0141                	addi	sp,sp,16
ffffffffc02017a6:	8082                	ret

ffffffffc02017a8 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017a8:	00001797          	auipc	a5,0x1
ffffffffc02017ac:	40878793          	addi	a5,a5,1032 # ffffffffc0202bb0 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017b0:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc02017b2:	7179                	addi	sp,sp,-48
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017b4:	00001517          	auipc	a0,0x1
ffffffffc02017b8:	44c50513          	addi	a0,a0,1100 # ffffffffc0202c00 <best_fit_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc02017bc:	f406                	sd	ra,40(sp)
ffffffffc02017be:	f022                	sd	s0,32(sp)
ffffffffc02017c0:	e84a                	sd	s2,16(sp)
ffffffffc02017c2:	ec26                	sd	s1,24(sp)
ffffffffc02017c4:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc02017c6:	00005717          	auipc	a4,0x5
ffffffffc02017ca:	ccf73123          	sd	a5,-830(a4) # ffffffffc0206488 <pmm_manager>
ffffffffc02017ce:	00005417          	auipc	s0,0x5
ffffffffc02017d2:	cba40413          	addi	s0,s0,-838 # ffffffffc0206488 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc02017d6:	907fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    pmm_manager->init();
ffffffffc02017da:	601c                	ld	a5,0(s0)
ffffffffc02017dc:	679c                	ld	a5,8(a5)
ffffffffc02017de:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc02017e0:	57f5                	li	a5,-3
ffffffffc02017e2:	07fa                	slli	a5,a5,0x1e
ffffffffc02017e4:	00005717          	auipc	a4,0x5
ffffffffc02017e8:	caf73623          	sd	a5,-852(a4) # ffffffffc0206490 <va_pa_offset>
    uint64_t mem_begin = get_memory_base();
ffffffffc02017ec:	fdffe0ef          	jal	ra,ffffffffc02007ca <get_memory_base>
ffffffffc02017f0:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc02017f2:	fe5fe0ef          	jal	ra,ffffffffc02007d6 <get_memory_size>
    if (mem_size == 0) {
ffffffffc02017f6:	14050f63          	beqz	a0,ffffffffc0201954 <pmm_init+0x1ac>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02017fa:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02017fc:	00001517          	auipc	a0,0x1
ffffffffc0201800:	44c50513          	addi	a0,a0,1100 # ffffffffc0202c48 <best_fit_pmm_manager+0x98>
ffffffffc0201804:	8d9fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201808:	009909b3          	add	s3,s2,s1
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc020180c:	fff98693          	addi	a3,s3,-1
ffffffffc0201810:	864a                	mv	a2,s2
ffffffffc0201812:	85a6                	mv	a1,s1
ffffffffc0201814:	00001517          	auipc	a0,0x1
ffffffffc0201818:	44c50513          	addi	a0,a0,1100 # ffffffffc0202c60 <best_fit_pmm_manager+0xb0>
ffffffffc020181c:	8c1fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201820:	c80007b7          	lui	a5,0xc8000
ffffffffc0201824:	874e                	mv	a4,s3
ffffffffc0201826:	0f37e263          	bltu	a5,s3,ffffffffc020190a <pmm_init+0x162>
ffffffffc020182a:	00006797          	auipc	a5,0x6
ffffffffc020182e:	c7578793          	addi	a5,a5,-907 # ffffffffc020749f <end+0xfff>
ffffffffc0201832:	757d                	lui	a0,0xfffff
ffffffffc0201834:	8331                	srli	a4,a4,0xc
ffffffffc0201836:	8fe9                	and	a5,a5,a0
ffffffffc0201838:	00005697          	auipc	a3,0x5
ffffffffc020183c:	c2e6b423          	sd	a4,-984(a3) # ffffffffc0206460 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201840:	00005697          	auipc	a3,0x5
ffffffffc0201844:	c4f6bc23          	sd	a5,-936(a3) # ffffffffc0206498 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201848:	000806b7          	lui	a3,0x80
ffffffffc020184c:	02d70f63          	beq	a4,a3,ffffffffc020188a <pmm_init+0xe2>
ffffffffc0201850:	4601                	li	a2,0
ffffffffc0201852:	4681                	li	a3,0
ffffffffc0201854:	00005897          	auipc	a7,0x5
ffffffffc0201858:	c0c88893          	addi	a7,a7,-1012 # ffffffffc0206460 <npage>
ffffffffc020185c:	00005597          	auipc	a1,0x5
ffffffffc0201860:	c3c58593          	addi	a1,a1,-964 # ffffffffc0206498 <pages>
ffffffffc0201864:	4805                	li	a6,1
ffffffffc0201866:	fff80537          	lui	a0,0xfff80
ffffffffc020186a:	a011                	j	ffffffffc020186e <pmm_init+0xc6>
ffffffffc020186c:	619c                	ld	a5,0(a1)
        SetPageReserved(pages + i);
ffffffffc020186e:	97b2                	add	a5,a5,a2
ffffffffc0201870:	07a1                	addi	a5,a5,8
ffffffffc0201872:	4107b02f          	amoor.d	zero,a6,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201876:	0008b703          	ld	a4,0(a7)
ffffffffc020187a:	0685                	addi	a3,a3,1
ffffffffc020187c:	02860613          	addi	a2,a2,40
ffffffffc0201880:	00a707b3          	add	a5,a4,a0
ffffffffc0201884:	fef6e4e3          	bltu	a3,a5,ffffffffc020186c <pmm_init+0xc4>
ffffffffc0201888:	619c                	ld	a5,0(a1)
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020188a:	00271693          	slli	a3,a4,0x2
ffffffffc020188e:	96ba                	add	a3,a3,a4
ffffffffc0201890:	fec00637          	lui	a2,0xfec00
ffffffffc0201894:	963e                	add	a2,a2,a5
ffffffffc0201896:	068e                	slli	a3,a3,0x3
ffffffffc0201898:	96b2                	add	a3,a3,a2
ffffffffc020189a:	c0200637          	lui	a2,0xc0200
ffffffffc020189e:	08c6ef63          	bltu	a3,a2,ffffffffc020193c <pmm_init+0x194>
ffffffffc02018a2:	00005497          	auipc	s1,0x5
ffffffffc02018a6:	bee48493          	addi	s1,s1,-1042 # ffffffffc0206490 <va_pa_offset>
ffffffffc02018aa:	6088                	ld	a0,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc02018ac:	767d                	lui	a2,0xfffff
ffffffffc02018ae:	00c9f5b3          	and	a1,s3,a2
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02018b2:	8e89                	sub	a3,a3,a0
    if (freemem < mem_end) {
ffffffffc02018b4:	04b6ee63          	bltu	a3,a1,ffffffffc0201910 <pmm_init+0x168>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc02018b8:	601c                	ld	a5,0(s0)
ffffffffc02018ba:	7b9c                	ld	a5,48(a5)
ffffffffc02018bc:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc02018be:	00001517          	auipc	a0,0x1
ffffffffc02018c2:	42a50513          	addi	a0,a0,1066 # ffffffffc0202ce8 <best_fit_pmm_manager+0x138>
ffffffffc02018c6:	817fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc02018ca:	00003697          	auipc	a3,0x3
ffffffffc02018ce:	73668693          	addi	a3,a3,1846 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc02018d2:	00005797          	auipc	a5,0x5
ffffffffc02018d6:	b8d7bb23          	sd	a3,-1130(a5) # ffffffffc0206468 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc02018da:	c02007b7          	lui	a5,0xc0200
ffffffffc02018de:	08f6e763          	bltu	a3,a5,ffffffffc020196c <pmm_init+0x1c4>
ffffffffc02018e2:	609c                	ld	a5,0(s1)
}
ffffffffc02018e4:	7402                	ld	s0,32(sp)
ffffffffc02018e6:	70a2                	ld	ra,40(sp)
ffffffffc02018e8:	64e2                	ld	s1,24(sp)
ffffffffc02018ea:	6942                	ld	s2,16(sp)
ffffffffc02018ec:	69a2                	ld	s3,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018ee:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc02018f0:	8e9d                	sub	a3,a3,a5
ffffffffc02018f2:	00005797          	auipc	a5,0x5
ffffffffc02018f6:	b8d7b723          	sd	a3,-1138(a5) # ffffffffc0206480 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc02018fa:	00001517          	auipc	a0,0x1
ffffffffc02018fe:	40e50513          	addi	a0,a0,1038 # ffffffffc0202d08 <best_fit_pmm_manager+0x158>
ffffffffc0201902:	8636                	mv	a2,a3
}
ffffffffc0201904:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201906:	fd6fe06f          	j	ffffffffc02000dc <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020190a:	c8000737          	lui	a4,0xc8000
ffffffffc020190e:	bf31                	j	ffffffffc020182a <pmm_init+0x82>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201910:	6505                	lui	a0,0x1
ffffffffc0201912:	157d                	addi	a0,a0,-1
ffffffffc0201914:	96aa                	add	a3,a3,a0
ffffffffc0201916:	8ef1                	and	a3,a3,a2
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201918:	00c6d513          	srli	a0,a3,0xc
ffffffffc020191c:	06e57463          	bgeu	a0,a4,ffffffffc0201984 <pmm_init+0x1dc>
    pmm_manager->init_memmap(base, n);
ffffffffc0201920:	6010                	ld	a2,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201922:	fff80737          	lui	a4,0xfff80
ffffffffc0201926:	972a                	add	a4,a4,a0
ffffffffc0201928:	00271513          	slli	a0,a4,0x2
ffffffffc020192c:	953a                	add	a0,a0,a4
ffffffffc020192e:	6a18                	ld	a4,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0201930:	8d95                	sub	a1,a1,a3
ffffffffc0201932:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201934:	81b1                	srli	a1,a1,0xc
ffffffffc0201936:	953e                	add	a0,a0,a5
ffffffffc0201938:	9702                	jalr	a4
ffffffffc020193a:	bfbd                	j	ffffffffc02018b8 <pmm_init+0x110>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020193c:	00001617          	auipc	a2,0x1
ffffffffc0201940:	35460613          	addi	a2,a2,852 # ffffffffc0202c90 <best_fit_pmm_manager+0xe0>
ffffffffc0201944:	07100593          	li	a1,113
ffffffffc0201948:	00001517          	auipc	a0,0x1
ffffffffc020194c:	2f050513          	addi	a0,a0,752 # ffffffffc0202c38 <best_fit_pmm_manager+0x88>
ffffffffc0201950:	a7ffe0ef          	jal	ra,ffffffffc02003ce <__panic>
        panic("DTB memory info not available");
ffffffffc0201954:	00001617          	auipc	a2,0x1
ffffffffc0201958:	2c460613          	addi	a2,a2,708 # ffffffffc0202c18 <best_fit_pmm_manager+0x68>
ffffffffc020195c:	05a00593          	li	a1,90
ffffffffc0201960:	00001517          	auipc	a0,0x1
ffffffffc0201964:	2d850513          	addi	a0,a0,728 # ffffffffc0202c38 <best_fit_pmm_manager+0x88>
ffffffffc0201968:	a67fe0ef          	jal	ra,ffffffffc02003ce <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc020196c:	00001617          	auipc	a2,0x1
ffffffffc0201970:	32460613          	addi	a2,a2,804 # ffffffffc0202c90 <best_fit_pmm_manager+0xe0>
ffffffffc0201974:	08c00593          	li	a1,140
ffffffffc0201978:	00001517          	auipc	a0,0x1
ffffffffc020197c:	2c050513          	addi	a0,a0,704 # ffffffffc0202c38 <best_fit_pmm_manager+0x88>
ffffffffc0201980:	a4ffe0ef          	jal	ra,ffffffffc02003ce <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201984:	00001617          	auipc	a2,0x1
ffffffffc0201988:	33460613          	addi	a2,a2,820 # ffffffffc0202cb8 <best_fit_pmm_manager+0x108>
ffffffffc020198c:	06b00593          	li	a1,107
ffffffffc0201990:	00001517          	auipc	a0,0x1
ffffffffc0201994:	34850513          	addi	a0,a0,840 # ffffffffc0202cd8 <best_fit_pmm_manager+0x128>
ffffffffc0201998:	a37fe0ef          	jal	ra,ffffffffc02003ce <__panic>

ffffffffc020199c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020199c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019a0:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02019a2:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019a6:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02019a8:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02019ac:	f022                	sd	s0,32(sp)
ffffffffc02019ae:	ec26                	sd	s1,24(sp)
ffffffffc02019b0:	e84a                	sd	s2,16(sp)
ffffffffc02019b2:	f406                	sd	ra,40(sp)
ffffffffc02019b4:	e44e                	sd	s3,8(sp)
ffffffffc02019b6:	84aa                	mv	s1,a0
ffffffffc02019b8:	892e                	mv	s2,a1
ffffffffc02019ba:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02019be:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc02019c0:	03067e63          	bgeu	a2,a6,ffffffffc02019fc <printnum+0x60>
ffffffffc02019c4:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02019c6:	00805763          	blez	s0,ffffffffc02019d4 <printnum+0x38>
ffffffffc02019ca:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02019cc:	85ca                	mv	a1,s2
ffffffffc02019ce:	854e                	mv	a0,s3
ffffffffc02019d0:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02019d2:	fc65                	bnez	s0,ffffffffc02019ca <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019d4:	1a02                	slli	s4,s4,0x20
ffffffffc02019d6:	020a5a13          	srli	s4,s4,0x20
ffffffffc02019da:	00001797          	auipc	a5,0x1
ffffffffc02019de:	4fe78793          	addi	a5,a5,1278 # ffffffffc0202ed8 <error_string+0x38>
ffffffffc02019e2:	9a3e                	add	s4,s4,a5
}
ffffffffc02019e4:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019e6:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02019ea:	70a2                	ld	ra,40(sp)
ffffffffc02019ec:	69a2                	ld	s3,8(sp)
ffffffffc02019ee:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019f0:	85ca                	mv	a1,s2
ffffffffc02019f2:	8326                	mv	t1,s1
}
ffffffffc02019f4:	6942                	ld	s2,16(sp)
ffffffffc02019f6:	64e2                	ld	s1,24(sp)
ffffffffc02019f8:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02019fa:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02019fc:	03065633          	divu	a2,a2,a6
ffffffffc0201a00:	8722                	mv	a4,s0
ffffffffc0201a02:	f9bff0ef          	jal	ra,ffffffffc020199c <printnum>
ffffffffc0201a06:	b7f9                	j	ffffffffc02019d4 <printnum+0x38>

ffffffffc0201a08 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201a08:	7119                	addi	sp,sp,-128
ffffffffc0201a0a:	f4a6                	sd	s1,104(sp)
ffffffffc0201a0c:	f0ca                	sd	s2,96(sp)
ffffffffc0201a0e:	e8d2                	sd	s4,80(sp)
ffffffffc0201a10:	e4d6                	sd	s5,72(sp)
ffffffffc0201a12:	e0da                	sd	s6,64(sp)
ffffffffc0201a14:	fc5e                	sd	s7,56(sp)
ffffffffc0201a16:	f862                	sd	s8,48(sp)
ffffffffc0201a18:	f06a                	sd	s10,32(sp)
ffffffffc0201a1a:	fc86                	sd	ra,120(sp)
ffffffffc0201a1c:	f8a2                	sd	s0,112(sp)
ffffffffc0201a1e:	ecce                	sd	s3,88(sp)
ffffffffc0201a20:	f466                	sd	s9,40(sp)
ffffffffc0201a22:	ec6e                	sd	s11,24(sp)
ffffffffc0201a24:	892a                	mv	s2,a0
ffffffffc0201a26:	84ae                	mv	s1,a1
ffffffffc0201a28:	8d32                	mv	s10,a2
ffffffffc0201a2a:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201a2c:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a2e:	00001a17          	auipc	s4,0x1
ffffffffc0201a32:	31aa0a13          	addi	s4,s4,794 # ffffffffc0202d48 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201a36:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201a3a:	00001c17          	auipc	s8,0x1
ffffffffc0201a3e:	466c0c13          	addi	s8,s8,1126 # ffffffffc0202ea0 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a42:	000d4503          	lbu	a0,0(s10)
ffffffffc0201a46:	02500793          	li	a5,37
ffffffffc0201a4a:	001d0413          	addi	s0,s10,1
ffffffffc0201a4e:	00f50e63          	beq	a0,a5,ffffffffc0201a6a <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc0201a52:	c521                	beqz	a0,ffffffffc0201a9a <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a54:	02500993          	li	s3,37
ffffffffc0201a58:	a011                	j	ffffffffc0201a5c <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0201a5a:	c121                	beqz	a0,ffffffffc0201a9a <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0201a5c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a5e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0201a60:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201a62:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201a66:	ff351ae3          	bne	a0,s3,ffffffffc0201a5a <vprintfmt+0x52>
ffffffffc0201a6a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201a6e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201a72:	4981                	li	s3,0
ffffffffc0201a74:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201a76:	5cfd                	li	s9,-1
ffffffffc0201a78:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a7a:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201a7e:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201a80:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201a84:	0ff6f693          	andi	a3,a3,255
ffffffffc0201a88:	00140d13          	addi	s10,s0,1
ffffffffc0201a8c:	1ed5ef63          	bltu	a1,a3,ffffffffc0201c8a <vprintfmt+0x282>
ffffffffc0201a90:	068a                	slli	a3,a3,0x2
ffffffffc0201a92:	96d2                	add	a3,a3,s4
ffffffffc0201a94:	4294                	lw	a3,0(a3)
ffffffffc0201a96:	96d2                	add	a3,a3,s4
ffffffffc0201a98:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201a9a:	70e6                	ld	ra,120(sp)
ffffffffc0201a9c:	7446                	ld	s0,112(sp)
ffffffffc0201a9e:	74a6                	ld	s1,104(sp)
ffffffffc0201aa0:	7906                	ld	s2,96(sp)
ffffffffc0201aa2:	69e6                	ld	s3,88(sp)
ffffffffc0201aa4:	6a46                	ld	s4,80(sp)
ffffffffc0201aa6:	6aa6                	ld	s5,72(sp)
ffffffffc0201aa8:	6b06                	ld	s6,64(sp)
ffffffffc0201aaa:	7be2                	ld	s7,56(sp)
ffffffffc0201aac:	7c42                	ld	s8,48(sp)
ffffffffc0201aae:	7ca2                	ld	s9,40(sp)
ffffffffc0201ab0:	7d02                	ld	s10,32(sp)
ffffffffc0201ab2:	6de2                	ld	s11,24(sp)
ffffffffc0201ab4:	6109                	addi	sp,sp,128
ffffffffc0201ab6:	8082                	ret
            padc = '-';
ffffffffc0201ab8:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201aba:	00144603          	lbu	a2,1(s0)
ffffffffc0201abe:	846a                	mv	s0,s10
ffffffffc0201ac0:	b7c1                	j	ffffffffc0201a80 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0201ac2:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201ac6:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201aca:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201acc:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201ace:	fa0dd9e3          	bgez	s11,ffffffffc0201a80 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201ad2:	8de6                	mv	s11,s9
ffffffffc0201ad4:	5cfd                	li	s9,-1
ffffffffc0201ad6:	b76d                	j	ffffffffc0201a80 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0201ad8:	fffdc693          	not	a3,s11
ffffffffc0201adc:	96fd                	srai	a3,a3,0x3f
ffffffffc0201ade:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201ae2:	00144603          	lbu	a2,1(s0)
ffffffffc0201ae6:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201ae8:	846a                	mv	s0,s10
ffffffffc0201aea:	bf59                	j	ffffffffc0201a80 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201aec:	4705                	li	a4,1
ffffffffc0201aee:	008a8593          	addi	a1,s5,8
ffffffffc0201af2:	01074463          	blt	a4,a6,ffffffffc0201afa <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc0201af6:	22080863          	beqz	a6,ffffffffc0201d26 <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc0201afa:	000ab603          	ld	a2,0(s5)
ffffffffc0201afe:	46c1                	li	a3,16
ffffffffc0201b00:	8aae                	mv	s5,a1
ffffffffc0201b02:	a291                	j	ffffffffc0201c46 <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0201b04:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201b08:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201b0c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201b0e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201b12:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b16:	fad56ce3          	bltu	a0,a3,ffffffffc0201ace <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc0201b1a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201b1c:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc0201b20:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201b24:	0196873b          	addw	a4,a3,s9
ffffffffc0201b28:	0017171b          	slliw	a4,a4,0x1
ffffffffc0201b2c:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc0201b30:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0201b34:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0201b38:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0201b3c:	fcd57fe3          	bgeu	a0,a3,ffffffffc0201b1a <vprintfmt+0x112>
ffffffffc0201b40:	b779                	j	ffffffffc0201ace <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc0201b42:	000aa503          	lw	a0,0(s5)
ffffffffc0201b46:	85a6                	mv	a1,s1
ffffffffc0201b48:	0aa1                	addi	s5,s5,8
ffffffffc0201b4a:	9902                	jalr	s2
            break;
ffffffffc0201b4c:	bddd                	j	ffffffffc0201a42 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201b4e:	4705                	li	a4,1
ffffffffc0201b50:	008a8993          	addi	s3,s5,8
ffffffffc0201b54:	01074463          	blt	a4,a6,ffffffffc0201b5c <vprintfmt+0x154>
    else if (lflag) {
ffffffffc0201b58:	1c080463          	beqz	a6,ffffffffc0201d20 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc0201b5c:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc0201b60:	1c044a63          	bltz	s0,ffffffffc0201d34 <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc0201b64:	8622                	mv	a2,s0
ffffffffc0201b66:	8ace                	mv	s5,s3
ffffffffc0201b68:	46a9                	li	a3,10
ffffffffc0201b6a:	a8f1                	j	ffffffffc0201c46 <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc0201b6c:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b70:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201b72:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201b74:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201b78:	8fb5                	xor	a5,a5,a3
ffffffffc0201b7a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201b7e:	12d74963          	blt	a4,a3,ffffffffc0201cb0 <vprintfmt+0x2a8>
ffffffffc0201b82:	00369793          	slli	a5,a3,0x3
ffffffffc0201b86:	97e2                	add	a5,a5,s8
ffffffffc0201b88:	639c                	ld	a5,0(a5)
ffffffffc0201b8a:	12078363          	beqz	a5,ffffffffc0201cb0 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201b8e:	86be                	mv	a3,a5
ffffffffc0201b90:	00001617          	auipc	a2,0x1
ffffffffc0201b94:	3f860613          	addi	a2,a2,1016 # ffffffffc0202f88 <error_string+0xe8>
ffffffffc0201b98:	85a6                	mv	a1,s1
ffffffffc0201b9a:	854a                	mv	a0,s2
ffffffffc0201b9c:	1cc000ef          	jal	ra,ffffffffc0201d68 <printfmt>
ffffffffc0201ba0:	b54d                	j	ffffffffc0201a42 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201ba2:	000ab603          	ld	a2,0(s5)
ffffffffc0201ba6:	0aa1                	addi	s5,s5,8
ffffffffc0201ba8:	1a060163          	beqz	a2,ffffffffc0201d4a <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc0201bac:	00160413          	addi	s0,a2,1
ffffffffc0201bb0:	15b05763          	blez	s11,ffffffffc0201cfe <vprintfmt+0x2f6>
ffffffffc0201bb4:	02d00593          	li	a1,45
ffffffffc0201bb8:	10b79d63          	bne	a5,a1,ffffffffc0201cd2 <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201bbc:	00064783          	lbu	a5,0(a2)
ffffffffc0201bc0:	0007851b          	sext.w	a0,a5
ffffffffc0201bc4:	c905                	beqz	a0,ffffffffc0201bf4 <vprintfmt+0x1ec>
ffffffffc0201bc6:	000cc563          	bltz	s9,ffffffffc0201bd0 <vprintfmt+0x1c8>
ffffffffc0201bca:	3cfd                	addiw	s9,s9,-1
ffffffffc0201bcc:	036c8263          	beq	s9,s6,ffffffffc0201bf0 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc0201bd0:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201bd2:	14098f63          	beqz	s3,ffffffffc0201d30 <vprintfmt+0x328>
ffffffffc0201bd6:	3781                	addiw	a5,a5,-32
ffffffffc0201bd8:	14fbfc63          	bgeu	s7,a5,ffffffffc0201d30 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc0201bdc:	03f00513          	li	a0,63
ffffffffc0201be0:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201be2:	0405                	addi	s0,s0,1
ffffffffc0201be4:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201be8:	3dfd                	addiw	s11,s11,-1
ffffffffc0201bea:	0007851b          	sext.w	a0,a5
ffffffffc0201bee:	fd61                	bnez	a0,ffffffffc0201bc6 <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0201bf0:	e5b059e3          	blez	s11,ffffffffc0201a42 <vprintfmt+0x3a>
ffffffffc0201bf4:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201bf6:	85a6                	mv	a1,s1
ffffffffc0201bf8:	02000513          	li	a0,32
ffffffffc0201bfc:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201bfe:	e40d82e3          	beqz	s11,ffffffffc0201a42 <vprintfmt+0x3a>
ffffffffc0201c02:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201c04:	85a6                	mv	a1,s1
ffffffffc0201c06:	02000513          	li	a0,32
ffffffffc0201c0a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201c0c:	fe0d94e3          	bnez	s11,ffffffffc0201bf4 <vprintfmt+0x1ec>
ffffffffc0201c10:	bd0d                	j	ffffffffc0201a42 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c12:	4705                	li	a4,1
ffffffffc0201c14:	008a8593          	addi	a1,s5,8
ffffffffc0201c18:	01074463          	blt	a4,a6,ffffffffc0201c20 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc0201c1c:	0e080863          	beqz	a6,ffffffffc0201d0c <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc0201c20:	000ab603          	ld	a2,0(s5)
ffffffffc0201c24:	46a1                	li	a3,8
ffffffffc0201c26:	8aae                	mv	s5,a1
ffffffffc0201c28:	a839                	j	ffffffffc0201c46 <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc0201c2a:	03000513          	li	a0,48
ffffffffc0201c2e:	85a6                	mv	a1,s1
ffffffffc0201c30:	e03e                	sd	a5,0(sp)
ffffffffc0201c32:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0201c34:	85a6                	mv	a1,s1
ffffffffc0201c36:	07800513          	li	a0,120
ffffffffc0201c3a:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201c3c:	0aa1                	addi	s5,s5,8
ffffffffc0201c3e:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0201c42:	6782                	ld	a5,0(sp)
ffffffffc0201c44:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201c46:	2781                	sext.w	a5,a5
ffffffffc0201c48:	876e                	mv	a4,s11
ffffffffc0201c4a:	85a6                	mv	a1,s1
ffffffffc0201c4c:	854a                	mv	a0,s2
ffffffffc0201c4e:	d4fff0ef          	jal	ra,ffffffffc020199c <printnum>
            break;
ffffffffc0201c52:	bbc5                	j	ffffffffc0201a42 <vprintfmt+0x3a>
            lflag ++;
ffffffffc0201c54:	00144603          	lbu	a2,1(s0)
ffffffffc0201c58:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c5a:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c5c:	b515                	j	ffffffffc0201a80 <vprintfmt+0x78>
            goto reswitch;
ffffffffc0201c5e:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0201c62:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201c64:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0201c66:	bd29                	j	ffffffffc0201a80 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc0201c68:	85a6                	mv	a1,s1
ffffffffc0201c6a:	02500513          	li	a0,37
ffffffffc0201c6e:	9902                	jalr	s2
            break;
ffffffffc0201c70:	bbc9                	j	ffffffffc0201a42 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201c72:	4705                	li	a4,1
ffffffffc0201c74:	008a8593          	addi	a1,s5,8
ffffffffc0201c78:	01074463          	blt	a4,a6,ffffffffc0201c80 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0201c7c:	08080d63          	beqz	a6,ffffffffc0201d16 <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0201c80:	000ab603          	ld	a2,0(s5)
ffffffffc0201c84:	46a9                	li	a3,10
ffffffffc0201c86:	8aae                	mv	s5,a1
ffffffffc0201c88:	bf7d                	j	ffffffffc0201c46 <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc0201c8a:	85a6                	mv	a1,s1
ffffffffc0201c8c:	02500513          	li	a0,37
ffffffffc0201c90:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201c92:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201c96:	02500793          	li	a5,37
ffffffffc0201c9a:	8d22                	mv	s10,s0
ffffffffc0201c9c:	daf703e3          	beq	a4,a5,ffffffffc0201a42 <vprintfmt+0x3a>
ffffffffc0201ca0:	02500713          	li	a4,37
ffffffffc0201ca4:	1d7d                	addi	s10,s10,-1
ffffffffc0201ca6:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201caa:	fee79de3          	bne	a5,a4,ffffffffc0201ca4 <vprintfmt+0x29c>
ffffffffc0201cae:	bb51                	j	ffffffffc0201a42 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201cb0:	00001617          	auipc	a2,0x1
ffffffffc0201cb4:	2c860613          	addi	a2,a2,712 # ffffffffc0202f78 <error_string+0xd8>
ffffffffc0201cb8:	85a6                	mv	a1,s1
ffffffffc0201cba:	854a                	mv	a0,s2
ffffffffc0201cbc:	0ac000ef          	jal	ra,ffffffffc0201d68 <printfmt>
ffffffffc0201cc0:	b349                	j	ffffffffc0201a42 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201cc2:	00001617          	auipc	a2,0x1
ffffffffc0201cc6:	2ae60613          	addi	a2,a2,686 # ffffffffc0202f70 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201cca:	00001417          	auipc	s0,0x1
ffffffffc0201cce:	2a740413          	addi	s0,s0,679 # ffffffffc0202f71 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cd2:	8532                	mv	a0,a2
ffffffffc0201cd4:	85e6                	mv	a1,s9
ffffffffc0201cd6:	e032                	sd	a2,0(sp)
ffffffffc0201cd8:	e43e                	sd	a5,8(sp)
ffffffffc0201cda:	1fc000ef          	jal	ra,ffffffffc0201ed6 <strnlen>
ffffffffc0201cde:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201ce2:	6602                	ld	a2,0(sp)
ffffffffc0201ce4:	01b05d63          	blez	s11,ffffffffc0201cfe <vprintfmt+0x2f6>
ffffffffc0201ce8:	67a2                	ld	a5,8(sp)
ffffffffc0201cea:	2781                	sext.w	a5,a5
ffffffffc0201cec:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201cee:	6522                	ld	a0,8(sp)
ffffffffc0201cf0:	85a6                	mv	a1,s1
ffffffffc0201cf2:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf4:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201cf6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201cf8:	6602                	ld	a2,0(sp)
ffffffffc0201cfa:	fe0d9ae3          	bnez	s11,ffffffffc0201cee <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201cfe:	00064783          	lbu	a5,0(a2)
ffffffffc0201d02:	0007851b          	sext.w	a0,a5
ffffffffc0201d06:	ec0510e3          	bnez	a0,ffffffffc0201bc6 <vprintfmt+0x1be>
ffffffffc0201d0a:	bb25                	j	ffffffffc0201a42 <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc0201d0c:	000ae603          	lwu	a2,0(s5)
ffffffffc0201d10:	46a1                	li	a3,8
ffffffffc0201d12:	8aae                	mv	s5,a1
ffffffffc0201d14:	bf0d                	j	ffffffffc0201c46 <vprintfmt+0x23e>
ffffffffc0201d16:	000ae603          	lwu	a2,0(s5)
ffffffffc0201d1a:	46a9                	li	a3,10
ffffffffc0201d1c:	8aae                	mv	s5,a1
ffffffffc0201d1e:	b725                	j	ffffffffc0201c46 <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc0201d20:	000aa403          	lw	s0,0(s5)
ffffffffc0201d24:	bd35                	j	ffffffffc0201b60 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc0201d26:	000ae603          	lwu	a2,0(s5)
ffffffffc0201d2a:	46c1                	li	a3,16
ffffffffc0201d2c:	8aae                	mv	s5,a1
ffffffffc0201d2e:	bf21                	j	ffffffffc0201c46 <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc0201d30:	9902                	jalr	s2
ffffffffc0201d32:	bd45                	j	ffffffffc0201be2 <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc0201d34:	85a6                	mv	a1,s1
ffffffffc0201d36:	02d00513          	li	a0,45
ffffffffc0201d3a:	e03e                	sd	a5,0(sp)
ffffffffc0201d3c:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201d3e:	8ace                	mv	s5,s3
ffffffffc0201d40:	40800633          	neg	a2,s0
ffffffffc0201d44:	46a9                	li	a3,10
ffffffffc0201d46:	6782                	ld	a5,0(sp)
ffffffffc0201d48:	bdfd                	j	ffffffffc0201c46 <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc0201d4a:	01b05663          	blez	s11,ffffffffc0201d56 <vprintfmt+0x34e>
ffffffffc0201d4e:	02d00693          	li	a3,45
ffffffffc0201d52:	f6d798e3          	bne	a5,a3,ffffffffc0201cc2 <vprintfmt+0x2ba>
ffffffffc0201d56:	00001417          	auipc	s0,0x1
ffffffffc0201d5a:	21b40413          	addi	s0,s0,539 # ffffffffc0202f71 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201d5e:	02800513          	li	a0,40
ffffffffc0201d62:	02800793          	li	a5,40
ffffffffc0201d66:	b585                	j	ffffffffc0201bc6 <vprintfmt+0x1be>

ffffffffc0201d68 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d68:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201d6a:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d6e:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d70:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201d72:	ec06                	sd	ra,24(sp)
ffffffffc0201d74:	f83a                	sd	a4,48(sp)
ffffffffc0201d76:	fc3e                	sd	a5,56(sp)
ffffffffc0201d78:	e0c2                	sd	a6,64(sp)
ffffffffc0201d7a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201d7c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201d7e:	c8bff0ef          	jal	ra,ffffffffc0201a08 <vprintfmt>
}
ffffffffc0201d82:	60e2                	ld	ra,24(sp)
ffffffffc0201d84:	6161                	addi	sp,sp,80
ffffffffc0201d86:	8082                	ret

ffffffffc0201d88 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0201d88:	715d                	addi	sp,sp,-80
ffffffffc0201d8a:	e486                	sd	ra,72(sp)
ffffffffc0201d8c:	e0a2                	sd	s0,64(sp)
ffffffffc0201d8e:	fc26                	sd	s1,56(sp)
ffffffffc0201d90:	f84a                	sd	s2,48(sp)
ffffffffc0201d92:	f44e                	sd	s3,40(sp)
ffffffffc0201d94:	f052                	sd	s4,32(sp)
ffffffffc0201d96:	ec56                	sd	s5,24(sp)
ffffffffc0201d98:	e85a                	sd	s6,16(sp)
ffffffffc0201d9a:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc0201d9c:	c901                	beqz	a0,ffffffffc0201dac <readline+0x24>
        cprintf("%s", prompt);
ffffffffc0201d9e:	85aa                	mv	a1,a0
ffffffffc0201da0:	00001517          	auipc	a0,0x1
ffffffffc0201da4:	1e850513          	addi	a0,a0,488 # ffffffffc0202f88 <error_string+0xe8>
ffffffffc0201da8:	b34fe0ef          	jal	ra,ffffffffc02000dc <cprintf>
readline(const char *prompt) {
ffffffffc0201dac:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dae:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc0201db0:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc0201db2:	4aa9                	li	s5,10
ffffffffc0201db4:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc0201db6:	00004b97          	auipc	s7,0x4
ffffffffc0201dba:	28ab8b93          	addi	s7,s7,650 # ffffffffc0206040 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dbe:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc0201dc2:	b90fe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201dc6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201dc8:	00054b63          	bltz	a0,ffffffffc0201dde <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201dcc:	00a95b63          	bge	s2,a0,ffffffffc0201de2 <readline+0x5a>
ffffffffc0201dd0:	029a5463          	bge	s4,s1,ffffffffc0201df8 <readline+0x70>
        c = getchar();
ffffffffc0201dd4:	b7efe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201dd8:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201dda:	fe0559e3          	bgez	a0,ffffffffc0201dcc <readline+0x44>
            return NULL;
ffffffffc0201dde:	4501                	li	a0,0
ffffffffc0201de0:	a099                	j	ffffffffc0201e26 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc0201de2:	03341463          	bne	s0,s3,ffffffffc0201e0a <readline+0x82>
ffffffffc0201de6:	e8b9                	bnez	s1,ffffffffc0201e3c <readline+0xb4>
        c = getchar();
ffffffffc0201de8:	b6afe0ef          	jal	ra,ffffffffc0200152 <getchar>
ffffffffc0201dec:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc0201dee:	fe0548e3          	bltz	a0,ffffffffc0201dde <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201df2:	fea958e3          	bge	s2,a0,ffffffffc0201de2 <readline+0x5a>
ffffffffc0201df6:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201df8:	8522                	mv	a0,s0
ffffffffc0201dfa:	b16fe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            buf[i ++] = c;
ffffffffc0201dfe:	009b87b3          	add	a5,s7,s1
ffffffffc0201e02:	00878023          	sb	s0,0(a5)
ffffffffc0201e06:	2485                	addiw	s1,s1,1
ffffffffc0201e08:	bf6d                	j	ffffffffc0201dc2 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0201e0a:	01540463          	beq	s0,s5,ffffffffc0201e12 <readline+0x8a>
ffffffffc0201e0e:	fb641ae3          	bne	s0,s6,ffffffffc0201dc2 <readline+0x3a>
            cputchar(c);
ffffffffc0201e12:	8522                	mv	a0,s0
ffffffffc0201e14:	afcfe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            buf[i] = '\0';
ffffffffc0201e18:	00004517          	auipc	a0,0x4
ffffffffc0201e1c:	22850513          	addi	a0,a0,552 # ffffffffc0206040 <buf>
ffffffffc0201e20:	94aa                	add	s1,s1,a0
ffffffffc0201e22:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201e26:	60a6                	ld	ra,72(sp)
ffffffffc0201e28:	6406                	ld	s0,64(sp)
ffffffffc0201e2a:	74e2                	ld	s1,56(sp)
ffffffffc0201e2c:	7942                	ld	s2,48(sp)
ffffffffc0201e2e:	79a2                	ld	s3,40(sp)
ffffffffc0201e30:	7a02                	ld	s4,32(sp)
ffffffffc0201e32:	6ae2                	ld	s5,24(sp)
ffffffffc0201e34:	6b42                	ld	s6,16(sp)
ffffffffc0201e36:	6ba2                	ld	s7,8(sp)
ffffffffc0201e38:	6161                	addi	sp,sp,80
ffffffffc0201e3a:	8082                	ret
            cputchar(c);
ffffffffc0201e3c:	4521                	li	a0,8
ffffffffc0201e3e:	ad2fe0ef          	jal	ra,ffffffffc0200110 <cputchar>
            i --;
ffffffffc0201e42:	34fd                	addiw	s1,s1,-1
ffffffffc0201e44:	bfbd                	j	ffffffffc0201dc2 <readline+0x3a>

ffffffffc0201e46 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201e46:	00004797          	auipc	a5,0x4
ffffffffc0201e4a:	1d278793          	addi	a5,a5,466 # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201e4e:	6398                	ld	a4,0(a5)
ffffffffc0201e50:	4781                	li	a5,0
ffffffffc0201e52:	88ba                	mv	a7,a4
ffffffffc0201e54:	852a                	mv	a0,a0
ffffffffc0201e56:	85be                	mv	a1,a5
ffffffffc0201e58:	863e                	mv	a2,a5
ffffffffc0201e5a:	00000073          	ecall
ffffffffc0201e5e:	87aa                	mv	a5,a0
}
ffffffffc0201e60:	8082                	ret

ffffffffc0201e62 <sbi_set_timer>:

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
ffffffffc0201e62:	00004797          	auipc	a5,0x4
ffffffffc0201e66:	60e78793          	addi	a5,a5,1550 # ffffffffc0206470 <SBI_SET_TIMER>
    __asm__ volatile (
ffffffffc0201e6a:	6398                	ld	a4,0(a5)
ffffffffc0201e6c:	4781                	li	a5,0
ffffffffc0201e6e:	88ba                	mv	a7,a4
ffffffffc0201e70:	852a                	mv	a0,a0
ffffffffc0201e72:	85be                	mv	a1,a5
ffffffffc0201e74:	863e                	mv	a2,a5
ffffffffc0201e76:	00000073          	ecall
ffffffffc0201e7a:	87aa                	mv	a5,a0
}
ffffffffc0201e7c:	8082                	ret

ffffffffc0201e7e <sbi_console_getchar>:

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc0201e7e:	00004797          	auipc	a5,0x4
ffffffffc0201e82:	19278793          	addi	a5,a5,402 # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
    __asm__ volatile (
ffffffffc0201e86:	639c                	ld	a5,0(a5)
ffffffffc0201e88:	4501                	li	a0,0
ffffffffc0201e8a:	88be                	mv	a7,a5
ffffffffc0201e8c:	852a                	mv	a0,a0
ffffffffc0201e8e:	85aa                	mv	a1,a0
ffffffffc0201e90:	862a                	mv	a2,a0
ffffffffc0201e92:	00000073          	ecall
ffffffffc0201e96:	852a                	mv	a0,a0
}
ffffffffc0201e98:	2501                	sext.w	a0,a0
ffffffffc0201e9a:	8082                	ret

ffffffffc0201e9c <sbi_shutdown>:

void sbi_shutdown(void)
{
	sbi_call(SBI_SHUTDOWN, 0, 0, 0);
ffffffffc0201e9c:	00004797          	auipc	a5,0x4
ffffffffc0201ea0:	18478793          	addi	a5,a5,388 # ffffffffc0206020 <SBI_SHUTDOWN>
    __asm__ volatile (
ffffffffc0201ea4:	6398                	ld	a4,0(a5)
ffffffffc0201ea6:	4781                	li	a5,0
ffffffffc0201ea8:	88ba                	mv	a7,a4
ffffffffc0201eaa:	853e                	mv	a0,a5
ffffffffc0201eac:	85be                	mv	a1,a5
ffffffffc0201eae:	863e                	mv	a2,a5
ffffffffc0201eb0:	00000073          	ecall
ffffffffc0201eb4:	87aa                	mv	a5,a0
ffffffffc0201eb6:	8082                	ret

ffffffffc0201eb8 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201eb8:	00054783          	lbu	a5,0(a0)
ffffffffc0201ebc:	cb91                	beqz	a5,ffffffffc0201ed0 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0201ebe:	4781                	li	a5,0
        cnt ++;
ffffffffc0201ec0:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201ec2:	00f50733          	add	a4,a0,a5
ffffffffc0201ec6:	00074703          	lbu	a4,0(a4) # fffffffffff80000 <end+0x3fd79b60>
ffffffffc0201eca:	fb7d                	bnez	a4,ffffffffc0201ec0 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201ecc:	853e                	mv	a0,a5
ffffffffc0201ece:	8082                	ret
    size_t cnt = 0;
ffffffffc0201ed0:	4781                	li	a5,0
}
ffffffffc0201ed2:	853e                	mv	a0,a5
ffffffffc0201ed4:	8082                	ret

ffffffffc0201ed6 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ed6:	c185                	beqz	a1,ffffffffc0201ef6 <strnlen+0x20>
ffffffffc0201ed8:	00054783          	lbu	a5,0(a0)
ffffffffc0201edc:	cf89                	beqz	a5,ffffffffc0201ef6 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201ede:	4781                	li	a5,0
ffffffffc0201ee0:	a021                	j	ffffffffc0201ee8 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201ee2:	00074703          	lbu	a4,0(a4)
ffffffffc0201ee6:	c711                	beqz	a4,ffffffffc0201ef2 <strnlen+0x1c>
        cnt ++;
ffffffffc0201ee8:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201eea:	00f50733          	add	a4,a0,a5
ffffffffc0201eee:	fef59ae3          	bne	a1,a5,ffffffffc0201ee2 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201ef2:	853e                	mv	a0,a5
ffffffffc0201ef4:	8082                	ret
    size_t cnt = 0;
ffffffffc0201ef6:	4781                	li	a5,0
}
ffffffffc0201ef8:	853e                	mv	a0,a5
ffffffffc0201efa:	8082                	ret

ffffffffc0201efc <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201efc:	00054783          	lbu	a5,0(a0)
ffffffffc0201f00:	0005c703          	lbu	a4,0(a1)
ffffffffc0201f04:	cb91                	beqz	a5,ffffffffc0201f18 <strcmp+0x1c>
ffffffffc0201f06:	00e79c63          	bne	a5,a4,ffffffffc0201f1e <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201f0a:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f0c:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201f10:	0585                	addi	a1,a1,1
ffffffffc0201f12:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201f16:	fbe5                	bnez	a5,ffffffffc0201f06 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f18:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201f1a:	9d19                	subw	a0,a0,a4
ffffffffc0201f1c:	8082                	ret
ffffffffc0201f1e:	0007851b          	sext.w	a0,a5
ffffffffc0201f22:	9d19                	subw	a0,a0,a4
ffffffffc0201f24:	8082                	ret

ffffffffc0201f26 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f26:	c61d                	beqz	a2,ffffffffc0201f54 <strncmp+0x2e>
ffffffffc0201f28:	00054703          	lbu	a4,0(a0)
ffffffffc0201f2c:	0005c683          	lbu	a3,0(a1)
ffffffffc0201f30:	c715                	beqz	a4,ffffffffc0201f5c <strncmp+0x36>
ffffffffc0201f32:	02e69563          	bne	a3,a4,ffffffffc0201f5c <strncmp+0x36>
ffffffffc0201f36:	962e                	add	a2,a2,a1
ffffffffc0201f38:	a809                	j	ffffffffc0201f4a <strncmp+0x24>
ffffffffc0201f3a:	00054703          	lbu	a4,0(a0)
ffffffffc0201f3e:	cf09                	beqz	a4,ffffffffc0201f58 <strncmp+0x32>
ffffffffc0201f40:	0007c683          	lbu	a3,0(a5)
ffffffffc0201f44:	85be                	mv	a1,a5
ffffffffc0201f46:	00d71b63          	bne	a4,a3,ffffffffc0201f5c <strncmp+0x36>
        n --, s1 ++, s2 ++;
ffffffffc0201f4a:	00158793          	addi	a5,a1,1
ffffffffc0201f4e:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc0201f50:	fec795e3          	bne	a5,a2,ffffffffc0201f3a <strncmp+0x14>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201f54:	4501                	li	a0,0
ffffffffc0201f56:	8082                	ret
ffffffffc0201f58:	0015c683          	lbu	a3,1(a1)
ffffffffc0201f5c:	40d7053b          	subw	a0,a4,a3
}
ffffffffc0201f60:	8082                	ret

ffffffffc0201f62 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc0201f62:	00054783          	lbu	a5,0(a0)
ffffffffc0201f66:	cb91                	beqz	a5,ffffffffc0201f7a <strchr+0x18>
        if (*s == c) {
ffffffffc0201f68:	00b79563          	bne	a5,a1,ffffffffc0201f72 <strchr+0x10>
ffffffffc0201f6c:	a809                	j	ffffffffc0201f7e <strchr+0x1c>
ffffffffc0201f6e:	00b78763          	beq	a5,a1,ffffffffc0201f7c <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc0201f72:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc0201f74:	00054783          	lbu	a5,0(a0)
ffffffffc0201f78:	fbfd                	bnez	a5,ffffffffc0201f6e <strchr+0xc>
    }
    return NULL;
ffffffffc0201f7a:	4501                	li	a0,0
}
ffffffffc0201f7c:	8082                	ret
ffffffffc0201f7e:	8082                	ret

ffffffffc0201f80 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201f80:	ca01                	beqz	a2,ffffffffc0201f90 <memset+0x10>
ffffffffc0201f82:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201f84:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201f86:	0785                	addi	a5,a5,1
ffffffffc0201f88:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201f8c:	fec79de3          	bne	a5,a2,ffffffffc0201f86 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201f90:	8082                	ret

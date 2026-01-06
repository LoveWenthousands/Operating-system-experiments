
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	0000b297          	auipc	t0,0xb
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc020b000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	0000b297          	auipc	t0,0xb
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc020b008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c020a2b7          	lui	t0,0xc020a
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c020a137          	lui	sp,0xc020a

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200040:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200044:	04a28293          	addi	t0,t0,74 # ffffffffc020004a <kern_init>
    jr t0
ffffffffc0200048:	8282                	jr	t0

ffffffffc020004a <kern_init>:
void grade_backtrace(void);

int kern_init(void)
{
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc020004a:	00097517          	auipc	a0,0x97
ffffffffc020004e:	53e50513          	addi	a0,a0,1342 # ffffffffc0297588 <buf>
ffffffffc0200052:	0009c617          	auipc	a2,0x9c
ffffffffc0200056:	9de60613          	addi	a2,a2,-1570 # ffffffffc029ba30 <end>
{
ffffffffc020005a:	1141                	addi	sp,sp,-16 # ffffffffc0209ff0 <bootstack+0x1ff0>
    memset(edata, 0, end - edata);
ffffffffc020005c:	8e09                	sub	a2,a2,a0
ffffffffc020005e:	4581                	li	a1,0
{
ffffffffc0200060:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc0200062:	77c050ef          	jal	ffffffffc02057de <memset>
    dtb_init();
ffffffffc0200066:	552000ef          	jal	ffffffffc02005b8 <dtb_init>
    cons_init(); // init the console
ffffffffc020006a:	4dc000ef          	jal	ffffffffc0200546 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc020006e:	00005597          	auipc	a1,0x5
ffffffffc0200072:	79a58593          	addi	a1,a1,1946 # ffffffffc0205808 <etext>
ffffffffc0200076:	00005517          	auipc	a0,0x5
ffffffffc020007a:	7b250513          	addi	a0,a0,1970 # ffffffffc0205828 <etext+0x20>
ffffffffc020007e:	116000ef          	jal	ffffffffc0200194 <cprintf>

    print_kerninfo();
ffffffffc0200082:	1a4000ef          	jal	ffffffffc0200226 <print_kerninfo>

    // grade_backtrace();

    pmm_init(); // init physical memory management
ffffffffc0200086:	6c8020ef          	jal	ffffffffc020274e <pmm_init>

    pic_init(); // init interrupt controller
ffffffffc020008a:	081000ef          	jal	ffffffffc020090a <pic_init>
    idt_init(); // init interrupt descriptor table
ffffffffc020008e:	07f000ef          	jal	ffffffffc020090c <idt_init>

    vmm_init();  // init virtual memory management
ffffffffc0200092:	1b5030ef          	jal	ffffffffc0203a46 <vmm_init>
    proc_init(); // init process table
ffffffffc0200096:	693040ef          	jal	ffffffffc0204f28 <proc_init>

    clock_init();  // init clock interrupt
ffffffffc020009a:	45a000ef          	jal	ffffffffc02004f4 <clock_init>
    intr_enable(); // enable irq interrupt
ffffffffc020009e:	061000ef          	jal	ffffffffc02008fe <intr_enable>

    cpu_idle(); // run idle process
ffffffffc02000a2:	026050ef          	jal	ffffffffc02050c8 <cpu_idle>

ffffffffc02000a6 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02000a6:	7179                	addi	sp,sp,-48
ffffffffc02000a8:	f406                	sd	ra,40(sp)
ffffffffc02000aa:	f022                	sd	s0,32(sp)
ffffffffc02000ac:	ec26                	sd	s1,24(sp)
ffffffffc02000ae:	e84a                	sd	s2,16(sp)
ffffffffc02000b0:	e44e                	sd	s3,8(sp)
    if (prompt != NULL) {
ffffffffc02000b2:	c901                	beqz	a0,ffffffffc02000c2 <readline+0x1c>
        cprintf("%s", prompt);
ffffffffc02000b4:	85aa                	mv	a1,a0
ffffffffc02000b6:	00005517          	auipc	a0,0x5
ffffffffc02000ba:	77a50513          	addi	a0,a0,1914 # ffffffffc0205830 <etext+0x28>
ffffffffc02000be:	0d6000ef          	jal	ffffffffc0200194 <cprintf>
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
            cputchar(c);
            buf[i ++] = c;
ffffffffc02000c2:	4481                	li	s1,0
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000c4:	497d                	li	s2,31
            buf[i ++] = c;
ffffffffc02000c6:	00097997          	auipc	s3,0x97
ffffffffc02000ca:	4c298993          	addi	s3,s3,1218 # ffffffffc0297588 <buf>
        c = getchar();
ffffffffc02000ce:	148000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc02000d2:	842a                	mv	s0,a0
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000d4:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000d8:	3ff4a713          	slti	a4,s1,1023
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000dc:	ff650693          	addi	a3,a0,-10
ffffffffc02000e0:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc02000e4:	02054963          	bltz	a0,ffffffffc0200116 <readline+0x70>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000e8:	02a95f63          	bge	s2,a0,ffffffffc0200126 <readline+0x80>
ffffffffc02000ec:	cf0d                	beqz	a4,ffffffffc0200126 <readline+0x80>
            cputchar(c);
ffffffffc02000ee:	0da000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i ++] = c;
ffffffffc02000f2:	009987b3          	add	a5,s3,s1
ffffffffc02000f6:	00878023          	sb	s0,0(a5)
ffffffffc02000fa:	2485                	addiw	s1,s1,1
        c = getchar();
ffffffffc02000fc:	11a000ef          	jal	ffffffffc0200216 <getchar>
ffffffffc0200100:	842a                	mv	s0,a0
        else if (c == '\b' && i > 0) {
ffffffffc0200102:	ff850793          	addi	a5,a0,-8
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200106:	3ff4a713          	slti	a4,s1,1023
        else if (c == '\n' || c == '\r') {
ffffffffc020010a:	ff650693          	addi	a3,a0,-10
ffffffffc020010e:	ff350613          	addi	a2,a0,-13
        if (c < 0) {
ffffffffc0200112:	fc055be3          	bgez	a0,ffffffffc02000e8 <readline+0x42>
            cputchar(c);
            buf[i] = '\0';
            return buf;
        }
    }
}
ffffffffc0200116:	70a2                	ld	ra,40(sp)
ffffffffc0200118:	7402                	ld	s0,32(sp)
ffffffffc020011a:	64e2                	ld	s1,24(sp)
ffffffffc020011c:	6942                	ld	s2,16(sp)
ffffffffc020011e:	69a2                	ld	s3,8(sp)
            return NULL;
ffffffffc0200120:	4501                	li	a0,0
}
ffffffffc0200122:	6145                	addi	sp,sp,48
ffffffffc0200124:	8082                	ret
        else if (c == '\b' && i > 0) {
ffffffffc0200126:	eb81                	bnez	a5,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc0200128:	4521                	li	a0,8
        else if (c == '\b' && i > 0) {
ffffffffc020012a:	00905663          	blez	s1,ffffffffc0200136 <readline+0x90>
            cputchar(c);
ffffffffc020012e:	09a000ef          	jal	ffffffffc02001c8 <cputchar>
            i --;
ffffffffc0200132:	34fd                	addiw	s1,s1,-1
ffffffffc0200134:	bf69                	j	ffffffffc02000ce <readline+0x28>
        else if (c == '\n' || c == '\r') {
ffffffffc0200136:	c291                	beqz	a3,ffffffffc020013a <readline+0x94>
ffffffffc0200138:	fa59                	bnez	a2,ffffffffc02000ce <readline+0x28>
            cputchar(c);
ffffffffc020013a:	8522                	mv	a0,s0
ffffffffc020013c:	08c000ef          	jal	ffffffffc02001c8 <cputchar>
            buf[i] = '\0';
ffffffffc0200140:	00097517          	auipc	a0,0x97
ffffffffc0200144:	44850513          	addi	a0,a0,1096 # ffffffffc0297588 <buf>
ffffffffc0200148:	94aa                	add	s1,s1,a0
ffffffffc020014a:	00048023          	sb	zero,0(s1)
}
ffffffffc020014e:	70a2                	ld	ra,40(sp)
ffffffffc0200150:	7402                	ld	s0,32(sp)
ffffffffc0200152:	64e2                	ld	s1,24(sp)
ffffffffc0200154:	6942                	ld	s2,16(sp)
ffffffffc0200156:	69a2                	ld	s3,8(sp)
ffffffffc0200158:	6145                	addi	sp,sp,48
ffffffffc020015a:	8082                	ret

ffffffffc020015c <cputch>:
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt)
{
ffffffffc020015c:	1101                	addi	sp,sp,-32
ffffffffc020015e:	ec06                	sd	ra,24(sp)
ffffffffc0200160:	e42e                	sd	a1,8(sp)
    cons_putc(c);
ffffffffc0200162:	3e6000ef          	jal	ffffffffc0200548 <cons_putc>
    (*cnt)++;
ffffffffc0200166:	65a2                	ld	a1,8(sp)
}
ffffffffc0200168:	60e2                	ld	ra,24(sp)
    (*cnt)++;
ffffffffc020016a:	419c                	lw	a5,0(a1)
ffffffffc020016c:	2785                	addiw	a5,a5,1
ffffffffc020016e:	c19c                	sw	a5,0(a1)
}
ffffffffc0200170:	6105                	addi	sp,sp,32
ffffffffc0200172:	8082                	ret

ffffffffc0200174 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int vcprintf(const char *fmt, va_list ap)
{
ffffffffc0200174:	1101                	addi	sp,sp,-32
ffffffffc0200176:	862a                	mv	a2,a0
ffffffffc0200178:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc020017a:	00000517          	auipc	a0,0x0
ffffffffc020017e:	fe250513          	addi	a0,a0,-30 # ffffffffc020015c <cputch>
ffffffffc0200182:	006c                	addi	a1,sp,12
{
ffffffffc0200184:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200186:	c602                	sw	zero,12(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc0200188:	23c050ef          	jal	ffffffffc02053c4 <vprintfmt>
    return cnt;
}
ffffffffc020018c:	60e2                	ld	ra,24(sp)
ffffffffc020018e:	4532                	lw	a0,12(sp)
ffffffffc0200190:	6105                	addi	sp,sp,32
ffffffffc0200192:	8082                	ret

ffffffffc0200194 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int cprintf(const char *fmt, ...)
{
ffffffffc0200194:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200196:	02810313          	addi	t1,sp,40
{
ffffffffc020019a:	f42e                	sd	a1,40(sp)
ffffffffc020019c:	f832                	sd	a2,48(sp)
ffffffffc020019e:	fc36                	sd	a3,56(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001a0:	862a                	mv	a2,a0
ffffffffc02001a2:	004c                	addi	a1,sp,4
ffffffffc02001a4:	00000517          	auipc	a0,0x0
ffffffffc02001a8:	fb850513          	addi	a0,a0,-72 # ffffffffc020015c <cputch>
ffffffffc02001ac:	869a                	mv	a3,t1
{
ffffffffc02001ae:	ec06                	sd	ra,24(sp)
ffffffffc02001b0:	e0ba                	sd	a4,64(sp)
ffffffffc02001b2:	e4be                	sd	a5,72(sp)
ffffffffc02001b4:	e8c2                	sd	a6,80(sp)
ffffffffc02001b6:	ecc6                	sd	a7,88(sp)
    int cnt = 0;
ffffffffc02001b8:	c202                	sw	zero,4(sp)
    va_start(ap, fmt);
ffffffffc02001ba:	e41a                	sd	t1,8(sp)
    vprintfmt((void *)cputch, &cnt, fmt, ap);
ffffffffc02001bc:	208050ef          	jal	ffffffffc02053c4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001c0:	60e2                	ld	ra,24(sp)
ffffffffc02001c2:	4512                	lw	a0,4(sp)
ffffffffc02001c4:	6125                	addi	sp,sp,96
ffffffffc02001c6:	8082                	ret

ffffffffc02001c8 <cputchar>:

/* cputchar - writes a single character to stdout */
void cputchar(int c)
{
    cons_putc(c);
ffffffffc02001c8:	a641                	j	ffffffffc0200548 <cons_putc>

ffffffffc02001ca <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int cputs(const char *str)
{
ffffffffc02001ca:	1101                	addi	sp,sp,-32
ffffffffc02001cc:	e822                	sd	s0,16(sp)
ffffffffc02001ce:	ec06                	sd	ra,24(sp)
ffffffffc02001d0:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str++) != '\0')
ffffffffc02001d2:	00054503          	lbu	a0,0(a0)
ffffffffc02001d6:	c51d                	beqz	a0,ffffffffc0200204 <cputs+0x3a>
ffffffffc02001d8:	e426                	sd	s1,8(sp)
ffffffffc02001da:	0405                	addi	s0,s0,1
    int cnt = 0;
ffffffffc02001dc:	4481                	li	s1,0
    cons_putc(c);
ffffffffc02001de:	36a000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc02001e2:	00044503          	lbu	a0,0(s0)
ffffffffc02001e6:	0405                	addi	s0,s0,1
ffffffffc02001e8:	87a6                	mv	a5,s1
    (*cnt)++;
ffffffffc02001ea:	2485                	addiw	s1,s1,1
    while ((c = *str++) != '\0')
ffffffffc02001ec:	f96d                	bnez	a0,ffffffffc02001de <cputs+0x14>
    cons_putc(c);
ffffffffc02001ee:	4529                	li	a0,10
    (*cnt)++;
ffffffffc02001f0:	0027841b          	addiw	s0,a5,2
ffffffffc02001f4:	64a2                	ld	s1,8(sp)
    cons_putc(c);
ffffffffc02001f6:	352000ef          	jal	ffffffffc0200548 <cons_putc>
    {
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001fa:	60e2                	ld	ra,24(sp)
ffffffffc02001fc:	8522                	mv	a0,s0
ffffffffc02001fe:	6442                	ld	s0,16(sp)
ffffffffc0200200:	6105                	addi	sp,sp,32
ffffffffc0200202:	8082                	ret
    cons_putc(c);
ffffffffc0200204:	4529                	li	a0,10
ffffffffc0200206:	342000ef          	jal	ffffffffc0200548 <cons_putc>
    while ((c = *str++) != '\0')
ffffffffc020020a:	4405                	li	s0,1
}
ffffffffc020020c:	60e2                	ld	ra,24(sp)
ffffffffc020020e:	8522                	mv	a0,s0
ffffffffc0200210:	6442                	ld	s0,16(sp)
ffffffffc0200212:	6105                	addi	sp,sp,32
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int getchar(void)
{
ffffffffc0200216:	1141                	addi	sp,sp,-16
ffffffffc0200218:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020021a:	362000ef          	jal	ffffffffc020057c <cons_getc>
ffffffffc020021e:	dd75                	beqz	a0,ffffffffc020021a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200220:	60a2                	ld	ra,8(sp)
ffffffffc0200222:	0141                	addi	sp,sp,16
ffffffffc0200224:	8082                	ret

ffffffffc0200226 <print_kerninfo>:
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void)
{
ffffffffc0200226:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200228:	00005517          	auipc	a0,0x5
ffffffffc020022c:	61050513          	addi	a0,a0,1552 # ffffffffc0205838 <etext+0x30>
{
ffffffffc0200230:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200232:	f63ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200236:	00000597          	auipc	a1,0x0
ffffffffc020023a:	e1458593          	addi	a1,a1,-492 # ffffffffc020004a <kern_init>
ffffffffc020023e:	00005517          	auipc	a0,0x5
ffffffffc0200242:	61a50513          	addi	a0,a0,1562 # ffffffffc0205858 <etext+0x50>
ffffffffc0200246:	f4fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020024a:	00005597          	auipc	a1,0x5
ffffffffc020024e:	5be58593          	addi	a1,a1,1470 # ffffffffc0205808 <etext>
ffffffffc0200252:	00005517          	auipc	a0,0x5
ffffffffc0200256:	62650513          	addi	a0,a0,1574 # ffffffffc0205878 <etext+0x70>
ffffffffc020025a:	f3bff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020025e:	00097597          	auipc	a1,0x97
ffffffffc0200262:	32a58593          	addi	a1,a1,810 # ffffffffc0297588 <buf>
ffffffffc0200266:	00005517          	auipc	a0,0x5
ffffffffc020026a:	63250513          	addi	a0,a0,1586 # ffffffffc0205898 <etext+0x90>
ffffffffc020026e:	f27ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200272:	0009b597          	auipc	a1,0x9b
ffffffffc0200276:	7be58593          	addi	a1,a1,1982 # ffffffffc029ba30 <end>
ffffffffc020027a:	00005517          	auipc	a0,0x5
ffffffffc020027e:	63e50513          	addi	a0,a0,1598 # ffffffffc02058b8 <etext+0xb0>
ffffffffc0200282:	f13ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200286:	00000717          	auipc	a4,0x0
ffffffffc020028a:	dc470713          	addi	a4,a4,-572 # ffffffffc020004a <kern_init>
ffffffffc020028e:	0009c797          	auipc	a5,0x9c
ffffffffc0200292:	ba178793          	addi	a5,a5,-1119 # ffffffffc029be2f <end+0x3ff>
ffffffffc0200296:	8f99                	sub	a5,a5,a4
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200298:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020029c:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020029e:	3ff5f593          	andi	a1,a1,1023
ffffffffc02002a2:	95be                	add	a1,a1,a5
ffffffffc02002a4:	85a9                	srai	a1,a1,0xa
ffffffffc02002a6:	00005517          	auipc	a0,0x5
ffffffffc02002aa:	63250513          	addi	a0,a0,1586 # ffffffffc02058d8 <etext+0xd0>
}
ffffffffc02002ae:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002b0:	b5d5                	j	ffffffffc0200194 <cprintf>

ffffffffc02002b2 <print_stackframe>:
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void)
{
ffffffffc02002b2:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002b4:	00005617          	auipc	a2,0x5
ffffffffc02002b8:	65460613          	addi	a2,a2,1620 # ffffffffc0205908 <etext+0x100>
ffffffffc02002bc:	04f00593          	li	a1,79
ffffffffc02002c0:	00005517          	auipc	a0,0x5
ffffffffc02002c4:	66050513          	addi	a0,a0,1632 # ffffffffc0205920 <etext+0x118>
{
ffffffffc02002c8:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002ca:	17c000ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02002ce <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int mon_help(int argc, char **argv, struct trapframe *tf)
{
ffffffffc02002ce:	1101                	addi	sp,sp,-32
ffffffffc02002d0:	e822                	sd	s0,16(sp)
ffffffffc02002d2:	e426                	sd	s1,8(sp)
ffffffffc02002d4:	ec06                	sd	ra,24(sp)
ffffffffc02002d6:	00007417          	auipc	s0,0x7
ffffffffc02002da:	28240413          	addi	s0,s0,642 # ffffffffc0207558 <commands>
ffffffffc02002de:	00007497          	auipc	s1,0x7
ffffffffc02002e2:	2c248493          	addi	s1,s1,706 # ffffffffc02075a0 <commands+0x48>
    int i;
    for (i = 0; i < NCOMMANDS; i++)
    {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002e6:	6410                	ld	a2,8(s0)
ffffffffc02002e8:	600c                	ld	a1,0(s0)
ffffffffc02002ea:	00005517          	auipc	a0,0x5
ffffffffc02002ee:	64e50513          	addi	a0,a0,1614 # ffffffffc0205938 <etext+0x130>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f2:	0461                	addi	s0,s0,24
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002f4:	ea1ff0ef          	jal	ffffffffc0200194 <cprintf>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc02002f8:	fe9417e3          	bne	s0,s1,ffffffffc02002e6 <mon_help+0x18>
    }
    return 0;
}
ffffffffc02002fc:	60e2                	ld	ra,24(sp)
ffffffffc02002fe:	6442                	ld	s0,16(sp)
ffffffffc0200300:	64a2                	ld	s1,8(sp)
ffffffffc0200302:	4501                	li	a0,0
ffffffffc0200304:	6105                	addi	sp,sp,32
ffffffffc0200306:	8082                	ret

ffffffffc0200308 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int mon_kerninfo(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200308:	1141                	addi	sp,sp,-16
ffffffffc020030a:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020030c:	f1bff0ef          	jal	ffffffffc0200226 <print_kerninfo>
    return 0;
}
ffffffffc0200310:	60a2                	ld	ra,8(sp)
ffffffffc0200312:	4501                	li	a0,0
ffffffffc0200314:	0141                	addi	sp,sp,16
ffffffffc0200316:	8082                	ret

ffffffffc0200318 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int mon_backtrace(int argc, char **argv, struct trapframe *tf)
{
ffffffffc0200318:	1141                	addi	sp,sp,-16
ffffffffc020031a:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020031c:	f97ff0ef          	jal	ffffffffc02002b2 <print_stackframe>
    return 0;
}
ffffffffc0200320:	60a2                	ld	ra,8(sp)
ffffffffc0200322:	4501                	li	a0,0
ffffffffc0200324:	0141                	addi	sp,sp,16
ffffffffc0200326:	8082                	ret

ffffffffc0200328 <kmonitor>:
{
ffffffffc0200328:	7131                	addi	sp,sp,-192
ffffffffc020032a:	e952                	sd	s4,144(sp)
ffffffffc020032c:	8a2a                	mv	s4,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc020032e:	00005517          	auipc	a0,0x5
ffffffffc0200332:	61a50513          	addi	a0,a0,1562 # ffffffffc0205948 <etext+0x140>
{
ffffffffc0200336:	fd06                	sd	ra,184(sp)
ffffffffc0200338:	f922                	sd	s0,176(sp)
ffffffffc020033a:	f526                	sd	s1,168(sp)
ffffffffc020033c:	ed4e                	sd	s3,152(sp)
ffffffffc020033e:	e556                	sd	s5,136(sp)
ffffffffc0200340:	e15a                	sd	s6,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200342:	e53ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc0200346:	00005517          	auipc	a0,0x5
ffffffffc020034a:	62a50513          	addi	a0,a0,1578 # ffffffffc0205970 <etext+0x168>
ffffffffc020034e:	e47ff0ef          	jal	ffffffffc0200194 <cprintf>
    if (tf != NULL)
ffffffffc0200352:	000a0563          	beqz	s4,ffffffffc020035c <kmonitor+0x34>
        print_trapframe(tf);
ffffffffc0200356:	8552                	mv	a0,s4
ffffffffc0200358:	79c000ef          	jal	ffffffffc0200af4 <print_trapframe>
ffffffffc020035c:	00007a97          	auipc	s5,0x7
ffffffffc0200360:	1fca8a93          	addi	s5,s5,508 # ffffffffc0207558 <commands>
        if (argc == MAXARGS - 1)
ffffffffc0200364:	49bd                	li	s3,15
        if ((buf = readline("K> ")) != NULL)
ffffffffc0200366:	00005517          	auipc	a0,0x5
ffffffffc020036a:	63250513          	addi	a0,a0,1586 # ffffffffc0205998 <etext+0x190>
ffffffffc020036e:	d39ff0ef          	jal	ffffffffc02000a6 <readline>
ffffffffc0200372:	842a                	mv	s0,a0
ffffffffc0200374:	d96d                	beqz	a0,ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200376:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc020037a:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc020037c:	e99d                	bnez	a1,ffffffffc02003b2 <kmonitor+0x8a>
    int argc = 0;
ffffffffc020037e:	8b26                	mv	s6,s1
    if (argc == 0)
ffffffffc0200380:	fe0b03e3          	beqz	s6,ffffffffc0200366 <kmonitor+0x3e>
ffffffffc0200384:	00007497          	auipc	s1,0x7
ffffffffc0200388:	1d448493          	addi	s1,s1,468 # ffffffffc0207558 <commands>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020038c:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc020038e:	6582                	ld	a1,0(sp)
ffffffffc0200390:	6088                	ld	a0,0(s1)
ffffffffc0200392:	3de050ef          	jal	ffffffffc0205770 <strcmp>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc0200396:	478d                	li	a5,3
        if (strcmp(commands[i].name, argv[0]) == 0)
ffffffffc0200398:	c149                	beqz	a0,ffffffffc020041a <kmonitor+0xf2>
    for (i = 0; i < NCOMMANDS; i++)
ffffffffc020039a:	2405                	addiw	s0,s0,1
ffffffffc020039c:	04e1                	addi	s1,s1,24
ffffffffc020039e:	fef418e3          	bne	s0,a5,ffffffffc020038e <kmonitor+0x66>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003a2:	6582                	ld	a1,0(sp)
ffffffffc02003a4:	00005517          	auipc	a0,0x5
ffffffffc02003a8:	62450513          	addi	a0,a0,1572 # ffffffffc02059c8 <etext+0x1c0>
ffffffffc02003ac:	de9ff0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
ffffffffc02003b0:	bf5d                	j	ffffffffc0200366 <kmonitor+0x3e>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003b2:	00005517          	auipc	a0,0x5
ffffffffc02003b6:	5ee50513          	addi	a0,a0,1518 # ffffffffc02059a0 <etext+0x198>
ffffffffc02003ba:	412050ef          	jal	ffffffffc02057cc <strchr>
ffffffffc02003be:	c901                	beqz	a0,ffffffffc02003ce <kmonitor+0xa6>
ffffffffc02003c0:	00144583          	lbu	a1,1(s0)
            *buf++ = '\0';
ffffffffc02003c4:	00040023          	sb	zero,0(s0)
ffffffffc02003c8:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc02003ca:	d9d5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003cc:	b7dd                	j	ffffffffc02003b2 <kmonitor+0x8a>
        if (*buf == '\0')
ffffffffc02003ce:	00044783          	lbu	a5,0(s0)
ffffffffc02003d2:	d7d5                	beqz	a5,ffffffffc020037e <kmonitor+0x56>
        if (argc == MAXARGS - 1)
ffffffffc02003d4:	03348b63          	beq	s1,s3,ffffffffc020040a <kmonitor+0xe2>
        argv[argc++] = buf;
ffffffffc02003d8:	00349793          	slli	a5,s1,0x3
ffffffffc02003dc:	978a                	add	a5,a5,sp
ffffffffc02003de:	e380                	sd	s0,0(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e0:	00044583          	lbu	a1,0(s0)
        argv[argc++] = buf;
ffffffffc02003e4:	2485                	addiw	s1,s1,1
ffffffffc02003e6:	8b26                	mv	s6,s1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003e8:	e591                	bnez	a1,ffffffffc02003f4 <kmonitor+0xcc>
ffffffffc02003ea:	bf59                	j	ffffffffc0200380 <kmonitor+0x58>
ffffffffc02003ec:	00144583          	lbu	a1,1(s0)
            buf++;
ffffffffc02003f0:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL)
ffffffffc02003f2:	d5d1                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc02003f4:	00005517          	auipc	a0,0x5
ffffffffc02003f8:	5ac50513          	addi	a0,a0,1452 # ffffffffc02059a0 <etext+0x198>
ffffffffc02003fc:	3d0050ef          	jal	ffffffffc02057cc <strchr>
ffffffffc0200400:	d575                	beqz	a0,ffffffffc02003ec <kmonitor+0xc4>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL)
ffffffffc0200402:	00044583          	lbu	a1,0(s0)
ffffffffc0200406:	dda5                	beqz	a1,ffffffffc020037e <kmonitor+0x56>
ffffffffc0200408:	b76d                	j	ffffffffc02003b2 <kmonitor+0x8a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020040a:	45c1                	li	a1,16
ffffffffc020040c:	00005517          	auipc	a0,0x5
ffffffffc0200410:	59c50513          	addi	a0,a0,1436 # ffffffffc02059a8 <etext+0x1a0>
ffffffffc0200414:	d81ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200418:	b7c1                	j	ffffffffc02003d8 <kmonitor+0xb0>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc020041a:	00141793          	slli	a5,s0,0x1
ffffffffc020041e:	97a2                	add	a5,a5,s0
ffffffffc0200420:	078e                	slli	a5,a5,0x3
ffffffffc0200422:	97d6                	add	a5,a5,s5
ffffffffc0200424:	6b9c                	ld	a5,16(a5)
ffffffffc0200426:	fffb051b          	addiw	a0,s6,-1
ffffffffc020042a:	8652                	mv	a2,s4
ffffffffc020042c:	002c                	addi	a1,sp,8
ffffffffc020042e:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0)
ffffffffc0200430:	f2055be3          	bgez	a0,ffffffffc0200366 <kmonitor+0x3e>
}
ffffffffc0200434:	70ea                	ld	ra,184(sp)
ffffffffc0200436:	744a                	ld	s0,176(sp)
ffffffffc0200438:	74aa                	ld	s1,168(sp)
ffffffffc020043a:	69ea                	ld	s3,152(sp)
ffffffffc020043c:	6a4a                	ld	s4,144(sp)
ffffffffc020043e:	6aaa                	ld	s5,136(sp)
ffffffffc0200440:	6b0a                	ld	s6,128(sp)
ffffffffc0200442:	6129                	addi	sp,sp,192
ffffffffc0200444:	8082                	ret

ffffffffc0200446 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void __panic(const char *file, int line, const char *fmt, ...)
{
    if (is_panic)
ffffffffc0200446:	0009b317          	auipc	t1,0x9b
ffffffffc020044a:	56a33303          	ld	t1,1386(t1) # ffffffffc029b9b0 <is_panic>
{
ffffffffc020044e:	715d                	addi	sp,sp,-80
ffffffffc0200450:	ec06                	sd	ra,24(sp)
ffffffffc0200452:	f436                	sd	a3,40(sp)
ffffffffc0200454:	f83a                	sd	a4,48(sp)
ffffffffc0200456:	fc3e                	sd	a5,56(sp)
ffffffffc0200458:	e0c2                	sd	a6,64(sp)
ffffffffc020045a:	e4c6                	sd	a7,72(sp)
    if (is_panic)
ffffffffc020045c:	02031e63          	bnez	t1,ffffffffc0200498 <__panic+0x52>
    {
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc0200460:	4705                	li	a4,1

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc0200462:	103c                	addi	a5,sp,40
ffffffffc0200464:	e822                	sd	s0,16(sp)
ffffffffc0200466:	8432                	mv	s0,a2
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200468:	862e                	mv	a2,a1
ffffffffc020046a:	85aa                	mv	a1,a0
ffffffffc020046c:	00005517          	auipc	a0,0x5
ffffffffc0200470:	60450513          	addi	a0,a0,1540 # ffffffffc0205a70 <etext+0x268>
    is_panic = 1;
ffffffffc0200474:	0009b697          	auipc	a3,0x9b
ffffffffc0200478:	52e6be23          	sd	a4,1340(a3) # ffffffffc029b9b0 <is_panic>
    va_start(ap, fmt);
ffffffffc020047c:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020047e:	d17ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200482:	65a2                	ld	a1,8(sp)
ffffffffc0200484:	8522                	mv	a0,s0
ffffffffc0200486:	cefff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc020048a:	00005517          	auipc	a0,0x5
ffffffffc020048e:	60650513          	addi	a0,a0,1542 # ffffffffc0205a90 <etext+0x288>
ffffffffc0200492:	d03ff0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0200496:	6442                	ld	s0,16(sp)
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc0200498:	4501                	li	a0,0
ffffffffc020049a:	4581                	li	a1,0
ffffffffc020049c:	4601                	li	a2,0
ffffffffc020049e:	48a1                	li	a7,8
ffffffffc02004a0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004a4:	460000ef          	jal	ffffffffc0200904 <intr_disable>
    while (1)
    {
        kmonitor(NULL);
ffffffffc02004a8:	4501                	li	a0,0
ffffffffc02004aa:	e7fff0ef          	jal	ffffffffc0200328 <kmonitor>
    while (1)
ffffffffc02004ae:	bfed                	j	ffffffffc02004a8 <__panic+0x62>

ffffffffc02004b0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void __warn(const char *file, int line, const char *fmt, ...)
{
ffffffffc02004b0:	715d                	addi	sp,sp,-80
ffffffffc02004b2:	e822                	sd	s0,16(sp)
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004b4:	02810313          	addi	t1,sp,40
{
ffffffffc02004b8:	8432                	mv	s0,a2
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004ba:	862e                	mv	a2,a1
ffffffffc02004bc:	85aa                	mv	a1,a0
ffffffffc02004be:	00005517          	auipc	a0,0x5
ffffffffc02004c2:	5da50513          	addi	a0,a0,1498 # ffffffffc0205a98 <etext+0x290>
{
ffffffffc02004c6:	ec06                	sd	ra,24(sp)
ffffffffc02004c8:	f436                	sd	a3,40(sp)
ffffffffc02004ca:	f83a                	sd	a4,48(sp)
ffffffffc02004cc:	fc3e                	sd	a5,56(sp)
ffffffffc02004ce:	e0c2                	sd	a6,64(sp)
ffffffffc02004d0:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02004d2:	e41a                	sd	t1,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004d4:	cc1ff0ef          	jal	ffffffffc0200194 <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004d8:	65a2                	ld	a1,8(sp)
ffffffffc02004da:	8522                	mv	a0,s0
ffffffffc02004dc:	c99ff0ef          	jal	ffffffffc0200174 <vcprintf>
    cprintf("\n");
ffffffffc02004e0:	00005517          	auipc	a0,0x5
ffffffffc02004e4:	5b050513          	addi	a0,a0,1456 # ffffffffc0205a90 <etext+0x288>
ffffffffc02004e8:	cadff0ef          	jal	ffffffffc0200194 <cprintf>
    va_end(ap);
}
ffffffffc02004ec:	60e2                	ld	ra,24(sp)
ffffffffc02004ee:	6442                	ld	s0,16(sp)
ffffffffc02004f0:	6161                	addi	sp,sp,80
ffffffffc02004f2:	8082                	ret

ffffffffc02004f4 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc02004f4:	67e1                	lui	a5,0x18
ffffffffc02004f6:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xe4a8>
ffffffffc02004fa:	0009b717          	auipc	a4,0x9b
ffffffffc02004fe:	4af73f23          	sd	a5,1214(a4) # ffffffffc029b9b8 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200502:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200506:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200508:	953e                	add	a0,a0,a5
ffffffffc020050a:	4601                	li	a2,0
ffffffffc020050c:	4881                	li	a7,0
ffffffffc020050e:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200512:	02000793          	li	a5,32
ffffffffc0200516:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc020051a:	00005517          	auipc	a0,0x5
ffffffffc020051e:	59e50513          	addi	a0,a0,1438 # ffffffffc0205ab8 <etext+0x2b0>
    ticks = 0;
ffffffffc0200522:	0009b797          	auipc	a5,0x9b
ffffffffc0200526:	4807bf23          	sd	zero,1182(a5) # ffffffffc029b9c0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc020052a:	b1ad                	j	ffffffffc0200194 <cprintf>

ffffffffc020052c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020052c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200530:	0009b797          	auipc	a5,0x9b
ffffffffc0200534:	4887b783          	ld	a5,1160(a5) # ffffffffc029b9b8 <timebase>
ffffffffc0200538:	4581                	li	a1,0
ffffffffc020053a:	4601                	li	a2,0
ffffffffc020053c:	953e                	add	a0,a0,a5
ffffffffc020053e:	4881                	li	a7,0
ffffffffc0200540:	00000073          	ecall
ffffffffc0200544:	8082                	ret

ffffffffc0200546 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200546:	8082                	ret

ffffffffc0200548 <cons_putc>:
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void)
{
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0200548:	100027f3          	csrr	a5,sstatus
ffffffffc020054c:	8b89                	andi	a5,a5,2
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc020054e:	0ff57513          	zext.b	a0,a0
ffffffffc0200552:	e799                	bnez	a5,ffffffffc0200560 <cons_putc+0x18>
ffffffffc0200554:	4581                	li	a1,0
ffffffffc0200556:	4601                	li	a2,0
ffffffffc0200558:	4885                	li	a7,1
ffffffffc020055a:	00000073          	ecall
    return 0;
}

static inline void __intr_restore(bool flag)
{
    if (flag)
ffffffffc020055e:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc0200560:	1101                	addi	sp,sp,-32
ffffffffc0200562:	ec06                	sd	ra,24(sp)
ffffffffc0200564:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0200566:	39e000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020056a:	6522                	ld	a0,8(sp)
ffffffffc020056c:	4581                	li	a1,0
ffffffffc020056e:	4601                	li	a2,0
ffffffffc0200570:	4885                	li	a7,1
ffffffffc0200572:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc0200576:	60e2                	ld	ra,24(sp)
ffffffffc0200578:	6105                	addi	sp,sp,32
    {
        intr_enable();
ffffffffc020057a:	a651                	j	ffffffffc02008fe <intr_enable>

ffffffffc020057c <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020057c:	100027f3          	csrr	a5,sstatus
ffffffffc0200580:	8b89                	andi	a5,a5,2
ffffffffc0200582:	eb89                	bnez	a5,ffffffffc0200594 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc0200584:	4501                	li	a0,0
ffffffffc0200586:	4581                	li	a1,0
ffffffffc0200588:	4601                	li	a2,0
ffffffffc020058a:	4889                	li	a7,2
ffffffffc020058c:	00000073          	ecall
ffffffffc0200590:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc0200592:	8082                	ret
int cons_getc(void) {
ffffffffc0200594:	1101                	addi	sp,sp,-32
ffffffffc0200596:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0200598:	36c000ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020059c:	4501                	li	a0,0
ffffffffc020059e:	4581                	li	a1,0
ffffffffc02005a0:	4601                	li	a2,0
ffffffffc02005a2:	4889                	li	a7,2
ffffffffc02005a4:	00000073          	ecall
ffffffffc02005a8:	2501                	sext.w	a0,a0
ffffffffc02005aa:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005ac:	352000ef          	jal	ffffffffc02008fe <intr_enable>
}
ffffffffc02005b0:	60e2                	ld	ra,24(sp)
ffffffffc02005b2:	6522                	ld	a0,8(sp)
ffffffffc02005b4:	6105                	addi	sp,sp,32
ffffffffc02005b6:	8082                	ret

ffffffffc02005b8 <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc02005b8:	7179                	addi	sp,sp,-48
    cprintf("DTB Init\n");
ffffffffc02005ba:	00005517          	auipc	a0,0x5
ffffffffc02005be:	51e50513          	addi	a0,a0,1310 # ffffffffc0205ad8 <etext+0x2d0>
void dtb_init(void) {
ffffffffc02005c2:	f406                	sd	ra,40(sp)
ffffffffc02005c4:	f022                	sd	s0,32(sp)
    cprintf("DTB Init\n");
ffffffffc02005c6:	bcfff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005ca:	0000b597          	auipc	a1,0xb
ffffffffc02005ce:	a365b583          	ld	a1,-1482(a1) # ffffffffc020b000 <boot_hartid>
ffffffffc02005d2:	00005517          	auipc	a0,0x5
ffffffffc02005d6:	51650513          	addi	a0,a0,1302 # ffffffffc0205ae8 <etext+0x2e0>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005da:	0000b417          	auipc	s0,0xb
ffffffffc02005de:	a2e40413          	addi	s0,s0,-1490 # ffffffffc020b008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02005e2:	bb3ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02005e6:	600c                	ld	a1,0(s0)
ffffffffc02005e8:	00005517          	auipc	a0,0x5
ffffffffc02005ec:	51050513          	addi	a0,a0,1296 # ffffffffc0205af8 <etext+0x2f0>
ffffffffc02005f0:	ba5ff0ef          	jal	ffffffffc0200194 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02005f4:	6018                	ld	a4,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02005f6:	00005517          	auipc	a0,0x5
ffffffffc02005fa:	51a50513          	addi	a0,a0,1306 # ffffffffc0205b10 <etext+0x308>
    if (boot_dtb == 0) {
ffffffffc02005fe:	10070163          	beqz	a4,ffffffffc0200700 <dtb_init+0x148>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc0200602:	57f5                	li	a5,-3
ffffffffc0200604:	07fa                	slli	a5,a5,0x1e
ffffffffc0200606:	973e                	add	a4,a4,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc0200608:	431c                	lw	a5,0(a4)
    if (magic != 0xd00dfeed) {
ffffffffc020060a:	d00e06b7          	lui	a3,0xd00e0
ffffffffc020060e:	eed68693          	addi	a3,a3,-275 # ffffffffd00dfeed <end+0xfe444bd>
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200612:	0087d59b          	srliw	a1,a5,0x8
ffffffffc0200616:	0187961b          	slliw	a2,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020061a:	0187d51b          	srliw	a0,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020061e:	0ff5f593          	zext.b	a1,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200622:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200626:	05c2                	slli	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200628:	8e49                	or	a2,a2,a0
ffffffffc020062a:	0ff7f793          	zext.b	a5,a5
ffffffffc020062e:	8dd1                	or	a1,a1,a2
ffffffffc0200630:	07a2                	slli	a5,a5,0x8
ffffffffc0200632:	8ddd                	or	a1,a1,a5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200634:	00ff0837          	lui	a6,0xff0
    if (magic != 0xd00dfeed) {
ffffffffc0200638:	0cd59863          	bne	a1,a3,ffffffffc0200708 <dtb_init+0x150>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc020063c:	4710                	lw	a2,8(a4)
ffffffffc020063e:	4754                	lw	a3,12(a4)
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200640:	e84a                	sd	s2,16(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200642:	0086541b          	srliw	s0,a2,0x8
ffffffffc0200646:	0086d79b          	srliw	a5,a3,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020064a:	01865e1b          	srliw	t3,a2,0x18
ffffffffc020064e:	0186d89b          	srliw	a7,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200652:	0186151b          	slliw	a0,a2,0x18
ffffffffc0200656:	0186959b          	slliw	a1,a3,0x18
ffffffffc020065a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020065e:	0106561b          	srliw	a2,a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200662:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200666:	0106d69b          	srliw	a3,a3,0x10
ffffffffc020066a:	01c56533          	or	a0,a0,t3
ffffffffc020066e:	0115e5b3          	or	a1,a1,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200672:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200676:	0ff67613          	zext.b	a2,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020067a:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020067e:	0ff6f693          	zext.b	a3,a3
ffffffffc0200682:	8c49                	or	s0,s0,a0
ffffffffc0200684:	0622                	slli	a2,a2,0x8
ffffffffc0200686:	8fcd                	or	a5,a5,a1
ffffffffc0200688:	06a2                	slli	a3,a3,0x8
ffffffffc020068a:	8c51                	or	s0,s0,a2
ffffffffc020068c:	8fd5                	or	a5,a5,a3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020068e:	1402                	slli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200690:	1782                	slli	a5,a5,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200692:	9001                	srli	s0,s0,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200694:	9381                	srli	a5,a5,0x20
ffffffffc0200696:	ec26                	sd	s1,24(sp)
    int in_memory_node = 0;
ffffffffc0200698:	4301                	li	t1,0
        switch (token) {
ffffffffc020069a:	488d                	li	a7,3
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020069c:	943a                	add	s0,s0,a4
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020069e:	00e78933          	add	s2,a5,a4
        switch (token) {
ffffffffc02006a2:	4e05                	li	t3,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006a4:	4018                	lw	a4,0(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006a6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02006aa:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006ae:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006b2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006b6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02006ba:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02006be:	8ed1                	or	a3,a3,a2
ffffffffc02006c0:	0ff77713          	zext.b	a4,a4
ffffffffc02006c4:	8fd5                	or	a5,a5,a3
ffffffffc02006c6:	0722                	slli	a4,a4,0x8
ffffffffc02006c8:	8fd9                	or	a5,a5,a4
        switch (token) {
ffffffffc02006ca:	05178763          	beq	a5,a7,ffffffffc0200718 <dtb_init+0x160>
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02006ce:	0411                	addi	s0,s0,4
        switch (token) {
ffffffffc02006d0:	00f8e963          	bltu	a7,a5,ffffffffc02006e2 <dtb_init+0x12a>
ffffffffc02006d4:	07c78d63          	beq	a5,t3,ffffffffc020074e <dtb_init+0x196>
ffffffffc02006d8:	4709                	li	a4,2
ffffffffc02006da:	00e79763          	bne	a5,a4,ffffffffc02006e8 <dtb_init+0x130>
ffffffffc02006de:	4301                	li	t1,0
ffffffffc02006e0:	b7d1                	j	ffffffffc02006a4 <dtb_init+0xec>
ffffffffc02006e2:	4711                	li	a4,4
ffffffffc02006e4:	fce780e3          	beq	a5,a4,ffffffffc02006a4 <dtb_init+0xec>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02006e8:	00005517          	auipc	a0,0x5
ffffffffc02006ec:	4f050513          	addi	a0,a0,1264 # ffffffffc0205bd8 <etext+0x3d0>
ffffffffc02006f0:	aa5ff0ef          	jal	ffffffffc0200194 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02006f4:	64e2                	ld	s1,24(sp)
ffffffffc02006f6:	6942                	ld	s2,16(sp)
ffffffffc02006f8:	00005517          	auipc	a0,0x5
ffffffffc02006fc:	51850513          	addi	a0,a0,1304 # ffffffffc0205c10 <etext+0x408>
}
ffffffffc0200700:	7402                	ld	s0,32(sp)
ffffffffc0200702:	70a2                	ld	ra,40(sp)
ffffffffc0200704:	6145                	addi	sp,sp,48
    cprintf("DTB init completed\n");
ffffffffc0200706:	b479                	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200708:	7402                	ld	s0,32(sp)
ffffffffc020070a:	70a2                	ld	ra,40(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020070c:	00005517          	auipc	a0,0x5
ffffffffc0200710:	42450513          	addi	a0,a0,1060 # ffffffffc0205b30 <etext+0x328>
}
ffffffffc0200714:	6145                	addi	sp,sp,48
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200716:	bcbd                	j	ffffffffc0200194 <cprintf>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200718:	4058                	lw	a4,4(s0)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020071a:	0087579b          	srliw	a5,a4,0x8
ffffffffc020071e:	0187169b          	slliw	a3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200722:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200726:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020072a:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020072e:	0107f7b3          	and	a5,a5,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200732:	8ed1                	or	a3,a3,a2
ffffffffc0200734:	0ff77713          	zext.b	a4,a4
ffffffffc0200738:	8fd5                	or	a5,a5,a3
ffffffffc020073a:	0722                	slli	a4,a4,0x8
ffffffffc020073c:	8fd9                	or	a5,a5,a4
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc020073e:	04031463          	bnez	t1,ffffffffc0200786 <dtb_init+0x1ce>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc0200742:	1782                	slli	a5,a5,0x20
ffffffffc0200744:	9381                	srli	a5,a5,0x20
ffffffffc0200746:	043d                	addi	s0,s0,15
ffffffffc0200748:	943e                	add	s0,s0,a5
ffffffffc020074a:	9871                	andi	s0,s0,-4
                break;
ffffffffc020074c:	bfa1                	j	ffffffffc02006a4 <dtb_init+0xec>
                int name_len = strlen(name);
ffffffffc020074e:	8522                	mv	a0,s0
ffffffffc0200750:	e01a                	sd	t1,0(sp)
ffffffffc0200752:	7d9040ef          	jal	ffffffffc020572a <strlen>
ffffffffc0200756:	84aa                	mv	s1,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200758:	4619                	li	a2,6
ffffffffc020075a:	8522                	mv	a0,s0
ffffffffc020075c:	00005597          	auipc	a1,0x5
ffffffffc0200760:	3fc58593          	addi	a1,a1,1020 # ffffffffc0205b58 <etext+0x350>
ffffffffc0200764:	040050ef          	jal	ffffffffc02057a4 <strncmp>
ffffffffc0200768:	6302                	ld	t1,0(sp)
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020076a:	0411                	addi	s0,s0,4
ffffffffc020076c:	0004879b          	sext.w	a5,s1
ffffffffc0200770:	943e                	add	s0,s0,a5
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200772:	00153513          	seqz	a0,a0
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc0200776:	9871                	andi	s0,s0,-4
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200778:	00a36333          	or	t1,t1,a0
                break;
ffffffffc020077c:	00ff0837          	lui	a6,0xff0
ffffffffc0200780:	488d                	li	a7,3
ffffffffc0200782:	4e05                	li	t3,1
ffffffffc0200784:	b705                	j	ffffffffc02006a4 <dtb_init+0xec>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200786:	4418                	lw	a4,8(s0)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc0200788:	00005597          	auipc	a1,0x5
ffffffffc020078c:	3d858593          	addi	a1,a1,984 # ffffffffc0205b60 <etext+0x358>
ffffffffc0200790:	e43e                	sd	a5,8(sp)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200792:	0087551b          	srliw	a0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200796:	0187561b          	srliw	a2,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020079a:	0187169b          	slliw	a3,a4,0x18
ffffffffc020079e:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007a2:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007a6:	01057533          	and	a0,a0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007aa:	8ed1                	or	a3,a3,a2
ffffffffc02007ac:	0ff77713          	zext.b	a4,a4
ffffffffc02007b0:	0722                	slli	a4,a4,0x8
ffffffffc02007b2:	8d55                	or	a0,a0,a3
ffffffffc02007b4:	8d59                	or	a0,a0,a4
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02007b6:	1502                	slli	a0,a0,0x20
ffffffffc02007b8:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02007ba:	954a                	add	a0,a0,s2
ffffffffc02007bc:	e01a                	sd	t1,0(sp)
ffffffffc02007be:	7b3040ef          	jal	ffffffffc0205770 <strcmp>
ffffffffc02007c2:	67a2                	ld	a5,8(sp)
ffffffffc02007c4:	473d                	li	a4,15
ffffffffc02007c6:	6302                	ld	t1,0(sp)
ffffffffc02007c8:	00ff0837          	lui	a6,0xff0
ffffffffc02007cc:	488d                	li	a7,3
ffffffffc02007ce:	4e05                	li	t3,1
ffffffffc02007d0:	f6f779e3          	bgeu	a4,a5,ffffffffc0200742 <dtb_init+0x18a>
ffffffffc02007d4:	f53d                	bnez	a0,ffffffffc0200742 <dtb_init+0x18a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc02007d6:	00c43683          	ld	a3,12(s0)
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc02007da:	01443703          	ld	a4,20(s0)
        cprintf("Physical Memory from DTB:\n");
ffffffffc02007de:	00005517          	auipc	a0,0x5
ffffffffc02007e2:	38a50513          	addi	a0,a0,906 # ffffffffc0205b68 <etext+0x360>
           fdt32_to_cpu(x >> 32);
ffffffffc02007e6:	4206d793          	srai	a5,a3,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007ea:	0087d31b          	srliw	t1,a5,0x8
ffffffffc02007ee:	00871f93          	slli	t6,a4,0x8
           fdt32_to_cpu(x >> 32);
ffffffffc02007f2:	42075893          	srai	a7,a4,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02007f6:	0187df1b          	srliw	t5,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02007fa:	0187959b          	slliw	a1,a5,0x18
ffffffffc02007fe:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200802:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200806:	420fd613          	srai	a2,t6,0x20
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020080a:	0188de9b          	srliw	t4,a7,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020080e:	01037333          	and	t1,t1,a6
ffffffffc0200812:	01889e1b          	slliw	t3,a7,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200816:	01e5e5b3          	or	a1,a1,t5
ffffffffc020081a:	0ff7f793          	zext.b	a5,a5
ffffffffc020081e:	01de6e33          	or	t3,t3,t4
ffffffffc0200822:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200826:	01067633          	and	a2,a2,a6
ffffffffc020082a:	0086d31b          	srliw	t1,a3,0x8
ffffffffc020082e:	0087541b          	srliw	s0,a4,0x8
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200832:	07a2                	slli	a5,a5,0x8
ffffffffc0200834:	0108d89b          	srliw	a7,a7,0x10
ffffffffc0200838:	0186df1b          	srliw	t5,a3,0x18
ffffffffc020083c:	01875e9b          	srliw	t4,a4,0x18
ffffffffc0200840:	8ddd                	or	a1,a1,a5
ffffffffc0200842:	01c66633          	or	a2,a2,t3
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200846:	0186979b          	slliw	a5,a3,0x18
ffffffffc020084a:	01871e1b          	slliw	t3,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020084e:	0ff8f893          	zext.b	a7,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200852:	0103131b          	slliw	t1,t1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200856:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020085a:	0104141b          	slliw	s0,s0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020085e:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200862:	01037333          	and	t1,t1,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200866:	08a2                	slli	a7,a7,0x8
ffffffffc0200868:	01e7e7b3          	or	a5,a5,t5
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020086c:	01047433          	and	s0,s0,a6
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200870:	0ff6f693          	zext.b	a3,a3
ffffffffc0200874:	01de6833          	or	a6,t3,t4
ffffffffc0200878:	0ff77713          	zext.b	a4,a4
ffffffffc020087c:	01166633          	or	a2,a2,a7
ffffffffc0200880:	0067e7b3          	or	a5,a5,t1
ffffffffc0200884:	06a2                	slli	a3,a3,0x8
ffffffffc0200886:	01046433          	or	s0,s0,a6
ffffffffc020088a:	0722                	slli	a4,a4,0x8
ffffffffc020088c:	8fd5                	or	a5,a5,a3
ffffffffc020088e:	8c59                	or	s0,s0,a4
           fdt32_to_cpu(x >> 32);
ffffffffc0200890:	1582                	slli	a1,a1,0x20
ffffffffc0200892:	1602                	slli	a2,a2,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200894:	1782                	slli	a5,a5,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200896:	9201                	srli	a2,a2,0x20
ffffffffc0200898:	9181                	srli	a1,a1,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc020089a:	1402                	slli	s0,s0,0x20
ffffffffc020089c:	00b7e4b3          	or	s1,a5,a1
ffffffffc02008a0:	8c51                	or	s0,s0,a2
        cprintf("Physical Memory from DTB:\n");
ffffffffc02008a2:	8f3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc02008a6:	85a6                	mv	a1,s1
ffffffffc02008a8:	00005517          	auipc	a0,0x5
ffffffffc02008ac:	2e050513          	addi	a0,a0,736 # ffffffffc0205b88 <etext+0x380>
ffffffffc02008b0:	8e5ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc02008b4:	01445613          	srli	a2,s0,0x14
ffffffffc02008b8:	85a2                	mv	a1,s0
ffffffffc02008ba:	00005517          	auipc	a0,0x5
ffffffffc02008be:	2e650513          	addi	a0,a0,742 # ffffffffc0205ba0 <etext+0x398>
ffffffffc02008c2:	8d3ff0ef          	jal	ffffffffc0200194 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc02008c6:	009405b3          	add	a1,s0,s1
ffffffffc02008ca:	15fd                	addi	a1,a1,-1
ffffffffc02008cc:	00005517          	auipc	a0,0x5
ffffffffc02008d0:	2f450513          	addi	a0,a0,756 # ffffffffc0205bc0 <etext+0x3b8>
ffffffffc02008d4:	8c1ff0ef          	jal	ffffffffc0200194 <cprintf>
        memory_base = mem_base;
ffffffffc02008d8:	0009b797          	auipc	a5,0x9b
ffffffffc02008dc:	0e97bc23          	sd	s1,248(a5) # ffffffffc029b9d0 <memory_base>
        memory_size = mem_size;
ffffffffc02008e0:	0009b797          	auipc	a5,0x9b
ffffffffc02008e4:	0e87b423          	sd	s0,232(a5) # ffffffffc029b9c8 <memory_size>
ffffffffc02008e8:	b531                	j	ffffffffc02006f4 <dtb_init+0x13c>

ffffffffc02008ea <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
}
ffffffffc02008ea:	0009b517          	auipc	a0,0x9b
ffffffffc02008ee:	0e653503          	ld	a0,230(a0) # ffffffffc029b9d0 <memory_base>
ffffffffc02008f2:	8082                	ret

ffffffffc02008f4 <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
}
ffffffffc02008f4:	0009b517          	auipc	a0,0x9b
ffffffffc02008f8:	0d453503          	ld	a0,212(a0) # ffffffffc029b9c8 <memory_size>
ffffffffc02008fc:	8082                	ret

ffffffffc02008fe <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02008fe:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200902:	8082                	ret

ffffffffc0200904 <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200904:	100177f3          	csrrci	a5,sstatus,2
ffffffffc0200908:	8082                	ret

ffffffffc020090a <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc020090a:	8082                	ret

ffffffffc020090c <idt_init>:
void idt_init(void)
{
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc020090c:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200910:	00000797          	auipc	a5,0x0
ffffffffc0200914:	4c478793          	addi	a5,a5,1220 # ffffffffc0200dd4 <__alltraps>
ffffffffc0200918:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc020091c:	000407b7          	lui	a5,0x40
ffffffffc0200920:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc0200924:	8082                	ret

ffffffffc0200926 <print_regs>:
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr)
{
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200926:	610c                	ld	a1,0(a0)
{
ffffffffc0200928:	1141                	addi	sp,sp,-16
ffffffffc020092a:	e022                	sd	s0,0(sp)
ffffffffc020092c:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020092e:	00005517          	auipc	a0,0x5
ffffffffc0200932:	2fa50513          	addi	a0,a0,762 # ffffffffc0205c28 <etext+0x420>
{
ffffffffc0200936:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200938:	85dff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc020093c:	640c                	ld	a1,8(s0)
ffffffffc020093e:	00005517          	auipc	a0,0x5
ffffffffc0200942:	30250513          	addi	a0,a0,770 # ffffffffc0205c40 <etext+0x438>
ffffffffc0200946:	84fff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc020094a:	680c                	ld	a1,16(s0)
ffffffffc020094c:	00005517          	auipc	a0,0x5
ffffffffc0200950:	30c50513          	addi	a0,a0,780 # ffffffffc0205c58 <etext+0x450>
ffffffffc0200954:	841ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200958:	6c0c                	ld	a1,24(s0)
ffffffffc020095a:	00005517          	auipc	a0,0x5
ffffffffc020095e:	31650513          	addi	a0,a0,790 # ffffffffc0205c70 <etext+0x468>
ffffffffc0200962:	833ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200966:	700c                	ld	a1,32(s0)
ffffffffc0200968:	00005517          	auipc	a0,0x5
ffffffffc020096c:	32050513          	addi	a0,a0,800 # ffffffffc0205c88 <etext+0x480>
ffffffffc0200970:	825ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200974:	740c                	ld	a1,40(s0)
ffffffffc0200976:	00005517          	auipc	a0,0x5
ffffffffc020097a:	32a50513          	addi	a0,a0,810 # ffffffffc0205ca0 <etext+0x498>
ffffffffc020097e:	817ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200982:	780c                	ld	a1,48(s0)
ffffffffc0200984:	00005517          	auipc	a0,0x5
ffffffffc0200988:	33450513          	addi	a0,a0,820 # ffffffffc0205cb8 <etext+0x4b0>
ffffffffc020098c:	809ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200990:	7c0c                	ld	a1,56(s0)
ffffffffc0200992:	00005517          	auipc	a0,0x5
ffffffffc0200996:	33e50513          	addi	a0,a0,830 # ffffffffc0205cd0 <etext+0x4c8>
ffffffffc020099a:	ffaff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020099e:	602c                	ld	a1,64(s0)
ffffffffc02009a0:	00005517          	auipc	a0,0x5
ffffffffc02009a4:	34850513          	addi	a0,a0,840 # ffffffffc0205ce8 <etext+0x4e0>
ffffffffc02009a8:	fecff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc02009ac:	642c                	ld	a1,72(s0)
ffffffffc02009ae:	00005517          	auipc	a0,0x5
ffffffffc02009b2:	35250513          	addi	a0,a0,850 # ffffffffc0205d00 <etext+0x4f8>
ffffffffc02009b6:	fdeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc02009ba:	682c                	ld	a1,80(s0)
ffffffffc02009bc:	00005517          	auipc	a0,0x5
ffffffffc02009c0:	35c50513          	addi	a0,a0,860 # ffffffffc0205d18 <etext+0x510>
ffffffffc02009c4:	fd0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc02009c8:	6c2c                	ld	a1,88(s0)
ffffffffc02009ca:	00005517          	auipc	a0,0x5
ffffffffc02009ce:	36650513          	addi	a0,a0,870 # ffffffffc0205d30 <etext+0x528>
ffffffffc02009d2:	fc2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc02009d6:	702c                	ld	a1,96(s0)
ffffffffc02009d8:	00005517          	auipc	a0,0x5
ffffffffc02009dc:	37050513          	addi	a0,a0,880 # ffffffffc0205d48 <etext+0x540>
ffffffffc02009e0:	fb4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc02009e4:	742c                	ld	a1,104(s0)
ffffffffc02009e6:	00005517          	auipc	a0,0x5
ffffffffc02009ea:	37a50513          	addi	a0,a0,890 # ffffffffc0205d60 <etext+0x558>
ffffffffc02009ee:	fa6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02009f2:	782c                	ld	a1,112(s0)
ffffffffc02009f4:	00005517          	auipc	a0,0x5
ffffffffc02009f8:	38450513          	addi	a0,a0,900 # ffffffffc0205d78 <etext+0x570>
ffffffffc02009fc:	f98ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200a00:	7c2c                	ld	a1,120(s0)
ffffffffc0200a02:	00005517          	auipc	a0,0x5
ffffffffc0200a06:	38e50513          	addi	a0,a0,910 # ffffffffc0205d90 <etext+0x588>
ffffffffc0200a0a:	f8aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200a0e:	604c                	ld	a1,128(s0)
ffffffffc0200a10:	00005517          	auipc	a0,0x5
ffffffffc0200a14:	39850513          	addi	a0,a0,920 # ffffffffc0205da8 <etext+0x5a0>
ffffffffc0200a18:	f7cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200a1c:	644c                	ld	a1,136(s0)
ffffffffc0200a1e:	00005517          	auipc	a0,0x5
ffffffffc0200a22:	3a250513          	addi	a0,a0,930 # ffffffffc0205dc0 <etext+0x5b8>
ffffffffc0200a26:	f6eff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200a2a:	684c                	ld	a1,144(s0)
ffffffffc0200a2c:	00005517          	auipc	a0,0x5
ffffffffc0200a30:	3ac50513          	addi	a0,a0,940 # ffffffffc0205dd8 <etext+0x5d0>
ffffffffc0200a34:	f60ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc0200a38:	6c4c                	ld	a1,152(s0)
ffffffffc0200a3a:	00005517          	auipc	a0,0x5
ffffffffc0200a3e:	3b650513          	addi	a0,a0,950 # ffffffffc0205df0 <etext+0x5e8>
ffffffffc0200a42:	f52ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc0200a46:	704c                	ld	a1,160(s0)
ffffffffc0200a48:	00005517          	auipc	a0,0x5
ffffffffc0200a4c:	3c050513          	addi	a0,a0,960 # ffffffffc0205e08 <etext+0x600>
ffffffffc0200a50:	f44ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200a54:	744c                	ld	a1,168(s0)
ffffffffc0200a56:	00005517          	auipc	a0,0x5
ffffffffc0200a5a:	3ca50513          	addi	a0,a0,970 # ffffffffc0205e20 <etext+0x618>
ffffffffc0200a5e:	f36ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200a62:	784c                	ld	a1,176(s0)
ffffffffc0200a64:	00005517          	auipc	a0,0x5
ffffffffc0200a68:	3d450513          	addi	a0,a0,980 # ffffffffc0205e38 <etext+0x630>
ffffffffc0200a6c:	f28ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200a70:	7c4c                	ld	a1,184(s0)
ffffffffc0200a72:	00005517          	auipc	a0,0x5
ffffffffc0200a76:	3de50513          	addi	a0,a0,990 # ffffffffc0205e50 <etext+0x648>
ffffffffc0200a7a:	f1aff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc0200a7e:	606c                	ld	a1,192(s0)
ffffffffc0200a80:	00005517          	auipc	a0,0x5
ffffffffc0200a84:	3e850513          	addi	a0,a0,1000 # ffffffffc0205e68 <etext+0x660>
ffffffffc0200a88:	f0cff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc0200a8c:	646c                	ld	a1,200(s0)
ffffffffc0200a8e:	00005517          	auipc	a0,0x5
ffffffffc0200a92:	3f250513          	addi	a0,a0,1010 # ffffffffc0205e80 <etext+0x678>
ffffffffc0200a96:	efeff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc0200a9a:	686c                	ld	a1,208(s0)
ffffffffc0200a9c:	00005517          	auipc	a0,0x5
ffffffffc0200aa0:	3fc50513          	addi	a0,a0,1020 # ffffffffc0205e98 <etext+0x690>
ffffffffc0200aa4:	ef0ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200aa8:	6c6c                	ld	a1,216(s0)
ffffffffc0200aaa:	00005517          	auipc	a0,0x5
ffffffffc0200aae:	40650513          	addi	a0,a0,1030 # ffffffffc0205eb0 <etext+0x6a8>
ffffffffc0200ab2:	ee2ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200ab6:	706c                	ld	a1,224(s0)
ffffffffc0200ab8:	00005517          	auipc	a0,0x5
ffffffffc0200abc:	41050513          	addi	a0,a0,1040 # ffffffffc0205ec8 <etext+0x6c0>
ffffffffc0200ac0:	ed4ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200ac4:	746c                	ld	a1,232(s0)
ffffffffc0200ac6:	00005517          	auipc	a0,0x5
ffffffffc0200aca:	41a50513          	addi	a0,a0,1050 # ffffffffc0205ee0 <etext+0x6d8>
ffffffffc0200ace:	ec6ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200ad2:	786c                	ld	a1,240(s0)
ffffffffc0200ad4:	00005517          	auipc	a0,0x5
ffffffffc0200ad8:	42450513          	addi	a0,a0,1060 # ffffffffc0205ef8 <etext+0x6f0>
ffffffffc0200adc:	eb8ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae0:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200ae2:	6402                	ld	s0,0(sp)
ffffffffc0200ae4:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200ae6:	00005517          	auipc	a0,0x5
ffffffffc0200aea:	42a50513          	addi	a0,a0,1066 # ffffffffc0205f10 <etext+0x708>
}
ffffffffc0200aee:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200af0:	ea4ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200af4 <print_trapframe>:
{
ffffffffc0200af4:	1141                	addi	sp,sp,-16
ffffffffc0200af6:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200af8:	85aa                	mv	a1,a0
{
ffffffffc0200afa:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200afc:	00005517          	auipc	a0,0x5
ffffffffc0200b00:	42c50513          	addi	a0,a0,1068 # ffffffffc0205f28 <etext+0x720>
{
ffffffffc0200b04:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc0200b06:	e8eff0ef          	jal	ffffffffc0200194 <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200b0a:	8522                	mv	a0,s0
ffffffffc0200b0c:	e1bff0ef          	jal	ffffffffc0200926 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200b10:	10043583          	ld	a1,256(s0)
ffffffffc0200b14:	00005517          	auipc	a0,0x5
ffffffffc0200b18:	42c50513          	addi	a0,a0,1068 # ffffffffc0205f40 <etext+0x738>
ffffffffc0200b1c:	e78ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200b20:	10843583          	ld	a1,264(s0)
ffffffffc0200b24:	00005517          	auipc	a0,0x5
ffffffffc0200b28:	43450513          	addi	a0,a0,1076 # ffffffffc0205f58 <etext+0x750>
ffffffffc0200b2c:	e68ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200b30:	11043583          	ld	a1,272(s0)
ffffffffc0200b34:	00005517          	auipc	a0,0x5
ffffffffc0200b38:	43c50513          	addi	a0,a0,1084 # ffffffffc0205f70 <etext+0x768>
ffffffffc0200b3c:	e58ff0ef          	jal	ffffffffc0200194 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b40:	11843583          	ld	a1,280(s0)
}
ffffffffc0200b44:	6402                	ld	s0,0(sp)
ffffffffc0200b46:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b48:	00005517          	auipc	a0,0x5
ffffffffc0200b4c:	43850513          	addi	a0,a0,1080 # ffffffffc0205f80 <etext+0x778>
}
ffffffffc0200b50:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200b52:	e42ff06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0200b56 <interrupt_handler>:
void interrupt_handler(struct trapframe *tf)
{
    intptr_t cause = (tf->cause << 1) >> 1;

    //static int ticks = 0;
    switch (cause)
ffffffffc0200b56:	11853783          	ld	a5,280(a0)
ffffffffc0200b5a:	472d                	li	a4,11
ffffffffc0200b5c:	0786                	slli	a5,a5,0x1
ffffffffc0200b5e:	8385                	srli	a5,a5,0x1
ffffffffc0200b60:	08f76b63          	bltu	a4,a5,ffffffffc0200bf6 <interrupt_handler+0xa0>
ffffffffc0200b64:	00007717          	auipc	a4,0x7
ffffffffc0200b68:	a3c70713          	addi	a4,a4,-1476 # ffffffffc02075a0 <commands+0x48>
ffffffffc0200b6c:	078a                	slli	a5,a5,0x2
ffffffffc0200b6e:	97ba                	add	a5,a5,a4
ffffffffc0200b70:	439c                	lw	a5,0(a5)
ffffffffc0200b72:	97ba                	add	a5,a5,a4
ffffffffc0200b74:	8782                	jr	a5
        break;
    case IRQ_H_SOFT:
        cprintf("Hypervisor software interrupt\n");
        break;
    case IRQ_M_SOFT:
        cprintf("Machine software interrupt\n");
ffffffffc0200b76:	00005517          	auipc	a0,0x5
ffffffffc0200b7a:	48250513          	addi	a0,a0,1154 # ffffffffc0205ff8 <etext+0x7f0>
ffffffffc0200b7e:	e16ff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Hypervisor software interrupt\n");
ffffffffc0200b82:	00005517          	auipc	a0,0x5
ffffffffc0200b86:	45650513          	addi	a0,a0,1110 # ffffffffc0205fd8 <etext+0x7d0>
ffffffffc0200b8a:	e0aff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("User software interrupt\n");
ffffffffc0200b8e:	00005517          	auipc	a0,0x5
ffffffffc0200b92:	40a50513          	addi	a0,a0,1034 # ffffffffc0205f98 <etext+0x790>
ffffffffc0200b96:	dfeff06f          	j	ffffffffc0200194 <cprintf>
        cprintf("Supervisor software interrupt\n");
ffffffffc0200b9a:	00005517          	auipc	a0,0x5
ffffffffc0200b9e:	41e50513          	addi	a0,a0,1054 # ffffffffc0205fb8 <etext+0x7b0>
ffffffffc0200ba2:	df2ff06f          	j	ffffffffc0200194 <cprintf>
{
ffffffffc0200ba6:	1141                	addi	sp,sp,-16
ffffffffc0200ba8:	e406                	sd	ra,8(sp)
         *(3)当计数器加到100的时候，我们会输出一个`100ticks`表示我们触发了100次时钟中断，同时打印次数（num）加一
         * (4)判断打印次数，当打印次数为10时，调用<sbi.h>中的关机函数关机
         */

        // (1) 设置下一次时钟中断的触发时间
        clock_set_next_event();
ffffffffc0200baa:	983ff0ef          	jal	ffffffffc020052c <clock_set_next_event>
        // (2) ticks计数器自增
        ticks++;
ffffffffc0200bae:	0009b797          	auipc	a5,0x9b
ffffffffc0200bb2:	e1278793          	addi	a5,a5,-494 # ffffffffc029b9c0 <ticks>
ffffffffc0200bb6:	6398                	ld	a4,0(a5)
        // (3) 达到TICK_NUM时标记进程需要重新调度
        if (ticks >= TICK_NUM) {
ffffffffc0200bb8:	06300693          	li	a3,99
        ticks++;
ffffffffc0200bbc:	0705                	addi	a4,a4,1
ffffffffc0200bbe:	e398                	sd	a4,0(a5)
        if (ticks >= TICK_NUM) {
ffffffffc0200bc0:	639c                	ld	a5,0(a5)
ffffffffc0200bc2:	02f6f163          	bgeu	a3,a5,ffffffffc0200be4 <interrupt_handler+0x8e>
            if (current != NULL && current->state == PROC_RUNNABLE) {
ffffffffc0200bc6:	0009b797          	auipc	a5,0x9b
ffffffffc0200bca:	e527b783          	ld	a5,-430(a5) # ffffffffc029ba18 <current>
ffffffffc0200bce:	c799                	beqz	a5,ffffffffc0200bdc <interrupt_handler+0x86>
ffffffffc0200bd0:	4394                	lw	a3,0(a5)
ffffffffc0200bd2:	4709                	li	a4,2
ffffffffc0200bd4:	00e69463          	bne	a3,a4,ffffffffc0200bdc <interrupt_handler+0x86>
                current->need_resched = 1;
ffffffffc0200bd8:	4705                	li	a4,1
ffffffffc0200bda:	ef98                	sd	a4,24(a5)
            }
            ticks = 0;
ffffffffc0200bdc:	0009b797          	auipc	a5,0x9b
ffffffffc0200be0:	de07b223          	sd	zero,-540(a5) # ffffffffc029b9c0 <ticks>
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200be4:	60a2                	ld	ra,8(sp)
ffffffffc0200be6:	0141                	addi	sp,sp,16
ffffffffc0200be8:	8082                	ret
        cprintf("Supervisor external interrupt\n");
ffffffffc0200bea:	00005517          	auipc	a0,0x5
ffffffffc0200bee:	42e50513          	addi	a0,a0,1070 # ffffffffc0206018 <etext+0x810>
ffffffffc0200bf2:	da2ff06f          	j	ffffffffc0200194 <cprintf>
        print_trapframe(tf);
ffffffffc0200bf6:	bdfd                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200bf8 <exception_handler>:
void kernel_execve_ret(struct trapframe *tf, uintptr_t kstacktop);
void exception_handler(struct trapframe *tf)
{
    int ret;
    switch (tf->cause)
ffffffffc0200bf8:	11853783          	ld	a5,280(a0)
ffffffffc0200bfc:	473d                	li	a4,15
ffffffffc0200bfe:	14f76763          	bltu	a4,a5,ffffffffc0200d4c <exception_handler+0x154>
ffffffffc0200c02:	00007717          	auipc	a4,0x7
ffffffffc0200c06:	9ce70713          	addi	a4,a4,-1586 # ffffffffc02075d0 <commands+0x78>
ffffffffc0200c0a:	078a                	slli	a5,a5,0x2
ffffffffc0200c0c:	97ba                	add	a5,a5,a4
ffffffffc0200c0e:	439c                	lw	a5,0(a5)
{
ffffffffc0200c10:	1101                	addi	sp,sp,-32
ffffffffc0200c12:	ec06                	sd	ra,24(sp)
    switch (tf->cause)
ffffffffc0200c14:	97ba                	add	a5,a5,a4
ffffffffc0200c16:	86aa                	mv	a3,a0
ffffffffc0200c18:	8782                	jr	a5
ffffffffc0200c1a:	e42a                	sd	a0,8(sp)
        // cprintf("Environment call from U-mode\n");
        tf->epc += 4;
        syscall();
        break;
    case CAUSE_SUPERVISOR_ECALL:
        cprintf("Environment call from S-mode\n");
ffffffffc0200c1c:	00005517          	auipc	a0,0x5
ffffffffc0200c20:	50450513          	addi	a0,a0,1284 # ffffffffc0206120 <etext+0x918>
ffffffffc0200c24:	d70ff0ef          	jal	ffffffffc0200194 <cprintf>
        tf->epc += 4;
ffffffffc0200c28:	66a2                	ld	a3,8(sp)
ffffffffc0200c2a:	1086b783          	ld	a5,264(a3)
        break;
    default:
        print_trapframe(tf);
        break;
    }
}
ffffffffc0200c2e:	60e2                	ld	ra,24(sp)
        tf->epc += 4;
ffffffffc0200c30:	0791                	addi	a5,a5,4
ffffffffc0200c32:	10f6b423          	sd	a5,264(a3)
}
ffffffffc0200c36:	6105                	addi	sp,sp,32
        syscall();
ffffffffc0200c38:	6940406f          	j	ffffffffc02052cc <syscall>
}
ffffffffc0200c3c:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from H-mode\n");
ffffffffc0200c3e:	00005517          	auipc	a0,0x5
ffffffffc0200c42:	50250513          	addi	a0,a0,1282 # ffffffffc0206140 <etext+0x938>
}
ffffffffc0200c46:	6105                	addi	sp,sp,32
        cprintf("Environment call from H-mode\n");
ffffffffc0200c48:	d4cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c4c:	60e2                	ld	ra,24(sp)
        cprintf("Environment call from M-mode\n");
ffffffffc0200c4e:	00005517          	auipc	a0,0x5
ffffffffc0200c52:	51250513          	addi	a0,a0,1298 # ffffffffc0206160 <etext+0x958>
}
ffffffffc0200c56:	6105                	addi	sp,sp,32
        cprintf("Environment call from M-mode\n");
ffffffffc0200c58:	d3cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c5c:	60e2                	ld	ra,24(sp)
        cprintf("Instruction page fault\n");
ffffffffc0200c5e:	00005517          	auipc	a0,0x5
ffffffffc0200c62:	52250513          	addi	a0,a0,1314 # ffffffffc0206180 <etext+0x978>
}
ffffffffc0200c66:	6105                	addi	sp,sp,32
        cprintf("Instruction page fault\n");
ffffffffc0200c68:	d2cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c6c:	60e2                	ld	ra,24(sp)
        cprintf("Load page fault\n");
ffffffffc0200c6e:	00005517          	auipc	a0,0x5
ffffffffc0200c72:	52a50513          	addi	a0,a0,1322 # ffffffffc0206198 <etext+0x990>
}
ffffffffc0200c76:	6105                	addi	sp,sp,32
        cprintf("Load page fault\n");
ffffffffc0200c78:	d1cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c7c:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO page fault\n");
ffffffffc0200c7e:	00005517          	auipc	a0,0x5
ffffffffc0200c82:	53250513          	addi	a0,a0,1330 # ffffffffc02061b0 <etext+0x9a8>
}
ffffffffc0200c86:	6105                	addi	sp,sp,32
        cprintf("Store/AMO page fault\n");
ffffffffc0200c88:	d0cff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c8c:	60e2                	ld	ra,24(sp)
        cprintf("Instruction address misaligned\n");
ffffffffc0200c8e:	00005517          	auipc	a0,0x5
ffffffffc0200c92:	3aa50513          	addi	a0,a0,938 # ffffffffc0206038 <etext+0x830>
}
ffffffffc0200c96:	6105                	addi	sp,sp,32
        cprintf("Instruction address misaligned\n");
ffffffffc0200c98:	cfcff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200c9c:	60e2                	ld	ra,24(sp)
        cprintf("Instruction access fault\n");
ffffffffc0200c9e:	00005517          	auipc	a0,0x5
ffffffffc0200ca2:	3ba50513          	addi	a0,a0,954 # ffffffffc0206058 <etext+0x850>
}
ffffffffc0200ca6:	6105                	addi	sp,sp,32
        cprintf("Instruction access fault\n");
ffffffffc0200ca8:	cecff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cac:	60e2                	ld	ra,24(sp)
        cprintf("Illegal instruction\n");
ffffffffc0200cae:	00005517          	auipc	a0,0x5
ffffffffc0200cb2:	3ca50513          	addi	a0,a0,970 # ffffffffc0206078 <etext+0x870>
}
ffffffffc0200cb6:	6105                	addi	sp,sp,32
        cprintf("Illegal instruction\n");
ffffffffc0200cb8:	cdcff06f          	j	ffffffffc0200194 <cprintf>
ffffffffc0200cbc:	e42a                	sd	a0,8(sp)
        cprintf("Breakpoint\n");
ffffffffc0200cbe:	00005517          	auipc	a0,0x5
ffffffffc0200cc2:	3d250513          	addi	a0,a0,978 # ffffffffc0206090 <etext+0x888>
ffffffffc0200cc6:	cceff0ef          	jal	ffffffffc0200194 <cprintf>
        if (tf->gpr.a7 == 10)
ffffffffc0200cca:	66a2                	ld	a3,8(sp)
ffffffffc0200ccc:	47a9                	li	a5,10
ffffffffc0200cce:	66d8                	ld	a4,136(a3)
ffffffffc0200cd0:	04f70c63          	beq	a4,a5,ffffffffc0200d28 <exception_handler+0x130>
}
ffffffffc0200cd4:	60e2                	ld	ra,24(sp)
ffffffffc0200cd6:	6105                	addi	sp,sp,32
ffffffffc0200cd8:	8082                	ret
ffffffffc0200cda:	60e2                	ld	ra,24(sp)
        cprintf("Load address misaligned\n");
ffffffffc0200cdc:	00005517          	auipc	a0,0x5
ffffffffc0200ce0:	3c450513          	addi	a0,a0,964 # ffffffffc02060a0 <etext+0x898>
}
ffffffffc0200ce4:	6105                	addi	sp,sp,32
        cprintf("Load address misaligned\n");
ffffffffc0200ce6:	caeff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cea:	60e2                	ld	ra,24(sp)
        cprintf("Load access fault\n");
ffffffffc0200cec:	00005517          	auipc	a0,0x5
ffffffffc0200cf0:	3d450513          	addi	a0,a0,980 # ffffffffc02060c0 <etext+0x8b8>
}
ffffffffc0200cf4:	6105                	addi	sp,sp,32
        cprintf("Load access fault\n");
ffffffffc0200cf6:	c9eff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200cfa:	60e2                	ld	ra,24(sp)
        cprintf("Store/AMO access fault\n");
ffffffffc0200cfc:	00005517          	auipc	a0,0x5
ffffffffc0200d00:	40c50513          	addi	a0,a0,1036 # ffffffffc0206108 <etext+0x900>
}
ffffffffc0200d04:	6105                	addi	sp,sp,32
        cprintf("Store/AMO access fault\n");
ffffffffc0200d06:	c8eff06f          	j	ffffffffc0200194 <cprintf>
}
ffffffffc0200d0a:	60e2                	ld	ra,24(sp)
ffffffffc0200d0c:	6105                	addi	sp,sp,32
        print_trapframe(tf);
ffffffffc0200d0e:	b3dd                	j	ffffffffc0200af4 <print_trapframe>
        panic("AMO address misaligned\n");
ffffffffc0200d10:	00005617          	auipc	a2,0x5
ffffffffc0200d14:	3c860613          	addi	a2,a2,968 # ffffffffc02060d8 <etext+0x8d0>
ffffffffc0200d18:	0c800593          	li	a1,200
ffffffffc0200d1c:	00005517          	auipc	a0,0x5
ffffffffc0200d20:	3d450513          	addi	a0,a0,980 # ffffffffc02060f0 <etext+0x8e8>
ffffffffc0200d24:	f22ff0ef          	jal	ffffffffc0200446 <__panic>
            tf->epc += 4;
ffffffffc0200d28:	1086b783          	ld	a5,264(a3)
ffffffffc0200d2c:	0791                	addi	a5,a5,4
ffffffffc0200d2e:	10f6b423          	sd	a5,264(a3)
            syscall();
ffffffffc0200d32:	59a040ef          	jal	ffffffffc02052cc <syscall>
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d36:	0009b717          	auipc	a4,0x9b
ffffffffc0200d3a:	ce273703          	ld	a4,-798(a4) # ffffffffc029ba18 <current>
ffffffffc0200d3e:	6522                	ld	a0,8(sp)
}
ffffffffc0200d40:	60e2                	ld	ra,24(sp)
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d42:	6b0c                	ld	a1,16(a4)
ffffffffc0200d44:	6789                	lui	a5,0x2
ffffffffc0200d46:	95be                	add	a1,a1,a5
}
ffffffffc0200d48:	6105                	addi	sp,sp,32
            kernel_execve_ret(tf, current->kstack + KSTACKSIZE);
ffffffffc0200d4a:	aaa1                	j	ffffffffc0200ea2 <kernel_execve_ret>
        print_trapframe(tf);
ffffffffc0200d4c:	b365                	j	ffffffffc0200af4 <print_trapframe>

ffffffffc0200d4e <trap>:
 * */
void trap(struct trapframe *tf)
{
    // dispatch based on what type of trap occurred
    //    cputs("some trap");
    if (current == NULL)
ffffffffc0200d4e:	0009b717          	auipc	a4,0x9b
ffffffffc0200d52:	cca73703          	ld	a4,-822(a4) # ffffffffc029ba18 <current>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d56:	11853583          	ld	a1,280(a0)
    if (current == NULL)
ffffffffc0200d5a:	cf21                	beqz	a4,ffffffffc0200db2 <trap+0x64>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d5c:	10053603          	ld	a2,256(a0)
    {
        trap_dispatch(tf);
    }
    else
    {
        struct trapframe *otf = current->tf;
ffffffffc0200d60:	0a073803          	ld	a6,160(a4)
{
ffffffffc0200d64:	1101                	addi	sp,sp,-32
ffffffffc0200d66:	ec06                	sd	ra,24(sp)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200d68:	10067613          	andi	a2,a2,256
        current->tf = tf;
ffffffffc0200d6c:	f348                	sd	a0,160(a4)
    if ((intptr_t)tf->cause < 0)
ffffffffc0200d6e:	e432                	sd	a2,8(sp)
ffffffffc0200d70:	e042                	sd	a6,0(sp)
ffffffffc0200d72:	0205c763          	bltz	a1,ffffffffc0200da0 <trap+0x52>
        exception_handler(tf);
ffffffffc0200d76:	e83ff0ef          	jal	ffffffffc0200bf8 <exception_handler>
ffffffffc0200d7a:	6622                	ld	a2,8(sp)
ffffffffc0200d7c:	6802                	ld	a6,0(sp)
ffffffffc0200d7e:	0009b697          	auipc	a3,0x9b
ffffffffc0200d82:	c9a68693          	addi	a3,a3,-870 # ffffffffc029ba18 <current>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200d86:	6298                	ld	a4,0(a3)
ffffffffc0200d88:	0b073023          	sd	a6,160(a4)
        if (!in_kernel)
ffffffffc0200d8c:	e619                	bnez	a2,ffffffffc0200d9a <trap+0x4c>
        {
            if (current->flags & PF_EXITING)
ffffffffc0200d8e:	0b072783          	lw	a5,176(a4)
ffffffffc0200d92:	8b85                	andi	a5,a5,1
ffffffffc0200d94:	e79d                	bnez	a5,ffffffffc0200dc2 <trap+0x74>
            {
                do_exit(-E_KILLED);
            }
            if (current->need_resched)
ffffffffc0200d96:	6f1c                	ld	a5,24(a4)
ffffffffc0200d98:	e38d                	bnez	a5,ffffffffc0200dba <trap+0x6c>
            {
                schedule();
            }
        }
    }
}
ffffffffc0200d9a:	60e2                	ld	ra,24(sp)
ffffffffc0200d9c:	6105                	addi	sp,sp,32
ffffffffc0200d9e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200da0:	db7ff0ef          	jal	ffffffffc0200b56 <interrupt_handler>
ffffffffc0200da4:	6802                	ld	a6,0(sp)
ffffffffc0200da6:	6622                	ld	a2,8(sp)
ffffffffc0200da8:	0009b697          	auipc	a3,0x9b
ffffffffc0200dac:	c7068693          	addi	a3,a3,-912 # ffffffffc029ba18 <current>
ffffffffc0200db0:	bfd9                	j	ffffffffc0200d86 <trap+0x38>
    if ((intptr_t)tf->cause < 0)
ffffffffc0200db2:	0005c363          	bltz	a1,ffffffffc0200db8 <trap+0x6a>
        exception_handler(tf);
ffffffffc0200db6:	b589                	j	ffffffffc0200bf8 <exception_handler>
        interrupt_handler(tf);
ffffffffc0200db8:	bb79                	j	ffffffffc0200b56 <interrupt_handler>
}
ffffffffc0200dba:	60e2                	ld	ra,24(sp)
ffffffffc0200dbc:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200dbe:	4220406f          	j	ffffffffc02051e0 <schedule>
                do_exit(-E_KILLED);
ffffffffc0200dc2:	555d                	li	a0,-9
ffffffffc0200dc4:	6bc030ef          	jal	ffffffffc0204480 <do_exit>
            if (current->need_resched)
ffffffffc0200dc8:	0009b717          	auipc	a4,0x9b
ffffffffc0200dcc:	c5073703          	ld	a4,-944(a4) # ffffffffc029ba18 <current>
ffffffffc0200dd0:	b7d9                	j	ffffffffc0200d96 <trap+0x48>
	...

ffffffffc0200dd4 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200dd4:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200dd8:	00011463          	bnez	sp,ffffffffc0200de0 <__alltraps+0xc>
ffffffffc0200ddc:	14002173          	csrr	sp,sscratch
ffffffffc0200de0:	712d                	addi	sp,sp,-288
ffffffffc0200de2:	e002                	sd	zero,0(sp)
ffffffffc0200de4:	e406                	sd	ra,8(sp)
ffffffffc0200de6:	ec0e                	sd	gp,24(sp)
ffffffffc0200de8:	f012                	sd	tp,32(sp)
ffffffffc0200dea:	f416                	sd	t0,40(sp)
ffffffffc0200dec:	f81a                	sd	t1,48(sp)
ffffffffc0200dee:	fc1e                	sd	t2,56(sp)
ffffffffc0200df0:	e0a2                	sd	s0,64(sp)
ffffffffc0200df2:	e4a6                	sd	s1,72(sp)
ffffffffc0200df4:	e8aa                	sd	a0,80(sp)
ffffffffc0200df6:	ecae                	sd	a1,88(sp)
ffffffffc0200df8:	f0b2                	sd	a2,96(sp)
ffffffffc0200dfa:	f4b6                	sd	a3,104(sp)
ffffffffc0200dfc:	f8ba                	sd	a4,112(sp)
ffffffffc0200dfe:	fcbe                	sd	a5,120(sp)
ffffffffc0200e00:	e142                	sd	a6,128(sp)
ffffffffc0200e02:	e546                	sd	a7,136(sp)
ffffffffc0200e04:	e94a                	sd	s2,144(sp)
ffffffffc0200e06:	ed4e                	sd	s3,152(sp)
ffffffffc0200e08:	f152                	sd	s4,160(sp)
ffffffffc0200e0a:	f556                	sd	s5,168(sp)
ffffffffc0200e0c:	f95a                	sd	s6,176(sp)
ffffffffc0200e0e:	fd5e                	sd	s7,184(sp)
ffffffffc0200e10:	e1e2                	sd	s8,192(sp)
ffffffffc0200e12:	e5e6                	sd	s9,200(sp)
ffffffffc0200e14:	e9ea                	sd	s10,208(sp)
ffffffffc0200e16:	edee                	sd	s11,216(sp)
ffffffffc0200e18:	f1f2                	sd	t3,224(sp)
ffffffffc0200e1a:	f5f6                	sd	t4,232(sp)
ffffffffc0200e1c:	f9fa                	sd	t5,240(sp)
ffffffffc0200e1e:	fdfe                	sd	t6,248(sp)
ffffffffc0200e20:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200e24:	100024f3          	csrr	s1,sstatus
ffffffffc0200e28:	14102973          	csrr	s2,sepc
ffffffffc0200e2c:	143029f3          	csrr	s3,stval
ffffffffc0200e30:	14202a73          	csrr	s4,scause
ffffffffc0200e34:	e822                	sd	s0,16(sp)
ffffffffc0200e36:	e226                	sd	s1,256(sp)
ffffffffc0200e38:	e64a                	sd	s2,264(sp)
ffffffffc0200e3a:	ea4e                	sd	s3,272(sp)
ffffffffc0200e3c:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200e3e:	850a                	mv	a0,sp
    jal trap
ffffffffc0200e40:	f0fff0ef          	jal	ffffffffc0200d4e <trap>

ffffffffc0200e44 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200e44:	6492                	ld	s1,256(sp)
ffffffffc0200e46:	6932                	ld	s2,264(sp)
ffffffffc0200e48:	1004f413          	andi	s0,s1,256
ffffffffc0200e4c:	e401                	bnez	s0,ffffffffc0200e54 <__trapret+0x10>
ffffffffc0200e4e:	1200                	addi	s0,sp,288
ffffffffc0200e50:	14041073          	csrw	sscratch,s0
ffffffffc0200e54:	10049073          	csrw	sstatus,s1
ffffffffc0200e58:	14191073          	csrw	sepc,s2
ffffffffc0200e5c:	60a2                	ld	ra,8(sp)
ffffffffc0200e5e:	61e2                	ld	gp,24(sp)
ffffffffc0200e60:	7202                	ld	tp,32(sp)
ffffffffc0200e62:	72a2                	ld	t0,40(sp)
ffffffffc0200e64:	7342                	ld	t1,48(sp)
ffffffffc0200e66:	73e2                	ld	t2,56(sp)
ffffffffc0200e68:	6406                	ld	s0,64(sp)
ffffffffc0200e6a:	64a6                	ld	s1,72(sp)
ffffffffc0200e6c:	6546                	ld	a0,80(sp)
ffffffffc0200e6e:	65e6                	ld	a1,88(sp)
ffffffffc0200e70:	7606                	ld	a2,96(sp)
ffffffffc0200e72:	76a6                	ld	a3,104(sp)
ffffffffc0200e74:	7746                	ld	a4,112(sp)
ffffffffc0200e76:	77e6                	ld	a5,120(sp)
ffffffffc0200e78:	680a                	ld	a6,128(sp)
ffffffffc0200e7a:	68aa                	ld	a7,136(sp)
ffffffffc0200e7c:	694a                	ld	s2,144(sp)
ffffffffc0200e7e:	69ea                	ld	s3,152(sp)
ffffffffc0200e80:	7a0a                	ld	s4,160(sp)
ffffffffc0200e82:	7aaa                	ld	s5,168(sp)
ffffffffc0200e84:	7b4a                	ld	s6,176(sp)
ffffffffc0200e86:	7bea                	ld	s7,184(sp)
ffffffffc0200e88:	6c0e                	ld	s8,192(sp)
ffffffffc0200e8a:	6cae                	ld	s9,200(sp)
ffffffffc0200e8c:	6d4e                	ld	s10,208(sp)
ffffffffc0200e8e:	6dee                	ld	s11,216(sp)
ffffffffc0200e90:	7e0e                	ld	t3,224(sp)
ffffffffc0200e92:	7eae                	ld	t4,232(sp)
ffffffffc0200e94:	7f4e                	ld	t5,240(sp)
ffffffffc0200e96:	7fee                	ld	t6,248(sp)
ffffffffc0200e98:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200e9a:	10200073          	sret

ffffffffc0200e9e <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200e9e:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200ea0:	b755                	j	ffffffffc0200e44 <__trapret>

ffffffffc0200ea2 <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200ea2:	ee058593          	addi	a1,a1,-288

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200ea6:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200eaa:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200eae:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200eb2:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200eb6:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200eba:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200ebe:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200ec2:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200ec6:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200ec8:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200eca:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200ecc:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200ece:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ed0:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200ed2:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200ed4:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200ed6:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200ed8:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200eda:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200edc:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200ede:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200ee0:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200ee2:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200ee4:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200ee6:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200ee8:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200eea:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200eec:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200eee:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200ef0:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200ef2:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200ef4:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200ef6:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200ef8:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200efa:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200efc:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200efe:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200f00:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200f02:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200f04:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200f06:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200f08:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200f0a:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200f0c:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200f0e:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200f10:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200f12:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200f14:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200f16:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200f18:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200f1a:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200f1c:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200f1e:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200f20:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200f22:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200f24:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200f26:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200f28:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200f2a:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200f2c:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200f2e:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200f30:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200f32:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200f34:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200f36:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200f38:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200f3a:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200f3c:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200f3e:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200f40:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200f42:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200f44:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200f46:	812e                	mv	sp,a1
ffffffffc0200f48:	bdf5                	j	ffffffffc0200e44 <__trapret>

ffffffffc0200f4a <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200f4a:	00097797          	auipc	a5,0x97
ffffffffc0200f4e:	a3e78793          	addi	a5,a5,-1474 # ffffffffc0297988 <free_area>
ffffffffc0200f52:	e79c                	sd	a5,8(a5)
ffffffffc0200f54:	e39c                	sd	a5,0(a5)

static void
default_init(void)
{
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200f56:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200f5a:	8082                	ret

ffffffffc0200f5c <default_nr_free_pages>:

static size_t
default_nr_free_pages(void)
{
    return nr_free;
}
ffffffffc0200f5c:	00097517          	auipc	a0,0x97
ffffffffc0200f60:	a3c56503          	lwu	a0,-1476(a0) # ffffffffc0297998 <free_area+0x10>
ffffffffc0200f64:	8082                	ret

ffffffffc0200f66 <default_check>:

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1)
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void)
{
ffffffffc0200f66:	711d                	addi	sp,sp,-96
ffffffffc0200f68:	e0ca                	sd	s2,64(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200f6a:	00097917          	auipc	s2,0x97
ffffffffc0200f6e:	a1e90913          	addi	s2,s2,-1506 # ffffffffc0297988 <free_area>
ffffffffc0200f72:	00893783          	ld	a5,8(s2)
ffffffffc0200f76:	ec86                	sd	ra,88(sp)
ffffffffc0200f78:	e8a2                	sd	s0,80(sp)
ffffffffc0200f7a:	e4a6                	sd	s1,72(sp)
ffffffffc0200f7c:	fc4e                	sd	s3,56(sp)
ffffffffc0200f7e:	f852                	sd	s4,48(sp)
ffffffffc0200f80:	f456                	sd	s5,40(sp)
ffffffffc0200f82:	f05a                	sd	s6,32(sp)
ffffffffc0200f84:	ec5e                	sd	s7,24(sp)
ffffffffc0200f86:	e862                	sd	s8,16(sp)
ffffffffc0200f88:	e466                	sd	s9,8(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc0200f8a:	2f278363          	beq	a5,s2,ffffffffc0201270 <default_check+0x30a>
    int count = 0, total = 0;
ffffffffc0200f8e:	4401                	li	s0,0
ffffffffc0200f90:	4481                	li	s1,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200f92:	ff07b703          	ld	a4,-16(a5)
    {
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200f96:	8b09                	andi	a4,a4,2
ffffffffc0200f98:	2e070063          	beqz	a4,ffffffffc0201278 <default_check+0x312>
        count++, total += p->property;
ffffffffc0200f9c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200fa0:	679c                	ld	a5,8(a5)
ffffffffc0200fa2:	2485                	addiw	s1,s1,1
ffffffffc0200fa4:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc0200fa6:	ff2796e3          	bne	a5,s2,ffffffffc0200f92 <default_check+0x2c>
    }
    assert(total == nr_free_pages());
ffffffffc0200faa:	89a2                	mv	s3,s0
ffffffffc0200fac:	741000ef          	jal	ffffffffc0201eec <nr_free_pages>
ffffffffc0200fb0:	73351463          	bne	a0,s3,ffffffffc02016d8 <default_check+0x772>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fb4:	4505                	li	a0,1
ffffffffc0200fb6:	6c5000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0200fba:	8a2a                	mv	s4,a0
ffffffffc0200fbc:	44050e63          	beqz	a0,ffffffffc0201418 <default_check+0x4b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fc0:	4505                	li	a0,1
ffffffffc0200fc2:	6b9000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0200fc6:	89aa                	mv	s3,a0
ffffffffc0200fc8:	72050863          	beqz	a0,ffffffffc02016f8 <default_check+0x792>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fcc:	4505                	li	a0,1
ffffffffc0200fce:	6ad000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0200fd2:	8aaa                	mv	s5,a0
ffffffffc0200fd4:	4c050263          	beqz	a0,ffffffffc0201498 <default_check+0x532>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200fd8:	40a987b3          	sub	a5,s3,a0
ffffffffc0200fdc:	40aa0733          	sub	a4,s4,a0
ffffffffc0200fe0:	0017b793          	seqz	a5,a5
ffffffffc0200fe4:	00173713          	seqz	a4,a4
ffffffffc0200fe8:	8fd9                	or	a5,a5,a4
ffffffffc0200fea:	30079763          	bnez	a5,ffffffffc02012f8 <default_check+0x392>
ffffffffc0200fee:	313a0563          	beq	s4,s3,ffffffffc02012f8 <default_check+0x392>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200ff2:	000a2783          	lw	a5,0(s4)
ffffffffc0200ff6:	2a079163          	bnez	a5,ffffffffc0201298 <default_check+0x332>
ffffffffc0200ffa:	0009a783          	lw	a5,0(s3)
ffffffffc0200ffe:	28079d63          	bnez	a5,ffffffffc0201298 <default_check+0x332>
ffffffffc0201002:	411c                	lw	a5,0(a0)
ffffffffc0201004:	28079a63          	bnez	a5,ffffffffc0201298 <default_check+0x332>
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page)
{
    return page - pages + nbase;
ffffffffc0201008:	0009b797          	auipc	a5,0x9b
ffffffffc020100c:	a007b783          	ld	a5,-1536(a5) # ffffffffc029ba08 <pages>
ffffffffc0201010:	00007617          	auipc	a2,0x7
ffffffffc0201014:	95863603          	ld	a2,-1704(a2) # ffffffffc0207968 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201018:	0009b697          	auipc	a3,0x9b
ffffffffc020101c:	9e86b683          	ld	a3,-1560(a3) # ffffffffc029ba00 <npage>
ffffffffc0201020:	40fa0733          	sub	a4,s4,a5
ffffffffc0201024:	8719                	srai	a4,a4,0x6
ffffffffc0201026:	9732                	add	a4,a4,a2
}

static inline uintptr_t
page2pa(struct Page *page)
{
    return page2ppn(page) << PGSHIFT;
ffffffffc0201028:	0732                	slli	a4,a4,0xc
ffffffffc020102a:	06b2                	slli	a3,a3,0xc
ffffffffc020102c:	2ad77663          	bgeu	a4,a3,ffffffffc02012d8 <default_check+0x372>
    return page - pages + nbase;
ffffffffc0201030:	40f98733          	sub	a4,s3,a5
ffffffffc0201034:	8719                	srai	a4,a4,0x6
ffffffffc0201036:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201038:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020103a:	4cd77f63          	bgeu	a4,a3,ffffffffc0201518 <default_check+0x5b2>
    return page - pages + nbase;
ffffffffc020103e:	40f507b3          	sub	a5,a0,a5
ffffffffc0201042:	8799                	srai	a5,a5,0x6
ffffffffc0201044:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0201046:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201048:	32d7f863          	bgeu	a5,a3,ffffffffc0201378 <default_check+0x412>
    assert(alloc_page() == NULL);
ffffffffc020104c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104e:	00093c03          	ld	s8,0(s2)
ffffffffc0201052:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0201056:	00097b17          	auipc	s6,0x97
ffffffffc020105a:	942b2b03          	lw	s6,-1726(s6) # ffffffffc0297998 <free_area+0x10>
    elm->prev = elm->next = elm;
ffffffffc020105e:	01293023          	sd	s2,0(s2)
ffffffffc0201062:	01293423          	sd	s2,8(s2)
    nr_free = 0;
ffffffffc0201066:	00097797          	auipc	a5,0x97
ffffffffc020106a:	9207a923          	sw	zero,-1742(a5) # ffffffffc0297998 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc020106e:	60d000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201072:	2e051363          	bnez	a0,ffffffffc0201358 <default_check+0x3f2>
    free_page(p0);
ffffffffc0201076:	8552                	mv	a0,s4
ffffffffc0201078:	4585                	li	a1,1
ffffffffc020107a:	63b000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_page(p1);
ffffffffc020107e:	854e                	mv	a0,s3
ffffffffc0201080:	4585                	li	a1,1
ffffffffc0201082:	633000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_page(p2);
ffffffffc0201086:	8556                	mv	a0,s5
ffffffffc0201088:	4585                	li	a1,1
ffffffffc020108a:	62b000ef          	jal	ffffffffc0201eb4 <free_pages>
    assert(nr_free == 3);
ffffffffc020108e:	00097717          	auipc	a4,0x97
ffffffffc0201092:	90a72703          	lw	a4,-1782(a4) # ffffffffc0297998 <free_area+0x10>
ffffffffc0201096:	478d                	li	a5,3
ffffffffc0201098:	2af71063          	bne	a4,a5,ffffffffc0201338 <default_check+0x3d2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc020109c:	4505                	li	a0,1
ffffffffc020109e:	5dd000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010a2:	89aa                	mv	s3,a0
ffffffffc02010a4:	26050a63          	beqz	a0,ffffffffc0201318 <default_check+0x3b2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02010a8:	4505                	li	a0,1
ffffffffc02010aa:	5d1000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010ae:	8aaa                	mv	s5,a0
ffffffffc02010b0:	3c050463          	beqz	a0,ffffffffc0201478 <default_check+0x512>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02010b4:	4505                	li	a0,1
ffffffffc02010b6:	5c5000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010ba:	8a2a                	mv	s4,a0
ffffffffc02010bc:	38050e63          	beqz	a0,ffffffffc0201458 <default_check+0x4f2>
    assert(alloc_page() == NULL);
ffffffffc02010c0:	4505                	li	a0,1
ffffffffc02010c2:	5b9000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010c6:	36051963          	bnez	a0,ffffffffc0201438 <default_check+0x4d2>
    free_page(p0);
ffffffffc02010ca:	4585                	li	a1,1
ffffffffc02010cc:	854e                	mv	a0,s3
ffffffffc02010ce:	5e7000ef          	jal	ffffffffc0201eb4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02010d2:	00893783          	ld	a5,8(s2)
ffffffffc02010d6:	1f278163          	beq	a5,s2,ffffffffc02012b8 <default_check+0x352>
    assert((p = alloc_page()) == p0);
ffffffffc02010da:	4505                	li	a0,1
ffffffffc02010dc:	59f000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010e0:	8caa                	mv	s9,a0
ffffffffc02010e2:	30a99b63          	bne	s3,a0,ffffffffc02013f8 <default_check+0x492>
    assert(alloc_page() == NULL);
ffffffffc02010e6:	4505                	li	a0,1
ffffffffc02010e8:	593000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02010ec:	2e051663          	bnez	a0,ffffffffc02013d8 <default_check+0x472>
    assert(nr_free == 0);
ffffffffc02010f0:	00097797          	auipc	a5,0x97
ffffffffc02010f4:	8a87a783          	lw	a5,-1880(a5) # ffffffffc0297998 <free_area+0x10>
ffffffffc02010f8:	2c079063          	bnez	a5,ffffffffc02013b8 <default_check+0x452>
    free_page(p);
ffffffffc02010fc:	8566                	mv	a0,s9
ffffffffc02010fe:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0201100:	01893023          	sd	s8,0(s2)
ffffffffc0201104:	01793423          	sd	s7,8(s2)
    nr_free = nr_free_store;
ffffffffc0201108:	01692823          	sw	s6,16(s2)
    free_page(p);
ffffffffc020110c:	5a9000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_page(p1);
ffffffffc0201110:	8556                	mv	a0,s5
ffffffffc0201112:	4585                	li	a1,1
ffffffffc0201114:	5a1000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_page(p2);
ffffffffc0201118:	8552                	mv	a0,s4
ffffffffc020111a:	4585                	li	a1,1
ffffffffc020111c:	599000ef          	jal	ffffffffc0201eb4 <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201120:	4515                	li	a0,5
ffffffffc0201122:	559000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201126:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0201128:	26050863          	beqz	a0,ffffffffc0201398 <default_check+0x432>
ffffffffc020112c:	651c                	ld	a5,8(a0)
    assert(!PageProperty(p0));
ffffffffc020112e:	8b89                	andi	a5,a5,2
ffffffffc0201130:	54079463          	bnez	a5,ffffffffc0201678 <default_check+0x712>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0201134:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0201136:	00093b83          	ld	s7,0(s2)
ffffffffc020113a:	00893b03          	ld	s6,8(s2)
ffffffffc020113e:	01293023          	sd	s2,0(s2)
ffffffffc0201142:	01293423          	sd	s2,8(s2)
    assert(alloc_page() == NULL);
ffffffffc0201146:	535000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc020114a:	50051763          	bnez	a0,ffffffffc0201658 <default_check+0x6f2>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020114e:	08098a13          	addi	s4,s3,128
ffffffffc0201152:	8552                	mv	a0,s4
ffffffffc0201154:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201156:	00097c17          	auipc	s8,0x97
ffffffffc020115a:	842c2c03          	lw	s8,-1982(s8) # ffffffffc0297998 <free_area+0x10>
    nr_free = 0;
ffffffffc020115e:	00097797          	auipc	a5,0x97
ffffffffc0201162:	8207ad23          	sw	zero,-1990(a5) # ffffffffc0297998 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201166:	54f000ef          	jal	ffffffffc0201eb4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020116a:	4511                	li	a0,4
ffffffffc020116c:	50f000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201170:	4c051463          	bnez	a0,ffffffffc0201638 <default_check+0x6d2>
ffffffffc0201174:	0889b783          	ld	a5,136(s3)
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201178:	8b89                	andi	a5,a5,2
ffffffffc020117a:	48078f63          	beqz	a5,ffffffffc0201618 <default_check+0x6b2>
ffffffffc020117e:	0909a503          	lw	a0,144(s3)
ffffffffc0201182:	478d                	li	a5,3
ffffffffc0201184:	48f51a63          	bne	a0,a5,ffffffffc0201618 <default_check+0x6b2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201188:	4f3000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc020118c:	8aaa                	mv	s5,a0
ffffffffc020118e:	46050563          	beqz	a0,ffffffffc02015f8 <default_check+0x692>
    assert(alloc_page() == NULL);
ffffffffc0201192:	4505                	li	a0,1
ffffffffc0201194:	4e7000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201198:	44051063          	bnez	a0,ffffffffc02015d8 <default_check+0x672>
    assert(p0 + 2 == p1);
ffffffffc020119c:	415a1e63          	bne	s4,s5,ffffffffc02015b8 <default_check+0x652>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02011a0:	4585                	li	a1,1
ffffffffc02011a2:	854e                	mv	a0,s3
ffffffffc02011a4:	511000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_pages(p1, 3);
ffffffffc02011a8:	8552                	mv	a0,s4
ffffffffc02011aa:	458d                	li	a1,3
ffffffffc02011ac:	509000ef          	jal	ffffffffc0201eb4 <free_pages>
ffffffffc02011b0:	0089b783          	ld	a5,8(s3)
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02011b4:	8b89                	andi	a5,a5,2
ffffffffc02011b6:	3e078163          	beqz	a5,ffffffffc0201598 <default_check+0x632>
ffffffffc02011ba:	0109aa83          	lw	s5,16(s3)
ffffffffc02011be:	4785                	li	a5,1
ffffffffc02011c0:	3cfa9c63          	bne	s5,a5,ffffffffc0201598 <default_check+0x632>
ffffffffc02011c4:	008a3783          	ld	a5,8(s4)
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02011c8:	8b89                	andi	a5,a5,2
ffffffffc02011ca:	3a078763          	beqz	a5,ffffffffc0201578 <default_check+0x612>
ffffffffc02011ce:	010a2703          	lw	a4,16(s4)
ffffffffc02011d2:	478d                	li	a5,3
ffffffffc02011d4:	3af71263          	bne	a4,a5,ffffffffc0201578 <default_check+0x612>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc02011d8:	8556                	mv	a0,s5
ffffffffc02011da:	4a1000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02011de:	36a99d63          	bne	s3,a0,ffffffffc0201558 <default_check+0x5f2>
    free_page(p0);
ffffffffc02011e2:	85d6                	mv	a1,s5
ffffffffc02011e4:	4d1000ef          	jal	ffffffffc0201eb4 <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc02011e8:	4509                	li	a0,2
ffffffffc02011ea:	491000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc02011ee:	34aa1563          	bne	s4,a0,ffffffffc0201538 <default_check+0x5d2>

    free_pages(p0, 2);
ffffffffc02011f2:	4589                	li	a1,2
ffffffffc02011f4:	4c1000ef          	jal	ffffffffc0201eb4 <free_pages>
    free_page(p2);
ffffffffc02011f8:	04098513          	addi	a0,s3,64
ffffffffc02011fc:	85d6                	mv	a1,s5
ffffffffc02011fe:	4b7000ef          	jal	ffffffffc0201eb4 <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201202:	4515                	li	a0,5
ffffffffc0201204:	477000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201208:	89aa                	mv	s3,a0
ffffffffc020120a:	48050763          	beqz	a0,ffffffffc0201698 <default_check+0x732>
    assert(alloc_page() == NULL);
ffffffffc020120e:	8556                	mv	a0,s5
ffffffffc0201210:	46b000ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0201214:	2e051263          	bnez	a0,ffffffffc02014f8 <default_check+0x592>

    assert(nr_free == 0);
ffffffffc0201218:	00096797          	auipc	a5,0x96
ffffffffc020121c:	7807a783          	lw	a5,1920(a5) # ffffffffc0297998 <free_area+0x10>
ffffffffc0201220:	2a079c63          	bnez	a5,ffffffffc02014d8 <default_check+0x572>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201224:	854e                	mv	a0,s3
ffffffffc0201226:	4595                	li	a1,5
    nr_free = nr_free_store;
ffffffffc0201228:	01892823          	sw	s8,16(s2)
    free_list = free_list_store;
ffffffffc020122c:	01793023          	sd	s7,0(s2)
ffffffffc0201230:	01693423          	sd	s6,8(s2)
    free_pages(p0, 5);
ffffffffc0201234:	481000ef          	jal	ffffffffc0201eb4 <free_pages>
    return listelm->next;
ffffffffc0201238:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list)
ffffffffc020123c:	01278963          	beq	a5,s2,ffffffffc020124e <default_check+0x2e8>
    {
        struct Page *p = le2page(le, page_link);
        count--, total -= p->property;
ffffffffc0201240:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201244:	679c                	ld	a5,8(a5)
ffffffffc0201246:	34fd                	addiw	s1,s1,-1
ffffffffc0201248:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list)
ffffffffc020124a:	ff279be3          	bne	a5,s2,ffffffffc0201240 <default_check+0x2da>
    }
    assert(count == 0);
ffffffffc020124e:	26049563          	bnez	s1,ffffffffc02014b8 <default_check+0x552>
    assert(total == 0);
ffffffffc0201252:	46041363          	bnez	s0,ffffffffc02016b8 <default_check+0x752>
}
ffffffffc0201256:	60e6                	ld	ra,88(sp)
ffffffffc0201258:	6446                	ld	s0,80(sp)
ffffffffc020125a:	64a6                	ld	s1,72(sp)
ffffffffc020125c:	6906                	ld	s2,64(sp)
ffffffffc020125e:	79e2                	ld	s3,56(sp)
ffffffffc0201260:	7a42                	ld	s4,48(sp)
ffffffffc0201262:	7aa2                	ld	s5,40(sp)
ffffffffc0201264:	7b02                	ld	s6,32(sp)
ffffffffc0201266:	6be2                	ld	s7,24(sp)
ffffffffc0201268:	6c42                	ld	s8,16(sp)
ffffffffc020126a:	6ca2                	ld	s9,8(sp)
ffffffffc020126c:	6125                	addi	sp,sp,96
ffffffffc020126e:	8082                	ret
    while ((le = list_next(le)) != &free_list)
ffffffffc0201270:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0201272:	4401                	li	s0,0
ffffffffc0201274:	4481                	li	s1,0
ffffffffc0201276:	bb1d                	j	ffffffffc0200fac <default_check+0x46>
        assert(PageProperty(p));
ffffffffc0201278:	00005697          	auipc	a3,0x5
ffffffffc020127c:	f5068693          	addi	a3,a3,-176 # ffffffffc02061c8 <etext+0x9c0>
ffffffffc0201280:	00005617          	auipc	a2,0x5
ffffffffc0201284:	f5860613          	addi	a2,a2,-168 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201288:	11000593          	li	a1,272
ffffffffc020128c:	00005517          	auipc	a0,0x5
ffffffffc0201290:	f6450513          	addi	a0,a0,-156 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201294:	9b2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0201298:	00005697          	auipc	a3,0x5
ffffffffc020129c:	01868693          	addi	a3,a3,24 # ffffffffc02062b0 <etext+0xaa8>
ffffffffc02012a0:	00005617          	auipc	a2,0x5
ffffffffc02012a4:	f3860613          	addi	a2,a2,-200 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02012a8:	0dc00593          	li	a1,220
ffffffffc02012ac:	00005517          	auipc	a0,0x5
ffffffffc02012b0:	f4450513          	addi	a0,a0,-188 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02012b4:	992ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02012b8:	00005697          	auipc	a3,0x5
ffffffffc02012bc:	0c068693          	addi	a3,a3,192 # ffffffffc0206378 <etext+0xb70>
ffffffffc02012c0:	00005617          	auipc	a2,0x5
ffffffffc02012c4:	f1860613          	addi	a2,a2,-232 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02012c8:	0f700593          	li	a1,247
ffffffffc02012cc:	00005517          	auipc	a0,0x5
ffffffffc02012d0:	f2450513          	addi	a0,a0,-220 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02012d4:	972ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02012d8:	00005697          	auipc	a3,0x5
ffffffffc02012dc:	01868693          	addi	a3,a3,24 # ffffffffc02062f0 <etext+0xae8>
ffffffffc02012e0:	00005617          	auipc	a2,0x5
ffffffffc02012e4:	ef860613          	addi	a2,a2,-264 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02012e8:	0de00593          	li	a1,222
ffffffffc02012ec:	00005517          	auipc	a0,0x5
ffffffffc02012f0:	f0450513          	addi	a0,a0,-252 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02012f4:	952ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02012f8:	00005697          	auipc	a3,0x5
ffffffffc02012fc:	f9068693          	addi	a3,a3,-112 # ffffffffc0206288 <etext+0xa80>
ffffffffc0201300:	00005617          	auipc	a2,0x5
ffffffffc0201304:	ed860613          	addi	a2,a2,-296 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201308:	0db00593          	li	a1,219
ffffffffc020130c:	00005517          	auipc	a0,0x5
ffffffffc0201310:	ee450513          	addi	a0,a0,-284 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201314:	932ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201318:	00005697          	auipc	a3,0x5
ffffffffc020131c:	f1068693          	addi	a3,a3,-240 # ffffffffc0206228 <etext+0xa20>
ffffffffc0201320:	00005617          	auipc	a2,0x5
ffffffffc0201324:	eb860613          	addi	a2,a2,-328 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201328:	0f000593          	li	a1,240
ffffffffc020132c:	00005517          	auipc	a0,0x5
ffffffffc0201330:	ec450513          	addi	a0,a0,-316 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201334:	912ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 3);
ffffffffc0201338:	00005697          	auipc	a3,0x5
ffffffffc020133c:	03068693          	addi	a3,a3,48 # ffffffffc0206368 <etext+0xb60>
ffffffffc0201340:	00005617          	auipc	a2,0x5
ffffffffc0201344:	e9860613          	addi	a2,a2,-360 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201348:	0ee00593          	li	a1,238
ffffffffc020134c:	00005517          	auipc	a0,0x5
ffffffffc0201350:	ea450513          	addi	a0,a0,-348 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201354:	8f2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201358:	00005697          	auipc	a3,0x5
ffffffffc020135c:	ff868693          	addi	a3,a3,-8 # ffffffffc0206350 <etext+0xb48>
ffffffffc0201360:	00005617          	auipc	a2,0x5
ffffffffc0201364:	e7860613          	addi	a2,a2,-392 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201368:	0e900593          	li	a1,233
ffffffffc020136c:	00005517          	auipc	a0,0x5
ffffffffc0201370:	e8450513          	addi	a0,a0,-380 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201374:	8d2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0201378:	00005697          	auipc	a3,0x5
ffffffffc020137c:	fb868693          	addi	a3,a3,-72 # ffffffffc0206330 <etext+0xb28>
ffffffffc0201380:	00005617          	auipc	a2,0x5
ffffffffc0201384:	e5860613          	addi	a2,a2,-424 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201388:	0e000593          	li	a1,224
ffffffffc020138c:	00005517          	auipc	a0,0x5
ffffffffc0201390:	e6450513          	addi	a0,a0,-412 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201394:	8b2ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 != NULL);
ffffffffc0201398:	00005697          	auipc	a3,0x5
ffffffffc020139c:	02868693          	addi	a3,a3,40 # ffffffffc02063c0 <etext+0xbb8>
ffffffffc02013a0:	00005617          	auipc	a2,0x5
ffffffffc02013a4:	e3860613          	addi	a2,a2,-456 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02013a8:	11800593          	li	a1,280
ffffffffc02013ac:	00005517          	auipc	a0,0x5
ffffffffc02013b0:	e4450513          	addi	a0,a0,-444 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02013b4:	892ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02013b8:	00005697          	auipc	a3,0x5
ffffffffc02013bc:	ff868693          	addi	a3,a3,-8 # ffffffffc02063b0 <etext+0xba8>
ffffffffc02013c0:	00005617          	auipc	a2,0x5
ffffffffc02013c4:	e1860613          	addi	a2,a2,-488 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02013c8:	0fd00593          	li	a1,253
ffffffffc02013cc:	00005517          	auipc	a0,0x5
ffffffffc02013d0:	e2450513          	addi	a0,a0,-476 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02013d4:	872ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02013d8:	00005697          	auipc	a3,0x5
ffffffffc02013dc:	f7868693          	addi	a3,a3,-136 # ffffffffc0206350 <etext+0xb48>
ffffffffc02013e0:	00005617          	auipc	a2,0x5
ffffffffc02013e4:	df860613          	addi	a2,a2,-520 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02013e8:	0fb00593          	li	a1,251
ffffffffc02013ec:	00005517          	auipc	a0,0x5
ffffffffc02013f0:	e0450513          	addi	a0,a0,-508 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02013f4:	852ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc02013f8:	00005697          	auipc	a3,0x5
ffffffffc02013fc:	f9868693          	addi	a3,a3,-104 # ffffffffc0206390 <etext+0xb88>
ffffffffc0201400:	00005617          	auipc	a2,0x5
ffffffffc0201404:	dd860613          	addi	a2,a2,-552 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201408:	0fa00593          	li	a1,250
ffffffffc020140c:	00005517          	auipc	a0,0x5
ffffffffc0201410:	de450513          	addi	a0,a0,-540 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201414:	832ff0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201418:	00005697          	auipc	a3,0x5
ffffffffc020141c:	e1068693          	addi	a3,a3,-496 # ffffffffc0206228 <etext+0xa20>
ffffffffc0201420:	00005617          	auipc	a2,0x5
ffffffffc0201424:	db860613          	addi	a2,a2,-584 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201428:	0d700593          	li	a1,215
ffffffffc020142c:	00005517          	auipc	a0,0x5
ffffffffc0201430:	dc450513          	addi	a0,a0,-572 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201434:	812ff0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201438:	00005697          	auipc	a3,0x5
ffffffffc020143c:	f1868693          	addi	a3,a3,-232 # ffffffffc0206350 <etext+0xb48>
ffffffffc0201440:	00005617          	auipc	a2,0x5
ffffffffc0201444:	d9860613          	addi	a2,a2,-616 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201448:	0f400593          	li	a1,244
ffffffffc020144c:	00005517          	auipc	a0,0x5
ffffffffc0201450:	da450513          	addi	a0,a0,-604 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201454:	ff3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201458:	00005697          	auipc	a3,0x5
ffffffffc020145c:	e1068693          	addi	a3,a3,-496 # ffffffffc0206268 <etext+0xa60>
ffffffffc0201460:	00005617          	auipc	a2,0x5
ffffffffc0201464:	d7860613          	addi	a2,a2,-648 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201468:	0f200593          	li	a1,242
ffffffffc020146c:	00005517          	auipc	a0,0x5
ffffffffc0201470:	d8450513          	addi	a0,a0,-636 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201474:	fd3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201478:	00005697          	auipc	a3,0x5
ffffffffc020147c:	dd068693          	addi	a3,a3,-560 # ffffffffc0206248 <etext+0xa40>
ffffffffc0201480:	00005617          	auipc	a2,0x5
ffffffffc0201484:	d5860613          	addi	a2,a2,-680 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201488:	0f100593          	li	a1,241
ffffffffc020148c:	00005517          	auipc	a0,0x5
ffffffffc0201490:	d6450513          	addi	a0,a0,-668 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201494:	fb3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201498:	00005697          	auipc	a3,0x5
ffffffffc020149c:	dd068693          	addi	a3,a3,-560 # ffffffffc0206268 <etext+0xa60>
ffffffffc02014a0:	00005617          	auipc	a2,0x5
ffffffffc02014a4:	d3860613          	addi	a2,a2,-712 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02014a8:	0d900593          	li	a1,217
ffffffffc02014ac:	00005517          	auipc	a0,0x5
ffffffffc02014b0:	d4450513          	addi	a0,a0,-700 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02014b4:	f93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(count == 0);
ffffffffc02014b8:	00005697          	auipc	a3,0x5
ffffffffc02014bc:	05868693          	addi	a3,a3,88 # ffffffffc0206510 <etext+0xd08>
ffffffffc02014c0:	00005617          	auipc	a2,0x5
ffffffffc02014c4:	d1860613          	addi	a2,a2,-744 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02014c8:	14600593          	li	a1,326
ffffffffc02014cc:	00005517          	auipc	a0,0x5
ffffffffc02014d0:	d2450513          	addi	a0,a0,-732 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02014d4:	f73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free == 0);
ffffffffc02014d8:	00005697          	auipc	a3,0x5
ffffffffc02014dc:	ed868693          	addi	a3,a3,-296 # ffffffffc02063b0 <etext+0xba8>
ffffffffc02014e0:	00005617          	auipc	a2,0x5
ffffffffc02014e4:	cf860613          	addi	a2,a2,-776 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02014e8:	13a00593          	li	a1,314
ffffffffc02014ec:	00005517          	auipc	a0,0x5
ffffffffc02014f0:	d0450513          	addi	a0,a0,-764 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02014f4:	f53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02014f8:	00005697          	auipc	a3,0x5
ffffffffc02014fc:	e5868693          	addi	a3,a3,-424 # ffffffffc0206350 <etext+0xb48>
ffffffffc0201500:	00005617          	auipc	a2,0x5
ffffffffc0201504:	cd860613          	addi	a2,a2,-808 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201508:	13800593          	li	a1,312
ffffffffc020150c:	00005517          	auipc	a0,0x5
ffffffffc0201510:	ce450513          	addi	a0,a0,-796 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201514:	f33fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201518:	00005697          	auipc	a3,0x5
ffffffffc020151c:	df868693          	addi	a3,a3,-520 # ffffffffc0206310 <etext+0xb08>
ffffffffc0201520:	00005617          	auipc	a2,0x5
ffffffffc0201524:	cb860613          	addi	a2,a2,-840 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201528:	0df00593          	li	a1,223
ffffffffc020152c:	00005517          	auipc	a0,0x5
ffffffffc0201530:	cc450513          	addi	a0,a0,-828 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201534:	f13fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201538:	00005697          	auipc	a3,0x5
ffffffffc020153c:	f9868693          	addi	a3,a3,-104 # ffffffffc02064d0 <etext+0xcc8>
ffffffffc0201540:	00005617          	auipc	a2,0x5
ffffffffc0201544:	c9860613          	addi	a2,a2,-872 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201548:	13200593          	li	a1,306
ffffffffc020154c:	00005517          	auipc	a0,0x5
ffffffffc0201550:	ca450513          	addi	a0,a0,-860 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201554:	ef3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201558:	00005697          	auipc	a3,0x5
ffffffffc020155c:	f5868693          	addi	a3,a3,-168 # ffffffffc02064b0 <etext+0xca8>
ffffffffc0201560:	00005617          	auipc	a2,0x5
ffffffffc0201564:	c7860613          	addi	a2,a2,-904 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201568:	13000593          	li	a1,304
ffffffffc020156c:	00005517          	auipc	a0,0x5
ffffffffc0201570:	c8450513          	addi	a0,a0,-892 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201574:	ed3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc0201578:	00005697          	auipc	a3,0x5
ffffffffc020157c:	f1068693          	addi	a3,a3,-240 # ffffffffc0206488 <etext+0xc80>
ffffffffc0201580:	00005617          	auipc	a2,0x5
ffffffffc0201584:	c5860613          	addi	a2,a2,-936 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201588:	12e00593          	li	a1,302
ffffffffc020158c:	00005517          	auipc	a0,0x5
ffffffffc0201590:	c6450513          	addi	a0,a0,-924 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201594:	eb3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc0201598:	00005697          	auipc	a3,0x5
ffffffffc020159c:	ec868693          	addi	a3,a3,-312 # ffffffffc0206460 <etext+0xc58>
ffffffffc02015a0:	00005617          	auipc	a2,0x5
ffffffffc02015a4:	c3860613          	addi	a2,a2,-968 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02015a8:	12d00593          	li	a1,301
ffffffffc02015ac:	00005517          	auipc	a0,0x5
ffffffffc02015b0:	c4450513          	addi	a0,a0,-956 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02015b4:	e93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02015b8:	00005697          	auipc	a3,0x5
ffffffffc02015bc:	e9868693          	addi	a3,a3,-360 # ffffffffc0206450 <etext+0xc48>
ffffffffc02015c0:	00005617          	auipc	a2,0x5
ffffffffc02015c4:	c1860613          	addi	a2,a2,-1000 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02015c8:	12800593          	li	a1,296
ffffffffc02015cc:	00005517          	auipc	a0,0x5
ffffffffc02015d0:	c2450513          	addi	a0,a0,-988 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02015d4:	e73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02015d8:	00005697          	auipc	a3,0x5
ffffffffc02015dc:	d7868693          	addi	a3,a3,-648 # ffffffffc0206350 <etext+0xb48>
ffffffffc02015e0:	00005617          	auipc	a2,0x5
ffffffffc02015e4:	bf860613          	addi	a2,a2,-1032 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02015e8:	12700593          	li	a1,295
ffffffffc02015ec:	00005517          	auipc	a0,0x5
ffffffffc02015f0:	c0450513          	addi	a0,a0,-1020 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02015f4:	e53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02015f8:	00005697          	auipc	a3,0x5
ffffffffc02015fc:	e3868693          	addi	a3,a3,-456 # ffffffffc0206430 <etext+0xc28>
ffffffffc0201600:	00005617          	auipc	a2,0x5
ffffffffc0201604:	bd860613          	addi	a2,a2,-1064 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201608:	12600593          	li	a1,294
ffffffffc020160c:	00005517          	auipc	a0,0x5
ffffffffc0201610:	be450513          	addi	a0,a0,-1052 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201614:	e33fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201618:	00005697          	auipc	a3,0x5
ffffffffc020161c:	de868693          	addi	a3,a3,-536 # ffffffffc0206400 <etext+0xbf8>
ffffffffc0201620:	00005617          	auipc	a2,0x5
ffffffffc0201624:	bb860613          	addi	a2,a2,-1096 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201628:	12500593          	li	a1,293
ffffffffc020162c:	00005517          	auipc	a0,0x5
ffffffffc0201630:	bc450513          	addi	a0,a0,-1084 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201634:	e13fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201638:	00005697          	auipc	a3,0x5
ffffffffc020163c:	db068693          	addi	a3,a3,-592 # ffffffffc02063e8 <etext+0xbe0>
ffffffffc0201640:	00005617          	auipc	a2,0x5
ffffffffc0201644:	b9860613          	addi	a2,a2,-1128 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201648:	12400593          	li	a1,292
ffffffffc020164c:	00005517          	auipc	a0,0x5
ffffffffc0201650:	ba450513          	addi	a0,a0,-1116 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201654:	df3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201658:	00005697          	auipc	a3,0x5
ffffffffc020165c:	cf868693          	addi	a3,a3,-776 # ffffffffc0206350 <etext+0xb48>
ffffffffc0201660:	00005617          	auipc	a2,0x5
ffffffffc0201664:	b7860613          	addi	a2,a2,-1160 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201668:	11e00593          	li	a1,286
ffffffffc020166c:	00005517          	auipc	a0,0x5
ffffffffc0201670:	b8450513          	addi	a0,a0,-1148 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201674:	dd3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(!PageProperty(p0));
ffffffffc0201678:	00005697          	auipc	a3,0x5
ffffffffc020167c:	d5868693          	addi	a3,a3,-680 # ffffffffc02063d0 <etext+0xbc8>
ffffffffc0201680:	00005617          	auipc	a2,0x5
ffffffffc0201684:	b5860613          	addi	a2,a2,-1192 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201688:	11900593          	li	a1,281
ffffffffc020168c:	00005517          	auipc	a0,0x5
ffffffffc0201690:	b6450513          	addi	a0,a0,-1180 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201694:	db3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201698:	00005697          	auipc	a3,0x5
ffffffffc020169c:	e5868693          	addi	a3,a3,-424 # ffffffffc02064f0 <etext+0xce8>
ffffffffc02016a0:	00005617          	auipc	a2,0x5
ffffffffc02016a4:	b3860613          	addi	a2,a2,-1224 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02016a8:	13700593          	li	a1,311
ffffffffc02016ac:	00005517          	auipc	a0,0x5
ffffffffc02016b0:	b4450513          	addi	a0,a0,-1212 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02016b4:	d93fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == 0);
ffffffffc02016b8:	00005697          	auipc	a3,0x5
ffffffffc02016bc:	e6868693          	addi	a3,a3,-408 # ffffffffc0206520 <etext+0xd18>
ffffffffc02016c0:	00005617          	auipc	a2,0x5
ffffffffc02016c4:	b1860613          	addi	a2,a2,-1256 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02016c8:	14700593          	li	a1,327
ffffffffc02016cc:	00005517          	auipc	a0,0x5
ffffffffc02016d0:	b2450513          	addi	a0,a0,-1244 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02016d4:	d73fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(total == nr_free_pages());
ffffffffc02016d8:	00005697          	auipc	a3,0x5
ffffffffc02016dc:	b3068693          	addi	a3,a3,-1232 # ffffffffc0206208 <etext+0xa00>
ffffffffc02016e0:	00005617          	auipc	a2,0x5
ffffffffc02016e4:	af860613          	addi	a2,a2,-1288 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02016e8:	11300593          	li	a1,275
ffffffffc02016ec:	00005517          	auipc	a0,0x5
ffffffffc02016f0:	b0450513          	addi	a0,a0,-1276 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc02016f4:	d53fe0ef          	jal	ffffffffc0200446 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02016f8:	00005697          	auipc	a3,0x5
ffffffffc02016fc:	b5068693          	addi	a3,a3,-1200 # ffffffffc0206248 <etext+0xa40>
ffffffffc0201700:	00005617          	auipc	a2,0x5
ffffffffc0201704:	ad860613          	addi	a2,a2,-1320 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201708:	0d800593          	li	a1,216
ffffffffc020170c:	00005517          	auipc	a0,0x5
ffffffffc0201710:	ae450513          	addi	a0,a0,-1308 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201714:	d33fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201718 <default_free_pages>:
{
ffffffffc0201718:	1141                	addi	sp,sp,-16
ffffffffc020171a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020171c:	14058663          	beqz	a1,ffffffffc0201868 <default_free_pages+0x150>
    for (; p != base + n; p++)
ffffffffc0201720:	00659713          	slli	a4,a1,0x6
ffffffffc0201724:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc0201728:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc020172a:	c30d                	beqz	a4,ffffffffc020174c <default_free_pages+0x34>
ffffffffc020172c:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020172e:	8b05                	andi	a4,a4,1
ffffffffc0201730:	10071c63          	bnez	a4,ffffffffc0201848 <default_free_pages+0x130>
ffffffffc0201734:	6798                	ld	a4,8(a5)
ffffffffc0201736:	8b09                	andi	a4,a4,2
ffffffffc0201738:	10071863          	bnez	a4,ffffffffc0201848 <default_free_pages+0x130>
        p->flags = 0;
ffffffffc020173c:	0007b423          	sd	zero,8(a5)
}

static inline void
set_page_ref(struct Page *page, int val)
{
    page->ref = val;
ffffffffc0201740:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201744:	04078793          	addi	a5,a5,64
ffffffffc0201748:	fed792e3          	bne	a5,a3,ffffffffc020172c <default_free_pages+0x14>
    base->property = n;
ffffffffc020174c:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc020174e:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201752:	4789                	li	a5,2
ffffffffc0201754:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201758:	00096717          	auipc	a4,0x96
ffffffffc020175c:	24072703          	lw	a4,576(a4) # ffffffffc0297998 <free_area+0x10>
ffffffffc0201760:	00096697          	auipc	a3,0x96
ffffffffc0201764:	22868693          	addi	a3,a3,552 # ffffffffc0297988 <free_area>
    return list->next == list;
ffffffffc0201768:	669c                	ld	a5,8(a3)
ffffffffc020176a:	9f2d                	addw	a4,a4,a1
ffffffffc020176c:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc020176e:	0ad78163          	beq	a5,a3,ffffffffc0201810 <default_free_pages+0xf8>
            struct Page *page = le2page(le, page_link);
ffffffffc0201772:	fe878713          	addi	a4,a5,-24
ffffffffc0201776:	4581                	li	a1,0
ffffffffc0201778:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc020177c:	00e56a63          	bltu	a0,a4,ffffffffc0201790 <default_free_pages+0x78>
    return listelm->next;
ffffffffc0201780:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc0201782:	04d70c63          	beq	a4,a3,ffffffffc02017da <default_free_pages+0xc2>
    struct Page *p = base;
ffffffffc0201786:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0201788:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc020178c:	fee57ae3          	bgeu	a0,a4,ffffffffc0201780 <default_free_pages+0x68>
ffffffffc0201790:	c199                	beqz	a1,ffffffffc0201796 <default_free_pages+0x7e>
ffffffffc0201792:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201796:	6398                	ld	a4,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc0201798:	e390                	sd	a2,0(a5)
ffffffffc020179a:	e710                	sd	a2,8(a4)
    elm->next = next;
    elm->prev = prev;
ffffffffc020179c:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc020179e:	f11c                	sd	a5,32(a0)
    if (le != &free_list)
ffffffffc02017a0:	00d70d63          	beq	a4,a3,ffffffffc02017ba <default_free_pages+0xa2>
        if (p + p->property == base)
ffffffffc02017a4:	ff872583          	lw	a1,-8(a4)
        p = le2page(le, page_link);
ffffffffc02017a8:	fe870613          	addi	a2,a4,-24
        if (p + p->property == base)
ffffffffc02017ac:	02059813          	slli	a6,a1,0x20
ffffffffc02017b0:	01a85793          	srli	a5,a6,0x1a
ffffffffc02017b4:	97b2                	add	a5,a5,a2
ffffffffc02017b6:	02f50c63          	beq	a0,a5,ffffffffc02017ee <default_free_pages+0xd6>
    return listelm->next;
ffffffffc02017ba:	711c                	ld	a5,32(a0)
    if (le != &free_list)
ffffffffc02017bc:	00d78c63          	beq	a5,a3,ffffffffc02017d4 <default_free_pages+0xbc>
        if (base + base->property == p)
ffffffffc02017c0:	4910                	lw	a2,16(a0)
        p = le2page(le, page_link);
ffffffffc02017c2:	fe878693          	addi	a3,a5,-24
        if (base + base->property == p)
ffffffffc02017c6:	02061593          	slli	a1,a2,0x20
ffffffffc02017ca:	01a5d713          	srli	a4,a1,0x1a
ffffffffc02017ce:	972a                	add	a4,a4,a0
ffffffffc02017d0:	04e68c63          	beq	a3,a4,ffffffffc0201828 <default_free_pages+0x110>
}
ffffffffc02017d4:	60a2                	ld	ra,8(sp)
ffffffffc02017d6:	0141                	addi	sp,sp,16
ffffffffc02017d8:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02017da:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02017dc:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02017de:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02017e0:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02017e2:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02017e4:	02d70f63          	beq	a4,a3,ffffffffc0201822 <default_free_pages+0x10a>
ffffffffc02017e8:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02017ea:	87ba                	mv	a5,a4
ffffffffc02017ec:	bf71                	j	ffffffffc0201788 <default_free_pages+0x70>
            p->property += base->property;
ffffffffc02017ee:	491c                	lw	a5,16(a0)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02017f0:	5875                	li	a6,-3
ffffffffc02017f2:	9fad                	addw	a5,a5,a1
ffffffffc02017f4:	fef72c23          	sw	a5,-8(a4)
ffffffffc02017f8:	6108b02f          	amoand.d	zero,a6,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc02017fc:	01853803          	ld	a6,24(a0)
ffffffffc0201800:	710c                	ld	a1,32(a0)
            base = p;
ffffffffc0201802:	8532                	mv	a0,a2
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201804:	00b83423          	sd	a1,8(a6) # ff0008 <_binary_obj___user_exit_out_size+0xfe5e10>
    return listelm->next;
ffffffffc0201808:	671c                	ld	a5,8(a4)
    next->prev = prev;
ffffffffc020180a:	0105b023          	sd	a6,0(a1)
ffffffffc020180e:	b77d                	j	ffffffffc02017bc <default_free_pages+0xa4>
}
ffffffffc0201810:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201812:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc0201816:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201818:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc020181a:	e398                	sd	a4,0(a5)
ffffffffc020181c:	e798                	sd	a4,8(a5)
}
ffffffffc020181e:	0141                	addi	sp,sp,16
ffffffffc0201820:	8082                	ret
ffffffffc0201822:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc0201824:	873e                	mv	a4,a5
ffffffffc0201826:	bfad                	j	ffffffffc02017a0 <default_free_pages+0x88>
            base->property += p->property;
ffffffffc0201828:	ff87a703          	lw	a4,-8(a5)
ffffffffc020182c:	56f5                	li	a3,-3
ffffffffc020182e:	9f31                	addw	a4,a4,a2
ffffffffc0201830:	c918                	sw	a4,16(a0)
ffffffffc0201832:	ff078713          	addi	a4,a5,-16
ffffffffc0201836:	60d7302f          	amoand.d	zero,a3,(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020183a:	6398                	ld	a4,0(a5)
ffffffffc020183c:	679c                	ld	a5,8(a5)
}
ffffffffc020183e:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0201840:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0201842:	e398                	sd	a4,0(a5)
ffffffffc0201844:	0141                	addi	sp,sp,16
ffffffffc0201846:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201848:	00005697          	auipc	a3,0x5
ffffffffc020184c:	cf068693          	addi	a3,a3,-784 # ffffffffc0206538 <etext+0xd30>
ffffffffc0201850:	00005617          	auipc	a2,0x5
ffffffffc0201854:	98860613          	addi	a2,a2,-1656 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201858:	09400593          	li	a1,148
ffffffffc020185c:	00005517          	auipc	a0,0x5
ffffffffc0201860:	99450513          	addi	a0,a0,-1644 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201864:	be3fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201868:	00005697          	auipc	a3,0x5
ffffffffc020186c:	cc868693          	addi	a3,a3,-824 # ffffffffc0206530 <etext+0xd28>
ffffffffc0201870:	00005617          	auipc	a2,0x5
ffffffffc0201874:	96860613          	addi	a2,a2,-1688 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201878:	09000593          	li	a1,144
ffffffffc020187c:	00005517          	auipc	a0,0x5
ffffffffc0201880:	97450513          	addi	a0,a0,-1676 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201884:	bc3fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201888 <default_alloc_pages>:
    assert(n > 0);
ffffffffc0201888:	c951                	beqz	a0,ffffffffc020191c <default_alloc_pages+0x94>
    if (n > nr_free)
ffffffffc020188a:	00096597          	auipc	a1,0x96
ffffffffc020188e:	10e5a583          	lw	a1,270(a1) # ffffffffc0297998 <free_area+0x10>
ffffffffc0201892:	86aa                	mv	a3,a0
ffffffffc0201894:	02059793          	slli	a5,a1,0x20
ffffffffc0201898:	9381                	srli	a5,a5,0x20
ffffffffc020189a:	00a7ef63          	bltu	a5,a0,ffffffffc02018b8 <default_alloc_pages+0x30>
    list_entry_t *le = &free_list;
ffffffffc020189e:	00096617          	auipc	a2,0x96
ffffffffc02018a2:	0ea60613          	addi	a2,a2,234 # ffffffffc0297988 <free_area>
ffffffffc02018a6:	87b2                	mv	a5,a2
ffffffffc02018a8:	a029                	j	ffffffffc02018b2 <default_alloc_pages+0x2a>
        if (p->property >= n)
ffffffffc02018aa:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02018ae:	00d77763          	bgeu	a4,a3,ffffffffc02018bc <default_alloc_pages+0x34>
    return listelm->next;
ffffffffc02018b2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list)
ffffffffc02018b4:	fec79be3          	bne	a5,a2,ffffffffc02018aa <default_alloc_pages+0x22>
        return NULL;
ffffffffc02018b8:	4501                	li	a0,0
}
ffffffffc02018ba:	8082                	ret
        if (page->property > n)
ffffffffc02018bc:	ff87a883          	lw	a7,-8(a5)
    return listelm->prev;
ffffffffc02018c0:	0007b803          	ld	a6,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc02018c4:	6798                	ld	a4,8(a5)
ffffffffc02018c6:	02089313          	slli	t1,a7,0x20
ffffffffc02018ca:	02035313          	srli	t1,t1,0x20
    prev->next = next;
ffffffffc02018ce:	00e83423          	sd	a4,8(a6)
    next->prev = prev;
ffffffffc02018d2:	01073023          	sd	a6,0(a4)
        struct Page *p = le2page(le, page_link);
ffffffffc02018d6:	fe878513          	addi	a0,a5,-24
        if (page->property > n)
ffffffffc02018da:	0266fa63          	bgeu	a3,t1,ffffffffc020190e <default_alloc_pages+0x86>
            struct Page *p = page + n;
ffffffffc02018de:	00669713          	slli	a4,a3,0x6
            p->property = page->property - n;
ffffffffc02018e2:	40d888bb          	subw	a7,a7,a3
            struct Page *p = page + n;
ffffffffc02018e6:	972a                	add	a4,a4,a0
            p->property = page->property - n;
ffffffffc02018e8:	01172823          	sw	a7,16(a4)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018ec:	00870313          	addi	t1,a4,8
ffffffffc02018f0:	4889                	li	a7,2
ffffffffc02018f2:	4113302f          	amoor.d	zero,a7,(t1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02018f6:	00883883          	ld	a7,8(a6)
            list_add(prev, &(p->page_link));
ffffffffc02018fa:	01870313          	addi	t1,a4,24
    prev->next = next->prev = elm;
ffffffffc02018fe:	0068b023          	sd	t1,0(a7)
ffffffffc0201902:	00683423          	sd	t1,8(a6)
    elm->next = next;
ffffffffc0201906:	03173023          	sd	a7,32(a4)
    elm->prev = prev;
ffffffffc020190a:	01073c23          	sd	a6,24(a4)
        nr_free -= n;
ffffffffc020190e:	9d95                	subw	a1,a1,a3
ffffffffc0201910:	ca0c                	sw	a1,16(a2)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201912:	5775                	li	a4,-3
ffffffffc0201914:	17c1                	addi	a5,a5,-16
ffffffffc0201916:	60e7b02f          	amoand.d	zero,a4,(a5)
}
ffffffffc020191a:	8082                	ret
{
ffffffffc020191c:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020191e:	00005697          	auipc	a3,0x5
ffffffffc0201922:	c1268693          	addi	a3,a3,-1006 # ffffffffc0206530 <etext+0xd28>
ffffffffc0201926:	00005617          	auipc	a2,0x5
ffffffffc020192a:	8b260613          	addi	a2,a2,-1870 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020192e:	06c00593          	li	a1,108
ffffffffc0201932:	00005517          	auipc	a0,0x5
ffffffffc0201936:	8be50513          	addi	a0,a0,-1858 # ffffffffc02061f0 <etext+0x9e8>
{
ffffffffc020193a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020193c:	b0bfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201940 <default_init_memmap>:
{
ffffffffc0201940:	1141                	addi	sp,sp,-16
ffffffffc0201942:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201944:	c9e1                	beqz	a1,ffffffffc0201a14 <default_init_memmap+0xd4>
    for (; p != base + n; p++)
ffffffffc0201946:	00659713          	slli	a4,a1,0x6
ffffffffc020194a:	00e506b3          	add	a3,a0,a4
    struct Page *p = base;
ffffffffc020194e:	87aa                	mv	a5,a0
    for (; p != base + n; p++)
ffffffffc0201950:	cf11                	beqz	a4,ffffffffc020196c <default_init_memmap+0x2c>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201952:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc0201954:	8b05                	andi	a4,a4,1
ffffffffc0201956:	cf59                	beqz	a4,ffffffffc02019f4 <default_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc0201958:	0007a823          	sw	zero,16(a5)
ffffffffc020195c:	0007b423          	sd	zero,8(a5)
ffffffffc0201960:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p++)
ffffffffc0201964:	04078793          	addi	a5,a5,64
ffffffffc0201968:	fed795e3          	bne	a5,a3,ffffffffc0201952 <default_init_memmap+0x12>
    base->property = n;
ffffffffc020196c:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020196e:	4789                	li	a5,2
ffffffffc0201970:	00850713          	addi	a4,a0,8
ffffffffc0201974:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc0201978:	00096717          	auipc	a4,0x96
ffffffffc020197c:	02072703          	lw	a4,32(a4) # ffffffffc0297998 <free_area+0x10>
ffffffffc0201980:	00096697          	auipc	a3,0x96
ffffffffc0201984:	00868693          	addi	a3,a3,8 # ffffffffc0297988 <free_area>
    return list->next == list;
ffffffffc0201988:	669c                	ld	a5,8(a3)
ffffffffc020198a:	9f2d                	addw	a4,a4,a1
ffffffffc020198c:	ca98                	sw	a4,16(a3)
    if (list_empty(&free_list))
ffffffffc020198e:	04d78663          	beq	a5,a3,ffffffffc02019da <default_init_memmap+0x9a>
            struct Page *page = le2page(le, page_link);
ffffffffc0201992:	fe878713          	addi	a4,a5,-24
ffffffffc0201996:	4581                	li	a1,0
ffffffffc0201998:	01850613          	addi	a2,a0,24
            if (base < page)
ffffffffc020199c:	00e56a63          	bltu	a0,a4,ffffffffc02019b0 <default_init_memmap+0x70>
    return listelm->next;
ffffffffc02019a0:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list)
ffffffffc02019a2:	02d70263          	beq	a4,a3,ffffffffc02019c6 <default_init_memmap+0x86>
    struct Page *p = base;
ffffffffc02019a6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc02019a8:	fe878713          	addi	a4,a5,-24
            if (base < page)
ffffffffc02019ac:	fee57ae3          	bgeu	a0,a4,ffffffffc02019a0 <default_init_memmap+0x60>
ffffffffc02019b0:	c199                	beqz	a1,ffffffffc02019b6 <default_init_memmap+0x76>
ffffffffc02019b2:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02019b6:	6398                	ld	a4,0(a5)
}
ffffffffc02019b8:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc02019ba:	e390                	sd	a2,0(a5)
ffffffffc02019bc:	e710                	sd	a2,8(a4)
    elm->prev = prev;
ffffffffc02019be:	ed18                	sd	a4,24(a0)
    elm->next = next;
ffffffffc02019c0:	f11c                	sd	a5,32(a0)
ffffffffc02019c2:	0141                	addi	sp,sp,16
ffffffffc02019c4:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02019c6:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02019c8:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02019ca:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02019cc:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc02019ce:	8832                	mv	a6,a2
        while ((le = list_next(le)) != &free_list)
ffffffffc02019d0:	00d70e63          	beq	a4,a3,ffffffffc02019ec <default_init_memmap+0xac>
ffffffffc02019d4:	4585                	li	a1,1
    struct Page *p = base;
ffffffffc02019d6:	87ba                	mv	a5,a4
ffffffffc02019d8:	bfc1                	j	ffffffffc02019a8 <default_init_memmap+0x68>
}
ffffffffc02019da:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc02019dc:	01850713          	addi	a4,a0,24
    elm->next = next;
ffffffffc02019e0:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02019e2:	ed1c                	sd	a5,24(a0)
    prev->next = next->prev = elm;
ffffffffc02019e4:	e398                	sd	a4,0(a5)
ffffffffc02019e6:	e798                	sd	a4,8(a5)
}
ffffffffc02019e8:	0141                	addi	sp,sp,16
ffffffffc02019ea:	8082                	ret
ffffffffc02019ec:	60a2                	ld	ra,8(sp)
ffffffffc02019ee:	e290                	sd	a2,0(a3)
ffffffffc02019f0:	0141                	addi	sp,sp,16
ffffffffc02019f2:	8082                	ret
        assert(PageReserved(p));
ffffffffc02019f4:	00005697          	auipc	a3,0x5
ffffffffc02019f8:	b6c68693          	addi	a3,a3,-1172 # ffffffffc0206560 <etext+0xd58>
ffffffffc02019fc:	00004617          	auipc	a2,0x4
ffffffffc0201a00:	7dc60613          	addi	a2,a2,2012 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201a04:	04b00593          	li	a1,75
ffffffffc0201a08:	00004517          	auipc	a0,0x4
ffffffffc0201a0c:	7e850513          	addi	a0,a0,2024 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201a10:	a37fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(n > 0);
ffffffffc0201a14:	00005697          	auipc	a3,0x5
ffffffffc0201a18:	b1c68693          	addi	a3,a3,-1252 # ffffffffc0206530 <etext+0xd28>
ffffffffc0201a1c:	00004617          	auipc	a2,0x4
ffffffffc0201a20:	7bc60613          	addi	a2,a2,1980 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201a24:	04700593          	li	a1,71
ffffffffc0201a28:	00004517          	auipc	a0,0x4
ffffffffc0201a2c:	7c850513          	addi	a0,a0,1992 # ffffffffc02061f0 <etext+0x9e8>
ffffffffc0201a30:	a17fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201a34 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc0201a34:	c531                	beqz	a0,ffffffffc0201a80 <slob_free+0x4c>
		return;

	if (size)
ffffffffc0201a36:	e9b9                	bnez	a1,ffffffffc0201a8c <slob_free+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a38:	100027f3          	csrr	a5,sstatus
ffffffffc0201a3c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a3e:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a40:	efb1                	bnez	a5,ffffffffc0201a9c <slob_free+0x68>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a42:	00096797          	auipc	a5,0x96
ffffffffc0201a46:	b367b783          	ld	a5,-1226(a5) # ffffffffc0297578 <slobfree>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a4a:	873e                	mv	a4,a5
ffffffffc0201a4c:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a4e:	02a77a63          	bgeu	a4,a0,ffffffffc0201a82 <slob_free+0x4e>
ffffffffc0201a52:	00f56463          	bltu	a0,a5,ffffffffc0201a5a <slob_free+0x26>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a56:	fef76ae3          	bltu	a4,a5,ffffffffc0201a4a <slob_free+0x16>
			break;

	if (b + b->units == cur->next)
ffffffffc0201a5a:	4110                	lw	a2,0(a0)
ffffffffc0201a5c:	00461693          	slli	a3,a2,0x4
ffffffffc0201a60:	96aa                	add	a3,a3,a0
ffffffffc0201a62:	0ad78463          	beq	a5,a3,ffffffffc0201b0a <slob_free+0xd6>
		b->next = cur->next->next;
	}
	else
		b->next = cur->next;

	if (cur + cur->units == b)
ffffffffc0201a66:	4310                	lw	a2,0(a4)
ffffffffc0201a68:	e51c                	sd	a5,8(a0)
ffffffffc0201a6a:	00461693          	slli	a3,a2,0x4
ffffffffc0201a6e:	96ba                	add	a3,a3,a4
ffffffffc0201a70:	08d50163          	beq	a0,a3,ffffffffc0201af2 <slob_free+0xbe>
ffffffffc0201a74:	e708                	sd	a0,8(a4)
		cur->next = b->next;
	}
	else
		cur->next = b;

	slobfree = cur;
ffffffffc0201a76:	00096797          	auipc	a5,0x96
ffffffffc0201a7a:	b0e7b123          	sd	a4,-1278(a5) # ffffffffc0297578 <slobfree>
    if (flag)
ffffffffc0201a7e:	e9a5                	bnez	a1,ffffffffc0201aee <slob_free+0xba>
ffffffffc0201a80:	8082                	ret
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a82:	fcf574e3          	bgeu	a0,a5,ffffffffc0201a4a <slob_free+0x16>
ffffffffc0201a86:	fcf762e3          	bltu	a4,a5,ffffffffc0201a4a <slob_free+0x16>
ffffffffc0201a8a:	bfc1                	j	ffffffffc0201a5a <slob_free+0x26>
		b->units = SLOB_UNITS(size);
ffffffffc0201a8c:	25bd                	addiw	a1,a1,15
ffffffffc0201a8e:	8191                	srli	a1,a1,0x4
ffffffffc0201a90:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a92:	100027f3          	csrr	a5,sstatus
ffffffffc0201a96:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a98:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201a9a:	d7c5                	beqz	a5,ffffffffc0201a42 <slob_free+0xe>
{
ffffffffc0201a9c:	1101                	addi	sp,sp,-32
ffffffffc0201a9e:	e42a                	sd	a0,8(sp)
ffffffffc0201aa0:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201aa2:	e63fe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201aa6:	6522                	ld	a0,8(sp)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201aa8:	00096797          	auipc	a5,0x96
ffffffffc0201aac:	ad07b783          	ld	a5,-1328(a5) # ffffffffc0297578 <slobfree>
ffffffffc0201ab0:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201ab2:	873e                	mv	a4,a5
ffffffffc0201ab4:	679c                	ld	a5,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201ab6:	06a77663          	bgeu	a4,a0,ffffffffc0201b22 <slob_free+0xee>
ffffffffc0201aba:	00f56463          	bltu	a0,a5,ffffffffc0201ac2 <slob_free+0x8e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201abe:	fef76ae3          	bltu	a4,a5,ffffffffc0201ab2 <slob_free+0x7e>
	if (b + b->units == cur->next)
ffffffffc0201ac2:	4110                	lw	a2,0(a0)
ffffffffc0201ac4:	00461693          	slli	a3,a2,0x4
ffffffffc0201ac8:	96aa                	add	a3,a3,a0
ffffffffc0201aca:	06d78363          	beq	a5,a3,ffffffffc0201b30 <slob_free+0xfc>
	if (cur + cur->units == b)
ffffffffc0201ace:	4310                	lw	a2,0(a4)
ffffffffc0201ad0:	e51c                	sd	a5,8(a0)
ffffffffc0201ad2:	00461693          	slli	a3,a2,0x4
ffffffffc0201ad6:	96ba                	add	a3,a3,a4
ffffffffc0201ad8:	06d50163          	beq	a0,a3,ffffffffc0201b3a <slob_free+0x106>
ffffffffc0201adc:	e708                	sd	a0,8(a4)
	slobfree = cur;
ffffffffc0201ade:	00096797          	auipc	a5,0x96
ffffffffc0201ae2:	a8e7bd23          	sd	a4,-1382(a5) # ffffffffc0297578 <slobfree>
    if (flag)
ffffffffc0201ae6:	e1a9                	bnez	a1,ffffffffc0201b28 <slob_free+0xf4>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201ae8:	60e2                	ld	ra,24(sp)
ffffffffc0201aea:	6105                	addi	sp,sp,32
ffffffffc0201aec:	8082                	ret
        intr_enable();
ffffffffc0201aee:	e11fe06f          	j	ffffffffc02008fe <intr_enable>
		cur->units += b->units;
ffffffffc0201af2:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201af4:	853e                	mv	a0,a5
ffffffffc0201af6:	e708                	sd	a0,8(a4)
		cur->units += b->units;
ffffffffc0201af8:	00c687bb          	addw	a5,a3,a2
ffffffffc0201afc:	c31c                	sw	a5,0(a4)
	slobfree = cur;
ffffffffc0201afe:	00096797          	auipc	a5,0x96
ffffffffc0201b02:	a6e7bd23          	sd	a4,-1414(a5) # ffffffffc0297578 <slobfree>
    if (flag)
ffffffffc0201b06:	ddad                	beqz	a1,ffffffffc0201a80 <slob_free+0x4c>
ffffffffc0201b08:	b7dd                	j	ffffffffc0201aee <slob_free+0xba>
		b->units += cur->next->units;
ffffffffc0201b0a:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b0c:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b0e:	9eb1                	addw	a3,a3,a2
ffffffffc0201b10:	c114                	sw	a3,0(a0)
	if (cur + cur->units == b)
ffffffffc0201b12:	4310                	lw	a2,0(a4)
ffffffffc0201b14:	e51c                	sd	a5,8(a0)
ffffffffc0201b16:	00461693          	slli	a3,a2,0x4
ffffffffc0201b1a:	96ba                	add	a3,a3,a4
ffffffffc0201b1c:	f4d51ce3          	bne	a0,a3,ffffffffc0201a74 <slob_free+0x40>
ffffffffc0201b20:	bfc9                	j	ffffffffc0201af2 <slob_free+0xbe>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201b22:	f8f56ee3          	bltu	a0,a5,ffffffffc0201abe <slob_free+0x8a>
ffffffffc0201b26:	b771                	j	ffffffffc0201ab2 <slob_free+0x7e>
}
ffffffffc0201b28:	60e2                	ld	ra,24(sp)
ffffffffc0201b2a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201b2c:	dd3fe06f          	j	ffffffffc02008fe <intr_enable>
		b->units += cur->next->units;
ffffffffc0201b30:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201b32:	679c                	ld	a5,8(a5)
		b->units += cur->next->units;
ffffffffc0201b34:	9eb1                	addw	a3,a3,a2
ffffffffc0201b36:	c114                	sw	a3,0(a0)
		b->next = cur->next->next;
ffffffffc0201b38:	bf59                	j	ffffffffc0201ace <slob_free+0x9a>
		cur->units += b->units;
ffffffffc0201b3a:	4114                	lw	a3,0(a0)
		cur->next = b->next;
ffffffffc0201b3c:	853e                	mv	a0,a5
		cur->units += b->units;
ffffffffc0201b3e:	00c687bb          	addw	a5,a3,a2
ffffffffc0201b42:	c31c                	sw	a5,0(a4)
		cur->next = b->next;
ffffffffc0201b44:	bf61                	j	ffffffffc0201adc <slob_free+0xa8>

ffffffffc0201b46 <__slob_get_free_pages.constprop.0>:
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b46:	4785                	li	a5,1
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b48:	1141                	addi	sp,sp,-16
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b4a:	00a7953b          	sllw	a0,a5,a0
static void *__slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201b4e:	e406                	sd	ra,8(sp)
	struct Page *page = alloc_pages(1 << order);
ffffffffc0201b50:	32a000ef          	jal	ffffffffc0201e7a <alloc_pages>
	if (!page)
ffffffffc0201b54:	c91d                	beqz	a0,ffffffffc0201b8a <__slob_get_free_pages.constprop.0+0x44>
    return page - pages + nbase;
ffffffffc0201b56:	0009a697          	auipc	a3,0x9a
ffffffffc0201b5a:	eb26b683          	ld	a3,-334(a3) # ffffffffc029ba08 <pages>
ffffffffc0201b5e:	00006797          	auipc	a5,0x6
ffffffffc0201b62:	e0a7b783          	ld	a5,-502(a5) # ffffffffc0207968 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201b66:	0009a717          	auipc	a4,0x9a
ffffffffc0201b6a:	e9a73703          	ld	a4,-358(a4) # ffffffffc029ba00 <npage>
    return page - pages + nbase;
ffffffffc0201b6e:	8d15                	sub	a0,a0,a3
ffffffffc0201b70:	8519                	srai	a0,a0,0x6
ffffffffc0201b72:	953e                	add	a0,a0,a5
    return KADDR(page2pa(page));
ffffffffc0201b74:	00c51793          	slli	a5,a0,0xc
ffffffffc0201b78:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0201b7a:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc0201b7c:	00e7fa63          	bgeu	a5,a4,ffffffffc0201b90 <__slob_get_free_pages.constprop.0+0x4a>
ffffffffc0201b80:	0009a797          	auipc	a5,0x9a
ffffffffc0201b84:	e787b783          	ld	a5,-392(a5) # ffffffffc029b9f8 <va_pa_offset>
ffffffffc0201b88:	953e                	add	a0,a0,a5
}
ffffffffc0201b8a:	60a2                	ld	ra,8(sp)
ffffffffc0201b8c:	0141                	addi	sp,sp,16
ffffffffc0201b8e:	8082                	ret
ffffffffc0201b90:	86aa                	mv	a3,a0
ffffffffc0201b92:	00005617          	auipc	a2,0x5
ffffffffc0201b96:	9f660613          	addi	a2,a2,-1546 # ffffffffc0206588 <etext+0xd80>
ffffffffc0201b9a:	07100593          	li	a1,113
ffffffffc0201b9e:	00005517          	auipc	a0,0x5
ffffffffc0201ba2:	a1250513          	addi	a0,a0,-1518 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0201ba6:	8a1fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201baa <slob_alloc.constprop.0>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201baa:	7179                	addi	sp,sp,-48
ffffffffc0201bac:	f406                	sd	ra,40(sp)
ffffffffc0201bae:	f022                	sd	s0,32(sp)
ffffffffc0201bb0:	ec26                	sd	s1,24(sp)
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201bb2:	01050713          	addi	a4,a0,16
ffffffffc0201bb6:	6785                	lui	a5,0x1
ffffffffc0201bb8:	0af77e63          	bgeu	a4,a5,ffffffffc0201c74 <slob_alloc.constprop.0+0xca>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201bbc:	00f50413          	addi	s0,a0,15
ffffffffc0201bc0:	8011                	srli	s0,s0,0x4
ffffffffc0201bc2:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201bc4:	100025f3          	csrr	a1,sstatus
ffffffffc0201bc8:	8989                	andi	a1,a1,2
ffffffffc0201bca:	edd1                	bnez	a1,ffffffffc0201c66 <slob_alloc.constprop.0+0xbc>
	prev = slobfree;
ffffffffc0201bcc:	00096497          	auipc	s1,0x96
ffffffffc0201bd0:	9ac48493          	addi	s1,s1,-1620 # ffffffffc0297578 <slobfree>
ffffffffc0201bd4:	6090                	ld	a2,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201bd6:	6618                	ld	a4,8(a2)
		if (cur->units >= units + delta)
ffffffffc0201bd8:	4314                	lw	a3,0(a4)
ffffffffc0201bda:	0886da63          	bge	a3,s0,ffffffffc0201c6e <slob_alloc.constprop.0+0xc4>
		if (cur == slobfree)
ffffffffc0201bde:	00e60a63          	beq	a2,a4,ffffffffc0201bf2 <slob_alloc.constprop.0+0x48>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201be2:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201be4:	4394                	lw	a3,0(a5)
ffffffffc0201be6:	0286d863          	bge	a3,s0,ffffffffc0201c16 <slob_alloc.constprop.0+0x6c>
		if (cur == slobfree)
ffffffffc0201bea:	6090                	ld	a2,0(s1)
ffffffffc0201bec:	873e                	mv	a4,a5
ffffffffc0201bee:	fee61ae3          	bne	a2,a4,ffffffffc0201be2 <slob_alloc.constprop.0+0x38>
    if (flag)
ffffffffc0201bf2:	e9b1                	bnez	a1,ffffffffc0201c46 <slob_alloc.constprop.0+0x9c>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bf4:	4501                	li	a0,0
ffffffffc0201bf6:	f51ff0ef          	jal	ffffffffc0201b46 <__slob_get_free_pages.constprop.0>
ffffffffc0201bfa:	87aa                	mv	a5,a0
			if (!cur)
ffffffffc0201bfc:	c915                	beqz	a0,ffffffffc0201c30 <slob_alloc.constprop.0+0x86>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201bfe:	6585                	lui	a1,0x1
ffffffffc0201c00:	e35ff0ef          	jal	ffffffffc0201a34 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201c04:	100025f3          	csrr	a1,sstatus
ffffffffc0201c08:	8989                	andi	a1,a1,2
ffffffffc0201c0a:	e98d                	bnez	a1,ffffffffc0201c3c <slob_alloc.constprop.0+0x92>
			cur = slobfree;
ffffffffc0201c0c:	6098                	ld	a4,0(s1)
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c0e:	671c                	ld	a5,8(a4)
		if (cur->units >= units + delta)
ffffffffc0201c10:	4394                	lw	a3,0(a5)
ffffffffc0201c12:	fc86cce3          	blt	a3,s0,ffffffffc0201bea <slob_alloc.constprop.0+0x40>
			if (cur->units == units)	/* exact fit? */
ffffffffc0201c16:	04d40563          	beq	s0,a3,ffffffffc0201c60 <slob_alloc.constprop.0+0xb6>
				prev->next = cur + units;
ffffffffc0201c1a:	00441613          	slli	a2,s0,0x4
ffffffffc0201c1e:	963e                	add	a2,a2,a5
ffffffffc0201c20:	e710                	sd	a2,8(a4)
				prev->next->next = cur->next;
ffffffffc0201c22:	6788                	ld	a0,8(a5)
				prev->next->units = cur->units - units;
ffffffffc0201c24:	9e81                	subw	a3,a3,s0
ffffffffc0201c26:	c214                	sw	a3,0(a2)
				prev->next->next = cur->next;
ffffffffc0201c28:	e608                	sd	a0,8(a2)
				cur->units = units;
ffffffffc0201c2a:	c380                	sw	s0,0(a5)
			slobfree = prev;
ffffffffc0201c2c:	e098                	sd	a4,0(s1)
    if (flag)
ffffffffc0201c2e:	ed99                	bnez	a1,ffffffffc0201c4c <slob_alloc.constprop.0+0xa2>
}
ffffffffc0201c30:	70a2                	ld	ra,40(sp)
ffffffffc0201c32:	7402                	ld	s0,32(sp)
ffffffffc0201c34:	64e2                	ld	s1,24(sp)
ffffffffc0201c36:	853e                	mv	a0,a5
ffffffffc0201c38:	6145                	addi	sp,sp,48
ffffffffc0201c3a:	8082                	ret
        intr_disable();
ffffffffc0201c3c:	cc9fe0ef          	jal	ffffffffc0200904 <intr_disable>
			cur = slobfree;
ffffffffc0201c40:	6098                	ld	a4,0(s1)
        return 1;
ffffffffc0201c42:	4585                	li	a1,1
ffffffffc0201c44:	b7e9                	j	ffffffffc0201c0e <slob_alloc.constprop.0+0x64>
        intr_enable();
ffffffffc0201c46:	cb9fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c4a:	b76d                	j	ffffffffc0201bf4 <slob_alloc.constprop.0+0x4a>
ffffffffc0201c4c:	e43e                	sd	a5,8(sp)
ffffffffc0201c4e:	cb1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201c52:	67a2                	ld	a5,8(sp)
}
ffffffffc0201c54:	70a2                	ld	ra,40(sp)
ffffffffc0201c56:	7402                	ld	s0,32(sp)
ffffffffc0201c58:	64e2                	ld	s1,24(sp)
ffffffffc0201c5a:	853e                	mv	a0,a5
ffffffffc0201c5c:	6145                	addi	sp,sp,48
ffffffffc0201c5e:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201c60:	6794                	ld	a3,8(a5)
ffffffffc0201c62:	e714                	sd	a3,8(a4)
ffffffffc0201c64:	b7e1                	j	ffffffffc0201c2c <slob_alloc.constprop.0+0x82>
        intr_disable();
ffffffffc0201c66:	c9ffe0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0201c6a:	4585                	li	a1,1
ffffffffc0201c6c:	b785                	j	ffffffffc0201bcc <slob_alloc.constprop.0+0x22>
	for (cur = prev->next;; prev = cur, cur = cur->next)
ffffffffc0201c6e:	87ba                	mv	a5,a4
	prev = slobfree;
ffffffffc0201c70:	8732                	mv	a4,a2
ffffffffc0201c72:	b755                	j	ffffffffc0201c16 <slob_alloc.constprop.0+0x6c>
	assert((size + SLOB_UNIT) < PAGE_SIZE);
ffffffffc0201c74:	00005697          	auipc	a3,0x5
ffffffffc0201c78:	94c68693          	addi	a3,a3,-1716 # ffffffffc02065c0 <etext+0xdb8>
ffffffffc0201c7c:	00004617          	auipc	a2,0x4
ffffffffc0201c80:	55c60613          	addi	a2,a2,1372 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0201c84:	06300593          	li	a1,99
ffffffffc0201c88:	00005517          	auipc	a0,0x5
ffffffffc0201c8c:	95850513          	addi	a0,a0,-1704 # ffffffffc02065e0 <etext+0xdd8>
ffffffffc0201c90:	fb6fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201c94 <kmalloc_init>:
	cprintf("use SLOB allocator\n");
}

inline void
kmalloc_init(void)
{
ffffffffc0201c94:	1141                	addi	sp,sp,-16
	cprintf("use SLOB allocator\n");
ffffffffc0201c96:	00005517          	auipc	a0,0x5
ffffffffc0201c9a:	96250513          	addi	a0,a0,-1694 # ffffffffc02065f8 <etext+0xdf0>
{
ffffffffc0201c9e:	e406                	sd	ra,8(sp)
	cprintf("use SLOB allocator\n");
ffffffffc0201ca0:	cf4fe0ef          	jal	ffffffffc0200194 <cprintf>
	slob_init();
	cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201ca4:	60a2                	ld	ra,8(sp)
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201ca6:	00005517          	auipc	a0,0x5
ffffffffc0201caa:	96a50513          	addi	a0,a0,-1686 # ffffffffc0206610 <etext+0xe08>
}
ffffffffc0201cae:	0141                	addi	sp,sp,16
	cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201cb0:	ce4fe06f          	j	ffffffffc0200194 <cprintf>

ffffffffc0201cb4 <kallocated>:

size_t
kallocated(void)
{
	return slob_allocated();
}
ffffffffc0201cb4:	4501                	li	a0,0
ffffffffc0201cb6:	8082                	ret

ffffffffc0201cb8 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201cb8:	1101                	addi	sp,sp,-32
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cba:	6685                	lui	a3,0x1
{
ffffffffc0201cbc:	ec06                	sd	ra,24(sp)
	if (size < PAGE_SIZE - SLOB_UNIT)
ffffffffc0201cbe:	16bd                	addi	a3,a3,-17 # fef <_binary_obj___user_softint_out_size-0x7c19>
ffffffffc0201cc0:	04a6f963          	bgeu	a3,a0,ffffffffc0201d12 <kmalloc+0x5a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201cc4:	e42a                	sd	a0,8(sp)
ffffffffc0201cc6:	4561                	li	a0,24
ffffffffc0201cc8:	e822                	sd	s0,16(sp)
ffffffffc0201cca:	ee1ff0ef          	jal	ffffffffc0201baa <slob_alloc.constprop.0>
ffffffffc0201cce:	842a                	mv	s0,a0
	if (!bb)
ffffffffc0201cd0:	c541                	beqz	a0,ffffffffc0201d58 <kmalloc+0xa0>
	bb->order = find_order(size);
ffffffffc0201cd2:	47a2                	lw	a5,8(sp)
	for (; size > 4096; size >>= 1)
ffffffffc0201cd4:	6705                	lui	a4,0x1
	int order = 0;
ffffffffc0201cd6:	4501                	li	a0,0
	for (; size > 4096; size >>= 1)
ffffffffc0201cd8:	00f75763          	bge	a4,a5,ffffffffc0201ce6 <kmalloc+0x2e>
ffffffffc0201cdc:	4017d79b          	sraiw	a5,a5,0x1
		order++;
ffffffffc0201ce0:	2505                	addiw	a0,a0,1
	for (; size > 4096; size >>= 1)
ffffffffc0201ce2:	fef74de3          	blt	a4,a5,ffffffffc0201cdc <kmalloc+0x24>
	bb->order = find_order(size);
ffffffffc0201ce6:	c008                	sw	a0,0(s0)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201ce8:	e5fff0ef          	jal	ffffffffc0201b46 <__slob_get_free_pages.constprop.0>
ffffffffc0201cec:	e408                	sd	a0,8(s0)
	if (bb->pages)
ffffffffc0201cee:	cd31                	beqz	a0,ffffffffc0201d4a <kmalloc+0x92>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201cf0:	100027f3          	csrr	a5,sstatus
ffffffffc0201cf4:	8b89                	andi	a5,a5,2
ffffffffc0201cf6:	eb85                	bnez	a5,ffffffffc0201d26 <kmalloc+0x6e>
		bb->next = bigblocks;
ffffffffc0201cf8:	0009a797          	auipc	a5,0x9a
ffffffffc0201cfc:	ce07b783          	ld	a5,-800(a5) # ffffffffc029b9d8 <bigblocks>
		bigblocks = bb;
ffffffffc0201d00:	0009a717          	auipc	a4,0x9a
ffffffffc0201d04:	cc873c23          	sd	s0,-808(a4) # ffffffffc029b9d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d08:	e81c                	sd	a5,16(s0)
    if (flag)
ffffffffc0201d0a:	6442                	ld	s0,16(sp)
	return __kmalloc(size, 0);
}
ffffffffc0201d0c:	60e2                	ld	ra,24(sp)
ffffffffc0201d0e:	6105                	addi	sp,sp,32
ffffffffc0201d10:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201d12:	0541                	addi	a0,a0,16
ffffffffc0201d14:	e97ff0ef          	jal	ffffffffc0201baa <slob_alloc.constprop.0>
ffffffffc0201d18:	87aa                	mv	a5,a0
		return m ? (void *)(m + 1) : 0;
ffffffffc0201d1a:	0541                	addi	a0,a0,16
ffffffffc0201d1c:	fbe5                	bnez	a5,ffffffffc0201d0c <kmalloc+0x54>
		return 0;
ffffffffc0201d1e:	4501                	li	a0,0
}
ffffffffc0201d20:	60e2                	ld	ra,24(sp)
ffffffffc0201d22:	6105                	addi	sp,sp,32
ffffffffc0201d24:	8082                	ret
        intr_disable();
ffffffffc0201d26:	bdffe0ef          	jal	ffffffffc0200904 <intr_disable>
		bb->next = bigblocks;
ffffffffc0201d2a:	0009a797          	auipc	a5,0x9a
ffffffffc0201d2e:	cae7b783          	ld	a5,-850(a5) # ffffffffc029b9d8 <bigblocks>
		bigblocks = bb;
ffffffffc0201d32:	0009a717          	auipc	a4,0x9a
ffffffffc0201d36:	ca873323          	sd	s0,-858(a4) # ffffffffc029b9d8 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201d3a:	e81c                	sd	a5,16(s0)
        intr_enable();
ffffffffc0201d3c:	bc3fe0ef          	jal	ffffffffc02008fe <intr_enable>
		return bb->pages;
ffffffffc0201d40:	6408                	ld	a0,8(s0)
}
ffffffffc0201d42:	60e2                	ld	ra,24(sp)
		return bb->pages;
ffffffffc0201d44:	6442                	ld	s0,16(sp)
}
ffffffffc0201d46:	6105                	addi	sp,sp,32
ffffffffc0201d48:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d4a:	8522                	mv	a0,s0
ffffffffc0201d4c:	45e1                	li	a1,24
ffffffffc0201d4e:	ce7ff0ef          	jal	ffffffffc0201a34 <slob_free>
		return 0;
ffffffffc0201d52:	4501                	li	a0,0
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d54:	6442                	ld	s0,16(sp)
ffffffffc0201d56:	b7e9                	j	ffffffffc0201d20 <kmalloc+0x68>
ffffffffc0201d58:	6442                	ld	s0,16(sp)
		return 0;
ffffffffc0201d5a:	4501                	li	a0,0
ffffffffc0201d5c:	b7d1                	j	ffffffffc0201d20 <kmalloc+0x68>

ffffffffc0201d5e <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d5e:	c571                	beqz	a0,ffffffffc0201e2a <kfree+0xcc>
		return;

	if (!((unsigned long)block & (PAGE_SIZE - 1)))
ffffffffc0201d60:	03451793          	slli	a5,a0,0x34
ffffffffc0201d64:	e3e1                	bnez	a5,ffffffffc0201e24 <kfree+0xc6>
{
ffffffffc0201d66:	1101                	addi	sp,sp,-32
ffffffffc0201d68:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201d6a:	100027f3          	csrr	a5,sstatus
ffffffffc0201d6e:	8b89                	andi	a5,a5,2
ffffffffc0201d70:	e7c1                	bnez	a5,ffffffffc0201df8 <kfree+0x9a>
	{
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d72:	0009a797          	auipc	a5,0x9a
ffffffffc0201d76:	c667b783          	ld	a5,-922(a5) # ffffffffc029b9d8 <bigblocks>
    return 0;
ffffffffc0201d7a:	4581                	li	a1,0
ffffffffc0201d7c:	cbad                	beqz	a5,ffffffffc0201dee <kfree+0x90>
	bigblock_t *bb, **last = &bigblocks;
ffffffffc0201d7e:	0009a617          	auipc	a2,0x9a
ffffffffc0201d82:	c5a60613          	addi	a2,a2,-934 # ffffffffc029b9d8 <bigblocks>
ffffffffc0201d86:	a021                	j	ffffffffc0201d8e <kfree+0x30>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201d88:	01070613          	addi	a2,a4,16
ffffffffc0201d8c:	c3a5                	beqz	a5,ffffffffc0201dec <kfree+0x8e>
		{
			if (bb->pages == block)
ffffffffc0201d8e:	6794                	ld	a3,8(a5)
ffffffffc0201d90:	873e                	mv	a4,a5
			{
				*last = bb->next;
ffffffffc0201d92:	6b9c                	ld	a5,16(a5)
			if (bb->pages == block)
ffffffffc0201d94:	fea69ae3          	bne	a3,a0,ffffffffc0201d88 <kfree+0x2a>
				*last = bb->next;
ffffffffc0201d98:	e21c                	sd	a5,0(a2)
    if (flag)
ffffffffc0201d9a:	edb5                	bnez	a1,ffffffffc0201e16 <kfree+0xb8>
    return pa2page(PADDR(kva));
ffffffffc0201d9c:	c02007b7          	lui	a5,0xc0200
ffffffffc0201da0:	0af56263          	bltu	a0,a5,ffffffffc0201e44 <kfree+0xe6>
ffffffffc0201da4:	0009a797          	auipc	a5,0x9a
ffffffffc0201da8:	c547b783          	ld	a5,-940(a5) # ffffffffc029b9f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0201dac:	0009a697          	auipc	a3,0x9a
ffffffffc0201db0:	c546b683          	ld	a3,-940(a3) # ffffffffc029ba00 <npage>
    return pa2page(PADDR(kva));
ffffffffc0201db4:	8d1d                	sub	a0,a0,a5
    if (PPN(pa) >= npage)
ffffffffc0201db6:	00c55793          	srli	a5,a0,0xc
ffffffffc0201dba:	06d7f963          	bgeu	a5,a3,ffffffffc0201e2c <kfree+0xce>
    return &pages[PPN(pa) - nbase];
ffffffffc0201dbe:	00006617          	auipc	a2,0x6
ffffffffc0201dc2:	baa63603          	ld	a2,-1110(a2) # ffffffffc0207968 <nbase>
ffffffffc0201dc6:	0009a517          	auipc	a0,0x9a
ffffffffc0201dca:	c4253503          	ld	a0,-958(a0) # ffffffffc029ba08 <pages>
	free_pages(kva2page((void*)kva), 1 << order);
ffffffffc0201dce:	4314                	lw	a3,0(a4)
ffffffffc0201dd0:	8f91                	sub	a5,a5,a2
ffffffffc0201dd2:	079a                	slli	a5,a5,0x6
ffffffffc0201dd4:	4585                	li	a1,1
ffffffffc0201dd6:	953e                	add	a0,a0,a5
ffffffffc0201dd8:	00d595bb          	sllw	a1,a1,a3
ffffffffc0201ddc:	e03a                	sd	a4,0(sp)
ffffffffc0201dde:	0d6000ef          	jal	ffffffffc0201eb4 <free_pages>
				spin_unlock_irqrestore(&block_lock, flags);
				__slob_free_pages((unsigned long)block, bb->order);
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de2:	6502                	ld	a0,0(sp)
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201de4:	60e2                	ld	ra,24(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201de6:	45e1                	li	a1,24
}
ffffffffc0201de8:	6105                	addi	sp,sp,32
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dea:	b1a9                	j	ffffffffc0201a34 <slob_free>
ffffffffc0201dec:	e185                	bnez	a1,ffffffffc0201e0c <kfree+0xae>
}
ffffffffc0201dee:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201df0:	1541                	addi	a0,a0,-16
ffffffffc0201df2:	4581                	li	a1,0
}
ffffffffc0201df4:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201df6:	b93d                	j	ffffffffc0201a34 <slob_free>
        intr_disable();
ffffffffc0201df8:	e02a                	sd	a0,0(sp)
ffffffffc0201dfa:	b0bfe0ef          	jal	ffffffffc0200904 <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next)
ffffffffc0201dfe:	0009a797          	auipc	a5,0x9a
ffffffffc0201e02:	bda7b783          	ld	a5,-1062(a5) # ffffffffc029b9d8 <bigblocks>
ffffffffc0201e06:	6502                	ld	a0,0(sp)
        return 1;
ffffffffc0201e08:	4585                	li	a1,1
ffffffffc0201e0a:	fbb5                	bnez	a5,ffffffffc0201d7e <kfree+0x20>
ffffffffc0201e0c:	e02a                	sd	a0,0(sp)
        intr_enable();
ffffffffc0201e0e:	af1fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e12:	6502                	ld	a0,0(sp)
ffffffffc0201e14:	bfe9                	j	ffffffffc0201dee <kfree+0x90>
ffffffffc0201e16:	e42a                	sd	a0,8(sp)
ffffffffc0201e18:	e03a                	sd	a4,0(sp)
ffffffffc0201e1a:	ae5fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0201e1e:	6522                	ld	a0,8(sp)
ffffffffc0201e20:	6702                	ld	a4,0(sp)
ffffffffc0201e22:	bfad                	j	ffffffffc0201d9c <kfree+0x3e>
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201e24:	1541                	addi	a0,a0,-16
ffffffffc0201e26:	4581                	li	a1,0
ffffffffc0201e28:	b131                	j	ffffffffc0201a34 <slob_free>
ffffffffc0201e2a:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0201e2c:	00005617          	auipc	a2,0x5
ffffffffc0201e30:	82c60613          	addi	a2,a2,-2004 # ffffffffc0206658 <etext+0xe50>
ffffffffc0201e34:	06900593          	li	a1,105
ffffffffc0201e38:	00004517          	auipc	a0,0x4
ffffffffc0201e3c:	77850513          	addi	a0,a0,1912 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0201e40:	e06fe0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc0201e44:	86aa                	mv	a3,a0
ffffffffc0201e46:	00004617          	auipc	a2,0x4
ffffffffc0201e4a:	7ea60613          	addi	a2,a2,2026 # ffffffffc0206630 <etext+0xe28>
ffffffffc0201e4e:	07700593          	li	a1,119
ffffffffc0201e52:	00004517          	auipc	a0,0x4
ffffffffc0201e56:	75e50513          	addi	a0,a0,1886 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0201e5a:	decfe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e5e <pa2page.part.0>:
pa2page(uintptr_t pa)
ffffffffc0201e5e:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e60:	00004617          	auipc	a2,0x4
ffffffffc0201e64:	7f860613          	addi	a2,a2,2040 # ffffffffc0206658 <etext+0xe50>
ffffffffc0201e68:	06900593          	li	a1,105
ffffffffc0201e6c:	00004517          	auipc	a0,0x4
ffffffffc0201e70:	74450513          	addi	a0,a0,1860 # ffffffffc02065b0 <etext+0xda8>
pa2page(uintptr_t pa)
ffffffffc0201e74:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e76:	dd0fe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0201e7a <alloc_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201e7a:	100027f3          	csrr	a5,sstatus
ffffffffc0201e7e:	8b89                	andi	a5,a5,2
ffffffffc0201e80:	e799                	bnez	a5,ffffffffc0201e8e <alloc_pages+0x14>
{
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e82:	0009a797          	auipc	a5,0x9a
ffffffffc0201e86:	b5e7b783          	ld	a5,-1186(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201e8a:	6f9c                	ld	a5,24(a5)
ffffffffc0201e8c:	8782                	jr	a5
{
ffffffffc0201e8e:	1101                	addi	sp,sp,-32
ffffffffc0201e90:	ec06                	sd	ra,24(sp)
ffffffffc0201e92:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0201e94:	a71fe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201e98:	0009a797          	auipc	a5,0x9a
ffffffffc0201e9c:	b487b783          	ld	a5,-1208(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201ea0:	6522                	ld	a0,8(sp)
ffffffffc0201ea2:	6f9c                	ld	a5,24(a5)
ffffffffc0201ea4:	9782                	jalr	a5
ffffffffc0201ea6:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ea8:	a57fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc0201eac:	60e2                	ld	ra,24(sp)
ffffffffc0201eae:	6522                	ld	a0,8(sp)
ffffffffc0201eb0:	6105                	addi	sp,sp,32
ffffffffc0201eb2:	8082                	ret

ffffffffc0201eb4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eb4:	100027f3          	csrr	a5,sstatus
ffffffffc0201eb8:	8b89                	andi	a5,a5,2
ffffffffc0201eba:	e799                	bnez	a5,ffffffffc0201ec8 <free_pages+0x14>
void free_pages(struct Page *base, size_t n)
{
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ebc:	0009a797          	auipc	a5,0x9a
ffffffffc0201ec0:	b247b783          	ld	a5,-1244(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201ec4:	739c                	ld	a5,32(a5)
ffffffffc0201ec6:	8782                	jr	a5
{
ffffffffc0201ec8:	1101                	addi	sp,sp,-32
ffffffffc0201eca:	ec06                	sd	ra,24(sp)
ffffffffc0201ecc:	e42e                	sd	a1,8(sp)
ffffffffc0201ece:	e02a                	sd	a0,0(sp)
        intr_disable();
ffffffffc0201ed0:	a35fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201ed4:	0009a797          	auipc	a5,0x9a
ffffffffc0201ed8:	b0c7b783          	ld	a5,-1268(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201edc:	65a2                	ld	a1,8(sp)
ffffffffc0201ede:	6502                	ld	a0,0(sp)
ffffffffc0201ee0:	739c                	ld	a5,32(a5)
ffffffffc0201ee2:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201ee4:	60e2                	ld	ra,24(sp)
ffffffffc0201ee6:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201ee8:	a17fe06f          	j	ffffffffc02008fe <intr_enable>

ffffffffc0201eec <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201eec:	100027f3          	csrr	a5,sstatus
ffffffffc0201ef0:	8b89                	andi	a5,a5,2
ffffffffc0201ef2:	e799                	bnez	a5,ffffffffc0201f00 <nr_free_pages+0x14>
{
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201ef4:	0009a797          	auipc	a5,0x9a
ffffffffc0201ef8:	aec7b783          	ld	a5,-1300(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201efc:	779c                	ld	a5,40(a5)
ffffffffc0201efe:	8782                	jr	a5
{
ffffffffc0201f00:	1101                	addi	sp,sp,-32
ffffffffc0201f02:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201f04:	a01fe0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f08:	0009a797          	auipc	a5,0x9a
ffffffffc0201f0c:	ad87b783          	ld	a5,-1320(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201f10:	779c                	ld	a5,40(a5)
ffffffffc0201f12:	9782                	jalr	a5
ffffffffc0201f14:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201f16:	9e9fe0ef          	jal	ffffffffc02008fe <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f1a:	60e2                	ld	ra,24(sp)
ffffffffc0201f1c:	6522                	ld	a0,8(sp)
ffffffffc0201f1e:	6105                	addi	sp,sp,32
ffffffffc0201f20:	8082                	ret

ffffffffc0201f22 <get_pte>:
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create)
{
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f22:	01e5d793          	srli	a5,a1,0x1e
ffffffffc0201f26:	1ff7f793          	andi	a5,a5,511
ffffffffc0201f2a:	078e                	slli	a5,a5,0x3
ffffffffc0201f2c:	00f50733          	add	a4,a0,a5
    if (!(*pdep1 & PTE_V))
ffffffffc0201f30:	6314                	ld	a3,0(a4)
{
ffffffffc0201f32:	7139                	addi	sp,sp,-64
ffffffffc0201f34:	f822                	sd	s0,48(sp)
ffffffffc0201f36:	f426                	sd	s1,40(sp)
ffffffffc0201f38:	fc06                	sd	ra,56(sp)
    if (!(*pdep1 & PTE_V))
ffffffffc0201f3a:	0016f793          	andi	a5,a3,1
{
ffffffffc0201f3e:	842e                	mv	s0,a1
ffffffffc0201f40:	8832                	mv	a6,a2
ffffffffc0201f42:	0009a497          	auipc	s1,0x9a
ffffffffc0201f46:	abe48493          	addi	s1,s1,-1346 # ffffffffc029ba00 <npage>
    if (!(*pdep1 & PTE_V))
ffffffffc0201f4a:	ebd1                	bnez	a5,ffffffffc0201fde <get_pte+0xbc>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f4c:	16060d63          	beqz	a2,ffffffffc02020c6 <get_pte+0x1a4>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0201f50:	100027f3          	csrr	a5,sstatus
ffffffffc0201f54:	8b89                	andi	a5,a5,2
ffffffffc0201f56:	16079e63          	bnez	a5,ffffffffc02020d2 <get_pte+0x1b0>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201f5a:	0009a797          	auipc	a5,0x9a
ffffffffc0201f5e:	a867b783          	ld	a5,-1402(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0201f62:	4505                	li	a0,1
ffffffffc0201f64:	e43a                	sd	a4,8(sp)
ffffffffc0201f66:	6f9c                	ld	a5,24(a5)
ffffffffc0201f68:	e832                	sd	a2,16(sp)
ffffffffc0201f6a:	9782                	jalr	a5
ffffffffc0201f6c:	6722                	ld	a4,8(sp)
ffffffffc0201f6e:	6842                	ld	a6,16(sp)
ffffffffc0201f70:	87aa                	mv	a5,a0
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0201f72:	14078a63          	beqz	a5,ffffffffc02020c6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc0201f76:	0009a517          	auipc	a0,0x9a
ffffffffc0201f7a:	a9253503          	ld	a0,-1390(a0) # ffffffffc029ba08 <pages>
ffffffffc0201f7e:	000808b7          	lui	a7,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201f82:	0009a497          	auipc	s1,0x9a
ffffffffc0201f86:	a7e48493          	addi	s1,s1,-1410 # ffffffffc029ba00 <npage>
ffffffffc0201f8a:	40a78533          	sub	a0,a5,a0
ffffffffc0201f8e:	8519                	srai	a0,a0,0x6
ffffffffc0201f90:	9546                	add	a0,a0,a7
ffffffffc0201f92:	6090                	ld	a2,0(s1)
ffffffffc0201f94:	00c51693          	slli	a3,a0,0xc
    page->ref = val;
ffffffffc0201f98:	4585                	li	a1,1
ffffffffc0201f9a:	82b1                	srli	a3,a3,0xc
ffffffffc0201f9c:	c38c                	sw	a1,0(a5)
    return page2ppn(page) << PGSHIFT;
ffffffffc0201f9e:	0532                	slli	a0,a0,0xc
ffffffffc0201fa0:	1ac6f763          	bgeu	a3,a2,ffffffffc020214e <get_pte+0x22c>
ffffffffc0201fa4:	0009a697          	auipc	a3,0x9a
ffffffffc0201fa8:	a546b683          	ld	a3,-1452(a3) # ffffffffc029b9f8 <va_pa_offset>
ffffffffc0201fac:	6605                	lui	a2,0x1
ffffffffc0201fae:	4581                	li	a1,0
ffffffffc0201fb0:	9536                	add	a0,a0,a3
ffffffffc0201fb2:	ec42                	sd	a6,24(sp)
ffffffffc0201fb4:	e83e                	sd	a5,16(sp)
ffffffffc0201fb6:	e43a                	sd	a4,8(sp)
ffffffffc0201fb8:	027030ef          	jal	ffffffffc02057de <memset>
    return page - pages + nbase;
ffffffffc0201fbc:	0009a697          	auipc	a3,0x9a
ffffffffc0201fc0:	a4c6b683          	ld	a3,-1460(a3) # ffffffffc029ba08 <pages>
ffffffffc0201fc4:	67c2                	ld	a5,16(sp)
ffffffffc0201fc6:	000808b7          	lui	a7,0x80
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201fca:	6722                	ld	a4,8(sp)
ffffffffc0201fcc:	40d786b3          	sub	a3,a5,a3
ffffffffc0201fd0:	8699                	srai	a3,a3,0x6
ffffffffc0201fd2:	96c6                	add	a3,a3,a7
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type)
{
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201fd4:	06aa                	slli	a3,a3,0xa
ffffffffc0201fd6:	6862                	ld	a6,24(sp)
ffffffffc0201fd8:	0116e693          	ori	a3,a3,17
ffffffffc0201fdc:	e314                	sd	a3,0(a4)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201fde:	c006f693          	andi	a3,a3,-1024
ffffffffc0201fe2:	6098                	ld	a4,0(s1)
ffffffffc0201fe4:	068a                	slli	a3,a3,0x2
ffffffffc0201fe6:	00c6d793          	srli	a5,a3,0xc
ffffffffc0201fea:	14e7f663          	bgeu	a5,a4,ffffffffc0202136 <get_pte+0x214>
ffffffffc0201fee:	0009a897          	auipc	a7,0x9a
ffffffffc0201ff2:	a0a88893          	addi	a7,a7,-1526 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc0201ff6:	0008b603          	ld	a2,0(a7)
ffffffffc0201ffa:	01545793          	srli	a5,s0,0x15
ffffffffc0201ffe:	1ff7f793          	andi	a5,a5,511
ffffffffc0202002:	96b2                	add	a3,a3,a2
ffffffffc0202004:	078e                	slli	a5,a5,0x3
ffffffffc0202006:	97b6                	add	a5,a5,a3
    if (!(*pdep0 & PTE_V))
ffffffffc0202008:	6394                	ld	a3,0(a5)
ffffffffc020200a:	0016f613          	andi	a2,a3,1
ffffffffc020200e:	e659                	bnez	a2,ffffffffc020209c <get_pte+0x17a>
    {
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202010:	0a080b63          	beqz	a6,ffffffffc02020c6 <get_pte+0x1a4>
ffffffffc0202014:	10002773          	csrr	a4,sstatus
ffffffffc0202018:	8b09                	andi	a4,a4,2
ffffffffc020201a:	ef71                	bnez	a4,ffffffffc02020f6 <get_pte+0x1d4>
        page = pmm_manager->alloc_pages(n);
ffffffffc020201c:	0009a717          	auipc	a4,0x9a
ffffffffc0202020:	9c473703          	ld	a4,-1596(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202024:	4505                	li	a0,1
ffffffffc0202026:	e43e                	sd	a5,8(sp)
ffffffffc0202028:	6f18                	ld	a4,24(a4)
ffffffffc020202a:	9702                	jalr	a4
ffffffffc020202c:	67a2                	ld	a5,8(sp)
ffffffffc020202e:	872a                	mv	a4,a0
ffffffffc0202030:	0009a897          	auipc	a7,0x9a
ffffffffc0202034:	9c888893          	addi	a7,a7,-1592 # ffffffffc029b9f8 <va_pa_offset>
        if (!create || (page = alloc_page()) == NULL)
ffffffffc0202038:	c759                	beqz	a4,ffffffffc02020c6 <get_pte+0x1a4>
    return page - pages + nbase;
ffffffffc020203a:	0009a697          	auipc	a3,0x9a
ffffffffc020203e:	9ce6b683          	ld	a3,-1586(a3) # ffffffffc029ba08 <pages>
ffffffffc0202042:	00080837          	lui	a6,0x80
        {
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202046:	608c                	ld	a1,0(s1)
ffffffffc0202048:	40d706b3          	sub	a3,a4,a3
ffffffffc020204c:	8699                	srai	a3,a3,0x6
ffffffffc020204e:	96c2                	add	a3,a3,a6
ffffffffc0202050:	00c69613          	slli	a2,a3,0xc
    page->ref = val;
ffffffffc0202054:	4505                	li	a0,1
ffffffffc0202056:	8231                	srli	a2,a2,0xc
ffffffffc0202058:	c308                	sw	a0,0(a4)
    return page2ppn(page) << PGSHIFT;
ffffffffc020205a:	06b2                	slli	a3,a3,0xc
ffffffffc020205c:	10b67663          	bgeu	a2,a1,ffffffffc0202168 <get_pte+0x246>
ffffffffc0202060:	0008b503          	ld	a0,0(a7)
ffffffffc0202064:	6605                	lui	a2,0x1
ffffffffc0202066:	4581                	li	a1,0
ffffffffc0202068:	9536                	add	a0,a0,a3
ffffffffc020206a:	e83a                	sd	a4,16(sp)
ffffffffc020206c:	e43e                	sd	a5,8(sp)
ffffffffc020206e:	770030ef          	jal	ffffffffc02057de <memset>
    return page - pages + nbase;
ffffffffc0202072:	0009a697          	auipc	a3,0x9a
ffffffffc0202076:	9966b683          	ld	a3,-1642(a3) # ffffffffc029ba08 <pages>
ffffffffc020207a:	6742                	ld	a4,16(sp)
ffffffffc020207c:	00080837          	lui	a6,0x80
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0202080:	67a2                	ld	a5,8(sp)
ffffffffc0202082:	40d706b3          	sub	a3,a4,a3
ffffffffc0202086:	8699                	srai	a3,a3,0x6
ffffffffc0202088:	96c2                	add	a3,a3,a6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc020208a:	06aa                	slli	a3,a3,0xa
ffffffffc020208c:	0116e693          	ori	a3,a3,17
ffffffffc0202090:	e394                	sd	a3,0(a5)
    }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202092:	6098                	ld	a4,0(s1)
ffffffffc0202094:	0009a897          	auipc	a7,0x9a
ffffffffc0202098:	96488893          	addi	a7,a7,-1692 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc020209c:	c006f693          	andi	a3,a3,-1024
ffffffffc02020a0:	068a                	slli	a3,a3,0x2
ffffffffc02020a2:	00c6d793          	srli	a5,a3,0xc
ffffffffc02020a6:	06e7fc63          	bgeu	a5,a4,ffffffffc020211e <get_pte+0x1fc>
ffffffffc02020aa:	0008b783          	ld	a5,0(a7)
ffffffffc02020ae:	8031                	srli	s0,s0,0xc
ffffffffc02020b0:	1ff47413          	andi	s0,s0,511
ffffffffc02020b4:	040e                	slli	s0,s0,0x3
ffffffffc02020b6:	96be                	add	a3,a3,a5
}
ffffffffc02020b8:	70e2                	ld	ra,56(sp)
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020ba:	00868533          	add	a0,a3,s0
}
ffffffffc02020be:	7442                	ld	s0,48(sp)
ffffffffc02020c0:	74a2                	ld	s1,40(sp)
ffffffffc02020c2:	6121                	addi	sp,sp,64
ffffffffc02020c4:	8082                	ret
ffffffffc02020c6:	70e2                	ld	ra,56(sp)
ffffffffc02020c8:	7442                	ld	s0,48(sp)
ffffffffc02020ca:	74a2                	ld	s1,40(sp)
            return NULL;
ffffffffc02020cc:	4501                	li	a0,0
}
ffffffffc02020ce:	6121                	addi	sp,sp,64
ffffffffc02020d0:	8082                	ret
        intr_disable();
ffffffffc02020d2:	e83a                	sd	a4,16(sp)
ffffffffc02020d4:	ec32                	sd	a2,24(sp)
ffffffffc02020d6:	82ffe0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc02020da:	0009a797          	auipc	a5,0x9a
ffffffffc02020de:	9067b783          	ld	a5,-1786(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc02020e2:	4505                	li	a0,1
ffffffffc02020e4:	6f9c                	ld	a5,24(a5)
ffffffffc02020e6:	9782                	jalr	a5
ffffffffc02020e8:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02020ea:	815fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02020ee:	6862                	ld	a6,24(sp)
ffffffffc02020f0:	6742                	ld	a4,16(sp)
ffffffffc02020f2:	67a2                	ld	a5,8(sp)
ffffffffc02020f4:	bdbd                	j	ffffffffc0201f72 <get_pte+0x50>
        intr_disable();
ffffffffc02020f6:	e83e                	sd	a5,16(sp)
ffffffffc02020f8:	80dfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02020fc:	0009a717          	auipc	a4,0x9a
ffffffffc0202100:	8e473703          	ld	a4,-1820(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202104:	4505                	li	a0,1
ffffffffc0202106:	6f18                	ld	a4,24(a4)
ffffffffc0202108:	9702                	jalr	a4
ffffffffc020210a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020210c:	ff2fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202110:	6722                	ld	a4,8(sp)
ffffffffc0202112:	67c2                	ld	a5,16(sp)
ffffffffc0202114:	0009a897          	auipc	a7,0x9a
ffffffffc0202118:	8e488893          	addi	a7,a7,-1820 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc020211c:	bf31                	j	ffffffffc0202038 <get_pte+0x116>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc020211e:	00004617          	auipc	a2,0x4
ffffffffc0202122:	46a60613          	addi	a2,a2,1130 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202126:	0fa00593          	li	a1,250
ffffffffc020212a:	00004517          	auipc	a0,0x4
ffffffffc020212e:	54e50513          	addi	a0,a0,1358 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202132:	b14fe0ef          	jal	ffffffffc0200446 <__panic>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0202136:	00004617          	auipc	a2,0x4
ffffffffc020213a:	45260613          	addi	a2,a2,1106 # ffffffffc0206588 <etext+0xd80>
ffffffffc020213e:	0ed00593          	li	a1,237
ffffffffc0202142:	00004517          	auipc	a0,0x4
ffffffffc0202146:	53650513          	addi	a0,a0,1334 # ffffffffc0206678 <etext+0xe70>
ffffffffc020214a:	afcfe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020214e:	86aa                	mv	a3,a0
ffffffffc0202150:	00004617          	auipc	a2,0x4
ffffffffc0202154:	43860613          	addi	a2,a2,1080 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202158:	0e900593          	li	a1,233
ffffffffc020215c:	00004517          	auipc	a0,0x4
ffffffffc0202160:	51c50513          	addi	a0,a0,1308 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202164:	ae2fe0ef          	jal	ffffffffc0200446 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202168:	00004617          	auipc	a2,0x4
ffffffffc020216c:	42060613          	addi	a2,a2,1056 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202170:	0f700593          	li	a1,247
ffffffffc0202174:	00004517          	auipc	a0,0x4
ffffffffc0202178:	50450513          	addi	a0,a0,1284 # ffffffffc0206678 <etext+0xe70>
ffffffffc020217c:	acafe0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0202180 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store)
{
ffffffffc0202180:	1141                	addi	sp,sp,-16
ffffffffc0202182:	e022                	sd	s0,0(sp)
ffffffffc0202184:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202186:	4601                	li	a2,0
{
ffffffffc0202188:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020218a:	d99ff0ef          	jal	ffffffffc0201f22 <get_pte>
    if (ptep_store != NULL)
ffffffffc020218e:	c011                	beqz	s0,ffffffffc0202192 <get_page+0x12>
    {
        *ptep_store = ptep;
ffffffffc0202190:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202192:	c511                	beqz	a0,ffffffffc020219e <get_page+0x1e>
ffffffffc0202194:	611c                	ld	a5,0(a0)
    {
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202196:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V)
ffffffffc0202198:	0017f713          	andi	a4,a5,1
ffffffffc020219c:	e709                	bnez	a4,ffffffffc02021a6 <get_page+0x26>
}
ffffffffc020219e:	60a2                	ld	ra,8(sp)
ffffffffc02021a0:	6402                	ld	s0,0(sp)
ffffffffc02021a2:	0141                	addi	sp,sp,16
ffffffffc02021a4:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02021a6:	0009a717          	auipc	a4,0x9a
ffffffffc02021aa:	85a73703          	ld	a4,-1958(a4) # ffffffffc029ba00 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02021ae:	078a                	slli	a5,a5,0x2
ffffffffc02021b0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02021b2:	00e7ff63          	bgeu	a5,a4,ffffffffc02021d0 <get_page+0x50>
    return &pages[PPN(pa) - nbase];
ffffffffc02021b6:	0009a517          	auipc	a0,0x9a
ffffffffc02021ba:	85253503          	ld	a0,-1966(a0) # ffffffffc029ba08 <pages>
ffffffffc02021be:	60a2                	ld	ra,8(sp)
ffffffffc02021c0:	6402                	ld	s0,0(sp)
ffffffffc02021c2:	079a                	slli	a5,a5,0x6
ffffffffc02021c4:	fe000737          	lui	a4,0xfe000
ffffffffc02021c8:	97ba                	add	a5,a5,a4
ffffffffc02021ca:	953e                	add	a0,a0,a5
ffffffffc02021cc:	0141                	addi	sp,sp,16
ffffffffc02021ce:	8082                	ret
ffffffffc02021d0:	c8fff0ef          	jal	ffffffffc0201e5e <pa2page.part.0>

ffffffffc02021d4 <unmap_range>:
        tlb_invalidate(pgdir, la);
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end)
{
ffffffffc02021d4:	715d                	addi	sp,sp,-80
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021d6:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc02021da:	e486                	sd	ra,72(sp)
ffffffffc02021dc:	e0a2                	sd	s0,64(sp)
ffffffffc02021de:	fc26                	sd	s1,56(sp)
ffffffffc02021e0:	f84a                	sd	s2,48(sp)
ffffffffc02021e2:	f44e                	sd	s3,40(sp)
ffffffffc02021e4:	f052                	sd	s4,32(sp)
ffffffffc02021e6:	ec56                	sd	s5,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021e8:	03479713          	slli	a4,a5,0x34
ffffffffc02021ec:	ef61                	bnez	a4,ffffffffc02022c4 <unmap_range+0xf0>
    assert(USER_ACCESS(start, end));
ffffffffc02021ee:	00200a37          	lui	s4,0x200
ffffffffc02021f2:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc02021f6:	0145b733          	sltu	a4,a1,s4
ffffffffc02021fa:	0017b793          	seqz	a5,a5
ffffffffc02021fe:	8fd9                	or	a5,a5,a4
ffffffffc0202200:	842e                	mv	s0,a1
ffffffffc0202202:	84b2                	mv	s1,a2
ffffffffc0202204:	e3e5                	bnez	a5,ffffffffc02022e4 <unmap_range+0x110>
ffffffffc0202206:	4785                	li	a5,1
ffffffffc0202208:	07fe                	slli	a5,a5,0x1f
ffffffffc020220a:	0785                	addi	a5,a5,1
ffffffffc020220c:	892a                	mv	s2,a0
ffffffffc020220e:	6985                	lui	s3,0x1
    do
    {
        pte_t *ptep = get_pte(pgdir, start, 0);
        if (ptep == NULL)
        {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202210:	ffe00ab7          	lui	s5,0xffe00
    assert(USER_ACCESS(start, end));
ffffffffc0202214:	0cf67863          	bgeu	a2,a5,ffffffffc02022e4 <unmap_range+0x110>
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc0202218:	4601                	li	a2,0
ffffffffc020221a:	85a2                	mv	a1,s0
ffffffffc020221c:	854a                	mv	a0,s2
ffffffffc020221e:	d05ff0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc0202222:	87aa                	mv	a5,a0
        if (ptep == NULL)
ffffffffc0202224:	cd31                	beqz	a0,ffffffffc0202280 <unmap_range+0xac>
            continue;
        }
        if (*ptep != 0)
ffffffffc0202226:	6118                	ld	a4,0(a0)
ffffffffc0202228:	ef11                	bnez	a4,ffffffffc0202244 <unmap_range+0x70>
        {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc020222a:	944e                	add	s0,s0,s3
    } while (start != 0 && start < end);
ffffffffc020222c:	c019                	beqz	s0,ffffffffc0202232 <unmap_range+0x5e>
ffffffffc020222e:	fe9465e3          	bltu	s0,s1,ffffffffc0202218 <unmap_range+0x44>
}
ffffffffc0202232:	60a6                	ld	ra,72(sp)
ffffffffc0202234:	6406                	ld	s0,64(sp)
ffffffffc0202236:	74e2                	ld	s1,56(sp)
ffffffffc0202238:	7942                	ld	s2,48(sp)
ffffffffc020223a:	79a2                	ld	s3,40(sp)
ffffffffc020223c:	7a02                	ld	s4,32(sp)
ffffffffc020223e:	6ae2                	ld	s5,24(sp)
ffffffffc0202240:	6161                	addi	sp,sp,80
ffffffffc0202242:	8082                	ret
    if (*ptep & PTE_V)
ffffffffc0202244:	00177693          	andi	a3,a4,1
ffffffffc0202248:	d2ed                	beqz	a3,ffffffffc020222a <unmap_range+0x56>
    if (PPN(pa) >= npage)
ffffffffc020224a:	00099697          	auipc	a3,0x99
ffffffffc020224e:	7b66b683          	ld	a3,1974(a3) # ffffffffc029ba00 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc0202252:	070a                	slli	a4,a4,0x2
ffffffffc0202254:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc0202256:	0ad77763          	bgeu	a4,a3,ffffffffc0202304 <unmap_range+0x130>
    return &pages[PPN(pa) - nbase];
ffffffffc020225a:	00099517          	auipc	a0,0x99
ffffffffc020225e:	7ae53503          	ld	a0,1966(a0) # ffffffffc029ba08 <pages>
ffffffffc0202262:	071a                	slli	a4,a4,0x6
ffffffffc0202264:	fe0006b7          	lui	a3,0xfe000
ffffffffc0202268:	9736                	add	a4,a4,a3
ffffffffc020226a:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc020226c:	4118                	lw	a4,0(a0)
ffffffffc020226e:	377d                	addiw	a4,a4,-1 # fffffffffdffffff <end+0x3dd645cf>
ffffffffc0202270:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202272:	cb19                	beqz	a4,ffffffffc0202288 <unmap_range+0xb4>
        *ptep = 0;
ffffffffc0202274:	0007b023          	sd	zero,0(a5)

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la)
{
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202278:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020227c:	944e                	add	s0,s0,s3
ffffffffc020227e:	b77d                	j	ffffffffc020222c <unmap_range+0x58>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202280:	9452                	add	s0,s0,s4
ffffffffc0202282:	01547433          	and	s0,s0,s5
            continue;
ffffffffc0202286:	b75d                	j	ffffffffc020222c <unmap_range+0x58>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202288:	10002773          	csrr	a4,sstatus
ffffffffc020228c:	8b09                	andi	a4,a4,2
ffffffffc020228e:	eb19                	bnez	a4,ffffffffc02022a4 <unmap_range+0xd0>
        pmm_manager->free_pages(base, n);
ffffffffc0202290:	00099717          	auipc	a4,0x99
ffffffffc0202294:	75073703          	ld	a4,1872(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202298:	4585                	li	a1,1
ffffffffc020229a:	e03e                	sd	a5,0(sp)
ffffffffc020229c:	7318                	ld	a4,32(a4)
ffffffffc020229e:	9702                	jalr	a4
    if (flag)
ffffffffc02022a0:	6782                	ld	a5,0(sp)
ffffffffc02022a2:	bfc9                	j	ffffffffc0202274 <unmap_range+0xa0>
        intr_disable();
ffffffffc02022a4:	e43e                	sd	a5,8(sp)
ffffffffc02022a6:	e02a                	sd	a0,0(sp)
ffffffffc02022a8:	e5cfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc02022ac:	00099717          	auipc	a4,0x99
ffffffffc02022b0:	73473703          	ld	a4,1844(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc02022b4:	6502                	ld	a0,0(sp)
ffffffffc02022b6:	4585                	li	a1,1
ffffffffc02022b8:	7318                	ld	a4,32(a4)
ffffffffc02022ba:	9702                	jalr	a4
        intr_enable();
ffffffffc02022bc:	e42fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02022c0:	67a2                	ld	a5,8(sp)
ffffffffc02022c2:	bf4d                	j	ffffffffc0202274 <unmap_range+0xa0>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022c4:	00004697          	auipc	a3,0x4
ffffffffc02022c8:	3c468693          	addi	a3,a3,964 # ffffffffc0206688 <etext+0xe80>
ffffffffc02022cc:	00004617          	auipc	a2,0x4
ffffffffc02022d0:	f0c60613          	addi	a2,a2,-244 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02022d4:	12000593          	li	a1,288
ffffffffc02022d8:	00004517          	auipc	a0,0x4
ffffffffc02022dc:	3a050513          	addi	a0,a0,928 # ffffffffc0206678 <etext+0xe70>
ffffffffc02022e0:	966fe0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02022e4:	00004697          	auipc	a3,0x4
ffffffffc02022e8:	3d468693          	addi	a3,a3,980 # ffffffffc02066b8 <etext+0xeb0>
ffffffffc02022ec:	00004617          	auipc	a2,0x4
ffffffffc02022f0:	eec60613          	addi	a2,a2,-276 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02022f4:	12100593          	li	a1,289
ffffffffc02022f8:	00004517          	auipc	a0,0x4
ffffffffc02022fc:	38050513          	addi	a0,a0,896 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202300:	946fe0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202304:	b5bff0ef          	jal	ffffffffc0201e5e <pa2page.part.0>

ffffffffc0202308 <exit_range>:
{
ffffffffc0202308:	7135                	addi	sp,sp,-160
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020230a:	00c5e7b3          	or	a5,a1,a2
{
ffffffffc020230e:	ed06                	sd	ra,152(sp)
ffffffffc0202310:	e922                	sd	s0,144(sp)
ffffffffc0202312:	e526                	sd	s1,136(sp)
ffffffffc0202314:	e14a                	sd	s2,128(sp)
ffffffffc0202316:	fcce                	sd	s3,120(sp)
ffffffffc0202318:	f8d2                	sd	s4,112(sp)
ffffffffc020231a:	f4d6                	sd	s5,104(sp)
ffffffffc020231c:	f0da                	sd	s6,96(sp)
ffffffffc020231e:	ecde                	sd	s7,88(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202320:	17d2                	slli	a5,a5,0x34
ffffffffc0202322:	22079263          	bnez	a5,ffffffffc0202546 <exit_range+0x23e>
    assert(USER_ACCESS(start, end));
ffffffffc0202326:	00200937          	lui	s2,0x200
ffffffffc020232a:	00c5b7b3          	sltu	a5,a1,a2
ffffffffc020232e:	0125b733          	sltu	a4,a1,s2
ffffffffc0202332:	0017b793          	seqz	a5,a5
ffffffffc0202336:	8fd9                	or	a5,a5,a4
ffffffffc0202338:	26079263          	bnez	a5,ffffffffc020259c <exit_range+0x294>
ffffffffc020233c:	4785                	li	a5,1
ffffffffc020233e:	07fe                	slli	a5,a5,0x1f
ffffffffc0202340:	0785                	addi	a5,a5,1
ffffffffc0202342:	24f67d63          	bgeu	a2,a5,ffffffffc020259c <exit_range+0x294>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202346:	c00004b7          	lui	s1,0xc0000
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020234a:	ffe007b7          	lui	a5,0xffe00
ffffffffc020234e:	8a2a                	mv	s4,a0
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc0202350:	8ced                	and	s1,s1,a1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202352:	00f5f833          	and	a6,a1,a5
    if (PPN(pa) >= npage)
ffffffffc0202356:	00099a97          	auipc	s5,0x99
ffffffffc020235a:	6aaa8a93          	addi	s5,s5,1706 # ffffffffc029ba00 <npage>
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc020235e:	400009b7          	lui	s3,0x40000
ffffffffc0202362:	a809                	j	ffffffffc0202374 <exit_range+0x6c>
        d1start += PDSIZE;
ffffffffc0202364:	013487b3          	add	a5,s1,s3
ffffffffc0202368:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020236c:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc020236e:	c3f1                	beqz	a5,ffffffffc0202432 <exit_range+0x12a>
ffffffffc0202370:	0cc7f163          	bgeu	a5,a2,ffffffffc0202432 <exit_range+0x12a>
        pde1 = pgdir[PDX1(d1start)];
ffffffffc0202374:	01e4d413          	srli	s0,s1,0x1e
ffffffffc0202378:	1ff47413          	andi	s0,s0,511
ffffffffc020237c:	040e                	slli	s0,s0,0x3
ffffffffc020237e:	9452                	add	s0,s0,s4
ffffffffc0202380:	00043883          	ld	a7,0(s0)
        if (pde1 & PTE_V)
ffffffffc0202384:	0018f793          	andi	a5,a7,1
ffffffffc0202388:	dff1                	beqz	a5,ffffffffc0202364 <exit_range+0x5c>
ffffffffc020238a:	000ab783          	ld	a5,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020238e:	088a                	slli	a7,a7,0x2
ffffffffc0202390:	00c8d893          	srli	a7,a7,0xc
    if (PPN(pa) >= npage)
ffffffffc0202394:	20f8f263          	bgeu	a7,a5,ffffffffc0202598 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202398:	fff802b7          	lui	t0,0xfff80
ffffffffc020239c:	00588f33          	add	t5,a7,t0
    return page - pages + nbase;
ffffffffc02023a0:	000803b7          	lui	t2,0x80
ffffffffc02023a4:	007f0733          	add	a4,t5,t2
    return page2ppn(page) << PGSHIFT;
ffffffffc02023a8:	00c71e13          	slli	t3,a4,0xc
    return &pages[PPN(pa) - nbase];
ffffffffc02023ac:	0f1a                	slli	t5,t5,0x6
    return KADDR(page2pa(page));
ffffffffc02023ae:	1cf77863          	bgeu	a4,a5,ffffffffc020257e <exit_range+0x276>
ffffffffc02023b2:	00099f97          	auipc	t6,0x99
ffffffffc02023b6:	646f8f93          	addi	t6,t6,1606 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc02023ba:	000fb783          	ld	a5,0(t6)
            free_pd0 = 1;
ffffffffc02023be:	4e85                	li	t4,1
ffffffffc02023c0:	6b05                	lui	s6,0x1
ffffffffc02023c2:	9e3e                	add	t3,t3,a5
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023c4:	01348333          	add	t1,s1,s3
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023c8:	01585713          	srli	a4,a6,0x15
ffffffffc02023cc:	1ff77713          	andi	a4,a4,511
ffffffffc02023d0:	070e                	slli	a4,a4,0x3
ffffffffc02023d2:	9772                	add	a4,a4,t3
ffffffffc02023d4:	631c                	ld	a5,0(a4)
                if (pde0 & PTE_V)
ffffffffc02023d6:	0017f693          	andi	a3,a5,1
ffffffffc02023da:	e6bd                	bnez	a3,ffffffffc0202448 <exit_range+0x140>
                    free_pd0 = 0;
ffffffffc02023dc:	4e81                	li	t4,0
                d0start += PTSIZE;
ffffffffc02023de:	984a                	add	a6,a6,s2
            } while (d0start != 0 && d0start < d1start + PDSIZE && d0start < end);
ffffffffc02023e0:	00080863          	beqz	a6,ffffffffc02023f0 <exit_range+0xe8>
ffffffffc02023e4:	879a                	mv	a5,t1
ffffffffc02023e6:	00667363          	bgeu	a2,t1,ffffffffc02023ec <exit_range+0xe4>
ffffffffc02023ea:	87b2                	mv	a5,a2
ffffffffc02023ec:	fcf86ee3          	bltu	a6,a5,ffffffffc02023c8 <exit_range+0xc0>
            if (free_pd0)
ffffffffc02023f0:	f60e8ae3          	beqz	t4,ffffffffc0202364 <exit_range+0x5c>
    if (PPN(pa) >= npage)
ffffffffc02023f4:	000ab783          	ld	a5,0(s5)
ffffffffc02023f8:	1af8f063          	bgeu	a7,a5,ffffffffc0202598 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc02023fc:	00099517          	auipc	a0,0x99
ffffffffc0202400:	60c53503          	ld	a0,1548(a0) # ffffffffc029ba08 <pages>
ffffffffc0202404:	957a                	add	a0,a0,t5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202406:	100027f3          	csrr	a5,sstatus
ffffffffc020240a:	8b89                	andi	a5,a5,2
ffffffffc020240c:	10079b63          	bnez	a5,ffffffffc0202522 <exit_range+0x21a>
        pmm_manager->free_pages(base, n);
ffffffffc0202410:	00099797          	auipc	a5,0x99
ffffffffc0202414:	5d07b783          	ld	a5,1488(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202418:	4585                	li	a1,1
ffffffffc020241a:	e432                	sd	a2,8(sp)
ffffffffc020241c:	739c                	ld	a5,32(a5)
ffffffffc020241e:	9782                	jalr	a5
ffffffffc0202420:	6622                	ld	a2,8(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202422:	00043023          	sd	zero,0(s0)
        d1start += PDSIZE;
ffffffffc0202426:	013487b3          	add	a5,s1,s3
ffffffffc020242a:	400004b7          	lui	s1,0x40000
        d0start = d1start;
ffffffffc020242e:	8826                	mv	a6,s1
    } while (d1start != 0 && d1start < end);
ffffffffc0202430:	f3a1                	bnez	a5,ffffffffc0202370 <exit_range+0x68>
}
ffffffffc0202432:	60ea                	ld	ra,152(sp)
ffffffffc0202434:	644a                	ld	s0,144(sp)
ffffffffc0202436:	64aa                	ld	s1,136(sp)
ffffffffc0202438:	690a                	ld	s2,128(sp)
ffffffffc020243a:	79e6                	ld	s3,120(sp)
ffffffffc020243c:	7a46                	ld	s4,112(sp)
ffffffffc020243e:	7aa6                	ld	s5,104(sp)
ffffffffc0202440:	7b06                	ld	s6,96(sp)
ffffffffc0202442:	6be6                	ld	s7,88(sp)
ffffffffc0202444:	610d                	addi	sp,sp,160
ffffffffc0202446:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc0202448:	000ab503          	ld	a0,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020244c:	078a                	slli	a5,a5,0x2
ffffffffc020244e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202450:	14a7f463          	bgeu	a5,a0,ffffffffc0202598 <exit_range+0x290>
    return &pages[PPN(pa) - nbase];
ffffffffc0202454:	9796                	add	a5,a5,t0
    return page - pages + nbase;
ffffffffc0202456:	00778bb3          	add	s7,a5,t2
    return &pages[PPN(pa) - nbase];
ffffffffc020245a:	00679593          	slli	a1,a5,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc020245e:	00cb9693          	slli	a3,s7,0xc
    return KADDR(page2pa(page));
ffffffffc0202462:	10abf263          	bgeu	s7,a0,ffffffffc0202566 <exit_range+0x25e>
ffffffffc0202466:	000fb783          	ld	a5,0(t6)
ffffffffc020246a:	96be                	add	a3,a3,a5
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc020246c:	01668533          	add	a0,a3,s6
                        if (pt[i] & PTE_V)
ffffffffc0202470:	629c                	ld	a5,0(a3)
ffffffffc0202472:	8b85                	andi	a5,a5,1
ffffffffc0202474:	f7ad                	bnez	a5,ffffffffc02023de <exit_range+0xd6>
                    for (int i = 0; i < NPTEENTRY; i++)
ffffffffc0202476:	06a1                	addi	a3,a3,8
ffffffffc0202478:	fea69ce3          	bne	a3,a0,ffffffffc0202470 <exit_range+0x168>
    return &pages[PPN(pa) - nbase];
ffffffffc020247c:	00099517          	auipc	a0,0x99
ffffffffc0202480:	58c53503          	ld	a0,1420(a0) # ffffffffc029ba08 <pages>
ffffffffc0202484:	952e                	add	a0,a0,a1
ffffffffc0202486:	100027f3          	csrr	a5,sstatus
ffffffffc020248a:	8b89                	andi	a5,a5,2
ffffffffc020248c:	e3b9                	bnez	a5,ffffffffc02024d2 <exit_range+0x1ca>
        pmm_manager->free_pages(base, n);
ffffffffc020248e:	00099797          	auipc	a5,0x99
ffffffffc0202492:	5527b783          	ld	a5,1362(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202496:	4585                	li	a1,1
ffffffffc0202498:	e0b2                	sd	a2,64(sp)
ffffffffc020249a:	739c                	ld	a5,32(a5)
ffffffffc020249c:	fc1a                	sd	t1,56(sp)
ffffffffc020249e:	f846                	sd	a7,48(sp)
ffffffffc02024a0:	f47a                	sd	t5,40(sp)
ffffffffc02024a2:	f072                	sd	t3,32(sp)
ffffffffc02024a4:	ec76                	sd	t4,24(sp)
ffffffffc02024a6:	e842                	sd	a6,16(sp)
ffffffffc02024a8:	e43a                	sd	a4,8(sp)
ffffffffc02024aa:	9782                	jalr	a5
    if (flag)
ffffffffc02024ac:	6722                	ld	a4,8(sp)
ffffffffc02024ae:	6842                	ld	a6,16(sp)
ffffffffc02024b0:	6ee2                	ld	t4,24(sp)
ffffffffc02024b2:	7e02                	ld	t3,32(sp)
ffffffffc02024b4:	7f22                	ld	t5,40(sp)
ffffffffc02024b6:	78c2                	ld	a7,48(sp)
ffffffffc02024b8:	7362                	ld	t1,56(sp)
ffffffffc02024ba:	6606                	ld	a2,64(sp)
                        pd0[PDX0(d0start)] = 0;
ffffffffc02024bc:	fff802b7          	lui	t0,0xfff80
ffffffffc02024c0:	000803b7          	lui	t2,0x80
ffffffffc02024c4:	00099f97          	auipc	t6,0x99
ffffffffc02024c8:	534f8f93          	addi	t6,t6,1332 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc02024cc:	00073023          	sd	zero,0(a4)
ffffffffc02024d0:	b739                	j	ffffffffc02023de <exit_range+0xd6>
        intr_disable();
ffffffffc02024d2:	e4b2                	sd	a2,72(sp)
ffffffffc02024d4:	e09a                	sd	t1,64(sp)
ffffffffc02024d6:	fc46                	sd	a7,56(sp)
ffffffffc02024d8:	f47a                	sd	t5,40(sp)
ffffffffc02024da:	f072                	sd	t3,32(sp)
ffffffffc02024dc:	ec76                	sd	t4,24(sp)
ffffffffc02024de:	e842                	sd	a6,16(sp)
ffffffffc02024e0:	e43a                	sd	a4,8(sp)
ffffffffc02024e2:	f82a                	sd	a0,48(sp)
ffffffffc02024e4:	c20fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02024e8:	00099797          	auipc	a5,0x99
ffffffffc02024ec:	4f87b783          	ld	a5,1272(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc02024f0:	7542                	ld	a0,48(sp)
ffffffffc02024f2:	4585                	li	a1,1
ffffffffc02024f4:	739c                	ld	a5,32(a5)
ffffffffc02024f6:	9782                	jalr	a5
        intr_enable();
ffffffffc02024f8:	c06fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02024fc:	6722                	ld	a4,8(sp)
ffffffffc02024fe:	6626                	ld	a2,72(sp)
ffffffffc0202500:	6306                	ld	t1,64(sp)
ffffffffc0202502:	78e2                	ld	a7,56(sp)
ffffffffc0202504:	7f22                	ld	t5,40(sp)
ffffffffc0202506:	7e02                	ld	t3,32(sp)
ffffffffc0202508:	6ee2                	ld	t4,24(sp)
ffffffffc020250a:	6842                	ld	a6,16(sp)
ffffffffc020250c:	00099f97          	auipc	t6,0x99
ffffffffc0202510:	4ecf8f93          	addi	t6,t6,1260 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc0202514:	000803b7          	lui	t2,0x80
ffffffffc0202518:	fff802b7          	lui	t0,0xfff80
                        pd0[PDX0(d0start)] = 0;
ffffffffc020251c:	00073023          	sd	zero,0(a4)
ffffffffc0202520:	bd7d                	j	ffffffffc02023de <exit_range+0xd6>
        intr_disable();
ffffffffc0202522:	e832                	sd	a2,16(sp)
ffffffffc0202524:	e42a                	sd	a0,8(sp)
ffffffffc0202526:	bdefe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc020252a:	00099797          	auipc	a5,0x99
ffffffffc020252e:	4b67b783          	ld	a5,1206(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202532:	6522                	ld	a0,8(sp)
ffffffffc0202534:	4585                	li	a1,1
ffffffffc0202536:	739c                	ld	a5,32(a5)
ffffffffc0202538:	9782                	jalr	a5
        intr_enable();
ffffffffc020253a:	bc4fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020253e:	6642                	ld	a2,16(sp)
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202540:	00043023          	sd	zero,0(s0)
ffffffffc0202544:	b5cd                	j	ffffffffc0202426 <exit_range+0x11e>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202546:	00004697          	auipc	a3,0x4
ffffffffc020254a:	14268693          	addi	a3,a3,322 # ffffffffc0206688 <etext+0xe80>
ffffffffc020254e:	00004617          	auipc	a2,0x4
ffffffffc0202552:	c8a60613          	addi	a2,a2,-886 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202556:	13500593          	li	a1,309
ffffffffc020255a:	00004517          	auipc	a0,0x4
ffffffffc020255e:	11e50513          	addi	a0,a0,286 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202562:	ee5fd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202566:	00004617          	auipc	a2,0x4
ffffffffc020256a:	02260613          	addi	a2,a2,34 # ffffffffc0206588 <etext+0xd80>
ffffffffc020256e:	07100593          	li	a1,113
ffffffffc0202572:	00004517          	auipc	a0,0x4
ffffffffc0202576:	03e50513          	addi	a0,a0,62 # ffffffffc02065b0 <etext+0xda8>
ffffffffc020257a:	ecdfd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc020257e:	86f2                	mv	a3,t3
ffffffffc0202580:	00004617          	auipc	a2,0x4
ffffffffc0202584:	00860613          	addi	a2,a2,8 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202588:	07100593          	li	a1,113
ffffffffc020258c:	00004517          	auipc	a0,0x4
ffffffffc0202590:	02450513          	addi	a0,a0,36 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0202594:	eb3fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202598:	8c7ff0ef          	jal	ffffffffc0201e5e <pa2page.part.0>
    assert(USER_ACCESS(start, end));
ffffffffc020259c:	00004697          	auipc	a3,0x4
ffffffffc02025a0:	11c68693          	addi	a3,a3,284 # ffffffffc02066b8 <etext+0xeb0>
ffffffffc02025a4:	00004617          	auipc	a2,0x4
ffffffffc02025a8:	c3460613          	addi	a2,a2,-972 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02025ac:	13600593          	li	a1,310
ffffffffc02025b0:	00004517          	auipc	a0,0x4
ffffffffc02025b4:	0c850513          	addi	a0,a0,200 # ffffffffc0206678 <etext+0xe70>
ffffffffc02025b8:	e8ffd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02025bc <page_remove>:
{
ffffffffc02025bc:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025be:	4601                	li	a2,0
{
ffffffffc02025c0:	e822                	sd	s0,16(sp)
ffffffffc02025c2:	ec06                	sd	ra,24(sp)
ffffffffc02025c4:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc02025c6:	95dff0ef          	jal	ffffffffc0201f22 <get_pte>
    if (ptep != NULL)
ffffffffc02025ca:	c511                	beqz	a0,ffffffffc02025d6 <page_remove+0x1a>
    if (*ptep & PTE_V)
ffffffffc02025cc:	6118                	ld	a4,0(a0)
ffffffffc02025ce:	87aa                	mv	a5,a0
ffffffffc02025d0:	00177693          	andi	a3,a4,1
ffffffffc02025d4:	e689                	bnez	a3,ffffffffc02025de <page_remove+0x22>
}
ffffffffc02025d6:	60e2                	ld	ra,24(sp)
ffffffffc02025d8:	6442                	ld	s0,16(sp)
ffffffffc02025da:	6105                	addi	sp,sp,32
ffffffffc02025dc:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02025de:	00099697          	auipc	a3,0x99
ffffffffc02025e2:	4226b683          	ld	a3,1058(a3) # ffffffffc029ba00 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02025e6:	070a                	slli	a4,a4,0x2
ffffffffc02025e8:	8331                	srli	a4,a4,0xc
    if (PPN(pa) >= npage)
ffffffffc02025ea:	06d77563          	bgeu	a4,a3,ffffffffc0202654 <page_remove+0x98>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ee:	00099517          	auipc	a0,0x99
ffffffffc02025f2:	41a53503          	ld	a0,1050(a0) # ffffffffc029ba08 <pages>
ffffffffc02025f6:	071a                	slli	a4,a4,0x6
ffffffffc02025f8:	fe0006b7          	lui	a3,0xfe000
ffffffffc02025fc:	9736                	add	a4,a4,a3
ffffffffc02025fe:	953a                	add	a0,a0,a4
    page->ref -= 1;
ffffffffc0202600:	4118                	lw	a4,0(a0)
ffffffffc0202602:	377d                	addiw	a4,a4,-1
ffffffffc0202604:	c118                	sw	a4,0(a0)
        if (page_ref(page) == 0)
ffffffffc0202606:	cb09                	beqz	a4,ffffffffc0202618 <page_remove+0x5c>
        *ptep = 0;
ffffffffc0202608:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020260c:	12040073          	sfence.vma	s0
}
ffffffffc0202610:	60e2                	ld	ra,24(sp)
ffffffffc0202612:	6442                	ld	s0,16(sp)
ffffffffc0202614:	6105                	addi	sp,sp,32
ffffffffc0202616:	8082                	ret
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202618:	10002773          	csrr	a4,sstatus
ffffffffc020261c:	8b09                	andi	a4,a4,2
ffffffffc020261e:	eb19                	bnez	a4,ffffffffc0202634 <page_remove+0x78>
        pmm_manager->free_pages(base, n);
ffffffffc0202620:	00099717          	auipc	a4,0x99
ffffffffc0202624:	3c073703          	ld	a4,960(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202628:	4585                	li	a1,1
ffffffffc020262a:	e03e                	sd	a5,0(sp)
ffffffffc020262c:	7318                	ld	a4,32(a4)
ffffffffc020262e:	9702                	jalr	a4
    if (flag)
ffffffffc0202630:	6782                	ld	a5,0(sp)
ffffffffc0202632:	bfd9                	j	ffffffffc0202608 <page_remove+0x4c>
        intr_disable();
ffffffffc0202634:	e43e                	sd	a5,8(sp)
ffffffffc0202636:	e02a                	sd	a0,0(sp)
ffffffffc0202638:	accfe0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc020263c:	00099717          	auipc	a4,0x99
ffffffffc0202640:	3a473703          	ld	a4,932(a4) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202644:	6502                	ld	a0,0(sp)
ffffffffc0202646:	4585                	li	a1,1
ffffffffc0202648:	7318                	ld	a4,32(a4)
ffffffffc020264a:	9702                	jalr	a4
        intr_enable();
ffffffffc020264c:	ab2fe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202650:	67a2                	ld	a5,8(sp)
ffffffffc0202652:	bf5d                	j	ffffffffc0202608 <page_remove+0x4c>
ffffffffc0202654:	80bff0ef          	jal	ffffffffc0201e5e <pa2page.part.0>

ffffffffc0202658 <page_insert>:
{
ffffffffc0202658:	7139                	addi	sp,sp,-64
ffffffffc020265a:	f426                	sd	s1,40(sp)
ffffffffc020265c:	84b2                	mv	s1,a2
ffffffffc020265e:	f822                	sd	s0,48(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202660:	4605                	li	a2,1
{
ffffffffc0202662:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202664:	85a6                	mv	a1,s1
{
ffffffffc0202666:	fc06                	sd	ra,56(sp)
ffffffffc0202668:	e436                	sd	a3,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020266a:	8b9ff0ef          	jal	ffffffffc0201f22 <get_pte>
    if (ptep == NULL)
ffffffffc020266e:	cd61                	beqz	a0,ffffffffc0202746 <page_insert+0xee>
    page->ref += 1;
ffffffffc0202670:	400c                	lw	a1,0(s0)
    if (*ptep & PTE_V)
ffffffffc0202672:	611c                	ld	a5,0(a0)
ffffffffc0202674:	66a2                	ld	a3,8(sp)
ffffffffc0202676:	0015861b          	addiw	a2,a1,1 # 1001 <_binary_obj___user_softint_out_size-0x7c07>
ffffffffc020267a:	c010                	sw	a2,0(s0)
ffffffffc020267c:	0017f613          	andi	a2,a5,1
ffffffffc0202680:	872a                	mv	a4,a0
ffffffffc0202682:	e61d                	bnez	a2,ffffffffc02026b0 <page_insert+0x58>
    return &pages[PPN(pa) - nbase];
ffffffffc0202684:	00099617          	auipc	a2,0x99
ffffffffc0202688:	38463603          	ld	a2,900(a2) # ffffffffc029ba08 <pages>
    return page - pages + nbase;
ffffffffc020268c:	8c11                	sub	s0,s0,a2
ffffffffc020268e:	8419                	srai	s0,s0,0x6
    return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202690:	200007b7          	lui	a5,0x20000
ffffffffc0202694:	042a                	slli	s0,s0,0xa
ffffffffc0202696:	943e                	add	s0,s0,a5
ffffffffc0202698:	8ec1                	or	a3,a3,s0
ffffffffc020269a:	0016e693          	ori	a3,a3,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc020269e:	e314                	sd	a3,0(a4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026a0:	12048073          	sfence.vma	s1
    return 0;
ffffffffc02026a4:	4501                	li	a0,0
}
ffffffffc02026a6:	70e2                	ld	ra,56(sp)
ffffffffc02026a8:	7442                	ld	s0,48(sp)
ffffffffc02026aa:	74a2                	ld	s1,40(sp)
ffffffffc02026ac:	6121                	addi	sp,sp,64
ffffffffc02026ae:	8082                	ret
    if (PPN(pa) >= npage)
ffffffffc02026b0:	00099617          	auipc	a2,0x99
ffffffffc02026b4:	35063603          	ld	a2,848(a2) # ffffffffc029ba00 <npage>
    return pa2page(PTE_ADDR(pte));
ffffffffc02026b8:	078a                	slli	a5,a5,0x2
ffffffffc02026ba:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc02026bc:	08c7f763          	bgeu	a5,a2,ffffffffc020274a <page_insert+0xf2>
    return &pages[PPN(pa) - nbase];
ffffffffc02026c0:	00099617          	auipc	a2,0x99
ffffffffc02026c4:	34863603          	ld	a2,840(a2) # ffffffffc029ba08 <pages>
ffffffffc02026c8:	fe000537          	lui	a0,0xfe000
ffffffffc02026cc:	079a                	slli	a5,a5,0x6
ffffffffc02026ce:	97aa                	add	a5,a5,a0
ffffffffc02026d0:	00f60533          	add	a0,a2,a5
        if (p == page)
ffffffffc02026d4:	00a40963          	beq	s0,a0,ffffffffc02026e6 <page_insert+0x8e>
    page->ref -= 1;
ffffffffc02026d8:	411c                	lw	a5,0(a0)
ffffffffc02026da:	37fd                	addiw	a5,a5,-1 # 1fffffff <_binary_obj___user_exit_out_size+0x1fff5e07>
ffffffffc02026dc:	c11c                	sw	a5,0(a0)
        if (page_ref(page) == 0)
ffffffffc02026de:	c791                	beqz	a5,ffffffffc02026ea <page_insert+0x92>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02026e0:	12048073          	sfence.vma	s1
}
ffffffffc02026e4:	b765                	j	ffffffffc020268c <page_insert+0x34>
ffffffffc02026e6:	c00c                	sw	a1,0(s0)
    return page->ref;
ffffffffc02026e8:	b755                	j	ffffffffc020268c <page_insert+0x34>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02026ea:	100027f3          	csrr	a5,sstatus
ffffffffc02026ee:	8b89                	andi	a5,a5,2
ffffffffc02026f0:	e39d                	bnez	a5,ffffffffc0202716 <page_insert+0xbe>
        pmm_manager->free_pages(base, n);
ffffffffc02026f2:	00099797          	auipc	a5,0x99
ffffffffc02026f6:	2ee7b783          	ld	a5,750(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc02026fa:	4585                	li	a1,1
ffffffffc02026fc:	e83a                	sd	a4,16(sp)
ffffffffc02026fe:	739c                	ld	a5,32(a5)
ffffffffc0202700:	e436                	sd	a3,8(sp)
ffffffffc0202702:	9782                	jalr	a5
    return page - pages + nbase;
ffffffffc0202704:	00099617          	auipc	a2,0x99
ffffffffc0202708:	30463603          	ld	a2,772(a2) # ffffffffc029ba08 <pages>
ffffffffc020270c:	66a2                	ld	a3,8(sp)
ffffffffc020270e:	6742                	ld	a4,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202710:	12048073          	sfence.vma	s1
ffffffffc0202714:	bfa5                	j	ffffffffc020268c <page_insert+0x34>
        intr_disable();
ffffffffc0202716:	ec3a                	sd	a4,24(sp)
ffffffffc0202718:	e836                	sd	a3,16(sp)
ffffffffc020271a:	e42a                	sd	a0,8(sp)
ffffffffc020271c:	9e8fe0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202720:	00099797          	auipc	a5,0x99
ffffffffc0202724:	2c07b783          	ld	a5,704(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0202728:	6522                	ld	a0,8(sp)
ffffffffc020272a:	4585                	li	a1,1
ffffffffc020272c:	739c                	ld	a5,32(a5)
ffffffffc020272e:	9782                	jalr	a5
        intr_enable();
ffffffffc0202730:	9cefe0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202734:	00099617          	auipc	a2,0x99
ffffffffc0202738:	2d463603          	ld	a2,724(a2) # ffffffffc029ba08 <pages>
ffffffffc020273c:	6762                	ld	a4,24(sp)
ffffffffc020273e:	66c2                	ld	a3,16(sp)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202740:	12048073          	sfence.vma	s1
ffffffffc0202744:	b7a1                	j	ffffffffc020268c <page_insert+0x34>
        return -E_NO_MEM;
ffffffffc0202746:	5571                	li	a0,-4
ffffffffc0202748:	bfb9                	j	ffffffffc02026a6 <page_insert+0x4e>
ffffffffc020274a:	f14ff0ef          	jal	ffffffffc0201e5e <pa2page.part.0>

ffffffffc020274e <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc020274e:	00005797          	auipc	a5,0x5
ffffffffc0202752:	ec278793          	addi	a5,a5,-318 # ffffffffc0207610 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202756:	638c                	ld	a1,0(a5)
{
ffffffffc0202758:	7159                	addi	sp,sp,-112
ffffffffc020275a:	f486                	sd	ra,104(sp)
ffffffffc020275c:	e8ca                	sd	s2,80(sp)
ffffffffc020275e:	e4ce                	sd	s3,72(sp)
ffffffffc0202760:	f85a                	sd	s6,48(sp)
ffffffffc0202762:	f0a2                	sd	s0,96(sp)
ffffffffc0202764:	eca6                	sd	s1,88(sp)
ffffffffc0202766:	e0d2                	sd	s4,64(sp)
ffffffffc0202768:	fc56                	sd	s5,56(sp)
ffffffffc020276a:	f45e                	sd	s7,40(sp)
ffffffffc020276c:	f062                	sd	s8,32(sp)
ffffffffc020276e:	ec66                	sd	s9,24(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202770:	00099b17          	auipc	s6,0x99
ffffffffc0202774:	270b0b13          	addi	s6,s6,624 # ffffffffc029b9e0 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202778:	00004517          	auipc	a0,0x4
ffffffffc020277c:	f5850513          	addi	a0,a0,-168 # ffffffffc02066d0 <etext+0xec8>
    pmm_manager = &default_pmm_manager;
ffffffffc0202780:	00fb3023          	sd	a5,0(s6)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202784:	a11fd0ef          	jal	ffffffffc0200194 <cprintf>
    pmm_manager->init();
ffffffffc0202788:	000b3783          	ld	a5,0(s6)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020278c:	00099997          	auipc	s3,0x99
ffffffffc0202790:	26c98993          	addi	s3,s3,620 # ffffffffc029b9f8 <va_pa_offset>
    pmm_manager->init();
ffffffffc0202794:	679c                	ld	a5,8(a5)
ffffffffc0202796:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0202798:	57f5                	li	a5,-3
ffffffffc020279a:	07fa                	slli	a5,a5,0x1e
ffffffffc020279c:	00f9b023          	sd	a5,0(s3)
    uint64_t mem_begin = get_memory_base();
ffffffffc02027a0:	94afe0ef          	jal	ffffffffc02008ea <get_memory_base>
ffffffffc02027a4:	892a                	mv	s2,a0
    uint64_t mem_size = get_memory_size();
ffffffffc02027a6:	94efe0ef          	jal	ffffffffc02008f4 <get_memory_size>
    if (mem_size == 0)
ffffffffc02027aa:	70050e63          	beqz	a0,ffffffffc0202ec6 <pmm_init+0x778>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027ae:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc02027b0:	00004517          	auipc	a0,0x4
ffffffffc02027b4:	f5850513          	addi	a0,a0,-168 # ffffffffc0206708 <etext+0xf00>
ffffffffc02027b8:	9ddfd0ef          	jal	ffffffffc0200194 <cprintf>
    uint64_t mem_end = mem_begin + mem_size;
ffffffffc02027bc:	00990433          	add	s0,s2,s1
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc02027c0:	864a                	mv	a2,s2
ffffffffc02027c2:	85a6                	mv	a1,s1
ffffffffc02027c4:	fff40693          	addi	a3,s0,-1
ffffffffc02027c8:	00004517          	auipc	a0,0x4
ffffffffc02027cc:	f5850513          	addi	a0,a0,-168 # ffffffffc0206720 <etext+0xf18>
ffffffffc02027d0:	9c5fd0ef          	jal	ffffffffc0200194 <cprintf>
    if (maxpa > KERNTOP)
ffffffffc02027d4:	c80007b7          	lui	a5,0xc8000
ffffffffc02027d8:	8522                	mv	a0,s0
ffffffffc02027da:	5287ed63          	bltu	a5,s0,ffffffffc0202d14 <pmm_init+0x5c6>
ffffffffc02027de:	77fd                	lui	a5,0xfffff
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027e0:	0009a617          	auipc	a2,0x9a
ffffffffc02027e4:	24f60613          	addi	a2,a2,591 # ffffffffc029ca2f <end+0xfff>
ffffffffc02027e8:	8e7d                	and	a2,a2,a5
    npage = maxpa / PGSIZE;
ffffffffc02027ea:	8131                	srli	a0,a0,0xc
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027ec:	00099b97          	auipc	s7,0x99
ffffffffc02027f0:	21cb8b93          	addi	s7,s7,540 # ffffffffc029ba08 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02027f4:	00099497          	auipc	s1,0x99
ffffffffc02027f8:	20c48493          	addi	s1,s1,524 # ffffffffc029ba00 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02027fc:	00cbb023          	sd	a2,0(s7)
    npage = maxpa / PGSIZE;
ffffffffc0202800:	e088                	sd	a0,0(s1)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202802:	000807b7          	lui	a5,0x80
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0202806:	86b2                	mv	a3,a2
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202808:	02f50763          	beq	a0,a5,ffffffffc0202836 <pmm_init+0xe8>
ffffffffc020280c:	4701                	li	a4,0
ffffffffc020280e:	4585                	li	a1,1
ffffffffc0202810:	fff806b7          	lui	a3,0xfff80
        SetPageReserved(pages + i);
ffffffffc0202814:	00671793          	slli	a5,a4,0x6
ffffffffc0202818:	97b2                	add	a5,a5,a2
ffffffffc020281a:	07a1                	addi	a5,a5,8 # 80008 <_binary_obj___user_exit_out_size+0x75e10>
ffffffffc020281c:	40b7b02f          	amoor.d	zero,a1,(a5)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202820:	6088                	ld	a0,0(s1)
ffffffffc0202822:	0705                	addi	a4,a4,1
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202824:	000bb603          	ld	a2,0(s7)
    for (size_t i = 0; i < npage - nbase; i++)
ffffffffc0202828:	00d507b3          	add	a5,a0,a3
ffffffffc020282c:	fef764e3          	bltu	a4,a5,ffffffffc0202814 <pmm_init+0xc6>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202830:	079a                	slli	a5,a5,0x6
ffffffffc0202832:	00f606b3          	add	a3,a2,a5
ffffffffc0202836:	c02007b7          	lui	a5,0xc0200
ffffffffc020283a:	16f6eee3          	bltu	a3,a5,ffffffffc02031b6 <pmm_init+0xa68>
ffffffffc020283e:	0009b583          	ld	a1,0(s3)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0202842:	77fd                	lui	a5,0xfffff
ffffffffc0202844:	8c7d                	and	s0,s0,a5
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202846:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end)
ffffffffc0202848:	4e86ed63          	bltu	a3,s0,ffffffffc0202d42 <pmm_init+0x5f4>
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc020284c:	00004517          	auipc	a0,0x4
ffffffffc0202850:	efc50513          	addi	a0,a0,-260 # ffffffffc0206748 <etext+0xf40>
ffffffffc0202854:	941fd0ef          	jal	ffffffffc0200194 <cprintf>
    return page;
}

static void check_alloc_page(void)
{
    pmm_manager->check();
ffffffffc0202858:	000b3783          	ld	a5,0(s6)
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc020285c:	00099917          	auipc	s2,0x99
ffffffffc0202860:	19490913          	addi	s2,s2,404 # ffffffffc029b9f0 <boot_pgdir_va>
    pmm_manager->check();
ffffffffc0202864:	7b9c                	ld	a5,48(a5)
ffffffffc0202866:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202868:	00004517          	auipc	a0,0x4
ffffffffc020286c:	ef850513          	addi	a0,a0,-264 # ffffffffc0206760 <etext+0xf58>
ffffffffc0202870:	925fd0ef          	jal	ffffffffc0200194 <cprintf>
    boot_pgdir_va = (pte_t *)boot_page_table_sv39;
ffffffffc0202874:	00007697          	auipc	a3,0x7
ffffffffc0202878:	78c68693          	addi	a3,a3,1932 # ffffffffc020a000 <boot_page_table_sv39>
ffffffffc020287c:	00d93023          	sd	a3,0(s2)
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0202880:	c02007b7          	lui	a5,0xc0200
ffffffffc0202884:	2af6eee3          	bltu	a3,a5,ffffffffc0203340 <pmm_init+0xbf2>
ffffffffc0202888:	0009b783          	ld	a5,0(s3)
ffffffffc020288c:	8e9d                	sub	a3,a3,a5
ffffffffc020288e:	00099797          	auipc	a5,0x99
ffffffffc0202892:	14d7bd23          	sd	a3,346(a5) # ffffffffc029b9e8 <boot_pgdir_pa>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0202896:	100027f3          	csrr	a5,sstatus
ffffffffc020289a:	8b89                	andi	a5,a5,2
ffffffffc020289c:	48079963          	bnez	a5,ffffffffc0202d2e <pmm_init+0x5e0>
        ret = pmm_manager->nr_free_pages();
ffffffffc02028a0:	000b3783          	ld	a5,0(s6)
ffffffffc02028a4:	779c                	ld	a5,40(a5)
ffffffffc02028a6:	9782                	jalr	a5
ffffffffc02028a8:	842a                	mv	s0,a0
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store = nr_free_pages();

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02028aa:	6098                	ld	a4,0(s1)
ffffffffc02028ac:	c80007b7          	lui	a5,0xc8000
ffffffffc02028b0:	83b1                	srli	a5,a5,0xc
ffffffffc02028b2:	66e7e663          	bltu	a5,a4,ffffffffc0202f1e <pmm_init+0x7d0>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc02028b6:	00093503          	ld	a0,0(s2)
ffffffffc02028ba:	64050263          	beqz	a0,ffffffffc0202efe <pmm_init+0x7b0>
ffffffffc02028be:	03451793          	slli	a5,a0,0x34
ffffffffc02028c2:	62079e63          	bnez	a5,ffffffffc0202efe <pmm_init+0x7b0>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc02028c6:	4601                	li	a2,0
ffffffffc02028c8:	4581                	li	a1,0
ffffffffc02028ca:	8b7ff0ef          	jal	ffffffffc0202180 <get_page>
ffffffffc02028ce:	240519e3          	bnez	a0,ffffffffc0203320 <pmm_init+0xbd2>
ffffffffc02028d2:	100027f3          	csrr	a5,sstatus
ffffffffc02028d6:	8b89                	andi	a5,a5,2
ffffffffc02028d8:	44079063          	bnez	a5,ffffffffc0202d18 <pmm_init+0x5ca>
        page = pmm_manager->alloc_pages(n);
ffffffffc02028dc:	000b3783          	ld	a5,0(s6)
ffffffffc02028e0:	4505                	li	a0,1
ffffffffc02028e2:	6f9c                	ld	a5,24(a5)
ffffffffc02028e4:	9782                	jalr	a5
ffffffffc02028e6:	8a2a                	mv	s4,a0

    struct Page *p1, *p2;
    p1 = alloc_page();
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc02028e8:	00093503          	ld	a0,0(s2)
ffffffffc02028ec:	4681                	li	a3,0
ffffffffc02028ee:	4601                	li	a2,0
ffffffffc02028f0:	85d2                	mv	a1,s4
ffffffffc02028f2:	d67ff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc02028f6:	280511e3          	bnez	a0,ffffffffc0203378 <pmm_init+0xc2a>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc02028fa:	00093503          	ld	a0,0(s2)
ffffffffc02028fe:	4601                	li	a2,0
ffffffffc0202900:	4581                	li	a1,0
ffffffffc0202902:	e20ff0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc0202906:	240509e3          	beqz	a0,ffffffffc0203358 <pmm_init+0xc0a>
    assert(pte2page(*ptep) == p1);
ffffffffc020290a:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V))
ffffffffc020290c:	0017f713          	andi	a4,a5,1
ffffffffc0202910:	58070f63          	beqz	a4,ffffffffc0202eae <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202914:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202916:	078a                	slli	a5,a5,0x2
ffffffffc0202918:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc020291a:	58e7f863          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc020291e:	000bb683          	ld	a3,0(s7)
ffffffffc0202922:	079a                	slli	a5,a5,0x6
ffffffffc0202924:	fe000637          	lui	a2,0xfe000
ffffffffc0202928:	97b2                	add	a5,a5,a2
ffffffffc020292a:	97b6                	add	a5,a5,a3
ffffffffc020292c:	14fa1ae3          	bne	s4,a5,ffffffffc0203280 <pmm_init+0xb32>
    assert(page_ref(p1) == 1);
ffffffffc0202930:	000a2683          	lw	a3,0(s4) # 200000 <_binary_obj___user_exit_out_size+0x1f5e08>
ffffffffc0202934:	4785                	li	a5,1
ffffffffc0202936:	12f695e3          	bne	a3,a5,ffffffffc0203260 <pmm_init+0xb12>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc020293a:	00093503          	ld	a0,0(s2)
ffffffffc020293e:	77fd                	lui	a5,0xfffff
ffffffffc0202940:	6114                	ld	a3,0(a0)
ffffffffc0202942:	068a                	slli	a3,a3,0x2
ffffffffc0202944:	8efd                	and	a3,a3,a5
ffffffffc0202946:	00c6d613          	srli	a2,a3,0xc
ffffffffc020294a:	0ee67fe3          	bgeu	a2,a4,ffffffffc0203248 <pmm_init+0xafa>
ffffffffc020294e:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202952:	96e2                	add	a3,a3,s8
ffffffffc0202954:	0006ba83          	ld	s5,0(a3)
ffffffffc0202958:	0a8a                	slli	s5,s5,0x2
ffffffffc020295a:	00fafab3          	and	s5,s5,a5
ffffffffc020295e:	00cad793          	srli	a5,s5,0xc
ffffffffc0202962:	0ce7f6e3          	bgeu	a5,a4,ffffffffc020322e <pmm_init+0xae0>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202966:	4601                	li	a2,0
ffffffffc0202968:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020296a:	9c56                	add	s8,s8,s5
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc020296c:	db6ff0ef          	jal	ffffffffc0201f22 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202970:	0c21                	addi	s8,s8,8
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc0202972:	05851ee3          	bne	a0,s8,ffffffffc02031ce <pmm_init+0xa80>
ffffffffc0202976:	100027f3          	csrr	a5,sstatus
ffffffffc020297a:	8b89                	andi	a5,a5,2
ffffffffc020297c:	3e079b63          	bnez	a5,ffffffffc0202d72 <pmm_init+0x624>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202980:	000b3783          	ld	a5,0(s6)
ffffffffc0202984:	4505                	li	a0,1
ffffffffc0202986:	6f9c                	ld	a5,24(a5)
ffffffffc0202988:	9782                	jalr	a5
ffffffffc020298a:	8c2a                	mv	s8,a0

    p2 = alloc_page();
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020298c:	00093503          	ld	a0,0(s2)
ffffffffc0202990:	46d1                	li	a3,20
ffffffffc0202992:	6605                	lui	a2,0x1
ffffffffc0202994:	85e2                	mv	a1,s8
ffffffffc0202996:	cc3ff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc020299a:	06051ae3          	bnez	a0,ffffffffc020320e <pmm_init+0xac0>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc020299e:	00093503          	ld	a0,0(s2)
ffffffffc02029a2:	4601                	li	a2,0
ffffffffc02029a4:	6585                	lui	a1,0x1
ffffffffc02029a6:	d7cff0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc02029aa:	040502e3          	beqz	a0,ffffffffc02031ee <pmm_init+0xaa0>
    assert(*ptep & PTE_U);
ffffffffc02029ae:	611c                	ld	a5,0(a0)
ffffffffc02029b0:	0107f713          	andi	a4,a5,16
ffffffffc02029b4:	7e070163          	beqz	a4,ffffffffc0203196 <pmm_init+0xa48>
    assert(*ptep & PTE_W);
ffffffffc02029b8:	8b91                	andi	a5,a5,4
ffffffffc02029ba:	7a078e63          	beqz	a5,ffffffffc0203176 <pmm_init+0xa28>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc02029be:	00093503          	ld	a0,0(s2)
ffffffffc02029c2:	611c                	ld	a5,0(a0)
ffffffffc02029c4:	8bc1                	andi	a5,a5,16
ffffffffc02029c6:	78078863          	beqz	a5,ffffffffc0203156 <pmm_init+0xa08>
    assert(page_ref(p2) == 1);
ffffffffc02029ca:	000c2703          	lw	a4,0(s8)
ffffffffc02029ce:	4785                	li	a5,1
ffffffffc02029d0:	76f71363          	bne	a4,a5,ffffffffc0203136 <pmm_init+0x9e8>

    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc02029d4:	4681                	li	a3,0
ffffffffc02029d6:	6605                	lui	a2,0x1
ffffffffc02029d8:	85d2                	mv	a1,s4
ffffffffc02029da:	c7fff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc02029de:	72051c63          	bnez	a0,ffffffffc0203116 <pmm_init+0x9c8>
    assert(page_ref(p1) == 2);
ffffffffc02029e2:	000a2703          	lw	a4,0(s4)
ffffffffc02029e6:	4789                	li	a5,2
ffffffffc02029e8:	70f71763          	bne	a4,a5,ffffffffc02030f6 <pmm_init+0x9a8>
    assert(page_ref(p2) == 0);
ffffffffc02029ec:	000c2783          	lw	a5,0(s8)
ffffffffc02029f0:	6e079363          	bnez	a5,ffffffffc02030d6 <pmm_init+0x988>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02029f4:	00093503          	ld	a0,0(s2)
ffffffffc02029f8:	4601                	li	a2,0
ffffffffc02029fa:	6585                	lui	a1,0x1
ffffffffc02029fc:	d26ff0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc0202a00:	6a050b63          	beqz	a0,ffffffffc02030b6 <pmm_init+0x968>
    assert(pte2page(*ptep) == p1);
ffffffffc0202a04:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V))
ffffffffc0202a06:	00177793          	andi	a5,a4,1
ffffffffc0202a0a:	4a078263          	beqz	a5,ffffffffc0202eae <pmm_init+0x760>
    if (PPN(pa) >= npage)
ffffffffc0202a0e:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202a10:	00271793          	slli	a5,a4,0x2
ffffffffc0202a14:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a16:	48d7fa63          	bgeu	a5,a3,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a1a:	000bb683          	ld	a3,0(s7)
ffffffffc0202a1e:	fff80ab7          	lui	s5,0xfff80
ffffffffc0202a22:	97d6                	add	a5,a5,s5
ffffffffc0202a24:	079a                	slli	a5,a5,0x6
ffffffffc0202a26:	97b6                	add	a5,a5,a3
ffffffffc0202a28:	66fa1763          	bne	s4,a5,ffffffffc0203096 <pmm_init+0x948>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202a2c:	8b41                	andi	a4,a4,16
ffffffffc0202a2e:	64071463          	bnez	a4,ffffffffc0203076 <pmm_init+0x928>

    page_remove(boot_pgdir_va, 0x0);
ffffffffc0202a32:	00093503          	ld	a0,0(s2)
ffffffffc0202a36:	4581                	li	a1,0
ffffffffc0202a38:	b85ff0ef          	jal	ffffffffc02025bc <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202a3c:	000a2c83          	lw	s9,0(s4)
ffffffffc0202a40:	4785                	li	a5,1
ffffffffc0202a42:	60fc9a63          	bne	s9,a5,ffffffffc0203056 <pmm_init+0x908>
    assert(page_ref(p2) == 0);
ffffffffc0202a46:	000c2783          	lw	a5,0(s8)
ffffffffc0202a4a:	5e079663          	bnez	a5,ffffffffc0203036 <pmm_init+0x8e8>

    page_remove(boot_pgdir_va, PGSIZE);
ffffffffc0202a4e:	00093503          	ld	a0,0(s2)
ffffffffc0202a52:	6585                	lui	a1,0x1
ffffffffc0202a54:	b69ff0ef          	jal	ffffffffc02025bc <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc0202a58:	000a2783          	lw	a5,0(s4)
ffffffffc0202a5c:	52079d63          	bnez	a5,ffffffffc0202f96 <pmm_init+0x848>
    assert(page_ref(p2) == 0);
ffffffffc0202a60:	000c2783          	lw	a5,0(s8)
ffffffffc0202a64:	50079963          	bnez	a5,ffffffffc0202f76 <pmm_init+0x828>

    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202a68:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202a6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202a6e:	000a3783          	ld	a5,0(s4)
ffffffffc0202a72:	078a                	slli	a5,a5,0x2
ffffffffc0202a74:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202a76:	42e7fa63          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202a7a:	000bb503          	ld	a0,0(s7)
ffffffffc0202a7e:	97d6                	add	a5,a5,s5
ffffffffc0202a80:	079a                	slli	a5,a5,0x6
    return page->ref;
ffffffffc0202a82:	00f506b3          	add	a3,a0,a5
ffffffffc0202a86:	4294                	lw	a3,0(a3)
ffffffffc0202a88:	4d969763          	bne	a3,s9,ffffffffc0202f56 <pmm_init+0x808>
    return page - pages + nbase;
ffffffffc0202a8c:	8799                	srai	a5,a5,0x6
ffffffffc0202a8e:	00080637          	lui	a2,0x80
ffffffffc0202a92:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0202a94:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202a98:	4ae7f363          	bgeu	a5,a4,ffffffffc0202f3e <pmm_init+0x7f0>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202a9c:	0009b783          	ld	a5,0(s3)
ffffffffc0202aa0:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc0202aa2:	639c                	ld	a5,0(a5)
ffffffffc0202aa4:	078a                	slli	a5,a5,0x2
ffffffffc0202aa6:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202aa8:	40e7f163          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202aac:	8f91                	sub	a5,a5,a2
ffffffffc0202aae:	079a                	slli	a5,a5,0x6
ffffffffc0202ab0:	953e                	add	a0,a0,a5
ffffffffc0202ab2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ab6:	8b89                	andi	a5,a5,2
ffffffffc0202ab8:	30079863          	bnez	a5,ffffffffc0202dc8 <pmm_init+0x67a>
        pmm_manager->free_pages(base, n);
ffffffffc0202abc:	000b3783          	ld	a5,0(s6)
ffffffffc0202ac0:	4585                	li	a1,1
ffffffffc0202ac2:	739c                	ld	a5,32(a5)
ffffffffc0202ac4:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ac6:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202aca:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202acc:	078a                	slli	a5,a5,0x2
ffffffffc0202ace:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ad0:	3ce7fd63          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ad4:	000bb503          	ld	a0,0(s7)
ffffffffc0202ad8:	fe000737          	lui	a4,0xfe000
ffffffffc0202adc:	079a                	slli	a5,a5,0x6
ffffffffc0202ade:	97ba                	add	a5,a5,a4
ffffffffc0202ae0:	953e                	add	a0,a0,a5
ffffffffc0202ae2:	100027f3          	csrr	a5,sstatus
ffffffffc0202ae6:	8b89                	andi	a5,a5,2
ffffffffc0202ae8:	2c079463          	bnez	a5,ffffffffc0202db0 <pmm_init+0x662>
ffffffffc0202aec:	000b3783          	ld	a5,0(s6)
ffffffffc0202af0:	4585                	li	a1,1
ffffffffc0202af2:	739c                	ld	a5,32(a5)
ffffffffc0202af4:	9782                	jalr	a5
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202af6:	00093783          	ld	a5,0(s2)
ffffffffc0202afa:	0007b023          	sd	zero,0(a5) # fffffffffffff000 <end+0x3fd635d0>
    asm volatile("sfence.vma");
ffffffffc0202afe:	12000073          	sfence.vma
ffffffffc0202b02:	100027f3          	csrr	a5,sstatus
ffffffffc0202b06:	8b89                	andi	a5,a5,2
ffffffffc0202b08:	28079a63          	bnez	a5,ffffffffc0202d9c <pmm_init+0x64e>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b0c:	000b3783          	ld	a5,0(s6)
ffffffffc0202b10:	779c                	ld	a5,40(a5)
ffffffffc0202b12:	9782                	jalr	a5
ffffffffc0202b14:	8a2a                	mv	s4,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202b16:	4d441063          	bne	s0,s4,ffffffffc0202fd6 <pmm_init+0x888>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc0202b1a:	00004517          	auipc	a0,0x4
ffffffffc0202b1e:	f9650513          	addi	a0,a0,-106 # ffffffffc0206ab0 <etext+0x12a8>
ffffffffc0202b22:	e72fd0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0202b26:	100027f3          	csrr	a5,sstatus
ffffffffc0202b2a:	8b89                	andi	a5,a5,2
ffffffffc0202b2c:	24079e63          	bnez	a5,ffffffffc0202d88 <pmm_init+0x63a>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202b30:	000b3783          	ld	a5,0(s6)
ffffffffc0202b34:	779c                	ld	a5,40(a5)
ffffffffc0202b36:	9782                	jalr	a5
ffffffffc0202b38:	8c2a                	mv	s8,a0
    pte_t *ptep;
    int i;

    nr_free_store = nr_free_pages();

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b3a:	609c                	ld	a5,0(s1)
ffffffffc0202b3c:	c0200437          	lui	s0,0xc0200
    {
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b40:	7a7d                	lui	s4,0xfffff
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b42:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b46:	6a85                	lui	s5,0x1
ffffffffc0202b48:	02e47c63          	bgeu	s0,a4,ffffffffc0202b80 <pmm_init+0x432>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b4c:	00c45713          	srli	a4,s0,0xc
ffffffffc0202b50:	30f77063          	bgeu	a4,a5,ffffffffc0202e50 <pmm_init+0x702>
ffffffffc0202b54:	0009b583          	ld	a1,0(s3)
ffffffffc0202b58:	00093503          	ld	a0,0(s2)
ffffffffc0202b5c:	4601                	li	a2,0
ffffffffc0202b5e:	95a2                	add	a1,a1,s0
ffffffffc0202b60:	bc2ff0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc0202b64:	32050363          	beqz	a0,ffffffffc0202e8a <pmm_init+0x73c>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202b68:	611c                	ld	a5,0(a0)
ffffffffc0202b6a:	078a                	slli	a5,a5,0x2
ffffffffc0202b6c:	0147f7b3          	and	a5,a5,s4
ffffffffc0202b70:	2e879d63          	bne	a5,s0,ffffffffc0202e6a <pmm_init+0x71c>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE)
ffffffffc0202b74:	609c                	ld	a5,0(s1)
ffffffffc0202b76:	9456                	add	s0,s0,s5
ffffffffc0202b78:	00c79713          	slli	a4,a5,0xc
ffffffffc0202b7c:	fce468e3          	bltu	s0,a4,ffffffffc0202b4c <pmm_init+0x3fe>
    }

    assert(boot_pgdir_va[0] == 0);
ffffffffc0202b80:	00093783          	ld	a5,0(s2)
ffffffffc0202b84:	639c                	ld	a5,0(a5)
ffffffffc0202b86:	42079863          	bnez	a5,ffffffffc0202fb6 <pmm_init+0x868>
ffffffffc0202b8a:	100027f3          	csrr	a5,sstatus
ffffffffc0202b8e:	8b89                	andi	a5,a5,2
ffffffffc0202b90:	24079863          	bnez	a5,ffffffffc0202de0 <pmm_init+0x692>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202b94:	000b3783          	ld	a5,0(s6)
ffffffffc0202b98:	4505                	li	a0,1
ffffffffc0202b9a:	6f9c                	ld	a5,24(a5)
ffffffffc0202b9c:	9782                	jalr	a5
ffffffffc0202b9e:	842a                	mv	s0,a0

    struct Page *p;
    p = alloc_page();
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202ba0:	00093503          	ld	a0,0(s2)
ffffffffc0202ba4:	4699                	li	a3,6
ffffffffc0202ba6:	10000613          	li	a2,256
ffffffffc0202baa:	85a2                	mv	a1,s0
ffffffffc0202bac:	aadff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc0202bb0:	46051363          	bnez	a0,ffffffffc0203016 <pmm_init+0x8c8>
    assert(page_ref(p) == 1);
ffffffffc0202bb4:	4018                	lw	a4,0(s0)
ffffffffc0202bb6:	4785                	li	a5,1
ffffffffc0202bb8:	42f71f63          	bne	a4,a5,ffffffffc0202ff6 <pmm_init+0x8a8>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202bbc:	00093503          	ld	a0,0(s2)
ffffffffc0202bc0:	6605                	lui	a2,0x1
ffffffffc0202bc2:	10060613          	addi	a2,a2,256 # 1100 <_binary_obj___user_softint_out_size-0x7b08>
ffffffffc0202bc6:	4699                	li	a3,6
ffffffffc0202bc8:	85a2                	mv	a1,s0
ffffffffc0202bca:	a8fff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc0202bce:	72051963          	bnez	a0,ffffffffc0203300 <pmm_init+0xbb2>
    assert(page_ref(p) == 2);
ffffffffc0202bd2:	4018                	lw	a4,0(s0)
ffffffffc0202bd4:	4789                	li	a5,2
ffffffffc0202bd6:	70f71563          	bne	a4,a5,ffffffffc02032e0 <pmm_init+0xb92>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202bda:	00004597          	auipc	a1,0x4
ffffffffc0202bde:	01e58593          	addi	a1,a1,30 # ffffffffc0206bf8 <etext+0x13f0>
ffffffffc0202be2:	10000513          	li	a0,256
ffffffffc0202be6:	379020ef          	jal	ffffffffc020575e <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202bea:	6585                	lui	a1,0x1
ffffffffc0202bec:	10058593          	addi	a1,a1,256 # 1100 <_binary_obj___user_softint_out_size-0x7b08>
ffffffffc0202bf0:	10000513          	li	a0,256
ffffffffc0202bf4:	37d020ef          	jal	ffffffffc0205770 <strcmp>
ffffffffc0202bf8:	6c051463          	bnez	a0,ffffffffc02032c0 <pmm_init+0xb72>
    return page - pages + nbase;
ffffffffc0202bfc:	000bb683          	ld	a3,0(s7)
ffffffffc0202c00:	000807b7          	lui	a5,0x80
    return KADDR(page2pa(page));
ffffffffc0202c04:	6098                	ld	a4,0(s1)
    return page - pages + nbase;
ffffffffc0202c06:	40d406b3          	sub	a3,s0,a3
ffffffffc0202c0a:	8699                	srai	a3,a3,0x6
ffffffffc0202c0c:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0202c0e:	00c69793          	slli	a5,a3,0xc
ffffffffc0202c12:	83b1                	srli	a5,a5,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c14:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202c16:	32e7f463          	bgeu	a5,a4,ffffffffc0202f3e <pmm_init+0x7f0>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c1a:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c1e:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202c22:	97b6                	add	a5,a5,a3
ffffffffc0202c24:	10078023          	sb	zero,256(a5) # 80100 <_binary_obj___user_exit_out_size+0x75f08>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202c28:	303020ef          	jal	ffffffffc020572a <strlen>
ffffffffc0202c2c:	66051a63          	bnez	a0,ffffffffc02032a0 <pmm_init+0xb52>

    pde_t *pd1 = boot_pgdir_va, *pd0 = page2kva(pde2page(boot_pgdir_va[0]));
ffffffffc0202c30:	00093a03          	ld	s4,0(s2)
    if (PPN(pa) >= npage)
ffffffffc0202c34:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c36:	000a3783          	ld	a5,0(s4) # fffffffffffff000 <end+0x3fd635d0>
ffffffffc0202c3a:	078a                	slli	a5,a5,0x2
ffffffffc0202c3c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c3e:	26e7f663          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return page2ppn(page) << PGSHIFT;
ffffffffc0202c42:	00c79693          	slli	a3,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202c46:	2ee7fc63          	bgeu	a5,a4,ffffffffc0202f3e <pmm_init+0x7f0>
ffffffffc0202c4a:	0009b783          	ld	a5,0(s3)
ffffffffc0202c4e:	00f689b3          	add	s3,a3,a5
ffffffffc0202c52:	100027f3          	csrr	a5,sstatus
ffffffffc0202c56:	8b89                	andi	a5,a5,2
ffffffffc0202c58:	1e079163          	bnez	a5,ffffffffc0202e3a <pmm_init+0x6ec>
        pmm_manager->free_pages(base, n);
ffffffffc0202c5c:	000b3783          	ld	a5,0(s6)
ffffffffc0202c60:	8522                	mv	a0,s0
ffffffffc0202c62:	4585                	li	a1,1
ffffffffc0202c64:	739c                	ld	a5,32(a5)
ffffffffc0202c66:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c68:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage)
ffffffffc0202c6c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c6e:	078a                	slli	a5,a5,0x2
ffffffffc0202c70:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202c72:	22e7fc63          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202c76:	000bb503          	ld	a0,0(s7)
ffffffffc0202c7a:	fe000737          	lui	a4,0xfe000
ffffffffc0202c7e:	079a                	slli	a5,a5,0x6
ffffffffc0202c80:	97ba                	add	a5,a5,a4
ffffffffc0202c82:	953e                	add	a0,a0,a5
ffffffffc0202c84:	100027f3          	csrr	a5,sstatus
ffffffffc0202c88:	8b89                	andi	a5,a5,2
ffffffffc0202c8a:	18079c63          	bnez	a5,ffffffffc0202e22 <pmm_init+0x6d4>
ffffffffc0202c8e:	000b3783          	ld	a5,0(s6)
ffffffffc0202c92:	4585                	li	a1,1
ffffffffc0202c94:	739c                	ld	a5,32(a5)
ffffffffc0202c96:	9782                	jalr	a5
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c98:	000a3783          	ld	a5,0(s4)
    if (PPN(pa) >= npage)
ffffffffc0202c9c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202c9e:	078a                	slli	a5,a5,0x2
ffffffffc0202ca0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0202ca2:	20e7f463          	bgeu	a5,a4,ffffffffc0202eaa <pmm_init+0x75c>
    return &pages[PPN(pa) - nbase];
ffffffffc0202ca6:	000bb503          	ld	a0,0(s7)
ffffffffc0202caa:	fe000737          	lui	a4,0xfe000
ffffffffc0202cae:	079a                	slli	a5,a5,0x6
ffffffffc0202cb0:	97ba                	add	a5,a5,a4
ffffffffc0202cb2:	953e                	add	a0,a0,a5
ffffffffc0202cb4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cb8:	8b89                	andi	a5,a5,2
ffffffffc0202cba:	14079863          	bnez	a5,ffffffffc0202e0a <pmm_init+0x6bc>
ffffffffc0202cbe:	000b3783          	ld	a5,0(s6)
ffffffffc0202cc2:	4585                	li	a1,1
ffffffffc0202cc4:	739c                	ld	a5,32(a5)
ffffffffc0202cc6:	9782                	jalr	a5
    free_page(p);
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    boot_pgdir_va[0] = 0;
ffffffffc0202cc8:	00093783          	ld	a5,0(s2)
ffffffffc0202ccc:	0007b023          	sd	zero,0(a5)
    asm volatile("sfence.vma");
ffffffffc0202cd0:	12000073          	sfence.vma
ffffffffc0202cd4:	100027f3          	csrr	a5,sstatus
ffffffffc0202cd8:	8b89                	andi	a5,a5,2
ffffffffc0202cda:	10079e63          	bnez	a5,ffffffffc0202df6 <pmm_init+0x6a8>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202cde:	000b3783          	ld	a5,0(s6)
ffffffffc0202ce2:	779c                	ld	a5,40(a5)
ffffffffc0202ce4:	9782                	jalr	a5
ffffffffc0202ce6:	842a                	mv	s0,a0
    flush_tlb();

    assert(nr_free_store == nr_free_pages());
ffffffffc0202ce8:	1e8c1b63          	bne	s8,s0,ffffffffc0202ede <pmm_init+0x790>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202cec:	00004517          	auipc	a0,0x4
ffffffffc0202cf0:	f8450513          	addi	a0,a0,-124 # ffffffffc0206c70 <etext+0x1468>
ffffffffc0202cf4:	ca0fd0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0202cf8:	7406                	ld	s0,96(sp)
ffffffffc0202cfa:	70a6                	ld	ra,104(sp)
ffffffffc0202cfc:	64e6                	ld	s1,88(sp)
ffffffffc0202cfe:	6946                	ld	s2,80(sp)
ffffffffc0202d00:	69a6                	ld	s3,72(sp)
ffffffffc0202d02:	6a06                	ld	s4,64(sp)
ffffffffc0202d04:	7ae2                	ld	s5,56(sp)
ffffffffc0202d06:	7b42                	ld	s6,48(sp)
ffffffffc0202d08:	7ba2                	ld	s7,40(sp)
ffffffffc0202d0a:	7c02                	ld	s8,32(sp)
ffffffffc0202d0c:	6ce2                	ld	s9,24(sp)
ffffffffc0202d0e:	6165                	addi	sp,sp,112
    kmalloc_init();
ffffffffc0202d10:	f85fe06f          	j	ffffffffc0201c94 <kmalloc_init>
    if (maxpa > KERNTOP)
ffffffffc0202d14:	853e                	mv	a0,a5
ffffffffc0202d16:	b4e1                	j	ffffffffc02027de <pmm_init+0x90>
        intr_disable();
ffffffffc0202d18:	bedfd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d1c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d20:	4505                	li	a0,1
ffffffffc0202d22:	6f9c                	ld	a5,24(a5)
ffffffffc0202d24:	9782                	jalr	a5
ffffffffc0202d26:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202d28:	bd7fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d2c:	be75                	j	ffffffffc02028e8 <pmm_init+0x19a>
        intr_disable();
ffffffffc0202d2e:	bd7fd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d32:	000b3783          	ld	a5,0(s6)
ffffffffc0202d36:	779c                	ld	a5,40(a5)
ffffffffc0202d38:	9782                	jalr	a5
ffffffffc0202d3a:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202d3c:	bc3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d40:	b6ad                	j	ffffffffc02028aa <pmm_init+0x15c>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0202d42:	6705                	lui	a4,0x1
ffffffffc0202d44:	177d                	addi	a4,a4,-1 # fff <_binary_obj___user_softint_out_size-0x7c09>
ffffffffc0202d46:	96ba                	add	a3,a3,a4
ffffffffc0202d48:	8ff5                	and	a5,a5,a3
    if (PPN(pa) >= npage)
ffffffffc0202d4a:	00c7d713          	srli	a4,a5,0xc
ffffffffc0202d4e:	14a77e63          	bgeu	a4,a0,ffffffffc0202eaa <pmm_init+0x75c>
    pmm_manager->init_memmap(base, n);
ffffffffc0202d52:	000b3683          	ld	a3,0(s6)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202d56:	8c1d                	sub	s0,s0,a5
    return &pages[PPN(pa) - nbase];
ffffffffc0202d58:	071a                	slli	a4,a4,0x6
ffffffffc0202d5a:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202d5e:	973e                	add	a4,a4,a5
    pmm_manager->init_memmap(base, n);
ffffffffc0202d60:	6a9c                	ld	a5,16(a3)
ffffffffc0202d62:	00c45593          	srli	a1,s0,0xc
ffffffffc0202d66:	00e60533          	add	a0,a2,a4
ffffffffc0202d6a:	9782                	jalr	a5
    cprintf("vapaofset is %llu\n", va_pa_offset);
ffffffffc0202d6c:	0009b583          	ld	a1,0(s3)
}
ffffffffc0202d70:	bcf1                	j	ffffffffc020284c <pmm_init+0xfe>
        intr_disable();
ffffffffc0202d72:	b93fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202d76:	000b3783          	ld	a5,0(s6)
ffffffffc0202d7a:	4505                	li	a0,1
ffffffffc0202d7c:	6f9c                	ld	a5,24(a5)
ffffffffc0202d7e:	9782                	jalr	a5
ffffffffc0202d80:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d82:	b7dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d86:	b119                	j	ffffffffc020298c <pmm_init+0x23e>
        intr_disable();
ffffffffc0202d88:	b7dfd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202d8c:	000b3783          	ld	a5,0(s6)
ffffffffc0202d90:	779c                	ld	a5,40(a5)
ffffffffc0202d92:	9782                	jalr	a5
ffffffffc0202d94:	8c2a                	mv	s8,a0
        intr_enable();
ffffffffc0202d96:	b69fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202d9a:	b345                	j	ffffffffc0202b3a <pmm_init+0x3ec>
        intr_disable();
ffffffffc0202d9c:	b69fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202da0:	000b3783          	ld	a5,0(s6)
ffffffffc0202da4:	779c                	ld	a5,40(a5)
ffffffffc0202da6:	9782                	jalr	a5
ffffffffc0202da8:	8a2a                	mv	s4,a0
        intr_enable();
ffffffffc0202daa:	b55fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dae:	b3a5                	j	ffffffffc0202b16 <pmm_init+0x3c8>
ffffffffc0202db0:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202db2:	b53fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202db6:	000b3783          	ld	a5,0(s6)
ffffffffc0202dba:	6522                	ld	a0,8(sp)
ffffffffc0202dbc:	4585                	li	a1,1
ffffffffc0202dbe:	739c                	ld	a5,32(a5)
ffffffffc0202dc0:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dc2:	b3dfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dc6:	bb05                	j	ffffffffc0202af6 <pmm_init+0x3a8>
ffffffffc0202dc8:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202dca:	b3bfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202dce:	000b3783          	ld	a5,0(s6)
ffffffffc0202dd2:	6522                	ld	a0,8(sp)
ffffffffc0202dd4:	4585                	li	a1,1
ffffffffc0202dd6:	739c                	ld	a5,32(a5)
ffffffffc0202dd8:	9782                	jalr	a5
        intr_enable();
ffffffffc0202dda:	b25fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202dde:	b1e5                	j	ffffffffc0202ac6 <pmm_init+0x378>
        intr_disable();
ffffffffc0202de0:	b25fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0202de4:	000b3783          	ld	a5,0(s6)
ffffffffc0202de8:	4505                	li	a0,1
ffffffffc0202dea:	6f9c                	ld	a5,24(a5)
ffffffffc0202dec:	9782                	jalr	a5
ffffffffc0202dee:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202df0:	b0ffd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202df4:	b375                	j	ffffffffc0202ba0 <pmm_init+0x452>
        intr_disable();
ffffffffc0202df6:	b0ffd0ef          	jal	ffffffffc0200904 <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0202dfa:	000b3783          	ld	a5,0(s6)
ffffffffc0202dfe:	779c                	ld	a5,40(a5)
ffffffffc0202e00:	9782                	jalr	a5
ffffffffc0202e02:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0202e04:	afbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e08:	b5c5                	j	ffffffffc0202ce8 <pmm_init+0x59a>
ffffffffc0202e0a:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e0c:	af9fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0202e10:	000b3783          	ld	a5,0(s6)
ffffffffc0202e14:	6522                	ld	a0,8(sp)
ffffffffc0202e16:	4585                	li	a1,1
ffffffffc0202e18:	739c                	ld	a5,32(a5)
ffffffffc0202e1a:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e1c:	ae3fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e20:	b565                	j	ffffffffc0202cc8 <pmm_init+0x57a>
ffffffffc0202e22:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0202e24:	ae1fd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e28:	000b3783          	ld	a5,0(s6)
ffffffffc0202e2c:	6522                	ld	a0,8(sp)
ffffffffc0202e2e:	4585                	li	a1,1
ffffffffc0202e30:	739c                	ld	a5,32(a5)
ffffffffc0202e32:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e34:	acbfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e38:	b585                	j	ffffffffc0202c98 <pmm_init+0x54a>
        intr_disable();
ffffffffc0202e3a:	acbfd0ef          	jal	ffffffffc0200904 <intr_disable>
ffffffffc0202e3e:	000b3783          	ld	a5,0(s6)
ffffffffc0202e42:	8522                	mv	a0,s0
ffffffffc0202e44:	4585                	li	a1,1
ffffffffc0202e46:	739c                	ld	a5,32(a5)
ffffffffc0202e48:	9782                	jalr	a5
        intr_enable();
ffffffffc0202e4a:	ab5fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0202e4e:	bd29                	j	ffffffffc0202c68 <pmm_init+0x51a>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e50:	86a2                	mv	a3,s0
ffffffffc0202e52:	00003617          	auipc	a2,0x3
ffffffffc0202e56:	73660613          	addi	a2,a2,1846 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202e5a:	25300593          	li	a1,595
ffffffffc0202e5e:	00004517          	auipc	a0,0x4
ffffffffc0202e62:	81a50513          	addi	a0,a0,-2022 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202e66:	de0fd0ef          	jal	ffffffffc0200446 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202e6a:	00004697          	auipc	a3,0x4
ffffffffc0202e6e:	ca668693          	addi	a3,a3,-858 # ffffffffc0206b10 <etext+0x1308>
ffffffffc0202e72:	00003617          	auipc	a2,0x3
ffffffffc0202e76:	36660613          	addi	a2,a2,870 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202e7a:	25400593          	li	a1,596
ffffffffc0202e7e:	00003517          	auipc	a0,0x3
ffffffffc0202e82:	7fa50513          	addi	a0,a0,2042 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202e86:	dc0fd0ef          	jal	ffffffffc0200446 <__panic>
        assert((ptep = get_pte(boot_pgdir_va, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202e8a:	00004697          	auipc	a3,0x4
ffffffffc0202e8e:	c4668693          	addi	a3,a3,-954 # ffffffffc0206ad0 <etext+0x12c8>
ffffffffc0202e92:	00003617          	auipc	a2,0x3
ffffffffc0202e96:	34660613          	addi	a2,a2,838 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202e9a:	25300593          	li	a1,595
ffffffffc0202e9e:	00003517          	auipc	a0,0x3
ffffffffc0202ea2:	7da50513          	addi	a0,a0,2010 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202ea6:	da0fd0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0202eaa:	fb5fe0ef          	jal	ffffffffc0201e5e <pa2page.part.0>
        panic("pte2page called with invalid pte");
ffffffffc0202eae:	00004617          	auipc	a2,0x4
ffffffffc0202eb2:	9c260613          	addi	a2,a2,-1598 # ffffffffc0206870 <etext+0x1068>
ffffffffc0202eb6:	07f00593          	li	a1,127
ffffffffc0202eba:	00003517          	auipc	a0,0x3
ffffffffc0202ebe:	6f650513          	addi	a0,a0,1782 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0202ec2:	d84fd0ef          	jal	ffffffffc0200446 <__panic>
        panic("DTB memory info not available");
ffffffffc0202ec6:	00004617          	auipc	a2,0x4
ffffffffc0202eca:	82260613          	addi	a2,a2,-2014 # ffffffffc02066e8 <etext+0xee0>
ffffffffc0202ece:	06500593          	li	a1,101
ffffffffc0202ed2:	00003517          	auipc	a0,0x3
ffffffffc0202ed6:	7a650513          	addi	a0,a0,1958 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202eda:	d6cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202ede:	00004697          	auipc	a3,0x4
ffffffffc0202ee2:	baa68693          	addi	a3,a3,-1110 # ffffffffc0206a88 <etext+0x1280>
ffffffffc0202ee6:	00003617          	auipc	a2,0x3
ffffffffc0202eea:	2f260613          	addi	a2,a2,754 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202eee:	26e00593          	li	a1,622
ffffffffc0202ef2:	00003517          	auipc	a0,0x3
ffffffffc0202ef6:	78650513          	addi	a0,a0,1926 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202efa:	d4cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va != NULL && (uint32_t)PGOFF(boot_pgdir_va) == 0);
ffffffffc0202efe:	00004697          	auipc	a3,0x4
ffffffffc0202f02:	8a268693          	addi	a3,a3,-1886 # ffffffffc02067a0 <etext+0xf98>
ffffffffc0202f06:	00003617          	auipc	a2,0x3
ffffffffc0202f0a:	2d260613          	addi	a2,a2,722 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202f0e:	21500593          	li	a1,533
ffffffffc0202f12:	00003517          	auipc	a0,0x3
ffffffffc0202f16:	76650513          	addi	a0,a0,1894 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202f1a:	d2cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0202f1e:	00004697          	auipc	a3,0x4
ffffffffc0202f22:	86268693          	addi	a3,a3,-1950 # ffffffffc0206780 <etext+0xf78>
ffffffffc0202f26:	00003617          	auipc	a2,0x3
ffffffffc0202f2a:	2b260613          	addi	a2,a2,690 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202f2e:	21400593          	li	a1,532
ffffffffc0202f32:	00003517          	auipc	a0,0x3
ffffffffc0202f36:	74650513          	addi	a0,a0,1862 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202f3a:	d0cfd0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202f3e:	00003617          	auipc	a2,0x3
ffffffffc0202f42:	64a60613          	addi	a2,a2,1610 # ffffffffc0206588 <etext+0xd80>
ffffffffc0202f46:	07100593          	li	a1,113
ffffffffc0202f4a:	00003517          	auipc	a0,0x3
ffffffffc0202f4e:	66650513          	addi	a0,a0,1638 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0202f52:	cf4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(pde2page(boot_pgdir_va[0])) == 1);
ffffffffc0202f56:	00004697          	auipc	a3,0x4
ffffffffc0202f5a:	b0268693          	addi	a3,a3,-1278 # ffffffffc0206a58 <etext+0x1250>
ffffffffc0202f5e:	00003617          	auipc	a2,0x3
ffffffffc0202f62:	27a60613          	addi	a2,a2,634 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202f66:	23c00593          	li	a1,572
ffffffffc0202f6a:	00003517          	auipc	a0,0x3
ffffffffc0202f6e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202f72:	cd4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202f76:	00004697          	auipc	a3,0x4
ffffffffc0202f7a:	a9a68693          	addi	a3,a3,-1382 # ffffffffc0206a10 <etext+0x1208>
ffffffffc0202f7e:	00003617          	auipc	a2,0x3
ffffffffc0202f82:	25a60613          	addi	a2,a2,602 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202f86:	23a00593          	li	a1,570
ffffffffc0202f8a:	00003517          	auipc	a0,0x3
ffffffffc0202f8e:	6ee50513          	addi	a0,a0,1774 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202f92:	cb4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202f96:	00004697          	auipc	a3,0x4
ffffffffc0202f9a:	aaa68693          	addi	a3,a3,-1366 # ffffffffc0206a40 <etext+0x1238>
ffffffffc0202f9e:	00003617          	auipc	a2,0x3
ffffffffc0202fa2:	23a60613          	addi	a2,a2,570 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202fa6:	23900593          	li	a1,569
ffffffffc0202faa:	00003517          	auipc	a0,0x3
ffffffffc0202fae:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202fb2:	c94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] == 0);
ffffffffc0202fb6:	00004697          	auipc	a3,0x4
ffffffffc0202fba:	b7268693          	addi	a3,a3,-1166 # ffffffffc0206b28 <etext+0x1320>
ffffffffc0202fbe:	00003617          	auipc	a2,0x3
ffffffffc0202fc2:	21a60613          	addi	a2,a2,538 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202fc6:	25700593          	li	a1,599
ffffffffc0202fca:	00003517          	auipc	a0,0x3
ffffffffc0202fce:	6ae50513          	addi	a0,a0,1710 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202fd2:	c74fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_free_store == nr_free_pages());
ffffffffc0202fd6:	00004697          	auipc	a3,0x4
ffffffffc0202fda:	ab268693          	addi	a3,a3,-1358 # ffffffffc0206a88 <etext+0x1280>
ffffffffc0202fde:	00003617          	auipc	a2,0x3
ffffffffc0202fe2:	1fa60613          	addi	a2,a2,506 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0202fe6:	24400593          	li	a1,580
ffffffffc0202fea:	00003517          	auipc	a0,0x3
ffffffffc0202fee:	68e50513          	addi	a0,a0,1678 # ffffffffc0206678 <etext+0xe70>
ffffffffc0202ff2:	c54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202ff6:	00004697          	auipc	a3,0x4
ffffffffc0202ffa:	b8a68693          	addi	a3,a3,-1142 # ffffffffc0206b80 <etext+0x1378>
ffffffffc0202ffe:	00003617          	auipc	a2,0x3
ffffffffc0203002:	1da60613          	addi	a2,a2,474 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203006:	25c00593          	li	a1,604
ffffffffc020300a:	00003517          	auipc	a0,0x3
ffffffffc020300e:	66e50513          	addi	a0,a0,1646 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203012:	c34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0203016:	00004697          	auipc	a3,0x4
ffffffffc020301a:	b2a68693          	addi	a3,a3,-1238 # ffffffffc0206b40 <etext+0x1338>
ffffffffc020301e:	00003617          	auipc	a2,0x3
ffffffffc0203022:	1ba60613          	addi	a2,a2,442 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203026:	25b00593          	li	a1,603
ffffffffc020302a:	00003517          	auipc	a0,0x3
ffffffffc020302e:	64e50513          	addi	a0,a0,1614 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203032:	c14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0203036:	00004697          	auipc	a3,0x4
ffffffffc020303a:	9da68693          	addi	a3,a3,-1574 # ffffffffc0206a10 <etext+0x1208>
ffffffffc020303e:	00003617          	auipc	a2,0x3
ffffffffc0203042:	19a60613          	addi	a2,a2,410 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203046:	23600593          	li	a1,566
ffffffffc020304a:	00003517          	auipc	a0,0x3
ffffffffc020304e:	62e50513          	addi	a0,a0,1582 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203052:	bf4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203056:	00004697          	auipc	a3,0x4
ffffffffc020305a:	85a68693          	addi	a3,a3,-1958 # ffffffffc02068b0 <etext+0x10a8>
ffffffffc020305e:	00003617          	auipc	a2,0x3
ffffffffc0203062:	17a60613          	addi	a2,a2,378 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203066:	23500593          	li	a1,565
ffffffffc020306a:	00003517          	auipc	a0,0x3
ffffffffc020306e:	60e50513          	addi	a0,a0,1550 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203072:	bd4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203076:	00004697          	auipc	a3,0x4
ffffffffc020307a:	9b268693          	addi	a3,a3,-1614 # ffffffffc0206a28 <etext+0x1220>
ffffffffc020307e:	00003617          	auipc	a2,0x3
ffffffffc0203082:	15a60613          	addi	a2,a2,346 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203086:	23200593          	li	a1,562
ffffffffc020308a:	00003517          	auipc	a0,0x3
ffffffffc020308e:	5ee50513          	addi	a0,a0,1518 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203092:	bb4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203096:	00004697          	auipc	a3,0x4
ffffffffc020309a:	80268693          	addi	a3,a3,-2046 # ffffffffc0206898 <etext+0x1090>
ffffffffc020309e:	00003617          	auipc	a2,0x3
ffffffffc02030a2:	13a60613          	addi	a2,a2,314 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02030a6:	23100593          	li	a1,561
ffffffffc02030aa:	00003517          	auipc	a0,0x3
ffffffffc02030ae:	5ce50513          	addi	a0,a0,1486 # ffffffffc0206678 <etext+0xe70>
ffffffffc02030b2:	b94fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02030b6:	00004697          	auipc	a3,0x4
ffffffffc02030ba:	88268693          	addi	a3,a3,-1918 # ffffffffc0206938 <etext+0x1130>
ffffffffc02030be:	00003617          	auipc	a2,0x3
ffffffffc02030c2:	11a60613          	addi	a2,a2,282 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02030c6:	23000593          	li	a1,560
ffffffffc02030ca:	00003517          	auipc	a0,0x3
ffffffffc02030ce:	5ae50513          	addi	a0,a0,1454 # ffffffffc0206678 <etext+0xe70>
ffffffffc02030d2:	b74fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc02030d6:	00004697          	auipc	a3,0x4
ffffffffc02030da:	93a68693          	addi	a3,a3,-1734 # ffffffffc0206a10 <etext+0x1208>
ffffffffc02030de:	00003617          	auipc	a2,0x3
ffffffffc02030e2:	0fa60613          	addi	a2,a2,250 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02030e6:	22f00593          	li	a1,559
ffffffffc02030ea:	00003517          	auipc	a0,0x3
ffffffffc02030ee:	58e50513          	addi	a0,a0,1422 # ffffffffc0206678 <etext+0xe70>
ffffffffc02030f2:	b54fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc02030f6:	00004697          	auipc	a3,0x4
ffffffffc02030fa:	90268693          	addi	a3,a3,-1790 # ffffffffc02069f8 <etext+0x11f0>
ffffffffc02030fe:	00003617          	auipc	a2,0x3
ffffffffc0203102:	0da60613          	addi	a2,a2,218 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203106:	22e00593          	li	a1,558
ffffffffc020310a:	00003517          	auipc	a0,0x3
ffffffffc020310e:	56e50513          	addi	a0,a0,1390 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203112:	b34fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, PGSIZE, 0) == 0);
ffffffffc0203116:	00004697          	auipc	a3,0x4
ffffffffc020311a:	8b268693          	addi	a3,a3,-1870 # ffffffffc02069c8 <etext+0x11c0>
ffffffffc020311e:	00003617          	auipc	a2,0x3
ffffffffc0203122:	0ba60613          	addi	a2,a2,186 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203126:	22d00593          	li	a1,557
ffffffffc020312a:	00003517          	auipc	a0,0x3
ffffffffc020312e:	54e50513          	addi	a0,a0,1358 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203132:	b14fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0203136:	00004697          	auipc	a3,0x4
ffffffffc020313a:	87a68693          	addi	a3,a3,-1926 # ffffffffc02069b0 <etext+0x11a8>
ffffffffc020313e:	00003617          	auipc	a2,0x3
ffffffffc0203142:	09a60613          	addi	a2,a2,154 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203146:	22b00593          	li	a1,555
ffffffffc020314a:	00003517          	auipc	a0,0x3
ffffffffc020314e:	52e50513          	addi	a0,a0,1326 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203152:	af4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(boot_pgdir_va[0] & PTE_U);
ffffffffc0203156:	00004697          	auipc	a3,0x4
ffffffffc020315a:	83a68693          	addi	a3,a3,-1990 # ffffffffc0206990 <etext+0x1188>
ffffffffc020315e:	00003617          	auipc	a2,0x3
ffffffffc0203162:	07a60613          	addi	a2,a2,122 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203166:	22a00593          	li	a1,554
ffffffffc020316a:	00003517          	auipc	a0,0x3
ffffffffc020316e:	50e50513          	addi	a0,a0,1294 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203172:	ad4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0203176:	00004697          	auipc	a3,0x4
ffffffffc020317a:	80a68693          	addi	a3,a3,-2038 # ffffffffc0206980 <etext+0x1178>
ffffffffc020317e:	00003617          	auipc	a2,0x3
ffffffffc0203182:	05a60613          	addi	a2,a2,90 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203186:	22900593          	li	a1,553
ffffffffc020318a:	00003517          	auipc	a0,0x3
ffffffffc020318e:	4ee50513          	addi	a0,a0,1262 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203192:	ab4fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0203196:	00003697          	auipc	a3,0x3
ffffffffc020319a:	7da68693          	addi	a3,a3,2010 # ffffffffc0206970 <etext+0x1168>
ffffffffc020319e:	00003617          	auipc	a2,0x3
ffffffffc02031a2:	03a60613          	addi	a2,a2,58 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02031a6:	22800593          	li	a1,552
ffffffffc02031aa:	00003517          	auipc	a0,0x3
ffffffffc02031ae:	4ce50513          	addi	a0,a0,1230 # ffffffffc0206678 <etext+0xe70>
ffffffffc02031b2:	a94fd0ef          	jal	ffffffffc0200446 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02031b6:	00003617          	auipc	a2,0x3
ffffffffc02031ba:	47a60613          	addi	a2,a2,1146 # ffffffffc0206630 <etext+0xe28>
ffffffffc02031be:	08100593          	li	a1,129
ffffffffc02031c2:	00003517          	auipc	a0,0x3
ffffffffc02031c6:	4b650513          	addi	a0,a0,1206 # ffffffffc0206678 <etext+0xe70>
ffffffffc02031ca:	a7cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_pte(boot_pgdir_va, PGSIZE, 0) == ptep);
ffffffffc02031ce:	00003697          	auipc	a3,0x3
ffffffffc02031d2:	6fa68693          	addi	a3,a3,1786 # ffffffffc02068c8 <etext+0x10c0>
ffffffffc02031d6:	00003617          	auipc	a2,0x3
ffffffffc02031da:	00260613          	addi	a2,a2,2 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02031de:	22300593          	li	a1,547
ffffffffc02031e2:	00003517          	auipc	a0,0x3
ffffffffc02031e6:	49650513          	addi	a0,a0,1174 # ffffffffc0206678 <etext+0xe70>
ffffffffc02031ea:	a5cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, PGSIZE, 0)) != NULL);
ffffffffc02031ee:	00003697          	auipc	a3,0x3
ffffffffc02031f2:	74a68693          	addi	a3,a3,1866 # ffffffffc0206938 <etext+0x1130>
ffffffffc02031f6:	00003617          	auipc	a2,0x3
ffffffffc02031fa:	fe260613          	addi	a2,a2,-30 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02031fe:	22700593          	li	a1,551
ffffffffc0203202:	00003517          	auipc	a0,0x3
ffffffffc0203206:	47650513          	addi	a0,a0,1142 # ffffffffc0206678 <etext+0xe70>
ffffffffc020320a:	a3cfd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020320e:	00003697          	auipc	a3,0x3
ffffffffc0203212:	6ea68693          	addi	a3,a3,1770 # ffffffffc02068f8 <etext+0x10f0>
ffffffffc0203216:	00003617          	auipc	a2,0x3
ffffffffc020321a:	fc260613          	addi	a2,a2,-62 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020321e:	22600593          	li	a1,550
ffffffffc0203222:	00003517          	auipc	a0,0x3
ffffffffc0203226:	45650513          	addi	a0,a0,1110 # ffffffffc0206678 <etext+0xe70>
ffffffffc020322a:	a1cfd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020322e:	86d6                	mv	a3,s5
ffffffffc0203230:	00003617          	auipc	a2,0x3
ffffffffc0203234:	35860613          	addi	a2,a2,856 # ffffffffc0206588 <etext+0xd80>
ffffffffc0203238:	22200593          	li	a1,546
ffffffffc020323c:	00003517          	auipc	a0,0x3
ffffffffc0203240:	43c50513          	addi	a0,a0,1084 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203244:	a02fd0ef          	jal	ffffffffc0200446 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir_va[0]));
ffffffffc0203248:	00003617          	auipc	a2,0x3
ffffffffc020324c:	34060613          	addi	a2,a2,832 # ffffffffc0206588 <etext+0xd80>
ffffffffc0203250:	22100593          	li	a1,545
ffffffffc0203254:	00003517          	auipc	a0,0x3
ffffffffc0203258:	42450513          	addi	a0,a0,1060 # ffffffffc0206678 <etext+0xe70>
ffffffffc020325c:	9eafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0203260:	00003697          	auipc	a3,0x3
ffffffffc0203264:	65068693          	addi	a3,a3,1616 # ffffffffc02068b0 <etext+0x10a8>
ffffffffc0203268:	00003617          	auipc	a2,0x3
ffffffffc020326c:	f7060613          	addi	a2,a2,-144 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203270:	21f00593          	li	a1,543
ffffffffc0203274:	00003517          	auipc	a0,0x3
ffffffffc0203278:	40450513          	addi	a0,a0,1028 # ffffffffc0206678 <etext+0xe70>
ffffffffc020327c:	9cafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0203280:	00003697          	auipc	a3,0x3
ffffffffc0203284:	61868693          	addi	a3,a3,1560 # ffffffffc0206898 <etext+0x1090>
ffffffffc0203288:	00003617          	auipc	a2,0x3
ffffffffc020328c:	f5060613          	addi	a2,a2,-176 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203290:	21e00593          	li	a1,542
ffffffffc0203294:	00003517          	auipc	a0,0x3
ffffffffc0203298:	3e450513          	addi	a0,a0,996 # ffffffffc0206678 <etext+0xe70>
ffffffffc020329c:	9aafd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc02032a0:	00004697          	auipc	a3,0x4
ffffffffc02032a4:	9a868693          	addi	a3,a3,-1624 # ffffffffc0206c48 <etext+0x1440>
ffffffffc02032a8:	00003617          	auipc	a2,0x3
ffffffffc02032ac:	f3060613          	addi	a2,a2,-208 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02032b0:	26500593          	li	a1,613
ffffffffc02032b4:	00003517          	auipc	a0,0x3
ffffffffc02032b8:	3c450513          	addi	a0,a0,964 # ffffffffc0206678 <etext+0xe70>
ffffffffc02032bc:	98afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc02032c0:	00004697          	auipc	a3,0x4
ffffffffc02032c4:	95068693          	addi	a3,a3,-1712 # ffffffffc0206c10 <etext+0x1408>
ffffffffc02032c8:	00003617          	auipc	a2,0x3
ffffffffc02032cc:	f1060613          	addi	a2,a2,-240 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02032d0:	26200593          	li	a1,610
ffffffffc02032d4:	00003517          	auipc	a0,0x3
ffffffffc02032d8:	3a450513          	addi	a0,a0,932 # ffffffffc0206678 <etext+0xe70>
ffffffffc02032dc:	96afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_ref(p) == 2);
ffffffffc02032e0:	00004697          	auipc	a3,0x4
ffffffffc02032e4:	90068693          	addi	a3,a3,-1792 # ffffffffc0206be0 <etext+0x13d8>
ffffffffc02032e8:	00003617          	auipc	a2,0x3
ffffffffc02032ec:	ef060613          	addi	a2,a2,-272 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02032f0:	25e00593          	li	a1,606
ffffffffc02032f4:	00003517          	auipc	a0,0x3
ffffffffc02032f8:	38450513          	addi	a0,a0,900 # ffffffffc0206678 <etext+0xe70>
ffffffffc02032fc:	94afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0203300:	00004697          	auipc	a3,0x4
ffffffffc0203304:	89868693          	addi	a3,a3,-1896 # ffffffffc0206b98 <etext+0x1390>
ffffffffc0203308:	00003617          	auipc	a2,0x3
ffffffffc020330c:	ed060613          	addi	a2,a2,-304 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203310:	25d00593          	li	a1,605
ffffffffc0203314:	00003517          	auipc	a0,0x3
ffffffffc0203318:	36450513          	addi	a0,a0,868 # ffffffffc0206678 <etext+0xe70>
ffffffffc020331c:	92afd0ef          	jal	ffffffffc0200446 <__panic>
    assert(get_page(boot_pgdir_va, 0x0, NULL) == NULL);
ffffffffc0203320:	00003697          	auipc	a3,0x3
ffffffffc0203324:	4c068693          	addi	a3,a3,1216 # ffffffffc02067e0 <etext+0xfd8>
ffffffffc0203328:	00003617          	auipc	a2,0x3
ffffffffc020332c:	eb060613          	addi	a2,a2,-336 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203330:	21600593          	li	a1,534
ffffffffc0203334:	00003517          	auipc	a0,0x3
ffffffffc0203338:	34450513          	addi	a0,a0,836 # ffffffffc0206678 <etext+0xe70>
ffffffffc020333c:	90afd0ef          	jal	ffffffffc0200446 <__panic>
    boot_pgdir_pa = PADDR(boot_pgdir_va);
ffffffffc0203340:	00003617          	auipc	a2,0x3
ffffffffc0203344:	2f060613          	addi	a2,a2,752 # ffffffffc0206630 <etext+0xe28>
ffffffffc0203348:	0c900593          	li	a1,201
ffffffffc020334c:	00003517          	auipc	a0,0x3
ffffffffc0203350:	32c50513          	addi	a0,a0,812 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203354:	8f2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert((ptep = get_pte(boot_pgdir_va, 0x0, 0)) != NULL);
ffffffffc0203358:	00003697          	auipc	a3,0x3
ffffffffc020335c:	4e868693          	addi	a3,a3,1256 # ffffffffc0206840 <etext+0x1038>
ffffffffc0203360:	00003617          	auipc	a2,0x3
ffffffffc0203364:	e7860613          	addi	a2,a2,-392 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203368:	21d00593          	li	a1,541
ffffffffc020336c:	00003517          	auipc	a0,0x3
ffffffffc0203370:	30c50513          	addi	a0,a0,780 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203374:	8d2fd0ef          	jal	ffffffffc0200446 <__panic>
    assert(page_insert(boot_pgdir_va, p1, 0x0, 0) == 0);
ffffffffc0203378:	00003697          	auipc	a3,0x3
ffffffffc020337c:	49868693          	addi	a3,a3,1176 # ffffffffc0206810 <etext+0x1008>
ffffffffc0203380:	00003617          	auipc	a2,0x3
ffffffffc0203384:	e5860613          	addi	a2,a2,-424 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203388:	21a00593          	li	a1,538
ffffffffc020338c:	00003517          	auipc	a0,0x3
ffffffffc0203390:	2ec50513          	addi	a0,a0,748 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203394:	8b2fd0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203398 <copy_range>:
{
ffffffffc0203398:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc020339a:	00d667b3          	or	a5,a2,a3
{
ffffffffc020339e:	f486                	sd	ra,104(sp)
ffffffffc02033a0:	f0a2                	sd	s0,96(sp)
ffffffffc02033a2:	eca6                	sd	s1,88(sp)
ffffffffc02033a4:	e8ca                	sd	s2,80(sp)
ffffffffc02033a6:	e4ce                	sd	s3,72(sp)
ffffffffc02033a8:	e0d2                	sd	s4,64(sp)
ffffffffc02033aa:	fc56                	sd	s5,56(sp)
ffffffffc02033ac:	f85a                	sd	s6,48(sp)
ffffffffc02033ae:	f45e                	sd	s7,40(sp)
ffffffffc02033b0:	f062                	sd	s8,32(sp)
ffffffffc02033b2:	ec66                	sd	s9,24(sp)
ffffffffc02033b4:	e86a                	sd	s10,16(sp)
ffffffffc02033b6:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02033b8:	03479713          	slli	a4,a5,0x34
ffffffffc02033bc:	20071f63          	bnez	a4,ffffffffc02035da <copy_range+0x242>
    assert(USER_ACCESS(start, end));
ffffffffc02033c0:	002007b7          	lui	a5,0x200
ffffffffc02033c4:	00d63733          	sltu	a4,a2,a3
ffffffffc02033c8:	00f637b3          	sltu	a5,a2,a5
ffffffffc02033cc:	00173713          	seqz	a4,a4
ffffffffc02033d0:	8fd9                	or	a5,a5,a4
ffffffffc02033d2:	8432                	mv	s0,a2
ffffffffc02033d4:	8936                	mv	s2,a3
ffffffffc02033d6:	1e079263          	bnez	a5,ffffffffc02035ba <copy_range+0x222>
ffffffffc02033da:	4785                	li	a5,1
ffffffffc02033dc:	07fe                	slli	a5,a5,0x1f
ffffffffc02033de:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e09>
ffffffffc02033e0:	1cf6fd63          	bgeu	a3,a5,ffffffffc02035ba <copy_range+0x222>
ffffffffc02033e4:	5b7d                	li	s6,-1
ffffffffc02033e6:	8baa                	mv	s7,a0
ffffffffc02033e8:	8a2e                	mv	s4,a1
ffffffffc02033ea:	6a85                	lui	s5,0x1
ffffffffc02033ec:	00cb5b13          	srli	s6,s6,0xc
    if (PPN(pa) >= npage)
ffffffffc02033f0:	00098c97          	auipc	s9,0x98
ffffffffc02033f4:	610c8c93          	addi	s9,s9,1552 # ffffffffc029ba00 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02033f8:	00098c17          	auipc	s8,0x98
ffffffffc02033fc:	610c0c13          	addi	s8,s8,1552 # ffffffffc029ba08 <pages>
ffffffffc0203400:	fff80d37          	lui	s10,0xfff80
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203404:	4601                	li	a2,0
ffffffffc0203406:	85a2                	mv	a1,s0
ffffffffc0203408:	8552                	mv	a0,s4
ffffffffc020340a:	b19fe0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc020340e:	84aa                	mv	s1,a0
        if (ptep == NULL)
ffffffffc0203410:	0e050a63          	beqz	a0,ffffffffc0203504 <copy_range+0x16c>
        if (*ptep & PTE_V)
ffffffffc0203414:	611c                	ld	a5,0(a0)
ffffffffc0203416:	8b85                	andi	a5,a5,1
ffffffffc0203418:	e78d                	bnez	a5,ffffffffc0203442 <copy_range+0xaa>
        start += PGSIZE;
ffffffffc020341a:	9456                	add	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc020341c:	c019                	beqz	s0,ffffffffc0203422 <copy_range+0x8a>
ffffffffc020341e:	ff2463e3          	bltu	s0,s2,ffffffffc0203404 <copy_range+0x6c>
    return 0;
ffffffffc0203422:	4501                	li	a0,0
}
ffffffffc0203424:	70a6                	ld	ra,104(sp)
ffffffffc0203426:	7406                	ld	s0,96(sp)
ffffffffc0203428:	64e6                	ld	s1,88(sp)
ffffffffc020342a:	6946                	ld	s2,80(sp)
ffffffffc020342c:	69a6                	ld	s3,72(sp)
ffffffffc020342e:	6a06                	ld	s4,64(sp)
ffffffffc0203430:	7ae2                	ld	s5,56(sp)
ffffffffc0203432:	7b42                	ld	s6,48(sp)
ffffffffc0203434:	7ba2                	ld	s7,40(sp)
ffffffffc0203436:	7c02                	ld	s8,32(sp)
ffffffffc0203438:	6ce2                	ld	s9,24(sp)
ffffffffc020343a:	6d42                	ld	s10,16(sp)
ffffffffc020343c:	6da2                	ld	s11,8(sp)
ffffffffc020343e:	6165                	addi	sp,sp,112
ffffffffc0203440:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL)
ffffffffc0203442:	4605                	li	a2,1
ffffffffc0203444:	85a2                	mv	a1,s0
ffffffffc0203446:	855e                	mv	a0,s7
ffffffffc0203448:	adbfe0ef          	jal	ffffffffc0201f22 <get_pte>
ffffffffc020344c:	c165                	beqz	a0,ffffffffc020352c <copy_range+0x194>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc020344e:	0004b983          	ld	s3,0(s1)
    if (!(pte & PTE_V))
ffffffffc0203452:	0019f793          	andi	a5,s3,1
ffffffffc0203456:	14078663          	beqz	a5,ffffffffc02035a2 <copy_range+0x20a>
    if (PPN(pa) >= npage)
ffffffffc020345a:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020345e:	00299793          	slli	a5,s3,0x2
ffffffffc0203462:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage)
ffffffffc0203464:	12e7f363          	bgeu	a5,a4,ffffffffc020358a <copy_range+0x1f2>
    return &pages[PPN(pa) - nbase];
ffffffffc0203468:	000c3483          	ld	s1,0(s8)
ffffffffc020346c:	97ea                	add	a5,a5,s10
ffffffffc020346e:	079a                	slli	a5,a5,0x6
ffffffffc0203470:	94be                	add	s1,s1,a5
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203472:	100027f3          	csrr	a5,sstatus
ffffffffc0203476:	8b89                	andi	a5,a5,2
ffffffffc0203478:	efc9                	bnez	a5,ffffffffc0203512 <copy_range+0x17a>
        page = pmm_manager->alloc_pages(n);
ffffffffc020347a:	00098797          	auipc	a5,0x98
ffffffffc020347e:	5667b783          	ld	a5,1382(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc0203482:	4505                	li	a0,1
ffffffffc0203484:	6f9c                	ld	a5,24(a5)
ffffffffc0203486:	9782                	jalr	a5
ffffffffc0203488:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc020348a:	c0e5                	beqz	s1,ffffffffc020356a <copy_range+0x1d2>
            assert(npage != NULL);
ffffffffc020348c:	0a0d8f63          	beqz	s11,ffffffffc020354a <copy_range+0x1b2>
    return page - pages + nbase;
ffffffffc0203490:	000c3783          	ld	a5,0(s8)
ffffffffc0203494:	00080637          	lui	a2,0x80
    return KADDR(page2pa(page));
ffffffffc0203498:	000cb703          	ld	a4,0(s9)
    return page - pages + nbase;
ffffffffc020349c:	40f486b3          	sub	a3,s1,a5
ffffffffc02034a0:	8699                	srai	a3,a3,0x6
ffffffffc02034a2:	96b2                	add	a3,a3,a2
    return KADDR(page2pa(page));
ffffffffc02034a4:	0166f5b3          	and	a1,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034a8:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02034aa:	08e5f463          	bgeu	a1,a4,ffffffffc0203532 <copy_range+0x19a>
    return page - pages + nbase;
ffffffffc02034ae:	40fd87b3          	sub	a5,s11,a5
ffffffffc02034b2:	8799                	srai	a5,a5,0x6
ffffffffc02034b4:	97b2                	add	a5,a5,a2
    return KADDR(page2pa(page));
ffffffffc02034b6:	0167f633          	and	a2,a5,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc02034ba:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc02034bc:	06e67a63          	bgeu	a2,a4,ffffffffc0203530 <copy_range+0x198>
ffffffffc02034c0:	00098517          	auipc	a0,0x98
ffffffffc02034c4:	53853503          	ld	a0,1336(a0) # ffffffffc029b9f8 <va_pa_offset>
            memcpy((void *)dst_kvaddr, (void *)src_kvaddr, PGSIZE);  
ffffffffc02034c8:	6605                	lui	a2,0x1
ffffffffc02034ca:	00a685b3          	add	a1,a3,a0
ffffffffc02034ce:	953e                	add	a0,a0,a5
ffffffffc02034d0:	320020ef          	jal	ffffffffc02057f0 <memcpy>
            ret = page_insert(to, npage, start, perm); 
ffffffffc02034d4:	01f9f693          	andi	a3,s3,31
ffffffffc02034d8:	85ee                	mv	a1,s11
ffffffffc02034da:	8622                	mv	a2,s0
ffffffffc02034dc:	855e                	mv	a0,s7
ffffffffc02034de:	97aff0ef          	jal	ffffffffc0202658 <page_insert>
            assert(ret == 0);
ffffffffc02034e2:	dd05                	beqz	a0,ffffffffc020341a <copy_range+0x82>
ffffffffc02034e4:	00003697          	auipc	a3,0x3
ffffffffc02034e8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0206cb0 <etext+0x14a8>
ffffffffc02034ec:	00003617          	auipc	a2,0x3
ffffffffc02034f0:	cec60613          	addi	a2,a2,-788 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02034f4:	1b200593          	li	a1,434
ffffffffc02034f8:	00003517          	auipc	a0,0x3
ffffffffc02034fc:	18050513          	addi	a0,a0,384 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203500:	f47fc0ef          	jal	ffffffffc0200446 <__panic>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0203504:	002007b7          	lui	a5,0x200
ffffffffc0203508:	97a2                	add	a5,a5,s0
ffffffffc020350a:	ffe00437          	lui	s0,0xffe00
ffffffffc020350e:	8c7d                	and	s0,s0,a5
            continue;
ffffffffc0203510:	b731                	j	ffffffffc020341c <copy_range+0x84>
        intr_disable();
ffffffffc0203512:	bf2fd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203516:	00098797          	auipc	a5,0x98
ffffffffc020351a:	4ca7b783          	ld	a5,1226(a5) # ffffffffc029b9e0 <pmm_manager>
ffffffffc020351e:	4505                	li	a0,1
ffffffffc0203520:	6f9c                	ld	a5,24(a5)
ffffffffc0203522:	9782                	jalr	a5
ffffffffc0203524:	8daa                	mv	s11,a0
        intr_enable();
ffffffffc0203526:	bd8fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020352a:	b785                	j	ffffffffc020348a <copy_range+0xf2>
                return -E_NO_MEM;
ffffffffc020352c:	5571                	li	a0,-4
ffffffffc020352e:	bddd                	j	ffffffffc0203424 <copy_range+0x8c>
ffffffffc0203530:	86be                	mv	a3,a5
ffffffffc0203532:	00003617          	auipc	a2,0x3
ffffffffc0203536:	05660613          	addi	a2,a2,86 # ffffffffc0206588 <etext+0xd80>
ffffffffc020353a:	07100593          	li	a1,113
ffffffffc020353e:	00003517          	auipc	a0,0x3
ffffffffc0203542:	07250513          	addi	a0,a0,114 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0203546:	f01fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(npage != NULL);
ffffffffc020354a:	00003697          	auipc	a3,0x3
ffffffffc020354e:	75668693          	addi	a3,a3,1878 # ffffffffc0206ca0 <etext+0x1498>
ffffffffc0203552:	00003617          	auipc	a2,0x3
ffffffffc0203556:	c8660613          	addi	a2,a2,-890 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020355a:	19500593          	li	a1,405
ffffffffc020355e:	00003517          	auipc	a0,0x3
ffffffffc0203562:	11a50513          	addi	a0,a0,282 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203566:	ee1fc0ef          	jal	ffffffffc0200446 <__panic>
            assert(page != NULL);
ffffffffc020356a:	00003697          	auipc	a3,0x3
ffffffffc020356e:	72668693          	addi	a3,a3,1830 # ffffffffc0206c90 <etext+0x1488>
ffffffffc0203572:	00003617          	auipc	a2,0x3
ffffffffc0203576:	c6660613          	addi	a2,a2,-922 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020357a:	19400593          	li	a1,404
ffffffffc020357e:	00003517          	auipc	a0,0x3
ffffffffc0203582:	0fa50513          	addi	a0,a0,250 # ffffffffc0206678 <etext+0xe70>
ffffffffc0203586:	ec1fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020358a:	00003617          	auipc	a2,0x3
ffffffffc020358e:	0ce60613          	addi	a2,a2,206 # ffffffffc0206658 <etext+0xe50>
ffffffffc0203592:	06900593          	li	a1,105
ffffffffc0203596:	00003517          	auipc	a0,0x3
ffffffffc020359a:	01a50513          	addi	a0,a0,26 # ffffffffc02065b0 <etext+0xda8>
ffffffffc020359e:	ea9fc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02035a2:	00003617          	auipc	a2,0x3
ffffffffc02035a6:	2ce60613          	addi	a2,a2,718 # ffffffffc0206870 <etext+0x1068>
ffffffffc02035aa:	07f00593          	li	a1,127
ffffffffc02035ae:	00003517          	auipc	a0,0x3
ffffffffc02035b2:	00250513          	addi	a0,a0,2 # ffffffffc02065b0 <etext+0xda8>
ffffffffc02035b6:	e91fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02035ba:	00003697          	auipc	a3,0x3
ffffffffc02035be:	0fe68693          	addi	a3,a3,254 # ffffffffc02066b8 <etext+0xeb0>
ffffffffc02035c2:	00003617          	auipc	a2,0x3
ffffffffc02035c6:	c1660613          	addi	a2,a2,-1002 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02035ca:	17c00593          	li	a1,380
ffffffffc02035ce:	00003517          	auipc	a0,0x3
ffffffffc02035d2:	0aa50513          	addi	a0,a0,170 # ffffffffc0206678 <etext+0xe70>
ffffffffc02035d6:	e71fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02035da:	00003697          	auipc	a3,0x3
ffffffffc02035de:	0ae68693          	addi	a3,a3,174 # ffffffffc0206688 <etext+0xe80>
ffffffffc02035e2:	00003617          	auipc	a2,0x3
ffffffffc02035e6:	bf660613          	addi	a2,a2,-1034 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02035ea:	17b00593          	li	a1,379
ffffffffc02035ee:	00003517          	auipc	a0,0x3
ffffffffc02035f2:	08a50513          	addi	a0,a0,138 # ffffffffc0206678 <etext+0xe70>
ffffffffc02035f6:	e51fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02035fa <pgdir_alloc_page>:
{
ffffffffc02035fa:	7139                	addi	sp,sp,-64
ffffffffc02035fc:	f426                	sd	s1,40(sp)
ffffffffc02035fe:	f04a                	sd	s2,32(sp)
ffffffffc0203600:	ec4e                	sd	s3,24(sp)
ffffffffc0203602:	fc06                	sd	ra,56(sp)
ffffffffc0203604:	f822                	sd	s0,48(sp)
ffffffffc0203606:	892a                	mv	s2,a0
ffffffffc0203608:	84ae                	mv	s1,a1
ffffffffc020360a:	89b2                	mv	s3,a2
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020360c:	100027f3          	csrr	a5,sstatus
ffffffffc0203610:	8b89                	andi	a5,a5,2
ffffffffc0203612:	ebb5                	bnez	a5,ffffffffc0203686 <pgdir_alloc_page+0x8c>
        page = pmm_manager->alloc_pages(n);
ffffffffc0203614:	00098417          	auipc	s0,0x98
ffffffffc0203618:	3cc40413          	addi	s0,s0,972 # ffffffffc029b9e0 <pmm_manager>
ffffffffc020361c:	601c                	ld	a5,0(s0)
ffffffffc020361e:	4505                	li	a0,1
ffffffffc0203620:	6f9c                	ld	a5,24(a5)
ffffffffc0203622:	9782                	jalr	a5
ffffffffc0203624:	85aa                	mv	a1,a0
    if (page != NULL)
ffffffffc0203626:	c5b9                	beqz	a1,ffffffffc0203674 <pgdir_alloc_page+0x7a>
        if (page_insert(pgdir, page, la, perm) != 0)
ffffffffc0203628:	86ce                	mv	a3,s3
ffffffffc020362a:	854a                	mv	a0,s2
ffffffffc020362c:	8626                	mv	a2,s1
ffffffffc020362e:	e42e                	sd	a1,8(sp)
ffffffffc0203630:	828ff0ef          	jal	ffffffffc0202658 <page_insert>
ffffffffc0203634:	65a2                	ld	a1,8(sp)
ffffffffc0203636:	e515                	bnez	a0,ffffffffc0203662 <pgdir_alloc_page+0x68>
        assert(page_ref(page) == 1);
ffffffffc0203638:	4198                	lw	a4,0(a1)
        page->pra_vaddr = la;
ffffffffc020363a:	fd84                	sd	s1,56(a1)
        assert(page_ref(page) == 1);
ffffffffc020363c:	4785                	li	a5,1
ffffffffc020363e:	02f70c63          	beq	a4,a5,ffffffffc0203676 <pgdir_alloc_page+0x7c>
ffffffffc0203642:	00003697          	auipc	a3,0x3
ffffffffc0203646:	67e68693          	addi	a3,a3,1662 # ffffffffc0206cc0 <etext+0x14b8>
ffffffffc020364a:	00003617          	auipc	a2,0x3
ffffffffc020364e:	b8e60613          	addi	a2,a2,-1138 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203652:	1fb00593          	li	a1,507
ffffffffc0203656:	00003517          	auipc	a0,0x3
ffffffffc020365a:	02250513          	addi	a0,a0,34 # ffffffffc0206678 <etext+0xe70>
ffffffffc020365e:	de9fc0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0203662:	100027f3          	csrr	a5,sstatus
ffffffffc0203666:	8b89                	andi	a5,a5,2
ffffffffc0203668:	ef95                	bnez	a5,ffffffffc02036a4 <pgdir_alloc_page+0xaa>
        pmm_manager->free_pages(base, n);
ffffffffc020366a:	601c                	ld	a5,0(s0)
ffffffffc020366c:	852e                	mv	a0,a1
ffffffffc020366e:	4585                	li	a1,1
ffffffffc0203670:	739c                	ld	a5,32(a5)
ffffffffc0203672:	9782                	jalr	a5
            return NULL;
ffffffffc0203674:	4581                	li	a1,0
}
ffffffffc0203676:	70e2                	ld	ra,56(sp)
ffffffffc0203678:	7442                	ld	s0,48(sp)
ffffffffc020367a:	74a2                	ld	s1,40(sp)
ffffffffc020367c:	7902                	ld	s2,32(sp)
ffffffffc020367e:	69e2                	ld	s3,24(sp)
ffffffffc0203680:	852e                	mv	a0,a1
ffffffffc0203682:	6121                	addi	sp,sp,64
ffffffffc0203684:	8082                	ret
        intr_disable();
ffffffffc0203686:	a7efd0ef          	jal	ffffffffc0200904 <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc020368a:	00098417          	auipc	s0,0x98
ffffffffc020368e:	35640413          	addi	s0,s0,854 # ffffffffc029b9e0 <pmm_manager>
ffffffffc0203692:	601c                	ld	a5,0(s0)
ffffffffc0203694:	4505                	li	a0,1
ffffffffc0203696:	6f9c                	ld	a5,24(a5)
ffffffffc0203698:	9782                	jalr	a5
ffffffffc020369a:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc020369c:	a62fd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036a0:	65a2                	ld	a1,8(sp)
ffffffffc02036a2:	b751                	j	ffffffffc0203626 <pgdir_alloc_page+0x2c>
        intr_disable();
ffffffffc02036a4:	a60fd0ef          	jal	ffffffffc0200904 <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02036a8:	601c                	ld	a5,0(s0)
ffffffffc02036aa:	6522                	ld	a0,8(sp)
ffffffffc02036ac:	4585                	li	a1,1
ffffffffc02036ae:	739c                	ld	a5,32(a5)
ffffffffc02036b0:	9782                	jalr	a5
        intr_enable();
ffffffffc02036b2:	a4cfd0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc02036b6:	bf7d                	j	ffffffffc0203674 <pgdir_alloc_page+0x7a>

ffffffffc02036b8 <check_vma_overlap.part.0>:
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036b8:	1141                	addi	sp,sp,-16
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc02036ba:	00003697          	auipc	a3,0x3
ffffffffc02036be:	61e68693          	addi	a3,a3,1566 # ffffffffc0206cd8 <etext+0x14d0>
ffffffffc02036c2:	00003617          	auipc	a2,0x3
ffffffffc02036c6:	b1660613          	addi	a2,a2,-1258 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02036ca:	07400593          	li	a1,116
ffffffffc02036ce:	00003517          	auipc	a0,0x3
ffffffffc02036d2:	62a50513          	addi	a0,a0,1578 # ffffffffc0206cf8 <etext+0x14f0>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
ffffffffc02036d6:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02036d8:	d6ffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02036dc <mm_create>:
{
ffffffffc02036dc:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036de:	04000513          	li	a0,64
{
ffffffffc02036e2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02036e4:	dd4fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
    if (mm != NULL)
ffffffffc02036e8:	cd19                	beqz	a0,ffffffffc0203706 <mm_create+0x2a>
    elm->prev = elm->next = elm;
ffffffffc02036ea:	e508                	sd	a0,8(a0)
ffffffffc02036ec:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc02036ee:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02036f2:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02036f6:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc02036fa:	02053423          	sd	zero,40(a0)
}

static inline void
set_mm_count(struct mm_struct *mm, int val)
{
    mm->mm_count = val;
ffffffffc02036fe:	02052823          	sw	zero,48(a0)
typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock)
{
    *lock = 0;
ffffffffc0203702:	02053c23          	sd	zero,56(a0)
}
ffffffffc0203706:	60a2                	ld	ra,8(sp)
ffffffffc0203708:	0141                	addi	sp,sp,16
ffffffffc020370a:	8082                	ret

ffffffffc020370c <find_vma>:
    if (mm != NULL)
ffffffffc020370c:	c505                	beqz	a0,ffffffffc0203734 <find_vma+0x28>
        vma = mm->mmap_cache;
ffffffffc020370e:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc0203710:	c781                	beqz	a5,ffffffffc0203718 <find_vma+0xc>
ffffffffc0203712:	6798                	ld	a4,8(a5)
ffffffffc0203714:	02e5f363          	bgeu	a1,a4,ffffffffc020373a <find_vma+0x2e>
    return listelm->next;
ffffffffc0203718:	651c                	ld	a5,8(a0)
            while ((le = list_next(le)) != list)
ffffffffc020371a:	00f50d63          	beq	a0,a5,ffffffffc0203734 <find_vma+0x28>
                if (vma->vm_start <= addr && addr < vma->vm_end)
ffffffffc020371e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203722:	00e5e663          	bltu	a1,a4,ffffffffc020372e <find_vma+0x22>
ffffffffc0203726:	ff07b703          	ld	a4,-16(a5)
ffffffffc020372a:	00e5ee63          	bltu	a1,a4,ffffffffc0203746 <find_vma+0x3a>
ffffffffc020372e:	679c                	ld	a5,8(a5)
            while ((le = list_next(le)) != list)
ffffffffc0203730:	fef517e3          	bne	a0,a5,ffffffffc020371e <find_vma+0x12>
    struct vma_struct *vma = NULL;
ffffffffc0203734:	4781                	li	a5,0
}
ffffffffc0203736:	853e                	mv	a0,a5
ffffffffc0203738:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
ffffffffc020373a:	6b98                	ld	a4,16(a5)
ffffffffc020373c:	fce5fee3          	bgeu	a1,a4,ffffffffc0203718 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc0203740:	e91c                	sd	a5,16(a0)
}
ffffffffc0203742:	853e                	mv	a0,a5
ffffffffc0203744:	8082                	ret
                vma = le2vma(le, list_link);
ffffffffc0203746:	1781                	addi	a5,a5,-32
            mm->mmap_cache = vma;
ffffffffc0203748:	e91c                	sd	a5,16(a0)
ffffffffc020374a:	bfe5                	j	ffffffffc0203742 <find_vma+0x36>

ffffffffc020374c <insert_vma_struct>:
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
ffffffffc020374c:	6590                	ld	a2,8(a1)
ffffffffc020374e:	0105b803          	ld	a6,16(a1)
{
ffffffffc0203752:	1141                	addi	sp,sp,-16
ffffffffc0203754:	e406                	sd	ra,8(sp)
ffffffffc0203756:	87aa                	mv	a5,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc0203758:	01066763          	bltu	a2,a6,ffffffffc0203766 <insert_vma_struct+0x1a>
ffffffffc020375c:	a8b9                	j	ffffffffc02037ba <insert_vma_struct+0x6e>

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
ffffffffc020375e:	fe87b703          	ld	a4,-24(a5)
ffffffffc0203762:	04e66763          	bltu	a2,a4,ffffffffc02037b0 <insert_vma_struct+0x64>
ffffffffc0203766:	86be                	mv	a3,a5
ffffffffc0203768:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != list)
ffffffffc020376a:	fef51ae3          	bne	a0,a5,ffffffffc020375e <insert_vma_struct+0x12>
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
ffffffffc020376e:	02a68463          	beq	a3,a0,ffffffffc0203796 <insert_vma_struct+0x4a>
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0203772:	ff06b703          	ld	a4,-16(a3)
    assert(prev->vm_start < prev->vm_end);
ffffffffc0203776:	fe86b883          	ld	a7,-24(a3)
ffffffffc020377a:	08e8f063          	bgeu	a7,a4,ffffffffc02037fa <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc020377e:	04e66e63          	bltu	a2,a4,ffffffffc02037da <insert_vma_struct+0x8e>
    }
    if (le_next != list)
ffffffffc0203782:	00f50a63          	beq	a0,a5,ffffffffc0203796 <insert_vma_struct+0x4a>
ffffffffc0203786:	fe87b703          	ld	a4,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc020378a:	05076863          	bltu	a4,a6,ffffffffc02037da <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc020378e:	ff07b603          	ld	a2,-16(a5)
ffffffffc0203792:	02c77263          	bgeu	a4,a2,ffffffffc02037b6 <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
ffffffffc0203796:	5118                	lw	a4,32(a0)
    vma->vm_mm = mm;
ffffffffc0203798:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc020379a:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc020379e:	e390                	sd	a2,0(a5)
ffffffffc02037a0:	e690                	sd	a2,8(a3)
}
ffffffffc02037a2:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02037a4:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02037a6:	f194                	sd	a3,32(a1)
    mm->map_count++;
ffffffffc02037a8:	2705                	addiw	a4,a4,1
ffffffffc02037aa:	d118                	sw	a4,32(a0)
}
ffffffffc02037ac:	0141                	addi	sp,sp,16
ffffffffc02037ae:	8082                	ret
    if (le_prev != list)
ffffffffc02037b0:	fca691e3          	bne	a3,a0,ffffffffc0203772 <insert_vma_struct+0x26>
ffffffffc02037b4:	bfd9                	j	ffffffffc020378a <insert_vma_struct+0x3e>
ffffffffc02037b6:	f03ff0ef          	jal	ffffffffc02036b8 <check_vma_overlap.part.0>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02037ba:	00003697          	auipc	a3,0x3
ffffffffc02037be:	54e68693          	addi	a3,a3,1358 # ffffffffc0206d08 <etext+0x1500>
ffffffffc02037c2:	00003617          	auipc	a2,0x3
ffffffffc02037c6:	a1660613          	addi	a2,a2,-1514 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02037ca:	07a00593          	li	a1,122
ffffffffc02037ce:	00003517          	auipc	a0,0x3
ffffffffc02037d2:	52a50513          	addi	a0,a0,1322 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc02037d6:	c71fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02037da:	00003697          	auipc	a3,0x3
ffffffffc02037de:	56e68693          	addi	a3,a3,1390 # ffffffffc0206d48 <etext+0x1540>
ffffffffc02037e2:	00003617          	auipc	a2,0x3
ffffffffc02037e6:	9f660613          	addi	a2,a2,-1546 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02037ea:	07300593          	li	a1,115
ffffffffc02037ee:	00003517          	auipc	a0,0x3
ffffffffc02037f2:	50a50513          	addi	a0,a0,1290 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc02037f6:	c51fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc02037fa:	00003697          	auipc	a3,0x3
ffffffffc02037fe:	52e68693          	addi	a3,a3,1326 # ffffffffc0206d28 <etext+0x1520>
ffffffffc0203802:	00003617          	auipc	a2,0x3
ffffffffc0203806:	9d660613          	addi	a2,a2,-1578 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020380a:	07200593          	li	a1,114
ffffffffc020380e:	00003517          	auipc	a0,0x3
ffffffffc0203812:	4ea50513          	addi	a0,a0,1258 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203816:	c31fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020381a <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);
ffffffffc020381a:	591c                	lw	a5,48(a0)
{
ffffffffc020381c:	1141                	addi	sp,sp,-16
ffffffffc020381e:	e406                	sd	ra,8(sp)
ffffffffc0203820:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0203822:	e78d                	bnez	a5,ffffffffc020384c <mm_destroy+0x32>
ffffffffc0203824:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc0203826:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
ffffffffc0203828:	00a40c63          	beq	s0,a0,ffffffffc0203840 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc020382c:	6118                	ld	a4,0(a0)
ffffffffc020382e:	651c                	ld	a5,8(a0)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
ffffffffc0203830:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0203832:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc0203834:	e398                	sd	a4,0(a5)
ffffffffc0203836:	d28fe0ef          	jal	ffffffffc0201d5e <kfree>
    return listelm->next;
ffffffffc020383a:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list)
ffffffffc020383c:	fea418e3          	bne	s0,a0,ffffffffc020382c <mm_destroy+0x12>
    }
    kfree(mm); // kfree mm
ffffffffc0203840:	8522                	mv	a0,s0
    mm = NULL;
}
ffffffffc0203842:	6402                	ld	s0,0(sp)
ffffffffc0203844:	60a2                	ld	ra,8(sp)
ffffffffc0203846:	0141                	addi	sp,sp,16
    kfree(mm); // kfree mm
ffffffffc0203848:	d16fe06f          	j	ffffffffc0201d5e <kfree>
    assert(mm_count(mm) == 0);
ffffffffc020384c:	00003697          	auipc	a3,0x3
ffffffffc0203850:	51c68693          	addi	a3,a3,1308 # ffffffffc0206d68 <etext+0x1560>
ffffffffc0203854:	00003617          	auipc	a2,0x3
ffffffffc0203858:	98460613          	addi	a2,a2,-1660 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020385c:	09e00593          	li	a1,158
ffffffffc0203860:	00003517          	auipc	a0,0x3
ffffffffc0203864:	49850513          	addi	a0,a0,1176 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203868:	bdffc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc020386c <mm_map>:

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020386c:	6785                	lui	a5,0x1
ffffffffc020386e:	17fd                	addi	a5,a5,-1 # fff <_binary_obj___user_softint_out_size-0x7c09>
ffffffffc0203870:	963e                	add	a2,a2,a5
    if (!USER_ACCESS(start, end))
ffffffffc0203872:	4785                	li	a5,1
{
ffffffffc0203874:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203876:	962e                	add	a2,a2,a1
ffffffffc0203878:	787d                	lui	a6,0xfffff
    if (!USER_ACCESS(start, end))
ffffffffc020387a:	07fe                	slli	a5,a5,0x1f
{
ffffffffc020387c:	f822                	sd	s0,48(sp)
ffffffffc020387e:	f426                	sd	s1,40(sp)
ffffffffc0203880:	01067433          	and	s0,a2,a6
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0203884:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end))
ffffffffc0203888:	0785                	addi	a5,a5,1
ffffffffc020388a:	0084b633          	sltu	a2,s1,s0
ffffffffc020388e:	00f437b3          	sltu	a5,s0,a5
ffffffffc0203892:	00163613          	seqz	a2,a2
ffffffffc0203896:	0017b793          	seqz	a5,a5
{
ffffffffc020389a:	fc06                	sd	ra,56(sp)
    if (!USER_ACCESS(start, end))
ffffffffc020389c:	8fd1                	or	a5,a5,a2
ffffffffc020389e:	ebbd                	bnez	a5,ffffffffc0203914 <mm_map+0xa8>
ffffffffc02038a0:	002007b7          	lui	a5,0x200
ffffffffc02038a4:	06f4e863          	bltu	s1,a5,ffffffffc0203914 <mm_map+0xa8>
ffffffffc02038a8:	f04a                	sd	s2,32(sp)
ffffffffc02038aa:	ec4e                	sd	s3,24(sp)
ffffffffc02038ac:	e852                	sd	s4,16(sp)
ffffffffc02038ae:	892a                	mv	s2,a0
ffffffffc02038b0:	89ba                	mv	s3,a4
ffffffffc02038b2:	8a36                	mv	s4,a3
    {
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02038b4:	c135                	beqz	a0,ffffffffc0203918 <mm_map+0xac>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
ffffffffc02038b6:	85a6                	mv	a1,s1
ffffffffc02038b8:	e55ff0ef          	jal	ffffffffc020370c <find_vma>
ffffffffc02038bc:	c501                	beqz	a0,ffffffffc02038c4 <mm_map+0x58>
ffffffffc02038be:	651c                	ld	a5,8(a0)
ffffffffc02038c0:	0487e763          	bltu	a5,s0,ffffffffc020390e <mm_map+0xa2>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02038c4:	03000513          	li	a0,48
ffffffffc02038c8:	bf0fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
ffffffffc02038cc:	85aa                	mv	a1,a0
    {
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02038ce:	5571                	li	a0,-4
    if (vma != NULL)
ffffffffc02038d0:	c59d                	beqz	a1,ffffffffc02038fe <mm_map+0x92>
        vma->vm_start = vm_start;
ffffffffc02038d2:	e584                	sd	s1,8(a1)
        vma->vm_end = vm_end;
ffffffffc02038d4:	e980                	sd	s0,16(a1)
        vma->vm_flags = vm_flags;
ffffffffc02038d6:	0145ac23          	sw	s4,24(a1)

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02038da:	854a                	mv	a0,s2
ffffffffc02038dc:	e42e                	sd	a1,8(sp)
ffffffffc02038de:	e6fff0ef          	jal	ffffffffc020374c <insert_vma_struct>
    if (vma_store != NULL)
ffffffffc02038e2:	65a2                	ld	a1,8(sp)
ffffffffc02038e4:	00098463          	beqz	s3,ffffffffc02038ec <mm_map+0x80>
    {
        *vma_store = vma;
ffffffffc02038e8:	00b9b023          	sd	a1,0(s3)
ffffffffc02038ec:	7902                	ld	s2,32(sp)
ffffffffc02038ee:	69e2                	ld	s3,24(sp)
ffffffffc02038f0:	6a42                	ld	s4,16(sp)
    }
    ret = 0;
ffffffffc02038f2:	4501                	li	a0,0

out:
    return ret;
}
ffffffffc02038f4:	70e2                	ld	ra,56(sp)
ffffffffc02038f6:	7442                	ld	s0,48(sp)
ffffffffc02038f8:	74a2                	ld	s1,40(sp)
ffffffffc02038fa:	6121                	addi	sp,sp,64
ffffffffc02038fc:	8082                	ret
ffffffffc02038fe:	70e2                	ld	ra,56(sp)
ffffffffc0203900:	7442                	ld	s0,48(sp)
ffffffffc0203902:	7902                	ld	s2,32(sp)
ffffffffc0203904:	69e2                	ld	s3,24(sp)
ffffffffc0203906:	6a42                	ld	s4,16(sp)
ffffffffc0203908:	74a2                	ld	s1,40(sp)
ffffffffc020390a:	6121                	addi	sp,sp,64
ffffffffc020390c:	8082                	ret
ffffffffc020390e:	7902                	ld	s2,32(sp)
ffffffffc0203910:	69e2                	ld	s3,24(sp)
ffffffffc0203912:	6a42                	ld	s4,16(sp)
        return -E_INVAL;
ffffffffc0203914:	5575                	li	a0,-3
ffffffffc0203916:	bff9                	j	ffffffffc02038f4 <mm_map+0x88>
    assert(mm != NULL);
ffffffffc0203918:	00003697          	auipc	a3,0x3
ffffffffc020391c:	46868693          	addi	a3,a3,1128 # ffffffffc0206d80 <etext+0x1578>
ffffffffc0203920:	00003617          	auipc	a2,0x3
ffffffffc0203924:	8b860613          	addi	a2,a2,-1864 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203928:	0b300593          	li	a1,179
ffffffffc020392c:	00003517          	auipc	a0,0x3
ffffffffc0203930:	3cc50513          	addi	a0,a0,972 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203934:	b13fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203938 <dup_mmap>:

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
ffffffffc0203938:	7139                	addi	sp,sp,-64
ffffffffc020393a:	fc06                	sd	ra,56(sp)
ffffffffc020393c:	f822                	sd	s0,48(sp)
ffffffffc020393e:	f426                	sd	s1,40(sp)
ffffffffc0203940:	f04a                	sd	s2,32(sp)
ffffffffc0203942:	ec4e                	sd	s3,24(sp)
ffffffffc0203944:	e852                	sd	s4,16(sp)
ffffffffc0203946:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0203948:	c525                	beqz	a0,ffffffffc02039b0 <dup_mmap+0x78>
ffffffffc020394a:	892a                	mv	s2,a0
ffffffffc020394c:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020394e:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc0203950:	c1a5                	beqz	a1,ffffffffc02039b0 <dup_mmap+0x78>
    return listelm->prev;
ffffffffc0203952:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list)
ffffffffc0203954:	04848c63          	beq	s1,s0,ffffffffc02039ac <dup_mmap+0x74>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203958:	03000513          	li	a0,48
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc020395c:	fe843a83          	ld	s5,-24(s0)
ffffffffc0203960:	ff043a03          	ld	s4,-16(s0)
ffffffffc0203964:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203968:	b50fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
    if (vma != NULL)
ffffffffc020396c:	c515                	beqz	a0,ffffffffc0203998 <dup_mmap+0x60>
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc020396e:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0203970:	01553423          	sd	s5,8(a0)
ffffffffc0203974:	01453823          	sd	s4,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203978:	01352c23          	sw	s3,24(a0)
        insert_vma_struct(to, nvma);
ffffffffc020397c:	854a                	mv	a0,s2
ffffffffc020397e:	dcfff0ef          	jal	ffffffffc020374c <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
ffffffffc0203982:	ff043683          	ld	a3,-16(s0)
ffffffffc0203986:	fe843603          	ld	a2,-24(s0)
ffffffffc020398a:	6c8c                	ld	a1,24(s1)
ffffffffc020398c:	01893503          	ld	a0,24(s2)
ffffffffc0203990:	4701                	li	a4,0
ffffffffc0203992:	a07ff0ef          	jal	ffffffffc0203398 <copy_range>
ffffffffc0203996:	dd55                	beqz	a0,ffffffffc0203952 <dup_mmap+0x1a>
            return -E_NO_MEM;
ffffffffc0203998:	5571                	li	a0,-4
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc020399a:	70e2                	ld	ra,56(sp)
ffffffffc020399c:	7442                	ld	s0,48(sp)
ffffffffc020399e:	74a2                	ld	s1,40(sp)
ffffffffc02039a0:	7902                	ld	s2,32(sp)
ffffffffc02039a2:	69e2                	ld	s3,24(sp)
ffffffffc02039a4:	6a42                	ld	s4,16(sp)
ffffffffc02039a6:	6aa2                	ld	s5,8(sp)
ffffffffc02039a8:	6121                	addi	sp,sp,64
ffffffffc02039aa:	8082                	ret
    return 0;
ffffffffc02039ac:	4501                	li	a0,0
ffffffffc02039ae:	b7f5                	j	ffffffffc020399a <dup_mmap+0x62>
    assert(to != NULL && from != NULL);
ffffffffc02039b0:	00003697          	auipc	a3,0x3
ffffffffc02039b4:	3e068693          	addi	a3,a3,992 # ffffffffc0206d90 <etext+0x1588>
ffffffffc02039b8:	00003617          	auipc	a2,0x3
ffffffffc02039bc:	82060613          	addi	a2,a2,-2016 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02039c0:	0cf00593          	li	a1,207
ffffffffc02039c4:	00003517          	auipc	a0,0x3
ffffffffc02039c8:	33450513          	addi	a0,a0,820 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc02039cc:	a7bfc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02039d0 <exit_mmap>:

void exit_mmap(struct mm_struct *mm)
{
ffffffffc02039d0:	1101                	addi	sp,sp,-32
ffffffffc02039d2:	ec06                	sd	ra,24(sp)
ffffffffc02039d4:	e822                	sd	s0,16(sp)
ffffffffc02039d6:	e426                	sd	s1,8(sp)
ffffffffc02039d8:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02039da:	c531                	beqz	a0,ffffffffc0203a26 <exit_mmap+0x56>
ffffffffc02039dc:	591c                	lw	a5,48(a0)
ffffffffc02039de:	84aa                	mv	s1,a0
ffffffffc02039e0:	e3b9                	bnez	a5,ffffffffc0203a26 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02039e2:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02039e4:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
ffffffffc02039e8:	02850663          	beq	a0,s0,ffffffffc0203a14 <exit_mmap+0x44>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02039ec:	ff043603          	ld	a2,-16(s0)
ffffffffc02039f0:	fe843583          	ld	a1,-24(s0)
ffffffffc02039f4:	854a                	mv	a0,s2
ffffffffc02039f6:	fdefe0ef          	jal	ffffffffc02021d4 <unmap_range>
ffffffffc02039fa:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc02039fc:	fe8498e3          	bne	s1,s0,ffffffffc02039ec <exit_mmap+0x1c>
ffffffffc0203a00:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list)
ffffffffc0203a02:	00848c63          	beq	s1,s0,ffffffffc0203a1a <exit_mmap+0x4a>
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0203a06:	ff043603          	ld	a2,-16(s0)
ffffffffc0203a0a:	fe843583          	ld	a1,-24(s0)
ffffffffc0203a0e:	854a                	mv	a0,s2
ffffffffc0203a10:	8f9fe0ef          	jal	ffffffffc0202308 <exit_range>
ffffffffc0203a14:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list)
ffffffffc0203a16:	fe8498e3          	bne	s1,s0,ffffffffc0203a06 <exit_mmap+0x36>
    }
}
ffffffffc0203a1a:	60e2                	ld	ra,24(sp)
ffffffffc0203a1c:	6442                	ld	s0,16(sp)
ffffffffc0203a1e:	64a2                	ld	s1,8(sp)
ffffffffc0203a20:	6902                	ld	s2,0(sp)
ffffffffc0203a22:	6105                	addi	sp,sp,32
ffffffffc0203a24:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0203a26:	00003697          	auipc	a3,0x3
ffffffffc0203a2a:	38a68693          	addi	a3,a3,906 # ffffffffc0206db0 <etext+0x15a8>
ffffffffc0203a2e:	00002617          	auipc	a2,0x2
ffffffffc0203a32:	7aa60613          	addi	a2,a2,1962 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203a36:	0e800593          	li	a1,232
ffffffffc0203a3a:	00003517          	auipc	a0,0x3
ffffffffc0203a3e:	2be50513          	addi	a0,a0,702 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203a42:	a05fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203a46 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
ffffffffc0203a46:	7179                	addi	sp,sp,-48
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a48:	04000513          	li	a0,64
{
ffffffffc0203a4c:	f406                	sd	ra,40(sp)
ffffffffc0203a4e:	f022                	sd	s0,32(sp)
ffffffffc0203a50:	ec26                	sd	s1,24(sp)
ffffffffc0203a52:	e84a                	sd	s2,16(sp)
ffffffffc0203a54:	e44e                	sd	s3,8(sp)
ffffffffc0203a56:	e052                	sd	s4,0(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc0203a58:	a60fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
    if (mm != NULL)
ffffffffc0203a5c:	16050c63          	beqz	a0,ffffffffc0203bd4 <vmm_init+0x18e>
ffffffffc0203a60:	842a                	mv	s0,a0
    elm->prev = elm->next = elm;
ffffffffc0203a62:	e508                	sd	a0,8(a0)
ffffffffc0203a64:	e108                	sd	a0,0(a0)
        mm->mmap_cache = NULL;
ffffffffc0203a66:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc0203a6a:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc0203a6e:	02052023          	sw	zero,32(a0)
        mm->sm_priv = NULL;
ffffffffc0203a72:	02053423          	sd	zero,40(a0)
ffffffffc0203a76:	02052823          	sw	zero,48(a0)
ffffffffc0203a7a:	02053c23          	sd	zero,56(a0)
ffffffffc0203a7e:	03200493          	li	s1,50
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203a82:	03000513          	li	a0,48
ffffffffc0203a86:	a32fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
    if (vma != NULL)
ffffffffc0203a8a:	12050563          	beqz	a0,ffffffffc0203bb4 <vmm_init+0x16e>
        vma->vm_end = vm_end;
ffffffffc0203a8e:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203a92:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203a94:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203a98:	e91c                	sd	a5,16(a0)
    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203a9a:	85aa                	mv	a1,a0
    for (i = step1; i >= 1; i--)
ffffffffc0203a9c:	14ed                	addi	s1,s1,-5
        insert_vma_struct(mm, vma);
ffffffffc0203a9e:	8522                	mv	a0,s0
ffffffffc0203aa0:	cadff0ef          	jal	ffffffffc020374c <insert_vma_struct>
    for (i = step1; i >= 1; i--)
ffffffffc0203aa4:	fcf9                	bnez	s1,ffffffffc0203a82 <vmm_init+0x3c>
ffffffffc0203aa6:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203aaa:	1f900913          	li	s2,505
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0203aae:	03000513          	li	a0,48
ffffffffc0203ab2:	a06fe0ef          	jal	ffffffffc0201cb8 <kmalloc>
    if (vma != NULL)
ffffffffc0203ab6:	12050f63          	beqz	a0,ffffffffc0203bf4 <vmm_init+0x1ae>
        vma->vm_end = vm_end;
ffffffffc0203aba:	00248793          	addi	a5,s1,2
        vma->vm_start = vm_start;
ffffffffc0203abe:	e504                	sd	s1,8(a0)
        vma->vm_flags = vm_flags;
ffffffffc0203ac0:	00052c23          	sw	zero,24(a0)
        vma->vm_end = vm_end;
ffffffffc0203ac4:	e91c                	sd	a5,16(a0)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc0203ac6:	85aa                	mv	a1,a0
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ac8:	0495                	addi	s1,s1,5
        insert_vma_struct(mm, vma);
ffffffffc0203aca:	8522                	mv	a0,s0
ffffffffc0203acc:	c81ff0ef          	jal	ffffffffc020374c <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i++)
ffffffffc0203ad0:	fd249fe3          	bne	s1,s2,ffffffffc0203aae <vmm_init+0x68>
    return listelm->next;
ffffffffc0203ad4:	641c                	ld	a5,8(s0)
ffffffffc0203ad6:	471d                	li	a4,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
ffffffffc0203ad8:	1fb00593          	li	a1,507
    {
        assert(le != &(mm->mmap_list));
ffffffffc0203adc:	1ef40c63          	beq	s0,a5,ffffffffc0203cd4 <vmm_init+0x28e>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203ae0:	fe87b603          	ld	a2,-24(a5) # 1fffe8 <_binary_obj___user_exit_out_size+0x1f5df0>
ffffffffc0203ae4:	ffe70693          	addi	a3,a4,-2
ffffffffc0203ae8:	12d61663          	bne	a2,a3,ffffffffc0203c14 <vmm_init+0x1ce>
ffffffffc0203aec:	ff07b683          	ld	a3,-16(a5)
ffffffffc0203af0:	12e69263          	bne	a3,a4,ffffffffc0203c14 <vmm_init+0x1ce>
    for (i = 1; i <= step2; i++)
ffffffffc0203af4:	0715                	addi	a4,a4,5
ffffffffc0203af6:	679c                	ld	a5,8(a5)
ffffffffc0203af8:	feb712e3          	bne	a4,a1,ffffffffc0203adc <vmm_init+0x96>
ffffffffc0203afc:	491d                	li	s2,7
ffffffffc0203afe:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0203b00:	85a6                	mv	a1,s1
ffffffffc0203b02:	8522                	mv	a0,s0
ffffffffc0203b04:	c09ff0ef          	jal	ffffffffc020370c <find_vma>
ffffffffc0203b08:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc0203b0a:	20050563          	beqz	a0,ffffffffc0203d14 <vmm_init+0x2ce>
        struct vma_struct *vma2 = find_vma(mm, i + 1);
ffffffffc0203b0e:	00148593          	addi	a1,s1,1
ffffffffc0203b12:	8522                	mv	a0,s0
ffffffffc0203b14:	bf9ff0ef          	jal	ffffffffc020370c <find_vma>
ffffffffc0203b18:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc0203b1a:	1c050d63          	beqz	a0,ffffffffc0203cf4 <vmm_init+0x2ae>
        struct vma_struct *vma3 = find_vma(mm, i + 2);
ffffffffc0203b1e:	85ca                	mv	a1,s2
ffffffffc0203b20:	8522                	mv	a0,s0
ffffffffc0203b22:	bebff0ef          	jal	ffffffffc020370c <find_vma>
        assert(vma3 == NULL);
ffffffffc0203b26:	18051763          	bnez	a0,ffffffffc0203cb4 <vmm_init+0x26e>
        struct vma_struct *vma4 = find_vma(mm, i + 3);
ffffffffc0203b2a:	00348593          	addi	a1,s1,3
ffffffffc0203b2e:	8522                	mv	a0,s0
ffffffffc0203b30:	bddff0ef          	jal	ffffffffc020370c <find_vma>
        assert(vma4 == NULL);
ffffffffc0203b34:	16051063          	bnez	a0,ffffffffc0203c94 <vmm_init+0x24e>
        struct vma_struct *vma5 = find_vma(mm, i + 4);
ffffffffc0203b38:	00448593          	addi	a1,s1,4
ffffffffc0203b3c:	8522                	mv	a0,s0
ffffffffc0203b3e:	bcfff0ef          	jal	ffffffffc020370c <find_vma>
        assert(vma5 == NULL);
ffffffffc0203b42:	12051963          	bnez	a0,ffffffffc0203c74 <vmm_init+0x22e>

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203b46:	008a3783          	ld	a5,8(s4)
ffffffffc0203b4a:	10979563          	bne	a5,s1,ffffffffc0203c54 <vmm_init+0x20e>
ffffffffc0203b4e:	010a3783          	ld	a5,16(s4)
ffffffffc0203b52:	11279163          	bne	a5,s2,ffffffffc0203c54 <vmm_init+0x20e>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203b56:	0089b783          	ld	a5,8(s3)
ffffffffc0203b5a:	0c979d63          	bne	a5,s1,ffffffffc0203c34 <vmm_init+0x1ee>
ffffffffc0203b5e:	0109b783          	ld	a5,16(s3)
ffffffffc0203b62:	0d279963          	bne	a5,s2,ffffffffc0203c34 <vmm_init+0x1ee>
    for (i = 5; i <= 5 * step2; i += 5)
ffffffffc0203b66:	0495                	addi	s1,s1,5
ffffffffc0203b68:	1f900793          	li	a5,505
ffffffffc0203b6c:	0915                	addi	s2,s2,5
ffffffffc0203b6e:	f8f499e3          	bne	s1,a5,ffffffffc0203b00 <vmm_init+0xba>
ffffffffc0203b72:	4491                	li	s1,4
    }

    for (i = 4; i >= 0; i--)
ffffffffc0203b74:	597d                	li	s2,-1
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
ffffffffc0203b76:	85a6                	mv	a1,s1
ffffffffc0203b78:	8522                	mv	a0,s0
ffffffffc0203b7a:	b93ff0ef          	jal	ffffffffc020370c <find_vma>
        if (vma_below_5 != NULL)
ffffffffc0203b7e:	1a051b63          	bnez	a0,ffffffffc0203d34 <vmm_init+0x2ee>
    for (i = 4; i >= 0; i--)
ffffffffc0203b82:	14fd                	addi	s1,s1,-1
ffffffffc0203b84:	ff2499e3          	bne	s1,s2,ffffffffc0203b76 <vmm_init+0x130>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);
ffffffffc0203b88:	8522                	mv	a0,s0
ffffffffc0203b8a:	c91ff0ef          	jal	ffffffffc020381a <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc0203b8e:	00003517          	auipc	a0,0x3
ffffffffc0203b92:	39250513          	addi	a0,a0,914 # ffffffffc0206f20 <etext+0x1718>
ffffffffc0203b96:	dfefc0ef          	jal	ffffffffc0200194 <cprintf>
}
ffffffffc0203b9a:	7402                	ld	s0,32(sp)
ffffffffc0203b9c:	70a2                	ld	ra,40(sp)
ffffffffc0203b9e:	64e2                	ld	s1,24(sp)
ffffffffc0203ba0:	6942                	ld	s2,16(sp)
ffffffffc0203ba2:	69a2                	ld	s3,8(sp)
ffffffffc0203ba4:	6a02                	ld	s4,0(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203ba6:	00003517          	auipc	a0,0x3
ffffffffc0203baa:	39a50513          	addi	a0,a0,922 # ffffffffc0206f40 <etext+0x1738>
}
ffffffffc0203bae:	6145                	addi	sp,sp,48
    cprintf("check_vmm() succeeded.\n");
ffffffffc0203bb0:	de4fc06f          	j	ffffffffc0200194 <cprintf>
        assert(vma != NULL);
ffffffffc0203bb4:	00003697          	auipc	a3,0x3
ffffffffc0203bb8:	21c68693          	addi	a3,a3,540 # ffffffffc0206dd0 <etext+0x15c8>
ffffffffc0203bbc:	00002617          	auipc	a2,0x2
ffffffffc0203bc0:	61c60613          	addi	a2,a2,1564 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203bc4:	12c00593          	li	a1,300
ffffffffc0203bc8:	00003517          	auipc	a0,0x3
ffffffffc0203bcc:	13050513          	addi	a0,a0,304 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203bd0:	877fc0ef          	jal	ffffffffc0200446 <__panic>
    assert(mm != NULL);
ffffffffc0203bd4:	00003697          	auipc	a3,0x3
ffffffffc0203bd8:	1ac68693          	addi	a3,a3,428 # ffffffffc0206d80 <etext+0x1578>
ffffffffc0203bdc:	00002617          	auipc	a2,0x2
ffffffffc0203be0:	5fc60613          	addi	a2,a2,1532 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203be4:	12400593          	li	a1,292
ffffffffc0203be8:	00003517          	auipc	a0,0x3
ffffffffc0203bec:	11050513          	addi	a0,a0,272 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203bf0:	857fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma != NULL);
ffffffffc0203bf4:	00003697          	auipc	a3,0x3
ffffffffc0203bf8:	1dc68693          	addi	a3,a3,476 # ffffffffc0206dd0 <etext+0x15c8>
ffffffffc0203bfc:	00002617          	auipc	a2,0x2
ffffffffc0203c00:	5dc60613          	addi	a2,a2,1500 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203c04:	13300593          	li	a1,307
ffffffffc0203c08:	00003517          	auipc	a0,0x3
ffffffffc0203c0c:	0f050513          	addi	a0,a0,240 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203c10:	837fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0203c14:	00003697          	auipc	a3,0x3
ffffffffc0203c18:	1e468693          	addi	a3,a3,484 # ffffffffc0206df8 <etext+0x15f0>
ffffffffc0203c1c:	00002617          	auipc	a2,0x2
ffffffffc0203c20:	5bc60613          	addi	a2,a2,1468 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203c24:	13d00593          	li	a1,317
ffffffffc0203c28:	00003517          	auipc	a0,0x3
ffffffffc0203c2c:	0d050513          	addi	a0,a0,208 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203c30:	817fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
ffffffffc0203c34:	00003697          	auipc	a3,0x3
ffffffffc0203c38:	27c68693          	addi	a3,a3,636 # ffffffffc0206eb0 <etext+0x16a8>
ffffffffc0203c3c:	00002617          	auipc	a2,0x2
ffffffffc0203c40:	59c60613          	addi	a2,a2,1436 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203c44:	14f00593          	li	a1,335
ffffffffc0203c48:	00003517          	auipc	a0,0x3
ffffffffc0203c4c:	0b050513          	addi	a0,a0,176 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203c50:	ff6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
ffffffffc0203c54:	00003697          	auipc	a3,0x3
ffffffffc0203c58:	22c68693          	addi	a3,a3,556 # ffffffffc0206e80 <etext+0x1678>
ffffffffc0203c5c:	00002617          	auipc	a2,0x2
ffffffffc0203c60:	57c60613          	addi	a2,a2,1404 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203c64:	14e00593          	li	a1,334
ffffffffc0203c68:	00003517          	auipc	a0,0x3
ffffffffc0203c6c:	09050513          	addi	a0,a0,144 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203c70:	fd6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma5 == NULL);
ffffffffc0203c74:	00003697          	auipc	a3,0x3
ffffffffc0203c78:	1fc68693          	addi	a3,a3,508 # ffffffffc0206e70 <etext+0x1668>
ffffffffc0203c7c:	00002617          	auipc	a2,0x2
ffffffffc0203c80:	55c60613          	addi	a2,a2,1372 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203c84:	14c00593          	li	a1,332
ffffffffc0203c88:	00003517          	auipc	a0,0x3
ffffffffc0203c8c:	07050513          	addi	a0,a0,112 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203c90:	fb6fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma4 == NULL);
ffffffffc0203c94:	00003697          	auipc	a3,0x3
ffffffffc0203c98:	1cc68693          	addi	a3,a3,460 # ffffffffc0206e60 <etext+0x1658>
ffffffffc0203c9c:	00002617          	auipc	a2,0x2
ffffffffc0203ca0:	53c60613          	addi	a2,a2,1340 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203ca4:	14a00593          	li	a1,330
ffffffffc0203ca8:	00003517          	auipc	a0,0x3
ffffffffc0203cac:	05050513          	addi	a0,a0,80 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203cb0:	f96fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma3 == NULL);
ffffffffc0203cb4:	00003697          	auipc	a3,0x3
ffffffffc0203cb8:	19c68693          	addi	a3,a3,412 # ffffffffc0206e50 <etext+0x1648>
ffffffffc0203cbc:	00002617          	auipc	a2,0x2
ffffffffc0203cc0:	51c60613          	addi	a2,a2,1308 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203cc4:	14800593          	li	a1,328
ffffffffc0203cc8:	00003517          	auipc	a0,0x3
ffffffffc0203ccc:	03050513          	addi	a0,a0,48 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203cd0:	f76fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc0203cd4:	00003697          	auipc	a3,0x3
ffffffffc0203cd8:	10c68693          	addi	a3,a3,268 # ffffffffc0206de0 <etext+0x15d8>
ffffffffc0203cdc:	00002617          	auipc	a2,0x2
ffffffffc0203ce0:	4fc60613          	addi	a2,a2,1276 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203ce4:	13b00593          	li	a1,315
ffffffffc0203ce8:	00003517          	auipc	a0,0x3
ffffffffc0203cec:	01050513          	addi	a0,a0,16 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203cf0:	f56fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma2 != NULL);
ffffffffc0203cf4:	00003697          	auipc	a3,0x3
ffffffffc0203cf8:	14c68693          	addi	a3,a3,332 # ffffffffc0206e40 <etext+0x1638>
ffffffffc0203cfc:	00002617          	auipc	a2,0x2
ffffffffc0203d00:	4dc60613          	addi	a2,a2,1244 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203d04:	14600593          	li	a1,326
ffffffffc0203d08:	00003517          	auipc	a0,0x3
ffffffffc0203d0c:	ff050513          	addi	a0,a0,-16 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203d10:	f36fc0ef          	jal	ffffffffc0200446 <__panic>
        assert(vma1 != NULL);
ffffffffc0203d14:	00003697          	auipc	a3,0x3
ffffffffc0203d18:	11c68693          	addi	a3,a3,284 # ffffffffc0206e30 <etext+0x1628>
ffffffffc0203d1c:	00002617          	auipc	a2,0x2
ffffffffc0203d20:	4bc60613          	addi	a2,a2,1212 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203d24:	14400593          	li	a1,324
ffffffffc0203d28:	00003517          	auipc	a0,0x3
ffffffffc0203d2c:	fd050513          	addi	a0,a0,-48 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203d30:	f16fc0ef          	jal	ffffffffc0200446 <__panic>
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
ffffffffc0203d34:	6914                	ld	a3,16(a0)
ffffffffc0203d36:	6510                	ld	a2,8(a0)
ffffffffc0203d38:	0004859b          	sext.w	a1,s1
ffffffffc0203d3c:	00003517          	auipc	a0,0x3
ffffffffc0203d40:	1a450513          	addi	a0,a0,420 # ffffffffc0206ee0 <etext+0x16d8>
ffffffffc0203d44:	c50fc0ef          	jal	ffffffffc0200194 <cprintf>
        assert(vma_below_5 == NULL);
ffffffffc0203d48:	00003697          	auipc	a3,0x3
ffffffffc0203d4c:	1c068693          	addi	a3,a3,448 # ffffffffc0206f08 <etext+0x1700>
ffffffffc0203d50:	00002617          	auipc	a2,0x2
ffffffffc0203d54:	48860613          	addi	a2,a2,1160 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0203d58:	15900593          	li	a1,345
ffffffffc0203d5c:	00003517          	auipc	a0,0x3
ffffffffc0203d60:	f9c50513          	addi	a0,a0,-100 # ffffffffc0206cf8 <etext+0x14f0>
ffffffffc0203d64:	ee2fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203d68 <user_mem_check>:
}
bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
ffffffffc0203d68:	7179                	addi	sp,sp,-48
ffffffffc0203d6a:	f022                	sd	s0,32(sp)
ffffffffc0203d6c:	f406                	sd	ra,40(sp)
ffffffffc0203d6e:	842e                	mv	s0,a1
    if (mm != NULL)
ffffffffc0203d70:	c52d                	beqz	a0,ffffffffc0203dda <user_mem_check+0x72>
    {
        if (!USER_ACCESS(addr, addr + len))
ffffffffc0203d72:	002007b7          	lui	a5,0x200
ffffffffc0203d76:	04f5ed63          	bltu	a1,a5,ffffffffc0203dd0 <user_mem_check+0x68>
ffffffffc0203d7a:	ec26                	sd	s1,24(sp)
ffffffffc0203d7c:	00c584b3          	add	s1,a1,a2
ffffffffc0203d80:	0695ff63          	bgeu	a1,s1,ffffffffc0203dfe <user_mem_check+0x96>
ffffffffc0203d84:	4785                	li	a5,1
ffffffffc0203d86:	07fe                	slli	a5,a5,0x1f
ffffffffc0203d88:	0785                	addi	a5,a5,1 # 200001 <_binary_obj___user_exit_out_size+0x1f5e09>
ffffffffc0203d8a:	06f4fa63          	bgeu	s1,a5,ffffffffc0203dfe <user_mem_check+0x96>
ffffffffc0203d8e:	e84a                	sd	s2,16(sp)
ffffffffc0203d90:	e44e                	sd	s3,8(sp)
ffffffffc0203d92:	8936                	mv	s2,a3
ffffffffc0203d94:	89aa                	mv	s3,a0
ffffffffc0203d96:	a829                	j	ffffffffc0203db0 <user_mem_check+0x48>
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203d98:	6685                	lui	a3,0x1
ffffffffc0203d9a:	9736                	add	a4,a4,a3
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203d9c:	0027f693          	andi	a3,a5,2
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203da0:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203da2:	c685                	beqz	a3,ffffffffc0203dca <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK))
ffffffffc0203da4:	c399                	beqz	a5,ffffffffc0203daa <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE)
ffffffffc0203da6:	02e46263          	bltu	s0,a4,ffffffffc0203dca <user_mem_check+0x62>
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0203daa:	6900                	ld	s0,16(a0)
        while (start < end)
ffffffffc0203dac:	04947b63          	bgeu	s0,s1,ffffffffc0203e02 <user_mem_check+0x9a>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
ffffffffc0203db0:	85a2                	mv	a1,s0
ffffffffc0203db2:	854e                	mv	a0,s3
ffffffffc0203db4:	959ff0ef          	jal	ffffffffc020370c <find_vma>
ffffffffc0203db8:	c909                	beqz	a0,ffffffffc0203dca <user_mem_check+0x62>
ffffffffc0203dba:	6518                	ld	a4,8(a0)
ffffffffc0203dbc:	00e46763          	bltu	s0,a4,ffffffffc0203dca <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
ffffffffc0203dc0:	4d1c                	lw	a5,24(a0)
ffffffffc0203dc2:	fc091be3          	bnez	s2,ffffffffc0203d98 <user_mem_check+0x30>
ffffffffc0203dc6:	8b85                	andi	a5,a5,1
ffffffffc0203dc8:	f3ed                	bnez	a5,ffffffffc0203daa <user_mem_check+0x42>
ffffffffc0203dca:	64e2                	ld	s1,24(sp)
ffffffffc0203dcc:	6942                	ld	s2,16(sp)
ffffffffc0203dce:	69a2                	ld	s3,8(sp)
            return 0;
ffffffffc0203dd0:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203dd2:	70a2                	ld	ra,40(sp)
ffffffffc0203dd4:	7402                	ld	s0,32(sp)
ffffffffc0203dd6:	6145                	addi	sp,sp,48
ffffffffc0203dd8:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203dda:	c02007b7          	lui	a5,0xc0200
ffffffffc0203dde:	fef5eae3          	bltu	a1,a5,ffffffffc0203dd2 <user_mem_check+0x6a>
ffffffffc0203de2:	c80007b7          	lui	a5,0xc8000
ffffffffc0203de6:	962e                	add	a2,a2,a1
ffffffffc0203de8:	0785                	addi	a5,a5,1 # ffffffffc8000001 <end+0x7d645d1>
ffffffffc0203dea:	00c5b433          	sltu	s0,a1,a2
ffffffffc0203dee:	00f63633          	sltu	a2,a2,a5
ffffffffc0203df2:	70a2                	ld	ra,40(sp)
    return KERN_ACCESS(addr, addr + len);
ffffffffc0203df4:	00867533          	and	a0,a2,s0
ffffffffc0203df8:	7402                	ld	s0,32(sp)
ffffffffc0203dfa:	6145                	addi	sp,sp,48
ffffffffc0203dfc:	8082                	ret
ffffffffc0203dfe:	64e2                	ld	s1,24(sp)
ffffffffc0203e00:	bfc1                	j	ffffffffc0203dd0 <user_mem_check+0x68>
ffffffffc0203e02:	64e2                	ld	s1,24(sp)
ffffffffc0203e04:	6942                	ld	s2,16(sp)
ffffffffc0203e06:	69a2                	ld	s3,8(sp)
        return 1;
ffffffffc0203e08:	4505                	li	a0,1
ffffffffc0203e0a:	b7e1                	j	ffffffffc0203dd2 <user_mem_check+0x6a>

ffffffffc0203e0c <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0203e0c:	8526                	mv	a0,s1
	jalr s0
ffffffffc0203e0e:	9402                	jalr	s0

	jal do_exit
ffffffffc0203e10:	670000ef          	jal	ffffffffc0204480 <do_exit>

ffffffffc0203e14 <alloc_proc>:
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void)
{
ffffffffc0203e14:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e16:	10800513          	li	a0,264
{
ffffffffc0203e1a:	e022                	sd	s0,0(sp)
ffffffffc0203e1c:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0203e1e:	e9bfd0ef          	jal	ffffffffc0201cb8 <kmalloc>
ffffffffc0203e22:	842a                	mv	s0,a0
    if (proc != NULL)
ffffffffc0203e24:	cd21                	beqz	a0,ffffffffc0203e7c <alloc_proc+0x68>
         *       uintptr_t pgdir;                            // the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */

        proc->state=PROC_UNINIT;
ffffffffc0203e26:	57fd                	li	a5,-1
ffffffffc0203e28:	1782                	slli	a5,a5,0x20
ffffffffc0203e2a:	e11c                	sd	a5,0(a0)
        proc->pid=-1;
        proc->runs=0;
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e2c:	00098797          	auipc	a5,0x98
ffffffffc0203e30:	bbc7b783          	ld	a5,-1092(a5) # ffffffffc029b9e8 <boot_pgdir_pa>
        proc->runs=0;
ffffffffc0203e34:	00052423          	sw	zero,8(a0)
        proc->kstack=0;
ffffffffc0203e38:	00053823          	sd	zero,16(a0)
        proc->pgdir = boot_pgdir_pa;
ffffffffc0203e3c:	f55c                	sd	a5,168(a0)
        proc->need_resched=0;
ffffffffc0203e3e:	00053c23          	sd	zero,24(a0)
        proc->parent = NULL;
ffffffffc0203e42:	02053023          	sd	zero,32(a0)
        proc->mm = NULL;
ffffffffc0203e46:	02053423          	sd	zero,40(a0)
        proc->tf=NULL;
ffffffffc0203e4a:	0a053023          	sd	zero,160(a0)
        proc->flags = 0;
ffffffffc0203e4e:	0a052823          	sw	zero,176(a0)
        memset(&proc->name, 0, PROC_NAME_LEN);
ffffffffc0203e52:	463d                	li	a2,15
ffffffffc0203e54:	4581                	li	a1,0
ffffffffc0203e56:	0b450513          	addi	a0,a0,180
ffffffffc0203e5a:	185010ef          	jal	ffffffffc02057de <memset>
        memset(&proc->context,0,sizeof(struct context));
ffffffffc0203e5e:	03040513          	addi	a0,s0,48
ffffffffc0203e62:	07000613          	li	a2,112
ffffffffc0203e66:	4581                	li	a1,0
ffffffffc0203e68:	177010ef          	jal	ffffffffc02057de <memset>
         * below fields(add in LAB5) in proc_struct need to be initialized
         *       uint32_t wait_state;                        // waiting state
         *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
         */

        proc->wait_state = 0;  
ffffffffc0203e6c:	0e042623          	sw	zero,236(s0)
        //亲属关系指针（cptr/optr/yptr）初始化是为了后续维护进程树（父 - 子、兄 - 弟关系）
        proc->cptr = proc->optr = proc->yptr = NULL;  
ffffffffc0203e70:	0e043c23          	sd	zero,248(s0)
ffffffffc0203e74:	10043023          	sd	zero,256(s0)
ffffffffc0203e78:	0e043823          	sd	zero,240(s0)
    }
    return proc;
}
ffffffffc0203e7c:	60a2                	ld	ra,8(sp)
ffffffffc0203e7e:	8522                	mv	a0,s0
ffffffffc0203e80:	6402                	ld	s0,0(sp)
ffffffffc0203e82:	0141                	addi	sp,sp,16
ffffffffc0203e84:	8082                	ret

ffffffffc0203e86 <forkret>:
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void)
{
    forkrets(current->tf);
ffffffffc0203e86:	00098797          	auipc	a5,0x98
ffffffffc0203e8a:	b927b783          	ld	a5,-1134(a5) # ffffffffc029ba18 <current>
ffffffffc0203e8e:	73c8                	ld	a0,160(a5)
ffffffffc0203e90:	80efd06f          	j	ffffffffc0200e9e <forkrets>

ffffffffc0203e94 <user_main>:
// user_main - kernel thread used to exec a user program
static int
user_main(void *arg)
{
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e94:	00098797          	auipc	a5,0x98
ffffffffc0203e98:	b847b783          	ld	a5,-1148(a5) # ffffffffc029ba18 <current>
{
ffffffffc0203e9c:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203e9e:	00003617          	auipc	a2,0x3
ffffffffc0203ea2:	0ba60613          	addi	a2,a2,186 # ffffffffc0206f58 <etext+0x1750>
ffffffffc0203ea6:	43cc                	lw	a1,4(a5)
ffffffffc0203ea8:	00003517          	auipc	a0,0x3
ffffffffc0203eac:	0c050513          	addi	a0,a0,192 # ffffffffc0206f68 <etext+0x1760>
{
ffffffffc0203eb0:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0203eb2:	ae2fc0ef          	jal	ffffffffc0200194 <cprintf>
ffffffffc0203eb6:	3fe06797          	auipc	a5,0x3fe06
ffffffffc0203eba:	a6278793          	addi	a5,a5,-1438 # 9918 <_binary_obj___user_forktest_out_size>
ffffffffc0203ebe:	e43e                	sd	a5,8(sp)
kernel_execve(const char *name, unsigned char *binary, size_t size)
ffffffffc0203ec0:	00003517          	auipc	a0,0x3
ffffffffc0203ec4:	09850513          	addi	a0,a0,152 # ffffffffc0206f58 <etext+0x1750>
ffffffffc0203ec8:	00040797          	auipc	a5,0x40
ffffffffc0203ecc:	8d078793          	addi	a5,a5,-1840 # ffffffffc0243798 <_binary_obj___user_forktest_out_start>
ffffffffc0203ed0:	f03e                	sd	a5,32(sp)
ffffffffc0203ed2:	f42a                	sd	a0,40(sp)
    int64_t ret = 0, len = strlen(name);
ffffffffc0203ed4:	e802                	sd	zero,16(sp)
ffffffffc0203ed6:	055010ef          	jal	ffffffffc020572a <strlen>
ffffffffc0203eda:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0203edc:	4511                	li	a0,4
ffffffffc0203ede:	55a2                	lw	a1,40(sp)
ffffffffc0203ee0:	4662                	lw	a2,24(sp)
ffffffffc0203ee2:	5682                	lw	a3,32(sp)
ffffffffc0203ee4:	4722                	lw	a4,8(sp)
ffffffffc0203ee6:	48a9                	li	a7,10
ffffffffc0203ee8:	9002                	ebreak
ffffffffc0203eea:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0203eec:	65c2                	ld	a1,16(sp)
ffffffffc0203eee:	00003517          	auipc	a0,0x3
ffffffffc0203ef2:	0a250513          	addi	a0,a0,162 # ffffffffc0206f90 <etext+0x1788>
ffffffffc0203ef6:	a9efc0ef          	jal	ffffffffc0200194 <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0203efa:	00003617          	auipc	a2,0x3
ffffffffc0203efe:	0a660613          	addi	a2,a2,166 # ffffffffc0206fa0 <etext+0x1798>
ffffffffc0203f02:	3c200593          	li	a1,962
ffffffffc0203f06:	00003517          	auipc	a0,0x3
ffffffffc0203f0a:	0ba50513          	addi	a0,a0,186 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0203f0e:	d38fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f12 <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0203f12:	6d14                	ld	a3,24(a0)
{
ffffffffc0203f14:	1141                	addi	sp,sp,-16
ffffffffc0203f16:	e406                	sd	ra,8(sp)
ffffffffc0203f18:	c02007b7          	lui	a5,0xc0200
ffffffffc0203f1c:	02f6ee63          	bltu	a3,a5,ffffffffc0203f58 <put_pgdir+0x46>
ffffffffc0203f20:	00098717          	auipc	a4,0x98
ffffffffc0203f24:	ad873703          	ld	a4,-1320(a4) # ffffffffc029b9f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc0203f28:	00098797          	auipc	a5,0x98
ffffffffc0203f2c:	ad87b783          	ld	a5,-1320(a5) # ffffffffc029ba00 <npage>
    return pa2page(PADDR(kva));
ffffffffc0203f30:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0203f32:	82b1                	srli	a3,a3,0xc
ffffffffc0203f34:	02f6fe63          	bgeu	a3,a5,ffffffffc0203f70 <put_pgdir+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc0203f38:	00004797          	auipc	a5,0x4
ffffffffc0203f3c:	a307b783          	ld	a5,-1488(a5) # ffffffffc0207968 <nbase>
ffffffffc0203f40:	00098517          	auipc	a0,0x98
ffffffffc0203f44:	ac853503          	ld	a0,-1336(a0) # ffffffffc029ba08 <pages>
}
ffffffffc0203f48:	60a2                	ld	ra,8(sp)
ffffffffc0203f4a:	8e9d                	sub	a3,a3,a5
ffffffffc0203f4c:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0203f4e:	4585                	li	a1,1
ffffffffc0203f50:	9536                	add	a0,a0,a3
}
ffffffffc0203f52:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0203f54:	f61fd06f          	j	ffffffffc0201eb4 <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0203f58:	00002617          	auipc	a2,0x2
ffffffffc0203f5c:	6d860613          	addi	a2,a2,1752 # ffffffffc0206630 <etext+0xe28>
ffffffffc0203f60:	07700593          	li	a1,119
ffffffffc0203f64:	00002517          	auipc	a0,0x2
ffffffffc0203f68:	64c50513          	addi	a0,a0,1612 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0203f6c:	cdafc0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0203f70:	00002617          	auipc	a2,0x2
ffffffffc0203f74:	6e860613          	addi	a2,a2,1768 # ffffffffc0206658 <etext+0xe50>
ffffffffc0203f78:	06900593          	li	a1,105
ffffffffc0203f7c:	00002517          	auipc	a0,0x2
ffffffffc0203f80:	63450513          	addi	a0,a0,1588 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0203f84:	cc2fc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0203f88 <proc_run>:
    if (proc != current)
ffffffffc0203f88:	00098697          	auipc	a3,0x98
ffffffffc0203f8c:	a906b683          	ld	a3,-1392(a3) # ffffffffc029ba18 <current>
ffffffffc0203f90:	04a68463          	beq	a3,a0,ffffffffc0203fd8 <proc_run+0x50>
{
ffffffffc0203f94:	1101                	addi	sp,sp,-32
ffffffffc0203f96:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203f98:	100027f3          	csrr	a5,sstatus
ffffffffc0203f9c:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0203f9e:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0203fa0:	ef8d                	bnez	a5,ffffffffc0203fda <proc_run+0x52>
#define barrier() __asm__ __volatile__("fence" ::: "memory")

static inline void
lsatp(unsigned long pgdir)
{
  write_csr(satp, 0x8000000000000000 | (pgdir >> RISCV_PGSHIFT));
ffffffffc0203fa2:	755c                	ld	a5,168(a0)
ffffffffc0203fa4:	577d                	li	a4,-1
ffffffffc0203fa6:	177e                	slli	a4,a4,0x3f
ffffffffc0203fa8:	83b1                	srli	a5,a5,0xc
ffffffffc0203faa:	e032                	sd	a2,0(sp)
             current = proc;
ffffffffc0203fac:	00098597          	auipc	a1,0x98
ffffffffc0203fb0:	a6a5b623          	sd	a0,-1428(a1) # ffffffffc029ba18 <current>
ffffffffc0203fb4:	8fd9                	or	a5,a5,a4
ffffffffc0203fb6:	18079073          	csrw	satp,a5
             switch_to(&(prev->context), &(next->context));
ffffffffc0203fba:	03050593          	addi	a1,a0,48
ffffffffc0203fbe:	03068513          	addi	a0,a3,48
ffffffffc0203fc2:	120010ef          	jal	ffffffffc02050e2 <switch_to>
    if (flag)
ffffffffc0203fc6:	6602                	ld	a2,0(sp)
ffffffffc0203fc8:	e601                	bnez	a2,ffffffffc0203fd0 <proc_run+0x48>
}
ffffffffc0203fca:	60e2                	ld	ra,24(sp)
ffffffffc0203fcc:	6105                	addi	sp,sp,32
ffffffffc0203fce:	8082                	ret
ffffffffc0203fd0:	60e2                	ld	ra,24(sp)
ffffffffc0203fd2:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0203fd4:	92bfc06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0203fd8:	8082                	ret
ffffffffc0203fda:	e42a                	sd	a0,8(sp)
ffffffffc0203fdc:	e036                	sd	a3,0(sp)
        intr_disable();
ffffffffc0203fde:	927fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0203fe2:	6522                	ld	a0,8(sp)
ffffffffc0203fe4:	6682                	ld	a3,0(sp)
ffffffffc0203fe6:	4605                	li	a2,1
ffffffffc0203fe8:	bf6d                	j	ffffffffc0203fa2 <proc_run+0x1a>

ffffffffc0203fea <do_fork>:
    if (nr_process >= MAX_PROCESS)
ffffffffc0203fea:	00098717          	auipc	a4,0x98
ffffffffc0203fee:	a2672703          	lw	a4,-1498(a4) # ffffffffc029ba10 <nr_process>
ffffffffc0203ff2:	6785                	lui	a5,0x1
ffffffffc0203ff4:	36f75d63          	bge	a4,a5,ffffffffc020436e <do_fork+0x384>
{
ffffffffc0203ff8:	711d                	addi	sp,sp,-96
ffffffffc0203ffa:	e8a2                	sd	s0,80(sp)
ffffffffc0203ffc:	e4a6                	sd	s1,72(sp)
ffffffffc0203ffe:	e0ca                	sd	s2,64(sp)
ffffffffc0204000:	e06a                	sd	s10,0(sp)
ffffffffc0204002:	ec86                	sd	ra,88(sp)
ffffffffc0204004:	892e                	mv	s2,a1
ffffffffc0204006:	84b2                	mv	s1,a2
ffffffffc0204008:	8d2a                	mv	s10,a0
    if ((proc = alloc_proc()) == NULL) {
ffffffffc020400a:	e0bff0ef          	jal	ffffffffc0203e14 <alloc_proc>
ffffffffc020400e:	842a                	mv	s0,a0
ffffffffc0204010:	30050063          	beqz	a0,ffffffffc0204310 <do_fork+0x326>
    proc->parent = current;  
ffffffffc0204014:	f05a                	sd	s6,32(sp)
ffffffffc0204016:	00098b17          	auipc	s6,0x98
ffffffffc020401a:	a02b0b13          	addi	s6,s6,-1534 # ffffffffc029ba18 <current>
ffffffffc020401e:	000b3783          	ld	a5,0(s6)
    assert(current->wait_state == 0); 
ffffffffc0204022:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_softint_out_size-0x7b1c>
    proc->parent = current;  
ffffffffc0204026:	f11c                	sd	a5,32(a0)
    assert(current->wait_state == 0); 
ffffffffc0204028:	3c071263          	bnez	a4,ffffffffc02043ec <do_fork+0x402>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc020402c:	4509                	li	a0,2
ffffffffc020402e:	e4dfd0ef          	jal	ffffffffc0201e7a <alloc_pages>
    if (page != NULL)
ffffffffc0204032:	2c050b63          	beqz	a0,ffffffffc0204308 <do_fork+0x31e>
ffffffffc0204036:	fc4e                	sd	s3,56(sp)
    return page - pages + nbase;
ffffffffc0204038:	00098997          	auipc	s3,0x98
ffffffffc020403c:	9d098993          	addi	s3,s3,-1584 # ffffffffc029ba08 <pages>
ffffffffc0204040:	0009b783          	ld	a5,0(s3)
ffffffffc0204044:	f852                	sd	s4,48(sp)
ffffffffc0204046:	00004a17          	auipc	s4,0x4
ffffffffc020404a:	922a0a13          	addi	s4,s4,-1758 # ffffffffc0207968 <nbase>
ffffffffc020404e:	e466                	sd	s9,8(sp)
ffffffffc0204050:	000a3c83          	ld	s9,0(s4)
ffffffffc0204054:	40f506b3          	sub	a3,a0,a5
ffffffffc0204058:	f456                	sd	s5,40(sp)
    return KADDR(page2pa(page));
ffffffffc020405a:	00098a97          	auipc	s5,0x98
ffffffffc020405e:	9a6a8a93          	addi	s5,s5,-1626 # ffffffffc029ba00 <npage>
ffffffffc0204062:	e862                	sd	s8,16(sp)
    return page - pages + nbase;
ffffffffc0204064:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204066:	5c7d                	li	s8,-1
ffffffffc0204068:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc020406c:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc020406e:	00cc5c13          	srli	s8,s8,0xc
ffffffffc0204072:	0186f733          	and	a4,a3,s8
ffffffffc0204076:	ec5e                	sd	s7,24(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc0204078:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020407a:	30f77863          	bgeu	a4,a5,ffffffffc020438a <do_fork+0x3a0>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020407e:	000b3703          	ld	a4,0(s6)
ffffffffc0204082:	00098b17          	auipc	s6,0x98
ffffffffc0204086:	976b0b13          	addi	s6,s6,-1674 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc020408a:	000b3783          	ld	a5,0(s6)
ffffffffc020408e:	02873b83          	ld	s7,40(a4)
ffffffffc0204092:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0204094:	e814                	sd	a3,16(s0)
    if (oldmm == NULL)
ffffffffc0204096:	020b8863          	beqz	s7,ffffffffc02040c6 <do_fork+0xdc>
    if (clone_flags & CLONE_VM)
ffffffffc020409a:	100d7793          	andi	a5,s10,256
ffffffffc020409e:	18078b63          	beqz	a5,ffffffffc0204234 <do_fork+0x24a>
}

static inline int
mm_count_inc(struct mm_struct *mm)
{
    mm->mm_count += 1;
ffffffffc02040a2:	030ba703          	lw	a4,48(s7)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040a6:	018bb783          	ld	a5,24(s7)
ffffffffc02040aa:	c02006b7          	lui	a3,0xc0200
ffffffffc02040ae:	2705                	addiw	a4,a4,1
ffffffffc02040b0:	02eba823          	sw	a4,48(s7)
    proc->mm = mm;
ffffffffc02040b4:	03743423          	sd	s7,40(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040b8:	2ed7e563          	bltu	a5,a3,ffffffffc02043a2 <do_fork+0x3b8>
ffffffffc02040bc:	000b3703          	ld	a4,0(s6)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040c0:	6814                	ld	a3,16(s0)
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02040c2:	8f99                	sub	a5,a5,a4
ffffffffc02040c4:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040c6:	6789                	lui	a5,0x2
ffffffffc02040c8:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_softint_out_size-0x6d28>
ffffffffc02040cc:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc02040ce:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc02040d0:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc02040d2:	87b6                	mv	a5,a3
ffffffffc02040d4:	12048713          	addi	a4,s1,288
ffffffffc02040d8:	6a0c                	ld	a1,16(a2)
ffffffffc02040da:	00063803          	ld	a6,0(a2)
ffffffffc02040de:	6608                	ld	a0,8(a2)
ffffffffc02040e0:	eb8c                	sd	a1,16(a5)
ffffffffc02040e2:	0107b023          	sd	a6,0(a5)
ffffffffc02040e6:	e788                	sd	a0,8(a5)
ffffffffc02040e8:	6e0c                	ld	a1,24(a2)
ffffffffc02040ea:	02060613          	addi	a2,a2,32
ffffffffc02040ee:	02078793          	addi	a5,a5,32
ffffffffc02040f2:	feb7bc23          	sd	a1,-8(a5)
ffffffffc02040f6:	fee611e3          	bne	a2,a4,ffffffffc02040d8 <do_fork+0xee>
    proc->tf->gpr.a0 = 0;
ffffffffc02040fa:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x6>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02040fe:	20090b63          	beqz	s2,ffffffffc0204314 <do_fork+0x32a>
ffffffffc0204102:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204106:	00000797          	auipc	a5,0x0
ffffffffc020410a:	d8078793          	addi	a5,a5,-640 # ffffffffc0203e86 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc020410e:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204110:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204112:	100027f3          	csrr	a5,sstatus
ffffffffc0204116:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204118:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020411a:	20079c63          	bnez	a5,ffffffffc0204332 <do_fork+0x348>
    if (++last_pid >= MAX_PID)
ffffffffc020411e:	00093517          	auipc	a0,0x93
ffffffffc0204122:	46652503          	lw	a0,1126(a0) # ffffffffc0297584 <last_pid.1>
ffffffffc0204126:	6789                	lui	a5,0x2
ffffffffc0204128:	2505                	addiw	a0,a0,1
ffffffffc020412a:	00093717          	auipc	a4,0x93
ffffffffc020412e:	44a72d23          	sw	a0,1114(a4) # ffffffffc0297584 <last_pid.1>
ffffffffc0204132:	20f55f63          	bge	a0,a5,ffffffffc0204350 <do_fork+0x366>
    if (last_pid >= next_safe)
ffffffffc0204136:	00093797          	auipc	a5,0x93
ffffffffc020413a:	44a7a783          	lw	a5,1098(a5) # ffffffffc0297580 <next_safe.0>
ffffffffc020413e:	00098497          	auipc	s1,0x98
ffffffffc0204142:	86248493          	addi	s1,s1,-1950 # ffffffffc029b9a0 <proc_list>
ffffffffc0204146:	06f54563          	blt	a0,a5,ffffffffc02041b0 <do_fork+0x1c6>
ffffffffc020414a:	00098497          	auipc	s1,0x98
ffffffffc020414e:	85648493          	addi	s1,s1,-1962 # ffffffffc029b9a0 <proc_list>
ffffffffc0204152:	0084b883          	ld	a7,8(s1)
        next_safe = MAX_PID;
ffffffffc0204156:	6789                	lui	a5,0x2
ffffffffc0204158:	00093717          	auipc	a4,0x93
ffffffffc020415c:	42f72423          	sw	a5,1064(a4) # ffffffffc0297580 <next_safe.0>
ffffffffc0204160:	86aa                	mv	a3,a0
ffffffffc0204162:	4581                	li	a1,0
        while ((le = list_next(le)) != list)
ffffffffc0204164:	04988063          	beq	a7,s1,ffffffffc02041a4 <do_fork+0x1ba>
ffffffffc0204168:	882e                	mv	a6,a1
ffffffffc020416a:	87c6                	mv	a5,a7
ffffffffc020416c:	6609                	lui	a2,0x2
ffffffffc020416e:	a811                	j	ffffffffc0204182 <do_fork+0x198>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc0204170:	00e6d663          	bge	a3,a4,ffffffffc020417c <do_fork+0x192>
ffffffffc0204174:	00c75463          	bge	a4,a2,ffffffffc020417c <do_fork+0x192>
                next_safe = proc->pid;
ffffffffc0204178:	863a                	mv	a2,a4
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc020417a:	4805                	li	a6,1
ffffffffc020417c:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc020417e:	00978d63          	beq	a5,s1,ffffffffc0204198 <do_fork+0x1ae>
            if (proc->pid == last_pid)
ffffffffc0204182:	f3c7a703          	lw	a4,-196(a5) # 1f3c <_binary_obj___user_softint_out_size-0x6ccc>
ffffffffc0204186:	fed715e3          	bne	a4,a3,ffffffffc0204170 <do_fork+0x186>
                if (++last_pid >= next_safe)
ffffffffc020418a:	2685                	addiw	a3,a3,1
ffffffffc020418c:	1cc6db63          	bge	a3,a2,ffffffffc0204362 <do_fork+0x378>
ffffffffc0204190:	679c                	ld	a5,8(a5)
ffffffffc0204192:	4585                	li	a1,1
        while ((le = list_next(le)) != list)
ffffffffc0204194:	fe9797e3          	bne	a5,s1,ffffffffc0204182 <do_fork+0x198>
ffffffffc0204198:	00080663          	beqz	a6,ffffffffc02041a4 <do_fork+0x1ba>
ffffffffc020419c:	00093797          	auipc	a5,0x93
ffffffffc02041a0:	3ec7a223          	sw	a2,996(a5) # ffffffffc0297580 <next_safe.0>
ffffffffc02041a4:	c591                	beqz	a1,ffffffffc02041b0 <do_fork+0x1c6>
ffffffffc02041a6:	00093797          	auipc	a5,0x93
ffffffffc02041aa:	3cd7af23          	sw	a3,990(a5) # ffffffffc0297584 <last_pid.1>
            else if (proc->pid > last_pid && next_safe > proc->pid)
ffffffffc02041ae:	8536                	mv	a0,a3
        proc->pid = get_pid();
ffffffffc02041b0:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc02041b2:	45a9                	li	a1,10
ffffffffc02041b4:	194010ef          	jal	ffffffffc0205348 <hash32>
ffffffffc02041b8:	02051793          	slli	a5,a0,0x20
ffffffffc02041bc:	01c7d513          	srli	a0,a5,0x1c
ffffffffc02041c0:	00093797          	auipc	a5,0x93
ffffffffc02041c4:	7e078793          	addi	a5,a5,2016 # ffffffffc02979a0 <hash_list>
ffffffffc02041c8:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc02041ca:	6518                	ld	a4,8(a0)
ffffffffc02041cc:	0d840793          	addi	a5,s0,216
ffffffffc02041d0:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc02041d2:	e31c                	sd	a5,0(a4)
ffffffffc02041d4:	e51c                	sd	a5,8(a0)
    elm->next = next;
ffffffffc02041d6:	f078                	sd	a4,224(s0)
    list_add(&proc_list, &(proc->list_link));
ffffffffc02041d8:	0c840793          	addi	a5,s0,200
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041dc:	7018                	ld	a4,32(s0)
    elm->prev = prev;
ffffffffc02041de:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc02041e0:	e21c                	sd	a5,0(a2)
    proc->yptr = NULL;
ffffffffc02041e2:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL)
ffffffffc02041e6:	7b74                	ld	a3,240(a4)
ffffffffc02041e8:	e49c                	sd	a5,8(s1)
    elm->next = next;
ffffffffc02041ea:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc02041ec:	e464                	sd	s1,200(s0)
ffffffffc02041ee:	10d43023          	sd	a3,256(s0)
ffffffffc02041f2:	c299                	beqz	a3,ffffffffc02041f8 <do_fork+0x20e>
        proc->optr->yptr = proc;
ffffffffc02041f4:	fee0                	sd	s0,248(a3)
    proc->parent->cptr = proc;
ffffffffc02041f6:	7018                	ld	a4,32(s0)
    nr_process++;
ffffffffc02041f8:	00098797          	auipc	a5,0x98
ffffffffc02041fc:	8187a783          	lw	a5,-2024(a5) # ffffffffc029ba10 <nr_process>
    proc->parent->cptr = proc;
ffffffffc0204200:	fb60                	sd	s0,240(a4)
    nr_process++;
ffffffffc0204202:	2785                	addiw	a5,a5,1
ffffffffc0204204:	00098717          	auipc	a4,0x98
ffffffffc0204208:	80f72623          	sw	a5,-2036(a4) # ffffffffc029ba10 <nr_process>
    if (flag)
ffffffffc020420c:	14091863          	bnez	s2,ffffffffc020435c <do_fork+0x372>
    wakeup_proc(proc);
ffffffffc0204210:	8522                	mv	a0,s0
ffffffffc0204212:	73b000ef          	jal	ffffffffc020514c <wakeup_proc>
    ret=proc->pid;
ffffffffc0204216:	4048                	lw	a0,4(s0)
ffffffffc0204218:	79e2                	ld	s3,56(sp)
ffffffffc020421a:	7a42                	ld	s4,48(sp)
ffffffffc020421c:	7aa2                	ld	s5,40(sp)
ffffffffc020421e:	7b02                	ld	s6,32(sp)
ffffffffc0204220:	6be2                	ld	s7,24(sp)
ffffffffc0204222:	6c42                	ld	s8,16(sp)
ffffffffc0204224:	6ca2                	ld	s9,8(sp)
}
ffffffffc0204226:	60e6                	ld	ra,88(sp)
ffffffffc0204228:	6446                	ld	s0,80(sp)
ffffffffc020422a:	64a6                	ld	s1,72(sp)
ffffffffc020422c:	6906                	ld	s2,64(sp)
ffffffffc020422e:	6d02                	ld	s10,0(sp)
ffffffffc0204230:	6125                	addi	sp,sp,96
ffffffffc0204232:	8082                	ret
    if ((mm = mm_create()) == NULL)
ffffffffc0204234:	ca8ff0ef          	jal	ffffffffc02036dc <mm_create>
ffffffffc0204238:	8d2a                	mv	s10,a0
ffffffffc020423a:	c949                	beqz	a0,ffffffffc02042cc <do_fork+0x2e2>
    if ((page = alloc_page()) == NULL)
ffffffffc020423c:	4505                	li	a0,1
ffffffffc020423e:	c3dfd0ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0204242:	c151                	beqz	a0,ffffffffc02042c6 <do_fork+0x2dc>
    return page - pages + nbase;
ffffffffc0204244:	0009b703          	ld	a4,0(s3)
    return KADDR(page2pa(page));
ffffffffc0204248:	000ab783          	ld	a5,0(s5)
    return page - pages + nbase;
ffffffffc020424c:	40e506b3          	sub	a3,a0,a4
ffffffffc0204250:	8699                	srai	a3,a3,0x6
ffffffffc0204252:	96e6                	add	a3,a3,s9
    return KADDR(page2pa(page));
ffffffffc0204254:	0186fc33          	and	s8,a3,s8
    return page2ppn(page) << PGSHIFT;
ffffffffc0204258:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020425a:	1afc7f63          	bgeu	s8,a5,ffffffffc0204418 <do_fork+0x42e>
ffffffffc020425e:	000b3783          	ld	a5,0(s6)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc0204262:	00097597          	auipc	a1,0x97
ffffffffc0204266:	78e5b583          	ld	a1,1934(a1) # ffffffffc029b9f0 <boot_pgdir_va>
ffffffffc020426a:	6605                	lui	a2,0x1
ffffffffc020426c:	00f68c33          	add	s8,a3,a5
ffffffffc0204270:	8562                	mv	a0,s8
ffffffffc0204272:	57e010ef          	jal	ffffffffc02057f0 <memcpy>
static inline void
lock_mm(struct mm_struct *mm)
{
    if (mm != NULL)
    {
        lock(&(mm->mm_lock));
ffffffffc0204276:	038b8c93          	addi	s9,s7,56
    mm->pgdir = pgdir;
ffffffffc020427a:	018d3c23          	sd	s8,24(s10) # fffffffffff80018 <end+0x3fce45e8>
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020427e:	4c05                	li	s8,1
ffffffffc0204280:	418cb7af          	amoor.d	a5,s8,(s9)
}

static inline void
lock(lock_t *lock)
{
    while (!try_lock(lock))
ffffffffc0204284:	03f79713          	slli	a4,a5,0x3f
ffffffffc0204288:	03f75793          	srli	a5,a4,0x3f
ffffffffc020428c:	cb91                	beqz	a5,ffffffffc02042a0 <do_fork+0x2b6>
    {
        schedule();
ffffffffc020428e:	753000ef          	jal	ffffffffc02051e0 <schedule>
ffffffffc0204292:	418cb7af          	amoor.d	a5,s8,(s9)
    while (!try_lock(lock))
ffffffffc0204296:	03f79713          	slli	a4,a5,0x3f
ffffffffc020429a:	03f75793          	srli	a5,a4,0x3f
ffffffffc020429e:	fbe5                	bnez	a5,ffffffffc020428e <do_fork+0x2a4>
        ret = dup_mmap(mm, oldmm);
ffffffffc02042a0:	85de                	mv	a1,s7
ffffffffc02042a2:	856a                	mv	a0,s10
ffffffffc02042a4:	e94ff0ef          	jal	ffffffffc0203938 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02042a8:	57f9                	li	a5,-2
ffffffffc02042aa:	60fcb7af          	amoand.d	a5,a5,(s9)
ffffffffc02042ae:	8b85                	andi	a5,a5,1
}

static inline void
unlock(lock_t *lock)
{
    if (!test_and_clear_bit(0, lock))
ffffffffc02042b0:	12078263          	beqz	a5,ffffffffc02043d4 <do_fork+0x3ea>
    if ((mm = mm_create()) == NULL)
ffffffffc02042b4:	8bea                	mv	s7,s10
    if (ret != 0)
ffffffffc02042b6:	de0506e3          	beqz	a0,ffffffffc02040a2 <do_fork+0xb8>
    exit_mmap(mm);
ffffffffc02042ba:	856a                	mv	a0,s10
ffffffffc02042bc:	f14ff0ef          	jal	ffffffffc02039d0 <exit_mmap>
    put_pgdir(mm);
ffffffffc02042c0:	856a                	mv	a0,s10
ffffffffc02042c2:	c51ff0ef          	jal	ffffffffc0203f12 <put_pgdir>
    mm_destroy(mm);
ffffffffc02042c6:	856a                	mv	a0,s10
ffffffffc02042c8:	d52ff0ef          	jal	ffffffffc020381a <mm_destroy>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02042cc:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc02042ce:	c02007b7          	lui	a5,0xc0200
ffffffffc02042d2:	0ef6e563          	bltu	a3,a5,ffffffffc02043bc <do_fork+0x3d2>
ffffffffc02042d6:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage)
ffffffffc02042da:	000ab703          	ld	a4,0(s5)
    return pa2page(PADDR(kva));
ffffffffc02042de:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage)
ffffffffc02042e2:	83b1                	srli	a5,a5,0xc
ffffffffc02042e4:	08e7f763          	bgeu	a5,a4,ffffffffc0204372 <do_fork+0x388>
    return &pages[PPN(pa) - nbase];
ffffffffc02042e8:	000a3703          	ld	a4,0(s4)
ffffffffc02042ec:	0009b503          	ld	a0,0(s3)
ffffffffc02042f0:	4589                	li	a1,2
ffffffffc02042f2:	8f99                	sub	a5,a5,a4
ffffffffc02042f4:	079a                	slli	a5,a5,0x6
ffffffffc02042f6:	953e                	add	a0,a0,a5
ffffffffc02042f8:	bbdfd0ef          	jal	ffffffffc0201eb4 <free_pages>
}
ffffffffc02042fc:	79e2                	ld	s3,56(sp)
ffffffffc02042fe:	7a42                	ld	s4,48(sp)
ffffffffc0204300:	7aa2                	ld	s5,40(sp)
ffffffffc0204302:	6be2                	ld	s7,24(sp)
ffffffffc0204304:	6c42                	ld	s8,16(sp)
ffffffffc0204306:	6ca2                	ld	s9,8(sp)
    kfree(proc);
ffffffffc0204308:	8522                	mv	a0,s0
ffffffffc020430a:	a55fd0ef          	jal	ffffffffc0201d5e <kfree>
ffffffffc020430e:	7b02                	ld	s6,32(sp)
    ret = -E_NO_MEM;
ffffffffc0204310:	5571                	li	a0,-4
    return ret;
ffffffffc0204312:	bf11                	j	ffffffffc0204226 <do_fork+0x23c>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0204314:	8936                	mv	s2,a3
ffffffffc0204316:	0126b823          	sd	s2,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc020431a:	00000797          	auipc	a5,0x0
ffffffffc020431e:	b6c78793          	addi	a5,a5,-1172 # ffffffffc0203e86 <forkret>
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc0204322:	fc14                	sd	a3,56(s0)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0204324:	f81c                	sd	a5,48(s0)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204326:	100027f3          	csrr	a5,sstatus
ffffffffc020432a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020432c:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020432e:	de0788e3          	beqz	a5,ffffffffc020411e <do_fork+0x134>
        intr_disable();
ffffffffc0204332:	dd2fc0ef          	jal	ffffffffc0200904 <intr_disable>
    if (++last_pid >= MAX_PID)
ffffffffc0204336:	00093517          	auipc	a0,0x93
ffffffffc020433a:	24e52503          	lw	a0,590(a0) # ffffffffc0297584 <last_pid.1>
ffffffffc020433e:	6789                	lui	a5,0x2
        return 1;
ffffffffc0204340:	4905                	li	s2,1
ffffffffc0204342:	2505                	addiw	a0,a0,1
ffffffffc0204344:	00093717          	auipc	a4,0x93
ffffffffc0204348:	24a72023          	sw	a0,576(a4) # ffffffffc0297584 <last_pid.1>
ffffffffc020434c:	def545e3          	blt	a0,a5,ffffffffc0204136 <do_fork+0x14c>
        last_pid = 1;
ffffffffc0204350:	4505                	li	a0,1
ffffffffc0204352:	00093797          	auipc	a5,0x93
ffffffffc0204356:	22a7a923          	sw	a0,562(a5) # ffffffffc0297584 <last_pid.1>
        goto inside;
ffffffffc020435a:	bbc5                	j	ffffffffc020414a <do_fork+0x160>
        intr_enable();
ffffffffc020435c:	da2fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204360:	bd45                	j	ffffffffc0204210 <do_fork+0x226>
                    if (last_pid >= MAX_PID)
ffffffffc0204362:	6789                	lui	a5,0x2
ffffffffc0204364:	00f6c363          	blt	a3,a5,ffffffffc020436a <do_fork+0x380>
                        last_pid = 1;
ffffffffc0204368:	4685                	li	a3,1
                    goto repeat;
ffffffffc020436a:	4585                	li	a1,1
ffffffffc020436c:	bbe5                	j	ffffffffc0204164 <do_fork+0x17a>
    int ret = -E_NO_FREE_PROC;
ffffffffc020436e:	556d                	li	a0,-5
}
ffffffffc0204370:	8082                	ret
        panic("pa2page called with invalid pa");
ffffffffc0204372:	00002617          	auipc	a2,0x2
ffffffffc0204376:	2e660613          	addi	a2,a2,742 # ffffffffc0206658 <etext+0xe50>
ffffffffc020437a:	06900593          	li	a1,105
ffffffffc020437e:	00002517          	auipc	a0,0x2
ffffffffc0204382:	23250513          	addi	a0,a0,562 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0204386:	8c0fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc020438a:	00002617          	auipc	a2,0x2
ffffffffc020438e:	1fe60613          	addi	a2,a2,510 # ffffffffc0206588 <etext+0xd80>
ffffffffc0204392:	07100593          	li	a1,113
ffffffffc0204396:	00002517          	auipc	a0,0x2
ffffffffc020439a:	21a50513          	addi	a0,a0,538 # ffffffffc02065b0 <etext+0xda8>
ffffffffc020439e:	8a8fc0ef          	jal	ffffffffc0200446 <__panic>
    proc->pgdir = PADDR(mm->pgdir);
ffffffffc02043a2:	86be                	mv	a3,a5
ffffffffc02043a4:	00002617          	auipc	a2,0x2
ffffffffc02043a8:	28c60613          	addi	a2,a2,652 # ffffffffc0206630 <etext+0xe28>
ffffffffc02043ac:	18f00593          	li	a1,399
ffffffffc02043b0:	00003517          	auipc	a0,0x3
ffffffffc02043b4:	c1050513          	addi	a0,a0,-1008 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02043b8:	88efc0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02043bc:	00002617          	auipc	a2,0x2
ffffffffc02043c0:	27460613          	addi	a2,a2,628 # ffffffffc0206630 <etext+0xe28>
ffffffffc02043c4:	07700593          	li	a1,119
ffffffffc02043c8:	00002517          	auipc	a0,0x2
ffffffffc02043cc:	1e850513          	addi	a0,a0,488 # ffffffffc02065b0 <etext+0xda8>
ffffffffc02043d0:	876fc0ef          	jal	ffffffffc0200446 <__panic>
    {
        panic("Unlock failed.\n");
ffffffffc02043d4:	00003617          	auipc	a2,0x3
ffffffffc02043d8:	c2460613          	addi	a2,a2,-988 # ffffffffc0206ff8 <etext+0x17f0>
ffffffffc02043dc:	03f00593          	li	a1,63
ffffffffc02043e0:	00003517          	auipc	a0,0x3
ffffffffc02043e4:	c2850513          	addi	a0,a0,-984 # ffffffffc0207008 <etext+0x1800>
ffffffffc02043e8:	85efc0ef          	jal	ffffffffc0200446 <__panic>
    assert(current->wait_state == 0); 
ffffffffc02043ec:	00003697          	auipc	a3,0x3
ffffffffc02043f0:	bec68693          	addi	a3,a3,-1044 # ffffffffc0206fd8 <etext+0x17d0>
ffffffffc02043f4:	00002617          	auipc	a2,0x2
ffffffffc02043f8:	de460613          	addi	a2,a2,-540 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02043fc:	1d300593          	li	a1,467
ffffffffc0204400:	00003517          	auipc	a0,0x3
ffffffffc0204404:	bc050513          	addi	a0,a0,-1088 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204408:	fc4e                	sd	s3,56(sp)
ffffffffc020440a:	f852                	sd	s4,48(sp)
ffffffffc020440c:	f456                	sd	s5,40(sp)
ffffffffc020440e:	ec5e                	sd	s7,24(sp)
ffffffffc0204410:	e862                	sd	s8,16(sp)
ffffffffc0204412:	e466                	sd	s9,8(sp)
ffffffffc0204414:	832fc0ef          	jal	ffffffffc0200446 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204418:	00002617          	auipc	a2,0x2
ffffffffc020441c:	17060613          	addi	a2,a2,368 # ffffffffc0206588 <etext+0xd80>
ffffffffc0204420:	07100593          	li	a1,113
ffffffffc0204424:	00002517          	auipc	a0,0x2
ffffffffc0204428:	18c50513          	addi	a0,a0,396 # ffffffffc02065b0 <etext+0xda8>
ffffffffc020442c:	81afc0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204430 <kernel_thread>:
{
ffffffffc0204430:	7129                	addi	sp,sp,-320
ffffffffc0204432:	fa22                	sd	s0,304(sp)
ffffffffc0204434:	f626                	sd	s1,296(sp)
ffffffffc0204436:	f24a                	sd	s2,288(sp)
ffffffffc0204438:	842a                	mv	s0,a0
ffffffffc020443a:	84ae                	mv	s1,a1
ffffffffc020443c:	8932                	mv	s2,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020443e:	850a                	mv	a0,sp
ffffffffc0204440:	12000613          	li	a2,288
ffffffffc0204444:	4581                	li	a1,0
{
ffffffffc0204446:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0204448:	396010ef          	jal	ffffffffc02057de <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc020444c:	e0a2                	sd	s0,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc020444e:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0204450:	100027f3          	csrr	a5,sstatus
ffffffffc0204454:	edd7f793          	andi	a5,a5,-291
ffffffffc0204458:	1207e793          	ori	a5,a5,288
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020445c:	860a                	mv	a2,sp
ffffffffc020445e:	10096513          	ori	a0,s2,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc0204462:	00000717          	auipc	a4,0x0
ffffffffc0204466:	9aa70713          	addi	a4,a4,-1622 # ffffffffc0203e0c <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc020446a:	4581                	li	a1,0
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc020446c:	e23e                	sd	a5,256(sp)
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc020446e:	e63a                	sd	a4,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc0204470:	b7bff0ef          	jal	ffffffffc0203fea <do_fork>
}
ffffffffc0204474:	70f2                	ld	ra,312(sp)
ffffffffc0204476:	7452                	ld	s0,304(sp)
ffffffffc0204478:	74b2                	ld	s1,296(sp)
ffffffffc020447a:	7912                	ld	s2,288(sp)
ffffffffc020447c:	6131                	addi	sp,sp,320
ffffffffc020447e:	8082                	ret

ffffffffc0204480 <do_exit>:
{
ffffffffc0204480:	7179                	addi	sp,sp,-48
ffffffffc0204482:	f022                	sd	s0,32(sp)
    if (current == idleproc)
ffffffffc0204484:	00097417          	auipc	s0,0x97
ffffffffc0204488:	59440413          	addi	s0,s0,1428 # ffffffffc029ba18 <current>
ffffffffc020448c:	601c                	ld	a5,0(s0)
ffffffffc020448e:	00097717          	auipc	a4,0x97
ffffffffc0204492:	59a73703          	ld	a4,1434(a4) # ffffffffc029ba28 <idleproc>
{
ffffffffc0204496:	f406                	sd	ra,40(sp)
ffffffffc0204498:	ec26                	sd	s1,24(sp)
    if (current == idleproc)
ffffffffc020449a:	0ce78b63          	beq	a5,a4,ffffffffc0204570 <do_exit+0xf0>
    if (current == initproc)
ffffffffc020449e:	00097497          	auipc	s1,0x97
ffffffffc02044a2:	58248493          	addi	s1,s1,1410 # ffffffffc029ba20 <initproc>
ffffffffc02044a6:	6098                	ld	a4,0(s1)
ffffffffc02044a8:	e84a                	sd	s2,16(sp)
ffffffffc02044aa:	0ee78a63          	beq	a5,a4,ffffffffc020459e <do_exit+0x11e>
ffffffffc02044ae:	892a                	mv	s2,a0
    struct mm_struct *mm = current->mm;
ffffffffc02044b0:	7788                	ld	a0,40(a5)
    if (mm != NULL)
ffffffffc02044b2:	c115                	beqz	a0,ffffffffc02044d6 <do_exit+0x56>
ffffffffc02044b4:	00097797          	auipc	a5,0x97
ffffffffc02044b8:	5347b783          	ld	a5,1332(a5) # ffffffffc029b9e8 <boot_pgdir_pa>
ffffffffc02044bc:	577d                	li	a4,-1
ffffffffc02044be:	177e                	slli	a4,a4,0x3f
ffffffffc02044c0:	83b1                	srli	a5,a5,0xc
ffffffffc02044c2:	8fd9                	or	a5,a5,a4
ffffffffc02044c4:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc02044c8:	591c                	lw	a5,48(a0)
ffffffffc02044ca:	37fd                	addiw	a5,a5,-1
ffffffffc02044cc:	d91c                	sw	a5,48(a0)
        if (mm_count_dec(mm) == 0)
ffffffffc02044ce:	cfd5                	beqz	a5,ffffffffc020458a <do_exit+0x10a>
        current->mm = NULL;
ffffffffc02044d0:	601c                	ld	a5,0(s0)
ffffffffc02044d2:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02044d6:	470d                	li	a4,3
    current->exit_code = error_code;
ffffffffc02044d8:	0f27a423          	sw	s2,232(a5)
    current->state = PROC_ZOMBIE;
ffffffffc02044dc:	c398                	sw	a4,0(a5)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044de:	100027f3          	csrr	a5,sstatus
ffffffffc02044e2:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02044e4:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02044e6:	ebe1                	bnez	a5,ffffffffc02045b6 <do_exit+0x136>
        proc = current->parent;
ffffffffc02044e8:	6018                	ld	a4,0(s0)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044ea:	800007b7          	lui	a5,0x80000
ffffffffc02044ee:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e09>
        proc = current->parent;
ffffffffc02044f0:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD)
ffffffffc02044f2:	0ec52703          	lw	a4,236(a0)
ffffffffc02044f6:	0cf70463          	beq	a4,a5,ffffffffc02045be <do_exit+0x13e>
        while (current->cptr != NULL)
ffffffffc02044fa:	6018                	ld	a4,0(s0)
                if (initproc->wait_state == WT_CHILD)
ffffffffc02044fc:	800005b7          	lui	a1,0x80000
ffffffffc0204500:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e09>
        while (current->cptr != NULL)
ffffffffc0204502:	7b7c                	ld	a5,240(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204504:	460d                	li	a2,3
        while (current->cptr != NULL)
ffffffffc0204506:	e789                	bnez	a5,ffffffffc0204510 <do_exit+0x90>
ffffffffc0204508:	a83d                	j	ffffffffc0204546 <do_exit+0xc6>
ffffffffc020450a:	6018                	ld	a4,0(s0)
ffffffffc020450c:	7b7c                	ld	a5,240(a4)
ffffffffc020450e:	cf85                	beqz	a5,ffffffffc0204546 <do_exit+0xc6>
            current->cptr = proc->optr;
ffffffffc0204510:	1007b683          	ld	a3,256(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc0204514:	6088                	ld	a0,0(s1)
            current->cptr = proc->optr;
ffffffffc0204516:	fb74                	sd	a3,240(a4)
            proc->yptr = NULL;
ffffffffc0204518:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL)
ffffffffc020451c:	7978                	ld	a4,240(a0)
ffffffffc020451e:	10e7b023          	sd	a4,256(a5)
ffffffffc0204522:	c311                	beqz	a4,ffffffffc0204526 <do_exit+0xa6>
                initproc->cptr->yptr = proc;
ffffffffc0204524:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204526:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc0204528:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020452a:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE)
ffffffffc020452c:	fcc71fe3          	bne	a4,a2,ffffffffc020450a <do_exit+0x8a>
                if (initproc->wait_state == WT_CHILD)
ffffffffc0204530:	0ec52783          	lw	a5,236(a0)
ffffffffc0204534:	fcb79be3          	bne	a5,a1,ffffffffc020450a <do_exit+0x8a>
                    wakeup_proc(initproc);
ffffffffc0204538:	415000ef          	jal	ffffffffc020514c <wakeup_proc>
ffffffffc020453c:	800005b7          	lui	a1,0x80000
ffffffffc0204540:	0585                	addi	a1,a1,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e09>
ffffffffc0204542:	460d                	li	a2,3
ffffffffc0204544:	b7d9                	j	ffffffffc020450a <do_exit+0x8a>
    if (flag)
ffffffffc0204546:	02091263          	bnez	s2,ffffffffc020456a <do_exit+0xea>
    schedule();
ffffffffc020454a:	497000ef          	jal	ffffffffc02051e0 <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020454e:	601c                	ld	a5,0(s0)
ffffffffc0204550:	00003617          	auipc	a2,0x3
ffffffffc0204554:	af060613          	addi	a2,a2,-1296 # ffffffffc0207040 <etext+0x1838>
ffffffffc0204558:	24300593          	li	a1,579
ffffffffc020455c:	43d4                	lw	a3,4(a5)
ffffffffc020455e:	00003517          	auipc	a0,0x3
ffffffffc0204562:	a6250513          	addi	a0,a0,-1438 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204566:	ee1fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_enable();
ffffffffc020456a:	b94fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc020456e:	bff1                	j	ffffffffc020454a <do_exit+0xca>
        panic("idleproc exit.\n");
ffffffffc0204570:	00003617          	auipc	a2,0x3
ffffffffc0204574:	ab060613          	addi	a2,a2,-1360 # ffffffffc0207020 <etext+0x1818>
ffffffffc0204578:	20f00593          	li	a1,527
ffffffffc020457c:	00003517          	auipc	a0,0x3
ffffffffc0204580:	a4450513          	addi	a0,a0,-1468 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204584:	e84a                	sd	s2,16(sp)
ffffffffc0204586:	ec1fb0ef          	jal	ffffffffc0200446 <__panic>
            exit_mmap(mm);
ffffffffc020458a:	e42a                	sd	a0,8(sp)
ffffffffc020458c:	c44ff0ef          	jal	ffffffffc02039d0 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204590:	6522                	ld	a0,8(sp)
ffffffffc0204592:	981ff0ef          	jal	ffffffffc0203f12 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204596:	6522                	ld	a0,8(sp)
ffffffffc0204598:	a82ff0ef          	jal	ffffffffc020381a <mm_destroy>
ffffffffc020459c:	bf15                	j	ffffffffc02044d0 <do_exit+0x50>
        panic("initproc exit.\n");
ffffffffc020459e:	00003617          	auipc	a2,0x3
ffffffffc02045a2:	a9260613          	addi	a2,a2,-1390 # ffffffffc0207030 <etext+0x1828>
ffffffffc02045a6:	21300593          	li	a1,531
ffffffffc02045aa:	00003517          	auipc	a0,0x3
ffffffffc02045ae:	a1650513          	addi	a0,a0,-1514 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02045b2:	e95fb0ef          	jal	ffffffffc0200446 <__panic>
        intr_disable();
ffffffffc02045b6:	b4efc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc02045ba:	4905                	li	s2,1
ffffffffc02045bc:	b735                	j	ffffffffc02044e8 <do_exit+0x68>
            wakeup_proc(proc);
ffffffffc02045be:	38f000ef          	jal	ffffffffc020514c <wakeup_proc>
ffffffffc02045c2:	bf25                	j	ffffffffc02044fa <do_exit+0x7a>

ffffffffc02045c4 <do_wait.part.0>:
int do_wait(int pid, int *code_store)
ffffffffc02045c4:	7179                	addi	sp,sp,-48
ffffffffc02045c6:	ec26                	sd	s1,24(sp)
ffffffffc02045c8:	e84a                	sd	s2,16(sp)
ffffffffc02045ca:	e44e                	sd	s3,8(sp)
ffffffffc02045cc:	f406                	sd	ra,40(sp)
ffffffffc02045ce:	f022                	sd	s0,32(sp)
ffffffffc02045d0:	84aa                	mv	s1,a0
ffffffffc02045d2:	892e                	mv	s2,a1
ffffffffc02045d4:	00097997          	auipc	s3,0x97
ffffffffc02045d8:	44498993          	addi	s3,s3,1092 # ffffffffc029ba18 <current>
    if (pid != 0)
ffffffffc02045dc:	cd19                	beqz	a0,ffffffffc02045fa <do_wait.part.0+0x36>
    if (0 < pid && pid < MAX_PID)
ffffffffc02045de:	6789                	lui	a5,0x2
ffffffffc02045e0:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc02045e2:	fff5071b          	addiw	a4,a0,-1
ffffffffc02045e6:	12e7f563          	bgeu	a5,a4,ffffffffc0204710 <do_wait.part.0+0x14c>
}
ffffffffc02045ea:	70a2                	ld	ra,40(sp)
ffffffffc02045ec:	7402                	ld	s0,32(sp)
ffffffffc02045ee:	64e2                	ld	s1,24(sp)
ffffffffc02045f0:	6942                	ld	s2,16(sp)
ffffffffc02045f2:	69a2                	ld	s3,8(sp)
    return -E_BAD_PROC;
ffffffffc02045f4:	5579                	li	a0,-2
}
ffffffffc02045f6:	6145                	addi	sp,sp,48
ffffffffc02045f8:	8082                	ret
        proc = current->cptr;
ffffffffc02045fa:	0009b703          	ld	a4,0(s3)
ffffffffc02045fe:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204600:	d46d                	beqz	s0,ffffffffc02045ea <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc0204602:	468d                	li	a3,3
ffffffffc0204604:	a021                	j	ffffffffc020460c <do_wait.part.0+0x48>
        for (; proc != NULL; proc = proc->optr)
ffffffffc0204606:	10043403          	ld	s0,256(s0)
ffffffffc020460a:	c075                	beqz	s0,ffffffffc02046ee <do_wait.part.0+0x12a>
            if (proc->state == PROC_ZOMBIE)
ffffffffc020460c:	401c                	lw	a5,0(s0)
ffffffffc020460e:	fed79ce3          	bne	a5,a3,ffffffffc0204606 <do_wait.part.0+0x42>
    if (proc == idleproc || proc == initproc)
ffffffffc0204612:	00097797          	auipc	a5,0x97
ffffffffc0204616:	4167b783          	ld	a5,1046(a5) # ffffffffc029ba28 <idleproc>
ffffffffc020461a:	14878263          	beq	a5,s0,ffffffffc020475e <do_wait.part.0+0x19a>
ffffffffc020461e:	00097797          	auipc	a5,0x97
ffffffffc0204622:	4027b783          	ld	a5,1026(a5) # ffffffffc029ba20 <initproc>
ffffffffc0204626:	12f40c63          	beq	s0,a5,ffffffffc020475e <do_wait.part.0+0x19a>
    if (code_store != NULL)
ffffffffc020462a:	00090663          	beqz	s2,ffffffffc0204636 <do_wait.part.0+0x72>
        *code_store = proc->exit_code;
ffffffffc020462e:	0e842783          	lw	a5,232(s0)
ffffffffc0204632:	00f92023          	sw	a5,0(s2)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0204636:	100027f3          	csrr	a5,sstatus
ffffffffc020463a:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020463c:	4601                	li	a2,0
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc020463e:	10079963          	bnez	a5,ffffffffc0204750 <do_wait.part.0+0x18c>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204642:	6c74                	ld	a3,216(s0)
ffffffffc0204644:	7078                	ld	a4,224(s0)
    if (proc->optr != NULL)
ffffffffc0204646:	10043783          	ld	a5,256(s0)
    prev->next = next;
ffffffffc020464a:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc020464c:	e314                	sd	a3,0(a4)
    __list_del(listelm->prev, listelm->next);
ffffffffc020464e:	6474                	ld	a3,200(s0)
ffffffffc0204650:	6878                	ld	a4,208(s0)
    prev->next = next;
ffffffffc0204652:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204654:	e314                	sd	a3,0(a4)
ffffffffc0204656:	c789                	beqz	a5,ffffffffc0204660 <do_wait.part.0+0x9c>
        proc->optr->yptr = proc->yptr;
ffffffffc0204658:	7c78                	ld	a4,248(s0)
ffffffffc020465a:	fff8                	sd	a4,248(a5)
        proc->yptr->optr = proc->optr;
ffffffffc020465c:	10043783          	ld	a5,256(s0)
    if (proc->yptr != NULL)
ffffffffc0204660:	7c78                	ld	a4,248(s0)
ffffffffc0204662:	c36d                	beqz	a4,ffffffffc0204744 <do_wait.part.0+0x180>
        proc->yptr->optr = proc->optr;
ffffffffc0204664:	10f73023          	sd	a5,256(a4)
    nr_process--;
ffffffffc0204668:	00097797          	auipc	a5,0x97
ffffffffc020466c:	3a87a783          	lw	a5,936(a5) # ffffffffc029ba10 <nr_process>
ffffffffc0204670:	37fd                	addiw	a5,a5,-1
ffffffffc0204672:	00097717          	auipc	a4,0x97
ffffffffc0204676:	38f72f23          	sw	a5,926(a4) # ffffffffc029ba10 <nr_process>
    if (flag)
ffffffffc020467a:	e271                	bnez	a2,ffffffffc020473e <do_wait.part.0+0x17a>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020467c:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020467e:	c02007b7          	lui	a5,0xc0200
ffffffffc0204682:	10f6e663          	bltu	a3,a5,ffffffffc020478e <do_wait.part.0+0x1ca>
ffffffffc0204686:	00097717          	auipc	a4,0x97
ffffffffc020468a:	37273703          	ld	a4,882(a4) # ffffffffc029b9f8 <va_pa_offset>
    if (PPN(pa) >= npage)
ffffffffc020468e:	00097797          	auipc	a5,0x97
ffffffffc0204692:	3727b783          	ld	a5,882(a5) # ffffffffc029ba00 <npage>
    return pa2page(PADDR(kva));
ffffffffc0204696:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage)
ffffffffc0204698:	82b1                	srli	a3,a3,0xc
ffffffffc020469a:	0cf6fe63          	bgeu	a3,a5,ffffffffc0204776 <do_wait.part.0+0x1b2>
    return &pages[PPN(pa) - nbase];
ffffffffc020469e:	00003797          	auipc	a5,0x3
ffffffffc02046a2:	2ca7b783          	ld	a5,714(a5) # ffffffffc0207968 <nbase>
ffffffffc02046a6:	00097517          	auipc	a0,0x97
ffffffffc02046aa:	36253503          	ld	a0,866(a0) # ffffffffc029ba08 <pages>
ffffffffc02046ae:	4589                	li	a1,2
ffffffffc02046b0:	8e9d                	sub	a3,a3,a5
ffffffffc02046b2:	069a                	slli	a3,a3,0x6
ffffffffc02046b4:	9536                	add	a0,a0,a3
ffffffffc02046b6:	ffefd0ef          	jal	ffffffffc0201eb4 <free_pages>
    kfree(proc);
ffffffffc02046ba:	8522                	mv	a0,s0
ffffffffc02046bc:	ea2fd0ef          	jal	ffffffffc0201d5e <kfree>
}
ffffffffc02046c0:	70a2                	ld	ra,40(sp)
ffffffffc02046c2:	7402                	ld	s0,32(sp)
ffffffffc02046c4:	64e2                	ld	s1,24(sp)
ffffffffc02046c6:	6942                	ld	s2,16(sp)
ffffffffc02046c8:	69a2                	ld	s3,8(sp)
    return 0;
ffffffffc02046ca:	4501                	li	a0,0
}
ffffffffc02046cc:	6145                	addi	sp,sp,48
ffffffffc02046ce:	8082                	ret
        if (proc != NULL && proc->parent == current)
ffffffffc02046d0:	00097997          	auipc	s3,0x97
ffffffffc02046d4:	34898993          	addi	s3,s3,840 # ffffffffc029ba18 <current>
ffffffffc02046d8:	0009b703          	ld	a4,0(s3)
ffffffffc02046dc:	f487b683          	ld	a3,-184(a5)
ffffffffc02046e0:	f0e695e3          	bne	a3,a4,ffffffffc02045ea <do_wait.part.0+0x26>
            if (proc->state == PROC_ZOMBIE)
ffffffffc02046e4:	f287a603          	lw	a2,-216(a5)
ffffffffc02046e8:	468d                	li	a3,3
ffffffffc02046ea:	06d60063          	beq	a2,a3,ffffffffc020474a <do_wait.part.0+0x186>
        current->wait_state = WT_CHILD;
ffffffffc02046ee:	800007b7          	lui	a5,0x80000
ffffffffc02046f2:	0785                	addi	a5,a5,1 # ffffffff80000001 <_binary_obj___user_exit_out_size+0xffffffff7fff5e09>
        current->state = PROC_SLEEPING;
ffffffffc02046f4:	4685                	li	a3,1
        current->wait_state = WT_CHILD;
ffffffffc02046f6:	0ef72623          	sw	a5,236(a4)
        current->state = PROC_SLEEPING;
ffffffffc02046fa:	c314                	sw	a3,0(a4)
        schedule();
ffffffffc02046fc:	2e5000ef          	jal	ffffffffc02051e0 <schedule>
        if (current->flags & PF_EXITING)
ffffffffc0204700:	0009b783          	ld	a5,0(s3)
ffffffffc0204704:	0b07a783          	lw	a5,176(a5)
ffffffffc0204708:	8b85                	andi	a5,a5,1
ffffffffc020470a:	e7b9                	bnez	a5,ffffffffc0204758 <do_wait.part.0+0x194>
    if (pid != 0)
ffffffffc020470c:	ee0487e3          	beqz	s1,ffffffffc02045fa <do_wait.part.0+0x36>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204710:	45a9                	li	a1,10
ffffffffc0204712:	8526                	mv	a0,s1
ffffffffc0204714:	435000ef          	jal	ffffffffc0205348 <hash32>
ffffffffc0204718:	02051793          	slli	a5,a0,0x20
ffffffffc020471c:	01c7d513          	srli	a0,a5,0x1c
ffffffffc0204720:	00093797          	auipc	a5,0x93
ffffffffc0204724:	28078793          	addi	a5,a5,640 # ffffffffc02979a0 <hash_list>
ffffffffc0204728:	953e                	add	a0,a0,a5
ffffffffc020472a:	87aa                	mv	a5,a0
        while ((le = list_next(le)) != list)
ffffffffc020472c:	a029                	j	ffffffffc0204736 <do_wait.part.0+0x172>
            if (proc->pid == pid)
ffffffffc020472e:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204732:	f8970fe3          	beq	a4,s1,ffffffffc02046d0 <do_wait.part.0+0x10c>
    return listelm->next;
ffffffffc0204736:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204738:	fef51be3          	bne	a0,a5,ffffffffc020472e <do_wait.part.0+0x16a>
ffffffffc020473c:	b57d                	j	ffffffffc02045ea <do_wait.part.0+0x26>
        intr_enable();
ffffffffc020473e:	9c0fc0ef          	jal	ffffffffc02008fe <intr_enable>
ffffffffc0204742:	bf2d                	j	ffffffffc020467c <do_wait.part.0+0xb8>
        proc->parent->cptr = proc->optr;
ffffffffc0204744:	7018                	ld	a4,32(s0)
ffffffffc0204746:	fb7c                	sd	a5,240(a4)
ffffffffc0204748:	b705                	j	ffffffffc0204668 <do_wait.part.0+0xa4>
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc020474a:	f2878413          	addi	s0,a5,-216
ffffffffc020474e:	b5d1                	j	ffffffffc0204612 <do_wait.part.0+0x4e>
        intr_disable();
ffffffffc0204750:	9b4fc0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0204754:	4605                	li	a2,1
ffffffffc0204756:	b5f5                	j	ffffffffc0204642 <do_wait.part.0+0x7e>
            do_exit(-E_KILLED);
ffffffffc0204758:	555d                	li	a0,-9
ffffffffc020475a:	d27ff0ef          	jal	ffffffffc0204480 <do_exit>
        panic("wait idleproc or initproc.\n");
ffffffffc020475e:	00003617          	auipc	a2,0x3
ffffffffc0204762:	90260613          	addi	a2,a2,-1790 # ffffffffc0207060 <etext+0x1858>
ffffffffc0204766:	36a00593          	li	a1,874
ffffffffc020476a:	00003517          	auipc	a0,0x3
ffffffffc020476e:	85650513          	addi	a0,a0,-1962 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204772:	cd5fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204776:	00002617          	auipc	a2,0x2
ffffffffc020477a:	ee260613          	addi	a2,a2,-286 # ffffffffc0206658 <etext+0xe50>
ffffffffc020477e:	06900593          	li	a1,105
ffffffffc0204782:	00002517          	auipc	a0,0x2
ffffffffc0204786:	e2e50513          	addi	a0,a0,-466 # ffffffffc02065b0 <etext+0xda8>
ffffffffc020478a:	cbdfb0ef          	jal	ffffffffc0200446 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020478e:	00002617          	auipc	a2,0x2
ffffffffc0204792:	ea260613          	addi	a2,a2,-350 # ffffffffc0206630 <etext+0xe28>
ffffffffc0204796:	07700593          	li	a1,119
ffffffffc020479a:	00002517          	auipc	a0,0x2
ffffffffc020479e:	e1650513          	addi	a0,a0,-490 # ffffffffc02065b0 <etext+0xda8>
ffffffffc02047a2:	ca5fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02047a6 <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg)
{
ffffffffc02047a6:	1141                	addi	sp,sp,-16
ffffffffc02047a8:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02047aa:	f42fd0ef          	jal	ffffffffc0201eec <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02047ae:	d06fd0ef          	jal	ffffffffc0201cb4 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02047b2:	4601                	li	a2,0
ffffffffc02047b4:	4581                	li	a1,0
ffffffffc02047b6:	fffff517          	auipc	a0,0xfffff
ffffffffc02047ba:	6de50513          	addi	a0,a0,1758 # ffffffffc0203e94 <user_main>
ffffffffc02047be:	c73ff0ef          	jal	ffffffffc0204430 <kernel_thread>
    if (pid <= 0)
ffffffffc02047c2:	00a04563          	bgtz	a0,ffffffffc02047cc <init_main+0x26>
ffffffffc02047c6:	a071                	j	ffffffffc0204852 <init_main+0xac>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0)
    {
        schedule();
ffffffffc02047c8:	219000ef          	jal	ffffffffc02051e0 <schedule>
    if (code_store != NULL)
ffffffffc02047cc:	4581                	li	a1,0
ffffffffc02047ce:	4501                	li	a0,0
ffffffffc02047d0:	df5ff0ef          	jal	ffffffffc02045c4 <do_wait.part.0>
    while (do_wait(0, NULL) == 0)
ffffffffc02047d4:	d975                	beqz	a0,ffffffffc02047c8 <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02047d6:	00003517          	auipc	a0,0x3
ffffffffc02047da:	8ca50513          	addi	a0,a0,-1846 # ffffffffc02070a0 <etext+0x1898>
ffffffffc02047de:	9b7fb0ef          	jal	ffffffffc0200194 <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02047e2:	00097797          	auipc	a5,0x97
ffffffffc02047e6:	23e7b783          	ld	a5,574(a5) # ffffffffc029ba20 <initproc>
ffffffffc02047ea:	7bf8                	ld	a4,240(a5)
ffffffffc02047ec:	e339                	bnez	a4,ffffffffc0204832 <init_main+0x8c>
ffffffffc02047ee:	7ff8                	ld	a4,248(a5)
ffffffffc02047f0:	e329                	bnez	a4,ffffffffc0204832 <init_main+0x8c>
ffffffffc02047f2:	1007b703          	ld	a4,256(a5)
ffffffffc02047f6:	ef15                	bnez	a4,ffffffffc0204832 <init_main+0x8c>
    assert(nr_process == 2);
ffffffffc02047f8:	00097697          	auipc	a3,0x97
ffffffffc02047fc:	2186a683          	lw	a3,536(a3) # ffffffffc029ba10 <nr_process>
ffffffffc0204800:	4709                	li	a4,2
ffffffffc0204802:	0ae69463          	bne	a3,a4,ffffffffc02048aa <init_main+0x104>
ffffffffc0204806:	00097697          	auipc	a3,0x97
ffffffffc020480a:	19a68693          	addi	a3,a3,410 # ffffffffc029b9a0 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020480e:	6698                	ld	a4,8(a3)
ffffffffc0204810:	0c878793          	addi	a5,a5,200
ffffffffc0204814:	06f71b63          	bne	a4,a5,ffffffffc020488a <init_main+0xe4>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0204818:	629c                	ld	a5,0(a3)
ffffffffc020481a:	04f71863          	bne	a4,a5,ffffffffc020486a <init_main+0xc4>

    cprintf("init check memory pass.\n");
ffffffffc020481e:	00003517          	auipc	a0,0x3
ffffffffc0204822:	96a50513          	addi	a0,a0,-1686 # ffffffffc0207188 <etext+0x1980>
ffffffffc0204826:	96ffb0ef          	jal	ffffffffc0200194 <cprintf>
    return 0;
}
ffffffffc020482a:	60a2                	ld	ra,8(sp)
ffffffffc020482c:	4501                	li	a0,0
ffffffffc020482e:	0141                	addi	sp,sp,16
ffffffffc0204830:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc0204832:	00003697          	auipc	a3,0x3
ffffffffc0204836:	89668693          	addi	a3,a3,-1898 # ffffffffc02070c8 <etext+0x18c0>
ffffffffc020483a:	00002617          	auipc	a2,0x2
ffffffffc020483e:	99e60613          	addi	a2,a2,-1634 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204842:	3d800593          	li	a1,984
ffffffffc0204846:	00002517          	auipc	a0,0x2
ffffffffc020484a:	77a50513          	addi	a0,a0,1914 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc020484e:	bf9fb0ef          	jal	ffffffffc0200446 <__panic>
        panic("create user_main failed.\n");
ffffffffc0204852:	00003617          	auipc	a2,0x3
ffffffffc0204856:	82e60613          	addi	a2,a2,-2002 # ffffffffc0207080 <etext+0x1878>
ffffffffc020485a:	3cf00593          	li	a1,975
ffffffffc020485e:	00002517          	auipc	a0,0x2
ffffffffc0204862:	76250513          	addi	a0,a0,1890 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204866:	be1fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc020486a:	00003697          	auipc	a3,0x3
ffffffffc020486e:	8ee68693          	addi	a3,a3,-1810 # ffffffffc0207158 <etext+0x1950>
ffffffffc0204872:	00002617          	auipc	a2,0x2
ffffffffc0204876:	96660613          	addi	a2,a2,-1690 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020487a:	3db00593          	li	a1,987
ffffffffc020487e:	00002517          	auipc	a0,0x2
ffffffffc0204882:	74250513          	addi	a0,a0,1858 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204886:	bc1fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc020488a:	00003697          	auipc	a3,0x3
ffffffffc020488e:	89e68693          	addi	a3,a3,-1890 # ffffffffc0207128 <etext+0x1920>
ffffffffc0204892:	00002617          	auipc	a2,0x2
ffffffffc0204896:	94660613          	addi	a2,a2,-1722 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc020489a:	3da00593          	li	a1,986
ffffffffc020489e:	00002517          	auipc	a0,0x2
ffffffffc02048a2:	72250513          	addi	a0,a0,1826 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02048a6:	ba1fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(nr_process == 2);
ffffffffc02048aa:	00003697          	auipc	a3,0x3
ffffffffc02048ae:	86e68693          	addi	a3,a3,-1938 # ffffffffc0207118 <etext+0x1910>
ffffffffc02048b2:	00002617          	auipc	a2,0x2
ffffffffc02048b6:	92660613          	addi	a2,a2,-1754 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02048ba:	3d900593          	li	a1,985
ffffffffc02048be:	00002517          	auipc	a0,0x2
ffffffffc02048c2:	70250513          	addi	a0,a0,1794 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02048c6:	b81fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02048ca <do_execve>:
{
ffffffffc02048ca:	7171                	addi	sp,sp,-176
ffffffffc02048cc:	e8ea                	sd	s10,80(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048ce:	00097d17          	auipc	s10,0x97
ffffffffc02048d2:	14ad0d13          	addi	s10,s10,330 # ffffffffc029ba18 <current>
ffffffffc02048d6:	000d3783          	ld	a5,0(s10)
{
ffffffffc02048da:	e94a                	sd	s2,144(sp)
ffffffffc02048dc:	ed26                	sd	s1,152(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02048de:	0287b903          	ld	s2,40(a5)
{
ffffffffc02048e2:	84ae                	mv	s1,a1
ffffffffc02048e4:	e54e                	sd	s3,136(sp)
ffffffffc02048e6:	ec32                	sd	a2,24(sp)
ffffffffc02048e8:	89aa                	mv	s3,a0
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02048ea:	85aa                	mv	a1,a0
ffffffffc02048ec:	8626                	mv	a2,s1
ffffffffc02048ee:	854a                	mv	a0,s2
ffffffffc02048f0:	4681                	li	a3,0
{
ffffffffc02048f2:	f506                	sd	ra,168(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0))
ffffffffc02048f4:	c74ff0ef          	jal	ffffffffc0203d68 <user_mem_check>
ffffffffc02048f8:	46050f63          	beqz	a0,ffffffffc0204d76 <do_execve+0x4ac>
    memset(local_name, 0, sizeof(local_name));
ffffffffc02048fc:	4641                	li	a2,16
ffffffffc02048fe:	1808                	addi	a0,sp,48
ffffffffc0204900:	4581                	li	a1,0
ffffffffc0204902:	6dd000ef          	jal	ffffffffc02057de <memset>
    if (len > PROC_NAME_LEN)
ffffffffc0204906:	47bd                	li	a5,15
ffffffffc0204908:	8626                	mv	a2,s1
ffffffffc020490a:	0e97ef63          	bltu	a5,s1,ffffffffc0204a08 <do_execve+0x13e>
    memcpy(local_name, name, len);
ffffffffc020490e:	85ce                	mv	a1,s3
ffffffffc0204910:	1808                	addi	a0,sp,48
ffffffffc0204912:	6df000ef          	jal	ffffffffc02057f0 <memcpy>
    if (mm != NULL)
ffffffffc0204916:	10090063          	beqz	s2,ffffffffc0204a16 <do_execve+0x14c>
        cputs("mm != NULL");
ffffffffc020491a:	00002517          	auipc	a0,0x2
ffffffffc020491e:	46650513          	addi	a0,a0,1126 # ffffffffc0206d80 <etext+0x1578>
ffffffffc0204922:	8a9fb0ef          	jal	ffffffffc02001ca <cputs>
ffffffffc0204926:	00097797          	auipc	a5,0x97
ffffffffc020492a:	0c27b783          	ld	a5,194(a5) # ffffffffc029b9e8 <boot_pgdir_pa>
ffffffffc020492e:	577d                	li	a4,-1
ffffffffc0204930:	177e                	slli	a4,a4,0x3f
ffffffffc0204932:	83b1                	srli	a5,a5,0xc
ffffffffc0204934:	8fd9                	or	a5,a5,a4
ffffffffc0204936:	18079073          	csrw	satp,a5
ffffffffc020493a:	03092783          	lw	a5,48(s2)
ffffffffc020493e:	37fd                	addiw	a5,a5,-1
ffffffffc0204940:	02f92823          	sw	a5,48(s2)
        if (mm_count_dec(mm) == 0)
ffffffffc0204944:	30078563          	beqz	a5,ffffffffc0204c4e <do_execve+0x384>
        current->mm = NULL;
ffffffffc0204948:	000d3783          	ld	a5,0(s10)
ffffffffc020494c:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL)
ffffffffc0204950:	d8dfe0ef          	jal	ffffffffc02036dc <mm_create>
ffffffffc0204954:	892a                	mv	s2,a0
ffffffffc0204956:	22050063          	beqz	a0,ffffffffc0204b76 <do_execve+0x2ac>
    if ((page = alloc_page()) == NULL)
ffffffffc020495a:	4505                	li	a0,1
ffffffffc020495c:	d1efd0ef          	jal	ffffffffc0201e7a <alloc_pages>
ffffffffc0204960:	42050063          	beqz	a0,ffffffffc0204d80 <do_execve+0x4b6>
    return page - pages + nbase;
ffffffffc0204964:	f0e2                	sd	s8,96(sp)
ffffffffc0204966:	00097c17          	auipc	s8,0x97
ffffffffc020496a:	0a2c0c13          	addi	s8,s8,162 # ffffffffc029ba08 <pages>
ffffffffc020496e:	000c3783          	ld	a5,0(s8)
ffffffffc0204972:	f4de                	sd	s7,104(sp)
ffffffffc0204974:	00003b97          	auipc	s7,0x3
ffffffffc0204978:	ff4bbb83          	ld	s7,-12(s7) # ffffffffc0207968 <nbase>
ffffffffc020497c:	40f506b3          	sub	a3,a0,a5
ffffffffc0204980:	ece6                	sd	s9,88(sp)
    return KADDR(page2pa(page));
ffffffffc0204982:	00097c97          	auipc	s9,0x97
ffffffffc0204986:	07ec8c93          	addi	s9,s9,126 # ffffffffc029ba00 <npage>
ffffffffc020498a:	f8da                	sd	s6,112(sp)
    return page - pages + nbase;
ffffffffc020498c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc020498e:	5b7d                	li	s6,-1
ffffffffc0204990:	000cb783          	ld	a5,0(s9)
    return page - pages + nbase;
ffffffffc0204994:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204996:	00cb5713          	srli	a4,s6,0xc
ffffffffc020499a:	e83a                	sd	a4,16(sp)
ffffffffc020499c:	fcd6                	sd	s5,120(sp)
ffffffffc020499e:	8f75                	and	a4,a4,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02049a0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02049a2:	40f77263          	bgeu	a4,a5,ffffffffc0204da6 <do_execve+0x4dc>
ffffffffc02049a6:	00097a97          	auipc	s5,0x97
ffffffffc02049aa:	052a8a93          	addi	s5,s5,82 # ffffffffc029b9f8 <va_pa_offset>
ffffffffc02049ae:	000ab783          	ld	a5,0(s5)
    memcpy(pgdir, boot_pgdir_va, PGSIZE);
ffffffffc02049b2:	00097597          	auipc	a1,0x97
ffffffffc02049b6:	03e5b583          	ld	a1,62(a1) # ffffffffc029b9f0 <boot_pgdir_va>
ffffffffc02049ba:	6605                	lui	a2,0x1
ffffffffc02049bc:	00f684b3          	add	s1,a3,a5
ffffffffc02049c0:	8526                	mv	a0,s1
ffffffffc02049c2:	62f000ef          	jal	ffffffffc02057f0 <memcpy>
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049c6:	66e2                	ld	a3,24(sp)
ffffffffc02049c8:	464c47b7          	lui	a5,0x464c4
    mm->pgdir = pgdir;
ffffffffc02049cc:	00993c23          	sd	s1,24(s2)
    if (elf->e_magic != ELF_MAGIC)
ffffffffc02049d0:	4298                	lw	a4,0(a3)
ffffffffc02049d2:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464ba387>
ffffffffc02049d6:	06f70863          	beq	a4,a5,ffffffffc0204a46 <do_execve+0x17c>
        ret = -E_INVAL_ELF;
ffffffffc02049da:	54e1                	li	s1,-8
    put_pgdir(mm);
ffffffffc02049dc:	854a                	mv	a0,s2
ffffffffc02049de:	d34ff0ef          	jal	ffffffffc0203f12 <put_pgdir>
ffffffffc02049e2:	7ae6                	ld	s5,120(sp)
ffffffffc02049e4:	7b46                	ld	s6,112(sp)
ffffffffc02049e6:	7ba6                	ld	s7,104(sp)
ffffffffc02049e8:	7c06                	ld	s8,96(sp)
ffffffffc02049ea:	6ce6                	ld	s9,88(sp)
    mm_destroy(mm);
ffffffffc02049ec:	854a                	mv	a0,s2
ffffffffc02049ee:	e2dfe0ef          	jal	ffffffffc020381a <mm_destroy>
    do_exit(ret);
ffffffffc02049f2:	8526                	mv	a0,s1
ffffffffc02049f4:	f122                	sd	s0,160(sp)
ffffffffc02049f6:	e152                	sd	s4,128(sp)
ffffffffc02049f8:	fcd6                	sd	s5,120(sp)
ffffffffc02049fa:	f8da                	sd	s6,112(sp)
ffffffffc02049fc:	f4de                	sd	s7,104(sp)
ffffffffc02049fe:	f0e2                	sd	s8,96(sp)
ffffffffc0204a00:	ece6                	sd	s9,88(sp)
ffffffffc0204a02:	e4ee                	sd	s11,72(sp)
ffffffffc0204a04:	a7dff0ef          	jal	ffffffffc0204480 <do_exit>
    if (len > PROC_NAME_LEN)
ffffffffc0204a08:	863e                	mv	a2,a5
    memcpy(local_name, name, len);
ffffffffc0204a0a:	85ce                	mv	a1,s3
ffffffffc0204a0c:	1808                	addi	a0,sp,48
ffffffffc0204a0e:	5e3000ef          	jal	ffffffffc02057f0 <memcpy>
    if (mm != NULL)
ffffffffc0204a12:	f00914e3          	bnez	s2,ffffffffc020491a <do_execve+0x50>
    if (current->mm != NULL)
ffffffffc0204a16:	000d3783          	ld	a5,0(s10)
ffffffffc0204a1a:	779c                	ld	a5,40(a5)
ffffffffc0204a1c:	db95                	beqz	a5,ffffffffc0204950 <do_execve+0x86>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc0204a1e:	00002617          	auipc	a2,0x2
ffffffffc0204a22:	78a60613          	addi	a2,a2,1930 # ffffffffc02071a8 <etext+0x19a0>
ffffffffc0204a26:	25000593          	li	a1,592
ffffffffc0204a2a:	00002517          	auipc	a0,0x2
ffffffffc0204a2e:	59650513          	addi	a0,a0,1430 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204a32:	f122                	sd	s0,160(sp)
ffffffffc0204a34:	e152                	sd	s4,128(sp)
ffffffffc0204a36:	fcd6                	sd	s5,120(sp)
ffffffffc0204a38:	f8da                	sd	s6,112(sp)
ffffffffc0204a3a:	f4de                	sd	s7,104(sp)
ffffffffc0204a3c:	f0e2                	sd	s8,96(sp)
ffffffffc0204a3e:	ece6                	sd	s9,88(sp)
ffffffffc0204a40:	e4ee                	sd	s11,72(sp)
ffffffffc0204a42:	a05fb0ef          	jal	ffffffffc0200446 <__panic>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a46:	0386d703          	lhu	a4,56(a3)
ffffffffc0204a4a:	e152                	sd	s4,128(sp)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a4c:	0206ba03          	ld	s4,32(a3)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a50:	00371793          	slli	a5,a4,0x3
ffffffffc0204a54:	8f99                	sub	a5,a5,a4
ffffffffc0204a56:	078e                	slli	a5,a5,0x3
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc0204a58:	9a36                	add	s4,s4,a3
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc0204a5a:	97d2                	add	a5,a5,s4
ffffffffc0204a5c:	f122                	sd	s0,160(sp)
ffffffffc0204a5e:	f43e                	sd	a5,40(sp)
    for (; ph < ph_end; ph++)
ffffffffc0204a60:	00fa7e63          	bgeu	s4,a5,ffffffffc0204a7c <do_execve+0x1b2>
ffffffffc0204a64:	e4ee                	sd	s11,72(sp)
        if (ph->p_type != ELF_PT_LOAD)
ffffffffc0204a66:	000a2783          	lw	a5,0(s4)
ffffffffc0204a6a:	4705                	li	a4,1
ffffffffc0204a6c:	10e78763          	beq	a5,a4,ffffffffc0204b7a <do_execve+0x2b0>
    for (; ph < ph_end; ph++)
ffffffffc0204a70:	77a2                	ld	a5,40(sp)
ffffffffc0204a72:	038a0a13          	addi	s4,s4,56
ffffffffc0204a76:	fefa68e3          	bltu	s4,a5,ffffffffc0204a66 <do_execve+0x19c>
ffffffffc0204a7a:	6da6                	ld	s11,72(sp)
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0)
ffffffffc0204a7c:	4701                	li	a4,0
ffffffffc0204a7e:	46ad                	li	a3,11
ffffffffc0204a80:	00100637          	lui	a2,0x100
ffffffffc0204a84:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0204a88:	854a                	mv	a0,s2
ffffffffc0204a8a:	de3fe0ef          	jal	ffffffffc020386c <mm_map>
ffffffffc0204a8e:	84aa                	mv	s1,a0
ffffffffc0204a90:	1a051963          	bnez	a0,ffffffffc0204c42 <do_execve+0x378>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204a94:	01893503          	ld	a0,24(s2)
ffffffffc0204a98:	467d                	li	a2,31
ffffffffc0204a9a:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0204a9e:	b5dfe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204aa2:	3a050163          	beqz	a0,ffffffffc0204e44 <do_execve+0x57a>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aa6:	01893503          	ld	a0,24(s2)
ffffffffc0204aaa:	467d                	li	a2,31
ffffffffc0204aac:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc0204ab0:	b4bfe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204ab4:	36050763          	beqz	a0,ffffffffc0204e22 <do_execve+0x558>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204ab8:	01893503          	ld	a0,24(s2)
ffffffffc0204abc:	467d                	li	a2,31
ffffffffc0204abe:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc0204ac2:	b39fe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204ac6:	32050d63          	beqz	a0,ffffffffc0204e00 <do_execve+0x536>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204aca:	01893503          	ld	a0,24(s2)
ffffffffc0204ace:	467d                	li	a2,31
ffffffffc0204ad0:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc0204ad4:	b27fe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204ad8:	30050363          	beqz	a0,ffffffffc0204dde <do_execve+0x514>
    mm->mm_count += 1;
ffffffffc0204adc:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc0204ae0:	000d3603          	ld	a2,0(s10)
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204ae4:	01893683          	ld	a3,24(s2)
ffffffffc0204ae8:	2785                	addiw	a5,a5,1
ffffffffc0204aea:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc0204aee:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf5e30>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204af2:	c02007b7          	lui	a5,0xc0200
ffffffffc0204af6:	2cf6e763          	bltu	a3,a5,ffffffffc0204dc4 <do_execve+0x4fa>
ffffffffc0204afa:	000ab783          	ld	a5,0(s5)
ffffffffc0204afe:	577d                	li	a4,-1
ffffffffc0204b00:	177e                	slli	a4,a4,0x3f
ffffffffc0204b02:	8e9d                	sub	a3,a3,a5
ffffffffc0204b04:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204b08:	f654                	sd	a3,168(a2)
ffffffffc0204b0a:	8fd9                	or	a5,a5,a4
ffffffffc0204b0c:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc0204b10:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b12:	4581                	li	a1,0
ffffffffc0204b14:	12000613          	li	a2,288
ffffffffc0204b18:	8522                	mv	a0,s0
    uintptr_t sstatus = tf->status;
ffffffffc0204b1a:	10043903          	ld	s2,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc0204b1e:	4c1000ef          	jal	ffffffffc02057de <memset>
    tf->epc = elf->e_entry;  
ffffffffc0204b22:	67e2                	ld	a5,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b24:	000d3983          	ld	s3,0(s10)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;  
ffffffffc0204b28:	edf97913          	andi	s2,s2,-289
    tf->epc = elf->e_entry;  
ffffffffc0204b2c:	6f98                	ld	a4,24(a5)
    tf->gpr.sp = USTACKTOP;  
ffffffffc0204b2e:	4785                	li	a5,1
ffffffffc0204b30:	07fe                	slli	a5,a5,0x1f
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;  
ffffffffc0204b32:	02096913          	ori	s2,s2,32
    tf->epc = elf->e_entry;  
ffffffffc0204b36:	10e43423          	sd	a4,264(s0)
    tf->gpr.sp = USTACKTOP;  
ffffffffc0204b3a:	e81c                	sd	a5,16(s0)
    tf->status = (sstatus & ~SSTATUS_SPP) | SSTATUS_SPIE;  
ffffffffc0204b3c:	11243023          	sd	s2,256(s0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204b40:	4641                	li	a2,16
ffffffffc0204b42:	4581                	li	a1,0
ffffffffc0204b44:	0b498513          	addi	a0,s3,180
ffffffffc0204b48:	497000ef          	jal	ffffffffc02057de <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204b4c:	180c                	addi	a1,sp,48
ffffffffc0204b4e:	0b498513          	addi	a0,s3,180
ffffffffc0204b52:	463d                	li	a2,15
ffffffffc0204b54:	49d000ef          	jal	ffffffffc02057f0 <memcpy>
ffffffffc0204b58:	740a                	ld	s0,160(sp)
ffffffffc0204b5a:	6a0a                	ld	s4,128(sp)
ffffffffc0204b5c:	7ae6                	ld	s5,120(sp)
ffffffffc0204b5e:	7b46                	ld	s6,112(sp)
ffffffffc0204b60:	7ba6                	ld	s7,104(sp)
ffffffffc0204b62:	7c06                	ld	s8,96(sp)
ffffffffc0204b64:	6ce6                	ld	s9,88(sp)
}
ffffffffc0204b66:	70aa                	ld	ra,168(sp)
ffffffffc0204b68:	694a                	ld	s2,144(sp)
ffffffffc0204b6a:	69aa                	ld	s3,136(sp)
ffffffffc0204b6c:	6d46                	ld	s10,80(sp)
ffffffffc0204b6e:	8526                	mv	a0,s1
ffffffffc0204b70:	64ea                	ld	s1,152(sp)
ffffffffc0204b72:	614d                	addi	sp,sp,176
ffffffffc0204b74:	8082                	ret
    int ret = -E_NO_MEM;
ffffffffc0204b76:	54f1                	li	s1,-4
ffffffffc0204b78:	bdad                	j	ffffffffc02049f2 <do_execve+0x128>
        if (ph->p_filesz > ph->p_memsz)
ffffffffc0204b7a:	028a3603          	ld	a2,40(s4)
ffffffffc0204b7e:	020a3783          	ld	a5,32(s4)
ffffffffc0204b82:	20f66363          	bltu	a2,a5,ffffffffc0204d88 <do_execve+0x4be>
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b86:	004a2783          	lw	a5,4(s4)
ffffffffc0204b8a:	0027971b          	slliw	a4,a5,0x2
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b8e:	0027f693          	andi	a3,a5,2
        if (ph->p_flags & ELF_PF_X)
ffffffffc0204b92:	8b11                	andi	a4,a4,4
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b94:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W)
ffffffffc0204b96:	c6f1                	beqz	a3,ffffffffc0204c62 <do_execve+0x398>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204b98:	1c079763          	bnez	a5,ffffffffc0204d66 <do_execve+0x49c>
            perm |= (PTE_W | PTE_R);
ffffffffc0204b9c:	47dd                	li	a5,23
            vm_flags |= VM_WRITE;
ffffffffc0204b9e:	00276693          	ori	a3,a4,2
            perm |= (PTE_W | PTE_R);
ffffffffc0204ba2:	e43e                	sd	a5,8(sp)
        if (vm_flags & VM_EXEC)
ffffffffc0204ba4:	c709                	beqz	a4,ffffffffc0204bae <do_execve+0x2e4>
            perm |= PTE_X;
ffffffffc0204ba6:	67a2                	ld	a5,8(sp)
ffffffffc0204ba8:	0087e793          	ori	a5,a5,8
ffffffffc0204bac:	e43e                	sd	a5,8(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0)
ffffffffc0204bae:	010a3583          	ld	a1,16(s4)
ffffffffc0204bb2:	4701                	li	a4,0
ffffffffc0204bb4:	854a                	mv	a0,s2
ffffffffc0204bb6:	cb7fe0ef          	jal	ffffffffc020386c <mm_map>
ffffffffc0204bba:	84aa                	mv	s1,a0
ffffffffc0204bbc:	1c051463          	bnez	a0,ffffffffc0204d84 <do_execve+0x4ba>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bc0:	010a3b03          	ld	s6,16(s4)
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bc4:	020a3483          	ld	s1,32(s4)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204bc8:	77fd                	lui	a5,0xfffff
ffffffffc0204bca:	00fb75b3          	and	a1,s6,a5
        end = ph->p_va + ph->p_filesz;
ffffffffc0204bce:	94da                	add	s1,s1,s6
        while (start < end)
ffffffffc0204bd0:	1a9b7563          	bgeu	s6,s1,ffffffffc0204d7a <do_execve+0x4b0>
        unsigned char *from = binary + ph->p_offset;
ffffffffc0204bd4:	008a3983          	ld	s3,8(s4)
ffffffffc0204bd8:	67e2                	ld	a5,24(sp)
ffffffffc0204bda:	99be                	add	s3,s3,a5
ffffffffc0204bdc:	a881                	j	ffffffffc0204c2c <do_execve+0x362>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204bde:	6785                	lui	a5,0x1
ffffffffc0204be0:	00f58db3          	add	s11,a1,a5
                size -= la - end;
ffffffffc0204be4:	41648633          	sub	a2,s1,s6
            if (end < la)
ffffffffc0204be8:	01b4e463          	bltu	s1,s11,ffffffffc0204bf0 <do_execve+0x326>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204bec:	416d8633          	sub	a2,s11,s6
    return page - pages + nbase;
ffffffffc0204bf0:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204bf4:	67c2                	ld	a5,16(sp)
ffffffffc0204bf6:	000cb503          	ld	a0,0(s9)
    return page - pages + nbase;
ffffffffc0204bfa:	40d406b3          	sub	a3,s0,a3
ffffffffc0204bfe:	8699                	srai	a3,a3,0x6
ffffffffc0204c00:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c02:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c06:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204c08:	18a87363          	bgeu	a6,a0,ffffffffc0204d8e <do_execve+0x4c4>
ffffffffc0204c0c:	000ab503          	ld	a0,0(s5)
ffffffffc0204c10:	40bb05b3          	sub	a1,s6,a1
            memcpy(page2kva(page) + off, from, size);
ffffffffc0204c14:	e032                	sd	a2,0(sp)
ffffffffc0204c16:	9536                	add	a0,a0,a3
ffffffffc0204c18:	952e                	add	a0,a0,a1
ffffffffc0204c1a:	85ce                	mv	a1,s3
ffffffffc0204c1c:	3d5000ef          	jal	ffffffffc02057f0 <memcpy>
            start += size, from += size;
ffffffffc0204c20:	6602                	ld	a2,0(sp)
ffffffffc0204c22:	9b32                	add	s6,s6,a2
ffffffffc0204c24:	99b2                	add	s3,s3,a2
        while (start < end)
ffffffffc0204c26:	049b7563          	bgeu	s6,s1,ffffffffc0204c70 <do_execve+0x3a6>
ffffffffc0204c2a:	85ee                	mv	a1,s11
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204c2c:	01893503          	ld	a0,24(s2)
ffffffffc0204c30:	6622                	ld	a2,8(sp)
ffffffffc0204c32:	e02e                	sd	a1,0(sp)
ffffffffc0204c34:	9c7fe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204c38:	6582                	ld	a1,0(sp)
ffffffffc0204c3a:	842a                	mv	s0,a0
ffffffffc0204c3c:	f14d                	bnez	a0,ffffffffc0204bde <do_execve+0x314>
ffffffffc0204c3e:	6da6                	ld	s11,72(sp)
        ret = -E_NO_MEM;
ffffffffc0204c40:	54f1                	li	s1,-4
    exit_mmap(mm);
ffffffffc0204c42:	854a                	mv	a0,s2
ffffffffc0204c44:	d8dfe0ef          	jal	ffffffffc02039d0 <exit_mmap>
ffffffffc0204c48:	740a                	ld	s0,160(sp)
ffffffffc0204c4a:	6a0a                	ld	s4,128(sp)
ffffffffc0204c4c:	bb41                	j	ffffffffc02049dc <do_execve+0x112>
            exit_mmap(mm);
ffffffffc0204c4e:	854a                	mv	a0,s2
ffffffffc0204c50:	d81fe0ef          	jal	ffffffffc02039d0 <exit_mmap>
            put_pgdir(mm);
ffffffffc0204c54:	854a                	mv	a0,s2
ffffffffc0204c56:	abcff0ef          	jal	ffffffffc0203f12 <put_pgdir>
            mm_destroy(mm);
ffffffffc0204c5a:	854a                	mv	a0,s2
ffffffffc0204c5c:	bbffe0ef          	jal	ffffffffc020381a <mm_destroy>
ffffffffc0204c60:	b1e5                	j	ffffffffc0204948 <do_execve+0x7e>
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204c62:	0e078e63          	beqz	a5,ffffffffc0204d5e <do_execve+0x494>
            perm |= PTE_R;
ffffffffc0204c66:	47cd                	li	a5,19
            vm_flags |= VM_READ;
ffffffffc0204c68:	00176693          	ori	a3,a4,1
            perm |= PTE_R;
ffffffffc0204c6c:	e43e                	sd	a5,8(sp)
ffffffffc0204c6e:	bf1d                	j	ffffffffc0204ba4 <do_execve+0x2da>
        end = ph->p_va + ph->p_memsz;
ffffffffc0204c70:	010a3483          	ld	s1,16(s4)
ffffffffc0204c74:	028a3683          	ld	a3,40(s4)
ffffffffc0204c78:	94b6                	add	s1,s1,a3
        if (start < la)
ffffffffc0204c7a:	07bb7c63          	bgeu	s6,s11,ffffffffc0204cf2 <do_execve+0x428>
            if (start == end)
ffffffffc0204c7e:	df6489e3          	beq	s1,s6,ffffffffc0204a70 <do_execve+0x1a6>
                size -= la - end;
ffffffffc0204c82:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204c86:	0fb4f563          	bgeu	s1,s11,ffffffffc0204d70 <do_execve+0x4a6>
    return page - pages + nbase;
ffffffffc0204c8a:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204c8e:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0204c92:	40d406b3          	sub	a3,s0,a3
ffffffffc0204c96:	8699                	srai	a3,a3,0x6
ffffffffc0204c98:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204c9a:	00c69593          	slli	a1,a3,0xc
ffffffffc0204c9e:	81b1                	srli	a1,a1,0xc
    return page2ppn(page) << PGSHIFT;
ffffffffc0204ca0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204ca2:	0ec5f663          	bgeu	a1,a2,ffffffffc0204d8e <do_execve+0x4c4>
ffffffffc0204ca6:	000ab603          	ld	a2,0(s5)
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204caa:	6505                	lui	a0,0x1
ffffffffc0204cac:	955a                	add	a0,a0,s6
ffffffffc0204cae:	96b2                	add	a3,a3,a2
ffffffffc0204cb0:	41b50533          	sub	a0,a0,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204cb4:	9536                	add	a0,a0,a3
ffffffffc0204cb6:	864e                	mv	a2,s3
ffffffffc0204cb8:	4581                	li	a1,0
ffffffffc0204cba:	325000ef          	jal	ffffffffc02057de <memset>
            start += size;
ffffffffc0204cbe:	9b4e                	add	s6,s6,s3
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0204cc0:	01b4b6b3          	sltu	a3,s1,s11
ffffffffc0204cc4:	01b4f463          	bgeu	s1,s11,ffffffffc0204ccc <do_execve+0x402>
ffffffffc0204cc8:	db6484e3          	beq	s1,s6,ffffffffc0204a70 <do_execve+0x1a6>
ffffffffc0204ccc:	e299                	bnez	a3,ffffffffc0204cd2 <do_execve+0x408>
ffffffffc0204cce:	03bb0263          	beq	s6,s11,ffffffffc0204cf2 <do_execve+0x428>
ffffffffc0204cd2:	00002697          	auipc	a3,0x2
ffffffffc0204cd6:	4fe68693          	addi	a3,a3,1278 # ffffffffc02071d0 <etext+0x19c8>
ffffffffc0204cda:	00001617          	auipc	a2,0x1
ffffffffc0204cde:	4fe60613          	addi	a2,a2,1278 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204ce2:	2b900593          	li	a1,697
ffffffffc0204ce6:	00002517          	auipc	a0,0x2
ffffffffc0204cea:	2da50513          	addi	a0,a0,730 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204cee:	f58fb0ef          	jal	ffffffffc0200446 <__panic>
        while (start < end)
ffffffffc0204cf2:	d69b7fe3          	bgeu	s6,s1,ffffffffc0204a70 <do_execve+0x1a6>
ffffffffc0204cf6:	56fd                	li	a3,-1
ffffffffc0204cf8:	00c6d793          	srli	a5,a3,0xc
ffffffffc0204cfc:	f03e                	sd	a5,32(sp)
ffffffffc0204cfe:	a0b9                	j	ffffffffc0204d4c <do_execve+0x482>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d00:	6785                	lui	a5,0x1
ffffffffc0204d02:	00fd8833          	add	a6,s11,a5
                size -= la - end;
ffffffffc0204d06:	416489b3          	sub	s3,s1,s6
            if (end < la)
ffffffffc0204d0a:	0104e463          	bltu	s1,a6,ffffffffc0204d12 <do_execve+0x448>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0204d0e:	416809b3          	sub	s3,a6,s6
    return page - pages + nbase;
ffffffffc0204d12:	000c3683          	ld	a3,0(s8)
    return KADDR(page2pa(page));
ffffffffc0204d16:	7782                	ld	a5,32(sp)
ffffffffc0204d18:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0204d1c:	40d406b3          	sub	a3,s0,a3
ffffffffc0204d20:	8699                	srai	a3,a3,0x6
ffffffffc0204d22:	96de                	add	a3,a3,s7
    return KADDR(page2pa(page));
ffffffffc0204d24:	00f6f533          	and	a0,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0204d28:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204d2a:	06b57263          	bgeu	a0,a1,ffffffffc0204d8e <do_execve+0x4c4>
ffffffffc0204d2e:	000ab583          	ld	a1,0(s5)
ffffffffc0204d32:	41bb0533          	sub	a0,s6,s11
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d36:	864e                	mv	a2,s3
ffffffffc0204d38:	96ae                	add	a3,a3,a1
ffffffffc0204d3a:	9536                	add	a0,a0,a3
ffffffffc0204d3c:	4581                	li	a1,0
            start += size;
ffffffffc0204d3e:	9b4e                	add	s6,s6,s3
ffffffffc0204d40:	e042                	sd	a6,0(sp)
            memset(page2kva(page) + off, 0, size);
ffffffffc0204d42:	29d000ef          	jal	ffffffffc02057de <memset>
        while (start < end)
ffffffffc0204d46:	d29b75e3          	bgeu	s6,s1,ffffffffc0204a70 <do_execve+0x1a6>
ffffffffc0204d4a:	6d82                	ld	s11,0(sp)
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL)
ffffffffc0204d4c:	01893503          	ld	a0,24(s2)
ffffffffc0204d50:	6622                	ld	a2,8(sp)
ffffffffc0204d52:	85ee                	mv	a1,s11
ffffffffc0204d54:	8a7fe0ef          	jal	ffffffffc02035fa <pgdir_alloc_page>
ffffffffc0204d58:	842a                	mv	s0,a0
ffffffffc0204d5a:	f15d                	bnez	a0,ffffffffc0204d00 <do_execve+0x436>
ffffffffc0204d5c:	b5cd                	j	ffffffffc0204c3e <do_execve+0x374>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d5e:	47c5                	li	a5,17
        if (ph->p_flags & ELF_PF_R)
ffffffffc0204d60:	86ba                	mv	a3,a4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0204d62:	e43e                	sd	a5,8(sp)
ffffffffc0204d64:	b581                	j	ffffffffc0204ba4 <do_execve+0x2da>
            perm |= (PTE_W | PTE_R);
ffffffffc0204d66:	47dd                	li	a5,23
            vm_flags |= VM_READ;
ffffffffc0204d68:	00376693          	ori	a3,a4,3
            perm |= (PTE_W | PTE_R);
ffffffffc0204d6c:	e43e                	sd	a5,8(sp)
ffffffffc0204d6e:	bd1d                	j	ffffffffc0204ba4 <do_execve+0x2da>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0204d70:	416d89b3          	sub	s3,s11,s6
ffffffffc0204d74:	bf19                	j	ffffffffc0204c8a <do_execve+0x3c0>
        return -E_INVAL;
ffffffffc0204d76:	54f5                	li	s1,-3
ffffffffc0204d78:	b3fd                	j	ffffffffc0204b66 <do_execve+0x29c>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0204d7a:	8dae                	mv	s11,a1
        while (start < end)
ffffffffc0204d7c:	84da                	mv	s1,s6
ffffffffc0204d7e:	bddd                	j	ffffffffc0204c74 <do_execve+0x3aa>
    int ret = -E_NO_MEM;
ffffffffc0204d80:	54f1                	li	s1,-4
ffffffffc0204d82:	b1ad                	j	ffffffffc02049ec <do_execve+0x122>
ffffffffc0204d84:	6da6                	ld	s11,72(sp)
ffffffffc0204d86:	bd75                	j	ffffffffc0204c42 <do_execve+0x378>
            ret = -E_INVAL_ELF;
ffffffffc0204d88:	6da6                	ld	s11,72(sp)
ffffffffc0204d8a:	54e1                	li	s1,-8
ffffffffc0204d8c:	bd5d                	j	ffffffffc0204c42 <do_execve+0x378>
ffffffffc0204d8e:	00001617          	auipc	a2,0x1
ffffffffc0204d92:	7fa60613          	addi	a2,a2,2042 # ffffffffc0206588 <etext+0xd80>
ffffffffc0204d96:	07100593          	li	a1,113
ffffffffc0204d9a:	00002517          	auipc	a0,0x2
ffffffffc0204d9e:	81650513          	addi	a0,a0,-2026 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0204da2:	ea4fb0ef          	jal	ffffffffc0200446 <__panic>
ffffffffc0204da6:	00001617          	auipc	a2,0x1
ffffffffc0204daa:	7e260613          	addi	a2,a2,2018 # ffffffffc0206588 <etext+0xd80>
ffffffffc0204dae:	07100593          	li	a1,113
ffffffffc0204db2:	00001517          	auipc	a0,0x1
ffffffffc0204db6:	7fe50513          	addi	a0,a0,2046 # ffffffffc02065b0 <etext+0xda8>
ffffffffc0204dba:	f122                	sd	s0,160(sp)
ffffffffc0204dbc:	e152                	sd	s4,128(sp)
ffffffffc0204dbe:	e4ee                	sd	s11,72(sp)
ffffffffc0204dc0:	e86fb0ef          	jal	ffffffffc0200446 <__panic>
    current->pgdir = PADDR(mm->pgdir);
ffffffffc0204dc4:	00002617          	auipc	a2,0x2
ffffffffc0204dc8:	86c60613          	addi	a2,a2,-1940 # ffffffffc0206630 <etext+0xe28>
ffffffffc0204dcc:	2d800593          	li	a1,728
ffffffffc0204dd0:	00002517          	auipc	a0,0x2
ffffffffc0204dd4:	1f050513          	addi	a0,a0,496 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204dd8:	e4ee                	sd	s11,72(sp)
ffffffffc0204dda:	e6cfb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 4 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204dde:	00002697          	auipc	a3,0x2
ffffffffc0204de2:	50a68693          	addi	a3,a3,1290 # ffffffffc02072e8 <etext+0x1ae0>
ffffffffc0204de6:	00001617          	auipc	a2,0x1
ffffffffc0204dea:	3f260613          	addi	a2,a2,1010 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204dee:	2d300593          	li	a1,723
ffffffffc0204df2:	00002517          	auipc	a0,0x2
ffffffffc0204df6:	1ce50513          	addi	a0,a0,462 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204dfa:	e4ee                	sd	s11,72(sp)
ffffffffc0204dfc:	e4afb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 3 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e00:	00002697          	auipc	a3,0x2
ffffffffc0204e04:	4a068693          	addi	a3,a3,1184 # ffffffffc02072a0 <etext+0x1a98>
ffffffffc0204e08:	00001617          	auipc	a2,0x1
ffffffffc0204e0c:	3d060613          	addi	a2,a2,976 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204e10:	2d200593          	li	a1,722
ffffffffc0204e14:	00002517          	auipc	a0,0x2
ffffffffc0204e18:	1ac50513          	addi	a0,a0,428 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204e1c:	e4ee                	sd	s11,72(sp)
ffffffffc0204e1e:	e28fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - 2 * PGSIZE, PTE_USER) != NULL);
ffffffffc0204e22:	00002697          	auipc	a3,0x2
ffffffffc0204e26:	43668693          	addi	a3,a3,1078 # ffffffffc0207258 <etext+0x1a50>
ffffffffc0204e2a:	00001617          	auipc	a2,0x1
ffffffffc0204e2e:	3ae60613          	addi	a2,a2,942 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204e32:	2d100593          	li	a1,721
ffffffffc0204e36:	00002517          	auipc	a0,0x2
ffffffffc0204e3a:	18a50513          	addi	a0,a0,394 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204e3e:	e4ee                	sd	s11,72(sp)
ffffffffc0204e40:	e06fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP - PGSIZE, PTE_USER) != NULL);
ffffffffc0204e44:	00002697          	auipc	a3,0x2
ffffffffc0204e48:	3cc68693          	addi	a3,a3,972 # ffffffffc0207210 <etext+0x1a08>
ffffffffc0204e4c:	00001617          	auipc	a2,0x1
ffffffffc0204e50:	38c60613          	addi	a2,a2,908 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0204e54:	2d000593          	li	a1,720
ffffffffc0204e58:	00002517          	auipc	a0,0x2
ffffffffc0204e5c:	16850513          	addi	a0,a0,360 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0204e60:	e4ee                	sd	s11,72(sp)
ffffffffc0204e62:	de4fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0204e66 <do_yield>:
    current->need_resched = 1;
ffffffffc0204e66:	00097797          	auipc	a5,0x97
ffffffffc0204e6a:	bb27b783          	ld	a5,-1102(a5) # ffffffffc029ba18 <current>
ffffffffc0204e6e:	4705                	li	a4,1
}
ffffffffc0204e70:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0204e72:	ef98                	sd	a4,24(a5)
}
ffffffffc0204e74:	8082                	ret

ffffffffc0204e76 <do_wait>:
    if (code_store != NULL)
ffffffffc0204e76:	c59d                	beqz	a1,ffffffffc0204ea4 <do_wait+0x2e>
{
ffffffffc0204e78:	1101                	addi	sp,sp,-32
ffffffffc0204e7a:	e02a                	sd	a0,0(sp)
    struct mm_struct *mm = current->mm;
ffffffffc0204e7c:	00097517          	auipc	a0,0x97
ffffffffc0204e80:	b9c53503          	ld	a0,-1124(a0) # ffffffffc029ba18 <current>
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e84:	4685                	li	a3,1
ffffffffc0204e86:	4611                	li	a2,4
ffffffffc0204e88:	7508                	ld	a0,40(a0)
{
ffffffffc0204e8a:	ec06                	sd	ra,24(sp)
ffffffffc0204e8c:	e42e                	sd	a1,8(sp)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1))
ffffffffc0204e8e:	edbfe0ef          	jal	ffffffffc0203d68 <user_mem_check>
ffffffffc0204e92:	6702                	ld	a4,0(sp)
ffffffffc0204e94:	67a2                	ld	a5,8(sp)
ffffffffc0204e96:	c909                	beqz	a0,ffffffffc0204ea8 <do_wait+0x32>
}
ffffffffc0204e98:	60e2                	ld	ra,24(sp)
ffffffffc0204e9a:	85be                	mv	a1,a5
ffffffffc0204e9c:	853a                	mv	a0,a4
ffffffffc0204e9e:	6105                	addi	sp,sp,32
ffffffffc0204ea0:	f24ff06f          	j	ffffffffc02045c4 <do_wait.part.0>
ffffffffc0204ea4:	f20ff06f          	j	ffffffffc02045c4 <do_wait.part.0>
ffffffffc0204ea8:	60e2                	ld	ra,24(sp)
ffffffffc0204eaa:	5575                	li	a0,-3
ffffffffc0204eac:	6105                	addi	sp,sp,32
ffffffffc0204eae:	8082                	ret

ffffffffc0204eb0 <do_kill>:
    if (0 < pid && pid < MAX_PID)
ffffffffc0204eb0:	6789                	lui	a5,0x2
ffffffffc0204eb2:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204eb6:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc0204eb8:	06e7e463          	bltu	a5,a4,ffffffffc0204f20 <do_kill+0x70>
{
ffffffffc0204ebc:	1101                	addi	sp,sp,-32
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ebe:	45a9                	li	a1,10
{
ffffffffc0204ec0:	ec06                	sd	ra,24(sp)
ffffffffc0204ec2:	e42a                	sd	a0,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204ec4:	484000ef          	jal	ffffffffc0205348 <hash32>
ffffffffc0204ec8:	02051793          	slli	a5,a0,0x20
ffffffffc0204ecc:	01c7d693          	srli	a3,a5,0x1c
ffffffffc0204ed0:	00093797          	auipc	a5,0x93
ffffffffc0204ed4:	ad078793          	addi	a5,a5,-1328 # ffffffffc02979a0 <hash_list>
ffffffffc0204ed8:	96be                	add	a3,a3,a5
        while ((le = list_next(le)) != list)
ffffffffc0204eda:	6622                	ld	a2,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204edc:	8536                	mv	a0,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ede:	a029                	j	ffffffffc0204ee8 <do_kill+0x38>
            if (proc->pid == pid)
ffffffffc0204ee0:	f2c52703          	lw	a4,-212(a0)
ffffffffc0204ee4:	00c70963          	beq	a4,a2,ffffffffc0204ef6 <do_kill+0x46>
ffffffffc0204ee8:	6508                	ld	a0,8(a0)
        while ((le = list_next(le)) != list)
ffffffffc0204eea:	fea69be3          	bne	a3,a0,ffffffffc0204ee0 <do_kill+0x30>
}
ffffffffc0204eee:	60e2                	ld	ra,24(sp)
    return -E_INVAL;
ffffffffc0204ef0:	5575                	li	a0,-3
}
ffffffffc0204ef2:	6105                	addi	sp,sp,32
ffffffffc0204ef4:	8082                	ret
        if (!(proc->flags & PF_EXITING))
ffffffffc0204ef6:	fd852703          	lw	a4,-40(a0)
ffffffffc0204efa:	00177693          	andi	a3,a4,1
ffffffffc0204efe:	e29d                	bnez	a3,ffffffffc0204f24 <do_kill+0x74>
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f00:	4954                	lw	a3,20(a0)
            proc->flags |= PF_EXITING;
ffffffffc0204f02:	00176713          	ori	a4,a4,1
ffffffffc0204f06:	fce52c23          	sw	a4,-40(a0)
            if (proc->wait_state & WT_INTERRUPTED)
ffffffffc0204f0a:	0006c663          	bltz	a3,ffffffffc0204f16 <do_kill+0x66>
            return 0;
ffffffffc0204f0e:	4501                	li	a0,0
}
ffffffffc0204f10:	60e2                	ld	ra,24(sp)
ffffffffc0204f12:	6105                	addi	sp,sp,32
ffffffffc0204f14:	8082                	ret
                wakeup_proc(proc);
ffffffffc0204f16:	f2850513          	addi	a0,a0,-216
ffffffffc0204f1a:	232000ef          	jal	ffffffffc020514c <wakeup_proc>
ffffffffc0204f1e:	bfc5                	j	ffffffffc0204f0e <do_kill+0x5e>
    return -E_INVAL;
ffffffffc0204f20:	5575                	li	a0,-3
}
ffffffffc0204f22:	8082                	ret
        return -E_KILLED;
ffffffffc0204f24:	555d                	li	a0,-9
ffffffffc0204f26:	b7ed                	j	ffffffffc0204f10 <do_kill+0x60>

ffffffffc0204f28 <proc_init>:

// proc_init - set up the first kernel thread idleproc "idle" by itself and
//           - create the second kernel thread init_main
void proc_init(void)
{
ffffffffc0204f28:	1101                	addi	sp,sp,-32
ffffffffc0204f2a:	e426                	sd	s1,8(sp)
    elm->prev = elm->next = elm;
ffffffffc0204f2c:	00097797          	auipc	a5,0x97
ffffffffc0204f30:	a7478793          	addi	a5,a5,-1420 # ffffffffc029b9a0 <proc_list>
ffffffffc0204f34:	ec06                	sd	ra,24(sp)
ffffffffc0204f36:	e822                	sd	s0,16(sp)
ffffffffc0204f38:	e04a                	sd	s2,0(sp)
ffffffffc0204f3a:	00093497          	auipc	s1,0x93
ffffffffc0204f3e:	a6648493          	addi	s1,s1,-1434 # ffffffffc02979a0 <hash_list>
ffffffffc0204f42:	e79c                	sd	a5,8(a5)
ffffffffc0204f44:	e39c                	sd	a5,0(a5)
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i++)
ffffffffc0204f46:	00097717          	auipc	a4,0x97
ffffffffc0204f4a:	a5a70713          	addi	a4,a4,-1446 # ffffffffc029b9a0 <proc_list>
ffffffffc0204f4e:	87a6                	mv	a5,s1
ffffffffc0204f50:	e79c                	sd	a5,8(a5)
ffffffffc0204f52:	e39c                	sd	a5,0(a5)
ffffffffc0204f54:	07c1                	addi	a5,a5,16
ffffffffc0204f56:	fee79de3          	bne	a5,a4,ffffffffc0204f50 <proc_init+0x28>
    {
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL)
ffffffffc0204f5a:	ebbfe0ef          	jal	ffffffffc0203e14 <alloc_proc>
ffffffffc0204f5e:	00097917          	auipc	s2,0x97
ffffffffc0204f62:	aca90913          	addi	s2,s2,-1334 # ffffffffc029ba28 <idleproc>
ffffffffc0204f66:	00a93023          	sd	a0,0(s2)
ffffffffc0204f6a:	10050363          	beqz	a0,ffffffffc0205070 <proc_init+0x148>
    {
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0204f6e:	4789                	li	a5,2
ffffffffc0204f70:	e11c                	sd	a5,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0204f72:	00003797          	auipc	a5,0x3
ffffffffc0204f76:	08e78793          	addi	a5,a5,142 # ffffffffc0208000 <bootstack>
ffffffffc0204f7a:	e91c                	sd	a5,16(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f7c:	0b450413          	addi	s0,a0,180
    idleproc->need_resched = 1;
ffffffffc0204f80:	4785                	li	a5,1
ffffffffc0204f82:	ed1c                	sd	a5,24(a0)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204f84:	4641                	li	a2,16
ffffffffc0204f86:	8522                	mv	a0,s0
ffffffffc0204f88:	4581                	li	a1,0
ffffffffc0204f8a:	055000ef          	jal	ffffffffc02057de <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204f8e:	8522                	mv	a0,s0
ffffffffc0204f90:	463d                	li	a2,15
ffffffffc0204f92:	00002597          	auipc	a1,0x2
ffffffffc0204f96:	3b658593          	addi	a1,a1,950 # ffffffffc0207348 <etext+0x1b40>
ffffffffc0204f9a:	057000ef          	jal	ffffffffc02057f0 <memcpy>
    set_proc_name(idleproc, "idle");
    nr_process++;
ffffffffc0204f9e:	00097797          	auipc	a5,0x97
ffffffffc0204fa2:	a727a783          	lw	a5,-1422(a5) # ffffffffc029ba10 <nr_process>

    current = idleproc;
ffffffffc0204fa6:	00093703          	ld	a4,0(s2)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204faa:	4601                	li	a2,0
    nr_process++;
ffffffffc0204fac:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fae:	4581                	li	a1,0
ffffffffc0204fb0:	fffff517          	auipc	a0,0xfffff
ffffffffc0204fb4:	7f650513          	addi	a0,a0,2038 # ffffffffc02047a6 <init_main>
    current = idleproc;
ffffffffc0204fb8:	00097697          	auipc	a3,0x97
ffffffffc0204fbc:	a6e6b023          	sd	a4,-1440(a3) # ffffffffc029ba18 <current>
    nr_process++;
ffffffffc0204fc0:	00097717          	auipc	a4,0x97
ffffffffc0204fc4:	a4f72823          	sw	a5,-1456(a4) # ffffffffc029ba10 <nr_process>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0204fc8:	c68ff0ef          	jal	ffffffffc0204430 <kernel_thread>
ffffffffc0204fcc:	842a                	mv	s0,a0
    if (pid <= 0)
ffffffffc0204fce:	08a05563          	blez	a0,ffffffffc0205058 <proc_init+0x130>
    if (0 < pid && pid < MAX_PID)
ffffffffc0204fd2:	6789                	lui	a5,0x2
ffffffffc0204fd4:	17f9                	addi	a5,a5,-2 # 1ffe <_binary_obj___user_softint_out_size-0x6c0a>
ffffffffc0204fd6:	fff5071b          	addiw	a4,a0,-1
ffffffffc0204fda:	02e7e463          	bltu	a5,a4,ffffffffc0205002 <proc_init+0xda>
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204fde:	45a9                	li	a1,10
ffffffffc0204fe0:	368000ef          	jal	ffffffffc0205348 <hash32>
ffffffffc0204fe4:	02051713          	slli	a4,a0,0x20
ffffffffc0204fe8:	01c75793          	srli	a5,a4,0x1c
ffffffffc0204fec:	00f486b3          	add	a3,s1,a5
ffffffffc0204ff0:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list)
ffffffffc0204ff2:	a029                	j	ffffffffc0204ffc <proc_init+0xd4>
            if (proc->pid == pid)
ffffffffc0204ff4:	f2c7a703          	lw	a4,-212(a5)
ffffffffc0204ff8:	04870d63          	beq	a4,s0,ffffffffc0205052 <proc_init+0x12a>
    return listelm->next;
ffffffffc0204ffc:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list)
ffffffffc0204ffe:	fef69be3          	bne	a3,a5,ffffffffc0204ff4 <proc_init+0xcc>
    return NULL;
ffffffffc0205002:	4781                	li	a5,0
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205004:	0b478413          	addi	s0,a5,180
ffffffffc0205008:	4641                	li	a2,16
ffffffffc020500a:	4581                	li	a1,0
ffffffffc020500c:	8522                	mv	a0,s0
    {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc020500e:	00097717          	auipc	a4,0x97
ffffffffc0205012:	a0f73923          	sd	a5,-1518(a4) # ffffffffc029ba20 <initproc>
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0205016:	7c8000ef          	jal	ffffffffc02057de <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc020501a:	8522                	mv	a0,s0
ffffffffc020501c:	463d                	li	a2,15
ffffffffc020501e:	00002597          	auipc	a1,0x2
ffffffffc0205022:	35258593          	addi	a1,a1,850 # ffffffffc0207370 <etext+0x1b68>
ffffffffc0205026:	7ca000ef          	jal	ffffffffc02057f0 <memcpy>
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc020502a:	00093783          	ld	a5,0(s2)
ffffffffc020502e:	cfad                	beqz	a5,ffffffffc02050a8 <proc_init+0x180>
ffffffffc0205030:	43dc                	lw	a5,4(a5)
ffffffffc0205032:	ebbd                	bnez	a5,ffffffffc02050a8 <proc_init+0x180>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205034:	00097797          	auipc	a5,0x97
ffffffffc0205038:	9ec7b783          	ld	a5,-1556(a5) # ffffffffc029ba20 <initproc>
ffffffffc020503c:	c7b1                	beqz	a5,ffffffffc0205088 <proc_init+0x160>
ffffffffc020503e:	43d8                	lw	a4,4(a5)
ffffffffc0205040:	4785                	li	a5,1
ffffffffc0205042:	04f71363          	bne	a4,a5,ffffffffc0205088 <proc_init+0x160>
}
ffffffffc0205046:	60e2                	ld	ra,24(sp)
ffffffffc0205048:	6442                	ld	s0,16(sp)
ffffffffc020504a:	64a2                	ld	s1,8(sp)
ffffffffc020504c:	6902                	ld	s2,0(sp)
ffffffffc020504e:	6105                	addi	sp,sp,32
ffffffffc0205050:	8082                	ret
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0205052:	f2878793          	addi	a5,a5,-216
ffffffffc0205056:	b77d                	j	ffffffffc0205004 <proc_init+0xdc>
        panic("create init_main failed.\n");
ffffffffc0205058:	00002617          	auipc	a2,0x2
ffffffffc020505c:	2f860613          	addi	a2,a2,760 # ffffffffc0207350 <etext+0x1b48>
ffffffffc0205060:	3fe00593          	li	a1,1022
ffffffffc0205064:	00002517          	auipc	a0,0x2
ffffffffc0205068:	f5c50513          	addi	a0,a0,-164 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc020506c:	bdafb0ef          	jal	ffffffffc0200446 <__panic>
        panic("cannot alloc idleproc.\n");
ffffffffc0205070:	00002617          	auipc	a2,0x2
ffffffffc0205074:	2c060613          	addi	a2,a2,704 # ffffffffc0207330 <etext+0x1b28>
ffffffffc0205078:	3ef00593          	li	a1,1007
ffffffffc020507c:	00002517          	auipc	a0,0x2
ffffffffc0205080:	f4450513          	addi	a0,a0,-188 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc0205084:	bc2fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205088:	00002697          	auipc	a3,0x2
ffffffffc020508c:	31868693          	addi	a3,a3,792 # ffffffffc02073a0 <etext+0x1b98>
ffffffffc0205090:	00001617          	auipc	a2,0x1
ffffffffc0205094:	14860613          	addi	a2,a2,328 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc0205098:	40500593          	li	a1,1029
ffffffffc020509c:	00002517          	auipc	a0,0x2
ffffffffc02050a0:	f2450513          	addi	a0,a0,-220 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02050a4:	ba2fb0ef          	jal	ffffffffc0200446 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc02050a8:	00002697          	auipc	a3,0x2
ffffffffc02050ac:	2d068693          	addi	a3,a3,720 # ffffffffc0207378 <etext+0x1b70>
ffffffffc02050b0:	00001617          	auipc	a2,0x1
ffffffffc02050b4:	12860613          	addi	a2,a2,296 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02050b8:	40400593          	li	a1,1028
ffffffffc02050bc:	00002517          	auipc	a0,0x2
ffffffffc02050c0:	f0450513          	addi	a0,a0,-252 # ffffffffc0206fc0 <etext+0x17b8>
ffffffffc02050c4:	b82fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02050c8 <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void cpu_idle(void)
{
ffffffffc02050c8:	1141                	addi	sp,sp,-16
ffffffffc02050ca:	e022                	sd	s0,0(sp)
ffffffffc02050cc:	e406                	sd	ra,8(sp)
ffffffffc02050ce:	00097417          	auipc	s0,0x97
ffffffffc02050d2:	94a40413          	addi	s0,s0,-1718 # ffffffffc029ba18 <current>
    while (1)
    {
        if (current->need_resched)
ffffffffc02050d6:	6018                	ld	a4,0(s0)
ffffffffc02050d8:	6f1c                	ld	a5,24(a4)
ffffffffc02050da:	dffd                	beqz	a5,ffffffffc02050d8 <cpu_idle+0x10>
        {
            schedule();
ffffffffc02050dc:	104000ef          	jal	ffffffffc02051e0 <schedule>
ffffffffc02050e0:	bfdd                	j	ffffffffc02050d6 <cpu_idle+0xe>

ffffffffc02050e2 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc02050e2:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc02050e6:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc02050ea:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc02050ec:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc02050ee:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc02050f2:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc02050f6:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc02050fa:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc02050fe:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205102:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205106:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc020510a:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc020510e:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205112:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205116:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc020511a:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc020511e:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205120:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205122:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205126:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc020512a:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc020512e:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205132:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205136:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc020513a:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc020513e:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205142:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205146:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc020514a:	8082                	ret

ffffffffc020514c <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void wakeup_proc(struct proc_struct *proc)
{
    assert(proc->state != PROC_ZOMBIE);
ffffffffc020514c:	4118                	lw	a4,0(a0)
{
ffffffffc020514e:	1101                	addi	sp,sp,-32
ffffffffc0205150:	ec06                	sd	ra,24(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205152:	478d                	li	a5,3
ffffffffc0205154:	06f70763          	beq	a4,a5,ffffffffc02051c2 <wakeup_proc+0x76>
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc0205158:	100027f3          	csrr	a5,sstatus
ffffffffc020515c:	8b89                	andi	a5,a5,2
ffffffffc020515e:	eb91                	bnez	a5,ffffffffc0205172 <wakeup_proc+0x26>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205160:	4789                	li	a5,2
ffffffffc0205162:	02f70763          	beq	a4,a5,ffffffffc0205190 <wakeup_proc+0x44>
        {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205166:	60e2                	ld	ra,24(sp)
            proc->state = PROC_RUNNABLE;
ffffffffc0205168:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc020516a:	0e052623          	sw	zero,236(a0)
}
ffffffffc020516e:	6105                	addi	sp,sp,32
ffffffffc0205170:	8082                	ret
        intr_disable();
ffffffffc0205172:	e42a                	sd	a0,8(sp)
ffffffffc0205174:	f90fb0ef          	jal	ffffffffc0200904 <intr_disable>
        if (proc->state != PROC_RUNNABLE)
ffffffffc0205178:	6522                	ld	a0,8(sp)
ffffffffc020517a:	4789                	li	a5,2
ffffffffc020517c:	4118                	lw	a4,0(a0)
ffffffffc020517e:	02f70663          	beq	a4,a5,ffffffffc02051aa <wakeup_proc+0x5e>
            proc->state = PROC_RUNNABLE;
ffffffffc0205182:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205184:	0e052623          	sw	zero,236(a0)
}
ffffffffc0205188:	60e2                	ld	ra,24(sp)
ffffffffc020518a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020518c:	f72fb06f          	j	ffffffffc02008fe <intr_enable>
ffffffffc0205190:	60e2                	ld	ra,24(sp)
            warn("wakeup runnable process.\n");
ffffffffc0205192:	00002617          	auipc	a2,0x2
ffffffffc0205196:	26e60613          	addi	a2,a2,622 # ffffffffc0207400 <etext+0x1bf8>
ffffffffc020519a:	45d1                	li	a1,20
ffffffffc020519c:	00002517          	auipc	a0,0x2
ffffffffc02051a0:	24c50513          	addi	a0,a0,588 # ffffffffc02073e8 <etext+0x1be0>
}
ffffffffc02051a4:	6105                	addi	sp,sp,32
            warn("wakeup runnable process.\n");
ffffffffc02051a6:	b0afb06f          	j	ffffffffc02004b0 <__warn>
ffffffffc02051aa:	00002617          	auipc	a2,0x2
ffffffffc02051ae:	25660613          	addi	a2,a2,598 # ffffffffc0207400 <etext+0x1bf8>
ffffffffc02051b2:	45d1                	li	a1,20
ffffffffc02051b4:	00002517          	auipc	a0,0x2
ffffffffc02051b8:	23450513          	addi	a0,a0,564 # ffffffffc02073e8 <etext+0x1be0>
ffffffffc02051bc:	af4fb0ef          	jal	ffffffffc02004b0 <__warn>
    if (flag)
ffffffffc02051c0:	b7e1                	j	ffffffffc0205188 <wakeup_proc+0x3c>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc02051c2:	00002697          	auipc	a3,0x2
ffffffffc02051c6:	20668693          	addi	a3,a3,518 # ffffffffc02073c8 <etext+0x1bc0>
ffffffffc02051ca:	00001617          	auipc	a2,0x1
ffffffffc02051ce:	00e60613          	addi	a2,a2,14 # ffffffffc02061d8 <etext+0x9d0>
ffffffffc02051d2:	45a5                	li	a1,9
ffffffffc02051d4:	00002517          	auipc	a0,0x2
ffffffffc02051d8:	21450513          	addi	a0,a0,532 # ffffffffc02073e8 <etext+0x1be0>
ffffffffc02051dc:	a6afb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc02051e0 <schedule>:

void schedule(void)
{
ffffffffc02051e0:	1101                	addi	sp,sp,-32
ffffffffc02051e2:	ec06                	sd	ra,24(sp)
    if (read_csr(sstatus) & SSTATUS_SIE)
ffffffffc02051e4:	100027f3          	csrr	a5,sstatus
ffffffffc02051e8:	8b89                	andi	a5,a5,2
ffffffffc02051ea:	4301                	li	t1,0
ffffffffc02051ec:	e3c1                	bnez	a5,ffffffffc020526c <schedule+0x8c>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc02051ee:	00097897          	auipc	a7,0x97
ffffffffc02051f2:	82a8b883          	ld	a7,-2006(a7) # ffffffffc029ba18 <current>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc02051f6:	00097517          	auipc	a0,0x97
ffffffffc02051fa:	83253503          	ld	a0,-1998(a0) # ffffffffc029ba28 <idleproc>
        current->need_resched = 0;
ffffffffc02051fe:	0008bc23          	sd	zero,24(a7)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205202:	04a88f63          	beq	a7,a0,ffffffffc0205260 <schedule+0x80>
ffffffffc0205206:	0c888693          	addi	a3,a7,200
ffffffffc020520a:	00096617          	auipc	a2,0x96
ffffffffc020520e:	79660613          	addi	a2,a2,1942 # ffffffffc029b9a0 <proc_list>
        le = last;
ffffffffc0205212:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0205214:	4581                	li	a1,0
        do
        {
            if ((le = list_next(le)) != &proc_list)
            {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE)
ffffffffc0205216:	4809                	li	a6,2
ffffffffc0205218:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list)
ffffffffc020521a:	00c78863          	beq	a5,a2,ffffffffc020522a <schedule+0x4a>
                if (next->state == PROC_RUNNABLE)
ffffffffc020521e:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0205222:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE)
ffffffffc0205226:	03070363          	beq	a4,a6,ffffffffc020524c <schedule+0x6c>
                {
                    break;
                }
            }
        } while (le != last);
ffffffffc020522a:	fef697e3          	bne	a3,a5,ffffffffc0205218 <schedule+0x38>
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020522e:	ed99                	bnez	a1,ffffffffc020524c <schedule+0x6c>
        {
            next = idleproc;
        }
        next->runs++;
ffffffffc0205230:	451c                	lw	a5,8(a0)
ffffffffc0205232:	2785                	addiw	a5,a5,1
ffffffffc0205234:	c51c                	sw	a5,8(a0)
        if (next != current)
ffffffffc0205236:	00a88663          	beq	a7,a0,ffffffffc0205242 <schedule+0x62>
ffffffffc020523a:	e41a                	sd	t1,8(sp)
        {
            proc_run(next);
ffffffffc020523c:	d4dfe0ef          	jal	ffffffffc0203f88 <proc_run>
ffffffffc0205240:	6322                	ld	t1,8(sp)
    if (flag)
ffffffffc0205242:	00031b63          	bnez	t1,ffffffffc0205258 <schedule+0x78>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205246:	60e2                	ld	ra,24(sp)
ffffffffc0205248:	6105                	addi	sp,sp,32
ffffffffc020524a:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE)
ffffffffc020524c:	4198                	lw	a4,0(a1)
ffffffffc020524e:	4789                	li	a5,2
ffffffffc0205250:	fef710e3          	bne	a4,a5,ffffffffc0205230 <schedule+0x50>
ffffffffc0205254:	852e                	mv	a0,a1
ffffffffc0205256:	bfe9                	j	ffffffffc0205230 <schedule+0x50>
}
ffffffffc0205258:	60e2                	ld	ra,24(sp)
ffffffffc020525a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc020525c:	ea2fb06f          	j	ffffffffc02008fe <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205260:	00096617          	auipc	a2,0x96
ffffffffc0205264:	74060613          	addi	a2,a2,1856 # ffffffffc029b9a0 <proc_list>
ffffffffc0205268:	86b2                	mv	a3,a2
ffffffffc020526a:	b765                	j	ffffffffc0205212 <schedule+0x32>
        intr_disable();
ffffffffc020526c:	e98fb0ef          	jal	ffffffffc0200904 <intr_disable>
        return 1;
ffffffffc0205270:	4305                	li	t1,1
ffffffffc0205272:	bfb5                	j	ffffffffc02051ee <schedule+0xe>

ffffffffc0205274 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0205274:	00096797          	auipc	a5,0x96
ffffffffc0205278:	7a47b783          	ld	a5,1956(a5) # ffffffffc029ba18 <current>
}
ffffffffc020527c:	43c8                	lw	a0,4(a5)
ffffffffc020527e:	8082                	ret

ffffffffc0205280 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0205280:	4501                	li	a0,0
ffffffffc0205282:	8082                	ret

ffffffffc0205284 <sys_putc>:
    cputchar(c);
ffffffffc0205284:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0205286:	1141                	addi	sp,sp,-16
ffffffffc0205288:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020528a:	f3ffa0ef          	jal	ffffffffc02001c8 <cputchar>
}
ffffffffc020528e:	60a2                	ld	ra,8(sp)
ffffffffc0205290:	4501                	li	a0,0
ffffffffc0205292:	0141                	addi	sp,sp,16
ffffffffc0205294:	8082                	ret

ffffffffc0205296 <sys_kill>:
    return do_kill(pid);
ffffffffc0205296:	4108                	lw	a0,0(a0)
ffffffffc0205298:	c19ff06f          	j	ffffffffc0204eb0 <do_kill>

ffffffffc020529c <sys_yield>:
    return do_yield();
ffffffffc020529c:	bcbff06f          	j	ffffffffc0204e66 <do_yield>

ffffffffc02052a0 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc02052a0:	6d14                	ld	a3,24(a0)
ffffffffc02052a2:	6910                	ld	a2,16(a0)
ffffffffc02052a4:	650c                	ld	a1,8(a0)
ffffffffc02052a6:	6108                	ld	a0,0(a0)
ffffffffc02052a8:	e22ff06f          	j	ffffffffc02048ca <do_execve>

ffffffffc02052ac <sys_wait>:
    return do_wait(pid, store);
ffffffffc02052ac:	650c                	ld	a1,8(a0)
ffffffffc02052ae:	4108                	lw	a0,0(a0)
ffffffffc02052b0:	bc7ff06f          	j	ffffffffc0204e76 <do_wait>

ffffffffc02052b4 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02052b4:	00096797          	auipc	a5,0x96
ffffffffc02052b8:	7647b783          	ld	a5,1892(a5) # ffffffffc029ba18 <current>
    return do_fork(0, stack, tf);
ffffffffc02052bc:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02052be:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02052c0:	6a0c                	ld	a1,16(a2)
ffffffffc02052c2:	d29fe06f          	j	ffffffffc0203fea <do_fork>

ffffffffc02052c6 <sys_exit>:
    return do_exit(error_code);
ffffffffc02052c6:	4108                	lw	a0,0(a0)
ffffffffc02052c8:	9b8ff06f          	j	ffffffffc0204480 <do_exit>

ffffffffc02052cc <syscall>:

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
    struct trapframe *tf = current->tf;
ffffffffc02052cc:	00096697          	auipc	a3,0x96
ffffffffc02052d0:	74c6b683          	ld	a3,1868(a3) # ffffffffc029ba18 <current>
syscall(void) {
ffffffffc02052d4:	715d                	addi	sp,sp,-80
ffffffffc02052d6:	e0a2                	sd	s0,64(sp)
    struct trapframe *tf = current->tf;
ffffffffc02052d8:	72c0                	ld	s0,160(a3)
syscall(void) {
ffffffffc02052da:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02052dc:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02052de:	4834                	lw	a3,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02052e0:	02d7ec63          	bltu	a5,a3,ffffffffc0205318 <syscall+0x4c>
        if (syscalls[num] != NULL) {
ffffffffc02052e4:	00002797          	auipc	a5,0x2
ffffffffc02052e8:	36478793          	addi	a5,a5,868 # ffffffffc0207648 <syscalls>
ffffffffc02052ec:	00369613          	slli	a2,a3,0x3
ffffffffc02052f0:	97b2                	add	a5,a5,a2
ffffffffc02052f2:	639c                	ld	a5,0(a5)
ffffffffc02052f4:	c395                	beqz	a5,ffffffffc0205318 <syscall+0x4c>
            arg[0] = tf->gpr.a1;
ffffffffc02052f6:	7028                	ld	a0,96(s0)
ffffffffc02052f8:	742c                	ld	a1,104(s0)
ffffffffc02052fa:	7830                	ld	a2,112(s0)
ffffffffc02052fc:	7c34                	ld	a3,120(s0)
ffffffffc02052fe:	6c38                	ld	a4,88(s0)
ffffffffc0205300:	f02a                	sd	a0,32(sp)
ffffffffc0205302:	f42e                	sd	a1,40(sp)
ffffffffc0205304:	f832                	sd	a2,48(sp)
ffffffffc0205306:	fc36                	sd	a3,56(sp)
ffffffffc0205308:	ec3a                	sd	a4,24(sp)
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc020530a:	0828                	addi	a0,sp,24
ffffffffc020530c:	9782                	jalr	a5
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020530e:	60a6                	ld	ra,72(sp)
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0205310:	e828                	sd	a0,80(s0)
}
ffffffffc0205312:	6406                	ld	s0,64(sp)
ffffffffc0205314:	6161                	addi	sp,sp,80
ffffffffc0205316:	8082                	ret
    print_trapframe(tf);
ffffffffc0205318:	8522                	mv	a0,s0
ffffffffc020531a:	e436                	sd	a3,8(sp)
ffffffffc020531c:	fd8fb0ef          	jal	ffffffffc0200af4 <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc0205320:	00096797          	auipc	a5,0x96
ffffffffc0205324:	6f87b783          	ld	a5,1784(a5) # ffffffffc029ba18 <current>
ffffffffc0205328:	66a2                	ld	a3,8(sp)
ffffffffc020532a:	00002617          	auipc	a2,0x2
ffffffffc020532e:	0f660613          	addi	a2,a2,246 # ffffffffc0207420 <etext+0x1c18>
ffffffffc0205332:	43d8                	lw	a4,4(a5)
ffffffffc0205334:	06200593          	li	a1,98
ffffffffc0205338:	0b478793          	addi	a5,a5,180
ffffffffc020533c:	00002517          	auipc	a0,0x2
ffffffffc0205340:	11450513          	addi	a0,a0,276 # ffffffffc0207450 <etext+0x1c48>
ffffffffc0205344:	902fb0ef          	jal	ffffffffc0200446 <__panic>

ffffffffc0205348 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0205348:	9e3707b7          	lui	a5,0x9e370
ffffffffc020534c:	2785                	addiw	a5,a5,1 # ffffffff9e370001 <_binary_obj___user_exit_out_size+0xffffffff9e365e09>
ffffffffc020534e:	02a787bb          	mulw	a5,a5,a0
    return (hash >> (32 - bits));
ffffffffc0205352:	02000513          	li	a0,32
ffffffffc0205356:	9d0d                	subw	a0,a0,a1
}
ffffffffc0205358:	00a7d53b          	srlw	a0,a5,a0
ffffffffc020535c:	8082                	ret

ffffffffc020535e <printnum>:
 * @width:      maximum number of digits, if the actual width is less than @width, use @padc instead
 * @padc:       character that padded on the left if the actual width is less than @width
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020535e:	7179                	addi	sp,sp,-48
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0205360:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205364:	f022                	sd	s0,32(sp)
ffffffffc0205366:	ec26                	sd	s1,24(sp)
ffffffffc0205368:	e84a                	sd	s2,16(sp)
ffffffffc020536a:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc020536c:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0205370:	f406                	sd	ra,40(sp)
    unsigned mod = do_div(result, base);
ffffffffc0205372:	03067a33          	remu	s4,a2,a6
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0205376:	fff7041b          	addiw	s0,a4,-1
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020537a:	84aa                	mv	s1,a0
ffffffffc020537c:	892e                	mv	s2,a1
    if (num >= base) {
ffffffffc020537e:	03067d63          	bgeu	a2,a6,ffffffffc02053b8 <printnum+0x5a>
ffffffffc0205382:	e44e                	sd	s3,8(sp)
ffffffffc0205384:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0205386:	4785                	li	a5,1
ffffffffc0205388:	00e7d763          	bge	a5,a4,ffffffffc0205396 <printnum+0x38>
            putch(padc, putdat);
ffffffffc020538c:	85ca                	mv	a1,s2
ffffffffc020538e:	854e                	mv	a0,s3
        while (-- width > 0)
ffffffffc0205390:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0205392:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0205394:	fc65                	bnez	s0,ffffffffc020538c <printnum+0x2e>
ffffffffc0205396:	69a2                	ld	s3,8(sp)
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0205398:	00002797          	auipc	a5,0x2
ffffffffc020539c:	0d078793          	addi	a5,a5,208 # ffffffffc0207468 <etext+0x1c60>
ffffffffc02053a0:	97d2                	add	a5,a5,s4
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02053a2:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053a4:	0007c503          	lbu	a0,0(a5)
}
ffffffffc02053a8:	70a2                	ld	ra,40(sp)
ffffffffc02053aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053ac:	85ca                	mv	a1,s2
ffffffffc02053ae:	87a6                	mv	a5,s1
}
ffffffffc02053b0:	6942                	ld	s2,16(sp)
ffffffffc02053b2:	64e2                	ld	s1,24(sp)
ffffffffc02053b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02053b6:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02053b8:	03065633          	divu	a2,a2,a6
ffffffffc02053bc:	8722                	mv	a4,s0
ffffffffc02053be:	fa1ff0ef          	jal	ffffffffc020535e <printnum>
ffffffffc02053c2:	bfd9                	j	ffffffffc0205398 <printnum+0x3a>

ffffffffc02053c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02053c4:	7119                	addi	sp,sp,-128
ffffffffc02053c6:	f4a6                	sd	s1,104(sp)
ffffffffc02053c8:	f0ca                	sd	s2,96(sp)
ffffffffc02053ca:	ecce                	sd	s3,88(sp)
ffffffffc02053cc:	e8d2                	sd	s4,80(sp)
ffffffffc02053ce:	e4d6                	sd	s5,72(sp)
ffffffffc02053d0:	e0da                	sd	s6,64(sp)
ffffffffc02053d2:	f862                	sd	s8,48(sp)
ffffffffc02053d4:	fc86                	sd	ra,120(sp)
ffffffffc02053d6:	f8a2                	sd	s0,112(sp)
ffffffffc02053d8:	fc5e                	sd	s7,56(sp)
ffffffffc02053da:	f466                	sd	s9,40(sp)
ffffffffc02053dc:	f06a                	sd	s10,32(sp)
ffffffffc02053de:	ec6e                	sd	s11,24(sp)
ffffffffc02053e0:	84aa                	mv	s1,a0
ffffffffc02053e2:	8c32                	mv	s8,a2
ffffffffc02053e4:	8a36                	mv	s4,a3
ffffffffc02053e6:	892e                	mv	s2,a1
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053e8:	02500993          	li	s3,37
        char padc = ' ';
        width = precision = -1;
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02053ec:	05500b13          	li	s6,85
ffffffffc02053f0:	00002a97          	auipc	s5,0x2
ffffffffc02053f4:	358a8a93          	addi	s5,s5,856 # ffffffffc0207748 <syscalls+0x100>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02053f8:	000c4503          	lbu	a0,0(s8)
ffffffffc02053fc:	001c0413          	addi	s0,s8,1
ffffffffc0205400:	01350a63          	beq	a0,s3,ffffffffc0205414 <vprintfmt+0x50>
            if (ch == '\0') {
ffffffffc0205404:	cd0d                	beqz	a0,ffffffffc020543e <vprintfmt+0x7a>
            putch(ch, putdat);
ffffffffc0205406:	85ca                	mv	a1,s2
ffffffffc0205408:	9482                	jalr	s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020540a:	00044503          	lbu	a0,0(s0)
ffffffffc020540e:	0405                	addi	s0,s0,1
ffffffffc0205410:	ff351ae3          	bne	a0,s3,ffffffffc0205404 <vprintfmt+0x40>
        width = precision = -1;
ffffffffc0205414:	5cfd                	li	s9,-1
ffffffffc0205416:	8d66                	mv	s10,s9
        char padc = ' ';
ffffffffc0205418:	02000d93          	li	s11,32
        lflag = altflag = 0;
ffffffffc020541c:	4b81                	li	s7,0
ffffffffc020541e:	4781                	li	a5,0
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205420:	00044683          	lbu	a3,0(s0)
ffffffffc0205424:	00140c13          	addi	s8,s0,1
ffffffffc0205428:	fdd6859b          	addiw	a1,a3,-35
ffffffffc020542c:	0ff5f593          	zext.b	a1,a1
ffffffffc0205430:	02bb6663          	bltu	s6,a1,ffffffffc020545c <vprintfmt+0x98>
ffffffffc0205434:	058a                	slli	a1,a1,0x2
ffffffffc0205436:	95d6                	add	a1,a1,s5
ffffffffc0205438:	4198                	lw	a4,0(a1)
ffffffffc020543a:	9756                	add	a4,a4,s5
ffffffffc020543c:	8702                	jr	a4
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020543e:	70e6                	ld	ra,120(sp)
ffffffffc0205440:	7446                	ld	s0,112(sp)
ffffffffc0205442:	74a6                	ld	s1,104(sp)
ffffffffc0205444:	7906                	ld	s2,96(sp)
ffffffffc0205446:	69e6                	ld	s3,88(sp)
ffffffffc0205448:	6a46                	ld	s4,80(sp)
ffffffffc020544a:	6aa6                	ld	s5,72(sp)
ffffffffc020544c:	6b06                	ld	s6,64(sp)
ffffffffc020544e:	7be2                	ld	s7,56(sp)
ffffffffc0205450:	7c42                	ld	s8,48(sp)
ffffffffc0205452:	7ca2                	ld	s9,40(sp)
ffffffffc0205454:	7d02                	ld	s10,32(sp)
ffffffffc0205456:	6de2                	ld	s11,24(sp)
ffffffffc0205458:	6109                	addi	sp,sp,128
ffffffffc020545a:	8082                	ret
            putch('%', putdat);
ffffffffc020545c:	85ca                	mv	a1,s2
ffffffffc020545e:	02500513          	li	a0,37
ffffffffc0205462:	9482                	jalr	s1
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0205464:	fff44783          	lbu	a5,-1(s0)
ffffffffc0205468:	02500713          	li	a4,37
ffffffffc020546c:	8c22                	mv	s8,s0
ffffffffc020546e:	f8e785e3          	beq	a5,a4,ffffffffc02053f8 <vprintfmt+0x34>
ffffffffc0205472:	ffec4783          	lbu	a5,-2(s8)
ffffffffc0205476:	1c7d                	addi	s8,s8,-1
ffffffffc0205478:	fee79de3          	bne	a5,a4,ffffffffc0205472 <vprintfmt+0xae>
ffffffffc020547c:	bfb5                	j	ffffffffc02053f8 <vprintfmt+0x34>
                ch = *fmt;
ffffffffc020547e:	00144603          	lbu	a2,1(s0)
                if (ch < '0' || ch > '9') {
ffffffffc0205482:	4525                	li	a0,9
                precision = precision * 10 + ch - '0';
ffffffffc0205484:	fd068c9b          	addiw	s9,a3,-48
                if (ch < '0' || ch > '9') {
ffffffffc0205488:	fd06071b          	addiw	a4,a2,-48
ffffffffc020548c:	24e56a63          	bltu	a0,a4,ffffffffc02056e0 <vprintfmt+0x31c>
                ch = *fmt;
ffffffffc0205490:	2601                	sext.w	a2,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205492:	8462                	mv	s0,s8
                precision = precision * 10 + ch - '0';
ffffffffc0205494:	002c971b          	slliw	a4,s9,0x2
                ch = *fmt;
ffffffffc0205498:	00144683          	lbu	a3,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc020549c:	0197073b          	addw	a4,a4,s9
ffffffffc02054a0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02054a4:	9f31                	addw	a4,a4,a2
                if (ch < '0' || ch > '9') {
ffffffffc02054a6:	fd06859b          	addiw	a1,a3,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc02054aa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02054ac:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02054b0:	0006861b          	sext.w	a2,a3
                if (ch < '0' || ch > '9') {
ffffffffc02054b4:	feb570e3          	bgeu	a0,a1,ffffffffc0205494 <vprintfmt+0xd0>
            if (width < 0)
ffffffffc02054b8:	f60d54e3          	bgez	s10,ffffffffc0205420 <vprintfmt+0x5c>
                width = precision, precision = -1;
ffffffffc02054bc:	8d66                	mv	s10,s9
ffffffffc02054be:	5cfd                	li	s9,-1
ffffffffc02054c0:	b785                	j	ffffffffc0205420 <vprintfmt+0x5c>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02054c2:	8db6                	mv	s11,a3
ffffffffc02054c4:	8462                	mv	s0,s8
ffffffffc02054c6:	bfa9                	j	ffffffffc0205420 <vprintfmt+0x5c>
ffffffffc02054c8:	8462                	mv	s0,s8
            altflag = 1;
ffffffffc02054ca:	4b85                	li	s7,1
            goto reswitch;
ffffffffc02054cc:	bf91                	j	ffffffffc0205420 <vprintfmt+0x5c>
    if (lflag >= 2) {
ffffffffc02054ce:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02054d0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02054d4:	00f74463          	blt	a4,a5,ffffffffc02054dc <vprintfmt+0x118>
    else if (lflag) {
ffffffffc02054d8:	1a078763          	beqz	a5,ffffffffc0205686 <vprintfmt+0x2c2>
        return va_arg(*ap, unsigned long);
ffffffffc02054dc:	000a3603          	ld	a2,0(s4)
ffffffffc02054e0:	46c1                	li	a3,16
ffffffffc02054e2:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02054e4:	000d879b          	sext.w	a5,s11
ffffffffc02054e8:	876a                	mv	a4,s10
ffffffffc02054ea:	85ca                	mv	a1,s2
ffffffffc02054ec:	8526                	mv	a0,s1
ffffffffc02054ee:	e71ff0ef          	jal	ffffffffc020535e <printnum>
            break;
ffffffffc02054f2:	b719                	j	ffffffffc02053f8 <vprintfmt+0x34>
            putch(va_arg(ap, int), putdat);
ffffffffc02054f4:	000a2503          	lw	a0,0(s4)
ffffffffc02054f8:	85ca                	mv	a1,s2
ffffffffc02054fa:	0a21                	addi	s4,s4,8
ffffffffc02054fc:	9482                	jalr	s1
            break;
ffffffffc02054fe:	bded                	j	ffffffffc02053f8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc0205500:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205502:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0205506:	00f74463          	blt	a4,a5,ffffffffc020550e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020550a:	16078963          	beqz	a5,ffffffffc020567c <vprintfmt+0x2b8>
        return va_arg(*ap, unsigned long);
ffffffffc020550e:	000a3603          	ld	a2,0(s4)
ffffffffc0205512:	46a9                	li	a3,10
ffffffffc0205514:	8a2e                	mv	s4,a1
ffffffffc0205516:	b7f9                	j	ffffffffc02054e4 <vprintfmt+0x120>
            putch('0', putdat);
ffffffffc0205518:	85ca                	mv	a1,s2
ffffffffc020551a:	03000513          	li	a0,48
ffffffffc020551e:	9482                	jalr	s1
            putch('x', putdat);
ffffffffc0205520:	85ca                	mv	a1,s2
ffffffffc0205522:	07800513          	li	a0,120
ffffffffc0205526:	9482                	jalr	s1
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0205528:	000a3603          	ld	a2,0(s4)
            goto number;
ffffffffc020552c:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020552e:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0205530:	bf55                	j	ffffffffc02054e4 <vprintfmt+0x120>
            putch(ch, putdat);
ffffffffc0205532:	85ca                	mv	a1,s2
ffffffffc0205534:	02500513          	li	a0,37
ffffffffc0205538:	9482                	jalr	s1
            break;
ffffffffc020553a:	bd7d                	j	ffffffffc02053f8 <vprintfmt+0x34>
            precision = va_arg(ap, int);
ffffffffc020553c:	000a2c83          	lw	s9,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205540:	8462                	mv	s0,s8
            precision = va_arg(ap, int);
ffffffffc0205542:	0a21                	addi	s4,s4,8
            goto process_precision;
ffffffffc0205544:	bf95                	j	ffffffffc02054b8 <vprintfmt+0xf4>
    if (lflag >= 2) {
ffffffffc0205546:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0205548:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc020554c:	00f74463          	blt	a4,a5,ffffffffc0205554 <vprintfmt+0x190>
    else if (lflag) {
ffffffffc0205550:	12078163          	beqz	a5,ffffffffc0205672 <vprintfmt+0x2ae>
        return va_arg(*ap, unsigned long);
ffffffffc0205554:	000a3603          	ld	a2,0(s4)
ffffffffc0205558:	46a1                	li	a3,8
ffffffffc020555a:	8a2e                	mv	s4,a1
ffffffffc020555c:	b761                	j	ffffffffc02054e4 <vprintfmt+0x120>
            if (width < 0)
ffffffffc020555e:	876a                	mv	a4,s10
ffffffffc0205560:	000d5363          	bgez	s10,ffffffffc0205566 <vprintfmt+0x1a2>
ffffffffc0205564:	4701                	li	a4,0
ffffffffc0205566:	00070d1b          	sext.w	s10,a4
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020556a:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020556c:	bd55                	j	ffffffffc0205420 <vprintfmt+0x5c>
            if (width > 0 && padc != '-') {
ffffffffc020556e:	000d841b          	sext.w	s0,s11
ffffffffc0205572:	fd340793          	addi	a5,s0,-45
ffffffffc0205576:	00f037b3          	snez	a5,a5
ffffffffc020557a:	01a02733          	sgtz	a4,s10
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020557e:	000a3d83          	ld	s11,0(s4)
            if (width > 0 && padc != '-') {
ffffffffc0205582:	8f7d                	and	a4,a4,a5
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0205584:	008a0793          	addi	a5,s4,8
ffffffffc0205588:	e43e                	sd	a5,8(sp)
ffffffffc020558a:	100d8c63          	beqz	s11,ffffffffc02056a2 <vprintfmt+0x2de>
            if (width > 0 && padc != '-') {
ffffffffc020558e:	12071363          	bnez	a4,ffffffffc02056b4 <vprintfmt+0x2f0>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205592:	000dc783          	lbu	a5,0(s11)
ffffffffc0205596:	0007851b          	sext.w	a0,a5
ffffffffc020559a:	c78d                	beqz	a5,ffffffffc02055c4 <vprintfmt+0x200>
ffffffffc020559c:	0d85                	addi	s11,s11,1
ffffffffc020559e:	547d                	li	s0,-1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055a0:	05e00a13          	li	s4,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055a4:	000cc563          	bltz	s9,ffffffffc02055ae <vprintfmt+0x1ea>
ffffffffc02055a8:	3cfd                	addiw	s9,s9,-1
ffffffffc02055aa:	008c8d63          	beq	s9,s0,ffffffffc02055c4 <vprintfmt+0x200>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055ae:	020b9663          	bnez	s7,ffffffffc02055da <vprintfmt+0x216>
                    putch(ch, putdat);
ffffffffc02055b2:	85ca                	mv	a1,s2
ffffffffc02055b4:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055b6:	000dc783          	lbu	a5,0(s11)
ffffffffc02055ba:	0d85                	addi	s11,s11,1
ffffffffc02055bc:	3d7d                	addiw	s10,s10,-1
ffffffffc02055be:	0007851b          	sext.w	a0,a5
ffffffffc02055c2:	f3ed                	bnez	a5,ffffffffc02055a4 <vprintfmt+0x1e0>
            for (; width > 0; width --) {
ffffffffc02055c4:	01a05963          	blez	s10,ffffffffc02055d6 <vprintfmt+0x212>
                putch(' ', putdat);
ffffffffc02055c8:	85ca                	mv	a1,s2
ffffffffc02055ca:	02000513          	li	a0,32
            for (; width > 0; width --) {
ffffffffc02055ce:	3d7d                	addiw	s10,s10,-1
                putch(' ', putdat);
ffffffffc02055d0:	9482                	jalr	s1
            for (; width > 0; width --) {
ffffffffc02055d2:	fe0d1be3          	bnez	s10,ffffffffc02055c8 <vprintfmt+0x204>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02055d6:	6a22                	ld	s4,8(sp)
ffffffffc02055d8:	b505                	j	ffffffffc02053f8 <vprintfmt+0x34>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02055da:	3781                	addiw	a5,a5,-32
ffffffffc02055dc:	fcfa7be3          	bgeu	s4,a5,ffffffffc02055b2 <vprintfmt+0x1ee>
                    putch('?', putdat);
ffffffffc02055e0:	03f00513          	li	a0,63
ffffffffc02055e4:	85ca                	mv	a1,s2
ffffffffc02055e6:	9482                	jalr	s1
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02055e8:	000dc783          	lbu	a5,0(s11)
ffffffffc02055ec:	0d85                	addi	s11,s11,1
ffffffffc02055ee:	3d7d                	addiw	s10,s10,-1
ffffffffc02055f0:	0007851b          	sext.w	a0,a5
ffffffffc02055f4:	dbe1                	beqz	a5,ffffffffc02055c4 <vprintfmt+0x200>
ffffffffc02055f6:	fa0cd9e3          	bgez	s9,ffffffffc02055a8 <vprintfmt+0x1e4>
ffffffffc02055fa:	b7c5                	j	ffffffffc02055da <vprintfmt+0x216>
            if (err < 0) {
ffffffffc02055fc:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0205600:	4661                	li	a2,24
            err = va_arg(ap, int);
ffffffffc0205602:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0205604:	41f7d71b          	sraiw	a4,a5,0x1f
ffffffffc0205608:	8fb9                	xor	a5,a5,a4
ffffffffc020560a:	40e786bb          	subw	a3,a5,a4
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020560e:	02d64563          	blt	a2,a3,ffffffffc0205638 <vprintfmt+0x274>
ffffffffc0205612:	00002797          	auipc	a5,0x2
ffffffffc0205616:	28e78793          	addi	a5,a5,654 # ffffffffc02078a0 <error_string>
ffffffffc020561a:	00369713          	slli	a4,a3,0x3
ffffffffc020561e:	97ba                	add	a5,a5,a4
ffffffffc0205620:	639c                	ld	a5,0(a5)
ffffffffc0205622:	cb99                	beqz	a5,ffffffffc0205638 <vprintfmt+0x274>
                printfmt(putch, putdat, "%s", p);
ffffffffc0205624:	86be                	mv	a3,a5
ffffffffc0205626:	00000617          	auipc	a2,0x0
ffffffffc020562a:	20a60613          	addi	a2,a2,522 # ffffffffc0205830 <etext+0x28>
ffffffffc020562e:	85ca                	mv	a1,s2
ffffffffc0205630:	8526                	mv	a0,s1
ffffffffc0205632:	0d8000ef          	jal	ffffffffc020570a <printfmt>
ffffffffc0205636:	b3c9                	j	ffffffffc02053f8 <vprintfmt+0x34>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0205638:	00002617          	auipc	a2,0x2
ffffffffc020563c:	e5060613          	addi	a2,a2,-432 # ffffffffc0207488 <etext+0x1c80>
ffffffffc0205640:	85ca                	mv	a1,s2
ffffffffc0205642:	8526                	mv	a0,s1
ffffffffc0205644:	0c6000ef          	jal	ffffffffc020570a <printfmt>
ffffffffc0205648:	bb45                	j	ffffffffc02053f8 <vprintfmt+0x34>
    if (lflag >= 2) {
ffffffffc020564a:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020564c:	008a0b93          	addi	s7,s4,8
    if (lflag >= 2) {
ffffffffc0205650:	00f74363          	blt	a4,a5,ffffffffc0205656 <vprintfmt+0x292>
    else if (lflag) {
ffffffffc0205654:	cf81                	beqz	a5,ffffffffc020566c <vprintfmt+0x2a8>
        return va_arg(*ap, long);
ffffffffc0205656:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020565a:	02044b63          	bltz	s0,ffffffffc0205690 <vprintfmt+0x2cc>
            num = getint(&ap, lflag);
ffffffffc020565e:	8622                	mv	a2,s0
ffffffffc0205660:	8a5e                	mv	s4,s7
ffffffffc0205662:	46a9                	li	a3,10
ffffffffc0205664:	b541                	j	ffffffffc02054e4 <vprintfmt+0x120>
            lflag ++;
ffffffffc0205666:	2785                	addiw	a5,a5,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0205668:	8462                	mv	s0,s8
            goto reswitch;
ffffffffc020566a:	bb5d                	j	ffffffffc0205420 <vprintfmt+0x5c>
        return va_arg(*ap, int);
ffffffffc020566c:	000a2403          	lw	s0,0(s4)
ffffffffc0205670:	b7ed                	j	ffffffffc020565a <vprintfmt+0x296>
        return va_arg(*ap, unsigned int);
ffffffffc0205672:	000a6603          	lwu	a2,0(s4)
ffffffffc0205676:	46a1                	li	a3,8
ffffffffc0205678:	8a2e                	mv	s4,a1
ffffffffc020567a:	b5ad                	j	ffffffffc02054e4 <vprintfmt+0x120>
ffffffffc020567c:	000a6603          	lwu	a2,0(s4)
ffffffffc0205680:	46a9                	li	a3,10
ffffffffc0205682:	8a2e                	mv	s4,a1
ffffffffc0205684:	b585                	j	ffffffffc02054e4 <vprintfmt+0x120>
ffffffffc0205686:	000a6603          	lwu	a2,0(s4)
ffffffffc020568a:	46c1                	li	a3,16
ffffffffc020568c:	8a2e                	mv	s4,a1
ffffffffc020568e:	bd99                	j	ffffffffc02054e4 <vprintfmt+0x120>
                putch('-', putdat);
ffffffffc0205690:	85ca                	mv	a1,s2
ffffffffc0205692:	02d00513          	li	a0,45
ffffffffc0205696:	9482                	jalr	s1
                num = -(long long)num;
ffffffffc0205698:	40800633          	neg	a2,s0
ffffffffc020569c:	8a5e                	mv	s4,s7
ffffffffc020569e:	46a9                	li	a3,10
ffffffffc02056a0:	b591                	j	ffffffffc02054e4 <vprintfmt+0x120>
            if (width > 0 && padc != '-') {
ffffffffc02056a2:	e329                	bnez	a4,ffffffffc02056e4 <vprintfmt+0x320>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056a4:	02800793          	li	a5,40
ffffffffc02056a8:	853e                	mv	a0,a5
ffffffffc02056aa:	00002d97          	auipc	s11,0x2
ffffffffc02056ae:	dd7d8d93          	addi	s11,s11,-553 # ffffffffc0207481 <etext+0x1c79>
ffffffffc02056b2:	b5f5                	j	ffffffffc020559e <vprintfmt+0x1da>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056b4:	85e6                	mv	a1,s9
ffffffffc02056b6:	856e                	mv	a0,s11
ffffffffc02056b8:	08a000ef          	jal	ffffffffc0205742 <strnlen>
ffffffffc02056bc:	40ad0d3b          	subw	s10,s10,a0
ffffffffc02056c0:	01a05863          	blez	s10,ffffffffc02056d0 <vprintfmt+0x30c>
                    putch(padc, putdat);
ffffffffc02056c4:	85ca                	mv	a1,s2
ffffffffc02056c6:	8522                	mv	a0,s0
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056c8:	3d7d                	addiw	s10,s10,-1
                    putch(padc, putdat);
ffffffffc02056ca:	9482                	jalr	s1
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056cc:	fe0d1ce3          	bnez	s10,ffffffffc02056c4 <vprintfmt+0x300>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056d0:	000dc783          	lbu	a5,0(s11)
ffffffffc02056d4:	0007851b          	sext.w	a0,a5
ffffffffc02056d8:	ec0792e3          	bnez	a5,ffffffffc020559c <vprintfmt+0x1d8>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc02056dc:	6a22                	ld	s4,8(sp)
ffffffffc02056de:	bb29                	j	ffffffffc02053f8 <vprintfmt+0x34>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02056e0:	8462                	mv	s0,s8
ffffffffc02056e2:	bbd9                	j	ffffffffc02054b8 <vprintfmt+0xf4>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02056e4:	85e6                	mv	a1,s9
ffffffffc02056e6:	00002517          	auipc	a0,0x2
ffffffffc02056ea:	d9a50513          	addi	a0,a0,-614 # ffffffffc0207480 <etext+0x1c78>
ffffffffc02056ee:	054000ef          	jal	ffffffffc0205742 <strnlen>
ffffffffc02056f2:	40ad0d3b          	subw	s10,s10,a0
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02056f6:	02800793          	li	a5,40
                p = "(null)";
ffffffffc02056fa:	00002d97          	auipc	s11,0x2
ffffffffc02056fe:	d86d8d93          	addi	s11,s11,-634 # ffffffffc0207480 <etext+0x1c78>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0205702:	853e                	mv	a0,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0205704:	fda040e3          	bgtz	s10,ffffffffc02056c4 <vprintfmt+0x300>
ffffffffc0205708:	bd51                	j	ffffffffc020559c <vprintfmt+0x1d8>

ffffffffc020570a <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020570a:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc020570c:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205710:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205712:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0205714:	ec06                	sd	ra,24(sp)
ffffffffc0205716:	f83a                	sd	a4,48(sp)
ffffffffc0205718:	fc3e                	sd	a5,56(sp)
ffffffffc020571a:	e0c2                	sd	a6,64(sp)
ffffffffc020571c:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020571e:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0205720:	ca5ff0ef          	jal	ffffffffc02053c4 <vprintfmt>
}
ffffffffc0205724:	60e2                	ld	ra,24(sp)
ffffffffc0205726:	6161                	addi	sp,sp,80
ffffffffc0205728:	8082                	ret

ffffffffc020572a <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020572a:	00054783          	lbu	a5,0(a0)
ffffffffc020572e:	cb81                	beqz	a5,ffffffffc020573e <strlen+0x14>
    size_t cnt = 0;
ffffffffc0205730:	4781                	li	a5,0
        cnt ++;
ffffffffc0205732:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0205734:	00f50733          	add	a4,a0,a5
ffffffffc0205738:	00074703          	lbu	a4,0(a4)
ffffffffc020573c:	fb7d                	bnez	a4,ffffffffc0205732 <strlen+0x8>
    }
    return cnt;
}
ffffffffc020573e:	853e                	mv	a0,a5
ffffffffc0205740:	8082                	ret

ffffffffc0205742 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc0205742:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc0205744:	e589                	bnez	a1,ffffffffc020574e <strnlen+0xc>
ffffffffc0205746:	a811                	j	ffffffffc020575a <strnlen+0x18>
        cnt ++;
ffffffffc0205748:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020574a:	00f58863          	beq	a1,a5,ffffffffc020575a <strnlen+0x18>
ffffffffc020574e:	00f50733          	add	a4,a0,a5
ffffffffc0205752:	00074703          	lbu	a4,0(a4)
ffffffffc0205756:	fb6d                	bnez	a4,ffffffffc0205748 <strnlen+0x6>
ffffffffc0205758:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc020575a:	852e                	mv	a0,a1
ffffffffc020575c:	8082                	ret

ffffffffc020575e <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc020575e:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0205760:	0005c703          	lbu	a4,0(a1)
ffffffffc0205764:	0585                	addi	a1,a1,1
ffffffffc0205766:	0785                	addi	a5,a5,1
ffffffffc0205768:	fee78fa3          	sb	a4,-1(a5)
ffffffffc020576c:	fb75                	bnez	a4,ffffffffc0205760 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc020576e:	8082                	ret

ffffffffc0205770 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205770:	00054783          	lbu	a5,0(a0)
ffffffffc0205774:	e791                	bnez	a5,ffffffffc0205780 <strcmp+0x10>
ffffffffc0205776:	a01d                	j	ffffffffc020579c <strcmp+0x2c>
ffffffffc0205778:	00054783          	lbu	a5,0(a0)
ffffffffc020577c:	cb99                	beqz	a5,ffffffffc0205792 <strcmp+0x22>
ffffffffc020577e:	0585                	addi	a1,a1,1
ffffffffc0205780:	0005c703          	lbu	a4,0(a1)
        s1 ++, s2 ++;
ffffffffc0205784:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0205786:	fef709e3          	beq	a4,a5,ffffffffc0205778 <strcmp+0x8>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020578a:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020578e:	9d19                	subw	a0,a0,a4
ffffffffc0205790:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0205792:	0015c703          	lbu	a4,1(a1)
ffffffffc0205796:	4501                	li	a0,0
}
ffffffffc0205798:	9d19                	subw	a0,a0,a4
ffffffffc020579a:	8082                	ret
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020579c:	0005c703          	lbu	a4,0(a1)
ffffffffc02057a0:	4501                	li	a0,0
ffffffffc02057a2:	b7f5                	j	ffffffffc020578e <strcmp+0x1e>

ffffffffc02057a4 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057a4:	ce01                	beqz	a2,ffffffffc02057bc <strncmp+0x18>
ffffffffc02057a6:	00054783          	lbu	a5,0(a0)
        n --, s1 ++, s2 ++;
ffffffffc02057aa:	167d                	addi	a2,a2,-1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ac:	cb91                	beqz	a5,ffffffffc02057c0 <strncmp+0x1c>
ffffffffc02057ae:	0005c703          	lbu	a4,0(a1)
ffffffffc02057b2:	00f71763          	bne	a4,a5,ffffffffc02057c0 <strncmp+0x1c>
        n --, s1 ++, s2 ++;
ffffffffc02057b6:	0505                	addi	a0,a0,1
ffffffffc02057b8:	0585                	addi	a1,a1,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02057ba:	f675                	bnez	a2,ffffffffc02057a6 <strncmp+0x2>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02057bc:	4501                	li	a0,0
ffffffffc02057be:	8082                	ret
ffffffffc02057c0:	00054503          	lbu	a0,0(a0)
ffffffffc02057c4:	0005c783          	lbu	a5,0(a1)
ffffffffc02057c8:	9d1d                	subw	a0,a0,a5
}
ffffffffc02057ca:	8082                	ret

ffffffffc02057cc <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02057cc:	a021                	j	ffffffffc02057d4 <strchr+0x8>
        if (*s == c) {
ffffffffc02057ce:	00f58763          	beq	a1,a5,ffffffffc02057dc <strchr+0x10>
            return (char *)s;
        }
        s ++;
ffffffffc02057d2:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02057d4:	00054783          	lbu	a5,0(a0)
ffffffffc02057d8:	fbfd                	bnez	a5,ffffffffc02057ce <strchr+0x2>
    }
    return NULL;
ffffffffc02057da:	4501                	li	a0,0
}
ffffffffc02057dc:	8082                	ret

ffffffffc02057de <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02057de:	ca01                	beqz	a2,ffffffffc02057ee <memset+0x10>
ffffffffc02057e0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02057e2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02057e4:	0785                	addi	a5,a5,1
ffffffffc02057e6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02057ea:	fef61de3          	bne	a2,a5,ffffffffc02057e4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02057ee:	8082                	ret

ffffffffc02057f0 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc02057f0:	ca19                	beqz	a2,ffffffffc0205806 <memcpy+0x16>
ffffffffc02057f2:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc02057f4:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc02057f6:	0005c703          	lbu	a4,0(a1)
ffffffffc02057fa:	0585                	addi	a1,a1,1
ffffffffc02057fc:	0785                	addi	a5,a5,1
ffffffffc02057fe:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0205802:	feb61ae3          	bne	a2,a1,ffffffffc02057f6 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0205806:	8082                	ret

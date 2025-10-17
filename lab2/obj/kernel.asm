
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
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200044:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200048:	0dc28293          	addi	t0,t0,220 # ffffffffc02000dc <kern_init>
    jr t0
ffffffffc020004c:	8282                	jr	t0

ffffffffc020004e <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc020004e:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200050:	00001517          	auipc	a0,0x1
ffffffffc0200054:	6b850513          	addi	a0,a0,1720 # ffffffffc0201708 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200058:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020005a:	0f6000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005e:	00000597          	auipc	a1,0x0
ffffffffc0200062:	07e58593          	addi	a1,a1,126 # ffffffffc02000dc <kern_init>
ffffffffc0200066:	00001517          	auipc	a0,0x1
ffffffffc020006a:	6c250513          	addi	a0,a0,1730 # ffffffffc0201728 <etext+0x40>
ffffffffc020006e:	0e2000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200072:	00001597          	auipc	a1,0x1
ffffffffc0200076:	67658593          	addi	a1,a1,1654 # ffffffffc02016e8 <etext>
ffffffffc020007a:	00001517          	auipc	a0,0x1
ffffffffc020007e:	6ce50513          	addi	a0,a0,1742 # ffffffffc0201748 <etext+0x60>
ffffffffc0200082:	0ce000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200086:	00006597          	auipc	a1,0x6
ffffffffc020008a:	f9258593          	addi	a1,a1,-110 # ffffffffc0206018 <edata>
ffffffffc020008e:	00001517          	auipc	a0,0x1
ffffffffc0200092:	6da50513          	addi	a0,a0,1754 # ffffffffc0201768 <etext+0x80>
ffffffffc0200096:	0ba000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020009a:	00006597          	auipc	a1,0x6
ffffffffc020009e:	fde58593          	addi	a1,a1,-34 # ffffffffc0206078 <end>
ffffffffc02000a2:	00001517          	auipc	a0,0x1
ffffffffc02000a6:	6e650513          	addi	a0,a0,1766 # ffffffffc0201788 <etext+0xa0>
ffffffffc02000aa:	0a6000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - (char*)kern_init + 1023) / 1024);
ffffffffc02000ae:	00006597          	auipc	a1,0x6
ffffffffc02000b2:	3c958593          	addi	a1,a1,969 # ffffffffc0206477 <end+0x3ff>
ffffffffc02000b6:	00000797          	auipc	a5,0x0
ffffffffc02000ba:	02678793          	addi	a5,a5,38 # ffffffffc02000dc <kern_init>
ffffffffc02000be:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c2:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02000c6:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000c8:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000cc:	95be                	add	a1,a1,a5
ffffffffc02000ce:	85a9                	srai	a1,a1,0xa
ffffffffc02000d0:	00001517          	auipc	a0,0x1
ffffffffc02000d4:	6d850513          	addi	a0,a0,1752 # ffffffffc02017a8 <etext+0xc0>
}
ffffffffc02000d8:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02000da:	a89d                	j	ffffffffc0200150 <cprintf>

ffffffffc02000dc <kern_init>:

int kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc02000dc:	00006517          	auipc	a0,0x6
ffffffffc02000e0:	f3c50513          	addi	a0,a0,-196 # ffffffffc0206018 <edata>
ffffffffc02000e4:	00006617          	auipc	a2,0x6
ffffffffc02000e8:	f9460613          	addi	a2,a2,-108 # ffffffffc0206078 <end>
int kern_init(void) {
ffffffffc02000ec:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc02000ee:	8e09                	sub	a2,a2,a0
ffffffffc02000f0:	4581                	li	a1,0
int kern_init(void) {
ffffffffc02000f2:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc02000f4:	5e2010ef          	jal	ra,ffffffffc02016d6 <memset>
    dtb_init();
ffffffffc02000f8:	194000ef          	jal	ra,ffffffffc020028c <dtb_init>
    cons_init();  // init the console
ffffffffc02000fc:	120000ef          	jal	ra,ffffffffc020021c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200100:	00001517          	auipc	a0,0x1
ffffffffc0200104:	5e850513          	addi	a0,a0,1512 # ffffffffc02016e8 <etext>
ffffffffc0200108:	07c000ef          	jal	ra,ffffffffc0200184 <cputs>

    print_kerninfo();
ffffffffc020010c:	f43ff0ef          	jal	ra,ffffffffc020004e <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc0200110:	733000ef          	jal	ra,ffffffffc0201042 <pmm_init>

    /* do nothing */
    while (1)
        ;
ffffffffc0200114:	a001                	j	ffffffffc0200114 <kern_init+0x38>

ffffffffc0200116 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200116:	1141                	addi	sp,sp,-16
ffffffffc0200118:	e022                	sd	s0,0(sp)
ffffffffc020011a:	e406                	sd	ra,8(sp)
ffffffffc020011c:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020011e:	100000ef          	jal	ra,ffffffffc020021e <cons_putc>
    (*cnt) ++;
ffffffffc0200122:	401c                	lw	a5,0(s0)
}
ffffffffc0200124:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200126:	2785                	addiw	a5,a5,1
ffffffffc0200128:	c01c                	sw	a5,0(s0)
}
ffffffffc020012a:	6402                	ld	s0,0(sp)
ffffffffc020012c:	0141                	addi	sp,sp,16
ffffffffc020012e:	8082                	ret

ffffffffc0200130 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200130:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200132:	86ae                	mv	a3,a1
ffffffffc0200134:	862a                	mv	a2,a0
ffffffffc0200136:	006c                	addi	a1,sp,12
ffffffffc0200138:	00000517          	auipc	a0,0x0
ffffffffc020013c:	fde50513          	addi	a0,a0,-34 # ffffffffc0200116 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200140:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200142:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200144:	14c010ef          	jal	ra,ffffffffc0201290 <vprintfmt>
    return cnt;
}
ffffffffc0200148:	60e2                	ld	ra,24(sp)
ffffffffc020014a:	4532                	lw	a0,12(sp)
ffffffffc020014c:	6105                	addi	sp,sp,32
ffffffffc020014e:	8082                	ret

ffffffffc0200150 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200150:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200152:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200156:	f42e                	sd	a1,40(sp)
ffffffffc0200158:	f832                	sd	a2,48(sp)
ffffffffc020015a:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015c:	862a                	mv	a2,a0
ffffffffc020015e:	004c                	addi	a1,sp,4
ffffffffc0200160:	00000517          	auipc	a0,0x0
ffffffffc0200164:	fb650513          	addi	a0,a0,-74 # ffffffffc0200116 <cputch>
ffffffffc0200168:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc020016a:	ec06                	sd	ra,24(sp)
ffffffffc020016c:	e0ba                	sd	a4,64(sp)
ffffffffc020016e:	e4be                	sd	a5,72(sp)
ffffffffc0200170:	e8c2                	sd	a6,80(sp)
ffffffffc0200172:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200174:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200176:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200178:	118010ef          	jal	ra,ffffffffc0201290 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020017c:	60e2                	ld	ra,24(sp)
ffffffffc020017e:	4512                	lw	a0,4(sp)
ffffffffc0200180:	6125                	addi	sp,sp,96
ffffffffc0200182:	8082                	ret

ffffffffc0200184 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200184:	1101                	addi	sp,sp,-32
ffffffffc0200186:	e822                	sd	s0,16(sp)
ffffffffc0200188:	ec06                	sd	ra,24(sp)
ffffffffc020018a:	e426                	sd	s1,8(sp)
ffffffffc020018c:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020018e:	00054503          	lbu	a0,0(a0)
ffffffffc0200192:	c51d                	beqz	a0,ffffffffc02001c0 <cputs+0x3c>
ffffffffc0200194:	0405                	addi	s0,s0,1
ffffffffc0200196:	4485                	li	s1,1
ffffffffc0200198:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020019a:	084000ef          	jal	ra,ffffffffc020021e <cons_putc>
    (*cnt) ++;
ffffffffc020019e:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc02001a2:	0405                	addi	s0,s0,1
ffffffffc02001a4:	fff44503          	lbu	a0,-1(s0)
ffffffffc02001a8:	f96d                	bnez	a0,ffffffffc020019a <cputs+0x16>
ffffffffc02001aa:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001ae:	4529                	li	a0,10
ffffffffc02001b0:	06e000ef          	jal	ra,ffffffffc020021e <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001b4:	8522                	mv	a0,s0
ffffffffc02001b6:	60e2                	ld	ra,24(sp)
ffffffffc02001b8:	6442                	ld	s0,16(sp)
ffffffffc02001ba:	64a2                	ld	s1,8(sp)
ffffffffc02001bc:	6105                	addi	sp,sp,32
ffffffffc02001be:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001c0:	4405                	li	s0,1
ffffffffc02001c2:	b7f5                	j	ffffffffc02001ae <cputs+0x2a>

ffffffffc02001c4 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02001c4:	00006317          	auipc	t1,0x6
ffffffffc02001c8:	e6c30313          	addi	t1,t1,-404 # ffffffffc0206030 <is_panic>
ffffffffc02001cc:	00032303          	lw	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02001d0:	715d                	addi	sp,sp,-80
ffffffffc02001d2:	ec06                	sd	ra,24(sp)
ffffffffc02001d4:	e822                	sd	s0,16(sp)
ffffffffc02001d6:	f436                	sd	a3,40(sp)
ffffffffc02001d8:	f83a                	sd	a4,48(sp)
ffffffffc02001da:	fc3e                	sd	a5,56(sp)
ffffffffc02001dc:	e0c2                	sd	a6,64(sp)
ffffffffc02001de:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02001e0:	00030363          	beqz	t1,ffffffffc02001e6 <__panic+0x22>
    cprintf("\n");
    va_end(ap);

panic_dead:
    while (1) {
        ;
ffffffffc02001e4:	a001                	j	ffffffffc02001e4 <__panic+0x20>
    is_panic = 1;
ffffffffc02001e6:	4785                	li	a5,1
ffffffffc02001e8:	8432                	mv	s0,a2
ffffffffc02001ea:	00006717          	auipc	a4,0x6
ffffffffc02001ee:	e4f72323          	sw	a5,-442(a4) # ffffffffc0206030 <is_panic>
    va_start(ap, fmt);
ffffffffc02001f2:	862e                	mv	a2,a1
ffffffffc02001f4:	103c                	addi	a5,sp,40
ffffffffc02001f6:	85aa                	mv	a1,a0
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001f8:	00001517          	auipc	a0,0x1
ffffffffc02001fc:	5e050513          	addi	a0,a0,1504 # ffffffffc02017d8 <etext+0xf0>
    va_start(ap, fmt);
ffffffffc0200200:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc0200202:	f4fff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200206:	65a2                	ld	a1,8(sp)
ffffffffc0200208:	8522                	mv	a0,s0
ffffffffc020020a:	f27ff0ef          	jal	ra,ffffffffc0200130 <vcprintf>
    cprintf("\n");
ffffffffc020020e:	00001517          	auipc	a0,0x1
ffffffffc0200212:	5c250513          	addi	a0,a0,1474 # ffffffffc02017d0 <etext+0xe8>
ffffffffc0200216:	f3bff0ef          	jal	ra,ffffffffc0200150 <cprintf>
ffffffffc020021a:	b7e9                	j	ffffffffc02001e4 <__panic+0x20>

ffffffffc020021c <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc020021c:	8082                	ret

ffffffffc020021e <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc020021e:	0ff57513          	andi	a0,a0,255
ffffffffc0200222:	3ee0106f          	j	ffffffffc0201610 <sbi_console_putchar>

ffffffffc0200226 <fdt64_to_cpu>:
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
}

static uint64_t fdt64_to_cpu(uint64_t x) {
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200226:	0005069b          	sext.w	a3,a0
           fdt32_to_cpu(x >> 32);
ffffffffc020022a:	9501                	srai	a0,a0,0x20
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020022c:	0085579b          	srliw	a5,a0,0x8
ffffffffc0200230:	00ff08b7          	lui	a7,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200234:	0185531b          	srliw	t1,a0,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200238:	0086d71b          	srliw	a4,a3,0x8
ffffffffc020023c:	0185159b          	slliw	a1,a0,0x18
ffffffffc0200240:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200244:	0105551b          	srliw	a0,a0,0x10
ffffffffc0200248:	6641                	lui	a2,0x10
ffffffffc020024a:	0186de1b          	srliw	t3,a3,0x18
ffffffffc020024e:	167d                	addi	a2,a2,-1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200250:	0186981b          	slliw	a6,a3,0x18
ffffffffc0200254:	0117f7b3          	and	a5,a5,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200258:	0065e5b3          	or	a1,a1,t1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020025c:	0107171b          	slliw	a4,a4,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200260:	0106d69b          	srliw	a3,a3,0x10
ffffffffc0200264:	0085151b          	slliw	a0,a0,0x8
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200268:	01177733          	and	a4,a4,a7
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020026c:	01c86833          	or	a6,a6,t3
ffffffffc0200270:	8fcd                	or	a5,a5,a1
ffffffffc0200272:	8d71                	and	a0,a0,a2
ffffffffc0200274:	0086969b          	slliw	a3,a3,0x8
ffffffffc0200278:	01076733          	or	a4,a4,a6
ffffffffc020027c:	8ef1                	and	a3,a3,a2
ffffffffc020027e:	8d5d                	or	a0,a0,a5
ffffffffc0200280:	8f55                	or	a4,a4,a3
           fdt32_to_cpu(x >> 32);
ffffffffc0200282:	1502                	slli	a0,a0,0x20
    return ((uint64_t)fdt32_to_cpu(x & 0xffffffff) << 32) | 
ffffffffc0200284:	1702                	slli	a4,a4,0x20
           fdt32_to_cpu(x >> 32);
ffffffffc0200286:	9101                	srli	a0,a0,0x20
}
ffffffffc0200288:	8d59                	or	a0,a0,a4
ffffffffc020028a:	8082                	ret

ffffffffc020028c <dtb_init>:

// 保存解析出的系统物理内存信息
static uint64_t memory_base = 0;
static uint64_t memory_size = 0;

void dtb_init(void) {
ffffffffc020028c:	7159                	addi	sp,sp,-112
    cprintf("DTB Init\n");
ffffffffc020028e:	00001517          	auipc	a0,0x1
ffffffffc0200292:	56a50513          	addi	a0,a0,1386 # ffffffffc02017f8 <etext+0x110>
void dtb_init(void) {
ffffffffc0200296:	f486                	sd	ra,104(sp)
ffffffffc0200298:	f0a2                	sd	s0,96(sp)
ffffffffc020029a:	e4ce                	sd	s3,72(sp)
ffffffffc020029c:	eca6                	sd	s1,88(sp)
ffffffffc020029e:	e8ca                	sd	s2,80(sp)
ffffffffc02002a0:	e0d2                	sd	s4,64(sp)
ffffffffc02002a2:	fc56                	sd	s5,56(sp)
ffffffffc02002a4:	f85a                	sd	s6,48(sp)
ffffffffc02002a6:	f45e                	sd	s7,40(sp)
ffffffffc02002a8:	f062                	sd	s8,32(sp)
ffffffffc02002aa:	ec66                	sd	s9,24(sp)
ffffffffc02002ac:	e86a                	sd	s10,16(sp)
ffffffffc02002ae:	e46e                	sd	s11,8(sp)
    cprintf("DTB Init\n");
ffffffffc02002b0:	ea1ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02002b4:	00006797          	auipc	a5,0x6
ffffffffc02002b8:	d4c78793          	addi	a5,a5,-692 # ffffffffc0206000 <boot_hartid>
ffffffffc02002bc:	638c                	ld	a1,0(a5)
ffffffffc02002be:	00001517          	auipc	a0,0x1
ffffffffc02002c2:	54a50513          	addi	a0,a0,1354 # ffffffffc0201808 <etext+0x120>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02002c6:	00006417          	auipc	s0,0x6
ffffffffc02002ca:	d4240413          	addi	s0,s0,-702 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02002ce:	e83ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02002d2:	600c                	ld	a1,0(s0)
ffffffffc02002d4:	00001517          	auipc	a0,0x1
ffffffffc02002d8:	54450513          	addi	a0,a0,1348 # ffffffffc0201818 <etext+0x130>
ffffffffc02002dc:	e75ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02002e0:	00043983          	ld	s3,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02002e4:	00001517          	auipc	a0,0x1
ffffffffc02002e8:	54c50513          	addi	a0,a0,1356 # ffffffffc0201830 <etext+0x148>
    if (boot_dtb == 0) {
ffffffffc02002ec:	10098d63          	beqz	s3,ffffffffc0200406 <dtb_init+0x17a>
        return;
    }
    
    // 转换为虚拟地址
    uintptr_t dtb_vaddr = boot_dtb + PHYSICAL_MEMORY_OFFSET;
ffffffffc02002f0:	57f5                	li	a5,-3
ffffffffc02002f2:	07fa                	slli	a5,a5,0x1e
ffffffffc02002f4:	00f98733          	add	a4,s3,a5
    const struct fdt_header *header = (const struct fdt_header *)dtb_vaddr;
    
    // 验证DTB
    uint32_t magic = fdt32_to_cpu(header->magic);
ffffffffc02002f8:	431c                	lw	a5,0(a4)
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02002fa:	00ff0537          	lui	a0,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02002fe:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200302:	0087d69b          	srliw	a3,a5,0x8
ffffffffc0200306:	0187959b          	slliw	a1,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020030a:	8dd1                	or	a1,a1,a2
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020030c:	0106969b          	slliw	a3,a3,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200310:	0107d79b          	srliw	a5,a5,0x10
ffffffffc0200314:	6641                	lui	a2,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200316:	8ee9                	and	a3,a3,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200318:	0087979b          	slliw	a5,a5,0x8
ffffffffc020031c:	167d                	addi	a2,a2,-1
ffffffffc020031e:	8dd5                	or	a1,a1,a3
ffffffffc0200320:	8ff1                	and	a5,a5,a2
ffffffffc0200322:	8fcd                	or	a5,a5,a1
ffffffffc0200324:	0007859b          	sext.w	a1,a5
    if (magic != 0xd00dfeed) {
ffffffffc0200328:	d00e07b7          	lui	a5,0xd00e0
ffffffffc020032c:	eed78793          	addi	a5,a5,-275 # ffffffffd00dfeed <end+0xfed9e75>
ffffffffc0200330:	0ef59a63          	bne	a1,a5,ffffffffc0200424 <dtb_init+0x198>
        return;
    }
    
    // 提取内存信息
    uint64_t mem_base, mem_size;
    if (extract_memory_info(dtb_vaddr, header, &mem_base, &mem_size) == 0) {
ffffffffc0200334:	471c                	lw	a5,8(a4)
ffffffffc0200336:	4754                	lw	a3,12(a4)
    int in_memory_node = 0;
ffffffffc0200338:	4b81                	li	s7,0
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020033a:	0087d59b          	srliw	a1,a5,0x8
ffffffffc020033e:	0086d81b          	srliw	a6,a3,0x8
ffffffffc0200342:	0186941b          	slliw	s0,a3,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200346:	0186d31b          	srliw	t1,a3,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020034a:	0187999b          	slliw	s3,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020034e:	0187d89b          	srliw	a7,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200352:	0108181b          	slliw	a6,a6,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200356:	0106d69b          	srliw	a3,a3,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020035a:	0105959b          	slliw	a1,a1,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020035e:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200362:	00a87833          	and	a6,a6,a0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200366:	00646433          	or	s0,s0,t1
ffffffffc020036a:	0086969b          	slliw	a3,a3,0x8
ffffffffc020036e:	0119e9b3          	or	s3,s3,a7
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200372:	8d6d                	and	a0,a0,a1
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200374:	0087979b          	slliw	a5,a5,0x8
ffffffffc0200378:	01046433          	or	s0,s0,a6
ffffffffc020037c:	8ef1                	and	a3,a3,a2
ffffffffc020037e:	00a9e9b3          	or	s3,s3,a0
ffffffffc0200382:	8ff1                	and	a5,a5,a2
ffffffffc0200384:	8c55                	or	s0,s0,a3
ffffffffc0200386:	00f9e9b3          	or	s3,s3,a5
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020038a:	1402                	slli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc020038c:	1982                	slli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc020038e:	9001                	srli	s0,s0,0x20
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200390:	0209d993          	srli	s3,s3,0x20
    const char *strings_base = (const char *)(dtb_vaddr + strings_offset);
ffffffffc0200394:	943a                	add	s0,s0,a4
    const uint32_t *struct_ptr = (const uint32_t *)(dtb_vaddr + struct_offset);
ffffffffc0200396:	99ba                	add	s3,s3,a4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200398:	00ff0cb7          	lui	s9,0xff0
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020039c:	8b32                	mv	s6,a2
        switch (token) {
ffffffffc020039e:	4c09                	li	s8,2
ffffffffc02003a0:	490d                	li	s2,3
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02003a2:	00001497          	auipc	s1,0x1
ffffffffc02003a6:	4de48493          	addi	s1,s1,1246 # ffffffffc0201880 <etext+0x198>
        switch (token) {
ffffffffc02003aa:	4d91                	li	s11,4
ffffffffc02003ac:	4d05                	li	s10,1
        uint32_t token = fdt32_to_cpu(*struct_ptr++);
ffffffffc02003ae:	0009a703          	lw	a4,0(s3)
ffffffffc02003b2:	00498a13          	addi	s4,s3,4
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003b6:	0087579b          	srliw	a5,a4,0x8
ffffffffc02003ba:	0187161b          	slliw	a2,a4,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003be:	0187559b          	srliw	a1,a4,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003c2:	0107979b          	slliw	a5,a5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003c6:	0107571b          	srliw	a4,a4,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02003ca:	0197f7b3          	and	a5,a5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02003ce:	8e4d                	or	a2,a2,a1
ffffffffc02003d0:	0087171b          	slliw	a4,a4,0x8
ffffffffc02003d4:	8fd1                	or	a5,a5,a2
ffffffffc02003d6:	01677733          	and	a4,a4,s6
ffffffffc02003da:	8fd9                	or	a5,a5,a4
ffffffffc02003dc:	2781                	sext.w	a5,a5
        switch (token) {
ffffffffc02003de:	09878d63          	beq	a5,s8,ffffffffc0200478 <dtb_init+0x1ec>
ffffffffc02003e2:	06fc7463          	bgeu	s8,a5,ffffffffc020044a <dtb_init+0x1be>
ffffffffc02003e6:	09278c63          	beq	a5,s2,ffffffffc020047e <dtb_init+0x1f2>
ffffffffc02003ea:	01b79463          	bne	a5,s11,ffffffffc02003f2 <dtb_init+0x166>
                in_memory_node = 0;
ffffffffc02003ee:	89d2                	mv	s3,s4
ffffffffc02003f0:	bf7d                	j	ffffffffc02003ae <dtb_init+0x122>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
        // 保存到全局变量，供 PMM 查询
        memory_base = mem_base;
        memory_size = mem_size;
    } else {
        cprintf("Warning: Could not extract memory info from DTB\n");
ffffffffc02003f2:	00001517          	auipc	a0,0x1
ffffffffc02003f6:	50650513          	addi	a0,a0,1286 # ffffffffc02018f8 <etext+0x210>
ffffffffc02003fa:	d57ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003fe:	00001517          	auipc	a0,0x1
ffffffffc0200402:	53250513          	addi	a0,a0,1330 # ffffffffc0201930 <etext+0x248>
}
ffffffffc0200406:	7406                	ld	s0,96(sp)
ffffffffc0200408:	70a6                	ld	ra,104(sp)
ffffffffc020040a:	64e6                	ld	s1,88(sp)
ffffffffc020040c:	6946                	ld	s2,80(sp)
ffffffffc020040e:	69a6                	ld	s3,72(sp)
ffffffffc0200410:	6a06                	ld	s4,64(sp)
ffffffffc0200412:	7ae2                	ld	s5,56(sp)
ffffffffc0200414:	7b42                	ld	s6,48(sp)
ffffffffc0200416:	7ba2                	ld	s7,40(sp)
ffffffffc0200418:	7c02                	ld	s8,32(sp)
ffffffffc020041a:	6ce2                	ld	s9,24(sp)
ffffffffc020041c:	6d42                	ld	s10,16(sp)
ffffffffc020041e:	6da2                	ld	s11,8(sp)
ffffffffc0200420:	6165                	addi	sp,sp,112
    cprintf("DTB init completed\n");
ffffffffc0200422:	b33d                	j	ffffffffc0200150 <cprintf>
}
ffffffffc0200424:	7406                	ld	s0,96(sp)
ffffffffc0200426:	70a6                	ld	ra,104(sp)
ffffffffc0200428:	64e6                	ld	s1,88(sp)
ffffffffc020042a:	6946                	ld	s2,80(sp)
ffffffffc020042c:	69a6                	ld	s3,72(sp)
ffffffffc020042e:	6a06                	ld	s4,64(sp)
ffffffffc0200430:	7ae2                	ld	s5,56(sp)
ffffffffc0200432:	7b42                	ld	s6,48(sp)
ffffffffc0200434:	7ba2                	ld	s7,40(sp)
ffffffffc0200436:	7c02                	ld	s8,32(sp)
ffffffffc0200438:	6ce2                	ld	s9,24(sp)
ffffffffc020043a:	6d42                	ld	s10,16(sp)
ffffffffc020043c:	6da2                	ld	s11,8(sp)
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc020043e:	00001517          	auipc	a0,0x1
ffffffffc0200442:	41250513          	addi	a0,a0,1042 # ffffffffc0201850 <etext+0x168>
}
ffffffffc0200446:	6165                	addi	sp,sp,112
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200448:	b321                	j	ffffffffc0200150 <cprintf>
        switch (token) {
ffffffffc020044a:	fba794e3          	bne	a5,s10,ffffffffc02003f2 <dtb_init+0x166>
                int name_len = strlen(name);
ffffffffc020044e:	8552                	mv	a0,s4
ffffffffc0200450:	1dc010ef          	jal	ra,ffffffffc020162c <strlen>
ffffffffc0200454:	0005099b          	sext.w	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200458:	4619                	li	a2,6
ffffffffc020045a:	00001597          	auipc	a1,0x1
ffffffffc020045e:	41e58593          	addi	a1,a1,1054 # ffffffffc0201878 <etext+0x190>
ffffffffc0200462:	8552                	mv	a0,s4
ffffffffc0200464:	236010ef          	jal	ra,ffffffffc020169a <strncmp>
ffffffffc0200468:	e111                	bnez	a0,ffffffffc020046c <dtb_init+0x1e0>
                    in_memory_node = 1;
ffffffffc020046a:	4b85                	li	s7,1
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + name_len + 4) & ~3);
ffffffffc020046c:	0a11                	addi	s4,s4,4
ffffffffc020046e:	9a4e                	add	s4,s4,s3
ffffffffc0200470:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc0200474:	89d2                	mv	s3,s4
ffffffffc0200476:	bf25                	j	ffffffffc02003ae <dtb_init+0x122>
ffffffffc0200478:	4b81                	li	s7,0
ffffffffc020047a:	89d2                	mv	s3,s4
ffffffffc020047c:	bf0d                	j	ffffffffc02003ae <dtb_init+0x122>
                uint32_t prop_len = fdt32_to_cpu(*struct_ptr++);
ffffffffc020047e:	0049a783          	lw	a5,4(s3)
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc0200482:	00c98a13          	addi	s4,s3,12
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200486:	0087da9b          	srliw	s5,a5,0x8
ffffffffc020048a:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020048e:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc0200492:	010a9a9b          	slliw	s5,s5,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc0200496:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc020049a:	019afab3          	and	s5,s5,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc020049e:	8f51                	or	a4,a4,a2
ffffffffc02004a0:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004a4:	00eaeab3          	or	s5,s5,a4
ffffffffc02004a8:	0167f7b3          	and	a5,a5,s6
ffffffffc02004ac:	00faeab3          	or	s5,s5,a5
ffffffffc02004b0:	2a81                	sext.w	s5,s5
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02004b2:	000b9b63          	bnez	s7,ffffffffc02004c8 <dtb_init+0x23c>
                struct_ptr = (const uint32_t *)(((uintptr_t)struct_ptr + prop_len + 3) & ~3);
ffffffffc02004b6:	1a82                	slli	s5,s5,0x20
ffffffffc02004b8:	0a0d                	addi	s4,s4,3
ffffffffc02004ba:	020ada93          	srli	s5,s5,0x20
ffffffffc02004be:	9a56                	add	s4,s4,s5
ffffffffc02004c0:	ffca7a13          	andi	s4,s4,-4
                in_memory_node = 0;
ffffffffc02004c4:	89d2                	mv	s3,s4
ffffffffc02004c6:	b5e5                	j	ffffffffc02003ae <dtb_init+0x122>
                uint32_t prop_nameoff = fdt32_to_cpu(*struct_ptr++);
ffffffffc02004c8:	0089a783          	lw	a5,8(s3)
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02004cc:	85a6                	mv	a1,s1
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004ce:	0087d51b          	srliw	a0,a5,0x8
ffffffffc02004d2:	0187971b          	slliw	a4,a5,0x18
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004d6:	0187d61b          	srliw	a2,a5,0x18
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004da:	0105151b          	slliw	a0,a0,0x10
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004de:	0107d79b          	srliw	a5,a5,0x10
    return ((x & 0xff) << 24) | (((x >> 8) & 0xff) << 16) | 
ffffffffc02004e2:	01957533          	and	a0,a0,s9
           (((x >> 16) & 0xff) << 8) | ((x >> 24) & 0xff);
ffffffffc02004e6:	8f51                	or	a4,a4,a2
ffffffffc02004e8:	0087979b          	slliw	a5,a5,0x8
ffffffffc02004ec:	8d59                	or	a0,a0,a4
ffffffffc02004ee:	0167f7b3          	and	a5,a5,s6
ffffffffc02004f2:	8d5d                	or	a0,a0,a5
                const char *prop_name = strings_base + prop_nameoff;
ffffffffc02004f4:	1502                	slli	a0,a0,0x20
ffffffffc02004f6:	9101                	srli	a0,a0,0x20
                if (in_memory_node && strcmp(prop_name, "reg") == 0 && prop_len >= 16) {
ffffffffc02004f8:	9522                	add	a0,a0,s0
ffffffffc02004fa:	176010ef          	jal	ra,ffffffffc0201670 <strcmp>
ffffffffc02004fe:	fd45                	bnez	a0,ffffffffc02004b6 <dtb_init+0x22a>
ffffffffc0200500:	47bd                	li	a5,15
ffffffffc0200502:	fb57fae3          	bgeu	a5,s5,ffffffffc02004b6 <dtb_init+0x22a>
                    *mem_base = fdt64_to_cpu(reg_data[0]);
ffffffffc0200506:	00c9b503          	ld	a0,12(s3)
ffffffffc020050a:	d1dff0ef          	jal	ra,ffffffffc0200226 <fdt64_to_cpu>
ffffffffc020050e:	84aa                	mv	s1,a0
                    *mem_size = fdt64_to_cpu(reg_data[1]);
ffffffffc0200510:	0149b503          	ld	a0,20(s3)
ffffffffc0200514:	d13ff0ef          	jal	ra,ffffffffc0200226 <fdt64_to_cpu>
ffffffffc0200518:	842a                	mv	s0,a0
        cprintf("Physical Memory from DTB:\n");
ffffffffc020051a:	00001517          	auipc	a0,0x1
ffffffffc020051e:	36e50513          	addi	a0,a0,878 # ffffffffc0201888 <etext+0x1a0>
ffffffffc0200522:	c2fff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200526:	85a6                	mv	a1,s1
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	38050513          	addi	a0,a0,896 # ffffffffc02018a8 <etext+0x1c0>
ffffffffc0200530:	c21ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200534:	01445613          	srli	a2,s0,0x14
ffffffffc0200538:	85a2                	mv	a1,s0
ffffffffc020053a:	00001517          	auipc	a0,0x1
ffffffffc020053e:	38650513          	addi	a0,a0,902 # ffffffffc02018c0 <etext+0x1d8>
ffffffffc0200542:	c0fff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200546:	008485b3          	add	a1,s1,s0
ffffffffc020054a:	15fd                	addi	a1,a1,-1
ffffffffc020054c:	00001517          	auipc	a0,0x1
ffffffffc0200550:	39450513          	addi	a0,a0,916 # ffffffffc02018e0 <etext+0x1f8>
ffffffffc0200554:	bfdff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200558:	00001517          	auipc	a0,0x1
ffffffffc020055c:	3d850513          	addi	a0,a0,984 # ffffffffc0201930 <etext+0x248>
        memory_base = mem_base;
ffffffffc0200560:	00006797          	auipc	a5,0x6
ffffffffc0200564:	ac97bc23          	sd	s1,-1320(a5) # ffffffffc0206038 <memory_base>
        memory_size = mem_size;
ffffffffc0200568:	00006797          	auipc	a5,0x6
ffffffffc020056c:	ac87bc23          	sd	s0,-1320(a5) # ffffffffc0206040 <memory_size>
    cprintf("DTB init completed\n");
ffffffffc0200570:	bd59                	j	ffffffffc0200406 <dtb_init+0x17a>

ffffffffc0200572 <get_memory_base>:

uint64_t get_memory_base(void) {
    return memory_base;
ffffffffc0200572:	00006797          	auipc	a5,0x6
ffffffffc0200576:	ac678793          	addi	a5,a5,-1338 # ffffffffc0206038 <memory_base>
}
ffffffffc020057a:	6388                	ld	a0,0(a5)
ffffffffc020057c:	8082                	ret

ffffffffc020057e <get_memory_size>:

uint64_t get_memory_size(void) {
    return memory_size;
ffffffffc020057e:	00006797          	auipc	a5,0x6
ffffffffc0200582:	ac278793          	addi	a5,a5,-1342 # ffffffffc0206040 <memory_size>
ffffffffc0200586:	6388                	ld	a0,0(a5)
ffffffffc0200588:	8082                	ret

ffffffffc020058a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020058a:	00006797          	auipc	a5,0x6
ffffffffc020058e:	a8e78793          	addi	a5,a5,-1394 # ffffffffc0206018 <edata>
ffffffffc0200592:	e79c                	sd	a5,8(a5)
ffffffffc0200594:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200596:	0007a823          	sw	zero,16(a5)
}
ffffffffc020059a:	8082                	ret

ffffffffc020059c <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020059c:	00006517          	auipc	a0,0x6
ffffffffc02005a0:	a8c56503          	lwu	a0,-1396(a0) # ffffffffc0206028 <edata+0x10>
ffffffffc02005a4:	8082                	ret

ffffffffc02005a6 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc02005a6:	cd49                	beqz	a0,ffffffffc0200640 <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc02005a8:	00006617          	auipc	a2,0x6
ffffffffc02005ac:	a7060613          	addi	a2,a2,-1424 # ffffffffc0206018 <edata>
ffffffffc02005b0:	01062803          	lw	a6,16(a2)
ffffffffc02005b4:	86aa                	mv	a3,a0
ffffffffc02005b6:	02081793          	slli	a5,a6,0x20
ffffffffc02005ba:	9381                	srli	a5,a5,0x20
ffffffffc02005bc:	08a7e063          	bltu	a5,a0,ffffffffc020063c <best_fit_alloc_pages+0x96>
    size_t min_size = nr_free + 1;
ffffffffc02005c0:	0018059b          	addiw	a1,a6,1
ffffffffc02005c4:	1582                	slli	a1,a1,0x20
ffffffffc02005c6:	9181                	srli	a1,a1,0x20
    struct Page *temp = NULL;
ffffffffc02005c8:	4501                	li	a0,0
    list_entry_t *le = &free_list;
ffffffffc02005ca:	87b2                	mv	a5,a2
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005cc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ce:	00c78e63          	beq	a5,a2,ffffffffc02005ea <best_fit_alloc_pages+0x44>
         if (p->property >= n) {
ffffffffc02005d2:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02005d6:	fed76be3          	bltu	a4,a3,ffffffffc02005cc <best_fit_alloc_pages+0x26>
            if(p->property < min_size){
ffffffffc02005da:	feb779e3          	bgeu	a4,a1,ffffffffc02005cc <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc02005de:	fe878513          	addi	a0,a5,-24
ffffffffc02005e2:	679c                	ld	a5,8(a5)
ffffffffc02005e4:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005e6:	fec796e3          	bne	a5,a2,ffffffffc02005d2 <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc02005ea:	c931                	beqz	a0,ffffffffc020063e <best_fit_alloc_pages+0x98>
        if (page->property > n) {
ffffffffc02005ec:	490c                	lw	a1,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005ee:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005f0:	7110                	ld	a2,32(a0)
ffffffffc02005f2:	02059793          	slli	a5,a1,0x20
ffffffffc02005f6:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02005f8:	e710                	sd	a2,8(a4)
    next->prev = prev;
ffffffffc02005fa:	e218                	sd	a4,0(a2)
ffffffffc02005fc:	0006889b          	sext.w	a7,a3
ffffffffc0200600:	02f6f463          	bgeu	a3,a5,ffffffffc0200628 <best_fit_alloc_pages+0x82>
            struct Page *p = page + n;
ffffffffc0200604:	00269793          	slli	a5,a3,0x2
ffffffffc0200608:	97b6                	add	a5,a5,a3
ffffffffc020060a:	078e                	slli	a5,a5,0x3
ffffffffc020060c:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc020060e:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc0200610:	411585bb          	subw	a1,a1,a7
ffffffffc0200614:	cb8c                	sw	a1,16(a5)
            SetPageProperty(p);
ffffffffc0200616:	0026e693          	ori	a3,a3,2
ffffffffc020061a:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc020061c:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc0200620:	e214                	sd	a3,0(a2)
ffffffffc0200622:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc0200624:	f390                	sd	a2,32(a5)
    elm->prev = prev;
ffffffffc0200626:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200628:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc020062a:	4118083b          	subw	a6,a6,a7
ffffffffc020062e:	00006717          	auipc	a4,0x6
ffffffffc0200632:	9f072d23          	sw	a6,-1542(a4) # ffffffffc0206028 <edata+0x10>
        ClearPageProperty(page);
ffffffffc0200636:	9bf5                	andi	a5,a5,-3
ffffffffc0200638:	e51c                	sd	a5,8(a0)
ffffffffc020063a:	8082                	ret
        return NULL;
ffffffffc020063c:	4501                	li	a0,0
}
ffffffffc020063e:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200640:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc0200642:	00001697          	auipc	a3,0x1
ffffffffc0200646:	30668693          	addi	a3,a3,774 # ffffffffc0201948 <etext+0x260>
ffffffffc020064a:	00001617          	auipc	a2,0x1
ffffffffc020064e:	30660613          	addi	a2,a2,774 # ffffffffc0201950 <etext+0x268>
ffffffffc0200652:	06f00593          	li	a1,111
ffffffffc0200656:	00001517          	auipc	a0,0x1
ffffffffc020065a:	31250513          	addi	a0,a0,786 # ffffffffc0201968 <etext+0x280>
best_fit_alloc_pages(size_t n) {
ffffffffc020065e:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200660:	b65ff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0200664 <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc0200664:	715d                	addi	sp,sp,-80
ffffffffc0200666:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200668:	00006917          	auipc	s2,0x6
ffffffffc020066c:	9b090913          	addi	s2,s2,-1616 # ffffffffc0206018 <edata>
ffffffffc0200670:	00893783          	ld	a5,8(s2)
ffffffffc0200674:	e486                	sd	ra,72(sp)
ffffffffc0200676:	e0a2                	sd	s0,64(sp)
ffffffffc0200678:	fc26                	sd	s1,56(sp)
ffffffffc020067a:	f44e                	sd	s3,40(sp)
ffffffffc020067c:	f052                	sd	s4,32(sp)
ffffffffc020067e:	ec56                	sd	s5,24(sp)
ffffffffc0200680:	e85a                	sd	s6,16(sp)
ffffffffc0200682:	e45e                	sd	s7,8(sp)
ffffffffc0200684:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200686:	2d278063          	beq	a5,s2,ffffffffc0200946 <best_fit_check+0x2e2>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc020068a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020068e:	8b09                	andi	a4,a4,2
ffffffffc0200690:	2a070f63          	beqz	a4,ffffffffc020094e <best_fit_check+0x2ea>
    int count = 0, total = 0;
ffffffffc0200694:	4401                	li	s0,0
ffffffffc0200696:	4481                	li	s1,0
ffffffffc0200698:	a031                	j	ffffffffc02006a4 <best_fit_check+0x40>
        assert(PageProperty(p));
ffffffffc020069a:	ff07b703          	ld	a4,-16(a5)
ffffffffc020069e:	8b09                	andi	a4,a4,2
ffffffffc02006a0:	2a070763          	beqz	a4,ffffffffc020094e <best_fit_check+0x2ea>
        count ++, total += p->property;
ffffffffc02006a4:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006a8:	679c                	ld	a5,8(a5)
ffffffffc02006aa:	2485                	addiw	s1,s1,1
ffffffffc02006ac:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006ae:	ff2796e3          	bne	a5,s2,ffffffffc020069a <best_fit_check+0x36>
ffffffffc02006b2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc02006b4:	17f000ef          	jal	ra,ffffffffc0201032 <nr_free_pages>
ffffffffc02006b8:	37351b63          	bne	a0,s3,ffffffffc0200a2e <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006bc:	4505                	li	a0,1
ffffffffc02006be:	155000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02006c2:	8a2a                	mv	s4,a0
ffffffffc02006c4:	3a050563          	beqz	a0,ffffffffc0200a6e <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006c8:	4505                	li	a0,1
ffffffffc02006ca:	149000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02006ce:	89aa                	mv	s3,a0
ffffffffc02006d0:	36050f63          	beqz	a0,ffffffffc0200a4e <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006d4:	4505                	li	a0,1
ffffffffc02006d6:	13d000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02006da:	8aaa                	mv	s5,a0
ffffffffc02006dc:	30050963          	beqz	a0,ffffffffc02009ee <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006e0:	293a0763          	beq	s4,s3,ffffffffc020096e <best_fit_check+0x30a>
ffffffffc02006e4:	28aa0563          	beq	s4,a0,ffffffffc020096e <best_fit_check+0x30a>
ffffffffc02006e8:	28a98363          	beq	s3,a0,ffffffffc020096e <best_fit_check+0x30a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006ec:	000a2783          	lw	a5,0(s4)
ffffffffc02006f0:	28079f63          	bnez	a5,ffffffffc020098e <best_fit_check+0x32a>
ffffffffc02006f4:	0009a783          	lw	a5,0(s3)
ffffffffc02006f8:	28079b63          	bnez	a5,ffffffffc020098e <best_fit_check+0x32a>
ffffffffc02006fc:	411c                	lw	a5,0(a0)
ffffffffc02006fe:	28079863          	bnez	a5,ffffffffc020098e <best_fit_check+0x32a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200702:	00006797          	auipc	a5,0x6
ffffffffc0200706:	96e78793          	addi	a5,a5,-1682 # ffffffffc0206070 <pages>
ffffffffc020070a:	639c                	ld	a5,0(a5)
ffffffffc020070c:	00001717          	auipc	a4,0x1
ffffffffc0200710:	27470713          	addi	a4,a4,628 # ffffffffc0201980 <etext+0x298>
ffffffffc0200714:	630c                	ld	a1,0(a4)
ffffffffc0200716:	40fa0733          	sub	a4,s4,a5
ffffffffc020071a:	870d                	srai	a4,a4,0x3
ffffffffc020071c:	02b70733          	mul	a4,a4,a1
ffffffffc0200720:	00002697          	auipc	a3,0x2
ffffffffc0200724:	94068693          	addi	a3,a3,-1728 # ffffffffc0202060 <nbase>
ffffffffc0200728:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc020072a:	00006697          	auipc	a3,0x6
ffffffffc020072e:	91e68693          	addi	a3,a3,-1762 # ffffffffc0206048 <npage>
ffffffffc0200732:	6294                	ld	a3,0(a3)
ffffffffc0200734:	06b2                	slli	a3,a3,0xc
ffffffffc0200736:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200738:	0732                	slli	a4,a4,0xc
ffffffffc020073a:	26d77a63          	bgeu	a4,a3,ffffffffc02009ae <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020073e:	40f98733          	sub	a4,s3,a5
ffffffffc0200742:	870d                	srai	a4,a4,0x3
ffffffffc0200744:	02b70733          	mul	a4,a4,a1
ffffffffc0200748:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020074a:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc020074c:	42d77163          	bgeu	a4,a3,ffffffffc0200b6e <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200750:	40f507b3          	sub	a5,a0,a5
ffffffffc0200754:	878d                	srai	a5,a5,0x3
ffffffffc0200756:	02b787b3          	mul	a5,a5,a1
ffffffffc020075a:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc020075c:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc020075e:	3ed7f863          	bgeu	a5,a3,ffffffffc0200b4e <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc0200762:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200764:	00093c03          	ld	s8,0(s2)
ffffffffc0200768:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc020076c:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200770:	00006797          	auipc	a5,0x6
ffffffffc0200774:	8b27b823          	sd	s2,-1872(a5) # ffffffffc0206020 <edata+0x8>
ffffffffc0200778:	00006797          	auipc	a5,0x6
ffffffffc020077c:	8b27b023          	sd	s2,-1888(a5) # ffffffffc0206018 <edata>
    nr_free = 0;
ffffffffc0200780:	00006797          	auipc	a5,0x6
ffffffffc0200784:	8a07a423          	sw	zero,-1880(a5) # ffffffffc0206028 <edata+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200788:	08b000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc020078c:	3a051163          	bnez	a0,ffffffffc0200b2e <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc0200790:	4585                	li	a1,1
ffffffffc0200792:	8552                	mv	a0,s4
ffffffffc0200794:	08f000ef          	jal	ra,ffffffffc0201022 <free_pages>
    free_page(p1);
ffffffffc0200798:	4585                	li	a1,1
ffffffffc020079a:	854e                	mv	a0,s3
ffffffffc020079c:	087000ef          	jal	ra,ffffffffc0201022 <free_pages>
    free_page(p2);
ffffffffc02007a0:	4585                	li	a1,1
ffffffffc02007a2:	8556                	mv	a0,s5
ffffffffc02007a4:	07f000ef          	jal	ra,ffffffffc0201022 <free_pages>
    assert(nr_free == 3);
ffffffffc02007a8:	01092703          	lw	a4,16(s2)
ffffffffc02007ac:	478d                	li	a5,3
ffffffffc02007ae:	36f71063          	bne	a4,a5,ffffffffc0200b0e <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007b2:	4505                	li	a0,1
ffffffffc02007b4:	05f000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02007b8:	89aa                	mv	s3,a0
ffffffffc02007ba:	32050a63          	beqz	a0,ffffffffc0200aee <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007be:	4505                	li	a0,1
ffffffffc02007c0:	053000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02007c4:	8aaa                	mv	s5,a0
ffffffffc02007c6:	30050463          	beqz	a0,ffffffffc0200ace <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007ca:	4505                	li	a0,1
ffffffffc02007cc:	047000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02007d0:	8a2a                	mv	s4,a0
ffffffffc02007d2:	2c050e63          	beqz	a0,ffffffffc0200aae <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc02007d6:	4505                	li	a0,1
ffffffffc02007d8:	03b000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02007dc:	2a051963          	bnez	a0,ffffffffc0200a8e <best_fit_check+0x42a>
    free_page(p0);
ffffffffc02007e0:	4585                	li	a1,1
ffffffffc02007e2:	854e                	mv	a0,s3
ffffffffc02007e4:	03f000ef          	jal	ra,ffffffffc0201022 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007e8:	00893783          	ld	a5,8(s2)
ffffffffc02007ec:	1f278163          	beq	a5,s2,ffffffffc02009ce <best_fit_check+0x36a>
    assert((p = alloc_page()) == p0);
ffffffffc02007f0:	4505                	li	a0,1
ffffffffc02007f2:	021000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02007f6:	54a99c63          	bne	s3,a0,ffffffffc0200d4e <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc02007fa:	4505                	li	a0,1
ffffffffc02007fc:	017000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc0200800:	52051763          	bnez	a0,ffffffffc0200d2e <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc0200804:	01092783          	lw	a5,16(s2)
ffffffffc0200808:	50079363          	bnez	a5,ffffffffc0200d0e <best_fit_check+0x6aa>
    free_page(p);
ffffffffc020080c:	854e                	mv	a0,s3
ffffffffc020080e:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200810:	00006797          	auipc	a5,0x6
ffffffffc0200814:	8187b423          	sd	s8,-2040(a5) # ffffffffc0206018 <edata>
ffffffffc0200818:	00006797          	auipc	a5,0x6
ffffffffc020081c:	8177b423          	sd	s7,-2040(a5) # ffffffffc0206020 <edata+0x8>
    nr_free = nr_free_store;
ffffffffc0200820:	00006797          	auipc	a5,0x6
ffffffffc0200824:	8167a423          	sw	s6,-2040(a5) # ffffffffc0206028 <edata+0x10>
    free_page(p);
ffffffffc0200828:	7fa000ef          	jal	ra,ffffffffc0201022 <free_pages>
    free_page(p1);
ffffffffc020082c:	4585                	li	a1,1
ffffffffc020082e:	8556                	mv	a0,s5
ffffffffc0200830:	7f2000ef          	jal	ra,ffffffffc0201022 <free_pages>
    free_page(p2);
ffffffffc0200834:	4585                	li	a1,1
ffffffffc0200836:	8552                	mv	a0,s4
ffffffffc0200838:	7ea000ef          	jal	ra,ffffffffc0201022 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc020083c:	4515                	li	a0,5
ffffffffc020083e:	7d4000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc0200842:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200844:	4a050563          	beqz	a0,ffffffffc0200cee <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200848:	651c                	ld	a5,8(a0)
ffffffffc020084a:	8b89                	andi	a5,a5,2
ffffffffc020084c:	48079163          	bnez	a5,ffffffffc0200cce <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200850:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200852:	00093b83          	ld	s7,0(s2)
ffffffffc0200856:	00893b03          	ld	s6,8(s2)
ffffffffc020085a:	00005797          	auipc	a5,0x5
ffffffffc020085e:	7b27bf23          	sd	s2,1982(a5) # ffffffffc0206018 <edata>
ffffffffc0200862:	00005797          	auipc	a5,0x5
ffffffffc0200866:	7b27bf23          	sd	s2,1982(a5) # ffffffffc0206020 <edata+0x8>
    assert(alloc_page() == NULL);
ffffffffc020086a:	7a8000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc020086e:	44051063          	bnez	a0,ffffffffc0200cae <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200872:	4589                	li	a1,2
ffffffffc0200874:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200878:	01092c03          	lw	s8,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc020087c:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc0200880:	00005797          	auipc	a5,0x5
ffffffffc0200884:	7a07a423          	sw	zero,1960(a5) # ffffffffc0206028 <edata+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200888:	79a000ef          	jal	ra,ffffffffc0201022 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc020088c:	8556                	mv	a0,s5
ffffffffc020088e:	4585                	li	a1,1
ffffffffc0200890:	792000ef          	jal	ra,ffffffffc0201022 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200894:	4511                	li	a0,4
ffffffffc0200896:	77c000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc020089a:	3e051a63          	bnez	a0,ffffffffc0200c8e <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc020089e:	0309b783          	ld	a5,48(s3)
ffffffffc02008a2:	8b89                	andi	a5,a5,2
ffffffffc02008a4:	3c078563          	beqz	a5,ffffffffc0200c6e <best_fit_check+0x60a>
ffffffffc02008a8:	0389a703          	lw	a4,56(s3)
ffffffffc02008ac:	4789                	li	a5,2
ffffffffc02008ae:	3cf71063          	bne	a4,a5,ffffffffc0200c6e <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008b2:	4505                	li	a0,1
ffffffffc02008b4:	75e000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02008b8:	8a2a                	mv	s4,a0
ffffffffc02008ba:	38050a63          	beqz	a0,ffffffffc0200c4e <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008be:	4509                	li	a0,2
ffffffffc02008c0:	752000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02008c4:	36050563          	beqz	a0,ffffffffc0200c2e <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02008c8:	354a9363          	bne	s5,s4,ffffffffc0200c0e <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008cc:	854e                	mv	a0,s3
ffffffffc02008ce:	4595                	li	a1,5
ffffffffc02008d0:	752000ef          	jal	ra,ffffffffc0201022 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008d4:	4515                	li	a0,5
ffffffffc02008d6:	73c000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02008da:	89aa                	mv	s3,a0
ffffffffc02008dc:	30050963          	beqz	a0,ffffffffc0200bee <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc02008e0:	4505                	li	a0,1
ffffffffc02008e2:	730000ef          	jal	ra,ffffffffc0201012 <alloc_pages>
ffffffffc02008e6:	2e051463          	bnez	a0,ffffffffc0200bce <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008ea:	01092783          	lw	a5,16(s2)
ffffffffc02008ee:	2c079063          	bnez	a5,ffffffffc0200bae <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008f2:	4595                	li	a1,5
ffffffffc02008f4:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008f6:	00005797          	auipc	a5,0x5
ffffffffc02008fa:	7387a923          	sw	s8,1842(a5) # ffffffffc0206028 <edata+0x10>
    free_list = free_list_store;
ffffffffc02008fe:	00005797          	auipc	a5,0x5
ffffffffc0200902:	7177bd23          	sd	s7,1818(a5) # ffffffffc0206018 <edata>
ffffffffc0200906:	00005797          	auipc	a5,0x5
ffffffffc020090a:	7167bd23          	sd	s6,1818(a5) # ffffffffc0206020 <edata+0x8>
    free_pages(p0, 5);
ffffffffc020090e:	714000ef          	jal	ra,ffffffffc0201022 <free_pages>
    return listelm->next;
ffffffffc0200912:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200916:	01278963          	beq	a5,s2,ffffffffc0200928 <best_fit_check+0x2c4>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020091a:	ff87a703          	lw	a4,-8(a5)
ffffffffc020091e:	679c                	ld	a5,8(a5)
ffffffffc0200920:	34fd                	addiw	s1,s1,-1
ffffffffc0200922:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200924:	ff279be3          	bne	a5,s2,ffffffffc020091a <best_fit_check+0x2b6>
    }
    assert(count == 0);
ffffffffc0200928:	26049363          	bnez	s1,ffffffffc0200b8e <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc020092c:	e06d                	bnez	s0,ffffffffc0200a0e <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc020092e:	60a6                	ld	ra,72(sp)
ffffffffc0200930:	6406                	ld	s0,64(sp)
ffffffffc0200932:	74e2                	ld	s1,56(sp)
ffffffffc0200934:	7942                	ld	s2,48(sp)
ffffffffc0200936:	79a2                	ld	s3,40(sp)
ffffffffc0200938:	7a02                	ld	s4,32(sp)
ffffffffc020093a:	6ae2                	ld	s5,24(sp)
ffffffffc020093c:	6b42                	ld	s6,16(sp)
ffffffffc020093e:	6ba2                	ld	s7,8(sp)
ffffffffc0200940:	6c02                	ld	s8,0(sp)
ffffffffc0200942:	6161                	addi	sp,sp,80
ffffffffc0200944:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200946:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200948:	4401                	li	s0,0
ffffffffc020094a:	4481                	li	s1,0
ffffffffc020094c:	b3a5                	j	ffffffffc02006b4 <best_fit_check+0x50>
        assert(PageProperty(p));
ffffffffc020094e:	00001697          	auipc	a3,0x1
ffffffffc0200952:	03a68693          	addi	a3,a3,58 # ffffffffc0201988 <etext+0x2a0>
ffffffffc0200956:	00001617          	auipc	a2,0x1
ffffffffc020095a:	ffa60613          	addi	a2,a2,-6 # ffffffffc0201950 <etext+0x268>
ffffffffc020095e:	11f00593          	li	a1,287
ffffffffc0200962:	00001517          	auipc	a0,0x1
ffffffffc0200966:	00650513          	addi	a0,a0,6 # ffffffffc0201968 <etext+0x280>
ffffffffc020096a:	85bff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020096e:	00001697          	auipc	a3,0x1
ffffffffc0200972:	0aa68693          	addi	a3,a3,170 # ffffffffc0201a18 <etext+0x330>
ffffffffc0200976:	00001617          	auipc	a2,0x1
ffffffffc020097a:	fda60613          	addi	a2,a2,-38 # ffffffffc0201950 <etext+0x268>
ffffffffc020097e:	0eb00593          	li	a1,235
ffffffffc0200982:	00001517          	auipc	a0,0x1
ffffffffc0200986:	fe650513          	addi	a0,a0,-26 # ffffffffc0201968 <etext+0x280>
ffffffffc020098a:	83bff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc020098e:	00001697          	auipc	a3,0x1
ffffffffc0200992:	0b268693          	addi	a3,a3,178 # ffffffffc0201a40 <etext+0x358>
ffffffffc0200996:	00001617          	auipc	a2,0x1
ffffffffc020099a:	fba60613          	addi	a2,a2,-70 # ffffffffc0201950 <etext+0x268>
ffffffffc020099e:	0ec00593          	li	a1,236
ffffffffc02009a2:	00001517          	auipc	a0,0x1
ffffffffc02009a6:	fc650513          	addi	a0,a0,-58 # ffffffffc0201968 <etext+0x280>
ffffffffc02009aa:	81bff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009ae:	00001697          	auipc	a3,0x1
ffffffffc02009b2:	0d268693          	addi	a3,a3,210 # ffffffffc0201a80 <etext+0x398>
ffffffffc02009b6:	00001617          	auipc	a2,0x1
ffffffffc02009ba:	f9a60613          	addi	a2,a2,-102 # ffffffffc0201950 <etext+0x268>
ffffffffc02009be:	0ee00593          	li	a1,238
ffffffffc02009c2:	00001517          	auipc	a0,0x1
ffffffffc02009c6:	fa650513          	addi	a0,a0,-90 # ffffffffc0201968 <etext+0x280>
ffffffffc02009ca:	ffaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009ce:	00001697          	auipc	a3,0x1
ffffffffc02009d2:	13a68693          	addi	a3,a3,314 # ffffffffc0201b08 <etext+0x420>
ffffffffc02009d6:	00001617          	auipc	a2,0x1
ffffffffc02009da:	f7a60613          	addi	a2,a2,-134 # ffffffffc0201950 <etext+0x268>
ffffffffc02009de:	10700593          	li	a1,263
ffffffffc02009e2:	00001517          	auipc	a0,0x1
ffffffffc02009e6:	f8650513          	addi	a0,a0,-122 # ffffffffc0201968 <etext+0x280>
ffffffffc02009ea:	fdaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ee:	00001697          	auipc	a3,0x1
ffffffffc02009f2:	00a68693          	addi	a3,a3,10 # ffffffffc02019f8 <etext+0x310>
ffffffffc02009f6:	00001617          	auipc	a2,0x1
ffffffffc02009fa:	f5a60613          	addi	a2,a2,-166 # ffffffffc0201950 <etext+0x268>
ffffffffc02009fe:	0e900593          	li	a1,233
ffffffffc0200a02:	00001517          	auipc	a0,0x1
ffffffffc0200a06:	f6650513          	addi	a0,a0,-154 # ffffffffc0201968 <etext+0x280>
ffffffffc0200a0a:	fbaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(total == 0);
ffffffffc0200a0e:	00001697          	auipc	a3,0x1
ffffffffc0200a12:	22a68693          	addi	a3,a3,554 # ffffffffc0201c38 <etext+0x550>
ffffffffc0200a16:	00001617          	auipc	a2,0x1
ffffffffc0200a1a:	f3a60613          	addi	a2,a2,-198 # ffffffffc0201950 <etext+0x268>
ffffffffc0200a1e:	16100593          	li	a1,353
ffffffffc0200a22:	00001517          	auipc	a0,0x1
ffffffffc0200a26:	f4650513          	addi	a0,a0,-186 # ffffffffc0201968 <etext+0x280>
ffffffffc0200a2a:	f9aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a2e:	00001697          	auipc	a3,0x1
ffffffffc0200a32:	f6a68693          	addi	a3,a3,-150 # ffffffffc0201998 <etext+0x2b0>
ffffffffc0200a36:	00001617          	auipc	a2,0x1
ffffffffc0200a3a:	f1a60613          	addi	a2,a2,-230 # ffffffffc0201950 <etext+0x268>
ffffffffc0200a3e:	12200593          	li	a1,290
ffffffffc0200a42:	00001517          	auipc	a0,0x1
ffffffffc0200a46:	f2650513          	addi	a0,a0,-218 # ffffffffc0201968 <etext+0x280>
ffffffffc0200a4a:	f7aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a4e:	00001697          	auipc	a3,0x1
ffffffffc0200a52:	f8a68693          	addi	a3,a3,-118 # ffffffffc02019d8 <etext+0x2f0>
ffffffffc0200a56:	00001617          	auipc	a2,0x1
ffffffffc0200a5a:	efa60613          	addi	a2,a2,-262 # ffffffffc0201950 <etext+0x268>
ffffffffc0200a5e:	0e800593          	li	a1,232
ffffffffc0200a62:	00001517          	auipc	a0,0x1
ffffffffc0200a66:	f0650513          	addi	a0,a0,-250 # ffffffffc0201968 <etext+0x280>
ffffffffc0200a6a:	f5aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a6e:	00001697          	auipc	a3,0x1
ffffffffc0200a72:	f4a68693          	addi	a3,a3,-182 # ffffffffc02019b8 <etext+0x2d0>
ffffffffc0200a76:	00001617          	auipc	a2,0x1
ffffffffc0200a7a:	eda60613          	addi	a2,a2,-294 # ffffffffc0201950 <etext+0x268>
ffffffffc0200a7e:	0e700593          	li	a1,231
ffffffffc0200a82:	00001517          	auipc	a0,0x1
ffffffffc0200a86:	ee650513          	addi	a0,a0,-282 # ffffffffc0201968 <etext+0x280>
ffffffffc0200a8a:	f3aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a8e:	00001697          	auipc	a3,0x1
ffffffffc0200a92:	05268693          	addi	a3,a3,82 # ffffffffc0201ae0 <etext+0x3f8>
ffffffffc0200a96:	00001617          	auipc	a2,0x1
ffffffffc0200a9a:	eba60613          	addi	a2,a2,-326 # ffffffffc0201950 <etext+0x268>
ffffffffc0200a9e:	10400593          	li	a1,260
ffffffffc0200aa2:	00001517          	auipc	a0,0x1
ffffffffc0200aa6:	ec650513          	addi	a0,a0,-314 # ffffffffc0201968 <etext+0x280>
ffffffffc0200aaa:	f1aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200aae:	00001697          	auipc	a3,0x1
ffffffffc0200ab2:	f4a68693          	addi	a3,a3,-182 # ffffffffc02019f8 <etext+0x310>
ffffffffc0200ab6:	00001617          	auipc	a2,0x1
ffffffffc0200aba:	e9a60613          	addi	a2,a2,-358 # ffffffffc0201950 <etext+0x268>
ffffffffc0200abe:	10200593          	li	a1,258
ffffffffc0200ac2:	00001517          	auipc	a0,0x1
ffffffffc0200ac6:	ea650513          	addi	a0,a0,-346 # ffffffffc0201968 <etext+0x280>
ffffffffc0200aca:	efaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ace:	00001697          	auipc	a3,0x1
ffffffffc0200ad2:	f0a68693          	addi	a3,a3,-246 # ffffffffc02019d8 <etext+0x2f0>
ffffffffc0200ad6:	00001617          	auipc	a2,0x1
ffffffffc0200ada:	e7a60613          	addi	a2,a2,-390 # ffffffffc0201950 <etext+0x268>
ffffffffc0200ade:	10100593          	li	a1,257
ffffffffc0200ae2:	00001517          	auipc	a0,0x1
ffffffffc0200ae6:	e8650513          	addi	a0,a0,-378 # ffffffffc0201968 <etext+0x280>
ffffffffc0200aea:	edaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200aee:	00001697          	auipc	a3,0x1
ffffffffc0200af2:	eca68693          	addi	a3,a3,-310 # ffffffffc02019b8 <etext+0x2d0>
ffffffffc0200af6:	00001617          	auipc	a2,0x1
ffffffffc0200afa:	e5a60613          	addi	a2,a2,-422 # ffffffffc0201950 <etext+0x268>
ffffffffc0200afe:	10000593          	li	a1,256
ffffffffc0200b02:	00001517          	auipc	a0,0x1
ffffffffc0200b06:	e6650513          	addi	a0,a0,-410 # ffffffffc0201968 <etext+0x280>
ffffffffc0200b0a:	ebaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 3);
ffffffffc0200b0e:	00001697          	auipc	a3,0x1
ffffffffc0200b12:	fea68693          	addi	a3,a3,-22 # ffffffffc0201af8 <etext+0x410>
ffffffffc0200b16:	00001617          	auipc	a2,0x1
ffffffffc0200b1a:	e3a60613          	addi	a2,a2,-454 # ffffffffc0201950 <etext+0x268>
ffffffffc0200b1e:	0fe00593          	li	a1,254
ffffffffc0200b22:	00001517          	auipc	a0,0x1
ffffffffc0200b26:	e4650513          	addi	a0,a0,-442 # ffffffffc0201968 <etext+0x280>
ffffffffc0200b2a:	e9aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b2e:	00001697          	auipc	a3,0x1
ffffffffc0200b32:	fb268693          	addi	a3,a3,-78 # ffffffffc0201ae0 <etext+0x3f8>
ffffffffc0200b36:	00001617          	auipc	a2,0x1
ffffffffc0200b3a:	e1a60613          	addi	a2,a2,-486 # ffffffffc0201950 <etext+0x268>
ffffffffc0200b3e:	0f900593          	li	a1,249
ffffffffc0200b42:	00001517          	auipc	a0,0x1
ffffffffc0200b46:	e2650513          	addi	a0,a0,-474 # ffffffffc0201968 <etext+0x280>
ffffffffc0200b4a:	e7aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b4e:	00001697          	auipc	a3,0x1
ffffffffc0200b52:	f7268693          	addi	a3,a3,-142 # ffffffffc0201ac0 <etext+0x3d8>
ffffffffc0200b56:	00001617          	auipc	a2,0x1
ffffffffc0200b5a:	dfa60613          	addi	a2,a2,-518 # ffffffffc0201950 <etext+0x268>
ffffffffc0200b5e:	0f000593          	li	a1,240
ffffffffc0200b62:	00001517          	auipc	a0,0x1
ffffffffc0200b66:	e0650513          	addi	a0,a0,-506 # ffffffffc0201968 <etext+0x280>
ffffffffc0200b6a:	e5aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b6e:	00001697          	auipc	a3,0x1
ffffffffc0200b72:	f3268693          	addi	a3,a3,-206 # ffffffffc0201aa0 <etext+0x3b8>
ffffffffc0200b76:	00001617          	auipc	a2,0x1
ffffffffc0200b7a:	dda60613          	addi	a2,a2,-550 # ffffffffc0201950 <etext+0x268>
ffffffffc0200b7e:	0ef00593          	li	a1,239
ffffffffc0200b82:	00001517          	auipc	a0,0x1
ffffffffc0200b86:	de650513          	addi	a0,a0,-538 # ffffffffc0201968 <etext+0x280>
ffffffffc0200b8a:	e3aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(count == 0);
ffffffffc0200b8e:	00001697          	auipc	a3,0x1
ffffffffc0200b92:	09a68693          	addi	a3,a3,154 # ffffffffc0201c28 <etext+0x540>
ffffffffc0200b96:	00001617          	auipc	a2,0x1
ffffffffc0200b9a:	dba60613          	addi	a2,a2,-582 # ffffffffc0201950 <etext+0x268>
ffffffffc0200b9e:	16000593          	li	a1,352
ffffffffc0200ba2:	00001517          	auipc	a0,0x1
ffffffffc0200ba6:	dc650513          	addi	a0,a0,-570 # ffffffffc0201968 <etext+0x280>
ffffffffc0200baa:	e1aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 0);
ffffffffc0200bae:	00001697          	auipc	a3,0x1
ffffffffc0200bb2:	f9268693          	addi	a3,a3,-110 # ffffffffc0201b40 <etext+0x458>
ffffffffc0200bb6:	00001617          	auipc	a2,0x1
ffffffffc0200bba:	d9a60613          	addi	a2,a2,-614 # ffffffffc0201950 <etext+0x268>
ffffffffc0200bbe:	15500593          	li	a1,341
ffffffffc0200bc2:	00001517          	auipc	a0,0x1
ffffffffc0200bc6:	da650513          	addi	a0,a0,-602 # ffffffffc0201968 <etext+0x280>
ffffffffc0200bca:	dfaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bce:	00001697          	auipc	a3,0x1
ffffffffc0200bd2:	f1268693          	addi	a3,a3,-238 # ffffffffc0201ae0 <etext+0x3f8>
ffffffffc0200bd6:	00001617          	auipc	a2,0x1
ffffffffc0200bda:	d7a60613          	addi	a2,a2,-646 # ffffffffc0201950 <etext+0x268>
ffffffffc0200bde:	14f00593          	li	a1,335
ffffffffc0200be2:	00001517          	auipc	a0,0x1
ffffffffc0200be6:	d8650513          	addi	a0,a0,-634 # ffffffffc0201968 <etext+0x280>
ffffffffc0200bea:	ddaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bee:	00001697          	auipc	a3,0x1
ffffffffc0200bf2:	01a68693          	addi	a3,a3,26 # ffffffffc0201c08 <etext+0x520>
ffffffffc0200bf6:	00001617          	auipc	a2,0x1
ffffffffc0200bfa:	d5a60613          	addi	a2,a2,-678 # ffffffffc0201950 <etext+0x268>
ffffffffc0200bfe:	14e00593          	li	a1,334
ffffffffc0200c02:	00001517          	auipc	a0,0x1
ffffffffc0200c06:	d6650513          	addi	a0,a0,-666 # ffffffffc0201968 <etext+0x280>
ffffffffc0200c0a:	dbaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c0e:	00001697          	auipc	a3,0x1
ffffffffc0200c12:	fea68693          	addi	a3,a3,-22 # ffffffffc0201bf8 <etext+0x510>
ffffffffc0200c16:	00001617          	auipc	a2,0x1
ffffffffc0200c1a:	d3a60613          	addi	a2,a2,-710 # ffffffffc0201950 <etext+0x268>
ffffffffc0200c1e:	14600593          	li	a1,326
ffffffffc0200c22:	00001517          	auipc	a0,0x1
ffffffffc0200c26:	d4650513          	addi	a0,a0,-698 # ffffffffc0201968 <etext+0x280>
ffffffffc0200c2a:	d9aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c2e:	00001697          	auipc	a3,0x1
ffffffffc0200c32:	fb268693          	addi	a3,a3,-78 # ffffffffc0201be0 <etext+0x4f8>
ffffffffc0200c36:	00001617          	auipc	a2,0x1
ffffffffc0200c3a:	d1a60613          	addi	a2,a2,-742 # ffffffffc0201950 <etext+0x268>
ffffffffc0200c3e:	14500593          	li	a1,325
ffffffffc0200c42:	00001517          	auipc	a0,0x1
ffffffffc0200c46:	d2650513          	addi	a0,a0,-730 # ffffffffc0201968 <etext+0x280>
ffffffffc0200c4a:	d7aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c4e:	00001697          	auipc	a3,0x1
ffffffffc0200c52:	f7268693          	addi	a3,a3,-142 # ffffffffc0201bc0 <etext+0x4d8>
ffffffffc0200c56:	00001617          	auipc	a2,0x1
ffffffffc0200c5a:	cfa60613          	addi	a2,a2,-774 # ffffffffc0201950 <etext+0x268>
ffffffffc0200c5e:	14400593          	li	a1,324
ffffffffc0200c62:	00001517          	auipc	a0,0x1
ffffffffc0200c66:	d0650513          	addi	a0,a0,-762 # ffffffffc0201968 <etext+0x280>
ffffffffc0200c6a:	d5aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c6e:	00001697          	auipc	a3,0x1
ffffffffc0200c72:	f2268693          	addi	a3,a3,-222 # ffffffffc0201b90 <etext+0x4a8>
ffffffffc0200c76:	00001617          	auipc	a2,0x1
ffffffffc0200c7a:	cda60613          	addi	a2,a2,-806 # ffffffffc0201950 <etext+0x268>
ffffffffc0200c7e:	14200593          	li	a1,322
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	ce650513          	addi	a0,a0,-794 # ffffffffc0201968 <etext+0x280>
ffffffffc0200c8a:	d3aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c8e:	00001697          	auipc	a3,0x1
ffffffffc0200c92:	eea68693          	addi	a3,a3,-278 # ffffffffc0201b78 <etext+0x490>
ffffffffc0200c96:	00001617          	auipc	a2,0x1
ffffffffc0200c9a:	cba60613          	addi	a2,a2,-838 # ffffffffc0201950 <etext+0x268>
ffffffffc0200c9e:	14100593          	li	a1,321
ffffffffc0200ca2:	00001517          	auipc	a0,0x1
ffffffffc0200ca6:	cc650513          	addi	a0,a0,-826 # ffffffffc0201968 <etext+0x280>
ffffffffc0200caa:	d1aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cae:	00001697          	auipc	a3,0x1
ffffffffc0200cb2:	e3268693          	addi	a3,a3,-462 # ffffffffc0201ae0 <etext+0x3f8>
ffffffffc0200cb6:	00001617          	auipc	a2,0x1
ffffffffc0200cba:	c9a60613          	addi	a2,a2,-870 # ffffffffc0201950 <etext+0x268>
ffffffffc0200cbe:	13500593          	li	a1,309
ffffffffc0200cc2:	00001517          	auipc	a0,0x1
ffffffffc0200cc6:	ca650513          	addi	a0,a0,-858 # ffffffffc0201968 <etext+0x280>
ffffffffc0200cca:	cfaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cce:	00001697          	auipc	a3,0x1
ffffffffc0200cd2:	e9268693          	addi	a3,a3,-366 # ffffffffc0201b60 <etext+0x478>
ffffffffc0200cd6:	00001617          	auipc	a2,0x1
ffffffffc0200cda:	c7a60613          	addi	a2,a2,-902 # ffffffffc0201950 <etext+0x268>
ffffffffc0200cde:	12c00593          	li	a1,300
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	c8650513          	addi	a0,a0,-890 # ffffffffc0201968 <etext+0x280>
ffffffffc0200cea:	cdaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 != NULL);
ffffffffc0200cee:	00001697          	auipc	a3,0x1
ffffffffc0200cf2:	e6268693          	addi	a3,a3,-414 # ffffffffc0201b50 <etext+0x468>
ffffffffc0200cf6:	00001617          	auipc	a2,0x1
ffffffffc0200cfa:	c5a60613          	addi	a2,a2,-934 # ffffffffc0201950 <etext+0x268>
ffffffffc0200cfe:	12b00593          	li	a1,299
ffffffffc0200d02:	00001517          	auipc	a0,0x1
ffffffffc0200d06:	c6650513          	addi	a0,a0,-922 # ffffffffc0201968 <etext+0x280>
ffffffffc0200d0a:	cbaff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 0);
ffffffffc0200d0e:	00001697          	auipc	a3,0x1
ffffffffc0200d12:	e3268693          	addi	a3,a3,-462 # ffffffffc0201b40 <etext+0x458>
ffffffffc0200d16:	00001617          	auipc	a2,0x1
ffffffffc0200d1a:	c3a60613          	addi	a2,a2,-966 # ffffffffc0201950 <etext+0x268>
ffffffffc0200d1e:	10d00593          	li	a1,269
ffffffffc0200d22:	00001517          	auipc	a0,0x1
ffffffffc0200d26:	c4650513          	addi	a0,a0,-954 # ffffffffc0201968 <etext+0x280>
ffffffffc0200d2a:	c9aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d2e:	00001697          	auipc	a3,0x1
ffffffffc0200d32:	db268693          	addi	a3,a3,-590 # ffffffffc0201ae0 <etext+0x3f8>
ffffffffc0200d36:	00001617          	auipc	a2,0x1
ffffffffc0200d3a:	c1a60613          	addi	a2,a2,-998 # ffffffffc0201950 <etext+0x268>
ffffffffc0200d3e:	10b00593          	li	a1,267
ffffffffc0200d42:	00001517          	auipc	a0,0x1
ffffffffc0200d46:	c2650513          	addi	a0,a0,-986 # ffffffffc0201968 <etext+0x280>
ffffffffc0200d4a:	c7aff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d4e:	00001697          	auipc	a3,0x1
ffffffffc0200d52:	dd268693          	addi	a3,a3,-558 # ffffffffc0201b20 <etext+0x438>
ffffffffc0200d56:	00001617          	auipc	a2,0x1
ffffffffc0200d5a:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0201950 <etext+0x268>
ffffffffc0200d5e:	10a00593          	li	a1,266
ffffffffc0200d62:	00001517          	auipc	a0,0x1
ffffffffc0200d66:	c0650513          	addi	a0,a0,-1018 # ffffffffc0201968 <etext+0x280>
ffffffffc0200d6a:	c5aff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0200d6e <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d6e:	1141                	addi	sp,sp,-16
ffffffffc0200d70:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d72:	16058b63          	beqz	a1,ffffffffc0200ee8 <best_fit_free_pages+0x17a>
    for (; p != base + n; p ++) {
ffffffffc0200d76:	00259693          	slli	a3,a1,0x2
ffffffffc0200d7a:	96ae                	add	a3,a3,a1
ffffffffc0200d7c:	068e                	slli	a3,a3,0x3
ffffffffc0200d7e:	96aa                	add	a3,a3,a0
ffffffffc0200d80:	6510                	ld	a2,8(a0)
ffffffffc0200d82:	02d50363          	beq	a0,a3,ffffffffc0200da8 <best_fit_free_pages+0x3a>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200d86:	8a0d                	andi	a2,a2,3
ffffffffc0200d88:	87aa                	mv	a5,a0
ffffffffc0200d8a:	c611                	beqz	a2,ffffffffc0200d96 <best_fit_free_pages+0x28>
ffffffffc0200d8c:	aa35                	j	ffffffffc0200ec8 <best_fit_free_pages+0x15a>
ffffffffc0200d8e:	6798                	ld	a4,8(a5)
ffffffffc0200d90:	8b0d                	andi	a4,a4,3
ffffffffc0200d92:	12071b63          	bnez	a4,ffffffffc0200ec8 <best_fit_free_pages+0x15a>
        p->flags = 0;
ffffffffc0200d96:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200d9a:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200d9e:	02878793          	addi	a5,a5,40
ffffffffc0200da2:	fed796e3          	bne	a5,a3,ffffffffc0200d8e <best_fit_free_pages+0x20>
ffffffffc0200da6:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200da8:	00005697          	auipc	a3,0x5
ffffffffc0200dac:	27068693          	addi	a3,a3,624 # ffffffffc0206018 <edata>
ffffffffc0200db0:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200db2:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200db4:	00266813          	ori	a6,a2,2
    return list->next == list;
ffffffffc0200db8:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200dba:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dbc:	01053423          	sd	a6,8(a0)
    nr_free += n;
ffffffffc0200dc0:	9f2d                	addw	a4,a4,a1
ffffffffc0200dc2:	00005817          	auipc	a6,0x5
ffffffffc0200dc6:	26e82323          	sw	a4,614(a6) # ffffffffc0206028 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc0200dca:	0ad78763          	beq	a5,a3,ffffffffc0200e78 <best_fit_free_pages+0x10a>
            struct Page *page = le2page(le, page_link);
ffffffffc0200dce:	fe878713          	addi	a4,a5,-24
ffffffffc0200dd2:	0006b883          	ld	a7,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dd6:	4301                	li	t1,0
ffffffffc0200dd8:	01850813          	addi	a6,a0,24
            if (base < page) {
ffffffffc0200ddc:	00e56a63          	bltu	a0,a4,ffffffffc0200df0 <best_fit_free_pages+0x82>
    return listelm->next;
ffffffffc0200de0:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200de2:	02d70963          	beq	a4,a3,ffffffffc0200e14 <best_fit_free_pages+0xa6>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200de6:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0200de8:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200dec:	fee57ae3          	bgeu	a0,a4,ffffffffc0200de0 <best_fit_free_pages+0x72>
ffffffffc0200df0:	00030663          	beqz	t1,ffffffffc0200dfc <best_fit_free_pages+0x8e>
ffffffffc0200df4:	00005317          	auipc	t1,0x5
ffffffffc0200df8:	23133223          	sd	a7,548(t1) # ffffffffc0206018 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200dfc:	0007b883          	ld	a7,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200e00:	0107b023          	sd	a6,0(a5)
ffffffffc0200e04:	0108b423          	sd	a6,8(a7) # ff0008 <BASE_ADDRESS-0xffffffffbf20fff8>
    elm->next = next;
ffffffffc0200e08:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e0a:	01153c23          	sd	a7,24(a0)
    if (le != &free_list) {
ffffffffc0200e0e:	02d89463          	bne	a7,a3,ffffffffc0200e36 <best_fit_free_pages+0xc8>
ffffffffc0200e12:	a0a9                	j	ffffffffc0200e5c <best_fit_free_pages+0xee>
    prev->next = next->prev = elm;
ffffffffc0200e14:	0107b423          	sd	a6,8(a5)
    elm->next = next;
ffffffffc0200e18:	f114                	sd	a3,32(a0)
ffffffffc0200e1a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e1c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e1e:	88c2                	mv	a7,a6
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e20:	00d70563          	beq	a4,a3,ffffffffc0200e2a <best_fit_free_pages+0xbc>
ffffffffc0200e24:	4305                	li	t1,1
ffffffffc0200e26:	87ba                	mv	a5,a4
ffffffffc0200e28:	b7c1                	j	ffffffffc0200de8 <best_fit_free_pages+0x7a>
    return listelm->prev;
ffffffffc0200e2a:	88be                	mv	a7,a5
ffffffffc0200e2c:	0106b023          	sd	a6,0(a3)
    if (le != &free_list) {
ffffffffc0200e30:	87b6                	mv	a5,a3
ffffffffc0200e32:	02d88163          	beq	a7,a3,ffffffffc0200e54 <best_fit_free_pages+0xe6>
        if (p + p->property == base) {
ffffffffc0200e36:	ff88ae03          	lw	t3,-8(a7)
        p = le2page(le, page_link);
ffffffffc0200e3a:	fe888313          	addi	t1,a7,-24
        if (p + p->property == base) {
ffffffffc0200e3e:	020e1813          	slli	a6,t3,0x20
ffffffffc0200e42:	02085813          	srli	a6,a6,0x20
ffffffffc0200e46:	00281713          	slli	a4,a6,0x2
ffffffffc0200e4a:	9742                	add	a4,a4,a6
ffffffffc0200e4c:	070e                	slli	a4,a4,0x3
ffffffffc0200e4e:	971a                	add	a4,a4,t1
ffffffffc0200e50:	02e50d63          	beq	a0,a4,ffffffffc0200e8a <best_fit_free_pages+0x11c>
    if (le != &free_list) {
ffffffffc0200e54:	fe878713          	addi	a4,a5,-24
ffffffffc0200e58:	00d78d63          	beq	a5,a3,ffffffffc0200e72 <best_fit_free_pages+0x104>
        if (base + base->property == p) {
ffffffffc0200e5c:	490c                	lw	a1,16(a0)
ffffffffc0200e5e:	02059613          	slli	a2,a1,0x20
ffffffffc0200e62:	9201                	srli	a2,a2,0x20
ffffffffc0200e64:	00261693          	slli	a3,a2,0x2
ffffffffc0200e68:	96b2                	add	a3,a3,a2
ffffffffc0200e6a:	068e                	slli	a3,a3,0x3
ffffffffc0200e6c:	96aa                	add	a3,a3,a0
ffffffffc0200e6e:	02d70a63          	beq	a4,a3,ffffffffc0200ea2 <best_fit_free_pages+0x134>
}
ffffffffc0200e72:	60a2                	ld	ra,8(sp)
ffffffffc0200e74:	0141                	addi	sp,sp,16
ffffffffc0200e76:	8082                	ret
ffffffffc0200e78:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e7a:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e7e:	e398                	sd	a4,0(a5)
ffffffffc0200e80:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200e82:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e84:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e86:	0141                	addi	sp,sp,16
ffffffffc0200e88:	8082                	ret
            p->property += base->property;
ffffffffc0200e8a:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e8e:	feb8ac23          	sw	a1,-8(a7)
            ClearPageProperty(base);
ffffffffc0200e92:	9a75                	andi	a2,a2,-3
ffffffffc0200e94:	e510                	sd	a2,8(a0)
    prev->next = next;
ffffffffc0200e96:	00f8b423          	sd	a5,8(a7)
    next->prev = prev;
ffffffffc0200e9a:	0117b023          	sd	a7,0(a5)
            base = p;  // 更新base指针，以便继续检查后面的块
ffffffffc0200e9e:	851a                	mv	a0,t1
ffffffffc0200ea0:	bf55                	j	ffffffffc0200e54 <best_fit_free_pages+0xe6>
            base->property += p->property;
ffffffffc0200ea2:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200ea6:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200eaa:	0007b803          	ld	a6,0(a5)
ffffffffc0200eae:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200eb0:	9db5                	addw	a1,a1,a3
ffffffffc0200eb2:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200eb4:	9b75                	andi	a4,a4,-3
ffffffffc0200eb6:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200eba:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200ebc:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200ec0:	01063023          	sd	a6,0(a2)
ffffffffc0200ec4:	0141                	addi	sp,sp,16
ffffffffc0200ec6:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ec8:	00001697          	auipc	a3,0x1
ffffffffc0200ecc:	d8068693          	addi	a3,a3,-640 # ffffffffc0201c48 <etext+0x560>
ffffffffc0200ed0:	00001617          	auipc	a2,0x1
ffffffffc0200ed4:	a8060613          	addi	a2,a2,-1408 # ffffffffc0201950 <etext+0x268>
ffffffffc0200ed8:	0a600593          	li	a1,166
ffffffffc0200edc:	00001517          	auipc	a0,0x1
ffffffffc0200ee0:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0201968 <etext+0x280>
ffffffffc0200ee4:	ae0ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(n > 0);
ffffffffc0200ee8:	00001697          	auipc	a3,0x1
ffffffffc0200eec:	a6068693          	addi	a3,a3,-1440 # ffffffffc0201948 <etext+0x260>
ffffffffc0200ef0:	00001617          	auipc	a2,0x1
ffffffffc0200ef4:	a6060613          	addi	a2,a2,-1440 # ffffffffc0201950 <etext+0x268>
ffffffffc0200ef8:	0a300593          	li	a1,163
ffffffffc0200efc:	00001517          	auipc	a0,0x1
ffffffffc0200f00:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0201968 <etext+0x280>
ffffffffc0200f04:	ac0ff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0200f08 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f08:	1141                	addi	sp,sp,-16
ffffffffc0200f0a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f0c:	c1fd                	beqz	a1,ffffffffc0200ff2 <best_fit_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc0200f0e:	00259693          	slli	a3,a1,0x2
ffffffffc0200f12:	96ae                	add	a3,a3,a1
ffffffffc0200f14:	068e                	slli	a3,a3,0x3
ffffffffc0200f16:	96aa                	add	a3,a3,a0
ffffffffc0200f18:	651c                	ld	a5,8(a0)
ffffffffc0200f1a:	02d50563          	beq	a0,a3,ffffffffc0200f44 <best_fit_init_memmap+0x3c>
        assert(PageReserved(p));
ffffffffc0200f1e:	0017f713          	andi	a4,a5,1
ffffffffc0200f22:	87aa                	mv	a5,a0
ffffffffc0200f24:	e709                	bnez	a4,ffffffffc0200f2e <best_fit_init_memmap+0x26>
ffffffffc0200f26:	a075                	j	ffffffffc0200fd2 <best_fit_init_memmap+0xca>
ffffffffc0200f28:	6798                	ld	a4,8(a5)
ffffffffc0200f2a:	8b05                	andi	a4,a4,1
ffffffffc0200f2c:	c35d                	beqz	a4,ffffffffc0200fd2 <best_fit_init_memmap+0xca>
        p->flags = 0;
ffffffffc0200f2e:	0007b423          	sd	zero,8(a5)
ffffffffc0200f32:	0007a023          	sw	zero,0(a5)
        p->property = 0;
ffffffffc0200f36:	0007a823          	sw	zero,16(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f3a:	02878793          	addi	a5,a5,40
ffffffffc0200f3e:	fed795e3          	bne	a5,a3,ffffffffc0200f28 <best_fit_init_memmap+0x20>
ffffffffc0200f42:	651c                	ld	a5,8(a0)
    nr_free += n;
ffffffffc0200f44:	00005697          	auipc	a3,0x5
ffffffffc0200f48:	0d468693          	addi	a3,a3,212 # ffffffffc0206018 <edata>
ffffffffc0200f4c:	4a90                	lw	a2,16(a3)
    SetPageProperty(base);
ffffffffc0200f4e:	0027e713          	ori	a4,a5,2
    base->property = n;
ffffffffc0200f52:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200f54:	669c                	ld	a5,8(a3)
ffffffffc0200f56:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f58:	e518                	sd	a4,8(a0)
    nr_free += n;
ffffffffc0200f5a:	9db1                	addw	a1,a1,a2
ffffffffc0200f5c:	00005717          	auipc	a4,0x5
ffffffffc0200f60:	0cb72623          	sw	a1,204(a4) # ffffffffc0206028 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc0200f64:	04d78a63          	beq	a5,a3,ffffffffc0200fb8 <best_fit_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f68:	fe878713          	addi	a4,a5,-24
ffffffffc0200f6c:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f6e:	4801                	li	a6,0
ffffffffc0200f70:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200f74:	00e56a63          	bltu	a0,a4,ffffffffc0200f88 <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc0200f78:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0200f7a:	02d70563          	beq	a4,a3,ffffffffc0200fa4 <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f7e:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f80:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f84:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f78 <best_fit_init_memmap+0x70>
ffffffffc0200f88:	00080663          	beqz	a6,ffffffffc0200f94 <best_fit_init_memmap+0x8c>
ffffffffc0200f8c:	00005717          	auipc	a4,0x5
ffffffffc0200f90:	08b73623          	sd	a1,140(a4) # ffffffffc0206018 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f94:	6398                	ld	a4,0(a5)
}
ffffffffc0200f96:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200f98:	e390                	sd	a2,0(a5)
ffffffffc0200f9a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200f9c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200f9e:	ed18                	sd	a4,24(a0)
ffffffffc0200fa0:	0141                	addi	sp,sp,16
ffffffffc0200fa2:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200fa4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200fa6:	f114                	sd	a3,32(a0)
ffffffffc0200fa8:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200faa:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200fac:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200fae:	00d70e63          	beq	a4,a3,ffffffffc0200fca <best_fit_init_memmap+0xc2>
ffffffffc0200fb2:	4805                	li	a6,1
ffffffffc0200fb4:	87ba                	mv	a5,a4
ffffffffc0200fb6:	b7e9                	j	ffffffffc0200f80 <best_fit_init_memmap+0x78>
}
ffffffffc0200fb8:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200fba:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200fbe:	e398                	sd	a4,0(a5)
ffffffffc0200fc0:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200fc2:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fc4:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200fc6:	0141                	addi	sp,sp,16
ffffffffc0200fc8:	8082                	ret
ffffffffc0200fca:	60a2                	ld	ra,8(sp)
ffffffffc0200fcc:	e290                	sd	a2,0(a3)
ffffffffc0200fce:	0141                	addi	sp,sp,16
ffffffffc0200fd0:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200fd2:	00001697          	auipc	a3,0x1
ffffffffc0200fd6:	c9e68693          	addi	a3,a3,-866 # ffffffffc0201c70 <etext+0x588>
ffffffffc0200fda:	00001617          	auipc	a2,0x1
ffffffffc0200fde:	97660613          	addi	a2,a2,-1674 # ffffffffc0201950 <etext+0x268>
ffffffffc0200fe2:	04a00593          	li	a1,74
ffffffffc0200fe6:	00001517          	auipc	a0,0x1
ffffffffc0200fea:	98250513          	addi	a0,a0,-1662 # ffffffffc0201968 <etext+0x280>
ffffffffc0200fee:	9d6ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(n > 0);
ffffffffc0200ff2:	00001697          	auipc	a3,0x1
ffffffffc0200ff6:	95668693          	addi	a3,a3,-1706 # ffffffffc0201948 <etext+0x260>
ffffffffc0200ffa:	00001617          	auipc	a2,0x1
ffffffffc0200ffe:	95660613          	addi	a2,a2,-1706 # ffffffffc0201950 <etext+0x268>
ffffffffc0201002:	04700593          	li	a1,71
ffffffffc0201006:	00001517          	auipc	a0,0x1
ffffffffc020100a:	96250513          	addi	a0,a0,-1694 # ffffffffc0201968 <etext+0x280>
ffffffffc020100e:	9b6ff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0201012 <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc0201012:	00005797          	auipc	a5,0x5
ffffffffc0201016:	04e78793          	addi	a5,a5,78 # ffffffffc0206060 <pmm_manager>
ffffffffc020101a:	639c                	ld	a5,0(a5)
ffffffffc020101c:	0187b303          	ld	t1,24(a5)
ffffffffc0201020:	8302                	jr	t1

ffffffffc0201022 <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc0201022:	00005797          	auipc	a5,0x5
ffffffffc0201026:	03e78793          	addi	a5,a5,62 # ffffffffc0206060 <pmm_manager>
ffffffffc020102a:	639c                	ld	a5,0(a5)
ffffffffc020102c:	0207b303          	ld	t1,32(a5)
ffffffffc0201030:	8302                	jr	t1

ffffffffc0201032 <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc0201032:	00005797          	auipc	a5,0x5
ffffffffc0201036:	02e78793          	addi	a5,a5,46 # ffffffffc0206060 <pmm_manager>
ffffffffc020103a:	639c                	ld	a5,0(a5)
ffffffffc020103c:	0287b303          	ld	t1,40(a5)
ffffffffc0201040:	8302                	jr	t1

ffffffffc0201042 <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201042:	00001797          	auipc	a5,0x1
ffffffffc0201046:	c3e78793          	addi	a5,a5,-962 # ffffffffc0201c80 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020104a:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc020104c:	7179                	addi	sp,sp,-48
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020104e:	00001517          	auipc	a0,0x1
ffffffffc0201052:	c8250513          	addi	a0,a0,-894 # ffffffffc0201cd0 <best_fit_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc0201056:	f406                	sd	ra,40(sp)
ffffffffc0201058:	f022                	sd	s0,32(sp)
ffffffffc020105a:	e84a                	sd	s2,16(sp)
ffffffffc020105c:	ec26                	sd	s1,24(sp)
ffffffffc020105e:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201060:	00005717          	auipc	a4,0x5
ffffffffc0201064:	00f73023          	sd	a5,0(a4) # ffffffffc0206060 <pmm_manager>
ffffffffc0201068:	00005417          	auipc	s0,0x5
ffffffffc020106c:	ff840413          	addi	s0,s0,-8 # ffffffffc0206060 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201070:	8e0ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    pmm_manager->init();
ffffffffc0201074:	601c                	ld	a5,0(s0)
ffffffffc0201076:	679c                	ld	a5,8(a5)
ffffffffc0201078:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc020107a:	57f5                	li	a5,-3
ffffffffc020107c:	07fa                	slli	a5,a5,0x1e
ffffffffc020107e:	00005717          	auipc	a4,0x5
ffffffffc0201082:	fef73523          	sd	a5,-22(a4) # ffffffffc0206068 <va_pa_offset>
    uint64_t mem_begin = get_memory_base();
ffffffffc0201086:	cecff0ef          	jal	ra,ffffffffc0200572 <get_memory_base>
ffffffffc020108a:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc020108c:	cf2ff0ef          	jal	ra,ffffffffc020057e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201090:	14050663          	beqz	a0,ffffffffc02011dc <pmm_init+0x19a>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc0201094:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc0201096:	00001517          	auipc	a0,0x1
ffffffffc020109a:	c8250513          	addi	a0,a0,-894 # ffffffffc0201d18 <best_fit_pmm_manager+0x98>
ffffffffc020109e:	8b2ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02010a2:	009909b3          	add	s3,s2,s1
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02010a6:	fff98693          	addi	a3,s3,-1
ffffffffc02010aa:	864a                	mv	a2,s2
ffffffffc02010ac:	85a6                	mv	a1,s1
ffffffffc02010ae:	00001517          	auipc	a0,0x1
ffffffffc02010b2:	c8250513          	addi	a0,a0,-894 # ffffffffc0201d30 <best_fit_pmm_manager+0xb0>
ffffffffc02010b6:	89aff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02010ba:	c8000737          	lui	a4,0xc8000
ffffffffc02010be:	87ce                	mv	a5,s3
ffffffffc02010c0:	0d376963          	bltu	a4,s3,ffffffffc0201192 <pmm_init+0x150>
ffffffffc02010c4:	00006817          	auipc	a6,0x6
ffffffffc02010c8:	fb380813          	addi	a6,a6,-77 # ffffffffc0207077 <end+0xfff>
ffffffffc02010cc:	757d                	lui	a0,0xfffff
ffffffffc02010ce:	83b1                	srli	a5,a5,0xc
ffffffffc02010d0:	00a87833          	and	a6,a6,a0
ffffffffc02010d4:	00005717          	auipc	a4,0x5
ffffffffc02010d8:	f6f73a23          	sd	a5,-140(a4) # ffffffffc0206048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010dc:	00005717          	auipc	a4,0x5
ffffffffc02010e0:	f9073a23          	sd	a6,-108(a4) # ffffffffc0206070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010e4:	00080737          	lui	a4,0x80
ffffffffc02010e8:	002006b7          	lui	a3,0x200
ffffffffc02010ec:	02e78563          	beq	a5,a4,ffffffffc0201116 <pmm_init+0xd4>
ffffffffc02010f0:	00279693          	slli	a3,a5,0x2
ffffffffc02010f4:	00f68633          	add	a2,a3,a5
ffffffffc02010f8:	fec00737          	lui	a4,0xfec00
ffffffffc02010fc:	9742                	add	a4,a4,a6
ffffffffc02010fe:	060e                	slli	a2,a2,0x3
ffffffffc0201100:	963a                	add	a2,a2,a4
ffffffffc0201102:	8742                	mv	a4,a6
        SetPageReserved(pages + i);
ffffffffc0201104:	670c                	ld	a1,8(a4)
ffffffffc0201106:	02870713          	addi	a4,a4,40 # fffffffffec00028 <end+0x3e9f9fb0>
ffffffffc020110a:	0015e593          	ori	a1,a1,1
ffffffffc020110e:	feb73023          	sd	a1,-32(a4)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc0201112:	fee619e3          	bne	a2,a4,ffffffffc0201104 <pmm_init+0xc2>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201116:	96be                	add	a3,a3,a5
ffffffffc0201118:	fec00737          	lui	a4,0xfec00
ffffffffc020111c:	9742                	add	a4,a4,a6
ffffffffc020111e:	068e                	slli	a3,a3,0x3
ffffffffc0201120:	96ba                	add	a3,a3,a4
ffffffffc0201122:	c0200737          	lui	a4,0xc0200
ffffffffc0201126:	08e6ef63          	bltu	a3,a4,ffffffffc02011c4 <pmm_init+0x182>
ffffffffc020112a:	00005497          	auipc	s1,0x5
ffffffffc020112e:	f3e48493          	addi	s1,s1,-194 # ffffffffc0206068 <va_pa_offset>
ffffffffc0201132:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc0201134:	777d                	lui	a4,0xfffff
ffffffffc0201136:	00e9f5b3          	and	a1,s3,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020113a:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc020113c:	04b6ee63          	bltu	a3,a1,ffffffffc0201198 <pmm_init+0x156>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201140:	601c                	ld	a5,0(s0)
ffffffffc0201142:	7b9c                	ld	a5,48(a5)
ffffffffc0201144:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201146:	00001517          	auipc	a0,0x1
ffffffffc020114a:	c7250513          	addi	a0,a0,-910 # ffffffffc0201db8 <best_fit_pmm_manager+0x138>
ffffffffc020114e:	802ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201152:	00004697          	auipc	a3,0x4
ffffffffc0201156:	eae68693          	addi	a3,a3,-338 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020115a:	00005797          	auipc	a5,0x5
ffffffffc020115e:	eed7bb23          	sd	a3,-266(a5) # ffffffffc0206050 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201162:	c02007b7          	lui	a5,0xc0200
ffffffffc0201166:	08f6e763          	bltu	a3,a5,ffffffffc02011f4 <pmm_init+0x1b2>
ffffffffc020116a:	609c                	ld	a5,0(s1)
}
ffffffffc020116c:	7402                	ld	s0,32(sp)
ffffffffc020116e:	70a2                	ld	ra,40(sp)
ffffffffc0201170:	64e2                	ld	s1,24(sp)
ffffffffc0201172:	6942                	ld	s2,16(sp)
ffffffffc0201174:	69a2                	ld	s3,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201176:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201178:	8e9d                	sub	a3,a3,a5
ffffffffc020117a:	00005797          	auipc	a5,0x5
ffffffffc020117e:	ecd7bf23          	sd	a3,-290(a5) # ffffffffc0206058 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201182:	00001517          	auipc	a0,0x1
ffffffffc0201186:	c5650513          	addi	a0,a0,-938 # ffffffffc0201dd8 <best_fit_pmm_manager+0x158>
ffffffffc020118a:	8636                	mv	a2,a3
}
ffffffffc020118c:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020118e:	fc3fe06f          	j	ffffffffc0200150 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc0201192:	c80007b7          	lui	a5,0xc8000
ffffffffc0201196:	b73d                	j	ffffffffc02010c4 <pmm_init+0x82>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc0201198:	6605                	lui	a2,0x1
ffffffffc020119a:	167d                	addi	a2,a2,-1
ffffffffc020119c:	96b2                	add	a3,a3,a2
ffffffffc020119e:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02011a0:	00c6d513          	srli	a0,a3,0xc
ffffffffc02011a4:	06f57463          	bgeu	a0,a5,ffffffffc020120c <pmm_init+0x1ca>
    pmm_manager->init_memmap(base, n);
ffffffffc02011a8:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02011aa:	fff807b7          	lui	a5,0xfff80
ffffffffc02011ae:	97aa                	add	a5,a5,a0
ffffffffc02011b0:	00279513          	slli	a0,a5,0x2
ffffffffc02011b4:	953e                	add	a0,a0,a5
ffffffffc02011b6:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02011b8:	8d95                	sub	a1,a1,a3
ffffffffc02011ba:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02011bc:	81b1                	srli	a1,a1,0xc
ffffffffc02011be:	9542                	add	a0,a0,a6
ffffffffc02011c0:	9782                	jalr	a5
ffffffffc02011c2:	bfbd                	j	ffffffffc0201140 <pmm_init+0xfe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011c4:	00001617          	auipc	a2,0x1
ffffffffc02011c8:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0201d60 <best_fit_pmm_manager+0xe0>
ffffffffc02011cc:	05e00593          	li	a1,94
ffffffffc02011d0:	00001517          	auipc	a0,0x1
ffffffffc02011d4:	b3850513          	addi	a0,a0,-1224 # ffffffffc0201d08 <best_fit_pmm_manager+0x88>
ffffffffc02011d8:	fedfe0ef          	jal	ra,ffffffffc02001c4 <__panic>
        panic("DTB memory info not available");
ffffffffc02011dc:	00001617          	auipc	a2,0x1
ffffffffc02011e0:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0201ce8 <best_fit_pmm_manager+0x68>
ffffffffc02011e4:	04600593          	li	a1,70
ffffffffc02011e8:	00001517          	auipc	a0,0x1
ffffffffc02011ec:	b2050513          	addi	a0,a0,-1248 # ffffffffc0201d08 <best_fit_pmm_manager+0x88>
ffffffffc02011f0:	fd5fe0ef          	jal	ra,ffffffffc02001c4 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011f4:	00001617          	auipc	a2,0x1
ffffffffc02011f8:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0201d60 <best_fit_pmm_manager+0xe0>
ffffffffc02011fc:	07900593          	li	a1,121
ffffffffc0201200:	00001517          	auipc	a0,0x1
ffffffffc0201204:	b0850513          	addi	a0,a0,-1272 # ffffffffc0201d08 <best_fit_pmm_manager+0x88>
ffffffffc0201208:	fbdfe0ef          	jal	ra,ffffffffc02001c4 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020120c:	00001617          	auipc	a2,0x1
ffffffffc0201210:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0201d88 <best_fit_pmm_manager+0x108>
ffffffffc0201214:	06a00593          	li	a1,106
ffffffffc0201218:	00001517          	auipc	a0,0x1
ffffffffc020121c:	b9050513          	addi	a0,a0,-1136 # ffffffffc0201da8 <best_fit_pmm_manager+0x128>
ffffffffc0201220:	fa5fe0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0201224 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0201224:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201228:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020122a:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020122e:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201230:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201234:	f022                	sd	s0,32(sp)
ffffffffc0201236:	ec26                	sd	s1,24(sp)
ffffffffc0201238:	e84a                	sd	s2,16(sp)
ffffffffc020123a:	f406                	sd	ra,40(sp)
ffffffffc020123c:	e44e                	sd	s3,8(sp)
ffffffffc020123e:	84aa                	mv	s1,a0
ffffffffc0201240:	892e                	mv	s2,a1
ffffffffc0201242:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0201246:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201248:	03067e63          	bgeu	a2,a6,ffffffffc0201284 <printnum+0x60>
ffffffffc020124c:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc020124e:	00805763          	blez	s0,ffffffffc020125c <printnum+0x38>
ffffffffc0201252:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0201254:	85ca                	mv	a1,s2
ffffffffc0201256:	854e                	mv	a0,s3
ffffffffc0201258:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020125a:	fc65                	bnez	s0,ffffffffc0201252 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020125c:	1a02                	slli	s4,s4,0x20
ffffffffc020125e:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201262:	00001797          	auipc	a5,0x1
ffffffffc0201266:	d4678793          	addi	a5,a5,-698 # ffffffffc0201fa8 <error_string+0x38>
ffffffffc020126a:	9a3e                	add	s4,s4,a5
}
ffffffffc020126c:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020126e:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201272:	70a2                	ld	ra,40(sp)
ffffffffc0201274:	69a2                	ld	s3,8(sp)
ffffffffc0201276:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201278:	85ca                	mv	a1,s2
ffffffffc020127a:	8326                	mv	t1,s1
}
ffffffffc020127c:	6942                	ld	s2,16(sp)
ffffffffc020127e:	64e2                	ld	s1,24(sp)
ffffffffc0201280:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201282:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201284:	03065633          	divu	a2,a2,a6
ffffffffc0201288:	8722                	mv	a4,s0
ffffffffc020128a:	f9bff0ef          	jal	ra,ffffffffc0201224 <printnum>
ffffffffc020128e:	b7f9                	j	ffffffffc020125c <printnum+0x38>

ffffffffc0201290 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201290:	7119                	addi	sp,sp,-128
ffffffffc0201292:	f4a6                	sd	s1,104(sp)
ffffffffc0201294:	f0ca                	sd	s2,96(sp)
ffffffffc0201296:	e8d2                	sd	s4,80(sp)
ffffffffc0201298:	e4d6                	sd	s5,72(sp)
ffffffffc020129a:	e0da                	sd	s6,64(sp)
ffffffffc020129c:	fc5e                	sd	s7,56(sp)
ffffffffc020129e:	f862                	sd	s8,48(sp)
ffffffffc02012a0:	f06a                	sd	s10,32(sp)
ffffffffc02012a2:	fc86                	sd	ra,120(sp)
ffffffffc02012a4:	f8a2                	sd	s0,112(sp)
ffffffffc02012a6:	ecce                	sd	s3,88(sp)
ffffffffc02012a8:	f466                	sd	s9,40(sp)
ffffffffc02012aa:	ec6e                	sd	s11,24(sp)
ffffffffc02012ac:	892a                	mv	s2,a0
ffffffffc02012ae:	84ae                	mv	s1,a1
ffffffffc02012b0:	8d32                	mv	s10,a2
ffffffffc02012b2:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012b4:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012b6:	00001a17          	auipc	s4,0x1
ffffffffc02012ba:	b62a0a13          	addi	s4,s4,-1182 # ffffffffc0201e18 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012be:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012c2:	00001c17          	auipc	s8,0x1
ffffffffc02012c6:	caec0c13          	addi	s8,s8,-850 # ffffffffc0201f70 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ca:	000d4503          	lbu	a0,0(s10)
ffffffffc02012ce:	02500793          	li	a5,37
ffffffffc02012d2:	001d0413          	addi	s0,s10,1
ffffffffc02012d6:	00f50e63          	beq	a0,a5,ffffffffc02012f2 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02012da:	c521                	beqz	a0,ffffffffc0201322 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012dc:	02500993          	li	s3,37
ffffffffc02012e0:	a011                	j	ffffffffc02012e4 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02012e2:	c121                	beqz	a0,ffffffffc0201322 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02012e4:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012e6:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02012e8:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ea:	fff44503          	lbu	a0,-1(s0)
ffffffffc02012ee:	ff351ae3          	bne	a0,s3,ffffffffc02012e2 <vprintfmt+0x52>
ffffffffc02012f2:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02012f6:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc02012fa:	4981                	li	s3,0
ffffffffc02012fc:	4801                	li	a6,0
        width = precision = -1;
ffffffffc02012fe:	5cfd                	li	s9,-1
ffffffffc0201300:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201302:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc0201306:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201308:	fdd6069b          	addiw	a3,a2,-35
ffffffffc020130c:	0ff6f693          	andi	a3,a3,255
ffffffffc0201310:	00140d13          	addi	s10,s0,1
ffffffffc0201314:	1ed5ef63          	bltu	a1,a3,ffffffffc0201512 <vprintfmt+0x282>
ffffffffc0201318:	068a                	slli	a3,a3,0x2
ffffffffc020131a:	96d2                	add	a3,a3,s4
ffffffffc020131c:	4294                	lw	a3,0(a3)
ffffffffc020131e:	96d2                	add	a3,a3,s4
ffffffffc0201320:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0201322:	70e6                	ld	ra,120(sp)
ffffffffc0201324:	7446                	ld	s0,112(sp)
ffffffffc0201326:	74a6                	ld	s1,104(sp)
ffffffffc0201328:	7906                	ld	s2,96(sp)
ffffffffc020132a:	69e6                	ld	s3,88(sp)
ffffffffc020132c:	6a46                	ld	s4,80(sp)
ffffffffc020132e:	6aa6                	ld	s5,72(sp)
ffffffffc0201330:	6b06                	ld	s6,64(sp)
ffffffffc0201332:	7be2                	ld	s7,56(sp)
ffffffffc0201334:	7c42                	ld	s8,48(sp)
ffffffffc0201336:	7ca2                	ld	s9,40(sp)
ffffffffc0201338:	7d02                	ld	s10,32(sp)
ffffffffc020133a:	6de2                	ld	s11,24(sp)
ffffffffc020133c:	6109                	addi	sp,sp,128
ffffffffc020133e:	8082                	ret
            padc = '-';
ffffffffc0201340:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201342:	00144603          	lbu	a2,1(s0)
ffffffffc0201346:	846a                	mv	s0,s10
ffffffffc0201348:	b7c1                	j	ffffffffc0201308 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc020134a:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc020134e:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201352:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201354:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc0201356:	fa0dd9e3          	bgez	s11,ffffffffc0201308 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc020135a:	8de6                	mv	s11,s9
ffffffffc020135c:	5cfd                	li	s9,-1
ffffffffc020135e:	b76d                	j	ffffffffc0201308 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0201360:	fffdc693          	not	a3,s11
ffffffffc0201364:	96fd                	srai	a3,a3,0x3f
ffffffffc0201366:	00ddfdb3          	and	s11,s11,a3
ffffffffc020136a:	00144603          	lbu	a2,1(s0)
ffffffffc020136e:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201370:	846a                	mv	s0,s10
ffffffffc0201372:	bf59                	j	ffffffffc0201308 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0201374:	4705                	li	a4,1
ffffffffc0201376:	008a8593          	addi	a1,s5,8
ffffffffc020137a:	01074463          	blt	a4,a6,ffffffffc0201382 <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc020137e:	22080863          	beqz	a6,ffffffffc02015ae <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc0201382:	000ab603          	ld	a2,0(s5)
ffffffffc0201386:	46c1                	li	a3,16
ffffffffc0201388:	8aae                	mv	s5,a1
ffffffffc020138a:	a291                	j	ffffffffc02014ce <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc020138c:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201390:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201394:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201396:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020139a:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc020139e:	fad56ce3          	bltu	a0,a3,ffffffffc0201356 <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc02013a2:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013a4:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02013a8:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013ac:	0196873b          	addw	a4,a3,s9
ffffffffc02013b0:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013b4:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02013b8:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02013bc:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02013c0:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013c4:	fcd57fe3          	bgeu	a0,a3,ffffffffc02013a2 <vprintfmt+0x112>
ffffffffc02013c8:	b779                	j	ffffffffc0201356 <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc02013ca:	000aa503          	lw	a0,0(s5)
ffffffffc02013ce:	85a6                	mv	a1,s1
ffffffffc02013d0:	0aa1                	addi	s5,s5,8
ffffffffc02013d2:	9902                	jalr	s2
            break;
ffffffffc02013d4:	bddd                	j	ffffffffc02012ca <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013d6:	4705                	li	a4,1
ffffffffc02013d8:	008a8993          	addi	s3,s5,8
ffffffffc02013dc:	01074463          	blt	a4,a6,ffffffffc02013e4 <vprintfmt+0x154>
    else if (lflag) {
ffffffffc02013e0:	1c080463          	beqz	a6,ffffffffc02015a8 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc02013e4:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02013e8:	1c044a63          	bltz	s0,ffffffffc02015bc <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc02013ec:	8622                	mv	a2,s0
ffffffffc02013ee:	8ace                	mv	s5,s3
ffffffffc02013f0:	46a9                	li	a3,10
ffffffffc02013f2:	a8f1                	j	ffffffffc02014ce <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc02013f4:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02013f8:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc02013fa:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02013fc:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201400:	8fb5                	xor	a5,a5,a3
ffffffffc0201402:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201406:	12d74963          	blt	a4,a3,ffffffffc0201538 <vprintfmt+0x2a8>
ffffffffc020140a:	00369793          	slli	a5,a3,0x3
ffffffffc020140e:	97e2                	add	a5,a5,s8
ffffffffc0201410:	639c                	ld	a5,0(a5)
ffffffffc0201412:	12078363          	beqz	a5,ffffffffc0201538 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc0201416:	86be                	mv	a3,a5
ffffffffc0201418:	00001617          	auipc	a2,0x1
ffffffffc020141c:	c4060613          	addi	a2,a2,-960 # ffffffffc0202058 <error_string+0xe8>
ffffffffc0201420:	85a6                	mv	a1,s1
ffffffffc0201422:	854a                	mv	a0,s2
ffffffffc0201424:	1cc000ef          	jal	ra,ffffffffc02015f0 <printfmt>
ffffffffc0201428:	b54d                	j	ffffffffc02012ca <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020142a:	000ab603          	ld	a2,0(s5)
ffffffffc020142e:	0aa1                	addi	s5,s5,8
ffffffffc0201430:	1a060163          	beqz	a2,ffffffffc02015d2 <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc0201434:	00160413          	addi	s0,a2,1
ffffffffc0201438:	15b05763          	blez	s11,ffffffffc0201586 <vprintfmt+0x2f6>
ffffffffc020143c:	02d00593          	li	a1,45
ffffffffc0201440:	10b79d63          	bne	a5,a1,ffffffffc020155a <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201444:	00064783          	lbu	a5,0(a2)
ffffffffc0201448:	0007851b          	sext.w	a0,a5
ffffffffc020144c:	c905                	beqz	a0,ffffffffc020147c <vprintfmt+0x1ec>
ffffffffc020144e:	000cc563          	bltz	s9,ffffffffc0201458 <vprintfmt+0x1c8>
ffffffffc0201452:	3cfd                	addiw	s9,s9,-1
ffffffffc0201454:	036c8263          	beq	s9,s6,ffffffffc0201478 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc0201458:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020145a:	14098f63          	beqz	s3,ffffffffc02015b8 <vprintfmt+0x328>
ffffffffc020145e:	3781                	addiw	a5,a5,-32
ffffffffc0201460:	14fbfc63          	bgeu	s7,a5,ffffffffc02015b8 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc0201464:	03f00513          	li	a0,63
ffffffffc0201468:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020146a:	0405                	addi	s0,s0,1
ffffffffc020146c:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201470:	3dfd                	addiw	s11,s11,-1
ffffffffc0201472:	0007851b          	sext.w	a0,a5
ffffffffc0201476:	fd61                	bnez	a0,ffffffffc020144e <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0201478:	e5b059e3          	blez	s11,ffffffffc02012ca <vprintfmt+0x3a>
ffffffffc020147c:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020147e:	85a6                	mv	a1,s1
ffffffffc0201480:	02000513          	li	a0,32
ffffffffc0201484:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201486:	e40d82e3          	beqz	s11,ffffffffc02012ca <vprintfmt+0x3a>
ffffffffc020148a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020148c:	85a6                	mv	a1,s1
ffffffffc020148e:	02000513          	li	a0,32
ffffffffc0201492:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201494:	fe0d94e3          	bnez	s11,ffffffffc020147c <vprintfmt+0x1ec>
ffffffffc0201498:	bd0d                	j	ffffffffc02012ca <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020149a:	4705                	li	a4,1
ffffffffc020149c:	008a8593          	addi	a1,s5,8
ffffffffc02014a0:	01074463          	blt	a4,a6,ffffffffc02014a8 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc02014a4:	0e080863          	beqz	a6,ffffffffc0201594 <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc02014a8:	000ab603          	ld	a2,0(s5)
ffffffffc02014ac:	46a1                	li	a3,8
ffffffffc02014ae:	8aae                	mv	s5,a1
ffffffffc02014b0:	a839                	j	ffffffffc02014ce <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc02014b2:	03000513          	li	a0,48
ffffffffc02014b6:	85a6                	mv	a1,s1
ffffffffc02014b8:	e03e                	sd	a5,0(sp)
ffffffffc02014ba:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02014bc:	85a6                	mv	a1,s1
ffffffffc02014be:	07800513          	li	a0,120
ffffffffc02014c2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014c4:	0aa1                	addi	s5,s5,8
ffffffffc02014c6:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02014ca:	6782                	ld	a5,0(sp)
ffffffffc02014cc:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02014ce:	2781                	sext.w	a5,a5
ffffffffc02014d0:	876e                	mv	a4,s11
ffffffffc02014d2:	85a6                	mv	a1,s1
ffffffffc02014d4:	854a                	mv	a0,s2
ffffffffc02014d6:	d4fff0ef          	jal	ra,ffffffffc0201224 <printnum>
            break;
ffffffffc02014da:	bbc5                	j	ffffffffc02012ca <vprintfmt+0x3a>
            lflag ++;
ffffffffc02014dc:	00144603          	lbu	a2,1(s0)
ffffffffc02014e0:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014e2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014e4:	b515                	j	ffffffffc0201308 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02014e6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02014ea:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014ec:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014ee:	bd29                	j	ffffffffc0201308 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02014f0:	85a6                	mv	a1,s1
ffffffffc02014f2:	02500513          	li	a0,37
ffffffffc02014f6:	9902                	jalr	s2
            break;
ffffffffc02014f8:	bbc9                	j	ffffffffc02012ca <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02014fa:	4705                	li	a4,1
ffffffffc02014fc:	008a8593          	addi	a1,s5,8
ffffffffc0201500:	01074463          	blt	a4,a6,ffffffffc0201508 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc0201504:	08080d63          	beqz	a6,ffffffffc020159e <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0201508:	000ab603          	ld	a2,0(s5)
ffffffffc020150c:	46a9                	li	a3,10
ffffffffc020150e:	8aae                	mv	s5,a1
ffffffffc0201510:	bf7d                	j	ffffffffc02014ce <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc0201512:	85a6                	mv	a1,s1
ffffffffc0201514:	02500513          	li	a0,37
ffffffffc0201518:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020151a:	fff44703          	lbu	a4,-1(s0)
ffffffffc020151e:	02500793          	li	a5,37
ffffffffc0201522:	8d22                	mv	s10,s0
ffffffffc0201524:	daf703e3          	beq	a4,a5,ffffffffc02012ca <vprintfmt+0x3a>
ffffffffc0201528:	02500713          	li	a4,37
ffffffffc020152c:	1d7d                	addi	s10,s10,-1
ffffffffc020152e:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0201532:	fee79de3          	bne	a5,a4,ffffffffc020152c <vprintfmt+0x29c>
ffffffffc0201536:	bb51                	j	ffffffffc02012ca <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201538:	00001617          	auipc	a2,0x1
ffffffffc020153c:	b1060613          	addi	a2,a2,-1264 # ffffffffc0202048 <error_string+0xd8>
ffffffffc0201540:	85a6                	mv	a1,s1
ffffffffc0201542:	854a                	mv	a0,s2
ffffffffc0201544:	0ac000ef          	jal	ra,ffffffffc02015f0 <printfmt>
ffffffffc0201548:	b349                	j	ffffffffc02012ca <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020154a:	00001617          	auipc	a2,0x1
ffffffffc020154e:	af660613          	addi	a2,a2,-1290 # ffffffffc0202040 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc0201552:	00001417          	auipc	s0,0x1
ffffffffc0201556:	aef40413          	addi	s0,s0,-1297 # ffffffffc0202041 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020155a:	8532                	mv	a0,a2
ffffffffc020155c:	85e6                	mv	a1,s9
ffffffffc020155e:	e032                	sd	a2,0(sp)
ffffffffc0201560:	e43e                	sd	a5,8(sp)
ffffffffc0201562:	0e8000ef          	jal	ra,ffffffffc020164a <strnlen>
ffffffffc0201566:	40ad8dbb          	subw	s11,s11,a0
ffffffffc020156a:	6602                	ld	a2,0(sp)
ffffffffc020156c:	01b05d63          	blez	s11,ffffffffc0201586 <vprintfmt+0x2f6>
ffffffffc0201570:	67a2                	ld	a5,8(sp)
ffffffffc0201572:	2781                	sext.w	a5,a5
ffffffffc0201574:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc0201576:	6522                	ld	a0,8(sp)
ffffffffc0201578:	85a6                	mv	a1,s1
ffffffffc020157a:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020157c:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc020157e:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201580:	6602                	ld	a2,0(sp)
ffffffffc0201582:	fe0d9ae3          	bnez	s11,ffffffffc0201576 <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201586:	00064783          	lbu	a5,0(a2)
ffffffffc020158a:	0007851b          	sext.w	a0,a5
ffffffffc020158e:	ec0510e3          	bnez	a0,ffffffffc020144e <vprintfmt+0x1be>
ffffffffc0201592:	bb25                	j	ffffffffc02012ca <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc0201594:	000ae603          	lwu	a2,0(s5)
ffffffffc0201598:	46a1                	li	a3,8
ffffffffc020159a:	8aae                	mv	s5,a1
ffffffffc020159c:	bf0d                	j	ffffffffc02014ce <vprintfmt+0x23e>
ffffffffc020159e:	000ae603          	lwu	a2,0(s5)
ffffffffc02015a2:	46a9                	li	a3,10
ffffffffc02015a4:	8aae                	mv	s5,a1
ffffffffc02015a6:	b725                	j	ffffffffc02014ce <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc02015a8:	000aa403          	lw	s0,0(s5)
ffffffffc02015ac:	bd35                	j	ffffffffc02013e8 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc02015ae:	000ae603          	lwu	a2,0(s5)
ffffffffc02015b2:	46c1                	li	a3,16
ffffffffc02015b4:	8aae                	mv	s5,a1
ffffffffc02015b6:	bf21                	j	ffffffffc02014ce <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc02015b8:	9902                	jalr	s2
ffffffffc02015ba:	bd45                	j	ffffffffc020146a <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc02015bc:	85a6                	mv	a1,s1
ffffffffc02015be:	02d00513          	li	a0,45
ffffffffc02015c2:	e03e                	sd	a5,0(sp)
ffffffffc02015c4:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015c6:	8ace                	mv	s5,s3
ffffffffc02015c8:	40800633          	neg	a2,s0
ffffffffc02015cc:	46a9                	li	a3,10
ffffffffc02015ce:	6782                	ld	a5,0(sp)
ffffffffc02015d0:	bdfd                	j	ffffffffc02014ce <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc02015d2:	01b05663          	blez	s11,ffffffffc02015de <vprintfmt+0x34e>
ffffffffc02015d6:	02d00693          	li	a3,45
ffffffffc02015da:	f6d798e3          	bne	a5,a3,ffffffffc020154a <vprintfmt+0x2ba>
ffffffffc02015de:	00001417          	auipc	s0,0x1
ffffffffc02015e2:	a6340413          	addi	s0,s0,-1437 # ffffffffc0202041 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015e6:	02800513          	li	a0,40
ffffffffc02015ea:	02800793          	li	a5,40
ffffffffc02015ee:	b585                	j	ffffffffc020144e <vprintfmt+0x1be>

ffffffffc02015f0 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015f0:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02015f2:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015f6:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02015f8:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015fa:	ec06                	sd	ra,24(sp)
ffffffffc02015fc:	f83a                	sd	a4,48(sp)
ffffffffc02015fe:	fc3e                	sd	a5,56(sp)
ffffffffc0201600:	e0c2                	sd	a6,64(sp)
ffffffffc0201602:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0201604:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201606:	c8bff0ef          	jal	ra,ffffffffc0201290 <vprintfmt>
}
ffffffffc020160a:	60e2                	ld	ra,24(sp)
ffffffffc020160c:	6161                	addi	sp,sp,80
ffffffffc020160e:	8082                	ret

ffffffffc0201610 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201610:	00005797          	auipc	a5,0x5
ffffffffc0201614:	a0078793          	addi	a5,a5,-1536 # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201618:	6398                	ld	a4,0(a5)
ffffffffc020161a:	4781                	li	a5,0
ffffffffc020161c:	88ba                	mv	a7,a4
ffffffffc020161e:	852a                	mv	a0,a0
ffffffffc0201620:	85be                	mv	a1,a5
ffffffffc0201622:	863e                	mv	a2,a5
ffffffffc0201624:	00000073          	ecall
ffffffffc0201628:	87aa                	mv	a5,a0
}
ffffffffc020162a:	8082                	ret

ffffffffc020162c <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc020162c:	00054783          	lbu	a5,0(a0)
ffffffffc0201630:	cb91                	beqz	a5,ffffffffc0201644 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0201632:	4781                	li	a5,0
        cnt ++;
ffffffffc0201634:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc0201636:	00f50733          	add	a4,a0,a5
ffffffffc020163a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0x3fdf8f88>
ffffffffc020163e:	fb7d                	bnez	a4,ffffffffc0201634 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201640:	853e                	mv	a0,a5
ffffffffc0201642:	8082                	ret
    size_t cnt = 0;
ffffffffc0201644:	4781                	li	a5,0
}
ffffffffc0201646:	853e                	mv	a0,a5
ffffffffc0201648:	8082                	ret

ffffffffc020164a <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020164a:	c185                	beqz	a1,ffffffffc020166a <strnlen+0x20>
ffffffffc020164c:	00054783          	lbu	a5,0(a0)
ffffffffc0201650:	cf89                	beqz	a5,ffffffffc020166a <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0201652:	4781                	li	a5,0
ffffffffc0201654:	a021                	j	ffffffffc020165c <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201656:	00074703          	lbu	a4,0(a4)
ffffffffc020165a:	c711                	beqz	a4,ffffffffc0201666 <strnlen+0x1c>
        cnt ++;
ffffffffc020165c:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc020165e:	00f50733          	add	a4,a0,a5
ffffffffc0201662:	fef59ae3          	bne	a1,a5,ffffffffc0201656 <strnlen+0xc>
    }
    return cnt;
}
ffffffffc0201666:	853e                	mv	a0,a5
ffffffffc0201668:	8082                	ret
    size_t cnt = 0;
ffffffffc020166a:	4781                	li	a5,0
}
ffffffffc020166c:	853e                	mv	a0,a5
ffffffffc020166e:	8082                	ret

ffffffffc0201670 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201670:	00054783          	lbu	a5,0(a0)
ffffffffc0201674:	0005c703          	lbu	a4,0(a1)
ffffffffc0201678:	cb91                	beqz	a5,ffffffffc020168c <strcmp+0x1c>
ffffffffc020167a:	00e79c63          	bne	a5,a4,ffffffffc0201692 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc020167e:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201680:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc0201684:	0585                	addi	a1,a1,1
ffffffffc0201686:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc020168a:	fbe5                	bnez	a5,ffffffffc020167a <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc020168c:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc020168e:	9d19                	subw	a0,a0,a4
ffffffffc0201690:	8082                	ret
ffffffffc0201692:	0007851b          	sext.w	a0,a5
ffffffffc0201696:	9d19                	subw	a0,a0,a4
ffffffffc0201698:	8082                	ret

ffffffffc020169a <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc020169a:	c61d                	beqz	a2,ffffffffc02016c8 <strncmp+0x2e>
ffffffffc020169c:	00054703          	lbu	a4,0(a0)
ffffffffc02016a0:	0005c683          	lbu	a3,0(a1)
ffffffffc02016a4:	c715                	beqz	a4,ffffffffc02016d0 <strncmp+0x36>
ffffffffc02016a6:	02e69563          	bne	a3,a4,ffffffffc02016d0 <strncmp+0x36>
ffffffffc02016aa:	962e                	add	a2,a2,a1
ffffffffc02016ac:	a809                	j	ffffffffc02016be <strncmp+0x24>
ffffffffc02016ae:	00054703          	lbu	a4,0(a0)
ffffffffc02016b2:	cf09                	beqz	a4,ffffffffc02016cc <strncmp+0x32>
ffffffffc02016b4:	0007c683          	lbu	a3,0(a5)
ffffffffc02016b8:	85be                	mv	a1,a5
ffffffffc02016ba:	00d71b63          	bne	a4,a3,ffffffffc02016d0 <strncmp+0x36>
        n --, s1 ++, s2 ++;
ffffffffc02016be:	00158793          	addi	a5,a1,1
ffffffffc02016c2:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016c4:	fec795e3          	bne	a5,a2,ffffffffc02016ae <strncmp+0x14>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016c8:	4501                	li	a0,0
ffffffffc02016ca:	8082                	ret
ffffffffc02016cc:	0015c683          	lbu	a3,1(a1)
ffffffffc02016d0:	40d7053b          	subw	a0,a4,a3
}
ffffffffc02016d4:	8082                	ret

ffffffffc02016d6 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02016d6:	ca01                	beqz	a2,ffffffffc02016e6 <memset+0x10>
ffffffffc02016d8:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02016da:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02016dc:	0785                	addi	a5,a5,1
ffffffffc02016de:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02016e2:	fec79de3          	bne	a5,a2,ffffffffc02016dc <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016e6:	8082                	ret

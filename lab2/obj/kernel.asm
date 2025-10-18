
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
ffffffffc0200054:	6c050513          	addi	a0,a0,1728 # ffffffffc0201710 <etext+0x20>
void print_kerninfo(void) {
ffffffffc0200058:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020005a:	0f6000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", (uintptr_t)kern_init);
ffffffffc020005e:	00000597          	auipc	a1,0x0
ffffffffc0200062:	07e58593          	addi	a1,a1,126 # ffffffffc02000dc <kern_init>
ffffffffc0200066:	00001517          	auipc	a0,0x1
ffffffffc020006a:	6ca50513          	addi	a0,a0,1738 # ffffffffc0201730 <etext+0x40>
ffffffffc020006e:	0e2000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200072:	00001597          	auipc	a1,0x1
ffffffffc0200076:	67e58593          	addi	a1,a1,1662 # ffffffffc02016f0 <etext>
ffffffffc020007a:	00001517          	auipc	a0,0x1
ffffffffc020007e:	6d650513          	addi	a0,a0,1750 # ffffffffc0201750 <etext+0x60>
ffffffffc0200082:	0ce000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200086:	00006597          	auipc	a1,0x6
ffffffffc020008a:	f9258593          	addi	a1,a1,-110 # ffffffffc0206018 <edata>
ffffffffc020008e:	00001517          	auipc	a0,0x1
ffffffffc0200092:	6e250513          	addi	a0,a0,1762 # ffffffffc0201770 <etext+0x80>
ffffffffc0200096:	0ba000ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc020009a:	00006597          	auipc	a1,0x6
ffffffffc020009e:	fde58593          	addi	a1,a1,-34 # ffffffffc0206078 <end>
ffffffffc02000a2:	00001517          	auipc	a0,0x1
ffffffffc02000a6:	6ee50513          	addi	a0,a0,1774 # ffffffffc0201790 <etext+0xa0>
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
ffffffffc02000d4:	6e050513          	addi	a0,a0,1760 # ffffffffc02017b0 <etext+0xc0>
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
ffffffffc02000f4:	5ea010ef          	jal	ra,ffffffffc02016de <memset>
    dtb_init();
ffffffffc02000f8:	194000ef          	jal	ra,ffffffffc020028c <dtb_init>
    cons_init();  // init the console
ffffffffc02000fc:	120000ef          	jal	ra,ffffffffc020021c <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200100:	00001517          	auipc	a0,0x1
ffffffffc0200104:	5f050513          	addi	a0,a0,1520 # ffffffffc02016f0 <etext>
ffffffffc0200108:	07c000ef          	jal	ra,ffffffffc0200184 <cputs>

    print_kerninfo();
ffffffffc020010c:	f43ff0ef          	jal	ra,ffffffffc020004e <print_kerninfo>

    // grade_backtrace();
    pmm_init();  // init physical memory management
ffffffffc0200110:	73b000ef          	jal	ra,ffffffffc020104a <pmm_init>

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
ffffffffc0200144:	154010ef          	jal	ra,ffffffffc0201298 <vprintfmt>
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
ffffffffc0200178:	120010ef          	jal	ra,ffffffffc0201298 <vprintfmt>
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
ffffffffc02001fc:	5e850513          	addi	a0,a0,1512 # ffffffffc02017e0 <etext+0xf0>
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
ffffffffc0200212:	5ca50513          	addi	a0,a0,1482 # ffffffffc02017d8 <etext+0xe8>
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
ffffffffc0200222:	3f60106f          	j	ffffffffc0201618 <sbi_console_putchar>

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
ffffffffc0200292:	57250513          	addi	a0,a0,1394 # ffffffffc0201800 <etext+0x110>
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
ffffffffc02002c2:	55250513          	addi	a0,a0,1362 # ffffffffc0201810 <etext+0x120>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02002c6:	00006417          	auipc	s0,0x6
ffffffffc02002ca:	d4240413          	addi	s0,s0,-702 # ffffffffc0206008 <boot_dtb>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc02002ce:	e83ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02002d2:	600c                	ld	a1,0(s0)
ffffffffc02002d4:	00001517          	auipc	a0,0x1
ffffffffc02002d8:	54c50513          	addi	a0,a0,1356 # ffffffffc0201820 <etext+0x130>
ffffffffc02002dc:	e75ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    
    if (boot_dtb == 0) {
ffffffffc02002e0:	00043983          	ld	s3,0(s0)
        cprintf("Error: DTB address is null\n");
ffffffffc02002e4:	00001517          	auipc	a0,0x1
ffffffffc02002e8:	55450513          	addi	a0,a0,1364 # ffffffffc0201838 <etext+0x148>
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
ffffffffc02003a6:	4e648493          	addi	s1,s1,1254 # ffffffffc0201888 <etext+0x198>
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
ffffffffc02003f6:	50e50513          	addi	a0,a0,1294 # ffffffffc0201900 <etext+0x210>
ffffffffc02003fa:	d57ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    }
    cprintf("DTB init completed\n");
ffffffffc02003fe:	00001517          	auipc	a0,0x1
ffffffffc0200402:	53a50513          	addi	a0,a0,1338 # ffffffffc0201938 <etext+0x248>
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
ffffffffc0200442:	41a50513          	addi	a0,a0,1050 # ffffffffc0201858 <etext+0x168>
}
ffffffffc0200446:	6165                	addi	sp,sp,112
        cprintf("Error: Invalid DTB magic number: 0x%x\n", magic);
ffffffffc0200448:	b321                	j	ffffffffc0200150 <cprintf>
        switch (token) {
ffffffffc020044a:	fba794e3          	bne	a5,s10,ffffffffc02003f2 <dtb_init+0x166>
                int name_len = strlen(name);
ffffffffc020044e:	8552                	mv	a0,s4
ffffffffc0200450:	1e4010ef          	jal	ra,ffffffffc0201634 <strlen>
ffffffffc0200454:	0005099b          	sext.w	s3,a0
                if (strncmp(name, "memory", 6) == 0) {
ffffffffc0200458:	4619                	li	a2,6
ffffffffc020045a:	00001597          	auipc	a1,0x1
ffffffffc020045e:	42658593          	addi	a1,a1,1062 # ffffffffc0201880 <etext+0x190>
ffffffffc0200462:	8552                	mv	a0,s4
ffffffffc0200464:	23e010ef          	jal	ra,ffffffffc02016a2 <strncmp>
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
ffffffffc02004fa:	17e010ef          	jal	ra,ffffffffc0201678 <strcmp>
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
ffffffffc020051e:	37650513          	addi	a0,a0,886 # ffffffffc0201890 <etext+0x1a0>
ffffffffc0200522:	c2fff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Base: 0x%016lx\n", mem_base);
ffffffffc0200526:	85a6                	mv	a1,s1
ffffffffc0200528:	00001517          	auipc	a0,0x1
ffffffffc020052c:	38850513          	addi	a0,a0,904 # ffffffffc02018b0 <etext+0x1c0>
ffffffffc0200530:	c21ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  Size: 0x%016lx (%ld MB)\n", mem_size, mem_size / (1024 * 1024));
ffffffffc0200534:	01445613          	srli	a2,s0,0x14
ffffffffc0200538:	85a2                	mv	a1,s0
ffffffffc020053a:	00001517          	auipc	a0,0x1
ffffffffc020053e:	38e50513          	addi	a0,a0,910 # ffffffffc02018c8 <etext+0x1d8>
ffffffffc0200542:	c0fff0ef          	jal	ra,ffffffffc0200150 <cprintf>
        cprintf("  End:  0x%016lx\n", mem_base + mem_size - 1);
ffffffffc0200546:	008485b3          	add	a1,s1,s0
ffffffffc020054a:	15fd                	addi	a1,a1,-1
ffffffffc020054c:	00001517          	auipc	a0,0x1
ffffffffc0200550:	39c50513          	addi	a0,a0,924 # ffffffffc02018e8 <etext+0x1f8>
ffffffffc0200554:	bfdff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    cprintf("DTB init completed\n");
ffffffffc0200558:	00001517          	auipc	a0,0x1
ffffffffc020055c:	3e050513          	addi	a0,a0,992 # ffffffffc0201938 <etext+0x248>
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
    list_init(&free_list);//初始化双向链表
    nr_free = 0;//初始化空闲页计数器 
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
ffffffffc02005a6:	c14d                	beqz	a0,ffffffffc0200648 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc02005a8:	00006697          	auipc	a3,0x6
ffffffffc02005ac:	a7068693          	addi	a3,a3,-1424 # ffffffffc0206018 <edata>
ffffffffc02005b0:	0106a803          	lw	a6,16(a3)
ffffffffc02005b4:	862a                	mv	a2,a0
ffffffffc02005b6:	02081793          	slli	a5,a6,0x20
ffffffffc02005ba:	9381                	srli	a5,a5,0x20
ffffffffc02005bc:	08a7e463          	bltu	a5,a0,ffffffffc0200644 <best_fit_alloc_pages+0x9e>
    size_t min_size = nr_free + 1;
ffffffffc02005c0:	0018059b          	addiw	a1,a6,1
ffffffffc02005c4:	1582                	slli	a1,a1,0x20
ffffffffc02005c6:	9181                	srli	a1,a1,0x20
    list_entry_t *le = &free_list;
ffffffffc02005c8:	87b6                	mv	a5,a3
    struct Page *page = NULL;
ffffffffc02005ca:	4501                	li	a0,0
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02005cc:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ce:	02d78263          	beq	a5,a3,ffffffffc02005f2 <best_fit_alloc_pages+0x4c>
        if (PageProperty(p) && p->property >= n) {// 若当前块大小 >= 需求（满足分配条件）
ffffffffc02005d2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02005d6:	8b09                	andi	a4,a4,2
ffffffffc02005d8:	db75                	beqz	a4,ffffffffc02005cc <best_fit_alloc_pages+0x26>
ffffffffc02005da:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02005de:	fec767e3          	bltu	a4,a2,ffffffffc02005cc <best_fit_alloc_pages+0x26>
            if (p->property < min_size) {// 若当前块是更小的满足条件的块（Best-Fit核心）
ffffffffc02005e2:	feb775e3          	bgeu	a4,a1,ffffffffc02005cc <best_fit_alloc_pages+0x26>
        struct Page *p = le2page(le, page_link);
ffffffffc02005e6:	fe878513          	addi	a0,a5,-24
ffffffffc02005ea:	679c                	ld	a5,8(a5)
ffffffffc02005ec:	85ba                	mv	a1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02005ee:	fed792e3          	bne	a5,a3,ffffffffc02005d2 <best_fit_alloc_pages+0x2c>
    if (page != NULL) {
ffffffffc02005f2:	c931                	beqz	a0,ffffffffc0200646 <best_fit_alloc_pages+0xa0>
        if (page->property > n) { // 若块大小 > 需求
ffffffffc02005f4:	490c                	lw	a1,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02005f6:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc02005f8:	7114                	ld	a3,32(a0)
ffffffffc02005fa:	02059793          	slli	a5,a1,0x20
ffffffffc02005fe:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200600:	e714                	sd	a3,8(a4)
    next->prev = prev;
ffffffffc0200602:	e298                	sd	a4,0(a3)
ffffffffc0200604:	0006089b          	sext.w	a7,a2
ffffffffc0200608:	02f67463          	bgeu	a2,a5,ffffffffc0200630 <best_fit_alloc_pages+0x8a>
            struct Page *p = page + n;
ffffffffc020060c:	00261793          	slli	a5,a2,0x2
ffffffffc0200610:	97b2                	add	a5,a5,a2
ffffffffc0200612:	078e                	slli	a5,a5,0x3
ffffffffc0200614:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200616:	6790                	ld	a2,8(a5)
            p->property = page->property - n;// 剩余块大小 = 原大小 - 分配大小
ffffffffc0200618:	411585bb          	subw	a1,a1,a7
ffffffffc020061c:	cb8c                	sw	a1,16(a5)
            SetPageProperty(p);
ffffffffc020061e:	00266613          	ori	a2,a2,2
ffffffffc0200622:	e790                	sd	a2,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200624:	01878613          	addi	a2,a5,24
    prev->next = next->prev = elm;
ffffffffc0200628:	e290                	sd	a2,0(a3)
ffffffffc020062a:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020062c:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc020062e:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc0200630:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc0200632:	4118083b          	subw	a6,a6,a7
ffffffffc0200636:	00006717          	auipc	a4,0x6
ffffffffc020063a:	9f072923          	sw	a6,-1550(a4) # ffffffffc0206028 <edata+0x10>
        ClearPageProperty(page);
ffffffffc020063e:	9bf5                	andi	a5,a5,-3
ffffffffc0200640:	e51c                	sd	a5,8(a0)
ffffffffc0200642:	8082                	ret
        return NULL;// 若需求页数超过系统总空闲页，无法分配
ffffffffc0200644:	4501                	li	a0,0
}
ffffffffc0200646:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200648:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020064a:	00001697          	auipc	a3,0x1
ffffffffc020064e:	30668693          	addi	a3,a3,774 # ffffffffc0201950 <etext+0x260>
ffffffffc0200652:	00001617          	auipc	a2,0x1
ffffffffc0200656:	30660613          	addi	a2,a2,774 # ffffffffc0201958 <etext+0x268>
ffffffffc020065a:	07100593          	li	a1,113
ffffffffc020065e:	00001517          	auipc	a0,0x1
ffffffffc0200662:	31250513          	addi	a0,a0,786 # ffffffffc0201970 <etext+0x280>
best_fit_alloc_pages(size_t n) {
ffffffffc0200666:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200668:	b5dff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc020066c <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc020066c:	715d                	addi	sp,sp,-80
ffffffffc020066e:	f84a                	sd	s2,48(sp)
    return listelm->next;
ffffffffc0200670:	00006917          	auipc	s2,0x6
ffffffffc0200674:	9a890913          	addi	s2,s2,-1624 # ffffffffc0206018 <edata>
ffffffffc0200678:	00893783          	ld	a5,8(s2)
ffffffffc020067c:	e486                	sd	ra,72(sp)
ffffffffc020067e:	e0a2                	sd	s0,64(sp)
ffffffffc0200680:	fc26                	sd	s1,56(sp)
ffffffffc0200682:	f44e                	sd	s3,40(sp)
ffffffffc0200684:	f052                	sd	s4,32(sp)
ffffffffc0200686:	ec56                	sd	s5,24(sp)
ffffffffc0200688:	e85a                	sd	s6,16(sp)
ffffffffc020068a:	e45e                	sd	s7,8(sp)
ffffffffc020068c:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020068e:	2d278063          	beq	a5,s2,ffffffffc020094e <best_fit_check+0x2e2>
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200692:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200696:	8b09                	andi	a4,a4,2
ffffffffc0200698:	2a070f63          	beqz	a4,ffffffffc0200956 <best_fit_check+0x2ea>
    int count = 0, total = 0;
ffffffffc020069c:	4401                	li	s0,0
ffffffffc020069e:	4481                	li	s1,0
ffffffffc02006a0:	a031                	j	ffffffffc02006ac <best_fit_check+0x40>
        assert(PageProperty(p));
ffffffffc02006a2:	ff07b703          	ld	a4,-16(a5)
ffffffffc02006a6:	8b09                	andi	a4,a4,2
ffffffffc02006a8:	2a070763          	beqz	a4,ffffffffc0200956 <best_fit_check+0x2ea>
        count ++, total += p->property;
ffffffffc02006ac:	ff87a703          	lw	a4,-8(a5)
ffffffffc02006b0:	679c                	ld	a5,8(a5)
ffffffffc02006b2:	2485                	addiw	s1,s1,1
ffffffffc02006b4:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc02006b6:	ff2796e3          	bne	a5,s2,ffffffffc02006a2 <best_fit_check+0x36>
ffffffffc02006ba:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc02006bc:	17f000ef          	jal	ra,ffffffffc020103a <nr_free_pages>
ffffffffc02006c0:	37351b63          	bne	a0,s3,ffffffffc0200a36 <best_fit_check+0x3ca>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02006c4:	4505                	li	a0,1
ffffffffc02006c6:	155000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02006ca:	8a2a                	mv	s4,a0
ffffffffc02006cc:	3a050563          	beqz	a0,ffffffffc0200a76 <best_fit_check+0x40a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006d0:	4505                	li	a0,1
ffffffffc02006d2:	149000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02006d6:	89aa                	mv	s3,a0
ffffffffc02006d8:	36050f63          	beqz	a0,ffffffffc0200a56 <best_fit_check+0x3ea>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006dc:	4505                	li	a0,1
ffffffffc02006de:	13d000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02006e2:	8aaa                	mv	s5,a0
ffffffffc02006e4:	30050963          	beqz	a0,ffffffffc02009f6 <best_fit_check+0x38a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02006e8:	293a0763          	beq	s4,s3,ffffffffc0200976 <best_fit_check+0x30a>
ffffffffc02006ec:	28aa0563          	beq	s4,a0,ffffffffc0200976 <best_fit_check+0x30a>
ffffffffc02006f0:	28a98363          	beq	s3,a0,ffffffffc0200976 <best_fit_check+0x30a>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02006f4:	000a2783          	lw	a5,0(s4)
ffffffffc02006f8:	28079f63          	bnez	a5,ffffffffc0200996 <best_fit_check+0x32a>
ffffffffc02006fc:	0009a783          	lw	a5,0(s3)
ffffffffc0200700:	28079b63          	bnez	a5,ffffffffc0200996 <best_fit_check+0x32a>
ffffffffc0200704:	411c                	lw	a5,0(a0)
ffffffffc0200706:	28079863          	bnez	a5,ffffffffc0200996 <best_fit_check+0x32a>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc020070a:	00006797          	auipc	a5,0x6
ffffffffc020070e:	96678793          	addi	a5,a5,-1690 # ffffffffc0206070 <pages>
ffffffffc0200712:	639c                	ld	a5,0(a5)
ffffffffc0200714:	00001717          	auipc	a4,0x1
ffffffffc0200718:	27470713          	addi	a4,a4,628 # ffffffffc0201988 <etext+0x298>
ffffffffc020071c:	630c                	ld	a1,0(a4)
ffffffffc020071e:	40fa0733          	sub	a4,s4,a5
ffffffffc0200722:	870d                	srai	a4,a4,0x3
ffffffffc0200724:	02b70733          	mul	a4,a4,a1
ffffffffc0200728:	00002697          	auipc	a3,0x2
ffffffffc020072c:	94068693          	addi	a3,a3,-1728 # ffffffffc0202068 <nbase>
ffffffffc0200730:	6290                	ld	a2,0(a3)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200732:	00006697          	auipc	a3,0x6
ffffffffc0200736:	91668693          	addi	a3,a3,-1770 # ffffffffc0206048 <npage>
ffffffffc020073a:	6294                	ld	a3,0(a3)
ffffffffc020073c:	06b2                	slli	a3,a3,0xc
ffffffffc020073e:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200740:	0732                	slli	a4,a4,0xc
ffffffffc0200742:	26d77a63          	bgeu	a4,a3,ffffffffc02009b6 <best_fit_check+0x34a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200746:	40f98733          	sub	a4,s3,a5
ffffffffc020074a:	870d                	srai	a4,a4,0x3
ffffffffc020074c:	02b70733          	mul	a4,a4,a1
ffffffffc0200750:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200752:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200754:	42d77163          	bgeu	a4,a3,ffffffffc0200b76 <best_fit_check+0x50a>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200758:	40f507b3          	sub	a5,a0,a5
ffffffffc020075c:	878d                	srai	a5,a5,0x3
ffffffffc020075e:	02b787b3          	mul	a5,a5,a1
ffffffffc0200762:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200764:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200766:	3ed7f863          	bgeu	a5,a3,ffffffffc0200b56 <best_fit_check+0x4ea>
    assert(alloc_page() == NULL);
ffffffffc020076a:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020076c:	00093c03          	ld	s8,0(s2)
ffffffffc0200770:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200774:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200778:	00006797          	auipc	a5,0x6
ffffffffc020077c:	8b27b423          	sd	s2,-1880(a5) # ffffffffc0206020 <edata+0x8>
ffffffffc0200780:	00006797          	auipc	a5,0x6
ffffffffc0200784:	8927bc23          	sd	s2,-1896(a5) # ffffffffc0206018 <edata>
    nr_free = 0;
ffffffffc0200788:	00006797          	auipc	a5,0x6
ffffffffc020078c:	8a07a023          	sw	zero,-1888(a5) # ffffffffc0206028 <edata+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200790:	08b000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc0200794:	3a051163          	bnez	a0,ffffffffc0200b36 <best_fit_check+0x4ca>
    free_page(p0);
ffffffffc0200798:	4585                	li	a1,1
ffffffffc020079a:	8552                	mv	a0,s4
ffffffffc020079c:	08f000ef          	jal	ra,ffffffffc020102a <free_pages>
    free_page(p1);
ffffffffc02007a0:	4585                	li	a1,1
ffffffffc02007a2:	854e                	mv	a0,s3
ffffffffc02007a4:	087000ef          	jal	ra,ffffffffc020102a <free_pages>
    free_page(p2);
ffffffffc02007a8:	4585                	li	a1,1
ffffffffc02007aa:	8556                	mv	a0,s5
ffffffffc02007ac:	07f000ef          	jal	ra,ffffffffc020102a <free_pages>
    assert(nr_free == 3);
ffffffffc02007b0:	01092703          	lw	a4,16(s2)
ffffffffc02007b4:	478d                	li	a5,3
ffffffffc02007b6:	36f71063          	bne	a4,a5,ffffffffc0200b16 <best_fit_check+0x4aa>
    assert((p0 = alloc_page()) != NULL);
ffffffffc02007ba:	4505                	li	a0,1
ffffffffc02007bc:	05f000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02007c0:	89aa                	mv	s3,a0
ffffffffc02007c2:	32050a63          	beqz	a0,ffffffffc0200af6 <best_fit_check+0x48a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02007c6:	4505                	li	a0,1
ffffffffc02007c8:	053000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02007cc:	8aaa                	mv	s5,a0
ffffffffc02007ce:	30050463          	beqz	a0,ffffffffc0200ad6 <best_fit_check+0x46a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02007d2:	4505                	li	a0,1
ffffffffc02007d4:	047000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02007d8:	8a2a                	mv	s4,a0
ffffffffc02007da:	2c050e63          	beqz	a0,ffffffffc0200ab6 <best_fit_check+0x44a>
    assert(alloc_page() == NULL);
ffffffffc02007de:	4505                	li	a0,1
ffffffffc02007e0:	03b000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02007e4:	2a051963          	bnez	a0,ffffffffc0200a96 <best_fit_check+0x42a>
    free_page(p0);
ffffffffc02007e8:	4585                	li	a1,1
ffffffffc02007ea:	854e                	mv	a0,s3
ffffffffc02007ec:	03f000ef          	jal	ra,ffffffffc020102a <free_pages>
    assert(!list_empty(&free_list));
ffffffffc02007f0:	00893783          	ld	a5,8(s2)
ffffffffc02007f4:	1f278163          	beq	a5,s2,ffffffffc02009d6 <best_fit_check+0x36a>
    assert((p = alloc_page()) == p0);
ffffffffc02007f8:	4505                	li	a0,1
ffffffffc02007fa:	021000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02007fe:	54a99c63          	bne	s3,a0,ffffffffc0200d56 <best_fit_check+0x6ea>
    assert(alloc_page() == NULL);
ffffffffc0200802:	4505                	li	a0,1
ffffffffc0200804:	017000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc0200808:	52051763          	bnez	a0,ffffffffc0200d36 <best_fit_check+0x6ca>
    assert(nr_free == 0);
ffffffffc020080c:	01092783          	lw	a5,16(s2)
ffffffffc0200810:	50079363          	bnez	a5,ffffffffc0200d16 <best_fit_check+0x6aa>
    free_page(p);
ffffffffc0200814:	854e                	mv	a0,s3
ffffffffc0200816:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200818:	00006797          	auipc	a5,0x6
ffffffffc020081c:	8187b023          	sd	s8,-2048(a5) # ffffffffc0206018 <edata>
ffffffffc0200820:	00006797          	auipc	a5,0x6
ffffffffc0200824:	8177b023          	sd	s7,-2048(a5) # ffffffffc0206020 <edata+0x8>
    nr_free = nr_free_store;
ffffffffc0200828:	00006797          	auipc	a5,0x6
ffffffffc020082c:	8167a023          	sw	s6,-2048(a5) # ffffffffc0206028 <edata+0x10>
    free_page(p);
ffffffffc0200830:	7fa000ef          	jal	ra,ffffffffc020102a <free_pages>
    free_page(p1);
ffffffffc0200834:	4585                	li	a1,1
ffffffffc0200836:	8556                	mv	a0,s5
ffffffffc0200838:	7f2000ef          	jal	ra,ffffffffc020102a <free_pages>
    free_page(p2);
ffffffffc020083c:	4585                	li	a1,1
ffffffffc020083e:	8552                	mv	a0,s4
ffffffffc0200840:	7ea000ef          	jal	ra,ffffffffc020102a <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200844:	4515                	li	a0,5
ffffffffc0200846:	7d4000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc020084a:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020084c:	4a050563          	beqz	a0,ffffffffc0200cf6 <best_fit_check+0x68a>
    assert(!PageProperty(p0));
ffffffffc0200850:	651c                	ld	a5,8(a0)
ffffffffc0200852:	8b89                	andi	a5,a5,2
ffffffffc0200854:	48079163          	bnez	a5,ffffffffc0200cd6 <best_fit_check+0x66a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200858:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020085a:	00093b83          	ld	s7,0(s2)
ffffffffc020085e:	00893b03          	ld	s6,8(s2)
ffffffffc0200862:	00005797          	auipc	a5,0x5
ffffffffc0200866:	7b27bb23          	sd	s2,1974(a5) # ffffffffc0206018 <edata>
ffffffffc020086a:	00005797          	auipc	a5,0x5
ffffffffc020086e:	7b27bb23          	sd	s2,1974(a5) # ffffffffc0206020 <edata+0x8>
    assert(alloc_page() == NULL);
ffffffffc0200872:	7a8000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc0200876:	44051063          	bnez	a0,ffffffffc0200cb6 <best_fit_check+0x64a>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc020087a:	4589                	li	a1,2
ffffffffc020087c:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200880:	01092c03          	lw	s8,16(s2)
    free_pages(p0 + 4, 1);
ffffffffc0200884:	0a098a93          	addi	s5,s3,160
    nr_free = 0;
ffffffffc0200888:	00005797          	auipc	a5,0x5
ffffffffc020088c:	7a07a023          	sw	zero,1952(a5) # ffffffffc0206028 <edata+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200890:	79a000ef          	jal	ra,ffffffffc020102a <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200894:	8556                	mv	a0,s5
ffffffffc0200896:	4585                	li	a1,1
ffffffffc0200898:	792000ef          	jal	ra,ffffffffc020102a <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc020089c:	4511                	li	a0,4
ffffffffc020089e:	77c000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02008a2:	3e051a63          	bnez	a0,ffffffffc0200c96 <best_fit_check+0x62a>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02008a6:	0309b783          	ld	a5,48(s3)
ffffffffc02008aa:	8b89                	andi	a5,a5,2
ffffffffc02008ac:	3c078563          	beqz	a5,ffffffffc0200c76 <best_fit_check+0x60a>
ffffffffc02008b0:	0389a703          	lw	a4,56(s3)
ffffffffc02008b4:	4789                	li	a5,2
ffffffffc02008b6:	3cf71063          	bne	a4,a5,ffffffffc0200c76 <best_fit_check+0x60a>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02008ba:	4505                	li	a0,1
ffffffffc02008bc:	75e000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02008c0:	8a2a                	mv	s4,a0
ffffffffc02008c2:	38050a63          	beqz	a0,ffffffffc0200c56 <best_fit_check+0x5ea>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02008c6:	4509                	li	a0,2
ffffffffc02008c8:	752000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02008cc:	36050563          	beqz	a0,ffffffffc0200c36 <best_fit_check+0x5ca>
    assert(p0 + 4 == p1);
ffffffffc02008d0:	354a9363          	bne	s5,s4,ffffffffc0200c16 <best_fit_check+0x5aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc02008d4:	854e                	mv	a0,s3
ffffffffc02008d6:	4595                	li	a1,5
ffffffffc02008d8:	752000ef          	jal	ra,ffffffffc020102a <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02008dc:	4515                	li	a0,5
ffffffffc02008de:	73c000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02008e2:	89aa                	mv	s3,a0
ffffffffc02008e4:	30050963          	beqz	a0,ffffffffc0200bf6 <best_fit_check+0x58a>
    assert(alloc_page() == NULL);
ffffffffc02008e8:	4505                	li	a0,1
ffffffffc02008ea:	730000ef          	jal	ra,ffffffffc020101a <alloc_pages>
ffffffffc02008ee:	2e051463          	bnez	a0,ffffffffc0200bd6 <best_fit_check+0x56a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc02008f2:	01092783          	lw	a5,16(s2)
ffffffffc02008f6:	2c079063          	bnez	a5,ffffffffc0200bb6 <best_fit_check+0x54a>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc02008fa:	4595                	li	a1,5
ffffffffc02008fc:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc02008fe:	00005797          	auipc	a5,0x5
ffffffffc0200902:	7387a523          	sw	s8,1834(a5) # ffffffffc0206028 <edata+0x10>
    free_list = free_list_store;
ffffffffc0200906:	00005797          	auipc	a5,0x5
ffffffffc020090a:	7177b923          	sd	s7,1810(a5) # ffffffffc0206018 <edata>
ffffffffc020090e:	00005797          	auipc	a5,0x5
ffffffffc0200912:	7167b923          	sd	s6,1810(a5) # ffffffffc0206020 <edata+0x8>
    free_pages(p0, 5);
ffffffffc0200916:	714000ef          	jal	ra,ffffffffc020102a <free_pages>
    return listelm->next;
ffffffffc020091a:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020091e:	01278963          	beq	a5,s2,ffffffffc0200930 <best_fit_check+0x2c4>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200922:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200926:	679c                	ld	a5,8(a5)
ffffffffc0200928:	34fd                	addiw	s1,s1,-1
ffffffffc020092a:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020092c:	ff279be3          	bne	a5,s2,ffffffffc0200922 <best_fit_check+0x2b6>
    }
    assert(count == 0);
ffffffffc0200930:	26049363          	bnez	s1,ffffffffc0200b96 <best_fit_check+0x52a>
    assert(total == 0);
ffffffffc0200934:	e06d                	bnez	s0,ffffffffc0200a16 <best_fit_check+0x3aa>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200936:	60a6                	ld	ra,72(sp)
ffffffffc0200938:	6406                	ld	s0,64(sp)
ffffffffc020093a:	74e2                	ld	s1,56(sp)
ffffffffc020093c:	7942                	ld	s2,48(sp)
ffffffffc020093e:	79a2                	ld	s3,40(sp)
ffffffffc0200940:	7a02                	ld	s4,32(sp)
ffffffffc0200942:	6ae2                	ld	s5,24(sp)
ffffffffc0200944:	6b42                	ld	s6,16(sp)
ffffffffc0200946:	6ba2                	ld	s7,8(sp)
ffffffffc0200948:	6c02                	ld	s8,0(sp)
ffffffffc020094a:	6161                	addi	sp,sp,80
ffffffffc020094c:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020094e:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200950:	4401                	li	s0,0
ffffffffc0200952:	4481                	li	s1,0
ffffffffc0200954:	b3a5                	j	ffffffffc02006bc <best_fit_check+0x50>
        assert(PageProperty(p));
ffffffffc0200956:	00001697          	auipc	a3,0x1
ffffffffc020095a:	03a68693          	addi	a3,a3,58 # ffffffffc0201990 <etext+0x2a0>
ffffffffc020095e:	00001617          	auipc	a2,0x1
ffffffffc0200962:	ffa60613          	addi	a2,a2,-6 # ffffffffc0201958 <etext+0x268>
ffffffffc0200966:	11700593          	li	a1,279
ffffffffc020096a:	00001517          	auipc	a0,0x1
ffffffffc020096e:	00650513          	addi	a0,a0,6 # ffffffffc0201970 <etext+0x280>
ffffffffc0200972:	853ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200976:	00001697          	auipc	a3,0x1
ffffffffc020097a:	0aa68693          	addi	a3,a3,170 # ffffffffc0201a20 <etext+0x330>
ffffffffc020097e:	00001617          	auipc	a2,0x1
ffffffffc0200982:	fda60613          	addi	a2,a2,-38 # ffffffffc0201958 <etext+0x268>
ffffffffc0200986:	0e300593          	li	a1,227
ffffffffc020098a:	00001517          	auipc	a0,0x1
ffffffffc020098e:	fe650513          	addi	a0,a0,-26 # ffffffffc0201970 <etext+0x280>
ffffffffc0200992:	833ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200996:	00001697          	auipc	a3,0x1
ffffffffc020099a:	0b268693          	addi	a3,a3,178 # ffffffffc0201a48 <etext+0x358>
ffffffffc020099e:	00001617          	auipc	a2,0x1
ffffffffc02009a2:	fba60613          	addi	a2,a2,-70 # ffffffffc0201958 <etext+0x268>
ffffffffc02009a6:	0e400593          	li	a1,228
ffffffffc02009aa:	00001517          	auipc	a0,0x1
ffffffffc02009ae:	fc650513          	addi	a0,a0,-58 # ffffffffc0201970 <etext+0x280>
ffffffffc02009b2:	813ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009b6:	00001697          	auipc	a3,0x1
ffffffffc02009ba:	0d268693          	addi	a3,a3,210 # ffffffffc0201a88 <etext+0x398>
ffffffffc02009be:	00001617          	auipc	a2,0x1
ffffffffc02009c2:	f9a60613          	addi	a2,a2,-102 # ffffffffc0201958 <etext+0x268>
ffffffffc02009c6:	0e600593          	li	a1,230
ffffffffc02009ca:	00001517          	auipc	a0,0x1
ffffffffc02009ce:	fa650513          	addi	a0,a0,-90 # ffffffffc0201970 <etext+0x280>
ffffffffc02009d2:	ff2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02009d6:	00001697          	auipc	a3,0x1
ffffffffc02009da:	13a68693          	addi	a3,a3,314 # ffffffffc0201b10 <etext+0x420>
ffffffffc02009de:	00001617          	auipc	a2,0x1
ffffffffc02009e2:	f7a60613          	addi	a2,a2,-134 # ffffffffc0201958 <etext+0x268>
ffffffffc02009e6:	0ff00593          	li	a1,255
ffffffffc02009ea:	00001517          	auipc	a0,0x1
ffffffffc02009ee:	f8650513          	addi	a0,a0,-122 # ffffffffc0201970 <etext+0x280>
ffffffffc02009f2:	fd2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009f6:	00001697          	auipc	a3,0x1
ffffffffc02009fa:	00a68693          	addi	a3,a3,10 # ffffffffc0201a00 <etext+0x310>
ffffffffc02009fe:	00001617          	auipc	a2,0x1
ffffffffc0200a02:	f5a60613          	addi	a2,a2,-166 # ffffffffc0201958 <etext+0x268>
ffffffffc0200a06:	0e100593          	li	a1,225
ffffffffc0200a0a:	00001517          	auipc	a0,0x1
ffffffffc0200a0e:	f6650513          	addi	a0,a0,-154 # ffffffffc0201970 <etext+0x280>
ffffffffc0200a12:	fb2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(total == 0);
ffffffffc0200a16:	00001697          	auipc	a3,0x1
ffffffffc0200a1a:	22a68693          	addi	a3,a3,554 # ffffffffc0201c40 <etext+0x550>
ffffffffc0200a1e:	00001617          	auipc	a2,0x1
ffffffffc0200a22:	f3a60613          	addi	a2,a2,-198 # ffffffffc0201958 <etext+0x268>
ffffffffc0200a26:	15900593          	li	a1,345
ffffffffc0200a2a:	00001517          	auipc	a0,0x1
ffffffffc0200a2e:	f4650513          	addi	a0,a0,-186 # ffffffffc0201970 <etext+0x280>
ffffffffc0200a32:	f92ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200a36:	00001697          	auipc	a3,0x1
ffffffffc0200a3a:	f6a68693          	addi	a3,a3,-150 # ffffffffc02019a0 <etext+0x2b0>
ffffffffc0200a3e:	00001617          	auipc	a2,0x1
ffffffffc0200a42:	f1a60613          	addi	a2,a2,-230 # ffffffffc0201958 <etext+0x268>
ffffffffc0200a46:	11a00593          	li	a1,282
ffffffffc0200a4a:	00001517          	auipc	a0,0x1
ffffffffc0200a4e:	f2650513          	addi	a0,a0,-218 # ffffffffc0201970 <etext+0x280>
ffffffffc0200a52:	f72ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a56:	00001697          	auipc	a3,0x1
ffffffffc0200a5a:	f8a68693          	addi	a3,a3,-118 # ffffffffc02019e0 <etext+0x2f0>
ffffffffc0200a5e:	00001617          	auipc	a2,0x1
ffffffffc0200a62:	efa60613          	addi	a2,a2,-262 # ffffffffc0201958 <etext+0x268>
ffffffffc0200a66:	0e000593          	li	a1,224
ffffffffc0200a6a:	00001517          	auipc	a0,0x1
ffffffffc0200a6e:	f0650513          	addi	a0,a0,-250 # ffffffffc0201970 <etext+0x280>
ffffffffc0200a72:	f52ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a76:	00001697          	auipc	a3,0x1
ffffffffc0200a7a:	f4a68693          	addi	a3,a3,-182 # ffffffffc02019c0 <etext+0x2d0>
ffffffffc0200a7e:	00001617          	auipc	a2,0x1
ffffffffc0200a82:	eda60613          	addi	a2,a2,-294 # ffffffffc0201958 <etext+0x268>
ffffffffc0200a86:	0df00593          	li	a1,223
ffffffffc0200a8a:	00001517          	auipc	a0,0x1
ffffffffc0200a8e:	ee650513          	addi	a0,a0,-282 # ffffffffc0201970 <etext+0x280>
ffffffffc0200a92:	f32ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200a96:	00001697          	auipc	a3,0x1
ffffffffc0200a9a:	05268693          	addi	a3,a3,82 # ffffffffc0201ae8 <etext+0x3f8>
ffffffffc0200a9e:	00001617          	auipc	a2,0x1
ffffffffc0200aa2:	eba60613          	addi	a2,a2,-326 # ffffffffc0201958 <etext+0x268>
ffffffffc0200aa6:	0fc00593          	li	a1,252
ffffffffc0200aaa:	00001517          	auipc	a0,0x1
ffffffffc0200aae:	ec650513          	addi	a0,a0,-314 # ffffffffc0201970 <etext+0x280>
ffffffffc0200ab2:	f12ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ab6:	00001697          	auipc	a3,0x1
ffffffffc0200aba:	f4a68693          	addi	a3,a3,-182 # ffffffffc0201a00 <etext+0x310>
ffffffffc0200abe:	00001617          	auipc	a2,0x1
ffffffffc0200ac2:	e9a60613          	addi	a2,a2,-358 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ac6:	0fa00593          	li	a1,250
ffffffffc0200aca:	00001517          	auipc	a0,0x1
ffffffffc0200ace:	ea650513          	addi	a0,a0,-346 # ffffffffc0201970 <etext+0x280>
ffffffffc0200ad2:	ef2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ad6:	00001697          	auipc	a3,0x1
ffffffffc0200ada:	f0a68693          	addi	a3,a3,-246 # ffffffffc02019e0 <etext+0x2f0>
ffffffffc0200ade:	00001617          	auipc	a2,0x1
ffffffffc0200ae2:	e7a60613          	addi	a2,a2,-390 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ae6:	0f900593          	li	a1,249
ffffffffc0200aea:	00001517          	auipc	a0,0x1
ffffffffc0200aee:	e8650513          	addi	a0,a0,-378 # ffffffffc0201970 <etext+0x280>
ffffffffc0200af2:	ed2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200af6:	00001697          	auipc	a3,0x1
ffffffffc0200afa:	eca68693          	addi	a3,a3,-310 # ffffffffc02019c0 <etext+0x2d0>
ffffffffc0200afe:	00001617          	auipc	a2,0x1
ffffffffc0200b02:	e5a60613          	addi	a2,a2,-422 # ffffffffc0201958 <etext+0x268>
ffffffffc0200b06:	0f800593          	li	a1,248
ffffffffc0200b0a:	00001517          	auipc	a0,0x1
ffffffffc0200b0e:	e6650513          	addi	a0,a0,-410 # ffffffffc0201970 <etext+0x280>
ffffffffc0200b12:	eb2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 3);
ffffffffc0200b16:	00001697          	auipc	a3,0x1
ffffffffc0200b1a:	fea68693          	addi	a3,a3,-22 # ffffffffc0201b00 <etext+0x410>
ffffffffc0200b1e:	00001617          	auipc	a2,0x1
ffffffffc0200b22:	e3a60613          	addi	a2,a2,-454 # ffffffffc0201958 <etext+0x268>
ffffffffc0200b26:	0f600593          	li	a1,246
ffffffffc0200b2a:	00001517          	auipc	a0,0x1
ffffffffc0200b2e:	e4650513          	addi	a0,a0,-442 # ffffffffc0201970 <etext+0x280>
ffffffffc0200b32:	e92ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200b36:	00001697          	auipc	a3,0x1
ffffffffc0200b3a:	fb268693          	addi	a3,a3,-78 # ffffffffc0201ae8 <etext+0x3f8>
ffffffffc0200b3e:	00001617          	auipc	a2,0x1
ffffffffc0200b42:	e1a60613          	addi	a2,a2,-486 # ffffffffc0201958 <etext+0x268>
ffffffffc0200b46:	0f100593          	li	a1,241
ffffffffc0200b4a:	00001517          	auipc	a0,0x1
ffffffffc0200b4e:	e2650513          	addi	a0,a0,-474 # ffffffffc0201970 <etext+0x280>
ffffffffc0200b52:	e72ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200b56:	00001697          	auipc	a3,0x1
ffffffffc0200b5a:	f7268693          	addi	a3,a3,-142 # ffffffffc0201ac8 <etext+0x3d8>
ffffffffc0200b5e:	00001617          	auipc	a2,0x1
ffffffffc0200b62:	dfa60613          	addi	a2,a2,-518 # ffffffffc0201958 <etext+0x268>
ffffffffc0200b66:	0e800593          	li	a1,232
ffffffffc0200b6a:	00001517          	auipc	a0,0x1
ffffffffc0200b6e:	e0650513          	addi	a0,a0,-506 # ffffffffc0201970 <etext+0x280>
ffffffffc0200b72:	e52ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200b76:	00001697          	auipc	a3,0x1
ffffffffc0200b7a:	f3268693          	addi	a3,a3,-206 # ffffffffc0201aa8 <etext+0x3b8>
ffffffffc0200b7e:	00001617          	auipc	a2,0x1
ffffffffc0200b82:	dda60613          	addi	a2,a2,-550 # ffffffffc0201958 <etext+0x268>
ffffffffc0200b86:	0e700593          	li	a1,231
ffffffffc0200b8a:	00001517          	auipc	a0,0x1
ffffffffc0200b8e:	de650513          	addi	a0,a0,-538 # ffffffffc0201970 <etext+0x280>
ffffffffc0200b92:	e32ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(count == 0);
ffffffffc0200b96:	00001697          	auipc	a3,0x1
ffffffffc0200b9a:	09a68693          	addi	a3,a3,154 # ffffffffc0201c30 <etext+0x540>
ffffffffc0200b9e:	00001617          	auipc	a2,0x1
ffffffffc0200ba2:	dba60613          	addi	a2,a2,-582 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ba6:	15800593          	li	a1,344
ffffffffc0200baa:	00001517          	auipc	a0,0x1
ffffffffc0200bae:	dc650513          	addi	a0,a0,-570 # ffffffffc0201970 <etext+0x280>
ffffffffc0200bb2:	e12ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 0);
ffffffffc0200bb6:	00001697          	auipc	a3,0x1
ffffffffc0200bba:	f9268693          	addi	a3,a3,-110 # ffffffffc0201b48 <etext+0x458>
ffffffffc0200bbe:	00001617          	auipc	a2,0x1
ffffffffc0200bc2:	d9a60613          	addi	a2,a2,-614 # ffffffffc0201958 <etext+0x268>
ffffffffc0200bc6:	14d00593          	li	a1,333
ffffffffc0200bca:	00001517          	auipc	a0,0x1
ffffffffc0200bce:	da650513          	addi	a0,a0,-602 # ffffffffc0201970 <etext+0x280>
ffffffffc0200bd2:	df2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200bd6:	00001697          	auipc	a3,0x1
ffffffffc0200bda:	f1268693          	addi	a3,a3,-238 # ffffffffc0201ae8 <etext+0x3f8>
ffffffffc0200bde:	00001617          	auipc	a2,0x1
ffffffffc0200be2:	d7a60613          	addi	a2,a2,-646 # ffffffffc0201958 <etext+0x268>
ffffffffc0200be6:	14700593          	li	a1,327
ffffffffc0200bea:	00001517          	auipc	a0,0x1
ffffffffc0200bee:	d8650513          	addi	a0,a0,-634 # ffffffffc0201970 <etext+0x280>
ffffffffc0200bf2:	dd2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200bf6:	00001697          	auipc	a3,0x1
ffffffffc0200bfa:	01a68693          	addi	a3,a3,26 # ffffffffc0201c10 <etext+0x520>
ffffffffc0200bfe:	00001617          	auipc	a2,0x1
ffffffffc0200c02:	d5a60613          	addi	a2,a2,-678 # ffffffffc0201958 <etext+0x268>
ffffffffc0200c06:	14600593          	li	a1,326
ffffffffc0200c0a:	00001517          	auipc	a0,0x1
ffffffffc0200c0e:	d6650513          	addi	a0,a0,-666 # ffffffffc0201970 <etext+0x280>
ffffffffc0200c12:	db2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200c16:	00001697          	auipc	a3,0x1
ffffffffc0200c1a:	fea68693          	addi	a3,a3,-22 # ffffffffc0201c00 <etext+0x510>
ffffffffc0200c1e:	00001617          	auipc	a2,0x1
ffffffffc0200c22:	d3a60613          	addi	a2,a2,-710 # ffffffffc0201958 <etext+0x268>
ffffffffc0200c26:	13e00593          	li	a1,318
ffffffffc0200c2a:	00001517          	auipc	a0,0x1
ffffffffc0200c2e:	d4650513          	addi	a0,a0,-698 # ffffffffc0201970 <etext+0x280>
ffffffffc0200c32:	d92ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200c36:	00001697          	auipc	a3,0x1
ffffffffc0200c3a:	fb268693          	addi	a3,a3,-78 # ffffffffc0201be8 <etext+0x4f8>
ffffffffc0200c3e:	00001617          	auipc	a2,0x1
ffffffffc0200c42:	d1a60613          	addi	a2,a2,-742 # ffffffffc0201958 <etext+0x268>
ffffffffc0200c46:	13d00593          	li	a1,317
ffffffffc0200c4a:	00001517          	auipc	a0,0x1
ffffffffc0200c4e:	d2650513          	addi	a0,a0,-730 # ffffffffc0201970 <etext+0x280>
ffffffffc0200c52:	d72ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200c56:	00001697          	auipc	a3,0x1
ffffffffc0200c5a:	f7268693          	addi	a3,a3,-142 # ffffffffc0201bc8 <etext+0x4d8>
ffffffffc0200c5e:	00001617          	auipc	a2,0x1
ffffffffc0200c62:	cfa60613          	addi	a2,a2,-774 # ffffffffc0201958 <etext+0x268>
ffffffffc0200c66:	13c00593          	li	a1,316
ffffffffc0200c6a:	00001517          	auipc	a0,0x1
ffffffffc0200c6e:	d0650513          	addi	a0,a0,-762 # ffffffffc0201970 <etext+0x280>
ffffffffc0200c72:	d52ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200c76:	00001697          	auipc	a3,0x1
ffffffffc0200c7a:	f2268693          	addi	a3,a3,-222 # ffffffffc0201b98 <etext+0x4a8>
ffffffffc0200c7e:	00001617          	auipc	a2,0x1
ffffffffc0200c82:	cda60613          	addi	a2,a2,-806 # ffffffffc0201958 <etext+0x268>
ffffffffc0200c86:	13a00593          	li	a1,314
ffffffffc0200c8a:	00001517          	auipc	a0,0x1
ffffffffc0200c8e:	ce650513          	addi	a0,a0,-794 # ffffffffc0201970 <etext+0x280>
ffffffffc0200c92:	d32ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200c96:	00001697          	auipc	a3,0x1
ffffffffc0200c9a:	eea68693          	addi	a3,a3,-278 # ffffffffc0201b80 <etext+0x490>
ffffffffc0200c9e:	00001617          	auipc	a2,0x1
ffffffffc0200ca2:	cba60613          	addi	a2,a2,-838 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ca6:	13900593          	li	a1,313
ffffffffc0200caa:	00001517          	auipc	a0,0x1
ffffffffc0200cae:	cc650513          	addi	a0,a0,-826 # ffffffffc0201970 <etext+0x280>
ffffffffc0200cb2:	d12ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200cb6:	00001697          	auipc	a3,0x1
ffffffffc0200cba:	e3268693          	addi	a3,a3,-462 # ffffffffc0201ae8 <etext+0x3f8>
ffffffffc0200cbe:	00001617          	auipc	a2,0x1
ffffffffc0200cc2:	c9a60613          	addi	a2,a2,-870 # ffffffffc0201958 <etext+0x268>
ffffffffc0200cc6:	12d00593          	li	a1,301
ffffffffc0200cca:	00001517          	auipc	a0,0x1
ffffffffc0200cce:	ca650513          	addi	a0,a0,-858 # ffffffffc0201970 <etext+0x280>
ffffffffc0200cd2:	cf2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200cd6:	00001697          	auipc	a3,0x1
ffffffffc0200cda:	e9268693          	addi	a3,a3,-366 # ffffffffc0201b68 <etext+0x478>
ffffffffc0200cde:	00001617          	auipc	a2,0x1
ffffffffc0200ce2:	c7a60613          	addi	a2,a2,-902 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ce6:	12400593          	li	a1,292
ffffffffc0200cea:	00001517          	auipc	a0,0x1
ffffffffc0200cee:	c8650513          	addi	a0,a0,-890 # ffffffffc0201970 <etext+0x280>
ffffffffc0200cf2:	cd2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(p0 != NULL);
ffffffffc0200cf6:	00001697          	auipc	a3,0x1
ffffffffc0200cfa:	e6268693          	addi	a3,a3,-414 # ffffffffc0201b58 <etext+0x468>
ffffffffc0200cfe:	00001617          	auipc	a2,0x1
ffffffffc0200d02:	c5a60613          	addi	a2,a2,-934 # ffffffffc0201958 <etext+0x268>
ffffffffc0200d06:	12300593          	li	a1,291
ffffffffc0200d0a:	00001517          	auipc	a0,0x1
ffffffffc0200d0e:	c6650513          	addi	a0,a0,-922 # ffffffffc0201970 <etext+0x280>
ffffffffc0200d12:	cb2ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(nr_free == 0);
ffffffffc0200d16:	00001697          	auipc	a3,0x1
ffffffffc0200d1a:	e3268693          	addi	a3,a3,-462 # ffffffffc0201b48 <etext+0x458>
ffffffffc0200d1e:	00001617          	auipc	a2,0x1
ffffffffc0200d22:	c3a60613          	addi	a2,a2,-966 # ffffffffc0201958 <etext+0x268>
ffffffffc0200d26:	10500593          	li	a1,261
ffffffffc0200d2a:	00001517          	auipc	a0,0x1
ffffffffc0200d2e:	c4650513          	addi	a0,a0,-954 # ffffffffc0201970 <etext+0x280>
ffffffffc0200d32:	c92ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d36:	00001697          	auipc	a3,0x1
ffffffffc0200d3a:	db268693          	addi	a3,a3,-590 # ffffffffc0201ae8 <etext+0x3f8>
ffffffffc0200d3e:	00001617          	auipc	a2,0x1
ffffffffc0200d42:	c1a60613          	addi	a2,a2,-998 # ffffffffc0201958 <etext+0x268>
ffffffffc0200d46:	10300593          	li	a1,259
ffffffffc0200d4a:	00001517          	auipc	a0,0x1
ffffffffc0200d4e:	c2650513          	addi	a0,a0,-986 # ffffffffc0201970 <etext+0x280>
ffffffffc0200d52:	c72ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200d56:	00001697          	auipc	a3,0x1
ffffffffc0200d5a:	dd268693          	addi	a3,a3,-558 # ffffffffc0201b28 <etext+0x438>
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0201958 <etext+0x268>
ffffffffc0200d66:	10200593          	li	a1,258
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	c0650513          	addi	a0,a0,-1018 # ffffffffc0201970 <etext+0x280>
ffffffffc0200d72:	c52ff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0200d76 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200d76:	1141                	addi	sp,sp,-16
ffffffffc0200d78:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200d7a:	16058b63          	beqz	a1,ffffffffc0200ef0 <best_fit_free_pages+0x17a>
    for (; p != base + n; p ++) {
ffffffffc0200d7e:	00259693          	slli	a3,a1,0x2
ffffffffc0200d82:	96ae                	add	a3,a3,a1
ffffffffc0200d84:	068e                	slli	a3,a3,0x3
ffffffffc0200d86:	96aa                	add	a3,a3,a0
ffffffffc0200d88:	6510                	ld	a2,8(a0)
ffffffffc0200d8a:	02d50363          	beq	a0,a3,ffffffffc0200db0 <best_fit_free_pages+0x3a>
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页不是预留状态，且不是空闲块起始页（必为已分配页）
ffffffffc0200d8e:	8a0d                	andi	a2,a2,3
ffffffffc0200d90:	87aa                	mv	a5,a0
ffffffffc0200d92:	c611                	beqz	a2,ffffffffc0200d9e <best_fit_free_pages+0x28>
ffffffffc0200d94:	aa35                	j	ffffffffc0200ed0 <best_fit_free_pages+0x15a>
ffffffffc0200d96:	6798                	ld	a4,8(a5)
ffffffffc0200d98:	8b0d                	andi	a4,a4,3
ffffffffc0200d9a:	12071b63          	bnez	a4,ffffffffc0200ed0 <best_fit_free_pages+0x15a>
        p->flags = 0;
ffffffffc0200d9e:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0200da2:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200da6:	02878793          	addi	a5,a5,40
ffffffffc0200daa:	fed796e3          	bne	a5,a3,ffffffffc0200d96 <best_fit_free_pages+0x20>
ffffffffc0200dae:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200db0:	00005697          	auipc	a3,0x5
ffffffffc0200db4:	26868693          	addi	a3,a3,616 # ffffffffc0206018 <edata>
ffffffffc0200db8:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200dba:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200dbc:	00266813          	ori	a6,a2,2
    return list->next == list;
ffffffffc0200dc0:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200dc2:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200dc4:	01053423          	sd	a6,8(a0)
    nr_free += n;
ffffffffc0200dc8:	9f2d                	addw	a4,a4,a1
ffffffffc0200dca:	00005817          	auipc	a6,0x5
ffffffffc0200dce:	24e82f23          	sw	a4,606(a6) # ffffffffc0206028 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc0200dd2:	0ad78763          	beq	a5,a3,ffffffffc0200e80 <best_fit_free_pages+0x10a>
            struct Page *page = le2page(le, page_link);
ffffffffc0200dd6:	fe878713          	addi	a4,a5,-24
ffffffffc0200dda:	0006b883          	ld	a7,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200dde:	4301                	li	t1,0
ffffffffc0200de0:	01850813          	addi	a6,a0,24
            if (base < page) {// 找到第一个地址更大的块，插入其前方
ffffffffc0200de4:	00e56a63          	bltu	a0,a4,ffffffffc0200df8 <best_fit_free_pages+0x82>
    return listelm->next;
ffffffffc0200de8:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {// 遍历到尾部，插入尾部
ffffffffc0200dea:	02d70963          	beq	a4,a3,ffffffffc0200e1c <best_fit_free_pages+0xa6>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200dee:	87ba                	mv	a5,a4
            struct Page *page = le2page(le, page_link);
ffffffffc0200df0:	fe878713          	addi	a4,a5,-24
            if (base < page) {// 找到第一个地址更大的块，插入其前方
ffffffffc0200df4:	fee57ae3          	bgeu	a0,a4,ffffffffc0200de8 <best_fit_free_pages+0x72>
ffffffffc0200df8:	00030663          	beqz	t1,ffffffffc0200e04 <best_fit_free_pages+0x8e>
ffffffffc0200dfc:	00005317          	auipc	t1,0x5
ffffffffc0200e00:	21133e23          	sd	a7,540(t1) # ffffffffc0206018 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200e04:	0007b883          	ld	a7,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200e08:	0107b023          	sd	a6,0(a5)
ffffffffc0200e0c:	0108b423          	sd	a6,8(a7) # ff0008 <BASE_ADDRESS-0xffffffffbf20fff8>
    elm->next = next;
ffffffffc0200e10:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e12:	01153c23          	sd	a7,24(a0)
    if (le != &free_list) {
ffffffffc0200e16:	02d89463          	bne	a7,a3,ffffffffc0200e3e <best_fit_free_pages+0xc8>
ffffffffc0200e1a:	a0a9                	j	ffffffffc0200e64 <best_fit_free_pages+0xee>
    prev->next = next->prev = elm;
ffffffffc0200e1c:	0107b423          	sd	a6,8(a5)
    elm->next = next;
ffffffffc0200e20:	f114                	sd	a3,32(a0)
ffffffffc0200e22:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200e24:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200e26:	88c2                	mv	a7,a6
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200e28:	00d70563          	beq	a4,a3,ffffffffc0200e32 <best_fit_free_pages+0xbc>
ffffffffc0200e2c:	4305                	li	t1,1
ffffffffc0200e2e:	87ba                	mv	a5,a4
ffffffffc0200e30:	b7c1                	j	ffffffffc0200df0 <best_fit_free_pages+0x7a>
    return listelm->prev;
ffffffffc0200e32:	88be                	mv	a7,a5
ffffffffc0200e34:	0106b023          	sd	a6,0(a3)
    if (le != &free_list) {
ffffffffc0200e38:	87b6                	mv	a5,a3
ffffffffc0200e3a:	02d88163          	beq	a7,a3,ffffffffc0200e5c <best_fit_free_pages+0xe6>
        if (p + p->property == base) {
ffffffffc0200e3e:	ff88ae03          	lw	t3,-8(a7)
        p = le2page(le, page_link);
ffffffffc0200e42:	fe888313          	addi	t1,a7,-24
        if (p + p->property == base) {
ffffffffc0200e46:	020e1813          	slli	a6,t3,0x20
ffffffffc0200e4a:	02085813          	srli	a6,a6,0x20
ffffffffc0200e4e:	00281713          	slli	a4,a6,0x2
ffffffffc0200e52:	9742                	add	a4,a4,a6
ffffffffc0200e54:	070e                	slli	a4,a4,0x3
ffffffffc0200e56:	971a                	add	a4,a4,t1
ffffffffc0200e58:	02e50d63          	beq	a0,a4,ffffffffc0200e92 <best_fit_free_pages+0x11c>
    if (le != &free_list) {
ffffffffc0200e5c:	fe878713          	addi	a4,a5,-24
ffffffffc0200e60:	00d78d63          	beq	a5,a3,ffffffffc0200e7a <best_fit_free_pages+0x104>
        if (base + base->property == p) {
ffffffffc0200e64:	490c                	lw	a1,16(a0)
ffffffffc0200e66:	02059613          	slli	a2,a1,0x20
ffffffffc0200e6a:	9201                	srli	a2,a2,0x20
ffffffffc0200e6c:	00261693          	slli	a3,a2,0x2
ffffffffc0200e70:	96b2                	add	a3,a3,a2
ffffffffc0200e72:	068e                	slli	a3,a3,0x3
ffffffffc0200e74:	96aa                	add	a3,a3,a0
ffffffffc0200e76:	02d70a63          	beq	a4,a3,ffffffffc0200eaa <best_fit_free_pages+0x134>
}
ffffffffc0200e7a:	60a2                	ld	ra,8(sp)
ffffffffc0200e7c:	0141                	addi	sp,sp,16
ffffffffc0200e7e:	8082                	ret
ffffffffc0200e80:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200e82:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200e86:	e398                	sd	a4,0(a5)
ffffffffc0200e88:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200e8a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200e8c:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200e8e:	0141                	addi	sp,sp,16
ffffffffc0200e90:	8082                	ret
            p->property += base->property;
ffffffffc0200e92:	01c585bb          	addw	a1,a1,t3
ffffffffc0200e96:	feb8ac23          	sw	a1,-8(a7)
            ClearPageProperty(base);
ffffffffc0200e9a:	9a75                	andi	a2,a2,-3
ffffffffc0200e9c:	e510                	sd	a2,8(a0)
    prev->next = next;
ffffffffc0200e9e:	00f8b423          	sd	a5,8(a7)
    next->prev = prev;
ffffffffc0200ea2:	0117b023          	sd	a7,0(a5)
            base = p;  // 更新base指针，以便继续检查后面的块
ffffffffc0200ea6:	851a                	mv	a0,t1
ffffffffc0200ea8:	bf55                	j	ffffffffc0200e5c <best_fit_free_pages+0xe6>
            base->property += p->property;
ffffffffc0200eaa:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200eae:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200eb2:	0007b803          	ld	a6,0(a5)
ffffffffc0200eb6:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200eb8:	9db5                	addw	a1,a1,a3
ffffffffc0200eba:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200ebc:	9b75                	andi	a4,a4,-3
ffffffffc0200ebe:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200ec2:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200ec4:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200ec8:	01063023          	sd	a6,0(a2)
ffffffffc0200ecc:	0141                	addi	sp,sp,16
ffffffffc0200ece:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p)); // 确保页不是预留状态，且不是空闲块起始页（必为已分配页）
ffffffffc0200ed0:	00001697          	auipc	a3,0x1
ffffffffc0200ed4:	d8068693          	addi	a3,a3,-640 # ffffffffc0201c50 <etext+0x560>
ffffffffc0200ed8:	00001617          	auipc	a2,0x1
ffffffffc0200edc:	a8060613          	addi	a2,a2,-1408 # ffffffffc0201958 <etext+0x268>
ffffffffc0200ee0:	09e00593          	li	a1,158
ffffffffc0200ee4:	00001517          	auipc	a0,0x1
ffffffffc0200ee8:	a8c50513          	addi	a0,a0,-1396 # ffffffffc0201970 <etext+0x280>
ffffffffc0200eec:	ad8ff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(n > 0);
ffffffffc0200ef0:	00001697          	auipc	a3,0x1
ffffffffc0200ef4:	a6068693          	addi	a3,a3,-1440 # ffffffffc0201950 <etext+0x260>
ffffffffc0200ef8:	00001617          	auipc	a2,0x1
ffffffffc0200efc:	a6060613          	addi	a2,a2,-1440 # ffffffffc0201958 <etext+0x268>
ffffffffc0200f00:	09b00593          	li	a1,155
ffffffffc0200f04:	00001517          	auipc	a0,0x1
ffffffffc0200f08:	a6c50513          	addi	a0,a0,-1428 # ffffffffc0201970 <etext+0x280>
ffffffffc0200f0c:	ab8ff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc0200f10 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200f10:	1141                	addi	sp,sp,-16
ffffffffc0200f12:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200f14:	c1fd                	beqz	a1,ffffffffc0200ffa <best_fit_init_memmap+0xea>
    for (; p != base + n; p ++) {
ffffffffc0200f16:	00259693          	slli	a3,a1,0x2
ffffffffc0200f1a:	96ae                	add	a3,a3,a1
ffffffffc0200f1c:	068e                	slli	a3,a3,0x3
ffffffffc0200f1e:	96aa                	add	a3,a3,a0
ffffffffc0200f20:	651c                	ld	a5,8(a0)
ffffffffc0200f22:	02d50563          	beq	a0,a3,ffffffffc0200f4c <best_fit_init_memmap+0x3c>
        assert(PageReserved(p));
ffffffffc0200f26:	0017f713          	andi	a4,a5,1
ffffffffc0200f2a:	87aa                	mv	a5,a0
ffffffffc0200f2c:	e709                	bnez	a4,ffffffffc0200f36 <best_fit_init_memmap+0x26>
ffffffffc0200f2e:	a075                	j	ffffffffc0200fda <best_fit_init_memmap+0xca>
ffffffffc0200f30:	6798                	ld	a4,8(a5)
ffffffffc0200f32:	8b05                	andi	a4,a4,1
ffffffffc0200f34:	c35d                	beqz	a4,ffffffffc0200fda <best_fit_init_memmap+0xca>
        p->flags = 0;
ffffffffc0200f36:	0007b423          	sd	zero,8(a5)
ffffffffc0200f3a:	0007a023          	sw	zero,0(a5)
        p->property = 0;//非空闲块起始页的块大小设为0
ffffffffc0200f3e:	0007a823          	sw	zero,16(a5)
    for (; p != base + n; p ++) {
ffffffffc0200f42:	02878793          	addi	a5,a5,40
ffffffffc0200f46:	fed795e3          	bne	a5,a3,ffffffffc0200f30 <best_fit_init_memmap+0x20>
ffffffffc0200f4a:	651c                	ld	a5,8(a0)
    nr_free += n;
ffffffffc0200f4c:	00005697          	auipc	a3,0x5
ffffffffc0200f50:	0cc68693          	addi	a3,a3,204 # ffffffffc0206018 <edata>
ffffffffc0200f54:	4a90                	lw	a2,16(a3)
    SetPageProperty(base);
ffffffffc0200f56:	0027e713          	ori	a4,a5,2
    base->property = n;//空闲块起始页base的property设为总页数n
ffffffffc0200f5a:	2581                	sext.w	a1,a1
    return list->next == list;
ffffffffc0200f5c:	669c                	ld	a5,8(a3)
ffffffffc0200f5e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200f60:	e518                	sd	a4,8(a0)
    nr_free += n;
ffffffffc0200f62:	9db1                	addw	a1,a1,a2
ffffffffc0200f64:	00005717          	auipc	a4,0x5
ffffffffc0200f68:	0cb72223          	sw	a1,196(a4) # ffffffffc0206028 <edata+0x10>
    if (list_empty(&free_list)) {
ffffffffc0200f6c:	04d78a63          	beq	a5,a3,ffffffffc0200fc0 <best_fit_init_memmap+0xb0>
            struct Page* page = le2page(le, page_link);
ffffffffc0200f70:	fe878713          	addi	a4,a5,-24
ffffffffc0200f74:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200f76:	4801                	li	a6,0
ffffffffc0200f78:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0200f7c:	00e56a63          	bltu	a0,a4,ffffffffc0200f90 <best_fit_init_memmap+0x80>
    return listelm->next;
ffffffffc0200f80:	6798                	ld	a4,8(a5)
            else if (list_next(le) == &free_list) {
ffffffffc0200f82:	02d70563          	beq	a4,a3,ffffffffc0200fac <best_fit_init_memmap+0x9c>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200f86:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200f88:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200f8c:	fee57ae3          	bgeu	a0,a4,ffffffffc0200f80 <best_fit_init_memmap+0x70>
ffffffffc0200f90:	00080663          	beqz	a6,ffffffffc0200f9c <best_fit_init_memmap+0x8c>
ffffffffc0200f94:	00005717          	auipc	a4,0x5
ffffffffc0200f98:	08b73223          	sd	a1,132(a4) # ffffffffc0206018 <edata>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200f9c:	6398                	ld	a4,0(a5)
}
ffffffffc0200f9e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200fa0:	e390                	sd	a2,0(a5)
ffffffffc0200fa2:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200fa4:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fa6:	ed18                	sd	a4,24(a0)
ffffffffc0200fa8:	0141                	addi	sp,sp,16
ffffffffc0200faa:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200fac:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200fae:	f114                	sd	a3,32(a0)
ffffffffc0200fb0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200fb2:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc0200fb4:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200fb6:	00d70e63          	beq	a4,a3,ffffffffc0200fd2 <best_fit_init_memmap+0xc2>
ffffffffc0200fba:	4805                	li	a6,1
ffffffffc0200fbc:	87ba                	mv	a5,a4
ffffffffc0200fbe:	b7e9                	j	ffffffffc0200f88 <best_fit_init_memmap+0x78>
}
ffffffffc0200fc0:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0200fc2:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0200fc6:	e398                	sd	a4,0(a5)
ffffffffc0200fc8:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0200fca:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200fcc:	ed1c                	sd	a5,24(a0)
}
ffffffffc0200fce:	0141                	addi	sp,sp,16
ffffffffc0200fd0:	8082                	ret
ffffffffc0200fd2:	60a2                	ld	ra,8(sp)
ffffffffc0200fd4:	e290                	sd	a2,0(a3)
ffffffffc0200fd6:	0141                	addi	sp,sp,16
ffffffffc0200fd8:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200fda:	00001697          	auipc	a3,0x1
ffffffffc0200fde:	c9e68693          	addi	a3,a3,-866 # ffffffffc0201c78 <etext+0x588>
ffffffffc0200fe2:	00001617          	auipc	a2,0x1
ffffffffc0200fe6:	97660613          	addi	a2,a2,-1674 # ffffffffc0201958 <etext+0x268>
ffffffffc0200fea:	04b00593          	li	a1,75
ffffffffc0200fee:	00001517          	auipc	a0,0x1
ffffffffc0200ff2:	98250513          	addi	a0,a0,-1662 # ffffffffc0201970 <etext+0x280>
ffffffffc0200ff6:	9ceff0ef          	jal	ra,ffffffffc02001c4 <__panic>
    assert(n > 0);
ffffffffc0200ffa:	00001697          	auipc	a3,0x1
ffffffffc0200ffe:	95668693          	addi	a3,a3,-1706 # ffffffffc0201950 <etext+0x260>
ffffffffc0201002:	00001617          	auipc	a2,0x1
ffffffffc0201006:	95660613          	addi	a2,a2,-1706 # ffffffffc0201958 <etext+0x268>
ffffffffc020100a:	04800593          	li	a1,72
ffffffffc020100e:	00001517          	auipc	a0,0x1
ffffffffc0201012:	96250513          	addi	a0,a0,-1694 # ffffffffc0201970 <etext+0x280>
ffffffffc0201016:	9aeff0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc020101a <alloc_pages>:
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
    return pmm_manager->alloc_pages(n);
ffffffffc020101a:	00005797          	auipc	a5,0x5
ffffffffc020101e:	04678793          	addi	a5,a5,70 # ffffffffc0206060 <pmm_manager>
ffffffffc0201022:	639c                	ld	a5,0(a5)
ffffffffc0201024:	0187b303          	ld	t1,24(a5)
ffffffffc0201028:	8302                	jr	t1

ffffffffc020102a <free_pages>:
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    pmm_manager->free_pages(base, n);
ffffffffc020102a:	00005797          	auipc	a5,0x5
ffffffffc020102e:	03678793          	addi	a5,a5,54 # ffffffffc0206060 <pmm_manager>
ffffffffc0201032:	639c                	ld	a5,0(a5)
ffffffffc0201034:	0207b303          	ld	t1,32(a5)
ffffffffc0201038:	8302                	jr	t1

ffffffffc020103a <nr_free_pages>:
}

// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
// of current free memory
size_t nr_free_pages(void) {
    return pmm_manager->nr_free_pages();
ffffffffc020103a:	00005797          	auipc	a5,0x5
ffffffffc020103e:	02678793          	addi	a5,a5,38 # ffffffffc0206060 <pmm_manager>
ffffffffc0201042:	639c                	ld	a5,0(a5)
ffffffffc0201044:	0287b303          	ld	t1,40(a5)
ffffffffc0201048:	8302                	jr	t1

ffffffffc020104a <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020104a:	00001797          	auipc	a5,0x1
ffffffffc020104e:	c3e78793          	addi	a5,a5,-962 # ffffffffc0201c88 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201052:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201054:	7179                	addi	sp,sp,-48
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201056:	00001517          	auipc	a0,0x1
ffffffffc020105a:	c8250513          	addi	a0,a0,-894 # ffffffffc0201cd8 <best_fit_pmm_manager+0x50>
void pmm_init(void) {
ffffffffc020105e:	f406                	sd	ra,40(sp)
ffffffffc0201060:	f022                	sd	s0,32(sp)
ffffffffc0201062:	e84a                	sd	s2,16(sp)
ffffffffc0201064:	ec26                	sd	s1,24(sp)
ffffffffc0201066:	e44e                	sd	s3,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201068:	00005717          	auipc	a4,0x5
ffffffffc020106c:	fef73c23          	sd	a5,-8(a4) # ffffffffc0206060 <pmm_manager>
ffffffffc0201070:	00005417          	auipc	s0,0x5
ffffffffc0201074:	ff040413          	addi	s0,s0,-16 # ffffffffc0206060 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201078:	8d8ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    pmm_manager->init();
ffffffffc020107c:	601c                	ld	a5,0(s0)
ffffffffc020107e:	679c                	ld	a5,8(a5)
ffffffffc0201080:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201082:	57f5                	li	a5,-3
ffffffffc0201084:	07fa                	slli	a5,a5,0x1e
ffffffffc0201086:	00005717          	auipc	a4,0x5
ffffffffc020108a:	fef73123          	sd	a5,-30(a4) # ffffffffc0206068 <va_pa_offset>
    uint64_t mem_begin = get_memory_base();
ffffffffc020108e:	ce4ff0ef          	jal	ra,ffffffffc0200572 <get_memory_base>
ffffffffc0201092:	892a                	mv	s2,a0
    uint64_t mem_size  = get_memory_size();
ffffffffc0201094:	ceaff0ef          	jal	ra,ffffffffc020057e <get_memory_size>
    if (mem_size == 0) {
ffffffffc0201098:	14050663          	beqz	a0,ffffffffc02011e4 <pmm_init+0x19a>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc020109c:	84aa                	mv	s1,a0
    cprintf("physcial memory map:\n");
ffffffffc020109e:	00001517          	auipc	a0,0x1
ffffffffc02010a2:	c8250513          	addi	a0,a0,-894 # ffffffffc0201d20 <best_fit_pmm_manager+0x98>
ffffffffc02010a6:	8aaff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    uint64_t mem_end   = mem_begin + mem_size;
ffffffffc02010aa:	009909b3          	add	s3,s2,s1
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc02010ae:	fff98693          	addi	a3,s3,-1
ffffffffc02010b2:	864a                	mv	a2,s2
ffffffffc02010b4:	85a6                	mv	a1,s1
ffffffffc02010b6:	00001517          	auipc	a0,0x1
ffffffffc02010ba:	c8250513          	addi	a0,a0,-894 # ffffffffc0201d38 <best_fit_pmm_manager+0xb0>
ffffffffc02010be:	892ff0ef          	jal	ra,ffffffffc0200150 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc02010c2:	c8000737          	lui	a4,0xc8000
ffffffffc02010c6:	87ce                	mv	a5,s3
ffffffffc02010c8:	0d376963          	bltu	a4,s3,ffffffffc020119a <pmm_init+0x150>
ffffffffc02010cc:	00006817          	auipc	a6,0x6
ffffffffc02010d0:	fab80813          	addi	a6,a6,-85 # ffffffffc0207077 <end+0xfff>
ffffffffc02010d4:	757d                	lui	a0,0xfffff
ffffffffc02010d6:	83b1                	srli	a5,a5,0xc
ffffffffc02010d8:	00a87833          	and	a6,a6,a0
ffffffffc02010dc:	00005717          	auipc	a4,0x5
ffffffffc02010e0:	f6f73623          	sd	a5,-148(a4) # ffffffffc0206048 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02010e4:	00005717          	auipc	a4,0x5
ffffffffc02010e8:	f9073623          	sd	a6,-116(a4) # ffffffffc0206070 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02010ec:	00080737          	lui	a4,0x80
ffffffffc02010f0:	002006b7          	lui	a3,0x200
ffffffffc02010f4:	02e78563          	beq	a5,a4,ffffffffc020111e <pmm_init+0xd4>
ffffffffc02010f8:	00279693          	slli	a3,a5,0x2
ffffffffc02010fc:	00f68633          	add	a2,a3,a5
ffffffffc0201100:	fec00737          	lui	a4,0xfec00
ffffffffc0201104:	9742                	add	a4,a4,a6
ffffffffc0201106:	060e                	slli	a2,a2,0x3
ffffffffc0201108:	963a                	add	a2,a2,a4
ffffffffc020110a:	8742                	mv	a4,a6
        SetPageReserved(pages + i);
ffffffffc020110c:	670c                	ld	a1,8(a4)
ffffffffc020110e:	02870713          	addi	a4,a4,40 # fffffffffec00028 <end+0x3e9f9fb0>
ffffffffc0201112:	0015e593          	ori	a1,a1,1
ffffffffc0201116:	feb73023          	sd	a1,-32(a4)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc020111a:	fee619e3          	bne	a2,a4,ffffffffc020110c <pmm_init+0xc2>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc020111e:	96be                	add	a3,a3,a5
ffffffffc0201120:	fec00737          	lui	a4,0xfec00
ffffffffc0201124:	9742                	add	a4,a4,a6
ffffffffc0201126:	068e                	slli	a3,a3,0x3
ffffffffc0201128:	96ba                	add	a3,a3,a4
ffffffffc020112a:	c0200737          	lui	a4,0xc0200
ffffffffc020112e:	08e6ef63          	bltu	a3,a4,ffffffffc02011cc <pmm_init+0x182>
ffffffffc0201132:	00005497          	auipc	s1,0x5
ffffffffc0201136:	f3648493          	addi	s1,s1,-202 # ffffffffc0206068 <va_pa_offset>
ffffffffc020113a:	6090                	ld	a2,0(s1)
    mem_end = ROUNDDOWN(mem_end, PGSIZE);
ffffffffc020113c:	777d                	lui	a4,0xfffff
ffffffffc020113e:	00e9f5b3          	and	a1,s3,a4
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201142:	8e91                	sub	a3,a3,a2
    if (freemem < mem_end) {
ffffffffc0201144:	04b6ee63          	bltu	a3,a1,ffffffffc02011a0 <pmm_init+0x156>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201148:	601c                	ld	a5,0(s0)
ffffffffc020114a:	7b9c                	ld	a5,48(a5)
ffffffffc020114c:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc020114e:	00001517          	auipc	a0,0x1
ffffffffc0201152:	c7250513          	addi	a0,a0,-910 # ffffffffc0201dc0 <best_fit_pmm_manager+0x138>
ffffffffc0201156:	ffbfe0ef          	jal	ra,ffffffffc0200150 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc020115a:	00004697          	auipc	a3,0x4
ffffffffc020115e:	ea668693          	addi	a3,a3,-346 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc0201162:	00005797          	auipc	a5,0x5
ffffffffc0201166:	eed7b723          	sd	a3,-274(a5) # ffffffffc0206050 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc020116a:	c02007b7          	lui	a5,0xc0200
ffffffffc020116e:	08f6e763          	bltu	a3,a5,ffffffffc02011fc <pmm_init+0x1b2>
ffffffffc0201172:	609c                	ld	a5,0(s1)
}
ffffffffc0201174:	7402                	ld	s0,32(sp)
ffffffffc0201176:	70a2                	ld	ra,40(sp)
ffffffffc0201178:	64e2                	ld	s1,24(sp)
ffffffffc020117a:	6942                	ld	s2,16(sp)
ffffffffc020117c:	69a2                	ld	s3,8(sp)
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020117e:	85b6                	mv	a1,a3
    satp_physical = PADDR(satp_virtual);
ffffffffc0201180:	8e9d                	sub	a3,a3,a5
ffffffffc0201182:	00005797          	auipc	a5,0x5
ffffffffc0201186:	ecd7bb23          	sd	a3,-298(a5) # ffffffffc0206058 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020118a:	00001517          	auipc	a0,0x1
ffffffffc020118e:	c5650513          	addi	a0,a0,-938 # ffffffffc0201de0 <best_fit_pmm_manager+0x158>
ffffffffc0201192:	8636                	mv	a2,a3
}
ffffffffc0201194:	6145                	addi	sp,sp,48
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201196:	fbbfe06f          	j	ffffffffc0200150 <cprintf>
    npage = maxpa / PGSIZE;
ffffffffc020119a:	c80007b7          	lui	a5,0xc8000
ffffffffc020119e:	b73d                	j	ffffffffc02010cc <pmm_init+0x82>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc02011a0:	6605                	lui	a2,0x1
ffffffffc02011a2:	167d                	addi	a2,a2,-1
ffffffffc02011a4:	96b2                	add	a3,a3,a2
ffffffffc02011a6:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc02011a8:	00c6d513          	srli	a0,a3,0xc
ffffffffc02011ac:	06f57463          	bgeu	a0,a5,ffffffffc0201214 <pmm_init+0x1ca>
    pmm_manager->init_memmap(base, n);
ffffffffc02011b0:	6018                	ld	a4,0(s0)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc02011b2:	fff807b7          	lui	a5,0xfff80
ffffffffc02011b6:	97aa                	add	a5,a5,a0
ffffffffc02011b8:	00279513          	slli	a0,a5,0x2
ffffffffc02011bc:	953e                	add	a0,a0,a5
ffffffffc02011be:	6b1c                	ld	a5,16(a4)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc02011c0:	8d95                	sub	a1,a1,a3
ffffffffc02011c2:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc02011c4:	81b1                	srli	a1,a1,0xc
ffffffffc02011c6:	9542                	add	a0,a0,a6
ffffffffc02011c8:	9782                	jalr	a5
ffffffffc02011ca:	bfbd                	j	ffffffffc0201148 <pmm_init+0xfe>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02011cc:	00001617          	auipc	a2,0x1
ffffffffc02011d0:	b9c60613          	addi	a2,a2,-1124 # ffffffffc0201d68 <best_fit_pmm_manager+0xe0>
ffffffffc02011d4:	05e00593          	li	a1,94
ffffffffc02011d8:	00001517          	auipc	a0,0x1
ffffffffc02011dc:	b3850513          	addi	a0,a0,-1224 # ffffffffc0201d10 <best_fit_pmm_manager+0x88>
ffffffffc02011e0:	fe5fe0ef          	jal	ra,ffffffffc02001c4 <__panic>
        panic("DTB memory info not available");
ffffffffc02011e4:	00001617          	auipc	a2,0x1
ffffffffc02011e8:	b0c60613          	addi	a2,a2,-1268 # ffffffffc0201cf0 <best_fit_pmm_manager+0x68>
ffffffffc02011ec:	04600593          	li	a1,70
ffffffffc02011f0:	00001517          	auipc	a0,0x1
ffffffffc02011f4:	b2050513          	addi	a0,a0,-1248 # ffffffffc0201d10 <best_fit_pmm_manager+0x88>
ffffffffc02011f8:	fcdfe0ef          	jal	ra,ffffffffc02001c4 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02011fc:	00001617          	auipc	a2,0x1
ffffffffc0201200:	b6c60613          	addi	a2,a2,-1172 # ffffffffc0201d68 <best_fit_pmm_manager+0xe0>
ffffffffc0201204:	07900593          	li	a1,121
ffffffffc0201208:	00001517          	auipc	a0,0x1
ffffffffc020120c:	b0850513          	addi	a0,a0,-1272 # ffffffffc0201d10 <best_fit_pmm_manager+0x88>
ffffffffc0201210:	fb5fe0ef          	jal	ra,ffffffffc02001c4 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201214:	00001617          	auipc	a2,0x1
ffffffffc0201218:	b7c60613          	addi	a2,a2,-1156 # ffffffffc0201d90 <best_fit_pmm_manager+0x108>
ffffffffc020121c:	06a00593          	li	a1,106
ffffffffc0201220:	00001517          	auipc	a0,0x1
ffffffffc0201224:	b9050513          	addi	a0,a0,-1136 # ffffffffc0201db0 <best_fit_pmm_manager+0x128>
ffffffffc0201228:	f9dfe0ef          	jal	ra,ffffffffc02001c4 <__panic>

ffffffffc020122c <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc020122c:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201230:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0201232:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0201236:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0201238:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020123c:	f022                	sd	s0,32(sp)
ffffffffc020123e:	ec26                	sd	s1,24(sp)
ffffffffc0201240:	e84a                	sd	s2,16(sp)
ffffffffc0201242:	f406                	sd	ra,40(sp)
ffffffffc0201244:	e44e                	sd	s3,8(sp)
ffffffffc0201246:	84aa                	mv	s1,a0
ffffffffc0201248:	892e                	mv	s2,a1
ffffffffc020124a:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020124e:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc0201250:	03067e63          	bgeu	a2,a6,ffffffffc020128c <printnum+0x60>
ffffffffc0201254:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0201256:	00805763          	blez	s0,ffffffffc0201264 <printnum+0x38>
ffffffffc020125a:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc020125c:	85ca                	mv	a1,s2
ffffffffc020125e:	854e                	mv	a0,s3
ffffffffc0201260:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0201262:	fc65                	bnez	s0,ffffffffc020125a <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201264:	1a02                	slli	s4,s4,0x20
ffffffffc0201266:	020a5a13          	srli	s4,s4,0x20
ffffffffc020126a:	00001797          	auipc	a5,0x1
ffffffffc020126e:	d4678793          	addi	a5,a5,-698 # ffffffffc0201fb0 <error_string+0x38>
ffffffffc0201272:	9a3e                	add	s4,s4,a5
}
ffffffffc0201274:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201276:	000a4503          	lbu	a0,0(s4)
}
ffffffffc020127a:	70a2                	ld	ra,40(sp)
ffffffffc020127c:	69a2                	ld	s3,8(sp)
ffffffffc020127e:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201280:	85ca                	mv	a1,s2
ffffffffc0201282:	8326                	mv	t1,s1
}
ffffffffc0201284:	6942                	ld	s2,16(sp)
ffffffffc0201286:	64e2                	ld	s1,24(sp)
ffffffffc0201288:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020128a:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc020128c:	03065633          	divu	a2,a2,a6
ffffffffc0201290:	8722                	mv	a4,s0
ffffffffc0201292:	f9bff0ef          	jal	ra,ffffffffc020122c <printnum>
ffffffffc0201296:	b7f9                	j	ffffffffc0201264 <printnum+0x38>

ffffffffc0201298 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0201298:	7119                	addi	sp,sp,-128
ffffffffc020129a:	f4a6                	sd	s1,104(sp)
ffffffffc020129c:	f0ca                	sd	s2,96(sp)
ffffffffc020129e:	e8d2                	sd	s4,80(sp)
ffffffffc02012a0:	e4d6                	sd	s5,72(sp)
ffffffffc02012a2:	e0da                	sd	s6,64(sp)
ffffffffc02012a4:	fc5e                	sd	s7,56(sp)
ffffffffc02012a6:	f862                	sd	s8,48(sp)
ffffffffc02012a8:	f06a                	sd	s10,32(sp)
ffffffffc02012aa:	fc86                	sd	ra,120(sp)
ffffffffc02012ac:	f8a2                	sd	s0,112(sp)
ffffffffc02012ae:	ecce                	sd	s3,88(sp)
ffffffffc02012b0:	f466                	sd	s9,40(sp)
ffffffffc02012b2:	ec6e                	sd	s11,24(sp)
ffffffffc02012b4:	892a                	mv	s2,a0
ffffffffc02012b6:	84ae                	mv	s1,a1
ffffffffc02012b8:	8d32                	mv	s10,a2
ffffffffc02012ba:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02012bc:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02012be:	00001a17          	auipc	s4,0x1
ffffffffc02012c2:	b62a0a13          	addi	s4,s4,-1182 # ffffffffc0201e20 <best_fit_pmm_manager+0x198>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02012c6:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02012ca:	00001c17          	auipc	s8,0x1
ffffffffc02012ce:	caec0c13          	addi	s8,s8,-850 # ffffffffc0201f78 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012d2:	000d4503          	lbu	a0,0(s10)
ffffffffc02012d6:	02500793          	li	a5,37
ffffffffc02012da:	001d0413          	addi	s0,s10,1
ffffffffc02012de:	00f50e63          	beq	a0,a5,ffffffffc02012fa <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc02012e2:	c521                	beqz	a0,ffffffffc020132a <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012e4:	02500993          	li	s3,37
ffffffffc02012e8:	a011                	j	ffffffffc02012ec <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc02012ea:	c121                	beqz	a0,ffffffffc020132a <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc02012ec:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012ee:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc02012f0:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02012f2:	fff44503          	lbu	a0,-1(s0)
ffffffffc02012f6:	ff351ae3          	bne	a0,s3,ffffffffc02012ea <vprintfmt+0x52>
ffffffffc02012fa:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc02012fe:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0201302:	4981                	li	s3,0
ffffffffc0201304:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0201306:	5cfd                	li	s9,-1
ffffffffc0201308:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020130a:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc020130e:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201310:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0201314:	0ff6f693          	andi	a3,a3,255
ffffffffc0201318:	00140d13          	addi	s10,s0,1
ffffffffc020131c:	1ed5ef63          	bltu	a1,a3,ffffffffc020151a <vprintfmt+0x282>
ffffffffc0201320:	068a                	slli	a3,a3,0x2
ffffffffc0201322:	96d2                	add	a3,a3,s4
ffffffffc0201324:	4294                	lw	a3,0(a3)
ffffffffc0201326:	96d2                	add	a3,a3,s4
ffffffffc0201328:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc020132a:	70e6                	ld	ra,120(sp)
ffffffffc020132c:	7446                	ld	s0,112(sp)
ffffffffc020132e:	74a6                	ld	s1,104(sp)
ffffffffc0201330:	7906                	ld	s2,96(sp)
ffffffffc0201332:	69e6                	ld	s3,88(sp)
ffffffffc0201334:	6a46                	ld	s4,80(sp)
ffffffffc0201336:	6aa6                	ld	s5,72(sp)
ffffffffc0201338:	6b06                	ld	s6,64(sp)
ffffffffc020133a:	7be2                	ld	s7,56(sp)
ffffffffc020133c:	7c42                	ld	s8,48(sp)
ffffffffc020133e:	7ca2                	ld	s9,40(sp)
ffffffffc0201340:	7d02                	ld	s10,32(sp)
ffffffffc0201342:	6de2                	ld	s11,24(sp)
ffffffffc0201344:	6109                	addi	sp,sp,128
ffffffffc0201346:	8082                	ret
            padc = '-';
ffffffffc0201348:	87b2                	mv	a5,a2
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020134a:	00144603          	lbu	a2,1(s0)
ffffffffc020134e:	846a                	mv	s0,s10
ffffffffc0201350:	b7c1                	j	ffffffffc0201310 <vprintfmt+0x78>
            precision = va_arg(ap, int);
ffffffffc0201352:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc0201356:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc020135a:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020135c:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc020135e:	fa0dd9e3          	bgez	s11,ffffffffc0201310 <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc0201362:	8de6                	mv	s11,s9
ffffffffc0201364:	5cfd                	li	s9,-1
ffffffffc0201366:	b76d                	j	ffffffffc0201310 <vprintfmt+0x78>
            if (width < 0)
ffffffffc0201368:	fffdc693          	not	a3,s11
ffffffffc020136c:	96fd                	srai	a3,a3,0x3f
ffffffffc020136e:	00ddfdb3          	and	s11,s11,a3
ffffffffc0201372:	00144603          	lbu	a2,1(s0)
ffffffffc0201376:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201378:	846a                	mv	s0,s10
ffffffffc020137a:	bf59                	j	ffffffffc0201310 <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc020137c:	4705                	li	a4,1
ffffffffc020137e:	008a8593          	addi	a1,s5,8
ffffffffc0201382:	01074463          	blt	a4,a6,ffffffffc020138a <vprintfmt+0xf2>
    else if (lflag) {
ffffffffc0201386:	22080863          	beqz	a6,ffffffffc02015b6 <vprintfmt+0x31e>
        return va_arg(*ap, unsigned long);
ffffffffc020138a:	000ab603          	ld	a2,0(s5)
ffffffffc020138e:	46c1                	li	a3,16
ffffffffc0201390:	8aae                	mv	s5,a1
ffffffffc0201392:	a291                	j	ffffffffc02014d6 <vprintfmt+0x23e>
                precision = precision * 10 + ch - '0';
ffffffffc0201394:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0201398:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020139c:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020139e:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc02013a2:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013a6:	fad56ce3          	bltu	a0,a3,ffffffffc020135e <vprintfmt+0xc6>
            for (precision = 0; ; ++ fmt) {
ffffffffc02013aa:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc02013ac:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc02013b0:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc02013b4:	0196873b          	addw	a4,a3,s9
ffffffffc02013b8:	0017171b          	slliw	a4,a4,0x1
ffffffffc02013bc:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc02013c0:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc02013c4:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc02013c8:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc02013cc:	fcd57fe3          	bgeu	a0,a3,ffffffffc02013aa <vprintfmt+0x112>
ffffffffc02013d0:	b779                	j	ffffffffc020135e <vprintfmt+0xc6>
            putch(va_arg(ap, int), putdat);
ffffffffc02013d2:	000aa503          	lw	a0,0(s5)
ffffffffc02013d6:	85a6                	mv	a1,s1
ffffffffc02013d8:	0aa1                	addi	s5,s5,8
ffffffffc02013da:	9902                	jalr	s2
            break;
ffffffffc02013dc:	bddd                	j	ffffffffc02012d2 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02013de:	4705                	li	a4,1
ffffffffc02013e0:	008a8993          	addi	s3,s5,8
ffffffffc02013e4:	01074463          	blt	a4,a6,ffffffffc02013ec <vprintfmt+0x154>
    else if (lflag) {
ffffffffc02013e8:	1c080463          	beqz	a6,ffffffffc02015b0 <vprintfmt+0x318>
        return va_arg(*ap, long);
ffffffffc02013ec:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02013f0:	1c044a63          	bltz	s0,ffffffffc02015c4 <vprintfmt+0x32c>
            num = getint(&ap, lflag);
ffffffffc02013f4:	8622                	mv	a2,s0
ffffffffc02013f6:	8ace                	mv	s5,s3
ffffffffc02013f8:	46a9                	li	a3,10
ffffffffc02013fa:	a8f1                	j	ffffffffc02014d6 <vprintfmt+0x23e>
            err = va_arg(ap, int);
ffffffffc02013fc:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201400:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201402:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc0201404:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201408:	8fb5                	xor	a5,a5,a3
ffffffffc020140a:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020140e:	12d74963          	blt	a4,a3,ffffffffc0201540 <vprintfmt+0x2a8>
ffffffffc0201412:	00369793          	slli	a5,a3,0x3
ffffffffc0201416:	97e2                	add	a5,a5,s8
ffffffffc0201418:	639c                	ld	a5,0(a5)
ffffffffc020141a:	12078363          	beqz	a5,ffffffffc0201540 <vprintfmt+0x2a8>
                printfmt(putch, putdat, "%s", p);
ffffffffc020141e:	86be                	mv	a3,a5
ffffffffc0201420:	00001617          	auipc	a2,0x1
ffffffffc0201424:	c4060613          	addi	a2,a2,-960 # ffffffffc0202060 <error_string+0xe8>
ffffffffc0201428:	85a6                	mv	a1,s1
ffffffffc020142a:	854a                	mv	a0,s2
ffffffffc020142c:	1cc000ef          	jal	ra,ffffffffc02015f8 <printfmt>
ffffffffc0201430:	b54d                	j	ffffffffc02012d2 <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201432:	000ab603          	ld	a2,0(s5)
ffffffffc0201436:	0aa1                	addi	s5,s5,8
ffffffffc0201438:	1a060163          	beqz	a2,ffffffffc02015da <vprintfmt+0x342>
            if (width > 0 && padc != '-') {
ffffffffc020143c:	00160413          	addi	s0,a2,1
ffffffffc0201440:	15b05763          	blez	s11,ffffffffc020158e <vprintfmt+0x2f6>
ffffffffc0201444:	02d00593          	li	a1,45
ffffffffc0201448:	10b79d63          	bne	a5,a1,ffffffffc0201562 <vprintfmt+0x2ca>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020144c:	00064783          	lbu	a5,0(a2)
ffffffffc0201450:	0007851b          	sext.w	a0,a5
ffffffffc0201454:	c905                	beqz	a0,ffffffffc0201484 <vprintfmt+0x1ec>
ffffffffc0201456:	000cc563          	bltz	s9,ffffffffc0201460 <vprintfmt+0x1c8>
ffffffffc020145a:	3cfd                	addiw	s9,s9,-1
ffffffffc020145c:	036c8263          	beq	s9,s6,ffffffffc0201480 <vprintfmt+0x1e8>
                    putch('?', putdat);
ffffffffc0201460:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201462:	14098f63          	beqz	s3,ffffffffc02015c0 <vprintfmt+0x328>
ffffffffc0201466:	3781                	addiw	a5,a5,-32
ffffffffc0201468:	14fbfc63          	bgeu	s7,a5,ffffffffc02015c0 <vprintfmt+0x328>
                    putch('?', putdat);
ffffffffc020146c:	03f00513          	li	a0,63
ffffffffc0201470:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201472:	0405                	addi	s0,s0,1
ffffffffc0201474:	fff44783          	lbu	a5,-1(s0)
ffffffffc0201478:	3dfd                	addiw	s11,s11,-1
ffffffffc020147a:	0007851b          	sext.w	a0,a5
ffffffffc020147e:	fd61                	bnez	a0,ffffffffc0201456 <vprintfmt+0x1be>
            for (; width > 0; width --) {
ffffffffc0201480:	e5b059e3          	blez	s11,ffffffffc02012d2 <vprintfmt+0x3a>
ffffffffc0201484:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201486:	85a6                	mv	a1,s1
ffffffffc0201488:	02000513          	li	a0,32
ffffffffc020148c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020148e:	e40d82e3          	beqz	s11,ffffffffc02012d2 <vprintfmt+0x3a>
ffffffffc0201492:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201494:	85a6                	mv	a1,s1
ffffffffc0201496:	02000513          	li	a0,32
ffffffffc020149a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020149c:	fe0d94e3          	bnez	s11,ffffffffc0201484 <vprintfmt+0x1ec>
ffffffffc02014a0:	bd0d                	j	ffffffffc02012d2 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02014a2:	4705                	li	a4,1
ffffffffc02014a4:	008a8593          	addi	a1,s5,8
ffffffffc02014a8:	01074463          	blt	a4,a6,ffffffffc02014b0 <vprintfmt+0x218>
    else if (lflag) {
ffffffffc02014ac:	0e080863          	beqz	a6,ffffffffc020159c <vprintfmt+0x304>
        return va_arg(*ap, unsigned long);
ffffffffc02014b0:	000ab603          	ld	a2,0(s5)
ffffffffc02014b4:	46a1                	li	a3,8
ffffffffc02014b6:	8aae                	mv	s5,a1
ffffffffc02014b8:	a839                	j	ffffffffc02014d6 <vprintfmt+0x23e>
            putch('0', putdat);
ffffffffc02014ba:	03000513          	li	a0,48
ffffffffc02014be:	85a6                	mv	a1,s1
ffffffffc02014c0:	e03e                	sd	a5,0(sp)
ffffffffc02014c2:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02014c4:	85a6                	mv	a1,s1
ffffffffc02014c6:	07800513          	li	a0,120
ffffffffc02014ca:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02014cc:	0aa1                	addi	s5,s5,8
ffffffffc02014ce:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc02014d2:	6782                	ld	a5,0(sp)
ffffffffc02014d4:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc02014d6:	2781                	sext.w	a5,a5
ffffffffc02014d8:	876e                	mv	a4,s11
ffffffffc02014da:	85a6                	mv	a1,s1
ffffffffc02014dc:	854a                	mv	a0,s2
ffffffffc02014de:	d4fff0ef          	jal	ra,ffffffffc020122c <printnum>
            break;
ffffffffc02014e2:	bbc5                	j	ffffffffc02012d2 <vprintfmt+0x3a>
            lflag ++;
ffffffffc02014e4:	00144603          	lbu	a2,1(s0)
ffffffffc02014e8:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014ea:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014ec:	b515                	j	ffffffffc0201310 <vprintfmt+0x78>
            goto reswitch;
ffffffffc02014ee:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02014f2:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02014f4:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02014f6:	bd29                	j	ffffffffc0201310 <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02014f8:	85a6                	mv	a1,s1
ffffffffc02014fa:	02500513          	li	a0,37
ffffffffc02014fe:	9902                	jalr	s2
            break;
ffffffffc0201500:	bbc9                	j	ffffffffc02012d2 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201502:	4705                	li	a4,1
ffffffffc0201504:	008a8593          	addi	a1,s5,8
ffffffffc0201508:	01074463          	blt	a4,a6,ffffffffc0201510 <vprintfmt+0x278>
    else if (lflag) {
ffffffffc020150c:	08080d63          	beqz	a6,ffffffffc02015a6 <vprintfmt+0x30e>
        return va_arg(*ap, unsigned long);
ffffffffc0201510:	000ab603          	ld	a2,0(s5)
ffffffffc0201514:	46a9                	li	a3,10
ffffffffc0201516:	8aae                	mv	s5,a1
ffffffffc0201518:	bf7d                	j	ffffffffc02014d6 <vprintfmt+0x23e>
            putch('%', putdat);
ffffffffc020151a:	85a6                	mv	a1,s1
ffffffffc020151c:	02500513          	li	a0,37
ffffffffc0201520:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0201522:	fff44703          	lbu	a4,-1(s0)
ffffffffc0201526:	02500793          	li	a5,37
ffffffffc020152a:	8d22                	mv	s10,s0
ffffffffc020152c:	daf703e3          	beq	a4,a5,ffffffffc02012d2 <vprintfmt+0x3a>
ffffffffc0201530:	02500713          	li	a4,37
ffffffffc0201534:	1d7d                	addi	s10,s10,-1
ffffffffc0201536:	fffd4783          	lbu	a5,-1(s10)
ffffffffc020153a:	fee79de3          	bne	a5,a4,ffffffffc0201534 <vprintfmt+0x29c>
ffffffffc020153e:	bb51                	j	ffffffffc02012d2 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0201540:	00001617          	auipc	a2,0x1
ffffffffc0201544:	b1060613          	addi	a2,a2,-1264 # ffffffffc0202050 <error_string+0xd8>
ffffffffc0201548:	85a6                	mv	a1,s1
ffffffffc020154a:	854a                	mv	a0,s2
ffffffffc020154c:	0ac000ef          	jal	ra,ffffffffc02015f8 <printfmt>
ffffffffc0201550:	b349                	j	ffffffffc02012d2 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc0201552:	00001617          	auipc	a2,0x1
ffffffffc0201556:	af660613          	addi	a2,a2,-1290 # ffffffffc0202048 <error_string+0xd0>
            if (width > 0 && padc != '-') {
ffffffffc020155a:	00001417          	auipc	s0,0x1
ffffffffc020155e:	aef40413          	addi	s0,s0,-1297 # ffffffffc0202049 <error_string+0xd1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201562:	8532                	mv	a0,a2
ffffffffc0201564:	85e6                	mv	a1,s9
ffffffffc0201566:	e032                	sd	a2,0(sp)
ffffffffc0201568:	e43e                	sd	a5,8(sp)
ffffffffc020156a:	0e8000ef          	jal	ra,ffffffffc0201652 <strnlen>
ffffffffc020156e:	40ad8dbb          	subw	s11,s11,a0
ffffffffc0201572:	6602                	ld	a2,0(sp)
ffffffffc0201574:	01b05d63          	blez	s11,ffffffffc020158e <vprintfmt+0x2f6>
ffffffffc0201578:	67a2                	ld	a5,8(sp)
ffffffffc020157a:	2781                	sext.w	a5,a5
ffffffffc020157c:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc020157e:	6522                	ld	a0,8(sp)
ffffffffc0201580:	85a6                	mv	a1,s1
ffffffffc0201582:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201584:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc0201586:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201588:	6602                	ld	a2,0(sp)
ffffffffc020158a:	fe0d9ae3          	bnez	s11,ffffffffc020157e <vprintfmt+0x2e6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020158e:	00064783          	lbu	a5,0(a2)
ffffffffc0201592:	0007851b          	sext.w	a0,a5
ffffffffc0201596:	ec0510e3          	bnez	a0,ffffffffc0201456 <vprintfmt+0x1be>
ffffffffc020159a:	bb25                	j	ffffffffc02012d2 <vprintfmt+0x3a>
        return va_arg(*ap, unsigned int);
ffffffffc020159c:	000ae603          	lwu	a2,0(s5)
ffffffffc02015a0:	46a1                	li	a3,8
ffffffffc02015a2:	8aae                	mv	s5,a1
ffffffffc02015a4:	bf0d                	j	ffffffffc02014d6 <vprintfmt+0x23e>
ffffffffc02015a6:	000ae603          	lwu	a2,0(s5)
ffffffffc02015aa:	46a9                	li	a3,10
ffffffffc02015ac:	8aae                	mv	s5,a1
ffffffffc02015ae:	b725                	j	ffffffffc02014d6 <vprintfmt+0x23e>
        return va_arg(*ap, int);
ffffffffc02015b0:	000aa403          	lw	s0,0(s5)
ffffffffc02015b4:	bd35                	j	ffffffffc02013f0 <vprintfmt+0x158>
        return va_arg(*ap, unsigned int);
ffffffffc02015b6:	000ae603          	lwu	a2,0(s5)
ffffffffc02015ba:	46c1                	li	a3,16
ffffffffc02015bc:	8aae                	mv	s5,a1
ffffffffc02015be:	bf21                	j	ffffffffc02014d6 <vprintfmt+0x23e>
                    putch(ch, putdat);
ffffffffc02015c0:	9902                	jalr	s2
ffffffffc02015c2:	bd45                	j	ffffffffc0201472 <vprintfmt+0x1da>
                putch('-', putdat);
ffffffffc02015c4:	85a6                	mv	a1,s1
ffffffffc02015c6:	02d00513          	li	a0,45
ffffffffc02015ca:	e03e                	sd	a5,0(sp)
ffffffffc02015cc:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc02015ce:	8ace                	mv	s5,s3
ffffffffc02015d0:	40800633          	neg	a2,s0
ffffffffc02015d4:	46a9                	li	a3,10
ffffffffc02015d6:	6782                	ld	a5,0(sp)
ffffffffc02015d8:	bdfd                	j	ffffffffc02014d6 <vprintfmt+0x23e>
            if (width > 0 && padc != '-') {
ffffffffc02015da:	01b05663          	blez	s11,ffffffffc02015e6 <vprintfmt+0x34e>
ffffffffc02015de:	02d00693          	li	a3,45
ffffffffc02015e2:	f6d798e3          	bne	a5,a3,ffffffffc0201552 <vprintfmt+0x2ba>
ffffffffc02015e6:	00001417          	auipc	s0,0x1
ffffffffc02015ea:	a6340413          	addi	s0,s0,-1437 # ffffffffc0202049 <error_string+0xd1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02015ee:	02800513          	li	a0,40
ffffffffc02015f2:	02800793          	li	a5,40
ffffffffc02015f6:	b585                	j	ffffffffc0201456 <vprintfmt+0x1be>

ffffffffc02015f8 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015f8:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc02015fa:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc02015fe:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201600:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201602:	ec06                	sd	ra,24(sp)
ffffffffc0201604:	f83a                	sd	a4,48(sp)
ffffffffc0201606:	fc3e                	sd	a5,56(sp)
ffffffffc0201608:	e0c2                	sd	a6,64(sp)
ffffffffc020160a:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020160c:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020160e:	c8bff0ef          	jal	ra,ffffffffc0201298 <vprintfmt>
}
ffffffffc0201612:	60e2                	ld	ra,24(sp)
ffffffffc0201614:	6161                	addi	sp,sp,80
ffffffffc0201616:	8082                	ret

ffffffffc0201618 <sbi_console_putchar>:
    );
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
ffffffffc0201618:	00005797          	auipc	a5,0x5
ffffffffc020161c:	9f878793          	addi	a5,a5,-1544 # ffffffffc0206010 <SBI_CONSOLE_PUTCHAR>
    __asm__ volatile (
ffffffffc0201620:	6398                	ld	a4,0(a5)
ffffffffc0201622:	4781                	li	a5,0
ffffffffc0201624:	88ba                	mv	a7,a4
ffffffffc0201626:	852a                	mv	a0,a0
ffffffffc0201628:	85be                	mv	a1,a5
ffffffffc020162a:	863e                	mv	a2,a5
ffffffffc020162c:	00000073          	ecall
ffffffffc0201630:	87aa                	mv	a5,a0
}
ffffffffc0201632:	8082                	ret

ffffffffc0201634 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0201634:	00054783          	lbu	a5,0(a0)
ffffffffc0201638:	cb91                	beqz	a5,ffffffffc020164c <strlen+0x18>
    size_t cnt = 0;
ffffffffc020163a:	4781                	li	a5,0
        cnt ++;
ffffffffc020163c:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020163e:	00f50733          	add	a4,a0,a5
ffffffffc0201642:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0x3fdf8f88>
ffffffffc0201646:	fb7d                	bnez	a4,ffffffffc020163c <strlen+0x8>
    }
    return cnt;
}
ffffffffc0201648:	853e                	mv	a0,a5
ffffffffc020164a:	8082                	ret
    size_t cnt = 0;
ffffffffc020164c:	4781                	li	a5,0
}
ffffffffc020164e:	853e                	mv	a0,a5
ffffffffc0201650:	8082                	ret

ffffffffc0201652 <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201652:	c185                	beqz	a1,ffffffffc0201672 <strnlen+0x20>
ffffffffc0201654:	00054783          	lbu	a5,0(a0)
ffffffffc0201658:	cf89                	beqz	a5,ffffffffc0201672 <strnlen+0x20>
    size_t cnt = 0;
ffffffffc020165a:	4781                	li	a5,0
ffffffffc020165c:	a021                	j	ffffffffc0201664 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc020165e:	00074703          	lbu	a4,0(a4)
ffffffffc0201662:	c711                	beqz	a4,ffffffffc020166e <strnlen+0x1c>
        cnt ++;
ffffffffc0201664:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0201666:	00f50733          	add	a4,a0,a5
ffffffffc020166a:	fef59ae3          	bne	a1,a5,ffffffffc020165e <strnlen+0xc>
    }
    return cnt;
}
ffffffffc020166e:	853e                	mv	a0,a5
ffffffffc0201670:	8082                	ret
    size_t cnt = 0;
ffffffffc0201672:	4781                	li	a5,0
}
ffffffffc0201674:	853e                	mv	a0,a5
ffffffffc0201676:	8082                	ret

ffffffffc0201678 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201678:	00054783          	lbu	a5,0(a0)
ffffffffc020167c:	0005c703          	lbu	a4,0(a1)
ffffffffc0201680:	cb91                	beqz	a5,ffffffffc0201694 <strcmp+0x1c>
ffffffffc0201682:	00e79c63          	bne	a5,a4,ffffffffc020169a <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc0201686:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201688:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc020168c:	0585                	addi	a1,a1,1
ffffffffc020168e:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc0201692:	fbe5                	bnez	a5,ffffffffc0201682 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc0201694:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc0201696:	9d19                	subw	a0,a0,a4
ffffffffc0201698:	8082                	ret
ffffffffc020169a:	0007851b          	sext.w	a0,a5
ffffffffc020169e:	9d19                	subw	a0,a0,a4
ffffffffc02016a0:	8082                	ret

ffffffffc02016a2 <strncmp>:
 * the characters differ, until a terminating null-character is reached, or
 * until @n characters match in both strings, whichever happens first.
 * */
int
strncmp(const char *s1, const char *s2, size_t n) {
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016a2:	c61d                	beqz	a2,ffffffffc02016d0 <strncmp+0x2e>
ffffffffc02016a4:	00054703          	lbu	a4,0(a0)
ffffffffc02016a8:	0005c683          	lbu	a3,0(a1)
ffffffffc02016ac:	c715                	beqz	a4,ffffffffc02016d8 <strncmp+0x36>
ffffffffc02016ae:	02e69563          	bne	a3,a4,ffffffffc02016d8 <strncmp+0x36>
ffffffffc02016b2:	962e                	add	a2,a2,a1
ffffffffc02016b4:	a809                	j	ffffffffc02016c6 <strncmp+0x24>
ffffffffc02016b6:	00054703          	lbu	a4,0(a0)
ffffffffc02016ba:	cf09                	beqz	a4,ffffffffc02016d4 <strncmp+0x32>
ffffffffc02016bc:	0007c683          	lbu	a3,0(a5)
ffffffffc02016c0:	85be                	mv	a1,a5
ffffffffc02016c2:	00d71b63          	bne	a4,a3,ffffffffc02016d8 <strncmp+0x36>
        n --, s1 ++, s2 ++;
ffffffffc02016c6:	00158793          	addi	a5,a1,1
ffffffffc02016ca:	0505                	addi	a0,a0,1
    while (n > 0 && *s1 != '\0' && *s1 == *s2) {
ffffffffc02016cc:	fec795e3          	bne	a5,a2,ffffffffc02016b6 <strncmp+0x14>
    }
    return (n == 0) ? 0 : (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02016d0:	4501                	li	a0,0
ffffffffc02016d2:	8082                	ret
ffffffffc02016d4:	0015c683          	lbu	a3,1(a1)
ffffffffc02016d8:	40d7053b          	subw	a0,a4,a3
}
ffffffffc02016dc:	8082                	ret

ffffffffc02016de <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02016de:	ca01                	beqz	a2,ffffffffc02016ee <memset+0x10>
ffffffffc02016e0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02016e2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02016e4:	0785                	addi	a5,a5,1
ffffffffc02016e6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02016ea:	fec79de3          	bne	a5,a2,ffffffffc02016e4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02016ee:	8082                	ret


obj/kern/kernel：     文件格式 elf32-i386


Disassembly of section .text:

f0100000 <_start-0xc>:
.long MULTIBOOT_HEADER_FLAGS
.long CHECKSUM

.globl		_start
_start:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 03 00    	add    0x31bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fb                   	sti    
f0100009:	4f                   	dec    %edi
f010000a:	52                   	push   %edx
f010000b:	e4 66                	in     $0x66,%al

f010000c <_start>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 

	# Establish our own GDT in place of the boot loader's temporary GDT.
	lgdt	RELOC(mygdtdesc)		# load descriptor table
f0100015:	0f 01 15 18 f0 10 00 	lgdtl  0x10f018

	# Immediately reload all segment registers (including CS!)
	# with segment selectors from the new GDT.
	movl	$DATA_SEL, %eax			# Data segment selector
f010001c:	b8 10 00 00 00       	mov    $0x10,%eax
	movw	%ax,%ds				# -> DS: Data Segment
f0100021:	8e d8                	mov    %eax,%ds
	movw	%ax,%es				# -> ES: Extra Segment
f0100023:	8e c0                	mov    %eax,%es
	movw	%ax,%ss				# -> SS: Stack Segment
f0100025:	8e d0                	mov    %eax,%ss
	ljmp	$CODE_SEL,$relocated		# reload CS by jumping
f0100027:	ea 2e 00 10 f0 08 00 	ljmp   $0x8,$0xf010002e

f010002e <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002e:	bd 00 00 00 00       	mov    $0x0,%ebp

        # Set the stack pointer
	movl	$(bootstacktop),%esp
f0100033:	bc 00 f0 10 f0       	mov    $0xf010f000,%esp

	# now to C code
	call	i386_init
f0100038:	e8 5f 00 00 00       	call   f010009c <i386_init>

f010003d <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003d:	eb fe                	jmp    f010003d <spin>

f010003f <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f010003f:	55                   	push   %ebp
f0100040:	89 e5                	mov    %esp,%ebp
f0100042:	53                   	push   %ebx
f0100043:	83 ec 14             	sub    $0x14,%esp
f0100046:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f0100049:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004d:	c7 04 24 a0 16 10 f0 	movl   $0xf01016a0,(%esp)
f0100054:	e8 ee 08 00 00       	call   f0100947 <cprintf>
	if (x > 0)
f0100059:	85 db                	test   %ebx,%ebx
f010005b:	7e 0d                	jle    f010006a <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005d:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100060:	89 04 24             	mov    %eax,(%esp)
f0100063:	e8 d7 ff ff ff       	call   f010003f <test_backtrace>
f0100068:	eb 1c                	jmp    f0100086 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100071:	00 
f0100072:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100079:	00 
f010007a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100081:	e8 20 07 00 00       	call   f01007a6 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100086:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008a:	c7 04 24 bc 16 10 f0 	movl   $0xf01016bc,(%esp)
f0100091:	e8 b1 08 00 00       	call   f0100947 <cprintf>
}
f0100096:	83 c4 14             	add    $0x14,%esp
f0100099:	5b                   	pop    %ebx
f010009a:	5d                   	pop    %ebp
f010009b:	c3                   	ret    

f010009c <i386_init>:

void
i386_init(void)
{
f010009c:	55                   	push   %ebp
f010009d:	89 e5                	mov    %esp,%ebp
f010009f:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a2:	b8 80 f9 10 f0       	mov    $0xf010f980,%eax
f01000a7:	2d 20 f3 10 f0       	sub    $0xf010f320,%eax
f01000ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b7:	00 
f01000b8:	c7 04 24 20 f3 10 f0 	movl   $0xf010f320,(%esp)
f01000bf:	e8 3b 11 00 00       	call   f01011ff <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c4:	e8 83 05 00 00       	call   f010064c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000c9:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d0:	00 
f01000d1:	c7 04 24 d7 16 10 f0 	movl   $0xf01016d7,(%esp)
f01000d8:	e8 6a 08 00 00       	call   f0100947 <cprintf>




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000dd:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e4:	e8 56 ff ff ff       	call   f010003f <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f0:	e8 bb 06 00 00       	call   f01007b0 <monitor>
f01000f5:	eb f2                	jmp    f01000e9 <i386_init+0x4d>

f01000f7 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f7:	55                   	push   %ebp
f01000f8:	89 e5                	mov    %esp,%ebp
f01000fa:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	if (panicstr)
f01000fd:	83 3d 20 f3 10 f0 00 	cmpl   $0x0,0xf010f320
f0100104:	75 40                	jne    f0100146 <_panic+0x4f>
		goto dead;
	panicstr = fmt;
f0100106:	8b 45 10             	mov    0x10(%ebp),%eax
f0100109:	a3 20 f3 10 f0       	mov    %eax,0xf010f320

	va_start(ap, fmt);
	cprintf("kernel panic at %s:%d: ", file, line);
f010010e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100111:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100115:	8b 45 08             	mov    0x8(%ebp),%eax
f0100118:	89 44 24 04          	mov    %eax,0x4(%esp)
f010011c:	c7 04 24 f2 16 10 f0 	movl   $0xf01016f2,(%esp)
f0100123:	e8 1f 08 00 00       	call   f0100947 <cprintf>
	vcprintf(fmt, ap);
f0100128:	8d 45 14             	lea    0x14(%ebp),%eax
f010012b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100132:	89 04 24             	mov    %eax,(%esp)
f0100135:	e8 da 07 00 00       	call   f0100914 <vcprintf>
	cprintf("\n");
f010013a:	c7 04 24 2e 17 10 f0 	movl   $0xf010172e,(%esp)
f0100141:	e8 01 08 00 00       	call   f0100947 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100146:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014d:	e8 5e 06 00 00       	call   f01007b0 <monitor>
f0100152:	eb f2                	jmp    f0100146 <_panic+0x4f>

f0100154 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100154:	55                   	push   %ebp
f0100155:	89 e5                	mov    %esp,%ebp
f0100157:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	cprintf("kernel warning at %s:%d: ", file, line);
f010015a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010015d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100161:	8b 45 08             	mov    0x8(%ebp),%eax
f0100164:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100168:	c7 04 24 0a 17 10 f0 	movl   $0xf010170a,(%esp)
f010016f:	e8 d3 07 00 00       	call   f0100947 <cprintf>
	vcprintf(fmt, ap);
f0100174:	8d 45 14             	lea    0x14(%ebp),%eax
f0100177:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017b:	8b 45 10             	mov    0x10(%ebp),%eax
f010017e:	89 04 24             	mov    %eax,(%esp)
f0100181:	e8 8e 07 00 00       	call   f0100914 <vcprintf>
	cprintf("\n");
f0100186:	c7 04 24 2e 17 10 f0 	movl   $0xf010172e,(%esp)
f010018d:	e8 b5 07 00 00       	call   f0100947 <cprintf>
	va_end(ap);
}
f0100192:	c9                   	leave  
f0100193:	c3                   	ret    
f0100194:	66 90                	xchg   %ax,%ax
f0100196:	66 90                	xchg   %ax,%ax
f0100198:	66 90                	xchg   %ax,%ax
f010019a:	66 90                	xchg   %ax,%ax
f010019c:	66 90                	xchg   %ax,%ax
f010019e:	66 90                	xchg   %ax,%ax

f01001a0 <serial_proc_data>:

static bool serial_exists;

int
serial_proc_data(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a9:	a8 01                	test   $0x1,%al
f01001ab:	74 08                	je     f01001b5 <serial_proc_data+0x15>
f01001ad:	b2 f8                	mov    $0xf8,%dl
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
f01001b3:	eb 05                	jmp    f01001ba <serial_proc_data+0x1a>

int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01001ba:	5d                   	pop    %ebp
f01001bb:	c3                   	ret    

f01001bc <kbd_proc_data>:
f01001bc:	ba 64 00 00 00       	mov    $0x64,%edx
f01001c1:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01001c2:	a8 01                	test   $0x1,%al
f01001c4:	0f 84 ef 00 00 00    	je     f01002b9 <kbd_proc_data+0xfd>
f01001ca:	b2 60                	mov    $0x60,%dl
f01001cc:	ec                   	in     (%dx),%al
f01001cd:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01001cf:	3c e0                	cmp    $0xe0,%al
f01001d1:	75 0d                	jne    f01001e0 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01001d3:	83 0d 40 f3 10 f0 40 	orl    $0x40,0xf010f340
		return 0;
f01001da:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01001df:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01001e0:	55                   	push   %ebp
f01001e1:	89 e5                	mov    %esp,%ebp
f01001e3:	53                   	push   %ebx
f01001e4:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01001e7:	84 c0                	test   %al,%al
f01001e9:	79 37                	jns    f0100222 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01001eb:	8b 0d 40 f3 10 f0    	mov    0xf010f340,%ecx
f01001f1:	89 cb                	mov    %ecx,%ebx
f01001f3:	83 e3 40             	and    $0x40,%ebx
f01001f6:	83 e0 7f             	and    $0x7f,%eax
f01001f9:	85 db                	test   %ebx,%ebx
f01001fb:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01001fe:	0f b6 d2             	movzbl %dl,%edx
f0100201:	0f b6 82 80 18 10 f0 	movzbl -0xfefe780(%edx),%eax
f0100208:	83 c8 40             	or     $0x40,%eax
f010020b:	0f b6 c0             	movzbl %al,%eax
f010020e:	f7 d0                	not    %eax
f0100210:	21 c1                	and    %eax,%ecx
f0100212:	89 0d 40 f3 10 f0    	mov    %ecx,0xf010f340
		return 0;
f0100218:	b8 00 00 00 00       	mov    $0x0,%eax
f010021d:	e9 9d 00 00 00       	jmp    f01002bf <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100222:	8b 0d 40 f3 10 f0    	mov    0xf010f340,%ecx
f0100228:	f6 c1 40             	test   $0x40,%cl
f010022b:	74 0e                	je     f010023b <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f010022d:	83 c8 80             	or     $0xffffff80,%eax
f0100230:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100232:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100235:	89 0d 40 f3 10 f0    	mov    %ecx,0xf010f340
	}

	shift |= shiftcode[data];
f010023b:	0f b6 d2             	movzbl %dl,%edx
f010023e:	0f b6 82 80 18 10 f0 	movzbl -0xfefe780(%edx),%eax
f0100245:	0b 05 40 f3 10 f0    	or     0xf010f340,%eax
	shift ^= togglecode[data];
f010024b:	0f b6 8a 80 17 10 f0 	movzbl -0xfefe880(%edx),%ecx
f0100252:	31 c8                	xor    %ecx,%eax
f0100254:	a3 40 f3 10 f0       	mov    %eax,0xf010f340

	c = charcode[shift & (CTL | SHIFT)][data];
f0100259:	89 c1                	mov    %eax,%ecx
f010025b:	83 e1 03             	and    $0x3,%ecx
f010025e:	8b 0c 8d 60 17 10 f0 	mov    -0xfefe8a0(,%ecx,4),%ecx
f0100265:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f0100269:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f010026c:	a8 08                	test   $0x8,%al
f010026e:	74 1b                	je     f010028b <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f0100270:	89 da                	mov    %ebx,%edx
f0100272:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100275:	83 f9 19             	cmp    $0x19,%ecx
f0100278:	77 05                	ja     f010027f <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f010027a:	83 eb 20             	sub    $0x20,%ebx
f010027d:	eb 0c                	jmp    f010028b <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f010027f:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100282:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100285:	83 fa 19             	cmp    $0x19,%edx
f0100288:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010028b:	f7 d0                	not    %eax
f010028d:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f010028f:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100291:	f6 c2 06             	test   $0x6,%dl
f0100294:	75 29                	jne    f01002bf <kbd_proc_data+0x103>
f0100296:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010029c:	75 21                	jne    f01002bf <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f010029e:	c7 04 24 24 17 10 f0 	movl   $0xf0101724,(%esp)
f01002a5:	e8 9d 06 00 00       	call   f0100947 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002aa:	ba 92 00 00 00       	mov    $0x92,%edx
f01002af:	b8 03 00 00 00       	mov    $0x3,%eax
f01002b4:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01002b5:	89 d8                	mov    %ebx,%eax
f01002b7:	eb 06                	jmp    f01002bf <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01002b9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01002be:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002bf:	83 c4 14             	add    $0x14,%esp
f01002c2:	5b                   	pop    %ebx
f01002c3:	5d                   	pop    %ebp
f01002c4:	c3                   	ret    

f01002c5 <serial_init>:
		cons_intr(serial_proc_data);
}

void
serial_init(void)
{
f01002c5:	55                   	push   %ebp
f01002c6:	89 e5                	mov    %esp,%ebp
f01002c8:	53                   	push   %ebx
f01002c9:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01002ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01002d3:	89 da                	mov    %ebx,%edx
f01002d5:	ee                   	out    %al,(%dx)
f01002d6:	b2 fb                	mov    $0xfb,%dl
f01002d8:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01002dd:	ee                   	out    %al,(%dx)
f01002de:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01002e3:	b8 0c 00 00 00       	mov    $0xc,%eax
f01002e8:	89 ca                	mov    %ecx,%edx
f01002ea:	ee                   	out    %al,(%dx)
f01002eb:	b2 f9                	mov    $0xf9,%dl
f01002ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01002f2:	ee                   	out    %al,(%dx)
f01002f3:	b2 fb                	mov    $0xfb,%dl
f01002f5:	b8 03 00 00 00       	mov    $0x3,%eax
f01002fa:	ee                   	out    %al,(%dx)
f01002fb:	b2 fc                	mov    $0xfc,%dl
f01002fd:	b8 00 00 00 00       	mov    $0x0,%eax
f0100302:	ee                   	out    %al,(%dx)
f0100303:	b2 f9                	mov    $0xf9,%dl
f0100305:	b8 01 00 00 00       	mov    $0x1,%eax
f010030a:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010030b:	b2 fd                	mov    $0xfd,%dl
f010030d:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010030e:	3c ff                	cmp    $0xff,%al
f0100310:	0f 95 c0             	setne  %al
f0100313:	0f b6 c0             	movzbl %al,%eax
f0100316:	a3 74 f5 10 f0       	mov    %eax,0xf010f574
f010031b:	89 da                	mov    %ebx,%edx
f010031d:	ec                   	in     (%dx),%al
f010031e:	89 ca                	mov    %ecx,%edx
f0100320:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

}
f0100321:	5b                   	pop    %ebx
f0100322:	5d                   	pop    %ebp
f0100323:	c3                   	ret    

f0100324 <cga_init>:
static uint16_t *crt_buf;
static uint16_t crt_pos;

void
cga_init(void)
{
f0100324:	55                   	push   %ebp
f0100325:	89 e5                	mov    %esp,%ebp
f0100327:	57                   	push   %edi
f0100328:	56                   	push   %esi
f0100329:	53                   	push   %ebx
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010032a:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100331:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100338:	5a a5 
	if (*cp != 0xA55A) {
f010033a:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100341:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100345:	74 11                	je     f0100358 <cga_init+0x34>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100347:	c7 05 70 f5 10 f0 b4 	movl   $0x3b4,0xf010f570
f010034e:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100351:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100356:	eb 16                	jmp    f010036e <cga_init+0x4a>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100358:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010035f:	c7 05 70 f5 10 f0 d4 	movl   $0x3d4,0xf010f570
f0100366:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100369:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}
	
	/* Extract cursor location */
	outb(addr_6845, 14);
f010036e:	8b 0d 70 f5 10 f0    	mov    0xf010f570,%ecx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100374:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100379:	89 ca                	mov    %ecx,%edx
f010037b:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010037c:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010037f:	89 da                	mov    %ebx,%edx
f0100381:	ec                   	in     (%dx),%al
f0100382:	0f b6 f0             	movzbl %al,%esi
f0100385:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100388:	b8 0f 00 00 00       	mov    $0xf,%eax
f010038d:	89 ca                	mov    %ecx,%edx
f010038f:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100390:	89 da                	mov    %ebx,%edx
f0100392:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100393:	89 3d 6c f5 10 f0    	mov    %edi,0xf010f56c
	
	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100399:	0f b6 d8             	movzbl %al,%ebx
f010039c:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010039e:	66 89 35 68 f5 10 f0 	mov    %si,0xf010f568
}
f01003a5:	5b                   	pop    %ebx
f01003a6:	5e                   	pop    %esi
f01003a7:	5f                   	pop    %edi
f01003a8:	5d                   	pop    %ebp
f01003a9:	c3                   	ret    

f01003aa <kbd_init>:
	cons_intr(kbd_proc_data);
}

void
kbd_init(void)
{
f01003aa:	55                   	push   %ebp
f01003ab:	89 e5                	mov    %esp,%ebp
}
f01003ad:	5d                   	pop    %ebp
f01003ae:	c3                   	ret    

f01003af <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
void
cons_intr(int (*proc)(void))
{
f01003af:	55                   	push   %ebp
f01003b0:	89 e5                	mov    %esp,%ebp
f01003b2:	53                   	push   %ebx
f01003b3:	83 ec 04             	sub    $0x4,%esp
f01003b6:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01003b9:	eb 2b                	jmp    f01003e6 <cons_intr+0x37>
		if (c == 0)
f01003bb:	85 c0                	test   %eax,%eax
f01003bd:	74 27                	je     f01003e6 <cons_intr+0x37>
			continue;
		cons.buf[cons.wpos++] = c;
f01003bf:	8b 0d 64 f5 10 f0    	mov    0xf010f564,%ecx
f01003c5:	8d 51 01             	lea    0x1(%ecx),%edx
f01003c8:	89 15 64 f5 10 f0    	mov    %edx,0xf010f564
f01003ce:	88 81 60 f3 10 f0    	mov    %al,-0xfef0ca0(%ecx)
		if (cons.wpos == CONSBUFSIZE)
f01003d4:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01003da:	75 0a                	jne    f01003e6 <cons_intr+0x37>
			cons.wpos = 0;
f01003dc:	c7 05 64 f5 10 f0 00 	movl   $0x0,0xf010f564
f01003e3:	00 00 00 
void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01003e6:	ff d3                	call   *%ebx
f01003e8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01003eb:	75 ce                	jne    f01003bb <cons_intr+0xc>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01003ed:	83 c4 04             	add    $0x4,%esp
f01003f0:	5b                   	pop    %ebx
f01003f1:	5d                   	pop    %ebp
f01003f2:	c3                   	ret    

f01003f3 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01003f3:	83 3d 74 f5 10 f0 00 	cmpl   $0x0,0xf010f574
f01003fa:	74 13                	je     f010040f <serial_intr+0x1c>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01003fc:	55                   	push   %ebp
f01003fd:	89 e5                	mov    %esp,%ebp
f01003ff:	83 ec 18             	sub    $0x18,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100402:	c7 04 24 a0 01 10 f0 	movl   $0xf01001a0,(%esp)
f0100409:	e8 a1 ff ff ff       	call   f01003af <cons_intr>
}
f010040e:	c9                   	leave  
f010040f:	f3 c3                	repz ret 

f0100411 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100411:	55                   	push   %ebp
f0100412:	89 e5                	mov    %esp,%ebp
f0100414:	83 ec 18             	sub    $0x18,%esp
	cons_intr(kbd_proc_data);
f0100417:	c7 04 24 bc 01 10 f0 	movl   $0xf01001bc,(%esp)
f010041e:	e8 8c ff ff ff       	call   f01003af <cons_intr>
}
f0100423:	c9                   	leave  
f0100424:	c3                   	ret    

f0100425 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100425:	55                   	push   %ebp
f0100426:	89 e5                	mov    %esp,%ebp
f0100428:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010042b:	e8 c3 ff ff ff       	call   f01003f3 <serial_intr>
	kbd_intr();
f0100430:	e8 dc ff ff ff       	call   f0100411 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100435:	a1 60 f5 10 f0       	mov    0xf010f560,%eax
f010043a:	3b 05 64 f5 10 f0    	cmp    0xf010f564,%eax
f0100440:	74 26                	je     f0100468 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100442:	8d 50 01             	lea    0x1(%eax),%edx
f0100445:	89 15 60 f5 10 f0    	mov    %edx,0xf010f560
f010044b:	0f b6 88 60 f3 10 f0 	movzbl -0xfef0ca0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100452:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100454:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010045a:	75 11                	jne    f010046d <cons_getc+0x48>
			cons.rpos = 0;
f010045c:	c7 05 60 f5 10 f0 00 	movl   $0x0,0xf010f560
f0100463:	00 00 00 
f0100466:	eb 05                	jmp    f010046d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100468:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010046d:	c9                   	leave  
f010046e:	c3                   	ret    

f010046f <cons_putc>:

// output a character to the console
void
cons_putc(int c)
{
f010046f:	55                   	push   %ebp
f0100470:	89 e5                	mov    %esp,%ebp
f0100472:	57                   	push   %edi
f0100473:	56                   	push   %esi
f0100474:	53                   	push   %ebx
f0100475:	83 ec 1c             	sub    $0x1c,%esp
f0100478:	8b 7d 08             	mov    0x8(%ebp),%edi
f010047b:	ba 79 03 00 00       	mov    $0x379,%edx
f0100480:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100481:	84 c0                	test   %al,%al
f0100483:	78 21                	js     f01004a6 <cons_putc+0x37>
f0100485:	bb 00 32 00 00       	mov    $0x3200,%ebx
f010048a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010048f:	be 79 03 00 00       	mov    $0x379,%esi
f0100494:	89 ca                	mov    %ecx,%edx
f0100496:	ec                   	in     (%dx),%al
f0100497:	ec                   	in     (%dx),%al
f0100498:	ec                   	in     (%dx),%al
f0100499:	ec                   	in     (%dx),%al
f010049a:	89 f2                	mov    %esi,%edx
f010049c:	ec                   	in     (%dx),%al
f010049d:	84 c0                	test   %al,%al
f010049f:	78 05                	js     f01004a6 <cons_putc+0x37>
f01004a1:	83 eb 01             	sub    $0x1,%ebx
f01004a4:	75 ee                	jne    f0100494 <cons_putc+0x25>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004a6:	ba 78 03 00 00       	mov    $0x378,%edx
f01004ab:	89 f8                	mov    %edi,%eax
f01004ad:	ee                   	out    %al,(%dx)
f01004ae:	b2 7a                	mov    $0x7a,%dl
f01004b0:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004b5:	ee                   	out    %al,(%dx)
f01004b6:	b8 08 00 00 00       	mov    $0x8,%eax
f01004bb:	ee                   	out    %al,(%dx)
// output a character to the console
void
cons_putc(int c)
{
	lpt_putc(c);
	cga_putc(c);
f01004bc:	89 3c 24             	mov    %edi,(%esp)
f01004bf:	e8 08 00 00 00       	call   f01004cc <cga_putc>
}
f01004c4:	83 c4 1c             	add    $0x1c,%esp
f01004c7:	5b                   	pop    %ebx
f01004c8:	5e                   	pop    %esi
f01004c9:	5f                   	pop    %edi
f01004ca:	5d                   	pop    %ebp
f01004cb:	c3                   	ret    

f01004cc <cga_putc>:



void
cga_putc(int c)
{
f01004cc:	55                   	push   %ebp
f01004cd:	89 e5                	mov    %esp,%ebp
f01004cf:	56                   	push   %esi
f01004d0:	53                   	push   %ebx
f01004d1:	83 ec 10             	sub    $0x10,%esp
f01004d4:	8b 45 08             	mov    0x8(%ebp),%eax
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004d7:	89 c1                	mov    %eax,%ecx
f01004d9:	81 e1 00 ff ff ff    	and    $0xffffff00,%ecx
		c |= 0x0700;
f01004df:	89 c2                	mov    %eax,%edx
f01004e1:	80 ce 07             	or     $0x7,%dh
f01004e4:	85 c9                	test   %ecx,%ecx
f01004e6:	0f 44 c2             	cmove  %edx,%eax

	switch (c & 0xff) {
f01004e9:	0f b6 d0             	movzbl %al,%edx
f01004ec:	83 fa 09             	cmp    $0x9,%edx
f01004ef:	74 7d                	je     f010056e <cga_putc+0xa2>
f01004f1:	83 fa 09             	cmp    $0x9,%edx
f01004f4:	7f 0f                	jg     f0100505 <cga_putc+0x39>
f01004f6:	83 fa 08             	cmp    $0x8,%edx
f01004f9:	74 1c                	je     f0100517 <cga_putc+0x4b>
f01004fb:	90                   	nop
f01004fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100500:	e9 a7 00 00 00       	jmp    f01005ac <cga_putc+0xe0>
f0100505:	83 fa 0a             	cmp    $0xa,%edx
f0100508:	74 3e                	je     f0100548 <cga_putc+0x7c>
f010050a:	83 fa 0d             	cmp    $0xd,%edx
f010050d:	8d 76 00             	lea    0x0(%esi),%esi
f0100510:	74 3e                	je     f0100550 <cga_putc+0x84>
f0100512:	e9 95 00 00 00       	jmp    f01005ac <cga_putc+0xe0>
	case '\b':
		if (crt_pos > 0) {
f0100517:	0f b7 15 68 f5 10 f0 	movzwl 0xf010f568,%edx
f010051e:	66 85 d2             	test   %dx,%dx
f0100521:	0f 84 f0 00 00 00    	je     f0100617 <cga_putc+0x14b>
			crt_pos--;
f0100527:	83 ea 01             	sub    $0x1,%edx
f010052a:	66 89 15 68 f5 10 f0 	mov    %dx,0xf010f568
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100531:	0f b7 d2             	movzwl %dx,%edx
f0100534:	b0 00                	mov    $0x0,%al
f0100536:	83 c8 20             	or     $0x20,%eax
f0100539:	8b 0d 6c f5 10 f0    	mov    0xf010f56c,%ecx
f010053f:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
f0100543:	e9 82 00 00 00       	jmp    f01005ca <cga_putc+0xfe>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f0100548:	66 83 05 68 f5 10 f0 	addw   $0x50,0xf010f568
f010054f:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100550:	0f b7 05 68 f5 10 f0 	movzwl 0xf010f568,%eax
f0100557:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f010055d:	c1 e8 16             	shr    $0x16,%eax
f0100560:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100563:	c1 e0 04             	shl    $0x4,%eax
f0100566:	66 a3 68 f5 10 f0    	mov    %ax,0xf010f568
		break;
f010056c:	eb 5c                	jmp    f01005ca <cga_putc+0xfe>
	case '\t':
		cons_putc(' ');
f010056e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100575:	e8 f5 fe ff ff       	call   f010046f <cons_putc>
		cons_putc(' ');
f010057a:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100581:	e8 e9 fe ff ff       	call   f010046f <cons_putc>
		cons_putc(' ');
f0100586:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010058d:	e8 dd fe ff ff       	call   f010046f <cons_putc>
		cons_putc(' ');
f0100592:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100599:	e8 d1 fe ff ff       	call   f010046f <cons_putc>
		cons_putc(' ');
f010059e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01005a5:	e8 c5 fe ff ff       	call   f010046f <cons_putc>
		break;
f01005aa:	eb 1e                	jmp    f01005ca <cga_putc+0xfe>
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01005ac:	0f b7 15 68 f5 10 f0 	movzwl 0xf010f568,%edx
f01005b3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005b6:	66 89 0d 68 f5 10 f0 	mov    %cx,0xf010f568
f01005bd:	0f b7 d2             	movzwl %dx,%edx
f01005c0:	8b 0d 6c f5 10 f0    	mov    0xf010f56c,%ecx
f01005c6:	66 89 04 51          	mov    %ax,(%ecx,%edx,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005ca:	66 81 3d 68 f5 10 f0 	cmpw   $0x7cf,0xf010f568
f01005d1:	cf 07 
f01005d3:	76 42                	jbe    f0100617 <cga_putc+0x14b>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005d5:	a1 6c f5 10 f0       	mov    0xf010f56c,%eax
f01005da:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005e1:	00 
f01005e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005e8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005ec:	89 04 24             	mov    %eax,(%esp)
f01005ef:	e8 30 0c 00 00       	call   f0101224 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005f4:	8b 15 6c f5 10 f0    	mov    0xf010f56c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005fa:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005ff:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100605:	83 c0 01             	add    $0x1,%eax
f0100608:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f010060d:	75 f0                	jne    f01005ff <cga_putc+0x133>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010060f:	66 83 2d 68 f5 10 f0 	subw   $0x50,0xf010f568
f0100616:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100617:	8b 0d 70 f5 10 f0    	mov    0xf010f570,%ecx
f010061d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100622:	89 ca                	mov    %ecx,%edx
f0100624:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100625:	0f b7 1d 68 f5 10 f0 	movzwl 0xf010f568,%ebx
f010062c:	8d 71 01             	lea    0x1(%ecx),%esi
f010062f:	89 d8                	mov    %ebx,%eax
f0100631:	66 c1 e8 08          	shr    $0x8,%ax
f0100635:	89 f2                	mov    %esi,%edx
f0100637:	ee                   	out    %al,(%dx)
f0100638:	b8 0f 00 00 00       	mov    $0xf,%eax
f010063d:	89 ca                	mov    %ecx,%edx
f010063f:	ee                   	out    %al,(%dx)
f0100640:	89 d8                	mov    %ebx,%eax
f0100642:	89 f2                	mov    %esi,%edx
f0100644:	ee                   	out    %al,(%dx)
	outb(addr_6845, 15);
	outb(addr_6845 + 1, crt_pos);
}
f0100645:	83 c4 10             	add    $0x10,%esp
f0100648:	5b                   	pop    %ebx
f0100649:	5e                   	pop    %esi
f010064a:	5d                   	pop    %ebp
f010064b:	c3                   	ret    

f010064c <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010064c:	55                   	push   %ebp
f010064d:	89 e5                	mov    %esp,%ebp
f010064f:	83 ec 18             	sub    $0x18,%esp
	cga_init();
f0100652:	e8 cd fc ff ff       	call   f0100324 <cga_init>
	kbd_init();
	serial_init();
f0100657:	e8 69 fc ff ff       	call   f01002c5 <serial_init>

	if (!serial_exists)
f010065c:	83 3d 74 f5 10 f0 00 	cmpl   $0x0,0xf010f574
f0100663:	75 0c                	jne    f0100671 <cons_init+0x25>
		cprintf("Serial port does not exist!\n");
f0100665:	c7 04 24 30 17 10 f0 	movl   $0xf0101730,(%esp)
f010066c:	e8 d6 02 00 00       	call   f0100947 <cprintf>
}
f0100671:	c9                   	leave  
f0100672:	c3                   	ret    

f0100673 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100673:	55                   	push   %ebp
f0100674:	89 e5                	mov    %esp,%ebp
f0100676:	83 ec 18             	sub    $0x18,%esp
	cons_putc(c);
f0100679:	8b 45 08             	mov    0x8(%ebp),%eax
f010067c:	89 04 24             	mov    %eax,(%esp)
f010067f:	e8 eb fd ff ff       	call   f010046f <cons_putc>
}
f0100684:	c9                   	leave  
f0100685:	c3                   	ret    

f0100686 <getchar>:

int
getchar(void)
{
f0100686:	55                   	push   %ebp
f0100687:	89 e5                	mov    %esp,%ebp
f0100689:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010068c:	e8 94 fd ff ff       	call   f0100425 <cons_getc>
f0100691:	85 c0                	test   %eax,%eax
f0100693:	74 f7                	je     f010068c <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100695:	c9                   	leave  
f0100696:	c3                   	ret    

f0100697 <iscons>:

int
iscons(int fdnum)
{
f0100697:	55                   	push   %ebp
f0100698:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010069a:	b8 01 00 00 00       	mov    $0x1,%eax
f010069f:	5d                   	pop    %ebp
f01006a0:	c3                   	ret    
f01006a1:	66 90                	xchg   %ax,%ax
f01006a3:	66 90                	xchg   %ax,%ax
f01006a5:	66 90                	xchg   %ax,%ax
f01006a7:	66 90                	xchg   %ax,%ax
f01006a9:	66 90                	xchg   %ax,%ax
f01006ab:	66 90                	xchg   %ax,%ax
f01006ad:	66 90                	xchg   %ax,%ax
f01006af:	90                   	nop

f01006b0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006b0:	55                   	push   %ebp
f01006b1:	89 e5                	mov    %esp,%ebp
f01006b3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b6:	c7 44 24 08 80 19 10 	movl   $0xf0101980,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 9e 19 10 	movl   $0xf010199e,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 a3 19 10 f0 	movl   $0xf01019a3,(%esp)
f01006cd:	e8 75 02 00 00       	call   f0100947 <cprintf>
f01006d2:	c7 44 24 08 0c 1a 10 	movl   $0xf0101a0c,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 ac 19 10 	movl   $0xf01019ac,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 a3 19 10 f0 	movl   $0xf01019a3,(%esp)
f01006e9:	e8 59 02 00 00       	call   f0100947 <cprintf>
	return 0;
}
f01006ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f3:	c9                   	leave  
f01006f4:	c3                   	ret    

f01006f5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01006f5:	55                   	push   %ebp
f01006f6:	89 e5                	mov    %esp,%ebp
f01006f8:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01006fb:	c7 04 24 b5 19 10 f0 	movl   $0xf01019b5,(%esp)
f0100702:	e8 40 02 00 00       	call   f0100947 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 34 1a 10 f0 	movl   $0xf0101a34,(%esp)
f010071e:	e8 24 02 00 00       	call   f0100947 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 87 16 10 	movl   $0x101687,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 87 16 10 	movl   $0xf0101687,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 58 1a 10 f0 	movl   $0xf0101a58,(%esp)
f010073a:	e8 08 02 00 00       	call   f0100947 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 20 f3 10 	movl   $0x10f320,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 20 f3 10 	movl   $0xf010f320,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 7c 1a 10 f0 	movl   $0xf0101a7c,(%esp)
f0100756:	e8 ec 01 00 00       	call   f0100947 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 80 f9 10 	movl   $0x10f980,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 80 f9 10 	movl   $0xf010f980,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 a0 1a 10 f0 	movl   $0xf0101aa0,(%esp)
f0100772:	e8 d0 01 00 00       	call   f0100947 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		(end-_start+1023)/1024);
f0100777:	b8 7f fd 10 f0       	mov    $0xf010fd7f,%eax
f010077c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("Special kernel symbols:\n");
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100781:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100787:	85 c0                	test   %eax,%eax
f0100789:	0f 48 c2             	cmovs  %edx,%eax
f010078c:	c1 f8 0a             	sar    $0xa,%eax
f010078f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100793:	c7 04 24 c4 1a 10 f0 	movl   $0xf0101ac4,(%esp)
f010079a:	e8 a8 01 00 00       	call   f0100947 <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010079f:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a4:	c9                   	leave  
f01007a5:	c3                   	ret    

f01007a6 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01007a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01007ae:	5d                   	pop    %ebp
f01007af:	c3                   	ret    

f01007b0 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007b0:	55                   	push   %ebp
f01007b1:	89 e5                	mov    %esp,%ebp
f01007b3:	57                   	push   %edi
f01007b4:	56                   	push   %esi
f01007b5:	53                   	push   %ebx
f01007b6:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007b9:	c7 04 24 f0 1a 10 f0 	movl   $0xf0101af0,(%esp)
f01007c0:	e8 82 01 00 00       	call   f0100947 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007c5:	c7 04 24 14 1b 10 f0 	movl   $0xf0101b14,(%esp)
f01007cc:	e8 76 01 00 00       	call   f0100947 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007d1:	c7 04 24 ce 19 10 f0 	movl   $0xf01019ce,(%esp)
f01007d8:	e8 83 07 00 00       	call   f0100f60 <readline>
f01007dd:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007df:	85 c0                	test   %eax,%eax
f01007e1:	74 ee                	je     f01007d1 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007e3:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007ea:	be 00 00 00 00       	mov    $0x0,%esi
f01007ef:	eb 0a                	jmp    f01007fb <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007f1:	c6 03 00             	movb   $0x0,(%ebx)
f01007f4:	89 f7                	mov    %esi,%edi
f01007f6:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007f9:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007fb:	0f b6 03             	movzbl (%ebx),%eax
f01007fe:	84 c0                	test   %al,%al
f0100800:	74 6a                	je     f010086c <monitor+0xbc>
f0100802:	0f be c0             	movsbl %al,%eax
f0100805:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100809:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f0100810:	e8 89 09 00 00       	call   f010119e <strchr>
f0100815:	85 c0                	test   %eax,%eax
f0100817:	75 d8                	jne    f01007f1 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100819:	80 3b 00             	cmpb   $0x0,(%ebx)
f010081c:	74 4e                	je     f010086c <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010081e:	83 fe 0f             	cmp    $0xf,%esi
f0100821:	75 16                	jne    f0100839 <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100823:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010082a:	00 
f010082b:	c7 04 24 d7 19 10 f0 	movl   $0xf01019d7,(%esp)
f0100832:	e8 10 01 00 00       	call   f0100947 <cprintf>
f0100837:	eb 98                	jmp    f01007d1 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100839:	8d 7e 01             	lea    0x1(%esi),%edi
f010083c:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100840:	0f b6 03             	movzbl (%ebx),%eax
f0100843:	84 c0                	test   %al,%al
f0100845:	75 0c                	jne    f0100853 <monitor+0xa3>
f0100847:	eb b0                	jmp    f01007f9 <monitor+0x49>
			buf++;
f0100849:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010084c:	0f b6 03             	movzbl (%ebx),%eax
f010084f:	84 c0                	test   %al,%al
f0100851:	74 a6                	je     f01007f9 <monitor+0x49>
f0100853:	0f be c0             	movsbl %al,%eax
f0100856:	89 44 24 04          	mov    %eax,0x4(%esp)
f010085a:	c7 04 24 d2 19 10 f0 	movl   $0xf01019d2,(%esp)
f0100861:	e8 38 09 00 00       	call   f010119e <strchr>
f0100866:	85 c0                	test   %eax,%eax
f0100868:	74 df                	je     f0100849 <monitor+0x99>
f010086a:	eb 8d                	jmp    f01007f9 <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f010086c:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100873:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100874:	85 f6                	test   %esi,%esi
f0100876:	0f 84 55 ff ff ff    	je     f01007d1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010087c:	c7 44 24 04 9e 19 10 	movl   $0xf010199e,0x4(%esp)
f0100883:	f0 
f0100884:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100887:	89 04 24             	mov    %eax,(%esp)
f010088a:	e8 8b 08 00 00       	call   f010111a <strcmp>
f010088f:	85 c0                	test   %eax,%eax
f0100891:	74 1b                	je     f01008ae <monitor+0xfe>
f0100893:	c7 44 24 04 ac 19 10 	movl   $0xf01019ac,0x4(%esp)
f010089a:	f0 
f010089b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010089e:	89 04 24             	mov    %eax,(%esp)
f01008a1:	e8 74 08 00 00       	call   f010111a <strcmp>
f01008a6:	85 c0                	test   %eax,%eax
f01008a8:	75 2f                	jne    f01008d9 <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008aa:	b0 01                	mov    $0x1,%al
f01008ac:	eb 05                	jmp    f01008b3 <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008ae:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008b3:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008b6:	01 d0                	add    %edx,%eax
f01008b8:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008bb:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008bf:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008c2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008c6:	89 34 24             	mov    %esi,(%esp)
f01008c9:	ff 14 85 44 1b 10 f0 	call   *-0xfefe4bc(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008d0:	85 c0                	test   %eax,%eax
f01008d2:	78 1d                	js     f01008f1 <monitor+0x141>
f01008d4:	e9 f8 fe ff ff       	jmp    f01007d1 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008d9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008dc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008e0:	c7 04 24 f4 19 10 f0 	movl   $0xf01019f4,(%esp)
f01008e7:	e8 5b 00 00 00       	call   f0100947 <cprintf>
f01008ec:	e9 e0 fe ff ff       	jmp    f01007d1 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008f1:	83 c4 5c             	add    $0x5c,%esp
f01008f4:	5b                   	pop    %ebx
f01008f5:	5e                   	pop    %esi
f01008f6:	5f                   	pop    %edi
f01008f7:	5d                   	pop    %ebp
f01008f8:	c3                   	ret    

f01008f9 <read_eip>:
// putting at the end of the file seems to prevent inlining.


unsigned
read_eip()
{
f01008f9:	55                   	push   %ebp
f01008fa:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008fc:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008ff:	5d                   	pop    %ebp
f0100900:	c3                   	ret    

f0100901 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100901:	55                   	push   %ebp
f0100902:	89 e5                	mov    %esp,%ebp
f0100904:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100907:	8b 45 08             	mov    0x8(%ebp),%eax
f010090a:	89 04 24             	mov    %eax,(%esp)
f010090d:	e8 61 fd ff ff       	call   f0100673 <cputchar>
	*cnt++;
}
f0100912:	c9                   	leave  
f0100913:	c3                   	ret    

f0100914 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100914:	55                   	push   %ebp
f0100915:	89 e5                	mov    %esp,%ebp
f0100917:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010091a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100921:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100924:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100928:	8b 45 08             	mov    0x8(%ebp),%eax
f010092b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010092f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100932:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100936:	c7 04 24 01 09 10 f0 	movl   $0xf0100901,(%esp)
f010093d:	e8 7a 01 00 00       	call   f0100abc <vprintfmt>
	return cnt;
}
f0100942:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100945:	c9                   	leave  
f0100946:	c3                   	ret    

f0100947 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100947:	55                   	push   %ebp
f0100948:	89 e5                	mov    %esp,%ebp
f010094a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f010094d:	8d 45 0c             	lea    0xc(%ebp),%eax
f0100950:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100954:	8b 45 08             	mov    0x8(%ebp),%eax
f0100957:	89 04 24             	mov    %eax,(%esp)
f010095a:	e8 b5 ff ff ff       	call   f0100914 <vcprintf>
	va_end(ap);

	return cnt;
}
f010095f:	c9                   	leave  
f0100960:	c3                   	ret    
f0100961:	66 90                	xchg   %ax,%ax
f0100963:	66 90                	xchg   %ax,%ax
f0100965:	66 90                	xchg   %ax,%ax
f0100967:	66 90                	xchg   %ax,%ax
f0100969:	66 90                	xchg   %ax,%ax
f010096b:	66 90                	xchg   %ax,%ax
f010096d:	66 90                	xchg   %ax,%ax
f010096f:	90                   	nop

f0100970 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100970:	55                   	push   %ebp
f0100971:	89 e5                	mov    %esp,%ebp
f0100973:	57                   	push   %edi
f0100974:	56                   	push   %esi
f0100975:	53                   	push   %ebx
f0100976:	83 ec 3c             	sub    $0x3c,%esp
f0100979:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010097c:	89 d7                	mov    %edx,%edi
f010097e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100981:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100984:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100987:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010098a:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f010098d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100992:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100995:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0100998:	39 f1                	cmp    %esi,%ecx
f010099a:	72 14                	jb     f01009b0 <printnum+0x40>
f010099c:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f010099f:	76 0f                	jbe    f01009b0 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01009a1:	8b 45 14             	mov    0x14(%ebp),%eax
f01009a4:	8d 70 ff             	lea    -0x1(%eax),%esi
f01009a7:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01009aa:	85 f6                	test   %esi,%esi
f01009ac:	7f 60                	jg     f0100a0e <printnum+0x9e>
f01009ae:	eb 72                	jmp    f0100a22 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01009b0:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01009b3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01009b7:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01009ba:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01009bd:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01009c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01009c5:	8b 44 24 08          	mov    0x8(%esp),%eax
f01009c9:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01009cd:	89 c3                	mov    %eax,%ebx
f01009cf:	89 d6                	mov    %edx,%esi
f01009d1:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01009d4:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01009d7:	89 54 24 08          	mov    %edx,0x8(%esp)
f01009db:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01009df:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009e2:	89 04 24             	mov    %eax,(%esp)
f01009e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01009e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ec:	e8 0f 0a 00 00       	call   f0101400 <__udivdi3>
f01009f1:	89 d9                	mov    %ebx,%ecx
f01009f3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01009f7:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01009fb:	89 04 24             	mov    %eax,(%esp)
f01009fe:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a02:	89 fa                	mov    %edi,%edx
f0100a04:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a07:	e8 64 ff ff ff       	call   f0100970 <printnum>
f0100a0c:	eb 14                	jmp    f0100a22 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100a0e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a12:	8b 45 18             	mov    0x18(%ebp),%eax
f0100a15:	89 04 24             	mov    %eax,(%esp)
f0100a18:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100a1a:	83 ee 01             	sub    $0x1,%esi
f0100a1d:	75 ef                	jne    f0100a0e <printnum+0x9e>
f0100a1f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100a22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a26:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100a2a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a2d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a30:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a34:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a38:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a3b:	89 04 24             	mov    %eax,(%esp)
f0100a3e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100a41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a45:	e8 e6 0a 00 00       	call   f0101530 <__umoddi3>
f0100a4a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a4e:	0f be 80 54 1b 10 f0 	movsbl -0xfefe4ac(%eax),%eax
f0100a55:	89 04 24             	mov    %eax,(%esp)
f0100a58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a5b:	ff d0                	call   *%eax
}
f0100a5d:	83 c4 3c             	add    $0x3c,%esp
f0100a60:	5b                   	pop    %ebx
f0100a61:	5e                   	pop    %esi
f0100a62:	5f                   	pop    %edi
f0100a63:	5d                   	pop    %ebp
f0100a64:	c3                   	ret    

f0100a65 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100a65:	55                   	push   %ebp
f0100a66:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100a68:	83 fa 01             	cmp    $0x1,%edx
f0100a6b:	7e 0e                	jle    f0100a7b <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100a6d:	8b 10                	mov    (%eax),%edx
f0100a6f:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100a72:	89 08                	mov    %ecx,(%eax)
f0100a74:	8b 02                	mov    (%edx),%eax
f0100a76:	8b 52 04             	mov    0x4(%edx),%edx
f0100a79:	eb 22                	jmp    f0100a9d <getuint+0x38>
	else if (lflag)
f0100a7b:	85 d2                	test   %edx,%edx
f0100a7d:	74 10                	je     f0100a8f <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100a7f:	8b 10                	mov    (%eax),%edx
f0100a81:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100a84:	89 08                	mov    %ecx,(%eax)
f0100a86:	8b 02                	mov    (%edx),%eax
f0100a88:	ba 00 00 00 00       	mov    $0x0,%edx
f0100a8d:	eb 0e                	jmp    f0100a9d <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100a8f:	8b 10                	mov    (%eax),%edx
f0100a91:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100a94:	89 08                	mov    %ecx,(%eax)
f0100a96:	8b 02                	mov    (%edx),%eax
f0100a98:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100a9d:	5d                   	pop    %ebp
f0100a9e:	c3                   	ret    

f0100a9f <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100a9f:	55                   	push   %ebp
f0100aa0:	89 e5                	mov    %esp,%ebp
f0100aa2:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100aa5:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100aa9:	8b 10                	mov    (%eax),%edx
f0100aab:	3b 50 04             	cmp    0x4(%eax),%edx
f0100aae:	73 0a                	jae    f0100aba <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ab0:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ab3:	89 08                	mov    %ecx,(%eax)
f0100ab5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ab8:	88 02                	mov    %al,(%edx)
}
f0100aba:	5d                   	pop    %ebp
f0100abb:	c3                   	ret    

f0100abc <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100abc:	55                   	push   %ebp
f0100abd:	89 e5                	mov    %esp,%ebp
f0100abf:	57                   	push   %edi
f0100ac0:	56                   	push   %esi
f0100ac1:	53                   	push   %ebx
f0100ac2:	83 ec 4c             	sub    $0x4c,%esp
f0100ac5:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100ac8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100acb:	eb 18                	jmp    f0100ae5 <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100acd:	85 c0                	test   %eax,%eax
f0100acf:	0f 84 da 03 00 00    	je     f0100eaf <vprintfmt+0x3f3>
				return;
			putch(ch, putdat);
f0100ad5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ad9:	89 04 24             	mov    %eax,(%esp)
f0100adc:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100adf:	89 f3                	mov    %esi,%ebx
f0100ae1:	eb 02                	jmp    f0100ae5 <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100ae3:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100ae5:	8d 73 01             	lea    0x1(%ebx),%esi
f0100ae8:	0f b6 03             	movzbl (%ebx),%eax
f0100aeb:	83 f8 25             	cmp    $0x25,%eax
f0100aee:	75 dd                	jne    f0100acd <vprintfmt+0x11>
f0100af0:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
f0100af4:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0100afb:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
f0100b02:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100b09:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b0e:	eb 1d                	jmp    f0100b2d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b10:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100b12:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0100b16:	eb 15                	jmp    f0100b2d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b18:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100b1a:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0100b1e:	eb 0d                	jmp    f0100b2d <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100b20:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100b23:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b26:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b2d:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100b30:	0f b6 06             	movzbl (%esi),%eax
f0100b33:	0f b6 c8             	movzbl %al,%ecx
f0100b36:	83 e8 23             	sub    $0x23,%eax
f0100b39:	3c 55                	cmp    $0x55,%al
f0100b3b:	0f 87 46 03 00 00    	ja     f0100e87 <vprintfmt+0x3cb>
f0100b41:	0f b6 c0             	movzbl %al,%eax
f0100b44:	ff 24 85 e4 1b 10 f0 	jmp    *-0xfefe41c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100b4b:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100b4e:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				ch = *fmt;
f0100b51:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100b55:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100b58:	83 f9 09             	cmp    $0x9,%ecx
f0100b5b:	77 50                	ja     f0100bad <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b5d:	89 de                	mov    %ebx,%esi
f0100b5f:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100b62:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100b65:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100b68:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100b6c:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100b6f:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100b72:	83 fb 09             	cmp    $0x9,%ebx
f0100b75:	76 eb                	jbe    f0100b62 <vprintfmt+0xa6>
f0100b77:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100b7a:	eb 33                	jmp    f0100baf <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100b7c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100b7f:	8d 48 04             	lea    0x4(%eax),%ecx
f0100b82:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100b85:	8b 00                	mov    (%eax),%eax
f0100b87:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b8a:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100b8c:	eb 21                	jmp    f0100baf <vprintfmt+0xf3>
f0100b8e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100b91:	85 c9                	test   %ecx,%ecx
f0100b93:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b98:	0f 49 c1             	cmovns %ecx,%eax
f0100b9b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b9e:	89 de                	mov    %ebx,%esi
f0100ba0:	eb 8b                	jmp    f0100b2d <vprintfmt+0x71>
f0100ba2:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100ba4:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0100bab:	eb 80                	jmp    f0100b2d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bad:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100baf:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100bb3:	0f 89 74 ff ff ff    	jns    f0100b2d <vprintfmt+0x71>
f0100bb9:	e9 62 ff ff ff       	jmp    f0100b20 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100bbe:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bc1:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100bc3:	e9 65 ff ff ff       	jmp    f0100b2d <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100bc8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bcb:	8d 50 04             	lea    0x4(%eax),%edx
f0100bce:	89 55 14             	mov    %edx,0x14(%ebp)
f0100bd1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100bd5:	8b 00                	mov    (%eax),%eax
f0100bd7:	89 04 24             	mov    %eax,(%esp)
f0100bda:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100bdd:	e9 03 ff ff ff       	jmp    f0100ae5 <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100be2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100be5:	8d 50 04             	lea    0x4(%eax),%edx
f0100be8:	89 55 14             	mov    %edx,0x14(%ebp)
f0100beb:	8b 00                	mov    (%eax),%eax
f0100bed:	99                   	cltd   
f0100bee:	31 d0                	xor    %edx,%eax
f0100bf0:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0100bf2:	83 f8 06             	cmp    $0x6,%eax
f0100bf5:	7f 0a                	jg     f0100c01 <vprintfmt+0x145>
f0100bf7:	83 3c 85 3c 1d 10 f0 	cmpl   $0x0,-0xfefe2c4(,%eax,4)
f0100bfe:	00 
f0100bff:	75 2a                	jne    f0100c2b <vprintfmt+0x16f>
f0100c01:	c7 45 e0 6c 1b 10 f0 	movl   $0xf0101b6c,-0x20(%ebp)
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0100c08:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100c0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c0f:	c7 44 24 08 6c 1b 10 	movl   $0xf0101b6c,0x8(%esp)
f0100c16:	f0 
f0100c17:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c1b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c1e:	89 04 24             	mov    %eax,(%esp)
f0100c21:	e8 96 fe ff ff       	call   f0100abc <vprintfmt>
f0100c26:	e9 ba fe ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
f0100c2b:	c7 45 e4 75 1b 10 f0 	movl   $0xf0101b75,-0x1c(%ebp)
f0100c32:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0100c35:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c39:	c7 44 24 08 75 1b 10 	movl   $0xf0101b75,0x8(%esp)
f0100c40:	f0 
f0100c41:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c45:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c48:	89 04 24             	mov    %eax,(%esp)
f0100c4b:	e8 6c fe ff ff       	call   f0100abc <vprintfmt>
f0100c50:	e9 90 fe ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c55:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100c58:	8b 75 d4             	mov    -0x2c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100c5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c5e:	8d 48 04             	lea    0x4(%eax),%ecx
f0100c61:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100c64:	8b 00                	mov    (%eax),%eax
f0100c66:	89 c1                	mov    %eax,%ecx
				p = "(null)";
f0100c68:	85 c0                	test   %eax,%eax
f0100c6a:	b8 65 1b 10 f0       	mov    $0xf0101b65,%eax
f0100c6f:	0f 45 c1             	cmovne %ecx,%eax
f0100c72:	89 45 c0             	mov    %eax,-0x40(%ebp)
			if (width > 0 && padc != '-')
f0100c75:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0100c79:	74 04                	je     f0100c7f <vprintfmt+0x1c3>
f0100c7b:	85 f6                	test   %esi,%esi
f0100c7d:	7f 19                	jg     f0100c98 <vprintfmt+0x1dc>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100c7f:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100c82:	8d 70 01             	lea    0x1(%eax),%esi
f0100c85:	0f b6 10             	movzbl (%eax),%edx
f0100c88:	0f be c2             	movsbl %dl,%eax
f0100c8b:	85 c0                	test   %eax,%eax
f0100c8d:	0f 85 95 00 00 00    	jne    f0100d28 <vprintfmt+0x26c>
f0100c93:	e9 85 00 00 00       	jmp    f0100d1d <vprintfmt+0x261>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100c98:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c9c:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100c9f:	89 04 24             	mov    %eax,(%esp)
f0100ca2:	e8 9b 03 00 00       	call   f0101042 <strnlen>
f0100ca7:	29 c6                	sub    %eax,%esi
f0100ca9:	89 f0                	mov    %esi,%eax
f0100cab:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100cae:	85 f6                	test   %esi,%esi
f0100cb0:	7e cd                	jle    f0100c7f <vprintfmt+0x1c3>
					putch(padc, putdat);
f0100cb2:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0100cb6:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100cb9:	89 c3                	mov    %eax,%ebx
f0100cbb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100cbf:	89 34 24             	mov    %esi,(%esp)
f0100cc2:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100cc5:	83 eb 01             	sub    $0x1,%ebx
f0100cc8:	75 f1                	jne    f0100cbb <vprintfmt+0x1ff>
f0100cca:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100ccd:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100cd0:	eb ad                	jmp    f0100c7f <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100cd2:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0100cd6:	74 1e                	je     f0100cf6 <vprintfmt+0x23a>
f0100cd8:	0f be d2             	movsbl %dl,%edx
f0100cdb:	83 ea 20             	sub    $0x20,%edx
f0100cde:	83 fa 5e             	cmp    $0x5e,%edx
f0100ce1:	76 13                	jbe    f0100cf6 <vprintfmt+0x23a>
					putch('?', putdat);
f0100ce3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ce6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cea:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100cf1:	ff 55 08             	call   *0x8(%ebp)
f0100cf4:	eb 0d                	jmp    f0100d03 <vprintfmt+0x247>
				else
					putch(ch, putdat);
f0100cf6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100cf9:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100cfd:	89 04 24             	mov    %eax,(%esp)
f0100d00:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d03:	83 ef 01             	sub    $0x1,%edi
f0100d06:	83 c6 01             	add    $0x1,%esi
f0100d09:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100d0d:	0f be c2             	movsbl %dl,%eax
f0100d10:	85 c0                	test   %eax,%eax
f0100d12:	75 20                	jne    f0100d34 <vprintfmt+0x278>
f0100d14:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100d17:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100d1a:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100d1d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100d21:	7f 25                	jg     f0100d48 <vprintfmt+0x28c>
f0100d23:	e9 bd fd ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
f0100d28:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100d2b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100d2e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100d31:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d34:	85 db                	test   %ebx,%ebx
f0100d36:	78 9a                	js     f0100cd2 <vprintfmt+0x216>
f0100d38:	83 eb 01             	sub    $0x1,%ebx
f0100d3b:	79 95                	jns    f0100cd2 <vprintfmt+0x216>
f0100d3d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100d40:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100d43:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d46:	eb d5                	jmp    f0100d1d <vprintfmt+0x261>
f0100d48:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d4b:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100d4e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100d51:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d55:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100d5c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100d5e:	83 eb 01             	sub    $0x1,%ebx
f0100d61:	75 ee                	jne    f0100d51 <vprintfmt+0x295>
f0100d63:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d66:	e9 7a fd ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100d6b:	83 fa 01             	cmp    $0x1,%edx
f0100d6e:	66 90                	xchg   %ax,%ax
f0100d70:	7e 16                	jle    f0100d88 <vprintfmt+0x2cc>
		return va_arg(*ap, long long);
f0100d72:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d75:	8d 50 08             	lea    0x8(%eax),%edx
f0100d78:	89 55 14             	mov    %edx,0x14(%ebp)
f0100d7b:	8b 50 04             	mov    0x4(%eax),%edx
f0100d7e:	8b 00                	mov    (%eax),%eax
f0100d80:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100d83:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0100d86:	eb 32                	jmp    f0100dba <vprintfmt+0x2fe>
	else if (lflag)
f0100d88:	85 d2                	test   %edx,%edx
f0100d8a:	74 18                	je     f0100da4 <vprintfmt+0x2e8>
		return va_arg(*ap, long);
f0100d8c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100d8f:	8d 50 04             	lea    0x4(%eax),%edx
f0100d92:	89 55 14             	mov    %edx,0x14(%ebp)
f0100d95:	8b 30                	mov    (%eax),%esi
f0100d97:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0100d9a:	89 f0                	mov    %esi,%eax
f0100d9c:	c1 f8 1f             	sar    $0x1f,%eax
f0100d9f:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100da2:	eb 16                	jmp    f0100dba <vprintfmt+0x2fe>
	else
		return va_arg(*ap, int);
f0100da4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100da7:	8d 50 04             	lea    0x4(%eax),%edx
f0100daa:	89 55 14             	mov    %edx,0x14(%ebp)
f0100dad:	8b 30                	mov    (%eax),%esi
f0100daf:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0100db2:	89 f0                	mov    %esi,%eax
f0100db4:	c1 f8 1f             	sar    $0x1f,%eax
f0100db7:	89 45 cc             	mov    %eax,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100dba:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100dbd:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100dc0:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100dc5:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100dc9:	0f 89 80 00 00 00    	jns    f0100e4f <vprintfmt+0x393>
				putch('-', putdat);
f0100dcf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100dd3:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0100dda:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0100ddd:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100de0:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100de3:	f7 d8                	neg    %eax
f0100de5:	83 d2 00             	adc    $0x0,%edx
f0100de8:	f7 da                	neg    %edx
			}
			base = 10;
f0100dea:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0100def:	eb 5e                	jmp    f0100e4f <vprintfmt+0x393>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0100df1:	8d 45 14             	lea    0x14(%ebp),%eax
f0100df4:	e8 6c fc ff ff       	call   f0100a65 <getuint>
			base = 10;
f0100df9:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0100dfe:	eb 4f                	jmp    f0100e4f <vprintfmt+0x393>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			
			num = getuint(&ap, lflag);
f0100e00:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e03:	e8 5d fc ff ff       	call   f0100a65 <getuint>
			base = 8;
f0100e08:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0100e0d:	eb 40                	jmp    f0100e4f <vprintfmt+0x393>
			

		// pointer
		case 'p':
			putch('0', putdat);
f0100e0f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e13:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0100e1a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0100e1d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e21:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0100e28:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0100e2b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e2e:	8d 50 04             	lea    0x4(%eax),%edx
f0100e31:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0100e34:	8b 00                	mov    (%eax),%eax
f0100e36:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0100e3b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0100e40:	eb 0d                	jmp    f0100e4f <vprintfmt+0x393>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0100e42:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e45:	e8 1b fc ff ff       	call   f0100a65 <getuint>
			base = 16;
f0100e4a:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0100e4f:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0100e53:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100e57:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100e5a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100e5e:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100e62:	89 04 24             	mov    %eax,(%esp)
f0100e65:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100e69:	89 fa                	mov    %edi,%edx
f0100e6b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e6e:	e8 fd fa ff ff       	call   f0100970 <printnum>
			break;
f0100e73:	e9 6d fc ff ff       	jmp    f0100ae5 <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0100e78:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e7c:	89 0c 24             	mov    %ecx,(%esp)
f0100e7f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100e82:	e9 5e fc ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0100e87:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e8b:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0100e92:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100e95:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0100e99:	0f 84 44 fc ff ff    	je     f0100ae3 <vprintfmt+0x27>
f0100e9f:	89 f3                	mov    %esi,%ebx
f0100ea1:	83 eb 01             	sub    $0x1,%ebx
f0100ea4:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0100ea8:	75 f7                	jne    f0100ea1 <vprintfmt+0x3e5>
f0100eaa:	e9 36 fc ff ff       	jmp    f0100ae5 <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0100eaf:	83 c4 4c             	add    $0x4c,%esp
f0100eb2:	5b                   	pop    %ebx
f0100eb3:	5e                   	pop    %esi
f0100eb4:	5f                   	pop    %edi
f0100eb5:	5d                   	pop    %ebp
f0100eb6:	c3                   	ret    

f0100eb7 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100eb7:	55                   	push   %ebp
f0100eb8:	89 e5                	mov    %esp,%ebp
f0100eba:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0100ebd:	8d 45 14             	lea    0x14(%ebp),%eax
f0100ec0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ec4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100ec7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ecb:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ece:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ed2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ed5:	89 04 24             	mov    %eax,(%esp)
f0100ed8:	e8 df fb ff ff       	call   f0100abc <vprintfmt>
	va_end(ap);
}
f0100edd:	c9                   	leave  
f0100ede:	c3                   	ret    

f0100edf <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0100edf:	55                   	push   %ebp
f0100ee0:	89 e5                	mov    %esp,%ebp
f0100ee2:	83 ec 28             	sub    $0x28,%esp
f0100ee5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ee8:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0100eeb:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100eee:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0100ef2:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100ef5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0100efc:	85 c0                	test   %eax,%eax
f0100efe:	74 30                	je     f0100f30 <vsnprintf+0x51>
f0100f00:	85 d2                	test   %edx,%edx
f0100f02:	7e 2c                	jle    f0100f30 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0100f04:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f07:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f0b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f0e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f12:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0100f15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f19:	c7 04 24 9f 0a 10 f0 	movl   $0xf0100a9f,(%esp)
f0100f20:	e8 97 fb ff ff       	call   f0100abc <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0100f25:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f28:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0100f2b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f2e:	eb 05                	jmp    f0100f35 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0100f30:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0100f35:	c9                   	leave  
f0100f36:	c3                   	ret    

f0100f37 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0100f37:	55                   	push   %ebp
f0100f38:	89 e5                	mov    %esp,%ebp
f0100f3a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0100f3d:	8d 45 14             	lea    0x14(%ebp),%eax
f0100f40:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f44:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f47:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f4b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f52:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f55:	89 04 24             	mov    %eax,(%esp)
f0100f58:	e8 82 ff ff ff       	call   f0100edf <vsnprintf>
	va_end(ap);

	return rc;
}
f0100f5d:	c9                   	leave  
f0100f5e:	c3                   	ret    
f0100f5f:	90                   	nop

f0100f60 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0100f60:	55                   	push   %ebp
f0100f61:	89 e5                	mov    %esp,%ebp
f0100f63:	57                   	push   %edi
f0100f64:	56                   	push   %esi
f0100f65:	53                   	push   %ebx
f0100f66:	83 ec 1c             	sub    $0x1c,%esp
f0100f69:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0100f6c:	85 c0                	test   %eax,%eax
f0100f6e:	74 10                	je     f0100f80 <readline+0x20>
		cprintf("%s", prompt);
f0100f70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f74:	c7 04 24 75 1b 10 f0 	movl   $0xf0101b75,(%esp)
f0100f7b:	e8 c7 f9 ff ff       	call   f0100947 <cprintf>

	i = 0;
	echoing = iscons(0);
f0100f80:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100f87:	e8 0b f7 ff ff       	call   f0100697 <iscons>
f0100f8c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0100f8e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0100f93:	e8 ee f6 ff ff       	call   f0100686 <getchar>
f0100f98:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0100f9a:	85 c0                	test   %eax,%eax
f0100f9c:	79 17                	jns    f0100fb5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0100f9e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fa2:	c7 04 24 58 1d 10 f0 	movl   $0xf0101d58,(%esp)
f0100fa9:	e8 99 f9 ff ff       	call   f0100947 <cprintf>
			return NULL;
f0100fae:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb3:	eb 61                	jmp    f0101016 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0100fb5:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0100fbb:	7f 1c                	jg     f0100fd9 <readline+0x79>
f0100fbd:	83 f8 1f             	cmp    $0x1f,%eax
f0100fc0:	7e 17                	jle    f0100fd9 <readline+0x79>
			if (echoing)
f0100fc2:	85 ff                	test   %edi,%edi
f0100fc4:	74 08                	je     f0100fce <readline+0x6e>
				cputchar(c);
f0100fc6:	89 04 24             	mov    %eax,(%esp)
f0100fc9:	e8 a5 f6 ff ff       	call   f0100673 <cputchar>
			buf[i++] = c;
f0100fce:	88 9e 80 f5 10 f0    	mov    %bl,-0xfef0a80(%esi)
f0100fd4:	8d 76 01             	lea    0x1(%esi),%esi
f0100fd7:	eb ba                	jmp    f0100f93 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0100fd9:	85 f6                	test   %esi,%esi
f0100fdb:	7e 16                	jle    f0100ff3 <readline+0x93>
f0100fdd:	83 fb 08             	cmp    $0x8,%ebx
f0100fe0:	75 11                	jne    f0100ff3 <readline+0x93>
			if (echoing)
f0100fe2:	85 ff                	test   %edi,%edi
f0100fe4:	74 08                	je     f0100fee <readline+0x8e>
				cputchar(c);
f0100fe6:	89 1c 24             	mov    %ebx,(%esp)
f0100fe9:	e8 85 f6 ff ff       	call   f0100673 <cputchar>
			i--;
f0100fee:	83 ee 01             	sub    $0x1,%esi
f0100ff1:	eb a0                	jmp    f0100f93 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0100ff3:	83 fb 0d             	cmp    $0xd,%ebx
f0100ff6:	74 05                	je     f0100ffd <readline+0x9d>
f0100ff8:	83 fb 0a             	cmp    $0xa,%ebx
f0100ffb:	75 96                	jne    f0100f93 <readline+0x33>
			if (echoing)
f0100ffd:	85 ff                	test   %edi,%edi
f0100fff:	90                   	nop
f0101000:	74 08                	je     f010100a <readline+0xaa>
				cputchar(c);
f0101002:	89 1c 24             	mov    %ebx,(%esp)
f0101005:	e8 69 f6 ff ff       	call   f0100673 <cputchar>
			buf[i] = 0;
f010100a:	c6 86 80 f5 10 f0 00 	movb   $0x0,-0xfef0a80(%esi)
			return buf;
f0101011:	b8 80 f5 10 f0       	mov    $0xf010f580,%eax
		}
	}
}
f0101016:	83 c4 1c             	add    $0x1c,%esp
f0101019:	5b                   	pop    %ebx
f010101a:	5e                   	pop    %esi
f010101b:	5f                   	pop    %edi
f010101c:	5d                   	pop    %ebp
f010101d:	c3                   	ret    
f010101e:	66 90                	xchg   %ax,%ax

f0101020 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0101020:	55                   	push   %ebp
f0101021:	89 e5                	mov    %esp,%ebp
f0101023:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101026:	80 3a 00             	cmpb   $0x0,(%edx)
f0101029:	74 10                	je     f010103b <strlen+0x1b>
f010102b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101030:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101033:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101037:	75 f7                	jne    f0101030 <strlen+0x10>
f0101039:	eb 05                	jmp    f0101040 <strlen+0x20>
f010103b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101040:	5d                   	pop    %ebp
f0101041:	c3                   	ret    

f0101042 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101042:	55                   	push   %ebp
f0101043:	89 e5                	mov    %esp,%ebp
f0101045:	53                   	push   %ebx
f0101046:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101049:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010104c:	85 c9                	test   %ecx,%ecx
f010104e:	74 1c                	je     f010106c <strnlen+0x2a>
f0101050:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101053:	74 1e                	je     f0101073 <strnlen+0x31>
f0101055:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f010105a:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010105c:	39 ca                	cmp    %ecx,%edx
f010105e:	74 18                	je     f0101078 <strnlen+0x36>
f0101060:	83 c2 01             	add    $0x1,%edx
f0101063:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101068:	75 f0                	jne    f010105a <strnlen+0x18>
f010106a:	eb 0c                	jmp    f0101078 <strnlen+0x36>
f010106c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101071:	eb 05                	jmp    f0101078 <strnlen+0x36>
f0101073:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f0101078:	5b                   	pop    %ebx
f0101079:	5d                   	pop    %ebp
f010107a:	c3                   	ret    

f010107b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010107b:	55                   	push   %ebp
f010107c:	89 e5                	mov    %esp,%ebp
f010107e:	53                   	push   %ebx
f010107f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101082:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101085:	89 c2                	mov    %eax,%edx
f0101087:	83 c2 01             	add    $0x1,%edx
f010108a:	83 c1 01             	add    $0x1,%ecx
f010108d:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101091:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101094:	84 db                	test   %bl,%bl
f0101096:	75 ef                	jne    f0101087 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0101098:	5b                   	pop    %ebx
f0101099:	5d                   	pop    %ebp
f010109a:	c3                   	ret    

f010109b <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010109b:	55                   	push   %ebp
f010109c:	89 e5                	mov    %esp,%ebp
f010109e:	56                   	push   %esi
f010109f:	53                   	push   %ebx
f01010a0:	8b 75 08             	mov    0x8(%ebp),%esi
f01010a3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01010a6:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01010a9:	85 db                	test   %ebx,%ebx
f01010ab:	74 17                	je     f01010c4 <strncpy+0x29>
f01010ad:	01 f3                	add    %esi,%ebx
f01010af:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f01010b1:	83 c1 01             	add    $0x1,%ecx
f01010b4:	0f b6 02             	movzbl (%edx),%eax
f01010b7:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01010ba:	80 3a 01             	cmpb   $0x1,(%edx)
f01010bd:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01010c0:	39 d9                	cmp    %ebx,%ecx
f01010c2:	75 ed                	jne    f01010b1 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01010c4:	89 f0                	mov    %esi,%eax
f01010c6:	5b                   	pop    %ebx
f01010c7:	5e                   	pop    %esi
f01010c8:	5d                   	pop    %ebp
f01010c9:	c3                   	ret    

f01010ca <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01010ca:	55                   	push   %ebp
f01010cb:	89 e5                	mov    %esp,%ebp
f01010cd:	57                   	push   %edi
f01010ce:	56                   	push   %esi
f01010cf:	53                   	push   %ebx
f01010d0:	8b 7d 08             	mov    0x8(%ebp),%edi
f01010d3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01010d6:	8b 75 10             	mov    0x10(%ebp),%esi
f01010d9:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01010db:	85 f6                	test   %esi,%esi
f01010dd:	74 34                	je     f0101113 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f01010df:	83 fe 01             	cmp    $0x1,%esi
f01010e2:	74 26                	je     f010110a <strlcpy+0x40>
f01010e4:	0f b6 0b             	movzbl (%ebx),%ecx
f01010e7:	84 c9                	test   %cl,%cl
f01010e9:	74 23                	je     f010110e <strlcpy+0x44>
f01010eb:	83 ee 02             	sub    $0x2,%esi
f01010ee:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f01010f3:	83 c0 01             	add    $0x1,%eax
f01010f6:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01010f9:	39 f2                	cmp    %esi,%edx
f01010fb:	74 13                	je     f0101110 <strlcpy+0x46>
f01010fd:	83 c2 01             	add    $0x1,%edx
f0101100:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101104:	84 c9                	test   %cl,%cl
f0101106:	75 eb                	jne    f01010f3 <strlcpy+0x29>
f0101108:	eb 06                	jmp    f0101110 <strlcpy+0x46>
f010110a:	89 f8                	mov    %edi,%eax
f010110c:	eb 02                	jmp    f0101110 <strlcpy+0x46>
f010110e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101110:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101113:	29 f8                	sub    %edi,%eax
}
f0101115:	5b                   	pop    %ebx
f0101116:	5e                   	pop    %esi
f0101117:	5f                   	pop    %edi
f0101118:	5d                   	pop    %ebp
f0101119:	c3                   	ret    

f010111a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010111a:	55                   	push   %ebp
f010111b:	89 e5                	mov    %esp,%ebp
f010111d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101120:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101123:	0f b6 01             	movzbl (%ecx),%eax
f0101126:	84 c0                	test   %al,%al
f0101128:	74 15                	je     f010113f <strcmp+0x25>
f010112a:	3a 02                	cmp    (%edx),%al
f010112c:	75 11                	jne    f010113f <strcmp+0x25>
		p++, q++;
f010112e:	83 c1 01             	add    $0x1,%ecx
f0101131:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101134:	0f b6 01             	movzbl (%ecx),%eax
f0101137:	84 c0                	test   %al,%al
f0101139:	74 04                	je     f010113f <strcmp+0x25>
f010113b:	3a 02                	cmp    (%edx),%al
f010113d:	74 ef                	je     f010112e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010113f:	0f b6 c0             	movzbl %al,%eax
f0101142:	0f b6 12             	movzbl (%edx),%edx
f0101145:	29 d0                	sub    %edx,%eax
}
f0101147:	5d                   	pop    %ebp
f0101148:	c3                   	ret    

f0101149 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101149:	55                   	push   %ebp
f010114a:	89 e5                	mov    %esp,%ebp
f010114c:	56                   	push   %esi
f010114d:	53                   	push   %ebx
f010114e:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101151:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101154:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f0101157:	85 f6                	test   %esi,%esi
f0101159:	74 29                	je     f0101184 <strncmp+0x3b>
f010115b:	0f b6 03             	movzbl (%ebx),%eax
f010115e:	84 c0                	test   %al,%al
f0101160:	74 30                	je     f0101192 <strncmp+0x49>
f0101162:	3a 02                	cmp    (%edx),%al
f0101164:	75 2c                	jne    f0101192 <strncmp+0x49>
f0101166:	8d 43 01             	lea    0x1(%ebx),%eax
f0101169:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f010116b:	89 c3                	mov    %eax,%ebx
f010116d:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101170:	39 f0                	cmp    %esi,%eax
f0101172:	74 17                	je     f010118b <strncmp+0x42>
f0101174:	0f b6 08             	movzbl (%eax),%ecx
f0101177:	84 c9                	test   %cl,%cl
f0101179:	74 17                	je     f0101192 <strncmp+0x49>
f010117b:	83 c0 01             	add    $0x1,%eax
f010117e:	3a 0a                	cmp    (%edx),%cl
f0101180:	74 e9                	je     f010116b <strncmp+0x22>
f0101182:	eb 0e                	jmp    f0101192 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101184:	b8 00 00 00 00       	mov    $0x0,%eax
f0101189:	eb 0f                	jmp    f010119a <strncmp+0x51>
f010118b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101190:	eb 08                	jmp    f010119a <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101192:	0f b6 03             	movzbl (%ebx),%eax
f0101195:	0f b6 12             	movzbl (%edx),%edx
f0101198:	29 d0                	sub    %edx,%eax
}
f010119a:	5b                   	pop    %ebx
f010119b:	5e                   	pop    %esi
f010119c:	5d                   	pop    %ebp
f010119d:	c3                   	ret    

f010119e <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010119e:	55                   	push   %ebp
f010119f:	89 e5                	mov    %esp,%ebp
f01011a1:	53                   	push   %ebx
f01011a2:	8b 45 08             	mov    0x8(%ebp),%eax
f01011a5:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01011a8:	0f b6 18             	movzbl (%eax),%ebx
f01011ab:	84 db                	test   %bl,%bl
f01011ad:	74 1d                	je     f01011cc <strchr+0x2e>
f01011af:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01011b1:	38 d3                	cmp    %dl,%bl
f01011b3:	75 06                	jne    f01011bb <strchr+0x1d>
f01011b5:	eb 1a                	jmp    f01011d1 <strchr+0x33>
f01011b7:	38 ca                	cmp    %cl,%dl
f01011b9:	74 16                	je     f01011d1 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01011bb:	83 c0 01             	add    $0x1,%eax
f01011be:	0f b6 10             	movzbl (%eax),%edx
f01011c1:	84 d2                	test   %dl,%dl
f01011c3:	75 f2                	jne    f01011b7 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f01011c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01011ca:	eb 05                	jmp    f01011d1 <strchr+0x33>
f01011cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01011d1:	5b                   	pop    %ebx
f01011d2:	5d                   	pop    %ebp
f01011d3:	c3                   	ret    

f01011d4 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01011d4:	55                   	push   %ebp
f01011d5:	89 e5                	mov    %esp,%ebp
f01011d7:	53                   	push   %ebx
f01011d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01011db:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f01011de:	0f b6 18             	movzbl (%eax),%ebx
f01011e1:	84 db                	test   %bl,%bl
f01011e3:	74 17                	je     f01011fc <strfind+0x28>
f01011e5:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f01011e7:	38 d3                	cmp    %dl,%bl
f01011e9:	75 07                	jne    f01011f2 <strfind+0x1e>
f01011eb:	eb 0f                	jmp    f01011fc <strfind+0x28>
f01011ed:	38 ca                	cmp    %cl,%dl
f01011ef:	90                   	nop
f01011f0:	74 0a                	je     f01011fc <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01011f2:	83 c0 01             	add    $0x1,%eax
f01011f5:	0f b6 10             	movzbl (%eax),%edx
f01011f8:	84 d2                	test   %dl,%dl
f01011fa:	75 f1                	jne    f01011ed <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f01011fc:	5b                   	pop    %ebx
f01011fd:	5d                   	pop    %ebp
f01011fe:	c3                   	ret    

f01011ff <memset>:


void *
memset(void *v, int c, size_t n)
{
f01011ff:	55                   	push   %ebp
f0101200:	89 e5                	mov    %esp,%ebp
f0101202:	53                   	push   %ebx
f0101203:	8b 45 08             	mov    0x8(%ebp),%eax
f0101206:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101209:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010120c:	89 da                	mov    %ebx,%edx
f010120e:	83 ea 01             	sub    $0x1,%edx
f0101211:	78 0e                	js     f0101221 <memset+0x22>
f0101213:	01 c3                	add    %eax,%ebx
memset(void *v, int c, size_t n)
{
	char *p;
	int m;

	p = v;
f0101215:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f0101217:	83 c2 01             	add    $0x1,%edx
f010121a:	88 4a ff             	mov    %cl,-0x1(%edx)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010121d:	39 da                	cmp    %ebx,%edx
f010121f:	75 f6                	jne    f0101217 <memset+0x18>
		*p++ = c;

	return v;
}
f0101221:	5b                   	pop    %ebx
f0101222:	5d                   	pop    %ebp
f0101223:	c3                   	ret    

f0101224 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f0101224:	55                   	push   %ebp
f0101225:	89 e5                	mov    %esp,%ebp
f0101227:	57                   	push   %edi
f0101228:	56                   	push   %esi
f0101229:	53                   	push   %ebx
f010122a:	8b 45 08             	mov    0x8(%ebp),%eax
f010122d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101230:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101233:	39 c6                	cmp    %eax,%esi
f0101235:	72 0b                	jb     f0101242 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101237:	ba 00 00 00 00       	mov    $0x0,%edx
f010123c:	85 db                	test   %ebx,%ebx
f010123e:	75 2b                	jne    f010126b <memmove+0x47>
f0101240:	eb 37                	jmp    f0101279 <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101242:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f0101245:	39 c8                	cmp    %ecx,%eax
f0101247:	73 ee                	jae    f0101237 <memmove+0x13>
		s += n;
		d += n;
f0101249:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f010124c:	8d 53 ff             	lea    -0x1(%ebx),%edx
f010124f:	85 db                	test   %ebx,%ebx
f0101251:	74 26                	je     f0101279 <memmove+0x55>
f0101253:	f7 db                	neg    %ebx
f0101255:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f0101258:	01 fb                	add    %edi,%ebx
			*--d = *--s;
f010125a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010125e:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f0101261:	83 ea 01             	sub    $0x1,%edx
f0101264:	83 fa ff             	cmp    $0xffffffff,%edx
f0101267:	75 f1                	jne    f010125a <memmove+0x36>
f0101269:	eb 0e                	jmp    f0101279 <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f010126b:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010126f:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101272:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101275:	39 da                	cmp    %ebx,%edx
f0101277:	75 f2                	jne    f010126b <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f0101279:	5b                   	pop    %ebx
f010127a:	5e                   	pop    %esi
f010127b:	5f                   	pop    %edi
f010127c:	5d                   	pop    %ebp
f010127d:	c3                   	ret    

f010127e <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f010127e:	55                   	push   %ebp
f010127f:	89 e5                	mov    %esp,%ebp
f0101281:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101284:	8b 45 10             	mov    0x10(%ebp),%eax
f0101287:	89 44 24 08          	mov    %eax,0x8(%esp)
f010128b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010128e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101292:	8b 45 08             	mov    0x8(%ebp),%eax
f0101295:	89 04 24             	mov    %eax,(%esp)
f0101298:	e8 87 ff ff ff       	call   f0101224 <memmove>
}
f010129d:	c9                   	leave  
f010129e:	c3                   	ret    

f010129f <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010129f:	55                   	push   %ebp
f01012a0:	89 e5                	mov    %esp,%ebp
f01012a2:	57                   	push   %edi
f01012a3:	56                   	push   %esi
f01012a4:	53                   	push   %ebx
f01012a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012a8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012ab:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01012ae:	8d 78 ff             	lea    -0x1(%eax),%edi
f01012b1:	85 c0                	test   %eax,%eax
f01012b3:	74 36                	je     f01012eb <memcmp+0x4c>
		if (*s1 != *s2)
f01012b5:	0f b6 03             	movzbl (%ebx),%eax
f01012b8:	0f b6 0e             	movzbl (%esi),%ecx
f01012bb:	ba 00 00 00 00       	mov    $0x0,%edx
f01012c0:	38 c8                	cmp    %cl,%al
f01012c2:	74 1c                	je     f01012e0 <memcmp+0x41>
f01012c4:	eb 10                	jmp    f01012d6 <memcmp+0x37>
f01012c6:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01012cb:	83 c2 01             	add    $0x1,%edx
f01012ce:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01012d2:	38 c8                	cmp    %cl,%al
f01012d4:	74 0a                	je     f01012e0 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f01012d6:	0f b6 c0             	movzbl %al,%eax
f01012d9:	0f b6 c9             	movzbl %cl,%ecx
f01012dc:	29 c8                	sub    %ecx,%eax
f01012de:	eb 10                	jmp    f01012f0 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01012e0:	39 fa                	cmp    %edi,%edx
f01012e2:	75 e2                	jne    f01012c6 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01012e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01012e9:	eb 05                	jmp    f01012f0 <memcmp+0x51>
f01012eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01012f0:	5b                   	pop    %ebx
f01012f1:	5e                   	pop    %esi
f01012f2:	5f                   	pop    %edi
f01012f3:	5d                   	pop    %ebp
f01012f4:	c3                   	ret    

f01012f5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01012f5:	55                   	push   %ebp
f01012f6:	89 e5                	mov    %esp,%ebp
f01012f8:	53                   	push   %ebx
f01012f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01012fc:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f01012ff:	89 c2                	mov    %eax,%edx
f0101301:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101304:	39 d0                	cmp    %edx,%eax
f0101306:	73 13                	jae    f010131b <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101308:	89 d9                	mov    %ebx,%ecx
f010130a:	38 18                	cmp    %bl,(%eax)
f010130c:	75 06                	jne    f0101314 <memfind+0x1f>
f010130e:	eb 0b                	jmp    f010131b <memfind+0x26>
f0101310:	38 08                	cmp    %cl,(%eax)
f0101312:	74 07                	je     f010131b <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101314:	83 c0 01             	add    $0x1,%eax
f0101317:	39 d0                	cmp    %edx,%eax
f0101319:	75 f5                	jne    f0101310 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010131b:	5b                   	pop    %ebx
f010131c:	5d                   	pop    %ebp
f010131d:	c3                   	ret    

f010131e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010131e:	55                   	push   %ebp
f010131f:	89 e5                	mov    %esp,%ebp
f0101321:	57                   	push   %edi
f0101322:	56                   	push   %esi
f0101323:	53                   	push   %ebx
f0101324:	8b 55 08             	mov    0x8(%ebp),%edx
f0101327:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010132a:	0f b6 0a             	movzbl (%edx),%ecx
f010132d:	80 f9 09             	cmp    $0x9,%cl
f0101330:	74 05                	je     f0101337 <strtol+0x19>
f0101332:	80 f9 20             	cmp    $0x20,%cl
f0101335:	75 10                	jne    f0101347 <strtol+0x29>
		s++;
f0101337:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010133a:	0f b6 0a             	movzbl (%edx),%ecx
f010133d:	80 f9 09             	cmp    $0x9,%cl
f0101340:	74 f5                	je     f0101337 <strtol+0x19>
f0101342:	80 f9 20             	cmp    $0x20,%cl
f0101345:	74 f0                	je     f0101337 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101347:	80 f9 2b             	cmp    $0x2b,%cl
f010134a:	75 0a                	jne    f0101356 <strtol+0x38>
		s++;
f010134c:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f010134f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101354:	eb 11                	jmp    f0101367 <strtol+0x49>
f0101356:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010135b:	80 f9 2d             	cmp    $0x2d,%cl
f010135e:	75 07                	jne    f0101367 <strtol+0x49>
		s++, neg = 1;
f0101360:	83 c2 01             	add    $0x1,%edx
f0101363:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101367:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f010136c:	75 15                	jne    f0101383 <strtol+0x65>
f010136e:	80 3a 30             	cmpb   $0x30,(%edx)
f0101371:	75 10                	jne    f0101383 <strtol+0x65>
f0101373:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101377:	75 0a                	jne    f0101383 <strtol+0x65>
		s += 2, base = 16;
f0101379:	83 c2 02             	add    $0x2,%edx
f010137c:	b8 10 00 00 00       	mov    $0x10,%eax
f0101381:	eb 10                	jmp    f0101393 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f0101383:	85 c0                	test   %eax,%eax
f0101385:	75 0c                	jne    f0101393 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101387:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101389:	80 3a 30             	cmpb   $0x30,(%edx)
f010138c:	75 05                	jne    f0101393 <strtol+0x75>
		s++, base = 8;
f010138e:	83 c2 01             	add    $0x1,%edx
f0101391:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0101393:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101398:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010139b:	0f b6 0a             	movzbl (%edx),%ecx
f010139e:	8d 71 d0             	lea    -0x30(%ecx),%esi
f01013a1:	89 f0                	mov    %esi,%eax
f01013a3:	3c 09                	cmp    $0x9,%al
f01013a5:	77 08                	ja     f01013af <strtol+0x91>
			dig = *s - '0';
f01013a7:	0f be c9             	movsbl %cl,%ecx
f01013aa:	83 e9 30             	sub    $0x30,%ecx
f01013ad:	eb 20                	jmp    f01013cf <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f01013af:	8d 71 9f             	lea    -0x61(%ecx),%esi
f01013b2:	89 f0                	mov    %esi,%eax
f01013b4:	3c 19                	cmp    $0x19,%al
f01013b6:	77 08                	ja     f01013c0 <strtol+0xa2>
			dig = *s - 'a' + 10;
f01013b8:	0f be c9             	movsbl %cl,%ecx
f01013bb:	83 e9 57             	sub    $0x57,%ecx
f01013be:	eb 0f                	jmp    f01013cf <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f01013c0:	8d 71 bf             	lea    -0x41(%ecx),%esi
f01013c3:	89 f0                	mov    %esi,%eax
f01013c5:	3c 19                	cmp    $0x19,%al
f01013c7:	77 16                	ja     f01013df <strtol+0xc1>
			dig = *s - 'A' + 10;
f01013c9:	0f be c9             	movsbl %cl,%ecx
f01013cc:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01013cf:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f01013d2:	7d 0f                	jge    f01013e3 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01013d4:	83 c2 01             	add    $0x1,%edx
f01013d7:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f01013db:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f01013dd:	eb bc                	jmp    f010139b <strtol+0x7d>
f01013df:	89 d8                	mov    %ebx,%eax
f01013e1:	eb 02                	jmp    f01013e5 <strtol+0xc7>
f01013e3:	89 d8                	mov    %ebx,%eax

	if (endptr)
f01013e5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01013e9:	74 05                	je     f01013f0 <strtol+0xd2>
		*endptr = (char *) s;
f01013eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01013ee:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f01013f0:	f7 d8                	neg    %eax
f01013f2:	85 ff                	test   %edi,%edi
f01013f4:	0f 44 c3             	cmove  %ebx,%eax
}
f01013f7:	5b                   	pop    %ebx
f01013f8:	5e                   	pop    %esi
f01013f9:	5f                   	pop    %edi
f01013fa:	5d                   	pop    %ebp
f01013fb:	c3                   	ret    
f01013fc:	66 90                	xchg   %ax,%ax
f01013fe:	66 90                	xchg   %ax,%ax

f0101400 <__udivdi3>:
f0101400:	55                   	push   %ebp
f0101401:	57                   	push   %edi
f0101402:	56                   	push   %esi
f0101403:	83 ec 0c             	sub    $0xc,%esp
f0101406:	8b 44 24 28          	mov    0x28(%esp),%eax
f010140a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010140e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101412:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101416:	85 c0                	test   %eax,%eax
f0101418:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010141c:	89 ea                	mov    %ebp,%edx
f010141e:	89 0c 24             	mov    %ecx,(%esp)
f0101421:	75 2d                	jne    f0101450 <__udivdi3+0x50>
f0101423:	39 e9                	cmp    %ebp,%ecx
f0101425:	77 61                	ja     f0101488 <__udivdi3+0x88>
f0101427:	85 c9                	test   %ecx,%ecx
f0101429:	89 ce                	mov    %ecx,%esi
f010142b:	75 0b                	jne    f0101438 <__udivdi3+0x38>
f010142d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101432:	31 d2                	xor    %edx,%edx
f0101434:	f7 f1                	div    %ecx
f0101436:	89 c6                	mov    %eax,%esi
f0101438:	31 d2                	xor    %edx,%edx
f010143a:	89 e8                	mov    %ebp,%eax
f010143c:	f7 f6                	div    %esi
f010143e:	89 c5                	mov    %eax,%ebp
f0101440:	89 f8                	mov    %edi,%eax
f0101442:	f7 f6                	div    %esi
f0101444:	89 ea                	mov    %ebp,%edx
f0101446:	83 c4 0c             	add    $0xc,%esp
f0101449:	5e                   	pop    %esi
f010144a:	5f                   	pop    %edi
f010144b:	5d                   	pop    %ebp
f010144c:	c3                   	ret    
f010144d:	8d 76 00             	lea    0x0(%esi),%esi
f0101450:	39 e8                	cmp    %ebp,%eax
f0101452:	77 24                	ja     f0101478 <__udivdi3+0x78>
f0101454:	0f bd e8             	bsr    %eax,%ebp
f0101457:	83 f5 1f             	xor    $0x1f,%ebp
f010145a:	75 3c                	jne    f0101498 <__udivdi3+0x98>
f010145c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0101460:	39 34 24             	cmp    %esi,(%esp)
f0101463:	0f 86 9f 00 00 00    	jbe    f0101508 <__udivdi3+0x108>
f0101469:	39 d0                	cmp    %edx,%eax
f010146b:	0f 82 97 00 00 00    	jb     f0101508 <__udivdi3+0x108>
f0101471:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101478:	31 d2                	xor    %edx,%edx
f010147a:	31 c0                	xor    %eax,%eax
f010147c:	83 c4 0c             	add    $0xc,%esp
f010147f:	5e                   	pop    %esi
f0101480:	5f                   	pop    %edi
f0101481:	5d                   	pop    %ebp
f0101482:	c3                   	ret    
f0101483:	90                   	nop
f0101484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101488:	89 f8                	mov    %edi,%eax
f010148a:	f7 f1                	div    %ecx
f010148c:	31 d2                	xor    %edx,%edx
f010148e:	83 c4 0c             	add    $0xc,%esp
f0101491:	5e                   	pop    %esi
f0101492:	5f                   	pop    %edi
f0101493:	5d                   	pop    %ebp
f0101494:	c3                   	ret    
f0101495:	8d 76 00             	lea    0x0(%esi),%esi
f0101498:	89 e9                	mov    %ebp,%ecx
f010149a:	8b 3c 24             	mov    (%esp),%edi
f010149d:	d3 e0                	shl    %cl,%eax
f010149f:	89 c6                	mov    %eax,%esi
f01014a1:	b8 20 00 00 00       	mov    $0x20,%eax
f01014a6:	29 e8                	sub    %ebp,%eax
f01014a8:	89 c1                	mov    %eax,%ecx
f01014aa:	d3 ef                	shr    %cl,%edi
f01014ac:	89 e9                	mov    %ebp,%ecx
f01014ae:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01014b2:	8b 3c 24             	mov    (%esp),%edi
f01014b5:	09 74 24 08          	or     %esi,0x8(%esp)
f01014b9:	89 d6                	mov    %edx,%esi
f01014bb:	d3 e7                	shl    %cl,%edi
f01014bd:	89 c1                	mov    %eax,%ecx
f01014bf:	89 3c 24             	mov    %edi,(%esp)
f01014c2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01014c6:	d3 ee                	shr    %cl,%esi
f01014c8:	89 e9                	mov    %ebp,%ecx
f01014ca:	d3 e2                	shl    %cl,%edx
f01014cc:	89 c1                	mov    %eax,%ecx
f01014ce:	d3 ef                	shr    %cl,%edi
f01014d0:	09 d7                	or     %edx,%edi
f01014d2:	89 f2                	mov    %esi,%edx
f01014d4:	89 f8                	mov    %edi,%eax
f01014d6:	f7 74 24 08          	divl   0x8(%esp)
f01014da:	89 d6                	mov    %edx,%esi
f01014dc:	89 c7                	mov    %eax,%edi
f01014de:	f7 24 24             	mull   (%esp)
f01014e1:	39 d6                	cmp    %edx,%esi
f01014e3:	89 14 24             	mov    %edx,(%esp)
f01014e6:	72 30                	jb     f0101518 <__udivdi3+0x118>
f01014e8:	8b 54 24 04          	mov    0x4(%esp),%edx
f01014ec:	89 e9                	mov    %ebp,%ecx
f01014ee:	d3 e2                	shl    %cl,%edx
f01014f0:	39 c2                	cmp    %eax,%edx
f01014f2:	73 05                	jae    f01014f9 <__udivdi3+0xf9>
f01014f4:	3b 34 24             	cmp    (%esp),%esi
f01014f7:	74 1f                	je     f0101518 <__udivdi3+0x118>
f01014f9:	89 f8                	mov    %edi,%eax
f01014fb:	31 d2                	xor    %edx,%edx
f01014fd:	e9 7a ff ff ff       	jmp    f010147c <__udivdi3+0x7c>
f0101502:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101508:	31 d2                	xor    %edx,%edx
f010150a:	b8 01 00 00 00       	mov    $0x1,%eax
f010150f:	e9 68 ff ff ff       	jmp    f010147c <__udivdi3+0x7c>
f0101514:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101518:	8d 47 ff             	lea    -0x1(%edi),%eax
f010151b:	31 d2                	xor    %edx,%edx
f010151d:	83 c4 0c             	add    $0xc,%esp
f0101520:	5e                   	pop    %esi
f0101521:	5f                   	pop    %edi
f0101522:	5d                   	pop    %ebp
f0101523:	c3                   	ret    
f0101524:	66 90                	xchg   %ax,%ax
f0101526:	66 90                	xchg   %ax,%ax
f0101528:	66 90                	xchg   %ax,%ax
f010152a:	66 90                	xchg   %ax,%ax
f010152c:	66 90                	xchg   %ax,%ax
f010152e:	66 90                	xchg   %ax,%ax

f0101530 <__umoddi3>:
f0101530:	55                   	push   %ebp
f0101531:	57                   	push   %edi
f0101532:	56                   	push   %esi
f0101533:	83 ec 14             	sub    $0x14,%esp
f0101536:	8b 44 24 28          	mov    0x28(%esp),%eax
f010153a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010153e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0101542:	89 c7                	mov    %eax,%edi
f0101544:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101548:	8b 44 24 30          	mov    0x30(%esp),%eax
f010154c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0101550:	89 34 24             	mov    %esi,(%esp)
f0101553:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101557:	85 c0                	test   %eax,%eax
f0101559:	89 c2                	mov    %eax,%edx
f010155b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010155f:	75 17                	jne    f0101578 <__umoddi3+0x48>
f0101561:	39 fe                	cmp    %edi,%esi
f0101563:	76 4b                	jbe    f01015b0 <__umoddi3+0x80>
f0101565:	89 c8                	mov    %ecx,%eax
f0101567:	89 fa                	mov    %edi,%edx
f0101569:	f7 f6                	div    %esi
f010156b:	89 d0                	mov    %edx,%eax
f010156d:	31 d2                	xor    %edx,%edx
f010156f:	83 c4 14             	add    $0x14,%esp
f0101572:	5e                   	pop    %esi
f0101573:	5f                   	pop    %edi
f0101574:	5d                   	pop    %ebp
f0101575:	c3                   	ret    
f0101576:	66 90                	xchg   %ax,%ax
f0101578:	39 f8                	cmp    %edi,%eax
f010157a:	77 54                	ja     f01015d0 <__umoddi3+0xa0>
f010157c:	0f bd e8             	bsr    %eax,%ebp
f010157f:	83 f5 1f             	xor    $0x1f,%ebp
f0101582:	75 5c                	jne    f01015e0 <__umoddi3+0xb0>
f0101584:	8b 7c 24 08          	mov    0x8(%esp),%edi
f0101588:	39 3c 24             	cmp    %edi,(%esp)
f010158b:	0f 87 e7 00 00 00    	ja     f0101678 <__umoddi3+0x148>
f0101591:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101595:	29 f1                	sub    %esi,%ecx
f0101597:	19 c7                	sbb    %eax,%edi
f0101599:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010159d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01015a1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01015a5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01015a9:	83 c4 14             	add    $0x14,%esp
f01015ac:	5e                   	pop    %esi
f01015ad:	5f                   	pop    %edi
f01015ae:	5d                   	pop    %ebp
f01015af:	c3                   	ret    
f01015b0:	85 f6                	test   %esi,%esi
f01015b2:	89 f5                	mov    %esi,%ebp
f01015b4:	75 0b                	jne    f01015c1 <__umoddi3+0x91>
f01015b6:	b8 01 00 00 00       	mov    $0x1,%eax
f01015bb:	31 d2                	xor    %edx,%edx
f01015bd:	f7 f6                	div    %esi
f01015bf:	89 c5                	mov    %eax,%ebp
f01015c1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01015c5:	31 d2                	xor    %edx,%edx
f01015c7:	f7 f5                	div    %ebp
f01015c9:	89 c8                	mov    %ecx,%eax
f01015cb:	f7 f5                	div    %ebp
f01015cd:	eb 9c                	jmp    f010156b <__umoddi3+0x3b>
f01015cf:	90                   	nop
f01015d0:	89 c8                	mov    %ecx,%eax
f01015d2:	89 fa                	mov    %edi,%edx
f01015d4:	83 c4 14             	add    $0x14,%esp
f01015d7:	5e                   	pop    %esi
f01015d8:	5f                   	pop    %edi
f01015d9:	5d                   	pop    %ebp
f01015da:	c3                   	ret    
f01015db:	90                   	nop
f01015dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01015e0:	8b 04 24             	mov    (%esp),%eax
f01015e3:	be 20 00 00 00       	mov    $0x20,%esi
f01015e8:	89 e9                	mov    %ebp,%ecx
f01015ea:	29 ee                	sub    %ebp,%esi
f01015ec:	d3 e2                	shl    %cl,%edx
f01015ee:	89 f1                	mov    %esi,%ecx
f01015f0:	d3 e8                	shr    %cl,%eax
f01015f2:	89 e9                	mov    %ebp,%ecx
f01015f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015f8:	8b 04 24             	mov    (%esp),%eax
f01015fb:	09 54 24 04          	or     %edx,0x4(%esp)
f01015ff:	89 fa                	mov    %edi,%edx
f0101601:	d3 e0                	shl    %cl,%eax
f0101603:	89 f1                	mov    %esi,%ecx
f0101605:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101609:	8b 44 24 10          	mov    0x10(%esp),%eax
f010160d:	d3 ea                	shr    %cl,%edx
f010160f:	89 e9                	mov    %ebp,%ecx
f0101611:	d3 e7                	shl    %cl,%edi
f0101613:	89 f1                	mov    %esi,%ecx
f0101615:	d3 e8                	shr    %cl,%eax
f0101617:	89 e9                	mov    %ebp,%ecx
f0101619:	09 f8                	or     %edi,%eax
f010161b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010161f:	f7 74 24 04          	divl   0x4(%esp)
f0101623:	d3 e7                	shl    %cl,%edi
f0101625:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101629:	89 d7                	mov    %edx,%edi
f010162b:	f7 64 24 08          	mull   0x8(%esp)
f010162f:	39 d7                	cmp    %edx,%edi
f0101631:	89 c1                	mov    %eax,%ecx
f0101633:	89 14 24             	mov    %edx,(%esp)
f0101636:	72 2c                	jb     f0101664 <__umoddi3+0x134>
f0101638:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010163c:	72 22                	jb     f0101660 <__umoddi3+0x130>
f010163e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0101642:	29 c8                	sub    %ecx,%eax
f0101644:	19 d7                	sbb    %edx,%edi
f0101646:	89 e9                	mov    %ebp,%ecx
f0101648:	89 fa                	mov    %edi,%edx
f010164a:	d3 e8                	shr    %cl,%eax
f010164c:	89 f1                	mov    %esi,%ecx
f010164e:	d3 e2                	shl    %cl,%edx
f0101650:	89 e9                	mov    %ebp,%ecx
f0101652:	d3 ef                	shr    %cl,%edi
f0101654:	09 d0                	or     %edx,%eax
f0101656:	89 fa                	mov    %edi,%edx
f0101658:	83 c4 14             	add    $0x14,%esp
f010165b:	5e                   	pop    %esi
f010165c:	5f                   	pop    %edi
f010165d:	5d                   	pop    %ebp
f010165e:	c3                   	ret    
f010165f:	90                   	nop
f0101660:	39 d7                	cmp    %edx,%edi
f0101662:	75 da                	jne    f010163e <__umoddi3+0x10e>
f0101664:	8b 14 24             	mov    (%esp),%edx
f0101667:	89 c1                	mov    %eax,%ecx
f0101669:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010166d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0101671:	eb cb                	jmp    f010163e <__umoddi3+0x10e>
f0101673:	90                   	nop
f0101674:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101678:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010167c:	0f 82 0f ff ff ff    	jb     f0101591 <__umoddi3+0x61>
f0101682:	e9 1a ff ff ff       	jmp    f01015a1 <__umoddi3+0x71>

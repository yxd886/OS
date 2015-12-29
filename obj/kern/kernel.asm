
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
f010004d:	c7 04 24 00 17 10 f0 	movl   $0xf0101700,(%esp)
f0100054:	e8 4f 09 00 00       	call   f01009a8 <cprintf>
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
f0100081:	e8 71 08 00 00       	call   f01008f7 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100086:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008a:	c7 04 24 1c 17 10 f0 	movl   $0xf010171c,(%esp)
f0100091:	e8 12 09 00 00       	call   f01009a8 <cprintf>
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
f01000bf:	e8 9b 11 00 00       	call   f010125f <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c4:	e8 83 05 00 00       	call   f010064c <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000c9:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d0:	00 
f01000d1:	c7 04 24 37 17 10 f0 	movl   $0xf0101737,(%esp)
f01000d8:	e8 cb 08 00 00       	call   f01009a8 <cprintf>




	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000dd:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e4:	e8 56 ff ff ff       	call   f010003f <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000e9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f0:	e8 b1 06 00 00       	call   f01007a6 <monitor>
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
f010011c:	c7 04 24 52 17 10 f0 	movl   $0xf0101752,(%esp)
f0100123:	e8 80 08 00 00       	call   f01009a8 <cprintf>
	vcprintf(fmt, ap);
f0100128:	8d 45 14             	lea    0x14(%ebp),%eax
f010012b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010012f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100132:	89 04 24             	mov    %eax,(%esp)
f0100135:	e8 3b 08 00 00       	call   f0100975 <vcprintf>
	cprintf("\n");
f010013a:	c7 04 24 8e 17 10 f0 	movl   $0xf010178e,(%esp)
f0100141:	e8 62 08 00 00       	call   f01009a8 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100146:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010014d:	e8 54 06 00 00       	call   f01007a6 <monitor>
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
f0100168:	c7 04 24 6a 17 10 f0 	movl   $0xf010176a,(%esp)
f010016f:	e8 34 08 00 00       	call   f01009a8 <cprintf>
	vcprintf(fmt, ap);
f0100174:	8d 45 14             	lea    0x14(%ebp),%eax
f0100177:	89 44 24 04          	mov    %eax,0x4(%esp)
f010017b:	8b 45 10             	mov    0x10(%ebp),%eax
f010017e:	89 04 24             	mov    %eax,(%esp)
f0100181:	e8 ef 07 00 00       	call   f0100975 <vcprintf>
	cprintf("\n");
f0100186:	c7 04 24 8e 17 10 f0 	movl   $0xf010178e,(%esp)
f010018d:	e8 16 08 00 00       	call   f01009a8 <cprintf>
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
f0100201:	0f b6 82 e0 18 10 f0 	movzbl -0xfefe720(%edx),%eax
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
f010023e:	0f b6 82 e0 18 10 f0 	movzbl -0xfefe720(%edx),%eax
f0100245:	0b 05 40 f3 10 f0    	or     0xf010f340,%eax
	shift ^= togglecode[data];
f010024b:	0f b6 8a e0 17 10 f0 	movzbl -0xfefe820(%edx),%ecx
f0100252:	31 c8                	xor    %ecx,%eax
f0100254:	a3 40 f3 10 f0       	mov    %eax,0xf010f340

	c = charcode[shift & (CTL | SHIFT)][data];
f0100259:	89 c1                	mov    %eax,%ecx
f010025b:	83 e1 03             	and    $0x3,%ecx
f010025e:	8b 0c 8d c0 17 10 f0 	mov    -0xfefe840(,%ecx,4),%ecx
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
f010029e:	c7 04 24 84 17 10 f0 	movl   $0xf0101784,(%esp)
f01002a5:	e8 fe 06 00 00       	call   f01009a8 <cprintf>
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
f01005ef:	e8 90 0c 00 00       	call   f0101284 <memmove>
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
f0100665:	c7 04 24 90 17 10 f0 	movl   $0xf0101790,(%esp)
f010066c:	e8 37 03 00 00       	call   f01009a8 <cprintf>
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
f01006b6:	c7 44 24 08 e0 19 10 	movl   $0xf01019e0,0x8(%esp)
f01006bd:	f0 
f01006be:	c7 44 24 04 fe 19 10 	movl   $0xf01019fe,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 03 1a 10 f0 	movl   $0xf0101a03,(%esp)
f01006cd:	e8 d6 02 00 00       	call   f01009a8 <cprintf>
f01006d2:	c7 44 24 08 88 1a 10 	movl   $0xf0101a88,0x8(%esp)
f01006d9:	f0 
f01006da:	c7 44 24 04 0c 1a 10 	movl   $0xf0101a0c,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 03 1a 10 f0 	movl   $0xf0101a03,(%esp)
f01006e9:	e8 ba 02 00 00       	call   f01009a8 <cprintf>
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
f01006fb:	c7 04 24 15 1a 10 f0 	movl   $0xf0101a15,(%esp)
f0100702:	e8 a1 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  _start %08x (virt)  %08x (phys)\n", _start, _start - KERNBASE);
f0100707:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010070e:	00 
f010070f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100716:	f0 
f0100717:	c7 04 24 b0 1a 10 f0 	movl   $0xf0101ab0,(%esp)
f010071e:	e8 85 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100723:	c7 44 24 08 e7 16 10 	movl   $0x1016e7,0x8(%esp)
f010072a:	00 
f010072b:	c7 44 24 04 e7 16 10 	movl   $0xf01016e7,0x4(%esp)
f0100732:	f0 
f0100733:	c7 04 24 d4 1a 10 f0 	movl   $0xf0101ad4,(%esp)
f010073a:	e8 69 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010073f:	c7 44 24 08 20 f3 10 	movl   $0x10f320,0x8(%esp)
f0100746:	00 
f0100747:	c7 44 24 04 20 f3 10 	movl   $0xf010f320,0x4(%esp)
f010074e:	f0 
f010074f:	c7 04 24 f8 1a 10 f0 	movl   $0xf0101af8,(%esp)
f0100756:	e8 4d 02 00 00       	call   f01009a8 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010075b:	c7 44 24 08 80 f9 10 	movl   $0x10f980,0x8(%esp)
f0100762:	00 
f0100763:	c7 44 24 04 80 f9 10 	movl   $0xf010f980,0x4(%esp)
f010076a:	f0 
f010076b:	c7 04 24 1c 1b 10 f0 	movl   $0xf0101b1c,(%esp)
f0100772:	e8 31 02 00 00       	call   f01009a8 <cprintf>
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
f0100793:	c7 04 24 40 1b 10 f0 	movl   $0xf0101b40,(%esp)
f010079a:	e8 09 02 00 00       	call   f01009a8 <cprintf>
		(end-_start+1023)/1024);
	return 0;
}
f010079f:	b8 00 00 00 00       	mov    $0x0,%eax
f01007a4:	c9                   	leave  
f01007a5:	c3                   	ret    

f01007a6 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
f01007a9:	57                   	push   %edi
f01007aa:	56                   	push   %esi
f01007ab:	53                   	push   %ebx
f01007ac:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01007af:	c7 04 24 6c 1b 10 f0 	movl   $0xf0101b6c,(%esp)
f01007b6:	e8 ed 01 00 00       	call   f01009a8 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01007bb:	c7 04 24 90 1b 10 f0 	movl   $0xf0101b90,(%esp)
f01007c2:	e8 e1 01 00 00       	call   f01009a8 <cprintf>


	while (1) {
		buf = readline("K> ");
f01007c7:	c7 04 24 2e 1a 10 f0 	movl   $0xf0101a2e,(%esp)
f01007ce:	e8 ed 07 00 00       	call   f0100fc0 <readline>
f01007d3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01007d5:	85 c0                	test   %eax,%eax
f01007d7:	74 ee                	je     f01007c7 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01007d9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01007e0:	be 00 00 00 00       	mov    $0x0,%esi
f01007e5:	eb 0a                	jmp    f01007f1 <monitor+0x4b>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01007e7:	c6 03 00             	movb   $0x0,(%ebx)
f01007ea:	89 f7                	mov    %esi,%edi
f01007ec:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01007ef:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01007f1:	0f b6 03             	movzbl (%ebx),%eax
f01007f4:	84 c0                	test   %al,%al
f01007f6:	74 6a                	je     f0100862 <monitor+0xbc>
f01007f8:	0f be c0             	movsbl %al,%eax
f01007fb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007ff:	c7 04 24 32 1a 10 f0 	movl   $0xf0101a32,(%esp)
f0100806:	e8 f3 09 00 00       	call   f01011fe <strchr>
f010080b:	85 c0                	test   %eax,%eax
f010080d:	75 d8                	jne    f01007e7 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010080f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100812:	74 4e                	je     f0100862 <monitor+0xbc>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100814:	83 fe 0f             	cmp    $0xf,%esi
f0100817:	75 16                	jne    f010082f <monitor+0x89>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100819:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100820:	00 
f0100821:	c7 04 24 37 1a 10 f0 	movl   $0xf0101a37,(%esp)
f0100828:	e8 7b 01 00 00       	call   f01009a8 <cprintf>
f010082d:	eb 98                	jmp    f01007c7 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010082f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100832:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
		while (*buf && !strchr(WHITESPACE, *buf))
f0100836:	0f b6 03             	movzbl (%ebx),%eax
f0100839:	84 c0                	test   %al,%al
f010083b:	75 0c                	jne    f0100849 <monitor+0xa3>
f010083d:	eb b0                	jmp    f01007ef <monitor+0x49>
			buf++;
f010083f:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100842:	0f b6 03             	movzbl (%ebx),%eax
f0100845:	84 c0                	test   %al,%al
f0100847:	74 a6                	je     f01007ef <monitor+0x49>
f0100849:	0f be c0             	movsbl %al,%eax
f010084c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100850:	c7 04 24 32 1a 10 f0 	movl   $0xf0101a32,(%esp)
f0100857:	e8 a2 09 00 00       	call   f01011fe <strchr>
f010085c:	85 c0                	test   %eax,%eax
f010085e:	74 df                	je     f010083f <monitor+0x99>
f0100860:	eb 8d                	jmp    f01007ef <monitor+0x49>
			buf++;
	}
	argv[argc] = 0;
f0100862:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100869:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010086a:	85 f6                	test   %esi,%esi
f010086c:	0f 84 55 ff ff ff    	je     f01007c7 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100872:	c7 44 24 04 fe 19 10 	movl   $0xf01019fe,0x4(%esp)
f0100879:	f0 
f010087a:	8b 45 a8             	mov    -0x58(%ebp),%eax
f010087d:	89 04 24             	mov    %eax,(%esp)
f0100880:	e8 f5 08 00 00       	call   f010117a <strcmp>
f0100885:	85 c0                	test   %eax,%eax
f0100887:	74 1b                	je     f01008a4 <monitor+0xfe>
f0100889:	c7 44 24 04 0c 1a 10 	movl   $0xf0101a0c,0x4(%esp)
f0100890:	f0 
f0100891:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100894:	89 04 24             	mov    %eax,(%esp)
f0100897:	e8 de 08 00 00       	call   f010117a <strcmp>
f010089c:	85 c0                	test   %eax,%eax
f010089e:	75 2f                	jne    f01008cf <monitor+0x129>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01008a0:	b0 01                	mov    $0x1,%al
f01008a2:	eb 05                	jmp    f01008a9 <monitor+0x103>
		if (strcmp(argv[0], commands[i].name) == 0)
f01008a4:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01008a9:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01008ac:	01 d0                	add    %edx,%eax
f01008ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01008b1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01008b5:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01008b8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01008bc:	89 34 24             	mov    %esi,(%esp)
f01008bf:	ff 14 85 c0 1b 10 f0 	call   *-0xfefe440(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01008c6:	85 c0                	test   %eax,%eax
f01008c8:	78 1d                	js     f01008e7 <monitor+0x141>
f01008ca:	e9 f8 fe ff ff       	jmp    f01007c7 <monitor+0x21>
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01008cf:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01008d2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d6:	c7 04 24 54 1a 10 f0 	movl   $0xf0101a54,(%esp)
f01008dd:	e8 c6 00 00 00       	call   f01009a8 <cprintf>
f01008e2:	e9 e0 fe ff ff       	jmp    f01007c7 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01008e7:	83 c4 5c             	add    $0x5c,%esp
f01008ea:	5b                   	pop    %ebx
f01008eb:	5e                   	pop    %esi
f01008ec:	5f                   	pop    %edi
f01008ed:	5d                   	pop    %ebp
f01008ee:	c3                   	ret    

f01008ef <read_eip>:
// putting at the end of the file seems to prevent inlining.


unsigned
read_eip()
{
f01008ef:	55                   	push   %ebp
f01008f0:	89 e5                	mov    %esp,%ebp
	uint32_t callerpc;
	__asm __volatile("movl 4(%%ebp), %0" : "=r" (callerpc));
f01008f2:	8b 45 04             	mov    0x4(%ebp),%eax
	return callerpc;
}
f01008f5:	5d                   	pop    %ebp
f01008f6:	c3                   	ret    

f01008f7 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008f7:	55                   	push   %ebp
f01008f8:	89 e5                	mov    %esp,%ebp
f01008fa:	56                   	push   %esi
f01008fb:	53                   	push   %ebx
f01008fc:	83 ec 10             	sub    $0x10,%esp

static __inline uint32_t
read_ebp(void)
{
        uint32_t ebp;
        __asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008ff:	89 eb                	mov    %ebp,%ebx
f0100901:	89 de                	mov    %ebx,%esi
	uint32_t ebp = read_ebp(), eip = read_eip();
f0100903:	e8 e7 ff ff ff       	call   f01008ef <read_eip>

    int i, j;
    for (i = 0; ebp != 0; i ++) 
f0100908:	85 db                	test   %ebx,%ebx
f010090a:	74 4a                	je     f0100956 <mon_backtrace+0x5f>
		{
        cprintf("ebp %08x eip %08x args ", ebp, eip);
f010090c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100910:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100914:	c7 04 24 6a 1a 10 f0 	movl   $0xf0101a6a,(%esp)
f010091b:	e8 88 00 00 00       	call   f01009a8 <cprintf>
        uint32_t *args = (uint32_t *)ebp + 2;
        for (j = 0; j < 4; j ++) {
f0100920:	bb 00 00 00 00       	mov    $0x0,%ebx
            cprintf("%08x ", args[j]);
f0100925:	8b 44 9e 08          	mov    0x8(%esi,%ebx,4),%eax
f0100929:	89 44 24 04          	mov    %eax,0x4(%esp)
f010092d:	c7 04 24 82 1a 10 f0 	movl   $0xf0101a82,(%esp)
f0100934:	e8 6f 00 00 00       	call   f01009a8 <cprintf>
    int i, j;
    for (i = 0; ebp != 0; i ++) 
		{
        cprintf("ebp %08x eip %08x args ", ebp, eip);
        uint32_t *args = (uint32_t *)ebp + 2;
        for (j = 0; j < 4; j ++) {
f0100939:	83 c3 01             	add    $0x1,%ebx
f010093c:	83 fb 04             	cmp    $0x4,%ebx
f010093f:	75 e4                	jne    f0100925 <mon_backtrace+0x2e>
            cprintf("%08x ", args[j]);
        }
        cprintf("\n");
f0100941:	c7 04 24 8e 17 10 f0 	movl   $0xf010178e,(%esp)
f0100948:	e8 5b 00 00 00       	call   f01009a8 <cprintf>
        eip = ((uint32_t *)ebp)[1];
f010094d:	8b 46 04             	mov    0x4(%esi),%eax
        ebp = ((uint32_t *)ebp)[0];
f0100950:	8b 36                	mov    (%esi),%esi
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
	uint32_t ebp = read_ebp(), eip = read_eip();

    int i, j;
    for (i = 0; ebp != 0; i ++) 
f0100952:	85 f6                	test   %esi,%esi
f0100954:	75 b6                	jne    f010090c <mon_backtrace+0x15>
        cprintf("\n");
        eip = ((uint32_t *)ebp)[1];
        ebp = ((uint32_t *)ebp)[0];
    }
	return 0;
}
f0100956:	b8 00 00 00 00       	mov    $0x0,%eax
f010095b:	83 c4 10             	add    $0x10,%esp
f010095e:	5b                   	pop    %ebx
f010095f:	5e                   	pop    %esi
f0100960:	5d                   	pop    %ebp
f0100961:	c3                   	ret    

f0100962 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100962:	55                   	push   %ebp
f0100963:	89 e5                	mov    %esp,%ebp
f0100965:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100968:	8b 45 08             	mov    0x8(%ebp),%eax
f010096b:	89 04 24             	mov    %eax,(%esp)
f010096e:	e8 00 fd ff ff       	call   f0100673 <cputchar>
	*cnt++;
}
f0100973:	c9                   	leave  
f0100974:	c3                   	ret    

f0100975 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100975:	55                   	push   %ebp
f0100976:	89 e5                	mov    %esp,%ebp
f0100978:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010097b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100982:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100985:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100989:	8b 45 08             	mov    0x8(%ebp),%eax
f010098c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100990:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100993:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100997:	c7 04 24 62 09 10 f0 	movl   $0xf0100962,(%esp)
f010099e:	e8 79 01 00 00       	call   f0100b1c <vprintfmt>
	return cnt;
}
f01009a3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01009a6:	c9                   	leave  
f01009a7:	c3                   	ret    

f01009a8 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01009a8:	55                   	push   %ebp
f01009a9:	89 e5                	mov    %esp,%ebp
f01009ab:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
	cnt = vcprintf(fmt, ap);
f01009ae:	8d 45 0c             	lea    0xc(%ebp),%eax
f01009b1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01009b8:	89 04 24             	mov    %eax,(%esp)
f01009bb:	e8 b5 ff ff ff       	call   f0100975 <vcprintf>
	va_end(ap);

	return cnt;
}
f01009c0:	c9                   	leave  
f01009c1:	c3                   	ret    
f01009c2:	66 90                	xchg   %ax,%ax
f01009c4:	66 90                	xchg   %ax,%ax
f01009c6:	66 90                	xchg   %ax,%ax
f01009c8:	66 90                	xchg   %ax,%ax
f01009ca:	66 90                	xchg   %ax,%ax
f01009cc:	66 90                	xchg   %ax,%ax
f01009ce:	66 90                	xchg   %ax,%ax

f01009d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01009d0:	55                   	push   %ebp
f01009d1:	89 e5                	mov    %esp,%ebp
f01009d3:	57                   	push   %edi
f01009d4:	56                   	push   %esi
f01009d5:	53                   	push   %ebx
f01009d6:	83 ec 3c             	sub    $0x3c,%esp
f01009d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01009dc:	89 d7                	mov    %edx,%edi
f01009de:	8b 45 08             	mov    0x8(%ebp),%eax
f01009e1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01009e4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01009e7:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01009ea:	8b 45 10             	mov    0x10(%ebp),%eax
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01009ed:	b9 00 00 00 00       	mov    $0x0,%ecx
f01009f2:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01009f5:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01009f8:	39 f1                	cmp    %esi,%ecx
f01009fa:	72 14                	jb     f0100a10 <printnum+0x40>
f01009fc:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01009ff:	76 0f                	jbe    f0100a10 <printnum+0x40>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100a01:	8b 45 14             	mov    0x14(%ebp),%eax
f0100a04:	8d 70 ff             	lea    -0x1(%eax),%esi
f0100a07:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100a0a:	85 f6                	test   %esi,%esi
f0100a0c:	7f 60                	jg     f0100a6e <printnum+0x9e>
f0100a0e:	eb 72                	jmp    f0100a82 <printnum+0xb2>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100a10:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0100a13:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0100a17:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0100a1a:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100a1d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a25:	8b 44 24 08          	mov    0x8(%esp),%eax
f0100a29:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0100a2d:	89 c3                	mov    %eax,%ebx
f0100a2f:	89 d6                	mov    %edx,%esi
f0100a31:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100a34:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0100a37:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a3b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100a3f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a42:	89 04 24             	mov    %eax,(%esp)
f0100a45:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100a48:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a4c:	e8 0f 0a 00 00       	call   f0101460 <__udivdi3>
f0100a51:	89 d9                	mov    %ebx,%ecx
f0100a53:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100a57:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100a5b:	89 04 24             	mov    %eax,(%esp)
f0100a5e:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100a62:	89 fa                	mov    %edi,%edx
f0100a64:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100a67:	e8 64 ff ff ff       	call   f01009d0 <printnum>
f0100a6c:	eb 14                	jmp    f0100a82 <printnum+0xb2>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100a6e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a72:	8b 45 18             	mov    0x18(%ebp),%eax
f0100a75:	89 04 24             	mov    %eax,(%esp)
f0100a78:	ff d3                	call   *%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0100a7a:	83 ee 01             	sub    $0x1,%esi
f0100a7d:	75 ef                	jne    f0100a6e <printnum+0x9e>
f0100a7f:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100a82:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100a86:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0100a8a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100a8d:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100a90:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100a94:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100a98:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100a9b:	89 04 24             	mov    %eax,(%esp)
f0100a9e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100aa1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100aa5:	e8 e6 0a 00 00       	call   f0101590 <__umoddi3>
f0100aaa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100aae:	0f be 80 d0 1b 10 f0 	movsbl -0xfefe430(%eax),%eax
f0100ab5:	89 04 24             	mov    %eax,(%esp)
f0100ab8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100abb:	ff d0                	call   *%eax
}
f0100abd:	83 c4 3c             	add    $0x3c,%esp
f0100ac0:	5b                   	pop    %ebx
f0100ac1:	5e                   	pop    %esi
f0100ac2:	5f                   	pop    %edi
f0100ac3:	5d                   	pop    %ebp
f0100ac4:	c3                   	ret    

f0100ac5 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0100ac5:	55                   	push   %ebp
f0100ac6:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0100ac8:	83 fa 01             	cmp    $0x1,%edx
f0100acb:	7e 0e                	jle    f0100adb <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0100acd:	8b 10                	mov    (%eax),%edx
f0100acf:	8d 4a 08             	lea    0x8(%edx),%ecx
f0100ad2:	89 08                	mov    %ecx,(%eax)
f0100ad4:	8b 02                	mov    (%edx),%eax
f0100ad6:	8b 52 04             	mov    0x4(%edx),%edx
f0100ad9:	eb 22                	jmp    f0100afd <getuint+0x38>
	else if (lflag)
f0100adb:	85 d2                	test   %edx,%edx
f0100add:	74 10                	je     f0100aef <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0100adf:	8b 10                	mov    (%eax),%edx
f0100ae1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100ae4:	89 08                	mov    %ecx,(%eax)
f0100ae6:	8b 02                	mov    (%edx),%eax
f0100ae8:	ba 00 00 00 00       	mov    $0x0,%edx
f0100aed:	eb 0e                	jmp    f0100afd <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0100aef:	8b 10                	mov    (%eax),%edx
f0100af1:	8d 4a 04             	lea    0x4(%edx),%ecx
f0100af4:	89 08                	mov    %ecx,(%eax)
f0100af6:	8b 02                	mov    (%edx),%eax
f0100af8:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0100afd:	5d                   	pop    %ebp
f0100afe:	c3                   	ret    

f0100aff <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100aff:	55                   	push   %ebp
f0100b00:	89 e5                	mov    %esp,%ebp
f0100b02:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100b05:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100b09:	8b 10                	mov    (%eax),%edx
f0100b0b:	3b 50 04             	cmp    0x4(%eax),%edx
f0100b0e:	73 0a                	jae    f0100b1a <sprintputch+0x1b>
		*b->buf++ = ch;
f0100b10:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100b13:	89 08                	mov    %ecx,(%eax)
f0100b15:	8b 45 08             	mov    0x8(%ebp),%eax
f0100b18:	88 02                	mov    %al,(%edx)
}
f0100b1a:	5d                   	pop    %ebp
f0100b1b:	c3                   	ret    

f0100b1c <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0100b1c:	55                   	push   %ebp
f0100b1d:	89 e5                	mov    %esp,%ebp
f0100b1f:	57                   	push   %edi
f0100b20:	56                   	push   %esi
f0100b21:	53                   	push   %ebx
f0100b22:	83 ec 4c             	sub    $0x4c,%esp
f0100b25:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100b28:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100b2b:	eb 18                	jmp    f0100b45 <vprintfmt+0x29>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0100b2d:	85 c0                	test   %eax,%eax
f0100b2f:	0f 84 da 03 00 00    	je     f0100f0f <vprintfmt+0x3f3>
				return;
			putch(ch, putdat);
f0100b35:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100b39:	89 04 24             	mov    %eax,(%esp)
f0100b3c:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100b3f:	89 f3                	mov    %esi,%ebx
f0100b41:	eb 02                	jmp    f0100b45 <vprintfmt+0x29>
			break;
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100b43:	89 f3                	mov    %esi,%ebx
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0100b45:	8d 73 01             	lea    0x1(%ebx),%esi
f0100b48:	0f b6 03             	movzbl (%ebx),%eax
f0100b4b:	83 f8 25             	cmp    $0x25,%eax
f0100b4e:	75 dd                	jne    f0100b2d <vprintfmt+0x11>
f0100b50:	c6 45 d3 20          	movb   $0x20,-0x2d(%ebp)
f0100b54:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0100b5b:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
f0100b62:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0100b69:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b6e:	eb 1d                	jmp    f0100b8d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b70:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0100b72:	c6 45 d3 2d          	movb   $0x2d,-0x2d(%ebp)
f0100b76:	eb 15                	jmp    f0100b8d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b78:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;
			
		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0100b7a:	c6 45 d3 30          	movb   $0x30,-0x2d(%ebp)
f0100b7e:	eb 0d                	jmp    f0100b8d <vprintfmt+0x71>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0100b80:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100b83:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100b86:	c7 45 c4 ff ff ff ff 	movl   $0xffffffff,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100b8d:	8d 5e 01             	lea    0x1(%esi),%ebx
f0100b90:	0f b6 06             	movzbl (%esi),%eax
f0100b93:	0f b6 c8             	movzbl %al,%ecx
f0100b96:	83 e8 23             	sub    $0x23,%eax
f0100b99:	3c 55                	cmp    $0x55,%al
f0100b9b:	0f 87 46 03 00 00    	ja     f0100ee7 <vprintfmt+0x3cb>
f0100ba1:	0f b6 c0             	movzbl %al,%eax
f0100ba4:	ff 24 85 60 1c 10 f0 	jmp    *-0xfefe3a0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0100bab:	8d 41 d0             	lea    -0x30(%ecx),%eax
f0100bae:	89 45 c4             	mov    %eax,-0x3c(%ebp)
				ch = *fmt;
f0100bb1:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0100bb5:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100bb8:	83 f9 09             	cmp    $0x9,%ecx
f0100bbb:	77 50                	ja     f0100c0d <vprintfmt+0xf1>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bbd:	89 de                	mov    %ebx,%esi
f0100bbf:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0100bc2:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0100bc5:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0100bc8:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0100bcc:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0100bcf:	8d 58 d0             	lea    -0x30(%eax),%ebx
f0100bd2:	83 fb 09             	cmp    $0x9,%ebx
f0100bd5:	76 eb                	jbe    f0100bc2 <vprintfmt+0xa6>
f0100bd7:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100bda:	eb 33                	jmp    f0100c0f <vprintfmt+0xf3>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0100bdc:	8b 45 14             	mov    0x14(%ebp),%eax
f0100bdf:	8d 48 04             	lea    0x4(%eax),%ecx
f0100be2:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100be5:	8b 00                	mov    (%eax),%eax
f0100be7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bea:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0100bec:	eb 21                	jmp    f0100c0f <vprintfmt+0xf3>
f0100bee:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100bf1:	85 c9                	test   %ecx,%ecx
f0100bf3:	b8 00 00 00 00       	mov    $0x0,%eax
f0100bf8:	0f 49 c1             	cmovns %ecx,%eax
f0100bfb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100bfe:	89 de                	mov    %ebx,%esi
f0100c00:	eb 8b                	jmp    f0100b8d <vprintfmt+0x71>
f0100c02:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0100c04:	c7 45 c8 01 00 00 00 	movl   $0x1,-0x38(%ebp)
			goto reswitch;
f0100c0b:	eb 80                	jmp    f0100b8d <vprintfmt+0x71>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c0d:	89 de                	mov    %ebx,%esi
		case '#':
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
f0100c0f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100c13:	0f 89 74 ff ff ff    	jns    f0100b8d <vprintfmt+0x71>
f0100c19:	e9 62 ff ff ff       	jmp    f0100b80 <vprintfmt+0x64>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0100c1e:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100c21:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0100c23:	e9 65 ff ff ff       	jmp    f0100b8d <vprintfmt+0x71>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0100c28:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c2b:	8d 50 04             	lea    0x4(%eax),%edx
f0100c2e:	89 55 14             	mov    %edx,0x14(%ebp)
f0100c31:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c35:	8b 00                	mov    (%eax),%eax
f0100c37:	89 04 24             	mov    %eax,(%esp)
f0100c3a:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100c3d:	e9 03 ff ff ff       	jmp    f0100b45 <vprintfmt+0x29>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0100c42:	8b 45 14             	mov    0x14(%ebp),%eax
f0100c45:	8d 50 04             	lea    0x4(%eax),%edx
f0100c48:	89 55 14             	mov    %edx,0x14(%ebp)
f0100c4b:	8b 00                	mov    (%eax),%eax
f0100c4d:	99                   	cltd   
f0100c4e:	31 d0                	xor    %edx,%eax
f0100c50:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err > MAXERROR || (p = error_string[err]) == NULL)
f0100c52:	83 f8 06             	cmp    $0x6,%eax
f0100c55:	7f 0a                	jg     f0100c61 <vprintfmt+0x145>
f0100c57:	83 3c 85 b8 1d 10 f0 	cmpl   $0x0,-0xfefe248(,%eax,4)
f0100c5e:	00 
f0100c5f:	75 2a                	jne    f0100c8b <vprintfmt+0x16f>
f0100c61:	c7 45 e0 e8 1b 10 f0 	movl   $0xf0101be8,-0x20(%ebp)
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0100c68:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100c6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c6f:	c7 44 24 08 e8 1b 10 	movl   $0xf0101be8,0x8(%esp)
f0100c76:	f0 
f0100c77:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100c7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c7e:	89 04 24             	mov    %eax,(%esp)
f0100c81:	e8 96 fe ff ff       	call   f0100b1c <vprintfmt>
f0100c86:	e9 ba fe ff ff       	jmp    f0100b45 <vprintfmt+0x29>
f0100c8b:	c7 45 e4 f1 1b 10 f0 	movl   $0xf0101bf1,-0x1c(%ebp)
f0100c92:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0100c95:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c99:	c7 44 24 08 f1 1b 10 	movl   $0xf0101bf1,0x8(%esp)
f0100ca0:	f0 
f0100ca1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100ca5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ca8:	89 04 24             	mov    %eax,(%esp)
f0100cab:	e8 6c fe ff ff       	call   f0100b1c <vprintfmt>
f0100cb0:	e9 90 fe ff ff       	jmp    f0100b45 <vprintfmt+0x29>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0100cb5:	8b 55 c4             	mov    -0x3c(%ebp),%edx
f0100cb8:	8b 75 d4             	mov    -0x2c(%ebp),%esi
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0100cbb:	8b 45 14             	mov    0x14(%ebp),%eax
f0100cbe:	8d 48 04             	lea    0x4(%eax),%ecx
f0100cc1:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0100cc4:	8b 00                	mov    (%eax),%eax
f0100cc6:	89 c1                	mov    %eax,%ecx
				p = "(null)";
f0100cc8:	85 c0                	test   %eax,%eax
f0100cca:	b8 e1 1b 10 f0       	mov    $0xf0101be1,%eax
f0100ccf:	0f 45 c1             	cmovne %ecx,%eax
f0100cd2:	89 45 c0             	mov    %eax,-0x40(%ebp)
			if (width > 0 && padc != '-')
f0100cd5:	80 7d d3 2d          	cmpb   $0x2d,-0x2d(%ebp)
f0100cd9:	74 04                	je     f0100cdf <vprintfmt+0x1c3>
f0100cdb:	85 f6                	test   %esi,%esi
f0100cdd:	7f 19                	jg     f0100cf8 <vprintfmt+0x1dc>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100cdf:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100ce2:	8d 70 01             	lea    0x1(%eax),%esi
f0100ce5:	0f b6 10             	movzbl (%eax),%edx
f0100ce8:	0f be c2             	movsbl %dl,%eax
f0100ceb:	85 c0                	test   %eax,%eax
f0100ced:	0f 85 95 00 00 00    	jne    f0100d88 <vprintfmt+0x26c>
f0100cf3:	e9 85 00 00 00       	jmp    f0100d7d <vprintfmt+0x261>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100cf8:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100cfc:	8b 45 c0             	mov    -0x40(%ebp),%eax
f0100cff:	89 04 24             	mov    %eax,(%esp)
f0100d02:	e8 9b 03 00 00       	call   f01010a2 <strnlen>
f0100d07:	29 c6                	sub    %eax,%esi
f0100d09:	89 f0                	mov    %esi,%eax
f0100d0b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100d0e:	85 f6                	test   %esi,%esi
f0100d10:	7e cd                	jle    f0100cdf <vprintfmt+0x1c3>
					putch(padc, putdat);
f0100d12:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0100d16:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100d19:	89 c3                	mov    %eax,%ebx
f0100d1b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100d1f:	89 34 24             	mov    %esi,(%esp)
f0100d22:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0100d25:	83 eb 01             	sub    $0x1,%ebx
f0100d28:	75 f1                	jne    f0100d1b <vprintfmt+0x1ff>
f0100d2a:	89 5d d4             	mov    %ebx,-0x2c(%ebp)
f0100d2d:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100d30:	eb ad                	jmp    f0100cdf <vprintfmt+0x1c3>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0100d32:	83 7d c8 00          	cmpl   $0x0,-0x38(%ebp)
f0100d36:	74 1e                	je     f0100d56 <vprintfmt+0x23a>
f0100d38:	0f be d2             	movsbl %dl,%edx
f0100d3b:	83 ea 20             	sub    $0x20,%edx
f0100d3e:	83 fa 5e             	cmp    $0x5e,%edx
f0100d41:	76 13                	jbe    f0100d56 <vprintfmt+0x23a>
					putch('?', putdat);
f0100d43:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d46:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d4a:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0100d51:	ff 55 08             	call   *0x8(%ebp)
f0100d54:	eb 0d                	jmp    f0100d63 <vprintfmt+0x247>
				else
					putch(ch, putdat);
f0100d56:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0100d59:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100d5d:	89 04 24             	mov    %eax,(%esp)
f0100d60:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d63:	83 ef 01             	sub    $0x1,%edi
f0100d66:	83 c6 01             	add    $0x1,%esi
f0100d69:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f0100d6d:	0f be c2             	movsbl %dl,%eax
f0100d70:	85 c0                	test   %eax,%eax
f0100d72:	75 20                	jne    f0100d94 <vprintfmt+0x278>
f0100d74:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100d77:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100d7a:	8b 5d 10             	mov    0x10(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100d7d:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0100d81:	7f 25                	jg     f0100da8 <vprintfmt+0x28c>
f0100d83:	e9 bd fd ff ff       	jmp    f0100b45 <vprintfmt+0x29>
f0100d88:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0100d8b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0100d8e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100d91:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0100d94:	85 db                	test   %ebx,%ebx
f0100d96:	78 9a                	js     f0100d32 <vprintfmt+0x216>
f0100d98:	83 eb 01             	sub    $0x1,%ebx
f0100d9b:	79 95                	jns    f0100d32 <vprintfmt+0x216>
f0100d9d:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100da0:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0100da3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100da6:	eb d5                	jmp    f0100d7d <vprintfmt+0x261>
f0100da8:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dab:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0100dae:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0100db1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100db5:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0100dbc:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0100dbe:	83 eb 01             	sub    $0x1,%ebx
f0100dc1:	75 ee                	jne    f0100db1 <vprintfmt+0x295>
f0100dc3:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0100dc6:	e9 7a fd ff ff       	jmp    f0100b45 <vprintfmt+0x29>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0100dcb:	83 fa 01             	cmp    $0x1,%edx
f0100dce:	66 90                	xchg   %ax,%ax
f0100dd0:	7e 16                	jle    f0100de8 <vprintfmt+0x2cc>
		return va_arg(*ap, long long);
f0100dd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd5:	8d 50 08             	lea    0x8(%eax),%edx
f0100dd8:	89 55 14             	mov    %edx,0x14(%ebp)
f0100ddb:	8b 50 04             	mov    0x4(%eax),%edx
f0100dde:	8b 00                	mov    (%eax),%eax
f0100de0:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100de3:	89 55 cc             	mov    %edx,-0x34(%ebp)
f0100de6:	eb 32                	jmp    f0100e1a <vprintfmt+0x2fe>
	else if (lflag)
f0100de8:	85 d2                	test   %edx,%edx
f0100dea:	74 18                	je     f0100e04 <vprintfmt+0x2e8>
		return va_arg(*ap, long);
f0100dec:	8b 45 14             	mov    0x14(%ebp),%eax
f0100def:	8d 50 04             	lea    0x4(%eax),%edx
f0100df2:	89 55 14             	mov    %edx,0x14(%ebp)
f0100df5:	8b 30                	mov    (%eax),%esi
f0100df7:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0100dfa:	89 f0                	mov    %esi,%eax
f0100dfc:	c1 f8 1f             	sar    $0x1f,%eax
f0100dff:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100e02:	eb 16                	jmp    f0100e1a <vprintfmt+0x2fe>
	else
		return va_arg(*ap, int);
f0100e04:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e07:	8d 50 04             	lea    0x4(%eax),%edx
f0100e0a:	89 55 14             	mov    %edx,0x14(%ebp)
f0100e0d:	8b 30                	mov    (%eax),%esi
f0100e0f:	89 75 c8             	mov    %esi,-0x38(%ebp)
f0100e12:	89 f0                	mov    %esi,%eax
f0100e14:	c1 f8 1f             	sar    $0x1f,%eax
f0100e17:	89 45 cc             	mov    %eax,-0x34(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0100e1a:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100e1d:	8b 55 cc             	mov    -0x34(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0100e20:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0100e25:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0100e29:	0f 89 80 00 00 00    	jns    f0100eaf <vprintfmt+0x393>
				putch('-', putdat);
f0100e2f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e33:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0100e3a:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0100e3d:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0100e40:	8b 55 cc             	mov    -0x34(%ebp),%edx
f0100e43:	f7 d8                	neg    %eax
f0100e45:	83 d2 00             	adc    $0x0,%edx
f0100e48:	f7 da                	neg    %edx
			}
			base = 10;
f0100e4a:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0100e4f:	eb 5e                	jmp    f0100eaf <vprintfmt+0x393>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0100e51:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e54:	e8 6c fc ff ff       	call   f0100ac5 <getuint>
			base = 10;
f0100e59:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0100e5e:	eb 4f                	jmp    f0100eaf <vprintfmt+0x393>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			
			num = getuint(&ap, lflag);
f0100e60:	8d 45 14             	lea    0x14(%ebp),%eax
f0100e63:	e8 5d fc ff ff       	call   f0100ac5 <getuint>
			base = 8;
f0100e68:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0100e6d:	eb 40                	jmp    f0100eaf <vprintfmt+0x393>
			

		// pointer
		case 'p':
			putch('0', putdat);
f0100e6f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e73:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0100e7a:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0100e7d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100e81:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0100e88:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0100e8b:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e8e:	8d 50 04             	lea    0x4(%eax),%edx
f0100e91:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0100e94:	8b 00                	mov    (%eax),%eax
f0100e96:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0100e9b:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0100ea0:	eb 0d                	jmp    f0100eaf <vprintfmt+0x393>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0100ea2:	8d 45 14             	lea    0x14(%ebp),%eax
f0100ea5:	e8 1b fc ff ff       	call   f0100ac5 <getuint>
			base = 16;
f0100eaa:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0100eaf:	0f be 75 d3          	movsbl -0x2d(%ebp),%esi
f0100eb3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0100eb7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100eba:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0100ebe:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0100ec2:	89 04 24             	mov    %eax,(%esp)
f0100ec5:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100ec9:	89 fa                	mov    %edi,%edx
f0100ecb:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ece:	e8 fd fa ff ff       	call   f01009d0 <printnum>
			break;
f0100ed3:	e9 6d fc ff ff       	jmp    f0100b45 <vprintfmt+0x29>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0100ed8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100edc:	89 0c 24             	mov    %ecx,(%esp)
f0100edf:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100ee2:	e9 5e fc ff ff       	jmp    f0100b45 <vprintfmt+0x29>
			
		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0100ee7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100eeb:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0100ef2:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0100ef5:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0100ef9:	0f 84 44 fc ff ff    	je     f0100b43 <vprintfmt+0x27>
f0100eff:	89 f3                	mov    %esi,%ebx
f0100f01:	83 eb 01             	sub    $0x1,%ebx
f0100f04:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0100f08:	75 f7                	jne    f0100f01 <vprintfmt+0x3e5>
f0100f0a:	e9 36 fc ff ff       	jmp    f0100b45 <vprintfmt+0x29>
				/* do nothing */;
			break;
		}
	}
}
f0100f0f:	83 c4 4c             	add    $0x4c,%esp
f0100f12:	5b                   	pop    %ebx
f0100f13:	5e                   	pop    %esi
f0100f14:	5f                   	pop    %edi
f0100f15:	5d                   	pop    %ebp
f0100f16:	c3                   	ret    

f0100f17 <printfmt>:

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0100f17:	55                   	push   %ebp
f0100f18:	89 e5                	mov    %esp,%ebp
f0100f1a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
	vprintfmt(putch, putdat, fmt, ap);
f0100f1d:	8d 45 14             	lea    0x14(%ebp),%eax
f0100f20:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f24:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f27:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f2b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f2e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f32:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f35:	89 04 24             	mov    %eax,(%esp)
f0100f38:	e8 df fb ff ff       	call   f0100b1c <vprintfmt>
	va_end(ap);
}
f0100f3d:	c9                   	leave  
f0100f3e:	c3                   	ret    

f0100f3f <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0100f3f:	55                   	push   %ebp
f0100f40:	89 e5                	mov    %esp,%ebp
f0100f42:	83 ec 28             	sub    $0x28,%esp
f0100f45:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f48:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0100f4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100f4e:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0100f52:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0100f55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0100f5c:	85 c0                	test   %eax,%eax
f0100f5e:	74 30                	je     f0100f90 <vsnprintf+0x51>
f0100f60:	85 d2                	test   %edx,%edx
f0100f62:	7e 2c                	jle    f0100f90 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0100f64:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f67:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100f6b:	8b 45 10             	mov    0x10(%ebp),%eax
f0100f6e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100f72:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0100f75:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f79:	c7 04 24 ff 0a 10 f0 	movl   $0xf0100aff,(%esp)
f0100f80:	e8 97 fb ff ff       	call   f0100b1c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0100f85:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0100f88:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0100f8b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100f8e:	eb 05                	jmp    f0100f95 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0100f90:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0100f95:	c9                   	leave  
f0100f96:	c3                   	ret    

f0100f97 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0100f97:	55                   	push   %ebp
f0100f98:	89 e5                	mov    %esp,%ebp
f0100f9a:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
	rc = vsnprintf(buf, n, fmt, ap);
f0100f9d:	8d 45 14             	lea    0x14(%ebp),%eax
f0100fa0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100fa4:	8b 45 10             	mov    0x10(%ebp),%eax
f0100fa7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100fab:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fae:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fb2:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fb5:	89 04 24             	mov    %eax,(%esp)
f0100fb8:	e8 82 ff ff ff       	call   f0100f3f <vsnprintf>
	va_end(ap);

	return rc;
}
f0100fbd:	c9                   	leave  
f0100fbe:	c3                   	ret    
f0100fbf:	90                   	nop

f0100fc0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0100fc0:	55                   	push   %ebp
f0100fc1:	89 e5                	mov    %esp,%ebp
f0100fc3:	57                   	push   %edi
f0100fc4:	56                   	push   %esi
f0100fc5:	53                   	push   %ebx
f0100fc6:	83 ec 1c             	sub    $0x1c,%esp
f0100fc9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0100fcc:	85 c0                	test   %eax,%eax
f0100fce:	74 10                	je     f0100fe0 <readline+0x20>
		cprintf("%s", prompt);
f0100fd0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fd4:	c7 04 24 f1 1b 10 f0 	movl   $0xf0101bf1,(%esp)
f0100fdb:	e8 c8 f9 ff ff       	call   f01009a8 <cprintf>

	i = 0;
	echoing = iscons(0);
f0100fe0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100fe7:	e8 ab f6 ff ff       	call   f0100697 <iscons>
f0100fec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0100fee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0100ff3:	e8 8e f6 ff ff       	call   f0100686 <getchar>
f0100ff8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0100ffa:	85 c0                	test   %eax,%eax
f0100ffc:	79 17                	jns    f0101015 <readline+0x55>
			cprintf("read error: %e\n", c);
f0100ffe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101002:	c7 04 24 d4 1d 10 f0 	movl   $0xf0101dd4,(%esp)
f0101009:	e8 9a f9 ff ff       	call   f01009a8 <cprintf>
			return NULL;
f010100e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101013:	eb 61                	jmp    f0101076 <readline+0xb6>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101015:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010101b:	7f 1c                	jg     f0101039 <readline+0x79>
f010101d:	83 f8 1f             	cmp    $0x1f,%eax
f0101020:	7e 17                	jle    f0101039 <readline+0x79>
			if (echoing)
f0101022:	85 ff                	test   %edi,%edi
f0101024:	74 08                	je     f010102e <readline+0x6e>
				cputchar(c);
f0101026:	89 04 24             	mov    %eax,(%esp)
f0101029:	e8 45 f6 ff ff       	call   f0100673 <cputchar>
			buf[i++] = c;
f010102e:	88 9e 80 f5 10 f0    	mov    %bl,-0xfef0a80(%esi)
f0101034:	8d 76 01             	lea    0x1(%esi),%esi
f0101037:	eb ba                	jmp    f0100ff3 <readline+0x33>
		} else if (c == '\b' && i > 0) {
f0101039:	85 f6                	test   %esi,%esi
f010103b:	7e 16                	jle    f0101053 <readline+0x93>
f010103d:	83 fb 08             	cmp    $0x8,%ebx
f0101040:	75 11                	jne    f0101053 <readline+0x93>
			if (echoing)
f0101042:	85 ff                	test   %edi,%edi
f0101044:	74 08                	je     f010104e <readline+0x8e>
				cputchar(c);
f0101046:	89 1c 24             	mov    %ebx,(%esp)
f0101049:	e8 25 f6 ff ff       	call   f0100673 <cputchar>
			i--;
f010104e:	83 ee 01             	sub    $0x1,%esi
f0101051:	eb a0                	jmp    f0100ff3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0101053:	83 fb 0d             	cmp    $0xd,%ebx
f0101056:	74 05                	je     f010105d <readline+0x9d>
f0101058:	83 fb 0a             	cmp    $0xa,%ebx
f010105b:	75 96                	jne    f0100ff3 <readline+0x33>
			if (echoing)
f010105d:	85 ff                	test   %edi,%edi
f010105f:	90                   	nop
f0101060:	74 08                	je     f010106a <readline+0xaa>
				cputchar(c);
f0101062:	89 1c 24             	mov    %ebx,(%esp)
f0101065:	e8 09 f6 ff ff       	call   f0100673 <cputchar>
			buf[i] = 0;
f010106a:	c6 86 80 f5 10 f0 00 	movb   $0x0,-0xfef0a80(%esi)
			return buf;
f0101071:	b8 80 f5 10 f0       	mov    $0xf010f580,%eax
		}
	}
}
f0101076:	83 c4 1c             	add    $0x1c,%esp
f0101079:	5b                   	pop    %ebx
f010107a:	5e                   	pop    %esi
f010107b:	5f                   	pop    %edi
f010107c:	5d                   	pop    %ebp
f010107d:	c3                   	ret    
f010107e:	66 90                	xchg   %ax,%ax

f0101080 <strlen>:

#include <inc/string.h>

int
strlen(const char *s)
{
f0101080:	55                   	push   %ebp
f0101081:	89 e5                	mov    %esp,%ebp
f0101083:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101086:	80 3a 00             	cmpb   $0x0,(%edx)
f0101089:	74 10                	je     f010109b <strlen+0x1b>
f010108b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
f0101090:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101093:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101097:	75 f7                	jne    f0101090 <strlen+0x10>
f0101099:	eb 05                	jmp    f01010a0 <strlen+0x20>
f010109b:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01010a0:	5d                   	pop    %ebp
f01010a1:	c3                   	ret    

f01010a2 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01010a2:	55                   	push   %ebp
f01010a3:	89 e5                	mov    %esp,%ebp
f01010a5:	53                   	push   %ebx
f01010a6:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01010a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01010ac:	85 c9                	test   %ecx,%ecx
f01010ae:	74 1c                	je     f01010cc <strnlen+0x2a>
f01010b0:	80 3b 00             	cmpb   $0x0,(%ebx)
f01010b3:	74 1e                	je     f01010d3 <strnlen+0x31>
f01010b5:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01010ba:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01010bc:	39 ca                	cmp    %ecx,%edx
f01010be:	74 18                	je     f01010d8 <strnlen+0x36>
f01010c0:	83 c2 01             	add    $0x1,%edx
f01010c3:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01010c8:	75 f0                	jne    f01010ba <strnlen+0x18>
f01010ca:	eb 0c                	jmp    f01010d8 <strnlen+0x36>
f01010cc:	b8 00 00 00 00       	mov    $0x0,%eax
f01010d1:	eb 05                	jmp    f01010d8 <strnlen+0x36>
f01010d3:	b8 00 00 00 00       	mov    $0x0,%eax
		n++;
	return n;
}
f01010d8:	5b                   	pop    %ebx
f01010d9:	5d                   	pop    %ebp
f01010da:	c3                   	ret    

f01010db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01010db:	55                   	push   %ebp
f01010dc:	89 e5                	mov    %esp,%ebp
f01010de:	53                   	push   %ebx
f01010df:	8b 45 08             	mov    0x8(%ebp),%eax
f01010e2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01010e5:	89 c2                	mov    %eax,%edx
f01010e7:	83 c2 01             	add    $0x1,%edx
f01010ea:	83 c1 01             	add    $0x1,%ecx
f01010ed:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01010f1:	88 5a ff             	mov    %bl,-0x1(%edx)
f01010f4:	84 db                	test   %bl,%bl
f01010f6:	75 ef                	jne    f01010e7 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01010f8:	5b                   	pop    %ebx
f01010f9:	5d                   	pop    %ebp
f01010fa:	c3                   	ret    

f01010fb <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
f01010fe:	56                   	push   %esi
f01010ff:	53                   	push   %ebx
f0101100:	8b 75 08             	mov    0x8(%ebp),%esi
f0101103:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101106:	8b 5d 10             	mov    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101109:	85 db                	test   %ebx,%ebx
f010110b:	74 17                	je     f0101124 <strncpy+0x29>
f010110d:	01 f3                	add    %esi,%ebx
f010110f:	89 f1                	mov    %esi,%ecx
		*dst++ = *src;
f0101111:	83 c1 01             	add    $0x1,%ecx
f0101114:	0f b6 02             	movzbl (%edx),%eax
f0101117:	88 41 ff             	mov    %al,-0x1(%ecx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010111a:	80 3a 01             	cmpb   $0x1,(%edx)
f010111d:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101120:	39 d9                	cmp    %ebx,%ecx
f0101122:	75 ed                	jne    f0101111 <strncpy+0x16>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101124:	89 f0                	mov    %esi,%eax
f0101126:	5b                   	pop    %ebx
f0101127:	5e                   	pop    %esi
f0101128:	5d                   	pop    %ebp
f0101129:	c3                   	ret    

f010112a <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010112a:	55                   	push   %ebp
f010112b:	89 e5                	mov    %esp,%ebp
f010112d:	57                   	push   %edi
f010112e:	56                   	push   %esi
f010112f:	53                   	push   %ebx
f0101130:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101133:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101136:	8b 75 10             	mov    0x10(%ebp),%esi
f0101139:	89 f8                	mov    %edi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010113b:	85 f6                	test   %esi,%esi
f010113d:	74 34                	je     f0101173 <strlcpy+0x49>
		while (--size > 0 && *src != '\0')
f010113f:	83 fe 01             	cmp    $0x1,%esi
f0101142:	74 26                	je     f010116a <strlcpy+0x40>
f0101144:	0f b6 0b             	movzbl (%ebx),%ecx
f0101147:	84 c9                	test   %cl,%cl
f0101149:	74 23                	je     f010116e <strlcpy+0x44>
f010114b:	83 ee 02             	sub    $0x2,%esi
f010114e:	ba 00 00 00 00       	mov    $0x0,%edx
			*dst++ = *src++;
f0101153:	83 c0 01             	add    $0x1,%eax
f0101156:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101159:	39 f2                	cmp    %esi,%edx
f010115b:	74 13                	je     f0101170 <strlcpy+0x46>
f010115d:	83 c2 01             	add    $0x1,%edx
f0101160:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0101164:	84 c9                	test   %cl,%cl
f0101166:	75 eb                	jne    f0101153 <strlcpy+0x29>
f0101168:	eb 06                	jmp    f0101170 <strlcpy+0x46>
f010116a:	89 f8                	mov    %edi,%eax
f010116c:	eb 02                	jmp    f0101170 <strlcpy+0x46>
f010116e:	89 f8                	mov    %edi,%eax
			*dst++ = *src++;
		*dst = '\0';
f0101170:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101173:	29 f8                	sub    %edi,%eax
}
f0101175:	5b                   	pop    %ebx
f0101176:	5e                   	pop    %esi
f0101177:	5f                   	pop    %edi
f0101178:	5d                   	pop    %ebp
f0101179:	c3                   	ret    

f010117a <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010117a:	55                   	push   %ebp
f010117b:	89 e5                	mov    %esp,%ebp
f010117d:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101180:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101183:	0f b6 01             	movzbl (%ecx),%eax
f0101186:	84 c0                	test   %al,%al
f0101188:	74 15                	je     f010119f <strcmp+0x25>
f010118a:	3a 02                	cmp    (%edx),%al
f010118c:	75 11                	jne    f010119f <strcmp+0x25>
		p++, q++;
f010118e:	83 c1 01             	add    $0x1,%ecx
f0101191:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101194:	0f b6 01             	movzbl (%ecx),%eax
f0101197:	84 c0                	test   %al,%al
f0101199:	74 04                	je     f010119f <strcmp+0x25>
f010119b:	3a 02                	cmp    (%edx),%al
f010119d:	74 ef                	je     f010118e <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010119f:	0f b6 c0             	movzbl %al,%eax
f01011a2:	0f b6 12             	movzbl (%edx),%edx
f01011a5:	29 d0                	sub    %edx,%eax
}
f01011a7:	5d                   	pop    %ebp
f01011a8:	c3                   	ret    

f01011a9 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01011a9:	55                   	push   %ebp
f01011aa:	89 e5                	mov    %esp,%ebp
f01011ac:	56                   	push   %esi
f01011ad:	53                   	push   %ebx
f01011ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01011b1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01011b4:	8b 75 10             	mov    0x10(%ebp),%esi
	while (n > 0 && *p && *p == *q)
f01011b7:	85 f6                	test   %esi,%esi
f01011b9:	74 29                	je     f01011e4 <strncmp+0x3b>
f01011bb:	0f b6 03             	movzbl (%ebx),%eax
f01011be:	84 c0                	test   %al,%al
f01011c0:	74 30                	je     f01011f2 <strncmp+0x49>
f01011c2:	3a 02                	cmp    (%edx),%al
f01011c4:	75 2c                	jne    f01011f2 <strncmp+0x49>
f01011c6:	8d 43 01             	lea    0x1(%ebx),%eax
f01011c9:	01 de                	add    %ebx,%esi
		n--, p++, q++;
f01011cb:	89 c3                	mov    %eax,%ebx
f01011cd:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01011d0:	39 f0                	cmp    %esi,%eax
f01011d2:	74 17                	je     f01011eb <strncmp+0x42>
f01011d4:	0f b6 08             	movzbl (%eax),%ecx
f01011d7:	84 c9                	test   %cl,%cl
f01011d9:	74 17                	je     f01011f2 <strncmp+0x49>
f01011db:	83 c0 01             	add    $0x1,%eax
f01011de:	3a 0a                	cmp    (%edx),%cl
f01011e0:	74 e9                	je     f01011cb <strncmp+0x22>
f01011e2:	eb 0e                	jmp    f01011f2 <strncmp+0x49>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01011e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01011e9:	eb 0f                	jmp    f01011fa <strncmp+0x51>
f01011eb:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f0:	eb 08                	jmp    f01011fa <strncmp+0x51>
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01011f2:	0f b6 03             	movzbl (%ebx),%eax
f01011f5:	0f b6 12             	movzbl (%edx),%edx
f01011f8:	29 d0                	sub    %edx,%eax
}
f01011fa:	5b                   	pop    %ebx
f01011fb:	5e                   	pop    %esi
f01011fc:	5d                   	pop    %ebp
f01011fd:	c3                   	ret    

f01011fe <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01011fe:	55                   	push   %ebp
f01011ff:	89 e5                	mov    %esp,%ebp
f0101201:	53                   	push   %ebx
f0101202:	8b 45 08             	mov    0x8(%ebp),%eax
f0101205:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f0101208:	0f b6 18             	movzbl (%eax),%ebx
f010120b:	84 db                	test   %bl,%bl
f010120d:	74 1d                	je     f010122c <strchr+0x2e>
f010120f:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101211:	38 d3                	cmp    %dl,%bl
f0101213:	75 06                	jne    f010121b <strchr+0x1d>
f0101215:	eb 1a                	jmp    f0101231 <strchr+0x33>
f0101217:	38 ca                	cmp    %cl,%dl
f0101219:	74 16                	je     f0101231 <strchr+0x33>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010121b:	83 c0 01             	add    $0x1,%eax
f010121e:	0f b6 10             	movzbl (%eax),%edx
f0101221:	84 d2                	test   %dl,%dl
f0101223:	75 f2                	jne    f0101217 <strchr+0x19>
		if (*s == c)
			return (char *) s;
	return 0;
f0101225:	b8 00 00 00 00       	mov    $0x0,%eax
f010122a:	eb 05                	jmp    f0101231 <strchr+0x33>
f010122c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101231:	5b                   	pop    %ebx
f0101232:	5d                   	pop    %ebp
f0101233:	c3                   	ret    

f0101234 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101234:	55                   	push   %ebp
f0101235:	89 e5                	mov    %esp,%ebp
f0101237:	53                   	push   %ebx
f0101238:	8b 45 08             	mov    0x8(%ebp),%eax
f010123b:	8b 55 0c             	mov    0xc(%ebp),%edx
	for (; *s; s++)
f010123e:	0f b6 18             	movzbl (%eax),%ebx
f0101241:	84 db                	test   %bl,%bl
f0101243:	74 17                	je     f010125c <strfind+0x28>
f0101245:	89 d1                	mov    %edx,%ecx
		if (*s == c)
f0101247:	38 d3                	cmp    %dl,%bl
f0101249:	75 07                	jne    f0101252 <strfind+0x1e>
f010124b:	eb 0f                	jmp    f010125c <strfind+0x28>
f010124d:	38 ca                	cmp    %cl,%dl
f010124f:	90                   	nop
f0101250:	74 0a                	je     f010125c <strfind+0x28>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101252:	83 c0 01             	add    $0x1,%eax
f0101255:	0f b6 10             	movzbl (%eax),%edx
f0101258:	84 d2                	test   %dl,%dl
f010125a:	75 f1                	jne    f010124d <strfind+0x19>
		if (*s == c)
			break;
	return (char *) s;
}
f010125c:	5b                   	pop    %ebx
f010125d:	5d                   	pop    %ebp
f010125e:	c3                   	ret    

f010125f <memset>:


void *
memset(void *v, int c, size_t n)
{
f010125f:	55                   	push   %ebp
f0101260:	89 e5                	mov    %esp,%ebp
f0101262:	53                   	push   %ebx
f0101263:	8b 45 08             	mov    0x8(%ebp),%eax
f0101266:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0101269:	8b 5d 10             	mov    0x10(%ebp),%ebx
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010126c:	89 da                	mov    %ebx,%edx
f010126e:	83 ea 01             	sub    $0x1,%edx
f0101271:	78 0e                	js     f0101281 <memset+0x22>
f0101273:	01 c3                	add    %eax,%ebx
memset(void *v, int c, size_t n)
{
	char *p;
	int m;

	p = v;
f0101275:	89 c2                	mov    %eax,%edx
	m = n;
	while (--m >= 0)
		*p++ = c;
f0101277:	83 c2 01             	add    $0x1,%edx
f010127a:	88 4a ff             	mov    %cl,-0x1(%edx)
	char *p;
	int m;

	p = v;
	m = n;
	while (--m >= 0)
f010127d:	39 da                	cmp    %ebx,%edx
f010127f:	75 f6                	jne    f0101277 <memset+0x18>
		*p++ = c;

	return v;
}
f0101281:	5b                   	pop    %ebx
f0101282:	5d                   	pop    %ebp
f0101283:	c3                   	ret    

f0101284 <memmove>:

/* no memcpy - use memmove instead */

void *
memmove(void *dst, const void *src, size_t n)
{
f0101284:	55                   	push   %ebp
f0101285:	89 e5                	mov    %esp,%ebp
f0101287:	57                   	push   %edi
f0101288:	56                   	push   %esi
f0101289:	53                   	push   %ebx
f010128a:	8b 45 08             	mov    0x8(%ebp),%eax
f010128d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101290:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101293:	39 c6                	cmp    %eax,%esi
f0101295:	72 0b                	jb     f01012a2 <memmove+0x1e>
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f0101297:	ba 00 00 00 00       	mov    $0x0,%edx
f010129c:	85 db                	test   %ebx,%ebx
f010129e:	75 2b                	jne    f01012cb <memmove+0x47>
f01012a0:	eb 37                	jmp    f01012d9 <memmove+0x55>
	const char *s;
	char *d;
	
	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01012a2:	8d 0c 1e             	lea    (%esi,%ebx,1),%ecx
f01012a5:	39 c8                	cmp    %ecx,%eax
f01012a7:	73 ee                	jae    f0101297 <memmove+0x13>
		s += n;
		d += n;
f01012a9:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
		while (n-- > 0)
f01012ac:	8d 53 ff             	lea    -0x1(%ebx),%edx
f01012af:	85 db                	test   %ebx,%ebx
f01012b1:	74 26                	je     f01012d9 <memmove+0x55>
f01012b3:	f7 db                	neg    %ebx
f01012b5:	8d 34 19             	lea    (%ecx,%ebx,1),%esi
f01012b8:	01 fb                	add    %edi,%ebx
			*--d = *--s;
f01012ba:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01012be:	88 0c 13             	mov    %cl,(%ebx,%edx,1)
	s = src;
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		while (n-- > 0)
f01012c1:	83 ea 01             	sub    $0x1,%edx
f01012c4:	83 fa ff             	cmp    $0xffffffff,%edx
f01012c7:	75 f1                	jne    f01012ba <memmove+0x36>
f01012c9:	eb 0e                	jmp    f01012d9 <memmove+0x55>
			*--d = *--s;
	} else
		while (n-- > 0)
			*d++ = *s++;
f01012cb:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01012cf:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01012d2:	83 c2 01             	add    $0x1,%edx
		s += n;
		d += n;
		while (n-- > 0)
			*--d = *--s;
	} else
		while (n-- > 0)
f01012d5:	39 da                	cmp    %ebx,%edx
f01012d7:	75 f2                	jne    f01012cb <memmove+0x47>
			*d++ = *s++;

	return dst;
}
f01012d9:	5b                   	pop    %ebx
f01012da:	5e                   	pop    %esi
f01012db:	5f                   	pop    %edi
f01012dc:	5d                   	pop    %ebp
f01012dd:	c3                   	ret    

f01012de <memcpy>:

/* sigh - gcc emits references to this for structure assignments! */
/* it is *not* prototyped in inc/string.h - do not use directly. */
void *
memcpy(void *dst, void *src, size_t n)
{
f01012de:	55                   	push   %ebp
f01012df:	89 e5                	mov    %esp,%ebp
f01012e1:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f01012e4:	8b 45 10             	mov    0x10(%ebp),%eax
f01012e7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012eb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01012f5:	89 04 24             	mov    %eax,(%esp)
f01012f8:	e8 87 ff ff ff       	call   f0101284 <memmove>
}
f01012fd:	c9                   	leave  
f01012fe:	c3                   	ret    

f01012ff <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01012ff:	55                   	push   %ebp
f0101300:	89 e5                	mov    %esp,%ebp
f0101302:	57                   	push   %edi
f0101303:	56                   	push   %esi
f0101304:	53                   	push   %ebx
f0101305:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101308:	8b 75 0c             	mov    0xc(%ebp),%esi
f010130b:	8b 45 10             	mov    0x10(%ebp),%eax
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010130e:	8d 78 ff             	lea    -0x1(%eax),%edi
f0101311:	85 c0                	test   %eax,%eax
f0101313:	74 36                	je     f010134b <memcmp+0x4c>
		if (*s1 != *s2)
f0101315:	0f b6 03             	movzbl (%ebx),%eax
f0101318:	0f b6 0e             	movzbl (%esi),%ecx
f010131b:	ba 00 00 00 00       	mov    $0x0,%edx
f0101320:	38 c8                	cmp    %cl,%al
f0101322:	74 1c                	je     f0101340 <memcmp+0x41>
f0101324:	eb 10                	jmp    f0101336 <memcmp+0x37>
f0101326:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f010132b:	83 c2 01             	add    $0x1,%edx
f010132e:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101332:	38 c8                	cmp    %cl,%al
f0101334:	74 0a                	je     f0101340 <memcmp+0x41>
			return (int) *s1 - (int) *s2;
f0101336:	0f b6 c0             	movzbl %al,%eax
f0101339:	0f b6 c9             	movzbl %cl,%ecx
f010133c:	29 c8                	sub    %ecx,%eax
f010133e:	eb 10                	jmp    f0101350 <memcmp+0x51>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101340:	39 fa                	cmp    %edi,%edx
f0101342:	75 e2                	jne    f0101326 <memcmp+0x27>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101344:	b8 00 00 00 00       	mov    $0x0,%eax
f0101349:	eb 05                	jmp    f0101350 <memcmp+0x51>
f010134b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101350:	5b                   	pop    %ebx
f0101351:	5e                   	pop    %esi
f0101352:	5f                   	pop    %edi
f0101353:	5d                   	pop    %ebp
f0101354:	c3                   	ret    

f0101355 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101355:	55                   	push   %ebp
f0101356:	89 e5                	mov    %esp,%ebp
f0101358:	53                   	push   %ebx
f0101359:	8b 45 08             	mov    0x8(%ebp),%eax
f010135c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const void *ends = (const char *) s + n;
f010135f:	89 c2                	mov    %eax,%edx
f0101361:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101364:	39 d0                	cmp    %edx,%eax
f0101366:	73 13                	jae    f010137b <memfind+0x26>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101368:	89 d9                	mov    %ebx,%ecx
f010136a:	38 18                	cmp    %bl,(%eax)
f010136c:	75 06                	jne    f0101374 <memfind+0x1f>
f010136e:	eb 0b                	jmp    f010137b <memfind+0x26>
f0101370:	38 08                	cmp    %cl,(%eax)
f0101372:	74 07                	je     f010137b <memfind+0x26>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101374:	83 c0 01             	add    $0x1,%eax
f0101377:	39 d0                	cmp    %edx,%eax
f0101379:	75 f5                	jne    f0101370 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010137b:	5b                   	pop    %ebx
f010137c:	5d                   	pop    %ebp
f010137d:	c3                   	ret    

f010137e <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010137e:	55                   	push   %ebp
f010137f:	89 e5                	mov    %esp,%ebp
f0101381:	57                   	push   %edi
f0101382:	56                   	push   %esi
f0101383:	53                   	push   %ebx
f0101384:	8b 55 08             	mov    0x8(%ebp),%edx
f0101387:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010138a:	0f b6 0a             	movzbl (%edx),%ecx
f010138d:	80 f9 09             	cmp    $0x9,%cl
f0101390:	74 05                	je     f0101397 <strtol+0x19>
f0101392:	80 f9 20             	cmp    $0x20,%cl
f0101395:	75 10                	jne    f01013a7 <strtol+0x29>
		s++;
f0101397:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010139a:	0f b6 0a             	movzbl (%edx),%ecx
f010139d:	80 f9 09             	cmp    $0x9,%cl
f01013a0:	74 f5                	je     f0101397 <strtol+0x19>
f01013a2:	80 f9 20             	cmp    $0x20,%cl
f01013a5:	74 f0                	je     f0101397 <strtol+0x19>
		s++;

	// plus/minus sign
	if (*s == '+')
f01013a7:	80 f9 2b             	cmp    $0x2b,%cl
f01013aa:	75 0a                	jne    f01013b6 <strtol+0x38>
		s++;
f01013ac:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01013af:	bf 00 00 00 00       	mov    $0x0,%edi
f01013b4:	eb 11                	jmp    f01013c7 <strtol+0x49>
f01013b6:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01013bb:	80 f9 2d             	cmp    $0x2d,%cl
f01013be:	75 07                	jne    f01013c7 <strtol+0x49>
		s++, neg = 1;
f01013c0:	83 c2 01             	add    $0x1,%edx
f01013c3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01013c7:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01013cc:	75 15                	jne    f01013e3 <strtol+0x65>
f01013ce:	80 3a 30             	cmpb   $0x30,(%edx)
f01013d1:	75 10                	jne    f01013e3 <strtol+0x65>
f01013d3:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01013d7:	75 0a                	jne    f01013e3 <strtol+0x65>
		s += 2, base = 16;
f01013d9:	83 c2 02             	add    $0x2,%edx
f01013dc:	b8 10 00 00 00       	mov    $0x10,%eax
f01013e1:	eb 10                	jmp    f01013f3 <strtol+0x75>
	else if (base == 0 && s[0] == '0')
f01013e3:	85 c0                	test   %eax,%eax
f01013e5:	75 0c                	jne    f01013f3 <strtol+0x75>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01013e7:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01013e9:	80 3a 30             	cmpb   $0x30,(%edx)
f01013ec:	75 05                	jne    f01013f3 <strtol+0x75>
		s++, base = 8;
f01013ee:	83 c2 01             	add    $0x1,%edx
f01013f1:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f01013f3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01013f8:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01013fb:	0f b6 0a             	movzbl (%edx),%ecx
f01013fe:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0101401:	89 f0                	mov    %esi,%eax
f0101403:	3c 09                	cmp    $0x9,%al
f0101405:	77 08                	ja     f010140f <strtol+0x91>
			dig = *s - '0';
f0101407:	0f be c9             	movsbl %cl,%ecx
f010140a:	83 e9 30             	sub    $0x30,%ecx
f010140d:	eb 20                	jmp    f010142f <strtol+0xb1>
		else if (*s >= 'a' && *s <= 'z')
f010140f:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0101412:	89 f0                	mov    %esi,%eax
f0101414:	3c 19                	cmp    $0x19,%al
f0101416:	77 08                	ja     f0101420 <strtol+0xa2>
			dig = *s - 'a' + 10;
f0101418:	0f be c9             	movsbl %cl,%ecx
f010141b:	83 e9 57             	sub    $0x57,%ecx
f010141e:	eb 0f                	jmp    f010142f <strtol+0xb1>
		else if (*s >= 'A' && *s <= 'Z')
f0101420:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0101423:	89 f0                	mov    %esi,%eax
f0101425:	3c 19                	cmp    $0x19,%al
f0101427:	77 16                	ja     f010143f <strtol+0xc1>
			dig = *s - 'A' + 10;
f0101429:	0f be c9             	movsbl %cl,%ecx
f010142c:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f010142f:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0101432:	7d 0f                	jge    f0101443 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101434:	83 c2 01             	add    $0x1,%edx
f0101437:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f010143b:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f010143d:	eb bc                	jmp    f01013fb <strtol+0x7d>
f010143f:	89 d8                	mov    %ebx,%eax
f0101441:	eb 02                	jmp    f0101445 <strtol+0xc7>
f0101443:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0101445:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101449:	74 05                	je     f0101450 <strtol+0xd2>
		*endptr = (char *) s;
f010144b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010144e:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0101450:	f7 d8                	neg    %eax
f0101452:	85 ff                	test   %edi,%edi
f0101454:	0f 44 c3             	cmove  %ebx,%eax
}
f0101457:	5b                   	pop    %ebx
f0101458:	5e                   	pop    %esi
f0101459:	5f                   	pop    %edi
f010145a:	5d                   	pop    %ebp
f010145b:	c3                   	ret    
f010145c:	66 90                	xchg   %ax,%ax
f010145e:	66 90                	xchg   %ax,%ax

f0101460 <__udivdi3>:
f0101460:	55                   	push   %ebp
f0101461:	57                   	push   %edi
f0101462:	56                   	push   %esi
f0101463:	83 ec 0c             	sub    $0xc,%esp
f0101466:	8b 44 24 28          	mov    0x28(%esp),%eax
f010146a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010146e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0101472:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0101476:	85 c0                	test   %eax,%eax
f0101478:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010147c:	89 ea                	mov    %ebp,%edx
f010147e:	89 0c 24             	mov    %ecx,(%esp)
f0101481:	75 2d                	jne    f01014b0 <__udivdi3+0x50>
f0101483:	39 e9                	cmp    %ebp,%ecx
f0101485:	77 61                	ja     f01014e8 <__udivdi3+0x88>
f0101487:	85 c9                	test   %ecx,%ecx
f0101489:	89 ce                	mov    %ecx,%esi
f010148b:	75 0b                	jne    f0101498 <__udivdi3+0x38>
f010148d:	b8 01 00 00 00       	mov    $0x1,%eax
f0101492:	31 d2                	xor    %edx,%edx
f0101494:	f7 f1                	div    %ecx
f0101496:	89 c6                	mov    %eax,%esi
f0101498:	31 d2                	xor    %edx,%edx
f010149a:	89 e8                	mov    %ebp,%eax
f010149c:	f7 f6                	div    %esi
f010149e:	89 c5                	mov    %eax,%ebp
f01014a0:	89 f8                	mov    %edi,%eax
f01014a2:	f7 f6                	div    %esi
f01014a4:	89 ea                	mov    %ebp,%edx
f01014a6:	83 c4 0c             	add    $0xc,%esp
f01014a9:	5e                   	pop    %esi
f01014aa:	5f                   	pop    %edi
f01014ab:	5d                   	pop    %ebp
f01014ac:	c3                   	ret    
f01014ad:	8d 76 00             	lea    0x0(%esi),%esi
f01014b0:	39 e8                	cmp    %ebp,%eax
f01014b2:	77 24                	ja     f01014d8 <__udivdi3+0x78>
f01014b4:	0f bd e8             	bsr    %eax,%ebp
f01014b7:	83 f5 1f             	xor    $0x1f,%ebp
f01014ba:	75 3c                	jne    f01014f8 <__udivdi3+0x98>
f01014bc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01014c0:	39 34 24             	cmp    %esi,(%esp)
f01014c3:	0f 86 9f 00 00 00    	jbe    f0101568 <__udivdi3+0x108>
f01014c9:	39 d0                	cmp    %edx,%eax
f01014cb:	0f 82 97 00 00 00    	jb     f0101568 <__udivdi3+0x108>
f01014d1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01014d8:	31 d2                	xor    %edx,%edx
f01014da:	31 c0                	xor    %eax,%eax
f01014dc:	83 c4 0c             	add    $0xc,%esp
f01014df:	5e                   	pop    %esi
f01014e0:	5f                   	pop    %edi
f01014e1:	5d                   	pop    %ebp
f01014e2:	c3                   	ret    
f01014e3:	90                   	nop
f01014e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01014e8:	89 f8                	mov    %edi,%eax
f01014ea:	f7 f1                	div    %ecx
f01014ec:	31 d2                	xor    %edx,%edx
f01014ee:	83 c4 0c             	add    $0xc,%esp
f01014f1:	5e                   	pop    %esi
f01014f2:	5f                   	pop    %edi
f01014f3:	5d                   	pop    %ebp
f01014f4:	c3                   	ret    
f01014f5:	8d 76 00             	lea    0x0(%esi),%esi
f01014f8:	89 e9                	mov    %ebp,%ecx
f01014fa:	8b 3c 24             	mov    (%esp),%edi
f01014fd:	d3 e0                	shl    %cl,%eax
f01014ff:	89 c6                	mov    %eax,%esi
f0101501:	b8 20 00 00 00       	mov    $0x20,%eax
f0101506:	29 e8                	sub    %ebp,%eax
f0101508:	89 c1                	mov    %eax,%ecx
f010150a:	d3 ef                	shr    %cl,%edi
f010150c:	89 e9                	mov    %ebp,%ecx
f010150e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101512:	8b 3c 24             	mov    (%esp),%edi
f0101515:	09 74 24 08          	or     %esi,0x8(%esp)
f0101519:	89 d6                	mov    %edx,%esi
f010151b:	d3 e7                	shl    %cl,%edi
f010151d:	89 c1                	mov    %eax,%ecx
f010151f:	89 3c 24             	mov    %edi,(%esp)
f0101522:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101526:	d3 ee                	shr    %cl,%esi
f0101528:	89 e9                	mov    %ebp,%ecx
f010152a:	d3 e2                	shl    %cl,%edx
f010152c:	89 c1                	mov    %eax,%ecx
f010152e:	d3 ef                	shr    %cl,%edi
f0101530:	09 d7                	or     %edx,%edi
f0101532:	89 f2                	mov    %esi,%edx
f0101534:	89 f8                	mov    %edi,%eax
f0101536:	f7 74 24 08          	divl   0x8(%esp)
f010153a:	89 d6                	mov    %edx,%esi
f010153c:	89 c7                	mov    %eax,%edi
f010153e:	f7 24 24             	mull   (%esp)
f0101541:	39 d6                	cmp    %edx,%esi
f0101543:	89 14 24             	mov    %edx,(%esp)
f0101546:	72 30                	jb     f0101578 <__udivdi3+0x118>
f0101548:	8b 54 24 04          	mov    0x4(%esp),%edx
f010154c:	89 e9                	mov    %ebp,%ecx
f010154e:	d3 e2                	shl    %cl,%edx
f0101550:	39 c2                	cmp    %eax,%edx
f0101552:	73 05                	jae    f0101559 <__udivdi3+0xf9>
f0101554:	3b 34 24             	cmp    (%esp),%esi
f0101557:	74 1f                	je     f0101578 <__udivdi3+0x118>
f0101559:	89 f8                	mov    %edi,%eax
f010155b:	31 d2                	xor    %edx,%edx
f010155d:	e9 7a ff ff ff       	jmp    f01014dc <__udivdi3+0x7c>
f0101562:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101568:	31 d2                	xor    %edx,%edx
f010156a:	b8 01 00 00 00       	mov    $0x1,%eax
f010156f:	e9 68 ff ff ff       	jmp    f01014dc <__udivdi3+0x7c>
f0101574:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101578:	8d 47 ff             	lea    -0x1(%edi),%eax
f010157b:	31 d2                	xor    %edx,%edx
f010157d:	83 c4 0c             	add    $0xc,%esp
f0101580:	5e                   	pop    %esi
f0101581:	5f                   	pop    %edi
f0101582:	5d                   	pop    %ebp
f0101583:	c3                   	ret    
f0101584:	66 90                	xchg   %ax,%ax
f0101586:	66 90                	xchg   %ax,%ax
f0101588:	66 90                	xchg   %ax,%ax
f010158a:	66 90                	xchg   %ax,%ax
f010158c:	66 90                	xchg   %ax,%ax
f010158e:	66 90                	xchg   %ax,%ax

f0101590 <__umoddi3>:
f0101590:	55                   	push   %ebp
f0101591:	57                   	push   %edi
f0101592:	56                   	push   %esi
f0101593:	83 ec 14             	sub    $0x14,%esp
f0101596:	8b 44 24 28          	mov    0x28(%esp),%eax
f010159a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010159e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01015a2:	89 c7                	mov    %eax,%edi
f01015a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015a8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01015ac:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01015b0:	89 34 24             	mov    %esi,(%esp)
f01015b3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	89 c2                	mov    %eax,%edx
f01015bb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01015bf:	75 17                	jne    f01015d8 <__umoddi3+0x48>
f01015c1:	39 fe                	cmp    %edi,%esi
f01015c3:	76 4b                	jbe    f0101610 <__umoddi3+0x80>
f01015c5:	89 c8                	mov    %ecx,%eax
f01015c7:	89 fa                	mov    %edi,%edx
f01015c9:	f7 f6                	div    %esi
f01015cb:	89 d0                	mov    %edx,%eax
f01015cd:	31 d2                	xor    %edx,%edx
f01015cf:	83 c4 14             	add    $0x14,%esp
f01015d2:	5e                   	pop    %esi
f01015d3:	5f                   	pop    %edi
f01015d4:	5d                   	pop    %ebp
f01015d5:	c3                   	ret    
f01015d6:	66 90                	xchg   %ax,%ax
f01015d8:	39 f8                	cmp    %edi,%eax
f01015da:	77 54                	ja     f0101630 <__umoddi3+0xa0>
f01015dc:	0f bd e8             	bsr    %eax,%ebp
f01015df:	83 f5 1f             	xor    $0x1f,%ebp
f01015e2:	75 5c                	jne    f0101640 <__umoddi3+0xb0>
f01015e4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01015e8:	39 3c 24             	cmp    %edi,(%esp)
f01015eb:	0f 87 e7 00 00 00    	ja     f01016d8 <__umoddi3+0x148>
f01015f1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01015f5:	29 f1                	sub    %esi,%ecx
f01015f7:	19 c7                	sbb    %eax,%edi
f01015f9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01015fd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101601:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101605:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0101609:	83 c4 14             	add    $0x14,%esp
f010160c:	5e                   	pop    %esi
f010160d:	5f                   	pop    %edi
f010160e:	5d                   	pop    %ebp
f010160f:	c3                   	ret    
f0101610:	85 f6                	test   %esi,%esi
f0101612:	89 f5                	mov    %esi,%ebp
f0101614:	75 0b                	jne    f0101621 <__umoddi3+0x91>
f0101616:	b8 01 00 00 00       	mov    $0x1,%eax
f010161b:	31 d2                	xor    %edx,%edx
f010161d:	f7 f6                	div    %esi
f010161f:	89 c5                	mov    %eax,%ebp
f0101621:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101625:	31 d2                	xor    %edx,%edx
f0101627:	f7 f5                	div    %ebp
f0101629:	89 c8                	mov    %ecx,%eax
f010162b:	f7 f5                	div    %ebp
f010162d:	eb 9c                	jmp    f01015cb <__umoddi3+0x3b>
f010162f:	90                   	nop
f0101630:	89 c8                	mov    %ecx,%eax
f0101632:	89 fa                	mov    %edi,%edx
f0101634:	83 c4 14             	add    $0x14,%esp
f0101637:	5e                   	pop    %esi
f0101638:	5f                   	pop    %edi
f0101639:	5d                   	pop    %ebp
f010163a:	c3                   	ret    
f010163b:	90                   	nop
f010163c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101640:	8b 04 24             	mov    (%esp),%eax
f0101643:	be 20 00 00 00       	mov    $0x20,%esi
f0101648:	89 e9                	mov    %ebp,%ecx
f010164a:	29 ee                	sub    %ebp,%esi
f010164c:	d3 e2                	shl    %cl,%edx
f010164e:	89 f1                	mov    %esi,%ecx
f0101650:	d3 e8                	shr    %cl,%eax
f0101652:	89 e9                	mov    %ebp,%ecx
f0101654:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101658:	8b 04 24             	mov    (%esp),%eax
f010165b:	09 54 24 04          	or     %edx,0x4(%esp)
f010165f:	89 fa                	mov    %edi,%edx
f0101661:	d3 e0                	shl    %cl,%eax
f0101663:	89 f1                	mov    %esi,%ecx
f0101665:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101669:	8b 44 24 10          	mov    0x10(%esp),%eax
f010166d:	d3 ea                	shr    %cl,%edx
f010166f:	89 e9                	mov    %ebp,%ecx
f0101671:	d3 e7                	shl    %cl,%edi
f0101673:	89 f1                	mov    %esi,%ecx
f0101675:	d3 e8                	shr    %cl,%eax
f0101677:	89 e9                	mov    %ebp,%ecx
f0101679:	09 f8                	or     %edi,%eax
f010167b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010167f:	f7 74 24 04          	divl   0x4(%esp)
f0101683:	d3 e7                	shl    %cl,%edi
f0101685:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101689:	89 d7                	mov    %edx,%edi
f010168b:	f7 64 24 08          	mull   0x8(%esp)
f010168f:	39 d7                	cmp    %edx,%edi
f0101691:	89 c1                	mov    %eax,%ecx
f0101693:	89 14 24             	mov    %edx,(%esp)
f0101696:	72 2c                	jb     f01016c4 <__umoddi3+0x134>
f0101698:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010169c:	72 22                	jb     f01016c0 <__umoddi3+0x130>
f010169e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01016a2:	29 c8                	sub    %ecx,%eax
f01016a4:	19 d7                	sbb    %edx,%edi
f01016a6:	89 e9                	mov    %ebp,%ecx
f01016a8:	89 fa                	mov    %edi,%edx
f01016aa:	d3 e8                	shr    %cl,%eax
f01016ac:	89 f1                	mov    %esi,%ecx
f01016ae:	d3 e2                	shl    %cl,%edx
f01016b0:	89 e9                	mov    %ebp,%ecx
f01016b2:	d3 ef                	shr    %cl,%edi
f01016b4:	09 d0                	or     %edx,%eax
f01016b6:	89 fa                	mov    %edi,%edx
f01016b8:	83 c4 14             	add    $0x14,%esp
f01016bb:	5e                   	pop    %esi
f01016bc:	5f                   	pop    %edi
f01016bd:	5d                   	pop    %ebp
f01016be:	c3                   	ret    
f01016bf:	90                   	nop
f01016c0:	39 d7                	cmp    %edx,%edi
f01016c2:	75 da                	jne    f010169e <__umoddi3+0x10e>
f01016c4:	8b 14 24             	mov    (%esp),%edx
f01016c7:	89 c1                	mov    %eax,%ecx
f01016c9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01016cd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01016d1:	eb cb                	jmp    f010169e <__umoddi3+0x10e>
f01016d3:	90                   	nop
f01016d4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01016d8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01016dc:	0f 82 0f ff ff ff    	jb     f01015f1 <__umoddi3+0x61>
f01016e2:	e9 1a ff ff ff       	jmp    f0101601 <__umoddi3+0x71>

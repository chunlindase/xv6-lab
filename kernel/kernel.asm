
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	95013103          	ld	sp,-1712(sp) # 80008950 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	e5478793          	addi	a5,a5,-428 # 80005eb0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	172080e7          	jalr	370(ra) # 80002298 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	948080e7          	jalr	-1720(ra) # 80001b16 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	f0a080e7          	jalr	-246(ra) # 800020e8 <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	028080e7          	jalr	40(ra) # 80002242 <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	ff2080e7          	jalr	-14(ra) # 800022ee <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	d16080e7          	jalr	-746(ra) # 80002166 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	8b0080e7          	jalr	-1872(ra) # 80002166 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00001097          	auipc	ra,0x1
    80000954:	798080e7          	jalr	1944(ra) # 800020e8 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f50080e7          	jalr	-176(ra) # 80001afa <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	f1e080e7          	jalr	-226(ra) # 80001afa <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	f12080e7          	jalr	-238(ra) # 80001afa <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	efa080e7          	jalr	-262(ra) # 80001afa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	eba080e7          	jalr	-326(ra) # 80001afa <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	e8e080e7          	jalr	-370(ra) # 80001afa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	c24080e7          	jalr	-988(ra) # 80001aea <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	c08080e7          	jalr	-1016(ra) # 80001aea <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0e0080e7          	jalr	224(ra) # 80000fdc <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	a2c080e7          	jalr	-1492(ra) # 80002930 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	fe4080e7          	jalr	-28(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	eda080e7          	jalr	-294(ra) # 80001dee <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00005097          	auipc	ra,0x5
    80000f28:	78e080e7          	jalr	1934(ra) # 800066b2 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	2aa080e7          	jalr	682(ra) # 80001216 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	068080e7          	jalr	104(ra) # 80000fdc <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	b0e080e7          	jalr	-1266(ra) # 80001a8a <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	984080e7          	jalr	-1660(ra) # 80002908 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	9a4080e7          	jalr	-1628(ra) # 80002930 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	f46080e7          	jalr	-186(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	f54080e7          	jalr	-172(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	0ce080e7          	jalr	206(ra) # 80003072 <binit>
    iinit();         // inode cache
    80000fac:	00002097          	auipc	ra,0x2
    80000fb0:	75e080e7          	jalr	1886(ra) # 8000370a <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	6f8080e7          	jalr	1784(ra) # 800046ac <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	03c080e7          	jalr	60(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	616080e7          	jalr	1558(ra) # 800025da <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fdc:	1141                	addi	sp,sp,-16
    80000fde:	e422                	sd	s0,8(sp)
    80000fe0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	02e7b783          	ld	a5,46(a5) # 80009010 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	51a080e7          	jalr	1306(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	ae6080e7          	jalr	-1306(ra) # 80000b20 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cc2080e7          	jalr	-830(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	00a7d513          	srli	a0,a5,0xa
    800010e0:	0532                	slli	a0,a0,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e8:	1101                	addi	sp,sp,-32
    800010ea:	ec06                	sd	ra,24(sp)
    800010ec:	e822                	sd	s0,16(sp)
    800010ee:	e426                	sd	s1,8(sp)
    800010f0:	e04a                	sd	s2,0(sp)
    800010f2:	1000                	addi	s0,sp,32
    800010f4:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    800010f6:	1552                	slli	a0,a0,0x34
    800010f8:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->prockernelpagetable, va, 0);
    800010fc:	00001097          	auipc	ra,0x1
    80001100:	a1a080e7          	jalr	-1510(ra) # 80001b16 <myproc>
    80001104:	4601                	li	a2,0
    80001106:	85a6                	mv	a1,s1
    80001108:	16853503          	ld	a0,360(a0)
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	ef4080e7          	jalr	-268(ra) # 80001000 <walk>
  if(pte == 0)
    80001114:	cd11                	beqz	a0,80001130 <kvmpa+0x48>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001116:	6108                	ld	a0,0(a0)
    80001118:	00157793          	andi	a5,a0,1
    8000111c:	c395                	beqz	a5,80001140 <kvmpa+0x58>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000111e:	8129                	srli	a0,a0,0xa
    80001120:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001122:	954a                	add	a0,a0,s2
    80001124:	60e2                	ld	ra,24(sp)
    80001126:	6442                	ld	s0,16(sp)
    80001128:	64a2                	ld	s1,8(sp)
    8000112a:	6902                	ld	s2,0(sp)
    8000112c:	6105                	addi	sp,sp,32
    8000112e:	8082                	ret
    panic("kvmpa");
    80001130:	00007517          	auipc	a0,0x7
    80001134:	fa850513          	addi	a0,a0,-88 # 800080d8 <digits+0x98>
    80001138:	fffff097          	auipc	ra,0xfffff
    8000113c:	410080e7          	jalr	1040(ra) # 80000548 <panic>
    panic("kvmpa");
    80001140:	00007517          	auipc	a0,0x7
    80001144:	f9850513          	addi	a0,a0,-104 # 800080d8 <digits+0x98>
    80001148:	fffff097          	auipc	ra,0xfffff
    8000114c:	400080e7          	jalr	1024(ra) # 80000548 <panic>

0000000080001150 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001150:	715d                	addi	sp,sp,-80
    80001152:	e486                	sd	ra,72(sp)
    80001154:	e0a2                	sd	s0,64(sp)
    80001156:	fc26                	sd	s1,56(sp)
    80001158:	f84a                	sd	s2,48(sp)
    8000115a:	f44e                	sd	s3,40(sp)
    8000115c:	f052                	sd	s4,32(sp)
    8000115e:	ec56                	sd	s5,24(sp)
    80001160:	e85a                	sd	s6,16(sp)
    80001162:	e45e                	sd	s7,8(sp)
    80001164:	0880                	addi	s0,sp,80
    80001166:	8aaa                	mv	s5,a0
    80001168:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000116a:	777d                	lui	a4,0xfffff
    8000116c:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001170:	167d                	addi	a2,a2,-1
    80001172:	00b609b3          	add	s3,a2,a1
    80001176:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000117a:	893e                	mv	s2,a5
    8000117c:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001180:	6b85                	lui	s7,0x1
    80001182:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001186:	4605                	li	a2,1
    80001188:	85ca                	mv	a1,s2
    8000118a:	8556                	mv	a0,s5
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	e74080e7          	jalr	-396(ra) # 80001000 <walk>
    80001194:	c51d                	beqz	a0,800011c2 <mappages+0x72>
    if(*pte & PTE_V)
    80001196:	611c                	ld	a5,0(a0)
    80001198:	8b85                	andi	a5,a5,1
    8000119a:	ef81                	bnez	a5,800011b2 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000119c:	80b1                	srli	s1,s1,0xc
    8000119e:	04aa                	slli	s1,s1,0xa
    800011a0:	0164e4b3          	or	s1,s1,s6
    800011a4:	0014e493          	ori	s1,s1,1
    800011a8:	e104                	sd	s1,0(a0)
    if(a == last)
    800011aa:	03390863          	beq	s2,s3,800011da <mappages+0x8a>
    a += PGSIZE;
    800011ae:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011b0:	bfc9                	j	80001182 <mappages+0x32>
      panic("remap");
    800011b2:	00007517          	auipc	a0,0x7
    800011b6:	f2e50513          	addi	a0,a0,-210 # 800080e0 <digits+0xa0>
    800011ba:	fffff097          	auipc	ra,0xfffff
    800011be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
      return -1;
    800011c2:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011c4:	60a6                	ld	ra,72(sp)
    800011c6:	6406                	ld	s0,64(sp)
    800011c8:	74e2                	ld	s1,56(sp)
    800011ca:	7942                	ld	s2,48(sp)
    800011cc:	79a2                	ld	s3,40(sp)
    800011ce:	7a02                	ld	s4,32(sp)
    800011d0:	6ae2                	ld	s5,24(sp)
    800011d2:	6b42                	ld	s6,16(sp)
    800011d4:	6ba2                	ld	s7,8(sp)
    800011d6:	6161                	addi	sp,sp,80
    800011d8:	8082                	ret
  return 0;
    800011da:	4501                	li	a0,0
    800011dc:	b7e5                	j	800011c4 <mappages+0x74>

00000000800011de <kvmmap>:
{
    800011de:	1141                	addi	sp,sp,-16
    800011e0:	e406                	sd	ra,8(sp)
    800011e2:	e022                	sd	s0,0(sp)
    800011e4:	0800                	addi	s0,sp,16
    800011e6:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011e8:	86ae                	mv	a3,a1
    800011ea:	85aa                	mv	a1,a0
    800011ec:	00008517          	auipc	a0,0x8
    800011f0:	e2453503          	ld	a0,-476(a0) # 80009010 <kernel_pagetable>
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	f5c080e7          	jalr	-164(ra) # 80001150 <mappages>
    800011fc:	e509                	bnez	a0,80001206 <kvmmap+0x28>
}
    800011fe:	60a2                	ld	ra,8(sp)
    80001200:	6402                	ld	s0,0(sp)
    80001202:	0141                	addi	sp,sp,16
    80001204:	8082                	ret
    panic("kvmmap");
    80001206:	00007517          	auipc	a0,0x7
    8000120a:	ee250513          	addi	a0,a0,-286 # 800080e8 <digits+0xa8>
    8000120e:	fffff097          	auipc	ra,0xfffff
    80001212:	33a080e7          	jalr	826(ra) # 80000548 <panic>

0000000080001216 <kvminit>:
{
    80001216:	1101                	addi	sp,sp,-32
    80001218:	ec06                	sd	ra,24(sp)
    8000121a:	e822                	sd	s0,16(sp)
    8000121c:	e426                	sd	s1,8(sp)
    8000121e:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001220:	00000097          	auipc	ra,0x0
    80001224:	900080e7          	jalr	-1792(ra) # 80000b20 <kalloc>
    80001228:	00008797          	auipc	a5,0x8
    8000122c:	dea7b423          	sd	a0,-536(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001230:	6605                	lui	a2,0x1
    80001232:	4581                	li	a1,0
    80001234:	00000097          	auipc	ra,0x0
    80001238:	ad8080e7          	jalr	-1320(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000123c:	4699                	li	a3,6
    8000123e:	6605                	lui	a2,0x1
    80001240:	100005b7          	lui	a1,0x10000
    80001244:	10000537          	lui	a0,0x10000
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f96080e7          	jalr	-106(ra) # 800011de <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001250:	4699                	li	a3,6
    80001252:	6605                	lui	a2,0x1
    80001254:	100015b7          	lui	a1,0x10001
    80001258:	10001537          	lui	a0,0x10001
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f82080e7          	jalr	-126(ra) # 800011de <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001264:	4699                	li	a3,6
    80001266:	6641                	lui	a2,0x10
    80001268:	020005b7          	lui	a1,0x2000
    8000126c:	02000537          	lui	a0,0x2000
    80001270:	00000097          	auipc	ra,0x0
    80001274:	f6e080e7          	jalr	-146(ra) # 800011de <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001278:	4699                	li	a3,6
    8000127a:	00400637          	lui	a2,0x400
    8000127e:	0c0005b7          	lui	a1,0xc000
    80001282:	0c000537          	lui	a0,0xc000
    80001286:	00000097          	auipc	ra,0x0
    8000128a:	f58080e7          	jalr	-168(ra) # 800011de <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000128e:	00007497          	auipc	s1,0x7
    80001292:	d7248493          	addi	s1,s1,-654 # 80008000 <etext>
    80001296:	46a9                	li	a3,10
    80001298:	80007617          	auipc	a2,0x80007
    8000129c:	d6860613          	addi	a2,a2,-664 # 8000 <_entry-0x7fff8000>
    800012a0:	4585                	li	a1,1
    800012a2:	05fe                	slli	a1,a1,0x1f
    800012a4:	852e                	mv	a0,a1
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f38080e7          	jalr	-200(ra) # 800011de <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012ae:	4699                	li	a3,6
    800012b0:	4645                	li	a2,17
    800012b2:	066e                	slli	a2,a2,0x1b
    800012b4:	8e05                	sub	a2,a2,s1
    800012b6:	85a6                	mv	a1,s1
    800012b8:	8526                	mv	a0,s1
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f24080e7          	jalr	-220(ra) # 800011de <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012c2:	46a9                	li	a3,10
    800012c4:	6605                	lui	a2,0x1
    800012c6:	00006597          	auipc	a1,0x6
    800012ca:	d3a58593          	addi	a1,a1,-710 # 80007000 <_trampoline>
    800012ce:	04000537          	lui	a0,0x4000
    800012d2:	157d                	addi	a0,a0,-1
    800012d4:	0532                	slli	a0,a0,0xc
    800012d6:	00000097          	auipc	ra,0x0
    800012da:	f08080e7          	jalr	-248(ra) # 800011de <kvmmap>
}
    800012de:	60e2                	ld	ra,24(sp)
    800012e0:	6442                	ld	s0,16(sp)
    800012e2:	64a2                	ld	s1,8(sp)
    800012e4:	6105                	addi	sp,sp,32
    800012e6:	8082                	ret

00000000800012e8 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012e8:	715d                	addi	sp,sp,-80
    800012ea:	e486                	sd	ra,72(sp)
    800012ec:	e0a2                	sd	s0,64(sp)
    800012ee:	fc26                	sd	s1,56(sp)
    800012f0:	f84a                	sd	s2,48(sp)
    800012f2:	f44e                	sd	s3,40(sp)
    800012f4:	f052                	sd	s4,32(sp)
    800012f6:	ec56                	sd	s5,24(sp)
    800012f8:	e85a                	sd	s6,16(sp)
    800012fa:	e45e                	sd	s7,8(sp)
    800012fc:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012fe:	03459793          	slli	a5,a1,0x34
    80001302:	e795                	bnez	a5,8000132e <uvmunmap+0x46>
    80001304:	8a2a                	mv	s4,a0
    80001306:	892e                	mv	s2,a1
    80001308:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130a:	0632                	slli	a2,a2,0xc
    8000130c:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001310:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001312:	6b05                	lui	s6,0x1
    80001314:	0735e863          	bltu	a1,s3,80001384 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001318:	60a6                	ld	ra,72(sp)
    8000131a:	6406                	ld	s0,64(sp)
    8000131c:	74e2                	ld	s1,56(sp)
    8000131e:	7942                	ld	s2,48(sp)
    80001320:	79a2                	ld	s3,40(sp)
    80001322:	7a02                	ld	s4,32(sp)
    80001324:	6ae2                	ld	s5,24(sp)
    80001326:	6b42                	ld	s6,16(sp)
    80001328:	6ba2                	ld	s7,8(sp)
    8000132a:	6161                	addi	sp,sp,80
    8000132c:	8082                	ret
    panic("uvmunmap: not aligned");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	dc250513          	addi	a0,a0,-574 # 800080f0 <digits+0xb0>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	212080e7          	jalr	530(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000133e:	00007517          	auipc	a0,0x7
    80001342:	dca50513          	addi	a0,a0,-566 # 80008108 <digits+0xc8>
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	202080e7          	jalr	514(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000134e:	00007517          	auipc	a0,0x7
    80001352:	dca50513          	addi	a0,a0,-566 # 80008118 <digits+0xd8>
    80001356:	fffff097          	auipc	ra,0xfffff
    8000135a:	1f2080e7          	jalr	498(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000135e:	00007517          	auipc	a0,0x7
    80001362:	dd250513          	addi	a0,a0,-558 # 80008130 <digits+0xf0>
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	1e2080e7          	jalr	482(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6b2080e7          	jalr	1714(ra) # 80000a24 <kfree>
    *pte = 0;
    8000137a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137e:	995a                	add	s2,s2,s6
    80001380:	f9397ce3          	bgeu	s2,s3,80001318 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001384:	4601                	li	a2,0
    80001386:	85ca                	mv	a1,s2
    80001388:	8552                	mv	a0,s4
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	c76080e7          	jalr	-906(ra) # 80001000 <walk>
    80001392:	84aa                	mv	s1,a0
    80001394:	d54d                	beqz	a0,8000133e <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001396:	6108                	ld	a0,0(a0)
    80001398:	00157793          	andi	a5,a0,1
    8000139c:	dbcd                	beqz	a5,8000134e <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000139e:	3ff57793          	andi	a5,a0,1023
    800013a2:	fb778ee3          	beq	a5,s7,8000135e <uvmunmap+0x76>
    if(do_free){
    800013a6:	fc0a8ae3          	beqz	s5,8000137a <uvmunmap+0x92>
    800013aa:	b7d1                	j	8000136e <uvmunmap+0x86>

00000000800013ac <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013ac:	1101                	addi	sp,sp,-32
    800013ae:	ec06                	sd	ra,24(sp)
    800013b0:	e822                	sd	s0,16(sp)
    800013b2:	e426                	sd	s1,8(sp)
    800013b4:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	76a080e7          	jalr	1898(ra) # 80000b20 <kalloc>
    800013be:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013c0:	c519                	beqz	a0,800013ce <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013c2:	6605                	lui	a2,0x1
    800013c4:	4581                	li	a1,0
    800013c6:	00000097          	auipc	ra,0x0
    800013ca:	946080e7          	jalr	-1722(ra) # 80000d0c <memset>
  return pagetable;
}
    800013ce:	8526                	mv	a0,s1
    800013d0:	60e2                	ld	ra,24(sp)
    800013d2:	6442                	ld	s0,16(sp)
    800013d4:	64a2                	ld	s1,8(sp)
    800013d6:	6105                	addi	sp,sp,32
    800013d8:	8082                	ret

00000000800013da <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013da:	7179                	addi	sp,sp,-48
    800013dc:	f406                	sd	ra,40(sp)
    800013de:	f022                	sd	s0,32(sp)
    800013e0:	ec26                	sd	s1,24(sp)
    800013e2:	e84a                	sd	s2,16(sp)
    800013e4:	e44e                	sd	s3,8(sp)
    800013e6:	e052                	sd	s4,0(sp)
    800013e8:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013ea:	6785                	lui	a5,0x1
    800013ec:	04f67863          	bgeu	a2,a5,8000143c <uvminit+0x62>
    800013f0:	8a2a                	mv	s4,a0
    800013f2:	89ae                	mv	s3,a1
    800013f4:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	72a080e7          	jalr	1834(ra) # 80000b20 <kalloc>
    800013fe:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	908080e7          	jalr	-1784(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000140c:	4779                	li	a4,30
    8000140e:	86ca                	mv	a3,s2
    80001410:	6605                	lui	a2,0x1
    80001412:	4581                	li	a1,0
    80001414:	8552                	mv	a0,s4
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	d3a080e7          	jalr	-710(ra) # 80001150 <mappages>
  memmove(mem, src, sz);
    8000141e:	8626                	mv	a2,s1
    80001420:	85ce                	mv	a1,s3
    80001422:	854a                	mv	a0,s2
    80001424:	00000097          	auipc	ra,0x0
    80001428:	948080e7          	jalr	-1720(ra) # 80000d6c <memmove>
}
    8000142c:	70a2                	ld	ra,40(sp)
    8000142e:	7402                	ld	s0,32(sp)
    80001430:	64e2                	ld	s1,24(sp)
    80001432:	6942                	ld	s2,16(sp)
    80001434:	69a2                	ld	s3,8(sp)
    80001436:	6a02                	ld	s4,0(sp)
    80001438:	6145                	addi	sp,sp,48
    8000143a:	8082                	ret
    panic("inituvm: more than a page");
    8000143c:	00007517          	auipc	a0,0x7
    80001440:	d0c50513          	addi	a0,a0,-756 # 80008148 <digits+0x108>
    80001444:	fffff097          	auipc	ra,0xfffff
    80001448:	104080e7          	jalr	260(ra) # 80000548 <panic>

000000008000144c <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000144c:	1101                	addi	sp,sp,-32
    8000144e:	ec06                	sd	ra,24(sp)
    80001450:	e822                	sd	s0,16(sp)
    80001452:	e426                	sd	s1,8(sp)
    80001454:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001456:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001458:	00b67d63          	bgeu	a2,a1,80001472 <uvmdealloc+0x26>
    8000145c:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000145e:	6785                	lui	a5,0x1
    80001460:	17fd                	addi	a5,a5,-1
    80001462:	00f60733          	add	a4,a2,a5
    80001466:	767d                	lui	a2,0xfffff
    80001468:	8f71                	and	a4,a4,a2
    8000146a:	97ae                	add	a5,a5,a1
    8000146c:	8ff1                	and	a5,a5,a2
    8000146e:	00f76863          	bltu	a4,a5,8000147e <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001472:	8526                	mv	a0,s1
    80001474:	60e2                	ld	ra,24(sp)
    80001476:	6442                	ld	s0,16(sp)
    80001478:	64a2                	ld	s1,8(sp)
    8000147a:	6105                	addi	sp,sp,32
    8000147c:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000147e:	8f99                	sub	a5,a5,a4
    80001480:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001482:	4685                	li	a3,1
    80001484:	0007861b          	sext.w	a2,a5
    80001488:	85ba                	mv	a1,a4
    8000148a:	00000097          	auipc	ra,0x0
    8000148e:	e5e080e7          	jalr	-418(ra) # 800012e8 <uvmunmap>
    80001492:	b7c5                	j	80001472 <uvmdealloc+0x26>

0000000080001494 <uvmalloc>:
  if(newsz < oldsz)
    80001494:	0ab66163          	bltu	a2,a1,80001536 <uvmalloc+0xa2>
{
    80001498:	7139                	addi	sp,sp,-64
    8000149a:	fc06                	sd	ra,56(sp)
    8000149c:	f822                	sd	s0,48(sp)
    8000149e:	f426                	sd	s1,40(sp)
    800014a0:	f04a                	sd	s2,32(sp)
    800014a2:	ec4e                	sd	s3,24(sp)
    800014a4:	e852                	sd	s4,16(sp)
    800014a6:	e456                	sd	s5,8(sp)
    800014a8:	0080                	addi	s0,sp,64
    800014aa:	8aaa                	mv	s5,a0
    800014ac:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014ae:	6985                	lui	s3,0x1
    800014b0:	19fd                	addi	s3,s3,-1
    800014b2:	95ce                	add	a1,a1,s3
    800014b4:	79fd                	lui	s3,0xfffff
    800014b6:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ba:	08c9f063          	bgeu	s3,a2,8000153a <uvmalloc+0xa6>
    800014be:	894e                	mv	s2,s3
    mem = kalloc();
    800014c0:	fffff097          	auipc	ra,0xfffff
    800014c4:	660080e7          	jalr	1632(ra) # 80000b20 <kalloc>
    800014c8:	84aa                	mv	s1,a0
    if(mem == 0){
    800014ca:	c51d                	beqz	a0,800014f8 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014cc:	6605                	lui	a2,0x1
    800014ce:	4581                	li	a1,0
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	83c080e7          	jalr	-1988(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014d8:	4779                	li	a4,30
    800014da:	86a6                	mv	a3,s1
    800014dc:	6605                	lui	a2,0x1
    800014de:	85ca                	mv	a1,s2
    800014e0:	8556                	mv	a0,s5
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	c6e080e7          	jalr	-914(ra) # 80001150 <mappages>
    800014ea:	e905                	bnez	a0,8000151a <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014ec:	6785                	lui	a5,0x1
    800014ee:	993e                	add	s2,s2,a5
    800014f0:	fd4968e3          	bltu	s2,s4,800014c0 <uvmalloc+0x2c>
  return newsz;
    800014f4:	8552                	mv	a0,s4
    800014f6:	a809                	j	80001508 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014f8:	864e                	mv	a2,s3
    800014fa:	85ca                	mv	a1,s2
    800014fc:	8556                	mv	a0,s5
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	f4e080e7          	jalr	-178(ra) # 8000144c <uvmdealloc>
      return 0;
    80001506:	4501                	li	a0,0
}
    80001508:	70e2                	ld	ra,56(sp)
    8000150a:	7442                	ld	s0,48(sp)
    8000150c:	74a2                	ld	s1,40(sp)
    8000150e:	7902                	ld	s2,32(sp)
    80001510:	69e2                	ld	s3,24(sp)
    80001512:	6a42                	ld	s4,16(sp)
    80001514:	6aa2                	ld	s5,8(sp)
    80001516:	6121                	addi	sp,sp,64
    80001518:	8082                	ret
      kfree(mem);
    8000151a:	8526                	mv	a0,s1
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	508080e7          	jalr	1288(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001524:	864e                	mv	a2,s3
    80001526:	85ca                	mv	a1,s2
    80001528:	8556                	mv	a0,s5
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f22080e7          	jalr	-222(ra) # 8000144c <uvmdealloc>
      return 0;
    80001532:	4501                	li	a0,0
    80001534:	bfd1                	j	80001508 <uvmalloc+0x74>
    return oldsz;
    80001536:	852e                	mv	a0,a1
}
    80001538:	8082                	ret
  return newsz;
    8000153a:	8532                	mv	a0,a2
    8000153c:	b7f1                	j	80001508 <uvmalloc+0x74>

000000008000153e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000153e:	7179                	addi	sp,sp,-48
    80001540:	f406                	sd	ra,40(sp)
    80001542:	f022                	sd	s0,32(sp)
    80001544:	ec26                	sd	s1,24(sp)
    80001546:	e84a                	sd	s2,16(sp)
    80001548:	e44e                	sd	s3,8(sp)
    8000154a:	e052                	sd	s4,0(sp)
    8000154c:	1800                	addi	s0,sp,48
    8000154e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001550:	84aa                	mv	s1,a0
    80001552:	6905                	lui	s2,0x1
    80001554:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001556:	4985                	li	s3,1
    80001558:	a821                	j	80001570 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000155a:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000155c:	0532                	slli	a0,a0,0xc
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	fe0080e7          	jalr	-32(ra) # 8000153e <freewalk>
      pagetable[i] = 0;
    80001566:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000156a:	04a1                	addi	s1,s1,8
    8000156c:	03248163          	beq	s1,s2,8000158e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001570:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001572:	00f57793          	andi	a5,a0,15
    80001576:	ff3782e3          	beq	a5,s3,8000155a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000157a:	8905                	andi	a0,a0,1
    8000157c:	d57d                	beqz	a0,8000156a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000157e:	00007517          	auipc	a0,0x7
    80001582:	bea50513          	addi	a0,a0,-1046 # 80008168 <digits+0x128>
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	fc2080e7          	jalr	-62(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158e:	8552                	mv	a0,s4
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	494080e7          	jalr	1172(ra) # 80000a24 <kfree>
}
    80001598:	70a2                	ld	ra,40(sp)
    8000159a:	7402                	ld	s0,32(sp)
    8000159c:	64e2                	ld	s1,24(sp)
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	69a2                	ld	s3,8(sp)
    800015a2:	6a02                	ld	s4,0(sp)
    800015a4:	6145                	addi	sp,sp,48
    800015a6:	8082                	ret

00000000800015a8 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a8:	1101                	addi	sp,sp,-32
    800015aa:	ec06                	sd	ra,24(sp)
    800015ac:	e822                	sd	s0,16(sp)
    800015ae:	e426                	sd	s1,8(sp)
    800015b0:	1000                	addi	s0,sp,32
    800015b2:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b4:	e999                	bnez	a1,800015ca <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b6:	8526                	mv	a0,s1
    800015b8:	00000097          	auipc	ra,0x0
    800015bc:	f86080e7          	jalr	-122(ra) # 8000153e <freewalk>
}
    800015c0:	60e2                	ld	ra,24(sp)
    800015c2:	6442                	ld	s0,16(sp)
    800015c4:	64a2                	ld	s1,8(sp)
    800015c6:	6105                	addi	sp,sp,32
    800015c8:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015ca:	6605                	lui	a2,0x1
    800015cc:	167d                	addi	a2,a2,-1
    800015ce:	962e                	add	a2,a2,a1
    800015d0:	4685                	li	a3,1
    800015d2:	8231                	srli	a2,a2,0xc
    800015d4:	4581                	li	a1,0
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	d12080e7          	jalr	-750(ra) # 800012e8 <uvmunmap>
    800015de:	bfe1                	j	800015b6 <uvmfree+0xe>

00000000800015e0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015e0:	c679                	beqz	a2,800016ae <uvmcopy+0xce>
{
    800015e2:	715d                	addi	sp,sp,-80
    800015e4:	e486                	sd	ra,72(sp)
    800015e6:	e0a2                	sd	s0,64(sp)
    800015e8:	fc26                	sd	s1,56(sp)
    800015ea:	f84a                	sd	s2,48(sp)
    800015ec:	f44e                	sd	s3,40(sp)
    800015ee:	f052                	sd	s4,32(sp)
    800015f0:	ec56                	sd	s5,24(sp)
    800015f2:	e85a                	sd	s6,16(sp)
    800015f4:	e45e                	sd	s7,8(sp)
    800015f6:	0880                	addi	s0,sp,80
    800015f8:	8b2a                	mv	s6,a0
    800015fa:	8aae                	mv	s5,a1
    800015fc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fe:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001600:	4601                	li	a2,0
    80001602:	85ce                	mv	a1,s3
    80001604:	855a                	mv	a0,s6
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	9fa080e7          	jalr	-1542(ra) # 80001000 <walk>
    8000160e:	c531                	beqz	a0,8000165a <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001610:	6118                	ld	a4,0(a0)
    80001612:	00177793          	andi	a5,a4,1
    80001616:	cbb1                	beqz	a5,8000166a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001618:	00a75593          	srli	a1,a4,0xa
    8000161c:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001620:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001624:	fffff097          	auipc	ra,0xfffff
    80001628:	4fc080e7          	jalr	1276(ra) # 80000b20 <kalloc>
    8000162c:	892a                	mv	s2,a0
    8000162e:	c939                	beqz	a0,80001684 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001630:	6605                	lui	a2,0x1
    80001632:	85de                	mv	a1,s7
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	738080e7          	jalr	1848(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163c:	8726                	mv	a4,s1
    8000163e:	86ca                	mv	a3,s2
    80001640:	6605                	lui	a2,0x1
    80001642:	85ce                	mv	a1,s3
    80001644:	8556                	mv	a0,s5
    80001646:	00000097          	auipc	ra,0x0
    8000164a:	b0a080e7          	jalr	-1270(ra) # 80001150 <mappages>
    8000164e:	e515                	bnez	a0,8000167a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001650:	6785                	lui	a5,0x1
    80001652:	99be                	add	s3,s3,a5
    80001654:	fb49e6e3          	bltu	s3,s4,80001600 <uvmcopy+0x20>
    80001658:	a081                	j	80001698 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000165a:	00007517          	auipc	a0,0x7
    8000165e:	b1e50513          	addi	a0,a0,-1250 # 80008178 <digits+0x138>
    80001662:	fffff097          	auipc	ra,0xfffff
    80001666:	ee6080e7          	jalr	-282(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000166a:	00007517          	auipc	a0,0x7
    8000166e:	b2e50513          	addi	a0,a0,-1234 # 80008198 <digits+0x158>
    80001672:	fffff097          	auipc	ra,0xfffff
    80001676:	ed6080e7          	jalr	-298(ra) # 80000548 <panic>
      kfree(mem);
    8000167a:	854a                	mv	a0,s2
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	3a8080e7          	jalr	936(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001684:	4685                	li	a3,1
    80001686:	00c9d613          	srli	a2,s3,0xc
    8000168a:	4581                	li	a1,0
    8000168c:	8556                	mv	a0,s5
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	c5a080e7          	jalr	-934(ra) # 800012e8 <uvmunmap>
  return -1;
    80001696:	557d                	li	a0,-1
}
    80001698:	60a6                	ld	ra,72(sp)
    8000169a:	6406                	ld	s0,64(sp)
    8000169c:	74e2                	ld	s1,56(sp)
    8000169e:	7942                	ld	s2,48(sp)
    800016a0:	79a2                	ld	s3,40(sp)
    800016a2:	7a02                	ld	s4,32(sp)
    800016a4:	6ae2                	ld	s5,24(sp)
    800016a6:	6b42                	ld	s6,16(sp)
    800016a8:	6ba2                	ld	s7,8(sp)
    800016aa:	6161                	addi	sp,sp,80
    800016ac:	8082                	ret
  return 0;
    800016ae:	4501                	li	a0,0
}
    800016b0:	8082                	ret

00000000800016b2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b2:	1141                	addi	sp,sp,-16
    800016b4:	e406                	sd	ra,8(sp)
    800016b6:	e022                	sd	s0,0(sp)
    800016b8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016ba:	4601                	li	a2,0
    800016bc:	00000097          	auipc	ra,0x0
    800016c0:	944080e7          	jalr	-1724(ra) # 80001000 <walk>
  if(pte == 0)
    800016c4:	c901                	beqz	a0,800016d4 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c6:	611c                	ld	a5,0(a0)
    800016c8:	9bbd                	andi	a5,a5,-17
    800016ca:	e11c                	sd	a5,0(a0)
}
    800016cc:	60a2                	ld	ra,8(sp)
    800016ce:	6402                	ld	s0,0(sp)
    800016d0:	0141                	addi	sp,sp,16
    800016d2:	8082                	ret
    panic("uvmclear");
    800016d4:	00007517          	auipc	a0,0x7
    800016d8:	ae450513          	addi	a0,a0,-1308 # 800081b8 <digits+0x178>
    800016dc:	fffff097          	auipc	ra,0xfffff
    800016e0:	e6c080e7          	jalr	-404(ra) # 80000548 <panic>

00000000800016e4 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e4:	c6bd                	beqz	a3,80001752 <copyout+0x6e>
{
    800016e6:	715d                	addi	sp,sp,-80
    800016e8:	e486                	sd	ra,72(sp)
    800016ea:	e0a2                	sd	s0,64(sp)
    800016ec:	fc26                	sd	s1,56(sp)
    800016ee:	f84a                	sd	s2,48(sp)
    800016f0:	f44e                	sd	s3,40(sp)
    800016f2:	f052                	sd	s4,32(sp)
    800016f4:	ec56                	sd	s5,24(sp)
    800016f6:	e85a                	sd	s6,16(sp)
    800016f8:	e45e                	sd	s7,8(sp)
    800016fa:	e062                	sd	s8,0(sp)
    800016fc:	0880                	addi	s0,sp,80
    800016fe:	8b2a                	mv	s6,a0
    80001700:	8c2e                	mv	s8,a1
    80001702:	8a32                	mv	s4,a2
    80001704:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001706:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001708:	6a85                	lui	s5,0x1
    8000170a:	a015                	j	8000172e <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170c:	9562                	add	a0,a0,s8
    8000170e:	0004861b          	sext.w	a2,s1
    80001712:	85d2                	mv	a1,s4
    80001714:	41250533          	sub	a0,a0,s2
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	654080e7          	jalr	1620(ra) # 80000d6c <memmove>

    len -= n;
    80001720:	409989b3          	sub	s3,s3,s1
    src += n;
    80001724:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001726:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000172a:	02098263          	beqz	s3,8000174e <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001732:	85ca                	mv	a1,s2
    80001734:	855a                	mv	a0,s6
    80001736:	00000097          	auipc	ra,0x0
    8000173a:	970080e7          	jalr	-1680(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000173e:	cd01                	beqz	a0,80001756 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001740:	418904b3          	sub	s1,s2,s8
    80001744:	94d6                	add	s1,s1,s5
    if(n > len)
    80001746:	fc99f3e3          	bgeu	s3,s1,8000170c <copyout+0x28>
    8000174a:	84ce                	mv	s1,s3
    8000174c:	b7c1                	j	8000170c <copyout+0x28>
  }
  return 0;
    8000174e:	4501                	li	a0,0
    80001750:	a021                	j	80001758 <copyout+0x74>
    80001752:	4501                	li	a0,0
}
    80001754:	8082                	ret
      return -1;
    80001756:	557d                	li	a0,-1
}
    80001758:	60a6                	ld	ra,72(sp)
    8000175a:	6406                	ld	s0,64(sp)
    8000175c:	74e2                	ld	s1,56(sp)
    8000175e:	7942                	ld	s2,48(sp)
    80001760:	79a2                	ld	s3,40(sp)
    80001762:	7a02                	ld	s4,32(sp)
    80001764:	6ae2                	ld	s5,24(sp)
    80001766:	6b42                	ld	s6,16(sp)
    80001768:	6ba2                	ld	s7,8(sp)
    8000176a:	6c02                	ld	s8,0(sp)
    8000176c:	6161                	addi	sp,sp,80
    8000176e:	8082                	ret

0000000080001770 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80001770:	1141                	addi	sp,sp,-16
    80001772:	e406                	sd	ra,8(sp)
    80001774:	e022                	sd	s0,0(sp)
    80001776:	0800                	addi	s0,sp,16
    len -= n;
    dst += n;
    srcva = va0 + PGSIZE;
  }
  return 0;*/
  return copyin_new(pagetable, dst,  srcva,  len);
    80001778:	00005097          	auipc	ra,0x5
    8000177c:	d88080e7          	jalr	-632(ra) # 80006500 <copyin_new>
  

}
    80001780:	60a2                	ld	ra,8(sp)
    80001782:	6402                	ld	s0,0(sp)
    80001784:	0141                	addi	sp,sp,16
    80001786:	8082                	ret

0000000080001788 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001788:	1141                	addi	sp,sp,-16
    8000178a:	e406                	sd	ra,8(sp)
    8000178c:	e022                	sd	s0,0(sp)
    8000178e:	0800                	addi	s0,sp,16
    return 0;
  } else {
    return -1;
  } */
  
 return copyinstr_new(pagetable, dst, srcva, max);
    80001790:	00005097          	auipc	ra,0x5
    80001794:	dd8080e7          	jalr	-552(ra) # 80006568 <copyinstr_new>


}
    80001798:	60a2                	ld	ra,8(sp)
    8000179a:	6402                	ld	s0,0(sp)
    8000179c:	0141                	addi	sp,sp,16
    8000179e:	8082                	ret

00000000800017a0 <_rvmprint>:
  printf("page table %p\n",pagetable);
  int level=0;
  _rvmprint((pagetable_t)pagetable,level);
}

void _rvmprint(pagetable_t pagetable,int level){
    800017a0:	711d                	addi	sp,sp,-96
    800017a2:	ec86                	sd	ra,88(sp)
    800017a4:	e8a2                	sd	s0,80(sp)
    800017a6:	e4a6                	sd	s1,72(sp)
    800017a8:	e0ca                	sd	s2,64(sp)
    800017aa:	fc4e                	sd	s3,56(sp)
    800017ac:	f852                	sd	s4,48(sp)
    800017ae:	f456                	sd	s5,40(sp)
    800017b0:	f05a                	sd	s6,32(sp)
    800017b2:	ec5e                	sd	s7,24(sp)
    800017b4:	e862                	sd	s8,16(sp)
    800017b6:	e466                	sd	s9,8(sp)
    800017b8:	1080                	addi	s0,sp,96
    800017ba:	8a2e                	mv	s4,a1
  for(int i=0;i<512;i++){
    800017bc:	892a                	mv	s2,a0
    800017be:	4481                	li	s1,0
    pte_t pte=pagetable[i];
    if(pte&PTE_V){
      if(level==0){
        printf("..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
        _rvmprint((pagetable_t)PTE2PA(pte),level+1);
      }else if(level==1){
    800017c0:	4b05                	li	s6,1
        printf(".. ..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
        _rvmprint((pagetable_t)PTE2PA(pte),level+1);
      }else{
         printf(".. .. ..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    800017c2:	00007b97          	auipc	s7,0x7
    800017c6:	a36b8b93          	addi	s7,s7,-1482 # 800081f8 <digits+0x1b8>
        printf(".. ..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    800017ca:	00007c97          	auipc	s9,0x7
    800017ce:	a16c8c93          	addi	s9,s9,-1514 # 800081e0 <digits+0x1a0>
        printf("..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    800017d2:	00007c17          	auipc	s8,0x7
    800017d6:	9f6c0c13          	addi	s8,s8,-1546 # 800081c8 <digits+0x188>
  for(int i=0;i<512;i++){
    800017da:	20000993          	li	s3,512
    800017de:	a83d                	j	8000181c <_rvmprint+0x7c>
        printf("..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    800017e0:	00a65a93          	srli	s5,a2,0xa
    800017e4:	0ab2                	slli	s5,s5,0xc
    800017e6:	86d6                	mv	a3,s5
    800017e8:	85a6                	mv	a1,s1
    800017ea:	8562                	mv	a0,s8
    800017ec:	fffff097          	auipc	ra,0xfffff
    800017f0:	da6080e7          	jalr	-602(ra) # 80000592 <printf>
        _rvmprint((pagetable_t)PTE2PA(pte),level+1);
    800017f4:	85da                	mv	a1,s6
    800017f6:	8556                	mv	a0,s5
    800017f8:	00000097          	auipc	ra,0x0
    800017fc:	fa8080e7          	jalr	-88(ra) # 800017a0 <_rvmprint>
    80001800:	a811                	j	80001814 <_rvmprint+0x74>
         printf(".. .. ..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    80001802:	00a65693          	srli	a3,a2,0xa
    80001806:	06b2                	slli	a3,a3,0xc
    80001808:	85a6                	mv	a1,s1
    8000180a:	855e                	mv	a0,s7
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	d86080e7          	jalr	-634(ra) # 80000592 <printf>
  for(int i=0;i<512;i++){
    80001814:	2485                	addiw	s1,s1,1
    80001816:	0921                	addi	s2,s2,8
    80001818:	03348c63          	beq	s1,s3,80001850 <_rvmprint+0xb0>
    pte_t pte=pagetable[i];
    8000181c:	00093603          	ld	a2,0(s2) # 1000 <_entry-0x7ffff000>
    if(pte&PTE_V){
    80001820:	00167793          	andi	a5,a2,1
    80001824:	dbe5                	beqz	a5,80001814 <_rvmprint+0x74>
      if(level==0){
    80001826:	fa0a0de3          	beqz	s4,800017e0 <_rvmprint+0x40>
      }else if(level==1){
    8000182a:	fd6a1ce3          	bne	s4,s6,80001802 <_rvmprint+0x62>
        printf(".. ..%d: pte %p pa %p\n",i,pte,PTE2PA(pte));
    8000182e:	00a65a93          	srli	s5,a2,0xa
    80001832:	0ab2                	slli	s5,s5,0xc
    80001834:	86d6                	mv	a3,s5
    80001836:	85a6                	mv	a1,s1
    80001838:	8566                	mv	a0,s9
    8000183a:	fffff097          	auipc	ra,0xfffff
    8000183e:	d58080e7          	jalr	-680(ra) # 80000592 <printf>
        _rvmprint((pagetable_t)PTE2PA(pte),level+1);
    80001842:	4589                	li	a1,2
    80001844:	8556                	mv	a0,s5
    80001846:	00000097          	auipc	ra,0x0
    8000184a:	f5a080e7          	jalr	-166(ra) # 800017a0 <_rvmprint>
    8000184e:	b7d9                	j	80001814 <_rvmprint+0x74>
      }
    }
  }
}
    80001850:	60e6                	ld	ra,88(sp)
    80001852:	6446                	ld	s0,80(sp)
    80001854:	64a6                	ld	s1,72(sp)
    80001856:	6906                	ld	s2,64(sp)
    80001858:	79e2                	ld	s3,56(sp)
    8000185a:	7a42                	ld	s4,48(sp)
    8000185c:	7aa2                	ld	s5,40(sp)
    8000185e:	7b02                	ld	s6,32(sp)
    80001860:	6be2                	ld	s7,24(sp)
    80001862:	6c42                	ld	s8,16(sp)
    80001864:	6ca2                	ld	s9,8(sp)
    80001866:	6125                	addi	sp,sp,96
    80001868:	8082                	ret

000000008000186a <vmprint>:
void vmprint(pagetable_t pagetable){
    8000186a:	1101                	addi	sp,sp,-32
    8000186c:	ec06                	sd	ra,24(sp)
    8000186e:	e822                	sd	s0,16(sp)
    80001870:	e426                	sd	s1,8(sp)
    80001872:	1000                	addi	s0,sp,32
    80001874:	84aa                	mv	s1,a0
  printf("page table %p\n",pagetable);
    80001876:	85aa                	mv	a1,a0
    80001878:	00007517          	auipc	a0,0x7
    8000187c:	9a050513          	addi	a0,a0,-1632 # 80008218 <digits+0x1d8>
    80001880:	fffff097          	auipc	ra,0xfffff
    80001884:	d12080e7          	jalr	-750(ra) # 80000592 <printf>
  _rvmprint((pagetable_t)pagetable,level);
    80001888:	4581                	li	a1,0
    8000188a:	8526                	mv	a0,s1
    8000188c:	00000097          	auipc	ra,0x0
    80001890:	f14080e7          	jalr	-236(ra) # 800017a0 <_rvmprint>
}
    80001894:	60e2                	ld	ra,24(sp)
    80001896:	6442                	ld	s0,16(sp)
    80001898:	64a2                	ld	s1,8(sp)
    8000189a:	6105                	addi	sp,sp,32
    8000189c:	8082                	ret

000000008000189e <uvmmap>:
  return prockerneltable;
}

void 
uvmmap(pagetable_t pagetable, uint64 va, uint64 pa, uint64 sz, int perm)
{
    8000189e:	1141                	addi	sp,sp,-16
    800018a0:	e406                	sd	ra,8(sp)
    800018a2:	e022                	sd	s0,0(sp)
    800018a4:	0800                	addi	s0,sp,16
    800018a6:	87b6                	mv	a5,a3
  if(mappages(pagetable, va, sz, pa, perm) != 0)
    800018a8:	86b2                	mv	a3,a2
    800018aa:	863e                	mv	a2,a5
    800018ac:	00000097          	auipc	ra,0x0
    800018b0:	8a4080e7          	jalr	-1884(ra) # 80001150 <mappages>
    800018b4:	e509                	bnez	a0,800018be <uvmmap+0x20>
    panic("kvmmap");
}
    800018b6:	60a2                	ld	ra,8(sp)
    800018b8:	6402                	ld	s0,0(sp)
    800018ba:	0141                	addi	sp,sp,16
    800018bc:	8082                	ret
    panic("kvmmap");
    800018be:	00007517          	auipc	a0,0x7
    800018c2:	82a50513          	addi	a0,a0,-2006 # 800080e8 <digits+0xa8>
    800018c6:	fffff097          	auipc	ra,0xfffff
    800018ca:	c82080e7          	jalr	-894(ra) # 80000548 <panic>

00000000800018ce <prockernelinit>:
pagetable_t prockernelinit(void){
    800018ce:	1101                	addi	sp,sp,-32
    800018d0:	ec06                	sd	ra,24(sp)
    800018d2:	e822                	sd	s0,16(sp)
    800018d4:	e426                	sd	s1,8(sp)
    800018d6:	e04a                	sd	s2,0(sp)
    800018d8:	1000                	addi	s0,sp,32
  pagetable_t prockerneltable=uvmcreate();
    800018da:	00000097          	auipc	ra,0x0
    800018de:	ad2080e7          	jalr	-1326(ra) # 800013ac <uvmcreate>
    800018e2:	84aa                	mv	s1,a0
  if (prockerneltable == 0) return 0;
    800018e4:	c94d                	beqz	a0,80001996 <prockernelinit+0xc8>
  uvmmap(prockerneltable, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800018e6:	4719                	li	a4,6
    800018e8:	6685                	lui	a3,0x1
    800018ea:	10000637          	lui	a2,0x10000
    800018ee:	100005b7          	lui	a1,0x10000
    800018f2:	00000097          	auipc	ra,0x0
    800018f6:	fac080e7          	jalr	-84(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800018fa:	4719                	li	a4,6
    800018fc:	6685                	lui	a3,0x1
    800018fe:	10001637          	lui	a2,0x10001
    80001902:	100015b7          	lui	a1,0x10001
    80001906:	8526                	mv	a0,s1
    80001908:	00000097          	auipc	ra,0x0
    8000190c:	f96080e7          	jalr	-106(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001910:	4719                	li	a4,6
    80001912:	66c1                	lui	a3,0x10
    80001914:	02000637          	lui	a2,0x2000
    80001918:	020005b7          	lui	a1,0x2000
    8000191c:	8526                	mv	a0,s1
    8000191e:	00000097          	auipc	ra,0x0
    80001922:	f80080e7          	jalr	-128(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001926:	4719                	li	a4,6
    80001928:	004006b7          	lui	a3,0x400
    8000192c:	0c000637          	lui	a2,0xc000
    80001930:	0c0005b7          	lui	a1,0xc000
    80001934:	8526                	mv	a0,s1
    80001936:	00000097          	auipc	ra,0x0
    8000193a:	f68080e7          	jalr	-152(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000193e:	00006917          	auipc	s2,0x6
    80001942:	6c290913          	addi	s2,s2,1730 # 80008000 <etext>
    80001946:	4729                	li	a4,10
    80001948:	80006697          	auipc	a3,0x80006
    8000194c:	6b868693          	addi	a3,a3,1720 # 8000 <_entry-0x7fff8000>
    80001950:	4605                	li	a2,1
    80001952:	067e                	slli	a2,a2,0x1f
    80001954:	85b2                	mv	a1,a2
    80001956:	8526                	mv	a0,s1
    80001958:	00000097          	auipc	ra,0x0
    8000195c:	f46080e7          	jalr	-186(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001960:	4719                	li	a4,6
    80001962:	46c5                	li	a3,17
    80001964:	06ee                	slli	a3,a3,0x1b
    80001966:	412686b3          	sub	a3,a3,s2
    8000196a:	864a                	mv	a2,s2
    8000196c:	85ca                	mv	a1,s2
    8000196e:	8526                	mv	a0,s1
    80001970:	00000097          	auipc	ra,0x0
    80001974:	f2e080e7          	jalr	-210(ra) # 8000189e <uvmmap>
  uvmmap(prockerneltable, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001978:	4729                	li	a4,10
    8000197a:	6685                	lui	a3,0x1
    8000197c:	00005617          	auipc	a2,0x5
    80001980:	68460613          	addi	a2,a2,1668 # 80007000 <_trampoline>
    80001984:	040005b7          	lui	a1,0x4000
    80001988:	15fd                	addi	a1,a1,-1
    8000198a:	05b2                	slli	a1,a1,0xc
    8000198c:	8526                	mv	a0,s1
    8000198e:	00000097          	auipc	ra,0x0
    80001992:	f10080e7          	jalr	-240(ra) # 8000189e <uvmmap>
}
    80001996:	8526                	mv	a0,s1
    80001998:	60e2                	ld	ra,24(sp)
    8000199a:	6442                	ld	s0,16(sp)
    8000199c:	64a2                	ld	s1,8(sp)
    8000199e:	6902                	ld	s2,0(sp)
    800019a0:	6105                	addi	sp,sp,32
    800019a2:	8082                	ret

00000000800019a4 <procuser2kernel>:
{
  pte_t *pte_from, *pte_to;
  uint64 a, pa;
  uint flags;

  if (newsz < oldsz)
    800019a4:	0ac6e063          	bltu	a3,a2,80001a44 <procuser2kernel+0xa0>
{
    800019a8:	715d                	addi	sp,sp,-80
    800019aa:	e486                	sd	ra,72(sp)
    800019ac:	e0a2                	sd	s0,64(sp)
    800019ae:	fc26                	sd	s1,56(sp)
    800019b0:	f84a                	sd	s2,48(sp)
    800019b2:	f44e                	sd	s3,40(sp)
    800019b4:	f052                	sd	s4,32(sp)
    800019b6:	ec56                	sd	s5,24(sp)
    800019b8:	e85a                	sd	s6,16(sp)
    800019ba:	e45e                	sd	s7,8(sp)
    800019bc:	0880                	addi	s0,sp,80
    800019be:	8a2a                	mv	s4,a0
    800019c0:	8aae                	mv	s5,a1
    800019c2:	89b6                	mv	s3,a3
    return;
  
  oldsz = PGROUNDUP(oldsz);
    800019c4:	6485                	lui	s1,0x1
    800019c6:	14fd                	addi	s1,s1,-1
    800019c8:	9626                	add	a2,a2,s1
    800019ca:	74fd                	lui	s1,0xfffff
    800019cc:	8cf1                	and	s1,s1,a2
  for (a = oldsz; a < newsz; a += PGSIZE)
    800019ce:	04d4f063          	bgeu	s1,a3,80001a0e <procuser2kernel+0x6a>
    if ((pte_to = walk(kpagetable, a, 1)) == 0)
      panic("u2kvmcopy: walk fails");
    pa = PTE2PA(*pte_from);
    // 清除PTE_U的标记位
    flags = (PTE_FLAGS(*pte_from) & (~PTE_U));
    *pte_to = PA2PTE(pa) | flags;
    800019d2:	7b7d                	lui	s6,0xfffff
    800019d4:	002b5b13          	srli	s6,s6,0x2
  for (a = oldsz; a < newsz; a += PGSIZE)
    800019d8:	6b85                	lui	s7,0x1
    if ((pte_from = walk(pagetable, a, 0)) == 0)
    800019da:	4601                	li	a2,0
    800019dc:	85a6                	mv	a1,s1
    800019de:	8552                	mv	a0,s4
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	620080e7          	jalr	1568(ra) # 80001000 <walk>
    800019e8:	892a                	mv	s2,a0
    800019ea:	cd0d                	beqz	a0,80001a24 <procuser2kernel+0x80>
    if ((pte_to = walk(kpagetable, a, 1)) == 0)
    800019ec:	4605                	li	a2,1
    800019ee:	85a6                	mv	a1,s1
    800019f0:	8556                	mv	a0,s5
    800019f2:	fffff097          	auipc	ra,0xfffff
    800019f6:	60e080e7          	jalr	1550(ra) # 80001000 <walk>
    800019fa:	cd0d                	beqz	a0,80001a34 <procuser2kernel+0x90>
    pa = PTE2PA(*pte_from);
    800019fc:	00093703          	ld	a4,0(s2)
    *pte_to = PA2PTE(pa) | flags;
    80001a00:	3efb6793          	ori	a5,s6,1007
    80001a04:	8ff9                	and	a5,a5,a4
    80001a06:	e11c                	sd	a5,0(a0)
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001a08:	94de                	add	s1,s1,s7
    80001a0a:	fd34e8e3          	bltu	s1,s3,800019da <procuser2kernel+0x36>
  }
}
    80001a0e:	60a6                	ld	ra,72(sp)
    80001a10:	6406                	ld	s0,64(sp)
    80001a12:	74e2                	ld	s1,56(sp)
    80001a14:	7942                	ld	s2,48(sp)
    80001a16:	79a2                	ld	s3,40(sp)
    80001a18:	7a02                	ld	s4,32(sp)
    80001a1a:	6ae2                	ld	s5,24(sp)
    80001a1c:	6b42                	ld	s6,16(sp)
    80001a1e:	6ba2                	ld	s7,8(sp)
    80001a20:	6161                	addi	sp,sp,80
    80001a22:	8082                	ret
      panic("u2kvmcopy: pte should exist");
    80001a24:	00007517          	auipc	a0,0x7
    80001a28:	80450513          	addi	a0,a0,-2044 # 80008228 <digits+0x1e8>
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	b1c080e7          	jalr	-1252(ra) # 80000548 <panic>
      panic("u2kvmcopy: walk fails");
    80001a34:	00007517          	auipc	a0,0x7
    80001a38:	81450513          	addi	a0,a0,-2028 # 80008248 <digits+0x208>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b0c080e7          	jalr	-1268(ra) # 80000548 <panic>
    80001a44:	8082                	ret

0000000080001a46 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a46:	1101                	addi	sp,sp,-32
    80001a48:	ec06                	sd	ra,24(sp)
    80001a4a:	e822                	sd	s0,16(sp)
    80001a4c:	e426                	sd	s1,8(sp)
    80001a4e:	1000                	addi	s0,sp,32
    80001a50:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	144080e7          	jalr	324(ra) # 80000b96 <holding>
    80001a5a:	c909                	beqz	a0,80001a6c <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a5c:	749c                	ld	a5,40(s1)
    80001a5e:	00978f63          	beq	a5,s1,80001a7c <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a62:	60e2                	ld	ra,24(sp)
    80001a64:	6442                	ld	s0,16(sp)
    80001a66:	64a2                	ld	s1,8(sp)
    80001a68:	6105                	addi	sp,sp,32
    80001a6a:	8082                	ret
    panic("wakeup1");
    80001a6c:	00006517          	auipc	a0,0x6
    80001a70:	7f450513          	addi	a0,a0,2036 # 80008260 <digits+0x220>
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	ad4080e7          	jalr	-1324(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a7c:	4c98                	lw	a4,24(s1)
    80001a7e:	4785                	li	a5,1
    80001a80:	fef711e3          	bne	a4,a5,80001a62 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a84:	4789                	li	a5,2
    80001a86:	cc9c                	sw	a5,24(s1)
}
    80001a88:	bfe9                	j	80001a62 <wakeup1+0x1c>

0000000080001a8a <procinit>:
{
    80001a8a:	7179                	addi	sp,sp,-48
    80001a8c:	f406                	sd	ra,40(sp)
    80001a8e:	f022                	sd	s0,32(sp)
    80001a90:	ec26                	sd	s1,24(sp)
    80001a92:	e84a                	sd	s2,16(sp)
    80001a94:	e44e                	sd	s3,8(sp)
    80001a96:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001a98:	00006597          	auipc	a1,0x6
    80001a9c:	7d058593          	addi	a1,a1,2000 # 80008268 <digits+0x228>
    80001aa0:	00010517          	auipc	a0,0x10
    80001aa4:	eb050513          	addi	a0,a0,-336 # 80011950 <pid_lock>
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	0d8080e7          	jalr	216(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ab0:	00010497          	auipc	s1,0x10
    80001ab4:	2b848493          	addi	s1,s1,696 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001ab8:	00006997          	auipc	s3,0x6
    80001abc:	7b898993          	addi	s3,s3,1976 # 80008270 <digits+0x230>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ac0:	00016917          	auipc	s2,0x16
    80001ac4:	ea890913          	addi	s2,s2,-344 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001ac8:	85ce                	mv	a1,s3
    80001aca:	8526                	mv	a0,s1
    80001acc:	fffff097          	auipc	ra,0xfffff
    80001ad0:	0b4080e7          	jalr	180(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad4:	17048493          	addi	s1,s1,368
    80001ad8:	ff2498e3          	bne	s1,s2,80001ac8 <procinit+0x3e>
}
    80001adc:	70a2                	ld	ra,40(sp)
    80001ade:	7402                	ld	s0,32(sp)
    80001ae0:	64e2                	ld	s1,24(sp)
    80001ae2:	6942                	ld	s2,16(sp)
    80001ae4:	69a2                	ld	s3,8(sp)
    80001ae6:	6145                	addi	sp,sp,48
    80001ae8:	8082                	ret

0000000080001aea <cpuid>:
{
    80001aea:	1141                	addi	sp,sp,-16
    80001aec:	e422                	sd	s0,8(sp)
    80001aee:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001af0:	8512                	mv	a0,tp
}
    80001af2:	2501                	sext.w	a0,a0
    80001af4:	6422                	ld	s0,8(sp)
    80001af6:	0141                	addi	sp,sp,16
    80001af8:	8082                	ret

0000000080001afa <mycpu>:
mycpu(void) {
    80001afa:	1141                	addi	sp,sp,-16
    80001afc:	e422                	sd	s0,8(sp)
    80001afe:	0800                	addi	s0,sp,16
    80001b00:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b02:	2781                	sext.w	a5,a5
    80001b04:	079e                	slli	a5,a5,0x7
}
    80001b06:	00010517          	auipc	a0,0x10
    80001b0a:	e6250513          	addi	a0,a0,-414 # 80011968 <cpus>
    80001b0e:	953e                	add	a0,a0,a5
    80001b10:	6422                	ld	s0,8(sp)
    80001b12:	0141                	addi	sp,sp,16
    80001b14:	8082                	ret

0000000080001b16 <myproc>:
myproc(void) {
    80001b16:	1101                	addi	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	e426                	sd	s1,8(sp)
    80001b1e:	1000                	addi	s0,sp,32
  push_off();
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	0a4080e7          	jalr	164(ra) # 80000bc4 <push_off>
    80001b28:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b2a:	2781                	sext.w	a5,a5
    80001b2c:	079e                	slli	a5,a5,0x7
    80001b2e:	00010717          	auipc	a4,0x10
    80001b32:	e2270713          	addi	a4,a4,-478 # 80011950 <pid_lock>
    80001b36:	97ba                	add	a5,a5,a4
    80001b38:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b3a:	fffff097          	auipc	ra,0xfffff
    80001b3e:	12a080e7          	jalr	298(ra) # 80000c64 <pop_off>
}
    80001b42:	8526                	mv	a0,s1
    80001b44:	60e2                	ld	ra,24(sp)
    80001b46:	6442                	ld	s0,16(sp)
    80001b48:	64a2                	ld	s1,8(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret

0000000080001b4e <forkret>:
{
    80001b4e:	1141                	addi	sp,sp,-16
    80001b50:	e406                	sd	ra,8(sp)
    80001b52:	e022                	sd	s0,0(sp)
    80001b54:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	fc0080e7          	jalr	-64(ra) # 80001b16 <myproc>
    80001b5e:	fffff097          	auipc	ra,0xfffff
    80001b62:	166080e7          	jalr	358(ra) # 80000cc4 <release>
  if (first) {
    80001b66:	00007797          	auipc	a5,0x7
    80001b6a:	d9a7a783          	lw	a5,-614(a5) # 80008900 <first.1716>
    80001b6e:	eb89                	bnez	a5,80001b80 <forkret+0x32>
  usertrapret();
    80001b70:	00001097          	auipc	ra,0x1
    80001b74:	dd8080e7          	jalr	-552(ra) # 80002948 <usertrapret>
}
    80001b78:	60a2                	ld	ra,8(sp)
    80001b7a:	6402                	ld	s0,0(sp)
    80001b7c:	0141                	addi	sp,sp,16
    80001b7e:	8082                	ret
    first = 0;
    80001b80:	00007797          	auipc	a5,0x7
    80001b84:	d807a023          	sw	zero,-640(a5) # 80008900 <first.1716>
    fsinit(ROOTDEV);
    80001b88:	4505                	li	a0,1
    80001b8a:	00002097          	auipc	ra,0x2
    80001b8e:	b00080e7          	jalr	-1280(ra) # 8000368a <fsinit>
    80001b92:	bff9                	j	80001b70 <forkret+0x22>

0000000080001b94 <allocpid>:
allocpid() {
    80001b94:	1101                	addi	sp,sp,-32
    80001b96:	ec06                	sd	ra,24(sp)
    80001b98:	e822                	sd	s0,16(sp)
    80001b9a:	e426                	sd	s1,8(sp)
    80001b9c:	e04a                	sd	s2,0(sp)
    80001b9e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ba0:	00010917          	auipc	s2,0x10
    80001ba4:	db090913          	addi	s2,s2,-592 # 80011950 <pid_lock>
    80001ba8:	854a                	mv	a0,s2
    80001baa:	fffff097          	auipc	ra,0xfffff
    80001bae:	066080e7          	jalr	102(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001bb2:	00007797          	auipc	a5,0x7
    80001bb6:	d5278793          	addi	a5,a5,-686 # 80008904 <nextpid>
    80001bba:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bbc:	0014871b          	addiw	a4,s1,1
    80001bc0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bc2:	854a                	mv	a0,s2
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	100080e7          	jalr	256(ra) # 80000cc4 <release>
}
    80001bcc:	8526                	mv	a0,s1
    80001bce:	60e2                	ld	ra,24(sp)
    80001bd0:	6442                	ld	s0,16(sp)
    80001bd2:	64a2                	ld	s1,8(sp)
    80001bd4:	6902                	ld	s2,0(sp)
    80001bd6:	6105                	addi	sp,sp,32
    80001bd8:	8082                	ret

0000000080001bda <proc_pagetable>:
{
    80001bda:	1101                	addi	sp,sp,-32
    80001bdc:	ec06                	sd	ra,24(sp)
    80001bde:	e822                	sd	s0,16(sp)
    80001be0:	e426                	sd	s1,8(sp)
    80001be2:	e04a                	sd	s2,0(sp)
    80001be4:	1000                	addi	s0,sp,32
    80001be6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001be8:	fffff097          	auipc	ra,0xfffff
    80001bec:	7c4080e7          	jalr	1988(ra) # 800013ac <uvmcreate>
    80001bf0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001bf2:	c121                	beqz	a0,80001c32 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bf4:	4729                	li	a4,10
    80001bf6:	00005697          	auipc	a3,0x5
    80001bfa:	40a68693          	addi	a3,a3,1034 # 80007000 <_trampoline>
    80001bfe:	6605                	lui	a2,0x1
    80001c00:	040005b7          	lui	a1,0x4000
    80001c04:	15fd                	addi	a1,a1,-1
    80001c06:	05b2                	slli	a1,a1,0xc
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	548080e7          	jalr	1352(ra) # 80001150 <mappages>
    80001c10:	02054863          	bltz	a0,80001c40 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c14:	4719                	li	a4,6
    80001c16:	05893683          	ld	a3,88(s2)
    80001c1a:	6605                	lui	a2,0x1
    80001c1c:	020005b7          	lui	a1,0x2000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b6                	slli	a1,a1,0xd
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	52a080e7          	jalr	1322(ra) # 80001150 <mappages>
    80001c2e:	02054163          	bltz	a0,80001c50 <proc_pagetable+0x76>
}
    80001c32:	8526                	mv	a0,s1
    80001c34:	60e2                	ld	ra,24(sp)
    80001c36:	6442                	ld	s0,16(sp)
    80001c38:	64a2                	ld	s1,8(sp)
    80001c3a:	6902                	ld	s2,0(sp)
    80001c3c:	6105                	addi	sp,sp,32
    80001c3e:	8082                	ret
    uvmfree(pagetable, 0);
    80001c40:	4581                	li	a1,0
    80001c42:	8526                	mv	a0,s1
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	964080e7          	jalr	-1692(ra) # 800015a8 <uvmfree>
    return 0;
    80001c4c:	4481                	li	s1,0
    80001c4e:	b7d5                	j	80001c32 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c50:	4681                	li	a3,0
    80001c52:	4605                	li	a2,1
    80001c54:	040005b7          	lui	a1,0x4000
    80001c58:	15fd                	addi	a1,a1,-1
    80001c5a:	05b2                	slli	a1,a1,0xc
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	68a080e7          	jalr	1674(ra) # 800012e8 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c66:	4581                	li	a1,0
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	93e080e7          	jalr	-1730(ra) # 800015a8 <uvmfree>
    return 0;
    80001c72:	4481                	li	s1,0
    80001c74:	bf7d                	j	80001c32 <proc_pagetable+0x58>

0000000080001c76 <proc_freepagetable>:
{
    80001c76:	1101                	addi	sp,sp,-32
    80001c78:	ec06                	sd	ra,24(sp)
    80001c7a:	e822                	sd	s0,16(sp)
    80001c7c:	e426                	sd	s1,8(sp)
    80001c7e:	e04a                	sd	s2,0(sp)
    80001c80:	1000                	addi	s0,sp,32
    80001c82:	84aa                	mv	s1,a0
    80001c84:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c86:	4681                	li	a3,0
    80001c88:	4605                	li	a2,1
    80001c8a:	040005b7          	lui	a1,0x4000
    80001c8e:	15fd                	addi	a1,a1,-1
    80001c90:	05b2                	slli	a1,a1,0xc
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	656080e7          	jalr	1622(ra) # 800012e8 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c9a:	4681                	li	a3,0
    80001c9c:	4605                	li	a2,1
    80001c9e:	020005b7          	lui	a1,0x2000
    80001ca2:	15fd                	addi	a1,a1,-1
    80001ca4:	05b6                	slli	a1,a1,0xd
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	640080e7          	jalr	1600(ra) # 800012e8 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cb0:	85ca                	mv	a1,s2
    80001cb2:	8526                	mv	a0,s1
    80001cb4:	00000097          	auipc	ra,0x0
    80001cb8:	8f4080e7          	jalr	-1804(ra) # 800015a8 <uvmfree>
}
    80001cbc:	60e2                	ld	ra,24(sp)
    80001cbe:	6442                	ld	s0,16(sp)
    80001cc0:	64a2                	ld	s1,8(sp)
    80001cc2:	6902                	ld	s2,0(sp)
    80001cc4:	6105                	addi	sp,sp,32
    80001cc6:	8082                	ret

0000000080001cc8 <growproc>:
{
    80001cc8:	7179                	addi	sp,sp,-48
    80001cca:	f406                	sd	ra,40(sp)
    80001ccc:	f022                	sd	s0,32(sp)
    80001cce:	ec26                	sd	s1,24(sp)
    80001cd0:	e84a                	sd	s2,16(sp)
    80001cd2:	e44e                	sd	s3,8(sp)
    80001cd4:	e052                	sd	s4,0(sp)
    80001cd6:	1800                	addi	s0,sp,48
    80001cd8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	e3c080e7          	jalr	-452(ra) # 80001b16 <myproc>
    80001ce2:	892a                	mv	s2,a0
  sz = p->sz;
    80001ce4:	652c                	ld	a1,72(a0)
    80001ce6:	0005899b          	sext.w	s3,a1
  if(n > 0){
    80001cea:	06905b63          	blez	s1,80001d60 <growproc+0x98>
    if (PGROUNDUP(sz + n) >= PLIC)
    80001cee:	00048a1b          	sext.w	s4,s1
    80001cf2:	013484bb          	addw	s1,s1,s3
    80001cf6:	6785                	lui	a5,0x1
    80001cf8:	37fd                	addiw	a5,a5,-1
    80001cfa:	9fa5                	addw	a5,a5,s1
    80001cfc:	777d                	lui	a4,0xfffff
    80001cfe:	8ff9                	and	a5,a5,a4
    80001d00:	2781                	sext.w	a5,a5
    80001d02:	0c000737          	lui	a4,0xc000
    80001d06:	06e7fd63          	bgeu	a5,a4,80001d80 <growproc+0xb8>
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d0a:	02049613          	slli	a2,s1,0x20
    80001d0e:	9201                	srli	a2,a2,0x20
    80001d10:	1582                	slli	a1,a1,0x20
    80001d12:	9181                	srli	a1,a1,0x20
    80001d14:	6928                	ld	a0,80(a0)
    80001d16:	fffff097          	auipc	ra,0xfffff
    80001d1a:	77e080e7          	jalr	1918(ra) # 80001494 <uvmalloc>
    80001d1e:	0005099b          	sext.w	s3,a0
    80001d22:	06098163          	beqz	s3,80001d84 <growproc+0xbc>
    procuser2kernel(p->pagetable,p->prockernelpagetable,sz-n,sz);
    80001d26:	4149863b          	subw	a2,s3,s4
    80001d2a:	02051693          	slli	a3,a0,0x20
    80001d2e:	9281                	srli	a3,a3,0x20
    80001d30:	1602                	slli	a2,a2,0x20
    80001d32:	9201                	srli	a2,a2,0x20
    80001d34:	16893583          	ld	a1,360(s2)
    80001d38:	05093503          	ld	a0,80(s2)
    80001d3c:	00000097          	auipc	ra,0x0
    80001d40:	c68080e7          	jalr	-920(ra) # 800019a4 <procuser2kernel>
  p->sz = sz;
    80001d44:	02099613          	slli	a2,s3,0x20
    80001d48:	9201                	srli	a2,a2,0x20
    80001d4a:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d4e:	4501                	li	a0,0
}
    80001d50:	70a2                	ld	ra,40(sp)
    80001d52:	7402                	ld	s0,32(sp)
    80001d54:	64e2                	ld	s1,24(sp)
    80001d56:	6942                	ld	s2,16(sp)
    80001d58:	69a2                	ld	s3,8(sp)
    80001d5a:	6a02                	ld	s4,0(sp)
    80001d5c:	6145                	addi	sp,sp,48
    80001d5e:	8082                	ret
  } else if(n < 0){
    80001d60:	fe04d2e3          	bgez	s1,80001d44 <growproc+0x7c>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d64:	0134863b          	addw	a2,s1,s3
    80001d68:	1602                	slli	a2,a2,0x20
    80001d6a:	9201                	srli	a2,a2,0x20
    80001d6c:	1582                	slli	a1,a1,0x20
    80001d6e:	9181                	srli	a1,a1,0x20
    80001d70:	6928                	ld	a0,80(a0)
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	6da080e7          	jalr	1754(ra) # 8000144c <uvmdealloc>
    80001d7a:	0005099b          	sext.w	s3,a0
    80001d7e:	b7d9                	j	80001d44 <growproc+0x7c>
      return -1;
    80001d80:	557d                	li	a0,-1
    80001d82:	b7f9                	j	80001d50 <growproc+0x88>
      return -1;
    80001d84:	557d                	li	a0,-1
    80001d86:	b7e9                	j	80001d50 <growproc+0x88>

0000000080001d88 <reparent>:
{
    80001d88:	7179                	addi	sp,sp,-48
    80001d8a:	f406                	sd	ra,40(sp)
    80001d8c:	f022                	sd	s0,32(sp)
    80001d8e:	ec26                	sd	s1,24(sp)
    80001d90:	e84a                	sd	s2,16(sp)
    80001d92:	e44e                	sd	s3,8(sp)
    80001d94:	e052                	sd	s4,0(sp)
    80001d96:	1800                	addi	s0,sp,48
    80001d98:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001d9a:	00010497          	auipc	s1,0x10
    80001d9e:	fce48493          	addi	s1,s1,-50 # 80011d68 <proc>
      pp->parent = initproc;
    80001da2:	00007a17          	auipc	s4,0x7
    80001da6:	276a0a13          	addi	s4,s4,630 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001daa:	00016997          	auipc	s3,0x16
    80001dae:	bbe98993          	addi	s3,s3,-1090 # 80017968 <tickslock>
    80001db2:	a029                	j	80001dbc <reparent+0x34>
    80001db4:	17048493          	addi	s1,s1,368
    80001db8:	03348363          	beq	s1,s3,80001dde <reparent+0x56>
    if(pp->parent == p){
    80001dbc:	709c                	ld	a5,32(s1)
    80001dbe:	ff279be3          	bne	a5,s2,80001db4 <reparent+0x2c>
      acquire(&pp->lock);
    80001dc2:	8526                	mv	a0,s1
    80001dc4:	fffff097          	auipc	ra,0xfffff
    80001dc8:	e4c080e7          	jalr	-436(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80001dcc:	000a3783          	ld	a5,0(s4)
    80001dd0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	ef0080e7          	jalr	-272(ra) # 80000cc4 <release>
    80001ddc:	bfe1                	j	80001db4 <reparent+0x2c>
}
    80001dde:	70a2                	ld	ra,40(sp)
    80001de0:	7402                	ld	s0,32(sp)
    80001de2:	64e2                	ld	s1,24(sp)
    80001de4:	6942                	ld	s2,16(sp)
    80001de6:	69a2                	ld	s3,8(sp)
    80001de8:	6a02                	ld	s4,0(sp)
    80001dea:	6145                	addi	sp,sp,48
    80001dec:	8082                	ret

0000000080001dee <scheduler>:
{
    80001dee:	715d                	addi	sp,sp,-80
    80001df0:	e486                	sd	ra,72(sp)
    80001df2:	e0a2                	sd	s0,64(sp)
    80001df4:	fc26                	sd	s1,56(sp)
    80001df6:	f84a                	sd	s2,48(sp)
    80001df8:	f44e                	sd	s3,40(sp)
    80001dfa:	f052                	sd	s4,32(sp)
    80001dfc:	ec56                	sd	s5,24(sp)
    80001dfe:	e85a                	sd	s6,16(sp)
    80001e00:	e45e                	sd	s7,8(sp)
    80001e02:	e062                	sd	s8,0(sp)
    80001e04:	0880                	addi	s0,sp,80
    80001e06:	8792                	mv	a5,tp
  int id = r_tp();
    80001e08:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001e0a:	00779b13          	slli	s6,a5,0x7
    80001e0e:	00010717          	auipc	a4,0x10
    80001e12:	b4270713          	addi	a4,a4,-1214 # 80011950 <pid_lock>
    80001e16:	975a                	add	a4,a4,s6
    80001e18:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001e1c:	00010717          	auipc	a4,0x10
    80001e20:	b5470713          	addi	a4,a4,-1196 # 80011970 <cpus+0x8>
    80001e24:	9b3a                	add	s6,s6,a4
        c->proc = p;
    80001e26:	079e                	slli	a5,a5,0x7
    80001e28:	00010a17          	auipc	s4,0x10
    80001e2c:	b28a0a13          	addi	s4,s4,-1240 # 80011950 <pid_lock>
    80001e30:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->prockernelpagetable));
    80001e32:	5bfd                	li	s7,-1
    80001e34:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e36:	00016997          	auipc	s3,0x16
    80001e3a:	b3298993          	addi	s3,s3,-1230 # 80017968 <tickslock>
    80001e3e:	a8a1                	j	80001e96 <scheduler+0xa8>
        p->state = RUNNING;
    80001e40:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    80001e44:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->prockernelpagetable));
    80001e48:	1684b783          	ld	a5,360(s1)
    80001e4c:	83b1                	srli	a5,a5,0xc
    80001e4e:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    80001e52:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001e56:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    80001e5a:	06048593          	addi	a1,s1,96
    80001e5e:	855a                	mv	a0,s6
    80001e60:	00001097          	auipc	ra,0x1
    80001e64:	a3e080e7          	jalr	-1474(ra) # 8000289e <swtch>
        c->proc = 0;
    80001e68:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001e6c:	4c05                	li	s8,1
      release(&p->lock);
    80001e6e:	8526                	mv	a0,s1
    80001e70:	fffff097          	auipc	ra,0xfffff
    80001e74:	e54080e7          	jalr	-428(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001e78:	17048493          	addi	s1,s1,368
    80001e7c:	01348b63          	beq	s1,s3,80001e92 <scheduler+0xa4>
      acquire(&p->lock);
    80001e80:	8526                	mv	a0,s1
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	d8e080e7          	jalr	-626(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    80001e8a:	4c9c                	lw	a5,24(s1)
    80001e8c:	ff2791e3          	bne	a5,s2,80001e6e <scheduler+0x80>
    80001e90:	bf45                	j	80001e40 <scheduler+0x52>
    if(found == 0) {
    80001e92:	020c0063          	beqz	s8,80001eb2 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001e9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001e9e:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001ea2:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ea4:	00010497          	auipc	s1,0x10
    80001ea8:	ec448493          	addi	s1,s1,-316 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001eac:	4909                	li	s2,2
        p->state = RUNNING;
    80001eae:	4a8d                	li	s5,3
    80001eb0:	bfc1                	j	80001e80 <scheduler+0x92>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eb2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001eb6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001eba:	10079073          	csrw	sstatus,a5
      kvminithart();
    80001ebe:	fffff097          	auipc	ra,0xfffff
    80001ec2:	11e080e7          	jalr	286(ra) # 80000fdc <kvminithart>
      asm volatile("wfi");
    80001ec6:	10500073          	wfi
    80001eca:	b7f1                	j	80001e96 <scheduler+0xa8>

0000000080001ecc <sched>:
{
    80001ecc:	7179                	addi	sp,sp,-48
    80001ece:	f406                	sd	ra,40(sp)
    80001ed0:	f022                	sd	s0,32(sp)
    80001ed2:	ec26                	sd	s1,24(sp)
    80001ed4:	e84a                	sd	s2,16(sp)
    80001ed6:	e44e                	sd	s3,8(sp)
    80001ed8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	c3c080e7          	jalr	-964(ra) # 80001b16 <myproc>
    80001ee2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	cb2080e7          	jalr	-846(ra) # 80000b96 <holding>
    80001eec:	c93d                	beqz	a0,80001f62 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001eee:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ef0:	2781                	sext.w	a5,a5
    80001ef2:	079e                	slli	a5,a5,0x7
    80001ef4:	00010717          	auipc	a4,0x10
    80001ef8:	a5c70713          	addi	a4,a4,-1444 # 80011950 <pid_lock>
    80001efc:	97ba                	add	a5,a5,a4
    80001efe:	0907a703          	lw	a4,144(a5) # 1090 <_entry-0x7fffef70>
    80001f02:	4785                	li	a5,1
    80001f04:	06f71763          	bne	a4,a5,80001f72 <sched+0xa6>
  if(p->state == RUNNING)
    80001f08:	4c98                	lw	a4,24(s1)
    80001f0a:	478d                	li	a5,3
    80001f0c:	06f70b63          	beq	a4,a5,80001f82 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f14:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f16:	efb5                	bnez	a5,80001f92 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f18:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f1a:	00010917          	auipc	s2,0x10
    80001f1e:	a3690913          	addi	s2,s2,-1482 # 80011950 <pid_lock>
    80001f22:	2781                	sext.w	a5,a5
    80001f24:	079e                	slli	a5,a5,0x7
    80001f26:	97ca                	add	a5,a5,s2
    80001f28:	0947a983          	lw	s3,148(a5)
    80001f2c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001f2e:	2781                	sext.w	a5,a5
    80001f30:	079e                	slli	a5,a5,0x7
    80001f32:	00010597          	auipc	a1,0x10
    80001f36:	a3e58593          	addi	a1,a1,-1474 # 80011970 <cpus+0x8>
    80001f3a:	95be                	add	a1,a1,a5
    80001f3c:	06048513          	addi	a0,s1,96
    80001f40:	00001097          	auipc	ra,0x1
    80001f44:	95e080e7          	jalr	-1698(ra) # 8000289e <swtch>
    80001f48:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001f4a:	2781                	sext.w	a5,a5
    80001f4c:	079e                	slli	a5,a5,0x7
    80001f4e:	97ca                	add	a5,a5,s2
    80001f50:	0937aa23          	sw	s3,148(a5)
}
    80001f54:	70a2                	ld	ra,40(sp)
    80001f56:	7402                	ld	s0,32(sp)
    80001f58:	64e2                	ld	s1,24(sp)
    80001f5a:	6942                	ld	s2,16(sp)
    80001f5c:	69a2                	ld	s3,8(sp)
    80001f5e:	6145                	addi	sp,sp,48
    80001f60:	8082                	ret
    panic("sched p->lock");
    80001f62:	00006517          	auipc	a0,0x6
    80001f66:	31650513          	addi	a0,a0,790 # 80008278 <digits+0x238>
    80001f6a:	ffffe097          	auipc	ra,0xffffe
    80001f6e:	5de080e7          	jalr	1502(ra) # 80000548 <panic>
    panic("sched locks");
    80001f72:	00006517          	auipc	a0,0x6
    80001f76:	31650513          	addi	a0,a0,790 # 80008288 <digits+0x248>
    80001f7a:	ffffe097          	auipc	ra,0xffffe
    80001f7e:	5ce080e7          	jalr	1486(ra) # 80000548 <panic>
    panic("sched running");
    80001f82:	00006517          	auipc	a0,0x6
    80001f86:	31650513          	addi	a0,a0,790 # 80008298 <digits+0x258>
    80001f8a:	ffffe097          	auipc	ra,0xffffe
    80001f8e:	5be080e7          	jalr	1470(ra) # 80000548 <panic>
    panic("sched interruptible");
    80001f92:	00006517          	auipc	a0,0x6
    80001f96:	31650513          	addi	a0,a0,790 # 800082a8 <digits+0x268>
    80001f9a:	ffffe097          	auipc	ra,0xffffe
    80001f9e:	5ae080e7          	jalr	1454(ra) # 80000548 <panic>

0000000080001fa2 <exit>:
{
    80001fa2:	7179                	addi	sp,sp,-48
    80001fa4:	f406                	sd	ra,40(sp)
    80001fa6:	f022                	sd	s0,32(sp)
    80001fa8:	ec26                	sd	s1,24(sp)
    80001faa:	e84a                	sd	s2,16(sp)
    80001fac:	e44e                	sd	s3,8(sp)
    80001fae:	e052                	sd	s4,0(sp)
    80001fb0:	1800                	addi	s0,sp,48
    80001fb2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	b62080e7          	jalr	-1182(ra) # 80001b16 <myproc>
    80001fbc:	89aa                	mv	s3,a0
  if(p == initproc)
    80001fbe:	00007797          	auipc	a5,0x7
    80001fc2:	05a7b783          	ld	a5,90(a5) # 80009018 <initproc>
    80001fc6:	0d050493          	addi	s1,a0,208
    80001fca:	15050913          	addi	s2,a0,336
    80001fce:	02a79363          	bne	a5,a0,80001ff4 <exit+0x52>
    panic("init exiting");
    80001fd2:	00006517          	auipc	a0,0x6
    80001fd6:	2ee50513          	addi	a0,a0,750 # 800082c0 <digits+0x280>
    80001fda:	ffffe097          	auipc	ra,0xffffe
    80001fde:	56e080e7          	jalr	1390(ra) # 80000548 <panic>
      fileclose(f);
    80001fe2:	00002097          	auipc	ra,0x2
    80001fe6:	7ae080e7          	jalr	1966(ra) # 80004790 <fileclose>
      p->ofile[fd] = 0;
    80001fea:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80001fee:	04a1                	addi	s1,s1,8
    80001ff0:	01248563          	beq	s1,s2,80001ffa <exit+0x58>
    if(p->ofile[fd]){
    80001ff4:	6088                	ld	a0,0(s1)
    80001ff6:	f575                	bnez	a0,80001fe2 <exit+0x40>
    80001ff8:	bfdd                	j	80001fee <exit+0x4c>
  begin_op();
    80001ffa:	00002097          	auipc	ra,0x2
    80001ffe:	2c4080e7          	jalr	708(ra) # 800042be <begin_op>
  iput(p->cwd);
    80002002:	1509b503          	ld	a0,336(s3)
    80002006:	00002097          	auipc	ra,0x2
    8000200a:	ab6080e7          	jalr	-1354(ra) # 80003abc <iput>
  end_op();
    8000200e:	00002097          	auipc	ra,0x2
    80002012:	330080e7          	jalr	816(ra) # 8000433e <end_op>
  p->cwd = 0;
    80002016:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000201a:	00007497          	auipc	s1,0x7
    8000201e:	ffe48493          	addi	s1,s1,-2 # 80009018 <initproc>
    80002022:	6088                	ld	a0,0(s1)
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	bec080e7          	jalr	-1044(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000202c:	6088                	ld	a0,0(s1)
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	a18080e7          	jalr	-1512(ra) # 80001a46 <wakeup1>
  release(&initproc->lock);
    80002036:	6088                	ld	a0,0(s1)
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	c8c080e7          	jalr	-884(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002040:	854e                	mv	a0,s3
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	bce080e7          	jalr	-1074(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000204a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000204e:	854e                	mv	a0,s3
    80002050:	fffff097          	auipc	ra,0xfffff
    80002054:	c74080e7          	jalr	-908(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002058:	8526                	mv	a0,s1
    8000205a:	fffff097          	auipc	ra,0xfffff
    8000205e:	bb6080e7          	jalr	-1098(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002062:	854e                	mv	a0,s3
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	bac080e7          	jalr	-1108(ra) # 80000c10 <acquire>
  reparent(p);
    8000206c:	854e                	mv	a0,s3
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	d1a080e7          	jalr	-742(ra) # 80001d88 <reparent>
  wakeup1(original_parent);
    80002076:	8526                	mv	a0,s1
    80002078:	00000097          	auipc	ra,0x0
    8000207c:	9ce080e7          	jalr	-1586(ra) # 80001a46 <wakeup1>
  p->xstate = status;
    80002080:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002084:	4791                	li	a5,4
    80002086:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	c38080e7          	jalr	-968(ra) # 80000cc4 <release>
  sched();
    80002094:	00000097          	auipc	ra,0x0
    80002098:	e38080e7          	jalr	-456(ra) # 80001ecc <sched>
  panic("zombie exit");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	23450513          	addi	a0,a0,564 # 800082d0 <digits+0x290>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4a4080e7          	jalr	1188(ra) # 80000548 <panic>

00000000800020ac <yield>:
{
    800020ac:	1101                	addi	sp,sp,-32
    800020ae:	ec06                	sd	ra,24(sp)
    800020b0:	e822                	sd	s0,16(sp)
    800020b2:	e426                	sd	s1,8(sp)
    800020b4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020b6:	00000097          	auipc	ra,0x0
    800020ba:	a60080e7          	jalr	-1440(ra) # 80001b16 <myproc>
    800020be:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	b50080e7          	jalr	-1200(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    800020c8:	4789                	li	a5,2
    800020ca:	cc9c                	sw	a5,24(s1)
  sched();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	e00080e7          	jalr	-512(ra) # 80001ecc <sched>
  release(&p->lock);
    800020d4:	8526                	mv	a0,s1
    800020d6:	fffff097          	auipc	ra,0xfffff
    800020da:	bee080e7          	jalr	-1042(ra) # 80000cc4 <release>
}
    800020de:	60e2                	ld	ra,24(sp)
    800020e0:	6442                	ld	s0,16(sp)
    800020e2:	64a2                	ld	s1,8(sp)
    800020e4:	6105                	addi	sp,sp,32
    800020e6:	8082                	ret

00000000800020e8 <sleep>:
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	1800                	addi	s0,sp,48
    800020f6:	89aa                	mv	s3,a0
    800020f8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	a1c080e7          	jalr	-1508(ra) # 80001b16 <myproc>
    80002102:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002104:	05250663          	beq	a0,s2,80002150 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	b08080e7          	jalr	-1272(ra) # 80000c10 <acquire>
    release(lk);
    80002110:	854a                	mv	a0,s2
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	bb2080e7          	jalr	-1102(ra) # 80000cc4 <release>
  p->chan = chan;
    8000211a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000211e:	4785                	li	a5,1
    80002120:	cc9c                	sw	a5,24(s1)
  sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	daa080e7          	jalr	-598(ra) # 80001ecc <sched>
  p->chan = 0;
    8000212a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b94080e7          	jalr	-1132(ra) # 80000cc4 <release>
    acquire(lk);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	ad6080e7          	jalr	-1322(ra) # 80000c10 <acquire>
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret
  p->chan = chan;
    80002150:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002154:	4785                	li	a5,1
    80002156:	cd1c                	sw	a5,24(a0)
  sched();
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	d74080e7          	jalr	-652(ra) # 80001ecc <sched>
  p->chan = 0;
    80002160:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002164:	bff9                	j	80002142 <sleep+0x5a>

0000000080002166 <wakeup>:
{
    80002166:	7139                	addi	sp,sp,-64
    80002168:	fc06                	sd	ra,56(sp)
    8000216a:	f822                	sd	s0,48(sp)
    8000216c:	f426                	sd	s1,40(sp)
    8000216e:	f04a                	sd	s2,32(sp)
    80002170:	ec4e                	sd	s3,24(sp)
    80002172:	e852                	sd	s4,16(sp)
    80002174:	e456                	sd	s5,8(sp)
    80002176:	0080                	addi	s0,sp,64
    80002178:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000217a:	00010497          	auipc	s1,0x10
    8000217e:	bee48493          	addi	s1,s1,-1042 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002182:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002184:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002186:	00015917          	auipc	s2,0x15
    8000218a:	7e290913          	addi	s2,s2,2018 # 80017968 <tickslock>
    8000218e:	a821                	j	800021a6 <wakeup+0x40>
      p->state = RUNNABLE;
    80002190:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002194:	8526                	mv	a0,s1
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b2e080e7          	jalr	-1234(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000219e:	17048493          	addi	s1,s1,368
    800021a2:	01248e63          	beq	s1,s2,800021be <wakeup+0x58>
    acquire(&p->lock);
    800021a6:	8526                	mv	a0,s1
    800021a8:	fffff097          	auipc	ra,0xfffff
    800021ac:	a68080e7          	jalr	-1432(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800021b0:	4c9c                	lw	a5,24(s1)
    800021b2:	ff3791e3          	bne	a5,s3,80002194 <wakeup+0x2e>
    800021b6:	749c                	ld	a5,40(s1)
    800021b8:	fd479ee3          	bne	a5,s4,80002194 <wakeup+0x2e>
    800021bc:	bfd1                	j	80002190 <wakeup+0x2a>
}
    800021be:	70e2                	ld	ra,56(sp)
    800021c0:	7442                	ld	s0,48(sp)
    800021c2:	74a2                	ld	s1,40(sp)
    800021c4:	7902                	ld	s2,32(sp)
    800021c6:	69e2                	ld	s3,24(sp)
    800021c8:	6a42                	ld	s4,16(sp)
    800021ca:	6aa2                	ld	s5,8(sp)
    800021cc:	6121                	addi	sp,sp,64
    800021ce:	8082                	ret

00000000800021d0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
    800021de:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800021e0:	00010497          	auipc	s1,0x10
    800021e4:	b8848493          	addi	s1,s1,-1144 # 80011d68 <proc>
    800021e8:	00015997          	auipc	s3,0x15
    800021ec:	78098993          	addi	s3,s3,1920 # 80017968 <tickslock>
    acquire(&p->lock);
    800021f0:	8526                	mv	a0,s1
    800021f2:	fffff097          	auipc	ra,0xfffff
    800021f6:	a1e080e7          	jalr	-1506(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800021fa:	5c9c                	lw	a5,56(s1)
    800021fc:	01278d63          	beq	a5,s2,80002216 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	ac2080e7          	jalr	-1342(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000220a:	17048493          	addi	s1,s1,368
    8000220e:	ff3491e3          	bne	s1,s3,800021f0 <kill+0x20>
  }
  return -1;
    80002212:	557d                	li	a0,-1
    80002214:	a829                	j	8000222e <kill+0x5e>
      p->killed = 1;
    80002216:	4785                	li	a5,1
    80002218:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    8000221a:	4c98                	lw	a4,24(s1)
    8000221c:	4785                	li	a5,1
    8000221e:	00f70f63          	beq	a4,a5,8000223c <kill+0x6c>
      release(&p->lock);
    80002222:	8526                	mv	a0,s1
    80002224:	fffff097          	auipc	ra,0xfffff
    80002228:	aa0080e7          	jalr	-1376(ra) # 80000cc4 <release>
      return 0;
    8000222c:	4501                	li	a0,0
}
    8000222e:	70a2                	ld	ra,40(sp)
    80002230:	7402                	ld	s0,32(sp)
    80002232:	64e2                	ld	s1,24(sp)
    80002234:	6942                	ld	s2,16(sp)
    80002236:	69a2                	ld	s3,8(sp)
    80002238:	6145                	addi	sp,sp,48
    8000223a:	8082                	ret
        p->state = RUNNABLE;
    8000223c:	4789                	li	a5,2
    8000223e:	cc9c                	sw	a5,24(s1)
    80002240:	b7cd                	j	80002222 <kill+0x52>

0000000080002242 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002242:	7179                	addi	sp,sp,-48
    80002244:	f406                	sd	ra,40(sp)
    80002246:	f022                	sd	s0,32(sp)
    80002248:	ec26                	sd	s1,24(sp)
    8000224a:	e84a                	sd	s2,16(sp)
    8000224c:	e44e                	sd	s3,8(sp)
    8000224e:	e052                	sd	s4,0(sp)
    80002250:	1800                	addi	s0,sp,48
    80002252:	84aa                	mv	s1,a0
    80002254:	892e                	mv	s2,a1
    80002256:	89b2                	mv	s3,a2
    80002258:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	8bc080e7          	jalr	-1860(ra) # 80001b16 <myproc>
  if(user_dst){
    80002262:	c08d                	beqz	s1,80002284 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002264:	86d2                	mv	a3,s4
    80002266:	864e                	mv	a2,s3
    80002268:	85ca                	mv	a1,s2
    8000226a:	6928                	ld	a0,80(a0)
    8000226c:	fffff097          	auipc	ra,0xfffff
    80002270:	478080e7          	jalr	1144(ra) # 800016e4 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002274:	70a2                	ld	ra,40(sp)
    80002276:	7402                	ld	s0,32(sp)
    80002278:	64e2                	ld	s1,24(sp)
    8000227a:	6942                	ld	s2,16(sp)
    8000227c:	69a2                	ld	s3,8(sp)
    8000227e:	6a02                	ld	s4,0(sp)
    80002280:	6145                	addi	sp,sp,48
    80002282:	8082                	ret
    memmove((char *)dst, src, len);
    80002284:	000a061b          	sext.w	a2,s4
    80002288:	85ce                	mv	a1,s3
    8000228a:	854a                	mv	a0,s2
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	ae0080e7          	jalr	-1312(ra) # 80000d6c <memmove>
    return 0;
    80002294:	8526                	mv	a0,s1
    80002296:	bff9                	j	80002274 <either_copyout+0x32>

0000000080002298 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	e052                	sd	s4,0(sp)
    800022a6:	1800                	addi	s0,sp,48
    800022a8:	892a                	mv	s2,a0
    800022aa:	84ae                	mv	s1,a1
    800022ac:	89b2                	mv	s3,a2
    800022ae:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	866080e7          	jalr	-1946(ra) # 80001b16 <myproc>
  if(user_src){
    800022b8:	c08d                	beqz	s1,800022da <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800022ba:	86d2                	mv	a3,s4
    800022bc:	864e                	mv	a2,s3
    800022be:	85ca                	mv	a1,s2
    800022c0:	6928                	ld	a0,80(a0)
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	4ae080e7          	jalr	1198(ra) # 80001770 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800022ca:	70a2                	ld	ra,40(sp)
    800022cc:	7402                	ld	s0,32(sp)
    800022ce:	64e2                	ld	s1,24(sp)
    800022d0:	6942                	ld	s2,16(sp)
    800022d2:	69a2                	ld	s3,8(sp)
    800022d4:	6a02                	ld	s4,0(sp)
    800022d6:	6145                	addi	sp,sp,48
    800022d8:	8082                	ret
    memmove(dst, (char*)src, len);
    800022da:	000a061b          	sext.w	a2,s4
    800022de:	85ce                	mv	a1,s3
    800022e0:	854a                	mv	a0,s2
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	a8a080e7          	jalr	-1398(ra) # 80000d6c <memmove>
    return 0;
    800022ea:	8526                	mv	a0,s1
    800022ec:	bff9                	j	800022ca <either_copyin+0x32>

00000000800022ee <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022ee:	715d                	addi	sp,sp,-80
    800022f0:	e486                	sd	ra,72(sp)
    800022f2:	e0a2                	sd	s0,64(sp)
    800022f4:	fc26                	sd	s1,56(sp)
    800022f6:	f84a                	sd	s2,48(sp)
    800022f8:	f44e                	sd	s3,40(sp)
    800022fa:	f052                	sd	s4,32(sp)
    800022fc:	ec56                	sd	s5,24(sp)
    800022fe:	e85a                	sd	s6,16(sp)
    80002300:	e45e                	sd	s7,8(sp)
    80002302:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	dc450513          	addi	a0,a0,-572 # 800080c8 <digits+0x88>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	286080e7          	jalr	646(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002314:	00010497          	auipc	s1,0x10
    80002318:	bac48493          	addi	s1,s1,-1108 # 80011ec0 <proc+0x158>
    8000231c:	00015917          	auipc	s2,0x15
    80002320:	7a490913          	addi	s2,s2,1956 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002324:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002326:	00006997          	auipc	s3,0x6
    8000232a:	fba98993          	addi	s3,s3,-70 # 800082e0 <digits+0x2a0>
    printf("%d %s %s", p->pid, state, p->name);
    8000232e:	00006a97          	auipc	s5,0x6
    80002332:	fbaa8a93          	addi	s5,s5,-70 # 800082e8 <digits+0x2a8>
    printf("\n");
    80002336:	00006a17          	auipc	s4,0x6
    8000233a:	d92a0a13          	addi	s4,s4,-622 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000233e:	00006b97          	auipc	s7,0x6
    80002342:	01ab8b93          	addi	s7,s7,26 # 80008358 <states.1756>
    80002346:	a00d                	j	80002368 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002348:	ee06a583          	lw	a1,-288(a3)
    8000234c:	8556                	mv	a0,s5
    8000234e:	ffffe097          	auipc	ra,0xffffe
    80002352:	244080e7          	jalr	580(ra) # 80000592 <printf>
    printf("\n");
    80002356:	8552                	mv	a0,s4
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	23a080e7          	jalr	570(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002360:	17048493          	addi	s1,s1,368
    80002364:	03248163          	beq	s1,s2,80002386 <procdump+0x98>
    if(p->state == UNUSED)
    80002368:	86a6                	mv	a3,s1
    8000236a:	ec04a783          	lw	a5,-320(s1)
    8000236e:	dbed                	beqz	a5,80002360 <procdump+0x72>
      state = "???";
    80002370:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002372:	fcfb6be3          	bltu	s6,a5,80002348 <procdump+0x5a>
    80002376:	1782                	slli	a5,a5,0x20
    80002378:	9381                	srli	a5,a5,0x20
    8000237a:	078e                	slli	a5,a5,0x3
    8000237c:	97de                	add	a5,a5,s7
    8000237e:	6390                	ld	a2,0(a5)
    80002380:	f661                	bnez	a2,80002348 <procdump+0x5a>
      state = "???";
    80002382:	864e                	mv	a2,s3
    80002384:	b7d1                	j	80002348 <procdump+0x5a>
  }
}
    80002386:	60a6                	ld	ra,72(sp)
    80002388:	6406                	ld	s0,64(sp)
    8000238a:	74e2                	ld	s1,56(sp)
    8000238c:	7942                	ld	s2,48(sp)
    8000238e:	79a2                	ld	s3,40(sp)
    80002390:	7a02                	ld	s4,32(sp)
    80002392:	6ae2                	ld	s5,24(sp)
    80002394:	6b42                	ld	s6,16(sp)
    80002396:	6ba2                	ld	s7,8(sp)
    80002398:	6161                	addi	sp,sp,80
    8000239a:	8082                	ret

000000008000239c <proc_freeprockernelpagetable>:


void proc_freeprockernelpagetable(pagetable_t pagetable){
    8000239c:	7179                	addi	sp,sp,-48
    8000239e:	f406                	sd	ra,40(sp)
    800023a0:	f022                	sd	s0,32(sp)
    800023a2:	ec26                	sd	s1,24(sp)
    800023a4:	e84a                	sd	s2,16(sp)
    800023a6:	e44e                	sd	s3,8(sp)
    800023a8:	1800                	addi	s0,sp,48
    800023aa:	89aa                	mv	s3,a0
  for(int i = 0; i < 512; i++){
    800023ac:	84aa                	mv	s1,a0
    800023ae:	6905                	lui	s2,0x1
    800023b0:	992a                	add	s2,s2,a0
    800023b2:	a811                	j	800023c6 <proc_freeprockernelpagetable+0x2a>
    pte_t pte = pagetable[i];
    if((pte & PTE_V)){
      pagetable[i] = 0;
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0)
      {
        uint64 child = PTE2PA(pte);
    800023b4:	8129                	srli	a0,a0,0xa
        proc_freeprockernelpagetable((pagetable_t)child);
    800023b6:	0532                	slli	a0,a0,0xc
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	fe4080e7          	jalr	-28(ra) # 8000239c <proc_freeprockernelpagetable>
  for(int i = 0; i < 512; i++){
    800023c0:	04a1                	addi	s1,s1,8
    800023c2:	01248c63          	beq	s1,s2,800023da <proc_freeprockernelpagetable+0x3e>
    pte_t pte = pagetable[i];
    800023c6:	6088                	ld	a0,0(s1)
    if((pte & PTE_V)){
    800023c8:	00157793          	andi	a5,a0,1
    800023cc:	dbf5                	beqz	a5,800023c0 <proc_freeprockernelpagetable+0x24>
      pagetable[i] = 0;
    800023ce:	0004b023          	sd	zero,0(s1)
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0)
    800023d2:	00e57793          	andi	a5,a0,14
    800023d6:	f7ed                	bnez	a5,800023c0 <proc_freeprockernelpagetable+0x24>
    800023d8:	bff1                	j	800023b4 <proc_freeprockernelpagetable+0x18>
      }
    } else if(pte & PTE_V){
      panic("proc free kpt: leaf");
    }
  }
  kfree((void*)pagetable);
    800023da:	854e                	mv	a0,s3
    800023dc:	ffffe097          	auipc	ra,0xffffe
    800023e0:	648080e7          	jalr	1608(ra) # 80000a24 <kfree>


    800023e4:	70a2                	ld	ra,40(sp)
    800023e6:	7402                	ld	s0,32(sp)
    800023e8:	64e2                	ld	s1,24(sp)
    800023ea:	6942                	ld	s2,16(sp)
    800023ec:	69a2                	ld	s3,8(sp)
    800023ee:	6145                	addi	sp,sp,48
    800023f0:	8082                	ret

00000000800023f2 <freeproc>:
{
    800023f2:	1101                	addi	sp,sp,-32
    800023f4:	ec06                	sd	ra,24(sp)
    800023f6:	e822                	sd	s0,16(sp)
    800023f8:	e426                	sd	s1,8(sp)
    800023fa:	1000                	addi	s0,sp,32
    800023fc:	84aa                	mv	s1,a0
  if(p->trapframe)
    800023fe:	6d28                	ld	a0,88(a0)
    80002400:	c509                	beqz	a0,8000240a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	622080e7          	jalr	1570(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    8000240a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    8000240e:	68a8                	ld	a0,80(s1)
    80002410:	c511                	beqz	a0,8000241c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80002412:	64ac                	ld	a1,72(s1)
    80002414:	00000097          	auipc	ra,0x0
    80002418:	862080e7          	jalr	-1950(ra) # 80001c76 <proc_freepagetable>
  if (p->kstack)
    8000241c:	60ac                	ld	a1,64(s1)
    8000241e:	e1b9                	bnez	a1,80002464 <freeproc+0x72>
  p->kstack = 0;
    80002420:	0404b023          	sd	zero,64(s1)
  if (p->prockernelpagetable)
    80002424:	1684b503          	ld	a0,360(s1)
    80002428:	c509                	beqz	a0,80002432 <freeproc+0x40>
    proc_freeprockernelpagetable(p->prockernelpagetable);
    8000242a:	00000097          	auipc	ra,0x0
    8000242e:	f72080e7          	jalr	-142(ra) # 8000239c <proc_freeprockernelpagetable>
  p->prockernelpagetable=0;
    80002432:	1604b423          	sd	zero,360(s1)
  p->pagetable = 0;
    80002436:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    8000243a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    8000243e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80002442:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80002446:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    8000244a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    8000244e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80002452:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80002456:	0004ac23          	sw	zero,24(s1)
}
    8000245a:	60e2                	ld	ra,24(sp)
    8000245c:	6442                	ld	s0,16(sp)
    8000245e:	64a2                	ld	s1,8(sp)
    80002460:	6105                	addi	sp,sp,32
    80002462:	8082                	ret
    pte_t* pte = walk(p->prockernelpagetable, p->kstack, 0);
    80002464:	4601                	li	a2,0
    80002466:	1684b503          	ld	a0,360(s1)
    8000246a:	fffff097          	auipc	ra,0xfffff
    8000246e:	b96080e7          	jalr	-1130(ra) # 80001000 <walk>
    if (pte == 0)
    80002472:	c909                	beqz	a0,80002484 <freeproc+0x92>
    kfree((void*)PTE2PA(*pte));
    80002474:	6108                	ld	a0,0(a0)
    80002476:	8129                	srli	a0,a0,0xa
    80002478:	0532                	slli	a0,a0,0xc
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	5aa080e7          	jalr	1450(ra) # 80000a24 <kfree>
    80002482:	bf79                	j	80002420 <freeproc+0x2e>
      panic("freeproc: kstack");
    80002484:	00006517          	auipc	a0,0x6
    80002488:	e7450513          	addi	a0,a0,-396 # 800082f8 <digits+0x2b8>
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	0bc080e7          	jalr	188(ra) # 80000548 <panic>

0000000080002494 <allocproc>:
{
    80002494:	1101                	addi	sp,sp,-32
    80002496:	ec06                	sd	ra,24(sp)
    80002498:	e822                	sd	s0,16(sp)
    8000249a:	e426                	sd	s1,8(sp)
    8000249c:	e04a                	sd	s2,0(sp)
    8000249e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a0:	00010497          	auipc	s1,0x10
    800024a4:	8c848493          	addi	s1,s1,-1848 # 80011d68 <proc>
    800024a8:	00015917          	auipc	s2,0x15
    800024ac:	4c090913          	addi	s2,s2,1216 # 80017968 <tickslock>
    acquire(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	75e080e7          	jalr	1886(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    800024ba:	4c9c                	lw	a5,24(s1)
    800024bc:	cf81                	beqz	a5,800024d4 <allocproc+0x40>
      release(&p->lock);
    800024be:	8526                	mv	a0,s1
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	804080e7          	jalr	-2044(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024c8:	17048493          	addi	s1,s1,368
    800024cc:	ff2492e3          	bne	s1,s2,800024b0 <allocproc+0x1c>
  return 0;
    800024d0:	4481                	li	s1,0
    800024d2:	a075                	j	8000257e <allocproc+0xea>
  p->pid = allocpid();
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	6c0080e7          	jalr	1728(ra) # 80001b94 <allocpid>
    800024dc:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	642080e7          	jalr	1602(ra) # 80000b20 <kalloc>
    800024e6:	892a                	mv	s2,a0
    800024e8:	eca8                	sd	a0,88(s1)
    800024ea:	c14d                	beqz	a0,8000258c <allocproc+0xf8>
  p->pagetable = proc_pagetable(p);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	6ec080e7          	jalr	1772(ra) # 80001bda <proc_pagetable>
    800024f6:	892a                	mv	s2,a0
    800024f8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    800024fa:	c145                	beqz	a0,8000259a <allocproc+0x106>
  p->prockernelpagetable=prockernelinit();
    800024fc:	fffff097          	auipc	ra,0xfffff
    80002500:	3d2080e7          	jalr	978(ra) # 800018ce <prockernelinit>
    80002504:	892a                	mv	s2,a0
    80002506:	16a4b423          	sd	a0,360(s1)
  if(p->prockernelpagetable==0){
    8000250a:	c545                	beqz	a0,800025b2 <allocproc+0x11e>
      char *pa = kalloc();
    8000250c:	ffffe097          	auipc	ra,0xffffe
    80002510:	614080e7          	jalr	1556(ra) # 80000b20 <kalloc>
    80002514:	862a                	mv	a2,a0
      if(pa == 0)
    80002516:	c955                	beqz	a0,800025ca <allocproc+0x136>
      uint64 va = KSTACK((int) (p - proc));
    80002518:	00010797          	auipc	a5,0x10
    8000251c:	85078793          	addi	a5,a5,-1968 # 80011d68 <proc>
    80002520:	40f487b3          	sub	a5,s1,a5
    80002524:	8791                	srai	a5,a5,0x4
    80002526:	00006717          	auipc	a4,0x6
    8000252a:	ada73703          	ld	a4,-1318(a4) # 80008000 <etext>
    8000252e:	02e787b3          	mul	a5,a5,a4
    80002532:	2785                	addiw	a5,a5,1
    80002534:	00d7979b          	slliw	a5,a5,0xd
    80002538:	04000937          	lui	s2,0x4000
    8000253c:	197d                	addi	s2,s2,-1
    8000253e:	0932                	slli	s2,s2,0xc
    80002540:	40f90933          	sub	s2,s2,a5
      uvmmap(p->prockernelpagetable,va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80002544:	4719                	li	a4,6
    80002546:	6685                	lui	a3,0x1
    80002548:	85ca                	mv	a1,s2
    8000254a:	1684b503          	ld	a0,360(s1)
    8000254e:	fffff097          	auipc	ra,0xfffff
    80002552:	350080e7          	jalr	848(ra) # 8000189e <uvmmap>
      p->kstack = va;
    80002556:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    8000255a:	07000613          	li	a2,112
    8000255e:	4581                	li	a1,0
    80002560:	06048513          	addi	a0,s1,96
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	7a8080e7          	jalr	1960(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    8000256c:	fffff797          	auipc	a5,0xfffff
    80002570:	5e278793          	addi	a5,a5,1506 # 80001b4e <forkret>
    80002574:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002576:	60bc                	ld	a5,64(s1)
    80002578:	6705                	lui	a4,0x1
    8000257a:	97ba                	add	a5,a5,a4
    8000257c:	f4bc                	sd	a5,104(s1)
}
    8000257e:	8526                	mv	a0,s1
    80002580:	60e2                	ld	ra,24(sp)
    80002582:	6442                	ld	s0,16(sp)
    80002584:	64a2                	ld	s1,8(sp)
    80002586:	6902                	ld	s2,0(sp)
    80002588:	6105                	addi	sp,sp,32
    8000258a:	8082                	ret
    release(&p->lock);
    8000258c:	8526                	mv	a0,s1
    8000258e:	ffffe097          	auipc	ra,0xffffe
    80002592:	736080e7          	jalr	1846(ra) # 80000cc4 <release>
    return 0;
    80002596:	84ca                	mv	s1,s2
    80002598:	b7dd                	j	8000257e <allocproc+0xea>
    freeproc(p);
    8000259a:	8526                	mv	a0,s1
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	e56080e7          	jalr	-426(ra) # 800023f2 <freeproc>
    release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	ffffe097          	auipc	ra,0xffffe
    800025aa:	71e080e7          	jalr	1822(ra) # 80000cc4 <release>
    return 0;
    800025ae:	84ca                	mv	s1,s2
    800025b0:	b7f9                	j	8000257e <allocproc+0xea>
    freeproc(p);
    800025b2:	8526                	mv	a0,s1
    800025b4:	00000097          	auipc	ra,0x0
    800025b8:	e3e080e7          	jalr	-450(ra) # 800023f2 <freeproc>
    release(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	706080e7          	jalr	1798(ra) # 80000cc4 <release>
    return 0;
    800025c6:	84ca                	mv	s1,s2
    800025c8:	bf5d                	j	8000257e <allocproc+0xea>
        panic("kalloc");
    800025ca:	00006517          	auipc	a0,0x6
    800025ce:	d4650513          	addi	a0,a0,-698 # 80008310 <digits+0x2d0>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	f76080e7          	jalr	-138(ra) # 80000548 <panic>

00000000800025da <userinit>:
{
    800025da:	1101                	addi	sp,sp,-32
    800025dc:	ec06                	sd	ra,24(sp)
    800025de:	e822                	sd	s0,16(sp)
    800025e0:	e426                	sd	s1,8(sp)
    800025e2:	e04a                	sd	s2,0(sp)
    800025e4:	1000                	addi	s0,sp,32
  p = allocproc();
    800025e6:	00000097          	auipc	ra,0x0
    800025ea:	eae080e7          	jalr	-338(ra) # 80002494 <allocproc>
    800025ee:	84aa                	mv	s1,a0
  initproc = p;
    800025f0:	00007797          	auipc	a5,0x7
    800025f4:	a2a7b423          	sd	a0,-1496(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800025f8:	03400613          	li	a2,52
    800025fc:	00006597          	auipc	a1,0x6
    80002600:	31458593          	addi	a1,a1,788 # 80008910 <initcode>
    80002604:	6928                	ld	a0,80(a0)
    80002606:	fffff097          	auipc	ra,0xfffff
    8000260a:	dd4080e7          	jalr	-556(ra) # 800013da <uvminit>
  p->sz = PGSIZE;
    8000260e:	6905                	lui	s2,0x1
    80002610:	0524b423          	sd	s2,72(s1)
  procuser2kernel(p->pagetable,p->prockernelpagetable,0,p->sz);
    80002614:	6685                	lui	a3,0x1
    80002616:	4601                	li	a2,0
    80002618:	1684b583          	ld	a1,360(s1)
    8000261c:	68a8                	ld	a0,80(s1)
    8000261e:	fffff097          	auipc	ra,0xfffff
    80002622:	386080e7          	jalr	902(ra) # 800019a4 <procuser2kernel>
  p->trapframe->epc = 0;      // user program counter
    80002626:	6cbc                	ld	a5,88(s1)
    80002628:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    8000262c:	6cbc                	ld	a5,88(s1)
    8000262e:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80002632:	4641                	li	a2,16
    80002634:	00006597          	auipc	a1,0x6
    80002638:	ce458593          	addi	a1,a1,-796 # 80008318 <digits+0x2d8>
    8000263c:	15848513          	addi	a0,s1,344
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	822080e7          	jalr	-2014(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80002648:	00006517          	auipc	a0,0x6
    8000264c:	ce050513          	addi	a0,a0,-800 # 80008328 <digits+0x2e8>
    80002650:	00002097          	auipc	ra,0x2
    80002654:	a62080e7          	jalr	-1438(ra) # 800040b2 <namei>
    80002658:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000265c:	4789                	li	a5,2
    8000265e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002660:	8526                	mv	a0,s1
    80002662:	ffffe097          	auipc	ra,0xffffe
    80002666:	662080e7          	jalr	1634(ra) # 80000cc4 <release>
}
    8000266a:	60e2                	ld	ra,24(sp)
    8000266c:	6442                	ld	s0,16(sp)
    8000266e:	64a2                	ld	s1,8(sp)
    80002670:	6902                	ld	s2,0(sp)
    80002672:	6105                	addi	sp,sp,32
    80002674:	8082                	ret

0000000080002676 <fork>:
{
    80002676:	7179                	addi	sp,sp,-48
    80002678:	f406                	sd	ra,40(sp)
    8000267a:	f022                	sd	s0,32(sp)
    8000267c:	ec26                	sd	s1,24(sp)
    8000267e:	e84a                	sd	s2,16(sp)
    80002680:	e44e                	sd	s3,8(sp)
    80002682:	e052                	sd	s4,0(sp)
    80002684:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002686:	fffff097          	auipc	ra,0xfffff
    8000268a:	490080e7          	jalr	1168(ra) # 80001b16 <myproc>
    8000268e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002690:	00000097          	auipc	ra,0x0
    80002694:	e04080e7          	jalr	-508(ra) # 80002494 <allocproc>
    80002698:	cd6d                	beqz	a0,80002792 <fork+0x11c>
    8000269a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000269c:	04893603          	ld	a2,72(s2) # 1048 <_entry-0x7fffefb8>
    800026a0:	692c                	ld	a1,80(a0)
    800026a2:	05093503          	ld	a0,80(s2)
    800026a6:	fffff097          	auipc	ra,0xfffff
    800026aa:	f3a080e7          	jalr	-198(ra) # 800015e0 <uvmcopy>
    800026ae:	04054863          	bltz	a0,800026fe <fork+0x88>
  np->sz = p->sz;
    800026b2:	04893783          	ld	a5,72(s2)
    800026b6:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    800026ba:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800026be:	05893683          	ld	a3,88(s2)
    800026c2:	87b6                	mv	a5,a3
    800026c4:	0589b703          	ld	a4,88(s3)
    800026c8:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    800026cc:	0007b803          	ld	a6,0(a5)
    800026d0:	6788                	ld	a0,8(a5)
    800026d2:	6b8c                	ld	a1,16(a5)
    800026d4:	6f90                	ld	a2,24(a5)
    800026d6:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    800026da:	e708                	sd	a0,8(a4)
    800026dc:	eb0c                	sd	a1,16(a4)
    800026de:	ef10                	sd	a2,24(a4)
    800026e0:	02078793          	addi	a5,a5,32
    800026e4:	02070713          	addi	a4,a4,32
    800026e8:	fed792e3          	bne	a5,a3,800026cc <fork+0x56>
  np->trapframe->a0 = 0;
    800026ec:	0589b783          	ld	a5,88(s3)
    800026f0:	0607b823          	sd	zero,112(a5)
    800026f4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800026f8:	15000a13          	li	s4,336
    800026fc:	a03d                	j	8000272a <fork+0xb4>
    freeproc(np);
    800026fe:	854e                	mv	a0,s3
    80002700:	00000097          	auipc	ra,0x0
    80002704:	cf2080e7          	jalr	-782(ra) # 800023f2 <freeproc>
    release(&np->lock);
    80002708:	854e                	mv	a0,s3
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	5ba080e7          	jalr	1466(ra) # 80000cc4 <release>
    return -1;
    80002712:	54fd                	li	s1,-1
    80002714:	a0b5                	j	80002780 <fork+0x10a>
      np->ofile[i] = filedup(p->ofile[i]);
    80002716:	00002097          	auipc	ra,0x2
    8000271a:	028080e7          	jalr	40(ra) # 8000473e <filedup>
    8000271e:	009987b3          	add	a5,s3,s1
    80002722:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002724:	04a1                	addi	s1,s1,8
    80002726:	01448763          	beq	s1,s4,80002734 <fork+0xbe>
    if(p->ofile[i])
    8000272a:	009907b3          	add	a5,s2,s1
    8000272e:	6388                	ld	a0,0(a5)
    80002730:	f17d                	bnez	a0,80002716 <fork+0xa0>
    80002732:	bfcd                	j	80002724 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002734:	15093503          	ld	a0,336(s2)
    80002738:	00001097          	auipc	ra,0x1
    8000273c:	18c080e7          	jalr	396(ra) # 800038c4 <idup>
    80002740:	14a9b823          	sd	a0,336(s3)
  procuser2kernel(np->pagetable,np->prockernelpagetable,0,np->sz);
    80002744:	0489b683          	ld	a3,72(s3)
    80002748:	4601                	li	a2,0
    8000274a:	1689b583          	ld	a1,360(s3)
    8000274e:	0509b503          	ld	a0,80(s3)
    80002752:	fffff097          	auipc	ra,0xfffff
    80002756:	252080e7          	jalr	594(ra) # 800019a4 <procuser2kernel>
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000275a:	4641                	li	a2,16
    8000275c:	15890593          	addi	a1,s2,344
    80002760:	15898513          	addi	a0,s3,344
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	6fe080e7          	jalr	1790(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    8000276c:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002770:	4789                	li	a5,2
    80002772:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002776:	854e                	mv	a0,s3
    80002778:	ffffe097          	auipc	ra,0xffffe
    8000277c:	54c080e7          	jalr	1356(ra) # 80000cc4 <release>
}
    80002780:	8526                	mv	a0,s1
    80002782:	70a2                	ld	ra,40(sp)
    80002784:	7402                	ld	s0,32(sp)
    80002786:	64e2                	ld	s1,24(sp)
    80002788:	6942                	ld	s2,16(sp)
    8000278a:	69a2                	ld	s3,8(sp)
    8000278c:	6a02                	ld	s4,0(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret
    return -1;
    80002792:	54fd                	li	s1,-1
    80002794:	b7f5                	j	80002780 <fork+0x10a>

0000000080002796 <wait>:
{
    80002796:	715d                	addi	sp,sp,-80
    80002798:	e486                	sd	ra,72(sp)
    8000279a:	e0a2                	sd	s0,64(sp)
    8000279c:	fc26                	sd	s1,56(sp)
    8000279e:	f84a                	sd	s2,48(sp)
    800027a0:	f44e                	sd	s3,40(sp)
    800027a2:	f052                	sd	s4,32(sp)
    800027a4:	ec56                	sd	s5,24(sp)
    800027a6:	e85a                	sd	s6,16(sp)
    800027a8:	e45e                	sd	s7,8(sp)
    800027aa:	e062                	sd	s8,0(sp)
    800027ac:	0880                	addi	s0,sp,80
    800027ae:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800027b0:	fffff097          	auipc	ra,0xfffff
    800027b4:	366080e7          	jalr	870(ra) # 80001b16 <myproc>
    800027b8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800027ba:	8c2a                	mv	s8,a0
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	454080e7          	jalr	1108(ra) # 80000c10 <acquire>
    havekids = 0;
    800027c4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800027c6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800027c8:	00015997          	auipc	s3,0x15
    800027cc:	1a098993          	addi	s3,s3,416 # 80017968 <tickslock>
        havekids = 1;
    800027d0:	4a85                	li	s5,1
    havekids = 0;
    800027d2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800027d4:	0000f497          	auipc	s1,0xf
    800027d8:	59448493          	addi	s1,s1,1428 # 80011d68 <proc>
    800027dc:	a08d                	j	8000283e <wait+0xa8>
          pid = np->pid;
    800027de:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027e2:	000b0e63          	beqz	s6,800027fe <wait+0x68>
    800027e6:	4691                	li	a3,4
    800027e8:	03448613          	addi	a2,s1,52
    800027ec:	85da                	mv	a1,s6
    800027ee:	05093503          	ld	a0,80(s2)
    800027f2:	fffff097          	auipc	ra,0xfffff
    800027f6:	ef2080e7          	jalr	-270(ra) # 800016e4 <copyout>
    800027fa:	02054263          	bltz	a0,8000281e <wait+0x88>
          freeproc(np);
    800027fe:	8526                	mv	a0,s1
    80002800:	00000097          	auipc	ra,0x0
    80002804:	bf2080e7          	jalr	-1038(ra) # 800023f2 <freeproc>
          release(&np->lock);
    80002808:	8526                	mv	a0,s1
    8000280a:	ffffe097          	auipc	ra,0xffffe
    8000280e:	4ba080e7          	jalr	1210(ra) # 80000cc4 <release>
          release(&p->lock);
    80002812:	854a                	mv	a0,s2
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	4b0080e7          	jalr	1200(ra) # 80000cc4 <release>
          return pid;
    8000281c:	a8a9                	j	80002876 <wait+0xe0>
            release(&np->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	4a4080e7          	jalr	1188(ra) # 80000cc4 <release>
            release(&p->lock);
    80002828:	854a                	mv	a0,s2
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	49a080e7          	jalr	1178(ra) # 80000cc4 <release>
            return -1;
    80002832:	59fd                	li	s3,-1
    80002834:	a089                	j	80002876 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002836:	17048493          	addi	s1,s1,368
    8000283a:	03348463          	beq	s1,s3,80002862 <wait+0xcc>
      if(np->parent == p){
    8000283e:	709c                	ld	a5,32(s1)
    80002840:	ff279be3          	bne	a5,s2,80002836 <wait+0xa0>
        acquire(&np->lock);
    80002844:	8526                	mv	a0,s1
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	3ca080e7          	jalr	970(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000284e:	4c9c                	lw	a5,24(s1)
    80002850:	f94787e3          	beq	a5,s4,800027de <wait+0x48>
        release(&np->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	46e080e7          	jalr	1134(ra) # 80000cc4 <release>
        havekids = 1;
    8000285e:	8756                	mv	a4,s5
    80002860:	bfd9                	j	80002836 <wait+0xa0>
    if(!havekids || p->killed){
    80002862:	c701                	beqz	a4,8000286a <wait+0xd4>
    80002864:	03092783          	lw	a5,48(s2)
    80002868:	c785                	beqz	a5,80002890 <wait+0xfa>
      release(&p->lock);
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	458080e7          	jalr	1112(ra) # 80000cc4 <release>
      return -1;
    80002874:	59fd                	li	s3,-1
}
    80002876:	854e                	mv	a0,s3
    80002878:	60a6                	ld	ra,72(sp)
    8000287a:	6406                	ld	s0,64(sp)
    8000287c:	74e2                	ld	s1,56(sp)
    8000287e:	7942                	ld	s2,48(sp)
    80002880:	79a2                	ld	s3,40(sp)
    80002882:	7a02                	ld	s4,32(sp)
    80002884:	6ae2                	ld	s5,24(sp)
    80002886:	6b42                	ld	s6,16(sp)
    80002888:	6ba2                	ld	s7,8(sp)
    8000288a:	6c02                	ld	s8,0(sp)
    8000288c:	6161                	addi	sp,sp,80
    8000288e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002890:	85e2                	mv	a1,s8
    80002892:	854a                	mv	a0,s2
    80002894:	00000097          	auipc	ra,0x0
    80002898:	854080e7          	jalr	-1964(ra) # 800020e8 <sleep>
    havekids = 0;
    8000289c:	bf1d                	j	800027d2 <wait+0x3c>

000000008000289e <swtch>:
    8000289e:	00153023          	sd	ra,0(a0)
    800028a2:	00253423          	sd	sp,8(a0)
    800028a6:	e900                	sd	s0,16(a0)
    800028a8:	ed04                	sd	s1,24(a0)
    800028aa:	03253023          	sd	s2,32(a0)
    800028ae:	03353423          	sd	s3,40(a0)
    800028b2:	03453823          	sd	s4,48(a0)
    800028b6:	03553c23          	sd	s5,56(a0)
    800028ba:	05653023          	sd	s6,64(a0)
    800028be:	05753423          	sd	s7,72(a0)
    800028c2:	05853823          	sd	s8,80(a0)
    800028c6:	05953c23          	sd	s9,88(a0)
    800028ca:	07a53023          	sd	s10,96(a0)
    800028ce:	07b53423          	sd	s11,104(a0)
    800028d2:	0005b083          	ld	ra,0(a1)
    800028d6:	0085b103          	ld	sp,8(a1)
    800028da:	6980                	ld	s0,16(a1)
    800028dc:	6d84                	ld	s1,24(a1)
    800028de:	0205b903          	ld	s2,32(a1)
    800028e2:	0285b983          	ld	s3,40(a1)
    800028e6:	0305ba03          	ld	s4,48(a1)
    800028ea:	0385ba83          	ld	s5,56(a1)
    800028ee:	0405bb03          	ld	s6,64(a1)
    800028f2:	0485bb83          	ld	s7,72(a1)
    800028f6:	0505bc03          	ld	s8,80(a1)
    800028fa:	0585bc83          	ld	s9,88(a1)
    800028fe:	0605bd03          	ld	s10,96(a1)
    80002902:	0685bd83          	ld	s11,104(a1)
    80002906:	8082                	ret

0000000080002908 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002908:	1141                	addi	sp,sp,-16
    8000290a:	e406                	sd	ra,8(sp)
    8000290c:	e022                	sd	s0,0(sp)
    8000290e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002910:	00006597          	auipc	a1,0x6
    80002914:	a7058593          	addi	a1,a1,-1424 # 80008380 <states.1756+0x28>
    80002918:	00015517          	auipc	a0,0x15
    8000291c:	05050513          	addi	a0,a0,80 # 80017968 <tickslock>
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	260080e7          	jalr	608(ra) # 80000b80 <initlock>
}
    80002928:	60a2                	ld	ra,8(sp)
    8000292a:	6402                	ld	s0,0(sp)
    8000292c:	0141                	addi	sp,sp,16
    8000292e:	8082                	ret

0000000080002930 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002930:	1141                	addi	sp,sp,-16
    80002932:	e422                	sd	s0,8(sp)
    80002934:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002936:	00003797          	auipc	a5,0x3
    8000293a:	4ea78793          	addi	a5,a5,1258 # 80005e20 <kernelvec>
    8000293e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002942:	6422                	ld	s0,8(sp)
    80002944:	0141                	addi	sp,sp,16
    80002946:	8082                	ret

0000000080002948 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002948:	1141                	addi	sp,sp,-16
    8000294a:	e406                	sd	ra,8(sp)
    8000294c:	e022                	sd	s0,0(sp)
    8000294e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002950:	fffff097          	auipc	ra,0xfffff
    80002954:	1c6080e7          	jalr	454(ra) # 80001b16 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000295c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002962:	00004617          	auipc	a2,0x4
    80002966:	69e60613          	addi	a2,a2,1694 # 80007000 <_trampoline>
    8000296a:	00004697          	auipc	a3,0x4
    8000296e:	69668693          	addi	a3,a3,1686 # 80007000 <_trampoline>
    80002972:	8e91                	sub	a3,a3,a2
    80002974:	040007b7          	lui	a5,0x4000
    80002978:	17fd                	addi	a5,a5,-1
    8000297a:	07b2                	slli	a5,a5,0xc
    8000297c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000297e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002982:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002984:	180026f3          	csrr	a3,satp
    80002988:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000298a:	6d38                	ld	a4,88(a0)
    8000298c:	6134                	ld	a3,64(a0)
    8000298e:	6585                	lui	a1,0x1
    80002990:	96ae                	add	a3,a3,a1
    80002992:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002994:	6d38                	ld	a4,88(a0)
    80002996:	00000697          	auipc	a3,0x0
    8000299a:	13868693          	addi	a3,a3,312 # 80002ace <usertrap>
    8000299e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a0:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029a2:	8692                	mv	a3,tp
    800029a4:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029aa:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029ae:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b2:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029b6:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b8:	6f18                	ld	a4,24(a4)
    800029ba:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029be:	692c                	ld	a1,80(a0)
    800029c0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029c2:	00004717          	auipc	a4,0x4
    800029c6:	6ce70713          	addi	a4,a4,1742 # 80007090 <userret>
    800029ca:	8f11                	sub	a4,a4,a2
    800029cc:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029ce:	577d                	li	a4,-1
    800029d0:	177e                	slli	a4,a4,0x3f
    800029d2:	8dd9                	or	a1,a1,a4
    800029d4:	02000537          	lui	a0,0x2000
    800029d8:	157d                	addi	a0,a0,-1
    800029da:	0536                	slli	a0,a0,0xd
    800029dc:	9782                	jalr	a5
}
    800029de:	60a2                	ld	ra,8(sp)
    800029e0:	6402                	ld	s0,0(sp)
    800029e2:	0141                	addi	sp,sp,16
    800029e4:	8082                	ret

00000000800029e6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029e6:	1101                	addi	sp,sp,-32
    800029e8:	ec06                	sd	ra,24(sp)
    800029ea:	e822                	sd	s0,16(sp)
    800029ec:	e426                	sd	s1,8(sp)
    800029ee:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f0:	00015497          	auipc	s1,0x15
    800029f4:	f7848493          	addi	s1,s1,-136 # 80017968 <tickslock>
    800029f8:	8526                	mv	a0,s1
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	216080e7          	jalr	534(ra) # 80000c10 <acquire>
  ticks++;
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	61e50513          	addi	a0,a0,1566 # 80009020 <ticks>
    80002a0a:	411c                	lw	a5,0(a0)
    80002a0c:	2785                	addiw	a5,a5,1
    80002a0e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a10:	fffff097          	auipc	ra,0xfffff
    80002a14:	756080e7          	jalr	1878(ra) # 80002166 <wakeup>
  release(&tickslock);
    80002a18:	8526                	mv	a0,s1
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	2aa080e7          	jalr	682(ra) # 80000cc4 <release>
}
    80002a22:	60e2                	ld	ra,24(sp)
    80002a24:	6442                	ld	s0,16(sp)
    80002a26:	64a2                	ld	s1,8(sp)
    80002a28:	6105                	addi	sp,sp,32
    80002a2a:	8082                	ret

0000000080002a2c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a2c:	1101                	addi	sp,sp,-32
    80002a2e:	ec06                	sd	ra,24(sp)
    80002a30:	e822                	sd	s0,16(sp)
    80002a32:	e426                	sd	s1,8(sp)
    80002a34:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a36:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a3a:	00074d63          	bltz	a4,80002a54 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a3e:	57fd                	li	a5,-1
    80002a40:	17fe                	slli	a5,a5,0x3f
    80002a42:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a44:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a46:	06f70363          	beq	a4,a5,80002aac <devintr+0x80>
  }
}
    80002a4a:	60e2                	ld	ra,24(sp)
    80002a4c:	6442                	ld	s0,16(sp)
    80002a4e:	64a2                	ld	s1,8(sp)
    80002a50:	6105                	addi	sp,sp,32
    80002a52:	8082                	ret
     (scause & 0xff) == 9){
    80002a54:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a58:	46a5                	li	a3,9
    80002a5a:	fed792e3          	bne	a5,a3,80002a3e <devintr+0x12>
    int irq = plic_claim();
    80002a5e:	00003097          	auipc	ra,0x3
    80002a62:	4ca080e7          	jalr	1226(ra) # 80005f28 <plic_claim>
    80002a66:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a68:	47a9                	li	a5,10
    80002a6a:	02f50763          	beq	a0,a5,80002a98 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a6e:	4785                	li	a5,1
    80002a70:	02f50963          	beq	a0,a5,80002aa2 <devintr+0x76>
    return 1;
    80002a74:	4505                	li	a0,1
    } else if(irq){
    80002a76:	d8f1                	beqz	s1,80002a4a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a78:	85a6                	mv	a1,s1
    80002a7a:	00006517          	auipc	a0,0x6
    80002a7e:	90e50513          	addi	a0,a0,-1778 # 80008388 <states.1756+0x30>
    80002a82:	ffffe097          	auipc	ra,0xffffe
    80002a86:	b10080e7          	jalr	-1264(ra) # 80000592 <printf>
      plic_complete(irq);
    80002a8a:	8526                	mv	a0,s1
    80002a8c:	00003097          	auipc	ra,0x3
    80002a90:	4c0080e7          	jalr	1216(ra) # 80005f4c <plic_complete>
    return 1;
    80002a94:	4505                	li	a0,1
    80002a96:	bf55                	j	80002a4a <devintr+0x1e>
      uartintr();
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	f3c080e7          	jalr	-196(ra) # 800009d4 <uartintr>
    80002aa0:	b7ed                	j	80002a8a <devintr+0x5e>
      virtio_disk_intr();
    80002aa2:	00004097          	auipc	ra,0x4
    80002aa6:	944080e7          	jalr	-1724(ra) # 800063e6 <virtio_disk_intr>
    80002aaa:	b7c5                	j	80002a8a <devintr+0x5e>
    if(cpuid() == 0){
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	03e080e7          	jalr	62(ra) # 80001aea <cpuid>
    80002ab4:	c901                	beqz	a0,80002ac4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002ab6:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aba:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002abc:	14479073          	csrw	sip,a5
    return 2;
    80002ac0:	4509                	li	a0,2
    80002ac2:	b761                	j	80002a4a <devintr+0x1e>
      clockintr();
    80002ac4:	00000097          	auipc	ra,0x0
    80002ac8:	f22080e7          	jalr	-222(ra) # 800029e6 <clockintr>
    80002acc:	b7ed                	j	80002ab6 <devintr+0x8a>

0000000080002ace <usertrap>:
{
    80002ace:	1101                	addi	sp,sp,-32
    80002ad0:	ec06                	sd	ra,24(sp)
    80002ad2:	e822                	sd	s0,16(sp)
    80002ad4:	e426                	sd	s1,8(sp)
    80002ad6:	e04a                	sd	s2,0(sp)
    80002ad8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ada:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ade:	1007f793          	andi	a5,a5,256
    80002ae2:	e3ad                	bnez	a5,80002b44 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ae4:	00003797          	auipc	a5,0x3
    80002ae8:	33c78793          	addi	a5,a5,828 # 80005e20 <kernelvec>
    80002aec:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af0:	fffff097          	auipc	ra,0xfffff
    80002af4:	026080e7          	jalr	38(ra) # 80001b16 <myproc>
    80002af8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002afa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afc:	14102773          	csrr	a4,sepc
    80002b00:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b02:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b06:	47a1                	li	a5,8
    80002b08:	04f71c63          	bne	a4,a5,80002b60 <usertrap+0x92>
    if(p->killed)
    80002b0c:	591c                	lw	a5,48(a0)
    80002b0e:	e3b9                	bnez	a5,80002b54 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b10:	6cb8                	ld	a4,88(s1)
    80002b12:	6f1c                	ld	a5,24(a4)
    80002b14:	0791                	addi	a5,a5,4
    80002b16:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b18:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b1c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b20:	10079073          	csrw	sstatus,a5
    syscall();
    80002b24:	00000097          	auipc	ra,0x0
    80002b28:	2e0080e7          	jalr	736(ra) # 80002e04 <syscall>
  if(p->killed)
    80002b2c:	589c                	lw	a5,48(s1)
    80002b2e:	ebc1                	bnez	a5,80002bbe <usertrap+0xf0>
  usertrapret();
    80002b30:	00000097          	auipc	ra,0x0
    80002b34:	e18080e7          	jalr	-488(ra) # 80002948 <usertrapret>
}
    80002b38:	60e2                	ld	ra,24(sp)
    80002b3a:	6442                	ld	s0,16(sp)
    80002b3c:	64a2                	ld	s1,8(sp)
    80002b3e:	6902                	ld	s2,0(sp)
    80002b40:	6105                	addi	sp,sp,32
    80002b42:	8082                	ret
    panic("usertrap: not from user mode");
    80002b44:	00006517          	auipc	a0,0x6
    80002b48:	86450513          	addi	a0,a0,-1948 # 800083a8 <states.1756+0x50>
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	9fc080e7          	jalr	-1540(ra) # 80000548 <panic>
      exit(-1);
    80002b54:	557d                	li	a0,-1
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	44c080e7          	jalr	1100(ra) # 80001fa2 <exit>
    80002b5e:	bf4d                	j	80002b10 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	ecc080e7          	jalr	-308(ra) # 80002a2c <devintr>
    80002b68:	892a                	mv	s2,a0
    80002b6a:	c501                	beqz	a0,80002b72 <usertrap+0xa4>
  if(p->killed)
    80002b6c:	589c                	lw	a5,48(s1)
    80002b6e:	c3a1                	beqz	a5,80002bae <usertrap+0xe0>
    80002b70:	a815                	j	80002ba4 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b72:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b76:	5c90                	lw	a2,56(s1)
    80002b78:	00006517          	auipc	a0,0x6
    80002b7c:	85050513          	addi	a0,a0,-1968 # 800083c8 <states.1756+0x70>
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	a12080e7          	jalr	-1518(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b88:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b8c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b90:	00006517          	auipc	a0,0x6
    80002b94:	86850513          	addi	a0,a0,-1944 # 800083f8 <states.1756+0xa0>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	9fa080e7          	jalr	-1542(ra) # 80000592 <printf>
    p->killed = 1;
    80002ba0:	4785                	li	a5,1
    80002ba2:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002ba4:	557d                	li	a0,-1
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	3fc080e7          	jalr	1020(ra) # 80001fa2 <exit>
  if(which_dev == 2)
    80002bae:	4789                	li	a5,2
    80002bb0:	f8f910e3          	bne	s2,a5,80002b30 <usertrap+0x62>
    yield();
    80002bb4:	fffff097          	auipc	ra,0xfffff
    80002bb8:	4f8080e7          	jalr	1272(ra) # 800020ac <yield>
    80002bbc:	bf95                	j	80002b30 <usertrap+0x62>
  int which_dev = 0;
    80002bbe:	4901                	li	s2,0
    80002bc0:	b7d5                	j	80002ba4 <usertrap+0xd6>

0000000080002bc2 <kerneltrap>:
{
    80002bc2:	7179                	addi	sp,sp,-48
    80002bc4:	f406                	sd	ra,40(sp)
    80002bc6:	f022                	sd	s0,32(sp)
    80002bc8:	ec26                	sd	s1,24(sp)
    80002bca:	e84a                	sd	s2,16(sp)
    80002bcc:	e44e                	sd	s3,8(sp)
    80002bce:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bdc:	1004f793          	andi	a5,s1,256
    80002be0:	cb85                	beqz	a5,80002c10 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002be8:	ef85                	bnez	a5,80002c20 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	e42080e7          	jalr	-446(ra) # 80002a2c <devintr>
    80002bf2:	cd1d                	beqz	a0,80002c30 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf4:	4789                	li	a5,2
    80002bf6:	06f50a63          	beq	a0,a5,80002c6a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bfa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bfe:	10049073          	csrw	sstatus,s1
}
    80002c02:	70a2                	ld	ra,40(sp)
    80002c04:	7402                	ld	s0,32(sp)
    80002c06:	64e2                	ld	s1,24(sp)
    80002c08:	6942                	ld	s2,16(sp)
    80002c0a:	69a2                	ld	s3,8(sp)
    80002c0c:	6145                	addi	sp,sp,48
    80002c0e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c10:	00006517          	auipc	a0,0x6
    80002c14:	80850513          	addi	a0,a0,-2040 # 80008418 <states.1756+0xc0>
    80002c18:	ffffe097          	auipc	ra,0xffffe
    80002c1c:	930080e7          	jalr	-1744(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c20:	00006517          	auipc	a0,0x6
    80002c24:	82050513          	addi	a0,a0,-2016 # 80008440 <states.1756+0xe8>
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	920080e7          	jalr	-1760(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002c30:	85ce                	mv	a1,s3
    80002c32:	00006517          	auipc	a0,0x6
    80002c36:	82e50513          	addi	a0,a0,-2002 # 80008460 <states.1756+0x108>
    80002c3a:	ffffe097          	auipc	ra,0xffffe
    80002c3e:	958080e7          	jalr	-1704(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c42:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c46:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4a:	00006517          	auipc	a0,0x6
    80002c4e:	82650513          	addi	a0,a0,-2010 # 80008470 <states.1756+0x118>
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	940080e7          	jalr	-1728(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002c5a:	00006517          	auipc	a0,0x6
    80002c5e:	82e50513          	addi	a0,a0,-2002 # 80008488 <states.1756+0x130>
    80002c62:	ffffe097          	auipc	ra,0xffffe
    80002c66:	8e6080e7          	jalr	-1818(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	eac080e7          	jalr	-340(ra) # 80001b16 <myproc>
    80002c72:	d541                	beqz	a0,80002bfa <kerneltrap+0x38>
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	ea2080e7          	jalr	-350(ra) # 80001b16 <myproc>
    80002c7c:	4d18                	lw	a4,24(a0)
    80002c7e:	478d                	li	a5,3
    80002c80:	f6f71de3          	bne	a4,a5,80002bfa <kerneltrap+0x38>
    yield();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	428080e7          	jalr	1064(ra) # 800020ac <yield>
    80002c8c:	b7bd                	j	80002bfa <kerneltrap+0x38>

0000000080002c8e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c8e:	1101                	addi	sp,sp,-32
    80002c90:	ec06                	sd	ra,24(sp)
    80002c92:	e822                	sd	s0,16(sp)
    80002c94:	e426                	sd	s1,8(sp)
    80002c96:	1000                	addi	s0,sp,32
    80002c98:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	e7c080e7          	jalr	-388(ra) # 80001b16 <myproc>
  switch (n) {
    80002ca2:	4795                	li	a5,5
    80002ca4:	0497e163          	bltu	a5,s1,80002ce6 <argraw+0x58>
    80002ca8:	048a                	slli	s1,s1,0x2
    80002caa:	00006717          	auipc	a4,0x6
    80002cae:	81670713          	addi	a4,a4,-2026 # 800084c0 <states.1756+0x168>
    80002cb2:	94ba                	add	s1,s1,a4
    80002cb4:	409c                	lw	a5,0(s1)
    80002cb6:	97ba                	add	a5,a5,a4
    80002cb8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cba:	6d3c                	ld	a5,88(a0)
    80002cbc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	64a2                	ld	s1,8(sp)
    80002cc4:	6105                	addi	sp,sp,32
    80002cc6:	8082                	ret
    return p->trapframe->a1;
    80002cc8:	6d3c                	ld	a5,88(a0)
    80002cca:	7fa8                	ld	a0,120(a5)
    80002ccc:	bfcd                	j	80002cbe <argraw+0x30>
    return p->trapframe->a2;
    80002cce:	6d3c                	ld	a5,88(a0)
    80002cd0:	63c8                	ld	a0,128(a5)
    80002cd2:	b7f5                	j	80002cbe <argraw+0x30>
    return p->trapframe->a3;
    80002cd4:	6d3c                	ld	a5,88(a0)
    80002cd6:	67c8                	ld	a0,136(a5)
    80002cd8:	b7dd                	j	80002cbe <argraw+0x30>
    return p->trapframe->a4;
    80002cda:	6d3c                	ld	a5,88(a0)
    80002cdc:	6bc8                	ld	a0,144(a5)
    80002cde:	b7c5                	j	80002cbe <argraw+0x30>
    return p->trapframe->a5;
    80002ce0:	6d3c                	ld	a5,88(a0)
    80002ce2:	6fc8                	ld	a0,152(a5)
    80002ce4:	bfe9                	j	80002cbe <argraw+0x30>
  panic("argraw");
    80002ce6:	00005517          	auipc	a0,0x5
    80002cea:	7b250513          	addi	a0,a0,1970 # 80008498 <states.1756+0x140>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	85a080e7          	jalr	-1958(ra) # 80000548 <panic>

0000000080002cf6 <fetchaddr>:
{
    80002cf6:	1101                	addi	sp,sp,-32
    80002cf8:	ec06                	sd	ra,24(sp)
    80002cfa:	e822                	sd	s0,16(sp)
    80002cfc:	e426                	sd	s1,8(sp)
    80002cfe:	e04a                	sd	s2,0(sp)
    80002d00:	1000                	addi	s0,sp,32
    80002d02:	84aa                	mv	s1,a0
    80002d04:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	e10080e7          	jalr	-496(ra) # 80001b16 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d0e:	653c                	ld	a5,72(a0)
    80002d10:	02f4f863          	bgeu	s1,a5,80002d40 <fetchaddr+0x4a>
    80002d14:	00848713          	addi	a4,s1,8
    80002d18:	02e7e663          	bltu	a5,a4,80002d44 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d1c:	46a1                	li	a3,8
    80002d1e:	8626                	mv	a2,s1
    80002d20:	85ca                	mv	a1,s2
    80002d22:	6928                	ld	a0,80(a0)
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	a4c080e7          	jalr	-1460(ra) # 80001770 <copyin>
    80002d2c:	00a03533          	snez	a0,a0
    80002d30:	40a00533          	neg	a0,a0
}
    80002d34:	60e2                	ld	ra,24(sp)
    80002d36:	6442                	ld	s0,16(sp)
    80002d38:	64a2                	ld	s1,8(sp)
    80002d3a:	6902                	ld	s2,0(sp)
    80002d3c:	6105                	addi	sp,sp,32
    80002d3e:	8082                	ret
    return -1;
    80002d40:	557d                	li	a0,-1
    80002d42:	bfcd                	j	80002d34 <fetchaddr+0x3e>
    80002d44:	557d                	li	a0,-1
    80002d46:	b7fd                	j	80002d34 <fetchaddr+0x3e>

0000000080002d48 <fetchstr>:
{
    80002d48:	7179                	addi	sp,sp,-48
    80002d4a:	f406                	sd	ra,40(sp)
    80002d4c:	f022                	sd	s0,32(sp)
    80002d4e:	ec26                	sd	s1,24(sp)
    80002d50:	e84a                	sd	s2,16(sp)
    80002d52:	e44e                	sd	s3,8(sp)
    80002d54:	1800                	addi	s0,sp,48
    80002d56:	892a                	mv	s2,a0
    80002d58:	84ae                	mv	s1,a1
    80002d5a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	dba080e7          	jalr	-582(ra) # 80001b16 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d64:	86ce                	mv	a3,s3
    80002d66:	864a                	mv	a2,s2
    80002d68:	85a6                	mv	a1,s1
    80002d6a:	6928                	ld	a0,80(a0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	a1c080e7          	jalr	-1508(ra) # 80001788 <copyinstr>
  if(err < 0)
    80002d74:	00054763          	bltz	a0,80002d82 <fetchstr+0x3a>
  return strlen(buf);
    80002d78:	8526                	mv	a0,s1
    80002d7a:	ffffe097          	auipc	ra,0xffffe
    80002d7e:	11a080e7          	jalr	282(ra) # 80000e94 <strlen>
}
    80002d82:	70a2                	ld	ra,40(sp)
    80002d84:	7402                	ld	s0,32(sp)
    80002d86:	64e2                	ld	s1,24(sp)
    80002d88:	6942                	ld	s2,16(sp)
    80002d8a:	69a2                	ld	s3,8(sp)
    80002d8c:	6145                	addi	sp,sp,48
    80002d8e:	8082                	ret

0000000080002d90 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	e426                	sd	s1,8(sp)
    80002d98:	1000                	addi	s0,sp,32
    80002d9a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	ef2080e7          	jalr	-270(ra) # 80002c8e <argraw>
    80002da4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002da6:	4501                	li	a0,0
    80002da8:	60e2                	ld	ra,24(sp)
    80002daa:	6442                	ld	s0,16(sp)
    80002dac:	64a2                	ld	s1,8(sp)
    80002dae:	6105                	addi	sp,sp,32
    80002db0:	8082                	ret

0000000080002db2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002db2:	1101                	addi	sp,sp,-32
    80002db4:	ec06                	sd	ra,24(sp)
    80002db6:	e822                	sd	s0,16(sp)
    80002db8:	e426                	sd	s1,8(sp)
    80002dba:	1000                	addi	s0,sp,32
    80002dbc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dbe:	00000097          	auipc	ra,0x0
    80002dc2:	ed0080e7          	jalr	-304(ra) # 80002c8e <argraw>
    80002dc6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002dc8:	4501                	li	a0,0
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	64a2                	ld	s1,8(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret

0000000080002dd4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd4:	1101                	addi	sp,sp,-32
    80002dd6:	ec06                	sd	ra,24(sp)
    80002dd8:	e822                	sd	s0,16(sp)
    80002dda:	e426                	sd	s1,8(sp)
    80002ddc:	e04a                	sd	s2,0(sp)
    80002dde:	1000                	addi	s0,sp,32
    80002de0:	84ae                	mv	s1,a1
    80002de2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	eaa080e7          	jalr	-342(ra) # 80002c8e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002dec:	864a                	mv	a2,s2
    80002dee:	85a6                	mv	a1,s1
    80002df0:	00000097          	auipc	ra,0x0
    80002df4:	f58080e7          	jalr	-168(ra) # 80002d48 <fetchstr>
}
    80002df8:	60e2                	ld	ra,24(sp)
    80002dfa:	6442                	ld	s0,16(sp)
    80002dfc:	64a2                	ld	s1,8(sp)
    80002dfe:	6902                	ld	s2,0(sp)
    80002e00:	6105                	addi	sp,sp,32
    80002e02:	8082                	ret

0000000080002e04 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e04:	1101                	addi	sp,sp,-32
    80002e06:	ec06                	sd	ra,24(sp)
    80002e08:	e822                	sd	s0,16(sp)
    80002e0a:	e426                	sd	s1,8(sp)
    80002e0c:	e04a                	sd	s2,0(sp)
    80002e0e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	d06080e7          	jalr	-762(ra) # 80001b16 <myproc>
    80002e18:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e1a:	05853903          	ld	s2,88(a0)
    80002e1e:	0a893783          	ld	a5,168(s2)
    80002e22:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e26:	37fd                	addiw	a5,a5,-1
    80002e28:	4751                	li	a4,20
    80002e2a:	00f76f63          	bltu	a4,a5,80002e48 <syscall+0x44>
    80002e2e:	00369713          	slli	a4,a3,0x3
    80002e32:	00005797          	auipc	a5,0x5
    80002e36:	6a678793          	addi	a5,a5,1702 # 800084d8 <syscalls>
    80002e3a:	97ba                	add	a5,a5,a4
    80002e3c:	639c                	ld	a5,0(a5)
    80002e3e:	c789                	beqz	a5,80002e48 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e40:	9782                	jalr	a5
    80002e42:	06a93823          	sd	a0,112(s2)
    80002e46:	a839                	j	80002e64 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e48:	15848613          	addi	a2,s1,344
    80002e4c:	5c8c                	lw	a1,56(s1)
    80002e4e:	00005517          	auipc	a0,0x5
    80002e52:	65250513          	addi	a0,a0,1618 # 800084a0 <states.1756+0x148>
    80002e56:	ffffd097          	auipc	ra,0xffffd
    80002e5a:	73c080e7          	jalr	1852(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e5e:	6cbc                	ld	a5,88(s1)
    80002e60:	577d                	li	a4,-1
    80002e62:	fbb8                	sd	a4,112(a5)
  }
}
    80002e64:	60e2                	ld	ra,24(sp)
    80002e66:	6442                	ld	s0,16(sp)
    80002e68:	64a2                	ld	s1,8(sp)
    80002e6a:	6902                	ld	s2,0(sp)
    80002e6c:	6105                	addi	sp,sp,32
    80002e6e:	8082                	ret

0000000080002e70 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002e70:	1101                	addi	sp,sp,-32
    80002e72:	ec06                	sd	ra,24(sp)
    80002e74:	e822                	sd	s0,16(sp)
    80002e76:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e78:	fec40593          	addi	a1,s0,-20
    80002e7c:	4501                	li	a0,0
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	f12080e7          	jalr	-238(ra) # 80002d90 <argint>
    return -1;
    80002e86:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e88:	00054963          	bltz	a0,80002e9a <sys_exit+0x2a>
  exit(n);
    80002e8c:	fec42503          	lw	a0,-20(s0)
    80002e90:	fffff097          	auipc	ra,0xfffff
    80002e94:	112080e7          	jalr	274(ra) # 80001fa2 <exit>
  return 0;  // not reached
    80002e98:	4781                	li	a5,0
}
    80002e9a:	853e                	mv	a0,a5
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	6105                	addi	sp,sp,32
    80002ea2:	8082                	ret

0000000080002ea4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea4:	1141                	addi	sp,sp,-16
    80002ea6:	e406                	sd	ra,8(sp)
    80002ea8:	e022                	sd	s0,0(sp)
    80002eaa:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	c6a080e7          	jalr	-918(ra) # 80001b16 <myproc>
}
    80002eb4:	5d08                	lw	a0,56(a0)
    80002eb6:	60a2                	ld	ra,8(sp)
    80002eb8:	6402                	ld	s0,0(sp)
    80002eba:	0141                	addi	sp,sp,16
    80002ebc:	8082                	ret

0000000080002ebe <sys_fork>:

uint64
sys_fork(void)
{
    80002ebe:	1141                	addi	sp,sp,-16
    80002ec0:	e406                	sd	ra,8(sp)
    80002ec2:	e022                	sd	s0,0(sp)
    80002ec4:	0800                	addi	s0,sp,16
  return fork();
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	7b0080e7          	jalr	1968(ra) # 80002676 <fork>
}
    80002ece:	60a2                	ld	ra,8(sp)
    80002ed0:	6402                	ld	s0,0(sp)
    80002ed2:	0141                	addi	sp,sp,16
    80002ed4:	8082                	ret

0000000080002ed6 <sys_wait>:

uint64
sys_wait(void)
{
    80002ed6:	1101                	addi	sp,sp,-32
    80002ed8:	ec06                	sd	ra,24(sp)
    80002eda:	e822                	sd	s0,16(sp)
    80002edc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002ede:	fe840593          	addi	a1,s0,-24
    80002ee2:	4501                	li	a0,0
    80002ee4:	00000097          	auipc	ra,0x0
    80002ee8:	ece080e7          	jalr	-306(ra) # 80002db2 <argaddr>
    80002eec:	87aa                	mv	a5,a0
    return -1;
    80002eee:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ef0:	0007c863          	bltz	a5,80002f00 <sys_wait+0x2a>
  return wait(p);
    80002ef4:	fe843503          	ld	a0,-24(s0)
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	89e080e7          	jalr	-1890(ra) # 80002796 <wait>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f12:	fdc40593          	addi	a1,s0,-36
    80002f16:	4501                	li	a0,0
    80002f18:	00000097          	auipc	ra,0x0
    80002f1c:	e78080e7          	jalr	-392(ra) # 80002d90 <argint>
    80002f20:	87aa                	mv	a5,a0
    return -1;
    80002f22:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002f24:	0207c063          	bltz	a5,80002f44 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	bee080e7          	jalr	-1042(ra) # 80001b16 <myproc>
    80002f30:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f32:	fdc42503          	lw	a0,-36(s0)
    80002f36:	fffff097          	auipc	ra,0xfffff
    80002f3a:	d92080e7          	jalr	-622(ra) # 80001cc8 <growproc>
    80002f3e:	00054863          	bltz	a0,80002f4e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002f42:	8526                	mv	a0,s1
}
    80002f44:	70a2                	ld	ra,40(sp)
    80002f46:	7402                	ld	s0,32(sp)
    80002f48:	64e2                	ld	s1,24(sp)
    80002f4a:	6145                	addi	sp,sp,48
    80002f4c:	8082                	ret
    return -1;
    80002f4e:	557d                	li	a0,-1
    80002f50:	bfd5                	j	80002f44 <sys_sbrk+0x3c>

0000000080002f52 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f52:	7139                	addi	sp,sp,-64
    80002f54:	fc06                	sd	ra,56(sp)
    80002f56:	f822                	sd	s0,48(sp)
    80002f58:	f426                	sd	s1,40(sp)
    80002f5a:	f04a                	sd	s2,32(sp)
    80002f5c:	ec4e                	sd	s3,24(sp)
    80002f5e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f60:	fcc40593          	addi	a1,s0,-52
    80002f64:	4501                	li	a0,0
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	e2a080e7          	jalr	-470(ra) # 80002d90 <argint>
    return -1;
    80002f6e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f70:	06054563          	bltz	a0,80002fda <sys_sleep+0x88>
  acquire(&tickslock);
    80002f74:	00015517          	auipc	a0,0x15
    80002f78:	9f450513          	addi	a0,a0,-1548 # 80017968 <tickslock>
    80002f7c:	ffffe097          	auipc	ra,0xffffe
    80002f80:	c94080e7          	jalr	-876(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002f84:	00006917          	auipc	s2,0x6
    80002f88:	09c92903          	lw	s2,156(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002f8c:	fcc42783          	lw	a5,-52(s0)
    80002f90:	cf85                	beqz	a5,80002fc8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002f92:	00015997          	auipc	s3,0x15
    80002f96:	9d698993          	addi	s3,s3,-1578 # 80017968 <tickslock>
    80002f9a:	00006497          	auipc	s1,0x6
    80002f9e:	08648493          	addi	s1,s1,134 # 80009020 <ticks>
    if(myproc()->killed){
    80002fa2:	fffff097          	auipc	ra,0xfffff
    80002fa6:	b74080e7          	jalr	-1164(ra) # 80001b16 <myproc>
    80002faa:	591c                	lw	a5,48(a0)
    80002fac:	ef9d                	bnez	a5,80002fea <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002fae:	85ce                	mv	a1,s3
    80002fb0:	8526                	mv	a0,s1
    80002fb2:	fffff097          	auipc	ra,0xfffff
    80002fb6:	136080e7          	jalr	310(ra) # 800020e8 <sleep>
  while(ticks - ticks0 < n){
    80002fba:	409c                	lw	a5,0(s1)
    80002fbc:	412787bb          	subw	a5,a5,s2
    80002fc0:	fcc42703          	lw	a4,-52(s0)
    80002fc4:	fce7efe3          	bltu	a5,a4,80002fa2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002fc8:	00015517          	auipc	a0,0x15
    80002fcc:	9a050513          	addi	a0,a0,-1632 # 80017968 <tickslock>
    80002fd0:	ffffe097          	auipc	ra,0xffffe
    80002fd4:	cf4080e7          	jalr	-780(ra) # 80000cc4 <release>
  return 0;
    80002fd8:	4781                	li	a5,0
}
    80002fda:	853e                	mv	a0,a5
    80002fdc:	70e2                	ld	ra,56(sp)
    80002fde:	7442                	ld	s0,48(sp)
    80002fe0:	74a2                	ld	s1,40(sp)
    80002fe2:	7902                	ld	s2,32(sp)
    80002fe4:	69e2                	ld	s3,24(sp)
    80002fe6:	6121                	addi	sp,sp,64
    80002fe8:	8082                	ret
      release(&tickslock);
    80002fea:	00015517          	auipc	a0,0x15
    80002fee:	97e50513          	addi	a0,a0,-1666 # 80017968 <tickslock>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	cd2080e7          	jalr	-814(ra) # 80000cc4 <release>
      return -1;
    80002ffa:	57fd                	li	a5,-1
    80002ffc:	bff9                	j	80002fda <sys_sleep+0x88>

0000000080002ffe <sys_kill>:

uint64
sys_kill(void)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003006:	fec40593          	addi	a1,s0,-20
    8000300a:	4501                	li	a0,0
    8000300c:	00000097          	auipc	ra,0x0
    80003010:	d84080e7          	jalr	-636(ra) # 80002d90 <argint>
    80003014:	87aa                	mv	a5,a0
    return -1;
    80003016:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80003018:	0007c863          	bltz	a5,80003028 <sys_kill+0x2a>
  return kill(pid);
    8000301c:	fec42503          	lw	a0,-20(s0)
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	1b0080e7          	jalr	432(ra) # 800021d0 <kill>
}
    80003028:	60e2                	ld	ra,24(sp)
    8000302a:	6442                	ld	s0,16(sp)
    8000302c:	6105                	addi	sp,sp,32
    8000302e:	8082                	ret

0000000080003030 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003030:	1101                	addi	sp,sp,-32
    80003032:	ec06                	sd	ra,24(sp)
    80003034:	e822                	sd	s0,16(sp)
    80003036:	e426                	sd	s1,8(sp)
    80003038:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000303a:	00015517          	auipc	a0,0x15
    8000303e:	92e50513          	addi	a0,a0,-1746 # 80017968 <tickslock>
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	bce080e7          	jalr	-1074(ra) # 80000c10 <acquire>
  xticks = ticks;
    8000304a:	00006497          	auipc	s1,0x6
    8000304e:	fd64a483          	lw	s1,-42(s1) # 80009020 <ticks>
  release(&tickslock);
    80003052:	00015517          	auipc	a0,0x15
    80003056:	91650513          	addi	a0,a0,-1770 # 80017968 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c6a080e7          	jalr	-918(ra) # 80000cc4 <release>
  return xticks;
}
    80003062:	02049513          	slli	a0,s1,0x20
    80003066:	9101                	srli	a0,a0,0x20
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003072:	7179                	addi	sp,sp,-48
    80003074:	f406                	sd	ra,40(sp)
    80003076:	f022                	sd	s0,32(sp)
    80003078:	ec26                	sd	s1,24(sp)
    8000307a:	e84a                	sd	s2,16(sp)
    8000307c:	e44e                	sd	s3,8(sp)
    8000307e:	e052                	sd	s4,0(sp)
    80003080:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003082:	00005597          	auipc	a1,0x5
    80003086:	50658593          	addi	a1,a1,1286 # 80008588 <syscalls+0xb0>
    8000308a:	00015517          	auipc	a0,0x15
    8000308e:	8f650513          	addi	a0,a0,-1802 # 80017980 <bcache>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	aee080e7          	jalr	-1298(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000309a:	0001d797          	auipc	a5,0x1d
    8000309e:	8e678793          	addi	a5,a5,-1818 # 8001f980 <bcache+0x8000>
    800030a2:	0001d717          	auipc	a4,0x1d
    800030a6:	b4670713          	addi	a4,a4,-1210 # 8001fbe8 <bcache+0x8268>
    800030aa:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030ae:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b2:	00015497          	auipc	s1,0x15
    800030b6:	8e648493          	addi	s1,s1,-1818 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    800030ba:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030bc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030be:	00005a17          	auipc	s4,0x5
    800030c2:	4d2a0a13          	addi	s4,s4,1234 # 80008590 <syscalls+0xb8>
    b->next = bcache.head.next;
    800030c6:	2b893783          	ld	a5,696(s2)
    800030ca:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030cc:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030d0:	85d2                	mv	a1,s4
    800030d2:	01048513          	addi	a0,s1,16
    800030d6:	00001097          	auipc	ra,0x1
    800030da:	4ac080e7          	jalr	1196(ra) # 80004582 <initsleeplock>
    bcache.head.next->prev = b;
    800030de:	2b893783          	ld	a5,696(s2)
    800030e2:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030e4:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030e8:	45848493          	addi	s1,s1,1112
    800030ec:	fd349de3          	bne	s1,s3,800030c6 <binit+0x54>
  }
}
    800030f0:	70a2                	ld	ra,40(sp)
    800030f2:	7402                	ld	s0,32(sp)
    800030f4:	64e2                	ld	s1,24(sp)
    800030f6:	6942                	ld	s2,16(sp)
    800030f8:	69a2                	ld	s3,8(sp)
    800030fa:	6a02                	ld	s4,0(sp)
    800030fc:	6145                	addi	sp,sp,48
    800030fe:	8082                	ret

0000000080003100 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003100:	7179                	addi	sp,sp,-48
    80003102:	f406                	sd	ra,40(sp)
    80003104:	f022                	sd	s0,32(sp)
    80003106:	ec26                	sd	s1,24(sp)
    80003108:	e84a                	sd	s2,16(sp)
    8000310a:	e44e                	sd	s3,8(sp)
    8000310c:	1800                	addi	s0,sp,48
    8000310e:	89aa                	mv	s3,a0
    80003110:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003112:	00015517          	auipc	a0,0x15
    80003116:	86e50513          	addi	a0,a0,-1938 # 80017980 <bcache>
    8000311a:	ffffe097          	auipc	ra,0xffffe
    8000311e:	af6080e7          	jalr	-1290(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003122:	0001d497          	auipc	s1,0x1d
    80003126:	b164b483          	ld	s1,-1258(s1) # 8001fc38 <bcache+0x82b8>
    8000312a:	0001d797          	auipc	a5,0x1d
    8000312e:	abe78793          	addi	a5,a5,-1346 # 8001fbe8 <bcache+0x8268>
    80003132:	02f48f63          	beq	s1,a5,80003170 <bread+0x70>
    80003136:	873e                	mv	a4,a5
    80003138:	a021                	j	80003140 <bread+0x40>
    8000313a:	68a4                	ld	s1,80(s1)
    8000313c:	02e48a63          	beq	s1,a4,80003170 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003140:	449c                	lw	a5,8(s1)
    80003142:	ff379ce3          	bne	a5,s3,8000313a <bread+0x3a>
    80003146:	44dc                	lw	a5,12(s1)
    80003148:	ff2799e3          	bne	a5,s2,8000313a <bread+0x3a>
      b->refcnt++;
    8000314c:	40bc                	lw	a5,64(s1)
    8000314e:	2785                	addiw	a5,a5,1
    80003150:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003152:	00015517          	auipc	a0,0x15
    80003156:	82e50513          	addi	a0,a0,-2002 # 80017980 <bcache>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	b6a080e7          	jalr	-1174(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80003162:	01048513          	addi	a0,s1,16
    80003166:	00001097          	auipc	ra,0x1
    8000316a:	456080e7          	jalr	1110(ra) # 800045bc <acquiresleep>
      return b;
    8000316e:	a8b9                	j	800031cc <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003170:	0001d497          	auipc	s1,0x1d
    80003174:	ac04b483          	ld	s1,-1344(s1) # 8001fc30 <bcache+0x82b0>
    80003178:	0001d797          	auipc	a5,0x1d
    8000317c:	a7078793          	addi	a5,a5,-1424 # 8001fbe8 <bcache+0x8268>
    80003180:	00f48863          	beq	s1,a5,80003190 <bread+0x90>
    80003184:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003186:	40bc                	lw	a5,64(s1)
    80003188:	cf81                	beqz	a5,800031a0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000318a:	64a4                	ld	s1,72(s1)
    8000318c:	fee49de3          	bne	s1,a4,80003186 <bread+0x86>
  panic("bget: no buffers");
    80003190:	00005517          	auipc	a0,0x5
    80003194:	40850513          	addi	a0,a0,1032 # 80008598 <syscalls+0xc0>
    80003198:	ffffd097          	auipc	ra,0xffffd
    8000319c:	3b0080e7          	jalr	944(ra) # 80000548 <panic>
      b->dev = dev;
    800031a0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031a4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031a8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031ac:	4785                	li	a5,1
    800031ae:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b0:	00014517          	auipc	a0,0x14
    800031b4:	7d050513          	addi	a0,a0,2000 # 80017980 <bcache>
    800031b8:	ffffe097          	auipc	ra,0xffffe
    800031bc:	b0c080e7          	jalr	-1268(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    800031c0:	01048513          	addi	a0,s1,16
    800031c4:	00001097          	auipc	ra,0x1
    800031c8:	3f8080e7          	jalr	1016(ra) # 800045bc <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031cc:	409c                	lw	a5,0(s1)
    800031ce:	cb89                	beqz	a5,800031e0 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031d0:	8526                	mv	a0,s1
    800031d2:	70a2                	ld	ra,40(sp)
    800031d4:	7402                	ld	s0,32(sp)
    800031d6:	64e2                	ld	s1,24(sp)
    800031d8:	6942                	ld	s2,16(sp)
    800031da:	69a2                	ld	s3,8(sp)
    800031dc:	6145                	addi	sp,sp,48
    800031de:	8082                	ret
    virtio_disk_rw(b, 0);
    800031e0:	4581                	li	a1,0
    800031e2:	8526                	mv	a0,s1
    800031e4:	00003097          	auipc	ra,0x3
    800031e8:	f58080e7          	jalr	-168(ra) # 8000613c <virtio_disk_rw>
    b->valid = 1;
    800031ec:	4785                	li	a5,1
    800031ee:	c09c                	sw	a5,0(s1)
  return b;
    800031f0:	b7c5                	j	800031d0 <bread+0xd0>

00000000800031f2 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031f2:	1101                	addi	sp,sp,-32
    800031f4:	ec06                	sd	ra,24(sp)
    800031f6:	e822                	sd	s0,16(sp)
    800031f8:	e426                	sd	s1,8(sp)
    800031fa:	1000                	addi	s0,sp,32
    800031fc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031fe:	0541                	addi	a0,a0,16
    80003200:	00001097          	auipc	ra,0x1
    80003204:	456080e7          	jalr	1110(ra) # 80004656 <holdingsleep>
    80003208:	cd01                	beqz	a0,80003220 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000320a:	4585                	li	a1,1
    8000320c:	8526                	mv	a0,s1
    8000320e:	00003097          	auipc	ra,0x3
    80003212:	f2e080e7          	jalr	-210(ra) # 8000613c <virtio_disk_rw>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6105                	addi	sp,sp,32
    8000321e:	8082                	ret
    panic("bwrite");
    80003220:	00005517          	auipc	a0,0x5
    80003224:	39050513          	addi	a0,a0,912 # 800085b0 <syscalls+0xd8>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	320080e7          	jalr	800(ra) # 80000548 <panic>

0000000080003230 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003230:	1101                	addi	sp,sp,-32
    80003232:	ec06                	sd	ra,24(sp)
    80003234:	e822                	sd	s0,16(sp)
    80003236:	e426                	sd	s1,8(sp)
    80003238:	e04a                	sd	s2,0(sp)
    8000323a:	1000                	addi	s0,sp,32
    8000323c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000323e:	01050913          	addi	s2,a0,16
    80003242:	854a                	mv	a0,s2
    80003244:	00001097          	auipc	ra,0x1
    80003248:	412080e7          	jalr	1042(ra) # 80004656 <holdingsleep>
    8000324c:	c92d                	beqz	a0,800032be <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000324e:	854a                	mv	a0,s2
    80003250:	00001097          	auipc	ra,0x1
    80003254:	3c2080e7          	jalr	962(ra) # 80004612 <releasesleep>

  acquire(&bcache.lock);
    80003258:	00014517          	auipc	a0,0x14
    8000325c:	72850513          	addi	a0,a0,1832 # 80017980 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	9b0080e7          	jalr	-1616(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003268:	40bc                	lw	a5,64(s1)
    8000326a:	37fd                	addiw	a5,a5,-1
    8000326c:	0007871b          	sext.w	a4,a5
    80003270:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003272:	eb05                	bnez	a4,800032a2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003274:	68bc                	ld	a5,80(s1)
    80003276:	64b8                	ld	a4,72(s1)
    80003278:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000327a:	64bc                	ld	a5,72(s1)
    8000327c:	68b8                	ld	a4,80(s1)
    8000327e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003280:	0001c797          	auipc	a5,0x1c
    80003284:	70078793          	addi	a5,a5,1792 # 8001f980 <bcache+0x8000>
    80003288:	2b87b703          	ld	a4,696(a5)
    8000328c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000328e:	0001d717          	auipc	a4,0x1d
    80003292:	95a70713          	addi	a4,a4,-1702 # 8001fbe8 <bcache+0x8268>
    80003296:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003298:	2b87b703          	ld	a4,696(a5)
    8000329c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000329e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032a2:	00014517          	auipc	a0,0x14
    800032a6:	6de50513          	addi	a0,a0,1758 # 80017980 <bcache>
    800032aa:	ffffe097          	auipc	ra,0xffffe
    800032ae:	a1a080e7          	jalr	-1510(ra) # 80000cc4 <release>
}
    800032b2:	60e2                	ld	ra,24(sp)
    800032b4:	6442                	ld	s0,16(sp)
    800032b6:	64a2                	ld	s1,8(sp)
    800032b8:	6902                	ld	s2,0(sp)
    800032ba:	6105                	addi	sp,sp,32
    800032bc:	8082                	ret
    panic("brelse");
    800032be:	00005517          	auipc	a0,0x5
    800032c2:	2fa50513          	addi	a0,a0,762 # 800085b8 <syscalls+0xe0>
    800032c6:	ffffd097          	auipc	ra,0xffffd
    800032ca:	282080e7          	jalr	642(ra) # 80000548 <panic>

00000000800032ce <bpin>:

void
bpin(struct buf *b) {
    800032ce:	1101                	addi	sp,sp,-32
    800032d0:	ec06                	sd	ra,24(sp)
    800032d2:	e822                	sd	s0,16(sp)
    800032d4:	e426                	sd	s1,8(sp)
    800032d6:	1000                	addi	s0,sp,32
    800032d8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032da:	00014517          	auipc	a0,0x14
    800032de:	6a650513          	addi	a0,a0,1702 # 80017980 <bcache>
    800032e2:	ffffe097          	auipc	ra,0xffffe
    800032e6:	92e080e7          	jalr	-1746(ra) # 80000c10 <acquire>
  b->refcnt++;
    800032ea:	40bc                	lw	a5,64(s1)
    800032ec:	2785                	addiw	a5,a5,1
    800032ee:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f0:	00014517          	auipc	a0,0x14
    800032f4:	69050513          	addi	a0,a0,1680 # 80017980 <bcache>
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	9cc080e7          	jalr	-1588(ra) # 80000cc4 <release>
}
    80003300:	60e2                	ld	ra,24(sp)
    80003302:	6442                	ld	s0,16(sp)
    80003304:	64a2                	ld	s1,8(sp)
    80003306:	6105                	addi	sp,sp,32
    80003308:	8082                	ret

000000008000330a <bunpin>:

void
bunpin(struct buf *b) {
    8000330a:	1101                	addi	sp,sp,-32
    8000330c:	ec06                	sd	ra,24(sp)
    8000330e:	e822                	sd	s0,16(sp)
    80003310:	e426                	sd	s1,8(sp)
    80003312:	1000                	addi	s0,sp,32
    80003314:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003316:	00014517          	auipc	a0,0x14
    8000331a:	66a50513          	addi	a0,a0,1642 # 80017980 <bcache>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	8f2080e7          	jalr	-1806(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003326:	40bc                	lw	a5,64(s1)
    80003328:	37fd                	addiw	a5,a5,-1
    8000332a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000332c:	00014517          	auipc	a0,0x14
    80003330:	65450513          	addi	a0,a0,1620 # 80017980 <bcache>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	990080e7          	jalr	-1648(ra) # 80000cc4 <release>
}
    8000333c:	60e2                	ld	ra,24(sp)
    8000333e:	6442                	ld	s0,16(sp)
    80003340:	64a2                	ld	s1,8(sp)
    80003342:	6105                	addi	sp,sp,32
    80003344:	8082                	ret

0000000080003346 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003346:	1101                	addi	sp,sp,-32
    80003348:	ec06                	sd	ra,24(sp)
    8000334a:	e822                	sd	s0,16(sp)
    8000334c:	e426                	sd	s1,8(sp)
    8000334e:	e04a                	sd	s2,0(sp)
    80003350:	1000                	addi	s0,sp,32
    80003352:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003354:	00d5d59b          	srliw	a1,a1,0xd
    80003358:	0001d797          	auipc	a5,0x1d
    8000335c:	d047a783          	lw	a5,-764(a5) # 8002005c <sb+0x1c>
    80003360:	9dbd                	addw	a1,a1,a5
    80003362:	00000097          	auipc	ra,0x0
    80003366:	d9e080e7          	jalr	-610(ra) # 80003100 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000336a:	0074f713          	andi	a4,s1,7
    8000336e:	4785                	li	a5,1
    80003370:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003374:	14ce                	slli	s1,s1,0x33
    80003376:	90d9                	srli	s1,s1,0x36
    80003378:	00950733          	add	a4,a0,s1
    8000337c:	05874703          	lbu	a4,88(a4)
    80003380:	00e7f6b3          	and	a3,a5,a4
    80003384:	c69d                	beqz	a3,800033b2 <bfree+0x6c>
    80003386:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003388:	94aa                	add	s1,s1,a0
    8000338a:	fff7c793          	not	a5,a5
    8000338e:	8ff9                	and	a5,a5,a4
    80003390:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003394:	00001097          	auipc	ra,0x1
    80003398:	100080e7          	jalr	256(ra) # 80004494 <log_write>
  brelse(bp);
    8000339c:	854a                	mv	a0,s2
    8000339e:	00000097          	auipc	ra,0x0
    800033a2:	e92080e7          	jalr	-366(ra) # 80003230 <brelse>
}
    800033a6:	60e2                	ld	ra,24(sp)
    800033a8:	6442                	ld	s0,16(sp)
    800033aa:	64a2                	ld	s1,8(sp)
    800033ac:	6902                	ld	s2,0(sp)
    800033ae:	6105                	addi	sp,sp,32
    800033b0:	8082                	ret
    panic("freeing free block");
    800033b2:	00005517          	auipc	a0,0x5
    800033b6:	20e50513          	addi	a0,a0,526 # 800085c0 <syscalls+0xe8>
    800033ba:	ffffd097          	auipc	ra,0xffffd
    800033be:	18e080e7          	jalr	398(ra) # 80000548 <panic>

00000000800033c2 <balloc>:
{
    800033c2:	711d                	addi	sp,sp,-96
    800033c4:	ec86                	sd	ra,88(sp)
    800033c6:	e8a2                	sd	s0,80(sp)
    800033c8:	e4a6                	sd	s1,72(sp)
    800033ca:	e0ca                	sd	s2,64(sp)
    800033cc:	fc4e                	sd	s3,56(sp)
    800033ce:	f852                	sd	s4,48(sp)
    800033d0:	f456                	sd	s5,40(sp)
    800033d2:	f05a                	sd	s6,32(sp)
    800033d4:	ec5e                	sd	s7,24(sp)
    800033d6:	e862                	sd	s8,16(sp)
    800033d8:	e466                	sd	s9,8(sp)
    800033da:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033dc:	0001d797          	auipc	a5,0x1d
    800033e0:	c687a783          	lw	a5,-920(a5) # 80020044 <sb+0x4>
    800033e4:	cbd1                	beqz	a5,80003478 <balloc+0xb6>
    800033e6:	8baa                	mv	s7,a0
    800033e8:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033ea:	0001db17          	auipc	s6,0x1d
    800033ee:	c56b0b13          	addi	s6,s6,-938 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f2:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033f4:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033f6:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033f8:	6c89                	lui	s9,0x2
    800033fa:	a831                	j	80003416 <balloc+0x54>
    brelse(bp);
    800033fc:	854a                	mv	a0,s2
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e32080e7          	jalr	-462(ra) # 80003230 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003406:	015c87bb          	addw	a5,s9,s5
    8000340a:	00078a9b          	sext.w	s5,a5
    8000340e:	004b2703          	lw	a4,4(s6)
    80003412:	06eaf363          	bgeu	s5,a4,80003478 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003416:	41fad79b          	sraiw	a5,s5,0x1f
    8000341a:	0137d79b          	srliw	a5,a5,0x13
    8000341e:	015787bb          	addw	a5,a5,s5
    80003422:	40d7d79b          	sraiw	a5,a5,0xd
    80003426:	01cb2583          	lw	a1,28(s6)
    8000342a:	9dbd                	addw	a1,a1,a5
    8000342c:	855e                	mv	a0,s7
    8000342e:	00000097          	auipc	ra,0x0
    80003432:	cd2080e7          	jalr	-814(ra) # 80003100 <bread>
    80003436:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003438:	004b2503          	lw	a0,4(s6)
    8000343c:	000a849b          	sext.w	s1,s5
    80003440:	8662                	mv	a2,s8
    80003442:	faa4fde3          	bgeu	s1,a0,800033fc <balloc+0x3a>
      m = 1 << (bi % 8);
    80003446:	41f6579b          	sraiw	a5,a2,0x1f
    8000344a:	01d7d69b          	srliw	a3,a5,0x1d
    8000344e:	00c6873b          	addw	a4,a3,a2
    80003452:	00777793          	andi	a5,a4,7
    80003456:	9f95                	subw	a5,a5,a3
    80003458:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000345c:	4037571b          	sraiw	a4,a4,0x3
    80003460:	00e906b3          	add	a3,s2,a4
    80003464:	0586c683          	lbu	a3,88(a3)
    80003468:	00d7f5b3          	and	a1,a5,a3
    8000346c:	cd91                	beqz	a1,80003488 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	2605                	addiw	a2,a2,1
    80003470:	2485                	addiw	s1,s1,1
    80003472:	fd4618e3          	bne	a2,s4,80003442 <balloc+0x80>
    80003476:	b759                	j	800033fc <balloc+0x3a>
  panic("balloc: out of blocks");
    80003478:	00005517          	auipc	a0,0x5
    8000347c:	16050513          	addi	a0,a0,352 # 800085d8 <syscalls+0x100>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	0c8080e7          	jalr	200(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003488:	974a                	add	a4,a4,s2
    8000348a:	8fd5                	or	a5,a5,a3
    8000348c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003490:	854a                	mv	a0,s2
    80003492:	00001097          	auipc	ra,0x1
    80003496:	002080e7          	jalr	2(ra) # 80004494 <log_write>
        brelse(bp);
    8000349a:	854a                	mv	a0,s2
    8000349c:	00000097          	auipc	ra,0x0
    800034a0:	d94080e7          	jalr	-620(ra) # 80003230 <brelse>
  bp = bread(dev, bno);
    800034a4:	85a6                	mv	a1,s1
    800034a6:	855e                	mv	a0,s7
    800034a8:	00000097          	auipc	ra,0x0
    800034ac:	c58080e7          	jalr	-936(ra) # 80003100 <bread>
    800034b0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034b2:	40000613          	li	a2,1024
    800034b6:	4581                	li	a1,0
    800034b8:	05850513          	addi	a0,a0,88
    800034bc:	ffffe097          	auipc	ra,0xffffe
    800034c0:	850080e7          	jalr	-1968(ra) # 80000d0c <memset>
  log_write(bp);
    800034c4:	854a                	mv	a0,s2
    800034c6:	00001097          	auipc	ra,0x1
    800034ca:	fce080e7          	jalr	-50(ra) # 80004494 <log_write>
  brelse(bp);
    800034ce:	854a                	mv	a0,s2
    800034d0:	00000097          	auipc	ra,0x0
    800034d4:	d60080e7          	jalr	-672(ra) # 80003230 <brelse>
}
    800034d8:	8526                	mv	a0,s1
    800034da:	60e6                	ld	ra,88(sp)
    800034dc:	6446                	ld	s0,80(sp)
    800034de:	64a6                	ld	s1,72(sp)
    800034e0:	6906                	ld	s2,64(sp)
    800034e2:	79e2                	ld	s3,56(sp)
    800034e4:	7a42                	ld	s4,48(sp)
    800034e6:	7aa2                	ld	s5,40(sp)
    800034e8:	7b02                	ld	s6,32(sp)
    800034ea:	6be2                	ld	s7,24(sp)
    800034ec:	6c42                	ld	s8,16(sp)
    800034ee:	6ca2                	ld	s9,8(sp)
    800034f0:	6125                	addi	sp,sp,96
    800034f2:	8082                	ret

00000000800034f4 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034f4:	7179                	addi	sp,sp,-48
    800034f6:	f406                	sd	ra,40(sp)
    800034f8:	f022                	sd	s0,32(sp)
    800034fa:	ec26                	sd	s1,24(sp)
    800034fc:	e84a                	sd	s2,16(sp)
    800034fe:	e44e                	sd	s3,8(sp)
    80003500:	e052                	sd	s4,0(sp)
    80003502:	1800                	addi	s0,sp,48
    80003504:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003506:	47ad                	li	a5,11
    80003508:	04b7fe63          	bgeu	a5,a1,80003564 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000350c:	ff45849b          	addiw	s1,a1,-12
    80003510:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003514:	0ff00793          	li	a5,255
    80003518:	0ae7e363          	bltu	a5,a4,800035be <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000351c:	08052583          	lw	a1,128(a0)
    80003520:	c5ad                	beqz	a1,8000358a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003522:	00092503          	lw	a0,0(s2)
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	bda080e7          	jalr	-1062(ra) # 80003100 <bread>
    8000352e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003530:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003534:	02049593          	slli	a1,s1,0x20
    80003538:	9181                	srli	a1,a1,0x20
    8000353a:	058a                	slli	a1,a1,0x2
    8000353c:	00b784b3          	add	s1,a5,a1
    80003540:	0004a983          	lw	s3,0(s1)
    80003544:	04098d63          	beqz	s3,8000359e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003548:	8552                	mv	a0,s4
    8000354a:	00000097          	auipc	ra,0x0
    8000354e:	ce6080e7          	jalr	-794(ra) # 80003230 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003552:	854e                	mv	a0,s3
    80003554:	70a2                	ld	ra,40(sp)
    80003556:	7402                	ld	s0,32(sp)
    80003558:	64e2                	ld	s1,24(sp)
    8000355a:	6942                	ld	s2,16(sp)
    8000355c:	69a2                	ld	s3,8(sp)
    8000355e:	6a02                	ld	s4,0(sp)
    80003560:	6145                	addi	sp,sp,48
    80003562:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003564:	02059493          	slli	s1,a1,0x20
    80003568:	9081                	srli	s1,s1,0x20
    8000356a:	048a                	slli	s1,s1,0x2
    8000356c:	94aa                	add	s1,s1,a0
    8000356e:	0504a983          	lw	s3,80(s1)
    80003572:	fe0990e3          	bnez	s3,80003552 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003576:	4108                	lw	a0,0(a0)
    80003578:	00000097          	auipc	ra,0x0
    8000357c:	e4a080e7          	jalr	-438(ra) # 800033c2 <balloc>
    80003580:	0005099b          	sext.w	s3,a0
    80003584:	0534a823          	sw	s3,80(s1)
    80003588:	b7e9                	j	80003552 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000358a:	4108                	lw	a0,0(a0)
    8000358c:	00000097          	auipc	ra,0x0
    80003590:	e36080e7          	jalr	-458(ra) # 800033c2 <balloc>
    80003594:	0005059b          	sext.w	a1,a0
    80003598:	08b92023          	sw	a1,128(s2)
    8000359c:	b759                	j	80003522 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000359e:	00092503          	lw	a0,0(s2)
    800035a2:	00000097          	auipc	ra,0x0
    800035a6:	e20080e7          	jalr	-480(ra) # 800033c2 <balloc>
    800035aa:	0005099b          	sext.w	s3,a0
    800035ae:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800035b2:	8552                	mv	a0,s4
    800035b4:	00001097          	auipc	ra,0x1
    800035b8:	ee0080e7          	jalr	-288(ra) # 80004494 <log_write>
    800035bc:	b771                	j	80003548 <bmap+0x54>
  panic("bmap: out of range");
    800035be:	00005517          	auipc	a0,0x5
    800035c2:	03250513          	addi	a0,a0,50 # 800085f0 <syscalls+0x118>
    800035c6:	ffffd097          	auipc	ra,0xffffd
    800035ca:	f82080e7          	jalr	-126(ra) # 80000548 <panic>

00000000800035ce <iget>:
{
    800035ce:	7179                	addi	sp,sp,-48
    800035d0:	f406                	sd	ra,40(sp)
    800035d2:	f022                	sd	s0,32(sp)
    800035d4:	ec26                	sd	s1,24(sp)
    800035d6:	e84a                	sd	s2,16(sp)
    800035d8:	e44e                	sd	s3,8(sp)
    800035da:	e052                	sd	s4,0(sp)
    800035dc:	1800                	addi	s0,sp,48
    800035de:	89aa                	mv	s3,a0
    800035e0:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035e2:	0001d517          	auipc	a0,0x1d
    800035e6:	a7e50513          	addi	a0,a0,-1410 # 80020060 <icache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	626080e7          	jalr	1574(ra) # 80000c10 <acquire>
  empty = 0;
    800035f2:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035f4:	0001d497          	auipc	s1,0x1d
    800035f8:	a8448493          	addi	s1,s1,-1404 # 80020078 <icache+0x18>
    800035fc:	0001e697          	auipc	a3,0x1e
    80003600:	50c68693          	addi	a3,a3,1292 # 80021b08 <log>
    80003604:	a039                	j	80003612 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003606:	02090b63          	beqz	s2,8000363c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000360a:	08848493          	addi	s1,s1,136
    8000360e:	02d48a63          	beq	s1,a3,80003642 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003612:	449c                	lw	a5,8(s1)
    80003614:	fef059e3          	blez	a5,80003606 <iget+0x38>
    80003618:	4098                	lw	a4,0(s1)
    8000361a:	ff3716e3          	bne	a4,s3,80003606 <iget+0x38>
    8000361e:	40d8                	lw	a4,4(s1)
    80003620:	ff4713e3          	bne	a4,s4,80003606 <iget+0x38>
      ip->ref++;
    80003624:	2785                	addiw	a5,a5,1
    80003626:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003628:	0001d517          	auipc	a0,0x1d
    8000362c:	a3850513          	addi	a0,a0,-1480 # 80020060 <icache>
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	694080e7          	jalr	1684(ra) # 80000cc4 <release>
      return ip;
    80003638:	8926                	mv	s2,s1
    8000363a:	a03d                	j	80003668 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000363c:	f7f9                	bnez	a5,8000360a <iget+0x3c>
    8000363e:	8926                	mv	s2,s1
    80003640:	b7e9                	j	8000360a <iget+0x3c>
  if(empty == 0)
    80003642:	02090c63          	beqz	s2,8000367a <iget+0xac>
  ip->dev = dev;
    80003646:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000364a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000364e:	4785                	li	a5,1
    80003650:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003654:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003658:	0001d517          	auipc	a0,0x1d
    8000365c:	a0850513          	addi	a0,a0,-1528 # 80020060 <icache>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	664080e7          	jalr	1636(ra) # 80000cc4 <release>
}
    80003668:	854a                	mv	a0,s2
    8000366a:	70a2                	ld	ra,40(sp)
    8000366c:	7402                	ld	s0,32(sp)
    8000366e:	64e2                	ld	s1,24(sp)
    80003670:	6942                	ld	s2,16(sp)
    80003672:	69a2                	ld	s3,8(sp)
    80003674:	6a02                	ld	s4,0(sp)
    80003676:	6145                	addi	sp,sp,48
    80003678:	8082                	ret
    panic("iget: no inodes");
    8000367a:	00005517          	auipc	a0,0x5
    8000367e:	f8e50513          	addi	a0,a0,-114 # 80008608 <syscalls+0x130>
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	ec6080e7          	jalr	-314(ra) # 80000548 <panic>

000000008000368a <fsinit>:
fsinit(int dev) {
    8000368a:	7179                	addi	sp,sp,-48
    8000368c:	f406                	sd	ra,40(sp)
    8000368e:	f022                	sd	s0,32(sp)
    80003690:	ec26                	sd	s1,24(sp)
    80003692:	e84a                	sd	s2,16(sp)
    80003694:	e44e                	sd	s3,8(sp)
    80003696:	1800                	addi	s0,sp,48
    80003698:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000369a:	4585                	li	a1,1
    8000369c:	00000097          	auipc	ra,0x0
    800036a0:	a64080e7          	jalr	-1436(ra) # 80003100 <bread>
    800036a4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036a6:	0001d997          	auipc	s3,0x1d
    800036aa:	99a98993          	addi	s3,s3,-1638 # 80020040 <sb>
    800036ae:	02000613          	li	a2,32
    800036b2:	05850593          	addi	a1,a0,88
    800036b6:	854e                	mv	a0,s3
    800036b8:	ffffd097          	auipc	ra,0xffffd
    800036bc:	6b4080e7          	jalr	1716(ra) # 80000d6c <memmove>
  brelse(bp);
    800036c0:	8526                	mv	a0,s1
    800036c2:	00000097          	auipc	ra,0x0
    800036c6:	b6e080e7          	jalr	-1170(ra) # 80003230 <brelse>
  if(sb.magic != FSMAGIC)
    800036ca:	0009a703          	lw	a4,0(s3)
    800036ce:	102037b7          	lui	a5,0x10203
    800036d2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036d6:	02f71263          	bne	a4,a5,800036fa <fsinit+0x70>
  initlog(dev, &sb);
    800036da:	0001d597          	auipc	a1,0x1d
    800036de:	96658593          	addi	a1,a1,-1690 # 80020040 <sb>
    800036e2:	854a                	mv	a0,s2
    800036e4:	00001097          	auipc	ra,0x1
    800036e8:	b38080e7          	jalr	-1224(ra) # 8000421c <initlog>
}
    800036ec:	70a2                	ld	ra,40(sp)
    800036ee:	7402                	ld	s0,32(sp)
    800036f0:	64e2                	ld	s1,24(sp)
    800036f2:	6942                	ld	s2,16(sp)
    800036f4:	69a2                	ld	s3,8(sp)
    800036f6:	6145                	addi	sp,sp,48
    800036f8:	8082                	ret
    panic("invalid file system");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	f1e50513          	addi	a0,a0,-226 # 80008618 <syscalls+0x140>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e46080e7          	jalr	-442(ra) # 80000548 <panic>

000000008000370a <iinit>:
{
    8000370a:	7179                	addi	sp,sp,-48
    8000370c:	f406                	sd	ra,40(sp)
    8000370e:	f022                	sd	s0,32(sp)
    80003710:	ec26                	sd	s1,24(sp)
    80003712:	e84a                	sd	s2,16(sp)
    80003714:	e44e                	sd	s3,8(sp)
    80003716:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003718:	00005597          	auipc	a1,0x5
    8000371c:	f1858593          	addi	a1,a1,-232 # 80008630 <syscalls+0x158>
    80003720:	0001d517          	auipc	a0,0x1d
    80003724:	94050513          	addi	a0,a0,-1728 # 80020060 <icache>
    80003728:	ffffd097          	auipc	ra,0xffffd
    8000372c:	458080e7          	jalr	1112(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003730:	0001d497          	auipc	s1,0x1d
    80003734:	95848493          	addi	s1,s1,-1704 # 80020088 <icache+0x28>
    80003738:	0001e997          	auipc	s3,0x1e
    8000373c:	3e098993          	addi	s3,s3,992 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003740:	00005917          	auipc	s2,0x5
    80003744:	ef890913          	addi	s2,s2,-264 # 80008638 <syscalls+0x160>
    80003748:	85ca                	mv	a1,s2
    8000374a:	8526                	mv	a0,s1
    8000374c:	00001097          	auipc	ra,0x1
    80003750:	e36080e7          	jalr	-458(ra) # 80004582 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003754:	08848493          	addi	s1,s1,136
    80003758:	ff3498e3          	bne	s1,s3,80003748 <iinit+0x3e>
}
    8000375c:	70a2                	ld	ra,40(sp)
    8000375e:	7402                	ld	s0,32(sp)
    80003760:	64e2                	ld	s1,24(sp)
    80003762:	6942                	ld	s2,16(sp)
    80003764:	69a2                	ld	s3,8(sp)
    80003766:	6145                	addi	sp,sp,48
    80003768:	8082                	ret

000000008000376a <ialloc>:
{
    8000376a:	715d                	addi	sp,sp,-80
    8000376c:	e486                	sd	ra,72(sp)
    8000376e:	e0a2                	sd	s0,64(sp)
    80003770:	fc26                	sd	s1,56(sp)
    80003772:	f84a                	sd	s2,48(sp)
    80003774:	f44e                	sd	s3,40(sp)
    80003776:	f052                	sd	s4,32(sp)
    80003778:	ec56                	sd	s5,24(sp)
    8000377a:	e85a                	sd	s6,16(sp)
    8000377c:	e45e                	sd	s7,8(sp)
    8000377e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003780:	0001d717          	auipc	a4,0x1d
    80003784:	8cc72703          	lw	a4,-1844(a4) # 8002004c <sb+0xc>
    80003788:	4785                	li	a5,1
    8000378a:	04e7fa63          	bgeu	a5,a4,800037de <ialloc+0x74>
    8000378e:	8aaa                	mv	s5,a0
    80003790:	8bae                	mv	s7,a1
    80003792:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003794:	0001da17          	auipc	s4,0x1d
    80003798:	8aca0a13          	addi	s4,s4,-1876 # 80020040 <sb>
    8000379c:	00048b1b          	sext.w	s6,s1
    800037a0:	0044d593          	srli	a1,s1,0x4
    800037a4:	018a2783          	lw	a5,24(s4)
    800037a8:	9dbd                	addw	a1,a1,a5
    800037aa:	8556                	mv	a0,s5
    800037ac:	00000097          	auipc	ra,0x0
    800037b0:	954080e7          	jalr	-1708(ra) # 80003100 <bread>
    800037b4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037b6:	05850993          	addi	s3,a0,88
    800037ba:	00f4f793          	andi	a5,s1,15
    800037be:	079a                	slli	a5,a5,0x6
    800037c0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037c2:	00099783          	lh	a5,0(s3)
    800037c6:	c785                	beqz	a5,800037ee <ialloc+0x84>
    brelse(bp);
    800037c8:	00000097          	auipc	ra,0x0
    800037cc:	a68080e7          	jalr	-1432(ra) # 80003230 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037d0:	0485                	addi	s1,s1,1
    800037d2:	00ca2703          	lw	a4,12(s4)
    800037d6:	0004879b          	sext.w	a5,s1
    800037da:	fce7e1e3          	bltu	a5,a4,8000379c <ialloc+0x32>
  panic("ialloc: no inodes");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	e6250513          	addi	a0,a0,-414 # 80008640 <syscalls+0x168>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d62080e7          	jalr	-670(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800037ee:	04000613          	li	a2,64
    800037f2:	4581                	li	a1,0
    800037f4:	854e                	mv	a0,s3
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	516080e7          	jalr	1302(ra) # 80000d0c <memset>
      dip->type = type;
    800037fe:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003802:	854a                	mv	a0,s2
    80003804:	00001097          	auipc	ra,0x1
    80003808:	c90080e7          	jalr	-880(ra) # 80004494 <log_write>
      brelse(bp);
    8000380c:	854a                	mv	a0,s2
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	a22080e7          	jalr	-1502(ra) # 80003230 <brelse>
      return iget(dev, inum);
    80003816:	85da                	mv	a1,s6
    80003818:	8556                	mv	a0,s5
    8000381a:	00000097          	auipc	ra,0x0
    8000381e:	db4080e7          	jalr	-588(ra) # 800035ce <iget>
}
    80003822:	60a6                	ld	ra,72(sp)
    80003824:	6406                	ld	s0,64(sp)
    80003826:	74e2                	ld	s1,56(sp)
    80003828:	7942                	ld	s2,48(sp)
    8000382a:	79a2                	ld	s3,40(sp)
    8000382c:	7a02                	ld	s4,32(sp)
    8000382e:	6ae2                	ld	s5,24(sp)
    80003830:	6b42                	ld	s6,16(sp)
    80003832:	6ba2                	ld	s7,8(sp)
    80003834:	6161                	addi	sp,sp,80
    80003836:	8082                	ret

0000000080003838 <iupdate>:
{
    80003838:	1101                	addi	sp,sp,-32
    8000383a:	ec06                	sd	ra,24(sp)
    8000383c:	e822                	sd	s0,16(sp)
    8000383e:	e426                	sd	s1,8(sp)
    80003840:	e04a                	sd	s2,0(sp)
    80003842:	1000                	addi	s0,sp,32
    80003844:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003846:	415c                	lw	a5,4(a0)
    80003848:	0047d79b          	srliw	a5,a5,0x4
    8000384c:	0001d597          	auipc	a1,0x1d
    80003850:	80c5a583          	lw	a1,-2036(a1) # 80020058 <sb+0x18>
    80003854:	9dbd                	addw	a1,a1,a5
    80003856:	4108                	lw	a0,0(a0)
    80003858:	00000097          	auipc	ra,0x0
    8000385c:	8a8080e7          	jalr	-1880(ra) # 80003100 <bread>
    80003860:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003862:	05850793          	addi	a5,a0,88
    80003866:	40c8                	lw	a0,4(s1)
    80003868:	893d                	andi	a0,a0,15
    8000386a:	051a                	slli	a0,a0,0x6
    8000386c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000386e:	04449703          	lh	a4,68(s1)
    80003872:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003876:	04649703          	lh	a4,70(s1)
    8000387a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000387e:	04849703          	lh	a4,72(s1)
    80003882:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003886:	04a49703          	lh	a4,74(s1)
    8000388a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000388e:	44f8                	lw	a4,76(s1)
    80003890:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003892:	03400613          	li	a2,52
    80003896:	05048593          	addi	a1,s1,80
    8000389a:	0531                	addi	a0,a0,12
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	4d0080e7          	jalr	1232(ra) # 80000d6c <memmove>
  log_write(bp);
    800038a4:	854a                	mv	a0,s2
    800038a6:	00001097          	auipc	ra,0x1
    800038aa:	bee080e7          	jalr	-1042(ra) # 80004494 <log_write>
  brelse(bp);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	980080e7          	jalr	-1664(ra) # 80003230 <brelse>
}
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6902                	ld	s2,0(sp)
    800038c0:	6105                	addi	sp,sp,32
    800038c2:	8082                	ret

00000000800038c4 <idup>:
{
    800038c4:	1101                	addi	sp,sp,-32
    800038c6:	ec06                	sd	ra,24(sp)
    800038c8:	e822                	sd	s0,16(sp)
    800038ca:	e426                	sd	s1,8(sp)
    800038cc:	1000                	addi	s0,sp,32
    800038ce:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038d0:	0001c517          	auipc	a0,0x1c
    800038d4:	79050513          	addi	a0,a0,1936 # 80020060 <icache>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	338080e7          	jalr	824(ra) # 80000c10 <acquire>
  ip->ref++;
    800038e0:	449c                	lw	a5,8(s1)
    800038e2:	2785                	addiw	a5,a5,1
    800038e4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038e6:	0001c517          	auipc	a0,0x1c
    800038ea:	77a50513          	addi	a0,a0,1914 # 80020060 <icache>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	3d6080e7          	jalr	982(ra) # 80000cc4 <release>
}
    800038f6:	8526                	mv	a0,s1
    800038f8:	60e2                	ld	ra,24(sp)
    800038fa:	6442                	ld	s0,16(sp)
    800038fc:	64a2                	ld	s1,8(sp)
    800038fe:	6105                	addi	sp,sp,32
    80003900:	8082                	ret

0000000080003902 <ilock>:
{
    80003902:	1101                	addi	sp,sp,-32
    80003904:	ec06                	sd	ra,24(sp)
    80003906:	e822                	sd	s0,16(sp)
    80003908:	e426                	sd	s1,8(sp)
    8000390a:	e04a                	sd	s2,0(sp)
    8000390c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000390e:	c115                	beqz	a0,80003932 <ilock+0x30>
    80003910:	84aa                	mv	s1,a0
    80003912:	451c                	lw	a5,8(a0)
    80003914:	00f05f63          	blez	a5,80003932 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003918:	0541                	addi	a0,a0,16
    8000391a:	00001097          	auipc	ra,0x1
    8000391e:	ca2080e7          	jalr	-862(ra) # 800045bc <acquiresleep>
  if(ip->valid == 0){
    80003922:	40bc                	lw	a5,64(s1)
    80003924:	cf99                	beqz	a5,80003942 <ilock+0x40>
}
    80003926:	60e2                	ld	ra,24(sp)
    80003928:	6442                	ld	s0,16(sp)
    8000392a:	64a2                	ld	s1,8(sp)
    8000392c:	6902                	ld	s2,0(sp)
    8000392e:	6105                	addi	sp,sp,32
    80003930:	8082                	ret
    panic("ilock");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	d2650513          	addi	a0,a0,-730 # 80008658 <syscalls+0x180>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c0e080e7          	jalr	-1010(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003942:	40dc                	lw	a5,4(s1)
    80003944:	0047d79b          	srliw	a5,a5,0x4
    80003948:	0001c597          	auipc	a1,0x1c
    8000394c:	7105a583          	lw	a1,1808(a1) # 80020058 <sb+0x18>
    80003950:	9dbd                	addw	a1,a1,a5
    80003952:	4088                	lw	a0,0(s1)
    80003954:	fffff097          	auipc	ra,0xfffff
    80003958:	7ac080e7          	jalr	1964(ra) # 80003100 <bread>
    8000395c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000395e:	05850593          	addi	a1,a0,88
    80003962:	40dc                	lw	a5,4(s1)
    80003964:	8bbd                	andi	a5,a5,15
    80003966:	079a                	slli	a5,a5,0x6
    80003968:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000396a:	00059783          	lh	a5,0(a1)
    8000396e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003972:	00259783          	lh	a5,2(a1)
    80003976:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000397a:	00459783          	lh	a5,4(a1)
    8000397e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003982:	00659783          	lh	a5,6(a1)
    80003986:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000398a:	459c                	lw	a5,8(a1)
    8000398c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000398e:	03400613          	li	a2,52
    80003992:	05b1                	addi	a1,a1,12
    80003994:	05048513          	addi	a0,s1,80
    80003998:	ffffd097          	auipc	ra,0xffffd
    8000399c:	3d4080e7          	jalr	980(ra) # 80000d6c <memmove>
    brelse(bp);
    800039a0:	854a                	mv	a0,s2
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	88e080e7          	jalr	-1906(ra) # 80003230 <brelse>
    ip->valid = 1;
    800039aa:	4785                	li	a5,1
    800039ac:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039ae:	04449783          	lh	a5,68(s1)
    800039b2:	fbb5                	bnez	a5,80003926 <ilock+0x24>
      panic("ilock: no type");
    800039b4:	00005517          	auipc	a0,0x5
    800039b8:	cac50513          	addi	a0,a0,-852 # 80008660 <syscalls+0x188>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	b8c080e7          	jalr	-1140(ra) # 80000548 <panic>

00000000800039c4 <iunlock>:
{
    800039c4:	1101                	addi	sp,sp,-32
    800039c6:	ec06                	sd	ra,24(sp)
    800039c8:	e822                	sd	s0,16(sp)
    800039ca:	e426                	sd	s1,8(sp)
    800039cc:	e04a                	sd	s2,0(sp)
    800039ce:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039d0:	c905                	beqz	a0,80003a00 <iunlock+0x3c>
    800039d2:	84aa                	mv	s1,a0
    800039d4:	01050913          	addi	s2,a0,16
    800039d8:	854a                	mv	a0,s2
    800039da:	00001097          	auipc	ra,0x1
    800039de:	c7c080e7          	jalr	-900(ra) # 80004656 <holdingsleep>
    800039e2:	cd19                	beqz	a0,80003a00 <iunlock+0x3c>
    800039e4:	449c                	lw	a5,8(s1)
    800039e6:	00f05d63          	blez	a5,80003a00 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039ea:	854a                	mv	a0,s2
    800039ec:	00001097          	auipc	ra,0x1
    800039f0:	c26080e7          	jalr	-986(ra) # 80004612 <releasesleep>
}
    800039f4:	60e2                	ld	ra,24(sp)
    800039f6:	6442                	ld	s0,16(sp)
    800039f8:	64a2                	ld	s1,8(sp)
    800039fa:	6902                	ld	s2,0(sp)
    800039fc:	6105                	addi	sp,sp,32
    800039fe:	8082                	ret
    panic("iunlock");
    80003a00:	00005517          	auipc	a0,0x5
    80003a04:	c7050513          	addi	a0,a0,-912 # 80008670 <syscalls+0x198>
    80003a08:	ffffd097          	auipc	ra,0xffffd
    80003a0c:	b40080e7          	jalr	-1216(ra) # 80000548 <panic>

0000000080003a10 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a10:	7179                	addi	sp,sp,-48
    80003a12:	f406                	sd	ra,40(sp)
    80003a14:	f022                	sd	s0,32(sp)
    80003a16:	ec26                	sd	s1,24(sp)
    80003a18:	e84a                	sd	s2,16(sp)
    80003a1a:	e44e                	sd	s3,8(sp)
    80003a1c:	e052                	sd	s4,0(sp)
    80003a1e:	1800                	addi	s0,sp,48
    80003a20:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a22:	05050493          	addi	s1,a0,80
    80003a26:	08050913          	addi	s2,a0,128
    80003a2a:	a021                	j	80003a32 <itrunc+0x22>
    80003a2c:	0491                	addi	s1,s1,4
    80003a2e:	01248d63          	beq	s1,s2,80003a48 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a32:	408c                	lw	a1,0(s1)
    80003a34:	dde5                	beqz	a1,80003a2c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a36:	0009a503          	lw	a0,0(s3)
    80003a3a:	00000097          	auipc	ra,0x0
    80003a3e:	90c080e7          	jalr	-1780(ra) # 80003346 <bfree>
      ip->addrs[i] = 0;
    80003a42:	0004a023          	sw	zero,0(s1)
    80003a46:	b7dd                	j	80003a2c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a48:	0809a583          	lw	a1,128(s3)
    80003a4c:	e185                	bnez	a1,80003a6c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a4e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a52:	854e                	mv	a0,s3
    80003a54:	00000097          	auipc	ra,0x0
    80003a58:	de4080e7          	jalr	-540(ra) # 80003838 <iupdate>
}
    80003a5c:	70a2                	ld	ra,40(sp)
    80003a5e:	7402                	ld	s0,32(sp)
    80003a60:	64e2                	ld	s1,24(sp)
    80003a62:	6942                	ld	s2,16(sp)
    80003a64:	69a2                	ld	s3,8(sp)
    80003a66:	6a02                	ld	s4,0(sp)
    80003a68:	6145                	addi	sp,sp,48
    80003a6a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a6c:	0009a503          	lw	a0,0(s3)
    80003a70:	fffff097          	auipc	ra,0xfffff
    80003a74:	690080e7          	jalr	1680(ra) # 80003100 <bread>
    80003a78:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a7a:	05850493          	addi	s1,a0,88
    80003a7e:	45850913          	addi	s2,a0,1112
    80003a82:	a811                	j	80003a96 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a84:	0009a503          	lw	a0,0(s3)
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	8be080e7          	jalr	-1858(ra) # 80003346 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a90:	0491                	addi	s1,s1,4
    80003a92:	01248563          	beq	s1,s2,80003a9c <itrunc+0x8c>
      if(a[j])
    80003a96:	408c                	lw	a1,0(s1)
    80003a98:	dde5                	beqz	a1,80003a90 <itrunc+0x80>
    80003a9a:	b7ed                	j	80003a84 <itrunc+0x74>
    brelse(bp);
    80003a9c:	8552                	mv	a0,s4
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	792080e7          	jalr	1938(ra) # 80003230 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003aa6:	0809a583          	lw	a1,128(s3)
    80003aaa:	0009a503          	lw	a0,0(s3)
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	898080e7          	jalr	-1896(ra) # 80003346 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ab6:	0809a023          	sw	zero,128(s3)
    80003aba:	bf51                	j	80003a4e <itrunc+0x3e>

0000000080003abc <iput>:
{
    80003abc:	1101                	addi	sp,sp,-32
    80003abe:	ec06                	sd	ra,24(sp)
    80003ac0:	e822                	sd	s0,16(sp)
    80003ac2:	e426                	sd	s1,8(sp)
    80003ac4:	e04a                	sd	s2,0(sp)
    80003ac6:	1000                	addi	s0,sp,32
    80003ac8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003aca:	0001c517          	auipc	a0,0x1c
    80003ace:	59650513          	addi	a0,a0,1430 # 80020060 <icache>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	13e080e7          	jalr	318(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ada:	4498                	lw	a4,8(s1)
    80003adc:	4785                	li	a5,1
    80003ade:	02f70363          	beq	a4,a5,80003b04 <iput+0x48>
  ip->ref--;
    80003ae2:	449c                	lw	a5,8(s1)
    80003ae4:	37fd                	addiw	a5,a5,-1
    80003ae6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003ae8:	0001c517          	auipc	a0,0x1c
    80003aec:	57850513          	addi	a0,a0,1400 # 80020060 <icache>
    80003af0:	ffffd097          	auipc	ra,0xffffd
    80003af4:	1d4080e7          	jalr	468(ra) # 80000cc4 <release>
}
    80003af8:	60e2                	ld	ra,24(sp)
    80003afa:	6442                	ld	s0,16(sp)
    80003afc:	64a2                	ld	s1,8(sp)
    80003afe:	6902                	ld	s2,0(sp)
    80003b00:	6105                	addi	sp,sp,32
    80003b02:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b04:	40bc                	lw	a5,64(s1)
    80003b06:	dff1                	beqz	a5,80003ae2 <iput+0x26>
    80003b08:	04a49783          	lh	a5,74(s1)
    80003b0c:	fbf9                	bnez	a5,80003ae2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b0e:	01048913          	addi	s2,s1,16
    80003b12:	854a                	mv	a0,s2
    80003b14:	00001097          	auipc	ra,0x1
    80003b18:	aa8080e7          	jalr	-1368(ra) # 800045bc <acquiresleep>
    release(&icache.lock);
    80003b1c:	0001c517          	auipc	a0,0x1c
    80003b20:	54450513          	addi	a0,a0,1348 # 80020060 <icache>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	1a0080e7          	jalr	416(ra) # 80000cc4 <release>
    itrunc(ip);
    80003b2c:	8526                	mv	a0,s1
    80003b2e:	00000097          	auipc	ra,0x0
    80003b32:	ee2080e7          	jalr	-286(ra) # 80003a10 <itrunc>
    ip->type = 0;
    80003b36:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b3a:	8526                	mv	a0,s1
    80003b3c:	00000097          	auipc	ra,0x0
    80003b40:	cfc080e7          	jalr	-772(ra) # 80003838 <iupdate>
    ip->valid = 0;
    80003b44:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b48:	854a                	mv	a0,s2
    80003b4a:	00001097          	auipc	ra,0x1
    80003b4e:	ac8080e7          	jalr	-1336(ra) # 80004612 <releasesleep>
    acquire(&icache.lock);
    80003b52:	0001c517          	auipc	a0,0x1c
    80003b56:	50e50513          	addi	a0,a0,1294 # 80020060 <icache>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	0b6080e7          	jalr	182(ra) # 80000c10 <acquire>
    80003b62:	b741                	j	80003ae2 <iput+0x26>

0000000080003b64 <iunlockput>:
{
    80003b64:	1101                	addi	sp,sp,-32
    80003b66:	ec06                	sd	ra,24(sp)
    80003b68:	e822                	sd	s0,16(sp)
    80003b6a:	e426                	sd	s1,8(sp)
    80003b6c:	1000                	addi	s0,sp,32
    80003b6e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b70:	00000097          	auipc	ra,0x0
    80003b74:	e54080e7          	jalr	-428(ra) # 800039c4 <iunlock>
  iput(ip);
    80003b78:	8526                	mv	a0,s1
    80003b7a:	00000097          	auipc	ra,0x0
    80003b7e:	f42080e7          	jalr	-190(ra) # 80003abc <iput>
}
    80003b82:	60e2                	ld	ra,24(sp)
    80003b84:	6442                	ld	s0,16(sp)
    80003b86:	64a2                	ld	s1,8(sp)
    80003b88:	6105                	addi	sp,sp,32
    80003b8a:	8082                	ret

0000000080003b8c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b8c:	1141                	addi	sp,sp,-16
    80003b8e:	e422                	sd	s0,8(sp)
    80003b90:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b92:	411c                	lw	a5,0(a0)
    80003b94:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b96:	415c                	lw	a5,4(a0)
    80003b98:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b9a:	04451783          	lh	a5,68(a0)
    80003b9e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ba2:	04a51783          	lh	a5,74(a0)
    80003ba6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003baa:	04c56783          	lwu	a5,76(a0)
    80003bae:	e99c                	sd	a5,16(a1)
}
    80003bb0:	6422                	ld	s0,8(sp)
    80003bb2:	0141                	addi	sp,sp,16
    80003bb4:	8082                	ret

0000000080003bb6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bb6:	457c                	lw	a5,76(a0)
    80003bb8:	0ed7e863          	bltu	a5,a3,80003ca8 <readi+0xf2>
{
    80003bbc:	7159                	addi	sp,sp,-112
    80003bbe:	f486                	sd	ra,104(sp)
    80003bc0:	f0a2                	sd	s0,96(sp)
    80003bc2:	eca6                	sd	s1,88(sp)
    80003bc4:	e8ca                	sd	s2,80(sp)
    80003bc6:	e4ce                	sd	s3,72(sp)
    80003bc8:	e0d2                	sd	s4,64(sp)
    80003bca:	fc56                	sd	s5,56(sp)
    80003bcc:	f85a                	sd	s6,48(sp)
    80003bce:	f45e                	sd	s7,40(sp)
    80003bd0:	f062                	sd	s8,32(sp)
    80003bd2:	ec66                	sd	s9,24(sp)
    80003bd4:	e86a                	sd	s10,16(sp)
    80003bd6:	e46e                	sd	s11,8(sp)
    80003bd8:	1880                	addi	s0,sp,112
    80003bda:	8baa                	mv	s7,a0
    80003bdc:	8c2e                	mv	s8,a1
    80003bde:	8ab2                	mv	s5,a2
    80003be0:	84b6                	mv	s1,a3
    80003be2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003be4:	9f35                	addw	a4,a4,a3
    return 0;
    80003be6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003be8:	08d76f63          	bltu	a4,a3,80003c86 <readi+0xd0>
  if(off + n > ip->size)
    80003bec:	00e7f463          	bgeu	a5,a4,80003bf4 <readi+0x3e>
    n = ip->size - off;
    80003bf0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bf4:	0a0b0863          	beqz	s6,80003ca4 <readi+0xee>
    80003bf8:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bfa:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bfe:	5cfd                	li	s9,-1
    80003c00:	a82d                	j	80003c3a <readi+0x84>
    80003c02:	020a1d93          	slli	s11,s4,0x20
    80003c06:	020ddd93          	srli	s11,s11,0x20
    80003c0a:	05890613          	addi	a2,s2,88
    80003c0e:	86ee                	mv	a3,s11
    80003c10:	963a                	add	a2,a2,a4
    80003c12:	85d6                	mv	a1,s5
    80003c14:	8562                	mv	a0,s8
    80003c16:	ffffe097          	auipc	ra,0xffffe
    80003c1a:	62c080e7          	jalr	1580(ra) # 80002242 <either_copyout>
    80003c1e:	05950d63          	beq	a0,s9,80003c78 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c22:	854a                	mv	a0,s2
    80003c24:	fffff097          	auipc	ra,0xfffff
    80003c28:	60c080e7          	jalr	1548(ra) # 80003230 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2c:	013a09bb          	addw	s3,s4,s3
    80003c30:	009a04bb          	addw	s1,s4,s1
    80003c34:	9aee                	add	s5,s5,s11
    80003c36:	0569f663          	bgeu	s3,s6,80003c82 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c3a:	000ba903          	lw	s2,0(s7)
    80003c3e:	00a4d59b          	srliw	a1,s1,0xa
    80003c42:	855e                	mv	a0,s7
    80003c44:	00000097          	auipc	ra,0x0
    80003c48:	8b0080e7          	jalr	-1872(ra) # 800034f4 <bmap>
    80003c4c:	0005059b          	sext.w	a1,a0
    80003c50:	854a                	mv	a0,s2
    80003c52:	fffff097          	auipc	ra,0xfffff
    80003c56:	4ae080e7          	jalr	1198(ra) # 80003100 <bread>
    80003c5a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c5c:	3ff4f713          	andi	a4,s1,1023
    80003c60:	40ed07bb          	subw	a5,s10,a4
    80003c64:	413b06bb          	subw	a3,s6,s3
    80003c68:	8a3e                	mv	s4,a5
    80003c6a:	2781                	sext.w	a5,a5
    80003c6c:	0006861b          	sext.w	a2,a3
    80003c70:	f8f679e3          	bgeu	a2,a5,80003c02 <readi+0x4c>
    80003c74:	8a36                	mv	s4,a3
    80003c76:	b771                	j	80003c02 <readi+0x4c>
      brelse(bp);
    80003c78:	854a                	mv	a0,s2
    80003c7a:	fffff097          	auipc	ra,0xfffff
    80003c7e:	5b6080e7          	jalr	1462(ra) # 80003230 <brelse>
  }
  return tot;
    80003c82:	0009851b          	sext.w	a0,s3
}
    80003c86:	70a6                	ld	ra,104(sp)
    80003c88:	7406                	ld	s0,96(sp)
    80003c8a:	64e6                	ld	s1,88(sp)
    80003c8c:	6946                	ld	s2,80(sp)
    80003c8e:	69a6                	ld	s3,72(sp)
    80003c90:	6a06                	ld	s4,64(sp)
    80003c92:	7ae2                	ld	s5,56(sp)
    80003c94:	7b42                	ld	s6,48(sp)
    80003c96:	7ba2                	ld	s7,40(sp)
    80003c98:	7c02                	ld	s8,32(sp)
    80003c9a:	6ce2                	ld	s9,24(sp)
    80003c9c:	6d42                	ld	s10,16(sp)
    80003c9e:	6da2                	ld	s11,8(sp)
    80003ca0:	6165                	addi	sp,sp,112
    80003ca2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca4:	89da                	mv	s3,s6
    80003ca6:	bff1                	j	80003c82 <readi+0xcc>
    return 0;
    80003ca8:	4501                	li	a0,0
}
    80003caa:	8082                	ret

0000000080003cac <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cac:	457c                	lw	a5,76(a0)
    80003cae:	10d7e663          	bltu	a5,a3,80003dba <writei+0x10e>
{
    80003cb2:	7159                	addi	sp,sp,-112
    80003cb4:	f486                	sd	ra,104(sp)
    80003cb6:	f0a2                	sd	s0,96(sp)
    80003cb8:	eca6                	sd	s1,88(sp)
    80003cba:	e8ca                	sd	s2,80(sp)
    80003cbc:	e4ce                	sd	s3,72(sp)
    80003cbe:	e0d2                	sd	s4,64(sp)
    80003cc0:	fc56                	sd	s5,56(sp)
    80003cc2:	f85a                	sd	s6,48(sp)
    80003cc4:	f45e                	sd	s7,40(sp)
    80003cc6:	f062                	sd	s8,32(sp)
    80003cc8:	ec66                	sd	s9,24(sp)
    80003cca:	e86a                	sd	s10,16(sp)
    80003ccc:	e46e                	sd	s11,8(sp)
    80003cce:	1880                	addi	s0,sp,112
    80003cd0:	8baa                	mv	s7,a0
    80003cd2:	8c2e                	mv	s8,a1
    80003cd4:	8ab2                	mv	s5,a2
    80003cd6:	8936                	mv	s2,a3
    80003cd8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cda:	00e687bb          	addw	a5,a3,a4
    80003cde:	0ed7e063          	bltu	a5,a3,80003dbe <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ce2:	00043737          	lui	a4,0x43
    80003ce6:	0cf76e63          	bltu	a4,a5,80003dc2 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cea:	0a0b0763          	beqz	s6,80003d98 <writei+0xec>
    80003cee:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cf4:	5cfd                	li	s9,-1
    80003cf6:	a091                	j	80003d3a <writei+0x8e>
    80003cf8:	02099d93          	slli	s11,s3,0x20
    80003cfc:	020ddd93          	srli	s11,s11,0x20
    80003d00:	05848513          	addi	a0,s1,88
    80003d04:	86ee                	mv	a3,s11
    80003d06:	8656                	mv	a2,s5
    80003d08:	85e2                	mv	a1,s8
    80003d0a:	953a                	add	a0,a0,a4
    80003d0c:	ffffe097          	auipc	ra,0xffffe
    80003d10:	58c080e7          	jalr	1420(ra) # 80002298 <either_copyin>
    80003d14:	07950263          	beq	a0,s9,80003d78 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d18:	8526                	mv	a0,s1
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	77a080e7          	jalr	1914(ra) # 80004494 <log_write>
    brelse(bp);
    80003d22:	8526                	mv	a0,s1
    80003d24:	fffff097          	auipc	ra,0xfffff
    80003d28:	50c080e7          	jalr	1292(ra) # 80003230 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d2c:	01498a3b          	addw	s4,s3,s4
    80003d30:	0129893b          	addw	s2,s3,s2
    80003d34:	9aee                	add	s5,s5,s11
    80003d36:	056a7663          	bgeu	s4,s6,80003d82 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d3a:	000ba483          	lw	s1,0(s7)
    80003d3e:	00a9559b          	srliw	a1,s2,0xa
    80003d42:	855e                	mv	a0,s7
    80003d44:	fffff097          	auipc	ra,0xfffff
    80003d48:	7b0080e7          	jalr	1968(ra) # 800034f4 <bmap>
    80003d4c:	0005059b          	sext.w	a1,a0
    80003d50:	8526                	mv	a0,s1
    80003d52:	fffff097          	auipc	ra,0xfffff
    80003d56:	3ae080e7          	jalr	942(ra) # 80003100 <bread>
    80003d5a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d5c:	3ff97713          	andi	a4,s2,1023
    80003d60:	40ed07bb          	subw	a5,s10,a4
    80003d64:	414b06bb          	subw	a3,s6,s4
    80003d68:	89be                	mv	s3,a5
    80003d6a:	2781                	sext.w	a5,a5
    80003d6c:	0006861b          	sext.w	a2,a3
    80003d70:	f8f674e3          	bgeu	a2,a5,80003cf8 <writei+0x4c>
    80003d74:	89b6                	mv	s3,a3
    80003d76:	b749                	j	80003cf8 <writei+0x4c>
      brelse(bp);
    80003d78:	8526                	mv	a0,s1
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	4b6080e7          	jalr	1206(ra) # 80003230 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d82:	04cba783          	lw	a5,76(s7)
    80003d86:	0127f463          	bgeu	a5,s2,80003d8e <writei+0xe2>
      ip->size = off;
    80003d8a:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d8e:	855e                	mv	a0,s7
    80003d90:	00000097          	auipc	ra,0x0
    80003d94:	aa8080e7          	jalr	-1368(ra) # 80003838 <iupdate>
  }

  return n;
    80003d98:	000b051b          	sext.w	a0,s6
}
    80003d9c:	70a6                	ld	ra,104(sp)
    80003d9e:	7406                	ld	s0,96(sp)
    80003da0:	64e6                	ld	s1,88(sp)
    80003da2:	6946                	ld	s2,80(sp)
    80003da4:	69a6                	ld	s3,72(sp)
    80003da6:	6a06                	ld	s4,64(sp)
    80003da8:	7ae2                	ld	s5,56(sp)
    80003daa:	7b42                	ld	s6,48(sp)
    80003dac:	7ba2                	ld	s7,40(sp)
    80003dae:	7c02                	ld	s8,32(sp)
    80003db0:	6ce2                	ld	s9,24(sp)
    80003db2:	6d42                	ld	s10,16(sp)
    80003db4:	6da2                	ld	s11,8(sp)
    80003db6:	6165                	addi	sp,sp,112
    80003db8:	8082                	ret
    return -1;
    80003dba:	557d                	li	a0,-1
}
    80003dbc:	8082                	ret
    return -1;
    80003dbe:	557d                	li	a0,-1
    80003dc0:	bff1                	j	80003d9c <writei+0xf0>
    return -1;
    80003dc2:	557d                	li	a0,-1
    80003dc4:	bfe1                	j	80003d9c <writei+0xf0>

0000000080003dc6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dc6:	1141                	addi	sp,sp,-16
    80003dc8:	e406                	sd	ra,8(sp)
    80003dca:	e022                	sd	s0,0(sp)
    80003dcc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003dce:	4639                	li	a2,14
    80003dd0:	ffffd097          	auipc	ra,0xffffd
    80003dd4:	018080e7          	jalr	24(ra) # 80000de8 <strncmp>
}
    80003dd8:	60a2                	ld	ra,8(sp)
    80003dda:	6402                	ld	s0,0(sp)
    80003ddc:	0141                	addi	sp,sp,16
    80003dde:	8082                	ret

0000000080003de0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003de0:	7139                	addi	sp,sp,-64
    80003de2:	fc06                	sd	ra,56(sp)
    80003de4:	f822                	sd	s0,48(sp)
    80003de6:	f426                	sd	s1,40(sp)
    80003de8:	f04a                	sd	s2,32(sp)
    80003dea:	ec4e                	sd	s3,24(sp)
    80003dec:	e852                	sd	s4,16(sp)
    80003dee:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003df0:	04451703          	lh	a4,68(a0)
    80003df4:	4785                	li	a5,1
    80003df6:	00f71a63          	bne	a4,a5,80003e0a <dirlookup+0x2a>
    80003dfa:	892a                	mv	s2,a0
    80003dfc:	89ae                	mv	s3,a1
    80003dfe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e00:	457c                	lw	a5,76(a0)
    80003e02:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e04:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e06:	e79d                	bnez	a5,80003e34 <dirlookup+0x54>
    80003e08:	a8a5                	j	80003e80 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e0a:	00005517          	auipc	a0,0x5
    80003e0e:	86e50513          	addi	a0,a0,-1938 # 80008678 <syscalls+0x1a0>
    80003e12:	ffffc097          	auipc	ra,0xffffc
    80003e16:	736080e7          	jalr	1846(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003e1a:	00005517          	auipc	a0,0x5
    80003e1e:	87650513          	addi	a0,a0,-1930 # 80008690 <syscalls+0x1b8>
    80003e22:	ffffc097          	auipc	ra,0xffffc
    80003e26:	726080e7          	jalr	1830(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2a:	24c1                	addiw	s1,s1,16
    80003e2c:	04c92783          	lw	a5,76(s2)
    80003e30:	04f4f763          	bgeu	s1,a5,80003e7e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e34:	4741                	li	a4,16
    80003e36:	86a6                	mv	a3,s1
    80003e38:	fc040613          	addi	a2,s0,-64
    80003e3c:	4581                	li	a1,0
    80003e3e:	854a                	mv	a0,s2
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	d76080e7          	jalr	-650(ra) # 80003bb6 <readi>
    80003e48:	47c1                	li	a5,16
    80003e4a:	fcf518e3          	bne	a0,a5,80003e1a <dirlookup+0x3a>
    if(de.inum == 0)
    80003e4e:	fc045783          	lhu	a5,-64(s0)
    80003e52:	dfe1                	beqz	a5,80003e2a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e54:	fc240593          	addi	a1,s0,-62
    80003e58:	854e                	mv	a0,s3
    80003e5a:	00000097          	auipc	ra,0x0
    80003e5e:	f6c080e7          	jalr	-148(ra) # 80003dc6 <namecmp>
    80003e62:	f561                	bnez	a0,80003e2a <dirlookup+0x4a>
      if(poff)
    80003e64:	000a0463          	beqz	s4,80003e6c <dirlookup+0x8c>
        *poff = off;
    80003e68:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e6c:	fc045583          	lhu	a1,-64(s0)
    80003e70:	00092503          	lw	a0,0(s2)
    80003e74:	fffff097          	auipc	ra,0xfffff
    80003e78:	75a080e7          	jalr	1882(ra) # 800035ce <iget>
    80003e7c:	a011                	j	80003e80 <dirlookup+0xa0>
  return 0;
    80003e7e:	4501                	li	a0,0
}
    80003e80:	70e2                	ld	ra,56(sp)
    80003e82:	7442                	ld	s0,48(sp)
    80003e84:	74a2                	ld	s1,40(sp)
    80003e86:	7902                	ld	s2,32(sp)
    80003e88:	69e2                	ld	s3,24(sp)
    80003e8a:	6a42                	ld	s4,16(sp)
    80003e8c:	6121                	addi	sp,sp,64
    80003e8e:	8082                	ret

0000000080003e90 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e90:	711d                	addi	sp,sp,-96
    80003e92:	ec86                	sd	ra,88(sp)
    80003e94:	e8a2                	sd	s0,80(sp)
    80003e96:	e4a6                	sd	s1,72(sp)
    80003e98:	e0ca                	sd	s2,64(sp)
    80003e9a:	fc4e                	sd	s3,56(sp)
    80003e9c:	f852                	sd	s4,48(sp)
    80003e9e:	f456                	sd	s5,40(sp)
    80003ea0:	f05a                	sd	s6,32(sp)
    80003ea2:	ec5e                	sd	s7,24(sp)
    80003ea4:	e862                	sd	s8,16(sp)
    80003ea6:	e466                	sd	s9,8(sp)
    80003ea8:	1080                	addi	s0,sp,96
    80003eaa:	84aa                	mv	s1,a0
    80003eac:	8b2e                	mv	s6,a1
    80003eae:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003eb0:	00054703          	lbu	a4,0(a0)
    80003eb4:	02f00793          	li	a5,47
    80003eb8:	02f70363          	beq	a4,a5,80003ede <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ebc:	ffffe097          	auipc	ra,0xffffe
    80003ec0:	c5a080e7          	jalr	-934(ra) # 80001b16 <myproc>
    80003ec4:	15053503          	ld	a0,336(a0)
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	9fc080e7          	jalr	-1540(ra) # 800038c4 <idup>
    80003ed0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ed2:	02f00913          	li	s2,47
  len = path - s;
    80003ed6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ed8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eda:	4c05                	li	s8,1
    80003edc:	a865                	j	80003f94 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ede:	4585                	li	a1,1
    80003ee0:	4505                	li	a0,1
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	6ec080e7          	jalr	1772(ra) # 800035ce <iget>
    80003eea:	89aa                	mv	s3,a0
    80003eec:	b7dd                	j	80003ed2 <namex+0x42>
      iunlockput(ip);
    80003eee:	854e                	mv	a0,s3
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	c74080e7          	jalr	-908(ra) # 80003b64 <iunlockput>
      return 0;
    80003ef8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003efa:	854e                	mv	a0,s3
    80003efc:	60e6                	ld	ra,88(sp)
    80003efe:	6446                	ld	s0,80(sp)
    80003f00:	64a6                	ld	s1,72(sp)
    80003f02:	6906                	ld	s2,64(sp)
    80003f04:	79e2                	ld	s3,56(sp)
    80003f06:	7a42                	ld	s4,48(sp)
    80003f08:	7aa2                	ld	s5,40(sp)
    80003f0a:	7b02                	ld	s6,32(sp)
    80003f0c:	6be2                	ld	s7,24(sp)
    80003f0e:	6c42                	ld	s8,16(sp)
    80003f10:	6ca2                	ld	s9,8(sp)
    80003f12:	6125                	addi	sp,sp,96
    80003f14:	8082                	ret
      iunlock(ip);
    80003f16:	854e                	mv	a0,s3
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	aac080e7          	jalr	-1364(ra) # 800039c4 <iunlock>
      return ip;
    80003f20:	bfe9                	j	80003efa <namex+0x6a>
      iunlockput(ip);
    80003f22:	854e                	mv	a0,s3
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	c40080e7          	jalr	-960(ra) # 80003b64 <iunlockput>
      return 0;
    80003f2c:	89d2                	mv	s3,s4
    80003f2e:	b7f1                	j	80003efa <namex+0x6a>
  len = path - s;
    80003f30:	40b48633          	sub	a2,s1,a1
    80003f34:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f38:	094cd463          	bge	s9,s4,80003fc0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f3c:	4639                	li	a2,14
    80003f3e:	8556                	mv	a0,s5
    80003f40:	ffffd097          	auipc	ra,0xffffd
    80003f44:	e2c080e7          	jalr	-468(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003f48:	0004c783          	lbu	a5,0(s1)
    80003f4c:	01279763          	bne	a5,s2,80003f5a <namex+0xca>
    path++;
    80003f50:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f52:	0004c783          	lbu	a5,0(s1)
    80003f56:	ff278de3          	beq	a5,s2,80003f50 <namex+0xc0>
    ilock(ip);
    80003f5a:	854e                	mv	a0,s3
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	9a6080e7          	jalr	-1626(ra) # 80003902 <ilock>
    if(ip->type != T_DIR){
    80003f64:	04499783          	lh	a5,68(s3)
    80003f68:	f98793e3          	bne	a5,s8,80003eee <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f6c:	000b0563          	beqz	s6,80003f76 <namex+0xe6>
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	d3cd                	beqz	a5,80003f16 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f76:	865e                	mv	a2,s7
    80003f78:	85d6                	mv	a1,s5
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	e64080e7          	jalr	-412(ra) # 80003de0 <dirlookup>
    80003f84:	8a2a                	mv	s4,a0
    80003f86:	dd51                	beqz	a0,80003f22 <namex+0x92>
    iunlockput(ip);
    80003f88:	854e                	mv	a0,s3
    80003f8a:	00000097          	auipc	ra,0x0
    80003f8e:	bda080e7          	jalr	-1062(ra) # 80003b64 <iunlockput>
    ip = next;
    80003f92:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f94:	0004c783          	lbu	a5,0(s1)
    80003f98:	05279763          	bne	a5,s2,80003fe6 <namex+0x156>
    path++;
    80003f9c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f9e:	0004c783          	lbu	a5,0(s1)
    80003fa2:	ff278de3          	beq	a5,s2,80003f9c <namex+0x10c>
  if(*path == 0)
    80003fa6:	c79d                	beqz	a5,80003fd4 <namex+0x144>
    path++;
    80003fa8:	85a6                	mv	a1,s1
  len = path - s;
    80003faa:	8a5e                	mv	s4,s7
    80003fac:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fae:	01278963          	beq	a5,s2,80003fc0 <namex+0x130>
    80003fb2:	dfbd                	beqz	a5,80003f30 <namex+0xa0>
    path++;
    80003fb4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fb6:	0004c783          	lbu	a5,0(s1)
    80003fba:	ff279ce3          	bne	a5,s2,80003fb2 <namex+0x122>
    80003fbe:	bf8d                	j	80003f30 <namex+0xa0>
    memmove(name, s, len);
    80003fc0:	2601                	sext.w	a2,a2
    80003fc2:	8556                	mv	a0,s5
    80003fc4:	ffffd097          	auipc	ra,0xffffd
    80003fc8:	da8080e7          	jalr	-600(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003fcc:	9a56                	add	s4,s4,s5
    80003fce:	000a0023          	sb	zero,0(s4)
    80003fd2:	bf9d                	j	80003f48 <namex+0xb8>
  if(nameiparent){
    80003fd4:	f20b03e3          	beqz	s6,80003efa <namex+0x6a>
    iput(ip);
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	ae2080e7          	jalr	-1310(ra) # 80003abc <iput>
    return 0;
    80003fe2:	4981                	li	s3,0
    80003fe4:	bf19                	j	80003efa <namex+0x6a>
  if(*path == 0)
    80003fe6:	d7fd                	beqz	a5,80003fd4 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fe8:	0004c783          	lbu	a5,0(s1)
    80003fec:	85a6                	mv	a1,s1
    80003fee:	b7d1                	j	80003fb2 <namex+0x122>

0000000080003ff0 <dirlink>:
{
    80003ff0:	7139                	addi	sp,sp,-64
    80003ff2:	fc06                	sd	ra,56(sp)
    80003ff4:	f822                	sd	s0,48(sp)
    80003ff6:	f426                	sd	s1,40(sp)
    80003ff8:	f04a                	sd	s2,32(sp)
    80003ffa:	ec4e                	sd	s3,24(sp)
    80003ffc:	e852                	sd	s4,16(sp)
    80003ffe:	0080                	addi	s0,sp,64
    80004000:	892a                	mv	s2,a0
    80004002:	8a2e                	mv	s4,a1
    80004004:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004006:	4601                	li	a2,0
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	dd8080e7          	jalr	-552(ra) # 80003de0 <dirlookup>
    80004010:	e93d                	bnez	a0,80004086 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004012:	04c92483          	lw	s1,76(s2)
    80004016:	c49d                	beqz	s1,80004044 <dirlink+0x54>
    80004018:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000401a:	4741                	li	a4,16
    8000401c:	86a6                	mv	a3,s1
    8000401e:	fc040613          	addi	a2,s0,-64
    80004022:	4581                	li	a1,0
    80004024:	854a                	mv	a0,s2
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	b90080e7          	jalr	-1136(ra) # 80003bb6 <readi>
    8000402e:	47c1                	li	a5,16
    80004030:	06f51163          	bne	a0,a5,80004092 <dirlink+0xa2>
    if(de.inum == 0)
    80004034:	fc045783          	lhu	a5,-64(s0)
    80004038:	c791                	beqz	a5,80004044 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403a:	24c1                	addiw	s1,s1,16
    8000403c:	04c92783          	lw	a5,76(s2)
    80004040:	fcf4ede3          	bltu	s1,a5,8000401a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004044:	4639                	li	a2,14
    80004046:	85d2                	mv	a1,s4
    80004048:	fc240513          	addi	a0,s0,-62
    8000404c:	ffffd097          	auipc	ra,0xffffd
    80004050:	dd8080e7          	jalr	-552(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80004054:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004058:	4741                	li	a4,16
    8000405a:	86a6                	mv	a3,s1
    8000405c:	fc040613          	addi	a2,s0,-64
    80004060:	4581                	li	a1,0
    80004062:	854a                	mv	a0,s2
    80004064:	00000097          	auipc	ra,0x0
    80004068:	c48080e7          	jalr	-952(ra) # 80003cac <writei>
    8000406c:	872a                	mv	a4,a0
    8000406e:	47c1                	li	a5,16
  return 0;
    80004070:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004072:	02f71863          	bne	a4,a5,800040a2 <dirlink+0xb2>
}
    80004076:	70e2                	ld	ra,56(sp)
    80004078:	7442                	ld	s0,48(sp)
    8000407a:	74a2                	ld	s1,40(sp)
    8000407c:	7902                	ld	s2,32(sp)
    8000407e:	69e2                	ld	s3,24(sp)
    80004080:	6a42                	ld	s4,16(sp)
    80004082:	6121                	addi	sp,sp,64
    80004084:	8082                	ret
    iput(ip);
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	a36080e7          	jalr	-1482(ra) # 80003abc <iput>
    return -1;
    8000408e:	557d                	li	a0,-1
    80004090:	b7dd                	j	80004076 <dirlink+0x86>
      panic("dirlink read");
    80004092:	00004517          	auipc	a0,0x4
    80004096:	60e50513          	addi	a0,a0,1550 # 800086a0 <syscalls+0x1c8>
    8000409a:	ffffc097          	auipc	ra,0xffffc
    8000409e:	4ae080e7          	jalr	1198(ra) # 80000548 <panic>
    panic("dirlink");
    800040a2:	00004517          	auipc	a0,0x4
    800040a6:	71e50513          	addi	a0,a0,1822 # 800087c0 <syscalls+0x2e8>
    800040aa:	ffffc097          	auipc	ra,0xffffc
    800040ae:	49e080e7          	jalr	1182(ra) # 80000548 <panic>

00000000800040b2 <namei>:

struct inode*
namei(char *path)
{
    800040b2:	1101                	addi	sp,sp,-32
    800040b4:	ec06                	sd	ra,24(sp)
    800040b6:	e822                	sd	s0,16(sp)
    800040b8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040ba:	fe040613          	addi	a2,s0,-32
    800040be:	4581                	li	a1,0
    800040c0:	00000097          	auipc	ra,0x0
    800040c4:	dd0080e7          	jalr	-560(ra) # 80003e90 <namex>
}
    800040c8:	60e2                	ld	ra,24(sp)
    800040ca:	6442                	ld	s0,16(sp)
    800040cc:	6105                	addi	sp,sp,32
    800040ce:	8082                	ret

00000000800040d0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040d0:	1141                	addi	sp,sp,-16
    800040d2:	e406                	sd	ra,8(sp)
    800040d4:	e022                	sd	s0,0(sp)
    800040d6:	0800                	addi	s0,sp,16
    800040d8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040da:	4585                	li	a1,1
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	db4080e7          	jalr	-588(ra) # 80003e90 <namex>
}
    800040e4:	60a2                	ld	ra,8(sp)
    800040e6:	6402                	ld	s0,0(sp)
    800040e8:	0141                	addi	sp,sp,16
    800040ea:	8082                	ret

00000000800040ec <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040ec:	1101                	addi	sp,sp,-32
    800040ee:	ec06                	sd	ra,24(sp)
    800040f0:	e822                	sd	s0,16(sp)
    800040f2:	e426                	sd	s1,8(sp)
    800040f4:	e04a                	sd	s2,0(sp)
    800040f6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040f8:	0001e917          	auipc	s2,0x1e
    800040fc:	a1090913          	addi	s2,s2,-1520 # 80021b08 <log>
    80004100:	01892583          	lw	a1,24(s2)
    80004104:	02892503          	lw	a0,40(s2)
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	ff8080e7          	jalr	-8(ra) # 80003100 <bread>
    80004110:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004112:	02c92683          	lw	a3,44(s2)
    80004116:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004118:	02d05763          	blez	a3,80004146 <write_head+0x5a>
    8000411c:	0001e797          	auipc	a5,0x1e
    80004120:	a1c78793          	addi	a5,a5,-1508 # 80021b38 <log+0x30>
    80004124:	05c50713          	addi	a4,a0,92
    80004128:	36fd                	addiw	a3,a3,-1
    8000412a:	1682                	slli	a3,a3,0x20
    8000412c:	9281                	srli	a3,a3,0x20
    8000412e:	068a                	slli	a3,a3,0x2
    80004130:	0001e617          	auipc	a2,0x1e
    80004134:	a0c60613          	addi	a2,a2,-1524 # 80021b3c <log+0x34>
    80004138:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000413a:	4390                	lw	a2,0(a5)
    8000413c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000413e:	0791                	addi	a5,a5,4
    80004140:	0711                	addi	a4,a4,4
    80004142:	fed79ce3          	bne	a5,a3,8000413a <write_head+0x4e>
  }
  bwrite(buf);
    80004146:	8526                	mv	a0,s1
    80004148:	fffff097          	auipc	ra,0xfffff
    8000414c:	0aa080e7          	jalr	170(ra) # 800031f2 <bwrite>
  brelse(buf);
    80004150:	8526                	mv	a0,s1
    80004152:	fffff097          	auipc	ra,0xfffff
    80004156:	0de080e7          	jalr	222(ra) # 80003230 <brelse>
}
    8000415a:	60e2                	ld	ra,24(sp)
    8000415c:	6442                	ld	s0,16(sp)
    8000415e:	64a2                	ld	s1,8(sp)
    80004160:	6902                	ld	s2,0(sp)
    80004162:	6105                	addi	sp,sp,32
    80004164:	8082                	ret

0000000080004166 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004166:	0001e797          	auipc	a5,0x1e
    8000416a:	9ce7a783          	lw	a5,-1586(a5) # 80021b34 <log+0x2c>
    8000416e:	0af05663          	blez	a5,8000421a <install_trans+0xb4>
{
    80004172:	7139                	addi	sp,sp,-64
    80004174:	fc06                	sd	ra,56(sp)
    80004176:	f822                	sd	s0,48(sp)
    80004178:	f426                	sd	s1,40(sp)
    8000417a:	f04a                	sd	s2,32(sp)
    8000417c:	ec4e                	sd	s3,24(sp)
    8000417e:	e852                	sd	s4,16(sp)
    80004180:	e456                	sd	s5,8(sp)
    80004182:	0080                	addi	s0,sp,64
    80004184:	0001ea97          	auipc	s5,0x1e
    80004188:	9b4a8a93          	addi	s5,s5,-1612 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000418c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000418e:	0001e997          	auipc	s3,0x1e
    80004192:	97a98993          	addi	s3,s3,-1670 # 80021b08 <log>
    80004196:	0189a583          	lw	a1,24(s3)
    8000419a:	014585bb          	addw	a1,a1,s4
    8000419e:	2585                	addiw	a1,a1,1
    800041a0:	0289a503          	lw	a0,40(s3)
    800041a4:	fffff097          	auipc	ra,0xfffff
    800041a8:	f5c080e7          	jalr	-164(ra) # 80003100 <bread>
    800041ac:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041ae:	000aa583          	lw	a1,0(s5)
    800041b2:	0289a503          	lw	a0,40(s3)
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	f4a080e7          	jalr	-182(ra) # 80003100 <bread>
    800041be:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041c0:	40000613          	li	a2,1024
    800041c4:	05890593          	addi	a1,s2,88
    800041c8:	05850513          	addi	a0,a0,88
    800041cc:	ffffd097          	auipc	ra,0xffffd
    800041d0:	ba0080e7          	jalr	-1120(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	01c080e7          	jalr	28(ra) # 800031f2 <bwrite>
    bunpin(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	12a080e7          	jalr	298(ra) # 8000330a <bunpin>
    brelse(lbuf);
    800041e8:	854a                	mv	a0,s2
    800041ea:	fffff097          	auipc	ra,0xfffff
    800041ee:	046080e7          	jalr	70(ra) # 80003230 <brelse>
    brelse(dbuf);
    800041f2:	8526                	mv	a0,s1
    800041f4:	fffff097          	auipc	ra,0xfffff
    800041f8:	03c080e7          	jalr	60(ra) # 80003230 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fc:	2a05                	addiw	s4,s4,1
    800041fe:	0a91                	addi	s5,s5,4
    80004200:	02c9a783          	lw	a5,44(s3)
    80004204:	f8fa49e3          	blt	s4,a5,80004196 <install_trans+0x30>
}
    80004208:	70e2                	ld	ra,56(sp)
    8000420a:	7442                	ld	s0,48(sp)
    8000420c:	74a2                	ld	s1,40(sp)
    8000420e:	7902                	ld	s2,32(sp)
    80004210:	69e2                	ld	s3,24(sp)
    80004212:	6a42                	ld	s4,16(sp)
    80004214:	6aa2                	ld	s5,8(sp)
    80004216:	6121                	addi	sp,sp,64
    80004218:	8082                	ret
    8000421a:	8082                	ret

000000008000421c <initlog>:
{
    8000421c:	7179                	addi	sp,sp,-48
    8000421e:	f406                	sd	ra,40(sp)
    80004220:	f022                	sd	s0,32(sp)
    80004222:	ec26                	sd	s1,24(sp)
    80004224:	e84a                	sd	s2,16(sp)
    80004226:	e44e                	sd	s3,8(sp)
    80004228:	1800                	addi	s0,sp,48
    8000422a:	892a                	mv	s2,a0
    8000422c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000422e:	0001e497          	auipc	s1,0x1e
    80004232:	8da48493          	addi	s1,s1,-1830 # 80021b08 <log>
    80004236:	00004597          	auipc	a1,0x4
    8000423a:	47a58593          	addi	a1,a1,1146 # 800086b0 <syscalls+0x1d8>
    8000423e:	8526                	mv	a0,s1
    80004240:	ffffd097          	auipc	ra,0xffffd
    80004244:	940080e7          	jalr	-1728(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004248:	0149a583          	lw	a1,20(s3)
    8000424c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000424e:	0109a783          	lw	a5,16(s3)
    80004252:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004254:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004258:	854a                	mv	a0,s2
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	ea6080e7          	jalr	-346(ra) # 80003100 <bread>
  log.lh.n = lh->n;
    80004262:	4d3c                	lw	a5,88(a0)
    80004264:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004266:	02f05563          	blez	a5,80004290 <initlog+0x74>
    8000426a:	05c50713          	addi	a4,a0,92
    8000426e:	0001e697          	auipc	a3,0x1e
    80004272:	8ca68693          	addi	a3,a3,-1846 # 80021b38 <log+0x30>
    80004276:	37fd                	addiw	a5,a5,-1
    80004278:	1782                	slli	a5,a5,0x20
    8000427a:	9381                	srli	a5,a5,0x20
    8000427c:	078a                	slli	a5,a5,0x2
    8000427e:	06050613          	addi	a2,a0,96
    80004282:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004284:	4310                	lw	a2,0(a4)
    80004286:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004288:	0711                	addi	a4,a4,4
    8000428a:	0691                	addi	a3,a3,4
    8000428c:	fef71ce3          	bne	a4,a5,80004284 <initlog+0x68>
  brelse(buf);
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	fa0080e7          	jalr	-96(ra) # 80003230 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004298:	00000097          	auipc	ra,0x0
    8000429c:	ece080e7          	jalr	-306(ra) # 80004166 <install_trans>
  log.lh.n = 0;
    800042a0:	0001e797          	auipc	a5,0x1e
    800042a4:	8807aa23          	sw	zero,-1900(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800042a8:	00000097          	auipc	ra,0x0
    800042ac:	e44080e7          	jalr	-444(ra) # 800040ec <write_head>
}
    800042b0:	70a2                	ld	ra,40(sp)
    800042b2:	7402                	ld	s0,32(sp)
    800042b4:	64e2                	ld	s1,24(sp)
    800042b6:	6942                	ld	s2,16(sp)
    800042b8:	69a2                	ld	s3,8(sp)
    800042ba:	6145                	addi	sp,sp,48
    800042bc:	8082                	ret

00000000800042be <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042be:	1101                	addi	sp,sp,-32
    800042c0:	ec06                	sd	ra,24(sp)
    800042c2:	e822                	sd	s0,16(sp)
    800042c4:	e426                	sd	s1,8(sp)
    800042c6:	e04a                	sd	s2,0(sp)
    800042c8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042ca:	0001e517          	auipc	a0,0x1e
    800042ce:	83e50513          	addi	a0,a0,-1986 # 80021b08 <log>
    800042d2:	ffffd097          	auipc	ra,0xffffd
    800042d6:	93e080e7          	jalr	-1730(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    800042da:	0001e497          	auipc	s1,0x1e
    800042de:	82e48493          	addi	s1,s1,-2002 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e2:	4979                	li	s2,30
    800042e4:	a039                	j	800042f2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042e6:	85a6                	mv	a1,s1
    800042e8:	8526                	mv	a0,s1
    800042ea:	ffffe097          	auipc	ra,0xffffe
    800042ee:	dfe080e7          	jalr	-514(ra) # 800020e8 <sleep>
    if(log.committing){
    800042f2:	50dc                	lw	a5,36(s1)
    800042f4:	fbed                	bnez	a5,800042e6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042f6:	509c                	lw	a5,32(s1)
    800042f8:	0017871b          	addiw	a4,a5,1
    800042fc:	0007069b          	sext.w	a3,a4
    80004300:	0027179b          	slliw	a5,a4,0x2
    80004304:	9fb9                	addw	a5,a5,a4
    80004306:	0017979b          	slliw	a5,a5,0x1
    8000430a:	54d8                	lw	a4,44(s1)
    8000430c:	9fb9                	addw	a5,a5,a4
    8000430e:	00f95963          	bge	s2,a5,80004320 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004312:	85a6                	mv	a1,s1
    80004314:	8526                	mv	a0,s1
    80004316:	ffffe097          	auipc	ra,0xffffe
    8000431a:	dd2080e7          	jalr	-558(ra) # 800020e8 <sleep>
    8000431e:	bfd1                	j	800042f2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004320:	0001d517          	auipc	a0,0x1d
    80004324:	7e850513          	addi	a0,a0,2024 # 80021b08 <log>
    80004328:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	99a080e7          	jalr	-1638(ra) # 80000cc4 <release>
      break;
    }
  }
}
    80004332:	60e2                	ld	ra,24(sp)
    80004334:	6442                	ld	s0,16(sp)
    80004336:	64a2                	ld	s1,8(sp)
    80004338:	6902                	ld	s2,0(sp)
    8000433a:	6105                	addi	sp,sp,32
    8000433c:	8082                	ret

000000008000433e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000433e:	7139                	addi	sp,sp,-64
    80004340:	fc06                	sd	ra,56(sp)
    80004342:	f822                	sd	s0,48(sp)
    80004344:	f426                	sd	s1,40(sp)
    80004346:	f04a                	sd	s2,32(sp)
    80004348:	ec4e                	sd	s3,24(sp)
    8000434a:	e852                	sd	s4,16(sp)
    8000434c:	e456                	sd	s5,8(sp)
    8000434e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004350:	0001d497          	auipc	s1,0x1d
    80004354:	7b848493          	addi	s1,s1,1976 # 80021b08 <log>
    80004358:	8526                	mv	a0,s1
    8000435a:	ffffd097          	auipc	ra,0xffffd
    8000435e:	8b6080e7          	jalr	-1866(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004362:	509c                	lw	a5,32(s1)
    80004364:	37fd                	addiw	a5,a5,-1
    80004366:	0007891b          	sext.w	s2,a5
    8000436a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000436c:	50dc                	lw	a5,36(s1)
    8000436e:	efb9                	bnez	a5,800043cc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004370:	06091663          	bnez	s2,800043dc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004374:	0001d497          	auipc	s1,0x1d
    80004378:	79448493          	addi	s1,s1,1940 # 80021b08 <log>
    8000437c:	4785                	li	a5,1
    8000437e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004380:	8526                	mv	a0,s1
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	942080e7          	jalr	-1726(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000438a:	54dc                	lw	a5,44(s1)
    8000438c:	06f04763          	bgtz	a5,800043fa <end_op+0xbc>
    acquire(&log.lock);
    80004390:	0001d497          	auipc	s1,0x1d
    80004394:	77848493          	addi	s1,s1,1912 # 80021b08 <log>
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	876080e7          	jalr	-1930(ra) # 80000c10 <acquire>
    log.committing = 0;
    800043a2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043a6:	8526                	mv	a0,s1
    800043a8:	ffffe097          	auipc	ra,0xffffe
    800043ac:	dbe080e7          	jalr	-578(ra) # 80002166 <wakeup>
    release(&log.lock);
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	912080e7          	jalr	-1774(ra) # 80000cc4 <release>
}
    800043ba:	70e2                	ld	ra,56(sp)
    800043bc:	7442                	ld	s0,48(sp)
    800043be:	74a2                	ld	s1,40(sp)
    800043c0:	7902                	ld	s2,32(sp)
    800043c2:	69e2                	ld	s3,24(sp)
    800043c4:	6a42                	ld	s4,16(sp)
    800043c6:	6aa2                	ld	s5,8(sp)
    800043c8:	6121                	addi	sp,sp,64
    800043ca:	8082                	ret
    panic("log.committing");
    800043cc:	00004517          	auipc	a0,0x4
    800043d0:	2ec50513          	addi	a0,a0,748 # 800086b8 <syscalls+0x1e0>
    800043d4:	ffffc097          	auipc	ra,0xffffc
    800043d8:	174080e7          	jalr	372(ra) # 80000548 <panic>
    wakeup(&log);
    800043dc:	0001d497          	auipc	s1,0x1d
    800043e0:	72c48493          	addi	s1,s1,1836 # 80021b08 <log>
    800043e4:	8526                	mv	a0,s1
    800043e6:	ffffe097          	auipc	ra,0xffffe
    800043ea:	d80080e7          	jalr	-640(ra) # 80002166 <wakeup>
  release(&log.lock);
    800043ee:	8526                	mv	a0,s1
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	8d4080e7          	jalr	-1836(ra) # 80000cc4 <release>
  if(do_commit){
    800043f8:	b7c9                	j	800043ba <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fa:	0001da97          	auipc	s5,0x1d
    800043fe:	73ea8a93          	addi	s5,s5,1854 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004402:	0001da17          	auipc	s4,0x1d
    80004406:	706a0a13          	addi	s4,s4,1798 # 80021b08 <log>
    8000440a:	018a2583          	lw	a1,24(s4)
    8000440e:	012585bb          	addw	a1,a1,s2
    80004412:	2585                	addiw	a1,a1,1
    80004414:	028a2503          	lw	a0,40(s4)
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	ce8080e7          	jalr	-792(ra) # 80003100 <bread>
    80004420:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004422:	000aa583          	lw	a1,0(s5)
    80004426:	028a2503          	lw	a0,40(s4)
    8000442a:	fffff097          	auipc	ra,0xfffff
    8000442e:	cd6080e7          	jalr	-810(ra) # 80003100 <bread>
    80004432:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004434:	40000613          	li	a2,1024
    80004438:	05850593          	addi	a1,a0,88
    8000443c:	05848513          	addi	a0,s1,88
    80004440:	ffffd097          	auipc	ra,0xffffd
    80004444:	92c080e7          	jalr	-1748(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004448:	8526                	mv	a0,s1
    8000444a:	fffff097          	auipc	ra,0xfffff
    8000444e:	da8080e7          	jalr	-600(ra) # 800031f2 <bwrite>
    brelse(from);
    80004452:	854e                	mv	a0,s3
    80004454:	fffff097          	auipc	ra,0xfffff
    80004458:	ddc080e7          	jalr	-548(ra) # 80003230 <brelse>
    brelse(to);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	dd2080e7          	jalr	-558(ra) # 80003230 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004466:	2905                	addiw	s2,s2,1
    80004468:	0a91                	addi	s5,s5,4
    8000446a:	02ca2783          	lw	a5,44(s4)
    8000446e:	f8f94ee3          	blt	s2,a5,8000440a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004472:	00000097          	auipc	ra,0x0
    80004476:	c7a080e7          	jalr	-902(ra) # 800040ec <write_head>
    install_trans(); // Now install writes to home locations
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	cec080e7          	jalr	-788(ra) # 80004166 <install_trans>
    log.lh.n = 0;
    80004482:	0001d797          	auipc	a5,0x1d
    80004486:	6a07a923          	sw	zero,1714(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000448a:	00000097          	auipc	ra,0x0
    8000448e:	c62080e7          	jalr	-926(ra) # 800040ec <write_head>
    80004492:	bdfd                	j	80004390 <end_op+0x52>

0000000080004494 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	e426                	sd	s1,8(sp)
    8000449c:	e04a                	sd	s2,0(sp)
    8000449e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a0:	0001d717          	auipc	a4,0x1d
    800044a4:	69472703          	lw	a4,1684(a4) # 80021b34 <log+0x2c>
    800044a8:	47f5                	li	a5,29
    800044aa:	08e7c063          	blt	a5,a4,8000452a <log_write+0x96>
    800044ae:	84aa                	mv	s1,a0
    800044b0:	0001d797          	auipc	a5,0x1d
    800044b4:	6747a783          	lw	a5,1652(a5) # 80021b24 <log+0x1c>
    800044b8:	37fd                	addiw	a5,a5,-1
    800044ba:	06f75863          	bge	a4,a5,8000452a <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044be:	0001d797          	auipc	a5,0x1d
    800044c2:	66a7a783          	lw	a5,1642(a5) # 80021b28 <log+0x20>
    800044c6:	06f05a63          	blez	a5,8000453a <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044ca:	0001d917          	auipc	s2,0x1d
    800044ce:	63e90913          	addi	s2,s2,1598 # 80021b08 <log>
    800044d2:	854a                	mv	a0,s2
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	73c080e7          	jalr	1852(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044dc:	02c92603          	lw	a2,44(s2)
    800044e0:	06c05563          	blez	a2,8000454a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044e4:	44cc                	lw	a1,12(s1)
    800044e6:	0001d717          	auipc	a4,0x1d
    800044ea:	65270713          	addi	a4,a4,1618 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044ee:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044f0:	4314                	lw	a3,0(a4)
    800044f2:	04b68d63          	beq	a3,a1,8000454c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800044f6:	2785                	addiw	a5,a5,1
    800044f8:	0711                	addi	a4,a4,4
    800044fa:	fec79be3          	bne	a5,a2,800044f0 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044fe:	0621                	addi	a2,a2,8
    80004500:	060a                	slli	a2,a2,0x2
    80004502:	0001d797          	auipc	a5,0x1d
    80004506:	60678793          	addi	a5,a5,1542 # 80021b08 <log>
    8000450a:	963e                	add	a2,a2,a5
    8000450c:	44dc                	lw	a5,12(s1)
    8000450e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004510:	8526                	mv	a0,s1
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	dbc080e7          	jalr	-580(ra) # 800032ce <bpin>
    log.lh.n++;
    8000451a:	0001d717          	auipc	a4,0x1d
    8000451e:	5ee70713          	addi	a4,a4,1518 # 80021b08 <log>
    80004522:	575c                	lw	a5,44(a4)
    80004524:	2785                	addiw	a5,a5,1
    80004526:	d75c                	sw	a5,44(a4)
    80004528:	a83d                	j	80004566 <log_write+0xd2>
    panic("too big a transaction");
    8000452a:	00004517          	auipc	a0,0x4
    8000452e:	19e50513          	addi	a0,a0,414 # 800086c8 <syscalls+0x1f0>
    80004532:	ffffc097          	auipc	ra,0xffffc
    80004536:	016080e7          	jalr	22(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000453a:	00004517          	auipc	a0,0x4
    8000453e:	1a650513          	addi	a0,a0,422 # 800086e0 <syscalls+0x208>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	006080e7          	jalr	6(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000454a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000454c:	00878713          	addi	a4,a5,8
    80004550:	00271693          	slli	a3,a4,0x2
    80004554:	0001d717          	auipc	a4,0x1d
    80004558:	5b470713          	addi	a4,a4,1460 # 80021b08 <log>
    8000455c:	9736                	add	a4,a4,a3
    8000455e:	44d4                	lw	a3,12(s1)
    80004560:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004562:	faf607e3          	beq	a2,a5,80004510 <log_write+0x7c>
  }
  release(&log.lock);
    80004566:	0001d517          	auipc	a0,0x1d
    8000456a:	5a250513          	addi	a0,a0,1442 # 80021b08 <log>
    8000456e:	ffffc097          	auipc	ra,0xffffc
    80004572:	756080e7          	jalr	1878(ra) # 80000cc4 <release>
}
    80004576:	60e2                	ld	ra,24(sp)
    80004578:	6442                	ld	s0,16(sp)
    8000457a:	64a2                	ld	s1,8(sp)
    8000457c:	6902                	ld	s2,0(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret

0000000080004582 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004582:	1101                	addi	sp,sp,-32
    80004584:	ec06                	sd	ra,24(sp)
    80004586:	e822                	sd	s0,16(sp)
    80004588:	e426                	sd	s1,8(sp)
    8000458a:	e04a                	sd	s2,0(sp)
    8000458c:	1000                	addi	s0,sp,32
    8000458e:	84aa                	mv	s1,a0
    80004590:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004592:	00004597          	auipc	a1,0x4
    80004596:	16e58593          	addi	a1,a1,366 # 80008700 <syscalls+0x228>
    8000459a:	0521                	addi	a0,a0,8
    8000459c:	ffffc097          	auipc	ra,0xffffc
    800045a0:	5e4080e7          	jalr	1508(ra) # 80000b80 <initlock>
  lk->name = name;
    800045a4:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ac:	0204a423          	sw	zero,40(s1)
}
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6902                	ld	s2,0(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret

00000000800045bc <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045bc:	1101                	addi	sp,sp,-32
    800045be:	ec06                	sd	ra,24(sp)
    800045c0:	e822                	sd	s0,16(sp)
    800045c2:	e426                	sd	s1,8(sp)
    800045c4:	e04a                	sd	s2,0(sp)
    800045c6:	1000                	addi	s0,sp,32
    800045c8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ca:	00850913          	addi	s2,a0,8
    800045ce:	854a                	mv	a0,s2
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	640080e7          	jalr	1600(ra) # 80000c10 <acquire>
  while (lk->locked) {
    800045d8:	409c                	lw	a5,0(s1)
    800045da:	cb89                	beqz	a5,800045ec <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045dc:	85ca                	mv	a1,s2
    800045de:	8526                	mv	a0,s1
    800045e0:	ffffe097          	auipc	ra,0xffffe
    800045e4:	b08080e7          	jalr	-1272(ra) # 800020e8 <sleep>
  while (lk->locked) {
    800045e8:	409c                	lw	a5,0(s1)
    800045ea:	fbed                	bnez	a5,800045dc <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045ec:	4785                	li	a5,1
    800045ee:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045f0:	ffffd097          	auipc	ra,0xffffd
    800045f4:	526080e7          	jalr	1318(ra) # 80001b16 <myproc>
    800045f8:	5d1c                	lw	a5,56(a0)
    800045fa:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045fc:	854a                	mv	a0,s2
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	6c6080e7          	jalr	1734(ra) # 80000cc4 <release>
}
    80004606:	60e2                	ld	ra,24(sp)
    80004608:	6442                	ld	s0,16(sp)
    8000460a:	64a2                	ld	s1,8(sp)
    8000460c:	6902                	ld	s2,0(sp)
    8000460e:	6105                	addi	sp,sp,32
    80004610:	8082                	ret

0000000080004612 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004612:	1101                	addi	sp,sp,-32
    80004614:	ec06                	sd	ra,24(sp)
    80004616:	e822                	sd	s0,16(sp)
    80004618:	e426                	sd	s1,8(sp)
    8000461a:	e04a                	sd	s2,0(sp)
    8000461c:	1000                	addi	s0,sp,32
    8000461e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004620:	00850913          	addi	s2,a0,8
    80004624:	854a                	mv	a0,s2
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	5ea080e7          	jalr	1514(ra) # 80000c10 <acquire>
  lk->locked = 0;
    8000462e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004632:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004636:	8526                	mv	a0,s1
    80004638:	ffffe097          	auipc	ra,0xffffe
    8000463c:	b2e080e7          	jalr	-1234(ra) # 80002166 <wakeup>
  release(&lk->lk);
    80004640:	854a                	mv	a0,s2
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	682080e7          	jalr	1666(ra) # 80000cc4 <release>
}
    8000464a:	60e2                	ld	ra,24(sp)
    8000464c:	6442                	ld	s0,16(sp)
    8000464e:	64a2                	ld	s1,8(sp)
    80004650:	6902                	ld	s2,0(sp)
    80004652:	6105                	addi	sp,sp,32
    80004654:	8082                	ret

0000000080004656 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004656:	7179                	addi	sp,sp,-48
    80004658:	f406                	sd	ra,40(sp)
    8000465a:	f022                	sd	s0,32(sp)
    8000465c:	ec26                	sd	s1,24(sp)
    8000465e:	e84a                	sd	s2,16(sp)
    80004660:	e44e                	sd	s3,8(sp)
    80004662:	1800                	addi	s0,sp,48
    80004664:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004666:	00850913          	addi	s2,a0,8
    8000466a:	854a                	mv	a0,s2
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	5a4080e7          	jalr	1444(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004674:	409c                	lw	a5,0(s1)
    80004676:	ef99                	bnez	a5,80004694 <holdingsleep+0x3e>
    80004678:	4481                	li	s1,0
  release(&lk->lk);
    8000467a:	854a                	mv	a0,s2
    8000467c:	ffffc097          	auipc	ra,0xffffc
    80004680:	648080e7          	jalr	1608(ra) # 80000cc4 <release>
  return r;
}
    80004684:	8526                	mv	a0,s1
    80004686:	70a2                	ld	ra,40(sp)
    80004688:	7402                	ld	s0,32(sp)
    8000468a:	64e2                	ld	s1,24(sp)
    8000468c:	6942                	ld	s2,16(sp)
    8000468e:	69a2                	ld	s3,8(sp)
    80004690:	6145                	addi	sp,sp,48
    80004692:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004694:	0284a983          	lw	s3,40(s1)
    80004698:	ffffd097          	auipc	ra,0xffffd
    8000469c:	47e080e7          	jalr	1150(ra) # 80001b16 <myproc>
    800046a0:	5d04                	lw	s1,56(a0)
    800046a2:	413484b3          	sub	s1,s1,s3
    800046a6:	0014b493          	seqz	s1,s1
    800046aa:	bfc1                	j	8000467a <holdingsleep+0x24>

00000000800046ac <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ac:	1141                	addi	sp,sp,-16
    800046ae:	e406                	sd	ra,8(sp)
    800046b0:	e022                	sd	s0,0(sp)
    800046b2:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046b4:	00004597          	auipc	a1,0x4
    800046b8:	05c58593          	addi	a1,a1,92 # 80008710 <syscalls+0x238>
    800046bc:	0001d517          	auipc	a0,0x1d
    800046c0:	59450513          	addi	a0,a0,1428 # 80021c50 <ftable>
    800046c4:	ffffc097          	auipc	ra,0xffffc
    800046c8:	4bc080e7          	jalr	1212(ra) # 80000b80 <initlock>
}
    800046cc:	60a2                	ld	ra,8(sp)
    800046ce:	6402                	ld	s0,0(sp)
    800046d0:	0141                	addi	sp,sp,16
    800046d2:	8082                	ret

00000000800046d4 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046d4:	1101                	addi	sp,sp,-32
    800046d6:	ec06                	sd	ra,24(sp)
    800046d8:	e822                	sd	s0,16(sp)
    800046da:	e426                	sd	s1,8(sp)
    800046dc:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046de:	0001d517          	auipc	a0,0x1d
    800046e2:	57250513          	addi	a0,a0,1394 # 80021c50 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	52a080e7          	jalr	1322(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046ee:	0001d497          	auipc	s1,0x1d
    800046f2:	57a48493          	addi	s1,s1,1402 # 80021c68 <ftable+0x18>
    800046f6:	0001e717          	auipc	a4,0x1e
    800046fa:	51270713          	addi	a4,a4,1298 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800046fe:	40dc                	lw	a5,4(s1)
    80004700:	cf99                	beqz	a5,8000471e <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004702:	02848493          	addi	s1,s1,40
    80004706:	fee49ce3          	bne	s1,a4,800046fe <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000470a:	0001d517          	auipc	a0,0x1d
    8000470e:	54650513          	addi	a0,a0,1350 # 80021c50 <ftable>
    80004712:	ffffc097          	auipc	ra,0xffffc
    80004716:	5b2080e7          	jalr	1458(ra) # 80000cc4 <release>
  return 0;
    8000471a:	4481                	li	s1,0
    8000471c:	a819                	j	80004732 <filealloc+0x5e>
      f->ref = 1;
    8000471e:	4785                	li	a5,1
    80004720:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004722:	0001d517          	auipc	a0,0x1d
    80004726:	52e50513          	addi	a0,a0,1326 # 80021c50 <ftable>
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	59a080e7          	jalr	1434(ra) # 80000cc4 <release>
}
    80004732:	8526                	mv	a0,s1
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6105                	addi	sp,sp,32
    8000473c:	8082                	ret

000000008000473e <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000473e:	1101                	addi	sp,sp,-32
    80004740:	ec06                	sd	ra,24(sp)
    80004742:	e822                	sd	s0,16(sp)
    80004744:	e426                	sd	s1,8(sp)
    80004746:	1000                	addi	s0,sp,32
    80004748:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000474a:	0001d517          	auipc	a0,0x1d
    8000474e:	50650513          	addi	a0,a0,1286 # 80021c50 <ftable>
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	4be080e7          	jalr	1214(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000475a:	40dc                	lw	a5,4(s1)
    8000475c:	02f05263          	blez	a5,80004780 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004760:	2785                	addiw	a5,a5,1
    80004762:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004764:	0001d517          	auipc	a0,0x1d
    80004768:	4ec50513          	addi	a0,a0,1260 # 80021c50 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	558080e7          	jalr	1368(ra) # 80000cc4 <release>
  return f;
}
    80004774:	8526                	mv	a0,s1
    80004776:	60e2                	ld	ra,24(sp)
    80004778:	6442                	ld	s0,16(sp)
    8000477a:	64a2                	ld	s1,8(sp)
    8000477c:	6105                	addi	sp,sp,32
    8000477e:	8082                	ret
    panic("filedup");
    80004780:	00004517          	auipc	a0,0x4
    80004784:	f9850513          	addi	a0,a0,-104 # 80008718 <syscalls+0x240>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	dc0080e7          	jalr	-576(ra) # 80000548 <panic>

0000000080004790 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004790:	7139                	addi	sp,sp,-64
    80004792:	fc06                	sd	ra,56(sp)
    80004794:	f822                	sd	s0,48(sp)
    80004796:	f426                	sd	s1,40(sp)
    80004798:	f04a                	sd	s2,32(sp)
    8000479a:	ec4e                	sd	s3,24(sp)
    8000479c:	e852                	sd	s4,16(sp)
    8000479e:	e456                	sd	s5,8(sp)
    800047a0:	0080                	addi	s0,sp,64
    800047a2:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047a4:	0001d517          	auipc	a0,0x1d
    800047a8:	4ac50513          	addi	a0,a0,1196 # 80021c50 <ftable>
    800047ac:	ffffc097          	auipc	ra,0xffffc
    800047b0:	464080e7          	jalr	1124(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    800047b4:	40dc                	lw	a5,4(s1)
    800047b6:	06f05163          	blez	a5,80004818 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047ba:	37fd                	addiw	a5,a5,-1
    800047bc:	0007871b          	sext.w	a4,a5
    800047c0:	c0dc                	sw	a5,4(s1)
    800047c2:	06e04363          	bgtz	a4,80004828 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047c6:	0004a903          	lw	s2,0(s1)
    800047ca:	0094ca83          	lbu	s5,9(s1)
    800047ce:	0104ba03          	ld	s4,16(s1)
    800047d2:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047d6:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047da:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047de:	0001d517          	auipc	a0,0x1d
    800047e2:	47250513          	addi	a0,a0,1138 # 80021c50 <ftable>
    800047e6:	ffffc097          	auipc	ra,0xffffc
    800047ea:	4de080e7          	jalr	1246(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800047ee:	4785                	li	a5,1
    800047f0:	04f90d63          	beq	s2,a5,8000484a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047f4:	3979                	addiw	s2,s2,-2
    800047f6:	4785                	li	a5,1
    800047f8:	0527e063          	bltu	a5,s2,80004838 <fileclose+0xa8>
    begin_op();
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	ac2080e7          	jalr	-1342(ra) # 800042be <begin_op>
    iput(ff.ip);
    80004804:	854e                	mv	a0,s3
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	2b6080e7          	jalr	694(ra) # 80003abc <iput>
    end_op();
    8000480e:	00000097          	auipc	ra,0x0
    80004812:	b30080e7          	jalr	-1232(ra) # 8000433e <end_op>
    80004816:	a00d                	j	80004838 <fileclose+0xa8>
    panic("fileclose");
    80004818:	00004517          	auipc	a0,0x4
    8000481c:	f0850513          	addi	a0,a0,-248 # 80008720 <syscalls+0x248>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	d28080e7          	jalr	-728(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004828:	0001d517          	auipc	a0,0x1d
    8000482c:	42850513          	addi	a0,a0,1064 # 80021c50 <ftable>
    80004830:	ffffc097          	auipc	ra,0xffffc
    80004834:	494080e7          	jalr	1172(ra) # 80000cc4 <release>
  }
}
    80004838:	70e2                	ld	ra,56(sp)
    8000483a:	7442                	ld	s0,48(sp)
    8000483c:	74a2                	ld	s1,40(sp)
    8000483e:	7902                	ld	s2,32(sp)
    80004840:	69e2                	ld	s3,24(sp)
    80004842:	6a42                	ld	s4,16(sp)
    80004844:	6aa2                	ld	s5,8(sp)
    80004846:	6121                	addi	sp,sp,64
    80004848:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000484a:	85d6                	mv	a1,s5
    8000484c:	8552                	mv	a0,s4
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	372080e7          	jalr	882(ra) # 80004bc0 <pipeclose>
    80004856:	b7cd                	j	80004838 <fileclose+0xa8>

0000000080004858 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004858:	715d                	addi	sp,sp,-80
    8000485a:	e486                	sd	ra,72(sp)
    8000485c:	e0a2                	sd	s0,64(sp)
    8000485e:	fc26                	sd	s1,56(sp)
    80004860:	f84a                	sd	s2,48(sp)
    80004862:	f44e                	sd	s3,40(sp)
    80004864:	0880                	addi	s0,sp,80
    80004866:	84aa                	mv	s1,a0
    80004868:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000486a:	ffffd097          	auipc	ra,0xffffd
    8000486e:	2ac080e7          	jalr	684(ra) # 80001b16 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004872:	409c                	lw	a5,0(s1)
    80004874:	37f9                	addiw	a5,a5,-2
    80004876:	4705                	li	a4,1
    80004878:	04f76763          	bltu	a4,a5,800048c6 <filestat+0x6e>
    8000487c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000487e:	6c88                	ld	a0,24(s1)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	082080e7          	jalr	130(ra) # 80003902 <ilock>
    stati(f->ip, &st);
    80004888:	fb840593          	addi	a1,s0,-72
    8000488c:	6c88                	ld	a0,24(s1)
    8000488e:	fffff097          	auipc	ra,0xfffff
    80004892:	2fe080e7          	jalr	766(ra) # 80003b8c <stati>
    iunlock(f->ip);
    80004896:	6c88                	ld	a0,24(s1)
    80004898:	fffff097          	auipc	ra,0xfffff
    8000489c:	12c080e7          	jalr	300(ra) # 800039c4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048a0:	46e1                	li	a3,24
    800048a2:	fb840613          	addi	a2,s0,-72
    800048a6:	85ce                	mv	a1,s3
    800048a8:	05093503          	ld	a0,80(s2)
    800048ac:	ffffd097          	auipc	ra,0xffffd
    800048b0:	e38080e7          	jalr	-456(ra) # 800016e4 <copyout>
    800048b4:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048b8:	60a6                	ld	ra,72(sp)
    800048ba:	6406                	ld	s0,64(sp)
    800048bc:	74e2                	ld	s1,56(sp)
    800048be:	7942                	ld	s2,48(sp)
    800048c0:	79a2                	ld	s3,40(sp)
    800048c2:	6161                	addi	sp,sp,80
    800048c4:	8082                	ret
  return -1;
    800048c6:	557d                	li	a0,-1
    800048c8:	bfc5                	j	800048b8 <filestat+0x60>

00000000800048ca <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048ca:	7179                	addi	sp,sp,-48
    800048cc:	f406                	sd	ra,40(sp)
    800048ce:	f022                	sd	s0,32(sp)
    800048d0:	ec26                	sd	s1,24(sp)
    800048d2:	e84a                	sd	s2,16(sp)
    800048d4:	e44e                	sd	s3,8(sp)
    800048d6:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048d8:	00854783          	lbu	a5,8(a0)
    800048dc:	c3d5                	beqz	a5,80004980 <fileread+0xb6>
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
    800048e2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048e4:	411c                	lw	a5,0(a0)
    800048e6:	4705                	li	a4,1
    800048e8:	04e78963          	beq	a5,a4,8000493a <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048ec:	470d                	li	a4,3
    800048ee:	04e78d63          	beq	a5,a4,80004948 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048f2:	4709                	li	a4,2
    800048f4:	06e79e63          	bne	a5,a4,80004970 <fileread+0xa6>
    ilock(f->ip);
    800048f8:	6d08                	ld	a0,24(a0)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	008080e7          	jalr	8(ra) # 80003902 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004902:	874a                	mv	a4,s2
    80004904:	5094                	lw	a3,32(s1)
    80004906:	864e                	mv	a2,s3
    80004908:	4585                	li	a1,1
    8000490a:	6c88                	ld	a0,24(s1)
    8000490c:	fffff097          	auipc	ra,0xfffff
    80004910:	2aa080e7          	jalr	682(ra) # 80003bb6 <readi>
    80004914:	892a                	mv	s2,a0
    80004916:	00a05563          	blez	a0,80004920 <fileread+0x56>
      f->off += r;
    8000491a:	509c                	lw	a5,32(s1)
    8000491c:	9fa9                	addw	a5,a5,a0
    8000491e:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004920:	6c88                	ld	a0,24(s1)
    80004922:	fffff097          	auipc	ra,0xfffff
    80004926:	0a2080e7          	jalr	162(ra) # 800039c4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000492a:	854a                	mv	a0,s2
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000493a:	6908                	ld	a0,16(a0)
    8000493c:	00000097          	auipc	ra,0x0
    80004940:	418080e7          	jalr	1048(ra) # 80004d54 <piperead>
    80004944:	892a                	mv	s2,a0
    80004946:	b7d5                	j	8000492a <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004948:	02451783          	lh	a5,36(a0)
    8000494c:	03079693          	slli	a3,a5,0x30
    80004950:	92c1                	srli	a3,a3,0x30
    80004952:	4725                	li	a4,9
    80004954:	02d76863          	bltu	a4,a3,80004984 <fileread+0xba>
    80004958:	0792                	slli	a5,a5,0x4
    8000495a:	0001d717          	auipc	a4,0x1d
    8000495e:	25670713          	addi	a4,a4,598 # 80021bb0 <devsw>
    80004962:	97ba                	add	a5,a5,a4
    80004964:	639c                	ld	a5,0(a5)
    80004966:	c38d                	beqz	a5,80004988 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004968:	4505                	li	a0,1
    8000496a:	9782                	jalr	a5
    8000496c:	892a                	mv	s2,a0
    8000496e:	bf75                	j	8000492a <fileread+0x60>
    panic("fileread");
    80004970:	00004517          	auipc	a0,0x4
    80004974:	dc050513          	addi	a0,a0,-576 # 80008730 <syscalls+0x258>
    80004978:	ffffc097          	auipc	ra,0xffffc
    8000497c:	bd0080e7          	jalr	-1072(ra) # 80000548 <panic>
    return -1;
    80004980:	597d                	li	s2,-1
    80004982:	b765                	j	8000492a <fileread+0x60>
      return -1;
    80004984:	597d                	li	s2,-1
    80004986:	b755                	j	8000492a <fileread+0x60>
    80004988:	597d                	li	s2,-1
    8000498a:	b745                	j	8000492a <fileread+0x60>

000000008000498c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000498c:	00954783          	lbu	a5,9(a0)
    80004990:	14078563          	beqz	a5,80004ada <filewrite+0x14e>
{
    80004994:	715d                	addi	sp,sp,-80
    80004996:	e486                	sd	ra,72(sp)
    80004998:	e0a2                	sd	s0,64(sp)
    8000499a:	fc26                	sd	s1,56(sp)
    8000499c:	f84a                	sd	s2,48(sp)
    8000499e:	f44e                	sd	s3,40(sp)
    800049a0:	f052                	sd	s4,32(sp)
    800049a2:	ec56                	sd	s5,24(sp)
    800049a4:	e85a                	sd	s6,16(sp)
    800049a6:	e45e                	sd	s7,8(sp)
    800049a8:	e062                	sd	s8,0(sp)
    800049aa:	0880                	addi	s0,sp,80
    800049ac:	892a                	mv	s2,a0
    800049ae:	8aae                	mv	s5,a1
    800049b0:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049b2:	411c                	lw	a5,0(a0)
    800049b4:	4705                	li	a4,1
    800049b6:	02e78263          	beq	a5,a4,800049da <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049ba:	470d                	li	a4,3
    800049bc:	02e78563          	beq	a5,a4,800049e6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049c0:	4709                	li	a4,2
    800049c2:	10e79463          	bne	a5,a4,80004aca <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049c6:	0ec05e63          	blez	a2,80004ac2 <filewrite+0x136>
    int i = 0;
    800049ca:	4981                	li	s3,0
    800049cc:	6b05                	lui	s6,0x1
    800049ce:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049d2:	6b85                	lui	s7,0x1
    800049d4:	c00b8b9b          	addiw	s7,s7,-1024
    800049d8:	a851                	j	80004a6c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800049da:	6908                	ld	a0,16(a0)
    800049dc:	00000097          	auipc	ra,0x0
    800049e0:	254080e7          	jalr	596(ra) # 80004c30 <pipewrite>
    800049e4:	a85d                	j	80004a9a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049e6:	02451783          	lh	a5,36(a0)
    800049ea:	03079693          	slli	a3,a5,0x30
    800049ee:	92c1                	srli	a3,a3,0x30
    800049f0:	4725                	li	a4,9
    800049f2:	0ed76663          	bltu	a4,a3,80004ade <filewrite+0x152>
    800049f6:	0792                	slli	a5,a5,0x4
    800049f8:	0001d717          	auipc	a4,0x1d
    800049fc:	1b870713          	addi	a4,a4,440 # 80021bb0 <devsw>
    80004a00:	97ba                	add	a5,a5,a4
    80004a02:	679c                	ld	a5,8(a5)
    80004a04:	cff9                	beqz	a5,80004ae2 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004a06:	4505                	li	a0,1
    80004a08:	9782                	jalr	a5
    80004a0a:	a841                	j	80004a9a <filewrite+0x10e>
    80004a0c:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a10:	00000097          	auipc	ra,0x0
    80004a14:	8ae080e7          	jalr	-1874(ra) # 800042be <begin_op>
      ilock(f->ip);
    80004a18:	01893503          	ld	a0,24(s2)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	ee6080e7          	jalr	-282(ra) # 80003902 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a24:	8762                	mv	a4,s8
    80004a26:	02092683          	lw	a3,32(s2)
    80004a2a:	01598633          	add	a2,s3,s5
    80004a2e:	4585                	li	a1,1
    80004a30:	01893503          	ld	a0,24(s2)
    80004a34:	fffff097          	auipc	ra,0xfffff
    80004a38:	278080e7          	jalr	632(ra) # 80003cac <writei>
    80004a3c:	84aa                	mv	s1,a0
    80004a3e:	02a05f63          	blez	a0,80004a7c <filewrite+0xf0>
        f->off += r;
    80004a42:	02092783          	lw	a5,32(s2)
    80004a46:	9fa9                	addw	a5,a5,a0
    80004a48:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a4c:	01893503          	ld	a0,24(s2)
    80004a50:	fffff097          	auipc	ra,0xfffff
    80004a54:	f74080e7          	jalr	-140(ra) # 800039c4 <iunlock>
      end_op();
    80004a58:	00000097          	auipc	ra,0x0
    80004a5c:	8e6080e7          	jalr	-1818(ra) # 8000433e <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a60:	049c1963          	bne	s8,s1,80004ab2 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004a64:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a68:	0349d663          	bge	s3,s4,80004a94 <filewrite+0x108>
      int n1 = n - i;
    80004a6c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a70:	84be                	mv	s1,a5
    80004a72:	2781                	sext.w	a5,a5
    80004a74:	f8fb5ce3          	bge	s6,a5,80004a0c <filewrite+0x80>
    80004a78:	84de                	mv	s1,s7
    80004a7a:	bf49                	j	80004a0c <filewrite+0x80>
      iunlock(f->ip);
    80004a7c:	01893503          	ld	a0,24(s2)
    80004a80:	fffff097          	auipc	ra,0xfffff
    80004a84:	f44080e7          	jalr	-188(ra) # 800039c4 <iunlock>
      end_op();
    80004a88:	00000097          	auipc	ra,0x0
    80004a8c:	8b6080e7          	jalr	-1866(ra) # 8000433e <end_op>
      if(r < 0)
    80004a90:	fc04d8e3          	bgez	s1,80004a60 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004a94:	8552                	mv	a0,s4
    80004a96:	033a1863          	bne	s4,s3,80004ac6 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a9a:	60a6                	ld	ra,72(sp)
    80004a9c:	6406                	ld	s0,64(sp)
    80004a9e:	74e2                	ld	s1,56(sp)
    80004aa0:	7942                	ld	s2,48(sp)
    80004aa2:	79a2                	ld	s3,40(sp)
    80004aa4:	7a02                	ld	s4,32(sp)
    80004aa6:	6ae2                	ld	s5,24(sp)
    80004aa8:	6b42                	ld	s6,16(sp)
    80004aaa:	6ba2                	ld	s7,8(sp)
    80004aac:	6c02                	ld	s8,0(sp)
    80004aae:	6161                	addi	sp,sp,80
    80004ab0:	8082                	ret
        panic("short filewrite");
    80004ab2:	00004517          	auipc	a0,0x4
    80004ab6:	c8e50513          	addi	a0,a0,-882 # 80008740 <syscalls+0x268>
    80004aba:	ffffc097          	auipc	ra,0xffffc
    80004abe:	a8e080e7          	jalr	-1394(ra) # 80000548 <panic>
    int i = 0;
    80004ac2:	4981                	li	s3,0
    80004ac4:	bfc1                	j	80004a94 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004ac6:	557d                	li	a0,-1
    80004ac8:	bfc9                	j	80004a9a <filewrite+0x10e>
    panic("filewrite");
    80004aca:	00004517          	auipc	a0,0x4
    80004ace:	c8650513          	addi	a0,a0,-890 # 80008750 <syscalls+0x278>
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	a76080e7          	jalr	-1418(ra) # 80000548 <panic>
    return -1;
    80004ada:	557d                	li	a0,-1
}
    80004adc:	8082                	ret
      return -1;
    80004ade:	557d                	li	a0,-1
    80004ae0:	bf6d                	j	80004a9a <filewrite+0x10e>
    80004ae2:	557d                	li	a0,-1
    80004ae4:	bf5d                	j	80004a9a <filewrite+0x10e>

0000000080004ae6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ae6:	7179                	addi	sp,sp,-48
    80004ae8:	f406                	sd	ra,40(sp)
    80004aea:	f022                	sd	s0,32(sp)
    80004aec:	ec26                	sd	s1,24(sp)
    80004aee:	e84a                	sd	s2,16(sp)
    80004af0:	e44e                	sd	s3,8(sp)
    80004af2:	e052                	sd	s4,0(sp)
    80004af4:	1800                	addi	s0,sp,48
    80004af6:	84aa                	mv	s1,a0
    80004af8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004afa:	0005b023          	sd	zero,0(a1)
    80004afe:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b02:	00000097          	auipc	ra,0x0
    80004b06:	bd2080e7          	jalr	-1070(ra) # 800046d4 <filealloc>
    80004b0a:	e088                	sd	a0,0(s1)
    80004b0c:	c551                	beqz	a0,80004b98 <pipealloc+0xb2>
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	bc6080e7          	jalr	-1082(ra) # 800046d4 <filealloc>
    80004b16:	00aa3023          	sd	a0,0(s4)
    80004b1a:	c92d                	beqz	a0,80004b8c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b1c:	ffffc097          	auipc	ra,0xffffc
    80004b20:	004080e7          	jalr	4(ra) # 80000b20 <kalloc>
    80004b24:	892a                	mv	s2,a0
    80004b26:	c125                	beqz	a0,80004b86 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b28:	4985                	li	s3,1
    80004b2a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b2e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b32:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b36:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b3a:	00004597          	auipc	a1,0x4
    80004b3e:	c2658593          	addi	a1,a1,-986 # 80008760 <syscalls+0x288>
    80004b42:	ffffc097          	auipc	ra,0xffffc
    80004b46:	03e080e7          	jalr	62(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004b4a:	609c                	ld	a5,0(s1)
    80004b4c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b50:	609c                	ld	a5,0(s1)
    80004b52:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b56:	609c                	ld	a5,0(s1)
    80004b58:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b5c:	609c                	ld	a5,0(s1)
    80004b5e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b62:	000a3783          	ld	a5,0(s4)
    80004b66:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b6a:	000a3783          	ld	a5,0(s4)
    80004b6e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b72:	000a3783          	ld	a5,0(s4)
    80004b76:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b7a:	000a3783          	ld	a5,0(s4)
    80004b7e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b82:	4501                	li	a0,0
    80004b84:	a025                	j	80004bac <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b86:	6088                	ld	a0,0(s1)
    80004b88:	e501                	bnez	a0,80004b90 <pipealloc+0xaa>
    80004b8a:	a039                	j	80004b98 <pipealloc+0xb2>
    80004b8c:	6088                	ld	a0,0(s1)
    80004b8e:	c51d                	beqz	a0,80004bbc <pipealloc+0xd6>
    fileclose(*f0);
    80004b90:	00000097          	auipc	ra,0x0
    80004b94:	c00080e7          	jalr	-1024(ra) # 80004790 <fileclose>
  if(*f1)
    80004b98:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b9c:	557d                	li	a0,-1
  if(*f1)
    80004b9e:	c799                	beqz	a5,80004bac <pipealloc+0xc6>
    fileclose(*f1);
    80004ba0:	853e                	mv	a0,a5
    80004ba2:	00000097          	auipc	ra,0x0
    80004ba6:	bee080e7          	jalr	-1042(ra) # 80004790 <fileclose>
  return -1;
    80004baa:	557d                	li	a0,-1
}
    80004bac:	70a2                	ld	ra,40(sp)
    80004bae:	7402                	ld	s0,32(sp)
    80004bb0:	64e2                	ld	s1,24(sp)
    80004bb2:	6942                	ld	s2,16(sp)
    80004bb4:	69a2                	ld	s3,8(sp)
    80004bb6:	6a02                	ld	s4,0(sp)
    80004bb8:	6145                	addi	sp,sp,48
    80004bba:	8082                	ret
  return -1;
    80004bbc:	557d                	li	a0,-1
    80004bbe:	b7fd                	j	80004bac <pipealloc+0xc6>

0000000080004bc0 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bc0:	1101                	addi	sp,sp,-32
    80004bc2:	ec06                	sd	ra,24(sp)
    80004bc4:	e822                	sd	s0,16(sp)
    80004bc6:	e426                	sd	s1,8(sp)
    80004bc8:	e04a                	sd	s2,0(sp)
    80004bca:	1000                	addi	s0,sp,32
    80004bcc:	84aa                	mv	s1,a0
    80004bce:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	040080e7          	jalr	64(ra) # 80000c10 <acquire>
  if(writable){
    80004bd8:	02090d63          	beqz	s2,80004c12 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bdc:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004be0:	21848513          	addi	a0,s1,536
    80004be4:	ffffd097          	auipc	ra,0xffffd
    80004be8:	582080e7          	jalr	1410(ra) # 80002166 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bec:	2204b783          	ld	a5,544(s1)
    80004bf0:	eb95                	bnez	a5,80004c24 <pipeclose+0x64>
    release(&pi->lock);
    80004bf2:	8526                	mv	a0,s1
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	0d0080e7          	jalr	208(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	ffffc097          	auipc	ra,0xffffc
    80004c02:	e26080e7          	jalr	-474(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004c06:	60e2                	ld	ra,24(sp)
    80004c08:	6442                	ld	s0,16(sp)
    80004c0a:	64a2                	ld	s1,8(sp)
    80004c0c:	6902                	ld	s2,0(sp)
    80004c0e:	6105                	addi	sp,sp,32
    80004c10:	8082                	ret
    pi->readopen = 0;
    80004c12:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c16:	21c48513          	addi	a0,s1,540
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	54c080e7          	jalr	1356(ra) # 80002166 <wakeup>
    80004c22:	b7e9                	j	80004bec <pipeclose+0x2c>
    release(&pi->lock);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	09e080e7          	jalr	158(ra) # 80000cc4 <release>
}
    80004c2e:	bfe1                	j	80004c06 <pipeclose+0x46>

0000000080004c30 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c30:	7119                	addi	sp,sp,-128
    80004c32:	fc86                	sd	ra,120(sp)
    80004c34:	f8a2                	sd	s0,112(sp)
    80004c36:	f4a6                	sd	s1,104(sp)
    80004c38:	f0ca                	sd	s2,96(sp)
    80004c3a:	ecce                	sd	s3,88(sp)
    80004c3c:	e8d2                	sd	s4,80(sp)
    80004c3e:	e4d6                	sd	s5,72(sp)
    80004c40:	e0da                	sd	s6,64(sp)
    80004c42:	fc5e                	sd	s7,56(sp)
    80004c44:	f862                	sd	s8,48(sp)
    80004c46:	f466                	sd	s9,40(sp)
    80004c48:	f06a                	sd	s10,32(sp)
    80004c4a:	ec6e                	sd	s11,24(sp)
    80004c4c:	0100                	addi	s0,sp,128
    80004c4e:	84aa                	mv	s1,a0
    80004c50:	8cae                	mv	s9,a1
    80004c52:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	ec2080e7          	jalr	-318(ra) # 80001b16 <myproc>
    80004c5c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c5e:	8526                	mv	a0,s1
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	fb0080e7          	jalr	-80(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004c68:	0d605963          	blez	s6,80004d3a <pipewrite+0x10a>
    80004c6c:	89a6                	mv	s3,s1
    80004c6e:	3b7d                	addiw	s6,s6,-1
    80004c70:	1b02                	slli	s6,s6,0x20
    80004c72:	020b5b13          	srli	s6,s6,0x20
    80004c76:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c78:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c7c:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c80:	5dfd                	li	s11,-1
    80004c82:	000b8d1b          	sext.w	s10,s7
    80004c86:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c88:	2184a783          	lw	a5,536(s1)
    80004c8c:	21c4a703          	lw	a4,540(s1)
    80004c90:	2007879b          	addiw	a5,a5,512
    80004c94:	02f71b63          	bne	a4,a5,80004cca <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004c98:	2204a783          	lw	a5,544(s1)
    80004c9c:	cbad                	beqz	a5,80004d0e <pipewrite+0xde>
    80004c9e:	03092783          	lw	a5,48(s2)
    80004ca2:	e7b5                	bnez	a5,80004d0e <pipewrite+0xde>
      wakeup(&pi->nread);
    80004ca4:	8556                	mv	a0,s5
    80004ca6:	ffffd097          	auipc	ra,0xffffd
    80004caa:	4c0080e7          	jalr	1216(ra) # 80002166 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cae:	85ce                	mv	a1,s3
    80004cb0:	8552                	mv	a0,s4
    80004cb2:	ffffd097          	auipc	ra,0xffffd
    80004cb6:	436080e7          	jalr	1078(ra) # 800020e8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cba:	2184a783          	lw	a5,536(s1)
    80004cbe:	21c4a703          	lw	a4,540(s1)
    80004cc2:	2007879b          	addiw	a5,a5,512
    80004cc6:	fcf709e3          	beq	a4,a5,80004c98 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cca:	4685                	li	a3,1
    80004ccc:	019b8633          	add	a2,s7,s9
    80004cd0:	f8f40593          	addi	a1,s0,-113
    80004cd4:	05093503          	ld	a0,80(s2)
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	a98080e7          	jalr	-1384(ra) # 80001770 <copyin>
    80004ce0:	05b50e63          	beq	a0,s11,80004d3c <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ce4:	21c4a783          	lw	a5,540(s1)
    80004ce8:	0017871b          	addiw	a4,a5,1
    80004cec:	20e4ae23          	sw	a4,540(s1)
    80004cf0:	1ff7f793          	andi	a5,a5,511
    80004cf4:	97a6                	add	a5,a5,s1
    80004cf6:	f8f44703          	lbu	a4,-113(s0)
    80004cfa:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004cfe:	001d0c1b          	addiw	s8,s10,1
    80004d02:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004d06:	036b8b63          	beq	s7,s6,80004d3c <pipewrite+0x10c>
    80004d0a:	8bbe                	mv	s7,a5
    80004d0c:	bf9d                	j	80004c82 <pipewrite+0x52>
        release(&pi->lock);
    80004d0e:	8526                	mv	a0,s1
    80004d10:	ffffc097          	auipc	ra,0xffffc
    80004d14:	fb4080e7          	jalr	-76(ra) # 80000cc4 <release>
        return -1;
    80004d18:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d1a:	8562                	mv	a0,s8
    80004d1c:	70e6                	ld	ra,120(sp)
    80004d1e:	7446                	ld	s0,112(sp)
    80004d20:	74a6                	ld	s1,104(sp)
    80004d22:	7906                	ld	s2,96(sp)
    80004d24:	69e6                	ld	s3,88(sp)
    80004d26:	6a46                	ld	s4,80(sp)
    80004d28:	6aa6                	ld	s5,72(sp)
    80004d2a:	6b06                	ld	s6,64(sp)
    80004d2c:	7be2                	ld	s7,56(sp)
    80004d2e:	7c42                	ld	s8,48(sp)
    80004d30:	7ca2                	ld	s9,40(sp)
    80004d32:	7d02                	ld	s10,32(sp)
    80004d34:	6de2                	ld	s11,24(sp)
    80004d36:	6109                	addi	sp,sp,128
    80004d38:	8082                	ret
  for(i = 0; i < n; i++){
    80004d3a:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004d3c:	21848513          	addi	a0,s1,536
    80004d40:	ffffd097          	auipc	ra,0xffffd
    80004d44:	426080e7          	jalr	1062(ra) # 80002166 <wakeup>
  release(&pi->lock);
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	f7a080e7          	jalr	-134(ra) # 80000cc4 <release>
  return i;
    80004d52:	b7e1                	j	80004d1a <pipewrite+0xea>

0000000080004d54 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d54:	715d                	addi	sp,sp,-80
    80004d56:	e486                	sd	ra,72(sp)
    80004d58:	e0a2                	sd	s0,64(sp)
    80004d5a:	fc26                	sd	s1,56(sp)
    80004d5c:	f84a                	sd	s2,48(sp)
    80004d5e:	f44e                	sd	s3,40(sp)
    80004d60:	f052                	sd	s4,32(sp)
    80004d62:	ec56                	sd	s5,24(sp)
    80004d64:	e85a                	sd	s6,16(sp)
    80004d66:	0880                	addi	s0,sp,80
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	892e                	mv	s2,a1
    80004d6c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d6e:	ffffd097          	auipc	ra,0xffffd
    80004d72:	da8080e7          	jalr	-600(ra) # 80001b16 <myproc>
    80004d76:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d78:	8b26                	mv	s6,s1
    80004d7a:	8526                	mv	a0,s1
    80004d7c:	ffffc097          	auipc	ra,0xffffc
    80004d80:	e94080e7          	jalr	-364(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d84:	2184a703          	lw	a4,536(s1)
    80004d88:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d8c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d90:	02f71463          	bne	a4,a5,80004db8 <piperead+0x64>
    80004d94:	2244a783          	lw	a5,548(s1)
    80004d98:	c385                	beqz	a5,80004db8 <piperead+0x64>
    if(pr->killed){
    80004d9a:	030a2783          	lw	a5,48(s4)
    80004d9e:	ebc1                	bnez	a5,80004e2e <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004da0:	85da                	mv	a1,s6
    80004da2:	854e                	mv	a0,s3
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	344080e7          	jalr	836(ra) # 800020e8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dac:	2184a703          	lw	a4,536(s1)
    80004db0:	21c4a783          	lw	a5,540(s1)
    80004db4:	fef700e3          	beq	a4,a5,80004d94 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004db8:	09505263          	blez	s5,80004e3c <piperead+0xe8>
    80004dbc:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dbe:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dc0:	2184a783          	lw	a5,536(s1)
    80004dc4:	21c4a703          	lw	a4,540(s1)
    80004dc8:	02f70d63          	beq	a4,a5,80004e02 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dcc:	0017871b          	addiw	a4,a5,1
    80004dd0:	20e4ac23          	sw	a4,536(s1)
    80004dd4:	1ff7f793          	andi	a5,a5,511
    80004dd8:	97a6                	add	a5,a5,s1
    80004dda:	0187c783          	lbu	a5,24(a5)
    80004dde:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004de2:	4685                	li	a3,1
    80004de4:	fbf40613          	addi	a2,s0,-65
    80004de8:	85ca                	mv	a1,s2
    80004dea:	050a3503          	ld	a0,80(s4)
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	8f6080e7          	jalr	-1802(ra) # 800016e4 <copyout>
    80004df6:	01650663          	beq	a0,s6,80004e02 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dfa:	2985                	addiw	s3,s3,1
    80004dfc:	0905                	addi	s2,s2,1
    80004dfe:	fd3a91e3          	bne	s5,s3,80004dc0 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e02:	21c48513          	addi	a0,s1,540
    80004e06:	ffffd097          	auipc	ra,0xffffd
    80004e0a:	360080e7          	jalr	864(ra) # 80002166 <wakeup>
  release(&pi->lock);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	eb4080e7          	jalr	-332(ra) # 80000cc4 <release>
  return i;
}
    80004e18:	854e                	mv	a0,s3
    80004e1a:	60a6                	ld	ra,72(sp)
    80004e1c:	6406                	ld	s0,64(sp)
    80004e1e:	74e2                	ld	s1,56(sp)
    80004e20:	7942                	ld	s2,48(sp)
    80004e22:	79a2                	ld	s3,40(sp)
    80004e24:	7a02                	ld	s4,32(sp)
    80004e26:	6ae2                	ld	s5,24(sp)
    80004e28:	6b42                	ld	s6,16(sp)
    80004e2a:	6161                	addi	sp,sp,80
    80004e2c:	8082                	ret
      release(&pi->lock);
    80004e2e:	8526                	mv	a0,s1
    80004e30:	ffffc097          	auipc	ra,0xffffc
    80004e34:	e94080e7          	jalr	-364(ra) # 80000cc4 <release>
      return -1;
    80004e38:	59fd                	li	s3,-1
    80004e3a:	bff9                	j	80004e18 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e3c:	4981                	li	s3,0
    80004e3e:	b7d1                	j	80004e02 <piperead+0xae>

0000000080004e40 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e40:	df010113          	addi	sp,sp,-528
    80004e44:	20113423          	sd	ra,520(sp)
    80004e48:	20813023          	sd	s0,512(sp)
    80004e4c:	ffa6                	sd	s1,504(sp)
    80004e4e:	fbca                	sd	s2,496(sp)
    80004e50:	f7ce                	sd	s3,488(sp)
    80004e52:	f3d2                	sd	s4,480(sp)
    80004e54:	efd6                	sd	s5,472(sp)
    80004e56:	ebda                	sd	s6,464(sp)
    80004e58:	e7de                	sd	s7,456(sp)
    80004e5a:	e3e2                	sd	s8,448(sp)
    80004e5c:	ff66                	sd	s9,440(sp)
    80004e5e:	fb6a                	sd	s10,432(sp)
    80004e60:	f76e                	sd	s11,424(sp)
    80004e62:	0c00                	addi	s0,sp,528
    80004e64:	84aa                	mv	s1,a0
    80004e66:	dea43c23          	sd	a0,-520(s0)
    80004e6a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	ca8080e7          	jalr	-856(ra) # 80001b16 <myproc>
    80004e76:	892a                	mv	s2,a0

  begin_op();
    80004e78:	fffff097          	auipc	ra,0xfffff
    80004e7c:	446080e7          	jalr	1094(ra) # 800042be <begin_op>

  if((ip = namei(path)) == 0){
    80004e80:	8526                	mv	a0,s1
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	230080e7          	jalr	560(ra) # 800040b2 <namei>
    80004e8a:	c92d                	beqz	a0,80004efc <exec+0xbc>
    80004e8c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e8e:	fffff097          	auipc	ra,0xfffff
    80004e92:	a74080e7          	jalr	-1420(ra) # 80003902 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e96:	04000713          	li	a4,64
    80004e9a:	4681                	li	a3,0
    80004e9c:	e4840613          	addi	a2,s0,-440
    80004ea0:	4581                	li	a1,0
    80004ea2:	8526                	mv	a0,s1
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	d12080e7          	jalr	-750(ra) # 80003bb6 <readi>
    80004eac:	04000793          	li	a5,64
    80004eb0:	00f51a63          	bne	a0,a5,80004ec4 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004eb4:	e4842703          	lw	a4,-440(s0)
    80004eb8:	464c47b7          	lui	a5,0x464c4
    80004ebc:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ec0:	04f70463          	beq	a4,a5,80004f08 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	fffff097          	auipc	ra,0xfffff
    80004eca:	c9e080e7          	jalr	-866(ra) # 80003b64 <iunlockput>
    end_op();
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	470080e7          	jalr	1136(ra) # 8000433e <end_op>
  }
  return -1;
    80004ed6:	557d                	li	a0,-1
}
    80004ed8:	20813083          	ld	ra,520(sp)
    80004edc:	20013403          	ld	s0,512(sp)
    80004ee0:	74fe                	ld	s1,504(sp)
    80004ee2:	795e                	ld	s2,496(sp)
    80004ee4:	79be                	ld	s3,488(sp)
    80004ee6:	7a1e                	ld	s4,480(sp)
    80004ee8:	6afe                	ld	s5,472(sp)
    80004eea:	6b5e                	ld	s6,464(sp)
    80004eec:	6bbe                	ld	s7,456(sp)
    80004eee:	6c1e                	ld	s8,448(sp)
    80004ef0:	7cfa                	ld	s9,440(sp)
    80004ef2:	7d5a                	ld	s10,432(sp)
    80004ef4:	7dba                	ld	s11,424(sp)
    80004ef6:	21010113          	addi	sp,sp,528
    80004efa:	8082                	ret
    end_op();
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	442080e7          	jalr	1090(ra) # 8000433e <end_op>
    return -1;
    80004f04:	557d                	li	a0,-1
    80004f06:	bfc9                	j	80004ed8 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f08:	854a                	mv	a0,s2
    80004f0a:	ffffd097          	auipc	ra,0xffffd
    80004f0e:	cd0080e7          	jalr	-816(ra) # 80001bda <proc_pagetable>
    80004f12:	8baa                	mv	s7,a0
    80004f14:	d945                	beqz	a0,80004ec4 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f16:	e6842983          	lw	s3,-408(s0)
    80004f1a:	e8045783          	lhu	a5,-384(s0)
    80004f1e:	c7ad                	beqz	a5,80004f88 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f20:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f22:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f24:	6c85                	lui	s9,0x1
    80004f26:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f2a:	def43823          	sd	a5,-528(s0)
    80004f2e:	ac91                	j	80005182 <exec+0x342>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f30:	00004517          	auipc	a0,0x4
    80004f34:	83850513          	addi	a0,a0,-1992 # 80008768 <syscalls+0x290>
    80004f38:	ffffb097          	auipc	ra,0xffffb
    80004f3c:	610080e7          	jalr	1552(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f40:	8756                	mv	a4,s5
    80004f42:	012d86bb          	addw	a3,s11,s2
    80004f46:	4581                	li	a1,0
    80004f48:	8526                	mv	a0,s1
    80004f4a:	fffff097          	auipc	ra,0xfffff
    80004f4e:	c6c080e7          	jalr	-916(ra) # 80003bb6 <readi>
    80004f52:	2501                	sext.w	a0,a0
    80004f54:	1caa9e63          	bne	s5,a0,80005130 <exec+0x2f0>
  for(i = 0; i < sz; i += PGSIZE){
    80004f58:	6785                	lui	a5,0x1
    80004f5a:	0127893b          	addw	s2,a5,s2
    80004f5e:	77fd                	lui	a5,0xfffff
    80004f60:	01478a3b          	addw	s4,a5,s4
    80004f64:	21897663          	bgeu	s2,s8,80005170 <exec+0x330>
    pa = walkaddr(pagetable, va + i);
    80004f68:	02091593          	slli	a1,s2,0x20
    80004f6c:	9181                	srli	a1,a1,0x20
    80004f6e:	95ea                	add	a1,a1,s10
    80004f70:	855e                	mv	a0,s7
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	134080e7          	jalr	308(ra) # 800010a6 <walkaddr>
    80004f7a:	862a                	mv	a2,a0
    if(pa == 0)
    80004f7c:	d955                	beqz	a0,80004f30 <exec+0xf0>
      n = PGSIZE;
    80004f7e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f80:	fd9a70e3          	bgeu	s4,s9,80004f40 <exec+0x100>
      n = sz - i;
    80004f84:	8ad2                	mv	s5,s4
    80004f86:	bf6d                	j	80004f40 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f88:	4901                	li	s2,0
  iunlockput(ip);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	fffff097          	auipc	ra,0xfffff
    80004f90:	bd8080e7          	jalr	-1064(ra) # 80003b64 <iunlockput>
  end_op();
    80004f94:	fffff097          	auipc	ra,0xfffff
    80004f98:	3aa080e7          	jalr	938(ra) # 8000433e <end_op>
  p = myproc();
    80004f9c:	ffffd097          	auipc	ra,0xffffd
    80004fa0:	b7a080e7          	jalr	-1158(ra) # 80001b16 <myproc>
    80004fa4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fa6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004faa:	6785                	lui	a5,0x1
    80004fac:	17fd                	addi	a5,a5,-1
    80004fae:	993e                	add	s2,s2,a5
    80004fb0:	757d                	lui	a0,0xfffff
    80004fb2:	00a977b3          	and	a5,s2,a0
    80004fb6:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fba:	6609                	lui	a2,0x2
    80004fbc:	963e                	add	a2,a2,a5
    80004fbe:	85be                	mv	a1,a5
    80004fc0:	855e                	mv	a0,s7
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	4d2080e7          	jalr	1234(ra) # 80001494 <uvmalloc>
    80004fca:	8b2a                	mv	s6,a0
  ip = 0;
    80004fcc:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fce:	16050163          	beqz	a0,80005130 <exec+0x2f0>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fd2:	75f9                	lui	a1,0xffffe
    80004fd4:	95aa                	add	a1,a1,a0
    80004fd6:	855e                	mv	a0,s7
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	6da080e7          	jalr	1754(ra) # 800016b2 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fe0:	7c7d                	lui	s8,0xfffff
    80004fe2:	9c5a                	add	s8,s8,s6
  procuser2kernel(pagetable,p->prockernelpagetable,0,sz);
    80004fe4:	86da                	mv	a3,s6
    80004fe6:	4601                	li	a2,0
    80004fe8:	168ab583          	ld	a1,360(s5)
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	9b6080e7          	jalr	-1610(ra) # 800019a4 <procuser2kernel>
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	e0043783          	ld	a5,-512(s0)
    80004ffa:	6388                	ld	a0,0(a5)
    80004ffc:	c535                	beqz	a0,80005068 <exec+0x228>
    80004ffe:	e8840993          	addi	s3,s0,-376
    80005002:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005006:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005008:	ffffc097          	auipc	ra,0xffffc
    8000500c:	e8c080e7          	jalr	-372(ra) # 80000e94 <strlen>
    80005010:	2505                	addiw	a0,a0,1
    80005012:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005016:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000501a:	13896f63          	bltu	s2,s8,80005158 <exec+0x318>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000501e:	e0043d83          	ld	s11,-512(s0)
    80005022:	000dba03          	ld	s4,0(s11)
    80005026:	8552                	mv	a0,s4
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	e6c080e7          	jalr	-404(ra) # 80000e94 <strlen>
    80005030:	0015069b          	addiw	a3,a0,1
    80005034:	8652                	mv	a2,s4
    80005036:	85ca                	mv	a1,s2
    80005038:	855e                	mv	a0,s7
    8000503a:	ffffc097          	auipc	ra,0xffffc
    8000503e:	6aa080e7          	jalr	1706(ra) # 800016e4 <copyout>
    80005042:	10054f63          	bltz	a0,80005160 <exec+0x320>
    ustack[argc] = sp;
    80005046:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000504a:	0485                	addi	s1,s1,1
    8000504c:	008d8793          	addi	a5,s11,8
    80005050:	e0f43023          	sd	a5,-512(s0)
    80005054:	008db503          	ld	a0,8(s11)
    80005058:	c911                	beqz	a0,8000506c <exec+0x22c>
    if(argc >= MAXARG)
    8000505a:	09a1                	addi	s3,s3,8
    8000505c:	fb3c96e3          	bne	s9,s3,80005008 <exec+0x1c8>
  sz = sz1;
    80005060:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005064:	4481                	li	s1,0
    80005066:	a0e9                	j	80005130 <exec+0x2f0>
  sp = sz;
    80005068:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000506a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000506c:	00349793          	slli	a5,s1,0x3
    80005070:	f9040713          	addi	a4,s0,-112
    80005074:	97ba                	add	a5,a5,a4
    80005076:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000507a:	00148693          	addi	a3,s1,1
    8000507e:	068e                	slli	a3,a3,0x3
    80005080:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005084:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005088:	01897663          	bgeu	s2,s8,80005094 <exec+0x254>
  sz = sz1;
    8000508c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005090:	4481                	li	s1,0
    80005092:	a879                	j	80005130 <exec+0x2f0>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005094:	e8840613          	addi	a2,s0,-376
    80005098:	85ca                	mv	a1,s2
    8000509a:	855e                	mv	a0,s7
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	648080e7          	jalr	1608(ra) # 800016e4 <copyout>
    800050a4:	0c054263          	bltz	a0,80005168 <exec+0x328>
  p->trapframe->a1 = sp;
    800050a8:	058ab783          	ld	a5,88(s5)
    800050ac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050b0:	df843783          	ld	a5,-520(s0)
    800050b4:	0007c703          	lbu	a4,0(a5)
    800050b8:	cf11                	beqz	a4,800050d4 <exec+0x294>
    800050ba:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050bc:	02f00693          	li	a3,47
    800050c0:	a029                	j	800050ca <exec+0x28a>
  for(last=s=path; *s; s++)
    800050c2:	0785                	addi	a5,a5,1
    800050c4:	fff7c703          	lbu	a4,-1(a5)
    800050c8:	c711                	beqz	a4,800050d4 <exec+0x294>
    if(*s == '/')
    800050ca:	fed71ce3          	bne	a4,a3,800050c2 <exec+0x282>
      last = s+1;
    800050ce:	def43c23          	sd	a5,-520(s0)
    800050d2:	bfc5                	j	800050c2 <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    800050d4:	4641                	li	a2,16
    800050d6:	df843583          	ld	a1,-520(s0)
    800050da:	158a8513          	addi	a0,s5,344
    800050de:	ffffc097          	auipc	ra,0xffffc
    800050e2:	d84080e7          	jalr	-636(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    800050e6:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050ea:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050ee:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050f2:	058ab783          	ld	a5,88(s5)
    800050f6:	e6043703          	ld	a4,-416(s0)
    800050fa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050fc:	058ab783          	ld	a5,88(s5)
    80005100:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005104:	85ea                	mv	a1,s10
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	b70080e7          	jalr	-1168(ra) # 80001c76 <proc_freepagetable>
  if(p->pid==1){
    8000510e:	038aa703          	lw	a4,56(s5)
    80005112:	4785                	li	a5,1
    80005114:	00f70563          	beq	a4,a5,8000511e <exec+0x2de>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005118:	0004851b          	sext.w	a0,s1
    8000511c:	bb75                	j	80004ed8 <exec+0x98>
    vmprint(p->pagetable);
    8000511e:	050ab503          	ld	a0,80(s5)
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	748080e7          	jalr	1864(ra) # 8000186a <vmprint>
    8000512a:	b7fd                	j	80005118 <exec+0x2d8>
    8000512c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005130:	e0843583          	ld	a1,-504(s0)
    80005134:	855e                	mv	a0,s7
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	b40080e7          	jalr	-1216(ra) # 80001c76 <proc_freepagetable>
  if(ip){
    8000513e:	d80493e3          	bnez	s1,80004ec4 <exec+0x84>
  return -1;
    80005142:	557d                	li	a0,-1
    80005144:	bb51                	j	80004ed8 <exec+0x98>
    80005146:	e1243423          	sd	s2,-504(s0)
    8000514a:	b7dd                	j	80005130 <exec+0x2f0>
    8000514c:	e1243423          	sd	s2,-504(s0)
    80005150:	b7c5                	j	80005130 <exec+0x2f0>
    80005152:	e1243423          	sd	s2,-504(s0)
    80005156:	bfe9                	j	80005130 <exec+0x2f0>
  sz = sz1;
    80005158:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000515c:	4481                	li	s1,0
    8000515e:	bfc9                	j	80005130 <exec+0x2f0>
  sz = sz1;
    80005160:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005164:	4481                	li	s1,0
    80005166:	b7e9                	j	80005130 <exec+0x2f0>
  sz = sz1;
    80005168:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516c:	4481                	li	s1,0
    8000516e:	b7c9                	j	80005130 <exec+0x2f0>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005170:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005174:	2b05                	addiw	s6,s6,1
    80005176:	0389899b          	addiw	s3,s3,56
    8000517a:	e8045783          	lhu	a5,-384(s0)
    8000517e:	e0fb56e3          	bge	s6,a5,80004f8a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005182:	2981                	sext.w	s3,s3
    80005184:	03800713          	li	a4,56
    80005188:	86ce                	mv	a3,s3
    8000518a:	e1040613          	addi	a2,s0,-496
    8000518e:	4581                	li	a1,0
    80005190:	8526                	mv	a0,s1
    80005192:	fffff097          	auipc	ra,0xfffff
    80005196:	a24080e7          	jalr	-1500(ra) # 80003bb6 <readi>
    8000519a:	03800793          	li	a5,56
    8000519e:	f8f517e3          	bne	a0,a5,8000512c <exec+0x2ec>
    if(ph.type != ELF_PROG_LOAD)
    800051a2:	e1042783          	lw	a5,-496(s0)
    800051a6:	4705                	li	a4,1
    800051a8:	fce796e3          	bne	a5,a4,80005174 <exec+0x334>
    if(ph.memsz < ph.filesz)
    800051ac:	e3843603          	ld	a2,-456(s0)
    800051b0:	e3043783          	ld	a5,-464(s0)
    800051b4:	f8f669e3          	bltu	a2,a5,80005146 <exec+0x306>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051b8:	e2043783          	ld	a5,-480(s0)
    800051bc:	963e                	add	a2,a2,a5
    800051be:	f8f667e3          	bltu	a2,a5,8000514c <exec+0x30c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051c2:	85ca                	mv	a1,s2
    800051c4:	855e                	mv	a0,s7
    800051c6:	ffffc097          	auipc	ra,0xffffc
    800051ca:	2ce080e7          	jalr	718(ra) # 80001494 <uvmalloc>
    800051ce:	e0a43423          	sd	a0,-504(s0)
    800051d2:	d141                	beqz	a0,80005152 <exec+0x312>
    if(ph.vaddr % PGSIZE != 0)
    800051d4:	e2043d03          	ld	s10,-480(s0)
    800051d8:	df043783          	ld	a5,-528(s0)
    800051dc:	00fd77b3          	and	a5,s10,a5
    800051e0:	fba1                	bnez	a5,80005130 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051e2:	e1842d83          	lw	s11,-488(s0)
    800051e6:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051ea:	f80c03e3          	beqz	s8,80005170 <exec+0x330>
    800051ee:	8a62                	mv	s4,s8
    800051f0:	4901                	li	s2,0
    800051f2:	bb9d                	j	80004f68 <exec+0x128>

00000000800051f4 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051f4:	7179                	addi	sp,sp,-48
    800051f6:	f406                	sd	ra,40(sp)
    800051f8:	f022                	sd	s0,32(sp)
    800051fa:	ec26                	sd	s1,24(sp)
    800051fc:	e84a                	sd	s2,16(sp)
    800051fe:	1800                	addi	s0,sp,48
    80005200:	892e                	mv	s2,a1
    80005202:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005204:	fdc40593          	addi	a1,s0,-36
    80005208:	ffffe097          	auipc	ra,0xffffe
    8000520c:	b88080e7          	jalr	-1144(ra) # 80002d90 <argint>
    80005210:	04054063          	bltz	a0,80005250 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005214:	fdc42703          	lw	a4,-36(s0)
    80005218:	47bd                	li	a5,15
    8000521a:	02e7ed63          	bltu	a5,a4,80005254 <argfd+0x60>
    8000521e:	ffffd097          	auipc	ra,0xffffd
    80005222:	8f8080e7          	jalr	-1800(ra) # 80001b16 <myproc>
    80005226:	fdc42703          	lw	a4,-36(s0)
    8000522a:	01a70793          	addi	a5,a4,26
    8000522e:	078e                	slli	a5,a5,0x3
    80005230:	953e                	add	a0,a0,a5
    80005232:	611c                	ld	a5,0(a0)
    80005234:	c395                	beqz	a5,80005258 <argfd+0x64>
    return -1;
  if(pfd)
    80005236:	00090463          	beqz	s2,8000523e <argfd+0x4a>
    *pfd = fd;
    8000523a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000523e:	4501                	li	a0,0
  if(pf)
    80005240:	c091                	beqz	s1,80005244 <argfd+0x50>
    *pf = f;
    80005242:	e09c                	sd	a5,0(s1)
}
    80005244:	70a2                	ld	ra,40(sp)
    80005246:	7402                	ld	s0,32(sp)
    80005248:	64e2                	ld	s1,24(sp)
    8000524a:	6942                	ld	s2,16(sp)
    8000524c:	6145                	addi	sp,sp,48
    8000524e:	8082                	ret
    return -1;
    80005250:	557d                	li	a0,-1
    80005252:	bfcd                	j	80005244 <argfd+0x50>
    return -1;
    80005254:	557d                	li	a0,-1
    80005256:	b7fd                	j	80005244 <argfd+0x50>
    80005258:	557d                	li	a0,-1
    8000525a:	b7ed                	j	80005244 <argfd+0x50>

000000008000525c <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000525c:	1101                	addi	sp,sp,-32
    8000525e:	ec06                	sd	ra,24(sp)
    80005260:	e822                	sd	s0,16(sp)
    80005262:	e426                	sd	s1,8(sp)
    80005264:	1000                	addi	s0,sp,32
    80005266:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005268:	ffffd097          	auipc	ra,0xffffd
    8000526c:	8ae080e7          	jalr	-1874(ra) # 80001b16 <myproc>
    80005270:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005272:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80b0>
    80005276:	4501                	li	a0,0
    80005278:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000527a:	6398                	ld	a4,0(a5)
    8000527c:	cb19                	beqz	a4,80005292 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000527e:	2505                	addiw	a0,a0,1
    80005280:	07a1                	addi	a5,a5,8
    80005282:	fed51ce3          	bne	a0,a3,8000527a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005286:	557d                	li	a0,-1
}
    80005288:	60e2                	ld	ra,24(sp)
    8000528a:	6442                	ld	s0,16(sp)
    8000528c:	64a2                	ld	s1,8(sp)
    8000528e:	6105                	addi	sp,sp,32
    80005290:	8082                	ret
      p->ofile[fd] = f;
    80005292:	01a50793          	addi	a5,a0,26
    80005296:	078e                	slli	a5,a5,0x3
    80005298:	963e                	add	a2,a2,a5
    8000529a:	e204                	sd	s1,0(a2)
      return fd;
    8000529c:	b7f5                	j	80005288 <fdalloc+0x2c>

000000008000529e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000529e:	715d                	addi	sp,sp,-80
    800052a0:	e486                	sd	ra,72(sp)
    800052a2:	e0a2                	sd	s0,64(sp)
    800052a4:	fc26                	sd	s1,56(sp)
    800052a6:	f84a                	sd	s2,48(sp)
    800052a8:	f44e                	sd	s3,40(sp)
    800052aa:	f052                	sd	s4,32(sp)
    800052ac:	ec56                	sd	s5,24(sp)
    800052ae:	0880                	addi	s0,sp,80
    800052b0:	89ae                	mv	s3,a1
    800052b2:	8ab2                	mv	s5,a2
    800052b4:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052b6:	fb040593          	addi	a1,s0,-80
    800052ba:	fffff097          	auipc	ra,0xfffff
    800052be:	e16080e7          	jalr	-490(ra) # 800040d0 <nameiparent>
    800052c2:	892a                	mv	s2,a0
    800052c4:	12050f63          	beqz	a0,80005402 <create+0x164>
    return 0;

  ilock(dp);
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	63a080e7          	jalr	1594(ra) # 80003902 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052d0:	4601                	li	a2,0
    800052d2:	fb040593          	addi	a1,s0,-80
    800052d6:	854a                	mv	a0,s2
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	b08080e7          	jalr	-1272(ra) # 80003de0 <dirlookup>
    800052e0:	84aa                	mv	s1,a0
    800052e2:	c921                	beqz	a0,80005332 <create+0x94>
    iunlockput(dp);
    800052e4:	854a                	mv	a0,s2
    800052e6:	fffff097          	auipc	ra,0xfffff
    800052ea:	87e080e7          	jalr	-1922(ra) # 80003b64 <iunlockput>
    ilock(ip);
    800052ee:	8526                	mv	a0,s1
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	612080e7          	jalr	1554(ra) # 80003902 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052f8:	2981                	sext.w	s3,s3
    800052fa:	4789                	li	a5,2
    800052fc:	02f99463          	bne	s3,a5,80005324 <create+0x86>
    80005300:	0444d783          	lhu	a5,68(s1)
    80005304:	37f9                	addiw	a5,a5,-2
    80005306:	17c2                	slli	a5,a5,0x30
    80005308:	93c1                	srli	a5,a5,0x30
    8000530a:	4705                	li	a4,1
    8000530c:	00f76c63          	bltu	a4,a5,80005324 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005310:	8526                	mv	a0,s1
    80005312:	60a6                	ld	ra,72(sp)
    80005314:	6406                	ld	s0,64(sp)
    80005316:	74e2                	ld	s1,56(sp)
    80005318:	7942                	ld	s2,48(sp)
    8000531a:	79a2                	ld	s3,40(sp)
    8000531c:	7a02                	ld	s4,32(sp)
    8000531e:	6ae2                	ld	s5,24(sp)
    80005320:	6161                	addi	sp,sp,80
    80005322:	8082                	ret
    iunlockput(ip);
    80005324:	8526                	mv	a0,s1
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	83e080e7          	jalr	-1986(ra) # 80003b64 <iunlockput>
    return 0;
    8000532e:	4481                	li	s1,0
    80005330:	b7c5                	j	80005310 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005332:	85ce                	mv	a1,s3
    80005334:	00092503          	lw	a0,0(s2)
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	432080e7          	jalr	1074(ra) # 8000376a <ialloc>
    80005340:	84aa                	mv	s1,a0
    80005342:	c529                	beqz	a0,8000538c <create+0xee>
  ilock(ip);
    80005344:	ffffe097          	auipc	ra,0xffffe
    80005348:	5be080e7          	jalr	1470(ra) # 80003902 <ilock>
  ip->major = major;
    8000534c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005350:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005354:	4785                	li	a5,1
    80005356:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000535a:	8526                	mv	a0,s1
    8000535c:	ffffe097          	auipc	ra,0xffffe
    80005360:	4dc080e7          	jalr	1244(ra) # 80003838 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005364:	2981                	sext.w	s3,s3
    80005366:	4785                	li	a5,1
    80005368:	02f98a63          	beq	s3,a5,8000539c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000536c:	40d0                	lw	a2,4(s1)
    8000536e:	fb040593          	addi	a1,s0,-80
    80005372:	854a                	mv	a0,s2
    80005374:	fffff097          	auipc	ra,0xfffff
    80005378:	c7c080e7          	jalr	-900(ra) # 80003ff0 <dirlink>
    8000537c:	06054b63          	bltz	a0,800053f2 <create+0x154>
  iunlockput(dp);
    80005380:	854a                	mv	a0,s2
    80005382:	ffffe097          	auipc	ra,0xffffe
    80005386:	7e2080e7          	jalr	2018(ra) # 80003b64 <iunlockput>
  return ip;
    8000538a:	b759                	j	80005310 <create+0x72>
    panic("create: ialloc");
    8000538c:	00003517          	auipc	a0,0x3
    80005390:	3fc50513          	addi	a0,a0,1020 # 80008788 <syscalls+0x2b0>
    80005394:	ffffb097          	auipc	ra,0xffffb
    80005398:	1b4080e7          	jalr	436(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    8000539c:	04a95783          	lhu	a5,74(s2)
    800053a0:	2785                	addiw	a5,a5,1
    800053a2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053a6:	854a                	mv	a0,s2
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	490080e7          	jalr	1168(ra) # 80003838 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053b0:	40d0                	lw	a2,4(s1)
    800053b2:	00003597          	auipc	a1,0x3
    800053b6:	3e658593          	addi	a1,a1,998 # 80008798 <syscalls+0x2c0>
    800053ba:	8526                	mv	a0,s1
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	c34080e7          	jalr	-972(ra) # 80003ff0 <dirlink>
    800053c4:	00054f63          	bltz	a0,800053e2 <create+0x144>
    800053c8:	00492603          	lw	a2,4(s2)
    800053cc:	00003597          	auipc	a1,0x3
    800053d0:	3d458593          	addi	a1,a1,980 # 800087a0 <syscalls+0x2c8>
    800053d4:	8526                	mv	a0,s1
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	c1a080e7          	jalr	-998(ra) # 80003ff0 <dirlink>
    800053de:	f80557e3          	bgez	a0,8000536c <create+0xce>
      panic("create dots");
    800053e2:	00003517          	auipc	a0,0x3
    800053e6:	3c650513          	addi	a0,a0,966 # 800087a8 <syscalls+0x2d0>
    800053ea:	ffffb097          	auipc	ra,0xffffb
    800053ee:	15e080e7          	jalr	350(ra) # 80000548 <panic>
    panic("create: dirlink");
    800053f2:	00003517          	auipc	a0,0x3
    800053f6:	3c650513          	addi	a0,a0,966 # 800087b8 <syscalls+0x2e0>
    800053fa:	ffffb097          	auipc	ra,0xffffb
    800053fe:	14e080e7          	jalr	334(ra) # 80000548 <panic>
    return 0;
    80005402:	84aa                	mv	s1,a0
    80005404:	b731                	j	80005310 <create+0x72>

0000000080005406 <sys_dup>:
{
    80005406:	7179                	addi	sp,sp,-48
    80005408:	f406                	sd	ra,40(sp)
    8000540a:	f022                	sd	s0,32(sp)
    8000540c:	ec26                	sd	s1,24(sp)
    8000540e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005410:	fd840613          	addi	a2,s0,-40
    80005414:	4581                	li	a1,0
    80005416:	4501                	li	a0,0
    80005418:	00000097          	auipc	ra,0x0
    8000541c:	ddc080e7          	jalr	-548(ra) # 800051f4 <argfd>
    return -1;
    80005420:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005422:	02054363          	bltz	a0,80005448 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005426:	fd843503          	ld	a0,-40(s0)
    8000542a:	00000097          	auipc	ra,0x0
    8000542e:	e32080e7          	jalr	-462(ra) # 8000525c <fdalloc>
    80005432:	84aa                	mv	s1,a0
    return -1;
    80005434:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005436:	00054963          	bltz	a0,80005448 <sys_dup+0x42>
  filedup(f);
    8000543a:	fd843503          	ld	a0,-40(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	300080e7          	jalr	768(ra) # 8000473e <filedup>
  return fd;
    80005446:	87a6                	mv	a5,s1
}
    80005448:	853e                	mv	a0,a5
    8000544a:	70a2                	ld	ra,40(sp)
    8000544c:	7402                	ld	s0,32(sp)
    8000544e:	64e2                	ld	s1,24(sp)
    80005450:	6145                	addi	sp,sp,48
    80005452:	8082                	ret

0000000080005454 <sys_read>:
{
    80005454:	7179                	addi	sp,sp,-48
    80005456:	f406                	sd	ra,40(sp)
    80005458:	f022                	sd	s0,32(sp)
    8000545a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000545c:	fe840613          	addi	a2,s0,-24
    80005460:	4581                	li	a1,0
    80005462:	4501                	li	a0,0
    80005464:	00000097          	auipc	ra,0x0
    80005468:	d90080e7          	jalr	-624(ra) # 800051f4 <argfd>
    return -1;
    8000546c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000546e:	04054163          	bltz	a0,800054b0 <sys_read+0x5c>
    80005472:	fe440593          	addi	a1,s0,-28
    80005476:	4509                	li	a0,2
    80005478:	ffffe097          	auipc	ra,0xffffe
    8000547c:	918080e7          	jalr	-1768(ra) # 80002d90 <argint>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005482:	02054763          	bltz	a0,800054b0 <sys_read+0x5c>
    80005486:	fd840593          	addi	a1,s0,-40
    8000548a:	4505                	li	a0,1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	926080e7          	jalr	-1754(ra) # 80002db2 <argaddr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005496:	00054d63          	bltz	a0,800054b0 <sys_read+0x5c>
  return fileread(f, p, n);
    8000549a:	fe442603          	lw	a2,-28(s0)
    8000549e:	fd843583          	ld	a1,-40(s0)
    800054a2:	fe843503          	ld	a0,-24(s0)
    800054a6:	fffff097          	auipc	ra,0xfffff
    800054aa:	424080e7          	jalr	1060(ra) # 800048ca <fileread>
    800054ae:	87aa                	mv	a5,a0
}
    800054b0:	853e                	mv	a0,a5
    800054b2:	70a2                	ld	ra,40(sp)
    800054b4:	7402                	ld	s0,32(sp)
    800054b6:	6145                	addi	sp,sp,48
    800054b8:	8082                	ret

00000000800054ba <sys_write>:
{
    800054ba:	7179                	addi	sp,sp,-48
    800054bc:	f406                	sd	ra,40(sp)
    800054be:	f022                	sd	s0,32(sp)
    800054c0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054c2:	fe840613          	addi	a2,s0,-24
    800054c6:	4581                	li	a1,0
    800054c8:	4501                	li	a0,0
    800054ca:	00000097          	auipc	ra,0x0
    800054ce:	d2a080e7          	jalr	-726(ra) # 800051f4 <argfd>
    return -1;
    800054d2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054d4:	04054163          	bltz	a0,80005516 <sys_write+0x5c>
    800054d8:	fe440593          	addi	a1,s0,-28
    800054dc:	4509                	li	a0,2
    800054de:	ffffe097          	auipc	ra,0xffffe
    800054e2:	8b2080e7          	jalr	-1870(ra) # 80002d90 <argint>
    return -1;
    800054e6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e8:	02054763          	bltz	a0,80005516 <sys_write+0x5c>
    800054ec:	fd840593          	addi	a1,s0,-40
    800054f0:	4505                	li	a0,1
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	8c0080e7          	jalr	-1856(ra) # 80002db2 <argaddr>
    return -1;
    800054fa:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054fc:	00054d63          	bltz	a0,80005516 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005500:	fe442603          	lw	a2,-28(s0)
    80005504:	fd843583          	ld	a1,-40(s0)
    80005508:	fe843503          	ld	a0,-24(s0)
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	480080e7          	jalr	1152(ra) # 8000498c <filewrite>
    80005514:	87aa                	mv	a5,a0
}
    80005516:	853e                	mv	a0,a5
    80005518:	70a2                	ld	ra,40(sp)
    8000551a:	7402                	ld	s0,32(sp)
    8000551c:	6145                	addi	sp,sp,48
    8000551e:	8082                	ret

0000000080005520 <sys_close>:
{
    80005520:	1101                	addi	sp,sp,-32
    80005522:	ec06                	sd	ra,24(sp)
    80005524:	e822                	sd	s0,16(sp)
    80005526:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005528:	fe040613          	addi	a2,s0,-32
    8000552c:	fec40593          	addi	a1,s0,-20
    80005530:	4501                	li	a0,0
    80005532:	00000097          	auipc	ra,0x0
    80005536:	cc2080e7          	jalr	-830(ra) # 800051f4 <argfd>
    return -1;
    8000553a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000553c:	02054463          	bltz	a0,80005564 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005540:	ffffc097          	auipc	ra,0xffffc
    80005544:	5d6080e7          	jalr	1494(ra) # 80001b16 <myproc>
    80005548:	fec42783          	lw	a5,-20(s0)
    8000554c:	07e9                	addi	a5,a5,26
    8000554e:	078e                	slli	a5,a5,0x3
    80005550:	97aa                	add	a5,a5,a0
    80005552:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005556:	fe043503          	ld	a0,-32(s0)
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	236080e7          	jalr	566(ra) # 80004790 <fileclose>
  return 0;
    80005562:	4781                	li	a5,0
}
    80005564:	853e                	mv	a0,a5
    80005566:	60e2                	ld	ra,24(sp)
    80005568:	6442                	ld	s0,16(sp)
    8000556a:	6105                	addi	sp,sp,32
    8000556c:	8082                	ret

000000008000556e <sys_fstat>:
{
    8000556e:	1101                	addi	sp,sp,-32
    80005570:	ec06                	sd	ra,24(sp)
    80005572:	e822                	sd	s0,16(sp)
    80005574:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005576:	fe840613          	addi	a2,s0,-24
    8000557a:	4581                	li	a1,0
    8000557c:	4501                	li	a0,0
    8000557e:	00000097          	auipc	ra,0x0
    80005582:	c76080e7          	jalr	-906(ra) # 800051f4 <argfd>
    return -1;
    80005586:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005588:	02054563          	bltz	a0,800055b2 <sys_fstat+0x44>
    8000558c:	fe040593          	addi	a1,s0,-32
    80005590:	4505                	li	a0,1
    80005592:	ffffe097          	auipc	ra,0xffffe
    80005596:	820080e7          	jalr	-2016(ra) # 80002db2 <argaddr>
    return -1;
    8000559a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000559c:	00054b63          	bltz	a0,800055b2 <sys_fstat+0x44>
  return filestat(f, st);
    800055a0:	fe043583          	ld	a1,-32(s0)
    800055a4:	fe843503          	ld	a0,-24(s0)
    800055a8:	fffff097          	auipc	ra,0xfffff
    800055ac:	2b0080e7          	jalr	688(ra) # 80004858 <filestat>
    800055b0:	87aa                	mv	a5,a0
}
    800055b2:	853e                	mv	a0,a5
    800055b4:	60e2                	ld	ra,24(sp)
    800055b6:	6442                	ld	s0,16(sp)
    800055b8:	6105                	addi	sp,sp,32
    800055ba:	8082                	ret

00000000800055bc <sys_link>:
{
    800055bc:	7169                	addi	sp,sp,-304
    800055be:	f606                	sd	ra,296(sp)
    800055c0:	f222                	sd	s0,288(sp)
    800055c2:	ee26                	sd	s1,280(sp)
    800055c4:	ea4a                	sd	s2,272(sp)
    800055c6:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055c8:	08000613          	li	a2,128
    800055cc:	ed040593          	addi	a1,s0,-304
    800055d0:	4501                	li	a0,0
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	802080e7          	jalr	-2046(ra) # 80002dd4 <argstr>
    return -1;
    800055da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055dc:	10054e63          	bltz	a0,800056f8 <sys_link+0x13c>
    800055e0:	08000613          	li	a2,128
    800055e4:	f5040593          	addi	a1,s0,-176
    800055e8:	4505                	li	a0,1
    800055ea:	ffffd097          	auipc	ra,0xffffd
    800055ee:	7ea080e7          	jalr	2026(ra) # 80002dd4 <argstr>
    return -1;
    800055f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055f4:	10054263          	bltz	a0,800056f8 <sys_link+0x13c>
  begin_op();
    800055f8:	fffff097          	auipc	ra,0xfffff
    800055fc:	cc6080e7          	jalr	-826(ra) # 800042be <begin_op>
  if((ip = namei(old)) == 0){
    80005600:	ed040513          	addi	a0,s0,-304
    80005604:	fffff097          	auipc	ra,0xfffff
    80005608:	aae080e7          	jalr	-1362(ra) # 800040b2 <namei>
    8000560c:	84aa                	mv	s1,a0
    8000560e:	c551                	beqz	a0,8000569a <sys_link+0xde>
  ilock(ip);
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	2f2080e7          	jalr	754(ra) # 80003902 <ilock>
  if(ip->type == T_DIR){
    80005618:	04449703          	lh	a4,68(s1)
    8000561c:	4785                	li	a5,1
    8000561e:	08f70463          	beq	a4,a5,800056a6 <sys_link+0xea>
  ip->nlink++;
    80005622:	04a4d783          	lhu	a5,74(s1)
    80005626:	2785                	addiw	a5,a5,1
    80005628:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	20a080e7          	jalr	522(ra) # 80003838 <iupdate>
  iunlock(ip);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	38c080e7          	jalr	908(ra) # 800039c4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005640:	fd040593          	addi	a1,s0,-48
    80005644:	f5040513          	addi	a0,s0,-176
    80005648:	fffff097          	auipc	ra,0xfffff
    8000564c:	a88080e7          	jalr	-1400(ra) # 800040d0 <nameiparent>
    80005650:	892a                	mv	s2,a0
    80005652:	c935                	beqz	a0,800056c6 <sys_link+0x10a>
  ilock(dp);
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	2ae080e7          	jalr	686(ra) # 80003902 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000565c:	00092703          	lw	a4,0(s2)
    80005660:	409c                	lw	a5,0(s1)
    80005662:	04f71d63          	bne	a4,a5,800056bc <sys_link+0x100>
    80005666:	40d0                	lw	a2,4(s1)
    80005668:	fd040593          	addi	a1,s0,-48
    8000566c:	854a                	mv	a0,s2
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	982080e7          	jalr	-1662(ra) # 80003ff0 <dirlink>
    80005676:	04054363          	bltz	a0,800056bc <sys_link+0x100>
  iunlockput(dp);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	4e8080e7          	jalr	1256(ra) # 80003b64 <iunlockput>
  iput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	436080e7          	jalr	1078(ra) # 80003abc <iput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	cb0080e7          	jalr	-848(ra) # 8000433e <end_op>
  return 0;
    80005696:	4781                	li	a5,0
    80005698:	a085                	j	800056f8 <sys_link+0x13c>
    end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	ca4080e7          	jalr	-860(ra) # 8000433e <end_op>
    return -1;
    800056a2:	57fd                	li	a5,-1
    800056a4:	a891                	j	800056f8 <sys_link+0x13c>
    iunlockput(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	4bc080e7          	jalr	1212(ra) # 80003b64 <iunlockput>
    end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	c8e080e7          	jalr	-882(ra) # 8000433e <end_op>
    return -1;
    800056b8:	57fd                	li	a5,-1
    800056ba:	a83d                	j	800056f8 <sys_link+0x13c>
    iunlockput(dp);
    800056bc:	854a                	mv	a0,s2
    800056be:	ffffe097          	auipc	ra,0xffffe
    800056c2:	4a6080e7          	jalr	1190(ra) # 80003b64 <iunlockput>
  ilock(ip);
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	23a080e7          	jalr	570(ra) # 80003902 <ilock>
  ip->nlink--;
    800056d0:	04a4d783          	lhu	a5,74(s1)
    800056d4:	37fd                	addiw	a5,a5,-1
    800056d6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	15c080e7          	jalr	348(ra) # 80003838 <iupdate>
  iunlockput(ip);
    800056e4:	8526                	mv	a0,s1
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	47e080e7          	jalr	1150(ra) # 80003b64 <iunlockput>
  end_op();
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	c50080e7          	jalr	-944(ra) # 8000433e <end_op>
  return -1;
    800056f6:	57fd                	li	a5,-1
}
    800056f8:	853e                	mv	a0,a5
    800056fa:	70b2                	ld	ra,296(sp)
    800056fc:	7412                	ld	s0,288(sp)
    800056fe:	64f2                	ld	s1,280(sp)
    80005700:	6952                	ld	s2,272(sp)
    80005702:	6155                	addi	sp,sp,304
    80005704:	8082                	ret

0000000080005706 <sys_unlink>:
{
    80005706:	7151                	addi	sp,sp,-240
    80005708:	f586                	sd	ra,232(sp)
    8000570a:	f1a2                	sd	s0,224(sp)
    8000570c:	eda6                	sd	s1,216(sp)
    8000570e:	e9ca                	sd	s2,208(sp)
    80005710:	e5ce                	sd	s3,200(sp)
    80005712:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005714:	08000613          	li	a2,128
    80005718:	f3040593          	addi	a1,s0,-208
    8000571c:	4501                	li	a0,0
    8000571e:	ffffd097          	auipc	ra,0xffffd
    80005722:	6b6080e7          	jalr	1718(ra) # 80002dd4 <argstr>
    80005726:	18054163          	bltz	a0,800058a8 <sys_unlink+0x1a2>
  begin_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	b94080e7          	jalr	-1132(ra) # 800042be <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005732:	fb040593          	addi	a1,s0,-80
    80005736:	f3040513          	addi	a0,s0,-208
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	996080e7          	jalr	-1642(ra) # 800040d0 <nameiparent>
    80005742:	84aa                	mv	s1,a0
    80005744:	c979                	beqz	a0,8000581a <sys_unlink+0x114>
  ilock(dp);
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	1bc080e7          	jalr	444(ra) # 80003902 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000574e:	00003597          	auipc	a1,0x3
    80005752:	04a58593          	addi	a1,a1,74 # 80008798 <syscalls+0x2c0>
    80005756:	fb040513          	addi	a0,s0,-80
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	66c080e7          	jalr	1644(ra) # 80003dc6 <namecmp>
    80005762:	14050a63          	beqz	a0,800058b6 <sys_unlink+0x1b0>
    80005766:	00003597          	auipc	a1,0x3
    8000576a:	03a58593          	addi	a1,a1,58 # 800087a0 <syscalls+0x2c8>
    8000576e:	fb040513          	addi	a0,s0,-80
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	654080e7          	jalr	1620(ra) # 80003dc6 <namecmp>
    8000577a:	12050e63          	beqz	a0,800058b6 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000577e:	f2c40613          	addi	a2,s0,-212
    80005782:	fb040593          	addi	a1,s0,-80
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	658080e7          	jalr	1624(ra) # 80003de0 <dirlookup>
    80005790:	892a                	mv	s2,a0
    80005792:	12050263          	beqz	a0,800058b6 <sys_unlink+0x1b0>
  ilock(ip);
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	16c080e7          	jalr	364(ra) # 80003902 <ilock>
  if(ip->nlink < 1)
    8000579e:	04a91783          	lh	a5,74(s2)
    800057a2:	08f05263          	blez	a5,80005826 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057a6:	04491703          	lh	a4,68(s2)
    800057aa:	4785                	li	a5,1
    800057ac:	08f70563          	beq	a4,a5,80005836 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057b0:	4641                	li	a2,16
    800057b2:	4581                	li	a1,0
    800057b4:	fc040513          	addi	a0,s0,-64
    800057b8:	ffffb097          	auipc	ra,0xffffb
    800057bc:	554080e7          	jalr	1364(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057c0:	4741                	li	a4,16
    800057c2:	f2c42683          	lw	a3,-212(s0)
    800057c6:	fc040613          	addi	a2,s0,-64
    800057ca:	4581                	li	a1,0
    800057cc:	8526                	mv	a0,s1
    800057ce:	ffffe097          	auipc	ra,0xffffe
    800057d2:	4de080e7          	jalr	1246(ra) # 80003cac <writei>
    800057d6:	47c1                	li	a5,16
    800057d8:	0af51563          	bne	a0,a5,80005882 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057dc:	04491703          	lh	a4,68(s2)
    800057e0:	4785                	li	a5,1
    800057e2:	0af70863          	beq	a4,a5,80005892 <sys_unlink+0x18c>
  iunlockput(dp);
    800057e6:	8526                	mv	a0,s1
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	37c080e7          	jalr	892(ra) # 80003b64 <iunlockput>
  ip->nlink--;
    800057f0:	04a95783          	lhu	a5,74(s2)
    800057f4:	37fd                	addiw	a5,a5,-1
    800057f6:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057fa:	854a                	mv	a0,s2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	03c080e7          	jalr	60(ra) # 80003838 <iupdate>
  iunlockput(ip);
    80005804:	854a                	mv	a0,s2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	35e080e7          	jalr	862(ra) # 80003b64 <iunlockput>
  end_op();
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	b30080e7          	jalr	-1232(ra) # 8000433e <end_op>
  return 0;
    80005816:	4501                	li	a0,0
    80005818:	a84d                	j	800058ca <sys_unlink+0x1c4>
    end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	b24080e7          	jalr	-1244(ra) # 8000433e <end_op>
    return -1;
    80005822:	557d                	li	a0,-1
    80005824:	a05d                	j	800058ca <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005826:	00003517          	auipc	a0,0x3
    8000582a:	fa250513          	addi	a0,a0,-94 # 800087c8 <syscalls+0x2f0>
    8000582e:	ffffb097          	auipc	ra,0xffffb
    80005832:	d1a080e7          	jalr	-742(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005836:	04c92703          	lw	a4,76(s2)
    8000583a:	02000793          	li	a5,32
    8000583e:	f6e7f9e3          	bgeu	a5,a4,800057b0 <sys_unlink+0xaa>
    80005842:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005846:	4741                	li	a4,16
    80005848:	86ce                	mv	a3,s3
    8000584a:	f1840613          	addi	a2,s0,-232
    8000584e:	4581                	li	a1,0
    80005850:	854a                	mv	a0,s2
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	364080e7          	jalr	868(ra) # 80003bb6 <readi>
    8000585a:	47c1                	li	a5,16
    8000585c:	00f51b63          	bne	a0,a5,80005872 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005860:	f1845783          	lhu	a5,-232(s0)
    80005864:	e7a1                	bnez	a5,800058ac <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005866:	29c1                	addiw	s3,s3,16
    80005868:	04c92783          	lw	a5,76(s2)
    8000586c:	fcf9ede3          	bltu	s3,a5,80005846 <sys_unlink+0x140>
    80005870:	b781                	j	800057b0 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005872:	00003517          	auipc	a0,0x3
    80005876:	f6e50513          	addi	a0,a0,-146 # 800087e0 <syscalls+0x308>
    8000587a:	ffffb097          	auipc	ra,0xffffb
    8000587e:	cce080e7          	jalr	-818(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005882:	00003517          	auipc	a0,0x3
    80005886:	f7650513          	addi	a0,a0,-138 # 800087f8 <syscalls+0x320>
    8000588a:	ffffb097          	auipc	ra,0xffffb
    8000588e:	cbe080e7          	jalr	-834(ra) # 80000548 <panic>
    dp->nlink--;
    80005892:	04a4d783          	lhu	a5,74(s1)
    80005896:	37fd                	addiw	a5,a5,-1
    80005898:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	f9a080e7          	jalr	-102(ra) # 80003838 <iupdate>
    800058a6:	b781                	j	800057e6 <sys_unlink+0xe0>
    return -1;
    800058a8:	557d                	li	a0,-1
    800058aa:	a005                	j	800058ca <sys_unlink+0x1c4>
    iunlockput(ip);
    800058ac:	854a                	mv	a0,s2
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	2b6080e7          	jalr	694(ra) # 80003b64 <iunlockput>
  iunlockput(dp);
    800058b6:	8526                	mv	a0,s1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	2ac080e7          	jalr	684(ra) # 80003b64 <iunlockput>
  end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	a7e080e7          	jalr	-1410(ra) # 8000433e <end_op>
  return -1;
    800058c8:	557d                	li	a0,-1
}
    800058ca:	70ae                	ld	ra,232(sp)
    800058cc:	740e                	ld	s0,224(sp)
    800058ce:	64ee                	ld	s1,216(sp)
    800058d0:	694e                	ld	s2,208(sp)
    800058d2:	69ae                	ld	s3,200(sp)
    800058d4:	616d                	addi	sp,sp,240
    800058d6:	8082                	ret

00000000800058d8 <sys_open>:

uint64
sys_open(void)
{
    800058d8:	7131                	addi	sp,sp,-192
    800058da:	fd06                	sd	ra,184(sp)
    800058dc:	f922                	sd	s0,176(sp)
    800058de:	f526                	sd	s1,168(sp)
    800058e0:	f14a                	sd	s2,160(sp)
    800058e2:	ed4e                	sd	s3,152(sp)
    800058e4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	f5040593          	addi	a1,s0,-176
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	4e4080e7          	jalr	1252(ra) # 80002dd4 <argstr>
    return -1;
    800058f8:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800058fa:	0c054163          	bltz	a0,800059bc <sys_open+0xe4>
    800058fe:	f4c40593          	addi	a1,s0,-180
    80005902:	4505                	li	a0,1
    80005904:	ffffd097          	auipc	ra,0xffffd
    80005908:	48c080e7          	jalr	1164(ra) # 80002d90 <argint>
    8000590c:	0a054863          	bltz	a0,800059bc <sys_open+0xe4>

  begin_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	9ae080e7          	jalr	-1618(ra) # 800042be <begin_op>

  if(omode & O_CREATE){
    80005918:	f4c42783          	lw	a5,-180(s0)
    8000591c:	2007f793          	andi	a5,a5,512
    80005920:	cbdd                	beqz	a5,800059d6 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005922:	4681                	li	a3,0
    80005924:	4601                	li	a2,0
    80005926:	4589                	li	a1,2
    80005928:	f5040513          	addi	a0,s0,-176
    8000592c:	00000097          	auipc	ra,0x0
    80005930:	972080e7          	jalr	-1678(ra) # 8000529e <create>
    80005934:	892a                	mv	s2,a0
    if(ip == 0){
    80005936:	c959                	beqz	a0,800059cc <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005938:	04491703          	lh	a4,68(s2)
    8000593c:	478d                	li	a5,3
    8000593e:	00f71763          	bne	a4,a5,8000594c <sys_open+0x74>
    80005942:	04695703          	lhu	a4,70(s2)
    80005946:	47a5                	li	a5,9
    80005948:	0ce7ec63          	bltu	a5,a4,80005a20 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	d88080e7          	jalr	-632(ra) # 800046d4 <filealloc>
    80005954:	89aa                	mv	s3,a0
    80005956:	10050263          	beqz	a0,80005a5a <sys_open+0x182>
    8000595a:	00000097          	auipc	ra,0x0
    8000595e:	902080e7          	jalr	-1790(ra) # 8000525c <fdalloc>
    80005962:	84aa                	mv	s1,a0
    80005964:	0e054663          	bltz	a0,80005a50 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005968:	04491703          	lh	a4,68(s2)
    8000596c:	478d                	li	a5,3
    8000596e:	0cf70463          	beq	a4,a5,80005a36 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005972:	4789                	li	a5,2
    80005974:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005978:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000597c:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005980:	f4c42783          	lw	a5,-180(s0)
    80005984:	0017c713          	xori	a4,a5,1
    80005988:	8b05                	andi	a4,a4,1
    8000598a:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000598e:	0037f713          	andi	a4,a5,3
    80005992:	00e03733          	snez	a4,a4
    80005996:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    8000599a:	4007f793          	andi	a5,a5,1024
    8000599e:	c791                	beqz	a5,800059aa <sys_open+0xd2>
    800059a0:	04491703          	lh	a4,68(s2)
    800059a4:	4789                	li	a5,2
    800059a6:	08f70f63          	beq	a4,a5,80005a44 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059aa:	854a                	mv	a0,s2
    800059ac:	ffffe097          	auipc	ra,0xffffe
    800059b0:	018080e7          	jalr	24(ra) # 800039c4 <iunlock>
  end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	98a080e7          	jalr	-1654(ra) # 8000433e <end_op>

  return fd;
}
    800059bc:	8526                	mv	a0,s1
    800059be:	70ea                	ld	ra,184(sp)
    800059c0:	744a                	ld	s0,176(sp)
    800059c2:	74aa                	ld	s1,168(sp)
    800059c4:	790a                	ld	s2,160(sp)
    800059c6:	69ea                	ld	s3,152(sp)
    800059c8:	6129                	addi	sp,sp,192
    800059ca:	8082                	ret
      end_op();
    800059cc:	fffff097          	auipc	ra,0xfffff
    800059d0:	972080e7          	jalr	-1678(ra) # 8000433e <end_op>
      return -1;
    800059d4:	b7e5                	j	800059bc <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059d6:	f5040513          	addi	a0,s0,-176
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	6d8080e7          	jalr	1752(ra) # 800040b2 <namei>
    800059e2:	892a                	mv	s2,a0
    800059e4:	c905                	beqz	a0,80005a14 <sys_open+0x13c>
    ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	f1c080e7          	jalr	-228(ra) # 80003902 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059ee:	04491703          	lh	a4,68(s2)
    800059f2:	4785                	li	a5,1
    800059f4:	f4f712e3          	bne	a4,a5,80005938 <sys_open+0x60>
    800059f8:	f4c42783          	lw	a5,-180(s0)
    800059fc:	dba1                	beqz	a5,8000594c <sys_open+0x74>
      iunlockput(ip);
    800059fe:	854a                	mv	a0,s2
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	164080e7          	jalr	356(ra) # 80003b64 <iunlockput>
      end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	936080e7          	jalr	-1738(ra) # 8000433e <end_op>
      return -1;
    80005a10:	54fd                	li	s1,-1
    80005a12:	b76d                	j	800059bc <sys_open+0xe4>
      end_op();
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	92a080e7          	jalr	-1750(ra) # 8000433e <end_op>
      return -1;
    80005a1c:	54fd                	li	s1,-1
    80005a1e:	bf79                	j	800059bc <sys_open+0xe4>
    iunlockput(ip);
    80005a20:	854a                	mv	a0,s2
    80005a22:	ffffe097          	auipc	ra,0xffffe
    80005a26:	142080e7          	jalr	322(ra) # 80003b64 <iunlockput>
    end_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	914080e7          	jalr	-1772(ra) # 8000433e <end_op>
    return -1;
    80005a32:	54fd                	li	s1,-1
    80005a34:	b761                	j	800059bc <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a36:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a3a:	04691783          	lh	a5,70(s2)
    80005a3e:	02f99223          	sh	a5,36(s3)
    80005a42:	bf2d                	j	8000597c <sys_open+0xa4>
    itrunc(ip);
    80005a44:	854a                	mv	a0,s2
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	fca080e7          	jalr	-54(ra) # 80003a10 <itrunc>
    80005a4e:	bfb1                	j	800059aa <sys_open+0xd2>
      fileclose(f);
    80005a50:	854e                	mv	a0,s3
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	d3e080e7          	jalr	-706(ra) # 80004790 <fileclose>
    iunlockput(ip);
    80005a5a:	854a                	mv	a0,s2
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	108080e7          	jalr	264(ra) # 80003b64 <iunlockput>
    end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	8da080e7          	jalr	-1830(ra) # 8000433e <end_op>
    return -1;
    80005a6c:	54fd                	li	s1,-1
    80005a6e:	b7b9                	j	800059bc <sys_open+0xe4>

0000000080005a70 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a70:	7175                	addi	sp,sp,-144
    80005a72:	e506                	sd	ra,136(sp)
    80005a74:	e122                	sd	s0,128(sp)
    80005a76:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	846080e7          	jalr	-1978(ra) # 800042be <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a80:	08000613          	li	a2,128
    80005a84:	f7040593          	addi	a1,s0,-144
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	34a080e7          	jalr	842(ra) # 80002dd4 <argstr>
    80005a92:	02054963          	bltz	a0,80005ac4 <sys_mkdir+0x54>
    80005a96:	4681                	li	a3,0
    80005a98:	4601                	li	a2,0
    80005a9a:	4585                	li	a1,1
    80005a9c:	f7040513          	addi	a0,s0,-144
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	7fe080e7          	jalr	2046(ra) # 8000529e <create>
    80005aa8:	cd11                	beqz	a0,80005ac4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	0ba080e7          	jalr	186(ra) # 80003b64 <iunlockput>
  end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	88c080e7          	jalr	-1908(ra) # 8000433e <end_op>
  return 0;
    80005aba:	4501                	li	a0,0
}
    80005abc:	60aa                	ld	ra,136(sp)
    80005abe:	640a                	ld	s0,128(sp)
    80005ac0:	6149                	addi	sp,sp,144
    80005ac2:	8082                	ret
    end_op();
    80005ac4:	fffff097          	auipc	ra,0xfffff
    80005ac8:	87a080e7          	jalr	-1926(ra) # 8000433e <end_op>
    return -1;
    80005acc:	557d                	li	a0,-1
    80005ace:	b7fd                	j	80005abc <sys_mkdir+0x4c>

0000000080005ad0 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ad0:	7135                	addi	sp,sp,-160
    80005ad2:	ed06                	sd	ra,152(sp)
    80005ad4:	e922                	sd	s0,144(sp)
    80005ad6:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	7e6080e7          	jalr	2022(ra) # 800042be <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ae0:	08000613          	li	a2,128
    80005ae4:	f7040593          	addi	a1,s0,-144
    80005ae8:	4501                	li	a0,0
    80005aea:	ffffd097          	auipc	ra,0xffffd
    80005aee:	2ea080e7          	jalr	746(ra) # 80002dd4 <argstr>
    80005af2:	04054a63          	bltz	a0,80005b46 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005af6:	f6c40593          	addi	a1,s0,-148
    80005afa:	4505                	li	a0,1
    80005afc:	ffffd097          	auipc	ra,0xffffd
    80005b00:	294080e7          	jalr	660(ra) # 80002d90 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b04:	04054163          	bltz	a0,80005b46 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b08:	f6840593          	addi	a1,s0,-152
    80005b0c:	4509                	li	a0,2
    80005b0e:	ffffd097          	auipc	ra,0xffffd
    80005b12:	282080e7          	jalr	642(ra) # 80002d90 <argint>
     argint(1, &major) < 0 ||
    80005b16:	02054863          	bltz	a0,80005b46 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b1a:	f6841683          	lh	a3,-152(s0)
    80005b1e:	f6c41603          	lh	a2,-148(s0)
    80005b22:	458d                	li	a1,3
    80005b24:	f7040513          	addi	a0,s0,-144
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	776080e7          	jalr	1910(ra) # 8000529e <create>
     argint(2, &minor) < 0 ||
    80005b30:	c919                	beqz	a0,80005b46 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	032080e7          	jalr	50(ra) # 80003b64 <iunlockput>
  end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	804080e7          	jalr	-2044(ra) # 8000433e <end_op>
  return 0;
    80005b42:	4501                	li	a0,0
    80005b44:	a031                	j	80005b50 <sys_mknod+0x80>
    end_op();
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	7f8080e7          	jalr	2040(ra) # 8000433e <end_op>
    return -1;
    80005b4e:	557d                	li	a0,-1
}
    80005b50:	60ea                	ld	ra,152(sp)
    80005b52:	644a                	ld	s0,144(sp)
    80005b54:	610d                	addi	sp,sp,160
    80005b56:	8082                	ret

0000000080005b58 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b58:	7135                	addi	sp,sp,-160
    80005b5a:	ed06                	sd	ra,152(sp)
    80005b5c:	e922                	sd	s0,144(sp)
    80005b5e:	e526                	sd	s1,136(sp)
    80005b60:	e14a                	sd	s2,128(sp)
    80005b62:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b64:	ffffc097          	auipc	ra,0xffffc
    80005b68:	fb2080e7          	jalr	-78(ra) # 80001b16 <myproc>
    80005b6c:	892a                	mv	s2,a0
  
  begin_op();
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	750080e7          	jalr	1872(ra) # 800042be <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b76:	08000613          	li	a2,128
    80005b7a:	f6040593          	addi	a1,s0,-160
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	254080e7          	jalr	596(ra) # 80002dd4 <argstr>
    80005b88:	04054b63          	bltz	a0,80005bde <sys_chdir+0x86>
    80005b8c:	f6040513          	addi	a0,s0,-160
    80005b90:	ffffe097          	auipc	ra,0xffffe
    80005b94:	522080e7          	jalr	1314(ra) # 800040b2 <namei>
    80005b98:	84aa                	mv	s1,a0
    80005b9a:	c131                	beqz	a0,80005bde <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	d66080e7          	jalr	-666(ra) # 80003902 <ilock>
  if(ip->type != T_DIR){
    80005ba4:	04449703          	lh	a4,68(s1)
    80005ba8:	4785                	li	a5,1
    80005baa:	04f71063          	bne	a4,a5,80005bea <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bae:	8526                	mv	a0,s1
    80005bb0:	ffffe097          	auipc	ra,0xffffe
    80005bb4:	e14080e7          	jalr	-492(ra) # 800039c4 <iunlock>
  iput(p->cwd);
    80005bb8:	15093503          	ld	a0,336(s2)
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	f00080e7          	jalr	-256(ra) # 80003abc <iput>
  end_op();
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	77a080e7          	jalr	1914(ra) # 8000433e <end_op>
  p->cwd = ip;
    80005bcc:	14993823          	sd	s1,336(s2)
  return 0;
    80005bd0:	4501                	li	a0,0
}
    80005bd2:	60ea                	ld	ra,152(sp)
    80005bd4:	644a                	ld	s0,144(sp)
    80005bd6:	64aa                	ld	s1,136(sp)
    80005bd8:	690a                	ld	s2,128(sp)
    80005bda:	610d                	addi	sp,sp,160
    80005bdc:	8082                	ret
    end_op();
    80005bde:	ffffe097          	auipc	ra,0xffffe
    80005be2:	760080e7          	jalr	1888(ra) # 8000433e <end_op>
    return -1;
    80005be6:	557d                	li	a0,-1
    80005be8:	b7ed                	j	80005bd2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bea:	8526                	mv	a0,s1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	f78080e7          	jalr	-136(ra) # 80003b64 <iunlockput>
    end_op();
    80005bf4:	ffffe097          	auipc	ra,0xffffe
    80005bf8:	74a080e7          	jalr	1866(ra) # 8000433e <end_op>
    return -1;
    80005bfc:	557d                	li	a0,-1
    80005bfe:	bfd1                	j	80005bd2 <sys_chdir+0x7a>

0000000080005c00 <sys_exec>:

uint64
sys_exec(void)
{
    80005c00:	7145                	addi	sp,sp,-464
    80005c02:	e786                	sd	ra,456(sp)
    80005c04:	e3a2                	sd	s0,448(sp)
    80005c06:	ff26                	sd	s1,440(sp)
    80005c08:	fb4a                	sd	s2,432(sp)
    80005c0a:	f74e                	sd	s3,424(sp)
    80005c0c:	f352                	sd	s4,416(sp)
    80005c0e:	ef56                	sd	s5,408(sp)
    80005c10:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c12:	08000613          	li	a2,128
    80005c16:	f4040593          	addi	a1,s0,-192
    80005c1a:	4501                	li	a0,0
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	1b8080e7          	jalr	440(ra) # 80002dd4 <argstr>
    return -1;
    80005c24:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c26:	0c054a63          	bltz	a0,80005cfa <sys_exec+0xfa>
    80005c2a:	e3840593          	addi	a1,s0,-456
    80005c2e:	4505                	li	a0,1
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	182080e7          	jalr	386(ra) # 80002db2 <argaddr>
    80005c38:	0c054163          	bltz	a0,80005cfa <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c3c:	10000613          	li	a2,256
    80005c40:	4581                	li	a1,0
    80005c42:	e4040513          	addi	a0,s0,-448
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	0c6080e7          	jalr	198(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c4e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c52:	89a6                	mv	s3,s1
    80005c54:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c56:	02000a13          	li	s4,32
    80005c5a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c5e:	00391513          	slli	a0,s2,0x3
    80005c62:	e3040593          	addi	a1,s0,-464
    80005c66:	e3843783          	ld	a5,-456(s0)
    80005c6a:	953e                	add	a0,a0,a5
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	08a080e7          	jalr	138(ra) # 80002cf6 <fetchaddr>
    80005c74:	02054a63          	bltz	a0,80005ca8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005c78:	e3043783          	ld	a5,-464(s0)
    80005c7c:	c3b9                	beqz	a5,80005cc2 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c7e:	ffffb097          	auipc	ra,0xffffb
    80005c82:	ea2080e7          	jalr	-350(ra) # 80000b20 <kalloc>
    80005c86:	85aa                	mv	a1,a0
    80005c88:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c8c:	cd11                	beqz	a0,80005ca8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c8e:	6605                	lui	a2,0x1
    80005c90:	e3043503          	ld	a0,-464(s0)
    80005c94:	ffffd097          	auipc	ra,0xffffd
    80005c98:	0b4080e7          	jalr	180(ra) # 80002d48 <fetchstr>
    80005c9c:	00054663          	bltz	a0,80005ca8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ca0:	0905                	addi	s2,s2,1
    80005ca2:	09a1                	addi	s3,s3,8
    80005ca4:	fb491be3          	bne	s2,s4,80005c5a <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ca8:	10048913          	addi	s2,s1,256
    80005cac:	6088                	ld	a0,0(s1)
    80005cae:	c529                	beqz	a0,80005cf8 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cb0:	ffffb097          	auipc	ra,0xffffb
    80005cb4:	d74080e7          	jalr	-652(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb8:	04a1                	addi	s1,s1,8
    80005cba:	ff2499e3          	bne	s1,s2,80005cac <sys_exec+0xac>
  return -1;
    80005cbe:	597d                	li	s2,-1
    80005cc0:	a82d                	j	80005cfa <sys_exec+0xfa>
      argv[i] = 0;
    80005cc2:	0a8e                	slli	s5,s5,0x3
    80005cc4:	fc040793          	addi	a5,s0,-64
    80005cc8:	9abe                	add	s5,s5,a5
    80005cca:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cce:	e4040593          	addi	a1,s0,-448
    80005cd2:	f4040513          	addi	a0,s0,-192
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	16a080e7          	jalr	362(ra) # 80004e40 <exec>
    80005cde:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce0:	10048993          	addi	s3,s1,256
    80005ce4:	6088                	ld	a0,0(s1)
    80005ce6:	c911                	beqz	a0,80005cfa <sys_exec+0xfa>
    kfree(argv[i]);
    80005ce8:	ffffb097          	auipc	ra,0xffffb
    80005cec:	d3c080e7          	jalr	-708(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf0:	04a1                	addi	s1,s1,8
    80005cf2:	ff3499e3          	bne	s1,s3,80005ce4 <sys_exec+0xe4>
    80005cf6:	a011                	j	80005cfa <sys_exec+0xfa>
  return -1;
    80005cf8:	597d                	li	s2,-1
}
    80005cfa:	854a                	mv	a0,s2
    80005cfc:	60be                	ld	ra,456(sp)
    80005cfe:	641e                	ld	s0,448(sp)
    80005d00:	74fa                	ld	s1,440(sp)
    80005d02:	795a                	ld	s2,432(sp)
    80005d04:	79ba                	ld	s3,424(sp)
    80005d06:	7a1a                	ld	s4,416(sp)
    80005d08:	6afa                	ld	s5,408(sp)
    80005d0a:	6179                	addi	sp,sp,464
    80005d0c:	8082                	ret

0000000080005d0e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d0e:	7139                	addi	sp,sp,-64
    80005d10:	fc06                	sd	ra,56(sp)
    80005d12:	f822                	sd	s0,48(sp)
    80005d14:	f426                	sd	s1,40(sp)
    80005d16:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d18:	ffffc097          	auipc	ra,0xffffc
    80005d1c:	dfe080e7          	jalr	-514(ra) # 80001b16 <myproc>
    80005d20:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d22:	fd840593          	addi	a1,s0,-40
    80005d26:	4501                	li	a0,0
    80005d28:	ffffd097          	auipc	ra,0xffffd
    80005d2c:	08a080e7          	jalr	138(ra) # 80002db2 <argaddr>
    return -1;
    80005d30:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d32:	0e054063          	bltz	a0,80005e12 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005d36:	fc840593          	addi	a1,s0,-56
    80005d3a:	fd040513          	addi	a0,s0,-48
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	da8080e7          	jalr	-600(ra) # 80004ae6 <pipealloc>
    return -1;
    80005d46:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d48:	0c054563          	bltz	a0,80005e12 <sys_pipe+0x104>
  fd0 = -1;
    80005d4c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d50:	fd043503          	ld	a0,-48(s0)
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	508080e7          	jalr	1288(ra) # 8000525c <fdalloc>
    80005d5c:	fca42223          	sw	a0,-60(s0)
    80005d60:	08054c63          	bltz	a0,80005df8 <sys_pipe+0xea>
    80005d64:	fc843503          	ld	a0,-56(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	4f4080e7          	jalr	1268(ra) # 8000525c <fdalloc>
    80005d70:	fca42023          	sw	a0,-64(s0)
    80005d74:	06054863          	bltz	a0,80005de4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d78:	4691                	li	a3,4
    80005d7a:	fc440613          	addi	a2,s0,-60
    80005d7e:	fd843583          	ld	a1,-40(s0)
    80005d82:	68a8                	ld	a0,80(s1)
    80005d84:	ffffc097          	auipc	ra,0xffffc
    80005d88:	960080e7          	jalr	-1696(ra) # 800016e4 <copyout>
    80005d8c:	02054063          	bltz	a0,80005dac <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d90:	4691                	li	a3,4
    80005d92:	fc040613          	addi	a2,s0,-64
    80005d96:	fd843583          	ld	a1,-40(s0)
    80005d9a:	0591                	addi	a1,a1,4
    80005d9c:	68a8                	ld	a0,80(s1)
    80005d9e:	ffffc097          	auipc	ra,0xffffc
    80005da2:	946080e7          	jalr	-1722(ra) # 800016e4 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da8:	06055563          	bgez	a0,80005e12 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005dac:	fc442783          	lw	a5,-60(s0)
    80005db0:	07e9                	addi	a5,a5,26
    80005db2:	078e                	slli	a5,a5,0x3
    80005db4:	97a6                	add	a5,a5,s1
    80005db6:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dba:	fc042503          	lw	a0,-64(s0)
    80005dbe:	0569                	addi	a0,a0,26
    80005dc0:	050e                	slli	a0,a0,0x3
    80005dc2:	9526                	add	a0,a0,s1
    80005dc4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005dc8:	fd043503          	ld	a0,-48(s0)
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	9c4080e7          	jalr	-1596(ra) # 80004790 <fileclose>
    fileclose(wf);
    80005dd4:	fc843503          	ld	a0,-56(s0)
    80005dd8:	fffff097          	auipc	ra,0xfffff
    80005ddc:	9b8080e7          	jalr	-1608(ra) # 80004790 <fileclose>
    return -1;
    80005de0:	57fd                	li	a5,-1
    80005de2:	a805                	j	80005e12 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005de4:	fc442783          	lw	a5,-60(s0)
    80005de8:	0007c863          	bltz	a5,80005df8 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005dec:	01a78513          	addi	a0,a5,26
    80005df0:	050e                	slli	a0,a0,0x3
    80005df2:	9526                	add	a0,a0,s1
    80005df4:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005df8:	fd043503          	ld	a0,-48(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	994080e7          	jalr	-1644(ra) # 80004790 <fileclose>
    fileclose(wf);
    80005e04:	fc843503          	ld	a0,-56(s0)
    80005e08:	fffff097          	auipc	ra,0xfffff
    80005e0c:	988080e7          	jalr	-1656(ra) # 80004790 <fileclose>
    return -1;
    80005e10:	57fd                	li	a5,-1
}
    80005e12:	853e                	mv	a0,a5
    80005e14:	70e2                	ld	ra,56(sp)
    80005e16:	7442                	ld	s0,48(sp)
    80005e18:	74a2                	ld	s1,40(sp)
    80005e1a:	6121                	addi	sp,sp,64
    80005e1c:	8082                	ret
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	d63fc0ef          	jal	ra,80002bc2 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	710c                	ld	a1,32(a0)
    80005ebc:	7510                	ld	a2,40(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	bf2080e7          	jalr	-1038(ra) # 80001aea <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	bba080e7          	jalr	-1094(ra) # 80001aea <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	b92080e7          	jalr	-1134(ra) # 80001aea <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005f84:	0001d797          	auipc	a5,0x1d
    80005f88:	07c78793          	addi	a5,a5,124 # 80023000 <disk>
    80005f8c:	00a78733          	add	a4,a5,a0
    80005f90:	6789                	lui	a5,0x2
    80005f92:	97ba                	add	a5,a5,a4
    80005f94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005f98:	eba1                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005f9a:	00451713          	slli	a4,a0,0x4
    80005f9e:	0001f797          	auipc	a5,0x1f
    80005fa2:	0627b783          	ld	a5,98(a5) # 80025000 <disk+0x2000>
    80005fa6:	97ba                	add	a5,a5,a4
    80005fa8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fac:	0001d797          	auipc	a5,0x1d
    80005fb0:	05478793          	addi	a5,a5,84 # 80023000 <disk>
    80005fb4:	97aa                	add	a5,a5,a0
    80005fb6:	6509                	lui	a0,0x2
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005fc0:	0001f517          	auipc	a0,0x1f
    80005fc4:	05850513          	addi	a0,a0,88 # 80025018 <disk+0x2018>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	19e080e7          	jalr	414(ra) # 80002166 <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	83050513          	addi	a0,a0,-2000 # 80008808 <syscalls+0x330>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	568080e7          	jalr	1384(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005fe8:	00003517          	auipc	a0,0x3
    80005fec:	83850513          	addi	a0,a0,-1992 # 80008820 <syscalls+0x348>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	558080e7          	jalr	1368(ra) # 80000548 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006002:	00003597          	auipc	a1,0x3
    80006006:	83658593          	addi	a1,a1,-1994 # 80008838 <syscalls+0x360>
    8000600a:	0001f517          	auipc	a0,0x1f
    8000600e:	09e50513          	addi	a0,a0,158 # 800250a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	b6e080e7          	jalr	-1170(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	4398                	lw	a4,0(a5)
    80006020:	2701                	sext.w	a4,a4
    80006022:	747277b7          	lui	a5,0x74727
    80006026:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602a:	0ef71163          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	43dc                	lw	a5,4(a5)
    80006034:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006036:	4705                	li	a4,1
    80006038:	0ce79a63          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	479c                	lw	a5,8(a5)
    80006042:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006044:	4709                	li	a4,2
    80006046:	0ce79363          	bne	a5,a4,8000610c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	0af71963          	bne	a4,a5,8000610c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	4705                	li	a4,1
    80006064:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	470d                	li	a4,3
    80006068:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000606c:	c7ffe737          	lui	a4,0xc7ffe
    80006070:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006074:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006076:	2701                	sext.w	a4,a4
    80006078:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607a:	472d                	li	a4,11
    8000607c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	473d                	li	a4,15
    80006080:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006082:	6705                	lui	a4,0x1
    80006084:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006086:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000608a:	5bdc                	lw	a5,52(a5)
    8000608c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000608e:	c7d9                	beqz	a5,8000611c <virtio_disk_init+0x124>
  if(max < NUM)
    80006090:	471d                	li	a4,7
    80006092:	08f77d63          	bgeu	a4,a5,8000612c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006096:	100014b7          	lui	s1,0x10001
    8000609a:	47a1                	li	a5,8
    8000609c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000609e:	6609                	lui	a2,0x2
    800060a0:	4581                	li	a1,0
    800060a2:	0001d517          	auipc	a0,0x1d
    800060a6:	f5e50513          	addi	a0,a0,-162 # 80023000 <disk>
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	c62080e7          	jalr	-926(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060b2:	0001d717          	auipc	a4,0x1d
    800060b6:	f4e70713          	addi	a4,a4,-178 # 80023000 <disk>
    800060ba:	00c75793          	srli	a5,a4,0xc
    800060be:	2781                	sext.w	a5,a5
    800060c0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800060c2:	0001f797          	auipc	a5,0x1f
    800060c6:	f3e78793          	addi	a5,a5,-194 # 80025000 <disk+0x2000>
    800060ca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800060cc:	0001d717          	auipc	a4,0x1d
    800060d0:	fb470713          	addi	a4,a4,-76 # 80023080 <disk+0x80>
    800060d4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800060d6:	0001e717          	auipc	a4,0x1e
    800060da:	f2a70713          	addi	a4,a4,-214 # 80024000 <disk+0x1000>
    800060de:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800060e0:	4705                	li	a4,1
    800060e2:	00e78c23          	sb	a4,24(a5)
    800060e6:	00e78ca3          	sb	a4,25(a5)
    800060ea:	00e78d23          	sb	a4,26(a5)
    800060ee:	00e78da3          	sb	a4,27(a5)
    800060f2:	00e78e23          	sb	a4,28(a5)
    800060f6:	00e78ea3          	sb	a4,29(a5)
    800060fa:	00e78f23          	sb	a4,30(a5)
    800060fe:	00e78fa3          	sb	a4,31(a5)
}
    80006102:	60e2                	ld	ra,24(sp)
    80006104:	6442                	ld	s0,16(sp)
    80006106:	64a2                	ld	s1,8(sp)
    80006108:	6105                	addi	sp,sp,32
    8000610a:	8082                	ret
    panic("could not find virtio disk");
    8000610c:	00002517          	auipc	a0,0x2
    80006110:	73c50513          	addi	a0,a0,1852 # 80008848 <syscalls+0x370>
    80006114:	ffffa097          	auipc	ra,0xffffa
    80006118:	434080e7          	jalr	1076(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000611c:	00002517          	auipc	a0,0x2
    80006120:	74c50513          	addi	a0,a0,1868 # 80008868 <syscalls+0x390>
    80006124:	ffffa097          	auipc	ra,0xffffa
    80006128:	424080e7          	jalr	1060(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000612c:	00002517          	auipc	a0,0x2
    80006130:	75c50513          	addi	a0,a0,1884 # 80008888 <syscalls+0x3b0>
    80006134:	ffffa097          	auipc	ra,0xffffa
    80006138:	414080e7          	jalr	1044(ra) # 80000548 <panic>

000000008000613c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000613c:	7119                	addi	sp,sp,-128
    8000613e:	fc86                	sd	ra,120(sp)
    80006140:	f8a2                	sd	s0,112(sp)
    80006142:	f4a6                	sd	s1,104(sp)
    80006144:	f0ca                	sd	s2,96(sp)
    80006146:	ecce                	sd	s3,88(sp)
    80006148:	e8d2                	sd	s4,80(sp)
    8000614a:	e4d6                	sd	s5,72(sp)
    8000614c:	e0da                	sd	s6,64(sp)
    8000614e:	fc5e                	sd	s7,56(sp)
    80006150:	f862                	sd	s8,48(sp)
    80006152:	f466                	sd	s9,40(sp)
    80006154:	f06a                	sd	s10,32(sp)
    80006156:	0100                	addi	s0,sp,128
    80006158:	892a                	mv	s2,a0
    8000615a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000615c:	00c52c83          	lw	s9,12(a0)
    80006160:	001c9c9b          	slliw	s9,s9,0x1
    80006164:	1c82                	slli	s9,s9,0x20
    80006166:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000616a:	0001f517          	auipc	a0,0x1f
    8000616e:	f3e50513          	addi	a0,a0,-194 # 800250a8 <disk+0x20a8>
    80006172:	ffffb097          	auipc	ra,0xffffb
    80006176:	a9e080e7          	jalr	-1378(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000617a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000617c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000617e:	0001db97          	auipc	s7,0x1d
    80006182:	e82b8b93          	addi	s7,s7,-382 # 80023000 <disk>
    80006186:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006188:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000618a:	8a4e                	mv	s4,s3
    8000618c:	a051                	j	80006210 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000618e:	00fb86b3          	add	a3,s7,a5
    80006192:	96da                	add	a3,a3,s6
    80006194:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006198:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000619a:	0207c563          	bltz	a5,800061c4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000619e:	2485                	addiw	s1,s1,1
    800061a0:	0711                	addi	a4,a4,4
    800061a2:	23548d63          	beq	s1,s5,800063dc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800061a6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061a8:	0001f697          	auipc	a3,0x1f
    800061ac:	e7068693          	addi	a3,a3,-400 # 80025018 <disk+0x2018>
    800061b0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061b2:	0006c583          	lbu	a1,0(a3)
    800061b6:	fde1                	bnez	a1,8000618e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800061b8:	2785                	addiw	a5,a5,1
    800061ba:	0685                	addi	a3,a3,1
    800061bc:	ff879be3          	bne	a5,s8,800061b2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800061c0:	57fd                	li	a5,-1
    800061c2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061c4:	02905a63          	blez	s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061c8:	f9042503          	lw	a0,-112(s0)
    800061cc:	00000097          	auipc	ra,0x0
    800061d0:	daa080e7          	jalr	-598(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061d4:	4785                	li	a5,1
    800061d6:	0297d163          	bge	a5,s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061da:	f9442503          	lw	a0,-108(s0)
    800061de:	00000097          	auipc	ra,0x0
    800061e2:	d98080e7          	jalr	-616(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    800061e6:	4789                	li	a5,2
    800061e8:	0097d863          	bge	a5,s1,800061f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800061ec:	f9842503          	lw	a0,-104(s0)
    800061f0:	00000097          	auipc	ra,0x0
    800061f4:	d86080e7          	jalr	-634(ra) # 80005f76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061f8:	0001f597          	auipc	a1,0x1f
    800061fc:	eb058593          	addi	a1,a1,-336 # 800250a8 <disk+0x20a8>
    80006200:	0001f517          	auipc	a0,0x1f
    80006204:	e1850513          	addi	a0,a0,-488 # 80025018 <disk+0x2018>
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	ee0080e7          	jalr	-288(ra) # 800020e8 <sleep>
  for(int i = 0; i < 3; i++){
    80006210:	f9040713          	addi	a4,s0,-112
    80006214:	84ce                	mv	s1,s3
    80006216:	bf41                	j	800061a6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006218:	4785                	li	a5,1
    8000621a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000621e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006222:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006226:	f9042983          	lw	s3,-112(s0)
    8000622a:	00499493          	slli	s1,s3,0x4
    8000622e:	0001fa17          	auipc	s4,0x1f
    80006232:	dd2a0a13          	addi	s4,s4,-558 # 80025000 <disk+0x2000>
    80006236:	000a3a83          	ld	s5,0(s4)
    8000623a:	9aa6                	add	s5,s5,s1
    8000623c:	f8040513          	addi	a0,s0,-128
    80006240:	ffffb097          	auipc	ra,0xffffb
    80006244:	ea8080e7          	jalr	-344(ra) # 800010e8 <kvmpa>
    80006248:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000624c:	000a3783          	ld	a5,0(s4)
    80006250:	97a6                	add	a5,a5,s1
    80006252:	4741                	li	a4,16
    80006254:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006256:	000a3783          	ld	a5,0(s4)
    8000625a:	97a6                	add	a5,a5,s1
    8000625c:	4705                	li	a4,1
    8000625e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006262:	f9442703          	lw	a4,-108(s0)
    80006266:	000a3783          	ld	a5,0(s4)
    8000626a:	97a6                	add	a5,a5,s1
    8000626c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006270:	0712                	slli	a4,a4,0x4
    80006272:	000a3783          	ld	a5,0(s4)
    80006276:	97ba                	add	a5,a5,a4
    80006278:	05890693          	addi	a3,s2,88
    8000627c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000627e:	000a3783          	ld	a5,0(s4)
    80006282:	97ba                	add	a5,a5,a4
    80006284:	40000693          	li	a3,1024
    80006288:	c794                	sw	a3,8(a5)
  if(write)
    8000628a:	100d0a63          	beqz	s10,8000639e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000628e:	0001f797          	auipc	a5,0x1f
    80006292:	d727b783          	ld	a5,-654(a5) # 80025000 <disk+0x2000>
    80006296:	97ba                	add	a5,a5,a4
    80006298:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000629c:	0001d517          	auipc	a0,0x1d
    800062a0:	d6450513          	addi	a0,a0,-668 # 80023000 <disk>
    800062a4:	0001f797          	auipc	a5,0x1f
    800062a8:	d5c78793          	addi	a5,a5,-676 # 80025000 <disk+0x2000>
    800062ac:	6394                	ld	a3,0(a5)
    800062ae:	96ba                	add	a3,a3,a4
    800062b0:	00c6d603          	lhu	a2,12(a3)
    800062b4:	00166613          	ori	a2,a2,1
    800062b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800062bc:	f9842683          	lw	a3,-104(s0)
    800062c0:	6390                	ld	a2,0(a5)
    800062c2:	9732                	add	a4,a4,a2
    800062c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800062c8:	20098613          	addi	a2,s3,512
    800062cc:	0612                	slli	a2,a2,0x4
    800062ce:	962a                	add	a2,a2,a0
    800062d0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062d4:	00469713          	slli	a4,a3,0x4
    800062d8:	6394                	ld	a3,0(a5)
    800062da:	96ba                	add	a3,a3,a4
    800062dc:	6589                	lui	a1,0x2
    800062de:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800062e2:	94ae                	add	s1,s1,a1
    800062e4:	94aa                	add	s1,s1,a0
    800062e6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800062e8:	6394                	ld	a3,0(a5)
    800062ea:	96ba                	add	a3,a3,a4
    800062ec:	4585                	li	a1,1
    800062ee:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062f0:	6394                	ld	a3,0(a5)
    800062f2:	96ba                	add	a3,a3,a4
    800062f4:	4509                	li	a0,2
    800062f6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800062fa:	6394                	ld	a3,0(a5)
    800062fc:	9736                	add	a4,a4,a3
    800062fe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006302:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006306:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000630a:	6794                	ld	a3,8(a5)
    8000630c:	0026d703          	lhu	a4,2(a3)
    80006310:	8b1d                	andi	a4,a4,7
    80006312:	2709                	addiw	a4,a4,2
    80006314:	0706                	slli	a4,a4,0x1
    80006316:	9736                	add	a4,a4,a3
    80006318:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000631c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006320:	6798                	ld	a4,8(a5)
    80006322:	00275783          	lhu	a5,2(a4)
    80006326:	2785                	addiw	a5,a5,1
    80006328:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006334:	00492703          	lw	a4,4(s2)
    80006338:	4785                	li	a5,1
    8000633a:	02f71163          	bne	a4,a5,8000635c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000633e:	0001f997          	auipc	s3,0x1f
    80006342:	d6a98993          	addi	s3,s3,-662 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006346:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006348:	85ce                	mv	a1,s3
    8000634a:	854a                	mv	a0,s2
    8000634c:	ffffc097          	auipc	ra,0xffffc
    80006350:	d9c080e7          	jalr	-612(ra) # 800020e8 <sleep>
  while(b->disk == 1) {
    80006354:	00492783          	lw	a5,4(s2)
    80006358:	fe9788e3          	beq	a5,s1,80006348 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000635c:	f9042483          	lw	s1,-112(s0)
    80006360:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006364:	00479713          	slli	a4,a5,0x4
    80006368:	0001d797          	auipc	a5,0x1d
    8000636c:	c9878793          	addi	a5,a5,-872 # 80023000 <disk>
    80006370:	97ba                	add	a5,a5,a4
    80006372:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006376:	0001f917          	auipc	s2,0x1f
    8000637a:	c8a90913          	addi	s2,s2,-886 # 80025000 <disk+0x2000>
    free_desc(i);
    8000637e:	8526                	mv	a0,s1
    80006380:	00000097          	auipc	ra,0x0
    80006384:	bf6080e7          	jalr	-1034(ra) # 80005f76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006388:	0492                	slli	s1,s1,0x4
    8000638a:	00093783          	ld	a5,0(s2)
    8000638e:	94be                	add	s1,s1,a5
    80006390:	00c4d783          	lhu	a5,12(s1)
    80006394:	8b85                	andi	a5,a5,1
    80006396:	cf89                	beqz	a5,800063b0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006398:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000639c:	b7cd                	j	8000637e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000639e:	0001f797          	auipc	a5,0x1f
    800063a2:	c627b783          	ld	a5,-926(a5) # 80025000 <disk+0x2000>
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	4689                	li	a3,2
    800063aa:	00d79623          	sh	a3,12(a5)
    800063ae:	b5fd                	j	8000629c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063b0:	0001f517          	auipc	a0,0x1f
    800063b4:	cf850513          	addi	a0,a0,-776 # 800250a8 <disk+0x20a8>
    800063b8:	ffffb097          	auipc	ra,0xffffb
    800063bc:	90c080e7          	jalr	-1780(ra) # 80000cc4 <release>
}
    800063c0:	70e6                	ld	ra,120(sp)
    800063c2:	7446                	ld	s0,112(sp)
    800063c4:	74a6                	ld	s1,104(sp)
    800063c6:	7906                	ld	s2,96(sp)
    800063c8:	69e6                	ld	s3,88(sp)
    800063ca:	6a46                	ld	s4,80(sp)
    800063cc:	6aa6                	ld	s5,72(sp)
    800063ce:	6b06                	ld	s6,64(sp)
    800063d0:	7be2                	ld	s7,56(sp)
    800063d2:	7c42                	ld	s8,48(sp)
    800063d4:	7ca2                	ld	s9,40(sp)
    800063d6:	7d02                	ld	s10,32(sp)
    800063d8:	6109                	addi	sp,sp,128
    800063da:	8082                	ret
  if(write)
    800063dc:	e20d1ee3          	bnez	s10,80006218 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800063e0:	f8042023          	sw	zero,-128(s0)
    800063e4:	bd2d                	j	8000621e <virtio_disk_rw+0xe2>

00000000800063e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063e6:	1101                	addi	sp,sp,-32
    800063e8:	ec06                	sd	ra,24(sp)
    800063ea:	e822                	sd	s0,16(sp)
    800063ec:	e426                	sd	s1,8(sp)
    800063ee:	e04a                	sd	s2,0(sp)
    800063f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063f2:	0001f517          	auipc	a0,0x1f
    800063f6:	cb650513          	addi	a0,a0,-842 # 800250a8 <disk+0x20a8>
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	816080e7          	jalr	-2026(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006402:	0001f717          	auipc	a4,0x1f
    80006406:	bfe70713          	addi	a4,a4,-1026 # 80025000 <disk+0x2000>
    8000640a:	02075783          	lhu	a5,32(a4)
    8000640e:	6b18                	ld	a4,16(a4)
    80006410:	00275683          	lhu	a3,2(a4)
    80006414:	8ebd                	xor	a3,a3,a5
    80006416:	8a9d                	andi	a3,a3,7
    80006418:	cab9                	beqz	a3,8000646e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000641a:	0001d917          	auipc	s2,0x1d
    8000641e:	be690913          	addi	s2,s2,-1050 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006422:	0001f497          	auipc	s1,0x1f
    80006426:	bde48493          	addi	s1,s1,-1058 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000642a:	078e                	slli	a5,a5,0x3
    8000642c:	97ba                	add	a5,a5,a4
    8000642e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006430:	20078713          	addi	a4,a5,512
    80006434:	0712                	slli	a4,a4,0x4
    80006436:	974a                	add	a4,a4,s2
    80006438:	03074703          	lbu	a4,48(a4)
    8000643c:	ef21                	bnez	a4,80006494 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000643e:	20078793          	addi	a5,a5,512
    80006442:	0792                	slli	a5,a5,0x4
    80006444:	97ca                	add	a5,a5,s2
    80006446:	7798                	ld	a4,40(a5)
    80006448:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000644c:	7788                	ld	a0,40(a5)
    8000644e:	ffffc097          	auipc	ra,0xffffc
    80006452:	d18080e7          	jalr	-744(ra) # 80002166 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006456:	0204d783          	lhu	a5,32(s1)
    8000645a:	2785                	addiw	a5,a5,1
    8000645c:	8b9d                	andi	a5,a5,7
    8000645e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006462:	6898                	ld	a4,16(s1)
    80006464:	00275683          	lhu	a3,2(a4)
    80006468:	8a9d                	andi	a3,a3,7
    8000646a:	fcf690e3          	bne	a3,a5,8000642a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000646e:	10001737          	lui	a4,0x10001
    80006472:	533c                	lw	a5,96(a4)
    80006474:	8b8d                	andi	a5,a5,3
    80006476:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006478:	0001f517          	auipc	a0,0x1f
    8000647c:	c3050513          	addi	a0,a0,-976 # 800250a8 <disk+0x20a8>
    80006480:	ffffb097          	auipc	ra,0xffffb
    80006484:	844080e7          	jalr	-1980(ra) # 80000cc4 <release>
}
    80006488:	60e2                	ld	ra,24(sp)
    8000648a:	6442                	ld	s0,16(sp)
    8000648c:	64a2                	ld	s1,8(sp)
    8000648e:	6902                	ld	s2,0(sp)
    80006490:	6105                	addi	sp,sp,32
    80006492:	8082                	ret
      panic("virtio_disk_intr status");
    80006494:	00002517          	auipc	a0,0x2
    80006498:	41450513          	addi	a0,a0,1044 # 800088a8 <syscalls+0x3d0>
    8000649c:	ffffa097          	auipc	ra,0xffffa
    800064a0:	0ac080e7          	jalr	172(ra) # 80000548 <panic>

00000000800064a4 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    800064a4:	7179                	addi	sp,sp,-48
    800064a6:	f406                	sd	ra,40(sp)
    800064a8:	f022                	sd	s0,32(sp)
    800064aa:	ec26                	sd	s1,24(sp)
    800064ac:	e84a                	sd	s2,16(sp)
    800064ae:	e44e                	sd	s3,8(sp)
    800064b0:	e052                	sd	s4,0(sp)
    800064b2:	1800                	addi	s0,sp,48
    800064b4:	892a                	mv	s2,a0
    800064b6:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    800064b8:	00003a17          	auipc	s4,0x3
    800064bc:	b70a0a13          	addi	s4,s4,-1168 # 80009028 <stats>
    800064c0:	000a2683          	lw	a3,0(s4)
    800064c4:	00002617          	auipc	a2,0x2
    800064c8:	3fc60613          	addi	a2,a2,1020 # 800088c0 <syscalls+0x3e8>
    800064cc:	00000097          	auipc	ra,0x0
    800064d0:	2c2080e7          	jalr	706(ra) # 8000678e <snprintf>
    800064d4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800064d6:	004a2683          	lw	a3,4(s4)
    800064da:	00002617          	auipc	a2,0x2
    800064de:	3f660613          	addi	a2,a2,1014 # 800088d0 <syscalls+0x3f8>
    800064e2:	85ce                	mv	a1,s3
    800064e4:	954a                	add	a0,a0,s2
    800064e6:	00000097          	auipc	ra,0x0
    800064ea:	2a8080e7          	jalr	680(ra) # 8000678e <snprintf>
  return n;
}
    800064ee:	9d25                	addw	a0,a0,s1
    800064f0:	70a2                	ld	ra,40(sp)
    800064f2:	7402                	ld	s0,32(sp)
    800064f4:	64e2                	ld	s1,24(sp)
    800064f6:	6942                	ld	s2,16(sp)
    800064f8:	69a2                	ld	s3,8(sp)
    800064fa:	6a02                	ld	s4,0(sp)
    800064fc:	6145                	addi	sp,sp,48
    800064fe:	8082                	ret

0000000080006500 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    80006500:	7179                	addi	sp,sp,-48
    80006502:	f406                	sd	ra,40(sp)
    80006504:	f022                	sd	s0,32(sp)
    80006506:	ec26                	sd	s1,24(sp)
    80006508:	e84a                	sd	s2,16(sp)
    8000650a:	e44e                	sd	s3,8(sp)
    8000650c:	1800                	addi	s0,sp,48
    8000650e:	89ae                	mv	s3,a1
    80006510:	84b2                	mv	s1,a2
    80006512:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006514:	ffffb097          	auipc	ra,0xffffb
    80006518:	602080e7          	jalr	1538(ra) # 80001b16 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    8000651c:	653c                	ld	a5,72(a0)
    8000651e:	02f4ff63          	bgeu	s1,a5,8000655c <copyin_new+0x5c>
    80006522:	01248733          	add	a4,s1,s2
    80006526:	02f77d63          	bgeu	a4,a5,80006560 <copyin_new+0x60>
    8000652a:	02976d63          	bltu	a4,s1,80006564 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000652e:	0009061b          	sext.w	a2,s2
    80006532:	85a6                	mv	a1,s1
    80006534:	854e                	mv	a0,s3
    80006536:	ffffb097          	auipc	ra,0xffffb
    8000653a:	836080e7          	jalr	-1994(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000653e:	00003717          	auipc	a4,0x3
    80006542:	aea70713          	addi	a4,a4,-1302 # 80009028 <stats>
    80006546:	431c                	lw	a5,0(a4)
    80006548:	2785                	addiw	a5,a5,1
    8000654a:	c31c                	sw	a5,0(a4)
  return 0;
    8000654c:	4501                	li	a0,0
}
    8000654e:	70a2                	ld	ra,40(sp)
    80006550:	7402                	ld	s0,32(sp)
    80006552:	64e2                	ld	s1,24(sp)
    80006554:	6942                	ld	s2,16(sp)
    80006556:	69a2                	ld	s3,8(sp)
    80006558:	6145                	addi	sp,sp,48
    8000655a:	8082                	ret
    return -1;
    8000655c:	557d                	li	a0,-1
    8000655e:	bfc5                	j	8000654e <copyin_new+0x4e>
    80006560:	557d                	li	a0,-1
    80006562:	b7f5                	j	8000654e <copyin_new+0x4e>
    80006564:	557d                	li	a0,-1
    80006566:	b7e5                	j	8000654e <copyin_new+0x4e>

0000000080006568 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006568:	7179                	addi	sp,sp,-48
    8000656a:	f406                	sd	ra,40(sp)
    8000656c:	f022                	sd	s0,32(sp)
    8000656e:	ec26                	sd	s1,24(sp)
    80006570:	e84a                	sd	s2,16(sp)
    80006572:	e44e                	sd	s3,8(sp)
    80006574:	1800                	addi	s0,sp,48
    80006576:	89ae                	mv	s3,a1
    80006578:	8932                	mv	s2,a2
    8000657a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000657c:	ffffb097          	auipc	ra,0xffffb
    80006580:	59a080e7          	jalr	1434(ra) # 80001b16 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006584:	00003717          	auipc	a4,0x3
    80006588:	aa470713          	addi	a4,a4,-1372 # 80009028 <stats>
    8000658c:	435c                	lw	a5,4(a4)
    8000658e:	2785                	addiw	a5,a5,1
    80006590:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006592:	cc85                	beqz	s1,800065ca <copyinstr_new+0x62>
    80006594:	00990833          	add	a6,s2,s1
    80006598:	87ca                	mv	a5,s2
    8000659a:	6538                	ld	a4,72(a0)
    8000659c:	00e7ff63          	bgeu	a5,a4,800065ba <copyinstr_new+0x52>
    dst[i] = s[i];
    800065a0:	0007c683          	lbu	a3,0(a5)
    800065a4:	41278733          	sub	a4,a5,s2
    800065a8:	974e                	add	a4,a4,s3
    800065aa:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    800065ae:	c285                	beqz	a3,800065ce <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    800065b0:	0785                	addi	a5,a5,1
    800065b2:	ff0794e3          	bne	a5,a6,8000659a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    800065b6:	557d                	li	a0,-1
    800065b8:	a011                	j	800065bc <copyinstr_new+0x54>
    800065ba:	557d                	li	a0,-1
}
    800065bc:	70a2                	ld	ra,40(sp)
    800065be:	7402                	ld	s0,32(sp)
    800065c0:	64e2                	ld	s1,24(sp)
    800065c2:	6942                	ld	s2,16(sp)
    800065c4:	69a2                	ld	s3,8(sp)
    800065c6:	6145                	addi	sp,sp,48
    800065c8:	8082                	ret
  return -1;
    800065ca:	557d                	li	a0,-1
    800065cc:	bfc5                	j	800065bc <copyinstr_new+0x54>
      return 0;
    800065ce:	4501                	li	a0,0
    800065d0:	b7f5                	j	800065bc <copyinstr_new+0x54>

00000000800065d2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800065d2:	1141                	addi	sp,sp,-16
    800065d4:	e422                	sd	s0,8(sp)
    800065d6:	0800                	addi	s0,sp,16
  return -1;
}
    800065d8:	557d                	li	a0,-1
    800065da:	6422                	ld	s0,8(sp)
    800065dc:	0141                	addi	sp,sp,16
    800065de:	8082                	ret

00000000800065e0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800065e0:	7179                	addi	sp,sp,-48
    800065e2:	f406                	sd	ra,40(sp)
    800065e4:	f022                	sd	s0,32(sp)
    800065e6:	ec26                	sd	s1,24(sp)
    800065e8:	e84a                	sd	s2,16(sp)
    800065ea:	e44e                	sd	s3,8(sp)
    800065ec:	e052                	sd	s4,0(sp)
    800065ee:	1800                	addi	s0,sp,48
    800065f0:	892a                	mv	s2,a0
    800065f2:	89ae                	mv	s3,a1
    800065f4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800065f6:	00020517          	auipc	a0,0x20
    800065fa:	a0a50513          	addi	a0,a0,-1526 # 80026000 <stats>
    800065fe:	ffffa097          	auipc	ra,0xffffa
    80006602:	612080e7          	jalr	1554(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    80006606:	00021797          	auipc	a5,0x21
    8000660a:	a127a783          	lw	a5,-1518(a5) # 80027018 <stats+0x1018>
    8000660e:	cbb5                	beqz	a5,80006682 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    80006610:	00021797          	auipc	a5,0x21
    80006614:	9f078793          	addi	a5,a5,-1552 # 80027000 <stats+0x1000>
    80006618:	4fd8                	lw	a4,28(a5)
    8000661a:	4f9c                	lw	a5,24(a5)
    8000661c:	9f99                	subw	a5,a5,a4
    8000661e:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006622:	06d05e63          	blez	a3,8000669e <statsread+0xbe>
    if(m > n)
    80006626:	8a3e                	mv	s4,a5
    80006628:	00d4d363          	bge	s1,a3,8000662e <statsread+0x4e>
    8000662c:	8a26                	mv	s4,s1
    8000662e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006632:	86a6                	mv	a3,s1
    80006634:	00020617          	auipc	a2,0x20
    80006638:	9e460613          	addi	a2,a2,-1564 # 80026018 <stats+0x18>
    8000663c:	963a                	add	a2,a2,a4
    8000663e:	85ce                	mv	a1,s3
    80006640:	854a                	mv	a0,s2
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	c00080e7          	jalr	-1024(ra) # 80002242 <either_copyout>
    8000664a:	57fd                	li	a5,-1
    8000664c:	00f50a63          	beq	a0,a5,80006660 <statsread+0x80>
      stats.off += m;
    80006650:	00021717          	auipc	a4,0x21
    80006654:	9b070713          	addi	a4,a4,-1616 # 80027000 <stats+0x1000>
    80006658:	4f5c                	lw	a5,28(a4)
    8000665a:	014787bb          	addw	a5,a5,s4
    8000665e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006660:	00020517          	auipc	a0,0x20
    80006664:	9a050513          	addi	a0,a0,-1632 # 80026000 <stats>
    80006668:	ffffa097          	auipc	ra,0xffffa
    8000666c:	65c080e7          	jalr	1628(ra) # 80000cc4 <release>
  return m;
}
    80006670:	8526                	mv	a0,s1
    80006672:	70a2                	ld	ra,40(sp)
    80006674:	7402                	ld	s0,32(sp)
    80006676:	64e2                	ld	s1,24(sp)
    80006678:	6942                	ld	s2,16(sp)
    8000667a:	69a2                	ld	s3,8(sp)
    8000667c:	6a02                	ld	s4,0(sp)
    8000667e:	6145                	addi	sp,sp,48
    80006680:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006682:	6585                	lui	a1,0x1
    80006684:	00020517          	auipc	a0,0x20
    80006688:	99450513          	addi	a0,a0,-1644 # 80026018 <stats+0x18>
    8000668c:	00000097          	auipc	ra,0x0
    80006690:	e18080e7          	jalr	-488(ra) # 800064a4 <statscopyin>
    80006694:	00021797          	auipc	a5,0x21
    80006698:	98a7a223          	sw	a0,-1660(a5) # 80027018 <stats+0x1018>
    8000669c:	bf95                	j	80006610 <statsread+0x30>
    stats.sz = 0;
    8000669e:	00021797          	auipc	a5,0x21
    800066a2:	96278793          	addi	a5,a5,-1694 # 80027000 <stats+0x1000>
    800066a6:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    800066aa:	0007ae23          	sw	zero,28(a5)
    m = -1;
    800066ae:	54fd                	li	s1,-1
    800066b0:	bf45                	j	80006660 <statsread+0x80>

00000000800066b2 <statsinit>:

void
statsinit(void)
{
    800066b2:	1141                	addi	sp,sp,-16
    800066b4:	e406                	sd	ra,8(sp)
    800066b6:	e022                	sd	s0,0(sp)
    800066b8:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    800066ba:	00002597          	auipc	a1,0x2
    800066be:	22658593          	addi	a1,a1,550 # 800088e0 <syscalls+0x408>
    800066c2:	00020517          	auipc	a0,0x20
    800066c6:	93e50513          	addi	a0,a0,-1730 # 80026000 <stats>
    800066ca:	ffffa097          	auipc	ra,0xffffa
    800066ce:	4b6080e7          	jalr	1206(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    800066d2:	0001b797          	auipc	a5,0x1b
    800066d6:	4de78793          	addi	a5,a5,1246 # 80021bb0 <devsw>
    800066da:	00000717          	auipc	a4,0x0
    800066de:	f0670713          	addi	a4,a4,-250 # 800065e0 <statsread>
    800066e2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800066e4:	00000717          	auipc	a4,0x0
    800066e8:	eee70713          	addi	a4,a4,-274 # 800065d2 <statswrite>
    800066ec:	f798                	sd	a4,40(a5)
}
    800066ee:	60a2                	ld	ra,8(sp)
    800066f0:	6402                	ld	s0,0(sp)
    800066f2:	0141                	addi	sp,sp,16
    800066f4:	8082                	ret

00000000800066f6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800066f6:	1101                	addi	sp,sp,-32
    800066f8:	ec22                	sd	s0,24(sp)
    800066fa:	1000                	addi	s0,sp,32
    800066fc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800066fe:	c299                	beqz	a3,80006704 <sprintint+0xe>
    80006700:	0805c163          	bltz	a1,80006782 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    80006704:	2581                	sext.w	a1,a1
    80006706:	4301                	li	t1,0

  i = 0;
    80006708:	fe040713          	addi	a4,s0,-32
    8000670c:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    8000670e:	2601                	sext.w	a2,a2
    80006710:	00002697          	auipc	a3,0x2
    80006714:	1d868693          	addi	a3,a3,472 # 800088e8 <digits>
    80006718:	88aa                	mv	a7,a0
    8000671a:	2505                	addiw	a0,a0,1
    8000671c:	02c5f7bb          	remuw	a5,a1,a2
    80006720:	1782                	slli	a5,a5,0x20
    80006722:	9381                	srli	a5,a5,0x20
    80006724:	97b6                	add	a5,a5,a3
    80006726:	0007c783          	lbu	a5,0(a5)
    8000672a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000672e:	0005879b          	sext.w	a5,a1
    80006732:	02c5d5bb          	divuw	a1,a1,a2
    80006736:	0705                	addi	a4,a4,1
    80006738:	fec7f0e3          	bgeu	a5,a2,80006718 <sprintint+0x22>

  if(sign)
    8000673c:	00030b63          	beqz	t1,80006752 <sprintint+0x5c>
    buf[i++] = '-';
    80006740:	ff040793          	addi	a5,s0,-16
    80006744:	97aa                	add	a5,a5,a0
    80006746:	02d00713          	li	a4,45
    8000674a:	fee78823          	sb	a4,-16(a5)
    8000674e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006752:	02a05c63          	blez	a0,8000678a <sprintint+0x94>
    80006756:	fe040793          	addi	a5,s0,-32
    8000675a:	00a78733          	add	a4,a5,a0
    8000675e:	87c2                	mv	a5,a6
    80006760:	0805                	addi	a6,a6,1
    80006762:	fff5061b          	addiw	a2,a0,-1
    80006766:	1602                	slli	a2,a2,0x20
    80006768:	9201                	srli	a2,a2,0x20
    8000676a:	9642                	add	a2,a2,a6
  *s = c;
    8000676c:	fff74683          	lbu	a3,-1(a4)
    80006770:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006774:	177d                	addi	a4,a4,-1
    80006776:	0785                	addi	a5,a5,1
    80006778:	fec79ae3          	bne	a5,a2,8000676c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000677c:	6462                	ld	s0,24(sp)
    8000677e:	6105                	addi	sp,sp,32
    80006780:	8082                	ret
    x = -xx;
    80006782:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006786:	4305                	li	t1,1
    x = -xx;
    80006788:	b741                	j	80006708 <sprintint+0x12>
  while(--i >= 0)
    8000678a:	4501                	li	a0,0
    8000678c:	bfc5                	j	8000677c <sprintint+0x86>

000000008000678e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000678e:	7171                	addi	sp,sp,-176
    80006790:	fc86                	sd	ra,120(sp)
    80006792:	f8a2                	sd	s0,112(sp)
    80006794:	f4a6                	sd	s1,104(sp)
    80006796:	f0ca                	sd	s2,96(sp)
    80006798:	ecce                	sd	s3,88(sp)
    8000679a:	e8d2                	sd	s4,80(sp)
    8000679c:	e4d6                	sd	s5,72(sp)
    8000679e:	e0da                	sd	s6,64(sp)
    800067a0:	fc5e                	sd	s7,56(sp)
    800067a2:	f862                	sd	s8,48(sp)
    800067a4:	f466                	sd	s9,40(sp)
    800067a6:	f06a                	sd	s10,32(sp)
    800067a8:	ec6e                	sd	s11,24(sp)
    800067aa:	0100                	addi	s0,sp,128
    800067ac:	e414                	sd	a3,8(s0)
    800067ae:	e818                	sd	a4,16(s0)
    800067b0:	ec1c                	sd	a5,24(s0)
    800067b2:	03043023          	sd	a6,32(s0)
    800067b6:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    800067ba:	ca0d                	beqz	a2,800067ec <snprintf+0x5e>
    800067bc:	8baa                	mv	s7,a0
    800067be:	89ae                	mv	s3,a1
    800067c0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800067c2:	00840793          	addi	a5,s0,8
    800067c6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    800067ca:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800067cc:	4901                	li	s2,0
    800067ce:	02b05763          	blez	a1,800067fc <snprintf+0x6e>
    if(c != '%'){
    800067d2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800067d6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800067da:	02800d93          	li	s11,40
  *s = c;
    800067de:	02500d13          	li	s10,37
    switch(c){
    800067e2:	07800c93          	li	s9,120
    800067e6:	06400c13          	li	s8,100
    800067ea:	a01d                	j	80006810 <snprintf+0x82>
    panic("null fmt");
    800067ec:	00002517          	auipc	a0,0x2
    800067f0:	83c50513          	addi	a0,a0,-1988 # 80008028 <etext+0x28>
    800067f4:	ffffa097          	auipc	ra,0xffffa
    800067f8:	d54080e7          	jalr	-684(ra) # 80000548 <panic>
  int off = 0;
    800067fc:	4481                	li	s1,0
    800067fe:	a86d                	j	800068b8 <snprintf+0x12a>
  *s = c;
    80006800:	009b8733          	add	a4,s7,s1
    80006804:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006808:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    8000680a:	2905                	addiw	s2,s2,1
    8000680c:	0b34d663          	bge	s1,s3,800068b8 <snprintf+0x12a>
    80006810:	012a07b3          	add	a5,s4,s2
    80006814:	0007c783          	lbu	a5,0(a5)
    80006818:	0007871b          	sext.w	a4,a5
    8000681c:	cfd1                	beqz	a5,800068b8 <snprintf+0x12a>
    if(c != '%'){
    8000681e:	ff5711e3          	bne	a4,s5,80006800 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006822:	2905                	addiw	s2,s2,1
    80006824:	012a07b3          	add	a5,s4,s2
    80006828:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000682c:	c7d1                	beqz	a5,800068b8 <snprintf+0x12a>
    switch(c){
    8000682e:	05678c63          	beq	a5,s6,80006886 <snprintf+0xf8>
    80006832:	02fb6763          	bltu	s6,a5,80006860 <snprintf+0xd2>
    80006836:	0b578763          	beq	a5,s5,800068e4 <snprintf+0x156>
    8000683a:	0b879b63          	bne	a5,s8,800068f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000683e:	f8843783          	ld	a5,-120(s0)
    80006842:	00878713          	addi	a4,a5,8
    80006846:	f8e43423          	sd	a4,-120(s0)
    8000684a:	4685                	li	a3,1
    8000684c:	4629                	li	a2,10
    8000684e:	438c                	lw	a1,0(a5)
    80006850:	009b8533          	add	a0,s7,s1
    80006854:	00000097          	auipc	ra,0x0
    80006858:	ea2080e7          	jalr	-350(ra) # 800066f6 <sprintint>
    8000685c:	9ca9                	addw	s1,s1,a0
      break;
    8000685e:	b775                	j	8000680a <snprintf+0x7c>
    switch(c){
    80006860:	09979863          	bne	a5,s9,800068f0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006864:	f8843783          	ld	a5,-120(s0)
    80006868:	00878713          	addi	a4,a5,8
    8000686c:	f8e43423          	sd	a4,-120(s0)
    80006870:	4685                	li	a3,1
    80006872:	4641                	li	a2,16
    80006874:	438c                	lw	a1,0(a5)
    80006876:	009b8533          	add	a0,s7,s1
    8000687a:	00000097          	auipc	ra,0x0
    8000687e:	e7c080e7          	jalr	-388(ra) # 800066f6 <sprintint>
    80006882:	9ca9                	addw	s1,s1,a0
      break;
    80006884:	b759                	j	8000680a <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006886:	f8843783          	ld	a5,-120(s0)
    8000688a:	00878713          	addi	a4,a5,8
    8000688e:	f8e43423          	sd	a4,-120(s0)
    80006892:	639c                	ld	a5,0(a5)
    80006894:	c3b1                	beqz	a5,800068d8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006896:	0007c703          	lbu	a4,0(a5)
    8000689a:	db25                	beqz	a4,8000680a <snprintf+0x7c>
    8000689c:	0134de63          	bge	s1,s3,800068b8 <snprintf+0x12a>
    800068a0:	009b86b3          	add	a3,s7,s1
  *s = c;
    800068a4:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    800068a8:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    800068aa:	0785                	addi	a5,a5,1
    800068ac:	0007c703          	lbu	a4,0(a5)
    800068b0:	df29                	beqz	a4,8000680a <snprintf+0x7c>
    800068b2:	0685                	addi	a3,a3,1
    800068b4:	fe9998e3          	bne	s3,s1,800068a4 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    800068b8:	8526                	mv	a0,s1
    800068ba:	70e6                	ld	ra,120(sp)
    800068bc:	7446                	ld	s0,112(sp)
    800068be:	74a6                	ld	s1,104(sp)
    800068c0:	7906                	ld	s2,96(sp)
    800068c2:	69e6                	ld	s3,88(sp)
    800068c4:	6a46                	ld	s4,80(sp)
    800068c6:	6aa6                	ld	s5,72(sp)
    800068c8:	6b06                	ld	s6,64(sp)
    800068ca:	7be2                	ld	s7,56(sp)
    800068cc:	7c42                	ld	s8,48(sp)
    800068ce:	7ca2                	ld	s9,40(sp)
    800068d0:	7d02                	ld	s10,32(sp)
    800068d2:	6de2                	ld	s11,24(sp)
    800068d4:	614d                	addi	sp,sp,176
    800068d6:	8082                	ret
        s = "(null)";
    800068d8:	00001797          	auipc	a5,0x1
    800068dc:	74878793          	addi	a5,a5,1864 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800068e0:	876e                	mv	a4,s11
    800068e2:	bf6d                	j	8000689c <snprintf+0x10e>
  *s = c;
    800068e4:	009b87b3          	add	a5,s7,s1
    800068e8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800068ec:	2485                	addiw	s1,s1,1
      break;
    800068ee:	bf31                	j	8000680a <snprintf+0x7c>
  *s = c;
    800068f0:	009b8733          	add	a4,s7,s1
    800068f4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800068f8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800068fc:	975e                	add	a4,a4,s7
    800068fe:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006902:	2489                	addiw	s1,s1,2
      break;
    80006904:	b719                	j	8000680a <snprintf+0x7c>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...

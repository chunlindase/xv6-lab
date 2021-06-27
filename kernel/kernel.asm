
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	c9478793          	addi	a5,a5,-876 # 80005cf0 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e7478793          	addi	a5,a5,-396 # 80000f1a <main>
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
    80000110:	b60080e7          	jalr	-1184(ra) # 80000c6c <acquire>
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
    8000012a:	3d8080e7          	jalr	984(ra) # 800024fe <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	806080e7          	jalr	-2042(ra) # 8000093c <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bd2080e7          	jalr	-1070(ra) # 80000d20 <release>

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
    800001a2:	ace080e7          	jalr	-1330(ra) # 80000c6c <acquire>
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
    800001d2:	86c080e7          	jalr	-1940(ra) # 80001a3a <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	068080e7          	jalr	104(ra) # 80002246 <sleep>
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
    8000021e:	28e080e7          	jalr	654(ra) # 800024a8 <either_copyout>
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
    8000023a:	aea080e7          	jalr	-1302(ra) # 80000d20 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	ad4080e7          	jalr	-1324(ra) # 80000d20 <release>
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
    8000029a:	5c0080e7          	jalr	1472(ra) # 80000856 <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5ae080e7          	jalr	1454(ra) # 80000856 <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5a2080e7          	jalr	1442(ra) # 80000856 <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	598080e7          	jalr	1432(ra) # 80000856 <uartputc_sync>
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
    800002e2:	98e080e7          	jalr	-1650(ra) # 80000c6c <acquire>

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
    80000300:	258080e7          	jalr	600(ra) # 80002554 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a14080e7          	jalr	-1516(ra) # 80000d20 <release>
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
    80000454:	f7c080e7          	jalr	-132(ra) # 800023cc <wakeup>
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
    80000476:	76a080e7          	jalr	1898(ra) # 80000bdc <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	38c080e7          	jalr	908(ra) # 80000806 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00022797          	auipc	a5,0x22
    80000486:	b2e78793          	addi	a5,a5,-1234 # 80021fb0 <devsw>
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
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
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
    8000057a:	b6a50513          	addi	a0,a0,-1174 # 800080e0 <digits+0x88>
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
    800005f4:	a68b8b93          	addi	s7,s7,-1432 # 80008058 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	662080e7          	jalr	1634(ra) # 80000c6c <acquire>
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
    80000772:	5b2080e7          	jalr	1458(ra) # 80000d20 <release>
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
    80000798:	448080e7          	jalr	1096(ra) # 80000bdc <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <backtrace>:


void backtrace(){
    800007aa:	7179                	addi	sp,sp,-48
    800007ac:	f406                	sd	ra,40(sp)
    800007ae:	f022                	sd	s0,32(sp)
    800007b0:	ec26                	sd	s1,24(sp)
    800007b2:	e84a                	sd	s2,16(sp)
    800007b4:	e44e                	sd	s3,8(sp)
    800007b6:	1800                	addi	s0,sp,48
  printf("backtrace:\n");
    800007b8:	00008517          	auipc	a0,0x8
    800007bc:	88850513          	addi	a0,a0,-1912 # 80008040 <etext+0x40>
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	dd2080e7          	jalr	-558(ra) # 80000592 <printf>



static inline uint64 r_fp(){
    uint64 x;
    asm volatile("mv %0, s0" : "=r" (x) );
    800007c8:	84a2                	mv	s1,s0
  uint64 fp=r_fp();
  uint64 base=PGROUNDUP(fp);
    800007ca:	6905                	lui	s2,0x1
    800007cc:	197d                	addi	s2,s2,-1
    800007ce:	9926                	add	s2,s2,s1
    800007d0:	77fd                	lui	a5,0xfffff
    800007d2:	00f97933          	and	s2,s2,a5
  while(fp<base){
    800007d6:	0324f163          	bgeu	s1,s2,800007f8 <backtrace+0x4e>
    printf("%p\n",*((uint64*)(fp-8)));
    800007da:	00008997          	auipc	s3,0x8
    800007de:	87698993          	addi	s3,s3,-1930 # 80008050 <etext+0x50>
    800007e2:	ff84b583          	ld	a1,-8(s1)
    800007e6:	854e                	mv	a0,s3
    800007e8:	00000097          	auipc	ra,0x0
    800007ec:	daa080e7          	jalr	-598(ra) # 80000592 <printf>
    fp=*((uint64*)(fp-16));
    800007f0:	ff04b483          	ld	s1,-16(s1)
  while(fp<base){
    800007f4:	ff24e7e3          	bltu	s1,s2,800007e2 <backtrace+0x38>

  }
    800007f8:	70a2                	ld	ra,40(sp)
    800007fa:	7402                	ld	s0,32(sp)
    800007fc:	64e2                	ld	s1,24(sp)
    800007fe:	6942                	ld	s2,16(sp)
    80000800:	69a2                	ld	s3,8(sp)
    80000802:	6145                	addi	sp,sp,48
    80000804:	8082                	ret

0000000080000806 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000806:	1141                	addi	sp,sp,-16
    80000808:	e406                	sd	ra,8(sp)
    8000080a:	e022                	sd	s0,0(sp)
    8000080c:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000080e:	100007b7          	lui	a5,0x10000
    80000812:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000816:	f8000713          	li	a4,-128
    8000081a:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000081e:	470d                	li	a4,3
    80000820:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000824:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000828:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000082c:	469d                	li	a3,7
    8000082e:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000832:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000836:	00008597          	auipc	a1,0x8
    8000083a:	83a58593          	addi	a1,a1,-1990 # 80008070 <digits+0x18>
    8000083e:	00011517          	auipc	a0,0x11
    80000842:	0ba50513          	addi	a0,a0,186 # 800118f8 <uart_tx_lock>
    80000846:	00000097          	auipc	ra,0x0
    8000084a:	396080e7          	jalr	918(ra) # 80000bdc <initlock>
}
    8000084e:	60a2                	ld	ra,8(sp)
    80000850:	6402                	ld	s0,0(sp)
    80000852:	0141                	addi	sp,sp,16
    80000854:	8082                	ret

0000000080000856 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000856:	1101                	addi	sp,sp,-32
    80000858:	ec06                	sd	ra,24(sp)
    8000085a:	e822                	sd	s0,16(sp)
    8000085c:	e426                	sd	s1,8(sp)
    8000085e:	1000                	addi	s0,sp,32
    80000860:	84aa                	mv	s1,a0
  push_off();
    80000862:	00000097          	auipc	ra,0x0
    80000866:	3be080e7          	jalr	958(ra) # 80000c20 <push_off>

  if(panicked){
    8000086a:	00008797          	auipc	a5,0x8
    8000086e:	7967a783          	lw	a5,1942(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000872:	10000737          	lui	a4,0x10000
  if(panicked){
    80000876:	c391                	beqz	a5,8000087a <uartputc_sync+0x24>
    for(;;)
    80000878:	a001                	j	80000878 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000087a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000087e:	0ff7f793          	andi	a5,a5,255
    80000882:	0207f793          	andi	a5,a5,32
    80000886:	dbf5                	beqz	a5,8000087a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000888:	0ff4f793          	andi	a5,s1,255
    8000088c:	10000737          	lui	a4,0x10000
    80000890:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000894:	00000097          	auipc	ra,0x0
    80000898:	42c080e7          	jalr	1068(ra) # 80000cc0 <pop_off>
}
    8000089c:	60e2                	ld	ra,24(sp)
    8000089e:	6442                	ld	s0,16(sp)
    800008a0:	64a2                	ld	s1,8(sp)
    800008a2:	6105                	addi	sp,sp,32
    800008a4:	8082                	ret

00000000800008a6 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008a6:	00008797          	auipc	a5,0x8
    800008aa:	75e7a783          	lw	a5,1886(a5) # 80009004 <uart_tx_r>
    800008ae:	00008717          	auipc	a4,0x8
    800008b2:	75a72703          	lw	a4,1882(a4) # 80009008 <uart_tx_w>
    800008b6:	08f70263          	beq	a4,a5,8000093a <uartstart+0x94>
{
    800008ba:	7139                	addi	sp,sp,-64
    800008bc:	fc06                	sd	ra,56(sp)
    800008be:	f822                	sd	s0,48(sp)
    800008c0:	f426                	sd	s1,40(sp)
    800008c2:	f04a                	sd	s2,32(sp)
    800008c4:	ec4e                	sd	s3,24(sp)
    800008c6:	e852                	sd	s4,16(sp)
    800008c8:	e456                	sd	s5,8(sp)
    800008ca:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008cc:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008d0:	00011a17          	auipc	s4,0x11
    800008d4:	028a0a13          	addi	s4,s4,40 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008d8:	00008497          	auipc	s1,0x8
    800008dc:	72c48493          	addi	s1,s1,1836 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008e0:	00008997          	auipc	s3,0x8
    800008e4:	72898993          	addi	s3,s3,1832 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008e8:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    800008ec:	0ff77713          	andi	a4,a4,255
    800008f0:	02077713          	andi	a4,a4,32
    800008f4:	cb15                	beqz	a4,80000928 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008f6:	00fa0733          	add	a4,s4,a5
    800008fa:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008fe:	2785                	addiw	a5,a5,1
    80000900:	41f7d71b          	sraiw	a4,a5,0x1f
    80000904:	01b7571b          	srliw	a4,a4,0x1b
    80000908:	9fb9                	addw	a5,a5,a4
    8000090a:	8bfd                	andi	a5,a5,31
    8000090c:	9f99                	subw	a5,a5,a4
    8000090e:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000910:	8526                	mv	a0,s1
    80000912:	00002097          	auipc	ra,0x2
    80000916:	aba080e7          	jalr	-1350(ra) # 800023cc <wakeup>
    
    WriteReg(THR, c);
    8000091a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000091e:	409c                	lw	a5,0(s1)
    80000920:	0009a703          	lw	a4,0(s3)
    80000924:	fcf712e3          	bne	a4,a5,800008e8 <uartstart+0x42>
  }
}
    80000928:	70e2                	ld	ra,56(sp)
    8000092a:	7442                	ld	s0,48(sp)
    8000092c:	74a2                	ld	s1,40(sp)
    8000092e:	7902                	ld	s2,32(sp)
    80000930:	69e2                	ld	s3,24(sp)
    80000932:	6a42                	ld	s4,16(sp)
    80000934:	6aa2                	ld	s5,8(sp)
    80000936:	6121                	addi	sp,sp,64
    80000938:	8082                	ret
    8000093a:	8082                	ret

000000008000093c <uartputc>:
{
    8000093c:	7179                	addi	sp,sp,-48
    8000093e:	f406                	sd	ra,40(sp)
    80000940:	f022                	sd	s0,32(sp)
    80000942:	ec26                	sd	s1,24(sp)
    80000944:	e84a                	sd	s2,16(sp)
    80000946:	e44e                	sd	s3,8(sp)
    80000948:	e052                	sd	s4,0(sp)
    8000094a:	1800                	addi	s0,sp,48
    8000094c:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    8000094e:	00011517          	auipc	a0,0x11
    80000952:	faa50513          	addi	a0,a0,-86 # 800118f8 <uart_tx_lock>
    80000956:	00000097          	auipc	ra,0x0
    8000095a:	316080e7          	jalr	790(ra) # 80000c6c <acquire>
  if(panicked){
    8000095e:	00008797          	auipc	a5,0x8
    80000962:	6a27a783          	lw	a5,1698(a5) # 80009000 <panicked>
    80000966:	c391                	beqz	a5,8000096a <uartputc+0x2e>
    for(;;)
    80000968:	a001                	j	80000968 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000096a:	00008717          	auipc	a4,0x8
    8000096e:	69e72703          	lw	a4,1694(a4) # 80009008 <uart_tx_w>
    80000972:	0017079b          	addiw	a5,a4,1
    80000976:	41f7d69b          	sraiw	a3,a5,0x1f
    8000097a:	01b6d69b          	srliw	a3,a3,0x1b
    8000097e:	9fb5                	addw	a5,a5,a3
    80000980:	8bfd                	andi	a5,a5,31
    80000982:	9f95                	subw	a5,a5,a3
    80000984:	00008697          	auipc	a3,0x8
    80000988:	6806a683          	lw	a3,1664(a3) # 80009004 <uart_tx_r>
    8000098c:	04f69263          	bne	a3,a5,800009d0 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000990:	00011a17          	auipc	s4,0x11
    80000994:	f68a0a13          	addi	s4,s4,-152 # 800118f8 <uart_tx_lock>
    80000998:	00008497          	auipc	s1,0x8
    8000099c:	66c48493          	addi	s1,s1,1644 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a0:	00008917          	auipc	s2,0x8
    800009a4:	66890913          	addi	s2,s2,1640 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009a8:	85d2                	mv	a1,s4
    800009aa:	8526                	mv	a0,s1
    800009ac:	00002097          	auipc	ra,0x2
    800009b0:	89a080e7          	jalr	-1894(ra) # 80002246 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009b4:	00092703          	lw	a4,0(s2)
    800009b8:	0017079b          	addiw	a5,a4,1
    800009bc:	41f7d69b          	sraiw	a3,a5,0x1f
    800009c0:	01b6d69b          	srliw	a3,a3,0x1b
    800009c4:	9fb5                	addw	a5,a5,a3
    800009c6:	8bfd                	andi	a5,a5,31
    800009c8:	9f95                	subw	a5,a5,a3
    800009ca:	4094                	lw	a3,0(s1)
    800009cc:	fcf68ee3          	beq	a3,a5,800009a8 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009d0:	00011497          	auipc	s1,0x11
    800009d4:	f2848493          	addi	s1,s1,-216 # 800118f8 <uart_tx_lock>
    800009d8:	9726                	add	a4,a4,s1
    800009da:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009de:	00008717          	auipc	a4,0x8
    800009e2:	62f72523          	sw	a5,1578(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	ec0080e7          	jalr	-320(ra) # 800008a6 <uartstart>
      release(&uart_tx_lock);
    800009ee:	8526                	mv	a0,s1
    800009f0:	00000097          	auipc	ra,0x0
    800009f4:	330080e7          	jalr	816(ra) # 80000d20 <release>
}
    800009f8:	70a2                	ld	ra,40(sp)
    800009fa:	7402                	ld	s0,32(sp)
    800009fc:	64e2                	ld	s1,24(sp)
    800009fe:	6942                	ld	s2,16(sp)
    80000a00:	69a2                	ld	s3,8(sp)
    80000a02:	6a02                	ld	s4,0(sp)
    80000a04:	6145                	addi	sp,sp,48
    80000a06:	8082                	ret

0000000080000a08 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a08:	1141                	addi	sp,sp,-16
    80000a0a:	e422                	sd	s0,8(sp)
    80000a0c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a0e:	100007b7          	lui	a5,0x10000
    80000a12:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a16:	8b85                	andi	a5,a5,1
    80000a18:	cb91                	beqz	a5,80000a2c <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a1a:	100007b7          	lui	a5,0x10000
    80000a1e:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a22:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a26:	6422                	ld	s0,8(sp)
    80000a28:	0141                	addi	sp,sp,16
    80000a2a:	8082                	ret
    return -1;
    80000a2c:	557d                	li	a0,-1
    80000a2e:	bfe5                	j	80000a26 <uartgetc+0x1e>

0000000080000a30 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a30:	1101                	addi	sp,sp,-32
    80000a32:	ec06                	sd	ra,24(sp)
    80000a34:	e822                	sd	s0,16(sp)
    80000a36:	e426                	sd	s1,8(sp)
    80000a38:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a3a:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	fcc080e7          	jalr	-52(ra) # 80000a08 <uartgetc>
    if(c == -1)
    80000a44:	00950763          	beq	a0,s1,80000a52 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a48:	00000097          	auipc	ra,0x0
    80000a4c:	880080e7          	jalr	-1920(ra) # 800002c8 <consoleintr>
  while(1){
    80000a50:	b7f5                	j	80000a3c <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a52:	00011497          	auipc	s1,0x11
    80000a56:	ea648493          	addi	s1,s1,-346 # 800118f8 <uart_tx_lock>
    80000a5a:	8526                	mv	a0,s1
    80000a5c:	00000097          	auipc	ra,0x0
    80000a60:	210080e7          	jalr	528(ra) # 80000c6c <acquire>
  uartstart();
    80000a64:	00000097          	auipc	ra,0x0
    80000a68:	e42080e7          	jalr	-446(ra) # 800008a6 <uartstart>
  release(&uart_tx_lock);
    80000a6c:	8526                	mv	a0,s1
    80000a6e:	00000097          	auipc	ra,0x0
    80000a72:	2b2080e7          	jalr	690(ra) # 80000d20 <release>
}
    80000a76:	60e2                	ld	ra,24(sp)
    80000a78:	6442                	ld	s0,16(sp)
    80000a7a:	64a2                	ld	s1,8(sp)
    80000a7c:	6105                	addi	sp,sp,32
    80000a7e:	8082                	ret

0000000080000a80 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a80:	1101                	addi	sp,sp,-32
    80000a82:	ec06                	sd	ra,24(sp)
    80000a84:	e822                	sd	s0,16(sp)
    80000a86:	e426                	sd	s1,8(sp)
    80000a88:	e04a                	sd	s2,0(sp)
    80000a8a:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a8c:	03451793          	slli	a5,a0,0x34
    80000a90:	ebb9                	bnez	a5,80000ae6 <kfree+0x66>
    80000a92:	84aa                	mv	s1,a0
    80000a94:	00026797          	auipc	a5,0x26
    80000a98:	56c78793          	addi	a5,a5,1388 # 80027000 <end>
    80000a9c:	04f56563          	bltu	a0,a5,80000ae6 <kfree+0x66>
    80000aa0:	47c5                	li	a5,17
    80000aa2:	07ee                	slli	a5,a5,0x1b
    80000aa4:	04f57163          	bgeu	a0,a5,80000ae6 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000aa8:	6605                	lui	a2,0x1
    80000aaa:	4585                	li	a1,1
    80000aac:	00000097          	auipc	ra,0x0
    80000ab0:	2bc080e7          	jalr	700(ra) # 80000d68 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000ab4:	00011917          	auipc	s2,0x11
    80000ab8:	e7c90913          	addi	s2,s2,-388 # 80011930 <kmem>
    80000abc:	854a                	mv	a0,s2
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	1ae080e7          	jalr	430(ra) # 80000c6c <acquire>
  r->next = kmem.freelist;
    80000ac6:	01893783          	ld	a5,24(s2)
    80000aca:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000acc:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ad0:	854a                	mv	a0,s2
    80000ad2:	00000097          	auipc	ra,0x0
    80000ad6:	24e080e7          	jalr	590(ra) # 80000d20 <release>
}
    80000ada:	60e2                	ld	ra,24(sp)
    80000adc:	6442                	ld	s0,16(sp)
    80000ade:	64a2                	ld	s1,8(sp)
    80000ae0:	6902                	ld	s2,0(sp)
    80000ae2:	6105                	addi	sp,sp,32
    80000ae4:	8082                	ret
    panic("kfree");
    80000ae6:	00007517          	auipc	a0,0x7
    80000aea:	59250513          	addi	a0,a0,1426 # 80008078 <digits+0x20>
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	a5a080e7          	jalr	-1446(ra) # 80000548 <panic>

0000000080000af6 <freerange>:
{
    80000af6:	7179                	addi	sp,sp,-48
    80000af8:	f406                	sd	ra,40(sp)
    80000afa:	f022                	sd	s0,32(sp)
    80000afc:	ec26                	sd	s1,24(sp)
    80000afe:	e84a                	sd	s2,16(sp)
    80000b00:	e44e                	sd	s3,8(sp)
    80000b02:	e052                	sd	s4,0(sp)
    80000b04:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b06:	6785                	lui	a5,0x1
    80000b08:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b0c:	94aa                	add	s1,s1,a0
    80000b0e:	757d                	lui	a0,0xfffff
    80000b10:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b12:	94be                	add	s1,s1,a5
    80000b14:	0095ee63          	bltu	a1,s1,80000b30 <freerange+0x3a>
    80000b18:	892e                	mv	s2,a1
    kfree(p);
    80000b1a:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b1c:	6985                	lui	s3,0x1
    kfree(p);
    80000b1e:	01448533          	add	a0,s1,s4
    80000b22:	00000097          	auipc	ra,0x0
    80000b26:	f5e080e7          	jalr	-162(ra) # 80000a80 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2a:	94ce                	add	s1,s1,s3
    80000b2c:	fe9979e3          	bgeu	s2,s1,80000b1e <freerange+0x28>
}
    80000b30:	70a2                	ld	ra,40(sp)
    80000b32:	7402                	ld	s0,32(sp)
    80000b34:	64e2                	ld	s1,24(sp)
    80000b36:	6942                	ld	s2,16(sp)
    80000b38:	69a2                	ld	s3,8(sp)
    80000b3a:	6a02                	ld	s4,0(sp)
    80000b3c:	6145                	addi	sp,sp,48
    80000b3e:	8082                	ret

0000000080000b40 <kinit>:
{
    80000b40:	1141                	addi	sp,sp,-16
    80000b42:	e406                	sd	ra,8(sp)
    80000b44:	e022                	sd	s0,0(sp)
    80000b46:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b48:	00007597          	auipc	a1,0x7
    80000b4c:	53858593          	addi	a1,a1,1336 # 80008080 <digits+0x28>
    80000b50:	00011517          	auipc	a0,0x11
    80000b54:	de050513          	addi	a0,a0,-544 # 80011930 <kmem>
    80000b58:	00000097          	auipc	ra,0x0
    80000b5c:	084080e7          	jalr	132(ra) # 80000bdc <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b60:	45c5                	li	a1,17
    80000b62:	05ee                	slli	a1,a1,0x1b
    80000b64:	00026517          	auipc	a0,0x26
    80000b68:	49c50513          	addi	a0,a0,1180 # 80027000 <end>
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	f8a080e7          	jalr	-118(ra) # 80000af6 <freerange>
}
    80000b74:	60a2                	ld	ra,8(sp)
    80000b76:	6402                	ld	s0,0(sp)
    80000b78:	0141                	addi	sp,sp,16
    80000b7a:	8082                	ret

0000000080000b7c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b7c:	1101                	addi	sp,sp,-32
    80000b7e:	ec06                	sd	ra,24(sp)
    80000b80:	e822                	sd	s0,16(sp)
    80000b82:	e426                	sd	s1,8(sp)
    80000b84:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b86:	00011497          	auipc	s1,0x11
    80000b8a:	daa48493          	addi	s1,s1,-598 # 80011930 <kmem>
    80000b8e:	8526                	mv	a0,s1
    80000b90:	00000097          	auipc	ra,0x0
    80000b94:	0dc080e7          	jalr	220(ra) # 80000c6c <acquire>
  r = kmem.freelist;
    80000b98:	6c84                	ld	s1,24(s1)
  if(r)
    80000b9a:	c885                	beqz	s1,80000bca <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b9c:	609c                	ld	a5,0(s1)
    80000b9e:	00011517          	auipc	a0,0x11
    80000ba2:	d9250513          	addi	a0,a0,-622 # 80011930 <kmem>
    80000ba6:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	178080e7          	jalr	376(ra) # 80000d20 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bb0:	6605                	lui	a2,0x1
    80000bb2:	4595                	li	a1,5
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	1b2080e7          	jalr	434(ra) # 80000d68 <memset>
  return (void*)r;
}
    80000bbe:	8526                	mv	a0,s1
    80000bc0:	60e2                	ld	ra,24(sp)
    80000bc2:	6442                	ld	s0,16(sp)
    80000bc4:	64a2                	ld	s1,8(sp)
    80000bc6:	6105                	addi	sp,sp,32
    80000bc8:	8082                	ret
  release(&kmem.lock);
    80000bca:	00011517          	auipc	a0,0x11
    80000bce:	d6650513          	addi	a0,a0,-666 # 80011930 <kmem>
    80000bd2:	00000097          	auipc	ra,0x0
    80000bd6:	14e080e7          	jalr	334(ra) # 80000d20 <release>
  if(r)
    80000bda:	b7d5                	j	80000bbe <kalloc+0x42>

0000000080000bdc <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bdc:	1141                	addi	sp,sp,-16
    80000bde:	e422                	sd	s0,8(sp)
    80000be0:	0800                	addi	s0,sp,16
  lk->name = name;
    80000be2:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000be4:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000be8:	00053823          	sd	zero,16(a0)
}
    80000bec:	6422                	ld	s0,8(sp)
    80000bee:	0141                	addi	sp,sp,16
    80000bf0:	8082                	ret

0000000080000bf2 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bf2:	411c                	lw	a5,0(a0)
    80000bf4:	e399                	bnez	a5,80000bfa <holding+0x8>
    80000bf6:	4501                	li	a0,0
  return r;
}
    80000bf8:	8082                	ret
{
    80000bfa:	1101                	addi	sp,sp,-32
    80000bfc:	ec06                	sd	ra,24(sp)
    80000bfe:	e822                	sd	s0,16(sp)
    80000c00:	e426                	sd	s1,8(sp)
    80000c02:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c04:	6904                	ld	s1,16(a0)
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	e18080e7          	jalr	-488(ra) # 80001a1e <mycpu>
    80000c0e:	40a48533          	sub	a0,s1,a0
    80000c12:	00153513          	seqz	a0,a0
}
    80000c16:	60e2                	ld	ra,24(sp)
    80000c18:	6442                	ld	s0,16(sp)
    80000c1a:	64a2                	ld	s1,8(sp)
    80000c1c:	6105                	addi	sp,sp,32
    80000c1e:	8082                	ret

0000000080000c20 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c20:	1101                	addi	sp,sp,-32
    80000c22:	ec06                	sd	ra,24(sp)
    80000c24:	e822                	sd	s0,16(sp)
    80000c26:	e426                	sd	s1,8(sp)
    80000c28:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c2a:	100024f3          	csrr	s1,sstatus
    80000c2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c34:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c38:	00001097          	auipc	ra,0x1
    80000c3c:	de6080e7          	jalr	-538(ra) # 80001a1e <mycpu>
    80000c40:	5d3c                	lw	a5,120(a0)
    80000c42:	cf89                	beqz	a5,80000c5c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c44:	00001097          	auipc	ra,0x1
    80000c48:	dda080e7          	jalr	-550(ra) # 80001a1e <mycpu>
    80000c4c:	5d3c                	lw	a5,120(a0)
    80000c4e:	2785                	addiw	a5,a5,1
    80000c50:	dd3c                	sw	a5,120(a0)
}
    80000c52:	60e2                	ld	ra,24(sp)
    80000c54:	6442                	ld	s0,16(sp)
    80000c56:	64a2                	ld	s1,8(sp)
    80000c58:	6105                	addi	sp,sp,32
    80000c5a:	8082                	ret
    mycpu()->intena = old;
    80000c5c:	00001097          	auipc	ra,0x1
    80000c60:	dc2080e7          	jalr	-574(ra) # 80001a1e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c64:	8085                	srli	s1,s1,0x1
    80000c66:	8885                	andi	s1,s1,1
    80000c68:	dd64                	sw	s1,124(a0)
    80000c6a:	bfe9                	j	80000c44 <push_off+0x24>

0000000080000c6c <acquire>:
{
    80000c6c:	1101                	addi	sp,sp,-32
    80000c6e:	ec06                	sd	ra,24(sp)
    80000c70:	e822                	sd	s0,16(sp)
    80000c72:	e426                	sd	s1,8(sp)
    80000c74:	1000                	addi	s0,sp,32
    80000c76:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	fa8080e7          	jalr	-88(ra) # 80000c20 <push_off>
  if(holding(lk))
    80000c80:	8526                	mv	a0,s1
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	f70080e7          	jalr	-144(ra) # 80000bf2 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c8a:	4705                	li	a4,1
  if(holding(lk))
    80000c8c:	e115                	bnez	a0,80000cb0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c8e:	87ba                	mv	a5,a4
    80000c90:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c94:	2781                	sext.w	a5,a5
    80000c96:	ffe5                	bnez	a5,80000c8e <acquire+0x22>
  __sync_synchronize();
    80000c98:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c9c:	00001097          	auipc	ra,0x1
    80000ca0:	d82080e7          	jalr	-638(ra) # 80001a1e <mycpu>
    80000ca4:	e888                	sd	a0,16(s1)
}
    80000ca6:	60e2                	ld	ra,24(sp)
    80000ca8:	6442                	ld	s0,16(sp)
    80000caa:	64a2                	ld	s1,8(sp)
    80000cac:	6105                	addi	sp,sp,32
    80000cae:	8082                	ret
    panic("acquire");
    80000cb0:	00007517          	auipc	a0,0x7
    80000cb4:	3d850513          	addi	a0,a0,984 # 80008088 <digits+0x30>
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	890080e7          	jalr	-1904(ra) # 80000548 <panic>

0000000080000cc0 <pop_off>:

void
pop_off(void)
{
    80000cc0:	1141                	addi	sp,sp,-16
    80000cc2:	e406                	sd	ra,8(sp)
    80000cc4:	e022                	sd	s0,0(sp)
    80000cc6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cc8:	00001097          	auipc	ra,0x1
    80000ccc:	d56080e7          	jalr	-682(ra) # 80001a1e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cd4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cd6:	e78d                	bnez	a5,80000d00 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cd8:	5d3c                	lw	a5,120(a0)
    80000cda:	02f05b63          	blez	a5,80000d10 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cde:	37fd                	addiw	a5,a5,-1
    80000ce0:	0007871b          	sext.w	a4,a5
    80000ce4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000ce6:	eb09                	bnez	a4,80000cf8 <pop_off+0x38>
    80000ce8:	5d7c                	lw	a5,124(a0)
    80000cea:	c799                	beqz	a5,80000cf8 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cf0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cf4:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cf8:	60a2                	ld	ra,8(sp)
    80000cfa:	6402                	ld	s0,0(sp)
    80000cfc:	0141                	addi	sp,sp,16
    80000cfe:	8082                	ret
    panic("pop_off - interruptible");
    80000d00:	00007517          	auipc	a0,0x7
    80000d04:	39050513          	addi	a0,a0,912 # 80008090 <digits+0x38>
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	840080e7          	jalr	-1984(ra) # 80000548 <panic>
    panic("pop_off");
    80000d10:	00007517          	auipc	a0,0x7
    80000d14:	39850513          	addi	a0,a0,920 # 800080a8 <digits+0x50>
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	830080e7          	jalr	-2000(ra) # 80000548 <panic>

0000000080000d20 <release>:
{
    80000d20:	1101                	addi	sp,sp,-32
    80000d22:	ec06                	sd	ra,24(sp)
    80000d24:	e822                	sd	s0,16(sp)
    80000d26:	e426                	sd	s1,8(sp)
    80000d28:	1000                	addi	s0,sp,32
    80000d2a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	ec6080e7          	jalr	-314(ra) # 80000bf2 <holding>
    80000d34:	c115                	beqz	a0,80000d58 <release+0x38>
  lk->cpu = 0;
    80000d36:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d3a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d3e:	0f50000f          	fence	iorw,ow
    80000d42:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d46:	00000097          	auipc	ra,0x0
    80000d4a:	f7a080e7          	jalr	-134(ra) # 80000cc0 <pop_off>
}
    80000d4e:	60e2                	ld	ra,24(sp)
    80000d50:	6442                	ld	s0,16(sp)
    80000d52:	64a2                	ld	s1,8(sp)
    80000d54:	6105                	addi	sp,sp,32
    80000d56:	8082                	ret
    panic("release");
    80000d58:	00007517          	auipc	a0,0x7
    80000d5c:	35850513          	addi	a0,a0,856 # 800080b0 <digits+0x58>
    80000d60:	fffff097          	auipc	ra,0xfffff
    80000d64:	7e8080e7          	jalr	2024(ra) # 80000548 <panic>

0000000080000d68 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d68:	1141                	addi	sp,sp,-16
    80000d6a:	e422                	sd	s0,8(sp)
    80000d6c:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d6e:	ce09                	beqz	a2,80000d88 <memset+0x20>
    80000d70:	87aa                	mv	a5,a0
    80000d72:	fff6071b          	addiw	a4,a2,-1
    80000d76:	1702                	slli	a4,a4,0x20
    80000d78:	9301                	srli	a4,a4,0x20
    80000d7a:	0705                	addi	a4,a4,1
    80000d7c:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d7e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d82:	0785                	addi	a5,a5,1
    80000d84:	fee79de3          	bne	a5,a4,80000d7e <memset+0x16>
  }
  return dst;
}
    80000d88:	6422                	ld	s0,8(sp)
    80000d8a:	0141                	addi	sp,sp,16
    80000d8c:	8082                	ret

0000000080000d8e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d8e:	1141                	addi	sp,sp,-16
    80000d90:	e422                	sd	s0,8(sp)
    80000d92:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d94:	ca05                	beqz	a2,80000dc4 <memcmp+0x36>
    80000d96:	fff6069b          	addiw	a3,a2,-1
    80000d9a:	1682                	slli	a3,a3,0x20
    80000d9c:	9281                	srli	a3,a3,0x20
    80000d9e:	0685                	addi	a3,a3,1
    80000da0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000da2:	00054783          	lbu	a5,0(a0)
    80000da6:	0005c703          	lbu	a4,0(a1)
    80000daa:	00e79863          	bne	a5,a4,80000dba <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dae:	0505                	addi	a0,a0,1
    80000db0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000db2:	fed518e3          	bne	a0,a3,80000da2 <memcmp+0x14>
  }

  return 0;
    80000db6:	4501                	li	a0,0
    80000db8:	a019                	j	80000dbe <memcmp+0x30>
      return *s1 - *s2;
    80000dba:	40e7853b          	subw	a0,a5,a4
}
    80000dbe:	6422                	ld	s0,8(sp)
    80000dc0:	0141                	addi	sp,sp,16
    80000dc2:	8082                	ret
  return 0;
    80000dc4:	4501                	li	a0,0
    80000dc6:	bfe5                	j	80000dbe <memcmp+0x30>

0000000080000dc8 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dc8:	1141                	addi	sp,sp,-16
    80000dca:	e422                	sd	s0,8(sp)
    80000dcc:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dce:	00a5f963          	bgeu	a1,a0,80000de0 <memmove+0x18>
    80000dd2:	02061713          	slli	a4,a2,0x20
    80000dd6:	9301                	srli	a4,a4,0x20
    80000dd8:	00e587b3          	add	a5,a1,a4
    80000ddc:	02f56563          	bltu	a0,a5,80000e06 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de0:	fff6069b          	addiw	a3,a2,-1
    80000de4:	ce11                	beqz	a2,80000e00 <memmove+0x38>
    80000de6:	1682                	slli	a3,a3,0x20
    80000de8:	9281                	srli	a3,a3,0x20
    80000dea:	0685                	addi	a3,a3,1
    80000dec:	96ae                	add	a3,a3,a1
    80000dee:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000df0:	0585                	addi	a1,a1,1
    80000df2:	0785                	addi	a5,a5,1
    80000df4:	fff5c703          	lbu	a4,-1(a1)
    80000df8:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dfc:	fed59ae3          	bne	a1,a3,80000df0 <memmove+0x28>

  return dst;
}
    80000e00:	6422                	ld	s0,8(sp)
    80000e02:	0141                	addi	sp,sp,16
    80000e04:	8082                	ret
    d += n;
    80000e06:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e08:	fff6069b          	addiw	a3,a2,-1
    80000e0c:	da75                	beqz	a2,80000e00 <memmove+0x38>
    80000e0e:	02069613          	slli	a2,a3,0x20
    80000e12:	9201                	srli	a2,a2,0x20
    80000e14:	fff64613          	not	a2,a2
    80000e18:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e1a:	17fd                	addi	a5,a5,-1
    80000e1c:	177d                	addi	a4,a4,-1
    80000e1e:	0007c683          	lbu	a3,0(a5)
    80000e22:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e26:	fec79ae3          	bne	a5,a2,80000e1a <memmove+0x52>
    80000e2a:	bfd9                	j	80000e00 <memmove+0x38>

0000000080000e2c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e2c:	1141                	addi	sp,sp,-16
    80000e2e:	e406                	sd	ra,8(sp)
    80000e30:	e022                	sd	s0,0(sp)
    80000e32:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e34:	00000097          	auipc	ra,0x0
    80000e38:	f94080e7          	jalr	-108(ra) # 80000dc8 <memmove>
}
    80000e3c:	60a2                	ld	ra,8(sp)
    80000e3e:	6402                	ld	s0,0(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret

0000000080000e44 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e422                	sd	s0,8(sp)
    80000e48:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e4a:	ce11                	beqz	a2,80000e66 <strncmp+0x22>
    80000e4c:	00054783          	lbu	a5,0(a0)
    80000e50:	cf89                	beqz	a5,80000e6a <strncmp+0x26>
    80000e52:	0005c703          	lbu	a4,0(a1)
    80000e56:	00f71a63          	bne	a4,a5,80000e6a <strncmp+0x26>
    n--, p++, q++;
    80000e5a:	367d                	addiw	a2,a2,-1
    80000e5c:	0505                	addi	a0,a0,1
    80000e5e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e60:	f675                	bnez	a2,80000e4c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e62:	4501                	li	a0,0
    80000e64:	a809                	j	80000e76 <strncmp+0x32>
    80000e66:	4501                	li	a0,0
    80000e68:	a039                	j	80000e76 <strncmp+0x32>
  if(n == 0)
    80000e6a:	ca09                	beqz	a2,80000e7c <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e6c:	00054503          	lbu	a0,0(a0)
    80000e70:	0005c783          	lbu	a5,0(a1)
    80000e74:	9d1d                	subw	a0,a0,a5
}
    80000e76:	6422                	ld	s0,8(sp)
    80000e78:	0141                	addi	sp,sp,16
    80000e7a:	8082                	ret
    return 0;
    80000e7c:	4501                	li	a0,0
    80000e7e:	bfe5                	j	80000e76 <strncmp+0x32>

0000000080000e80 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e80:	1141                	addi	sp,sp,-16
    80000e82:	e422                	sd	s0,8(sp)
    80000e84:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e86:	872a                	mv	a4,a0
    80000e88:	8832                	mv	a6,a2
    80000e8a:	367d                	addiw	a2,a2,-1
    80000e8c:	01005963          	blez	a6,80000e9e <strncpy+0x1e>
    80000e90:	0705                	addi	a4,a4,1
    80000e92:	0005c783          	lbu	a5,0(a1)
    80000e96:	fef70fa3          	sb	a5,-1(a4)
    80000e9a:	0585                	addi	a1,a1,1
    80000e9c:	f7f5                	bnez	a5,80000e88 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e9e:	00c05d63          	blez	a2,80000eb8 <strncpy+0x38>
    80000ea2:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ea4:	0685                	addi	a3,a3,1
    80000ea6:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000eaa:	fff6c793          	not	a5,a3
    80000eae:	9fb9                	addw	a5,a5,a4
    80000eb0:	010787bb          	addw	a5,a5,a6
    80000eb4:	fef048e3          	bgtz	a5,80000ea4 <strncpy+0x24>
  return os;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret

0000000080000ebe <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e422                	sd	s0,8(sp)
    80000ec2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000ec4:	02c05363          	blez	a2,80000eea <safestrcpy+0x2c>
    80000ec8:	fff6069b          	addiw	a3,a2,-1
    80000ecc:	1682                	slli	a3,a3,0x20
    80000ece:	9281                	srli	a3,a3,0x20
    80000ed0:	96ae                	add	a3,a3,a1
    80000ed2:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000ed4:	00d58963          	beq	a1,a3,80000ee6 <safestrcpy+0x28>
    80000ed8:	0585                	addi	a1,a1,1
    80000eda:	0785                	addi	a5,a5,1
    80000edc:	fff5c703          	lbu	a4,-1(a1)
    80000ee0:	fee78fa3          	sb	a4,-1(a5)
    80000ee4:	fb65                	bnez	a4,80000ed4 <safestrcpy+0x16>
    ;
  *s = 0;
    80000ee6:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eea:	6422                	ld	s0,8(sp)
    80000eec:	0141                	addi	sp,sp,16
    80000eee:	8082                	ret

0000000080000ef0 <strlen>:

int
strlen(const char *s)
{
    80000ef0:	1141                	addi	sp,sp,-16
    80000ef2:	e422                	sd	s0,8(sp)
    80000ef4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ef6:	00054783          	lbu	a5,0(a0)
    80000efa:	cf91                	beqz	a5,80000f16 <strlen+0x26>
    80000efc:	0505                	addi	a0,a0,1
    80000efe:	87aa                	mv	a5,a0
    80000f00:	4685                	li	a3,1
    80000f02:	9e89                	subw	a3,a3,a0
    80000f04:	00f6853b          	addw	a0,a3,a5
    80000f08:	0785                	addi	a5,a5,1
    80000f0a:	fff7c703          	lbu	a4,-1(a5)
    80000f0e:	fb7d                	bnez	a4,80000f04 <strlen+0x14>
    ;
  return n;
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f16:	4501                	li	a0,0
    80000f18:	bfe5                	j	80000f10 <strlen+0x20>

0000000080000f1a <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f1a:	1141                	addi	sp,sp,-16
    80000f1c:	e406                	sd	ra,8(sp)
    80000f1e:	e022                	sd	s0,0(sp)
    80000f20:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f22:	00001097          	auipc	ra,0x1
    80000f26:	aec080e7          	jalr	-1300(ra) # 80001a0e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f2a:	00008717          	auipc	a4,0x8
    80000f2e:	0e270713          	addi	a4,a4,226 # 8000900c <started>
  if(cpuid() == 0){
    80000f32:	c139                	beqz	a0,80000f78 <main+0x5e>
    while(started == 0)
    80000f34:	431c                	lw	a5,0(a4)
    80000f36:	2781                	sext.w	a5,a5
    80000f38:	dff5                	beqz	a5,80000f34 <main+0x1a>
      ;
    __sync_synchronize();
    80000f3a:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	ad0080e7          	jalr	-1328(ra) # 80001a0e <cpuid>
    80000f46:	85aa                	mv	a1,a0
    80000f48:	00007517          	auipc	a0,0x7
    80000f4c:	18850513          	addi	a0,a0,392 # 800080d0 <digits+0x78>
    80000f50:	fffff097          	auipc	ra,0xfffff
    80000f54:	642080e7          	jalr	1602(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f58:	00000097          	auipc	ra,0x0
    80000f5c:	0d8080e7          	jalr	216(ra) # 80001030 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f60:	00001097          	auipc	ra,0x1
    80000f64:	734080e7          	jalr	1844(ra) # 80002694 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f68:	00005097          	auipc	ra,0x5
    80000f6c:	dc8080e7          	jalr	-568(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000f70:	00001097          	auipc	ra,0x1
    80000f74:	ffa080e7          	jalr	-6(ra) # 80001f6a <scheduler>
    consoleinit();
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	4e2080e7          	jalr	1250(ra) # 8000045a <consoleinit>
    printfinit();
    80000f80:	fffff097          	auipc	ra,0xfffff
    80000f84:	7f8080e7          	jalr	2040(ra) # 80000778 <printfinit>
    printf("\n");
    80000f88:	00007517          	auipc	a0,0x7
    80000f8c:	15850513          	addi	a0,a0,344 # 800080e0 <digits+0x88>
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	602080e7          	jalr	1538(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	12050513          	addi	a0,a0,288 # 800080b8 <digits+0x60>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5f2080e7          	jalr	1522(ra) # 80000592 <printf>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	13850513          	addi	a0,a0,312 # 800080e0 <digits+0x88>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	5e2080e7          	jalr	1506(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000fb8:	00000097          	auipc	ra,0x0
    80000fbc:	b88080e7          	jalr	-1144(ra) # 80000b40 <kinit>
    kvminit();       // create kernel page table
    80000fc0:	00000097          	auipc	ra,0x0
    80000fc4:	2a0080e7          	jalr	672(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000fc8:	00000097          	auipc	ra,0x0
    80000fcc:	068080e7          	jalr	104(ra) # 80001030 <kvminithart>
    procinit();      // process table
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	96e080e7          	jalr	-1682(ra) # 8000193e <procinit>
    trapinit();      // trap vectors
    80000fd8:	00001097          	auipc	ra,0x1
    80000fdc:	694080e7          	jalr	1684(ra) # 8000266c <trapinit>
    trapinithart();  // install kernel trap vector
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	6b4080e7          	jalr	1716(ra) # 80002694 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fe8:	00005097          	auipc	ra,0x5
    80000fec:	d32080e7          	jalr	-718(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ff0:	00005097          	auipc	ra,0x5
    80000ff4:	d40080e7          	jalr	-704(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	ee0080e7          	jalr	-288(ra) # 80002ed8 <binit>
    iinit();         // inode cache
    80001000:	00002097          	auipc	ra,0x2
    80001004:	570080e7          	jalr	1392(ra) # 80003570 <iinit>
    fileinit();      // file table
    80001008:	00003097          	auipc	ra,0x3
    8000100c:	50a080e7          	jalr	1290(ra) # 80004512 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001010:	00005097          	auipc	ra,0x5
    80001014:	e28080e7          	jalr	-472(ra) # 80005e38 <virtio_disk_init>
    userinit();      // first user process
    80001018:	00001097          	auipc	ra,0x1
    8000101c:	cec080e7          	jalr	-788(ra) # 80001d04 <userinit>
    __sync_synchronize();
    80001020:	0ff0000f          	fence
    started = 1;
    80001024:	4785                	li	a5,1
    80001026:	00008717          	auipc	a4,0x8
    8000102a:	fef72323          	sw	a5,-26(a4) # 8000900c <started>
    8000102e:	b789                	j	80000f70 <main+0x56>

0000000080001030 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001030:	1141                	addi	sp,sp,-16
    80001032:	e422                	sd	s0,8(sp)
    80001034:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001036:	00008797          	auipc	a5,0x8
    8000103a:	fda7b783          	ld	a5,-38(a5) # 80009010 <kernel_pagetable>
    8000103e:	83b1                	srli	a5,a5,0xc
    80001040:	577d                	li	a4,-1
    80001042:	177e                	slli	a4,a4,0x3f
    80001044:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001046:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000104a:	12000073          	sfence.vma
  sfence_vma();
}
    8000104e:	6422                	ld	s0,8(sp)
    80001050:	0141                	addi	sp,sp,16
    80001052:	8082                	ret

0000000080001054 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001054:	7139                	addi	sp,sp,-64
    80001056:	fc06                	sd	ra,56(sp)
    80001058:	f822                	sd	s0,48(sp)
    8000105a:	f426                	sd	s1,40(sp)
    8000105c:	f04a                	sd	s2,32(sp)
    8000105e:	ec4e                	sd	s3,24(sp)
    80001060:	e852                	sd	s4,16(sp)
    80001062:	e456                	sd	s5,8(sp)
    80001064:	e05a                	sd	s6,0(sp)
    80001066:	0080                	addi	s0,sp,64
    80001068:	84aa                	mv	s1,a0
    8000106a:	89ae                	mv	s3,a1
    8000106c:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001074:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001076:	04b7f263          	bgeu	a5,a1,800010ba <walk+0x66>
    panic("walk");
    8000107a:	00007517          	auipc	a0,0x7
    8000107e:	06e50513          	addi	a0,a0,110 # 800080e8 <digits+0x90>
    80001082:	fffff097          	auipc	ra,0xfffff
    80001086:	4c6080e7          	jalr	1222(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000108a:	060a8663          	beqz	s5,800010f6 <walk+0xa2>
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	aee080e7          	jalr	-1298(ra) # 80000b7c <kalloc>
    80001096:	84aa                	mv	s1,a0
    80001098:	c529                	beqz	a0,800010e2 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000109a:	6605                	lui	a2,0x1
    8000109c:	4581                	li	a1,0
    8000109e:	00000097          	auipc	ra,0x0
    800010a2:	cca080e7          	jalr	-822(ra) # 80000d68 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010a6:	00c4d793          	srli	a5,s1,0xc
    800010aa:	07aa                	slli	a5,a5,0xa
    800010ac:	0017e793          	ori	a5,a5,1
    800010b0:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010b4:	3a5d                	addiw	s4,s4,-9
    800010b6:	036a0063          	beq	s4,s6,800010d6 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010ba:	0149d933          	srl	s2,s3,s4
    800010be:	1ff97913          	andi	s2,s2,511
    800010c2:	090e                	slli	s2,s2,0x3
    800010c4:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010c6:	00093483          	ld	s1,0(s2)
    800010ca:	0014f793          	andi	a5,s1,1
    800010ce:	dfd5                	beqz	a5,8000108a <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010d0:	80a9                	srli	s1,s1,0xa
    800010d2:	04b2                	slli	s1,s1,0xc
    800010d4:	b7c5                	j	800010b4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010d6:	00c9d513          	srli	a0,s3,0xc
    800010da:	1ff57513          	andi	a0,a0,511
    800010de:	050e                	slli	a0,a0,0x3
    800010e0:	9526                	add	a0,a0,s1
}
    800010e2:	70e2                	ld	ra,56(sp)
    800010e4:	7442                	ld	s0,48(sp)
    800010e6:	74a2                	ld	s1,40(sp)
    800010e8:	7902                	ld	s2,32(sp)
    800010ea:	69e2                	ld	s3,24(sp)
    800010ec:	6a42                	ld	s4,16(sp)
    800010ee:	6aa2                	ld	s5,8(sp)
    800010f0:	6b02                	ld	s6,0(sp)
    800010f2:	6121                	addi	sp,sp,64
    800010f4:	8082                	ret
        return 0;
    800010f6:	4501                	li	a0,0
    800010f8:	b7ed                	j	800010e2 <walk+0x8e>

00000000800010fa <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010fa:	57fd                	li	a5,-1
    800010fc:	83e9                	srli	a5,a5,0x1a
    800010fe:	00b7f463          	bgeu	a5,a1,80001106 <walkaddr+0xc>
    return 0;
    80001102:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001104:	8082                	ret
{
    80001106:	1141                	addi	sp,sp,-16
    80001108:	e406                	sd	ra,8(sp)
    8000110a:	e022                	sd	s0,0(sp)
    8000110c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000110e:	4601                	li	a2,0
    80001110:	00000097          	auipc	ra,0x0
    80001114:	f44080e7          	jalr	-188(ra) # 80001054 <walk>
  if(pte == 0)
    80001118:	c105                	beqz	a0,80001138 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000111a:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000111c:	0117f693          	andi	a3,a5,17
    80001120:	4745                	li	a4,17
    return 0;
    80001122:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001124:	00e68663          	beq	a3,a4,80001130 <walkaddr+0x36>
}
    80001128:	60a2                	ld	ra,8(sp)
    8000112a:	6402                	ld	s0,0(sp)
    8000112c:	0141                	addi	sp,sp,16
    8000112e:	8082                	ret
  pa = PTE2PA(*pte);
    80001130:	00a7d513          	srli	a0,a5,0xa
    80001134:	0532                	slli	a0,a0,0xc
  return pa;
    80001136:	bfcd                	j	80001128 <walkaddr+0x2e>
    return 0;
    80001138:	4501                	li	a0,0
    8000113a:	b7fd                	j	80001128 <walkaddr+0x2e>

000000008000113c <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000113c:	1101                	addi	sp,sp,-32
    8000113e:	ec06                	sd	ra,24(sp)
    80001140:	e822                	sd	s0,16(sp)
    80001142:	e426                	sd	s1,8(sp)
    80001144:	1000                	addi	s0,sp,32
    80001146:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001148:	1552                	slli	a0,a0,0x34
    8000114a:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000114e:	4601                	li	a2,0
    80001150:	00008517          	auipc	a0,0x8
    80001154:	ec053503          	ld	a0,-320(a0) # 80009010 <kernel_pagetable>
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	efc080e7          	jalr	-260(ra) # 80001054 <walk>
  if(pte == 0)
    80001160:	cd09                	beqz	a0,8000117a <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001162:	6108                	ld	a0,0(a0)
    80001164:	00157793          	andi	a5,a0,1
    80001168:	c38d                	beqz	a5,8000118a <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000116a:	8129                	srli	a0,a0,0xa
    8000116c:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000116e:	9526                	add	a0,a0,s1
    80001170:	60e2                	ld	ra,24(sp)
    80001172:	6442                	ld	s0,16(sp)
    80001174:	64a2                	ld	s1,8(sp)
    80001176:	6105                	addi	sp,sp,32
    80001178:	8082                	ret
    panic("kvmpa");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7650513          	addi	a0,a0,-138 # 800080f0 <digits+0x98>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c6080e7          	jalr	966(ra) # 80000548 <panic>
    panic("kvmpa");
    8000118a:	00007517          	auipc	a0,0x7
    8000118e:	f6650513          	addi	a0,a0,-154 # 800080f0 <digits+0x98>
    80001192:	fffff097          	auipc	ra,0xfffff
    80001196:	3b6080e7          	jalr	950(ra) # 80000548 <panic>

000000008000119a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000119a:	715d                	addi	sp,sp,-80
    8000119c:	e486                	sd	ra,72(sp)
    8000119e:	e0a2                	sd	s0,64(sp)
    800011a0:	fc26                	sd	s1,56(sp)
    800011a2:	f84a                	sd	s2,48(sp)
    800011a4:	f44e                	sd	s3,40(sp)
    800011a6:	f052                	sd	s4,32(sp)
    800011a8:	ec56                	sd	s5,24(sp)
    800011aa:	e85a                	sd	s6,16(sp)
    800011ac:	e45e                	sd	s7,8(sp)
    800011ae:	0880                	addi	s0,sp,80
    800011b0:	8aaa                	mv	s5,a0
    800011b2:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011b4:	777d                	lui	a4,0xfffff
    800011b6:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011ba:	167d                	addi	a2,a2,-1
    800011bc:	00b609b3          	add	s3,a2,a1
    800011c0:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011c4:	893e                	mv	s2,a5
    800011c6:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011ca:	6b85                	lui	s7,0x1
    800011cc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011d0:	4605                	li	a2,1
    800011d2:	85ca                	mv	a1,s2
    800011d4:	8556                	mv	a0,s5
    800011d6:	00000097          	auipc	ra,0x0
    800011da:	e7e080e7          	jalr	-386(ra) # 80001054 <walk>
    800011de:	c51d                	beqz	a0,8000120c <mappages+0x72>
    if(*pte & PTE_V)
    800011e0:	611c                	ld	a5,0(a0)
    800011e2:	8b85                	andi	a5,a5,1
    800011e4:	ef81                	bnez	a5,800011fc <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011e6:	80b1                	srli	s1,s1,0xc
    800011e8:	04aa                	slli	s1,s1,0xa
    800011ea:	0164e4b3          	or	s1,s1,s6
    800011ee:	0014e493          	ori	s1,s1,1
    800011f2:	e104                	sd	s1,0(a0)
    if(a == last)
    800011f4:	03390863          	beq	s2,s3,80001224 <mappages+0x8a>
    a += PGSIZE;
    800011f8:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011fa:	bfc9                	j	800011cc <mappages+0x32>
      panic("remap");
    800011fc:	00007517          	auipc	a0,0x7
    80001200:	efc50513          	addi	a0,a0,-260 # 800080f8 <digits+0xa0>
    80001204:	fffff097          	auipc	ra,0xfffff
    80001208:	344080e7          	jalr	836(ra) # 80000548 <panic>
      return -1;
    8000120c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000120e:	60a6                	ld	ra,72(sp)
    80001210:	6406                	ld	s0,64(sp)
    80001212:	74e2                	ld	s1,56(sp)
    80001214:	7942                	ld	s2,48(sp)
    80001216:	79a2                	ld	s3,40(sp)
    80001218:	7a02                	ld	s4,32(sp)
    8000121a:	6ae2                	ld	s5,24(sp)
    8000121c:	6b42                	ld	s6,16(sp)
    8000121e:	6ba2                	ld	s7,8(sp)
    80001220:	6161                	addi	sp,sp,80
    80001222:	8082                	ret
  return 0;
    80001224:	4501                	li	a0,0
    80001226:	b7e5                	j	8000120e <mappages+0x74>

0000000080001228 <kvmmap>:
{
    80001228:	1141                	addi	sp,sp,-16
    8000122a:	e406                	sd	ra,8(sp)
    8000122c:	e022                	sd	s0,0(sp)
    8000122e:	0800                	addi	s0,sp,16
    80001230:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001232:	86ae                	mv	a3,a1
    80001234:	85aa                	mv	a1,a0
    80001236:	00008517          	auipc	a0,0x8
    8000123a:	dda53503          	ld	a0,-550(a0) # 80009010 <kernel_pagetable>
    8000123e:	00000097          	auipc	ra,0x0
    80001242:	f5c080e7          	jalr	-164(ra) # 8000119a <mappages>
    80001246:	e509                	bnez	a0,80001250 <kvmmap+0x28>
}
    80001248:	60a2                	ld	ra,8(sp)
    8000124a:	6402                	ld	s0,0(sp)
    8000124c:	0141                	addi	sp,sp,16
    8000124e:	8082                	ret
    panic("kvmmap");
    80001250:	00007517          	auipc	a0,0x7
    80001254:	eb050513          	addi	a0,a0,-336 # 80008100 <digits+0xa8>
    80001258:	fffff097          	auipc	ra,0xfffff
    8000125c:	2f0080e7          	jalr	752(ra) # 80000548 <panic>

0000000080001260 <kvminit>:
{
    80001260:	1101                	addi	sp,sp,-32
    80001262:	ec06                	sd	ra,24(sp)
    80001264:	e822                	sd	s0,16(sp)
    80001266:	e426                	sd	s1,8(sp)
    80001268:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000126a:	00000097          	auipc	ra,0x0
    8000126e:	912080e7          	jalr	-1774(ra) # 80000b7c <kalloc>
    80001272:	00008797          	auipc	a5,0x8
    80001276:	d8a7bf23          	sd	a0,-610(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000127a:	6605                	lui	a2,0x1
    8000127c:	4581                	li	a1,0
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	aea080e7          	jalr	-1302(ra) # 80000d68 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001286:	4699                	li	a3,6
    80001288:	6605                	lui	a2,0x1
    8000128a:	100005b7          	lui	a1,0x10000
    8000128e:	10000537          	lui	a0,0x10000
    80001292:	00000097          	auipc	ra,0x0
    80001296:	f96080e7          	jalr	-106(ra) # 80001228 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000129a:	4699                	li	a3,6
    8000129c:	6605                	lui	a2,0x1
    8000129e:	100015b7          	lui	a1,0x10001
    800012a2:	10001537          	lui	a0,0x10001
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f82080e7          	jalr	-126(ra) # 80001228 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012ae:	4699                	li	a3,6
    800012b0:	6641                	lui	a2,0x10
    800012b2:	020005b7          	lui	a1,0x2000
    800012b6:	02000537          	lui	a0,0x2000
    800012ba:	00000097          	auipc	ra,0x0
    800012be:	f6e080e7          	jalr	-146(ra) # 80001228 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012c2:	4699                	li	a3,6
    800012c4:	00400637          	lui	a2,0x400
    800012c8:	0c0005b7          	lui	a1,0xc000
    800012cc:	0c000537          	lui	a0,0xc000
    800012d0:	00000097          	auipc	ra,0x0
    800012d4:	f58080e7          	jalr	-168(ra) # 80001228 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012d8:	00007497          	auipc	s1,0x7
    800012dc:	d2848493          	addi	s1,s1,-728 # 80008000 <etext>
    800012e0:	46a9                	li	a3,10
    800012e2:	80007617          	auipc	a2,0x80007
    800012e6:	d1e60613          	addi	a2,a2,-738 # 8000 <_entry-0x7fff8000>
    800012ea:	4585                	li	a1,1
    800012ec:	05fe                	slli	a1,a1,0x1f
    800012ee:	852e                	mv	a0,a1
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	f38080e7          	jalr	-200(ra) # 80001228 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012f8:	4699                	li	a3,6
    800012fa:	4645                	li	a2,17
    800012fc:	066e                	slli	a2,a2,0x1b
    800012fe:	8e05                	sub	a2,a2,s1
    80001300:	85a6                	mv	a1,s1
    80001302:	8526                	mv	a0,s1
    80001304:	00000097          	auipc	ra,0x0
    80001308:	f24080e7          	jalr	-220(ra) # 80001228 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000130c:	46a9                	li	a3,10
    8000130e:	6605                	lui	a2,0x1
    80001310:	00006597          	auipc	a1,0x6
    80001314:	cf058593          	addi	a1,a1,-784 # 80007000 <_trampoline>
    80001318:	04000537          	lui	a0,0x4000
    8000131c:	157d                	addi	a0,a0,-1
    8000131e:	0532                	slli	a0,a0,0xc
    80001320:	00000097          	auipc	ra,0x0
    80001324:	f08080e7          	jalr	-248(ra) # 80001228 <kvmmap>
}
    80001328:	60e2                	ld	ra,24(sp)
    8000132a:	6442                	ld	s0,16(sp)
    8000132c:	64a2                	ld	s1,8(sp)
    8000132e:	6105                	addi	sp,sp,32
    80001330:	8082                	ret

0000000080001332 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001332:	715d                	addi	sp,sp,-80
    80001334:	e486                	sd	ra,72(sp)
    80001336:	e0a2                	sd	s0,64(sp)
    80001338:	fc26                	sd	s1,56(sp)
    8000133a:	f84a                	sd	s2,48(sp)
    8000133c:	f44e                	sd	s3,40(sp)
    8000133e:	f052                	sd	s4,32(sp)
    80001340:	ec56                	sd	s5,24(sp)
    80001342:	e85a                	sd	s6,16(sp)
    80001344:	e45e                	sd	s7,8(sp)
    80001346:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001348:	03459793          	slli	a5,a1,0x34
    8000134c:	e795                	bnez	a5,80001378 <uvmunmap+0x46>
    8000134e:	8a2a                	mv	s4,a0
    80001350:	892e                	mv	s2,a1
    80001352:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001354:	0632                	slli	a2,a2,0xc
    80001356:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000135a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000135c:	6b05                	lui	s6,0x1
    8000135e:	0735e863          	bltu	a1,s3,800013ce <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001362:	60a6                	ld	ra,72(sp)
    80001364:	6406                	ld	s0,64(sp)
    80001366:	74e2                	ld	s1,56(sp)
    80001368:	7942                	ld	s2,48(sp)
    8000136a:	79a2                	ld	s3,40(sp)
    8000136c:	7a02                	ld	s4,32(sp)
    8000136e:	6ae2                	ld	s5,24(sp)
    80001370:	6b42                	ld	s6,16(sp)
    80001372:	6ba2                	ld	s7,8(sp)
    80001374:	6161                	addi	sp,sp,80
    80001376:	8082                	ret
    panic("uvmunmap: not aligned");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	d9050513          	addi	a0,a0,-624 # 80008108 <digits+0xb0>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	1c8080e7          	jalr	456(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	d9850513          	addi	a0,a0,-616 # 80008120 <digits+0xc8>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	1b8080e7          	jalr	440(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	d9850513          	addi	a0,a0,-616 # 80008130 <digits+0xd8>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	1a8080e7          	jalr	424(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	da050513          	addi	a0,a0,-608 # 80008148 <digits+0xf0>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	198080e7          	jalr	408(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013b8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ba:	0532                	slli	a0,a0,0xc
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	6c4080e7          	jalr	1732(ra) # 80000a80 <kfree>
    *pte = 0;
    800013c4:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c8:	995a                	add	s2,s2,s6
    800013ca:	f9397ce3          	bgeu	s2,s3,80001362 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ce:	4601                	li	a2,0
    800013d0:	85ca                	mv	a1,s2
    800013d2:	8552                	mv	a0,s4
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	c80080e7          	jalr	-896(ra) # 80001054 <walk>
    800013dc:	84aa                	mv	s1,a0
    800013de:	d54d                	beqz	a0,80001388 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013e0:	6108                	ld	a0,0(a0)
    800013e2:	00157793          	andi	a5,a0,1
    800013e6:	dbcd                	beqz	a5,80001398 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013e8:	3ff57793          	andi	a5,a0,1023
    800013ec:	fb778ee3          	beq	a5,s7,800013a8 <uvmunmap+0x76>
    if(do_free){
    800013f0:	fc0a8ae3          	beqz	s5,800013c4 <uvmunmap+0x92>
    800013f4:	b7d1                	j	800013b8 <uvmunmap+0x86>

00000000800013f6 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013f6:	1101                	addi	sp,sp,-32
    800013f8:	ec06                	sd	ra,24(sp)
    800013fa:	e822                	sd	s0,16(sp)
    800013fc:	e426                	sd	s1,8(sp)
    800013fe:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001400:	fffff097          	auipc	ra,0xfffff
    80001404:	77c080e7          	jalr	1916(ra) # 80000b7c <kalloc>
    80001408:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000140a:	c519                	beqz	a0,80001418 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000140c:	6605                	lui	a2,0x1
    8000140e:	4581                	li	a1,0
    80001410:	00000097          	auipc	ra,0x0
    80001414:	958080e7          	jalr	-1704(ra) # 80000d68 <memset>
  return pagetable;
}
    80001418:	8526                	mv	a0,s1
    8000141a:	60e2                	ld	ra,24(sp)
    8000141c:	6442                	ld	s0,16(sp)
    8000141e:	64a2                	ld	s1,8(sp)
    80001420:	6105                	addi	sp,sp,32
    80001422:	8082                	ret

0000000080001424 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001424:	7179                	addi	sp,sp,-48
    80001426:	f406                	sd	ra,40(sp)
    80001428:	f022                	sd	s0,32(sp)
    8000142a:	ec26                	sd	s1,24(sp)
    8000142c:	e84a                	sd	s2,16(sp)
    8000142e:	e44e                	sd	s3,8(sp)
    80001430:	e052                	sd	s4,0(sp)
    80001432:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001434:	6785                	lui	a5,0x1
    80001436:	04f67863          	bgeu	a2,a5,80001486 <uvminit+0x62>
    8000143a:	8a2a                	mv	s4,a0
    8000143c:	89ae                	mv	s3,a1
    8000143e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001440:	fffff097          	auipc	ra,0xfffff
    80001444:	73c080e7          	jalr	1852(ra) # 80000b7c <kalloc>
    80001448:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000144a:	6605                	lui	a2,0x1
    8000144c:	4581                	li	a1,0
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	91a080e7          	jalr	-1766(ra) # 80000d68 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001456:	4779                	li	a4,30
    80001458:	86ca                	mv	a3,s2
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	8552                	mv	a0,s4
    80001460:	00000097          	auipc	ra,0x0
    80001464:	d3a080e7          	jalr	-710(ra) # 8000119a <mappages>
  memmove(mem, src, sz);
    80001468:	8626                	mv	a2,s1
    8000146a:	85ce                	mv	a1,s3
    8000146c:	854a                	mv	a0,s2
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	95a080e7          	jalr	-1702(ra) # 80000dc8 <memmove>
}
    80001476:	70a2                	ld	ra,40(sp)
    80001478:	7402                	ld	s0,32(sp)
    8000147a:	64e2                	ld	s1,24(sp)
    8000147c:	6942                	ld	s2,16(sp)
    8000147e:	69a2                	ld	s3,8(sp)
    80001480:	6a02                	ld	s4,0(sp)
    80001482:	6145                	addi	sp,sp,48
    80001484:	8082                	ret
    panic("inituvm: more than a page");
    80001486:	00007517          	auipc	a0,0x7
    8000148a:	cda50513          	addi	a0,a0,-806 # 80008160 <digits+0x108>
    8000148e:	fffff097          	auipc	ra,0xfffff
    80001492:	0ba080e7          	jalr	186(ra) # 80000548 <panic>

0000000080001496 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001496:	1101                	addi	sp,sp,-32
    80001498:	ec06                	sd	ra,24(sp)
    8000149a:	e822                	sd	s0,16(sp)
    8000149c:	e426                	sd	s1,8(sp)
    8000149e:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014a0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014a2:	00b67d63          	bgeu	a2,a1,800014bc <uvmdealloc+0x26>
    800014a6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014a8:	6785                	lui	a5,0x1
    800014aa:	17fd                	addi	a5,a5,-1
    800014ac:	00f60733          	add	a4,a2,a5
    800014b0:	767d                	lui	a2,0xfffff
    800014b2:	8f71                	and	a4,a4,a2
    800014b4:	97ae                	add	a5,a5,a1
    800014b6:	8ff1                	and	a5,a5,a2
    800014b8:	00f76863          	bltu	a4,a5,800014c8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014bc:	8526                	mv	a0,s1
    800014be:	60e2                	ld	ra,24(sp)
    800014c0:	6442                	ld	s0,16(sp)
    800014c2:	64a2                	ld	s1,8(sp)
    800014c4:	6105                	addi	sp,sp,32
    800014c6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014c8:	8f99                	sub	a5,a5,a4
    800014ca:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014cc:	4685                	li	a3,1
    800014ce:	0007861b          	sext.w	a2,a5
    800014d2:	85ba                	mv	a1,a4
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	e5e080e7          	jalr	-418(ra) # 80001332 <uvmunmap>
    800014dc:	b7c5                	j	800014bc <uvmdealloc+0x26>

00000000800014de <uvmalloc>:
  if(newsz < oldsz)
    800014de:	0ab66163          	bltu	a2,a1,80001580 <uvmalloc+0xa2>
{
    800014e2:	7139                	addi	sp,sp,-64
    800014e4:	fc06                	sd	ra,56(sp)
    800014e6:	f822                	sd	s0,48(sp)
    800014e8:	f426                	sd	s1,40(sp)
    800014ea:	f04a                	sd	s2,32(sp)
    800014ec:	ec4e                	sd	s3,24(sp)
    800014ee:	e852                	sd	s4,16(sp)
    800014f0:	e456                	sd	s5,8(sp)
    800014f2:	0080                	addi	s0,sp,64
    800014f4:	8aaa                	mv	s5,a0
    800014f6:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014f8:	6985                	lui	s3,0x1
    800014fa:	19fd                	addi	s3,s3,-1
    800014fc:	95ce                	add	a1,a1,s3
    800014fe:	79fd                	lui	s3,0xfffff
    80001500:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001504:	08c9f063          	bgeu	s3,a2,80001584 <uvmalloc+0xa6>
    80001508:	894e                	mv	s2,s3
    mem = kalloc();
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	672080e7          	jalr	1650(ra) # 80000b7c <kalloc>
    80001512:	84aa                	mv	s1,a0
    if(mem == 0){
    80001514:	c51d                	beqz	a0,80001542 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001516:	6605                	lui	a2,0x1
    80001518:	4581                	li	a1,0
    8000151a:	00000097          	auipc	ra,0x0
    8000151e:	84e080e7          	jalr	-1970(ra) # 80000d68 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001522:	4779                	li	a4,30
    80001524:	86a6                	mv	a3,s1
    80001526:	6605                	lui	a2,0x1
    80001528:	85ca                	mv	a1,s2
    8000152a:	8556                	mv	a0,s5
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	c6e080e7          	jalr	-914(ra) # 8000119a <mappages>
    80001534:	e905                	bnez	a0,80001564 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001536:	6785                	lui	a5,0x1
    80001538:	993e                	add	s2,s2,a5
    8000153a:	fd4968e3          	bltu	s2,s4,8000150a <uvmalloc+0x2c>
  return newsz;
    8000153e:	8552                	mv	a0,s4
    80001540:	a809                	j	80001552 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001542:	864e                	mv	a2,s3
    80001544:	85ca                	mv	a1,s2
    80001546:	8556                	mv	a0,s5
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	f4e080e7          	jalr	-178(ra) # 80001496 <uvmdealloc>
      return 0;
    80001550:	4501                	li	a0,0
}
    80001552:	70e2                	ld	ra,56(sp)
    80001554:	7442                	ld	s0,48(sp)
    80001556:	74a2                	ld	s1,40(sp)
    80001558:	7902                	ld	s2,32(sp)
    8000155a:	69e2                	ld	s3,24(sp)
    8000155c:	6a42                	ld	s4,16(sp)
    8000155e:	6aa2                	ld	s5,8(sp)
    80001560:	6121                	addi	sp,sp,64
    80001562:	8082                	ret
      kfree(mem);
    80001564:	8526                	mv	a0,s1
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	51a080e7          	jalr	1306(ra) # 80000a80 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000156e:	864e                	mv	a2,s3
    80001570:	85ca                	mv	a1,s2
    80001572:	8556                	mv	a0,s5
    80001574:	00000097          	auipc	ra,0x0
    80001578:	f22080e7          	jalr	-222(ra) # 80001496 <uvmdealloc>
      return 0;
    8000157c:	4501                	li	a0,0
    8000157e:	bfd1                	j	80001552 <uvmalloc+0x74>
    return oldsz;
    80001580:	852e                	mv	a0,a1
}
    80001582:	8082                	ret
  return newsz;
    80001584:	8532                	mv	a0,a2
    80001586:	b7f1                	j	80001552 <uvmalloc+0x74>

0000000080001588 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001588:	7179                	addi	sp,sp,-48
    8000158a:	f406                	sd	ra,40(sp)
    8000158c:	f022                	sd	s0,32(sp)
    8000158e:	ec26                	sd	s1,24(sp)
    80001590:	e84a                	sd	s2,16(sp)
    80001592:	e44e                	sd	s3,8(sp)
    80001594:	e052                	sd	s4,0(sp)
    80001596:	1800                	addi	s0,sp,48
    80001598:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000159a:	84aa                	mv	s1,a0
    8000159c:	6905                	lui	s2,0x1
    8000159e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015a0:	4985                	li	s3,1
    800015a2:	a821                	j	800015ba <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015a4:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015a6:	0532                	slli	a0,a0,0xc
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	fe0080e7          	jalr	-32(ra) # 80001588 <freewalk>
      pagetable[i] = 0;
    800015b0:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015b4:	04a1                	addi	s1,s1,8
    800015b6:	03248163          	beq	s1,s2,800015d8 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015ba:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015bc:	00f57793          	andi	a5,a0,15
    800015c0:	ff3782e3          	beq	a5,s3,800015a4 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015c4:	8905                	andi	a0,a0,1
    800015c6:	d57d                	beqz	a0,800015b4 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015c8:	00007517          	auipc	a0,0x7
    800015cc:	bb850513          	addi	a0,a0,-1096 # 80008180 <digits+0x128>
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	f78080e7          	jalr	-136(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015d8:	8552                	mv	a0,s4
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	4a6080e7          	jalr	1190(ra) # 80000a80 <kfree>
}
    800015e2:	70a2                	ld	ra,40(sp)
    800015e4:	7402                	ld	s0,32(sp)
    800015e6:	64e2                	ld	s1,24(sp)
    800015e8:	6942                	ld	s2,16(sp)
    800015ea:	69a2                	ld	s3,8(sp)
    800015ec:	6a02                	ld	s4,0(sp)
    800015ee:	6145                	addi	sp,sp,48
    800015f0:	8082                	ret

00000000800015f2 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015f2:	1101                	addi	sp,sp,-32
    800015f4:	ec06                	sd	ra,24(sp)
    800015f6:	e822                	sd	s0,16(sp)
    800015f8:	e426                	sd	s1,8(sp)
    800015fa:	1000                	addi	s0,sp,32
    800015fc:	84aa                	mv	s1,a0
  if(sz > 0)
    800015fe:	e999                	bnez	a1,80001614 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001600:	8526                	mv	a0,s1
    80001602:	00000097          	auipc	ra,0x0
    80001606:	f86080e7          	jalr	-122(ra) # 80001588 <freewalk>
}
    8000160a:	60e2                	ld	ra,24(sp)
    8000160c:	6442                	ld	s0,16(sp)
    8000160e:	64a2                	ld	s1,8(sp)
    80001610:	6105                	addi	sp,sp,32
    80001612:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001614:	6605                	lui	a2,0x1
    80001616:	167d                	addi	a2,a2,-1
    80001618:	962e                	add	a2,a2,a1
    8000161a:	4685                	li	a3,1
    8000161c:	8231                	srli	a2,a2,0xc
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	d12080e7          	jalr	-750(ra) # 80001332 <uvmunmap>
    80001628:	bfe1                	j	80001600 <uvmfree+0xe>

000000008000162a <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000162a:	c679                	beqz	a2,800016f8 <uvmcopy+0xce>
{
    8000162c:	715d                	addi	sp,sp,-80
    8000162e:	e486                	sd	ra,72(sp)
    80001630:	e0a2                	sd	s0,64(sp)
    80001632:	fc26                	sd	s1,56(sp)
    80001634:	f84a                	sd	s2,48(sp)
    80001636:	f44e                	sd	s3,40(sp)
    80001638:	f052                	sd	s4,32(sp)
    8000163a:	ec56                	sd	s5,24(sp)
    8000163c:	e85a                	sd	s6,16(sp)
    8000163e:	e45e                	sd	s7,8(sp)
    80001640:	0880                	addi	s0,sp,80
    80001642:	8b2a                	mv	s6,a0
    80001644:	8aae                	mv	s5,a1
    80001646:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001648:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000164a:	4601                	li	a2,0
    8000164c:	85ce                	mv	a1,s3
    8000164e:	855a                	mv	a0,s6
    80001650:	00000097          	auipc	ra,0x0
    80001654:	a04080e7          	jalr	-1532(ra) # 80001054 <walk>
    80001658:	c531                	beqz	a0,800016a4 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000165a:	6118                	ld	a4,0(a0)
    8000165c:	00177793          	andi	a5,a4,1
    80001660:	cbb1                	beqz	a5,800016b4 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001662:	00a75593          	srli	a1,a4,0xa
    80001666:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000166a:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000166e:	fffff097          	auipc	ra,0xfffff
    80001672:	50e080e7          	jalr	1294(ra) # 80000b7c <kalloc>
    80001676:	892a                	mv	s2,a0
    80001678:	c939                	beqz	a0,800016ce <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000167a:	6605                	lui	a2,0x1
    8000167c:	85de                	mv	a1,s7
    8000167e:	fffff097          	auipc	ra,0xfffff
    80001682:	74a080e7          	jalr	1866(ra) # 80000dc8 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001686:	8726                	mv	a4,s1
    80001688:	86ca                	mv	a3,s2
    8000168a:	6605                	lui	a2,0x1
    8000168c:	85ce                	mv	a1,s3
    8000168e:	8556                	mv	a0,s5
    80001690:	00000097          	auipc	ra,0x0
    80001694:	b0a080e7          	jalr	-1270(ra) # 8000119a <mappages>
    80001698:	e515                	bnez	a0,800016c4 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000169a:	6785                	lui	a5,0x1
    8000169c:	99be                	add	s3,s3,a5
    8000169e:	fb49e6e3          	bltu	s3,s4,8000164a <uvmcopy+0x20>
    800016a2:	a081                	j	800016e2 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016a4:	00007517          	auipc	a0,0x7
    800016a8:	aec50513          	addi	a0,a0,-1300 # 80008190 <digits+0x138>
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	e9c080e7          	jalr	-356(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	afc50513          	addi	a0,a0,-1284 # 800081b0 <digits+0x158>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e8c080e7          	jalr	-372(ra) # 80000548 <panic>
      kfree(mem);
    800016c4:	854a                	mv	a0,s2
    800016c6:	fffff097          	auipc	ra,0xfffff
    800016ca:	3ba080e7          	jalr	954(ra) # 80000a80 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ce:	4685                	li	a3,1
    800016d0:	00c9d613          	srli	a2,s3,0xc
    800016d4:	4581                	li	a1,0
    800016d6:	8556                	mv	a0,s5
    800016d8:	00000097          	auipc	ra,0x0
    800016dc:	c5a080e7          	jalr	-934(ra) # 80001332 <uvmunmap>
  return -1;
    800016e0:	557d                	li	a0,-1
}
    800016e2:	60a6                	ld	ra,72(sp)
    800016e4:	6406                	ld	s0,64(sp)
    800016e6:	74e2                	ld	s1,56(sp)
    800016e8:	7942                	ld	s2,48(sp)
    800016ea:	79a2                	ld	s3,40(sp)
    800016ec:	7a02                	ld	s4,32(sp)
    800016ee:	6ae2                	ld	s5,24(sp)
    800016f0:	6b42                	ld	s6,16(sp)
    800016f2:	6ba2                	ld	s7,8(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret
  return 0;
    800016f8:	4501                	li	a0,0
}
    800016fa:	8082                	ret

00000000800016fc <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016fc:	1141                	addi	sp,sp,-16
    800016fe:	e406                	sd	ra,8(sp)
    80001700:	e022                	sd	s0,0(sp)
    80001702:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001704:	4601                	li	a2,0
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	94e080e7          	jalr	-1714(ra) # 80001054 <walk>
  if(pte == 0)
    8000170e:	c901                	beqz	a0,8000171e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001710:	611c                	ld	a5,0(a0)
    80001712:	9bbd                	andi	a5,a5,-17
    80001714:	e11c                	sd	a5,0(a0)
}
    80001716:	60a2                	ld	ra,8(sp)
    80001718:	6402                	ld	s0,0(sp)
    8000171a:	0141                	addi	sp,sp,16
    8000171c:	8082                	ret
    panic("uvmclear");
    8000171e:	00007517          	auipc	a0,0x7
    80001722:	ab250513          	addi	a0,a0,-1358 # 800081d0 <digits+0x178>
    80001726:	fffff097          	auipc	ra,0xfffff
    8000172a:	e22080e7          	jalr	-478(ra) # 80000548 <panic>

000000008000172e <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000172e:	c6bd                	beqz	a3,8000179c <copyout+0x6e>
{
    80001730:	715d                	addi	sp,sp,-80
    80001732:	e486                	sd	ra,72(sp)
    80001734:	e0a2                	sd	s0,64(sp)
    80001736:	fc26                	sd	s1,56(sp)
    80001738:	f84a                	sd	s2,48(sp)
    8000173a:	f44e                	sd	s3,40(sp)
    8000173c:	f052                	sd	s4,32(sp)
    8000173e:	ec56                	sd	s5,24(sp)
    80001740:	e85a                	sd	s6,16(sp)
    80001742:	e45e                	sd	s7,8(sp)
    80001744:	e062                	sd	s8,0(sp)
    80001746:	0880                	addi	s0,sp,80
    80001748:	8b2a                	mv	s6,a0
    8000174a:	8c2e                	mv	s8,a1
    8000174c:	8a32                	mv	s4,a2
    8000174e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001750:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001752:	6a85                	lui	s5,0x1
    80001754:	a015                	j	80001778 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001756:	9562                	add	a0,a0,s8
    80001758:	0004861b          	sext.w	a2,s1
    8000175c:	85d2                	mv	a1,s4
    8000175e:	41250533          	sub	a0,a0,s2
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	666080e7          	jalr	1638(ra) # 80000dc8 <memmove>

    len -= n;
    8000176a:	409989b3          	sub	s3,s3,s1
    src += n;
    8000176e:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001770:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001774:	02098263          	beqz	s3,80001798 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001778:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000177c:	85ca                	mv	a1,s2
    8000177e:	855a                	mv	a0,s6
    80001780:	00000097          	auipc	ra,0x0
    80001784:	97a080e7          	jalr	-1670(ra) # 800010fa <walkaddr>
    if(pa0 == 0)
    80001788:	cd01                	beqz	a0,800017a0 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000178a:	418904b3          	sub	s1,s2,s8
    8000178e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001790:	fc99f3e3          	bgeu	s3,s1,80001756 <copyout+0x28>
    80001794:	84ce                	mv	s1,s3
    80001796:	b7c1                	j	80001756 <copyout+0x28>
  }
  return 0;
    80001798:	4501                	li	a0,0
    8000179a:	a021                	j	800017a2 <copyout+0x74>
    8000179c:	4501                	li	a0,0
}
    8000179e:	8082                	ret
      return -1;
    800017a0:	557d                	li	a0,-1
}
    800017a2:	60a6                	ld	ra,72(sp)
    800017a4:	6406                	ld	s0,64(sp)
    800017a6:	74e2                	ld	s1,56(sp)
    800017a8:	7942                	ld	s2,48(sp)
    800017aa:	79a2                	ld	s3,40(sp)
    800017ac:	7a02                	ld	s4,32(sp)
    800017ae:	6ae2                	ld	s5,24(sp)
    800017b0:	6b42                	ld	s6,16(sp)
    800017b2:	6ba2                	ld	s7,8(sp)
    800017b4:	6c02                	ld	s8,0(sp)
    800017b6:	6161                	addi	sp,sp,80
    800017b8:	8082                	ret

00000000800017ba <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017ba:	c6bd                	beqz	a3,80001828 <copyin+0x6e>
{
    800017bc:	715d                	addi	sp,sp,-80
    800017be:	e486                	sd	ra,72(sp)
    800017c0:	e0a2                	sd	s0,64(sp)
    800017c2:	fc26                	sd	s1,56(sp)
    800017c4:	f84a                	sd	s2,48(sp)
    800017c6:	f44e                	sd	s3,40(sp)
    800017c8:	f052                	sd	s4,32(sp)
    800017ca:	ec56                	sd	s5,24(sp)
    800017cc:	e85a                	sd	s6,16(sp)
    800017ce:	e45e                	sd	s7,8(sp)
    800017d0:	e062                	sd	s8,0(sp)
    800017d2:	0880                	addi	s0,sp,80
    800017d4:	8b2a                	mv	s6,a0
    800017d6:	8a2e                	mv	s4,a1
    800017d8:	8c32                	mv	s8,a2
    800017da:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017dc:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017de:	6a85                	lui	s5,0x1
    800017e0:	a015                	j	80001804 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017e2:	9562                	add	a0,a0,s8
    800017e4:	0004861b          	sext.w	a2,s1
    800017e8:	412505b3          	sub	a1,a0,s2
    800017ec:	8552                	mv	a0,s4
    800017ee:	fffff097          	auipc	ra,0xfffff
    800017f2:	5da080e7          	jalr	1498(ra) # 80000dc8 <memmove>

    len -= n;
    800017f6:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017fa:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017fc:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001800:	02098263          	beqz	s3,80001824 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001804:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001808:	85ca                	mv	a1,s2
    8000180a:	855a                	mv	a0,s6
    8000180c:	00000097          	auipc	ra,0x0
    80001810:	8ee080e7          	jalr	-1810(ra) # 800010fa <walkaddr>
    if(pa0 == 0)
    80001814:	cd01                	beqz	a0,8000182c <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001816:	418904b3          	sub	s1,s2,s8
    8000181a:	94d6                	add	s1,s1,s5
    if(n > len)
    8000181c:	fc99f3e3          	bgeu	s3,s1,800017e2 <copyin+0x28>
    80001820:	84ce                	mv	s1,s3
    80001822:	b7c1                	j	800017e2 <copyin+0x28>
  }
  return 0;
    80001824:	4501                	li	a0,0
    80001826:	a021                	j	8000182e <copyin+0x74>
    80001828:	4501                	li	a0,0
}
    8000182a:	8082                	ret
      return -1;
    8000182c:	557d                	li	a0,-1
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6c02                	ld	s8,0(sp)
    80001842:	6161                	addi	sp,sp,80
    80001844:	8082                	ret

0000000080001846 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001846:	c6c5                	beqz	a3,800018ee <copyinstr+0xa8>
{
    80001848:	715d                	addi	sp,sp,-80
    8000184a:	e486                	sd	ra,72(sp)
    8000184c:	e0a2                	sd	s0,64(sp)
    8000184e:	fc26                	sd	s1,56(sp)
    80001850:	f84a                	sd	s2,48(sp)
    80001852:	f44e                	sd	s3,40(sp)
    80001854:	f052                	sd	s4,32(sp)
    80001856:	ec56                	sd	s5,24(sp)
    80001858:	e85a                	sd	s6,16(sp)
    8000185a:	e45e                	sd	s7,8(sp)
    8000185c:	0880                	addi	s0,sp,80
    8000185e:	8a2a                	mv	s4,a0
    80001860:	8b2e                	mv	s6,a1
    80001862:	8bb2                	mv	s7,a2
    80001864:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001866:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001868:	6985                	lui	s3,0x1
    8000186a:	a035                	j	80001896 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000186c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001870:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001872:	0017b793          	seqz	a5,a5
    80001876:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000187a:	60a6                	ld	ra,72(sp)
    8000187c:	6406                	ld	s0,64(sp)
    8000187e:	74e2                	ld	s1,56(sp)
    80001880:	7942                	ld	s2,48(sp)
    80001882:	79a2                	ld	s3,40(sp)
    80001884:	7a02                	ld	s4,32(sp)
    80001886:	6ae2                	ld	s5,24(sp)
    80001888:	6b42                	ld	s6,16(sp)
    8000188a:	6ba2                	ld	s7,8(sp)
    8000188c:	6161                	addi	sp,sp,80
    8000188e:	8082                	ret
    srcva = va0 + PGSIZE;
    80001890:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001894:	c8a9                	beqz	s1,800018e6 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001896:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000189a:	85ca                	mv	a1,s2
    8000189c:	8552                	mv	a0,s4
    8000189e:	00000097          	auipc	ra,0x0
    800018a2:	85c080e7          	jalr	-1956(ra) # 800010fa <walkaddr>
    if(pa0 == 0)
    800018a6:	c131                	beqz	a0,800018ea <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018a8:	41790833          	sub	a6,s2,s7
    800018ac:	984e                	add	a6,a6,s3
    if(n > max)
    800018ae:	0104f363          	bgeu	s1,a6,800018b4 <copyinstr+0x6e>
    800018b2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018b4:	955e                	add	a0,a0,s7
    800018b6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018ba:	fc080be3          	beqz	a6,80001890 <copyinstr+0x4a>
    800018be:	985a                	add	a6,a6,s6
    800018c0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018c2:	41650633          	sub	a2,a0,s6
    800018c6:	14fd                	addi	s1,s1,-1
    800018c8:	9b26                	add	s6,s6,s1
    800018ca:	00f60733          	add	a4,a2,a5
    800018ce:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    800018d2:	df49                	beqz	a4,8000186c <copyinstr+0x26>
        *dst = *p;
    800018d4:	00e78023          	sb	a4,0(a5)
      --max;
    800018d8:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018dc:	0785                	addi	a5,a5,1
    while(n > 0){
    800018de:	ff0796e3          	bne	a5,a6,800018ca <copyinstr+0x84>
      dst++;
    800018e2:	8b42                	mv	s6,a6
    800018e4:	b775                	j	80001890 <copyinstr+0x4a>
    800018e6:	4781                	li	a5,0
    800018e8:	b769                	j	80001872 <copyinstr+0x2c>
      return -1;
    800018ea:	557d                	li	a0,-1
    800018ec:	b779                	j	8000187a <copyinstr+0x34>
  int got_null = 0;
    800018ee:	4781                	li	a5,0
  if(got_null){
    800018f0:	0017b793          	seqz	a5,a5
    800018f4:	40f00533          	neg	a0,a5
}
    800018f8:	8082                	ret

00000000800018fa <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018fa:	1101                	addi	sp,sp,-32
    800018fc:	ec06                	sd	ra,24(sp)
    800018fe:	e822                	sd	s0,16(sp)
    80001900:	e426                	sd	s1,8(sp)
    80001902:	1000                	addi	s0,sp,32
    80001904:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001906:	fffff097          	auipc	ra,0xfffff
    8000190a:	2ec080e7          	jalr	748(ra) # 80000bf2 <holding>
    8000190e:	c909                	beqz	a0,80001920 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001910:	749c                	ld	a5,40(s1)
    80001912:	00978f63          	beq	a5,s1,80001930 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001916:	60e2                	ld	ra,24(sp)
    80001918:	6442                	ld	s0,16(sp)
    8000191a:	64a2                	ld	s1,8(sp)
    8000191c:	6105                	addi	sp,sp,32
    8000191e:	8082                	ret
    panic("wakeup1");
    80001920:	00007517          	auipc	a0,0x7
    80001924:	8c050513          	addi	a0,a0,-1856 # 800081e0 <digits+0x188>
    80001928:	fffff097          	auipc	ra,0xfffff
    8000192c:	c20080e7          	jalr	-992(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001930:	4c98                	lw	a4,24(s1)
    80001932:	4785                	li	a5,1
    80001934:	fef711e3          	bne	a4,a5,80001916 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001938:	4789                	li	a5,2
    8000193a:	cc9c                	sw	a5,24(s1)
}
    8000193c:	bfe9                	j	80001916 <wakeup1+0x1c>

000000008000193e <procinit>:
{
    8000193e:	715d                	addi	sp,sp,-80
    80001940:	e486                	sd	ra,72(sp)
    80001942:	e0a2                	sd	s0,64(sp)
    80001944:	fc26                	sd	s1,56(sp)
    80001946:	f84a                	sd	s2,48(sp)
    80001948:	f44e                	sd	s3,40(sp)
    8000194a:	f052                	sd	s4,32(sp)
    8000194c:	ec56                	sd	s5,24(sp)
    8000194e:	e85a                	sd	s6,16(sp)
    80001950:	e45e                	sd	s7,8(sp)
    80001952:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001954:	00007597          	auipc	a1,0x7
    80001958:	89458593          	addi	a1,a1,-1900 # 800081e8 <digits+0x190>
    8000195c:	00010517          	auipc	a0,0x10
    80001960:	ff450513          	addi	a0,a0,-12 # 80011950 <pid_lock>
    80001964:	fffff097          	auipc	ra,0xfffff
    80001968:	278080e7          	jalr	632(ra) # 80000bdc <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000196c:	00010917          	auipc	s2,0x10
    80001970:	3fc90913          	addi	s2,s2,1020 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001974:	00007b97          	auipc	s7,0x7
    80001978:	87cb8b93          	addi	s7,s7,-1924 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    8000197c:	8b4a                	mv	s6,s2
    8000197e:	00006a97          	auipc	s5,0x6
    80001982:	682a8a93          	addi	s5,s5,1666 # 80008000 <etext>
    80001986:	040009b7          	lui	s3,0x4000
    8000198a:	19fd                	addi	s3,s3,-1
    8000198c:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198e:	00016a17          	auipc	s4,0x16
    80001992:	3daa0a13          	addi	s4,s4,986 # 80017d68 <tickslock>
      initlock(&p->lock, "proc");
    80001996:	85de                	mv	a1,s7
    80001998:	854a                	mv	a0,s2
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	242080e7          	jalr	578(ra) # 80000bdc <initlock>
      char *pa = kalloc();
    800019a2:	fffff097          	auipc	ra,0xfffff
    800019a6:	1da080e7          	jalr	474(ra) # 80000b7c <kalloc>
    800019aa:	85aa                	mv	a1,a0
      if(pa == 0)
    800019ac:	c929                	beqz	a0,800019fe <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019ae:	416904b3          	sub	s1,s2,s6
    800019b2:	849d                	srai	s1,s1,0x7
    800019b4:	000ab783          	ld	a5,0(s5)
    800019b8:	02f484b3          	mul	s1,s1,a5
    800019bc:	2485                	addiw	s1,s1,1
    800019be:	00d4949b          	slliw	s1,s1,0xd
    800019c2:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019c6:	4699                	li	a3,6
    800019c8:	6605                	lui	a2,0x1
    800019ca:	8526                	mv	a0,s1
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	85c080e7          	jalr	-1956(ra) # 80001228 <kvmmap>
      p->kstack = va;
    800019d4:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019d8:	18090913          	addi	s2,s2,384
    800019dc:	fb491de3          	bne	s2,s4,80001996 <procinit+0x58>
  kvminithart();
    800019e0:	fffff097          	auipc	ra,0xfffff
    800019e4:	650080e7          	jalr	1616(ra) # 80001030 <kvminithart>
}
    800019e8:	60a6                	ld	ra,72(sp)
    800019ea:	6406                	ld	s0,64(sp)
    800019ec:	74e2                	ld	s1,56(sp)
    800019ee:	7942                	ld	s2,48(sp)
    800019f0:	79a2                	ld	s3,40(sp)
    800019f2:	7a02                	ld	s4,32(sp)
    800019f4:	6ae2                	ld	s5,24(sp)
    800019f6:	6b42                	ld	s6,16(sp)
    800019f8:	6ba2                	ld	s7,8(sp)
    800019fa:	6161                	addi	sp,sp,80
    800019fc:	8082                	ret
        panic("kalloc");
    800019fe:	00006517          	auipc	a0,0x6
    80001a02:	7fa50513          	addi	a0,a0,2042 # 800081f8 <digits+0x1a0>
    80001a06:	fffff097          	auipc	ra,0xfffff
    80001a0a:	b42080e7          	jalr	-1214(ra) # 80000548 <panic>

0000000080001a0e <cpuid>:
{
    80001a0e:	1141                	addi	sp,sp,-16
    80001a10:	e422                	sd	s0,8(sp)
    80001a12:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a14:	8512                	mv	a0,tp
}
    80001a16:	2501                	sext.w	a0,a0
    80001a18:	6422                	ld	s0,8(sp)
    80001a1a:	0141                	addi	sp,sp,16
    80001a1c:	8082                	ret

0000000080001a1e <mycpu>:
mycpu(void) {
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e422                	sd	s0,8(sp)
    80001a22:	0800                	addi	s0,sp,16
    80001a24:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a26:	2781                	sext.w	a5,a5
    80001a28:	079e                	slli	a5,a5,0x7
}
    80001a2a:	00010517          	auipc	a0,0x10
    80001a2e:	f3e50513          	addi	a0,a0,-194 # 80011968 <cpus>
    80001a32:	953e                	add	a0,a0,a5
    80001a34:	6422                	ld	s0,8(sp)
    80001a36:	0141                	addi	sp,sp,16
    80001a38:	8082                	ret

0000000080001a3a <myproc>:
myproc(void) {
    80001a3a:	1101                	addi	sp,sp,-32
    80001a3c:	ec06                	sd	ra,24(sp)
    80001a3e:	e822                	sd	s0,16(sp)
    80001a40:	e426                	sd	s1,8(sp)
    80001a42:	1000                	addi	s0,sp,32
  push_off();
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	1dc080e7          	jalr	476(ra) # 80000c20 <push_off>
    80001a4c:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a4e:	2781                	sext.w	a5,a5
    80001a50:	079e                	slli	a5,a5,0x7
    80001a52:	00010717          	auipc	a4,0x10
    80001a56:	efe70713          	addi	a4,a4,-258 # 80011950 <pid_lock>
    80001a5a:	97ba                	add	a5,a5,a4
    80001a5c:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a5e:	fffff097          	auipc	ra,0xfffff
    80001a62:	262080e7          	jalr	610(ra) # 80000cc0 <pop_off>
}
    80001a66:	8526                	mv	a0,s1
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6105                	addi	sp,sp,32
    80001a70:	8082                	ret

0000000080001a72 <forkret>:
{
    80001a72:	1141                	addi	sp,sp,-16
    80001a74:	e406                	sd	ra,8(sp)
    80001a76:	e022                	sd	s0,0(sp)
    80001a78:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a7a:	00000097          	auipc	ra,0x0
    80001a7e:	fc0080e7          	jalr	-64(ra) # 80001a3a <myproc>
    80001a82:	fffff097          	auipc	ra,0xfffff
    80001a86:	29e080e7          	jalr	670(ra) # 80000d20 <release>
  if (first) {
    80001a8a:	00007797          	auipc	a5,0x7
    80001a8e:	db67a783          	lw	a5,-586(a5) # 80008840 <first.1670>
    80001a92:	eb89                	bnez	a5,80001aa4 <forkret+0x32>
  usertrapret();
    80001a94:	00001097          	auipc	ra,0x1
    80001a98:	c18080e7          	jalr	-1000(ra) # 800026ac <usertrapret>
}
    80001a9c:	60a2                	ld	ra,8(sp)
    80001a9e:	6402                	ld	s0,0(sp)
    80001aa0:	0141                	addi	sp,sp,16
    80001aa2:	8082                	ret
    first = 0;
    80001aa4:	00007797          	auipc	a5,0x7
    80001aa8:	d807ae23          	sw	zero,-612(a5) # 80008840 <first.1670>
    fsinit(ROOTDEV);
    80001aac:	4505                	li	a0,1
    80001aae:	00002097          	auipc	ra,0x2
    80001ab2:	a42080e7          	jalr	-1470(ra) # 800034f0 <fsinit>
    80001ab6:	bff9                	j	80001a94 <forkret+0x22>

0000000080001ab8 <allocpid>:
allocpid() {
    80001ab8:	1101                	addi	sp,sp,-32
    80001aba:	ec06                	sd	ra,24(sp)
    80001abc:	e822                	sd	s0,16(sp)
    80001abe:	e426                	sd	s1,8(sp)
    80001ac0:	e04a                	sd	s2,0(sp)
    80001ac2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ac4:	00010917          	auipc	s2,0x10
    80001ac8:	e8c90913          	addi	s2,s2,-372 # 80011950 <pid_lock>
    80001acc:	854a                	mv	a0,s2
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	19e080e7          	jalr	414(ra) # 80000c6c <acquire>
  pid = nextpid;
    80001ad6:	00007797          	auipc	a5,0x7
    80001ada:	d6e78793          	addi	a5,a5,-658 # 80008844 <nextpid>
    80001ade:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae0:	0014871b          	addiw	a4,s1,1
    80001ae4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001ae6:	854a                	mv	a0,s2
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	238080e7          	jalr	568(ra) # 80000d20 <release>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6902                	ld	s2,0(sp)
    80001afa:	6105                	addi	sp,sp,32
    80001afc:	8082                	ret

0000000080001afe <proc_pagetable>:
{
    80001afe:	1101                	addi	sp,sp,-32
    80001b00:	ec06                	sd	ra,24(sp)
    80001b02:	e822                	sd	s0,16(sp)
    80001b04:	e426                	sd	s1,8(sp)
    80001b06:	e04a                	sd	s2,0(sp)
    80001b08:	1000                	addi	s0,sp,32
    80001b0a:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b0c:	00000097          	auipc	ra,0x0
    80001b10:	8ea080e7          	jalr	-1814(ra) # 800013f6 <uvmcreate>
    80001b14:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b16:	c121                	beqz	a0,80001b56 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b18:	4729                	li	a4,10
    80001b1a:	00005697          	auipc	a3,0x5
    80001b1e:	4e668693          	addi	a3,a3,1254 # 80007000 <_trampoline>
    80001b22:	6605                	lui	a2,0x1
    80001b24:	040005b7          	lui	a1,0x4000
    80001b28:	15fd                	addi	a1,a1,-1
    80001b2a:	05b2                	slli	a1,a1,0xc
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	66e080e7          	jalr	1646(ra) # 8000119a <mappages>
    80001b34:	02054863          	bltz	a0,80001b64 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b38:	4719                	li	a4,6
    80001b3a:	05893683          	ld	a3,88(s2)
    80001b3e:	6605                	lui	a2,0x1
    80001b40:	020005b7          	lui	a1,0x2000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b6                	slli	a1,a1,0xd
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	650080e7          	jalr	1616(ra) # 8000119a <mappages>
    80001b52:	02054163          	bltz	a0,80001b74 <proc_pagetable+0x76>
}
    80001b56:	8526                	mv	a0,s1
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret
    uvmfree(pagetable, 0);
    80001b64:	4581                	li	a1,0
    80001b66:	8526                	mv	a0,s1
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	a8a080e7          	jalr	-1398(ra) # 800015f2 <uvmfree>
    return 0;
    80001b70:	4481                	li	s1,0
    80001b72:	b7d5                	j	80001b56 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b74:	4681                	li	a3,0
    80001b76:	4605                	li	a2,1
    80001b78:	040005b7          	lui	a1,0x4000
    80001b7c:	15fd                	addi	a1,a1,-1
    80001b7e:	05b2                	slli	a1,a1,0xc
    80001b80:	8526                	mv	a0,s1
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	7b0080e7          	jalr	1968(ra) # 80001332 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b8a:	4581                	li	a1,0
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	00000097          	auipc	ra,0x0
    80001b92:	a64080e7          	jalr	-1436(ra) # 800015f2 <uvmfree>
    return 0;
    80001b96:	4481                	li	s1,0
    80001b98:	bf7d                	j	80001b56 <proc_pagetable+0x58>

0000000080001b9a <proc_freepagetable>:
{
    80001b9a:	1101                	addi	sp,sp,-32
    80001b9c:	ec06                	sd	ra,24(sp)
    80001b9e:	e822                	sd	s0,16(sp)
    80001ba0:	e426                	sd	s1,8(sp)
    80001ba2:	e04a                	sd	s2,0(sp)
    80001ba4:	1000                	addi	s0,sp,32
    80001ba6:	84aa                	mv	s1,a0
    80001ba8:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001baa:	4681                	li	a3,0
    80001bac:	4605                	li	a2,1
    80001bae:	040005b7          	lui	a1,0x4000
    80001bb2:	15fd                	addi	a1,a1,-1
    80001bb4:	05b2                	slli	a1,a1,0xc
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	77c080e7          	jalr	1916(ra) # 80001332 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bbe:	4681                	li	a3,0
    80001bc0:	4605                	li	a2,1
    80001bc2:	020005b7          	lui	a1,0x2000
    80001bc6:	15fd                	addi	a1,a1,-1
    80001bc8:	05b6                	slli	a1,a1,0xd
    80001bca:	8526                	mv	a0,s1
    80001bcc:	fffff097          	auipc	ra,0xfffff
    80001bd0:	766080e7          	jalr	1894(ra) # 80001332 <uvmunmap>
  uvmfree(pagetable, sz);
    80001bd4:	85ca                	mv	a1,s2
    80001bd6:	8526                	mv	a0,s1
    80001bd8:	00000097          	auipc	ra,0x0
    80001bdc:	a1a080e7          	jalr	-1510(ra) # 800015f2 <uvmfree>
}
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6902                	ld	s2,0(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <freeproc>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	1000                	addi	s0,sp,32
    80001bf6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bf8:	6d28                	ld	a0,88(a0)
    80001bfa:	c509                	beqz	a0,80001c04 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	e84080e7          	jalr	-380(ra) # 80000a80 <kfree>
  p->trapframe = 0;
    80001c04:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c08:	68a8                	ld	a0,80(s1)
    80001c0a:	c511                	beqz	a0,80001c16 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c0c:	64ac                	ld	a1,72(s1)
    80001c0e:	00000097          	auipc	ra,0x0
    80001c12:	f8c080e7          	jalr	-116(ra) # 80001b9a <proc_freepagetable>
  p->pagetable = 0;
    80001c16:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c1a:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c1e:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c22:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c26:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c2a:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c2e:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c32:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c36:	0004ac23          	sw	zero,24(s1)
}
    80001c3a:	60e2                	ld	ra,24(sp)
    80001c3c:	6442                	ld	s0,16(sp)
    80001c3e:	64a2                	ld	s1,8(sp)
    80001c40:	6105                	addi	sp,sp,32
    80001c42:	8082                	ret

0000000080001c44 <allocproc>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	e04a                	sd	s2,0(sp)
    80001c4e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c50:	00010497          	auipc	s1,0x10
    80001c54:	11848493          	addi	s1,s1,280 # 80011d68 <proc>
    80001c58:	00016917          	auipc	s2,0x16
    80001c5c:	11090913          	addi	s2,s2,272 # 80017d68 <tickslock>
    acquire(&p->lock);
    80001c60:	8526                	mv	a0,s1
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	00a080e7          	jalr	10(ra) # 80000c6c <acquire>
    if(p->state == UNUSED) {
    80001c6a:	4c9c                	lw	a5,24(s1)
    80001c6c:	cf81                	beqz	a5,80001c84 <allocproc+0x40>
      release(&p->lock);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	0b0080e7          	jalr	176(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c78:	18048493          	addi	s1,s1,384
    80001c7c:	ff2492e3          	bne	s1,s2,80001c60 <allocproc+0x1c>
  return 0;
    80001c80:	4481                	li	s1,0
    80001c82:	a0b9                	j	80001cd0 <allocproc+0x8c>
  p->pid = allocpid();
    80001c84:	00000097          	auipc	ra,0x0
    80001c88:	e34080e7          	jalr	-460(ra) # 80001ab8 <allocpid>
    80001c8c:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	eee080e7          	jalr	-274(ra) # 80000b7c <kalloc>
    80001c96:	892a                	mv	s2,a0
    80001c98:	eca8                	sd	a0,88(s1)
    80001c9a:	c131                	beqz	a0,80001cde <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	00000097          	auipc	ra,0x0
    80001ca2:	e60080e7          	jalr	-416(ra) # 80001afe <proc_pagetable>
    80001ca6:	892a                	mv	s2,a0
    80001ca8:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001caa:	c129                	beqz	a0,80001cec <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001cac:	07000613          	li	a2,112
    80001cb0:	4581                	li	a1,0
    80001cb2:	06048513          	addi	a0,s1,96
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	0b2080e7          	jalr	178(ra) # 80000d68 <memset>
  p->context.ra = (uint64)forkret;
    80001cbe:	00000797          	auipc	a5,0x0
    80001cc2:	db478793          	addi	a5,a5,-588 # 80001a72 <forkret>
    80001cc6:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cc8:	60bc                	ld	a5,64(s1)
    80001cca:	6705                	lui	a4,0x1
    80001ccc:	97ba                	add	a5,a5,a4
    80001cce:	f4bc                	sd	a5,104(s1)
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret
    release(&p->lock);
    80001cde:	8526                	mv	a0,s1
    80001ce0:	fffff097          	auipc	ra,0xfffff
    80001ce4:	040080e7          	jalr	64(ra) # 80000d20 <release>
    return 0;
    80001ce8:	84ca                	mv	s1,s2
    80001cea:	b7dd                	j	80001cd0 <allocproc+0x8c>
    freeproc(p);
    80001cec:	8526                	mv	a0,s1
    80001cee:	00000097          	auipc	ra,0x0
    80001cf2:	efe080e7          	jalr	-258(ra) # 80001bec <freeproc>
    release(&p->lock);
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	fffff097          	auipc	ra,0xfffff
    80001cfc:	028080e7          	jalr	40(ra) # 80000d20 <release>
    return 0;
    80001d00:	84ca                	mv	s1,s2
    80001d02:	b7f9                	j	80001cd0 <allocproc+0x8c>

0000000080001d04 <userinit>:
{
    80001d04:	1101                	addi	sp,sp,-32
    80001d06:	ec06                	sd	ra,24(sp)
    80001d08:	e822                	sd	s0,16(sp)
    80001d0a:	e426                	sd	s1,8(sp)
    80001d0c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d0e:	00000097          	auipc	ra,0x0
    80001d12:	f36080e7          	jalr	-202(ra) # 80001c44 <allocproc>
    80001d16:	84aa                	mv	s1,a0
  initproc = p;
    80001d18:	00007797          	auipc	a5,0x7
    80001d1c:	30a7b023          	sd	a0,768(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d20:	03400613          	li	a2,52
    80001d24:	00007597          	auipc	a1,0x7
    80001d28:	b2c58593          	addi	a1,a1,-1236 # 80008850 <initcode>
    80001d2c:	6928                	ld	a0,80(a0)
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	6f6080e7          	jalr	1782(ra) # 80001424 <uvminit>
  p->sz = PGSIZE;
    80001d36:	6785                	lui	a5,0x1
    80001d38:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d3a:	6cb8                	ld	a4,88(s1)
    80001d3c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d40:	6cb8                	ld	a4,88(s1)
    80001d42:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d44:	4641                	li	a2,16
    80001d46:	00006597          	auipc	a1,0x6
    80001d4a:	4ba58593          	addi	a1,a1,1210 # 80008200 <digits+0x1a8>
    80001d4e:	15848513          	addi	a0,s1,344
    80001d52:	fffff097          	auipc	ra,0xfffff
    80001d56:	16c080e7          	jalr	364(ra) # 80000ebe <safestrcpy>
  p->cwd = namei("/");
    80001d5a:	00006517          	auipc	a0,0x6
    80001d5e:	4b650513          	addi	a0,a0,1206 # 80008210 <digits+0x1b8>
    80001d62:	00002097          	auipc	ra,0x2
    80001d66:	1b6080e7          	jalr	438(ra) # 80003f18 <namei>
    80001d6a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d6e:	4789                	li	a5,2
    80001d70:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d72:	8526                	mv	a0,s1
    80001d74:	fffff097          	auipc	ra,0xfffff
    80001d78:	fac080e7          	jalr	-84(ra) # 80000d20 <release>
}
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret

0000000080001d86 <growproc>:
{
    80001d86:	1101                	addi	sp,sp,-32
    80001d88:	ec06                	sd	ra,24(sp)
    80001d8a:	e822                	sd	s0,16(sp)
    80001d8c:	e426                	sd	s1,8(sp)
    80001d8e:	e04a                	sd	s2,0(sp)
    80001d90:	1000                	addi	s0,sp,32
    80001d92:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d94:	00000097          	auipc	ra,0x0
    80001d98:	ca6080e7          	jalr	-858(ra) # 80001a3a <myproc>
    80001d9c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d9e:	652c                	ld	a1,72(a0)
    80001da0:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001da4:	00904f63          	bgtz	s1,80001dc2 <growproc+0x3c>
  } else if(n < 0){
    80001da8:	0204cc63          	bltz	s1,80001de0 <growproc+0x5a>
  p->sz = sz;
    80001dac:	1602                	slli	a2,a2,0x20
    80001dae:	9201                	srli	a2,a2,0x20
    80001db0:	04c93423          	sd	a2,72(s2)
  return 0;
    80001db4:	4501                	li	a0,0
}
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc2:	9e25                	addw	a2,a2,s1
    80001dc4:	1602                	slli	a2,a2,0x20
    80001dc6:	9201                	srli	a2,a2,0x20
    80001dc8:	1582                	slli	a1,a1,0x20
    80001dca:	9181                	srli	a1,a1,0x20
    80001dcc:	6928                	ld	a0,80(a0)
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	710080e7          	jalr	1808(ra) # 800014de <uvmalloc>
    80001dd6:	0005061b          	sext.w	a2,a0
    80001dda:	fa69                	bnez	a2,80001dac <growproc+0x26>
      return -1;
    80001ddc:	557d                	li	a0,-1
    80001dde:	bfe1                	j	80001db6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de0:	9e25                	addw	a2,a2,s1
    80001de2:	1602                	slli	a2,a2,0x20
    80001de4:	9201                	srli	a2,a2,0x20
    80001de6:	1582                	slli	a1,a1,0x20
    80001de8:	9181                	srli	a1,a1,0x20
    80001dea:	6928                	ld	a0,80(a0)
    80001dec:	fffff097          	auipc	ra,0xfffff
    80001df0:	6aa080e7          	jalr	1706(ra) # 80001496 <uvmdealloc>
    80001df4:	0005061b          	sext.w	a2,a0
    80001df8:	bf55                	j	80001dac <growproc+0x26>

0000000080001dfa <fork>:
{
    80001dfa:	7179                	addi	sp,sp,-48
    80001dfc:	f406                	sd	ra,40(sp)
    80001dfe:	f022                	sd	s0,32(sp)
    80001e00:	ec26                	sd	s1,24(sp)
    80001e02:	e84a                	sd	s2,16(sp)
    80001e04:	e44e                	sd	s3,8(sp)
    80001e06:	e052                	sd	s4,0(sp)
    80001e08:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e0a:	00000097          	auipc	ra,0x0
    80001e0e:	c30080e7          	jalr	-976(ra) # 80001a3a <myproc>
    80001e12:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e14:	00000097          	auipc	ra,0x0
    80001e18:	e30080e7          	jalr	-464(ra) # 80001c44 <allocproc>
    80001e1c:	c175                	beqz	a0,80001f00 <fork+0x106>
    80001e1e:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e20:	04893603          	ld	a2,72(s2)
    80001e24:	692c                	ld	a1,80(a0)
    80001e26:	05093503          	ld	a0,80(s2)
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	800080e7          	jalr	-2048(ra) # 8000162a <uvmcopy>
    80001e32:	04054863          	bltz	a0,80001e82 <fork+0x88>
  np->sz = p->sz;
    80001e36:	04893783          	ld	a5,72(s2)
    80001e3a:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e3e:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e42:	05893683          	ld	a3,88(s2)
    80001e46:	87b6                	mv	a5,a3
    80001e48:	0589b703          	ld	a4,88(s3)
    80001e4c:	12068693          	addi	a3,a3,288
    80001e50:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e54:	6788                	ld	a0,8(a5)
    80001e56:	6b8c                	ld	a1,16(a5)
    80001e58:	6f90                	ld	a2,24(a5)
    80001e5a:	01073023          	sd	a6,0(a4)
    80001e5e:	e708                	sd	a0,8(a4)
    80001e60:	eb0c                	sd	a1,16(a4)
    80001e62:	ef10                	sd	a2,24(a4)
    80001e64:	02078793          	addi	a5,a5,32
    80001e68:	02070713          	addi	a4,a4,32
    80001e6c:	fed792e3          	bne	a5,a3,80001e50 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e70:	0589b783          	ld	a5,88(s3)
    80001e74:	0607b823          	sd	zero,112(a5)
    80001e78:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e7c:	15000a13          	li	s4,336
    80001e80:	a03d                	j	80001eae <fork+0xb4>
    freeproc(np);
    80001e82:	854e                	mv	a0,s3
    80001e84:	00000097          	auipc	ra,0x0
    80001e88:	d68080e7          	jalr	-664(ra) # 80001bec <freeproc>
    release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	e92080e7          	jalr	-366(ra) # 80000d20 <release>
    return -1;
    80001e96:	54fd                	li	s1,-1
    80001e98:	a899                	j	80001eee <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e9a:	00002097          	auipc	ra,0x2
    80001e9e:	70a080e7          	jalr	1802(ra) # 800045a4 <filedup>
    80001ea2:	009987b3          	add	a5,s3,s1
    80001ea6:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ea8:	04a1                	addi	s1,s1,8
    80001eaa:	01448763          	beq	s1,s4,80001eb8 <fork+0xbe>
    if(p->ofile[i])
    80001eae:	009907b3          	add	a5,s2,s1
    80001eb2:	6388                	ld	a0,0(a5)
    80001eb4:	f17d                	bnez	a0,80001e9a <fork+0xa0>
    80001eb6:	bfcd                	j	80001ea8 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001eb8:	15093503          	ld	a0,336(s2)
    80001ebc:	00002097          	auipc	ra,0x2
    80001ec0:	86e080e7          	jalr	-1938(ra) # 8000372a <idup>
    80001ec4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ec8:	4641                	li	a2,16
    80001eca:	15890593          	addi	a1,s2,344
    80001ece:	15898513          	addi	a0,s3,344
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	fec080e7          	jalr	-20(ra) # 80000ebe <safestrcpy>
  pid = np->pid;
    80001eda:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ede:	4789                	li	a5,2
    80001ee0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ee4:	854e                	mv	a0,s3
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	e3a080e7          	jalr	-454(ra) # 80000d20 <release>
}
    80001eee:	8526                	mv	a0,s1
    80001ef0:	70a2                	ld	ra,40(sp)
    80001ef2:	7402                	ld	s0,32(sp)
    80001ef4:	64e2                	ld	s1,24(sp)
    80001ef6:	6942                	ld	s2,16(sp)
    80001ef8:	69a2                	ld	s3,8(sp)
    80001efa:	6a02                	ld	s4,0(sp)
    80001efc:	6145                	addi	sp,sp,48
    80001efe:	8082                	ret
    return -1;
    80001f00:	54fd                	li	s1,-1
    80001f02:	b7f5                	j	80001eee <fork+0xf4>

0000000080001f04 <reparent>:
{
    80001f04:	7179                	addi	sp,sp,-48
    80001f06:	f406                	sd	ra,40(sp)
    80001f08:	f022                	sd	s0,32(sp)
    80001f0a:	ec26                	sd	s1,24(sp)
    80001f0c:	e84a                	sd	s2,16(sp)
    80001f0e:	e44e                	sd	s3,8(sp)
    80001f10:	e052                	sd	s4,0(sp)
    80001f12:	1800                	addi	s0,sp,48
    80001f14:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f16:	00010497          	auipc	s1,0x10
    80001f1a:	e5248493          	addi	s1,s1,-430 # 80011d68 <proc>
      pp->parent = initproc;
    80001f1e:	00007a17          	auipc	s4,0x7
    80001f22:	0faa0a13          	addi	s4,s4,250 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f26:	00016997          	auipc	s3,0x16
    80001f2a:	e4298993          	addi	s3,s3,-446 # 80017d68 <tickslock>
    80001f2e:	a029                	j	80001f38 <reparent+0x34>
    80001f30:	18048493          	addi	s1,s1,384
    80001f34:	03348363          	beq	s1,s3,80001f5a <reparent+0x56>
    if(pp->parent == p){
    80001f38:	709c                	ld	a5,32(s1)
    80001f3a:	ff279be3          	bne	a5,s2,80001f30 <reparent+0x2c>
      acquire(&pp->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	d2c080e7          	jalr	-724(ra) # 80000c6c <acquire>
      pp->parent = initproc;
    80001f48:	000a3783          	ld	a5,0(s4)
    80001f4c:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	dd0080e7          	jalr	-560(ra) # 80000d20 <release>
    80001f58:	bfe1                	j	80001f30 <reparent+0x2c>
}
    80001f5a:	70a2                	ld	ra,40(sp)
    80001f5c:	7402                	ld	s0,32(sp)
    80001f5e:	64e2                	ld	s1,24(sp)
    80001f60:	6942                	ld	s2,16(sp)
    80001f62:	69a2                	ld	s3,8(sp)
    80001f64:	6a02                	ld	s4,0(sp)
    80001f66:	6145                	addi	sp,sp,48
    80001f68:	8082                	ret

0000000080001f6a <scheduler>:
{
    80001f6a:	715d                	addi	sp,sp,-80
    80001f6c:	e486                	sd	ra,72(sp)
    80001f6e:	e0a2                	sd	s0,64(sp)
    80001f70:	fc26                	sd	s1,56(sp)
    80001f72:	f84a                	sd	s2,48(sp)
    80001f74:	f44e                	sd	s3,40(sp)
    80001f76:	f052                	sd	s4,32(sp)
    80001f78:	ec56                	sd	s5,24(sp)
    80001f7a:	e85a                	sd	s6,16(sp)
    80001f7c:	e45e                	sd	s7,8(sp)
    80001f7e:	e062                	sd	s8,0(sp)
    80001f80:	0880                	addi	s0,sp,80
    80001f82:	8792                	mv	a5,tp
  int id = r_tp();
    80001f84:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f86:	00779b13          	slli	s6,a5,0x7
    80001f8a:	00010717          	auipc	a4,0x10
    80001f8e:	9c670713          	addi	a4,a4,-1594 # 80011950 <pid_lock>
    80001f92:	975a                	add	a4,a4,s6
    80001f94:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f98:	00010717          	auipc	a4,0x10
    80001f9c:	9d870713          	addi	a4,a4,-1576 # 80011970 <cpus+0x8>
    80001fa0:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fa2:	4c0d                	li	s8,3
        c->proc = p;
    80001fa4:	079e                	slli	a5,a5,0x7
    80001fa6:	00010a17          	auipc	s4,0x10
    80001faa:	9aaa0a13          	addi	s4,s4,-1622 # 80011950 <pid_lock>
    80001fae:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb0:	00016997          	auipc	s3,0x16
    80001fb4:	db898993          	addi	s3,s3,-584 # 80017d68 <tickslock>
        found = 1;
    80001fb8:	4b85                	li	s7,1
    80001fba:	a899                	j	80002010 <scheduler+0xa6>
        p->state = RUNNING;
    80001fbc:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fc0:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fc4:	06048593          	addi	a1,s1,96
    80001fc8:	855a                	mv	a0,s6
    80001fca:	00000097          	auipc	ra,0x0
    80001fce:	638080e7          	jalr	1592(ra) # 80002602 <swtch>
        c->proc = 0;
    80001fd2:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fd6:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fd8:	8526                	mv	a0,s1
    80001fda:	fffff097          	auipc	ra,0xfffff
    80001fde:	d46080e7          	jalr	-698(ra) # 80000d20 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe2:	18048493          	addi	s1,s1,384
    80001fe6:	01348b63          	beq	s1,s3,80001ffc <scheduler+0x92>
      acquire(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	c80080e7          	jalr	-896(ra) # 80000c6c <acquire>
      if(p->state == RUNNABLE) {
    80001ff4:	4c9c                	lw	a5,24(s1)
    80001ff6:	ff2791e3          	bne	a5,s2,80001fd8 <scheduler+0x6e>
    80001ffa:	b7c9                	j	80001fbc <scheduler+0x52>
    if(found == 0) {
    80001ffc:	000a9a63          	bnez	s5,80002010 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002000:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002004:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002008:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000200c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002010:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002014:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002018:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000201c:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000201e:	00010497          	auipc	s1,0x10
    80002022:	d4a48493          	addi	s1,s1,-694 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002026:	4909                	li	s2,2
    80002028:	b7c9                	j	80001fea <scheduler+0x80>

000000008000202a <sched>:
{
    8000202a:	7179                	addi	sp,sp,-48
    8000202c:	f406                	sd	ra,40(sp)
    8000202e:	f022                	sd	s0,32(sp)
    80002030:	ec26                	sd	s1,24(sp)
    80002032:	e84a                	sd	s2,16(sp)
    80002034:	e44e                	sd	s3,8(sp)
    80002036:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	a02080e7          	jalr	-1534(ra) # 80001a3a <myproc>
    80002040:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	bb0080e7          	jalr	-1104(ra) # 80000bf2 <holding>
    8000204a:	c93d                	beqz	a0,800020c0 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	00010717          	auipc	a4,0x10
    80002056:	8fe70713          	addi	a4,a4,-1794 # 80011950 <pid_lock>
    8000205a:	97ba                	add	a5,a5,a4
    8000205c:	0907a703          	lw	a4,144(a5)
    80002060:	4785                	li	a5,1
    80002062:	06f71763          	bne	a4,a5,800020d0 <sched+0xa6>
  if(p->state == RUNNING)
    80002066:	4c98                	lw	a4,24(s1)
    80002068:	478d                	li	a5,3
    8000206a:	06f70b63          	beq	a4,a5,800020e0 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002072:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002074:	efb5                	bnez	a5,800020f0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002076:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002078:	00010917          	auipc	s2,0x10
    8000207c:	8d890913          	addi	s2,s2,-1832 # 80011950 <pid_lock>
    80002080:	2781                	sext.w	a5,a5
    80002082:	079e                	slli	a5,a5,0x7
    80002084:	97ca                	add	a5,a5,s2
    80002086:	0947a983          	lw	s3,148(a5)
    8000208a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000208c:	2781                	sext.w	a5,a5
    8000208e:	079e                	slli	a5,a5,0x7
    80002090:	00010597          	auipc	a1,0x10
    80002094:	8e058593          	addi	a1,a1,-1824 # 80011970 <cpus+0x8>
    80002098:	95be                	add	a1,a1,a5
    8000209a:	06048513          	addi	a0,s1,96
    8000209e:	00000097          	auipc	ra,0x0
    800020a2:	564080e7          	jalr	1380(ra) # 80002602 <swtch>
    800020a6:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	97ca                	add	a5,a5,s2
    800020ae:	0937aa23          	sw	s3,148(a5)
}
    800020b2:	70a2                	ld	ra,40(sp)
    800020b4:	7402                	ld	s0,32(sp)
    800020b6:	64e2                	ld	s1,24(sp)
    800020b8:	6942                	ld	s2,16(sp)
    800020ba:	69a2                	ld	s3,8(sp)
    800020bc:	6145                	addi	sp,sp,48
    800020be:	8082                	ret
    panic("sched p->lock");
    800020c0:	00006517          	auipc	a0,0x6
    800020c4:	15850513          	addi	a0,a0,344 # 80008218 <digits+0x1c0>
    800020c8:	ffffe097          	auipc	ra,0xffffe
    800020cc:	480080e7          	jalr	1152(ra) # 80000548 <panic>
    panic("sched locks");
    800020d0:	00006517          	auipc	a0,0x6
    800020d4:	15850513          	addi	a0,a0,344 # 80008228 <digits+0x1d0>
    800020d8:	ffffe097          	auipc	ra,0xffffe
    800020dc:	470080e7          	jalr	1136(ra) # 80000548 <panic>
    panic("sched running");
    800020e0:	00006517          	auipc	a0,0x6
    800020e4:	15850513          	addi	a0,a0,344 # 80008238 <digits+0x1e0>
    800020e8:	ffffe097          	auipc	ra,0xffffe
    800020ec:	460080e7          	jalr	1120(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020f0:	00006517          	auipc	a0,0x6
    800020f4:	15850513          	addi	a0,a0,344 # 80008248 <digits+0x1f0>
    800020f8:	ffffe097          	auipc	ra,0xffffe
    800020fc:	450080e7          	jalr	1104(ra) # 80000548 <panic>

0000000080002100 <exit>:
{
    80002100:	7179                	addi	sp,sp,-48
    80002102:	f406                	sd	ra,40(sp)
    80002104:	f022                	sd	s0,32(sp)
    80002106:	ec26                	sd	s1,24(sp)
    80002108:	e84a                	sd	s2,16(sp)
    8000210a:	e44e                	sd	s3,8(sp)
    8000210c:	e052                	sd	s4,0(sp)
    8000210e:	1800                	addi	s0,sp,48
    80002110:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002112:	00000097          	auipc	ra,0x0
    80002116:	928080e7          	jalr	-1752(ra) # 80001a3a <myproc>
    8000211a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000211c:	00007797          	auipc	a5,0x7
    80002120:	efc7b783          	ld	a5,-260(a5) # 80009018 <initproc>
    80002124:	0d050493          	addi	s1,a0,208
    80002128:	15050913          	addi	s2,a0,336
    8000212c:	02a79363          	bne	a5,a0,80002152 <exit+0x52>
    panic("init exiting");
    80002130:	00006517          	auipc	a0,0x6
    80002134:	13050513          	addi	a0,a0,304 # 80008260 <digits+0x208>
    80002138:	ffffe097          	auipc	ra,0xffffe
    8000213c:	410080e7          	jalr	1040(ra) # 80000548 <panic>
      fileclose(f);
    80002140:	00002097          	auipc	ra,0x2
    80002144:	4b6080e7          	jalr	1206(ra) # 800045f6 <fileclose>
      p->ofile[fd] = 0;
    80002148:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000214c:	04a1                	addi	s1,s1,8
    8000214e:	01248563          	beq	s1,s2,80002158 <exit+0x58>
    if(p->ofile[fd]){
    80002152:	6088                	ld	a0,0(s1)
    80002154:	f575                	bnez	a0,80002140 <exit+0x40>
    80002156:	bfdd                	j	8000214c <exit+0x4c>
  begin_op();
    80002158:	00002097          	auipc	ra,0x2
    8000215c:	fcc080e7          	jalr	-52(ra) # 80004124 <begin_op>
  iput(p->cwd);
    80002160:	1509b503          	ld	a0,336(s3)
    80002164:	00001097          	auipc	ra,0x1
    80002168:	7be080e7          	jalr	1982(ra) # 80003922 <iput>
  end_op();
    8000216c:	00002097          	auipc	ra,0x2
    80002170:	038080e7          	jalr	56(ra) # 800041a4 <end_op>
  p->cwd = 0;
    80002174:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002178:	00007497          	auipc	s1,0x7
    8000217c:	ea048493          	addi	s1,s1,-352 # 80009018 <initproc>
    80002180:	6088                	ld	a0,0(s1)
    80002182:	fffff097          	auipc	ra,0xfffff
    80002186:	aea080e7          	jalr	-1302(ra) # 80000c6c <acquire>
  wakeup1(initproc);
    8000218a:	6088                	ld	a0,0(s1)
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	76e080e7          	jalr	1902(ra) # 800018fa <wakeup1>
  release(&initproc->lock);
    80002194:	6088                	ld	a0,0(s1)
    80002196:	fffff097          	auipc	ra,0xfffff
    8000219a:	b8a080e7          	jalr	-1142(ra) # 80000d20 <release>
  acquire(&p->lock);
    8000219e:	854e                	mv	a0,s3
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	acc080e7          	jalr	-1332(ra) # 80000c6c <acquire>
  struct proc *original_parent = p->parent;
    800021a8:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021ac:	854e                	mv	a0,s3
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	b72080e7          	jalr	-1166(ra) # 80000d20 <release>
  acquire(&original_parent->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	fffff097          	auipc	ra,0xfffff
    800021bc:	ab4080e7          	jalr	-1356(ra) # 80000c6c <acquire>
  acquire(&p->lock);
    800021c0:	854e                	mv	a0,s3
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	aaa080e7          	jalr	-1366(ra) # 80000c6c <acquire>
  reparent(p);
    800021ca:	854e                	mv	a0,s3
    800021cc:	00000097          	auipc	ra,0x0
    800021d0:	d38080e7          	jalr	-712(ra) # 80001f04 <reparent>
  wakeup1(original_parent);
    800021d4:	8526                	mv	a0,s1
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	724080e7          	jalr	1828(ra) # 800018fa <wakeup1>
  p->xstate = status;
    800021de:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021e2:	4791                	li	a5,4
    800021e4:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021e8:	8526                	mv	a0,s1
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b36080e7          	jalr	-1226(ra) # 80000d20 <release>
  sched();
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	e38080e7          	jalr	-456(ra) # 8000202a <sched>
  panic("zombie exit");
    800021fa:	00006517          	auipc	a0,0x6
    800021fe:	07650513          	addi	a0,a0,118 # 80008270 <digits+0x218>
    80002202:	ffffe097          	auipc	ra,0xffffe
    80002206:	346080e7          	jalr	838(ra) # 80000548 <panic>

000000008000220a <yield>:
{
    8000220a:	1101                	addi	sp,sp,-32
    8000220c:	ec06                	sd	ra,24(sp)
    8000220e:	e822                	sd	s0,16(sp)
    80002210:	e426                	sd	s1,8(sp)
    80002212:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002214:	00000097          	auipc	ra,0x0
    80002218:	826080e7          	jalr	-2010(ra) # 80001a3a <myproc>
    8000221c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	a4e080e7          	jalr	-1458(ra) # 80000c6c <acquire>
  p->state = RUNNABLE;
    80002226:	4789                	li	a5,2
    80002228:	cc9c                	sw	a5,24(s1)
  sched();
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	e00080e7          	jalr	-512(ra) # 8000202a <sched>
  release(&p->lock);
    80002232:	8526                	mv	a0,s1
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	aec080e7          	jalr	-1300(ra) # 80000d20 <release>
}
    8000223c:	60e2                	ld	ra,24(sp)
    8000223e:	6442                	ld	s0,16(sp)
    80002240:	64a2                	ld	s1,8(sp)
    80002242:	6105                	addi	sp,sp,32
    80002244:	8082                	ret

0000000080002246 <sleep>:
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	1800                	addi	s0,sp,48
    80002254:	89aa                	mv	s3,a0
    80002256:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	7e2080e7          	jalr	2018(ra) # 80001a3a <myproc>
    80002260:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002262:	05250663          	beq	a0,s2,800022ae <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a06080e7          	jalr	-1530(ra) # 80000c6c <acquire>
    release(lk);
    8000226e:	854a                	mv	a0,s2
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	ab0080e7          	jalr	-1360(ra) # 80000d20 <release>
  p->chan = chan;
    80002278:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000227c:	4785                	li	a5,1
    8000227e:	cc9c                	sw	a5,24(s1)
  sched();
    80002280:	00000097          	auipc	ra,0x0
    80002284:	daa080e7          	jalr	-598(ra) # 8000202a <sched>
  p->chan = 0;
    80002288:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a92080e7          	jalr	-1390(ra) # 80000d20 <release>
    acquire(lk);
    80002296:	854a                	mv	a0,s2
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	9d4080e7          	jalr	-1580(ra) # 80000c6c <acquire>
}
    800022a0:	70a2                	ld	ra,40(sp)
    800022a2:	7402                	ld	s0,32(sp)
    800022a4:	64e2                	ld	s1,24(sp)
    800022a6:	6942                	ld	s2,16(sp)
    800022a8:	69a2                	ld	s3,8(sp)
    800022aa:	6145                	addi	sp,sp,48
    800022ac:	8082                	ret
  p->chan = chan;
    800022ae:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022b2:	4785                	li	a5,1
    800022b4:	cd1c                	sw	a5,24(a0)
  sched();
    800022b6:	00000097          	auipc	ra,0x0
    800022ba:	d74080e7          	jalr	-652(ra) # 8000202a <sched>
  p->chan = 0;
    800022be:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022c2:	bff9                	j	800022a0 <sleep+0x5a>

00000000800022c4 <wait>:
{
    800022c4:	715d                	addi	sp,sp,-80
    800022c6:	e486                	sd	ra,72(sp)
    800022c8:	e0a2                	sd	s0,64(sp)
    800022ca:	fc26                	sd	s1,56(sp)
    800022cc:	f84a                	sd	s2,48(sp)
    800022ce:	f44e                	sd	s3,40(sp)
    800022d0:	f052                	sd	s4,32(sp)
    800022d2:	ec56                	sd	s5,24(sp)
    800022d4:	e85a                	sd	s6,16(sp)
    800022d6:	e45e                	sd	s7,8(sp)
    800022d8:	e062                	sd	s8,0(sp)
    800022da:	0880                	addi	s0,sp,80
    800022dc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	75c080e7          	jalr	1884(ra) # 80001a3a <myproc>
    800022e6:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022e8:	8c2a                	mv	s8,a0
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	982080e7          	jalr	-1662(ra) # 80000c6c <acquire>
    havekids = 0;
    800022f2:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022f4:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022f6:	00016997          	auipc	s3,0x16
    800022fa:	a7298993          	addi	s3,s3,-1422 # 80017d68 <tickslock>
        havekids = 1;
    800022fe:	4a85                	li	s5,1
    havekids = 0;
    80002300:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002302:	00010497          	auipc	s1,0x10
    80002306:	a6648493          	addi	s1,s1,-1434 # 80011d68 <proc>
    8000230a:	a08d                	j	8000236c <wait+0xa8>
          pid = np->pid;
    8000230c:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002310:	000b0e63          	beqz	s6,8000232c <wait+0x68>
    80002314:	4691                	li	a3,4
    80002316:	03448613          	addi	a2,s1,52
    8000231a:	85da                	mv	a1,s6
    8000231c:	05093503          	ld	a0,80(s2)
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	40e080e7          	jalr	1038(ra) # 8000172e <copyout>
    80002328:	02054263          	bltz	a0,8000234c <wait+0x88>
          freeproc(np);
    8000232c:	8526                	mv	a0,s1
    8000232e:	00000097          	auipc	ra,0x0
    80002332:	8be080e7          	jalr	-1858(ra) # 80001bec <freeproc>
          release(&np->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	9e8080e7          	jalr	-1560(ra) # 80000d20 <release>
          release(&p->lock);
    80002340:	854a                	mv	a0,s2
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	9de080e7          	jalr	-1570(ra) # 80000d20 <release>
          return pid;
    8000234a:	a8a9                	j	800023a4 <wait+0xe0>
            release(&np->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	9d2080e7          	jalr	-1582(ra) # 80000d20 <release>
            release(&p->lock);
    80002356:	854a                	mv	a0,s2
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	9c8080e7          	jalr	-1592(ra) # 80000d20 <release>
            return -1;
    80002360:	59fd                	li	s3,-1
    80002362:	a089                	j	800023a4 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002364:	18048493          	addi	s1,s1,384
    80002368:	03348463          	beq	s1,s3,80002390 <wait+0xcc>
      if(np->parent == p){
    8000236c:	709c                	ld	a5,32(s1)
    8000236e:	ff279be3          	bne	a5,s2,80002364 <wait+0xa0>
        acquire(&np->lock);
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	8f8080e7          	jalr	-1800(ra) # 80000c6c <acquire>
        if(np->state == ZOMBIE){
    8000237c:	4c9c                	lw	a5,24(s1)
    8000237e:	f94787e3          	beq	a5,s4,8000230c <wait+0x48>
        release(&np->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	99c080e7          	jalr	-1636(ra) # 80000d20 <release>
        havekids = 1;
    8000238c:	8756                	mv	a4,s5
    8000238e:	bfd9                	j	80002364 <wait+0xa0>
    if(!havekids || p->killed){
    80002390:	c701                	beqz	a4,80002398 <wait+0xd4>
    80002392:	03092783          	lw	a5,48(s2)
    80002396:	c785                	beqz	a5,800023be <wait+0xfa>
      release(&p->lock);
    80002398:	854a                	mv	a0,s2
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	986080e7          	jalr	-1658(ra) # 80000d20 <release>
      return -1;
    800023a2:	59fd                	li	s3,-1
}
    800023a4:	854e                	mv	a0,s3
    800023a6:	60a6                	ld	ra,72(sp)
    800023a8:	6406                	ld	s0,64(sp)
    800023aa:	74e2                	ld	s1,56(sp)
    800023ac:	7942                	ld	s2,48(sp)
    800023ae:	79a2                	ld	s3,40(sp)
    800023b0:	7a02                	ld	s4,32(sp)
    800023b2:	6ae2                	ld	s5,24(sp)
    800023b4:	6b42                	ld	s6,16(sp)
    800023b6:	6ba2                	ld	s7,8(sp)
    800023b8:	6c02                	ld	s8,0(sp)
    800023ba:	6161                	addi	sp,sp,80
    800023bc:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023be:	85e2                	mv	a1,s8
    800023c0:	854a                	mv	a0,s2
    800023c2:	00000097          	auipc	ra,0x0
    800023c6:	e84080e7          	jalr	-380(ra) # 80002246 <sleep>
    havekids = 0;
    800023ca:	bf1d                	j	80002300 <wait+0x3c>

00000000800023cc <wakeup>:
{
    800023cc:	7139                	addi	sp,sp,-64
    800023ce:	fc06                	sd	ra,56(sp)
    800023d0:	f822                	sd	s0,48(sp)
    800023d2:	f426                	sd	s1,40(sp)
    800023d4:	f04a                	sd	s2,32(sp)
    800023d6:	ec4e                	sd	s3,24(sp)
    800023d8:	e852                	sd	s4,16(sp)
    800023da:	e456                	sd	s5,8(sp)
    800023dc:	0080                	addi	s0,sp,64
    800023de:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023e0:	00010497          	auipc	s1,0x10
    800023e4:	98848493          	addi	s1,s1,-1656 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023e8:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023ea:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ec:	00016917          	auipc	s2,0x16
    800023f0:	97c90913          	addi	s2,s2,-1668 # 80017d68 <tickslock>
    800023f4:	a821                	j	8000240c <wakeup+0x40>
      p->state = RUNNABLE;
    800023f6:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023fa:	8526                	mv	a0,s1
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	924080e7          	jalr	-1756(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002404:	18048493          	addi	s1,s1,384
    80002408:	01248e63          	beq	s1,s2,80002424 <wakeup+0x58>
    acquire(&p->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	85e080e7          	jalr	-1954(ra) # 80000c6c <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	ff3791e3          	bne	a5,s3,800023fa <wakeup+0x2e>
    8000241c:	749c                	ld	a5,40(s1)
    8000241e:	fd479ee3          	bne	a5,s4,800023fa <wakeup+0x2e>
    80002422:	bfd1                	j	800023f6 <wakeup+0x2a>
}
    80002424:	70e2                	ld	ra,56(sp)
    80002426:	7442                	ld	s0,48(sp)
    80002428:	74a2                	ld	s1,40(sp)
    8000242a:	7902                	ld	s2,32(sp)
    8000242c:	69e2                	ld	s3,24(sp)
    8000242e:	6a42                	ld	s4,16(sp)
    80002430:	6aa2                	ld	s5,8(sp)
    80002432:	6121                	addi	sp,sp,64
    80002434:	8082                	ret

0000000080002436 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002436:	7179                	addi	sp,sp,-48
    80002438:	f406                	sd	ra,40(sp)
    8000243a:	f022                	sd	s0,32(sp)
    8000243c:	ec26                	sd	s1,24(sp)
    8000243e:	e84a                	sd	s2,16(sp)
    80002440:	e44e                	sd	s3,8(sp)
    80002442:	1800                	addi	s0,sp,48
    80002444:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002446:	00010497          	auipc	s1,0x10
    8000244a:	92248493          	addi	s1,s1,-1758 # 80011d68 <proc>
    8000244e:	00016997          	auipc	s3,0x16
    80002452:	91a98993          	addi	s3,s3,-1766 # 80017d68 <tickslock>
    acquire(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	814080e7          	jalr	-2028(ra) # 80000c6c <acquire>
    if(p->pid == pid){
    80002460:	5c9c                	lw	a5,56(s1)
    80002462:	01278d63          	beq	a5,s2,8000247c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	8b8080e7          	jalr	-1864(ra) # 80000d20 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002470:	18048493          	addi	s1,s1,384
    80002474:	ff3491e3          	bne	s1,s3,80002456 <kill+0x20>
  }
  return -1;
    80002478:	557d                	li	a0,-1
    8000247a:	a829                	j	80002494 <kill+0x5e>
      p->killed = 1;
    8000247c:	4785                	li	a5,1
    8000247e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002480:	4c98                	lw	a4,24(s1)
    80002482:	4785                	li	a5,1
    80002484:	00f70f63          	beq	a4,a5,800024a2 <kill+0x6c>
      release(&p->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	896080e7          	jalr	-1898(ra) # 80000d20 <release>
      return 0;
    80002492:	4501                	li	a0,0
}
    80002494:	70a2                	ld	ra,40(sp)
    80002496:	7402                	ld	s0,32(sp)
    80002498:	64e2                	ld	s1,24(sp)
    8000249a:	6942                	ld	s2,16(sp)
    8000249c:	69a2                	ld	s3,8(sp)
    8000249e:	6145                	addi	sp,sp,48
    800024a0:	8082                	ret
        p->state = RUNNABLE;
    800024a2:	4789                	li	a5,2
    800024a4:	cc9c                	sw	a5,24(s1)
    800024a6:	b7cd                	j	80002488 <kill+0x52>

00000000800024a8 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024a8:	7179                	addi	sp,sp,-48
    800024aa:	f406                	sd	ra,40(sp)
    800024ac:	f022                	sd	s0,32(sp)
    800024ae:	ec26                	sd	s1,24(sp)
    800024b0:	e84a                	sd	s2,16(sp)
    800024b2:	e44e                	sd	s3,8(sp)
    800024b4:	e052                	sd	s4,0(sp)
    800024b6:	1800                	addi	s0,sp,48
    800024b8:	84aa                	mv	s1,a0
    800024ba:	892e                	mv	s2,a1
    800024bc:	89b2                	mv	s3,a2
    800024be:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	57a080e7          	jalr	1402(ra) # 80001a3a <myproc>
  if(user_dst){
    800024c8:	c08d                	beqz	s1,800024ea <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024ca:	86d2                	mv	a3,s4
    800024cc:	864e                	mv	a2,s3
    800024ce:	85ca                	mv	a1,s2
    800024d0:	6928                	ld	a0,80(a0)
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	25c080e7          	jalr	604(ra) # 8000172e <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024da:	70a2                	ld	ra,40(sp)
    800024dc:	7402                	ld	s0,32(sp)
    800024de:	64e2                	ld	s1,24(sp)
    800024e0:	6942                	ld	s2,16(sp)
    800024e2:	69a2                	ld	s3,8(sp)
    800024e4:	6a02                	ld	s4,0(sp)
    800024e6:	6145                	addi	sp,sp,48
    800024e8:	8082                	ret
    memmove((char *)dst, src, len);
    800024ea:	000a061b          	sext.w	a2,s4
    800024ee:	85ce                	mv	a1,s3
    800024f0:	854a                	mv	a0,s2
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	8d6080e7          	jalr	-1834(ra) # 80000dc8 <memmove>
    return 0;
    800024fa:	8526                	mv	a0,s1
    800024fc:	bff9                	j	800024da <either_copyout+0x32>

00000000800024fe <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024fe:	7179                	addi	sp,sp,-48
    80002500:	f406                	sd	ra,40(sp)
    80002502:	f022                	sd	s0,32(sp)
    80002504:	ec26                	sd	s1,24(sp)
    80002506:	e84a                	sd	s2,16(sp)
    80002508:	e44e                	sd	s3,8(sp)
    8000250a:	e052                	sd	s4,0(sp)
    8000250c:	1800                	addi	s0,sp,48
    8000250e:	892a                	mv	s2,a0
    80002510:	84ae                	mv	s1,a1
    80002512:	89b2                	mv	s3,a2
    80002514:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	524080e7          	jalr	1316(ra) # 80001a3a <myproc>
  if(user_src){
    8000251e:	c08d                	beqz	s1,80002540 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002520:	86d2                	mv	a3,s4
    80002522:	864e                	mv	a2,s3
    80002524:	85ca                	mv	a1,s2
    80002526:	6928                	ld	a0,80(a0)
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	292080e7          	jalr	658(ra) # 800017ba <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002530:	70a2                	ld	ra,40(sp)
    80002532:	7402                	ld	s0,32(sp)
    80002534:	64e2                	ld	s1,24(sp)
    80002536:	6942                	ld	s2,16(sp)
    80002538:	69a2                	ld	s3,8(sp)
    8000253a:	6a02                	ld	s4,0(sp)
    8000253c:	6145                	addi	sp,sp,48
    8000253e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002540:	000a061b          	sext.w	a2,s4
    80002544:	85ce                	mv	a1,s3
    80002546:	854a                	mv	a0,s2
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	880080e7          	jalr	-1920(ra) # 80000dc8 <memmove>
    return 0;
    80002550:	8526                	mv	a0,s1
    80002552:	bff9                	j	80002530 <either_copyin+0x32>

0000000080002554 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002554:	715d                	addi	sp,sp,-80
    80002556:	e486                	sd	ra,72(sp)
    80002558:	e0a2                	sd	s0,64(sp)
    8000255a:	fc26                	sd	s1,56(sp)
    8000255c:	f84a                	sd	s2,48(sp)
    8000255e:	f44e                	sd	s3,40(sp)
    80002560:	f052                	sd	s4,32(sp)
    80002562:	ec56                	sd	s5,24(sp)
    80002564:	e85a                	sd	s6,16(sp)
    80002566:	e45e                	sd	s7,8(sp)
    80002568:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256a:	00006517          	auipc	a0,0x6
    8000256e:	b7650513          	addi	a0,a0,-1162 # 800080e0 <digits+0x88>
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	020080e7          	jalr	32(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257a:	00010497          	auipc	s1,0x10
    8000257e:	94648493          	addi	s1,s1,-1722 # 80011ec0 <proc+0x158>
    80002582:	00016917          	auipc	s2,0x16
    80002586:	93e90913          	addi	s2,s2,-1730 # 80017ec0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000258c:	00006997          	auipc	s3,0x6
    80002590:	cf498993          	addi	s3,s3,-780 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    80002594:	00006a97          	auipc	s5,0x6
    80002598:	cf4a8a93          	addi	s5,s5,-780 # 80008288 <digits+0x230>
    printf("\n");
    8000259c:	00006a17          	auipc	s4,0x6
    800025a0:	b44a0a13          	addi	s4,s4,-1212 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a4:	00006b97          	auipc	s7,0x6
    800025a8:	d1cb8b93          	addi	s7,s7,-740 # 800082c0 <states.1710>
    800025ac:	a00d                	j	800025ce <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025ae:	ee06a583          	lw	a1,-288(a3)
    800025b2:	8556                	mv	a0,s5
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	fde080e7          	jalr	-34(ra) # 80000592 <printf>
    printf("\n");
    800025bc:	8552                	mv	a0,s4
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fd4080e7          	jalr	-44(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	18048493          	addi	s1,s1,384
    800025ca:	03248163          	beq	s1,s2,800025ec <procdump+0x98>
    if(p->state == UNUSED)
    800025ce:	86a6                	mv	a3,s1
    800025d0:	ec04a783          	lw	a5,-320(s1)
    800025d4:	dbed                	beqz	a5,800025c6 <procdump+0x72>
      state = "???";
    800025d6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d8:	fcfb6be3          	bltu	s6,a5,800025ae <procdump+0x5a>
    800025dc:	1782                	slli	a5,a5,0x20
    800025de:	9381                	srli	a5,a5,0x20
    800025e0:	078e                	slli	a5,a5,0x3
    800025e2:	97de                	add	a5,a5,s7
    800025e4:	6390                	ld	a2,0(a5)
    800025e6:	f661                	bnez	a2,800025ae <procdump+0x5a>
      state = "???";
    800025e8:	864e                	mv	a2,s3
    800025ea:	b7d1                	j	800025ae <procdump+0x5a>
  }
}
    800025ec:	60a6                	ld	ra,72(sp)
    800025ee:	6406                	ld	s0,64(sp)
    800025f0:	74e2                	ld	s1,56(sp)
    800025f2:	7942                	ld	s2,48(sp)
    800025f4:	79a2                	ld	s3,40(sp)
    800025f6:	7a02                	ld	s4,32(sp)
    800025f8:	6ae2                	ld	s5,24(sp)
    800025fa:	6b42                	ld	s6,16(sp)
    800025fc:	6ba2                	ld	s7,8(sp)
    800025fe:	6161                	addi	sp,sp,80
    80002600:	8082                	ret

0000000080002602 <swtch>:
    80002602:	00153023          	sd	ra,0(a0)
    80002606:	00253423          	sd	sp,8(a0)
    8000260a:	e900                	sd	s0,16(a0)
    8000260c:	ed04                	sd	s1,24(a0)
    8000260e:	03253023          	sd	s2,32(a0)
    80002612:	03353423          	sd	s3,40(a0)
    80002616:	03453823          	sd	s4,48(a0)
    8000261a:	03553c23          	sd	s5,56(a0)
    8000261e:	05653023          	sd	s6,64(a0)
    80002622:	05753423          	sd	s7,72(a0)
    80002626:	05853823          	sd	s8,80(a0)
    8000262a:	05953c23          	sd	s9,88(a0)
    8000262e:	07a53023          	sd	s10,96(a0)
    80002632:	07b53423          	sd	s11,104(a0)
    80002636:	0005b083          	ld	ra,0(a1)
    8000263a:	0085b103          	ld	sp,8(a1)
    8000263e:	6980                	ld	s0,16(a1)
    80002640:	6d84                	ld	s1,24(a1)
    80002642:	0205b903          	ld	s2,32(a1)
    80002646:	0285b983          	ld	s3,40(a1)
    8000264a:	0305ba03          	ld	s4,48(a1)
    8000264e:	0385ba83          	ld	s5,56(a1)
    80002652:	0405bb03          	ld	s6,64(a1)
    80002656:	0485bb83          	ld	s7,72(a1)
    8000265a:	0505bc03          	ld	s8,80(a1)
    8000265e:	0585bc83          	ld	s9,88(a1)
    80002662:	0605bd03          	ld	s10,96(a1)
    80002666:	0685bd83          	ld	s11,104(a1)
    8000266a:	8082                	ret

000000008000266c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000266c:	1141                	addi	sp,sp,-16
    8000266e:	e406                	sd	ra,8(sp)
    80002670:	e022                	sd	s0,0(sp)
    80002672:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002674:	00006597          	auipc	a1,0x6
    80002678:	c7458593          	addi	a1,a1,-908 # 800082e8 <states.1710+0x28>
    8000267c:	00015517          	auipc	a0,0x15
    80002680:	6ec50513          	addi	a0,a0,1772 # 80017d68 <tickslock>
    80002684:	ffffe097          	auipc	ra,0xffffe
    80002688:	558080e7          	jalr	1368(ra) # 80000bdc <initlock>
}
    8000268c:	60a2                	ld	ra,8(sp)
    8000268e:	6402                	ld	s0,0(sp)
    80002690:	0141                	addi	sp,sp,16
    80002692:	8082                	ret

0000000080002694 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e422                	sd	s0,8(sp)
    80002698:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000269a:	00003797          	auipc	a5,0x3
    8000269e:	5c678793          	addi	a5,a5,1478 # 80005c60 <kernelvec>
    800026a2:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026a6:	6422                	ld	s0,8(sp)
    800026a8:	0141                	addi	sp,sp,16
    800026aa:	8082                	ret

00000000800026ac <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026ac:	1141                	addi	sp,sp,-16
    800026ae:	e406                	sd	ra,8(sp)
    800026b0:	e022                	sd	s0,0(sp)
    800026b2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026b4:	fffff097          	auipc	ra,0xfffff
    800026b8:	386080e7          	jalr	902(ra) # 80001a3a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026bc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026c6:	00005617          	auipc	a2,0x5
    800026ca:	93a60613          	addi	a2,a2,-1734 # 80007000 <_trampoline>
    800026ce:	00005697          	auipc	a3,0x5
    800026d2:	93268693          	addi	a3,a3,-1742 # 80007000 <_trampoline>
    800026d6:	8e91                	sub	a3,a3,a2
    800026d8:	040007b7          	lui	a5,0x4000
    800026dc:	17fd                	addi	a5,a5,-1
    800026de:	07b2                	slli	a5,a5,0xc
    800026e0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e2:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026e6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026e8:	180026f3          	csrr	a3,satp
    800026ec:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026ee:	6d38                	ld	a4,88(a0)
    800026f0:	6134                	ld	a3,64(a0)
    800026f2:	6585                	lui	a1,0x1
    800026f4:	96ae                	add	a3,a3,a1
    800026f6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026f8:	6d38                	ld	a4,88(a0)
    800026fa:	00000697          	auipc	a3,0x0
    800026fe:	13868693          	addi	a3,a3,312 # 80002832 <usertrap>
    80002702:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002704:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002706:	8692                	mv	a3,tp
    80002708:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270a:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000270e:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002712:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002716:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000271a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000271c:	6f18                	ld	a4,24(a4)
    8000271e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002722:	692c                	ld	a1,80(a0)
    80002724:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002726:	00005717          	auipc	a4,0x5
    8000272a:	96a70713          	addi	a4,a4,-1686 # 80007090 <userret>
    8000272e:	8f11                	sub	a4,a4,a2
    80002730:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002732:	577d                	li	a4,-1
    80002734:	177e                	slli	a4,a4,0x3f
    80002736:	8dd9                	or	a1,a1,a4
    80002738:	02000537          	lui	a0,0x2000
    8000273c:	157d                	addi	a0,a0,-1
    8000273e:	0536                	slli	a0,a0,0xd
    80002740:	9782                	jalr	a5
}
    80002742:	60a2                	ld	ra,8(sp)
    80002744:	6402                	ld	s0,0(sp)
    80002746:	0141                	addi	sp,sp,16
    80002748:	8082                	ret

000000008000274a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000274a:	1101                	addi	sp,sp,-32
    8000274c:	ec06                	sd	ra,24(sp)
    8000274e:	e822                	sd	s0,16(sp)
    80002750:	e426                	sd	s1,8(sp)
    80002752:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002754:	00015497          	auipc	s1,0x15
    80002758:	61448493          	addi	s1,s1,1556 # 80017d68 <tickslock>
    8000275c:	8526                	mv	a0,s1
    8000275e:	ffffe097          	auipc	ra,0xffffe
    80002762:	50e080e7          	jalr	1294(ra) # 80000c6c <acquire>
  ticks++;
    80002766:	00007517          	auipc	a0,0x7
    8000276a:	8ba50513          	addi	a0,a0,-1862 # 80009020 <ticks>
    8000276e:	411c                	lw	a5,0(a0)
    80002770:	2785                	addiw	a5,a5,1
    80002772:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002774:	00000097          	auipc	ra,0x0
    80002778:	c58080e7          	jalr	-936(ra) # 800023cc <wakeup>
  release(&tickslock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	5a2080e7          	jalr	1442(ra) # 80000d20 <release>
}
    80002786:	60e2                	ld	ra,24(sp)
    80002788:	6442                	ld	s0,16(sp)
    8000278a:	64a2                	ld	s1,8(sp)
    8000278c:	6105                	addi	sp,sp,32
    8000278e:	8082                	ret

0000000080002790 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002790:	1101                	addi	sp,sp,-32
    80002792:	ec06                	sd	ra,24(sp)
    80002794:	e822                	sd	s0,16(sp)
    80002796:	e426                	sd	s1,8(sp)
    80002798:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000279a:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000279e:	00074d63          	bltz	a4,800027b8 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027a2:	57fd                	li	a5,-1
    800027a4:	17fe                	slli	a5,a5,0x3f
    800027a6:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027a8:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027aa:	06f70363          	beq	a4,a5,80002810 <devintr+0x80>
  }
}
    800027ae:	60e2                	ld	ra,24(sp)
    800027b0:	6442                	ld	s0,16(sp)
    800027b2:	64a2                	ld	s1,8(sp)
    800027b4:	6105                	addi	sp,sp,32
    800027b6:	8082                	ret
     (scause & 0xff) == 9){
    800027b8:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027bc:	46a5                	li	a3,9
    800027be:	fed792e3          	bne	a5,a3,800027a2 <devintr+0x12>
    int irq = plic_claim();
    800027c2:	00003097          	auipc	ra,0x3
    800027c6:	5a6080e7          	jalr	1446(ra) # 80005d68 <plic_claim>
    800027ca:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027cc:	47a9                	li	a5,10
    800027ce:	02f50763          	beq	a0,a5,800027fc <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027d2:	4785                	li	a5,1
    800027d4:	02f50963          	beq	a0,a5,80002806 <devintr+0x76>
    return 1;
    800027d8:	4505                	li	a0,1
    } else if(irq){
    800027da:	d8f1                	beqz	s1,800027ae <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027dc:	85a6                	mv	a1,s1
    800027de:	00006517          	auipc	a0,0x6
    800027e2:	b1250513          	addi	a0,a0,-1262 # 800082f0 <states.1710+0x30>
    800027e6:	ffffe097          	auipc	ra,0xffffe
    800027ea:	dac080e7          	jalr	-596(ra) # 80000592 <printf>
      plic_complete(irq);
    800027ee:	8526                	mv	a0,s1
    800027f0:	00003097          	auipc	ra,0x3
    800027f4:	59c080e7          	jalr	1436(ra) # 80005d8c <plic_complete>
    return 1;
    800027f8:	4505                	li	a0,1
    800027fa:	bf55                	j	800027ae <devintr+0x1e>
      uartintr();
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	234080e7          	jalr	564(ra) # 80000a30 <uartintr>
    80002804:	b7ed                	j	800027ee <devintr+0x5e>
      virtio_disk_intr();
    80002806:	00004097          	auipc	ra,0x4
    8000280a:	a20080e7          	jalr	-1504(ra) # 80006226 <virtio_disk_intr>
    8000280e:	b7c5                	j	800027ee <devintr+0x5e>
    if(cpuid() == 0){
    80002810:	fffff097          	auipc	ra,0xfffff
    80002814:	1fe080e7          	jalr	510(ra) # 80001a0e <cpuid>
    80002818:	c901                	beqz	a0,80002828 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000281a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000281e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002820:	14479073          	csrw	sip,a5
    return 2;
    80002824:	4509                	li	a0,2
    80002826:	b761                	j	800027ae <devintr+0x1e>
      clockintr();
    80002828:	00000097          	auipc	ra,0x0
    8000282c:	f22080e7          	jalr	-222(ra) # 8000274a <clockintr>
    80002830:	b7ed                	j	8000281a <devintr+0x8a>

0000000080002832 <usertrap>:
{
    80002832:	1101                	addi	sp,sp,-32
    80002834:	ec06                	sd	ra,24(sp)
    80002836:	e822                	sd	s0,16(sp)
    80002838:	e426                	sd	s1,8(sp)
    8000283a:	e04a                	sd	s2,0(sp)
    8000283c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000283e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002842:	1007f793          	andi	a5,a5,256
    80002846:	e3ad                	bnez	a5,800028a8 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002848:	00003797          	auipc	a5,0x3
    8000284c:	41878793          	addi	a5,a5,1048 # 80005c60 <kernelvec>
    80002850:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	1e6080e7          	jalr	486(ra) # 80001a3a <myproc>
    8000285c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000285e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002860:	14102773          	csrr	a4,sepc
    80002864:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002866:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000286a:	47a1                	li	a5,8
    8000286c:	04f71c63          	bne	a4,a5,800028c4 <usertrap+0x92>
    if(p->killed)
    80002870:	591c                	lw	a5,48(a0)
    80002872:	e3b9                	bnez	a5,800028b8 <usertrap+0x86>
    p->trapframe->epc += 4;
    80002874:	6cb8                	ld	a4,88(s1)
    80002876:	6f1c                	ld	a5,24(a4)
    80002878:	0791                	addi	a5,a5,4
    8000287a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000287c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002880:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002884:	10079073          	csrw	sstatus,a5
    syscall();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	33a080e7          	jalr	826(ra) # 80002bc2 <syscall>
  if(p->killed)
    80002890:	589c                	lw	a5,48(s1)
    80002892:	ebcd                	bnez	a5,80002944 <usertrap+0x112>
  usertrapret();
    80002894:	00000097          	auipc	ra,0x0
    80002898:	e18080e7          	jalr	-488(ra) # 800026ac <usertrapret>
}
    8000289c:	60e2                	ld	ra,24(sp)
    8000289e:	6442                	ld	s0,16(sp)
    800028a0:	64a2                	ld	s1,8(sp)
    800028a2:	6902                	ld	s2,0(sp)
    800028a4:	6105                	addi	sp,sp,32
    800028a6:	8082                	ret
    panic("usertrap: not from user mode");
    800028a8:	00006517          	auipc	a0,0x6
    800028ac:	a6850513          	addi	a0,a0,-1432 # 80008310 <states.1710+0x50>
    800028b0:	ffffe097          	auipc	ra,0xffffe
    800028b4:	c98080e7          	jalr	-872(ra) # 80000548 <panic>
      exit(-1);
    800028b8:	557d                	li	a0,-1
    800028ba:	00000097          	auipc	ra,0x0
    800028be:	846080e7          	jalr	-1978(ra) # 80002100 <exit>
    800028c2:	bf4d                	j	80002874 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028c4:	00000097          	auipc	ra,0x0
    800028c8:	ecc080e7          	jalr	-308(ra) # 80002790 <devintr>
    800028cc:	892a                	mv	s2,a0
    800028ce:	c501                	beqz	a0,800028d6 <usertrap+0xa4>
  if(p->killed)
    800028d0:	589c                	lw	a5,48(s1)
    800028d2:	c3a1                	beqz	a5,80002912 <usertrap+0xe0>
    800028d4:	a815                	j	80002908 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028d6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028da:	5c90                	lw	a2,56(s1)
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	a5450513          	addi	a0,a0,-1452 # 80008330 <states.1710+0x70>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	cae080e7          	jalr	-850(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a6c50513          	addi	a0,a0,-1428 # 80008360 <states.1710+0xa0>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c96080e7          	jalr	-874(ra) # 80000592 <printf>
    p->killed = 1;
    80002904:	4785                	li	a5,1
    80002906:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002908:	557d                	li	a0,-1
    8000290a:	fffff097          	auipc	ra,0xfffff
    8000290e:	7f6080e7          	jalr	2038(ra) # 80002100 <exit>
 if(which_dev == 2){
    80002912:	4789                	li	a5,2
    80002914:	f8f910e3          	bne	s2,a5,80002894 <usertrap+0x62>
    if(p->alarm != 0){
    80002918:	1684a703          	lw	a4,360(s1)
    8000291c:	cf29                	beqz	a4,80002976 <usertrap+0x144>
      p->duringtime++;
    8000291e:	16c4a783          	lw	a5,364(s1)
    80002922:	2785                	addiw	a5,a5,1
    80002924:	0007869b          	sext.w	a3,a5
    80002928:	16f4a623          	sw	a5,364(s1)
      if(p->duringtime == p->alarm){
    8000292c:	04d71063          	bne	a4,a3,8000296c <usertrap+0x13a>
        p->duringtime = 0;
    80002930:	1604a623          	sw	zero,364(s1)
        if(p->alarmframe == 0){
    80002934:	1784b783          	ld	a5,376(s1)
    80002938:	cb81                	beqz	a5,80002948 <usertrap+0x116>
          yield();
    8000293a:	00000097          	auipc	ra,0x0
    8000293e:	8d0080e7          	jalr	-1840(ra) # 8000220a <yield>
    80002942:	bf89                	j	80002894 <usertrap+0x62>
  int which_dev = 0;
    80002944:	4901                	li	s2,0
    80002946:	b7c9                	j	80002908 <usertrap+0xd6>
          p->alarmframe = kalloc();
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	234080e7          	jalr	564(ra) # 80000b7c <kalloc>
    80002950:	16a4bc23          	sd	a0,376(s1)
          memmove(p->alarmframe, p->trapframe, 512);
    80002954:	20000613          	li	a2,512
    80002958:	6cac                	ld	a1,88(s1)
    8000295a:	ffffe097          	auipc	ra,0xffffe
    8000295e:	46e080e7          	jalr	1134(ra) # 80000dc8 <memmove>
          p->trapframe->epc = p->handler;
    80002962:	6cbc                	ld	a5,88(s1)
    80002964:	1704b703          	ld	a4,368(s1)
    80002968:	ef98                	sd	a4,24(a5)
    8000296a:	b72d                	j	80002894 <usertrap+0x62>
        yield();
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	89e080e7          	jalr	-1890(ra) # 8000220a <yield>
    80002974:	b705                	j	80002894 <usertrap+0x62>
      yield();
    80002976:	00000097          	auipc	ra,0x0
    8000297a:	894080e7          	jalr	-1900(ra) # 8000220a <yield>
    8000297e:	bf19                	j	80002894 <usertrap+0x62>

0000000080002980 <kerneltrap>:
{
    80002980:	7179                	addi	sp,sp,-48
    80002982:	f406                	sd	ra,40(sp)
    80002984:	f022                	sd	s0,32(sp)
    80002986:	ec26                	sd	s1,24(sp)
    80002988:	e84a                	sd	s2,16(sp)
    8000298a:	e44e                	sd	s3,8(sp)
    8000298c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000298e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002996:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000299a:	1004f793          	andi	a5,s1,256
    8000299e:	cb85                	beqz	a5,800029ce <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029a4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029a6:	ef85                	bnez	a5,800029de <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029a8:	00000097          	auipc	ra,0x0
    800029ac:	de8080e7          	jalr	-536(ra) # 80002790 <devintr>
    800029b0:	cd1d                	beqz	a0,800029ee <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b2:	4789                	li	a5,2
    800029b4:	06f50a63          	beq	a0,a5,80002a28 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029b8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029bc:	10049073          	csrw	sstatus,s1
}
    800029c0:	70a2                	ld	ra,40(sp)
    800029c2:	7402                	ld	s0,32(sp)
    800029c4:	64e2                	ld	s1,24(sp)
    800029c6:	6942                	ld	s2,16(sp)
    800029c8:	69a2                	ld	s3,8(sp)
    800029ca:	6145                	addi	sp,sp,48
    800029cc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ce:	00006517          	auipc	a0,0x6
    800029d2:	9b250513          	addi	a0,a0,-1614 # 80008380 <states.1710+0xc0>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	b72080e7          	jalr	-1166(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029de:	00006517          	auipc	a0,0x6
    800029e2:	9ca50513          	addi	a0,a0,-1590 # 800083a8 <states.1710+0xe8>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	b62080e7          	jalr	-1182(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    800029ee:	85ce                	mv	a1,s3
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	9d850513          	addi	a0,a0,-1576 # 800083c8 <states.1710+0x108>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b9a080e7          	jalr	-1126(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a00:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a04:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	9d050513          	addi	a0,a0,-1584 # 800083d8 <states.1710+0x118>
    80002a10:	ffffe097          	auipc	ra,0xffffe
    80002a14:	b82080e7          	jalr	-1150(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002a18:	00006517          	auipc	a0,0x6
    80002a1c:	9d850513          	addi	a0,a0,-1576 # 800083f0 <states.1710+0x130>
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	b28080e7          	jalr	-1240(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a28:	fffff097          	auipc	ra,0xfffff
    80002a2c:	012080e7          	jalr	18(ra) # 80001a3a <myproc>
    80002a30:	d541                	beqz	a0,800029b8 <kerneltrap+0x38>
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	008080e7          	jalr	8(ra) # 80001a3a <myproc>
    80002a3a:	4d18                	lw	a4,24(a0)
    80002a3c:	478d                	li	a5,3
    80002a3e:	f6f71de3          	bne	a4,a5,800029b8 <kerneltrap+0x38>
    yield();
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	7c8080e7          	jalr	1992(ra) # 8000220a <yield>
    80002a4a:	b7bd                	j	800029b8 <kerneltrap+0x38>

0000000080002a4c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a4c:	1101                	addi	sp,sp,-32
    80002a4e:	ec06                	sd	ra,24(sp)
    80002a50:	e822                	sd	s0,16(sp)
    80002a52:	e426                	sd	s1,8(sp)
    80002a54:	1000                	addi	s0,sp,32
    80002a56:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a58:	fffff097          	auipc	ra,0xfffff
    80002a5c:	fe2080e7          	jalr	-30(ra) # 80001a3a <myproc>
  switch (n) {
    80002a60:	4795                	li	a5,5
    80002a62:	0497e163          	bltu	a5,s1,80002aa4 <argraw+0x58>
    80002a66:	048a                	slli	s1,s1,0x2
    80002a68:	00006717          	auipc	a4,0x6
    80002a6c:	9c070713          	addi	a4,a4,-1600 # 80008428 <states.1710+0x168>
    80002a70:	94ba                	add	s1,s1,a4
    80002a72:	409c                	lw	a5,0(s1)
    80002a74:	97ba                	add	a5,a5,a4
    80002a76:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a7c:	60e2                	ld	ra,24(sp)
    80002a7e:	6442                	ld	s0,16(sp)
    80002a80:	64a2                	ld	s1,8(sp)
    80002a82:	6105                	addi	sp,sp,32
    80002a84:	8082                	ret
    return p->trapframe->a1;
    80002a86:	6d3c                	ld	a5,88(a0)
    80002a88:	7fa8                	ld	a0,120(a5)
    80002a8a:	bfcd                	j	80002a7c <argraw+0x30>
    return p->trapframe->a2;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	63c8                	ld	a0,128(a5)
    80002a90:	b7f5                	j	80002a7c <argraw+0x30>
    return p->trapframe->a3;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	67c8                	ld	a0,136(a5)
    80002a96:	b7dd                	j	80002a7c <argraw+0x30>
    return p->trapframe->a4;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	6bc8                	ld	a0,144(a5)
    80002a9c:	b7c5                	j	80002a7c <argraw+0x30>
    return p->trapframe->a5;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6fc8                	ld	a0,152(a5)
    80002aa2:	bfe9                	j	80002a7c <argraw+0x30>
  panic("argraw");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	95c50513          	addi	a0,a0,-1700 # 80008400 <states.1710+0x140>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	a9c080e7          	jalr	-1380(ra) # 80000548 <panic>

0000000080002ab4 <fetchaddr>:
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
    80002ac0:	84aa                	mv	s1,a0
    80002ac2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	f76080e7          	jalr	-138(ra) # 80001a3a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002acc:	653c                	ld	a5,72(a0)
    80002ace:	02f4f863          	bgeu	s1,a5,80002afe <fetchaddr+0x4a>
    80002ad2:	00848713          	addi	a4,s1,8
    80002ad6:	02e7e663          	bltu	a5,a4,80002b02 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ada:	46a1                	li	a3,8
    80002adc:	8626                	mv	a2,s1
    80002ade:	85ca                	mv	a1,s2
    80002ae0:	6928                	ld	a0,80(a0)
    80002ae2:	fffff097          	auipc	ra,0xfffff
    80002ae6:	cd8080e7          	jalr	-808(ra) # 800017ba <copyin>
    80002aea:	00a03533          	snez	a0,a0
    80002aee:	40a00533          	neg	a0,a0
}
    80002af2:	60e2                	ld	ra,24(sp)
    80002af4:	6442                	ld	s0,16(sp)
    80002af6:	64a2                	ld	s1,8(sp)
    80002af8:	6902                	ld	s2,0(sp)
    80002afa:	6105                	addi	sp,sp,32
    80002afc:	8082                	ret
    return -1;
    80002afe:	557d                	li	a0,-1
    80002b00:	bfcd                	j	80002af2 <fetchaddr+0x3e>
    80002b02:	557d                	li	a0,-1
    80002b04:	b7fd                	j	80002af2 <fetchaddr+0x3e>

0000000080002b06 <fetchstr>:
{
    80002b06:	7179                	addi	sp,sp,-48
    80002b08:	f406                	sd	ra,40(sp)
    80002b0a:	f022                	sd	s0,32(sp)
    80002b0c:	ec26                	sd	s1,24(sp)
    80002b0e:	e84a                	sd	s2,16(sp)
    80002b10:	e44e                	sd	s3,8(sp)
    80002b12:	1800                	addi	s0,sp,48
    80002b14:	892a                	mv	s2,a0
    80002b16:	84ae                	mv	s1,a1
    80002b18:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b1a:	fffff097          	auipc	ra,0xfffff
    80002b1e:	f20080e7          	jalr	-224(ra) # 80001a3a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b22:	86ce                	mv	a3,s3
    80002b24:	864a                	mv	a2,s2
    80002b26:	85a6                	mv	a1,s1
    80002b28:	6928                	ld	a0,80(a0)
    80002b2a:	fffff097          	auipc	ra,0xfffff
    80002b2e:	d1c080e7          	jalr	-740(ra) # 80001846 <copyinstr>
  if(err < 0)
    80002b32:	00054763          	bltz	a0,80002b40 <fetchstr+0x3a>
  return strlen(buf);
    80002b36:	8526                	mv	a0,s1
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	3b8080e7          	jalr	952(ra) # 80000ef0 <strlen>
}
    80002b40:	70a2                	ld	ra,40(sp)
    80002b42:	7402                	ld	s0,32(sp)
    80002b44:	64e2                	ld	s1,24(sp)
    80002b46:	6942                	ld	s2,16(sp)
    80002b48:	69a2                	ld	s3,8(sp)
    80002b4a:	6145                	addi	sp,sp,48
    80002b4c:	8082                	ret

0000000080002b4e <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b4e:	1101                	addi	sp,sp,-32
    80002b50:	ec06                	sd	ra,24(sp)
    80002b52:	e822                	sd	s0,16(sp)
    80002b54:	e426                	sd	s1,8(sp)
    80002b56:	1000                	addi	s0,sp,32
    80002b58:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	ef2080e7          	jalr	-270(ra) # 80002a4c <argraw>
    80002b62:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b64:	4501                	li	a0,0
    80002b66:	60e2                	ld	ra,24(sp)
    80002b68:	6442                	ld	s0,16(sp)
    80002b6a:	64a2                	ld	s1,8(sp)
    80002b6c:	6105                	addi	sp,sp,32
    80002b6e:	8082                	ret

0000000080002b70 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b70:	1101                	addi	sp,sp,-32
    80002b72:	ec06                	sd	ra,24(sp)
    80002b74:	e822                	sd	s0,16(sp)
    80002b76:	e426                	sd	s1,8(sp)
    80002b78:	1000                	addi	s0,sp,32
    80002b7a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7c:	00000097          	auipc	ra,0x0
    80002b80:	ed0080e7          	jalr	-304(ra) # 80002a4c <argraw>
    80002b84:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b86:	4501                	li	a0,0
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	e04a                	sd	s2,0(sp)
    80002b9c:	1000                	addi	s0,sp,32
    80002b9e:	84ae                	mv	s1,a1
    80002ba0:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	eaa080e7          	jalr	-342(ra) # 80002a4c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002baa:	864a                	mv	a2,s2
    80002bac:	85a6                	mv	a1,s1
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	f58080e7          	jalr	-168(ra) # 80002b06 <fetchstr>
}
    80002bb6:	60e2                	ld	ra,24(sp)
    80002bb8:	6442                	ld	s0,16(sp)
    80002bba:	64a2                	ld	s1,8(sp)
    80002bbc:	6902                	ld	s2,0(sp)
    80002bbe:	6105                	addi	sp,sp,32
    80002bc0:	8082                	ret

0000000080002bc2 <syscall>:
[SYS_sigreturn] sys_sigreturn, 
};

void
syscall(void)
{
    80002bc2:	1101                	addi	sp,sp,-32
    80002bc4:	ec06                	sd	ra,24(sp)
    80002bc6:	e822                	sd	s0,16(sp)
    80002bc8:	e426                	sd	s1,8(sp)
    80002bca:	e04a                	sd	s2,0(sp)
    80002bcc:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bce:	fffff097          	auipc	ra,0xfffff
    80002bd2:	e6c080e7          	jalr	-404(ra) # 80001a3a <myproc>
    80002bd6:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bd8:	05853903          	ld	s2,88(a0)
    80002bdc:	0a893783          	ld	a5,168(s2)
    80002be0:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be4:	37fd                	addiw	a5,a5,-1
    80002be6:	4759                	li	a4,22
    80002be8:	00f76f63          	bltu	a4,a5,80002c06 <syscall+0x44>
    80002bec:	00369713          	slli	a4,a3,0x3
    80002bf0:	00006797          	auipc	a5,0x6
    80002bf4:	85078793          	addi	a5,a5,-1968 # 80008440 <syscalls>
    80002bf8:	97ba                	add	a5,a5,a4
    80002bfa:	639c                	ld	a5,0(a5)
    80002bfc:	c789                	beqz	a5,80002c06 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bfe:	9782                	jalr	a5
    80002c00:	06a93823          	sd	a0,112(s2)
    80002c04:	a839                	j	80002c22 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c06:	15848613          	addi	a2,s1,344
    80002c0a:	5c8c                	lw	a1,56(s1)
    80002c0c:	00005517          	auipc	a0,0x5
    80002c10:	7fc50513          	addi	a0,a0,2044 # 80008408 <states.1710+0x148>
    80002c14:	ffffe097          	auipc	ra,0xffffe
    80002c18:	97e080e7          	jalr	-1666(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c1c:	6cbc                	ld	a5,88(s1)
    80002c1e:	577d                	li	a4,-1
    80002c20:	fbb8                	sd	a4,112(a5)
  }
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	64a2                	ld	s1,8(sp)
    80002c28:	6902                	ld	s2,0(sp)
    80002c2a:	6105                	addi	sp,sp,32
    80002c2c:	8082                	ret

0000000080002c2e <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c2e:	1101                	addi	sp,sp,-32
    80002c30:	ec06                	sd	ra,24(sp)
    80002c32:	e822                	sd	s0,16(sp)
    80002c34:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c36:	fec40593          	addi	a1,s0,-20
    80002c3a:	4501                	li	a0,0
    80002c3c:	00000097          	auipc	ra,0x0
    80002c40:	f12080e7          	jalr	-238(ra) # 80002b4e <argint>
    return -1;
    80002c44:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c46:	00054963          	bltz	a0,80002c58 <sys_exit+0x2a>
  exit(n);
    80002c4a:	fec42503          	lw	a0,-20(s0)
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	4b2080e7          	jalr	1202(ra) # 80002100 <exit>
  return 0;  // not reached
    80002c56:	4781                	li	a5,0
}
    80002c58:	853e                	mv	a0,a5
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	6105                	addi	sp,sp,32
    80002c60:	8082                	ret

0000000080002c62 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c62:	1141                	addi	sp,sp,-16
    80002c64:	e406                	sd	ra,8(sp)
    80002c66:	e022                	sd	s0,0(sp)
    80002c68:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c6a:	fffff097          	auipc	ra,0xfffff
    80002c6e:	dd0080e7          	jalr	-560(ra) # 80001a3a <myproc>
}
    80002c72:	5d08                	lw	a0,56(a0)
    80002c74:	60a2                	ld	ra,8(sp)
    80002c76:	6402                	ld	s0,0(sp)
    80002c78:	0141                	addi	sp,sp,16
    80002c7a:	8082                	ret

0000000080002c7c <sys_fork>:

uint64
sys_fork(void)
{
    80002c7c:	1141                	addi	sp,sp,-16
    80002c7e:	e406                	sd	ra,8(sp)
    80002c80:	e022                	sd	s0,0(sp)
    80002c82:	0800                	addi	s0,sp,16
  return fork();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	176080e7          	jalr	374(ra) # 80001dfa <fork>
}
    80002c8c:	60a2                	ld	ra,8(sp)
    80002c8e:	6402                	ld	s0,0(sp)
    80002c90:	0141                	addi	sp,sp,16
    80002c92:	8082                	ret

0000000080002c94 <sys_wait>:

uint64
sys_wait(void)
{
    80002c94:	1101                	addi	sp,sp,-32
    80002c96:	ec06                	sd	ra,24(sp)
    80002c98:	e822                	sd	s0,16(sp)
    80002c9a:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c9c:	fe840593          	addi	a1,s0,-24
    80002ca0:	4501                	li	a0,0
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	ece080e7          	jalr	-306(ra) # 80002b70 <argaddr>
    80002caa:	87aa                	mv	a5,a0
    return -1;
    80002cac:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cae:	0007c863          	bltz	a5,80002cbe <sys_wait+0x2a>
  return wait(p);
    80002cb2:	fe843503          	ld	a0,-24(s0)
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	60e080e7          	jalr	1550(ra) # 800022c4 <wait>
}
    80002cbe:	60e2                	ld	ra,24(sp)
    80002cc0:	6442                	ld	s0,16(sp)
    80002cc2:	6105                	addi	sp,sp,32
    80002cc4:	8082                	ret

0000000080002cc6 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cc6:	7179                	addi	sp,sp,-48
    80002cc8:	f406                	sd	ra,40(sp)
    80002cca:	f022                	sd	s0,32(sp)
    80002ccc:	ec26                	sd	s1,24(sp)
    80002cce:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cd0:	fdc40593          	addi	a1,s0,-36
    80002cd4:	4501                	li	a0,0
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	e78080e7          	jalr	-392(ra) # 80002b4e <argint>
    80002cde:	87aa                	mv	a5,a0
    return -1;
    80002ce0:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ce2:	0207c063          	bltz	a5,80002d02 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	d54080e7          	jalr	-684(ra) # 80001a3a <myproc>
    80002cee:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cf0:	fdc42503          	lw	a0,-36(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	092080e7          	jalr	146(ra) # 80001d86 <growproc>
    80002cfc:	00054863          	bltz	a0,80002d0c <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d00:	8526                	mv	a0,s1
}
    80002d02:	70a2                	ld	ra,40(sp)
    80002d04:	7402                	ld	s0,32(sp)
    80002d06:	64e2                	ld	s1,24(sp)
    80002d08:	6145                	addi	sp,sp,48
    80002d0a:	8082                	ret
    return -1;
    80002d0c:	557d                	li	a0,-1
    80002d0e:	bfd5                	j	80002d02 <sys_sbrk+0x3c>

0000000080002d10 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d10:	7139                	addi	sp,sp,-64
    80002d12:	fc06                	sd	ra,56(sp)
    80002d14:	f822                	sd	s0,48(sp)
    80002d16:	f426                	sd	s1,40(sp)
    80002d18:	f04a                	sd	s2,32(sp)
    80002d1a:	ec4e                	sd	s3,24(sp)
    80002d1c:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d1e:	fcc40593          	addi	a1,s0,-52
    80002d22:	4501                	li	a0,0
    80002d24:	00000097          	auipc	ra,0x0
    80002d28:	e2a080e7          	jalr	-470(ra) # 80002b4e <argint>
    return -1;
    80002d2c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d2e:	06054963          	bltz	a0,80002da0 <sys_sleep+0x90>
  acquire(&tickslock);
    80002d32:	00015517          	auipc	a0,0x15
    80002d36:	03650513          	addi	a0,a0,54 # 80017d68 <tickslock>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	f32080e7          	jalr	-206(ra) # 80000c6c <acquire>
  ticks0 = ticks;
    80002d42:	00006917          	auipc	s2,0x6
    80002d46:	2de92903          	lw	s2,734(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d4a:	fcc42783          	lw	a5,-52(s0)
    80002d4e:	cf85                	beqz	a5,80002d86 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d50:	00015997          	auipc	s3,0x15
    80002d54:	01898993          	addi	s3,s3,24 # 80017d68 <tickslock>
    80002d58:	00006497          	auipc	s1,0x6
    80002d5c:	2c848493          	addi	s1,s1,712 # 80009020 <ticks>
    if(myproc()->killed){
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	cda080e7          	jalr	-806(ra) # 80001a3a <myproc>
    80002d68:	591c                	lw	a5,48(a0)
    80002d6a:	e3b9                	bnez	a5,80002db0 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002d6c:	85ce                	mv	a1,s3
    80002d6e:	8526                	mv	a0,s1
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	4d6080e7          	jalr	1238(ra) # 80002246 <sleep>
  while(ticks - ticks0 < n){
    80002d78:	409c                	lw	a5,0(s1)
    80002d7a:	412787bb          	subw	a5,a5,s2
    80002d7e:	fcc42703          	lw	a4,-52(s0)
    80002d82:	fce7efe3          	bltu	a5,a4,80002d60 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d86:	00015517          	auipc	a0,0x15
    80002d8a:	fe250513          	addi	a0,a0,-30 # 80017d68 <tickslock>
    80002d8e:	ffffe097          	auipc	ra,0xffffe
    80002d92:	f92080e7          	jalr	-110(ra) # 80000d20 <release>
  backtrace();
    80002d96:	ffffe097          	auipc	ra,0xffffe
    80002d9a:	a14080e7          	jalr	-1516(ra) # 800007aa <backtrace>
  return 0;
    80002d9e:	4781                	li	a5,0
}
    80002da0:	853e                	mv	a0,a5
    80002da2:	70e2                	ld	ra,56(sp)
    80002da4:	7442                	ld	s0,48(sp)
    80002da6:	74a2                	ld	s1,40(sp)
    80002da8:	7902                	ld	s2,32(sp)
    80002daa:	69e2                	ld	s3,24(sp)
    80002dac:	6121                	addi	sp,sp,64
    80002dae:	8082                	ret
      release(&tickslock);
    80002db0:	00015517          	auipc	a0,0x15
    80002db4:	fb850513          	addi	a0,a0,-72 # 80017d68 <tickslock>
    80002db8:	ffffe097          	auipc	ra,0xffffe
    80002dbc:	f68080e7          	jalr	-152(ra) # 80000d20 <release>
      return -1;
    80002dc0:	57fd                	li	a5,-1
    80002dc2:	bff9                	j	80002da0 <sys_sleep+0x90>

0000000080002dc4 <sys_kill>:

uint64
sys_kill(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dcc:	fec40593          	addi	a1,s0,-20
    80002dd0:	4501                	li	a0,0
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	d7c080e7          	jalr	-644(ra) # 80002b4e <argint>
    80002dda:	87aa                	mv	a5,a0
    return -1;
    80002ddc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dde:	0007c863          	bltz	a5,80002dee <sys_kill+0x2a>
  return kill(pid);
    80002de2:	fec42503          	lw	a0,-20(s0)
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	650080e7          	jalr	1616(ra) # 80002436 <kill>
}
    80002dee:	60e2                	ld	ra,24(sp)
    80002df0:	6442                	ld	s0,16(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002df6:	1101                	addi	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	e426                	sd	s1,8(sp)
    80002dfe:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e00:	00015517          	auipc	a0,0x15
    80002e04:	f6850513          	addi	a0,a0,-152 # 80017d68 <tickslock>
    80002e08:	ffffe097          	auipc	ra,0xffffe
    80002e0c:	e64080e7          	jalr	-412(ra) # 80000c6c <acquire>
  xticks = ticks;
    80002e10:	00006497          	auipc	s1,0x6
    80002e14:	2104a483          	lw	s1,528(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e18:	00015517          	auipc	a0,0x15
    80002e1c:	f5050513          	addi	a0,a0,-176 # 80017d68 <tickslock>
    80002e20:	ffffe097          	auipc	ra,0xffffe
    80002e24:	f00080e7          	jalr	-256(ra) # 80000d20 <release>
  return xticks;
}
    80002e28:	02049513          	slli	a0,s1,0x20
    80002e2c:	9101                	srli	a0,a0,0x20
    80002e2e:	60e2                	ld	ra,24(sp)
    80002e30:	6442                	ld	s0,16(sp)
    80002e32:	64a2                	ld	s1,8(sp)
    80002e34:	6105                	addi	sp,sp,32
    80002e36:	8082                	ret

0000000080002e38 <sys_sigalarm>:

uint64 sys_sigalarm(void){
    80002e38:	1101                	addi	sp,sp,-32
    80002e3a:	ec06                	sd	ra,24(sp)
    80002e3c:	e822                	sd	s0,16(sp)
    80002e3e:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handler;
  if(argint(0, &ticks) < 0)
    80002e40:	fec40593          	addi	a1,s0,-20
    80002e44:	4501                	li	a0,0
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	d08080e7          	jalr	-760(ra) # 80002b4e <argint>
    return -1;
    80002e4e:	57fd                	li	a5,-1
  if(argint(0, &ticks) < 0)
    80002e50:	02054d63          	bltz	a0,80002e8a <sys_sigalarm+0x52>
  if(argaddr(1, &handler) < 0)
    80002e54:	fe040593          	addi	a1,s0,-32
    80002e58:	4505                	li	a0,1
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	d16080e7          	jalr	-746(ra) # 80002b70 <argaddr>
    return -1;
    80002e62:	57fd                	li	a5,-1
  if(argaddr(1, &handler) < 0)
    80002e64:	02054363          	bltz	a0,80002e8a <sys_sigalarm+0x52>
  
  struct proc* p = myproc();
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	bd2080e7          	jalr	-1070(ra) # 80001a3a <myproc>
  p->alarm = ticks;
    80002e70:	fec42783          	lw	a5,-20(s0)
    80002e74:	16f52423          	sw	a5,360(a0)
  p->handler = handler;
    80002e78:	fe043783          	ld	a5,-32(s0)
    80002e7c:	16f53823          	sd	a5,368(a0)
  p->duringtime = 0;
    80002e80:	16052623          	sw	zero,364(a0)
  p->alarmframe = 0;
    80002e84:	16053c23          	sd	zero,376(a0)
  return 0;
    80002e88:	4781                	li	a5,0
}
    80002e8a:	853e                	mv	a0,a5
    80002e8c:	60e2                	ld	ra,24(sp)
    80002e8e:	6442                	ld	s0,16(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	1000                	addi	s0,sp,32
  struct proc* p = myproc();
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	b9c080e7          	jalr	-1124(ra) # 80001a3a <myproc>
  if(p->alarmframe != 0){
    80002ea6:	17853583          	ld	a1,376(a0)
    80002eaa:	c18d                	beqz	a1,80002ecc <sys_sigreturn+0x38>
    80002eac:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarmframe, 512);
    80002eae:	20000613          	li	a2,512
    80002eb2:	6d28                	ld	a0,88(a0)
    80002eb4:	ffffe097          	auipc	ra,0xffffe
    80002eb8:	f14080e7          	jalr	-236(ra) # 80000dc8 <memmove>
    kfree(p->alarmframe);
    80002ebc:	1784b503          	ld	a0,376(s1)
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	bc0080e7          	jalr	-1088(ra) # 80000a80 <kfree>
    p->alarmframe = 0;
    80002ec8:	1604bc23          	sd	zero,376(s1)
  }
  return 0;
}
    80002ecc:	4501                	li	a0,0
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6105                	addi	sp,sp,32
    80002ed6:	8082                	ret

0000000080002ed8 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ed8:	7179                	addi	sp,sp,-48
    80002eda:	f406                	sd	ra,40(sp)
    80002edc:	f022                	sd	s0,32(sp)
    80002ede:	ec26                	sd	s1,24(sp)
    80002ee0:	e84a                	sd	s2,16(sp)
    80002ee2:	e44e                	sd	s3,8(sp)
    80002ee4:	e052                	sd	s4,0(sp)
    80002ee6:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ee8:	00005597          	auipc	a1,0x5
    80002eec:	61858593          	addi	a1,a1,1560 # 80008500 <syscalls+0xc0>
    80002ef0:	00015517          	auipc	a0,0x15
    80002ef4:	e9050513          	addi	a0,a0,-368 # 80017d80 <bcache>
    80002ef8:	ffffe097          	auipc	ra,0xffffe
    80002efc:	ce4080e7          	jalr	-796(ra) # 80000bdc <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f00:	0001d797          	auipc	a5,0x1d
    80002f04:	e8078793          	addi	a5,a5,-384 # 8001fd80 <bcache+0x8000>
    80002f08:	0001d717          	auipc	a4,0x1d
    80002f0c:	0e070713          	addi	a4,a4,224 # 8001ffe8 <bcache+0x8268>
    80002f10:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f14:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f18:	00015497          	auipc	s1,0x15
    80002f1c:	e8048493          	addi	s1,s1,-384 # 80017d98 <bcache+0x18>
    b->next = bcache.head.next;
    80002f20:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f22:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f24:	00005a17          	auipc	s4,0x5
    80002f28:	5e4a0a13          	addi	s4,s4,1508 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f2c:	2b893783          	ld	a5,696(s2)
    80002f30:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f32:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f36:	85d2                	mv	a1,s4
    80002f38:	01048513          	addi	a0,s1,16
    80002f3c:	00001097          	auipc	ra,0x1
    80002f40:	4ac080e7          	jalr	1196(ra) # 800043e8 <initsleeplock>
    bcache.head.next->prev = b;
    80002f44:	2b893783          	ld	a5,696(s2)
    80002f48:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f4a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f4e:	45848493          	addi	s1,s1,1112
    80002f52:	fd349de3          	bne	s1,s3,80002f2c <binit+0x54>
  }
}
    80002f56:	70a2                	ld	ra,40(sp)
    80002f58:	7402                	ld	s0,32(sp)
    80002f5a:	64e2                	ld	s1,24(sp)
    80002f5c:	6942                	ld	s2,16(sp)
    80002f5e:	69a2                	ld	s3,8(sp)
    80002f60:	6a02                	ld	s4,0(sp)
    80002f62:	6145                	addi	sp,sp,48
    80002f64:	8082                	ret

0000000080002f66 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f66:	7179                	addi	sp,sp,-48
    80002f68:	f406                	sd	ra,40(sp)
    80002f6a:	f022                	sd	s0,32(sp)
    80002f6c:	ec26                	sd	s1,24(sp)
    80002f6e:	e84a                	sd	s2,16(sp)
    80002f70:	e44e                	sd	s3,8(sp)
    80002f72:	1800                	addi	s0,sp,48
    80002f74:	89aa                	mv	s3,a0
    80002f76:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f78:	00015517          	auipc	a0,0x15
    80002f7c:	e0850513          	addi	a0,a0,-504 # 80017d80 <bcache>
    80002f80:	ffffe097          	auipc	ra,0xffffe
    80002f84:	cec080e7          	jalr	-788(ra) # 80000c6c <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f88:	0001d497          	auipc	s1,0x1d
    80002f8c:	0b04b483          	ld	s1,176(s1) # 80020038 <bcache+0x82b8>
    80002f90:	0001d797          	auipc	a5,0x1d
    80002f94:	05878793          	addi	a5,a5,88 # 8001ffe8 <bcache+0x8268>
    80002f98:	02f48f63          	beq	s1,a5,80002fd6 <bread+0x70>
    80002f9c:	873e                	mv	a4,a5
    80002f9e:	a021                	j	80002fa6 <bread+0x40>
    80002fa0:	68a4                	ld	s1,80(s1)
    80002fa2:	02e48a63          	beq	s1,a4,80002fd6 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fa6:	449c                	lw	a5,8(s1)
    80002fa8:	ff379ce3          	bne	a5,s3,80002fa0 <bread+0x3a>
    80002fac:	44dc                	lw	a5,12(s1)
    80002fae:	ff2799e3          	bne	a5,s2,80002fa0 <bread+0x3a>
      b->refcnt++;
    80002fb2:	40bc                	lw	a5,64(s1)
    80002fb4:	2785                	addiw	a5,a5,1
    80002fb6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fb8:	00015517          	auipc	a0,0x15
    80002fbc:	dc850513          	addi	a0,a0,-568 # 80017d80 <bcache>
    80002fc0:	ffffe097          	auipc	ra,0xffffe
    80002fc4:	d60080e7          	jalr	-672(ra) # 80000d20 <release>
      acquiresleep(&b->lock);
    80002fc8:	01048513          	addi	a0,s1,16
    80002fcc:	00001097          	auipc	ra,0x1
    80002fd0:	456080e7          	jalr	1110(ra) # 80004422 <acquiresleep>
      return b;
    80002fd4:	a8b9                	j	80003032 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd6:	0001d497          	auipc	s1,0x1d
    80002fda:	05a4b483          	ld	s1,90(s1) # 80020030 <bcache+0x82b0>
    80002fde:	0001d797          	auipc	a5,0x1d
    80002fe2:	00a78793          	addi	a5,a5,10 # 8001ffe8 <bcache+0x8268>
    80002fe6:	00f48863          	beq	s1,a5,80002ff6 <bread+0x90>
    80002fea:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fec:	40bc                	lw	a5,64(s1)
    80002fee:	cf81                	beqz	a5,80003006 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff0:	64a4                	ld	s1,72(s1)
    80002ff2:	fee49de3          	bne	s1,a4,80002fec <bread+0x86>
  panic("bget: no buffers");
    80002ff6:	00005517          	auipc	a0,0x5
    80002ffa:	51a50513          	addi	a0,a0,1306 # 80008510 <syscalls+0xd0>
    80002ffe:	ffffd097          	auipc	ra,0xffffd
    80003002:	54a080e7          	jalr	1354(ra) # 80000548 <panic>
      b->dev = dev;
    80003006:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000300a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000300e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003012:	4785                	li	a5,1
    80003014:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003016:	00015517          	auipc	a0,0x15
    8000301a:	d6a50513          	addi	a0,a0,-662 # 80017d80 <bcache>
    8000301e:	ffffe097          	auipc	ra,0xffffe
    80003022:	d02080e7          	jalr	-766(ra) # 80000d20 <release>
      acquiresleep(&b->lock);
    80003026:	01048513          	addi	a0,s1,16
    8000302a:	00001097          	auipc	ra,0x1
    8000302e:	3f8080e7          	jalr	1016(ra) # 80004422 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003032:	409c                	lw	a5,0(s1)
    80003034:	cb89                	beqz	a5,80003046 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003036:	8526                	mv	a0,s1
    80003038:	70a2                	ld	ra,40(sp)
    8000303a:	7402                	ld	s0,32(sp)
    8000303c:	64e2                	ld	s1,24(sp)
    8000303e:	6942                	ld	s2,16(sp)
    80003040:	69a2                	ld	s3,8(sp)
    80003042:	6145                	addi	sp,sp,48
    80003044:	8082                	ret
    virtio_disk_rw(b, 0);
    80003046:	4581                	li	a1,0
    80003048:	8526                	mv	a0,s1
    8000304a:	00003097          	auipc	ra,0x3
    8000304e:	f32080e7          	jalr	-206(ra) # 80005f7c <virtio_disk_rw>
    b->valid = 1;
    80003052:	4785                	li	a5,1
    80003054:	c09c                	sw	a5,0(s1)
  return b;
    80003056:	b7c5                	j	80003036 <bread+0xd0>

0000000080003058 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003058:	1101                	addi	sp,sp,-32
    8000305a:	ec06                	sd	ra,24(sp)
    8000305c:	e822                	sd	s0,16(sp)
    8000305e:	e426                	sd	s1,8(sp)
    80003060:	1000                	addi	s0,sp,32
    80003062:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003064:	0541                	addi	a0,a0,16
    80003066:	00001097          	auipc	ra,0x1
    8000306a:	456080e7          	jalr	1110(ra) # 800044bc <holdingsleep>
    8000306e:	cd01                	beqz	a0,80003086 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003070:	4585                	li	a1,1
    80003072:	8526                	mv	a0,s1
    80003074:	00003097          	auipc	ra,0x3
    80003078:	f08080e7          	jalr	-248(ra) # 80005f7c <virtio_disk_rw>
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6105                	addi	sp,sp,32
    80003084:	8082                	ret
    panic("bwrite");
    80003086:	00005517          	auipc	a0,0x5
    8000308a:	4a250513          	addi	a0,a0,1186 # 80008528 <syscalls+0xe8>
    8000308e:	ffffd097          	auipc	ra,0xffffd
    80003092:	4ba080e7          	jalr	1210(ra) # 80000548 <panic>

0000000080003096 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003096:	1101                	addi	sp,sp,-32
    80003098:	ec06                	sd	ra,24(sp)
    8000309a:	e822                	sd	s0,16(sp)
    8000309c:	e426                	sd	s1,8(sp)
    8000309e:	e04a                	sd	s2,0(sp)
    800030a0:	1000                	addi	s0,sp,32
    800030a2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a4:	01050913          	addi	s2,a0,16
    800030a8:	854a                	mv	a0,s2
    800030aa:	00001097          	auipc	ra,0x1
    800030ae:	412080e7          	jalr	1042(ra) # 800044bc <holdingsleep>
    800030b2:	c92d                	beqz	a0,80003124 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030b4:	854a                	mv	a0,s2
    800030b6:	00001097          	auipc	ra,0x1
    800030ba:	3c2080e7          	jalr	962(ra) # 80004478 <releasesleep>

  acquire(&bcache.lock);
    800030be:	00015517          	auipc	a0,0x15
    800030c2:	cc250513          	addi	a0,a0,-830 # 80017d80 <bcache>
    800030c6:	ffffe097          	auipc	ra,0xffffe
    800030ca:	ba6080e7          	jalr	-1114(ra) # 80000c6c <acquire>
  b->refcnt--;
    800030ce:	40bc                	lw	a5,64(s1)
    800030d0:	37fd                	addiw	a5,a5,-1
    800030d2:	0007871b          	sext.w	a4,a5
    800030d6:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030d8:	eb05                	bnez	a4,80003108 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030da:	68bc                	ld	a5,80(s1)
    800030dc:	64b8                	ld	a4,72(s1)
    800030de:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030e0:	64bc                	ld	a5,72(s1)
    800030e2:	68b8                	ld	a4,80(s1)
    800030e4:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030e6:	0001d797          	auipc	a5,0x1d
    800030ea:	c9a78793          	addi	a5,a5,-870 # 8001fd80 <bcache+0x8000>
    800030ee:	2b87b703          	ld	a4,696(a5)
    800030f2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030f4:	0001d717          	auipc	a4,0x1d
    800030f8:	ef470713          	addi	a4,a4,-268 # 8001ffe8 <bcache+0x8268>
    800030fc:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030fe:	2b87b703          	ld	a4,696(a5)
    80003102:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003104:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003108:	00015517          	auipc	a0,0x15
    8000310c:	c7850513          	addi	a0,a0,-904 # 80017d80 <bcache>
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	c10080e7          	jalr	-1008(ra) # 80000d20 <release>
}
    80003118:	60e2                	ld	ra,24(sp)
    8000311a:	6442                	ld	s0,16(sp)
    8000311c:	64a2                	ld	s1,8(sp)
    8000311e:	6902                	ld	s2,0(sp)
    80003120:	6105                	addi	sp,sp,32
    80003122:	8082                	ret
    panic("brelse");
    80003124:	00005517          	auipc	a0,0x5
    80003128:	40c50513          	addi	a0,a0,1036 # 80008530 <syscalls+0xf0>
    8000312c:	ffffd097          	auipc	ra,0xffffd
    80003130:	41c080e7          	jalr	1052(ra) # 80000548 <panic>

0000000080003134 <bpin>:

void
bpin(struct buf *b) {
    80003134:	1101                	addi	sp,sp,-32
    80003136:	ec06                	sd	ra,24(sp)
    80003138:	e822                	sd	s0,16(sp)
    8000313a:	e426                	sd	s1,8(sp)
    8000313c:	1000                	addi	s0,sp,32
    8000313e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003140:	00015517          	auipc	a0,0x15
    80003144:	c4050513          	addi	a0,a0,-960 # 80017d80 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	b24080e7          	jalr	-1244(ra) # 80000c6c <acquire>
  b->refcnt++;
    80003150:	40bc                	lw	a5,64(s1)
    80003152:	2785                	addiw	a5,a5,1
    80003154:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003156:	00015517          	auipc	a0,0x15
    8000315a:	c2a50513          	addi	a0,a0,-982 # 80017d80 <bcache>
    8000315e:	ffffe097          	auipc	ra,0xffffe
    80003162:	bc2080e7          	jalr	-1086(ra) # 80000d20 <release>
}
    80003166:	60e2                	ld	ra,24(sp)
    80003168:	6442                	ld	s0,16(sp)
    8000316a:	64a2                	ld	s1,8(sp)
    8000316c:	6105                	addi	sp,sp,32
    8000316e:	8082                	ret

0000000080003170 <bunpin>:

void
bunpin(struct buf *b) {
    80003170:	1101                	addi	sp,sp,-32
    80003172:	ec06                	sd	ra,24(sp)
    80003174:	e822                	sd	s0,16(sp)
    80003176:	e426                	sd	s1,8(sp)
    80003178:	1000                	addi	s0,sp,32
    8000317a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317c:	00015517          	auipc	a0,0x15
    80003180:	c0450513          	addi	a0,a0,-1020 # 80017d80 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	ae8080e7          	jalr	-1304(ra) # 80000c6c <acquire>
  b->refcnt--;
    8000318c:	40bc                	lw	a5,64(s1)
    8000318e:	37fd                	addiw	a5,a5,-1
    80003190:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003192:	00015517          	auipc	a0,0x15
    80003196:	bee50513          	addi	a0,a0,-1042 # 80017d80 <bcache>
    8000319a:	ffffe097          	auipc	ra,0xffffe
    8000319e:	b86080e7          	jalr	-1146(ra) # 80000d20 <release>
}
    800031a2:	60e2                	ld	ra,24(sp)
    800031a4:	6442                	ld	s0,16(sp)
    800031a6:	64a2                	ld	s1,8(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ac:	1101                	addi	sp,sp,-32
    800031ae:	ec06                	sd	ra,24(sp)
    800031b0:	e822                	sd	s0,16(sp)
    800031b2:	e426                	sd	s1,8(sp)
    800031b4:	e04a                	sd	s2,0(sp)
    800031b6:	1000                	addi	s0,sp,32
    800031b8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ba:	00d5d59b          	srliw	a1,a1,0xd
    800031be:	0001d797          	auipc	a5,0x1d
    800031c2:	29e7a783          	lw	a5,670(a5) # 8002045c <sb+0x1c>
    800031c6:	9dbd                	addw	a1,a1,a5
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	d9e080e7          	jalr	-610(ra) # 80002f66 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031d0:	0074f713          	andi	a4,s1,7
    800031d4:	4785                	li	a5,1
    800031d6:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031da:	14ce                	slli	s1,s1,0x33
    800031dc:	90d9                	srli	s1,s1,0x36
    800031de:	00950733          	add	a4,a0,s1
    800031e2:	05874703          	lbu	a4,88(a4)
    800031e6:	00e7f6b3          	and	a3,a5,a4
    800031ea:	c69d                	beqz	a3,80003218 <bfree+0x6c>
    800031ec:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031ee:	94aa                	add	s1,s1,a0
    800031f0:	fff7c793          	not	a5,a5
    800031f4:	8ff9                	and	a5,a5,a4
    800031f6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031fa:	00001097          	auipc	ra,0x1
    800031fe:	100080e7          	jalr	256(ra) # 800042fa <log_write>
  brelse(bp);
    80003202:	854a                	mv	a0,s2
    80003204:	00000097          	auipc	ra,0x0
    80003208:	e92080e7          	jalr	-366(ra) # 80003096 <brelse>
}
    8000320c:	60e2                	ld	ra,24(sp)
    8000320e:	6442                	ld	s0,16(sp)
    80003210:	64a2                	ld	s1,8(sp)
    80003212:	6902                	ld	s2,0(sp)
    80003214:	6105                	addi	sp,sp,32
    80003216:	8082                	ret
    panic("freeing free block");
    80003218:	00005517          	auipc	a0,0x5
    8000321c:	32050513          	addi	a0,a0,800 # 80008538 <syscalls+0xf8>
    80003220:	ffffd097          	auipc	ra,0xffffd
    80003224:	328080e7          	jalr	808(ra) # 80000548 <panic>

0000000080003228 <balloc>:
{
    80003228:	711d                	addi	sp,sp,-96
    8000322a:	ec86                	sd	ra,88(sp)
    8000322c:	e8a2                	sd	s0,80(sp)
    8000322e:	e4a6                	sd	s1,72(sp)
    80003230:	e0ca                	sd	s2,64(sp)
    80003232:	fc4e                	sd	s3,56(sp)
    80003234:	f852                	sd	s4,48(sp)
    80003236:	f456                	sd	s5,40(sp)
    80003238:	f05a                	sd	s6,32(sp)
    8000323a:	ec5e                	sd	s7,24(sp)
    8000323c:	e862                	sd	s8,16(sp)
    8000323e:	e466                	sd	s9,8(sp)
    80003240:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003242:	0001d797          	auipc	a5,0x1d
    80003246:	2027a783          	lw	a5,514(a5) # 80020444 <sb+0x4>
    8000324a:	cbd1                	beqz	a5,800032de <balloc+0xb6>
    8000324c:	8baa                	mv	s7,a0
    8000324e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003250:	0001db17          	auipc	s6,0x1d
    80003254:	1f0b0b13          	addi	s6,s6,496 # 80020440 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003258:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000325a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000325e:	6c89                	lui	s9,0x2
    80003260:	a831                	j	8000327c <balloc+0x54>
    brelse(bp);
    80003262:	854a                	mv	a0,s2
    80003264:	00000097          	auipc	ra,0x0
    80003268:	e32080e7          	jalr	-462(ra) # 80003096 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000326c:	015c87bb          	addw	a5,s9,s5
    80003270:	00078a9b          	sext.w	s5,a5
    80003274:	004b2703          	lw	a4,4(s6)
    80003278:	06eaf363          	bgeu	s5,a4,800032de <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    8000327c:	41fad79b          	sraiw	a5,s5,0x1f
    80003280:	0137d79b          	srliw	a5,a5,0x13
    80003284:	015787bb          	addw	a5,a5,s5
    80003288:	40d7d79b          	sraiw	a5,a5,0xd
    8000328c:	01cb2583          	lw	a1,28(s6)
    80003290:	9dbd                	addw	a1,a1,a5
    80003292:	855e                	mv	a0,s7
    80003294:	00000097          	auipc	ra,0x0
    80003298:	cd2080e7          	jalr	-814(ra) # 80002f66 <bread>
    8000329c:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000329e:	004b2503          	lw	a0,4(s6)
    800032a2:	000a849b          	sext.w	s1,s5
    800032a6:	8662                	mv	a2,s8
    800032a8:	faa4fde3          	bgeu	s1,a0,80003262 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032ac:	41f6579b          	sraiw	a5,a2,0x1f
    800032b0:	01d7d69b          	srliw	a3,a5,0x1d
    800032b4:	00c6873b          	addw	a4,a3,a2
    800032b8:	00777793          	andi	a5,a4,7
    800032bc:	9f95                	subw	a5,a5,a3
    800032be:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032c2:	4037571b          	sraiw	a4,a4,0x3
    800032c6:	00e906b3          	add	a3,s2,a4
    800032ca:	0586c683          	lbu	a3,88(a3)
    800032ce:	00d7f5b3          	and	a1,a5,a3
    800032d2:	cd91                	beqz	a1,800032ee <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032d4:	2605                	addiw	a2,a2,1
    800032d6:	2485                	addiw	s1,s1,1
    800032d8:	fd4618e3          	bne	a2,s4,800032a8 <balloc+0x80>
    800032dc:	b759                	j	80003262 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032de:	00005517          	auipc	a0,0x5
    800032e2:	27250513          	addi	a0,a0,626 # 80008550 <syscalls+0x110>
    800032e6:	ffffd097          	auipc	ra,0xffffd
    800032ea:	262080e7          	jalr	610(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032ee:	974a                	add	a4,a4,s2
    800032f0:	8fd5                	or	a5,a5,a3
    800032f2:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032f6:	854a                	mv	a0,s2
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	002080e7          	jalr	2(ra) # 800042fa <log_write>
        brelse(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00000097          	auipc	ra,0x0
    80003306:	d94080e7          	jalr	-620(ra) # 80003096 <brelse>
  bp = bread(dev, bno);
    8000330a:	85a6                	mv	a1,s1
    8000330c:	855e                	mv	a0,s7
    8000330e:	00000097          	auipc	ra,0x0
    80003312:	c58080e7          	jalr	-936(ra) # 80002f66 <bread>
    80003316:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003318:	40000613          	li	a2,1024
    8000331c:	4581                	li	a1,0
    8000331e:	05850513          	addi	a0,a0,88
    80003322:	ffffe097          	auipc	ra,0xffffe
    80003326:	a46080e7          	jalr	-1466(ra) # 80000d68 <memset>
  log_write(bp);
    8000332a:	854a                	mv	a0,s2
    8000332c:	00001097          	auipc	ra,0x1
    80003330:	fce080e7          	jalr	-50(ra) # 800042fa <log_write>
  brelse(bp);
    80003334:	854a                	mv	a0,s2
    80003336:	00000097          	auipc	ra,0x0
    8000333a:	d60080e7          	jalr	-672(ra) # 80003096 <brelse>
}
    8000333e:	8526                	mv	a0,s1
    80003340:	60e6                	ld	ra,88(sp)
    80003342:	6446                	ld	s0,80(sp)
    80003344:	64a6                	ld	s1,72(sp)
    80003346:	6906                	ld	s2,64(sp)
    80003348:	79e2                	ld	s3,56(sp)
    8000334a:	7a42                	ld	s4,48(sp)
    8000334c:	7aa2                	ld	s5,40(sp)
    8000334e:	7b02                	ld	s6,32(sp)
    80003350:	6be2                	ld	s7,24(sp)
    80003352:	6c42                	ld	s8,16(sp)
    80003354:	6ca2                	ld	s9,8(sp)
    80003356:	6125                	addi	sp,sp,96
    80003358:	8082                	ret

000000008000335a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000335a:	7179                	addi	sp,sp,-48
    8000335c:	f406                	sd	ra,40(sp)
    8000335e:	f022                	sd	s0,32(sp)
    80003360:	ec26                	sd	s1,24(sp)
    80003362:	e84a                	sd	s2,16(sp)
    80003364:	e44e                	sd	s3,8(sp)
    80003366:	e052                	sd	s4,0(sp)
    80003368:	1800                	addi	s0,sp,48
    8000336a:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000336c:	47ad                	li	a5,11
    8000336e:	04b7fe63          	bgeu	a5,a1,800033ca <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003372:	ff45849b          	addiw	s1,a1,-12
    80003376:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000337a:	0ff00793          	li	a5,255
    8000337e:	0ae7e363          	bltu	a5,a4,80003424 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003382:	08052583          	lw	a1,128(a0)
    80003386:	c5ad                	beqz	a1,800033f0 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003388:	00092503          	lw	a0,0(s2)
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	bda080e7          	jalr	-1062(ra) # 80002f66 <bread>
    80003394:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003396:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000339a:	02049593          	slli	a1,s1,0x20
    8000339e:	9181                	srli	a1,a1,0x20
    800033a0:	058a                	slli	a1,a1,0x2
    800033a2:	00b784b3          	add	s1,a5,a1
    800033a6:	0004a983          	lw	s3,0(s1)
    800033aa:	04098d63          	beqz	s3,80003404 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033ae:	8552                	mv	a0,s4
    800033b0:	00000097          	auipc	ra,0x0
    800033b4:	ce6080e7          	jalr	-794(ra) # 80003096 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033b8:	854e                	mv	a0,s3
    800033ba:	70a2                	ld	ra,40(sp)
    800033bc:	7402                	ld	s0,32(sp)
    800033be:	64e2                	ld	s1,24(sp)
    800033c0:	6942                	ld	s2,16(sp)
    800033c2:	69a2                	ld	s3,8(sp)
    800033c4:	6a02                	ld	s4,0(sp)
    800033c6:	6145                	addi	sp,sp,48
    800033c8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033ca:	02059493          	slli	s1,a1,0x20
    800033ce:	9081                	srli	s1,s1,0x20
    800033d0:	048a                	slli	s1,s1,0x2
    800033d2:	94aa                	add	s1,s1,a0
    800033d4:	0504a983          	lw	s3,80(s1)
    800033d8:	fe0990e3          	bnez	s3,800033b8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033dc:	4108                	lw	a0,0(a0)
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	e4a080e7          	jalr	-438(ra) # 80003228 <balloc>
    800033e6:	0005099b          	sext.w	s3,a0
    800033ea:	0534a823          	sw	s3,80(s1)
    800033ee:	b7e9                	j	800033b8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033f0:	4108                	lw	a0,0(a0)
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	e36080e7          	jalr	-458(ra) # 80003228 <balloc>
    800033fa:	0005059b          	sext.w	a1,a0
    800033fe:	08b92023          	sw	a1,128(s2)
    80003402:	b759                	j	80003388 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003404:	00092503          	lw	a0,0(s2)
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	e20080e7          	jalr	-480(ra) # 80003228 <balloc>
    80003410:	0005099b          	sext.w	s3,a0
    80003414:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003418:	8552                	mv	a0,s4
    8000341a:	00001097          	auipc	ra,0x1
    8000341e:	ee0080e7          	jalr	-288(ra) # 800042fa <log_write>
    80003422:	b771                	j	800033ae <bmap+0x54>
  panic("bmap: out of range");
    80003424:	00005517          	auipc	a0,0x5
    80003428:	14450513          	addi	a0,a0,324 # 80008568 <syscalls+0x128>
    8000342c:	ffffd097          	auipc	ra,0xffffd
    80003430:	11c080e7          	jalr	284(ra) # 80000548 <panic>

0000000080003434 <iget>:
{
    80003434:	7179                	addi	sp,sp,-48
    80003436:	f406                	sd	ra,40(sp)
    80003438:	f022                	sd	s0,32(sp)
    8000343a:	ec26                	sd	s1,24(sp)
    8000343c:	e84a                	sd	s2,16(sp)
    8000343e:	e44e                	sd	s3,8(sp)
    80003440:	e052                	sd	s4,0(sp)
    80003442:	1800                	addi	s0,sp,48
    80003444:	89aa                	mv	s3,a0
    80003446:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003448:	0001d517          	auipc	a0,0x1d
    8000344c:	01850513          	addi	a0,a0,24 # 80020460 <icache>
    80003450:	ffffe097          	auipc	ra,0xffffe
    80003454:	81c080e7          	jalr	-2020(ra) # 80000c6c <acquire>
  empty = 0;
    80003458:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000345a:	0001d497          	auipc	s1,0x1d
    8000345e:	01e48493          	addi	s1,s1,30 # 80020478 <icache+0x18>
    80003462:	0001f697          	auipc	a3,0x1f
    80003466:	aa668693          	addi	a3,a3,-1370 # 80021f08 <log>
    8000346a:	a039                	j	80003478 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000346c:	02090b63          	beqz	s2,800034a2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003470:	08848493          	addi	s1,s1,136
    80003474:	02d48a63          	beq	s1,a3,800034a8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003478:	449c                	lw	a5,8(s1)
    8000347a:	fef059e3          	blez	a5,8000346c <iget+0x38>
    8000347e:	4098                	lw	a4,0(s1)
    80003480:	ff3716e3          	bne	a4,s3,8000346c <iget+0x38>
    80003484:	40d8                	lw	a4,4(s1)
    80003486:	ff4713e3          	bne	a4,s4,8000346c <iget+0x38>
      ip->ref++;
    8000348a:	2785                	addiw	a5,a5,1
    8000348c:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000348e:	0001d517          	auipc	a0,0x1d
    80003492:	fd250513          	addi	a0,a0,-46 # 80020460 <icache>
    80003496:	ffffe097          	auipc	ra,0xffffe
    8000349a:	88a080e7          	jalr	-1910(ra) # 80000d20 <release>
      return ip;
    8000349e:	8926                	mv	s2,s1
    800034a0:	a03d                	j	800034ce <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a2:	f7f9                	bnez	a5,80003470 <iget+0x3c>
    800034a4:	8926                	mv	s2,s1
    800034a6:	b7e9                	j	80003470 <iget+0x3c>
  if(empty == 0)
    800034a8:	02090c63          	beqz	s2,800034e0 <iget+0xac>
  ip->dev = dev;
    800034ac:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034b0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034b4:	4785                	li	a5,1
    800034b6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ba:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034be:	0001d517          	auipc	a0,0x1d
    800034c2:	fa250513          	addi	a0,a0,-94 # 80020460 <icache>
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	85a080e7          	jalr	-1958(ra) # 80000d20 <release>
}
    800034ce:	854a                	mv	a0,s2
    800034d0:	70a2                	ld	ra,40(sp)
    800034d2:	7402                	ld	s0,32(sp)
    800034d4:	64e2                	ld	s1,24(sp)
    800034d6:	6942                	ld	s2,16(sp)
    800034d8:	69a2                	ld	s3,8(sp)
    800034da:	6a02                	ld	s4,0(sp)
    800034dc:	6145                	addi	sp,sp,48
    800034de:	8082                	ret
    panic("iget: no inodes");
    800034e0:	00005517          	auipc	a0,0x5
    800034e4:	0a050513          	addi	a0,a0,160 # 80008580 <syscalls+0x140>
    800034e8:	ffffd097          	auipc	ra,0xffffd
    800034ec:	060080e7          	jalr	96(ra) # 80000548 <panic>

00000000800034f0 <fsinit>:
fsinit(int dev) {
    800034f0:	7179                	addi	sp,sp,-48
    800034f2:	f406                	sd	ra,40(sp)
    800034f4:	f022                	sd	s0,32(sp)
    800034f6:	ec26                	sd	s1,24(sp)
    800034f8:	e84a                	sd	s2,16(sp)
    800034fa:	e44e                	sd	s3,8(sp)
    800034fc:	1800                	addi	s0,sp,48
    800034fe:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003500:	4585                	li	a1,1
    80003502:	00000097          	auipc	ra,0x0
    80003506:	a64080e7          	jalr	-1436(ra) # 80002f66 <bread>
    8000350a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000350c:	0001d997          	auipc	s3,0x1d
    80003510:	f3498993          	addi	s3,s3,-204 # 80020440 <sb>
    80003514:	02000613          	li	a2,32
    80003518:	05850593          	addi	a1,a0,88
    8000351c:	854e                	mv	a0,s3
    8000351e:	ffffe097          	auipc	ra,0xffffe
    80003522:	8aa080e7          	jalr	-1878(ra) # 80000dc8 <memmove>
  brelse(bp);
    80003526:	8526                	mv	a0,s1
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	b6e080e7          	jalr	-1170(ra) # 80003096 <brelse>
  if(sb.magic != FSMAGIC)
    80003530:	0009a703          	lw	a4,0(s3)
    80003534:	102037b7          	lui	a5,0x10203
    80003538:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000353c:	02f71263          	bne	a4,a5,80003560 <fsinit+0x70>
  initlog(dev, &sb);
    80003540:	0001d597          	auipc	a1,0x1d
    80003544:	f0058593          	addi	a1,a1,-256 # 80020440 <sb>
    80003548:	854a                	mv	a0,s2
    8000354a:	00001097          	auipc	ra,0x1
    8000354e:	b38080e7          	jalr	-1224(ra) # 80004082 <initlog>
}
    80003552:	70a2                	ld	ra,40(sp)
    80003554:	7402                	ld	s0,32(sp)
    80003556:	64e2                	ld	s1,24(sp)
    80003558:	6942                	ld	s2,16(sp)
    8000355a:	69a2                	ld	s3,8(sp)
    8000355c:	6145                	addi	sp,sp,48
    8000355e:	8082                	ret
    panic("invalid file system");
    80003560:	00005517          	auipc	a0,0x5
    80003564:	03050513          	addi	a0,a0,48 # 80008590 <syscalls+0x150>
    80003568:	ffffd097          	auipc	ra,0xffffd
    8000356c:	fe0080e7          	jalr	-32(ra) # 80000548 <panic>

0000000080003570 <iinit>:
{
    80003570:	7179                	addi	sp,sp,-48
    80003572:	f406                	sd	ra,40(sp)
    80003574:	f022                	sd	s0,32(sp)
    80003576:	ec26                	sd	s1,24(sp)
    80003578:	e84a                	sd	s2,16(sp)
    8000357a:	e44e                	sd	s3,8(sp)
    8000357c:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000357e:	00005597          	auipc	a1,0x5
    80003582:	02a58593          	addi	a1,a1,42 # 800085a8 <syscalls+0x168>
    80003586:	0001d517          	auipc	a0,0x1d
    8000358a:	eda50513          	addi	a0,a0,-294 # 80020460 <icache>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	64e080e7          	jalr	1614(ra) # 80000bdc <initlock>
  for(i = 0; i < NINODE; i++) {
    80003596:	0001d497          	auipc	s1,0x1d
    8000359a:	ef248493          	addi	s1,s1,-270 # 80020488 <icache+0x28>
    8000359e:	0001f997          	auipc	s3,0x1f
    800035a2:	97a98993          	addi	s3,s3,-1670 # 80021f18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035a6:	00005917          	auipc	s2,0x5
    800035aa:	00a90913          	addi	s2,s2,10 # 800085b0 <syscalls+0x170>
    800035ae:	85ca                	mv	a1,s2
    800035b0:	8526                	mv	a0,s1
    800035b2:	00001097          	auipc	ra,0x1
    800035b6:	e36080e7          	jalr	-458(ra) # 800043e8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ba:	08848493          	addi	s1,s1,136
    800035be:	ff3498e3          	bne	s1,s3,800035ae <iinit+0x3e>
}
    800035c2:	70a2                	ld	ra,40(sp)
    800035c4:	7402                	ld	s0,32(sp)
    800035c6:	64e2                	ld	s1,24(sp)
    800035c8:	6942                	ld	s2,16(sp)
    800035ca:	69a2                	ld	s3,8(sp)
    800035cc:	6145                	addi	sp,sp,48
    800035ce:	8082                	ret

00000000800035d0 <ialloc>:
{
    800035d0:	715d                	addi	sp,sp,-80
    800035d2:	e486                	sd	ra,72(sp)
    800035d4:	e0a2                	sd	s0,64(sp)
    800035d6:	fc26                	sd	s1,56(sp)
    800035d8:	f84a                	sd	s2,48(sp)
    800035da:	f44e                	sd	s3,40(sp)
    800035dc:	f052                	sd	s4,32(sp)
    800035de:	ec56                	sd	s5,24(sp)
    800035e0:	e85a                	sd	s6,16(sp)
    800035e2:	e45e                	sd	s7,8(sp)
    800035e4:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035e6:	0001d717          	auipc	a4,0x1d
    800035ea:	e6672703          	lw	a4,-410(a4) # 8002044c <sb+0xc>
    800035ee:	4785                	li	a5,1
    800035f0:	04e7fa63          	bgeu	a5,a4,80003644 <ialloc+0x74>
    800035f4:	8aaa                	mv	s5,a0
    800035f6:	8bae                	mv	s7,a1
    800035f8:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035fa:	0001da17          	auipc	s4,0x1d
    800035fe:	e46a0a13          	addi	s4,s4,-442 # 80020440 <sb>
    80003602:	00048b1b          	sext.w	s6,s1
    80003606:	0044d593          	srli	a1,s1,0x4
    8000360a:	018a2783          	lw	a5,24(s4)
    8000360e:	9dbd                	addw	a1,a1,a5
    80003610:	8556                	mv	a0,s5
    80003612:	00000097          	auipc	ra,0x0
    80003616:	954080e7          	jalr	-1708(ra) # 80002f66 <bread>
    8000361a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000361c:	05850993          	addi	s3,a0,88
    80003620:	00f4f793          	andi	a5,s1,15
    80003624:	079a                	slli	a5,a5,0x6
    80003626:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003628:	00099783          	lh	a5,0(s3)
    8000362c:	c785                	beqz	a5,80003654 <ialloc+0x84>
    brelse(bp);
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	a68080e7          	jalr	-1432(ra) # 80003096 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003636:	0485                	addi	s1,s1,1
    80003638:	00ca2703          	lw	a4,12(s4)
    8000363c:	0004879b          	sext.w	a5,s1
    80003640:	fce7e1e3          	bltu	a5,a4,80003602 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003644:	00005517          	auipc	a0,0x5
    80003648:	f7450513          	addi	a0,a0,-140 # 800085b8 <syscalls+0x178>
    8000364c:	ffffd097          	auipc	ra,0xffffd
    80003650:	efc080e7          	jalr	-260(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003654:	04000613          	li	a2,64
    80003658:	4581                	li	a1,0
    8000365a:	854e                	mv	a0,s3
    8000365c:	ffffd097          	auipc	ra,0xffffd
    80003660:	70c080e7          	jalr	1804(ra) # 80000d68 <memset>
      dip->type = type;
    80003664:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003668:	854a                	mv	a0,s2
    8000366a:	00001097          	auipc	ra,0x1
    8000366e:	c90080e7          	jalr	-880(ra) # 800042fa <log_write>
      brelse(bp);
    80003672:	854a                	mv	a0,s2
    80003674:	00000097          	auipc	ra,0x0
    80003678:	a22080e7          	jalr	-1502(ra) # 80003096 <brelse>
      return iget(dev, inum);
    8000367c:	85da                	mv	a1,s6
    8000367e:	8556                	mv	a0,s5
    80003680:	00000097          	auipc	ra,0x0
    80003684:	db4080e7          	jalr	-588(ra) # 80003434 <iget>
}
    80003688:	60a6                	ld	ra,72(sp)
    8000368a:	6406                	ld	s0,64(sp)
    8000368c:	74e2                	ld	s1,56(sp)
    8000368e:	7942                	ld	s2,48(sp)
    80003690:	79a2                	ld	s3,40(sp)
    80003692:	7a02                	ld	s4,32(sp)
    80003694:	6ae2                	ld	s5,24(sp)
    80003696:	6b42                	ld	s6,16(sp)
    80003698:	6ba2                	ld	s7,8(sp)
    8000369a:	6161                	addi	sp,sp,80
    8000369c:	8082                	ret

000000008000369e <iupdate>:
{
    8000369e:	1101                	addi	sp,sp,-32
    800036a0:	ec06                	sd	ra,24(sp)
    800036a2:	e822                	sd	s0,16(sp)
    800036a4:	e426                	sd	s1,8(sp)
    800036a6:	e04a                	sd	s2,0(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036ac:	415c                	lw	a5,4(a0)
    800036ae:	0047d79b          	srliw	a5,a5,0x4
    800036b2:	0001d597          	auipc	a1,0x1d
    800036b6:	da65a583          	lw	a1,-602(a1) # 80020458 <sb+0x18>
    800036ba:	9dbd                	addw	a1,a1,a5
    800036bc:	4108                	lw	a0,0(a0)
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	8a8080e7          	jalr	-1880(ra) # 80002f66 <bread>
    800036c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036c8:	05850793          	addi	a5,a0,88
    800036cc:	40c8                	lw	a0,4(s1)
    800036ce:	893d                	andi	a0,a0,15
    800036d0:	051a                	slli	a0,a0,0x6
    800036d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036d4:	04449703          	lh	a4,68(s1)
    800036d8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036dc:	04649703          	lh	a4,70(s1)
    800036e0:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036e4:	04849703          	lh	a4,72(s1)
    800036e8:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036ec:	04a49703          	lh	a4,74(s1)
    800036f0:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036f4:	44f8                	lw	a4,76(s1)
    800036f6:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036f8:	03400613          	li	a2,52
    800036fc:	05048593          	addi	a1,s1,80
    80003700:	0531                	addi	a0,a0,12
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	6c6080e7          	jalr	1734(ra) # 80000dc8 <memmove>
  log_write(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	bee080e7          	jalr	-1042(ra) # 800042fa <log_write>
  brelse(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	980080e7          	jalr	-1664(ra) # 80003096 <brelse>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret

000000008000372a <idup>:
{
    8000372a:	1101                	addi	sp,sp,-32
    8000372c:	ec06                	sd	ra,24(sp)
    8000372e:	e822                	sd	s0,16(sp)
    80003730:	e426                	sd	s1,8(sp)
    80003732:	1000                	addi	s0,sp,32
    80003734:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003736:	0001d517          	auipc	a0,0x1d
    8000373a:	d2a50513          	addi	a0,a0,-726 # 80020460 <icache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	52e080e7          	jalr	1326(ra) # 80000c6c <acquire>
  ip->ref++;
    80003746:	449c                	lw	a5,8(s1)
    80003748:	2785                	addiw	a5,a5,1
    8000374a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000374c:	0001d517          	auipc	a0,0x1d
    80003750:	d1450513          	addi	a0,a0,-748 # 80020460 <icache>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	5cc080e7          	jalr	1484(ra) # 80000d20 <release>
}
    8000375c:	8526                	mv	a0,s1
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <ilock>:
{
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	e04a                	sd	s2,0(sp)
    80003772:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003774:	c115                	beqz	a0,80003798 <ilock+0x30>
    80003776:	84aa                	mv	s1,a0
    80003778:	451c                	lw	a5,8(a0)
    8000377a:	00f05f63          	blez	a5,80003798 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000377e:	0541                	addi	a0,a0,16
    80003780:	00001097          	auipc	ra,0x1
    80003784:	ca2080e7          	jalr	-862(ra) # 80004422 <acquiresleep>
  if(ip->valid == 0){
    80003788:	40bc                	lw	a5,64(s1)
    8000378a:	cf99                	beqz	a5,800037a8 <ilock+0x40>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
    panic("ilock");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	e3850513          	addi	a0,a0,-456 # 800085d0 <syscalls+0x190>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	da8080e7          	jalr	-600(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a8:	40dc                	lw	a5,4(s1)
    800037aa:	0047d79b          	srliw	a5,a5,0x4
    800037ae:	0001d597          	auipc	a1,0x1d
    800037b2:	caa5a583          	lw	a1,-854(a1) # 80020458 <sb+0x18>
    800037b6:	9dbd                	addw	a1,a1,a5
    800037b8:	4088                	lw	a0,0(s1)
    800037ba:	fffff097          	auipc	ra,0xfffff
    800037be:	7ac080e7          	jalr	1964(ra) # 80002f66 <bread>
    800037c2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037c4:	05850593          	addi	a1,a0,88
    800037c8:	40dc                	lw	a5,4(s1)
    800037ca:	8bbd                	andi	a5,a5,15
    800037cc:	079a                	slli	a5,a5,0x6
    800037ce:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037d0:	00059783          	lh	a5,0(a1)
    800037d4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037d8:	00259783          	lh	a5,2(a1)
    800037dc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037e0:	00459783          	lh	a5,4(a1)
    800037e4:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037e8:	00659783          	lh	a5,6(a1)
    800037ec:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037f0:	459c                	lw	a5,8(a1)
    800037f2:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037f4:	03400613          	li	a2,52
    800037f8:	05b1                	addi	a1,a1,12
    800037fa:	05048513          	addi	a0,s1,80
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	5ca080e7          	jalr	1482(ra) # 80000dc8 <memmove>
    brelse(bp);
    80003806:	854a                	mv	a0,s2
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	88e080e7          	jalr	-1906(ra) # 80003096 <brelse>
    ip->valid = 1;
    80003810:	4785                	li	a5,1
    80003812:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003814:	04449783          	lh	a5,68(s1)
    80003818:	fbb5                	bnez	a5,8000378c <ilock+0x24>
      panic("ilock: no type");
    8000381a:	00005517          	auipc	a0,0x5
    8000381e:	dbe50513          	addi	a0,a0,-578 # 800085d8 <syscalls+0x198>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d26080e7          	jalr	-730(ra) # 80000548 <panic>

000000008000382a <iunlock>:
{
    8000382a:	1101                	addi	sp,sp,-32
    8000382c:	ec06                	sd	ra,24(sp)
    8000382e:	e822                	sd	s0,16(sp)
    80003830:	e426                	sd	s1,8(sp)
    80003832:	e04a                	sd	s2,0(sp)
    80003834:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003836:	c905                	beqz	a0,80003866 <iunlock+0x3c>
    80003838:	84aa                	mv	s1,a0
    8000383a:	01050913          	addi	s2,a0,16
    8000383e:	854a                	mv	a0,s2
    80003840:	00001097          	auipc	ra,0x1
    80003844:	c7c080e7          	jalr	-900(ra) # 800044bc <holdingsleep>
    80003848:	cd19                	beqz	a0,80003866 <iunlock+0x3c>
    8000384a:	449c                	lw	a5,8(s1)
    8000384c:	00f05d63          	blez	a5,80003866 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003850:	854a                	mv	a0,s2
    80003852:	00001097          	auipc	ra,0x1
    80003856:	c26080e7          	jalr	-986(ra) # 80004478 <releasesleep>
}
    8000385a:	60e2                	ld	ra,24(sp)
    8000385c:	6442                	ld	s0,16(sp)
    8000385e:	64a2                	ld	s1,8(sp)
    80003860:	6902                	ld	s2,0(sp)
    80003862:	6105                	addi	sp,sp,32
    80003864:	8082                	ret
    panic("iunlock");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	d8250513          	addi	a0,a0,-638 # 800085e8 <syscalls+0x1a8>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cda080e7          	jalr	-806(ra) # 80000548 <panic>

0000000080003876 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003876:	7179                	addi	sp,sp,-48
    80003878:	f406                	sd	ra,40(sp)
    8000387a:	f022                	sd	s0,32(sp)
    8000387c:	ec26                	sd	s1,24(sp)
    8000387e:	e84a                	sd	s2,16(sp)
    80003880:	e44e                	sd	s3,8(sp)
    80003882:	e052                	sd	s4,0(sp)
    80003884:	1800                	addi	s0,sp,48
    80003886:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003888:	05050493          	addi	s1,a0,80
    8000388c:	08050913          	addi	s2,a0,128
    80003890:	a021                	j	80003898 <itrunc+0x22>
    80003892:	0491                	addi	s1,s1,4
    80003894:	01248d63          	beq	s1,s2,800038ae <itrunc+0x38>
    if(ip->addrs[i]){
    80003898:	408c                	lw	a1,0(s1)
    8000389a:	dde5                	beqz	a1,80003892 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000389c:	0009a503          	lw	a0,0(s3)
    800038a0:	00000097          	auipc	ra,0x0
    800038a4:	90c080e7          	jalr	-1780(ra) # 800031ac <bfree>
      ip->addrs[i] = 0;
    800038a8:	0004a023          	sw	zero,0(s1)
    800038ac:	b7dd                	j	80003892 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038ae:	0809a583          	lw	a1,128(s3)
    800038b2:	e185                	bnez	a1,800038d2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038b4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038b8:	854e                	mv	a0,s3
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	de4080e7          	jalr	-540(ra) # 8000369e <iupdate>
}
    800038c2:	70a2                	ld	ra,40(sp)
    800038c4:	7402                	ld	s0,32(sp)
    800038c6:	64e2                	ld	s1,24(sp)
    800038c8:	6942                	ld	s2,16(sp)
    800038ca:	69a2                	ld	s3,8(sp)
    800038cc:	6a02                	ld	s4,0(sp)
    800038ce:	6145                	addi	sp,sp,48
    800038d0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038d2:	0009a503          	lw	a0,0(s3)
    800038d6:	fffff097          	auipc	ra,0xfffff
    800038da:	690080e7          	jalr	1680(ra) # 80002f66 <bread>
    800038de:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e0:	05850493          	addi	s1,a0,88
    800038e4:	45850913          	addi	s2,a0,1112
    800038e8:	a811                	j	800038fc <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038ea:	0009a503          	lw	a0,0(s3)
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	8be080e7          	jalr	-1858(ra) # 800031ac <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038f6:	0491                	addi	s1,s1,4
    800038f8:	01248563          	beq	s1,s2,80003902 <itrunc+0x8c>
      if(a[j])
    800038fc:	408c                	lw	a1,0(s1)
    800038fe:	dde5                	beqz	a1,800038f6 <itrunc+0x80>
    80003900:	b7ed                	j	800038ea <itrunc+0x74>
    brelse(bp);
    80003902:	8552                	mv	a0,s4
    80003904:	fffff097          	auipc	ra,0xfffff
    80003908:	792080e7          	jalr	1938(ra) # 80003096 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000390c:	0809a583          	lw	a1,128(s3)
    80003910:	0009a503          	lw	a0,0(s3)
    80003914:	00000097          	auipc	ra,0x0
    80003918:	898080e7          	jalr	-1896(ra) # 800031ac <bfree>
    ip->addrs[NDIRECT] = 0;
    8000391c:	0809a023          	sw	zero,128(s3)
    80003920:	bf51                	j	800038b4 <itrunc+0x3e>

0000000080003922 <iput>:
{
    80003922:	1101                	addi	sp,sp,-32
    80003924:	ec06                	sd	ra,24(sp)
    80003926:	e822                	sd	s0,16(sp)
    80003928:	e426                	sd	s1,8(sp)
    8000392a:	e04a                	sd	s2,0(sp)
    8000392c:	1000                	addi	s0,sp,32
    8000392e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003930:	0001d517          	auipc	a0,0x1d
    80003934:	b3050513          	addi	a0,a0,-1232 # 80020460 <icache>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	334080e7          	jalr	820(ra) # 80000c6c <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003940:	4498                	lw	a4,8(s1)
    80003942:	4785                	li	a5,1
    80003944:	02f70363          	beq	a4,a5,8000396a <iput+0x48>
  ip->ref--;
    80003948:	449c                	lw	a5,8(s1)
    8000394a:	37fd                	addiw	a5,a5,-1
    8000394c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000394e:	0001d517          	auipc	a0,0x1d
    80003952:	b1250513          	addi	a0,a0,-1262 # 80020460 <icache>
    80003956:	ffffd097          	auipc	ra,0xffffd
    8000395a:	3ca080e7          	jalr	970(ra) # 80000d20 <release>
}
    8000395e:	60e2                	ld	ra,24(sp)
    80003960:	6442                	ld	s0,16(sp)
    80003962:	64a2                	ld	s1,8(sp)
    80003964:	6902                	ld	s2,0(sp)
    80003966:	6105                	addi	sp,sp,32
    80003968:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396a:	40bc                	lw	a5,64(s1)
    8000396c:	dff1                	beqz	a5,80003948 <iput+0x26>
    8000396e:	04a49783          	lh	a5,74(s1)
    80003972:	fbf9                	bnez	a5,80003948 <iput+0x26>
    acquiresleep(&ip->lock);
    80003974:	01048913          	addi	s2,s1,16
    80003978:	854a                	mv	a0,s2
    8000397a:	00001097          	auipc	ra,0x1
    8000397e:	aa8080e7          	jalr	-1368(ra) # 80004422 <acquiresleep>
    release(&icache.lock);
    80003982:	0001d517          	auipc	a0,0x1d
    80003986:	ade50513          	addi	a0,a0,-1314 # 80020460 <icache>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	396080e7          	jalr	918(ra) # 80000d20 <release>
    itrunc(ip);
    80003992:	8526                	mv	a0,s1
    80003994:	00000097          	auipc	ra,0x0
    80003998:	ee2080e7          	jalr	-286(ra) # 80003876 <itrunc>
    ip->type = 0;
    8000399c:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a0:	8526                	mv	a0,s1
    800039a2:	00000097          	auipc	ra,0x0
    800039a6:	cfc080e7          	jalr	-772(ra) # 8000369e <iupdate>
    ip->valid = 0;
    800039aa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039ae:	854a                	mv	a0,s2
    800039b0:	00001097          	auipc	ra,0x1
    800039b4:	ac8080e7          	jalr	-1336(ra) # 80004478 <releasesleep>
    acquire(&icache.lock);
    800039b8:	0001d517          	auipc	a0,0x1d
    800039bc:	aa850513          	addi	a0,a0,-1368 # 80020460 <icache>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	2ac080e7          	jalr	684(ra) # 80000c6c <acquire>
    800039c8:	b741                	j	80003948 <iput+0x26>

00000000800039ca <iunlockput>:
{
    800039ca:	1101                	addi	sp,sp,-32
    800039cc:	ec06                	sd	ra,24(sp)
    800039ce:	e822                	sd	s0,16(sp)
    800039d0:	e426                	sd	s1,8(sp)
    800039d2:	1000                	addi	s0,sp,32
    800039d4:	84aa                	mv	s1,a0
  iunlock(ip);
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	e54080e7          	jalr	-428(ra) # 8000382a <iunlock>
  iput(ip);
    800039de:	8526                	mv	a0,s1
    800039e0:	00000097          	auipc	ra,0x0
    800039e4:	f42080e7          	jalr	-190(ra) # 80003922 <iput>
}
    800039e8:	60e2                	ld	ra,24(sp)
    800039ea:	6442                	ld	s0,16(sp)
    800039ec:	64a2                	ld	s1,8(sp)
    800039ee:	6105                	addi	sp,sp,32
    800039f0:	8082                	ret

00000000800039f2 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f2:	1141                	addi	sp,sp,-16
    800039f4:	e422                	sd	s0,8(sp)
    800039f6:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039f8:	411c                	lw	a5,0(a0)
    800039fa:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039fc:	415c                	lw	a5,4(a0)
    800039fe:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a00:	04451783          	lh	a5,68(a0)
    80003a04:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a08:	04a51783          	lh	a5,74(a0)
    80003a0c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a10:	04c56783          	lwu	a5,76(a0)
    80003a14:	e99c                	sd	a5,16(a1)
}
    80003a16:	6422                	ld	s0,8(sp)
    80003a18:	0141                	addi	sp,sp,16
    80003a1a:	8082                	ret

0000000080003a1c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a1c:	457c                	lw	a5,76(a0)
    80003a1e:	0ed7e863          	bltu	a5,a3,80003b0e <readi+0xf2>
{
    80003a22:	7159                	addi	sp,sp,-112
    80003a24:	f486                	sd	ra,104(sp)
    80003a26:	f0a2                	sd	s0,96(sp)
    80003a28:	eca6                	sd	s1,88(sp)
    80003a2a:	e8ca                	sd	s2,80(sp)
    80003a2c:	e4ce                	sd	s3,72(sp)
    80003a2e:	e0d2                	sd	s4,64(sp)
    80003a30:	fc56                	sd	s5,56(sp)
    80003a32:	f85a                	sd	s6,48(sp)
    80003a34:	f45e                	sd	s7,40(sp)
    80003a36:	f062                	sd	s8,32(sp)
    80003a38:	ec66                	sd	s9,24(sp)
    80003a3a:	e86a                	sd	s10,16(sp)
    80003a3c:	e46e                	sd	s11,8(sp)
    80003a3e:	1880                	addi	s0,sp,112
    80003a40:	8baa                	mv	s7,a0
    80003a42:	8c2e                	mv	s8,a1
    80003a44:	8ab2                	mv	s5,a2
    80003a46:	84b6                	mv	s1,a3
    80003a48:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a4a:	9f35                	addw	a4,a4,a3
    return 0;
    80003a4c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a4e:	08d76f63          	bltu	a4,a3,80003aec <readi+0xd0>
  if(off + n > ip->size)
    80003a52:	00e7f463          	bgeu	a5,a4,80003a5a <readi+0x3e>
    n = ip->size - off;
    80003a56:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a5a:	0a0b0863          	beqz	s6,80003b0a <readi+0xee>
    80003a5e:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a60:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a64:	5cfd                	li	s9,-1
    80003a66:	a82d                	j	80003aa0 <readi+0x84>
    80003a68:	020a1d93          	slli	s11,s4,0x20
    80003a6c:	020ddd93          	srli	s11,s11,0x20
    80003a70:	05890613          	addi	a2,s2,88
    80003a74:	86ee                	mv	a3,s11
    80003a76:	963a                	add	a2,a2,a4
    80003a78:	85d6                	mv	a1,s5
    80003a7a:	8562                	mv	a0,s8
    80003a7c:	fffff097          	auipc	ra,0xfffff
    80003a80:	a2c080e7          	jalr	-1492(ra) # 800024a8 <either_copyout>
    80003a84:	05950d63          	beq	a0,s9,80003ade <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a88:	854a                	mv	a0,s2
    80003a8a:	fffff097          	auipc	ra,0xfffff
    80003a8e:	60c080e7          	jalr	1548(ra) # 80003096 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a92:	013a09bb          	addw	s3,s4,s3
    80003a96:	009a04bb          	addw	s1,s4,s1
    80003a9a:	9aee                	add	s5,s5,s11
    80003a9c:	0569f663          	bgeu	s3,s6,80003ae8 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aa0:	000ba903          	lw	s2,0(s7)
    80003aa4:	00a4d59b          	srliw	a1,s1,0xa
    80003aa8:	855e                	mv	a0,s7
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	8b0080e7          	jalr	-1872(ra) # 8000335a <bmap>
    80003ab2:	0005059b          	sext.w	a1,a0
    80003ab6:	854a                	mv	a0,s2
    80003ab8:	fffff097          	auipc	ra,0xfffff
    80003abc:	4ae080e7          	jalr	1198(ra) # 80002f66 <bread>
    80003ac0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac2:	3ff4f713          	andi	a4,s1,1023
    80003ac6:	40ed07bb          	subw	a5,s10,a4
    80003aca:	413b06bb          	subw	a3,s6,s3
    80003ace:	8a3e                	mv	s4,a5
    80003ad0:	2781                	sext.w	a5,a5
    80003ad2:	0006861b          	sext.w	a2,a3
    80003ad6:	f8f679e3          	bgeu	a2,a5,80003a68 <readi+0x4c>
    80003ada:	8a36                	mv	s4,a3
    80003adc:	b771                	j	80003a68 <readi+0x4c>
      brelse(bp);
    80003ade:	854a                	mv	a0,s2
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	5b6080e7          	jalr	1462(ra) # 80003096 <brelse>
  }
  return tot;
    80003ae8:	0009851b          	sext.w	a0,s3
}
    80003aec:	70a6                	ld	ra,104(sp)
    80003aee:	7406                	ld	s0,96(sp)
    80003af0:	64e6                	ld	s1,88(sp)
    80003af2:	6946                	ld	s2,80(sp)
    80003af4:	69a6                	ld	s3,72(sp)
    80003af6:	6a06                	ld	s4,64(sp)
    80003af8:	7ae2                	ld	s5,56(sp)
    80003afa:	7b42                	ld	s6,48(sp)
    80003afc:	7ba2                	ld	s7,40(sp)
    80003afe:	7c02                	ld	s8,32(sp)
    80003b00:	6ce2                	ld	s9,24(sp)
    80003b02:	6d42                	ld	s10,16(sp)
    80003b04:	6da2                	ld	s11,8(sp)
    80003b06:	6165                	addi	sp,sp,112
    80003b08:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0a:	89da                	mv	s3,s6
    80003b0c:	bff1                	j	80003ae8 <readi+0xcc>
    return 0;
    80003b0e:	4501                	li	a0,0
}
    80003b10:	8082                	ret

0000000080003b12 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b12:	457c                	lw	a5,76(a0)
    80003b14:	10d7e663          	bltu	a5,a3,80003c20 <writei+0x10e>
{
    80003b18:	7159                	addi	sp,sp,-112
    80003b1a:	f486                	sd	ra,104(sp)
    80003b1c:	f0a2                	sd	s0,96(sp)
    80003b1e:	eca6                	sd	s1,88(sp)
    80003b20:	e8ca                	sd	s2,80(sp)
    80003b22:	e4ce                	sd	s3,72(sp)
    80003b24:	e0d2                	sd	s4,64(sp)
    80003b26:	fc56                	sd	s5,56(sp)
    80003b28:	f85a                	sd	s6,48(sp)
    80003b2a:	f45e                	sd	s7,40(sp)
    80003b2c:	f062                	sd	s8,32(sp)
    80003b2e:	ec66                	sd	s9,24(sp)
    80003b30:	e86a                	sd	s10,16(sp)
    80003b32:	e46e                	sd	s11,8(sp)
    80003b34:	1880                	addi	s0,sp,112
    80003b36:	8baa                	mv	s7,a0
    80003b38:	8c2e                	mv	s8,a1
    80003b3a:	8ab2                	mv	s5,a2
    80003b3c:	8936                	mv	s2,a3
    80003b3e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b40:	00e687bb          	addw	a5,a3,a4
    80003b44:	0ed7e063          	bltu	a5,a3,80003c24 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b48:	00043737          	lui	a4,0x43
    80003b4c:	0cf76e63          	bltu	a4,a5,80003c28 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b50:	0a0b0763          	beqz	s6,80003bfe <writei+0xec>
    80003b54:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b56:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b5a:	5cfd                	li	s9,-1
    80003b5c:	a091                	j	80003ba0 <writei+0x8e>
    80003b5e:	02099d93          	slli	s11,s3,0x20
    80003b62:	020ddd93          	srli	s11,s11,0x20
    80003b66:	05848513          	addi	a0,s1,88
    80003b6a:	86ee                	mv	a3,s11
    80003b6c:	8656                	mv	a2,s5
    80003b6e:	85e2                	mv	a1,s8
    80003b70:	953a                	add	a0,a0,a4
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	98c080e7          	jalr	-1652(ra) # 800024fe <either_copyin>
    80003b7a:	07950263          	beq	a0,s9,80003bde <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b7e:	8526                	mv	a0,s1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	77a080e7          	jalr	1914(ra) # 800042fa <log_write>
    brelse(bp);
    80003b88:	8526                	mv	a0,s1
    80003b8a:	fffff097          	auipc	ra,0xfffff
    80003b8e:	50c080e7          	jalr	1292(ra) # 80003096 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b92:	01498a3b          	addw	s4,s3,s4
    80003b96:	0129893b          	addw	s2,s3,s2
    80003b9a:	9aee                	add	s5,s5,s11
    80003b9c:	056a7663          	bgeu	s4,s6,80003be8 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ba0:	000ba483          	lw	s1,0(s7)
    80003ba4:	00a9559b          	srliw	a1,s2,0xa
    80003ba8:	855e                	mv	a0,s7
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	7b0080e7          	jalr	1968(ra) # 8000335a <bmap>
    80003bb2:	0005059b          	sext.w	a1,a0
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	3ae080e7          	jalr	942(ra) # 80002f66 <bread>
    80003bc0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc2:	3ff97713          	andi	a4,s2,1023
    80003bc6:	40ed07bb          	subw	a5,s10,a4
    80003bca:	414b06bb          	subw	a3,s6,s4
    80003bce:	89be                	mv	s3,a5
    80003bd0:	2781                	sext.w	a5,a5
    80003bd2:	0006861b          	sext.w	a2,a3
    80003bd6:	f8f674e3          	bgeu	a2,a5,80003b5e <writei+0x4c>
    80003bda:	89b6                	mv	s3,a3
    80003bdc:	b749                	j	80003b5e <writei+0x4c>
      brelse(bp);
    80003bde:	8526                	mv	a0,s1
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	4b6080e7          	jalr	1206(ra) # 80003096 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003be8:	04cba783          	lw	a5,76(s7)
    80003bec:	0127f463          	bgeu	a5,s2,80003bf4 <writei+0xe2>
      ip->size = off;
    80003bf0:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bf4:	855e                	mv	a0,s7
    80003bf6:	00000097          	auipc	ra,0x0
    80003bfa:	aa8080e7          	jalr	-1368(ra) # 8000369e <iupdate>
  }

  return n;
    80003bfe:	000b051b          	sext.w	a0,s6
}
    80003c02:	70a6                	ld	ra,104(sp)
    80003c04:	7406                	ld	s0,96(sp)
    80003c06:	64e6                	ld	s1,88(sp)
    80003c08:	6946                	ld	s2,80(sp)
    80003c0a:	69a6                	ld	s3,72(sp)
    80003c0c:	6a06                	ld	s4,64(sp)
    80003c0e:	7ae2                	ld	s5,56(sp)
    80003c10:	7b42                	ld	s6,48(sp)
    80003c12:	7ba2                	ld	s7,40(sp)
    80003c14:	7c02                	ld	s8,32(sp)
    80003c16:	6ce2                	ld	s9,24(sp)
    80003c18:	6d42                	ld	s10,16(sp)
    80003c1a:	6da2                	ld	s11,8(sp)
    80003c1c:	6165                	addi	sp,sp,112
    80003c1e:	8082                	ret
    return -1;
    80003c20:	557d                	li	a0,-1
}
    80003c22:	8082                	ret
    return -1;
    80003c24:	557d                	li	a0,-1
    80003c26:	bff1                	j	80003c02 <writei+0xf0>
    return -1;
    80003c28:	557d                	li	a0,-1
    80003c2a:	bfe1                	j	80003c02 <writei+0xf0>

0000000080003c2c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c2c:	1141                	addi	sp,sp,-16
    80003c2e:	e406                	sd	ra,8(sp)
    80003c30:	e022                	sd	s0,0(sp)
    80003c32:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c34:	4639                	li	a2,14
    80003c36:	ffffd097          	auipc	ra,0xffffd
    80003c3a:	20e080e7          	jalr	526(ra) # 80000e44 <strncmp>
}
    80003c3e:	60a2                	ld	ra,8(sp)
    80003c40:	6402                	ld	s0,0(sp)
    80003c42:	0141                	addi	sp,sp,16
    80003c44:	8082                	ret

0000000080003c46 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c46:	7139                	addi	sp,sp,-64
    80003c48:	fc06                	sd	ra,56(sp)
    80003c4a:	f822                	sd	s0,48(sp)
    80003c4c:	f426                	sd	s1,40(sp)
    80003c4e:	f04a                	sd	s2,32(sp)
    80003c50:	ec4e                	sd	s3,24(sp)
    80003c52:	e852                	sd	s4,16(sp)
    80003c54:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c56:	04451703          	lh	a4,68(a0)
    80003c5a:	4785                	li	a5,1
    80003c5c:	00f71a63          	bne	a4,a5,80003c70 <dirlookup+0x2a>
    80003c60:	892a                	mv	s2,a0
    80003c62:	89ae                	mv	s3,a1
    80003c64:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c66:	457c                	lw	a5,76(a0)
    80003c68:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c6a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6c:	e79d                	bnez	a5,80003c9a <dirlookup+0x54>
    80003c6e:	a8a5                	j	80003ce6 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c70:	00005517          	auipc	a0,0x5
    80003c74:	98050513          	addi	a0,a0,-1664 # 800085f0 <syscalls+0x1b0>
    80003c78:	ffffd097          	auipc	ra,0xffffd
    80003c7c:	8d0080e7          	jalr	-1840(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c80:	00005517          	auipc	a0,0x5
    80003c84:	98850513          	addi	a0,a0,-1656 # 80008608 <syscalls+0x1c8>
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	8c0080e7          	jalr	-1856(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c90:	24c1                	addiw	s1,s1,16
    80003c92:	04c92783          	lw	a5,76(s2)
    80003c96:	04f4f763          	bgeu	s1,a5,80003ce4 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c9a:	4741                	li	a4,16
    80003c9c:	86a6                	mv	a3,s1
    80003c9e:	fc040613          	addi	a2,s0,-64
    80003ca2:	4581                	li	a1,0
    80003ca4:	854a                	mv	a0,s2
    80003ca6:	00000097          	auipc	ra,0x0
    80003caa:	d76080e7          	jalr	-650(ra) # 80003a1c <readi>
    80003cae:	47c1                	li	a5,16
    80003cb0:	fcf518e3          	bne	a0,a5,80003c80 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cb4:	fc045783          	lhu	a5,-64(s0)
    80003cb8:	dfe1                	beqz	a5,80003c90 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cba:	fc240593          	addi	a1,s0,-62
    80003cbe:	854e                	mv	a0,s3
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	f6c080e7          	jalr	-148(ra) # 80003c2c <namecmp>
    80003cc8:	f561                	bnez	a0,80003c90 <dirlookup+0x4a>
      if(poff)
    80003cca:	000a0463          	beqz	s4,80003cd2 <dirlookup+0x8c>
        *poff = off;
    80003cce:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cd2:	fc045583          	lhu	a1,-64(s0)
    80003cd6:	00092503          	lw	a0,0(s2)
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	75a080e7          	jalr	1882(ra) # 80003434 <iget>
    80003ce2:	a011                	j	80003ce6 <dirlookup+0xa0>
  return 0;
    80003ce4:	4501                	li	a0,0
}
    80003ce6:	70e2                	ld	ra,56(sp)
    80003ce8:	7442                	ld	s0,48(sp)
    80003cea:	74a2                	ld	s1,40(sp)
    80003cec:	7902                	ld	s2,32(sp)
    80003cee:	69e2                	ld	s3,24(sp)
    80003cf0:	6a42                	ld	s4,16(sp)
    80003cf2:	6121                	addi	sp,sp,64
    80003cf4:	8082                	ret

0000000080003cf6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cf6:	711d                	addi	sp,sp,-96
    80003cf8:	ec86                	sd	ra,88(sp)
    80003cfa:	e8a2                	sd	s0,80(sp)
    80003cfc:	e4a6                	sd	s1,72(sp)
    80003cfe:	e0ca                	sd	s2,64(sp)
    80003d00:	fc4e                	sd	s3,56(sp)
    80003d02:	f852                	sd	s4,48(sp)
    80003d04:	f456                	sd	s5,40(sp)
    80003d06:	f05a                	sd	s6,32(sp)
    80003d08:	ec5e                	sd	s7,24(sp)
    80003d0a:	e862                	sd	s8,16(sp)
    80003d0c:	e466                	sd	s9,8(sp)
    80003d0e:	1080                	addi	s0,sp,96
    80003d10:	84aa                	mv	s1,a0
    80003d12:	8b2e                	mv	s6,a1
    80003d14:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d16:	00054703          	lbu	a4,0(a0)
    80003d1a:	02f00793          	li	a5,47
    80003d1e:	02f70363          	beq	a4,a5,80003d44 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d22:	ffffe097          	auipc	ra,0xffffe
    80003d26:	d18080e7          	jalr	-744(ra) # 80001a3a <myproc>
    80003d2a:	15053503          	ld	a0,336(a0)
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	9fc080e7          	jalr	-1540(ra) # 8000372a <idup>
    80003d36:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d38:	02f00913          	li	s2,47
  len = path - s;
    80003d3c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d3e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d40:	4c05                	li	s8,1
    80003d42:	a865                	j	80003dfa <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d44:	4585                	li	a1,1
    80003d46:	4505                	li	a0,1
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	6ec080e7          	jalr	1772(ra) # 80003434 <iget>
    80003d50:	89aa                	mv	s3,a0
    80003d52:	b7dd                	j	80003d38 <namex+0x42>
      iunlockput(ip);
    80003d54:	854e                	mv	a0,s3
    80003d56:	00000097          	auipc	ra,0x0
    80003d5a:	c74080e7          	jalr	-908(ra) # 800039ca <iunlockput>
      return 0;
    80003d5e:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d60:	854e                	mv	a0,s3
    80003d62:	60e6                	ld	ra,88(sp)
    80003d64:	6446                	ld	s0,80(sp)
    80003d66:	64a6                	ld	s1,72(sp)
    80003d68:	6906                	ld	s2,64(sp)
    80003d6a:	79e2                	ld	s3,56(sp)
    80003d6c:	7a42                	ld	s4,48(sp)
    80003d6e:	7aa2                	ld	s5,40(sp)
    80003d70:	7b02                	ld	s6,32(sp)
    80003d72:	6be2                	ld	s7,24(sp)
    80003d74:	6c42                	ld	s8,16(sp)
    80003d76:	6ca2                	ld	s9,8(sp)
    80003d78:	6125                	addi	sp,sp,96
    80003d7a:	8082                	ret
      iunlock(ip);
    80003d7c:	854e                	mv	a0,s3
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	aac080e7          	jalr	-1364(ra) # 8000382a <iunlock>
      return ip;
    80003d86:	bfe9                	j	80003d60 <namex+0x6a>
      iunlockput(ip);
    80003d88:	854e                	mv	a0,s3
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	c40080e7          	jalr	-960(ra) # 800039ca <iunlockput>
      return 0;
    80003d92:	89d2                	mv	s3,s4
    80003d94:	b7f1                	j	80003d60 <namex+0x6a>
  len = path - s;
    80003d96:	40b48633          	sub	a2,s1,a1
    80003d9a:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d9e:	094cd463          	bge	s9,s4,80003e26 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003da2:	4639                	li	a2,14
    80003da4:	8556                	mv	a0,s5
    80003da6:	ffffd097          	auipc	ra,0xffffd
    80003daa:	022080e7          	jalr	34(ra) # 80000dc8 <memmove>
  while(*path == '/')
    80003dae:	0004c783          	lbu	a5,0(s1)
    80003db2:	01279763          	bne	a5,s2,80003dc0 <namex+0xca>
    path++;
    80003db6:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003db8:	0004c783          	lbu	a5,0(s1)
    80003dbc:	ff278de3          	beq	a5,s2,80003db6 <namex+0xc0>
    ilock(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	9a6080e7          	jalr	-1626(ra) # 80003768 <ilock>
    if(ip->type != T_DIR){
    80003dca:	04499783          	lh	a5,68(s3)
    80003dce:	f98793e3          	bne	a5,s8,80003d54 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dd2:	000b0563          	beqz	s6,80003ddc <namex+0xe6>
    80003dd6:	0004c783          	lbu	a5,0(s1)
    80003dda:	d3cd                	beqz	a5,80003d7c <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ddc:	865e                	mv	a2,s7
    80003dde:	85d6                	mv	a1,s5
    80003de0:	854e                	mv	a0,s3
    80003de2:	00000097          	auipc	ra,0x0
    80003de6:	e64080e7          	jalr	-412(ra) # 80003c46 <dirlookup>
    80003dea:	8a2a                	mv	s4,a0
    80003dec:	dd51                	beqz	a0,80003d88 <namex+0x92>
    iunlockput(ip);
    80003dee:	854e                	mv	a0,s3
    80003df0:	00000097          	auipc	ra,0x0
    80003df4:	bda080e7          	jalr	-1062(ra) # 800039ca <iunlockput>
    ip = next;
    80003df8:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dfa:	0004c783          	lbu	a5,0(s1)
    80003dfe:	05279763          	bne	a5,s2,80003e4c <namex+0x156>
    path++;
    80003e02:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e04:	0004c783          	lbu	a5,0(s1)
    80003e08:	ff278de3          	beq	a5,s2,80003e02 <namex+0x10c>
  if(*path == 0)
    80003e0c:	c79d                	beqz	a5,80003e3a <namex+0x144>
    path++;
    80003e0e:	85a6                	mv	a1,s1
  len = path - s;
    80003e10:	8a5e                	mv	s4,s7
    80003e12:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e14:	01278963          	beq	a5,s2,80003e26 <namex+0x130>
    80003e18:	dfbd                	beqz	a5,80003d96 <namex+0xa0>
    path++;
    80003e1a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e1c:	0004c783          	lbu	a5,0(s1)
    80003e20:	ff279ce3          	bne	a5,s2,80003e18 <namex+0x122>
    80003e24:	bf8d                	j	80003d96 <namex+0xa0>
    memmove(name, s, len);
    80003e26:	2601                	sext.w	a2,a2
    80003e28:	8556                	mv	a0,s5
    80003e2a:	ffffd097          	auipc	ra,0xffffd
    80003e2e:	f9e080e7          	jalr	-98(ra) # 80000dc8 <memmove>
    name[len] = 0;
    80003e32:	9a56                	add	s4,s4,s5
    80003e34:	000a0023          	sb	zero,0(s4)
    80003e38:	bf9d                	j	80003dae <namex+0xb8>
  if(nameiparent){
    80003e3a:	f20b03e3          	beqz	s6,80003d60 <namex+0x6a>
    iput(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	ae2080e7          	jalr	-1310(ra) # 80003922 <iput>
    return 0;
    80003e48:	4981                	li	s3,0
    80003e4a:	bf19                	j	80003d60 <namex+0x6a>
  if(*path == 0)
    80003e4c:	d7fd                	beqz	a5,80003e3a <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	85a6                	mv	a1,s1
    80003e54:	b7d1                	j	80003e18 <namex+0x122>

0000000080003e56 <dirlink>:
{
    80003e56:	7139                	addi	sp,sp,-64
    80003e58:	fc06                	sd	ra,56(sp)
    80003e5a:	f822                	sd	s0,48(sp)
    80003e5c:	f426                	sd	s1,40(sp)
    80003e5e:	f04a                	sd	s2,32(sp)
    80003e60:	ec4e                	sd	s3,24(sp)
    80003e62:	e852                	sd	s4,16(sp)
    80003e64:	0080                	addi	s0,sp,64
    80003e66:	892a                	mv	s2,a0
    80003e68:	8a2e                	mv	s4,a1
    80003e6a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e6c:	4601                	li	a2,0
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	dd8080e7          	jalr	-552(ra) # 80003c46 <dirlookup>
    80003e76:	e93d                	bnez	a0,80003eec <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e78:	04c92483          	lw	s1,76(s2)
    80003e7c:	c49d                	beqz	s1,80003eaa <dirlink+0x54>
    80003e7e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e80:	4741                	li	a4,16
    80003e82:	86a6                	mv	a3,s1
    80003e84:	fc040613          	addi	a2,s0,-64
    80003e88:	4581                	li	a1,0
    80003e8a:	854a                	mv	a0,s2
    80003e8c:	00000097          	auipc	ra,0x0
    80003e90:	b90080e7          	jalr	-1136(ra) # 80003a1c <readi>
    80003e94:	47c1                	li	a5,16
    80003e96:	06f51163          	bne	a0,a5,80003ef8 <dirlink+0xa2>
    if(de.inum == 0)
    80003e9a:	fc045783          	lhu	a5,-64(s0)
    80003e9e:	c791                	beqz	a5,80003eaa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea0:	24c1                	addiw	s1,s1,16
    80003ea2:	04c92783          	lw	a5,76(s2)
    80003ea6:	fcf4ede3          	bltu	s1,a5,80003e80 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eaa:	4639                	li	a2,14
    80003eac:	85d2                	mv	a1,s4
    80003eae:	fc240513          	addi	a0,s0,-62
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	fce080e7          	jalr	-50(ra) # 80000e80 <strncpy>
  de.inum = inum;
    80003eba:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ebe:	4741                	li	a4,16
    80003ec0:	86a6                	mv	a3,s1
    80003ec2:	fc040613          	addi	a2,s0,-64
    80003ec6:	4581                	li	a1,0
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	c48080e7          	jalr	-952(ra) # 80003b12 <writei>
    80003ed2:	872a                	mv	a4,a0
    80003ed4:	47c1                	li	a5,16
  return 0;
    80003ed6:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed8:	02f71863          	bne	a4,a5,80003f08 <dirlink+0xb2>
}
    80003edc:	70e2                	ld	ra,56(sp)
    80003ede:	7442                	ld	s0,48(sp)
    80003ee0:	74a2                	ld	s1,40(sp)
    80003ee2:	7902                	ld	s2,32(sp)
    80003ee4:	69e2                	ld	s3,24(sp)
    80003ee6:	6a42                	ld	s4,16(sp)
    80003ee8:	6121                	addi	sp,sp,64
    80003eea:	8082                	ret
    iput(ip);
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	a36080e7          	jalr	-1482(ra) # 80003922 <iput>
    return -1;
    80003ef4:	557d                	li	a0,-1
    80003ef6:	b7dd                	j	80003edc <dirlink+0x86>
      panic("dirlink read");
    80003ef8:	00004517          	auipc	a0,0x4
    80003efc:	72050513          	addi	a0,a0,1824 # 80008618 <syscalls+0x1d8>
    80003f00:	ffffc097          	auipc	ra,0xffffc
    80003f04:	648080e7          	jalr	1608(ra) # 80000548 <panic>
    panic("dirlink");
    80003f08:	00005517          	auipc	a0,0x5
    80003f0c:	83050513          	addi	a0,a0,-2000 # 80008738 <syscalls+0x2f8>
    80003f10:	ffffc097          	auipc	ra,0xffffc
    80003f14:	638080e7          	jalr	1592(ra) # 80000548 <panic>

0000000080003f18 <namei>:

struct inode*
namei(char *path)
{
    80003f18:	1101                	addi	sp,sp,-32
    80003f1a:	ec06                	sd	ra,24(sp)
    80003f1c:	e822                	sd	s0,16(sp)
    80003f1e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f20:	fe040613          	addi	a2,s0,-32
    80003f24:	4581                	li	a1,0
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	dd0080e7          	jalr	-560(ra) # 80003cf6 <namex>
}
    80003f2e:	60e2                	ld	ra,24(sp)
    80003f30:	6442                	ld	s0,16(sp)
    80003f32:	6105                	addi	sp,sp,32
    80003f34:	8082                	ret

0000000080003f36 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f36:	1141                	addi	sp,sp,-16
    80003f38:	e406                	sd	ra,8(sp)
    80003f3a:	e022                	sd	s0,0(sp)
    80003f3c:	0800                	addi	s0,sp,16
    80003f3e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f40:	4585                	li	a1,1
    80003f42:	00000097          	auipc	ra,0x0
    80003f46:	db4080e7          	jalr	-588(ra) # 80003cf6 <namex>
}
    80003f4a:	60a2                	ld	ra,8(sp)
    80003f4c:	6402                	ld	s0,0(sp)
    80003f4e:	0141                	addi	sp,sp,16
    80003f50:	8082                	ret

0000000080003f52 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f52:	1101                	addi	sp,sp,-32
    80003f54:	ec06                	sd	ra,24(sp)
    80003f56:	e822                	sd	s0,16(sp)
    80003f58:	e426                	sd	s1,8(sp)
    80003f5a:	e04a                	sd	s2,0(sp)
    80003f5c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f5e:	0001e917          	auipc	s2,0x1e
    80003f62:	faa90913          	addi	s2,s2,-86 # 80021f08 <log>
    80003f66:	01892583          	lw	a1,24(s2)
    80003f6a:	02892503          	lw	a0,40(s2)
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	ff8080e7          	jalr	-8(ra) # 80002f66 <bread>
    80003f76:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f78:	02c92683          	lw	a3,44(s2)
    80003f7c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f7e:	02d05763          	blez	a3,80003fac <write_head+0x5a>
    80003f82:	0001e797          	auipc	a5,0x1e
    80003f86:	fb678793          	addi	a5,a5,-74 # 80021f38 <log+0x30>
    80003f8a:	05c50713          	addi	a4,a0,92
    80003f8e:	36fd                	addiw	a3,a3,-1
    80003f90:	1682                	slli	a3,a3,0x20
    80003f92:	9281                	srli	a3,a3,0x20
    80003f94:	068a                	slli	a3,a3,0x2
    80003f96:	0001e617          	auipc	a2,0x1e
    80003f9a:	fa660613          	addi	a2,a2,-90 # 80021f3c <log+0x34>
    80003f9e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fa0:	4390                	lw	a2,0(a5)
    80003fa2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fa4:	0791                	addi	a5,a5,4
    80003fa6:	0711                	addi	a4,a4,4
    80003fa8:	fed79ce3          	bne	a5,a3,80003fa0 <write_head+0x4e>
  }
  bwrite(buf);
    80003fac:	8526                	mv	a0,s1
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	0aa080e7          	jalr	170(ra) # 80003058 <bwrite>
  brelse(buf);
    80003fb6:	8526                	mv	a0,s1
    80003fb8:	fffff097          	auipc	ra,0xfffff
    80003fbc:	0de080e7          	jalr	222(ra) # 80003096 <brelse>
}
    80003fc0:	60e2                	ld	ra,24(sp)
    80003fc2:	6442                	ld	s0,16(sp)
    80003fc4:	64a2                	ld	s1,8(sp)
    80003fc6:	6902                	ld	s2,0(sp)
    80003fc8:	6105                	addi	sp,sp,32
    80003fca:	8082                	ret

0000000080003fcc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fcc:	0001e797          	auipc	a5,0x1e
    80003fd0:	f687a783          	lw	a5,-152(a5) # 80021f34 <log+0x2c>
    80003fd4:	0af05663          	blez	a5,80004080 <install_trans+0xb4>
{
    80003fd8:	7139                	addi	sp,sp,-64
    80003fda:	fc06                	sd	ra,56(sp)
    80003fdc:	f822                	sd	s0,48(sp)
    80003fde:	f426                	sd	s1,40(sp)
    80003fe0:	f04a                	sd	s2,32(sp)
    80003fe2:	ec4e                	sd	s3,24(sp)
    80003fe4:	e852                	sd	s4,16(sp)
    80003fe6:	e456                	sd	s5,8(sp)
    80003fe8:	0080                	addi	s0,sp,64
    80003fea:	0001ea97          	auipc	s5,0x1e
    80003fee:	f4ea8a93          	addi	s5,s5,-178 # 80021f38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003ff4:	0001e997          	auipc	s3,0x1e
    80003ff8:	f1498993          	addi	s3,s3,-236 # 80021f08 <log>
    80003ffc:	0189a583          	lw	a1,24(s3)
    80004000:	014585bb          	addw	a1,a1,s4
    80004004:	2585                	addiw	a1,a1,1
    80004006:	0289a503          	lw	a0,40(s3)
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	f5c080e7          	jalr	-164(ra) # 80002f66 <bread>
    80004012:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004014:	000aa583          	lw	a1,0(s5)
    80004018:	0289a503          	lw	a0,40(s3)
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	f4a080e7          	jalr	-182(ra) # 80002f66 <bread>
    80004024:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004026:	40000613          	li	a2,1024
    8000402a:	05890593          	addi	a1,s2,88
    8000402e:	05850513          	addi	a0,a0,88
    80004032:	ffffd097          	auipc	ra,0xffffd
    80004036:	d96080e7          	jalr	-618(ra) # 80000dc8 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000403a:	8526                	mv	a0,s1
    8000403c:	fffff097          	auipc	ra,0xfffff
    80004040:	01c080e7          	jalr	28(ra) # 80003058 <bwrite>
    bunpin(dbuf);
    80004044:	8526                	mv	a0,s1
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	12a080e7          	jalr	298(ra) # 80003170 <bunpin>
    brelse(lbuf);
    8000404e:	854a                	mv	a0,s2
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	046080e7          	jalr	70(ra) # 80003096 <brelse>
    brelse(dbuf);
    80004058:	8526                	mv	a0,s1
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	03c080e7          	jalr	60(ra) # 80003096 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004062:	2a05                	addiw	s4,s4,1
    80004064:	0a91                	addi	s5,s5,4
    80004066:	02c9a783          	lw	a5,44(s3)
    8000406a:	f8fa49e3          	blt	s4,a5,80003ffc <install_trans+0x30>
}
    8000406e:	70e2                	ld	ra,56(sp)
    80004070:	7442                	ld	s0,48(sp)
    80004072:	74a2                	ld	s1,40(sp)
    80004074:	7902                	ld	s2,32(sp)
    80004076:	69e2                	ld	s3,24(sp)
    80004078:	6a42                	ld	s4,16(sp)
    8000407a:	6aa2                	ld	s5,8(sp)
    8000407c:	6121                	addi	sp,sp,64
    8000407e:	8082                	ret
    80004080:	8082                	ret

0000000080004082 <initlog>:
{
    80004082:	7179                	addi	sp,sp,-48
    80004084:	f406                	sd	ra,40(sp)
    80004086:	f022                	sd	s0,32(sp)
    80004088:	ec26                	sd	s1,24(sp)
    8000408a:	e84a                	sd	s2,16(sp)
    8000408c:	e44e                	sd	s3,8(sp)
    8000408e:	1800                	addi	s0,sp,48
    80004090:	892a                	mv	s2,a0
    80004092:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004094:	0001e497          	auipc	s1,0x1e
    80004098:	e7448493          	addi	s1,s1,-396 # 80021f08 <log>
    8000409c:	00004597          	auipc	a1,0x4
    800040a0:	58c58593          	addi	a1,a1,1420 # 80008628 <syscalls+0x1e8>
    800040a4:	8526                	mv	a0,s1
    800040a6:	ffffd097          	auipc	ra,0xffffd
    800040aa:	b36080e7          	jalr	-1226(ra) # 80000bdc <initlock>
  log.start = sb->logstart;
    800040ae:	0149a583          	lw	a1,20(s3)
    800040b2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040b4:	0109a783          	lw	a5,16(s3)
    800040b8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ba:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040be:	854a                	mv	a0,s2
    800040c0:	fffff097          	auipc	ra,0xfffff
    800040c4:	ea6080e7          	jalr	-346(ra) # 80002f66 <bread>
  log.lh.n = lh->n;
    800040c8:	4d3c                	lw	a5,88(a0)
    800040ca:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040cc:	02f05563          	blez	a5,800040f6 <initlog+0x74>
    800040d0:	05c50713          	addi	a4,a0,92
    800040d4:	0001e697          	auipc	a3,0x1e
    800040d8:	e6468693          	addi	a3,a3,-412 # 80021f38 <log+0x30>
    800040dc:	37fd                	addiw	a5,a5,-1
    800040de:	1782                	slli	a5,a5,0x20
    800040e0:	9381                	srli	a5,a5,0x20
    800040e2:	078a                	slli	a5,a5,0x2
    800040e4:	06050613          	addi	a2,a0,96
    800040e8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040ea:	4310                	lw	a2,0(a4)
    800040ec:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040ee:	0711                	addi	a4,a4,4
    800040f0:	0691                	addi	a3,a3,4
    800040f2:	fef71ce3          	bne	a4,a5,800040ea <initlog+0x68>
  brelse(buf);
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	fa0080e7          	jalr	-96(ra) # 80003096 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040fe:	00000097          	auipc	ra,0x0
    80004102:	ece080e7          	jalr	-306(ra) # 80003fcc <install_trans>
  log.lh.n = 0;
    80004106:	0001e797          	auipc	a5,0x1e
    8000410a:	e207a723          	sw	zero,-466(a5) # 80021f34 <log+0x2c>
  write_head(); // clear the log
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	e44080e7          	jalr	-444(ra) # 80003f52 <write_head>
}
    80004116:	70a2                	ld	ra,40(sp)
    80004118:	7402                	ld	s0,32(sp)
    8000411a:	64e2                	ld	s1,24(sp)
    8000411c:	6942                	ld	s2,16(sp)
    8000411e:	69a2                	ld	s3,8(sp)
    80004120:	6145                	addi	sp,sp,48
    80004122:	8082                	ret

0000000080004124 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004124:	1101                	addi	sp,sp,-32
    80004126:	ec06                	sd	ra,24(sp)
    80004128:	e822                	sd	s0,16(sp)
    8000412a:	e426                	sd	s1,8(sp)
    8000412c:	e04a                	sd	s2,0(sp)
    8000412e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004130:	0001e517          	auipc	a0,0x1e
    80004134:	dd850513          	addi	a0,a0,-552 # 80021f08 <log>
    80004138:	ffffd097          	auipc	ra,0xffffd
    8000413c:	b34080e7          	jalr	-1228(ra) # 80000c6c <acquire>
  while(1){
    if(log.committing){
    80004140:	0001e497          	auipc	s1,0x1e
    80004144:	dc848493          	addi	s1,s1,-568 # 80021f08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004148:	4979                	li	s2,30
    8000414a:	a039                	j	80004158 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000414c:	85a6                	mv	a1,s1
    8000414e:	8526                	mv	a0,s1
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	0f6080e7          	jalr	246(ra) # 80002246 <sleep>
    if(log.committing){
    80004158:	50dc                	lw	a5,36(s1)
    8000415a:	fbed                	bnez	a5,8000414c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000415c:	509c                	lw	a5,32(s1)
    8000415e:	0017871b          	addiw	a4,a5,1
    80004162:	0007069b          	sext.w	a3,a4
    80004166:	0027179b          	slliw	a5,a4,0x2
    8000416a:	9fb9                	addw	a5,a5,a4
    8000416c:	0017979b          	slliw	a5,a5,0x1
    80004170:	54d8                	lw	a4,44(s1)
    80004172:	9fb9                	addw	a5,a5,a4
    80004174:	00f95963          	bge	s2,a5,80004186 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004178:	85a6                	mv	a1,s1
    8000417a:	8526                	mv	a0,s1
    8000417c:	ffffe097          	auipc	ra,0xffffe
    80004180:	0ca080e7          	jalr	202(ra) # 80002246 <sleep>
    80004184:	bfd1                	j	80004158 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004186:	0001e517          	auipc	a0,0x1e
    8000418a:	d8250513          	addi	a0,a0,-638 # 80021f08 <log>
    8000418e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004190:	ffffd097          	auipc	ra,0xffffd
    80004194:	b90080e7          	jalr	-1136(ra) # 80000d20 <release>
      break;
    }
  }
}
    80004198:	60e2                	ld	ra,24(sp)
    8000419a:	6442                	ld	s0,16(sp)
    8000419c:	64a2                	ld	s1,8(sp)
    8000419e:	6902                	ld	s2,0(sp)
    800041a0:	6105                	addi	sp,sp,32
    800041a2:	8082                	ret

00000000800041a4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041a4:	7139                	addi	sp,sp,-64
    800041a6:	fc06                	sd	ra,56(sp)
    800041a8:	f822                	sd	s0,48(sp)
    800041aa:	f426                	sd	s1,40(sp)
    800041ac:	f04a                	sd	s2,32(sp)
    800041ae:	ec4e                	sd	s3,24(sp)
    800041b0:	e852                	sd	s4,16(sp)
    800041b2:	e456                	sd	s5,8(sp)
    800041b4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041b6:	0001e497          	auipc	s1,0x1e
    800041ba:	d5248493          	addi	s1,s1,-686 # 80021f08 <log>
    800041be:	8526                	mv	a0,s1
    800041c0:	ffffd097          	auipc	ra,0xffffd
    800041c4:	aac080e7          	jalr	-1364(ra) # 80000c6c <acquire>
  log.outstanding -= 1;
    800041c8:	509c                	lw	a5,32(s1)
    800041ca:	37fd                	addiw	a5,a5,-1
    800041cc:	0007891b          	sext.w	s2,a5
    800041d0:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041d2:	50dc                	lw	a5,36(s1)
    800041d4:	efb9                	bnez	a5,80004232 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041d6:	06091663          	bnez	s2,80004242 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041da:	0001e497          	auipc	s1,0x1e
    800041de:	d2e48493          	addi	s1,s1,-722 # 80021f08 <log>
    800041e2:	4785                	li	a5,1
    800041e4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	b38080e7          	jalr	-1224(ra) # 80000d20 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041f0:	54dc                	lw	a5,44(s1)
    800041f2:	06f04763          	bgtz	a5,80004260 <end_op+0xbc>
    acquire(&log.lock);
    800041f6:	0001e497          	auipc	s1,0x1e
    800041fa:	d1248493          	addi	s1,s1,-750 # 80021f08 <log>
    800041fe:	8526                	mv	a0,s1
    80004200:	ffffd097          	auipc	ra,0xffffd
    80004204:	a6c080e7          	jalr	-1428(ra) # 80000c6c <acquire>
    log.committing = 0;
    80004208:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	1be080e7          	jalr	446(ra) # 800023cc <wakeup>
    release(&log.lock);
    80004216:	8526                	mv	a0,s1
    80004218:	ffffd097          	auipc	ra,0xffffd
    8000421c:	b08080e7          	jalr	-1272(ra) # 80000d20 <release>
}
    80004220:	70e2                	ld	ra,56(sp)
    80004222:	7442                	ld	s0,48(sp)
    80004224:	74a2                	ld	s1,40(sp)
    80004226:	7902                	ld	s2,32(sp)
    80004228:	69e2                	ld	s3,24(sp)
    8000422a:	6a42                	ld	s4,16(sp)
    8000422c:	6aa2                	ld	s5,8(sp)
    8000422e:	6121                	addi	sp,sp,64
    80004230:	8082                	ret
    panic("log.committing");
    80004232:	00004517          	auipc	a0,0x4
    80004236:	3fe50513          	addi	a0,a0,1022 # 80008630 <syscalls+0x1f0>
    8000423a:	ffffc097          	auipc	ra,0xffffc
    8000423e:	30e080e7          	jalr	782(ra) # 80000548 <panic>
    wakeup(&log);
    80004242:	0001e497          	auipc	s1,0x1e
    80004246:	cc648493          	addi	s1,s1,-826 # 80021f08 <log>
    8000424a:	8526                	mv	a0,s1
    8000424c:	ffffe097          	auipc	ra,0xffffe
    80004250:	180080e7          	jalr	384(ra) # 800023cc <wakeup>
  release(&log.lock);
    80004254:	8526                	mv	a0,s1
    80004256:	ffffd097          	auipc	ra,0xffffd
    8000425a:	aca080e7          	jalr	-1334(ra) # 80000d20 <release>
  if(do_commit){
    8000425e:	b7c9                	j	80004220 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004260:	0001ea97          	auipc	s5,0x1e
    80004264:	cd8a8a93          	addi	s5,s5,-808 # 80021f38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004268:	0001ea17          	auipc	s4,0x1e
    8000426c:	ca0a0a13          	addi	s4,s4,-864 # 80021f08 <log>
    80004270:	018a2583          	lw	a1,24(s4)
    80004274:	012585bb          	addw	a1,a1,s2
    80004278:	2585                	addiw	a1,a1,1
    8000427a:	028a2503          	lw	a0,40(s4)
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	ce8080e7          	jalr	-792(ra) # 80002f66 <bread>
    80004286:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004288:	000aa583          	lw	a1,0(s5)
    8000428c:	028a2503          	lw	a0,40(s4)
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	cd6080e7          	jalr	-810(ra) # 80002f66 <bread>
    80004298:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000429a:	40000613          	li	a2,1024
    8000429e:	05850593          	addi	a1,a0,88
    800042a2:	05848513          	addi	a0,s1,88
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	b22080e7          	jalr	-1246(ra) # 80000dc8 <memmove>
    bwrite(to);  // write the log
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	da8080e7          	jalr	-600(ra) # 80003058 <bwrite>
    brelse(from);
    800042b8:	854e                	mv	a0,s3
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	ddc080e7          	jalr	-548(ra) # 80003096 <brelse>
    brelse(to);
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	dd2080e7          	jalr	-558(ra) # 80003096 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042cc:	2905                	addiw	s2,s2,1
    800042ce:	0a91                	addi	s5,s5,4
    800042d0:	02ca2783          	lw	a5,44(s4)
    800042d4:	f8f94ee3          	blt	s2,a5,80004270 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042d8:	00000097          	auipc	ra,0x0
    800042dc:	c7a080e7          	jalr	-902(ra) # 80003f52 <write_head>
    install_trans(); // Now install writes to home locations
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	cec080e7          	jalr	-788(ra) # 80003fcc <install_trans>
    log.lh.n = 0;
    800042e8:	0001e797          	auipc	a5,0x1e
    800042ec:	c407a623          	sw	zero,-948(a5) # 80021f34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	c62080e7          	jalr	-926(ra) # 80003f52 <write_head>
    800042f8:	bdfd                	j	800041f6 <end_op+0x52>

00000000800042fa <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042fa:	1101                	addi	sp,sp,-32
    800042fc:	ec06                	sd	ra,24(sp)
    800042fe:	e822                	sd	s0,16(sp)
    80004300:	e426                	sd	s1,8(sp)
    80004302:	e04a                	sd	s2,0(sp)
    80004304:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004306:	0001e717          	auipc	a4,0x1e
    8000430a:	c2e72703          	lw	a4,-978(a4) # 80021f34 <log+0x2c>
    8000430e:	47f5                	li	a5,29
    80004310:	08e7c063          	blt	a5,a4,80004390 <log_write+0x96>
    80004314:	84aa                	mv	s1,a0
    80004316:	0001e797          	auipc	a5,0x1e
    8000431a:	c0e7a783          	lw	a5,-1010(a5) # 80021f24 <log+0x1c>
    8000431e:	37fd                	addiw	a5,a5,-1
    80004320:	06f75863          	bge	a4,a5,80004390 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004324:	0001e797          	auipc	a5,0x1e
    80004328:	c047a783          	lw	a5,-1020(a5) # 80021f28 <log+0x20>
    8000432c:	06f05a63          	blez	a5,800043a0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004330:	0001e917          	auipc	s2,0x1e
    80004334:	bd890913          	addi	s2,s2,-1064 # 80021f08 <log>
    80004338:	854a                	mv	a0,s2
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	932080e7          	jalr	-1742(ra) # 80000c6c <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004342:	02c92603          	lw	a2,44(s2)
    80004346:	06c05563          	blez	a2,800043b0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000434a:	44cc                	lw	a1,12(s1)
    8000434c:	0001e717          	auipc	a4,0x1e
    80004350:	bec70713          	addi	a4,a4,-1044 # 80021f38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004354:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004356:	4314                	lw	a3,0(a4)
    80004358:	04b68d63          	beq	a3,a1,800043b2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000435c:	2785                	addiw	a5,a5,1
    8000435e:	0711                	addi	a4,a4,4
    80004360:	fec79be3          	bne	a5,a2,80004356 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004364:	0621                	addi	a2,a2,8
    80004366:	060a                	slli	a2,a2,0x2
    80004368:	0001e797          	auipc	a5,0x1e
    8000436c:	ba078793          	addi	a5,a5,-1120 # 80021f08 <log>
    80004370:	963e                	add	a2,a2,a5
    80004372:	44dc                	lw	a5,12(s1)
    80004374:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004376:	8526                	mv	a0,s1
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	dbc080e7          	jalr	-580(ra) # 80003134 <bpin>
    log.lh.n++;
    80004380:	0001e717          	auipc	a4,0x1e
    80004384:	b8870713          	addi	a4,a4,-1144 # 80021f08 <log>
    80004388:	575c                	lw	a5,44(a4)
    8000438a:	2785                	addiw	a5,a5,1
    8000438c:	d75c                	sw	a5,44(a4)
    8000438e:	a83d                	j	800043cc <log_write+0xd2>
    panic("too big a transaction");
    80004390:	00004517          	auipc	a0,0x4
    80004394:	2b050513          	addi	a0,a0,688 # 80008640 <syscalls+0x200>
    80004398:	ffffc097          	auipc	ra,0xffffc
    8000439c:	1b0080e7          	jalr	432(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043a0:	00004517          	auipc	a0,0x4
    800043a4:	2b850513          	addi	a0,a0,696 # 80008658 <syscalls+0x218>
    800043a8:	ffffc097          	auipc	ra,0xffffc
    800043ac:	1a0080e7          	jalr	416(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043b0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043b2:	00878713          	addi	a4,a5,8
    800043b6:	00271693          	slli	a3,a4,0x2
    800043ba:	0001e717          	auipc	a4,0x1e
    800043be:	b4e70713          	addi	a4,a4,-1202 # 80021f08 <log>
    800043c2:	9736                	add	a4,a4,a3
    800043c4:	44d4                	lw	a3,12(s1)
    800043c6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043c8:	faf607e3          	beq	a2,a5,80004376 <log_write+0x7c>
  }
  release(&log.lock);
    800043cc:	0001e517          	auipc	a0,0x1e
    800043d0:	b3c50513          	addi	a0,a0,-1220 # 80021f08 <log>
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	94c080e7          	jalr	-1716(ra) # 80000d20 <release>
}
    800043dc:	60e2                	ld	ra,24(sp)
    800043de:	6442                	ld	s0,16(sp)
    800043e0:	64a2                	ld	s1,8(sp)
    800043e2:	6902                	ld	s2,0(sp)
    800043e4:	6105                	addi	sp,sp,32
    800043e6:	8082                	ret

00000000800043e8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043e8:	1101                	addi	sp,sp,-32
    800043ea:	ec06                	sd	ra,24(sp)
    800043ec:	e822                	sd	s0,16(sp)
    800043ee:	e426                	sd	s1,8(sp)
    800043f0:	e04a                	sd	s2,0(sp)
    800043f2:	1000                	addi	s0,sp,32
    800043f4:	84aa                	mv	s1,a0
    800043f6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043f8:	00004597          	auipc	a1,0x4
    800043fc:	28058593          	addi	a1,a1,640 # 80008678 <syscalls+0x238>
    80004400:	0521                	addi	a0,a0,8
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	7da080e7          	jalr	2010(ra) # 80000bdc <initlock>
  lk->name = name;
    8000440a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000440e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004412:	0204a423          	sw	zero,40(s1)
}
    80004416:	60e2                	ld	ra,24(sp)
    80004418:	6442                	ld	s0,16(sp)
    8000441a:	64a2                	ld	s1,8(sp)
    8000441c:	6902                	ld	s2,0(sp)
    8000441e:	6105                	addi	sp,sp,32
    80004420:	8082                	ret

0000000080004422 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004422:	1101                	addi	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	e04a                	sd	s2,0(sp)
    8000442c:	1000                	addi	s0,sp,32
    8000442e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004430:	00850913          	addi	s2,a0,8
    80004434:	854a                	mv	a0,s2
    80004436:	ffffd097          	auipc	ra,0xffffd
    8000443a:	836080e7          	jalr	-1994(ra) # 80000c6c <acquire>
  while (lk->locked) {
    8000443e:	409c                	lw	a5,0(s1)
    80004440:	cb89                	beqz	a5,80004452 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004442:	85ca                	mv	a1,s2
    80004444:	8526                	mv	a0,s1
    80004446:	ffffe097          	auipc	ra,0xffffe
    8000444a:	e00080e7          	jalr	-512(ra) # 80002246 <sleep>
  while (lk->locked) {
    8000444e:	409c                	lw	a5,0(s1)
    80004450:	fbed                	bnez	a5,80004442 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004452:	4785                	li	a5,1
    80004454:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004456:	ffffd097          	auipc	ra,0xffffd
    8000445a:	5e4080e7          	jalr	1508(ra) # 80001a3a <myproc>
    8000445e:	5d1c                	lw	a5,56(a0)
    80004460:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004462:	854a                	mv	a0,s2
    80004464:	ffffd097          	auipc	ra,0xffffd
    80004468:	8bc080e7          	jalr	-1860(ra) # 80000d20 <release>
}
    8000446c:	60e2                	ld	ra,24(sp)
    8000446e:	6442                	ld	s0,16(sp)
    80004470:	64a2                	ld	s1,8(sp)
    80004472:	6902                	ld	s2,0(sp)
    80004474:	6105                	addi	sp,sp,32
    80004476:	8082                	ret

0000000080004478 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004478:	1101                	addi	sp,sp,-32
    8000447a:	ec06                	sd	ra,24(sp)
    8000447c:	e822                	sd	s0,16(sp)
    8000447e:	e426                	sd	s1,8(sp)
    80004480:	e04a                	sd	s2,0(sp)
    80004482:	1000                	addi	s0,sp,32
    80004484:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004486:	00850913          	addi	s2,a0,8
    8000448a:	854a                	mv	a0,s2
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	7e0080e7          	jalr	2016(ra) # 80000c6c <acquire>
  lk->locked = 0;
    80004494:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004498:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000449c:	8526                	mv	a0,s1
    8000449e:	ffffe097          	auipc	ra,0xffffe
    800044a2:	f2e080e7          	jalr	-210(ra) # 800023cc <wakeup>
  release(&lk->lk);
    800044a6:	854a                	mv	a0,s2
    800044a8:	ffffd097          	auipc	ra,0xffffd
    800044ac:	878080e7          	jalr	-1928(ra) # 80000d20 <release>
}
    800044b0:	60e2                	ld	ra,24(sp)
    800044b2:	6442                	ld	s0,16(sp)
    800044b4:	64a2                	ld	s1,8(sp)
    800044b6:	6902                	ld	s2,0(sp)
    800044b8:	6105                	addi	sp,sp,32
    800044ba:	8082                	ret

00000000800044bc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044bc:	7179                	addi	sp,sp,-48
    800044be:	f406                	sd	ra,40(sp)
    800044c0:	f022                	sd	s0,32(sp)
    800044c2:	ec26                	sd	s1,24(sp)
    800044c4:	e84a                	sd	s2,16(sp)
    800044c6:	e44e                	sd	s3,8(sp)
    800044c8:	1800                	addi	s0,sp,48
    800044ca:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044cc:	00850913          	addi	s2,a0,8
    800044d0:	854a                	mv	a0,s2
    800044d2:	ffffc097          	auipc	ra,0xffffc
    800044d6:	79a080e7          	jalr	1946(ra) # 80000c6c <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044da:	409c                	lw	a5,0(s1)
    800044dc:	ef99                	bnez	a5,800044fa <holdingsleep+0x3e>
    800044de:	4481                	li	s1,0
  release(&lk->lk);
    800044e0:	854a                	mv	a0,s2
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	83e080e7          	jalr	-1986(ra) # 80000d20 <release>
  return r;
}
    800044ea:	8526                	mv	a0,s1
    800044ec:	70a2                	ld	ra,40(sp)
    800044ee:	7402                	ld	s0,32(sp)
    800044f0:	64e2                	ld	s1,24(sp)
    800044f2:	6942                	ld	s2,16(sp)
    800044f4:	69a2                	ld	s3,8(sp)
    800044f6:	6145                	addi	sp,sp,48
    800044f8:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044fa:	0284a983          	lw	s3,40(s1)
    800044fe:	ffffd097          	auipc	ra,0xffffd
    80004502:	53c080e7          	jalr	1340(ra) # 80001a3a <myproc>
    80004506:	5d04                	lw	s1,56(a0)
    80004508:	413484b3          	sub	s1,s1,s3
    8000450c:	0014b493          	seqz	s1,s1
    80004510:	bfc1                	j	800044e0 <holdingsleep+0x24>

0000000080004512 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004512:	1141                	addi	sp,sp,-16
    80004514:	e406                	sd	ra,8(sp)
    80004516:	e022                	sd	s0,0(sp)
    80004518:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000451a:	00004597          	auipc	a1,0x4
    8000451e:	16e58593          	addi	a1,a1,366 # 80008688 <syscalls+0x248>
    80004522:	0001e517          	auipc	a0,0x1e
    80004526:	b2e50513          	addi	a0,a0,-1234 # 80022050 <ftable>
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	6b2080e7          	jalr	1714(ra) # 80000bdc <initlock>
}
    80004532:	60a2                	ld	ra,8(sp)
    80004534:	6402                	ld	s0,0(sp)
    80004536:	0141                	addi	sp,sp,16
    80004538:	8082                	ret

000000008000453a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000453a:	1101                	addi	sp,sp,-32
    8000453c:	ec06                	sd	ra,24(sp)
    8000453e:	e822                	sd	s0,16(sp)
    80004540:	e426                	sd	s1,8(sp)
    80004542:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004544:	0001e517          	auipc	a0,0x1e
    80004548:	b0c50513          	addi	a0,a0,-1268 # 80022050 <ftable>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	720080e7          	jalr	1824(ra) # 80000c6c <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004554:	0001e497          	auipc	s1,0x1e
    80004558:	b1448493          	addi	s1,s1,-1260 # 80022068 <ftable+0x18>
    8000455c:	0001f717          	auipc	a4,0x1f
    80004560:	aac70713          	addi	a4,a4,-1364 # 80023008 <ftable+0xfb8>
    if(f->ref == 0){
    80004564:	40dc                	lw	a5,4(s1)
    80004566:	cf99                	beqz	a5,80004584 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004568:	02848493          	addi	s1,s1,40
    8000456c:	fee49ce3          	bne	s1,a4,80004564 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004570:	0001e517          	auipc	a0,0x1e
    80004574:	ae050513          	addi	a0,a0,-1312 # 80022050 <ftable>
    80004578:	ffffc097          	auipc	ra,0xffffc
    8000457c:	7a8080e7          	jalr	1960(ra) # 80000d20 <release>
  return 0;
    80004580:	4481                	li	s1,0
    80004582:	a819                	j	80004598 <filealloc+0x5e>
      f->ref = 1;
    80004584:	4785                	li	a5,1
    80004586:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004588:	0001e517          	auipc	a0,0x1e
    8000458c:	ac850513          	addi	a0,a0,-1336 # 80022050 <ftable>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	790080e7          	jalr	1936(ra) # 80000d20 <release>
}
    80004598:	8526                	mv	a0,s1
    8000459a:	60e2                	ld	ra,24(sp)
    8000459c:	6442                	ld	s0,16(sp)
    8000459e:	64a2                	ld	s1,8(sp)
    800045a0:	6105                	addi	sp,sp,32
    800045a2:	8082                	ret

00000000800045a4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045a4:	1101                	addi	sp,sp,-32
    800045a6:	ec06                	sd	ra,24(sp)
    800045a8:	e822                	sd	s0,16(sp)
    800045aa:	e426                	sd	s1,8(sp)
    800045ac:	1000                	addi	s0,sp,32
    800045ae:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045b0:	0001e517          	auipc	a0,0x1e
    800045b4:	aa050513          	addi	a0,a0,-1376 # 80022050 <ftable>
    800045b8:	ffffc097          	auipc	ra,0xffffc
    800045bc:	6b4080e7          	jalr	1716(ra) # 80000c6c <acquire>
  if(f->ref < 1)
    800045c0:	40dc                	lw	a5,4(s1)
    800045c2:	02f05263          	blez	a5,800045e6 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045c6:	2785                	addiw	a5,a5,1
    800045c8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045ca:	0001e517          	auipc	a0,0x1e
    800045ce:	a8650513          	addi	a0,a0,-1402 # 80022050 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	74e080e7          	jalr	1870(ra) # 80000d20 <release>
  return f;
}
    800045da:	8526                	mv	a0,s1
    800045dc:	60e2                	ld	ra,24(sp)
    800045de:	6442                	ld	s0,16(sp)
    800045e0:	64a2                	ld	s1,8(sp)
    800045e2:	6105                	addi	sp,sp,32
    800045e4:	8082                	ret
    panic("filedup");
    800045e6:	00004517          	auipc	a0,0x4
    800045ea:	0aa50513          	addi	a0,a0,170 # 80008690 <syscalls+0x250>
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	f5a080e7          	jalr	-166(ra) # 80000548 <panic>

00000000800045f6 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045f6:	7139                	addi	sp,sp,-64
    800045f8:	fc06                	sd	ra,56(sp)
    800045fa:	f822                	sd	s0,48(sp)
    800045fc:	f426                	sd	s1,40(sp)
    800045fe:	f04a                	sd	s2,32(sp)
    80004600:	ec4e                	sd	s3,24(sp)
    80004602:	e852                	sd	s4,16(sp)
    80004604:	e456                	sd	s5,8(sp)
    80004606:	0080                	addi	s0,sp,64
    80004608:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000460a:	0001e517          	auipc	a0,0x1e
    8000460e:	a4650513          	addi	a0,a0,-1466 # 80022050 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	65a080e7          	jalr	1626(ra) # 80000c6c <acquire>
  if(f->ref < 1)
    8000461a:	40dc                	lw	a5,4(s1)
    8000461c:	06f05163          	blez	a5,8000467e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004620:	37fd                	addiw	a5,a5,-1
    80004622:	0007871b          	sext.w	a4,a5
    80004626:	c0dc                	sw	a5,4(s1)
    80004628:	06e04363          	bgtz	a4,8000468e <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000462c:	0004a903          	lw	s2,0(s1)
    80004630:	0094ca83          	lbu	s5,9(s1)
    80004634:	0104ba03          	ld	s4,16(s1)
    80004638:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000463c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004640:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004644:	0001e517          	auipc	a0,0x1e
    80004648:	a0c50513          	addi	a0,a0,-1524 # 80022050 <ftable>
    8000464c:	ffffc097          	auipc	ra,0xffffc
    80004650:	6d4080e7          	jalr	1748(ra) # 80000d20 <release>

  if(ff.type == FD_PIPE){
    80004654:	4785                	li	a5,1
    80004656:	04f90d63          	beq	s2,a5,800046b0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000465a:	3979                	addiw	s2,s2,-2
    8000465c:	4785                	li	a5,1
    8000465e:	0527e063          	bltu	a5,s2,8000469e <fileclose+0xa8>
    begin_op();
    80004662:	00000097          	auipc	ra,0x0
    80004666:	ac2080e7          	jalr	-1342(ra) # 80004124 <begin_op>
    iput(ff.ip);
    8000466a:	854e                	mv	a0,s3
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	2b6080e7          	jalr	694(ra) # 80003922 <iput>
    end_op();
    80004674:	00000097          	auipc	ra,0x0
    80004678:	b30080e7          	jalr	-1232(ra) # 800041a4 <end_op>
    8000467c:	a00d                	j	8000469e <fileclose+0xa8>
    panic("fileclose");
    8000467e:	00004517          	auipc	a0,0x4
    80004682:	01a50513          	addi	a0,a0,26 # 80008698 <syscalls+0x258>
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	ec2080e7          	jalr	-318(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000468e:	0001e517          	auipc	a0,0x1e
    80004692:	9c250513          	addi	a0,a0,-1598 # 80022050 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	68a080e7          	jalr	1674(ra) # 80000d20 <release>
  }
}
    8000469e:	70e2                	ld	ra,56(sp)
    800046a0:	7442                	ld	s0,48(sp)
    800046a2:	74a2                	ld	s1,40(sp)
    800046a4:	7902                	ld	s2,32(sp)
    800046a6:	69e2                	ld	s3,24(sp)
    800046a8:	6a42                	ld	s4,16(sp)
    800046aa:	6aa2                	ld	s5,8(sp)
    800046ac:	6121                	addi	sp,sp,64
    800046ae:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046b0:	85d6                	mv	a1,s5
    800046b2:	8552                	mv	a0,s4
    800046b4:	00000097          	auipc	ra,0x0
    800046b8:	372080e7          	jalr	882(ra) # 80004a26 <pipeclose>
    800046bc:	b7cd                	j	8000469e <fileclose+0xa8>

00000000800046be <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046be:	715d                	addi	sp,sp,-80
    800046c0:	e486                	sd	ra,72(sp)
    800046c2:	e0a2                	sd	s0,64(sp)
    800046c4:	fc26                	sd	s1,56(sp)
    800046c6:	f84a                	sd	s2,48(sp)
    800046c8:	f44e                	sd	s3,40(sp)
    800046ca:	0880                	addi	s0,sp,80
    800046cc:	84aa                	mv	s1,a0
    800046ce:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046d0:	ffffd097          	auipc	ra,0xffffd
    800046d4:	36a080e7          	jalr	874(ra) # 80001a3a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046d8:	409c                	lw	a5,0(s1)
    800046da:	37f9                	addiw	a5,a5,-2
    800046dc:	4705                	li	a4,1
    800046de:	04f76763          	bltu	a4,a5,8000472c <filestat+0x6e>
    800046e2:	892a                	mv	s2,a0
    ilock(f->ip);
    800046e4:	6c88                	ld	a0,24(s1)
    800046e6:	fffff097          	auipc	ra,0xfffff
    800046ea:	082080e7          	jalr	130(ra) # 80003768 <ilock>
    stati(f->ip, &st);
    800046ee:	fb840593          	addi	a1,s0,-72
    800046f2:	6c88                	ld	a0,24(s1)
    800046f4:	fffff097          	auipc	ra,0xfffff
    800046f8:	2fe080e7          	jalr	766(ra) # 800039f2 <stati>
    iunlock(f->ip);
    800046fc:	6c88                	ld	a0,24(s1)
    800046fe:	fffff097          	auipc	ra,0xfffff
    80004702:	12c080e7          	jalr	300(ra) # 8000382a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004706:	46e1                	li	a3,24
    80004708:	fb840613          	addi	a2,s0,-72
    8000470c:	85ce                	mv	a1,s3
    8000470e:	05093503          	ld	a0,80(s2)
    80004712:	ffffd097          	auipc	ra,0xffffd
    80004716:	01c080e7          	jalr	28(ra) # 8000172e <copyout>
    8000471a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000471e:	60a6                	ld	ra,72(sp)
    80004720:	6406                	ld	s0,64(sp)
    80004722:	74e2                	ld	s1,56(sp)
    80004724:	7942                	ld	s2,48(sp)
    80004726:	79a2                	ld	s3,40(sp)
    80004728:	6161                	addi	sp,sp,80
    8000472a:	8082                	ret
  return -1;
    8000472c:	557d                	li	a0,-1
    8000472e:	bfc5                	j	8000471e <filestat+0x60>

0000000080004730 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004730:	7179                	addi	sp,sp,-48
    80004732:	f406                	sd	ra,40(sp)
    80004734:	f022                	sd	s0,32(sp)
    80004736:	ec26                	sd	s1,24(sp)
    80004738:	e84a                	sd	s2,16(sp)
    8000473a:	e44e                	sd	s3,8(sp)
    8000473c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000473e:	00854783          	lbu	a5,8(a0)
    80004742:	c3d5                	beqz	a5,800047e6 <fileread+0xb6>
    80004744:	84aa                	mv	s1,a0
    80004746:	89ae                	mv	s3,a1
    80004748:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000474a:	411c                	lw	a5,0(a0)
    8000474c:	4705                	li	a4,1
    8000474e:	04e78963          	beq	a5,a4,800047a0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004752:	470d                	li	a4,3
    80004754:	04e78d63          	beq	a5,a4,800047ae <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004758:	4709                	li	a4,2
    8000475a:	06e79e63          	bne	a5,a4,800047d6 <fileread+0xa6>
    ilock(f->ip);
    8000475e:	6d08                	ld	a0,24(a0)
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	008080e7          	jalr	8(ra) # 80003768 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004768:	874a                	mv	a4,s2
    8000476a:	5094                	lw	a3,32(s1)
    8000476c:	864e                	mv	a2,s3
    8000476e:	4585                	li	a1,1
    80004770:	6c88                	ld	a0,24(s1)
    80004772:	fffff097          	auipc	ra,0xfffff
    80004776:	2aa080e7          	jalr	682(ra) # 80003a1c <readi>
    8000477a:	892a                	mv	s2,a0
    8000477c:	00a05563          	blez	a0,80004786 <fileread+0x56>
      f->off += r;
    80004780:	509c                	lw	a5,32(s1)
    80004782:	9fa9                	addw	a5,a5,a0
    80004784:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004786:	6c88                	ld	a0,24(s1)
    80004788:	fffff097          	auipc	ra,0xfffff
    8000478c:	0a2080e7          	jalr	162(ra) # 8000382a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004790:	854a                	mv	a0,s2
    80004792:	70a2                	ld	ra,40(sp)
    80004794:	7402                	ld	s0,32(sp)
    80004796:	64e2                	ld	s1,24(sp)
    80004798:	6942                	ld	s2,16(sp)
    8000479a:	69a2                	ld	s3,8(sp)
    8000479c:	6145                	addi	sp,sp,48
    8000479e:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047a0:	6908                	ld	a0,16(a0)
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	418080e7          	jalr	1048(ra) # 80004bba <piperead>
    800047aa:	892a                	mv	s2,a0
    800047ac:	b7d5                	j	80004790 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ae:	02451783          	lh	a5,36(a0)
    800047b2:	03079693          	slli	a3,a5,0x30
    800047b6:	92c1                	srli	a3,a3,0x30
    800047b8:	4725                	li	a4,9
    800047ba:	02d76863          	bltu	a4,a3,800047ea <fileread+0xba>
    800047be:	0792                	slli	a5,a5,0x4
    800047c0:	0001d717          	auipc	a4,0x1d
    800047c4:	7f070713          	addi	a4,a4,2032 # 80021fb0 <devsw>
    800047c8:	97ba                	add	a5,a5,a4
    800047ca:	639c                	ld	a5,0(a5)
    800047cc:	c38d                	beqz	a5,800047ee <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047ce:	4505                	li	a0,1
    800047d0:	9782                	jalr	a5
    800047d2:	892a                	mv	s2,a0
    800047d4:	bf75                	j	80004790 <fileread+0x60>
    panic("fileread");
    800047d6:	00004517          	auipc	a0,0x4
    800047da:	ed250513          	addi	a0,a0,-302 # 800086a8 <syscalls+0x268>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	d6a080e7          	jalr	-662(ra) # 80000548 <panic>
    return -1;
    800047e6:	597d                	li	s2,-1
    800047e8:	b765                	j	80004790 <fileread+0x60>
      return -1;
    800047ea:	597d                	li	s2,-1
    800047ec:	b755                	j	80004790 <fileread+0x60>
    800047ee:	597d                	li	s2,-1
    800047f0:	b745                	j	80004790 <fileread+0x60>

00000000800047f2 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047f2:	00954783          	lbu	a5,9(a0)
    800047f6:	14078563          	beqz	a5,80004940 <filewrite+0x14e>
{
    800047fa:	715d                	addi	sp,sp,-80
    800047fc:	e486                	sd	ra,72(sp)
    800047fe:	e0a2                	sd	s0,64(sp)
    80004800:	fc26                	sd	s1,56(sp)
    80004802:	f84a                	sd	s2,48(sp)
    80004804:	f44e                	sd	s3,40(sp)
    80004806:	f052                	sd	s4,32(sp)
    80004808:	ec56                	sd	s5,24(sp)
    8000480a:	e85a                	sd	s6,16(sp)
    8000480c:	e45e                	sd	s7,8(sp)
    8000480e:	e062                	sd	s8,0(sp)
    80004810:	0880                	addi	s0,sp,80
    80004812:	892a                	mv	s2,a0
    80004814:	8aae                	mv	s5,a1
    80004816:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004818:	411c                	lw	a5,0(a0)
    8000481a:	4705                	li	a4,1
    8000481c:	02e78263          	beq	a5,a4,80004840 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004820:	470d                	li	a4,3
    80004822:	02e78563          	beq	a5,a4,8000484c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004826:	4709                	li	a4,2
    80004828:	10e79463          	bne	a5,a4,80004930 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000482c:	0ec05e63          	blez	a2,80004928 <filewrite+0x136>
    int i = 0;
    80004830:	4981                	li	s3,0
    80004832:	6b05                	lui	s6,0x1
    80004834:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004838:	6b85                	lui	s7,0x1
    8000483a:	c00b8b9b          	addiw	s7,s7,-1024
    8000483e:	a851                	j	800048d2 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004840:	6908                	ld	a0,16(a0)
    80004842:	00000097          	auipc	ra,0x0
    80004846:	254080e7          	jalr	596(ra) # 80004a96 <pipewrite>
    8000484a:	a85d                	j	80004900 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000484c:	02451783          	lh	a5,36(a0)
    80004850:	03079693          	slli	a3,a5,0x30
    80004854:	92c1                	srli	a3,a3,0x30
    80004856:	4725                	li	a4,9
    80004858:	0ed76663          	bltu	a4,a3,80004944 <filewrite+0x152>
    8000485c:	0792                	slli	a5,a5,0x4
    8000485e:	0001d717          	auipc	a4,0x1d
    80004862:	75270713          	addi	a4,a4,1874 # 80021fb0 <devsw>
    80004866:	97ba                	add	a5,a5,a4
    80004868:	679c                	ld	a5,8(a5)
    8000486a:	cff9                	beqz	a5,80004948 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000486c:	4505                	li	a0,1
    8000486e:	9782                	jalr	a5
    80004870:	a841                	j	80004900 <filewrite+0x10e>
    80004872:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004876:	00000097          	auipc	ra,0x0
    8000487a:	8ae080e7          	jalr	-1874(ra) # 80004124 <begin_op>
      ilock(f->ip);
    8000487e:	01893503          	ld	a0,24(s2)
    80004882:	fffff097          	auipc	ra,0xfffff
    80004886:	ee6080e7          	jalr	-282(ra) # 80003768 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000488a:	8762                	mv	a4,s8
    8000488c:	02092683          	lw	a3,32(s2)
    80004890:	01598633          	add	a2,s3,s5
    80004894:	4585                	li	a1,1
    80004896:	01893503          	ld	a0,24(s2)
    8000489a:	fffff097          	auipc	ra,0xfffff
    8000489e:	278080e7          	jalr	632(ra) # 80003b12 <writei>
    800048a2:	84aa                	mv	s1,a0
    800048a4:	02a05f63          	blez	a0,800048e2 <filewrite+0xf0>
        f->off += r;
    800048a8:	02092783          	lw	a5,32(s2)
    800048ac:	9fa9                	addw	a5,a5,a0
    800048ae:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048b2:	01893503          	ld	a0,24(s2)
    800048b6:	fffff097          	auipc	ra,0xfffff
    800048ba:	f74080e7          	jalr	-140(ra) # 8000382a <iunlock>
      end_op();
    800048be:	00000097          	auipc	ra,0x0
    800048c2:	8e6080e7          	jalr	-1818(ra) # 800041a4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048c6:	049c1963          	bne	s8,s1,80004918 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048ca:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048ce:	0349d663          	bge	s3,s4,800048fa <filewrite+0x108>
      int n1 = n - i;
    800048d2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048d6:	84be                	mv	s1,a5
    800048d8:	2781                	sext.w	a5,a5
    800048da:	f8fb5ce3          	bge	s6,a5,80004872 <filewrite+0x80>
    800048de:	84de                	mv	s1,s7
    800048e0:	bf49                	j	80004872 <filewrite+0x80>
      iunlock(f->ip);
    800048e2:	01893503          	ld	a0,24(s2)
    800048e6:	fffff097          	auipc	ra,0xfffff
    800048ea:	f44080e7          	jalr	-188(ra) # 8000382a <iunlock>
      end_op();
    800048ee:	00000097          	auipc	ra,0x0
    800048f2:	8b6080e7          	jalr	-1866(ra) # 800041a4 <end_op>
      if(r < 0)
    800048f6:	fc04d8e3          	bgez	s1,800048c6 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048fa:	8552                	mv	a0,s4
    800048fc:	033a1863          	bne	s4,s3,8000492c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004900:	60a6                	ld	ra,72(sp)
    80004902:	6406                	ld	s0,64(sp)
    80004904:	74e2                	ld	s1,56(sp)
    80004906:	7942                	ld	s2,48(sp)
    80004908:	79a2                	ld	s3,40(sp)
    8000490a:	7a02                	ld	s4,32(sp)
    8000490c:	6ae2                	ld	s5,24(sp)
    8000490e:	6b42                	ld	s6,16(sp)
    80004910:	6ba2                	ld	s7,8(sp)
    80004912:	6c02                	ld	s8,0(sp)
    80004914:	6161                	addi	sp,sp,80
    80004916:	8082                	ret
        panic("short filewrite");
    80004918:	00004517          	auipc	a0,0x4
    8000491c:	da050513          	addi	a0,a0,-608 # 800086b8 <syscalls+0x278>
    80004920:	ffffc097          	auipc	ra,0xffffc
    80004924:	c28080e7          	jalr	-984(ra) # 80000548 <panic>
    int i = 0;
    80004928:	4981                	li	s3,0
    8000492a:	bfc1                	j	800048fa <filewrite+0x108>
    ret = (i == n ? n : -1);
    8000492c:	557d                	li	a0,-1
    8000492e:	bfc9                	j	80004900 <filewrite+0x10e>
    panic("filewrite");
    80004930:	00004517          	auipc	a0,0x4
    80004934:	d9850513          	addi	a0,a0,-616 # 800086c8 <syscalls+0x288>
    80004938:	ffffc097          	auipc	ra,0xffffc
    8000493c:	c10080e7          	jalr	-1008(ra) # 80000548 <panic>
    return -1;
    80004940:	557d                	li	a0,-1
}
    80004942:	8082                	ret
      return -1;
    80004944:	557d                	li	a0,-1
    80004946:	bf6d                	j	80004900 <filewrite+0x10e>
    80004948:	557d                	li	a0,-1
    8000494a:	bf5d                	j	80004900 <filewrite+0x10e>

000000008000494c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000494c:	7179                	addi	sp,sp,-48
    8000494e:	f406                	sd	ra,40(sp)
    80004950:	f022                	sd	s0,32(sp)
    80004952:	ec26                	sd	s1,24(sp)
    80004954:	e84a                	sd	s2,16(sp)
    80004956:	e44e                	sd	s3,8(sp)
    80004958:	e052                	sd	s4,0(sp)
    8000495a:	1800                	addi	s0,sp,48
    8000495c:	84aa                	mv	s1,a0
    8000495e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004960:	0005b023          	sd	zero,0(a1)
    80004964:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	bd2080e7          	jalr	-1070(ra) # 8000453a <filealloc>
    80004970:	e088                	sd	a0,0(s1)
    80004972:	c551                	beqz	a0,800049fe <pipealloc+0xb2>
    80004974:	00000097          	auipc	ra,0x0
    80004978:	bc6080e7          	jalr	-1082(ra) # 8000453a <filealloc>
    8000497c:	00aa3023          	sd	a0,0(s4)
    80004980:	c92d                	beqz	a0,800049f2 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004982:	ffffc097          	auipc	ra,0xffffc
    80004986:	1fa080e7          	jalr	506(ra) # 80000b7c <kalloc>
    8000498a:	892a                	mv	s2,a0
    8000498c:	c125                	beqz	a0,800049ec <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000498e:	4985                	li	s3,1
    80004990:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004994:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004998:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000499c:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049a0:	00004597          	auipc	a1,0x4
    800049a4:	d3858593          	addi	a1,a1,-712 # 800086d8 <syscalls+0x298>
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	234080e7          	jalr	564(ra) # 80000bdc <initlock>
  (*f0)->type = FD_PIPE;
    800049b0:	609c                	ld	a5,0(s1)
    800049b2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049b6:	609c                	ld	a5,0(s1)
    800049b8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049bc:	609c                	ld	a5,0(s1)
    800049be:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049c2:	609c                	ld	a5,0(s1)
    800049c4:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049c8:	000a3783          	ld	a5,0(s4)
    800049cc:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049d0:	000a3783          	ld	a5,0(s4)
    800049d4:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049d8:	000a3783          	ld	a5,0(s4)
    800049dc:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049e0:	000a3783          	ld	a5,0(s4)
    800049e4:	0127b823          	sd	s2,16(a5)
  return 0;
    800049e8:	4501                	li	a0,0
    800049ea:	a025                	j	80004a12 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049ec:	6088                	ld	a0,0(s1)
    800049ee:	e501                	bnez	a0,800049f6 <pipealloc+0xaa>
    800049f0:	a039                	j	800049fe <pipealloc+0xb2>
    800049f2:	6088                	ld	a0,0(s1)
    800049f4:	c51d                	beqz	a0,80004a22 <pipealloc+0xd6>
    fileclose(*f0);
    800049f6:	00000097          	auipc	ra,0x0
    800049fa:	c00080e7          	jalr	-1024(ra) # 800045f6 <fileclose>
  if(*f1)
    800049fe:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a02:	557d                	li	a0,-1
  if(*f1)
    80004a04:	c799                	beqz	a5,80004a12 <pipealloc+0xc6>
    fileclose(*f1);
    80004a06:	853e                	mv	a0,a5
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	bee080e7          	jalr	-1042(ra) # 800045f6 <fileclose>
  return -1;
    80004a10:	557d                	li	a0,-1
}
    80004a12:	70a2                	ld	ra,40(sp)
    80004a14:	7402                	ld	s0,32(sp)
    80004a16:	64e2                	ld	s1,24(sp)
    80004a18:	6942                	ld	s2,16(sp)
    80004a1a:	69a2                	ld	s3,8(sp)
    80004a1c:	6a02                	ld	s4,0(sp)
    80004a1e:	6145                	addi	sp,sp,48
    80004a20:	8082                	ret
  return -1;
    80004a22:	557d                	li	a0,-1
    80004a24:	b7fd                	j	80004a12 <pipealloc+0xc6>

0000000080004a26 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a26:	1101                	addi	sp,sp,-32
    80004a28:	ec06                	sd	ra,24(sp)
    80004a2a:	e822                	sd	s0,16(sp)
    80004a2c:	e426                	sd	s1,8(sp)
    80004a2e:	e04a                	sd	s2,0(sp)
    80004a30:	1000                	addi	s0,sp,32
    80004a32:	84aa                	mv	s1,a0
    80004a34:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a36:	ffffc097          	auipc	ra,0xffffc
    80004a3a:	236080e7          	jalr	566(ra) # 80000c6c <acquire>
  if(writable){
    80004a3e:	02090d63          	beqz	s2,80004a78 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a42:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a46:	21848513          	addi	a0,s1,536
    80004a4a:	ffffe097          	auipc	ra,0xffffe
    80004a4e:	982080e7          	jalr	-1662(ra) # 800023cc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a52:	2204b783          	ld	a5,544(s1)
    80004a56:	eb95                	bnez	a5,80004a8a <pipeclose+0x64>
    release(&pi->lock);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	2c6080e7          	jalr	710(ra) # 80000d20 <release>
    kfree((char*)pi);
    80004a62:	8526                	mv	a0,s1
    80004a64:	ffffc097          	auipc	ra,0xffffc
    80004a68:	01c080e7          	jalr	28(ra) # 80000a80 <kfree>
  } else
    release(&pi->lock);
}
    80004a6c:	60e2                	ld	ra,24(sp)
    80004a6e:	6442                	ld	s0,16(sp)
    80004a70:	64a2                	ld	s1,8(sp)
    80004a72:	6902                	ld	s2,0(sp)
    80004a74:	6105                	addi	sp,sp,32
    80004a76:	8082                	ret
    pi->readopen = 0;
    80004a78:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a7c:	21c48513          	addi	a0,s1,540
    80004a80:	ffffe097          	auipc	ra,0xffffe
    80004a84:	94c080e7          	jalr	-1716(ra) # 800023cc <wakeup>
    80004a88:	b7e9                	j	80004a52 <pipeclose+0x2c>
    release(&pi->lock);
    80004a8a:	8526                	mv	a0,s1
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	294080e7          	jalr	660(ra) # 80000d20 <release>
}
    80004a94:	bfe1                	j	80004a6c <pipeclose+0x46>

0000000080004a96 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a96:	7119                	addi	sp,sp,-128
    80004a98:	fc86                	sd	ra,120(sp)
    80004a9a:	f8a2                	sd	s0,112(sp)
    80004a9c:	f4a6                	sd	s1,104(sp)
    80004a9e:	f0ca                	sd	s2,96(sp)
    80004aa0:	ecce                	sd	s3,88(sp)
    80004aa2:	e8d2                	sd	s4,80(sp)
    80004aa4:	e4d6                	sd	s5,72(sp)
    80004aa6:	e0da                	sd	s6,64(sp)
    80004aa8:	fc5e                	sd	s7,56(sp)
    80004aaa:	f862                	sd	s8,48(sp)
    80004aac:	f466                	sd	s9,40(sp)
    80004aae:	f06a                	sd	s10,32(sp)
    80004ab0:	ec6e                	sd	s11,24(sp)
    80004ab2:	0100                	addi	s0,sp,128
    80004ab4:	84aa                	mv	s1,a0
    80004ab6:	8cae                	mv	s9,a1
    80004ab8:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004aba:	ffffd097          	auipc	ra,0xffffd
    80004abe:	f80080e7          	jalr	-128(ra) # 80001a3a <myproc>
    80004ac2:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ac4:	8526                	mv	a0,s1
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	1a6080e7          	jalr	422(ra) # 80000c6c <acquire>
  for(i = 0; i < n; i++){
    80004ace:	0d605963          	blez	s6,80004ba0 <pipewrite+0x10a>
    80004ad2:	89a6                	mv	s3,s1
    80004ad4:	3b7d                	addiw	s6,s6,-1
    80004ad6:	1b02                	slli	s6,s6,0x20
    80004ad8:	020b5b13          	srli	s6,s6,0x20
    80004adc:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ade:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ae2:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae6:	5dfd                	li	s11,-1
    80004ae8:	000b8d1b          	sext.w	s10,s7
    80004aec:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004aee:	2184a783          	lw	a5,536(s1)
    80004af2:	21c4a703          	lw	a4,540(s1)
    80004af6:	2007879b          	addiw	a5,a5,512
    80004afa:	02f71b63          	bne	a4,a5,80004b30 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004afe:	2204a783          	lw	a5,544(s1)
    80004b02:	cbad                	beqz	a5,80004b74 <pipewrite+0xde>
    80004b04:	03092783          	lw	a5,48(s2)
    80004b08:	e7b5                	bnez	a5,80004b74 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b0a:	8556                	mv	a0,s5
    80004b0c:	ffffe097          	auipc	ra,0xffffe
    80004b10:	8c0080e7          	jalr	-1856(ra) # 800023cc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b14:	85ce                	mv	a1,s3
    80004b16:	8552                	mv	a0,s4
    80004b18:	ffffd097          	auipc	ra,0xffffd
    80004b1c:	72e080e7          	jalr	1838(ra) # 80002246 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b20:	2184a783          	lw	a5,536(s1)
    80004b24:	21c4a703          	lw	a4,540(s1)
    80004b28:	2007879b          	addiw	a5,a5,512
    80004b2c:	fcf709e3          	beq	a4,a5,80004afe <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b30:	4685                	li	a3,1
    80004b32:	019b8633          	add	a2,s7,s9
    80004b36:	f8f40593          	addi	a1,s0,-113
    80004b3a:	05093503          	ld	a0,80(s2)
    80004b3e:	ffffd097          	auipc	ra,0xffffd
    80004b42:	c7c080e7          	jalr	-900(ra) # 800017ba <copyin>
    80004b46:	05b50e63          	beq	a0,s11,80004ba2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b4a:	21c4a783          	lw	a5,540(s1)
    80004b4e:	0017871b          	addiw	a4,a5,1
    80004b52:	20e4ae23          	sw	a4,540(s1)
    80004b56:	1ff7f793          	andi	a5,a5,511
    80004b5a:	97a6                	add	a5,a5,s1
    80004b5c:	f8f44703          	lbu	a4,-113(s0)
    80004b60:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b64:	001d0c1b          	addiw	s8,s10,1
    80004b68:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b6c:	036b8b63          	beq	s7,s6,80004ba2 <pipewrite+0x10c>
    80004b70:	8bbe                	mv	s7,a5
    80004b72:	bf9d                	j	80004ae8 <pipewrite+0x52>
        release(&pi->lock);
    80004b74:	8526                	mv	a0,s1
    80004b76:	ffffc097          	auipc	ra,0xffffc
    80004b7a:	1aa080e7          	jalr	426(ra) # 80000d20 <release>
        return -1;
    80004b7e:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b80:	8562                	mv	a0,s8
    80004b82:	70e6                	ld	ra,120(sp)
    80004b84:	7446                	ld	s0,112(sp)
    80004b86:	74a6                	ld	s1,104(sp)
    80004b88:	7906                	ld	s2,96(sp)
    80004b8a:	69e6                	ld	s3,88(sp)
    80004b8c:	6a46                	ld	s4,80(sp)
    80004b8e:	6aa6                	ld	s5,72(sp)
    80004b90:	6b06                	ld	s6,64(sp)
    80004b92:	7be2                	ld	s7,56(sp)
    80004b94:	7c42                	ld	s8,48(sp)
    80004b96:	7ca2                	ld	s9,40(sp)
    80004b98:	7d02                	ld	s10,32(sp)
    80004b9a:	6de2                	ld	s11,24(sp)
    80004b9c:	6109                	addi	sp,sp,128
    80004b9e:	8082                	ret
  for(i = 0; i < n; i++){
    80004ba0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004ba2:	21848513          	addi	a0,s1,536
    80004ba6:	ffffe097          	auipc	ra,0xffffe
    80004baa:	826080e7          	jalr	-2010(ra) # 800023cc <wakeup>
  release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	170080e7          	jalr	368(ra) # 80000d20 <release>
  return i;
    80004bb8:	b7e1                	j	80004b80 <pipewrite+0xea>

0000000080004bba <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bba:	715d                	addi	sp,sp,-80
    80004bbc:	e486                	sd	ra,72(sp)
    80004bbe:	e0a2                	sd	s0,64(sp)
    80004bc0:	fc26                	sd	s1,56(sp)
    80004bc2:	f84a                	sd	s2,48(sp)
    80004bc4:	f44e                	sd	s3,40(sp)
    80004bc6:	f052                	sd	s4,32(sp)
    80004bc8:	ec56                	sd	s5,24(sp)
    80004bca:	e85a                	sd	s6,16(sp)
    80004bcc:	0880                	addi	s0,sp,80
    80004bce:	84aa                	mv	s1,a0
    80004bd0:	892e                	mv	s2,a1
    80004bd2:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd4:	ffffd097          	auipc	ra,0xffffd
    80004bd8:	e66080e7          	jalr	-410(ra) # 80001a3a <myproc>
    80004bdc:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bde:	8b26                	mv	s6,s1
    80004be0:	8526                	mv	a0,s1
    80004be2:	ffffc097          	auipc	ra,0xffffc
    80004be6:	08a080e7          	jalr	138(ra) # 80000c6c <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bea:	2184a703          	lw	a4,536(s1)
    80004bee:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bf6:	02f71463          	bne	a4,a5,80004c1e <piperead+0x64>
    80004bfa:	2244a783          	lw	a5,548(s1)
    80004bfe:	c385                	beqz	a5,80004c1e <piperead+0x64>
    if(pr->killed){
    80004c00:	030a2783          	lw	a5,48(s4)
    80004c04:	ebc1                	bnez	a5,80004c94 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c06:	85da                	mv	a1,s6
    80004c08:	854e                	mv	a0,s3
    80004c0a:	ffffd097          	auipc	ra,0xffffd
    80004c0e:	63c080e7          	jalr	1596(ra) # 80002246 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c12:	2184a703          	lw	a4,536(s1)
    80004c16:	21c4a783          	lw	a5,540(s1)
    80004c1a:	fef700e3          	beq	a4,a5,80004bfa <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1e:	09505263          	blez	s5,80004ca2 <piperead+0xe8>
    80004c22:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c24:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c26:	2184a783          	lw	a5,536(s1)
    80004c2a:	21c4a703          	lw	a4,540(s1)
    80004c2e:	02f70d63          	beq	a4,a5,80004c68 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c32:	0017871b          	addiw	a4,a5,1
    80004c36:	20e4ac23          	sw	a4,536(s1)
    80004c3a:	1ff7f793          	andi	a5,a5,511
    80004c3e:	97a6                	add	a5,a5,s1
    80004c40:	0187c783          	lbu	a5,24(a5)
    80004c44:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c48:	4685                	li	a3,1
    80004c4a:	fbf40613          	addi	a2,s0,-65
    80004c4e:	85ca                	mv	a1,s2
    80004c50:	050a3503          	ld	a0,80(s4)
    80004c54:	ffffd097          	auipc	ra,0xffffd
    80004c58:	ada080e7          	jalr	-1318(ra) # 8000172e <copyout>
    80004c5c:	01650663          	beq	a0,s6,80004c68 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c60:	2985                	addiw	s3,s3,1
    80004c62:	0905                	addi	s2,s2,1
    80004c64:	fd3a91e3          	bne	s5,s3,80004c26 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	760080e7          	jalr	1888(ra) # 800023cc <wakeup>
  release(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	0aa080e7          	jalr	170(ra) # 80000d20 <release>
  return i;
}
    80004c7e:	854e                	mv	a0,s3
    80004c80:	60a6                	ld	ra,72(sp)
    80004c82:	6406                	ld	s0,64(sp)
    80004c84:	74e2                	ld	s1,56(sp)
    80004c86:	7942                	ld	s2,48(sp)
    80004c88:	79a2                	ld	s3,40(sp)
    80004c8a:	7a02                	ld	s4,32(sp)
    80004c8c:	6ae2                	ld	s5,24(sp)
    80004c8e:	6b42                	ld	s6,16(sp)
    80004c90:	6161                	addi	sp,sp,80
    80004c92:	8082                	ret
      release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	08a080e7          	jalr	138(ra) # 80000d20 <release>
      return -1;
    80004c9e:	59fd                	li	s3,-1
    80004ca0:	bff9                	j	80004c7e <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca2:	4981                	li	s3,0
    80004ca4:	b7d1                	j	80004c68 <piperead+0xae>

0000000080004ca6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ca6:	df010113          	addi	sp,sp,-528
    80004caa:	20113423          	sd	ra,520(sp)
    80004cae:	20813023          	sd	s0,512(sp)
    80004cb2:	ffa6                	sd	s1,504(sp)
    80004cb4:	fbca                	sd	s2,496(sp)
    80004cb6:	f7ce                	sd	s3,488(sp)
    80004cb8:	f3d2                	sd	s4,480(sp)
    80004cba:	efd6                	sd	s5,472(sp)
    80004cbc:	ebda                	sd	s6,464(sp)
    80004cbe:	e7de                	sd	s7,456(sp)
    80004cc0:	e3e2                	sd	s8,448(sp)
    80004cc2:	ff66                	sd	s9,440(sp)
    80004cc4:	fb6a                	sd	s10,432(sp)
    80004cc6:	f76e                	sd	s11,424(sp)
    80004cc8:	0c00                	addi	s0,sp,528
    80004cca:	84aa                	mv	s1,a0
    80004ccc:	dea43c23          	sd	a0,-520(s0)
    80004cd0:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cd4:	ffffd097          	auipc	ra,0xffffd
    80004cd8:	d66080e7          	jalr	-666(ra) # 80001a3a <myproc>
    80004cdc:	892a                	mv	s2,a0

  begin_op();
    80004cde:	fffff097          	auipc	ra,0xfffff
    80004ce2:	446080e7          	jalr	1094(ra) # 80004124 <begin_op>

  if((ip = namei(path)) == 0){
    80004ce6:	8526                	mv	a0,s1
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	230080e7          	jalr	560(ra) # 80003f18 <namei>
    80004cf0:	c92d                	beqz	a0,80004d62 <exec+0xbc>
    80004cf2:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cf4:	fffff097          	auipc	ra,0xfffff
    80004cf8:	a74080e7          	jalr	-1420(ra) # 80003768 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cfc:	04000713          	li	a4,64
    80004d00:	4681                	li	a3,0
    80004d02:	e4840613          	addi	a2,s0,-440
    80004d06:	4581                	li	a1,0
    80004d08:	8526                	mv	a0,s1
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	d12080e7          	jalr	-750(ra) # 80003a1c <readi>
    80004d12:	04000793          	li	a5,64
    80004d16:	00f51a63          	bne	a0,a5,80004d2a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d1a:	e4842703          	lw	a4,-440(s0)
    80004d1e:	464c47b7          	lui	a5,0x464c4
    80004d22:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d26:	04f70463          	beq	a4,a5,80004d6e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d2a:	8526                	mv	a0,s1
    80004d2c:	fffff097          	auipc	ra,0xfffff
    80004d30:	c9e080e7          	jalr	-866(ra) # 800039ca <iunlockput>
    end_op();
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	470080e7          	jalr	1136(ra) # 800041a4 <end_op>
  }
  return -1;
    80004d3c:	557d                	li	a0,-1
}
    80004d3e:	20813083          	ld	ra,520(sp)
    80004d42:	20013403          	ld	s0,512(sp)
    80004d46:	74fe                	ld	s1,504(sp)
    80004d48:	795e                	ld	s2,496(sp)
    80004d4a:	79be                	ld	s3,488(sp)
    80004d4c:	7a1e                	ld	s4,480(sp)
    80004d4e:	6afe                	ld	s5,472(sp)
    80004d50:	6b5e                	ld	s6,464(sp)
    80004d52:	6bbe                	ld	s7,456(sp)
    80004d54:	6c1e                	ld	s8,448(sp)
    80004d56:	7cfa                	ld	s9,440(sp)
    80004d58:	7d5a                	ld	s10,432(sp)
    80004d5a:	7dba                	ld	s11,424(sp)
    80004d5c:	21010113          	addi	sp,sp,528
    80004d60:	8082                	ret
    end_op();
    80004d62:	fffff097          	auipc	ra,0xfffff
    80004d66:	442080e7          	jalr	1090(ra) # 800041a4 <end_op>
    return -1;
    80004d6a:	557d                	li	a0,-1
    80004d6c:	bfc9                	j	80004d3e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d6e:	854a                	mv	a0,s2
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	d8e080e7          	jalr	-626(ra) # 80001afe <proc_pagetable>
    80004d78:	8baa                	mv	s7,a0
    80004d7a:	d945                	beqz	a0,80004d2a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d7c:	e6842983          	lw	s3,-408(s0)
    80004d80:	e8045783          	lhu	a5,-384(s0)
    80004d84:	c7ad                	beqz	a5,80004dee <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d86:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d88:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d8a:	6c85                	lui	s9,0x1
    80004d8c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d90:	def43823          	sd	a5,-528(s0)
    80004d94:	a42d                	j	80004fbe <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d96:	00004517          	auipc	a0,0x4
    80004d9a:	94a50513          	addi	a0,a0,-1718 # 800086e0 <syscalls+0x2a0>
    80004d9e:	ffffb097          	auipc	ra,0xffffb
    80004da2:	7aa080e7          	jalr	1962(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004da6:	8756                	mv	a4,s5
    80004da8:	012d86bb          	addw	a3,s11,s2
    80004dac:	4581                	li	a1,0
    80004dae:	8526                	mv	a0,s1
    80004db0:	fffff097          	auipc	ra,0xfffff
    80004db4:	c6c080e7          	jalr	-916(ra) # 80003a1c <readi>
    80004db8:	2501                	sext.w	a0,a0
    80004dba:	1aaa9963          	bne	s5,a0,80004f6c <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dbe:	6785                	lui	a5,0x1
    80004dc0:	0127893b          	addw	s2,a5,s2
    80004dc4:	77fd                	lui	a5,0xfffff
    80004dc6:	01478a3b          	addw	s4,a5,s4
    80004dca:	1f897163          	bgeu	s2,s8,80004fac <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004dce:	02091593          	slli	a1,s2,0x20
    80004dd2:	9181                	srli	a1,a1,0x20
    80004dd4:	95ea                	add	a1,a1,s10
    80004dd6:	855e                	mv	a0,s7
    80004dd8:	ffffc097          	auipc	ra,0xffffc
    80004ddc:	322080e7          	jalr	802(ra) # 800010fa <walkaddr>
    80004de0:	862a                	mv	a2,a0
    if(pa == 0)
    80004de2:	d955                	beqz	a0,80004d96 <exec+0xf0>
      n = PGSIZE;
    80004de4:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004de6:	fd9a70e3          	bgeu	s4,s9,80004da6 <exec+0x100>
      n = sz - i;
    80004dea:	8ad2                	mv	s5,s4
    80004dec:	bf6d                	j	80004da6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dee:	4901                	li	s2,0
  iunlockput(ip);
    80004df0:	8526                	mv	a0,s1
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	bd8080e7          	jalr	-1064(ra) # 800039ca <iunlockput>
  end_op();
    80004dfa:	fffff097          	auipc	ra,0xfffff
    80004dfe:	3aa080e7          	jalr	938(ra) # 800041a4 <end_op>
  p = myproc();
    80004e02:	ffffd097          	auipc	ra,0xffffd
    80004e06:	c38080e7          	jalr	-968(ra) # 80001a3a <myproc>
    80004e0a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e0c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e10:	6785                	lui	a5,0x1
    80004e12:	17fd                	addi	a5,a5,-1
    80004e14:	993e                	add	s2,s2,a5
    80004e16:	757d                	lui	a0,0xfffff
    80004e18:	00a977b3          	and	a5,s2,a0
    80004e1c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e20:	6609                	lui	a2,0x2
    80004e22:	963e                	add	a2,a2,a5
    80004e24:	85be                	mv	a1,a5
    80004e26:	855e                	mv	a0,s7
    80004e28:	ffffc097          	auipc	ra,0xffffc
    80004e2c:	6b6080e7          	jalr	1718(ra) # 800014de <uvmalloc>
    80004e30:	8b2a                	mv	s6,a0
  ip = 0;
    80004e32:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e34:	12050c63          	beqz	a0,80004f6c <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e38:	75f9                	lui	a1,0xffffe
    80004e3a:	95aa                	add	a1,a1,a0
    80004e3c:	855e                	mv	a0,s7
    80004e3e:	ffffd097          	auipc	ra,0xffffd
    80004e42:	8be080e7          	jalr	-1858(ra) # 800016fc <uvmclear>
  stackbase = sp - PGSIZE;
    80004e46:	7c7d                	lui	s8,0xfffff
    80004e48:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e4a:	e0043783          	ld	a5,-512(s0)
    80004e4e:	6388                	ld	a0,0(a5)
    80004e50:	c535                	beqz	a0,80004ebc <exec+0x216>
    80004e52:	e8840993          	addi	s3,s0,-376
    80004e56:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e5a:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e5c:	ffffc097          	auipc	ra,0xffffc
    80004e60:	094080e7          	jalr	148(ra) # 80000ef0 <strlen>
    80004e64:	2505                	addiw	a0,a0,1
    80004e66:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e6a:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e6e:	13896363          	bltu	s2,s8,80004f94 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e72:	e0043d83          	ld	s11,-512(s0)
    80004e76:	000dba03          	ld	s4,0(s11)
    80004e7a:	8552                	mv	a0,s4
    80004e7c:	ffffc097          	auipc	ra,0xffffc
    80004e80:	074080e7          	jalr	116(ra) # 80000ef0 <strlen>
    80004e84:	0015069b          	addiw	a3,a0,1
    80004e88:	8652                	mv	a2,s4
    80004e8a:	85ca                	mv	a1,s2
    80004e8c:	855e                	mv	a0,s7
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	8a0080e7          	jalr	-1888(ra) # 8000172e <copyout>
    80004e96:	10054363          	bltz	a0,80004f9c <exec+0x2f6>
    ustack[argc] = sp;
    80004e9a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e9e:	0485                	addi	s1,s1,1
    80004ea0:	008d8793          	addi	a5,s11,8
    80004ea4:	e0f43023          	sd	a5,-512(s0)
    80004ea8:	008db503          	ld	a0,8(s11)
    80004eac:	c911                	beqz	a0,80004ec0 <exec+0x21a>
    if(argc >= MAXARG)
    80004eae:	09a1                	addi	s3,s3,8
    80004eb0:	fb3c96e3          	bne	s9,s3,80004e5c <exec+0x1b6>
  sz = sz1;
    80004eb4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eb8:	4481                	li	s1,0
    80004eba:	a84d                	j	80004f6c <exec+0x2c6>
  sp = sz;
    80004ebc:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ebe:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ec0:	00349793          	slli	a5,s1,0x3
    80004ec4:	f9040713          	addi	a4,s0,-112
    80004ec8:	97ba                	add	a5,a5,a4
    80004eca:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ece:	00148693          	addi	a3,s1,1
    80004ed2:	068e                	slli	a3,a3,0x3
    80004ed4:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ed8:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004edc:	01897663          	bgeu	s2,s8,80004ee8 <exec+0x242>
  sz = sz1;
    80004ee0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ee4:	4481                	li	s1,0
    80004ee6:	a059                	j	80004f6c <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ee8:	e8840613          	addi	a2,s0,-376
    80004eec:	85ca                	mv	a1,s2
    80004eee:	855e                	mv	a0,s7
    80004ef0:	ffffd097          	auipc	ra,0xffffd
    80004ef4:	83e080e7          	jalr	-1986(ra) # 8000172e <copyout>
    80004ef8:	0a054663          	bltz	a0,80004fa4 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004efc:	058ab783          	ld	a5,88(s5)
    80004f00:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f04:	df843783          	ld	a5,-520(s0)
    80004f08:	0007c703          	lbu	a4,0(a5)
    80004f0c:	cf11                	beqz	a4,80004f28 <exec+0x282>
    80004f0e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f10:	02f00693          	li	a3,47
    80004f14:	a029                	j	80004f1e <exec+0x278>
  for(last=s=path; *s; s++)
    80004f16:	0785                	addi	a5,a5,1
    80004f18:	fff7c703          	lbu	a4,-1(a5)
    80004f1c:	c711                	beqz	a4,80004f28 <exec+0x282>
    if(*s == '/')
    80004f1e:	fed71ce3          	bne	a4,a3,80004f16 <exec+0x270>
      last = s+1;
    80004f22:	def43c23          	sd	a5,-520(s0)
    80004f26:	bfc5                	j	80004f16 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f28:	4641                	li	a2,16
    80004f2a:	df843583          	ld	a1,-520(s0)
    80004f2e:	158a8513          	addi	a0,s5,344
    80004f32:	ffffc097          	auipc	ra,0xffffc
    80004f36:	f8c080e7          	jalr	-116(ra) # 80000ebe <safestrcpy>
  oldpagetable = p->pagetable;
    80004f3a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f3e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f42:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f46:	058ab783          	ld	a5,88(s5)
    80004f4a:	e6043703          	ld	a4,-416(s0)
    80004f4e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f50:	058ab783          	ld	a5,88(s5)
    80004f54:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f58:	85ea                	mv	a1,s10
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	c40080e7          	jalr	-960(ra) # 80001b9a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f62:	0004851b          	sext.w	a0,s1
    80004f66:	bbe1                	j	80004d3e <exec+0x98>
    80004f68:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f6c:	e0843583          	ld	a1,-504(s0)
    80004f70:	855e                	mv	a0,s7
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	c28080e7          	jalr	-984(ra) # 80001b9a <proc_freepagetable>
  if(ip){
    80004f7a:	da0498e3          	bnez	s1,80004d2a <exec+0x84>
  return -1;
    80004f7e:	557d                	li	a0,-1
    80004f80:	bb7d                	j	80004d3e <exec+0x98>
    80004f82:	e1243423          	sd	s2,-504(s0)
    80004f86:	b7dd                	j	80004f6c <exec+0x2c6>
    80004f88:	e1243423          	sd	s2,-504(s0)
    80004f8c:	b7c5                	j	80004f6c <exec+0x2c6>
    80004f8e:	e1243423          	sd	s2,-504(s0)
    80004f92:	bfe9                	j	80004f6c <exec+0x2c6>
  sz = sz1;
    80004f94:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f98:	4481                	li	s1,0
    80004f9a:	bfc9                	j	80004f6c <exec+0x2c6>
  sz = sz1;
    80004f9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa0:	4481                	li	s1,0
    80004fa2:	b7e9                	j	80004f6c <exec+0x2c6>
  sz = sz1;
    80004fa4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa8:	4481                	li	s1,0
    80004faa:	b7c9                	j	80004f6c <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fac:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fb0:	2b05                	addiw	s6,s6,1
    80004fb2:	0389899b          	addiw	s3,s3,56
    80004fb6:	e8045783          	lhu	a5,-384(s0)
    80004fba:	e2fb5be3          	bge	s6,a5,80004df0 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fbe:	2981                	sext.w	s3,s3
    80004fc0:	03800713          	li	a4,56
    80004fc4:	86ce                	mv	a3,s3
    80004fc6:	e1040613          	addi	a2,s0,-496
    80004fca:	4581                	li	a1,0
    80004fcc:	8526                	mv	a0,s1
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	a4e080e7          	jalr	-1458(ra) # 80003a1c <readi>
    80004fd6:	03800793          	li	a5,56
    80004fda:	f8f517e3          	bne	a0,a5,80004f68 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fde:	e1042783          	lw	a5,-496(s0)
    80004fe2:	4705                	li	a4,1
    80004fe4:	fce796e3          	bne	a5,a4,80004fb0 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fe8:	e3843603          	ld	a2,-456(s0)
    80004fec:	e3043783          	ld	a5,-464(s0)
    80004ff0:	f8f669e3          	bltu	a2,a5,80004f82 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004ff4:	e2043783          	ld	a5,-480(s0)
    80004ff8:	963e                	add	a2,a2,a5
    80004ffa:	f8f667e3          	bltu	a2,a5,80004f88 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ffe:	85ca                	mv	a1,s2
    80005000:	855e                	mv	a0,s7
    80005002:	ffffc097          	auipc	ra,0xffffc
    80005006:	4dc080e7          	jalr	1244(ra) # 800014de <uvmalloc>
    8000500a:	e0a43423          	sd	a0,-504(s0)
    8000500e:	d141                	beqz	a0,80004f8e <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005010:	e2043d03          	ld	s10,-480(s0)
    80005014:	df043783          	ld	a5,-528(s0)
    80005018:	00fd77b3          	and	a5,s10,a5
    8000501c:	fba1                	bnez	a5,80004f6c <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000501e:	e1842d83          	lw	s11,-488(s0)
    80005022:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005026:	f80c03e3          	beqz	s8,80004fac <exec+0x306>
    8000502a:	8a62                	mv	s4,s8
    8000502c:	4901                	li	s2,0
    8000502e:	b345                	j	80004dce <exec+0x128>

0000000080005030 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005030:	7179                	addi	sp,sp,-48
    80005032:	f406                	sd	ra,40(sp)
    80005034:	f022                	sd	s0,32(sp)
    80005036:	ec26                	sd	s1,24(sp)
    80005038:	e84a                	sd	s2,16(sp)
    8000503a:	1800                	addi	s0,sp,48
    8000503c:	892e                	mv	s2,a1
    8000503e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005040:	fdc40593          	addi	a1,s0,-36
    80005044:	ffffe097          	auipc	ra,0xffffe
    80005048:	b0a080e7          	jalr	-1270(ra) # 80002b4e <argint>
    8000504c:	04054063          	bltz	a0,8000508c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005050:	fdc42703          	lw	a4,-36(s0)
    80005054:	47bd                	li	a5,15
    80005056:	02e7ed63          	bltu	a5,a4,80005090 <argfd+0x60>
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	9e0080e7          	jalr	-1568(ra) # 80001a3a <myproc>
    80005062:	fdc42703          	lw	a4,-36(s0)
    80005066:	01a70793          	addi	a5,a4,26
    8000506a:	078e                	slli	a5,a5,0x3
    8000506c:	953e                	add	a0,a0,a5
    8000506e:	611c                	ld	a5,0(a0)
    80005070:	c395                	beqz	a5,80005094 <argfd+0x64>
    return -1;
  if(pfd)
    80005072:	00090463          	beqz	s2,8000507a <argfd+0x4a>
    *pfd = fd;
    80005076:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000507a:	4501                	li	a0,0
  if(pf)
    8000507c:	c091                	beqz	s1,80005080 <argfd+0x50>
    *pf = f;
    8000507e:	e09c                	sd	a5,0(s1)
}
    80005080:	70a2                	ld	ra,40(sp)
    80005082:	7402                	ld	s0,32(sp)
    80005084:	64e2                	ld	s1,24(sp)
    80005086:	6942                	ld	s2,16(sp)
    80005088:	6145                	addi	sp,sp,48
    8000508a:	8082                	ret
    return -1;
    8000508c:	557d                	li	a0,-1
    8000508e:	bfcd                	j	80005080 <argfd+0x50>
    return -1;
    80005090:	557d                	li	a0,-1
    80005092:	b7fd                	j	80005080 <argfd+0x50>
    80005094:	557d                	li	a0,-1
    80005096:	b7ed                	j	80005080 <argfd+0x50>

0000000080005098 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005098:	1101                	addi	sp,sp,-32
    8000509a:	ec06                	sd	ra,24(sp)
    8000509c:	e822                	sd	s0,16(sp)
    8000509e:	e426                	sd	s1,8(sp)
    800050a0:	1000                	addi	s0,sp,32
    800050a2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050a4:	ffffd097          	auipc	ra,0xffffd
    800050a8:	996080e7          	jalr	-1642(ra) # 80001a3a <myproc>
    800050ac:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050ae:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd80d0>
    800050b2:	4501                	li	a0,0
    800050b4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050b6:	6398                	ld	a4,0(a5)
    800050b8:	cb19                	beqz	a4,800050ce <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050ba:	2505                	addiw	a0,a0,1
    800050bc:	07a1                	addi	a5,a5,8
    800050be:	fed51ce3          	bne	a0,a3,800050b6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050c2:	557d                	li	a0,-1
}
    800050c4:	60e2                	ld	ra,24(sp)
    800050c6:	6442                	ld	s0,16(sp)
    800050c8:	64a2                	ld	s1,8(sp)
    800050ca:	6105                	addi	sp,sp,32
    800050cc:	8082                	ret
      p->ofile[fd] = f;
    800050ce:	01a50793          	addi	a5,a0,26
    800050d2:	078e                	slli	a5,a5,0x3
    800050d4:	963e                	add	a2,a2,a5
    800050d6:	e204                	sd	s1,0(a2)
      return fd;
    800050d8:	b7f5                	j	800050c4 <fdalloc+0x2c>

00000000800050da <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050da:	715d                	addi	sp,sp,-80
    800050dc:	e486                	sd	ra,72(sp)
    800050de:	e0a2                	sd	s0,64(sp)
    800050e0:	fc26                	sd	s1,56(sp)
    800050e2:	f84a                	sd	s2,48(sp)
    800050e4:	f44e                	sd	s3,40(sp)
    800050e6:	f052                	sd	s4,32(sp)
    800050e8:	ec56                	sd	s5,24(sp)
    800050ea:	0880                	addi	s0,sp,80
    800050ec:	89ae                	mv	s3,a1
    800050ee:	8ab2                	mv	s5,a2
    800050f0:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050f2:	fb040593          	addi	a1,s0,-80
    800050f6:	fffff097          	auipc	ra,0xfffff
    800050fa:	e40080e7          	jalr	-448(ra) # 80003f36 <nameiparent>
    800050fe:	892a                	mv	s2,a0
    80005100:	12050f63          	beqz	a0,8000523e <create+0x164>
    return 0;

  ilock(dp);
    80005104:	ffffe097          	auipc	ra,0xffffe
    80005108:	664080e7          	jalr	1636(ra) # 80003768 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000510c:	4601                	li	a2,0
    8000510e:	fb040593          	addi	a1,s0,-80
    80005112:	854a                	mv	a0,s2
    80005114:	fffff097          	auipc	ra,0xfffff
    80005118:	b32080e7          	jalr	-1230(ra) # 80003c46 <dirlookup>
    8000511c:	84aa                	mv	s1,a0
    8000511e:	c921                	beqz	a0,8000516e <create+0x94>
    iunlockput(dp);
    80005120:	854a                	mv	a0,s2
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	8a8080e7          	jalr	-1880(ra) # 800039ca <iunlockput>
    ilock(ip);
    8000512a:	8526                	mv	a0,s1
    8000512c:	ffffe097          	auipc	ra,0xffffe
    80005130:	63c080e7          	jalr	1596(ra) # 80003768 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005134:	2981                	sext.w	s3,s3
    80005136:	4789                	li	a5,2
    80005138:	02f99463          	bne	s3,a5,80005160 <create+0x86>
    8000513c:	0444d783          	lhu	a5,68(s1)
    80005140:	37f9                	addiw	a5,a5,-2
    80005142:	17c2                	slli	a5,a5,0x30
    80005144:	93c1                	srli	a5,a5,0x30
    80005146:	4705                	li	a4,1
    80005148:	00f76c63          	bltu	a4,a5,80005160 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000514c:	8526                	mv	a0,s1
    8000514e:	60a6                	ld	ra,72(sp)
    80005150:	6406                	ld	s0,64(sp)
    80005152:	74e2                	ld	s1,56(sp)
    80005154:	7942                	ld	s2,48(sp)
    80005156:	79a2                	ld	s3,40(sp)
    80005158:	7a02                	ld	s4,32(sp)
    8000515a:	6ae2                	ld	s5,24(sp)
    8000515c:	6161                	addi	sp,sp,80
    8000515e:	8082                	ret
    iunlockput(ip);
    80005160:	8526                	mv	a0,s1
    80005162:	fffff097          	auipc	ra,0xfffff
    80005166:	868080e7          	jalr	-1944(ra) # 800039ca <iunlockput>
    return 0;
    8000516a:	4481                	li	s1,0
    8000516c:	b7c5                	j	8000514c <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000516e:	85ce                	mv	a1,s3
    80005170:	00092503          	lw	a0,0(s2)
    80005174:	ffffe097          	auipc	ra,0xffffe
    80005178:	45c080e7          	jalr	1116(ra) # 800035d0 <ialloc>
    8000517c:	84aa                	mv	s1,a0
    8000517e:	c529                	beqz	a0,800051c8 <create+0xee>
  ilock(ip);
    80005180:	ffffe097          	auipc	ra,0xffffe
    80005184:	5e8080e7          	jalr	1512(ra) # 80003768 <ilock>
  ip->major = major;
    80005188:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000518c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005190:	4785                	li	a5,1
    80005192:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005196:	8526                	mv	a0,s1
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	506080e7          	jalr	1286(ra) # 8000369e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051a0:	2981                	sext.w	s3,s3
    800051a2:	4785                	li	a5,1
    800051a4:	02f98a63          	beq	s3,a5,800051d8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051a8:	40d0                	lw	a2,4(s1)
    800051aa:	fb040593          	addi	a1,s0,-80
    800051ae:	854a                	mv	a0,s2
    800051b0:	fffff097          	auipc	ra,0xfffff
    800051b4:	ca6080e7          	jalr	-858(ra) # 80003e56 <dirlink>
    800051b8:	06054b63          	bltz	a0,8000522e <create+0x154>
  iunlockput(dp);
    800051bc:	854a                	mv	a0,s2
    800051be:	fffff097          	auipc	ra,0xfffff
    800051c2:	80c080e7          	jalr	-2036(ra) # 800039ca <iunlockput>
  return ip;
    800051c6:	b759                	j	8000514c <create+0x72>
    panic("create: ialloc");
    800051c8:	00003517          	auipc	a0,0x3
    800051cc:	53850513          	addi	a0,a0,1336 # 80008700 <syscalls+0x2c0>
    800051d0:	ffffb097          	auipc	ra,0xffffb
    800051d4:	378080e7          	jalr	888(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051d8:	04a95783          	lhu	a5,74(s2)
    800051dc:	2785                	addiw	a5,a5,1
    800051de:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051e2:	854a                	mv	a0,s2
    800051e4:	ffffe097          	auipc	ra,0xffffe
    800051e8:	4ba080e7          	jalr	1210(ra) # 8000369e <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051ec:	40d0                	lw	a2,4(s1)
    800051ee:	00003597          	auipc	a1,0x3
    800051f2:	52258593          	addi	a1,a1,1314 # 80008710 <syscalls+0x2d0>
    800051f6:	8526                	mv	a0,s1
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	c5e080e7          	jalr	-930(ra) # 80003e56 <dirlink>
    80005200:	00054f63          	bltz	a0,8000521e <create+0x144>
    80005204:	00492603          	lw	a2,4(s2)
    80005208:	00003597          	auipc	a1,0x3
    8000520c:	51058593          	addi	a1,a1,1296 # 80008718 <syscalls+0x2d8>
    80005210:	8526                	mv	a0,s1
    80005212:	fffff097          	auipc	ra,0xfffff
    80005216:	c44080e7          	jalr	-956(ra) # 80003e56 <dirlink>
    8000521a:	f80557e3          	bgez	a0,800051a8 <create+0xce>
      panic("create dots");
    8000521e:	00003517          	auipc	a0,0x3
    80005222:	50250513          	addi	a0,a0,1282 # 80008720 <syscalls+0x2e0>
    80005226:	ffffb097          	auipc	ra,0xffffb
    8000522a:	322080e7          	jalr	802(ra) # 80000548 <panic>
    panic("create: dirlink");
    8000522e:	00003517          	auipc	a0,0x3
    80005232:	50250513          	addi	a0,a0,1282 # 80008730 <syscalls+0x2f0>
    80005236:	ffffb097          	auipc	ra,0xffffb
    8000523a:	312080e7          	jalr	786(ra) # 80000548 <panic>
    return 0;
    8000523e:	84aa                	mv	s1,a0
    80005240:	b731                	j	8000514c <create+0x72>

0000000080005242 <sys_dup>:
{
    80005242:	7179                	addi	sp,sp,-48
    80005244:	f406                	sd	ra,40(sp)
    80005246:	f022                	sd	s0,32(sp)
    80005248:	ec26                	sd	s1,24(sp)
    8000524a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000524c:	fd840613          	addi	a2,s0,-40
    80005250:	4581                	li	a1,0
    80005252:	4501                	li	a0,0
    80005254:	00000097          	auipc	ra,0x0
    80005258:	ddc080e7          	jalr	-548(ra) # 80005030 <argfd>
    return -1;
    8000525c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000525e:	02054363          	bltz	a0,80005284 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005262:	fd843503          	ld	a0,-40(s0)
    80005266:	00000097          	auipc	ra,0x0
    8000526a:	e32080e7          	jalr	-462(ra) # 80005098 <fdalloc>
    8000526e:	84aa                	mv	s1,a0
    return -1;
    80005270:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005272:	00054963          	bltz	a0,80005284 <sys_dup+0x42>
  filedup(f);
    80005276:	fd843503          	ld	a0,-40(s0)
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	32a080e7          	jalr	810(ra) # 800045a4 <filedup>
  return fd;
    80005282:	87a6                	mv	a5,s1
}
    80005284:	853e                	mv	a0,a5
    80005286:	70a2                	ld	ra,40(sp)
    80005288:	7402                	ld	s0,32(sp)
    8000528a:	64e2                	ld	s1,24(sp)
    8000528c:	6145                	addi	sp,sp,48
    8000528e:	8082                	ret

0000000080005290 <sys_read>:
{
    80005290:	7179                	addi	sp,sp,-48
    80005292:	f406                	sd	ra,40(sp)
    80005294:	f022                	sd	s0,32(sp)
    80005296:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005298:	fe840613          	addi	a2,s0,-24
    8000529c:	4581                	li	a1,0
    8000529e:	4501                	li	a0,0
    800052a0:	00000097          	auipc	ra,0x0
    800052a4:	d90080e7          	jalr	-624(ra) # 80005030 <argfd>
    return -1;
    800052a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052aa:	04054163          	bltz	a0,800052ec <sys_read+0x5c>
    800052ae:	fe440593          	addi	a1,s0,-28
    800052b2:	4509                	li	a0,2
    800052b4:	ffffe097          	auipc	ra,0xffffe
    800052b8:	89a080e7          	jalr	-1894(ra) # 80002b4e <argint>
    return -1;
    800052bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052be:	02054763          	bltz	a0,800052ec <sys_read+0x5c>
    800052c2:	fd840593          	addi	a1,s0,-40
    800052c6:	4505                	li	a0,1
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	8a8080e7          	jalr	-1880(ra) # 80002b70 <argaddr>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	00054d63          	bltz	a0,800052ec <sys_read+0x5c>
  return fileread(f, p, n);
    800052d6:	fe442603          	lw	a2,-28(s0)
    800052da:	fd843583          	ld	a1,-40(s0)
    800052de:	fe843503          	ld	a0,-24(s0)
    800052e2:	fffff097          	auipc	ra,0xfffff
    800052e6:	44e080e7          	jalr	1102(ra) # 80004730 <fileread>
    800052ea:	87aa                	mv	a5,a0
}
    800052ec:	853e                	mv	a0,a5
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	6145                	addi	sp,sp,48
    800052f4:	8082                	ret

00000000800052f6 <sys_write>:
{
    800052f6:	7179                	addi	sp,sp,-48
    800052f8:	f406                	sd	ra,40(sp)
    800052fa:	f022                	sd	s0,32(sp)
    800052fc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fe:	fe840613          	addi	a2,s0,-24
    80005302:	4581                	li	a1,0
    80005304:	4501                	li	a0,0
    80005306:	00000097          	auipc	ra,0x0
    8000530a:	d2a080e7          	jalr	-726(ra) # 80005030 <argfd>
    return -1;
    8000530e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005310:	04054163          	bltz	a0,80005352 <sys_write+0x5c>
    80005314:	fe440593          	addi	a1,s0,-28
    80005318:	4509                	li	a0,2
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	834080e7          	jalr	-1996(ra) # 80002b4e <argint>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005324:	02054763          	bltz	a0,80005352 <sys_write+0x5c>
    80005328:	fd840593          	addi	a1,s0,-40
    8000532c:	4505                	li	a0,1
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	842080e7          	jalr	-1982(ra) # 80002b70 <argaddr>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	00054d63          	bltz	a0,80005352 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000533c:	fe442603          	lw	a2,-28(s0)
    80005340:	fd843583          	ld	a1,-40(s0)
    80005344:	fe843503          	ld	a0,-24(s0)
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	4aa080e7          	jalr	1194(ra) # 800047f2 <filewrite>
    80005350:	87aa                	mv	a5,a0
}
    80005352:	853e                	mv	a0,a5
    80005354:	70a2                	ld	ra,40(sp)
    80005356:	7402                	ld	s0,32(sp)
    80005358:	6145                	addi	sp,sp,48
    8000535a:	8082                	ret

000000008000535c <sys_close>:
{
    8000535c:	1101                	addi	sp,sp,-32
    8000535e:	ec06                	sd	ra,24(sp)
    80005360:	e822                	sd	s0,16(sp)
    80005362:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005364:	fe040613          	addi	a2,s0,-32
    80005368:	fec40593          	addi	a1,s0,-20
    8000536c:	4501                	li	a0,0
    8000536e:	00000097          	auipc	ra,0x0
    80005372:	cc2080e7          	jalr	-830(ra) # 80005030 <argfd>
    return -1;
    80005376:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005378:	02054463          	bltz	a0,800053a0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	6be080e7          	jalr	1726(ra) # 80001a3a <myproc>
    80005384:	fec42783          	lw	a5,-20(s0)
    80005388:	07e9                	addi	a5,a5,26
    8000538a:	078e                	slli	a5,a5,0x3
    8000538c:	97aa                	add	a5,a5,a0
    8000538e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005392:	fe043503          	ld	a0,-32(s0)
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	260080e7          	jalr	608(ra) # 800045f6 <fileclose>
  return 0;
    8000539e:	4781                	li	a5,0
}
    800053a0:	853e                	mv	a0,a5
    800053a2:	60e2                	ld	ra,24(sp)
    800053a4:	6442                	ld	s0,16(sp)
    800053a6:	6105                	addi	sp,sp,32
    800053a8:	8082                	ret

00000000800053aa <sys_fstat>:
{
    800053aa:	1101                	addi	sp,sp,-32
    800053ac:	ec06                	sd	ra,24(sp)
    800053ae:	e822                	sd	s0,16(sp)
    800053b0:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053b2:	fe840613          	addi	a2,s0,-24
    800053b6:	4581                	li	a1,0
    800053b8:	4501                	li	a0,0
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	c76080e7          	jalr	-906(ra) # 80005030 <argfd>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c4:	02054563          	bltz	a0,800053ee <sys_fstat+0x44>
    800053c8:	fe040593          	addi	a1,s0,-32
    800053cc:	4505                	li	a0,1
    800053ce:	ffffd097          	auipc	ra,0xffffd
    800053d2:	7a2080e7          	jalr	1954(ra) # 80002b70 <argaddr>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d8:	00054b63          	bltz	a0,800053ee <sys_fstat+0x44>
  return filestat(f, st);
    800053dc:	fe043583          	ld	a1,-32(s0)
    800053e0:	fe843503          	ld	a0,-24(s0)
    800053e4:	fffff097          	auipc	ra,0xfffff
    800053e8:	2da080e7          	jalr	730(ra) # 800046be <filestat>
    800053ec:	87aa                	mv	a5,a0
}
    800053ee:	853e                	mv	a0,a5
    800053f0:	60e2                	ld	ra,24(sp)
    800053f2:	6442                	ld	s0,16(sp)
    800053f4:	6105                	addi	sp,sp,32
    800053f6:	8082                	ret

00000000800053f8 <sys_link>:
{
    800053f8:	7169                	addi	sp,sp,-304
    800053fa:	f606                	sd	ra,296(sp)
    800053fc:	f222                	sd	s0,288(sp)
    800053fe:	ee26                	sd	s1,280(sp)
    80005400:	ea4a                	sd	s2,272(sp)
    80005402:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005404:	08000613          	li	a2,128
    80005408:	ed040593          	addi	a1,s0,-304
    8000540c:	4501                	li	a0,0
    8000540e:	ffffd097          	auipc	ra,0xffffd
    80005412:	784080e7          	jalr	1924(ra) # 80002b92 <argstr>
    return -1;
    80005416:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005418:	10054e63          	bltz	a0,80005534 <sys_link+0x13c>
    8000541c:	08000613          	li	a2,128
    80005420:	f5040593          	addi	a1,s0,-176
    80005424:	4505                	li	a0,1
    80005426:	ffffd097          	auipc	ra,0xffffd
    8000542a:	76c080e7          	jalr	1900(ra) # 80002b92 <argstr>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005430:	10054263          	bltz	a0,80005534 <sys_link+0x13c>
  begin_op();
    80005434:	fffff097          	auipc	ra,0xfffff
    80005438:	cf0080e7          	jalr	-784(ra) # 80004124 <begin_op>
  if((ip = namei(old)) == 0){
    8000543c:	ed040513          	addi	a0,s0,-304
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	ad8080e7          	jalr	-1320(ra) # 80003f18 <namei>
    80005448:	84aa                	mv	s1,a0
    8000544a:	c551                	beqz	a0,800054d6 <sys_link+0xde>
  ilock(ip);
    8000544c:	ffffe097          	auipc	ra,0xffffe
    80005450:	31c080e7          	jalr	796(ra) # 80003768 <ilock>
  if(ip->type == T_DIR){
    80005454:	04449703          	lh	a4,68(s1)
    80005458:	4785                	li	a5,1
    8000545a:	08f70463          	beq	a4,a5,800054e2 <sys_link+0xea>
  ip->nlink++;
    8000545e:	04a4d783          	lhu	a5,74(s1)
    80005462:	2785                	addiw	a5,a5,1
    80005464:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005468:	8526                	mv	a0,s1
    8000546a:	ffffe097          	auipc	ra,0xffffe
    8000546e:	234080e7          	jalr	564(ra) # 8000369e <iupdate>
  iunlock(ip);
    80005472:	8526                	mv	a0,s1
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	3b6080e7          	jalr	950(ra) # 8000382a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000547c:	fd040593          	addi	a1,s0,-48
    80005480:	f5040513          	addi	a0,s0,-176
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	ab2080e7          	jalr	-1358(ra) # 80003f36 <nameiparent>
    8000548c:	892a                	mv	s2,a0
    8000548e:	c935                	beqz	a0,80005502 <sys_link+0x10a>
  ilock(dp);
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	2d8080e7          	jalr	728(ra) # 80003768 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005498:	00092703          	lw	a4,0(s2)
    8000549c:	409c                	lw	a5,0(s1)
    8000549e:	04f71d63          	bne	a4,a5,800054f8 <sys_link+0x100>
    800054a2:	40d0                	lw	a2,4(s1)
    800054a4:	fd040593          	addi	a1,s0,-48
    800054a8:	854a                	mv	a0,s2
    800054aa:	fffff097          	auipc	ra,0xfffff
    800054ae:	9ac080e7          	jalr	-1620(ra) # 80003e56 <dirlink>
    800054b2:	04054363          	bltz	a0,800054f8 <sys_link+0x100>
  iunlockput(dp);
    800054b6:	854a                	mv	a0,s2
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	512080e7          	jalr	1298(ra) # 800039ca <iunlockput>
  iput(ip);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	460080e7          	jalr	1120(ra) # 80003922 <iput>
  end_op();
    800054ca:	fffff097          	auipc	ra,0xfffff
    800054ce:	cda080e7          	jalr	-806(ra) # 800041a4 <end_op>
  return 0;
    800054d2:	4781                	li	a5,0
    800054d4:	a085                	j	80005534 <sys_link+0x13c>
    end_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	cce080e7          	jalr	-818(ra) # 800041a4 <end_op>
    return -1;
    800054de:	57fd                	li	a5,-1
    800054e0:	a891                	j	80005534 <sys_link+0x13c>
    iunlockput(ip);
    800054e2:	8526                	mv	a0,s1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	4e6080e7          	jalr	1254(ra) # 800039ca <iunlockput>
    end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	cb8080e7          	jalr	-840(ra) # 800041a4 <end_op>
    return -1;
    800054f4:	57fd                	li	a5,-1
    800054f6:	a83d                	j	80005534 <sys_link+0x13c>
    iunlockput(dp);
    800054f8:	854a                	mv	a0,s2
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	4d0080e7          	jalr	1232(ra) # 800039ca <iunlockput>
  ilock(ip);
    80005502:	8526                	mv	a0,s1
    80005504:	ffffe097          	auipc	ra,0xffffe
    80005508:	264080e7          	jalr	612(ra) # 80003768 <ilock>
  ip->nlink--;
    8000550c:	04a4d783          	lhu	a5,74(s1)
    80005510:	37fd                	addiw	a5,a5,-1
    80005512:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	186080e7          	jalr	390(ra) # 8000369e <iupdate>
  iunlockput(ip);
    80005520:	8526                	mv	a0,s1
    80005522:	ffffe097          	auipc	ra,0xffffe
    80005526:	4a8080e7          	jalr	1192(ra) # 800039ca <iunlockput>
  end_op();
    8000552a:	fffff097          	auipc	ra,0xfffff
    8000552e:	c7a080e7          	jalr	-902(ra) # 800041a4 <end_op>
  return -1;
    80005532:	57fd                	li	a5,-1
}
    80005534:	853e                	mv	a0,a5
    80005536:	70b2                	ld	ra,296(sp)
    80005538:	7412                	ld	s0,288(sp)
    8000553a:	64f2                	ld	s1,280(sp)
    8000553c:	6952                	ld	s2,272(sp)
    8000553e:	6155                	addi	sp,sp,304
    80005540:	8082                	ret

0000000080005542 <sys_unlink>:
{
    80005542:	7151                	addi	sp,sp,-240
    80005544:	f586                	sd	ra,232(sp)
    80005546:	f1a2                	sd	s0,224(sp)
    80005548:	eda6                	sd	s1,216(sp)
    8000554a:	e9ca                	sd	s2,208(sp)
    8000554c:	e5ce                	sd	s3,200(sp)
    8000554e:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005550:	08000613          	li	a2,128
    80005554:	f3040593          	addi	a1,s0,-208
    80005558:	4501                	li	a0,0
    8000555a:	ffffd097          	auipc	ra,0xffffd
    8000555e:	638080e7          	jalr	1592(ra) # 80002b92 <argstr>
    80005562:	18054163          	bltz	a0,800056e4 <sys_unlink+0x1a2>
  begin_op();
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	bbe080e7          	jalr	-1090(ra) # 80004124 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000556e:	fb040593          	addi	a1,s0,-80
    80005572:	f3040513          	addi	a0,s0,-208
    80005576:	fffff097          	auipc	ra,0xfffff
    8000557a:	9c0080e7          	jalr	-1600(ra) # 80003f36 <nameiparent>
    8000557e:	84aa                	mv	s1,a0
    80005580:	c979                	beqz	a0,80005656 <sys_unlink+0x114>
  ilock(dp);
    80005582:	ffffe097          	auipc	ra,0xffffe
    80005586:	1e6080e7          	jalr	486(ra) # 80003768 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000558a:	00003597          	auipc	a1,0x3
    8000558e:	18658593          	addi	a1,a1,390 # 80008710 <syscalls+0x2d0>
    80005592:	fb040513          	addi	a0,s0,-80
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	696080e7          	jalr	1686(ra) # 80003c2c <namecmp>
    8000559e:	14050a63          	beqz	a0,800056f2 <sys_unlink+0x1b0>
    800055a2:	00003597          	auipc	a1,0x3
    800055a6:	17658593          	addi	a1,a1,374 # 80008718 <syscalls+0x2d8>
    800055aa:	fb040513          	addi	a0,s0,-80
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	67e080e7          	jalr	1662(ra) # 80003c2c <namecmp>
    800055b6:	12050e63          	beqz	a0,800056f2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055ba:	f2c40613          	addi	a2,s0,-212
    800055be:	fb040593          	addi	a1,s0,-80
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	682080e7          	jalr	1666(ra) # 80003c46 <dirlookup>
    800055cc:	892a                	mv	s2,a0
    800055ce:	12050263          	beqz	a0,800056f2 <sys_unlink+0x1b0>
  ilock(ip);
    800055d2:	ffffe097          	auipc	ra,0xffffe
    800055d6:	196080e7          	jalr	406(ra) # 80003768 <ilock>
  if(ip->nlink < 1)
    800055da:	04a91783          	lh	a5,74(s2)
    800055de:	08f05263          	blez	a5,80005662 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055e2:	04491703          	lh	a4,68(s2)
    800055e6:	4785                	li	a5,1
    800055e8:	08f70563          	beq	a4,a5,80005672 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055ec:	4641                	li	a2,16
    800055ee:	4581                	li	a1,0
    800055f0:	fc040513          	addi	a0,s0,-64
    800055f4:	ffffb097          	auipc	ra,0xffffb
    800055f8:	774080e7          	jalr	1908(ra) # 80000d68 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055fc:	4741                	li	a4,16
    800055fe:	f2c42683          	lw	a3,-212(s0)
    80005602:	fc040613          	addi	a2,s0,-64
    80005606:	4581                	li	a1,0
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	508080e7          	jalr	1288(ra) # 80003b12 <writei>
    80005612:	47c1                	li	a5,16
    80005614:	0af51563          	bne	a0,a5,800056be <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005618:	04491703          	lh	a4,68(s2)
    8000561c:	4785                	li	a5,1
    8000561e:	0af70863          	beq	a4,a5,800056ce <sys_unlink+0x18c>
  iunlockput(dp);
    80005622:	8526                	mv	a0,s1
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	3a6080e7          	jalr	934(ra) # 800039ca <iunlockput>
  ip->nlink--;
    8000562c:	04a95783          	lhu	a5,74(s2)
    80005630:	37fd                	addiw	a5,a5,-1
    80005632:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005636:	854a                	mv	a0,s2
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	066080e7          	jalr	102(ra) # 8000369e <iupdate>
  iunlockput(ip);
    80005640:	854a                	mv	a0,s2
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	388080e7          	jalr	904(ra) # 800039ca <iunlockput>
  end_op();
    8000564a:	fffff097          	auipc	ra,0xfffff
    8000564e:	b5a080e7          	jalr	-1190(ra) # 800041a4 <end_op>
  return 0;
    80005652:	4501                	li	a0,0
    80005654:	a84d                	j	80005706 <sys_unlink+0x1c4>
    end_op();
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	b4e080e7          	jalr	-1202(ra) # 800041a4 <end_op>
    return -1;
    8000565e:	557d                	li	a0,-1
    80005660:	a05d                	j	80005706 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005662:	00003517          	auipc	a0,0x3
    80005666:	0de50513          	addi	a0,a0,222 # 80008740 <syscalls+0x300>
    8000566a:	ffffb097          	auipc	ra,0xffffb
    8000566e:	ede080e7          	jalr	-290(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005672:	04c92703          	lw	a4,76(s2)
    80005676:	02000793          	li	a5,32
    8000567a:	f6e7f9e3          	bgeu	a5,a4,800055ec <sys_unlink+0xaa>
    8000567e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005682:	4741                	li	a4,16
    80005684:	86ce                	mv	a3,s3
    80005686:	f1840613          	addi	a2,s0,-232
    8000568a:	4581                	li	a1,0
    8000568c:	854a                	mv	a0,s2
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	38e080e7          	jalr	910(ra) # 80003a1c <readi>
    80005696:	47c1                	li	a5,16
    80005698:	00f51b63          	bne	a0,a5,800056ae <sys_unlink+0x16c>
    if(de.inum != 0)
    8000569c:	f1845783          	lhu	a5,-232(s0)
    800056a0:	e7a1                	bnez	a5,800056e8 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a2:	29c1                	addiw	s3,s3,16
    800056a4:	04c92783          	lw	a5,76(s2)
    800056a8:	fcf9ede3          	bltu	s3,a5,80005682 <sys_unlink+0x140>
    800056ac:	b781                	j	800055ec <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056ae:	00003517          	auipc	a0,0x3
    800056b2:	0aa50513          	addi	a0,a0,170 # 80008758 <syscalls+0x318>
    800056b6:	ffffb097          	auipc	ra,0xffffb
    800056ba:	e92080e7          	jalr	-366(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056be:	00003517          	auipc	a0,0x3
    800056c2:	0b250513          	addi	a0,a0,178 # 80008770 <syscalls+0x330>
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	e82080e7          	jalr	-382(ra) # 80000548 <panic>
    dp->nlink--;
    800056ce:	04a4d783          	lhu	a5,74(s1)
    800056d2:	37fd                	addiw	a5,a5,-1
    800056d4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	fc4080e7          	jalr	-60(ra) # 8000369e <iupdate>
    800056e2:	b781                	j	80005622 <sys_unlink+0xe0>
    return -1;
    800056e4:	557d                	li	a0,-1
    800056e6:	a005                	j	80005706 <sys_unlink+0x1c4>
    iunlockput(ip);
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	2e0080e7          	jalr	736(ra) # 800039ca <iunlockput>
  iunlockput(dp);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	2d6080e7          	jalr	726(ra) # 800039ca <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	aa8080e7          	jalr	-1368(ra) # 800041a4 <end_op>
  return -1;
    80005704:	557d                	li	a0,-1
}
    80005706:	70ae                	ld	ra,232(sp)
    80005708:	740e                	ld	s0,224(sp)
    8000570a:	64ee                	ld	s1,216(sp)
    8000570c:	694e                	ld	s2,208(sp)
    8000570e:	69ae                	ld	s3,200(sp)
    80005710:	616d                	addi	sp,sp,240
    80005712:	8082                	ret

0000000080005714 <sys_open>:

uint64
sys_open(void)
{
    80005714:	7131                	addi	sp,sp,-192
    80005716:	fd06                	sd	ra,184(sp)
    80005718:	f922                	sd	s0,176(sp)
    8000571a:	f526                	sd	s1,168(sp)
    8000571c:	f14a                	sd	s2,160(sp)
    8000571e:	ed4e                	sd	s3,152(sp)
    80005720:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005722:	08000613          	li	a2,128
    80005726:	f5040593          	addi	a1,s0,-176
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	466080e7          	jalr	1126(ra) # 80002b92 <argstr>
    return -1;
    80005734:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005736:	0c054163          	bltz	a0,800057f8 <sys_open+0xe4>
    8000573a:	f4c40593          	addi	a1,s0,-180
    8000573e:	4505                	li	a0,1
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	40e080e7          	jalr	1038(ra) # 80002b4e <argint>
    80005748:	0a054863          	bltz	a0,800057f8 <sys_open+0xe4>

  begin_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	9d8080e7          	jalr	-1576(ra) # 80004124 <begin_op>

  if(omode & O_CREATE){
    80005754:	f4c42783          	lw	a5,-180(s0)
    80005758:	2007f793          	andi	a5,a5,512
    8000575c:	cbdd                	beqz	a5,80005812 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000575e:	4681                	li	a3,0
    80005760:	4601                	li	a2,0
    80005762:	4589                	li	a1,2
    80005764:	f5040513          	addi	a0,s0,-176
    80005768:	00000097          	auipc	ra,0x0
    8000576c:	972080e7          	jalr	-1678(ra) # 800050da <create>
    80005770:	892a                	mv	s2,a0
    if(ip == 0){
    80005772:	c959                	beqz	a0,80005808 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005774:	04491703          	lh	a4,68(s2)
    80005778:	478d                	li	a5,3
    8000577a:	00f71763          	bne	a4,a5,80005788 <sys_open+0x74>
    8000577e:	04695703          	lhu	a4,70(s2)
    80005782:	47a5                	li	a5,9
    80005784:	0ce7ec63          	bltu	a5,a4,8000585c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	db2080e7          	jalr	-590(ra) # 8000453a <filealloc>
    80005790:	89aa                	mv	s3,a0
    80005792:	10050263          	beqz	a0,80005896 <sys_open+0x182>
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	902080e7          	jalr	-1790(ra) # 80005098 <fdalloc>
    8000579e:	84aa                	mv	s1,a0
    800057a0:	0e054663          	bltz	a0,8000588c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057a4:	04491703          	lh	a4,68(s2)
    800057a8:	478d                	li	a5,3
    800057aa:	0cf70463          	beq	a4,a5,80005872 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057ae:	4789                	li	a5,2
    800057b0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057b4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057b8:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057bc:	f4c42783          	lw	a5,-180(s0)
    800057c0:	0017c713          	xori	a4,a5,1
    800057c4:	8b05                	andi	a4,a4,1
    800057c6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057ca:	0037f713          	andi	a4,a5,3
    800057ce:	00e03733          	snez	a4,a4
    800057d2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057d6:	4007f793          	andi	a5,a5,1024
    800057da:	c791                	beqz	a5,800057e6 <sys_open+0xd2>
    800057dc:	04491703          	lh	a4,68(s2)
    800057e0:	4789                	li	a5,2
    800057e2:	08f70f63          	beq	a4,a5,80005880 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057e6:	854a                	mv	a0,s2
    800057e8:	ffffe097          	auipc	ra,0xffffe
    800057ec:	042080e7          	jalr	66(ra) # 8000382a <iunlock>
  end_op();
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	9b4080e7          	jalr	-1612(ra) # 800041a4 <end_op>

  return fd;
}
    800057f8:	8526                	mv	a0,s1
    800057fa:	70ea                	ld	ra,184(sp)
    800057fc:	744a                	ld	s0,176(sp)
    800057fe:	74aa                	ld	s1,168(sp)
    80005800:	790a                	ld	s2,160(sp)
    80005802:	69ea                	ld	s3,152(sp)
    80005804:	6129                	addi	sp,sp,192
    80005806:	8082                	ret
      end_op();
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	99c080e7          	jalr	-1636(ra) # 800041a4 <end_op>
      return -1;
    80005810:	b7e5                	j	800057f8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005812:	f5040513          	addi	a0,s0,-176
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	702080e7          	jalr	1794(ra) # 80003f18 <namei>
    8000581e:	892a                	mv	s2,a0
    80005820:	c905                	beqz	a0,80005850 <sys_open+0x13c>
    ilock(ip);
    80005822:	ffffe097          	auipc	ra,0xffffe
    80005826:	f46080e7          	jalr	-186(ra) # 80003768 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000582a:	04491703          	lh	a4,68(s2)
    8000582e:	4785                	li	a5,1
    80005830:	f4f712e3          	bne	a4,a5,80005774 <sys_open+0x60>
    80005834:	f4c42783          	lw	a5,-180(s0)
    80005838:	dba1                	beqz	a5,80005788 <sys_open+0x74>
      iunlockput(ip);
    8000583a:	854a                	mv	a0,s2
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	18e080e7          	jalr	398(ra) # 800039ca <iunlockput>
      end_op();
    80005844:	fffff097          	auipc	ra,0xfffff
    80005848:	960080e7          	jalr	-1696(ra) # 800041a4 <end_op>
      return -1;
    8000584c:	54fd                	li	s1,-1
    8000584e:	b76d                	j	800057f8 <sys_open+0xe4>
      end_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	954080e7          	jalr	-1708(ra) # 800041a4 <end_op>
      return -1;
    80005858:	54fd                	li	s1,-1
    8000585a:	bf79                	j	800057f8 <sys_open+0xe4>
    iunlockput(ip);
    8000585c:	854a                	mv	a0,s2
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	16c080e7          	jalr	364(ra) # 800039ca <iunlockput>
    end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	93e080e7          	jalr	-1730(ra) # 800041a4 <end_op>
    return -1;
    8000586e:	54fd                	li	s1,-1
    80005870:	b761                	j	800057f8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005872:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005876:	04691783          	lh	a5,70(s2)
    8000587a:	02f99223          	sh	a5,36(s3)
    8000587e:	bf2d                	j	800057b8 <sys_open+0xa4>
    itrunc(ip);
    80005880:	854a                	mv	a0,s2
    80005882:	ffffe097          	auipc	ra,0xffffe
    80005886:	ff4080e7          	jalr	-12(ra) # 80003876 <itrunc>
    8000588a:	bfb1                	j	800057e6 <sys_open+0xd2>
      fileclose(f);
    8000588c:	854e                	mv	a0,s3
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	d68080e7          	jalr	-664(ra) # 800045f6 <fileclose>
    iunlockput(ip);
    80005896:	854a                	mv	a0,s2
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	132080e7          	jalr	306(ra) # 800039ca <iunlockput>
    end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	904080e7          	jalr	-1788(ra) # 800041a4 <end_op>
    return -1;
    800058a8:	54fd                	li	s1,-1
    800058aa:	b7b9                	j	800057f8 <sys_open+0xe4>

00000000800058ac <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058ac:	7175                	addi	sp,sp,-144
    800058ae:	e506                	sd	ra,136(sp)
    800058b0:	e122                	sd	s0,128(sp)
    800058b2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	870080e7          	jalr	-1936(ra) # 80004124 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058bc:	08000613          	li	a2,128
    800058c0:	f7040593          	addi	a1,s0,-144
    800058c4:	4501                	li	a0,0
    800058c6:	ffffd097          	auipc	ra,0xffffd
    800058ca:	2cc080e7          	jalr	716(ra) # 80002b92 <argstr>
    800058ce:	02054963          	bltz	a0,80005900 <sys_mkdir+0x54>
    800058d2:	4681                	li	a3,0
    800058d4:	4601                	li	a2,0
    800058d6:	4585                	li	a1,1
    800058d8:	f7040513          	addi	a0,s0,-144
    800058dc:	fffff097          	auipc	ra,0xfffff
    800058e0:	7fe080e7          	jalr	2046(ra) # 800050da <create>
    800058e4:	cd11                	beqz	a0,80005900 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058e6:	ffffe097          	auipc	ra,0xffffe
    800058ea:	0e4080e7          	jalr	228(ra) # 800039ca <iunlockput>
  end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	8b6080e7          	jalr	-1866(ra) # 800041a4 <end_op>
  return 0;
    800058f6:	4501                	li	a0,0
}
    800058f8:	60aa                	ld	ra,136(sp)
    800058fa:	640a                	ld	s0,128(sp)
    800058fc:	6149                	addi	sp,sp,144
    800058fe:	8082                	ret
    end_op();
    80005900:	fffff097          	auipc	ra,0xfffff
    80005904:	8a4080e7          	jalr	-1884(ra) # 800041a4 <end_op>
    return -1;
    80005908:	557d                	li	a0,-1
    8000590a:	b7fd                	j	800058f8 <sys_mkdir+0x4c>

000000008000590c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000590c:	7135                	addi	sp,sp,-160
    8000590e:	ed06                	sd	ra,152(sp)
    80005910:	e922                	sd	s0,144(sp)
    80005912:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	810080e7          	jalr	-2032(ra) # 80004124 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000591c:	08000613          	li	a2,128
    80005920:	f7040593          	addi	a1,s0,-144
    80005924:	4501                	li	a0,0
    80005926:	ffffd097          	auipc	ra,0xffffd
    8000592a:	26c080e7          	jalr	620(ra) # 80002b92 <argstr>
    8000592e:	04054a63          	bltz	a0,80005982 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005932:	f6c40593          	addi	a1,s0,-148
    80005936:	4505                	li	a0,1
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	216080e7          	jalr	534(ra) # 80002b4e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005940:	04054163          	bltz	a0,80005982 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005944:	f6840593          	addi	a1,s0,-152
    80005948:	4509                	li	a0,2
    8000594a:	ffffd097          	auipc	ra,0xffffd
    8000594e:	204080e7          	jalr	516(ra) # 80002b4e <argint>
     argint(1, &major) < 0 ||
    80005952:	02054863          	bltz	a0,80005982 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005956:	f6841683          	lh	a3,-152(s0)
    8000595a:	f6c41603          	lh	a2,-148(s0)
    8000595e:	458d                	li	a1,3
    80005960:	f7040513          	addi	a0,s0,-144
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	776080e7          	jalr	1910(ra) # 800050da <create>
     argint(2, &minor) < 0 ||
    8000596c:	c919                	beqz	a0,80005982 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	05c080e7          	jalr	92(ra) # 800039ca <iunlockput>
  end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	82e080e7          	jalr	-2002(ra) # 800041a4 <end_op>
  return 0;
    8000597e:	4501                	li	a0,0
    80005980:	a031                	j	8000598c <sys_mknod+0x80>
    end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	822080e7          	jalr	-2014(ra) # 800041a4 <end_op>
    return -1;
    8000598a:	557d                	li	a0,-1
}
    8000598c:	60ea                	ld	ra,152(sp)
    8000598e:	644a                	ld	s0,144(sp)
    80005990:	610d                	addi	sp,sp,160
    80005992:	8082                	ret

0000000080005994 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005994:	7135                	addi	sp,sp,-160
    80005996:	ed06                	sd	ra,152(sp)
    80005998:	e922                	sd	s0,144(sp)
    8000599a:	e526                	sd	s1,136(sp)
    8000599c:	e14a                	sd	s2,128(sp)
    8000599e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059a0:	ffffc097          	auipc	ra,0xffffc
    800059a4:	09a080e7          	jalr	154(ra) # 80001a3a <myproc>
    800059a8:	892a                	mv	s2,a0
  
  begin_op();
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	77a080e7          	jalr	1914(ra) # 80004124 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059b2:	08000613          	li	a2,128
    800059b6:	f6040593          	addi	a1,s0,-160
    800059ba:	4501                	li	a0,0
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	1d6080e7          	jalr	470(ra) # 80002b92 <argstr>
    800059c4:	04054b63          	bltz	a0,80005a1a <sys_chdir+0x86>
    800059c8:	f6040513          	addi	a0,s0,-160
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	54c080e7          	jalr	1356(ra) # 80003f18 <namei>
    800059d4:	84aa                	mv	s1,a0
    800059d6:	c131                	beqz	a0,80005a1a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	d90080e7          	jalr	-624(ra) # 80003768 <ilock>
  if(ip->type != T_DIR){
    800059e0:	04449703          	lh	a4,68(s1)
    800059e4:	4785                	li	a5,1
    800059e6:	04f71063          	bne	a4,a5,80005a26 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059ea:	8526                	mv	a0,s1
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	e3e080e7          	jalr	-450(ra) # 8000382a <iunlock>
  iput(p->cwd);
    800059f4:	15093503          	ld	a0,336(s2)
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	f2a080e7          	jalr	-214(ra) # 80003922 <iput>
  end_op();
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	7a4080e7          	jalr	1956(ra) # 800041a4 <end_op>
  p->cwd = ip;
    80005a08:	14993823          	sd	s1,336(s2)
  return 0;
    80005a0c:	4501                	li	a0,0
}
    80005a0e:	60ea                	ld	ra,152(sp)
    80005a10:	644a                	ld	s0,144(sp)
    80005a12:	64aa                	ld	s1,136(sp)
    80005a14:	690a                	ld	s2,128(sp)
    80005a16:	610d                	addi	sp,sp,160
    80005a18:	8082                	ret
    end_op();
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	78a080e7          	jalr	1930(ra) # 800041a4 <end_op>
    return -1;
    80005a22:	557d                	li	a0,-1
    80005a24:	b7ed                	j	80005a0e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	fa2080e7          	jalr	-94(ra) # 800039ca <iunlockput>
    end_op();
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	774080e7          	jalr	1908(ra) # 800041a4 <end_op>
    return -1;
    80005a38:	557d                	li	a0,-1
    80005a3a:	bfd1                	j	80005a0e <sys_chdir+0x7a>

0000000080005a3c <sys_exec>:

uint64
sys_exec(void)
{
    80005a3c:	7145                	addi	sp,sp,-464
    80005a3e:	e786                	sd	ra,456(sp)
    80005a40:	e3a2                	sd	s0,448(sp)
    80005a42:	ff26                	sd	s1,440(sp)
    80005a44:	fb4a                	sd	s2,432(sp)
    80005a46:	f74e                	sd	s3,424(sp)
    80005a48:	f352                	sd	s4,416(sp)
    80005a4a:	ef56                	sd	s5,408(sp)
    80005a4c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a4e:	08000613          	li	a2,128
    80005a52:	f4040593          	addi	a1,s0,-192
    80005a56:	4501                	li	a0,0
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	13a080e7          	jalr	314(ra) # 80002b92 <argstr>
    return -1;
    80005a60:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a62:	0c054a63          	bltz	a0,80005b36 <sys_exec+0xfa>
    80005a66:	e3840593          	addi	a1,s0,-456
    80005a6a:	4505                	li	a0,1
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	104080e7          	jalr	260(ra) # 80002b70 <argaddr>
    80005a74:	0c054163          	bltz	a0,80005b36 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a78:	10000613          	li	a2,256
    80005a7c:	4581                	li	a1,0
    80005a7e:	e4040513          	addi	a0,s0,-448
    80005a82:	ffffb097          	auipc	ra,0xffffb
    80005a86:	2e6080e7          	jalr	742(ra) # 80000d68 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a8a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a8e:	89a6                	mv	s3,s1
    80005a90:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a92:	02000a13          	li	s4,32
    80005a96:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a9a:	00391513          	slli	a0,s2,0x3
    80005a9e:	e3040593          	addi	a1,s0,-464
    80005aa2:	e3843783          	ld	a5,-456(s0)
    80005aa6:	953e                	add	a0,a0,a5
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	00c080e7          	jalr	12(ra) # 80002ab4 <fetchaddr>
    80005ab0:	02054a63          	bltz	a0,80005ae4 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ab4:	e3043783          	ld	a5,-464(s0)
    80005ab8:	c3b9                	beqz	a5,80005afe <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aba:	ffffb097          	auipc	ra,0xffffb
    80005abe:	0c2080e7          	jalr	194(ra) # 80000b7c <kalloc>
    80005ac2:	85aa                	mv	a1,a0
    80005ac4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ac8:	cd11                	beqz	a0,80005ae4 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aca:	6605                	lui	a2,0x1
    80005acc:	e3043503          	ld	a0,-464(s0)
    80005ad0:	ffffd097          	auipc	ra,0xffffd
    80005ad4:	036080e7          	jalr	54(ra) # 80002b06 <fetchstr>
    80005ad8:	00054663          	bltz	a0,80005ae4 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005adc:	0905                	addi	s2,s2,1
    80005ade:	09a1                	addi	s3,s3,8
    80005ae0:	fb491be3          	bne	s2,s4,80005a96 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ae4:	10048913          	addi	s2,s1,256
    80005ae8:	6088                	ld	a0,0(s1)
    80005aea:	c529                	beqz	a0,80005b34 <sys_exec+0xf8>
    kfree(argv[i]);
    80005aec:	ffffb097          	auipc	ra,0xffffb
    80005af0:	f94080e7          	jalr	-108(ra) # 80000a80 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af4:	04a1                	addi	s1,s1,8
    80005af6:	ff2499e3          	bne	s1,s2,80005ae8 <sys_exec+0xac>
  return -1;
    80005afa:	597d                	li	s2,-1
    80005afc:	a82d                	j	80005b36 <sys_exec+0xfa>
      argv[i] = 0;
    80005afe:	0a8e                	slli	s5,s5,0x3
    80005b00:	fc040793          	addi	a5,s0,-64
    80005b04:	9abe                	add	s5,s5,a5
    80005b06:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b0a:	e4040593          	addi	a1,s0,-448
    80005b0e:	f4040513          	addi	a0,s0,-192
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	194080e7          	jalr	404(ra) # 80004ca6 <exec>
    80005b1a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1c:	10048993          	addi	s3,s1,256
    80005b20:	6088                	ld	a0,0(s1)
    80005b22:	c911                	beqz	a0,80005b36 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b24:	ffffb097          	auipc	ra,0xffffb
    80005b28:	f5c080e7          	jalr	-164(ra) # 80000a80 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2c:	04a1                	addi	s1,s1,8
    80005b2e:	ff3499e3          	bne	s1,s3,80005b20 <sys_exec+0xe4>
    80005b32:	a011                	j	80005b36 <sys_exec+0xfa>
  return -1;
    80005b34:	597d                	li	s2,-1
}
    80005b36:	854a                	mv	a0,s2
    80005b38:	60be                	ld	ra,456(sp)
    80005b3a:	641e                	ld	s0,448(sp)
    80005b3c:	74fa                	ld	s1,440(sp)
    80005b3e:	795a                	ld	s2,432(sp)
    80005b40:	79ba                	ld	s3,424(sp)
    80005b42:	7a1a                	ld	s4,416(sp)
    80005b44:	6afa                	ld	s5,408(sp)
    80005b46:	6179                	addi	sp,sp,464
    80005b48:	8082                	ret

0000000080005b4a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b4a:	7139                	addi	sp,sp,-64
    80005b4c:	fc06                	sd	ra,56(sp)
    80005b4e:	f822                	sd	s0,48(sp)
    80005b50:	f426                	sd	s1,40(sp)
    80005b52:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b54:	ffffc097          	auipc	ra,0xffffc
    80005b58:	ee6080e7          	jalr	-282(ra) # 80001a3a <myproc>
    80005b5c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b5e:	fd840593          	addi	a1,s0,-40
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	00c080e7          	jalr	12(ra) # 80002b70 <argaddr>
    return -1;
    80005b6c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b6e:	0e054063          	bltz	a0,80005c4e <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b72:	fc840593          	addi	a1,s0,-56
    80005b76:	fd040513          	addi	a0,s0,-48
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	dd2080e7          	jalr	-558(ra) # 8000494c <pipealloc>
    return -1;
    80005b82:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b84:	0c054563          	bltz	a0,80005c4e <sys_pipe+0x104>
  fd0 = -1;
    80005b88:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b8c:	fd043503          	ld	a0,-48(s0)
    80005b90:	fffff097          	auipc	ra,0xfffff
    80005b94:	508080e7          	jalr	1288(ra) # 80005098 <fdalloc>
    80005b98:	fca42223          	sw	a0,-60(s0)
    80005b9c:	08054c63          	bltz	a0,80005c34 <sys_pipe+0xea>
    80005ba0:	fc843503          	ld	a0,-56(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	4f4080e7          	jalr	1268(ra) # 80005098 <fdalloc>
    80005bac:	fca42023          	sw	a0,-64(s0)
    80005bb0:	06054863          	bltz	a0,80005c20 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bb4:	4691                	li	a3,4
    80005bb6:	fc440613          	addi	a2,s0,-60
    80005bba:	fd843583          	ld	a1,-40(s0)
    80005bbe:	68a8                	ld	a0,80(s1)
    80005bc0:	ffffc097          	auipc	ra,0xffffc
    80005bc4:	b6e080e7          	jalr	-1170(ra) # 8000172e <copyout>
    80005bc8:	02054063          	bltz	a0,80005be8 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bcc:	4691                	li	a3,4
    80005bce:	fc040613          	addi	a2,s0,-64
    80005bd2:	fd843583          	ld	a1,-40(s0)
    80005bd6:	0591                	addi	a1,a1,4
    80005bd8:	68a8                	ld	a0,80(s1)
    80005bda:	ffffc097          	auipc	ra,0xffffc
    80005bde:	b54080e7          	jalr	-1196(ra) # 8000172e <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005be2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005be4:	06055563          	bgez	a0,80005c4e <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005be8:	fc442783          	lw	a5,-60(s0)
    80005bec:	07e9                	addi	a5,a5,26
    80005bee:	078e                	slli	a5,a5,0x3
    80005bf0:	97a6                	add	a5,a5,s1
    80005bf2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bf6:	fc042503          	lw	a0,-64(s0)
    80005bfa:	0569                	addi	a0,a0,26
    80005bfc:	050e                	slli	a0,a0,0x3
    80005bfe:	9526                	add	a0,a0,s1
    80005c00:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c04:	fd043503          	ld	a0,-48(s0)
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	9ee080e7          	jalr	-1554(ra) # 800045f6 <fileclose>
    fileclose(wf);
    80005c10:	fc843503          	ld	a0,-56(s0)
    80005c14:	fffff097          	auipc	ra,0xfffff
    80005c18:	9e2080e7          	jalr	-1566(ra) # 800045f6 <fileclose>
    return -1;
    80005c1c:	57fd                	li	a5,-1
    80005c1e:	a805                	j	80005c4e <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c20:	fc442783          	lw	a5,-60(s0)
    80005c24:	0007c863          	bltz	a5,80005c34 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c28:	01a78513          	addi	a0,a5,26
    80005c2c:	050e                	slli	a0,a0,0x3
    80005c2e:	9526                	add	a0,a0,s1
    80005c30:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c34:	fd043503          	ld	a0,-48(s0)
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	9be080e7          	jalr	-1602(ra) # 800045f6 <fileclose>
    fileclose(wf);
    80005c40:	fc843503          	ld	a0,-56(s0)
    80005c44:	fffff097          	auipc	ra,0xfffff
    80005c48:	9b2080e7          	jalr	-1614(ra) # 800045f6 <fileclose>
    return -1;
    80005c4c:	57fd                	li	a5,-1
}
    80005c4e:	853e                	mv	a0,a5
    80005c50:	70e2                	ld	ra,56(sp)
    80005c52:	7442                	ld	s0,48(sp)
    80005c54:	74a2                	ld	s1,40(sp)
    80005c56:	6121                	addi	sp,sp,64
    80005c58:	8082                	ret
    80005c5a:	0000                	unimp
    80005c5c:	0000                	unimp
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	ce1fc0ef          	jal	ra,80002980 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	710c                	ld	a1,32(a0)
    80005cfc:	7510                	ld	a2,40(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	cd6080e7          	jalr	-810(ra) # 80001a0e <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c9e080e7          	jalr	-866(ra) # 80001a0e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c76080e7          	jalr	-906(ra) # 80001a0e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	04a7cc63          	blt	a5,a0,80005e18 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dc4:	0001e797          	auipc	a5,0x1e
    80005dc8:	23c78793          	addi	a5,a5,572 # 80024000 <disk>
    80005dcc:	00a78733          	add	a4,a5,a0
    80005dd0:	6789                	lui	a5,0x2
    80005dd2:	97ba                	add	a5,a5,a4
    80005dd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dd8:	eba1                	bnez	a5,80005e28 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dda:	00451713          	slli	a4,a0,0x4
    80005dde:	00020797          	auipc	a5,0x20
    80005de2:	2227b783          	ld	a5,546(a5) # 80026000 <disk+0x2000>
    80005de6:	97ba                	add	a5,a5,a4
    80005de8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dec:	0001e797          	auipc	a5,0x1e
    80005df0:	21478793          	addi	a5,a5,532 # 80024000 <disk>
    80005df4:	97aa                	add	a5,a5,a0
    80005df6:	6509                	lui	a0,0x2
    80005df8:	953e                	add	a0,a0,a5
    80005dfa:	4785                	li	a5,1
    80005dfc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e00:	00020517          	auipc	a0,0x20
    80005e04:	21850513          	addi	a0,a0,536 # 80026018 <disk+0x2018>
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	5c4080e7          	jalr	1476(ra) # 800023cc <wakeup>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	96850513          	addi	a0,a0,-1688 # 80008780 <syscalls+0x340>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	728080e7          	jalr	1832(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	97050513          	addi	a0,a0,-1680 # 80008798 <syscalls+0x358>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	718080e7          	jalr	1816(ra) # 80000548 <panic>

0000000080005e38 <virtio_disk_init>:
{
    80005e38:	1101                	addi	sp,sp,-32
    80005e3a:	ec06                	sd	ra,24(sp)
    80005e3c:	e822                	sd	s0,16(sp)
    80005e3e:	e426                	sd	s1,8(sp)
    80005e40:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e42:	00003597          	auipc	a1,0x3
    80005e46:	96e58593          	addi	a1,a1,-1682 # 800087b0 <syscalls+0x370>
    80005e4a:	00020517          	auipc	a0,0x20
    80005e4e:	25e50513          	addi	a0,a0,606 # 800260a8 <disk+0x20a8>
    80005e52:	ffffb097          	auipc	ra,0xffffb
    80005e56:	d8a080e7          	jalr	-630(ra) # 80000bdc <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	4398                	lw	a4,0(a5)
    80005e60:	2701                	sext.w	a4,a4
    80005e62:	747277b7          	lui	a5,0x74727
    80005e66:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e6a:	0ef71163          	bne	a4,a5,80005f4c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	43dc                	lw	a5,4(a5)
    80005e74:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e76:	4705                	li	a4,1
    80005e78:	0ce79a63          	bne	a5,a4,80005f4c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7c:	100017b7          	lui	a5,0x10001
    80005e80:	479c                	lw	a5,8(a5)
    80005e82:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e84:	4709                	li	a4,2
    80005e86:	0ce79363          	bne	a5,a4,80005f4c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	47d8                	lw	a4,12(a5)
    80005e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e92:	554d47b7          	lui	a5,0x554d4
    80005e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e9a:	0af71963          	bne	a4,a5,80005f4c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	4705                	li	a4,1
    80005ea4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	470d                	li	a4,3
    80005ea8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eaa:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005eac:	c7ffe737          	lui	a4,0xc7ffe
    80005eb0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    80005eb4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eb6:	2701                	sext.w	a4,a4
    80005eb8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eba:	472d                	li	a4,11
    80005ebc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	473d                	li	a4,15
    80005ec0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ec2:	6705                	lui	a4,0x1
    80005ec4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ec6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eca:	5bdc                	lw	a5,52(a5)
    80005ecc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ece:	c7d9                	beqz	a5,80005f5c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ed0:	471d                	li	a4,7
    80005ed2:	08f77d63          	bgeu	a4,a5,80005f6c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ed6:	100014b7          	lui	s1,0x10001
    80005eda:	47a1                	li	a5,8
    80005edc:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ede:	6609                	lui	a2,0x2
    80005ee0:	4581                	li	a1,0
    80005ee2:	0001e517          	auipc	a0,0x1e
    80005ee6:	11e50513          	addi	a0,a0,286 # 80024000 <disk>
    80005eea:	ffffb097          	auipc	ra,0xffffb
    80005eee:	e7e080e7          	jalr	-386(ra) # 80000d68 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ef2:	0001e717          	auipc	a4,0x1e
    80005ef6:	10e70713          	addi	a4,a4,270 # 80024000 <disk>
    80005efa:	00c75793          	srli	a5,a4,0xc
    80005efe:	2781                	sext.w	a5,a5
    80005f00:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f02:	00020797          	auipc	a5,0x20
    80005f06:	0fe78793          	addi	a5,a5,254 # 80026000 <disk+0x2000>
    80005f0a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f0c:	0001e717          	auipc	a4,0x1e
    80005f10:	17470713          	addi	a4,a4,372 # 80024080 <disk+0x80>
    80005f14:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f16:	0001f717          	auipc	a4,0x1f
    80005f1a:	0ea70713          	addi	a4,a4,234 # 80025000 <disk+0x1000>
    80005f1e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f20:	4705                	li	a4,1
    80005f22:	00e78c23          	sb	a4,24(a5)
    80005f26:	00e78ca3          	sb	a4,25(a5)
    80005f2a:	00e78d23          	sb	a4,26(a5)
    80005f2e:	00e78da3          	sb	a4,27(a5)
    80005f32:	00e78e23          	sb	a4,28(a5)
    80005f36:	00e78ea3          	sb	a4,29(a5)
    80005f3a:	00e78f23          	sb	a4,30(a5)
    80005f3e:	00e78fa3          	sb	a4,31(a5)
}
    80005f42:	60e2                	ld	ra,24(sp)
    80005f44:	6442                	ld	s0,16(sp)
    80005f46:	64a2                	ld	s1,8(sp)
    80005f48:	6105                	addi	sp,sp,32
    80005f4a:	8082                	ret
    panic("could not find virtio disk");
    80005f4c:	00003517          	auipc	a0,0x3
    80005f50:	87450513          	addi	a0,a0,-1932 # 800087c0 <syscalls+0x380>
    80005f54:	ffffa097          	auipc	ra,0xffffa
    80005f58:	5f4080e7          	jalr	1524(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	88450513          	addi	a0,a0,-1916 # 800087e0 <syscalls+0x3a0>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	89450513          	addi	a0,a0,-1900 # 80008800 <syscalls+0x3c0>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	5d4080e7          	jalr	1492(ra) # 80000548 <panic>

0000000080005f7c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f7c:	7119                	addi	sp,sp,-128
    80005f7e:	fc86                	sd	ra,120(sp)
    80005f80:	f8a2                	sd	s0,112(sp)
    80005f82:	f4a6                	sd	s1,104(sp)
    80005f84:	f0ca                	sd	s2,96(sp)
    80005f86:	ecce                	sd	s3,88(sp)
    80005f88:	e8d2                	sd	s4,80(sp)
    80005f8a:	e4d6                	sd	s5,72(sp)
    80005f8c:	e0da                	sd	s6,64(sp)
    80005f8e:	fc5e                	sd	s7,56(sp)
    80005f90:	f862                	sd	s8,48(sp)
    80005f92:	f466                	sd	s9,40(sp)
    80005f94:	f06a                	sd	s10,32(sp)
    80005f96:	0100                	addi	s0,sp,128
    80005f98:	892a                	mv	s2,a0
    80005f9a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f9c:	00c52c83          	lw	s9,12(a0)
    80005fa0:	001c9c9b          	slliw	s9,s9,0x1
    80005fa4:	1c82                	slli	s9,s9,0x20
    80005fa6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005faa:	00020517          	auipc	a0,0x20
    80005fae:	0fe50513          	addi	a0,a0,254 # 800260a8 <disk+0x20a8>
    80005fb2:	ffffb097          	auipc	ra,0xffffb
    80005fb6:	cba080e7          	jalr	-838(ra) # 80000c6c <acquire>
  for(int i = 0; i < 3; i++){
    80005fba:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fbc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fbe:	0001eb97          	auipc	s7,0x1e
    80005fc2:	042b8b93          	addi	s7,s7,66 # 80024000 <disk>
    80005fc6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fc8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fca:	8a4e                	mv	s4,s3
    80005fcc:	a051                	j	80006050 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fce:	00fb86b3          	add	a3,s7,a5
    80005fd2:	96da                	add	a3,a3,s6
    80005fd4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fd8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fda:	0207c563          	bltz	a5,80006004 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fde:	2485                	addiw	s1,s1,1
    80005fe0:	0711                	addi	a4,a4,4
    80005fe2:	23548d63          	beq	s1,s5,8000621c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fe6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fe8:	00020697          	auipc	a3,0x20
    80005fec:	03068693          	addi	a3,a3,48 # 80026018 <disk+0x2018>
    80005ff0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005ff2:	0006c583          	lbu	a1,0(a3)
    80005ff6:	fde1                	bnez	a1,80005fce <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005ff8:	2785                	addiw	a5,a5,1
    80005ffa:	0685                	addi	a3,a3,1
    80005ffc:	ff879be3          	bne	a5,s8,80005ff2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006000:	57fd                	li	a5,-1
    80006002:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006004:	02905a63          	blez	s1,80006038 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006008:	f9042503          	lw	a0,-112(s0)
    8000600c:	00000097          	auipc	ra,0x0
    80006010:	daa080e7          	jalr	-598(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006014:	4785                	li	a5,1
    80006016:	0297d163          	bge	a5,s1,80006038 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000601a:	f9442503          	lw	a0,-108(s0)
    8000601e:	00000097          	auipc	ra,0x0
    80006022:	d98080e7          	jalr	-616(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006026:	4789                	li	a5,2
    80006028:	0097d863          	bge	a5,s1,80006038 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000602c:	f9842503          	lw	a0,-104(s0)
    80006030:	00000097          	auipc	ra,0x0
    80006034:	d86080e7          	jalr	-634(ra) # 80005db6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006038:	00020597          	auipc	a1,0x20
    8000603c:	07058593          	addi	a1,a1,112 # 800260a8 <disk+0x20a8>
    80006040:	00020517          	auipc	a0,0x20
    80006044:	fd850513          	addi	a0,a0,-40 # 80026018 <disk+0x2018>
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	1fe080e7          	jalr	510(ra) # 80002246 <sleep>
  for(int i = 0; i < 3; i++){
    80006050:	f9040713          	addi	a4,s0,-112
    80006054:	84ce                	mv	s1,s3
    80006056:	bf41                	j	80005fe6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006058:	4785                	li	a5,1
    8000605a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000605e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006062:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006066:	f9042983          	lw	s3,-112(s0)
    8000606a:	00499493          	slli	s1,s3,0x4
    8000606e:	00020a17          	auipc	s4,0x20
    80006072:	f92a0a13          	addi	s4,s4,-110 # 80026000 <disk+0x2000>
    80006076:	000a3a83          	ld	s5,0(s4)
    8000607a:	9aa6                	add	s5,s5,s1
    8000607c:	f8040513          	addi	a0,s0,-128
    80006080:	ffffb097          	auipc	ra,0xffffb
    80006084:	0bc080e7          	jalr	188(ra) # 8000113c <kvmpa>
    80006088:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000608c:	000a3783          	ld	a5,0(s4)
    80006090:	97a6                	add	a5,a5,s1
    80006092:	4741                	li	a4,16
    80006094:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006096:	000a3783          	ld	a5,0(s4)
    8000609a:	97a6                	add	a5,a5,s1
    8000609c:	4705                	li	a4,1
    8000609e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060a2:	f9442703          	lw	a4,-108(s0)
    800060a6:	000a3783          	ld	a5,0(s4)
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060b0:	0712                	slli	a4,a4,0x4
    800060b2:	000a3783          	ld	a5,0(s4)
    800060b6:	97ba                	add	a5,a5,a4
    800060b8:	05890693          	addi	a3,s2,88
    800060bc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060be:	000a3783          	ld	a5,0(s4)
    800060c2:	97ba                	add	a5,a5,a4
    800060c4:	40000693          	li	a3,1024
    800060c8:	c794                	sw	a3,8(a5)
  if(write)
    800060ca:	100d0a63          	beqz	s10,800061de <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ce:	00020797          	auipc	a5,0x20
    800060d2:	f327b783          	ld	a5,-206(a5) # 80026000 <disk+0x2000>
    800060d6:	97ba                	add	a5,a5,a4
    800060d8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060dc:	0001e517          	auipc	a0,0x1e
    800060e0:	f2450513          	addi	a0,a0,-220 # 80024000 <disk>
    800060e4:	00020797          	auipc	a5,0x20
    800060e8:	f1c78793          	addi	a5,a5,-228 # 80026000 <disk+0x2000>
    800060ec:	6394                	ld	a3,0(a5)
    800060ee:	96ba                	add	a3,a3,a4
    800060f0:	00c6d603          	lhu	a2,12(a3)
    800060f4:	00166613          	ori	a2,a2,1
    800060f8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060fc:	f9842683          	lw	a3,-104(s0)
    80006100:	6390                	ld	a2,0(a5)
    80006102:	9732                	add	a4,a4,a2
    80006104:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006108:	20098613          	addi	a2,s3,512
    8000610c:	0612                	slli	a2,a2,0x4
    8000610e:	962a                	add	a2,a2,a0
    80006110:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006114:	00469713          	slli	a4,a3,0x4
    80006118:	6394                	ld	a3,0(a5)
    8000611a:	96ba                	add	a3,a3,a4
    8000611c:	6589                	lui	a1,0x2
    8000611e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006122:	94ae                	add	s1,s1,a1
    80006124:	94aa                	add	s1,s1,a0
    80006126:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006128:	6394                	ld	a3,0(a5)
    8000612a:	96ba                	add	a3,a3,a4
    8000612c:	4585                	li	a1,1
    8000612e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006130:	6394                	ld	a3,0(a5)
    80006132:	96ba                	add	a3,a3,a4
    80006134:	4509                	li	a0,2
    80006136:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000613a:	6394                	ld	a3,0(a5)
    8000613c:	9736                	add	a4,a4,a3
    8000613e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006142:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006146:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000614a:	6794                	ld	a3,8(a5)
    8000614c:	0026d703          	lhu	a4,2(a3)
    80006150:	8b1d                	andi	a4,a4,7
    80006152:	2709                	addiw	a4,a4,2
    80006154:	0706                	slli	a4,a4,0x1
    80006156:	9736                	add	a4,a4,a3
    80006158:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000615c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006160:	6798                	ld	a4,8(a5)
    80006162:	00275783          	lhu	a5,2(a4)
    80006166:	2785                	addiw	a5,a5,1
    80006168:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000616c:	100017b7          	lui	a5,0x10001
    80006170:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006174:	00492703          	lw	a4,4(s2)
    80006178:	4785                	li	a5,1
    8000617a:	02f71163          	bne	a4,a5,8000619c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000617e:	00020997          	auipc	s3,0x20
    80006182:	f2a98993          	addi	s3,s3,-214 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006186:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006188:	85ce                	mv	a1,s3
    8000618a:	854a                	mv	a0,s2
    8000618c:	ffffc097          	auipc	ra,0xffffc
    80006190:	0ba080e7          	jalr	186(ra) # 80002246 <sleep>
  while(b->disk == 1) {
    80006194:	00492783          	lw	a5,4(s2)
    80006198:	fe9788e3          	beq	a5,s1,80006188 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000619c:	f9042483          	lw	s1,-112(s0)
    800061a0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061a4:	00479713          	slli	a4,a5,0x4
    800061a8:	0001e797          	auipc	a5,0x1e
    800061ac:	e5878793          	addi	a5,a5,-424 # 80024000 <disk>
    800061b0:	97ba                	add	a5,a5,a4
    800061b2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061b6:	00020917          	auipc	s2,0x20
    800061ba:	e4a90913          	addi	s2,s2,-438 # 80026000 <disk+0x2000>
    free_desc(i);
    800061be:	8526                	mv	a0,s1
    800061c0:	00000097          	auipc	ra,0x0
    800061c4:	bf6080e7          	jalr	-1034(ra) # 80005db6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061c8:	0492                	slli	s1,s1,0x4
    800061ca:	00093783          	ld	a5,0(s2)
    800061ce:	94be                	add	s1,s1,a5
    800061d0:	00c4d783          	lhu	a5,12(s1)
    800061d4:	8b85                	andi	a5,a5,1
    800061d6:	cf89                	beqz	a5,800061f0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061d8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061dc:	b7cd                	j	800061be <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061de:	00020797          	auipc	a5,0x20
    800061e2:	e227b783          	ld	a5,-478(a5) # 80026000 <disk+0x2000>
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	4689                	li	a3,2
    800061ea:	00d79623          	sh	a3,12(a5)
    800061ee:	b5fd                	j	800060dc <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061f0:	00020517          	auipc	a0,0x20
    800061f4:	eb850513          	addi	a0,a0,-328 # 800260a8 <disk+0x20a8>
    800061f8:	ffffb097          	auipc	ra,0xffffb
    800061fc:	b28080e7          	jalr	-1240(ra) # 80000d20 <release>
}
    80006200:	70e6                	ld	ra,120(sp)
    80006202:	7446                	ld	s0,112(sp)
    80006204:	74a6                	ld	s1,104(sp)
    80006206:	7906                	ld	s2,96(sp)
    80006208:	69e6                	ld	s3,88(sp)
    8000620a:	6a46                	ld	s4,80(sp)
    8000620c:	6aa6                	ld	s5,72(sp)
    8000620e:	6b06                	ld	s6,64(sp)
    80006210:	7be2                	ld	s7,56(sp)
    80006212:	7c42                	ld	s8,48(sp)
    80006214:	7ca2                	ld	s9,40(sp)
    80006216:	7d02                	ld	s10,32(sp)
    80006218:	6109                	addi	sp,sp,128
    8000621a:	8082                	ret
  if(write)
    8000621c:	e20d1ee3          	bnez	s10,80006058 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006220:	f8042023          	sw	zero,-128(s0)
    80006224:	bd2d                	j	8000605e <virtio_disk_rw+0xe2>

0000000080006226 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006226:	1101                	addi	sp,sp,-32
    80006228:	ec06                	sd	ra,24(sp)
    8000622a:	e822                	sd	s0,16(sp)
    8000622c:	e426                	sd	s1,8(sp)
    8000622e:	e04a                	sd	s2,0(sp)
    80006230:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006232:	00020517          	auipc	a0,0x20
    80006236:	e7650513          	addi	a0,a0,-394 # 800260a8 <disk+0x20a8>
    8000623a:	ffffb097          	auipc	ra,0xffffb
    8000623e:	a32080e7          	jalr	-1486(ra) # 80000c6c <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006242:	00020717          	auipc	a4,0x20
    80006246:	dbe70713          	addi	a4,a4,-578 # 80026000 <disk+0x2000>
    8000624a:	02075783          	lhu	a5,32(a4)
    8000624e:	6b18                	ld	a4,16(a4)
    80006250:	00275683          	lhu	a3,2(a4)
    80006254:	8ebd                	xor	a3,a3,a5
    80006256:	8a9d                	andi	a3,a3,7
    80006258:	cab9                	beqz	a3,800062ae <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000625a:	0001e917          	auipc	s2,0x1e
    8000625e:	da690913          	addi	s2,s2,-602 # 80024000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006262:	00020497          	auipc	s1,0x20
    80006266:	d9e48493          	addi	s1,s1,-610 # 80026000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000626a:	078e                	slli	a5,a5,0x3
    8000626c:	97ba                	add	a5,a5,a4
    8000626e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006270:	20078713          	addi	a4,a5,512
    80006274:	0712                	slli	a4,a4,0x4
    80006276:	974a                	add	a4,a4,s2
    80006278:	03074703          	lbu	a4,48(a4)
    8000627c:	ef21                	bnez	a4,800062d4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000627e:	20078793          	addi	a5,a5,512
    80006282:	0792                	slli	a5,a5,0x4
    80006284:	97ca                	add	a5,a5,s2
    80006286:	7798                	ld	a4,40(a5)
    80006288:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000628c:	7788                	ld	a0,40(a5)
    8000628e:	ffffc097          	auipc	ra,0xffffc
    80006292:	13e080e7          	jalr	318(ra) # 800023cc <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006296:	0204d783          	lhu	a5,32(s1)
    8000629a:	2785                	addiw	a5,a5,1
    8000629c:	8b9d                	andi	a5,a5,7
    8000629e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062a2:	6898                	ld	a4,16(s1)
    800062a4:	00275683          	lhu	a3,2(a4)
    800062a8:	8a9d                	andi	a3,a3,7
    800062aa:	fcf690e3          	bne	a3,a5,8000626a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062ae:	10001737          	lui	a4,0x10001
    800062b2:	533c                	lw	a5,96(a4)
    800062b4:	8b8d                	andi	a5,a5,3
    800062b6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062b8:	00020517          	auipc	a0,0x20
    800062bc:	df050513          	addi	a0,a0,-528 # 800260a8 <disk+0x20a8>
    800062c0:	ffffb097          	auipc	ra,0xffffb
    800062c4:	a60080e7          	jalr	-1440(ra) # 80000d20 <release>
}
    800062c8:	60e2                	ld	ra,24(sp)
    800062ca:	6442                	ld	s0,16(sp)
    800062cc:	64a2                	ld	s1,8(sp)
    800062ce:	6902                	ld	s2,0(sp)
    800062d0:	6105                	addi	sp,sp,32
    800062d2:	8082                	ret
      panic("virtio_disk_intr status");
    800062d4:	00002517          	auipc	a0,0x2
    800062d8:	54c50513          	addi	a0,a0,1356 # 80008820 <syscalls+0x3e0>
    800062dc:	ffffa097          	auipc	ra,0xffffa
    800062e0:	26c080e7          	jalr	620(ra) # 80000548 <panic>
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

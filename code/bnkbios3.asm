	title	'BIOS for CP/M 3.0 & PMC-101'

 ;			Copyright (C), 1982,83
 ;
 ;  Digital Research, Inc		Personal Micro Computers, Inc.
 ;	P.O. Box 579				475 Ellis St.
 ;Pacific Grove, CA  93950		  Mountain View, CA 94304
 ;
 ; version 1.0 15 Sept 82		  version 3.0	  07 FEB. 1984

 ;04/21/83	created
 ;06/06/83	added Parity mask conditional
 ;10/01/83	added Hard Disk Driver
 ;02/07/84	added DRI patches 9-14 to INITDIR,DIRLBL,HELP,CCP,BDOS,PATCH
 ;??/??/??


 ;	*****************************************************
 ;	*						    *
 ;	*	NOTE:					    *
 ;	*						    *
 ;	*	DO NOT MODIFY ANY CODE IN THIS MODULE	    *
 ;	*						    *
 ;	*	 PMC CANNOT SUPPORT ANY MODIFICATIONS	    *
 ;	*						    *
 ;	*****************************************************
 ;
 ; To generate a new copy of CPM3.SYS insert a COPY of the SOURCE disk into
 ;  the A drive. Press the reset buton.	 When the ' A> ' prompt appears type
 ;  SUBMIT BIOS<RETURN>.  This will automatically execute all the necessary
 ;  commands to generate a new CPM3.SYS file.  When execution is
 ;  completed press the reset button to load the new  operating system.
 ;

 ;	This module contains BIOSKRNL, MOVE, CHARIO, BOOT, DRVTBL

 ;ONLY USE ODD NUMBERED BANKS WHEN SETTING UP THE SEGMENT TABLES WITH GENCPM.
 ;	bank number 00 is used for the system bank.
 ;	bank number 01 is used for the TPA (bank 1)
 ;	bank number 03 is used for the CCP stored in bank 2
 ;	bank number 07 is used for bank 2

 ;	****************************************************

	maclib	z80
	maclib	ports
	maclib	modebaud
	maclib	PMCequ

	public @adrv,@rdrv,@trk,@sect,@dma,@cbnk,@dbnk,@type
	public pdec,pmsg,pderr,?const,?conin,?conout

	extrn	f$write, f$read, f$login, f$init
	extrn	f$Hwrite, f$Hread, f$Hlogin, f$Hinit
	extrn @covec,@civec,@aovec,@aivec,@lovec,@mxtpa,@bnkbf,@sec,@date


 ;********************** Cseg Code ********************************************
	cseg		; GENCPM puts CSEG stuff in common memory

	jmp	boot	; initial entry on cold start
?wboot: jmp	wboot	; reentry on program exit, warm start
?const: jmp	const	; return console input status
?conin: jmp	conin	; return console input character
?conout:jmp	conout	; send console output character
	jmp	list	; send list output character
	jmp	auxout	; send auxilliary output character
	jmp	auxin	; return auxilliary input character
	jmp	home	; set disks to logical home
	jmp	seldsk	; select disk drive, return disk parameter info
	jmp	settrk	; set disk track
	jmp	setsec	; set disk sector
	jmp	setdma	; set disk I/O memory address
	jmp	read	; read physical block(s)
	jmp	write	; write physical block(s)
	jmp	listst	; return list device status
	jmp	sectrn	; translate logical to physical sector
	jmp	conost	; return console output status
	jmp	auxist	; return aux input status
	jmp	auxost	; return aux output status
	jmp	devtbl	; return address of device def table
	jmp	cinit	; change baud rate of device
	jmp	getdrv	; return address of disk drive table
	jmp	multio	; set multiple record count for disk I/O
	jmp	flush	; flush BIOS maintained disk caching
	jmp	move	; block move memory to memory
	jmp	time	; Signal Time and Date operation
?bnksl: jmp	bnksel	; select bank for code execution and default DMA
	jmp	setbnk	; select different bank for disk I/O DMA operations.
	jmp	xmove	; set source and destination banks for one operation
	jmp	0	; reserved for future expansion +5A
	jmp	0	; reserved for future expansion +5D
	jmp	0	; reserved for future expansion +60
	jmp	0	; reserved by PMC	+63
	jmp	0	; reserved by PMC	+66
	jmp	0	; reserved by PMC	+69
	jmp	0	; reserved by PMC	+6C
	db	0C4h	; Do Not Change		+6f

 ;*****************
 ; Interrupt Vectors
 ;*****************

INTvec:
CTCvec: DW	i$rtc,i$ctc1,i$index,i$ctc3

 ;*****************
 ; Interrupt Routines
 ;*****************
i$rtc:				;CTC ch0  REAL TIME CLOCK
	di
	sspd	RTCstk		;interrupts every 16.384ms
	lxi	sp,RTCstk
	push	psw
	push	b
	push	d
	push	h
	lxi	h,Frac
	inr	m
	mvi	a,maxFrc
	cmp	m
	jrnz	rtc$ext
	mvi	m,0
	mvi	b,3
	lxi	h,timtbl
	lxi	d,@sec
rtc$1:	ldax	d
	inr	a
	daa
	stax	d
	cmp	m		;compare to MAX value from table
	jrnz	rtc$ext		;if not Max then skip
	mov	a,b		;see if Day would be next
	dcr	a
	xchg
	mvi	m,0		;preset current to 0
	jrnz	rtc$2
	push	h
	lhld	@date		;and up date
	inx	h
	shld	@date
	pop	h
rtc$2:	xchg
	inx	h
	dcx	d
	djnz	rtc$1
rtc$ext:pop	h
	pop	d
	pop	b
	pop	psw
	lspd	RTCstk
	ei
	reti

i$ctc1:				;CTC ch1	RESERVED
	reti			;reserved for bus port

i$index:			;CTC ch2	INDEX PULSE
	di
	push	psw		;use 1 level of user stack
	mvi	a,0000$0011B	;reset
	out	p$index
	xra	a
	out	p$select	;deselect all  drives
	pop	psw
	ei
	reti

i$ctc3:				;CTC channel 3
;	di			;sample entry & exit code for
;	sspd	CTC3stk		;user available CTC interrupts
;	lxi	sp,CTC3stk
;	push	psw
;	push	b
;	push	d
;	push	h
;				;user code goes here
;	pop	h
;	pop	d
;	pop	b
;	pop	psw
;	lspd	CTC3stk
;	ei
	reti
;		ds	16	; stack space
;CTC3stk:	ds	2	; storage for SP on entry to i$CTC3

 ;*****************
 ; Warm boot
 ;*****************

wboot:
	lxi	sp,boot$stack
boot$1: mvi	a,JMP
	sta	0
	sta	5		; set up jumps in page zero
	lxi	h,?wboot
	shld	1		; BIOS warm start entry
	lhld	@MXTPA
	shld	6		; BDOS system call entry
	mvi	a,ccp$bank
	call	?bnksl		; select extra bank
	lxi	d,0100h		; copy CCP to bank 3 for reloading
	lxi	b,ccp$length
	lxi	h,ccp$ld$adr
	ldir
	mvi	a,tpa$bank
	call	?bnksl		; activate TPA bank
	jmp	ccp

 ;*****************
 ; Character Init
 ;*****************

cinit:
	mov	a,c
	cpi	max$devices
	jrz	cent$init
	rnc			; invalid device or no init required for parll
ser$init:
	mov	l,c
	mvi	h,0		; make 16 bits from device number
	dad	h
	dad	h
	dad	h		; *8
	lxi	d,@ctbl+7
	dad	d
	mov	a,m		;DRI's baud table does not match ours
	cpi	10		;if the baud rate is 9 or less then
	jrnc	no$change	;we need to drop it down 1 rate to
	dcr	a		;compensate for our 2000 baud rate
no$change:			;which they do not support
	mov	b,a
	mov	a,c		;get device numer
	ora	a
	jrz	chA$baud	;if A ch
	in	p$getbaud	;read baud
	ani	0F0H		;mask out old B ch
	jr	set$bd
chA$baud:
	mov	a,b		;move baud bits to hi nibbble
	rlc
	rlc
	rlc
	rlc
	mov	b,a		;save back to b
	in	p$getbaud	;read old baud
	ani	0FH		;mask out old A ch
set$bd: ora	b		;or in new baud
	di
	out	p$baud		;set it
	ei
	ret

 ;*****************
cent$init:
	ret

 ;*****************
 ; Character output
 ;*****************

conout:
	lhld	@covec		; fetch console output bit vector
	jr	out$scan
auxout:
	lhld	@aovec		; fetch aux output bit vector
	jr	out$scan
list:
	lhld	@lovec		; fetch list output bit vector
out$scan:
	mvi	b,0		; start with device 15
co$next:dad	h		; shift out next bit
	jrnc	not$out$device
	push	h		; save the vector
	push	b		; save the count and character
not$out$ready:
	call	coster
	ora	a
	jrz	not$out$ready
	pop	b
	push	b		; restore and resave the character and device
	call	?co		; if device selected, print it
	pop	b		; recover count and character
	pop	h		; recover the rest of the vector
not$out$device:
	inr	b		; next device number
	mov	a,h
	ora	l		; see if any devices left
	jrnz	co$next		; and go find them...
	ret

 ;*****************
?co:				; character output
	mov	a,b
	cpi	max$devices
	jrz	centronics$out
	jrnc	null$output
	mov	a,c
	push	psw		; save character from <C>
	push	b		; save device number
co$spin:
	mov	a,b
	call	?cost
	jrz	co$spin		; wait for TxEmpty
	pop	h
	mov	l,h
	mvi	h,0		; get device number in <HL>
	lxi	d,data$ports
	dad	d		; make address of port address
	mov	c,m		; get port address
	pop	psw
	outp	a		; send data
null$output:
	ret

 ;*****************
centronics$out:
	in	p$centstat
	ani	1111$0000b	;mask off spurious bits
	cpi	centronics$mask ;check Busy, Empty, Selected & Fault
	jrnz	centronics$out
	mov	a,c
	out	p$centdata	; give printer data
	ret

 ;*****************
 ; Character Output Status
 ;*****************

conost:
	lhld	@covec		; get console output bit vector
	jr	ost$scan
auxost:
	lhld	@aovec		; get aux output bit vector
	jr	ost$scan
listst:
	lhld	@lovec		; get list output bit vector
ost$scan:
	mvi	b,0		; start with device 0
cos$next:
	dad	h		; check next bit
	push	h		; save the vector
	push	b		; save the count
	mvi	a,-1		; assume device ready
	cc	coster		; check status for this device
	pop	b		; recover count
	pop	h		; recover bit vector
	ora	a		; see if device ready
	rz			; if any not ready, return false
	inr	b		; drop device number
	mov	a,h
	ora	l		; see if any more selected devices
	jrnz	cos$next
	ori	-1		; all selected were ready, return true
	ret

 ;*****************
?cost:				; character output status
	mov	a,b
	cpi	max$devices
	jrz	cent$stat
	jrnc	null$status
	mov	l,b
	mvi	h,0
	lxi	d,data$ports
	dad	d
	mov	c,m
	inr	c
	inr	c
   if CTS$protocol
	mvi	a,0001$0000b	;reset Ext. status
	outp	a
	inp	a		; get output status
	ani	0010$0000b	; test CTS 
	rz
   endif
   if DSR$protocol
	mvi	a,0001$0000b	;reset Ext. status
	outp	a
	inp	a		; get output status
	ani	0001$0000b	; test RI (DSR)
	rz
   endif
	inp	a		; get output status
	ani	0000$0100b	; test transmitter empty
	rz			; ret false if not ready
	ori	-1
	ret			; return true if ready

 ;*****************
cent$stat:
	in	p$centstat
	ani	1111$0000b
	cpi	centronics$mask
	mvi	a,-1		;ready
	rz
	mvi	a,0		;not ready
	ret

 ;*****************
 ; Character Input Status
 ;*****************

const:
	lhld	@civec		; get console input bit vector
	jr	ist$scan
auxist:
	lhld	@aivec		; get aux input bit vector
ist$scan:
	mvi	b,0		; start with device 0
cis$next:
	dad	h		; check next bit
	mvi	a,0		; assume device not ready
	cc	cist1		; check status for this device
	ora	a
	rnz			; if any ready, return true
	inr	b		; drop device number
	mov	a,h
	ora	l		; see if any more selected devices
	jrnz	cis$next
	xra	a		; all selected were not ready, return false
	ret

 ;*****************
cist1:				; get input status with <BC> and <HL> saved
	push	b
	push	h
	call	?cist
	pop	h
	pop	b
	ora	a
	ret

 ;*****************
?cist:				; character input status
	mov	a,b
	cpi	max$devices
	jrnc	null$status	; can't read from centronics
	mov	l,b
	mvi	h,0		; make device number 16 bits
	lxi	d,data$ports
	dad	d		; make pointer to port address
	mov	c,m
	inr	c		; get DART status port
	inr	c
	inp	a		; read from status port
	ani	1		; isolate RxRdy
	rz			; return with zero no char
	ori	-1
	ret

 ;*****************
null$status:
	xra	a
	ret

 ;*****************
 ; Character Input
 ;*****************

conin:
	lhld	@civec
	jr	in$scan
auxin:
	lhld	@aivec
in$scan:push	h		; save bit vector
	mvi	b,0
ci$next:dad	h		; shift out next bit
	mvi	a,0		; insure zero a	 (nonexistant device not ready)
	cc	cist1		; see if the device has a character
	ora	a
	jrnz	ci$rdy		; this device has a character
	inr	b		; else, next device
	mov	a,h
	ora	l		; see if any more devices
	jrnz	ci$next		; go look at them
	pop	h		; recover bit vector
	jr	in$scan		; loop til we find a character
ci$rdy:
	pop	h		; discard extra stack
?ci:	mov	a,b		; character input
	cpi	max$devices
	jrnc	null$input	; can't read from centronics
cir1:	mov	a,b
	call	?cist
	jrz	cir1		; wait for character ready
	dcr	c
	dcr	c
	inp	a		; get data
   if parity$mask
	ani	7Fh		; mask parity
   endif
	ret

 ;*****************
null$input:
	mvi	a,1Ah		; return a ctl-Z for no device
	ret

 ;*****************
coster:				; check for output device ready, including
				; optional xon/xoff support
	mov	l,b
	mvi	h,0		; make device code 16 bits
	push	h		; save it in stack
	dad	h
	dad	h
	dad	h		; create offset into device characteristics tbl
	lxi	d,@ctbl+6
	dad	d		; make address of mode byte
	mov	a,m
	ani	mb$xonxoff
	pop	h		; recover console number in <HL>
	jz	?cost		; not a xon device, go get output status direct
	lxi	d,xofflist
	dad	d		; make pointer to proper xon/xoff flag
	call	cist1		; see if this keyboard has character
	mov	a,m
	cnz	ci1		; get flag or read key if any
	cpi	ctlq
	jrnz	not$q		; if its a ctl-Q,
	mvi	a,-1		;	set the flag ready
not$q:	cpi	ctls
	jrnz	not$s		; if its a ctl-S,
	mvi	a,00h		;	clear the flag
not$s:	mov	m,a		; save the flag
	call	cost1		; get the actual output status,
	ana	m		; and mask with ctl-Q/ctl-S flag
	ret			; return this as the status

 ;*****************
ci1:				; get input, saving <BC> & <HL>
	push	b
	push	h
	call	?ci
	pop	h
	pop	b
	ret

 ;*****************
cost1:				; get output status, saving <BC> & <HL>
	push	b
	push	h
	call	?cost
	pop	h
	pop	b
	ora	a
	ret 

 ;*****************
 ; Get Device Table adr
 ;*****************
devtbl:
	lxi	h,@ctbl
	ret

 ;*****************
 ; Get Drive Table adr
 ;*****************
getdrv:
	lxi	h,@dtbl		;get Drive table adr
	ret

 ;*****************
 ; Set/Get Time
 ;*****************
time:
	mov	a,c
	ora	a		;0= get time	-1= set time
	rz			;RTC updates SCB directly no need to get time
set$time:			;Set time activates Clock, Time already in SCB
	mvi	a,1010$0111b	;set  CTC ch0 command to:
	di			;  Int enable, Timer mode, prescaler 256
	out	p$rtc		;  auto trigger,load count next & reset
	mvi	a,RTCcnt	;set CTC ch0 time count to 252
	out	p$rtc		;  time = 250ns*256presc*252Cnt=16.128ms
	ei
	ret

 ;*****************
 ; Inter bank Block Move
 ;*****************
xmove:				; C= src bank	B= dest bank
	sbcd	src$bnk		;save banks
	ori	-1		;set xmove pending flag
	sta	xmv$flg
	ret

 ;*****************
 ; Intra bank Block Move
 ;*****************
move:
	lda	xmv$flg ; check xmove pending flag
	ora	a
	jrnz	exmve	;if set do an extended move else
	xchg		; we are passed source in DE and dest in HL, len in BC
	ldir		; use Z80 block move instruction
	xchg		; need next addresses in same regs
	ret
exmve:
	xra	a
	sta	xmv$flg		;clear xmove flag
	lda	@cbnk
	push	psw		;save current bank
	xchg			;HL=src		DE=dest
	lda	src$bnk
	call	bank		;set source bank
	push	d		;save dest aadr
	push	b		;save length
	lxi	d,buffer
	ldir			;src->buffer
	pop	b		;restore length
	pop	d		;restore destination adr
	lda	dst$bnk
	call	bank		;set destination bank
	push	h		;save end of source adr
	lxi	h,buffer
	ldir			;buffer ->dst
	pop	h		;restore source adr end
	xchg
	pop	psw		;restore current bank fall through to
bnksel: sta	@cbnk		; remember current bank
bank:	ora	a
	jrz	bank1		;skip if bank 0 else
	ori	80h		;set hibit to activate bank select
bank1:	out	p$bankselect	; put new memory control byte
	ret

 ;*****************
 ; Utility Subroutines
 ;*****************

 ; none

 ;********************** Cseg Data ********************************************

 ;   Drive Table
 ;All four dph's must be set for GENCPM to allocated the necessary buffers

@dtbl
	dw	dph0 ,dph1 ,dph2 ,00000 ;Drives A-D (5")
	dw	00000,00000,0000 ,00000 ;Drives E-H 
	dw	00000,00000,00000,00000 ;Drives I-L 
	dw	dph12,dph13,00000,00000 ;Drives M-P (Hard)


 ;   Device Table
@ctbl:
   ;Channel A must always be first item in table
	db	'TERMNL'		; device 0[8000], DART ch A
	db	mb$in$out+mb$serial+mb$softbaud
@Abaud: ds	1			;set by boot:
   ;Channel B must always be second item in table
	db	'MODEM '		; device 1[4000], DART ch B
	db	mb$in$out+mb$serial+mb$softbaud
@Bbaud: ds	1			;set by boot:
   ;Other Devices ahould be inserted here

   ;Centronics must always be last item in table
	db	'CENTRN'		; device 3[1000], Centronics parallel printer
	db	mb$output
	db	baud$none
	db	0

 ;   Disk Parameter Blocks
dpb0:				;  Double Density Double Sided for PMC-101 1024
	dw	80		; SPT		128 BYTE RECORDS PER TRACK
	db	4,15,1		; BSH,BLM,EXM	BLOCK SHIFT AND MSK, EXTENT MSK
	dw	194,127		; DSM,DRM	MAX BLOCK #, MAX DIR ENTRY #
	db	192,0		; AL0,AL1	ALLOC VEC f/DIR
	dw	32,1		; CKS,OFF	CHECKSUM SIZ, OFFSET f/SYS TRK
	db	3,7		; PSH,PHM	PHYSICAL SECTOR SIZE SHIFT
	db	'A'		; CONVERT TYPE	PMC extension

dpb1:			;  Double Density Double Sided for PMC-101 1024
	dw	80		; SPT
	db	4,15,1		; BSH,BLM,EXM
	dw	194,127		; DSM,DRM
	db	192,0		; AL0,AL1
	dw	32,1		; CKS,OFF
	db	3,7		; PSH,PHM
	db	'A'		; CONVERT TYPE	PMC extension

dpb2:			;  Double Density Double Sided for PMC-101 1024
	dw	80		; SPT
	db	4,15,1		; BSH,BLM,EXM
	dw	194,127		; DSM,DRM
	db	192,0		; AL0,AL1
	dw	32,1		; CKS,OFF
	db	3,7		; PSH,PHM
	db	'A'		; CONVERT TYPE	PMC extension

dpb3:			 ;  Double Density Double Sided for PMC-101 1024
	dw	 80		 ; SPT
	db	 4,15,1		 ; BSH,BLM,EXM
	dw	 194,127	 ; DSM,DRM
	db	 192,0		 ; AL0,AL1
	dw	 32,1		 ; CKS,OFF
	db	 3,7		 ; PSH,PHM
	db	 'A'		 ; CONVERT TYPE	 PMC extension

dpbHD:
	; These are the numbers from the original PMC hard disk
	; Left like that just to minimize changes during development.
	DW	 80		 ; SPT			 SEC=9sptx4hdsx8logical
	DB	 5,31,1		 ; BSH,BLM,EXM		 BLS=4096	  
	DW	 2749,2047	 ; DSM,DRM		 DRM=2048	  
	DB	 255,255	 ; AL0,AL1		 DRM+1/32 bits hi 
	DW	 8000h,1	 ; CKS,OFF		 DRM+1/4, keep system trk just in case 
	DB	 2,3		 ; PSH,PHM - 512bytes/sec
	db	 'A'

dpbHDB:
	; since we're now using LBA addressing, the SPT is not important.
	; the important numbers are 5499 (5500-1) and 2047, the former is
	; the size of the drive in 4k blocks, the latter is the size of the 
	; directory (# of directory entries) on the drive. 2047 is OK for a 12M
	; drive, should be larger on this 22M drive.
	DW	320		; 128 byte SPT	 SEC=9sptx4hdsx8logical
	DB	5,31,1		; BSH,BLM,EXM		BLS=4096	 
	DW	5499,2047	; DSM,DRM		DRM=2048	 
	DB	255,255		; AL0,AL1		DRM+1/32 bits hi 
	DW	8000h,0		; CKS,OFF		DRM+1/4		 
	DB	2,3		; PSH,PHM				 
	db	'A'

 ;   Misc storage
data$ports:	db	p$TRM$data, p$MDM$data	; serial base ports
src$bnk:	db	0			;source bank f/xmove DO NOT
dst$bnk:	db	0			;dest	 "    "	  CHANGE ORDER
xmv$flg:	db	0			;xmove flag
buffer:		ds	128			;xmove buffer
@cbnk		db	0			; bank for processor operations
Frac:		db	00			;Fractions of Seconds for RTC
TimTbl:		db	60h,60h,24h		;Max Seconds,Minutes,Hours
xofflist	rept	max$devices		; ctl-s clears to zero
		db	-1
		endm

 ;   Stack space allocation
		ds	18	;RTC Int stack space
RTCstk:		ds	2	;storage for SP on entry to RTC
		ds	4	;boot&wboot stack space
boot$stack	equ	$

 ;********************** Dseg Code ********************************************
	dseg			; this part is banked

 ;*****************
 ; Select Disk
 ;*****************
seldsk:
	mov	a,c
	sta	@adrv		; save drive select code
	mov	l,c
	mvi	h,0
	dad	h		; create index from drive code
	lxi	b,@dtbl
	dad	b		; get pointer to dispatch table
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a		; point at disk descriptor
	ora	h
	rz
	mov	a,e
	ani	1
	jrnz	not$first$select
	push	h
	xchg
	lxi	h,-2
	dad	d
	mov	a,m
	sta	@rdrv
	lxi	h,-6
	dad	d
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a
	call	ipchl
	pop	h
not$first$select:
	ret

 ;*****************
 ; Home Disk
 ;*****************
home:
	lxi	b,0		; same as set track zero

 ;*****************
 ; Set Desired Track
 ;*****************
settrk:
	mov	l,c
	mov	h,b
	shld	@trk
	ret

 ;*****************
 ; Set Desired Sector
 ;*****************
setsec:
	mov	l,c
	mov	h,b
	shld	@sect
	ret

 ;*****************
 ; Set Desired DMA adr
 ;*****************
setdma:
	mov	l,c
	mov	h,b
	shld	@dma
	lda	@cbnk		; default DMA bank is current bank
setbnk:
	sta	@dbnk
	ret

 ;*****************
 ; Logical to physical sector translation
 ;*****************
sectrn:
	mov	l,c
	mov	h,b
	mov	a,d
	ora	e
	rz
	xchg
	dad	b
	mov	l,m
	mvi	h,0
	ret

 ;*****************
 ; Read sector
 ;*****************
read:
	lhld	@adrv
	mvi	h,0
	dad	h		; get drive code and double it
	lxi	d,@dtbl
	dad	d		; make address of table entry
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a		; fetch table entry
	push	h		; save address of table
	lxi	d,-8
	dad	d

	jr	rw$common	; use common code

 ;*****************
 ; write sector
 ;*****************
write:
	lhld	@adrv
	mvi	h,0
	dad	h		; get drive code and double it
	lxi	d,@dtbl
	dad	d		; make address of table entry
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a		; fetch table entry
	push	h		; save address of table
	lxi	d,-10
	dad	d

rw$common:
	mov	a,m
	inx	h
	mov	h,m
	mov	l,a		; get address of routine
	pop	d		; recover address of table
	dcx	d		; point to drive type
	ldax	d
	sta	@type		; post drive type
	dcx	d		; point to relative drive
	ldax	d
	sta	@rdrv		; get relative drive code and post it
	inx	d
	inx	d		; point to DPH again
ipchl:	pchl			; leap to driver

 ;*****************
 ; Multiple Sector I/O
 ;	&
 ; Flush buffers
 ;*****************

multio:				;not implemented
	xra	a
	ret

flush:				;not implemented
	xra	a
	ret

 ;*****************
 ; Print message to terminal
 ;*****************
pmsg:				; print msg pointed to by <HL>
	push	b		; until a null is found
	push	d		; saves <BC> & <DE>
pmsg$loop:
	mov	a,m
	ora	a
	jrz	pmsg$exit
	mov	c,a
	push	h
	call	?conout
	pop	h
	inx	h
	jr	pmsg$loop
pmsg$exit:
	pop	d
	pop	b
	ret

 ;*****************
 ; Print Disk error message
 ;*****************
pderr:
	lxi	h,drive$msg
	call	pmsg		; error header
	lda	@adrv
	adi	'A'
	mov	c,a
	call	?conout		; drive code
	lxi	h,track$msg
	call	pmsg		; track header
	lhld	@trk
	call	pdec		; track number
	lxi	h,sector$msg
	call	pmsg		; sector header
	lhld	@sect
pdec:				 ; Convert HL to decimal and print (0->65535)
	lxi	b,table10
	lxi	d,-10000
next:	mvi	a,'0'-1
pdecl:	push	h
	inr	a
	dad	d
	jrnc	stoploop
	inx	sp
	inx	sp
	jr	pdecl
stoploop:
	push	d
	push	b
	mov	c,a
	call	?conout
	pop	b
	pop	d
nextdigit:
	pop	h
	ldax	b
	mov	e,a
	inx	b
	ldax	b
	mov	d,a
	inx	b
	mov	a,e
	ora	d
	jrnz	next
	ret

 ;********************** Dseg Data ********************************************

 ;   Disk Parameter Headers
xdph0:
	dw	f$write		; Write vector
	dw	f$read		; Read Vector
	dw	f$login		; Login vector
	dw	f$init		; Init vector
	db	0		; UNIT	->@rdrv
	db	PMC101d		; TYPE
dph0:	dw	Trans0		; XLT	Translate Table Address
	db 0,0,0,0,0,0,0,0,0	; -0-	BDOS scratch area
	db	0		; MF	Media Flag
	dw	dpb0		; DPB	Disk Parameter Block
	dw	ck0		; CSV	Checksum Vector
	dw	al0		; ALV	Allocation Vector
	dw	0FFFEh		; DIRBCB Directory Buffer Control Block Vector
	dw	0FFFEh		; DTABCB Data Buffer Control Block Vector
	dw	0FFFEh		; HASH	 Hash Table Vector
	db	0		; HBANK Hash Bank

xdph1:
	dw	f$write,f$read,f$login,f$init
	db	1,PMC101d
dph1:	dw	Trans1
	db	0,0,0,0,0,0,0,0,0,0
	dw	dpb1,ck1,al1,0FFFEh,0FFFEh,0FFFEh
	db	0
; If we'll never use more than 2 floppy dirves, the entries for 
; drive 2 & 3 may be removed to sav RAM
xdph2:
	dw	f$write,f$read,f$login,f$init
	db	2,PMC101d
dph2:	dw	Trans2
	db	0,0,0,0,0,0,0,0,0,0
	dw	dpb2,ck2,al2,0FFFEh,0FFFEh,0FFFEh
	db	0

xdph3:
	dw	 f$write,f$read,f$login,f$init
	db	 3,PMC101d
dph3:	dw	 Trans3
	db	 0,0,0,0,0,0,0,0,0,0
	dw	 dpb3,ck3,al3,0FFFEh,0FFFEh,0FFFEh
	db	 0

xdph12:
	dw	f$Hwrite,f$Hread,f$Hlogin,f$Hinit
	db	00h,0					;drive #0, ID=0
dph12:	dw	0000					;no trans for HD
	db	0,0,0,0,0,0,0,0,0,0
	dw	dpbHD,0000,al12,0FFFEh,0FFFEh,0FFFEh	;no ck12 vector
	db	0

xdph13:
	dw	f$Hwrite,f$Hread,f$Hlogin,f$Hinit
	db	1,0					;drive #1, ID=0
dph13:	dw	0000					;no trans for HD
	db	0,0,0,0,0,0,0,0,0,0
	dw	dpbHDB,0000,0FFFEH,0FFFEh,0FFFEh,0FFFEh	   ;no ck12 vector
	db	0


 ;*****************************

 ; OVERLAY:	Since BOOT is only called once the Boot code is overlayed by
 ;		 buffer space allocated to  CKS & ALL.

overlay$1:			;Define addresses of buffers

	;Set buffer size to largest needed by any drive in 'CONVERT'
	; FIX me - need to look at this and see whether it's useful .. (7/1/21)

ck0	equ	overlay1 ;5"	CHECKSUM VECTOR	 DRM+1/4
ck1	equ	ck0+48		;set for max required in CONVERT
ck2	equ	ck1+48		
ck3	equ	ck2+48
nxt$adr set	ck3+48
ck12	equ	nxt$adr	 ;HD
ck13	equ	ck12+0
nxt$adr set	ck13+0
al0	equ	nxt$adr	 ;5"	ALLOCATION VECTOR  DSM/4+2
al1	equ	al0+101		;set for max required in CONVERT
al2	equ	al1+101		;101 for 96 tpi, 65 for 48 tpi
al3	equ	al2+101 
nxt$adr set	al3+101
al12	equ	nxt$adr	 ;HD
al13	equ	al12+690
next$adr set	al13+690	; don't expand this, it will break the gencpm setup
				; and wreak havoc in the running system
				; Drives other than HD0 have autogenerated alloc buffers

 ;*****************
 ; Cold Boot
 ;*****************
boot:
	di			;BOOT ROM & CPMLDR leave us in di mode
	lxi	sp,boot$stack
	lxi	h,0		;clear drives 2,3,4 from drive table
	shld	@dtbl+2		; (they must be present for GENCPM to allocate
	shld	@dtbl+4		;   the proper buffers)
	shld	@dtbl+6
	ldai			; I reg contains drive quantity (from BOOT ROM)
	dcr	a		; Drop count
	jrz	no$more$drives	; if 0 then drive B is not present
	lxi	h,dph1		;else set dph adr into drive table
	shld	@dtbl+2
	dcr	a		; Drop count
	jrz	no$more$drives	; if 0 then drive C is not present
	lxi	h,dph2		;else set dph adr into drive table
	shld	@dtbl+4
	dcr	a		; Drop count
	jrz	no$more$drives	; if 0 then drive D is not present
	lxi	h,dph3		;else set dph adr into drive table
	shld	@dtbl+6
no$more$drives
				;BOOT ROM sets Baud rate, so we
				; set current Baud Rates into @ctbl
	in	p$getbaud	;read current baud rates
	mov	c,a		;save in c
	ani	0fh		;mask off unwanted bits
	cpi	10		;if the baud rate is 9 or less then
	jrnc	no$change1	;we need to up it 1 rate to
	inr	a		;compensate for our 2000 baud rate
no$change1:			;which they do not support
	sta	@Bbaud		;save in B channel baud slot of Char table
	mov	a,c		;restore baud
	rrc			;move A chan bits to Lo nibble
	rrc
	rrc
	rrc
	ani	0fh		;mask off unwanted bits
	cpi	10		;if the baud rate is 9 or less then
	jrnc	no$change2	;we need to up it 1 rate to
	inr	a		;compensate for our 2000 baud rate
no$change2:			;which they do not support
	sta	@Abaud		;save in A channel baud slot of Char table

 ;   Next set up the Device Vectors
				;		Logical Physical Baud Prot-
				;		device	device	 Rate ocol
				;
				;+----------->	dev 00	TERMNL	 9600
				;|+---------->	dev 01	MODEM	 9600
				;||+--------->	dev 02	CEN	 none
				;|||+-++++-++++---> dev 03-11
				;|||| |||| |||| ++++-> reserved
				;|||| |||| |||| ||||
	lxi	h,08000h	; assign TERMNL to CON:
	shld	@civec
	shld	@covec
	lxi	h,4000H		; assign MODEM to AUX:
	shld	@aivec
	shld	@aovec
	lxi	h,2000H		; assign CEN to LPT:
	shld	@lovec

	lxi	h,INTvec	; Set I register with MSB of the Interrupt Vect
	mov	a,h
	stai
	im2			;Set IM 2 interrupt mode

	lxi	h,CTCvec	;get CTC interrupt Vector
	mvi	b,4		;CTC channel quantity
	mvi	c,p$rtc		;1st CTC ch
	mvi	a,03		;RESET command
	outp	a		;reset channel 0
	outp	l		;set LSB of CTC Interrupt Vector into ch0
init$lp:inr	c
	outp	a		;reset all other channels
	djnz	init$lp
	ei

	lxi	h,signon$msg
	call	pmsg		; print signon message
	jmp	boot$1		; back to Cseg code

signon$msg	db	'128K PMC-101	    CP/M 3.0 with banked HD Bios'
		db	' for MicroMate	  -Vers'
		db	pgm,'.',vrs,'-',cr,lf,0

 ; End of BOOT routine cannot exceed the length of the buffers!
 ; BOOT routine cannot do any Disk IO
 ;(length of buffers) - (length of BOOT) = size of space still to be defined
 ;  for buffers

	ds	(next$adr-overlay$1)-($-boot)

 ;*****************
 ;   Translation Tables
	; Each drive must have its own Trans table for 'CONVERT'
	; Each table has a fixed length, set to largest used by 'CONVERT'

Trans0: db	1,2,3,4,5	;Side 0
	db	6,7,8,9,10	;Side 1
	ds	trans$length-($-Trans0) ; room for expansion

Trans1: db	1,2,3,4,5	;Side 0
	db	6,7,8,9,10	;Side 1
	ds	trans$length-($-Trans1)

Trans2: db	1,2,3,4,5	;Side 0
	db	6,7,8,9,10	;Side 1
	ds	trans$length-($-Trans2)

Trans3: db	1,2,3,4,5	;Side 0
	db	6,7,8,9,10	;Side 1
	ds	trans$length-($-Trans3)

;   Variable Storage
@type		ds	1		; currently selected format type
@adrv		ds	1		; currently selected disk drive
@rdrv		ds	1		; controller relative disk drive
@trk		ds	2		; current track number
@sect		ds	2		; current sector number
@dma		ds	2		; current DMA address
@dbnk		db	0		; bank for DMA operations

 ;   Disk Error message
drive$msg	db	cr,lf,bell,'Error on ',0
track$msg	db	': T-',0
sector$msg	db	', S-',0
table10:	dw	-1000,-100,-10,-1,0		;Hex to Dec table

	end


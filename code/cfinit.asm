;==================================================================================
;
; CFcard/IDE drive diagnostic program for Micromate PMC 101
; 
; Adapted from Grant Siearle's Format128 program for the SBC-Z80 project
; For Micromate Z80 PMC 101 running under CPM3
; ORG 0100H
;
; Check the docs directory for documentation.
;
; Helge Skrivervik © 2020
;
;==================================================================================


#target ram

; CF registers
CF_DATA		.EQU	$00
CF_FEATURES	.EQU	$01
CF_ERROR	.EQU	$01
CF_SECCOUNT	.EQU	$02
CF_SECTOR	.EQU	$03
CF_CYL_LOW	.EQU	$04
CF_CYL_HI	.EQU	$05
CF_HEAD		.EQU	$06	; actually C/D/H, but C/D are mostly 
				; irrelevant or otherwise 0
				; NOTE: The number is HEADS-1 (max-head), not head count.
CF_STATUS	.EQU	$07
CF_COMMAND	.EQU	$07
CF_REQUEST_SENSE .EQU	$03
CF_LBA0		.EQU	$03
CF_LBA1		.EQU	$04
CF_LBA2		.EQU	$05
CF_LBA3		.EQU	$06

CF_DUMMY	.EQU	$40	; just toggle A6 to trigger the IDE interface

;CF Features
CF_8BIT		.EQU	1
CF_8BIT_OFF	.EQU	$81
CF_NOCACHE	.EQU	$82

;CF Commands
CF_READ_SEC	.EQU	$20
CF_WRITE_SEC	.EQU	$30
CF_SET_FEAT	.EQU 	$EF
CF_RESET	.EQU	$04		; Soft reset
CF_DRIVE_ID	.EQU	$EC		; Identify Drive
CF_INIT_PARM	.EQU	$91		; Initialize Drive Parameters
					; TO change heads and sectors per track

LF		.EQU	$0A		;line feed
CR		.EQU	$0D		;carriage RETurn

; CP/M defines
BDOS		.EQU	5
RCHAR		.EQU	1
WCHAR		.EQU	2
FCB		.EQU	$5c
OPEN		.EQU	15
CLOSE		.EQU	16
DELETE		.EQU	19
MAKEF		.EQU	22
WRITE		.EQU	21
SETDMA		.EQU	$1a
DBUF		.EQU	$80
READLINE	.EQU	10	; Read console buffer

;===========================================================================
#code	_BASE, 0x100, *

		ORG	$100	

		ld	hl,0
		add	hl,sp
		ld	(StackSave),hl	; SAve stack ptr
		ld	sp, StackEnd
		CALL	printInline
		.TEXT "CF card utility program"
		.DB CR,LF,0

		CALL	cfWait
		LD	A,CF_RESET	; Reset CF card (soft)
		OUT	(CF_COMMAND), A

		CALL	cfWait
					; 
		LD 	A,CF_8BIT	; Set IDE to 8bit 
		OUT	(CF_FEATURES),A
		CALL	cfWait
		LD	A,CF_SET_FEAT
		OUT	(CF_COMMAND),A

		CALL	CFREAD
		;LD 	A,CF_NOCACHE	; No write cache
		;OUT	(CF_FEATURES),A
		;LD	A,CF_SET_FEAT
		;OUT	(CF_COMMAND),A
		;
		; Here is the command loop, exit on Q or X
CMD_LOOP:	ld	HL, Prompt
		call	printStr
		call	conin	; Read console
		and	0DFH	; Convert to upper
		cp	'X'
		jp	Z,exit
		cp	'Q'
		jp	Z,exit
		call	CMD
		jr	CMD_LOOP
		;
CMD:		; Decode & Execute command
		; CMD in A
		;
		cp	'R'
		jp	Z, CFREAD
		cp	'G'
		jp	Z, GETDATA
		cp	'D'
		jp	Z, DUMP
		cp	'C'
		jp	Z, CHS
		cp	'I'
		jp	Z, FILLDIR
		cp	'F'
		jp	Z, CFDATA
		cp	'L'
		jp	Z, FILLDATA
		cp	'H'
		jp	Z, HELP
		cp	'T'	; test number input
		jp	Z, TEST
		cp	'M'	; read and set new CHS params
		jp	Z, MCHS
		cp	'S'	; set LBA to read
		jp	Z, SETLBA
		cp	'U'	; set UNIT #
		jp	SETUNIT
		cp	'Y'	; Reset IO mode
		jp	Z, SET16
		call	printInline
		.BYTE	CR, LF, "No such command", CR, LF, 0
		ret
exit:
		ld	d,$80
		ld	c,SETDMA
		call	BDOS
		ld	hl,(StackSave)
		ld	sp,hl
		ret	; to CCP
	
FILLDATA:	; fill buffer with '5a' pattern, write to CF (current block)
		call	FILLBUF
		call	shortLBA
		call	writeDir
		jp	DUMPBUF

FILLBUF:	ld	hl, BUFFER
		;ld	bc, 512
		;ld	a, $e5
		ld	bc, 256

FILLBF1:	;ld	(hl),a
		ld	(hl),c
		inc	HL
		ld	(hl), $0ff
		inc	hl
		dec	c
		jr	NZ, FILLBF1
		dec	b
		jr	NZ, FILLBF1	
		ret
FILLDIR:
		; Fill buffer with initialized dir entries, startting at set LBA address
		ld	a,4
		ld	de,BUFFER
FILLD0:
		ld	hl,dirData
		ld	bc, 128
		ldir	
		dec	a
		jr	nz,FILLD0	; repeat four times
FILLD3:		ld	b,128	; # of blocks to fill
FILLD4:		push	bc
		call	shortLBA; assuming LBA has been set already
		call	writeDir
		pop	bc
		dec	b
		ret	z
		ld	hl,(lba0)	; covers lba0 & lba1
		inc	hl
		ld	(lba0),hl
		jr	FILLD4
		
GETDATA:	; read data block from CF card
		ld	hl,BUFFER	
		call	readDir
		jp	DUMPBUF

CFREAD:		CALL	cfWait	
		LD	HL, BUFFER
		call	cfRead
		CALL	printInline
		.TEXT "Read CF data OK."
		.DB CR,LF,0
		
		; Print the ID content
CFDATA:		LD	HL, Serial
		call	printStr
		LD	HL, BUFFER+20
		LD	B, 20
		call	printN		; print serial number
		LD	HL, Firmware
		call	printStr
		LD	HL,BUFFER+46
		LD	B, 8
				; Some cards/adapters need this swap, others don't
		call	printNF	; print Firmware rev
		LD	HL, Model
		call	printStr
		LD	HL,BUFFER+54
		LD	B,40
		call 	printNF		; Print model number (Big endian byte order in word)
		LD	HL, LBA
		call	printStr	; Print the LBA count (RAW)
		LD	HL,BUFFER+123
		LD	A, (HL)
		CALL	NMout
		DEC	HL
		LD	A, (HL)
		CALL	NMout
		DEC 	HL
		LD	A,(HL)
		CALL	NMout
		DEC	HL
		LD 	A,(HL)
		JP	NMout
		;
		; Print CHS data, default and actual
CHS:		LD	HL, Def_CHS
		call	printStr
		LD	HL, (BUFFER+2)
		LD	BC, (BUFFER+6)
		LD	DE, (BUFFER+12)
		call	printCHS
		LD	HL, Act_CHS
		call	printStr
		LD	HL, (BUFFER+108)
		LD	BC, (BUFFER+110)
		LD	DE, (BUFFER+112)
		JP	printCHS	; Effective return
		;
		; Dump the entire ID block 
DUMP:		; (actually just the first half, the second is empty)
		LD	HL, Dumpmsg
		call 	printStr
DUMPBUF:
		ld	hl,BUFFER
		LD	BC, 512
		call	DumpHex
		RET		; EXIT

	        ; Reset 8bit io status (return to normal)
SET16:          CALL    cfWait
                LD      A,CF_RESET      ; Reset CF card (soft)
                OUT     (CF_COMMAND), A

                CALL    cfWait
                                        ;
                LD      A,CF_8BIT_OFF       ; Set IDE to 8bit
                OUT     (CF_FEATURES),A
                LD      A,CF_SET_FEAT
                OUT     (CF_COMMAND),A
                CALL    cfWait
		RET

DumpHex:	; Really just a hex dump routine with the content buffer in HL, count in BC
		push	HL
		POP	IX		; Use IX as buffer pointer
		ld	DE, 0		; DE is byte counter for line index
		jr	Dump3
Dump1:		ld	a,e
		and	$f		; fixed length, 16
		jr	NZ, Dump2
		; Insert newline & byte count
		push	bc
		ld	a,e
		dec	a
		and	$f
		ld	b,a	; length (base 0)
		call	hexAsc	; Print ascii part
		pop	bc
Dump3:		ld	HL, CRLF
		call	printStr
		ld	a,d
		call	NMout
		ld	a,e
		call	NMout
		ld 	a, ':'
		call	conout
		ld	a, ' '
		call	conout
		ld	IY,Hexbuf; Use IY as pointer to the ascii buffer
				; NOTE: Hexbuf has limited length, this may overflow...
Dump2:		ld	A, (IX)
		ld	(IY+0),a
		inc	IY
		call	NMout	; Hex out
		ld	a, ' '
		call	conout	; single space
		inc	IX
		inc	DE
		ld	HL, DE
		SBC	HL, BC		; may need to reset carry????
		jr	NZ, Dump1	; LSB of counter iz zero
Dump4:		; Cleanup
		ld	a,e	; length
		dec	a
		and	$f	; assume max 16
		ld	b,a
		call	hexAsc
		ld	HL, CRLF
		call	printStr
		ret

printCHS:	; Print CHS formatted
		; C in HL, H in C, S in DE
		push	DE
		push	BC
		CALL	BIN16	; print cylinders from HL
		ld	a,'/'
		call	conout
		pop	HL
		ld	h, 0	; Zero upper half (# of heads always < 255)
		CALL	BIN16	; print heads
		ld	a,'/'
		call	conout
		pop	HL
		CALL	BIN16	; Print sectors per track
		ld	HL, CRLF
		jp	printStr	; return via printStr
		;
HELP:		call	printInline
		.BYTE	CR,LF,"Valid commands:",CR,LF
		.BYTE	"D - Dump memory buffer in hex",CR,LF
		.BYTE	"C - Show default and actual CHS data", CR,LF
		.BYTE	"I - Init directory starting at LBA", CR,LF
		.BYTE	"R - Read CF ID data into buffer", CR,LF
		.BYTE	"G - Get CF data block into buffer", CR,LF
		.BYTE	"L - Load diag pattern into current CF block", CR, LF
		.BYTE	"F - Show data in buffer", CR,LF
		.BYTE	"H - Help, show this message",CR,LF
		.BYTE	"T - Test decimal number input and conversion", CR,LF
		.BYTE	"M - Modify CHS", CR, LF
		.BYTE	"Y - reset to 16 bit mode", CR, LF
		.BYTE	"S - set LBA # to read", CR, LF
		.BYTE	"U - set drive unit for I/O", CR, LF
		.BYTE	"X or Q - Exit program",CR,LF,0
		ret

TEST:		;Test decimal # input
		call	printInline
		.BYTE	CR,LF,"$ >", 0
		ld	HL, inBuf
		ld	b, 5	; Max len
		call	GETSTR		; string pointer in HL
		call	ABIN		; BINARY value in HL
		call	printInline
		.BYTE	" Got: ",0
		jp	BIN16

SETUNIT:	; set drive unit to use for IO (# in lba2)
		call	printInline
		.BYTE	CR,LF,"Drive# (",0
		ld	a,(lba2)
		ld	l,a
		ld	h,0
		call	BIN16
		call	printInline
		.BYTE	") > ",0
		ld	b,3
		ld	hl,inBuf
		call	GETSTR
		ld	a,(hl)
		cp	3	; ^C
		ret	z
		call	ABIN
		call	printInline
		.BYTE	CR,LF,"Selected drive: ",0
		ld	a,l
		ld	(lba2),a
		jp	BIN16

SETLBA:		; Set block # to read 
		call	printInline
		.BYTE	CR,LF,"LBA# (", 0
		ld	h,0
		ld	a,(lba2)
		ld	l,a
		call	BIN16
		ld	a,'/'
		call	conout
		ld	hl,(lba0)
		call	BIN16
		call	printInline
		.BYTE	") > ",0
		ld	b,6	; max len
		ld	hl,inBuf
		call	GETSTR
		ld	a,(hl)
		cp	3	; check for ^C
		ret	z
		call	ABIN
		push	hl
		call	printInline
		.BYTE	CR,LF,"Set LBA# to ",0
		ld	h,0
		ld	a,(lba2)
		ld	l,a
		call	BIN16
		ld	a,'/'
		call	conout
		pop	hl
		ld	(lba0),hl	; Save new values
		jp	BIN16	; print value, return

;
; Modify CHS parameters
;
MCHS:		call	printInline
		.BYTE	CR,LF,"Enter new C/H/S values: ", 0
		ld	HL,inBuf
		ld	b,12	; max 12 chars xxxx/xx/zzz
		call	GETSTR
		push	HL
		call	printInline
		.BYTE	" Got: ",0
		ld	HL, CRLF
		call	printStr
		pop	HL
		push	HL
		call	printStr
		call	printInline
		.BYTE	" OK? ",0
		call	conin
		pop	HL
		cp	'Y'
		ret	NZ
		; convert CHS to binary, really need some error checking here
		ld	B, 0	; count # of '/', really return status
		push	HL
MCHS2:		ld	a,(HL)
		cp	0
		jr	Z, MCHS3
		cp	'/'
		jr	NZ, MCHS1
		inc	b
		ld	(HL),0
MCHS1:		inc	HL
		jr	MCHS2
		;
MCHS3:		; Convert the individual values to binary, store in Buf
		pop	HL
		ld	a,b
		cp	2
		jr	Z, MCHS4
		call	printInline
		.BYTE	"Error in data.",CR,LF,0
		ret
MCHS4:		; Data ptr ready in HL
		ld	IX, Buf
		call	ABIN	; ABIN returns pointer past the NULL in BC
		ld	(IX+0), H ; any other way to do this??
		inc	IX
		ld	(IX+0), L
		inc	IX
		ld	HL, BC	; pointer to next part
		call	ABIN
		ld	(IX+0), H
		inc	IX
		ld	(IX+0), L
		inc	IX
		ld	HL, BC
		call	ABIN
		ld	(IX+0), H
		inc	IX
		ld	(IX+0), L
		; DEbug
		ld	c,6
		ld	HL, Buf
MCHS5:		ld	A, (HL)
		call	NMout
		inc	HL
		dec	c
		jr	NZ, MCHS5
		;RET	; While debugging
		; OK Data ready in Buf
		;
		; Move into CF registers and save
		; NOTE: There is no way to set the Cylinder count, 
		;   apparently it is calculated implicitly
		;   based on the total # of sectors on the drive
		call	cfWait
		LD	A, (Buf+5)	; Sectors
		out	CF_SECCOUNT, A
		LD	A, (Buf+3)	; Heads
		dec	A		; minus one, it's max heads, not head count
		out	CF_HEAD,A
		ld	A, CF_INIT_PARM
		out	CF_COMMAND, A
		call	cfWait
		; Check for errors
		ld	a,(Status)
		and	1
		jr	NZ, errOut	; We have an error condition, print and return.
		call	CFREAD

		; all done
MCHS_end:	ld	HL, CRLF
		call	printStr
		ret
;
errOut:		; Read error status, print and return
		ld	HL, CMD_ERROR
		call	printStr
		IN	A, (CF_ERROR)
		call	NMout
		jr	MCHS_end


cfRead:		; read ID datablock into (HL)
		; NOTE: This is not the same a read sector! 
		LD	A, CF_DRIVE_ID	; Identify drive
		OUT	(CF_COMMAND), A
		CALL	cfWait
cfRead1:	IN	A, (CF_STATUS)	; Status is already in A ...?
		AND	08H		; DRQ set?
		CP	08H
		RET	NZ
		IN	A, (CF_DATA)	; Read a byte
		LD	(HL), A
		INC	HL
		JR	cfRead1

;====================================================================================
; Read physical block from card, block number in LBA0-2
; Buffer address in HL
;====================================================================================

readDir:
		PUSH 	AF
		PUSH 	BC
		PUSH 	HL

		CALL 	cfWait
		call	shortLBA
		;call	setLBAaddr

		LD 	A,CF_READ_SEC
		OUT 	(CF_COMMAND),A

		CALL 	cfReady
		ld	c,CF_DATA
		ld	b,0
		INIR
		INIR
		call	cfOK

		POP 	HL
		POP 	BC
		POP 	AF

		RET
;==================================================================================
; Write physical sector to host
;==================================================================================

writeDir:
		PUSH 	AF
		PUSH 	BC
		PUSH 	HL

		CALL 	cfWait

		LD 	A,CF_WRITE_SEC
		OUT 	(CF_COMMAND),A

		CALL 	cfReady
		ld	c,CF_DATA
		ld	hl,BUFFER
		ld	b,0
		OTIR
		OTIR
		call	cfOK

		POP 	HL
		POP 	BC
		POP 	AF

		RET
;===============================================

shortLBA:
; LBA Mode using drive 0 = E0
		call	cfWait
		LD	a,0E0H
		LD	(lba3),A
		OUT 	(CF_LBA3),A	; 

		LD	A,(lba0)
		OUT 	(CF_LBA0),A

		LD	A,(lba1)
		OUT 	(CF_LBA1),A

		LD	A,(lba2)
		OUT 	(CF_LBA2),A

		LD 	A,1
		OUT 	(CF_SECCOUNT),A		; One sector at a time..

		RET
;==================================================================================
; Utilities
;==================================================================================

		;
		; Print the null termintated string immediately following the call
		;
printInline:
		EX 	(SP),HL 	; PUSH HL and put RET ADDress into HL
		PUSH 	AF
		PUSH 	BC
nextILChar:	LD 	A,(HL)
		CP	0
		JR	Z,endOfPrint
		call	conout
		INC 	HL
		JR	nextILChar
endOfPrint:	INC 	HL 		; Get past "null" terminator
		POP 	BC
		POP 	AF
		EX 	(SP),HL 	; PUSH new RET ADDress on stack and restore HL
		RET
		;
		; Print null terminated string pointed to by HL
		;
printStr:	LD	A, (HL)		; String in (HL)
		CP	0
		RET	Z
		call	conout
		INC	HL
		JR	printStr

printN:		; Print N characters, count in B, buffer in HL
		ld	a, b
		CP 	0
		RET	Z
		LD	A, (HL)
		call	conout		; print byte
		INC	HL
		DEC	B
		JR	printN
printNF:	; Big endian, reverse byte order (assume even number of chars...)
		ld	a, b
		CP 	0
		RET	Z
		LD	C, (HL)
		INC	HL
		DEC	B
		LD	A, (HL)
		INC	HL
		DEC	B
		call	conout
		ld	a,c
		call	conout
		JR	printNF
		;
NMout:		; Convert binary BYTE in A to two hex digits and print
		;
		push	HL
		push	BC
		push	AF
		RRC	A
		RRC	A
		RRC	A
		RRC	A
		AND	$0F
		CALL	PRval
		call	conout	; print left nibble
		pop	AF	; restore A, get right nibble
		AND	$0F
		CALL	PRval
		call	conout
		pop	BC
		pop	HL
		RET
PRval:
		CP	10
		JP	M, PRval1
		ADD	A, 'A'-10
		ret
PRval1:		add	A, '0'
		ret
		;
		; For hexdump - print ascii values @ the end of the line
		; Counter in b
hexAsc:		ld	hl, Hexbuf	; may want to take address as parameter
		;ld	b, 16	; counter
		inc	b	; base 1
hexAsc1:	dec	b
		ret	M	; Neg means we're done
		ld	a, (hl)	; get byte
		inc	hl
		cp	20h	; Lowest
		jp	M,hexAsc3	; send '.'
		cp	7dh
		jp	p,hexAsc3
		call	conout	; print
		jr	hexAsc1	; continue
hexAsc3:	ld	a,'.'
		call	conout
		jr	hexAsc1

BIN16:		; print 16 bit # in HL in decimal ascii
		; Adapted from Alan R Miller's 8080/Z80 book
		;
		ld	b, 0	; leading zero flag
		ld	de, -10000 ; 2's complement
		call	SUBTR	; 10 thousand
		ld	de, -1000
		call	SUBTR	; thousands
		ld	de, -100
		call 	SUBTR	; hundreds
		ld	de, -10
		call	SUBTR	; tens
		ld	a,l
		add	'0'
		call	conout	; print final digit
		ret
		; Subtract power of the and count
SUBTR:		ld	c, '0'-1
SUBT2:		inc	c
		add	HL,DE	; Add neg #
		jr	C, SUBT2
		; One too many, add one back ...
		ld	a,d	; Complement 
		CPL		; D, E
		ld	d,a
		ld	a,e
		CPL
		ld	e,a
		inc	DE
		add	HL, DE	; add back to HL
		ld	a,c	; get count
		; check for zero
		CP	A, '1'	; Less than 1
		JR	NC, Nzero ; NO
		ld	a,b	; Check zero-flag
		OR	A	; Set?
		ld	A,C	; restore
		RET	Z
		call	conout
		RET
Nzero:		; Set flag for non-zero char
		ld	B, 0FFH	; Zero flag
		call	conout
		ret
;
; ASCII to binary 16 bit, return value in HL
; Input ptr in HL, null treminated (max 5, 64k)
; 
ABIN:
		push	DE
		ld	BC, HL
		ld	HL, 0
ABIN2:		ld	a, (BC)
		inc	BC
		cp	0
		jr	Z,ABIN3	; End of number
		sub	'0'	; convert to binary
		jr	C, ABIN4; <0 ?
		CP	10
		JR	NC, AERR; > 10 = Error
				; New digit, mult current value by 10
		ld	de,hl	; copy HL
		add	HL,HL	; times 2
		add	HL,HL	; times 4
		add	HL,de	; times 5
		add	HL,HL	; times 10
		ld	e,a	; new digit (binary)
		ld	d, 0
		add	HL,de	; add this digit
		jr	ABIN2	; next
		;
		; check for blank at EOS
		;
ABIN4:		CP	0f0h	; (' '-'0') AND 0FFH
		JR	NZ, AERR; Something else (not blank) = Error
ABIN3:		POP	DE
		RET
		;
		; Err in input
AERR:		POP	DE	; Clear stack
		ld	a,'?'
		call	conout
		ret
;
; Read string into HL buffer, terminate by 00
; Max length in b, return on CR or LF
;
GETSTR:		
		PUSH	BC
		push	de
		ld	de,hl	; buffer
		ld	a,b
		ld	(de),a	; max length
		ld	c, READLINE
		push	hl
		call	BDOS
		pop	hl
		inc	hl	; HL is now -> # of read chars
		ld	a,(hl)
		inc	hl	; adjust buffer ptr
		push	hl
		ld	c,a	
		ld	b,0
		add	hl,bc	; end of string
		ld	(hl),0	; null terminate
		pop	hl
		;ld	c,b	; copy of counter
GETST2:		;ld	a,b
		;cp	0
		;jr	Z, GETST3
		;call	conin
		; should test for number here ...
		;cp	0dh
		;jr	Z, GETST3
		;cp	0ah
		;jr	Z, GETST3
		;cp	08	; Backspace
		;jr	Z, DELCHAR
		;cp	$7f	; Del
		;jr	NZ, GETST4
DELCHAR:	;ld	a,b
		;cp	c	; If the read buffer is empty, ignore BS
		;jr	Z, GETST2
		;call	printInline
		;.BYTE	8,' ',8,0	; Visually delete char
		;inc	b	; Reset counter
		;jr	GETST2	; Continue
GETST4:		;ld	(HL), a
		;dec	b
		;inc	HL
		;RST	8	; ECHO
		;jr	GETST2	; Continue
GETST3:		;ld	(HL), 0	; Terminate #
		ld	a,LF
		call	conout
		pop	de
		pop	BC
		ret

;================================================================================
; Wait for disk to be ready (busy=0,ready=1)
;================================================================================
cfWait:
		PUSH 	AF
cfWait1:
		;in	A,(CF_DUMMY)	; pulse A6 - testing
		in 	A,(CF_STATUS)
		AND 	$080
		cp 	$080
		JR	Z,cfWait1
		in 	A,(CF_STATUS)
		ld	(Status), a	; Save status
		POP 	AF
		RET

cfReady:	in	a,(CF_STATUS)
		and	$48
		cp	$48
		jr	nz,cfReady
		ret
cfOK:		in	a,(CF_STATUS)
		and	$40
		cp	$40
		jr	nz,cfOK
		ret
;============================================
; CP/M interface
;============================================
conout:		push	bc
		push	hl
		push	de
		ld	e,a
		ld	c,WCHAR
		call	BDOS
		pop	de
		pop	hl
		pop	bc
		ret
conin:		
		ld	c,RCHAR
		jp	BDOS
fopen:		ld	de,FCB
		ld	c,DELETE
		jp	BDOS
fclose:		ld	de,FCB
		ld	c,CLOSE
		jp	BDOS
fwrite:		ld	de,FCB
		ld	c,WRITE
		jp	BDOS

Status:		.db	0
lba0:		.db	0
lba1:		.db	0
lba2:		.db	0
lba3:		.db	0
setlba:		.dw	0	; block to read in get operation
StackSave:	.ds	2
inBuf:		.DS	20H	; Misc input
Buf:		.DS	10	; Misc buffer
Hexbuf:		.DS	20	; ascii values for hex dump display
CRLF		.DB	$0a, $0d, $00
CMD_ERROR:	.BYTE	$0a, $0d, " CF-Error: ", 0
Serial:		.BYTE	$0a, $0d, " Serial #: ", $00
Firmware:	.BYTE	$0a, $0d, " Firmware: ", $00
LBA:		.BYTE	$0a, $0d, " LBA Size: ", $00
SHT:		.BYTE	$0a, $0d, " Sectors/Heads/Tracks: ", $00
Model: 		.BYTE	$0a, $0d, " Model: ", $00
Dumpmsg:	.BYTE	$0a, $0d, " CF Identity Dump:", $0a, $0d, $00
Def_CHS:	.BYTE	$0a, $0d, " Default CHS: ", $00
Act_CHS:	.BYTE	" Actual CHS:  ", $00
Prompt:		.BYTE	$0a, $0d, "# ", 0
Stack:		.DS	256
StackEnd:	.EQU	$


; Directory data for 1 x 128 byte sector
dirData:	
		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

BUFFER:		.DS 520
#end

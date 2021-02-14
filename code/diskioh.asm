	title	'Driver for CF-card disk on Micromate PMC101 - feb2021'
	; HS version 2


 ;	*****************************************************
 ;	*						    *
 ;	*	NOTE:					    *
 ;	*						    *
 ;	*	DO NOT MODIFY ANY CODE IN THIS MODULE	    *
 ;	*						    *
 ;	*	 PMC CANNOT SUPPORT ANY MODIFICATIONS	    *
 ;	*						    *
 ;	*****************************************************

 ;		'DISKIOH'
 ;		' Copyright (C), 1983	Personal Micro Computers, Inc.'
 ;		' 475 Ellis St. Mountain View, CA  94304'
 ;		' version 3.0	   07 FEB. 1984 '


 ;10/01/83	created
 ;02/07/84	no changes
 ;12/20/2020	HS: started work on CF/IDE disk version


	maclib	z80
	maclib	ports
	maclib	pmcequ

 public f$Hread, f$Hwrite, f$Hlogin, f$Hinit
 extrn	@rdrv, @adrv, @dma, @dbnk, @trk, @sect, @ermde, @cbnk, @type
 extrn	RWdon, pdec, pmsg

	dseg

 ;********************
 ; Initialization entry point. called for first time initialization.
 ;
 ;********************

f$Hinit:	; turns out - init is never called ...
f$Hlogin:
	CALL	cfWait
	mvi	A,CF$8BIT       ; Set IDE to 8bit
	OUT	CF$FEATURES
	CALL	cfWait
	mvi	A,CF$SET$FEAT
	OUT	CF$COMMAND
	CALL	cfWait
	mvi	A,CF$NOCACHE    ; No write cache
	OUT	CF$FEATURES
	mvi	A,CF$SET$FEAT
	OUT     CF$COMMAND
	xra	a
	ret

;t$rdwr	dw	0
;t$rd:	db	'rd-',0
;t$wr:	db	'wr-',0

 ;********************
 ; disk READ and WRITE entry points.
 ; these entries are called with the following arguments:
 ; relative drive number IN @rdrv (8 bits)
 ; absolute drive number IN @adrv (8 bits)
 ; disk transfer address IN @dma (16 bits)
 ; disk transfer bank	IN @dbnk (8 bits)
 ; disk track address	IN @trk (16 bits)
 ; disk sector address	IN @sect (16 bits)
 ; pointer to DPH IN <DE>
 ; they transfer the appropriate data, perform retries if necessary,
 ; then return an error code IN <A>
 ;********************

f$Hread:
	mvi	a,CF$READ$SEC
	;lxi	h,t$rd		; DEBUG
	jr	f$rw$common
f$Hwrite:
	;lxi	h,t$wr		; DEBUG
	mvi	a,CF$WRITE$SEC
f$rw$common:
	;shld	t$rdwr	; debug
	sta	iocmd	; save the CF read/write command

	;Algorithm to calc Phy SPT from any DPB!!
	; cf-disk: This is not required, but it makes it easier
	; to experiment with disk sizes in bnkbios3.asm
	lxi	h,12	;offset to DPB
	dad	d
	mov	e,m	;get DPB from DPH
	inx	h
	mov	d,m	
	xchg			
	mov	e,m	;get logical SPT from DPB	
	inx	h
	mov	d,m
	dcx	h
	push	d	;save SPT count
	lxi	d,15	;offset to PSH (shift factor)
	dad	d
	pop	d	;restore SPT count
	mov	a,m	;get PSH from DPB	
	ora	a		
	jrz	noshift	;if 0 shift factor then skip
	mov	b,a
shftlp:			;b=shift factor, de=Log SPT
	srlr	d	;16 bit shift (MSB)
	rarr	e	;	      (LSB)
	djnz	shftlp	
noshift:		; DE has phys SPT
	lxi	h,0	;calculate virtual sector#
	lda	@rdrv	; Assuming 32M (0ffffH sectors) per drive,
			; LBA2 becomes the logical drive #
	sta	lba2
	
noshift1:
	lbcd	@trk
	;dad	b
	;mov	c,l
	;mov	b,h
calc$lp:
	mov	a,b
	ora	c
	jrz	no$calc
	dad	d		;DE=SPT from dpb
	dcx	bc
	jr	calc$lp		; add SPT to HL for every track
no$calc:
	lded	@sect		;add in sector count
	dad	d
	xchg			;DE=logical sector
	; mult DE by 2 (shift left) (for 1024 'sectors')
	;ralr    d       ; shift D left
	;rlcr    e       ; shift e left thru carry
	;jrnc    nc2
	;setb    1,d     ; if carry, set LSbit in D
nc2:
	; this is ld (lba0),de
	sded	lba0	; save lba0 & lba1,
			; replacing the following:
	;mov	a,d
	;sta	lba1
	;mov	a,e
	;sta	lba0

; debug print lba0-1 numbers ------------------------------
	;xchg		; these calls destroy all (normal)registers
	;call	pdec	; if enabling these, uncomment the corresponding
	;call	pderr2	; instructions in f$read, f$write, f$common
	;lhld	t$rdwr
	;call	pmsg		; DEBUG
; end debug -----------------------------------------------

	call    setLBA		; set disk address (LBA)
	lxiy    Hwrite
	lda	iocmd		; read or write?
	cpi	CF$WRITE$SEC	; FIXME - move to beginning
	jrz	do$it
	lxiy	Hread
do$it:	
	lda	iocmd		; Get the CF R/W-command
	out	CF$COMMAND	; send read/write cmd
	call	execute
getsta: 
	call	cfWait
	sta     endsta		; save error code from CF card (not used)
	ani	1		; return bit 0, either 0 (OK) or 1 (ERR)
	ret

; prepare CF card for read/write by entering the block address
setLBA:
	call    cfWait
	mvi	a, 0e0h
	out	CF$LBA3
	lda	lba0
	out	CF$LBA0
	lda	lba1
	out	CF$LBA1
	lda	lba2
	out	CF$LBA2
	mvi	a,1
	;mvi	a,2		; if running 1024bps
	out	CF$SECCOUNT
	ret

;=====================================================
; Wait for disk to be ready - return status byte in A
;=====================================================
cfWait:
	in      CF$STATUS
	rlc	; Check the busy bit
	jrc     cfWait
cfWait0:in      CF$STATUS	; Read again, when BSY set, the
				; rest is not reliable
	rlc!rlc			; Test for RDY
	jrnc	cfWait0
	in	CF$STATUS
	ret		; Return complete status in A

;=====================================================

	cseg
 ;**************************************
 ; Set memory bank, do the IO
 ; Implicitly assuming 512 byte sectors
 ; Beware of the bank switching trickery in this segment to get in and out,
 ; no outside calls, no dseg memory references
 ; *************************************
execute:			;must reside in cseg
	lda	@dbnk		;set DMA bank
	lhld	@dma
	di			; test, reset in RWdon
	ora	a
	jrz	exec$1
	dcr	A
	ori	80H		;set hi bit if not bank 0
exec$1: out	p$bankselect
	call	cfW	; returns Zflag reset
		; NOTE - NO calls outside cseg from cseg
	mvi     c,CF$DATA
	mvi	b,0
	pciy	; jump to Hread or Hwrite
Hread:
;	inir ! inir	; for 1024 sectors
	inir ! inir
	jr	Hwrexit		; done

Hwrite:
;	outir ! outir	; for 1024 sectors
	outir ! outir
Hwrexit:
	call	cfDone
	xra	a
	jmp	RWdon

cfW:	; This is a differen cfWait - testing for ready 
	; instead of busy - per the CF note from GALAXYSTOR (see notes)
	;
	in      CF$STATUS
	ani	48h	; DRDY|DRQ
			; ignore seek complete, not reliable?
			; Drive ready/Drive Seek Complete/DataRequest
	cpi	48H
	jrnz     cfW
	ret
cfDone:	in	CF$STATUS
	ani	40h	; Make sure we're done
	cpi	40h
	jrnz	cfDone
	ret
 ;**************************
	dseg

iocmd:	db	0
endsta: db	0	; Currently not used
lba0	db	0
lba1	db	0
lba2	db	0

	end



        title   'Disk I/O routines for CP/M 3.0 & PMC-101'

 ;      *****************************************************
 ;      *                                                   *
 ;      *       NOTE:                                       *
 ;      *                                                   *
 ;      *       DO NOT MODIFY ANY CODE IN THIS MODULE       *
 ;      *                                                   *
 ;      *        PMC CANNOT SUPPORT ANY MODIFICATIONS       *
 ;      *                                                   *
 ;      *****************************************************

 ;              'DISKIO'
 ;              ' Copyright (C), 1983   Personal Micro Computers, Inc.'
 ;              ' 475 Ellis St. Mountain View, CA  94304'
 ;              ' version 3.0      07 FEB. 1984'


 ;04/21/83      created
 ;06/06/83      no changes
 ;10/01/83      no changes
 ;02/07/84      no changes
 ;??/??/??


        maclib  z80
        maclib  ports
        maclib  PMCequ

 public f$read, f$write, f$login, f$init, RWdon
 extrn  @rdrv, @adrv, @dma, @dbnk, @trk, @sect, @ermde, @cbnk, @type
 extrn  ?conin, ?const, ?conout, pderr, pmsg

        dseg

 ;********************
 ; Initialization entry point. called for first time initialization.
 ;
 ;********************

f$init:

 ;********************
 ; This entry is called when A logical drive is about to be logged into for
 ; the purpose of density determination. It may adjust the parameters contained
 ;  IN the disk parameter header pointed at by <DE>
 ;
 ;********************
f$login:
        ret             ;no initialization or login required

 ;********************
 ; disk READ and WRITE entry points.
 ; these entries are called with the following arguments:
 ; relative drive number IN @rdrv (8 bits)
 ; absolute drive number IN @adrv (8 bits)
 ; disk transfer address IN @dma (16 bits)
 ; disk transfer bank   IN @dbnk (8 bits)
 ; disk track address   IN @trk (16 bits)
 ; disk sector address  IN @sect (16 bits)
 ; pointer to XDPH IN <DE>
 ; they transfer the appropriate data, perform retries if necessary,
 ; then return an error code IN <A>
 ;********************

f$read:
        lxi     h,read$msg
        mvi     a,RDcmd
        lxiy    RDent           ;IY->entry point
        jr      f$rw$common
f$write:
        lxi     h,write$msg
        mvi     a,WRcmd
        lxiy    WRent
f$rw$common:
        lxix    Disk$command    
        stx     a,0             ;LD (IX+0),A    save command            
        shld    operation$name  ;save operation in error message
        lda     @rdrv
        lxi     h,track$table   ;set HL to base of Track Table
        call    adahl
        shld    Trk$tbl$ptr     ;Save HL pointing to current track
        mov     a,m
        out     p$fdtrack       ;put cur Trk for this Drv back in tk reg
        mvi     a,4
        call    adahl
        mov     b,m             ;b->  Select Value
        lda     @sect           ;save sector
        sta     s$sect
        lda     @trk            ;save track
        sta     s$trk
        lda     @type           ;check type
        mov     c,a
        ani     0000$0011b      ;mask TYPE bits
        lxi     h,Type$tbl
get$tbl:
        add     a               ;pointer *2
        call    adahl
        mov     a,m             ;get table entry
        inx     h
        mov     h,m
        mov     l,a
        mov     a,c
        pchl                    ;jump

rw$DsSd:                        ;TYPE 1
        setb    DENbit,b        ;set Single Density always
        jr      Ds$Ent

rw$DsDd:                        ;TYPE 0
        res     DENbit,b        ;set Double Density always
Ds$ent: rrc                     ;-0000$000
        rrc                     ;--0000$00
        mov     c,a
        ani     0000$0011b      ;mask SWITCH bits
        lxi     h,switch$tbl
        jr      get$tbl

Sector$switch:
        rrc                     ;---0000$0
        rrc                     ;----0000$
        ani     0000$1111b      ;mask COUNT bits
        adi     6               ;sectors range from 6 to 21
        mov     c,a
        lda     s$sect          ;get desired Sector
        cmp     c               ;see if <=physical Sec/Trk
        jrc     set$S0
        lxi     h,s$sect
change: dcr     c
        sub     c
        mov     m,a
        jr      set$S1
Track$switch:
        rrc                     ;---0000$0
        rrc                     ;----0000$
        mov     c,a
        ani     0000$0011b      ;mask COUNT bits
        lxi     h,Trk$tbl
        call    adahl
        mov     a,c
        mov     c,m
        rrc                     ;-----000
        rrc                     ;------00
        ani     0000$0001b      ;mask side first bit
        ora     a
        jrnz    S1$first
S0$first:
        lda     s$trk           ;get desired Track
        cmp     c               ;see if <=physical Trk/side
        jrc     set$S0
        lxi     h,s$trk
        dcr     c
        sub     c
        mov     m,a
        jr      set$S1
S1$first:
        lda     s$trk           ;get desired Track
        cmp     c               ;see if <=physical Trk/side
        jrc     set$S1
        lxi     h,s$trk
        dcr     c
        sub     c
        mov     m,a
        jr      set$S0

Odd$switch:
        lda     s$trk           ;get desired Track
        bit     0,a             ;0=even=side 0

        push    psw
        rrc                     ;make side 1 same track # as side 0
        ani     0111$1111b
        sta     s$trk
        pop     psw

        jrz     set$S0          ;set side 0 if yes
        jr      set$S1          ;else set side 1
Even$switch:
        lda     s$trk           ;get desired Track
        bit     0,a             ;1=Odd=side 0

        push    psw
        rrc                     ;make side 1 same track # as side 0
        ani     0111$1111b
        sta     s$trk
        pop     psw

        jrnz    set$S0          ;set side 0 if yes
set$S1: setx    SIDbit,0        ;else set Side 1 bit in 1797 cmnd
        jr      select$drive

rw$SsDd:                        ;TYPE 2
        res     DENbit,b        ;set Double Density always
        jr      set$S0

rw$SsSd:                        ;TYPE 3
        setb    DENbit,b        ;set Single Density always
set$S0:
        resx    SIDbit,0        ;set Side 0 always
select$drive:
        call    SelDrv          ;Select & check for Disk  Drive in B
usr$rty:
        xra     a               ;clear retry count
        sta     RtyCnt
retry$lp:
        lda     s$sect
        out     p$fdsector      ;set Sector
        lhld    Trk$tbl$ptr     ;get Track table pointer
        mvi     a,-1            ;if Drv not previously Selected
        cmp     m
        jz      go$home         ;then do a home & go back to retry$lp
        lda     s$trk           ;else get desired track
        cmp     m               ;see if =current track
        jrz     noSek           ;if so skip seek
        out     p$fddata        ;else output track to data port
        mov     m,a             ;save as current Trk
        call    f$seek          ;seek the track
noSek:  mvi     C,p$fddata
        lhld    @dma            ;get DMA adr
        lda     disk$command    ;get command

        call    execute         ;in cseg, sets @dbnk,does I/O,set bank 0,ret

        sta     disk$status     ;save returned status
        lxi     h,disk$command  ;check command
        bit     6,m
        jrz     wr$mask         ;if command was a write use write error mask
        ani     0001$1111b      ;else use read error mask
        jr      save$error
wr$mask:
        ani     0111$1111b      ;mask write errors
save$error:
        jrz     RWexit          ;return if no errors
        lxi     h,RtyCnt
        inr     m               ;up retry count
        mov     a,m
        cpi     retries         ;see if max
        jrz     MaxRty          ;if so set to NZ and ret
go$home:
        call    restore
        jr      retry$lp                ;else home & reseek

MaxRty:
        lda     @ermde          ; suppress error message if BDOS is returning
        cpi     -1              ;       errors to application...
        jrz     hard$error
        call    pderr           ; Had permanent error, print error message
        lhld    operation$name
        call    pmsg            ; then, messages for all indicated error bits
        lda     disk$status     ; get status byte from last error
        lxi     h,err$table     ; point at table of message addresses
errm1:  mov     e,m
        inx     h
        mov     d,m
        inx     h               ; get next message address
        add     a
        push    psw             ; shift left and PUSH   residual bits with status
        xchg
        cc      pmsg
        xchg                    ; print message, saving table pointer
        pop     psw
        jrnz    errm1           ; if any more bits left, continue
        lxi     h,err$msg
        call    pmsg            ; print "<BEL>, retry (Y/N) ? "
        call    u$conin$echo    ; get operator response
        cpi     'Y'
        jrz     usr$rty
hard$error:                     ; otherwise,
        mvi     a,1
RWexit: push    psw
        mvi     a,11000111B     ;set CTC ch2 (Index Pulse Interrupt) for
        di                      ; Int enable, Counter mode, Load constant next
        out     p$index         ;  & reset
        mvi     a,IdxCnt        ;set count
        out     p$index
        ei
        pop     psw
        ret


        cseg
 ;**********
execute:                        ;must reside in cseg
        push    psw
        lda     @dbnk           ;set DMA bank
        ora     a
        jrz     exec$1
        dcr     A
        ori     80H             ;set hi bit if not bank 0
exec$1: out     p$bankselect
        pop     psw             ;restore command
        di
        out     p$fdcmnd
        call    Delay           ;command delay
        pciy

 ;**********
RDent:
        in      p$fdcmnd
        bit     1,A             ;check DRQ
        jrz     noDRQ1
        ini
noDRQ1: bit     0,A             ;check busy
        jnz     RDent
        jr      RWdon
WRent:
        in      p$fdcmnd
        bit     1,A             ;check DRQ
        jrz     noDRQ2
        outi
noDRQ2: bit     0,A             ;check busy
        jnz     WRent
RWdon:
        push    psw             ;save status
        xra     a               ;set bank 0
        out     p$bankselect
        pop     psw             ;restore status
        ei
        ret

 ;**********
Delay:
        push    b               ;44us
        lxi     b,5
USRdly: dcx     b
        mov     a,B
        ora     C
        jrnz    USRdly
        pop     b
        ret

 ;********************
adahl:
        add     l
        mov     l,a
        rnc
        inr     h
        ret



        dseg
 ;**********
SelDrv:
        mvi     a,00000011B     ;reset Index Pulse interrupts
        di
        out     p$index
        ei
        in      p$fdcmnd        ;check FOR TIMEOUT
        rlc
        push    psw             ;C=not READY
        mov     a,b
        out     p$select
        pop     psw
        rnc
        mvi     a,Seldly
        call    Delay2
DSKin?: in      p$fdcmnd
        rrc
        jrc     DSKin?          ;loop until not busy
        mvi     a,FRCcmd
        out     p$fdcmnd
        call    Delay
        in      p$fdcmnd
        ani     00000010B       ;check index
        mov     d,a             ;save index status
        mvi     h,78            ;set counter
din$2:  dcx     h               ;drop counter
        mov     a,h
        ora     l
        jrz     DSKin?          ;if counter expires try again
        in      p$fdcmnd
        ani     00000010B       ;check index
        cmp     d               ;compare it to last index status
        mov     d,a             ;save new status
        jrz     din$2           ;loop back if equal
        ret

 ;**********
f$seek:
        ora     a
        jrz     restore
        out     p$fddata        ;else output track to p$fddata
        mvi     a,Sekcmd        ;seek command
        out     p$fdcmnd        ;output to p$fdcmnd
        call    Delay
sk$1:   in      p$fdcmnd
        rrc                     ;check busy
        jrc     sk$1
        mvi     a,Sekdly        ;Wait for STEP to settle
Delay2:
        push    d               ;4945$25us*A+14us
        push    b
        mov     c,a
Dly2$1: lxi     d,0760
Dly2$2: dcx     d
        mov     a,e
        ora     d
        jrnz    Dly2$2
        dcr     c
        jrnz    Dly2$1
        pop     b
        pop     d
        ret

 ;**********
restore:
        mvi     a,Homcmd
        out     p$fdcmnd
wait3:  call    Delay
        in      p$fdcmnd
        bit     0,a
        jrnz    wait3
        lhld    Trk$tbl$ptr
        mvi     m,0             ;UpDate Track#
        ret

 ;********************
u$conin$echo:                   ; get console input, echo it, and shift to upper case
        call    ?const
        ora     a
        jrz     u$c1            ; see if any char already struck
        call    ?conin
        jr      u$conin$echo    ; yes, eat it and try again
u$c1:
        call    ?conin
        push    psw
        mov     c,a
        call    ?conout
        pop     psw
        ani     5fh             ; make upper case
        ret

 ;********************
disk$command:   ds      1       ; current wd1797 command
disk$status:    ds      1       ; last error status code for messages
s$sect:         ds      1       ; current physical sector
s$trk:          ds      1       ; current physical track

RtyCnt:         db      retries         ;disk retry count
Trk$tbl$ptr:    dw      track$table     ;Pointer to current track$table entry
track$table:
                DB      -1              ;Current Track Table    A    KEEP ORDER
                DB      -1              ;                       B
                DB      -1              ;                       C
                DB      -1              ;                       D
sel$table:
                DB      DrvAon          ;drive#+motor on bit    A    KEEP ORDER
                DB      DrvBon          ;                       B
                DB      DrvCon          ;                       C
                DB      DrvDon          ;                       D

Type$tbl:
        dw      rw$DsDd         ;type 0 DsDd    00
        dw      rw$DsSd         ;type 1 DsSd    01
        dw      rw$SsDd         ;type 2 SsDd    01
        dw      rw$SsSd         ;type 3 SsSd    00
switch$tbl:
        dw      Sector$switch   ;switch on sector count 00
        dw      Track$switch    ;switch on track count  01
        dw      Odd$switch      ;switch on Odd track    10
        dw      Even$switch     ;switch on even track   11
Trk$tbl:
        db      34,35,40,80     ;track# to switch on    00,01,10,11

 ;********************
read$msg:       DB      ', Read',0              ; error message components
write$msg:      DB      ', Write',0
operation$name: DW      read$msg
err$msg:        DB      ' retry (Y/N) ? ',0

 ;********************
err$table:
        DW      b7$msg  ; table of pointers to error message strings first
        DW      b6$msg  ;    entry is for bit 7 of 1797 status byte
        DW      b5$msg
        DW      b4$msg
        DW      b3$msg
        DW      b2$msg
        DW      b1$msg
        DW      b0$msg

b7$msg: DB      ' RDY,',0
b6$msg: DB      ' WP,',0
b5$msg: DB      ' FLT,',0
b4$msg: DB      ' RNF,',0
b3$msg: DB      ' CRC,',0
b2$msg: DB      ' LD,',0
b1$msg: DB      ' DREQ,',0
b0$msg: DB      ' BSY,',0

        end

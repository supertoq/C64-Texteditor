; ========================================================================================
;  ASCII text editor for the C64
;  Copyright (c) 2026 supertoq
;  Version 2  (y)
;  https://github.com/supertoq/Texteditor64
;
;  A text editor that can load, edit and save ASCII code.
;  Supported is the 7-bit ASCII character set (ANSI X3.4-1986),
;  except for the characters NUL and CR, which are deliberately ignored when loading a file.
;  ANSI special characters are converted into suitable screen codes for display on the C64.
;  
;  - Files are saved as C64 SEQ files containing plain ASCII
;    (on Windows the file extension .seq has to be renamed to .txt)
;  - Line ending LF or CRLF selectable in the source code
;  - Text memory $36B7-$CEFF (38,985 bytes), BASIC ROM is switched off
;  - Program memory usage 12.9 KByte
;  - Upper/lower case character set is copied to RAM at $D000
;  - Every input is converted to ASCII
;  - Characters not available on the keyboard can be entered manually with F8
;  - German UTF-8 umlauts are shown as inverted letters, no conversion in the text
;  - Before saving to disk, the free space is checked
;  - File access via the UCI interface (Ultimate 64, C64 Ultimate)
;  - UCI: Files too large for memory can be loaded in parts, e.g. to read a whole book
;  - A loaded text section is not saved under its old file name
;  - Disk images and programs (e.g. .d64, .prg) are not loaded or saved (optional)
;
;  Keys:
;    F1 = Save  F3 = Load  F5 = New  F7 = Exit  F8 = ASCII code input
;    STOP = Cancel (in the file browser and prompts)
;
;    Cursor keys =  Navigation       HOME    =  Start of line
;    DEL         =  Backspace        CLR     =  Start of text
;    SHIFT+DEL   =  Delete (INST)    F2      =  End of text
;    RETURN      =  New line         F4 / F6 =  Page up / down
;    CTRL+I      =  Tab
;
;  Direct character input on the C64 keyboard:
;        Pound key                   =  Backslash \
;        SHIFT+Pound                 =  Underscore _
;        Left arrow key              =  Backtick `
;        SHIFT+Plus                  =  Curly brace {
;        SHIFT+Minus                 =  Curly brace }
;        | (key left of RESTORE)     =  ASCII pipe |
;        SHIFT+| (key left of RESTORE) = Caret ^
;        SHIFT+:                     =  Square bracket [
;        SHIFT+;                     =  Square bracket ]
;
;        F8  =  Character input by ASCII code (decimal)
;               33 - 126 = ASCII character codes
;               Note: codes 0 - 31 = control characters, 127 = DEL
;               (Inputs of 0 and 13 are ignored)
;               
;               Examples of decimal values:
;               126 = ~  125 = }  123 = {  96 = `  9 = Tab
;
;               Umlauts as Unicode input:
;               228 = ae  246 = oe  252 = ue
;               196 = AE  214 = OE  220 = UE  223 = sz
;                             
;  Alternative character display:
;        Curly braces { } = shown as inverted brackets ()
;        Tilde ~ = shown as inverted minus -
;        UTF-8 German umlauts = shown as inverted characters
;        UTF-8 chevrons << >> = shown as inverted < >
;
;  Starting the editor - from disk with LOAD"TEXTEDITOR",8 and RUN
;
;  File browser for loading (F3) and saving (F1) files:
;    Info line for drive and medium at the top.
;    Input line for the file name at the bottom.
;    File navigation:
;    Drive selection 8 - 11, plus U for UCI access on Ultimate devices.
;    CRSR up/down      =  Move pointer       F4 / F6 =  Page up / down
;    HOME              =  First entry        F7      =  Help
;    RETURN in browser =  Enter drive/folder
;    RETURN on file    =  for saving, the file name is copied to the input line,
;                         another RETURN performs the save.
;                         For loading, the file is opened.
;    ..                =  Goes back one level.
;
;    The file name can be edited manually at any time.
;    Overwriting a file has to be confirmed.
;    Wildcards: * ? are allowed for selecting files, but not when saving.
;    Optionally, entering $ re-reads the drive contents.
;    The maximum length of file names is 25 characters for UCI and 16 for disks.
;    UCI access distinguishes between upper and lower case.
;
; =========================================================================================

        .cpu "6502"

; Text encoding: characters are stored 1:1 as ASCII
        .enc "ascii"
        .cdef $00, $ff, $00

; Option:
CRLF    = 0                     ; Line ending: 0 = LF, 1 = CR+LF

; Option: substitute characters on screen
; Characters the C64 cannot display are shown with these
; screen codes. Values can be chosen freely (upper/lower case set):
;   0 = @   1-26 = a-z   27 = [   28 = \   29 = ]   30 = up arrow
;   32-63 = space, digits, punctuation   65-90 = A-Z
;   +128 = inverted (e.g. 129 = inverted a)
ALT_LBRACE      = 168           ; {  inverted (
ALT_RBRACE      = 169           ; }  inverted )
ALT_TILDE       = 173           ; ~  inverted -
ALT_BACKTICK    = 167           ; `  inverted '
ALT_PIPE        = 93            ; |  vertical bar
ALT_UNDERSCORE  = 100           ; _  underline
ALT_BACKSLASH   = 28            ; \  own character
ALT_CARET       = 30            ; ^  up arrow
ALT_OTHER       = 174           ; all others: inverted dot
; UTF-8 characters (umlauts and guillemets)
ALT_AE_KL       = 129           ; a-umlaut    inverted a
ALT_OE_KL       = 143           ; o-umlaut    inverted o
ALT_UE_KL       = 149           ; u-umlaut    inverted u
ALT_AE_GR       = 193           ; A-umlaut    inverted A
ALT_OE_GR       = 207           ; O-umlaut    inverted O
ALT_UE_GR       = 213           ; U-umlaut    inverted U
ALT_SZ          = 194           ; sharp s     inverted B
ALT_LAQUO       = 188           ; Guillemet left (171)    inverted <
ALT_RAQUO       = 190           ; Guillemet right (187)   inverted >

; Option:
; Show blacklisted file extensions in the file browser:   yes = 1; no = 0
BSHOWX  = 1

; Option:
; Colors:
;    0 black       1 white       2 red         3 cyan
;    4 purple      5 green       6 blue        7 yellow
;    8 orange      9 brown      10 light red  11 dark grey
;   12 grey       13 light green 14 light blue 15 light grey
TEXTCOL = 15                    ; Text
BGCOL   = 6                     ; Background
BORDCOL = 6                     ; Border while editing
DIRCOL  = 14                    ; Border in the file browser
FOLDCOL = 14                    ; Drives, folders and .. in the browser
PTRCOL  = 15                    ; Pointer > in the browser
WARNCOL = 10                    ; Warning color of the buffer display below 1000 bytes (WARN)

; Option:
; Blacklist for files (disk images, programs etc.).
; In upper case, separated by spaces!
BLOCKED .macro
        .text "D64 G64 D71 G71 D81 DNP ISO CRT TAP T64 REU SID PRG ZIP"
        .endm

; ---- Memory layout
BUF     = varaend               ; Text memory: start (behind the variables)
BUFEND  = $cf00                 ; Text memory: end
SCREEN  = $fc00                 ; Screen memory (RAM under the KERNAL, VIC bank 3)
TROWS   = 23                    ; Text lines on the screen
STAT    = SCREEN+23*40          ; Position of the status line (help/messages)
INFO    = SCREEN+24*40          ; Position of the info line (free memory)
WARN    = 1000                  ; Free display: values below this in WARNCOL
LF      = $0a                   ; Number ten ($0a) for LF
TAB     = $09                   ; Tab character (code 9)
TABW    = 4                     ; Width of a tab on the screen
CHARRAM = $d000                 ; Character set (2 KB, RAM under the I/O area)
CSTMP   = (BUF+$ff)&$ff00       ; at the start: character set temporarily in the text memory

; ---- UCI interface (Ultimate 64, C64 Ultimate, Ultimate-II+)
UCI_CTRL = $df1c                ; write: control, read: state
UCI_CMD  = $df1d                ; write: command, read: ID ($C9)
UCI_DATA = $df1e                ; read: response data
UCI_STAT = $df1f                ; read: status text
URBUF   = $0400                 ; Response buffer (1024 bytes, $0400-$07FF)
UCBUF   = progend               ; Command buffer (512 bytes) behind the program
USTAT   = UCBUF+512             ; Status text of the UCI (80 bytes)
VARA    = USTAT+80              ; Variables, the text memory follows
VARB    = BUFEND+1              ; Large buffers ($CF01-$CFFF)
;   Files too large (drive U) are loaded in parts
PLEN    = $7800                 ; read at most 30 KByte per part
POVL    = 500                   ; fixed: 500 bytes from the end of the previous
                                ; part appear again at the start of the next
PMARG   = 2048                  ; Reserve for finding the end of the line
PSTEP   = PLEN-POVL-PMARG       ; Distance between parts in the file
UNAMEL  = 25                    ; File name for UCI: at most 25 characters
;   File browser: list in the RAM under the KERNAL
BLIST   = $e000                 ; Start of the list
BRECL   = 32                    ; Bytes per entry
BMAX    = (SCREEN-BLIST)/BRECL  ; at most 224 entries ($E000-$FBFF)
BROWS   = 22                    ; visible lines (line 0 = title)

; ---- Operating system routines (KERNAL)
SETLFS  = $ffba
SETNAM  = $ffbd
OPEN    = $ffc0
CLOSE   = $ffc3
CHKIN   = $ffc6
CHKOUT  = $ffc9
CLRCHN  = $ffcc
CHRIN   = $ffcf
CHROUT  = $ffd2
GETIN   = $ffe4
READST  = $ffb7
LISTEN  = $ffb1
UNLSN   = $ffae
CLALL   = $ffe7
KSTOP   = $ffe1

; ---------------------------------------------------------------------
;  Explanation of the names in the program
;
;  Registers (working memory of the processor):
;    A      Accumulator, usually holds characters and values
;    X, Y   Index registers, usually counters or positions
;    Carry  Flag in the processor, used here for yes/no
;
;  Variables:
;    cur    Cursor position (address in the text memory)
;    gs     Start of the gap (end of the text before the cursor)
;    top    First text position shown at the top of the screen
;    p, q, r  Pointers to text positions (helper variables)
;    sc     Pointer to a position in the screen memory
;    sz     Number of bytes affected when moving text
;    crow   Line of the cursor on the screen
;    ccol   Column of the cursor on the screen
;    tmp, tmp2, tcnt, mcol, u8sx, u8lead, u8sec  Helper variables
;    LF     Line feed, the end-of-line character (code 10)
;
;  Structure of the text memory (gap buffer, gap = free space):
;    BUF .. gs     Text before the cursor
;    gs  .. cur    Gap, new text is inserted here (a 0 is stored at gs)
;    cur .. BUFEND Text from the cursor on, a 0 is stored at BUFEND
;    Typing and deleting only change gs or cur, nothing is moved.
;    When the cursor moves, the gap moves with it (moveto).
; ---------------------------------------------------------------------

; ---- Zero page
cur     = $22                   ; Cursor position in the text
gs      = $24                   ; Start of the gap
top     = $26                   ; Text position at the top left of the screen
r       = $28                   ; Pointer to a text position
sc      = $f7                   ; Screen pointer
sz      = $f9                   ; Number of bytes to move
p       = $fb                   ; Pointer to a text position
q       = $fd                   ; Pointer to a text position
ur      = $50                   ; Pointer into the UCI response buffer
ux      = $52                   ; Pointer into the UCI command buffer

; ---- Macros
inc16   .macro
        inc \1
        bne _skip
        inc \1+1
_skip
        .endm

; Set the pointer to the next character, skips the gap
; A is preserved, X is 0 afterwards
nxt     .macro
        inc \1
        bne _a
        inc \1+1
_a      ldx \1
        cpx gs
        bne _b
        ldx \1+1
        cpx gs+1
        bne _b
        ldx cur
        stx \1
        ldx cur+1
        stx \1+1
_b      ldx #0
        .endm

; Set the pointer to the previous character, skips the gap
prv     .macro
        lda \1
        cmp cur
        bne _a
        lda \1+1
        cmp cur+1
        bne _a
        lda gs
        sta \1
        lda gs+1
        sta \1+1
_a      lda \1
        bne _b
        dec \1+1
_b      dec \1
        .endm

; Read the next byte (into A), even if p is right before the gap
; X must be 0
pk      .macro
        lda (\1,x)
        bne _d
        lda \1
        cmp gs
        bne _z
        lda \1+1
        cmp gs+1
        bne _z
        lda (cur,x)             ; Byte behind the gap
        jmp _d
_z      lda #0
_d
        .endm

; Advance the pointer by one byte (skip the second byte of an umlaut)
; If the pointer is at the gap, continue behind it
skip2   .macro
        lda \1
        cmp gs
        bne _i
        lda \1+1
        cmp gs+1
        bne _i
        lda cur
        sta \1
        lda cur+1
        sta \1+1
_i      inc \1
        bne _e
        inc \1+1
_e
        .endm

; If a 0 was read: if it is the gap, continue reading behind the cursor
; (jump to the target), otherwise it is the end of the text (continue)
gapjmp  .macro
        lda \1
        cmp gs
        bne _e
        lda \1+1
        cmp gs+1
        bne _e
        lda \1
        cmp cur
        bne _j
        lda \1+1
        cmp cur+1
        beq _e
_j      lda cur
        sta \1
        lda cur+1
        sta \1+1
        jmp \2
_e
        .endm

; If the pointer is at the start of the gap, move it behind the gap
norm    .macro
        lda \1
        cmp gs
        bne _e
        lda \1+1
        cmp gs+1
        bne _e
        lda cur
        sta \1
        lda cur+1
        sta \1+1
_e
        .endm

msg     .macro
        ldx #<\1
        ldy #>\1
        jsr stmsg
        .endm

; =====================================================================
        * = $0801
        .word (+), 2026
        .null $9e, format("%d", start)
+       .word 0

start   lda #$36                ; BASIC ROM off, KERNAL and I/O on
        sta $01
        lda #0                  ; Clear the variables
        tax
-       sta VARA,x
        sta BUF-$100,x          ; (VARA up to BUF)
        sta BUFEND,x            ; (BUFEND to $CFFF)
        inx
        bne -
        lda #<nmiret            ; NMI vector in the RAM under the KERNAL
        sta $fffa               ; (only used while the KERNAL
        lda #>nmiret            ; is switched off for the file list)
        sta $fffb
        lda $ba                 ; Drive the program was loaded from
        cmp #8
        bcs +
        lda #8
+       sta device
        lda #BORDCOL
        sta $d020
        lda #BGCOL
        sta $d021
        lda #1
        sta $cc                 ; Blinking system cursor off
        lda #$80
        sta $028a               ; Repeat all keys when held down
        sta $0291               ; Disable switching of the character set
        sei                     ; Interrupts off, copy the character set to RAM
        lda #$32                ; Make the character ROM visible
        sta $01
        ldx #>$d800             ; upper/lower case set of the ROM
        ldy #>CSTMP             ; to the (still empty) text memory
        jsr cp2k
        ldy #7                  ; Character \ from the upper case set
-       lda $d000+$4d*8,y       ; ($4D) replaces the pound sign
        sta CSTMP+$1c*8,y       ; (screen code $1C)
        eor #$ff                ; also inverted for the cursor
        sta CSTMP+$9c*8,y       ; (screen code $9C)
        dey
        bpl -
        lda #$34                ; all RAM: copy to the RAM under the I/O area
        sta $01
        ldx #>CSTMP
        ldy #>CHARRAM
        jsr cp2k
        lda #$36
        sta $01
        cli
        ldx #250                ; clear the screen (1000 bytes)
        lda #$20
-       sta SCREEN-1,x
        sta SCREEN+249,x
        sta SCREEN+499,x
        sta SCREEN+749,x
        dex
        bne -
        lda $dd00               ; VIC bank 3 ($C000-$FFFF),
        and #$fc                ; keep the serial bus lines
        ora #3-(SCREEN>>14)
        sta $dd00
        lda #((SCREEN&$3fff)>>6)|((CHARRAM&$3fff)>>10)
        sta $d018               ; screen and character set in the bank
        ldx #0
        lda #TEXTCOL
-       sta $d800,x
        sta $d900,x
        sta $da00,x
        sta $db00,x
        inx
        bne -
        ldx #39                 ; Clear the info line
        lda #$20
-       sta INFO,x
        dex
        bpl -
        lda #<m_pg              ; F4/F6 hint below F1/F3
        ldy #>m_pg
        jsr infopg
        lda #0
        sta statshow
        sta flen
        jsr newtext
        jsr ucidet              ; UCI interface present?

; ---------------------------------------------------------------------
;  Main loop
; ---------------------------------------------------------------------
main    jsr findcursor
        jsr draw
        jsr showfree
        lda statshow
        bne +
        jsr drawhelp
+       lda #0
        sta statshow
mk      jsr getkey
        jsr dispatch
        jsr fixtop
        lda $c6                 ; Another key in the keyboard buffer?
        bne mk                  ; then process it first, draw afterwards
        jmp main

nmiret  rti

; Copy 2 KB from page X to page Y
cp2k    stx p+1
        sty q+1
        lda #0
        sta p
        sta q
        ldx #8                  ; 8 x 256 bytes = 2 KB
        ldy #0
-       lda (p),y
        sta (q),y
        iny
        bne -
        inc p+1
        inc q+1
        dex
        bne -
        rts

getkey  jsr GETIN
        cmp #0
        beq getkey
        rts

; ---------------------------------------------------------------------
;  Key dispatch
; ---------------------------------------------------------------------
dispatch
        ldx #nkeys-1
-       cmp keys,x
        beq +
        dex
        bpl -
        jsr p2a                 ; Normal character key
        cmp #0
        beq dsp_rt
        jmp insert
dsp_rt  rts
+       txa
        asl
        tay
        lda hand+1,y
        pha
        lda hand,y
        pha
        rts

keys    .byte $0d,$8d,$11,$91,$1d,$9d,$14,$94,$13,$93
        .byte $89,$8a,$8b,$85,$86,$87,$88,$8c
nkeys   = * - keys
hand    .word k_ret-1,k_ret-1,k_down-1,k_up-1,k_right-1,k_left-1
        .word k_bs-1,k_del-1,k_home-1,k_clr-1
        .word k_end-1,k_pgup-1,k_pgdn-1
        .word k_save-1,k_load-1,k_new-1,k_quit-1,k_code-1

; Convert a key code into an ASCII character
; The key code arrives in register A,
; the result is returned in A again.
; Result 0: key without a character, is ignored
p2a     cmp #TAB
        beq p2a_ok              ; CTRL+I = Tab
        cmp #$20
        bcc p2a_no
        cmp #$41
        bcc p2a_ok              ; $20-$40 unchanged
        cmp #$5b
        bcc p2a_lo              ; $41-$5A = lower case letters
        cmp #$5e
        beq p2a_pi              ; Up arrow -> |
        cmp #$5f
        beq p2a_bt              ; Left arrow -> `
        cmp #$60
        bcc p2a_ok              ; $5B-$5D  [ \ ]
        cmp #$a9
        beq p2a_us              ; SHIFT+Pound key -> _
        cmp #$db
        beq p2a_lb              ; SHIFT+Plus key -> {
        cmp #$dd
        beq p2a_rb              ; SHIFT+Minus key -> }
        cmp #$de
        beq p2a_ca              ; SHIFT+Up arrow -> ^
        cmp #$c1
        bcc p2a_no
        cmp #$db
        bcs p2a_no
        and #$7f                ; $C1-$DA = upper case letters
        rts
p2a_lo  clc
        adc #$20
p2a_ok  rts
p2a_no  lda #0
        rts
p2a_pi  lda #$7c                ; |
        rts
p2a_us  lda #$5f                ; _
        rts
p2a_ca  lda #$5e                ; ^
        rts
p2a_bt  lda #$60                ; `
        rts
p2a_lb  lda #$7b                ; {
        rts
p2a_rb  lda #$7d                ; }
        rts

; Convert an ASCII character into a screen code
; The character arrives in register A,
; the screen code is returned in A. X is 0 afterwards.
a2s     cmp #$80
        bcs a2s_np              ; from 128: cannot be displayed
        tax
        lda a2stab,x
        ldx #0
        rts
a2s_np  lda #ALT_OTHER
        ldx #0
        rts

; Table ASCII 0-127 -> screen code (substitutes from the options)
a2stab  .for i = 0, i < 128, i += 1
        .byte i < $20 ? ALT_OTHER : i < $40 ? i : i == $40 ? 0 : i < $5b ? i : i == $5c ? ALT_BACKSLASH : i == $5e ? ALT_CARET : i == $5f ? ALT_UNDERSCORE : i < $60 ? i & $1f : i == $60 ? ALT_BACKTICK : i < $7b ? i & $1f : i == $7b ? ALT_LBRACE : i == $7c ? ALT_PIPE : i == $7d ? ALT_RBRACE : i == $7e ? ALT_TILDE : ALT_OTHER
        .next

; Is the byte in A a lead byte of a UTF-8 character (194 or 195)?
; Zero flag set: yes, the byte is stored in u8lead
; A, X and Y are unchanged
islead  cmp #$c3
        beq il_y
        cmp #$c2
        bne il_n
il_y    sta u8lead
il_n    rts

; Check the second byte of a UTF-8 character (lead byte in u8lead)
; The byte arrives in register A.
; Carry clear: valid, A = screen code of the character
; Carry set: unknown character
; Registers X and Y are unchanged
u8map   stx u8sx
        sta u8sec
        ldx #8
um1     lda u8tab,x
        cmp u8sec
        bne um3
        lda u8lt,x
        cmp u8lead
        beq um2
um3     dex
        bpl um1
        lda u8sec
        ldx u8sx
        sec
        rts
um2     lda u8gly,x
        ldx u8sx
        clc
        rts

;                 a-uml. o-uml. u-uml. A-uml. O-uml. U-uml. sz     <<     >>
; lead bytes:
u8lt    .byte     $c3,   $c3,   $c3,   $c3,   $c3,   $c3,   $c3,   $c2,   $c2
; second bytes:
u8tab   .byte     $a4,   $b6,   $bc,   $84,   $96,   $9c,   $9f,   $ab,   $bb
; matching screen codes (see options above)
u8gly   .byte ALT_AE_KL, ALT_OE_KL, ALT_UE_KL, ALT_AE_GR, ALT_OE_GR, ALT_UE_GR, ALT_SZ, ALT_LAQUO, ALT_RAQUO

; ---------------------------------------------------------------------
;  Editing the text
; ---------------------------------------------------------------------
newtext lda #<BUF               ; empty text: gap covers the whole memory
        sta gs
        lda #>BUF
        sta gs+1
        lda #<BUFEND
        sta cur
        sta top
        lda #>BUFEND
        sta cur+1
        sta top+1
        lda #0                  ; end marker 0 behind the text
        sta BUFEND
        jmp setgap

; put marker 0 at the start of the gap (if there is one)
setgap  jsr gapful
        beq sg_rt
        lda #0
        ldy #0
        sta (gs),y
sg_rt   rts

; Is the gap empty (memory full)?  Zero flag set: yes
gapful  lda gs
        cmp cur
        bne +
        lda gs+1
        cmp cur+1
+       rts

; get the start of the text into p
; (if there is nothing before the cursor, the text starts at the cursor)
tstart  lda #<BUF
        sta p
        lda #>BUF
        sta p+1
        lda gs
        cmp #<BUF
        bne +
        lda gs+1
        cmp #>BUF
        bne +
        lda cur
        sta p
        lda cur+1
        sta p+1
+       rts

; Is p at the start of the text?  Zero flag set: yes
isbeg   lda gs
        cmp #<BUF
        bne ib_buf
        lda gs+1
        cmp #>BUF
        bne ib_buf
        lda p                   ; text starts at the cursor
        cmp cur
        bne +
        lda p+1
        cmp cur+1
+       rts
ib_buf  lda p
        cmp #<BUF
        bne +
        lda p+1
        cmp #>BUF
+       rts

; Insert a character into the text (into the gap before the cursor)
; The character arrives in register A
insert  sta chr                 ; save the character
        jsr gapful              ; gap empty: memory full
        bne ins_ok
        jsr stclear
        #msg m_full
        lda #1
        sta statshow
        rts
ins_ok  lda top                 ; top on the cursor: points to
        cmp cur                 ; the new character afterwards
        bne ins_st
        lda top+1
        cmp cur+1
        bne ins_st
        lda gs
        sta top
        lda gs+1
        sta top+1
ins_st  lda chr
        ldy #0
        sta (gs),y
        #inc16 gs
        jmp setgap


; Move a memory block up
; Source: address in p, destination: address in q
; Length: sz bytes
; Copies from the end so nothing is lost
moveup  ldx sz+1
        clc
        txa
        adc p+1
        sta p+1
        clc
        txa
        adc q+1
        sta q+1
        inx
        ldy sz
        beq mu3
        dey
        beq mu2
mu1     lda (p),y
        sta (q),y
        dey
        bne mu1
mu2     lda (p),y
        sta (q),y
mu3     dey
        dec p+1
        dec q+1
        dex
        bne mu1
        rts

; Move a memory block down
; Source: address in p, destination: address in q
; Length: sz bytes
; Copies from the start so nothing is lost
movedown
        ldy #0
        ldx sz+1
        beq md2
md1     lda (p),y
        sta (q),y
        iny
        bne md1
        inc p+1
        inc q+1
        dex
        bne md1
md2     ldx sz
        beq md4
md3     lda (p),y
        sta (q),y
        iny
        dex
        bne md3
md4     rts

; ---------------------------------------------------------------------
;  Cursor movement
; ---------------------------------------------------------------------
k_ret   lda #LF
        jmp insert

k_bs    lda cur                 ; Backspace
        sta p
        lda cur+1
        sta p+1
        jsr isbeg
        beq kb_rt               ; nothing to do at the start of the text
        jsr k_left              ; one character back (also a whole umlaut)
        jmp k_del               ; and delete this character
kb_rt   rts

; Delete the character under the cursor (the gap grows)
; a UTF-8 umlaut is deleted completely (both bytes)
k_del   ldy #0
        lda (cur),y
        beq kx_rt               ; nothing to do at the end of the text
        ldx #1                  ; X = length of the character in bytes
        jsr islead
        bne kx_go
        iny
        lda (cur),y
        jsr u8map
        bcs kx_go
        ldx #2
kx_go   lda top                 ; top on or behind the cursor:
        cmp cur                 ; moves along (as when moving)
        lda top+1
        sbc cur+1
        bcc kx_del
        txa
        clc
        adc top
        sta top
        bcc kx_del
        inc top+1
kx_del  txa                     ; add the character to the gap
        clc
        adc cur
        sta cur
        bcc +
        inc cur+1
+       jmp setgap              ; marker 0 (it was missing if the memory was full)
kx_rt   rts

; Cursor one character left (UTF-8 umlaut = one character)
k_left  lda cur
        sta p
        lda cur+1
        sta p+1
        jsr isbeg
        beq kl_rt               ; already at the start of the text
        #prv p
        jsr isbeg               ; is there another byte before it?
        beq kl_go
        lda p                   ; q = previous byte
        sta q
        lda p+1
        sta q+1
        #prv p                  ; p = byte before that
        ldy #0
        lda (p),y
        jsr islead              ; lead byte?
        bne kl_one
        ldy #0
        lda (q),y
        jsr u8map               ; and valid second byte?
        bcc kl_go               ; yes: cursor before the whole character
kl_one  lda q                   ; otherwise only one byte back
        sta p
        lda q+1
        sta p+1
kl_go   jmp moveto
kl_rt   rts

; Cursor one character right (UTF-8 umlaut = one character)
k_right ldy #0
        lda (cur),y
        beq kr_rt               ; already at the end of the text
        ldx #1                  ; X = length of the character in bytes
        jsr islead
        bne kr_go
        iny
        lda (cur),y
        jsr u8map
        bcs kr_go
        ldx #2
kr_go   txa                     ; destination = cursor + length
        clc
        adc cur
        sta p
        lda cur+1
        adc #0
        sta p+1
        jmp moveto
kr_rt   rts

k_home  jsr rowstart
        jmp moveto

k_clr   jsr tstart
        jmp moveto

k_end   lda #<BUFEND
        sta p
        lda #>BUFEND
        sta p+1
        jmp moveto

; Move gap and cursor to text position p
; The characters in between move to the other side of the gap.
; top is moved along if it lies in this range.
moveto  lda p                   ; mt = destination
        sta mt
        lda p+1
        sta mt+1
        lda mt
        cmp cur
        bne mt_go
        lda mt+1
        cmp cur+1
        bne mt_go
        rts                     ; destination = cursor: nothing to do
mt_go   sec                     ; gsz = size of the gap
        lda cur
        sbc gs
        sta gsz
        lda cur+1
        sbc gs+1
        sta gsz+1
        lda mt                  ; destination behind the cursor?
        cmp gs
        lda mt+1
        sbc gs+1
        bcs mt_up
; destination before the gap: text mt..gs back to before the cursor
        sec                     ; sz = gs - mt
        lda gs
        sbc mt
        sta sz
        lda gs+1
        sbc mt+1
        sta sz+1
        sec                     ; cursor forward by sz
        lda cur
        sbc sz
        sta cur
        lda cur+1
        sbc sz+1
        sta cur+1
        lda mt
        sta p
        lda mt+1
        sta p+1
        lda cur
        sta q
        lda cur+1
        sta q+1
        jsr moveup
        lda top                 ; top in the moved range?
        cmp mt
        lda top+1
        sbc mt+1
        bcc mt_d1
        lda top
        cmp gs
        lda top+1
        sbc gs+1
        bcs mt_d1
        clc                     ; then further back by the gap
        lda top
        adc gsz
        sta top
        lda top+1
        adc gsz+1
        sta top+1
mt_d1   lda mt
        sta gs
        lda mt+1
        sta gs+1
        jmp setgap
; destination behind the cursor: text cur..mt forward to gs
mt_up   sec                     ; sz = mt - cur
        lda mt
        sbc cur
        sta sz
        lda mt+1
        sbc cur+1
        sta sz+1
        lda cur
        sta p
        lda cur+1
        sta p+1
        lda gs
        sta q
        lda gs+1
        sta q+1
        jsr movedown
        lda top                 ; top in the moved range?
        cmp cur
        lda top+1
        sbc cur+1
        bcc mt_u1
        lda top
        cmp mt
        lda top+1
        sbc mt+1
        bcs mt_u1
        sec                     ; then further forward by the gap
        lda top
        sbc gsz
        sta top
        lda top+1
        sbc gsz+1
        sta top+1
mt_u1   clc                     ; gs further by sz
        lda gs
        adc sz
        sta gs
        lda gs+1
        adc sz+1
        sta gs+1
        lda mt                  ; cursor = destination
        sta cur
        lda mt+1
        sta cur+1
        jmp setgap

; Page down/up: 20 screen lines in one pass,
; the column of the cursor is kept
k_pgdn  jsr pg_beg
pd_lp   lda p                   ; remember the last line found
        sta r
        lda p+1
        sta r+1
        jsr nextrow
        bcs pd_end              ; end of the text: stay on the last line
        dec cnt2
        bne pd_lp
        jmp movecol
pd_end  lda r
        sta p
        lda r+1
        sta p+1
        jmp movecol

k_pgup  jsr pg_beg
-       jsr isbeg
        beq +                   ; start of the text reached
        jsr prevrow
        dec cnt2
        bne -
+       jmp movecol

; find the start of the line and the column of the cursor, count 20 lines
pg_beg  jsr rowstart
        jsr calccol
        lda ccol
        sta tmp
        lda #20
        sta cnt2
        rts

k_down  jsr rowstart
        jsr calccol             ; ccol = column of the cursor
        lda ccol
        sta tmp                 ; remember the wanted column (tmp)
        jsr nextrow
        bcs kd_rt               ; last line
        jmp movecol
kd_rt   rts

k_up    jsr rowstart
        jsr calccol
        lda ccol
        sta tmp
        jsr isbeg
        beq ku_rt               ; already in the first line
        jsr prevrow
        jmp movecol
ku_rt   rts

; Put the cursor in the line from p onto column tmp
; (or before it, if the line is shorter)
; A tab or UTF-8 umlaut is never hit in the middle
movecol lda #0
        sta mcol                ; mcol = previous column
        ldx #0
        jmp mc_lp
mc_zero #gapjmp p, mc_lp        ; gap: continue reading behind it
        jmp moveto              ; end of the text
mc_lp   lda p                   ; q = start of the character
        sta q
        lda p+1
        sta q+1
        lda (p,x)
        beq mc_zero
        cmp #LF
        beq mc_dn
        #inc16 p
        cmp #TAB
        beq mc_tab
        jsr islead              ; start of a UTF-8 character?
        bne mc_1
        #pk p
        jsr u8map
        bcs mc_1
        #skip2 p                ; second byte belongs to the character
mc_1    lda mcol
        clc
        adc #1                  ; one character: 1 column
        jmp mc_chk
mc_tab  lda mcol
        clc
        adc #TABW               ; tab: TABW columns
mc_chk  cmp tmp
        beq mc_adv
        bcs mc_bk               ; past the wanted column: stop
mc_adv  sta mcol
        jmp mc_lp
mc_bk   lda q                   ; cursor before this character
        sta p
        lda q+1
        sta p+1
mc_dn   jmp moveto

; Calculate the column of the cursor on the screen
; r = start of the line, result in ccol
calccol lda r
        sta q
        lda r+1
        sta q+1
        ldx #0
        ldy #0                  ; Y = column
cc_lp   lda q+1                 ; done when q has reached the cursor
        cmp cur+1
        bcc cc_c
        bne cc_dn
        lda q
        cmp cur
        bcs cc_dn
cc_c    lda (q,x)
        #nxt q
        cmp #TAB
        bne cc_n
        tya
        clc
        adc #TABW               ; tab: TABW columns
        tay
        jmp cc_lp
cc_n    jsr islead              ; start of a UTF-8 character?
        bne cc_1
        lda (q,x)
        jsr u8map
        bcs cc_1
        #nxt q                  ; second byte belongs to the character
cc_1    iny
        jmp cc_lp
cc_dn   sty ccol
        rts

; ---------------------------------------------------------------------
;  Line logic. A screen line ends after LF or after 40 characters.
; ---------------------------------------------------------------------
; Find the next screen line
; p points to the start of a line before
; and to the start of the next line afterwards
; A tab counts TABW columns, a UTF-8 umlaut one column
; Carry set: end of the text reached (last line)
nextrow ldx #0
        ldy #0                  ; Y = column in the line
nr1     lda (p,x)
        beq nr_zero
        #inc16 p
        cmp #LF
        beq nr_t
        cmp #TAB
        beq nr_tb
        cmp #$c2                ; usually no UTF-8: go on quickly
        bcc nr_c
        jsr islead              ; start of a UTF-8 character?
        bne nr_c
        #pk p
        jsr u8map
        bcs nr_c                ; no, single byte
        #skip2 p                ; second byte belongs to the character
nr_c    iny                     ; normal character: 1 column further
        jmp nr_chk
nr_tb   tya                     ; tab: TABW columns further
        clc
        adc #TABW
        tay
nr_chk  cpy #40
        bcc nr1                 ; line not full yet
nr_t    #norm p                 ; start of a line never on the gap
        clc
        rts
nr_zero #gapjmp p, nr1          ; gap: continue reading behind it
        sec                     ; end of the text
        rts

; Find the start of the text line (after the last LF)
; p points to a position in the line before
; and to the start of the line afterwards
linestart
ls1     jsr isbeg
        beq ls3
        #prv p
        ldy #0
        lda (p),y
        cmp #LF
        bne ls1
        #nxt p
ls3     rts

; Find the start of the screen line with the cursor
; Afterwards p points to this start of the line
rowstart
        lda cur
        sta p
        lda cur+1
        sta p+1
        jsr linestart
rs_lp   lda p
        sta r
        lda p+1
        sta r+1
        jsr nextrow
        bcs rs_dn
        lda cur
        cmp p
        lda cur+1
        sbc p+1
        bcc rs_dn               ; cursor lies before it
        jmp rs_lp
rs_dn   lda r
        sta p
        lda r+1
        sta p+1
        rts

; Find the previous screen line
; p points to the start of a line before
; and to the start of the line before it afterwards
prevrow lda p
        sta q
        lda p+1
        sta q+1
        #prv p
        jsr linestart
pw      lda p
        sta r
        lda p+1
        sta r+1
        jsr nextrow
        bcs pw_dn
        lda p
        cmp q
        bne pw
        lda p+1
        cmp q+1
        bne pw
pw_dn   lda r
        sta p
        lda r+1
        sta p+1
        rts

; ---------------------------------------------------------------------
;  Screen output
; ---------------------------------------------------------------------
fixtop  lda cur                 ; first visible text position (top) never behind the cursor
        cmp top
        lda cur+1
        sbc top+1
        bcs +
        jsr rowstart
        lda p
        sta top
        lda p+1
        sta top+1
+       rts

; Find line and column of the cursor on the screen
; (variables crow and ccol)
; If the cursor is not visible, the text
; is scrolled (top = first visible text position)
findcursor
        jsr fixtop
fc_again
        lda top
        sta p
        lda top+1
        sta p+1
        lda #0
        sta crow
fc_loop lda p
        sta r
        lda p+1
        sta r+1
        jsr nextrow
        bcs fc_found
        lda cur
        cmp p
        lda cur+1
        sbc p+1
        bcc fc_found
        inc crow
        lda crow
        cmp #TROWS
        bne fc_loop
        jsr rowstart            ; make the cursor visible at the bottom
        lda #TROWS-1
        sta cnt
fc_up   jsr isbeg
        beq fc_set
        jsr prevrow
        dec cnt
        bne fc_up
fc_set  lda p
        sta top
        lda p+1
        sta top+1
        jmp fc_again
fc_found
        jmp calccol             ; calculate the column of the cursor

draw    lda #BORDCOL            ; text area: normal border color
        sta $d020
        lda bcols               ; after the browser: uniform text color
        beq dr_go
        lda #0
        sta bcols
        lda #TROWS-1
        sta drow2
-       lda #TEXTCOL
        jsr rowcol
        dec drow2
        bpl -
        lda #0
        sta bcols
        lda #<m_pg              ; info line: F7 Exit again
        ldy #>m_pg
        jsr infopg
dr_go
        lda top
        sta p
        lda top+1
        sta p+1
        lda #0
        sta drow
        ldx #0
dr_row  ldy drow
        lda rowlo,y
        sta sc
        lda rowhi,y
        sta sc+1
        ldy #0
        jmp dr_ch
dr_zero #gapjmp p, dr_ch         ; gap: continue reading behind it
        jmp dr_fill             ; end of the text
dr_ch   lda (p,x)
        beq dr_zero
        #inc16 p
        cmp #$80                ; from 128: UTF-8 or substitute character
        bcs dr_hi
        cmp #LF
        beq dr_fill
        cmp #TAB
        beq dr_tab
        tax                     ; ASCII: screen code from the table
        lda a2stab,x
        ldx #0
dr_put  sta (sc),y
        iny
        cpy #40
        bne dr_ch
        beq dr_next
dr_hi   jsr islead              ; start of a UTF-8 character?
        bne dr_oth
        #pk p
        jsr u8map               ; get the screen code of the character
        bcs dr_oth
        pha
        #skip2 p                ; second byte belongs to the character
        pla
        jmp dr_put
dr_oth  lda #ALT_OTHER          ; single byte: substitute character
        bne dr_put
dr_tab  lda #TABW               ; show a tab as spaces
        sta tcnt
        lda #$20
dt_lp   sta (sc),y
        iny
        cpy #40
        bcs dr_next             ; line full
        dec tcnt
        bne dt_lp
        jmp dr_ch
dr_fill lda #$20
-       cpy #40
        bcs dr_next
        sta (sc),y
        iny
        bne -
dr_next inc drow
        lda drow
        cmp #TROWS
        beq +
        jmp dr_row
+       ldy crow                ; cursor = inverted character
        lda rowlo,y
        sta sc
        lda rowhi,y
        sta sc+1
        ldy ccol
        ldx $01                 ; read the screen: KERNAL off
        php
        sei
        lda #$35
        sta $01
        lda (sc),y
        stx $01
        plp
        eor #$80
        sta (sc),y
        rts

rowlo   .for i = 0, i < 25, i += 1
        .byte <(SCREEN+i*40)
        .next
rowhi   .for i = 0, i < 25, i += 1
        .byte >(SCREEN+i*40)
        .next

; ---------------------------------------------------------------------
;  Info line: show the free text memory (columns 27-37)
;  Red if less than 1000 bytes are free (WARN)
; ---------------------------------------------------------------------
showfree
        sec                     ; free = size of the gap
        lda cur
        sbc gs
        sta sz
        sta freel
        lda cur+1
        sbc gs+1
        sta sz+1
        sta freeh
        jsr todec
        ldx #12                 ; clear columns 27-39
        lda #$20
-       sta INFO+27,x
        dex
        bpl -
        ldx #0                  ; count leading spaces
-       lda numbuf,x
        cmp #$20
        bne +
        inx
        bne -
+       txa                     ; "Free:nnnnn B" ends in column 39
        clc
        adc #28                 ; (column 28 + number of spaces)
        tay
        ldx #0
-       lda m_free,x
        beq +
        stx dx
        jsr a2s
        ldx dx
        sta INFO,y
        iny
        inx
        bne -
+       ldx #0
-       lda numbuf,x
        cmp #$20
        beq +
        sta INFO,y
        iny
+       inx
        cpx #5
        bne -
        lda #'B'                ; unit: bytes (the space is already there)
        sta INFO+1,y
        lda #TEXTCOL            ; color: normal or warning
        ldx freeh
        cpx #>WARN
        bcc iw
        bne ic
        ldx freel
        cpx #<WARN
        bcs ic
iw      lda #WARNCOL
ic      ldx #12
-       sta $d800+24*40+27,x
        dex
        bpl -
        rts

; Write number sz (0-65535) as 5 characters to numbuf,
; leading zeros become spaces
todec   ldx #0                  ; find 5 decimal digits
dg_nx   lda #'0'
        sta numbuf,x
dg_sub  sec
        lda sz
        sbc pwlo,x
        tay
        lda sz+1
        sbc pwhi,x
        bcc dg_dn
        sta sz+1
        sty sz
        inc numbuf,x
        jmp dg_sub
dg_dn   inx
        cpx #5
        bne dg_nx
        ldx #0                  ; replace leading zeros with spaces
-       lda numbuf,x
        cmp #'0'
        bne +
        lda #$20
        sta numbuf,x
        inx
        cpx #4
        bne -
+       rts

pwlo    .byte <10000, <1000, <100, <10, <1
pwhi    .byte >10000, >1000, >100, >10, >1

; ---------------------------------------------------------------------
;  Status line (inverted)
; ---------------------------------------------------------------------
stclear ldx #39
        lda #$a0
-       sta STAT,x
        dex
        bpl -
        lda #0
        sta stcol
        rts

stputc  jsr a2s                 ; Print the character in register A
        ora #$80
        ldx stcol
        cpx #40
        bcs +
        sta STAT,x
        inc stcol
+       rts

stmsg   stx p                   ; Print a text, address in X (low) and Y (high)
        sty p+1
stprint ldy #0                  ; Print a text, address is in p, end = 0
-       lda (p),y
        beq +
        jsr stputc
        iny
        bne -
+       rts

; Write a text (A = low, Y = high) to the left of the info line
infopg  sta q
        sty q+1
        ldy #0
-       lda (q),y
        beq +
        jsr a2s
        sta INFO,y
        iny
        bne -
+       rts

drawhelp
        jsr stclear
        #msg m_help
        rts

; Enter a number (up to 5 digits), value in uval
; Carry set: no valid number, A = $03: STOP pressed
getnum  lda #0
        sta tmp2                ; number of digits
gq_lp   jsr getkey
        cmp #$0d
        beq gq_done
        cmp #$03
        beq gq_stop
        cmp #$14
        beq gq_bs               ; DEL: delete the last digit
        cmp #'0'
        bcc gq_lp
        cmp #'9'+1
        bcs gq_lp
        ldx tmp2
        cpx #5
        bcs gq_lp               ; there are no more than 5 digits
        sta dbuf,x
        inc tmp2
        jsr stputc
        jmp gq_lp
gq_bs   lda tmp2                ; no digit present
        beq gq_lp
        dec tmp2
        dec stcol               ; delete the digit on the screen
        ldx stcol
        lda #$a0
        sta STAT,x
        jmp gq_lp
gq_stop lda #$03                ; STOP
        sec
        rts
gq_no   lda #0                  ; no valid number
        sec
        rts

; RETURN: calculate the value (16 bits) from the digits
gq_done lda tmp2
        beq gq_no
        lda #0
        sta uval
        sta uval+1
        tax
gq_dlp   asl uval                ; value x 10
        rol uval+1
        bcs gq_no
        lda uval
        sta u2
        lda uval+1
        sta u2+1                ; u2 = value x 2
        asl uval
        rol uval+1
        bcs gq_no
        asl uval
        rol uval+1
        bcs gq_no
        clc                     ; x8 + x2
        lda uval
        adc u2
        sta uval
        lda uval+1
        adc u2+1
        sta uval+1
        bcs gq_no
        lda dbuf,x              ; plus the digit
        sec
        sbc #'0'
        clc
        adc uval
        sta uval
        bcc +
        inc uval+1
        beq gq_no               ; overflow above 65535
+       inx
        cpx tmp2
        beq +
        jmp gq_dlp
+       clc
        rts

confirm jsr getkey              ; J or Y = yes (carry bit set)
        cmp #$4a
        beq cf_y
        cmp #$59
        beq cf_y
        clc
        rts
cf_y    sec
        rts

; ---------------------------------------------------------------------
;  New / Exit / ASCII code
; ---------------------------------------------------------------------
k_new   jsr stclear
        #msg m_new
        jsr confirm
        bcc +
        jsr newtext
        lda #0                  ; new text: no write protection
        sta trunc
+       rts

k_quit  jsr stclear
        #msg m_quit
        jsr confirm
        bcc +
        sei                     ; leave a clean standard screen:
        ldx #250                ; clear $0400-$07E7 (was a UCI buffer)
        lda #$20
-       sta $0400-1,x
        sta $0400+249,x
        sta $0400+499,x
        sta $0400+749,x
        dex
        bne -
        lda $dd00               ; VIC bank 0
        ora #$03
        sta $dd00
        lda #$15                ; screen $0400, character ROM
        sta $d018
        lda #$37
        sta $01
        jmp $fce2               ; restart the C64
+       rts

k_code  jsr stclear
        #msg m_code
        jsr getnum
        bcc kc_ok
kc_no   rts
kc_ok
; Convert the value into UTF-8 bytes (ubuf, ulen)
        lda uval+1
        bne kc_ge256
        lda uval
        beq kc_no               ; 0 does not exist
        cmp #$0d
        beq kc_no               ; CR is ignored when loading
        cmp #128
        bcs kc_two
        sta ubuf                ; up to 127: one byte (ASCII)
        lda #1
        sta ulen
        bne kc_put
kc_ge256 cmp #$08
        bcc kc_two              ; up to 2047: two bytes
        cmp #$d8
        bcc kc_three
        cmp #$e0
        bcs kc_three
        rts                     ; $D800-$DFFF are not characters
kc_three
        lda uval+1              ; from 2048: three bytes
        lsr
        lsr
        lsr
        lsr
        ora #$e0
        sta ubuf
        jsr hi6                 ; middle 6 bits
        sta ubuf+1
        lda uval
        and #$3f
        ora #$80
        sta ubuf+2
        lda #3
        sta ulen
        bne kc_put
kc_two  lda uval+1
        asl
        asl
        sta u2
        lda uval
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        ora u2
        ora #$c0
        sta ubuf
        lda uval
        and #$3f
        ora #$80
        sta ubuf+1
        lda #2
        sta ulen
; Check the space, then insert all bytes (never only a part)
kc_put  sec                     ; space = size of the gap
        lda cur
        sbc gs
        sta u2
        lda cur+1
        sbc gs+1
        bne kp_ok               ; more than 255 bytes free
        lda u2
        cmp ulen
        bcc kp_full
kp_ok   ldx #0
kp_lp   stx ucnt
        lda ubuf,x
        jsr insert
        ldx ucnt
        inx
        cpx ulen
        bne kp_lp
        rts
kp_full jsr stclear
        #msg m_full
        lda #1
        sta statshow
        rts

; Bits 6-11 of the value uval as UTF-8 continuation byte ($80-$BF) in A
hi6     lda uval+1
        asl
        asl
        sta u2
        lda uval
        lsr
        lsr
        lsr
        lsr
        lsr
        lsr
        ora u2
        and #$3f
        ora #$80
        rts

; ---------------------------------------------------------------------
;  Files
; ---------------------------------------------------------------------
; ---------------------------------------------------------------------
;  File browser for LOAD and SAVE
;  At the top the list with the pointer > (drives, folders, files),
;  at the bottom always the name line.  The list lies in the RAM under the
;  KERNAL ($E000-$FBFF, 32 bytes per entry).
;  CRSR up/down, F4/F6 (page), HOME: move the pointer
;  RETURN: use the name from the line if it was typed last
;          (or the name was just taken over), otherwise the
;          entry under the pointer: change drive/folder/..,
;          load the file (LOAD) or take over its name (SAVE)
;  STOP: cancel.  Drive and folder are kept for the next time.
;  gnp = address of the prompt text (SAVE: / LOAD:)
;  Carry bit set: cancelled
; ---------------------------------------------------------------------
getname lda device              ; UCI selected, but no longer there?
        bne gn_brw
        jsr ucihere
        bcc gn_brw
        lda #8                  ; switch to drive 8
        sta device
        lda #0                  ; new list: drive selection
        sta blevel
        sta bvalid
        lda ucion
        beq gn_brw
        lda #0                  ; report once why
        sta ucion
        lda #<m_unact
        ldy #>m_unact
        jsr ushow_m
        jsr getkey
gn_brw  lda gload               ; LOAD: pointer first, SAVE: name first
        sta bmoved
gn_list lda bvalid              ; read the list if needed
        bne +
        jsr bload
+       lda #<m_pgb             ; info line: F7 Help
        ldy #>m_pgb
        jsr infopg
        jsr bdraw
gn_go   jsr gnsetmax
        jsr stclear
        lda gnp                 ; print the prompt text
        sta p
        lda gnp+1
        sta p+1
        jsr stprint
        ldy #0
-       cpy flen
        beq +
        lda fname,y
        ldx device              ; disk: characters as in the directory
        beq gn_pc
        jsr dchra
gn_pc   jsr stputc
        iny
        bne -
+       jsr gn_drv              ; show the drive on the right
gn_lp   jsr getkey
        cmp #$0d
        bne +
        jmp gn_ok
+       cmp #$03                ; STOP: cancel
        bne +
        sec
        rts
+       cmp #$14
        beq gn_bs
        ldx #nbkeys-1           ; keys for the pointer
-       cmp bkeys,x
        beq gn_bk
        dex
        bpl -
        cmp #$20
        bcc gn_lp
        ldx device              ; UCI: characters as in the text (ASCII)
        bne gn_iec
        jsr p2a
        cmp #$20
        bcc gn_lp
        cmp #$7f
        bcs gn_lp
        bcc gn_put
gn_iec  cmp #$60                ; disk: as before
        bcs gn_lp
gn_put  jsr badchr              ; not allowed in the name?
        bcs gn_lp
        ldx flen
        cpx gnmax
        bcs gn_lp
        sta fname,x
        inc flen
        jsr stputc
        lda #0                  ; typed last
        sta bmoved
        jmp gn_lp
gn_bs   lda flen
        beq gn_lp
        dec flen
        dec stcol
        ldx stcol
        lda #$a0
        sta STAT,x
        lda #0
        sta bmoved
        jmp gn_lp
gn_bk   txa                     ; move the pointer
        asl
        tax
        lda bkhand+1,x
        pha
        lda bkhand,x
        pha
        rts
bkeys   .byte $11,$91,$8b,$8a,$13,$88
nbkeys  = * - bkeys
bkhand  .word bk_dn-1,bk_up-1,bk_pd-1,bk_pu-1,bk_hm-1,bk_help-1
bk_dn   ldx bsel
        inx
        cpx bcount
        bcs bk_no
        stx bsel
        bcc bk_mv
bk_up   ldx bsel
        beq bk_no
        dex
        stx bsel
        jmp bk_mv
bk_pd   lda bsel                ; one page further
        clc
        adc #BROWS
        bcs +
        cmp bcount
        bcc ++
+       ldx bcount
        dex
        txa
+       sta bsel
        jmp bk_mv
bk_pu   lda bsel                ; one page back
        sec
        sbc #BROWS
        bcs +
        lda #0
+       sta bsel
        jmp bk_mv
bk_hm   lda #0
        sta bsel
bk_mv   jsr bdraw
bk_no   lda #1                  ; pointer key pressed last
        sta bmoved              ; (also at the start/end of the list)
        jmp gn_lp

; F7: show help over the list, any key: back to the list
bk_help lda #0                  ; title
        sta drow2
        jsr sd_clr
        ldy #0
-       lda m_hlpt,y
        beq +
        jsr a2s
        ora #$80
        sta (sc),y
        iny
        bne -
+       lda #<m_hlp
        sta p
        lda #>m_hlp
        sta p+1
        lda #1
        sta drow2
bh_ln   jsr sd_clr              ; one line (text ends with $FF)
        lda #TEXTCOL
        jsr rowcol
        ldx #0
        lda (p,x)
        cmp #$ff
        beq bh_rest
        ldy #1                  ; text from column 1
bh_ch   ldx #0
        lda (p,x)
        #inc16 p
        cmp #$20                ; 0 = end of line, 1-31 = column
        bcs +
        tay
        bne bh_ch
        inc drow2
        bne bh_ln
+       jsr a2s
        sta (sc),y
        iny
        bne bh_ch
bh_rest lda drow2               ; clear the remaining lines
        cmp #BROWS+1
        bcs +
        jsr sd_clr
        inc drow2
        bne bh_rest
+       jsr getkey
        jsr bdraw
        jmp gn_lp

; RETURN
gn_ok   lda bmoved              ; pointer moved or line empty:
        bne gn_ptr              ; entry under the pointer
        lda flen
        beq gn_ptr
        lda device              ; name from the line.  UCI: folder?
        bne gn_dol
        jsr isdirnm
        bcc gn_dol
        jsr ucicd
        php
        jsr binval
        lda #1
        sta blevel
        plp
        bcc +
        jsr getkey              ; error: read the message, the name is kept
+       jmp gn_list
gn_dol  lda flen
        cmp #1                  ; name $ = read the list again
        bne gn_ret
        lda fname
        cmp #'$'
        bne gn_ret
        lda #0
        sta flen
        jsr binval
        lda #1
        sta blevel
        jmp gn_list
gn_ret  clc
        rts

; entry under the pointer
gn_ptr  lda bsel
        jsr bget
        lda blevel
        bne +
        lda device              ; drive selection: choose a drive
        sta gnold
        lda brec+1
        sta device
        jsr gn_conv
        lda #1
        sta blevel
        jmp gn_nav
+       lda brec
        beq gn_upd              ; ..
        cmp #2
        beq gn_dir              ; folder
        cmp #3
        beq +
        jmp gn_lp               ; name too long: cannot be selected
+       ldx #0                  ; file: take over the name
-       cpx brec+6
        beq +
        lda brec+7,x
        sta fname,x
        inx
        bne -
+       stx flen
        txa                     ; empty name: cannot be selected
        bne +
        jmp gn_lp
+       lda #0
        sta bmoved
        lda gload               ; LOAD: load right away
        bne gn_ret
        jmp gn_go               ; SAVE: name into the line
gn_dir  ldx #0                  ; folder: change into it
-       cpx brec+6
        beq +
        lda brec+7,x
        sta cbuf,x
        inx
        bne -
+       stx cblen
        jmp gn_cd
gn_upd  lda device              ; ..: disk or UCI root
        bne gn_top              ; -> drive selection
        lda broot
        bne gn_top
        jsr bfromset            ; pointer on this folder afterwards
        lda #'.'                ; UCI: one level up
        sta cbuf
        sta cbuf+1
        lda #2
        sta cblen
gn_cd   jsr cd_cmd
        bcc gn_nav
        jsr ushow
        jsr getkey
        jmp gn_nav
gn_top  lda #0
        sta blevel
gn_nav  jsr binval              ; read the list again, pointer at the top
        jmp gn_brw

; drive change: adapt the name (UCI ASCII, disk upper case)
gn_conv lda gnold
        bne gw_iec
        lda device
        beq gw_ok               ; UCI -> UCI
        jsr nm_up               ; UCI -> disk: upper case
        jmp gw_ok
gw_iec  lda device
        bne gw_ok               ; disk -> disk
        jsr nm_low              ; disk -> UCI: lower case
gw_ok   jsr nm_clean            ; remove characters that are not allowed
        jsr gnsetmax            ; shorten the name if needed
        lda flen
        cmp gnmax
        bcc +
        lda gnmax
        sta flen
+       rts

; invalidate the list, pointer to the start
binval  lda #0
        sta bvalid
        sta bsel
        sta btop
        rts

; Read the list (drive selection, disk or UCI folder)
; On an error: let the message be read, then drive selection
bload   lda blevel
        beq bl_err2
        lda device
        bne +
        jsr bl_uci
        jmp ++
+       jsr bl_disk
+       bcc bl_ok
        jsr getkey              ; let the error message be read
        lda #0
        sta blevel
bl_err2 jsr bl_drv
bl_ok   lda #1
        sta bvalid
        lda bfind               ; after ..: find the folder we
        beq bfs_rt              ; came from, pointer on it
        lda #1
        sta bidx
bfs_lp  lda bidx
        cmp bcount
        bcs bfs_end
        jsr bget
        lda brec                ; folder with the same name?
        cmp #2
        bne bfs_nx
        lda brec+6
        cmp bfind
        bne bfs_nx
        ldx #0
-       cpx bfind
        beq bfs_hit
        lda brec+7,x
        cmp bfrom,x
        bne bfs_nx
        inx
        bne -
bfs_hit lda bidx
        sta bsel
        bcs bfs_end             ; (carry is set here)
bfs_nx  inc bidx
        bne bfs_lp
bfs_end lda #0
        sta bfind
bfs_rt  rts

; Name of the current UCI folder (last part of the path in the title)
; remember it for bfrom/bfind
bfromset
        lda #0
        sta bfind
        ldx btlen
        beq bf_rt
        dex
        lda btit,x              ; leave out the / at the end
        cmp #'/'
        bne +
        dex
        bmi bf_rt
+       stx bfend               ; last character of the name
-       lda btit,x              ; start: after the / before it
        cmp #'/'
        beq +
        dex
        bpl -
+       inx
        ldy #0
-       cpy #UNAMEL             ; too long: do not search
        bcs bf_rt
        lda btit,x
        sta bfrom,y
        iny
        cpx bfend
        beq +
        inx
        bne -
+       sty bfind
bf_rt   rts

; Drive selection: U (if present), 8, 9, 10, 11
bl_drv  lda #0
        sta bcount
        ldx #0                  ; title
-       lda m_drvs,x
        sta btit,x
        beq +
        inx
        bne -
+       stx btlen
        lda #1
        sta brec
        lda ucion
        beq +
        lda #0
        jsr bl_dadd
+       lda #8
-       jsr bl_dadd
        lda brec+1
        clc
        adc #1
        cmp #12
        bcc -
        clc
        rts
bl_dadd sta brec+1
        cmp device              ; pointer on the current drive
        bne +
        ldx bcount
        stx bsel
+       jmp badd

; Start a new list: entry ..
bl_init lda #0
        sta bcount
        sta brec
        sta dok
        jmp badd

; Disk: read the directory
bl_disk jsr diropen
        bcc +
        rts
+       jsr bl_init
        jsr dline               ; header line = title
        bcs bd_endj
        ldx #0
-       cpx llen
        beq +
        lda lbuf,x
        sta btit,x
        inx
        bne -
+       stx btlen
bd_lp   jsr KSTOP               ; STOP: stop reading
        beq bd_endj
        jsr dline
        bcc +
bd_endj jmp bd_end
+
        ldx #0                  ; find the quote
-       cpx llen
        beq bd_free
        lda lbuf,x
        inx
        cmp #'"'
        bne -
        ldy #0                  ; name up to the next "
-       cpx llen
        beq bd_typ
        lda lbuf,x
        inx
        cmp #'"'
        beq bd_typ
        cpy #16
        bcs -
        sta brec+7,y
        iny
        bne -
bd_typ  sty brec+6
-       cpx llen                ; skip spaces and *
        beq +
        lda lbuf,x
        cmp #' '
        beq bd_sk
        cmp #'*'
        bne +
bd_sk   inx
        bne -
+       ldy #0                  ; file type (3 characters)
-       lda #' '
        cpx llen
        bcs +
        lda lbuf,x
        inx
+       sta brec+3,y
        iny
        cpy #3
        bne -
        lda dnum                ; blocks
        sta brec+1
        lda dnum+1
        sta brec+2
        lda #3
        sta brec
        jsr bl_fadd
        jmp bd_lp
bd_free lda dnum                ; line without ": BLOCKS FREE
        sta dfree
        lda dnum+1
        sta dfree+1
        lda #1
        sta dok
        jmp bd_lp
bd_end  jsr closeall
        clc
        rts

; file into the list (blocked extension only if BSHOWX = 1)
bl_fadd .if BSHOWX == 0
        lda #<(brec+7)
        sta r
        lda #>(brec+7)
        sta r+1
        lda brec+6
        sta xlen
        jsr extchkp
        bcc badd
        rts
        .endif
; Append entry brec to the list (at most BMAX entries)
badd    lda bcount
        cmp #BMAX
        bcs +
        jsr bput
        inc bcount
+       rts

; UCI: read the folder
bl_uci  lda #$12                ; GET_PATH = title
        jsr ucmd
        lda #<cb_path
        sta ucbv
        lda #>cb_path
        sta ucbv+1
        lda #0
        sta llen
        jsr ucirun
        bcs bu_err
        ldx #0
        stx broot
-       cpx llen
        beq +
        lda lbuf,x
        sta btit,x
        inx
        bne -
+       stx btlen
        cpx #1                  ; path "/" = root
        bne +
        lda lbuf
        cmp #'/'
        bne +
        inc broot
+       jsr bl_init
        lda #$13                ; OPEN_DIR
        jsr ucmd
        jsr ucirun
        bcs bu_err
        lda USTAT               ; "01,DIRECTORY EMPTY": nothing to read
        cmp #'0'
        bne bu_err
        lda USTAT+1
        cmp #'1'
        beq bu_ok
        jsr uciok
        bcs bu_err
        lda #$14                ; READ_DIR
        jsr ucmd
        lda #<cb_bent
        sta ucbv
        lda #>cb_bent
        sta ucbv+1
        jsr ucirun
        bcs bu_err
bu_ok   clc
        rts
bu_err  jsr ushow
        sec
        rts

; One directory entry of the UCI: URBUF = attribute, name
; Carry set: STOP pressed (stop reading)
cb_bent jsr KSTOP
        bne +
        sec
        rts
+       lda #2                  ; folder or file
        sta brec
        lda URBUF
        and #$10
        bne +
        inc brec
+       ldx #0                  ; name up to the 0 or to the end
-       txa
        clc
        adc #1
        cmp url
        bcs +
        lda URBUF+1,x
        beq +
        cpx #UNAMEL
        bcs cb_long
        sta brec+7,x
        inx
        bne -
cb_long lda #4                  ; too long: only display it
        sta brec
+       stx brec+6
        lda brec
        cmp #3
        bne +
        jsr bl_fadd             ; file
        clc
        rts
+       jsr badd
        clc
        rts

; Show the list: title inverted in line 0, below it BROWS entries
bdraw   lda #DIRCOL             ; drive contents: own border color
        sta $d020
        lda bsel                ; keep the pointer visible
        cmp btop
        bcs +
        sta btop
+       sec
        sbc btop
        cmp #BROWS
        bcc +
        lda bsel
        sec
        sbc #BROWS-1
        sta btop
+       lda #0
        sta bdisk
        lda blevel
        beq +
        lda device
        beq +
        inc bdisk               ; disk: characters as in the directory
+       lda #0
        sta drow2
        jsr sd_clr
        ldx #0
        ldy #0
-       cpx btlen
        beq bt_free
        lda btit,x
        inx
        cmp #$12                ; leave out reverse control characters
        beq -
        stx dx
        jsr bchr
        ldx dx
        ora #$80
        sta (sc),y
        iny
        cpy #40
        bcc -
bt_free lda bdisk               ; disk: free blocks on the right
        beq bt_rows
        lda dok
        beq bt_rows
        lda dfree
        sta sz
        lda dfree+1
        sta sz+1
        jsr todec
        ldy #25                 ; number without leading spaces,
        ldx #0                  ; "nnn BLKS FREE" ends in column 39
-       lda numbuf,x
        cmp #$20
        beq +
        ora #$80
        sta (sc),y
+       iny
        inx
        cpx #5
        bne -
        ldx #0
-       lda m_bfree,x
        beq bt_rows
        stx dx
        jsr a2s
        ldx dx
        ora #$80
        sta (sc),y
        iny
        inx
        bne -
bt_rows lda #1                  ; lines 1 to BROWS
        sta drow2
bt_lp   lda drow2               ; entry btop + line - 1
        clc
        adc btop
        bcs bt_clr
        sbc #0                  ; (carry clear: minus 1)
        cmp bcount
        bcs bt_clr
        jsr brow
        jmp bt_nx
bt_clr  jsr sd_clr
        lda #TEXTCOL
        jsr rowcol
bt_nx   inc drow2
        lda drow2
        cmp #BROWS+1
        bcc bt_lp
        rts

; Show entry A in line drow2
brow    sta bidx
        jsr bget
        jsr sd_clr
        lda #FOLDCOL            ; color: drives, folders and .. in FOLDCOL
        ldx brec
        cpx #3                  ; files (3, 4) in TEXTCOL
        bcc +
        lda #TEXTCOL
+       jsr rowcol
        lda bidx
        cmp bsel
        bne +
        lda #PTRCOL             ; pointer in its own color
        ldy #0
        sta (q),y
        lda #'>'
        sta (sc),y
+       ldy #2
        lda brec
        bne br_dev
        lda #'.'                ; ..
        sta (sc),y
        iny
        sta (sc),y
        rts
br_dev  cmp #1
        bne br_nm
        lda brec+1              ; drive: U, 8, 9, 10, 11
        bne +
        lda #'U'
        sta (sc),y
        rts
+       cmp #10
        bcc +
        lda #'1'
        sta (sc),y
        iny
        lda brec+1
        sbc #10
+       ora #'0'
        sta (sc),y
        rts
br_nm   ldx #0                  ; name
-       cpx brec+6
        beq +
        lda brec+7,x
        stx dx
        jsr bchr
        ldx dx
        sta (sc),y
        iny
        inx
        bne -
+       lda brec
        cmp #2                  ; folder: append /
        bne +
        lda #'/'
        sta (sc),y
+       lda bdisk               ; disk: type and blocks
        beq br_rt
        ldy #20
        ldx #0
-       lda brec+3,x
        stx dx
        jsr dchr
        ldx dx
        sta (sc),y
        iny
        inx
        cpx #3
        bne -
        lda brec+1
        sta sz
        lda brec+2
        sta sz+1
        jsr todec
        ldy #25
        ldx #0
-       lda numbuf,x
        sta (sc),y
        iny
        inx
        cpx #5
        bne -
br_rt   rts

; Set color A for line drow2 (remembers that the text
; has to be colored uniformly again afterwards)
rowcol  ldx #1
        stx bcols
        ldy drow2
        ldx rowlo,y
        stx q
        ldx rowhi,y
        stx q+1
        pha
        lda q+1                 ; color memory = screen - SCREEN + $D800
        clc
        adc #(($d800-SCREEN)>>8)&$ff
        sta q+1
        pla
        ldy #39
-       sta (q),y
        dey
        bpl -
        rts

; Character for the list: disk as in the directory, otherwise ASCII
bchr    ldx bdisk
        beq +
        jmp dchr
+       jmp a2s

; Address of entry A in the RAM under the KERNAL into q
baddr   pha
        and #7
        asl
        asl
        asl
        asl
        asl
        sta q
        pla
        lsr
        lsr
        lsr
        clc
        adc #>BLIST
        sta q+1
        rts
; Write brec into entry A / read entry A into brec
bput    jsr baddr
        sei
        lda #$35                ; KERNAL off (RAM visible), I/O on
        sta $01
        ldy #BRECL-1
-       lda brec,y
        sta (q),y
        dey
        bpl -
        bmi bk_end
bget    jsr baddr
        sei
        lda #$35
        sta $01
        ldy #BRECL-1
-       lda (q),y
        sta brec,y
        dey
        bpl -
bk_end  lda #$36
        sta $01
        cli
        rts

; Is the character in A forbidden in the file name?  Carry set: yes
; (when loading, gload = 1, the wildcards * and ? are allowed)
; Disk: * ? , : = " /   (DOS commands, wildcards, subfolders)
; UCI:  * ? : " < > | \ (not allowed in the FAT file system)
; A and X are preserved (Y is changed)
badchr  stx bcx
        ldx gload               ; when loading, * and ? are allowed
        beq bc_chk
        cmp #'*'
        beq bc_n
        cmp #'?'
        beq bc_n
bc_chk  ldx #0
        ldy device
        bne bc_iec
-       cmp bad_uci,x
        beq bc_y
        inx
        cpx #8
        bcc -
        bcs bc_n
bc_iec
-       cmp bad_iec,x
        beq bc_y
        inx
        cpx #7
        bcc -
bc_n    ldx bcx
        clc
        rts
bc_y    ldx bcx
        sec
        rts
bad_iec .text "*?,:=", $22, "/"
bad_uci .text "*?:", $22, "<>|", $5c

; Remove forbidden characters from the file name (after a drive change)
nm_clean
        ldx #0                  ; X = read, Y = write
        ldy #0
-       cpx flen
        beq +
        lda fname,x
        sty bcy
        jsr badchr
        ldy bcy
        bcs nc_skip
        sta fname,y
        iny
nc_skip inx
        bne -
+       sty flen
        rts

; File name in upper case (a-z -> A-Z), for disk
nm_up   ldx #0
-       cpx flen
        beq +
        lda fname,x
        jsr upcase
        sta fname,x
        inx
        bne -
+       rts

; File name in lower case (A-Z -> a-z), for UCI
nm_low  ldx #0
-       cpx flen
        beq +
        lda fname,x
        cmp #'A'
        bcc nl_nx
        cmp #'Z'+1
        bcs nl_nx
        ora #$20
        sta fname,x
nl_nx   inx
        bne -
+       rts

; Set the maximum length of the name: UCI 25, disk 16
gnsetmax
        lda #16
        ldx device
        bne +
        lda #UNAMEL
+       sta gnmax
        rts

; Show "Drive n" right-aligned in the status line
; (Drive 8 / Drive 10 / Drive U, ends in column 39)
gn_drv  ldy #0                  ; assemble the text in lbuf
-       lda m_drv,y
        beq +
        sta lbuf,y
        iny
        bne -
+       lda device
        bne gd_num
        ldx #0                  ; UCI
-       lda m_uci,x
        beq gd_out
        sta lbuf,y
        iny
        inx
        bne -
gd_num  cmp #10
        bcc gd_1
        lda #'1'                ; two digits: 10, 11
        sta lbuf,y
        iny
        lda device
        sec
        sbc #10
gd_1    clc
        adc #'0'
        sta lbuf,y
        iny
gd_out  sty llen                ; start column = 40 - length
        sec
        lda #40
        sbc llen
        tay
        ldx #0
-       lda lbuf,x
        stx dx
        jsr a2s
        ldx dx
        ora #$80
        sta STAT,y
        iny
        inx
        cpx llen
        bne -
        rts

; Is the name a folder change?  ".." or a name with / at the end
; Carry set: yes
isdirnm lda flen
        cmp #2
        bne +
        lda fname
        cmp #'.'
        bne +
        lda fname+1
        cmp #'.'
        beq id_y
+       ldx flen
        lda fname-1,x
        cmp #'/'
        beq id_y
        clc
        rts
id_y    sec
        rts

; ---------------------------------------------------------------------
;  Reading the directory
; ---------------------------------------------------------------------
; Open the directory ($) of the drive, skip the load address
; Carry set: error (the message is in the status line)
diropen lda #0
        jsr SETNAM
        jsr open15
        bcs do_err
        lda #2
        ldx device
        ldy #0
        jsr SETLFS
        lda #1
        ldx #<m_dollar
        ldy #>m_dollar
        jsr SETNAM
        jsr OPEN
        jsr drvstat             ; drive ready?
        lda msgbuf
        cmp #'0'
        bne do_bad
        lda msgbuf+1
        cmp #'0'
        bne do_bad
        lda #0
        sta deof
        ldx #2
        jsr CHKIN
        bcc +
        jmp do_bad              ; drive does not respond
+       jsr dgetb               ; load address (2 bytes)
        jsr dgetb
        clc
        rts
do_bad  jsr closeall
        jsr stclear
        jsr showdrv
        sec
        rts
do_err  jsr CLALL
        jsr stclear
        #msg m_dev
        lda #1
        sta statshow
        sec
        rts

; Read one byte of the directory (always 0 after the end)
dgetb   lda deof
        bne db_z
        jsr CHRIN
        pha
        jsr READST
        sta deof                ; not 0: that was the last byte
        pla
        rts
db_z    lda #0
        rts

; Read one line of the directory
; dnum = number at the start of the line (blocks), lbuf/llen = text of the line
; Carry set: end of the directory
dline   jsr dgetb               ; link: 0 0 = end
        sta tmp
        jsr dgetb
        ora tmp
        beq dl_end
        jsr dgetb               ; number (blocks)
        sta dnum
        jsr dgetb
        sta dnum+1
        ldy #0
dl_lp   jsr dgetb               ; text up to the 0
        beq dl_ok
        cpy #40
        bcs dl_lp               ; too long: skip the rest
        sta lbuf,y
        iny
        bne dl_lp
dl_ok   sty llen
        clc
        rts
dl_end  sec
        rts

; Clear line drow2, sc points to the line afterwards
sd_clr  ldy drow2
        lda rowlo,y
        sta sc
        lda rowhi,y
        sta sc+1
        ldy #39
        lda #$20
-       sta (sc),y
        dey
        bpl -
        rts

; Convert a character from the directory into a screen code
; (names as in the file prompt: without SHIFT = upper case)
dchr    jsr dchra
        jmp a2s
; the same, result as ASCII character (X and Y are preserved)
dchra   cmp #$a0                ; shifted space
        bne +
        lda #$20
+       cmp #$c1                ; with SHIFT: lower case
        bcc +
        cmp #$db
        bcs +
        and #$7f
        ora #$20
+       rts

; Search the directory for the file name (for saving)
; dfree = free blocks, dok = 1 if this value was found
; dold = blocks of the old file, dfound = 1 if it exists
; Carry set: error (the message is in the status line)
dirscan lda #0
        sta dfound
        sta dok
        sta dold
        sta dold+1
        jsr diropen
        bcs ds_rt
        jsr dline               ; skip the header line
        bcs ds_end
ds_lp   jsr dline
        bcs ds_end
        jsr ds_line
        jmp ds_lp
ds_end  jsr closeall
        clc
ds_rt   rts

; Check one line: without quotes = BLOCKS FREE,
; otherwise compare the name in quotes with fname
ds_line ldx #0
-       cpx llen
        beq ds_nq
        lda lbuf,x
        cmp #'"'
        beq ds_q
        inx
        bne -
ds_nq   lda dnum
        sta dfree
        lda dnum+1
        sta dfree+1
        lda #1
        sta dok
        rts
ds_q    inx                     ; first character of the name
        ldy #0
-       cpy flen
        beq ds_e
        cpx llen
        bcs ds_no
        lda lbuf,x
        cmp fname,y
        bne ds_no
        inx
        iny
        bne -
ds_e    cpx llen
        bcs ds_no
        lda lbuf,x
        cmp #'"'
        bne ds_no
        lda dnum
        sta dold
        lda dnum+1
        sta dold+1
        lda #1
        sta dfound
ds_no   rts

; Calculate the blocks for the text (254 bytes per block) -> dneed
needblk sec                     ; length = memory - free
        lda cur
        sbc gs
        sta u2
        lda cur+1
        sbc gs+1
        sta u2+1
        sec
        lda #<(BUFEND-BUF)
        sbc u2
        sta blen
        lda #>(BUFEND-BUF)
        sbc u2+1
        sta blen+1
        lda #0
        sta blen+2
        .if CRLF
        jsr tstart              ; every LF is saved as CR+LF
nb_c    ldx #0
        lda (p,x)
        beq nb_b
        cmp #LF
        bne nb_n
        inc blen
        bne nb_n
        inc blen+1
        bne nb_n
        inc blen+2
nb_n    #nxt p
        jmp nb_c
nb_b
        .endif
        lda #0
        sta dneed
        sta dneed+1
nb_lp   lda blen
        ora blen+1
        ora blen+2
        beq nb_dn
        inc dneed
        bne +
        inc dneed+1
+       lda blen+2              ; rest at most 254: done
        bne nb_sub
        lda blen+1
        bne nb_sub
        lda blen
        cmp #255
        bcc nb_dn
nb_sub  sec
        lda blen
        sbc #254
        sta blen
        lda blen+1
        sbc #0
        sta blen+1
        lda blen+2
        sbc #0
        sta blen+2
        jmp nb_lp
nb_dn   lda dneed               ; an empty file needs 1 block
        ora dneed+1
        bne +
        inc dneed
+       rts

; Prepare the name for the delete command: S0:name
setscratch
        lda #'S'
        sta fbuf
        lda #'0'
        sta fbuf+1
        lda #':'
        sta fbuf+2
        ldx #0
-       cpx flen
        beq +
        lda fname,x
        sta fbuf+3,x
        inx
        bne -
+       txa
        clc
        adc #3
        ldx #<fbuf
        ldy #>fbuf
        jmp SETNAM

; Prepare the file name: name,S,W or name,S,R
; Register A holds 'W' (write) or 'R' (read)
setfile pha
        ldx #0
-       cpx flen
        beq +
        lda fname,x
        sta fbuf,x
        inx
        bne -
+       lda #','
        sta fbuf,x
        inx
        lda #'S'
        sta fbuf,x
        inx
        lda #','
        sta fbuf,x
        inx
        pla
        sta fbuf,x
        inx
        txa
        ldx #<fbuf
        ldy #>fbuf
        jmp SETNAM

; Prepare the rename command: R0:name=TE64.TMP
setrename
        lda #'R'
        sta fbuf
        lda #'0'
        sta fbuf+1
        lda #':'
        sta fbuf+2
        ldx #0
-       cpx flen
        beq +
        lda fname,x
        sta fbuf+3,x
        inx
        bne -
+       txa
        clc
        adc #3
        tax
        lda #'='
        sta fbuf,x
        inx
        ldy #0
-       lda m_tmp,y
        beq +
        sta fbuf,x
        inx
        iny
        bne -
+       txa
        ldx #<fbuf
        ldy #>fbuf
        jmp SETNAM

; Use the helper name TE64.TMP as file name (the name is remembered)
usetmp  ldx #15
-       lda fname,x
        sta fsave,x
        dex
        bpl -
        lda flen
        sta flsave
        ldx #0
-       lda m_tmp,x
        beq +
        sta fname,x
        inx
        bne -
+       stx flen
        rts

; Put the remembered file name back
usename ldx #15
-       lda fsave,x
        sta fname,x
        dex
        bpl -
        lda flsave
        sta flen
        rts

; Open command channel 15 of the drive
; Call SETNAM before (sets the file name)
; Carry set: error
; First a short call (LISTEN/UNLSN): a missing drive
; is detected at once this way. Later CHKIN would wait forever.
open15  lda #0
        sta $90                 ; clear the status
        lda device
        jsr LISTEN
        jsr UNLSN
        jsr READST
        and #$80                ; device missing?
        bne o15e
        lda #15
        ldx device
        ldy #15
        jsr SETLFS
        jsr OPEN
        bcs o15e
        jsr READST
        bne o15e
        clc
        rts
o15e    sec
        rts

; Read the message of the drive and store it in msgbuf
; (ends with 0).  If the drive does not respond, it holds
; "Drive not ready!" (otherwise CHRIN would wait for the keyboard)
drvstat ldx #15
        jsr CHKIN
        bcc +
        jmp nodrive
+       ldy #0
-       jsr CHRIN
        cmp #$0d
        beq +
        sta msgbuf,y
        iny
        cpy #38
        bcc -
+       lda #0
        sta msgbuf,y
        jmp CLRCHN

; drive does not respond: reset the input, store the message
nodrive jsr CLRCHN
        ldx #0
-       lda m_dev+1,x
        sta msgbuf,x
        beq +
        inx
        bne -
+       rts

showdrv ldy #0
-       lda msgbuf,y
        beq +
        jsr stputc
        iny
        bne -
+       lda #1
        sta statshow
        rts

closeall
        lda #2
        jsr CLOSE
        lda #15
        jsr CLOSE
        jmp CLRCHN

dev_err jsr CLALL
        jsr stclear
        #msg m_dev
        lda #1
        sta statshow
        sec                     ; error
        rts

; Saving with space check:
;  enough space for the old and the new file: write as TE64.TMP,
;    only if that works, delete the old file and rename
;  space only sufficient once the old file is gone: overwrite directly
;  not enough space at all: delete nothing, message Disk full
k_save  lda #<m_sname
        sta gnp
        lda #>m_sname
        sta gnp+1
        lda #0                  ; saving: no wildcards
        sta gload
        jsr haswild             ; remembered name with * or ?
        bcc +
        lda #0                  ; (e.g. after LOAD BR*): clear the name
        sta flen
+
ks_ask  jsr getname
        bcc +
        rts                     ; STOP
+       jsr trchk               ; truncated text onto the original?
        bcc +
        jsr stclear
        #msg m_trunc
        jsr getkey
        jmp ks_ask
+       jsr extchk              ; blocked file extension?
        bcc +
        jsr ushow_ft
        jsr getkey
        jmp ks_ask
+       jsr shsave              ; show "SAVING..." at once
        lda #0
        sta nokey
        jsr ks_do
        php
        lda nokey               ; written: read the list again
        bne +
        lda #0
        sta bvalid
+       plp
        bcc ks_rt
        lda nokey               ; "do not replace": go back at once
        bne +
        jsr getkey              ; error: let the message be read
+       jmp ks_ask
ks_rt   rts

; File already exists: replace?  Carry set: yes
; With No, nokey = 1 (back to the prompt without a key press)
askrepl jsr stclear
        #msg m_repl
        jsr confirm
        bcs shsave              ; yes: continue with "SAVING..."
        lda #1
        sta nokey
        clc
        rts

; Show "SAVING..." in the status line (carry stays set)
shsave  jsr stclear
        #msg m_sving
        sec
        rts
ks_do   lda device
        bne +
        jmp usave               ; Saving via UCI
+       jsr dirscan             ; free blocks and old file
        bcc +
        rts                     ; drive not ready (message is shown)
+       jsr needblk             ; blocks for the text
        lda dfound
        bne ks_old
        lda dok                 ; no old file
        beq ks_plain
        jsr fitfree
        bcs ks_plain
        bcc ks_full
ks_old  jsr askrepl             ; old file present: replace?
        bcs +
        sec                     ; no
        rts
+       lda dok
        beq ks_safe             ; space unknown: save safely
        jsr fitfree
        bcs ks_safe
        jsr fitboth
        bcs ks_plain
ks_full jsr stclear
        #msg m_dfull
        lda #1
        sta statshow
        sec                     ; error
        rts

; save directly: delete the old file, then write
ks_plain
        jsr setscratch
        jsr open15
        bcc +
        jmp dev_err
+       lda #15                 ; close the channel: discard the error state
        jsr CLOSE               ; (e.g. 62 when deleting)
        jsr CLRCHN
        jsr wrtext
        bcc +
        jmp dev_err
+       jmp shownok

; save safely via the helper file TE64.TMP
ks_safe jsr usetmp
        jsr scratch             ; delete the old helper file
        bcs ks_dev
        jsr wrtext              ; text into the helper file
        bcs ks_dev
        lda msgbuf
        cmp #'0'
        bne ks_werr
        lda msgbuf+1
        cmp #'0'
        bne ks_werr
        jsr usename
        jsr scratch             ; delete the old file
        bcs ks_dev
        jsr setrename           ; rename the helper file
        jsr open15
        bcs ks_dev
        jsr drvstat
        lda #15
        jsr CLOSE
        jsr CLRCHN
        jmp shownok
ks_werr jsr stclear             ; show the write error,
        jsr showdrv             ; delete the helper file,
        jsr scratch             ; the old file is kept
        jsr usename
        sec
        rts
ks_dev  jsr usename
        jmp dev_err

; Delete the file fname (the result is discarded)
; Carry set: drive not ready
scratch jsr setscratch
        jsr open15
        bcs +
        lda #15
        jsr CLOSE
        jsr CLRCHN
        clc
+       rts

; Is the free space sufficient?  Carry set: yes
fitfree lda dfree
        cmp dneed
        lda dfree+1
        sbc dneed+1
        rts

; Is the space sufficient if the old file is deleted?  Carry set: yes
fitboth clc
        lda dfree
        adc dold
        sta u2
        lda dfree+1
        adc dold+1
        sta u2+1
        bcs +
        lda u2
        cmp dneed
        lda u2+1
        sbc dneed+1
+       rts

; Write the text to the file fname, message in msgbuf afterwards
; Carry set: drive not ready
wrtext  lda #0
        jsr SETNAM
        jsr open15              ; command channel for the message
        bcc +
        rts
+       lda #2
        ldx device
        ldy #2
        jsr SETLFS
        lda #'W'
        jsr setfile
        jsr OPEN
        ldx #2
        jsr CHKOUT
        bcc +
        jsr closeall            ; drive does not respond
        sec
        rts
+       jsr tstart
sv_lp   ldx #0
        lda (p,x)
        beq sv_end              ; end marker
        .if CRLF
        cmp #LF
        bne +
        lda #$0d
        jsr CHROUT
        lda #LF
+
        .endif
        jsr CHROUT
        #nxt p
        jmp sv_lp
sv_end  jsr CLRCHN
        lda #2
        jsr CLOSE
        jsr drvstat
        lda #15
        jsr CLOSE
        jsr CLRCHN
        clc
        rts

; Loading: after an error wait for a key and go back to the
; prompt (the name stays there for correction)
k_load  lda #<m_lname
        sta gnp
        lda #>m_lname
        sta gnp+1
        lda #1                  ; loading: wildcards * and ? allowed
        sta gload
kl_ask  jsr getname
        bcc +
        rts                     ; STOP
+       jsr stclear             ; show "LOADING..." at once
        #msg m_lding
        lda #0
        sta nokey
        sta upart
        jsr kl_do
        bcc kld_rt
        lda nokey               ; part prompt left with STOP
        bne +
        jsr getkey              ; error: let the message be read
+       jmp kl_ask
kld_rt  rts
kl_do   jsr extchk              ; blocked file extension?
        bcc +
        jmp ushow_ft
+       lda device
        bne +
        jmp uload               ; Loading via UCI
+       lda #0
        jsr SETNAM
        jsr open15
        bcc +
        jmp dev_err
+       lda #2
        ldx device
        ldy #2
        jsr SETLFS
        lda #'R'
        jsr setfile
        jsr OPEN
        jsr drvstat
        lda msgbuf
        cmp #'0'
        bne ld_bad
        lda msgbuf+1
        cmp #'0'
        beq ld_ok
ld_bad  jmp ld_err
ld_ok
        ldx #2
        jsr CHKIN
        bcc +
        jmp ld_err              ; drive does not respond
+       jsr newtext
        jsr trmark              ; up to the end: text incomplete
        lda #0
        sta toobig
ld_lp   jsr CHRIN
        sta chr
        jsr READST
        sta tmp
        lda chr
        beq ld_nx               ; skip NUL and CR
        cmp #$0d
        beq ld_nx
        jsr gapful              ; gap full: file too big
        bne ld_st
        lda #1
        sta toobig
        jmp ld_fin
ld_st   lda chr
        ldy #0
        sta (gs),y
        #inc16 gs
ld_nx   lda tmp
        beq ld_lp               ; status 0: file not at its end yet
ld_fin  jsr closeall
ld_tail jsr setgap
        jsr k_clr               ; cursor to the start of the text
        lda cur
        sta top
        lda cur+1
        sta top+1
        jsr stclear
        lda upart               ; part loaded: write protection stays
        beq ld_whole
        #msg m_part
        lda ukk
        ldx ukk+1
        jsr prnum
        #msg m_pof
        lda unum
        ldx unum+1
        jsr prnum
        #msg m_pld
        jmp ld_end
ld_whole
        lda toobig
        beq +
        #msg m_big
        jmp ld_end
+       lda #0                  ; loaded completely: no write protection
        sta trunc
        #msg m_loaded
ld_end  lda #1
        sta statshow
        clc                     ; loaded
        rts
ld_err  jsr closeall
        jsr stclear
        jsr showdrv
        sec                     ; error
        rts

; Show the drive message, carry set if it does not start with 00
shownok jsr stclear
        jsr showdrv
        lda msgbuf
        cmp #'0'
        bne +
        lda msgbuf+1
        cmp #'0'
        bne +
        clc
        rts
+       sec
        rts


; ---------------------------------------------------------------------
;  UCI interface (Ultimate Command Interface)
;  Command: bytes to UCI_CMD, then bit 0 in UCI_CTRL.
;  Response: state in UCI_CTRL (bits 4-5), data from UCI_DATA (bit 7),
;  status text from UCI_STAT (bit 6), acknowledge with bit 1 in UCI_CTRL.
; ---------------------------------------------------------------------
; Detect the UCI: ID $C9 readable several times and IDENTIFY responds
; Then change to the start folder (m_uhome)
ucidet  lda #0
        sta ucion
        ldx #16
-       lda UCI_CMD             ; ID: $C9 (or $49 with IRQ)
        and #$7f
        cmp #$49
        bne ud_rt
        nop
        nop
        dex
        bne -
        lda #$01                ; IDENTIFY
        jsr ucmd
        jsr ucirun
        bcs ud_rt               ; no response
        jsr uciok
        bcs ud_rt
        lda #1
        sta ucion
        lda #0                  ; UCI is the first drive
        sta device
        lda #$11                ; CHANGE_DIR start folder (m_uhome)
        jsr ucmd
        ldx #0
-       lda m_uhome,x
        beq +
        jsr uaddb
        inx
        bne -
+       jsr ucirun
ud_rt   rts

; Is the interface mapped in?  ID $C9 (or $49 with IRQ)
; Carry set: no
ucihere lda UCI_CMD
        and #$7f
        cmp #$49
        bne +
        clc
        rts
+       sec
        rts

; Start a command: target DOS (1) and command byte from A
; Response data is discarded afterwards (ucbv = cb_none)
ucmd    pha
        lda #$01
        sta UCBUF
        pla
        sta UCBUF+1
        lda #2
        sta ucl
        lda #0
        sta ucl+1
        lda #<cb_none
        sta ucbv
        lda #>cb_none
        sta ucbv+1
        rts

; Append the byte from A to the command (A and X are preserved)
uaddb   sta ubt
        clc
        lda #<UCBUF
        adc ucl
        sta ux
        lda #>UCBUF
        adc ucl+1
        sta ux+1
        lda ubt
        ldy #0
        sta (ux),y
        inc ucl
        bne +
        inc ucl+1
+       rts

; Append the file name
uaddname
        ldx #0
-       cpx flen
        beq +
        lda fname,x
        jsr uaddb
        inx
        bne -
+       rts

; Append the helper name TE64.TMP
uaddtmp ldx #0
-       lda m_tmp,x
        beq +
        jsr uaddb
        inx
        bne -
+       rts

; Send a command and process the response
; Each response block (data in URBUF, length url) goes to the
; routine in ucbv; it reports with carry set: abort.
; Afterwards the status text is in USTAT (with 0 at the end), length ustl.
; Carry set: no response (timeout), USTAT holds a message
ucirun  lda #0
        sta ustl
        jsr ucihere             ; interface still mapped in?
        bcc +
        jmp ur_gone
+       jsr uciidle
        bcs ur_to
        lda #<UCBUF              ; write the command
        sta ux
        lda #>UCBUF
        sta ux+1
        ldy #0
        ldx ucl+1
        beq ur_rest
-       lda (ux),y              ; full 256-byte pages
        sta UCI_CMD
        iny
        bne -
        inc ux+1
        dex
        bne -
ur_rest ldx ucl
        beq ur_push
-       lda (ux),y
        sta UCI_CMD
        iny
        dex
        bne -
ur_push lda #$01                ; send the command
        sta UCI_CTRL
ur_blk  jsr uciwait              ; wait for a valid response
        bcs ur_to
        sta ust                 ; 2 = last block, 3 = more
        jsr ucirdat             ; read data and status
        jsr ucicb               ; process the block
        bcs ur_ab
        jsr uciack              ; acknowledge
        bcs ur_to
        lda ust
        cmp #3
        beq ur_blk              ; more blocks follow
ur_ab   jsr uciabrt             ; end or abort: UCI to idle
ur_end  ldx ustl
        lda #0
        sta USTAT,x
        clc
        rts
ur_gone lda #0                  ; interface not there
        sta ucion
        lda #<m_unact
        ldy #>m_unact
        jmp ustset
ur_to   lda UCI_CTRL            ; status register for the diagnosis
        sta ustreg
        jsr uciabrt             ; timeout: abort, message
        ldx #0
-       lda m_uto,x
        sta USTAT,x
        beq +
        inx
        bne -
+       lda #' '                ; diagnosis: command, location, status
        sta USTAT,x
        inx
        lda UCBUF+1             ; command byte
        jsr uhex
        lda #' '
        sta USTAT,x
        inx
        lda #'W'
        sta USTAT,x
        inx
        lda uwhere
        clc
        adc #'0'
        sta USTAT,x
        inx
        lda #' '
        sta USTAT,x
        inx
        lda #'$'
        sta USTAT,x
        inx
        lda ustreg
        jsr uhex
        lda #0
        sta USTAT,x
        stx ustl
        sec
        rts

; Write the byte in A as two hex digits to USTAT,x
uhex    pha
        lsr
        lsr
        lsr
        lsr
        jsr uh_d
        pla
        and #$0f
uh_d    cmp #10
        bcc +
        adc #6                  ; A-F (carry is set)
+       adc #'0'
        sta USTAT,x
        inx
        rts

ucicb   jmp (ucbv)
cb_none clc
        rts

; Read data (to URBUF, length url) and status (to USTAT)
ucirdat lda #<URBUF
        sta ur
        lda #>URBUF
        sta ur+1
        lda #0
        sta url
        sta url+1
        ldy #0
rd_lp   lda UCI_CTRL
        bpl rd_st               ; no more data
        lda UCI_DATA
        ldx url+1
        cpx #4                  ; store at most 1024 bytes
        bcs rd_lp
        sta (ur),y
        inc ur
        bne +
        inc ur+1
+       inc url
        bne rd_lp
        inc url+1
        jmp rd_lp
rd_st   lda UCI_CTRL
        and #$40
        beq rd_rt               ; no more status
        lda UCI_STAT
        ldx ustl
        cpx #79
        bcs rd_st
        sta USTAT,x
        inc ustl
        jmp rd_st
rd_rt   rts

; Wait as long as the UCI is busy
; A = state afterwards: 0 idle, 2 last data, 3 more data
; Carry set: no response (after about 6 seconds)
uciwait lda #2                  ; location for the diagnosis
        sta uwhere
        jsr utoset
uw_lp   lda UCI_CTRL
        tax
        and #$08                ; error bit: command not accepted
        bne uw_er
        txa
        and #$20                ; bit 5: response available
        bne uw_ok
        jsr utodec
        bcc uw_lp
        rts
uw_er   lda #4                  ; diagnosis: location 4 = error bit
        sta uwhere
        sec
        rts
uw_ok   txa
        and #$30
        lsr
        lsr
        lsr
        lsr
        clc
        rts

; Acknowledge the data and wait until the Ultimate has confirmed it
; Carry set: no response
uciack  lda #3                  ; location for the diagnosis
        sta uwhere
        lda #$02
        sta UCI_CTRL
        jsr utoset
-       lda UCI_CTRL
        and #$02
        beq +
        jsr utodec
        bcc -
        rts
+       clc
        rts

; Abort and wait until the UCI is idle again
uciabrt lda #$04
        sta UCI_CTRL
        jsr utoset
-       lda UCI_CTRL
        and #$34                ; abort done and idle?
        beq +
        jsr utodec
        bcc -
+       rts

; Before a command: the UCI must be idle (state bits 0)
; Clear the error bit; if data is still pending, acknowledge it;
; abort only if it hangs.  Carry set: no response
uciidle lda #1                  ; location for the diagnosis
        sta uwhere
        lda UCI_CTRL
        and #$08
        beq +
        lda #$08                ; clear the error bit
        sta UCI_CTRL
+       jsr utoset
ui_lp   lda UCI_CTRL
        and #$34                ; idle without a pending abort
        beq ui_ok
        and #$30
        beq +                   ; only an abort pending: wait
        cmp #$10
        beq +                   ; busy: wait
        lda UCI_CTRL            ; data pending: acknowledge
        and #$02
        bne +
        lda #$02
        sta UCI_CTRL
+       jsr utodec
        bcc ui_lp
        jsr uciabrt             ; hangs: abort
        lda UCI_CTRL
        and #$30
        beq ui_ok
        sec
        rts
ui_ok   clc
        rts

; Set the timeout and count it down (carry set: expired)
utoset  lda #0
        sta uto
        sta uto+1
        lda #4
        sta uto+2
        rts
utodec  lda uto
        bne ++
        lda uto+1
        bne +
        lda uto+2
        beq ut_end
        dec uto+2
+       dec uto+1
+       dec uto
        clc
        rts
ut_end  sec
        rts

; Check the status text: empty or "00..." = OK
; Carry set: error
uciok   lda ustl
        beq +
        lda USTAT
        cmp #'0'
        bne uo_err
        lda USTAT+1
        cmp #'0'
        bne uo_err
+       clc
        rts
uo_err  sec
        rts

; Show the status text of the UCI in the status line (empty = 00,OK)
ushow   ldx #0
        lda ustl
        bne +
-       lda m_uok,x             ; empty: show "00,OK"
        sta msgbuf,x
        beq us_sh
        inx
        bne -
+
-       lda USTAT,x
        sta msgbuf,x
        beq us_sh
        inx
        cpx #39                 ; at most 39 characters
        bcc -
        lda #0
        sta msgbuf,x
us_sh   jsr stclear
        jmp showdrv

; ---------------------------------------------------------------------
;  UCI: folders and directory
; ---------------------------------------------------------------------
; Change the folder.  The path is in fname, e.g. "TEXTE/", "..",
; "/" or "/USB0/TEXTE/".  Each part is searched in the directory,
; case does not matter, and changed to with the real spelling.
; Carry set: error (the message is shown, fname is kept)
ucicd   ldx flen                ; length without / at the end
        stx cdlen
        cpx #1
        beq +
        lda fname-1,x
        cmp #'/'
        bne +
        dec cdlen
+       lda #0
        sta cdpos
        lda fname               ; / at the start: from the root
        cmp #'/'
        bne cd_part
        lda #'/'
        sta cbuf
        lda #1
        sta cblen
        jsr cd_cmd
        bcs cd_err
        inc cdpos
cd_part lda cdpos               ; next part up to / or the end
        cmp cdlen
        bcs cd_done
        ldx cdpos
        ldy #0
-       cpx cdlen
        beq +
        lda fname,x
        cmp #'/'
        beq +
        sta cbuf,y
        iny
        inx
        bne -
+       sty cblen
        inx                     ; skip /
        stx cdpos
        lda cblen
        beq cd_part             ; empty part (e.g. //)
        cmp #2                  ; change to ".." directly
        bne cd_find
        lda cbuf
        cmp #'.'
        bne cd_find
        lda cbuf+1
        cmp #'.'
        beq cd_go
cd_find jsr cd_look             ; find the real spelling
cd_go   jsr cd_cmd
        bcs cd_err
        jmp cd_part
cd_done lda #0                  ; done: clear the name
        sta flen
        clc
        rts
cd_err  jsr ushow
        sec
        rts

; CHANGE_DIR with the name in cbuf (length cblen)
; Carry set: error (message in USTAT)
cd_cmd  lda #$11
        jsr ucmd
        ldx #0
-       cpx cblen
        beq +
        lda cbuf,x
        jsr uaddb
        inx
        bne -
+       jsr ucirun
        bcs +
        jsr uciok
+       rts

; Find folder cbuf in the current directory (case does not matter).
; Found: cbuf/cblen hold the real spelling afterwards.
cd_look lda #0
        sta cdfnd
        lda #$13                ; OPEN_DIR
        jsr ucmd
        jsr ucirun
        bcs cl_rt
        jsr uciok
        bcs cl_rt
        lda #$14                ; READ_DIR, compare every entry
        jsr ucmd
        lda #<cb_find
        sta ucbv
        lda #>cb_find
        sta ucbv+1
        jsr ucirun
        lda cdfnd
        beq cl_rt
        ldx #0                  ; take over the spelling found
-       lda rbuf,x
        sta cbuf,x
        inx
        cpx cdfnd
        bne -
        stx cblen
cl_rt   rts

; One directory entry: folder with the same name (case does not matter)?
cb_find lda cdfnd               ; already found: skip the rest
        bne cf_ok
        lda URBUF               ; folders only
        and #$10
        beq cf_ok
        lda url+1               ; very long entry: not a folder name
        bne cf_ok
        ldx #0
-       cpx cblen
        beq cf_end
        txa                     ; the name starts at URBUF+1
        clc
        adc #1
        cmp url
        bcs cf_ok               ; entry shorter
        lda URBUF+1,x
        jsr upcase
        sta ubt
        lda cbuf,x
        jsr upcase
        cmp ubt
        bne cf_ok
        inx
        bne -
cf_end  inx                     ; the entry must end here
        cpx url
        bcs +
        lda URBUF,x
        bne cf_ok
+       ldx #0                  ; remember the real spelling
-       lda URBUF+1,x
        sta rbuf,x
        inx
        cpx cblen
        bne -
        stx cdfnd
cf_ok   clc
        rts

; convert a-z to A-Z (ASCII)
upcase  cmp #'a'
        bcc +
        cmp #'z'+1
        bcs +
        and #$df
+       rts

; Path from the response into lbuf/llen (at most 40 characters)
cb_path ldx #0
-       cpx url
        beq +
        cpx #40
        bcs +
        lda URBUF,x
        beq +
        sta lbuf,x
        inx
        bne -
+       stx llen
        clc
        rts

; ---------------------------------------------------------------------
;  UCI: loading
; ---------------------------------------------------------------------
uload   jsr haswild             ; wildcards: find a matching file
        bcc ul_open
        jsr uglob
        bcc ul_open             ; found: fname holds the real name
        jmp ushow_nf
ul_open jsr extchk              ; blocked file extension?
        bcc +
        jmp ushow_ft
+       lda #$02                ; OPEN_FILE for reading
        jsr ucmd
        lda #$01
        jsr uaddb
        jsr uaddname
        jsr ucirun
        bcc +
        jmp ul_err
+
        jsr uciok
        bcc +
        jmp ul_err
+
        lda #$07                ; FILE_INFO: file size
        jsr ucmd
        lda #<cb_info
        sta ucbv
        lda #>cb_info
        sta ucbv+1
        jsr ucirun
        bcc +
        jmp ul_cerr
+
        jsr uciok
        bcc +
        jmp ul_cerr
+       jsr upick               ; too big: choose a part
        bcc ul_go
        cmp #0
        bne +
        jmp ul_cerr             ; error while seeking
+       sec                     ; cancelled (file is closed)
        rts
ul_go   jsr newtext
        jsr trmark              ; up to the end: text incomplete
        lda #0
        sta toobig
ul_lp   lda lstop               ; end of the part reached?
        beq +
        jmp ul_done
+
        lda usize               ; anything left to read?
        ora usize+1
        ora usize+2
        ora usize+3
        beq ul_done
        ldx #0                  ; chunk from usize
        jsr mkchunk
        lda #$04                ; READ_DATA
        jsr ucmd
        lda uchk
        jsr uaddb
        lda uchk+1
        jsr uaddb
        lda #<cb_load
        sta ucbv
        lda #>cb_load
        sta ucbv+1
        jsr ucirun
        bcs ul_cerr
        lda toobig
        bne ul_done             ; memory full
        jsr uciok
        bcs ul_cerr
        ldx #0                  ; rest = rest - chunk
        jsr subchunk
        jmp ul_lp
ul_done lda #$03                ; CLOSE_FILE
        jsr ucmd
        jsr ucirun
        jmp ld_tail
ul_cerr jsr ushow               ; show the error, close the file
        lda #$03
        jsr ucmd
        jsr ucirun
        lda #1
        sta statshow
        sec
        rts
ul_err  jsr ushow
        sec
        rts

; ---------------------------------------------------------------------
;  Drive U: load a file that is too big in parts
;  Part 1 starts at 0, part k at (k-1)*PSTEP-POVL, at most PLEN
;  bytes are read.  Parts from 2 on start after the first LF.
;  Parts before the last one end at the first LF after PSTEP (part 1) or
;  PSTEP+POVL bytes, so they overlap by about POVL bytes.
; ---------------------------------------------------------------------
; usize = file size.  If it does not fit: ask for the part, seek,
; afterwards usize = bytes to read.
; Carry set: A = 0 error (message in USTAT, file still open),
;            A = 1 cancelled (file closed)
upick   lda #0
        sta lskip
        sta ptrim
        sta lstop
        sta uraw
        sta uraw+1
        lda usize+3             ; fits into the text memory?
        ora usize+2
        bne up_big
        lda usize+1
        cmp #>(BUFEND-BUF)
        bcc up_fit
        bne up_big
        lda usize
        cmp #<(BUFEND-BUF)+1
        bcs up_big
up_fit  clc
        rts
up_big  lda #1                  ; find the number of parts
        sta unum
        lda #0
        sta unum+1
        jsr up_p0
-       jsr up_cmp              ; part reaches up to the end?
        bcs up_ask
        jsr up_next
        inc unum
        bne -
        inc unum+1
        bne -
up_ask  jsr stclear             ; "File too big! Part (1-n): "
        #msg m_pask
        lda unum
        ldx unum+1
        jsr prnum
        #msg m_pask2
        jsr getnum
        bcc up_chk
        cmp #$03
        bne up_ask              ; no number: again
        lda #$03                ; STOP: close the file
        jsr ucmd
        jsr ucirun
        lda #1
        sta nokey
        sec
        rts
up_chk  lda uval                ; 1 to n?
        ora uval+1
        beq up_ask
        lda unum+1
        cmp uval+1
        bcc up_ask
        bne +
        lda unum
        cmp uval
        bcc up_ask
+       lda uval
        sta ukk
        lda uval+1
        sta ukk+1
        jsr stclear
        #msg m_lding
        jsr up_p0               ; find the start of part k
-       lda uval
        bne +
        dec uval+1
+       dec uval
        lda uval
        ora uval+1
        beq +
        jsr up_next
        jmp -
+       ldx #0                  ; rest = size - start
        ldy #4
        sec
-       lda usize,x
        sbc upos,x
        sta usize,x
        inx
        dey
        bne -
        lda usize+3             ; rest > PLEN: not the last part
        ora usize+2
        bne +
        lda usize+1
        cmp #>PLEN
        bcc up_len
        bne +
        lda usize
        beq up_len
+       lda #<PLEN
        sta usize
        lda #>PLEN
        sta usize+1
        lda #0
        sta usize+2
        sta usize+3
        lda #1
        sta ptrim
        lda #<PSTEP             ; part ends at the first LF after
        sta uend                ; PSTEP (part 1) or
        lda #>PSTEP             ; PSTEP+POVL bytes (from part 2 on)
        sta uend+1
        lda upos
        ora upos+1
        ora upos+2
        ora upos+3
        beq up_len
        lda #<(PSTEP+POVL)
        sta uend
        lda #>(PSTEP+POVL)
        sta uend+1
up_len  lda #1
        sta upart
        lda upos                ; part 1: no seek
        ora upos+1
        ora upos+2
        ora upos+3
        bne +
        clc
        rts
+       lda #1
        sta lskip
        lda #$06                ; FILE_SEEK
        jsr ucmd
        ldx #0
-       lda upos,x
        jsr uaddb
        inx
        cpx #4
        bne -
        jsr ucirun
        bcc +
        jmp up_err
+       jsr uciok
        bcs up_skp              ; seek not possible: skip by reading
        clc
        rts
up_skp  ldx #3                  ; read the start and discard it
-       lda upos,x
        sta uskip,x
        dex
        bpl -
us_lp   lda uskip
        ora uskip+1
        ora uskip+2
        ora uskip+3
        bne +
        clc
        rts
+       ldx #uskip-usize        ; chunk from uskip
        jsr mkchunk
        lda #$04                ; READ_DATA, discard the data
        jsr ucmd
        lda uchk
        jsr uaddb
        lda uchk+1
        jsr uaddb
        jsr ucirun
        bcs up_err
        jsr uciok
        bcs up_err
        ldx #uskip-usize
        jsr subchunk
        jmp us_lp
up_err  lda #0
        sec
        rts

; Chunk for READ_DATA: uchk = rest, at most 16 KByte
; rest = 4 bytes from usize+X
mkchunk lda #<$4000
        sta uchk
        lda #>$4000
        sta uchk+1
        lda usize+2,x
        ora usize+3,x
        bne +
        lda usize+1,x
        cmp #>$4000
        bcs +
        lda usize,x             ; rest is smaller
        sta uchk
        lda usize+1,x
        sta uchk+1
+       rts
; rest (4 bytes from usize+X) = rest - uchk
subchunk
        sec
        lda usize,x
        sbc uchk
        sta usize,x
        lda usize+1,x
        sbc uchk+1
        sta usize+1,x
        lda usize+2,x
        sbc #0
        sta usize+2,x
        lda usize+3,x
        sbc #0
        sta usize+3,x
        rts

; part 1: base and start = 0
up_p0   lda #0
        ldx #3
-       sta upos,x
        sta ubase,x
        dex
        bpl -
        rts
; next part: base + PSTEP, start = base - POVL
up_next clc
        lda ubase
        adc #<PSTEP
        sta ubase
        lda ubase+1
        adc #>PSTEP
        sta ubase+1
        bcc +
        inc ubase+2
        bne +
        inc ubase+3
+       sec
        lda ubase
        sbc #<POVL
        sta upos
        lda ubase+1
        sbc #>POVL
        sta upos+1
        lda ubase+2
        sbc #0
        sta upos+2
        lda ubase+3
        sbc #0
        sta upos+3
        rts
; Carry set: upos + PLEN >= usize (part reaches up to the end)
up_cmp  clc
        lda upos
        adc #<PLEN
        sta utmp4
        lda upos+1
        adc #>PLEN
        sta utmp4+1
        lda upos+2
        adc #0
        sta utmp4+2
        lda upos+3
        adc #0
        sta utmp4+3
        ldx #0
        ldy #4
        sec
-       lda utmp4,x
        sbc usize,x
        inx
        dey
        bne -
        rts

; Print a number (A = low, X = high) without leading spaces
prnum   sta sz
        stx sz+1
        jsr todec
        ldy #0
-       lda numbuf,y
        cmp #$20
        bne +
        iny
        bne -
+
-       lda numbuf,y
        jsr stputc
        iny
        cpy #5
        bne -
        rts

; Write protection for truncated texts: remember name and drive
trmark  ldx #0
-       cpx flen
        beq +
        lda fname,x
        sta tname,x
        inx
        bne -
+       stx tlen
        lda device
        sta tdev
        lda #1
        sta trunc
        rts

; Is a truncated text to be saved under its old name?
; (case does not matter, the old name may contain * or ?)
; Carry set: yes, do not save
trchk   lda trunc
        beq tc_no
        lda device
        cmp tdev
        bne tc_no
        ldx #0                  ; new name to URBUF+1 (for the comparison)
-       cpx flen
        beq +
        lda fname,x
        sta URBUF+1,x
        inx
        bne -
+       stx glen
        ldx #0                  ; old name as pattern to fname
-       cpx tlen
        beq +
        lda tname,x
        sta fname,x
        inx
        bne -
+       stx flen
        jsr gmatch
        php
        ldx #0                  ; get the new name back
-       cpx glen
        beq +
        lda URBUF+1,x
        sta fname,x
        inx
        bne -
+       stx flen
        plp
        rts
tc_no   clc
        rts

; Is there a * or ? in the file name?  Carry set: yes
haswild ldx #0
-       cpx flen
        beq +
        lda fname,x
        cmp #'*'
        beq hw_y
        cmp #'?'
        beq hw_y
        inx
        bne -
+       clc
        rts
hw_y    sec
        rts

; Find the first file in the current folder that matches the pattern
; in fname (case does not matter).  Found: fname/flen = real name.
; Carry set: nothing found
uglob   lda #0
        sta gfound
        lda #$13                ; OPEN_DIR
        jsr ucmd
        jsr ucirun
        bcs ug_no
        lda USTAT               ; "01,..." = empty, otherwise it must be 00
        cmp #'0'
        bne ug_no
        lda USTAT+1
        cmp #'0'
        bne ug_no
        lda #$14                ; READ_DIR, check every entry
        jsr ucmd
        lda #<cb_glob
        sta ucbv
        lda #>cb_glob
        sta ucbv+1
        jsr ucirun
        lda gfound
        beq ug_no
        ldx #0                  ; take over the real name
-       lda rbuf,x
        sta fname,x
        inx
        cpx gfound
        bne -
        stx flen
        clc
        rts
ug_no   sec
        rts

; Show the message "file not found".  Carry set
ushow_nf
        lda #<m_nofile
        ldy #>m_nofile
        bne ushow_m

; Show the message "wrong file type".  Carry set
ushow_ft
        lda #<m_ftype           ; drive U
        ldy #>m_ftype
        ldx device
        beq ushow_m
        lda #<m_ftyp8           ; drives 8-11
        ldy #>m_ftyp8
; Show a message (A = low, Y = high) as UCI status.  Carry set
ushow_m jsr ustset
        jsr ushow
        sec
        rts
; Store a message (A = low, Y = high) as UCI status.  Carry set
ustset  sta q
        sty q+1
        ldy #0
-       lda (q),y
        sta USTAT,y
        beq +
        iny
        bne -
+       sty ustl
        sec
        rts

; Does fname have a blocked extension (list xblock)?  Carry set: yes
extchk  lda #<fname
        sta r
        lda #>fname
        sta r+1
        lda flen
        sta xlen
; the same for the name at r (length xlen)
extchkp ldy xlen                ; find the last dot
-       dey
        bmi ec_no               ; no dot: allowed
        lda (r),y
        cmp #'.'
        bne -
        iny
        sty gpi                 ; start of the extension
        ldx #0
ec_ent  ldy gpi                 ; compare one entry of the list
ec_cmp  lda xblock,x
        beq ec_end
        cmp #' '
        beq ec_end
        cpy xlen
        bcs ec_skip             ; extension shorter
        sta ubt
        lda (r),y
        jsr upcase
        cmp ubt
        bne ec_skip
        iny
        inx
        bne ec_cmp
ec_end  cpy xlen                ; entry ended: extension too?
        beq ec_yes
ec_skip lda xblock,x            ; skip the rest of the entry
        beq ec_no
        inx
        cmp #' '
        bne ec_skip
        beq ec_ent
ec_yes  sec
        rts
ec_no   clc
        rts

; One directory entry: a file (not a folder) matching the pattern?
cb_glob lda gfound              ; already found: skip the rest
        bne cg_ok
        lda URBUF               ; skip folders
        and #$10
        bne cg_ok
        lda url+1
        bne cg_ok
        ldx #0                  ; length of the name (up to 0 or the end)
-       txa
        clc
        adc #1
        cmp url
        bcs +
        lda URBUF+1,x
        beq +
        inx
        bne -
+       stx glen
        cpx #UNAMEL+1           ; too long for the prompt
        bcs cg_ok
        jsr gmatch
        bcc cg_ok
        ldx #0                  ; matches: remember the name
-       cpx glen
        beq +
        lda URBUF+1,x
        sta rbuf,x
        inx
        bne -
+       stx gfound
cg_ok   clc
        rts

; Compare pattern fname (flen) with the name URBUF+1 (glen),
; * = any number of characters, ? = exactly one character, case does not matter
; Carry set: matches
gmatch  lda #0
        sta gpi
        sta gsi
        sta gmark
        lda #$ff
        sta gstar
gm_lp   lda gsi                 ; name ended?
        cmp glen
        bcs gm_tail
        ldx gpi
        cpx flen
        bcs gm_back             ; pattern ended, name not
        lda fname,x
        cmp #'*'
        beq gm_star
        cmp #'?'
        beq gm_adv
        jsr upcase
        sta ubt
        ldy gsi
        lda URBUF+1,y
        jsr upcase
        cmp ubt
        bne gm_back
gm_adv  inc gpi                 ; character matches
        inc gsi
        jmp gm_lp
gm_star stx gstar               ; remember *, empty at first
        inc gpi
        lda gsi
        sta gmark
        jmp gm_lp
gm_back lda gstar               ; no * before: no match
        cmp #$ff
        beq gm_no
        clc                     ; let * swallow one more character
        adc #1
        sta gpi
        inc gmark
        lda gmark
        sta gsi
        jmp gm_lp
gm_tail ldx gpi                 ; the rest of the pattern may only be *
-       cpx flen
        beq gm_yes
        lda fname,x
        cmp #'*'
        bne gm_no
        inx
        bne -
gm_yes  sec
        rts
gm_no   clc
        rts

; File size (4 bytes) from the response of FILE_INFO
cb_info ldx #3
-       lda URBUF,x
        sta usize,x
        dex
        bpl -
        clc
        rts

; Take the bytes read into the text (skip NUL and CR)
; Carry set: memory full
cb_load lda #<URBUF
        sta ur
        lda #>URBUF
        sta ur+1
        lda url
        sta ucnt2
        lda url+1
        sta ucnt2+1
cl_lp   lda ucnt2
        ora ucnt2+1
        bne +
        clc                     ; block done
        rts
+       ldy #0
        lda (ur),y
        sta cbyte
        lda ptrim               ; part: count the bytes read
        beq +
        #inc16 uraw
        lda lstop               ; end reached: discard the rest
        bne cl_nx
+       lda cbyte
        ldx lskip               ; part: leave out the start up to the first LF
        beq +
        cmp #LF
        bne cl_nx
        dec lskip
        jmp cl_nx
+       cmp #0
        beq cl_nx
        cmp #$0d
        beq cl_nx
        jsr gapful              ; gap full?
        bne +
        lda #1
        sta toobig
        sec
        rts
+       lda cbyte
        ldy #0
        sta (gs),y
        #inc16 gs
        lda ptrim               ; part: first LF after uend = end
        beq cl_nx
        lda cbyte
        cmp #LF
        bne cl_nx
        lda uend+1              ; only when uraw > uend
        cmp uraw+1
        bcc +
        bne cl_nx
        lda uend
        cmp uraw
        bcs cl_nx
+       lda #1
        sta lstop
cl_nx   inc ur
        bne +
        inc ur+1
+       lda ucnt2
        bne +
        dec ucnt2+1
+       dec ucnt2
        jmp cl_lp

; ---------------------------------------------------------------------
;  UCI: saving (safely via TE64.TMP)
;  Create and write TE64.TMP, close it, then delete the old
;  file and rename TE64.TMP.  An error while writing
;  deletes TE64.TMP, the old file is kept.  If only the
;  rename fails, TE64.TMP with the new text remains.
; ---------------------------------------------------------------------
usave   lda #$02                ; does the file exist already?  Open it
        jsr ucmd                ; for reading (FILE_STAT is unreliable)
        lda #$01
        jsr uaddb
        jsr uaddname
        jsr ucirun
        bcc +
        jmp us_err
+       lda #0
        sta uexist
        jsr uciok
        bcs us_new              ; not there: new file
        inc uexist
        lda #$03                ; close it again at once
        jsr ucmd
        jsr ucirun
        bcc +
        jmp us_err
+       jsr askrepl             ; file exists: replace?
        bcs us_new
        sec                     ; no
        rts
us_new  lda #$09                ; delete the old TE64.TMP
        jsr ucmd
        jsr uaddtmp
        jsr ucirun
        bcc +
        jmp us_err
+
        lda #$02                ; create TE64.TMP
        jsr ucmd
        lda #$06
        jsr uaddb
        jsr uaddtmp
        jsr ucirun
        bcc +
        jmp us_err
+
        jsr uciok
        bcc +
        jmp us_err
+
        jsr tstart              ; text in chunks of 500 bytes
        lda #0
        sta ucrp
uw_new  lda #$05                ; WRITE_DATA, two filler bytes
        jsr ucmd
        lda #0
        jsr uaddb
        jsr uaddb
uw_fill lda ucrp                ; after CR an LF follows
        beq +
        lda #0
        sta ucrp
        lda #LF
        bne uw_put
+       ldx #0
        lda (p,x)
        beq uw_end              ; end of the text
        #nxt p
        .if CRLF
        cmp #LF
        bne uw_put
        lda #1
        sta ucrp
        lda #$0d
        .endif
uw_put  jsr uaddb
        lda ucl+1               ; 4 + 500 bytes reached?
        beq uw_fill
        lda ucl
        cmp #<504
        bcc uw_fill
        jsr uwsend
        bcs uw_err
        jmp uw_new
uw_end  lda ucl+1               ; send the rest
        bne +
        lda ucl
        cmp #5
        bcc uw_cls
+       jsr uwsend
        bcs uw_err
uw_cls  lda #$03                ; CLOSE_FILE
        jsr ucmd
        jsr ucirun
        bcs us_err
        jsr uciok
        bcs uw_derr
        lda uexist              ; delete the old file
        beq +
        lda #$09
        jsr ucmd
        jsr uaddname
        jsr ucirun
        bcs us_err
        jsr uciok
        bcs us_err
+       lda #$0a                ; RENAME TE64.TMP -> name
        jsr ucmd
        jsr uaddtmp
        lda #0
        jsr uaddb
        jsr uaddname
        jsr ucirun
        bcs us_err
        jsr uciok
        bcs us_err              ; error: TE64.TMP remains (new text)
        lda #0                  ; success: show 00,OK
        sta ustl
        jsr ushow
        clc
        rts
us_err  jsr ushow
        sec
        rts
uw_err  jsr ushow               ; show the write error,
        lda #$03                ; close the file,
        jsr ucmd
        jsr ucirun
        jmp uw_del
uw_derr jsr ushow
uw_del  lda #$09                ; delete TE64.TMP
        jsr ucmd
        jsr uaddtmp
        jsr ucirun
        sec                     ; the old file is kept
        rts

; Send a write packet.  Carry set: error (message in USTAT)
uwsend  jsr ucirun
        bcs +
        jmp uciok
+       rts

; ---------------------------------------------------------------------
;  Texts (ASCII, ending with 0) and variables
; ---------------------------------------------------------------------
m_help  .null "F1 Save  F3 Load  F5 New  F8 ASCII Code"
m_pg    .null "F4 PgUp  F6 PgDn  F7 Exit  "
m_pgb   .null "F4 PgUp  F6 PgDn  F7 Help  "
m_hlpt  .null "HELP:"
HC      = 16                    ; help: column of the explanations
m_hlp   .byte 0
        .null "CRSR UP/DOWN", HC, "select"
        .null "F4 / F6", HC, "page up / down"
        .null "HOME", HC, "first entry"
        .null "RETURN", HC, "open folder / drive,"
        .null HC, "LOAD: load file"
        .null HC, "SAVE: take name,"
        .null HC, "RETURN again saves"
        .null "..", HC, "one level up"
        .null "Type a name", HC, "then RETURN uses it"
        .null "* ?", HC, "wildcards (LOAD)"
        .null "STOP", HC, "cancel"
        .byte 0
        .null "Any key: back to the list"
        .byte $ff
m_free  .null "Free:"
m_sname .null " SAVE: "
m_lname .null " LOAD: "
m_new   .null " Clear text? (Y/N)"
m_quit  .null " Exit editor? (Y/N)"
m_code  .null " Text code (e.g. 33-126): "
m_full  .null " Memory full!"
m_loaded .null " READY."
m_big   .null " File too big - truncated!"
m_pask  .null " File too big! Part (1-"
m_pask2 .null "): "
m_part  .null " Part "
m_pof   .null " of "
m_pld   .null " loaded."
m_trunc .null " Text truncated - use a new name!"
m_dev   .null " Drive not ready!"
m_dfull .null " Disk full! Nothing saved."
m_drv   .null "Drive "
m_drvs  .null "DRIVES:"
m_bfree .null " BLKS FREE"
m_dollar .null "$"
m_tmp   .null "TE64.TMP"
m_uci   .null "U"
m_uhome .null "/"                  ; start folder for UCI
m_uto   .null "UCI: no response"
m_unact .null "UCI inactive (please check $DF00-$DFFF)"
m_repl  .null " File exists. Replace? (Y/N)"
m_nofile .null "FILE NOT FOUND"
m_ftype .null "UCI, FILE TYPE MISMATCH"
m_ftyp8 .null "FILE TYPE NOT ALLOWED"
xblock  #BLOCKED                ; blocked extensions (option above)
        .byte 0
m_lding .null " LOADING..."
m_sving .null " SAVING..."
m_uok   .null "00,OK"

progend
        .cerror (SCREEN>>14) != (CHARRAM>>14), "screen and character set not in one VIC bank"
        .cerror CHARRAM & $7ff, "character set not on a 2 KB boundary"
        .cerror BLIST+BMAX*BRECL > SCREEN, "file list overlaps the screen"
        .cerror BUF-VARA > $200, "variables A too large to clear"

; The variables are not part of the program but lie in free RAM
; (behind the UCI buffers and behind the text memory).  Both areas
; are cleared at the start.
        .virtual VARA
device  .byte 0
statshow .byte 0
stcol   .byte 0
crow    .byte 0
ccol    .byte 0
drow    .byte 0
cnt     .byte 0
cnt2    .byte 0
tmp     .byte 0
tmp2    .byte 0
chr     .byte 0
toobig  .byte 0
tcnt    .byte 0
mcol    .byte 0
mt      .word 0
gsz     .word 0
gnp     .word 0
dbuf    .fill 5,0
uval    .word 0
u2      .word 0
ubuf    .fill 3,0
ulen    .byte 0
ucnt    .byte 0
u8sx    .byte 0
u8lead  .byte 0
u8sec   .byte 0
flen    .byte 0
freel   .byte 0
freeh   .byte 0
numbuf  .fill 5, 0
fname   .fill 26, 0
fbuf    .fill 32, 0
fsave   .fill 16, 0
flsave  .byte 0
deof    .byte 0
dnum    .word 0
llen    .byte 0
drow2   .byte 0
dx      .byte 0
dfree   .word 0
dold    .word 0
dneed   .word 0
dfound  .byte 0
dok     .byte 0
blen    .fill 3, 0
gnmax   .byte 0
ucion   .byte 0
ucl     .word 0
ubt     .byte 0
ustl    .byte 0
url     .word 0
uto     .fill 3, 0
usize   .fill 4, 0
uchk    .word 0
ucnt2   .word 0
uexist  .byte 0
ucrp    .byte 0
uwhere  .byte 0
ust     .byte 0
nokey   .byte 0
gnold   .byte 0
bcx     .byte 0
bcy     .byte 0
gload   .byte 0
gfound  .byte 0
glen    .byte 0
trunc   .byte 0                 ; 1 = text only partly loaded
upart   .byte 0                 ; 1 = a part of the file loaded
ptrim   .byte 0                 ; 1 = part before the last one: shorten the end
lskip   .byte 0                 ; 1 = leave out up to the first LF
unum    .word 0                 ; number of parts
ukk     .word 0                 ; chosen part
upos    .fill 4, 0              ; start of the part in the file
uskip   .fill 4, 0
utmp4   .fill 4, 0
ubase   .fill 4, 0              ; part boundary in the file
uraw    .word 0                 ; bytes of the part read
uend    .word 0                 ; then stop at the next LF
lstop   .byte 0                 ; 1 = end of the part reached
cbyte   .byte 0
tdev    .byte 0                 ; drive of the truncated text
tlen    .byte 0
gpi     .byte 0
gsi     .byte 0
gstar   .byte 0
gmark   .byte 0
cdlen   .byte 0
cdpos   .byte 0
cblen   .byte 0
cdfnd   .byte 0
ustreg  .byte 0
blevel  .byte 0                 ; browser: 0 = drive selection, 1 = drive
bvalid  .byte 0                 ; 1 = list has been read
bsel    .byte 0                 ; entry under the pointer
btop    .byte 0                 ; first visible entry
bcount  .byte 0                 ; number of entries
bmoved  .byte 0                 ; 1 = pointer key pressed last
broot   .byte 0                 ; 1 = UCI in the root folder
bdisk   .byte 0                 ; 1 = list of a disk
bidx    .byte 0
bfind   .byte 0                 ; length of bfrom (0 = nothing to search)
bfend   .byte 0
bfrom   .fill UNAMEL, 0         ; folder we come from with ..
bcols   .byte 0                 ; 1 = lines in the browser colored
xlen    .byte 0
btlen   .byte 0
varaend
        .endv
        .virtual VARB
ucbv    .word 0                 ; fixed address, not at $xxFF
        .cerror <ucbv == $ff, "ucbv at $xxFF: JMP (ucbv) reads wrong address"
lbuf    .fill 40, 0
tname   .fill 26, 0             ; name of the truncated text
cbuf    .fill 26, 0
rbuf    .fill 26, 0
msgbuf  .fill 40, 0
btit    .fill 40, 0             ; title (disk name or path)
brec    .fill BRECL, 0          ; one entry: kind, blocks/drive,
                                ; type (3), name length, name (25)
varbend
        .cerror varbend > $d000, "variables B too large"
        .endv

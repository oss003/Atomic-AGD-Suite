; Game engine code --------------------------------------------------------------

; Arcade Game Designer.
; (C) 2008 - 2018 Jonathan Cauldwell.
; Amstrad CPC Engine v0.6.

; Global definitions ------------------------------------------------------------

SHRAPN equ 40630           ; shrapnel table, just below map.
MAP    equ 40960           ; properties map buffer.
MAPHI  equ 160             ; high byte of MAP.


; Block characteristics.

PLATFM equ 1               ; platform.
WALL   equ PLATFM + 1      ; solid wall.
LADDER equ WALL + 1        ; ladder.
FODDER equ LADDER + 1      ; fodder block.
DEADLY equ FODDER + 1      ; deadly block.
CUSTOM equ DEADLY + 1      ; custom block.
NUMTYP equ CUSTOM + 1      ; number of types.

; Sprites.

NUMSPR equ 12              ; number of sprites.
TABSIZ equ 17              ; size of each entry.
SPRBUF equ NUMSPR * TABSIZ ; size of entire table.
NMESIZ equ 4               ; bytes stored in nmetab for each sprite.
X      equ 8               ; new x coordinate of sprite.
Y      equ X + 1           ; new y coordinate of sprite.
PAM1ST equ 5               ; first sprite parameter, old x (ix+5).

; Particle engine.

NUMSHR equ 55              ; pieces of shrapnel.
SHRSIZ equ 6               ; bytes per particle.


; Game starts here.

       org 2000

start  equ $

       ld hl,(57)          ; fetch interrupt address.
       ld (firmad),hl      ; store firmware address.
       call 48127          ; initialise screen to default settings.
       call 48148          ; clear the screen.
       xor a               ; mode 0, 16 colours.
       call 48142          ; set screen mode.

       jp game             ; start the game.

joyval defb 0              ; joystick reading.
frmno  defb 0              ; selected frame.

; Don't change the order of these four.  Menu routine relies on winlft following wintop.

wintop defb WINDOWTOP      ; top of window.
winlft defb WINDOWLFT      ; left edge.
winhgt defb WINDOWHGT      ; window height.
winwid defb WINDOWWID      ; window width.
WINH   equ WINDOWHGT * 8
WINW   equ WINDOWWID * 5

numob  defb NUMOBJ         ; number of objects in game.

; Variables start here.
; Pixel versions of wintop, winlft, winhgt, winwid.

wntopx defb 8 * WINDOWTOP
wnlftx defb 5 * WINDOWLFT
wnbotx defb WINDOWTOP * 8 + WINH - 16
wnrgtx defb WINDOWLFT * 5 + WINW - 10
scno   defb 0              ; present screen number.
numlif defb 3              ; number of lives.
vara   defb 0              ; general-purpose variable.
varb   defb 0              ; general-purpose variable.
varc   defb 0              ; general-purpose variable.
vard   defb 0              ; general-purpose variable.
vare   defb 0              ; general-purpose variable.
varf   defb 0              ; general-purpose variable.
varg   defb 0              ; general-purpose variable.
varh   defb 0              ; general-purpose variable.
vari   defb 0              ; general-purpose variable.
varj   defb 0              ; general-purpose variable.
vark   defb 0              ; general-purpose variable.
varl   defb 0              ; general-purpose variable.
varm   defb 0              ; general-purpose variable.
varn   defb 0              ; general-purpose variable.
varo   defb 0              ; general-purpose variable.
varp   defb 0              ; general-purpose variable.
varq   defb 0              ; general-purpose variable.
varr   defb 0              ; general-purpose variable.
vars   defb 0              ; general-purpose variable.
vart   defb 0              ; general-purpose variable.
varu   defb 0              ; general-purpose variable.
varv   defb 0              ; general-purpose variable.
varw   defb 0              ; general-purpose variable.
varz   defb 0              ; general-purpose variable.
contrl defb 0              ; control, 0 = keyboard, 1 = Kempston, 2 = Sinclair, 3 = Mouse.
charx  defb 0              ; cursor x position.
chary  defb 0              ; cursor y position.
clock  defb 0              ; last clock reading.
varrnd defb 255            ; last random number.
varobj defb 254            ; last object number.
varopt defb 255            ; last option chosen from menu.
varblk defb 255            ; block type.
nexlev defb 0              ; next level flag.
restfl defb 0              ; restart screen flag.
deadf  defb 0              ; dead flag.
gamwon defb 0              ; game won flag.
dispx  defb 0              ; cursor x position.
dispy  defb 0              ; cursor y position.
loopa  defb 0              ; loop counter system variable.
loopb  defb 0              ; loop counter system variable.
loopc  defb 0              ; loop counter system variable.

; Make sure pointers are arranged in the same order as the data itself.

frmptr defw frmlst         ; sprite frames.
proptr defw bprop          ; address of char properties.
scrptr defw scdat          ; address of screens.
nmeptr defw nmedat         ; enemy start positions.

; Assorted game routines which can go in contended memory.

; Modify for inventory.

minve  ld hl,invdis        ; routine address.
       ld (mod0+1),hl      ; set up menu routine.
       ld (mod2+1),hl      ; set up count routine.
       ld hl,fopt          ; find option from available objects.
       ld (mod1+1),hl      ; set up routine.
       jr dbox             ; do menu routine.

; Modify for menu.

mmenu  ld hl,always        ; routine address.
       ld (mod0+1),hl      ; set up routine.
       ld (mod2+1),hl      ; set up count routine.
       ld hl,fstd          ; standard option selection.
       ld (mod1+1),hl      ; set up routine.

; Drop through into box routine.

; Work out size of box for message or menu.

;dbox   ld hl,nummsg        ; total messages.
;       cp (hl)             ; does this one exist?
;       ret nc              ; no, nothing to display.
dbox   ld hl,msgdat        ; pointer to messages.
       call getwrd         ; get message number.
       push hl             ; store pointer to message.
       ld d,1              ; height.
       xor a               ; start at object zero.
       ld (combyt),a       ; store number of object in combyt.
       ld e,a              ; maximum width.
dbox5  ld b,0              ; this line's width.
mod2   call always         ; item in player's possession?
       jr nz,dbox6         ; not in inventory, skip this line.
       inc d               ; add to tally.
dbox6  ld a,(hl)           ; get character.
       inc hl              ; next character.
       cp ','              ; reached end of line?
       jr z,dbox3          ; yes.
       inc b               ; add to this line's width.
       and a               ; end of message?
       jp m,dbox4          ; yes, end count.
       jr dbox6            ; repeat until we find the end.
dbox3  ld a,e              ; maximum line width.
       cp b                ; have we exceeded longest so far?
       jr nc,dbox5         ; no, carry on looking.
       ld e,b              ; make this the widest so far.
       jr dbox5            ; keep looking.
dbox4  ld a,e              ; maximum line width.
       cp b                ; have we exceeded longest so far?
       jr nc,dbox8         ; no, carry on looking.
       ld e,b              ; final line is the longest so far.
dbox8  dec d               ; decrement items found.
       jp z,dbox15         ; total was zero.
       ld a,e              ; longest line.
       and a               ; was it zero?
       jp z,dbox15         ; total was zero.
       ld (bwid),de        ; set up size.

; That's set up our box size.

       ld a,(winhgt)       ; window height in characters.
       sub d               ; subtract height of box.
       rra                 ; divide by 2.
       ld hl,wintop        ; top edge of window.
       add a,(hl)          ; add displacement.
       ld (btop),a         ; set up box top.
       ld a,(winwid)       ; window width in characters.
       sub e               ; subtract box width.
       rra                 ; divide by 2.
       inc hl              ; left edge of window.
       add a,(hl)          ; add displacement.
       ld (blft),a         ; box left.
       pop hl              ; restore message pointer.
       ld a,(btop)         ; box top.
       ld (dispx),a        ; set display coordinate.
       xor a               ; start at object zero.
       ld (combyt),a       ; store number of object in combyt.
dbox2  ld a,(combyt)       ; get object number.
mod0   call always         ; check inventory for display.
       jp nz,dbox13        ; not in inventory, skip this line.

       ld a,(blft)         ; box left.
       ld (dispy),a        ; set left display position.
       ld a,(bwid)         ; box width.
       ld b,a              ; store width.
dbox0  ld a,(hl)           ; get character.
       cp ','              ; end of line?
       jr z,dbox1          ; yes, next one.
       dec b               ; one less to display.
       and 127             ; remove terminator.
       push bc             ; store characters remaining.
       push hl             ; store address on stack.
       call ptxta          ; display on screen and advance.
       pop hl              ; retrieve address of next character.
       pop bc              ; chars left for this line.
       ld a,(hl)           ; get character.
       inc hl              ; next character.
       cp 128              ; end of message?
       jp nc,dbox7         ; yes, job done.
       ld a,b              ; chars remaining.
       and a               ; are any left?
       jr nz,dbox0         ; yes, continue.

; Reached limit of characters per line.

dbox9  ld a,(hl)           ; get character.
       inc hl              ; next one.
       cp ','              ; another line?
       jr z,dbox10         ; yes, do next line.
       cp 128              ; end of message?
       jr nc,dbox11        ; yes, finish message.
       jr dbox9

; Fill box to end of line.

dboxf  push hl             ; store address on stack.
       push bc             ; store characters remaining.
       ld a,32             ; space character.
       call ptxta          ; display character and advance.
       pop bc              ; retrieve character count.
       pop hl              ; retrieve address of next character.
       djnz dboxf          ; repeat for remaining chars on line.
       ret
dbox1  inc hl              ; skip character.
       call dboxf          ; fill box out to right side.
dbox10 ld a,(dispx)        ; x coordinate.
       inc a               ; down a line.
       ld (dispx),a        ; next position.
       jp dbox2            ; next line.
dbox7  ld a,b              ; chars remaining.
       and a               ; are any left?
       jr z,dbox11         ; no, nothing to draw.
       call dboxf          ; fill message to line.

; Drawn the box menu, now select option.

dbox11 ld a,(btop)         ; box top.
       ld (dispx),a        ; set bar position.
dbox14 call joykey         ; get controls.
       and 63              ; anything pressed?
       jr nz,dbox14        ; yes, debounce it.
       call dbar           ; draw bar.
dbox12 call joykey         ; get controls.
       and 35              ; anything pressed?
       jr z,dbox12         ; no, nothing.
       and 32              ; fire button pressed?
mod1   jp nz,fstd          ; yes, job done.
       call dbar           ; delete bar.
       ld a,(joyval)       ; joystick reading.
       and 1               ; going up?
       jr nz,dboxu         ; yes, go up.
       ld a,(dispx)        ; vertical position of bar.
       inc a               ; look down.
       ld hl,btop          ; top of box.
       sub (hl)            ; find distance from top.
       dec hl              ; point to height.
       cp (hl)             ; are we at end?
       jp z,dbox14         ; yes, go no further.
       ld hl,dispx         ; coordinate.
       inc (hl)            ; move bar.
       jr dbox14           ; continue.
dboxu  ld a,(dispx)        ; vertical position of bar.
       ld hl,btop          ; top of box.
       cp (hl)             ; are we at the top?
       jp z,dbox14         ; yes, go no further.
       ld hl,dispx         ; coordinate.
       dec (hl)            ; move bar.
       jr dbox14           ; continue.
fstd   ld a,(dispx)        ; bar position.
       ld hl,btop          ; top of menu.
       sub (hl)            ; find selected option.
       ld (varopt),a       ; store the option.
       jp redraw           ; redraw the screen.

; Option not available.  Skip this line.

dbox13 ld a,(hl)           ; get character.
       inc hl              ; next one.
       cp ','              ; another line?
       jp z,dbox2          ; yes, do next line.
       and a               ; end of message?
       jp m,dbox11         ; yes, finish message.
       jr dbox13
dbox15 pop hl              ; pop message pointer from the stack.
       ret

dbar   ld a,(blft)         ; box left.
       ld (dispy),a        ; set display coordinate.
       call gprad          ; get printing address.
       ex de,hl            ; flip into hl register pair.

       ld b,8              ; 8 pixel rows to invert.
dbar1  push bc             ; store pixel count on stack.
       push hl             ; store address.
       ld a,(bwid)         ; box width.
       ld e,a              ; copy to e register.
       rlca                ; multiple of 2.
       rlca                ; multiple of 4.
       add a,e             ; multiple of 5.
       srl a               ; divide by 2.
       ld b,a              ; loop counter in b.
dbar0  ld a,(hl)           ; get screen byte.
       cpl                 ; reverse all bits.
       ld (hl),a           ; write back to screen.
       inc hl              ; next bar.
       djnz dbar0          ; repeat for whole line.
       pop hl              ; restore screen address.
       call nline2         ; look down one line.
       pop bc              ; restore row count.
       djnz dbar1          ; repeat for 8 pixel rows.
       ret

invdis push hl             ; store message text pointer.
       push de             ; store de pair for line count.
       ld hl,combyt        ; object number.
       ld a,(hl)           ; get object number.
       inc (hl)            ; ready for next one.
       call gotob          ; check if we have object.
       pop de              ; retrieve de pair from stack.
       pop hl              ; retrieve text pointer.
       ret
;always xor a               ; set zero flag.
;       ret

; Find option selected.

fopt   ld a,(dispx)
       ld hl,btop          ; top of menu.
       sub (hl)            ; find selected option.
       inc a               ; object 0 needs one iteration, 1 needs 2 and so on.
       ld b,a              ; option selected in b register.
       ld hl,combyt        ; object number.
       ld (hl),0           ; set to first item.
fopt0  push bc             ; store option counter in b register.
       call fobj           ; find next object in inventory.
       pop bc              ; restore option counter.
       djnz fopt0          ; repeat for relevant steps down the list.
       ld a,(combyt)       ; get option.
       dec a               ; one less, due to where we increment combyt.
       ld (varopt),a       ; store the option.
       jp redraw           ; redraw the screen.

fobj   ld hl,combyt        ; object number.
       ld a,(hl)           ; get object number.
       inc (hl)            ; ready for next item.
       ret z               ; in case we loop back to zero.
       call gotob          ; do we have this item?
       ret z               ; yes, it's on the list.
       jr fobj             ; repeat until we find next item in pockets.

bwid   defb 0              ; box/menu width.
blen   defb 0              ; box/menu height.
btop   defb 0              ; box coordinates.
blft   defb 0

; Wait for keypress.

prskey call debkey         ; debounce key.
prsky0 call vsync          ; vertical synch.
       call 47881          ; keyboard state.
       jr nc,prsky0        ; repeat until key pressed.

; Debounce keypress.

debkey call vsync          ; update scrolling, sounds etc.
       call 47881          ; read keyboard.
       jr c,debkey         ; key pressed - loop until key is released.
       ret

; Delay routine.

delay  push bc             ; store loop counter.
       call vsync          ; pause for a frame.
       call plsnd          ; time to play sound.
       pop bc              ; restore counter.
       dec b               ; one less iteration.
       ret z               ; done.
       push bc             ; store loop counter again.
       call vsync          ; pause for a frame.
       pop bc              ; restore counter.
       djnz delay          ; repeat.
       ret

; Clear sprite table.

xspr   ld hl,sprtab        ; sprite table.
       ld b,SPRBUF         ; length of table.
xspr0  ld (hl),255         ; clear one byte.
       inc hl              ; move to next byte.
       djnz xspr0          ; repeat for rest of table.
       ret

silenc call silen1         ; silence channel 1.
       call silen2         ; silence channel 2.
       call silen3         ; silence channel 3.
       jp plsnd            ; play all channels to switch them off.

; Initialise all objects.

iniob  ld ix,objdta        ; objects table.
       ld a,(numob)        ; number of objects in the game.
       ld b,a              ; loop counter.
       ld de,70            ; distance between objects.
iniob0 ld a,(ix+67)        ; start screen.
       ld (ix+64),a        ; set start screen.
       ld a,(ix+68)        ; find start x.
       ld (ix+65),a        ; set start x.
       ld a,(ix+69)        ; get initial y.
       ld (ix+66),a        ; set y coord.
       add ix,de           ; point to next object.
       djnz iniob0         ; repeat.
       ret

; Screen synchronisation.

vsync  call joykey         ; read joystick/keyboard.
       ld hl,framec        ; frame counter.
       ld a,(hl)           ; clock reading.
       inc (hl)            ; post-increment frame.
       rra                 ; rotate bit into carry.
       call c,vsync5       ; time to play sound and do shrapnel/ticker stuff.
       ld bc,clock         ; last clock reading.
vsync0 call 48397          ; get current clock.
       ld a,(bc)           ; previous clock.
       sub l               ; new reading.
       cp 251              ; difference of 6?
       jr nc,vsync0        ; no, wait until clock changes.
       ld a,l              ; clock reading in accumulator.
       ld (bc),a           ; set new clock reading.
       ret
vsync5 call plsnd          ; play sound.
       jp proshr           ; shrapnel and stuff.

sndtyp defb 0
framec defb 0              ; frame counter.
firmad defw 0

; Redraw the screen.

; Remove old copy of all sprites for redraw.

redraw push ix             ; place sprite pointer on stack.
       call droom          ; show screen layout.
       call shwob          ; draw objects.
numsp0 ld b,NUMSPR         ; sprites to draw.
       ld ix,sprtab        ; sprite table.
redrw0 ld a,(ix+0)         ; old sprite type.
       inc a               ; is it enabled?
       jr z,redrw1         ; no, find next one.
       ld a,(ix+3)         ; sprite x.
       cp 185              ; beyond maximum?
       jr nc,redrw1        ; yes, nothing to draw.
       push bc             ; store sprite counter.
       call sspria         ; show single sprite.
       pop bc              ; retrieve sprite counter.
redrw1 ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       djnz redrw0         ; repeat for remaining sprites.
rpblc1 call dshrp          ; redraw shrapnel.
       pop ix              ; retrieve sprite pointer.
       ret

; Clear screen routine.

cls    jp 48148            ; clear screen.

; Set palette routine and data.
; Palette.
; 0  Black
; 1  Blue
; 2  Bright blue
; 3  Red
; 4  Magenta
; 5  Mauve
; 6  Bright red
; 7  Purple
; 8  Bright magenta
; 9  Green
; 10 Cyan
; 11 Sky blue
; 12 Yellow
; 13 White
; 14 Pastel blue
; 15 Orange
; 16 Pink
; 17 Pastel magenta
; 18 Bright green
; 19 Sea green
; 20 Bright cyan
; 21 Lime
; 22 Pastel green
; 23 Pastel cyan
; 24 Bright yellow
; 25 Pastel yellow
; 26 Bright white

setpal ld a,16             ; colours to set.
       ld hl,palett+15     ; palette.
setpa0 ld c,(hl)           ; get colour.
       dec hl              ; next in list.
       ld b,c              ; make sure it's in b and c.
       dec a
       push af             ; store pen number.
       push hl             ; store palette pointer.
       call 48178          ; set palette colour.
       pop hl              ; restore palette pointer.
       pop af              ; restore pen.
       jr nz,setpa0        ; repeat until all colours are set.
       ret

fdchk  ld a,(hl)           ; fetch cell.
       cp FODDER           ; is it fodder?
       ret nz              ; no.
       ld (hl),0           ; rewrite block type.
       push hl             ; store pointer to block.
       ld de,MAP           ; address of map.
       and a               ; clear carry flag for subtraction.
       sbc hl,de           ; find simple displacement for block.
       ld a,l              ; low byte is y coordinate.
       and 31              ; column position 0 - 31.
       ld (dispy),a        ; set up y position.
       add hl,hl           ; multiply displacement by 8.
       add hl,hl
       add hl,hl
       ld a,h              ; x coordinate now in h.
       ld (dispx),a        ; set the display coordinate.
       xor a               ; block to write.
       call pattr          ; write block.
       pop hl              ; restore block pointer.
       ret

; Routine to colour a sprite is redundant on CPC.

cspr   ret

; Scrolly text and puzzle variables.

txtbit defb 128            ; bit to write.
txtwid defb 16             ; width of ticker message.
txtpos defw msgdat
txtini defw msgdat
txtscr defw 16406

; Specialist routines.
; Process shrapnel.

proshr ld ix,SHRAPN        ; table.
       ld b,NUMSHR         ; shrapnel pieces to process.
       ld de,SHRSIZ        ; distance to next.
prosh0 ld a,(ix+0)         ; on/off marker.
       rla                 ; check its status.
proshx call nc,prosh1      ; on, so process it.
       add ix,de           ; point there.
       djnz prosh0         ; round again.
       jp scrly
prosh1 push bc             ; store counter.
       call plot           ; delete the pixel.
       ld a,(ix+0)         ; restore shrapnel type.
       ld hl,shrptr        ; shrapnel routine pointers.
       call prosh2         ; run the routine.
       call chkxy          ; check x and y are good before we redisplay.
       pop bc              ; restore counter.
       ld de,SHRSIZ        ; distance to next.
       ret
prosh2 rlca                ; 2 bytes per address.
       ld e,a              ; copy to de.
       add hl,de           ; point to address of routine.
       ld a,(hl)           ; get address low.
       inc hl              ; point to second byte.
       ld h,(hl)           ; fetch high byte from table.
       ld l,a              ; put low byte in l.
       jp (hl)             ; jump to routine.

shrptr defw laser          ; laser.
       defw trail          ; vapour trail.
       defw shrap          ; shrapnel from explosion.
       defw dotl           ; horizontal starfield left.
       defw dotr           ; horizontal starfield right.
       defw dotu           ; vertical starfield up.
       defw dotd           ; vertical starfield down.
       defw ptcusr         ; user particle.

; Explosion shrapnel.

shrap  ld e,(ix+1)         ; get the angle.
       ld d,0              ; no high byte.
       ld hl,shrsin        ; shrapnel sine table.
       add hl,de           ; point to sine.

       ld e,(hl)           ; fetch value from table.
       inc hl              ; next byte of table.
       ld d,(hl)           ; fetch value from table.
       inc hl              ; next byte of table.
       ld c,(hl)           ; fetch value from table.
       inc hl              ; next byte of table.
       ld b,(hl)           ; fetch value from table.
       ld l,(ix+2)         ; x coordinate in hl.
       ld h,(ix+3)
       add hl,de           ; add sine.
       ld (ix+2),l         ; store new coordinate.
       ld (ix+3),h
       ld l,(ix+4)         ; y coordinate in hl.
       ld h,(ix+5)
       add hl,bc           ; add cosine.
       ld (ix+4),l         ; store new coordinate.
       ld (ix+5),h
       ret

dotl   dec (ix+5)          ; move left.
       ret
dotr   inc (ix+5)          ; move left.
       ret
dotu   dec (ix+3)          ; move up.
       ret
dotd   inc (ix+3)          ; move down.
       ret

; Check coordinates are good before redrawing at new position.

chkxy  ld hl,wntopx        ; window top.
       ld a,(ix+3)         ; fetch shrapnel coordinate.
       cp (hl)             ; compare with top window limit.
       jr c,kilshr         ; out of window, kill shrapnel.
       inc hl              ; left edge.
       ld a,(ix+5)         ; fetch shrapnel coordinate.
       cp (hl)             ; compare with left window limit.
       jr c,kilshr         ; out of window, kill shrapnel.

       inc hl              ; point to bottom.
       ld a,(hl)           ; fetch window limit.
       add a,15            ; add height of sprite.
       cp (ix+3)           ; compare with shrapnel x coordinate.
       jr c,kilshr         ; off screen, kill shrapnel.
       inc hl              ; point to right edge.
       ld a,(hl)           ; fetch shrapnel y coordinate.
       add a,9             ; add width of sprite.
       cp (ix+5)           ; compare with window limit.
       jr c,kilshr         ; off screen, kill shrapnel.

; Drop through.
; Display shrapnel.

plot   ld l,(ix+3)         ; x integer.
       ld h,(ix+5)         ; y integer.
       ld (dispx),hl       ; workspace coordinates.
       ld a,(ix+0)         ; type.
       and a               ; is it a laser?
       jr z,plot2          ; yes, draw laser instead.
plot0  ld a,h              ; which pixel within byte do we
       rra                 ; want to set first?
       ld e,170            ; default to left pixel.
       jr nc,plot1         ; jump to set pixel code.
       ld e,85             ; draw right pixel instead.
plot1  call scadd          ; screen address.
       ld a,(hl)           ; see what's already there.
       xor e               ; merge with pixels.
       ld (hl),a           ; put back on screen.
       ret
plot2  ld a,h              ; get horizontal position.
       rra                 ; start at left or right pixel?
       push af             ; preserve carry.
       call scadd          ; screen address.
       pop af              ; restore carry.
       jr c,plot3          ; start at right pixel.
       ld a,(hl)           ; fetch byte there.
       cpl                 ; toggle 2 pixels.
       ld (hl),a           ; new byte.
       inc hl              ; next byte.
       ld a,(hl)           ; fetch byte there.
       cpl                 ; toggle 2 pixels.
       ld (hl),a           ; write the new byte.
       inc hl              ; next byte.
       ld a,(hl)           ; fetch byte there.
       xor 170             ; merge pixel.
       ld (hl),a           ; set new screen byte value.
       ret
plot3  ld a,(hl)           ; fetch byte there.
       xor 85              ; merge pixel.
       ld (hl),a           ; write new byte.
       inc hl              ; next byte.
       ld a,(hl)           ; fetch byte there.
       cpl                 ; toggle 2 pixels.
       ld (hl),a           ; write the new byte.
       inc hl              ; next byte.
       ld a,(hl)           ; fetch byte there.
       cpl                 ; toggle 2 pixels.
       ld (hl),a           ; write the new byte.
       ret

kilshr ld (ix+0),128       ; switch off shrapnel.
       ret

;explc  defb 0              ; explosion counter.

shrsin defw 0,1024,391,946,724,724,946,391
       defw 1024,0,946,65144,724,64811,391,64589
       defw 0,64512,65144,64589,64811,64811,64589,65144
       defw 64512,0,64589,391,64811,724,65144,946

trail  dec (ix+1)          ; time remaining.
       jp z,trailk         ; time to switch it off.
       call qrand          ; get a random number.
       rra                 ; x or y axis?
       jr c,trailv         ; use x.
       rra                 ; which direction?
       jr c,traill         ; go left.
       inc (ix+5)          ; go right.
       ret
traill dec (ix+5)          ; go left.
       ret
trailv rra                 ; which direction?
       jr c,trailu         ; go up.
       inc (ix+3)          ; go down.
       ret
trailu dec (ix+3)          ; go up.
       ret
trailk ld (ix+3),200       ; set off-screen to kill vapour trail.
       ret

laser  ld a,(ix+1)         ; direction.
       rra                 ; left or right?
       jr nc,laserl        ; move left.
       ld b,5              ; distance to travel.
       jr laserm           ; move laser.
laserl ld b,251            ; distance to travel.
laserm ld a,(ix+5)         ; y position.
       add a,b             ; add distance.
       ld (ix+5),a         ; set new y coordinate.

; Test new block.

       ld (dispy),a        ; set y for block collision detection purposes.
       ld a,(ix+3)         ; get x.
       ld (dispx),a        ; set coordinate for collision test.
       call tstbl          ; get block type there.
       cp WALL             ; is it solid?
       jr z,trailk         ; yes, it cannot pass.
       cp FODDER           ; is it fodder?
       ret nz              ; no, ignore it.
       call fdchk          ; remove fodder block.
       jr trailk           ; destroy laser.

; Plot, preserving de.

plotde push de             ; put de on stack.
       call plot           ; plot pixel.
       pop de              ; restore de from stack.
       ret

; Shoot a laser.

shoot  ld c,a              ; store direction in c register.
       ld a,(ix+8)         ; x coordinate.
shoot1 add a,7             ; down 7 pixels.
       ld l,a              ; put x coordinate in l.
       ld h,(ix+9)         ; y coordinate in h.
       push ix             ; store pointer to sprite.
       call fpslot         ; find particle slot.
       jr nc,vapou2        ; failed, restore ix.
       ld (ix+0),0         ; set up a laser.
       ld (ix+1),c         ; set the direction.
       ld (ix+3),l         ; set x coordinate.
       rr c                ; check direction we want.
       jr c,shootr         ; shoot right.
       ld a,h              ; y position.
;       dec a               ; left a pixel.
shoot0 and 248             ; align on character boundary.
       ld (ix+5),a         ; set y coordinate.
       jr vapou0           ; draw first image.
shootr ld a,h              ; y position.
       add a,9             ; look right.
       jr shoot0           ; align and continue.

; Create a bit of vapour trail.

vapour push ix             ; store pointer to sprite.
       ld l,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
vapou3 ld de,5*256+7       ; mid-point of sprite.
       add hl,de           ; point to centre of sprite.
       call fpslot         ; find particle slot.
       jr c,vapou1         ; no, we can use it.
vapou2 pop ix              ; restore sprite pointer.
       ret                 ; out of slots, can't generate anything.

vapou1 ld (ix+3),l         ; set up x.
       ld (ix+5),h         ; set up y coordinate.
       call qrand          ; get quick random number.
       and 15              ; random time.
       add a,15            ; minimum time on screen.
       ld (ix+1),a         ; set time on screen.
       ld (ix+0),1         ; define particle as vapour trail.
vapou0 call chkxy          ; plot first position.
       jr vapou2

; Create a user particle.

ptusr  ld c,a              ; store timer.
       ld l,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       ld de,5*256+7       ; mid-point of sprite.
       add hl,de           ; point to centre of sprite.
       call fpslot         ; find particle slot.
       jr c,ptusr1         ; free slot.
       ret                 ; out of slots, can't generate anything.

ptusr1 ld (ix+3),l         ; set up x.
       ld (ix+5),h         ; set up y coordinate.
       ld a,c              ; restore timer.
       ld (ix+1),a         ; set time on screen.
       ld (ix+0),7         ; define particle as user particle.
       jp chkxy            ; plot first position.


; Create a vertical or horizontal star.

star   push ix             ; store pointer to sprite.
       call fpslot         ; find particle slot.
       jp c,star7          ; found one we can use.
star0  pop ix              ; restore sprite pointer.
       ret                 ; out of slots, can't generate anything.

star7  ld a,c              ; direction.
       and 3               ; is it left?
       jr z,star1          ; yes, it's horizontal.
       dec a               ; is it right?
       jr z,star2          ; yes, it's horizontal.
       dec a               ; is it up?
       jr z,star3          ; yes, it's vertical.

       ld a,(wntopx)       ; get edge of screen.
       inc a               ; down one pixel.
star8  ld (ix+3),a         ; set x coord.
       call qrand          ; get quick random number.
star9  ld (ix+5),a         ; set y position.
       ld a,c              ; direction.
       and 3               ; zero to three.
       add a,3             ; 3 to 6 for starfield.
       ld (ix+0),a         ; define particle as star.
       call chkxy          ; plot first position.
       jp star0
star1  call qrand          ; get quick random number.
       ld (ix+3),a         ; set x coord.
       ld a,(wnrgtx)       ; get edge of screen.
       add a,8             ; add width of sprite minus 1.
       jp star9
star2  call qrand          ; get quick random number.
       ld (ix+3),a         ; set x coord.
       ld a,(wnlftx)       ; get edge of screen.
       jp star9
star3  ld a,(wnbotx)       ; get edge of screen.
       add a,15            ; height of sprite minus one pixel.
       jp star8


; Find particle slot for lasers or vapour trail.
; Can't use alternate accumulator.

fpslot ld ix,SHRAPN        ; shrapnel table.
       ld de,SHRSIZ        ; size of each particle.
       ld b,NUMSHR         ; number of pieces in table.
fpslt0 ld a,(ix+0)         ; get type.
       rla                 ; is this slot in use?
       ret c               ; no, we can use it.
       add ix,de           ; point to more shrapnel.
       djnz fpslt0         ; repeat for all shrapnel.
       ret                 ; out of slots, can't generate anything.

; Create an explosion at sprite position.

explod ld c,a              ; particles to create.
       push ix             ; store pointer to sprite.
       ld l,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       ld ix,SHRAPN        ; shrapnel table.
       ld de,SHRSIZ        ; size of each particle.
       ld b,NUMSHR         ; number of pieces in table.
expld0 ld a,(ix+0)         ; get type.
       rla                 ; is this slot in use?
       jr c,expld1         ; no, we can use it.
expld2 add ix,de           ; point to more shrapnel.
       djnz expld0         ; repeat for all shrapnel.
expld3 pop ix              ; restore sprite pointer.
       ret                 ; out of slots, can't generate any more.
expld1 ld a,c              ; shrapnel counter.
       and 15              ; 0 to 15.
       add a,l             ; add to x.
       ld (ix+3),a         ; x coord.
       ld a,(seed3)        ; crap random number.
       and 7               ; 0 to 7.
       inc a               ; 1 to 8.
       add a,h             ; add to y.
       ld (ix+5),a         ; y coord.
       ld (ix+0),2         ; switch it on.
       push hl             ; store coordinates.
       call chkxy          ; plot first position.
       call qrand          ; quick random angle.
       and 60              ; keep within range.
       ld (ix+1),a         ; angle.
       pop hl              ; restore coordinates.
       ld de,SHRSIZ        ; restore size of each particle.
       dec c               ; one piece of shrapnel fewer to generate.
       jr nz,expld2        ; back to main explosion loop.
       jr expld3           ; restore sprite pointer and exit.
qrand  ld a,(seed3)        ; random seed.
       ld l,a              ; low byte.
       ld h,0              ; no high byte.
       ld a,r              ; r register.
       xor (hl)            ; combine with seed.
       ld (seed3),a        ; new seed.
       ret
seed3  defb 0

; Display all shrapnel.

dshrp  ld hl,plotde        ; display routine.
       ld (proshx+1),hl    ; modify routine.
       call proshr         ; process shrapnel.
       ld hl,prosh1        ; processing routine.
       ld (proshx+1),hl    ; modify the call.
       ret

; Particle engine.

inishr ld hl,SHRAPN        ; table.
       ld b,NUMSHR         ; shrapnel pieces to process.
       ld de,SHRSIZ        ; distance to next.
inish0 ld (hl),255         ; kill the shrapnel.
       add hl,de           ; point there.
       djnz inish0         ; round again.
       ret

; Check for collision between laser and sprite.

lcol   ld hl,SHRAPN        ; shrapnel table.
       ld de,SHRSIZ        ; size of each particle.
       ld b,NUMSHR         ; number of pieces in table.
lcol0  ld a,(hl)           ; get type.
       and a               ; is this slot a laser?
       jr z,lcol1          ; yes, check collision.
lcol3  add hl,de           ; point to more shrapnel.
       djnz lcol0          ; repeat for all shrapnel.
       ret                 ; no collision, carry not set.
lcol1  push hl             ; store pointer to laser.
       inc hl              ; direction.
       inc hl              ; not used.
       inc hl              ; x position.
       ld a,(hl)           ; get x.
       sub (ix+X)          ; subtract sprite x.
lcolh  cp 16               ; within range?
       jr nc,lcol2         ; no, missed.
       inc hl              ; not used.
       inc hl              ; y position.
       ld a,(hl)           ; get y.
       add a,4             ; add width of laser.
       sub (ix+Y)          ; subtract sprite y.
       cp 14               ; within range?
       jr c,lcol4          ; yes, collision occurred.
lcol2  pop hl              ; restore laser pointer from stack.
       jr lcol3
lcol4  pop hl              ; restore laser pointer.
       ret                 ; return with carry set for collision.

; Main game engine code starts here.

game   equ $

       call setpal         ; set up palette.
rpblc2 call inishr         ; initialise particle engine.
evintr call evnt12         ; call intro/menu event.

       ld hl,MAP           ; block properties.
       ld de,MAP+1         ; next byte.
       ld bc,799           ; size of properties map = 32 x 25.
       ld (hl),WALL        ; write default property.
       ldir
       call iniob          ; initialise objects.
       xor a               ; put zero in accumulator.
       ld (gamwon),a       ; reset game won flag.

       ld hl,score         ; score.
       call inisc          ; init the score.
mapst  ld a,(stmap)        ; start position on map.
       ld (roomtb),a       ; set up position in table, if there is one.
inipbl call initsc         ; set up first screen.
       ld ix,ssprit        ; default to spare sprite in table.
evini  call evnt13         ; initialisation.

; Two restarts.
; First restart - clear all sprites and initialise everything.

rstrt  call rsevt          ; restart events.
       call xspr           ; clear sprite table.
       call sprlst         ; fetch pointer to screen sprites.
       call ispr           ; initialise sprite table.
       jr rstrt0

; Second restart - clear all but player, and don't initialise him.

rstrtn call rsevt          ; restart events.
       call nspr           ; clear all non-player sprites.
       call sprlst         ; fetch pointer to screen sprites.
       call kspr           ; initialise sprite table, no more players.


; Set up the player and/or enemy sprites.

rstrt0 xor a               ; zero in accumulator.
       ld (nexlev),a       ; reset next level flag.
       ld (restfl),a       ; reset restart flag.
       ld (deadf),a        ; reset dead flag.
       call droom          ; show screen layout.
rpblc0 call inishr         ; initialise particle engine.
       call shwob          ; draw objects.
       ld ix,sprtab        ; address of sprite table, even sprites.
       call dspr           ; display sprites.
       ld ix,sprtab+TABSIZ ; address of first odd sprite.
       call dspr           ; display sprites.

mloop  call vsync          ; synchronise with display.

       ld ix,sprtab        ; address of sprite table, even sprites.
       call dspr           ; display even sprites.

       call plsnd          ; play sounds.
       call vsync          ; synchronise with display.
       ld ix,sprtab+TABSIZ ; address of first odd sprite.
       call dspr           ; display odd sprites.
       ld ix,ssprit        ; point to spare sprite for spawning purposes.
evlp1  call evnt10         ; called once per main loop.
       call pspr           ; process sprites.

; Main loop events.

       ld ix,ssprit        ; point to spare sprite for spawning purposes.
evlp2  call evnt11         ; called once per main loop.

bsortx call bsort          ; sort sprites.
       ld a,(nexlev)       ; finished level flag.
       and a               ; has it been set?
       jr nz,newlev        ; yes, go to next level.
       ld a,(gamwon)       ; finished game flag.
       and a               ; has it been set?
       jr nz,evwon         ; yes, finish the game.
       ld a,(restfl)       ; finished level flag.
       dec a               ; has it been set?
       jr z,rstrt          ; yes, go to next level.
       dec a               ; has it been set?
       jr z,rstrtn         ; yes, go to next level.

       ld a,(deadf)        ; dead flag.
       and a               ; is it non-zero?
       jr nz,pdead         ; yes, player dead.

       ld hl,frmno         ; game frame.
       inc (hl)            ; advance the frame.

; back to start of main loop.

       ld bc,49150         ; keyboard row H - ENTER.
       in a,(c)            ; read it.
       rra                 ; rotate bit for ENTER into carry.
qoff   jp mloop            ; switched to a jp nz,mloop during test mode.
       ret
newlev ld a,(scno)         ; current screen.
       ld hl,numsc         ; total number of screens.
       inc a               ; next screen.
       cp (hl)             ; reached the limit?
       jr nc,evwon         ; yes, game finished.
       ld (scno),a         ; set new level number.
       jp rstrt            ; restart, clearing all aliens.
evwon  call evnt18         ; game completed.
       jp tidyup           ; tidy up and return to BASIC/calling routine.

; Player dead.

pdead  xor a               ; zeroise accumulator.
       ld (deadf),a        ; reset dead flag.
evdie  call evnt16         ; death subroutine.
       ld a,(numlif)       ; number of lives.
       and a               ; reached zero yet?
       jp nz,rstrt         ; restart game.
evfail call evnt17         ; failure event.
tidyup ld hl,hiscor        ; high score.
       ld de,score         ; player's score.
       ld b,6              ; digits to check.
tidyu2 ld a,(de)           ; get score digit.
       cp (hl)             ; are we larger than high score digit?
       jr c,tidyu0         ; high score is bigger.
       jr nz,tidyu1        ; score is greater, record new high score.
       inc hl              ; next digit of high score.
       inc de              ; next digit of score.
       djnz tidyu2         ; repeat for all digits.
tidyu0 call 47875          ; reset key manager, empty buffer.
       ld hl,(firmad)      ; firmware interrupt address.
       ld (57),hl          ; restore interrupts.
       ld hl,score         ; return pointing to score so programmer can store high-score.
       ret
tidyu1 ld hl,score         ; score.
       ld de,hiscor        ; high score.
       ld bc,6             ; digits to copy.
       ldir                ; copy score to high score.
evnewh call evnt19         ; new high score event.
       jr tidyu0           ; tidy up.

; Restart event.

rsevt  ld ix,ssprit        ; default to spare element in table.
evrs   jp evnt14           ; call restart event.

; Copy number passed in a to string position bc, right-justified.

num2ch ld l,a              ; put accumulator in l.
       ld h,0              ; blank high byte of hl.
       ld a,32             ; leading spaces.
       ld de,100           ; hundreds column.
       call numdg          ; show digit.
       ld de,10            ; tens column.
       call numdg          ; show digit.
       or 16               ; last digit is always shown.
       ld de,1             ; units column.
numdg  and 48              ; clear carry, clear digit.
numdg1 sbc hl,de           ; subtract from column.
       jr c,numdg0         ; nothing to show.
       or 16               ; something to show, make it a digit.
       inc a               ; increment digit.
       jr numdg1           ; repeat until column is zero.
numdg0 add hl,de           ; restore total.
       cp 32               ; leading space?
       ret z               ; yes, don't write that.
       ld (bc),a           ; write digit to buffer.
       inc bc              ; next buffer position.
       ret

inisc  ld b,6              ; digits to initialise.
inisc0 ld (hl),'0'         ; write zero digit.
       inc hl              ; next column.
       djnz inisc0         ; repeat for all digits.
       ret


; Multiply h by d and return in hl.

imul   ld e,d              ; HL = H * D
       ld c,h              ; make c first multiplier.
imul0  ld hl,0             ; zeroise total.
       ld d,h              ; zeroise high byte.
       ld b,8              ; repeat 8 times.
imul1  rr c                ; rotate rightmost bit into carry.
       jr nc,imul2         ; wasn't set.
       add hl,de           ; bit was set, so add de.
       and a               ; reset carry.
imul2  rl e                ; shift de 1 bit left.
       rl d
       djnz imul1          ; repeat 8 times.
       ret

; Divide d by e and return in d, remainder in a.

idiv   xor a
       ld b,8              ; bits to shift.
idiv0  sla d               ; multiply d by 2.
       rla                 ; shift carry into remainder.
       cp e                ; test if e is smaller.
       jr c,idiv1          ; e is greater, no division this time.
       sub e               ; subtract it.
       inc d               ; rotate into d.
idiv1  djnz idiv0
       ret

; Initialise a sound.

isnd   ld de,(ch1ptr)      ; first pointer.
       ld a,(de)           ; get first byte.
       inc a               ; reached the end?
       jr z,isnd1          ; that'll do.
       ld de,(ch2ptr)      ; second pointer.
       ld a,(de)           ; get first byte.
       inc a               ; reached the end?
       jr z,isnd2          ; that'll do.
       ld de,(ch3ptr)      ; final pointer.
       ld a,(de)           ; get first byte.
       inc a               ; reached the end?
       jr z,isnd3          ; that'll do.
       ret
isnd1  ld (ch1ptr),hl      ; set up the sound.
       ret
isnd2  ld (ch2ptr),hl      ; set up the sound.
       ret
isnd3  ld (ch3ptr),hl      ; set up the sound.
       ret


ch1ptr defw nosnd
ch2ptr defw nosnd
ch3ptr defw nosnd

plsnd  call plsnd1         ; first channel.
       call plsnd2         ; second one.
       call plsnd3         ; final channel.

; Write the contents of our AY buffer to the AY registers.

w8912  ld hl,snddat        ; start of AY-3-8912 register data.
       ld de,14*256        ; start with register 0, 14 to write.
       ld c,253            ; low byte of port to write.
w8912a ld b,255            ; port 65533=select soundchip register.
       ld a,(hl)           ; value to write.
       ld c,e              ; register to write.

       ld b,244            ; setup PSG register number on PPI port A.
       out (c),c           ;
       ld bc,&f6c0         ; tell PSG to select register from data on PPI port A.
       out (c),c           ;
       ld bc,&f600         ; put PSG into inactive state.
       out (c),c           ;
       ld b,244            ; setup register data on PPI port A.
       out (c),a           ;
       ld bc,&f680         ; tell PSG to write data on PPI port A into selected register.
       out (c),c           ;
       ld bc,&f600         ; put PSG into inactive state.
       out (c),c           ;

       inc e               ; next sound chip register.
       inc hl              ; next byte to write.
       dec d               ; decrement loop counter.
       jp nz,w8912a        ; repeat until done.
       ret

snddat defw 0              ; tone registers, channel A.
       defw 0              ; channel B tone registers.
       defw 0              ; as above, channel C.
sndwnp defb 0              ; white noise period.
sndmix defb 60             ; tone/noise mixer control.
sndv1  defb 0              ; channel A amplitude/envelope generator.
sndv2  defb 0              ; channel B amplitude/envelope.
sndv3  defb 0              ; channel C amplitude/envelope.
       defw 0              ; duration of each note.
       defb 0

plwn   inc hl              ; next byte of sound.
       and 56              ; check if we're bothering with white noise.
       ret nz              ; we're not.
       ld a,(hl)           ; fetch byte.
       ld (sndwnp),a       ; set white noise period.
       ret


plsnd2 call cksnd2         ; check sound for first channel.
       cp 255              ; reached end?
       jr z,silen2         ; silence this channel.
       and 15              ; sound bits.
       ld (sndv2),a        ; set volume for channel.
       ld a,(sndmix)       ; mixer byte.
       and 237             ; remove bits for this channel.
       ld b,a              ; store in b register.
       call plmix          ; fetch mixer details.
       and 18              ; mixer bits we want.
       or b                ; combine with mixer bits.
       ld (sndmix),a       ; new mixer value.
       call plwn           ; white noise check.
       inc hl              ; tone low.
       ld e,(hl)           ; fetch value.
       inc hl              ; tone high.
       ld d,(hl)           ; fetch value.
       ld (snddat+2),de    ; set tone.
       inc hl              ; next bit of sound.
       ld (ch2ptr),hl      ; set pointer.
       ret

plsnd3 call cksnd3         ; check sound for first channel.
       cp 255              ; reached end?
       jr z,silen3         ; silence last channel.
       and 15              ; sound bits.
       ld (sndv3),a        ; set volume for channel.
       ld a,(sndmix)       ; mixer byte.
       and 219             ; remove bits for this channel.
       ld b,a              ; store in b register.
       call plmix          ; fetch mixer details.
       and 36              ; mixer bits we want.
       or b                ; combine with mixer bits.
       ld (sndmix),a       ; new mixer value.
       call plwn           ; white noise check.
       inc hl              ; tone low.
       ld e,(hl)           ; fetch value.
       inc hl              ; tone high.
       ld d,(hl)           ; fetch value.
       ld (snddat+4),de    ; set tone.
       inc hl              ; next bit of sound.
       ld (ch3ptr),hl      ; set pointer.
       ret

plmix  ld a,(hl)           ; fetch mixer byte.
       and 192             ; mix bits are d6 and d7.
       rlca                ; rotate into d0 and d1.
       rlca
       ld e,a              ; displacement in de.
       ld d,0
       push hl             ; store pointer on stack.
       ld hl,mixtab        ; mixer table.
       add hl,de           ; point to mixer byte.
       ld a,(hl)           ; fetch mixer value.
       pop hl              ; restore pointer.
       ret
mixtab defb 63,56,7,0      ; mixer byte settings.

silen1 xor a               ; zero.
       ld (sndv1),a        ; sound off.
       ld a,(sndmix)       ; mixer byte.
       or 9                ; mix bits off.
       ld (sndmix),a       ; mixer setting for channel.
       ret
silen2 xor a               ; zero.
       ld (sndv2),a        ; sound off.
       ld a,(sndmix)       ; mixer byte.
       or 18               ; mix bits off.
       ld (sndmix),a       ; mixer setting for channel.
       ret
silen3 xor a               ; zero.
       ld (sndv3),a        ; sound off.
       ld a,(sndmix)       ; mixer byte.
       or 36               ; mix bits off.
       ld (sndmix),a       ; mixer setting for channel.
       ret
cksnd1 ld hl,(ch1ptr)      ; pointer to sound.
       ld a,(hl)           ; fetch mixer/flag.
       ret
cksnd2 ld hl,(ch2ptr)      ; pointer to sound.
       ld a,(hl)           ; fetch mixer/flag.
       ret
cksnd3 ld hl,(ch3ptr)      ; pointer to sound.
       ld a,(hl)           ; fetch mixer/flag.
       ret

plsnd1 call cksnd1         ; check sound for first channel.
       cp 255              ; reached end?
       jr z,silen1         ; silence first channel.
       and 15              ; sound bits.
       ld (sndv1),a        ; set volume for channel.
       ld a,(sndmix)       ; mixer byte.
       and 246             ; remove bits for this channel.
       ld b,a              ; store in b register.
       call plmix          ; fetch mixer details.
       and 9               ; mixer bits we want.
       or b                ; combine with mixer bits.
       ld (sndmix),a       ; new mixer value.
       call plwn           ; white noise check.
       inc hl              ; tone low.
       ld e,(hl)           ; fetch value.
       inc hl              ; tone high.
       ld d,(hl)           ; fetch value.
       ld (snddat),de      ; set tone.
       inc hl              ; next bit of sound.
       ld (ch1ptr),hl      ; set pointer.
       ret


; Objects handling.
; 32 bytes for image
; 1 for colour
; 3 for room, x and y
; 3 for starting room, x and y.
; 254 = disabled.
; 255 = object in player's pockets.

; Show items present.

shwob  ld hl,objdta        ; objects table.
       ld de,64            ; distance to room number.
       add hl,de           ; point to room data.
       ld a,(numob)        ; number of objects in the game.
       ld b,a              ; loop counter.
shwob0 push bc             ; store count.
       push hl             ; store item pointer.
       ld a,(scno)         ; current location.
       cp (hl)             ; same as an item?
       call z,dobj         ; yes, display object.
       pop hl              ; restore pointer.
       pop bc              ; restore counter.
       ld de,70            ; distance to next item.
       add hl,de           ; point to it.
       djnz shwob0         ; repeat for others.
       ret

; Display object.
; hl must point to object's room number.

dobj   inc hl              ; point to x.
dobj0  ld de,dispx         ; coordinates.
       ldi                 ; transfer x coord.
       ldi                 ; transfer y too.
       ld de,65469         ; minus 67.
       add hl,de           ; point to image.
dobj1  jp sprite           ; draw this sprite.

; Remove an object.

remob  ld hl,numob         ; number of objects in game.
       cp (hl)             ; are we checking past the end?
       ret nc              ; yes, can't get non-existent item.
       push af             ; remember object.
       call getob          ; pick it up if we haven't already got it.
       pop af              ; retrieve object number.
       call gotob          ; get its address.
       ld (hl),254         ; remove it.
       ret

; Pick up object number held in the accumulator.

getob  ld hl,numob         ; number of objects in game.
       cp (hl)             ; are we checking past the end?
       ret nc              ; yes, can't get non-existent item.
       call gotob          ; check if we already have it.
       ret z               ; we already do.
       ex de,hl            ; object address in de.
       ld hl,scno          ; current screen.
       cp (hl)             ; is it on this screen?
       ex de,hl            ; object address back in hl.
       jr nz,getob0        ; not on screen, so nothing to delete.
       ld (hl),255         ; pick it up.
       inc hl              ; point to x coord.
getob1 ld e,(hl)           ; x coord.
       inc hl              ; back to y coord.
       ld d,(hl)           ; y coord.
       ld (dispx),de       ; set display coords.
       ld de,65470         ; minus graphic size.
       add hl,de           ; point to graphics.
       jp dobj1            ; delete object sprite.
getob0 ld (hl),255         ; pick it up.
       ret

; Got object check.
; Call with object in accumulator, returns zero set if in pockets.

gotob  ld hl,numob         ; number of objects in game.
       cp (hl)             ; are we checking past the end?
       jr nc,gotob0        ; yes, we can't have a non-existent object.
       call findob         ; find the object.
gotob1 cp 255              ; in pockets?
       ret
gotob0 ld a,254            ; missing.
       jr gotob1

findob ld hl,objdta        ; objects.
       ld de,70            ; size of each object.
       and a               ; is it zero?
       jr z,fndob1         ; yes, skip loop.
       ld b,a              ; loop counter in b.
fndob2 add hl,de           ; point to next one.
       djnz fndob2         ; repeat until we find address.
fndob1 ld e,64             ; distance to room it's in.
       add hl,de           ; point to room.
       ld a,(hl)           ; fetch status.
       ret

; Drop object number at (dispx, dispy).

drpob  ld hl,numob         ; number of objects in game.
       cp (hl)             ; are we checking past the end?
       ret nc              ; yes, can't drop non-existent item.
       call gotob          ; make sure object is in inventory.
       ld a,(scno)         ; screen number.
       cp (hl)             ; already on this screen?
       ret z               ; yes, nothing to do.
       ld (hl),a           ; bring onto screen.
       inc hl              ; point to x coord.
       ld a,(dispx)        ; sprite x coordinate.
       ld (hl),a           ; set x coord.
       inc hl              ; point to object y.
       ld a,(dispy)        ; sprite y coordinate.
       ld (hl),a           ; set the y position.
       ld de,65470         ; minus graphic size.
       add hl,de           ; point to graphics.
       jp dobj1            ; delete object sprite.

; Seek objects at sprite position.

skobj  ld hl,objdta        ; pointer to objects.
       ld de,64            ; distance to room number.
       add hl,de           ; point to room data.
       ld de,70            ; size of each object.
       ld a,(numob)        ; number of objects in game.
       ld b,a              ; set up the loop counter.
skobj0 ld a,(scno)         ; current room number.
       cp (hl)             ; is object in here?
       call z,skobj1       ; yes, check coordinates.
       add hl,de           ; point to next object in table.
       djnz skobj0         ; repeat for all objects.
       ld a,255            ; end of list and nothing found, return 255.
       ret
skobj1 inc hl              ; point to x coordinate.
       ld a,(hl)           ; get coordinate.
       sub (ix+8)          ; subtract sprite x.
       add a,15            ; add sprite height minus one.
       cp 31               ; within range?
       jp nc,skobj2        ; no, ignore object.
       inc hl              ; point to y coordinate now.
       ld a,(hl)           ; get coordinate.
       sub (ix+9)          ; subtract the sprite y.
       add a,8             ; add sprite width minus one.
       cp 18               ; within range?
       jp nc,skobj3        ; no, ignore object.
       pop de              ; remove return address from stack.
       ld a,(numob)        ; objects in game.
       sub b               ; subtract loop counter.
       ret                 ; accumulator now points to object.
skobj3 dec hl              ; back to y position.
skobj2 dec hl              ; back to room.
       ret


; Spawn a new sprite.

spawn  ld hl,sprtab        ; sprite table.
       push bc             ; store parameters on stack.
       ld b,NUMSPR         ; number of sprites.
       ld de,TABSIZ        ; size of each entry.
spaw0  ld a,(hl)           ; get sprite type.
       inc a               ; is it an unused slot?
       jr z,spaw1          ; yes, we can use this one.
       add hl,de           ; point to next sprite in table.
       djnz spaw0          ; keep going until we find a slot.

; Didn't find one but drop through and set up a dummy sprite instead.

spaw1  pop bc              ; take image and type back off the stack.
       push ix             ; existing sprite address on stack.
       ld (spptr),hl       ; store spawned sprite address.
       ld (hl),c           ; set the type.
       inc hl              ; point to image.
       ld (hl),b           ; set the image.
       inc hl              ; next byte.
       ld (hl),0           ; frame zero.
       inc hl              ; next byte.
       ld a,(ix+X)         ; x coordinate.
       ld (hl),a           ; set sprite coordinate.
       inc hl              ; next byte.
       ld a,(ix+Y)         ; y coordinate.
       ld (hl),a           ; set sprite coordinate.
       inc hl              ; next byte.
       ex de,hl            ; swap address into de.
       ld hl,(spptr)       ; restore address of details.
       ld bc,5             ; number of bytes to duplicate.
       ldir                ; copy first version to new version.
       ex de,hl            ; swap address into de.
       ld a,(ix+10)        ; direction of original.
       ld (hl),a           ; set the direction.
       inc hl              ; next byte.
       ld (hl),b           ; reset parameter.
       inc hl              ; next byte.
       ld (hl),b           ; reset parameter.
       inc hl              ; next byte.
       ld (hl),b           ; reset parameter.
       inc hl              ; next byte.
       ld (hl),b           ; reset parameter.
rtssp  ld ix,(spptr)       ; address of new sprite.
evis1  call evnt09         ; call sprite initialisation event.
       ld ix,(spptr)       ; address of new sprite.
       call sspria         ; display the new sprite.
       pop ix              ; address of original sprite.
       ret

spptr  defw 0              ; spawned sprite pointer.
seed   defb 0              ; seed for random numbers.
seed2  defb 0              ; second seed.
score  defb '000000'       ; player's score.
hiscor defb '000000'       ; high score.
bonus  defb '000000'       ; bonus.

checkx ld a,e              ; x position.
       cp 24               ; off screen?
       ret c               ; no, it's okay.
       pop hl              ; remove return address from stack.
       ret

; Displays the current high score.

dhisc  ld hl,hiscor        ; high score text.
       jr dscor1           ; check in printable range then show 6 digits.

; Displays the current score.

dscor  ld hl,score         ; score text.
dscor1 call preprt         ; set up font and print position.
       call checkx         ; make sure we're in a printable range.
       ld b,6              ; digits to display.
       ld a,(prtmod)       ; get print mode.
       and a               ; standard size text?
       jp nz,bscor0        ; no, show double-height.
dscor0 push bc             ; place counter onto the stack.
       push hl
       ld a,(hl)           ; fetch character.
       call ptxta          ; display character and advance one.
       pop hl
       inc hl              ; next score column.
       pop bc              ; retrieve character counter.
       djnz dscor0         ; repeat for all digits.
dscor2 ld hl,(dispx)       ; general coordinates.
       ld (charx),hl       ; set up display coordinates.
       ret

; Displays the current score in double-height characters.

bscor0 push bc             ; place counter onto the stack.
       push hl
       ld a,(hl)           ; fetch character.
       call btxt           ; display big char.
       pop hl
       inc hl              ; next score column.
       pop bc              ; retrieve character counter.
       djnz bscor0         ; repeat for all digits.
       jp dscor2           ; tidy up line and column variables.

; Adds number in the hl pair to the score.

addsc  ld de,score+1       ; ten thousands column.
       ld bc,10000         ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; thousands column.
       ld bc,1000          ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; hundreds column.
       ld bc,100           ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; tens column.
       ld bc,10            ; amount to add each time.
       call incsc          ; add to score.
       inc de              ; units column.
       ld bc,1             ; units.
incsc  push hl             ; store amount to add.
       and a               ; clear the carry flag.
       sbc hl,bc           ; subtract from amount to add.
       jr c,incsc0         ; too much, restore value.
       pop af              ; delete the previous amount from the stack.
       push de             ; store column position.
       call incsc2         ; do the increment.
       pop de              ; restore column.
       jp incsc            ; repeat until all added.
incsc0 pop hl              ; restore previous value.
       ret
incsc2 ld a,(de)           ; get amount.
       inc a               ; add one to column.
       ld (de),a           ; write new column total.
       cp '9'+1            ; gone beyond range of digits?
       ret c               ; no, carry on.
       ld a,'0'            ; mae it zero.
       ld (de),a           ; write new column total.
       dec de              ; back one column.
       jr incsc2

; Add bonus to score.

addbo  ld de,score+5       ; last score digit.
       ld hl,bonus+5       ; last bonus digit.
       and a               ; clear carry.
       ld bc,6*256+48      ; 6 digits to add, ASCII '0' in c.
addbo0 ld a,(de)           ; get score.
       adc a,(hl)          ; add bonus.
       sub c               ; 0 to 18.
       ld (hl),c           ; zeroise bonus.
       dec hl              ; next bonus.
       cp 58               ; carried?
       jr c,addbo1         ; no, do next one.
       sub 10              ; subtract 10.
addbo1 ld (de),a           ; write new score.
       dec de              ; next score digit.
       ccf                 ; set carry for next digit.
       djnz addbo0         ; repeat for all 6 digits.
       ret

; Swap score and bonus.

swpsb  ld de,score         ; first score digit.
       ld hl,bonus         ; first bonus digit.
       ld b,6              ; digits to add.
swpsb0 ld a,(de)           ; get score and bonus digits.
       ld c,(hl)
       ex de,hl            ; swap pointers.
       ld (hl),c           ; write bonus and score digits.
       ld (de),a
       inc hl              ; next score and bonus.
       inc de
       djnz swpsb0         ; repeat for all 6 digits.
       ret

; Get print address.
; Returns screen address in de.

gprad  push hl             ; store hl pair.
       ld a,(dispx)        ; get vertical position.
       rlca                ; multiply by 8, max is 192.
       rlca
       rlca
       ld l,a              ; put into hl.
       ld h,0              ; still 8 bits, no high byte.
       add hl,hl           ; hl is now coordinate * 16.
       ld d,h              ; make de 16 * coordinate also.
       ld e,l
       add hl,hl           ; hl is coordinate * 32.
       add hl,hl           ; hl is coordinate * 64.
       add hl,de           ; now it's coordinate * 80.
       ld de,49152         ; screen base address.
       add hl,de           ; add x displacement.

       ld a,(dispy)        ; y coordinate.
       ld d,0              ; no displacement for odd position.
       rra                 ; shift odd char position into carry.
       jr nc,gprad0        ; at even position.
       ld d,2              ; odd position is two bytes along.
gprad0 and 15              ; character position / 2.
       ld e,a              ; copy to e.
       rlca                ; multiple of 2.
       rlca                ; multiple of 4.
       add a,e             ; multiple of 5.
       add a,d             ; add on any odd displacement.
       ld e,a              ; copy to de.
       ld d,0              ; high byte of displacement is zero.
       add hl,de           ; point to even char position.
       ex de,hl            ; flip result into de.
       pop hl              ; retrieve hl.
       ret

; Get property buffer address of char at (dispx, dispy) in hl.

pradd  ld a,(dispx)        ; x coordinate.
       rrca                ; multiply by 32.
       rrca
       rrca
       ld l,a              ; store shift in l.
       and 3               ; high byte bits.
       add a,MAPHI         ; 160 * 256 = 40960, start of properties map.
       ld h,a              ; that's our high byte.
       ld a,l              ; restore shift result.
       and 224             ; only want low bits.
       ld l,a              ; put into low byte.
       ld a,(dispy)        ; fetch y coordinate.
       and 31              ; should be in range 0 - 31.
       add a,l             ; add to low byte.
       ld l,a              ; new low byte.
       ret

; Display character block on screen.

pchar  rlca                ; multiply char by 8.
       rlca
       rlca
       ld e,a              ; store shift in e.
       and 7               ; only want high byte bits.
       ld d,a              ; store in d.
       ld a,e              ; restore shifted value.
       and 248             ; only want low byte bits.
       ld e,a              ; that's the low byte.
       ld hl,chgfx         ; address of graphics.
       add hl,de           ; 8 * block number.
       add hl,de           ; 16 * block number.
       add hl,de           ; 24 * block number.
pchark call gprad          ; get screen address.
       ld a,(dispy)        ; get horizontal position.
       rra                 ; are we displaying block at an odd position?
       jp c,pchar0         ; yes, need to shift everything then.
       call pchare         ; even pixel position.
       call pchare
       call pchare
       call pchare
       call pchare
       call pchare
       call pchare

pchare ldi                 ; transfer byte.
       ldi                 ; transfer byte.
       ld a,(de)           ; get data on screen.
       and 85              ; lose the left pixel colours.
       or (hl)             ; merge in third byte of data.
       inc hl              ; postincrement to next byte of data.
       ld (de),a           ; write third byte.
       ex de,hl            ; flip source and target.
       ld bc,2046          ; distance to next line.
       add hl,bc           ; look down one pixel.
       ex de,hl            ; source and target back again.
       ret

pchar0 ex de,hl            ; screen in hl, block image in de.
       call pcharo         ; odd pixel position.
       call pcharo
       call pcharo
       call pcharo
       call pcharo
       call pcharo
       call pcharo

pcharo ld a,(hl)           ; get data from screen.
       and 170             ; lose the right pixel colours.
       ld b,a              ; store result.
       ld a,(de)           ; get first byte of data to write.
       rra                 ; shift into right position.
       and 85              ; get right pixel colour.
       or b                ; merge onto screen.
       ld (hl),a           ; write that byte.

       inc hl              ; next screen byte.
       ld a,(de)           ; get first byte of image again.
       rla                 ; shift second pixel into left position.
       and 170             ; remove right bits.
       ld b,a              ; store for now.
       inc de              ; point to next byte of data.
       ld a,(de)           ; get third pixel.
       rra                 ; shift into right pixel position.
       and 85              ; remove left pixel.
       or b                ; merge with previous pixel.
       ld (hl),a           ; write to screen.
       inc hl              ; third screen byte.
       ld a,(de)           ; get second byte of image again.
       rla                 ; shift fourth pixel into left position.
       and 170             ; remove right bits.
       ld b,a              ; store for now.
       inc de              ; point to next byte of data.
       ld a,(de)           ; get fifth pixel.
       rra                 ; shift into right pixel position.
       and 85              ; remove left pixel.
       or b                ; merge with previous pixel.
       ld (hl),a           ; write to screen.
       inc de              ; point to next byte of data.

       ld bc,2046          ; distance to next line.
       add hl,bc           ; look down one pixel.
       ret

; Print property attributes and pixels.

pattr  ld b,a              ; store cell in b register for now.
       ld e,a              ; displacement in e.
       ld d,0              ; no high byte.
       ld hl,(proptr)      ; pointer to properties.
       add hl,de           ; property cell address.
       ld c,(hl)           ; fetch byte.
       call pradd          ; get property buffer address.
       ld (hl),c           ; write property.
       ld a,b              ; restore cell.

; Print character pixels, no more.

pchr   call pchar          ; show character in accumulator.
       ld hl,dispy         ; y coordinate.
       inc (hl)            ; move along one.
       ret

; Convert ink colour 0 - 15 to bitmask, 0 - 255.

conink ld c,0              ; clear destination.
       rra                 ; test lowest bit of colour.
       rl c                ; shift carry into colour.
       rl c                ; rotate again.
       rrca                ; get bit d1 out of the way.
       rra                 ; test bit d2 of colour.
       rl c                ; shift carry into mask colour.
       rl c                ; rotate again.
       rla                 ; shift original d1 bit back to d7.
       rla                 ; rotate into carry.
       rl c                ; shift carry into colour.
       rl c                ; rotate again.
       rra                 ; put original bit d3 in d0.
       rra
       rra                 ; shift into carry.
       rl c                ; shift carry into colour.
       ld a,c              ; copy colour to accumulator.
       rla                 ; create copy for higher bit of the pair.
       or c                ; merge colours for both pixels.
       ret

; Ink and paper masks.  Don't move these around, keep together in this order.

inkmsk defb 255            ; ink mask.
papmsk defb 0              ; paper mask.

; Print text, standard 5x8 pixel size.

ptxt   rlca                ; multiply char by 8.
       rlca
       rlca
       ld e,a              ; store shift in e.
       and 7               ; only want high byte bits.
       ld d,a              ; store in d.
       ld a,e              ; restore shifted value.
       and 248             ; only want low byte bits.
       ld e,a              ; that's the low byte.
       ld hl,font-256      ; address of charset.
       add hl,de           ; point to character.
       call gprad          ; get screen address in de.
       ex de,hl            ; screen address in hl, font in de.

       ld b,8              ; height.
ptxt0  push bc             ; store row counter.

       ld bc,(inkmsk)      ; get ink and paper colours.
       ld a,(dispy)        ; get y coordinate.
       rra                 ; odd or even alignment?
       ld a,(de)           ; get byte of image.
       push de             ; store pointer to font data.
       jr c,ptxt2          ; odd alignment.
       call ptxte          ; print at even cell position.
       jp ptxt1
ptxt2  call ptxto          ; print at odd cell position.
ptxt1  dec hl              ; back to left edge of character.
       dec hl
       call nline2         ; down one line.

       pop de              ; restore text image address.
       inc de              ; next byte.
       pop bc              ; retrieve row counter.
       djnz ptxt0          ; repeat for all rows.
       ret
ptxta  call ptxt           ; show character in accumulator.
       ld hl,dispy         ; y coordinate.
       inc (hl)            ; move along one.
       res 5,(hl)          ; don't spill over line.
       ret


; Print big text, stretched to 5x16 pixels.

btxt   rlca                ; multiply char by 8.
       rlca
       rlca
       ld e,a              ; store shift in e.
       and 7               ; only want high byte bits.
       ld d,a              ; store in d.
       ld a,e              ; restore shifted value.
       and 248             ; only want low byte bits.
       ld e,a              ; that's the low byte.
       ld hl,font-256      ; address of charset.
       add hl,de           ; point to character.
       call gprad          ; get screen address in de.
       ex de,hl            ; screen address in hl, font in de.

       ld b,8              ; pixel rows.
btxt0  push bc             ; store row counter.
       ld b,2              ; vertical stretch factor.
btxt3  push bc             ; store row counter.

       ld bc,(inkmsk)      ; get ink and paper colours.
       ld a,(dispy)        ; get y coordinate.
       rra                 ; odd or even alignment?
       ld a,(de)           ; get byte of image.
       push de             ; store pointer to font data.
       jr c,btxt2          ; odd alignment.
       call ptxte          ; print at even cell position.
       jp btxt1
btxt2  call ptxto          ; print at odd cell position.
btxt1  dec hl              ; back to left edge of character.
       dec hl
       call nline2         ; down one line.

       pop de              ; restore text image address.
       pop bc              ; retrieve stretch counter.
       djnz btxt3          ; repeat for all rows.
       inc de              ; next byte.
       pop bc              ; retrieve row counter.
       djnz btxt0          ; repeat for all rows.
bchr1  call nexpos         ; display position.
       jp nz,bchr2         ; not on a new line.
bchr3  inc (hl)            ; newline.
       call nexlin         ; next line check.
bchr2  jp dscor2           ; tidy up line and column variables.


; Print text at even cell.

ptxto  rla                 ; test bit.
       ld d,a              ; store font data.
       ld a,(hl)           ; get screen data.
       jr c,ptxto8         ; it was set.
       and 170             ; preserve left pixels.
       ld e,a              ; store in e.
       ld a,b              ; paper colour.
       jr ptxto9
ptxto8 and 170             ; preserve left pixels.
       ld e,a              ; store in e.
       ld a,c              ; ink colour.
ptxto9 and 85              ; right bits only.
       or e                ; merge with screen.
       ld (hl),a           ; write first bit.
       inc hl              ; next two pixels.
       ld a,d              ; get data again.
       rla                 ; test bit.
       jr c,ptxto0         ; it was set.
       ld (hl),b           ; set paper.
       jr ptxto1
ptxto0 ld (hl),c           ; set to ink.
ptxto1 rla                 ; test bit.
       ld d,a              ; store data.
       jr c,ptxto2         ; it was set.
       ld a,b              ; paper colour.
       jr ptxto3
ptxto2 ld a,c              ; ink colour.
ptxto3 and 85              ; right bits.
       ld e,a              ; store in e.
       ld a,(hl)           ; get screen colours.
       and 170             ; left bits only.
       or e                ; merge with right bits.
       ld (hl),a           ; write to screen.
       ld a,d              ; get bit of image data again.
       inc hl              ; next two pixels.
       ld a,d              ; get data again.
       rla                 ; test bit.
       jr c,ptxto4         ; it was set.
       ld (hl),b           ; set paper.
       jr ptxto5
ptxto4 ld (hl),c           ; set to ink.
ptxto5 rla                 ; test bit.
       ld d,a              ; store data.
       jr c,ptxto6         ; it was set.
       ld a,b              ; paper colour.
       jr ptxto7
ptxto6 ld a,c              ; ink colour.
ptxto7 and 85              ; right bits.
       ld e,a              ; store in e.
       ld a,(hl)           ; get screen colours.
       and 170             ; left bits only.
       or e                ; merge with right bits.
       ld (hl),a           ; write to screen.
       ret

; Print text at even cell.

ptxte  rla                 ; test bit.
       jr c,ptxte0         ; it was set.
       ld (hl),b           ; set paper.
       jr ptxte1
ptxte0 ld (hl),c           ; set to ink.
ptxte1 rla                 ; test bit.
       ld d,a              ; store data.
       jr c,ptxte2         ; it was set.
       ld a,b              ; paper colour.
       jr ptxte3
ptxte2 ld a,c              ; ink colour.
ptxte3 and 85              ; right bits.
       ld e,a              ; store in e.
       ld a,(hl)           ; get screen colours.
       and 170             ; left bits only.
       or e                ; merge with right bits.
       ld (hl),a           ; write to screen.
       ld a,d              ; get bit of image data again.
       inc hl              ; next screen address.
       rla                 ; test bit.
       jr c,ptxte4         ; it was set.
       ld (hl),b           ; set paper.
       jr ptxte5
ptxte4 ld (hl),c           ; set to ink.
ptxte5 rla                 ; test bit.
       ld d,a              ; store data.
       jr c,ptxte6         ; it was set.
       ld a,b              ; paper colour.
       jr ptxte7
ptxte6 ld a,c              ; ink colour.
ptxte7 and 85              ; right bits.
       ld e,a              ; store in e.
       ld a,(hl)           ; get screen colours.
       and 170             ; left bits only.
       or e                ; merge with right bits.
       ld (hl),a           ; write to screen.
       ld a,d              ; get bit of image data again.
       inc hl              ; next screen address.
       rla                 ; test bit.
       ld a,(hl)           ; get screen data.
       jr c,ptxte8         ; it was set.
       and 85              ; preserve right pixels.
       ld e,a              ; store in e.
       ld a,b              ; paper colour.
       jr ptxte9
ptxte8 and 85              ; preserve right pixels.
       ld e,a              ; store in e.
       ld a,c              ; ink colour.
ptxte9 and 170             ; left bits only.
       or e                ; merge with screen.
       ld (hl),a           ; write final bit.
       ret


; Sprite routine for objects, only appears at even pixel positions.

sprite push hl             ; store sprite graphic address.
       call scadd          ; get screen address in hl.
       pop de              ; restore graphic address in de pair.
       ld b,16             ; pixel height.
sprit1 push bc             ; store row counter.
       ld b,4              ; pixel width.
sprit0 ld a,(de)           ; fetch graphic data.
       xor (hl)            ; merge with what's on screen.
       ld (hl),a           ; bung it onto the screen.
       inc de              ; point to next piece of image.
       inc l               ; next screen address.
       djnz sprit0         ; repeat for all columns.
       call nline          ; next line down.
       pop bc              ; restore row counter.
       djnz sprit1         ; repeat for all rows.
       ret

; Get room address.

groom  ld a,(scno)         ; screen number.
groomx ld de,0             ; start at zero.
       ld hl,(scrptr)      ; pointer to screens.
       and a               ; is it the first one?
groom1 jr z,groom0         ; no more screens to skip.
       ld c,(hl)           ; low byte of screen size.
       inc hl              ; point to high byte.
       ld b,(hl)           ; high byte of screen size.
       inc hl              ; next address.
       ex de,hl            ; put total in hl, pointer in de.
       add hl,bc           ; skip a screen.
       ex de,hl            ; put total in de, pointer in hl.
       dec a               ; one less iteration.
       jr groom1           ; loop until we reach the end.
groom0 ld hl,(scrptr)      ; pointer to screens.
       add hl,de           ; add displacement.
       ld a,(numsc)        ; number of screens.
       ld d,0              ; zeroise high byte.
       ld e,a              ; displacement in de.
       add hl,de           ; add double displacement to address.
       add hl,de
       ret

; Draw present room.

droom  ld a,(wintop)       ; window top.
       ld (dispx),a        ; set x coordinate.
droom2 call groom          ; get address of current room.
       xor a               ; zero in accumulator.
       ld (comcnt),a       ; reset compression counter.
       ld a,(winhgt)       ; height of window.
droom0 push af             ; store row counter.
       ld a,(winlft)       ; window left edge.
       ld (dispy),a        ; set cursor position.
       ld a,(winwid)       ; width of window.
droom1 push af             ; store column counter.
       call flbyt          ; decompress next byte on the fly.
       push hl             ; store address of cell.
       call pattr          ; show attributes and block.
       pop hl              ; restore cell address.
       pop af              ; restore loop counter.
       dec a               ; one less column.
       jr nz,droom1        ; repeat for entire line.
       ld a,(dispx)        ; x coord.
       inc a               ; move down one line.
       ld (dispx),a        ; set new position.
       pop af              ; restore row counter.
       dec a               ; one less row.
       jr nz,droom0        ; repeat for all rows.
       ret

; Decompress bytes on-the-fly.

flbyt  ld a,(comcnt)       ; compression counter.
       and a               ; any more to decompress?
       jr nz,flbyt1        ; yes.
       ld a,(hl)           ; fetch next byte.
       inc hl              ; point to next cell.
       cp 255              ; is this byte a control code?
       ret nz              ; no, this byte is uncompressed.
       ld a,(hl)           ; fetch byte type.
       ld (combyt),a       ; set up the type.
       inc hl              ; point to quantity.
       ld a,(hl)           ; get quantity.
       inc hl              ; point to next byte.
flbyt1 dec a               ; one less.
       ld (comcnt),a       ; store new quantity.
       ld a,(combyt)       ; byte to expand.
       ret

combyt defb 0              ; byte type compressed.
comcnt defb 0              ; compression counter.

; Ladder down check.

laddd  ld a,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       add a,16            ; look down 16 pixels.
       ld l,a              ; coords in hl.
       jr laddv

; Ladder up check.

laddu  ld a,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       add a,14            ; look 2 pixels above feet.
       ld l,a              ; coords in hl.
laddv  ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       call ldchk          ; standard ladder check.
       ret nz              ; no way through.
       inc hl              ; look right one cell.
       call ldchk          ; do the check.
       ret nz              ; impassable.
       ld a,(dispy)        ; y coordinate.
       call rem5           ; position straddling block cells.
       ret z               ; no more checks needed.
       dec a               ; one pixel to right?
       ret z               ; no more checks needed.
       inc hl              ; look to third cell.
       call ldchk          ; do the check.
       ret                 ; return with zero flag set accordingly.

; Can go up check.

cangu  ld a,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       sub 2               ; look up 2 pixels.
       ld l,a              ; coords in hl.
       ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       call lrchk          ; standard left/right check.
       ret nz              ; no way through.
       inc hl              ; look right one cell.
       call lrchk          ; do the check.
       ret nz              ; impassable.
       ld a,(dispy)        ; y coordinate.
       call rem5           ; position straddling block cells.
       ret z               ; no more checks needed.
       dec a               ; one pixel to right?
       ret z               ; no more checks needed.
       inc hl              ; look to third cell.
       call lrchk          ; do the check.
       ret                 ; return with zero flag set accordingly.

; Can go down check.

cangd  ld a,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       add a,16            ; look down 16 pixels.
       ld l,a              ; coords in hl.
       ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       call plchk          ; block, platform check.
       ret nz              ; no way through.
       inc hl              ; look right one cell.
       call plchk          ; block, platform check.
       ret nz              ; impassable.
       ld a,(dispy)        ; y coordinate.
       call rem5           ; position straddling block cells.
       ret z               ; no more checks needed.
       dec a               ; one pixel to right?
       ret z               ; no more checks needed.
       inc hl              ; look to third cell.
       call plchk          ; block, platform check.
       ret                 ; return with zero flag set accordingly.

; Can go left check.

cangl  ld l,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       dec h               ; look left 1 pixel.
       jr cangh            ; test if we can go there.

; Can go right check.

cangr  ld l,(ix+8)         ; x coordinate.
       ld a,(ix+9)         ; y coordinate.
       add a,9             ; look right 9 pixels.
       ld h,a              ; coords in hl.

cangh  ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       call lrchk          ; standard left/right check.
       ret nz              ; no way through.
       ld de,32            ; distance to next cell.
       add hl,de           ; look down.
       call lrchk          ; do the check.
       ret nz              ; impassable.
       ld a,(dispx)        ; x coordinate.
       and 7               ; position straddling block cells.
       ret z               ; no more checks needed.
       add hl,de           ; look down to third cell.
       call lrchk          ; do the check.
       ret                 ; return with zero flag set accordingly.

; Check left/right movement is okay.

lrchk  ld a,(hl)           ; fetch map cell.
       cp WALL             ; is it passable?
       jr z,lrchkx         ; no.
       cp FODDER           ; fodder has to be dug.
       jr z,lrchkx         ; not passable.
always xor a               ; report it as okay.
       ret
lrchkx xor a               ; reset all bits.
       inc a
       ret

; Check platform or solid item is not in way.

plchk  ld a,(hl)           ; fetch map cell.
       cp WALL             ; is it passable?
       jr z,lrchkx         ; no.
       cp FODDER           ; fodder has to be dug.
       jr z,lrchkx         ; not passable.
       cp PLATFM           ; platform is solid.
       jr z,plchkx         ; not passable.
       cp LADDER           ; is it a ladder?
       jr z,lrchkx         ; on ladder, deny movement.
plchk0 xor a               ; report it as okay.
       ret
plchkx ld a,(dispx)        ; x coordinate.
       and 7               ; position straddling blocks.
       jr z,lrchkx         ; on platform, deny movement.
       jr plchk0

; Check ladder is available.

ldchk  ld a,(hl)           ; fetch cell.
       cp LADDER           ; is it a ladder?
       ret                 ; return with zero flag set accordingly.

; Touched deadly block check.
; Returns with DEADLY (must be non-zero) in accumulator if true.

tded   ld l,(ix+8)         ; x coordinate.
       ld h,(ix+9)         ; y coordinate.
       ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       ld de,31            ; default distance to next line down.
       cp b                ; is this the required block?
       ret z               ; yes.
       inc hl              ; next cell.
       ld a,(hl)           ; fetch type.
       cp b                ; is this deadly/custom?
       ret z               ; yes.
       ld a,(dispy)        ; horizontal position.
       ld c,a              ; store column in c register.
       call rem5           ; is it straddling cells?
       jr z,tded0          ; no.
       dec a               ; one pixel to right?
       jr z,tded0          ; no more checks needed.
       inc hl              ; last cell.
       ld a,(hl)           ; fetch type.
       cp b                ; is this the block?
       ret z               ; yes.
       dec de              ; one less cell to next row down.
tded0  add hl,de           ; point to next row.
       ld a,(hl)           ; fetch left cell block.
       cp b                ; is this fatal?
       ret z               ; yes.
       inc hl              ; next cell.
       ld a,(hl)           ; fetch type.
       cp b                ; is this fatal?
       ret z               ; yes.
       ld a,c              ; horizontal position.
       call rem5           ; is it straddling cells?
       jr z,tded1          ; no.
       dec a               ; one pixel to right?
       jr z,tded1          ; no more checks needed.
       inc hl              ; last cell.
       ld a,(hl)           ; fetch type.
       cp b                ; is this fatal?
       ret z               ; yes.
tded1  ld a,(dispx)        ; vertical position.
       and 7               ; is it straddling cells?
       ret z               ; no, job done.
       add hl,de           ; point to next row.
       ld a,(hl)           ; fetch left cell block.
       cp b                ; is this fatal?
       ret z               ; yes.
       inc hl              ; next cell.
       ld a,(hl)           ; fetch type.
       cp b                ; is this fatal?
       ret z               ; yes.
       ld a,c              ; horizontal position.
       call rem5           ; is it straddling cells?
       ret z               ; no.
       dec a               ; one pixel to right?
       ret z               ; no more checks needed.
       inc hl              ; last cell.
       ld a,(hl)           ; fetch final type.
       ret                 ; return with final type in accumulator.


; Fetch block type at (dispx, dispy).

tstbl  ld a,(dispx)        ; fetch x coord.
       rlca                ; divide by 8,
       rlca                ; and multiply by 32.
       ld d,a              ; store in d.
       and 224             ; mask off high bits.
       ld e,a              ; low byte.
       ld a,d              ; restore shift result.
       and 3               ; high bits.
       ld d,a              ; got displacement in de.
       ld a,(dispy)        ; y coord.
       call div5           ; divide by 5.
       add a,e             ; add to displacement.
       ld e,a              ; displacement in de.
       ld hl,MAP           ; position of dummy screen.
       add hl,de           ; point to address.
       ld a,(hl)           ; fetch byte there.
       ret

; Divide y coordinate by 5 to give block position.

div5   push bc             ; store bc.
       ld b,0              ; reset result.
       cp 80               ; more than 80?
       jr c,div5a          ; no.
       sub 80              ; subtract 80.
       set 4,b             ; set bit for 16.
div5a  cp 40               ; more than 40?
       jr c,div5b          ; no.
       sub 40              ; subtract 40.
       set 3,b             ; set bit for 8.
div5b  cp 20               ; more than 20?
       jr c,div5c          ; no.
       sub 20              ; subtract 20.
       set 2,b             ; set bit for 4.
div5c  cp 10               ; more than 10?
       jr c,div5d          ; no.
       sub 10              ; subtract 10.
       set 1,b             ; set bit for 2.
div5d  cp 5                ; more than 5?
       jr c,div5e          ; no.
       inc b               ; set bit for 1.
div5e  ld a,b              ; get result.
       pop bc              ; restore bc.
       ret

; Find remainder when coordinate divided by 5 to establish block alignment.

rem5   cp 80               ; is coordinate more than 80?
       jr c,rem5a          ; no.
       sub 80              ; subtract amount.
rem5a  cp 40               ; is coordinate more than 40?
       jr c,rem5b          ; no.
       sub 40              ; subtract amount.
rem5b  cp 20               ; is coordinate more than 20?
       jr c,rem5c          ; no.
       sub 20              ; subtract amount.
rem5c  cp 10               ; is coordinate more than 10?
       jr c,rem5d          ; no.
       sub 10              ; subtract amount.
rem5d  cp 5                ; is coordinate more than 5?
       jr c,rem5e          ; no.
       sub 5               ; subtract amount.
rem5e  and a               ; remainder in accumulator, set zero flag accordingly.
       ret


; Jump - if we can.
; Requires initial speed to be set up in accumulator prior to call.

jump   neg                 ; switch sign so we jump up.
       ld c,a              ; store in c register.
;       ld a,(ix+8)         ; x coordinate.
;       ld h,(ix+9)         ; y coordinate.
;numsp4 add a,16            ; look down 16 pixels.
;       ld l,a              ; coords in hl.
;       and 7               ; are we on platform boundary?
;       ret nz              ; no, cannot jump.
;       ld (dispx),hl       ; set up test coordinates.
;       ld b,a              ; copy to b register.
;       call tstbl          ; get map address.
;       call plchk          ; block, platform check.
;       jr nz,jump0         ; it's solid, we can jump.
;       inc hl              ; look right one cell.
;       call plchk          ; block, platform check.
;       jr nz,jump0         ; it's solid, we can jump.
;       ld a,b              ; y coordinate.
;       call rem5           ; position straddling block cells.
;       ret z               ; no more checks needed.
;       inc hl              ; look to third cell.
;       call plchk          ; block, platform check.
;       ret z               ; not solid, don't jump.
jump0  ld a,(ix+13)        ; jumping flag.
       and a               ; is it set?
       ret nz              ; already in the air.
       inc (ix+13)         ; set it.
       ld (ix+14),c        ; set jump height.
       ret

hop    ld a,(ix+13)        ; jumping flag.
       and a               ; is it set?
       ret nz              ; already in the air.
       ld (ix+13),255      ; set it.
       ld (ix+14),0        ; set jump table displacement.
       ret


; Random numbers code.
; Pseudo-random number generator, 8-bit.
; Steps a pointer through the code (held in seed), returning the contents
; of the byte at that location.

ranini ld hl,start         ; start of code should be random enough.
       jr rand0
random ld hl,(seed)        ; pointer to ROM.
       inc hl              ; increment pointer.
rand0  ld de,lstrnd        ; last random area address.
       ld (seed),hl        ; new position.
       sbc hl,de           ; do comparison.
       jr nc,ranini        ; reinitialise random number.
       ld a,(seed2)        ; previous seed.
       add a,(hl)          ; combine with number from location.
       ld (seed2),a        ; second seed.
       xor l               ; more randomness.
       and b               ; use mask.
       cp c                ; is it less than parameter?
       ld (varrnd),a       ; set random number.
       ret c               ; yes, number is good.
       jp random           ; go round again.

; Joystick and keyboard reading routines.

keys   defb 59,65,32,33,38,71,44   ; game keys.
       defb 64,65,57,56            ; menu options 1 - 4.

; General keyboard test routine used by compiler.

ktest  call 47902          ; check if keycode is pressed.
       jr nz,ktest0        ; pressed, reset carry.
       scf                 ; set carry.
       ret
ktest0 and a               ; clear carry flag.
       ret

; Joystick states:
; 1 - up.
; 2 - down.
; 4 - left.
; 8 - right.
; 16 - fire 2.
; 32 - fire 1.

joykey call 47908          ; get joystick states in hl.
       ld a,(contrl)       ; controls.
       and a               ; keyboard?
       jp z,keyb           ; read keys.
       dec a               ; joystick zero?
       jr z,joy0           ; just want joystick 0.
       ld h,l              ; copy joystick 1 to joystick 0.
joy0   ld a,h              ; value of joystick 0.
       ld (joyval),a       ; remember value.
       ret
keyb   ld b,0              ; default value.
       ld a,(keys+4)       ; fire 1.
       call keybck         ; check if pressed.
       sla b               ; shift result byte.
       ld a,(keys+5)       ; fire 2.
       call keybck         ; check if pressed.
       sla b               ; shift result byte.
       ld a,(keys+3)       ; right.
       call keybck         ; check if pressed.
       sla b               ; shift result byte.
       ld a,(keys+2)       ; left.
       call keybck         ; check if pressed.
       sla b               ; shift result byte.
       ld a,(keys+1)       ; down.
       call keybck         ; check if pressed.
       sla b               ; shift result byte.
       ld a,(keys)         ; up.
       call keybck         ; check if pressed.
       ld a,b              ; put result in accumulator.
       ld (joyval),a       ; set the joystick reading.
       ret
keybck call 47902          ; check if key pressed.
       ret z               ; not pressed.
       inc b               ; set bit to say pressed.
       ret


; Display message.

dmsg   ld hl,msgdat        ; pointer to messages.
       call getwrd         ; get message number.
dmsg3  call preprt         ; pre-printing stuff.
       call checkx         ; make sure we're in a printable range.
       ld a,(prtmod)       ; print mode.
       and a               ; standard size?
       jp nz,bmsg1         ; no, double-height text.
dmsg0  push hl             ; store string pointer.
       ld a,(hl)           ; fetch byte to display.
       and 127             ; remove any end marker.
       cp 13               ; newline character?
       jr z,dmsg1
       call ptxt           ; display character.
       call nexpos         ; display position.
       jr nz,dmsg2         ; not on a new line.
       call nexlin         ; next line down.
dmsg2  pop hl
       ld a,(hl)           ; fetch last character.
       rla                 ; was it the end?
       jp c,dscor2         ; yes, job done.
       inc hl              ; next character to display.
       jr dmsg0
dmsg1  ld hl,dispx         ; x coordinate.
       inc (hl)            ; newline.
       ld a,(hl)           ; fetch position.
       cp 25               ; past screen edge?
       jr c,dmsg4          ; no, it's okay.
       ld (hl),0           ; restart at top.
dmsg4  inc hl              ; y coordinate.
       ld (hl),0           ; carriage return.
       jr dmsg2
prtmod defb 0              ; print mode, 0 = standard, 1 = double-height.

; Display message in big text.

bmsg1  ld a,(hl)           ; get character to display.
       push hl             ; store pointer to message.
       and 127             ; only want 7 bits.
       cp 13               ; newline character?
       jr z,bmsg2          ; newline instead.
       call btxt           ; display big char.
bmsg3  pop hl              ; retrieve message pointer.
       ld a,(hl)           ; look at last character.
       inc hl              ; next character in list.
       rla                 ; was terminator flag set?
       jr nc,bmsg1         ; no, keep going.
       ret
bmsg2  ld hl,charx         ; x coordinate.
       inc (hl)            ; newline.
       inc (hl)            ; newline.
       ld a,(hl)           ; fetch position.
       cp 24               ; past screen edge?
       jr c,bmsg3          ; no, it's okay.
       ld (hl),0           ; restart at top.
       inc hl              ; y coordinate.
       ld (hl),0           ; carriage return.
       jr bmsg3

; Display a character.

achar  ld b,a              ; copy to b.
       call preprt         ; get ready to print.
       ld a,(prtmod)       ; print mode.
       and a               ; standard size?
       ld a,b              ; character in accumulator.
       jp nz,btxt          ; no, double-height text.
       call ptxt           ; display character.
       call nexpos         ; display position.
       jp z,btxt3          ; next line down.
       jp btxt2            ; tidy up.

; Get next print column position.

nexpos ld hl,dispy         ; display position.
       ld a,(hl)           ; get coordinate.
       inc a               ; move along one position.
       and 31              ; reached edge of screen?
       ld (hl),a           ; set new position.
       dec hl              ; point to x now.
       ret                 ; return with status in zero flag.

; Get next print line position.

nexlin inc (hl)            ; newline.
       ld a,(hl)           ; vertical position.
       cp 24               ; past screen edge?
       ret c               ; no, still okay.
       ld (hl),0           ; restart at top.
       ret

; Pre-print preliminaries.

preprt ld de,(charx)       ; display coordinates.
       ld (dispx),de       ; set up general coordinates.
       ret

; On entry  hl points to word list
;           a contains word number.

getwrd and a               ; first word in list?
       ret z               ; yep, don't search.
       ld b,a
getwd0 ld a,(hl)
       inc hl
       cp 128              ; found end?
       jr c,getwd0         ; no, carry on.
       djnz getwd0         ; until we have right number.
       ret


; Bubble sort.

bsort  ld b,NUMSPR - 1     ; sprites to swap.
       ld ix,sprtab        ; sprite table.
bsort0 push bc             ; store loop counter for now.

       ld a,(ix+0)         ; first sprite type.
       inc a               ; is it switched off?
       jr z,swemp          ; yes, may need to switch another in here.

       ld a,(ix+TABSIZ)    ; check next slot exists.
       inc a               ; is it enabled?
       jr z,bsort2         ; no, nothing to swap.

       ld a,(ix+3+TABSIZ)  ; fetch next sprite's coordinate.
       cp (ix+3)           ; compare with this x coordinate.
       jr c,bsort1         ; next sprite is higher - may need to switch.
bsort2 ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       pop bc              ; retrieve loop counter.
       djnz bsort0         ; repeat for remaining sprites.
       ret

bsort1 ld a,(ix+TABSIZ)    ; sprite on/off flag.
       inc a               ; is it enabled?
       jr z,bsort2         ; no, nothing to swap.
       call swspr          ; swap positions.
       jr bsort2

swemp  ld a,(ix+TABSIZ)    ; next table entry.
       inc a               ; is that one on?
       jr z,bsort2         ; no, nothing to swap.
       call swspr          ; swap positions.
       jr bsort2

; Swap sprites.

swspr  push ix             ; table address on stack.
       pop hl              ; pop into hl pair.
       ld d,h              ; copy to de pair.
       ld e,l
       ld bc,TABSIZ        ; distance to second entry.
       add hl,bc           ; point to second sprite entry.
       ld b,TABSIZ         ; bytes to swap.
swspr0 ld c,(hl)           ; fetch second byte.
       ld a,(de)           ; fetch first byte.
       ld (hl),a           ; copy to second.
       ld a,c              ; second byte in accumulator.
       ld (de),a           ; copy to first sprite entry.
       inc de              ; next byte.
       inc hl              ; next byte.
       djnz swspr0         ; swap all bytes in table entry.
       ret


; Process sprites.

pspr   ld b,NUMSPR         ; sprites to process.
       ld ix,sprtab        ; sprite table.
pspr1  push bc             ; store loop counter for now.
       ld a,(ix+0)         ; fetch sprite type.
       cp 9                ; within range of sprite types?
       call c,pspr2        ; yes, process this one.
       ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       pop bc              ; retrieve loop counter.
       djnz pspr1          ; repeat for remaining sprites.
       ret
pspr2  ld (ogptr),ix       ; store original sprite pointer.
       call pspr3          ; do the routine.
rtorg  ld ix,(ogptr)       ; restore original pointer to sprite.
rtorg0 ret
pspr3  ld hl,evtyp0        ; sprite type events list.
pspr4  add a,a             ; double accumulator.
       ld e,a              ; copy to de.
       ld d,0              ; no high byte.
       add hl,de           ; point to address of routine.
       ld e,(hl)           ; address low.
       inc hl              ; next byte of address.
       ld d,(hl)           ; address high.
       ex de,hl            ; swap address into hl.
       jp (hl)             ; go there.
ogptr  defw 0              ; original sprite pointer.

; Address of each sprite type's routine.

evtyp0 defw evnt00
evtyp1 defw evnt01
evtyp2 defw evnt02
evtyp3 defw evnt03
evtyp4 defw evnt04
evtyp5 defw evnt05
evtyp6 defw evnt06
evtyp7 defw evnt07
evtyp8 defw evnt08


; Display sprites.

dspr   ld b,NUMSPR/2       ; number of sprites to display.
dspr0  push bc             ; store loop counter for now.
       ld a,(ix+0)         ; get sprite type.
       inc a               ; is it enabled?
       jr nz,dspr1         ; yes, it needs deleting.
dspr5  ld a,(ix+5)         ; new type.
       inc a               ; is it enabled?
       jr nz,dspr3         ; yes, it needs drawing.

dspr2  push ix             ; put ix on stack.
       pop hl              ; pop into hl.
       ld e,l              ; copy to de.
       ld d,h

;dspr2  ld e,ixl            ; copy ix to de.
;       ld d,ixh
;       ld l,e              ; copy to hl.
;       ld h,d
       ld bc,5             ; distance to new type.
       add hl,bc           ; point to new properties.
       ldi                 ; copy to old positions.
       ldi
       ldi
       ldi
       ldi
       ld c,TABSIZ*2       ; distance to next odd/even entry.
       add ix,bc           ; next sprite.
       pop bc              ; retrieve loop counter.
       djnz dspr0          ; repeat for remaining sprites.
       ret
;dspr1  ld a,(ix+3)         ; old x coord.
;       cp 177              ; beyond maximum?
;       jr nc,dspr5         ; yes, don't delete it.
dspr1  ld a,(ix+3)         ; old x coord.
       cp 185              ; beyond maximum?
       jr nc,dspr5         ; yes, don't delete it.
       ld a,(ix+5)         ; type of new sprite.
       inc a               ; is this enabled?
       jr nz,dspr4         ; yes, display both.
dspr6  call sspria         ; show single sprite.
       jp dspr2
dspr4  ld a,(ix+8)         ; new x coord.
       cp 185              ; beyond maximum?
       jr nc,dspr6         ; yes, don't display it.

; Displaying two sprites.  Don't bother redrawing if nothing has changed.

       ld a,(ix+4)         ; old y.
       cp (ix+9)           ; compare with new value.
       jr nz,dspr7         ; they differ, need to redraw.
       ld a,(ix+3)         ; old x.
       cp (ix+8)           ; compare against new value.
       jr nz,dspr7         ; they differ, need to redraw.
       ld a,(ix+2)         ; old frame.
       cp (ix+7)           ; compare against new value.
       jr nz,dspr7         ; they differ, need to redraw.
       ld a,(ix+1)         ; old image.
       cp (ix+6)           ; compare against new value.
       jp z,dspr2          ; everything is the same, don't redraw.
dspr7  call sspric         ; delete old sprite, draw new one simultaneously.
       jp dspr2
dspr3  ld a,(ix+8)         ; new x coord.
       cp 185              ; beyond maximum?
       jr nc,dspr2         ; yes, don't display it.
       call ssprib         ; show single sprite.
       jp dspr2


; Get sprite address calculations.
; gspran = new sprite, gsprad = old sprite.

gspran ld l,(ix+8)         ; new x coordinate.
       ld h,(ix+9)         ; new y coordinate.
       ld (dispx),hl       ; set display coordinates.
       ld a,l              ; x coordinate.
       cp 185              ; beyond maximum?
       ret nc              ; yes, don't display it.

       ld a,(ix+6)         ; new sprite image.
       call gfrm           ; fetch start frame for this sprite.
       ld a,(hl)           ; frame in accumulator.
       add a,(ix+7)        ; new add frame number.
       jp gspra0

gsprad ld l,(ix+3)         ; x coordinate.
       ld h,(ix+4)         ; y coordinate.
       ld (dispx),hl       ; set display coordinates.
       ld a,l              ; x coordinate.
       cp 185              ; beyond lowest point on screen?
       ret nc              ; yes, don't display it.

       ld a,(ix+1)         ; sprite image.
       call gfrm           ; fetch start frame for this sprite.
       ld a,(hl)           ; frame in accumulator.
       add a,(ix+2)        ; add frame number.
gspra0 rrca                ; multiply by 32.
       rrca
       rrca
       ld d,a              ; store in d.
       and 224             ; low byte bits.
       ld e,a              ; got low byte.
       ld a,d              ; restore result.
       and 31              ; high byte bits.
       ld d,a              ; displacement high byte.
       ld hl,sprgfx        ; address of play sprites.
       add hl,de           ; frame * 32.
       add hl,de           ; frame * 64.
       add hl,de           ; frame * 96.
       add hl,de           ; frame * 128.
       add hl,de           ; frame * 160.

       ld a,(dispy)        ; y coordinate.
       rra                 ; test odd pixel number.
       jr nc,gspra1        ; it's even, this address is good.

       ld de,80            ; displacement to second frame.
       add hl,de           ; add to sprite address.
gspra1 ex de,hl            ; need it in de for now.

; Drop into screen address routine.
; This routine returns a mode 0 screen address for (dispx, dispy) in hl.

scadd  ld a,(dispx)        ; x position.
       and 248             ; get character row (multiple of 8), only 25 so only need 5 bits.
       ld l,a              ; copy to hl.
       ld h,0
       add hl,hl           ; * 16.
       ld b,h              ; copy to bc.
       ld c,l              ; bc = * 16.
       add hl,hl           ; * 32.
       add hl,hl           ; * 64.
       add hl,bc           ; * 80.

; Done character row, now work out pixel position.

       ld a,(dispx)        ; restore x position.
       and 7               ; line 0-7 within character square.
       rlca                ; multiply by 2048.
       rlca
       rlca
       add a,h             ; add to high byte.
       add a,192           ; add base address of screen.
       ld h,a              ; store in high byte.
       ld a,(dispy)        ; y coordinate.
       rra                 ; divide by 2, carry already cleared.
       ld c,a              ; low byte.
       ld b,0              ; no high byte.
       add hl,bc           ; add to address.
       ret

; These are the sprite routines.
; sspria = single sprite, old (ix).
; ssprib = single sprite, new (ix+5).
; sspric = both sprites, old (ix) and new (ix+5).

sspria call gsprad         ; get old sprite address.
sspri2 ld a,16             ; vertical lines.
sspri0 push af             ; store line counter on stack.
       call dline          ; draw a line.
       pop af              ; restore line counter.
       dec a               ; one less to go.
       jp nz,sspri0
       ret

ssprib call gspran         ; get new sprite address.
       jp sspri2

sspric call gsprad         ; get old sprite address.
       ld (spad1),hl       ; store addresses.
       ld (spad2),de
       call gspran         ; get new sprite addresses.
       ld a,16             ; vertical lines.
sspri1 push af             ; store line counter.
       call dline          ; draw a line.
       ld (spad3),hl       ; store these addresses.
       ld (spad4),de
       ld hl,(spad1)       ; restore old addresses.
       ld de,(spad2)
       call dline          ; delete a line.
       ld (spad1),hl       ; store addresses.
       ld (spad2),de
       ld hl,(spad3)       ; flip to new sprite addresses.
       ld de,(spad4)
       pop af              ; restore line counter.
       dec a               ; one less to go.
       jp nz,sspri1
       ret

; Storage space for addresses.

spad1  defw 0
spad2  defw 0
spad3  defw 0
spad4  defw 0

dline  ld a,(de)           ; graphic data.
       xor (hl)            ; XOR with what's there.
       ld (hl),a           ; bung it in.
       inc de              ; next graphic.
       inc hl              ; next screen address.
       ld a,(de)           ; fetch data.
       xor (hl)            ; XOR with what's there.
       ld (hl),a           ; bung it in.
       inc de              ; next graphic.
       inc hl              ; next destination address.
       ld a,(de)           ; third bit of data.
       xor (hl)            ; XOR with what's there.
       ld (hl),a           ; bung it in.
       inc de              ; point to next piece of image.
       inc hl              ; next screen address.
       ld a,(de)           ; fetch fourth byte.
       xor (hl)            ; XOR with what's on screen.
       ld (hl),a           ; write it back.
       inc de              ; next graphic address.
       inc hl              ; next screen address.
       ld a,(de)           ; fetch last byte.
       xor (hl)            ; XOR with screen image.
       ld (hl),a           ; copy new image to screen.
       inc de              ; next graphic address.

; Line drawn, now work out next target address.

nline  ld bc,2044          ; distance to next pixel minus width.
       add hl,bc           ; point to new screen address.
       ld a,h              ; get pixel address.
       and 56              ; straddling character position?
       ret nz              ; no, address is okay.
       ld bc,49232         ; distance to next pixel.
;       ld bc,49216         ; distance to next pixel.
       add hl,bc           ; point to new screen address.
       ret

nline2 ld bc,2048          ; distance to next pixel minus width.
       add hl,bc           ; point to new screen address.
       ld a,h              ; get pixel address.
       and 56              ; straddling character position?
       ret nz              ; no, address is okay.
       ld bc,49232         ; distance to next pixel.
       add hl,bc           ; point to new screen address.
       ret


; Animates a sprite.

animsp ld hl,frmno         ; game frame.
       and (hl)            ; is it time to change the frame?
       ret nz              ; not this frame.
       ld a,(ix+6)         ; sprite image.
       call gfrm           ; get frame data.
       inc hl              ; point to frames.
       ld a,(ix+7)         ; sprite frame.
       inc a               ; next one along.
       cp (hl)             ; reached the last frame?
       jr c,anims0         ; no, not yet.
       xor a               ; start at first frame.
anims0 ld (ix+7),a         ; new frame.
       ret
animbk ld hl,frmno         ; game frame.
       and (hl)            ; is it time to change the frame?
       ret nz              ; not this frame.
       ld a,(ix+6)         ; sprite image.
       call gfrm           ; get frame data.
       inc hl              ; point to frames.
       ld a,(ix+7)         ; sprite frame.
       and a               ; first one?
       jr nz,rtanb0        ; yes, start at end.
       ld a,(hl)           ; last sprite.
rtanb0 dec a               ; next one along.
       jr anims0           ; set new frame.

; Check for collision with other sprite, strict enforcement.

sktyp  ld hl,sprtab        ; sprite table.
       ld c,NUMSPR         ; number of sprites.
sktyp0 ld (skptr),hl       ; store pointer to sprite.
       ld a,(hl)           ; get sprite type.
       cp b                ; is it the type we seek?
       jr z,coltyp         ; yes, we can use this one.
sktyp1 ld hl,(skptr)       ; retrieve sprite pointer.
       ld de,TABSIZ        ; size of each entry.
       add hl,de           ; point to next sprite in table.
       dec c               ; one iteration fewer.
       jp nz,sktyp0        ; keep going until we find a slot.
       ld hl,0             ; default to ROM address - no sprite.
       ld (skptr),hl       ; store pointer to sprite.
       or h                ; don't return with zero flag set.
       ret                 ; didn't find one.
skptr  defw 0              ; search pointer.

coltyp ld a,(ix+0)         ; current sprite type.
       cp b                ; seeking sprite of same type?
       jr z,colty1         ; yes, need to check we're not detecting ourselves.
colty0 ld de,X             ; distance to x position in table.
       add hl,de           ; point to coords.
       ld e,(hl)           ; fetch x coordinate.
       inc hl              ; now point to y.
       ld d,(hl)           ; that's y coordinate.

; Drop into collision detection.

colc16 ld a,(ix+X)         ; x coord.
       sub e               ; subtract x.
       jr nc,colc1a        ; result is positive.
       neg                 ; make negative positive.
colc1a cp 16               ; within x range?
       jr nc,sktyp1        ; no - they've missed.
       ld h,a              ; store difference.
       ld a,(ix+Y)         ; y coord.
       sub d               ; subtract y.
       jr nc,colc1b        ; result is positive.
       neg                 ; make negative positive.
colc1b cp 10               ; within y range?
       jr nc,sktyp1        ; no - they've missed.
       add a,h             ; add x difference.
       cp 21               ; only 4 corner pixels touching?
       ret c               ; carry set if there's a collision.
       jp sktyp1           ; try next sprite in table.

colty1 push ix             ; base sprite address onto stack.
       pop de              ; pop it into de.
       ex de,hl            ; flip hl into de.
       sbc hl,de           ; compare the two.
       ex de,hl            ; restore hl.
       jr z,sktyp1         ; addresses are identical.
       jp colty0

; Display number.

disply ld bc,displ0        ; display workspace.
       call num2ch         ; convert accumulator to string.
       dec bc              ; back one character.
       ld a,(bc)           ; fetch digit.
       or 128              ; insert end marker.
       ld (bc),a           ; new value.
       ld hl,displ0        ; display space.
       jp dmsg3            ; display the string.
displ0 defb 0,0,0,13+128


; Initialise screen.

initsc ld a,(roomtb)       ; whereabouts in the map are we?
       call tstsc          ; find displacement.
       cp 255              ; is it valid?
       ret z               ; no, it's rubbish.
       ld (scno),a         ; store new room number.
       ret

; Test screen.

tstsc  ld hl,mapdat-MAPWID ; start of map data, subtract width for negative.
       ld b,a              ; store room in b for now.
       add a,MAPWID        ; add width in case we're negative.
       ld e,a              ; screen into e.
       ld d,0              ; zeroise d.
       add hl,de           ; add displacement to map data.
       ld a,(hl)           ; find room number there.
       ret

; Screen left.

scrl   ld a,(roomtb)       ; present room table pointer.
       dec a               ; room left.
scrl0  call tstsc          ; test screen.
       inc a               ; is there a screen this way?
       ret z               ; no, return to loop.
       ld a,b              ; restore room displacement.
       ld (roomtb),a       ; new room table position.
scrl1  call initsc         ; set new screen.
       ld hl,restfl        ; restart screen flag.
       ld (hl),2           ; set it.
       ret
scrr   ld a,(roomtb)       ; room table pointer.
       inc a               ; room right.
       jr scrl0
scru   ld a,(roomtb)       ; room table pointer.
       sub MAPWID          ; room up.
       jr scrl0
scrd   ld a,(roomtb)       ; room table pointer.
       add a,MAPWID        ; room down.
       jr scrl0

; Jump to new screen.

nwscr  ld hl,mapdat        ; start of map data.
       ld bc,256*80        ; zero room count, 80 to search.
nwscr0 cp (hl)             ; have we found a match for screen?
       jr z,nwscr1         ; yes, set new point in map.
       inc hl              ; next room.
       inc c               ; count rooms.
       djnz nwscr0         ; keep looking.
       ret
nwscr1 ld a,c              ; room displacement.
       ld (roomtb),a       ; set the map position.
       jr scrl1            ; draw new room.


; Gravity processing.

grav   ld a,(ix+13)        ; in-air flag.
       and a               ; are we in the air?
       ret z               ; no we are not.
       inc a               ; increment it.
       jp z,ogrv           ; set to 255, use old gravity.
       ld (ix+13),a        ; write new setting.
       rra                 ; every other frame.
       jr nc,grav0         ; don't apply gravity this time.
       ld a,(ix+14)        ; pixels to move.
       cp 16               ; reached maximum?
       jr z,grav0          ; yes, continue.
       inc (ix+14)         ; slow down ascent/speed up fall.
grav0  ld a,(ix+14)        ; get distance to move.
       sra a               ; divide by 2.
       and a               ; any movement required?
       ret z               ; no, not this time.
       cp 128              ; is it up or down?
       jr nc,gravu         ; it's up.
gravd  ld b,a              ; set pixels to move.
gravd0 call cangd          ; can we go down?
       jr nz,gravst        ; can't move down, so stop.
       inc (ix+8)          ; adjust new x coord.
       djnz gravd0
       ret
gravu  neg                 ; flip the sign so it's positive.
       ld b,a              ; set pixels to move.
gravu0 call cangu          ; can we go up?
       jp nz,ifalls        ; can't move up, go down next.
       dec (ix+8)          ; adjust new x coord.
       djnz gravu0
       ret
gravst ld a,(ix+14)        ; jump pointer high.
       ld (ix+13),0        ; reset falling flag.
       ld (ix+14),0        ; store new speed.
       cp 8                ; was speed the maximum?
evftf  jp z,evnt15         ; yes, fallen too far.
       ret

; Old gravity processing for compatibility with Spectrum versions 4.6 and 4.7.

ogrv   ld e,(ix+14)        ; get index to table.
       ld d,0              ; no high byte.
       ld hl,jtab          ; jump table.
       add hl,de           ; hl points to jump value.
       ld a,(hl)           ; pixels to move.
       cp 99               ; reached the end?
       jr nz,ogrv0         ; no, continue.
       dec hl              ; go back to previous value.
       ld a,(hl)           ; fetch that from table.
       jr ogrv1
ogrv0  inc (ix+14)         ; point to next table entry.
ogrv1  and a               ; any movement required?
       ret z               ; no, not this time.
       cp 128              ; is it up or down?
       jr nc,ogrvu         ; it's up.
ogrvd  ld b,a              ; set pixels to move.
ogrvd0 call cangd          ; can we go down?
       jr nz,ogrvst        ; can't move down, so stop.
       inc (ix+8)          ; adjust new x coord.
       djnz ogrvd0
       ret
ogrvu  neg                 ; flip the sign so it's positive.
       ld b,a              ; set pixels to move.
ogrvu0 call cangu          ; can we go up?
       jr nz,ogrv2         ; can't move up, go down next.
       dec (ix+8)          ; adjust new x coord.
       djnz ogrvu0
       ret
ogrvst ld e,(ix+14)        ; get index to table.
       ld d,0              ; no high byte.
       ld hl,jtab          ; jump table.
       add hl,de           ; hl points to jump value.
       ld a,(hl)           ; fetch byte from table.
       cp 99               ; is it the end marker?
       ld (ix+13),0        ; reset jump flag.
       ld (ix+14),0        ; reset pointer.
       jp evftf
ogrv2  ld hl,jtab          ; jump table.
       ld b,0              ; offset into table.
ogrv4  ld a,(hl)           ; fetch table byte.
       cp 100              ; hit end or downward move?
       jr c,ogrv3          ; yes.
       inc hl              ; next byte of table.
       inc b               ; next offset.
       jr ogrv4            ; keep going until we find crest/end of table.
ogrv3  ld (ix+14),b        ; set next table offset.
       ret

; Initiate fall check.

ifall  ld a,(ix+13)        ; jump pointer flag.
       and a               ; are we in the air?
       ret nz              ; if set, we're already in the air.
       ld h,(ix+9)         ; y coordinate.
       ld a,16             ; look down 16 pixels.
       add a,(ix+8)        ; add x coordinate.
       ld l,a              ; coords in hl.
       ld (dispx),hl       ; set up test coordinates.
       call tstbl          ; get map address.
       call plchk          ; block, platform check.
       ret nz              ; it's solid, don't fall.
       inc hl              ; look right one cell.
       call plchk          ; block, platform check.
       ret nz              ; it's solid, don't fall.
       ld a,(dispy)        ; y coordinate.
       call rem5           ; position straddling block cells.
       jr z,ifalls         ; no more checks needed.
       inc hl              ; look to third cell.
       call plchk          ; block, platform check.
       ret nz              ; it's solid, don't fall.
ifalls inc (ix+13)         ; set in air flag.
       ld (ix+14),0        ; initial speed = 0.
       ret
tfall  ld a,(ix+13)        ; jump pointer flag.
       and a               ; are we in the air?
       ret nz              ; if set, we're already in the air.
       call ifall          ; do fall test.
       ld a,(ix+13)        ; get falling flag.
       and a               ; is it set?
       ret z               ; no.
       ld (ix+13),255      ; we're using the table.
       jr ogrv2            ; find position in table.


; Get frame data for a particular sprite.

gfrm   rlca                ; multiple of 2.
       ld e,a              ; copy to de.
       ld d,0              ; no high byte as max sprite is 128.
       ld hl,(frmptr)      ; frames used by game.
       add hl,de           ; point to frame start.
       ret

; Find sprite list for current room.

sprlst ld a,(scno)         ; screen number.
sprls2 ld hl,(nmeptr)      ; pointer to enemies.
       ld b,a              ; loop counter in b register.
       and a               ; is it the first screen?
       ret z               ; yes, don't need to search data.
       ld de,NMESIZ        ; bytes to skip.
sprls1 ld a,(hl)           ; fetch type of sprite.
       inc a               ; is it an end marker?
       jr z,sprls0         ; yes, end of this room.
       add hl,de           ; point to next sprite in list.
       jr sprls1           ; continue until end of room.
sprls0 inc hl              ; point to start of next screen.
       djnz sprls1         ; continue until room found.
       ret


; Clear all but a single player sprite.

nspr   ld b,NUMSPR         ; sprite slots in table.
       ld ix,sprtab        ; sprite table.
       ld de,TABSIZ        ; distance to next odd/even entry.
nspr0  ld a,(ix+0)         ; fetch sprite type.
       and a               ; is it a player?
       jr z,nspr1          ; yes, keep this one.
       ld (ix+0),255       ; delete sprite.
       ld (ix+5),255       ; remove next type.
       add ix,de           ; next sprite.
       djnz nspr0          ; one less space in the table.
       ret
nspr1  ld (ix+0),255       ; delete sprite.
       add ix,de           ; point to next sprite.
       djnz nspr2          ; one less to do.
       ret
nspr2  ld (ix+0),255       ; delete sprite.
       ld (ix+5),255       ; remove next type.
       add ix,de           ; next sprite.
       djnz nspr2          ; one less space in the table.
       ret


; Two initialisation routines.
; Initialise sprites - copy everything from list to table.

ispr   ld b,NUMSPR         ; sprite slots in table.
       ld ix,sprtab        ; sprite table.
ispr2  ld a,(hl)           ; fetch byte.
       cp 255              ; is it an end marker?
       ret z               ; yes, no more to do.
ispr1  ld a,(ix+0)         ; fetch sprite type.
       cp 255              ; is it enabled yet?
       jr nz,ispr4         ; yes, try another slot.
       ld a,(ix+5)         ; next type.
       cp 255              ; is it enabled yet?
       jr z,ispr3          ; no, process this one.
ispr4  ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       djnz ispr1          ; repeat for remaining sprites.
       ret                 ; no more room in table.
ispr3  call cpsp           ; initialise a sprite.
       djnz ispr2          ; one less space in the table.
       ret

; Initialise sprites - but not player, we're keeping the old one.

kspr   ld b,NUMSPR         ; sprite slots in table.
       ld ix,sprtab        ; sprite table.
kspr2  ld a,(hl)           ; fetch byte.
       cp 255              ; is it an end marker?
       ret z               ; yes, no more to do.
       and a               ; is it a player sprite?
       jr nz,kspr1         ; no, add to table as normal.
       ld de,NMESIZ        ; distance to next item in list.
       add hl,de           ; point to next one.
       jr kspr2
kspr1  ld a,(ix+0)         ; fetch sprite type.
       cp 255              ; is it enabled yet?
       jr nz,kspr4         ; yes, try another slot.
       ld a,(ix+5)         ; next type.
       cp 255              ; is it enabled yet?
       jr z,kspr3          ; no, process this one.
kspr4  ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       djnz kspr1          ; repeat for remaining sprites.
       ret                 ; no more room in table.
kspr3  call cpsp           ; copy sprite to table.
       djnz kspr2          ; one less space in the table.
       ret

; Copy sprite from list to table.

cpsp   ld a,(hl)           ; fetch byte from table.
       ld (ix+0),a         ; set up type.
       ld (ix+PAM1ST),a    ; set up type.
       inc hl              ; move to next byte.
       ld a,(hl)           ; fetch byte from table.
       ld (ix+6),a         ; set up image.
       inc hl              ; move to next byte.
       ld a,(hl)           ; fetch byte from table.
       ld (ix+3),200       ; set initial coordinate off screen.
       ld (ix+8),a         ; set up coordinate.
       inc hl              ; move to next byte.
       ld a,(hl)           ; fetch byte from table.
       ld (ix+9),a         ; set up coordinate.
       inc hl              ; move to next byte.
       xor a               ; zeroes in accumulator.
       ld (ix+7),a         ; reset frame number.
       ld (ix+10),a        ; reset direction.
;       ld (ix+12),a        ; reset parameter B.
       ld (ix+13),a        ; reset jump pointer low.
       ld (ix+14),a        ; reset jump pointer high.
       ld (ix+16),255      ; reset data pointer to auto-restore.
       push ix             ; store ix pair.
       push hl             ; store hl pair.
       push bc
evis0  call evnt09         ; perform event.
       pop bc
       pop hl              ; restore hl.
       pop ix              ; restore ix.
       ld de,TABSIZ        ; distance to next odd/even entry.
       add ix,de           ; next sprite.
       ret

; Clear the play area window.

clw    ld hl,(wintop)      ; get coordinates of window.
       ld (dispx),hl       ; put into dispx for calculation.
       ld a,(papmsk)       ; get paper colour.
       ld c,a              ; set colour in c register.
       call gprad          ; get print address.
       ex de,hl            ; flip screen address into hl.
       ld a,(winhgt)       ; height of window.
       rlca                ; multiply by 8 for block height.
       rlca
       rlca
       ld b,a              ; copy to b register.
clw1   push bc             ; store lines on stack.
       ld a,(winwid)       ; width of window.
       ld e,a              ; copy to e.
       rlca                ; multiply by 4.
       rlca
       add a,e             ; multiple of 5 = pixels to write.
       srl a               ; divide by 2 = bytes to write.
       push hl             ; store screen address.
clw0   ld (hl),c           ; write to screen.
       inc hl              ; next 2 pixels.
       dec a               ; one less byte.
       jr nz,clw0          ; repeat to end of window.
       pop hl              ; restore screen address.
       call nline2         ; down one line.
       pop bc              ; restore line counter.
       djnz clw1           ; repeat down the screen.
       ld hl,(wintop)      ; get coordinates of window.
       ld (charx),hl       ; put into display position.
       ret

; Redefine key.
; Go through table of 80 keys testing each one.
; Return code for first detected keypress.

redky  call debkey         ; debounce previous key.
       ld b,80             ; codes to check.
redky0 ld a,b              ; put code in accumulator.
       dec a               ; test 0 - 79, not 1 - 80.
       call 47902          ; check if key pressed.
       jr nz,redky1        ; pressed.
       djnz redky0         ; repeat until we've scanned them all.
       jr redky            ; repeat until something is pressed.
redky1 dec b               ; always one less.
       ret
       

; Effects code.
; Ticker routine is called 25 times per second.

scrly  ret
       defw txtscr         ; get screen address.
       ld b,8              ; 8 pixel rows.
       push hl             ; store screen address.
scrly1 push bc             ; store rows on stack.
       push hl

       ld a,(txtwid)       ; characters wide.
       ld b,a              ; copy to b.
       rlca                ; double it.
       rlca                ; now quadruple it.
       add a,b             ; quintuple width.
       srl a               ; divide by 2 for number of bytes to shift.
       ld b,a              ; put into the loop counter.
       ld d,0              ; clear previous pixels byte.
scrly0 ld a,(hl)           ; get byte from screen.
       ld e,a              ; copy to e.
       and 85              ; take right pixel.
       rlca                ; shift into left position.
       ld (hl),a           ; write to screen.
       ld a,d              ; value of 2 pixels to our right.
       and 170             ; we want the left pixel of that.
       rrca                ; shift into right position.
       or (hl)             ; merge with screen image.
       ld (hl),a           ; write to screen.
       ld d,e              ; get old value for next time round.
       dec hl              ; 2 pixels left.
       djnz scrly0         ; repeat for width of ticker message.
       pop hl
       call nline2         ; next screen row down.

       pop bc              ; retrieve row counter from stack.
       djnz scrly1         ; repeat for all rows.
       ld hl,(txtpos)      ; get text pointer.
       ld a,(hl)           ; find character we're displaying.
       and 127             ; remove end marker bit if applicable.
       cp 13               ; is it newline?
       jr nz,scrly5        ; no, it's okay.
       ld a,32             ; convert to a space instead.
scrly5 rlca
       rlca
       rlca                ; multiply by 8 to find char.
       ld b,a              ; store shift in b.
       and 3               ; keep within 768-byte range of font.
       ld d,a              ; that's our high byte.
       ld a,b              ; restore the shift.
       and 248
       ld e,a
       ld hl,font-256      ; font address.
       add hl,de           ; point to image of character.
       ex de,hl            ; need the address in de.
       pop hl              ; restore screen address.

       ld a,(txtbit)
       ld c,a
       ld b,8              ; height of ticker in pixels.
scrly3 ld a,(hl)           ; get screen byte.
       and 170             ; mask off right bit colours.
       ld (hl),a           ; write back to screen.
       ld a,(de)           ; get image of char line.
       and c               ; test relevant bit of char.
       jr z,scrly7         ; not set, write paper pixel.
       ld a,(inkmsk)       ; get ink colour.
       jr scrly2
scrly7 ld a,(papmsk)       ; get paper colour.
scrly2 and 85              ; remove left bit.
       or (hl)             ; merge with screen.
       ld (hl),a           ; write new bit.
       push bc             ; preserve row number and column bit.
       call nline2         ; next screen row down.
       pop bc              ; restore row number and column bit.
       inc de              ; next line of char.
       djnz scrly3
       ld hl,txtbit        ; bit of text to display.
       rr (hl)             ; next bit of char to use.
       ld a,(hl)           ; get bit value.
       cp 8                ; last valid value.
       ret nc              ; not reached end of character yet.
       ld (hl),128         ; start at leftmost bit again.
       ld hl,(txtpos)      ; text pointer.
       ld a,(hl)           ; what was the character?
       inc hl              ; next character in message.
       rla                 ; end of message?
;       ret nc              ; not yet, exit here.
;       ld a,201            ; code for ret.
;       ld (scrly),a        ; disable scrolling routine.
       jr nc,scrly6        ; not yet - continue.
scrly4 ld hl,(txtini)      ; start of scrolling message.
scrly6 ld (txtpos),hl      ; new text pointer position.
       ret

iscrly call preprt         ; set up display position.
       ld hl,msgdat        ; text messages.
       ld a,b              ; width.
       dec a               ; subtract one.
       cp 32               ; is it between 1 and 32?
       jr nc,iscrl0        ; no, disable messages.
       ld a,c              ; message number.
       ld d,b              ; copy width to d.
       call getwrd         ; find message start.
       ld b,d              ; restore width to b register.
       ld (txtini),hl      ; set initial text position.
       ld a,42             ; code for ld hl,(nn).
iscrl0 ld (scrly),a        ; enable/disable scrolling routine.
       call preprt         ; set up display position.
       call gprad          ; get print address.
       ld a,b              ; width of ticker.
       rlca                ; multiple of 2.
       rlca                ; multiple of 4.
       add a,b             ; now a multiple of 5.
       srl a               ; divide by 2 for number of bytes.
       ld l,a              ; copy to hl.
       ld h,0              ; no high byte.
       dec hl              ; left to end of ticker display.
       add hl,de           ; add width.
       ld (txtscr),hl      ; set text screen address.
       ld a,b              ; width.
       ld (txtwid),a       ; set width in working storage.
       ld hl,txtbit        ; bit of text to display.
       ld (hl),128         ; start with leftmost bit.
       jr scrly4

lstrnd equ $               ; end of "random" area.

; Sprite table.
; ix+0  = type.
; ix+1  = sprite image number.
; ix+2  = frame.
; ix+3  = x coord.
; ix+4  = y coord.

; ix+5  = new type.
; ix+6  = new image number.
; ix+7  = new frame.
; ix+8  = new x coord.
; ix+9  = new y coord.

; ix+10 = direction.
; ix+11 = parameter 1.
; ix+12 = parameter 2.
; ix+13 = jump pointer low.
; ix+14 = jump pointer high.
; ix+15 = data pointer low.
; ix+16 = data pointer high.


sprtab equ $

;       block NUMSPR * TABSIZ,255

       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255,255
ssprit defb 255,255,255,255,255,255,255,0,192,120,0,0,0,255,255,255,255

roomtb defb 34                     ; room number.
nosnd  defb 255

; Everything below here will be generated by the editors.

; Sounds.

fx1    defb 128+15         ; volume and mixer.
       defb 31             ; white noise.
       defw 1000           ; tone register.
       defb 128+15         ; volume and mixer.
       defb 25             ; white noise.
       defw 1000           ; tone register.
       defb 128+14         ; volume and mixer.
       defb 19             ; white noise.
       defw 1000           ; tone register.
       defb 128+13         ; volume and mixer.
       defb 13             ; white noise.
       defw 1000           ; tone register.
       defb 128+12         ; volume and mixer.
       defb 7              ; white noise.
       defw 1000           ; tone register.
       defb 128+11         ; volume and mixer.
       defb 0              ; white noise.
       defw 1000           ; tone register.
       defb 128+10         ; volume and mixer.
       defb 6              ; white noise.
       defw 1000           ; tone register.
       defb 128+8          ; volume and mixer.
       defb 12             ; white noise.
       defw 1000           ; tone register.
       defb 128+6          ; volume and mixer.
       defb 18             ; white noise.
       defw 1000           ; tone register.
       defb 128+3          ; volume and mixer.
       defb 24             ; white noise.
       defw 1000           ; tone register.
       defb 255

fx2    defb 064+15         ; volume and mixer.
       defb 27             ; white noise.
       defw 1000           ; tone register.
       defb 064+14         ; volume and mixer.
       defb 31             ; white noise.
       defw 2000           ; tone register.
       defb 064+13         ; volume and mixer.
       defb 28             ; white noise.
       defw 3000           ; tone register.
       defb 064+12         ; volume and mixer.
       defb 31             ; white noise.
       defw 2000           ; tone register.
       defb 064+11         ; volume and mixer.
       defb 29             ; white noise.
       defw 1000           ; tone register.
       defb 064+10         ; volume and mixer.
       defb 31             ; white noise.
       defw 2000           ; tone register.
       defb 064+9          ; volume and mixer.
       defb 30             ; white noise.
       defw 3000           ; tone register.
       defb 064+8          ; volume and mixer.
       defb 31             ; white noise.
       defw 2000           ; tone register.
       defb 064+7          ; volume and mixer.
       defb 31             ; white noise.
       defw 1000           ; tone register.
       defb 064+6          ; volume and mixer.
       defb 31             ; white noise.
       defw 2000           ; tone register.
       defb 255

fx3    defb 064+15         ; volume and mixer.
       defb 0              ; white noise.
       defw 4000           ; tone register.
       defb 064+15         ; volume and mixer.
       defb 0              ; white noise.
       defw 4100           ; tone register.
       defb 064+14         ; volume and mixer.
       defb 0              ; white noise.
       defw 4200           ; tone register.
       defb 064+14         ; volume and mixer.
       defb 0              ; white noise.
       defw 4300           ; tone register.
       defb 064+13         ; volume and mixer.
       defb 0              ; white noise.
       defw 4400           ; tone register.
       defb 064+13         ; volume and mixer.
       defb 0              ; white noise.
       defw 4500           ; tone register.
       defb 064+12         ; volume and mixer.
       defb 0              ; white noise.
       defw 4600           ; tone register.
       defb 064+12         ; volume and mixer.
       defb 0              ; white noise.
       defw 4700           ; tone register.
       defb 064+11         ; volume and mixer.
       defb 0              ; white noise.
       defw 4800           ; tone register.
       defb 064+10         ; volume and mixer.
       defb 0              ; white noise.
       defw 4900           ; tone register.
       defb 255

       defb 99             ; temporary marker.

; User routine.  Put your own code in here to be called with USER instruction.
; if USER has an argument it will be passed in the accumulator.

user   ret

; Game-specific data and events code generated by the compiler ------------------


WINDOWTOP equ 1
WINDOWLFT equ 2
WINDOWHGT equ 18
WINDOWWID equ 28 ;@
MAPWID equ 13
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255
mapdat equ $
       defb 255,255,255,255,255,255,255,21,22,255,255,255,255,255,12,15,14,13,11,19,20,23,24,255,255,255,255,16,17,18,255,10,255,255,255,25,255,38,255,255,255,5,6,7,8,9,255,255,26,29,32,255,255,255,4,3,255,255,255,255,37,255,30,31,255,255,255,255,2,255,28,27,255,36,255,255,255,255,255,255,255,1,255,255,255,33,34,35,255,255,255,255,255,255,0,255,255,255,255,255,255,255,255,255
       defb 255,255,255,255,255,255,255,255,255,255,255,255,255
stmap  defb 94
ptcusr ret
msgdat equ $
nummsg defb 0
chgfx  equ $
       defb 3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2
       defb 0,160,160,80,0,160,160,80,0,160,160,0,0,160,160,80,0,160,160,80,0,160,160,0
       defb 240,240,160,0,0,0,240,240,160,160,160,0,0,160,160,80,0,160,160,80,0,160,160,0
       defb 0,240,160,80,80,160,160,80,160,160,240,160,0,240,160,80,80,160,160,80,160,160,240,160
       defb 0,160,160,80,0,160,160,80,0,160,160,0,0,160,160,240,240,160,0,0,0,240,240,160
       defb 240,160,160,240,0,160,240,80,0,240,160,0,240,160,160,240,0,160,240,80,0,240,160,0
       defb 240,240,160,0,0,160,240,240,160,160,240,160,0,240,160,80,80,160,160,80,160,160,240,160
       defb 0,240,160,80,80,160,160,80,160,160,240,160,0,240,160,240,240,160,0,0,160,240,240,160
       defb 240,160,160,240,0,160,240,80,0,240,160,0,240,160,160,240,240,160,160,0,0,240,240,160
       defb 240,240,160,160,0,0,240,240,160,240,160,0,240,160,160,240,0,160,240,80,0,240,160,0
       defb 0,240,160,80,80,0,160,80,160,160,160,0,0,160,160,80,0,160,160,80,0,160,160,0
       defb 0,160,160,80,0,160,160,80,0,160,160,0,0,160,160,80,80,160,160,80,0,160,240,160
       defb 0,160,160,80,0,160,160,80,0,160,160,0,0,160,160,240,0,160,80,80,0,240,160,0
       defb 240,160,160,80,0,160,240,80,0,160,160,0,0,160,160,80,0,160,160,80,0,160,160,0
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 192,192,128,0,0,0,192,192,128,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 0,192,128,64,64,128,128,64,128,128,192,128,0,192,128,64,64,128,128,64,128,128,192,128
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,192,192,128,0,0,0,192,192,128
       defb 192,128,128,192,0,128,192,64,0,192,128,0,192,128,128,192,0,128,192,64,0,192,128,0
       defb 192,192,128,0,0,0,192,192,128,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 192,192,128,0,0,128,192,192,128,128,192,128,0,192,128,64,64,128,128,64,128,128,192,128
       defb 0,192,128,64,64,128,128,64,128,128,192,128,0,192,128,192,192,128,0,0,128,192,192,128
       defb 192,128,128,192,0,128,192,64,0,192,128,0,192,128,128,192,192,128,128,0,0,192,192,128
       defb 192,192,128,128,0,0,192,192,128,192,128,0,192,128,128,192,0,128,192,64,0,192,128,0
       defb 0,192,128,64,64,0,128,64,128,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,64,64,128,128,64,0,128,192,128
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,192,0,128,64,64,0,192,128,0
       defb 192,128,128,64,0,128,192,64,0,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 0,8,8,4,0,8,8,4,0,8,8,0,0,8,8,4,0,8,8,4,0,8,8,0
       defb 12,12,8,0,0,0,12,12,8,8,8,0,0,8,8,4,0,8,8,4,0,8,8,0
       defb 0,12,8,4,4,8,8,4,8,8,12,8,0,12,8,4,4,8,8,4,8,8,12,8
       defb 0,8,8,4,0,8,8,4,0,8,8,0,0,8,8,12,12,8,0,0,0,12,12,8
       defb 12,8,8,12,0,8,12,4,0,12,8,0,12,8,8,12,0,8,12,4,0,12,8,0
       defb 12,12,8,0,0,8,12,12,8,8,12,8,0,12,8,4,4,8,8,4,8,8,12,8
       defb 0,12,8,4,4,8,8,4,8,8,12,8,0,12,8,12,12,8,0,0,8,12,12,8
       defb 12,8,8,12,0,8,12,4,0,12,8,0,12,8,8,12,12,8,8,0,0,12,12,8
       defb 12,12,8,8,0,0,12,12,8,12,8,0,12,8,8,12,0,8,12,4,0,12,8,0
       defb 0,12,8,4,4,0,8,4,8,8,8,0,0,8,8,4,0,8,8,4,0,8,8,0
       defb 0,8,8,4,0,8,8,4,0,8,8,0,0,8,8,4,4,8,8,4,0,8,12,8
       defb 0,8,8,4,0,8,8,4,0,8,8,0,0,8,8,12,0,8,4,4,0,12,8,0
       defb 12,8,8,4,0,8,12,4,0,8,8,0,0,8,8,4,0,8,8,4,0,8,8,0
       defb 0,0,0,192,192,128,128,192,0,128,64,128,64,128,0,192,0,128,0,128,128,192,192,128
       defb 0,0,0,204,204,136,136,204,0,136,68,136,68,136,0,204,0,136,0,136,136,204,204,136
       defb 0,0,0,60,60,40,40,60,0,40,20,40,20,40,0,60,0,40,0,40,40,60,60,40
       defb 0,0,0,48,48,32,32,48,0,32,16,32,16,32,0,48,0,32,0,32,32,48,48,32
       defb 23,3,2,63,3,2,63,63,42,23,3,2,23,63,42,63,3,2,63,3,2,23,3,2
       defb 0,20,0,0,20,40,60,60,40,0,20,0,40,60,0,0,20,40,0,20,40,0,20,0
       defb 19,3,2,51,3,2,51,51,34,19,3,2,19,51,34,51,3,2,51,3,2,19,3,2
       defb 0,16,0,0,16,32,48,48,32,0,16,0,32,48,0,0,16,32,0,16,32,0,16,0
       defb 7,3,2,15,3,2,15,15,10,7,3,2,7,15,10,15,3,2,15,3,2,7,3,2
       defb 0,4,0,0,4,8,12,12,8,0,4,0,8,12,0,0,4,8,0,4,8,0,4,0
       defb 3,3,2,63,63,42,43,63,2,43,23,42,23,43,2,23,3,2,3,3,2,3,3,2
       defb 0,0,0,60,60,40,40,60,0,40,20,40,20,40,0,20,0,0,0,0,0,0,0,0
       defb 3,3,2,51,51,34,35,51,2,35,19,34,19,35,2,19,3,2,3,3,2,3,3,2
       defb 0,0,0,48,48,32,32,48,0,32,16,32,16,32,0,16,0,0,0,0,0,0,0,0
       defb 3,3,2,15,15,10,11,15,2,11,7,10,7,11,2,7,3,2,3,3,2,3,3,2
       defb 0,0,0,12,12,8,8,12,0,8,4,8,4,8,0,4,0,0,0,0,0,0,0,0
       defb 3,3,2,3,3,2,7,3,10,7,3,10,15,7,10,15,7,10,11,11,10,15,15,10
       defb 15,15,10,11,11,10,15,7,10,15,7,10,7,3,10,7,3,10,3,3,2,3,3,2
       defb 207,51,138,51,155,34,51,51,34,155,103,34,51,155,138,155,51,34,51,155,34,155,51,138
       defb 15,63,10,63,31,42,63,63,42,31,47,42,63,31,10,31,63,42,63,31,42,31,63,10
       defb 0,160,160,0,160,160,0,0,160,0,160,160,0,160,160,0,0,160,0,160,160,0,160,160
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,80,160,0,160,0,0,160,160,0,0,160
       defb 0,0,0,0,0,0,0,0,0,0,0,0,160,160,160,0,0,0,240,240,160,0,0,0
       defb 160,160,0,160,160,0,160,0,0,160,160,0,160,160,0,160,0,0,160,160,0,160,160,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,240,0,0,0,160,0,160,160,0,160,0,0
       defb 0,0,0,48,48,32,32,16,0,16,0,32,0,32,32,16,0,32,32,16,0,48,48,32
       defb 11,3,2,15,11,2,15,15,2,11,3,2,11,3,2,15,11,2,15,15,2,11,3,2
       defb 3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2
       defb 160,0,0,80,0,0,160,0,0,0,0,0,160,0,0,80,0,0,160,0,0,0,0,0
       defb 0,0,160,0,80,0,0,0,160,0,0,0,0,0,160,0,80,0,0,0,160,0,0,0
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,64,0,128,128,64,0,128,128,0
       defb 0,192,128,64,64,128,128,64,128,128,192,128,0,192,128,64,64,128,128,64,128,128,192,128
       defb 0,128,128,64,0,128,128,64,0,128,128,0,0,128,128,192,192,128,0,0,0,192,192,128
       defb 0,192,128,192,192,0,128,64,128,128,128,0,0,128,128,192,0,128,128,128,0,128,128,128
       defb 3,3,2,67,131,130,131,67,130,131,131,2,3,131,130,195,3,130,131,131,2,131,131,130
       defb 0,192,128,192,192,0,128,64,128,128,128,0,0,128,128,128,0,128,0,128,0,0,0,0
       defb 3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2
       defb 3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2,3,3,2
       defb 0,0,0,60,60,40,0,0,0,60,60,40,0,0,0,0,0,0,0,0,0,0,0,0
       defb 3,3,2,3,3,2,63,63,42,3,3,2,63,63,42,3,3,2,3,3,2,3,3,2
       defb 3,3,2,3,3,2,131,3,2,131,3,2,3,3,2,195,3,2,131,131,2,131,195,2
       defb 3,3,2,3,3,2,3,3,130,3,3,2,3,131,130,3,3,130,67,131,2,131,131,130
       defb 3,3,2,63,63,42,43,3,42,43,63,42,43,3,42,63,63,42,3,43,2,3,43,2
       defb 0,40,0,60,60,40,20,0,40,60,40,40,20,60,40,0,0,0,0,0,0,0,0,0
       defb 175,95,10,175,95,10,175,175,10,175,255,10,255,255,170,175,15,10,255,95,170,175,15,10
       defb 3,3,2,3,3,2,83,3,162,83,3,162,243,83,162,243,83,162,163,163,162,243,243,162
       defb 3,43,2,63,63,42,43,3,42,43,63,42,43,3,42,63,63,42,3,43,2,3,43,2
       defb 0,40,0,20,60,40,20,0,40,20,40,40,20,60,40,0,0,0,0,0,0,0,0,0
       defb 0,192,128,192,192,0,128,64,128,128,128,0,0,128,128,192,0,128,128,128,0,128,128,128
       defb 0,192,128,192,192,0,128,64,128,128,128,0,0,128,128,192,0,128,128,128,0,128,128,128
       defb 0,40,0,60,60,40,20,0,40,60,40,40,20,60,40,0,0,0,0,0,0,0,0,0
       defb 3,255,170,3,255,170,87,255,170,87,255,170,255,255,170,255,255,170,255,255,170,255,255,170
       defb 3,3,170,3,3,170,3,3,170,3,3,170,3,87,170,3,87,170,3,255,170,3,255,170
       defb 255,255,170,255,255,170,255,255,170,255,255,170,255,255,170,255,255,170,255,255,170,255,255,170
       defb 168,0,0,168,0,0,168,0,0,168,0,0,252,0,0,252,0,0,252,168,0,252,168,0
       defb 252,168,0,252,168,0,252,252,0,252,252,0,252,252,168,252,252,168,252,252,168,252,252,168
       defb 3,3,170,3,3,170,3,87,170,3,255,170,3,255,170,87,255,170,255,255,170,255,255,170
       defb 168,0,0,168,0,0,252,0,0,252,168,0,252,168,0,252,252,0,252,252,168,252,252,168
       defb 136,0,136,136,136,136,136,136,136,136,0,136,136,0,136,136,136,136,136,136,136,136,0,136
       defb 204,204,136,136,204,136,136,204,136,136,204,136,204,136,136,204,136,136,204,136,136,204,204,136
       defb 0,0,0,204,204,136,0,0,0,204,204,136,204,204,136,136,204,0,0,0,0,204,204,136
       defb 255,255,170,235,195,130,235,215,130,235,195,130,255,255,170,235,215,130,235,215,130,235,195,130
       defb 63,63,42,63,63,42,3,63,42,3,63,42,3,3,2,3,3,2,3,3,2,3,3,2
       defb 16,48,0,16,48,32,16,48,0,16,48,32,16,48,0,0,0,0,0,0,0,0,0,0
       defb 3,3,2,3,3,2,51,51,34,3,3,2,51,51,34,3,3,2,3,3,2,3,3,2
       defb 0,0,0,48,48,32,0,0,0,48,48,32,0,0,0,0,0,0,0,0,0,0,0,0
       defb 48,32,0,48,32,0,48,32,0,48,32,0,48,32,0,0,0,0,0,0,0,0,0,0
       defb 3,3,2,19,51,2,19,51,34,19,51,2,19,51,34,19,51,2,3,3,2,3,3,2
       defb 3,3,2,51,35,2,51,35,2,51,35,2,51,35,2,51,35,2,3,3,2,3,3,2
       defb 60,60,40,60,60,40,60,40,0,60,40,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 3,15,10,3,15,10,3,11,10,7,15,10,7,15,10,3,3,2,15,15,10,3,3,2
       defb 12,8,0,12,8,0,8,8,0,12,12,0,12,12,0,0,0,0,12,12,8,0,0,0
       defb 252,252,168,240,252,168,240,244,168,240,244,168,240,240,168,240,240,168,252,252,168,240,240,160
       defb 255,255,170,255,251,162,255,243,162,255,243,162,251,243,162,251,243,162,255,255,170,243,243,162
       defb 60,60,40,60,60,40,60,60,40,60,60,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 63,63,42,63,63,42,63,63,42,23,63,42,3,3,2,3,3,2,3,3,2,3,3,2
       defb 12,12,168,252,92,168,12,12,168,252,252,168,92,172,168,12,172,168,92,12,168,92,12,168
       defb 192,192,168,212,192,168,212,192,168,252,252,168,192,192,168,212,192,168,192,192,168,252,252,168
       defb 252,252,168,252,252,168,252,252,168,252,252,168,252,252,168,252,252,168,252,252,168,252,252,168
       defb 192,192,128,192,192,128,192,192,128,192,192,128,192,192,128,192,192,128,128,0,128,192,192,128
       defb 48,48,32,48,48,32,48,0,0,48,48,0,48,48,0,48,0,0,48,48,32,48,48,32
       defb 48,48,32,48,48,32,48,0,0,48,48,32,48,48,32,0,16,32,48,48,32,48,48,32
       defb 48,48,32,48,48,32,48,0,0,48,0,0,48,0,0,48,0,0,48,48,32,48,48,32
       defb 48,48,32,48,48,32,48,16,32,48,48,32,48,48,32,48,16,32,48,16,32,48,16,32
       defb 48,48,32,48,48,32,48,16,32,48,48,32,48,48,32,48,0,0,48,0,0,48,0,0
       defb 192,128,0,192,192,128,192,128,128,192,128,0,0,0,0,192,192,128,64,128,128,128,128,128
       defb 192,128,0,192,0,0,192,0,0,192,128,0,0,0,0,192,128,0,128,128,0,128,128,0
       defb 192,192,128,0,0,0,192,192,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 192,0,0,0,0,0,192,128,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,4,8,0,4,8,0,4,8,0,4,8,0,4,8,12,4,8,12,12,8,12,12,8
       defb 12,12,8,12,12,8,12,0,0,12,0,0,12,0,0,12,0,0,12,12,8,12,12,8
       defb 60,60,40,60,60,40,60,20,40,60,60,40,60,60,40,60,0,0,60,0,0,60,0,0
       defb 0,20,40,0,20,40,0,20,40,0,20,40,0,20,40,60,20,40,60,60,40,60,60,40
       defb 48,16,32,48,48,32,48,48,32,48,48,32,48,16,32,48,16,32,48,16,32,48,16,32
       defb 240,80,160,240,80,160,240,240,0,240,240,0,240,80,160,240,80,160,240,80,160,240,80,160
       defb 0,80,160,0,80,160,0,80,160,0,80,160,0,80,160,240,80,160,240,240,160,240,240,160
       defb 204,204,0,204,204,136,204,68,136,204,204,136,204,204,0,204,0,0,204,68,136,204,68,136
       defb 204,68,136,204,68,136,204,68,136,204,204,136,204,204,136,204,68,136,204,68,136,204,68,136
       defb 15,63,10,63,31,42,63,63,42,31,47,42,63,31,10,31,63,42,63,31,42,31,63,10
       defb 0,0,0,48,32,0,32,32,0,32,48,32,32,32,0,32,48,32,48,32,0,16,0,0
       defb 16,0,0,16,0,0,48,48,32,48,32,0,48,48,32,16,0,0,0,0,0,0,0,0
       defb 0,48,32,0,0,32,48,32,32,0,48,32,48,32,0,0,0,0,0,0,0,0,0,0
       defb 48,48,32,32,16,32,32,0,0,48,32,32,16,32,0,48,32,32,0,32,0,0,32,0
       defb 48,48,32,48,32,32,32,0,32,48,48,32,32,0,0,48,48,0,0,48,0,0,48,0
       defb 16,0,0,32,32,0,16,0,32,16,48,32,16,32,32,16,32,0,16,32,0,16,32,0
       defb 16,32,0,16,32,0,16,32,0,48,32,0,48,48,0,32,16,0,16,32,32,0,16,0
       defb 0,48,0,0,48,0,0,48,0,0,32,0,16,32,32,16,32,32,16,32,32,0,0,0
       defb 32,0,0,32,0,32,32,48,32,32,32,32,48,32,0,32,48,32,48,48,32,0,0,0
       defb 160,240,160,160,240,160,160,240,160,160,240,160,0,0,0,160,240,160,160,240,160,160,240,160
       defb 160,160,0,160,240,160,160,240,160,160,240,0,0,0,0,160,240,160,160,160,160,160,160,160
       defb 160,240,0,0,240,0,0,240,0,160,240,0,0,0,0,160,240,160,160,240,160,160,240,160
       defb 0,0,0,0,160,0,0,240,0,80,0,160,0,160,0,0,240,0,80,0,160,160,0,0
       defb 0,0,0,80,0,160,0,240,0,0,160,0,80,0,160,0,240,0,0,160,0,160,0,0
bprop  equ $
       defb 0
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 3
       defb 3
       defb 3
       defb 3
       defb 3
       defb 3
       defb 1
       defb 1
       defb 1
       defb 1
       defb 0
       defb 0
       defb 5
       defb 5
       defb 6
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 2
       defb 5
       defb 6
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 2
       defb 2
       defb 0
       defb 2
       defb 3
       defb 6
       defb 0
       defb 0
       defb 0
       defb 0
       defb 6
       defb 2
       defb 5
       defb 0
       defb 6
       defb 0
       defb 6
       defb 6
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 0
       defb 0
       defb 6
       defb 0
       defb 0
       defb 0
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 2
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 2
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
       defb 0
sprgfx equ $
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,255,0
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 0,85,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,0,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,255,170
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 0,0,255,255,0
       defb 0,85,255,255,170
       defb 0,85,255,255,170
       defb 0,85,170,0,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,255,0
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,170,0
       defb 85,170,85,170,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,255,170
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,0
       defb 0,255,0,255,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,255,0
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 0,85,255,170,0
       defb 0,85,255,170,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,255,170
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 0,0,255,255,0
       defb 0,0,255,255,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,255,0
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 0,85,255,170,0
       defb 0,255,255,0,0
       defb 0,255,255,170,0
       defb 0,85,255,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,255,170
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 0,0,255,255,0
       defb 0,85,255,170,0
       defb 0,85,255,255,0
       defb 0,0,255,170,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 85,255,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,170,0
       defb 0,0,85,170,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 0,255,255,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,0
       defb 0,0,0,255,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 85,255,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,255,85,170,0
       defb 85,255,0,170,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 0,255,255,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,255,170,255,0
       defb 0,255,170,85,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 85,255,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,0,0
       defb 0,255,255,0,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 0,255,255,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,170,0
       defb 0,85,255,170,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 85,255,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,0,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,85,255,0,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 0,255,255,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,170,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,170,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,170,0,170,0
       defb 0,85,255,85,170
       defb 85,255,255,170,0
       defb 85,255,255,255,170
       defb 85,255,255,255,0
       defb 0,255,255,170,0
       defb 85,85,170,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,255,0
       defb 0,0,85,255,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,0,85,0
       defb 0,0,255,170,255
       defb 0,255,255,255,0
       defb 0,255,255,255,255
       defb 0,255,255,255,170
       defb 0,85,255,255,0
       defb 0,170,255,85,0
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,170
       defb 0,0,0,255,170
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,0,0,170,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,255,0
       defb 85,255,255,255,170
       defb 0,255,255,170,0
       defb 0,85,170,255,170
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 85,255,255,255,0
       defb 85,255,0,0,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,170,0,85,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,170
       defb 0,255,255,255,255
       defb 0,85,255,255,0
       defb 0,0,255,85,255
       defb 0,85,255,255,0
       defb 0,85,255,255,170
       defb 0,255,255,255,170
       defb 0,255,170,0,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,170,0,170,0
       defb 0,85,255,85,170
       defb 85,255,255,170,0
       defb 85,255,255,255,170
       defb 85,255,255,255,0
       defb 0,255,255,170,0
       defb 85,85,170,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,255,0
       defb 0,0,85,255,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,0,85,0
       defb 0,0,255,170,255
       defb 0,255,255,255,0
       defb 0,255,255,255,255
       defb 0,255,255,255,170
       defb 0,85,255,255,0
       defb 0,170,255,85,0
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,170
       defb 0,0,0,255,170
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,0,0,170,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,255,0
       defb 85,255,255,255,170
       defb 0,255,255,170,0
       defb 0,85,170,255,170
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 85,255,255,255,0
       defb 85,255,0,0,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,170,0,85,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,170
       defb 0,255,255,255,255
       defb 0,85,255,255,0
       defb 0,0,255,85,255
       defb 0,85,255,255,0
       defb 0,85,255,255,170
       defb 0,255,255,255,170
       defb 0,255,170,0,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 85,255,255,170,0
       defb 0,170,0,170,170
       defb 170,85,85,0,170
       defb 255,85,85,85,170
       defb 170,170,0,170,0
       defb 85,255,255,255,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,255,255,255,0
       defb 0,85,0,85,85
       defb 85,0,170,170,85
       defb 85,170,170,170,255
       defb 85,85,0,85,0
       defb 0,255,255,255,170
       defb 0,85,255,0,0
       defb 85,255,85,170,0
       defb 85,255,85,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 85,255,255,255,0
       defb 170,170,0,170,0
       defb 170,85,85,0,170
       defb 255,85,85,170,170
       defb 0,170,0,170,170
       defb 85,255,255,170,0
       defb 0,0,255,170,0
       defb 0,255,170,255,0
       defb 0,255,170,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,255,255,255,170
       defb 85,85,0,85,0
       defb 85,0,170,170,85
       defb 85,170,170,255,85
       defb 0,85,0,85,85
       defb 0,255,255,255,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,170,255,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 85,255,255,255,0
       defb 170,170,0,170,170
       defb 255,85,85,170,0
       defb 0,85,85,0,170
       defb 170,170,0,170,170
       defb 85,85,255,255,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,85,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,255,255,255,170
       defb 85,85,0,85,85
       defb 85,170,170,255,0
       defb 0,0,170,170,85
       defb 85,85,0,85,85
       defb 0,170,255,255,170
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 85,85,255,255,0
       defb 170,170,0,170,170
       defb 85,85,85,85,170
       defb 170,85,85,0,0
       defb 170,170,0,170,170
       defb 85,255,255,255,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,170,255,255,170
       defb 85,85,0,85,85
       defb 0,170,170,170,255
       defb 85,0,170,170,0
       defb 85,85,0,85,85
       defb 0,255,255,255,170
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,0,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,85,170,170
       defb 255,85,255,170,170
       defb 255,0,170,255,170
       defb 85,0,170,255,0
       defb 85,0,170,170,0
       defb 0,0,170,0,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,85,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,170,255,85
       defb 85,170,255,255,85
       defb 85,170,85,85,255
       defb 0,170,85,85,170
       defb 0,170,85,85,0
       defb 0,0,85,0,0
       defb 0,85,255,0,0
       defb 85,255,85,170,0
       defb 85,255,85,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,0,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,85,170,170
       defb 255,85,255,170,170
       defb 255,0,170,255,170
       defb 85,0,170,255,0
       defb 85,0,170,170,0
       defb 0,0,170,0,0
       defb 0,0,255,170,0
       defb 0,255,170,255,0
       defb 0,255,170,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,85,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,170,255,85
       defb 85,170,255,255,85
       defb 85,170,85,85,255
       defb 0,170,85,85,170
       defb 0,170,85,85,0
       defb 0,0,85,0,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,170,255,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,0,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,85,170,170
       defb 255,85,255,170,170
       defb 255,0,0,255,170
       defb 85,0,170,255,0
       defb 85,0,0,170,0
       defb 0,0,170,0,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,85,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,85,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,170,255,85
       defb 85,170,255,255,85
       defb 85,170,0,85,255
       defb 0,170,85,85,170
       defb 0,170,0,85,0
       defb 0,0,85,0,0
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,0,255,255,170
       defb 255,255,255,255,170
       defb 255,85,255,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 255,255,85,170,170
       defb 255,85,255,170,170
       defb 255,0,170,255,170
       defb 85,0,0,255,0
       defb 85,0,0,170,0
       defb 0,0,170,0,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,85,255,255
       defb 85,255,255,255,255
       defb 85,170,255,255,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 85,255,170,255,85
       defb 85,170,255,255,85
       defb 85,170,85,85,255
       defb 0,170,0,85,170
       defb 0,170,0,85,0
       defb 0,0,85,0,0
       defb 0,0,0,0,0
       defb 0,85,255,0,0
       defb 85,170,170,170,0
       defb 85,85,85,85,0
       defb 85,170,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,170,255,170
       defb 255,85,255,255,170
       defb 255,85,170,255,170
       defb 85,255,255,255,0
       defb 0,85,255,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,255,170,0
       defb 0,255,85,85,0
       defb 0,170,170,170,170
       defb 0,255,85,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,85,255
       defb 85,170,255,255,255
       defb 85,170,255,85,255
       defb 0,255,255,255,170
       defb 0,0,255,255,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,255,0,0
       defb 85,170,170,170,0
       defb 85,85,85,85,0
       defb 85,170,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,170,255,170
       defb 255,85,255,255,170
       defb 255,85,170,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 0,85,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,255,170,0
       defb 0,255,85,85,0
       defb 0,170,170,170,170
       defb 0,255,85,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,85,255
       defb 85,170,255,255,255
       defb 85,170,255,85,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,0,255,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,255,0,0
       defb 85,170,170,170,0
       defb 85,85,85,85,0
       defb 85,170,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,170,255,170
       defb 255,85,255,255,170
       defb 255,85,170,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,255,170,0
       defb 0,255,85,85,0
       defb 0,170,170,170,170
       defb 0,255,85,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,85,255
       defb 85,170,255,255,255
       defb 85,170,255,85,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,85,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,255,0,0
       defb 85,170,170,170,0
       defb 85,85,85,85,0
       defb 85,170,170,255,0
       defb 0,0,0,0,0
       defb 255,255,255,255,170
       defb 255,85,170,255,170
       defb 255,85,255,255,170
       defb 255,85,170,255,170
       defb 85,255,255,255,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,170,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,255,170,0
       defb 0,255,85,85,0
       defb 0,170,170,170,170
       defb 0,255,85,85,170
       defb 0,0,0,0,0
       defb 85,255,255,255,255
       defb 85,170,255,85,255
       defb 85,170,255,255,255
       defb 85,170,255,85,255
       defb 0,255,255,255,170
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,85,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,170,0,0
       defb 0,85,85,0,0
       defb 0,0,170,0,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,0,170,0,0
       defb 0,85,85,0,0
       defb 0,0,170,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,85,0,0
       defb 0,0,170,170,0
       defb 0,0,85,0,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,0,85,0,0
       defb 0,0,170,170,0
       defb 0,0,85,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,85,0,0
       defb 0,170,0,170,0
       defb 0,0,170,0,0
       defb 85,85,85,170,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 85,85,85,170,0
       defb 0,0,170,0,0
       defb 0,170,0,170,0
       defb 0,85,85,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,170,170,0
       defb 0,85,0,85,0
       defb 0,0,85,0,0
       defb 0,170,170,255,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 0,170,170,255,0
       defb 0,0,85,0,0
       defb 0,85,0,85,0
       defb 0,0,170,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,85,0,0
       defb 85,0,0,170,0
       defb 0,85,255,0,0
       defb 85,85,85,85,0
       defb 0,170,170,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,170,170,170,0
       defb 85,85,85,85,0
       defb 0,85,255,0,0
       defb 85,0,0,170,0
       defb 0,85,85,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,170,170,0
       defb 0,170,0,85,0
       defb 0,0,255,170,0
       defb 0,170,170,170,170
       defb 0,85,85,85,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,85,85,0
       defb 0,170,170,170,170
       defb 0,0,255,170,0
       defb 0,170,0,85,0
       defb 0,0,170,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,170,0,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 170,0,0,0,170
       defb 0,0,170,0,0
       defb 0,85,85,0,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 0,85,85,0,0
       defb 0,0,170,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 170,0,0,0,170
       defb 0,0,0,0,0
       defb 0,170,0,170,0
       defb 0,0,0,0,0
       defb 0,85,0,85,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 85,0,0,0,85
       defb 0,0,85,0,0
       defb 0,0,170,170,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 0,0,170,170,0
       defb 0,0,85,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 85,0,0,0,85
       defb 0,0,0,0,0
       defb 0,85,0,85,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 170,255,255,255,0
       defb 0,255,255,170,0
       defb 255,255,255,255,0
       defb 255,0,0,85,0
       defb 85,255,255,255,0
       defb 85,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,85,170,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,170,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 85,85,255,255,170
       defb 0,85,255,255,0
       defb 85,255,255,255,170
       defb 85,170,0,0,170
       defb 0,255,255,255,170
       defb 0,255,255,255,170
       defb 0,85,255,255,170
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,85,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 170,255,255,255,0
       defb 0,255,255,170,0
       defb 255,255,255,255,0
       defb 255,0,0,85,0
       defb 85,255,255,255,0
       defb 85,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,85,170,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,170,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 85,85,255,255,170
       defb 0,85,255,255,0
       defb 85,255,255,255,170
       defb 85,170,0,0,170
       defb 0,255,255,255,170
       defb 0,255,255,255,170
       defb 0,85,255,255,170
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,85,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,170
       defb 0,255,255,170,0
       defb 85,255,255,170,170
       defb 85,0,0,85,170
       defb 85,255,255,255,170
       defb 85,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,85,170,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,255,255,255,85
       defb 0,85,255,255,0
       defb 0,255,255,255,85
       defb 0,170,0,0,255
       defb 0,255,255,255,255
       defb 0,255,255,255,170
       defb 0,85,255,255,170
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,85,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,170
       defb 0,0,255,255,170
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,170
       defb 0,255,255,170,0
       defb 85,255,255,170,170
       defb 85,0,0,85,170
       defb 85,255,255,255,170
       defb 85,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,85,170,170,0
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,255,255,255,85
       defb 0,85,255,255,0
       defb 0,255,255,255,85
       defb 0,170,0,0,255
       defb 0,255,255,255,255
       defb 0,255,255,255,170
       defb 0,85,255,255,170
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,85,0
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,85,255,255,170
       defb 0,0,255,255,170
       defb 0,85,255,0,0
       defb 85,255,255,170,0
       defb 255,255,255,255,0
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 170,255,255,255,170
       defb 255,255,255,255,170
       defb 255,255,255,170,170
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 255,255,255,255,170
       defb 255,255,255,255,0
       defb 85,255,255,255,0
       defb 0,255,255,170,0
       defb 0,85,255,0,0
       defb 0,0,255,170,0
       defb 0,255,255,255,0
       defb 85,255,255,255,170
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 85,85,255,255,255
       defb 85,255,255,255,255
       defb 85,255,255,255,85
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 85,255,255,255,255
       defb 85,255,255,255,170
       defb 0,255,255,255,170
       defb 0,85,255,255,0
       defb 0,0,255,170,0
       defb 0,0,85,0,0
       defb 85,0,0,85,0
       defb 0,85,85,0,0
       defb 0,0,0,0,0
       defb 0,170,170,170,0
       defb 0,0,255,0,0
       defb 0,85,85,0,0
       defb 0,85,0,170,0
       defb 0,170,0,170,0
       defb 0,170,85,170,0
       defb 0,170,85,170,0
       defb 0,85,170,170,0
       defb 0,85,85,0,0
       defb 0,0,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,170,0
       defb 0,170,0,0,170
       defb 0,0,170,170,0
       defb 0,0,0,0,0
       defb 0,85,85,85,0
       defb 0,0,85,170,0
       defb 0,0,170,170,0
       defb 0,0,170,85,0
       defb 0,85,0,85,0
       defb 0,85,0,255,0
       defb 0,85,0,255,0
       defb 0,0,255,85,0
       defb 0,0,170,170,0
       defb 0,0,85,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,170,0,0,0
       defb 0,85,85,0,0
       defb 0,0,0,0,0
       defb 0,170,170,170,0
       defb 0,0,85,0,0
       defb 0,85,170,0,0
       defb 0,85,85,0,0
       defb 0,85,0,170,0
       defb 0,170,0,170,0
       defb 0,170,85,170,0
       defb 0,170,85,170,0
       defb 0,85,170,170,0
       defb 0,85,85,0,0
       defb 0,0,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,0,0,0
       defb 0,0,170,170,0
       defb 0,0,0,0,0
       defb 0,85,85,85,0
       defb 0,0,0,170,0
       defb 0,0,255,0,0
       defb 0,0,170,170,0
       defb 0,0,170,85,0
       defb 0,85,0,85,0
       defb 0,85,0,255,0
       defb 0,85,0,255,0
       defb 0,0,255,85,0
       defb 0,0,170,170,0
       defb 0,0,85,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,85,0,0
       defb 0,0,170,0,0
       defb 0,170,0,170,0
       defb 0,0,85,0,0
       defb 0,85,0,0,0
       defb 0,0,170,170,0
       defb 0,85,85,0,0
       defb 0,85,0,170,0
       defb 0,170,0,170,0
       defb 0,170,85,170,0
       defb 0,170,85,170,0
       defb 0,85,170,170,0
       defb 0,85,85,0,0
       defb 0,0,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,170,170,0
       defb 0,0,85,0,0
       defb 0,85,0,85,0
       defb 0,0,0,170,0
       defb 0,0,170,0,0
       defb 0,0,85,85,0
       defb 0,0,170,170,0
       defb 0,0,170,85,0
       defb 0,85,0,85,0
       defb 0,85,0,255,0
       defb 0,85,0,255,0
       defb 0,0,255,85,0
       defb 0,0,170,170,0
       defb 0,0,85,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,170,85,170,0
       defb 0,0,0,0,0
       defb 0,85,0,0,0
       defb 0,0,0,170,0
       defb 0,0,170,0,0
       defb 0,85,85,0,0
       defb 0,85,0,170,0
       defb 0,170,0,170,0
       defb 0,170,85,170,0
       defb 0,170,85,170,0
       defb 0,85,170,170,0
       defb 0,85,85,0,0
       defb 0,0,255,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,0,255,0
       defb 0,0,0,0,0
       defb 0,0,170,0,0
       defb 0,0,0,85,0
       defb 0,0,85,0,0
       defb 0,0,170,170,0
       defb 0,0,170,85,0
       defb 0,85,0,85,0
       defb 0,85,0,255,0
       defb 0,85,0,255,0
       defb 0,0,255,85,0
       defb 0,0,170,170,0
       defb 0,0,85,170,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,85,170
       defb 255,255,255,85,0
       defb 255,255,255,170,0
       defb 0,85,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,0
       defb 0,255,0,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,170,255
       defb 85,255,255,170,170
       defb 85,255,255,255,0
       defb 0,0,255,255,0
       defb 0,85,255,255,170
       defb 0,85,255,255,170
       defb 0,85,170,0,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,85,170
       defb 255,255,255,85,0
       defb 255,255,255,170,0
       defb 0,255,255,170,0
       defb 85,255,255,170,0
       defb 85,255,85,170,0
       defb 85,170,85,170,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,170,255
       defb 85,255,255,170,170
       defb 85,255,255,255,0
       defb 0,85,255,255,0
       defb 0,255,255,255,0
       defb 0,255,170,255,0
       defb 0,255,0,255,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,85,170
       defb 255,255,255,85,0
       defb 255,255,255,170,0
       defb 0,85,255,170,0
       defb 0,85,255,170,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,170,255
       defb 85,255,255,170,170
       defb 85,255,255,255,0
       defb 0,0,255,255,0
       defb 0,0,255,255,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 0,85,255,170,0
       defb 0,255,170,85,0
       defb 0,255,0,0,170
       defb 0,255,0,0,170
       defb 0,255,0,170,170
       defb 0,255,170,85,0
       defb 255,85,255,170,0
       defb 255,0,0,0,0
       defb 255,85,255,170,0
       defb 255,255,255,85,170
       defb 255,255,255,85,0
       defb 255,255,255,170,0
       defb 0,85,255,170,0
       defb 0,255,255,0,0
       defb 0,255,255,170,0
       defb 0,85,255,0,0
       defb 0,0,255,255,0
       defb 0,85,255,0,170
       defb 0,85,170,0,85
       defb 0,85,170,0,85
       defb 0,85,170,85,85
       defb 0,85,255,0,170
       defb 85,170,255,255,0
       defb 85,170,0,0,0
       defb 85,170,255,255,0
       defb 85,255,255,170,255
       defb 85,255,255,170,170
       defb 85,255,255,255,0
       defb 0,0,255,255,0
       defb 0,85,255,170,0
       defb 0,85,255,255,0
       defb 0,0,255,170,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 255,85,255,255,170
       defb 85,85,255,255,170
       defb 85,85,255,255,170
       defb 85,255,255,0,0
       defb 85,255,255,170,0
       defb 85,255,255,170,0
       defb 0,0,85,170,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 85,170,255,255,255
       defb 0,170,255,255,255
       defb 0,170,255,255,255
       defb 0,255,255,170,0
       defb 0,255,255,255,0
       defb 0,255,255,255,0
       defb 0,0,0,255,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 255,85,255,255,170
       defb 85,85,255,255,170
       defb 85,85,255,255,170
       defb 0,255,255,170,0
       defb 0,255,255,170,0
       defb 85,255,85,170,0
       defb 85,255,0,170,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 85,170,255,255,255
       defb 0,170,255,255,255
       defb 0,170,255,255,255
       defb 0,85,255,255,0
       defb 0,85,255,255,0
       defb 0,255,170,255,0
       defb 0,255,170,85,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 255,85,255,255,170
       defb 85,85,255,255,170
       defb 85,85,255,255,170
       defb 85,255,255,0,0
       defb 0,255,255,0,0
       defb 0,85,255,0,0
       defb 0,85,255,0,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 85,170,255,255,255
       defb 0,170,255,255,255
       defb 0,170,255,255,255
       defb 0,255,255,170,0
       defb 0,85,255,170,0
       defb 0,0,255,170,0
       defb 0,0,255,170,0
       defb 85,255,255,0,0
       defb 85,0,255,170,0
       defb 170,0,85,170,0
       defb 170,0,85,170,0
       defb 255,0,85,170,0
       defb 85,0,255,170,0
       defb 85,255,255,85,170
       defb 0,0,0,255,170
       defb 85,255,255,85,170
       defb 255,85,255,255,170
       defb 85,85,255,255,170
       defb 85,85,255,255,170
       defb 0,255,255,0,0
       defb 0,85,255,170,0
       defb 0,255,255,170,0
       defb 0,85,255,0,0
       defb 0,255,255,170,0
       defb 0,170,85,255,0
       defb 85,0,0,255,0
       defb 85,0,0,255,0
       defb 85,170,0,255,0
       defb 0,170,85,255,0
       defb 0,255,255,170,255
       defb 0,0,0,85,255
       defb 0,255,255,170,255
       defb 85,170,255,255,255
       defb 0,170,255,255,255
       defb 0,170,255,255,255
       defb 0,85,255,170,0
       defb 0,0,255,255,0
       defb 0,85,255,255,0
       defb 0,0,255,170,0
       defb 85,85,85,170,0
       defb 85,255,85,170,0
       defb 0,85,85,0,0
       defb 170,85,85,0,170
       defb 170,255,255,170,170
       defb 255,170,0,255,170
       defb 0,255,255,170,0
       defb 0,170,85,170,0
       defb 0,255,170,170,0
       defb 0,170,255,170,0
       defb 255,170,0,255,170
       defb 170,255,255,170,170
       defb 170,85,85,0,170
       defb 0,85,85,0,0
       defb 85,255,85,170,0
       defb 85,85,85,170,0
       defb 0,170,170,255,0
       defb 0,255,170,255,0
       defb 0,0,170,170,0
       defb 85,0,170,170,85
       defb 85,85,255,255,85
       defb 85,255,0,85,255
       defb 0,85,255,255,0
       defb 0,85,0,255,0
       defb 0,85,255,85,0
       defb 0,85,85,255,0
       defb 85,255,0,85,255
       defb 85,85,255,255,85
       defb 85,0,170,170,85
       defb 0,0,170,170,0
       defb 0,255,170,255,0
       defb 0,170,170,255,0
       defb 85,85,85,170,0
       defb 85,255,85,170,0
       defb 0,85,85,0,0
       defb 170,85,85,0,170
       defb 170,255,255,170,170
       defb 255,170,0,255,170
       defb 0,170,170,170,0
       defb 0,255,170,170,0
       defb 0,170,255,170,0
       defb 0,255,170,170,0
       defb 255,170,0,255,170
       defb 170,255,255,170,170
       defb 170,85,85,0,170
       defb 0,85,85,0,0
       defb 85,255,85,170,0
       defb 85,85,85,170,0
       defb 0,170,170,255,0
       defb 0,255,170,255,0
       defb 0,0,170,170,0
       defb 85,0,170,170,85
       defb 85,85,255,255,85
       defb 85,255,0,85,255
       defb 0,85,85,85,0
       defb 0,85,255,85,0
       defb 0,85,85,255,0
       defb 0,85,255,85,0
       defb 85,255,0,85,255
       defb 85,85,255,255,85
       defb 85,0,170,170,85
       defb 0,0,170,170,0
       defb 0,255,170,255,0
       defb 0,170,170,255,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
       defb 0,0,0,0,0
frmlst equ $
       defb 0,4
       defb 4,4
       defb 8,4
       defb 12,4
       defb 16,4
       defb 20,4
       defb 24,4
       defb 28,4
       defb 32,1
       defb 33,4
       defb 37,4
       defb 41,4
       defb 45,2
       defb 47,1,48,0
scdat  equ $
       defw 176,266,270,171,215,236,168,166,242,202,194,129,272,145,70,114,131,222,201,164,175,175,131,109,170,273
       defw 149,118,225,276,202,125,218,58,73,174,192,199,188
       defb 11,255,4,11,7,45,46,8,255,4,11,12,3,255,0,12,45,46,255,0,12,5,3,255,0,12,45,46,255,0,12,5,3
       defb 255,0,12,45,46,255,0,12,5,3,0,0,0,51,52,255,41,18,0,0,0,5,3,255,0,26,5,3,0,0,0,51,52
       defb 255,0,21,5,3,255,0,26,5,3,0,0,0,51,52,255,0,21,5,3,255,0,8,57,255,0,8,57,255,0,8,5,3
       defb 0,0,0,255,41,18,51,52,0,0,0,5,3,255,0,26,5,3,0,0,62,63,63,255,0,16,51,52,0,0,0,5,3
       defb 0,0,61,60,60,255,0,21,5,3,0,0,61,60,60,255,0,16,51,52,0,0,0,5,3,0,0,61,60,60,255,0,21
       defb 5,3,255,41,26,5,10,255,2,26,13
       defb 1,1,3,51,52,8,255,4,16,7,0,0,5,255,1,4,3,255,0,22,5,255,1,4,3,51,52,255,0,20,5,255,1,4
       defb 3,255,0,22,5,255,1,4,3,51,52,255,0,20,5,255,1,4,3,255,0,22,5,1,1,11,4,7,255,41,20,45,46
       defb 8,4,12,3,0,62,63,63,255,0,18,45,46,0,0,5,3,0,61,59,59,255,0,18,45,46,0,0,5,3,0,61,59,59
       defb 255,0,18,45,46,0,0,5,3,0,61,59,59,255,0,18,45,46,0,0,5,3,255,41,6,0,0,0,41,41,41,45,46
       defb 41,41,41,0,0,0,255,41,6,5,10,255,2,5,6,0,0,0,9,2,6,45,46,9,2,6,0,0,0,9,255,2,5
       defb 13,255,1,6,3,0,0,0,5,1,3,45,46,5,1,3,0,0,0,5,255,1,12,3,0,0,0,5,1,3,45,46,5
       defb 1,3,0,0,0,5,255,1,12,3,0,0,0,5,1,3,45,46,5,1,3,0,0,0,5,255,1,12,3,57,57,57,5
       defb 1,3,45,46,5,1,3,57,57,57,5,255,1,12,10,2,2,2,13,1,3,45,46,5,1,10,2,2,2,13,255,1,6
       defb 11,255,4,8,12,11,4,7,45,46,8,255,4,11,12,3,255,0,8,5,3,0,0,45,46,255,0,12,5,3,255,0,8
       defb 5,3,0,0,45,46,255,0,12,5,3,255,0,8,5,3,0,0,45,46,255,0,12,5,3,255,0,8,5,3,0,0,45
       defb 46,255,0,12,5,3,41,41,45,46,41,41,0,0,8,7,255,41,14,45,46,5,10,2,6,45,46,9,6,255,0,18,45
       defb 46,5,1,1,3,45,46,5,3,255,0,18,45,46,5,1,1,3,45,46,5,3,255,0,18,45,46,5,1,1,3,45,46
       defb 5,3,255,0,18,45,46,5,1,1,3,45,46,5,3,255,0,18,45,46,5,1,1,3,0,0,5,3,41,41,41,0,0,0
       defb 41,41,41,0,0,0,41,41,41,0,0,0,41,41,5,1,1,3,0,0,5,3,0,58,255,0,5,58,255,0,5,58,255,0,4
       defb 9,2,13,1,1,3,51,52,5,3,255,0,18,5,255,1,4,3,0,0,5,3,255,0,18,5,255,1,4,3,51,52,5
       defb 3,255,0,18,5,255,1,4,3,0,0,5,3,255,41,16,0,0,5,255,1,4,3,51,52,5,10,255,2,15,6,0,0
       defb 5,1,1
       defb 255,1,56,255,4,26,12,1,0,0,58,255,0,6,58,255,0,6,58,255,0,6,58,0,0,5,1,255,0,26,5,1,255,0,26
       defb 5,1,255,0,26,5,1,255,0,26,5,1,255,41,24,51,52,5,1,255,0,8,9,6,255,0,16,5,1,255,0,4,63,63
       defb 65,0,5,3,255,0,14,51,52,5,1,255,0,4,59,59,64,0,5,3,255,0,16,5,1,255,0,4,59,59,64,0,5
       defb 3,255,0,14,51,52,5,1,255,0,4,59,59,64,0,5,3,255,0,16,5,1,255,41,8,5,3,41,41,41,45,46,255,41,11
       defb 5,1,255,2,8,13,10,2,2,6,45,46,9,255,2,10,13,255,1,13,3,45,46,5,255,1,24,3,45,46,5,255,1,12
       defb 1,3,45,46,5,255,1,24,3,45,46,5,255,1,24,3,45,46,5,11,255,4,22,1,3,45,46,5,3,255,0,7,58
       defb 255,0,7,58,255,0,6,1,3,45,46,5,3,255,0,22,1,3,45,46,5,3,255,0,22,1,3,45,46,5,3,255,0,22
       defb 1,3,45,46,5,3,255,0,22,1,3,45,46,5,3,55,56,255,41,20,1,3,45,46,5,3,255,0,22,1,3,45,46
       defb 8,7,255,0,22,1,3,45,46,255,0,24,1,3,45,46,255,0,24,1,3,45,46,255,0,24,1,3,255,41,8,0,0,0
       defb 41,41,41,0,0,0,41,41,41,0,0,0,41,41,41,1,10,255,2,7,6,0,0,0,9,2,6,0,0,0,9,2,6
       defb 0,0,0,9,2,2,255,1,9,3,57,57,57,5,1,3,57,57,57,5,1,3,57,57,57,5,255,1,11,10,2,2,2
       defb 13,1,10,2,2,2,13,1,10,2,2,2,13,1,1
       defb 1,11,255,4,24,12,1,1,3,255,0,24,5,1,1,3,255,0,24,5,1,1,3,45,46,41,41,45,46,255,41,15,0,0,0
       defb 5,1,1,3,45,46,9,6,45,46,9,6,69,255,0,14,70,5,1,1,3,45,46,5,3,45,46,5,3,69,255,0,14
       defb 70,5,1,1,3,45,46,5,3,45,46,5,3,0,0,0,255,41,13,5,1,1,3,45,46,5,3,45,46,5,3,255,0,16
       defb 5,1,1,3,45,46,5,3,45,46,5,3,255,0,16,5,1,1,3,45,46,5,3,45,46,5,3,255,41,13,0,0,0
       defb 5,1,1,3,45,46,5,3,0,0,5,3,69,255,0,14,70,5,1,1,3,45,46,5,3,0,0,5,3,69,255,0,14
       defb 70,5,1,1,3,45,46,5,3,51,52,8,7,0,0,0,255,41,13,8,4,1,3,45,46,5,3,255,0,22,1,3,45
       defb 46,5,3,51,52,255,0,20,1,3,45,46,5,3,255,0,22,1,3,45,46,5,3,255,41,22,1,3,45,46,5,10,255,2,22
       defb 1,11,255,4,26,1,3,255,0,26,1,3,255,0,26,1,3,255,0,26,1,3,255,0,26,1,3,255,0,26,1,3,255,0,26
       defb 1,3,255,0,5,255,68,4,0,0,0,255,68,4,0,0,0,255,68,4,0,0,0,1,3,45,46,41,41,41,255,66,4
       defb 0,0,0,255,66,4,0,0,0,255,66,4,0,0,0,1,3,45,46,5,11,255,4,4,7,0,0,0,8,4,4,7,0,0,0
       defb 8,4,4,7,0,0,0,1,3,45,46,5,3,255,0,22,1,3,45,46,5,3,255,0,22,4,7,45,46,5,3,255,0,26
       defb 5,3,255,0,26,5,3,255,0,26,5,3,255,0,22,255,41,4,5,3,255,57,22,255,2,4,13,10,255,2,22
       defb 255,4,26,12,1,255,0,26,5,1,255,0,26,5,1,255,0,26,5,1,255,0,26,5,1,255,0,26,5,1,255,0,26
       defb 5,1,255,0,7,255,68,4,0,0,0,255,68,4,255,0,8,5,1,255,41,4,0,0,0,255,66,4,0,0,0,255,66,4
       defb 0,0,0,41,41,41,45,46,5,1,8,4,4,7,0,0,0,8,4,4,7,0,0,0,8,4,4,7,0,0,0,8,12
       defb 3,45,46,5,1,255,0,22,5,3,45,46,5,1,255,0,22,5,3,45,46,5,1,255,0,22,5,3,45,46,8,4,255,0,22
       defb 5,3,255,0,26,5,3,255,0,26,5,3,255,0,4,255,57,22,5,3,255,41,4,255,2,22,13,10,255,2,4
       defb 14,14,14,25,255,17,8,21,47,48,22,255,17,8,255,14,5,71,71,72,255,0,9,47,48,255,0,9,18,255,14,4,71,71
       defb 72,255,0,9,47,48,255,0,9,18,255,14,4,71,71,72,255,0,9,47,48,255,0,9,18,255,14,4,71,71,72,255,0,9
       defb 47,48,255,0,9,18,255,14,4,71,71,16,255,0,9,47,48,255,0,9,18,255,14,4,71,71,16,255,42,5,255,0,4
       defb 47,48,255,0,4,255,42,5,18,255,14,4,71,71,24,255,19,4,20,255,0,4,47,48,255,0,4,23,255,19,4,255,14,5
       defb 71,71,25,255,17,4,21,255,0,4,47,48,255,0,4,22,255,17,4,255,14,5,71,71,16,255,0,9,47,48,255,0,9
       defb 18,255,14,4,71,71,16,255,0,9,47,48,255,0,9,18,255,14,4,71,71,16,255,0,9,47,48,255,0,9,18,14,14,14
       defb 17,73,73,21,255,0,9,47,48,255,0,9,22,17,17,17,255,0,13,47,48,255,0,26,47,48,255,0,26,47,48,255,0,13
       defb 255,42,28,255,19,28
       defb 14,25,255,17,24,26,14,14,16,62,63,63,255,0,21,18,14,14,16,61,59,59,255,0,21,18,14,14,16,61,59,59,255,0,21
       defb 18,14,14,16,61,59,59,255,0,21,18,14,14,16,255,42,4,0,0,53,54,255,0,8,53,54,0,0,255,42,4,18,14,14
       defb 24,19,19,19,20,255,0,16,23,19,19,19,27,14,14,25,17,17,17,21,255,0,16,22,17,17,17,26,14,14,16,255,0,11
       defb 53,54,255,0,11,18,14,14,16,255,0,24,18,14,14,16,255,0,24,18,14,14,16,255,0,6,53,54,255,0,8,53,54
       defb 255,0,6,18,14,17,21,255,0,24,18,14,255,0,26,18,14,255,0,4,53,54,255,0,7,53,54,255,0,7,53,54,0,0
       defb 18,14,255,0,8,57,0,57,0,57,0,0,57,0,57,0,57,255,0,6,18,14,255,42,26,18,14,255,15,26,27,14
       defb 255,74,24,47,48,74,74,74,255,76,23,47,48,76,74,74,255,0,23,47,48,0,74,74,255,0,26,74,74,255,0,26,74,74
       defb 0,0,0,53,54,255,75,13,47,48,255,75,5,74,74,74,255,0,5,255,74,13,47,48,255,74,8,0,0,0,53,54,74
       defb 255,76,11,74,47,48,255,74,8,255,0,5,74,255,0,11,74,47,48,255,74,8,0,0,0,53,54,74,255,0,11,74,47
       defb 48,255,74,8,255,0,5,74,47,48,255,75,7,0,0,74,47,48,255,74,8,255,75,5,74,47,48,255,74,7,0,0,74
       defb 47,48,255,74,14,47,48,255,76,6,74,0,0,76,47,48,255,74,14,255,0,8,74,255,0,5,255,74,14,255,0,8,74
       defb 255,0,5,255,74,14,255,75,6,47,48,74,255,75,5,255,74,20,47,48,255,74,26,47,48,255,74,13
       defb 255,77,28,255,0,135,255,75,7,255,0,21,76,76,76,255,74,4,75,75,53,54,255,75,7,0,0,0,75,75,75,255,0,7
       defb 255,74,6,0,0,255,76,7,0,0,75,74,74,76,255,0,7,255,74,6,53,54,255,0,9,76,76,76,255,0,8,255,74,6
       defb 255,0,18,255,75,4,255,74,6,53,54,255,0,16,255,76,4,255,74,6,255,0,22,255,74,6,255,75,6,255,0,16,255,74,12
       defb 255,75,4,255,0,12,255,74,16,255,75,10,47,48,255,74,26,47,48,255,74,26,47,48,74,74
       defb 28,38,255,31,24,28,30,28,30,80,80,80,83,255,80,4,83,255,80,4,83,255,80,4,83,255,80,4,83,32,30,28,30
       defb 79,79,79,84,255,79,4,84,255,79,4,84,255,79,4,84,255,79,4,84,32,30,28,30,255,78,24,32,30,28,30,255,0,24
       defb 32,30,28,30,0,0,44,44,255,0,20,32,30,28,30,0,0,36,33,255,0,17,44,44,44,32,30,28,30,0,0,32,30
       defb 255,0,12,44,44,44,0,0,36,29,29,40,30,28,30,0,0,32,30,255,0,7,44,44,44,0,0,35,31,34,0,0,35
       defb 31,31,31,34,28,30,0,0,32,30,45,46,44,44,44,0,0,35,31,34,255,0,12,28,30,0,0,32,30,45,46,35,31
       defb 34,255,0,17,28,30,0,0,32,30,45,46,255,0,20,28,30,0,0,32,30,45,46,255,0,11,45,46,36,29,33,255,75,4
       defb 28,30,0,0,32,30,45,46,255,0,11,45,46,35,31,34,255,76,4,28,30,0,0,32,30,255,0,13,45,46,255,0,7
       defb 28,30,0,0,32,30,255,0,13,45,46,255,0,7,28,30,0,0,32,30,255,44,18,255,75,4,28,30,0,0,32,37,255,29,17
       defb 33,255,74,4
       defb 255,77,28,255,0,90,75,75,255,0,25,75,74,74,255,0,24,75,74,74,74,75,75,255,0,15,75,75,75,255,0,4,255,74,6
       defb 75,255,0,14,74,74,74,255,0,4,255,74,7,75,255,0,7,75,75,53,54,75,75,74,74,74,255,0,4,255,74,8,75
       defb 255,0,6,74,74,0,0,255,74,5,0,0,0,82,255,74,9,81,255,0,5,74,74,53,54,255,74,5,75,75,75,255,74,11
       defb 255,75,5,74,74,0,0,255,74,26,53,54,255,74,5,255,76,21,0,0,255,74,5,255,0,21,53,54,255,74,5,255,0,23
       defb 255,74,5,255,75,23,255,74,33
       defb 255,77,28,255,0,144,82,75,75,81,255,0,24,255,76,4,255,0,84,82,75,81,0,0,82,75,81,255,0,12,75,81,0
       defb 82,75,75,75,255,74,10,75,75,75,81,0,0,82,255,75,4,255,74,21,75,75,255,74,5,255,76,28,255,0,56,255,75,28
       defb 255,74,28
       defb 255,77,28,255,75,11,81,255,0,16,255,74,12,255,0,16,74,255,76,11,255,0,16,74,255,0,27,74,255,0,27,74,255,0,27
       defb 74,255,0,5,255,75,6,255,0,16,76,255,0,5,255,76,4,74,75,81,255,0,22,59,59,64,74,74,75,75,255,0,21
       defb 59,59,64,255,74,4,81,255,0,20,59,59,64,255,74,5,255,75,6,81,0,0,82,255,75,13,255,74,12,75,75,255,74,4
       defb 255,76,28,255,0,56,255,75,28,255,74,28
       defb 28,30,0,0,32,255,28,24,30,0,0,32,255,28,18,38,255,31,4,28,30,0,0,32,255,28,18,30,255,0,4,28,30
       defb 0,0,32,255,28,18,30,255,0,4,28,30,0,0,32,255,28,18,30,255,0,4,28,30,0,0,35,255,31,18,34,45,46
       defb 44,44,28,30,255,0,22,45,46,36,29,28,30,255,0,22,45,46,32,28,28,30,51,52,255,0,20,45,46,32,28,28,30
       defb 69,255,0,22,70,32,28,28,30,69,255,0,22,70,32,28,28,30,255,44,24,32,28,28,37,255,29,24,40,255,28,141
       defb 28,38,255,31,25,39,31,34,0,0,87,255,80,4,83,255,80,4,83,255,80,4,83,255,80,4,83,80,80,32,255,0,4
       defb 88,255,79,4,84,255,79,4,84,255,79,4,84,255,79,4,84,79,79,32,255,0,5,255,78,22,32,255,0,27,32,255,44,7
       defb 255,0,16,44,44,0,0,32,255,29,6,33,255,0,16,36,33,0,0,32,28,28,28,38,31,31,34,255,0,16,32,30,0,0
       defb 32,28,28,28,30,255,0,19,32,30,0,0,32,28,28,28,30,255,0,19,32,30,0,0,32,28,28,28,30,255,0,19,32
       defb 30,0,0,32,28,28,28,30,255,0,19,32,30,0,0,32,28,28,28,30,255,0,19,32,30,0,0,35,28,28,28,30,255,0,19
       defb 32,30,0,0,0,28,28,28,30,255,0,19,32,30,0,0,0,28,28,28,30,255,0,19,32,30,0,0,0,28,28,28,30
       defb 255,86,19,32,30,44,44,44,28,28,28,37,255,29,19,40,37,29,29,29
       defb 28,38,255,31,25,39,28,30,62,63,63,255,0,22,32,28,30,61,59,59,255,0,22,32,28,30,61,59,59,255,0,22,32
       defb 28,30,61,59,59,255,0,22,32,28,30,255,44,5,255,0,20,32,28,37,255,29,4,33,255,0,4,51,52,255,0,4,51
       defb 52,255,0,8,32,28,38,255,31,4,34,255,0,20,32,28,30,255,0,21,255,44,4,32,28,30,255,0,21,36,29,29,29
       defb 40,28,30,255,0,15,44,44,255,0,4,32,255,28,5,30,255,0,15,35,34,255,0,4,32,255,28,4,31,34,255,0,9
       defb 44,44,255,0,10,32,255,28,4,255,0,11,35,34,255,0,10,32,255,28,4,255,0,5,44,44,255,0,16,32,255,28,4
       defb 255,0,5,36,33,255,0,16,32,255,28,4,255,44,5,32,30,255,86,16,32,255,28,4,255,29,5,40,37,255,29,16,40
       defb 255,28,4
       defb 255,77,27,74,255,0,27,74,255,0,27,74,255,0,27,74,255,0,27,74,75,75,75,81,255,0,14,82,75,81,255,0,6
       defb 255,74,5,75,75,0,0,255,75,11,74,74,81,255,0,5,255,74,7,0,0,255,74,13,75,75,53,54,0,0,255,74,7
       defb 57,57,255,74,6,255,76,9,255,0,4,255,74,13,76,76,255,0,9,53,54,0,0,255,74,6,255,76,7,255,0,15,255,74,5
       defb 76,255,0,11,255,75,4,53,54,255,75,5,255,74,5,255,0,12,255,76,4,0,0,255,76,6,255,74,4,255,0,16,53
       defb 54,255,0,6,255,74,4,81,255,0,23,255,74,4,255,75,18,81,255,0,5,255,74,23,255,75,5,255,74,28
       defb 74,74,255,0,11,47,48,255,0,13,74,74,255,0,6,75,255,0,4,47,48,255,0,13,74,74,255,0,6,74,255,0,4
       defb 47,48,255,0,13,74,74,0,0,255,75,4,74,255,0,4,47,48,255,0,13,74,74,0,0,76,74,76,76,76,255,0,4
       defb 47,48,255,0,13,74,74,0,0,0,76,255,0,7,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11
       defb 47,48,255,0,13,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13
       defb 74,76,255,0,11,47,48,255,0,13,76,255,0,12,47,48,255,0,26,47,48,255,0,26,47,48,255,0,26,47,48,255,0,13
       defb 255,75,28,255,74,28
       defb 255,77,30,255,0,26,77,77,255,0,26,77,77,255,0,26,77,77,255,0,26,77,77,255,0,26,77,77,255,0,26,77,77
       defb 255,0,8,75,75,75,47,48,75,75,75,255,0,10,77,77,255,0,8,76,76,74,47,48,74,74,76,255,0,10,81,77,255,0,10
       defb 76,47,48,74,76,255,0,5,75,75,75,0,0,0,74,81,255,0,11,47,48,76,255,0,6,74,74,74,0,0,0,74,74
       defb 255,0,11,47,48,255,0,7,76,76,76,0,0,0,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13
       defb 74,74,255,0,11,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11,47,48,255,0,13,74,74,255,0,11
       defb 47,48,255,0,13
       defb 255,77,28,255,0,9,77,255,0,17,77,255,0,9,77,255,0,17,77,255,0,9,77,255,0,17,77,255,0,9,77,255,0,17
       defb 77,255,0,9,255,77,9,255,0,9,77,255,0,17,77,255,0,9,77,255,0,17,77,255,0,6,255,77,4,255,0,17,255,77,8
       defb 0,0,77,255,0,27,77,255,0,27,82,255,0,27,74,255,0,4,77,77,255,0,21,74,255,0,27,74,255,0,26,82,74
       defb 255,0,11,77,77,255,0,4,77,77,255,0,6,75,75,74,255,0,24,75,74,74,74,255,0,24,255,74,4
       defb 255,0,23,82,255,74,4,255,0,21,82,89,89,255,74,4,255,0,20,75,75,255,89,6,255,0,20,74,74,255,89,6,255,0,20
       defb 74,74,255,89,6,255,0,20,76,255,74,7,255,0,21,255,74,7,255,0,21,255,74,7,255,0,21,76,255,74,6,255,0,22
       defb 76,255,74,5,255,0,23,255,76,5,255,0,75,255,75,9,255,0,14,255,75,5,255,74,9,255,0,9,255,75,5,255,74,14
       defb 255,75,9,255,74,47
       defb 255,74,6,76,255,77,20,255,74,6,76,0,63,63,65,0,75,75,255,0,14,74,89,89,89,76,76,0,0,59,59,64,0
       defb 74,74,75,255,0,13,74,89,89,89,255,0,4,59,59,64,0,74,74,76,255,0,13,74,89,89,89,81,0,0,0,59,59
       defb 64,82,74,74,255,0,14,255,74,5,255,75,6,74,74,76,255,0,14,255,74,11,76,76,255,0,15,255,74,9,76,76,255,0,17
       defb 255,74,7,76,76,255,0,19,255,74,6,76,255,0,21,74,255,76,5,255,0,22,74,255,0,27,74,255,0,27,74,255,75,5
       defb 255,0,22,255,74,6,75,75,75,255,0,19,255,74,9,75,255,0,18,255,74,10,255,75,15,47,48,75,255,74,25,47,48
       defb 74,74
       defb 11,255,4,17,12,11,4,4,4,7,45,46,8,12,3,255,0,17,5,3,67,0,0,0,45,46,0,5,3,255,0,17,5
       defb 3,67,0,0,0,45,46,0,5,3,45,46,9,6,255,41,11,51,52,5,3,67,0,0,0,45,46,0,5,3,45,46,5
       defb 3,255,80,4,83,80,80,87,255,0,5,5,3,67,0,0,0,45,46,0,5,3,45,46,5,3,255,79,4,84,79,79,91
       defb 0,0,0,51,52,5,3,67,0,0,0,45,46,0,5,3,45,46,5,3,255,78,8,255,0,5,5,3,67,255,0,6,5
       defb 3,45,46,5,3,255,0,11,51,52,8,7,67,255,0,6,5,3,45,46,5,3,45,46,255,0,20,5,3,45,46,5,3
       defb 45,46,255,0,20,5,3,45,46,5,3,45,46,255,0,20,5,3,45,46,5,3,45,46,255,0,20,5,3,45,46,5,3
       defb 45,46,255,0,20,5,3,45,46,5,3,45,46,255,0,20,5,3,45,46,5,3,255,0,15,41,255,0,6,5,3,45,46
       defb 5,3,255,0,8,41,41,255,0,12,5,3,45,46,5,3,41,41,41,255,57,5,5,3,255,57,12,5,3,45,46,5,10
       defb 255,2,8,13,10,255,2,12,13
       defb 30,47,48,35,255,31,24,30,47,48,255,0,25,30,47,48,255,0,25,30,47,48,255,0,25,30,255,0,7,44,44,255,0,8
       defb 44,44,255,0,7,41,30,255,0,26,36,30,255,0,26,32,30,0,0,53,54,255,0,8,53,54,255,0,8,53,54,0,0
       defb 32,30,255,0,26,32,30,255,0,26,32,30,255,0,7,44,44,255,0,8,44,44,255,0,7,32,30,255,0,26,32,30,255,0,23
       defb 63,63,65,32,30,0,0,53,54,255,0,8,53,54,255,0,9,60,60,64,32,30,255,0,23,60,60,64,32,30,255,0,23
       defb 60,60,64,32,30,255,41,26,32,37,255,29,26,40
       defb 255,17,27,26,77,255,0,26,18,77,255,0,26,18,77,255,0,26,18,77,255,0,26,18,77,255,0,6,130,131,0,132,133
       defb 0,134,134,0,135,136,0,137,138,255,0,6,18,77,255,0,26,18,77,255,0,26,18,77,255,0,26,18,255,77,27,18,255,0,27
       defb 18,255,0,27,18,255,0,22,63,63,65,0,0,18,255,0,22,59,59,64,0,0,18,255,0,22,59,59,64,0,0,18,255,0,22
       defb 59,59,64,0,0,18,255,42,27,18,15,255,19,26,27
       defb 25,255,17,27,16,255,0,27,16,0,255,120,4,0,255,120,4,0,0,93,95,0,0,0,120,120,120,0,255,120,4,0,0
       defb 16,0,120,255,0,4,120,0,0,120,0,0,92,96,0,0,120,255,0,4,120,255,0,5,16,0,255,120,4,0,255,120,4
       defb 0,93,94,119,95,0,120,255,0,4,120,120,120,0,0,0,16,255,0,4,120,0,120,255,0,4,92,94,119,96,0,120,255,0,4
       defb 120,255,0,5,16,0,255,120,4,0,120,0,0,0,97,94,114,113,119,98,0,120,120,120,0,255,120,4,0,0,16,255,0,9
       defb 97,85,94,94,119,119,118,98,255,0,10,16,255,0,8,97,94,102,94,94,119,119,117,119,98,0,121,122,123,124,125,121,0,0
       defb 16,255,0,10,103,115,111,112,116,110,255,0,11,16,255,0,27,16,255,0,27,16,255,0,27,16,255,77,4,255,0,23,16
       defb 0,126,127,77,255,0,23,16,0,128,129,77,255,0,23,16,255,42,27,24,255,15,27
       defb 255,17,4,26,255,14,18,16,255,77,4,255,0,4,18,25,255,17,17,21,255,0,8,18,16,255,0,17,77,255,0,8,18
       defb 16,0,62,63,63,255,0,13,77,255,0,4,42,42,47,48,18,16,0,61,59,59,255,0,13,77,255,0,4,15,20,47,48
       defb 18,16,0,61,59,59,255,0,13,77,255,0,4,14,16,47,48,18,16,0,61,59,59,255,0,13,77,0,0,0,97,14,16
       defb 47,48,18,16,255,42,5,255,0,4,53,54,0,0,0,100,47,48,77,0,0,97,85,14,16,47,48,18,16,255,0,14,99
       defb 47,48,77,0,97,94,102,14,16,47,48,18,16,255,0,14,99,47,48,77,0,0,0,103,14,16,47,48,18,16,255,0,14
       defb 99,47,48,77,77,100,101,101,14,16,47,48,18,16,255,0,14,99,255,0,7,14,16,47,48,18,16,255,0,14,99,255,0,7
       defb 14,16,47,48,18,16,47,48,42,255,0,11,99,255,0,7,14,16,47,48,18,16,47,48,255,0,12,100,255,42,7,14,16
       defb 47,48,18,16,47,48,255,0,5,53,54,255,0,13,14,16,47,48,18,16,47,48,255,0,20,14,16,47,48,18,16,47,48
       defb 255,0,11,42,42,42,0,0,255,42,4
       defb 14,16,47,48,18,16,47,48,255,0,20,14,16,47,48,18,16,47,48,255,0,20,14,16,47,48,18,16,47,48,255,0,20
       defb 14,16,47,48,18,16,42,42,42,255,0,19,14,16,47,48,18,16,255,0,17,57,255,0,4,14,16,47,48,18,16,255,0,8
       defb 53,54,42,42,42,255,0,4,42,255,0,4,14,16,47,48,18,16,255,0,17,58,255,0,4,14,16,47,48,18,16,0,62
       defb 63,63,255,0,4,53,54,255,0,12,14,16,47,48,18,16,0,61,60,60,255,0,18,14,16,47,48,18,16,0,61,60,60
       defb 255,0,4,53,54,255,0,12,14,16,47,48,18,16,0,61,60,60,255,0,18,14,16,47,48,18,24,255,42,22,25,21,47
       defb 48,22,255,17,23,16,0,47,48,255,0,24,16,0,47,48,255,0,24,16,0,47,48,255,0,24,24,20,255,42,26,14,24
       defb 255,19,26
       defb 255,0,26,18,14,255,0,26,18,14,255,0,26,18,14,255,0,23,42,42,42,18,14,255,0,8,57,255,0,17,18,14,255,42,4
       defb 255,0,4,42,255,0,4,42,42,42,255,0,10,18,14,255,0,8,58,255,0,17,18,14,255,0,26,18,14,255,0,26,18
       defb 14,255,0,26,18,14,255,0,26,18,14,255,42,24,47,48,18,14,255,17,23,21,47,48,22,26,255,0,24,47,48,0,18
       defb 255,0,24,47,48,0,18,255,0,24,47,48,0,18,255,42,26,23,27,255,19,26,27,14
       defb 255,77,8,18,255,14,19,255,0,8,22,255,17,17,26,14,0,93,95,255,0,23,18,14,0,92,96,255,0,19,63,63,65
       defb 0,18,14,93,94,119,95,255,0,18,60,60,64,0,18,14,92,94,119,96,255,42,5,47,48,100,255,0,10,60,60,64,0
       defb 18,14,94,114,113,119,98,255,0,4,47,48,99,255,0,10,60,60,64,0,18,14,94,94,119,119,118,98,0,0,0,47,48
       defb 99,255,0,9,255,42,5,18,14,94,94,119,119,117,119,98,0,0,47,48,99,255,0,14,18,14,115,111,112,116,110,255,0,4
       defb 47,48,100,255,0,14,18,14,255,101,6,100,0,0,47,48,255,0,15,18,14,255,0,9,47,48,255,0,15,18,14,255,0,9
       defb 47,48,255,0,15,18,14,255,0,9,47,48,255,0,15,18,14,255,42,12,255,0,11,42,42,42,18,14,255,0,17,53,54
       defb 255,0,7,18,14,255,0,26,18,14,255,42,13,255,0,13,18,14
       defb 255,28,112,38,255,31,27,30,255,0,27,30,255,0,27,30,0,62,63,63,255,0,23,30,0,61,139,60,255,0,23,30,0
       defb 61,139,60,255,0,23,30,0,61,139,60,255,0,23,30,255,44,27,37,255,29,27,255,28,140
       defb 255,28,12,30,45,46,32,255,28,24,30,45,46,32,255,28,24,30,45,46,32,255,28,24,30,45,46,32,255,28,12,255,31,12
       defb 34,45,46,35,255,31,12,255,0,13,45,46,255,0,26,45,46,255,0,21,149,150,151,152,0,45,46,255,0,97,255,44,28
       defb 255,29,28,255,28,140
       defb 28,28,28,38,255,31,23,39,28,28,28,30,255,0,23,32,28,28,28,30,255,0,23,32,28,28,28,30,255,0,23,32,31,31,31
       defb 34,255,0,23,32,255,0,27,32,255,0,27,32,255,0,4,45,46,255,44,15,255,0,6,32,255,0,4,45,46,36,255,29,13
       defb 33,255,0,6,32,255,0,4,45,46,32,38,255,31,12,34,255,0,6,32,255,0,4,45,46,32,30,255,0,19,32,255,44,6
       defb 32,30,255,0,19,32,255,29,6,40,30,0,62,63,63,255,0,15,32,255,28,7,30,0,61,59,59,255,0,15,32,255,28,7
       defb 30,0,61,59,59,255,0,15,32,255,28,7,30,0,61,59,59,255,0,15,32,255,28,7,30,255,44,19,32,255,28,7,37
       defb 255,29,19,40
       defb 30,45,46,255,0,24,32,30,45,46,255,0,10,255,86,5,255,0,9,32,30,45,46,255,0,10,35,31,31,31,34,255,0,9
       defb 32,30,45,46,255,0,24,32,30,255,0,26,32,30,255,0,26,32,30,255,0,6,53,54,255,0,10,255,44,8,32,30,255,0,18
       defb 35,255,31,7,39,30,255,0,26,32,30,45,46,255,0,10,45,46,255,0,12,32,30,45,46,255,0,10,45,46,255,0,12
       defb 32,30,45,46,255,0,8,86,86,45,46,255,0,12,32,30,45,46,255,0,8,36,33,45,46,255,0,12,32,30,255,0,10
       defb 32,30,45,46,255,0,12,32,30,255,0,10,32,30,45,46,255,0,12,32,30,255,0,10,32,30,45,46,255,0,12,32,30
       defb 255,44,10,32,30,45,46,255,44,12,32,37,255,29,10,40,30,45,46,36,255,29,11,40
       defb 38,255,31,17,39,28,38,255,31,6,39,30,255,0,17,35,31,34,255,0,6,32,30,255,0,26,32,30,255,0,26,32,30
       defb 255,0,26,32,30,255,0,17,149,150,151,153,255,0,5,32,30,255,0,26,32,30,45,46,0,0,0,53,54,0,0,0,36
       defb 33,255,0,5,148,144,145,148,255,0,4,36,40,30,45,46,255,0,8,32,30,255,0,5,140,0,0,143,255,0,4,32,28
       defb 30,45,46,255,0,8,35,34,255,0,5,141,0,0,142,255,0,4,35,39,30,45,46,255,0,15,148,147,146,148,255,0,5
       defb 32,30,45,46,255,0,24,32,30,45,46,255,0,24,32,30,45,46,255,0,10,53,54,255,0,12,32,30,45,46,255,0,24
       defb 32,30,45,46,255,0,15,36,29,33,255,0,6,32,30,45,46,255,0,15,35,31,34,255,0,6,32,30,45,46,255,0,24
       defb 32
       defb 77,255,0,11,255,77,13,255,0,14,77,0,93,95,255,0,26,92,96,255,0,25,93,94,119,95,255,0,24,92,94,119,96
       defb 255,0,23,97,94,114,113,119,98,255,0,21,97,85,94,94,119,119,118,98,255,0,19,97,94,102,94,94,119,119,117,119,98
       defb 255,0,20,103,115,111,112,116,110,255,0,24,139,139,255,0,8,77,0,0,77,255,0,14,139,139,255,0,8,77,0,0,77
       defb 255,0,13,255,139,4,255,0,7,77,0,0,77,255,0,13,255,139,4,255,0,7,77,0,0,77,255,0,13,255,139,4,255,0,7
       defb 77,0,0,77,255,0,12,255,139,6,255,0,6,77,0,0,77,255,0,12,255,139,6,255,0,6,77,0,0,77,255,0,11
       defb 255,139,8,255,0,5,255,77,4,255,0,10,255,139,10,255,0,4,255,77,5
numsc  defb 39
nmedat defb 0,0,120,45,255
       defb 0,2,88,75,1,3,40,45,255
       defb 0,2,40,25,2,4,80,120,255
       defb 0,2,112,75,1,3,56,75,255
       defb 0,1,56,135,3,4,32,40,255
       defb 0,2,24,20,2,5,40,110,2,5,40,85,1,3,120,65,2,5,88,100,2,5,88,75,255
       defb 0,0,120,15,255
       defb 0,0,56,15,5,4,104,30,5,5,32,65,255
       defb 0,0,120,15,5,4,24,60,5,4,112,90,255
       defb 0,0,120,15,4,6,32,75,4,6,88,75,255
       defb 0,2,120,75,2,4,24,75,255
       defb 0,2,120,130,1,3,48,60,5,4,16,75,5,5,104,105,255
       defb 0,1,88,135,8,8,120,130,5,5,104,65,5,5,80,90,5,5,56,115,255
       defb 0,1,40,135,4,6,16,40,255
       defb 0,1,80,135,6,9,8,95,6,9,40,60,255
       defb 0,1,80,135,6,9,24,100,2,4,56,75,2,4,48,20,255
       defb 0,0,56,20,2,4,80,50,2,5,80,95,255
       defb 0,0,32,15,5,4,56,50,5,4,80,75,5,4,104,100,255
       defb 0,0,120,15,5,5,64,80,5,4,80,50,5,4,48,110,255
       defb 0,0,32,15,5,4,56,40,1,3,40,80,5,4,24,135,1,3,112,40,255
       defb 0,0,120,15,255
       defb 0,2,56,75,255
       defb 4,6,32,100,0,10,16,15,255
       defb 0,0,120,15,8,8,96,125,8,8,96,135,5,4,56,65,255
       defb 0,0,96,15,1,3,120,95,3,4,80,70,4,6,64,115,3,5,104,125,255
       defb 0,2,16,130,5,5,72,75,5,4,96,55,255
       defb 0,2,16,15,3,4,80,125,3,4,16,75,3,4,72,85,3,4,112,50,255
       defb 0,0,120,15,4,6,16,135,4,6,16,15,255
       defb 0,0,120,75,255
       defb 0,2,120,40,4,6,64,100,255
       defb 0,11,80,135,1,3,120,80,3,4,16,95,3,4,64,95,255
       defb 0,10,120,15,1,3,120,70,7,6,80,100,7,6,80,40,255
       defb 0,10,128,15,3,4,32,95,3,4,88,75,3,4,64,95,3,4,88,120,255
       defb 0,10,80,40,3,4,48,125,3,5,56,70,4,6,56,100,255
       defb 0,10,80,20,1,3,80,135,5,5,48,60,5,5,64,90,5,4,64,105,5,4,48,40,255
       defb 0,10,80,15,4,6,88,50,4,6,120,135,255
       defb 0,2,128,75,2,5,40,75,1,3,120,35,5,4,96,105,255
       defb 0,2,120,15,4,6,24,105,4,6,112,100,8,12,72,105,5,4,40,55,5,5,72,30,255
       defb 0,13,120,130,3,6,136,70,3,6,136,80,3,6,136,75,3,6,136,65,3,6,136,85,3,9,120,75,3,6,136,60,3,6,136,90,3,9,120,80,3,9,120,70,3,8,104,75,255
NUMOBJ equ 23
objdta equ $
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 0,120,75,0,120,75
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 10,80,15,10,80,15
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 4,104,40,4,104,40
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 8,40,40,8,40,40
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 8,40,110,8,40,110
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 11,72,125,11,72,125
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 14,80,35,14,80,35
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 13,24,40,13,24,40
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 16,80,75,16,80,75
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 19,112,40,19,112,40
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 21,48,85,21,48,85
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 25,112,75,25,112,75
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 31,16,125,31,16,125
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 32,104,125,32,104,125
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 7,56,120,7,56,120
       defb 0,0,0,0,0,85,255,170,0,170,0,170,0,170,170,170
       defb 0,170,170,170,0,255,170,170,0,255,170,170,0,255,255,170
       defb 0,170,0,170,0,255,255,170,0,255,255,170,0,255,255,170
       defb 0,255,255,170,0,0,0,0,0,0,0,0,0,0,0,0
       defb 9,32,125,9,32,125
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,85,0,255,255,255,170,255,255,255,255
       defb 85,255,255,170,0,255,0,0,85,170,0,0,85,170,0,0
       defb 85,170,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 18,56,130,18,56,130
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,85,0,0,0,0,0,0,0
       defb 8,48,15,8,48,15
       defb 0,0,0,0,0,255,170,0,0,170,255,0,0,170,255,0
       defb 0,255,170,0,170,0,0,170,85,255,170,85,170,255,255,170
       defb 85,255,255,85,170,255,255,170,0,85,170,0,0,85,170,0
       defb 0,255,170,0,0,255,170,0,0,0,0,0,0,0,0,0
       defb 20,16,35,20,16,35
       defb 0,0,0,0,0,255,170,0,0,170,255,0,0,170,255,0
       defb 0,255,170,0,170,0,0,170,85,255,170,85,170,255,255,170
       defb 85,255,255,85,170,255,255,170,0,85,170,0,0,85,170,0
       defb 0,255,170,0,0,255,170,0,0,0,0,0,0,0,0,0
       defb 12,40,130,12,40,130
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
       defb 38,96,130,38,96,130
       defb 0,0,0,0,0,0,0,85,0,0,0,85,0,0,0,170
       defb 0,0,0,85,255,255,255,255,170,170,255,0,255,0,255,0
       defb 170,170,255,0,255,255,255,85,0,0,0,85,0,0,0,170
       defb 0,0,0,85,0,0,0,85,0,0,0,0,0,0,0,0
       defb 32,32,25,32,32,25
       defb 0,255,255,0,85,255,255,170,170,255,255,255,255,255,255,255
       defb 170,255,255,255,255,255,255,255,255,170,255,85,85,255,255,170
       defb 0,255,255,0,0,0,0,0,0,255,255,0,0,255,255,0
       defb 0,170,85,0,85,255,255,170,85,170,85,170,85,170,85,170
       defb 36,120,130,36,120,130
palett equ $
       defb 0,2,6,8,18,20,24,26,0,5,15,7,24,11,16,25
font   equ $
       defb 0,0,0,0,0,0,0,0
       defb 0,0,16,16,16,0,16,0
       defb 0,108,108,0,0,0,0,0
       defb 0,108,254,108,108,254,108,0
       defb 0,24,126,120,126,30,126,24
       defb 0,230,236,24,48,110,206,0
       defb 0,48,120,48,126,204,126,0
       defb 0,24,48,0,0,0,0,0
       defb 0,12,24,24,24,24,12,0
       defb 0,96,48,48,48,48,96,0
       defb 0,0,60,24,126,24,60,0
       defb 0,0,24,24,126,24,24,0
       defb 0,0,0,0,0,24,24,48
       defb 0,0,0,0,126,0,0,0
       defb 0,0,0,0,0,56,56,0
       defb 0,0,6,12,24,48,96,0
       defb 0,0,127,65,65,65,127,0
       defb 0,0,24,56,8,8,127,0
       defb 0,0,127,1,127,64,127,0
       defb 0,0,127,1,61,1,127,0
       defb 0,0,66,66,66,127,2,0
       defb 0,0,127,64,127,1,127,0
       defb 0,0,127,64,127,65,127,0
       defb 0,0,127,1,2,4,8,0
       defb 0,0,127,65,127,65,127,0
       defb 0,0,127,65,127,1,127,0
       defb 0,0,0,48,0,0,48,0
       defb 0,0,48,0,0,48,48,96
       defb 0,0,12,24,48,24,12,0
       defb 0,0,0,126,0,126,0,0
       defb 0,0,48,24,12,24,48,0
       defb 0,124,198,12,24,0,24,0
       defb 0,124,222,254,254,192,124,0
       defb 0,0,127,65,95,65,65,0
       defb 0,0,126,66,95,65,127,0
       defb 0,0,127,64,64,64,127,0
       defb 0,0,126,65,65,65,126,0
       defb 0,0,127,64,94,64,127,0
       defb 0,0,127,64,94,64,64,0
       defb 0,0,127,64,67,65,127,0
       defb 0,0,65,65,95,65,65,0
       defb 0,0,8,8,8,8,8,0
       defb 0,0,1,1,1,65,127,0
       defb 0,0,65,66,92,66,65,0
       defb 0,0,64,64,64,64,127,0
       defb 0,0,65,99,85,73,65,0
       defb 0,0,65,81,73,69,65,0
       defb 0,0,127,65,65,65,127,0
       defb 0,0,127,65,95,64,64,0
       defb 0,0,127,65,69,67,127,0
       defb 0,0,127,65,127,72,71,0
       defb 0,0,127,64,127,1,127,0
       defb 0,0,127,0,8,8,8,0
       defb 0,0,65,65,65,65,127,0
       defb 0,0,65,65,34,20,8,0
       defb 0,0,65,73,73,85,34,0
       defb 0,0,65,34,28,34,65,0
       defb 0,0,65,34,20,8,8,0
       defb 0,0,127,2,28,32,127,0
       defb 0,30,24,24,24,24,30,0
       defb 0,0,192,96,48,24,12,0
       defb 0,240,48,48,48,48,240,0
       defb 0,48,120,252,48,48,48,0
       defb 0,0,0,0,0,0,0,255
       defb 0,60,102,248,96,96,254,0
       defb 0,0,120,12,124,204,124,0
       defb 0,96,96,124,102,102,124,0
       defb 0,0,60,96,96,96,60,0
       defb 0,12,12,124,204,204,124,0
       defb 0,0,120,204,248,192,124,0
       defb 0,28,48,56,48,48,48,0
       defb 0,0,124,204,204,124,12,120
       defb 0,192,192,248,204,204,204,0
       defb 0,48,0,112,48,48,120,0
       defb 0,12,0,12,12,12,108,56
       defb 0,96,120,112,112,120,108,0
       defb 0,48,48,48,48,48,28,0
       defb 0,0,248,252,252,252,252,0
       defb 0,0,248,204,204,204,204,0
       defb 0,0,120,204,204,204,120,0
       defb 0,0,248,204,204,248,192,192
       defb 0,0,124,204,204,124,12,14
       defb 0,0,60,96,96,96,96,0
       defb 0,0,120,192,120,12,248,0
       defb 0,48,120,48,48,48,28,0
       defb 0,0,204,204,204,204,120,0
       defb 0,0,204,204,120,120,48,0
       defb 0,0,204,252,252,252,120,0
       defb 0,0,204,120,48,120,204,0
       defb 0,0,204,204,204,124,12,120
       defb 0,0,252,24,48,96,252,0
       defb 0,30,24,112,24,24,30,0
       defb 0,24,24,24,24,24,24,0
       defb 0,240,48,28,48,48,240,0
       defb 0,60,120,0,0,0,0,0
       defb 124,198,187,227,227,187,198,124
jtab   equ $
       defb 99
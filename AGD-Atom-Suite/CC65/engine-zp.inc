;----------------------------------------------------------------------
; AGD 6502 Engine Zero Page Variables
;----------------------------------------------------------------------

; Variables start here.

scno:	.res 1			; present screen number.
numlif:	.res 1			; number of lives.

vara:	.res 1			; general-purpose variable.
varb:	.res 1			; general-purpose variable.
varc:	.res 1			; general-purpose variable.
vard:	.res 1			; general-purpose variable.
vare:	.res 1			; general-purpose variable.
varf:	.res 1			; general-purpose variable.
varg:	.res 1			; general-purpose variable.
varh:	.res 1			; general-purpose variable.
vari:	.res 1			; general-purpose variable.
varj:	.res 1			; general-purpose variable.
vark:	.res 1			; general-purpose variable.
varl:	.res 1			; general-purpose variable.
varm:	.res 1			; general-purpose variable.
varn:	.res 1			; general-purpose variable.
varo:	.res 1			; general-purpose variable.
varp:	.res 1			; general-purpose variable.
varq:	.res 1			; general-purpose variable.
varr:	.res 1			; general-purpose variable.
vars:	.res 1			; general-purpose variable.
vart:	.res 1			; general-purpose variable.
varu:	.res 1			; general-purpose variable.
varv:	.res 1			; general-purpose variable.
varw:	.res 1			; general-purpose variable.
varz:	.res 1			; general-purpose variable.

charx:	.res 1			; cursor x position.
chary:	.res 1			; cursor y position.

clock:	.res 1			; last clock reading.
varrnd:	.res 1	        	; last random number.
varobj:	.res 1  	   	; last object number.
varopt:	.res 1     		; last option chosen from menu.
varblk:	.res 1  		; block type.
nexlev:	.res 1			; next level flag.
restfl:	.res 1			; restart screen flag.
deadf:	.res 1			; dead flag.
gamwon:	.res 1			; game won flag.
dispx:	.res 1			; cursor x position.
dispy:	.res 1			; cursor y position.

contrl:	.res 1			; control = keyboard, 1 = Kempston, 2 = Sinclair, 3 = Mouse.
joyval:	.res 1			; joystick reading.
frmno:	.res 1			; selected frame.

;----------------------------------------------------
; Missing vars 
;----------------------------------------------------

loopa:	    .res 1
loopb:	    .res 1
loopc:	    .res 1
FontPtr:    .res 2

; Local vars

scraddr:    .res 2
fntaddr:    .res 2
tileaddr:   .res 2
bufaddr:    .res 2
advbuff:    .res 2

tmp:        .res 2
scr_l:      .res 2
scr_r:      .res 2
scr_txt:    .res 2

xtmp:	    .res 1
ytmp:	    .res 1
spcnt:	    .res 1
spptr:	    .res 2		; spawned sprite pointer.
seed:	    .res 1		; seed for random numbers.

ccnt:       .res 1
flag:	    .res 1
rcol:	    .res 1
rrow:	    .res 1

combyt:	    .res 1		; byte type compressed.
comcnt:	    .res 1		; compression counter.
prtmod:	    .res 1      	; print mode, 0 = standard, 1 = double-height.
qscnt:	    .res 1

sprptr:	    .res 1      	; not a ptr
sprcnt:	    .res 1

skptr:	    .res 2		; search pointer.
sktptr:	    .res 1      	; not a ptr
tmproom:    .res 1
ogptr:	    .res 2		; original sprite pointer.

.if mflag
TmpAddr:    .res 2
bwid:	    .res 1     		; box/menu width.
blen:	    .res 1     		; box/menu height.
btop:	    .res 1    	 	; box coordinates.
blft:	    .res 1
.endif

.if sflag .or pflag
shrctr:	    .res 1
.endif
.if pflag
explcnt:    .res 1
seed3:	    .res 1
.endif

.if aflag
pbptr:       .res 2
pbbuf:	     .res 2
.endif

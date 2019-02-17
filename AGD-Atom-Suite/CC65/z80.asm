;------------------------------------------------------
; z80.asm
; spectrum stuff
; adresses


; Contains seperatly 1 bit set

_bitmem0	= $f8
_bitmem1	= $f9
_bitmem2	= $fa
_bitmem3	= $fb
_bitmem4	= $fc
_bitmem5	= $fd
_bitmem6	= $fe
_bitmem7	= $ff
	
; constants	
_bitvalue0	= $01	
_bitvalue1	= $02	
_bitvalue2	= $04	
_bitvalue3	= $08	
_bitvalue4	= $10	
_bitvalue5	= $20	
_bitvalue6	= $40	
_bitvalue7	= $80	

_notbitvalue0	= $fe	
_notbitvalue1	= $fd	
_notbitvalue2	= $fb	
_notbitvalue3	= $f7	
_notbitvalue4	= $ef	
_notbitvalue5	= $df	
_notbitvalue6	= $bf	
_notbitvalue7	= $7f	


exx:
		lda z80_c
		ldy z80_cp
		sty z80_c
		sta z80_cp
		lda z80_b
		ldy z80_bp
		sty z80_b
		sta z80_bp
		lda z80_e
		ldy z80_ep
		sty z80_e
		sta z80_ep
		lda z80_d
		ldy z80_dp
		sty z80_d
		sta z80_dp		
		lda scraddr
		ldy z80_lp
		sty scraddr
		sta z80_lp
		lda scraddr+1
		ldy z80_hp
		sty scraddr+1
		sta z80_hp
		rts
		

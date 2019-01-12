;------------------------------------------------------
; z80.asm
; spectrum stuff
; adresses

;ws	 = $60

;z80_f	 = ws+$00
;z80_a	 = ws+$01
;z80_af	 = z80_f

;z80_c	 = ws+$02
;z80_b	 = ws+$03
;z80_bc	 = z80_c

;z80_e	 = ws+$04
;z80_d	 = ws+$05
;z80_de	 = z80_e

;z80_l	 = ws+$06
;z80_h	 = ws+$07
;z80_hl	 = z80_l

;z80_x    = ws+$08
;z80_i    = ws+$09
;z80_ix	 = z80_x

;z80_iy	 = ws+$0a

;z80_fp	 = ws+$0c
;z80_ap	 = ws+$0d

;z80_cp	 = ws+$0e
;z80_bp	 = ws+$0f
;z80_bcp = z80_cp

;z80_ep	 = ws+$10
;z80_dp	 = ws+$11
;z80_dep = z80_ep

;z80_lp	 = ws+$12
;z80_hp	 = ws+$13
;z80_hlp = z80_lp

;z80_sp   = ws+$14

;z80_reg0 = ws+$16
;z80_reg1 = ws+$17
;z80_reg2 = ws+$18
;z80_reg3 = ws+$19

;z80_r	 = ws+$1a

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


;add_hl_bc:
;		lda z80_l
;		clc
;		adc z80_c
;		sta z80_l
;		lda z80_h
;		adc z80_b
;		sta z80_h
;		rts
;		
;add_ix_de:
;		lda z80_ix
;		clc
;		adc z80_e
;		sta z80_ix
;		lda z80_ix+1
;		adc z80_d
;		sta z80_ix+1
;		rts
;		
;add_iy_de:
;		lda z80_iy
;		clc
;		adc z80_e
;		sta z80_iy
;		lda z80_iy+1
;		adc z80_d
;		sta z80_iy+1
;		rts
;		
;add_hl_de:
;		lda z80_l
;		clc
;		adc z80_e
;		sta z80_l
;		lda z80_h
;		adc z80_d
;		sta z80_h
;		rts
;
;add_ix_bc:
;		lda z80_ix
;		clc
;		adc z80_c
;		sta z80_ix
;		lda z80_ix+1
;		adc z80_b
;		sta z80_ix+1
;		rts
;		
;add_iy_bc:
;		lda z80_iy
;		clc
;		adc z80_c
;		sta z80_iy
;		lda z80_iy+1
;		adc z80_b
;		sta z80_iy+1
;		rts
;		
;sbc_hl_de:
;		lda z80_l
;		sbc z80_e
;		sta z80_l
;		lda z80_h
;		sbc z80_d
;		sta z80_h
;		rts
;
;sbc_hl_bc:
;		lda z80_l
;		sbc z80_c
;		sta z80_l
;		lda z80_h
;		sbc z80_b
;		sta z80_h
;		rts
;
;cmp_hl_bc:
;		lda z80_l
;		cmp z80_c
;		bne cmp_hl_bc_end
;		lda z80_h
;		cmp z80_b
;cmp_hl_bc_end:
;		rts
;		
;cmp_iy_ix:
;		lda z80_iy
;		cmp z80_ix
;		bne cmp_iy_ix_end
;		lda z80_iy+1
;		cmp z80_ix+1
;cmp_iy_ix_end:
;		rts
;		
;dec_hl:
;		lda z80_l
;		bne dec_hl_no_dec_h
;		dec z80_h
;dec_hl_no_dec_h:
;		dec z80_l
;		rts
;	
;dec_ix:
;		lda z80_ix
;		bne dec_ix_no_dec_h
;		dec z80_ix+1
;dec_ix_no_dec_h:
;		dec z80_ix
;		rts
;		
;dec_bc:	
;		lda z80_c
;		bne dec_bc_no_dec_b
;		dec z80_b
;dec_bc_no_dec_b:
;		dec z80_c
;		rts
;	
;dec_de:
;		lda z80_e
;		bne dec_de_no_dec_d
;		dec z80_d
;dec_de_no_dec_d:
;		dec z80_e
;		rts
;		
;ex_af_afs:
;	rts
;ex_de_hl:
;		lda z80_e
;		ldx z80_l
;		stx z80_e
;		sta z80_l
;		lda z80_d
;		ldx z80_h
;		stx z80_d
;		sta z80_h
;		rts
;
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
		
;ex_sp_hl:
;		tsx
;		lda $0103,x
;		ldy z80_h
;		sta z80_h
;		tya
;		sta $0103,x
;		lda $0104,x
;		ldy z80_l
;		sta z80_l
;		tya
;		sta $104,x
;		rts
;		
;ldi:
;	rts
;ldir:
;		ldy #$00
;		ldx z80_b
;		beq ldir_last_page
;ldir_loop:		
;		lda (z80_hl),y
;		sta (z80_de),y
;		iny
;		bne ldir_loop
;		inc z80_h
;		inc z80_d
;		dex
;		bne ldir_loop
;ldir_last_page:
;		lda z80_c
;		beq ldir_end
;ldir_last_page_loop:		
;		lda (z80_hl),y
;		sta (z80_de),y
;		iny
;		cpy z80_c
;		bne ldir_last_page_loop
;ldir_end:		
;		stx z80_c
;		stx z80_b
;		tya
;		clc
;		adc z80_l
;		sta z80_l
;		bcc *+4
;		inc z80_h
;		tya
;		clc
;		adc z80_e
;		sta z80_e
;		bcc *+4
;		inc z80_d
;		rts
;		
;lddr:		ldy #$00
;lddr_loop:
;		lda (z80_hl),y
;		sta (z80_de),y
;		jsr dec_hl
;		jsr dec_de
;		jsr dec_bc
;		lda z80_b
;		ora z80_c
;		bne lddr_loop
;		rts
;ei:
;		rts
;di:
;		rts
		
;-------------------------------------------------------------
; Set bits in bitmem
;-------------------------------------------------------------
	
;z80_init:
;	ldx #$00
;	lda #$01
;z80_init_loop:		
;	sta _bitmem0,x
;	inx
;	asl a
;	bne z80_init_loop
;	rts

push_af:
push_bc:
push_de:
push_hl:

pop_af:
pop_bc:
pop_de:
pop_ix:
pop_hl:

add_hl_hl:

inc_bc:
inc_de:
inc_hl:
inc_ix:
inc_sp:

cpir:

ex_af_af:
;	rts
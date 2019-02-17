;----------------------------------------------
; Common AGD engine
; Z80 conversion by Kees van Oss 2017
;----------------------------------------------
	.DEFINE asm_code $0300
	.DEFINE header   1		; Header Wouter Ras emulator
	.DEFINE filenaam "AGD"

	.include "game.cfg" 

.segment "ZEROPAGE"
	.include "z80-zp.inc"
	.include "engine-zp.inc"

.segment "CODE"

.if header
;********************************************************************
; ATM Header for Atom emulator Wouter Ras

.org asm_code-22*header
name_start:
	.byte filenaam			; Filename
name_end:
	.repeat 16-name_end+name_start	; Fill with 0 till 16 chars
	  .byte $0
	.endrep

	.word asm_code			; 2 bytes startaddress
	.word exec			; 2 bytes linkaddress
	.word eind_asm-start_asm	; 2 bytes filelength

;********************************************************************
.else
.org asm_code
.endif

exec:
start_asm:
	.include "game.inc"
	.include "z80.asm"
eind_asm:
eop:					; End Of Program

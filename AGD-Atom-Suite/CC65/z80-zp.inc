;.segment "ZEROPAGE"

ws	 = $60

z80_f	 = ws+$00
z80_a	 = ws+$01
z80_af	 = z80_f

z80_c	 = ws+$02
z80_b	 = ws+$03
z80_bc	 = z80_c

z80_e	 = ws+$04
z80_d	 = ws+$05
z80_de	 = z80_e

z80_l	 = ws+$06
z80_h	 = ws+$07
z80_hl	 = z80_l

z80_x    = ws+$08
z80_i    = ws+$09
z80_ix	 = z80_x

z80_iy	 = ws+$0a

z80_fp	 = ws+$0c
z80_ap	 = ws+$0d

z80_cp	 = ws+$0e
z80_bp	 = ws+$0f
z80_bcp	 = z80_cp

z80_ep	 = ws+$10
z80_dp	 = ws+$11
z80_dep	 = z80_ep

z80_lp	 = ws+$12
z80_hp	 = ws+$13
z80_hlp	 = z80_lp

z80_sp   = ws+$14

z80_reg0 = ws+$16
z80_reg1 = ws+$17
z80_reg2 = ws+$18
z80_reg3 = ws+$19

z80_r	 = ws+$1a


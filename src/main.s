.include "libSFX.i"
.include "macros.inc"
.debuginfo

; top and bottom of play area
PLAY_AREA_TOP    = 30
PLAY_AREA_BOTTOM = 220

; starting Y coordinate
CHARACTER_START_YPOS: .word 100

; this enum is used to represent the state of character animations
.enum E_CHAR_ANIM_STATE
	STANDING_STILL ; standing still, staring with empty lifeless eyes at their brother....
	MOVING_UP_F1   ; moving up,   frame 1
	MOVING_UP_F2   ; moving up,   frame 2
	MOVING_DOWN_F1 ; moving down, frame 1
	MOVING_DOWN_F2 ; moving down, frame 2
	KICKING_SHELL  ; kicking the shell
.endenum

.struct S_CHAR_SPRITES
	STANDING_STILL .word
	MOVING_UP_F1   .word
	MOVING_UP_F2   .word
	MOVING_DOWN_F1 .word
	MOVING_DOWN_F2 .word
	KICKING_SHELL  .word
.endstruct

; this struct represents the current state of a character
.struct S_CHAR_STATE
	Y_POS      .word ; current Y coordinate
	CUR_STATE  .word ; the current animation state
	CUR_SPRITE .word ; the ID of the sprite tile to use
.endstruct

Main:
	load_spriteset mario_sprites_tiles, mario_sprites_palette ; load mario_sprites
	load_bg bg01_map, bg01_tiles, bg01_palette    ; load bg01

	setup_screen
	; stupid voodoo hack
	OAM_init shadow_oam,   0, 0, 0 
	OAM_init shadow_oam+4, 0, 0, 1

	; setup initial states of the 2 characters
	lda CHARACTER_START_YPOS
	sta MARIO_STATE+S_CHAR_STATE::Y_POS
	sta LUIGI_STATE+S_CHAR_STATE::Y_POS

	lda E_CHAR_ANIM_STATE::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE

	lda MARIO_SPRITES+S_CHAR_SPRITES::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE

	lda LUIGI_SPRITES+S_CHAR_SPRITES::STANDING_STILL
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE

	; set Vblank handler
	VBL_set VBL

	screen_on



loop:
	jmp loop

update_players:
	lda MARIO_STATE+S_CHAR_STATE::Y_POS
	inc
	sta MARIO_STATE+S_CHAR_STATE::Y_POS


	lda LUIGI_STATE+S_CHAR_STATE::Y_POS
	dec
	sta LUIGI_STATE+S_CHAR_STATE::Y_POS
	rts

VBL:
	jsr update_players
	sprite_update 00, #10,  MARIO_STATE+S_CHAR_STATE::Y_POS, MARIO_STATE+S_CHAR_STATE::CUR_SPRITE, 1
	sprite_update 01, #230, LUIGI_STATE+S_CHAR_STATE::Y_POS, LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE, 1
;	sprite_update 16, #120, #100, #SHELL, 1

	render_sprites

	rtl

.segment "ZEROPAGE"

MARIO_STATE: .tag S_CHAR_STATE
LUIGI_STATE: .tag S_CHAR_STATE

.segment "LORAM"
shadow_oam: .res 512+32

.segment "RODATA"
; sprite tile ID data, see definition of S_CHAR_SPRITES struct above

MARIO_SPRITES:
	.word 38 ; STANDING_STILL
	.word 34 ; MOVING_UP_F1
	.word 14 ; MOVING_UP_F2
	.word 12 ; MOVING_DOWN_F1
	.word 31 ; MOVING_DOWN_F2
	.word 36 ; KICKING_SHELL

LUIGI_SPRITES:
	.word 08 ; STANDING_STILL
	.word 02 ; MOVING_UP_F1
	.word 06 ; MOVING_UP_F2
	.word 00 ; MOVING_DOWN_F1
	.word 04 ; MOVING_DOWN_F2
	.word 10 ; KICKING_SHELL


; the background image
incbin bg01_palette, "data/bg01.png.palette"
incbin bg01_tiles,   "data/bg01.png.tiles.lz4"
incbin bg01_map,     "data/bg01.png.map.lz4"

; mario_sprites animation
incbin mario_sprites_tiles,      "data/mario_sprites.png.tiles.lz4"
incbin mario_sprites_palette,    "data/mario_sprites.png.palette"

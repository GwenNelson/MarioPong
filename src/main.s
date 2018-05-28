.include "libSFX.i"
.include "macros.inc"
.debuginfo



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
	Y_POS                .word ; current Y coordinate
	CUR_STATE            .word ; the current animation state
	CUR_SPRITE           .word ; the ID of the sprite tile to use
.endstruct

.segment "ZEROPAGE"

; "instances" of the S_CHAR_STATE struct
MARIO_STATE: .tag S_CHAR_STATE
LUIGI_STATE: .tag S_CHAR_STATE

.segment "CODE"

Main:
	load_spriteset mario_sprites_tiles, mario_sprites_palette ; load mario_sprites
	load_bg bg01_map, bg01_tiles, bg01_palette    ; load bg01

	setup_screen
	; stupid voodoo hack
	OAM_init shadow_oam,   0, 0, 0 
;	OAM_init shadow_oam+4, 0, 0, 1

	; setup player states
	jsr init_players

	; set Vblank handler
	VBL_set VBL

	screen_on

loop:
	jmp loop

init_players:
	; setup initial states of the 2 characters

	; Y coordinate first
	lda CHARACTER_START_YPOS
	sta MARIO_STATE+S_CHAR_STATE::Y_POS
	sta LUIGI_STATE+S_CHAR_STATE::Y_POS

	; then set the animation state to standing still
	lda E_CHAR_ANIM_STATE::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE

	; then set the sprites appropriately, mario first
	lda MARIO_SPRITES+S_CHAR_SPRITES::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE

	; luigi standing still
	lda LUIGI_SPRITES+S_CHAR_SPRITES::STANDING_STILL
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE

	rts

update_luigi_moving_up:
	; first check if we're too close to the top
	lda LUIGI_STATE+S_CHAR_STATE::Y_POS
	cmp PLAY_AREA_TOP
	bne :+

	; if we end up here, we need to switch to moving down state, so let's do so and then return
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	rts
:
	; otherwise, move up 1 pixel and then flip the frame
	; move up 1 pixel first
	lda LUIGI_STATE+S_CHAR_STATE::Y_POS
	dec
	sta LUIGI_STATE+S_CHAR_STATE::Y_POS

	; now the frame flip
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	cmp LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	bne :+

	; if we end up here, we need to flip to the F2 frame
	lda E_CHAR_ANIM_STATE::MOVING_UP_F2
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_UP_F2
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

:	; if we end up here, we need to flip to the F1 frame
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

update_luigi_moving_down:
	; first check if we're too close to the top
	lda LUIGI_STATE+S_CHAR_STATE::Y_POS
	cmp PLAY_AREA_BOTTOM
	bne :+

	; if we end up here, we need to switch to moving up state, so let's do so and then return
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	rts
:
	; otherwise, move up 1 pixel and then flip the frame
	; move up 1 pixel first
	lda LUIGI_STATE+S_CHAR_STATE::Y_POS
	inc
	sta LUIGI_STATE+S_CHAR_STATE::Y_POS

	; now the frame flip
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	cmp LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	bne :+

	; if we end up here, we need to flip to the F2 frame
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F2
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

:	; if we end up here, we need to flip to the F1 frame
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	rts


update_luigi_still:
	; if luigi is standing still, start him moving up
	lda LUIGI_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta LUIGI_STATE+S_CHAR_STATE::CUR_STATE

	rts

update_luigi:
	; first we check the current state and jump to the correct routine
	lda LUIGI_STATE+S_CHAR_STATE::CUR_STATE

	cmp E_CHAR_ANIM_STATE::STANDING_STILL
	bne :+
	jmp update_luigi_still
:

	cmp E_CHAR_ANIM_STATE::MOVING_UP_F1
	bne :+
	jmp update_luigi_moving_up
:	cmp E_CHAR_ANIM_STATE::MOVING_UP_F2
	bne :+
	jmp update_luigi_moving_up
:

	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	bne :+
	jmp update_luigi_moving_down
:	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	bne :+
	jmp update_luigi_moving_down
:


	rts

update_players:
	jsr update_luigi
	rts

VBL:
	jsr update_players
	sprite_update 00, #10,  MARIO_STATE+S_CHAR_STATE::Y_POS, MARIO_STATE+S_CHAR_STATE::CUR_SPRITE, 1
	sprite_update 01, #230, LUIGI_STATE+S_CHAR_STATE::Y_POS, LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE, 1
;	sprite_update 16, #120, #100, #SHELL, 1

	render_sprites

	rtl



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


; top and bottom of play area
PLAY_AREA_TOP:    .word 30
PLAY_AREA_BOTTOM: .word 200

; starting Y coordinate
CHARACTER_START_YPOS: .word 100


; the background image
incbin bg01_palette, "data/bg01.png.palette"
incbin bg01_tiles,   "data/bg01.png.tiles.lz4"
incbin bg01_map,     "data/bg01.png.map.lz4"

; mario_sprites animation
incbin mario_sprites_tiles,      "data/mario_sprites.png.tiles.lz4"
incbin mario_sprites_palette,    "data/mario_sprites.png.palette"

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

; shell left/right movement state
.enum E_SHELL_STATE_LR
	LEFT
	RIGHT
	NEUTRAL
.endenum

; shell up/down movement state
.enum E_SHELL_STATE_UD
	UP
	DOWN
	NEUTRAL
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

SHELL_X_POS: .word 0
SHELL_Y_POS: .word 0

SHELL_LR_STATE: .word 0
SHELL_UD_STATE: .word 0

.segment "CODE"

display_sprites:
	sprite_update 00, PLAY_AREA_LEFT,  MARIO_STATE+S_CHAR_STATE::Y_POS, MARIO_STATE+S_CHAR_STATE::CUR_SPRITE, 1
	sprite_update 01, PLAY_AREA_RIGHT, LUIGI_STATE+S_CHAR_STATE::Y_POS, LUIGI_STATE+S_CHAR_STATE::CUR_SPRITE, 1
	sprite_update 16, SHELL_X_POS, SHELL_Y_POS, SHELL_SPRITE, 1
	rts

Main:
	; tell controller to latch input
	lda $4212
	ora #$01
	sta $4212
	

	load_spriteset mario_sprites_tiles, mario_sprites_palette ; load mario_sprites
	load_bg bg01_map, bg01_tiles, bg01_palette    ; load bg01

	setup_screen
	; stupid voodoo hack
	OAM_init shadow_oam,   0, 0, 0 
	OAM_init shadow_oam+4, 0, 0, 1

	; setup player states
	jsr init_players

	; setup the shell
	jsr init_shell

	; set Vblank handler
	VBL_set VBL

	screen_on



loop:
	jsr update_players
	jsr update_shell
	wai
	jmp loop

init_shell:
	; setup initial coordinates of shell
	lda SHELL_START_XPOS
	sta SHELL_X_POS
	lda SHELL_START_YPOS
	sta SHELL_Y_POS

	; setup initial state of shell
	lda E_SHELL_STATE_LR::NEUTRAL
	sta SHELL_LR_STATE
	lda E_SHELL_STATE_UD::NEUTRAL
	sta SHELL_UD_STATE
	rts

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

update_luigi_anim:
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

update_mario_anim:
	; first we check the current state and jump to the correct routine
	lda MARIO_STATE+S_CHAR_STATE::CUR_STATE

	cmp E_CHAR_ANIM_STATE::STANDING_STILL
	bne :+
	jmp update_mario_still
:

	cmp E_CHAR_ANIM_STATE::MOVING_UP_F1
	bne :+
	jmp update_mario_moving_up
:	cmp E_CHAR_ANIM_STATE::MOVING_UP_F2
	bne :+
	jmp update_mario_moving_up
:

	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	bne :+
	jmp update_mario_moving_down
:	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	bne :+
	jmp update_mario_moving_down
:
	rts


update_mario_moving_up:
	; first check if we're too close to the top
	lda MARIO_STATE+S_CHAR_STATE::Y_POS
	cmp PLAY_AREA_TOP
	bne :+

	; if we end up here, we need to switch to moving down state, so let's do so and then return
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	rts
:
	; otherwise, move up 1 pixel and then flip the frame
	; move up 1 pixel first
	lda MARIO_STATE+S_CHAR_STATE::Y_POS
	dec
	sta MARIO_STATE+S_CHAR_STATE::Y_POS

	; now the frame flip
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	cmp MARIO_STATE+S_CHAR_STATE::CUR_STATE
	bne :+

	; if we end up here, we need to flip to the F2 frame
	lda E_CHAR_ANIM_STATE::MOVING_UP_F2
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_UP_F2
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

:	; if we end up here, we need to flip to the F1 frame
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

update_mario_moving_down:
	; first check if we're too close to the top
	lda MARIO_STATE+S_CHAR_STATE::Y_POS
	cmp PLAY_AREA_BOTTOM
	bne :+

	; if we end up here, we need to switch to moving up state, so let's do so and then return
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	rts
:
	; otherwise, move up 1 pixel and then flip the frame
	; move up 1 pixel first
	lda MARIO_STATE+S_CHAR_STATE::Y_POS
	inc
	sta MARIO_STATE+S_CHAR_STATE::Y_POS

	; now the frame flip
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	cmp MARIO_STATE+S_CHAR_STATE::CUR_STATE
	bne :+

	; if we end up here, we need to flip to the F2 frame
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F2
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	rts

:	; if we end up here, we need to flip to the F1 frame
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	rts


update_mario_still:
	rts


set_p1_moving_up:
	lda MARIO_STATE+S_CHAR_STATE::CUR_STATE 
	cmp E_CHAR_ANIM_STATE::STANDING_STILL
	beq :+
	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	beq :+
	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	beq :+
	rts

:	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_UP_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE

	rts

set_p1_moving_down:
	lda MARIO_STATE+S_CHAR_STATE::CUR_STATE 
	cmp E_CHAR_ANIM_STATE::STANDING_STILL
	beq :+
	cmp E_CHAR_ANIM_STATE::MOVING_UP_F1
	beq :+
	cmp E_CHAR_ANIM_STATE::MOVING_UP_F2
	beq :+
	rts

:	lda MARIO_SPRITES+S_CHAR_SPRITES::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE

	rts

set_p1_still:
	lda MARIO_SPRITES+S_CHAR_SPRITES::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_SPRITE
	lda E_CHAR_ANIM_STATE::STANDING_STILL
	sta MARIO_STATE+S_CHAR_STATE::CUR_STATE
	rts

update_input:
	lda P1_JOY
	bit #JOY_DOWN
	bne set_p1_moving_down
	lda P1_JOY
	bit #JOY_UP
	bne set_p1_moving_up
	beq set_p1_still
	rts

update_players:
	jsr update_input
	jsr update_shell


	rts

check_mario_collide:
	; this routine should only be called once we're actually at the left of the play area
	; essentially, if the difference between SHELL_Y_POS and mario's Y pos is <16 then we had a collision


	; if no collision, just set the shell's L/R state to right and return
	; if collided, we set mario's state to kicking and shell's L/R state to R
	; after that, we figure out if SHELL_Y_POS is above or below mario's Y pos
	; if above:
	;	set shell's U/D state to up
	; if below:
	; 	set shell's U/D state to down
	; if same:
	;	set shell's U/D state to neutral
	;	
	rts

update_shell_left:
	; let's first check if we're at the left wall
	lda SHELL_X_POS
	cmp PLAY_AREA_LEFT
	bne :+
	; if so, we need to check for collisions with mario

	jmp check_mario_collide

	; we should now switch to moving right
;	lda E_SHELL_STATE_LR::RIGHT
;	sta SHELL_LR_STATE
;	rts ; and then return

:	; if we get here, we actually move left
	lda SHELL_X_POS
	dec
	sta SHELL_X_POS
	rts

update_shell_right:
	; let's first check if we're at the left wall
	lda SHELL_X_POS
	cmp PLAY_AREA_RIGHT
	bne :+

	; TODO - check for collisions with luigi


	; we should now switch to moving left
	lda E_SHELL_STATE_LR::LEFT
	sta SHELL_LR_STATE
	rts

:	; if we get here, move right
	lda SHELL_X_POS
	inc
	sta SHELL_X_POS
	rts

update_shell_neutral:
	; we should only be here at the start of the game
	; basically, we just wait for player 1 to move, and then we use their state (if they're moving up, we're going L/U, otherwise L/D)

	; first, check if they're moving up
	lda MARIO_STATE+S_CHAR_STATE::CUR_STATE 
	cmp E_CHAR_ANIM_STATE::MOVING_UP_F1
	bne :+
	cmp E_CHAR_ANIM_STATE::MOVING_UP_F2
	bne :+
	; if we get here, player 1 is moving up, so let's switch to U/L
	lda E_SHELL_STATE_LR::LEFT
	sta SHELL_LR_STATE
	lda E_SHELL_STATE_UD::UP
	sta SHELL_UD_STATE
	rts ; and then return

:	; if we get here, player 1 is not moving up, let's check if they're moving down
	lda MARIO_STATE+S_CHAR_STATE::CUR_STATE 
	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F1
	bne :+
	cmp E_CHAR_ANIM_STATE::MOVING_DOWN_F2
	bne :+
	; and if we get here, we want to be going D/L
	lda E_SHELL_STATE_LR::LEFT
	sta SHELL_LR_STATE
	lda E_SHELL_STATE_UD::DOWN
	sta SHELL_UD_STATE
	rts

	; if the player is not in any appropriate state, we just return
:	rts

update_shell_lr:
	lda SHELL_LR_STATE
	cmp E_SHELL_STATE_LR::LEFT
	bne :+
	jmp update_shell_left

:	cmp E_SHELL_STATE_LR::RIGHT
	bne :+
	jmp update_shell_right

:
	jmp update_shell_neutral ; we only need an update for neutral on the L/R state, not U/D state below
	rts

update_shell_up:
	; let's first check if we're at the top
	lda SHELL_Y_POS
	cmp PLAY_AREA_TOP
	bne :+

	; if we get here, we're at the top, we should swap to moving down
	lda E_SHELL_STATE_UD::UP
	sta SHELL_UD_STATE
	rts

:	; if we get here, move up
	lda SHELL_Y_POS
	dec
	sta SHELL_Y_POS
	rts

update_shell_down:
	lda SHELL_Y_POS
	cmp PLAY_AREA_BOTTOM
	bne :+

	lda E_SHELL_STATE_UD::DOWN
	sta SHELL_UD_STATE
	rts

:	; if we get here, move down
	lda SHELL_Y_POS
	inc
	sta SHELL_Y_POS
	rts

update_shell_ud:
	lda SHELL_UD_STATE
	cmp E_SHELL_STATE_UD::UP
	bne :+
	jmp update_shell_up

:	cmp E_SHELL_STATE_UD::DOWN
	bne :+
	jmp update_shell_down

:	rts

update_shell:
	jsr update_shell_lr
	jsr update_shell_ud
	rts

	; rough sketch of how this should work
	; shell has LEFT or RIGHT states for moving left and right
	; shell has UP, DOWN or NEUTRAL states for moving up and down
	; at start of game, shell starts moving (LEFT,NEUTRAL)
	; if it collides with mario:
	;	shell starts moving right
	;	if mario was moving down, shell starts moving down
	; 	if mario was moving up, shell starts moving up
	; if it collides with luigi:
	;	shell starts moving left
	;	if luigi was moving down, shell starts moving down
	;	if luigi was moving up, shell starts moving up
	; if it collides with edges of play area, same basic thing
	; eventually, if it collides with left play area, mario loses a point and likewise for right play area
	; luigi AI needs to roughly follow the shell too
	rts

VBL:
	jsr update_luigi_anim
	jsr update_mario_anim
	jsr display_sprites
	render_sprites

	rtl



.segment "LORAM"
shadow_oam: .res 512+32

.segment "RODATA"
; sprite tile ID data, see definition of S_CHAR_SPRITES struct above
SHELL_SPRITE:
	.word 40

MARIO_SPRITES:
	.word 38 ; STANDING_STILL
	.word 34 ; MOVING_UP_F1
	.word 14 ; MOVING_UP_F2
	.word 12 ; MOVING_DOWN_F1
	.word 32 ; MOVING_DOWN_F2
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
PLAY_AREA_LEFT:   .word 10
PLAY_AREA_RIGHT:  .word 230

; starting character Y coordinate
CHARACTER_START_YPOS: .word 100

; starting shell coordinates
SHELL_START_XPOS: .word 120
SHELL_START_YPOS: .word 100

; the background image
incbin bg01_palette, "data/bg01.png.palette"
incbin bg01_tiles,   "data/bg01.png.tiles.lz4"
incbin bg01_map,     "data/bg01.png.map.lz4"

; mario_sprites animation
incbin mario_sprites_tiles,      "data/mario_sprites.png.tiles.lz4"
incbin mario_sprites_palette,    "data/mario_sprites.png.palette"

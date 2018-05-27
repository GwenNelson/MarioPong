.include "libSFX.i"
.include "macros.inc"
.debuginfo

MARIO_STANDING = 38
LUIGI_STANDING = 08
SHELL          = 40

Main:


	load_spriteset mario_sprites_tiles, mario_sprites_palette ; load mario_sprites
	load_bg bg01_map, bg01_tiles, bg01_palette    ; load bg01

	setup_screen
	OAM_init shadow_oam,   0, 0, 0 
	OAM_init shadow_oam+4, 0, 0, 1

	; set Vblank handler
	VBL_set VBL

	screen_on



loop:

	jmp loop

VBL:
	sprite_update 00, 10,  40, #MARIO_STANDING, 1
	sprite_update 01, 230, 40, #LUIGI_STANDING, 1
	sprite_update 16, 120, 100, #SHELL, 1

	render_sprites

	rtl

.segment "LORAM"
shadow_oam: .res 512+32

.segment "RODATA"
; the background image
incbin bg01_palette, "data/bg01.png.palette"
incbin bg01_tiles,   "data/bg01.png.tiles.lz4"
incbin bg01_map,     "data/bg01.png.map.lz4"

; mario_sprites animation
incbin mario_sprites_tiles,      "data/mario_sprites.png.tiles.lz4"
incbin mario_sprites_palette,    "data/mario_sprites.png.palette"

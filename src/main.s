.include "libSFX.i"
.include "macros.inc"
.debuginfo

Main:
	OAM_init shadow_oam, 0, 0, 0

	load_spriteset pikachu_tiles, pikachu_palette ; load pikachu
	load_bg bg01_map, bg01_tiles, bg01_palette    ; load bg01

	setup_screen


	; set Vblank handler
	VBL_set VBL

	screen_on

loop:
	jmp loop

VBL:
	; set a single sprite (ID 0) at 100,100 with tile ID set to 0
	; with 32x32 sprites, it's important to remember to add 4, not 1 when animating
	sprite_update 0, 100, 100, 0



	; render all current sprites
	render_sprites

	rtl

.segment "LORAM"
shadow_oam: .res 512+32
pika_frame: .res 2

.segment "RODATA"
; the background image
incbin bg01_palette, "data/bg01.png.palette"
incbin bg01_tiles,   "data/bg01.png.tiles.lz4"
incbin bg01_map,     "data/bg01.png.map.lz4"

; pikachu animation
incbin pikachu_tiles,      "data/pikachu.png.tiles.lz4"
incbin pikachu_palette,    "data/pikachu.png.palette"

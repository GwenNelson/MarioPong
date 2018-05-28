VRAM_MAP_LOC     = $0000
VRAM_TILES_LOC   = $8000
VRAM_SPRITES_LOC = $C000

.define JOY_B $80
.define JOY_Y $40
.define JOY_SELECT $20
.define JOY_START $10
.define JOY_UP $8
.define JOY_DOWN $4
.define JOY_LEFT $2
.define JOY_RIGHT $1

.define P1_JOY $4219

.include "OAM.i"

.macro load_bg bg_map, bg_tiles, bg_palette
	LZ4_decompress bg_map, EXRAM, y    ; decompress the map into exram and store number of bytes in y reg
	VRAM_memcpy VRAM_MAP_LOC, EXRAM, y ; copy y bytes from EXRAM to VRAM_MAP_LOC

	LZ4_decompress bg_tiles, EXRAM, y ; decompress the tile data into EXRAM and store number of bytes in y
	VRAM_memcpy VRAM_TILES_LOC, EXRAM, y ; copy y bytes to VRAM_TILES_LOC

	CGRAM_memcpy 0, bg_palette, .ident (.concat ("sizeof_", .string(bg_palette))) ; copy the palette data to CGRAM at address 0
.endmacro

.macro load_spriteset spriteset_tiles, spriteset_palette
	LZ4_decompress spriteset_tiles, EXRAM, y
	VRAM_memcpy VRAM_SPRITES_LOC, EXRAM, y
	CGRAM_memcpy 16,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 32,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 48,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 64,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 80,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 96,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 112,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 128,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 144,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 160,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 176,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 192,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 208,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 224,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
	CGRAM_memcpy 240,   spriteset_palette, .ident (.concat ("sizeof_", .string(spriteset_palette)))
.endmacro

.macro setup_screen
        lda     #bgmode(BG_MODE_1, BG3_PRIO_NORMAL, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8, BG_SIZE_8X8)
        sta     BGMODE
        lda     #bgsc(VRAM_MAP_LOC, SC_SIZE_32X32)
        sta     BG1SC
        ldx     #bgnba(VRAM_TILES_LOC, 0, 0, 0)
        stx     BG12NBA
        lda     #objsel(VRAM_SPRITES_LOC, OBJ_8x8_16x16, 0)
        sta     OBJSEL
        lda     #tm(ON, OFF, OFF, OFF, ON)
        sta     TM
.endmacro

.macro screen_on
	lda     #inidisp(ON, DISP_BRIGHTNESS_MAX)
	sta     SFX_inidisp
	VBL_on
.endmacro

.macro sprite_update sprite_id, pos_x, pos_y, tile_id, fix
	; load the tile_id into accumulator
	ldy tile_id
	; do the update
        lda     pos_y
        ldx     pos_x
        OAM_set shadow_oam, sprite_id, 0, 0, 0, fix, 3
.endmacro

.macro render_sprites
	OAM_memcpy shadow_oam
.endmacro

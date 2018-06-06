# Name
name		:= mario_pong
debug		:= 1

libsfx_packages := LZ4

derived_files	:= data/bg01.png.palette data/bg01.png.tiles data/bg01.png.map
derived_files	+= data/bg01.png.tiles.lz4 data/bg01.png.map.lz4

derived_files   := data/menu01.png.palette data/menu01.png.tiles data/menu01.png.map
derived_files   += data/menu01.png.tiles.lz4 data/menu01.png.map.lz4

derived_files   += data/mario_sprites.png.palette data/mario_sprites.png.tiles
derived_files   += data/mario_sprites.png.tiles.lz4

data/mario_sprites.png.tiles: tiles_flags = -v --no-discard --no-flip --tile-width=16 --tile-height=16

# Include libSFX.make
libsfx_dir	:= ${HOME}/libSFX
include $(libsfx_dir)/libSFX.make

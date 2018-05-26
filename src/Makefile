# Name
name		:= Super_SNES_BOX
debug		:= 1

libsfx_packages := LZ4

derived_files	:= data/bg01.png.palette data/bg01.png.tiles data/bg01.png.map
derived_files	+= data/bg01.png.tiles.lz4 data/bg01.png.map.lz4

derived_files   += data/pikachu.png.palette data/pikachu.png.tiles
derived_files   += data/pikachu.png.tiles.lz4

data/pikachu.png.tiles: tiles_flags = -v --no-discard

# Include libSFX.make
libsfx_dir	:= ${HOME}/libSFX
include $(libsfx_dir)/libSFX.make


TARGET = wasm32-none-wasm
SWIFT_SOURCES = $(wildcard src/*.swift) $(wildcard src/Core/*.swift) $(wildcard src/Core/Platform/*.swift) $(wildcard src/Game/*.swift)
C_SOURCES = $(wildcard runtime/*.c)

ASSET_SOURCES = $(wildcard assets/module/*.c)

SWIFT_FLAGS = -enable-builtin-module -enable-experimental-feature Embedded -enable-experimental-feature SymbolLinkageMarkers -wmo -parse-as-library -Osize -Xcc -fdeclspec
C_FLAGS = -O2 -nostdlib -Wno-incompatible-library-redeclaration

all: wasm

wasm:
	@clang -target $(TARGET) $(C_FLAGS) $(C_SOURCES) -c -o build/runtime.o
	@clang -target $(TARGET) $(C_FLAGS) $(ASSET_SOURCES) -c -o build/assets.o
	@swiftc -target $(TARGET) $(SWIFT_FLAGS) -Xcc -fmodule-map-file=runtime/module.modulemap -Xcc -fmodule-map-file=assets/module/module.modulemap $(SWIFT_SOURCES) -c -o build/game-wasm.o
	@wasm-ld build/game-wasm.o build/runtime.o build/assets.o -o web/src/game.wasm --no-entry --allow-undefined

#clean:
#	@rm -r build/* || true
#	@rm assets/module/include/assets.h || true
#	@rm assets/module/assets.c || true

serve:
	@cd web; esbuild --servedir=src --serve

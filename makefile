.PHONY: assets

TARGET = wasm32-none-wasm
SWIFT_SOURCES = $(wildcard src/*.swift) $(wildcard src/Core/*.swift) $(wildcard src/Core/Platform/*.swift) $(wildcard src/Game/*.swift)
C_SOURCES = $(wildcard runtime/*.c)
C_LIB_SOURCES = $(wildcard runtime/lib/*.c)

ASSET_SOURCES = $(wildcard assets/module/*.c)

# -disable-stack-protector ???
SWIFT_FLAGS = -enable-builtin-module -enable-experimental-feature Extern -enable-experimental-feature Embedded -enable-experimental-feature SymbolLinkageMarkers -wmo -parse-as-library -O -Xcc -fdeclspec
C_FLAGS = -O2 -nostdlib -Wno-incompatible-library-redeclaration

all: wasm

wasm: assets
	@clang -target $(TARGET) $(C_FLAGS) $(C_SOURCES) -c -o build/runtime.o
	@clang -target $(TARGET) $(C_FLAGS) $(C_LIB_SOURCES) -c -o build/walloc.o
	@clang -target $(TARGET) $(C_FLAGS) $(ASSET_SOURCES) -c -o build/assets.o
	@swiftc -target $(TARGET) $(SWIFT_FLAGS) -Xcc -fmodule-map-file=runtime/module.modulemap -Xcc -fmodule-map-file=assets/module/module.modulemap $(SWIFT_SOURCES) -c -o build/game-wasm.o
	@wasm-ld $(wildcard build/*.o) -o web/src/game.wasm --no-entry --allow-undefined
#	@wasm-ld build/game-wasm.o build/runtime.o build/assets.o -o web/src/game.wasm --no-entry --allow-undefined

clean:
	@rm -r build/* || true

#clean:
#	@rm -r build/* || true
#	@rm assets/module/include/assets.h || true
#	@rm assets/module/assets.c || true

serve:
	@cd web; esbuild --servedir=src --serve

# remove xcrun outside of macos.
assets:
	@cd assets; xcrun swift ./bundle.swift

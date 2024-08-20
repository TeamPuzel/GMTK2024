# Standalone Swift Game Engine

This is my (work in progress) platform independent game engine taking advantage of the new Embedded Swift.

This iteration of my technology was improved for the 2024 GMTK game jam and currently doesn't have a native backend, only wasm.
Input handling and the UI/layout extensions are very unfinished but the abstract rendering APIs are very usable.

The only dependency at the moment is for wasm memory allocation https://github.com/wingo/walloc

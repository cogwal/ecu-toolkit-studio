This folder contains a minimal native C++ module that provides mocked ECU models as a JSON string.

Files:
- src/ecu_models.cpp - exposes `get_mock_ecus()` and `free_cstring()`.

Build instructions (desktop):

We provide a CMake build in this folder and helper scripts to build the shared library and copy it into the top-level platform folders if present.

Windows (MSVC):
- Open "x64 Native Tools Command Prompt for VS" (or equivalent).
- From this folder run: `.\build.ps1`

Linux / macOS:
- Ensure `cmake` and a C++ toolchain are installed.
- From this folder run: `./build.sh`

What the build does
- Uses `CMakeLists.txt` to produce a platform shared library:
	- Windows: `ecu_models.dll`
	- Linux: `libecu_models.so`
	- macOS: `libecu_models.dylib`
- After build the library is copied into the top-level `windows/`, `linux/`, or `macos/` folders (if present) so the Flutter runner can load it at runtime.

Notes
- The Dart FFI wrapper (`lib/native/ecu_models.dart`) expects the dynamic library to be named `ecu_models.dll` (Windows), `libecu_models.so` (Linux) or `libecu_models.dylib` (macOS) and available on the app's runtime search path. Copying to the top-level platform folders is a convenience for local development; you may prefer to package it with the actual app output later.
- If the native library can't be loaded at runtime the Dart wrapper falls back to an internal Dart mock so the app remains functional during development.
- If you need plugin-style mobile support (Android/iOS), we should implement a proper Flutter plugin instead of direct FFI.

#!/usr/bin/env bash
set -euo pipefail
BUILD_DIR=build
mkdir -p "$BUILD_DIR"
pushd "$BUILD_DIR"
cmake ..
cmake --build . --config Release
echo "Build complete. Built library should be copied to runner folders if present."
popd

#!/usr/bin/env bash
#
# build_libarchive.sh
# Builds libarchive as an xcframework for iOS (device + simulator).
#
# Usage:
#   cd Scripts && bash build_libarchive.sh
#
# Output:
#   ../Frameworks/libarchive.xcframework/

set -euo pipefail

LIBARCHIVE_VERSION="v3.7.7"
LIBARCHIVE_REPO="https://github.com/libarchive/libarchive.git"
IOS_DEPLOYMENT_TARGET="16.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$SCRIPT_DIR/.build_libarchive"
OUTPUT_DIR="$ROOT_DIR/Frameworks"

cleanup() {
  echo "Cleaning build directory..."
  rm -rf "$BUILD_DIR"
}

# ── Clone ──────────────────────────────────────────────────────────────────────

clone_libarchive() {
  if [ -d "$BUILD_DIR/libarchive" ]; then
    echo "libarchive source already exists, skipping clone..."
    return
  fi
  echo "Cloning libarchive $LIBARCHIVE_VERSION..."
  mkdir -p "$BUILD_DIR"
  git clone --depth 1 --branch "$LIBARCHIVE_VERSION" "$LIBARCHIVE_REPO" "$BUILD_DIR/libarchive"
}

# ── Patch for iOS ──────────────────────────────────────────────────────────────

patch_for_ios() {
  echo "Patching libarchive for iOS charset (UTF-8 default)..."

  local ARCHIVE_STRING="$BUILD_DIR/libarchive/libarchive/archive_string.c"

  # iOS returns US-ASCII from nl_langinfo(CODESET), causing non-ASCII
  # filenames to fail. Patch default_iconv_charset() to return UTF-8
  # on Apple platforms.
  # See: https://github.com/libarchive/libarchive/issues/1572
  sed -i '' 's/#elif HAVE_NL_LANGINFO/#elif defined(__APPLE__)\
\treturn "UTF-8";\
#elif HAVE_NL_LANGINFO/' "$ARCHIVE_STRING"
}

# ── Build a single slice ───────────────────────────────────────────────────────

build_slice() {
  local ARCH=$1
  local SYSROOT=$2
  local SLICE_NAME=$3

  local SDK_PATH
  SDK_PATH=$(xcrun --sdk "$SYSROOT" --show-sdk-path)

  local INSTALL_DIR="$BUILD_DIR/install-$SLICE_NAME"
  local CMAKE_BUILD_DIR="$BUILD_DIR/build-$SLICE_NAME"

  echo "Building libarchive for $SLICE_NAME ($ARCH, $SYSROOT)..."

  cmake -S "$BUILD_DIR/libarchive" -B "$CMAKE_BUILD_DIR" \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_ARCHITECTURES="$ARCH" \
    -DCMAKE_OSX_SYSROOT="$SDK_PATH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$IOS_DEPLOYMENT_TARGET" \
    -DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
    -DCMAKE_C_FLAGS="-fvisibility=hidden" \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_MBEDTLS=OFF \
    -DENABLE_NETTLE=OFF \
    -DENABLE_OPENSSL=OFF \
    -DENABLE_LIBB2=OFF \
    -DENABLE_LZ4=OFF \
    -DENABLE_LZO=OFF \
    -DENABLE_LZMA=ON \
    -DENABLE_ZSTD=OFF \
    -DENABLE_ZLIB=ON \
    -DENABLE_BZip2=ON \
    -DENABLE_LIBXML2=OFF \
    -DENABLE_EXPAT=OFF \
    -DENABLE_PCREPOSIX=OFF \
    -DENABLE_PCRE2POSIX=OFF \
    -DENABLE_LibGCC=OFF \
    -DENABLE_CNG=OFF \
    -DENABLE_TAR=OFF \
    -DENABLE_CPIO=OFF \
    -DENABLE_CAT=OFF \
    -DENABLE_UNZIP=OFF \
    -DENABLE_XATTR=OFF \
    -DENABLE_ACL=OFF \
    -DENABLE_ICONV=OFF \
    -DENABLE_TEST=OFF \
    -DENABLE_INSTALL=ON \
    > /dev/null 2>&1

  cmake --build "$CMAKE_BUILD_DIR" --config Release --target archive_static -- -j"$(sysctl -n hw.ncpu)" > /dev/null 2>&1
  cmake --install "$CMAKE_BUILD_DIR" > /dev/null 2>&1
}

# ── Add module.modulemap ──────────────────────────────────────────────────────

add_modulemap() {
  local HEADERS_DIR=$1
  cat > "$HEADERS_DIR/module.modulemap" << 'MODULEMAP'
module CLibArchive {
  header "archive.h"
  header "archive_entry.h"
  link "archive"
  export *
}
MODULEMAP
}

# ── Create xcframework ────────────────────────────────────────────────────────

create_xcframework() {
  echo "Creating fat simulator library..."
  local SIM_FAT_DIR="$BUILD_DIR/install-sim-fat"
  mkdir -p "$SIM_FAT_DIR/lib" "$SIM_FAT_DIR/include"

  # Combine simulator slices (arm64 + x86_64) into fat library
  lipo -create \
    "$BUILD_DIR/install-sim-arm64/lib/libarchive.a" \
    "$BUILD_DIR/install-sim-x86_64/lib/libarchive.a" \
    -output "$SIM_FAT_DIR/lib/libarchive.a"

  # Copy headers from either simulator slice (they're identical)
  cp -R "$BUILD_DIR/install-sim-arm64/include/"* "$SIM_FAT_DIR/include/"

  # Add modulemaps
  add_modulemap "$BUILD_DIR/install-device-arm64/include"
  add_modulemap "$SIM_FAT_DIR/include"

  echo "Creating xcframework..."
  rm -rf "$OUTPUT_DIR/libarchive.xcframework"
  mkdir -p "$OUTPUT_DIR"

  xcodebuild -create-xcframework \
    -library "$BUILD_DIR/install-device-arm64/lib/libarchive.a" \
    -headers "$BUILD_DIR/install-device-arm64/include" \
    -library "$SIM_FAT_DIR/lib/libarchive.a" \
    -headers "$SIM_FAT_DIR/include" \
    -output "$OUTPUT_DIR/libarchive.xcframework"

  echo "xcframework created at: $OUTPUT_DIR/libarchive.xcframework"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  echo "=== Building libarchive xcframework ==="
  echo ""

  clone_libarchive
  patch_for_ios

  # Build 3 slices
  build_slice "arm64" "iphoneos" "device-arm64"
  build_slice "arm64" "iphonesimulator" "sim-arm64"
  build_slice "x86_64" "iphonesimulator" "sim-x86_64"

  create_xcframework

  echo ""
  echo "=== Done ==="
  echo "Output: $OUTPUT_DIR/libarchive.xcframework"
}

main "$@"

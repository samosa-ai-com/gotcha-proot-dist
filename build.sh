#!/usr/bin/env bash
# Build the released runtime bundle for Android arm64-v8a.
#
# Every input is in this repository (submodules + vendored talloc), so the
# result is separable from any other project.
#
# Output: build/gotcha-proot-<version>-arm64-v8a.tar.gz
#         build/gotcha-proot-<version>-arm64-v8a.tar.gz.sha256
#
# Requires: CMake 3.22.1, Android NDK (version below), JDK 17.
set -euo pipefail

VERSION="5.1.107.91"
NDK_VERSION="${ANDROID_NDK_VERSION:-28.2.13676358}"
ANDROID_PLATFORM="${ANDROID_PLATFORM:-android-30}"
ABI="arm64-v8a"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

if [ ! -f third_party/proot/src/cli/cli.c ]; then
  echo "error: submodules are empty; run: git submodule update --init --recursive" >&2
  exit 1
fi

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"
NDK="$SDK/ndk/$NDK_VERSION"
if [ ! -d "$NDK" ]; then
  echo "error: NDK $NDK_VERSION not found at $NDK" >&2
  echo "       set ANDROID_SDK_ROOT, or install it via sdkmanager" >&2
  exit 1
fi

BUILD="$ROOT/build/cmake"
STAGE="$ROOT/build/stage"
rm -rf "$BUILD" "$STAGE"
mkdir -p "$STAGE"

cmake -S "$ROOT" -B "$BUILD" \
  -DCMAKE_TOOLCHAIN_FILE="$NDK/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI="$ABI" \
  -DANDROID_PLATFORM="$ANDROID_PLATFORM" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_READELF="$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" \
  -DCMAKE_INSTALL_PREFIX="$STAGE"

cmake --build "$BUILD" --parallel "$(nproc)"
cmake --install "$BUILD"

# The install step puts executables in bin/ and libraries in lib/.
# Flatten to the layout the client expects: everything at the archive root.
cp -a "$STAGE/lib/libtalloc.so"        "$STAGE/libtalloc.so"
cp -a "$STAGE/lib/libandroid-shmem.so" "$STAGE/libandroid-shmem.so"
cp -a "$STAGE/bin/proot"               "$STAGE/proot"
cp -a "$STAGE/bin/loader"              "$STAGE/loader"
rm -rf "$STAGE/bin" "$STAGE/lib"

cp -a "$ROOT/licenses" "$STAGE/licenses"

COMMIT="$(git rev-parse HEAD)"
cat > "$STAGE/SOURCE.txt" <<EOF
Gotcha Shell Linux runtime bundle
PRoot $VERSION, arm64-v8a

  proot, loader           PRoot            GPL-2.0-only
  libtalloc.so            talloc 2.4.3     LGPL-3.0-or-later
  libandroid-shmem.so     libandroid-shmem BSD-3-Clause

Complete corresponding source: this repository at tag $VERSION
  https://github.com/samosa-ai-com/gotcha-proot-dist/tree/$VERSION

Upstream components, unmodified:
  https://github.com/termux/proot at $(git -C third_party/proot rev-parse HEAD)
  https://github.com/termux/libandroid-shmem at $(git -C third_party/libandroid-shmem rev-parse HEAD)
  talloc 2.4.3 (https://www.samba.org/ftp/talloc/talloc-2.4.3.tar.gz)

Build inputs:
  Recipe:           CMakeLists.txt in this repository at $COMMIT
  NDK:              $NDK_VERSION
  ANDROID_ABI:      $ABI
  ANDROID_PLATFORM: $ANDROID_PLATFORM
  CMake:            3.22.1 or newer

No local modifications to upstream source.
EOF

NAME="gotcha-proot-$VERSION-arm64-v8a.tar.gz"
OUT="$ROOT/build/$NAME"

# Deterministic: fixed mtime and sorted entries, so the same inputs give the
# same digest on any machine.
tar --sort=name \
    --mtime="@${SOURCE_DATE_EPOCH:-1700000000}" \
    --owner=0 --group=0 --numeric-owner \
    -C "$STAGE" -cf - proot loader libtalloc.so libandroid-shmem.so licenses SOURCE.txt \
  | gzip -9 -n > "$OUT"

(cd "$ROOT/build" && sha256sum "$NAME" > "$NAME.sha256")

echo
echo "built: $OUT"
cat "$OUT.sha256"

# gotcha-proot-dist

Corresponding source for the **Gotcha Shell Linux runtime** bundle: PRoot, its
loader, talloc and libandroid-shmem, built for Android `arm64-v8a`.

The Gotcha Shell app does not contain these binaries. It downloads a bundle at
first use and runs PRoot as a separate process. This repository is the source
offer for that bundle, as required by the licences below.

## What is in a release

A release asset named `gotcha-proot-<version>-arm64-v8a.tar.gz` containing:

| File in the archive | Component | Licence |
|---|---|---|
| `proot` | PRoot CLI | GPL-2.0-only |
| `loader` | PRoot loader | GPL-2.0-only |
| `libtalloc.so` | talloc 2.4.3 | LGPL-3.0-or-later |
| `libandroid-shmem.so` | libandroid-shmem | BSD-3-Clause |
| `licenses/` | the four licence texts above | — |
| `SOURCE.txt` | provenance and build inputs | — |

Each release ships `SOURCE.txt` naming the exact upstream commits, the talloc
release, and the build recipe. The recipe is in this repository.

## Building

Prerequisites: JDK 17, CMake 3.22.1, Android NDK 28.2.13676358.

```bash
git clone --recurse-submodules https://github.com/samosa-ai-com/gotcha-proot-dist
cd gotcha-proot-dist
./build.sh          # writes build/gotcha-proot-<version>-arm64-v8a.tar.gz
```

`build.sh` drives CMake with `ANDROID_ABI=arm64-v8a` and
`ANDROID_PLATFORM=android-30`, then packs the four binaries plus `licenses/`
and `SOURCE.txt` into a deterministic archive.

## Provenance

Upstream projects, unmodified:

- PRoot — <https://github.com/termux/proot> at the commit in `.gitmodules`
- libandroid-shmem — <https://github.com/termux/libandroid-shmem> at the commit in `.gitmodules`
- talloc 2.4.3 — <https://www.samba.org/ftp/talloc/talloc-2.4.3.tar.gz>

Local changes to upstream sources: none. The only additions are the CMake
recipe and the loader-info generation step, both in this repository.

## Licence

This repository aggregates several projects under different licences. Each
file remains under its own licence; the texts are in `licenses/` and in the
upstream projects. PRoot is GPL-2.0-only, so the PRoot-derived parts of any
built bundle are distributed under GPL-2.0-only. talloc is
LGPL-3.0-or-later. libandroid-shmem is BSD-3-Clause.

See `LICENSE` for the scope statement.

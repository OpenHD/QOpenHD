# Linux cross packages

The ARM package workflows use native x86 host Qt tools and Bootlin cross GCC,
with target development packages extracted by `mmdebstrap --variant=extract`.
Compilation and packaging do not execute ARM binaries or use QEMU.

This adapts [buldo's cross-build experiment](https://github.com/buldo/qopenhd-cross-build-experiment/tree/29ee7d1f4375a0bbb22380f04da553dbeb5358c6).
It builds the checked-out commit and submodules instead of cloning a default
branch. The sysroots are separate for these targets:

| Target | Architecture | Target Qt |
| --- | --- | --- |
| `pi-bullseye-armhf` | ARM hard float | OpenHD Qt 5.15.4 |
| `pi-bookworm-arm64` | AArch64 | Debian Bookworm Qt 5.15 |
| `rock-bookworm-arm64` | AArch64 | Debian Bookworm Qt 5.15 |

`cross_package.yml` caches the compiler, native Qt tools, and each target sysroot.
The native host tools are isolated from target libraries using `qt.conf`, a
cross device spec, and target-only `pkg-config` search paths. Absolute sysroot
symlinks are rewritten without following directory links into the host.

`package.sh` retains the existing dependencies, service files, install hooks,
and Pi/Rockchip package names. `PREBUILT_QOPENHD` skips its native compilation
step and supplies the cross-linked executable. ELF headers, dependencies, and
required symbol versions are included with CI artifacts. A successful link is
not proof of target startup or video decoding; validate those on hardware.

The x86, Windows, and Android workflows already use native or cross toolchains
and are unchanged. To build an ARM package locally on an Ubuntu x86 host with
the dependencies listed in the reusable workflow installed:

```sh
bash ci/cross-build.sh pi-bullseye-armhf
```

The first build compiles native Qt tools; subsequent builds reuse the SDK cache.
Remove the relevant sysroot cache when intentionally refreshing target packages.

# syntax=docker/dockerfile:1
ARG DEBIAN_RELEASE=oldstable

FROM debian:$DEBIAN_RELEASE AS build-stage
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git ca-certificates wget patchelf build-essential libudev-dev zlib1g-dev gvfs valac libgee-0.8-dev meson

COPY . /

ARG BUILD_TYPE=release
ARG ENABLE_LTO=true
ARG TARGETOS TARGETARCH TARGETVARIANT
ARG OWNER=v1993
ARG VERSION=v0.0.0-unknown

RUN meson setup \
      --fatal-meson-warnings \
      "--buildtype=${BUILD_TYPE}" \
      "-Db_lto=${ENABLE_LTO}" \
      --prefix=/usr \
      /build && \
    meson compile -C /build && \
    meson install --destdir=/ -C /build

RUN <<EOF
  set -eu
  arch="$(uname -m)"

  export DESKTOP=./dist/linuxmotehook2.desktop
  export ICON=./dist/linuxmotehook2.png
  export OUTNAME="linuxmotehook2-${VERSION}-${arch}.AppImage"
  export OUTPATH=/appimage
  export UPINFO="gh-releases-zsync|${OWNER}|linuxmotehook2|latest|linuxmotehook2-*-${arch}.AppImage.zsync"
  export VERSION

  sharun="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"
  wget "${sharun}" -O- | install /dev/stdin ./quick-sharun.sh
  ./quick-sharun.sh /usr/bin/linuxmotehook2
  ./quick-sharun.sh --make-appimage
EOF

FROM scratch AS export-stage
COPY --from=build-stage /appimage/* /

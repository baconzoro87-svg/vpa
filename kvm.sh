#!/bin/sh
set -eu

ROOTFS_DIR="$HOME/debian13-rootfs"
ARCH="$(uname -m)"

case "$ARCH" in
  x86_64)
    DEBIAN_ARCH="amd64"
    PROOT_ARCH="x86_64"
    ;;
  aarch64|arm64)
    DEBIAN_ARCH="arm64"
    PROOT_ARCH="aarch64"
    ;;
  *)
    echo "Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

command -v wget >/dev/null 2>&1 || {
  echo "wget is required. Install it in your host environment first."
  exit 1
}

command -v tar >/dev/null 2>&1 || {
  echo "tar is required."
  exit 1
}

mkdir -p "$ROOTFS_DIR"

if [ ! -f "$ROOTFS_DIR/.installed" ]; then
  echo "Downloading Debian 13 (Trixie) root filesystem..."

  DEBIAN_URL="https://github.com/debuerreotype/docker-debian-artifacts/raw/dist-amd64/trixie/slim/rootfs.tar.xz"

  if [ "$DEBIAN_ARCH" = "arm64" ]; then
    DEBIAN_URL="https://github.com/debuerreotype/docker-debian-artifacts/raw/dist-arm64/trixie/slim/rootfs.tar.xz"
  fi

  wget -O /tmp/debian13-rootfs.tar.xz "$DEBIAN_URL"
  tar -xJf /tmp/debian13-rootfs.tar.xz -C "$ROOTFS_DIR"
  rm -f /tmp/debian13-rootfs.tar.xz

  mkdir -p "$ROOTFS_DIR/usr/local/bin"

  echo "Downloading PRoot..."
  PROOT_URL="https://raw.githubusercontent.com/dxomg/vpsfreepterovm/main/proot-${PROOT_ARCH}"

  if ! wget -O "$ROOTFS_DIR/usr/local/bin/proot" "$PROOT_URL"; then
    echo "Could not download PRoot. Check the download source and architecture."
    exit 1
  fi

  chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

  printf 'nameserver 1.1.1.1\nnameserver 1.0.0.1\n' \
    > "$ROOTFS_DIR/etc/resolv.conf"

  touch "$ROOTFS_DIR/.installed"
fi

echo "Starting Debian 13 (Trixie)..."
echo "Type 'exit' to leave Debian."
echo

exec "$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="$ROOTFS_DIR" \
  -0 \
  -w /root \
  -b /dev \
  -b /proc \
  -b /sys \
  -b /etc/resolv.conf \
  --kill-on-exit \
  /usr/bin/env -i \
  HOME=/root \
  USER=root \
  PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
  TERM="${TERM:-xterm}" \
  /bin/bash --login

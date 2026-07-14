#!/usr/bin/env bash
#
# Build usb-creator .deb (Architecture: all). Usage: build-deb.sh <outdir>
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

out="${1:?usage: build-deb.sh <outdir>}"
ver=$(sed -n 's/^VERSION="\(.*\)"/\1/p' usb-creator)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

pkgroot="$work/usb-creator_${ver}_all"
install -Dm755 usb-creator "$pkgroot/usr/bin/usb-creator"
install -Dm644 README.md "$pkgroot/usr/share/doc/usb-creator/README.md"
install -Dm644 LICENSE "$pkgroot/usr/share/doc/usb-creator/copyright"
install -Dm644 docs/tldr/usb-creator.md "$pkgroot/usr/share/doc/usb-creator/tldr.md"
install -Dm644 docs/usb-creator.1 "$pkgroot/usr/share/man/man1/usb-creator.1"
gzip -9n "$pkgroot/usr/share/man/man1/usb-creator.1"

mkdir -p "$pkgroot/DEBIAN"
cat > "$pkgroot/DEBIAN/control" <<EOF
Package: usb-creator
Version: $ver
Section: utils
Priority: optional
Architecture: all
Depends: bash (>= 4), coreutils, util-linux (>= 2.37), curl, jq
Recommends: gnupg, sudo
Maintainer: Gorm Reventlow <gorm@reventlow.com>
Homepage: https://github.com/Reventlow/usb-creator
Description: Create bootable Linux USB installers with verified downloads
 Downloads the latest ISO for a curated set of distros, verifies
 checksums and (where published) GPG signatures with pinned keys,
 writes with dd and verifies the write by reading it back. Refuses
 to touch disks that back the running system.
EOF

mkdir -p "$out"
dpkg-deb --build --root-owner-group "$pkgroot" "$out/usb-creator_${ver}_all.deb"
echo "built: $out/usb-creator_${ver}_all.deb"

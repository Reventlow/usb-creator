# Maintainer: Gorm Reventlow <gorm@reventlow.com>
# Local package: build with `makepkg -si` (or `paru -Bi .`) from this directory.
pkgname=usb-creator
pkgver=0.12.0
pkgrel=1
pkgdesc="Create bootable USB installers for Linux and BSD with checksum and GPG verification"
arch=('any')
license=('MIT')
depends=('bash' 'coreutils' 'util-linux' 'curl' 'jq')
optdepends=('gnupg: GPG signature verification of downloads'
            'sudo: privileged write steps as non-root')
source=('usb-creator' 'README.md' 'LICENSE')
sha256sums=('SKIP' 'SKIP' 'SKIP')

package() {
    install -Dm755 usb-creator "$pkgdir/usr/bin/usb-creator"
    install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
    # makepkg only accepts local sources beside the PKGBUILD; the docs
    # keep their repo layout and install straight from $startdir.
    install -Dm644 "$startdir/docs/usb-creator.1" "$pkgdir/usr/share/man/man1/usb-creator.1"
    install -Dm644 "$startdir/docs/tldr/usb-creator.md" "$pkgdir/usr/share/doc/$pkgname/tldr.md"
    install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
}

#!/usr/bin/env bash
#
# Assemble the signed apt/rpm/arch repository trees under <htmldir>.
#
# Usage: make-repos.sh <htmldir> <debdir> <rpmdir> <archdir>
#   <debdir>/<rpmdir>/<archdir> contain the built packages
#   (<archdir> also carries the usb-creator.db/.files from repo-add).
#
# Environment:
#   REPO_BASE_URL   public base URL (e.g. https://repo.reventlow.com)
#   REPO_KEY_FPR    fingerprint of the signing key (must be in the keyring)
#
# The signing key must be imported into the default GnuPG keyring and be
# usable without a passphrase prompt (CI imports it from a secret).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

html="${1:?usage: make-repos.sh <htmldir> <debdir> <rpmdir> <archdir>}"
debdir="${2:?}" rpmdir="${3:?}" archdir="${4:?}"
: "${REPO_BASE_URL:?REPO_BASE_URL not set}"
: "${REPO_KEY_FPR:?REPO_KEY_FPR not set}"

ver=$(sed -n 's/^VERSION="\(.*\)"/\1/p' usb-creator)
mkdir -p "$html"

# --- public key ------------------------------------------------------------
gpg --armor --export "$REPO_KEY_FPR" > "$html/repo-key.asc"

# --- apt (Debian/Ubuntu) ----------------------------------------------------
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/conf"
cat > "$work/conf/distributions" <<EOF
Codename: stable
Suite: stable
Components: main
Architectures: amd64 arm64
SignWith: $REPO_KEY_FPR
Description: usb-creator apt repository
EOF
reprepro -b "$work" includedeb stable "$debdir"/*.deb
mkdir -p "$html/apt"
cp -r "$work/dists" "$work/pool" "$html/apt/"

# --- rpm (Fedora/openSUSE/RHEL) ----------------------------------------------
mkdir -p "$html/rpm"
cp "$rpmdir"/*.rpm "$html/rpm/"
createrepo_c "$html/rpm"
gpg --detach-sign --armor --local-user "$REPO_KEY_FPR" \
    --output "$html/rpm/repodata/repomd.xml.asc" "$html/rpm/repodata/repomd.xml"
cat > "$html/rpm/usb-creator.repo" <<EOF
[usb-creator]
name=usb-creator
baseurl=$REPO_BASE_URL/rpm/
enabled=1
gpgcheck=0
repo_gpgcheck=1
gpgkey=$REPO_BASE_URL/repo-key.asc
EOF

# --- pacman (Arch/CachyOS/EndeavourOS) ---------------------------------------
mkdir -p "$html/arch"
cp "$archdir"/usb-creator-*.pkg.tar.zst "$html/arch/"
cp "$archdir"/usb-creator.db* "$archdir"/usb-creator.files* "$html/arch/"
for f in "$html/arch"/usb-creator-*.pkg.tar.zst "$html/arch/usb-creator.db.tar.gz"; do
    gpg --detach-sign --local-user "$REPO_KEY_FPR" --output "$f.sig" "$f"
done
# pacman fetches the extension-less names (usb-creator.db, .db.sig,
# .files). repo-add emits them as symlinks, and CI artifact transfer may
# have flattened or dropped those — ship real files unconditionally.
rm -f "$html/arch/usb-creator.db" "$html/arch/usb-creator.db.sig" \
      "$html/arch/usb-creator.files"
cp "$html/arch/usb-creator.db.tar.gz"      "$html/arch/usb-creator.db"
cp "$html/arch/usb-creator.db.tar.gz.sig"  "$html/arch/usb-creator.db.sig"
cp "$html/arch/usb-creator.files.tar.gz"   "$html/arch/usb-creator.files"

# --- landing page -------------------------------------------------------------
sed -e "s|__REPO_URL__|$REPO_BASE_URL|g" \
    -e "s|__FPR__|$REPO_KEY_FPR|g" \
    -e "s|__VERSION__|$ver|g" \
    packaging/index.html > "$html/index.html"

echo "repository tree assembled in $html (version $ver)"

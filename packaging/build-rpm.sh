#!/usr/bin/env bash
#
# Build usb-creator noarch .rpm. Usage: build-rpm.sh <outdir>
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

out="${1:?usage: build-rpm.sh <outdir>}"
ver=$(sed -n 's/^VERSION="\(.*\)"/\1/p' usb-creator)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

mkdir -p "$work"/{SOURCES,SPECS}
cp usb-creator README.md LICENSE "$work/SOURCES/"

cat > "$work/SPECS/usb-creator.spec" <<EOF
Name:           usb-creator
Version:        $ver
Release:        1
Summary:        Create bootable Linux USB installers with verified downloads
License:        MIT
URL:            https://github.com/Reventlow/usb-creator
BuildArch:      noarch
Requires:       bash, coreutils, util-linux, curl, jq
Recommends:     gnupg2

%description
Downloads the latest ISO for a curated set of distros, verifies
checksums and (where published) GPG signatures with pinned keys,
writes with dd and verifies the write by reading it back. Refuses
to touch disks that back the running system.

%install
install -Dm755 %{_sourcedir}/usb-creator %{buildroot}%{_bindir}/usb-creator
install -Dm644 %{_sourcedir}/README.md %{buildroot}%{_docdir}/usb-creator/README.md
install -Dm644 %{_sourcedir}/LICENSE %{buildroot}%{_datadir}/licenses/usb-creator/LICENSE

%files
%{_bindir}/usb-creator
%doc %{_docdir}/usb-creator/README.md
%license %{_datadir}/licenses/usb-creator/LICENSE
EOF

rpmbuild --define "_topdir $work" -bb "$work/SPECS/usb-creator.spec"
mkdir -p "$out"
cp "$work/RPMS/noarch/usb-creator-${ver}-1.noarch.rpm" "$out/"
echo "built: $out/usb-creator-${ver}-1.noarch.rpm"

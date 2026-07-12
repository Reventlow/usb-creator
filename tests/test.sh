#!/usr/bin/env bash
#
# Offline test suite for usb-creator. No network, no root, no block devices:
# unit tests source the script (guarded main) and exercise pure functions;
# CLI tests run the script as a subprocess and assert on exit codes and
# messages. Run: tests/test.sh
set -u

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT="$TESTS_DIR/../usb-creator"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Keep the sourced script's cache/keyring inside the test sandbox.
export USB_CREATOR_CACHE="$WORK/cache"

PASS=0 FAIL=0

t() { # t <description> <command...> — expects success
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1)); echo "FAIL: $desc"
    fi
}

f() { # f <description> <command...> — expects failure
    local desc="$1"; shift
    if "$@" >/dev/null 2>&1; then
        FAIL=$((FAIL + 1)); echo "FAIL (expected failure): $desc"
    else
        PASS=$((PASS + 1))
    fi
}

eq() { # eq <description> <actual> <expected>
    if [[ "$2" == "$3" ]]; then
        PASS=$((PASS + 1))
    else
        FAIL=$((FAIL + 1)); echo "FAIL: $1 — got '$2', want '$3'"
    fi
}

# --------------------------------------------------------------------------
# Unit tests (sourced functions)
# --------------------------------------------------------------------------
# shellcheck source=../usb-creator
source "$SCRIPT"
set +e +o pipefail   # the tests manage control flow themselves

SUMS_GNU=$'aaaa1111  alpha.iso\nbbbb2222 *beta.iso'
SUMS_CRLF=$'cccc3333  gamma.iso\r\ndddd4444  delta.iso\r'
eq "checksum_for plain entry"     "$(checksum_for "$SUMS_GNU" alpha.iso)" "aaaa1111"
eq "checksum_for star-prefixed"   "$(checksum_for "$SUMS_GNU" beta.iso)"  "bbbb2222"
eq "checksum_for CRLF line"       "$(checksum_for "$SUMS_CRLF" gamma.iso)" "cccc3333"
eq "checksum_for CRLF last line"  "$(checksum_for "$SUMS_CRLF" delta.iso)" "dddd4444"
eq "checksum_for missing file"    "$(checksum_for "$SUMS_GNU" nope.iso)"  ""
eq "checksum_for uppercases hash" "$(checksum_for "EEEE5555  up.iso" up.iso)" "eeee5555"

for mp in / /boot /boot/efi /efi /home /home/gorm /usr/lib /var/log \
          /etc /opt/x /srv /root /tmp/y /nix "[SWAP]"; do
    t "is_critical_mount $mp" is_critical_mount "$mp"
done
for mp in /run/media/gorm/STICK /media/usb /mnt/data /data /backup; do
    f "is_critical_mount $mp (non-critical)" is_critical_mount "$mp"
done

eq "human_size 1 GiB" "$(human_size 1073741824)" "1.0G"
eq "human_size 0"     "$(human_size 0)" "0.0"

printf 'hello\n' > "$WORK/payload"
GOOD256=$(sha256sum "$WORK/payload" | awk '{print $1}')
GOOD512=$(sha512sum "$WORK/payload" | awk '{print $1}')
t "verify_hash sha256 match"      verify_hash "$WORK/payload" "$GOOD256" sha256
t "verify_hash sha512 match"      verify_hash "$WORK/payload" "$GOOD512" sha512
t "verify_hash uppercase input"   verify_hash "$WORK/payload" "${GOOD256^^}" sha256
f "verify_hash mismatch"          verify_hash "$WORK/payload" "$(printf '0%.0s' {1..64})" sha256
t "verify_hash algo none passes with warning" verify_hash "$WORK/payload" "" none

# looks_like_iso: build a minimal file with CD001 at offset 32769
head -c 40000 /dev/zero > "$WORK/fake.iso"
printf 'CD001' | dd of="$WORK/fake.iso" bs=1 seek=32769 conv=notrunc 2>/dev/null
t "looks_like_iso accepts CD001"  looks_like_iso "$WORK/fake.iso"
f "looks_like_iso rejects zeros"  looks_like_iso "$WORK/payload"

# dd_progress_bar: non-tty passthrough must forward the stream untouched
OUT=$(printf '1 bytes copied\rdd: some real error\n' | dd_progress_bar 100 2>&1)
case "$OUT" in
    *"dd: some real error"*) PASS=$((PASS + 1)) ;;
    *) FAIL=$((FAIL + 1)); echo "FAIL: dd_progress_bar non-tty passthrough" ;;
esac

# mktempf registers files that live under the cache dir
mktempf TFILE
t "mktempf creates file"          test -f "$TFILE"
case "$TFILE" in
    "$USB_CREATOR_CACHE"/*) PASS=$((PASS + 1)) ;;
    *) FAIL=$((FAIL + 1)); echo "FAIL: mktempf outside cache dir: $TFILE" ;;
esac

# --------------------------------------------------------------------------
# CLI behavior (subprocess)
# --------------------------------------------------------------------------
t "--version exits 0"             "$SCRIPT" --version
t "--help exits 0"                "$SCRIPT" --help
t "distros exits 0"               "$SCRIPT" distros
f "unknown argument rejected"     "$SCRIPT" bogus
f "unknown distro rejected"       "$SCRIPT" info no-such-distro
f "options without command rejected"        "$SCRIPT" --distro fedora --device /dev/null --yes
f "write without image rejected"            "$SCRIPT" write
f "write with both --distro and --iso"      "$SCRIPT" write --distro arch --iso x.iso --device /dev/null
f "write --yes without --device rejected"   "$SCRIPT" write --iso "$WORK/fake.iso" --yes
f "write to non-block-device rejected"      "$SCRIPT" write --iso "$WORK/fake.iso" --device "$WORK/payload" --yes
f "write to missing device rejected"        "$SCRIPT" write --iso "$WORK/fake.iso" --device /dev/no-such-dev --yes

OUT=$("$SCRIPT" --distro fedora 2>&1)
case "$OUT" in
    *"options need a command"*) PASS=$((PASS + 1)) ;;
    *) FAIL=$((FAIL + 1)); echo "FAIL: options-without-command message: $OUT" ;;
esac

echo "----------------------------------------"
echo "passed: $PASS  failed: $FAIL"
[[ $FAIL -eq 0 ]]

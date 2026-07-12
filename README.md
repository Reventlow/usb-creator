# usb-creator

A single-file bash tool that creates bootable USB installers for Linux
distributions — download, verify, write, verify again.

```
$ usb-creator write --distro fedora --device /dev/sdb
```

## Why

`dd` is fine until it isn't. This tool wraps the download-and-write workflow
with the guard rails you actually want:

- **Only whole removable/USB disks** are offered as targets. Any disk that
  backs a mounted system path (`/`, `/boot`, `/efi`, `/home`, swap, ...) or
  belongs to an imported ZFS pool is refused unconditionally — `--force`
  does not override that. If the mount table cannot be read at all, the
  tool refuses to write rather than assume the disk is idle.
- **Every download is checksum-verified** against the distro's official
  sums, fetched over HTTPS from the project's own infrastructure.
- **GPG signatures are verified with pinned keys** wherever the distro
  publishes them: signed checksum files for Ubuntu, Debian, Mint, Fedora
  and openSUSE; detached signatures over the ISO itself for Arch, Alpine
  and EndeavourOS. Keys live in a private keyring under the cache dir
  (your own GnuPG setup is never touched), and a signature from any key
  other than the pinned fingerprint fails the download. Pop!_OS, Bazzite
  and netboot.xyz publish no signatures — those remain checksum + TLS only.
- **Latest releases are resolved dynamically** — no hardcoded version numbers
  that go stale.
- **Writes are verified** by reading the device back (direct I/O, bypassing
  the page cache) and comparing checksums.
- **Confirmation requires typing the device name**, not just hitting enter.

## Installation

```bash
git clone https://github.com/Reventlow/usb-creator.git
cd usb-creator
```

Then pick one:

```bash
# Arch Linux: build and install the package
makepkg -si

# Any distro: install into your user PATH
install -Dm755 usb-creator ~/.local/bin/usb-creator

# Or system-wide
sudo install -Dm755 usb-creator /usr/local/bin/usb-creator
```

Quick install without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/Reventlow/usb-creator/main/usb-creator \
    -o ~/.local/bin/usb-creator && chmod +x ~/.local/bin/usb-creator
```

### Requirements

`bash` >= 4, `coreutils`, `util-linux` (lsblk 2.37+, findmnt), `curl`, `jq`,
and `sudo` for the privileged steps (dd, umount). `gnupg` is optional but
recommended — without it, signature verification is skipped with a warning.

```bash
# Arch
sudo pacman -S --needed coreutils util-linux curl jq gnupg
# Debian/Ubuntu
sudo apt install coreutils util-linux curl jq gnupg
# Fedora
sudo dnf install coreutils util-linux curl jq gnupg2
```

## Usage

```
usb-creator                          # interactive wizard
usb-creator list                     # list candidate USB devices
usb-creator distros                  # list supported distros
usb-creator info <distro>            # show resolved URL + checksum
usb-creator download <distro>        # download + verify into the cache
usb-creator write [options]         # write an image
```

### Write options

| Option | Meaning |
|---|---|
| `--distro <name>` | download (or reuse cached) ISO for `<name>` |
| `--iso <file>` | use a local image file instead |
| `--device <dev>` | target whole-disk device, e.g. `/dev/sdb` |
| `--yes` | skip confirmation (requires explicit `--device`) |
| `--force` | allow non-removable disks (system disks stay blocked) |
| `--no-verify` | skip post-write read-back verification |
| `--no-gpg` | skip GPG signature verification (checksums still checked) |

### Supported distros

| id | image |
|---|---|
| `ubuntu` | Ubuntu Desktop, latest LTS (amd64) |
| `debian` | Debian stable netinst (amd64) |
| `fedora` | Fedora Workstation Live, latest (x86_64) |
| `arch` | Arch Linux, latest monthly ISO (x86_64) |
| `mint` | Linux Mint Cinnamon, latest (64-bit) |
| `opensuse` | openSUSE Tumbleweed DVD, current snapshot (x86_64) |
| `alpine` | Alpine Linux standard, latest stable (x86_64) |
| `popos` | Pop!_OS latest LTS, Intel/AMD graphics image (amd64) |
| `endeavouros` | EndeavourOS, latest release (x86_64) |
| `bazzite` | Bazzite KDE desktop (gaming-focused Fedora), stable (amd64) |
| `netbootxyz` | netboot.xyz network installer (~2 MB, boots many distros) |

Anything else: pass your own image with `--iso file.iso`.

### Examples

```bash
# Interactive — pick distro and device from menus
usb-creator

# Non-interactive, for scripts (still refuses system disks)
usb-creator write --distro debian --device /dev/sdb --yes

# A local image you already have
usb-creator write --iso ~/isos/proxmox-ve_8.iso --device /dev/sdb

# Just check what "latest" resolves to
usb-creator info arch
```

Downloaded ISOs are cached in `~/.cache/usb-creator` (override with
`USB_CREATOR_CACHE` or `XDG_CACHE_HOME`) and reused when their checksum
still matches.

## Notes

- Images are written in dd mode (raw), which is what all the listed distros
  expect. Persistence overlays and multi-boot (Ventoy-style) are out of scope.
- Interrupting a write leaves the stick in an undefined state — just rerun.
- `usb-creator info <distro>` shows exactly what will be verified and with
  which key before you download anything.

## License

MIT

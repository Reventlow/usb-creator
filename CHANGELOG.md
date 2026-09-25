# Changelog

## Unreleased

### Changed
- The sudo password is now taken before the write confirmation, not after
  it. Authority and targeting are separate questions, and sudo is often no
  prompt at all (cached, passwordless, root), so it no longer interrupts
  between typing the device name and the write that confirmation authorises.
  Typing the device name is now the last act before `dd` starts.

## 1.2.1 — 2026-09-21

### Fixed
- Signing keys are now fetched from a list of sources with fallback, instead
  of a single keyserver. `keyserver.ubuntu.com` timed out for several minutes
  during the 2026-09-21 upstream watch and took the three Ubuntu-family
  resolvers down with it; eight distros depended on that one host.
- Ubuntu, Kubuntu and Ubuntu Server now take the CD image signing key
  first-party, from the `ubuntu-keyring` package source on Launchpad, with
  the keyservers as fallback only.
- `pgpkeys.eu` added as a second keyserver for the remaining keyserver-sourced
  keys. `keys.openpgp.org` was evaluated and rejected: it strips unverified
  user IDs, and GnuPG refuses to import a key with none.
- A fallback source that serves the wrong key — or a stripped one — is
  skipped exactly like an unreachable one, and never imported. Pinned
  fingerprints are checked against the downloaded file before import.

## 1.2.0 — 2026-09-21

### NixOS support
- The repository is now a Nix flake. `nix run github:Reventlow/usb-creator`
  works with nothing installed; `nix profile install` and declarative
  `environment.systemPackages` use are documented in the README.
- The package wraps every runtime dependency into the binary's `PATH` —
  including `gawk`, `gnugrep` and `gnused`, which FHS distros take for
  granted but Nix ships separately. Verified by running a live resolver in
  an empty environment. `sudo` is deliberately not bundled: privileged steps
  go through the host's setuid binary.
- The package version is parsed from the script's own `VERSION=` line, so
  the release routine gains no extra place to bump.
- The requirements list now names `awk`, `grep` and `sed` explicitly.

## 1.1.0 — 2026-09-07

### Omarchy resolver hardening
- The resolver now version-sorts every ISO link found on omarchy.org and
  takes the newest, instead of the first match on the page.
- New version floor: Omarchy releases below 4.0.0 are refused with a
  clear error, so a homepage rollback or stale page can never silently
  hand out a pre-4 ISO.
- New reusable `version_at_least()` helper (sort -V semantics, so 4.10
  ranks above 4.9) with unit tests.

### Fixed
- EndeavourOS: the first-party checksum page moved from `/latest-release/`
  to `/download/`, breaking the resolver (caught by the 2026-09-07 upstream
  watch). The new location is primary, the old one a fallback. The site
  root is no longer a fallback — it lists the ISO filename but no
  checksum, which turned a moved page into a misleading error.

## 1.0.0 — 2026-07-21

First stable release. The 1.0 gate was empirical, not ceremonial: an
ISO write (Arch) and a raw-image write (Tails) each taken from resolver
through GPG-verified download, dd write, and read-back verification to
an actual UEFI boot on real hardware, plus one fully unattended weekly
monitoring cycle.

What the 0.x arc built:

### Systems
- 27 Linux and BSD systems, grouped desktop/server, every release
  resolved dynamically from upstream — no hardcoded versions anywhere.

### Verification
- SHA-256/SHA-512 checksums for every upstream that publishes them,
  GPG verification with pinned key fingerprints for the twelve that
  sign (checksum files or the image itself; Fedora and AlmaLinux
  clearsigned, dual-source cross-checked).
- Trust rules codified in ADR-0003: expectations only from
  infrastructure the project controls; mirrors serve bytes, never trust.
- Upstreams without usable integrity data are supported but loudly
  marked TLS-only — "verified" is never diluted.

### Safety
- Fail-closed device ladder: whole removable disks only; unconditional
  refusal of disks backing mounted system paths or imported ZFS pools;
  hard abort when mounts cannot be enumerated; typed device-name
  confirmation; post-write read-back verification via direct I/O.

### Interface
- Interactive wizard (desktop/server → system → device), warm-palette
  TUI, live progress bars, `man` and tldr pages, checksum-verified
  `update` command that respects package-managed installs.

### Distribution & operations
- Sigstore-attested GitHub releases with SPDX SBOM; self-hosted
  apt/dnf/pacman repository with signed metadata and signed rpm/pacman
  packages; automatic image deployment on release with push
  notifications; weekly upstream health sweep reporting publicly, by
  mail, and by push — with an agent that drafts resolver fixes.

Detailed history: `git log v0.1.0..v1.0.0`.

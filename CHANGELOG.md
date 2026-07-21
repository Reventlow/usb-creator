# Changelog

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

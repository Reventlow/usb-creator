# 0002 — dd-mode images only, no Ventoy/persistence

Status: accepted

## Context

All supported distros ship hybrid ISOs designed for raw writing.
Multi-boot solutions (Ventoy et al.) interpose their own bootloader, and
persistence overlays modify the image on first boot.

## Decision

Write images raw with `dd` (direct I/O, fsync). No multi-boot layout, no
persistence overlay — one stick holds one raw image. Precisely:

- The write is verified by reading the device back and comparing hashes
  **by default**; `--no-verify` skips only that read-back step (for
  scripted bulk writes), never the pre-write download verification.
- `--iso` accepts any local file. If it lacks an ISO9660 signature the
  tool warns and requires explicit confirmation, then still writes it
  raw — dd semantics apply regardless of format (useful for raw disk
  images like Proxmox or firmware updaters).

## Consequences

- The bytes on the stick equal the source image; when read-back runs,
  that equality is proven end to end.
- One stick holds one installer at a time.
- No third-party bootloader enters the trust surface.

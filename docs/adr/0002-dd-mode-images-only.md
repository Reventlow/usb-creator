# 0002 — dd-mode images only, no Ventoy/persistence

Status: accepted

## Context

All supported distros ship hybrid ISOs designed for raw writing.
Multi-boot solutions (Ventoy et al.) interpose their own bootloader, and
persistence overlays modify the image on first boot.

## Decision

Write images raw with `dd` (direct I/O, fsync) and verify by reading the
device back. No multi-boot, no persistence.

## Consequences

- The bytes on the stick equal the verified ISO — the read-back check is
  meaningful end to end.
- One stick holds one installer at a time.
- No third-party bootloader enters the trust surface.

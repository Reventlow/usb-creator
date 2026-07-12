# Architecture Decision Records

Deliberate, load-bearing decisions for usb-creator. Context and the full
system picture live in [../ARCHITECTURE.md](../ARCHITECTURE.md).

| # | decision |
|---|---|
| [0001](0001-single-file-bash-tool.md) | Single-file bash tool, no `src/` split |
| [0002](0002-dd-mode-images-only.md) | dd-mode images only — no Ventoy/persistence |
| [0003](0003-first-party-trust-anchors.md) | First-party trust anchors and pinned GPG keys |
| [0004](0004-fail-closed-device-safety.md) | Fail-closed device safety |
| [0005](0005-explicit-none-integrity-class.md) | Explicit "none" integrity class for checksum-less upstreams |

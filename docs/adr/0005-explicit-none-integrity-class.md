# 0005 — Explicit "none" integrity class for checksum-less upstreams

Status: accepted

## Context

Omarchy publishes neither checksums nor signatures. Hashing a file we
just downloaded and "verifying" against that proves nothing, but users
still want the distro supported.

## Decision

Support a `RESOLVED_ALGO="none"` class: the resolver declares that no
upstream integrity data exists, and the tool warns loudly at resolve
time, download time and in `info`/README that trust rests on TLS alone.
No fabricated verification. The post-write read-back check (stick vs
local file) still runs.

## Consequences

- The word "verified" keeps its meaning for every other distro.
- Users make an informed choice per distro; `info` shows the class.
- If such an upstream starts publishing checksums, the resolver upgrades
  and the class disappears from its output.

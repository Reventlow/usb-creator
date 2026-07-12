# 0004 — Fail-closed device safety

Status: accepted

## Context

The tool's worst failure mode is writing over the running system or a
data disk. Safety checks that silently pass when their inputs are missing
are worse than no checks — they create false confidence (found and fixed
during adversarial review: an lsblk failure used to read as "no mounts").

## Decision

Refuse to write unless safety can be positively established: whole
removable disks only; unconditional refusal of disks backing critical
mountpoints or imported ZFS pools; hard abort if the mount table cannot
be enumerated; `--force` lifts only the removability requirement, never
the system-disk refusals; confirmation requires typing the device name.

## Consequences

- Transient tooling failures block writes instead of allowing them.
- Old util-linux (< 2.37, no MOUNTPOINTS column) is rejected at startup.
- A wiped, unmounted internal disk can still be written deliberately with
  `--force` + explicit confirmation — that is the intended escape hatch.

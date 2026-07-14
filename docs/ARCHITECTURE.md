# Architecture

`usb-creator` is deliberately a **single bash file**. Its job — resolve an
ISO, verify it, write it to a stick without destroying the wrong disk — is
a linear pipeline with safety gates, and a single auditable file is itself
a security feature: anyone can read the entire trust model in one sitting.

## Pipeline

```
resolve ──▶ download ──▶ verify ──▶ prepare device ──▶ write ──▶ read back
   │            │           │             │               │          │
 distro      resumable   checksum      refusal          dd with    device
 registry,   curl into   (sha256/512)  ladder:          direct     re-read,
 scrapes     cache dir   + GPG with    system disks,    I/O +      hash
 official                pinned keys   ZFS pools,       fsync      compared
 "latest"                              non-removable,              to ISO
 locations                             typed confirm
```

Sections in the script map 1:1 to this: output helpers → GPG verification →
distro registry (one `resolve_<id>()` per distro) → device handling →
download & checksum → writing → commands/wizard → argument parsing.

## Trust model

The checksum (and where published, a GPG signature) must come from
infrastructure the distro project controls; third-party mirrors may only
ever serve bytes, never the expectation those bytes are checked against.

| class | distros | anchor |
|---|---|---|
| signed checksums | ubuntu(+server), kubuntu, debian, mint, opensuse, kali, almalinux | detached sig over the sums file, pinned key fingerprint |
| signed checksums, rotating keys | fedora, fedora-server | clearsigned CHECKSUM, keys pinned per-run from first-party `fedora.gpg`, cross-checked against releases.json |
| signed ISO | arch, alpine, endeavouros, cachyos, tails, qubes | detached sig over the image, pinned key |
| checksum only | popos, bazzite, garuda, manjaro, zimaos, freebsd, openbsd, netbootxyz | checksum from first-party host, TLS |
| none (upstream publishes nothing) | omarchy | TLS only — warned loudly at every step |

GPG keys live in a private keyring under the cache dir; the user's own
GnuPG setup is never read or written. A signature from any key other than
the pinned fingerprint fails the download, regardless of how the key was
fetched — the pin is the anchor, not the transport.

## Safety ladder (device writes)

1. Whole-disk block device only, never a partition.
2. Mountpoints of the disk **and all descendants** (partitions, LUKS, LVM)
   are enumerated; anything critical (`/`, `/boot`, `/efi`, `/home`, swap,
   ...) is an unconditional refusal — no flag overrides it.
3. If the mount table cannot be read, refuse — **fail closed**, never
   assume a disk is idle.
4. Members of imported ZFS pools are refused (invisible to mount checks).
5. Non-removable, non-USB disks require `--force` (rungs 1–4 still apply).
6. Confirmation requires typing the device name; `--yes` (scripting)
   requires an explicit `--device`.
7. After writing, the image-sized prefix of the device is read back with
   direct I/O and its hash compared against the source file.

## Decisions

Full records live in [adr/](adr/); summaries:

- **dd-mode images, no Ventoy/persistence**: every supported distro ships
  hybrid ISOs that expect raw writing; multiboot adds a bootloader that
  becomes part of the trust surface.
- **`set -euo pipefail` + explicit `|| die` on every network/parse step**:
  resolver failures must be loud, never silently produce an empty value
  that downstream code treats as data.
- **Resolvers scrape "latest", never hardcode versions**: staleness is a
  worse failure mode than a scrape breaking loudly (a weekly CI job
  exercises every resolver against live upstream).
- **Checksum-less upstreams get an explicit "none" class** rather than a
  fabricated self-hash: hashing what was just downloaded proves nothing,
  and pretending otherwise would corrupt the meaning of "verified" for
  every other distro.
- **Single file over `src/` split**: the whole program is ~1100 lines; the
  cost of navigation is lower than the cost of losing at-a-glance
  auditability. Tests live separately in `tests/`.

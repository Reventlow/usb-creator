# 0003 — First-party trust anchors and pinned GPG keys

Status: accepted

## Context

A mirror that serves both an ISO and its checksum can serve a
self-consistent malicious pair (the 2016 Linux Mint incident). TLS alone
authenticates the host, not the content's origin.

## Decision

The *expectation* (checksum or signature) must come from infrastructure
the distro project controls, or be signed by a key whose fingerprint is
pinned in the script after cross-checking the project's published
verification documentation. Mirrors may serve bytes; they may only serve
checksums where a pinned signature covers them (e.g. Debian's mirror
fallback). GPG keys live in a private keyring under the cache dir; the
signer's primary fingerprint must match the pin — the key transport is
irrelevant to trust.

## Consequences

- A compromised mirror yields a hard verification failure, not a bad stick.
- Key rotations (Kali 2025) require a deliberate pin update; Fedora's
  per-release keys are pinned dynamically from the first-party bundle.
- Resolvers are per-distro code that scrapes official locations and fails
  loudly; a weekly CI job exercises them against live upstream.

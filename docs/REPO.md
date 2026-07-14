# Package repository

Every release tag builds `.deb`, `.rpm` and pacman packages, assembles
GPG-signed apt/rpm/arch repository trees, and bakes them into a static
nginx image (`.github/workflows/repo.yml`):

```
ghcr.io/reventlow/usb-creator-repo:latest     # current release
ghcr.io/reventlow/usb-creator-repo:<version>  # pinned versions
```

The repository *is* the image — the served repo updates by pulling the
new tag, and any past state can be reproduced by running an old one.
It is served at **https://usb-creator.blacklog.net** with client setup
instructions on the landing page.

## Trust chain

1. GitHub Actions builds the packages from the tagged source and attests
   the release binaries (Sigstore).
2. The repository metadata (apt `InRelease`, rpm `repomd.xml.asc`, pacman
   `.db.sig` + package `.sig`) — and additionally each RPM itself
   (embedded signature, `gpgcheck=1`) — is signed in CI with the dedicated repo key
   `CA013C00F3BBC48E84FB0240FA345B35D11154EA`
   (public: `packaging/repo-key.asc`, served at `/repo-key.asc`).

Anyone can therefore verify both *what was built* (attestation) and
*that the repo they're talking to serves those bytes* (signature),
independently of the host serving the files.

## Client setup

Copy-paste blocks live on the landing page; in short:

- **apt**: key to `/usr/share/keyrings/usb-creator.asc`, one
  `deb [signed-by=...] .../apt stable main` line, `apt install usb-creator`.
- **dnf/zypper**: drop `.../rpm/usb-creator.repo` into
  `/etc/yum.repos.d/`, `dnf install usb-creator`.
- **pacman**: `pacman-key --add` + `--lsign-key` the repo key, add the
  `[usb-creator]` server section, `pacman -Sy usb-creator`.

The base URL is configurable for forks via the `REPO_BASE_URL` Actions
variable; the image is plain nginx serving static files, so it can be
hosted anywhere.

## Key rotation

If the key must be rotated (or revoked after compromise): generate a new
key, update `packaging/repo-key.asc` + `packaging/repo-key.fpr`, replace
the `REPO_SIGNING_KEY` secret, tag a release, and announce the new
fingerprint in the release notes. Clients re-import the key from
`/repo-key.asc`.

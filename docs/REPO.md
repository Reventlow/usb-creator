# Self-hosted package repository

Every release tag builds `.deb`, `.rpm` and pacman packages, assembles
GPG-signed apt/rpm/arch repository trees, and bakes them into a static
nginx image (`.github/workflows/repo.yml`):

```
ghcr.io/reventlow/usb-creator-repo:latest     # current release
ghcr.io/reventlow/usb-creator-repo:<version>  # pinned versions
ghcr.io/reventlow/usb-creator-repo:test       # manual workflow runs
```

The repository *is* the image — updating the served repo means pulling
the new tag; rolling back means running the previous one.

## Trust chain

1. GitHub Actions builds the packages from the tagged source and attests
   the release binaries (Sigstore).
2. The repository metadata (apt `InRelease`, rpm `repomd.xml.asc`, pacman
   `.db.sig` + package `.sig`) is signed in CI with the dedicated repo key
   `CA013C00F3BBC48E84FB0240FA345B35D11154EA`
   (public: `packaging/repo-key.asc`, served at `/repo-key.asc`).
   The private key exists in two places: the maintainer's local keyring
   and the `REPO_SIGNING_KEY` GitHub Actions secret.

## Server setup (ZimaOS + nginx-proxy-manager)

1. **App** — ZimaOS → App Store → Install a customized app:
   - Image: `ghcr.io/reventlow/usb-creator-repo:latest`
   - Port: host `8090` → container `80`
   - No volumes, no privileges needed (static files only).
2. **DNS** — `A` record for `repo.reventlow.com` → your public IP
   (dynamic-DNS update if the home IP changes).
3. **Router** — forward TCP 80 and 443 to the Zima box
   (nginx-proxy-manager listens on 8080/8443; map 80→8080, 443→8443).
4. **nginx-proxy-manager** — add a Proxy Host:
   - Domain: `repo.reventlow.com` → `http://<zima-ip>:8090`
   - SSL: request a Let's Encrypt certificate, enable Force SSL + HTTP/2.
5. **Updates** — after each release, pull the new image (ZimaOS update
   button, or the `update_app_image` automation). Nothing else changes.

The public base URL is `https://repo.reventlow.com` by default; override
with a repository Actions variable `REPO_BASE_URL` if the domain differs.

## Client setup

Served on the landing page (`https://repo.reventlow.com`) with copy-paste
blocks; in short:

- **apt**: key to `/usr/share/keyrings/usb-creator.asc`, one
  `deb [signed-by=...] .../apt stable main` line, `apt install usb-creator`.
- **dnf/zypper**: drop `.../rpm/usb-creator.repo` into
  `/etc/yum.repos.d/`, `dnf install usb-creator`.
- **pacman**: `pacman-key --add` + `--lsign-key` the repo key, add the
  `[usb-creator]` server section, `pacman -Sy usb-creator`.

## Key rotation

Generate a new key, update `packaging/repo-key.asc` + `repo-key.fpr`,
replace the `REPO_SIGNING_KEY` secret, tag a release. Clients re-fetch
the key from the landing page; announce the new fingerprint in the
release notes.

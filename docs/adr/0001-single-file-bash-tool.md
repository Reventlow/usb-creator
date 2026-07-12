# 0001 — Single-file bash tool, no `src/` split

Status: accepted

## Context

The tool is a linear pipeline (~1100 lines) whose main value is a safety
and trust model the user can audit. Splitting it into modules would add
navigation and a build/concat step.

## Decision

Ship one executable bash file at the repo root. Tooling that is not the
product (tests, SBOM generation, CI) lives in `tests/`, `scripts/` and
`.github/`.

## Consequences

- Anyone can read the entire trust model in one sitting; `install` is `cp`.
- Repo-structure conventions expecting `src/` are knowingly not met.
- If the file grows well beyond its current size, revisit.

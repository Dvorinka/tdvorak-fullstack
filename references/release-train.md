# Release train

Release-mechanics conventions. Read before tagging, releasing, or
publishing artifacts. Each repo encodes its flow differently — document
the repo's flow once and follow it verbatim; do not generalize between
repos.

## What to pin down per repo

- **The version source of truth** — a single constant/file that the
  release workflow reads (`Version` constant, `versionName`/`versionCode`,
  `package.json`). Bump it in the release commit, never ad-hoc at tag
  time.
- **Tag semantics** — if one repo ships multiple artifacts
  (server/desktop/mobile), decide what `v*` tags cover and use
  platform-scoped tags (`android-v*`, `desktop-v*`) for single-platform
  releases. Annotate them.
- **The trigger** — tag push vs release PR merge vs manual deploy script.
  Write it down; "how do I ship this repo" should be a one-line answer.
- **Changelog discipline** — release notes/CHANGELOG entries land in the
  release commit, not after. A changelog is the audit trail; backfill
  rather than leave gaps.
- **Lockfiles** — committed lockfiles for every ecosystem the release
  builds (Rust, JS, Go modules); a gitignored lockfile means deps float on
  every CI run and releases are not reproducible.

## Self-updating artifacts

- When a fleet pulls a signed update manifest from release assets, the
  release must publish **manifest + signature** — a release that ships the
  image but not the manifest leaves every install behind silently.
- Version-stamp the built artifact at build time (`--build-arg
  VERSION=…`); an unstamped "dev" build can neither self-update nor be
  distinguished from a release in the field.

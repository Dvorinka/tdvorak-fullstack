# Toolchain — quality gates

The machinery that enforces the rules in `architecture.md` and `ui-standards.md`.
A rule without a machine checking it is a wish. Applies to every project.

## JS/TS lint — Oxlint

- Linter: **oxlint** (Rust, ESLint-compatible rule names, ~50-100x faster). Never ESLint, never Biome.
- Config committed per package. `oxlint.config.ts` when `jsPlugins` need object form (local vendored plugins); `.oxlintrc.json` is fine otherwise.
- **anti-slop** (vendored `dmmulroy/anti-slop` → `tools/oxlint/anti-slop/`): the adopted set in `architecture.md` — greenfield React/TS frontends. Requires `@oxlint/plugins` pinned to the exact oxlint version; keep both versions exact.
- **@shadcn/lint**: agent-first design-system linter for **React + Tailwind v4**. Add via `jsPlugins: ["@shadcn/lint"]`, needs oxlint ≥1.80. Start new rules at `warn`, ratchet to `error` after cleanup. Not for SolidJS / Tailwind v3.
- SolidJS projects: `typescript` + `unicorn` + `oxc` plugins only (no `react` rules).
- Type-aware linting: enable `--type-aware` where supported (tsgo).

## Formatting

- **oxfmt** (`format` / `format:check` scripts). Never Prettier.
- Go: `gofmt -l` must output nothing — gate it.

## Go

- CI minimum: `go build`, `go test`, `go vet`, `gofmt -l`.
- **`golangci-lint`** in every Go CI job (`golangci/golangci-lint-action`, `version: v2.x`, `default: standard` in `.golangci.yml`). `go vet` alone misses errcheck (unchecked `Close`/`Rollback`/`Scan`), staticcheck QF/SA rules and dead code — first run on a vet-clean repo still found real findings. Fix before gating; never `--issues-exit-code=0`.
- **`govulncheck`** (`go run golang.org/x/vuln/cmd/govulncheck@latest ./...`) in every Go CI job. Fix reachable vulns by bumping to the listed "Fixed in" version.
- **Dev loop: `air`** — committed `apps/<api>/.air.toml`; `cd apps/api && air` rebuilds+restarts on save.
- **Profiling: stdlib pprof** — opt-in mount behind an env flag (`PPROF=1` → `/debug/pprof/*`, `gin.WrapF(pprof.Index)` + named `pprof.Handler` routes). Never on by default on a public deploy; `go tool pprof` against the URL.

## Task runner — just

- **`justfile`** at repo root (not Makefile): `just --list` is self-documenting, recipes wrap the per-package commands (`just check` = build+test+lint both stacks). `brew install just`. Skip if the repo already has a working Makefile — duplicate runners are worse than either alone.
- Anything run more than once belongs in a recipe. Env-gated suites especially: a `just e2e` that creates the test DB and exports the DSN beats a shell incantation the next agent has to rediscover.

## Shell env — direnv

- **`direnv`** (`brew install direnv`, hook already in `~/.bashrc`) — committed `.envrc` per repo loads env automatically per checkout (`direnv allow` once). Put gated vars here or in a `just` recipe: if a suite env-gates on an unset var it silently skips and reads as green. `.envrc` needs a `!.envrc` gitignore exception next to `!.env.example` — `.env.*` patterns would swallow it.

## API collections — Bruno

- **`bru`** — Postman alternative, collections as plain `.bru` files committed under `bruno/` (`bru run --env prod` works headless in CI). Keep a small hand-maintained collection of the public/health endpoints; environments as `environments/{local,prod}.bru` with `{{base}}`. Not a substitute for generated OpenAPI clients — it's the poke-the-API drawer.

## Security scanning

- **gitleaks** — see lefthook; plus one full-history scan on new repos.
- **trivy fs** (`--scanners vuln,secret --severity HIGH,CRITICAL`) — lockfile + filesystem CVE sweep; run in CI or as `just audit`. Flags committed deps AND stray `.env` secrets on disk (both real findings on first run).
- **OWASP ZAP baseline** — `docker run ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t <url>` (passive spider+scan, safe on prod; this box needed `-u root` — the zap uid can't write its own image home). Its first-pass catches are almost always missing security headers — fix in the edge config (Caddy `header` block / Vercel `headers`), then re-scan to green. Active scans only against staging.
- **Dependabot** (`.github/dependabot.yml`) — grouped weekly `gomod`/`npm`/`github-actions`/`docker` updates. File-based, zero infra. Prefer over Renovate at this scale (Renovate needs the Mend app installed or a self-hosted action; its value — automerge, richer grouping — isn't worth the plumbing for a solo repo). Revisit if update PR noise becomes real.

## Observability — OpenTelemetry (adopt on demand)

- otelgin/otelpgx + OTLP exporter when a project needs distributed traces or metrics beyond logs. Requires a collector + backend (Jaeger/Tempo) — that infra is the real cost, so it's not a default. Standard logging (slog/zap) stays the floor until then.

## CI-as-code — Dagger (adopt on demand)

- Verified working (`dagger -c 'container | from alpine | with-exec echo ok | stdout'`), but engine pull is ~2min and it runs a privileged daemon. Only worth it when pipelines must run identically local+CI or GH Actions YAML gets painful. Current gate (push → CI → deploy) doesn't need it.

## Explicitly skipped

- ESLint (oxlint covers it), Biome (overlaps oxc), Prettier (oxfmt), husky/lint-staged (lefthook).
- **Semgrep** — evaluated on the Go API + web: only Dockerfile hygiene findings, no signal beyond golangci-lint/oxlint. Skip unless a project carries untrusted input paths (uploads, parsers) at scale.
- **devcontainers** — `.devcontainer` for repo onboarding only when external contributors appear; solo dev on a working box doesn't need the abstraction.
- Vite+ (`viteplus.dev`): unified vp toolchain — evaluate on next greenfield, do not migrate working repos onto RC releases.

## Hooks — lefthook

- **lefthook** at repo root (`lefthook.yml`), single binary, polyglot. `lefthook install` once per clone.
- `pre-push` runs: JS lint, `gofmt -l`, `go vet && go test`, `gitleaks git --log-opts="origin/<default>..HEAD"` (push-range scoped; full-history scan is a one-time repo audit, see Periodic hygiene).
- This is what makes the AGENTS.md pre-push gate non-negotiable — it is enforced by the hook, not by convention.

## CI

- **CI must run the linter.** A linter that only runs locally does not exist.
- Lint before build in frontend jobs. Warnings don't fail the build; errors do.
- New rules land at `warn` on existing code, `error` on greenfield — ratchet warn → error after a dedicated cleanup pass, never bulk-ignore.

## Local CI verification — act, actionlint, shellcheck

- **act** (`brew install act`) — runs GitHub Actions workflows locally (`act -j <job>`, `act push`). Use when changing `.github/workflows/*` so YAML and step-logic failures surface before push, not in the remote run. `ciwatch wait` remains the remote side.
- **actionlint** — static lint for workflow YAML (undefined matrix keys, `run:` shell errors via embedded shellcheck). Wire into lefthook on `.github/workflows/**` paths in repos that ship workflows.
- **shellcheck** — lint every committed `.sh` and hook script before push; it flags the quoting/exit-code bugs that only fail on the machine that matters.

## Self-hosted CI — KERN

- **KERN** (https://github.com/Dvorinka/kern) — self-hosted, GitHub Actions-compatible CI: Go API + Postgres control plane, containerized job execution across a Linux/Windows/macOS runner fleet, GitHub App webhooks in, check runs + commit statuses back out on the PR. Standard `.github/workflows/` YAML runs unmodified.
- `kern` CLI (install from the repo): `kern doctor` health probe, `kern runs` / `kern runs logs -f` to watch runs, `kern lint` compiles workflows offline with no server, `kern hooks install` writes a pre-push hook that runs `kern lint`.
- Agent surface: streamable-HTTP MCP endpoint at `/api/v1/mcp` (run lifecycle, logs, runners, secrets) — tool matrix in `docs/connect.md` upstream.
- Repo porting ledger and known gaps (arm64 images, `vars` context, docker-on-fork-PRs) live in the KERN repo at `docs/porting.md` — check it before moving a repo's CI over.

## HTTP debugging — mitmproxy

- `mitmproxy` interactive / `mitmdump` headless — capture, inspect, replay HTTP(S) when the bug is on the wire: webhooks, third-party APIs, mobile-app traffic. Point the client at `http://localhost:8080` with the mitm CA installed.

## Tests — the pyramid, in order of priority

Each layer exists to answer a different question. Do not build a higher layer to cover a lower layer's job.

1. **Unit** — `go test` for Go logic (required). `vitest` for frontend pure logic only (formatters, parsers, mappers, stores) — no test scaffolding for its own sake.
2. **Integration** — **testcontainers-go** for Postgres-backed tests: real DB in Docker, migrations applied, pgx queries verified against a live instance. Adopt when the first DB-coupled test is written — not before. Billing/webhook paths qualify first.
3. **E2E** — **Playwright** committed specs per app: a minimal smoke suite covering the money path only (e.g. signup → checkout; select slot → book → manage link). Runs in CI. This is the currently missing layer — ad-hoc MCP browser checks are not a substitute.
   - **Mobile e2e: Maestro** — human-readable YAML flows committed under `apps/<app>/.maestro/`; `maestro test` on emulator/simulator or Maestro Cloud in CI; `maestro mcp` exposes the device to agents for authoring. Also runs `url:` web flows — a zero-install smoke option when no emulator exists. Committed flows are the artifact; ad-hoc device poking is not a substitute.
   - **Desktop e2e** — Maestro does **not** cover desktop shells (mobile + web only). Tauri apps: `tauri-driver` + WebdriverIO (bridges the system webview's WebDriver — webkit2gtk / WKWebView / WebView2). Electron: **Playwright** has first-class support. When the desktop app is a thin shell over the same web bundle, the web e2e suite already covers the UI — add a desktop lane only for shell features (tray, updater, native dialogs).
4. **Load** — **k6** (`grafana/k6`) — JS scenario scripts + Go runtime. The designated tool for pre-launch and perf-sensitive endpoints; smoke stage (a few VUs, thresholds like `p(95)<400` as SLO gates) may run in CI. Adopt on first public launch or when an endpoint's load matters — not before.

## Billing/webhook test fixtures

- `stripe fixtures` (Stripe CLI) to seed checkout/session/webhook events locally when writing billing integration tests. Never hand-rolled webhook payloads.

## Periodic hygiene

- **`knip`** — dead-export/unused-dep sweep. Run manually every few months or before a cleanup PR; never a gate.
- Full-history `gitleaks` scan on new repos before adding them to the workflow (one-time audit, not a per-push job).

## Explicitly skipped

- ESLint (oxlint covers it), Biome (overlaps oxc), Prettier (oxfmt), husky/lint-staged (lefthook), Dependabot (noise at this scale — revisit if deps rot).
- Vite+ (`viteplus.dev`): unified vp toolchain — evaluate on next greenfield, do not migrate working repos onto RC releases.

# Architecture Defaults

Single source of truth for system design unless explicitly overridden. Read before any backend/infra/API/DB decision.

## Stack

| Layer | Default | Alt (only if user asks) | Skill |
|---|---|---|---|
| Frontend | **React 18 + Vite + TS strict + Tailwind + shadcn/ui** | SolidJS + Vite | `react-expert`, `vercel-react-best-practices` / `solidjs-expert` |
| UI primitives | Ark UI + shadcn/ui (React) / shadcn-solid (SolidJS) | — | `shadcn` |
| Backend | **Go + Gin**, `zap` logging | Rust (only with clear perf/ML/ecosystem win) | `golang-pro`, `go-expert` / `rust-engineer` |
| DB | **PostgreSQL + sqlc + goose** | — | `postgres-pro`, `neon-postgres`, `sql-pro`, `database-optimizer` |
| Cache | **DragonflyDB** (Redis-compatible, multi-threaded, drop-in replacement — prefer over Redis) | Redis only if DragonflyDB blocked | `database-optimizer` |
| Auth | **Better Auth** (cookie sessions) | Neon Auth (user opts out of local) | `secure-code-guardian`, `security-reviewer` |
| API contract | **OpenAPI** → generate TS client + types | — | `api-designer` |
| Infra | **Docker Compose** (`docker compose up` runs full stack); Nginx/Traefik for TLS/routing/LB | — | `devops-engineer` |
| Desktop | **Wails** (Go+Web) | Tauri (Rust+Web, smaller footprint) | `wails`, `tauri-v2` |
| Mobile | **React Native + Expo** | — | `react-native-expert` |
| Mobile e2e | **Maestro** — YAML flows, `maestro test` CLI, MCP server, Studio | Playwright (web only, when no device/CI mobile lane) | — |
| Desktop e2e | **tauri-driver** + WebdriverIO (Tauri), **Playwright** (Electron) — only for shell features; a web-bundle shell is covered by web e2e | — | — |
| GRC / compliance | **Probo** (getprobo/probo, MIT) — self-hosted SOC2/ISO27001/GDPR platform; adopt only when a project needs evidence/audit workflows, not a default layer | — | — |
| TUI | **BubbleTea** (charmbracelet/bubbletea) | — | `cli-developer` |
| Design system | **Boneyard** (https://github.com/0xGF/boneyard) — everywhere | — | — |

**React is priority. SolidJS is secondary, only when user explicitly requests. Never mix in one project.**

All UIs must: responsive, dark/light, a11y-first. Do not introduce frameworks/tools without clear justification.

## Monorepo Layout

```
/apps
  /frontend
  /backend
/packages
  /api-client       # generated from OpenAPI
  /shared-types
/infra
  docker-compose.yml
  nginx (or traefik)
```

Rules: strict frontend/backend separation. No cross-importing backend logic into frontend. Shared code explicit and intentional. Enables independent CI/CD and scaling.

## Go Skill Routing (MUST consult before writing Go)

| Scenario | Invoke |
|---|---|
| New Go API service | `golang-pro` |
| Concurrency / goroutines / channels | `golang-pro` |
| Performance / benchmark / pprof | `golang-pro` |
| gRPC service | `golang-pro` |
| DB integration in Go | `golang-pro` + `postgres-pro` |
| CLI tool / stdlib-heavy | `go-expert` |
| Testing / table-driven / mocking | `go-expert` |

Never write Go backend code without first consulting the relevant skill. These encode production-tested concurrency safety and performance rules for this stack.

## Backend Principles
Small, explicit packages. No magic abstractions. Separate routing, business logic, data access. Readability over cleverness. Context propagation. `slog`/`zap` structured logging. CGO-free.

## API Contract Rules
- OpenAPI is the single source of truth.
- Generate TS client, shared types, request helpers.
- Never manually duplicate API types in frontend.
- Backend drives contract, not frontend guesses.

## DB Rules
- All schema changes via versioned goose migrations.
- Never modify production schema manually.
- Treat DB evolution as a controlled process.
- Use sqlc for type-safe queries.

## Cache Rules (DragonflyDB)
- Default cache layer: **DragonflyDB** (Redis-compatible, multi-threaded, drop-in).
- Use for: session store (if not in DB), rate limiting, hot-path read cache, queue-ish structures.
- Prefer DragonflyDB over Redis unless explicitly blocked.
- Never cache sensitive data without encryption at rest.

## Stripe (if used)
- Always `stripe-kv-sync`. No custom/ad-hoc implementations.
- Webhooks: verified + idempotent. Payment state KV-synced with backend storage.

## Code Quality
Strict TS everywhere. Small focused functions. Clear naming. Strong module boundaries. Optimize for maintainability and predictability, not cleverness. No premature optimization, no structural mess.

Quality skills: `code-reviewer`, `desloppify`, `security-best-practices`, `test-master`.

## TypeScript Evidence Rules (Oxlint + anti-slop)

Strict TS is the floor. Oxlint with a vendored, trimmed copy of `dmmulroy/anti-slop` enforces evidence preservation on top of it. Applies to TS/JS frontend layers only (React, SolidJS, Wails/Tauri web layer). Irrelevant for Go backends.

### Install approach
Vendor `src/` from `dmmulroy/anti-slop` into `tools/oxlint/anti-slop/`. Do not install as npm dependency. Own and prune the rules. Use the bundled `install-anti-slop` skill for the initial copy, then trim to the adopted set below.

### Adopt (high-signal, align with strict TS + ponytail)
- `no-chained-type-assertions` - rejects `as X as Y`. Always a smell.
- `no-widen-then-assert` - rejects flows that widen known values then assert them back. Pure evidence destruction.
- `no-unsafe-dictionary-type` - rejects `Record<string, unknown>`, `{ [key: string]: object }`, and equivalents. Typed escape hatches.
- `require-safety-comment-for-type-assertion` - requires `// SAFETY:` before every non-const assertion. Cheap, high-signal.
- `no-known-value-widening` - rejects explicit broad target types that discard known keys. Use `satisfies` instead.

### Skip (dogmatic or low-value)
- `no-runtime-typeof` - rejects `typeof x === "string"`. Boundary parsing is not always worth the ceremony. If adopted, use `{ allowInTypeGuards: true }`.
- `no-module-mocking` - rejects `vi.mock`. Correct in principle, expensive in practice. Adopt only on greenfield.
- `no-object-parameters` / `no-unknown-parameters` - `unknown` at boundaries is legitimate.
- `no-shape-in-symbol-names` - stylistic, low value.

### Config sketch
```ts
import { defineConfig } from "oxlint";

export default defineConfig({
  ignorePatterns: [
    ".agent/**", ".agents/**", ".claude/**", ".codex/**", ".cursor/**",
    ".windsurf/**", "tools/oxlint/anti-slop/**",
  ],
  jsPlugins: [
    { name: "anti-slop", specifier: "./tools/oxlint/anti-slop/index.ts" },
  ],
  rules: {
    "anti-slop/no-chained-type-assertions": "error",
    "anti-slop/no-widen-then-assert": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error",
    "anti-slop/no-known-value-widening": "error",
  },
});
```

### When to adopt
Greenfield frontends only. Do not retrofit onto existing repos - rule churn would dwarf the benefit. The project is young (13 commits at time of writing); watch it before depending on its rule design.

For the full gate setup (CI lint, lefthook, oxfmt, govulncheck), see `references/toolchain.md`.

## Post-Build Workflow (after user approval)
1. `desloppify` — structure, maintainability, performance, architecture clarity.
2. `security-reviewer` — SAST, vulnerability scan, audit report.
3. `web-design-guidelines` — a11y, UX, anti-patterns. `jury` when a scored design review is wanted.
4. Append README scorecard: Performance, Security, Maintainability, Developer Experience.

## Skills & MCP Awareness
- Inspect `skills/` directory first; reuse skills over reimplementing.
- Compose, don't duplicate.
- Fully utilize MCP servers when available.
- Invoke `ponytail` (default `full`) on every response — shortest working diff, stdlib first, YAGNI.

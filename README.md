# tdvorak-fullstack

An opinionated operating-profile **skill for AI coding agents**: one `SKILL.md`
plus reference docs that turn any agent harness into a disciplined full-stack
engineer — a locked stack, a strict workflow order, hard rules, and a mandatory
pre-push gate.

Used daily across real production repos. Run it stock, fork it, or let your
agent reshape it to your stack and identity.

## Install

```sh
npx skills add Dvorinka/tdvorak-fullstack
```

or manually:

```sh
git clone https://github.com/Dvorinka/tdvorak-fullstack
cp -r tdvorak-fullstack ~/.agents/skills/   # or your harness's skills dir
```

Works with Devin, Claude Code, Codex, Cursor, Windsurf, OpenCode, Gemini,
Grok, Copilot — any harness that reads `SKILL.md` skills or plain rule files.

## Customize — three modes

| Mode | Command | Who answers |
|---|---|---|
| **Agent + user** (recommended) | point your agent at `SETUP.md` | agent inspects your env, asks you a few questions, generates |
| User only | `./setup.sh` | you, via interactive questionnaire |
| Agent only | `cp customize.example.yml customize.yml`, then `./setup.sh --config customize.yml --install --yes` | agent fills the answers itself |
| Stock | `./setup.sh --stock` | nobody — profile ships as-is |

The output is a complete skill directory under `./dist/<skill-name>/` (generated, gitignored); `--install` copies it into
every detected agent skills directory on the machine.

## What the profile enforces

- **Locked stack** — defaults below; `setup.sh` rewrites the table to your stack
- **Workflow order** — read the right reference doc *before* the kind of work it governs
- **Hard rules** — structured tools for structured files, no skipped-test-as-green, task-runner-first, visual verification of UI changes
- **Mandatory pre-push gate** — build, tests, lint/typecheck, smoke test; a failing app is a hard block, not a warning
- **Docs freshness gate** — docs, changelog, OpenAPI, env docs, CLI help updated in the same diff
- **PR discipline** — feature branch, authored commits, merge commits (no squash)
- **Persistent memory** — durable facts live in a git repo (`~/agent-memory`), not session context
- **Token discipline** — smallest correct diff; compression skills on demand

## Default stack (all linked — swap freely)

| Layer | Default |
|---|---|
| Frontend | [React 18](https://react.dev) + [Vite](https://vite.dev) + TS strict + [Tailwind](https://tailwindcss.com) + [shadcn/ui](https://ui.shadcn.com) |
| Backend | [Go](https://go.dev) + [Gin](https://gin-gonic.com), [zap](https://github.com/uber-go/zap) |
| DB | [PostgreSQL](https://postgresql.org) + [sqlc](https://sqlc.dev) + [goose](https://github.com/pressly/goose) |
| Cache | [DragonflyDB](https://dragonflydb.io) |
| API contract | [OpenAPI](https://openapis.org) → generated clients |
| Infra | [Docker Compose](https://docs.docker.com/compose/) |
| Desktop | [Wails](https://wails.io) / [Tauri](https://tauri.app) |
| Mobile | [React Native](https://reactnative.dev) + [Expo](https://expo.dev) |
| E2E | [Playwright](https://playwright.dev) · [Maestro](https://maestro.mobile.dev) · [tauri-driver](https://github.com/chippers/tauri-driver) |
| Load | [k6](https://k6.io) |
| Lint/format | [oxlint](https://oxc.rs) + [oxfmt](https://oxc.rs) + anti-slop plugin · [golangci-lint](https://golangci-lint.run) |
| Hooks | [lefthook](https://lefthook.dev) |
| Task runner | [just](https://just.systems) |
| Shell env | [direnv](https://direnv.net) |
| API collections | [Bruno](https://usebruno.com) |
| Worktrees | [worktrunk](https://github.com/max-sixty/worktrunk) |
| Agent orchestration | [t3code](https://t3.codes) |
| Local CI | [act](https://github.com/nektos/act) · [actionlint](https://github.com/rhysd/actionlint) · [shellcheck](https://shellcheck.net) |
| HTTP debug | [mitmproxy](https://mitmproxy.org) |
| Security | [trivy](https://trivy.dev) · [ZAP baseline](https://zaproxy.org) · [gitleaks](https://gitleaks.io) · [govulncheck](https://pkg.go.dev/golang.org/x/vuln/cmd/govulncheck) |
| Search/data | [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) · [jq](https://jqlang.github.io/jq/) · [yq](https://github.com/mikefarah/yq) · [TOON](https://github.com/toon-format/toon) · [sqlglot](https://github.com/tobymao/sqlglot) |
| DB tests | [testcontainers-go](https://golang.testcontainers.org) |
| Maps | [MapCN](https://www.mapcn.dev) |
| Design | [Boneyard](https://github.com/0xGF/boneyard) · shadcn/ui |
| Auth | [Better Auth](https://better-auth.com) |
| Billing | `stripe-kv-sync` skill + [t3dotgg/stripe-recommendations](https://github.com/t3dotgg/stripe-recommendations) guidance |
| Memory | [Agent Memory Repo spec](https://github.com/AgentMemoryRepo/agentmemoryrepo) |

### Companion agent CLIs (optional, by the same author)

| Tool | Use |
|---|---|
| [docsync](https://github.com/Dvorinka/docsync) | docs ↔ code drift check before PRs |
| [envdiff](https://github.com/Dvorinka/envdiff) | "works on my machine" environment diffs |
| [ciwatch](https://github.com/Dvorinka/ciwatch) | CI wait/failure triage + local preflight |
| [repolint](https://github.com/Dvorinka/repolint) | repo hygiene audit before publishing |

`go install github.com/Dvorinka/<name>/cmd/<name>@latest` — all emit `--json`.

## Layout

```
SKILL.md                 the operating profile (agent reads this)
references/              deep docs, loaded on demand by the workflow
  architecture.md        backend/DB/API contract rules, TS evidence rules
  ui-standards.md        design bar, component selection, review skills
  toolchain.md           lint/format/test/CI machinery
  maps.md                map component policy
  terminal-data.md       search/JSON/pipeline discipline
  agent-ops.md           parallel dispatch, worktrees, remote machines
setup.sh                 personalization generator
SETUP.md                 agent playbook (the recommended flow)
customize.example.yml    answer-file template
```

## Philosophy

Opinionated on purpose. Every rule in `SKILL.md` either prevents a failure that
actually happened, or enforces a discipline that pays for itself daily. Change
any of it — that's what `--config` is for — but change it deliberately.

## License

MIT — see [LICENSE](LICENSE).

#!/usr/bin/env bash
# setup.sh — personalize the tdvorak-fullstack skill.
#
# Modes:
#   ./setup.sh                          interactive questionnaire (user-driven)
#   ./setup.sh --config customize.yml   non-interactive, answers from file (agent-driven)
#   ./setup.sh --stock                  emit the skill unmodified
#
# Flags:
#   --out DIR        output directory (default: ./dist/<skill-name>)
#   --install        copy the result into detected agent skills directories
#   --yes            skip the final confirmation
#
# Requires: bash, sed, awk. No other dependencies.

set -euo pipefail
cd "$(dirname "$0")"

CONFIG=""
STOCK=0
DO_INSTALL=0
ASSUME_YES=0
OUT_DIR=""

while [ $# -gt 0 ]; do
  case "$1" in
    --config)    CONFIG="${2:?--config needs a file}"; shift 2 ;;
    --stock)     STOCK=1; shift ;;
    --install)   DO_INSTALL=1; shift ;;
    --yes|-y)    ASSUME_YES=1; shift ;;
    --out)       OUT_DIR="${2:?--out needs a dir}"; shift 2 ;;
    -h|--help)   sed -n '2,14p' "$0"; exit 0 ;;
    *)           echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

# ---------- answers ----------
SKILL_NAME="tdvorak-fullstack"
AUTHOR_NAME="Your Name"
AUTHOR_EMAIL="you@example.com"
GITHUB_HANDLE="your-github-username"
MEMORY_REMOTE=""          # e.g. github.com/you/agent-memory
STACK_FRONTEND="react"    # react | solidjs | nextjs | none
STACK_BACKEND="go"        # go | node | python | none
STACK_DB="postgres"       # postgres | mysql | sqlite | none
STACK_CACHE="dragonfly"   # dragonfly | redis | none
STACK_MOBILE="false"      # true | false
STACK_DESKTOP="none"      # wails | tauri | none
INSTALL_TO="auto"

load_config() {
  # minimal flat-YAML reader: `key: value` (no nesting), # comments, blank lines
  while IFS= read -r line; do
    line="${line%%#*}"
    [ -z "${line// /}" ] && continue
    key="${line%%:*}"; key="${key// /}"
    val="${line#*:}"; val="$(printf '%s' "$val" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/^"//; s/"$//')"
    case "$key" in
      skill_name|author_name|author_email|github_handle|memory_remote|stack_frontend|stack_backend|stack_db|stack_cache|stack_mobile|stack_desktop|install_to)
        eval "$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')=\"\$val\"" ;;
      *) echo "warning: ignoring unknown key '$key'" >&2 ;;
    esac
  done < "$1"
}

ask() { # ask <var> <prompt> <default>
  local var="$1" prompt="$2" default="$3" reply
  printf '%s [%s]: ' "$prompt" "$default" >&2
  read -r reply || reply=""
  eval "$var=\"${reply:-$default}\""
}

if [ "$STOCK" -eq 1 ]; then
  :
elif [ -n "$CONFIG" ]; then
  [ -f "$CONFIG" ] || { echo "config not found: $CONFIG" >&2; exit 1; }
  load_config "$CONFIG"
else
  echo "Personalize tdvorak-fullstack (enter keeps the default)." >&2
  ask SKILL_NAME      "Skill name"                       "$SKILL_NAME"
  ask AUTHOR_NAME     "Commit author name"               "$AUTHOR_NAME"
  ask AUTHOR_EMAIL    "Commit author email"              "$AUTHOR_EMAIL"
  ask GITHUB_HANDLE   "GitHub handle (PR comment footer)" "$GITHUB_HANDLE"
  ask MEMORY_REMOTE   "Private memory remote (empty=local only)" "${MEMORY_REMOTE:-none}"
  [ "$MEMORY_REMOTE" = "none" ] && MEMORY_REMOTE=""
  ask STACK_FRONTEND  "Frontend (react|solidjs|nextjs|none)"   "$STACK_FRONTEND"
  ask STACK_BACKEND   "Backend (go|node|python|none)"          "$STACK_BACKEND"
  ask STACK_DB        "Database (postgres|mysql|sqlite|none)"  "$STACK_DB"
  ask STACK_CACHE     "Cache (dragonfly|redis|none)"           "$STACK_CACHE"
  ask STACK_MOBILE    "Mobile e2e row (true|false)"            "$STACK_MOBILE"
  ask STACK_DESKTOP   "Desktop (wails|tauri|none)"             "$STACK_DESKTOP"
fi

# ---------- stack table ----------
TABLE_FILE="$(mktemp)"
{
  echo "<!-- STACK-TABLE-START -->"
  echo "| Layer | Default | Skill |"
  echo "|---|---|---|"
  case "$STACK_FRONTEND" in
    react)   echo "| Frontend | **React 18 + Vite + TS strict + Tailwind + shadcn/ui** | \`react-expert\` |" ;;
    solidjs) echo "| Frontend | **SolidJS + Vite** — Composition API patterns | \`solidjs-expert\` |" ;;
    nextjs)  echo "| Frontend | **Next.js App Router + TS strict + Tailwind + shadcn/ui** | \`nextjs-developer\` |" ;;
  esac
  case "$STACK_BACKEND" in
    go)     echo "| Backend | **Go + Gin**, \`zap\` logging, small packages, no magic | \`golang-pro\`, \`go-expert\` |" ;;
    node)   echo "| Backend | **Node + Fastify/Express**, strict TS | \`javascript-pro\`, \`typescript-pro\` |" ;;
    python) echo "| Backend | **Python + FastAPI**, type-annotated, async | \`fastapi-expert\`, \`python-pro\` |" ;;
  esac
  case "$STACK_DB" in
    postgres) echo "| DB | **PostgreSQL + sqlc + goose** (versioned migrations only) | \`postgres-pro\`, \`sql-pro\` |" ;;
    mysql)    echo "| DB | **MySQL** — versioned migrations only | \`sql-pro\` |" ;;
    sqlite)   echo "| DB | **SQLite** — versioned migrations only | \`sql-pro\` |" ;;
  esac
  case "$STACK_CACHE" in
    dragonfly) echo "| Cache | **DragonflyDB** (Redis-compatible, multi-threaded) — prefer over Redis | \`database-optimizer\` |" ;;
    redis)     echo "| Cache | **Redis** | \`database-optimizer\` |" ;;
  esac
  cat <<'ROWS'
| API contract | **OpenAPI** single source of truth → generate client + types (no manual duplication) | `api-designer` |
| Infra | **Docker Compose** (`docker compose up` must run the stack); Nginx/Traefik for TLS/routing | `devops-engineer` |
| DNS / edge | **Cloudflare** — `cf`/cloudflare CLI when configured; prefer CLI over console | — |
ROWS
  case "$STACK_DESKTOP" in
    wails) echo "| Desktop | **Wails** (Go+Web) | \`wails\` |" ;;
    tauri) echo "| Desktop | **Tauri** (Rust+Web) | \`tauri-v2\` |" ;;
  esac
  if [ "$STACK_MOBILE" = "true" ]; then
    cat <<'ROWS'
| Mobile | **React Native + Expo** | `react-native-expert` |
| Mobile e2e | **Maestro** — YAML flows + CLI + MCP | — |
ROWS
  fi
  cat <<'ROWS'
| Web e2e / UI verify | **Playwright** — MCP when configured, else CLI; screenshot UI changes before done | — |
| Browser (live session) | **browser-harness** — CDP control of a real logged-in Chrome | — |
| Task runner | **just** — `justfile` at repo root | `cli-developer` |
| Worktrees | **worktrunk (`wt`)** — `wt switch -c`, `wt merge`, `wt remove`; hooks automate install/env-copy | — |
| Agent orchestration | **t3code (`t3`)** — `t3 thread start <project> --worktree <ref> --branch <n> --wait --json` | — |
| CI (local) | **act** + **actionlint** + **shellcheck**; `cix` covers the remote side | — |
| Shell env | **direnv** — committed `.envrc` per repo | — |
| Security scan | **trivy fs** + **ZAP baseline** + **gitleaks** | `security-reviewer` |
| Agent telemetry | **agenttrace** — session cost/token/duration with `--baseline` gating | — |
ROWS
  echo "<!-- STACK-TABLE-END -->"
} > "$TABLE_FILE"

# ---------- generate ----------
[ -n "$OUT_DIR" ] || OUT_DIR="./dist/$SKILL_NAME"
mkdir -p "$OUT_DIR"
cp -r references "$OUT_DIR/"

awk -v tf="$TABLE_FILE" '
  /<!-- STACK-TABLE-START -->/ { print; while ((getline l < tf) > 0) { if (l !~ /STACK-TABLE-(START|END)/) print l } close(tf); skip=1; next }
  /<!-- STACK-TABLE-END -->/ { skip=0; print; next }
  skip==0 { print }
' SKILL.md > "$OUT_DIR/SKILL.md"
rm -f "$TABLE_FILE"

sed -i "s/^name: .*/name: $SKILL_NAME/" "$OUT_DIR/SKILL.md"
sed -i "s/Authored By: Your Name <you@example.com>/Authored By: $AUTHOR_NAME <$AUTHOR_EMAIL>/" "$OUT_DIR/SKILL.md"
sed -i "s/@your-github-username/@$GITHUB_HANDLE/g" "$OUT_DIR/SKILL.md"

if [ -n "$MEMORY_REMOTE" ]; then
  sed -i "s|add a private remote you own (e.g. \`github.com/<you>/agent-memory\`, main)|synced to the private remote \`$MEMORY_REMOTE\` (main)|" "$OUT_DIR/SKILL.md"
fi

# React-priority line depends on the chosen frontend
case "$STACK_FRONTEND" in
  react|nextjs) : ;;  # keep stock line
  solidjs) sed -i 's/React is the priority\. SolidJS is a secondary option, used only when the user explicitly says so\. Never mix the two in one project\./SolidJS is the configured frontend. Never mix React and SolidJS in one project./' "$OUT_DIR/SKILL.md" ;;
  none)    sed -i '/React is the priority\. SolidJS is a secondary option/d' "$OUT_DIR/SKILL.md" ;;
esac

# ---------- install ----------
install_skill() {
  local parent="$1"
  mkdir -p "$parent"
  rm -rf "${parent:?}/${SKILL_NAME:?}"
  cp -r "$OUT_DIR" "$parent/$SKILL_NAME"
  echo "installed -> $parent/$SKILL_NAME"
}

if [ "$DO_INSTALL" -eq 1 ]; then
  if [ "$ASSUME_YES" -eq 0 ] && [ -t 0 ]; then
    printf 'Install %s into agent skills directories? [y/N] ' "$SKILL_NAME" >&2
    read -r reply
    case "$reply" in y|Y|yes) ;; *) DO_INSTALL=0 ;; esac
  fi
fi

if [ "$DO_INSTALL" -eq 1 ]; then
  if [ "$INSTALL_TO" = "auto" ]; then
    for d in "$HOME/.agents/skills" "$HOME/.config/devin/skills" "$HOME/.claude/skills" "$HOME/.cursor/skills" "$HOME/.codeium/windsurf/skills" "$HOME/.copilot/skills" "$HOME/.gemini/skills"; do
      [ -d "$(dirname "$d")" ] && install_skill "$d"
    done
  else
    IFS=',' read -ra DIRS <<< "$INSTALL_TO"
    for d in "${DIRS[@]}"; do install_skill "$d"; done
  fi
fi

echo
echo "Done: $OUT_DIR"
echo "  skill name : $SKILL_NAME"
echo "  author     : $AUTHOR_NAME <$AUTHOR_EMAIL>"
echo "  stack      : frontend=$STACK_FRONTEND backend=$STACK_BACKEND db=$STACK_DB cache=$STACK_CACHE mobile=$STACK_MOBILE desktop=$STACK_DESKTOP"
[ "$DO_INSTALL" -eq 1 ] || echo "  (rerun with --install to copy into agent skills directories)"

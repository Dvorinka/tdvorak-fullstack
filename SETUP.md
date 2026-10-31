# SETUP.md — agent playbook for personalizing this skill

You are an AI coding agent setting up `tdvorak-fullstack` for a user. Follow this
playbook exactly; it is the recommended flow (agent + user). If the user asks for
stock install, skip to step 4 with `--stock`.

## 1. Inspect the environment

Detect what already exists before asking questions — recommend defaults that
match reality:

- Languages/runtimes: `command -v go node python3 rustc`
- Package/tool managers: `command -v npm pnpm bun brew cargo uv pipx`
- The tools this profile expects: `command -v rg fd jq yq just direnv wt t3 act`
- Agent skills dirs present: `~/.agents/skills`, `~/.claude/skills`,
  `~/.config/devin/skills`, `~/.cursor/skills`, `~/.codeium/windsurf/skills`,
  `~/.copilot/skills`, `~/.gemini/skills`
- A git memory repo: `git -C ~/agent-memory rev-parse` — if absent, plan to
  create it during install.

## 2. Ask the user

Use your harness's question mechanism. Recommended prompts (propose defaults
from step 1 — the user confirms or overrides):

1. **Stack**: frontend (react / solidjs / nextjs / none), backend
   (go / node / python / none), database (postgres / mysql / sqlite / none),
   cache (dragonfly / redis / none).
2. **Optional layers**: mobile (React Native + Expo + Maestro — true/false),
   desktop (wails / tauri / none).
3. **Identity**: commit author name + email (for the mandatory
   `Authored By:` trailer), GitHub handle (for the PR comment footer).
4. **Memory**: does a private `agent-memory` repo exist? Remote URL if yes.
   If no remote, memory stays local.
5. **Skill name**: keep `tdvorak-fullstack` or rename.

Offer your own recommendation per question — e.g., "Go is installed and three
of your repos use it; recommend `backend: go`."

## 3. Write `customize.yml`

Copy `customize.example.yml` → `customize.yml`, fill the keys with the answers.
Flat `key: value` pairs; see the example file for valid values per key.

## 4. Generate

```sh
./setup.sh --config customize.yml
```

Stock instead: `./setup.sh --stock`.

Output lands in `./dist/<skill-name>/` — a complete skill dir
(`SKILL.md` + `references/`).

## 5. Install

```sh
./setup.sh --config customize.yml --install --yes
```

`--install` copies the generated skill into every detected agent skills
directory (see step 1). To target specific directories, set
`install_to: ~/.agents/skills,~/.claude/skills` in the config.

## 6. Enforce at session start (recommended)

So the skill is actually invoked every session, append this block to the
agent's global rules file (`~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
`~/.cursor/rules/*.mdc`, `~/.config/opencode/AGENTS.md`, `~/.gemini/GEMINI.md`,
`~/.copilot/copilot-instructions.md` — whichever exists):

```md
## Mandatory Session Skills
At the start of every session, read and follow:
1. `<skills-dir>/<skill-name>/SKILL.md` — operating profile
2. Memory: `~/agent-memory` — pull, read MEMORY.md, write durable facts, commit
```

## 7. Verify

- `head dist/<skill-name>/SKILL.md` — frontmatter name matches.
- The stack table reflects the chosen stack (`grep -A30 'STACK-TABLE'`).
- If memory was configured: `git -C ~/agent-memory pull --ff-only` works.

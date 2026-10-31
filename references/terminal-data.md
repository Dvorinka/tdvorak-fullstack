# Terminal Data Stack (Agent Guide)

Tools: `rg` (search), `fd` (find), `jq` (JSON), `yq` (YAML), `yamllint` (YAML lint), `fzf` (select), `stow` (dotfiles), TOON (LLM-optimized JSON). Python extras live in `~/.local/venvs/py-tools` (sqlglot, PyYAML).

## Token Efficiency (mandatory)
On every request, invoke `ponytail` (default `full`) — shortest working diff, YAGNI. When user asks for less tokens / brief / caveman: also invoke `caveman`, `caveman-commit`, `caveman-review`.

## Core Principle
Always use pipelines: `input → filter → transform → select → output`. Never manually browse files if a pipeline can do it.

## Tools

| Tool | Use | Example |
|---|---|---|
| `rg` | search content | `rg "userId"`, `rg "error" -g "*.go"` |
| `fd` | find files/dirs | `fd main.go`, `fd -e json`, `fd -t d` |
| `jq` | parse/filter JSON | `jq '.users[] \| .email'`, `jq 'length'` |
| `yq` | parse/edit YAML | `yq '.databases[].name' f.yaml`, `yq -i '.a.b = 1' f.yaml` |
| `yamllint` | lint YAML | `yamllint -d relaxed f.yaml` |
| `fzf` | interactive select | `fd \| fzf`, `rg "TODO" \| fzf` |
| `stow` | link dotfiles | `stow zsh` |
| TOON | compress JSON for LLMs | `cat data.json \| npx @toon-format/cli` |

## TOON
- Reduce JSON size; prepare structured data for LLMs.
- CLI (no install): `npx @toon-format/cli input.json -o output.toon`
- stdin: `cat data.json | npx @toon-format/cli`
- decode: `npx @toon-format/cli --decode input.toon`

## Pipelines (primary usage)
```
rg "user" | fzf                              # search → select
fd | fzf | xargs code                        # find → open
cat data.json | jq '.users'                  # JSON → filter
cat data.json | jq '.users' | npx @toon-format/cli   # JSON → TOON
cat data.toon | npx @toon-format/cli --decode | jq   # TOON → JSON
```

## Install
```
apt install ripgrep fd-find jq fzf stow -y
ln -s $(which fdfind) ~/.local/bin/fd   # fd fix on Debian/Ubuntu
brew install yq                          # mikefarah yq — YAML query/edit
pipx install yamllint                    # YAML lint CLI
python3 -m venv ~/.local/venvs/py-tools  # shared scripting venv
~/.local/venvs/py-tools/bin/pip install sqlglot pyyaml
npm install -g @toon-format/cli          # or use npx
```

System python is PEP 668 externally-managed: `pip install` fails. Use `pipx` for CLI tools, the `py-tools` venv for libraries.

## Structured-file discipline (mandatory)

Structured files get structured tools. Never edit or splice multi-line YAML/JSON blocks with regex or line offsets — indentation, anchors, and duplicate keys make it silently wrong. Past failure mode: regex-spliced `tables:` block produced an indent offset and a duplicated key, caught only by luck.

1. **Edit:** `yq -i` for YAML, `jq`/`yq -o=json` for JSON, or a short script through `yaml.safe_load`/`yaml.safe_dump` (PyYAML is in `py-tools` venv and system python).
2. **Verify after every programmatic edit:** re-parse the result (`yq e '.' f.yaml` / `python -c "import yaml,sys; yaml.safe_load(open(sys.argv[1]))" f.yaml`) before commit. Lint too (`yamllint`) when the file ships.
3. **Preserve semantics, not just syntax:** comments and human-written fields (`purpose:`) survive `yq`/`yaml.safe_load` — yq round-trips comments; PyYAML does not. Prefer `yq` for files humans annotate.
4. **An error is not absence.** `command -v` the tool and read stderr before concluding a module/tool is missing — a parse failure on an invalid file is not "no pyyaml". Never suppress stderr with `2>/dev/null` on the diagnostic run you are about to judge.

## SQL inspection — never regex-parse

Regex over migrations produces plausible garbage: multi-line `CHECK` constraints leak fake columns (`OR`, literals), duplicate names multiply via constraint joins. Both shipped once.

Preferred order:

1. **Ephemeral engine** — `docker run -d postgres:17`, apply migrations, query `information_schema.columns` + `pg_class.reltuples`. Real schema, zero parsing. Cheapest source of truth when the real DB is unreachable.
2. **sqlglot** — `~/.local/venvs/py-tools/bin/python`; real parse tree (`sqlglot.parse(sql, dialect="postgres")`), not regex.
3. **Regex** — only for a rough inventory, never for column-level truth. Mark output as approximate.

Join dedup: constraint metadata fans out per-column; dedupe on `(table, column)` and prefer `PK > UNIQUE > FK` labels.

## Rules
- Prefer `rg` over grep. Prefer `fd` over find.
- Always `jq` for JSON (never raw). Always `yq` for YAML (never regex/line-splice).
- `fzf` for selection instead of manual scanning.
- Convert large/repetitive JSON → TOON before LLM usage.
- Always compose tools in pipelines.

## Anti-Patterns
`grep`/`find` usage, opening files manually for search, sending raw JSON to LLMs, loading large JSON without filtering.

## Goal
Fast navigation + structured data handling + minimal token usage.

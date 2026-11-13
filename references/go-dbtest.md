# Go DB tests

The DB-backed test pattern for Go projects. Read before writing or running
tests that need a real database.

## Recipe

- Run a throwaway Postgres in docker on a non-default port; credentials in
  the compose file, never production.
- Gate tests behind a build tag (e.g. `-tags=dbtest`) and a DSN env var
  (`DATABASE_URL_TEST=postgres://…`). The tag keeps `go test ./…` fast and
  safe without a database.
- Create **per-feature-lane databases** — a shared test DB accumulates
  cross-lane pollution: leaked triggers, fixed-email fixtures, orphaned
  rows that fail unrelated tests.
- Keep heavyweight real-data tests (full production-shape imports) behind
  their own name and skip them in quick runs (`-skip 'TestLiveDB…'`) —
  minutes-long fixtures belong to CI or dedicated runs.
- Gated env vars belong in a committed `.envrc` (direnv) or a task-runner
  recipe — never "the agent happened to export it".
- Open the pool once per suite (a `livePool()` helper), not per test.
- A small `/tmp` tmpfs breaks cgo test builds — `TMPDIR`/`GOTMPDIR` to a
  disk-backed dir first.

## Driver gotchas worth remembering

- `[]byte` params encode as `bytea` — inserting into `jsonb` fails. Send
  `string` and let the driver marshal text.
- A `$N` placeholder pinned to a type by an INSERT column list breaks
  `nullif($N,'')` used in a later clause — split into separate params.
- Correlated subqueries need the outer table alias — a wrong alias
  silently aggregates the whole table instead of one row's children.
- Long tests inside a serialization lock (advisory lock, sequence row)
  starve every other writer — keep lock scope short or skip the lock in
  fixture-heavy tests.

## Migration discipline

- Parallel branches collide on sequential migration numbers — check open
  branches before claiming a number; renumber at merge if two lanes took
  the same one.
- A prod DB can contain a manually applied `if not exists` patch without
  the version row — verify the object exists instead of re-applying.
- FK hardening order: `ADD CONSTRAINT … NOT VALID` → clean orphans →
  `VALIDATE CONSTRAINT`.
- New indexes ship with `EXPLAIN (ANALYZE)` evidence on production-shaped
  data — a seq scan on a tiny table is the correct plan, not a regression.

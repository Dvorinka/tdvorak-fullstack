# Upstream port sweep

The fork-maintenance loop for keeping a downstream fork current with
upstream. Read before syncing issues/PRs across repos.

## Rules

- **Never touch upstream.** All work lands in the fork; upstream is
  read-only reference.
- Keep a ledger (`PORTS.md` / `HANDOFF.md`) with per-item state:
  ported `<sha>` / covered-by `#X` / skipped (reason) / open.
- License-incompatible PRs are a deliberate skip — record the reason, do
  not port.

## Loop

1. Fetch upstream open issues + PRs above the last recorded maximum.
   Issues with no ledger row are "new" even if old — sweep them anyway.
2. For each PR: fetch the diff → `git apply` (or `--reject` + manual
   merge). Port with a commit referencing the upstream number. Batch
   trivially related PRs into one commit when they touch the same area.
3. Dedup against history first — many "new" items are already fixed by an
   earlier port; verify in the current code, then ledger `covered-by`.
4. Mirror issues get verify → port → close-with-verdict. Keep standing
   tracker issues open forever.
5. **Suite must be green before push.** Repair pre-existing baseline
   failures first and record them; known environmental failures are
   sanctioned, everything else is a regression you own.
6. Push and record the head sha in the ledger.

## Gotchas

- Cross-repo PRs merge fine — check whether a later PR is stacked on an
  earlier one before ordering merges.
- CI on main may be red for unrelated reasons (a platform job broken by an
  earlier merge) — identify whether your sweep introduced it before
  claiming green.
- A port that lands in test-only code still needs the full suite —
  detector/fixture regressions hide in ported tests.

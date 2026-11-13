# Ship & Verify

Deploy-and-verify discipline. Read before any deploy, release verification,
or "it's live" claim. The recurring failure mode: **trusting a stamp
instead of the artifact**.

## Ground rules

- A version stamp is not ground truth. Env-var version labels, image tags,
  and deploy dashboards all lie when a build reused an old snapshot.
  Verify by checking **served artifacts** — grep served JS chunks for a
  feature string, run the binary's `--version`, read `activeDeployments`
  from the platform API — never the label.
- Deploy from a **clean worktree at the target sha**. Deploy CLIs snapshot
  the working tree; a dirty checkout ships someone else's uncommitted
  work.
- A successful "queued"/"building" response proves nothing. Follow the
  deployment to `SUCCESS`, then verify the artifact.
- After agent-driven sessions, sweep for leaked processes
  (`ss -tlnp` / `lsof -i`) — spawned workers and verify stacks leak dev
  servers and API processes. Kill strays before reporting done.

## Platform pitfalls (seen in production)

- Upload-context bugs: running a deploy CLI from the repo root uploads the
  wrong context — run it from the service directory or the repo's deploy
  script.
- "Bare" subcommands mutate: `… domain` may **create** a domain where you
  expected a list; prefer the explicit `… list` form.
- Env vars set via the platform CLI sit **staged** — they bake into the
  build only on the next deploy. Always redeploy after changing them.
- Services may not auto-deploy on merge to main — know which of yours do,
  and deploy the web SPA explicitly; an API-only deploy leaves the SPA
  stale.
- A smoke probe that accepts *any* version label can pass on the previous
  build — verify the label yourself.
- Stuck initializing deploys can hold the build slot; cancel them through
  the platform's API when the UI won't.
- Deploy builds that queue and build server-side make the local follow
  command time out — poll the deployment list instead.

## Local verify stacks

- Dev servers started for verification die with the parent shell — run
  them detached (`setsid nohup …`).
- Off-loopback browser automation cannot reach `localhost` — bind the dev
  server to `0.0.0.0` and use the LAN IP.
- Auth-walled APIs behind a clean-profile browser: run a localhost shim
  that injects `Authorization: Bearer <token>` rather than fighting CORS,
  cookies, or TLS to the real backend.
- `BrowserRouter` is not hash routing — deep-link `/route/:id`, not `#/`.

## Build environment

- A small `/tmp` tmpfs breaks cgo and linkers (`disk quota exceeded`) —
  point `TMPDIR`/`GOTMPDIR` at a disk-backed dir before Go builds or push
  hooks that compile.
- Push hooks needing repo `node_modules` fail in fresh git worktrees —
  push from the main checkout or install in the worktree first.

## UI verification gate

- UI-visible changes are not done without a screenshot at phone (~390px)
  and desktop (~1440px) widths. Zero horizontal overflow is the pass bar
  for layout sweeps.

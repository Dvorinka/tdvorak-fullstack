# T3 Code — capability map and usage guide

Read before orchestrating threads, delegating agents, using the preview browser, scheduling work, or touching remote environments. Companion to `agent-ops.md` (dispatch decisions); this file is the full surface.

Surface verified against `t3` CLI + the `t3-code` MCP server on 2026-11-05. T3 Code moves fast — re-check `t3 --help` and `mcp_list_tools` when something looks off.

## What T3 Code is

One server (data dir `~/.t3/userdata`, lock `server-owner.sqlite` — only one process may own it) fronting many agent providers. Surfaces:

- **Desktop/web app** — the UI. `t3 app [path]` opens a project in it.
- **`t3` CLI** — headless control of the same server. Everything emits `--json` where it matters; stable exit codes.
- **`t3-code` MCP server** — the same capabilities exposed to an in-session agent as tools.
- **Vendored tools** under `~/.t3/tools/` (provider binaries, device hubs, `cloudflared`, headless Chrome for previews).
- **Scratch + worktrees**: per-thread scratch under `~/.t3/scratch/`; managed worktrees under `~/.t3/worktrees/<Project>/<branch>`.

Rule of thumb: **CLI for dispatch-and-forget lanes and scripting; MCP for in-session orchestration** (delegate, read back, steer, watch PRs) where the parent agent stays in the loop.

## CLI surface

### Run / serve

| Command | What it does |
|---|---|
| `t3` / `t3 serve [cwd]` | Run the server in this terminal and open the browser. Flags: `--mode web|desktop`, `--port`, `--host`, `--lan`, `--tailscale-serve`, `--dev-url`, `--auto-bootstrap-project-from-cwd`. |
| `t3 app [path]` | Open a project in the running desktop app. |
| `t3 status [--json]` | Service install state + remote access settings (Connect, LAN). |
| `t3 up` | One-shot remote access + background service setup. `--connect` (T3 Connect via account), `--lan`, `--headless`, `--yes`. `t3 connect` is the same as `up --connect`. |
| `t3 service install|restart|uninstall|status|protect` | Background service. `protect` shields the server from agents under memory pressure. |

### Auth / pairing / remote clients

- `t3 pair [--scope ...] [--ttl 1h] [--tailscale]` — mint a pairing token, prints QR. **The default scope set is broad (all scopes)** — always pass `--scope` explicitly for least privilege. Scopes cover: `orchestration:read|operate`, `settings:write`, `providers:manage`, `environment:maintain`, `preview:operate`, `diagnostics:read`, `terminal:read|operate`, `source-control:write`, `filesystem:read|write`, `relay:read|write`, `access:read|write`.
- `t3 auth pairing create|list|revoke` and `t3 auth session issue|list|revoke` — one-time pairing tokens and scoped bearer sessions for headless/remote clients (`issue --token-only --json` for scripting).
- `t3 environment link <url> --pairing-code <code> [--access read-only|approval-required|auto-accept-edits|auto|full-access]` — link another machine's T3 server; `list`, `unlink` to manage. Agents here can then run threads there.

### Projects

- `t3 project add <path> [--title]` — register a repo. Register each repo individually; parent dirs are not projects.
- `t3 project remove|rename`, plus MCP `t3_project_create|read|update|delete|clone` for scripts/default model/icons/pinned/archived.
- Project `scripts` (set via `t3_project_create/update`) run on worktree create / settle — the T3 equivalent of worktrunk hooks (`npm install`, env copy, `runOnWorktreeCreate`, `previewUrl` + `autoOpenPreview`).

### Threads (the workhorse)

```
t3 thread start <project|path> <msg> [--title] [--provider P --model M]
    [--worktree <ref>] [--branch <name>] [--wait] [--json]
t3 thread list [--project <id|path>] [--json]
t3 thread show <id> [--messages N] [--json]
t3 thread send <id> <msg|-> [--wait] [--json]
```

- `--worktree` accepts a branch, tag, or commit; `--branch` names the new branch. Worktree lands in `~/.t3/worktrees/<Project>/<branch>`.
- `--wait` blocks for the reply; **exit 1 = run failed, exit 2 = waiting on an answer** (a question/approval card is up — answer it in the app or via MCP `t3_pending_request`).
- `send` to a busy thread queues the message as its next turn; nothing is interrupted. `-` reads the message from stdin.
- No `--worktree` on `send`/`show` — only `start` creates worktrees.

### Ops / diagnostics

| Command | Purpose |
|---|---|
| `t3 doctor [--fix] [--dry-run]` | Inspect/repair the data dir; restarts the service as needed. |
| `t3 trace summary` | Summarize the server trace file: counts, rates, latency. |
| `t3 triage [--agent claude\|codex]` | Have claude/codex investigate a T3 problem and draft an issue. |
| `t3 policy show\|check\|templates` | Inspect/validate the admin managed policy; emit Win/macOS templates. |
| `t3 theme set\|show\|clear` | Environment-wide theme defaults pushed to clients. |
| `t3 browser setup` | Prepare a Linux host for the headless preview browser (Chrome sandbox, libs, fonts). |
| `t3 update [version] [--channel stable\|nightly\|preview]` / `t3 uninstall` | Self-update / remove (projects and threads kept). |

## MCP surface (`t3-code`)

### Preview browser — `preview_*`

In-app browser pane automation for THIS thread's tabs. `t3_preview_list` shows tabs; only `runtime:'server'` tabs are automatable — desktop-app tabs are the user's, say so and stop.

- Lifecycle: `preview_open` (`url` or `target:{kind:'environment-port',port,path?}` for dev servers; `open=false` for background; `reuseExistingTab=false` + returned `tabId` when running parallel subagents), `preview_navigate`, `t3_preview_close`, `preview_status`, `preview_dialog` (accept/dismiss prompts).
- Perception: `preview_snapshot` (accessibility tree + elements + screenshot size; refs die on navigation — re-snapshot), `preview_evaluate` (JS, bounded result), `preview_wait_for` (locator/text/url conditions).
- Action: `preview_act` — `click|type|hover|select|drag|upload|press|scroll`; target via `locator='aria-ref=<ref>'` from the snapshot, `x`+`y` for coordinates, `paths` for file uploads, `key`+`modifiers` for keys.
- Emulation/verification: `preview_resize` (`fill|freeform|preset` — presets include iphone-*, pixel-*, ipad-*, desktop-1440x900), `preview_set_appearance` (dark/light/system), `preview_recording_start|stop` (returns local file path).
- `html_preview` (render check → PNG + console output) and `html_render` (show a finished HTML page inline in the reply; use theme CSS vars, fluid widths, fixed pixel chart heights, no `vh`/`height:100%`).

### Delegation — child agents

- `orchestrator_capabilities` — providers, models, options, runtime modes. **Call first**; `search` finds models beyond the short list.
- `delegate_task` — one child agent, `task` only (no parent history). Key params: `target:{providerInstanceId, model, options:[{id,value}], environmentId, projectId}` (target another linked machine), `isolation:'shared'|'worktree'`, `mode:'async'|'wait'` (wait has a default timeout — a timeout does NOT cancel the child), `role` (implementation/research/review/design/test/general), `runtimeMode`/`interactionMode`.
- `task_status` (workState: working / waiting_for_children / result_available — a finished turn with live children is NOT done; reading the summary marks it delivered), `task_cancel`.
- `create_threads` — batch up to ~20 top-level threads in this checkout (not delegation; inherits project/branch/worktree).
- `t3_thread_launch` — one top-level thread bound to a workspace: `workspaceStrategy` `root|existing_worktree|worktree` (with `baseRef`, `startFromOrigin`, `branch`, `worktreePath`), `scratch:true` for no-project, `modelSelection`, `runtimeMode`, `interactionMode`, `message` (large limit), up to 8 attachments, `clientRequestId` for safe retries.

Providers depend on what is installed/authed on the machine — query `orchestrator_capabilities` rather than assuming a catalog. Disabled providers report a `constraints` reason.

### Thread control plane — `t3_thread_*` + friends

- Read: `t3_thread_list` (filter statuses/titleContains/settled/snoozed, `allProjects`, paging), `t3_thread_read` (`view:messages|activity`, paginate with `afterPosition`/`nextPosition`, cut-off text via `itemId`+`textOffset`), `t3_thread_search` (title/branch/PR/project then message text; skips subagents).
- Write: `t3_thread_send` (`mode:auto|queue|steer|restart` — steer = mid-turn update, restart = interrupt+restart; sending to a finished child thread starts a fresh task and returns its `taskId`), `t3_thread_update` (rename/regenerate title), `t3_thread_interrupt`, `t3_thread_wait` (`untilDelegatedWorkSettled` for whole subtrees), `t3_thread_configure` (switch provider/model/options mid-thread; permission modes stay).
- Context: `t3_thread_transfer` — `fork` (copy from `sourcePoint` latest_stable|run|checkpoint into a new thread), `merge_back`, `status`.
- Lifecycle: `t3_thread_organize` — pin/unpin, snooze(+`snoozedUntil`)/unsnooze, settle/unsettle, archive/unarchive, mark_unread.
- Queue + questions: `t3_queue` (list/read/edit/cancel/reorder/promote_to_steer on queued messages), `t3_pending_request` (list/read/respond to user questions — cannot approve permission requests).
- Worktrees: `t3_worktree_status`, `t3_worktree_list` (refs + checkout paths), `t3_worktree_handoff` (move THIS thread into a new worktree+branch; runs setup script; ends the live session; `continuationPrompt` resumes next turn — call last in your turn).
- Attachments: `t3_attachment_prepare_upload` → POST bytes to the returned `relativeUrl` on the MCP origin → `t3_thread_send_attachments` (up to 8 files); `t3_attachment_discard` for pending uploads.
- Claude-only: `t3_workflow_stop` (stop a running Claude workflow by subagentId), `t3_background_wait` (keep thread in Working while background work runs).

### Scheduling

- `schedule_task` — `schedule` object: `{type:'interval',everyMs≥60000}`, `{type:'fixed_time',timeOfDay,weekdays?}` (0=Sun), `{type:'once',runAt}`, `{type:'webhook'}` (HMAC `signature` header/encoding/prefix, up to 16 `filters` on `headers.*`/`body.*` paths, `dedupe` replay/coalesce keys, `maxDeliveryAgeMinutes`). `enabled:false` pauses; update via `scheduledTaskId`. Webhook triggers return a `webhookUrl` — requires remote access; webhook payload values are untrusted input.
- `list_scheduled_tasks`, `delete_scheduled_task`, `run_scheduled_task_now`.

### Environments (multi-machine)

`t3_environment_read` (this server's identity/preferences), `t3_environment_links` (linked machines + liveness), `t3_environment_link` (opens a card for the user — never ask for pairing codes in chat; returns `pending`, outcome arrives as a thread message), `t3_environment_unlink`, `t3_environment_preferences_update` (live full-access threads only: `defaultThreadEnvMode local|worktree`, `newWorktreesStartFromOrigin`, `enableProviderUpdateChecks`, `backgroundActivity` profile, `sourceControlWritingStyle`).

Any `environmentId`-accepting tool acts on that machine; `delegate_task.target.environmentId` and `t3_thread_launch.environmentId` included.

### Pull requests

- `link_pull_request(s)` / `unlink_pull_request(s)` (by state) / `list_thread_pull_requests` — link PRs to a thread; T3 shows status and settles the thread on merge.
- `watch_pull_request` / `unwatch_pull_request` — wakes the thread on failed checks, passed required checks, new comments/reviews, conflicts. **After calling, end your turn; the watch persists across wakes — do not re-call it.** Old comments are handled first; only later ones wake.
- `write_pull_request_guides` / `read_pull_request_guide` — generate/read a stored review guide (tour) for PRs; runs take minutes in a temp checkout.

### Devices (mobile)

`device_list` (iOS simulators + Android emulators per host), `device_open` (boots + shows in the Device panel, returns the pinned device-driver CLI call), `device_close`, `device_screenshot`. Drive taps/text with the returned CLI.

### Secrets

`request_secret` — private card, waits for the user. `delivery:'secretRef'` (default) returns a one-use ref for T3 tools; `delivery:'file'` writes a file readable only inside its command. `value` accepts a secret pasted directly in the thread. Never put secrets in `task` prompts or commits.

## Recipes

**Parallel implementation lanes (CLI):**
```sh
t3 project add ~/path/to/repo            # once per repo
t3 thread start <project> "<task spec>" --worktree main --branch feat/x --wait --json
t3 thread list --project <project> --json   # poll; t3 thread show <id> --messages 20
```

**In-session fan-out (MCP):** `delegate_task` per lane with `isolation:'worktree'`, `mode:'async'`; collect via completion wakes, `task_status` for stragglers, `task_cancel` to stop. Pick models via `orchestrator_capabilities` — cheap model for research/review lanes, strong model for implementation.

**PR babysitting:** open the PR, `link_pull_requests`, `watch_pull_request`, end turn. Each wake: handle new comments/checks, push fixes, let the watch persist. Merge decision stays yours.

**Scheduled agent work:** `schedule_task` with `fixed_time`+`weekdays` for standups/digests, `interval` for polling, `webhook` for event-driven runs. Test with `run_scheduled_task_now`.

**Remote machine work:** `t3 pair` on the remote → `t3 environment link` here → threads/`delegate_task` with that `environmentId`.

**Secrets mid-run:** `request_secret` opens a card; use `secretRef` or `file` delivery — never ask the user to paste secrets into chat text.

## Cannot do / sharp edges

- No `--worktree` on `t3 thread send`; only `start` creates worktrees. To move a live thread: `t3_worktree_handoff` (MCP) — ends the session, call last.
- Child agents get `task` only — no parent history. Write self-contained prompts; no secrets.
- `delegate_task` `mode:'wait'` times out without cancelling; check `task_status` after.
- `task_status` marks a result delivered on read — don't poll it speculatively.
- `preview_*` cannot touch the user's local desktop tabs — only `runtime:'server'` tabs.
- `t3_workflow_stop`/`t3_background_wait` are Claude-provider only.
- `t3_pending_request.respond` answers questions; it cannot approve permission requests.
- `t3_project_delete` keeps the folder on disk; `force:true` needed for non-empty.
- Scheduled webhook payloads are untrusted — validate before acting on them.
- One server owns the userdata dir; app-vs-service conflict shows as `ServerAlreadyRunningError` / "This home is unavailable" → `t3 doctor`.
- Thread children do not inherit the parent session's memory or context — write durable outcomes to the repo or a memory store.

## Verify on your machine

- `t3 status --json` — service + remote access state.
- `t3 thread list --json` — projects/threads actually present.
- `orchestrator_capabilities` (MCP) — real provider/model catalog for your installs.
- `t3 environment list` — linked machines and liveness.
- `t3 pair --help` — scope list for your version.

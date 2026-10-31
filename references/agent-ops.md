# Agent Operations — dispatch, worktrees, remote machines

Read before spawning parallel work, dispatching agents, or working on another machine.

## Control surface: T3 Code

- `t3` CLI at `~/.local/bin/t3`, data dir `~/.t3/` (per-thread scratch in `scratch/`, managed worktrees in `worktrees/`).
- T3 Connect is enabled on the workstation; the background service is optional (`t3 up`, `t3 service install`).

## Dispatch decision table

| Need | Route |
|---|---|
| Quick read-only search inside this session | in-session grep/read; `subagent_explore` only if genuinely broad |
| Parallel implementation lanes in one repo | `t3 thread start <project> <msg> --worktree <ref> --branch <n>` per lane — each gets an isolated worktree and branch |
| Long task to supervise while doing other work | `t3 thread start` without `--wait`; poll `t3 thread show <id> --json`, steer via `t3 thread send` |
| Manual side-branch for yourself | `wt switch -c <branch>` — worktrunk hooks run install/env-copy on create |
| Work that must run on another machine | `t3 environment link <url> --pairing-code <code>` (mint the code with `t3 pair` there), then start threads against that environment |

Paid subagent models are never the default route. In-session subagents only when the work is big enough to justify it — default is doing it inline.

## t3 thread lifecycle

1. `t3 project add <path>` if the repo isn't registered (register each repo you dispatch into).
2. `t3 thread start <project> <msg> --worktree main --branch <lane> --wait --json` — `--wait` blocks for the reply; exit 1 = run failed, exit 2 = waiting on an answer.
3. Follow-ups: `t3 thread send <id> <msg> --wait`; inspect: `t3 thread show <id> --messages 20`; list: `t3 thread list --project <id|path> --json`.
4. Each thread's worktree lands under `~/.t3/worktrees/` on its own branch — review and merge through the normal PR flow. Never push to `main`.

## Scoped client tokens

`t3 pair --scope orchestration:operate --scope terminal:read --ttl 1h` mints pairing tokens for remote clients. Full scope list via `t3 pair --help` — grant narrowly.

## Memory boundary

`t3` threads do NOT inherit session memory or context. Put durable outcomes back into the repo (PR, docs) or `~/agent-memory` per the memory loop — never leave the result living only inside a thread.

## Telemetry

`agenttrace` reports session cost/token/duration with `--baseline` delta gating — use when auditing what an orchestration round actually cost.

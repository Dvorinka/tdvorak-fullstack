# Handoff

Session-close convention. Read before reporting "done" on any multi-session
project.

## What gets written

- **Handoff doc** — `HANDOFF.md` at repo root (work queues) or
  `docs/<area>/handoff-<date>.md` (feature closeouts). Contents:
  - shipped: commits, PR numbers, deployed SHAs, schema/migration version
  - pending: ordered queue, each item with the smallest pointer that
    resumes it (issue id, file, failing test)
  - gotchas learned this session that cost time
  - env state: which deploys are live, which migrations applied manually,
    which env vars are set where
  - blocked-on-user: decisions only the user can make, stated explicitly
- **Mail/report draft** — when the work has a stakeholder awaiting an
  answer, draft it to a file. Draft, never send.
- **Memory closeout** — durable one-line facts to the memory repo if the
  project uses one; the handoff doc is the long form, memory is the index.

## Rules

- Write the handoff **before** the final summary — the summary links the
  file.
- A handoff is resumption-complete: a cold agent should continue without
  re-reading chat history. Test: could you resume this in 3 weeks?
- Open items stay open in text — mark `[added]`, `[pending]`, `[blocked]`
  rather than deleting lines that are still true.
- `git fetch` before claiming a bug is real — a parallel session may have
  landed it already.

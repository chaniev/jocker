# Backlog rules — Jocker

Read root AGENTS.md, backlog/README.md and docs/requirements/README.md.
Capture, triage, status reconciliation and planning do not authorize app changes.

- Preserve source notes, permanent JCR/TASK IDs and append-only logs.
- Search active cards, plans and dated done directories for duplicates.
- Card `- Статус:` matches its directory. Active cards contain `## Requirements`.
- Use REQ relations, concrete behavior-preserving `none`, or `pending` only in
  needs-clarification. Proposed/rejected requirements cannot enter ready, risky
  or implementation. Do not infer acceptance from a backlog entry.
- Blocking decisions belong in needs-clarification. Risky requires an identified
  failure mechanism, review and stop conditions, not just a module name.
- Plans live in implementation-plans until completion, with one plan per task.
  Planning is separate from starting execution. Ready plans have accepted
  requirements, decision evidence and no unresolved blockers.
- Every implementation card has a ready plan matching its requirements and a
  dedicated branch. Respect authorization already present in the request.
- Close only with evidence. Move completed card and plan together to
  done/YYYY-MM-DD; record completed_at and completion_date_evidence.
- Fix links and README statuses when moving a card. Keep logs as historical
  evidence; append corrections instead of rewriting them.
- Validate with make requirements-check and the root harness. Report unresolved
  decisions and duplicates without silently resolving product choices.

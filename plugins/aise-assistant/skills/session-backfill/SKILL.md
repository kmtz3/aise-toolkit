---
name: session-backfill
description: Backfill historical post-sales sessions for an already-configured customer (or all your customers with --bulk mine) — discovers from GCal + Gong, deduplicates against existing Planhat Conversations, and creates Conversation records with summaries. No Active Package bootstrap — Planhat has no equivalent.
argument-hint: "<customer> | --bulk mine [--since YYYY-MM-DD] [--dry-run]"
---

Backfill historical post-sales sessions for $ARGUMENTS.

Read the procedure in [`agents/session-backfill.md`](../../agents/session-backfill.md) and execute it inline as the main assistant — do not try to spawn `session-backfill` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses flags; also recognize natural language equivalents:

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "backfill sessions for Acme", "fill in session history for Acme" | **Single customer** — discovers and creates missing Conversation records for one customer. |
| `--bulk mine` | "backfill all my customers", "catch up all accounts", "fill sessions for all mine" | **Bulk** — runs across every customer this AISE has touched in Planhat; presents a queue before writing anything. |
| `--since YYYY-MM-DD` | "since I took over", "from [date]", "only sessions after [date]" | Limits lookback to sessions on or after this date. |
| `--dry-run` | "preview only", "show me what would be created", "don't write yet" | Reports what would be created without writing anything. |

## The procedure

1. **Resolves user identity** — Planhat `_id` and display name via `custom.AISE Identity` on the user's Planhat User record.
2. **Finds target customer(s)** — resolves the Planhat Company (name search → SF `sourceId` fallback). For `--bulk mine`, derives the touched-customer set from Task `ownerId` and Conversation `users` (Company `owner` is the CSM, not the AISE, so it isn't used for this). Presents a queue and waits for confirmation before any discovery in bulk mode.
3. **Discovers sessions in parallel** — GCal (events matching customer name/domain), Gong (via `meeting_lookup` → `Glean search app:gong`). Also sweeps existing Planhat Conversations for the company to build the dedup baseline.
4. **Resolves against Planhat** — runs the mandatory session-record resolution ladder (Conversation by `externalId` → Task by `sourceId` → title+company+date fallback) for every calendar-sourced candidate, and a scored title/date matcher for Gong-only candidates with no calendar event. Applies the relevance filter (excludes sales calls, internal PB syncs, generic GCal-only titles with no AISE) and an occurrence check (requires positive evidence a session actually happened before proposing a create).
5. **Infers type from the live Planhat type vocabulary, resolves Delivered By** — flags anything that can't be resolved cleanly. Never defaults Delivered By to the current user for historical sessions.
6. **Presents proposal in chat** — table of sessions to create with source, type, and flags. Waits for approval. `--dry-run` stops here.
7. **Writes Conversation records on approval** — re-checks dedup immediately before each write, sets `externalId` (GCal event id, or a `gong_`-prefixed key for Gong-only sessions) as the dedup key, and verifies every write by reading the record back.
8. **Reports** — created count, skipped count, flagged items with reasons, suggested next step.

Do NOT write any Conversation records until the user approves the proposal in step 6.
Do NOT ask the user to paste transcripts or calendar exports — discover everything via tools.

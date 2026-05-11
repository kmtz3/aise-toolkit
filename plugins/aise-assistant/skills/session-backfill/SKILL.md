---
name: session-backfill
description: Backfill historical post-sales sessions for an already-configured customer (or all your customers with --bulk mine) — discovers from GCal + Gong + Notion meeting notes, deduplicates against existing Session records, and creates Session entries with summaries. Bootstraps a missing Active Package from Salesforce if needed.
argument-hint: "<customer> | --bulk mine [--since YYYY-MM-DD] [--dry-run]"
---

Backfill historical post-sales sessions for $ARGUMENTS.

Read the procedure in [`agents/session-backfill.md`](../../agents/session-backfill.md) and execute it inline as the main assistant — do not try to spawn `session-backfill` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses flags; also recognize natural language equivalents:

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "backfill sessions for Acme", "fill in session history for Acme" | **Single customer** — discovers and creates missing Session records for one customer. |
| `--bulk mine` | "backfill all my customers", "catch up all accounts", "fill sessions for all mine" | **Bulk** — runs across all owned customers; presents a queue before writing anything. |
| `--since YYYY-MM-DD` | "since I took over", "from [date]", "only sessions after [date]" | Limits lookback to sessions on or after this date. |
| `--dry-run` | "preview only", "show me what would be created", "don't write yet" | Reports what would be created without writing anything. |

## The procedure

1. **Resolves user identity** — Notion UUID from the `AISE Identity` page.
2. **Finds target customer(s)** — verifies Customer page exists and is owned by the user. Checks for Active Package (`Active? = YES`). If none exists, runs the **Active Package Bootstrap** sub-procedure (queries Salesforce, Glean fallback, maps Master Package, proposes + waits for confirmation before creating). For `--bulk mine` presents a queue and waits for confirmation before any discovery.
3. **Discovers sessions in parallel** — GCal (events matching customer name/domain from contract start date), Gong (transcripts via `meeting_lookup` → `Glean search app:gong`), Notion meeting notes. Also queries existing Sessions DB to build the dedup baseline.
4. **Merges, deduplicates, and filters** — GCal+Gong same date → merge (Gong primary); removes sessions already in Sessions DB; applies the relevance filter (excludes sales calls, internal PB syncs, generic GCal-only titles with no AISE).
5. **Infers type (A/E/S), matches Consumed Package by date range, resolves Delivered By** — flags anything that can't be resolved cleanly. Never defaults Delivered By to the current user for historical sessions.
6. **Presents proposal in chat** — table of sessions to create with source, type, flags, and Consumed Package. Waits for approval. `--dry-run` stops here.
7. **Writes Session records on approval** — applies session template, writes brief + source link (or GCal-only placeholder with event metadata), populates decisions/actions/next steps from transcript where available.
8. **Reports** — created count, skipped count, packages bootstrapped, flagged items with reasons, suggested next step.

Do NOT write any Session records or Active Packages until the user approves the proposal in step 6.
Do NOT ask the user to paste transcripts or calendar exports — discover everything via tools.

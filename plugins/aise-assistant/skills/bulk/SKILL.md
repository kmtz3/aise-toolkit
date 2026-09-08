---
name: bulk
description: Run a workflow in bulk across multiple sessions or customers. Two modes via required flag: --debrief (post-session debrief across a date range, default yesterday) and --prep (session prep for the upcoming week's external meetings).
---

Run a bulk workflow. A mode flag is required:

- **`/bulk --debrief [date-range]`** — run the full post-session debrief for every external customer meeting across the target range (default: yesterday)
- **`/bulk --prep`** — run session prep for all external customer sessions in the upcoming week

If no mode flag is given, list the two modes with a one-line description and ask which to run.

---

## `--debrief` — bulk post-session debrief

Run the full post-session debrief workflow: **$ARGUMENTS**

Read the procedure in `agents/bulk-debrief.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Discovers external customer meetings across the target date range, resolves each to its Planhat Task/Conversation via the Google Calendar event ID resolution ladder, checks for evidence of a completed debrief (a done Task with a linked Conversation carrying real content), presents a debrief queue (with one round of mid-run expansion allowed), then executes the full post-session-debrief procedure for each unprocessed session sequentially. For queues of 4+ sessions, each session runs in an isolated sub-agent to prevent parent-context exhaustion.

### Steps

1. Resolve the target date range — defaults to yesterday. Accepts a positional natural-language argument (`yesterday`, `today`, `this past week`, `last 3 days`, `May 11-14`, `2026-05-11..2026-05-14`) or the legacy `--date YYYY-MM-DD` flag. See `agents/bulk-debrief.md` step 1 for the full parse table. Pull all calendar events for each day in the range and filter to external-confirmed meetings (≥1 non-@productboard.com attendee, user accepted, event confirmed).
2. Match each external meeting to a Planhat Company (owner-scoped to the current user) and resolve its session record via the GCal event ID ladder — Conversation by `externalId`, then Task by `sourceId`, then a company+date+title fallback (flagged when used), matching both candidate ID forms. A resolved Conversation is only "already debriefed" if its `description` carries real findings, not just an auto-conversion stub — flag fully-debriefed sessions as skipped, transcript-pending partials as skipped by default too (rerun-able), and stub/empty records as needing a full run.
3. Present the debrief queue — grouped by date when the range spans multiple days; lists sessions queued, sessions already debriefed (skipped by default, use `--rerun <customer>` in your reply to force-include), sessions skipped for other reasons, anything needing user input. Wait for one go-ahead. **One round of mid-run expansion is allowed** — if the user replies "yes and also add X", re-run discovery for X, merge into the queue (dedup by resolved Planhat record `_id`), and reconfirm before locking the queue.
4. Execute the `post-session-debrief` procedure for each queued session, sequentially in chronological order. **Mode by queue size:** inline for 1–3 sessions; spawn one `general-purpose` sub-agent per session for 4+ (each sub-agent receives the full `agents/post-session-debrief.md` procedure + session-specific inputs and returns a structured summary). Pass a bulk-run flag so dedup defaults inside the agent fall to "skip" rather than interrupting for input.
5. **Publish any debrief artifacts and link them into Planhat** per `context/session-artifact-convention.md` — same once-per-run folder and account-ID resolution as `--prep`. Written session summaries belong on the Planhat Conversation, not in Drive; only actual files (exports, decks, KDDs regenerated during debrief) get uploaded.
6. Print a master summary: sessions debriefed (with dedup skips noted per session), sessions already debriefed and skipped, other skips, sessions awaiting Gong transcript indexing (⚠️ Partial flag), anything needing manual follow-up.

Do NOT start running debriefs before the step 3 confirmation. Do NOT run debriefs in parallel — sequential execution applies in both inline and sub-agent mode.

**Arguments / flags:**
- **positional date-range** — `yesterday` (default), `today`, `this past week`, `last N days`, or an absolute range like `May 11-14` / `2026-05-11..2026-05-14`
- `--date YYYY-MM-DD` — legacy single-day form (still supported)
- `--skip <customer>` — exclude a customer from the queue (repeatable)
- `--rerun <customer>` — force-include a session already flagged as debriefed (repeatable)

---

## `--prep` — bulk session prep

Run bulk session prep for all external customer sessions in the upcoming week: **$ARGUMENTS**

Read the procedure in `agents/bulk-prep-week.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Scans the next 7 days of calendar events, maps each to an owned Notion Customer, deduplicates against existing Session pages with prep briefs, then runs full session prep sequentially for each session that needs it.

### Steps

1. Resolve the time window — default today + 7 days; `--week YYYY-MM-DD` anchors to a specific Monday–Sunday.
2. Pull all external calendar events — filter out all-PB meetings, declines, sub-30-min events, and all-day blockers.
3. Map each event to an owned Notion Customer record (by attendee domain / title); log unmatched and ambiguous as ⚠️.
4. Dedup: skip sessions that already have a `📋 Prep` toggle; update existing session pages that don't; create pages for sessions with no Notion record yet.
5. Run full session prep (following `session-prepper.md`) sequentially for each session that needs it — including KDD sub-pages for any Architecting sessions.
6. **Publish artifacts and link them into Planhat** per `context/session-artifact-convention.md`. Resolve the `Customer Session Artifacts` folder **once at the start of the run** (creating it if missing) and reuse the ID for every session — do not re-resolve per session. Resolve each customer's Salesforce Account Id once and reuse it across that customer's artifacts. Upload per the naming convention and prepend the artifact link block to `custom.Prep Notes` on each session's Planhat calendar-event Task (Conversation as fallback).
7. Report a per-session status table with links to all prepped Notion pages, **the Drive link and Planhat target record per artifact**, and a count of skipped / flagged items. Note once at the top if the Drive folder had to be created.

Do NOT ask for context that's retrievable. Search first, ask once if something is genuinely missing.

**Flags:**
- `--week YYYY-MM-DD` — anchor to a specific Monday–Sunday instead of today + 7 days
- `--skip <customer>` — exclude a customer from the run
- `--force <customer>` — rerun prep even if a brief already exists

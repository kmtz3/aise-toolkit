---
name: bulk
description: Run a workflow in bulk across multiple sessions or customers. Two modes via required flag: --debrief (post-session debrief for all yesterday's external meetings) and --prep (session prep for all next-week's external meetings).
---

Run a bulk workflow. A mode flag is required:

- **`/bulk --debrief`** — run the full post-session debrief for every external customer meeting from yesterday (or a specified date)
- **`/bulk --prep`** — run session prep for all external customer sessions in the upcoming week

If no mode flag is given, list the two modes with a one-line description and ask which to run.

---

## `--debrief` — bulk post-session debrief

Run the full post-session debrief workflow: **$ARGUMENTS**

Read the procedure in `agents/bulk-debrief.md` and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Discovers all external customer meetings from yesterday (or `--date`), matches each to a Notion customer + session, checks for prior debrief signals, presents a debrief queue, then executes the full post-session-debrief procedure for each unprocessed session sequentially.

### Steps

1. Determine the target date (yesterday by default; `--date YYYY-MM-DD` to override). Pull all calendar events and filter to external-confirmed meetings (≥1 non-@productboard.com attendee, user accepted, event confirmed).
2. Match each external meeting to a Notion Customer record (Owner-filtered to the current user) and existing Session record. Run a pre-flight debrief state check per session: notes exist? Gmail draft exists? Tasks exist? Flag fully-debriefed sessions as skipped, partially-debriefed as "fill gaps only."
3. Present the debrief queue — sessions queued, sessions already debriefed (skipped by default, use `--rerun <customer>` in your reply to force-include), sessions skipped for other reasons, anything needing user input. Wait for one go-ahead.
4. Execute the full `post-session-debrief` procedure inline for each queued session, sequentially in chronological order. Pass a bulk-run flag so dedup defaults inside that agent fall to "skip" rather than interrupting for input.
5. Print a master summary: sessions debriefed (with dedup skips noted per session), sessions already debriefed and skipped, other skips, anything needing manual follow-up.

Do NOT start running debriefs before the step 3 confirmation. Do NOT run debriefs in parallel.

**Flags:**
- `--date YYYY-MM-DD` — target a specific date instead of yesterday
- `--skip <customer>` — exclude a customer from the queue
- `--rerun <customer>` — force-include a session already flagged as debriefed

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
6. Report a per-session status table with links to all prepped Notion pages and a count of skipped / flagged items.

Do NOT ask for context that's retrievable. Search first, ask once if something is genuinely missing.

**Flags:**
- `--week YYYY-MM-DD` — anchor to a specific Monday–Sunday instead of today + 7 days
- `--skip <customer>` — exclude a customer from the run
- `--force <customer>` — rerun prep even if a brief already exists

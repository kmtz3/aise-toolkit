---
name: daily-brief
description: Pulls today's Google Calendar events and open Planhat Tasks, flags tomorrow's external sessions needing prep, auto-creates calendar focus blocks for missing prep, optionally auto-runs session-prepper to write full prep notes onto the Planhat calendar-event Task, and renders a styled HTML daily briefing page saved to ~/Desktop/aise-assistant/briefs/daily-brief-YYYY-MM-DD.html (or, in a scheduled cloud run with no device access, attached to the chat).
tools: Read, Write, Bash, SendUserFile, mcp__claude_ai_Google_Calendar__list_events, mcp__claude_ai_Google_Calendar__get_event, mcp__claude_ai_Google_Calendar__create_event, mcp__claude_ai_Planhat__list_model_records, mcp__claude_ai_Planhat__get_model_record, mcp__claude_ai_Planhat__search_records, mcp__claude_ai_Planhat__update_model_record, mcp__claude_ai_Planhat__create_model_record, mcp__claude_ai_Glean__search, mcp__claude_ai_Glean__meeting_lookup, mcp__claude_ai_Glean__gmail_search
---

You are the **daily-brief** agent. You pull today's calendar events and open Planhat Tasks, check tomorrow's calendar for sessions that still need prep, auto-create calendar prep blockers where needed, optionally trigger full session prep so notes land directly on the Planhat calendar-event Task, and render a self-contained HTML briefing page.

**Planhat is the source of truth for this agent.** Sessions, prep status, and open tasks are all read from Planhat (`Conversation` / `Task` models). Notion is retired — there is no fallback.

Not your job (unless `--auto-prep` is passed): drafting emails, running full session prep or summaries, fetching email/Slack content.

---

## Inputs

No required arguments. Optional:
- `--date YYYY-MM-DD` — generate the brief for a specific date instead of today (tomorrow = date + 1).
- `--open` — after saving, call `open <path>` to launch the file in the default browser.
- `--no-blocks` — skip the calendar focus block creation step entirely.
- `--no-debrief-check` — skip the "not yet debriefed this week" check (step 6b).
- `--auto-prep` — for tomorrow's sessions found missing prep (step 4), run the full `session-prepper` procedure inline instead of just flagging the gap. This is a materially heavier and slower operation per session (deep context pull, KDD sub-page for Architecting sessions, facilitation HTML) — off by default so the everyday morning brief stays fast. When off, tomorrow's unprepped sessions are still flagged and still get a calendar focus block (step 5) — they just don't get written yet.

---

## Run mode

Detect the mode once, before step 1, and carry it through to step 8:

- **Cloud / scheduled mode** — there are no `mcp__remote-devices__*` tools available, **or** the prompt says the run is "scheduled" or unattended. There is no computer bridge, so nothing can be saved to the user's Desktop and no one is there to answer questions. Never prompt; resolve ambiguity with the documented defaults and surface it in the chat flags.
- **Cowork mode** — the Read tool is blocked / running in the Linux sandbox. See step 8.
- **CLI mode** — Claude Code terminal, local filesystem available. See step 8.

---

## Procedure

### 1. Read user context

**Resolve identity:**
1. `list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<user's email from session context>"}, SELECT: ["firstName", "lastName", "email"])` → `planhat_user_id`, display name (or use the pre-resolved table in `context/planhat-schema.md` § Planhat User IDs).
2. `get_model_record(MODEL: "User", OBJECT_ID: "{planhat_user_id}", SELECT: ["custom.AISE Identity"])` → the field is HTML rich text (`<p>Key: value</p>` per line, not plain `\n`-separated text — see `context/planhat-user-profile.md`). Strip tags, split on `</p>`/`</li>` boundaries, then parse `Key: value` for preferred/first name, timezone, and working hours.
3. If the Planhat User lookup fails, or `custom.AISE Identity` is empty or fails to parse as `Key: value` pairs (e.g. comes back as a single unparseable token — a sign the field is corrupted): run the **Auto-resolve procedure** in `context/planhat-user-profile.md` § Auto-resolve procedure for consuming agents — check for a migratable legacy Notion page and auto-backfill if found; if genuinely nothing exists anywhere, run `agents/assistant-onboarding.md` inline to populate the profile, then resume this task. Do not just print a message and stop.

Parse from `custom.AISE Identity`:
- Preferred/first name (for the greeting header).
- Time zone (IANA, for correct midnight-to-midnight windows).
- Working hours end time (e.g. `17:00` or `18:00`) — used as the cutoff for prep block placement. If the field is absent or unparseable, default to `18:00`.

`planhat_user_id` (from step 1) is used directly as the `ownerId` filter for the Tasks query in step 6 — no separate Notion-specific identity needed anywhere in this agent.

Compute:
- **Target date** — today in the user's local time zone (or `--date` override). This is the "today" window.
- **Tomorrow date** — target date + 1 calendar day.

### 2. Pull calendar events — today + tomorrow

Call `list_events` twice: once for the full target date window, once for the full tomorrow window (each midnight-to-midnight in the user's timezone).

For each event collect: title, start/end datetime, attendee list (name + email domain), event status, user's response status, description snippet (first 200 chars).

**Timezone display rule.** Always convert and display every time in the user's timezone from `custom.AISE Identity` (step 1). **Ignore the event's own `timeZone` label**: events routinely carry `Europe/London` or `America/Los_Angeles` labels while the offsets are the user's local time, so trust the absolute instant (the offset on the `start`/`end` datetime), convert it to the user's IANA zone, and never print the event's label.

**Filter out immediately (both days):**
- Cancelled events.
- Events where user's response status is `declined`.
- All-day events (OOO markers, date blockers).

**Classify each remaining event:**
- **External customer session** — ≥1 non-`productboard.com` attendee, confirmed, user accepted. Before assigning this classification, check whether the external domain maps to a known Planhat Company: `search_records(QUERY: "<org name>")` filtered to `model: "Company"`, or `list_model_records(MODEL: "Company", FILTER: {"domains[contains]": "<domain>"})` as a fallback (check the name-mismatch table in `context/planhat-schema.md` § Customer Name Mapping before concluding no match — some accounts are named differently, e.g. "S&P Global Ratings" → Planhat "S&P Global"). If no matching Company is found **and** context suggests PB is the buyer/evaluator (e.g. a sibling internal "Trial" / "Eval" / "Pilot" event on the same day, or the external org is a known vendor/tool), classify as **Vendor / tool eval — not a customer session**, badge `⚠️ Not in Planhat (vendor/tool eval)`, and do **not** queue it for prep-block creation or Task lookup. Otherwise proceed with the customer-session path. Note: a Calendly-booked event whose description contains patterns like "📐 Architecting Session", "Training", or similar AISE session keywords is always external even if the domain check is inconclusive.
- **Internal meeting** — all attendees `@productboard.com`.
- **Focus block / prep block** — `eventType = focusTime`, OR `colorId = 7` (Google Calendar "Blueberry"), OR title contains "prep", "focus", "block", "no meetings", or similar patterns; treat as already-blocked time.
- **Solo / no attendees** — only the user on the invite.

**Schedule hygiene — compute after classification.** Sort today's and tomorrow's remaining events by start time (focus blocks and solo events excluded) and compute the gap between each event's end and the next one's start. For every **external customer session** that starts **less than 10 minutes** after another meeting ends (internal or external, including overlaps), record a `⚠️ Back-to-back` flag on that session: `"No buffer: [previous title] ends [HH:MM], this starts [HH:MM]"`. Show it in the HTML under the session and as a line in the chat flags. Flag only; never move events.

### 3. Check prep status — today's external sessions

For each external session (today's and tomorrow's — do this resolution once per unique customer+event, then reuse for both steps 3 and 4). **Resolve the session record first, then the Company from it**: a name or domain search is only a fallback, because it can return duplicate or unrelated Companies.

**A. Resolve the session's Planhat record by GCal event ID.** Run the ladder in `context/planhat-schema.md` § Session record resolution — the same one `session-prepper` § 5b uses, so the two must stay consistent. Derive both candidate IDs from the event (`event.id`, plus the segment before the first `_` for a recurring instance), then per candidate:
```
list_model_records(MODEL: "Conversation", FILTER: {"externalId[equal to]": "<candidate>"})
list_model_records(MODEL: "Task",         FILTER: {"sourceId[equal to]": "<candidate>"})
```
Use `equal to` only: `sourceId[starts with]` errors with "Failed to fetch Task records". An exact `externalId` / `sourceId` filter is reliable — the Task-model result cap only bites on unfiltered or non-unique queries. A recurring instance can match only on the instance-stamped ID, so always try both forms. A **Conversation** hit means the session is already logged (Task completed and converted); read prep status from that Conversation. A **Task** hit means it is still upcoming; read prep status from the Task. Only if both miss on both forms, fall back to `search_records(QUERY: "<calendar event title>")` filtered to a date match, and flag that it matched on title.

**B. Take the Company from the record.** When A resolved a Task or Conversation, its `companyId` **is** the Company — use it and skip any name search. This is what disambiguates accounts that exist twice in Planhat.

**C. Company search — only when A found no record.** `search_records(QUERY: "<org name from attendee domain or event title>")` filtered to `model: "Company"`. Check `context/planhat-schema.md` § Customer Name Mapping (including its duplicate-Company note) before concluding no match. Fall back to `list_model_records(MODEL: "Company", FILTER: {"domains[contains]": "<domain>"})`, keeping only Companies whose `domains` array contains the domain as an exact element (also try the parent domain of a subdomain). **When more than one Company comes back, prefer the one whose `owner` equals `planhat_user_id`**, and add a `⚠️ Duplicate Company: <name> ×N, used <_id> (owned by you)` line to the chat flags. If several owned Companies still match, take the one confirmed by the event title and flag it. If no Company resolves at all, badge `— Not in Planhat` and skip D below.

**D. Badge from `custom.Prep Notes` on whichever record the ladder returned:**
- Record found (Task or Conversation) + `custom.Prep Notes` has real content (not empty/whitespace) → `✅ Prep done`
- Record found + `custom.Prep Notes` empty or absent → `⚠️ No prep`
- Nothing resolved (Company resolved but no Task and no Conversation for the event ID) → `— Not in Planhat` (GCal sync may not have created one yet, or the event is too recently added)

**Playbook link (external sessions, today and tomorrow).** Read `custom.Facilitation Playbook URL` in the same Task read as `custom.Prep Notes` (add it to the `SELECT`). If it is empty, or the record is a Conversation (the field is Task-only), fall back to the `Drive file:` link in the artifact header whose filename ends `_Facilitation.html`, parsed **before** the header strip below. No match either way = no guide; show nothing and never infer one from a `_SessionPrep.html` or `_KDD.html` link. Store the URL per session for Step 7. Read-only: daily-brief never writes this field (`--backfill-playbook-urls` does).

**Prep-notes parsing — skip the artifact header.** `custom.Prep Notes` can start with a "SESSION PREP ARTIFACT … Drive file …" header block that links the artifact. Strip it (everything up to and including the first `<hr>`, or the paragraph run that begins with that heading) before extracting the topic or the risk line below, so neither picks up the header text.

**Resolve session topic — today's external sessions:**
For each external session, derive a 2-sentence topic summary using this priority order:

1. **Planhat Task first** — if `custom.Prep Notes` has content (from A/D above), extract the `Goals` line from the body after the header strip. If empty but the Task has a `description`, use that.
2. **Specific calendar event description** — check the event's `description` (already fetched in Step 2) before reaching for weaker signals. Classify it: generic (empty/whitespace, or only conferencing boilerplate — Zoom/Meet/Teams links, dial-in numbers, scheduling footers) → skip to 3; specific (named topics, an "Agenda:" line/bullet list, questions to cover, a doc/deck link, a decision to make) → use it directly as the topic, since it's what was put on the invite for this session.
3. **Most recent Planhat Conversation** — if no usable Task content and no specific calendar signal, query `list_model_records(MODEL: "Conversation", FILTER: {"companyId[equal to]": "<company-id>"}, SORT: "-date", LIMIT: 5)` and read the most recent `description`/`subject` for context on where things left off.
4. **Glean fallback** — if the above have nothing, call `mcp__claude_ai_Glean__search` or `mcp__claude_ai_Glean__meeting_lookup` with the customer name + approximate date to find the most recent Gong call, Slack thread, or Gmail thread referencing this session. Extract the agreed agenda or topic. Use `mcp__claude_ai_Glean__gmail_search` as a secondary check if Gong/Slack return nothing useful.
5. **Generic calendar text as last resort** — if Glean also returns nothing and the calendar description was generic, fall back to the first 150 chars of it anyway rather than leaving the topic blank.
6. **If no signal found** — leave topic blank; do not fabricate.

**Top-risk line.** From the same `custom.Prep Notes` (after the header strip), extract **one** line: the first line/paragraph starting with `🔴`; if none, the first `<blockquote>`. Strip tags, keep it to one sentence (trim to ~160 chars with an ellipsis). It is the binding warning (renewal at risk, legal constraint, a consent that must stay off). Omit it when neither exists; never synthesise a risk from other sources.

Store the resolved topic string and risk line per session for use in Step 7.

### 4. Check prep status — tomorrow's external sessions

Same A–D resolution as Step 3 (record by event ID first, Company from the record), applied to tomorrow's external sessions. For each:

- Task found + `custom.Prep Notes` has real content → `✅ Prep done` — no action needed.
- Task found + `custom.Prep Notes` empty/absent → `🚨 Prep needed` — queue for blocker creation (step 5) and, if `--auto-prep` was passed, full prep writing (step 5.5).
- Nothing resolved (or no Company at all) → `— Not in Planhat` — still queue for blocker creation and auto-prep; flag the gap separately. This usually means GCal sync has not created the Task yet. Session-prepper's § 5b re-runs the full ladder itself and only creates as a last resort with `sourceId` set — it must not be relied on to create routinely.

Resolve topic and top-risk line using the same rules as Step 3.

Collect the **prep-needed queue**: sessions that need prep and don't already have it (each entry: customer name, Planhat company id, calendar event, resolved Planhat Task id if one exists).

Also scan today's existing events for any event whose title matches the prep-block pattern (step 2) and whose description or title references the same customer. If a prep block already exists for a customer, remove that customer from the prep-needed queue.

### 5. Create calendar focus blocks — for each prep-needed session

Skip this entire step if `--no-blocks` was passed.

For each session in the prep-needed queue:

**A. Calculate prep duration.**
Read `context/project-instructions.md` for the prep time benchmark by session type. If the section isn't found, use these defaults:
- 🏗️ Architecting → 60 min
- 🎓 Training → 45 min
- 🗣️ Sync → 30 min
- 🔎 Discovery / 👟 Kick off → 45 min
- Unknown type → 45 min

**B. Find the best available slot today.**
Use the `Working hours` end time resolved from the Identity page in Step 1 (default `18:00` if absent) as the hard cutoff. If the current local time is already at or past that cutoff, skip block creation for this session and note "⏰ Past working hours — no prep block created" in both the chat summary and the HTML tomorrow section; do not create the event.

Otherwise, scan today's calendar events to find a free window of at least the required duration before the working-hours cutoff. Prefer the afternoon. Avoid placing the block back-to-back against an existing meeting (leave ≥10 min gap). If no suitable slot exists today, place the block tomorrow morning at least 90 minutes before the session start time.

**C. Check for duplicate.**
Before creating, scan the existing event list for any event title containing `[Prep]` and the customer name. If one already exists, skip creation for this customer and note it.

**D. Create the event.**
Call `create_event` with:
- **Title:** `[Prep] [Customer name] — [Session type or "Session"]`
- **Start/end:** the slot calculated in step B.
- **Description:** `Prep block auto-created by /daily-brief. Session: [session title] on [tomorrow date at time].`
- **Calendar:** user's primary calendar.

Record: customer name, created slot (start–end), event ID.

### 5.5. Write full prep notes to Planhat — only if `--auto-prep` was passed

Skip this entire step if `--auto-prep` was not passed (default). When it is skipped, tomorrow's unprepped sessions still get flagged (step 4) and still get a calendar focus block (step 5) — they just don't get prep content written yet.

For each session remaining in the prep-needed queue after step 5:

Run the full procedure in [`agents/session-prepper.md`](session-prepper.md) inline (per the standard "agents are procedure documents, run inline" convention — do not spawn it as a subagent), treating the calendar event as the session identifier. This is the same invocation pattern `bulk-prep-week.md` § 5 uses. Session-prepper's own § 5b is what actually writes the full brief into `custom.Prep Notes` on the Planhat Task (`mainType: "event"`) matching the session — that is the mechanism that makes prep notes "ready there" on the calendar event, matching the Task resolved in step 3/4-A above. Session-prepper is Planhat-only end to end — there is no Notion write to reconcile.

Run sessions **sequentially**, not in parallel — same reasoning as `bulk-prep-week`: each context pull is heavy and parallel writes risk conflicts.

**Artifact publishing.** Each auto-prepped session also publishes its prep artifact per `context/session-artifact-convention.md` — session-prepper § 6.8 does the work. Resolve the `Customer Session Artifacts` folder **once for the whole run** (creating it if missing) and pass the cached folder ID and per-customer Salesforce Account Id into each session-prepper invocation so it isn't re-resolved per session. Report folder creation once, at the top of step 9.

After this step, re-check `custom.Prep Notes` on each affected Task (same lookup as step 3/4-D) so step 7's badges reflect the just-written state rather than the stale pre-run status.

### 6. Pull open Planhat Tasks

Query the Planhat Task model directly, scoped to the current user as owner. **This query is paged and merged, never a single call** (see `context/planhat-schema.md` § API Quirks: result caps and paging):
```
list_model_records(
  MODEL: "Task",
  FILTER: {"ownerId[equal to]": "<planhat_user_id>", "mainType[equal to]": "task"},
  SELECT: ["action", "status", "endTime", "companyId", "companyName", "custom.Priority", "sourceId"],
  SORT: "endTime",
  LIMIT: 200,
  OFFSET: <0, 200, 400, ...>
)
```
**Mandatory paging loop.** Start at `OFFSET: 0`; after each page, if it returned exactly `LIMIT` (200) rows, fetch the next page at `OFFSET + 200`; stop only when a page returns **fewer than 200 rows**. Merge all pages into one list (dedupe on `_id`) **before** any filtering, tiering or per-company grouping, and run the rest of this step and step 6a on the merged list. `SORT: "endTime"` ascending puts undated tasks first, so page 1 alone is undated tasks plus the earliest overdue ones, and everything due recently sits on later pages: a single page is never the answer. Record the page count and merged total for step 9. If a page errors, say so in the flags and report the task list as incomplete rather than rendering the pages that did load as the whole set.

`mainType: "task"` excludes calendar-event Tasks (`mainType: "event"`) from this list — those are meetings, not action items. Exclude `status` of `done` and `ignored` in post-processing, case-insensitively (the field holds `Done` and `done`; it is not reliably filterable server-side — see the Task model's known filter quirks). Blank `status` is open.

For each task collect: title (`action`), Company name (`companyName`, or resolve `companyId` if absent), Due date (`endTime`), Priority (`custom.Priority`, normalised per the rule below), `status`, Planhat Task `_id` (for building a direct link — use the template in `context/planhat-schema.md` § Planhat Record URLs: `https://ws.planhat.com/productboard/home/data-explorer/task?preview=Task.<_id>`. The `task` path slug is confirmed verified (2026-09-03)).

**Normalise priority.** `P1` and `High` are equivalent, as are `P2` and `Medium`. Treat `P0`, `P1` and `High` as **high priority** in the rules below.

**Detect template tasks first, then tier the rest.** Apply the rules in `context/planhat-schema.md` § Task hygiene: a Task is a template task when its title starts with `[PRE]`, `[POST]` or `[SESSION]`, **or** it has no `status` and no `custom.Priority`, **or** it shares an identical `endTime` with at least 5 other Tasks on the same Company (bulk-created program checklists). Remove template tasks from the tiers and collapse them to **one summary line per Company** (`[Company]: [N] template checklist tasks, oldest due [date]`) in a "Program checklists" group under the task section. They are not counted in the "open tasks" header number except as one line each.

**Tier each remaining task:**
- **Today** — due today or yesterday (`endTime` is target date or the day before), OR any task with high priority (`P0`/`P1`/`High`) that is due on or before the target date and not stale, OR no due date with `status = "in-progress"`.
- **Overdue** — due before yesterday but within the last 30 days, and not high priority. Shown in its own `🔴 Overdue` group below Today, expanded, so it stays visible without burying today's work.
- **Stale** — real (non-template) task more than **30 days** past `endTime`. Collapsed `<details>` bucket, closed by default, with the count in the summary. A stale task is never promoted to Today, even when high priority; the high-priority ones carry a 🔴 badge inside the bucket.
- **This Week** — due tomorrow through end of the current calendar week (Sunday, or Friday if uncertain).
- **Later** — due beyond end-of-week, OR no due date (unless already captured above).

Within a tier, sort high priority first (`P0`, `P1`/`High`, `P2`/`Medium`, `P3`, `P4`, blank), then overdue before not-yet-due, then due date ascending, then alphabetically. Priority never moves a task across tiers except into Today as defined above.

### 6a. Link open tasks to the sessions they relate to

For every external customer session today and tomorrow, take its resolved `companyId` (step 3) and filter the **merged, non-template** task set to that Company, excluding stale tasks. Rank: high priority first, then overdue, then by due date. Keep the top **5** as that session's **"Open before this call"** list; if more exist, add a `+N more` line. Each entry: title, priority badge, due date (red when overdue), Planhat link. Do not remove these tasks from the global lists in step 7; the global list stays below as the full picture. Omit the "Open before this call" block when the Company has no open tasks.

### 6b. Check for undebriefed sessions this week (read-only)

Skip if `--no-debrief-check` was passed. This step never writes to Planhat and never runs a debrief, it only surfaces the gap so a missed call is visible every morning.

1. **Window.** Monday of the current ISO week (user's time zone) through now; on a Monday, from the previous Monday. Same window as the `bulk-debrief` weekly sweep (`agents/bulk-debrief.md` step 1b), so the brief and `/bulk --debrief` always agree on what counts as "this week".
2. **Candidates and status.** Run `agents/bulk-debrief.md` steps 2–4 over that window, read-only: pull calendar events, keep external-confirmed events that have already ended (use `Bash: date -u +%Y-%m-%dT%H:%M:%SZ` for "now"), resolve each to its Planhat Company (owner = current user) and session record via the GCal event ID ladder, then classify via `custom.Debrief Status` (with the step 4C heuristic only for records where it is blank). Reuse any Company / session resolution already done in steps 3 and 4 for the same events.
3. **Bucket each session:**
   - `complete` / verified by heuristic → counted, not listed.
   - **Not debriefed** (no record, stub only, Task done with no Conversation, or Conversation with findings but no Slack debrief Task) → listed.
   - `partial - transcript pending` → listed separately as "Transcript pending".
4. **Output.** For the HTML section and chat summary, each listed row carries: date, customer, session title, days since the call, and the reason (e.g. "no Conversation", "stub only", "no Slack debrief Task", "transcript pending"). If nothing is listed, render a one-line "All of this week's delivered sessions are debriefed" with the count checked.
5. Do not run the debrief from here. The fix is `/bulk --debrief`, which sweeps the same window and queues exactly these sessions.
6. If Calendar or Planhat is unavailable for this step, say so in the section rather than showing an empty list that looks like "all clear".
7. **Open debrief tasks (second list).** From the merged task set of step 6 (before template/stale filtering, so old ones count), take open tasks whose `action` matches `Slack debrief` or `Re-debrief` (case-insensitive substring: `Slack debrief – [Customer] [date]` and `Re-debrief [Customer] [date] — Gong transcript` are the shapes `post-session-debrief` writes). Group by Company: **Company, count, oldest due date** (`endTime`; `—` when none), each group linking to its oldest task. Sort by count descending, then oldest date. Render under the undebriefed list as "Open debrief tasks ([total])". Empty state: omit the list. This list is separate from the undebriefed-sessions list above: those are calls with no debrief at all, these are debriefs that already exist as outstanding work.

### 7. Render the HTML page

Build a self-contained HTML file (inline CSS, no external dependencies, no CDN links). Structure:

```
<header>
  Daily Brief
  [Weekday, Month DD, YYYY]
  [First name] · [N] meetings today · [N] open tasks · [N] prep block(s) created
</header>

<section: Today's Schedule>
  [Time range]  [Event title]
  [Badge: customer name + prep status | "Internal" | "Focus block"]
  [📘 Facilitation guide: link — external sessions with a playbook URL only; omit otherwise]
  [Topic: 2-sentence agreed topic — external customer sessions only, omit if no topic resolved]
  [Risk: top-risk line — external customer sessions only, omit if none]
  [⚠️ Back-to-back flag — omit if buffer ≥ 10 min]
  [Open before this call: up to 5 open tasks for this Company (step 6a)]
  [Attendees — external in bold]
  (sorted by start time; all times in the user's timezone)

<section: Tomorrow — Heads Up>
  For each of tomorrow's external sessions (sorted by time):
  [Time]  [Event title]
  [Badge: ✅ Prep done | 🚨 Prep needed → "📅 Prep block created [time]" | "⚠️ Not in Planhat"]
  [📘 Facilitation guide: link — only when a playbook URL resolved; omit otherwise]
  [Topic: 2-sentence agreed topic — omit if no topic resolved]
  [Risk: top-risk line — omit if none]
  [⚠️ Back-to-back flag — omit if buffer ≥ 10 min]
  [Open before this call: up to 5 open tasks for this Company (step 6a)]
  [Attendees]

<section: Not debriefed this week>    ← omitted entirely under --no-debrief-check
  [Date]  [Customer]  [Session title]  [N days ago]  [Badge: 🔴 Not debriefed (reason) | 🟡 Transcript pending]
  Footer line: "Run /bulk --debrief to catch these up." Empty state: "All [N] delivered sessions this week are debriefed."
  Then "Open debrief tasks ([N])": one row per Company: [Company]  [count] open  oldest due [date]  [↗ Planhat link]  (omit when none)

<section: Open Tasks>
  ### 🔴 Today ([N])    ← due today/yesterday, or high priority (P0/P1/High) and not stale
  [Task title]  [Customer]  Due: [date or "—"]  [Priority badge]  [Status badge]  [↗ Planhat link]

  ### 🟠 Overdue ([N])    ← 2–30 days past due, not high priority
  [same row format]

  ### 📅 This Week ([N])
  [same row format]

  ### 📦 Later ([N])    ← inside a <details> toggle, collapsed by default
  [same row format]

  ### 🕸️ Stale ([N])    ← >30 days overdue, inside a <details> toggle, collapsed by default
  [same row format]

  ### 🗂️ Program checklists ([N] companies)    ← template tasks collapsed, one line per Company
  [Company]: [N] template checklist tasks, oldest due [date]

<footer>
  Generated [HH:MM local time] · Sources: Google Calendar · Planhat
  Quick links: [Planhat] [Gmail] [Google Calendar]
</footer>
```

**Design spec:**
- Dark theme (`background: #0f172a`, card sections `background: #1e293b`), system font (`-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`). Text: `#e2e8f0` primary, `#94a3b8` muted.
- Max width 760px, centered, white card sections with `box-shadow: 0 1px 3px rgba(0,0,0,.12)`, `border-radius: 8px`, comfortable padding.
- Color-coded badges: green `#22c55e` = prep done, amber `#f59e0b` = no prep / warning, red `#ef4444` = overdue / prep needed, blue `#3b82f6` = today task, purple `#8b5cf6` = in-progress, grey `#94a3b8` = later / internal.
- Session topic line: render as `<div class="sched-topic">Topic: {topic}</div>` with `font-size: 13px; color: #94a3b8; font-style: italic; margin-top: 4px;`. Omit the element entirely when no topic was resolved — do not render an empty label.
- Top-risk line: render as `<div class="sched-risk"><span class="badge badge-red">Risk</span> {risk}</div>` directly under the topic, with `font-size: 13px; margin-top: 4px;`, red `#ef4444` badge and normal-weight text in `#e2e8f0`. Omit the element entirely when no risk line was extracted.
- Facilitation guide link: a single `<a class="sched-guide">` row with the label `📘 Facilitation guide`, `font-size: 13px`, `target="_blank" rel="noopener"`, placed directly under the badge row; rendered only when a playbook URL resolved.
- "Open before this call" block: `<div class="sched-open">` with a muted label and a compact list of up to 5 rows (title, priority badge, due date, link), `font-size: 13px`; overdue due dates in red.
- Tomorrow section has a soft yellow-tinted background (`#fffbeb`) to visually separate it from today.
- Tasks in the Later section inside a `<details><summary>Show [N] later tasks</summary>…</details>` toggle; Stale the same way (`Show [N] stale tasks (30+ days overdue)`), closed by default.
- No images, no external fonts, no JS dependencies beyond native `<details>`.
- Mobile-readable at 375px width.

### 8. Save the file

Always write the HTML using the **Write tool** (not bash `cat` or redirection) so it is available for delivery. Pick the branch by the **run mode** detected at the top.

**Delivery — Cloud / scheduled, Cowork, or CLI:**

- **Scheduled / cloud mode (no device bridge):** there is no computer access, so the Desktop path does not exist and `mcp__cowork__present_files` is unavailable. Write the HTML with the Write tool to the **current working directory** as `daily-brief-YYYY-MM-DD.html`, then deliver it with `SendUserFile` (`display: "attach"`). Do not attempt `mkdir`, `cp` to `~/Desktop`, or `open`. In the chat summary, state that **the Desktop copy was skipped because this run had no computer access**. Never improvise another delivery route.
- **Cowork mode** (Read tool blocked / skill running in Linux sandbox): Write the HTML to a path within the current session outputs folder (e.g. the current working directory). Then call `mcp__cowork__present_files` with `{"files": [{"file_path": "<outputs_path>/daily-brief-YYYY-MM-DD.html"}]}` to deliver the file to the user's Mac. Do **not** use bash `cp`, `mkdir`, or `open` — those commands run inside the Linux sandbox and cannot reach the user's Mac filesystem.
- **CLI mode** (Claude Code terminal, Read tool works): Use the Write tool to save to `~/Desktop/aise-assistant/briefs/daily-brief-[YYYY-MM-DD].html`. You may also run `mkdir -p ~/Desktop/aise-assistant/briefs` via bash before writing if the directory does not exist. If `--open` was passed, run `open ~/Desktop/aise-assistant/briefs/daily-brief-[YYYY-MM-DD].html`.

`--open` is ignored in cloud and Cowork modes. Overwrite if a file already exists at that path (re-runs are idempotent).

**Building the HTML.** Merge all Task pages into one list first (step 6) and generate the HTML from that merged list, whether by hand or by a script, so the render never reads a single page.

### 9. Report in chat

Post a compact summary:

```
**Daily brief saved** → ~/Desktop/aise-assistant/briefs/daily-brief-[YYYY-MM-DD].html  _(cloud/scheduled run: "attached to this chat; Desktop copy skipped, no computer access")_

Today: [N] meetings ([N] external, [N] internal) · [N] open tasks ([N] today, [N] overdue, [N] this week, [N] stale, [N] template checklist tasks across [N] companies)
Task fetch: [N] pages, [N] tasks merged

Tomorrow:
- [Customer] — [time] — 🚨 Prep needed → 📅 Block created [HH:MM–HH:MM][ · ✅ Full prep written to Planhat (--auto-prep) | ⚠️ Prep written to Notion only — not yet Planhat-migrated]
- [Customer] — [time] — ✅ Prep already done

Not debriefed this week: [N] of [M] delivered sessions – [Customer date (reason)], ... (run /bulk --debrief) | all [M] debriefed | check skipped (--no-debrief-check)
Open debrief tasks: [N] – [Company ×count, oldest date], ...

⚠️ Flags: [overdue tasks | sessions not in Planhat | blocked prep slots with no room | back-to-back external sessions (no buffer) | duplicate Companies found (name ×N, used which) | task count may be incomplete (a page failed)]
```

When `--auto-prep` published artifacts, add an **Artifacts** block underneath: one line per session with the Drive file name, link, and the Planhat record the link landed on — plus a single line if the `Customer Session Artifacts` folder had to be created this run.

---

## Guardrails

- **No writes to Gmail.** This agent writes: the local HTML file, calendar focus block events, and — only with `--auto-prep` — full prep content via `session-prepper` (which writes both the Notion Session page and the Planhat Task, per its own contract). Without `--auto-prep`, this agent is read-only aside from the HTML file and calendar blocks.
- **Dedup calendar blocks.** Never create a second prep block for the same customer on the same day. Check before creating.
- **If Calendar is unavailable**, render tasks section only; note the failure prominently in both the HTML and chat.
- **If Planhat is unavailable**, render calendar section only; skip Tasks and prep-status badges; note the failure.
- **Overdue tasks are tiered, not blanket-promoted.** Due today or yesterday → Today; 2–30 days overdue → Overdue; more than 30 days → Stale (collapsed). High-priority (`P0`/`P1`/`High`) non-stale tasks due on or before today go to Today. Template checklist tasks are collapsed to one line per Company and never listed individually.
- **Never trust a single page of a Task query.** Page until a page returns fewer than `LIMIT` rows, merge, then process (step 6). A page that returns exactly `LIMIT` rows means there is another one.
- **Scheduled runs never prompt and never assume a Desktop.** Use the cloud branch of step 8 and say what was skipped.
- **`--no-blocks` is an escape hatch** — respect it without asking why.
- **`--auto-prep` is opt-in, not default** — never run session-prepper without it being explicitly passed; the everyday brief should stay fast.
- **Never include customer names in the HTML filename.** Date only.
- **If no free slot exists today and tomorrow morning is <90 min before the session**, note "no room for prep block" in chat rather than placing a block that would be useless.
- **Customer confidentiality.** The daily-brief HTML stays local by default — do not upload or share it unless the user explicitly asks for it to be filed in Drive, in which case it follows `context/session-artifact-convention.md` as `{UserName}_{YYYY-MM-DD}_NA_Brief.html`. Per-session prep artifacts published under `--auto-prep` are a separate thing and do go to the `Customer Session Artifacts` folder.
- **The debrief check (step 6b) is read-only.** It never creates Tasks, Conversations or calendar events and never runs a debrief. A failed lookup is reported as a failed check, never rendered as "all debriefed".
- **Reporting transparency.** Never report a session as "prep done" or a task list as complete when the signal looks suspiciously absent (a Company with zero Tasks/Conversations ever, for an account you know is active) — flag it rather than silently under-report.

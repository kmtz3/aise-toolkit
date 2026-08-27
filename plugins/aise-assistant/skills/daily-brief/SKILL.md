---
name: daily-brief
description: Pull today's meetings + open Planhat Tasks, flag tomorrow's sessions needing prep, auto-create calendar focus blocks for missing prep, optionally auto-write full prep notes onto the Planhat calendar-event Task, and render a styled HTML daily briefing page to ~/Desktop/aise-assistant/briefs/.
---

Generate a daily briefing page for **$ARGUMENTS** (defaults to today).

Read the procedure in the plugin's `agents/daily-brief.md` and execute it inline as the main assistant — do not try to spawn `daily-brief` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). **Path note:** `agents/daily-brief.md` lives at the plugin root (e.g. `plugins/aise-assistant/agents/daily-brief.md`), not inside the skill subdirectory — use an absolute path or resolve from the plugin root, not relative to `skills/daily-brief/`. **Planhat is the source of truth for this skill** — sessions, prep status, and tasks are all read from Planhat, not Notion (see the agent file's header note for why). The steps:

1. Resolve user identity — follow Step 1 of `agents/daily-brief.md` exactly (Planhat `custom.AISE Identity` lookup for name/timezone/working hours/`planhat_user_id` — the field is HTML rich text, strip tags before parsing `Key: value` lines). Compute today and tomorrow's date windows.
2. Pull both days' calendar events; classify each (external customer session, internal, focus block) — resolving the Planhat Company per event to check for a vendor/tool-eval mismatch.
3. For today's external sessions: resolve the matching Planhat Task (`mainType: "event"`, GCal-synced) and badge prep status from `custom.Prep Notes`.
4. For tomorrow's external sessions: flag any missing prep, auto-create a focus block on today's calendar (skip with `--no-blocks`), and — only if `--auto-prep` was passed — run the full `session-prepper` procedure inline so the prep brief lands in `custom.Prep Notes` on the Planhat Task, not just a blank calendar block. Each auto-prepped session also publishes its prep artifact to Drive and links it back per `context/session-artifact-convention.md` — resolve (or create) the `Customer Session Artifacts` folder once for the whole run and reuse the ID across sessions.
5. Pull all open Planhat Tasks (`mainType: "task"`, owner = current user) and tier them: Today / This Week / Later (overdue always promoted to Today).
6. Render a self-contained HTML page and save to `~/Desktop/aise-assistant/briefs/daily-brief-YYYY-MM-DD.html`. If `--open` was passed, launch in browser. The brief itself stays local by default — only upload it to Drive (as `{UserName}_{YYYY-MM-DD}_{SalesforceAccountId|NA}_Brief.html`) if the user asks for it to be filed there.
7. In the chat summary, list every artifact published this run: file name, Drive link, and which Planhat record received the link. Say so explicitly if the Drive folder had to be created.

Do NOT ask the user for context that's retrievable. Search first, ask once if something is genuinely missing.

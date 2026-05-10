---
name: daily-brief
description: Pull today's meetings + open Tasks, flag tomorrow's sessions needing prep, auto-create calendar focus blocks for missing prep, and render a styled HTML daily briefing page to ~/Desktop/aise-assistant/briefs/.
---

Generate a daily briefing page for **$ARGUMENTS** (defaults to today).

Read the procedure in `agents/daily-brief.md` and execute it inline as the main assistant — do not try to spawn `daily-brief` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Read `about/identity.md` for name and timezone; compute today and tomorrow's date windows.
2. Pull both days' calendar events; classify each (external customer session, internal, focus block).
3. For today's external sessions: check Notion for a prep brief and badge accordingly.
4. For tomorrow's external sessions: flag any missing prep and auto-create a focus block on today's calendar (skip with `--no-blocks`).
5. Pull all open Notion Tasks for the user and tier them: Today / This Week / Later (overdue always promoted to Today).
6. Render a self-contained HTML page and save to `~/Desktop/aise-assistant/briefs/daily-brief-YYYY-MM-DD.html`. If `--open` was passed, launch in browser.

Do NOT ask the user for context that's retrievable. Search first, ask once if something is genuinely missing.

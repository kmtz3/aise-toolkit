---
name: session-summary
description: Summarize a delivered session — finds transcript independently, extracts decisions/actions/risks, proposes Notion updates
---

Summarize the session identified in the user's message (customer name and/or session date).

If no argument is given, check the calendar for today's and yesterday's delivered customer sessions and ask which one.

Read the procedure in `agents/session-summarizer.md` and execute it inline as the main assistant — do not try to spawn `session-summarizer` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Find the transcript/notes **without asking the user to paste** — follow the **Transcript lookup order** in `context/project-instructions.md §3` (meeting_lookup → Gong search → Notion meeting notes → session page body → Gmail → Glean chat → ask once).
2. Extract decisions (KDDs), open items, action items (split PB-side vs Customer-side), risks, stakeholder changes.
3. Propose Notion updates:
   - Update the Session page (status → Delivered, summary appended to body).
   - Update the Customer page (decisions log, stakeholder shifts).
   - Create Tasks **only for PB-side action items** — customer-side actions stay in the summary.
4. Wait for confirmation before writing, unless the user has given a standing approval.
5. Offer a follow-up draft (email or Slack) if appropriate.

Flag conflicts between sources — don't silently pick.

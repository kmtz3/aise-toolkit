---
name: session-summary
description: Summarize a delivered session — finds transcript/notes independently, extracts decisions/actions/risks, returns them in chat. Read-only, no writes.
---

Summarize the session identified in the user's message (customer name and/or session date).

If no argument is given, check the calendar for today's and yesterday's delivered customer sessions and ask which one.

Read the procedure in `agents/session-summarizer.md` and execute it inline as the main assistant — do not try to spawn `session-summarizer` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Find the transcript/notes **without asking the user to paste** — follow the **Transcript lookup order** in `context/project-instructions.md §3`, skipping its Notion-specific hops (Gong `ask_account` → Glean `meeting_lookup` → Glean `search` scoped `app:gong` → Gmail → Glean `chat` → ask once). Also always run the **Facilitator call notes in Planhat** check on the session's Task/Conversation.
2. Extract decisions (KDDs), open items, action items (split PB-side vs Customer-side), risks, stakeholder changes, source.
3. Return the structured extraction in chat — this is a read-only command, there is nothing to confirm or write.
4. Offer a follow-up draft (email or Slack) if appropriate — delegate to `agents/email-drafter.md`.
5. Offer a scorecard self-assessment if the user asks (`/session-score` or "score this").

Flag conflicts between sources — don't silently pick.

For the full post-session workflow that also writes to Planhat (Conversation, Tasks, follow-up draft, scorecard, `custom.Next Step`), use `/session-debrief` instead — it invokes `session-summarizer` for extraction only and does every write itself.

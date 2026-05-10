---
name: session-prep
description: Prep for a customer session — pulls context, drafts a brief, posts to Notion under a toggle
---

Prep the user for the customer session identified in the user's message (customer name, session type, and/or date).

Read the procedure in `agents/session-prepper.md` and execute it inline as the main assistant — do not try to spawn `session-prepper` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Confirm date, attendees, and session type (Calendar + Notion lookup if needed).
2. Pull context from Glean, Gmail, Notion, Calendar, and past chats — in parallel.
3. Consult `context/pb-aise-reference-guide.md` (what-good-looks-like) and `context/score-cards.md` for the session type.
4. Draft a prep brief: customer context, goals, KDDs to drive, open items, risks, suggested agenda, questions to ask.
5. Find the Notion Session page (create one if missing) and append the brief inside a collapsible toggle heading `📋 Prep — YYYY-MM-DD` so real session notes can go underneath.
6. **If the session is `🏗️ Architecting`**, also build the customer-facing KDD doc (title, agenda, outcome, action items, per-KDD starter examples + blank decision tables) per `templates/session-kdds/00-index.md`, and create it as a **sub-page of the Session page** titled `KDDs — [Session ID] [Name]`. Ready to copy-paste into the customer's space.
7. Report back with links (Session page + KDD sub-page when created) and any gaps or contradictions surfaced.

Do NOT ask the user for context that's retrievable. Search first, ask once if something is genuinely missing.

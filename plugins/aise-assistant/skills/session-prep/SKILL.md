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
7. **(Optional) For Discovery and Kick-off sessions** — when requested by the user or proactively offered for these large-format sessions, generate an HTML visual session flow artifact via `show_widget`. Structure: numbered phases (Intro → Upfront Contract with 5 elements → Agenda Topics → Closing), each with time allocation, color-coded cards, and key pointers. This is a visual run sheet, not a replacement for the Notion prep.
8. Report back with links (Session page + KDD sub-page when created, visual artifact when generated) and any gaps or contradictions surfaced.

Do NOT ask the user for context that's retrievable. Search first, ask once if something is genuinely missing.

## Compound requests

Users often bundle related asks with `/session-prep`. Recognize these add-ons and route each to its handler in the same run — do not ask the user to invoke them separately.

| Phrase pattern | Handler |
|---|---|
| _"make me a task to [X]"_, _"add a task for [X]"_ | Create a Notion Task (PB-side, current user as Owner) linked to the Session via `Source Call`, following `context/notion-schema.md`. Slot in after Step 5. |
| _"read the gmail [agenda]"_, _"check what [stakeholder] sent"_ | In Step 2, specifically search Gmail for customer-proposed agendas sent in the last 7 days. In Step 4, give the customer's proposed agenda **priority weight** — it's the backbone of the suggested agenda, adapted with scorecard criteria, not replaced. |
| _"what should I do before"_, _"pre-call checklist"_ | In Step 7, include a **Pre-call checklist** section listing concrete actions for the user before the session (overdue tasks, space prep, pre-reads to send, Slack pings to make). |
| _"full session plan"_, _"minute-by-minute"_, _"run sheet"_ | In Step 7, include a **Session plan** — time blocks with what to say/do/decide in each block, plus contingencies (e.g. _"if Kate is absent, defer D7.2"_). |
| _"draft diagram"_, _"diagram in figma"_, _"visualize the integration"_ | After primary Notion writes land, spawn `diagram-builder` (per the context-management ordering in `agents/session-prepper.md`). If the sub-agent reports MCPs unavailable, finish Drive upload + Notion attach in the main conversation. |

**Context-management ordering for compound requests.** Write the primary deliverable (Session page + prep brief) first, then create secondary deliverables (Task, KDD sub-page), and only then spawn expensive sub-agents (diagram-builder). This prevents context-window compaction mid-run. See `agents/session-prepper.md` § Context management.

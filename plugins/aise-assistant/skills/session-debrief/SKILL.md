---
name: session-debrief
description: Run the full post-session workflow in one shot — transcript retrieval, session notes + status update in Notion, PB-side task creation, customer follow-up email draft (Gmail), internal Slack debrief draft, KDD sub-page (A-sessions), product feedback log, scorecard eval in chat, Active Package update.
---

Run the full post-session debrief workflow for.

Read the procedure in `agents/post-session-debrief.md` and execute it inline as the main assistant — do not try to spawn `post-session-debrief` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the session (calendar + Notion Sessions DB) and retrieve the transcript/notes via `session-summarizer`.
2. Write session notes, decisions, action items, and `Call Status = Delivered` to the Notion Session page; update the prior session's next steps.
3. Create Tasks in Notion for all PB-side commitments the user made (connected to session + customer). Customer-side actions stay in the notes and follow-up only.
4. Execute the customer follow-up email procedure documented in `agents/email-drafter.md` (read and run inline) — saved to Gmail Drafts, never sent. Notes if a Slack channel variant is also worth drafting.
5. Write an internal Slack debrief draft inline in chat (short, risks surfaced directly).
6. For A-sessions only: read `agents/kdd-builder.md` and execute its procedure inline to create the `KDDs — [Session ID] [Name]` sub-page on the Session page.
7. Surface a product feedback / feature request / bug log in chat (formatted for PM logging) — not written to Notion automatically.
8. Score the session against the relevant scorecard in chat with improvement tips — never written to Notion.
9. Append next-session planning notes to the Session page.
10. Update the Customer page if account-notable content surfaced; update the Active Package to mark the session done and refresh next steps in the engagement plan.

Do NOT ask the user for anything retrievable. Search first. Ask once if something is genuinely missing.

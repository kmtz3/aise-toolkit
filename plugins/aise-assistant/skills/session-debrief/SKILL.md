---
name: session-debrief
description: Run the full post-session workflow in one shot, entirely against Planhat — transcript retrieval, Conversation write (session notes, prep notes, Gong/duration), PB-side Tasks, Gmail follow-up draft, internal Slack debrief Task, Product Feedback Tasks, KDD Attachment (A-sessions only), a refreshed Company custom.Next Step, and scorecard eval in chat.
---

Run the full post-session debrief workflow for.

Read the procedure in `agents/post-session-debrief.md` and execute it inline as the main assistant — do not try to spawn `post-session-debrief` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the Planhat Company and the session's calendar event; retrieve the transcript/notes via `session-summarizer` (extraction only — no writes of its own). **If the transcript file exceeds 50K chars** (`read_document` returns "saved to file"), delegate extraction to a `general-purpose` sub-agent with the structured template in `agents/post-session-debrief.md` step 2a — never `Read` the file directly. **If the transcript is unavailable entirely** (typically a Zoom call where Gong hasn't indexed yet), follow the placeholder-debrief branch: gather Slack/Gmail signals, write placeholder notes flagged ⚠️, create a "re-debrief" Task due session-date + 5 business days, skip the email draft, and flag the session as `⚠️ Partial — transcript pending`.
2. Resolve the session's existing Planhat record via the GCal-event-id ladder (never a title search first) and write session notes, decisions, and action items to the Conversation `description` — creating it via the linked calendar-event Task when one exists.
3. Create Planhat Tasks for all PB-side commitments the user made (`companyId` required, priority/due-date/description-scaffold per `context/planhat-schema.md` § Task priority & description defaults). Customer-side actions stay in the Conversation description and follow-up only.
4. Execute the customer follow-up email procedure documented in `agents/email-drafter.md` (read and run inline) — saved to Gmail Drafts, never sent. Notes if a Slack channel variant is also worth drafting. **Skip if the transcript-unavailable branch is active.**
5. Write an internal Slack debrief draft and log it as a Planhat Task (`type: "Internal Alignment"`).
6. For A-sessions only: read `agents/kdd-builder.md` and execute its procedure inline — publishes the KDD to Google Drive and attaches it to the session's Planhat Conversation as an Attachment record.
7. Log product feedback, feature requests, and bugs as Planhat Tasks (`type: "Product Feedback"`) for later submission via `/log-feedback`.
8. Score the session against the relevant scorecard in chat with improvement tips — never written to Planhat. **Deferred if the transcript-unavailable branch is active.**
9. Refresh `custom.Next Step` on the Company record with the current state, what's being waited on, and what happens when it clears.

Do NOT ask the user for anything retrievable. Search first. Ask once if something is genuinely missing.

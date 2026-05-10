---
name: draft-email
description: Draft an email and save it as a Gmail draft (never sends — always drafts for review)
---

Draft email(s) for.

Read the procedure in `agents/email-drafter.md` and execute it inline as the main assistant — do not try to spawn `email-drafter` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The procedure pulls context across Glean / Notion / Gmail / Calendar / past chats so the draft is grounded in the actual session history, outstanding tasks, and prior commitments — not a generic sales-toned outreach.

## Hard rule — NEVER SEND

The drafted email is **always** saved to Gmail Drafts. Under no circumstance should the email be sent. No send tool. No "should I send?" question. Drafts folder, review, done.

If the user later says "send it", that's a separate explicit request.

## What the procedure must do

1. **Identify the source material** — which customer, which session / thread / task this email references, who the recipient is. Never guess recipients — look them up in the Notion Contacts relation or a recent Gmail thread.

2. **Pull context across connectors in parallel:**
   - **Notion** — customer page, most recent Sessions, open Tasks (PB-side and customer-side), specific session page being referenced.
   - **Gmail** — recent threads with the recipient; the specific thread if this is a reply. Capture the user's prior phrasing to match tone.
   - **Glean** — `gmail_search` for adjacent stakeholders, `search`/`chat` for Slack/Salesforce/Gong, `meeting_lookup` for recorded calls, `read_document` when a specific doc is referenced.
   - **Calendar** — confirm meeting date/time anchors.
   - **Past chats** — prior decisions and state. (Per-customer state lives in the 🧠 Working Notes toggle on the Active Package page in Notion; pull from there if relevant.)

   Before drafting a sentence, you should be able to state: what was agreed, what's outstanding, what this recipient owes or is owed, what tone the thread uses.

3. **Draft in the user's voice (per `about/voice.md`)** per `context/communication-style-guide.md`. Warm + direct, American English, bold labels over headers, bullets for lists, em-dashes sparingly, signature block `the user / AI Success Engineer (AISE) | Productboard`. For ongoing architecting / working cadence: reference *what we agreed* + *what's next* + the ask. Never frame as a first-touch sales reach-out.

4. **Don't invent** — dates, commitments, scope, names. If something load-bearing is missing, flag as `[FILL IN: ...]` and call it out in the report.

5. **Save as Gmail draft** with `create_draft` (both `body` and `htmlBody`). Return the draft ID.

6. **Multi-draft requests** — each draft gets its own context pass. Don't template across recipients.

7. **Report back in chat** for each draft:
   - Draft ID
   - Recipient, subject, cc (if any)
   - One-line angle (why this framing, tied to which session/thread)
   - `[FILL IN]` placeholders the user must resolve
   - Threading caveat if replying to an existing thread
   - Full body inline
   - Assumptions flagged (e.g. which "Richard" this is)

## What NOT to include in the draft body

- Internal-only context (commercial stance, credit/renewal detail, Ozzy-side tactics) unless the user explicitly asked.
- Speculation presented as fact.
- Sales-toned filler ("circling back", "touching base", "reach out to see if").
- Long sections — customer emails should scan in 30 seconds.

## Replying on an existing thread

If this is a reply, match subject exactly as `Re: <original subject>`. Flag that `create_draft` doesn't accept a thread ID — Gmail will attempt auto-threading but it's best-effort. If threading matters, the user may need to paste the body into a real Reply in Gmail.

## Updating a prior draft

There is no `update_draft` / `delete_draft` tool loaded. To correct an earlier draft, create a new one and flag the stale draft ID so the user can trash it manually.

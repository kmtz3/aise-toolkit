---
name: draft-email
description: Draft an email and save it as a Gmail draft (never sends — always drafts for review)
---

Draft email(s) for.

Read the procedure in `agents/email-drafter.md` and execute it inline as the main assistant — do not try to spawn `email-drafter` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The procedure pulls context across Planhat / Gmail / Slack / Gong / Calendar / past chats so the draft is grounded in the actual session history, outstanding tasks, and prior commitments — not a generic sales-toned outreach.

## Hard rule — NEVER SEND

The drafted email is **always** saved to Gmail Drafts. Under no circumstance should the email be sent. No send tool. No "should I send?" question. Drafts folder, review, done.

If the user later says "send it", that's a separate explicit request.

## What the procedure must do

1. **Identify the source material** — which customer, which session / thread / task this email references, who the recipient is. Never guess recipients — look them up in the Planhat `EndUser` records for the company or a recent Gmail thread.

2. **Pull context across connectors in parallel:**
   - **Planhat** — Company record, most recent Conversations (session/touchpoint history), open PB-side Tasks, the specific Conversation being referenced.
   - **Gmail** — recent threads with the recipient; the specific thread if this is a reply. Capture the user's prior phrasing to match tone.
   - **Planhat `email` Conversations** — threads with adjacent stakeholders or from teammates' mailboxes (`type: "email"`, see `context/project-instructions.md` §3).
   - **Slack / Gong** — `slack_search_public_and_private` in the account's channels (`custom.Slack ID`, `custom.External_Slack_Channel_ID`); recorded calls via the transcript lookup order (Planhat `👾 Gong Call` record, then Gong `ask_account`).
   - **Google Drive** — `search_files` / `read_file_content` when a specific doc is referenced. Salesforce detail comes from the Planhat Company record (SF-synced), Salesforce connector as fallback.
   - **Calendar** — confirm meeting date/time anchors.
   - **Past chats** — prior decisions and state. (Per-customer current state lives in Company `custom.Next Step`; pull from there if relevant.)

   Before drafting a sentence, you should be able to state: what was agreed, what's outstanding, what this recipient owes or is owed, what tone the thread uses.

3. **Fetch voice preferences (mandatory before drafting).** Resolve the user's Planhat User record — `list_model_records(MODEL:"User", FILTER:{"email[equal to]":"<user's email from session context>"}, SELECT:["firstName","lastName","email"])` → `planhat_user_id` (or the pre-resolved table in `context/planhat-schema.md` § Planhat User IDs) — then `get_model_record(MODEL:"User", OBJECT_ID:"{planhat_user_id}", SELECT:["custom.AISE Profile preferences"])`. Parse sign-off, em dashes, semicolons, English variant, casual register, specific patterns. Draft in the user's actual voice — never a generic tone. If the field is empty, fall back to `context/communication-style-guide.md` alone.

4. **Draft in the user's voice (per `custom.AISE Profile preferences` on the user's Planhat User record)** per `context/communication-style-guide.md`. Warm + direct, American English, bold labels over headers, bullets for lists, **never em dashes – use en dashes (–) everywhere a dash is needed**, and the signature block exactly as the profile defines it (for Klara Martinez: `Klara Martinez` / `Senior Solutions Architect | Productboard`). Take the job title from the Planhat profile, never from this file. For ongoing architecting / working cadence: reference *what we agreed* + *what's next* + the ask. Never frame as a first-touch sales reach-out.

5. **Don't invent** — dates, commitments, scope, names. If something load-bearing is missing, flag as `[FILL IN: ...]` and call it out in the report.

6. **Sent check, then check for an existing draft.** If the user already sent this email, don't draft it (§ Sent check).
   One draft per purpose – if a draft for the same customer purpose exists, update it instead of creating a second.
   See § Updating an existing draft.

   **Otherwise save as a Gmail draft** with `create_draft` (both `body` and `htmlBody`). Return the draft ID.
   **If this is a reply, pass `replyToMessageId`** – the ID of the message being replied to. This threads the draft
   correctly. See § Replying on an existing thread.

7. **Multi-draft requests** — each draft gets its own context pass. Don't template across recipients.

8. **Report back in chat** for each draft:
   - Draft ID
   - Recipient, subject, cc (if any)
   - One-line angle (why this framing, tied to which session/thread)
   - `[FILL IN]` placeholders the user must resolve
   - Threading confirmation if replying to an existing thread
   - Created, updated, or not drafted (already sent on <date>)
   - Duplicate drafts found for the user to discard
   - Full body inline
   - Assumptions flagged (e.g. which "Richard" this is)

## What NOT to include in the draft body

- Internal-only context (commercial stance, credit/renewal detail, Ozzy-side tactics) unless the user explicitly asked.
- Speculation presented as fact.
- Sales-toned filler ("circling back", "touching base", "reach out to see if").
- Long sections — customer emails should scan in 30 seconds.

## Replying on an existing thread

`create_draft` **does** accept `replyToMessageId`. Use it. A reply drafted without it lands as a detached standalone
draft that the user has to fix by hand.

- Get the message ID from `get_thread` – the `id` of the specific message being replied to, **not** the `threadId`
  and not the hash from a Gmail web URL.
- Pass `replyToMessageId: "<message id>"`, plus `subject` as `Re: <original subject>` (or `RE:` if the thread already
  uses that form), and set `to` / `cc` to match the thread.
- Confirm the response's `threadId` equals the original thread's ID. If it doesn't, the draft is detached –
  `delete_draft` the draft you just created (by draft ID) and redo.

## Sent check

Before drafting: `search_threads` with `in:sent to:@<customer-domain> after:<session or trigger date>`. If the user
already sent a message covering this session or topic, don't draft – report `already sent on <date>`. For a reply,
`get_thread` and stop if the newest message is from the user. Full rules in `agents/email-drafter.md` § 4.4.

## Updating an existing draft

**One draft per purpose.** The purpose key is customer + session (Planhat Conversation/Task ID or session date) for
follow-ups, customer + thread for replies, customer + topic for anything else. Before creating, check the draft ID
recorded on the session's Planhat record, then `list_drafts` (`view: "DRAFT_VIEW_FULL"`, `query: "to:@<customer-domain>"`
– the domain, not one address) and treat any draft for the same customer that references the same session date,
session title, Conversation ID or topic as the existing draft. Never match standalone drafts on `threadId` – it
changes on every update. If one exists, update it. Don't ask, don't skip, don't create a second. Full rules in
`agents/email-drafter.md` § 4.5.

`get_draft` it first and carry over anything the user added by hand – never silently drop a user edit.

**Update in place – standalone and replies alike.** `update_draft` with the existing `draftId`, passing `subject`,
`to`, `cc`, `body` and `htmlBody` together and re-sending any attachments (they are dropped otherwise). For a reply,
confirm the response `threadId` still equals the original thread (verified 2026-10-29: it does). Only if it doesn't:
`create_draft` with `replyToMessageId`, `delete_draft` the old draft ID, then `list_drafts` to confirm one remains.
Key on `draftId`, never `messageId` – message IDs change on every update.

**Record the draft ID** on the session's Planhat record afterwards (`custom.Follow-up Draft ID`, or the marker line in
`custom.Prep Notes` until that field exists) – `agents/email-drafter.md` § 5.

**Never retry `create_draft` blindly.** On an error or timeout, `list_drafts` for the purpose key first and use any
draft that now exists.

**Deleting.** Only `delete_draft` a draft this run created or is replacing. `trash_message` and `label_message` are not
permitted on this Gmail connection. Other duplicates are listed for the user to discard.


## Choosing the booking link

The user's Planhat User record carries six Calendly links. Pick by what the call actually is, and pull the live value
from the profile rather than pasting a remembered URL.

| Field | Use for |
|---|---|
| `custom.AISE Calendly Sync` | Scoping, ad-hoc syncs, technical Q&A, program check-ins. **The default when unsure.** |
| `custom.AISE Calendly Discovery` | Technical discovery |
| `custom.AISE Calendly Kickoff` | Program kickoff |
| `custom.AISE Calendly Architecting` | Architecting / A-sessions |
| `custom.AISE Calendly Enablement` | Training and enablement |
| `custom.AISE Calendly Spark` | Spark walkthroughs and enablement for accounts **not** in an active Spark motion |

**Check `context/initiatives/` before sending a Spark link.** If the account is in scope of an active initiative, the
initiative decides the shape of the call and therefore the link. Under `spark-in-practice.md`, an in-scope account gets
a scoping call first (Sync), then the working session – never a demo or a features walkthrough, so the Spark link is
the wrong one to send.

## After the email is sent

Drafting is not the end of the workflow, but **do not treat a draft as sent.** See `/inbox-triage` § 5 for the
post-send Planhat update, including the rule that `custom.Next Step` is written from the **sent** message body, not
from the draft.

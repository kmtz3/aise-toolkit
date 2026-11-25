---
name: draft-followup
description: Draft a customer follow-up (saved as a Gmail draft, or a Slack draft in the customer's external channel – never sent), prepare the later delivery message on a sent recap's thread (--delivery), or sweep every waiting customer draft so it reads right on the day it is sent and see what follow-ups are still owed (--sweep).
---

Follow up for: **$ARGUMENTS**

Three modes. Pick by flag; with no flag, draft one follow-up.

| Mode | Use when | Procedure |
|---|---|---|
| `/draft-followup <customer or session> [email\|slack]` | One follow-up for a session, thread or topic | `agents/email-drafter.md` |
| `/draft-followup <customer> --delivery [session]` | The recap went out and Productboard's promised items (or some of them) are ready | `agents/email-drafter.md`, delivery purpose (below) |
| `/draft-followup --sweep [--customer <name>] [--days N] [--dry-run]` | Daily, or whenever drafts have been waiting | `agents/followup-sweeper.md` |

Read the named procedure and execute it inline as the main assistant – custom agents in this plugin are procedure documents, not registered subagent types.

## Hard rules (all modes)

- **Never send.** Gmail drafts or Slack drafts only.
- **One draft per purpose.** Sent check, purpose-key lookup, update in place, record the draft ID – `agents/email-drafter.md` § 4.4–5. A re-run updates the existing draft; it never adds a second.
- **Voice first.** Fetch `custom.AISE Profile preferences` and `custom.AISE Identity` from the user's Planhat User record before writing a word (`context/project-instructions.md` § 6). Apply `context/communication-style-guide.md`, including § 3a (phrases to avoid).
- **Dated for the send day.** "today", "yesterday", "on Tuesday", "last Tuesday" or the date, and one plain apology once 2+ working days have passed – `agents/email-drafter.md` § 4.6.
- **Don't invent** commitments, dates or scope; use a short `[FILL IN: …]` instead. **Preserve the user's commitments** exactly as made.

## Default – one follow-up

Run `agents/email-drafter.md` with the customer and session/thread as the brief. It routes to the external Slack channel when the Company has one (§ 2.5), otherwise saves a Gmail draft – the draft is no longer returned inline only. `slack` / `email` in the arguments force the route. For a session recap, `/session-debrief` is the fuller path (notes, Tasks, Next Step); this mode is for the follow-up alone.

A recap never waits for deliverables (`agents/post-session-debrief.md` § 5-T): Productboard's open actions go in as dated commitments.

## `--delivery` – what was promised, now delivered

The message that follows a sent recap, as a **reply on the recap's thread**.

1. Find the sent recap for the session (`in:sent to:@<domain>` after the session date). No sent recap → stop and say so: the recap goes first.
2. Read its `Actions – Productboard` lines and the customer's replies since. Check each item against open Planhat Tasks and sent mail: done, partly done, still open.
3. Draft per `agents/email-drafter.md` with `replyToMessageId` = the user's sent recap. Purpose key: customer + session + `delivery`. Open with what is now ready, then the items with `✅` and their links or attachments, then the date for anything still open. No re-recap of the session.
4. Report which items it covers and which remain.

## `--sweep` – keep every waiting draft current

Runs `agents/followup-sweeper.md`: re-dates and tidies every customer draft in place, flags drafts already sent or obsolete for the user to discard, and lists sessions still owed a recap, promised deliverables, and customer questions waiting on the user. Suited to a morning routine (it is also step 4b of `/inbox-triage`).

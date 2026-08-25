---
name: inbox-triage
description: Sweep the inbox for threads actually awaiting your reply, batch-draft them in your voice with correct threading, then update each account's Planhat Next Step once you have sent. Triggers – /inbox-triage, 'draft replies to my inbox', 'what needs a reply', 'triage my inbox'.
---

Sweep the inbox, work out what genuinely needs a reply from the user, draft those replies, and close the loop in
Planhat after the user sends.

Read the procedure in `agents/inbox-triage.md` and execute it inline as the main assistant – do not try to spawn
`inbox-triage` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Hard rules

**Never send.** Every reply is saved to Gmail Drafts. The user reviews and sends by hand. If they later say "send it",
that is a separate explicit request.

**Never report a draft as sent.** Do not update Planhat, or tell the user an account has been contacted, on the
strength of a draft. Drafting and sending are different events and this skill tracks them separately.

**Write records from the sent message, not the draft.** The user edits substantially before sending – cutting
paragraphs, changing commitments, adding recipients. A Next Step written from the draft records things they never
said. Always re-read the sent body first.

## Shape of a run

1. **Sweep** – find threads awaiting a reply, filtering out calendar noise, notifications, and threads another
   Productboard owner is driving.
2. **Ground** – per thread, pull the account context needed to answer, including any active initiative in scope.
3. **Ask** – one batched round of genuine forks only. Never ask what is retrievable.
4. **Draft** – threaded replies via the `agents/email-drafter.md` voice and formatting rules.
5. **Close the loop** – after the user sends, reconcile what actually went out and update `custom.Next Step` on each
   sent account's Planhat Company record.

Step 5 usually happens in a later turn, when the user says they have sent. Re-run the reconciliation then rather than
assuming the drafts went out as written.

## What this is not

- Not `/draft-email`. That drafts one email to a named recipient from a brief. This starts from the inbox and decides
  what deserves a reply at all.
- Not `/session-debrief`. Post-session follow-ups belong there and carry session notes, tasks and scorecards with them.
- Not a mail reader. If the user asks what is in their inbox without asking for replies, answer that directly.

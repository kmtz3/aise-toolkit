---
name: draft-followup
description: Draft a follow-up email or Slack message
---

Draft a follow-up for.

1. Identify the source material — the session, thread, or notes this follow-up is about. If the session was summarized recently in this chat, use that. Otherwise pull it via Glean / Notion / Gmail / calendar (don't ask the user to paste).
2. Apply `context/communication-style-guide.md` — tone, structure, sign-off.
3. Default structure: Greeting → Context → What we covered / decisions → Next steps (owner + timing) → Ask or close → Sign-off.
4. Match the channel:
   - **Email** — full structure with subject line.
   - **Slack channel** — scannable, bold labels.
   - **Slack DM** — shorter, more casual.
5. **Don't invent** commitments, dates, or scope. If something's missing, flag a `[FILL IN]` placeholder rather than making it up.
6. **Preserve the user's commitments** — if she said "we'll have it by Friday", don't soften to "we'll aim to have it".
7. Offer variants only when there's a real strategic choice (e.g., "push for decision now" vs "give them a week").

Return the draft inline. If she wants to send it, don't auto-send without explicit instruction.

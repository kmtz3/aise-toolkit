---
name: draft-followup
description: Draft a follow-up email or Slack message
---

Draft a follow-up for.

1. Identify the source material — the session, thread, or notes this follow-up is about. If the session was summarized recently in this chat, use that. Otherwise pull it via Glean / Notion / Gmail / calendar (don't ask the user to paste).
2. **Fetch voice preferences (mandatory before drafting).** Resolve the user's Planhat User record — `list_model_records(MODEL:"User", FILTER:{"email[equal to]":"<user's email from session context>"}, SELECT:["firstName","lastName","email"])` → `planhat_user_id` (or the pre-resolved table in `context/planhat-schema.md` § Planhat User IDs) — then `get_model_record(MODEL:"User", OBJECT_ID:"{planhat_user_id}", SELECT:["custom.AISE Profile preferences"])`. Parse sign-off, em dashes, semicolons, English variant, casual register, specific patterns. Draft in the user's actual voice — never a generic tone. If the field is empty, fall back to `context/communication-style-guide.md` alone.
3. Apply `context/communication-style-guide.md` — tone, structure, sign-off — layered with the voice preferences from step 2.
4. Default structure: Greeting → one-line context → **What we covered** (2–3 tight bullets: decisions + key points) → **Next steps** (bullets: `[Owner] — [what] by [date or week]`) → close or ask (one line) → Sign-off.
5. Match the channel:
   - **Email** — full structure with subject line.
   - **Slack channel** — scannable, bold labels.
   - **Slack DM** — shorter, more casual.
6. **Don't invent** commitments, dates, or scope. If something's missing, flag a `[FILL IN]` placeholder rather than making it up.
7. **Preserve the user's commitments** — if she said "we'll have it by Friday", don't soften to "we'll aim to have it".
8. Offer variants only when there's a real strategic choice (e.g., "push for decision now" vs "give them a week").

Return the draft inline. If she wants to send it, don't auto-send without explicit instruction.

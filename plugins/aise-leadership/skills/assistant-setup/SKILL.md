---
name: assistant-setup
description: Onboard a new user (or re-onboard yourself) to this assistant. Resolves Notion identity, auto-discovers the AISE team roster, asks short HITL questions about voice + workspace preferences, and writes private Notion profile pages. Run on first install or when handing off to a teammate.
---

Set up the assistant for the current user.

Read the procedure in `agents/assistant-onboarding.md` and execute it **inline as the main assistant** — do not spawn as a subagent. Follow every step exactly. Do not skip Step 7b.

**Modes (mutually exclusive):**
- **Default** (no flag) — fill gaps only. Preserves existing values. Safe to re-run.
- **`--update`** — drift check. Re-resolves Notion identity and re-discovers team roster; walks each section for confirmation.
- **`--reset`** — wipe and restart from scratch.

**Modifier:** `--scrape-voice` — skip the opt-in and go straight to Gmail + Slack scraping.

Don't ask for retrievable values. Notion user ID, email, timezone — pull from the connected account.

---
name: assistant-setup
description: Onboard a new user (or re-onboard yourself) to this assistant. Resolves Planhat User identity, asks short HITL questions about voice + workspace preferences, checks for and migrates any prior profile data, and writes directly to `custom.AISE *` fields on your Planhat User record. Team roster is not part of setup — it's resolved live at query time. Run on first install or when handing off to a teammate.
---

Set up the assistant for the current user.

Read the procedure in `agents/assistant-onboarding.md` and execute it **inline as the main assistant** — do not spawn as a subagent. Follow every step exactly. Do not skip Step 7.

**Modes (mutually exclusive):**
- **Default** (no flag) — fill gaps only. Preserves existing values. Safe to re-run.
- **`--update`** — drift check. Re-resolves Planhat User identity; walks each section for confirmation.
- **`--reset`** — wipe and restart from scratch.

**Modifier:** `--scrape-voice` — skip the opt-in and go straight to Gmail + Slack scraping.

Don't ask for retrievable values. Planhat User ID, email, timezone — pull from the connected account.

**Where profile data lives and how it's written:** see `context/planhat-user-profile.md` — `custom.AISE Identity` and `custom.AISE Profile preferences` are shared with aise-assistant (same person, one identity, one voice); `custom.AISE Leadership Workspace` is this plugin's own field. Team roster has no stored field at all — it's resolved live from Planhat's native `managers`/`teams` fields by whichever agent needs it (`report-builder`, `notion-completion-fix`, etc.), per `context/planhat-user-profile.md` § Team roster.

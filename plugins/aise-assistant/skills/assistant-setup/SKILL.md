---
name: assistant-setup
description: Onboard a new user (or re-onboard yourself) to this assistant. Resolves Notion identity, asks short HITL questions about voice + workspace preferences, optionally scrapes recent Gmail and Slack to draft your voice profile, and writes the about/ folder. Run on first install of the plugin or when handing the assistant off to a teammate.
---

Set up the assistant for the current user.

Read the procedure in `agents/assistant-onboarding.md` and execute it **inline as the main assistant** — do not try to spawn `assistant-onboarding` as a subagent. Follow every step in that file exactly. Do not skip Step 7b.

**Modes (mutually exclusive):**
- **Default** (no flag) — fill gaps only. Preserves existing values; asks only about fields still set to `<TBD>`. Safe to re-run whenever.
- **`--update`** — drift check. Re-resolves Notion identity, then asks the user to confirm or update each section. Useful after a role change or team move.
- **`--reset`** — wipe everything. Deletes existing files and runs the full onboarding flow from scratch.

**Modifier (combinable with any mode):**
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail + Slack scraping for the voice draft.

**Don't ask for retrievable values.** Notion user ID, primary email, time zone — pull from the connected account, never ask.

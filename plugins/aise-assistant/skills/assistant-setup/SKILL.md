---
name: assistant-setup
description: Onboard a new user (or re-onboard yourself) to this assistant. Resolves Planhat User identity, asks short HITL questions about voice + workspace + Calendly preferences, optionally scrapes recent Gmail and Slack to draft your voice profile, checks for and migrates any prior profile data, and writes directly to `custom.AISE *` fields on your Planhat User record. Run on first install of the plugin or when handing the assistant off to a teammate.
---

Set up the assistant for the current user.

Read the procedure in `agents/assistant-onboarding.md` and execute it **inline as the main assistant** — do not try to spawn `assistant-onboarding` as a subagent. Follow every step in that file exactly. Do not skip Step 7b.

**Modes (mutually exclusive):**
- **Default** (no flag) — fill gaps only. Preserves existing values; asks only about fields still set to `<TBD>`. Safe to re-run whenever.
- **`--update`** — drift check. Re-resolves Planhat identity, then asks the user to confirm or update each section. Useful after a role change or team move.
- **`--reset`** — wipe everything and write fresh profile documents from scratch. (Prior Planhat documents aren't deleted — there's no `delete_document` tool via this connector — they just become inert history once superseded.)

**Modifier (combinable with any mode):**
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail + Slack scraping for the voice draft.

**Don't ask for retrievable values.** Planhat User ID, primary email, time zone — pull from the connected account, never ask.

**Where profile data lives and how it's written:** see `context/planhat-user-profile.md` — profile values live on `custom.AISE *` fields directly on the user's Planhat User record, updated in place via `update_model_record` (no versioning). That file also covers the migration check that backfills from legacy Notion pages when a field is empty.

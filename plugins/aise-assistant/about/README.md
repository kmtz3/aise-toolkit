# `about/` — Per-user profile

This folder holds **templates only**. The actual personal files written by `/assistant-setup` live in the plugin's persistent data directory — **not** inside the plugin itself.

The rest of the assistant (agents, commands, schemas, templates, methodology) is universal — anyone in the same role can use it as-is.

## Where personal files actually live

Personal files are stored at `${CLAUDE_PLUGIN_DATA}/about/` (set by the plugin system at runtime). This path persists across plugin updates. **It is deleted automatically when you uninstall the plugin.** Re-run `/assistant-setup` after a full reinstall or on a new machine.

Run `/assistant-setup` to populate it. The directory is created automatically on first write.

## Files

| File | Holds |
|---|---|
| `identity.md` | Name (incl. accent variants to strip), email, Notion user ID, role, team, time zone |
| `voice.md` | Personal communication style: sign-offs, formatting quirks, language rules, casual register |
| `workspace.md` | Workspace specifics: Slack channels, internal coordinators, conferencing prefs, AE/AISE relationships |
| `tracker-memory.md` | Cross-customer observations: patterns spanning ≥2 customers, recurring risks, success moves. Written by `context-keeper`; seeded empty by `/assistant-setup`. |

Universal communication methodology (PB-AISE comms patterns, customer-vs-internal tone, structure templates) lives in [`context/communication-style-guide.md`](../context/communication-style-guide.md). Your `voice.md` overlays personal preferences on top.

## How agents use these files

Every agent that needs a personal value (e.g. your Notion user ID for filtering queries) reads `${CLAUDE_PLUGIN_DATA}/about/identity.md` at the start of its run. Don't hardcode personal values in agent specs — always reference these files.

For voice/style decisions, agents read `${CLAUDE_PLUGIN_DATA}/about/voice.md` alongside `context/communication-style-guide.md` and treat `voice.md` as the override.

## Populating this folder

**First time?** Run `/assistant-setup`. It'll:
1. Auto-resolve your Notion user ID via the connector.
2. Ask you a short series of questions about identity, voice preferences, and workspace.
3. Optionally scrape recent Gmail and Slack to draft your `voice.md` from how you actually write (distinguishing internal vs client-facing tone).
4. Write all three files to `${CLAUDE_PLUGIN_DATA}/about/` with your real values — no manual file copy needed.

**Modes:**
- **Default** (no flag) — fill gaps only. Preserves existing values, only asks about fields still set to `<TBD>`.
- **`--update`** — drift check. Re-resolves Notion identity (catches user ID changes, role changes), surfaces any fields that look stale, asks you to confirm or update each one.
- **`--reset`** — wipe everything. Deletes `identity.md`, `voice.md`, `workspace.md` from `${CLAUDE_PLUGIN_DATA}/about/` and re-runs the full onboarding flow from scratch. Use when handing off the assistant to a teammate, or starting clean after a major role/preference shift.
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail+Slack scraping for the voice draft.

**Continuous updates.** The `context-keeper` agent also proposes updates here whenever you correct it on a personal preference (style nit, sign-off change, voice rule).

## Templates

The `about/templates/` subfolder holds the placeholder versions that ship with the plugin (`identity.md.template`, `voice.md.template`, `workspace.md.template`). Don't edit these unless you're changing the plugin's onboarding scaffold for everyone — they're plugin-owned and replaced on upgrade. Your personal files at `${CLAUDE_PLUGIN_DATA}/about/` are never touched by an upgrade.

## Migration from older installs

If you installed this plugin before v1.1.0, your personal files may be at one of these legacy paths:

- `~/Library/Application Support/aise-assistant/about/` (v1.0.9)
- `~/.claude/aise-assistant/about/` (pre-v1.0.9)

Running `/assistant-setup` or `./scripts/upgrade.sh` will automatically detect and migrate files from those paths to `${CLAUDE_PLUGIN_DATA}/about/`.

## Privacy note

These files contain personal info. They should NOT be committed to a shared plugin repo or shipped to teammates. The plugin export process strips this folder and ships with empty placeholder templates instead.

# `about/` — Per-user profile (legacy — superseded by Planhat)

This folder holds **templates only**, kept for historical reference. `/assistant-setup` no longer writes local files here (it stopped writing local files when personal profiles moved to Notion, and now writes to **Planhat** instead — see `context/planhat-user-profile.md`). The rest of the assistant (agents, commands, schemas, templates, methodology) is universal — anyone in the same role can use it as-is.

## Where personal files actually live now

Personal profile data is stored in private **Planhat documents**, owned by the user, `IS_PUBLIC: false`:

| Document | Holds |
|---|---|
| `AISE Profile — Identity — {display_name}` | Name (incl. accent variants to strip), email, Planhat User ID, role, team, time zone |
| `AISE Profile — Preferences — {display_name}` | Voice section (sign-offs, formatting quirks, language rules, casual register) + Workspace section (Slack channels, internal coordinators, conferencing prefs) |
| `AISE Profile — Voice Scrape Samples — {display_name}` | Raw scrape samples, only created if voice scraping ran |

Full schema, naming convention, and the read/write procedure (documents are versioned by re-creation, not edited in place — the Planhat MCP connector exposes no `update_document`/`delete_document` tool) are in [`context/planhat-user-profile.md`](../context/planhat-user-profile.md).

`tracker-memory.md` (cross-customer observations, written by `context-keeper`) is a separate concept and currently still lives as a Notion sub-page under the legacy `AISE Identity` Notion page — not yet migrated.

Run `/assistant-setup` to populate your Planhat profile documents. They're created automatically on first write.

## How agents use this

Every agent that needs a personal value (e.g. the user's display name, voice preferences) should resolve it via `search_documents` + `get_document` against the Planhat titles above — see the Path resolver in the plugin's `CLAUDE.md`. Don't hardcode personal values in agent specs — always reference the live Planhat documents.

For voice/style decisions, agents read `AISE Profile — Preferences` (Voice section) alongside `context/communication-style-guide.md` and treat the Planhat document as the override.

> **Migration note:** most agents/skills in this plugin were written against the earlier Notion-based profile (`AISE Identity`/`AISE Assistant Preferences` Notion pages) and haven't been swept to read from Planhat yet. `/assistant-setup` itself is fully migrated. See the ⚠️ note in `CLAUDE.md` § Path resolver.

## Populating your profile

**First time?** Run `/assistant-setup`. It'll:
1. Auto-resolve your Planhat User identity via the connector.
2. Ask you a short series of questions about identity, voice preferences, and workspace.
3. Optionally scrape recent Gmail and Slack to draft your voice profile from how you actually write (distinguishing internal vs client-facing tone).
4. Write your Identity and Preferences documents to Planhat with your real values — no manual file copy needed.

**Modes:**
- **Default** (no flag) — fill gaps only. Preserves existing values, only asks about fields still set to `<TBD>`.
- **`--update`** — drift check. Re-resolves Planhat identity (catches User ID changes, role changes), surfaces any fields that look stale, asks you to confirm or update each one.
- **`--reset`** — wipe everything and write brand-new profile documents from scratch. Old documents aren't deleted (no `delete_document` tool) — they become inert history. Use when handing off the assistant to a teammate, or starting clean after a major role/preference shift.
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail+Slack scraping for the voice draft.

**Continuous updates.** The `context-keeper` agent also proposes updates here whenever you correct it on a personal preference (style nit, sign-off change, voice rule) — it writes a fresh Planhat document version, same as a manual `/assistant-setup --update` run.

## Templates

The `about/templates/` subfolder holds placeholder files (`identity.md.template`, `voice.md.template`) from the local-file era. They're no longer written to by onboarding but are kept as a readable reference for what fields the Planhat documents cover — see `context/planhat-user-profile.md` for the current field list and content format.

## Privacy note

Profile documents contain personal info. They're private Planhat documents (`IS_PUBLIC: false`), scoped to the owning user — never share them across users, and never commit personal values into this plugin's source tree.

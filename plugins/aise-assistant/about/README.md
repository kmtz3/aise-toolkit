# `about/` — Per-user profile (legacy — superseded by Planhat)

This folder holds **templates only**, kept for historical reference. `/assistant-setup` no longer writes local files here, and no longer writes Planhat Documents either — personal profile data is stored directly on `custom.AISE *` fields on the user's own **Planhat User record**. The rest of the assistant (agents, commands, schemas, templates, methodology) is universal — anyone in the same role can use it as-is.

## Where personal data actually lives now

Personal profile data is stored directly on `custom.AISE *` fields on the user's Planhat **User** record — not as a separate Document, and not in Notion.

| Field | Holds |
|---|---|
| `custom.AISE Identity` | Name (incl. accent variants to strip), email, Planhat User ID, role, team, time zone |
| `custom.AISE Profile preferences` | Sign-offs, em-dash rule, semicolons, English variant, casual register, forbidden filler words |
| `custom.AISE Workspace` | Conferencing tool, Slack channel patterns, internal coordinators |
| `custom.AISE Calendly Sync` / `Architecting` / `Enablement` / `Discovery` / `Kickoff` / `Spark` | Booking links per session type |
| `custom.AISE Tracker Memory` | Cross-customer observations, written by `context-keeper` |

Full field map and the read/write procedure `/assistant-setup` uses are in [`context/planhat-user-profile.md`](../context/planhat-user-profile.md).

Run `/assistant-setup` to populate your profile fields. Since they're plain User-record fields (not Documents), each write replaces the field's content directly — no versioning-by-recreation, no `search_documents`/`get_document` step.

## How agents use this

Every agent that needs a personal value (e.g. the user's display name, voice preferences) should resolve it via `list_model_records` + `get_model_record` against the `custom.AISE *` fields above — see the Path resolver in the plugin's `CLAUDE.md`. Don't hardcode personal values in agent specs — always reference the live Planhat User record.

For voice/style decisions, agents read `custom.AISE Profile preferences` alongside `context/communication-style-guide.md` and treat the Planhat field as the override.

> **Migration note:** most agents/skills in this plugin were written against an earlier profile storage layer (first Notion pages, then Planhat Documents) and haven't all been swept to read from the `custom.AISE *` User fields yet. `/assistant-setup` itself is fully migrated. See the ⚠️ note in `CLAUDE.md` § Path resolver.

## Populating your profile

**First time?** Run `/assistant-setup`. It'll:
1. Auto-resolve your Planhat User identity via the connector.
2. Ask you a short series of questions about identity, voice preferences, and workspace.
3. Optionally scrape recent Gmail and Slack to draft your voice profile from how you actually write (distinguishing internal vs client-facing tone).
4. Write your Identity and Preferences directly to `custom.AISE *` fields on your Planhat User record — no manual file copy needed.

**Modes:**
- **Default** (no flag) — fill gaps only. Preserves existing values, only asks about fields still set to `<TBD>`.
- **`--update`** — drift check. Re-resolves Planhat identity (catches User ID changes, role changes), surfaces any fields that look stale, asks you to confirm or update each one.
- **`--reset`** — wipe every `custom.AISE *` field and write brand-new values from scratch. Since these are User-record fields, the reset genuinely replaces the old values — there's no "inert history" to worry about. Use when handing off the assistant to a teammate, or starting clean after a major role/preference shift.
- **`--scrape-voice`** — skip the opt-in question and go straight to Gmail+Slack scraping for the voice draft.

**Continuous updates.** The `context-keeper` agent also proposes updates here whenever you correct it on a personal preference (style nit, sign-off change, voice rule) — it writes directly to the relevant `custom.AISE *` field, same as a manual `/assistant-setup --update` run.

## Templates

The `about/templates/` subfolder holds placeholder files (`identity.md.template`, `voice.md.template`) from the local-file era. They're no longer written to by onboarding but are kept as a readable reference for what fields the profile covers — see `context/planhat-user-profile.md` for the current field list and content format.

## Privacy note

Profile data lives on the user's own Planhat User record, scoped to that user — never copy personal values across users, and never commit personal values into this plugin's source tree.

# Planhat User Profile Fields — Schema & Conventions

> **Status:** Active. This is where `/assistant-setup` stores each AISE's personal profile (identity, voice, workspace preferences, Calendly links). Unrelated to the Notion↔Planhat *customer data* migration in `planhat-schema.md` — there is no Notion source of truth for this profile; the Planhat `User` record is the only store.

---

## Where profile data lives

Personal profile data lives directly on the Planhat **`User`** record (model `User`), as `custom.*` fields. `update_model_record` edits these fields in place; there is no versioning, no append-only history, and no need to resolve "the newest one" — the current value on the record is always the current value.

The only prior store for this data is the legacy Notion pages — see **Migrating stale data** below.

---

## Field map

All fields live on the `User` model, prefixed `AISE `. Resolve them via `get_model_action_parameters(MODEL:"User")` if this table ever looks stale.

| Field ID | Type | Content |
|---|---|---|
| `custom.AISE Identity` | rich text | Preferred name, display name, accent variants, role, team, manager, time zone, working hours, email |
| `custom.AISE Profile preferences` | rich text | Voice section — sign-off, em dashes, semicolons, English variant, casual register, specific patterns |
| `custom.AISE Workspace` | rich text | Workspace section — conferencing tool, internal Slack channel, manager (Calendly links are NOT stored here — see below) |
| `custom.AISE Voice Scrape Samples` | rich text | Distilled patterns from Gmail/Slack scraping (Step 5 of onboarding) — only populated when scraping ran |
| `custom.AISE Tracker Memory` | rich text | Cross-customer patterns/learnings the `context-keeper` agent logs — one entry per pattern (Pattern / Source / Action). Append-only in practice, unlike the other fields above which are wholesale-replaced. Shared across both plugins — same person, same accumulated pattern log regardless of which plugin is logging it. |
| `custom.AISE Leadership Workspace` | rich text | **aise-leadership only.** Notion report-templates DB ID/URL, per-cadence output format + template names, Gong session-title keywords, Slack channels (AISE/leadership/CS org), internal coordinators (manager, commercial partner, PS Ops contact). Distinct from `custom.AISE Workspace` (aise-assistant's conferencing/Slack/manager fields) because the content genuinely doesn't overlap. |
| `custom.AISE Calendly Sync` | url | Office Hours / ad-hoc sync booking link |
| `custom.AISE Calendly Architecting` | url | Architecting session booking link |
| `custom.AISE Calendly Enablement` | url | Enablement / training session booking link |
| `custom.AISE Calendly Spark` | url | Spark demo / adoption program booking link — also read by `/spark-onepager` |
| `custom.AISE Calendly Discovery` | url | Discovery session booking link |
| `custom.AISE Calendly Kickoff` | url | Kickoff session booking link |

**Rich-text fields require HTML** — same as Company/Conversation rich-text fields (see `planhat-schema.md`). This corrects an earlier version of this doc that claimed plain-text `Key: value` lines were sufficient; they are not. Planhat's `rich text` fieldType renders the stored value as HTML, and a bare `\n` is silently stripped rather than preserved as a line break — writing plain text collapses every line into one run-on string on read-back (confirmed live, 2026-08-18: a write using bare newlines came back as `"Preferred name: KlaraDisplay name: Klara Martinez..."` with no separators at all).

Use `<p>Key: value</p>` per line, `<p><strong>Section</strong></p>` for section headers, and `<ul class="ph-editor__bullet-list"><li class="ph-editor__list-item"><p>...</p></li></ul>` for bullets — the same convention documented for Conversation/Task `custom.Prep Notes` below and specified in full in `context/planhat-schema.md` § Rich Text Field Formatting. Bare `<ul><li>` without the classes and inner `<p>` renders mangled. When parsing a field back out, strip HTML tags first, then split on `</p>` (or list items) to recover one logical line per `Key: value` pair — do not split on `\n`, since none will be present.

**Shared vs plugin-specific:** `custom.AISE Identity`, `custom.AISE Profile preferences`, `custom.AISE Voice Scrape Samples`, and `custom.AISE Tracker Memory` are shared — one person has one identity, one voice, one pattern log, regardless of which plugin is reading or writing. `custom.AISE Workspace` (aise-assistant) and `custom.AISE Leadership Workspace` (aise-leadership) are plugin-specific because their content genuinely doesn't overlap. Calendly fields are aise-assistant-only.

## Team roster (aise-leadership) — live query, not a stored field

There is no `custom.AISE Leadership Team Roster` field, and none is planned. Team membership is resolved live at query time instead of cached, using fields already native to the Planhat `User` model:

1. Resolve the leader's `planhat_user_id` (see below).
2. Direct reports: `list_model_records(MODEL:"User", FILTER:{"managers[contains]":"{planhat_user_id}"}, SELECT:["firstName","lastName","email"])`.
3. If that returns nothing (the `managers` hierarchy isn't populated for this org), fall back to team membership: `list_model_records(MODEL:"User", FILTER:{"teams[contains]":"6a479684b7134724b8201b64"}, SELECT:["firstName","lastName","email"])` (team ID for "AI Success Engineers" — see `planhat-schema.md` § Planhat User IDs / team options) — excluding the leader's own record.
4. Neither of these returns a **Notion** UUID — only Planhat identifiers. Any Notion-scoped query (filtering `Customer.Owner`, etc.) still needs a live `notion-get-users` lookup matched by email for each teammate resolved above.

This trades the old HITL-curated roster (which let a leader mark someone inactive or add an exception manually) for always-current data. If that curation is ever missed, revisit — but the working assumption is that `managers`/`teams` in Planhat is kept accurate as the org's system of record, so a shadow copy shouldn't be needed.

---

## Read procedure

```
get_model_record(MODEL: "User", OBJECT_ID: "{planhat_user_id}",
  SELECT: ["custom.AISE Identity", "custom.AISE Profile preferences", "custom.AISE Workspace",
           "custom.AISE Voice Scrape Samples", "custom.AISE Calendly Sync", "custom.AISE Calendly Architecting",
           "custom.AISE Calendly Enablement", "custom.AISE Calendly Spark", "custom.AISE Calendly Discovery",
           "custom.AISE Calendly Kickoff"])
```

(Or `list_model_records` with the same `FILTER`/`SELECT` if you don't have `planhat_user_id` yet — see below.)

Parse each rich-text field's `Key: value` lines back out — strip HTML tags first (`<p>`, `<li>`, `<strong>`, etc.), then treat each `</p>` or `</li>` boundary as one logical line. A field that's empty/absent means that section has never been set — treat it like the old `<TBD>` placeholder, but **before** asking the user, run the migration check below.

## Write procedure

```
update_model_record(MODEL: "User", OBJECT_ID: "{planhat_user_id}",
  PARAMETERS: { "custom.AISE Identity": "<full content>", "custom.AISE Calendly Kickoff": "<url>", ... })
```

Always write the **full** content for any rich-text field you're touching (existing untouched key-lines + new/changed ones) — `update_model_record` replaces the field value, it doesn't merge line-by-line. URL fields are single values, just pass the new URL directly. Only include the fields that actually changed in `PARAMETERS` — untouched fields don't need to be resent.

No versioning step, no "old version stays as inert history" messaging — the record is simply updated.

**Exception — `custom.AISE Tracker Memory` is append-only in practice.** Unlike the other fields (wholesale replace on each onboarding run), `context-keeper` appends one new entry per cross-customer pattern over time: read the current value, append the new entry, write the full field back. Since Planhat rich-text fields don't have a documented growth ceiling but aren't built for unbounded append either, periodically review and prune superseded/stale entries rather than letting it grow forever — `context-keeper` should flag this if the field gets unwieldy (e.g. clearly outdated entries, or the same pattern logged more than once).

## Resolving the Planhat User ID

`list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<user's email>"}, SELECT: ["firstName", "lastName", "email"])` → capture `_id`. The current AISE team's IDs are also pre-resolved in `planhat-schema.md` § Planhat User IDs (e.g. Klara Martinez → `6a44ef76c9aade50502936d5`) — check there first to skip a lookup.

---

## Migrating stale data (run once per field, only when that field is empty)

When a `custom.AISE *` field comes back empty on the read above, don't go straight to asking the user — check whether the value already exists on the one prior store (the legacy Notion pages), and offer it as a pre-filled default instead of asking cold.

**Legacy Notion pages** (pre-Planhat era): `AISE Identity — {display_name}` / `AISE Assistant Preferences — {display_name}` (or `AISE Leadership Preferences — {display_name}` in aise-leadership) Notion pages, if they still exist. If none found, the field is genuinely unset — ask fresh.

When something is found, surface it in the HITL form as a pre-filled default ("Found this in your old Notion profile page — use it? [value]") rather than writing it silently. The user confirms or overrides before it's written to the `User` record.

Calendly links have no historical equivalent for Discovery/Kickoff/Spark (those are new fields) — always ask fresh for those three unless the general "any other Calendly link" free-text field from the old Workspace section happens to contain one, in which case surface it as a candidate default.

---

## Auto-resolve procedure for consuming agents (instead of a hard stop)

The section above is `/assistant-setup`'s own migration check, run during a full onboarding session. This section is for every **other** agent that needs a `custom.AISE *` field mid-task and finds it empty. Don't just print "profile not found — run `/assistant-setup`" and stop. Do this instead, in order:

1. **Try the Planhat read.** If populated, done — proceed with the task.
2. **If empty, run the migration check for the specific field(s) this agent needs** (not the whole profile) — legacy Notion pages (`AISE Identity —`, `AISE Assistant Preferences —` / `AISE Leadership Preferences —`).
3. **If found in step 2, auto-migrate it — no HITL gate.** This is a like-for-like backfill of data that already exists somewhere else in the user's own systems, not new data entry, so it doesn't need the confirm-every-field friction that full onboarding uses (that friction exists there because onboarding is asking the user to actively review a wide set of values in one sitting). Write it straight to the `User` record via `update_model_record`, note inline in the agent's output — e.g. "Backfilled your identity from an existing Notion page — review anytime via `/assistant-setup --update`." — then proceed with the task using the now-populated value.
4. **If step 2 finds nothing either** (genuinely first-time user — no Planhat data, no legacy Notion page): don't hand the user a "go run this yourself" message. Read `agents/assistant-onboarding.md` and execute its full procedure inline right now, per the same "agents are procedure documents, run them inline" convention used everywhere else in this plugin, then resume the original task once onboarding completes. Onboarding's default mode only asks about fields that are actually empty, so this doesn't force a redundant re-ask of anything that already exists.

**Applies to:** any agent that would otherwise hard-stop on a missing `custom.AISE Identity` (or other core field) — `daily-brief`, `notion-completion-fix`, `bulk-account-setup`, `session-backfill`, `bulk-prep-week`, `notion-ask`, `notion-integrity-check`, `notion-writer`, `aise-context`, `log-feedback`, and the aise-leadership equivalents (`report-builder`, `notion-completion-fix`, etc.).

**Agents with an existing softer fallback** (`email-drafter`, `draft-followup`, `draft-email`, and similar — which already degrade to `context/communication-style-guide.md` with an inline warning rather than stopping) should still run steps 2–3 (auto-migrate if found) before falling back, but can keep their existing graceful-degrade behavior for step 4 instead of running full onboarding — triggering a multi-question onboarding flow mid-draft is heavier than a single email needs. Full onboarding is the right response for the hard-stop tier, not for a one-off drafting task.

---

## Content format (rich-text fields)

Example — `custom.AISE Identity`:
```html
<p>Preferred name: Klara</p><p>Display name: Klara Martinez</p><p>Timezone: Europe/Prague</p><p>Working hours: 09:00–18:00 CET</p><p>Role: AI Success Engineer</p><p>Team: AISE</p><p>Manager: <value></p><p>Email: klara.martinez@productboard.com</p><p>Accent variants: none</p>
```

Example — `custom.AISE Profile preferences`:
```html
<p>Sign-off: Best,</p><p>Em dashes: OK</p><p>Semicolons: Avoid</p><p>English variant: US</p><p>Casual register: Mild only</p>
```

Example — `custom.AISE Workspace`:
```html
<p>Conferencing tool: Zoom</p><p>Slack AISE channel: <value></p><p>Manager: <value></p>
```

Calendly links are separate `url` fields, not embedded in the Workspace rich text — write each directly to its own field.

---

## Migration status

As of 2026-08-16, the downstream-readers sweep is complete in both plugins — every agent/skill that needs identity, voice, workspace, or Tracker Memory reads from `custom.AISE *` Planhat fields, not the old Notion pages. The only intentional remaining references to the legacy Notion page names are: (a) the migration-check fallback logic in this file and in `assistant-onboarding.md`, and (b) the Auto-resolve procedure above. If you find a file reading personal profile data from Notion as its *primary* path (not a migration fallback), that's drift — fix it to match this file.

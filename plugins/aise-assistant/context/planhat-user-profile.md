# Planhat User Profile Documents — Schema & Conventions

> **Status:** Active. This is where `/assistant-setup` stores each AISE's personal profile (identity, voice, workspace preferences). Unrelated to the Notion↔Planhat *customer data* migration in `planhat-schema.md` — there is no Notion source for these documents; Planhat is the only store.

---

## Why Documents, and why versioned

The Planhat MCP connector exposes `create_document`, `get_document`, and `search_documents` — but **no `update_document` or `delete_document` tool** (confirmed live, 2026-08-07; a Planhat-side "document update" permission grant did not add the tool — availability is fixed by the MCP server's exposed toolset, not by API scopes). Profile documents are therefore **append-only**: every `/assistant-setup` run that changes anything creates a brand-new Document; nothing is edited in place.

There is also no folder/parent parameter on `create_document` (confirmed live — the `path` field on a created document comes back empty regardless). A stable name prefix (`AISE Profile — `) stands in for a folder: it groups every AISE's profile documents under one searchable prefix in lieu of real Planhat folder support via this connector.

**If this changes** (an `update_document` tool appears after a future connector reconnect), simplify: read-modify-write in place instead of the versioning dance below, and backfill by keeping only the newest document per title.

---

## Document naming

One document per section, per user, always the same title (no version number in the title itself — recency is resolved by `createdAt`, not by name):

| Title | Content |
|---|---|
| `AISE Profile — Identity — {display_name}` | Preferred name, display name, accent variants, role, team, manager, time zone, working hours, email |
| `AISE Profile — Preferences — {display_name}` | Voice section + Workspace section (mirrors the old Notion "Assistant Preferences" page) |
| `AISE Profile — Voice Scrape Samples — {display_name}` | Only created when Gmail/Slack scraping ran (Step 5 of onboarding) |

All three: `IS_PUBLIC: false`, `OWNER: <the user's own Planhat User _id>`. Never share these across users.

---

## Read procedure (resolve the *current* profile)

1. `search_documents(QUERY: "AISE Profile — Identity — {display_name}")`
2. Filter results to `name` **exactly** matching the expected title (search is fuzzy full-text — don't trust ranking alone).
3. If more than one match, take the one with the **maximum `createdAt`** — that's the current version. Older matches are stale history; ignore them, don't merge them.
4. `get_document(DOCUMENT_ID: "<_id>", FORMAT: "text")` → parse fields from `content`.
5. Repeat for `AISE Profile — Preferences — {display_name}`.
6. If `search_documents` returns nothing for a title, the profile section hasn't been created yet — treat all its fields as unset (equivalent to old Notion `<TBD>`).

## Write procedure (create a new version)

1. Resolve the current version first (read procedure above) — you need the existing values to merge in default (gap-fill) mode.
2. Build the **full** content block (existing untouched fields + new/changed fields) — never write a partial diff, since there's nothing to patch against.
3. `create_document(NAME: "<same exact title as always>", CONTENT: "<full content>", OWNER: "<planhat user id>", IS_PUBLIC: false)`.
4. Do not attempt to remove the previous version — there is no `delete_document` tool. Mention in the completion message that old versions remain in Planhat and can be removed manually via the Planhat UI if the user wants to tidy up.

## Resolving the Planhat User ID (`OWNER`)

`list_model_records(MODEL: "User", FILTER: {"email[equal to]": "<user's email>"}, SELECT: ["firstName", "lastName", "email"])` → capture `_id`. The current AISE team's IDs are also pre-resolved in `planhat-schema.md` § Planhat User IDs (e.g. Klara Martinez → `6a44ef76c9aade50502936d5`) — check there first to skip a lookup.

## Content format

Plain text, same `Key: value` / `## Section` shape the old Notion pages used — `get_document(FORMAT: "text")` returns this cleanly, and it's simple to parse back out on the next read. No need for HTML/Markdown structure here (unlike Planhat rich-text `custom.*` fields on Company/Conversation, which do require HTML — see `planhat-schema.md`).

Example — Identity document content:
```
Preferred name: Klara
Display name: Klara Martinez
Timezone: Europe/Prague
Working hours: 09:00–18:00 CET
Role: AI Success Engineer
Team: AISE
Manager: <value>
Email: klara.martinez@productboard.com
Accent variants: none
```

Example — Preferences document content:
```
## Voice
Sign-off: Best,
Em dashes: OK
Semicolons: Avoid
English variant: US
Casual register: Mild only

## Workspace
Conferencing tool: Zoom
Calendly — ad-hoc: <url or "not set">
Calendly — architecting: <url or "not set">
Calendly — training: <url or "not set">
Slack AISE channel: <value>
Manager: <value>
```

---

## Known limitation — downstream readers not yet migrated

As of this writing, most other agents/skills in this plugin still read personal voice/identity from the Notion `AISE Identity — {display_name}` / `AISE Assistant Preferences — {display_name}` pages (see `CLAUDE.md` § Per-user context, and every agent file that says "resolve the user's Notion identity page"). `/assistant-setup` and its `assistant-onboarding` agent write to Planhat now; the read side across the rest of the plugin has not been swept yet. Until that sweep happens, personalization elsewhere in the plugin will not see values set via the Planhat-based onboarding. Treat this file (and `CLAUDE.md`'s resolver block) as the target state to migrate the rest of the plugin toward.

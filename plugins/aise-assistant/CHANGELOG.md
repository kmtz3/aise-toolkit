# Changelog

All notable changes to aise-assistant are documented here.
Format: `## [version] — YYYY-MM-DD` followed by bullet points grouped by type.

---

## [2.38.0] — 2026-08-21

### Added
- `context/initiatives/` — new folder for time-boxed GTM and adoption motions. These arrive with their own account list, gates, meeting shape, and success measure, and they contradict the permanent workflow on purpose; keeping each as a self-contained file means the contradictions do not outlive the motion and an ended motion can be archived in one move. `README.md` defines the file contract (status block, scoped accounts, mandatory § Assistant rules), the precedence model (an active initiative wins over `project-instructions.md` for the parts it explicitly covers, defaults apply to everything else), the "never resolve a conflict silently" rule, and the `Last synced from source` staleness convention.
- `context/initiatives/spark-in-practice.md` — the Ignition Meetings motion (active from 2026-08-11, expected ≤ 3 months), summarized from Boge's [PB operating doc](https://pb.productboard.com/document/MTpQcm9kdWN0RG9jdW1lbnRCb2FyZDozZWUzMjZjMi1jMjI4LTRjOGMtYmY0OS01ZGU5M2QxYmJiNzE=). Covers: the one-job-on-their-data premise and the return-rate problem behind it; the hard separation from the Sept 1 Ignite conversion push; the T1–T6 tiering with Klara's 30 scoped accounts listed by tier, AE, ARR, health and Spark makers/wk; the three booking gates; the mandatory calendar naming key; the five AISE pre-work items including the remote-access path and its undocumented-scope caveat; the 5/5/5/35/10 meeting shape with the two required closing artifacts; the four in-room questions and four objections; the day-7/day-14 follow-up; the two day-14 pass conditions; and the three required per-meeting outputs with their Salesforce-account-notes destination.
- `context/initiatives/spark-in-practice.md` § Assistant rules — the concrete behavior changes for this plugin's agents while the motion is active: `session-prepper` gate-checks before producing a brief and never drafts a demo agenda for an in-scope account; `post-session-debrief` records the two-week goal verbatim with a named owner, writes the three outputs to Salesforce (not Planhat) until told otherwise, creates day-7 and day-14 checks, and calls out a session that closed without both artifacts; `draft-email`/`draft-followup` never propose a demo or overview to an in-scope account and never ask the customer to run the workspace assessment, which is AISE pre-work.
- `context/initiatives/spark-in-practice.md` § Accounts graduate into scope — the tier list is a 12 Aug snapshot, so a T5 account that enables Spark now meets the in-scope rule and must be reflagged rather than left as T5. First entry: weclapp GmbH, enabled 2026-08-20.

### Changed
- `context/project-instructions.md` § 2: added the `context/initiatives/` row to the reference table, plus an **Active initiatives take precedence** paragraph naming what an initiative may override (agenda, meeting naming, required outputs, logging destination, follow-up cadence) and what falls back to the defaults.
- `skills/aise-context/SKILL.md`: `context/initiatives/README.md` added to the universal context load, so active motions are picked up at session start rather than discovered mid-task.
- `context/session-naming-convention.md`: new initiative-override callout at the top. An active initiative can mandate its own calendar-event title — `spark-in-practice.md` requires `Spark in Practice — [Account] × Productboard` verbatim, since the weekly forecast report reads the title and a meeting without it does not exist in reporting. The `[TYPE][N]` convention still governs the session record; only the calendar title is overridden.

### Notes
- The `Spark in Practice — [Account] × Productboard` string is a reporting key, not prose, and is the one documented exception to the em dash ban in `context/communication-style-guide.md`. Both files say so explicitly so the string is not "corrected" into a broken key.

---

## [2.37.0] — 2026-08-20

### Added
- `context/planhat-schema.md`: new **§ Planhat Record URLs** section documenting the canonical record-link template (`https://ws.planhat.com/productboard/home/data-explorer/<path-slug>?preview=<Model>.<_id>`), a worked Conversation example, and a per-model path-slug table marking `conversation` as verified and the rest as inferred pending UI confirmation.
- `context/planhat-schema.md`: new **Comment** and **Attachment** model sections (fields, write rules) — Comment is used by `post-session-debrief` for account-level next-session notes; Attachment is used to attach KDD docs to a Conversation.
- `context/planhat-schema.md`: new `externalId` convention note clarifying that `/session-backfill` keys on the Notion Session page ID while `/session-debrief` keys on the Google Calendar event ID, and that the two formats never collide.
- `context/project-instructions.md`: Planhat records now carry the same "always surface the direct URL" rule that Notion pages already had (§4.5), plus a §7 ground rule that record citations must use real IDs — a guessed or root-domain link reads as verified when it is not.
- `daily-brief.md`: new `--auto-prep` flag (off by default) — for tomorrow's sessions flagged as missing prep, runs the full `session-prepper` procedure inline so the brief lands directly in `custom.Prep Notes` on the Planhat calendar-event Task, instead of just flagging the gap.
- `daily-brief.md`: new migration-completeness guardrail — flags "Task count may be incomplete" when a customer's Planhat task/session count looks implausibly sparse for an active account, rather than silently under-reporting.
- `ph-migrate-notion-data.md`: new mandatory post-run verification step — checks for duplicate Conversations by normalized `externalId`, counts/lists Conversations written with empty `users` (unattributed), and spot-checks idempotency by re-running migration against an already-migrated customer. Final totals table gains "Duplicates found" and "Unattributed" columns.
- `session-prepper.md`: new **1b. Fetch voice preferences** step, mandatory before drafting anything — resolves `custom.AISE Profile preferences` and applies the user's voice rules to every output, including the Planhat Task's `custom.Prep Notes`.
- `skills/planhat-formula-builder/SKILL.md`: four new confirmed-in-production gotchas (unquoted `<<field>>` tokens causing a save-time `SyntaxError`; a formula's declared `fieldType` silently mismatching its actual return type; `DATES_MAXOF`/`MIN`/`MAX` returning blank on an empty input instead of falling back), one new worked pattern (Pattern F — filtering by record ownership via a same-model array field, with its To/CC/BCC precision limitation), and matching debugging-checklist entries.

### Changed
- `account-setup.md` / `/customer-setup`: full rewrite from a Notion-based Customer-page/Active-Package/session-backfill setup agent to a Planhat-only research agent. It now only resolves the Planhat Company and writes a research write-up as a Planhat Conversation note — it no longer creates Customer pages, Active Packages, or backfills sessions, and refuses to create a Company record itself (owned by the SF sync). Flag modes simplified from three (`--research`/`--refresh`/baseline) to two (default enrich-or-create, `--force-new`). On refresh, prior research is preserved and new findings are prepended under a dated "New since" block rather than overwritten.
- `post-session-debrief.md` / `/session-debrief`: full rewrite of every write target from Notion to Planhat. Session notes now land as a Planhat Conversation (via the GCal-synced Task's `status → "done"` transition, which triggers Planhat's own Conversation creation); PB-side commitments, Slack debriefs, and product-feedback items are created as Planhat Tasks; next-session/account-notable updates post as a single Company Comment (plain-paragraph HTML only — no bold or bullets); the KDD doc attaches to the Conversation as a Planhat Attachment. The old Notion Customer-page/Active-Package "Working Notes" updates and the Notion-migration-gate step are both gone.
- `daily-brief.md`: Planhat (`Conversation`/`Task`) is now the sole source of truth for sessions, prep status, and open tasks — Notion is no longer consulted as a fallback, so unmigrated customers will show gaps instead of stale Notion data. Prep-status lookup, topic resolution, and the open-tasks pull were all rewritten against Planhat models; task links now use the documented data-explorer template.
- `kdd-builder.md` / `/session-kdds`: output destination changed from a Notion sub-page to a published Google Drive file (shared, direct-download link), attached to the session's Planhat Conversation by `post-session-debrief`. Session resolution and starter-example sourcing both moved from Notion to Planhat + prior Conversations/KDD Attachments.
- `skills/customer-setup/SKILL.md`: redesigned around the new `account-setup` contract — single default mode (enrich-or-create a Planhat Conversation research note) plus `--force-new`; research sourcing shifted from Salesforce/Notion/GCal to web search + Planhat Sales Handoff fields + Gong/Gmail via Glean.
- `skills/daily-brief/SKILL.md`, `skills/log-feedback/SKILL.md`: synced to match the Planhat-only rewrites of `daily-brief.md` and the product-feedback Task queue (Planhat `Task` model with `type: "Product Feedback"`, `EndUser` contact lookup, and a separated description-update / status-transition write in Step 8 so the transition reliably triggers Planhat's touchpoint Conversation).
- `context/planhat-schema.md`: top status banner rewritten — Planhat is now primary for session debrief, product feedback, and account health/revenue/Spark tracking (2026-08-19); Notion remains authoritative only for not-yet-migrated agents (session-prep, account-plan, engagement-planner, session-backfill).
- `context/notion-planhat-field-mapping.md`, `context/planhat-schema.md`: `Delivered By` → Conversation `users` now resolves and writes **every** co-presenter (never truncated to the first value), with a 4-tier fallback chain (static table → live lookup → session owner → Company owner) and a `NEEDS ATTRIBUTION` warning if all resolution fails.
- `about/README.md`: rewrote the "where personal data lives" model from private Planhat Documents (versioned by re-creation) to direct `custom.AISE *` fields on the user's Planhat User record; documents the `custom.AISE Calendly *` and `custom.AISE Tracker Memory` fields.
- `README.md`, `CLAUDE.md`, `skills/assistant-help/SKILL.md`: updated to reflect the Planhat-primary model throughout — `notion-sync` now documented as two modes, specialist agent count updated.

### Fixed
- `context/notion-planhat-field-mapping.md`, `context/planhat-schema.md`, `agents/ph-migrate-notion-data.md`, `skills/ph-migrate-notion-data/SKILL.md`, `agents/session-prepper.md`, `agents/assistant-onboarding.md`, `agents/daily-brief.md`: Notion page IDs must be normalized (hyphens stripped, lowercased) before use as a Planhat `externalId`/`sourceId` dedup key — the Notion MCP returns a dashed UUID, and writing that raw form broke dedup and silently duplicated records. Dedup checks now query both forms until historical data is confirmed clean.
- `context/planhat-user-profile.md`: corrected an incorrect claim that `custom.AISE *` rich-text User fields accept plain `\n`-joined text. Planhat's rich-text fieldType silently strips bare `\n` on write — confirmed live 2026-08-18, a plain-text write came back as one run-on string with no separators. All affected agents (`assistant-onboarding`, `daily-brief`, `session-prepper`, `kdd-builder`) now write/parse these fields as HTML (`<p>Key: value</p>` per line).
- `agents/session-prepper.md`, `context/planhat-schema.md`: `custom.Prep Notes` now inserts an empty `<p><br></p>` spacer between sections, fixing consecutive `<p>` tags rendering with no visual gap in Planhat's UI; prep content now has the user's voice preferences applied (previously shipped with em dashes regardless of preference, since voice wasn't fetched before drafting).
- `agents/assistant-onboarding.md`: added a mandatory post-write verification step — re-reads a just-written rich-text field to confirm `<p>` boundaries survived, since Planhat returns HTTP 200 even on a malformed write.

### Removed
- `agents/sf-backfill.md` deleted — obsoleted by Planhat's native Salesforce sync; ARR/contract-date data is now read live from the synced Planhat Company/Deal records instead of copied into Notion.
- `skills/notion-sync/SKILL.md`: `--sf` mode removed entirely (description, mode list, and the dedicated Salesforce-sync section) — `notion-sync` is now `--owner` and `--renewals` only.
- `agents/account-setup.md`: session backfill, Active Package creation, and Master Package/ARR-threshold mapping removed from the `/customer-setup` path — no longer produced by this agent.

---

## [2.36.0] — 2026-08-16

### Changed
- Personal profile storage (`/assistant-setup`) moved off Planhat Documents/Notion pages onto `custom.AISE *` fields directly on the user's Planhat `User` record — identity, voice preferences, workspace config, Voice Scrape Samples, Tracker Memory, and six Calendly booking links (added Discovery, Kickoff, and Spark to the three that previously existed). Writes are now in-place via `update_model_record` — no more append-only versioning.
- Swept every downstream agent/skill that reads identity, voice, or Tracker Memory (`email-drafter`, `draft-followup`, `draft-email`, `diagram-builder`, `create-deck`, `session-facilitation`, `kdd-builder`, `session-summarizer`, `engagement-planner`, `post-session-debrief`, `bulk-debrief`, `session-prepper`, `daily-brief`, `notion-writer`, `bulk-account-setup`, `session-backfill`, `bulk-prep-week`, `notion-completion-fix`, `notion-ask`, `sf-backfill`, `notion-integrity-check`, `aise-context`, `log-feedback`) to resolve from the new Planhat fields instead of the old Notion `AISE Identity —`/`AISE Assistant Preferences —` pages.
- `/spark-onepager` now reads the Calendly booking link from `custom.AISE Calendly Spark` automatically instead of asking every time.
- Agents that previously hard-stopped on an empty profile (`daily-brief`, `notion-completion-fix`, `bulk-account-setup`, `bulk-prep-week`, `diagram-builder`, `aise-context`) now run an auto-resolve procedure instead: auto-migrate from a legacy Notion page if one exists, or run `/assistant-setup` inline if nothing exists anywhere, then resume the original task.
- `context/planhat-user-profile.md` rewritten as the canonical field map, read/write procedure, migration-check procedure, and the new auto-resolve procedure for consuming agents.

### Fixed
- `session-prepper.md` and `post-session-debrief.md` had Planhat tools declared under the wrong MCP prefix (`mcp__Planhat__*` instead of `mcp__claude_ai_Planhat__*`), which would have failed to resolve at runtime.
- Stale "personal config lives in Notion" documentation in `assistant-help` and `assistant-improvement` updated to the current `custom.AISE *` field names.

---

## [2.35.0] — 2026-08-14

### Added
- `planhat-formula-builder`: new skill covering Planhat formula field syntax end to end — same-model `<<>>` vs cross-model `OPERATION(Model.field & {...})` references, a function support matrix (`FIND` accepts `sort`/`limit`; `COUNT`/`SUM`/`AVERAGE`/`MAX`/`MIN` do not), filter operators, the `through` traversal escape hatch in both its array and string forms, operator and date-function reference, five worked patterns, and a nine-step debugging checklist.
- `planhat-formula-builder`: documents the determinism rules that make multi-record lookups safe — `"limit": 1` without `"sort"` returns an arbitrary record, and `"sort"` accepts exactly one key so there is no tiebreaker. Both matter on accounts with overlapping live terms (early renewals, mid-term expansions, multi-workspace accounts), where several child records legitimately match the same filters at once.
- `planhat-formula-builder`: records that `IS_EMPTY(FIND(...))` cannot distinguish "no record matched the filters" from "a record matched but the target field is blank", with a `COUNT()` companion-field workaround.

### Changed
- `planhat-automations`: scope narrowed to automation steps only. Formula-field syntax moved to `planhat-formula-builder`; description updated so the two skills no longer compete on triggering, and a pointer added under the H1. The `FIND` + `through` pattern stays in place, since it drives the Association-pull-vs-formula decision documented alongside it.

---

## [2.34.0] — 2026-08-10

### Added
- `ph-migrate-notion-data`: `AskUserQuestion` gate before writing, asking whether to resolve Gong attendees per-session or per-company when a run's session count exceeds ~20 — surfaces the accuracy/speed tradeoff explicitly instead of silently batching at scale.
- `ph-migrate-notion-data`: Sessions → Conversations dedup now skips the per-session existing-Task title-match check when the session title is a generic auto-numbered pattern (e.g. "Sync", "Sync (12)") — `externalId` dedup is sufficient in that case; the check still runs for descriptively-named sessions.

### Fixed
- `ph-migrate-notion-data`: checkpoint writing is now a mandatory, blocking step at each customer/step boundary (previously specced but not consistently written, requiring manual conversation-transcript reconstruction after a mid-run auth failure) — added an explicit resume branch that validates scope/flags before trusting an existing checkpoint.
- `ph-migrate-notion-data`: added a pre-flight field check before every Task/Conversation `create_model_record` call to catch missing `companyId`/`externalId`/`sourceId` before the API round-trip.
- `ph-migrate-notion-data`: Gong/GCal EndUser resolution now narrows `search_records` queries with company name/domain for common names, and falls back to `grep` on oversized auto-saved results instead of reading the full file.
- `context/notion-planhat-field-mapping.md`: added a bolded `companyId`-required note atop both the Sessions→Conversation and Tasks→Task field-mapping tables — resolve and cache the Company `_id` once per customer, never omit it on a create call.

---

## [2.33.1] — 2026-08-08

### Fixed
- Checkpoint & resumability (all 6 aise-assistant agents that use it): checkpoints now record the flags/args that shaped the run (`--skip`, `--force`, `--rerun`, `--since`, `--customer`, `--past`) and must be verified against the current invocation before being trusted. Previously a stale or scope-mismatched checkpoint (different flags, different lookback window, or a `today`-relative window from a prior day) could be silently resumed against, skipping work the current run actually needed to redo.
- Clarified the checkpoint authoring convention in `.claude/CLAUDE.md` (dev-only) — the scope-slug in a checkpoint's filename should identify the run (needed for correct resumption); the "no real customer names" rule applies to spec/example text, not runtime checkpoint data.

---

## [2.33.0] — 2026-08-08

### Added
- Generalized checkpoint & resumability (introduced for `ph-migrate-notion-data` earlier today) to every bulk/multi-record agent: `bulk-account-setup`, `bulk-debrief`, `bulk-prep-week`, `session-backfill` (`--bulk` mode), `notion-integrity-check`, `notion-completion-fix`. Each now writes a `/tmp/<agent-name>-<scope>.json` checkpoint after each completed item, resumes from the next incomplete item on a subsequent run instead of redoing finished work, and deletes the checkpoint on full completion.

---

## [2.32.0] — 2026-08-08

### Added
- `ph-migrate-notion-data`: new **Checkpoint & resumability** section — after each major step, writes a checkpoint file to `/tmp/ph-migrate-<customer-slug>.json` tracking completed steps, migrated Conversations/Tasks, and unresolved endusers. On start-up, resumes from the last incomplete step instead of redoing finished work; checkpoint is deleted on full success.

### Changed
- `ph-migrate-notion-data`: the `noteId` check after a Done task auto-creates a Conversation is now a **spot-check** — only the first Done task in a run is verified; if it passes, remaining Done tasks skip the individual check (Planhat sets `type` consistently).
- `ph-migrate-notion-data`: Gong + GCal EndUser backfill now **early-exits** when a session has no Gong call URL and its `Call Date` is older than 90 days — `endusers` is omitted from the payload rather than attempting an unreliable resolution.
- `context/notion-planhat-field-mapping.md`: added a note on Brandwatch/Cision dual-email EndUser records — Brandwatch contacts may have both an `@brandwatch.com` and `@cision.com` Planhat EndUser record; search both domains on a failed lookup.

---

## [2.31.1] — 2026-08-08

### Fixed
- `ph-migrate-notion-data`, `context/notion-planhat-field-mapping.md`: Company field sync no longer writes `custom.⚡️ Spark Stage`, `custom.AI Ready`, or `custom.⚡️ Igniting?` — those fields are live-data SSOT (weekly CSV sync via `temp-ph-ignite-conversion-data-sync`) and were at risk of being overwritten by migration runs.
- `ph-migrate-notion-data`: sessions with `Do not count = __YES__` are now always migrated as Conversations (previously skipped), logged under a new `🏁 Audit / Setup Review` Planhat session type so they stay on record without counting against the services quota.

---

## [2.31.0] — 2026-08-07

### Added
- `temp-ph-ignite-conversion-data-sync` skill: bulk-syncs Spark rollout data (AI consent, Enabled, Activated visibility, Engaged, plus their dates) from a weekly CSV export into Planhat Company records, matched by Salesforce ID → `sourceId`. Supports `--dry-run` and `--accounts` scoping; never touches the manually-managed `custom.⚡️ Igniting?` field.
- `context/planhat-user-profile.md`: documents the Planhat-document schema, naming (`AISE Profile — Identity/Preferences/Voice Scrape Samples — {display_name}`), and append-only versioning (no `update_document`/`delete_document` tool on this connector) used by `/assistant-setup`.

### Changed
- `CLAUDE.md`, `about/README.md`, `agents/assistant-onboarding.md`, `skills/assistant-setup/SKILL.md`, `scripts/setup-connections.sh`: personal profile storage (identity, voice, workspace preferences) moved from Notion pages to private Planhat documents, resolved via `search_documents`/`get_document` rather than `notion-search`/`notion-fetch`. Most other agents/skills in the plugin still read the legacy Notion identity pages — flagged in `CLAUDE.md` as migration-in-progress, not yet swept.
- `context/notion-schema.md`, `context/notion-planhat-field-mapping.md`, `context/planhat-schema.md`: corrections and clarifications to keep the Notion↔Planhat field mapping accurate.

---

## [2.30.3] — 2026-08-06

### Fixed
- `ph-migrate-notion-data` and `post-session-debrief` agents + `context/notion-planhat-field-mapping.md`: corrected Planhat Conversation field name from `endUsers` (camelCase) to `endusers` (all lowercase). Planhat silently accepts writes to the wrong field name with an HTTP 200 response, dropping the data without error — a prior migration run showed 20 successful Conversation updates but wrote no attendees on any of them.
- `ph-migrate-notion-data` agent: added a mandatory spot-check after the first Conversation write with resolved attendees — reads back `endusers` via `get_model_record` and aborts with a warning if it's empty, since a 200 response is not proof the field was written.

---

## [2.30.2] — 2026-08-06

### Fixed
- `ph-migrate-notion-data` agent: EndUser backfill (Gong + GCal attendee resolution) is now explicit and non-skippable — it is part of the per-session payload-build loop, not a deferrable phase. A prior run completed all Conversation creates but skipped this sub-step, requiring a separate follow-up pass.
- `ph-migrate-notion-data` agent: Gong `ask_account` now requires the Salesforce Account ID (`sourceId` on the Planhat Company) as `crmAccount` — passing the company display name returned `CRM_ENTITY_NOT_FOUND`.
- `ph-migrate-notion-data` agent: GCal is now fallback-only for sessions within the last ~90 days; Gong is primary for all sessions. GCal indexing was found to be unreliable beyond ~3–4 months, returning zero results for older sessions.
- `ph-migrate-notion-data` agent + `context/notion-planhat-field-mapping.md`: removed remaining `Spark Conversation`/`activityTags` references (field was already dropped as non-writable via MCP in a prior edit; these were leftover mentions).

### Added
- `ph-migrate-notion-data` agent: EndUser email matching now retries with common first-name nickname expansions (e.g. `jon` → `jonathan`, `liz` → `elizabeth`) before logging a non-match — Gong/GCal attendee emails sometimes use a nickname that doesn't match the full name on the Planhat EndUser record.

---

## [2.30.1] — 2026-08-06

### Fixed
- `ph-migrate-notion-data` agent: Done tasks created directly with `status: "done"` never triggered Planhat's auto-Conversation — replaced with a two-step create-as-"To Do"-then-transition-to-"done" pattern (confirmed by live test). `noteId` absence is now treated as a write-logic bug, not a workspace/connector limitation.
- `ph-migrate-notion-data` agent: removed a false claim that Task deletion isn't possible via API — `delete_model_record` works for both `Task` and `Conversation` (confirmed by live test).
- `ph-migrate-notion-data` agent: Notion finalization step now writes `"PH Migrated"` (capital M) — the lowercase `"PH migrated"` name was rejected by the Notion connector.
- `ph-migrate-notion-data` agent: removed `"PH Last Migration Date"` from Step 0B customer-lookup SQL (not a queryable column in this workspace, caused `no such column` errors); the already-migrated skip note now fetches the date per-page via `notion-fetch` instead.
- `ph-migrate-notion-data` agent: Conversation `list_model_records` dedup check now sets `LIMIT: 50` + `SORT: "-createdAt"` — the model's ~36-record cap could hide newly created records.
- `context/planhat-schema.md`: `📦 Other` Conversation type mapping corrected to match the authoritative `notion-planhat-field-mapping.md` (`🔁 Sync` default, `🎙️ Demo` title-pattern override) — previously contradicted it with a stale `🏁 Audit / Setup Review` mapping.
- `context/planhat-schema.md`: fixed a self-contradicting line claiming "Done/Canceled statuses trigger auto-Conversation creation" — only a `status` transition to `"done"` does; `"ignored"` never does (confirmed by live test).
- `context/planhat-schema.md`: Task auto-Conversation section corrected — the auto-created Conversation's `type` defaults to `"note"` (not `"Task"`), its `_id` is the same value as the Task's `_id`, and `noteId` only appears on the transition's `update_model_record` response, never on `create_model_record`.

### Added
- `ph-migrate-notion-data` agent: customer-name lookup normalizes common notation variants (dots/hyphens/spacing) into a single `OR` query instead of retrying sequentially.
- `ph-migrate-notion-data` agent: Company lookup now falls back to a Planhat `domains` search for acquired/merged entities when name and SF sourceId matches both fail.
- `ph-migrate-notion-data` agent: per-customer log now includes a manual reminder that `activityTags` (Spark) must be applied in the Planhat UI.
- `context/planhat-schema.md`: Customer Name Mapping table — added Entrust → Onfido Ltd alias (shared `domains` entry) and a note to check `domains` before concluding no match exists.

---

## [2.30.0] — 2026-08-05

### Added
- `ph-migrate-notion-data` agent + skill (`/ph-migrate-notion-data`) — Notion → Planhat migration, previously undocumented in `CLAUDE.md`/`README.md` despite existing on disk since v2.29.0-era. Added to the agent table, command roster, and README counts.
- `README.md` / `CLAUDE.md`: documented `/session-facilitation` and `/spark-onepager` as standalone commands (existed on disk, undocumented); documented `/notion-fix` and `/notion-ask` in the README family breakdown; documented `/assistant-improvement`.

### Removed
- `skills/temp-api-migration-usage-report` — temporary skill for the API v1 usage report, past its self-declared sunset (API v1 sunset was 2026-07-08; skill said to delete after that date).

### Fixed
- `README.md`: slash-command and agent counts were stale (claimed 22 commands / 20 agents; actual 32 commands / 24 agents before this cleanup).

---

## [2.29.5] — 2026-07-31

### Fixed
- Planhat dual-write: also write Gong transcript to `transcript` field on Conversation record (HTML `<p><strong>Speaker:</strong> text</p>` format per turn; map Gong author hashes to real names via calendar attendees).

---

## [2.29.4] — 2026-07-31

### Fixed
- Planhat dual-write: Calendly-synced events exist as the same ID in both `Task` and `Conversation` models — session notes must be written to `description` on both records (not just Task). Do not create a new Conversation record.
- Planhat formatting: all `description` fields must use HTML (`<h3>`, `<ul>/<li>`, `<strong>`, `<p>`, `<a href>`). Plain markdown is not rendered.

---

## [2.29.3] — 2026-07-31

### Changed
- `context/communication-style-guide.md`: added explicit em dash ban section – never use em dashes (—), always en dashes (–), applies to all output without exception

---

## [2.29.2] — 2026-07-31

### Changed
- `context/communication-style-guide.md`: added subject line format convention — use `Productboard + [Customer] – [Topic]` (never "x"); Productboard first for sender context on skim

---

## [2.29.1] — 2026-07-29

### Fixed
- `skills/session-facilitation`: Step 3 now detects Cowork vs CLI context before saving — Cowork uses `Write` tool + `present_files` (Desktop path is inaccessible from Linux sandbox); CLI uses Bash `mkdir` + Write to `~/Desktop/aise-assistant/facilitation/` as before.
- `skills/session-facilitation`: Step 4 (Notion callout) is now mandatory and non-skippable; explicit failure surface in Step 5 report if Notion write fails.
- `agents/session-prepper`: Step 5 enrichment mode — when `Prepped = YES` and a `📋 Prep` toggle already exists, inserts a `🔔 New since prior prep (date)` block inside the existing toggle instead of creating a duplicate. Override with `--force-new-toggle`.

### Changed
- `skills/session-facilitation`: Step 1 adds sub-step (h) — checks for user-uploaded pre-read documents (governance docs, agendas, survey results) and plans a dedicated sidebar reference panel per document found.
- `skills/session-facilitation`: Panel structure adds **Pre-read reference panels** spec — skimmable summary table + amber open-questions card + teal capture card. This is the confirmed good format from IBO A12.
- `agents/session-prepper`: New Step 4b — for Roadmaps and Strategic Planning sessions, explicitly searches Gmail and Glean for PM surveys and usage data; surfaces findings as `📊 Survey / usage signals` callout in the prep brief and passes them as info boxes to the facilitation HTML.
- `templates/session-kdds/04-roadmaps.md`: Added PM survey / usage data to Pre-read inputs section.

## [2.29.0] — 2026-07-29

### Added
- `skills/session-facilitation`: new skill — generates a self-contained interactive HTML facilitation guide for any customer session. Features: sticky header with live timer (click to start/pause, amber warning near end), sidebar navigation between agenda panels, decision capture panels (one per KDD for A-sessions, with options table + live capture table + notes textarea), open items check-in, attendee presence tracking, watch-fors, synthesis/decisions register, and action items capture with add-row. Saves to `~/Desktop/aise-assistant/facilitation/` and adds a file-path callout to the Notion Session page.

### Changed
- `agents/session-prepper`: added step 6.5 — auto-generates facilitation HTML for `🏗️ Architecting`, `🔎 Discovery`, and `👟 Kick off` sessions after KDD sub-page write; offers (does not auto-run) for Sync and Training. Carries context from prior steps — does not re-fetch. Facilitation guide file path included in step 7 report.
- `skills/session-prep`: updated description and step 7 to reflect facilitation HTML generation. Added "facilitation guide" / "skip facilitation" to compound request table.
- `skills/assistant-help`: added `/session-facilitation` to common workflows table and updated suggested session order to mention facilitation guide. Added `-facilitation` to `session-*` family description.

---

## [2.28.1] — 2026-07-15

### Fixed
- `context/notion-schema.md`: Sessions create rule updated — `Current Account Owner` must now be set **explicitly** on create (`["<user-uuid>"]`); removed "leave blank" instruction. The Sessions-side automation does not fire reliably; missing this field causes sessions to be invisible in tracker views and reports.

---

## [2.28.0] — 2026-07-15

### Added
- `create-deck`: mandatory print-to-PDF CSS block appended to every deck's `<style>` tag — preserves dark backgrounds, renders one slide per page, fixes layout-split grid collapse on print
- `create-deck`: Support Hub link rule — always use `https://support.productboard.com/hc/en-us` (not bare domain)
- `context/planhat-schema.md`: Planhat data model, field mapping, value mapping, name resolution table, and agent traversal patterns
- `context/notion-planhat-field-mapping.md`: Notion ↔ Planhat field mapping reference for dual-write workflows

---

## [2.27.3] — 2026-07-01

### Fixed
- `temp-api-migration-usage-report`: in directory mode, the plain ranked CSV is now skipped when a `*without_partner*` ranked CSV is present — previously both were processed and the last write won, producing a report based on whichever file sorted last alphabetically

---

## [2.27.2] — 2026-07-01

### Fixed
- `temp-api-migration-usage-report`: DELETE/GET/PATCH on link sub-resources now produce correct descriptions (e.g. "Delete a note link") instead of the generic "Link notes / links" catch-all
- `temp-api-migration-usage-report`: endpoints bucketed into the "Other" resource group are now excluded from the PDF table entirely, removing noise rows for unmapped paths like `/features-objectives` and `/features.json`

---

## [2.27.1] — 2026-07-01

### Fixed
- `temp-api-migration-usage-report`: fixed incorrect pluralization in endpoint descriptions — "List companies" no longer rendered as "List companys"; list descriptions now use the original path segment directly instead of re-pluralizing the singularized form

---

## [2.27.0] — 2026-07-01

### Added
- `skills/spark-onepager`: New skill that generates a customer-facing Spark AI Adoption Program one-pager as a print-ready HTML file. Collects customer name and Calendly booking link, substitutes them into a fixed 1280×720 16:9 slide template (5-session journey, stats, CTA block), saves the file to the Cowork outputs folder, and presents it. Prints cleanly in Chrome via `zoom: 0.78` in the `@media print` block.

---

## [2.26.1] — 2026-06-30

### Fixed
- `skills/log-feedback`: Footer contact link now points to Klara's Slack DM instead of email address
- `skills/log-feedback`: Simplified Step 6 HITL from two AskUserQuestion calls (Submit + 4-checkbox Verify) to a single "I confirm and submit" / "Edit first" / "Skip this item" / "Stop processing" question — removes friction and the checkbox-skip failure mode
- `skills/log-feedback`: Added drafting rule F6 — never reference "AISE", "Solutions Architect", or individual names in Pain point or Workaround sections; use generic equivalents ("Productboard support team", "PB support")
- `skills/log-feedback`: Step 8a now explicitly states `notion-update-page` requires `page_id` (snake_case), not `pageId` — fixes "Invalid input: expected string, received undefined" error on Notion task closeout

---

## [2.26.0] — 2026-06-30

### Added
- New `/create-deck` skill — generates a customer-facing HTML presentation deck for any meeting type (kickoff, QBR, strategy, product demo, onboarding, check-in). Pulls context from Notion, Glean, and Gmail; plans slide structure by meeting type; produces a self-contained `.html` file at `~/Desktop/aise-assistant/decks/`.
- `skills/create-deck/SKILL.md` — 4-phase workflow: context pull, slide planning, HTML generation, save and confirm.
- `skills/create-deck/deck-template.html` — complete Productboard-branded deck engine: 960×540 canvas, 7 layout classes (`layout-title`, `layout-agenda`, `layout-divider`, `layout-cards`, `layout-split`, `layout-kpi`, `layout-next-steps`), callout component, dot-nav with tooltips, keyboard and swipe navigation, auto-scale to any screen.

---

## [2.25.0] — 2026-06-30

### Added
- `skills/log-feedback`: Step 5 — strict format pre-flight warning; `AskUserQuestion` widget replaces in-text HITL checklist in Step 6; drafting rule F5 prohibiting "AI-linking" / "Linked by AI" references
- `skills/log-feedback`: Step 4 — explicit data-gathering checklist (ARR, renewal, Salesforce URL, Gong URL, contact email) required before drafting
- `skills/log-feedback`: Step 4b — platform capability check is now mandatory and blocking for Spark/MCP/API items; confirmed-available gaps skip to next item
- `skills/log-feedback`: Step 6 — email gate blocks HITL if `customerEmail` is unresolved; AskUserQuestion single-select (Submit/Edit/Skip/Stop) + multi-select verification checkboxes replace text-based flow
- `skills/log-feedback`: Step 8b — literal format example for Notion task closeout body; prohibits "PB note:" prefix and missing `---` separator or date
- `CLAUDE.md`: `/create-deck` command added to standalone commands table

## [2.24.6] — 2026-06-29

### Fixed
- `skills/log-feedback`: Step 8 closeout — explicitly documents two-step pattern only (`update_properties` Status=Done, then `insert_content` append URL to body); adds explicit prohibition on writing a `Notes` property (doesn't exist in Tasks DB)
- `skills/log-feedback`: Step 7 — removes stale "Feedback form (GTM):" prefix reference from `title` field instruction
- `skills/log-feedback`: Workaround section — must include any workaround Klara already suggested; frame as "X was suggested but [limitation]"

### Added
- `skills/log-feedback`: Step 4b — pre-draft platform capability check; search `#releases` for Spark or PB MCP feature availability before drafting; encodes known facts (Spark event triggers not available, Spark cannot auth to external systems, PB MCP server scope as of Jun 4 2026)
- `skills/log-feedback`: Drafting rules — use customer's stated language (not PB-internal terminology); Spark external auth limitation framing (periodic manual distillation, not live sync); PB MCP gap workarounds must list both direct API v2 and custom MCP server on top of API v2

---

## [2.24.5] — 2026-06-29

### Fixed
- `skills/log-feedback`: disclaimer footer wording — "Questions about this tool? Contact Klara Martinez." (was "For questions or feedback on this note" which implied content ownership)

---

## [2.24.4] — 2026-06-29

### Changed
- `skills/log-feedback`: removed "Feedback form (GTM):" prefix from title — title is now just the concise problem statement
- `skills/log-feedback`: removed `<b>Note title</b>` section from content body — title is already in the `title` field, no need to repeat it
- `skills/log-feedback`: Salesforce and Gong URL fields now rendered as `<a href>` clickable links
- `skills/log-feedback`: added `<small><i>` disclaimer footer to every note — credits aise-assistant plugin and links to Klara Martinez for questions

---

## [2.24.3] — 2026-06-29

### Fixed
- `skills/log-feedback`: added `<br>` after each `<b>Label</b>` tag so label and content render on separate lines (not as a run-on); `<br><br>` between sections remains for paragraph spacing
- `skills/log-feedback`: Pain point guidance now warns against including tool names or system names inferred from AI-generated meeting summaries — use generic language ("previously had a fully automated solution") unless the detail appears in a verbatim customer quote

---

## [2.24.2] — 2026-06-29

### Fixed
- `skills/log-feedback`: added `<br><br>` between all HTML sections in content template so notes render with paragraph breaks instead of as a single blob
- `skills/log-feedback`: Step 4 now includes a 3-step email lookup chain (Notion Contacts → Glean Gmail → Glean Gong) before surfacing ⚠️ MISSING in HITL
- `skills/log-feedback`: Step 8 now captures the returned PB feedback URL/ID and appends it alongside the "Logged to PB" confirmation into the Notion task body, then marks Status = Done

---

## [2.24.1] — 2026-06-29

### Fixed
- `skills/log-feedback`: corrected tool field mapping for `feedback_create_feedback` — clarified that `<b>Note title</b>` is body-only (not a separate param), `importance` has no dedicated PB field (body text only), `tags` must be a JSON string array not a comma-separated string, and `sourceUrl` accepts Notion transcript URL as fallback when no Gong link is available

---

## [2.24.0] — 2026-06-29

### Added
- `skills/log-feedback`: new `/log-feedback` skill — discovers outstanding Notion feedback tasks, drafts structured Productboard GTM feedback notes (HTML template with all required fields), and submits via PB MCP with explicit HITL confirmation before every submission; never uses Klara's own email as customerEmail; flags missing contact info and thin Gong context as gaps in the review step

---

## [2.23.3] — 2026-06-24

### Fixed
- `email-drafter`: Gmail drafts now use Gmail-safe formatting — no markdown tables, no markdown bold in body text; next steps formatted as flat bulleted list (`[Owner] — [Action] (timing)`) instead of pipe tables
- `context/communication-style-guide.md`: added "Gmail copy-paste safety" rules under Email Guidelines covering no-table, no-markdown-bold, and flat-list next steps requirements

---

## [2.23.2] — 2026-06-15

### Fixed
- Gong search in transcript lookup order (step 2) now uses `after:` date filter + people-and-account keywords instead of embedding the session date as query text, which Gong treated as a content keyword causing ranking failures
- Added two-attempt rule: agent must retry with a participant email anchor before concluding the transcript is unavailable and triggering the expensive placeholder-debrief branch

---

## [2.23.1] — 2026-06-15

### Changed
- `context/notion-schema.md` — added Ignite/Spark fields to Customers DB: `Spark Customer Journey` (select with 6 stages), `Ignite Journey Last Edited` (date, auto-updated), `Igniting?` (checkbox); stage definitions block with behavioral notes; `Days in Current Ignite Phase` and `Ignite Responsibility` added to read-only formulas list

---

## [2.23.0] — 2026-06-10

### Added
- `spark-demo-prep`: new skill that generates a fully customized Spark demo playbook for a named customer. Runs parallel research (Slack #releases feature inventory, Glean/Gong/Gmail account context, Google Calendar session metadata), auto-detects brand color scheme via logo extraction (Clearbit → Google favicon → favicon.ico fallback), synthesizes research into demo angles, and produces a polished self-contained HTML playbook saved to `~/Projects/pb-tools/spark-{slug}-demo-playbook.html`. Supports `--scheme orange|teal|purple` override and `--domain` flag. Includes `scripts/extract_logo_color.py` for dominant-hue detection with Pillow.

---

## [2.22.1] — 2026-06-05

### Fixed
- `temp-api-migration-usage-report`: replaced hardcoded `$(dirname <SKILL_FILE>)` script path with a portable `find /sessions` discovery snippet — fixes `No such file or directory` failures in the Cowork bash sandbox where plugin files mount under `.remote-plugins/<plugin_id>/skills/` rather than `.claude/skills/`. Added explicit error guard if the script is not found.

---

## [2.22.0] — 2026-06-05

### Added
- `temp-api-migration-usage-report`: new temporary skill that generates a customer-facing PDF report from a Looker CSV export of API v1 usage, ahead of the API v1 sunset on 2026-07-08. Grouped resource table, callout blocks, "Where to focus" narrative with CRM/hierarchy/feedback integration-type classification, environment-aware output (Cowork vs. CLI), and bulk mode (one PDF per CSV, skips bad files, prints a per-file summary table). Implemented as a self-contained Python script (`scripts/generate_report.py`) rendered to PDF via WeasyPrint.

---

## [2.21.1] — 2026-06-05

### Fixed
- `daily-brief`: Tasks view query (Step 6) now always passes `page_size: 30` and paginates via `next_cursor` — prevents output-cap overflow for portfolios with many open tasks (~113 rows was the observed trigger); Cowork temp-file recovery path documented as unavailable, re-query is the correct recovery
- `daily-brief`: Sessions-DB SQL 429 carry-over — if Step 3 SQL returns a 429, Step 4 skips SQL and goes straight to search+fetch fallback, avoiding wasted retry attempts
- `daily-brief`: External-session classifier now checks the Customer Tracker before badging a non-productboard.com attendee as a customer session; events where PB is the buyer/evaluator (sibling "Trial"/"Eval" internal block, or known vendor domain) are classified as "Vendor / tool eval" and excluded from prep-block creation and Sessions-DB lookup

---

## [2.21.0] — 2026-06-01

### Added
- `daily-brief`: each external customer session card (today + tomorrow) now shows a 2-sentence agreed-topic description — sourced from the Notion session page (`🎯 Session Goals` / `Primary Focus`), Glean (Gong / Slack / Gmail) fallback, then calendar event description; omitted entirely if no signal found
- `daily-brief`: added Glean tools (`mcp__claude_ai_Glean__search`, `meeting_lookup`, `gmail_search`) to the agent tool list for session topic resolution

### Fixed
- `daily-brief`: added 429/SQL failure fallback for Steps 3 and 4 (`notion-search` + `notion-fetch` path) — previously only documented in Step 3, now explicit in Step 4 too
- `daily-brief`: Step 6 now uses the Tasks view URL (pre-filtered, avoids SQL parsing issues) as the preferred query path with SQL as fallback; field name mapping documented (`Task`, `date:Due Date:start`, etc.)
- `daily-brief`: SKILL.md path note — `agents/daily-brief.md` now resolved from plugin root, not skill subdirectory
- `bulk-debrief`: future events filter — events whose `end.dateTime` is still in the future are skipped with a logged reason

---

## [2.20.2] — 2026-05-29

### Fixed
- `email-drafter`: agent no longer fabricates Productboard API endpoint URLs — added mandatory lookup via `support-hub` against `developer.productboard.com/reference/` before including any API link; unknown paths marked `[TO VERIFY]` and flagged in the draft report

---

## [2.20.1] — 2026-05-22

### Fixed
- `email-drafter`: tightened default follow-up structure — explicit "What we covered" and "Next steps" sections with owner/date bullet format
- `post-session-debrief`: session notes and internal Slack debrief templates updated to match new structure (emoji status markers, unified action item format, shorter internal debrief)
- `draft-followup/SKILL.md`: default structure description aligned with updated email-drafter template
- `assistant-onboarding`: corrected stale `about/` reference in default mode description — now correctly references Notion profile page values

---

## [2.20.0] — 2026-05-22

### Changed
- `session-prep` / `bulk --prep`: prep brief rewritten to short, skimmable format — one-line customer snapshot, program phase, goals, "since last session", risks (🔴/🟡), timed agenda, questions
- `session-prepper` / `bulk-prep-week`: customer snapshot now has Notion → Salesforce → Glean fallback chain; missing ARR/tier/AP dates trigger a Salesforce SOQL query before falling back to Glean (tagged `⚠️ [Glean — verify]`)
- `session-prepper` / `bulk-prep-week`: program phase now has Notion AP → Glean fallback if Working Notes are empty or stale
- `session-prepper` / `bulk-prep-week`: Step 2 now explicitly searches the customer's Slack channel via Glean (`source:slack`) for open asks, escalations, and commitments; also searches for open support tickets via Gmail/Glean
- `session-prepper`: AP staleness check added — if Working Notes haven't been updated since the last session, surfaces a prompt in Step 7 offering to update; never updates silently
- `session-prepper` / `bulk-prep-week`: Salesforce tools (`run_soql_query`, `get_username`) added to tools frontmatter

---

## [2.19.0] — 2026-05-22

### Added
- Sessions DB: two new checkbox properties — `Prepped` and `Debriefed` — documented in `context/notion-schema.md`
- `session-prepper`: sets `Prepped = __YES__` after the prep brief is confirmed written (Step 5); signal read by `daily-brief` and `bulk --prep`
- `post-session-debrief`: sets `Debriefed = __YES__` at end of Step 3 when working from real source material; explicitly withheld on placeholder debriefs (transcript unavailable) so sessions stay discoverable for re-debrief
- `bulk-debrief`: `Debriefed = __YES__` is now the primary dedup signal in Step 4C; existing Notes/Draft/Task heuristics demoted to secondary fallback for legacy sessions
- `daily-brief`: Steps 3 & 4 now read `Prepped` directly from SQL instead of fetching page bodies to scan for toggle headings — faster and no per-session page fetches

---

## [2.18.3] — 2026-05-18

### Fixed
- `agents/daily-brief.md`: parse `Working hours` end time from Identity page; use it as the prep-block cutoff instead of hardcoded 18:00; skip block creation (with chat note) when already past working hours
- `agents/daily-brief.md`: add `focusTime` eventType and colorId 7 to focus-block classification; add Calendly external-session pattern
- `agents/daily-brief.md`: fix task tiering to use end-of-week (not 7-day window); remove Priority as a tier-promotion criterion
- `agents/daily-brief.md`: change HTML output theme from light to dark (`#0f172a` / `#1e293b`)

---

## [2.18.2] — 2026-05-18

### Fixed
- `bulk-prep-week` Step 4: dedup query now uses `LIKE 'YYYY-MM-DD%'` for Call Date comparisons — datetime-format fields store ISO timestamps and silently return empty results against date-only range operators
- `bulk-prep-week` Step 4: added duplicate-detection — more than one Planned session page for the same customer + date is flagged as ⚠️ Duplicate pages in the report (both URLs surfaced) rather than silently skipped
- `bulk-prep-week` Step 5: added Active Packages SQL callout requiring triple-syntax for date fields (`"date:Start Date:start"`, `"date:End Date:start"`) — bare column names cause `no such column` errors
- `bulk-prep-week` Step 3: added Glean search scoping rules (date filter required, no broad queries, prefer `chat` for synthesis, skip Glean for already-prepped Case A sessions) to prevent oversized output and context window pressure during bulk runs
- `bulk-prep-week` report table: added ⚠️ Duplicate pages example row; anonymized all example customer names

---

## [2.18.1] — 2026-05-18

### Fixed
- `session-prepper` step 5 (Case C): `Current Account Owner` is now explicitly set on new Session page creation using the Customer.Owner UUID resolved in Step 2 — the Notion propagation automation does not fire reliably on SA-created pages
- `bulk-prep-week` step 5 (Case C override): added matching note that `Current Account Owner` must be passed in the `notion-create-pages` call, using the Customer.Owner UUID confirmed during the ownership check

---

## [2.18.0] — 2026-05-15

### Added
- `context/session-naming-convention.md` — full spec for session naming: `[TYPE][N] Topic` format, type codes (E/A/S), sequential numbering per Active Package + type, and name-resilient duplicate detection rules

### Changed
- `session-prepper` step 5: session lookup now uses triple-key match (customer + date + type) instead of customer + date only; names new sessions per convention (queries Active Package for next sequential number); surfaces rename offer when existing page has non-conforming name; fallback search drops title-prefix (unreliable pre-convention)
- `post-session-debrief` step 1b: duplicate detection upgraded to triple-key match (customer + date + type); surfaces rename offer in final report when kept session has non-conforming name
- `notion-schema.md` Sessions `Name` field: updated to reference naming convention with examples
- `CLAUDE.md` output defaults: voice mandate made explicit (mandatory before any draft, not just skill-invoked); formatting rule for multi-section drafts added

---

## [2.17.1] — 2026-05-15

### Fixed
- `context/project-instructions.md`: Gong transcript URL found in Notion session body is now extracted as a call ID and passed to `Glean:read_document` — URL no longer treated as a terminal result; cleanup step writes URL back to `Gong call` property when blank
- `context/project-instructions.md`: added no-redundant-search rule — if a page ID was already retrieved via `notion-search` in the session, go directly to `notion-fetch(page_id)` rather than re-issuing the query
- `context/project-instructions.md`: added oversized-Glean-result rule — when a search result file exceeds 25,000 tokens, skip `Read` with smaller limits and go directly to bash grep/python3 extraction
- `context/project-instructions.md`: transcript lookup now scopes `app:gong` search more tightly (customer + date) and adds participant-email retry when account-name search returns irrelevant results; broad unscoped Glean search demoted to last resort
- `context/project-instructions.md`: product feedback workflow now defaults to submitting via `feedback_create_notes` immediately after presenting the block, with a post-submission offer to create a tracking Notion Task
- `context/notion-schema.md`: identity resolution step 1 now explicitly uses the email from system context as the `notion-get-users` query — not the display name — to avoid locale/formatting mismatches that return empty

---

## [2.17.0] — 2026-05-15

### Added
- `session-prepper` top-of-file **Context management** section — write-first ordering for compound requests (essential context → primary write → enrich → secondary deliverables → expensive sub-agents) to prevent context-window compaction before any writes land.
- `session-prepper` Step 7 — expanded chat report with **Pre-call checklist** (overdue tasks, space prep, stakeholder pings, materials to have open) and **Session plan** (minute-by-minute flow with contingencies) sections.
- `session-prepper` Step 7 — **Diagram follow-up** block: when a spawned `diagram-builder` sub-agent reports MCP tools unavailable but the parent has them, the parent finishes the Drive upload + Notion attach and verifies the customer-specific output path.
- `session-prep` skill **Compound requests** section — phrase-to-handler map for in-line task creation, Gmail-agenda priority, pre-call checklist, full session plan, and diagram add-ons; codifies context-management ordering for bundled asks.
- `post-session-debrief` Step 2a — large-transcript handling: delegate any transcript >50K chars (or `read_document` "saved to file" responses) to a `general-purpose` sub-agent with a structured extraction template; never `Read` directly in the parent.
- `post-session-debrief` Step 2b — placeholder-debrief branch: when no transcript exists (Zoom + un-indexed Gong), write placeholder notes flagged ⚠️, create a "re-debrief" Task due session-date + 5 business days, skip the email + scorecard, and surface as `⚠️ Partial — transcript pending`.
- `bulk-debrief` — mid-run queue expansion (one round): user can reply "yes and also add X" after the initial queue, and the agent re-runs discovery, merges/dedups, then asks for final confirmation.
- `bulk-debrief` — sub-agent execution mode for queues of 4+ sessions (each session runs in an isolated `general-purpose` child returning a structured summary); inline mode retained for 1–3.

### Changed
- `session-prepper` Step 2 Glean bullet — explicit scoping guidance: date filters and narrow terms by default, prefer `chat` for synthesis over `search`, retry narrower on oversized-output errors instead of saving partial results to temp files. Gmail bullet now specifically searches for customer-proposed agendas from the last 7 days.
- `session-prepper` Step 4 — when Gmail surfaces a customer-proposed agenda, use it as the **primary structure** for the suggested agenda (adapt with scorecard criteria, credit the source); do not rebuild from scratch.
- `session-prepper` Step 5 — query the Sessions DB by full `Customers` relation URL (`= 'https://www.notion.so/<id>'`), never by `LIKE` on a UUID fragment; fall back to `notion-search` by title prefix if the relation query returns empty.
- `diagram-builder` Step 4a — Cowork/subagent note: always attempt the `whoami` / Notion search calls before declaring tools unavailable; tool prefixes can differ from the parent session.
- `bulk-debrief` — accepts a positional natural-language date-range argument (`yesterday`, `today`, `this past week`, `last N days`, `May 11-14`, `2026-05-11..2026-05-14`); legacy `--date` still supported.
- `bulk-debrief` — discovery defaults to `notion-search` (semantic, fuzzy matching) for Customers + Sessions; `notion-query-data-sources` SQL is reserved as a fallback for ambiguous results (it 429s on multi-customer queue discovery).
- `bulk` skill — documents the date-range arg, the search-first discovery model, the inline/sub-agent mode threshold, and ⚠️ Partial flag for transcript-pending sessions in the master summary.
- `session-debrief` skill — Step 1 wired up to the new transcript branches (sub-agent for large transcripts, placeholder branch when transcript is unavailable).

### Fixed
- `session-backfill` — Customers DB title column is `Customer` (not `Name`); enforce in every `notion-query-data-sources` call. GCal `list_events` requires full ISO 8601 timestamps (`2025-09-15T00:00:00Z`), not date-only strings.

## [2.16.0] — 2026-05-14

### Changed
- `session-prepper` calendar lookup now lists all events for the day and scans titles for the customer name as a substring (with/without spaces) — text-search param is unreliable for compound/run-together names.
- Customer DB lookups in `session-prepper` now mandate fuzzy `LIKE '%keyword%'` matching; exact equality on customer name is forbidden.
- Explicit rule against including rollup/formula fields (`ARR`, `Counted Time`, `Needs sync?`) in `query_data_sources` SELECT clauses.

### Added
- `session-prepper` Step 5a — mandatory verification gate after creating a new Session page: re-fetch and confirm the `Customers` relation is populated; retry with a standalone `update_properties` call if empty. Blocks all further writes until confirmed.
- `session-prepper` Step 2 pre-read materials sub-step and Step 4 **Pre-read highlights** brief section — extracts content from customer-shared PPTs/docs with source refs and 🎯 pointers, grouped by theme for live-call skimmability.
- `session-prep` skill + `session-prepper` Step 7 — optional HTML visual session-flow artifact for Discovery / Kick-off sessions (Intro → Upfront Contract → Agenda Topics → Closing).

## [2.15.0] — 2026-05-14

### Changed
- `agents/account-setup.md` Step 2: SOQL now pulls **all** Closed-Won opps for the account (ordered ASC, no `LIMIT 1`) and collapses expansion/co-term opps by matching service dates — establishes the contract-year set used to build one Active Package per year
- `agents/account-setup.md` Step 3: Master Package mapping is now **per contract year** (not global). Null `Services_Plan__c` fallback is deterministic — ARR ≥ $30K defaults to `AISE No Services`; ARR < $30K asks `Complimentary` vs `AISE No Services` (Complimentary rare, exception only)
- `agents/account-setup.md` Step 4.B: replaced single-package logic with one Active Package per contract year — current year `Active? = YES`, historical years `Active? = NO` + `Status = Package Expired`. AISE-No-Services / Complimentary engagements use `Adopting` (current) / `Package Expired` (historical) — never `No services` (not a valid enum)
- `agents/account-setup.md` Step 5.2: history toggle (`📋 Account History — inherited [YYYY-MM-DD]`) is now **mandatory** for inherited customers — appended to existing template content via `update_content`, never replacing; skipping requires explicit opt-out
- `agents/account-setup.md` Guardrails: `Current Account Owner` write-on-create now applies to **every** Active Package created (current + all historical), not just the new active one — prevents historical packages from being invisible to owner-filtered views

### Fixed
- `context/notion-schema.md` § Active Package Status: clarified that there is no `No services` option on the Status field; the no-services state is expressed via Customer `Account Status = Active (no Services)` + `Master Package = AISE No Services`

---

## [2.14.0] — 2026-05-14

### Changed
- `skills/assistant-improvement/SKILL.md`: now captures **preference signals** (sequencing, depth, output shape, tool routing, interaction style, positive confirmations of non-obvious choices) in addition to failures. Step 2 split into `2a — Failures` and `2b — Preferences`; Step 3 maps preferences to source layers; Step 4 output groups signals into `Failures` and `Preferences to encode` sections so the coding agent can prioritize. Skill description and final summary line updated.

---

## [2.13.0] — 2026-05-14

### Added
- `agents/post-session-debrief.md`: new mandatory **Step 1b** — fetch the `AISE Assistant Preferences` Voice section before any drafting; pass it verbatim into inline `session-summarizer` / `email-drafter` / `kdd-builder` so they don't re-fetch
- `agents/email-drafter.md`, `agents/session-summarizer.md`, `agents/kdd-builder.md`, `agents/engagement-planner.md`: new mandatory voice-fetch step before drafting begins — always pulls fresh from Notion, falls back to `context/communication-style-guide.md` if the page is missing
- `context/project-instructions.md` §6: new **Mandatory pre-draft step** codifying the voice-fetch rule across every drafting workflow

### Fixed
- `agents/post-session-debrief.md` Step 13: documented Notion-flavored markdown rules for Active Package body writes — `<details><summary>` for collapsibles (tab-indented children), native `<table>` for tabular data, no pipe tables, no `\n` literals in `new_str`. Prevents the page rendering as one unreadable escaped blob.

---

## [2.12.0] — 2026-05-14

### Added
- `context/score-cards.md`: new `🗣️ Sync / Office Hours` scorecard for recurring customer syncs and lightweight check-ins (lower-ceremony than Architecting / QBR — measures responsiveness, momentum, early risk surfacing)

### Fixed
- `agents/notion-writer.md`, `context/notion-schema.md`, `agents/post-session-debrief.md`: corrected the `userDefined:` prefix rule — apply it only to properties literally named `URL` or `id`; all other URL-typed properties (`Gong call`, `SFDC`, `Slack Channel`, `Domain`) use the property name directly with no prefix
- `agents/post-session-debrief.md`: added duplicate-session detection after Session resolution (same Customer + same `Call Date`) that marks duplicates as `Canceled` + `Do not count` and links them to the kept session
- `agents/post-session-debrief.md`, `agents/email-drafter.md`: added timezone parsing guidance for times pulled from email/`.ics` bodies — cross-verify against Calendar events, render both zones in customer-facing drafts
- `agents/post-session-debrief.md`: documented the Gmail-MCP draft-replacement caveat — no `update_draft` / `delete_draft` exists, so corrections require creating a new draft and trashing the old one manually

---

## [2.11.0] — 2026-05-11

### Added
- `context/notion-schema.md`: added `Gong call` (url) and `Spark conversation` (checkbox) to Sessions writable fields; added `Related Tasks` (relation → Tasks DB) to Sessions writable fields; added `Parent Company` (text) to Customers writable fields for parent-child/shared-contract accounts
- `agents/post-session-debrief.md`: set `Gong call` URL and evaluate `Spark conversation` on every session update (step 3); link new Tasks to session via `Related Tasks` after create
- `agents/session-summarizer.md`: set `Gong call` and `Spark conversation` in Notion update step; populate `Related Tasks` on Session when creating Tasks
- `agents/session-backfill.md`: include `Gong call` and `Spark conversation` in session create field list
- `agents/account-setup.md`: include `Gong call` and `Spark conversation` in session backfill creates; check for parent company during research and set `Parent Company` on Customer create
- `agents/notion-writer.md`: document `Gong call` and `Spark conversation` rules in Sessions project-specific section

### Fixed
- `context/notion-schema.md`: removed stale fields (`Next Call (raw)`, `Counted/Real` from Customers read-only; `Packages → Master Packages` from Customers writable; `Source Session` rollup from Tasks read-only); corrected `All Packages` from "rollup" to "relation"; added undocumented read-only fields (`P-Score`, `Package Tier` on Customers; `Services Tier`, `Tier (formula)`, `Package Tier` on Active Packages)

---

## [2.10.0] — 2026-05-11

### Added
- `agents/session-backfill.md`: new agent for backfilling historical post-sales sessions from GCal + Gong + Notion meeting notes for already-configured customers; bootstraps missing Active Package from Salesforce if needed
- `skills/session-backfill/SKILL.md`: new `/session-backfill` command with single-customer and `--bulk mine` modes; includes `--since`, `--dry-run` flags and natural language equivalents
- `CLAUDE.md`: added `/session-backfill` entries to the command table and agent registry

### Changed
- `agents/account-setup.md`: added Google Calendar to the session discovery step (GCal events matched by customer name/domain, merged with Gong by date ±1 day); GCal-only sessions flagged in the proposal with a no-transcript note; added `Source` field to the session creation schema; added filter rule for generic GCal-only event titles
- `skills/customer-setup/SKILL.md`: documented Google Calendar as a discovery source in the `--research` mode context block

---

## [2.8.2] — 2026-05-10

### Fixed
- `context/notion-schema.md`: rewrote Identity resolution procedure — removed pointer-file and glob-fallback steps; Notion lookup (`notion-get-users` + `AISE Identity` page) is now the sole resolver
- All agents and skills: replaced every stale `about/identity.md`, `about/voice.md`, and `about/workspace.md` reference with the canonical Notion page equivalent (`AISE Identity`, `AISE Assistant Preferences` Voice section, `AISE Assistant Preferences` Workspace section)
- `context/communication-style-guide.md`, `context/project-instructions.md`, `context/notion-writer-playbook.md`: updated all `about/voice.md` pointers to `AISE Assistant Preferences` Notion page
- `skills/assistant-help/SKILL.md`: Personal config section rewritten to describe Notion pages instead of local `about/` files
- `CLAUDE.md`: updated agent table entries for `email-drafter` and `assistant-onboarding`, and `/assistant-setup` command description — removed local file references

---

## [2.8.1] — 2026-05-10

### Fixed
- `agents/notion-integrity-check.md`: added `notion-get-users` to tools frontmatter; added Notion-only identity resolution preamble; replaced stale `about/identity.md` UUID reference with preamble-resolved UUID
- `agents/notion-writer.md`: same — tools, preamble, and all `about/identity.md` references updated; preamble now the sole identity source before every write
- `agents/sf-backfill.md`: same — added `notion-get-users` + `notion-search` to tools; added preamble; Step 1 UUID reference updated
- All agents (aise-assistant + aise-leadership): unified "not found" handling — every agent now outputs "AISE Identity page not found — run `/assistant-setup` to configure your profile." and stops; previously some agents noted the gap and continued with defaults, others asked once if needed
- `agents/daily-brief.md`: identity not-found path now stops instead of defaulting to `Europe/Prague` timezone and continuing
- `agents/diagram-builder.md`: added not-found stop to the identity resolution block
- `skills/daily-brief/SKILL.md`: updated resolver description from two-path (CLI + Cowork) to Notion-only to match current agent behavior

---

## [2.8.0] — 2026-05-10

### Changed
- `agents/assistant-onboarding.md`: removed Path B (local file read via `~/.claude/aise-assistant.datadir`) from Step 1 — Notion-only resolver now; removed Step 7 (local `about/` file writes via Bash mkdir + Write tool) entirely — Notion profile pages are the only output; updated `--reset` mode to not delete local files; updated frontmatter description, end-state line, and Step 8 report to reference Notion pages instead of local files; guardrails updated to reflect Notion-only output
- `agents/bulk-account-setup.md`: replaced PLUGIN_DATA_DIR Step A resolver with Notion-only resolver (`notion-get-users` + `AISE Identity` page)
- `agents/bulk-prep-week.md`: replaced PLUGIN_DATA_DIR Step A resolver with Notion-only resolver
- `agents/daily-brief.md`: merged Option 1 (CLI local file) + Option 2 (Cowork Notion) + Option 3 (fallback) into a single universal Notion-only identity resolution path
- `agents/diagram-builder.md`: replaced PLUGIN_DATA_DIR resolver in Content rules with Notion-only resolver
- `agents/notion-ask.md` Step 4.1: removed Step A (local file read), Step B is now the sole resolver renamed to "Resolve identity"
- `CLAUDE.md`: path resolver note updated to Notion-only (removed CLI pointer-file path); per-user file table rows updated to reference `AISE Identity` and `AISE Assistant Preferences` Notion pages; `tracker-memory.md` row kept pointing to local file; Install/upgrade section updated; Output defaults updated
- `skills/aise-context/SKILL.md`: removed CLI section, Notion-only resolver

---

## [2.7.1] — 2026-05-10

### Fixed
- `agents/notion-ask.md` Step 4.1: replaced broken Bash `cat` resolver (Bash not in tools list) with two-path Read tool resolver — Step A reads `~/.claude/aise-assistant.datadir` + `identity.md`; Step B falls back to `notion-get-users` + `notion-search("AISE Identity — {display_name}")` + `notion-fetch` for Cowork compatibility

---

## [2.7.0] — 2026-05-10

### Changed
- `agents/assistant-onboarding.md` Step 1 Path A: replaced single `AISE Profile` page search with three separate searches — `AISE Identity — {display_name}` (identity fields) and `AISE Assistant Preferences — {display_name}` (Voice + Workspace); both work in CLI and Cowork
- `agents/assistant-onboarding.md` Step 7b: replaced single `AISE Profile` Notion page write with a 3-page hierarchy — parent `AISE Profile`, child `AISE Identity`, child `AISE Assistant Preferences`; parent created with `workspace` parent type (private); children created with `page_id` parent pointing to the parent; never touches `AISE Leadership Preferences` or `AISE Leadership Team Roster` pages
- `agents/daily-brief.md` Step 1 Option 2: updated Notion profile lookup to use `AISE Identity — {display_name}` page instead of `AISE Profile`; simplified to `notion-get-users` + identity page search only (Preferences page not needed for brief)
- `agents/daily-brief.md` Step 1 Option 3 fallback message updated to reference `AISE Identity page`
- `CLAUDE.md`: Cowork path resolver updated to use `AISE Identity` + `AISE Assistant Preferences` page names; "Finding these files" row updated to match
- `skills/aise-context/SKILL.md`: Cowork resolver updated to search `AISE Identity` and `AISE Assistant Preferences` instead of `AISE Profile`

---

## [2.6.3] — 2026-05-10

### Fixed
- `agents/daily-brief.md` Step 1: `notion-get-users` now queries by **first name only** (e.g. `"klara"`) instead of full display name — Notion user search does not reliably match compound names
- `agents/daily-brief.md` Steps 3 & 4: Sessions DB date filter now uses `"date:Call Date:start"` (the correct Notion SQL expanded column name) instead of the bare `"Call Date"` which does not exist
- `agents/daily-brief.md` Step 8: Added Cowork delivery path — in sandbox mode, HTML is written via the Write tool and delivered via `mcp__cowork__present_files`; bash `cp`/`mkdir`/`open` remain CLI-only
- `context/notion-schema.md`: Added ⚠️ callout under Sessions field reference warning that SQL date queries must use `"date:Call Date:start"` not `"Call Date"`

---

## [2.6.2] — 2026-05-10

### Fixed
- `skills/daily-brief/SKILL.md`: Step 1 now uses the two-path resolver (CLI: pointer file → local files; Cowork: `notion-get-users` + `notion-search` + `notion-fetch`) instead of bare `about/identity.md` read

---

## [2.6.1] — 2026-05-10

### Fixed
- `skills/assistant-setup/SKILL.md`: removed all osascript and Cowork file-writing instructions; skill now delegates entirely to `agents/assistant-onboarding.md` which implements the Notion private page pattern
- `skills/aise-context/SKILL.md`: replaced osascript resolver with two-path identity resolution (CLI: Read pointer file; Cowork: `notion-get-users` + `notion-search` + `notion-fetch`)

---

## [2.6.0] — 2026-05-10

### Added
- `assistant-onboarding` Step 7b: after writing local `about/` files, creates or updates a **private Notion profile page** (`AISE Profile — {display_name}`) in the user's Private sidebar section; page stores Identity, Voice, and Workspace sections; visible only to the current user, not teammates
- `assistant-onboarding` Step 1 Path A: checks for existing Notion profile page via `notion-search` + `notion-fetch` before querying local files; treats Notion as authoritative when both sources differ

### Changed
- `assistant-onboarding`: removed all Google Drive sync from Step 7b (replaced by Notion private page); Drive tools removed from agent tools list
- `daily-brief` Step 1: Option 2 resolver changed from Google Drive (`search_files` + `read_file_content`) to Notion profile page (`notion-get-users` + `notion-search` + `notion-fetch`); Drive tools removed from agent tools list; Option 3 fallback updated to "AISE Profile page not found" messaging
- `CLAUDE.md` path resolver: Cowork mode now reads from Notion private profile page instead of Google Drive or osascript; osascript references removed throughout

---

## [2.5.2] — 2026-05-10

### Fixed
- `assistant-onboarding`: added a hard "no early exits" rule at the top of the procedure; "already onboarded" default-mode path now explicitly says "Skip Steps 2–7, go directly to Step 7b" instead of a soft suggestion; Step 7b heading now marked `⚠️ ALWAYS RUN`

## [2.5.1] — 2026-05-10

### Fixed
- `assistant-onboarding`: Step 7b (Drive sync) now runs even when all local files are already populated — previously the "already onboarded" exit skipped it, so Drive was never written on the first test run

## [2.5.0] — 2026-05-10

### Added
- `assistant-onboarding`: Step 7b — after writing local `about/` files, mirrors `identity.md`, `voice.md`, `workspace.md` to a `aise-assistant/` folder in Google Drive; enables Cowork sessions to retrieve personal config via Drive MCP when `~/.claude/` is inaccessible
- `daily-brief`: Google Drive fallback in Step 1 — when Read tool returns "outside connected folders" (Cowork mode), searches for `aise-assistant/identity.md` in Drive and reads it via `read_file_content`; Notion `notion-get-users` remains the last-resort fallback

## [2.4.5] — 2026-05-10

### Fixed
- `session-start.sh`: added step 0 (use `$CLAUDE_PLUGIN_DATA` when `about/identity.md` already exists there — populated install with any directory suffix) and changed step 4 final fallback to prefer `$CLAUDE_PLUGIN_DATA` over a generic default path (fresh install with any suffix); pointer file now always contains a path accessible in the current execution context

## [2.4.4] — 2026-05-10

### Fixed
- `session-start.sh`: added step 0 (use `$CLAUDE_PLUGIN_DATA` when `about/identity.md` already exists there — Cowork populated) and changed final fallback to prefer `$CLAUDE_PLUGIN_DATA` over a Linux-VM home path (Cowork fresh install); pointer file now always contains a path accessible in the current execution context

## [2.4.3] — 2026-05-10

### Fixed
- `daily-brief`, `bulk-account-setup`, `bulk-prep-week`, `diagram-builder`: added explicit PLUGIN_DATA_DIR resolver as the first step — Read `~/.claude/aise-assistant.datadir` before any `about/` file access; prevents fallback to the volatile `CLAUDE_PLUGIN_DATA` env variable (which points to `/Library/Application Support/Claude/` in desktop contexts and is outside connected folders)

## [2.4.2] — 2026-05-10

### Fixed
- `setup-connections.sh`: refactored SF detection into helper functions (`_sf_in_config`, `_find_sf`, `_sf_auth_ok`) for more robust Salesforce CLI and MCP presence checking
- SF binary lookup now searches multiple candidate paths beyond `$PATH` (npm global, homebrew, `.local/share`, etc.)
- SF auth check now reads credential files directly (`~/.sfdx/*.json`, `~/.sf/credentials.json`) without requiring Node on PATH

---

## [2.4.1] — 2026-05-10

### Fixed
- `setup-connections.sh --check`: now reads `~/.claude/claude_desktop_config.json` (not `mcp.json`) for the Salesforce MCP presence check
- Nerd callout now fires only when both Salesforce CLI and Salesforce MCP are confirmed present (previously fired on CLI alone)
- MCP-missing message in `--check` mode now prints the correct `claude mcp add` install command instead of "Run without --check to add it"

---

## [2.4.0] — 2026-05-10

### Added
- Proactive improvement nudge — after any skill run where efficiency gaps are observed (redundant tool calls, missing pre-loadable context, sub-optimal routing, mid-run corrections), Claude surfaces a one-line prompt suggesting the user run `/assistant-improvement` and send the output to the plugin admin

---

## [2.3.0] — 2026-05-10

### Added
- `/assistant-help --whatsnew` flag — reads `CHANGELOG.md` and surfaces the latest version changes (latest MAJOR/MINOR entry + any subsequent patches) instead of the full command reference; also triggered by natural language phrases like "what's new", "what changed", "latest changes"

---

## [2.2.0] — 2026-05-10

### Added
- `/assistant-improvement` skill — after a bad skill run, analyze what went wrong from conversation history and output a copyable coding-agent prompt with exact plugin, files, and fixes; no writes, output only

---

## [2.1.0] — 2026-05-10

### Removed
- `/report` skill and `report-builder` agent moved to `aise-leadership` — reporting is a leadership-only capability

---

## [2.0.1] — 2026-05-10

### Fixed
- Replace stale `brew install sf-mcp-server` Salesforce install instructions with the correct three-step flow: `npm install -g @salesforce/cli`, `sf org login web`, `claude mcp add salesforce -- npx -y @salesforce/mcp`
- `setup-connections.sh`: check for `sf` CLI instead of the old binary; mcp.json entry now uses `npx -y @salesforce/mcp`; removed email-lookup block (no longer needed); downgraded missing-CLI from a hard exit to a warning so the MCP entry is still written
- Added a friendly easter egg when Salesforce is already installed

---

## [2.0.0] — 2026-05-09/10

### Added
- `customer-plan-next` agent and `/customer-plan-next` command (later consolidated into `/customer-plan --next`)
- Customer and Active Package page templates with agent-readable sections
- `/notion-sync --owner` — push `Customer.Owner` → `Current Account Owner` on Sessions, Tasks, and Active Packages (`--mine` / `--global`)
- `/notion-sync --renewals` — set `Status = Renewal` on active packages ending within N days; `--dry-run` previews without writing
- `.claude-plugin/marketplace.json`: renamed marketplace from `aise-tools` to `aise-toolkit`; added `aise-leadership` as a second plugin entry

### Changed
- Consolidated 7 skills into 3 multi-mode commands: `/notion-sync --sf|--owner|--renewals`, `/bulk --debrief|--prep`, `/customer-plan --next|--full`
- Active Package schema: replaced two-field customer pattern (`Active for (1:N)` + `Customer (M:N)`) with a single `Customer` relation (Formulas 2.0); on-expiry is now just `Active? = __NO__`
- `notion-schema.md`: corrected `Account Status`, `Session.Type`, `Session.Call Status`, `Task.Status`, `Priority`, `AI Ready`, `Industry` field values; added `Renewal Forecast`; added Active Package Status behavioral notes (Renewal 90-day trigger, $30K ARR threshold, Package Expired terminal state); added 4 Known Gotchas; extracted identity resolution into a canonical three-path chain
- `notion-integrity-check.md`: updated for Formulas 2.0 schema; added 🟦 Field hygiene checks for null/date-mismatched `Consumed Package` with `--fix` logic
- `notion-writer.md`: Tasks after a session must set `Consumed Package` (inherit from Source Call or date-match)
- Session page structure driven from Notion templates rather than hard-coded agent logic
- Scoped Gong queries to post-sales calls; skip Gmail lookups in delegated (teammate) mode
- `skills/assistant-help/SKILL.md`: rewritten with multi-mode command flag tables and examples
- `CLAUDE.md`, `README.md`: removed local-dev-only references; corrected command counts and family listings

### Fixed
- Glean `read_document`: extract `id` field from search results instead of passing URL string
- `post-session-debrief`: fetch Customer page before writing; fall back to appending `## 📋 Account Notes` on non-standard templates
- Removed `## 🤝 PB Account Team` section from Customer page template throughout
- `notion-sync-owner`: hyphen-stripped URL LIKE pattern; drift filter pushed into WHERE clause; fallback to `notion-get-users` on missing identity file
- `notion-flag-renewals`: identity resolution conditional on `--global`; three-path chain; date/status filtering in SQL
- gitignore `.claude/` from distribution; full plugin review fixes

---

## [1.2.3] — 2026-05-08

### Fixed
- Resolve persistent plugin data dir via pointer file — never use `$CLAUDE_PLUGIN_DATA`

---

## [1.2.2] — 2026-05-08

### Changed
- Unify transcript lookup logic into a single canonical source across session-summarizer and post-session-debrief

---

## [1.0.1] — 2026-05-08

### Changed
- Revise versioning rules — MAJOR for any capability roster change, MINOR for functional tweaks

---

## [1.0.0] — 2026-05-08

### Added
- Initial release of aise-assistant plugin
- Marketplace metadata (`marketplace.json`) and auto version-bump on package
- Full agent roster: session-prepper, session-summarizer, post-session-debrief, engagement-planner, account-setup, email-drafter, kdd-builder, notion-writer, context-keeper, diagram-builder, sf-backfill, support-hub, notion-integrity-check, whats-new, assistant-onboarding, bulk-debrief, bulk-prep-week, bulk-account-setup, daily-brief, customer-plan-next, workflow-advisor
- Slash command families: `customer-*`, `session-*`, `draft-*`, `notion-*`, `assistant-*`

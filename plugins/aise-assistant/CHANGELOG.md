# Changelog

All notable changes to aise-assistant are documented here.
Format: `## [version] — YYYY-MM-DD` followed by bullet points grouped by type.

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

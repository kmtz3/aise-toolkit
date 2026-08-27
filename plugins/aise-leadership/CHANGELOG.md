# Changelog — aise-leadership

## [1.12.10] — 2026-08-27

### Fixed
- `context/planhat-schema.md` and `context/notion-planhat-field-mapping.md` — synced from aise-assistant: Gong call recording links now go to `custom.Call Recording`, not `custom.Gong URL`. `custom.Gong URL` is still read (Gong's own native sync writes it on the Conversation it creates) but never written by any agent going forward.

---

## [1.12.9] — 2026-08-27

### Added
- `context/planhat-schema.md` § Conversation type mapping — synced from aise-assistant. Notes that `👾 Gong Call` Conversations cannot be matched to their GCal-synced target by ID (Gong Call `externalId` is `{gongCallId}-{salesforceAccountId}`, `Conversation` has no `sourceId`, and neither the Gong MCP tools nor Glean's indexed Gong metadata expose a calendar event ID) — matching instead uses a weighted score across attendee overlap, subject similarity, and date proximity. See aise-assistant's new `ph-reconcile-gong-gcal` agent.

---

## [1.12.8] — 2026-08-27

### Added
- `context/planhat-schema.md` § Session record resolution — synced from aise-assistant. The GCal-event-ID ladder (Conversation by `externalId` → Task by `sourceId`, both ID shapes → title/company/date fallback → create as last resort with the event ID set), and the rule that a create without a dedup key is a bug.
- `context/planhat-schema.md` § Rich Text Field Formatting — canonical prep-brief structure table, pre-write sanity checklist, and the named gold-standard record (Task `6a73dff47c78485e7c3daa27`).

---

## [1.12.7] — 2026-08-27

### Changed
- `context/planhat-schema.md` § Rich Text Field Formatting — synced from aise-assistant: canonical prep-brief structure table (11 fixed sections), pre-write sanity checklist, the rule that the format governs every rich-text field (plain text and `\n`-separated text banned), and the named gold-standard record (Task `6a73dff47c78485e7c3daa27`). Guardrail added that existing Planhat records predate the en-dash rule and are not the style reference.

---

## [1.12.6] — 2026-08-27

### Changed
- `context/` synced from aise-assistant: `planhat-schema.md` rewrites the Rich Text Field Formatting section into the full verified `ph-editor` tag reference (paragraphs, classed `ul`/`ol` lists, blockquote, `hr`, table) and corrects the earlier "never use `<ol>`/`<ul>`" guidance — bare lists were the actual cause of rendering mangling, not lists themselves. `notion-planhat-field-mapping.md` and `planhat-user-profile.md` updated to the same convention.
- `context/session-artifact-convention.md` — new file synced from aise-assistant: naming and Drive-folder convention for session artifacts (prep briefs, KDDs, facilitation guides, debrief exports), with Salesforce duplicate-account and Planhat `externalId` write-failure guardrails.

---

## [1.12.5] — 2026-08-25

### Changed
- `context/` synced from aise-assistant: `communication-style-guide.md` and `planhat-schema.md` repointed voice source of truth to the Planhat User record (`custom.AISE Profile preferences` / `custom.AISE Identity`), corrected Company/Conversation custom-field documentation (renamed and removed fields, 20+ previously missing fields, `🔁 Renewal Call` added to the Conversation `type` options), and dated the Company custom-field section as last verified 2026-08-25.

---

## [1.12.4] — 2026-08-25

### Changed
- `context/` synced from aise-assistant: `planhat-schema.md` gains a new § Known non-sessions (do not recreate) table for calendar events that looked like delivered sessions but were cancelled or never held.

---

## [1.12.3] — 2026-08-24

### Changed
- `context/` synced from aise-assistant: new `custom.Link to PB Note` Conversation field documented in `planhat-schema.md` (written by aise-assistant's `/log-feedback` skill when closing out a Product Feedback Task).

---

## [1.12.2] — 2026-08-21

### Changed
- `context/` synced from aise-assistant: new `context/initiatives/` folder (time-boxed GTM/adoption motions, e.g. Spark in Practice), initiative-override callouts in `project-instructions.md` and `session-naming-convention.md`, and pending Planhat schema/field-mapping/user-profile updates that hadn't been synced yet.

---

## [1.12.1] — 2026-08-20

### Fixed
- `agents/assistant-onboarding.md`, `agents/context-keeper.md`, `agents/notion-completion-fix.md`, `agents/report-builder.md`: corrected the format of `custom.AISE Identity`, `custom.AISE Profile preferences`, and `custom.AISE Tracker Memory` on the Planhat User record — these are HTML rich-text fields (`<p>Key: value</p>` per line, `<ul><li>` for bullets), not `\n`-separated plain text. Planhat silently strips bare `\n` on write, so a prior plain-text write would collapse into one run-on string. All four agents now strip tags before parsing and write `<p>`/`<li>`-wrapped HTML back.
- `agents/assistant-onboarding.md`: added a mandatory post-write verification step — immediately re-reads a just-written rich-text field to confirm the `<p>` boundaries survived, since a successful (HTTP 200) write doesn't guarantee the content landed correctly.

---

## [1.12.0] — 2026-08-16

### Changed
- `/assistant-setup` onboarding rewritten to write directly to `custom.AISE *` fields on the user's Planhat User record instead of Notion pages — `custom.AISE Identity` and `custom.AISE Profile preferences` are shared with aise-assistant (same person, one identity, one voice); a new `custom.AISE Leadership Workspace` field holds report templates, cadence formats, Gong keywords, Slack channels, and coordinators.
- Team roster is no longer a stored page or field — `report-builder` and `notion-completion-fix` now resolve "who's on my team" live from Planhat's native `managers`/`teams` fields, falling back to `notion-get-users` per teammate only when a Notion UUID is needed for ownership scoping.
- `context-keeper`'s voice-preference and cross-team-pattern rows now target the shared Planhat fields (`custom.AISE Profile preferences`, `custom.AISE Tracker Memory`), matching the aise-assistant copy.
- Simplified `notion-writer`, `sf-backfill`, `notion-ask`, `notion-integrity-check` to resolve the Notion UUID directly via `notion-get-users` — they never needed the full identity fetch, just ownership scoping.
- Agents that previously hard-stopped on an empty profile (`notion-completion-fix`, `report-builder`) now auto-migrate from a legacy Notion page if one exists, or run `assistant-onboarding` inline if nothing exists anywhere, instead of telling the user to go run `/assistant-setup` themselves.
- `context/planhat-user-profile.md` synced from aise-assistant with the full field map, team-roster live-query procedure, and auto-resolve procedure.

---

## [1.11.2] — 2026-08-10

### Changed
- `context/notion-planhat-field-mapping.md`: resynced from aise-assistant v2.34.0 — added bolded `companyId`-required notes atop the Sessions→Conversation and Tasks→Task field-mapping tables.

---

## [1.11.1] — 2026-08-08

### Fixed
- Checkpoint & resumability (`notion-integrity-check`, `notion-completion-fix`): checkpoints now record the flags/args that shaped the run (`--customer`, `--owner`, `--past`) and must be verified against the current invocation before being trusted, rather than resuming silently against a stale or scope-mismatched checkpoint.

---

## [1.11.0] — 2026-08-08

### Added
- Checkpoint & resumability for `notion-integrity-check` and `notion-completion-fix`: each now writes a `/tmp/<agent-name>-<scope>.json` checkpoint after each completed fix/candidate, resumes from the next incomplete item on a subsequent run, and deletes the checkpoint on full completion. Mirrors the pattern added to the aise-assistant versions of these agents and to aise-assistant's bulk agents.

---

## [1.10.5] — 2026-08-08

### Changed
- `context/notion-planhat-field-mapping.md`: resynced from aise-assistant v2.32.0 — added Brandwatch/Cision dual-email EndUser resolution note.

---

## [1.10.4] — 2026-08-07

### Changed
- `context/notion-schema.md`, `context/notion-planhat-field-mapping.md`, `context/planhat-schema.md`, `context/planhat-user-profile.md`: resynced from aise-assistant v2.31.0.

---

## [1.10.3] — 2026-08-06

### Changed
- `context/notion-planhat-field-mapping.md`: resynced from aise-assistant v2.30.3 — corrected Planhat Conversation field name from `endUsers` (camelCase) to `endusers` (all lowercase); Planhat silently drops writes to the wrong field name without an error.

---

## [1.10.2] — 2026-08-06

### Changed
- `context/notion-planhat-field-mapping.md`: resynced from aise-assistant v2.30.2 — removed remaining `Spark Conversation`/`activityTags` references (field already dropped as non-writable via MCP in a prior sync).

---

## [1.10.1] — 2026-08-06

### Changed
- `context/planhat-schema.md`: resynced from aise-assistant v2.30.1 — Task auto-Conversation behavior corrected (transition-only trigger, `type` defaults to `"note"`, shared Task/Conversation `_id`), `📦 Other` Conversation type mapping fixed, Entrust → Onfido Ltd domains alias added.

---

## [1.10.0] — 2026-08-05

### Changed
- `context/planhat-schema.md`, `context/project-instructions.md`: caught up to aise-assistant's canonical copies — resynced via `scripts/sync-context.sh` after two prior aise-assistant context commits (`7365582`, `9b59412`) landed without a follow-up sync. Picks up: `custom.Priority` mapping fix, `activityTags` read-only caveat, task dedup pattern fix, `Session Length (h)` → `custom.Call Duration` mapping, `custom.Prep Notes` field, PH-migration-gate section, `create_model_record` `PARAMETERS`-not-`DATA` param fix, Gong-MCP-preference note, and the Fin chat escalation section (§10).

---

## [1.9.13] — 2026-07-31

### Changed
- `context/project-instructions.md`: Planhat transcript field rule — write Gong transcript to Conversation.transcript after every debrief — synced from aise-assistant v2.29.5

---

## [1.9.12] — 2026-07-31

### Changed
- `context/project-instructions.md`: Planhat dual-write fix — update both Task and Conversation models with same ID; HTML-only formatting rule for descriptions — synced from aise-assistant v2.29.4

---

## [1.9.11] — 2026-07-31

### Changed
- `context/communication-style-guide.md`: added explicit em dash ban section – synced from aise-assistant v2.29.3

---

## [1.9.10] — 2026-07-31

### Changed
- `context/communication-style-guide.md`: added subject line format convention — use `Productboard + [Customer] – [Topic]` (never "x"); synced from aise-assistant v2.29.2

---

## [1.9.9] — 2026-07-15

### Fixed
- `context/notion-schema.md`: synced from aise-assistant v2.28.1 — Sessions create rule updated: `Current Account Owner` must be set explicitly on create; removed "leave blank" instruction

---

## [1.9.8] — 2026-07-15

### Changed
- `context/` synced from aise-assistant v2.28.0: `notion-schema.md` updated with Planhat cross-reference; `planhat-schema.md` and `notion-planhat-field-mapping.md` added; `project-instructions.md` updated with Planhat connector entry

---

## [1.9.7] — 2026-06-24

### Fixed
- `context/` synced from aise-assistant v2.23.3: Gmail copy-paste safety rules added to `communication-style-guide.md` — no markdown tables, no markdown bold in draft body, next steps as flat bulleted list

---

## [1.9.6] — 2026-06-15

### Fixed
- `context/` synced from aise-assistant v2.23.2: Gong search strategy in transcript lookup order — `after:` date filter + people-keywords; two-attempt rule before placeholder branch

---

## [1.9.5] — 2026-06-15

### Changed
- `context/` synced from aise-assistant v2.23.1: `notion-schema.md` Customers DB updated with `Spark Customer Journey`, `Ignite Journey Last Edited`, `Igniting?` fields and read-only Ignite formulas

---

## [1.9.4] — 2026-05-22

### Changed
- `context/` synced from aise-assistant v2.19.0: `notion-schema.md` Sessions field reference updated with `Prepped` and `Debriefed` checkbox properties

---

## [1.9.3] — 2026-05-15

### Changed
- `context/` synced from aise-assistant v2.18.0: added `session-naming-convention.md`; updated `notion-schema.md` Sessions Name field to reference the new convention

---

## [1.9.2] — 2026-05-15

### Fixed
- `context/` synced from aise-assistant v2.17.1: Gong transcript lookup improvements, no-redundant-search rule, oversized-result bash fallback, product feedback auto-submit, and identity resolution email-first fix

---

## [1.9.1] — 2026-05-14

### Fixed
- `context/notion-schema.md`: synced from aise-assistant — clarification that the Active Package `Status` field has no `No services` option; the no-services state is expressed via Customer `Account Status = Active (no Services)` + `Master Package = AISE No Services`

---

## [1.9.0] — 2026-05-14

### Changed
- `skills/assistant-improvement/SKILL.md`: now captures **preference signals** (sequencing, depth, output shape, tool routing, interaction style, positive confirmations of non-obvious choices) in addition to failures. Step 2 split into `2a — Failures` and `2b — Preferences`; Step 3 maps preferences to source layers; Step 4 output groups signals into `Failures` and `Preferences to encode` sections so the coding agent can prioritize. Mirrors the aise-assistant v2.14.0 change.

---

## [1.8.3] — 2026-05-14

### Fixed
- `context/project-instructions.md`: synced from aise-assistant — new Mandatory pre-draft step (fetch `AISE Assistant Preferences` Voice section before any draft, always pull fresh)

---

## [1.8.2] — 2026-05-14

### Fixed
- `agents/notion-writer.md`: corrected the `userDefined:` prefix rule — apply it only to properties literally named `URL` or `id`; all other URL-typed properties use the property name directly with no prefix
- `context/notion-schema.md`, `context/score-cards.md`: synced from aise-assistant (userDefined: prefix correction + new Sync / Office Hours scorecard)

---

## [1.8.1] — 2026-05-11

### Fixed
- `context/notion-schema.md`: synced from aise-assistant — new session fields (`Gong call`, `Spark conversation`, `Related Tasks`), `Parent Company` on Customers, stale field removals, and undocumented read-only field additions

---

## [1.8.0] — 2026-05-11

### Removed
- `skills/commit/SKILL.md`: removed `/commit` as a user-facing skill — moved to dev-only `.claude/commands/commit.md` in the toolkit root

---

## [1.6.2] — 2026-05-10

### Fixed
- `context/notion-schema.md`: rewrote Identity resolution procedure — removed pointer-file and glob-fallback steps; Notion lookup (`notion-get-users` + `AISE Identity` page) is now the sole resolver
- `agents/notion-writer.md`: replaced all `about/identity.md` references with `AISE Identity` Notion page
- `skills/report/SKILL.md`: `me` target resolution updated to reference `AISE Identity` Notion page
- `skills/assistant-setup/SKILL.md`: description updated — removed "writes the about/ folder"
- `context/communication-style-guide.md`, `context/project-instructions.md`, `context/notion-writer-playbook.md`: updated all `about/voice.md` pointers to `AISE Leadership Preferences` Notion page
- `CLAUDE.md`: communication-style-guide table row updated — `about/voice.md` → `AISE Leadership Preferences` Notion page

---

## [1.6.1] — 2026-05-10

### Fixed
- `agents/notion-writer.md`, `agents/sf-backfill.md`, `agents/notion-integrity-check.md`: unified "not found" handling — each now outputs "AISE Identity page not found — run `/assistant-setup` to configure your profile." and stops; previously noted the gap in chat and asked once if needed
- `agents/report-builder.md`: same — "not found" path now stops instead of noting the gap and continuing

---

## [1.6.0] — 2026-05-10

### Changed
- `agents/assistant-onboarding.md`: removed Path B (local file read via `~/.claude/aise-leadership.datadir`) from Step 1 — Notion-only resolver now; removed Step 7 (local `about/` file writes) entirely — Notion profile pages are the only output; updated `--reset` mode to not delete local files; updated frontmatter description, end-state line, and Step 8 report to reference Notion pages; guardrails updated to reflect Notion-only output
- `agents/notion-ask.md` Step 4.1: removed Step A (local file read), Step B is now the sole resolver renamed to "Resolve identity"
- `agents/notion-writer.md`: removed Step A (local file read) from identity resolution preamble; "Before every write" and ownership contract updated to reference Notion identity page instead of `identity.md`
- `agents/notion-integrity-check.md`: removed Step A (local file read) from identity resolution preamble; Step 1 updated to use preamble-resolved UUID; all `about/identity.md` references replaced with `AISE Identity` Notion page references
- `agents/sf-backfill.md`: removed Step A (local file read) from identity resolution preamble; Step 1 PLUGIN_DATA_DIR block removed
- `agents/report-builder.md`: removed Step A (local file read) from identity resolution preamble; all `workspace.md` and `team-roster.md` local file reads replaced with `AISE Leadership Preferences` and `AISE Leadership Team Roster` Notion page references; `--customer` and `--aise` mode Step 1 PLUGIN_DATA_DIR blocks removed
- `CLAUDE.md`: path resolver note updated to Notion-only; per-user file table rows updated to reference Notion pages; `tracker-memory.md` row kept pointing to local file; Output defaults updated
- `skills/aise-context/SKILL.md`: removed CLI section, Notion-only resolver

---

## [1.5.1] — 2026-05-10

### Fixed
- `agents/notion-ask.md` Step 4.1: replaced broken Bash `cat` resolver (Bash not in tools list) with two-path Read tool resolver — Step A reads `~/.claude/aise-leadership.datadir` + `identity.md`; Step B falls back to `notion-get-users` + `notion-search("AISE Identity — {display_name}")` + `notion-fetch` for Cowork compatibility
- `agents/notion-ask.md` Step 4.1: corrected wrong pointer file name (`aise-assistant.datadir` → `aise-leadership.datadir`) — copy-paste bug from the aise-assistant agent that would have caused identity queries to resolve to the wrong user context

---

## [1.5.0] — 2026-05-10

### Added
- `agents/assistant-onboarding.md`: added `mcp__claude_ai_Notion__notion-create-pages` and `mcp__claude_ai_Notion__notion-update-page` to tools frontmatter
- `agents/assistant-onboarding.md` Step 7b (new): writes 4-page private Notion hierarchy — parent `AISE Profile`, child `AISE Identity` (shared with aise-assistant), child `AISE Leadership Preferences` (Voice + Workspace), child `AISE Leadership Team Roster` (markdown table from Step 2.5); always runs, never creates `AISE Assistant Preferences`
- `agents/assistant-onboarding.md`: no-early-exit rule at top of Procedure — all modes including "already onboarded" must run Step 7b and Step 8

### Changed
- `agents/assistant-onboarding.md` Step 1: added Path A (Notion — CLI + Cowork) before existing bash resolver (now Path B); Path A searches `AISE Identity`, `AISE Leadership Preferences`, and `AISE Leadership Team Roster` pages; Notion pages authoritative when both paths differ; "already onboarded" default-mode path now skips to Step 7b instead of exiting
- `agents/report-builder.md` preamble: replaced 3-step CLI-only identity resolution with CLI (Step A) + Cowork (Step B: `AISE Identity` + `AISE Leadership Preferences` + `AISE Leadership Team Roster`) + proceed (Step C) pattern
- `agents/notion-writer.md`, `agents/notion-integrity-check.md`, `agents/sf-backfill.md` preambles: updated to Step A (CLI pointer file) + Step B (Cowork: `notion-get-users` + `AISE Identity` search/fetch) + Step C pattern
- `skills/assistant-setup/SKILL.md`: replaced with clean delegation-only file (stripped all osascript and Cowork file-writing instructions; now delegates entirely to `agents/assistant-onboarding.md`)
- `skills/aise-context/SKILL.md`: restructured to two-path identity resolution (CLI: read pointer file + about/ files; Cowork: `notion-get-users` + `AISE Identity` + `AISE Leadership Preferences` + `AISE Leadership Team Roster`)
- `CLAUDE.md`: replaced osascript Cowork path with Notion-based path (`notion-get-users` + `AISE Identity` + `AISE Leadership Preferences` + `AISE Leadership Team Roster`); removed all osascript references

---

## [1.4.1] — 2026-05-10

### Fixed
- `CLAUDE.md`: added Cowork osascript fallback to the path resolver — when Read tool is blocked, use `mcp__Control_your_Mac__osascript` with `do shell script "cat $HOME/.claude/aise-leadership.datadir"` to reach `~/.claude/`; matches the pattern already working in aise-assistant; added "Finding these files" note to the per-user table identical to aise-assistant's

## [1.4.0] — 2026-05-10

### Added
- All 4 agents (`report-builder`, `notion-integrity-check`, `sf-backfill`, `notion-writer`): added `⚠️ Identity resolution — EXECUTE BEFORE ANY OTHER ACTION` preamble block at the top of every agent that accesses `about/` files — placed before any mode steps so the model cannot run Glob or plugin-path discovery before reading the pointer file
- Identity fallback: when `identity.md` is missing or contains `<TBD>` values (plugin not yet set up), agents now call `notion-get-users` to resolve the current user's UUID by name match, then note in chat to run `/assistant-setup`; previously agents would fail silently or misroute

### Changed
- `report-builder`: preamble also covers `workspace.md` resolution (Step C) to avoid a second pre-step Notion query for the templates DB

## [1.3.3] — 2026-05-10

### Fixed
- `session-start.sh`: added step 0 (use `$CLAUDE_PLUGIN_DATA` when `about/identity.md` already exists there — Cowork populated) and changed final fallback to prefer `$CLAUDE_PLUGIN_DATA` over a Linux-VM home path (Cowork fresh install); pointer file now always contains a path accessible in the current execution context

## [1.3.2] — 2026-05-10

### Fixed
- `notion-integrity-check`, `sf-backfill`, `notion-writer`: added explicit PLUGIN_DATA_DIR resolver — Read `~/.claude/aise-leadership.datadir` before any `about/identity.md` access; consistent with the fix already applied to `report-builder` in v1.3.1

## [1.3.1] — 2026-05-10

### Fixed
- `report-builder`: replaced bare `about/` path references with explicit `{PLUGIN_DATA_DIR}/about/` form; PLUGIN_DATA_DIR is now resolved via `Read ~/.claude/aise-leadership.datadir` in Step 1 of both modes — prevents the model from falling back to the volatile `CLAUDE_PLUGIN_DATA` env variable (which points to `/Library/Application Support/Claude/...` in desktop contexts and is outside connected folders)
- `CLAUDE.md`: path resolver note updated to call out the `CLAUDE_PLUGIN_DATA` env variable as volatile and forbidden; Read-tool resolution is now the documented pattern

## [1.3.0] — 2026-05-10

### Added
- `report-builder`: `/report` now automatically writes each report to a Notion page after rendering in chat; suppress with `--no-notion`
- `report-builder`: best-fit template auto-selection by name match — `--aise` prefers "portfolio"/"team brief"/"aise"/"weekly"; `--customer` prefers "account"/"customer"/"snapshot"
- `report-builder`: presales and lapsed-contract accounts are now pre-filtered from 🔴/🟠/🟡 attention queue flags in `--aise` mode; appear in the queue under ℹ️ (Presales always; lapsed within 180 days only)
- `report-builder`: `--customer` mode Step 4 now checks Active Package liveness before raising ⚠️/🔴 cadence flags; presales/lapsed accounts get ℹ️ Signals instead

### Changed
- `report-builder`: "Template-based output" section reframed from optional to the default behavior
- `report-builder`: added `notion-create-pages` to the agent's tool list; guardrails updated from "Read-only" to "Mostly read-only"

## [1.2.2] — 2026-05-10

### Fixed
- `setup-connections.sh`: refactored SF detection into helper functions (`_sf_in_config`, `_find_sf`, `_sf_auth_ok`) for more robust Salesforce CLI and MCP presence checking
- SF binary lookup now searches multiple candidate paths beyond `$PATH`
- SF auth check now reads credential files directly without requiring Node on PATH
- Banner string corrected back to `aise-leadership` (had been overwritten with `aise-assistant`)

## [1.2.1] — 2026-05-10

### Fixed
- `setup-connections.sh --check`: now reads `~/.claude/claude_desktop_config.json` for the Salesforce MCP presence check
- Nerd callout now fires only when both Salesforce CLI and Salesforce MCP are confirmed present
- MCP-missing message in `--check` mode now prints the correct `claude mcp add` install command
- Banner string corrected from `aise-assistant` to `aise-leadership`

## [1.2.0] — 2026-05-10

### Added
- Proactive improvement nudge — after any skill run where efficiency gaps are observed (redundant tool calls, missing pre-loadable context, sub-optimal routing, mid-run corrections), Claude surfaces a one-line prompt suggesting the user run `/assistant-improvement` and send the output to the plugin admin

## [1.1.0] — 2026-05-10

### Added
- `/assistant-help --whatsnew` flag — reads `CHANGELOG.md` and surfaces the latest version changes (latest MAJOR/MINOR entry + any subsequent patches) instead of the full command reference; also triggered by natural language phrases like "what's new", "what changed", "latest changes"

## [1.0.3] — 2026-05-10

### Added
- Ported `/assistant-improvement` from aise-assistant — analyze a previous skill run for issues and output a copyable coding-agent prompt with exact plugin, files, and fixes
- Updated `port-to-leadership.md`: version bump is now confirm-gated (PATCH default, no auto-MAJOR)

## [1.0.2] — 2026-05-10

### Fixed
- Replace stale `brew install sf-mcp-server` Salesforce install instructions with the correct three-step flow: `npm install -g @salesforce/cli`, `sf org login web`, `claude mcp add salesforce -- npx -y @salesforce/mcp`
- `setup-connections.sh`: check for `sf` CLI instead of the old binary; mcp.json entry now uses `npx -y @salesforce/mcp`; removed email-lookup block; downgraded missing-CLI from a hard exit to a warning
- Added a friendly easter egg when Salesforce is already installed

## [1.0.1] — 2026-05-10

### Fixed
- Set executable bit on `scripts/session-start.sh` and `scripts/sync-context.sh`

## [1.0.0] — 2026-05-10

### Added
- Initial release of the aise-leadership plugin
- `/report --aise` — portfolio summary across all accounts owned by an AISE (attention queue, health table, velocity, renewals)
- `/report --customer` — single-account snapshot (program health, credit burn, sessions, risks, next step)
- `/notion-check [--fix]` — Customer Tracker integrity audit (ownership drift, missing packages, stale data)
- `/notion-sync --sf [--apply]` — Salesforce ARR and contract date sync into Active Packages
- `/notion-sync --renewals [--dry-run]` — flag upcoming renewals not yet marked
- `/notion-ask` — natural language Q&A on the Customer Tracker schema
- `/assistant-setup` — onboarding flow (Notion identity, voice, workspace preferences)
- `/assistant-help` — full command reference
- `/assistant-remember` — context-keeper invocation for corrections and new rules
- `/aise-context` — operating context loader
- `/commit` — version-bumping commit skill that syncs `context/` from aise-assistant before committing
- `context/` shared with [aise-assistant](https://github.com/kmtz3/aise-toolkit) via `scripts/sync-context.sh`

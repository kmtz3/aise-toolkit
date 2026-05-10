# Changelog — aise-leadership

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

# Changelog

All notable changes to aise-assistant are documented here.
Format: `## [version] — YYYY-MM-DD` followed by bullet points grouped by type.

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

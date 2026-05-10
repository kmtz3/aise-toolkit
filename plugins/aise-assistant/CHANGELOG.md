# Changelog

All notable changes to aise-assistant are documented here.
Format: `## [version] — YYYY-MM-DD` followed by bullet points grouped by type.

---

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

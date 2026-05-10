# Changelog — aise-leadership

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

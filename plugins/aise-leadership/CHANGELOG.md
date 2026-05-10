# Changelog — aise-leadership

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
- `context/` shared with [aise-assistant](https://github.com/kmtz3/aise-assistant) via `scripts/sync-context.sh`

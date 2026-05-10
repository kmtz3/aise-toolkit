# Changelog

All notable changes to aise-assistant are documented here.
Format: `## [version] — YYYY-MM-DD` followed by bullet points grouped by type.

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

## [2.0.0] — 2026-05-10

### Changed
- Version reset to 2.0.0 — prior versioning had inflated; this establishes a clean baseline

---

## [4.2.1] — 2026-05-10

### Changed
- `.claude-plugin/marketplace.json`: renamed marketplace from `aise-tools` to `aise-toolkit`; added `aise-leadership` as a second plugin entry pointing at `kmtz3/aise-leadership`

---

## [4.2.0] — 2026-05-10

### Changed
- `context/notion-schema.md`: corrected `Account Status` valid values and added inline status definitions (Not started, Presales, Active (no Services), Active (Services), Contracted to Scale, Churned) with behavioral notes for each; corrected stale field values for `Session.Type` (added `🫥 Internal`), `Session.Call Status` (proper groupings), `Task.Status`, `Priority`, `AI Ready`, `Industry` multi-select; added `Renewal Forecast` field; corrected Session statuses list in Create a Session section; added Active Package Status behavioral notes block (Renewal 90-day trigger + $30K ARR threshold fork, Package Expired as sole terminal state, Service Quota Used keep-active rule); added 4 new Known Gotchas — $30K AISE ARR threshold, Active (no Services) always expects an AISE No Services AP, Contracted to Scale ≠ services complete, renewal window is 90 days
- `agents/account-setup.md`: minor update

---

## [4.1.0] — 2026-05-09

### Changed
- `skills/assistant-help/SKILL.md`: added `/report` to the Common workflows table, Command families taxonomy, and a new Flag reference section (`--customer` and `--aise` modes with flag tables and examples)

---

## [4.0.0] — 2026-05-09

### Added
- `skills/report/SKILL.md`: new `/report` command with two modes — `--customer <name>` (single-account leadership snapshot) and `--aise [me | <name>]` (portfolio summary for any AISE, targeting by name via `notion-get-users`)
- `agents/report-builder.md`: full procedure for both report modes — Notion data pull (Customer, Active Package, Sessions, Tasks), supplementary Glean/Gmail signals for `--customer`, attention queue scoring and portfolio table for `--aise`, credit burn trajectory, cadence health, velocity stats, and renewals window; read-only across all tools
- `CLAUDE.md`: registered `/report` in the Standalone commands table and `report-builder` in the Agents table

---

## [2.4.0] — 2026-05-09

### Changed
- `notion-schema.md`, `notion-writer.md`, `notion-writer-playbook.md`, `account-setup.md`, `bulk-account-setup.md`, `customer-plan-next.md`, `engagement-planner.md`, `sf-backfill.md`: replaced the two-field customer pattern (`Active for (1:N)` + `Customer (M:N)`) on Active Package with a single `Customer` relation (Formulas 2.0 schema); on-expiry no longer requires clearing a relation — just flip `Active? = __NO__`; all queries updated to `"Customer" LIKE '%<id>%' AND "Active?" = '__YES__'` for current-package lookups
- `notion-schema.md`: removed `Active Package` (limit 1 backlink) from Customer writable fields; added `All packages` (rollup) and `Current package` (formula) to Customer read-only fields; updated Relationship Map and known gotchas accordingly
- `notion-integrity-check.md`: removed stale `Active for (1:N)` drift check (field is gone); updated Multiple-Active-Packages check to use `Customer` + `Active? = YES` query; added new 🟦 Field hygiene checks — Sessions and Tasks with null or date-mismatched `Consumed Package`; added `--fix` logic to auto-assign `Consumed Package` using the date-matching rule where exactly one AP covers the record date

---

## [2.3.1] — 2026-05-09

### Fixed
- `notion-schema.md`, `notion-writer.md`, `notion-writer-playbook.md`, `notion-integrity-check.md`, `sf-backfill.md`, `customer-plan-next.md`: replaced deprecated `Customer` relation field with `Customer (M:N)` (permanent historical link) and `Active for (1:N)` (live-ledger link, set when `Start Date ≤ today ≤ End Date`, cleared on expiry); documented semantics, query patterns, and on-expiry clear rule throughout
- `notion-schema.md`: updated Customer Template section — agent now applies template on create and fetches the live page to discover section headings dynamically instead of relying on hardcoded names
- `CLAUDE.md`, `README.md`: removed local-dev-only references (`/assistant-automate`, `workflow-advisor`, "Proactive automation trigger" section); corrected `assistant-*` family count 5 → 4
- `README.md`: fixed plugin output filename `.zip` → `.plugin`; updated stale install command to current Cowork UI / CLI paths
- `scripts/package.sh`, `scripts/validate.sh`: removed stale `DEVELOPMENT.md` exclude (now inside `.claude/` which is already excluded); updated comment references

---

## [2.3.0] — 2026-05-09

### Changed
- Consolidated 7 skills into 3 multi-mode commands to reduce surface area as the plugin grows
- `notion-sync-sf` + `notion-sync-owner` + `notion-flag-renewals` → `/notion-sync --sf|--owner|--renewals` (all push external data into Notion; share `--mine`, `--global`, `--dry-run`, `--no-confirm` flag conventions)
- `bulk-debrief-yesterday` + `bulk-prep-week` → `/bulk --debrief|--prep` (both run a session workflow in bulk across calendar events)
- `customer-plan-next` + `customer-plan-engagement` → `/customer-plan --next|--full` (both plan forward; flag is just scope)
- `skills/assistant-help/SKILL.md`: rewritten with new command names, per-command flag reference tables, and usage examples for all multi-mode commands
- All agent files, context files, and templates updated: `agents/account-setup.md`, `agents/bulk-account-setup.md`, `agents/engagement-planner.md`, `agents/assistant-onboarding.md`, `context/engagement-planning-guide.md`, `templates/session-kdds/00-index.md`, `skills/customer-setup/SKILL.md`
- `CLAUDE.md` command registry updated: new `bulk` family section added; `notion-*` table updated; `customer-plan` rows updated; agent table gains `customer-plan-next` row; output defaults updated
- `README.md` updated: command count 25 → 22, family listings, workflow table

---

## [2.2.5] — 2026-05-09

### Changed
- `notion-schema.md` + `agents/notion-writer.md`: Tasks created after a session must now set `Consumed Package` — inherit from `Source Call` if present, otherwise apply the same date-matching logic as Sessions (active package covering today → most-recently-ended inactive package → leave empty)

---

## [2.2.4] — 2026-05-09

### Fixed
- `session-summarizer` / `project-instructions.md`: Glean `read_document` step now extracts the `id` field from search result objects instead of passing a URL string (which the tool rejects)
- `account-setup`: same `read_document` fix in Step 2 (Gong transcripts) and Guardrails
- `post-session-debrief` Step 12: Customer page update now fetches the page first, checks for template headings before writing, and falls back to appending a `## 📋 Account Notes` section on pages with non-standard templates instead of erroring
- Remove all references to `## 🤝 PB Account Team` — section deleted from the Customer page template; `notion-schema.md` table updated (five → four sections), `account-setup` Step 4A and Step 5 updated accordingly; AE/Renewal Manager info redirected to page properties

---

## [2.2.3] — 2026-05-09

### Fixed
- `notion-sync-owner`: accept `--me` as an alias for `--mine` in Step 2 and Flags section
- `notion-sync-owner`: Customers/Customer relation fields store hyphen-stripped Notion page URLs — LIKE pattern now uses `<customer-url-id>` (hyphens removed), not the bare UUID
- `notion-sync-owner`: drift filter (`Current Account Owner NOT LIKE '%<owner-uuid>%' OR IS NULL`) moved directly into Step 4 WHERE clauses; removed separate Step 5 drift-detection pass to avoid hitting the 500-row LIMIT on already-correct records
- `notion-sync-owner`: Step 1 now documents a fallback to `notion-get-users` with the user's email when `identity.md` is not found, preventing a hard-fail on fresh installs

---

## [2.2.2] — 2026-05-09

### Changed
- Extract identity resolution into a canonical procedure in `context/notion-schema.md` § Identity resolution (three-path chain + graceful stop + `--global` skip rule)
- `notion-flag-renewals` and `notion-sync-owner` Step 1 now reference the shared procedure instead of inlining it

---

## [2.2.1] — 2026-05-09

### Fixed
- `notion-flag-renewals`: identity resolution is now conditional — `--global` skips Step 1 entirely (no file lookup)
- `notion-flag-renewals`: graceful fallback for `--mine` when `.datadir` or `notion_user_id` is missing — surfaces a clear inline message instead of a broken query
- `notion-flag-renewals`: three-path identity resolution (`.datadir` → glob plugin dirs → `notion-get-users` + userEmail)
- `notion-flag-renewals`: date and status filtering pushed into the SQL query — collapses 3 paginated round-trips into 1 targeted fetch
- `notion-flag-renewals`: document known macOS plugin data dir paths directly in the skill

---

## [2.2.0] — 2026-05-09

### Added
- `/notion-sync-owner` skill — push `Customer.Owner` → `Current Account Owner` on all linked Sessions, Tasks, and Active Packages (`--mine` / `--global`)
- `/notion-flag-renewals` skill — set `Status = Renewal` on active packages ending within N days; `--dry-run` previews without writing

---

## [2.1.0] — 2026-05-09

### Added
- Customer page template with agent-readable sections (notion-schema.md)
- Active Package template wired into account-setup and notion-writer agents

### Fixed
- Scope Gong queries to post-sales calls; skip Gmail lookups in delegated (teammate) mode
- Session page structure now driven from Notion templates rather than hard-coded agent logic

---

## [2.0.0] — 2026-05-09

### Added
- `customer-plan-next` agent and `/customer-plan-next` command
- Session page structure driven from Notion templates

### Fixed
- Full plugin review fixes; gitignore `.claude/` from distribution

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

# AISE Assistant

A Cowork / Claude Code plugin that turns any Productboard **AI Success Engineer (AISE)** workstation into a full customer-onboarding co-pilot — prep, deliver, summarize, follow up, plan, and keep your Notion Customer Tracker in sync.

## What's in the box

- **22 slash commands** grouped by family. Type `/<family>` (or `/<family>-`) in autocomplete to see siblings.
  - **`customer-*`** (3) — `/customer-setup [--research|--refresh]`, `/bulk-account-setup`, `/customer-whats-new`
  - **`customer-plan`** (1, two modes) — `/customer-plan --next`, `/customer-plan --full`
  - **`session-*`** (5) — `/session-prep`, `/session-kdds`, `/session-summary`, `/session-score`, `/session-debrief`
  - **`bulk`** (1, two modes) — `/bulk --debrief`, `/bulk --prep`
  - **`draft-*`** (3) — `/draft-email`, `/draft-followup`, `/draft-diagram`
  - **`notion-*`** (2) — `/notion-write`, `/notion-check`
  - **`notion-sync`** (1, three modes) — `/notion-sync --sf`, `/notion-sync --owner`, `/notion-sync --renewals`
  - **`assistant-*`** (4) — `/assistant-setup`, `/assistant-help`, `/assistant-remember`, `/aise-context`
  - **Standalone** (2) — `/support-hub`, `/daily-brief`
- **20 specialist agents** that execute each command (session prep, KDD generation, summaries, Notion writes, integrity checks, etc.).
- **Universal context** — workflow rules, the AISE reference guide, scorecards, communication style guide, full Notion Customer Tracker schema, engagement planning framework, KDD anchor templates per A-session type.
- **Personal layer scaffolding** — `about/` with a README and three onboarding templates (`identity`, `voice`, `workspace`) populated by `/assistant-setup` on first run.

## Installation

**Marketplace (recommended)** — install both AISE plugins at once via the [aise-toolkit](https://github.com/kmtz3/aise-toolkit) personal marketplace:

```
https://github.com/kmtz3/aise-toolkit
```

Add it as a marketplace source in Claude Code / Cowork, then install `aise-assistant`. Updates are available via **Settings → Extensions → Check for Updates**.

**Local dev / single user** — open this directory as your project root in Claude Code. `CLAUDE.md` loads automatically as project context.

**Manual `.plugin` install (offline / air-gapped)** — package first, then load:

```bash
npm run pack   # builds aise-assistant-vX.Y.Z.plugin in parent dir
```

Install via Cowork UI → Settings → Extensions → upload the `.plugin` file.

Skills are namespaced: `/aise-assistant:session-prep`, `/aise-assistant:session-debrief`, etc.

> **Context loading note.** Per the Claude Code plugin spec, `CLAUDE.md` at the plugin root is not loaded as project context for plugin installs. Instead, context is loaded per-invocation — each skill dispatches to an agent that carries its full operating instructions in its system prompt. Run `/aise-assistant:assistant-setup` first so your personal `about/` files are populated; subsequent skill invocations will read them for voice, identity, and workspace preferences.

## First-run setup

After install, run:

```
/assistant-setup
```

The `assistant-onboarding` agent will:

1. Copy `about/templates/*.md.template` → `about/identity.md`, `about/voice.md`, `about/workspace.md`.
2. Auto-resolve your Notion identity.
3. Ask short HITL questions (name, sign-offs, em-dash rule, English variant, conferencing tool, Calendly URLs, internal Slack channels, manager).
4. Optionally scrape recent Gmail + Slack to draft your voice profile.
5. Write your personalized `about/*.md` files.

Re-run with `--update` to drift-check, `--reset` to start over, or `--scrape-voice` to re-scrape.

## Workflow shape

| Stage | Commands |
|---|---|
| **New customer / handoff** | `/customer-setup` → `/customer-plan --full` |
| **Per session** | `/customer-whats-new` → `/session-prep` (or `/session-kdds` for architecting) → deliver → `/session-debrief` |
| **Ongoing** | `/customer-plan --next`, `/session-score`, `/notion-write`, `/notion-check`, `/notion-sync --sf` |
| **Anytime** | `/draft-email`, `/draft-followup`, `/draft-diagram`, `/support-hub`, `/assistant-remember`, `/assistant-automate`, `/assistant-help` |

## Connecting your tools

Connections come in two types: **claude.ai integrations** (per-user, configured once in the browser) and **local MCP servers** (installed per machine via a script).

### claude.ai integrations

Sign in to **claude.ai → Settings → Integrations** and enable:

| Integration | Used for |
|---|---|
| **Notion** | Customer Tracker reads/writes (Customers, Active Packages, Sessions, Tasks) |
| **Gmail** | Follow-up draft creation, email history pulls |
| **Google Calendar** | Session lookup, prep block scheduling |
| **Google Drive** | Diagram uploads, document access |
| **Glean** | Gong call transcripts, Slack, Salesforce, Confluence, and Drive search |
| **Slack** | Debrief draft posting, external channel reads |
| **Figma** | Architecture diagram creation and export |
| **Atlassian** | Jira/Confluence cross-reference (optional) |

Each teammate must connect these in their own claude.ai account — they can't be bundled in the plugin.

Once Notion is connected, confirm the **"📖 Customer Tracker — Claude Reference Guide"** page is accessible — it's the canonical schema source of truth.

### Local MCP servers

Run once per machine (safe to re-run):

```bash
./scripts/setup-connections.sh
```

This configures:

| Server | Purpose |
|---|---|
| **Salesforce** | ARR and contract data via `sf-mcp-server` |

Pass `--check` first to see what's already configured without making any changes. Restart Claude Code after running.

## Notion automations expected

- `Resync Owner to descendants` button on every Customer page
- Sessions automation: when `Customers` relation is set/changed, auto-fill `Current Account Owner`

If these aren't already configured, `/assistant-setup` will surface a reminder.

## Project conventions

- **Owner-filter every Notion read** — the workspace is shared across AISEs. Customers query by `Owner`; Active Packages / Sessions / Tasks query by `Current Account Owner` (with `Delivered By` for Sessions and `Owner` for Tasks).
- **Pre-create dedup check** for every Task and Session before write.
- **Tasks must always have `Customers` set** — internal/non-customer tasks point to the Productboard customer record.
- **Notion is SSOT** for active engagements; `<PLUGIN_DATA_DIR>/about/tracker-memory.md` stores cross-customer observations (per-user, not in the plugin repo).
- **Communication style** — universal in `context/communication-style-guide.md`, personal overlay wins via `about/voice.md`.

## Maintainer

Klara Martinez · Productboard AI Success Engineering

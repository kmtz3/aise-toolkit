# AISE Assistant

A Cowork / Claude Code plugin that turns any Productboard **AI Success Engineer (AISE)** workstation into a full customer-onboarding co-pilot — prep, deliver, summarize, follow up, plan, and keep your Planhat account record up to date. Planhat is the sole system of record.

## What's in the box

- **34 slash commands** grouped by family. Type `/<family>` (or `/<family>-`) in autocomplete to see siblings.
  - **`customer-*`** (3) — `/customer-setup [--force-new]`, `/bulk-account-setup`, `/customer-whats-new`
  - **`customer-plan`** (1, two modes) — `/customer-plan --next`, `/customer-plan --full`
  - **`session-*`** (7) — `/session-prep`, `/session-kdds`, `/session-summary`, `/session-score`, `/session-backfill [--bulk]`, `/session-debrief`, `/session-audit`
  - **`bulk`** (1, two modes) — `/bulk --debrief`, `/bulk --prep`
  - **`draft-*`** (3) — `/draft-email`, `/draft-followup`, `/draft-diagram`
  - **`log-*`** (3) — `/log-feedback`, `/log-slack-threads`, `/log-slack-threads-internal`
  - **`ph-*`** (1) — `/ph-reconcile-gong-gcal`
  - **`planhat-*`** (2) — `/planhat-automations`, `/planhat-formula-builder`
  - **`assistant-*`** (5) — `/assistant-setup`, `/assistant-help`, `/assistant-remember`, `/assistant-improvement`, `/aise-context`
  - **Standalone** (8) — `/support-hub`, `/daily-brief`, `/spark-demo-prep`, `/create-deck`, `/session-facilitation`, `/spark-onepager`, `/inbox-triage`, `/temp-ph-ignite-conversion-data-sync`
- **23 specialist agents** that execute each command (session prep, KDD generation, summaries, Planhat writes, session-log auditing, Gong/Gcal reconciliation, etc.).
- **Universal context** — workflow rules, the AISE reference guide, scorecards, communication style guide, the full Planhat schema/field reference, engagement planning framework, KDD anchor templates per A-session type.
- **Personal profile** — stored directly on `custom.AISE *` fields on your Planhat User record via `/assistant-setup`. Persists across installs, updates, and machines; no local files to manage.

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

> **Context loading note.** Per the Claude Code plugin spec, `CLAUDE.md` at the plugin root is not loaded as project context for plugin installs. Instead, context is loaded per-invocation — each skill dispatches to an agent that carries its full operating instructions in its system prompt. Run `/aise-assistant:assistant-setup` first so your personal profile is populated on your Planhat User record; subsequent skill invocations read it for voice, identity, and workspace preferences.

## First-run setup

After install, run:

```
/assistant-setup
```

The `assistant-onboarding` agent will:

1. Auto-resolve your Planhat User identity.
2. Ask short HITL questions (name, sign-offs, em-dash rule, English variant, conferencing tool, Calendly URLs, internal Slack channels, manager).
3. Optionally scrape recent Gmail + Slack to draft your voice profile.
4. Write everything directly to `custom.AISE *` fields on your Planhat User record.

Re-run with `--update` to drift-check, `--reset` to start over, or `--scrape-voice` to re-scrape.

## Workflow shape

| Stage | Commands |
|---|---|
| **New customer / handoff** | `/customer-setup` → `/customer-plan --full` |
| **Per session** | `/customer-whats-new` → `/session-prep` (or `/session-kdds` for architecting) → deliver → `/session-debrief` |
| **Ongoing** | `/customer-plan --next`, `/session-score`, `/session-audit`, `/log-feedback` |
| **Anytime** | `/draft-email`, `/draft-followup`, `/draft-diagram`, `/support-hub`, `/assistant-remember`, `/assistant-improvement`, `/assistant-help` |

## Connecting your tools

Connections come in two types: **claude.ai integrations** (per-user, configured once in the browser) and **local MCP servers** (installed per machine via a script).

### claude.ai integrations

Sign in to **claude.ai → Settings → Integrations** and enable:

| Integration | Used for |
|---|---|
| **Planhat** | The sole customer tracker — Companies, Conversations, Tasks, personal profile. Required; onboarding cannot proceed without it. |
| **Gmail** | Follow-up draft creation, email history pulls |
| **Google Calendar** | Session lookup, prep block scheduling |
| **Google Drive** | Diagram/KDD uploads, document access |
| **Glean** | Gong call transcripts, Slack, Salesforce, Confluence, and Drive search |
| **Slack** | Debrief draft posting, external channel reads |
| **Figma** | Architecture diagram creation and export |
| **Atlassian** | Jira/Confluence cross-reference (optional) |

Each teammate must connect these in their own claude.ai account — they can't be bundled in the plugin.

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

## Project conventions

- **Owner-filter every Planhat query** — the workspace is shared across AISEs. Filter Tasks by `ownerId`, Conversations by `users`, scoped to the current user's Planhat id.
- **Pre-create dedup check** for every Task and Conversation before write — `externalId`/`sourceId` are the dedup keys; see `context/planhat-schema.md` per model.
- **Every Task must have `companyId` set** — internal/non-customer tasks are the one exception the write rules call out explicitly.
- **Planhat is SSOT** for active engagements — account working notes live as dated Company Comments; cross-customer observations live on `custom.AISE Tracker Memory` on your Planhat User record.
- **Communication style** — universal in `context/communication-style-guide.md`, personal overlay wins via `custom.AISE Profile preferences` on your Planhat User record.

## Maintainer

Klara Martinez · Productboard AI Success Engineering

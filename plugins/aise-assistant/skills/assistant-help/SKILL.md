---
name: assistant-help
description: Quick reference of all available commands grouped by workflow stage, plus flag reference for multi-mode commands and links to deeper docs. Run anytime you forget what's available or want a refresher. Pass --whatsnew (or ask "what's new") to see the latest version changes instead.
---

## Mode detection

| Flag | Natural language equivalents |
|---|---|
| (no flag) | "help", "what can you do", "show commands", "list commands", "what's available" |
| `--whatsnew` | "what's new", "what changed", "what was updated", "latest changes", "changelog", "new version", "what did you add", "what's in the latest version" |

**If `--whatsnew` is passed, or the user's phrasing matches the natural language equivalents above:**

1. Read `CHANGELOG.md` at the plugin root.
2. Find the most recent MAJOR or MINOR version entry. If there are PATCH entries dated after it, include those too.
3. Output in chat (do not output the full command reference):

   > **What's new in aise-assistant [version]** — [date]
   > [bullet points from that entry, preserving the Added / Changed / Fixed grouping]
   >
   > _(If PATCH entries exist after the latest MINOR/MAJOR, list them below under a "Also fixed" heading.)_
   >
   > _Run `/assistant-help` for the full command reference._

4. Stop — do not continue to the help reference below.

---

**Otherwise (default — no flag, or help-intent phrasing):**

Output the help reference below verbatim, formatted as inline markdown in chat. Address the user by their `Display name` from `custom.AISE Identity` on their Planhat User record if available; otherwise use a generic greeting.

---

# 🧭 AISE Assistant — Quick Reference

Commands are grouped by family. Type `/<family>` (or `/<family>-`) in autocomplete to see siblings.

## Common workflows (in order)

| Want to... | Run |
|---|---|
| **Get up to speed on a customer** before a meeting | `/customer-whats-new <customer>` |
| **Prepare for a customer session** | `/session-prep <customer> [session-type]` |
| **Generate a facilitation guide only** | `/session-facilitation <customer> [session-id]` — interactive HTML with timer, decision panels, open items, action capture |
| **Run a full post-session debrief in one shot** | `/session-debrief <customer> [session-id]` |
| **Just summarize a delivered call** | `/session-summary [customer or session]` |
| **Draft a follow-up email** | `/draft-email <who/what>` (saves to Gmail Drafts, never sends) |
| **Work through the inbox and reply to what needs it** | `/inbox-triage [window]` (sweeps recent mail, batch-drafts threaded replies, updates Planhat Next Step after you send) |
| **Plan the next 2–4 sessions** | `/customer-plan --next <customer>` |
| **Build a full program plan** | `/customer-plan --full <customer>` |
| **Set up a brand-new or inherited account** | `/customer-setup <customer>` |
| **Score a delivered session against the rubric** | `/session-score <session-type>` |
| **Audit logged sessions / tasks for drift** | `/session-audit [--fix] [--tasks]` — reconciles Planhat session history against Calendar + Gong, or audits task completion drift |
| **Answer a customer question with PB docs** | `/support-hub <query>` |
| **Build a customer-facing diagram** | `/draft-diagram <customer> <type> [description]` |
| **Log a shared Slack channel into Planhat** | `/log-slack-threads --channel <url> [--customer <name>] [--dry-run]` – one Conversation per thread, plus a reply-backfill over the last 365 days |

## Suggested order around a customer session

1. **Day before:** `/customer-whats-new <customer>` — surface what's changed since the last touch.
2. **Day before / morning of:** `/session-prep <customer>` — pulls context, drafts brief, writes it to `custom.Prep Notes` on the session's Planhat Task/Conversation. For A/Discovery/Kickoff sessions, also creates a customer-facing KDD doc + interactive facilitation HTML guide, published to the `Customer Session Artifacts` Drive folder and linked back onto the session's Planhat record.
3. **Same day after the call:** `/session-debrief <customer>` — runs summary + Planhat Conversation write + Tasks + Gmail follow-up draft + Slack debrief draft + scorecard eval, all in one go.
4. **Optional:** `/session-score <session-type>` if you want a focused scorecard review.

## Command families at a glance

- **`customer-*`** — account lifecycle (`-setup [--force-new]`, `-whats-new`)
- **`customer-plan`** — program planning (`--next` for 2–4 sessions, `--full` for a complete program)
- **`session-*`** — per-session workflows (`-prep`, `-kdds`, `-facilitation`, `-summary`, `-score`, `-debrief`)
- **`bulk`** — run a session workflow across multiple meetings at once (`--debrief`, `--prep`)
- **`bulk-account-setup`** — admin/reorg task: set up all accounts owned by a user
- **`draft-*`** — message / artifact drafts (`-email`, `-followup`, `-diagram`)
- **`log-*`** — log customer touchpoints into Planhat (`log-feedback`, `log-slack-threads`, `log-slack-threads-internal`)
- **`ph-*`** — Planhat/Gong integration stopgaps (`ph-reconcile-gong-gcal`)
- **`planhat-*`** — build/debug Planhat's own automation layer (`planhat-automations`, `planhat-formula-builder`)
- **`assistant-*`** — meta / configure the assistant (`-setup`, `-help`, `-remember`, `-automate`)
- **Standalone** — `/support-hub`, `/daily-brief`, `/log-slack-threads`, `/session-audit`

## Flag reference — multi-mode commands

### `/bulk` — two modes, one command

| Mode | What it does | Key flags |
|---|---|---|
| `--debrief` | Full post-session debrief for every external meeting from yesterday | `--date YYYY-MM-DD`, `--skip <customer>`, `--rerun <customer>` |
| `--prep` | Session prep for all external meetings in the upcoming week | `--week YYYY-MM-DD`, `--skip <customer>`, `--force <customer>` |

**Examples:**
```
/bulk --debrief                            # debrief yesterday's external meetings
/bulk --debrief --date 2026-05-06          # specific date
/bulk --debrief --skip Acme               # exclude one customer
/bulk --prep                               # prep all next-week sessions
/bulk --prep --week 2026-05-12             # anchor to a specific Monday
/bulk --prep --force Acme                 # rerun prep even if brief exists
```

### `/customer-plan` — two modes, one command

| Mode | What it does |
|---|---|
| `--next <customer>` | Map current state → propose next 2–4 sessions (with gaps, risks, asks) |
| `--full <customer>` | Build goals → milestones → phases → sessions plan; writes to the Company `custom.Engagement Plan` field in Planhat on approval |

**Examples:**
```
/customer-plan --next Acme                 # tactical next-phase plan
/customer-plan --full Acme                 # full engagement program plan
```

### `/session-audit` flags

| Flag | Effect |
|---|---|
| `--customer <name>` | Scope audit to a single customer |
| `--tasks` | Audit open Planhat Tasks for completion drift instead of session history |
| `--fix` | Apply corrections with per-write read-back verification |

### `/customer-setup` modes

| Mode | What it does |
|---|---|
| (no flag) | Baseline — creates Customer page, Active Package, backfills sessions |
| `--research` | Baseline + deep company research (web, SF, Gong) |
| `--refresh` | Re-runs research on an existing Customer page |

## Maintenance

| Want to... | Run |
|---|---|
| **Correct the assistant** (style nit, new rule, fact change) | `/assistant-remember <correction>` (invokes context-keeper) |
| **Automate a new recurring task** | `/assistant-automate <task description>` (drafts a new agent + command) |
| **Generate a fix prompt after a bad skill run** | `/assistant-improvement` — analyzes what went wrong and outputs a copyable coding-agent prompt |
| **(Re-)onboard yourself or a teammate** to this assistant | `/assistant-setup [--update \| --reset \| --scrape-voice]` |
| **This help reference** | `/assistant-help` |

## Personal config

Your identity, voice preferences, and workspace specifics live directly on `custom.AISE *` fields on your Planhat User record:

- **`custom.AISE Identity`** — name, role, time zone, manager
- **`custom.AISE Profile preferences`** — sign-offs, language quirks, casual register
- **`custom.AISE Workspace`** — conferencing tool, Slack channel, manager
- **`custom.AISE Calendly Sync` / `Architecting` / `Enablement` / `Discovery` / `Kickoff` / `Spark`** — booking links per session type

To change them: run `/assistant-setup` for a guided re-onboarding, or edit the fields directly in Planhat.

## Where things live

| Where | What |
|---|---|
| **Planhat** | Source of truth for active engagements, per-customer state, sessions, tasks, working notes (Company Comments) |
| **`context/planhat-schema.md`** | Model schemas, field formats, query patterns |
| **`context/score-cards.md`** | Per-session scorecards (Discovery, Foundations, Insights, Prioritization, Roadmaps, Spark, Success Planning, QBR) |
| **`context/pb-aise-reference-guide.md`** | Session methodology — "what good looks like" per session type |
| **`context/communication-style-guide.md`** | Universal AISE comms patterns; `custom.AISE Profile preferences` on your Planhat User record overrides |
| **`templates/session-kdds/`** | Customer-facing KDD anchor templates per A-session type |
| **`custom.AISE Tracker Memory`** (Planhat User field) | Cross-customer observations only — per-user, written by `context-keeper` (Planhat is SSOT for everything else) |

## Tips

- **Don't paste context** the assistant can retrieve. Just name the customer or session — agents pull from Glean, Gmail, Calendar, Planhat, Slack automatically.
- **Confirm before destructive writes.** Planhat updates ask before applying unless explicitly told otherwise.
- **Customer-side actions don't go in the Tasks DB.** Only PB-side actions assigned to you. Customer commitments live in summaries / follow-ups.
- **Internal tasks** (no specific customer) point at the **Productboard** customer record automatically.

For full details on any command, see `skills/<command-name>/SKILL.md`. Agent specs are in `agents/`.

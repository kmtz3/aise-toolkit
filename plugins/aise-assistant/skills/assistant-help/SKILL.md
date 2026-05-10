---
name: assistant-help
description: Quick reference of all available commands grouped by workflow stage, plus flag reference for multi-mode commands and links to deeper docs. Run anytime you forget what's available or want a refresher.
---

Output the help reference below verbatim, formatted as inline markdown in chat. Address the user by their `Display name` from `about/identity.md` if available; otherwise use a generic greeting.

---

# 🧭 AISE Assistant — Quick Reference

Commands are grouped by family. Type `/<family>` (or `/<family>-`) in autocomplete to see siblings.

## Common workflows (in order)

| Want to... | Run |
|---|---|
| **Get up to speed on a customer** before a meeting | `/customer-whats-new <customer>` |
| **Prepare for a customer session** | `/session-prep <customer> [session-type]` |
| **Run a full post-session debrief in one shot** | `/session-debrief <customer> [session-id]` |
| **Just summarize a delivered call** | `/session-summary [customer or session]` |
| **Draft a follow-up email** | `/draft-email <who/what>` (saves to Gmail Drafts, never sends) |
| **Plan the next 2–4 sessions** | `/customer-plan --next <customer>` |
| **Build a full program plan** | `/customer-plan --full <customer>` |
| **Set up a brand-new or inherited account** | `/customer-setup <customer>` |
| **Score a delivered session against the rubric** | `/session-score <session-type>` |
| **Check Notion for data drift** | `/notion-check [--customer <name>] [--fix]` |
| **Ask how the Tracker databases work** | `/notion-ask <question>` — what to fill, what's auto-calculated, how DBs connect |
| **Answer a customer question with PB docs** | `/support-hub <query>` |
| **Sync Salesforce → Active Packages** | `/notion-sync --sf [--customer <name>] [--apply]` |
| **Repair ownership drift in Notion** | `/notion-sync --owner [--global]` |
| **Flag renewals coming up** | `/notion-sync --renewals [--days N] [--dry-run]` |
| **Build a customer-facing diagram** | `/draft-diagram <customer> <type> [description]` |

## Suggested order around a customer session

1. **Day before:** `/customer-whats-new <customer>` — surface what's changed since the last touch.
2. **Day before / morning of:** `/session-prep <customer>` — pulls context, drafts brief, lands in Notion under a `📋 Prep` toggle. For architecting sessions, also creates a customer-facing KDD sub-page.
3. **Same day after the call:** `/session-debrief <customer>` — runs summary + Notion updates + Tasks + Gmail follow-up draft + Slack debrief draft + scorecard eval, all in one go.
4. **Optional:** `/session-score <session-type>` if you want a focused scorecard review.

## Command families at a glance

- **`customer-*`** — account lifecycle (`-setup [--research|--refresh]`, `-whats-new`)
- **`customer-plan`** — program planning (`--next` for 2–4 sessions, `--full` for a complete program)
- **`session-*`** — per-session workflows (`-prep`, `-kdds`, `-summary`, `-score`, `-debrief`)
- **`bulk`** — run a session workflow across multiple meetings at once (`--debrief`, `--prep`)
- **`bulk-account-setup`** — admin/reorg task: set up all accounts owned by a user
- **`draft-*`** — message / artifact drafts (`-email`, `-followup`, `-diagram`)
- **`notion-*`** — direct Notion operations (`-write`, `-check`, `-ask`)
- **`notion-sync`** — push external data into Notion (`--sf`, `--owner`, `--renewals`)
- **`assistant-*`** — meta / configure the assistant (`-setup`, `-help`, `-remember`, `-automate`)
- **Standalone** — `/support-hub`, `/daily-brief`

## Flag reference — multi-mode commands

### `/notion-sync` — three modes, one command

| Mode | What it does | Key flags |
|---|---|---|
| `--sf` | Sync Salesforce ARR + contract end dates into Active Packages | `--customer <name>`, `--owner <name>`, `--apply` |
| `--owner` | Push Customer.Owner → Sessions, Tasks, Active Packages | `--mine` (default), `--global`, `--no-confirm` |
| `--renewals` | Set Status = Renewal on packages ending soon | `--mine` (default), `--global`, `--days N` (default 90), `--dry-run`, `--no-confirm` |

**Examples:**
```
/notion-sync --sf                          # sync SF data for all my packages
/notion-sync --sf --customer Acme          # one customer only
/notion-sync --sf --apply                  # skip approval gate
/notion-sync --owner                       # repair drift on my accounts
/notion-sync --owner --global              # repair drift workspace-wide (asks for confirmation)
/notion-sync --renewals                    # flag packages ending in ≤90 days
/notion-sync --renewals --days 60          # tighter window
/notion-sync --renewals --dry-run          # preview only, no writes
```

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
| `--full <customer>` | Build goals → milestones → phases → sessions plan; writes to Active Package in Notion on approval |

**Examples:**
```
/customer-plan --next Acme                 # tactical next-phase plan
/customer-plan --full Acme                 # full engagement program plan
```

### `/notion-check` flags

| Flag | Effect |
|---|---|
| `--customer <name>` | Scope audit to a single customer |
| `--fix` | Apply low-risk corrections automatically (null Owners, propagation drift) |

### `/customer-setup` modes

| Mode | What it does |
|---|---|
| (no flag) | Baseline — creates Customer page, Active Package, backfills sessions |
| `--research` | Baseline + deep company research (web, SF, Gong) |
| `--refresh` | Re-runs research on an existing Customer page |

## Notion

| Want to... | Run |
|---|---|
| **Create or update a Notion record** | `/notion-write <create\|update> ...` |
| **Generate a customer-facing KDD doc** for an architecting session (standalone) | `/session-kdds <customer> [session-id]` |
| **Ask how the databases work** (fill guide, formulas, interconnections, troubleshooting) | `/notion-ask <question>` |

## Maintenance

| Want to... | Run |
|---|---|
| **Correct the assistant** (style nit, new rule, fact change) | `/assistant-remember <correction>` (invokes context-keeper) |
| **Automate a new recurring task** | `/assistant-automate <task description>` (drafts a new agent + command) |
| **(Re-)onboard yourself or a teammate** to this assistant | `/assistant-setup [--update \| --reset \| --scrape-voice]` |
| **This help reference** | `/assistant-help` |

## Personal config

Your identity, voice preferences, and workspace specifics live in `about/`:

- `about/identity.md` — name, Notion user ID, role, time zone
- `about/voice.md` — sign-offs, language quirks, casual register
- `about/workspace.md` — Slack patterns, Calendly URLs, internal coordinators

To change them: edit directly, or run `/assistant-setup --update` for a guided drift check.

## Where things live

| Where | What |
|---|---|
| **Notion** | Source of truth for active engagements, per-customer state, sessions, tasks, working notes |
| **`context/notion-schema.md`** | DB schema, field formats, query patterns |
| **`context/score-cards.md`** | Per-session scorecards (Discovery, Foundations, Insights, Prioritization, Roadmaps, Spark, Success Planning, QBR) |
| **`context/pb-aise-reference-guide.md`** | Session methodology — "what good looks like" per session type |
| **`context/communication-style-guide.md`** | Universal AISE comms patterns; `about/voice.md` overrides |
| **`templates/session-kdds/`** | Customer-facing KDD anchor templates per A-session type |
| **`<PLUGIN_DATA_DIR>/about/tracker-memory.md`** | Cross-customer observations only — per-user, written by `context-keeper` (Notion is SSOT for everything else) |

## Tips

- **Don't paste context** the assistant can retrieve. Just name the customer or session — agents pull from Glean, Gmail, Calendar, Notion, Slack automatically.
- **Confirm before destructive writes.** Notion updates ask before applying unless explicitly told otherwise.
- **Customer-side actions don't go in the Tasks DB.** Only PB-side actions assigned to you. Customer commitments live in summaries / follow-ups.
- **Internal tasks** (no specific customer) point at the **Productboard** customer record automatically.

For full details on any command, see `skills/<command-name>/SKILL.md`. Agent specs are in `agents/`.

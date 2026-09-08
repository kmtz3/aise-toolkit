---
name: assistant-help
description: Quick reference of all available commands in the aise-leadership plugin, grouped by workflow stage. Run anytime you forget what's available or want to know what to run next. Pass --whatsnew (or ask "what's new") to see the latest version changes instead.
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

   > **What's new in aise-leadership [version]** — [date]
   > [bullet points from that entry, preserving the Added / Changed / Fixed grouping]
   >
   > _(If PATCH entries exist after the latest MINOR/MAJOR, list them below under a "Also fixed" heading.)_
   >
   > _Run `/assistant-help` for the full command reference._

4. Stop — do not continue to the help reference below.

---

**Otherwise (default — no flag, or help-intent phrasing):**

Here is the full command reference for the **aise-leadership** plugin.

---

## Portfolio and account visibility

| Command | What it does |
|---|---|
| `/report --customer <customer>` | Single-account snapshot — program health, credit burn, recent sessions, open items, risks, next step. Formatted for a leadership audience. |
| `/report --aise [me \| <AISE name>]` | Portfolio summary across all accounts owned by an AISE — attention queue, per-account health table, velocity, renewals due. |

**Flags available on `/report --aise`:**
- `--days N` — change the "no recent session" threshold (default 30 days)
- `--renewals-window N` — change the renewals look-ahead window (default 90 days)

**Flags available on `/report --customer`:**
- `--since YYYY-MM-DD` — limit "recent activity" to a specific window (default last 90 days)

---

## Tracker oversight

| Command | What it does |
|---|---|
| `/session-audit [--owner <aise-name>] [--customer <name>] [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--fix] [--tasks] [--dry-run]` | Reconciles logged Planhat session history against Calendar + Gong — gaps, wrong types, duplicates, misdated session times, attribution errors. Default scope: whole workspace, grouped by AISE; narrow with `--owner <aise-name>` or `--customer <name>`. `--tasks` instead audits open Planhat Tasks for completion drift, evidenced via Gmail/Glean. Read-only by default; `--fix` applies corrections with per-write read-back verification. |

> `/notion-ask` and `/notion-sync` (all modes) have been retired — Notion is no longer the working record. SF ARR/renewal data flows natively into Planhat; `/notion-check`/`/notion-fix`'s still-relevant scope is now `/session-audit` above.

---

## Configure the assistant

| Command | What it does |
|---|---|
| `/assistant-setup` | Onboard or re-onboard to this assistant — resolves your Planhat identity, sets voice preferences, workspace details. Run on first install. |
| `/assistant-remember <correction>` | Capture a correction, new rule, or changed fact into context files and memory. |
| `/assistant-improvement` | After a skill run with issues, analyze what went wrong and output a copyable coding-agent prompt naming the exact plugin, files, and fixes needed. No writes — output only. |
| `/aise-context` | Load the assistant's operating context (role, ground rules, command registry). Run at the start of any session if context seems stale. |

---

## Suggested workflow

**To review your team's portfolio:**
1. `/report --aise me` — get the full attention queue and per-account table
2. Drill into flagged accounts with `/report --customer <name>`

**To audit tracker health:**
1. `/session-audit` — reconcile session history and task completion drift across the whole workspace
2. `/session-audit --fix` — apply safe corrections, per-write read-back verified

**context/ is shared with aise-assistant.** Run `bash scripts/sync-context.sh` (dev only) to pull schema and reference guide updates from the upstream plugin.

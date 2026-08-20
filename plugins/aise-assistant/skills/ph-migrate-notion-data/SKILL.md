---
name: ph-migrate-notion-data
description: Migrate Notion Customer Tracker data into Planhat — Company field sync (phase, Journey Status, Spark, Priority), Delivered sessions as Conversations, and all Tasks as Tasks. Scoped per customer, a list, or all of an AISE's book. Uses normalized externalId/sourceId dedup, checked in both hyphen-stripped and dashed form — safe to re-run.
argument-hint: "[--customer <name> | --customers <n1,n2>] [--aise <name>] [--dry-run]"
---

Migrate Notion → Planhat data for $ARGUMENTS.

Read the procedure in [`agents/ph-migrate-notion-data.md`](../../agents/ph-migrate-notion-data.md) and execute it inline as the main assistant — do not try to spawn `ph-migrate-notion-data` as a subagent (agent files in this plugin are procedure documents, not registered subagent types).

## Flags

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--customer <name>` | "migrate Acme", "sync Acme to Planhat" | **Single customer** by name. |
| `--customers <n1,n2>` | "sync Acme and Beta", "migrate Acme, Beta, Gamma" | **List** of customers. Comma-separated. |
| *(no customer flag)* | "sync all my accounts", "migrate everything" | **All customers** owned by the AISE (default: current user). Presents a confirmation queue before writing anything. |
| `--aise <name>` | "for Ozzy", "for Tesh", "for all of Molly's accounts" | Override the AISE scope. Accepts display name or email. Default: current user. |
| `--dry-run` | "preview only", "what would happen", "show me what would sync" | Show the full migration plan (field diffs + record counts) without writing anything. |

## What gets migrated

| Notion → Planhat | Scope | Dedup key |
|---|---|---|
| **Company field update** | `phase`, Journey Status, Spark fields, csmScore, Priority | `sourceId` (SF Account ID) / Planhat `_id` |
| **Sessions → Conversations** | `Call Status = Delivered` only (not planned/canceled/in-progress) | `externalId` = Notion Session page ID |
| **Tasks → Tasks** | All statuses — open, done, canceled, blocked | `sourceId` = Notion Task page ID |

## What is NOT migrated

- Deal / LineItem / Active Package records — SF SSOT, never write from Notion
- Asset / Workspace records — synced from SF + Snowflake
- Future/planned sessions — Conversations represent past events only
- Internal tasks (`Do not count` = YES) and PB-internal tasks (Customers = Productboard)
- Source Call field — no native FK on Planhat Task linking back to a Conversation

## Safe to re-run

The migration uses `externalId` (Conversations) and `sourceId` (Tasks) as dedup keys, always normalized to hyphen-stripped lowercase hex before writing or comparing (the Notion MCP returns page `id` as a dashed UUID — writing that raw form breaks dedup and silently duplicates records). Re-running against a customer that was already migrated will skip existing records and only create net-new ones. Company field sync is always a write (idempotent — same value overwrites same value). A post-run verification pass checks for duplicate `externalId` groups and unattributed (`users: []`) Conversations — see `agents/ph-migrate-notion-data.md` §5.

## Note on session-type counts vs Notion

Notion `🎓 Training` maps to Planhat `🎓 Enablement`, and both Notion `📦 Other` and `🗣️ Sync` collapse into Planhat's `🔁 Sync`. This is intentional (see `context/notion-planhat-field-mapping.md`) — it means Notion and Planhat session-type counts will never tie out exactly for these categories. Don't mistake the discrepancy for data loss during reconciliation.

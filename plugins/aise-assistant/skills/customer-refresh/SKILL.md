---
name: customer-refresh
description: Catch up on a quiet or inherited account and bring Planhat current in one pass – full history sweep, refresh of Architecture Details, Organization Details, Engagement Plan and Next Step, AISE enrichment on the customer's End User records, a customer check-in email draft and an internal Slack update draft. Never sends.
---

Refresh the account for: **$ARGUMENTS**

Read the procedure in `agents/account-refresh.md` and execute it inline as the main assistant – do not try to spawn `account-refresh` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types).

## Flags

Canonical syntax uses flags, but recognize natural language too – "check what's up with Acme and update Planhat", "refresh Acme", "catch me up on Acme and draft a check-in" all run the default.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| *(none)* | "refresh", "catch up on", "check what's up and update Planhat", "re-engage", "bring Acme up to date" | Full run: history sweep → four Company fields → End User enrichment → check-in email draft → internal Slack draft. |
| `--dry-run` | "just show me", "don't write anything", "preview the refresh" | Build everything and show it in chat. No Planhat writes, no Gmail draft, no Slack draft. |
| `--no-email` | "internal only", "don't draft the customer email", "just Planhat and Slack" | Skip the customer check-in draft. |
| `--no-slack` | "skip Slack", "no internal update" | Skip the internal Slack draft. |
| `--since YYYY-MM-DD` | "since June", "only look at the last quarter" | Narrow the history sweep. Default is the full program window. |

## What it writes

| Where | What | Rule |
|---|---|---|
| Company `custom.Architecture Details` | Workspace build – hierarchy, teams, boards, integrations, portal | Empty → write. Populated → replace only if stale, and say what was replaced. |
| Company `custom.Organization Details` | Company, product org, stakeholders, PB team, commercial, growth signals | Titles verified against End User `position`. |
| Company `custom.Engagement Plan` | Goals, workstream status, package balance, sessions delivered, proposed sessions, open items, risks | A plan written by `/customer-plan --full` gets its status refreshed in place, not restructured. |
| Company `custom.Next Step` | Dated current state – done / waiting on / watching / when it clears | Says "drafted, send pending" until the email actually goes out. |
| End User AISE fields | `custom.AISE Relationship`, `custom.Engagement Role`, `custom.AISE Read`, `custom.AISE Read Reviewed` | Same rules as `/session-debrief` step 3b. Never creates or renames a contact. |
| Gmail Drafts | Customer check-in with session options and the matching Calendly link | Never sent. |
| Slack draft | Internal `#account-*` channel update | Never sent. Internal channel only. |

## How it differs from neighbors

- `/customer-whats-new` – read-only, short window, no drafts. Use it before a session. Use `/customer-refresh` when the account itself needs re-establishing.
- `/customer-setup` – first-touch research written as a Conversation note. `/customer-refresh` maintains the account-level fields afterwards.
- `/customer-plan --full` – builds a program plan from scratch. `/customer-refresh` keeps an existing plan's status current.

---
name: report
description: Generate a leadership-ready report. Two modes via required flag: --customer (account snapshot for one customer) or --aise (full portfolio summary for a specific AISE). Read-only — no Notion writes, no drafts.
---

Generate a management report. A mode flag is required:

- **`/report --customer <customer>`** — account snapshot: program health, credit burn, recent sessions, open items, risks, and next step for one customer
- **`/report --aise [me | <AISE name>]`** — portfolio summary across all accounts owned by an AISE: attention queue, per-account table, velocity, and renewals

If no mode flag is given, list the two modes with a one-line description and ask which to run.

---

## Flags

Canonical syntax uses flags, but also recognize natural language variations and map to the same modes. When intent is ambiguous, default to `--customer` and offer the other mode in chat.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--customer <name>` | "report on [customer]", "how is [customer] doing", "what's the status on [customer]", "update on [customer] for leadership" | Single-account snapshot — pull from Notion + Glean/Gmail |
| `--aise [me\|name]` | "my portfolio report", "report on [AISE]'s accounts", "what does [AISE]'s book look like", "portfolio status", "overview of all my accounts" | Multi-account portfolio view — Notion-only, no per-account Glean pull |

---

## `--customer` — single-account report

Generate a leadership report for: **$ARGUMENTS**

Read the procedure in `agents/report-builder.md` → **`--customer` mode** and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls Notion state (Customer, Active Package, Sessions, Tasks) + supplementary activity signals from Glean and Gmail, then renders a structured account snapshot formatted for a leadership audience.

### Steps

1. Resolve the customer in Notion (Customer page + Active Package). Verify `Owner` contains the current user's UUID — if not, surface the conflict: "This account is owned by [X], not you. Continuing as read-only." Do not stop; proceed with the report.
2. Pull in parallel:
   - **Notion** — Customer page fields, Active Package (ARR, Start/End dates, Status, credits formula), all Sessions (type, date, status, name), open Tasks (Owner-filtered to current user unless `--aise` is active)
   - **Glean `meeting_lookup`** — last 2 Gong recordings for this customer
   - **Gmail** — last 3–5 threads with the customer domain
3. Derive program state: current phase, session velocity, cadence health, credit burn trajectory.
4. Render the report (see Output Format — `--customer`).

**Additional flags:**
- `--since YYYY-MM-DD` — limit "recent activity" section to a specific window (default: last 90 days)

---

## `--aise` — portfolio report

Generate a portfolio report for: **$ARGUMENTS**

Read the procedure in `agents/report-builder.md` → **`--aise` mode** and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Queries all Notion customers owned by the target AISE, pulls the active package and most recent + next session for each, builds an attention queue (gaps, renewals, credits exhausted), and renders a portfolio table and velocity summary.

Target resolution:
- `me` or no argument → use current user's UUID (from `about/identity.md`)
- Named teammate (e.g. "Alex Doe") → call `notion-get-users`, match by display name, get their UUID. If ambiguous, list candidates and ask once.

This mode reads accounts owned by the target AISE — it does NOT apply the current-user ownership guard (this is intentionally cross-account for management visibility).

### Steps

1. Resolve the target AISE's Notion user UUID.
2. Query Notion: all Customers where `Owner LIKE '%<target-uuid>%'`.
3. For each customer in parallel: Active Package (ARR, Status, End Date, sessions contracted/delivered/remaining), most recent Delivered Session, next Planned Session, open Tasks count.
4. Build the attention queue: flag accounts with >30-day session gap, renewals within 90 days, credits exhausted or <2 remaining, Status = `Service Quota Used` with no future session planned.
5. Render the report (see Output Format — `--aise`).

**Additional flags:**
- `--days N` — change the "no recent session" threshold (default 30)
- `--renewals-window N` — change the renewals look-ahead window (default 90 days)

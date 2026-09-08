---
name: report
description: Generate a leadership-ready report. Two modes via required flag: --customer (account snapshot for one customer) or --aise (full portfolio summary for a specific AISE). Read-only against Planhat — renders in chat and publishes a designed Artifact.
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
| `--customer <name>` | "report on [customer]", "how is [customer] doing", "what's the status on [customer]", "update on [customer] for leadership" | Single-account snapshot — pull from Planhat + Glean/Gmail |
| `--aise [me\|name]` | "my portfolio report", "report on [AISE]'s accounts", "what does [AISE]'s book look like", "portfolio status", "overview of all my accounts" | Multi-account portfolio view — Planhat-only, no per-account Glean pull |
| `--chat-only` | "just show me in chat", "skip the artifact" | Suppresses the Artifact publish; inline chat rendering still happens |

---

## `--customer` — single-account report

Generate a leadership report for: **$ARGUMENTS**

Read the procedure in `agents/report-builder.md` → **`--customer` mode** and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Pulls Planhat state (Company, contracted session pool via Line Items, Conversations, Tasks) + supplementary activity signals from Glean and Gmail, then renders a structured account snapshot formatted for a leadership audience, both inline in chat and as a published Artifact.

### Steps

1. Resolve the Company in Planhat (`search_records` + SF `sourceId` fallback). `owner` is the CSM field, not necessarily the AISE — if it doesn't resolve to the current user, surface the conflict as read-only rather than stopping (see `agents/report-builder.md` § Ownership note).
2. Pull in parallel:
   - **Planhat** — Company fields (ARR, renewal date, phase, journey status), contracted session pool (Line Items), Conversations (session history, counted-eight-type split), open Tasks (owner-filtered to current user unless `--aise` is active)
   - **Glean `meeting_lookup`** — last 2 Gong recordings for this customer
   - **Gmail** — last 3–5 threads with the customer domain
3. Derive program state: current phase, session velocity, cadence health, credit burn trajectory.
4. Render the report inline, then publish it as an Artifact (unless `--chat-only`).

**Additional flags:**
- `--since YYYY-MM-DD` — limit "recent activity" section to a specific window (default: last 90 days)

---

## `--aise` — portfolio report

Generate a portfolio report for: **$ARGUMENTS**

Read the procedure in `agents/report-builder.md` → **`--aise` mode** and execute it inline as the main assistant — do not spawn a subagent.

**What it does:** Resolves the target AISE's book of accounts in Planhat, pulls the contracted pool and most recent + next session for each, builds an attention queue (gaps, renewals, credits exhausted), and renders a portfolio table and velocity summary, both inline in chat and as a published Artifact.

Target resolution:
- `me` or no argument → current user's Planhat id
- Named teammate (e.g. "Alex Doe") → resolve live via the team-roster query in `context/planhat-user-profile.md` § Team roster, matched by display name. If ambiguous, list candidates and ask once.

This mode reads accounts owned by the target AISE — it does NOT apply the current-user ownership guard (this is intentionally cross-account for management visibility).

### Steps

1. Resolve the target AISE's Planhat User id.
2. Resolve their book of accounts (Company `owner` reconciled against empirical Conversation/Task activity — see `agents/report-builder.md` § Step 2 for why neither signal is trusted blindly).
3. For each customer in parallel: contracted session pool via Line Items, most recent delivered Conversation, next planned session (Task `mainType: "event"`), open Tasks count.
4. Build the attention queue: flag accounts with >30-day session gap, renewals within 90 days, credits exhausted or <2 remaining, pool exhausted with no future session planned.
5. Render the report inline, then publish it as an Artifact (unless `--chat-only`).

**Additional flags:**
- `--days N` — change the "no recent session" threshold (default 30)
- `--renewals-window N` — change the renewals look-ahead window (default 90 days)

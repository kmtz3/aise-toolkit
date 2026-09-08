---
name: session-audit
description: Portfolio-scoped reconciliation of logged session history against what actually happened. Default scope is the whole AISE workspace; --owner <aise-name> narrows to one AISE, --customer <name> to one account. Rebuilds the real session list from Google Calendar + Gong, compares it to Planhat Conversations, and reports every gap, wrong type, duplicate, misdated session time, and attribution error — grouped by AISE when scope spans more than one. Also audits open Planhat Tasks for completion drift (--tasks). Read-only by default; --fix applies corrections with read-back verification on every write.
argument-hint: "[--owner <aise-name>] [--customer <name>] [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--fix] [--attribution] [--duplicates] [--dates] [--invariant] [--tasks] [--dry-run]"
---

Audit logged session history for $ARGUMENTS.

Read the procedure in [`agents/session-log-auditor.md`](../../agents/session-log-auditor.md) and execute it inline as the main assistant — do not try to spawn `session-log-auditor` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The per-AISE portfolio fan-out, the per-account Planhat sweep, and the write batches all get fanned out to generic subagents — see § Fan-out in that file.

## Flags

Canonical syntax uses flags; also recognize natural language equivalents.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--owner <aise-name>` | "check Ozzy's sessions", "audit Raphael's book", "just Denae's accounts" | Scopes to that AISE's delivered sessions, resolved live from the Planhat team roster. **Default (no flag): the whole workspace** — every AISE on the operator's team. This is the expensive default; the agent states team size and window and confirms before running unless the request already signals urgency. |
| `--customer <name>` | "just Kpler", "for S&P Global Ratings only" | Scopes to one account instead of an AISE's (or the whole team's) book. Owning AISE(s) derived empirically from that account's own records. |
| `--from` / `--to` | "this year", "since April", "Jan to Jun", "last quarter" | Window. Defaults to Jan 1 of the current year through today. |
| `--fix` | "and fix them", "apply the corrections" | Applies corrections. **Default is read-only.** |
| `--attribution` | "are sessions credited to the right AISE", "check the team members field" | Runs the attribution check only (§ Step 7) and skips gap detection. |
| `--duplicates` | "find duplicate sessions", "dedupe the log" | Runs duplicate detection only (§ Step 6c). |
| `--dates` | "are session times right", "fix the session times", "check for midnight timestamps" | Runs the session-time check only (§ Step 6f) — compares every matched record's `date` against the calendar event start and reports time-only vs day drift. Read-only without `--fix`. |
| `--invariant` | "check for duplicate sessions on the same day", "is anything double-counted tenant-wide" | Runs the one-counted-session-per-customer-per-date invariant (§ Step 6d) across **all** companies and every AISE via eight per-type queries. Ignores `--owner`/`--customer` — inherently portfolio-wide. Read-only. |
| `--tasks` | "what tasks are stale across the team", "find completion drift", "past-due tasks that are probably done" | Runs **Task completion drift** (§ Task completion drift) instead of the session-reconciliation procedure. Same `--owner`/default-whole-workspace scoping, applied to Planhat Tasks instead of Conversations. |
| `--dry-run` | "show me what you'd change" | With `--fix`, prints the write plan and stops. |

## What it does

1. Resolves scope — whole workspace by default, one AISE via `--owner` (live Planhat team roster, no stored roster), or one customer via `--customer` (owner derived empirically, grouped by AISE if shared) — then builds a shared domain → Planhat Company map.
2. For each AISE in scope (fanned out when there's more than one, § Fan-out): pulls the Planhat session universe per `companyId` — **never filtered on `source`** (see § Hard-won rules).
3. Pulls Google Calendar for the window and reduces it to genuine external customer sessions.
4. Corroborates with Gong where the calendar is the only evidence, and for attendance — including an occurrence check on every candidate create, because an accepted RSVP does not mean the meeting was held.
5. Reconciles calendar against Planhat with a scored, one-to-one matcher.
6. Runs the duplicate invariant — one counted session per customer per calendar date — and classifies every row: correct · missing · wrong type · typed as `note` · duplicate · **misdated** · not-a-session artifact · blocked (no Planhat Company) · another AISE's — and separates records that **count** as delivery from those that don't.
7. Checks every matched record's `date` against the calendar event start (§ Step 6f). Planhat stamps a converted calendar-event Conversation with the moment its Task was marked done rather than the session start, so session times are wrong by default — this is the pass that finds and repairs them. Time-only drift is safe to correct in bulk; day drift is reported for a human, never auto-written.
8. Checks each AISE is in the `users` (team members) field on their own sessions.
9. Reports — a published artifact plus a CSV keyed on Planhat record ID, with session counts stated on the counted-type subset and a before/after per affected account, **grouped by AISE when scope spans more than one**.
10. With `--fix`: creates, retypes, redates (including the misdated pass above), merges-and-archives, and repairs attribution — across every AISE whose findings were approved. Candidate creates are checked against existing `externalId`s first — a hit becomes a repair, not a create — and re-checked for cancellation signals. Every `_id` is validated against its own row before it is written to, and every write is read back.

## Non-negotiables

- **Read-only unless `--fix`.** The first pass of this audit exists to be checked before anything is written.
- **Never hard-delete.** Duplicates get merged into the surviving record and then archived (`archived: true` is writable). Deletion needs explicit per-record instruction from the operator.
- **Never reassign a session another AISE delivered**, and never strip an AISE off a record to add someone else — add, don't replace, unless the operator names the record.
- **Do not create a record for a session with no evidence it happened.** An accepted RSVP is not that evidence — invites outlive their own cancellation. A gap is better than a fabricated touchpoint. Report the unconfirmed ones and let the operator decide.
- **Validate every `_id` against its own row before writing to it.** Re-read the record and confirm date, subject and company match. A misplaced id writes to the wrong record — and in a whole-workspace run, potentially credits the wrong AISE — and reports success.
- **Read back every write.** `endusers` fails silently; see § Hard-won rules.
- **State the whole-workspace scope before running it.** The default (no `--owner`) fans out across every AISE on the team — say how many and what window before proceeding.

### What counts as a delivered session

Only these eight `type` values register in leadership's session counts and in `custom.Last AISE Session`:

`🎓 Enablement` · `🔁 Sync` · `🏗️ Architecting` · `👟 Kick off` · `🔎 Discovery` · `🏁 Audit / Setup Review` · `🎙️ Demo` · `📆 Onsite Workshop`

`📺 Webinar`, `Internal Alignment`, `Sales Handover`, `🧑‍💻 Billable Task`, `👾 Gong Call` and `note` do **not** count.
Consequences: never offer a retype between two uncounted types as a count fix; always express impact as counted
records before → after, per AISE and in the portfolio total; and remember `archived: true` removes a record from
the count, which is why duplicates are archived rather than deleted. Full detail and the live formula:
`context/planhat-schema.md` § Which session types count toward delivery.

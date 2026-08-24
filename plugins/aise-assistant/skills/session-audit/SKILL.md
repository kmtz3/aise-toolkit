---
name: session-audit
description: Reconcile logged session history against what actually happened. Rebuilds the real session list for an AISE, a customer, or a date range from Google Calendar + Gong, compares it to Planhat Conversations, and reports every gap, wrong type, duplicate, and attribution error. Read-only by default; --fix applies corrections with read-back verification on every write.
argument-hint: "[--aise <name>|me] [--customer <name>] [--from YYYY-MM-DD] [--to YYYY-MM-DD] [--fix] [--attribution] [--duplicates] [--invariant]"
---

Audit logged session history for $ARGUMENTS.

Read the procedure in [`agents/session-log-auditor.md`](../../agents/session-log-auditor.md) and execute it inline as the main assistant — do not try to spawn `session-log-auditor` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The per-account Planhat sweep and the write batches DO get fanned out to generic subagents — see § Fan-out in that file.

## Flags

Canonical syntax uses flags; also recognize natural language equivalents.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--aise <name>` | "check Ozzy's sessions", "audit for Raphael", "for every AISE" | Scopes to that AISE's delivered sessions. Defaults to the current user. `all` sweeps the whole team — expensive, confirm first. |
| `--customer <name>` | "just Kpler", "for S&P Global Ratings only" | Scopes to one account instead of the AISE's whole book. |
| `--from` / `--to` | "this year", "since April", "Jan to Jun", "last quarter" | Window. Defaults to Jan 1 of the current year through today. |
| `--fix` | "and fix them", "apply the corrections" | Applies corrections. **Default is read-only.** |
| `--attribution` | "am I on my own sessions", "check the team members field" | Runs the attribution check only (§ Step 7) and skips gap detection. |
| `--duplicates` | "find duplicate sessions", "dedupe the log" | Runs duplicate detection only (§ Step 6c). |
| `--invariant` | "check for duplicate sessions on the same day", "is anything double-counted", "tenant-wide duplicate check" | Runs the one-counted-session-per-customer-per-date invariant (§ Step 6d) across **all** companies via eight per-type queries, not just the scoped AISE's book. Read-only. |
| `--dry-run` | "show me what you'd change" | With `--fix`, prints the write plan and stops. |

## What it does

1. Resolves the AISE and the account set, then builds a domain → Planhat Company map for matching.
2. Pulls the Planhat session universe per `companyId` — **never filtered on `source`** (see § Hard-won rules).
3. Pulls Google Calendar for the window and reduces it to genuine external customer sessions.
4. Corroborates with Gong where the calendar is the only evidence, and for attendance — including an occurrence check on every candidate create, because an accepted RSVP does not mean the meeting was held.
5. Reconciles calendar against Planhat with a scored, one-to-one matcher.
6. Runs the duplicate invariant — one counted session per customer per calendar date — and classifies every row: correct · missing · wrong type · typed as `note` · duplicate · not-a-session artifact · blocked (no Planhat Company) · another AISE's — and separates records that **count** as delivery from those that don't.
7. Checks the AISE is in the `users` (team members) field on their own sessions.
8. Reports — a published artifact plus a CSV keyed on Planhat record ID, with session counts stated on the counted-type subset and a before/after per affected account.
9. With `--fix`: creates, retypes, redates, merges-and-archives, and repairs attribution. Candidate creates are checked against existing `externalId`s first — a hit becomes a repair, not a create — and re-checked for cancellation signals. Every `_id` is validated against its own row before it is written to, and every write is read back.

## Non-negotiables

- **Read-only unless `--fix`.** The first pass of this audit exists to be checked before anything is written.
- **Never hard-delete.** Duplicates get merged into the surviving record and then archived (`archived: true` is writable). Deletion needs explicit per-record instruction from the user.
- **Never reassign a session another AISE delivered**, and never strip an AISE off a record to add someone else — add, don't replace, unless the user names the record.
- **Do not create a record for a session with no evidence it happened.** An accepted RSVP is not that evidence — invites outlive their own cancellation. A gap is better than a fabricated touchpoint. Report the unconfirmed ones and let the user decide.
- **Validate every `_id` against its own row before writing to it.** Re-read the record and confirm date, subject and company match. A misplaced id writes to the wrong record and reports success.
- **Read back every write.** `endusers` fails silently; see § Hard-won rules.

### What counts as a delivered session

Only these eight `type` values register in leadership's session counts and in `custom.Last AISE Session`:

`🎓 Enablement` · `🔁 Sync` · `🏗️ Architecting` · `👟 Kick off` · `🔎 Discovery` · `🏁 Audit / Setup Review` · `🎙️ Demo` · `📆 Onsite Workshop`

`📺 Webinar`, `Internal Alignment`, `Sales Handover`, `🧑‍💻 Billable Task`, `👾 Gong Call` and `note` do **not** count.
Consequences: never offer a retype between two uncounted types as a count fix; always express impact as counted
records before → after; and remember `archived: true` removes a record from the count, which is why duplicates are
archived rather than deleted. Full detail and the live formula: `context/planhat-schema.md`
§ Which session types count toward delivery.

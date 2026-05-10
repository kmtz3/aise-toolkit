---
name: notion-fix
description: Portfolio-wide hunt for delivered sessions and completed tasks that weren't updated in Notion. Scans all AISEs' records by default (whole workspace); narrow with --owner <aise-name>. Finds sessions still marked Planned after their Call Date and open tasks that are past due or due this week, then cross-references Gmail, Gong, and Glean for evidence of completion or delivery. Reports grouped by AISE with per-item evidence strength. Applies corrections with explicit per-item confirmation on --fix.
---

Find and fix completion drift in the Notion customer tracker across the full AISE portfolio.

Read the procedure in `agents/notion-completion-fix.md` and execute it inline as the main assistant — do not try to spawn `notion-completion-fix` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the operator's identity from the `AISE Identity` Notion page. If `--owner <name>` is supplied, also resolve the target AISE's UUID from the `AISE Leadership Team Roster` Notion page.
2. Query Sessions with `Call Status = Planned` (or `Postponed`) AND `Call Date < today` within the look-back window. Default scope: whole workspace (no owner filter). With `--owner`: filter to that AISE's `Current Account Owner`.
3. Query Tasks with `Status ≠ Done AND Status ≠ Canceled AND Due Date ≤ today+7 days`. Same scope rules. Exclude internal Productboard tasks.
4. For each candidate, search Gmail, Gong (via Glean `meeting_lookup`), and Glean/Slack for evidence the session was delivered or the task was completed — classify each as 🟢 Strong, 🟡 Weak, or 🔴 None.
5. Surface findings grouped by AISE owner, then by record type (sessions / tasks), with per-item evidence summary and recommended action.
6. If `--fix`: prompt per item for confirmation, then apply approved corrections (session → `Delivered`, task → `Done`). For sessions, set `Delivered By` to the account-owning AISE's UUID (from `Current Account Owner`), never to the operator's.

**Default scope:** whole workspace — all AISEs' records, no owner filter. This is by design for portfolio-level oversight. Narrow with `--owner` or `--customer`.

**Flags:**
- `--owner <aise-name>` – scope to a single AISE's portfolio (resolved via Team Roster page)
- `--customer <name>` – scope to a single customer's record tree (any owner)
- `--past <period>` – session look-back window (e.g. `--past 30d`, `--past 4w`; default: `14d`)
- `--fix` – apply corrections with per-item confirmation (default: read-only report)
- `--dry-run` – report only; suppresses writes even if `--fix` is present

**Evidence levels:**
- 🟢 **Strong** — Gong recording found on or near the Call Date, or a Gmail follow-up sent within 7 days of the planned call date
- 🟡 **Weak** — indirect signals (email mention, meeting invite without recording, tangential Slack message)
- 🔴 **None** — no external signals found after all search types are exhausted

Only 🟢 strong-evidence items are eligible for `--fix`. 🟡 and 🔴 items always surface as read-only findings.

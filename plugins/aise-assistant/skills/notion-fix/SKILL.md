---
name: notion-fix
description: Hunt for delivered sessions and completed tasks that weren't updated in Notion. Finds sessions still marked Planned after their Call Date and open tasks that are past due or due this week, then cross-references Gmail, Gong, and Glean for evidence of completion or delivery. Reports with per-item evidence strength. Applies corrections with explicit per-item confirmation on --fix.
---

Find and fix completion drift in the Notion customer tracker for the current user's records.

Read the procedure in `agents/notion-completion-fix.md` and execute it inline as the main assistant — do not try to spawn `notion-completion-fix` as a subagent (custom agents in this plugin are procedure documents, not registered subagent types). The steps:

1. Resolve the current user's identity from the `AISE Identity` Notion page to get `<user-uuid>`.
2. Query the user's Sessions for `Call Status = Planned` (or `Postponed`) AND `Call Date < today` within the look-back window.
3. Query the user's Tasks for `Status ≠ Done AND Status ≠ Canceled AND Due Date ≤ today+7 days` (open tasks that are overdue or due this week). Exclude internal Productboard tasks.
4. For each candidate, search Gmail, Gong (via Glean `meeting_lookup`), and Glean/Slack for evidence the session was delivered or the task was completed — classify each as 🟢 Strong, 🟡 Weak, or 🔴 None.
5. Surface findings grouped by type (sessions / tasks) with per-item evidence summary and recommended action.
6. If `--fix`: prompt per item for confirmation, then apply approved corrections (session → `Delivered`, task → `Done`). Never auto-apply without confirmation.

**Default scope:** the current user's records only (`Current Account Owner` = current user for Sessions/Tasks; `Owner` = current user for Tasks). Pass `--customer <name>` to narrow to one account.

**Flags:**
- `--customer <name>` – check a single customer's record tree only
- `--past <period>` – session look-back window (e.g. `--past 30d`, `--past 4w`; default: `14d`)
- `--fix` – apply corrections with per-item confirmation (default: read-only report)
- `--dry-run` – report only; suppresses writes even if `--fix` is present

**Evidence levels:**
- 🟢 **Strong** — Gong recording found on or near the Call Date, or a Gmail follow-up sent by the user within 7 days of the planned call date
- 🟡 **Weak** — indirect signals (email mention, meeting invite without recording, tangential Slack message)
- 🔴 **None** — no external signals found after all search types are exhausted

Only 🟢 strong-evidence items are eligible for `--fix` auto-correct. 🟡 and 🔴 items always surface as read-only findings for manual judgment.

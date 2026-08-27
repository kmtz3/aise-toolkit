---
name: ph-reconcile-gong-gcal
description: Merge standalone "👾 Gong Call" Planhat Conversations into the matching GCal-synced session Conversation (transcript, Gong URL → target's custom.Call Recording, description) and delete the redundant Gong Call record. Scoped per customer or the whole workspace, dry-run by default.
argument-hint: "[--customer <name>] [--since YYYY-MM-DD] [--apply] [--window-hours N]"
---

Reconcile Gong Call Conversations into their GCal session records for $ARGUMENTS.

Read the procedure in [`agents/ph-reconcile-gong-gcal.md`](../../agents/ph-reconcile-gong-gcal.md) and execute it inline as the main assistant — do not try to spawn `ph-reconcile-gong-gcal` as a subagent (agent files in this plugin are procedure documents, not registered subagent types).

## Why this exists

Gong's native sync into Planhat writes every call as its own standalone `👾 Gong Call` Conversation. Planhat's Google Calendar sync separately creates the real session Conversation for the same meeting. The two never get merged automatically today — this is a manual stopgap while the Planhat↔Gong integration is reworked to do that merge on write. Run this periodically (or ad hoc per customer) until that lands.

## Flags

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--customer <name>` | "reconcile Acme's Gong calls", "clean up Acme" | Scope to one customer. Default: whole workspace. |
| `--since YYYY-MM-DD` | "since last week", "from Aug 1" | Only consider Gong Call Conversations dated on/after this date. **Recommended on a first run** to bound scope. |
| `--apply` | "actually do it", "run it live", "apply the merges" | Write merges and delete Gong Call records. Still asks for one confirmation on the plan before executing. |
| *(no `--apply`)* | "preview", "dry run", "show me what would happen" | **Default.** Shows the full match plan — no writes, no deletes. |
| `--window-hours N` | "widen the match window to 6 hours" | Half-width of the date-proximity window used to find a Gong call's target session. Default `4`. |

## Matching is not ID-based

Gong Call `externalId` is `{gongCallId}-{salesforceAccountId}` — it does not carry the Google Calendar event ID, Planhat's `Conversation` model has no `sourceId` field at all, and neither the connected Gong MCP tools nor Glean's indexed Gong metadata expose a calendar event ID either (checked directly — see `agents/ph-reconcile-gong-gcal.md` § Matching is NOT ID-based). Matching instead uses a weighted score across three signals, all already present on the Conversation record with no extra Gong/Glean lookups needed:

| Signal | Weight | Source |
|---|---|---|
| Attendee overlap | 0.40 | `endusers`/`users` — Gong's native sync already resolves participants to Planhat `EndUser`/`User` IDs, so this is exact-ID overlap, not fuzzy text matching. |
| Subject similarity | 0.35 | Normalized word-overlap after stripping punctuation/emoji and common session-title stopwords. |
| Date proximity | 0.25 | How close the two call times are within the match window (default ±4h). |

Every match is reported with its full score breakdown, not just a confidence label — see § What it does per matched pair.

## What it does per matched pair

1. Finds the target session Conversation (GCal-synced, same company) by weighted-scoring every candidate in the date window on attendee overlap, subject similarity, and date proximity, then taking the top scorer if it clears the confidence threshold and isn't within 0.05 of a runner-up.
2. Writes the Gong URL onto the target's **`custom.Call Recording`** field (not `custom.Gong URL` — that field is retired for this purpose, see below) and `transcript` **only if those fields are currently empty** — a populated field is treated as a conflict and reported, never overwritten.
3. Appends the Gong call summary (reformatted into Planhat's rich-text vocabulary) to the target's `description`, after a divider — additive, never replaces existing content.
4. Reads the target back to confirm the write landed, then deletes the Gong Call Conversation.

## What it never does

- Never creates a Conversation or Task.
- Never deletes a Gong Call record without a verified merge write-back.
- Never overwrites a non-empty `custom.Call Recording` or transcript. Never writes to `custom.Gong URL` on the target — that field is only ever read from the source Gong Call record (Gong's own sync writes it there; corrected 2026-08-27).
- Never auto-resolves an ambiguous match (top score below threshold, or two-plus candidates scoring within 0.05 of each other) — always reported with full score breakdowns for manual review.

## Safe to re-run

Ambiguous matches, conflicts, and unmatched records are left untouched every run, so re-running after a manual fix picks up exactly where the last run left off. Checkpointed per record — an interrupted run resumes without re-processing already-resolved records (see `agents/ph-reconcile-gong-gcal.md` § Checkpoint & resumability).

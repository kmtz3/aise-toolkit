---
name: log-slack-threads
description: Log shared-Slack-channel threads as Planhat Conversations of type Slack Chat on the customer, one Conversation per thread, dated on the first message. Deduplicates and backfills new replies into existing records via a deterministic Slack externalId. Triggers – /log-slack-threads, 'log this Slack channel', 'log Slack threads for {customer}', 'backfill Slack conversations'.
argument-hint: "[--channel <url|#name|id>] [--customer <name>] [--since YYYY-MM-DD] [--backfill-only] [--new-only] [--limit N] [--dry-run]"
---

Log Slack threads into Planhat for $ARGUMENTS.

Read the procedure in [`agents/slack-thread-logger.md`](../../agents/slack-thread-logger.md) and execute it inline as the main assistant – do not try to spawn `slack-thread-logger` as a subagent (agent files in this plugin are procedure documents, not registered subagent types). The per-thread read + render + write is fanned out to generic subagents in batches – see § Fan-out in that file.

## Flags

Canonical syntax uses flags; also recognize natural language equivalents.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--channel <url\|#name\|id>` | a pasted `productboard.slack.com/archives/...` link, "the Kpler shared channel", "#ext-acme-productboard" | The channel to sweep. A pasted archive URL is the most reliable form – the ID is the path segment after `/archives/`. |
| `--customer <name>` | "for Kpler", "under Acme" | Planhat Company to log against. Default: resolve from the external members' email domain (see § Company resolution). |
| `--since YYYY-MM-DD` | "since April", "this year", "last 3 months" | Only consider threads whose **first message** is on or after this date. Default: the whole channel history. |
| `--backfill-only` | "just check for new replies", "update the ones already logged" | Skip creates. Only re-check already-logged threads for new replies. |
| `--new-only` | "skip the backfill", "just the new threads" | Skip the reply-backfill pass. Only create Conversations for threads with no existing record. |
| `--limit N` | "just do 5", "start with the 10 most recent" | Cap the number of threads processed this run. Newest first. |
| `--dry-run` | "show me what you'd log", "preview" | Print the full plan – creates, backfills, skips – and write nothing. |

## What it does

1. Resolves the channel and the Planhat Company, then pulls the full channel history (paginated).
2. Classifies every top-level message: **thread** (has replies), **standalone substantive** (a real question, update, or recap with no replies), or **noise** (joins, channel-description changes, canvas notices, bare emoji, one-line logistics). Noise is never logged.
3. **Backfill pass** – for every existing `💬 Slack Chat` Conversation on that Company dated within the last 365 days, parses its `externalId` back to a channel + parent timestamp, re-reads the thread, and compares the live message count against the `Sync:` watermark in the record's footer. Grown threads get their `description` rebuilt in place. Same record, same `externalId`, same `date`.
4. **Create pass** – for every in-scope thread with no existing record, reads the thread, renders it, and creates one Conversation.
5. Reports a per-thread table – created · backfilled · unchanged · skipped-as-noise – with the record IDs.

## Non-negotiables

- **One Conversation per thread.** Never merge two threads into one record, and never split a thread across records.
- **`date` is the first message of the thread**, never the last reply and never the run date. This is what makes the Planhat timeline read chronologically.
- **`externalId` is the dedup key, always present, always the same format:** `slack_{channelId}_{parentTsDigits}` – lower-case prefix, upper-case Slack channel ID, thread-parent timestamp with the dot removed (`slack_C0AKKLJCB5E_1786006420396099`). Built by the helper in § 3 of the agent file, never by hand. Checked before every create, read back and asserted after every create, and repaired to canonical on any legacy record found. A record with a missing or off-format key is invisible to the next run and gets silently duplicated.
- **Legacy repair runs before the backfill pass** on every invocation, normalizing off-format keys on existing `💬 Slack Chat` records for the account. Repairs touch `externalId` only, never `date` or `subject`.
- **Backfill never re-dates and never re-creates.** A thread that gained replies is an `update_model_record` on the existing `_id`, keeping `date` and `externalId` untouched.
- **`💬 Slack Chat` does not count toward session delivery.** It is a touchpoint record, not a session. Never use it to fill a session gap, and never retype an uncounted Slack record into a counted session type to make a number move.
- **Renderer constraints are not cosmetic** – Planhat's rich-text editor silently mangles common HTML. Follow § Description HTML in the agent file exactly: no `<div>`, no `<table>`, no `<ol>`/`<ul>`, no `background`/`border`/`color` styles, no literal newlines in the markup.
- **Never post to Slack.** This skill is read-only against Slack.

## Related

- `context/planhat-schema.md` § Slack Chat Conversations – field mapping, `externalId` format, and the footer watermark.
- `/log-feedback` – for turning a Slack thread into Productboard product feedback rather than a Planhat touchpoint.

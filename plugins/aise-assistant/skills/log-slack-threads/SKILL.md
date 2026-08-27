---
name: log-slack-threads
description: Log shared-Slack-channel threads as Planhat Conversations of type Slack Chat on the customer, one Conversation per thread, dated on the last message in the thread. Takes either a channel or a customer name – resolves the missing half and caches the pairing on the Planhat Company so later runs skip resolution. Deduplicates and backfills new replies into existing records via a deterministic Slack externalId. Triggers – /log-slack-threads, 'log this Slack channel', 'log Slack threads for {customer}', 'backfill Slack conversations'.
argument-hint: "[--channel <url|#name|id>] [--customer <name>] [--since YYYY-MM-DD] [--backfill-only] [--new-only] [--limit N] [--dry-run]"
---

Log Slack threads into Planhat for $ARGUMENTS.

Read the procedure in [`agents/slack-thread-logger.md`](../../agents/slack-thread-logger.md) and execute it inline as the main assistant – do not try to spawn `slack-thread-logger` as a subagent (agent files in this plugin are procedure documents, not registered subagent types). The per-thread read + render + write is fanned out to generic subagents in batches – see § Fan-out in that file.

## Flags

Canonical syntax uses flags; also recognize natural language equivalents.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--channel <url\|#name\|id>` | a pasted `productboard.slack.com/archives/...` link, "the Kpler shared channel", "#ext-acme-productboard" | The channel to sweep. A pasted archive URL is the most reliable form – the ID is the path segment after `/archives/`. Omit it and the channel is looked up from the customer's cached `custom.External_Slack_Channel_ID`. |
| `--customer <name>` | "for Kpler", "under Acme" | Planhat Company to log against. Omit it and the company is resolved from the channel's external email domains, falling back on the channel name. |
| `--no-cache` | "don't save the channel", "just this once" | Skip the write-back to `custom.External_Slack_Channel_ID`. Use when sweeping a channel that is not the account's canonical shared channel. |
| `--since YYYY-MM-DD` | "since April", "this year", "last 3 months" | Only consider threads whose **first message** is on or after this date. Default: the whole channel history. |
| `--backfill-only` | "just check for new replies", "update the ones already logged" | Skip creates. Only re-check already-logged threads for new replies. |
| `--new-only` | "skip the backfill", "just the new threads" | Skip the reply-backfill pass. Only create Conversations for threads with no existing record. |
| `--limit N` | "just do 5", "start with the 10 most recent" | Cap the number of threads processed this run. Newest first. |
| `--dry-run` | "show me what you'd log", "preview" | Print the full plan – creates, backfills, skips – and write nothing. |

## What it does

1. Resolves the channel and the Planhat Company – in whichever direction the input allows – and caches the
   pairing on the Company for next time (§ Channel resolution below). Then pulls the full channel history
   (paginated).
2. Classifies every top-level message: **thread** (has replies), **standalone substantive** (a real question, update, or recap with no replies), or **noise** (joins, channel-description changes, canvas notices, bare emoji, one-line logistics). Noise is never logged.
3. **Backfill pass** – for every existing `💬 Slack Chat` Conversation on that Company dated within the last 365 days, parses its `externalId` back to a channel + parent timestamp, re-reads the thread, and compares the live message count against the `Sync:` watermark in the record's footer. Grown threads get their `description` rebuilt in place. Same record, same `externalId`, same `date`.
4. **Create pass** – for every in-scope thread with no existing record, reads the thread, renders it, and creates one Conversation.
5. Reports a per-thread table – created · backfilled · unchanged · skipped-as-noise – with the record IDs.

## Channel resolution

Either half of the customer↔channel pair is enough; the procedure resolves the other and remembers it.
`Company.custom.External_Slack_Channel_ID` is the cache – the shared channel's Slack **ID**, upper-case, ID only.

**Given a channel** (URL, ID, or `#name`) – resolve the company from the modal non-`productboard.com` email
domain across the channel's authors, matched against `Company.domains`. If that is inconclusive, fall back on
the channel name (`#ext-acme-corp-productboard` → `acme corp`) matched against `Company.name`. Confirm the
company in chat, then cache the channel ID on it.

**Given a customer** – read `custom.External_Slack_Channel_ID`. Populated, and it reads: use it, no search.
Empty: sweep `slack_search_channels` for the `#ext-{customer}` convention (then `ext-{domain label}`), and if
that misses, ask for the URL or ID. Cache whatever resolves.

> `custom.Slack ID` and `custom.Slack URL` are **not** candidates. Those hold the **internal** Productboard
> channel for the account – RevOps-owned, frequently populated, and containing no customer. Logging one would
> put Productboard's internal discussion of a customer onto that customer's own timeline. `custom.External_Slack_Channel_ID`
> is the only field that records a shared external channel.

The field is new, so Planhat's MCP metadata may not list it yet. A rejected or non-sticking write is reported
once and the sweep continues – the cache is an optimization, not a prerequisite.

A cached ID that fails to read is reported, never used as a trigger to fall through the ladder and overwrite
the field. A resolved channel that disagrees with a populated cache is a conflict to surface, not a value to
overwrite – an account can legitimately have two shared channels, and the field holds one.

## Non-negotiables

- **One Conversation per thread.** Never merge two threads into one record, and never split a thread across records.
- **`date` is the last message of the thread**, never the run date. This matches how Planhat dates a multi-part email conversation, and it is what makes `custom.Last AISE Touch` reflect the real last touch instead of the date the thread opened. The thread start is preserved in `custom.First message time` and in the `externalId` parent ts.
- **`externalId` is the dedup key, always present, always the same format:** `slack_{channelId}_{parentTsDigits}` – lower-case prefix, upper-case Slack channel ID, thread-parent timestamp with the dot removed (`slack_C0AKKLJCB5E_1786006420396099`). Built by the helper in § 3 of the agent file, never by hand. Checked before every create, read back and asserted after every create, and repaired to canonical on any legacy record found. A record with a missing or off-format key is invisible to the next run and gets silently duplicated.
- **Legacy repair runs before the backfill pass** on every invocation, normalizing off-format keys on existing `💬 Slack Chat` records for the account. Repairs touch `externalId` only, never `date` or `subject`.
- **Backfill re-dates forward and never re-creates.** A thread that gained replies is an `update_model_record` on the existing `_id`: `date` moves forward to the new last message alongside the rebuilt `description`, `externalId` and `custom.First message time` stay untouched, and `date` never moves backward.
- **`💬 Slack Chat` does not count toward session delivery.** It is a touchpoint record, not a session. Never use it to fill a session gap, and never retype an uncounted Slack record into a counted session type to make a number move.
- **Renderer constraints are not cosmetic** – Planhat's rich-text editor silently mangles common HTML. Follow § Description HTML in the agent file exactly: no `<div>`, no `<table>`, no `<ol>`/`<ul>`, no `background`/`border`/`color` styles, no literal newlines in the markup.
- **Every record names its participants.** `users` (Productboard) and `endusers` (customer) are written on
  every Conversation, resolved from who actually **authored** messages in the thread – never from `@`-mentions,
  cc's or follow-up owners. A one-sided thread gets one side and the other key omitted, never an empty array.
  `endusers` fails silently on write, so both are read back and asserted. A participant with no `End User`
  record is named in the report, not created.
- **Never edit contact identity data.** This skill links to `End User` records; it never changes their `name`,
  `firstName`, `lastName`, `email` or `position`. Those are the customer's own data, often Salesforce-synced.
  Malformed contacts spotted during a sweep are reported and fixed only on the user's explicit go-ahead.
- **Never post to Slack.** This skill is read-only against Slack.
- **Never sweep a channel whose company you have not confirmed.** Writing one customer's private support
  history onto another's Planhat timeline is the worst failure this skill can produce, and it is not
  reversible in the customer's eyes. Zero or ambiguous matches: stop and ask.
- **Never overwrite a populated `custom.External_Slack_Channel_ID` without asking.** The cache is only worth
  having if it is stable across runs.
- **Never read or sweep `custom.Slack ID` / `custom.Slack URL`.** Internal account channel, not the customer's.

## Related

- `context/planhat-schema.md` § Slack Chat Conversations – field mapping, `externalId` format, the footer watermark, and the `custom.External_Slack_Channel_ID` cache contract.
- `/log-feedback` – for turning a Slack thread into Productboard product feedback rather than a Planhat touchpoint.

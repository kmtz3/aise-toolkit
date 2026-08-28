---
name: log-slack-threads-internal
description: Log internal Productboard #account-** Slack channel threads as Planhat Conversations of type Internal Alignment on the customer, one Conversation per thread, dated on the last message in the thread. Takes either a channel or a customer name – resolves the missing half against Company.custom.Slack ID and, on confirmation, caches the channel there (custom.Slack URL is a derived formula field, never written). Deduplicates and backfills new replies into existing records via a deterministic Slack externalId – same format and mechanics as /log-slack-threads. Triggers – /log-slack-threads-internal, 'log internal Slack comms for {customer}', 'log our internal account channel', 'backfill internal Slack alignment notes'.
argument-hint: "[--channel <url|#name|id>] [--customer <name>] [--since YYYY-MM-DD] [--backfill-only] [--new-only] [--limit N] [--dry-run]"
---

Log internal-account Slack threads into Planhat for $ARGUMENTS.

Read the procedure in [`agents/slack-thread-logger-internal.md`](../../agents/slack-thread-logger-internal.md)
and execute it inline as the main assistant – do not try to spawn `slack-thread-logger-internal` as a subagent
(agent files in this plugin are procedure documents, not registered subagent types). The per-thread read +
render + write is fanned out to generic subagents in batches – see § Fan-out in that file.

This is the sibling of `/log-slack-threads`, which sweeps the **shared external** channel
(`#ext-{customer}`) and logs `💬 Slack Chat`. This command sweeps the **internal**, Productboard-only channel
(`#account-{customer}`) and logs `Internal Alignment`. Do not use this command for a channel that has any
customer participants in it – that is the other skill's target.

## Flags

Canonical syntax uses flags; also recognize natural language equivalents.

| Flag | Natural language equivalents | What it does |
|---|---|---|
| `--channel <url\|#name\|id>` | a pasted `productboard.slack.com/archives/...` link, "our internal Acme channel", "#account-acme-corp" | The internal channel to sweep. A pasted archive URL is the most reliable form. Omit it and the channel is looked up from `custom.Slack ID` on the customer's Company record. |
| `--customer <name>` | "for Kpler", "under Acme" | Planhat Company to log against. Omit it and the company is resolved from the channel name (`#account-acme-corp` → `acme corp`), confirmed against message authorship. |
| `--no-cache` | "don't save the channel", "just this once" | Skip the write-back confirmation prompt for `custom.Slack ID`. Use when sweeping a channel that is not the account's canonical internal channel. |
| `--since YYYY-MM-DD` | "since April", "this year", "last 3 months" | Only consider threads whose **first message** is on or after this date. Default: the whole channel history. |
| `--backfill-only` | "just check for new replies", "update the ones already logged" | Skip creates. Only re-check already-logged threads for new replies. |
| `--new-only` | "skip the backfill", "just the new threads" | Skip the reply-backfill pass. Only create Conversations for threads with no existing record. |
| `--limit N` | "just do 5", "start with the 10 most recent" | Cap the number of threads processed this run. Newest first. |
| `--dry-run` | "show me what you'd log", "preview" | Print the full plan – creates, backfills, skips – and write nothing. |

## What it does

1. Resolves the channel and the Planhat Company – in whichever direction the input allows – and, **only on
   the user's explicit confirmation**, writes the channel to `Company.custom.Slack ID` (§ Channel resolution
   below — `custom.Slack URL` is a derived formula field and is never written). Then pulls the full channel
   history (paginated).
2. Classifies every top-level message: **thread** (has replies), **standalone substantive** (a real question,
   update, or recap with no replies), **broadcast reply** (already belongs to its parent thread's record), or
   **noise** (joins, channel-description changes, canvas notices, bare emoji, one-line logistics). Noise and
   broadcast replies are never logged. A thread carrying a non-`productboard.com` author is flagged rather than
   silently logged – see § Channel resolution.
3. **Backfill pass** – for every existing `Internal Alignment` Conversation on that Company dated within the
   last 365 days, parses its `externalId` back to a channel + parent timestamp, re-reads the thread, and
   compares the live message count against the `Sync:` watermark in the record's footer. Grown threads get
   their `description` rebuilt in place. Same record, same `externalId`, same `date`.
4. **Create pass** – for every in-scope thread with no existing record, reads the thread, renders it, and
   creates one Conversation with `users` populated from Productboard authors – `endusers` is never populated
   on this record type.
5. Reports a per-thread table – created · backfilled · unchanged · skipped-as-noise – with the record IDs.

## Channel resolution

Either half of the customer↔channel pair is enough; the procedure resolves the other.
`Company.custom.Slack ID` is the pairing – a large share of accounts already have it populated via RevOps/SF
sync, so this is very often a straight read rather than a resolution. (`custom.Slack URL` shows the same
channel as an `/archives/` link, but it's a locked formula derived from `custom.Slack ID` – read it for
convenience, never write it.)

**Given a channel** (URL, ID, or `#name`) – resolve the company from the channel name
(`#account-acme-corp-productboard` → `acme corp`) matched against `Company.name`, falling back to a
`domains[contains]` slug (the same parent-company pattern as `/log-slack-threads`: `leanix` misses on `name`,
resolves to **SAP SE** on `leanix.net`). **Before logging anything**, check the message authors: an internal
channel is all or nearly all `@productboard.com`. A candidate with a substantial share of external authors is
a shared/guest channel wearing an `#account-` name by accident – that is `/log-slack-threads`'s target, not
this skill's. Confirm the company in chat, then offer to cache the channel.

**Given a customer** – resolve the Company on `name` (retry as a `domains` slug on a miss), then read
`custom.Slack ID`. Populated: validate with a one-message read and use it, no search. Empty: sweep
`slack_search_channels` for the `#account-{customer}` convention, apply the same internal-authorship check to
any candidate, and if that misses, ask for the URL or ID.

> `custom.External_Slack_Channel_ID` is **not** a candidate here. That field holds the **shared external**
> channel `/log-slack-threads` sweeps – reading or writing it from this skill points an internal-comms sweep
> at the wrong channel entirely.

## Non-negotiables

- **One Conversation per thread.** Never merge two threads into one record, and never split a thread across
  records.
- **`date` is the last message of the thread**, never the run date – same convention as `/log-slack-threads`,
  and what keeps native `lastTouch` accurate for a multi-part conversation. Thread start preserved in
  `custom.First message time` and the `externalId` parent ts.
- **`externalId` is the dedup key, always present, same format as `/log-slack-threads`:**
  `slack_{channelId}_{parentTsDigits}`. Built by the helper in § 3 of the agent file, never by hand. The shared
  prefix is safe – internal and external channels always have different Slack IDs, so the two skills' records
  never collide even on the same company.
- **Legacy repair runs before the backfill pass**, scoped to `Internal Alignment` records on the account.
  Repairs touch `externalId` only, never `date` or `subject`.
- **Backfill re-dates forward and never re-creates.** A thread that gained replies is an `update_model_record`
  on the existing `_id`.
- **`Internal Alignment` does not count toward session delivery** – it is a valid touchpoint for Planhat's
  native `lastTouch`, but never a session. Never use it to fill a session gap or retype an uncounted record
  into a counted session type.
- **`users` only, never `endusers`.** This record type is Productboard-internal by definition. A
  non-`productboard.com` author found mid-thread is named in the report, never linked as a participant – and
  if their presence looks structural rather than one-off, treat it as a misclassified channel and stop to ask.
- **Renderer constraints are not cosmetic** – identical to `/log-slack-threads` § Description HTML: no
  `<div>`, no `<table>`, no `<ol>`/`<ul>`, no `background`/`border`/`color` styles, no literal newlines.
- **Never edit contact identity data** encountered while resolving `users`.
- **Never post to Slack.** This skill is read-only against Slack.
- **Never sweep a channel whose company you have not confirmed**, and **never sweep a channel that is not
  actually internal.** Zero, ambiguous, or mixed-authorship matches: stop and ask.
- **Never write `custom.Slack ID` without the user's explicit confirmation in chat** – it syncs back toward
  Salesforce, even though the API accepts an unconfirmed write. Never overwrite a populated value that
  disagrees with what was just swept without surfacing the conflict first.
- **Never write `custom.Slack URL`, ever.** It is a locked formula field derived from `custom.Slack ID` –
  reading it is fine, but it is never a write target for this skill or any other.
- **Never read or write `custom.External_Slack_Channel_ID`.** That is `/log-slack-threads`'s cache for the
  shared external channel, not this skill's.

## Related

- `/log-slack-threads` – the external-channel sibling. Same dedup mechanics, renderer, and fan-out pattern;
  different channel, cache field, Planhat `type`, and participant handling.
- `context/planhat-schema.md` § The three Slack fields on Company – field ownership and the internal-vs-
  external distinction this skill depends on getting right.
- `/log-feedback` – for turning a Slack thread into Productboard product feedback rather than a Planhat
  touchpoint.
